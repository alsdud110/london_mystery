import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:world_mystery/app.dart';
import 'package:world_mystery/core/router/app_router.dart';
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/models/profile.dart';
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/features/game/game_providers.dart';

import '../test/helpers.dart' show testOverrides;
import '../test/sandbox/generated/s9_sandbox/s9_ep01.g.dart';
import '../test/sandbox/sandbox_season.dart';

/// The sandbox case (STEP 3-8, generated from its plans) played on a device
/// or emulator as a child would, the screen captured at each step by the app
/// itself (`takeScreenshot`), written on the host by
/// `test_driver/sandbox_qa_driver.dart` under `qa/screenshots/sandbox/`.
///
/// The game runs on in-memory storage only (`testOverrides`): nothing the
/// device keeps is read, changed or cleared.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  final game = Episode.fromJson(s9Ep01Json);
  final [m1, m2, m3, fin] = game.allMissions;

  testWidgets('The Lost Library Key, played and captured', (t) async {
    registerSandboxPlaces();
    addTearDown(SeasonCatalog.testPlaces.clear);
    final c = ProviderContainer(overrides: [...await testOverrides(), ...sandboxOverrides()]);
    addTearDown(c.dispose);
    final ctrl = c.read(gameControllerProvider.notifier);
    ctrl.createDetective('Minyoung', DetectiveAvatar.girl);
    c.read(seasonPreviewSwitchProvider.notifier).set(true);
    expect(ctrl.openSeason(sandboxSeasonId), isTrue);
    expect(ctrl.openEpisode('s9_ep01'), isTrue);
    await t.pumpWidget(UncontrolledProviderScope(container: c, child: const WorldMysteryApp()));

    Future<void> pause(int ms) async {
      await Future<void>.delayed(Duration(milliseconds: ms));
      await t.pump();
    }

    await pause(1500);
    await binding.convertFlutterSurfaceToImage();
    await pause(300);
    final size = t.view.physicalSize / t.view.devicePixelRatio;
    final tag = '${size.width.round()}x${size.height.round()}';

    /// A screen, held still, taken by the app.
    Future<void> shot(String name) async {
      await pause(400);
      await binding.takeScreenshot('$tag/$name');
      await pause(150);
    }

    Future<void> reveal(Finder f) async {
      if (f.evaluate().isEmpty) await t.scrollUntilVisible(f, 250, scrollable: find.byType(Scrollable).first);
      await Scrollable.ensureVisible(t.element(f.last), alignment: 0.5);
      await pause(250);
    }

    Future<void> tapF(Finder f, {int after = 600}) async {
      await reveal(f);
      await t.tap(f.last);
      await pause(after);
    }

    Future<void> tapText(String text, {int after = 600}) => tapF(find.text(text), after: after);

    Future<void> until(Finder f, {int limitMs = 20000}) async {
      for (var waited = 0; waited < limitMs && f.evaluate().isEmpty; waited += 100) {
        await pause(100);
      }
      expect(f, findsWidgets);
    }

    Future<void> toPuzzle(Mission m) async {
      await until(find.bySemanticsLabel('GO TO ${m.location}'));
      await t.tap(find.bySemanticsLabel('GO TO ${m.location}'));
      await pause(3000);
      await tapText('INVESTIGATE', after: 900);
      await tapText('TAP TO OPEN', after: 2000);
      await tapText('SOLVE THE PUZZLE', after: 1200);
      await until(find.text(m.question));
    }

    Future<void> onToMap() async {
      await until(find.text('CONTINUE INVESTIGATION'), limitMs: 8000);
      await pause(600);
      await tapText('CONTINUE INVESTIGATION', after: 1200);
      await t.tapAt(Offset(size.width / 2, size.height / 2));
      await pause(1200);
      await tapText('TO THE MAP', after: 4000);
    }

    // ── Story Intro.
    c.read(routerProvider).go(Routes.intro);
    await pause(1500);
    await tapText('SKIP ›', after: 1200);
    await shot('01_story_intro');
    await tapText("I'M READY", after: 2500);

    // ── Mission 1: a wrong option first (its line), then the answer.
    await toPuzzle(m1);
    await shot('02_m1_puzzle');
    await tapText('On the front desk', after: 300);
    await tapText('CHECK ANSWER', after: 1200);
    await shot('02b_m1_wrong_answer');
    await tapText('GET MORE HINTS', after: 1200);
    await shot('02c_m1_hint');
    await tapText('On the blue shelf by the window', after: 300);
    await tapText('CHECK ANSWER', after: 3000);
    await shot('02d_m1_solved');
    await onToMap();

    // ── The map: Mission 2 at Mission 1's pin (the same desk), both shown.
    await until(find.bySemanticsLabel('GO TO ${m2.location}'));
    expect(t.takeException(), isNull, reason: 'the map paints with two missions at one point');
    await shot('02e_map_same_pin');

    // ── Mission 2: the visitors in order.
    await toPuzzle(m2);
    for (final id in Mission.sequenceIds(m2.answer)) {
      await tapF(find.text(m2.options.firstWhere((o) => o.id == id).label), after: 300);
    }
    await shot('03_m2_puzzle');
    await tapText('CHECK ANSWER', after: 3000);
    await onToMap();

    // ── Mission 3: the word.
    await toPuzzle(m3);
    await t.enterText(find.byType(TextField), 'LAMP');
    await pause(500);
    await shot('04_m3_puzzle');
    await tapText('CHECK ANSWER', after: 3000);
    await onToMap();

    // ── The final: B, E, L, L in the lock.
    await until(find.text('OPEN THE FINAL CASE'));
    await tapText('OPEN THE FINAL CASE', after: 3500);
    await until(find.text(fin.question));
    for (final letter in fin.answer.split('')) {
      await tapF(find.bySemanticsLabel('Letter $letter').first, after: 300);
    }
    expect(find.text('THE LIBRARY LOCK'), findsOneWidget);
    await shot('05_final_lock');
    await tapText('OPEN THE LOCK', after: 4000);
    await until(find.text('CASE SOLVED'));
    await shot('06_case_solved');

    // ── After the case, then the Case Solved report.
    await tapText('CONTINUE INVESTIGATION', after: 1500);
    await t.tapAt(Offset(size.width / 2, size.height / 2));
    await pause(1500);
    await shot('06b_after_the_case');
    await tapText('SEE MY CASE REPORT', after: 4000);
    await until(find.text('CASE CLOSED'));
    await shot('07_case_report');
    expect(c.read(gameControllerProvider).completedMissionIds, [for (final m in game.allMissions) m.id]);
  });
}
