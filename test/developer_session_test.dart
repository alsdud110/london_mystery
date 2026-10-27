import 'dart:convert';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/models/difficulty.dart';
import 'package:london_mystery/data/models/episode.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/mission.dart';
import 'package:london_mystery/data/models/profile.dart';
import 'package:london_mystery/data/models/season.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/models/wallet.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/data/repositories/memory_preferences.dart';
import 'package:london_mystery/data/repositories/profile_store.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/game/wallet_controller.dart';
import 'package:london_mystery/features/game_master/dev_session.dart';
import 'package:london_mystery/features/game_master/playtest_tools.dart';
import 'package:london_mystery/features/onboarding/how_to_play_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'full_playthrough_test.dart' show reveal, tapText, wait;
import 'helpers.dart';

/// Difficulty PART 4: developer mode is a test session of its own — TESTER,
/// the boy's picture, Rookie; storage in memory; a new one at every entry —
/// and the player's game comes back exactly as it was (see
/// docs/DIFFICULTY_IMPLEMENTATION.md).

const id = 'abcdef0123456789abcdef0123456789';
final catalog = MockEpisodeRepository.bundled();
List<Episode> casesOf(String seasonId) => [for (final e in catalog) if (e.seasonId == seasonId) e];
final london = casesOf(SeasonIds.london);
final paris = casesOf(SeasonIds.paris);
String pk(String legacyKey) => AppConstants.profileKey(id, legacyKey);

GameProgress solved(Episode e) => GameProgress(
      detectiveName: 'KIM',
      introSeen: true,
      completedMissionIds: [for (final m in e.allMissions) m.id],
      startedAt: DateTime(2026, 9, 2),
      completedAt: DateTime(2026, 9, 2, 1),
      playMillis: 1000,
    );

/// The player: KIM, the girl, Junior; London under way (Cases 01–02 solved,
/// Case 03 begun), coins and a tip bought, How to Play seen, sound on.
Map<String, Object> player() => {
      AppConstants.detectiveStorageKey: jsonEncode({
        'schema': 1,
        'profile': {
          'id': id,
          'origin': 'fresh',
          'walletBackfill': 'never',
          'detectiveName': 'KIM',
          'avatar': 'girl',
          'createdAt': '2026-09-01T10:00:00.000',
          'difficulty': 'junior',
        },
      }),
      pk(AppConstants.progressKeyFor('ep01')): jsonEncode(solved(london[0]).toJson()),
      pk(AppConstants.progressKeyFor('ep02')): jsonEncode(solved(london[1]).toJson()),
      pk(AppConstants.progressKeyFor('ep03')):
          jsonEncode(const GameProgress(detectiveName: 'KIM', introSeen: true, completedMissionIds: ['ep03_m1']).toJson()),
      pk(AppConstants.seasonKeyFor(SeasonIds.london)):
          jsonEncode(const SeasonProgress(activeEpisodeId: 'ep03', solvedEpisodeIds: ['ep01', 'ep02'], difficulty: Difficulty.junior).toJson()),
      pk(AppConstants.walletStorageKey): jsonEncode(Wallet([
        const CoinEntry(key: Wallet.startKey, amount: 20, source: CoinSource.start),
        for (final e in london.take(2))
          for (final m in e.allMissions) CoinEntry(key: Wallet.missionKey(m.id), amount: WalletController.coinsFor(m), source: CoinSource.mission),
        CoinEntry(key: Wallet.missionKey('ep03_m1'), amount: 5, source: CoinSource.mission),
        CoinEntry(key: Wallet.tipKey('ep03_m1', 2), amount: -20, source: CoinSource.tip),
      ]).toJson()),
      AppConstants.onboardingSeenKey(id): true,
      AppConstants.soundEnabledKey: true,
    };

Map<String, Object?> snapshot(SharedPreferences p) => {for (final k in p.getKeys()) k: p.get(k)};

late WidgetRef ref;

/// The game as the app runs it: under its developer-mode host.
Future<SharedPreferences> pumpGame(WidgetTester t, Map<String, Object> prefs) async {
  t.view.physicalSize = const Size(390, 844) * 3;
  t.view.devicePixelRatio = 3;
  addTearDown(t.view.reset);
  SharedPreferences.setMockInitialValues(prefs);
  final storage = await SharedPreferences.getInstance();
  await t.pumpWidget(DevSessionHost(
    overrides: await testOverridesFor(storage),
    child: Consumer(builder: (context, r, _) {
      ref = r;
      return const LondonMysteryApp();
    }),
  ));
  await wait(t, const Duration(milliseconds: 300));
  return storage;
}

ProviderContainer session(WidgetTester t) => ProviderScope.containerOf(t.element(find.byType(LondonMysteryApp)));

String path(WidgetTester t) => session(t).read(routerProvider).routerDelegate.currentConfiguration.uri.toString();

Future<void> openGameMaster(WidgetTester t) async {
  session(t).read(gameMasterAccessProvider.notifier).grant();
  session(t).read(routerProvider).go(Routes.gameMaster);
  await wait(t, const Duration(milliseconds: 600));
}

Future<void> enterDeveloperMode(WidgetTester t) async {
  await openGameMaster(t);
  await tapText(t, 'START DEVELOPER MODE', after: const Duration(milliseconds: 900));
  expect(find.byKey(const ValueKey('developer-mode-header')), findsOneWidget);
}

Future<void> exitDeveloperMode(WidgetTester t) async {
  session(t).read(routerProvider).go(Routes.gameMaster);
  await wait(t, const Duration(milliseconds: 600));
  await tapText(t, 'EXIT DEVELOPER MODE', after: const Duration(milliseconds: 900));
  expect(find.byKey(const ValueKey('developer-mode-header')), findsNothing);
}

Future<void> tapKey(WidgetTester t, String key) async {
  await reveal(t, find.byKey(ValueKey(key)));
  await t.tap(find.byKey(ValueKey(key)));
  await wait(t, const Duration(milliseconds: 900));
}

/// The case shortcut, from the Game Master's page of the test session.
Future<void> jumpTo(WidgetTester t, String seasonId, String caseId) async {
  session(t).read(routerProvider).go(Routes.gameMaster);
  await wait(t, const Duration(milliseconds: 600));
  // From the top of the page (it may have been left scrolled down).
  t.state<ScrollableState>(find.byType(Scrollable).first).position.jumpTo(0);
  await t.pump();
  await tapKey(t, 'shortcut-season-$seasonId');
  await tapKey(t, 'shortcut-case-$caseId');
  expect(path(t), Routes.caseFile(caseId));
}

/// Plays the open case's first [count] missions (intro seen first).
List<SubmitOutcome> solve(WidgetTester t, int count) {
  final c = session(t);
  final game = c.read(gameControllerProvider.notifier)..startInvestigation();
  final missions = c.read(currentEpisodeProvider).allMissions.take(count);
  return [for (final Mission m in missions) game.submitAnswer(m, m.answer)];
}

bool selected(WidgetTester t, Finder f) => t.getSemantics(f).flagsCollection.isSelected == Tristate.isTrue;

void main() {
  testWidgets('1–6, 15, 28–31. In and out: TESTER/BOY/Rookie inside; KIM, the girl, Junior and every save as they were after — byte for byte', (t) async {
    final prefs = await pumpGame(t, player());
    final before = snapshot(prefs);
    final own = session(t);
    final coins = own.read(walletProvider).balance;
    await enterDeveloperMode(t);
    final test = session(t);
    expect(identical(test, own), isFalse, reason: 'a container of its own');
    expect(test.read(sharedPreferencesProvider), isA<MemoryPreferences>());
    final tester = test.read(detectiveProfileProvider);
    expect((tester.detectiveName, tester.avatar, tester.difficulty), ('TESTER', DetectiveAvatar.boy, Difficulty.rookie));
    expect(test.read(gameControllerProvider).detectiveName, 'TESTER');
    expect(test.read(seasonProvider).solvedEpisodeIds, isEmpty, reason: 'a test session starts empty');
    expect(test.read(walletProvider).balance, AppConstants.startCoins);
    expect(find.byKey(const ValueKey('developer-mode-banner')), findsOneWidget);
    // The detective's file shows TESTER and the boy.
    test.read(routerProvider).go(Routes.detective);
    await wait(t, const Duration(milliseconds: 600));
    expect(find.text('TESTER'), findsWidgets);
    final semantics = t.ensureSemantics();
    expect(selected(t, find.byKey(const ValueKey('avatar-boy'))), isTrue);
    semantics.dispose();

    // London and Paris played, coins earned, a tip bought, London complete.
    await jumpTo(t, SeasonIds.london, 'ep03');
    expect(solve(t, 2).map((o) => o.result), everyElement(SubmitResult.correct));
    expect(session(t).read(walletProvider).balance, greaterThan(AppConstants.startCoins), reason: 'coins in the test session');
    expect(session(t).read(walletProvider.notifier).unlockTip(london[2].missions[2], 2), TipUnlock.paid);
    expect(session(t).read(gameControllerProvider).collectedEvidence(london[2]), isNotEmpty);
    await jumpTo(t, SeasonIds.paris, 's2_ep03');
    expect(solve(t, 1).single.result, SubmitResult.correct);
    session(t).read(routerProvider).go(Routes.gameMaster);
    await wait(t, const Duration(milliseconds: 600));
    await tapText(t, 'CASE 12부터', after: const Duration(milliseconds: 600));
    await tapText(t, '시작', after: const Duration(milliseconds: 1200));
    final finale = solve(t, london.last.allMissions.length);
    expect(finale.map((o) => o.result), everyElement(SubmitResult.correct));
    expect(session(t).read(seasonLevelProvider(SeasonIds.london))!.status, SeasonLevelStatus.completed, reason: 'London complete — in the test');
    expect(session(t).read(nextLevelQuestionProvider), isNotNull);
    expect(prefs.getString(AppConstants.detectiveStorageKey), before[AppConstants.detectiveStorageKey], reason: 'TESTER never on the device');

    await exitDeveloperMode(t);
    expect(identical(session(t), own), isTrue, reason: 'the player\'s own game, the same one');
    expect(path(t), Routes.gameMaster, reason: 'back on the page left');
    expect(snapshot(prefs), before, reason: 'nothing of the test session on the device');
    final kim = own.read(detectiveProfileProvider);
    expect((kim.detectiveName, kim.avatar, kim.difficulty), ('KIM', DetectiveAvatar.girl, Difficulty.junior));
    expect(own.read(seasonProvider).solvedEpisodeIds, ['ep01', 'ep02']);
    expect(own.read(seasonLevelProvider(SeasonIds.london))!.status, SeasonLevelStatus.inProgress);
    expect(own.read(walletProvider).balance, coins);
    expect(own.read(walletProvider).ownsTip('ep03_m1', 2), isTrue);
    expect(find.byKey(const ValueKey('developer-mode-banner')), findsNothing);
    own.read(routerProvider).go(Routes.detective);
    await wait(t, const Duration(milliseconds: 600));
    expect(find.text('KIM'), findsWidgets);
    expect(find.text('TESTER'), findsNothing);
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('16–19. Every entry a new session; within one, pages come and go and the progress stays', (t) async {
    final prefs = await pumpGame(t, player());
    final before = snapshot(prefs);
    await enterDeveloperMode(t);
    final first = session(t);
    await jumpTo(t, SeasonIds.paris, 's2_ep03');
    solve(t, 2);
    expect(session(t).read(gameControllerProvider).completedMissionIds.length, 2);
    // Pages in the same session: the title, the Game Master, the case file.
    session(t).read(routerProvider).go(Routes.start);
    await wait(t, const Duration(milliseconds: 800));
    await openGameMaster(t);
    expect(identical(session(t), first), isTrue, reason: 'the same session');
    await t.pump(); // a rebuild
    expect(session(t).read(progressRepositoryProvider).load('s2_ep03').completedMissionIds.length, 2);
    await exitDeveloperMode(t);

    await enterDeveloperMode(t);
    expect(identical(session(t), first), isFalse, reason: 'a new session');
    expect(session(t).read(progressRepositoryProvider).load('s2_ep03').completedMissionIds, isEmpty);
    await jumpTo(t, SeasonIds.paris, 's2_ep03');
    final c = session(t);
    expect(c.read(gameControllerProvider).completedMissionIds, isEmpty, reason: 'Mission 1 again');
    expect(c.read(currentEpisodeProvider).id, 's2_ep03');
    expect(c.read(gameControllerProvider).isUnlocked(c.read(currentEpisodeProvider), paris[2].missions.first.id), isTrue);
    expect(c.read(walletProvider).balance, AppConstants.startCoins);
    expect(c.read(detectiveProfileProvider).difficulty, Difficulty.rookie);
    await exitDeveloperMode(t);
    expect(snapshot(prefs), before);
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('20. A test session is never kept: the app started again is the player\'s game', (t) async {
    final prefs = await pumpGame(t, player());
    final before = snapshot(prefs);
    await enterDeveloperMode(t);
    await jumpTo(t, SeasonIds.london, 'ep05');
    solve(t, 1);
    // The app stopped in the middle of the test session, and started again.
    await t.pumpWidget(const SizedBox());
    await t.pump(const Duration(milliseconds: 100));
    await t.pumpWidget(DevSessionHost(
      overrides: await testOverridesFor(prefs),
      child: Consumer(builder: (context, r, _) {
        ref = r;
        return const LondonMysteryApp();
      }),
    ));
    await wait(t, const Duration(milliseconds: 600));
    expect(find.byKey(const ValueKey('developer-mode-banner')), findsNothing);
    expect(session(t).read(detectiveProfileProvider).detectiveName, 'KIM');
    expect(session(t).read(progressRepositoryProvider).load('ep05').completedMissionIds, isEmpty);
    expect(snapshot(prefs), before);
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('21–27. The test level: chosen freely; a case under way starts again at Mission 1; no restart question; the player\'s level kept', (t) async {
    final prefs = await pumpGame(t, player());
    final before = snapshot(prefs);
    await enterDeveloperMode(t);
    final semantics = t.ensureSemantics();
    expect(selected(t, find.byKey(const ValueKey('difficulty-rookie'))), isTrue, reason: 'Rookie at first');
    // No case begun: only the level changes.
    await tapKey(t, 'difficulty-junior');
    expect(session(t).read(detectiveProfileProvider).difficulty, Difficulty.junior);
    expect(find.byKey(const ValueKey('restart-season-dialog')), findsNothing);
    expect(selected(t, find.byKey(const ValueKey('difficulty-junior'))), isTrue);
    // A case begun at Junior (its intro fixes the season's level), two missions in.
    await jumpTo(t, SeasonIds.london, 'ep04');
    session(t).read(routerProvider).go(Routes.intro);
    await wait(t, const Duration(milliseconds: 600));
    expect(session(t).read(seasonProvider).difficulty, Difficulty.junior);
    solve(t, 2);
    expect(session(t).read(gameControllerProvider).completedMissionIds.length, 2);
    // Master: the case starts again from its Mission 1, the season at Master.
    session(t).read(routerProvider).go(Routes.gameMaster);
    await wait(t, const Duration(milliseconds: 600));
    await tapKey(t, 'difficulty-master');
    expect(find.byKey(const ValueKey('restart-season-dialog')), findsNothing, reason: 'no question in a test');
    final c = session(t);
    expect(c.read(detectiveProfileProvider).difficulty, Difficulty.master);
    expect(c.read(seasonProvider).difficulty, Difficulty.master);
    expect(c.read(currentDifficultyProvider), Difficulty.master);
    expect(c.read(currentEpisodeProvider).id, 'ep04', reason: 'the same case');
    expect(c.read(gameControllerProvider).completedMissionIds, isEmpty, reason: 'from its Mission 1');
    expect(c.read(seasonProvider).solvedEpisodeIds, isEmpty, reason: 'only the case starts again');
    expect(find.textContaining('CASE 04 restarts as MASTER'), findsOneWidget);
    semantics.dispose();
    // How to Play, forgotten and seen again in the test session: its own record.
    await c.read(howToPlaySeenProvider.notifier).forget();
    c.read(howToPlaySeenProvider.notifier).complete();
    expect(c.read(sharedPreferencesProvider).getBool(AppConstants.onboardingSeenKey(devDetectiveId)), isTrue);
    await exitDeveloperMode(t);
    expect(session(t).read(howToPlaySeenProvider), isTrue, reason: 'the player\'s How to Play record');
    expect(session(t).read(detectiveProfileProvider).difficulty, Difficulty.junior, reason: 'the player\'s level');
    expect(session(t).read(seasonDifficultyProvider(SeasonIds.london)), Difficulty.junior);
    expect(snapshot(prefs), before);
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('32–35. CASE NN부터, the case shortcut, the case again, OPERATOR MODE: all in the test session', (t) async {
    final prefs = await pumpGame(t, player());
    final before = snapshot(prefs);
    await enterDeveloperMode(t);
    // CASE 07부터: the test session prepared (earlier cases solved there).
    await tapText(t, 'CASE 07부터', after: const Duration(milliseconds: 600));
    await tapText(t, '시작', after: const Duration(milliseconds: 1200));
    expect(path(t), Routes.caseFile('ep07'));
    expect(session(t).read(seasonProvider).solvedEpisodeIds, [for (final e in london.take(6)) e.id]);
    expect(session(t).read(detectiveProfileProvider).detectiveName, 'TESTER');
    solve(t, 1);
    // The case again, from its start.
    session(t).read(routerProvider).go(Routes.gameMaster);
    await wait(t, const Duration(milliseconds: 600));
    await tapText(t, '지금 사건(CASE 07) 처음부터', after: const Duration(milliseconds: 600));
    await tapText(t, '다시 시작', after: const Duration(milliseconds: 900));
    expect(session(t).read(gameControllerProvider).completedMissionIds, isEmpty);
    // OPERATOR MODE: every case of the season open, in the test.
    session(t).read(routerProvider).go(Routes.gameMaster);
    await wait(t, const Duration(milliseconds: 600));
    await reveal(t, find.text('전체 사건 열기 (OPERATOR MODE)'));
    await t.tap(find.text('전체 사건 열기 (OPERATOR MODE)'));
    await wait(t, const Duration(milliseconds: 400));
    expect(session(t).read(operatorAccessProvider), isTrue);
    expect(session(t).read(seasonProvider.notifier).isUnlocked('ep12'), isTrue);
    // The shortcut to a Paris case.
    await jumpTo(t, SeasonIds.paris, 's2_ep10');
    expect(session(t).read(selectedSeasonIdProvider), SeasonIds.paris);
    await exitDeveloperMode(t);
    final own = session(t);
    expect(own.read(operatorAccessProvider), isFalse, reason: 'the switches were the test session\'s');
    expect(own.read(seasonPreviewProvider), isFalse);
    expect(own.read(selectedSeasonIdProvider), SeasonIds.london);
    expect(snapshot(prefs), before);
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('The player\'s own Game Master: the way into developer mode and the next-player reset; no test tool on the player\'s saves', (t) async {
    final prefs = await pumpGame(t, player());
    final before = snapshot(prefs);
    await openGameMaster(t);
    expect(find.text('START DEVELOPER MODE'), findsOneWidget);
    expect(find.text('다음 플레이어를 위해 기기 초기화'), findsOneWidget, reason: 'the reset stays (36–37)');
    for (final tool in ['CASE 03부터', '사건 바로가기', '전체 사건 열기 (OPERATOR MODE)', '지금 사건(CASE 03) 처음부터']) {
      expect(find.text(tool), findsNothing, reason: '$tool only in a test session');
    }
    // Called on the player's saves anyway: refused, nothing written.
    expect(jumpToCase(ref, SeasonIds.paris, 's2_ep01'), CaseJumpRefusal.playerSaves);
    restartCurrentCase(ref);
    expect(() => startPlaytestAt(ref, 'ep05'), throwsStateError);
    expect(changeTestLevel(ref, Difficulty.master), isFalse);
    await t.pump();
    expect(snapshot(prefs), before);
    // In the test session the reset is not offered (nothing to reset there).
    await tapText(t, 'START DEVELOPER MODE', after: const Duration(milliseconds: 900));
    expect(find.text('다음 플레이어를 위해 기기 초기화'), findsNothing);
    await wait(t, const Duration(seconds: 1));
  });

  testWidgets('36–37. NEW ADVENTURE and the next-player reset work on the player\'s game as before', (t) async {
    final prefs = await pumpGame(t, player());
    await enterDeveloperMode(t);
    await exitDeveloperMode(t);
    final own = session(t);
    await own.read(gameControllerProvider.notifier).newAdventure();
    expect(own.read(seasonProvider).solvedEpisodeIds, isEmpty);
    expect(ProfileStore(prefs).profile!.detectiveName, 'KIM', reason: 'NEW ADVENTURE keeps the detective');
    await own.read(gameControllerProvider.notifier).resetAll();
    expect(ProfileStore(prefs).profile!.isCreated, isFalse, reason: 'the reset empties the slot');
    await wait(t, const Duration(seconds: 1));
  });

  testWidgets('Back on a test session\'s first page leaves developer mode, not the app', (t) async {
    final prefs = await pumpGame(t, player());
    final before = snapshot(prefs);
    await enterDeveloperMode(t);
    expect(session(t).read(routerProvider).canPop(), isFalse);
    await t.binding.handlePopRoute();
    await wait(t, const Duration(milliseconds: 900));
    expect(find.byKey(const ValueKey('developer-mode-banner')), findsNothing);
    expect(session(t).read(detectiveProfileProvider).detectiveName, 'KIM');
    expect(path(t), Routes.gameMaster);
    expect(snapshot(prefs), before);
    await wait(t, const Duration(seconds: 1));
  });

  testWidgets('Without a detective yet: developer mode still opens (TESTER), and the device stays without one', (t) async {
    final prefs = await pumpGame(t, const {});
    await enterDeveloperMode(t);
    expect(session(t).read(detectiveProfileProvider).detectiveName, 'TESTER');
    await jumpTo(t, SeasonIds.london, 'ep02');
    await exitDeveloperMode(t);
    expect(session(t).read(detectiveProfileProvider).isCreated, isFalse);
    expect(ProfileStore(prefs).profile?.isCreated ?? false, isFalse);
    await wait(t, const Duration(seconds: 1));
  });
}
