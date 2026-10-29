import 'dart:convert';
import 'dart:io' show File;
import 'dart:math' as math;

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

  /// The part of the map in view: between the header and the card.
  Rect inView(WidgetTester t) {
    final area = t.getRect(find.byKey(const ValueKey('world-map-viewer')));
    final header = t.getRect(find.byKey(const ValueKey('world-map-header')));
    final card = t.getRect(find.byKey(const ValueKey('world-map-card')));
    return Rect.fromLTRB(area.left, header.bottom, area.right, card.top);
  }

  /// Drags the map until [cityId]'s pin is well inside the part in view,
  /// clear of the map's buttons (east when it is not on the map yet).
  Future<void> bringIntoView(WidgetTester t, String cityId) async {
    final viewer = find.byKey(const ValueKey('world-map-viewer'));
    for (var i = 0; i < 10; i++) {
      final area = inView(t);
      final safe = Rect.fromLTRB(area.left + 50, area.top + 40, area.right - 80, area.bottom - 30);
      final f = pin(cityId);
      if (f.evaluate().isNotEmpty && safe.contains(t.getCenter(f))) return;
      // Where the city is on screen now, on the map or off it (the world
      // covers the viewer: its height, twice as wide).
      final box = t.getRect(viewer);
      final h = math.max(box.height, box.width / ArtAssets.worldMapAspect);
      final city = WorldCities.all.firstWhere((c) => c.id == cityId);
      final m = t.widget<InteractiveViewer>(viewer).transformationController!.value;
      final at = MatrixUtils.transformPoint(m, Offset(city.at.dx * h * ArtAssets.worldMapAspect, city.at.dy * h)) + box.topLeft;
      final d = safe.center - at;
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

    test('a city with no painted marker is placed by its latitude and longitude', () {
      const northWest = WorldCity(id: 'x', name: 'X', latitude: ArtAssets.worldMapNorth, longitude: ArtAssets.worldMapWest);
      expect(northWest.at, Offset.zero);
      const southEast = WorldCity(id: 'y', name: 'Y', latitude: ArtAssets.worldMapSouth, longitude: ArtAssets.worldMapEast);
      expect(southEast.at.dx, closeTo(1, 1e-9));
      expect(southEast.at.dy, closeTo(1, 1e-9));
      const marked = WorldCity(id: 'z', name: 'Z', latitude: 0, longitude: 0, mapAt: Offset(0.25, 0.75));
      expect(marked.at, const Offset(0.25, 0.75));
    });

    test("each city's pin stands by its landmark on world_map_v4; its latitude and longitude kept", () {
      // Where the pins' tips go: beside Big Ben, the Eiffel Tower, the
      // Colosseum, by Korea and the castle (1983 × 793), where the earlier
      // map painted its markers' tips.
      for (final (city, x, y) in const [
        (WorldCities.london, 897.5, 209.5),
        (WorldCities.paris, 965.5, 279.5),
        (WorldCities.rome, 1038.5, 330.0),
        (WorldCities.seoul, 1633.0, 325.0),
        (WorldCities.tokyo, 1734.0, 350.5),
      ]) {
        final at = Offset(city.at.dx * 1983, city.at.dy * 793);
        expect((at - Offset(x, y)).distance, lessThan(1), reason: city.name);
      }
      expect((WorldCities.london.latitude, WorldCities.london.longitude), (51.51, -0.13));
      expect((WorldCities.tokyo.latitude, WorldCities.tokyo.longitude), (35.68, 139.69));
      for (final c in WorldCities.all) {
        expect(c.at.dx, inInclusiveRange(0, 1), reason: c.name);
        expect(c.at.dy, inInclusiveRange(0, 1), reason: c.name);
      }
      // Paris east of London, Tokyo east of Seoul.
      expect(WorldCities.paris.at.dx, greaterThan(WorldCities.london.at.dx));
      expect(WorldCities.tokyo.at.dx, greaterThan(WorldCities.seoul.at.dx));
    });

    test("names stay clear of each other's marks and names; only the chosen city's always shows", () {
      Rect dot(Offset p) => Rect.fromCircle(center: p, radius: 7);
      // London, Paris and Rome close together, London chosen.
      const points = [Offset(180, 200), Offset(200, 222), Offset(250, 260)];
      final marks = [Rect.fromLTRB(166, 172, 194, 202), dot(points[1]), dot(points[2])];
      const sizes = [Size(64, 22), Size(40, 15), Size(40, 15)];
      final out = placeLabels(points: points, marks: marks, sizes: sizes, order: const [0, 1, 2], viewport: const Size(390, 600), selected: 0);
      expect(out.every((r) => r != null), isTrue, reason: 'room for all three');
      for (var a = 0; a < 3; a++) {
        for (var b = 0; b < 3; b++) {
          if (a != b) expect(out[a]!.overlaps(marks[b]), isFalse, reason: 'name $a clear of mark $b');
          if (a < b) expect(out[a]!.overlaps(out[b]!), isFalse, reason: 'names $a and $b');
        }
      }
      // No room: another city's name hides, the chosen one's never.
      final crowded = placeLabels(
        points: const [Offset(20, 20), Offset(22, 22)],
        marks: [dot(const Offset(20, 20)), dot(const Offset(22, 22))],
        sizes: const [Size(300, 30), Size(300, 30)],
        order: const [1, 0],
        viewport: const Size(60, 60),
        selected: 1,
      );
      expect(crowded[1], isNotNull);
      expect(crowded[0], isNull);
  });
  });

  group('where the map opens', () {
    testWidgets('a new detective: London, ready to begin; Paris locked; the rest coming soon', (t) async {
      await pumpApp(t, seasonSaves(0));
      await openMap(t);
      expect(appRef.read(homeCityIdProvider), WorldCities.london.id);
      expect(find.text('WORLD MYSTERY'), findsOneWidget);
      expect(find.text('Detective MINYOUNG'), findsOneWidget);
      expect(inCard('london', 'SEASON 1 · LONDON'), findsOneWidget);
      expect(inCard('london', 'Shadows over London'), findsOneWidget);
      expect(inCard('london', '12 cases · Not started'), findsOneWidget);
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
      expect(find.descendant(of: find.byKey(const ValueKey('city-label-paris')), matching: find.text('Paris')), findsOneWidget);
    });

    testWidgets('London under way: London, to continue', (t) async {
      await pumpApp(t, seasonSaves(3, activeBegun: true));
      await openMap(t);
      expect(appRef.read(homeCityIdProvider), WorldCities.london.id);
      expect(inCard('london', 'CONTINUE'), findsOneWidget);
      expect(inCard('london', 'In progress · 3 of 12 solved'), findsOneWidget);
    });

    testWidgets('London solved, Paris not begun: Paris — and looking does not choose it', (t) async {
      await pumpApp(t, seasonSaves(12));
      final before = saves();
      await openMap(t);
      expect(appRef.read(homeCityIdProvider), WorldCities.paris.id);
      expect(inCard('paris', 'SEASON 2 · PARIS'), findsOneWidget);
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
      expect(inCard('paris', 'In progress · 2 of 12 solved'), findsOneWidget);
    });

    testWidgets('Paris solved, no next season out: Paris', (t) async {
      await pumpApp(t, seasonSaves(12));
      await beginParis(t);
      solveParis(12);
      await openMap(t);
      expect(appRef.read(homeCityIdProvider), WorldCities.paris.id);
      expect(inCard('paris', 'REVISIT'), findsOneWidget);
      expect(inCard('paris', 'Completed · 12 of 12 solved'), findsOneWidget);
    });
  });

  // The opening view: close on the home city, which stands at 45% of the
  // map left in view (between the header and the card), across the middle.
  group('the camera', () {
    void expectFramed(WidgetTester t, String cityId) {
      final area = inView(t);
      // The place: the pin's tip, under the middle of its head (the middle
      // of its touch) by 50 × 76 / 120.
      final at = t.getCenter(pin(cityId)) + const Offset(0, 50 * 76 / 120);
      expect(at.dx, closeTo(area.center.dx, 1), reason: '$cityId across the middle');
      expect(at.dy, closeTo(area.top + area.height * WorldMapView.focusHeight, 1), reason: '$cityId at 45% of the view');
    }

    for (final size in const [Size(390, 844), Size(360, 640)]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}';

      testWidgets('$tag: London opens close, chosen across the middle, Paris and Rome whole beside it', (t) async {
        await pumpApp(t, seasonSaves(0), size: size);
        await openMap(t);
        final s = view(t).getMaxScaleOnAxis();
        expect(s, inInclusiveRange(1.0, 2.6), reason: 'about ${WorldMapView.openingSpan}° across');
        final area = inView(t);
        final london = t.getCenter(pin('london'));
        // Across the middle, or slid a little west when Rome would be under
        // the map's buttons.
        expect(london.dx, inInclusiveRange(area.width * 0.4, area.center.dx + 1), reason: 'london across the middle');
        // At 45% of the view, or a little above it when Rome needs the
        // room (the world's north edge then holds London up).
        expect(london.dy, inInclusiveRange(area.top + area.height * 0.3, area.top + area.height * WorldMapView.focusHeight + 1));
        expect(find.byKey(const ValueKey('mark-london-home')), findsOneWidget);
        for (final id in ['london', 'paris', 'rome']) {
          // The whole touch square and the name, inside the part in view.
          expect(area.contains(t.getRect(pin(id)).topLeft) && area.contains(t.getRect(pin(id)).bottomRight), isTrue, reason: '$id touch in view');
          final label = find.byKey(ValueKey('city-label-$id'));
          expect(label, findsOneWidget, reason: '$id named');
          expect(area.contains(t.getRect(label).topLeft) && area.contains(t.getRect(label).bottomRight), isTrue, reason: '$id name in view');
          final buttons = t.getRect(find.byKey(const ValueKey('world-map-home'))).expandToInclude(t.getRect(find.byKey(const ValueKey('world-map-zoom-out'))));
          expect(t.getRect(pin(id)).overlaps(buttons), isFalse, reason: '$id touch clear of the buttons');
          expect(t.getRect(label).overlaps(buttons), isFalse, reason: '$id name clear of the buttons');
        }
      });

      testWidgets('$tag: Paris (London solved) opens on Paris the same way', (t) async {
        await pumpApp(t, seasonSaves(12), size: size);
        await openMap(t);
        expectFramed(t, 'paris');
        expect(card('paris'), findsOneWidget);
      });
    }

    testWidgets('London, Paris and Rome can each be chosen, close as they are', (t) async {
      await pumpApp(t, seasonSaves(3, activeBegun: true));
      await openMap(t);
      final before = saves();
      for (final id in ['paris', 'london', 'rome', 'paris', 'london']) {
        await t.tap(pin(id));
        await wait(t, const Duration(milliseconds: 600));
        expect(card(id), findsOneWidget, reason: id);
      }
      expect(saves(), before, reason: 'choosing saves nothing');
    });

    testWidgets('the season under way has the floating drop; every city not under way or done, a lock', (t) async {
      await pumpApp(t, seasonSaves(3, activeBegun: true), size: const Size(390, 844));
      await openMap(t);
      final before = saves();
      expect(find.byKey(const ValueKey('mark-london-home')), findsOneWidget);
      expect(find.byKey(const ValueKey('mark-paris-locked')), findsOneWidget, reason: 'Paris: London not complete');
      expect(find.byKey(const ValueKey('mark-rome-locked')), findsOneWidget, reason: 'Rome: coming soon, locked too');
      // Every name on a tag, chosen or not.
      for (final id in ['london', 'paris', 'rome']) {
        final label = find.byKey(ValueKey('city-label-$id'));
        expect(find.descendant(of: label, matching: find.byType(DecoratedBox)), findsOneWidget, reason: id);
      }
      // Each pin's tip on its city's place, its head in the middle of its touch.
      final viewer = find.byKey(const ValueKey('world-map-viewer'));
      final box = t.getRect(viewer);
      final h = math.max(box.height, box.width / ArtAssets.worldMapAspect);
      for (final c in [WorldCities.london, WorldCities.paris, WorldCities.rome]) {
        final place = MatrixUtils.transformPoint(view(t), Offset(c.at.dx * h * ArtAssets.worldMapAspect, c.at.dy * h)) + box.topLeft;
        final art = t.getRect(find.descendant(of: pin(c.id), matching: find.byKey(const ValueKey('pin-art'))));
        expect((art.bottomCenter - place).distance, lessThan(4.5), reason: '${c.name}: the tip on the place (home floats up to 4)');
        expect((Offset(art.center.dx, art.top + art.height * 44 / 120) - t.getCenter(pin(c.id))).dx.abs(), lessThan(0.5));
      }

      // The drop floats: up to 4 above its place and back.
      final float = find.descendant(of: find.byKey(const ValueKey('mark-london-home')), matching: find.byType(Transform));
      final heights = <double>[];
      for (var k = 0; k < 8; k++) {
        await t.pump(const Duration(milliseconds: 200));
        heights.add(t.widget<Transform>(float).transform.getTranslation().y);
      }
      expect(heights.reduce(math.min), lessThan(-2), reason: 'floats up');
      expect(heights.reduce(math.max), greaterThan(-2), reason: 'and down');
      expect(heights.every((h) => h >= -4.001 && h <= 0.001), isTrue);

      // A locked city chosen: its lock in a gold ring; the drop stays home.
      await t.tap(pin('paris'));
      await wait(t, const Duration(milliseconds: 600));
      expect(card('paris'), findsOneWidget);
      expect(find.byKey(const ValueKey('mark-paris-lockedChosen')), findsOneWidget);
      expect(find.byKey(const ValueKey('mark-london-home')), findsOneWidget);
      expect(find.byKey(const ValueKey('city-card-enter')), findsNothing, reason: 'a locked season cannot be entered');
      await tapCity(t, 'tokyo');
      expect(find.byKey(const ValueKey('mark-tokyo-lockedChosen')), findsOneWidget);
      await bringIntoView(t, 'paris');
      expect(find.byKey(const ValueKey('mark-paris-locked')), findsOneWidget, reason: 'not chosen: the plain lock again');
      expect(saves(), before, reason: 'choosing saves nothing');
    });

    testWidgets('Paris under way: the drop on Paris; London complete, a dot, chosen in a ring', (t) async {
      await pumpApp(t, seasonSaves(12));
      await openMap(t);
      expect(card('paris'), findsOneWidget);
      expect(find.byKey(const ValueKey('mark-paris-home')), findsOneWidget);
      expect(find.byKey(const ValueKey('city-card-enter')), findsOneWidget);
      await bringIntoView(t, 'london');
      expect(find.byKey(const ValueKey('mark-london-open')), findsOneWidget);
      await tapCity(t, 'london');
      expect(card('london'), findsOneWidget);
      expect(find.byKey(const ValueKey('mark-london-openChosen')), findsOneWidget);
      expect(find.byKey(const ValueKey('city-card-enter')), findsOneWidget, reason: 'a completed season opens again');
      expect(find.byKey(const ValueKey('mark-paris-home')), findsOneWidget);
    });

    testWidgets('back to my city: the opening view again, my city chosen', (t) async {
      await pumpApp(t, seasonSaves(3, activeBegun: true));
      await openMap(t);
      final opening = view(t).clone();
      final home = t.getCenter(pin('london'));
      await tapCity(t, 'tokyo');
      expect(card('tokyo'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('world-map-home')));
      await wait(t, const Duration(milliseconds: 800));
      expect(card('london'), findsOneWidget);
      expect(view(t).getMaxScaleOnAxis(), closeTo(opening.getMaxScaleOnAxis(), 0.001));
      expect((t.getCenter(pin('london')) - home).distance, lessThan(1), reason: 'where it opened');
    });
  });

  group('choosing on the map', () {
    testWidgets('a pin shows its city on the card; only the card button plays a season', (t) async {
      await pumpApp(t, seasonSaves(0));
      await openMap(t);
      final before = saves();

      await tapCity(t, 'paris');
      expect(inCard('paris', 'SEASON 2 · PARIS'), findsOneWidget);
      expect(inCard('paris', 'Paris Stands Still'), findsOneWidget);
      expect(inCard('paris', 'Complete London to unlock.'), findsOneWidget);
      // Locked: why, and no button that cannot be pressed.
      expect(find.byKey(const ValueKey('city-card-enter')), findsNothing);
      expect(path(), Routes.worldMap);

      // Tokyo is east: the map is dragged there.
      await tapCity(t, 'tokyo');
      expect(inCard('tokyo', 'TOKYO'), findsOneWidget);
      expect(inCard('tokyo', 'Coming Soon'), findsOneWidget);
      expect(inCard('tokyo', 'A new mystery is on its way.'), findsOneWidget);
      expect(find.byKey(const ValueKey('city-card-enter')), findsNothing);

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
      final start = view(t).getMaxScaleOnAxis();
      final box = t.getRect(find.byKey(const ValueKey('world-map-viewer')));
      final world = math.max(box.height, box.width / ArtAssets.worldMapAspect) * ArtAssets.worldMapAspect * start;
      expect(box.width / world, lessThan(1 / 3), reason: 'opens close on the city: under a third of the world across');

      await t.tap(find.byKey(const ValueKey('world-map-zoom-in')));
      await wait(t, const Duration(milliseconds: 600));
      expect(view(t).getMaxScaleOnAxis(), closeTo(start * WorldMapView.zoomStep, 0.01));
      final pinSize = t.getRect(pin('london')).size;

      await t.tap(find.byKey(const ValueKey('world-map-zoom-in')));
      await wait(t, const Duration(milliseconds: 600));
      // Pins keep their size on screen.
      final zoomed = t.getRect(pin('london')).size;
      expect(zoomed.width, closeTo(pinSize.width, 0.5));
      expect(zoomed.height, closeTo(pinSize.height, 0.5));

      await t.tap(find.byKey(const ValueKey('world-map-zoom-out')));
      await wait(t, const Duration(milliseconds: 600));
      expect(view(t).getMaxScaleOnAxis(), closeTo(start * WorldMapView.zoomStep, 0.01));

      // Two fingers apart: closer in.
      final before = view(t).getMaxScaleOnAxis();
      final mid = inView(t).center;
      final a = await t.startGesture(mid - const Offset(30, 0));
      final b = await t.startGesture(mid + const Offset(30, 0), pointer: 7);
      for (var k = 1; k <= 5; k++) {
        await a.moveTo(mid - Offset(30.0 + 12 * k, 0));
        await b.moveTo(mid + Offset(30.0 + 12 * k, 0));
        await t.pump(const Duration(milliseconds: 16));
      }
      await a.up();
      await b.up();
      await wait(t, const Duration(milliseconds: 600));
      expect(view(t).getMaxScaleOnAxis(), greaterThan(before * 1.3), reason: 'pinched');

      final moved = view(t).getTranslation();
      await t.drag(find.byKey(const ValueKey('world-map-viewer')), const Offset(-120, 0));
      await wait(t, const Duration(milliseconds: 400));
      expect(view(t).getTranslation().x, lessThan(moved.x));

      // Zoomed out as far as it goes: the world still covers the viewport.
      for (var i = 0; i < 6; i++) {
        await t.tap(find.byKey(const ValueKey('world-map-zoom-out')));
        await wait(t, const Duration(milliseconds: 600));
      }
      expect(view(t).getMaxScaleOnAxis(), 1);
      expect(view(t).getTranslation().x, lessThanOrEqualTo(WorldMapView.edge));
      // The whole world's height: its top no lower than the header.
      expect(view(t).getTranslation().y, lessThanOrEqualTo(inView(t).top + 0.01));
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
        expect(card(id), findsOneWidget);
        expect(find.byKey(const ValueKey('city-card-enter')), findsNothing, reason: '$id: nothing to enter');
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

  test('the world map artwork is world_map_v4 (1983 × 793) with its pins, listed in the app', () {
    final file = File(ArtAssets.worldMap);
    expect(file.existsSync(), isTrue);
    expect(ArtAssets.worldMap, endsWith('world_map_v4.png'));
    // The PNG header: width and height, big-endian, at bytes 16..23.
    final head = ByteData.sublistView(file.readAsBytesSync().sublist(16, 24));
    expect((head.getUint32(0), head.getUint32(4)), (1983, 793));
    expect(head.getUint32(0) / head.getUint32(4), ArtAssets.worldMapAspect);
    for (final (pin, w, h) in const [
      (ArtAssets.worldMapPinInProgress, 96, 120),
      (ArtAssets.worldMapPinCompleted, 96, 120),
      (ArtAssets.worldMapPinLocked, 96, 120),
      (ArtAssets.worldMapPinRing, 144, 144),
    ]) {
      final head = ByteData.sublistView(File(pin).readAsBytesSync().sublist(16, 24));
      expect((head.getUint32(0), head.getUint32(4)), (w, h), reason: pin);
    }
    expect(File('pubspec.yaml').readAsStringSync(), contains('- assets/shared/world_map/'));
  });
}
