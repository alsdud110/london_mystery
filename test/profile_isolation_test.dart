import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/models/profile.dart';
import 'package:london_mystery/data/models/wallet.dart';
import 'package:london_mystery/data/repositories/profile_store.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/game/wallet_controller.dart';
import 'package:london_mystery/features/profile/profile_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers.dart';

/// Plays Case 01's first mission: name, story intro, tip 1, the answer.
void playFirstMission(ProviderContainer c, String name) {
  final game = c.read(gameControllerProvider.notifier);
  final m01 = episode01.missions.first;
  expect(game.registerDetective(name), isNull);
  game.startInvestigation();
  c.read(walletProvider.notifier).unlockTip(m01, 1);
  game.useHint(m01);
  expect(game.submitAnswer(m01, 'b').coins, 30);
}

/// Shows which profile and detective the session it sits in plays.
class _Probe extends ConsumerWidget {
  const _Probe();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Directionality(
        textDirection: TextDirection.ltr,
        child: Text(
          'name: ${ref.watch(gameControllerProvider).detectiveName ?? '-'} '
          'coins: ${ref.watch(walletProvider).balance}',
        ),
      );
}

void main() {
  group('two profiles on one device', () {
    test('never share progress, coins, tips, badges or the season', () async {
      final a = ProviderContainer(overrides: await testOverrides());
      addTearDown(a.dispose);
      final prefs = a.read(sharedPreferencesProvider);
      playFirstMission(a, 'ANNA');
      final b = await ProfileStore(prefs).addProfile(detectiveName: 'BEN');

      final bc = ProviderContainer(overrides: [
        ...await testOverridesFor(prefs),
        profileSessionProvider.overrideWithValue(ProfileSession(profile: b)),
      ]);
      addTearDown(bc.dispose);
      final fresh = bc.read(gameControllerProvider);
      expect(fresh.detectiveName, isNull);
      expect(fresh.completedMissionIds, isEmpty);
      expect(fresh.hintsUsed, isEmpty);
      expect(fresh.badgeIds, isEmpty);
      expect(bc.read(walletProvider).balance, 20, reason: 'B starts with the start coins only');
      expect(bc.read(walletProvider).ownsTip('m01', 1), isFalse);
      expect(bc.read(seasonProvider).solvedEpisodeIds, isEmpty);

      // B plays the same mission: each is paid once, in its own wallet.
      playFirstMission(bc, 'BEN');
      expect(bc.read(walletProvider).balance, 50);

      final again = ProviderContainer(overrides: await testOverridesFor(prefs));
      addTearDown(again.dispose);
      expect(again.read(profileSessionProvider).profileId, isNot(b.id), reason: 'A is still the active profile');
      expect(again.read(gameControllerProvider).detectiveName, 'ANNA');
      expect(again.read(walletProvider).balance, 50);
      expect(again.read(walletProvider).entries.map((e) => e.key), ['start', 'tip:m01:1', 'mission:m01']);
    });

    test('one guest per device', () async {
      final c = ProviderContainer(overrides: await testOverrides());
      addTearDown(c.dispose);
      final store = c.read(profileStoreProvider);
      expect(c.read(profileSessionProvider).profile.kind, ProfileKind.guest);
      await expectLater(store.addProfile(kind: ProfileKind.guest), throwsStateError);
      expect(store.read()!.profiles, hasLength(1));
    });
  });

  group('switching profiles', () {
    testWidgets('drops every state of the profile before: case, wallet, router, passes', (t) async {
      final overrides = await testOverrides();
      final prefs = await SharedPreferences.getInstance();
      final store = ProfileStore(prefs);
      final start = store.ensureActiveSync();
      final ben = await store.addProfile(detectiveName: 'BEN');
      final host = GlobalKey<ProfileSessionHostState>();
      await t.pumpWidget(ProfileSessionHost(key: host, session: start, overrides: overrides, child: const _Probe()));

      final a = host.currentState!.container;
      playFirstMission(a, 'ANNA');
      a.read(parentReportAccessProvider.notifier).grant();
      a.read(gameMasterAccessProvider.notifier).grant();
      a.read(operatorAccessSwitchProvider.notifier).set(true);
      a.read(recentSolveProvider.notifier).add('ep01');
      final routerA = a.read(routerProvider);
      await t.pump();
      expect(find.text('name: ANNA coins: 50'), findsOneWidget);

      await host.currentState!.switchTo(ben.id);
      await t.pump();
      final b = host.currentState!.container;
      expect(identical(a, b), isFalse);
      expect(find.text('name: - coins: 20'), findsOneWidget);
      expect(b.read(parentReportAccessProvider), isFalse);
      expect(b.read(gameMasterAccessProvider), isFalse);
      expect(b.read(operatorAccessProvider), isFalse);
      expect(b.read(recentSolveProvider), isEmpty);
      expect(identical(b.read(routerProvider), routerA), isFalse, reason: 'a new router and page stack');
      expect(store.read()!.activeProfileId, ben.id, reason: 'the choice survives a restart');

      // Back to A: its saves are there, its one-visit passes are not.
      await host.currentState!.switchTo(start.profileId);
      await t.pump();
      final a2 = host.currentState!.container;
      expect(find.text('name: ANNA coins: 50'), findsOneWidget);
      expect(a2.read(gameControllerProvider).isCompleted('m01'), isTrue);
      expect(a2.read(walletProvider).ownsTip('m01', 1), isTrue);
      expect(a2.read(parentReportAccessProvider), isFalse);
      expect(a2.read(operatorAccessProvider), isFalse);
    });

  });

  group('operator access and playtest data', () {
    Future<(ProviderContainer, ProfileOrigin Function())> setUpGame() async {
      final c = ProviderContainer(overrides: await testOverrides());
      addTearDown(c.dispose);
      final pid = c.read(profileSessionProvider).profileId;
      return (c, () => c.read(profileStoreProvider).profile(pid)!.origin);
    }

    Future<void> settle() => Future<void>.delayed(Duration.zero);

    test('switching it on (and off) marks nothing', () async {
      final (c, origin) = await setUpGame();
      c.read(operatorAccessSwitchProvider.notifier).set(true);
      c.read(operatorAccessSwitchProvider.notifier).set(false);
      await settle();
      expect(origin(), ProfileOrigin.fresh);
    });

    test('solving a case a child could reach anyway, with it on, marks nothing', () async {
      final (c, origin) = await setUpGame();
      c.read(operatorAccessSwitchProvider.notifier).set(true);
      playFirstMission(c, 'ANNA');
      await settle();
      expect(origin(), ProfileOrigin.fresh);
    });

    test('play in a case only operator access opened is operator data, record by record', () async {
      final (c, origin) = await setUpGame();
      final game = c.read(gameControllerProvider.notifier);
      playFirstMission(c, 'ANNA'); // normal play first
      c.read(operatorAccessSwitchProvider.notifier).set(true);
      expect(game.openEpisode('ep08'), isTrue);
      expect(c.read(gameControllerProvider).playtest, isFalse, reason: 'only opened');

      game.startInvestigation();
      expect(c.read(gameControllerProvider).playtest, isTrue, reason: 'the run is played');
      final m = c.read(currentEpisodeProvider).missions.first;
      c.read(gameControllerProvider.notifier).revealTip(m, 1);
      expect(game.submitAnswer(m, m.answer).result, SubmitResult.correct);
      await settle();

      final wallet = c.read(walletProvider);
      CoinEntry entry(String key) => wallet.entries.firstWhere((e) => e.key == key);
      expect(entry(Wallet.missionKey(m.id)).playtest, isTrue);
      expect(entry(Wallet.tipKey(m.id, 1)).playtest, isTrue);
      expect(entry(Wallet.missionKey('m01')).playtest, isFalse, reason: 'normal play stays normal');
      expect(entry(Wallet.startKey).playtest, isFalse);
      expect(c.read(progressRepositoryProvider).load('ep01').playtest, isFalse);
      expect(origin(), ProfileOrigin.fresh, reason: 'the profile itself is not marked');
      expect(
        const DetectiveProfile(id: 'abcdef0123456789', kind: ProfileKind.account, origin: ProfileOrigin.playtest)
            .syncable,
        isFalse,
        reason: 'a Phase 1 playtest profile is never synced, even as an account profile',
      );
    });

    test('a full reset leaves no test data', () async {
      final (c, origin) = await setUpGame();
      final game = c.read(gameControllerProvider.notifier);
      game.registerDetective('ANNA');
      c.read(operatorAccessSwitchProvider.notifier).set(true);
      game.openEpisode('ep08');
      game.startInvestigation();
      final m = c.read(currentEpisodeProvider).missions.first;
      game.submitAnswer(m, m.answer);
      await game.resetAll();
      expect(c.read(walletProvider).entries.where((e) => e.playtest), isEmpty);
      expect(c.read(seasonProvider).playtestEpisodeIds, isEmpty);
      expect(c.read(progressRepositoryProvider).load('ep08').playtest, isFalse);
      expect(origin(), ProfileOrigin.fresh);
    });
  });
}
