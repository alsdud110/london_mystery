/// Rewarded-ad integration boundary. No ad SDK is shipped yet.
///
/// A production adapter should initialize the approved child-safe ad SDK,
/// load a rewarded placement, and invoke the reward handler ONLY after the
/// SDK reports a completed, earned reward. Never reward on tap, load, close,
/// failure, or cancellation. Configure platform app IDs, placement IDs,
/// child-directed treatment, and consent/privacy policy before enabling.
abstract interface class RewardedAdGateway {
  bool get isAvailable;

  /// Returns an event identifier only for a completed, earned reward.
  /// Null means unavailable, cancelled, failed, or not earned.
  Future<String?> showAndEarnReward();
}

/// Safe default: no ad shown and no coins earned.
final class DisabledRewardedAdGateway implements RewardedAdGateway {
  const DisabledRewardedAdGateway();

  @override
  bool get isAvailable => false;

  @override
  Future<String?> showAndEarnReward() async => null;
}
