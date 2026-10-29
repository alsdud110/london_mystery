import 'dart:convert';
import 'dart:io';

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
  var checkOnly = false, force = false;
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
    stderr.writeln('--target $target: only --target sandbox is made (a season of the game is registered by hand)');
    exit(64);
  }
  // The season's other written cases are made with it (generate_season.dart):
  // a case made alone would leave the season's list of cases without them.
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
  final schemaDir = '${File.fromUri(Platform.script).parent.path}/schema';
  exit(makeAndWrite(() => CaseGenerator.sandbox(seasonPath: seasonPath!, casePaths: cases, schemaDir: schemaDir),
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
/// imports each file needs.
const generatorVersion = 3;

/// Why nothing was made or written, a line each (as `validate_plan` prints them).
class GenerateFailure implements Exception {
  const GenerateFailure(this.lines);

  final List<String> lines;

  @override
  String toString() => 'GenerateFailure:\n${lines.join('\n')}';
}

/// What the plans make: the files by name (the manifest last), not yet written.
class Generated {
  const Generated(this.seasonId, this.files, this.notes);

  final String seasonId;
  final Map<String, String> files;

  /// For the person running it (the approvals' state).
  final List<String> notes;

  String get defaultDir => 'test/sandbox/generated/$seasonId';
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
  static Generated sandbox({
    required String seasonPath,
    required List<String> casePaths,
    String root = '.',
    String schemaDir = 'tool/season_gen/schema',
  }) {
    final schemas = SchemaSet.load(schemaDir);
    final lines = <String>[];
    void failed(String path, Iterable<String> errors) {
      if (errors.isEmpty) return;
      lines.add('FAILED  $path');
      lines.addAll([for (final e in errors) '  error    $e']);
    }

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
    for (final (i, (path, p)) in plans.indexed) {
      if (order.indexOf(p.caseId) != i) {
        failed(path, ['[case_missing] ${order[i]} comes before ${p.caseId} in ${season.seasonId} and is not given: '
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

    // 4. What the game needs of them.
    final seasonIssues = <String>{};
    for (final (path, p) in plans) {
      final found = PlayCheck.casePlan(p, season, root: root);
      failed(path, [for (final i in found) if (!i.inSeason) 'play $i']);
      seasonIssues.addAll([for (final i in found) if (i.inSeason) 'play $i']);
    }
    failed(seasonPath, seasonIssues);
    if (lines.isNotEmpty) throw GenerateFailure(lines);

    // 5. The approvals: a sandbox is made from drafts too, and says so.
    final notes = <String>[];
    var approved = true;
    for (final (_, p) in plans) {
      try {
        final r = SeasonApprovals(seasonDir).readiness(p.caseId);
        if (!r.ready) {
          approved = false;
          notes.add('${p.caseId} is not approved (${r.blockers.join('; ')}): sandbox content only');
        }
      } on Object catch (e) {
        approved = false;
        notes.add('${p.caseId}: the approvals could not be read ($e): sandbox content only');
      }
    }

    // 6. The files.
    final seasonJson = PlanFiles.readJson(seasonPath);
    final files = <String, String>{
      '${season.seasonId}_season.g.dart': _seasonFile(season, ContentHash.ofJson(seasonJson)),
      for (final (path, p) in plans) '${p.caseId}.g.dart': _caseFile(p, relative[p.caseId]!, ContentHash.ofJson(PlanFiles.readJson(path))),
      '${season.seasonId}_cases.g.dart': _casesFile(season, [for (final (_, p) in plans) p.caseId]),
    };
    final manifest = <String, Object?>{
      'generator': 'generate_case.dart',
      'generatorVersion': generatorVersion,
      'target': 'sandbox',
      'seasonId': season.seasonId,
      'cases': [for (final (_, p) in plans) p.caseId],
      'approved': approved,
      'inputs': {
        'season.plan.json': ContentHash.ofJson(seasonJson),
        for (final (path, p) in plans) relative[p.caseId]!: ContentHash.ofJson(PlanFiles.readJson(path)),
      },
      'outputs': {for (final MapEntry(:key, :value) in files.entries) key: ContentHash.ofBytes(utf8.encode(value))},
    };
    files[manifestName] = PlanFiles.encode(manifest);
    return Generated(season.seasonId, files, notes);
  }

  static String _slashes(String path) => path.replaceAll(r'\', '/');

  /// `s9_sandbox` → `s9Sandbox`.
  static String constName(String id) {
    final parts = id.split('_');
    return [parts.first, for (final p in parts.skip(1)) if (p.isNotEmpty) '${p[0].toUpperCase()}${p.substring(1)}'].join();
  }

  static String _head(String source, String hash) => '$generatedHeader\n// source: $source $hash\n';

  // ── The season ─────────────────────────────────────────────────────────

  static String _seasonFile(SeasonPlan s, String hash) {
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
      for (final p in s.places)
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
  static String _casesFile(SeasonPlan s, List<String> caseIds) {
    final name = constName(s.seasonId);
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
    'package:world_mystery/data/models/dialogue.dart': [
      'DialogueAnswer', 'DialogueDeduction', 'DialogueQuestion', 'DialogueScene', 'DialogueSpeaker', 'DialogueStatement', //
    ],
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

  static String _caseFile(CasePlan c, String source, String hash) {
    final name = constName(c.caseId);
    final all = c.allMissions;
    final learning = {
      for (final m in all)
        m.missionId: DartCall('LearningObjective', named: {
          'dependency': DartCode('LanguageDependency.${m.learning.dependency}'),
          'level': DartCode('LearningLevel.${m.learning.level}'),
          'objective': m.learning.objective,
          if (m.learning.skill case final s?) 'skill': DartCode('LanguageSkill.$s'),
          if (m.learning.expressions.isNotEmpty) 'expressions': m.learning.expressions,
          'recallFrom': ?m.learning.recallFrom,
        }),
    };
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
