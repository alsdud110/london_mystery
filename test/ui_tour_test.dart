import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/core/utils/audio_service.dart';
import 'package:london_mystery/features/game/game_providers.dart' show sharedPreferencesProvider;

import 'helpers.dart';
import 'parent_gate_test.dart' show gateAnswer;
import 'full_playthrough_test.dart' show wait, reveal, goToTime;

// Visual review tour: LM_TOUR=<folder> flutter test test/ui_tour_test.dart
final _dir = Platform.environment['LM_TOUR'];
var _n = 0;
late WidgetTester _t;
Future<void> shot(String name) async {
  final dir = _dir;
  if (dir == null) return;
  await _t.runAsync(() async {
    final b = _t.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('shot')));
    final img = await b.toImage(pixelRatio: 1.0);
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    Directory(dir).createSync(recursive: true);
    File('$dir/${(_n++).toString().padLeft(2, '0')}_$name.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
}

Future<void> tapText(WidgetTester t, String text, {Duration after = const Duration(milliseconds: 800)}) async {
  await reveal(t, find.text(text));
  await t.tap(find.text(text).last);
  await wait(t, after);
}

Future<void> openMission(WidgetTester t, String goLabel) async {
  await t.tap(find.bySemanticsLabel(goLabel));
  await wait(t, goToTime);
  await shot('mission_story');
  await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 700));
  await shot('mission_envelope');
  await tapText(t, 'TAP TO OPEN', after: const Duration(milliseconds: 1800));
  await shot('mission_letter');
  await tapText(t, 'SOLVE THE PUZZLE', after: const Duration(milliseconds: 900));
  await shot('mission_puzzle');
}

Future<void> finishMission(WidgetTester t, {required String sceneLine}) async {
  await wait(t, const Duration(milliseconds: 2800));
  await shot('success');
  await tapText(t, 'CONTINUE', after: const Duration(milliseconds: 900));
  await t.tapAt(const Offset(200, 400));
  await wait(t, const Duration(milliseconds: 900));
  await shot('story_scene');
  await tapText(t, 'TO THE MAP', after: const Duration(milliseconds: 1200));
  await wait(t, const Duration(milliseconds: 3200));
  await shot('map');
}

void main() {
  testWidgets('ui tour', (t) async {
    WidgetController.hitTestWarningShouldBeFatal = true; // every tap must land
    addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);
    _t = t;
    // LM_TOUR_SMALL=1: the smallest supported phone (360×640) instead of 390×844.
    final small = Platform.environment['LM_TOUR_SMALL'] != null;
    t.view.physicalSize = small ? const Size(1080, 1920) : const Size(1170, 2532);
    for (final (family, files) in [('Nunito', ['Nunito.ttf']), ('Cinzel', ['Cinzel.ttf']), ('LibreBaskerville', ['LibreBaskerville.ttf', 'LibreBaskerville-Italic.ttf']), ('Fredoka', ['Fredoka.ttf'])]) {
      final l = FontLoader(family);
      for (final f in files) {
        l.addFont(rootBundle.load('assets/fonts/$f'));
      }
      await l.load();
    }
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);

    final audio = MockAudioService();
    final overrides = await testOverrides(audio: audio);
    late WidgetRef appRef;
    await t.pumpWidget(ProviderScope(
      overrides: overrides,
      child: RepaintBoundary(
        key: const ValueKey('shot'),
        child: Consumer(builder: (context, ref, _) {
          appRef = ref;
          return const LondonMysteryApp();
        }),
      ),
    ));
    await wait(t);

    // START → register.
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await t.pump();
    await shot('start');
    await tapText(t, 'START ADVENTURE');
    await t.enterText(find.byType(TextField), 'minyoung');
    await shot('register');
    await tapText(t, 'OPEN THE CASEBOOK');
    // The season's casebook, then (as a tour of the case files) Case 01 from there.
    await wait(t, const Duration(milliseconds: 1600));
    expect(find.text('BEGIN SEASON ONE'), findsOneWidget);
    await shot('season_cover');
    appRef.read(routerProvider).go(Routes.episodes);
    await wait(t);
    await shot('episodes');

    // Case files: only the cases at first; open one, choose its episode, begin.
    expect(find.text('THE MISSING CROWN'), findsOneWidget);
    expect(find.text('The Missing Crown'), findsNothing, reason: 'episodes stay folded away');
    await tapText(t, 'BEGIN INVESTIGATION', after: const Duration(milliseconds: 400));
    expect(find.text('CASE FILES'), findsOneWidget, reason: 'nothing chosen yet');
    await tapText(t, 'THE MISSING CROWN', after: const Duration(milliseconds: 400));
    await tapText(t, 'The Missing Crown', after: const Duration(milliseconds: 400));
    await shot('episodes_open');
    await tapText(t, 'BEGIN INVESTIGATION');
    await wait(t, const Duration(seconds: 3));
    await shot('intro');
    await tapText(t, 'SKIP ›');
    await shot('intro_ready');
    await tapText(t, "I'M READY", after: const Duration(milliseconds: 1500));

    // Map: one way forward; the case status lives in the menu.
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await t.pump();
    await shot('map');
    expect(find.text("YOU'RE HERE"), findsOneWidget, reason: 'only the current place is marked');
    expect(find.text('BRITISH MUSEUM'), findsNothing, reason: 'locked places stay a mystery');
    await t.tap(find.byTooltip('Menu'));
    await wait(t);
    await shot('map_menu');
    await t.tapAt(const Offset(20, 20)); // close the menu
    await wait(t);
    // Android back on the map asks first (the game dialog).
    await t.binding.handlePopRoute();
    await wait(t, const Duration(milliseconds: 600));
    await shot('map_leave_dialog');
    await tapText(t, 'Keep investigating', after: const Duration(milliseconds: 600));
    // Where the next place is would give away the answer of this one.
    expect(find.byKey(const ValueKey('pin-m02')), findsNothing, reason: 'locked places stay off the map');
    expect(find.text("King's Cross"), findsNothing, reason: 'the current pin names its own landmark');
    expect(find.text('British Museum'), findsOneWidget, reason: 'the map letters its landmarks');

    // ── Mission 01: word card, a wrong answer, a tip, then the answer.
    await openMission(t, "GO TO KING'S CROSS");
    await tapText(t, 'Letter', after: const Duration(milliseconds: 600)); // re-read the letter
    await t.tapOnText(find.textRange.ofSubstring('museum').first);
    await wait(t, const Duration(milliseconds: 600));
    await shot('word_card');
    await tapText(t, 'GOT IT!', after: const Duration(milliseconds: 500));
    await tapText(t, 'BACK TO THE PUZZLE', after: const Duration(milliseconds: 500));

    await tapText(t, 'Hyde Park', after: const Duration(milliseconds: 200));
    await shot('choice_selected');
    await tapText(t, 'CHECK ANSWER');
    await shot('try_again');
    expect(audio.played, contains(GameSound.wrong));
    await tapText(t, 'GET A TIP');
    await shot('tip');
    await tapText(t, 'The British Museum', after: const Duration(milliseconds: 200));
    await tapText(t, 'CHECK ANSWER', after: Duration.zero);
    await wait(t, const Duration(milliseconds: 2800));
    await shot('success_badge');
    expect(find.textContaining('First Clue'), findsOneWidget);
    await tapText(t, 'CONTINUE', after: const Duration(milliseconds: 900));
    expect(find.text('The letter suddenly begins to glow...'), findsOneWidget);
    await t.tapAt(const Offset(200, 400));
    await wait(t, const Duration(milliseconds: 900));
    await shot('story_scene_unlock');
    await tapText(t, 'TO THE MAP', after: const Duration(milliseconds: 1400));
    await shot('map_unlock');
    await wait(t, const Duration(milliseconds: 3000));
    expect(audio.played, contains(GameSound.unlock));
    expect(find.descendant(of: find.byKey(const ValueKey('pin-m02')), matching: find.text('BRITISH MUSEUM')), findsOneWidget, reason: 'the new place is named on the map');

    // ── Mission 02: word input, using both tips.
    await openMission(t, 'GO TO BRITISH MUSEUM');
    await tapText(t, 'Get a tip', after: const Duration(milliseconds: 500));
    await tapText(t, 'Get a tip', after: const Duration(milliseconds: 500));
    expect(find.text('DETECTIVE TIP 2'), findsOneWidget);
    expect(find.text('Get a tip'), findsNothing, reason: 'at most two tips');
    await reveal(t, find.byType(TextField));
    await t.enterText(find.byType(TextField), 'stone');
    await tapText(t, 'CHECK ANSWER', after: Duration.zero);
    await finishMission(t, sceneLine: 'The old stone shines in the dark.');

    // ── Mission 03: number code keypad.
    await openMission(t, 'GO TO BIG BEN');
    for (final d in ['4', '1', '7']) {
      await tapText(t, d, after: const Duration(milliseconds: 150));
    }
    await tapText(t, 'UNLOCK', after: Duration.zero);
    await finishMission(t, sceneLine: 'Inside the box, there is a photo.');

    // ── Mission 04: image choice (picture C = Buckingham Palace).
    await openMission(t, 'GO TO HYDE PARK');
    final pictureC = find.bySemanticsLabel('Picture C');
    await reveal(t, pictureC);
    await t.tap(pictureC);
    await wait(t, const Duration(milliseconds: 300));
    await shot('image_selected');
    await tapText(t, 'CHECK ANSWER', after: Duration.zero);
    await finishMission(t, sceneLine: 'The swans fly up into the sky.');

    // ── Mission 05: QR (typed fallback, as on a device without a camera).
    await openMission(t, 'GO TO BUCKINGHAM PALACE');
    await tapText(t, "Can't scan? Type the code", after: const Duration(milliseconds: 400));
    await reveal(t, find.byType(TextField));
    await t.enterText(find.byType(TextField), 'LM-EP01-PALACE');
    await tapText(t, 'CHECK CODE', after: Duration.zero);
    await finishMission(t, sceneLine: 'The guard opens a secret door.');
    expect(find.text('OPEN THE FINAL CASE'), findsOneWidget, reason: 'all five places solved');

    // Progress is persisted after every step.
    final prefs = appRef.read(sharedPreferencesProvider);
    expect(prefs.getString(AppConstants.progressStorageKey), contains('"m05"'));

    // Notebook: evidence can be zoomed; the Crown Symbol shows the lock order.
    await t.tap(find.byTooltip('Detective notebook'));
    await wait(t, const Duration(milliseconds: 1000));
    await shot('notebook');
    await tapText(t, 'EVIDENCE', after: const Duration(milliseconds: 600));
    await shot('notebook_evidence');
    await tapText(t, 'Crown Symbol', after: const Duration(milliseconds: 800));
    await shot('evidence_zoom');
    await tapText(t, 'CLOSE', after: const Duration(milliseconds: 600));
    await tapText(t, 'BADGES', after: const Duration(milliseconds: 600));
    await shot('badges');
    await t.tap(find.byTooltip('Close'));
    await wait(t);

    // ── Final case: picture locks clock-train-park-museum → 7 9 2 4.
    await tapText(t, 'OPEN THE FINAL CASE', after: goToTime);
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300)));
    await t.pump();
    await shot('final');
    for (final (i, digit) in [7, 9, 2, 4].indexed) {
      final up = find.byTooltip('Lock ${i + 1} up');
      await reveal(t, up);
      for (var n = 0; n < digit; n++) {
        await t.tap(up);
        await t.pump(const Duration(milliseconds: 20));
      }
    }
    await wait(t, const Duration(milliseconds: 300));
    await shot('final_locks');
    await tapText(t, 'OPEN THE BOX', after: const Duration(milliseconds: 3500));
    await shot('case_solved_box');
    expect(find.text('Brilliant work, Detective MINYOUNG!'), findsOneWidget);
    expect(audio.played, contains(GameSound.finale));

    // The story after the case, then the case file and the parent report.
    await tapText(t, 'CONTINUE', after: const Duration(milliseconds: 1000));
    expect(find.text('CASE 01 COMPLETE'), findsOneWidget);
    await t.tapAt(t.getCenter(find.byType(Scaffold).last));
    await wait(t, const Duration(milliseconds: 1200));
    await shot('post_case');
    await tapText(t, 'SEE MY CASE REPORT', after: const Duration(milliseconds: 3200));
    await shot('case_closed');
    expect(find.text('MINYOUNG'), findsOneWidget);
    expect(find.text('THE MISSING CROWN'), findsOneWidget);
    expect(find.text('MASTER DETECTIVE'), findsOneWidget);
    await reveal(t, find.text('Evidence'));
    expect(find.text('6 / 6'), findsOneWidget);
    expect(find.text('5 / 5'), findsOneWidget); // clues
    expect(find.text('3'), findsOneWidget); // hints: 1 + 2
    // The parent report asks a grown-up first.
    await tapText(t, 'VIEW MY DETECTIVE REPORT', after: const Duration(milliseconds: 600));
    await shot('parent_gate');
    await t.enterText(find.byType(TextField), gateAnswer(t));
    await tapText(t, 'OK', after: const Duration(milliseconds: 1200));
    await shot('report');
    await reveal(t, find.text('Words Checked'));
    expect(find.text('Words Checked'), findsOneWidget);

    // Back on the case file: the play-again dialog.
    await t.tap(find.byTooltip('Back'));
    await wait(t, const Duration(milliseconds: 800));
    await tapText(t, 'Play again', after: const Duration(milliseconds: 600));
    await shot('play_again_dialog');
    await tapText(t, 'Cancel', after: const Duration(milliseconds: 600));

    // The case archive (earlier cases) and the operator tools.
    appRef.read(routerProvider).go(Routes.archive);
    await wait(t, const Duration(milliseconds: 1200));
    await shot('archive');
    appRef.read(routerProvider).go(Routes.start);
    await wait(t, const Duration(milliseconds: 1200));
    await shot('start_returning');
    await t.longPress(find.byWidgetPredicate((w) => w is GestureDetector && w.onLongPress != null));
    await wait(t, const Duration(milliseconds: 600));
    await shot('admin_gate');
    await t.enterText(find.byType(TextField), gateAnswer(t));
    await tapText(t, 'OK', after: const Duration(milliseconds: 1200));
    await shot('game_master');
    await wait(t, const Duration(seconds: 3));
  });
}
