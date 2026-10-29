import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/data/content/season_content_validator.dart';
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/learning.dart';
import 'package:world_mystery/data/models/scene_explore.dart' show ScenePixels;
import 'package:world_mystery/data/models/scene_place.dart';

import '../../tool/season_gen/generate_case.dart';
import '../../tool/season_gen/plan_files.dart';
import '../../tool/season_gen/plan_ids.dart';
import '../../tool/season_gen/season_cases.dart';
import '../../tool/season_planner/finding.dart';
import '../../tool/season_planner/season_quality.dart';

/// STEP 3-11: the Rome trial season, planned by Claude Code with
/// `tool/season_planner`, checked whole: the planner's checks, the real
/// generator (which waits only for the pictures), and the game's own
/// `SeasonContentValidator` on the cases' game JSON. The pictures are not
/// made: nothing here pretends they are.
void main() {
  const dir = 'content_pipeline/seasons/s3_rome';
  final season = PlanFiles.loadSeasonPlan('$dir/season.plan.json');
  final cases = [for (final p in SeasonCases.of('$dir/season.plan.json')) PlanFiles.loadCasePlan(p)];
  final report = SeasonQuality.run(dir);
  final manifest = jsonDecode(File('$dir/assets.manifest.json').readAsStringSync()) as Map;
  final assets = (manifest['assets'] as List).cast<Map>();

  group('the plans', () {
    test('twelve cases in three acts, no ERROR', () {
      expect(report.findings.where((f) => f.isError), isEmpty, reason: report.findings.where((f) => f.isError).join('\n'));
      expect([for (final c in cases) c.caseId], [for (var n = 1; n <= 12; n++) PlanIds.caseOf(3, n)]);
      expect(report.summary['missions'], 36);
      expect(report.summary['finals'], 12);
      expect([for (final a in season.acts) a.caseIds.length], [4, 4, 4]);
    });

    test('its quality report is the one the plans make now', () {
      final onDisk = File('$dir/planning/quality_report.json').readAsStringSync().replaceAll('\r\n', '\n');
      expect(onDisk, PlanFiles.encode(report.toJson()), reason: 'run: dart run tool/season_planner/plan_season.dart check $dir');
    });

    test('every case plays four kinds of puzzle, one of them hands-on', () {
      const handsOn = {'order_sequence', 'letter_tile_lock', 'combo_dial_lock'};
      for (final c in cases) {
        final kinds = [for (final m in c.allMissions) m.puzzle.paletteId];
        expect(kinds.toSet().length, 4, reason: '${c.caseId}: $kinds');
        expect(kinds.any(handsOn.contains), isTrue, reason: c.caseId);
      }
    });

    test('every case after the first uses a clue of an earlier case', () {
      for (final c in cases.skip(1)) {
        final earlier = [for (final m in c.allMissions) for (final i in m.clueInputs) if (PlanIds.caseOfChild(i.ref) != c.caseId) i.ref];
        expect(earlier, isNotEmpty, reason: c.caseId);
      }
      expect(report.summary['crossCaseClueInputs'] as int, greaterThanOrEqualTo(40));
    });

    test('a letter-collecting final closes the season', () {
      final last = cases.last.finalMission;
      expect(last.puzzle.paletteId, 'letter_tile_lock');
      final tiles = [for (final m in cases.last.missions) m.play!.clue!.value];
      final letters = tiles.join().replaceAll(RegExp(r'[^A-Z]'), '').replaceAll('GOLDTILES', '');
      expect((letters.split('')..sort()).join(), (last.puzzle.answerSpec.answer.split('')..sort()).join(),
          reason: 'the final\'s tiles are the gold tiles its missions found');
    });

    test('names no other season\'s city or story', () {
      final text = jsonEncode([for (final c in cases) c.toJson()]).toLowerCase();
      for (final word in ['london', 'paris', 'big ben', 'eiffel', 'clockmaker', 'sandbox']) {
        expect(text.contains(word), isFalse, reason: word);
      }
    });
  });

  group('the generator', () {
    test('passes every check but the pictures not made yet', () {
      final g = report.summary['generator'] as Map;
      expect(g['run'], isTrue);
      expect(g['compatible'], isTrue);
      expect(g['otherFailures'], 0);
      expect(g['blockedByPictures'], season.places.length);
      try {
        CaseGenerator.sandbox(seasonPath: '$dir/season.plan.json', casePaths: SeasonCases.of('$dir/season.plan.json'));
        fail('made without its pictures');
      } on GenerateFailure catch (e) {
        final errors = [for (final l in e.lines) if (l.trim().startsWith('error')) l];
        expect(errors, hasLength(season.places.length));
        expect(errors.every((l) => l.contains('[place_file_missing]')), isTrue, reason: errors.join('\n'));
      }
      expect(Directory('test/sandbox/generated/s3_rome').existsSync(), isFalse, reason: 'nothing was written');
    });

    test('its game JSON is read by the game, and the game\'s validator finds nothing wrong', () {
      final episodes = {for (final c in cases) c.caseId: CaseGenerator.episodeJson(c)};
      for (final json in episodes.values) {
        final e = Episode.fromJson(json.cast<String, dynamic>());
        expect(e.allMissions, hasLength(4));
      }
      final content = SeasonContent(
        info: {
          'id': season.seasonId,
          'number': season.number,
          'title': season.title,
          'tagline': season.tagline,
          'city': season.city,
          'cases': season.plannedCases,
          'outro': season.outro,
          'finale': season.finale,
        },
        episodes: {for (final e in episodes.entries) e.key: e.value.cast<String, dynamic>()},
        places: {for (final p in season.places) p.placeId: ScenePlace(file: p.file, pixels: ScenePixels(p.width.toDouble(), p.height.toDouble()))},
        released: false,
        learning: {
          for (final c in cases)
            for (final m in c.allMissions)
              m.missionId: LearningObjective(
                dependency: LanguageDependency.values.byName(m.learning.dependency),
                level: LearningLevel.values.byName(m.learning.level),
                objective: m.learning.objective,
                skill: m.learning.skill == null ? null : LanguageSkill.values.byName(m.learning.skill!),
                expressions: m.learning.expressions,
                recallFrom: m.learning.recallFrom,
              ),
        },
        languageTopics: {for (final c in cases) c.caseId: CaseLanguageTopic(title: c.learningGoal.title, titleKo: c.learningGoal.titleKo)},
      );
      final issues = SeasonContentValidator.validate(content);
      expect(issues, isEmpty, reason: issues.join('\n'));
      expect(SeasonCatalog.all.any((s) => s.id == season.seasonId), isFalse, reason: 'a trial: never in the catalog');
    });
  });

  group('the pictures', () {
    test('each place\'s picture is planned at the file the season plan shows, and none is made', () {
      for (final p in season.places) {
        final a = assets.singleWhere((a) => a['subject'] == p.placeId);
        expect(a['outputPath'], p.file);
        expect([a['width'], a['height']], [p.width, p.height]);
      }
      for (final a in assets) {
        expect(a['status'], 'planned', reason: '${a['assetId']}');
        expect(File('${a['outputPath']}').existsSync(), isFalse, reason: '${a['outputPath']} is not made yet');
        expect('${a['outputPath']}', startsWith('assets/seasons/season_03_rome/'));
      }
      expect(report.picturesPending, season.places.length);
      expect(report.findings.where((f) => f.code == 'image_pending').every((f) => f.level == Level.info), isTrue);
    });

    test('every character has a base portrait, and every other pose is drawn from it', () {
      for (final c in season.characters) {
        final drawn = assets.where((a) => a['subject'] == c.charId).toList();
        final base = drawn.singleWhere((a) => a['pose'] == 'base');
        for (final pose in drawn.where((a) => a['pose'] != 'base')) {
          expect(pose['references'], contains(base['assetId']), reason: '${pose['assetId']}');
        }
      }
    });

    test('no API was called, and the cost is an estimate', () {
      final a = report.summary['assets'] as Map;
      expect(report.summary['apiCalls'], 0);
      expect(a['estimatedUsd'], isA<double>());
      expect(a['generated'], 0);
      expect(Directory(dir).listSync(recursive: true).whereType<File>().any((f) => f.path.endsWith('image_manifest.json')), isFalse);
    });
  });
}
