import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/profile.dart';
import 'package:world_mystery/data/models/season.dart';
import 'package:world_mystery/data/repositories/episode_repository.dart';
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/features/game/game_providers.dart';
import 'package:world_mystery/features/mission_map/map_world.dart';
import 'package:world_mystery/features/mission_map/mission_map_screen.dart';
import 'package:world_mystery/features/mission_map/widgets/london_map_painter.dart';
import 'package:world_mystery/features/mission_map/widgets/map_pin.dart';
import 'package:world_mystery/widgets/art_assets.dart';
import 'package:world_mystery/widgets/place_art.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';
import 'multi_season_test.dart' show assetOf, parisCase, season1Finished, showsLondon;

/// The ten Paris landmarks where they were measured on the artwork.
const measured = <ParisLandmark, Offset>{
  ParisLandmark.gareDuNord: Offset(0.768, 0.200),
  ParisLandmark.montmartre: Offset(0.555, 0.098),
  ParisLandmark.seineQuays: Offset(0.602, 0.596),
  ParisLandmark.louvre: Offset(0.501, 0.441),
  ParisLandmark.notreDame: Offset(0.732, 0.566),
  ParisLandmark.eiffelTower: Offset(0.120, 0.562),
  ParisLandmark.palaisGarnier: Offset(0.391, 0.273),
  ParisLandmark.luxembourgGardens: Offset(0.475, 0.771),
  ParisLandmark.arcDeTriomphe: Offset(0.128, 0.246),
  ParisLandmark.artsEtMetiers: Offset(0.684, 0.381),
};

/// Season 2's cases and their places, as decided.
const caseMap = <String, ParisLandmark>{
  's2_ep01': ParisLandmark.gareDuNord,
  's2_ep02': ParisLandmark.montmartre,
  // Case 03 climbs the Eiffel Tower; its plaque points Case 04 to the
  // Seine; Case 06 is at the Louvre (2026-10-21).
  's2_ep03': ParisLandmark.eiffelTower,
  's2_ep04': ParisLandmark.seineQuays,
  's2_ep05': ParisLandmark.notreDame,
  's2_ep06': ParisLandmark.louvre,
  's2_ep07': ParisLandmark.palaisGarnier,
  's2_ep08': ParisLandmark.montmartre,
  's2_ep09': ParisLandmark.luxembourgGardens,
  's2_ep10': ParisLandmark.arcDeTriomphe,
  's2_ep11': ParisLandmark.luxembourgGardens,
  's2_ep12': ParisLandmark.artsEtMetiers,
};

/// Paris Case [n]: Case 01 as it is in the game, a stand-in for the others
/// (tests only).
Episode caseOf(int n) =>
    n == 1 ? MockEpisodeRepository.bundled().firstWhere((e) => e.id == 's2_ep01') : parisCase(n);

/// Every mission of [e] is in the group around [l] on the map (its group is
/// moved down from the top edge as a whole).
void expectAround(Episode e, MapLandmark l, Map<String, Offset> places) {
  final drop = math.max(0.0, MapWorld.topMargin - (l.at.dy - MapWorld.groupRadius));
  for (final m in e.allMissions) {
    final p = places[m.id]!;
    expect((p - l.at).distance, lessThanOrEqualTo(MapWorld.groupRadius + drop + 1e-9), reason: '${m.id} at ${l.name}');
  }
}

void main() {
  group('the Paris map', () {
    test('is registered for Season 2: its own artwork, size and ratio', () {
      expect(SeasonMap.forSeason(SeasonIds.paris), same(SeasonMap.paris));
      expect(SeasonMap.bySeason.keys, [SeasonIds.london, SeasonIds.paris]);
      expect(SeasonMap.paris.artwork, ArtAssets.parisMap);
      expect(ArtAssets.parisMap, 'assets/seasons/season_02_paris/locations/map/paris_mystery.png');
      expect(SeasonMap.paris.aspect, 3 / 2);
      expect(SeasonMap.paris.pixels, ArtAssets.parisMapPixels);
      // The file is in the game, and is the size the map is decoded at.
      final file = File(ArtAssets.parisMap);
      expect(file.existsSync(), isTrue);
      final png = file.readAsBytesSync();
      int u32(int at) => (png[at] << 24) | (png[at + 1] << 16) | (png[at + 2] << 8) | png[at + 3];
      expect(png.sublist(0, 8), [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
      expect((u32(16), u32(20)), (1536, 1024));
      expect(SeasonMap.paris.pixels.width, 1536);
      expect(SeasonMap.paris.pixels.height, 1024);
      expect(File('pubspec.yaml').readAsStringSync(), contains('- assets/seasons/season_02_paris/locations/map/'));
      expect(SeasonMap.paris.artwork, isNot(ArtAssets.londonMap));
    });

    test('its ten landmarks stand where they were measured, inside the map', () {
      expect(SeasonMap.paris.landmarks, ParisLandmark.values);
      expect(ParisLandmark.values, hasLength(10));
      expect({for (final l in ParisLandmark.values) l: l.at}, measured);
      expect({for (final l in ParisLandmark.values) l.name}, {
        'Gare du Nord', 'Montmartre', 'Seine Quays', 'Louvre', 'Notre-Dame',
        'Eiffel Tower', 'Palais Garnier', 'Luxembourg Gardens', 'Arc de Triomphe', 'Arts et Métiers',
      });
      for (final l in ParisLandmark.values) {
        expect(l.at.dx, inInclusiveRange(0.05, 0.95), reason: l.name);
        expect(l.at.dy, inInclusiveRange(0.05, 0.95), reason: l.name);
        // No scene picture yet: none is named, so none is missing.
        expect(l.artwork, isNull, reason: l.name);
      }
      // Two landmarks never share a spot (the closest: the bookstalls and Notre-Dame).
      final ls = ParisLandmark.values;
      for (var i = 0; i < ls.length; i++) {
        for (var j = i + 1; j < ls.length; j++) {
          final d = Offset((ls[i].at.dx - ls[j].at.dx) * SeasonMap.paris.aspect, ls[i].at.dy - ls[j].at.dy).distance;
          expect(d, greaterThan(0.15), reason: '${ls[i].name} / ${ls[j].name}');
        }
      }
    });

    test('its twelve cases are at their landmarks; two pairs share one', () {
      expect(SeasonMap.paris.caseLandmarks, caseMap);
      expect(SeasonMap.paris.missionLandmarks, isEmpty, reason: 'mapped by case');
      expect({...caseMap.values}, {...ParisLandmark.values}, reason: 'every landmark has a case');
      expect(caseMap['s2_ep02'], same(caseMap['s2_ep08']));
      expect(caseMap['s2_ep09'], same(caseMap['s2_ep11']));
      for (final MapEntry(key: caseId, value: l) in caseMap.entries) {
        expect(SeasonMap.paris.landmarkFor('${caseId}_m1', caseId), l, reason: caseId);
        expect(SeasonMap.paris.landmarkFor('${caseId}_final', caseId), l, reason: caseId);
      }
    });

    test('a case\'s missions gather at its landmark; cases sharing one keep their own missions', () {
      for (final n in [1, 2, 3, 8, 9, 11, 12]) {
        final e = caseOf(n);
        final places = MapWorld.places(e, map: SeasonMap.paris);
        expect(places.keys, [for (final m in e.allMissions) m.id], reason: e.id);
        expectAround(e, caseMap[e.id]!, places);
      }
      // Montmartre is above the top margin: its missions are brought down to it.
      final m2 = MapWorld.places(caseOf(2), map: SeasonMap.paris);
      for (final p in m2.values) {
        expect(p.dy, greaterThanOrEqualTo(MapWorld.topMargin - 1e-9));
      }
      // Case 02 and Case 08 at Montmartre: the same place, their own pins.
      expect(MapWorld.places(caseOf(8), map: SeasonMap.paris).keys.toSet().intersection(m2.keys.toSet()), isEmpty);
    });

    test('a mission of its own goes to its own landmark before its case\'s', () {
      const map = SeasonMap(
        artwork: ArtAssets.parisMap,
        pixels: ArtAssets.parisMapPixels,
        aspect: ArtAssets.parisMapAspect,
        landmarks: ParisLandmark.values,
        missionLandmarks: {'s2_ep01_final': ParisLandmark.louvre},
        caseLandmarks: ParisLandmark.cases,
      );
      expect(map.landmarkFor('s2_ep01_final', 's2_ep01'), ParisLandmark.louvre);
      expect(map.landmarkFor('s2_ep01_m1', 's2_ep01'), ParisLandmark.gareDuNord);
      expect(map.landmarkFor('s2_ep99_m1', 's2_ep99'), isNull);
      final e = caseOf(1);
      final places = MapWorld.places(e, map: map);
      expect((places['s2_ep01_final']! - ParisLandmark.louvre.at).distance, lessThan(1e-9), reason: 'alone at the Louvre');
      // The others gather at Gare du Nord (brought down from the top margin as a group).
      final drop = math.max(0.0, MapWorld.topMargin - (ParisLandmark.gareDuNord.at.dy - MapWorld.groupRadius));
      for (final m in e.missions) {
        expect((places[m.id]! - ParisLandmark.gareDuNord.at).distance, lessThanOrEqualTo(MapWorld.groupRadius + drop + 1e-9));
        expect((places[m.id]! - ParisLandmark.louvre.at).distance, greaterThan(MapWorld.groupRadius), reason: '${m.id} is not at the Louvre');
      }
    });

    test('each season keeps to its own map; London as it was', () {
      expect(SeasonMap.london.caseLandmarks, isEmpty);
      expect(SeasonMap.london.missionLandmarks.keys.where((id) => id.startsWith('s2_')), isEmpty);
      for (final e in season1Cases()) {
        for (final m in e.allMissions) {
          expect(SeasonMap.paris.landmarkFor(m.id, e.id), isNull, reason: '${m.id} is not in Paris');
          expect(SeasonMap.london.landmarkFor(m.id, e.id), MapWorld.missionLandmarks[m.id], reason: m.id);
          expect(SeasonMap.landmarkOf(m.id), MapWorld.missionLandmarks[m.id], reason: m.id);
          expect(MapWorld.places(e)[m.id], MapWorld.places(e, map: SeasonMap.london)[m.id]);
        }
        expect(PlaceArt.placeOf(e.allMissions.first), isNotNull);
      }
      expect(SeasonMap.london.landmarkFor('s2_ep01_m1', 's2_ep01'), isNull);
    });
  });

  group('Montmartre, at the top of the map', () {
    test('its places stay near the hill: only its group is less tall, the margin kept', () {
      expect(SeasonMap.paris.groupHeights, {ParisLandmark.montmartre: 0.6}, reason: 'Montmartre only');
      expect(SeasonMap.london.groupHeights, isEmpty);
      expect(ParisLandmark.montmartre.at, const Offset(0.555, 0.098), reason: 'the landmark stays where it is drawn');
      for (final n in [2, 8]) {
        final e = caseOf(n);
        final places = MapWorld.places(e, map: SeasonMap.paris);
        final ys = [for (final p in places.values) p.dy];
        // Below the top margin (room for YOU'RE HERE), within 0.6 of a group's height.
        expect(ys.reduce(math.min), closeTo(MapWorld.topMargin, 1e-9));
        expect(ys.reduce(math.max), lessThanOrEqualTo(MapWorld.topMargin + 2 * 0.6 * MapWorld.groupRadius + 1e-9));
        expect(ys.reduce(math.max), lessThan(0.27), reason: 'was 0.344 with a full-height group');
        // Still apart on the smallest phone's map world (738 × 492 px): no two marks touch.
        final ps = places.values.toList();
        for (var i = 0; i < ps.length; i++) {
          for (var j = i + 1; j < ps.length; j++) {
            final gap = Offset((ps[i].dx - ps[j].dx) * 738, (ps[i].dy - ps[j].dy) * 492).distance;
            expect(gap, greaterThan(2 * MapPin.markRadius), reason: '${e.id} places $i/$j');
          }
        }
        // Only the height changed: each place keeps its left-right spot.
        final full = MapWorld.places(e, map: const SeasonMap(
          artwork: ArtAssets.parisMap,
          pixels: ArtAssets.parisMapPixels,
          aspect: ArtAssets.parisMapAspect,
          landmarks: ParisLandmark.values,
          caseLandmarks: ParisLandmark.cases,
        ));
        for (final m in e.allMissions) {
          expect(places[m.id]!.dx, full[m.id]!.dx, reason: m.id);
        }
      }
      // Case 02 and Case 08 put their places at the same spots of the hill.
      final c2 = MapWorld.places(caseOf(2), map: SeasonMap.paris).values.toList();
      final c8 = MapWorld.places(caseOf(8), map: SeasonMap.paris).values.toList();
      expect(c8, c2);
    });

    test('every other Paris landmark keeps its full-height group', () {
      const full = SeasonMap(
        artwork: ArtAssets.parisMap,
        pixels: ArtAssets.parisMapPixels,
        aspect: ArtAssets.parisMapAspect,
        landmarks: ParisLandmark.values,
        caseLandmarks: ParisLandmark.cases,
      );
      for (var n = 1; n <= 12; n++) {
        if (n == 2 || n == 8) continue;
        final e = caseOf(n);
        expect(MapWorld.places(e, map: SeasonMap.paris), MapWorld.places(e, map: full), reason: e.id);
      }
    });

    test('London\'s places are exactly what they were', () {
      // Measured before the per-map group heights existed.
      const before = {
        'm01': Offset(0.53, 0.17),
        'm02': Offset(0.385, 0.3),
        'm03': Offset(0.53, 0.58),
        'm04': Offset(0.21, 0.44),
        'm05': Offset(0.16977873200349974, 0.6808529300325821),
        'final': Offset(0.3202212679965002, 0.599147069967418),
        'ep05_m1': Offset(0.7950501935745663, 0.48232341554437275),
        'ep05_m2': Offset(0.8941753345773094, 0.42414126756450177),
        'ep05_m3': Offset(0.8036697710530657, 0.3594944364757563),
        'ep05_final': Offset(0.9071047007950586, 0.5340408804153692),
        'ep10_m1': Offset(0.8072208689422745, 0.5392781865552532),
        'ep10_m2': Offset(0.9299783754557477, 0.44721005667014835),
        'ep10_m3': Offset(0.8128007556019778, 0.36351175677459846),
        'ep10_final': Offset(0.915, 0.69),
        'ep12_m1': Offset(0.5186862915010153, 0.69879393923934),
        'ep12_m2': Offset(0.53, 0.17),
        'ep12_m3': Offset(0.85, 0.45),
        'ep12_final': Offset(0.5413137084989847, 0.46120606076066006),
      };
      final now = {for (final e in MockEpisodeRepository.bundled()) ...MapWorld.places(e)};
      for (final MapEntry(:key, :value) in before.entries) {
        expect(now[key], value, reason: key);
      }
    });
  });

  group('Season 2 and its release', () {
    test('as shipped, released: with Season 1 finished its map opens', () async {
      SharedPreferences.setMockInitialValues({});
      final c = ProviderContainer(overrides: await testOverridesFor(await SharedPreferences.getInstance()));
      addTearDown(c.dispose);
      c.read(gameControllerProvider.notifier).createDetective('Kim', DetectiveAvatar.boy);
      c.read(progressRepositoryProvider).saveSeason(season1Finished);
      c.invalidate(seasonProvider);
      final paris = c.read(seasonAvailabilityProvider(SeasonIds.paris))!;
      expect(paris.released, isTrue);
      expect(paris.status, SeasonStatus.open);
      expect(paris.canEnter, isTrue);
      expect(c.read(gameControllerProvider.notifier).openSeason(SeasonIds.paris), isTrue);
      expect(c.read(selectedSeasonIdProvider), SeasonIds.paris);
      expect(c.read(playableSeasonCountProvider), 2);
    });

    test('not yet released, its map and Case 01 open no season', () async {
      SharedPreferences.setMockInitialValues({});
      final c = ProviderContainer(overrides: [
        ...await testOverridesFor(await SharedPreferences.getInstance()),
        // Paris as it was before its release (2026-10-21).
        seasonReleasedProvider.overrideWithValue((id) => id != SeasonIds.paris),
      ]);
      addTearDown(c.dispose);
      c.read(gameControllerProvider.notifier).createDetective('Kim', DetectiveAvatar.boy);
      c.read(progressRepositoryProvider).saveSeason(season1Finished);
      c.invalidate(seasonProvider);
      final paris = c.read(seasonAvailabilityProvider(SeasonIds.paris))!;
      expect(paris.hasMap, isTrue);
      expect(paris.hasCases, isTrue);
      expect(paris.released, isFalse);
      expect(paris.status, SeasonStatus.comingSoon);
      expect(paris.canEnter, isFalse);
      expect(c.read(gameControllerProvider.notifier).openSeason(SeasonIds.paris), isFalse);
      expect(c.read(selectedSeasonIdProvider), SeasonIds.london);
      expect(c.read(playableSeasonCountProvider), 1);
    });
  });

  group('on the map page', () {
    /// Season 2 played as released, its Case 01 and stand-in later cases
    /// (tests only), on [maps].
    Future<ProviderContainer> playParis(Map<String, SeasonMap> maps, {int caseNumber = 1}) async {
      SharedPreferences.setMockInitialValues({});
      final c = ProviderContainer(
        overrides: [
          ...await testOverridesFor(await SharedPreferences.getInstance()),
          allEpisodesProvider.overrideWithValue([...MockEpisodeRepository.bundled(), for (var n = 2; n <= 12; n++) parisCase(n)]),
          seasonMapsProvider.overrideWithValue(maps),
          seasonReleasedProvider.overrideWithValue((_) => true),
        ],
      );
      final ctrl = c.read(gameControllerProvider.notifier);
      ctrl.createDetective('Kim', DetectiveAvatar.boy);
      c.read(progressRepositoryProvider).saveSeason(season1Finished);
      c.invalidate(seasonProvider);
      expect(ctrl.openSeason(SeasonIds.paris), isTrue);
      c.read(operatorAccessSwitchProvider.notifier).set(true); // open any Paris case
      expect(ctrl.openEpisode('s2_ep${caseNumber.toString().padLeft(2, '0')}'), isTrue);
      ctrl.startInvestigation();
      return c;
    }

    Future<void> pumpMap(WidgetTester t, ProviderContainer c) async {
      t.view.physicalSize = const Size(390, 844) * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(UncontrolledProviderScope(container: c, child: const MaterialApp(home: MissionMapScreen())));
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300))); // the artwork loads (or fails)
      await t.pump(const Duration(milliseconds: 1500));
    }

    Finder lettered(String name) => find.text(name, findRichText: true);

    testWidgets('Paris\'s artwork and names; the current place says YOU\'RE HERE, its name on the pin', (t) async {
      final c = await playParis(SeasonMap.bySeason, caseNumber: 8);
      addTearDown(c.dispose);
      await pumpMap(t, c);
      expect(find.byWidgetPredicate((w) => w is Image && assetOf(w.image) == ArtAssets.parisMap), findsOneWidget);
      expect(showsLondon(), isFalse);
      expect(lettered("YOU'RE HERE"), findsWidgets);
      // Montmartre (Case 08's place) is named by its pin; the others are lettered.
      expect(lettered('Montmartre'), findsNothing);
      for (final name in ['Louvre', 'Notre-Dame', 'Seine Quays', 'Arts et Métiers', 'Eiffel Tower']) {
        expect(lettered(name), findsWidgets, reason: name);
      }
      expect(lettered("King's Cross"), findsNothing, reason: 'no London landmark in Paris');
      // GO TO the case's own first place (not Case 02's, at the same landmark).
      final current = c.read(gameControllerProvider).currentMission(c.read(currentEpisodeProvider))!;
      expect(current.id, 's2_ep08_m1');
      expect(find.bySemanticsLabel('GO TO ${current.location}'), findsOneWidget);
      expect(find.byKey(const ValueKey('pin-s2_ep02_m1')), findsNothing);
      expect(t.takeException(), isNull);
      await t.pump(const Duration(seconds: 3));
    });

    testWidgets('a missing Paris artwork shows parchment, never London\'s map', (t) async {
      const missing = SeasonMap(
        artwork: 'assets/seasons/season_02_paris/locations/map/missing.png',
        pixels: ArtAssets.parisMapPixels,
        aspect: ArtAssets.parisMapAspect,
        landmarks: ParisLandmark.values,
        caseLandmarks: ParisLandmark.cases,
      );
      final c = await playParis({SeasonIds.london: SeasonMap.london, SeasonIds.paris: missing});
      addTearDown(c.dispose);
      await pumpMap(t, c);
      expect(find.byKey(const ValueKey('map-artwork-missing')), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is CustomPaint && w.painter is LondonMapPainter && (w.painter! as LondonMapPainter).drawMap),
        findsNothing,
        reason: 'London is drawn in code only for London',
      );
      expect(showsLondon(), isFalse);
      expect(t.takeException(), isNull);
      await t.pump(const Duration(seconds: 3));
    });
  });
}
