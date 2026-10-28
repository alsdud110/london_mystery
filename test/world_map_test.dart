import 'dart:convert';
import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show ByteData;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/app.dart';
import 'package:world_mystery/core/constants/app_constants.dart';
import 'package:world_mystery/core/router/app_router.dart';
import 'package:world_mystery/data/models/game_progress.dart';
import 'package:world_mystery/data/models/season.dart';
import 'package:world_mystery/data/models/season_progress.dart';
import 'package:world_mystery/features/game/game_providers.dart';
import 'package:world_mystery/features/world_map/widgets/world_map_view.dart';
import 'package:world_mystery/features/world_map/world_cities.dart';
import 'package:world_mystery/features/world_map/world_map_state.dart';
import 'package:world_mystery/widgets/art_assets.dart';

import 'full_playthrough_test.dart' show wait;
import 'helpers.dart';

void main() {
  final london = season1Cases();
  final ids = [for (final e in london) e.id];

  /// Season 1 with its first [solved] cases solved; [activeBegun]: the case
  /// after them has begun (saves from before profiles).
  Map<String, Object> seasonSaves(int solved, {bool activeBegun = false}) {
    final act = ids[solved == 0 ? 0 : (solved < 12 ? solved : 11)];
    GameProgress solvedCase(String id) => GameProgress(
      detectiveName: 'MINYOUNG',
      introSeen: true,
      completedMissionIds: [for (final m in london.firstWhere((e) => e.id == id).allMissions) m.id],
      startedAt: DateTime(2026, 9, 29, 10),
      completedAt: DateTime(2026, 9, 29, 10, 30),
      playMillis: 0,
    );
    return {
      AppConstants.progressStorageKey: jsonEncode(
        (solved > 0 ? solvedCase('ep01') : GameProgress(detectiveName: 'MINYOUNG', introSeen: activeBegun)).toJson(),
      ),
      for (final id in ids.skip(1).take(solved > 0 ? solved - 1 : 0))
        AppConstants.progressKeyFor(id): jsonEncode(solvedCase(id).toJson()),
      if (activeBegun && solved > 0 && solved < 12)
        AppConstants.progressKeyFor(act): jsonEncode(
          GameProgress(detectiveName: 'MINYOUNG', introSeen: true, startedAt: DateTime(2026, 9, 29, 11), playMillis: 0).toJson(),
        ),
      AppConstants.seasonStorageKey: jsonEncode(
        SeasonProgress(activeEpisodeId: act, solvedEpisodeIds: ids.take(solved).toList()).toJson(),
      ),
    };
  }

  late WidgetRef appRef;
  String path() => appRef.read(routerProvider).routerDelegate.currentConfiguration.uri.toString();

  Future<void> pumpApp(WidgetTester t, Map<String, Object> prefs, {Size size = const Size(360, 640)}) async {
    t.view.physicalSize = size * 3;
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(ProviderScope(
      overrides: await testOverrides(prefs: prefs),
      child: Consumer(builder: (context, ref, _) {
        appRef = ref;
        return const WorldMysteryApp();
      }),
    ));
    await wait(t, const Duration(milliseconds: 300));
  }

  Future<void> openMap(WidgetTester t) async {
    appRef.read(routerProvider).go(Routes.worldMap);
    await wait(t, const Duration(milliseconds: 600));
    expect(path(), Routes.worldMap);
  }

  Finder pin(String cityId) => find.byKey(ValueKey('city-pin-$cityId'));
  Finder card(String cityId) => find.byKey(ValueKey('city-card-$cityId'));
  Finder inCard(String cityId, String text) => find.descendant(of: card(cityId), matching: find.text(text));

  Map<String, Object?> saves() {
    final prefs = appRef.read(sharedPreferencesProvider);
    return {for (final k in prefs.getKeys()) k: prefs.get(k)};
  }

  /// Drags the map until [cityId]'s pin is well inside it, clear of the
  /// map's buttons (east when it is not on the map yet).
  Future<void> bringIntoView(WidgetTester t, String cityId) async {
    final viewer = find.byKey(const ValueKey('world-map-viewer'));
    for (var i = 0; i < 10; i++) {
      final area = t.getRect(viewer);
      final safe = Rect.fromLTRB(area.left + 50, area.top + 50, area.right - 80, area.bottom - 30);
      final f = pin(cityId);
      if (f.evaluate().isNotEmpty && safe.contains(t.getCenter(f))) return;
      final d = f.evaluate().isEmpty ? const Offset(-150, 0) : safe.center - t.getCenter(f);
      await t.drag(viewer, Offset(d.dx.clamp(-150.0, 150.0), d.dy.clamp(-150.0, 150.0)));
      await wait(t, const Duration(milliseconds: 300));
    }
    fail('$cityId could not be brought onto the map');
  }

  Future<void> tapCity(WidgetTester t, String cityId) async {
    await bringIntoView(t, cityId);
    await t.tap(pin(cityId));
    await wait(t, const Duration(milliseconds: 600));
  }

  Matrix4 view(WidgetTester t) =>
      t.widget<InteractiveViewer>(find.byKey(const ValueKey('world-map-viewer'))).transformationController!.value;

  /// Plays Paris from the map's card (London complete).
  Future<void> beginParis(WidgetTester t) async {
    await openMap(t);
    await t.tap(find.byKey(const ValueKey('city-card-enter')));
    await wait(t, const Duration(milliseconds: 600));
  }

  void solveParis(int count) {
    final cases = SeasonAvailability.casesOf(SeasonIds.paris, appRef.read(allEpisodesProvider));
    for (final e in cases.take(count)) {
      appRef.read(seasonProvider.notifier).markSolved(e.id);
    }
  }

  group('the cities', () {
    test('London and Paris have their seasons; Tokyo, Rome and Seoul none yet', () {
      expect([for (final c in WorldCities.all) c.name], ['London', 'Paris', 'Rome', 'Tokyo', 'Seoul']);
      expect(WorldCities.london.seasonId, SeasonIds.london);
      expect(WorldCities.paris.seasonId, SeasonIds.paris);
      for (final c in [WorldCities.rome, WorldCities.tokyo, WorldCities.seoul]) {
        expect(c.seasonId, isNull, reason: c.name);
      }
      expect({for (final c in WorldCities.all) c.id}.length, WorldCities.all.length);
    });

    test('a city is placed by its latitude and longitude', () {
      const nullIsland = WorldCity(id: 'x', name: 'X', latitude: 0, longitude: 0);
      expect(nullIsland.at, const Offset(0.5, 0.5));
      const corner = WorldCity(id: 'y', name: 'Y', latitude: 90, longitude: -180);
      expect(corner.at, Offset.zero);
      for (final c in WorldCities.all) {
        expect(c.at.dx, inInclusiveRange(0, 1), reason: c.name);
        expect(c.at.dy, inInclusiveRange(0, 1), reason: c.name);
      }
      // Paris east of London, Tokyo east of Seoul.
      expect(WorldCities.paris.at.dx, greaterThan(WorldCities.london.at.dx));
      expect(WorldCities.tokyo.at.dx, greaterThan(WorldCities.seoul.at.dx));
    });

    test('pins that would cover each other step apart, west to east', () {
      final out = spreadPins(const [Offset(100, 100), Offset(108, 106), Offset(300, 100)], gap: 80, rise: 60);
      expect(out[1].dx - out[0].dx, closeTo(80, 1e-9));
      expect(out[0].dy, out[1].dy);
      expect(out[2], const Offset(300, 100)); // far away: where it is
      // London, Paris, Rome: a row, west to east.
      final row = spreadPins(const [Offset(180, 74), Offset(185, 81), Offset(204, 93)], gap: 80, rise: 60);
      expect(row[1].dx - row[0].dx, closeTo(80, 1e-9));
      expect(row[2].dx - row[1].dx, closeTo(80, 1e-9));
      final ring = spreadPins(const [Offset(0, 0), Offset(4, 0), Offset(0, 4), Offset(4, 4)], gap: 80, rise: 60);
      for (var i = 0; i < 4; i++) {
        for (var j = i + 1; j < 4; j++) {
          expect((ring[i] - ring[j]).distance, greaterThanOrEqualTo(79.9));
        }
      }
    });
  });

  group('where the map opens', () {
    testWidgets('a new detective: London, ready to begin; Paris locked; the rest coming soon', (t) async {
      await pumpApp(t, seasonSaves(0));
      await openMap(t);
      expect(appRef.read(homeCityIdProvider), WorldCities.london.id);
      expect(find.text('WORLD MYSTERY'), findsOneWidget);
      expect(find.text('Detective MINYOUNG'), findsOneWidget);
      expect(inCard('london', 'SEASON 1'), findsOneWidget);
      expect(inCard('london', 'LONDON'), findsOneWidget);
      expect(inCard('london', 'Shadows over London'), findsOneWidget);
      expect(inCard('london', 'BEGIN ADVENTURE'), findsOneWidget);
      final states = {for (final s in appRef.read(worldCityStatesProvider)) s.city.id: s.status};
      expect(states, {
        'london': WorldCityStatus.playable,
        'paris': WorldCityStatus.locked,
        'rome': WorldCityStatus.comingSoon,
        'tokyo': WorldCityStatus.comingSoon,
        'seoul': WorldCityStatus.comingSoon,
      });
      // London at the middle of the map, Paris beside it, named.
      final viewer = t.getRect(find.byKey(const ValueKey('world-map-viewer')));
      expect((t.getCenter(pin('london')).dx - viewer.center.dx).abs(), lessThan(90));
      expect(find.descendant(of: pin('paris'), matching: find.text('PARIS')), findsOneWidget);
    });

    testWidgets('London under way: London, to continue', (t) async {
      await pumpApp(t, seasonSaves(3, activeBegun: true));
      await openMap(t);
      expect(appRef.read(homeCityIdProvider), WorldCities.london.id);
      expect(inCard('london', 'CONTINUE'), findsOneWidget);
      expect(inCard('london', 'IN PROGRESS • 3 / 12 SOLVED'), findsOneWidget);
    });

    testWidgets('London solved, Paris not begun: Paris — and looking does not choose it', (t) async {
      await pumpApp(t, seasonSaves(12));
      final before = saves();
      await openMap(t);
      expect(appRef.read(homeCityIdProvider), WorldCities.paris.id);
      expect(inCard('paris', 'SEASON 2'), findsOneWidget);
      expect(inCard('paris', 'Paris Stands Still'), findsOneWidget);
      expect(inCard('paris', 'BEGIN ADVENTURE'), findsOneWidget);
      // Opening the map chose nothing and saved nothing.
      expect(appRef.read(selectedSeasonIdProvider), SeasonIds.london);
      expect(saves(), before);
    });

    testWidgets('Paris under way: Paris', (t) async {
      await pumpApp(t, seasonSaves(12));
      await beginParis(t);
      expect(appRef.read(selectedSeasonIdProvider), SeasonIds.paris);
      solveParis(2);
      await openMap(t);
      expect(appRef.read(homeCityIdProvider), WorldCities.paris.id);
      expect(inCard('paris', 'CONTINUE'), findsOneWidget);
      expect(inCard('paris', 'IN PROGRESS • 2 / 12 SOLVED'), findsOneWidget);
    });

    testWidgets('Paris solved, no next season out: Paris', (t) async {
      await pumpApp(t, seasonSaves(12));
      await beginParis(t);
      solveParis(12);
      await openMap(t);
      expect(appRef.read(homeCityIdProvider), WorldCities.paris.id);
      expect(inCard('paris', 'REVISIT'), findsOneWidget);
      expect(inCard('paris', 'COMPLETED • 12 / 12 SOLVED'), findsOneWidget);
    });
  });

  group('choosing on the map', () {
    testWidgets('a pin shows its city on the card; only the card button plays a season', (t) async {
      await pumpApp(t, seasonSaves(0));
      await openMap(t);
      final before = saves();

      await tapCity(t, 'paris');
      expect(inCard('paris', 'PARIS'), findsOneWidget);
      expect(inCard('paris', 'Paris Stands Still'), findsOneWidget);
      expect(inCard('paris', 'Complete London to unlock.'), findsOneWidget);
      expect(inCard('paris', 'LOCKED'), findsOneWidget);
      // The locked button does nothing.
      await t.tap(find.byKey(const ValueKey('city-card-enter')));
      await wait(t, const Duration(milliseconds: 400));
      expect(path(), Routes.worldMap);

      // Tokyo is east: the map is dragged there.
      await tapCity(t, 'tokyo');
      expect(inCard('tokyo', 'TOKYO'), findsOneWidget);
      expect(inCard('tokyo', 'COMING SOON'), findsWidgets);
      expect(inCard('tokyo', 'A new mystery is on its way.'), findsOneWidget);

      expect(appRef.read(selectedSeasonIdProvider), SeasonIds.london);
      expect(saves(), before);

      // Back to my city: London again.
      await t.tap(find.byKey(const ValueKey('world-map-home')));
      await wait(t, const Duration(milliseconds: 600));
      expect(card('london'), findsOneWidget);
    });

    testWidgets('BEGIN ADVENTURE plays the city season from its cover', (t) async {
      await pumpApp(t, seasonSaves(12));
      await beginParis(t);
      expect(appRef.read(selectedSeasonIdProvider), SeasonIds.paris);
      expect(path(), Routes.seasonOf(SeasonIds.paris));
    });

    testWidgets('the map pinches, drags and zooms with its buttons, inside the world', (t) async {
      await pumpApp(t, seasonSaves(0));
      await openMap(t);
      final start = view(t).clone();
      expect(start.getMaxScaleOnAxis(), 1);

      await t.tap(find.byKey(const ValueKey('world-map-zoom-in')));
      await wait(t, const Duration(milliseconds: 600));
      expect(view(t).getMaxScaleOnAxis(), closeTo(WorldMapView.zoomStep, 0.01));
      final pinSize = t.getRect(pin('london')).size;

      await t.tap(find.byKey(const ValueKey('world-map-zoom-in')));
      await wait(t, const Duration(milliseconds: 600));
      // Pins keep their size on screen.
      final zoomed = t.getRect(pin('london')).size;
      expect(zoomed.width, closeTo(pinSize.width, 0.5));
      expect(zoomed.height, closeTo(pinSize.height, 0.5));

      await t.tap(find.byKey(const ValueKey('world-map-zoom-out')));
      await wait(t, const Duration(milliseconds: 600));
      expect(view(t).getMaxScaleOnAxis(), closeTo(WorldMapView.zoomStep, 0.01));

      final moved = view(t).getTranslation();
      await t.drag(find.byKey(const ValueKey('world-map-viewer')), const Offset(-120, 0));
      await wait(t, const Duration(milliseconds: 400));
      expect(view(t).getTranslation().x, lessThan(moved.x));

      // Zoomed out as far as it goes: the world still covers the viewport.
      for (var i = 0; i < 4; i++) {
        await t.tap(find.byKey(const ValueKey('world-map-zoom-out')));
        await wait(t, const Duration(milliseconds: 600));
      }
      expect(view(t).getMaxScaleOnAxis(), 1);
      expect(view(t).getTranslation().x, lessThanOrEqualTo(WorldMapView.edge));
      expect(view(t).getTranslation().y, lessThanOrEqualTo(0));
    });

    testWidgets('World Archive opens from the map header', (t) async {
      await pumpApp(t, seasonSaves(0));
      await openMap(t);
      await t.tap(find.byKey(const ValueKey('world-map-archive')));
      await wait(t, const Duration(milliseconds: 600));
      expect(path(), Routes.seasons);
    });
  });

  // MAP-5: the World Map as the hub — a season played from it goes back to
  // it; what cannot be entered stays on the map, with nothing saved.
  group('the hub', () {
    Future<void> back(WidgetTester t, {bool system = false}) async {
      if (system) {
        await t.binding.handlePopRoute();
      } else {
        await t.tap(find.byTooltip('Back'));
      }
      await wait(t, const Duration(milliseconds: 1400));
    }

    testWidgets('London: its cover; its opening and its case files go back up to the map', (t) async {
      await pumpApp(t, seasonSaves(0));
      await openMap(t);
      await t.tap(find.byKey(const ValueKey('city-card-enter')));
      await wait(t, const Duration(milliseconds: 1600));
      expect(path(), Routes.seasonOf(SeasonIds.london));
      expect(find.text('BEGIN SEASON ONE'), findsOneWidget, reason: 'the cover, not skipped');
      await back(t);
      expect(path(), Routes.worldMap);

      // The opening's first scene → the cover → the map (system back).
      appRef.read(routerProvider).go(Routes.prologue);
      await wait(t, const Duration(milliseconds: 1400));
      await back(t, system: true);
      expect(path(), Routes.season);
      await back(t, system: true);
      expect(path(), Routes.worldMap);

      // The case files → the season → the map.
      appRef.read(routerProvider).go(Routes.episodes);
      await wait(t, const Duration(milliseconds: 1400));
      await back(t, system: true);
      expect(path(), Routes.season);
      await back(t, system: true);
      expect(path(), Routes.worldMap);
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('Paris unlocked: its cover, and back to the map (arrow and system back)', (t) async {
      await pumpApp(t, seasonSaves(12));
      await beginParis(t);
      await wait(t, const Duration(milliseconds: 1200));
      expect(path(), Routes.seasonOf(SeasonIds.paris));
      expect(find.text('BEGIN INVESTIGATION'), findsOneWidget, reason: "Paris's cover");
      await back(t);
      expect(path(), Routes.worldMap);
      appRef.read(routerProvider).go(Routes.season);
      await wait(t, const Duration(milliseconds: 1400));
      await back(t, system: true);
      expect(path(), Routes.worldMap);
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('a coming-soon city: nothing to enter, nothing saved', (t) async {
      await pumpApp(t, seasonSaves(3, activeBegun: true));
      await openMap(t);
      final before = saves();
      for (final id in ['tokyo', 'rome', 'seoul']) {
        await tapCity(t, id);
        await t.tap(find.byKey(const ValueKey('city-card-enter')), warnIfMissed: false);
        await wait(t, const Duration(milliseconds: 400));
        expect(path(), Routes.worldMap, reason: id);
      }
      expect(appRef.read(selectedSeasonIdProvider), SeasonIds.london);
      expect(saves(), before);
    });

    testWidgets("the case map's menu leaves to the World Map; CONTINUE comes back to the case, nothing changed", (t) async {
      await pumpApp(t, seasonSaves(3, activeBegun: true));
      appRef.read(routerProvider).go(Routes.map);
      await wait(t, const Duration(milliseconds: 1500));
      final before = saves();
      final episode = appRef.read(currentEpisodeProvider).id;
      await t.tap(find.byTooltip('Menu'));
      await wait(t);
      await t.tap(find.text('World map'));
      await wait(t, const Duration(milliseconds: 1200));
      expect(path(), Routes.worldMap);
      expect(saves(), before, reason: 'the case stays as it was');
      expect(inCard('london', 'CONTINUE'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('city-card-enter')));
      await wait(t, const Duration(milliseconds: 1500));
      expect(path(), Routes.map, reason: 'back on the case under way');
      expect(appRef.read(currentEpisodeProvider).id, episode);
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('a completed season: REVISIT opens its board, as before', (t) async {
      await pumpApp(t, seasonSaves(12));
      await openMap(t);
      await tapCity(t, 'london');
      expect(inCard('london', 'REVISIT'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('city-card-enter')));
      await wait(t, const Duration(milliseconds: 2400));
      expect(path(), Routes.seasonOf(SeasonIds.london));
      expect(find.text('COMPLETED'), findsOneWidget);
      await wait(t, const Duration(seconds: 3));
    });
  });

  group('small screens', () {
    for (final (size, scale) in [(const Size(320, 568), 1.0), (const Size(320, 568), 1.3), (const Size(360, 640), 1.3)]) {
      testWidgets('every card fits at ${size.width.toInt()}x${size.height.toInt()}, text x$scale', (t) async {
        t.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpApp(t, seasonSaves(3, activeBegun: true), size: size);
        await openMap(t);
        expect(t.takeException(), isNull);
        for (final id in ['paris', 'london', 'rome', 'seoul', 'tokyo']) {
          await tapCity(t, id);
          expect(card(id), findsOneWidget);
          expect(t.takeException(), isNull, reason: id);
        }
      });
    }
  });

  test('the world map artwork is a 2:1 PNG, listed in the app', () {
    final file = File(ArtAssets.worldMap);
    expect(file.existsSync(), isTrue);
    // The PNG header: width and height, big-endian, at bytes 16..23.
    final head = ByteData.sublistView(file.readAsBytesSync().sublist(16, 24));
    expect(head.getUint32(0) / head.getUint32(4), ArtAssets.worldMapAspect);
    expect(File('pubspec.yaml').readAsStringSync(), contains('- assets/shared/world_map/'));
  });
}
