import 'dart:convert';
import 'dart:math' as math;

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
import 'package:world_mystery/data/models/garden_puzzles.dart' show TowerTestScene;
import 'package:world_mystery/data/models/season.dart';
import 'package:world_mystery/data/models/season_progress.dart';
import 'package:world_mystery/data/repositories/episode_repository.dart';
import 'package:world_mystery/features/game/game_controller.dart';

import '../test/helpers.dart' show testOverrides;

/// Case 10's visual QA on a device or emulator: the case played through as
/// a child would, the screen captured at each step by the app itself
/// (`takeScreenshot`), written on the host by
/// `test_driver/case10_qa_driver.dart` under `qa/screenshots/case10/`,
/// one folder a screen size (`393x807/03_m1_tape`).
///
/// The game runs on in-memory storage only (`testOverrides`): nothing the
/// device keeps is read, changed or cleared.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  final inGame = MockEpisodeRepository.bundled();
  final s1 = [for (final e in inGame) if (e.seasonId == AppConstants.firstSeasonId) e];
  final paris = [for (final id in ['s2_ep01', 's2_ep02', 's2_ep03', 's2_ep04', 's2_ep05', 's2_ep06', 's2_ep07', 's2_ep08', 's2_ep09']) inGame.firstWhere((e) => e.id == id)];
  final case10 = inGame.firstWhere((e) => e.id == 's2_ep10');
  final [m1, m2, m3, _] = case10.allMissions;
  final city = SeasonCatalog.cityClocks(m2)!;
  final dial = SeasonCatalog.shadowCheck(m3)!.sundial;

  testWidgets('Case 10, played and captured', (t) async {
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
    await binding.convertFlutterSurfaceToImage();
    await pause(300);
    final size = t.view.physicalSize / t.view.devicePixelRatio;
    final tag = '${size.width.round()}x${size.height.round()}';

    /// A screen, held still, taken by the app.
    Future<void> shot(String name) async {
      await pause(350);
      await binding.takeScreenshot('$tag/$name');
      await pause(150);
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

    Future<void> until(Finder f, {int limitMs = 40000}) async {
      for (var waited = 0; waited < limitMs && f.evaluate().isEmpty; waited += 100) {
        await pause(100);
      }
    }

    /// A mission solved: its Discovery Moment, the story after it, the map.
    Future<void> onToTheMap(String name) async {
      await until(find.text('CONTINUE INVESTIGATION'));
      await pause(600);
      await shot('${name}_discovery');
      await tapText('CONTINUE INVESTIGATION', after: 1200);
      await t.tapAt(Offset(size.width / 2, size.height / 2));
      await pause(1200);
      await shot('${name}_scene');
      await tapText('TO THE MAP', after: 3500);
    }

    // ── Cases 01–09 closed (in memory) ─────────────────────────────────
    final game = ref.read(gameControllerProvider.notifier);
    expect(game.openSeason(SeasonIds.paris), isTrue);
    for (final e in paris) {
      expect(game.openEpisode(e.id), isTrue);
      game.startInvestigation();
      for (final m in e.allMissions) {
        game.submitAnswer(m, m.answer);
      }
      if (e.id == 's2_ep08') game.closeCase(GameProgress.examinedKey(e.finalMission.id, TornHourScene.leadId));
      if (e.id == 's2_ep09') game.closeCase(GameProgress.examinedKey(e.finalMission.id, TowerTestScene.leadId));
    }
    final router = ref.read(routerProvider);
    router.go(Routes.solvedSettled);
    await pause(3000);
    await reveal(find.text('OPEN CASE 10'));
    await shot('00_case09_closed_open_case10');
    expect(game.openEpisode('s2_ep10'), isTrue);

    // ── Intro: the arch, T1's star, the room, the plate ────────────────
    router.go(Routes.intro);
    final picture = find.byKey(const ValueKey('intro-picture'));
    await until(find.byKey(const ValueKey('intro-0')));
    await reveal(picture);
    await shot('01_intro_arch');
    await until(find.byKey(const ValueKey('intro-1')));
    await pause(900);
    await shot('02_intro_t1_star');
    await until(find.byKey(const ValueKey('intro-3')));
    await pause(1700);
    await shot('03_intro_door_star');
    await until(find.byKey(const ValueKey('intro-5')));
    await pause(1200);
    await shot('04_intro_plate');
    await tapText('SKIP ›', after: 1200);
    await shot('05_intro_ready');
    await tapText("I'M READY", after: 2000);

    // ── M1: the drum tape ──────────────────────────────────────────────
    router.go(Routes.mission(m1.id));
    await pause(1600);
    await shot('06_m1_place');
    await tapText('INVESTIGATE', after: 1200);
    await reveal(find.byKey(const ValueKey('tape-pull')));
    await shot('07_m1_initial');
    final pull = await t.startGesture(t.getCenter(find.byKey(const ValueKey('tape-pull'))));
    for (var i = 0; i < 8; i++) {
      await pull.moveBy(const Offset(10, 0));
      await pause(30);
    }
    await pull.up();
    await pause(900);
    await shot('08_m1_tape_out');
    await tapKey('tape-mark-t3', after: 400);
    await shot('09_m1_not_a_jump');
    await tapKey('tape-mark-t5', after: 400);
    await shot('10_m1_one_jump');
    await tapKey('tape-mark-t9', after: 300);
    await shot('11_m1_completed');
    await onToTheMap('12_m1');

    // ── M2: a city of clocks ───────────────────────────────────────────
    router.go(Routes.mission(m2.id));
    await pause(1600);
    await tapText('INVESTIGATE', after: 1200);
    await reveal(find.byKey(const ValueKey('city-photo')));
    await shot('13_m2_initial');
    Offset onPhoto(Offset px) {
      final r = t.getRect(find.byKey(const ValueKey('city-photo')));
      return Offset(r.left + px.dx / 1536 * r.width, r.top + px.dy / 1024 * r.height);
    }

    // The glass dragged slowly to the church, held there (captured).
    final church = city.photo.clock('church').centre;
    final g = await t.startGesture(onPhoto(const Offset(760, 330)));
    for (var i = 1; i <= 12; i++) {
      await g.moveTo(Offset.lerp(onPhoto(const Offset(760, 330)), onPhoto(church), i / 12)!);
      await pause(40);
    }
    await pause(200);
    await shot('14_m2_glass_on_church');
    await g.up();
    await pause(600);
    await shot('15_m2_church_found');
    for (final id in ['cafe', 't1', 'post']) {
      await reveal(find.byKey(const ValueKey('city-photo')));
      await t.tapAt(onPhoto(city.photo.clock(id).centre));
      await pause(500);
    }
    await reveal(find.byKey(const ValueKey('city-tray-not')));
    await shot('16_m2_all_found');
    await tapKey('city-card-cafe', after: 300);
    await tapKey('city-tray-trial', after: 500);
    await shot('17_m2_wrong_tray');
    await tapKey('city-card-cafe', after: 300);
    await tapKey('city-tray-not', after: 300);
    await tapKey('city-card-t1', after: 300);
    await tapKey('city-tray-trial', after: 300);
    await tapKey('city-card-church', after: 300);
    await tapKey('city-tray-not', after: 300);
    await tapKey('city-card-post', after: 300);
    await tapKey('city-tray-not', after: 300);
    await reveal(find.byKey(const ValueKey('city-tray-trial')));
    await shot('18_m2_sorted_times');
    await onToTheMap('19_m2');

    // ── M3: the hour of shadows ────────────────────────────────────────
    router.go(Routes.mission(m3.id));
    await pause(1600);
    await tapText('INVESTIGATE', after: 1200);
    await reveal(find.byKey(const ValueKey('shadow-photo-photo1')));
    await shot('20_m3_photo1');
    await reveal(find.byKey(const ValueKey('sundial')));
    await shot('21_m3_dial');
    await tapKey('sun-point-90', after: 600);
    await shot('22_m3_wrong_line');
    // Dragged round to 2:00, slowly (captured midway).
    await reveal(find.byKey(const ValueKey('sundial')));
    final r = t.getRect(find.byKey(const ValueKey('sundial')));
    Offset towards(double degrees) {
      final a = degrees * math.pi / 180;
      return r.center + Offset(math.sin(a), -math.cos(a)) * r.width * 0.3;
    }

    final d = await t.startGesture(towards(dial.sunAngleAt(90)));
    for (var time = 92.0; time <= 120; time += 3) {
      await d.moveTo(towards(dial.sunAngleAt(time)));
      await pause(40);
      if (time >= 104 && time < 107) await shot('23_m3_dragging');
    }
    await d.up();
    await pause(700);
    await shot('24_m3_photo1_matched');
    await tapKey('shadow-next', after: 700);
    await reveal(find.byKey(const ValueKey('shadow-photo-photo2')));
    await shot('25_m3_photo2');
    await tapKey('sun-point-210', after: 700);
    await reveal(find.byKey(const ValueKey('shadow-reading')));
    await shot('26_m3_completed');
    await onToTheMap('27_m3');

    // ── Final ──────────────────────────────────────────────────────────
    router.go(Routes.finalMission);
    await pause(2600);
    await shot('28_final_initial');
    await reveal(find.byKey(const ValueKey('record-tape')));
    await shot('29_final_tape');
    await tapKey('tape-mark-t3', after: 500);
    await shot('30_final_wrong_two_thirty');
    await tapKey('tape-mark-t7', after: 3200);
    await reveal(find.byKey(const ValueKey('record-tape')));
    await shot('31_final_sun_laid');
    await reveal(find.byKey(const ValueKey('trial-log')));
    await shot('32_final_book');
    await tapKey('trial-log-line-p2', after: 500);
    await shot('33_final_page_in_book');
    await tapKey('trial-log-line-p3', after: 900);
    await reveal(find.byKey(const ValueKey('record-question-sheet')));
    await shot('34_final_question');
    await tapText('The hour was lost. Time jumped from 2:45 to 4:00.', after: 300);
    await tapText('CHECK ANSWER', after: 1600);
    await shot('35_final_wrong');
    await tapText('TRY AGAIN', after: 800);
    await tapText('The hour was there. T1 was one hour behind, and the page about it is missing.', after: 300);
    await tapText('CHECK ANSWER', after: 3800);
    await reveal(find.byKey(const ValueKey('final-read-list')));
    await shot('36_final_answered');

    // ── The record list, Saint-Sulpice, the case closed ────────────────
    await tapKey('final-read-list', after: 900);
    await shot('37_list');
    await tapKey('record-line-p2', after: 500);
    await shot('38_list_wrong');
    await tapKey('record-line-p3', after: 1300);
    await shot('39_list_map');
    await tapKey('record-done', after: 1500);
    await shot('40_case_solved');
    await tapText('CONTINUE INVESTIGATION', after: 1200);
    await t.tapAt(Offset(size.width / 2, size.height / 2));
    await pause(1500);
    await shot('41_final_scene');
    await tapText('SEE MY CASE REPORT', after: 4500);
    await reveal(find.byKey(const ValueKey('next-case-coming-soon')));
    await shot('42_case11_coming_soon');
    expect(ref.read(gameControllerProvider).isCaseSolved, isTrue);
    debugPrint('QA_DONE');
  });
}
