import 'package:flutter/foundation.dart';

import '../../core/cloud/cloud_bootstrap.dart';
import '../../data/models/profile.dart';
import '../account/account_controller.dart';
import '../account/consent.dart';

/// Why a profile does not sync now. Checked in this order.
enum SyncBlock {
  /// Firebase is off for this build, or did not start with the expected
  /// project (see `CloudDecision`, `CloudBootstrap`).
  cloudUnavailable,

  /// Nobody is signed in.
  signedOut,

  /// The account's consent is not confirmed: no upload, no download.
  consentNotConfirmed,

  /// An account deletion has started (locally or on the server).
  deletionInProgress,

  /// The guest of this device: never uploaded automatically.
  guestProfile,

  /// A profile of another account (never opened for this one anyway).
  otherAccount,

  /// Set up by the operator tools (Phase 1 `origin: playtest`): test data.
  operatorProfile,

  /// Found again after a damaged profile list: waits for a review.
  needsReview,
}

/// The result of [SyncGate.check].
@immutable
class SyncGateResult {
  const SyncGateResult.open(String this.uid) : block = null;

  const SyncGateResult.closed(SyncBlock this.block) : uid = null;

  final SyncBlock? block;

  /// The account the sync may run for (only when open).
  final String? uid;

  bool get open => block == null;
}

/// Whether a profile may sync with the cloud now: every condition at once.
/// Pure (all inputs given), so each one is tested on its own.
abstract final class SyncGate {
  static SyncGateResult check({
    required CloudStatus cloud,
    required AccountState account,
    required DetectiveProfile profile,
    required bool deletionInProgress,
  }) {
    if (cloud != CloudStatus.ready) return const SyncGateResult.closed(SyncBlock.cloudUnavailable);
    final uid = account.uid;
    if (uid == null) return const SyncGateResult.closed(SyncBlock.signedOut);
    if (account.consent != ConsentStatus.confirmed || !account.cloudFeaturesAllowed) {
      return const SyncGateResult.closed(SyncBlock.consentNotConfirmed);
    }
    if (deletionInProgress) return const SyncGateResult.closed(SyncBlock.deletionInProgress);
    if (profile.kind == ProfileKind.guest || profile.ownerUid == null) {
      return const SyncGateResult.closed(SyncBlock.guestProfile);
    }
    if (profile.ownerUid != uid) return const SyncGateResult.closed(SyncBlock.otherAccount);
    if (profile.origin == ProfileOrigin.playtest) return const SyncGateResult.closed(SyncBlock.operatorProfile);
    if (profile.needsReview) return const SyncGateResult.closed(SyncBlock.needsReview);
    assert(profile.syncable);
    return SyncGateResult.open(uid);
  }
}

/// One sync run, bound to the account and profile it started for. The
/// sender asks [stillValid] before every write and before applying anything
/// it read: after a sign-out, another sign-in, a consent change, a deletion
/// or a profile switch the run stops, and nothing of it reaches the new
/// account (its claimed events are released, not acknowledged).
@immutable
class SyncRun {
  const SyncRun({required this.uid, required this.profileId});

  /// Starts a run when [gate] is open.
  static SyncRun? start(SyncGateResult gate, DetectiveProfile profile) =>
      gate.open ? SyncRun(uid: gate.uid!, profileId: profile.id) : null;

  final String uid;
  final String profileId;

  bool stillValid({
    required CloudStatus cloud,
    required AccountState account,
    required DetectiveProfile activeProfile,
    required bool deletionInProgress,
  }) {
    if (activeProfile.id != profileId) return false;
    final gate = SyncGate.check(
      cloud: cloud,
      account: account,
      profile: activeProfile,
      deletionInProgress: deletionInProgress,
    );
    return gate.open && gate.uid == uid;
  }
}
