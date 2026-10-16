
import '../models/game_progress.dart';
import '../models/season_progress.dart';
import '../models/wallet.dart';
import '../repositories/progress_repository.dart';
import 'case_conflicts.dart';
import 'merge.dart';

/// Brings saves from another copy of the same profile (later: the cloud)
/// into this device's saves with the merge rules (see `merge.dart`).
///
/// - Applying the same data again changes nothing: no coin is paid or
///   charged twice, no event is queued twice.
/// - What the rules cannot decide is kept as a conflict, never overwritten.
/// - Only a result the other side does not have yet is queued to be sent.
///
/// Not used by the game yet (no server). It works on the saves: run it
/// before a game session opens the profile, or open the session again after.
class SyncApplier {
  SyncApplier(this.repo, {required this.episodeIds});

  final SharedPrefsProgressRepository repo;

  /// Every case of the season (to keep their saves on an epoch change).
  final List<String> episodeIds;

  /// The other side is at a later epoch (reset elsewhere): this side moves
  /// to it, keeping its own saves as a conflict first. Returns false when
  /// the other side is behind (its data is then ignored).
  bool _catchUp(int remoteEpoch) {
    if (remoteEpoch < repo.epoch) return false;
    repo.adoptEpoch(remoteEpoch, episodeIds: episodeIds);
    return true;
  }

  /// [remotePreserved]: a run of the other side that already lost to ours
  /// (in the sender's transaction), to be kept here too.
  MergeOutcome applyCase(String episodeId, CaseSnapshot remote, {GameProgress? remotePreserved, String? remoteReason}) {
    if (!_catchUp(remote.epoch)) return MergeOutcome.keptLocal;
    final local = CaseSnapshot(epoch: repo.epoch, progress: repo.load(episodeId));
    final m = mergeCase(local, remote);
    final now = DateTime.now();
    repo.transaction(() {
      void keep(GameProgress p, FileSide side, String reason) => repo.keepConflict(CaseConflicts.caseRecord(
            caseId: episodeId,
            run: p,
            side: side,
            epoch: repo.epoch,
            reason: reason,
            at: now,
          ));
      if (m.preserved case final p?) {
        keep(p, identical(p, local.progress) ? FileSide.device : FileSide.account, m.reason);
      }
      if (remotePreserved != null && !isBlankRun(remotePreserved)) {
        keep(remotePreserved, FileSide.account, remoteReason ?? CaseConflicts.reasonSameNumber);
      }
      // Ours unchanged (same, kept, or a conflict we win): nothing to store;
      // our own changes are already queued. Theirs taken: stored, not sent
      // back. Combined: stored and queued (they lack part of it).
      if (!identical(m.merged, local.progress)) {
        repo.saveMerged(episodeId: episodeId, progress: m.merged, queue: m.outcome == MergeOutcome.combined);
      }
      CaseConflicts.settle(repo, episodeId, now: now);
    });
    return m.outcome;
  }

  MergeOutcome applySeason(int remoteEpoch, SeasonProgress remote) {
    if (!_catchUp(remoteEpoch)) return MergeOutcome.keptLocal;
    final m = mergeSeason(
      SeasonSnapshot(epoch: repo.epoch, season: repo.loadSeason()),
      SeasonSnapshot(epoch: remoteEpoch, season: remote),
    );
    if (m.outcome != MergeOutcome.same) {
      repo.saveMerged(season: m.merged, queue: m.outcome != MergeOutcome.tookRemote);
    }
    return m.outcome;
  }

  /// Applies the other side's coin entries. Different amounts under one key
  /// are kept as conflicts; the local entry and the balance stay as they are.
  MergeOutcome applyWallet(int remoteEpoch, Wallet remote) {
    if (!_catchUp(remoteEpoch)) return MergeOutcome.keptLocal;
    final local = repo.loadWallet() ?? Wallet.empty;
    final m = mergeWallet(
      WalletSnapshot(epoch: repo.epoch, wallet: local),
      WalletSnapshot(epoch: remoteEpoch, wallet: remote),
    );
    repo.transaction(() {
      for (final c in m.conflicts) {
        repo.keepConflict({
          'id': 'wallet:${c.key}:${c.local.amount}:${c.remote.amount}',
          'kind': 'wallet',
          'subject': c.key,
          'reason': 'same key, different amount',
          'local': c.local.toJson(),
          'remote': c.remote.toJson(),
          // Shown and kept only: no balance is changed for it (Phase 4.5).
          'v': 2,
          'epoch': repo.epoch,
          'at': DateTime.now().toUtc().toIso8601String(),
          'status': 'open',
        });
      }
      // Entries only the other side had are stored; they came from there,
      // so they are not queued back. Ours that it lacks stay queued.
      if (canonicalJson(m.merged.toJson()) != canonicalJson(local.toJson())) {
        repo.saveMerged(wallet: m.merged, queue: false);
      }
    });
    return m.outcome;
  }
}
