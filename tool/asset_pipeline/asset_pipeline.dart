import 'dart:convert';
import 'dart:io';

import '../ai_agents/env_file.dart';
import '../ai_agents/image_manifest.dart';
import '../ai_agents/image_pricing.dart';
import '../ai_agents/openai_image.dart';
import '../ai_agents/png_check.dart';
import '../season_gen/content_approval.dart';
import '../season_gen/plan_files.dart';
import '../season_gen/sha256.dart';
import 'asset_budget.dart';
import 'asset_plan.dart';
import 'asset_state.dart';
import 'asset_transform.dart';
import 'asset_wiring.dart';

/// A season's pictures made from its `assets.manifest.json` (STEP 3-12A):
/// checked, ordered by their references, priced, then (only with
/// `--generate`, a budget and a call limit) made one by one with
/// `ImageStudio`, each checked whole, fitted to the game's size and recorded.
///
///     dart run tool/asset_pipeline/asset_pipeline.dart --manifest content_pipeline/seasons/s3_rome/assets.manifest.json
///         [--generate --max-budget 2.50 [--max-calls 3] [--only <assetId>]...]
///         [--wiring [--write]] [--apply-plan] [--work <dir>] [--env .env]
///
/// * Without `--generate` (the default) nothing is sent and nothing written:
///   the check, the order, the costs and where each picture is shown.
/// * `--generate` needs `--max-budget` (US dollars, list-price estimates:
///   the bill is OpenAI's) and makes at most `--max-calls` calls (3 unless
///   given, at most 50). A run whose next pictures' conservative cost passes
///   the budget is refused before any call.
/// * A picture made is never made again; a damaged or changed one is never
///   reused or written over; a failed one is tried again by a later run; an
///   API error stops the run at once. Nothing is written in `assets/`.
/// * `--wiring --write` writes `planning/asset_wiring.json`; `--apply-plan`
///   shows what `--apply` copies into `assets/` (writes nothing).
/// * `--apply [--only <assetId>]...` (the Rome integration): each validated
///   picture copied into `assets/` (checked, never over another file), its
///   manifest status `generated`, its folder listed in `pubspec.yaml`.
/// * `--doctor [--fix]`: this machine's records against the game's files
///   (`asset_work/` is not in Git); `--fix` does only what is safe.
/// * A picture in `assets/` that this machine has not made is never made
///   again; a missing picture whose game copy is the same is put back.
///
/// Exit codes: 0 done (or a dry run); 1 a call or a picture failed; 2
/// refused before any call; 64 usage.
Future<void> main(List<String> args) async {
  final a = _Args.parse(args);
  if (a == null) {
    stderr.writeln('usage: dart run tool/asset_pipeline/asset_pipeline.dart --manifest <assets.manifest.json> '
        '[--generate --max-budget <usd> [--max-calls ${AssetBudget.defaultMaxCalls}] [--only <assetId>]...] '
        '[--wiring [--write]] [--apply-plan] [--apply [--only <assetId>]...] [--doctor [--fix]] [--work <dir>] [--env .env]');
    exit(64);
  }
  final plan = AssetPlan.load(a.manifest!);
  final openAi = OpenAiImageApi();
  final pipeline = AssetPipeline(
    plan: plan,
    studio: ImageStudio(api: openAi, editApi: openAi, findKey: () => ApiKey.find(envPath: a.envPath)),
    work: a.work,
  );
  if (a.wiring) exit(pipeline.wiring(write: a.write));
  if (a.applyPlan) exit(pipeline.applyPlan());
  if (a.apply) exit(pipeline.apply(only: a.only));
  if (a.doctor) exit(pipeline.doctor(fix: a.fix));
  exit(await pipeline.run(generate: a.generate, maxBudget: a.maxBudget, maxCalls: a.maxCalls, only: a.only));
}

class _Args {
  String? manifest, work;
  String envPath = '.env';
  double? maxBudget;
  int maxCalls = AssetBudget.defaultMaxCalls;
  bool generate = false, wiring = false, write = false, applyPlan = false, apply = false, doctor = false, fix = false;
  final only = <String>{};

  static _Args? parse(List<String> args) {
    final a = _Args();
    for (var i = 0; i < args.length; i++) {
      String next() => i + 1 < args.length ? args[++i] : throw const FormatException();
      try {
        switch (args[i]) {
          case '--manifest':
            a.manifest = next();
          case '--work':
            a.work = next();
          case '--env':
            a.envPath = next();
          case '--max-budget':
            a.maxBudget = double.parse(next());
          case '--max-calls':
            a.maxCalls = int.parse(next());
          case '--only':
            a.only.add(next());
          case '--generate':
            a.generate = true;
          case '--wiring':
            a.wiring = true;
          case '--write':
            a.write = true;
          case '--apply-plan':
            a.applyPlan = true;
          case '--apply':
            a.apply = true;
          case '--doctor':
            a.doctor = true;
          case '--fix':
            a.fix = true;
          default:
            return null;
        }
      } on FormatException {
        return null;
      }
    }
    if (a.write && !a.wiring) return null;
    if (a.fix && !a.doctor) return null;
    return a.manifest == null ? null : a;
  }
}

/// Runs a season's [plan] through [studio].
class AssetPipeline {
  AssetPipeline({required this.plan, required this.studio, String? work, void Function(String)? log, DateTime Function()? now})
      : work = (work ?? AssetPlan.workDirFor(plan.seasonId)).replaceAll(r'\', '/').replaceAll(RegExp(r'/$'), ''),
        log = log ?? stdout.writeln,
        now = now ?? DateTime.now;

  final AssetPlan plan;
  final ImageStudio studio;

  /// Where the pictures and records are kept, from the repository's root.
  final String work;
  final void Function(String) log;
  final DateTime Function() now;

  String get root => studio.root;
  String get statePath => '$work/${PipelineState.fileName}';
  String get ledgerPath => '$work/${ImageManifest.fileName}';

  bool _checked() {
    if (plan.ok) return true;
    for (final f in plan.errors) {
      log('error    [${f.code}] ${f.where}: ${f.message}');
    }
    log('${plan.errors.length} error(s): nothing made, nothing sent');
    return false;
  }

  PipelineState? _state() {
    try {
      return PipelineState.load('$root/$statePath', plan.seasonId);
    } on FormatException catch (e) {
      log('error    ${e.message}');
      return null;
    }
  }

  /// The picture the game takes of [id] (its game copy, else its API
  /// picture), when it is validated.
  String? _gameFile(PipelineState s, String id) => s.statusOf(id) == AssetStatus.validated ? s.of(id).game?.path : null;

  /// Makes (or with [generate] false, only shows) the season's pictures.
  /// Its exit code.
  Future<int> run({bool generate = false, double? maxBudget, int maxCalls = AssetBudget.defaultMaxCalls, Set<String> only = const {}}) async {
    if (!_checked()) return 2;
    final unknown = only.where((id) => !plan.assets.any((a) => a.assetId == id)).toList();
    if (unknown.isNotEmpty) {
      log('error    --only ${unknown.join(', ')}: not an asset of ${plan.manifestPath}');
      return 2;
    }
    final state = _state();
    if (state == null) return 2;
    final order = plan.schedule!.order;
    final queue = [for (final id in order) if (only.isEmpty || only.contains(id)) plan.asset(id)];

    log('manifest ${plan.manifestPath}: ${plan.assets.length} pictures of ${plan.seasonId}, ${plan.model}, quality ${plan.quality}');
    log('work     $work (raw/, game/, ${PipelineState.fileName}, ${ImageManifest.fileName}); never assets/ or lib/');
    if (!generate) return _dryRun(state, queue, maxBudget: maxBudget, maxCalls: maxCalls, only: only);

    // Generating: a budget, a call limit and a key before anything else.
    if (maxBudget == null || maxBudget <= 0) {
      log('error    --generate needs --max-budget <usd>: no call is made without a budget');
      return 2;
    }
    if (maxCalls < 1 || maxCalls > AssetBudget.maxCallsCeiling) {
      log('error    --max-calls $maxCalls: 1 to ${AssetBudget.maxCallsCeiling}');
      return 2;
    }
    final key = studio.findKey();
    if (key == null) {
      log('error    no API key: OPENAI_API_KEY is in neither the environment nor the .env file; nothing sent');
      return 2;
    }

    for (final line in _recoverFromGame(state)) {
      log('restored $line');
    }
    for (final line in state.verify(root)) {
      log('state    $line');
    }

    if (!_budgetFits(_plannedCalls(state, queue, maxCalls), maxBudget, maxCalls)) {
      log('error    the planned calls pass --max-budget: nothing sent');
      return 2;
    }

    final budget = AssetBudget(maxUsd: maxBudget, maxCalls: maxCalls);
    final started = now().toUtc();
    var failed = false;
    String? stopped;
    for (final a in queue) {
      final r = state.of(a.assetId);
      if (r.status == AssetStatus.validated) continue;
      if (r.status == AssetStatus.blocked) {
        log('blocked  ${a.assetId}: ${r.error}');
        continue;
      }
      if (_inGame(a, state)) {
        log('in game  ${a.assetId}: ${a.outputPath} is in assets/ already (made on another machine or by hand): '
            'never made again here (--doctor --fix records it)');
        continue;
      }
      if (r.status != AssetStatus.generated) {
        final waiting = [for (final ref in a.references) if (_gameFile(state, ref) == null) ref];
        if (waiting.isNotEmpty) {
          log('waiting  ${a.assetId}: drawn from ${waiting.join(', ')}, not made yet');
          continue;
        }
        final cost = plan.costOf(a);
        if (budget.refusal(cost.conservativeUsd) case final why?) {
          stopped = why;
          log('stop     $why');
          break;
        }
        final outcome = await _make(a, state, budget, cost);
        if (outcome == _Made.apiFailed || outcome == _Made.failed) {
          failed = true;
          stopped = '${outcome == _Made.apiFailed ? 'an API error' : 'a picture not readable back'} (${a.assetId}): stopped, nothing more sent';
          log('stop     $stopped');
          break;
        }
        if (outcome != _Made.made) continue;
      }
      if (!_validate(a, state)) failed = true;
    }
    state.runs.add({
      'startedAt': started.toIso8601String(),
      'endedAt': now().toUtc().toIso8601String(),
      'maxBudgetUsd': maxBudget,
      'maxCalls': maxCalls,
      if (only.isNotEmpty) 'only': (only.toList()..sort()),
      'apiCalls': budget.calls,
      'spentUsd': ImagePricing.round(budget.spentUsd),
      'spentNote': 'usage at list prices; a call with no usage, or a failed one, at its conservative estimate. The bill is OpenAI\'s.',
      'stopped': ?stopped,
    });
    state.save();
    log('done     ${budget.calls} API call(s), ${ImagePricing.usd(budget.spentUsd)} spent of ${ImagePricing.usd(maxBudget)} (estimate); '
        'states ${jsonEncode(state.counts)}');
    return failed ? 1 : 0;
  }

  /// The calls a run of [queue] would make, in order: each picture not
  /// validated, blocked or already generated, whose references are made
  /// before it, at most [maxCalls].
  List<PipelineAsset> _plannedCalls(PipelineState state, List<PipelineAsset> queue, int maxCalls) {
    final ready = <String>{for (final a in plan.assets) if (state.statusOf(a.assetId) == AssetStatus.validated) a.assetId};
    final toCall = <PipelineAsset>[];
    for (final a in queue) {
      final s = state.statusOf(a.assetId);
      if (s == AssetStatus.validated || s == AssetStatus.blocked || _inGame(a, state)) continue;
      if (!a.references.every(ready.contains)) continue;
      if (s != AssetStatus.generated) {
        if (toCall.length == maxCalls) break;
        toCall.add(a);
      }
      ready.add(a.assetId);
    }
    return toCall;
  }

  /// Whether [toCall]'s conservative cost stays within [maxBudget], shown.
  bool _budgetFits(List<PipelineAsset> toCall, double maxBudget, int maxCalls) {
    final estimated = toCall.fold<double>(0, (s, a) => s + plan.costOf(a).estimatedUsd);
    final planned = toCall.fold<double>(0, (s, a) => s + plan.costOf(a).conservativeUsd);
    log('run      ${toCall.length} call(s) planned (--max-calls $maxCalls): ${toCall.map((a) => a.assetId).join(', ')}');
    log('cost     ${ImagePricing.usd(estimated)} estimated, ${ImagePricing.usd(planned)} conservative '
        '(x${AssetBudget.safetyFactor}), budget ${ImagePricing.usd(maxBudget)}');
    return planned <= maxBudget + 1e-9;
  }

  int _dryRun(PipelineState state, List<PipelineAsset> queue, {double? maxBudget, int maxCalls = AssetBudget.defaultMaxCalls, Set<String> only = const {}}) {
    final levels = plan.schedule!.levels;
    var total = 0.0, conservative = 0.0, remaining = 0.0;
    log('order    (references first; level: how many pictures deep it is drawn)');
    for (final (i, a) in queue.indexed) {
      final c = plan.costOf(a);
      total += c.estimatedUsd;
      conservative += c.conservativeUsd;
      final status = state.statusOf(a.assetId);
      if (status != AssetStatus.validated) remaining += c.conservativeUsd;
      log('  ${(i + 1).toString().padLeft(2)}. L${levels[a.assetId]} ${a.assetId.padRight(34)} ${a.size.padRight(9)} ${a.stylePreset.padRight(10)} '
          '${ImagePricing.usd(c.estimatedUsd)} ${status.name}'
          '${a.references.isEmpty ? '' : '  ← ${a.references.join(', ')} (images/edits)'}');
    }
    final withRefs = queue.where((a) => a.references.isNotEmpty).length;
    log('cost     ${ImagePricing.usd(total)} estimated (${ImagePricing.usd(conservative)} conservative, x${AssetBudget.safetyFactor}); '
        '$withRefs drawn from references, each reference priced at ${ImagePricing.referenceImageTokens} image input tokens; '
        'list prices of ${ImagePricing.checkedOn}, the bill is OpenAI\'s');
    log('left     ${ImagePricing.usd(remaining)} conservative for the pictures not validated yet');
    final wiring = AssetWiring.counts(AssetWiring.of(plan, root: root));
    log('wiring   ${jsonEncode(wiring)} (--wiring to list)');
    if (state.records.isNotEmpty) log('state    ${jsonEncode(state.counts)} ($statePath)');
    if (maxBudget != null) {
      // The run --generate would make with these limits, judged as it would judge it.
      // The queue is --only's pictures alone: no other picture can be called.
      final toCall = _plannedCalls(state, queue, maxCalls);
      final fits = _budgetFits(toCall, maxBudget, maxCalls);
      final waiting = queue.length - toCall.length - queue.where((a) => state.statusOf(a.assetId) == AssetStatus.validated).length;
      log('verdict  ${fits ? 'within' : 'REFUSED: over'} --max-budget ${ImagePricing.usd(maxBudget)}'
          '${only.isEmpty ? '' : '; calls only for --only (${only.length})'}'
          '${waiting > 0 ? '; $waiting picture(s) left for a later run (--max-calls, or references not made)' : ''}');
    }
    log('dry run  nothing sent, nothing written (--generate --max-budget <usd> to make them)');
    return 0;
  }

  /// One picture asked of the API through [studio].
  Future<_Made> _make(PipelineAsset a, PipelineState state, AssetBudget budget, AssetCost cost) async {
    final r = state.of(a.assetId);
    final raw = plan.rawPath(a, work: work);
    final req = plan.request(a, raw: raw, refFiles: [for (final ref in a.references) _gameFile(state, ref)!]);
    final problems = studio.problems(req);
    if (problems.isNotEmpty) {
      r
        ..status = AssetStatus.blocked
        ..error = problems.join('; ')
        ..updatedAt = now().toUtc().toIso8601String();
      state.save();
      log('blocked  ${a.assetId}: ${r.error}');
      return _Made.refused;
    }
    final keyHere = req.keyIn(root);
    final callsBefore = ImageManifest.load('$root/$ledgerPath').callsFor(keyHere);
    r
      ..status = AssetStatus.generating
      ..attempts = r.attempts + 1
      ..requestKey = keyHere
      ..estimatedUsd = cost.estimatedUsd
      ..conservativeUsd = cost.conservativeUsd
      ..error = null
      ..updatedAt = now().toUtc().toIso8601String();
    state.save();
    log('make     ${a.assetId} → $raw');
    final code = await studio.run(req, generate: true, budgetUsd: budget.remainingUsd, manifestPath: ledgerPath);
    final ledger = ImageManifest.load('$root/$ledgerPath');
    final called = ledger.callsFor(keyHere) > callsBefore;
    final entry = ledger.entries.lastWhere((e) => e['key'] == keyHere, orElse: () => const {});
    final usage = ((entry['cost'] as Map?)?['fromUsageUsd'] as num?)?.toDouble();
    if (called) budget.charge(conservativeUsd: cost.conservativeUsd, fromUsageUsd: code == 0 ? usage : null);
    r.updatedAt = now().toUtc().toIso8601String();
    switch (code) {
      case 0:
        try {
          r
            ..status = AssetStatus.generated
            ..raw = FileRecord.of(root, raw)
            ..game = null
            ..fromUsageUsd = called ? usage : r.fromUsageUsd;
        } on Object catch (e) {
          r
            ..status = AssetStatus.failed
            ..error = 'its picture could not be read back: $e';
          state.save();
          return _Made.failed;
        }
        state.save();
        return _Made.made;
      case 1:
        r
          ..status = AssetStatus.failed
          ..error = ApiKey.redactKeys('${(entry['error'] as Map?)?['message'] ?? 'the API or its picture failed'}');
        state.save();
        return _Made.apiFailed;
      default:
        r
          ..status = AssetStatus.blocked
          ..error = 'refused by the image tool before sending (see its lines above)';
        state.save();
        return _Made.refused;
    }
  }

  /// [a]'s API picture checked and fitted to the game's size. Whether it
  /// is now `validated`.
  bool _validate(PipelineAsset a, PipelineState state) {
    final r = state.of(a.assetId);
    void fail(String why, {AssetStatus status = AssetStatus.failed}) {
      r
        ..status = status
        ..error = why
        ..updatedAt = now().toUtc().toIso8601String();
      state.save();
      log('${status == AssetStatus.blocked ? 'blocked ' : 'FAILED  '} ${a.assetId}: $why');
    }

    final raw = r.raw!;
    if (raw.problem(root) case final p?) {
      fail('${raw.path}: $p', status: p == 'missing' ? AssetStatus.failed : AssetStatus.blocked);
      return false;
    }
    final fit = AssetTransform.plan(raw.width, raw.height, a.width, a.height, anchor: AssetPlan.anchorOf(a));
    if (!fit.needed) {
      r
        ..status = AssetStatus.validated
        ..game = raw
        ..transformed = false
        ..error = null
        ..updatedAt = now().toUtc().toIso8601String();
      state.save();
      log('valid    ${a.assetId}: ${raw.width}x${raw.height} as the game shows it');
      return true;
    }
    if (fit.problems.isNotEmpty) {
      fail('${raw.width}x${raw.height} → ${a.size}: ${fit.problems.join('; ')}');
      return false;
    }
    final gamePath = plan.gamePath(a, work: work);
    final bytes = AssetTransform.apply(File('$root/${raw.path}').readAsBytesSync(), fit);
    final file = File('$root/$gamePath');
    if (file.existsSync() && 'sha256:${Sha256.hex(file.readAsBytesSync())}' != 'sha256:${Sha256.hex(bytes)}') {
      fail('$gamePath is there and is not this picture: never written over (move it away)', status: AssetStatus.blocked);
      return false;
    }
    file.parent.createSync(recursive: true);
    final part = File('${file.path}.part')..writeAsBytesSync(bytes, flush: true);
    final info = PngCheck.file(part.path);
    if (info.width != a.width || info.height != a.height) {
      part.deleteSync();
      fail('fitted to ${info.width}x${info.height}, not ${a.size}');
      return false;
    }
    part.renameSync(file.path);
    r
      ..status = AssetStatus.validated
      ..game = FileRecord.of(root, gamePath)
      ..transformed = true
      ..error = null
      ..updatedAt = now().toUtc().toIso8601String();
    state.save();
    log('valid    ${a.assetId}: ${raw.width}x${raw.height} → ${a.size} (${jsonEncode(fit.toJson())}) $gamePath');
    return true;
  }

  /// Where each picture is shown; with [write], `planning/asset_wiring.json`.
  int wiring({bool write = false}) {
    if (!_checked()) return 2;
    final all = AssetWiring.of(plan, root: root);
    for (final w in all) {
      log('${w.status.id.padRight(14)} ${w.asset.assetId.padRight(34)} ${w.field ?? '-'}');
    }
    log('wiring   ${jsonEncode(AssetWiring.counts(all))}');
    if (write) {
      final path = '${plan.seasonDir}/planning/asset_wiring.json';
      File('$root/$path').writeAsStringSync(PlanFiles.encode(AssetWiring.report(plan, root: root)));
      log('wrote    $path');
    }
    return 0;
  }

  /// What a later step copies into `assets/` and registers, read-only: each
  /// validated picture, its destination, whether one is there already, its
  /// approval, and the `pubspec.yaml` folders it needs.
  int applyPlan() {
    if (!_checked()) return 2;
    final state = _state();
    if (state == null) return 2;
    for (final line in state.verify(root)) {
      log('state    $line (not saved: --apply-plan writes nothing)');
    }
    final approvals = SeasonApprovals('$root/${plan.seasonDir}');
    final pubspec = File('$root/pubspec.yaml').existsSync() ? File('$root/pubspec.yaml').readAsStringSync() : '';
    final listed = {for (final m in RegExp(r'^\s*-\s*(assets/\S+)', multiLine: true).allMatches(pubspec)) m[1]!};
    final folders = <String>{};
    var ready = 0;
    for (final a in plan.assets) {
      final r = state.records[a.assetId];
      final folder = '${a.outputPath.substring(0, a.outputPath.lastIndexOf('/'))}/';
      folders.add(folder);
      if (r?.status != AssetStatus.validated) {
        log('wait     ${a.assetId}: ${r?.status.name ?? 'planned'}');
        continue;
      }
      String approval;
      try {
        approval = approvals.asset(a.assetId).status.name;
      } on Object catch (e) {
        approval = 'unreadable ($e)';
      }
      final there = File('$root/${a.outputPath}').existsSync();
      if (!there && approval == 'approved') ready++;
      log('${there ? 'CONFLICT' : 'copy    '} ${r!.game!.path} → ${a.outputPath} (approval: $approval)'
          '${there ? ': a file is there already, never written over' : ''}');
    }
    final missing = [for (final f in folders.toList()..sort()) if (!listed.contains(f)) f];
    log('pubspec  ${missing.length} of ${folders.length} folders to list under flutter: assets:');
    for (final f in missing) {
      log('           - $f');
    }
    log('ready    $ready picture(s) validated, approved and free to copy; nothing written (--apply copies them)');
    return 0;
  }

  /// Whether [a]'s game file is in `assets/` already while this machine's
  /// state has not made it: made on another machine (`asset_work/` is not in
  /// Git) or by hand. Never made again here.
  bool _inGame(PipelineAsset a, PipelineState state) =>
      state.statusOf(a.assetId) != AssetStatus.validated && File('$root/${a.outputPath}').existsSync();

  /// Each validated record whose picture is missing here but whose game copy
  /// in `assets/` is that very picture (its recorded sha256): the picture put
  /// back from it, so the record holds and nothing is made again (another
  /// machine's `asset_work/`, or one restored from an old copy). Never over a
  /// file. The lines of what was put back.
  List<String> _recoverFromGame(PipelineState state) {
    final out = <String>[];
    for (final a in plan.assets) {
      final r = state.records[a.assetId];
      final raw = r?.raw;
      if (r == null || raw == null || (r.status != AssetStatus.validated && r.status != AssetStatus.generated)) continue;
      if (raw.problem(root) != 'missing') continue;
      final game = File('$root/${a.outputPath}');
      if (!game.existsSync() || 'sha256:${Sha256.hex(game.readAsBytesSync())}' != raw.sha256) continue;
      File('$root/${raw.path}').parent.createSync(recursive: true);
      game.copySync('$root/${raw.path}');
      out.add('${a.assetId}: its picture put back from its game copy ${a.outputPath} (the same sha256)');
    }
    return out;
  }

  /// The pictures into the game (the Rome integration; STEP 3-12C's step,
  /// done by hand before): each validated picture ([only]: those) copied to
  /// its `outputPath` beside it first (`.part`), checked against its record,
  /// then moved; one already there and the same is left; one there and
  /// different is a CONFLICT, never written over. Then its manifest status
  /// `generated` and its folder listed in `pubspec.yaml`. Approvals are
  /// shown, not required (`approve.dart` stays a person's). Exit 0, or 1 on a
  /// conflict or a picture not as recorded.
  int apply({Set<String> only = const {}}) {
    if (!_checked()) return 2;
    final state = _state();
    if (state == null) return 2;
    for (final line in _recoverFromGame(state)) {
      log('restored $line');
    }
    final approvals = SeasonApprovals('$root/${plan.seasonDir}');
    final done = <String>[];
    var problems = 0;
    for (final a in plan.assets) {
      if (only.isNotEmpty && !only.contains(a.assetId)) continue;
      final r = state.records[a.assetId];
      if (r?.status != AssetStatus.validated || r?.game == null) continue;
      final source = r!.game!;
      if (source.problem(root) case final p?) {
        log('FAILED   ${a.assetId}: ${source.path} $p: not copied');
        problems++;
        continue;
      }
      String approval;
      try {
        approval = approvals.asset(a.assetId).status.name;
      } on Object {
        approval = 'unreadable';
      }
      final dest = File('$root/${a.outputPath}');
      if (dest.existsSync()) {
        if ('sha256:${Sha256.hex(dest.readAsBytesSync())}' == source.sha256) {
          done.add(a.assetId);
          continue;
        }
        log('CONFLICT ${a.assetId}: ${a.outputPath} is there and is another picture: never written over (move it away)');
        problems++;
        continue;
      }
      dest.parent.createSync(recursive: true);
      final part = File('${dest.path}.part');
      File('$root/${source.path}').copySync(part.path);
      if ('sha256:${Sha256.hex(part.readAsBytesSync())}' != source.sha256) {
        part.deleteSync();
        log('FAILED   ${a.assetId}: the copy is not the picture recorded: nothing written');
        problems++;
        continue;
      }
      part.renameSync(dest.path);
      done.add(a.assetId);
      log('copied   ${source.path} → ${a.outputPath} (${source.sha256.substring(0, 23)}…, approval: $approval)');
    }
    final marked = AssetManifestFile.markGenerated('$root/${plan.manifestPath}', done.toSet());
    if (marked.isNotEmpty) log('manifest ${marked.length} set to generated: ${marked.join(', ')}');
    final folders = {for (final a in plan.assets) if (done.contains(a.assetId)) a.outputPath.substring(0, a.outputPath.lastIndexOf('/') + 1)};
    final added = PubspecAssets.add('$root/pubspec.yaml', folders);
    for (final f in added) {
      log('pubspec  listed $f');
    }
    log('applied  ${done.length} picture(s) in the game; ${problems == 0 ? 'no problem' : '$problems problem(s)'}');
    return problems == 0 ? 0 : 1;
  }

  /// This machine's records against the game's files (the work folder is not
  /// in Git, so another machine's pictures arrive in `assets/` only). Each
  /// picture: its state, its picture here, its game copy, its manifest
  /// status. With [fix], only what is safe: a picture put back from its
  /// identical game copy, and a game file made elsewhere recorded here
  /// (`validated`, its picture a copy of it) so it is never made again;
  /// a picture here that differs from the game's is a CONFLICT, left as it is.
  /// A picture the manifest says is in the game but is not refuses the run
  /// before (the manifest's own check, `asset_file_missing`): restore it from
  /// Git or a backup. Exit 0 when nothing is left to look at, else 1.
  int doctor({bool fix = false}) {
    if (!_checked()) return 2;
    final state = _state();
    if (state == null) return 2;
    if (fix) {
      for (final line in _recoverFromGame(state)) {
        log('restored $line');
      }
    }
    var open = 0, changed = false;
    for (final a in plan.assets) {
      final r = state.records[a.assetId];
      final game = File('$root/${a.outputPath}');
      final gameSha = game.existsSync() ? 'sha256:${Sha256.hex(game.readAsBytesSync())}' : null;
      final rawProblem = r?.raw?.problem(root);
      final status = r?.status ?? AssetStatus.planned;
      String? issue;
      if (status == AssetStatus.validated && rawProblem == 'missing' && gameSha != null && gameSha == r!.raw!.sha256) {
        issue = 'restore  its picture is missing here; its game copy is the same picture (--fix puts it back)';
      } else if (status == AssetStatus.validated && rawProblem == null && gameSha != null && gameSha != (r!.game ?? r.raw)!.sha256) {
        issue = 'CONFLICT ${a.outputPath} is another picture than this machine made: never written over';
      } else if (status == AssetStatus.validated && rawProblem != null) {
        issue = 'CHANGED  its picture ${r!.raw!.path} is $rawProblem';
      } else if (status != AssetStatus.validated && gameSha != null) {
        if (fix) {
          final raw = plan.rawPath(a, work: work);
          final there = File('$root/$raw');
          if (there.existsSync() && 'sha256:${Sha256.hex(there.readAsBytesSync())}' != gameSha) {
            issue = 'CONFLICT $raw is another picture than ${a.outputPath}: nothing recorded';
          } else {
            there.parent.createSync(recursive: true);
            if (!there.existsSync()) game.copySync(there.path);
            state.of(a.assetId)
              ..status = AssetStatus.validated
              ..raw = FileRecord.of(root, raw)
              ..game = FileRecord.of(root, raw)
              ..transformed = false
              ..error = null
              ..updatedAt = now().toUtc().toIso8601String();
            changed = true;
            log('adopted  ${a.assetId}: ${a.outputPath} made elsewhere, recorded here as made (never made again)');
            continue;
          }
        } else {
          issue = 'adopt    ${a.outputPath} is in the game, but this machine has no record of it (--fix records it; it is never made again)';
        }
      } else if (status == AssetStatus.validated && gameSha == null) {
        issue = 'apply    made here, not in the game yet (--apply copies it)';
      }
      if (issue != null) {
        open++;
        log('${issue.substring(0, 9)}${a.assetId}: ${issue.substring(9)}');
      }
    }
    if (changed) state.save();
    log('doctor   ${plan.assets.length} pictures, ${open == 0 ? 'all as recorded' : '$open to look at'}'
        '${fix ? '' : ' (--fix: only what is safe)'}');
    return open == 0 ? 0 : 1;
  }
}

/// The asset manifest's own statuses (`planned`, `generated`), written in
/// its format (2-space JSON, its line endings kept).
abstract final class AssetManifestFile {
  /// [ids] set to `generated`; the ids changed.
  static List<String> markGenerated(String path, Set<String> ids) {
    final file = File(path);
    final raw = file.readAsStringSync();
    final crlf = raw.contains('\r\n');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    final changed = <String>[];
    for (final a in (json['assets'] as List).cast<Map<String, dynamic>>()) {
      if (ids.contains(a['assetId']) && a['status'] != 'generated') {
        a['status'] = 'generated';
        changed.add('${a['assetId']}'.split('.').last);
      }
    }
    if (changed.isEmpty) return changed;
    final text = '${const JsonEncoder.withIndent('  ').convert(json)}\n';
    file.writeAsStringSync(crlf ? text.replaceAll('\n', '\r\n') : text);
    return changed;
  }
}

/// `pubspec.yaml`'s `flutter: assets:` list: a folder added after the last
/// one of its season (else after the last asset folder), never twice.
abstract final class PubspecAssets {
  /// [folders] (`assets/…/`) not listed yet, added; the folders added.
  static List<String> add(String path, Set<String> folders) {
    final file = File(path);
    if (!file.existsSync() || folders.isEmpty) return const [];
    final raw = file.readAsStringSync();
    final crlf = raw.contains('\r\n');
    final lines = raw.replaceAll('\r\n', '\n').split('\n');
    final entry = RegExp(r'^(\s+)- (assets/\S+)\s*$');
    final listed = {for (final l in lines) ?entry.firstMatch(l)?[2]};
    final added = <String>[];
    for (final f in folders.toList()..sort()) {
      if (listed.contains(f)) continue;
      final season = '${f.split('/').take(3).join('/')}/';
      var last = -1, lastOfSeason = -1;
      var indent = '    ';
      for (final (i, l) in lines.indexed) {
        final m = entry.firstMatch(l);
        if (m == null) continue;
        last = i;
        indent = m[1]!;
        if (m[2]!.startsWith(season)) lastOfSeason = i;
      }
      final at = lastOfSeason >= 0 ? lastOfSeason : last;
      if (at < 0) continue;
      lines.insert(at + 1, '$indent- $f');
      listed.add(f);
      added.add(f);
    }
    if (added.isNotEmpty) {
      final text = lines.join('\n');
      file.writeAsStringSync(crlf ? text.replaceAll('\n', '\r\n') : text);
    }
    return added;
  }
}

/// What one `_make` came to: a picture; refused before sending; the API (or
/// its answer) failed, which stops the run; the picture written but not
/// readable back, which stops it too.
enum _Made { made, refused, apiFailed, failed }
