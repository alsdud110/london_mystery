import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/features/mission/final_mission_screen.dart';
import 'package:london_mystery/widgets/art_assets.dart';
import 'package:london_mystery/widgets/desk_background.dart';
import 'package:london_mystery/widgets/game_button.dart';

import 'full_playthrough_test.dart' show wait;
import 'helpers.dart';
import 'title_screen_test.dart' show capture;

/// Case 01's final mission on the detective's desk: the Royal Box, the four
/// locks as before, OPEN THE BOX and SEE MY CASE REPORT as glass buttons.
void main() {
  setUpAll(() async {
    for (final (family, files) in [
      ('Nunito', ['Nunito.ttf']),
      ('Cinzel', ['Cinzel.ttf']),
      ('LibreBaskerville', ['LibreBaskerville.ttf', 'LibreBaskerville-Italic.ttf']),
    ]) {
      final loader = FontLoader(family);
      for (final f in files) {
        loader.addFont(rootBundle.load('assets/fonts/$f'));
      }
      await loader.load();
    }
  });

  for (final size in const [Size(360, 640), Size(390, 844)]) {
    final tag = '${size.width.toInt()}x${size.height.toInt()}';
    testWidgets('final mission $tag: desk, locks, OPEN THE BOX → open → SEE MY CASE REPORT, and a revisit', (t) async {
      t.view.physicalSize = size * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(ProviderScope(
        overrides: await testOverrides(prefs: {
          AppConstants.progressStorageKey: jsonEncode(GameProgress(
            detectiveName: 'MINYOUNG',
            introSeen: true,
            completedMissionIds: [for (final m in episode01.missions) m.id],
            startedAt: DateTime(2026, 9, 29, 10),
            playMillis: 0,
          ).toJson()),
        }),
        child: const RepaintBoundary(key: ValueKey('shot'), child: LondonMysteryApp()),
      ));
      await wait(t, const Duration(milliseconds: 300));
      final router = ProviderScope.containerOf(find.byType(LondonMysteryApp).evaluate().first).read(routerProvider);
      router.go(Routes.finalMission);
      await wait(t, const Duration(milliseconds: 1200));

      // A. The first view: on the desk, the box drawn in code (no picture yet).
      expect(t.takeException(), isNull);
      expect(find.byType(DeskBackground), findsOneWidget, reason: 'the desk, not the night sky');
      expect(find.byType(RoyalBoxAnimation), findsOneWidget);
      // The painted box, shut.
      bool showing(String file) => find
          .byWidgetPredicate((w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName == file)
          .evaluate()
          .isNotEmpty;
      expect(showing(ArtAssets.royalBox.closed), isTrue, reason: 'the shut box');
      expect(showing(ArtAssets.royalBox.open), isFalse);
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 600))); // decode the box
      await t.pump();
      await capture(t, 'final_initial_$tag');

      // B. The four locks, as before.
      final open = find.text('OPEN THE BOX');
      await t.scrollUntilVisible(open, 300, scrollable: find.byType(Scrollable).first);
      await wait(t, const Duration(milliseconds: 300));
      expect(t.widget<GameButton>(find.ancestor(of: open, matching: find.byType(GameButton))).style, GameButtonStyle.glass);
      await capture(t, 'final_locks_$tag');

      // C. The right code (7924, turned up from 0000), then OPEN THE BOX.
      Finder up(int i) => find.byTooltip('Lock ${i + 1} up');
      for (final (i, n) in const [(0, 7), (1, 9), (2, 2), (3, 4)]) {
        for (var k = 0; k < n; k++) {
          await t.tap(up(i));
          await t.pump(const Duration(milliseconds: 60));
        }
      }
      await wait(t, const Duration(milliseconds: 300));
      await capture(t, 'final_code_$tag');
      await t.tap(open);
      // D. Mid-opening: shut and open pictures crossfade in exactly the same place.
      // (the scroll up, 500 ms, then the shake; the lid swings at 0.2–0.5 of 2.4 s)
      await wait(t, const Duration(milliseconds: 1300));
      Finder pic(String file) => find.byWidgetPredicate(
          (w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName == file);
      expect(t.getRect(pic(ArtAssets.royalBox.closed)), t.getRect(pic(ArtAssets.royalBox.open)), reason: "no jump between the two");
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
      await t.pump();
      await capture(t, "final_opening_$tag");
      await wait(t, const Duration(milliseconds: 2300));

      // D–E. Open, solved, SEE MY CASE REPORT as the glass button.
      final report = find.text('SEE MY CASE REPORT');
      await t.scrollUntilVisible(report, 300, scrollable: find.byType(Scrollable).first);
      await wait(t, const Duration(milliseconds: 300));
      expect(t.widget<GameButton>(find.ancestor(of: report, matching: find.byType(GameButton))).style, GameButtonStyle.glass);
      expect(find.text('CASE SOLVED'), findsOneWidget);
      expect(showing(ArtAssets.royalBox.open), isTrue, reason: 'open, the Crown inside');
      expect(showing(ArtAssets.royalBox.closed), isFalse);
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 600)));
      await t.pump();
      await capture(t, 'final_opened_$tag');

      // F. A revisit opens on the solved page as before (box open at once).
      router.go(Routes.map);
      await wait(t, const Duration(milliseconds: 1500));
      router.go(Routes.finalMission);
      await wait(t, const Duration(milliseconds: 1200));
      expect(find.text('CASE SOLVED'), findsOneWidget, reason: 'still solved on a revisit');
      expect(showing(ArtAssets.royalBox.open), isTrue, reason: 'open from the start on a revisit');
      expect(showing(ArtAssets.royalBox.closed), isFalse);
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 600)));
      await t.pump();
      await capture(t, 'final_revisit_$tag');
      await t.scrollUntilVisible(report, 300, scrollable: find.byType(Scrollable).first);
      await wait(t, const Duration(milliseconds: 300));
      await t.tap(report);
      await wait(t, const Duration(milliseconds: 1500));
      expect(router.routerDelegate.currentConfiguration.uri.path, Routes.solved);
      await wait(t, const Duration(seconds: 3));
    });
  }

  testWidgets('a Royal Box picture that cannot be loaded falls back to the box drawn in code', (t) async {
    final c = AnimationController(vsync: const TestVSync());
    addTearDown(c.dispose);
    const art = (closed: 'assets/art/special/missing_closed.png', open: 'assets/art/special/missing_open.png');
    await t.pumpWidget(MaterialApp(home: SizedBox(width: 300, height: 200, child: RoyalBoxAnimation(animation: c, art: art))));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await t.pump();
    expect(t.takeException(), isNull);
    expect(
      find.byWidgetPredicate((w) => w is CustomPaint && w.painter.runtimeType.toString() == '_RoyalBoxPainter'),
      findsNWidgets(2),
      reason: 'the light, and the drawn box in place of the missing picture',
    );
  });

  // The picture seam: with two pictures,
  // shut shows at 0, open at 1, the same animation in between, nothing
  // else of the screen involved. Stand-in files from the bundle.
  testWidgets('Royal Box pictures, when given: shut → open with the same animation', (t) async {
    final c = AnimationController(vsync: const TestVSync());
    addTearDown(c.dispose);
    const art = (closed: 'assets/art/objects/suitcase.png', open: 'assets/art/objects/crown.png');
    await t.pumpWidget(MaterialApp(home: SizedBox(width: 300, height: 200, child: RoyalBoxAnimation(animation: c, art: art))));
    double opacityOf(String file) => t
        .widgetList<Opacity>(find.ancestor(
          of: find.byWidgetPredicate((w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName == file),
          matching: find.byType(Opacity),
        ))
        .fold(1.0, (a, o) => a * o.opacity);
    expect(opacityOf(art.closed), 1);
    expect(find.byWidgetPredicate((w) => w is Image && (w.image as AssetImage).assetName == art.open), findsNothing);
    c.value = 0.35;
    await t.pump();
    expect(opacityOf(art.closed), inExclusiveRange(0.0, 1.0), reason: 'the lid swings: one into the other');
    expect(opacityOf(art.open), inExclusiveRange(0.0, 1.0));
    c.value = 1;
    await t.pump();
    expect(find.byWidgetPredicate((w) => w is Image && (w.image as AssetImage).assetName == art.closed), findsNothing);
    expect(opacityOf(art.open), 1, reason: 'open, as on a revisit');
  });
}
