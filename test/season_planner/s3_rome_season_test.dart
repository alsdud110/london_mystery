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
import '../../tool/season_gen/play_check.dart';
import '../../tool/season_gen/season_cases.dart';
import '../../tool/season_planner/finding.dart';
import '../../tool/season_planner/season_quality.dart';

/// STEP 3-11: the Rome trial season, planned by Claude Code with
/// `tool/season_planner`, checked whole: the planner's checks, the real
/// generator, and the game's own `SeasonContentValidator` on the cases'
/// game JSON. Since STEP 3-15B B3 every picture a case shows is made and the
/// season is in the game (the Rome integration); the 3 still planned (the
/// cover, the map, the owl scene, the prologue, the gold tiles) are shown by
/// no generated case yet.
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
    test('passes every check, every picture it waits for made: the season generated whole (STEP 3-15B B3)', () {
      final g = report.summary['generator'] as Map;
      expect(g['run'], isTrue);
      expect(g['compatible'], isTrue);
      expect(g['blockedByPictures'], 0);
      // 15, and every case's levels (Junior, Master): one a case and the season's.
      expect(g['files'], 15 + 12 + 1);
      // STEP 3-15A: Case 05's two places are in assets/; STEP 3-15B B1 added
      // the six of Cases 01–04, B2 the five of Cases 06–08, B3 the last five
      // (Cases 09–12). Nothing stops the generator now.
      expect([for (final p in season.places) if (!File(p.file).existsSync()) p.placeId], isEmpty);
      final made = CaseGenerator.sandbox(seasonPath: '$dir/season.plan.json', casePaths: SeasonCases.of('$dir/season.plan.json'), target: 'game');
      expect(made.files, hasLength(15 + 12 + 1 + 2), reason: "the sandbox's 15, the levels' 13, its SeasonContent and its art");
      final planned = {for (final a in assets) a['outputPath']};
      for (final c in cases) {
        for (final m in c.allMissions) {
          for (final (_, f) in PlayCheck.pictureFiles(m)) {
            expect(planned, contains(f), reason: '${m.missionId} shows $f: planned in the manifest');
            expect(File(f).existsSync(), isTrue, reason: '${m.missionId} shows $f: made');
          }
        }
      }
      // Written by plan_season.dart generate, as these plans make it now.
      expect(GeneratedFiles.stale(made.defaultDir, made.files), isEmpty,
          reason: 'run: dart run tool/season_planner/plan_season.dart generate $dir --target game');
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
      expect(SeasonCatalog.all.any((s) => s.id == season.seasonId), isTrue, reason: 'Season 3 of the game since the Rome integration');
    });
  });

  group('the pictures', () {
    test('each place\'s picture is planned at the file the season plan shows; every one a case shows is made (STEP 3-15A, 3-15B B1–B3)', () {
      for (final p in season.places) {
        final a = assets.singleWhere((a) => a['subject'] == p.placeId);
        expect(a['outputPath'], p.file);
        expect([a['width'], a['height']], [p.width, p.height]);
      }
      const made = {
        'cat_ruins', 'cast_workshop', 'cat_tito', 'cat_rosso', 'cat_luna', //
        'pantheon_hall', 'floor_stone_ship', 'floor_stone_lion', 'floor_stone_book', 'floor_stone_key', //
        'guard_room', 'map_hall', 'trevi_fountain', 'flower_market', 'rotonda_bookshop', 'colosseum', //
        'char_giulia_base', 'char_sofia_base', 'char_enzo_base', 'char_aldo_base', 'char_carla_base', 'char_livia_base',
        'navona_square', 'lecture_hall', 'spanish_steps', 'tiber_bridge', 'restoration_lab', 'bridge_angels', 'bridge_hole',
        'char_livia_hood',
        // STEP 3-15B B3: Cases 09–12 (forum_view drawn in 3-12B, copied now).
        'forum_view', 'map_archive', 'civetta_square', 'site_office', 'roman_library', //
        'char_bruno_base', 'char_bruno_site', 'char_pia_base', //
        'ev_real_piece', 'ev_business_card', 'ev_yellow_helmet', //
        'room_bath', 'room_theatre', 'helmet_white_crane', 'helmet_yellow_plain', 'stone_lion', 'stone_street',
        // The Rome integration: the cover, the map, the evidence cards.
        'cover', 'city_map', 'ev_night_log', 'ev_owl_card', 'ev_brass_key', 'ev_dropped_pass', 'ev_plaster_copy', //
        'ev_order_card', 'ev_aldo_photo', 'ev_loan_page', 'ev_livia_drawing', 'ev_city_plan', 'ev_owl_mosaic',
      };
      for (final a in assets) {
        final isMade = made.contains('${a['assetId']}'.split('.').last);
        expect(a['status'], isMade ? 'generated' : 'planned', reason: '${a['assetId']}');
        expect(File('${a['outputPath']}').existsSync(), isMade, reason: '${a['outputPath']}');
        expect('${a['outputPath']}', startsWith('assets/seasons/season_03_rome/'));
      }
      final pending = report.findings.where((f) => f.code == 'image_pending').toList();
      expect(report.picturesPending, pending.length);
      expect(pending, isEmpty, reason: 'no picture a case shows waits');
      expect(report.findings.where((f) => f.code == 'asset_pending').single.level, Level.info, reason: 'the 16 not shown yet: an INFO');
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

    test('the planner calls no API, and the cost is an estimate; the 60 made by the asset pipeline are counted', () {
      final a = report.summary['assets'] as Map;
      expect(report.summary['apiCalls'], 0);
      expect(a['estimatedUsd'], isA<double>());
      expect(a['generated'], 60);
      expect(a['planned'], 3, reason: 'the prologue, the gold tiles and the owl scene: no screen shows them');
      expect(Directory(dir).listSync(recursive: true).whereType<File>().any((f) => f.path.endsWith('image_manifest.json')), isFalse);
    });
  });
}
