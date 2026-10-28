import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/app.dart';
import 'package:world_mystery/core/router/app_router.dart';
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/difficulty.dart';
import 'package:world_mystery/data/models/easy_steps.dart';
import 'package:world_mystery/data/models/season.dart';
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/features/game/game_providers.dart';

import 'difficulty_paris_7d_test.dart' show parisAt;
import 'easy_play.dart';
import 'full_playthrough_test.dart' show tapText, wait;
import 'helpers.dart';

/// Case 11 M1's page rubbed with a finger, where the step page can scroll:
/// a small phone, large text, the hints shown. On the page being rubbed a
/// stroke rubs, whichever way it goes, and never scrolls; anywhere else a
/// drag scrolls the page as before.
void main() {
  for (final level in const [Difficulty.junior, Difficulty.master]) {
    testWidgets('360x640, text 1.3, ${level.name}: the rub wins on the page, the scroll everywhere else', (t) async {
      await loadGameFonts();
      t.view.physicalSize = const Size(360, 640) * 3;
      t.view.devicePixelRatio = 3;
      t.view.padding = const FakeViewPadding(top: 24 * 3, bottom: 24 * 3);
      t.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(t.view.reset);
      addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
      late WidgetRef ref;
      await t.pumpWidget(ProviderScope(
        overrides: [
          ...await testOverrides(prefs: parisAt(level, active: 's2_ep11', selected: false)),
          seasonPreviewProvider.overrideWithValue(true),
        ],
        child: Consumer(builder: (context, r, _) {
          ref = r;
          return const WorldMysteryApp();
        }),
      ));
      await wait(t, const Duration(milliseconds: 300));
      final game = ref.read(gameControllerProvider.notifier);
      expect(game.openSeason(SeasonIds.paris), isTrue);
      expect(game.openEpisode('s2_ep11'), isTrue);
      game.startInvestigation();
      final m1 = ref.read(currentEpisodeProvider).missions.first;
      final steps = SeasonCatalog.easySteps(m1)!;
      ref.read(routerProvider).go(Routes.mission(m1.id));
      await wait(t, const Duration(milliseconds: 1400));
      await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 2500));
      final play = EasyPlay(t, 'rub_scroll');
      await play.talk();
      await play.tapOn('book', (steps.steps.first.panels.first as PicturePanel).picture, null);
      play.expectSay(steps.steps[1].say);
      for (var i = 0; i < 2; i++) {
        await play.tapKey('easy-hint', after: const Duration(milliseconds: 400));
      }

      final rub = find.byKey(const ValueKey('easy-rub'));
      final page = t.state<ScrollableState>(find.ancestor(of: rub, matching: find.byType(Scrollable)).first).position;
      expect(page.maxScrollExtent, greaterThan(0), reason: 'the step page scrolls here: what this test is about');

      // Away from the page being rubbed: a drag scrolls, and back.
      await t.drag(find.byKey(const ValueKey('easy-hint')), const Offset(0, -200));
      await wait(t, const Duration(milliseconds: 400));
      expect(page.pixels, greaterThan(0), reason: 'a drag beside the page scrolls');
      await t.drag(find.byKey(const ValueKey('easy-hint')), const Offset(0, 400));
      await wait(t, const Duration(milliseconds: 400));
      expect(page.pixels, 0);

      // On the page: strokes up and down rub it, the step page stays put.
      final done = findReadable(steps.steps[1].done!);
      for (var i = 0; i < 9 && done.evaluate().isEmpty; i++) {
        final r = t.getRect(rub);
        final x = r.left + r.width * (0.1 + 0.1 * i);
        final (from, to) = i.isEven ? (r.top + 4, r.bottom - 4) : (r.bottom - 4, r.top + 4);
        final finger = await t.startGesture(Offset(x, from));
        for (var k = 1; k <= 10; k++) {
          await finger.moveTo(Offset(x, from + (to - from) * k / 10));
          await t.pump(const Duration(milliseconds: 16));
        }
        await finger.up();
        await wait(t, const Duration(milliseconds: 300));
        expect(page.pixels, 0, reason: 'stroke $i rubs; it does not scroll');
      }
      expect(done, findsOneWidget, reason: 'strokes up and down bring out the page');
      await play.next();
      expect(t.takeException(), isNull);
      await wait(t, const Duration(seconds: 2));
    });
  }
}
