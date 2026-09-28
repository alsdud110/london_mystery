import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/utils/audio_service.dart';
import 'package:london_mystery/features/game/game_providers.dart' show sharedPreferencesProvider;

import 'helpers.dart';
import 'parent_gate_test.dart' show gateAnswer;

/// Pumps frames for [d] without waiting for looping animations to settle.
Future<void> wait(WidgetTester t, [Duration d = const Duration(milliseconds: 800)]) async {
  const step = Duration(milliseconds: 50);
  for (var e = Duration.zero; e < d; e += step) {
    await t.pump(step);
  }
}

/// Scrolls lazily-built lists until [f] exists, then centres it on screen.
Future<void> reveal(WidgetTester t, Finder f) async {
  if (f.evaluate().isEmpty) {
    await t.scrollUntilVisible(f, 250, scrollable: find.byType(Scrollable).first);
  }
  await Scrollable.ensureVisible(t.element(f.last), alignment: 0.5);
  await t.pump();
}

Future<void> tapText(WidgetTester t, String text, {Duration after = const Duration(milliseconds: 800)}) async {
  await reveal(t, find.text(text));
  await t.tap(find.text(text).last);
  await wait(t, after);
}

/// Map → mission: open the envelope, read the letter, go to the puzzle.
Future<void> openMission(WidgetTester t, String goLabel) async {
  await tapText(t, goLabel, after: const Duration(milliseconds: 1500));
  expect(find.text('TAP TO OPEN'), findsOneWidget, reason: 'step 1: the sealed letter');
  await tapText(t, 'TAP TO OPEN', after: const Duration(milliseconds: 1800));
  expect(find.text('THE LETTER'), findsOneWidget, reason: 'step 2: read the letter');
  await tapText(t, 'I READ IT! SOLVE THE PUZZLE', after: const Duration(milliseconds: 900));
  expect(find.text('NEED A TIP?'), findsOneWidget, reason: 'step 3: the puzzle');
}

/// Success overlay → story scene → back on the map (unlock ceremony).
Future<void> finishMission(WidgetTester t, {required String sceneLine}) async {
  await wait(t, const Duration(milliseconds: 2800));
  expect(find.text('SUCCESS!'), findsOneWidget);
  expect(find.text('Well done, Detective MINYOUNG!'), findsOneWidget);
  expect(find.text('ADDED TO YOUR NOTEBOOK'), findsOneWidget);
  await tapText(t, 'CONTINUE', after: const Duration(milliseconds: 900));
  expect(find.text(sceneLine), findsOneWidget, reason: 'story transition');
  await t.tapAt(const Offset(200, 400)); // skip typing
  await wait(t, const Duration(milliseconds: 900));
  await tapText(t, 'TO THE MAP', after: const Duration(milliseconds: 1200));
  await wait(t, const Duration(milliseconds: 3200)); // LOCKED → UNLOCKED ceremony
}

void main() {
  testWidgets('a child can play Episode 01 from title screen to the case report', (t) async {
    WidgetController.hitTestWarningShouldBeFatal = true; // every tap must land
    addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);
    t.view.physicalSize = const Size(1170, 2532);
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);

    final audio = MockAudioService();
    final overrides = await testOverrides(audio: audio);
    late WidgetRef appRef;
    await t.pumpWidget(ProviderScope(
      overrides: overrides,
      child: Consumer(builder: (context, ref, _) {
        appRef = ref;
        return const LondonMysteryApp();
      }),
    ));
    await wait(t);

    // START → register.
    expect(find.text('Become a Detective.'), findsOneWidget);
    await tapText(t, 'START ADVENTURE');
    await t.enterText(find.byType(TextField), 'minyoung');
    await tapText(t, 'START MISSION');

    // Episode → story intro.
    expect(find.text('THE MISSING CROWN'), findsOneWidget);
    await tapText(t, 'BEGIN INVESTIGATION');
    await tapText(t, 'SKIP ›');
    await tapText(t, "I'M READY", after: const Duration(milliseconds: 1500));

    // Map: only King's Cross is open; locked pins explain themselves.
    expect(find.text('0 / 5'), findsOneWidget);
    expect(find.text('Detective MINYOUNG'), findsOneWidget);
    await t.tap(find.text('BRITISH MUSEUM'));
    await wait(t);
    expect(find.textContaining('Locked!'), findsOneWidget);
    await wait(t, const Duration(seconds: 3));

    // ── Mission 01: word card, a wrong answer, a tip, then the answer.
    await openMission(t, 'PLAY MISSION 01');
    await tapText(t, 'Letter', after: const Duration(milliseconds: 600)); // re-read the letter
    await t.tapOnText(find.textRange.ofSubstring('museum').first);
    await wait(t, const Duration(milliseconds: 600));
    expect(find.text('= 박물관'), findsOneWidget, reason: 'tap a word to see its meaning');
    await tapText(t, 'GOT IT!', after: const Duration(milliseconds: 500));
    await tapText(t, 'BACK TO THE PUZZLE', after: const Duration(milliseconds: 500));

    await tapText(t, 'Hyde Park', after: const Duration(milliseconds: 200));
    await tapText(t, 'CHECK ANSWER');
    expect(find.text('Not quite!'), findsOneWidget);
    expect(audio.played, contains(GameSound.wrong));
    await tapText(t, '💡 GET A TIP');
    expect(find.text('DETECTIVE TIP 1'), findsOneWidget);
    await tapText(t, 'The British Museum', after: const Duration(milliseconds: 200));
    await tapText(t, 'CHECK ANSWER', after: Duration.zero);
    await wait(t, const Duration(milliseconds: 2800));
    expect(find.text('NEW BADGE!'), findsOneWidget);
    expect(find.text('First Clue'), findsOneWidget);
    await tapText(t, 'CONTINUE', after: const Duration(milliseconds: 900));
    expect(find.text('The letter suddenly begins to glow...'), findsOneWidget);
    await t.tapAt(const Offset(200, 400));
    await wait(t, const Duration(milliseconds: 900));
    expect(find.text('NEW PLACE UNLOCKED'), findsOneWidget);
    await tapText(t, 'TO THE MAP', after: const Duration(milliseconds: 1400));
    expect(find.text('UNLOCKED!'), findsOneWidget, reason: 'pin ceremony');
    await wait(t, const Duration(milliseconds: 3000));
    expect(audio.played, contains(GameSound.unlock));
    expect(find.text('1 / 5'), findsOneWidget);

    // ── Mission 02: word input, using both tips.
    await openMission(t, 'PLAY MISSION 02');
    await tapText(t, 'NEED A TIP?', after: const Duration(milliseconds: 500));
    await tapText(t, 'ONE MORE TIP', after: const Duration(milliseconds: 500));
    expect(find.text('DETECTIVE TIP 2'), findsOneWidget);
    expect(find.text('NEED A TIP?'), findsNothing);
    await reveal(t, find.byType(TextField));
    await t.enterText(find.byType(TextField), 'stone');
    await tapText(t, 'CHECK ANSWER', after: Duration.zero);
    await finishMission(t, sceneLine: 'The old stone shines in the dark.');

    // ── Mission 03: number code keypad.
    await openMission(t, 'PLAY MISSION 03');
    for (final d in ['4', '1', '7']) {
      await tapText(t, d, after: const Duration(milliseconds: 150));
    }
    await tapText(t, 'UNLOCK', after: Duration.zero);
    await finishMission(t, sceneLine: 'Inside the box, there is a photo.');

    // ── Mission 04: image choice (picture C = Buckingham Palace).
    await openMission(t, 'PLAY MISSION 04');
    final pictureC = find.bySemanticsLabel('Picture C');
    await reveal(t, pictureC);
    await t.tap(pictureC);
    await wait(t, const Duration(milliseconds: 300));
    await tapText(t, 'CHECK ANSWER', after: Duration.zero);
    await finishMission(t, sceneLine: 'The swans fly up into the sky.');

    // ── Mission 05: QR (typed fallback, as on a device without a camera).
    await openMission(t, 'PLAY MISSION 05');
    await tapText(t, "Can't scan? Type the code", after: const Duration(milliseconds: 400));
    await reveal(t, find.byType(TextField));
    await t.enterText(find.byType(TextField), 'LM-EP01-PALACE');
    await tapText(t, 'CHECK CODE', after: Duration.zero);
    await finishMission(t, sceneLine: 'The guard opens a secret door.');
    expect(find.text('5 / 5'), findsOneWidget);

    // Progress is persisted after every step.
    final prefs = appRef.read(sharedPreferencesProvider);
    expect(prefs.getString(AppConstants.progressStorageKey), contains('"m05"'));

    // Notebook: evidence can be zoomed; the Crown Symbol shows the lock order.
    await tapText(t, 'NOTES', after: const Duration(milliseconds: 1000));
    await tapText(t, 'EVIDENCE', after: const Duration(milliseconds: 600));
    await tapText(t, 'Crown Symbol', after: const Duration(milliseconds: 800));
    expect(find.textContaining('Four pictures for four locks'), findsOneWidget);
    await tapText(t, 'CLOSE', after: const Duration(milliseconds: 600));
    await tapText(t, 'BADGES', after: const Duration(milliseconds: 600));
    expect(find.text('London Explorer'), findsOneWidget);
    await t.tap(find.byTooltip('Close'));
    await wait(t);

    // ── Final case: picture locks clock-train-park-museum → 7 9 2 4.
    await tapText(t, 'OPEN THE FINAL CASE', after: const Duration(milliseconds: 1500));
    expect(find.text('THE ROYAL ARCHIVE'), findsOneWidget);
    for (final (i, digit) in [7, 9, 2, 4].indexed) {
      final up = find.byTooltip('Lock ${i + 1} up');
      await reveal(t, up);
      for (var n = 0; n < digit; n++) {
        await t.tap(up);
        await t.pump(const Duration(milliseconds: 20));
      }
    }
    await wait(t, const Duration(milliseconds: 300));
    await tapText(t, 'OPEN THE BOX', after: const Duration(milliseconds: 3500));
    expect(find.text('🎉 CASE SOLVED'), findsOneWidget);
    expect(find.text('Brilliant work, Detective MINYOUNG!'), findsOneWidget);
    expect(audio.played, contains(GameSound.finale));

    // Result: the case file, then the parent report.
    await tapText(t, 'SEE MY CASE REPORT', after: const Duration(milliseconds: 3200));
    expect(find.text('CASE CLOSED'), findsOneWidget);
    expect(find.text('MINYOUNG'), findsOneWidget);
    expect(find.text('THE MISSING CROWN'), findsOneWidget);
    expect(find.text('MASTER DETECTIVE'), findsOneWidget);
    await reveal(t, find.text('Evidence'));
    expect(find.text('6 / 6'), findsOneWidget);
    expect(find.text('5 / 5'), findsOneWidget); // clues
    expect(find.text('3'), findsOneWidget); // hints: 1 + 2
    // The parent report asks a grown-up first.
    await tapText(t, 'VIEW MY DETECTIVE REPORT', after: const Duration(milliseconds: 600));
    expect(find.text('For grown-ups'), findsOneWidget);
    await t.enterText(find.byType(TextField), gateAnswer(t));
    await tapText(t, 'OK', after: const Duration(milliseconds: 1200));
    expect(find.text('Episode 01 Result'), findsOneWidget);
    await reveal(t, find.text('Words Checked'));
    expect(find.text('Words Checked'), findsOneWidget);
    await wait(t, const Duration(seconds: 3));
  });
}
