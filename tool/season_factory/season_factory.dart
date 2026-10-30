import 'dart:convert';
import 'dart:io';

import '../ai_agents/env_file.dart';
import '../ai_agents/openai_image.dart';
import '../asset_pipeline/asset_pipeline.dart';
import '../asset_pipeline/asset_plan.dart';
import '../asset_pipeline/asset_state.dart';
import '../asset_pipeline/asset_wiring.dart';
import '../season_gen/case_levels.dart';
import '../season_gen/content_hash.dart';
import '../season_gen/generate_case.dart';
import '../season_gen/generate_season.dart';
import '../season_gen/json_schema_lite.dart';
import '../season_gen/plan_files.dart';
import '../season_gen/plan_ids.dart';
import '../season_gen/season_cases.dart';
import '../season_planner/finding.dart';
import '../season_planner/season_quality.dart';
import 'sheets.dart';

/// The season factory (the Rome integration): a planned season carried
/// into the game by the tools that already do each part, one command for
/// the whole way, stopping only where a person's (or Claude's) eyes are
/// needed. A thin layer: nothing here plans, draws or generates itself.
///
///     dart run tool/season_factory/season_factory.dart status <seasonDir>
///     dart run tool/season_factory/season_factory.dart run <seasonDir> --budget <usd> [--batch 4] [--skip-tests] [--full-tests]
///     dart run tool/season_factory/season_factory.dart reviewed <seasonDir> (--all | <assetId>...)
///     dart run tool/season_factory/season_factory.dart reject <seasonDir> <assetId> --why <text>
///
/// `run` goes through these steps in order, each one done only when it is
/// not done yet (run it again after any stop, it goes on where it stopped):
///
///  1. plans: every check (`SeasonQuality`, as `plan_season.dart check`);
///     an ERROR stops (exit 10).
///  2. doctor: this machine's picture records against the game's files,
///     only what is safe fixed (`asset_pipeline.dart --doctor --fix`).
///  3. review: pictures made here and not yet looked at: a review sheet is
///     written and the run stops (exit 20). Each is looked at, then
///     `reviewed` (or `reject`ed, its prompt fixed in the manifest).
///  4. pictures: the next [--batch] the game shows (the asset pipeline,
///     references first, one call each, never past the budget: the season's
///     `--budget` minus what the factory spent before, kept in
///     `planning/factory.json`); then step 3 (exit 20). The budget spent:
///     exit 40, nothing sent. An API error: exit 1, nothing more sent.
///  5. into the game: every validated picture copied into `assets/`
///     (`asset_pipeline.dart --apply`).
///  6. measured: the season map's landmarks and every look round's areas,
///     on the very files; anything not measured (or measured on another
///     file) gets a grid sheet and stops the run (exit 30).
///  6b. levels: every case's `levels.json` (Rookie / Junior / Master: the
///     same game, only its English) written and checked
///     (`case_levels.dart check`, a level copied from Rookie refused);
///     missing lines get a skeleton (the lines written kept) and stop the
///     run (exit 35): Claude writes them (the create-season skill), then
///     runs again.
///  7. generated: `generate_season.dart --target game`: the season in
///     `lib/data/generated/`, registered (catalog, map, cover, World Map
///     city, evidence pictures); a failure stops (exit 50).
///  8. checked: `flutter analyze` and `test/generated_seasons_test.dart` (the
///     season played whole in the app, every look round on four screens);
///     `--full-tests` the whole suite; a failure stops (exit 60).
///
/// Exit 0: the season is in the game, played through. 64: usage.
Future<void> main(List<String> args) async => exit(await SeasonFactory.cli(args));

abstract final class SeasonFactory {
  static const exitPlans = 10, exitReview = 20, exitMeasure = 30, exitLevels = 35, exitBudget = 40, exitGenerate = 50, exitTests = 60;

  static Future<int> cli(List<String> args) async {
    if (args.length < 2) return _usage();
    final dir = args[1].replaceAll(r'\', '/').replaceAll(RegExp(r'/$'), '');
    if (!File('$dir/season.plan.json').existsSync()) {
      stdout.writeln('error    $dir has no season.plan.json');
      return 64;
    }
    String? opt(String name) {
      final i = args.indexOf(name);
      return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
    }

    switch (args[0]) {
      case 'status':
        return status(dir);
      case 'run':
        final budget = double.tryParse(opt('--budget') ?? '');
        if (budget == null || budget < 0) return _usage('run needs --budget <usd> (0 makes no picture)');
        return run(
          dir,
          budget: budget,
          batch: int.tryParse(opt('--batch') ?? '') ?? 4,
          tests: !args.contains('--skip-tests'),
          fullTests: args.contains('--full-tests'),
        );
      case 'reviewed':
        final ids = [for (final a in args.skip(2)) if (!a.startsWith('--')) _assetId(dir, a)];
        return reviewed(dir, ids, all: args.contains('--all'));
      case 'reject':
        final why = opt('--why');
        if (args.length < 3 || why == null) return _usage('reject <seasonDir> <assetId> --why <text>');
        return reject(dir, _assetId(dir, args[2]), why);
      default:
        return _usage();
    }
  }

  static int _usage([String? why]) {
    if (why != null) stdout.writeln('error    $why');
    stdout.writeln('usage: dart run tool/season_factory/season_factory.dart '
        '(status <seasonDir> | run <seasonDir> --budget <usd> [--batch 4] [--skip-tests] [--full-tests] | '
        'reviewed <seasonDir> (--all | <assetId>...) | reject <seasonDir> <assetId> --why <text>)');
    return 64;
  }

  /// `ev_owl_card` → `s3_rome.asset.ev_owl_card` (a full id stays as it is).
  static String _assetId(String dir, String id) {
    if (PlanIds.asset.hasMatch(id)) return id;
    final seasonId = (PlanFiles.readJson('$dir/season.plan.json') as Map)['seasonId'];
    return '$seasonId.asset.$id';
  }

  // ── The factory's own record ─────────────────────────────────────────

  /// `planning/factory.json` (in Git, so every machine sees it): the budget
  /// given last, what the factory spent on pictures, the pictures looked at.
  static Map<String, dynamic> _record(String dir) {
    final f = File('$dir/planning/factory.json');
    if (!f.existsSync()) return {'schemaVersion': 1, 'spentUsd': 0.0, 'reviewed': <String>[], 'rejected': <Object>[], 'runs': <Object>[]};
    return (jsonDecode(f.readAsStringSync()) as Map).cast<String, dynamic>();
  }

  static void _save(String dir, Map<String, dynamic> record) {
    (record['reviewed'] as List).sort();
    File('$dir/planning/factory.json')
      ..parent.createSync(recursive: true)
      ..writeAsStringSync('${const JsonEncoder.withIndent('  ').convert(record)}\n');
  }

  static Set<String> _reviewed(Map<String, dynamic> r) => {...(r['reviewed'] as List).cast<String>()};

  // ── What the season needs ────────────────────────────────────────────

  static AssetPipeline _pipeline(AssetPlan plan, {void Function(String)? log}) {
    final openAi = OpenAiImageApi();
    return AssetPipeline(plan: plan, studio: ImageStudio(api: openAi, editApi: openAi, findKey: () => ApiKey.find()), log: log);
  }

  /// The pictures the game shows, by asset id: every one a case shows
  /// (the generator writes it in), the cover, the map, and each picture made
  /// for an evidence (its notebook card). Not the ones no screen shows
  /// (`not_supported`), nor a story scene the generator has no table for.
  static Set<String> neededPictures(AssetPlan plan) {
    final evidence = <String>{};
    for (final path in SeasonCases.of('${plan.seasonDir}/season.plan.json')) {
      for (final m in PlanFiles.loadCasePlan(path).allMissions) {
        evidence.add(m.clueOutputs.evidence);
      }
    }
    return {
      for (final w in AssetWiring.of(plan))
        if (w.status == WiringStatus.wired ||
            w.status == WiringStatus.wiredWhenMade ||
            w.asset.type == 'cover' ||
            w.asset.type == 'map' ||
            evidence.contains(w.asset.subject))
          w.asset.assetId,
    };
  }

  /// What is left to measure on the made pictures: the map's landmarks and
  /// every look round's areas, each on the file the game shows. A line each.
  static List<(String what, String file)> unmeasured(String dir) {
    final out = <(String, String)>[];
    final season = PlanFiles.readJson('$dir/season.plan.json') as Map;
    final map = (season['art'] as Map?)?['map'] as Map?;
    final mapAsset = _assetsOfType(dir, 'map').firstOrNull;
    if (mapAsset != null && File(mapAsset).existsSync()) {
      if (map == null) {
        out.add(('the season map\'s landmarks (season.plan.json art.map: each location\'s drawing centre, every place\'s locId)', mapAsset));
      } else if (map['measuredOn'] != ContentHash.ofBytes(File('${map['file']}').readAsBytesSync())) {
        out.add(('the season map\'s landmarks, measured on another file (art.map.measuredOn)', '${map['file']}'));
      }
    }
    for (final path in SeasonCases.of('$dir/season.plan.json')) {
      final plan = PlanFiles.loadCasePlan(path);
      for (final m in plan.allMissions) {
        final e = m.play?.explore;
        if (e == null || !File(e.picture.file).existsSync()) continue;
        final measured = e.picture.measuredOn == ContentHash.ofBytes(File(e.picture.file).readAsBytesSync());
        if (!measured || m.puzzle.notes.any((n) => n.contains('UNMEASURED'))) {
          out.add(('${m.missionId}\'s look round (play.explore areas, marks, guideAt, opening; picture.measuredOn; the UNMEASURED note)', e.picture.file));
        }
      }
    }
    return out;
  }

  static List<String> _assetsOfType(String dir, String type) => [
    for (final a in (PlanFiles.readJson('$dir/assets.manifest.json') as Map)['assets'] as List)
      if ((a as Map)['type'] == type) '${a['outputPath']}',
  ];

  // ── levels ───────────────────────────────────────────────────────────

  /// Each levels file of the season at [dir] not yet written (by its path),
  /// with what is wrong with it: a case's `levels.json` or the season's
  /// `season.levels.json`, held to `case_levels.dart check` (every line at
  /// Junior and Master, the same game, not copied from Rookie). The common
  /// plan is written first and is Rookie's; each levels file gives each of
  /// its lines again at each level. [skeleton]: a file missing lines (or
  /// with lines the plan no longer has) is written again with every line,
  /// the lines written kept, so a stopped writing goes on where it stopped.
  static Map<String, List<String>> levelsToWrite(String dir, {bool skeleton = false}) {
    final schemas = SchemaSet.load('tool/season_gen/schema');
    final season = PlanFiles.loadSeasonPlan('$dir/season.plan.json');
    bool unfinished(List<String> found) =>
        found.any((f) => f.startsWith('[levels_missing]') || f.startsWith('[level_stale]') || f.startsWith('[level_missing]'));
    final out = <String, List<String>>{};
    for (final path in SeasonCases.of('$dir/season.plan.json')) {
      final found = CaseLevels.checkWritten(path, season, schemas);
      if (found.isEmpty) continue;
      if (skeleton && unfinished(found)) CaseLevels.writeSkeleton(path);
      out[CaseLevels.pathFor(path)] = found;
    }
    // The season's own lines (its outro and finale), the same way.
    final own = SeasonLevels.checkWritten('$dir/season.plan.json');
    if (own.isNotEmpty) {
      if (skeleton && unfinished(own)) SeasonLevels.writeSkeleton('$dir/season.plan.json');
      out[SeasonLevels.pathFor('$dir/season.plan.json')] = own;
    }
    return out;
  }

  // ── status ───────────────────────────────────────────────────────────

  static int status(String dir) {
    final report = SeasonQuality.run(dir);
    stdout.writeln('season   $dir: ${report.seasonId}');
    stdout.writeln('plans    ${report.count(Level.error)} ERROR, ${report.count(Level.warning)} WARNING');
    final plan = AssetPlan.load('$dir/assets.manifest.json');
    if (!plan.ok) {
      stdout.writeln('pictures the manifest has errors: plan_season.dart check');
      return 1;
    }
    final state = PipelineState.load('${AssetPlan.workDirFor(plan.seasonId)}/${PipelineState.fileName}', plan.seasonId);
    final record = _record(dir);
    final needed = neededPictures(plan);
    final inGame = {for (final a in plan.assets) if (File(a.outputPath).existsSync()) a.assetId};
    final madeHere = {for (final a in plan.assets) if (state.statusOf(a.assetId) == AssetStatus.validated) a.assetId};
    final toMake = needed.difference(inGame).difference(madeHere);
    final toReview = madeHere.difference(inGame).difference(_reviewed(record));
    stdout.writeln('pictures ${needed.length} the game shows: ${inGame.intersection(needed).length} in the game, '
        '${madeHere.difference(inGame).length} made here, ${toMake.length} to make, ${toReview.length} to review');
    stdout.writeln('budget   ${(record['spentUsd'] as num).toStringAsFixed(4)} spent by the factory (budget given last: ${record['budgetUsd'] ?? '-'})');
    final measure = unmeasured(dir);
    stdout.writeln('measured ${measure.isEmpty ? 'everything made' : '${measure.length} to measure'}');
    final levels = report.hasErrors ? const <String, List<String>>{} : levelsToWrite(dir);
    stdout.writeln('levels   ${levels.isEmpty ? 'every case at Rookie, Junior and Master' : '${levels.length} files to write: ${levels.keys.join(', ')}'}');
    final seasonId = report.seasonId;
    final gameDir = '${GameRegistry.dir}/$seasonId';
    final inLib = File('$gameDir/$manifestName').existsSync();
    stdout.writeln('game     ${inLib ? 'generated into $gameDir' : 'not in the game yet'}');
    final next = report.hasErrors
        ? 'fix the plans: plan_season.dart check $dir'
        : toReview.isNotEmpty
        ? 'look at the pictures made, then: season_factory.dart reviewed $dir <assetId>... (or reject)'
        : toMake.isNotEmpty
        ? 'season_factory.dart run $dir --budget <usd>'
        : measure.isNotEmpty
        ? 'measure (season_factory.dart run writes the grid sheets)'
        : levels.isNotEmpty
        ? 'write Junior and Master in each levels file (create-season § Levels), then season_factory.dart run $dir --budget 0'
        : 'season_factory.dart run $dir --budget 0 (generate, register, test)';
    stdout.writeln('next     $next');
    return 0;
  }

  // ── reviewed / reject ────────────────────────────────────────────────

  static int reviewed(String dir, List<String> ids, {bool all = false}) {
    final plan = AssetPlan.load('$dir/assets.manifest.json');
    final state = PipelineState.load('${AssetPlan.workDirFor(plan.seasonId)}/${PipelineState.fileName}', plan.seasonId);
    final record = _record(dir);
    final made = {for (final a in plan.assets) if (state.statusOf(a.assetId) == AssetStatus.validated) a.assetId};
    final marking = all ? made.difference(_reviewed(record)) : ids.toSet();
    for (final id in marking) {
      if (!made.contains(id)) {
        stdout.writeln('error    $id is not a picture made here');
        return 1;
      }
    }
    (record['reviewed'] as List).addAll(marking.difference(_reviewed(record)));
    _save(dir, record);
    stdout.writeln('reviewed ${marking.length}: ${(marking.toList()..sort()).join(', ')}');
    return 0;
  }

  /// [assetId]'s picture set aside (never deleted: `superseded/` in the
  /// work folder, with its record) so the next run makes it again, from
  /// its manifest prompt as fixed since. [why] is kept.
  static int reject(String dir, String assetId, String why) {
    final plan = AssetPlan.load('$dir/assets.manifest.json');
    final work = AssetPlan.workDirFor(plan.seasonId);
    final state = PipelineState.load('$work/${PipelineState.fileName}', plan.seasonId);
    final r = state.records[assetId];
    final asset = plan.assets.where((a) => a.assetId == assetId).firstOrNull;
    if (r?.raw == null || asset == null) {
      stdout.writeln('error    $assetId has no picture made here');
      return 1;
    }
    if (File(asset.outputPath).existsSync()) {
      stdout.writeln('error    $assetId is in the game already (${asset.outputPath}): move it away by hand first, it is never written over');
      return 1;
    }
    final raw = File(r!.raw!.path);
    final name = asset.outputPath.split('/').last.replaceAll('.png', '');
    final aside = Directory('$work/superseded/${name}_${r.raw!.sha256.substring(7, 23)}')..createSync(recursive: true);
    if (raw.existsSync()) raw.renameSync('${aside.path}/${raw.uri.pathSegments.last}');
    File('${aside.path}/state_record.json').writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert({'assetId': assetId, 'record': r.toJson(), 'why': why})}\n',
    );
    state.records.remove(assetId);
    state.save();
    final record = _record(dir);
    (record['reviewed'] as List).remove(assetId);
    (record['rejected'] as List).add({'assetId': assetId, 'sha256': r.raw!.sha256, 'why': why});
    _save(dir, record);
    stdout.writeln('rejected $assetId: set aside in ${aside.path}; fix its prompt in assets.manifest.json, then run again');
    return 0;
  }

  // ── run ──────────────────────────────────────────────────────────────

  static Future<int> run(String dir, {required double budget, int batch = 4, bool tests = true, bool fullTests = false}) async {
    void say(String step, String line) => stdout.writeln('${step.padRight(9)}$line');

    // 1. The plans.
    final report = SeasonQuality.run(dir);
    SeasonQuality.write(dir, report);
    if (report.hasErrors) {
      for (final f in report.findings.where((f) => f.isError)) {
        stdout.writeln(f);
      }
      say('plans', '${report.count(Level.error)} ERROR: fix the plans, then run again');
      return exitPlans;
    }
    say('plans', 'no ERROR (${report.count(Level.warning)} WARNING)');
    final seasonId = report.seasonId;

    // 2. This machine's records against the game's files.
    final plan = AssetPlan.load('$dir/assets.manifest.json');
    final pipeline = _pipeline(plan, log: (l) => stdout.writeln('  $l'));
    pipeline.doctor(fix: true);

    final work = AssetPlan.workDirFor(seasonId);
    PipelineState state() => PipelineState.load('$work/${PipelineState.fileName}', seasonId);
    final record = _record(dir)..['budgetUsd'] = budget;
    _save(dir, record);
    final needed = neededPictures(plan);
    bool inGame(PipelineAsset a) => File(a.outputPath).existsSync();

    // 3. Pictures made here and not looked at.
    int review(Iterable<PipelineAsset> made) {
      final files = [for (final a in made) state().records[a.assetId]!.game!.path];
      final sheet = '$work/review/factory_${DateTime.now().toUtc().toIso8601String().replaceAll(RegExp(r'[:.]'), '-')}.png';
      Sheets.review(files, sheet);
      say('review', 'look at each picture before it goes into the game: $sheet');
      for (final (i, a) in made.indexed) {
        stdout.writeln('  ${i + 1}. ${a.assetId}: ${a.description}');
      }
      say('review', 'then: season_factory.dart reviewed $dir <assetId>... (or --all), or reject <assetId> --why <text>');
      return exitReview;
    }

    final unreviewed = [
      for (final a in plan.assets)
        if (state().statusOf(a.assetId) == AssetStatus.validated && !inGame(a) && !_reviewed(_record(dir)).contains(a.assetId)) a,
    ];
    if (unreviewed.isNotEmpty) return review(unreviewed);

    // 4. The next pictures the game shows, within the budget.
    final toMake = [for (final a in plan.assets) if (needed.contains(a.assetId) && !inGame(a) && state().statusOf(a.assetId) != AssetStatus.validated) a];
    if (toMake.isNotEmpty) {
      final spent = (_record(dir)['spentUsd'] as num).toDouble();
      final left = budget - spent;
      say('pictures', '${toMake.length} to make; ${spent.toStringAsFixed(4)} of ${budget.toStringAsFixed(2)} spent, ${left.toStringAsFixed(4)} left');
      if (left <= 0) {
        say('budget', 'spent: nothing sent (run again with a larger --budget)');
        return exitBudget;
      }
      final before = {for (final a in toMake) a.assetId: state().statusOf(a.assetId)};
      final code = await pipeline.run(generate: true, maxBudget: left, maxCalls: batch, only: {for (final a in toMake) a.assetId});
      final runs = state().runs;
      final last = runs.isEmpty ? null : runs.last;
      final cost = (last?['spentUsd'] as num?)?.toDouble() ?? 0;
      final r = _record(dir);
      r['spentUsd'] = ((r['spentUsd'] as num).toDouble() + cost);
      (r['runs'] as List).add({'at': DateTime.now().toUtc().toIso8601String(), 'calls': last?['apiCalls'] ?? 0, 'spentUsd': cost});
      _save(dir, r);
      final made = [for (final a in toMake) if (before[a.assetId] != AssetStatus.validated && state().statusOf(a.assetId) == AssetStatus.validated) a];
      if (code == 2) {
        say('budget', 'the next picture passes what is left: nothing sent');
        if (made.isEmpty) return exitBudget;
      }
      if (code == 1) {
        say('stopped', 'an API error or a picture not readable: nothing more sent (see the lines above)');
        return made.isEmpty ? 1 : review(made);
      }
      if (made.isNotEmpty) return review(made);
    }

    // 5. Into the game.
    if (pipeline.apply(only: needed) != 0) {
      say('apply', 'a picture could not go into the game (see above)');
      return 1;
    }
    pipeline.wiring(write: true);

    // 6. Measured on the made pictures.
    final measure = unmeasured(dir);
    if (measure.isNotEmpty) {
      for (final (what, file) in measure) {
        final sheet = '$work/review/grid_${file.split('/').last}';
        Sheets.grid(file, sheet);
        say('measure', '$what\n           on $file: grid sheet $sheet (sha256 ${ContentHash.ofBytes(File(file).readAsBytesSync())})');
      }
      say('measure', 'write each into the plans as read off its sheet, then run again');
      return exitMeasure;
    }

    // 6b. Every case at Junior and Master: the same game, other English.
    final unwritten = levelsToWrite(dir, skeleton: true);
    if (unwritten.isNotEmpty) {
      unwritten.forEach((file, found) {
        say('levels', '$file: ${found.length} to fix');
        for (final f in found.take(5)) {
          stdout.writeln('  $f');
        }
      });
      say('levels', 'write Junior and Master for every empty line (the same meaning, answers and names; only the English; '
          'the lines written are kept), check with case_levels.dart check, read case_levels.dart review, then run again');
      return exitLevels;
    }
    say('levels', 'every case written at Rookie, Junior and Master');

    // 7. Generated into the game, registered.
    final generated = generateSeason('$dir/season.plan.json', target: 'game');
    if (generated != 0) return exitGenerate;
    SeasonQuality.write(dir, SeasonQuality.run(dir));

    // 8. Checked in the app.
    if (tests) {
      for (final command in [
        ['analyze'],
        ['test', if (!fullTests) 'test/generated_seasons_test.dart'],
      ]) {
        say('check', 'flutter ${command.join(' ')}');
        final p = await Process.start('flutter', command, runInShell: true, mode: ProcessStartMode.inheritStdio);
        if (await p.exitCode != 0) {
          say('check', 'flutter ${command.first} failed: read it above, fix, run again');
          return exitTests;
        }
      }
    } else {
      say('check', 'skipped (--skip-tests): run flutter analyze and flutter test test/generated_seasons_test.dart');
    }
    final r = _record(dir);
    say('done', '$seasonId is in the game (${GameRegistry.dir}/$seasonId); pictures ${(r['spentUsd'] as num).toStringAsFixed(4)} spent by the factory');
    return 0;
  }
}
