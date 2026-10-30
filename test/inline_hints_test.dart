import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/core/constants/app_constants.dart';
import 'package:world_mystery/core/router/app_router.dart';
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/features/game/wallet_controller.dart';
import 'package:world_mystery/widgets/detective_tips.dart';

import 'full_playthrough_test.dart' show reveal, tapText, wait;
import 'helpers.dart';
import 'mission_play.dart';
import 'title_screen_test.dart' show capture;

/// Wave 2.6.1: hints are written on the puzzle itself (never a sheet over
/// it), fold and unfold, pile up in order, stay after a restart, and leave
/// the puzzle usable.
void main() {
  Finder hintCard(int n) => find.text('DETECTIVE HINT $n');
  final coins = find.byKey(const ValueKey('coin-balance'));
  int coinsShown(WidgetTester t) => int.parse(
    t
        .widget<Text>(find.descendant(of: coins, matching: find.byType(Text)))
        .data!,
  );

  /// No sheet and no dialog over the puzzle.
  void nothingOver() {
    expect(find.byType(BottomSheet), findsNothing, reason: 'no bottom sheet');
    expect(find.byType(Dialog), findsNothing, reason: 'no dialog');
  }

  for (final (size, scale, tag) in const [
    (Size(360, 640), 1.0, '360x640'),
    (Size(390, 844), 1.0, '390x844'),
    (Size(412, 915), 1.0, '412x915'),
    (Size(360, 640), 1.3, '360x640_x1.3'),
  ]) {
    group(tag, () {
      testWidgets(
        'multiple choice: hints on the page, folded and unfolded, piled up, the puzzle still answers',
        (t) async {
          // Case 01's first mission is a look round now, and Case 02's belfry
          // is searched (2026-10-30): its Time Card keeps the answer cards,
          // with the notebook's card at the page's foot.
          final play = MissionPlay();
          final mission = await play.openPuzzle(
            t,
            size,
            'ep02_m3',
            textScale: scale,
          );
          final before = play.ref.read(walletProvider).balance;
          await tapText(
            t,
            'Get a Free Hint',
            after: const Duration(milliseconds: 600),
          );
          nothingOver();
          expect(hintCard(1), findsOneWidget);
          expect(
            play.ref.read(walletProvider).balance,
            before,
            reason: 'the free hint costs nothing',
          );
          await reveal(t, findReadable(mission.hints[0]));
          expect(findReadable(mission.hints[0]), findsOneWidget);
          await capture(t, 'inline_hint1_$tag');

          // Fold, and open again.
          await reveal(t, hintCard(1));
          await t.tap(hintCard(1));
          await wait(t, const Duration(milliseconds: 400));
          expect(
            findReadable(mission.hints[0]),
            findsNothing,
            reason: 'folded to its label',
          );
          expect(hintCard(1), findsOneWidget);
          await t.tap(hintCard(1));
          await wait(t, const Duration(milliseconds: 400));
          expect(
            findReadable(mission.hints[0]),
            findsOneWidget,
            reason: 'open again',
          );

          // The paid hint: bought, then on the same page under the first.
          await tapText(
            t,
            'Get More Hints',
            after: const Duration(milliseconds: 600),
          );
          await takeTipFromSheet(t);
          await wait(t, const Duration(milliseconds: 400));
          nothingOver();
          expect(coinsShown(t), before - AppConstants.tipPrices[1], reason: 'the second hint paid for');
          expect(hintCard(2), findsOneWidget);
          expect(
            t.getRect(hintCard(1)).top,
            lessThan(t.getRect(hintCard(2)).top),
            reason: 'in the order opened',
          );
          await capture(t, 'inline_hint2_$tag');

          // The puzzle still answers with the hints open.
          await play.solve(t, mission);
          expect(
            play.ref.read(gameControllerProvider).isCompleted('ep02_m3'),
            isTrue,
          );
          expect(t.takeException(), isNull);
        },
      );
    });
  }

  testWidgets(
    'word input: the hint sits under the answer, and typing still works with the keyboard up',
    (t) async {
      // Case 06's wet card keeps the word puzzle page (Case 01 M2's word is
      // written on a label in its room: case01_inspect_test).
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(360, 640), 'ep06_m2');
      final field = find.byType(TextField);
      await reveal(t, field);
      await t.showKeyboard(field);
      t.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
      addTearDown(t.view.resetViewInsets);
      await wait(t, const Duration(milliseconds: 300));
      await tapText(
        t,
        'Get a Free Hint',
        after: const Duration(milliseconds: 600),
      );
      nothingOver();
      expect(hintCard(1), findsOneWidget);
      expect(
        t.getRect(field).top,
        lessThan(t.getRect(hintCard(1)).top),
        reason: 'under the answer',
      );
      await reveal(t, field);
      await t.enterText(field, 'grey');
      await t.pump();
      expect(find.text('grey'), findsOneWidget);
      await capture(t, 'inline_hint_word_keyboard_360x640');
      expect(t.takeException(), isNull);
    },
  );

  testWidgets('number code: the hint sits under the code and the check', (
    t,
  ) async {
    final play = MissionPlay();
    // A keypad mission (Case 01 M3, the keypad before, is now read for its traces).
    await play.openPuzzle(t, const Size(360, 640), 'ep08_m3');
    await tapText(
      t,
      'Get a Free Hint',
      after: const Duration(milliseconds: 600),
    );
    nothingOver();
    expect(hintCard(1), findsOneWidget);
    expect(
      t.getRect(find.text('UNLOCK')).top,
      lessThan(t.getRect(hintCard(1)).top),
      reason: 'under the keypad',
    );
    await capture(t, 'inline_hint_number_360x640');
    expect(t.takeException(), isNull);
  });

  testWidgets(
    'after a restart: the hints opened are there, nothing to buy again',
    (t) async {
      final play = MissionPlay();
      final mission = await play.openPuzzle(t, const Size(390, 844), 'm01');
      await tapText(
        t,
        'Get a Free Hint',
        after: const Duration(milliseconds: 600),
      );
      await tapText(
        t,
        'Get More Hints',
        after: const Duration(milliseconds: 600),
      );
      await takeTipFromSheet(t);
      await play.restart(t);
      play.ref.read(routerProvider).go(Routes.mission('m01'));
      await wait(t, const Duration(milliseconds: 1200));
      await reveal(t, findReadable(mission.hints[1]));
      expect(hintCard(1), findsOneWidget);
      expect(hintCard(2), findsOneWidget);
      expect(hintAction(), findsNothing);
      expect(coinsShown(t), 0, reason: 'charged once');
    },
  );

  testWidgets('Reduce Motion: the hint is there at once', (t) async {
    t.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final play = MissionPlay();
    final mission = await play.openPuzzle(t, const Size(390, 844), 'm01');
    await reveal(t, find.text('Get a Free Hint'));
    await t.tap(find.text('Get a Free Hint'));
    await t.pump();
    await t.pump();
    final card = t.getSize(find.byKey(const ValueKey('tip-0')));
    expect(card.height, greaterThan(60), reason: 'whole on the next frame');
    expect(findReadable(mission.hints[0]), findsOneWidget);
  });

  /// How lit hint [n]'s bulb is now (0 dark, 1 lit).
  double bulb(WidgetTester t, int n) {
    final paint = find.descendant(of: find.byKey(ValueKey('hint-bulb-$n')), matching: find.byType(CustomPaint)).first;
    return (t.widget<CustomPaint>(paint).painter! as HintBulbLight).level;
  }

  testWidgets('the bulb: lit while a hint is open, dark folded, each hint on its own', (t) async {
    final play = MissionPlay();
    final mission = await play.openPuzzle(t, const Size(390, 844), 'm01');
    await tapText(t, 'Get a Free Hint', after: const Duration(milliseconds: 600));
    // Hint 2 bought (the dialog is tested elsewhere).
    play.ref.read(gameControllerProvider.notifier).revealTip(mission, 2);
    await wait(t, const Duration(milliseconds: 600));
    expect(bulb(t, 1), 1, reason: 'open: lit');
    expect(bulb(t, 2), 1);

    // Folding hint 1: it goes out over about a fifth of a second; hint 2 stays lit.
    await reveal(t, hintCard(1));
    await t.tap(hintCard(1));
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    expect(bulb(t, 1), inExclusiveRange(0, 1), reason: 'going out, not a jump');
    await t.pump(const Duration(milliseconds: 200));
    expect(bulb(t, 1), 0, reason: 'folded: dark');
    expect(bulb(t, 2), 1, reason: 'hint 2 is its own');
    await capture(t, 'hint_bulb_dark_lit_390x844');

    // Hint 2 folded too, then hint 1 opened again.
    await reveal(t, hintCard(2));
    await t.tap(hintCard(2));
    await wait(t, const Duration(milliseconds: 400));
    expect(bulb(t, 2), 0);
    await reveal(t, hintCard(1));
    await t.tap(hintCard(1));
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
    expect(bulb(t, 1), inExclusiveRange(0, 1), reason: 'lighting up');
    await t.pump(const Duration(milliseconds: 200));
    expect(bulb(t, 1), 1);
    expect(bulb(t, 2), 0);
    expect(t.takeException(), isNull);
  });

  testWidgets('the bulb with Reduce Motion: on and off at once', (t) async {
    t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final play = MissionPlay();
    await play.openPuzzle(t, const Size(390, 844), 'm01');
    await tapText(t, 'Get a Free Hint', after: const Duration(milliseconds: 600));
    expect(bulb(t, 1), 1);
    await reveal(t, hintCard(1));
    await t.tap(hintCard(1));
    await t.pump();
    await t.pump();
    expect(bulb(t, 1), 0, reason: 'dark on the next frame');
    await t.tap(hintCard(1));
    await t.pump();
    await t.pump();
    expect(bulb(t, 1), 1, reason: 'lit on the next frame');
  });

  group('Case 06: the talk', () {
    for (final (size, scale, tag) in const [
      (Size(360, 640), 1.0, '360x640'),
      (Size(390, 844), 1.0, '390x844'),
      (Size(412, 915), 1.0, '412x915'),
      (Size(360, 640), 1.3, '360x640_x1.3'),
    ]) {
      testWidgets(
        '$tag: the hint is written in the panel under the questions; the talk goes on',
        (t) async {
          final play = MissionPlay();
          final mission = await play.openPuzzle(
            t,
            size,
            'ep06_m1',
            textScale: scale,
          );
          await play.tapKey(
            t,
            'lineup-juggler',
            after: const Duration(milliseconds: 900),
          );
          final panel = find.byKey(const ValueKey('talk-panel'));
          final link = find.descendant(
            of: panel,
            matching: find.text('Get a Free Hint'),
          );
          await reveal(t, link);
          await t.tap(link);
          await wait(t, const Duration(milliseconds: 600));
          nothingOver();
          expect(
            find.byKey(const ValueKey('statements-sheet')),
            findsNothing,
            reason: 'the notes do not open',
          );
          final card = find.descendant(of: panel, matching: hintCard(1));
          expect(card, findsOneWidget, reason: 'in the panel');
          expect(
            find.descendant(
              of: panel,
              matching: findReadable(mission.hints[0]),
            ),
            findsOneWidget,
          );
          final r = t.getRect(card);
          expect(
            r.top,
            greaterThanOrEqualTo(t.getRect(panel).top),
            reason: 'in sight in the panel',
          );
          expect(r.top, lessThan(size.height));
          // Under the questions, above the links.
          final question = find.byKey(const ValueKey('question-carry'));
          await reveal(t, question);
          expect(t.getRect(question).top, lessThan(t.getRect(card).top));
          await reveal(t, find.byKey(const ValueKey('open-words')));
          expect(
            t.getRect(card).top,
            lessThan(t.getRect(find.byKey(const ValueKey('open-words'))).top),
          );
          await capture(t, 'inline_hint_case06_$tag');
          // The questions still work.
          await play.tapKey(t, 'question-carry');
          expect(find.text('THE JUGGLER'), findsOneWidget);
          expect(t.takeException(), isNull);
        },
      );
    }
  });

  group('Case 03: the search', () {
    for (final (size, tag) in const [
      (Size(360, 640), '360x640'),
      (Size(412, 915), '412x915'),
    ]) {
      testWidgets(
        '$tag: the hint is written in the panel under the picture; the report stays closed',
        (t) async {
          final play = MissionPlay();
          final mission = await play.openPuzzle(t, size, 'ep03_m1');
          await tapText(
            t,
            'Get a Free Hint',
            after: const Duration(milliseconds: 600),
          );
          nothingOver();
          final panel = find.byKey(const ValueKey('search-panel'));
          expect(
            find.descendant(of: panel, matching: hintCard(1)),
            findsOneWidget,
          );
          expect(
            find.descendant(
              of: panel,
              matching: findReadable(mission.hints[0]),
            ),
            findsOneWidget,
          );
          final picture = t.getRect(
            find.byKey(const ValueKey('investigation-picture')),
          );
          expect(
            picture.height,
            greaterThan(size.height * 0.25),
            reason: 'the picture keeps its room',
          );
          await capture(t, 'inline_hint_case03_$tag');
          expect(t.takeException(), isNull);
        },
      );
    }
  });
}
