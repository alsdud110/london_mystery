import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/profile.dart';
import 'package:london_mystery/data/models/wallet.dart';
import 'package:london_mystery/data/repositories/profile_store.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/game/scoring.dart';
import 'package:london_mystery/features/game/wallet_controller.dart';
import 'package:london_mystery/features/game_master/playtest_tools.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

String save(GameProgress p) => jsonEncode(p.toJson());

/// Case 01 solved (rule 3 XP) and open, a tip bought, coins in the wallet.
final legacy = <String, Object>{
  AppConstants.progressStorageKey: save(GameProgress(
    detectiveName: 'KIM',
    introSeen: true,
    completedMissionIds: [for (final m in episode01.allMissions) m.id],
    hintsUsed: const {'m01': 2},
    xpRules: {for (final m in episode01.allMissions) m.id: 3},
    startedAt: DateTime(2026, 9, 1),
    completedAt: DateTime(2026, 9, 2),
    playMillis: 1000,
  )),
  AppConstants.seasonStorageKey: jsonEncode({'activeEpisodeId': 'ep01', 'solvedEpisodeIds': ['ep01']}),
  AppConstants.walletStorageKey: jsonEncode(const Wallet([
    CoinEntry(key: 'start', amount: 20, source: CoinSource.start),
    CoinEntry(key: 'mission:m01', amount: 30, source: CoinSource.mission),
    CoinEntry(key: 'tip:m01:2', amount: -20, source: CoinSource.tip),
  ]).toJson()),
};

void expectOriginalsKept(SharedPreferences prefs) {
  for (final e in legacy.entries) {
    expect(prefs.getString(e.key), e.value, reason: '${e.key}: the original is kept');
  }
}

/// Gives the test a [WidgetRef] of a container (for the game master tools).
Future<WidgetRef> widgetRefOf(WidgetTester t, ProviderContainer c) async {
  late WidgetRef captured;
  await t.pumpWidget(UncontrolledProviderScope(
    container: c,
    child: Consumer(builder: (context, ref, _) {
      captured = ref;
      return const SizedBox();
    }),
  ));
  return captured;
}

void main() {
  group('Start a New Adventure (the everyday reset)', () {
    test('the same detective starts over: id, name, picture kept; progress, XP, coins start again', () async {
      final c = ProviderContainer(overrides: await testOverrides(prefs: legacy));
      final prefs = c.read(sharedPreferencesProvider);
      final store = c.read(profileStoreProvider);
      final pid = c.read(profileSessionProvider).profileId;
      await c.read(detectiveProfileProvider.notifier).setAvatar(DetectiveAvatar.girl);
      final before = store.profile!;
      expect(before.detectiveName, 'KIM');
      expect(c.read(seasonProvider).isSolved('ep01'), isTrue);

      // Saves of an earlier profile held on the device, runs a cloud build
      // kept aside, and a setting of the device: never removed by it.
      const held = 'abcdefabcdefabcdefabcdefabcdefab';
      final heldKey = AppConstants.profileKey(held, AppConstants.progressStorageKey);
      await prefs.setString(heldKey, save(const GameProgress(detectiveName: 'BEN')));
      await prefs.setString(AppConstants.keptRunsKey(pid), '{"items":[]}');
      await prefs.setBool(AppConstants.soundEnabledKey, false);

      await c.read(gameControllerProvider.notifier).newAdventure();
      final after = store.profile!;
      expect(after.id, pid, reason: 'the same detective');
      expect((after.detectiveName, after.avatar, after.createdAt), (before.detectiveName, before.avatar, before.createdAt));
      expect(c.read(gameControllerProvider).detectiveName, 'KIM');
      expect(c.read(gameControllerProvider).hasDetective, isTrue, reason: 'no new detective to create');
      expect(c.read(gameControllerProvider).completedMissionIds, isEmpty);
      expect(XpBreakdown.totalFor(episode01, c.read(gameControllerProvider)), 0);
      expect(c.read(seasonProvider).solvedEpisodeIds, isEmpty);
      expect(c.read(currentEpisodeProvider).id, 'ep01');
      expect(c.read(walletProvider).balance, AppConstants.startCoins, reason: 'a new wallet: the start coins');
      expect(c.read(walletProvider).ownsTip('m01', 2), isFalse);
      expect(
        prefs.getKeys().where((k) => k.startsWith(AppConstants.profilePrefix(pid))).toSet(),
        {
          AppConstants.profileKey(pid, AppConstants.progressStorageKey),
          AppConstants.profileKey(pid, AppConstants.walletStorageKey),
          AppConstants.keptRunsKey(pid),
        },
        reason: 'only the name on Case 01, the new wallet (and the runs kept aside)',
      );
      expectOriginalsKept(prefs);
      expect(prefs.getString(heldKey), isNotNull, reason: 'held saves are untouched');
      expect(prefs.getBool(AppConstants.soundEnabledKey), isFalse, reason: 'the sound setting stays');
      c.dispose();

      // Restart: the detective is there, the old progress does not come back.
      final again = ProviderContainer(overrides: await testOverridesFor(prefs));
      addTearDown(again.dispose);
      expect(again.read(profileSessionProvider).profileId, pid);
      expect(again.read(gameControllerProvider).detectiveName, 'KIM');
      expect(again.read(detectiveProfileProvider).avatar, DetectiveAvatar.girl);
      expect(again.read(seasonProvider).solvedEpisodeIds, isEmpty);
      expect(again.read(walletProvider).balance, AppConstants.startCoins);
      expectOriginalsKept(prefs);
      expect(again.read(gameControllerProvider.notifier).createDetective('Lee', DetectiveAvatar.boy), isNotNull,
          reason: 'still one detective');
    });
  });

  group('Play again', () {
    test('starts the case over; XP is not counted twice, coins and tips stay correct', () async {
      final c = ProviderContainer(overrides: await testOverrides(prefs: legacy));
      final prefs = c.read(sharedPreferencesProvider);
      final game = c.read(gameControllerProvider.notifier);
      expect(XpBreakdown.totalFor(episode01, c.read(gameControllerProvider)), 5 * 100 + 200);

      game.playAgain();
      final run = c.read(gameControllerProvider);
      expect(run.completedMissionIds, isEmpty);
      expect(run.detectiveName, 'KIM');
      expect(c.read(seasonProvider).isSolved('ep01'), isTrue, reason: 'the season remembers');
      expect(c.read(walletProvider).balance, 30, reason: 'coins are not taken back');

      // Solving again pays nothing more; the bought tip is still free.
      game.startInvestigation();
      final outcome = game.submitAnswer(episode01.missions.first, 'b');
      expect(outcome.coins, 0);
      expect(outcome.firstSolve, isFalse, reason: 'solved in an earlier run');
      expect(c.read(walletProvider).ownsTip('m01', 2), isTrue);
      expect(XpBreakdown.totalFor(episode01, c.read(gameControllerProvider)), 30,
          reason: 'the case XP is the run\'s, never added on top of the first');
      expectOriginalsKept(prefs);
      c.dispose();

      final again = ProviderContainer(overrides: await testOverridesFor(prefs));
      addTearDown(again.dispose);
      expect(again.read(gameControllerProvider).completedMissionIds, ['m01'], reason: 'the new run, not the old one');
      expect(again.read(walletProvider).balance, 30);
    });
  });

  group('the game master reset for the next player', () {
    testWidgets('also removes the originals and the copy record; safe to repeat', (t) async {
      final c = ProviderContainer(overrides: await testOverrides(prefs: legacy));
      addTearDown(c.dispose);
      final prefs = c.read(sharedPreferencesProvider);
      final pid = c.read(profileSessionProvider).profileId;
      final ref = await widgetRefOf(t, c);
      expect(prefs.getString(AppConstants.legacyMigrationKey), isNotNull);

      expect(await t.runAsync(() => resetForNextPlayer(ref)), isTrue);
      expect(ProfileStore.legacyKeys(prefs), isEmpty);
      expect(prefs.getString(AppConstants.legacyMigrationKey), isNull);
      expect(c.read(gameControllerProvider).hasDetective, isFalse);
      expect(c.read(walletProvider).balance, 20);
      expect(ProfileStore(prefs).profile!.id, pid, reason: 'the same slot, wiped');

      expect(await t.runAsync(() => resetForNextPlayer(ref)), isTrue, reason: 'running it again is fine');
      final start = await t.runAsync(() => ProfileStore(prefs).bootstrap());
      expect((start! as ProfileSession).profileId, pid);
    });

    test('cut short after the detective was wiped: the old progress cannot come back', () async {
      final c = ProviderContainer(overrides: await testOverrides(prefs: legacy));
      final prefs = c.read(sharedPreferencesProvider);
      // Only the first step ran (the app stopped before the originals went).
      await c.read(gameControllerProvider.notifier).resetAll();
      c.dispose();
      expectOriginalsKept(prefs);

      final again = ProviderContainer(overrides: await testOverridesFor(prefs));
      addTearDown(again.dispose);
      expect(again.read(gameControllerProvider).hasDetective, isFalse);
      expect(again.read(walletProvider).balance, 20);
      // The rest can be finished at any time.
      expect(await ProfileStore(prefs).wipeLegacy(), isTrue);
      expect(ProfileStore.legacyKeys(prefs), isEmpty);
    });
  });

  group('playtest tools', () {
    testWidgets('a playtest start keeps the detective and the originals', (t) async {
      final c = ProviderContainer(overrides: await testOverrides(prefs: legacy));
      addTearDown(c.dispose);
      final prefs = c.read(sharedPreferencesProvider);
      final ref = await widgetRefOf(t, c);
      await t.runAsync(() => startPlaytestAt(ref, 'ep03'));
      final p = c.read(profileStoreProvider).profile!;
      expect(p.detectiveName, 'KIM');
      expect(p.isCreated, isTrue);
      final season = c.read(seasonProvider);
      expect(season.isSolved('ep02'), isTrue);
      expect(c.read(currentEpisodeProvider).id, 'ep03');
      expectOriginalsKept(prefs);
    });
  });
}
