import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/mission_map/map_camera.dart';
import 'package:london_mystery/features/mission_map/map_world.dart';
import 'package:london_mystery/features/mission_map/widgets/london_map_painter.dart';
import 'package:london_mystery/features/mission_map/widgets/map_pin.dart';
import 'package:london_mystery/widgets/game_button.dart';

import 'full_playthrough_test.dart' show wait;
import 'helpers.dart';

void main() {
  group('camera math', () {
    // A 300 × 360 viewport over a 600 × 400 world.
    const camera = MapCamera(viewport: Size(300, 360), world: Size(600, 400), focusDrop: 0);

    test('a place in the middle of the world comes to the viewport centre', () {
      final offset = camera.offsetFor(const Offset(0.5, 0.5));
      expect(camera.onScreen(const Offset(0.5, 0.5), offset), const Offset(150, 180));
    });

    test('near the top or bottom the camera stops at the world edge', () {
      expect(camera.offsetFor(const Offset(0.5, 0.02)).dy, 0, reason: 'top edge');
      expect(camera.offsetFor(const Offset(0.5, 0.98)).dy, 360 - 400, reason: 'bottom edge');
    });

    test('near the left or right the camera stops at the world edge', () {
      expect(camera.offsetFor(const Offset(0.02, 0.5)).dx, 0, reason: 'left edge');
      expect(camera.offsetFor(const Offset(0.98, 0.5)).dx, 300 - 600, reason: 'right edge');
    });

    test('the world always covers the viewport', () {
      for (final p in const [Offset.zero, Offset(1, 1), Offset(0.3, 0.9), Offset(0.9, 0.1)]) {
        final o = camera.offsetFor(p);
        expect(o.dx, inInclusiveRange(300 - 600, 0));
        expect(o.dy, inInclusiveRange(360 - 400, 0));
      }
    });

    test('a world smaller than the viewport is centred, not clamped off', () {
      const small = MapCamera(viewport: Size(300, 360), world: Size(240, 160), focusDrop: 0);
      expect(small.offsetFor(const Offset(0.1, 0.9)), const Offset(30, 100));
    });

    test('the cover world keeps the artwork ratio and is larger than the viewport', () {
      for (final viewport in const [Size(320, 384), Size(350, 420), Size(600, 200)]) {
        final c = MapCamera.cover(viewport, aspect: 3 / 2);
        expect(c.world.width / c.world.height, closeTo(3 / 2, 1e-9));
        expect(c.world.width, greaterThanOrEqualTo(viewport.width));
        expect(c.world.height, greaterThanOrEqualTo(viewport.height));
      }
    });

    test('the focused place sits a little below the centre, for its note', () {
      const dropped = MapCamera(viewport: Size(300, 360), world: Size(600, 400));
      final offset = dropped.offsetFor(const Offset(0.5, 0.5));
      expect(dropped.onScreen(const Offset(0.5, 0.5), offset).dy, 180 + MapCamera.defaultFocusDrop);
    });
  });

  group('map world', () {
    test('every mission of the season stands on a landmark of the map', () {
      for (final e in MockEpisodeRepository.bundled()) {
        final places = MapWorld.places(e);
        for (final m in e.allMissions) {
          expect(MapWorld.missionLandmarks[m.id], isNotNull, reason: m.id);
          final p = places[m.id]!;
          expect(p.dx, inInclusiveRange(0, 1), reason: m.id);
          expect(p.dy, inInclusiveRange(0, 1), reason: m.id);
          // In a group around it (moved down a little when near the top).
          expect((p - MapWorld.missionLandmarks[m.id]!.at).distance, lessThan(2 * MapWorld.groupRadius), reason: '${m.id} near its landmark');
          expect(p.dy, greaterThanOrEqualTo(MapWorld.topMargin - 1e-9), reason: '${m.id} leaves room for its note');
        }
      }
    });

    test('places that share a landmark do not sit on top of each other', () {
      for (final e in MockEpisodeRepository.bundled()) {
        final places = MapWorld.places(e).values.toList();
        for (var i = 0; i < places.length; i++) {
          for (var j = i + 1; j < places.length; j++) {
            // In a 600 × 400 world, pins at least ~30 px apart.
            final d = Offset((places[i].dx - places[j].dx) * 600, (places[i].dy - places[j].dy) * 400).distance;
            expect(d, greaterThan(30), reason: '${e.id} places $i and $j');
          }
        }
      }
    });

    test('a case spread over London puts each place on its own landmark', () {
      final places = MapWorld.places(episode01);
      expect(places['m01'], Landmark.kingsCross.at);
      expect(places['m02'], Landmark.britishMuseum.at);
      expect(places['m03'], Landmark.bigBen.at);
      expect(places['m04'], Landmark.hydePark.at);
    });
  });

  group('camera on the mission map', () {
    late WidgetRef appRef;

    Future<void> openMap(WidgetTester t, {String? justUnlocked}) async {
      t.view.physicalSize = const Size(1080, 1920);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(ProviderScope(
        overrides: await testOverrides(),
        child: Consumer(builder: (context, ref, _) {
          appRef = ref;
          return const LondonMysteryApp();
        }),
      ));
      await wait(t, const Duration(milliseconds: 300));
      final game = appRef.read(gameControllerProvider.notifier);
      game.registerDetective('Kim');
      game.startInvestigation();
      if (justUnlocked != null) {
        // As when a case is solved: m01 done, m02 just unlocked.
        game.submitAnswer(episode01.missionById('m01')!, 'b');
        expect(appRef.read(recentUnlockProvider), justUnlocked);
      }
      appRef.read(routerProvider).go(Routes.map);
      await t.pump();
      await t.pump(const Duration(milliseconds: 16));
    }

    final goTo = find.ancestor(of: find.textContaining('GO TO'), matching: find.byType(GameButton));
    /// How much of the red dashed way to the current place is drawn.
    double redWay(WidgetTester t) =>
        t.widgetList<CustomPaint>(find.byType(CustomPaint)).map((w) => w.painter).whereType<LondonMapPainter>().single.heading!.value;
    Offset worldAt(WidgetTester t) => t.getRect(find.byKey(const ValueKey('map-world'))).topLeft;
    Rect inner(WidgetTester t) => t.getRect(find.byKey(const ValueKey('map-viewport'))).deflate(5);
    Offset cameraOn(WidgetTester t, String id) =>
        inner(t).topLeft + MapCamera.cover(inner(t).size, aspect: 3 / 2).offsetFor(MapWorld.places(episode01)[id]!);

    testWidgets('the map opens already on the current place (no long pan)', (t) async {
      await openMap(t);
      expect(worldAt(t), offsetMoreOrLessEquals(cameraOn(t, 'm01'), epsilon: 0.5));
      await t.pump(const Duration(milliseconds: 500));
      expect(worldAt(t), offsetMoreOrLessEquals(cameraOn(t, 'm01'), epsilon: 0.5), reason: 'same place: no animation');
      expect(redWay(t), 1, reason: 'not travelling: the way is drawn (nothing solved yet, so nothing shows)');
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('back from a solved place, the world pans to the place it unlocked', (t) async {
      await openMap(t, justUnlocked: 'm02');
      final start = worldAt(t);
      expect(start, offsetMoreOrLessEquals(cameraOn(t, 'm01'), epsilon: 0.5), reason: 'starts on the solved place');

      // Pins, names and the YOU'RE HERE note ride with the world.
      Offset relative(Finder f) => t.getRect(f).topLeft - worldAt(t);
      final pin = relative(find.byKey(const ValueKey('pin-m02')));
      final solved = relative(find.byKey(const ValueKey('pin-m01')));
      final name = relative(find.text('Tower of London'));

      await t.pump(const Duration(milliseconds: 500));
      final middle = worldAt(t);
      expect(redWay(t), inExclusiveRange(0, 1), reason: 'the red dashed way is being drawn with the camera');
      expect(middle, isNot(start), reason: 'the camera is moving');
      expect(middle, isNot(offsetMoreOrLessEquals(cameraOn(t, 'm02'), epsilon: 0.5)), reason: 'not a jump');
      expect(relative(find.byKey(const ValueKey('pin-m02'))), offsetMoreOrLessEquals(pin));
      expect(relative(find.byKey(const ValueKey('pin-m01'))), offsetMoreOrLessEquals(solved));
      expect(relative(find.text('Tower of London')), offsetMoreOrLessEquals(name));

      // The page has finished opening; the camera is still moving.
      final buttons = [t.getRect(goTo), t.getRect(find.byTooltip('Detective notebook'))];
      await t.pump(const Duration(milliseconds: 600));
      expect(worldAt(t), offsetMoreOrLessEquals(cameraOn(t, 'm02'), epsilon: 0.5), reason: 'lands on the new place');
      expect(redWay(t), 1, reason: 'the red dashed way reaches the new place');
      expect([t.getRect(goTo), t.getRect(find.byTooltip('Detective notebook'))], buttons, reason: 'the buttons stay put');
      await wait(t, const Duration(seconds: 3)); // the pin's unlock stamp
      expect(find.text("YOU'RE HERE"), findsOneWidget);
      final here = t.getRect(find.text("YOU'RE HERE"));
      expect(inner(t).contains(here.center), isTrue, reason: 'the note is in view, with its pin');
      expect(here.center.dx - (worldAt(t).dx + relative(find.byKey(const ValueKey('pin-m02'))).dx + MapPin.width / 2), closeTo(0, 1));
    });

    testWidgets('solving a place while the map is open pans the camera there', (t) async {
      await openMap(t);
      expect(worldAt(t), offsetMoreOrLessEquals(cameraOn(t, 'm01'), epsilon: 0.5));
      appRef.read(gameControllerProvider.notifier).submitAnswer(episode01.missionById('m01')!, 'b');
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));
      expect(worldAt(t), isNot(offsetMoreOrLessEquals(cameraOn(t, 'm02'), epsilon: 0.5)), reason: 'on the way');
      await t.pump(const Duration(milliseconds: 600));
      expect(worldAt(t), offsetMoreOrLessEquals(cameraOn(t, 'm02'), epsilon: 0.5));
      await wait(t, const Duration(seconds: 3));
    });
  });
}
