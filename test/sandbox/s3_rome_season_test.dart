import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/data/content/puzzle_engine_collisions.dart';
import 'package:world_mystery/data/content/season_content_validator.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/models/scene_explore.dart';

import '../../tool/season_gen/content_hash.dart';
import '../../tool/season_gen/generate_case.dart';
import '../../tool/season_gen/plan_files.dart';
import '../../tool/season_gen/plan_models.dart';
import '../../tool/season_gen/play_check.dart';
import '../../tool/season_gen/season_cases.dart';
import 'rome_season.dart';

/// STEP 3-15B B3, the Rome integration: Rome, Season 3, from its plans to
/// the screen, on the pictures the asset pipeline drew. Made by the
/// season's own path into the game (`plan_season.dart generate --target
/// game`: `lib/data/generated/s3_rome/` and the game's lists of generated
/// seasons), as the game has it. Rome's own facts are checked here (its
/// generation, its four measured look rounds, Case 04's opening, Case 10's
/// helmets, every face drawn, Case 08's bridge first seen among the choices).
/// It is played whole, in order and on four screens, by
/// `test/generated_seasons_test.dart` (`season_playthrough.dart`), as every
/// season made from its plans is.
void main() {
  const seasonDir = 'content_pipeline/seasons/s3_rome';
  const seasonPath = '$seasonDir/season.plan.json';
  const outDir = 'lib/data/generated/s3_rome';
  final casePaths = SeasonCases.of(seasonPath);
  final plans = [for (final p in casePaths) PlanFiles.loadCasePlan(p)];
  final episodes = romeEpisodes();
  final content = romeContent;
  MissionPlan planOf(String id) => [for (final p in plans) ...p.allMissions].firstWhere((m) => m.missionId == id);

  /// The four look rounds, each measured on the very file the game shows.
  const measured = [
    ('s3_ep01_m3', 'assets/seasons/season_03_rome/locations/map_hall.png'),
    ('s3_ep04_m1', 'assets/seasons/season_03_rome/locations/pantheon_hall.png'),
    ('s3_ep05_m1', 'assets/seasons/season_03_rome/locations/cat_ruins.png'),
    ('s3_ep10_m1', 'assets/seasons/season_03_rome/locations/civetta_square.png'),
  ];

  group('the generated season', () {
    test('is what the Rome plans make now, the whole season in the game (generate_season --target game --check)', () {
      final made = CaseGenerator.sandbox(seasonPath: seasonPath, casePaths: casePaths, target: 'game');
      expect(made.defaultDir, outDir);
      expect(GeneratedFiles.stale(outDir, made.files), isEmpty,
          reason: 'run: dart run tool/season_planner/plan_season.dart generate $seasonDir --target game');
      final registry = GameRegistry.files(GameRegistry.seasons(adding: made));
      expect(GeneratedFiles.stale(GameRegistry.dir, registry), isEmpty, reason: "the game's lists of generated seasons");
      final manifest = jsonDecode(made.files[manifestName]!) as Map;
      expect(manifest['target'], 'game');
      expect(manifest['slice'] ?? false, isFalse, reason: 'the season, not a slice');
      expect(manifest['cases'], [for (var n = 1; n <= 12; n++) 's3_ep${n.toString().padLeft(2, '0')}']);
      expect([for (final e in episodes) e.number], [for (var n = 1; n <= 12; n++) n]);
      expect([for (final e in episodes) e.missions.length], everyElement(3));
      expect(Directory('test/sandbox/generated/s3_rome_c01_08').existsSync(), isFalse, reason: 'the slice it replaced');
      expect(Directory('test/sandbox/generated/s3_rome').existsSync(), isFalse, reason: "one copy: the game's");
    });

    test('the game finds nothing wrong: its validator, engine choice and bundled pictures', () {
      expect([for (final i in SeasonContentValidator.validate(content)) (i.rule, i.caseId, i.message)], isEmpty);
      final engines = {for (final s in PuzzleEngineCollisionCheck.slotsOf(content)) s.mission.id: s.active?.engine};
      for (final (id, _) in measured) {
        expect(engines[id], 'SceneExplore', reason: id);
      }
      expect(content.dialogues.keys, ['s3_ep01_m1', 's3_ep11_m2'], reason: 'the witnesses of Case 01 and Case 11');
      final pubspec = File('pubspec.yaml').readAsStringSync();
      final folders = [for (final m in RegExp(r'^\s+- (assets/\S+/)\s*$', multiLine: true).allMatches(pubspec)) m[1]!];
      final files = {
        for (final p in content.places.values) p.file,
        for (final s in content.explores.values) ...[s.picture, for (final c in s.choices) c.picture],
        for (final d in content.dialogues.values) for (final s in d.speakers) s.portrait,
        for (final m in content.talkMissions.values) for (final s in [?m.before, ?m.after]) ...s.speaker.portraits.values,
        for (final e in content.endings.values) for (final l in e) ?l.portrait,
        for (final e in episodes) for (final m in e.allMissions) for (final o in m.options) ?o.picture,
      };
      for (final f in files) {
        expect(File(f).existsSync(), isTrue, reason: f);
        expect(folders.any((d) => f.startsWith(d) && !f.substring(d.length).contains('/')), isTrue, reason: '$f is not in a pubspec assets folder');
      }
      // Every place of the season has its picture now (Case 09 to 12's too).
      expect(content.places.keys, containsAll(['s3_rome.forum_view', 's3_rome.map_archive', 's3_rome.civetta_square', 's3_rome.site_office', 's3_rome.roman_library']));
    });

    for (final (id, file) in measured) {
      test('$id is a look round on the drawn picture, its places measured on that very file', () {
        final m = planOf(id);
        final ep = m.play!.explore!;
        final explore = content.explores[id]!;
        final f = File(ep.picture.file);
        expect(explore.picture, file);
        expect(PlayCheck.pngSize(f), (1536, 1024));
        expect(ep.picture.measuredOn, ContentHash.ofBytes(f.readAsBytesSync()), reason: 'measured on the file the game shows');
        expect(m.puzzle.notes.any((n) => n.contains('UNMEASURED')), isFalse);
        Rect px(SceneRect r) => Rect.fromLTRB(r.left / 1536, r.top / 1024, r.right / 1536, r.bottom / 1024);
        for (final (i, s) in explore.spots.indexed) {
          expect(s.areas, [for (final r in ep.spots[i].areas) px(r)], reason: s.id);
        }
        // No two places overlap: a tap inside one is never taken by another.
        final all = [for (final s in explore.spots) for (final r in s.areas) (s.id, r), for (final o in explore.others) for (final r in o.areas) (o.label, r)];
        for (final (i, (a, ra)) in all.indexed) {
          for (final (b, rb) in all.skip(i + 1)) {
            if (a == b) continue;
            expect(ra.intersect(rb).isEmpty || ra.intersect(rb).width <= 0 || ra.intersect(rb).height <= 0, isTrue, reason: '$id: $a and $b overlap');
          }
        }
        // The opening view holds every place to find (its middle, at least).
        for (final s in explore.spots) {
          for (final r in s.areas) {
            expect(explore.opening.contains(r.center), isTrue, reason: '$id ${s.id} outside the opening');
          }
        }
        expect(explore.document, isNotNull);
        for (final c in explore.choices) {
          expect(File(c.picture).existsSync(), isTrue, reason: c.picture);
        }
      });
    }

    test('Case 04 M1 opens the Pantheon closer, with nothing re-measured; Case 10 M1 on the measured helmets', () {
      final pantheon = content.explores['s3_ep04_m1']!;
      // x 300-1350 of 1536: the hall a phone's width, about 1.46 times larger
      // than the whole picture's width it opened on before.
      expect(pantheon.opening, Rect.fromLTRB(300 / 1536, 0, 1350 / 1536, 1020 / 1024));
      expect(1 / pantheon.opening.width, greaterThan(1.4));
      final civetta = content.explores['s3_ep10_m1']!;
      final hooks = civetta.spots.firstWhere((s) => s.id == 'hooks');
      expect(hooks.kind, ExploreKind.choice);
      expect(hooks.requires, 'notice');
      expect([for (final c in civetta.choices) c.picture.split('/').last], ['helmet_white_crane.png', 'helmet_yellow_plain.png', 'yellow_helmet.png']);
    });

    test('every face is drawn and written in: Pia and Bruno too', () {
      const pia = 'assets/seasons/season_03_rome/characters/pia_base.png';
      const bruno = 'assets/seasons/season_03_rome/characters/bruno_base.png';
      const brunoSite = 'assets/seasons/season_03_rome/characters/bruno_site.png';
      final d = content.dialogues['s3_ep01_m1']!;
      expect({for (final s in d.speakers) s.portrait}, {
        'assets/seasons/season_03_rome/characters/enzo_base.png',
        'assets/seasons/season_03_rome/characters/sofia_base.png',
        'assets/seasons/season_03_rome/characters/livia_base.png',
      });
      final talks = [for (final m in content.talkMissions.values) ?m.before, for (final m in content.talkMissions.values) ?m.after];
      for (final s in talks) {
        expect(s.speaker.portraits, isNotEmpty, reason: '${s.id}: ${s.speaker.name} has a face');
        for (final p in s.speaker.portraits.values) {
          expect(File(p).existsSync(), isTrue, reason: '${s.id}: $p');
        }
      }
      for (final MapEntry(key: id, value: lines) in content.endings.entries) {
        for (final l in lines) {
          if (l.portrait case final p?) expect(File(p).existsSync(), isTrue, reason: '$id: $p');
        }
      }
      expect(content.talkMissions['s3_ep03_m3']!.after!.speaker.portraits.values, everyElement(pia), reason: 'Pia at her stall');
      expect(content.talkMissions['s3_ep07_m3']!.before!.speaker.portraits.values, everyElement(bruno), reason: 'Bruno, the businessman');
      // Case 11 M2's witnesses: Valli at his site, Pia, Sofia.
      final witnesses = content.dialogues['s3_ep11_m2']!;
      for (final s in witnesses.speakers) {
        expect(File(s.portrait).existsSync(), isTrue, reason: '${s.name}: ${s.portrait}');
      }
      expect({for (final s in witnesses.speakers) s.portrait}, containsAll([brunoSite, pia]));
      final used = {
        for (final s in talks) ...s.speaker.portraits.values,
        for (final e in content.endings.values) for (final l in e) ?l.portrait,
        for (final d in content.dialogues.values) for (final s in d.speakers) s.portrait,
      };
      expect(used, containsAll([pia, bruno, brunoSite]));
      // The Owl, hood down on the bridge: the hooded portrait drawn in STEP 3-12B.
      expect(content.talkMissions['s3_ep08_m2']!.before!.speaker.portraits.values,
          everyElement('assets/seasons/season_03_rome/characters/livia_hood.png'));
    });

    test('a picture choice never shows its right picture as the mission\'s own place (Case 08 M1)', () {
      for (final e in episodes) {
        for (final m in e.allMissions.where((m) => m.type == MissionType.imageChoice)) {
          final right = m.options.firstWhere((o) => o.id == m.answer).picture;
          expect(content.places[m.place.key]!.file, isNot(right), reason: '${m.id}: its first page would show the answer');
        }
      }
      final m1 = episodes[7].missions.first;
      expect(m1.place.key, 's3_rome.map_hall', reason: 'where the card came; the bridge is first seen among the choices');
      expect(episodes[7].missions[1].place.key, 's3_rome.tiber_bridge', reason: 'M2 on the bridge, after the answer');
    });
  });

}
