import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/data/content/season_content_validator.dart';
import 'package:world_mystery/data/generated/generated_seasons.g.dart';
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/features/mission_map/map_world.dart';
import 'package:world_mystery/features/world_map/world_cities.dart';
import 'package:world_mystery/widgets/art_assets.dart';

import '../tool/season_gen/content_hash.dart';
import '../tool/season_gen/generate_case.dart';
import '../tool/season_gen/plan_files.dart';
import '../tool/season_gen/season_cases.dart';
import 'sandbox/season_playthrough.dart';

/// Every season of the game made from its plans (the Rome integration:
/// `generate_season.dart --target game`, listed in `generatedSeasons`),
/// checked and played whatever its city. A new season made by the season
/// factory (`tool/season_factory`) is in these tests by being generated: no
/// test is written for it by hand.
///
/// Its plans are `content_pipeline/seasons/<seasonId>/`, as the factory and
/// the planner keep them.
void main() {
  test('the game lists every season generated into lib/, and nothing else', () {
    final dirs = [
      for (final d in Directory(GameRegistry.dir).listSync().whereType<Directory>())
        if (File('${d.path}/$manifestName').existsSync()) d.uri.pathSegments.where((s) => s.isNotEmpty).last,
    ]..sort();
    expect([for (final s in generatedSeasons) s.id]..sort(), dirs);
    expect(SeasonCatalog.all.take(2).map((s) => s.id), ['s1_london', 's2_paris'], reason: 'London and Paris first, as ever');
    expect(SeasonCatalog.all.skip(2), generatedSeasons);
    final numbers = [for (final s in SeasonCatalog.all) s.season.number];
    expect(numbers, [for (var n = 1; n <= numbers.length; n++) n], reason: 'one season a number, in play order');
  });

  for (final content in generatedSeasons) {
    final id = content.id;
    final seasonDir = 'content_pipeline/seasons/$id';
    final seasonPath = '$seasonDir/season.plan.json';
    final episodes = [for (final json in content.episodes.values) Episode.fromJson({...json, 'seasonId': id})];
    final pubspec = File('pubspec.yaml').readAsStringSync();
    final folders = [for (final m in RegExp(r'^\s+- (assets/\S+/)\s*$', multiLine: true).allMatches(pubspec)) m[1]!];
    bool bundled(String f) => File(f).existsSync() && folders.any((d) => f.startsWith(d) && !f.substring(d.length).contains('/'));

    group('$id, generated', () {
      test('is what its plans make now, and the game lists it (generate_season --target game --check)', () {
        final made = CaseGenerator.sandbox(seasonPath: seasonPath, casePaths: SeasonCases.of(seasonPath), target: 'game');
        expect(GeneratedFiles.stale(made.defaultDir, made.files), isEmpty, reason: 'run: dart run tool/season_factory/season_factory.dart run $seasonDir');
        expect(GeneratedFiles.stale(GameRegistry.dir, GameRegistry.files(GameRegistry.seasons(adding: made))), isEmpty);
        expect(content.released, isTrue);
        expect(episodes, hasLength(content.season.plannedCases ?? episodes.length));
      });

      test('the game\'s validator finds nothing wrong; every picture it shows is bundled', () {
        expect([for (final i in SeasonContentValidator.validate(content)) (i.rule, i.caseId, i.message)], isEmpty);
        final files = {
          for (final p in content.places.values) p.file,
          for (final s in content.explores.values) ...[s.picture, for (final c in s.choices) c.picture],
          for (final d in content.dialogues.values) for (final s in d.speakers) s.portrait,
          for (final m in content.talkMissions.values) for (final s in [?m.before, ?m.after]) ...s.speaker.portraits.values,
          for (final e in content.endings.values) for (final l in e) ?l.portrait,
          for (final e in episodes) for (final m in e.allMissions) for (final o in m.options) ?o.picture,
        };
        for (final f in files) {
          expect(bundled(f), isTrue, reason: '$f: on disk and in a pubspec assets folder');
        }
      });

      test('its own map, measured on the very file: every mission at a landmark, under the top margin', () {
        final map = SeasonMap.forSeason(id);
        expect(map, isNotNull, reason: 'a season without its map can never be entered');
        expect(bundled(map!.artwork), isTrue);
        expect(map.landmarks.whereType<SeasonLandmark>(), hasLength(map.landmarks.length));
        final plan = PlanFiles.readJson(seasonPath) as Map;
        final measuredOn = ((plan['art'] as Map)['map'] as Map)['measuredOn'];
        expect(measuredOn, ContentHash.ofBytes(File(map.artwork).readAsBytesSync()), reason: 'landmarks measured on the file the game shows');
        for (final e in episodes) {
          final places = MapWorld.places(e, map: map);
          for (final m in e.allMissions) {
            expect(map.landmarkFor(m.id, e.id), isNotNull, reason: m.id);
            final at = places[m.id]!;
            expect(at.dx, inInclusiveRange(0.0, 1.0), reason: m.id);
            expect(at.dy, inInclusiveRange(MapWorld.topMargin - 1e-9, 1.0), reason: m.id);
          }
        }
      });

      test('every look round measured on its picture: no two places overlap, each place in its opening view', () {
        for (final MapEntry(key: missionId, value: s) in content.explores.entries) {
          final all = [for (final x in s.spots) for (final r in x.areas) (x.id, r), for (final o in s.others) for (final r in o.areas) (o.label, r)];
          for (final (i, (a, ra)) in all.indexed) {
            for (final (b, rb) in all.skip(i + 1)) {
              if (a == b) continue;
              final cut = ra.intersect(rb);
              expect(cut.width <= 0 || cut.height <= 0, isTrue, reason: '$missionId: $a and $b overlap');
            }
          }
          for (final x in s.spots) {
            for (final r in x.areas) {
              expect(s.opening.contains(r.center), isTrue, reason: '$missionId ${x.id} outside the opening');
            }
          }
        }
        for (final path in SeasonCases.of(seasonPath)) {
          final plan = PlanFiles.loadCasePlan(path);
          for (final m in plan.allMissions) {
            final e = m.play?.explore;
            if (e == null) continue;
            expect(m.puzzle.notes.where((n) => n.contains('UNMEASURED')), isEmpty, reason: m.missionId);
            expect(e.picture.measuredOn, ContentHash.ofBytes(File(e.picture.file).readAsBytesSync()), reason: '${m.missionId}: measured on the file the game shows');
          }
        }
      });

      test('a picture choice never shows its right picture as the mission\'s own place', () {
        for (final e in episodes) {
          for (final m in e.allMissions.where((m) => m.type == MissionType.imageChoice)) {
            final right = m.options.firstWhere((o) => o.id == m.answer).picture;
            expect(content.places[m.place.key]!.file, isNot(right), reason: '${m.id}: its first page would show the answer');
          }
        }
      });

      test('its cover, its city on the World Map and its evidence pictures, registered and bundled', () {
        final cover = ArtAssets.seasonCovers[id];
        if (cover != null) expect(bundled(cover.file), isTrue, reason: cover.file);
        final city = WorldCities.ofSeason(id);
        if (city != null) {
          expect(WorldCities.all.where((c) => c.id == city.id), hasLength(1));
          expect(city.at.dx, inInclusiveRange(0.0, 1.0));
          expect(city.at.dy, inInclusiveRange(0.0, 1.0));
        }
        final evidence = {for (final e in episodes) for (final v in e.allEvidence) v.id};
        for (final MapEntry(:key, :value) in ArtAssets.evidencePictures.entries) {
          if (!key.startsWith('${id.split('_').first}_')) continue;
          expect(evidence, contains(key));
          expect(bundled(value), isTrue, reason: value);
        }
      });
    });

    seasonPlaythroughTests(id);
  }
}
