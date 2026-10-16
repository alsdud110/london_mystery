import 'package:flutter/foundation.dart';

import '../../models/game_progress.dart';
import '../../models/wallet.dart';
import '../../repositories/progress_repository.dart';
import '../case_conflicts.dart';
import '../merge.dart';
import '../outbox.dart';
import '../sync_applier.dart';
import 'cloud_codec.dart';
import 'cloud_store.dart';

// Phase 4.4: bringing a profile's cloud records down to this device (a new
// device, or what another device sent since). Two steps, so that nothing is
// half-restored:
// 1. [SyncRestorer.download] reads every record of the profile and checks
//    each one (the codec's checks, against the server's epoch). One record
//    that is not valid stops the restore: nothing is applied.
// 2. [SyncRestorer.apply] merges what was read into the device's saves in
//    one save (all of it or none), with the merge rules of the sender. Local
//    play is never lost: a case whose two runs cannot both be kept is held
//    while the device has play of it not sent yet (kept as a conflict, the
//    device's save unchanged); otherwise the rule's winner plays on and the
//    other run is kept (Phase 4.5). A coin entry with another amount is held
//    (the device's entry stays).

/// A profile's records on the server, read and checked.
@immutable
class CloudProfileState {
  const CloudProfileState({this.meta, this.cases = const {}, this.season, this.wallet, this.walletVersion});

  /// Nothing synced yet (no sync/meta): nothing to restore.
  static const empty = CloudProfileState();

  /// The server's epoch and its version; null when the profile was never synced.
  final CloudMeta? meta;

  /// The cases of the server's epoch (earlier epochs are left out).
  final Map<String, CloudAccepted<CaseSnapshot>> cases;
  final CloudAccepted<SeasonSnapshot>? season;

  /// The coins of the server's epoch (null: none there).
  final Wallet? wallet;
  final int? walletVersion;
}

/// What a download found.
sealed class CloudDownload {
  const CloudDownload();
}

final class DownloadOk extends CloudDownload {
  const DownloadOk(this.state);

  final CloudProfileState state;
}

/// A record is not valid: nothing may be applied (never corrected).
final class DownloadInvalid extends CloudDownload {
  const DownloadInvalid(this.rejected);

  final List<CloudRejected<void>> rejected;
}

/// The records changed while they were read (another device wrote, e.g. a
/// reset): read them again.
final class DownloadChanged extends CloudDownload {
  const DownloadChanged();
}

/// What [SyncRestorer.apply] did to the device's saves.
@immutable
class RestoreApplied {
  const RestoreApplied({
    this.restored = const [],
    this.held = const [],
    this.adoptedEpoch,
    this.localAhead = false,
  });

  /// Subjects whose saves now hold the server's record (`case:<id>`,
  /// `season`, `wallet`), merged with the device's own play.
  final List<String> restored;

  /// Subjects left as they were on the device and kept as conflicts.
  final List<String> held;

  /// The server was at a later epoch (a New Adventure elsewhere): the device
  /// moved to it, its own saves kept as a conflict first.
  final int? adoptedEpoch;

  /// The device is at a later epoch than the server (its reset is not sent
  /// yet): nothing of the server's earlier epoch is applied.
  final bool localAhead;
}

abstract final class SyncRestorer {
  /// Reads every record of the profile at [paths] and checks them. Throws
  /// [CloudStoreException] when the server cannot be read (nothing changes).
  static Future<CloudDownload> download(CloudStore store, SyncPaths paths, CloudCodec codec) async {
    final rawMeta = await store.get(paths.meta);
    // No sync/meta: the rules let no case, season or coin be written before
    // it, so there is nothing to restore.
    if (rawMeta == null) return const DownloadOk(CloudProfileState.empty);
    final CloudMeta meta;
    switch (codec.readMeta(rawMeta)) {
      case CloudAccepted<CloudMeta>(:final value):
        meta = value;
      case CloudRejected<CloudMeta>(:final subject, :final reasons):
        return DownloadInvalid([CloudRejected(subject, reasons)]);
      case CloudStale<CloudMeta>():
        throw StateError('a meta document has no earlier epoch');
    }
    final epoch = meta.epoch;
    final rawCases = await store.list(paths.cases);
    final rawSeason = await store.get(paths.season);
    final rawWallet = await store.list(paths.wallet);

    final rejected = <CloudRejected<void>>[];
    final cases = <String, CloudAccepted<CaseSnapshot>>{};
    for (final MapEntry(key: id, value: doc) in rawCases.entries) {
      switch (codec.readCase(id, doc, serverEpoch: epoch)) {
        case final CloudAccepted<CaseSnapshot> c:
          cases[id] = c;
        case CloudRejected<CaseSnapshot>(:final subject, :final reasons):
          rejected.add(CloudRejected(subject, reasons));
        case CloudStale<CaseSnapshot>():
          break; // an earlier epoch: not restored
      }
    }
    CloudAccepted<SeasonSnapshot>? season;
    if (rawSeason != null) {
      switch (codec.readSeason(rawSeason, serverEpoch: epoch)) {
        case final CloudAccepted<SeasonSnapshot> s:
          season = s;
        case CloudRejected<SeasonSnapshot>(:final subject, :final reasons):
          rejected.add(CloudRejected(subject, reasons));
        case CloudStale<SeasonSnapshot>():
          break;
      }
    }
    final w = codec.readWallet(rawWallet, serverEpoch: epoch);
    // Problems of an earlier epoch's coins do not stop the current wallet.
    if (!w.accepted) rejected.addAll(w.rejected);

    // The epoch everything was read against must still be the server's: a
    // New Adventure made meanwhile changes sync/meta (its epoch and version),
    // and the records read before it must not be restored. Checked after
    // every download, so a reset in between is always read again. (A record
    // rejected only because it changed meanwhile is caught here too.)
    final again = await store.get(paths.meta);
    final now = again == null ? null : codec.readMeta(again);
    if (now is! CloudAccepted<CloudMeta> || now.value.epoch != epoch || now.value.cloudVersion != meta.cloudVersion) {
      return const DownloadChanged();
    }
    if (rejected.isNotEmpty) return DownloadInvalid(rejected);
    final hasCoins = w.wallet.entries.isNotEmpty;
    // The server lists coins by document id: back in the order they were made.
    final made = [...w.wallet.entries]
      ..sort((a, b) {
        final t = (a.at ?? DateTime(0)).compareTo(b.at ?? DateTime(0));
        return t != 0 ? t : a.key.compareTo(b.key);
      });
    return DownloadOk(CloudProfileState(
      meta: meta,
      cases: cases,
      season: season,
      wallet: hasCoins ? made.fold<Wallet>(Wallet.empty, (w, e) => w.adding(e)) : null,
      walletVersion: hasCoins ? w.summaryVersion : null,
    ));
  }

  /// Merges [state] into the saves of [repo], in one save. Nothing is
  /// applied unless [isStillValid] (the run's account, profile and session)
  /// holds; it is synchronous, so it holds throughout. A version is recorded
  /// (`CloudSyncMeta.merged`) only for what was merged without a conflict;
  /// the device's own changes keep their place in the queue and back-off.
  static RestoreApplied apply(
    SharedPrefsProgressRepository repo,
    CloudProfileState state, {
    required List<String> episodeIds,
    required bool Function() isStillValid,
  }) {
    final meta = state.meta;
    if (meta == null || !isStillValid()) return const RestoreApplied();
    final epoch = meta.epoch;
    if (repo.epoch > epoch) return const RestoreApplied(localAhead: true);
    final restored = <String>[];
    final held = <String>[];
    int? adopted;
    repo.transaction(() {
      if (epoch > repo.epoch) {
        repo.adoptEpoch(epoch, episodeIds: episodeIds);
        adopted = epoch;
      }
      repo.updateCloudSync((m) => m.merged('meta', cloudVersion: meta.cloudVersion, epoch: epoch));
      final applier = SyncApplier(repo, episodeIds: episodeIds);
      for (final MapEntry(key: id, value: cloud) in state.cases.entries) {
        final subject = 'case:$id';
        final local = repo.load(id);
        final m = mergeCase(CaseSnapshot(epoch: epoch, progress: local), cloud.value);
        // Two runs that cannot both be kept. With play of this device not
        // sent yet, the device's play stays as it is and the server's run is
        // kept beside it (the sender meets it next, with the same rule). With
        // nothing unsent, the rule's winner is taken — the same one on every
        // device (Phase 4.5) — and the other run kept: nothing is lost
        // either way, and the player may still choose.
        final unsent = repo.outbox.events.any((e) => e.kind == OutboxKind.caseRun && e.subject == id);
        if (m.outcome == MergeOutcome.conflict && unsent) {
          repo.keepConflict(_heldCase(id, cloud.value.progress, cloud.cloudVersion, m.reason, epoch));
          held.add(subject);
          continue;
        }
        applier.applyCase(id, cloud.value);
        // A choice made here that the server already has (Phase 4.5).
        CaseConflicts.noteOnServer(repo, id, cloud.value.progress.runId);
        repo.updateCloudSync((x) => x.merged(subject, cloudVersion: cloud.cloudVersion, epoch: epoch));
        restored.add(subject);
      }
      if (state.season case final season?) {
        applier.applySeason(epoch, season.value.season);
        repo.updateCloudSync((x) => x.merged('season', cloudVersion: season.cloudVersion, epoch: epoch));
        restored.add('season');
      }
      if (state.wallet case final wallet?) {
        // The same key with another amount: the local entry stays, kept as
        // a conflict (no balance is changed for it).
        if (applier.applyWallet(epoch, wallet) == MergeOutcome.conflict) {
          held.add('wallet');
        } else {
          if (state.walletVersion case final v?) {
            repo.updateCloudSync((x) => x.merged('wallet', cloudVersion: v, epoch: epoch));
          }
          restored.add('wallet');
        }
      }
    });
    return RestoreApplied(restored: restored, held: held, adoptedEpoch: adopted);
  }

  static Map<String, dynamic> _heldCase(String id, GameProgress cloud, int cloudVersion, String reason, int epoch) => {
        'id': 'restoreHeld:case:$id:${cloud.runId}:${cloud.runSeq}:$cloudVersion',
        'kind': 'restoreHeld',
        'subject': 'case:$id',
        'reason': reason,
        'cloud': cloud.toJson(),
        'cloudVersion': cloudVersion,
        // Record v2 (Phase 4.5): a case file for the player to choose.
        'v': 2,
        'caseId': id,
        'runId': cloud.runId,
        'runSeq': cloud.runSeq,
        'side': FileSide.account.name,
        'epoch': epoch,
        'at': DateTime.now().toUtc().toIso8601String(),
        'status': ConflictStatus.open.name,
      };
}
