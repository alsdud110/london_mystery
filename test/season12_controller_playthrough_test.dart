import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/data/models/profile.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/game/wallet_controller.dart';

import 'helpers.dart';

/// Controller-level, all-case completion coverage.
///
/// This intentionally does NOT claim to exercise the Map, puzzle widgets,
/// animations, or native-device navigation. Those need widget/device tests.
void main() {
  test('all 12 cases / 50 missions: solve, unlock, save, resume, no double rewards', () async {
    final overrides = await testOverrides();
    var container = ProviderContainer(overrides: overrides);
    addTearDown(() => container.dispose());

    final catalog = container.read(episodeCatalogProvider);
    expect(catalog, hasLength(12));
    expect(catalog.expand((e) => e.allMissions), hasLength(50));
    expect(catalog.map((e) => e.id), [
      for (var i = 1; i <= 12; i++) 'ep${i.toString().padLeft(2, '0')}',
    ]);

    final create = container.read(gameControllerProvider.notifier)
        .createDetective('Kim', DetectiveAvatar.boy);
    expect(create, isNull);
    expect(container.read(walletProvider).balance, AppConstants.startCoins);

    var expectedCoins = AppConstants.startCoins;
    for (var index = 0; index < catalog.length; index++) {
      final episode = catalog[index];
      var controller = container.read(gameControllerProvider.notifier);
      expect(controller.openEpisode(episode.id), isTrue, reason: episode.id);
      expect(container.read(currentEpisodeProvider).id, episode.id);
      expect(container.read(gameControllerProvider).completedMissionIds, isEmpty,
          reason: 'a new case begins with no completed missions: ${episode.id}');

      if (index + 1 < catalog.length) {
        expect(controller.openEpisode(catalog[index + 1].id), isFalse,
            reason: 'next case stays sealed until final: ${episode.id}');
      }

      controller.startInvestigation();
      for (final mission in episode.allMissions) {
        controller = container.read(gameControllerProvider.notifier);
        controller.markMissionStarted(mission.id);
        final outcome = controller.submitAnswer(mission, mission.answer);
        expect(outcome.result, SubmitResult.correct, reason: mission.id);
        final award = mission.isFinal
            ? AppConstants.finalCoins
            : AppConstants.missionCoins;
        expect(outcome.coins, award, reason: mission.id);
        expectedCoins += award;
        expect(container.read(walletProvider).balance, expectedCoins,
            reason: 'wallet after ${mission.id}');
        expect(container.read(gameControllerProvider).isCompleted(mission.id),
            isTrue, reason: mission.id);

        final again = controller.submitAnswer(mission, mission.answer);
        expect(again.result, SubmitResult.correct, reason: mission.id);
        expect(again.coins, 0, reason: 'no duplicate reward for ${mission.id}');
        expect(container.read(walletProvider).balance, expectedCoins);
      }

      final progress = container.read(gameControllerProvider);
      expect(progress.isCaseSolved, isTrue, reason: episode.id);
      expect(progress.completedMissionIds, hasLength(episode.allMissions.length));
      expect(progress.collectedEvidence(episode),
          hasLength(episode.allEvidence.length), reason: episode.id);
      expect(container.read(seasonProvider).isSolved(episode.id), isTrue);

      // Recreate providers with the SAME persisted SharedPreferences.
      final prefs = container.read(sharedPreferencesProvider);
      final previous = container;
      container = ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      previous.dispose();
      expect(container.read(currentEpisodeProvider).id, episode.id,
          reason: 'resume active case: ${episode.id}');
      expect(container.read(gameControllerProvider).isCaseSolved, isTrue,
          reason: 'resume completed case: ${episode.id}');
      expect(container.read(walletProvider).balance, expectedCoins,
          reason: 'resume wallet after ${episode.id}');
    }

    expect(expectedCoins,
        AppConstants.startCoins +
            38 * AppConstants.missionCoins +
            12 * AppConstants.finalCoins);
    expect(container.read(seasonProvider).solvedEpisodeIds,
        [for (final e in catalog) e.id]);
  });

  test('debug ad completion is credited once; missing funds cannot buy tip', () async {
    final container = ProviderContainer(overrides: await testOverrides());
    addTearDown(container.dispose);
    final wallet = container.read(walletProvider.notifier);
    final firstMission = container.read(currentEpisodeProvider).missions.first;
    expect(container.read(walletProvider).balance, AppConstants.startCoins);
    expect(wallet.unlockTip(firstMission, 2), TipUnlock.paid);
    expect(container.read(walletProvider).balance, 0);

    final secondMission = container.read(currentEpisodeProvider).missions[1];
    expect(wallet.unlockTip(secondMission, 2), TipUnlock.insufficientCoins);
    expect(container.read(walletProvider).ownsTip(secondMission.id, 2), isFalse);
    expect(wallet.rewardCompletedAd('test-completed-event'), 20);
    expect(wallet.rewardCompletedAd('test-completed-event'), 0);
    expect(container.read(walletProvider).balance, 20);
    expect(wallet.unlockTip(secondMission, 2), TipUnlock.paid);
    expect(container.read(walletProvider).balance, 0);
  });
}
