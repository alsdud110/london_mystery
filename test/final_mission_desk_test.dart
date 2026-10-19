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
/// locks as before, OPEN THE BOX and CONTINUE (to the post-case scene) as glass buttons.
void main() {
  setUpAll(() async {
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

  for (final size in const [Size(360, 640), Size(390, 844)]) {
    final tag = '${size.width.toInt()}x${size.height.toInt()}';
    testWidgets('final mission $tag: desk, locks, OPEN THE BOX → open → CONTINUE, and a revisit', (t) async {
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
      // Its drums blank in the picture (the painted 0000 never shown), the
      // locks' numbers written on them: 0 0 0 0 to start.
      expect(showing(ArtAssets.royalBoxClosedPainted), isFalse);
      String drum(int i) =>
          t.widget<Text>(find.descendant(of: find.byKey(ValueKey('royal-box-dial-$i')), matching: find.byType(Text)).last).data!;
      expect([for (var i = 0; i < 4; i++) drum(i)], ['0', '0', '0', '0']);
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
      // The box's drums follow the locks; still shut, the open box unseen.
      expect([for (var i = 0; i < 4; i++) drum(i)], ['7', '9', '2', '4']);
      expect(showing(ArtAssets.royalBox.open), isFalse, reason: 'not open before OPEN THE BOX');
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

      // D–E. Open, solved, CONTINUE (to the post-case scene) as the glass button.
      final onward = find.text('CONTINUE INVESTIGATION');
      await t.scrollUntilVisible(onward, 300, scrollable: find.byType(Scrollable).first);
      await wait(t, const Duration(milliseconds: 300));
      expect(t.widget<GameButton>(find.ancestor(of: onward, matching: find.byType(GameButton))).style, GameButtonStyle.glass);
      expect(find.text('SEE MY CASE REPORT'), findsNothing, reason: 'the report comes after the post-case scene');
      expect(find.text('CASE SOLVED'), findsOneWidget);
      expect(showing(ArtAssets.royalBox.open), isTrue, reason: 'open, the Crown inside');
      expect(showing(ArtAssets.royalBox.closed), isFalse);
      expect(find.byKey(const ValueKey('royal-box-dial-0')), findsNothing, reason: 'the open box prints its own code');
      // Open, the Crown reads large: the box fills the page's width, closer.
      final openBox = t.getRect(find.byKey(const ValueKey('royal-box-open')));
      final page = t.getRect(find.byType(RoyalBoxAnimation));
      expect(openBox.width, greaterThan(page.width), reason: 'looked at closer than the whole canvas');
      expect(page.width / size.width, greaterThan(0.8));
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
      await t.scrollUntilVisible(onward, 300, scrollable: find.byType(Scrollable).first);
      await wait(t, const Duration(milliseconds: 300));
      await t.tap(onward);
      await wait(t, const Duration(milliseconds: 1500));
      expect(router.routerDelegate.currentConfiguration.uri.path, Routes.story('final'));
      await t.tapAt(Offset(size.width / 2, size.height / 2)); // the whole story at once
      await wait(t, const Duration(milliseconds: 1200));
      await t.tap(find.text('SEE MY CASE REPORT'));
      await wait(t, const Duration(milliseconds: 1500));
      expect(router.routerDelegate.currentConfiguration.uri.path, Routes.solved);
      await wait(t, const Duration(seconds: 3));
    });
  }

  testWidgets('a Royal Box picture that cannot be loaded falls back to the box drawn in code', (t) async {
    final c = AnimationController(vsync: const TestVSync());
    addTearDown(c.dispose);
    final art = (
      closed: 'assets/art/special/missing_closed.png',
      open: 'assets/art/special/missing_open.png',
      dials: ArtAssets.royalBox.dials,
      shut: ArtAssets.royalBox.shut,
      opened: ArtAssets.royalBox.opened,
    );
    await t.pumpWidget(MaterialApp(home: SizedBox(width: 300, height: 200, child: RoyalBoxAnimation(animation: c, art: art))));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await t.pump();
    expect(t.takeException(), isNull);
    expect(
      find.byWidgetPredicate((w) => w is CustomPaint && w.painter.runtimeType.toString() == '_RoyalBoxPainter'),
      findsOneWidget,
      reason: 'the drawn box in place of the missing picture',
    );
  });

  // The picture seam: with two pictures,
  // shut shows at 0, open at 1, the same animation in between, nothing
  // else of the screen involved. Stand-in files from the bundle.
  testWidgets('Royal Box pictures, when given: shut → open with the same animation', (t) async {
    final c = AnimationController(vsync: const TestVSync());
    addTearDown(c.dispose);
    final art = (
      closed: 'assets/art/objects/suitcase.png',
      open: 'assets/art/objects/crown.png',
      dials: const <Rect>[],
      shut: ArtAssets.royalBox.shut,
      opened: ArtAssets.royalBox.opened,
    );
    await t.pumpWidget(MaterialApp(home: SizedBox(width: 300, height: 200, child: RoyalBoxAnimation(animation: c, art: art))));
    double opacityOf(String file) => t
        .widgetList<Opacity>(find.ancestor(
          of: find.byWidgetPredicate((w) => w is Image && w.image is AssetImage && (w.image as AssetImage).assetName == file),
          matching: find.byType(Opacity),
        ))
        .fold(1.0, (a, o) => a * o.opacity);
    expect(opacityOf(art.closed), 1);
    expect(find.byWidgetPredicate((w) => w is Image && (w.image as AssetImage).assetName == art.open), findsNothing);
    c.value = 0.24; // the lid starting to swing (the shut box gives way first)
    await t.pump();
    expect(opacityOf(art.closed), inExclusiveRange(0.0, 1.0), reason: 'the lid swings: one into the other');
    expect(opacityOf(art.open), inExclusiveRange(0.0, 1.0));
    c.value = 1;
    await t.pump();
    expect(find.byWidgetPredicate((w) => w is Image && (w.image as AssetImage).assetName == art.closed), findsNothing);
    expect(opacityOf(art.open), 1, reason: 'open, as on a revisit');
  });
}
