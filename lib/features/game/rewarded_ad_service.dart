import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'rewarded_ad_gateway.dart';
import 'wallet_controller.dart';

/// Default is deliberately disabled until an approved rewarded-ad SDK is wired.
final rewardedAdGatewayProvider = Provider<RewardedAdGateway>(
  (ref) => kDebugMode
      ? SimulatedRewardedAdGateway()
      : const DisabledRewardedAdGateway(),
);

enum RewardedAdStatus { unavailable, notEarned, earned }

class RewardedAdOutcome {
  const RewardedAdOutcome(this.status, {this.coins = 0});

  final RewardedAdStatus status;
  final int coins;
}

/// Single entry point for the UI. Only an earned callback can credit coins.
/// Production adapters must supply a stable, unique reward event ID.
/// Client-only IDs are not fraud-proof; server-side verification is recommended.
final rewardedAdServiceProvider = Provider<RewardedAdService>(
  (ref) => RewardedAdService(ref),
);

class RewardedAdService {
  const RewardedAdService(this.ref);

  final Ref ref;

  Future<RewardedAdOutcome> showAndReward() async {
    final gateway = ref.read(rewardedAdGatewayProvider);
    if (!gateway.isAvailable) {
      return const RewardedAdOutcome(RewardedAdStatus.unavailable);
    }
    final rewardId = await gateway.showAndEarnReward();
    if (rewardId == null || rewardId.trim().isEmpty) {
      return const RewardedAdOutcome(RewardedAdStatus.notEarned);
    }
    final coins = ref.read(walletProvider.notifier).rewardCompletedAd(rewardId);
    return RewardedAdOutcome(RewardedAdStatus.earned, coins: coins);
  }
}
