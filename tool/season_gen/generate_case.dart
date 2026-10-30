import 'dart:convert';
import 'dart:io';

import 'case_levels.dart';
import 'clue_graph_check.dart';
import 'content_approval.dart';
import 'content_hash.dart';
import 'dart_literal.dart';
import 'json_schema_lite.dart';
import 'play_check.dart';
import 'plan_files.dart';
import 'plan_models.dart';
import 'season_cases.dart';
import 'validate_plan.dart' show check;

/// Makes the game's Dart content of case plans (STEP 3-8): each case as the
/// JSON `Episode.fromJson` reads, its learning, language topic and evidence
/// links, and its season's info and places, from the plans' data only. The
/// words are the plans' own (`play`); nothing is made up here.
///
///     dart run tool/season_gen/generate_case.dart --season <season.plan.json>
///         --target sandbox [--out <dir>] [--check] [--force] <case.plan.json>...
///
/// * `--target sandbox` (the only one made now): written under
///   `test/sandbox/generated/<seasonId>/`, never in `lib/`: the content is
///   played by the tests only, never in the app.
/// * `--check`: nothing written; exit 1 when the files on disk are not what
///   the plans make now (line endings aside).
/// * `--force`: writes over generated files changed by hand.
/// * `--slice` (STEP 3-15A): cases from the middle of a season, for a test
///   of them alone before the season is drawn whole: written under
///   `test/sandbox/generated/<seasonId>_slice/`, with the places they use
///   only (each on disk, as always). Every other check is the same.
///
/// Nothing is written unless every plan keeps its format, structure, puzzle
/// selection and clue graph (as `validate_plan.dart` checks them) and
/// `PlayCheck` finds nothing missing. The same plans always make the same
/// bytes: no time, no machine, LF line endings. Every file starts with
/// [generatedHeader]; one changed since it was made (its hash against
/// [manifestName]) or one without the header is never written over.
Future<void> main(List<String> args) async {
  String? seasonPath, out;
  var target = 'sandbox';
  var checkOnly = false, force = false, slice = false;
  final cases = <String>[];
  for (var i = 0; i < args.length; i++) {
    switch (args[i]) {
      case '--season' when i + 1 < args.length:
        seasonPath = args[++i];
      case '--target' when i + 1 < args.length:
        target = args[++i];
      case '--out' when i + 1 < args.length:
        out = args[++i];
      case '--check':
        checkOnly = true;
      case '--force':
        force = true;
      case '--slice':
        slice = true;
      default:
        cases.add(args[i]);
    }
  }
  if (seasonPath == null || cases.isEmpty) {
    stderr.writeln('usage: dart run tool/season_gen/generate_case.dart --season <season.plan.json> --target sandbox '
        '[--out <dir>] [--check] [--force] <case.plan.json>...');
    exit(64);
  }
  if (target != 'sandbox') {
    stderr.writeln('--target $target: cases alone are made for the sandbox only; '
        'a season of the game is made whole: dart run tool/season_gen/generate_season.dart --season <season.plan.json> --target game');
    exit(64);
  }
  // The season's other written cases are made with it (generate_season.dart):
  // a case made alone would leave the season's list of cases without them.
  // A slice is a list of its own (STEP 3-15A).
  if (!slice) {
    try {
      final given = {for (final c in cases) File(c).absolute.path.replaceAll(r'\', '/')};
      final left = [for (final c in SeasonCases.of(seasonPath)) if (!given.contains(File(c).absolute.path.replaceAll(r'\', '/'))) c];
      if (left.isNotEmpty) {
        stdout.writeln('FAILED  $seasonPath');
        for (final c in left) {
          stdout.writeln('  error    [case_left_out] $c is a case of the season too: '
              'run dart run tool/season_gen/generate_season.dart --season $seasonPath --target sandbox');
        }
        stdout.writeln('nothing written');
        exit(1);
      }
    } on GenerateFailure {
      // The season's folder as it is: the plans given are checked below.
    }
  }
  final schemaDir = '${File.fromUri(Platform.script).parent.path}/schema';
  exit(makeAndWrite(() => CaseGenerator.sandbox(seasonPath: seasonPath!, casePaths: cases, schemaDir: schemaDir, slice: slice),
      out: out, checkOnly: checkOnly, force: force));
}

/// Makes the content ([make]) and writes it into [out] (by default its
/// sandbox folder), or with [checkOnly] compares it with what is there;
/// prints each step. The command's exit code.
int makeAndWrite(Generated Function() make, {String? out, bool checkOnly = false, bool force = false}) {
  final Generated made;
  try {
    made = make();
  } on GenerateFailure catch (e) {
    for (final line in e.lines) {
      stdout.writeln(line);
    }
    stdout.writeln('nothing written');
    return 1;
  }
  final dir = out ?? made.defaultDir;
  for (final n in made.notes) {
    stdout.writeln('note     $n');
  }
  if (checkOnly) {
    final stale = GeneratedFiles.stale(dir, made.files);
    for (final f in stale) {
      stdout.writeln('stale    $dir/$f');
    }
    stdout.writeln(stale.isEmpty ? 'ok       $dir: up to date (${made.files.length} files)' : '${stale.length} stale: run without --check');
    return stale.isEmpty ? 0 : 1;
  }
  try {
    final warnings = GeneratedFiles.write(dir, made.files, force: force);
    for (final w in warnings) {
      stdout.writeln('warning  $w');
    }
  } on GenerateFailure catch (e) {
    for (final line in e.lines) {
      stdout.writeln(line);
    }
    stdout.writeln('nothing written');
    return 1;
  }
  for (final f in made.files.keys) {
    stdout.writeln('wrote    $dir/$f');
  }
  return 0;
}

/// The first line of every generated file.
const generatedHeader = '// GENERATED by tool/season_gen/generate_case.dart — DO NOT EDIT.';

/// Written beside the generated files: what they were made of, and their hashes.
const manifestName = 'generated.manifest.json';

/// Raised when the version of what is made changes how it is made.
/// 2 (STEP 3-9): the season's cases in one file (`<seasonId>_cases.g.dart`),
/// their order in the manifest. 3 (STEP 3-13): the scene tables
/// (`explores`, `investigations`, `dialogues`) and picture options, the
/// imports each file needs. 4 (STEP 3-13B): the story around the puzzles
/// (`talkMissions`, `discoveries`, `endings`). 5: each case's words at
/// Junior and Master (`<caseId>_levels.g.dart`, `<seasonId>_levels.g.dart`)
/// from its `levels.json`.
const generatorVersion = 5;

/// Why nothing was made or written, a line each (as `validate_plan` prints them).
class GenerateFailure implements Exception {
  const GenerateFailure(this.lines);

  final List<String> lines;

  @override
  String toString() => 'GenerateFailure:\n${lines.join('\n')}';
}

/// What the plans make: the files by name (the manifest last), not yet written.
class Generated {
  const Generated(this.seasonId, this.files, this.notes, {this.slice = false, this.target = 'sandbox'});

  final String seasonId;
  final Map<String, String> files;

  /// For the person running it (the approvals' state).
  final List<String> notes;

  /// Cases from the middle of the season, made alone (STEP 3-15A).
  final bool slice;

  /// `sandbox` (played by the tests only) or `game` (the season in the app,
  /// `SeasonCatalog.all`, through [GameRegistry]).
  final String target;

  String get defaultDir => target == 'game' ? '${GameRegistry.dir}/$seasonId' : 'test/sandbox/generated/$seasonId${slice ? '_slice' : ''}';
}

abstract final class CaseGenerator {
  /// The sandbox content of the case plans at [casePaths] (each under its
  /// season's folder, `cases/<caseId>/case.plan.json`) and the season plan
  /// at [seasonPath]. [root]: the repository's root (the places' files).
  /// A [GenerateFailure] with every finding when they cannot be made.
  ///
  /// The cases given are the season's first ones in its play order (its
  /// acts), none left out before the last: a case is unlocked by the one
  /// before it, so a case made without it could never be reached, or would
  /// be the season's first. They are made in that order, whatever the order
  /// of [casePaths].
  ///
  /// With [slice] (STEP 3-15A), the cases given are any run of the season's
  /// cases in play order, none missing between them (a case before them is
  /// opened by the test), and only the places their missions use are made
  /// and must be on disk: a first playable case before the season is drawn.
  ///
  /// With [target] `game` (the Rome integration), the season whole (never a
  /// slice) as the app plays it: the same files, and beside them its
  /// `SeasonContent` (`<seasonId>_content.g.dart`) and its art
  /// (`<seasonId>_art.g.dart`: its map, cover, World Map city and evidence
  /// pictures), written under `lib/data/generated/<seasonId>/` and listed by
  /// [GameRegistry]. It needs the season's map planned and drawn (`art.map`):
  /// a season without its map can never be entered.
  static Generated sandbox({
    required String seasonPath,
    required List<String> casePaths,
    String root = '.',
    String schemaDir = 'tool/season_gen/schema',
    bool slice = false,
    String target = 'sandbox',
  }) {
    final schemas = SchemaSet.load(schemaDir);
    final lines = <String>[];
    void failed(String path, Iterable<String> errors) {
      if (errors.isEmpty) return;
      lines.add('FAILED  $path');
      lines.addAll([for (final e in errors) '  error    $e']);
    }

    if (target != 'sandbox' && target != 'game') throw GenerateFailure(['  error    [target_unknown] --target $target: sandbox or game']);
    if (target == 'game' && slice) throw GenerateFailure(['  error    [game_slice] a season of the game is made whole, never a slice']);

    // 1. The plans as validate_plan checks them.
    final seasonCheck = check(seasonPath, schemas);
    failed(seasonPath, seasonCheck.errors);
    if (seasonCheck.errors.isNotEmpty) throw GenerateFailure(lines);
    final season = PlanFiles.loadSeasonPlan(seasonPath);
    final plans = <(String, CasePlan)>[];
    for (final path in casePaths) {
      final r = check(path, schemas, season: season);
      failed(path, r.errors);
      if (r.errors.isEmpty) plans.add((path, r.casePlan!));
    }
    if (lines.isNotEmpty) throw GenerateFailure(lines);
    final across = [for (final i in ClueGraphCheck.season(season, [for (final (_, p) in plans) p]).issues) if (i.acrossCases && i.isError) 'clues $i'];
    failed('season ${season.seasonId}', across);
    final ids = <String>{};
    final missionIds = <String>{};
    for (final (path, p) in plans) {
      if (!ids.add(p.caseId)) failed(path, ['[case_given_twice] ${p.caseId} given twice']);
      for (final m in p.allMissions) {
        if (!missionIds.add(m.missionId)) failed(path, ['[mission_given_twice] ${m.missionId} is a mission of another case plan too']);
      }
    }
    if (lines.isNotEmpty) throw GenerateFailure(lines);

    // 2. The season's play order: the cases given are its first, none missing.
    final order = season.caseIds;
    plans.sort((a, b) => order.indexOf(a.$2.caseId).compareTo(order.indexOf(b.$2.caseId)));
    final first = slice && plans.isNotEmpty ? order.indexOf(plans.first.$2.caseId) : 0;
    for (final (i, (path, p)) in plans.indexed) {
      if (order.indexOf(p.caseId) != first + i) {
        failed(path, ['[case_missing] ${order[first + i]} comes before ${p.caseId} in ${season.seasonId} and is not given: '
            '${p.caseId} could never be unlocked']);
        break;
      }
    }
    if (lines.isNotEmpty) throw GenerateFailure(lines);

    // 3. Where each case plan is, from its season's folder (the manifest's names).
    final seasonDir = _slashes(File(seasonPath).absolute.parent.path);
    final relative = <String, String>{};
    for (final (path, p) in plans) {
      final abs = _slashes(File(path).absolute.path);
      final want = 'cases/${p.caseId}/case.plan.json';
      if (abs != '$seasonDir/$want') {
        failed(path, ['[case_misplaced] not $want of the season plan\'s folder ($seasonDir)']);
      } else {
        relative[p.caseId] = want;
      }
    }
    if (lines.isNotEmpty) throw GenerateFailure(lines);

    // 4. What the game needs of them. A slice's places are the ones its
    // missions use (each still on disk); the season's others are not made.
    final used = {for (final (_, p) in plans) for (final m in p.allMissions) m.placeId};
    final places = [for (final p in season.places) if (!slice || used.contains(p.placeId)) p];
    final otherPlaces = {
      for (final (i, p) in season.places.indexed)
        if (!places.contains(p)) '\$.places[$i].file',
    };
    final seasonIssues = <String>{};
    final notes = <String>[];
    for (final (path, p) in plans) {
      final found = PlayCheck.casePlan(p, season, root: root);
      failed(path, [for (final i in found) if (i.blocking && !i.inSeason) 'play $i']);
      seasonIssues.addAll([for (final i in found) if (i.blocking && i.inSeason && !otherPlaces.contains(i.path)) 'play $i']);
      // A face not made yet: written without it (STEP 3-15A), and said.
      notes.addAll([for (final i in found) if (!i.blocking) '${p.caseId} $i']);
    }
    failed(seasonPath, seasonIssues);
    if (lines.isNotEmpty) throw GenerateFailure(lines);
    bool onDisk(String file) => File('$root/$file').existsSync();

    // 4b. The game: every case of the season, its map drawn and measured on
    // the very file, its cover on disk when planned.
    if (target == 'game') {
      final art = season.art;
      final all = season.caseIds;
      if (plans.length != all.length) {
        failed(seasonPath, ['[game_cases_missing] the game takes the season whole: ${all.length} cases, ${plans.length} given']);
      }
      final map = art?.map;
      if (map == null) {
        failed(seasonPath, ['[game_map_missing] \$.art.map: a season without its map can never be entered (SeasonAvailability)']);
      } else if (!onDisk(map.file)) {
        failed(seasonPath, ['[game_map_missing] \$.art.map.file: ${map.file} is not on disk']);
      } else if (map.measuredOn case final hash? when hash != ContentHash.ofBytes(File('$root/${map.file}').readAsBytesSync())) {
        failed(seasonPath, ['[map_remeasure] \$.art.map.measuredOn: ${map.file} is not the file its landmarks were measured on']);
      }
      if (art?.cover case final c? when !onDisk(c.file)) failed(seasonPath, ['[game_cover_missing] \$.art.cover.file: ${c.file} is not on disk']);
      if (lines.isNotEmpty) throw GenerateFailure(lines);
    }

    // 4c. The levels (Junior, Master): each case's `levels.json`, checked as
    // its plan is and the same game beyond its words (`CaseLevels`). The
    // game's seasons are played at every level: each case needs its own.
    final levels = <String, (Map<PlanLevel, CasePlan>, Map<PlanLevel, Map<String, String>>)>{};
    for (final (path, p) in plans) {
      final CaseLevels? written;
      try {
        written = CaseLevels.load(path);
      } on PlanFormatException catch (e) {
        failed(path, ['levels ${e.path}: ${e.message}']);
        continue;
      }
      if (written == null) {
        if (target == 'game') {
          failed(path, ['levels [levels_missing] ${CaseLevels.pathFor(path)}: a case of the game is written at every level '
              '(case_levels.dart skeleton, then each line)']);
        }
        continue;
      }
      final found = CaseLevels.checkCase(path, season, schemas, root: root);
      failed(path, [for (final f in found) 'levels $f']);
      if (found.isNotEmpty) continue;
      final json = PlanFiles.readJson(path);
      levels[p.caseId] = ({for (final l in PlanLevel.values) l: CasePlan.fromJson(written.apply(json, l))}, written.glossary);
    }
    if (lines.isNotEmpty) throw GenerateFailure(lines);
    final leveled = plans.isNotEmpty && plans.every((e) => levels.containsKey(e.$2.caseId));
    if (levels.isNotEmpty && !leveled) {
      failed(seasonPath, ['[levels_partial] every case of the season is written at every level, or none: '
          '${[for (final (_, p) in plans) if (!levels.containsKey(p.caseId)) p.caseId].join(', ')} not']);
      throw GenerateFailure(lines);
    }
    // The season's own lines (its outro and finale) at each level, with its cases'.
    SeasonLevels? seasonLevels;
    if (leveled) {
      failed(seasonPath, [for (final f in SeasonLevels.check(seasonPath)) 'levels $f']);
      if (lines.isNotEmpty) throw GenerateFailure(lines);
      seasonLevels = SeasonLevels.load(seasonPath);
    }

    // 5. The approvals: a sandbox is made from drafts too, and says so.
    var approved = true;
    for (final (_, p) in plans) {
      try {
        final r = SeasonApprovals(seasonDir).readiness(p.caseId);
        if (!r.ready) {
          approved = false;
          notes.add('${p.caseId} is not approved (${r.blockers.join('; ')}): '
              '${target == 'game' ? 'in the game as drafted (approve with tool/season_gen/approve.dart)' : 'sandbox content only'}');
        }
      } on Object catch (e) {
        approved = false;
        notes.add('${p.caseId}: the approvals could not be read ($e): ${target == 'game' ? 'in the game as drafted' : 'sandbox content only'}');
      }
    }

    // 6. The files.
    final seasonJson = PlanFiles.readJson(seasonPath);
    final files = <String, String>{
      '${season.seasonId}_season.g.dart': _seasonFile(season, ContentHash.ofJson(seasonJson), places),
      for (final (path, p) in plans) '${p.caseId}.g.dart': _caseFile(p, season, relative[p.caseId]!, ContentHash.ofJson(PlanFiles.readJson(path)), onDisk),
      '${season.seasonId}_cases.g.dart': _casesFile(season, [for (final (_, p) in plans) p]),
      if (leveled) ...{
        for (final (path, p) in plans)
          '${p.caseId}_levels.g.dart': _levelsFile(
            p,
            levels[p.caseId]!,
            season,
            'cases/${p.caseId}/${CaseLevels.fileName}',
            ContentHash.ofJson(PlanFiles.readJson(CaseLevels.pathFor(path))),
            onDisk,
          ),
        '${season.seasonId}_levels.g.dart': _seasonLevelsFile(season, [for (final (_, p) in plans) p], {
          for (final l in PlanLevel.values) l: seasonLevels?.textAt(PlanFiles.readJson(seasonPath), l) ?? const {},
        }),
      },
      if (target == 'game') ...{
        '${season.seasonId}_content.g.dart': _contentFile(season, leveled: leveled),
        '${season.seasonId}_art.g.dart': _artFile(
          season,
          [for (final (_, p) in plans) p],
          SeasonEvidencePictures.of('$seasonDir/assets.manifest.json', [for (final (_, p) in plans) p], onDisk),
        ),
      },
    };
    final manifest = <String, Object?>{
      'generator': 'generate_case.dart',
      'generatorVersion': generatorVersion,
      'target': target,
      if (slice) 'slice': true,
      'seasonId': season.seasonId,
      if (target == 'game') 'seasonNumber': season.number,
      'cases': [for (final (_, p) in plans) p.caseId],
      'approved': approved,
      'inputs': {
        'season.plan.json': ContentHash.ofJson(seasonJson),
        if (seasonLevels != null) SeasonLevels.fileName: ContentHash.ofJson(PlanFiles.readJson(SeasonLevels.pathFor(seasonPath))),
        for (final (path, p) in plans) ...{
          relative[p.caseId]!: ContentHash.ofJson(PlanFiles.readJson(path)),
          if (levels.containsKey(p.caseId))
            'cases/${p.caseId}/${CaseLevels.fileName}': ContentHash.ofJson(PlanFiles.readJson(CaseLevels.pathFor(path))),
        },
      },
      'outputs': {for (final MapEntry(:key, :value) in files.entries) key: ContentHash.ofBytes(utf8.encode(value))},
    };
    files[manifestName] = PlanFiles.encode(manifest);
    return Generated(season.seasonId, files, notes, slice: slice, target: target);
  }

  // ── The game: the season's content and art ─────────────────────────────

  /// The season as the app plays it (`SeasonCatalog.all`, by [GameRegistry]).
  static String _contentFile(SeasonPlan s, {bool leveled = false}) {
    final name = constName(s.seasonId);
    final tables = [...sceneTables.keys, ...storyTables.keys];
    return '$generatedHeader\n// source: season.plan.json and its cases (in play order)\n\n'
        "import 'package:world_mystery/data/mock/season_catalog.dart' show SeasonContent;\n"
        '\n'
        "import '${s.seasonId}_cases.g.dart';\n"
        "${leveled ? "import '${s.seasonId}_levels.g.dart';\n" : ''}"
        "import '${s.seasonId}_season.g.dart';\n"
        '\n'
        '/// Season ${s.number}, ${s.title}: its content as the game plays it, released\n'
        '/// (`SeasonCatalog.all`, listed by `generated_seasons.g.dart`).\n'
        'final ${name}Content = SeasonContent(\n'
        '  info: ${name}InfoJson,\n'
        '  episodes: ${name}Episodes,\n'
        '  places: ${name}Places,\n'
        '  storyGreeting: ${name}StoryGreeting,\n'
        '  learning: ${name}Learning,\n'
        '  languageTopics: ${name}LanguageTopics,\n'
        '  evidenceLinks: ${name}EvidenceLinks,\n'
        '${[for (final t in tables) '  $t: $name${_suffix(t)},\n'].join()}'
        '${leveled ? '  casePatches: ${name}CasePatches,\n  variants: ${name}Variants,\n  writtenLevels: ${name}WrittenLevels,\n  infoLevels: ${name}InfoLevels,\n' : ''}'
        ');\n';
  }

  // ── The levels (Junior, Master) ────────────────────────────────────────

  /// `junior` → `Junior` (a constant's part).
  static String _level(PlanLevel l) => _suffix(l.name);

  /// The case's words a level gives, as `DifficultyContent` lays them over
  /// the case's JSON (`SeasonContent.casePatches`): every text field whole
  /// (so nothing of the case falls back on another level's words), the
  /// words the level adds to the glossary. Never an id, an answer or an
  /// order: `CaseLevels.sameGame` holds the level to its plan's game.
  static Map<String, Object?> levelPatch(CasePlan level, Map<String, String> glossary) {
    final json = episodeJson(level);
    Map<String, Object?> only(Object? from, List<String> keys) => {
      for (final k in keys)
        if ((from as Map)[k] != null) k: from[k],
    };
    Map<String, Object?> mission(Map<String, Object?> m) => {
      ...only(m, ['title', 'location', 'story', 'letterIntro', 'letter', 'question', 'prompt', 'hints', 'successMessage', 'transition', 'orderFeedback']),
      if ((m['options'] as List).isNotEmpty)
        'options': {for (final o in m['options'] as List) (o as Map)['id']: only(o, ['label', 'feedback', 'altText'])},
      'feedback': ?m['feedback'],
      if (m['clue'] != null) 'clue': only(m['clue'], ['title', 'note']),
      'evidence': only(m['evidence'], ['name', 'description']),
      if (m['recall'] case final Map<dynamic, dynamic> r) 'recall': only(r, ['title', 'prompt', 'miss', 'feedback']),
    };
    return {
      ...only(json, ['title', 'synopsis', 'objectives', 'intro', 'caseSummary', 'hook', 'place']),
      if (glossary.isNotEmpty) 'glossary': glossary,
      'missions': {
        for (final m in [...json['missions'] as List, json['finalMission']]) (m as Map)['id']: mission(m.cast<String, Object?>()),
      },
    };
  }

  /// A case at Junior and Master: its words ([levelPatch]) and its puzzle
  /// tables made from its level's plan, as its own are.
  static String _levelsFile(
    CasePlan c,
    (Map<PlanLevel, CasePlan>, Map<PlanLevel, Map<String, String>>) at,
    SeasonPlan season,
    String source,
    String hash,
    bool Function(String file) onDisk,
  ) {
    final name = constName(c.caseId);
    final b = StringBuffer();
    for (final l in PlanLevel.values) {
      final plan = at.$1[l]!;
      final prefix = '$name${_level(l)}';
      b
        ..write('/// Case ${c.caseId} at ${_level(l)}: its words (`SeasonContent.casePatches`).\n')
        ..write('const ${prefix}Patch = <String, Object?>${DartLiteral.of(levelPatch(plan, at.$2[l] ?? const {}))};\n\n')
        ..write(_tableDecls(plan, season, prefix, onDisk, doc: 'at ${_level(l)}'))
        ..write('\n');
    }
    final body = b.toString().trimRight();
    return '${_head(source, hash)}\n${_imports(body)}\n$body\n';
  }

  /// The season's cases at Junior and Master, as `SeasonContent` takes them.
  static String _seasonLevelsFile(SeasonPlan s, List<CasePlan> plans, Map<PlanLevel, Map<String, List<String>>> own) {
    final name = constName(s.seasonId);
    final ids = [for (final p in plans) p.caseId];
    final b = StringBuffer()
      ..write('$generatedHeader\n// source: ${[
        if (own.values.any((t) => t.isNotEmpty)) SeasonLevels.fileName,
        for (final id in ids) 'cases/$id/${CaseLevels.fileName}',
      ].join(', ')}\n\n')
      ..write("import 'package:world_mystery/data/mock/season_catalog.dart' show SeasonContent;\n")
      ..write("import 'package:world_mystery/data/models/difficulty.dart';\n\n")
      ..write([for (final id in ids) "import '${id}_levels.g.dart';\n"].join())
      ..write('\n/// Each case\'s words at Junior and Master (Rookie\'s are the cases\' own).\n')
      ..write('const ${name}CasePatches = <Difficulty, Map<String, Map<String, Object?>>>{\n');
    for (final l in PlanLevel.values) {
      b.write('  Difficulty.${l.name}: {\n');
      for (final id in ids) {
        b.write("    '$id': ${constName(id)}${_level(l)}Patch,\n");
      }
      b.write('  },\n');
    }
    b
      ..write('};\n\n')
      ..write('/// Their puzzle tables at Junior and Master: every entry, made from each level\'s plan.\n')
      ..write('final ${name}Variants = <Difficulty, SeasonContent>{\n');
    for (final l in PlanLevel.values) {
      String spread(String table) => '{${[for (final id in ids) '...${constName(id)}${_level(l)}${_suffix(table)}'].join(', ')}}';
      b
        ..write('  Difficulty.${l.name}: SeasonContent(\n')
        ..write('    info: const {},\n')
        ..write('    episodes: const {},\n')
        ..write('    learning: ${spread('learning')},\n');
      for (final t in [...sceneTables.keys, ...storyTables.keys]) {
        b.write('    $t: ${spread(t)},\n');
      }
      b.write('  ),\n');
    }
    b
      ..write('};\n\n')
      ..write('/// Every case written at every level: nothing falls back on another level\'s words.\n')
      ..write('const ${name}WrittenLevels = <String, Set<Difficulty>>{\n');
    for (final id in ids) {
      b.write("  '$id': {Difficulty.rookie, Difficulty.junior, Difficulty.master},\n");
    }
    b
      ..write('};\n\n')
      ..write('/// The season\'s own lines at Junior and Master (`SeasonContent.infoLevels`):\n')
      ..write('/// its ${SeasonLevels.textKeys.join(' and ')}, as many lines as its own.\n')
      ..write('const ${name}InfoLevels = <Difficulty, Map<String, List<String>>>{\n');
    for (final l in PlanLevel.values) {
      if (own[l]?.isNotEmpty ?? false) b.write('  Difficulty.${l.name}: ${DartLiteral.of(own[l], indent: '  ')},\n');
    }
    b.write('};\n');
    return b.toString();
  }

  /// The World Map artwork's pixel size (`ArtAssets.worldMap`): a city's
  /// `mapAt` is planned in its pixels.
  static const worldMapPixels = (1983, 793);

  /// A landmark's group of places is pressed to this share of its height
  /// when a full group would rise into the map's top margin (as Paris's
  /// Montmartre): `MapWorld.topMargin` 0.15 + `MapWorld.groupRadius` 0.12.
  static const _groupLow = 0.15 + 0.12;

  /// The season's map, cover, World Map city and evidence pictures, as the
  /// game's art tables take them (listed by `generated_season_art.g.dart`).
  static String _artFile(SeasonPlan s, List<CasePlan> plans, Map<String, String> evidencePictures) {
    final name = constName(s.seasonId);
    final art = s.art!;
    final map = art.map!;
    String landmark(String locId) => '_${constName(locId)}';
    final names = {for (final l in s.locations) l.locId: l.name};
    final locOf = {for (final p in s.places) p.placeId: p.locId};
    final b = StringBuffer()
      ..write('$generatedHeader\n// source: season.plan.json art, assets.manifest.json\n\n')
      ..write("import 'dart:ui' show Offset, Size;\n\n")
      ..write("import 'package:flutter/painting.dart' show Alignment;\n")
      ..write("import 'package:world_mystery/features/mission_map/map_world.dart' show MapLandmark, SeasonLandmark, SeasonMap;\n")
      ..write("import 'package:world_mystery/features/world_map/world_cities.dart' show WorldCity;\n")
      ..write("import 'package:world_mystery/widgets/art_assets.dart' show SeasonCover;\n\n")
      ..write('// The landmarks drawn on the map, at the centre of each one\'s drawing,\n')
      ..write('// measured on ${map.file}${map.measuredOn == null ? '' : ' (${map.measuredOn!.substring(0, 23)}…)'}.\n');
    for (final l in map.landmarks) {
      b.write("const ${landmark(l.locId)} = SeasonLandmark('${l.locId}', ${DartLiteral.of(names[l.locId])}, "
          'Offset(${_n(l.at.x)} / ${map.width}, ${_n(l.at.y)} / ${map.height}));\n');
    }
    final low = [for (final l in map.landmarks) if (l.at.y / map.height < _groupLow) l.locId];
    b
      ..write('\n/// The Mission Map of season ${s.seasonId}: every mission at its place\'s landmark.\n')
      ..write('const ${name}Map = SeasonMap(\n')
      ..write("  artwork: '${map.file}',\n")
      ..write('  pixels: Size(${map.width}, ${map.height}),\n')
      ..write('  aspect: ${map.width} / ${map.height},\n')
      ..write('  landmarks: [${[for (final l in map.landmarks) landmark(l.locId)].join(', ')}],\n')
      ..write('  missionLandmarks: <String, MapLandmark>{\n');
    for (final p in plans) {
      for (final m in p.allMissions) {
        b.write("    '${m.missionId}': ${landmark(locOf[m.placeId]!)},\n");
      }
    }
    b
      ..write('  },\n')
      ..write(low.isEmpty ? '' : '  groupHeights: <MapLandmark, double>{${[for (final l in low) '${landmark(l)}: 0.6'].join(', ')}},\n')
      ..write('  namesClearOfCurrent: true,\n')
      ..write(');\n');
    if (art.cover case final c?) {
      String align(ScenePoint p) => 'Alignment(${_n(p.x)}, ${_n(p.y)})';
      b
        ..write('\n/// Its cover (portrait, no text) and how the screens frame it.\n')
        ..write('const ${name}Cover = SeasonCover(\n')
        ..write("  file: '${c.file}',\n")
        ..write('  pixels: Size(${c.width}, ${c.height}),\n')
        ..write('  archiveLook: ${align(c.archiveLook)},\n')
        ..write('  crop: ${align(c.crop)},\n')
        ..write('  push: ${align(c.push)},\n')
        ..write(');\n');
    }
    if (art.worldCity case final w?) {
      final (ww, wh) = worldMapPixels;
      b
        ..write('\n/// Its city on the World Map.\n')
        ..write('const ${name}WorldCity = WorldCity(\n')
        ..write("  id: '${w.cityId}',\n")
        ..write('  name: ${DartLiteral.of(s.city)},\n')
        ..write('  latitude: ${w.latitude},\n')
        ..write('  longitude: ${w.longitude},\n')
        ..write("  seasonId: '${s.seasonId}',\n")
        ..write(w.mapAt == null ? '' : '  mapAt: Offset(${_n(w.mapAt!.x)} / $ww, ${_n(w.mapAt!.y)} / $wh),\n')
        ..write(');\n');
    }
    b
      ..write('\n/// Its evidence shown by a picture (`ArtAssets.evidencePictures`), by evidence id:\n')
      ..write('/// each picture made for it (assets.manifest.json, on disk).\n')
      ..write('const ${name}EvidencePictures = <String, String>${DartLiteral.of(evidencePictures)};\n');
    return b.toString();
  }

  static String _slashes(String path) => path.replaceAll(r'\', '/');

  /// `s9_sandbox` → `s9Sandbox`.
  static String constName(String id) {
    final parts = id.split('_');
    return [parts.first, for (final p in parts.skip(1)) if (p.isNotEmpty) '${p[0].toUpperCase()}${p.substring(1)}'].join();
  }

  static String _head(String source, String hash) => '$generatedHeader\n// source: $source $hash\n';

  // ── The season ─────────────────────────────────────────────────────────

  static String _seasonFile(SeasonPlan s, String hash, List<PlacePlan> shown) {
    final name = constName(s.seasonId);
    final info = <String, Object?>{
      'id': s.seasonId,
      'number': s.number,
      'title': s.title,
      'tagline': s.tagline,
      'city': s.city,
      'cases': s.plannedCases,
      if (s.outro.isNotEmpty) 'outro': s.outro,
      if (s.finale.isNotEmpty) 'finale': s.finale,
      'figures': [for (final f in s.figures) f.toJson()],
      if (s.prologue case final p?) 'prologue': p.toJson(),
    };
    final places = {
      for (final p in shown)
        p.placeId: DartCall('ScenePlace', named: {
          'file': p.file,
          'pixels': DartCall('ScenePixels', positional: [p.width.toDouble(), p.height.toDouble()]),
        }),
    };
    return '${_head('season.plan.json', hash)}\n'
        "import 'package:world_mystery/data/models/scene_explore.dart' show ScenePixels;\n"
        "import 'package:world_mystery/data/models/scene_place.dart';\n"
        '\n'
        '/// Season ${s.seasonId} as `Season.fromJson` reads it.\n'
        'const ${name}InfoJson = <String, dynamic>${DartLiteral.of(info)};\n'
        '\n'
        "/// The pictures of its places (`SeasonContent.places`).\n"
        'const ${name}Places = <String, ScenePlace>${DartLiteral.of(places)};\n'
        '\n'
        '/// `SeasonContent.storyGreeting`.\n'
        'const ${name}StoryGreeting = ${s.storyGreeting ?? true};\n';
  }

  // ── The season's cases ─────────────────────────────────────────────────

  /// Every case made, in play order, as `SeasonContent` takes them: a new
  /// case of the season is in the game's content with no line written by hand.
  static String _casesFile(SeasonPlan s, List<CasePlan> plans) {
    final name = constName(s.seasonId);
    final caseIds = [for (final p in plans) p.caseId];
    String spread(String suffix) => '{\n${[for (final id in caseIds) '  ...${constName(id)}$suffix,\n'].join()}}';
    String byCase(String suffix) => DartLiteral.of({for (final id in caseIds) id: DartCode('${constName(id)}$suffix')});
    final body = '/// The cases of season ${s.seasonId} made, in play order (`SeasonContent.episodes`).\n'
        'const ${name}Episodes = <String, Map<String, dynamic>>${byCase('Json')};\n'
        '\n'
        '/// Their missions\' learning design (`SeasonContent.learning`).\n'
        'const ${name}Learning = <String, LearningObjective>${spread('Learning')};\n'
        '\n'
        '/// Their language topics (`SeasonContent.languageTopics`).\n'
        'const ${name}LanguageTopics = <String, CaseLanguageTopic>${byCase('LanguageTopic')};\n'
        '\n'
        '/// Their evidence matched to earlier evidence (`SeasonContent.evidenceLinks`).\n'
        'const ${name}EvidenceLinks = <String, EvidenceLink>${spread('EvidenceLinks')};\n'
        '${[
          for (final MapEntry(key: table, value: model) in sceneTables.entries)
            '\n/// Their missions played on `$table` (`SeasonContent.$table`).\n'
                'const $name${_suffix(table)} = <String, $model>${spread(_suffix(table))};\n',
        ].join()}'
        '${[
          for (final MapEntry(key: table, value: (model, doc)) in storyTables.entries)
            '\n/// Their $doc (`SeasonContent.$table`).\n'
                '${_keyword(table, [for (final p in plans) ...p.allMissions])} $name${_suffix(table)} = <String, $model>${spread(_suffix(table))};\n',
        ].join()}';
    return '$generatedHeader\n// source: ${caseIds.join(', ')} (in play order)\n\n'
        '${_imports(body)}\n'
        '${[for (final id in caseIds) "import '$id.g.dart';\n"].join()}'
        '\n'
        '$body';
  }

  /// Where the game's types a generated file names are declared.
  static const _libraries = {
    'dart:ui': ['Offset', 'Rect'],
    'package:world_mystery/data/models/case_talk.dart': ['EndingLine', 'TalkLine', 'TalkMission', 'TalkScene', 'TalkSpeaker', 'TalkVoice'],
    'package:world_mystery/data/models/dialogue.dart': [
      'DialogueAnswer', 'DialogueDeduction', 'DialogueQuestion', 'DialogueScene', 'DialogueSpeaker', 'DialogueStatement', //
    ],
    'package:world_mystery/data/models/discovery.dart': ['Discovery', 'DiscoveryTiming', 'DiscoveryType'],
    'package:world_mystery/data/models/investigation.dart': ['InvestigationFind', 'InvestigationScene', 'InvestigationSpot'],
    'package:world_mystery/data/models/learning.dart': [],
    'package:world_mystery/data/models/scene_exhibit.dart': ['EvidenceLink'],
    'package:world_mystery/data/models/scene_explore.dart': ['ExploreKind', 'ExplorePicture', 'ExploreScene', 'ExploreSpot', 'ScenePixels'],
  };

  /// The imports of [body]: each library whose types it names, showing only
  /// those (the learning models whole, as before).
  static String _imports(String body) {
    final b = StringBuffer();
    for (final MapEntry(key: lib, value: names) in _libraries.entries) {
      if (names.isEmpty) {
        b.write("import '$lib';\n");
        continue;
      }
      final used = [for (final n in names) if (RegExp('\\b$n\\b').hasMatch(body)) n];
      if (used.isNotEmpty) b.write("import '$lib' show ${used.join(', ')};\n");
    }
    return b.toString();
  }

  // ── A case ─────────────────────────────────────────────────────────────

  /// [c]'s missions' learning design (`SeasonContent.learning`).
  static Map<String, Object?> _learning(CasePlan c) => {
    for (final m in c.allMissions)
      m.missionId: DartCall('LearningObjective', named: {
        'dependency': DartCode('LanguageDependency.${m.learning.dependency}'),
        'level': DartCode('LearningLevel.${m.learning.level}'),
        'objective': m.learning.objective,
        if (m.learning.skill case final s?) 'skill': DartCode('LanguageSkill.$s'),
        if (m.learning.expressions.isNotEmpty) 'expressions': m.learning.expressions,
        'recallFrom': ?m.learning.recallFrom,
      }),
  };

  /// [c]'s learning and its puzzle tables (scenes, then the story around
  /// them), each a constant named [prefix] and the table: what a level's
  /// `SeasonContent` holds of the case ([doc]: which level, for the comments).
  static String _tableDecls(CasePlan c, SeasonPlan season, String prefix, bool Function(String file) onDisk, {required String doc}) {
    final all = c.allMissions;
    return "/// Its missions' learning design $doc.\n"
        'const ${prefix}Learning = <String, LearningObjective>${DartLiteral.of(_learning(c))};\n'
        '${[
          for (final MapEntry(key: table, value: model) in sceneTables.entries)
            '\n/// Its missions played on `$table` $doc.\n'
                'const $prefix${_suffix(table)} = <String, $model>${DartLiteral.of({
                  for (final m in all)
                    if (m.puzzle.engineTable == table) m.missionId: ?scene(m),
                })};\n',
        ].join()}'
        '${[
          for (final MapEntry(key: table, value: (model, doc2)) in storyTables.entries)
            '\n/// Its $doc2 $doc.\n'
                '${_keyword(table, all)} $prefix${_suffix(table)} = <String, $model>${DartLiteral.of({
                  for (final m in all) m.missionId: ?story(table, m, season, onDisk: onDisk),
                })};\n',
        ].join()}';
  }

  static String _caseFile(CasePlan c, SeasonPlan season, String source, String hash, bool Function(String file) onDisk) {
    final name = constName(c.caseId);
    final all = c.allMissions;
    final learning = _learning(c);
    final links = <String, Object?>{
      for (final m in all)
        for (final input in m.clueInputs)
          if (input.use == ClueUse.evidenceLink)
            m.clueOutputs.evidence: DartCall('EvidenceLink', named: {'to': input.ref, 'line': m.play!.evidenceLinkLine!}),
    };
    final topic = DartCall('CaseLanguageTopic', named: {'title': c.learningGoal.title, 'titleKo': c.learningGoal.titleKo});
    final body = '/// Case ${c.caseId} as `Episode.fromJson` reads it.\n'
        'const ${name}Json = <String, dynamic>${DartLiteral.of(episodeJson(c))};\n'
        '\n'
        "/// Its missions' learning design (`SeasonContent.learning`).\n"
        'const ${name}Learning = <String, LearningObjective>${DartLiteral.of(learning)};\n'
        '\n'
        '/// Its language topic (`SeasonContent.languageTopics`).\n'
        'const ${name}LanguageTopic = ${DartLiteral.of(topic)};\n'
        '\n'
        '/// Its evidence matched to earlier evidence (`SeasonContent.evidenceLinks`).\n'
        'const ${name}EvidenceLinks = <String, EvidenceLink>${DartLiteral.of(links)};\n'
        '${[
          for (final MapEntry(key: table, value: model) in sceneTables.entries)
            '\n/// Its missions played on `$table` (`SeasonContent.$table`): their scenes,\n'
                '/// places on their pictures as the pictures\' pixels (fractions at run time).\n'
                'const $name${_suffix(table)} = <String, $model>${DartLiteral.of({
                  for (final m in all)
                    if (m.puzzle.engineTable == table) m.missionId: ?scene(m),
                })};\n',
        ].join()}'
        '${[
          for (final MapEntry(key: table, value: (model, doc)) in storyTables.entries)
            '\n/// Its $doc (`SeasonContent.$table`).\n'
                '${_keyword(table, all)} $name${_suffix(table)} = <String, $model>${DartLiteral.of({
                  for (final m in all) m.missionId: ?story(table, m, season, onDisk: onDisk),
                })};\n',
        ].join()}';
    return '${_head(source, hash)}\n${_imports(body)}\n$body';
  }

  /// [c] as the game's case JSON, its keys in `Episode.toJson`'s order (and
  /// its missions' in `Mission.toJson`'s), so the game reads it back as it is.
  static Map<String, Object?> episodeJson(CasePlan c) {
    final w = c.play!;
    final all = c.allMissions;
    return {
      'id': c.caseId,
      'number': c.number,
      'title': c.title,
      'synopsis': c.synopsis,
      'objectives': w.objectives.isEmpty ? [c.goal] : w.objectives,
      'intro': w.intro,
      'missions': [for (final (i, m) in c.missions.indexed) _mission(m, i, all[i + 1].missionId)],
      'finalMission': _mission(c.finalMission, all.length - 1, null),
      'glossary': w.glossary,
      'caseSummary': w.caseSummary!,
      if (w.keyWords.isNotEmpty) 'keyWords': w.keyWords,
      'hook': c.hook,
      'place': ?w.place,
      'seasonId': c.seasonId,
    };
  }

  static Map<String, Object?> _mission(MissionPlan m, int index, String? next) {
    final w = m.play!;
    final a = m.puzzle.answerSpec;
    final recall = [for (final c in m.clueInputs) if (c.use == ClueUse.recall) c.ref];
    return {
      'id': m.missionId,
      'number': index + 1,
      'title': w.title!,
      'location': w.location!,
      'story': w.story,
      'sceneKey': m.placeId,
      'letterIntro': w.letterIntro!,
      'letter': w.letter!,
      'type': m.puzzle.missionType,
      'question': w.question!,
      'prompt': ?w.prompt,
      'options': [for (final o in a.options) o.toJson()],
      'answer': a.answer,
      'acceptedAnswers': a.acceptedAnswers,
      'codeLength': ?a.codeLength,
      'codeFormat': ?a.codeFormat,
      if (a.dialSymbols.isNotEmpty) 'dialSymbols': a.dialSymbols,
      'hints': w.hints,
      if (w.clue case final clue?) 'clue': {'id': m.clueOutputs.clue!, ...clue.toJson()},
      'evidence': {'id': m.clueOutputs.evidence, ...w.evidence!.toJson()},
      'successMessage': w.successMessage!,
      if (w.transition.isNotEmpty) 'transition': w.transition,
      'nextMissionId': ?next,
      'skills': <Object?>[],
      'mapX': w.mapX!,
      'mapY': w.mapY!,
      if (w.feedback.isNotEmpty) 'feedback': w.feedback,
      'orderFeedback': ?w.orderFeedback,
      if (recall.length == 1) 'recall': {'evidence': recall.single, ...?w.recall?.toJson()},
      if (w.hideOptionNames == true) 'hideOptionNames': true,
      'lockTitle': ?w.lockTitle,
    };
  }

  // ── Scenes (STEP 3-13) ─────────────────────────────────────────────────

  /// The scene tables a case file writes, by their `SeasonContent` name:
  /// its Dart model and the plan's scene of each mission played on it.
  static const sceneTables = {
    'explores': 'ExploreScene',
    'investigations': 'InvestigationScene',
    'dialogues': 'DialogueScene',
  };

  /// `explores` → `Explores` (a constant's suffix).
  static String _suffix(String table) => '${table[0].toUpperCase()}${table.substring(1)}';

  /// [m]'s scene as its engine's model, or null when it has none.
  static DartCall? scene(MissionPlan m) {
    final w = m.play;
    if (w == null) return null;
    return switch (m.puzzle.engineTable) {
      'explores' => w.explore == null ? null : _explore(w.explore!),
      'investigations' => w.search == null ? null : _search(w.search!, m.puzzle.answerSpec.answer),
      'dialogues' => w.dialogue == null ? null : _dialogue(w.dialogue!, m.puzzle.answerSpec.answer),
      _ => null,
    };
  }

  /// A number of a picture's pixels: written whole when it is.
  static String _n(double v) => v == v.truncateToDouble() ? '${v.toInt()}' : '$v';

  /// [r] on a [w]×[h] picture as the fractions the game keeps (a constant
  /// expression, its pixels as measured on the file).
  static DartCode _rect(SceneRect r, int w, int h) =>
      DartCode('Rect.fromLTRB(${_n(r.left)} / $w, ${_n(r.top)} / $h, ${_n(r.right)} / $w, ${_n(r.bottom)} / $h)');

  static DartCode _point(ScenePoint p, int w, int h) => DartCode('Offset(${_n(p.x)} / $w, ${_n(p.y)} / $h)');

  static List<DartCode> _rects(List<SceneRect> rs, int w, int h) => [for (final r in rs) _rect(r, w, h)];

  static DartCall _empty(EmptySpotPlan s, int w, int h) =>
      DartCall('InvestigationSpot', named: {'label': s.label, 'areas': _rects(s.areas, w, h), 'line': s.line});

  static DartCall _explore(ExplorePlan s) {
    final (w, h) = (s.picture.width, s.picture.height);
    return DartCall('ExploreScene', named: {
      'picture': s.picture.file,
      'pixels': DartCall('ScenePixels', positional: [w.toDouble(), h.toDouble()]),
      'place': s.place,
      'task': s.task,
      'nextTask': s.nextTask,
      'spots': [
        for (final x in s.spots)
          DartCall('ExploreSpot', named: {
            'id': x.id,
            'kind': DartCode('ExploreKind.${x.kind}'),
            'title': x.title,
            'label': x.label,
            'areas': _rects(x.areas, w, h),
            'mark': _point(x.mark, w, h),
            'line': ?x.line,
            'requires': ?x.requires,
            'lockedLine': ?x.lockedLine,
            'unreadLine': ?x.unreadLine,
          }),
      ],
      'others': [for (final o in s.others) _empty(o, w, h)],
      'missLine': s.missLine,
      'choiceTitle': s.choiceTitle,
      'choiceHow': s.choiceHow,
      'choices': [
        for (final c in s.choices) DartCall('ExplorePicture', named: {'optionId': c.optionId, 'picture': c.picture, 'description': c.description}),
      ],
      'pictureAspect': DartCode('${s.choicePixels.$1} / ${s.choicePixels.$2}'),
      'guideAt': _point(s.guideAt, w, h),
      if (s.inside case final r?) 'inside': _rect(r, w, h),
      if (s.opening case final r?) 'opening': _rect(r, w, h),
      'documentLabel': ?s.documentLabel,
    });
  }

  static DartCall _search(SearchPlan s, String answer) {
    final (w, h) = (s.picture.width, s.picture.height);
    return DartCall('InvestigationScene', named: {
      'picture': s.picture.file,
      'pixels': DartCall('ScenePixels', positional: [w.toDouble(), h.toDouble()]),
      'task': s.task,
      'documentTitle': s.documentTitle,
      'finds': [
        for (final f in s.finds)
          DartCall('InvestigationFind', named: {
            'id': f.id,
            'name': f.name,
            'title': f.title,
            'reportLine': f.reportLine,
            'spot': f.spot,
            'areas': _rects(f.areas, w, h),
            'foundLine': f.foundLine,
            'picture': f.picture.file,
            'at': _point(f.at, w, h),
            'width': DartCode('${_n(f.width)} / $w'),
            'pictureAspect': DartCode('${f.picture.width} / ${f.picture.height}'),
            'squash': ?f.squash,
            'turn': ?f.turn,
          }),
      ],
      'spots': [for (final o in s.spots) _empty(o, w, h)],
      'answer': answer,
      'missLine': s.missLine,
      'doneLine': s.doneLine,
      'arrival': s.arrival,
      'guideAt': _point(s.guideAt, w, h),
      if (s.opening case final r?) 'opening': _rect(r, w, h),
      if (s.inside case final r?) 'inside': _rect(r, w, h),
      'startLabel': ?s.startLabel,
      'documentLabel': ?s.documentLabel,
    });
  }

  static DartCall _dialogue(DialoguePlan s, String answer) {
    final d = s.deduction;
    return DartCall('DialogueScene', named: {
      'place': s.place,
      'background': s.background,
      'goal': s.goal,
      'how': s.how,
      'guide': s.guide,
      'speakers': [
        for (final x in s.witnesses)
          DartCall('DialogueSpeaker', named: {
            'id': x.id,
            'name': x.name,
            'title': x.title,
            'portrait': x.portrait,
            'description': x.description,
            'greeting': x.greeting,
            'answers': {
              for (final q in s.questions)
                if (x.answers[q.id] case final a?)
                  q.id: DartCall('DialogueAnswer', positional: [a.line], named: {if (a.thing != null) 'statementId': '${x.id}.${q.id}'}),
            },
            if (x.face case (final fx, final fy)) 'face': DartCode('Offset($fx, $fy)'),
          }),
      ],
      'questions': [for (final q in s.questions) DartCall('DialogueQuestion', named: {'id': q.id, 'text': q.text})],
      'statements': [
        for (final MapEntry(key: id, value: (x, q, a)) in s.statements.entries)
          DartCall('DialogueStatement', named: {'id': id, 'speakerId': x.id, 'about': q, 'text': a.line, 'thing': a.thing!}),
      ],
      'deduction': DartCall('DialogueDeduction', named: {
        'topic': d.topic,
        'pair': DartCode('{${d.pair.map(DartLiteral.string).join(', ')}}'),
        'answer': answer,
        for (final k in TalkDeductionPlan.requiredLines) k: d.lines[k],
        if (d.then.isNotEmpty) 'then': DartCode('{${d.then.map(DartLiteral.string).join(', ')}}'),
        for (final k in TalkDeductionPlan.thenLines) k: ?d.lines[k],
        'witnesses': ?d.witnesses,
      }),
    });
  }

  // ── The story around the puzzles (STEP 3-13B) ──────────────────────────

  /// The `SeasonContent` tables of the story around a puzzle a case file
  /// writes, each optional for a mission: their entries' type, and what
  /// they hold (for the files' comments).
  static const storyTables = {
    'talkMissions': ('TalkMission', "missions' talks before and after their puzzles"),
    'discoveries': ('Discovery', "missions' own Discovery Moments"),
    'endings': ('List<EndingLine>', "finals' endings after their answers"),
  };

  /// A talk's scene cannot be a constant (`TalkScene` checks its steps when
  /// made): the talks of [missions] are `final` when there are any.
  static String _keyword(String table, List<MissionPlan> missions) =>
      table == 'talkMissions' && missions.any((m) => m.play?.talk != null) ? 'final' : 'const';

  /// [m]'s entry in story table [table], or null when its plan has none.
  /// A face is written only when [onDisk] holds its file (STEP 3-15A):
  /// one not made yet is left out, never stood in for.
  static Object? story(String table, MissionPlan m, SeasonPlan season, {bool Function(String file)? onDisk}) {
    String? face(String? file) => file != null && (onDisk?.call(file) ?? true) ? file : null;
    final w = m.play;
    if (w == null) return null;
    return switch (table) {
      'talkMissions' => w.talk == null ? null : _talkMission(m, w.talk!, season, face(w.talk!.portrait)),
      'discoveries' => w.discovery == null ? null : _discovery(w.discovery!),
      'endings' => w.ending.isEmpty ? null : [for (final l in w.ending) _endingLine(l, m, season, face(l.portrait))],
      _ => null,
    };
  }

  /// The picture of [m]'s place: the talks and the ending are over it.
  static String _placeFile(MissionPlan m, SeasonPlan season) => season.places.firstWhere((p) => p.placeId == m.placeId).file;

  /// [charId]'s name plate, as the game's talks print it.
  static String _nameOf(String charId, SeasonPlan season) =>
      season.characters.firstWhere((c) => c.charId == charId).name.toUpperCase();

  static DartCall _talkLine(TalkLinePlan l) => switch (l.by) {
    TalkBy.speaker => DartCall('TalkLine', positional: [l.text]),
    TalkBy.detective => DartCall('TalkLine.detective', positional: [l.text]),
    TalkBy.narrator => DartCall('TalkLine.narrator', positional: [l.text]),
  };

  static DartCall _talkMission(MissionPlan m, MissionTalkPlan t, SeasonPlan season, String? portrait) {
    final speaker = DartConst(DartCall('TalkSpeaker', named: {
      'id': t.speaker,
      'name': _nameOf(t.speaker, season),
      if (portrait case final p?) 'portraits': {'base': p},
    }));
    // Only listened to: finished once its lines are heard.
    DartCall scene(String part, TalkPartPlan p) => DartCall('TalkScene', named: {
      'id': '${m.missionId}:$part',
      'speaker': speaker,
      'goal': t.goal,
      'opening': DartConst([for (final l in p.lines) _talkLine(l)]),
      'finishWhen': const DartCode('const {}'),
      'place': m.play!.location!,
      'background': _placeFile(m, season),
      'finishLabel': ?p.finishLabel,
    });
    return DartCall('TalkMission', named: {
      if (t.before case final b?) 'before': scene('before', b),
      if (t.after case final a?) 'after': scene('after', a),
    });
  }

  static DartCall _discovery(DiscoveryPlan d) => DartCall('Discovery', named: {
    'type': DartCode('DiscoveryType.${d.type}'),
    'timing': DartCode('DiscoveryTiming.${d.timingOrDefault}'),
    'title': d.title,
    'detail': d.detail,
    if (d.showEvidence == true) 'showEvidence': true,
    if (d.seasonClue == true) 'seasonClue': true,
    'note': ?d.note,
  });

  static DartCall _endingLine(EndingLinePlan l, MissionPlan m, SeasonPlan season, String? portrait) => DartCall('EndingLine', positional: [
    l.text,
  ], named: {
    if (l.by != TalkBy.narrator) 'voice': DartCode('TalkVoice.${l.by.name}'),
    if (l.speaker case final s?) 'name': _nameOf(s, season),
    'portrait': ?portrait,
    'background': _placeFile(m, season),
    'evidenceId': ?l.evidence,
  });
}

/// The generated files on disk.
abstract final class GeneratedFiles {
  /// [text] as it was made: a Windows checkout's CRLF read as LF.
  static String _lf(String text) => text.replaceAll('\r\n', '\n');

  /// The files of [files] that [dir] does not hold as they are (missing or other).
  static List<String> stale(String dir, Map<String, String> files) => [
    for (final MapEntry(:key, :value) in files.entries)
      if (!File('$dir/$key').existsSync() || _lf(File('$dir/$key').readAsStringSync()) != value) key,
  ];

  /// Writes [files] into [dir]: every one to a file beside it first, and
  /// only once all of them are whole on disk is each moved over the one it
  /// replaces, the manifest last. A [GenerateFailure] (nothing written) when
  /// a file there was not made by the generator, or was changed since
  /// ([force]: written over all the same), or when one cannot be written
  /// (the ones written beside are taken away). The warnings: files in [dir]
  /// the generator does not make, left as they are.
  ///
  /// The moves are not one step: should one fail midway (the disk, another
  /// program holding the file), the files moved before it are new and the
  /// manifest is still the old one, so the next run finds them changed since
  /// it was made and writes nothing without `--force`; never a mix that
  /// passes `--check`.
  static List<String> write(String dir, Map<String, String> files, {bool force = false}) {
    final manifest = File('$dir/$manifestName');
    Map<String, Object?> recorded = const {};
    if (manifest.existsSync()) {
      try {
        recorded = ((jsonDecode(manifest.readAsStringSync()) as Map)['outputs'] as Map).cast<String, Object?>();
      } on Object {
        if (!force) throw GenerateFailure(['  error    [hand_edited] $dir/$manifestName: not a manifest the generator wrote (--force to write over it)']);
      }
    }
    final errors = <String>[];
    for (final name in files.keys.where((n) => n != manifestName)) {
      final f = File('$dir/$name');
      if (!f.existsSync() || force) continue;
      final text = _lf(f.readAsStringSync());
      if (!text.startsWith(generatedHeader)) {
        errors.add('  error    [hand_edited] $dir/$name: not a generated file (no GENERATED header): never written over');
      } else if (recorded[name] != ContentHash.ofBytes(utf8.encode(text))) {
        errors.add('  error    [hand_edited] $dir/$name: changed since it was generated (--force to write over it)');
      }
    }
    if (errors.isNotEmpty) throw GenerateFailure(errors);
    final warnings = <String>[
      if (Directory(dir).existsSync())
        for (final f in Directory(dir).listSync().whereType<File>())
          if (!files.containsKey(f.uri.pathSegments.last)) '${f.path}: not made by the generator, left as it is',
    ];
    Directory(dir).createSync(recursive: true);
    final parts = {for (final key in files.keys) key: File('$dir/$key.part')};
    try {
      for (final MapEntry(:key, :value) in files.entries) {
        parts[key]!.writeAsStringSync(value, flush: true);
      }
    } on FileSystemException catch (e) {
      for (final part in parts.values) {
        if (part.existsSync()) part.deleteSync();
      }
      throw GenerateFailure(['  error    [write_failed] ${e.path}: ${e.message}']);
    }
    for (final MapEntry(:key, value: part) in parts.entries) {
      part.renameSync('$dir/$key');
    }
    return warnings;
  }
}

/// A season's evidence shown by a picture (the Rome integration): each
/// picture of its asset manifest made for an evidence of its cases (its
/// `subject` an evidence id), its file on disk. One evidence, one picture.
abstract final class SeasonEvidencePictures {
  static Map<String, String> of(String manifestPath, List<CasePlan> plans, bool Function(String file) onDisk) {
    final manifest = File(manifestPath);
    if (!manifest.existsSync()) return const {};
    final evidence = {
      for (final p in plans)
        for (final m in p.allMissions) m.clueOutputs.evidence,
    };
    final assets = ((jsonDecode(manifest.readAsStringSync()) as Map)['assets'] as List).cast<Map>();
    final out = <String, String>{};
    for (final a in assets) {
      final subject = '${a['subject']}', file = '${a['outputPath']}';
      if (evidence.contains(subject) && a['status'] == 'generated' && onDisk(file)) out.putIfAbsent(subject, () => file);
    }
    return Map.fromEntries(out.entries.toList()..sort((a, b) => a.key.compareTo(b.key)));
  }
}

/// The seasons of the game made from plans (the Rome integration):
/// `lib/data/generated/<seasonId>/` each (`generate_season.dart --target
/// game`), and in [dir] the two lists the game reads them by, made from
/// the seasons' manifests there, in season order:
///
/// * `generated_seasons.g.dart`: their `SeasonContent`s (`SeasonCatalog.all`);
/// * `generated_season_art.g.dart`: their maps (`SeasonMap.bySeason`),
///   covers (`ArtAssets.seasonCovers`), World Map cities (`WorldCities.all`)
///   and evidence pictures (`ArtAssets.evidencePictures`).
///
/// A new season of the game is these two lists made again: no line of the
/// game written by hand.
abstract final class GameRegistry {
  static const dir = 'lib/data/generated';

  /// The seasons whose game manifests are in [dir] (with [adding], one
  /// being made now), as (season number, season id, its art file's names).
  static List<(int, String, Set<String>)> seasons({String root = '.', Generated? adding}) {
    final found = <String, (int, String, Set<String>)>{};
    final base = Directory('$root/$dir');
    if (base.existsSync()) {
      for (final d in base.listSync().whereType<Directory>()) {
        final m = File('${d.path}/$manifestName');
        if (!m.existsSync()) continue;
        final json = jsonDecode(m.readAsStringSync()) as Map;
        if (json['target'] != 'game') continue;
        final id = '${json['seasonId']}';
        final art = File('${d.path}/${id}_art.g.dart');
        found[id] = (json['seasonNumber'] as int, id, art.existsSync() ? _artNames(art.readAsStringSync(), id) : {});
      }
    }
    if (adding != null) {
      final json = jsonDecode(adding.files[manifestName]!) as Map;
      found[adding.seasonId] = (json['seasonNumber'] as int, adding.seasonId, _artNames(adding.files['${adding.seasonId}_art.g.dart'] ?? '', adding.seasonId));
    }
    return found.values.toList()..sort((a, b) => a.$1.compareTo(b.$1));
  }

  /// Which of a season's art its art file declares (`Map`, `Cover`, `WorldCity`).
  static Set<String> _artNames(String text, String seasonId) {
    final name = CaseGenerator.constName(seasonId);
    return {for (final part in ['Map', 'Cover', 'WorldCity']) if (text.contains('const $name$part = ')) part};
  }

  /// The two lists and their manifest, as [seasons] make them.
  static Map<String, String> files(List<(int, String, Set<String>)> seasons) {
    String imports(String suffix) => [for (final (_, id, _) in seasons) "import '$id/${id}_$suffix.g.dart';\n"].join();
    String entries(String part, String Function(String id, String name) entry) =>
        [for (final (_, id, art) in seasons) if (part.isEmpty || art.contains(part)) entry(id, CaseGenerator.constName(id))].join();
    final contents = '$generatedHeader\n// source: $dir/*/generated.manifest.json (target game, in season order)\n\n'
        "import 'package:world_mystery/data/mock/season_catalog.dart' show SeasonContent;\n\n"
        '${imports('content')}\n'
        '/// The seasons of the game made from their plans, in season order, after\n'
        '/// London and Paris (`SeasonCatalog.all`).\n'
        'final generatedSeasons = <SeasonContent>[\n${entries('', (id, n) => '  ${n}Content,\n')}];\n';
    final art = '$generatedHeader\n// source: $dir/*/generated.manifest.json (target game, in season order)\n\n'
        "import 'package:world_mystery/features/mission_map/map_world.dart' show SeasonMap;\n"
        "import 'package:world_mystery/features/world_map/world_cities.dart' show WorldCity;\n"
        "import 'package:world_mystery/widgets/art_assets.dart' show SeasonCover;\n\n"
        '${imports('art')}\n'
        '/// Their maps, by season id (`SeasonMap.bySeason`).\n'
        "const generatedSeasonMaps = <String, SeasonMap>{\n${entries('Map', (id, n) => "  '$id': ${n}Map,\n")}};\n\n"
        '/// Their covers, by season id (`ArtAssets.seasonCovers`).\n'
        "const generatedSeasonCovers = <String, SeasonCover>{\n${entries('Cover', (id, n) => "  '$id': ${n}Cover,\n")}};\n\n"
        '/// Their cities on the World Map (`WorldCities.all`): one already drawn\n'
        '/// as coming soon takes its season.\n'
        'const generatedWorldCities = <WorldCity>[\n${entries('WorldCity', (id, n) => '  ${n}WorldCity,\n')}];\n\n'
        '/// Their evidence pictures, by evidence id (`ArtAssets.evidencePictures`).\n'
        'const generatedEvidencePictures = <String, String>{\n${entries('', (id, n) => '  ...${n}EvidencePictures,\n')}};\n';
    final files = {'generated_seasons.g.dart': contents, 'generated_season_art.g.dart': art};
    final manifest = {
      'generator': 'generate_case.dart',
      'generatorVersion': generatorVersion,
      'target': 'gameRegistry',
      'seasons': [for (final (_, id, _) in seasons) id],
      'outputs': {for (final MapEntry(:key, :value) in files.entries) key: ContentHash.ofBytes(utf8.encode(value))},
    };
    return {...files, manifestName: PlanFiles.encode(manifest)};
  }
}
