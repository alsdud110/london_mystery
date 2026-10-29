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
import '../test/sandbox/sandbox_season.dart';

/// The sandbox season's two generated cases (STEP 3-9) played one after the
/// other on a device or emulator as a child would: Case 02 sealed, Case 01
/// solved, Case 02 opened from its report and solved. The screen is
/// captured at each step by the app itself (`takeScreenshot`), written on
/// the host by `test_driver/sandbox_qa_driver.dart` under
/// `qa/screenshots/sandbox/multi_case/`.
///
///   flutter drive --driver=test_driver/sandbox_qa_driver.dart \
///     --target=integration_test/sandbox_multi_case_qa_test.dart -d DEVICE
///
/// The game runs on in-memory storage only (`testOverrides`): nothing the
/// device keeps is read, changed or cleared.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('Case 01 then Case 02 of the sandbox season, played and captured', (t) async {
    registerSandboxPlaces();
    addTearDown(SeasonCatalog.testPlaces.clear);
    final c = ProviderContainer(overrides: [...await testOverrides(), ...sandboxOverrides()]);
    addTearDown(c.dispose);
    final ctrl = c.read(gameControllerProvider.notifier);
    ctrl.createDetective('Minyoung', DetectiveAvatar.girl);
    c.read(seasonPreviewSwitchProvider.notifier).set(true);
    expect(ctrl.openSeason(sandboxSeasonId), isTrue);
    final [case01, case02, ...] = sandboxEpisodes();
    expect(ctrl.openEpisode(case02.id), isFalse, reason: 'Case 02 is sealed');
    await t.pumpWidget(UncontrolledProviderScope(container: c, child: const WorldMysteryApp()));

    Future<void> pause(int ms) async {
      await Future<void>.delayed(Duration(milliseconds: ms));
      await t.pump();
    }

    await pause(1500);
    await binding.convertFlutterSurfaceToImage();
    await pause(300);
    final size = t.view.physicalSize / t.view.devicePixelRatio;
    final tag = 'multi_case/${size.width.round()}x${size.height.round()}';

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

    /// [m]'s answer put in with its puzzle's own controls (not yet checked).
    Future<void> enter(Mission m, String answer) async {
      switch (m.type) {
        case MissionType.multipleChoice:
          await tapText(m.options.firstWhere((o) => o.id == answer).label, after: 300);
        case MissionType.sequence:
          for (final id in Mission.sequenceIds(answer)) {
            await tapF(find.text(m.options.firstWhere((o) => o.id == id).label), after: 300);
          }
        case MissionType.wordInput:
          await t.enterText(find.byType(TextField), answer);
          await pause(500);
        case MissionType.letterLock:
          for (final letter in answer.split('')) {
            await tapF(find.bySemanticsLabel('Letter $letter').first, after: 300);
          }
        case MissionType.finalCode:
          for (final (i, d) in answer.split('').map(int.parse).indexed) {
            final up = find.byTooltip('Lock ${i + 1} up');
            await reveal(up);
            for (var n = 0; n < d; n++) {
              await t.tap(up);
              await pause(120);
            }
          }
        default:
          fail('${m.type} is not a puzzle the generator makes');
      }
    }

    String check(Mission m) => switch (m.type) {
      MissionType.letterLock => 'OPEN THE LOCK',
      MissionType.finalCode => 'UNLOCK',
      _ => 'CHECK ANSWER',
    };

    /// [episode] from its Story Intro to its Case Solved report; [shots]
    /// names its screens (`02_c1`), [wrong] a mission's wrong try first.
    Future<void> playCase(Episode episode, String prefix, {Map<String, String> wrong = const {}}) async {
      await until(find.text('SKIP ›'));
      await tapText('SKIP ›', after: 1200);
      await shot('${prefix}_01_story_intro');
      await tapText("I'M READY", after: 2500);
      for (final (i, m) in episode.missions.indexed) {
        await toPuzzle(m);
        if (wrong[m.id] case final w?) {
          await enter(m, w);
          await tapText(check(m), after: 1500);
          await shot('${prefix}_0${i + 2}a_m${i + 1}_wrong');
          await tapText('TRY AGAIN', after: 800);
          if (m.type == MissionType.sequence) await tapText('Start again', after: 400);
        }
        await enter(m, m.answer);
        await shot('${prefix}_0${i + 2}_m${i + 1}_puzzle');
        await tapText(check(m), after: 3000);
        await onToMap();
      }
      final fin = episode.finalMission;
      await until(find.text('OPEN THE FINAL CASE'));
      await tapText('OPEN THE FINAL CASE', after: 3500);
      await until(find.text(fin.question));
      await enter(fin, fin.answer);
      await shot('${prefix}_05_final');
      await tapText(check(fin), after: 4000);
      await until(find.text('CASE SOLVED'));
      await shot('${prefix}_06_case_solved');
      await tapText('CONTINUE INVESTIGATION', after: 1500);
      await t.tapAt(Offset(size.width / 2, size.height / 2));
      await pause(1500);
      await tapText('SEE MY CASE REPORT', after: 4000);
      await until(find.text('CASE CLOSED'));
      await shot('${prefix}_07_case_report');
    }

    // ── Case 02 sealed in the case files.
    c.read(routerProvider).go(Routes.episodes);
    await until(find.bySemanticsLabel('Case 2, ${case02.title}, sealed'));
    await shot('00_case_files_case02_sealed');

    // ── Case 01.
    expect(ctrl.openEpisode(case01.id), isTrue);
    c.read(routerProvider).go(Routes.intro);
    await playCase(case01, 'c1');
    expect(c.read(seasonProvider).solvedEpisodeIds, [case01.id]);

    // ── Case 02 unlocked: OPEN CASE 02 → the board → BEGIN INVESTIGATION.
    await tapText('OPEN CASE 02', after: 4500);
    await until(find.bySemanticsLabel('Case 02, ${case02.title}, current case'));
    await shot('c2_00_board_case02_unlocked');
    await tapText('BEGIN INVESTIGATION', after: 2000);
    expect(c.read(currentEpisodeProvider).id, case02.id);

    // ── Case 02, its first mission tried wrong first.
    await playCase(case02, 'c2', wrong: {case02.missions.first.id: 'lamp,book,shelf'});
    expect(c.read(seasonProvider).solvedEpisodeIds, [case01.id, case02.id]);
    expect(c.read(gameControllerProvider).completedMissionIds, [for (final m in case02.allMissions) m.id]);
  });
}
