import '../models/game_progress.dart';
import '../models/profile.dart';
import '../models/season_progress.dart';
import '../models/wallet.dart';
import 'outbox.dart';

/// What may ever leave the device for a live cloud. Nothing is sent yet
/// (there is no server); a sender must ask here first.
///
/// Operator (playtest) data is kept apart record by record: a case run, a
/// solved case in the season record, a coin entry. Normal play next to it is
/// still sent. A whole profile stays on the device when it is a guest, when
/// it was set up by the operator tools before records carried their origin
/// (Phase 1 `origin: playtest` — its records cannot be told apart, so none of
/// them is treated as normal), or while it waits for a review.
abstract final class SyncPolicy {
  /// A build with operator tools (debug, `LM_PLAYTEST`) never sends to the
  /// live cloud, whatever its data (it may use a development backend).
  static bool buildMayUseLiveCloud({required bool operatorToolsInBuild}) => !operatorToolsInBuild;

  static bool profileMayUpload(DetectiveProfile profile) => profile.syncable;

  /// The events of [outbox] that may be sent now.
  static List<OutboxEvent> uploadable(
    Outbox outbox,
    DetectiveProfile profile, {
    required bool operatorToolsInBuild,
  }) {
    if (!buildMayUseLiveCloud(operatorToolsInBuild: operatorToolsInBuild) || !profileMayUpload(profile)) return const [];
    return [for (final e in outbox.pending) if (!e.playtest && e.profileId == profile.id) e];
  }

  /// A case save as it may be sent, or null when it is operator data.
  static Map<String, dynamic>? caseForUpload(GameProgress progress) => progress.playtest ? null : progress.toJson();

  /// The season record as it may be sent: cases solved only as operator data
  /// are left out.
  static Map<String, dynamic> seasonForUpload(SeasonProgress season) => SeasonProgress(
        activeEpisodeId: season.activeEpisodeId,
        solvedEpisodeIds: [
          for (final id in season.solvedEpisodeIds)
            if (!season.playtestEpisodeIds.contains(id)) id,
        ],
      ).toJson();

  static bool entryMayUpload(CoinEntry entry) => !entry.playtest;
}
