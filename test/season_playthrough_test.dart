import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/features/game/game_providers.dart';

import 'full_playthrough_test.dart' show finishMission, goToTime, openMission, reveal, tapText, throughPostCase, wait;
import 'helpers.dart';

void main() {
  testWidgets('after Case 01, a child can open and solve Case 02, which opens Case 03', (t) async {
    WidgetController.hitTestWarningShouldBeFatal = true; // every tap must land
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
    await t.pumpWidget(ProviderScope(
      overrides: await testOverrides(prefs: {AppConstants.progressStorageKey: saved}),
      child: Consumer(builder: (context, ref, _) {
        appRef = ref;
        return const LondonMysteryApp();
      }),
    ));
    await wait(t);

    // Title → Case 01's case file → the next case file.
    await tapText(t, 'CONTINUE ADVENTURE', after: const Duration(milliseconds: 3200));
    expect(find.text('CASE CLOSED'), findsOneWidget);
    await tapText(t, 'OPEN CASE 02', after: const Duration(milliseconds: 800));

    // Case files: Case 02 is open, the ones after it are sealed.
    expect(find.text('CASE FILES'), findsOneWidget);
    expect(find.text('THE SILENT CLOCK'), findsOneWidget);
    await tapText(t, 'THE VANISHING PAINTING', after: const Duration(milliseconds: 400));
    expect(find.text('Solve Case 02 to open this file.'), findsOneWidget);
    await tapText(t, 'THE SILENT CLOCK', after: const Duration(milliseconds: 400));
    await tapText(t, 'Big Ben has stopped. Its hands do not move.', after: const Duration(milliseconds: 400));
    await tapText(t, 'BEGIN INVESTIGATION');
    await tapText(t, 'SKIP ›');
    await tapText(t, "I'M READY", after: const Duration(milliseconds: 1500));

    // ── Mission 1: read the clock (keypad).
    expect(find.text('The Silent Clock'), findsOneWidget, reason: 'the map shows the case');
    await openMission(t, 'GO TO WESTMINSTER BRIDGE');
    for (final d in ['8', '1', '7']) {
      await tapText(t, d, after: const Duration(milliseconds: 150));
    }
    await tapText(t, 'UNLOCK', after: Duration.zero);
    await finishMission(t, sceneLine: 'Mrs Bell opens a small door at the bottom of the tower.');

    // ── Mission 2: a wrong answer first, then the right bell.
    await openMission(t, 'GO TO THE CLOCK ROOM');
    await tapText(t, 'Under the biggest bell', after: const Duration(milliseconds: 200));
    await tapText(t, 'CHECK ANSWER');
    expect(find.text('Not quite!'), findsOneWidget);
    await tapText(t, 'GET A TIP');
    expect(find.text('DETECTIVE TIP 1'), findsOneWidget);
    await tapText(t, 'Under the smallest bell', after: const Duration(milliseconds: 200));
    await tapText(t, 'CHECK ANSWER', after: Duration.zero);
    await finishMission(t, sceneLine: 'You hold the brass gear up to the light.');

    // ── Mission 3: the plan hides its gallery and picture in the stopped
    // clock. The detective checks the notebook (8:17, the first clue) and
    // works out Gallery 8 · Picture 17; swapping hour and minutes is wrong.
    await t.tap(find.bySemanticsLabel('GO TO THE BELFRY'));
    await wait(t, goToTime);
    await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 700));
    await tapText(t, 'TAP TO OPEN', after: const Duration(milliseconds: 1800));
    expect(find.textContaining('9:17'), findsNothing, reason: "the plan never writes the final's time");
    await tapText(t, 'SOLVE THE PUZZLE', after: const Duration(milliseconds: 900));
    await t.tap(find.byTooltip('Detective notebook'));
    await wait(t, const Duration(milliseconds: 900));
    expect(find.text('8:17'), findsOneWidget, reason: 'the stopped time, kept in the notebook');
    await t.tap(find.byTooltip('Close'));
    await wait(t, const Duration(milliseconds: 900));
    await tapText(t, 'Gallery 17 · Picture 8', after: const Duration(milliseconds: 200));
    await tapText(t, 'CHECK ANSWER');
    expect(find.text('Not quite!'), findsOneWidget);
    await tapText(t, 'TRY AGAIN', after: const Duration(milliseconds: 400));
    await tapText(t, 'Gallery 8 · Picture 17', after: const Duration(milliseconds: 200));
    await tapText(t, 'CHECK ANSWER', after: Duration.zero);
    await finishMission(t, sceneLine: 'The time was a message.');

    // ── Final case: 8:17 + one hour — set the Great Clock to 9:17 on the dials.
    await tapText(t, 'OPEN THE FINAL CASE', after: goToTime);
    expect(find.text('INSIDE BIG BEN'), findsOneWidget);
    expect(find.textContaining('9:17'), findsNothing, reason: 'the detective works the time out');
    for (final (i, digit) in [9, 1, 7].indexed) {
      final up = find.byTooltip('Lock ${i + 1} up');
      await reveal(t, up);
      for (var n = 0; n < digit; n++) {
        await t.tap(up);
        await t.pump(const Duration(milliseconds: 20));
      }
    }
    await wait(t, const Duration(milliseconds: 300));
    await tapText(t, 'UNLOCK', after: const Duration(milliseconds: 3500));
    expect(find.text('CASE SOLVED'), findsOneWidget);
    expect(find.text('Big Ben rings again!'), findsOneWidget);

    await throughPostCase(t, caseNumber: '02', evidence: 'Raven Feather');
    expect(find.text('THE SILENT CLOCK'), findsOneWidget);
    expect(find.text('CLOCK WATCHER'), findsOneWidget, reason: "the case's own badge");
    await reveal(t, find.text('Evidence'));
    expect(find.text('4 / 4'), findsOneWidget); // evidence
    expect(find.text('3 / 3'), findsOneWidget); // clues

    // Case 01 is untouched, and Case 03 is open now.
    final prefs = appRef.read(sharedPreferencesProvider);
    expect(prefs.getString(AppConstants.progressStorageKey), saved);
    // OPEN CASE 03 lands on Case 03 with its folder already open and chosen.
    await tapText(t, 'OPEN CASE 03', after: const Duration(milliseconds: 800));
    expect(find.text('Solve Case 02 to open this file.'), findsNothing);
    expect(find.text('A painting has vanished from Gallery 8.'), findsOneWidget);
    expect(find.text('BEGIN INVESTIGATION'), findsOneWidget);
    await wait(t, const Duration(seconds: 3));
  });
}
