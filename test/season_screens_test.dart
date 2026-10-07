import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/models/episode.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/mission_map/map_camera.dart';
import 'package:london_mystery/features/mission_map/map_world.dart';
import 'package:london_mystery/features/mission_map/widgets/map_pin.dart';
import 'package:london_mystery/widgets/game_button.dart';
import 'package:london_mystery/widgets/landmark_art.dart';

import 'full_playthrough_test.dart' show wait;
import 'helpers.dart';

/// Opens every screen of every case at a small phone size and fails on any
/// layout error (overflow, clipping exceptions). Set LM_SCREENSHOTS to a
/// folder to also save a picture of each screen for visual review.
void main() {
  final season = MockEpisodeRepository.bundled();
  final shots = Platform.environment['LM_SCREENSHOTS'];

  setUpAll(() async {
    // Real fonts, so text sizes (and any overflow) match the device.
    for (final (family, files) in [
      ('Sentient', ['Sentient-Variable.ttf']),
      ('IMFellEnglishSC', ['IMFellEnglishSC-Regular.ttf']),
      ('LibreBaskerville', ['LibreBaskerville.ttf', 'LibreBaskerville-Italic.ttf']),
    ]) {
      final loader = FontLoader(family);
      for (final f in files) {
        loader.addFont(rootBundle.load('assets/fonts/$f'));
      }
      await loader.load();
    }
  });

  /// Everything before [e] solved; in [e], the missions before [upTo] solved.
  Map<String, Object> saves(Episode e, int upTo, {required bool puzzle}) {
    final done = [for (final m in e.allMissions.take(upTo)) m.id];
    final current = upTo < e.allMissions.length ? e.allMissions[upTo] : null;
    final progress = GameProgress(
      detectiveName: 'MINYOUNG',
      introSeen: true,
      completedMissionIds: done,
      missionStartedAt: {if (puzzle && current != null) current.id: DateTime(2026, 9, 29, 10)},
      startedAt: DateTime(2026, 9, 29, 10),
      playMillis: 0,
    );
    final solved = [for (final s in season.takeWhile((s) => s.id != e.id)) s.id];
    return {
      AppConstants.progressKeyFor(e.id): jsonEncode(progress.toJson()),
      if (e.id != AppConstants.currentEpisodeId)
        AppConstants.progressStorageKey: jsonEncode(const GameProgress(detectiveName: 'MINYOUNG').toJson()),
      AppConstants.seasonStorageKey: jsonEncode(SeasonProgress(activeEpisodeId: e.id, solvedEpisodeIds: solved).toJson()),
    };
  }

  Future<void> capture(WidgetTester t, String name) async {
    if (shots == null) return;
    await t.runAsync(() async {
      final boundary = t.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('shot')));
      final image = await boundary.toImage(pixelRatio: 1.5);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$shots/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  Future<void> openScreen(WidgetTester t, Map<String, Object> prefs, String path, {Size size = const Size(360, 640)}) async {
    t.view.physicalSize = size * 3; // 360 × 640 by default: a small phone
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    late WidgetRef appRef;
    await t.pumpWidget(ProviderScope(
      overrides: await testOverrides(prefs: prefs),
      child: RepaintBoundary(
        key: const ValueKey('shot'),
        child: Consumer(builder: (context, ref, _) {
          appRef = ref;
          return const LondonMysteryApp();
        }),
      ),
    ));
    await wait(t, const Duration(milliseconds: 300));
    appRef.read(routerProvider).go(path);
    await wait(t, const Duration(milliseconds: 1200));
    expect(appRef.read(routerProvider).routerDelegate.currentConfiguration.uri.path, path, reason: 'not redirected');
  }

  for (final e in season) {
    // The notebook of a solved case: every evidence tile, at a small size.
    testWidgets('${e.id} notebook evidence page lays out without errors', (t) async {
      await openScreen(t, saves(e, e.allMissions.length, puzzle: false), Routes.notebook);
      await t.tap(find.text('EVIDENCE'));
      await wait(t, const Duration(milliseconds: 800));
      await capture(t, '${e.id}_notebook_evidence');
      await t.drag(find.byType(Scrollable).last, const Offset(0, -2000));
      await wait(t, const Duration(milliseconds: 400));
      expect(t.takeException(), isNull);
      await wait(t, const Duration(seconds: 3));
    });
  }

  // The mission map camera: a tall viewport over the 3:2 London world, the
  // current place at its centre, every pin on its place in the world, locked
  // places off the map, the buttons fixed below — at a small and a tall phone.
  for (final size in const [Size(360, 640), Size(390, 844)]) {
    for (final e in season) {
      final n = e.allMissions.length;
      final places = MapWorld.places(e);
      for (final upTo in {0, n ~/ 2, n}) {
        final tag = '${size.width.toInt()}x${size.height.toInt()}';
        testWidgets('${e.id} map ($upTo/$n solved) at $tag lays out without errors', (t) async {
          await openScreen(t, saves(e, upTo, puzzle: false), Routes.map, size: size);
          await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300))); // decode the artwork
          await t.pump();

          // A page-sized, tall viewport (not a strip, not the whole screen).
          final viewport = t.getRect(find.byKey(const ValueKey('map-viewport')));
          expect(viewport.height / viewport.width, inInclusiveRange(1.0, 1.25), reason: 'a tall viewport');
          expect(viewport.height, greaterThan(size.height * 0.45), reason: 'the map is the main picture');
          expect(viewport.left, greaterThanOrEqualTo(0));
          expect(viewport.right, lessThanOrEqualTo(size.width));
          final inner = viewport.deflate(5);

          // The world: the artwork at 3:2, larger than the viewport, never
          // leaving an empty edge.
          final world = t.getRect(find.byKey(const ValueKey('map-world')));
          expect(world.width / world.height, closeTo(3 / 2, 0.01));
          expect(world.width, greaterThan(inner.width * 1.5), reason: 'one part of London, not the whole map');
          expect(world.left, lessThanOrEqualTo(inner.left + 0.5));
          expect(world.top, lessThanOrEqualTo(inner.top + 0.5));
          expect(world.right, greaterThanOrEqualTo(inner.right - 0.5));
          expect(world.bottom, greaterThanOrEqualTo(inner.bottom - 0.5));
          expect(t.getRect(find.byType(Image)), world, reason: 'the artwork is the world, unstretched');

          // The camera is on the current place (or the last one when done).
          final focus = places[(upTo < n ? e.allMissions[upTo] : e.allMissions.last).id]!;
          final camera = MapCamera.cover(inner.size, aspect: 3 / 2);
          expect(world.topLeft - inner.topLeft, offsetMoreOrLessEquals(camera.offsetFor(focus), epsilon: 0.5));

          for (final (i, m) in e.allMissions.indexed) {
            final pin = find.byKey(ValueKey('pin-${m.id}'));
            if (i > upTo) {
              expect(pin, findsNothing, reason: '${m.id} is locked: off the map');
              continue;
            }
            final r = t.getRect(pin);
            final tip = Offset(r.center.dx, r.top + MapPin.anchorY);
            final place = world.topLeft + Offset(places[m.id]!.dx * world.width, places[m.id]!.dy * world.height);
            if (i == upTo) {
              expect((tip - place).distance, lessThan(0.5), reason: '${m.id}: the current pin is on its place');
            } else {
              // A solved mark is on its place, or has stepped just aside.
              expect((tip - place).distance, lessThan(70), reason: '${m.id}: solved mark by its place');
            }
          }
          if (upTo < n) {
            final here = t.getRect(find.text("YOU'RE HERE"));
            expect(inner.contains(here.topLeft) && inner.contains(here.bottomRight), isTrue, reason: 'the current place is in view');
            expect((here.center.dx - inner.center.dx).abs(), lessThan(inner.width / 2), reason: 'near the centre');
            // No solved mark on the current pin's note, pin or name (drawn bounds).
            final current = e.allMissions[upTo];
            final pinRect = t.getRect(find.byKey(ValueKey('pin-${current.id}')));
            final tip = Offset(pinRect.center.dx, pinRect.top + MapPin.anchorY);
            final taken = [here, t.getRect(find.descendant(of: find.byKey(ValueKey('pin-${current.id}')), matching: find.text(current.location))), Rect.fromLTRB(tip.dx - 13, tip.dy - 34, tip.dx + 13, tip.dy)];
            for (final m in e.allMissions.take(upTo)) {
              final r = t.getRect(find.byKey(ValueKey('pin-${m.id}')));
              final mark = Rect.fromCircle(center: Offset(r.center.dx, r.top + MapPin.anchorY), radius: 16);
              for (final k in taken) {
                expect(mark.overlaps(k), isFalse, reason: '${m.id} solved mark clear of $k');
              }
              expect(world.contains(mark.topLeft) && world.contains(mark.bottomRight), isTrue, reason: '${m.id} inside the map');
            }
          }
          for (final button in [find.byTooltip('Detective notebook'), find.byType(GameButton)]) {
            final r = t.getRect(button);
            expect(r.bottom, lessThanOrEqualTo(size.height), reason: 'buttons stay on screen');
            expect(r.top, greaterThan(viewport.bottom), reason: 'buttons sit below the map');
          }
          await capture(t, '${e.id}_map_${upTo}_$tag');
          expect(t.takeException(), isNull);
          await wait(t, const Duration(seconds: 3));
        });
      }
    }
  }

  testWidgets('the case archive with every case file opened lays out without errors', (t) async {
    final last = season.last;
    await openScreen(t, saves(last, 0, puzzle: false), Routes.notebook);
    await t.tap(find.text('CASE ARCHIVE'));
    await wait(t, const Duration(milliseconds: 600));
    for (final e in season.take(season.length - 1)) {
      final folder = find.text(e.title.toUpperCase());
      await t.drag(find.byType(ListView).last, const Offset(0, 20000)); // back to the top
      await t.pump();
      await t.scrollUntilVisible(folder, 200, scrollable: find.descendant(of: find.byType(ListView).last, matching: find.byType(Scrollable)).first);
      await t.tap(folder);
      await wait(t, const Duration(milliseconds: 500));
      await capture(t, 'archive_${e.id}');
      await t.drag(find.byType(ListView).last, const Offset(0, -900));
      await wait(t, const Duration(milliseconds: 300));
      expect(t.takeException(), isNull, reason: e.id);
    }
    await wait(t, const Duration(seconds: 3));
  });

  for (final e in season) {
    for (final (i, m) in e.allMissions.indexed) {
      final path = m.isFinal ? Routes.finalMission : Routes.mission(m.id);
      for (final puzzle in m.isFinal ? const [true] : const [false, true]) {
        final stage = m.isFinal ? 'final' : (puzzle ? 'puzzle' : 'story');
        testWidgets('${e.id} ${m.id} $stage screen lays out without errors', (t) async {
          await openScreen(t, saves(e, i, puzzle: puzzle), path);
          await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200))); // decode the pictures
          await t.pump();
          await capture(t, '${m.id}_$stage');
          // Image-choice answers are recognised, not read: no printed name.
          final answers = find.descendant(of: find.byType(GridView), matching: find.byType(LandmarkArt));
          for (final art in t.widgetList<LandmarkArt>(answers)) {
            expect(art.showName, isFalse, reason: '${m.id} ${art.artwork}');
          }
          // Scroll to the end so everything below the fold is laid out too.
          final list = find.byType(Scrollable);
          if (list.evaluate().isNotEmpty) {
            await t.drag(list.first, const Offset(0, -3000));
            await wait(t, const Duration(milliseconds: 600));
            await capture(t, '${m.id}_${stage}_end');
          }
          expect(t.takeException(), isNull);
          await wait(t, const Duration(seconds: 3)); // let timers finish
        });
      }
    }
  }
}
