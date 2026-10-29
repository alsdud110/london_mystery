import 'dart:convert';
import 'dart:io';

import '../season_gen/clue_graph_check.dart';
import '../season_gen/generate_case.dart';
import '../season_gen/json_schema_lite.dart';
import '../season_gen/plan_check.dart';
import '../season_gen/plan_files.dart';
import '../season_gen/plan_ids.dart';
import '../season_gen/plan_models.dart';
import '../season_gen/play_check.dart';
import '../season_gen/puzzle_selection_check.dart';
import '../season_gen/validate_plan.dart' show check;
import 'asset_manifest.dart';
import 'english_check.dart';
import 'finding.dart';
import 'story_bible.dart';

/// What a season's plans are worth, once checked whole (STEP 3-11).
class QualityReport {
  QualityReport(this.seasonId, this.findings, this.summary);

  final String seasonId;
  final List<Finding> findings;
  final Map<String, Object?> summary;

  int count(Level level) => findings.where((f) => f.level == level).length;
  bool get hasErrors => count(Level.error) > 0;

  /// The pictures the generator still waits for (season places not on disk).
  int get picturesPending => findings.where((f) => f.code == 'image_pending').length;

  /// As `planning/quality_report.json` keeps it: the same plans always make
  /// the same report (no time, no machine), so it changes only with them.
  Map<String, Object?> toJson() => {
    'schemaVersion': 1,
    'seasonId': seasonId,
    'tool': 'tool/season_planner/plan_season.dart check',
    'counts': {'ERROR': count(Level.error), 'WARNING': count(Level.warning), 'INFO': count(Level.info)},
    'summary': summary,
    'findings': [for (final f in findings) f.toJson()],
  };
}

/// Checks a season's folder whole: the plans as `season_gen` checks them
/// (schema, structure, puzzle selection, clue graph, `PlayCheck`), the real
/// generator run on them in memory, then what only a whole season shows —
/// twelve cases, the people and places they name, the story bible, the
/// pictures' manifest and the English.
///
/// A place's picture not on disk is never an error here: it is `image_pending`
/// (INFO), the one thing the generator may still wait for. Anything else the
/// generator refuses is an ERROR. Nothing here writes a file, calls an API
/// or reads an image beyond whether it is there.
abstract final class SeasonQuality {
  static const _cities = ['london', 'paris', 'big ben', 'eiffel', 'montmartre', 'thames', 'seine'];
  static final _title = RegExp(r"\b(Mr|Mrs|Ms|Dr|Signor|Signora|Professor|Director|Nonna|Inspector)\.? ([A-Z][a-z]+)");

  static const _choiceTypes = {'multipleChoice', 'imageChoice', 'canvasChoice'};
  static const _wordTypes = {'wordInput', 'letterLock'};

  /// [seasonDir]: `content_pipeline/seasons/<seasonId>`. [root]: the
  /// repository (pictures, schemas). The report of everything found.
  static QualityReport run(String seasonDir, {String root = '.', String? schemaDir}) {
    final dir = seasonDir.replaceAll(r'\', '/').replaceAll(RegExp(r'/$'), '');
    final out = Findings();
    final schemas = SchemaSet.load(schemaDir ?? '$root/tool/season_gen/schema');
    final seasonPath = '$dir/season.plan.json';
    final summary = <String, Object?>{};

    // 1. The season plan.
    if (!File(seasonPath).existsSync()) {
      out.error('season_plan_missing', seasonPath, 'no season plan', source: Source.plan);
      return QualityReport('?', out.all, summary);
    }
    final seasonCheck = check(seasonPath, schemas);
    for (final e in seasonCheck.errors) {
      out.error('plan', 'season.plan.json', e, source: Source.plan);
    }
    final SeasonPlan season;
    try {
      season = PlanFiles.loadSeasonPlan(seasonPath);
    } on PlanFormatException catch (e) {
      out.error('plan', 'season.plan.json ${e.path}', e.message, source: Source.plan);
      return QualityReport('?', out.all, summary);
    }
    if (seasonCheck.errors.isNotEmpty) return QualityReport(season.seasonId, out.all, summary);

    // 2. Twelve cases, each in its folder.
    final plans = <CasePlan>[];
    final paths = <String, String>{};
    final folders = Directory('$dir/cases').existsSync()
        ? [for (final d in Directory('$dir/cases').listSync().whereType<Directory>()) d.uri.pathSegments.where((s) => s.isNotEmpty).last]
        : <String>[];
    for (final f in folders) {
      if (!season.caseIds.contains(f)) out.error('case_not_in_season', 'cases/$f', 'not a case of ${season.seasonId}', source: Source.season);
    }
    for (final id in season.caseIds) {
      final path = '$dir/cases/$id/case.plan.json';
      if (!File(path).existsSync()) {
        out.error('case_missing', 'cases/$id', 'no case.plan.json: the season has ${season.plannedCases} cases', source: Source.season);
        continue;
      }
      paths[id] = path;
      final r = check(path, schemas, season: season);
      for (final e in r.errors) {
        out.error(_codeOf(e, 'plan'), 'cases/$id', e, source: Source.plan);
      }
      for (final w in r.warnings) {
        out.warning(_codeOf(w, 'plan'), 'cases/$id', w, source: Source.plan);
      }
      if (r.casePlan case final c?) {
        if (c.caseId != id) {
          out.error('case_misplaced', 'cases/$id', 'its caseId is ${c.caseId}', source: Source.season);
        } else {
          plans.add(c);
        }
      }
    }

    // 3. The season's clues and puzzles across cases (as validate_plan --season).
    if (PlanCheck.season(season).isEmpty && plans.isNotEmpty) {
      final clues = ClueGraphCheck.season(season, plans);
      for (final i in clues.issues.where((i) => i.acrossCases)) {
        (i.isError ? out.error : out.warning)(i.code, 'cases/${i.caseId} ${i.path}', i.message, source: Source.plan);
      }
    }
    for (final i in PuzzleSelectionCheck.season(plans)) {
      out.warning(i.code, i.path, i.message, source: Source.plan);
    }

    // 4. What the generator needs of each case; a picture not made yet apart.
    final pendingPlaces = <String>{};
    for (final c in plans) {
      for (final i in PlayCheck.casePlan(c, season, root: root)) {
        if (i.code == 'place_file_missing') {
          if (pendingPlaces.add(i.path)) out.info('image_pending', 'season.plan.json ${i.path}', '${i.message}: a picture still to be made (assets.manifest.json)', source: Source.play);
        } else {
          out.error(i.code, '${i.inSeason ? 'season.plan.json' : 'cases/${c.caseId}'} ${i.path}', i.message, source: Source.play);
        }
      }
    }

    // 5. The season's own rules: people, places, puzzles, words.
    _people(season, plans, out);
    _puzzles(plans, out);
    EnglishCheck.check(plans, out);

    // 6. The story bible and the pictures.
    final biblePath = '$dir/${StoryBible.path}';
    summary['bible'] = File(biblePath).existsSync()
        ? StoryBible.check(_json(biblePath, out), season, plans, out)
        : (() {
            out.error('bible_missing', StoryBible.path, 'no story bible', source: Source.bible);
            return null;
          })();
    final manifestPath = '$dir/${AssetManifest.fileName}';
    summary['assets'] = File(manifestPath).existsSync()
        ? AssetManifest.check(_json(manifestPath, out), season, plans, out, root: root)
        : (() {
            out.error('asset_manifest_missing', AssetManifest.fileName, 'no asset manifest', source: Source.assets);
            return null;
          })();

    // 7. The real generator, in memory, once the plans hold.
    summary['generator'] = _generator(seasonPath, season, plans, paths, root, schemaDir ?? '$root/tool/season_gen/schema', out);

    summary.addAll(_counts(season, plans));
    summary['picturesPending'] = pendingPlaces.length;
    summary['apiCalls'] = 0;
    return QualityReport(season.seasonId, out.all, summary);
  }

  static String _codeOf(String line, String fallback) => RegExp(r'\[([a-z_]+)\]').firstMatch(line)?[1] ?? fallback;

  static Object? _json(String path, Findings out) {
    try {
      return jsonDecode(File(path).readAsStringSync());
    } on FormatException catch (e) {
      out.error('json_invalid', path, 'not JSON: ${e.message}');
      return null;
    }
  }

  /// The people and places a case names: of the season, after they come in,
  /// and no name of another season's story.
  static void _people(SeasonPlan season, List<CasePlan> plans, Findings out) {
    final order = season.caseIds;
    final people = {for (final c in season.characters) c.charId: c};
    final names = <String>{
      for (final c in season.characters) ...c.name.replaceAll('.', '').split(' ').where((w) => w.length > 2),
    };
    final city = season.city.toLowerCase();
    for (final c in plans) {
      for (final (i, id) in c.characters.indexed) {
        final p = people[id];
        if (p != null && order.indexOf(c.caseId) < order.indexOf(p.firstCase)) {
          out.error('character_before_first_case', 'cases/${c.caseId} \$.characters[$i]', '$id comes in at ${p.firstCase}', source: Source.season);
        }
      }
      for (final (path, text) in EnglishCheck.texts(c)) {
        for (final m in _title.allMatches(text)) {
          if (!names.contains(m[2])) {
            out.warning('story_unknown_name', 'cases/${c.caseId} $path', '"${m[0]}" is no character of season.plan.json', source: Source.season);
          }
        }
        final lower = text.toLowerCase();
        for (final other in _cities) {
          if (!city.contains(other) && lower.contains(other)) {
            out.warning('story_other_season', 'cases/${c.caseId} $path', '"$other": another season\'s story', source: Source.season);
          }
        }
      }
    }
  }

  /// Each puzzle's answer, wrong answers and hints.
  static void _puzzles(List<CasePlan> plans, Findings out) {
    String norm(String s) => s.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    for (final c in plans) {
      for (final (i, m) in c.allMissions.indexed) {
        final at = 'cases/${c.caseId} ${m.isFinal ? r'$.final' : '\$.missions[$i]'}';
        final p = m.puzzle;
        final a = p.answerSpec;
        final w = m.play;
        if (a.answer.trim().isEmpty) out.error('answer_missing', '$at.puzzle.answerSpec.answer', 'no answer', source: Source.puzzle);
        if (_choiceTypes.contains(p.missionType)) {
          for (final (j, o) in a.options.indexed) {
            if (o.id != a.answer && (o.feedback == null || o.feedback!.trim().isEmpty)) {
              out.error('feedback_missing', '$at.puzzle.answerSpec.options[$j]', '"${o.label}" is wrong, and says nothing to think again with', source: Source.puzzle);
            }
          }
        } else if (w != null && w.feedback.isEmpty && w.orderFeedback == null) {
          out.warning('feedback_missing', '$at.play', 'no wrong-answer line (feedback, orderFeedback): only the game\'s own', source: Source.puzzle);
        }
        if (w == null) continue;
        if (w.hints.length < PlayCheck.maxHints) {
          out.info('hint_single', '$at.play.hints', 'one hint: a second, closer one helps a stuck reader', source: Source.puzzle);
        }
        // A hint never says the answer itself.
        final answers = <String>{
          if (_wordTypes.contains(p.missionType)) ...[a.answer, ...a.acceptedAnswers].map(norm),
          if (_choiceTypes.contains(p.missionType)) ...[for (final o in a.options) if (o.id == a.answer) norm(o.label)],
        }..removeWhere((s) => s.length < 3);
        for (final (j, h) in w.hints.indexed) {
          final words = norm(h);
          for (final ans in answers) {
            if (words.contains(ans)) {
              out.warning('hint_reveals_answer', '$at.play.hints[$j]', 'the hint says the answer ($ans)', source: Source.puzzle);
            }
          }
        }
        // Wrong-answer lines are for wrong answers.
        for (final key in w.feedback.keys) {
          if ([a.answer, ...a.acceptedAnswers].map(norm).contains(norm(key))) {
            out.error('feedback_for_answer', '$at.play.feedback.$key', 'a wrong-answer line for the right answer', source: Source.puzzle);
          }
        }
      }
    }
  }

  /// The real generator, in memory: `CaseGenerator.sandbox` on the case
  /// plans (nothing written), and each case's game JSON. Its only failures
  /// allowed are the pictures not made yet.
  static Map<String, Object?> _generator(String seasonPath, SeasonPlan season, List<CasePlan> plans, Map<String, String> paths,
      String root, String schemaDir, Findings out) {
    if (out.all.any((f) => f.isError) || plans.length != season.caseIds.length) {
      out.info('generator_skipped', 'generate_season', 'not run: the plans have errors to fix first', source: Source.generator);
      return {'run': false};
    }
    for (final c in plans) {
      try {
        final json = CaseGenerator.episodeJson(c);
        if ((json['missions'] as List).length != c.missions.length) throw StateError('missions lost');
      } on Object catch (e) {
        out.error('generator_episode', 'cases/${c.caseId}', 'its game JSON cannot be made: $e', source: Source.generator);
      }
    }
    try {
      final made = CaseGenerator.sandbox(seasonPath: seasonPath, casePaths: [for (final id in season.caseIds) paths[id]!], root: root, schemaDir: schemaDir);
      out.info('generator_ok', 'generate_season', '${made.files.length} files made in memory (nothing written)', source: Source.generator);
      return {'run': true, 'compatible': true, 'files': made.files.length, 'blockedByPictures': 0};
    } on GenerateFailure catch (e) {
      final errors = [for (final l in e.lines) if (l.trimLeft().startsWith('error')) l.trim()];
      final pictures = errors.where((l) => l.contains('[place_file_missing]')).length;
      final other = errors.where((l) => !l.contains('[place_file_missing]')).toList();
      for (final l in other) {
        out.error('generator', 'generate_season', l, source: Source.generator);
      }
      if (other.isEmpty) {
        out.info('generator_waits_for_pictures', 'generate_season',
            'every check of the generator passes but one: $pictures place pictures are not on disk yet', source: Source.generator);
      }
      return {'run': true, 'compatible': other.isEmpty, 'blockedByPictures': pictures, 'otherFailures': other.length};
    }
  }

  static Map<String, Object?> _counts(SeasonPlan season, List<CasePlan> plans) {
    final byKind = <String, int>{};
    final finals = <String, int>{};
    var crossCase = 0, recalls = 0, links = 0;
    for (final c in plans) {
      for (final m in c.allMissions) {
        final k = m.puzzle.paletteId ?? 'none';
        byKind[k] = (byKind[k] ?? 0) + 1;
        if (m.isFinal) finals[k] = (finals[k] ?? 0) + 1;
        for (final i in m.clueInputs) {
          if (PlanIds.caseOfChild(i.ref) != c.caseId) crossCase++;
          if (i.use == ClueUse.recall) recalls++;
          if (i.use == ClueUse.evidenceLink) links++;
        }
      }
    }
    return {
      'cases': plans.length,
      'plannedCases': season.plannedCases,
      'acts': season.acts.length,
      'missions': plans.fold<int>(0, (n, c) => n + c.missions.length),
      'finals': plans.length,
      'puzzlesByKind': byKind,
      'finalsByKind': finals,
      'crossCaseClueInputs': crossCase,
      'recallSteps': recalls,
      'evidenceLinks': links,
      'characters': season.characters.length,
      'locations': season.locations.length,
      'places': season.places.length,
    };
  }

  /// Writes [report] to `<seasonDir>/planning/quality_report.json`, whole
  /// (beside it first, then moved over it).
  static String write(String seasonDir, QualityReport report) {
    final path = '$seasonDir/planning/quality_report.json';
    final part = File('$path.part')..parent.createSync(recursive: true);
    part.writeAsStringSync(PlanFiles.encode(report.toJson()), flush: true);
    part.renameSync(path);
    return path;
  }
}
