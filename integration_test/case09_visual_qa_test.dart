import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:world_mystery/app.dart';
import 'package:world_mystery/core/constants/app_constants.dart';
import 'package:world_mystery/core/router/app_router.dart';
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/abbesses_puzzles.dart' show TornHourScene;
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/game_progress.dart';
import 'package:world_mystery/data/models/garden_puzzles.dart';
import 'package:world_mystery/data/models/season.dart';
import 'package:world_mystery/data/models/season_progress.dart';
import 'package:world_mystery/data/repositories/episode_repository.dart';
import 'package:world_mystery/features/game/game_controller.dart';

import '../test/helpers.dart' show testOverrides;

/// Case 09's visual QA on a device or emulator: the case played through as
/// a child would, the screen captured at each step (and frame by frame
/// where something moves), written on the host by
/// `test_driver/case09_qa_driver.dart` under `qa/screenshots/case09/`.
///
/// The game runs on in-memory storage only (`testOverrides`): nothing the
/// device keeps is read, changed or cleared.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  final inGame = MockEpisodeRepository.bundled();
  final s1 = [for (final e in inGame) if (e.seasonId == AppConstants.firstSeasonId) e];
  final paris = [for (final id in ['s2_ep01', 's2_ep02', 's2_ep03', 's2_ep04', 's2_ep05', 's2_ep06', 's2_ep07', 's2_ep08']) inGame.firstWhere((e) => e.id == id)];
  final case09 = inGame.firstWhere((e) => e.id == 's2_ep09');
  final [m1, m2, m3, fin] = case09.allMissions;
  final trial = SeasonCatalog.trialMap(m1)!;
  final gears = SeasonCatalog.gearBoard(m2)!;

  testWidgets('Case 09, played and captured', (t) async {
    GameProgress solved(Episode e) => GameProgress(
          detectiveName: 'MINYOUNG',
          introSeen: true,
          completedMissionIds: [for (final m in e.allMissions) m.id],
          startedAt: DateTime(2026, 10, 20, 10),
          completedAt: DateTime(2026, 10, 20, 10, 30),
          playMillis: 0,
        );
    late WidgetRef ref;
    await t.pumpWidget(ProviderScope(
      overrides: [
        ...await testOverrides(prefs: {
          AppConstants.progressStorageKey: jsonEncode(solved(s1.first).toJson()),
          for (final e in s1.skip(1)) AppConstants.progressKeyFor(e.id): jsonEncode(solved(e).toJson()),
          AppConstants.seasonStorageKey: jsonEncode(SeasonProgress(activeEpisodeId: 'ep12', solvedEpisodeIds: [for (final e in s1) e.id]).toJson()),
        }),
      ],
      child: Consumer(builder: (context, r, _) {
        ref = r;
        return const WorldMysteryApp();
      }),
    ));

    Future<void> pause(int ms) async {
      await Future<void>.delayed(Duration(milliseconds: ms));
      await t.pump();
    }

    await pause(1500);
    final size = t.view.physicalSize / t.view.devicePixelRatio;
    // Where this run's pictures go (`--dart-define=QA_SET=final_polish`
    // keeps a pass apart from the ones before it).
    const set = String.fromEnvironment('QA_SET');
    final tag = '${set.isEmpty ? '' : '$set/'}${size.width.round()}x${size.height.round()}';

    /// A screen: the host takes the device's own screenshot
    /// (`qa/tools/screencap_watcher.py`) while the screen is held still. A
    /// frame of something moving: taken in the app, at once.
    Future<void> shot(String name) async {
      await t.pump();
      debugPrint('QA_SHOT $tag/$name');
      await pause(4500);
    }

    /// A screen recording of the next [seconds] (the host pulls it after
    /// the run); a moment for it to start.
    Future<void> rec(String name, int seconds) async {
      debugPrint('QA_REC $tag/video/$name $seconds');
      await pause(1500);
    }


    Future<void> reveal(Finder f) async {
      if (f.evaluate().isEmpty) {
        await t.scrollUntilVisible(f, 250, scrollable: find.byType(Scrollable).first);
      }
      await Scrollable.ensureVisible(t.element(f.last), alignment: 0.5);
      await pause(250);
    }

    Future<void> tapF(Finder f, {int after = 500}) async {
      await reveal(f);
      await t.tap(f.last);
      await pause(after);
    }

    Future<void> tapText(String text, {int after = 600}) => tapF(find.text(text), after: after);
    Future<void> tapKey(String key, {int after = 500}) => tapF(find.byKey(ValueKey(key)), after: after);

    Offset onPicture(String key, Offset px) {
      final r = t.getRect(find.byKey(ValueKey(key)));
      return Offset(r.left + px.dx / 1536 * r.width, r.top + px.dy / 1024 * r.height);
    }

    bool inView(String key) {
      final r = t.getRect(find.byKey(ValueKey(key)));
      return r.top >= 0 && r.bottom <= size.height;
    }

    /// [thing] dragged by a finger to [to], slowly; [midway] is called with
    /// the finger halfway (to capture the drag).
    Future<void> drag(String thing, Offset Function() to, {Future<void> Function()? midway}) async {
      final from = t.getCenter(find.byKey(ValueKey(thing)));
      final g = await t.startGesture(from);
      await pause(80);
      final end = to();
      for (var i = 1; i <= 12; i++) {
        await g.moveTo(Offset.lerp(from, end, i / 12)!);
        await pause(30);
        if (i == 7 && midway != null) await midway();
      }
      await g.up();
      await pause(700);
    }

    Future<void> until(Finder f, {int limitMs = 40000}) async {
      for (var waited = 0; waited < limitMs && f.evaluate().isEmpty; waited += 100) {
        await pause(100);
      }
    }

    /// A mission solved: its Discovery Moment, the story after it, the map.
    Future<void> onToTheMap() async {
      await until(find.text('CONTINUE INVESTIGATION'));
      await tapText('CONTINUE INVESTIGATION', after: 1200);
      await t.tapAt(Offset(size.width / 2, size.height / 2));
      await pause(1200);
      await tapText('TO THE MAP', after: 3500);
    }

    // ── Cases 01–08 closed (in memory) ─────────────────────────────────
    final game = ref.read(gameControllerProvider.notifier);
    expect(game.openSeason(SeasonIds.paris), isTrue);
    for (final e in paris) {
      expect(game.openEpisode(e.id), isTrue);
      game.startInvestigation();
      for (final m in e.allMissions) {
        game.submitAnswer(m, m.answer);
      }
      if (e.id == 's2_ep08') game.closeCase(GameProgress.examinedKey(e.finalMission.id, TornHourScene.leadId));
    }
    expect(game.openEpisode('s2_ep09'), isTrue);
    final router = ref.read(routerProvider);

    // ── Intro: the pencil drawing, then the garden (recorded) ──────────
    // Recorded from before the page opens until the garden (line 4).
    await rec('intro', 20);
    router.go(Routes.intro);
    final picture = find.byKey(const ValueKey('intro-picture'));
    // The lines type themselves and go on alone: no tap, so nothing is
    // skipped. The drawing is there from the first line.
    await until(find.byKey(const ValueKey('intro-0')));
    await shot('00_intro_first_line');
    await reveal(picture);
    await shot('01_intro_pencil');
    // Line 4 starts: the drawing turns into the garden.
    await until(find.textContaining('You walk into'));
    await pause(400);
    await reveal(picture);
    await shot('02_intro_garden');
    await tapText('SKIP ›', after: 1200);
    await tapText("I'M READY", after: 2000);

    // ── M1 ─────────────────────────────────────────────────────────────
    router.go(Routes.mission(m1.id));
    await pause(1600);
    await tapText('INVESTIGATE', after: 1200);
    await reveal(find.byKey(const ValueKey('trial-map')));
    await shot('03_m1_initial');
    Offset spot(String id) {
      final s = trial.spots.firstWhere((s) => s.id == id);
      return Offset(s.at.dx * 1536, s.at.dy * 1024);
    }

    Future<void> lay(String model, String place, {Future<void> Function()? midway}) async {
      final key = 'trial-model-$model';
      await reveal(find.byKey(ValueKey(key)));
      if (inView(key) && inView('trial-map')) {
        await drag(key, () => onPicture('trial-map', spot(place)) + const Offset(0, 10), midway: midway);
      } else {
        await tapKey(key, after: 300);
        await reveal(find.byKey(const ValueKey('trial-map')));
        await t.tapAt(onPicture('trial-map', spot(place)));
        await pause(700);
      }
    }

    await lay('t1', 'palaisGarnier', midway: () => shot('04_m1_dragging'));
    await shot('04b_m1_wrong');
    await lay('t1', 'arcDeTriomphe');
    await lay('t2', 'seineQuays');
    // T3 by taps (the other way to play it).
    await tapKey('trial-model-t3', after: 400);
    await shot('04c_m1_tap_picked');
    await reveal(find.byKey(const ValueKey('trial-map')));
    await t.tapAt(onPicture('trial-map', spot('artsEtMetiers')));
    await pause(400);
    await shot('05_m1_completed');
    await pause(3200);
    await shot('05b_m1_discovery');
    await onToTheMap();

    // ── M2 ─────────────────────────────────────────────────────────────
    router.go(Routes.mission(m2.id));
    await pause(1600);
    await tapText('INVESTIGATE', after: 1200);
    await reveal(find.byKey(const ValueKey('gear-board')));
    await shot('06_m2_initial');
    Future<void> fit(GearSize g, String slot, {Future<void> Function()? midway}) async {
      final at = gears.slots.firstWhere((s) => s.id == slot).at;
      await reveal(find.byKey(const ValueKey('gear-board')));
      final r = t.getRect(find.byKey(const ValueKey('gear-board')));
      final s = r.width / gears.view.width;
      await drag('gear-tray-${g.name}', () => r.topLeft + (at - gears.view.topLeft) * s + Offset(0, gears.radii[g]! * s + 14), midway: midway);
    }

    await fit(GearSize.big, 'slot1', midway: () => shot('07_m2_gear_placed'));
    await shot('07b_m2_one_in');
    await fit(GearSize.small, 'slot1');
    await shot('07c_m2_too_small');
    await rec('gears', 8);
    await fit(GearSize.small, 'slot2');
    await shot('08_m2_completed');
    await pause(1500);
    await onToTheMap();

    // ── M3 ─────────────────────────────────────────────────────────────
    router.go(Routes.mission(m3.id));
    await pause(1600);
    await tapText('INVESTIGATE', after: 1200);
    await reveal(find.byKey(const ValueKey('marks-plan')));
    await shot('09_m3_initial');
    await tapKey('marks-card-b', after: 400);
    await reveal(find.byKey(const ValueKey('marks-paper-key')));
    await shot('10_m3_matching');
    await tapKey('marks-paper-key', after: 500);
    await shot('10b_m3_key_wrong');
    await tapKey('marks-paper-repair', after: 500);
    await tapKey('marks-card-a', after: 300);
    await tapKey('marks-paper-emblem', after: 300);
    await shot('11_m3_completed');
    await pause(1500);
    await onToTheMap();

    // ── Final ──────────────────────────────────────────────────────────
    await rec('hands', 8);
    router.go(Routes.finalMission);
    await pause(400);
    final dial = find.byKey(const ValueKey('tower-dial'));
    for (var i = 0; i < 20 && dial.evaluate().isEmpty; i++) {
      await pause(100);
    }
    await reveal(dial);
    await reveal(find.byKey(const ValueKey('tower-test')));
    await shot('12_final_initial');
    await tapKey('tower-back', after: 700);
    await shot('13_final_adjusted');
    await rec('test', 7);
    await tapKey('tower-test', after: 200);
    await reveal(find.byKey(const ValueKey('test-clock-garden')));
    await shot('14_final_test');
    await tapText('Every clock in Paris went wrong.', after: 300);
    await tapText('CHECK ANSWER', after: 1600);
    await shot('14b_final_wrong');
    await tapText('TRY AGAIN', after: 800);
    await tapText('Only the joined clocks went wrong.', after: 300);
    await tapText('CHECK ANSWER', after: 3800);
    await reveal(find.byKey(const ValueKey('final-follow-star')));
    await shot('15_final_answer');

    // ── The star, the case closed ──────────────────────────────────────
    await tapKey('final-follow-star', after: 900);
    await shot('17a_star_question');
    await tapKey('star-model-t2', after: 500);
    await shot('17b_star_wrong');
    await tapKey('star-model-t1', after: 1300);
    await shot('17_follow_star');
    await tapKey('star-done', after: 1500);
    await shot('16_case_closed');
    await tapText('CONTINUE INVESTIGATION', after: 1200);
    await t.tapAt(Offset(size.width / 2, size.height / 2));
    await pause(1500);
    await shot('16b_final_scene');
    await tapText('SEE MY CASE REPORT', after: 4500);
    await reveal(find.byKey(const ValueKey('next-case-coming-soon')));
    await shot('18_case10_coming_soon');
    expect(ref.read(gameControllerProvider).isCaseSolved, isTrue);
    debugPrint('QA_DONE');
  });
}
