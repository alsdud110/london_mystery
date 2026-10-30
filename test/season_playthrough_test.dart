import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/app.dart';
import 'package:world_mystery/core/constants/app_constants.dart';
import 'package:world_mystery/data/mock/season1/season1_investigations.dart';
import 'package:world_mystery/data/models/game_progress.dart';
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/features/game/game_providers.dart';

import 'full_playthrough_test.dart'
    show
        finishMission,
        goToTime,
        openMission,
        reveal,
        tapText,
        throughPostCase,
        wait;
import 'helpers.dart';

void main() {
  testWidgets(
    'after Case 01, a child can open and solve Case 02, which opens Case 03',
    (t) async {
      WidgetController.hitTestWarningShouldBeFatal =
          true; // every tap must land
      addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);
      t.view.physicalSize = const Size(1170, 2532);
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);

      // A Case 01 save exactly as the app wrote it before the season existed.
      final crownSolved = GameProgress(
        detectiveName: 'MINYOUNG',
        introSeen: true,
        completedMissionIds: [for (final m in episode01.allMissions) m.id],
        badgeIds: const ['firstClue', 'masterDetective'],
        startedAt: DateTime(2026, 9, 1, 10),
        completedAt: DateTime(2026, 9, 1, 10, 30),
        playMillis: 30 * 60 * 1000,
      );
      final saved = jsonEncode(crownSolved.toJson());
      late WidgetRef appRef;
      await t.pumpWidget(
        ProviderScope(
          overrides: await testOverrides(
            prefs: {AppConstants.progressStorageKey: saved},
          ),
          child: Consumer(
            builder: (context, ref, _) {
              appRef = ref;
              return const WorldMysteryApp();
            },
          ),
        ),
      );
      await wait(t);

      // Title → the World Map → Case 01's case file → the next case file.
      await tapText(
        t,
        'CONTINUE ADVENTURE',
        after: const Duration(milliseconds: 1200),
      );
      await tapText(t, 'CONTINUE', after: const Duration(milliseconds: 3200));
      expect(find.text('CASE CLOSED'), findsOneWidget);
      await tapText(
        t,
        'OPEN CASE 02',
        after: const Duration(milliseconds: 800),
      );
      // The investigation board: Case 02 is the current case.
      expect(find.text('CURRENT CASE'), findsOneWidget);
      expect(find.text('The Silent Clock'), findsOneWidget);
      await tapText(
        t,
        'View all case files',
        after: const Duration(milliseconds: 800),
      );

      // Case files: Case 02 is open, the ones after it are sealed.
      expect(find.text('CASE FILES'), findsOneWidget);
      expect(find.text('THE SILENT CLOCK'), findsOneWidget);
      await tapText(
        t,
        'THE VANISHING PAINTING',
        after: const Duration(milliseconds: 400),
      );
      expect(find.text('Solve Case 02 to open this file.'), findsOneWidget);
      await tapText(
        t,
        'THE SILENT CLOCK',
        after: const Duration(milliseconds: 400),
      );
      await tapText(
        t,
        'Big Ben has stopped. Its hands do not move.',
        after: const Duration(milliseconds: 400),
      );
      await tapText(t, 'BEGIN INVESTIGATION');
      await tapText(t, 'SKIP ›');
      await tapText(t, "I'M READY", after: const Duration(milliseconds: 1500));

      // ── Mission 1: set Mrs Bell's clock face to the stopped time (from
      // 12:00: eight hours on, then seventeen minutes).
      expect(
        find.text('The Silent Clock'),
        findsOneWidget,
        reason: 'the map shows the case',
      );
      await openMission(t, 'GO TO WESTMINSTER BRIDGE');
      for (final (key, times) in const [('clock-hour-plus', 8), ('clock-minute-plus', 17)]) {
        for (var i = 0; i < times; i++) {
          await reveal(t, find.byKey(ValueKey(key)));
          await t.tap(find.byKey(ValueKey(key)));
          await t.pump(const Duration(milliseconds: 60));
        }
      }
      expect(find.text('8:17'), findsOneWidget);
      await reveal(t, find.byKey(const ValueKey('clock-submit')));
      await t.tap(find.byKey(const ValueKey('clock-submit')));
      await t.pump();
      await finishMission(
        t,
        sceneLine: 'Mrs Bell opens a small door at the bottom of the tower.',
      );

      // ── Mission 2: the belfry searched with R.'s note (2026-10-30): the
      // biggest bell first (the note says NOT), then the smallest.
      final belfry = season1Investigations['ep02_m2']!;
      Future<void> tapBelfry(Offset point) async {
        final picture = find.byKey(const ValueKey('investigation-picture'));
        final box = t.getRect(find.descendant(of: picture, matching: find.byType(GestureDetector)).first);
        await t.tapAt(Offset(box.left + point.dx * box.width, box.top + point.dy * box.height));
        await wait(t, const Duration(milliseconds: 700));
      }

      await t.tap(find.bySemanticsLabel('GO TO THE CLOCK ROOM'));
      await wait(t, goToTime);
      await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 700));
      await wait(t, const Duration(milliseconds: 2400)); // the arrival, then the note
      await tapText(t, belfry.startLabel, after: const Duration(milliseconds: 1400));
      await tapBelfry(belfry.spots.first.areas.first.center);
      expect(appRef.read(gameControllerProvider).isCompleted('ep02_m2'), isFalse, reason: 'not under the biggest bell');
      await tapBelfry(belfry.finds.single.areas.first.center);
      await wait(t, const Duration(milliseconds: 400));
      await t.tap(find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key! as ValueKey<String>).value.startsWith('find-card-')));
      await wait(t, const Duration(milliseconds: 1500));
      await finishMission(
        t,
        sceneLine: 'You hold the brass gear up to the light.',
      );

      // ── Mission 3: the plan hides its gallery and picture in the stopped
      // clock. The detective checks the notebook (8:17, the first clue) and
      // works out Gallery 8 · Picture 17; swapping hour and minutes is wrong.
      await t.tap(find.bySemanticsLabel('GO TO THE BELFRY'));
      await wait(t, goToTime);
      await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 700));
      await tapText(
        t,
        'TAP TO OPEN',
        after: const Duration(milliseconds: 1800),
      );
      expect(
        find.textContaining('9:17'),
        findsNothing,
        reason: "the plan never writes the final's time",
      );
      await tapText(
        t,
        'SOLVE THE PUZZLE',
        after: const Duration(milliseconds: 900),
      );
      await t.tap(find.byTooltip('Detective notebook'));
      await wait(t, const Duration(milliseconds: 900));
      expect(
        find.text('8:17'),
        findsOneWidget,
        reason: 'the stopped time, kept in the notebook',
      );
      await t.tap(find.byTooltip('Close'));
      await wait(t, const Duration(milliseconds: 900));
      await tapText(
        t,
        'Gallery 17 · Picture 8',
        after: const Duration(milliseconds: 200),
      );
      await tapText(t, 'CHECK ANSWER');
      expect(find.text('Not quite!'), findsOneWidget);
      await tapText(t, 'TRY AGAIN', after: const Duration(milliseconds: 400));
      await tapText(
        t,
        'Gallery 8 · Picture 17',
        after: const Duration(milliseconds: 200),
      );
      await tapText(t, 'CHECK ANSWER', after: Duration.zero);
      await finishMission(t, sceneLine: 'The time was a message.');

      // ── Final case: 8:17 + one hour — the Great Clock's own hands, frozen
      // at 8:17, set to 9:17 (2026-10-30; was three number wheels).
      await tapText(t, 'OPEN THE FINAL CASE', after: goToTime);
      expect(find.text('INSIDE BIG BEN'), findsOneWidget);
      expect(
        find.textContaining('9:17'),
        findsNothing,
        reason: 'the detective works the time out',
      );
      expect(find.byTooltip('Lock 1 up'), findsNothing, reason: 'no number wheels: the clock itself');
      Future<void> key(String k) async {
        await reveal(t, find.byKey(ValueKey(k)));
        await t.tap(find.byKey(ValueKey(k)));
        await t.pump(const Duration(milliseconds: 60));
      }

      expect(t.widget<Text>(find.byKey(const ValueKey('clock-time'))).data, '8:17', reason: 'frozen where it stopped');
      // A minute on is a slip the final answers (the hour moves, not the minutes).
      await key('clock-minute-plus');
      await key('clock-submit');
      await wait(t, const Duration(milliseconds: 600));
      expect(find.text('Not quite!'), findsOneWidget);
      await tapText(t, 'TRY AGAIN', after: const Duration(milliseconds: 400));
      await key('clock-minute-minus');
      await key('clock-hour-plus');
      expect(t.widget<Text>(find.byKey(const ValueKey('clock-time'))).data, '9:17');
      await key('clock-submit');
      await wait(t, const Duration(milliseconds: 3500));
      expect(find.text('CASE SOLVED'), findsOneWidget);
      expect(find.text('Big Ben rings again!'), findsOneWidget);

      await throughPostCase(t, caseNumber: '02', evidence: 'Raven Feather');
      expect(find.text('THE SILENT CLOCK'), findsOneWidget);
      expect(
        find.text('CLOCK WATCHER'),
        findsOneWidget,
        reason: "the case's own badge",
      );
      await reveal(t, find.text('Evidence'));
      expect(find.text('4 / 4'), findsOneWidget); // evidence
      expect(find.text('3 / 3'), findsOneWidget); // clues

      // Case 01 is untouched, and Case 03 is open now.
      final prefs = appRef.read(sharedPreferencesProvider);
      expect(savedString(prefs, AppConstants.progressStorageKey), saved);
      // OPEN CASE 03 lands on the board, Case 03 its current case, ready to begin.
      await tapText(
        t,
        'OPEN CASE 03',
        after: const Duration(milliseconds: 800),
      );
      expect(find.text('The Vanishing Painting'), findsOneWidget);
      expect(find.text('BEGIN INVESTIGATION'), findsOneWidget);
      await wait(t, const Duration(seconds: 3));
    },
  );
}
