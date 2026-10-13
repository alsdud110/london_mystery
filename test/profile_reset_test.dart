import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/profile.dart';
import 'package:london_mystery/data/models/wallet.dart';
import 'package:london_mystery/data/repositories/profile_store.dart';
import 'package:london_mystery/data/repositories/progress_repository.dart';
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
    test('wipes this detective only: the originals and the other profiles stay', () async {
      final c = ProviderContainer(overrides: await testOverrides(prefs: legacy));
      final prefs = c.read(sharedPreferencesProvider);
      final store = c.read(profileStoreProvider);
      final pid = c.read(profileSessionProvider).profileId;
      expect(c.read(gameControllerProvider).detectiveName, 'KIM');

      // Another profile with a save of its own.
      final other = await store.addProfile(detectiveName: 'BEN');
      final otherKey = AppConstants.profileKey(other.id, AppConstants.progressStorageKey);
      await prefs.setString(otherKey, save(const GameProgress(detectiveName: 'BEN')));

      await c.read(gameControllerProvider.notifier).resetAll();
      expect(
        prefs.getKeys().where((k) => k.startsWith(AppConstants.profilePrefix(pid))).toSet(),
        {
          AppConstants.profileKey(pid, AppConstants.walletStorageKey),
          AppConstants.outboxKey(pid),
          AppConstants.metaKey(pid),
        },
        reason: 'only the new wallet, its queued start coins, and the next epoch',
      );
      expect((c.read(progressRepositoryProvider) as SharedPrefsProgressRepository).epoch, 1);
      expect(c.read(walletProvider).balance, 20);
      expectOriginalsKept(prefs);
      expect(prefs.getString(otherKey), isNotNull, reason: 'the other detective is untouched');
      final p = store.profile(pid)!;
      expect(p.detectiveName, isNull);
      expect(p.origin, ProfileOrigin.fresh);
      expect(p.walletBackfill, WalletBackfill.never);
      c.dispose();

      // Restart: the old progress does not come back from the originals.
      final again = ProviderContainer(overrides: await testOverridesFor(prefs));
      addTearDown(again.dispose);
      expect(again.read(profileSessionProvider).profileId, pid);
      expect(again.read(gameControllerProvider).hasDetective, isFalse);
      expect(again.read(seasonProvider).solvedEpisodeIds, isEmpty);
      expect(again.read(walletProvider).balance, 20);
      expectOriginalsKept(prefs);
    });
  });

  group('Play again', () {
    test('starts a new run; the old run never comes back; XP, coins and tips stay correct', () async {
      final c = ProviderContainer(overrides: await testOverrides(prefs: legacy));
      final prefs = c.read(sharedPreferencesProvider);
      final game = c.read(gameControllerProvider.notifier);
      expect(XpBreakdown.totalFor(episode01, c.read(gameControllerProvider)), 5 * 100 + 200);
      expect(c.read(gameControllerProvider).runId, isNull, reason: 'a save from before runs');

      game.playAgain();
      final run = c.read(gameControllerProvider);
      expect(run.runSeq, 1);
      expect(run.runId, isNotNull);
      expect(run.rev, 0);
      expect(run.completedMissionIds, isEmpty);
      expect(run.detectiveName, 'KIM');
      expect(c.read(seasonProvider).isSolved('ep01'), isTrue, reason: 'the season remembers');
      expect(c.read(walletProvider).balance, 30, reason: 'coins are not taken back');

      // Solving again pays nothing more; the bought tip is still free.
      game.startInvestigation();
      expect(game.submitAnswer(episode01.missions.first, 'b').coins, 0);
      expect(c.read(walletProvider).ownsTip('m01', 2), isTrue);
      expect(XpBreakdown.totalFor(episode01, c.read(gameControllerProvider)), 30, reason: 'rule 4 for the new run');
      expectOriginalsKept(prefs);
      c.dispose();

      final again = ProviderContainer(overrides: await testOverridesFor(prefs));
      addTearDown(again.dispose);
      final restored = again.read(gameControllerProvider);
      expect(restored.runId, run.runId);
      expect(restored.runSeq, 1);
      expect(restored.completedMissionIds, ['m01'], reason: 'the new run, not the old one');
    });

    test('a second play again counts on', () async {
      final c = ProviderContainer(overrides: await testOverrides(prefs: legacy));
      addTearDown(c.dispose);
      final game = c.read(gameControllerProvider.notifier);
      game.playAgain();
      final first = c.read(gameControllerProvider).runId;
      game.playAgain();
      expect(c.read(gameControllerProvider).runSeq, 2);
      expect(c.read(gameControllerProvider).runId, isNot(first));
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
      expect(ProfileStore(prefs).read()!.activeProfileId, pid, reason: 'the same guest, wiped');

      expect(await t.runAsync(() => resetForNextPlayer(ref)), isTrue, reason: 'running it again is fine');
      expect(await t.runAsync(() => ProfileStore(prefs).bootstrap()).then((s) => s!.profileId), pid);
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
    testWidgets('a playtest start marks what it sets up as operator data and keeps the originals', (t) async {
      final c = ProviderContainer(overrides: await testOverrides(prefs: legacy));
      addTearDown(c.dispose);
      final prefs = c.read(sharedPreferencesProvider);
      final ref = await widgetRefOf(t, c);
      await t.runAsync(() => startPlaytestAt(ref, 'ep03'));
      final p = c.read(profileStoreProvider).profile(c.read(profileSessionProvider).profileId)!;
      expect(p.detectiveName, 'KIM');
      final season = c.read(seasonProvider);
      expect(season.isSolved('ep02'), isTrue);
      expect(season.playtestEpisodeIds, ['ep01', 'ep02'], reason: 'solved only by the tool');
      expect(c.read(progressRepositoryProvider).load('ep01').playtest, isTrue);
      expect(c.read(progressRepositoryProvider).load('ep02').playtest, isTrue);
      // Case 03 is open only because of the tool: what is played in it is operator data too.
      final game = c.read(gameControllerProvider.notifier);
      game.startInvestigation();
      expect(c.read(gameControllerProvider).playtest, isTrue);
      expectOriginalsKept(prefs);
    });
  });
}
