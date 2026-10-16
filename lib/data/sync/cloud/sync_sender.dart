import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../models/game_progress.dart';
import '../../models/season_progress.dart';
import '../../models/wallet.dart';
import '../../repositories/progress_repository.dart';
import '../case_conflicts.dart';
import '../merge.dart';
import '../outbox.dart';
import '../sync_applier.dart';
import 'cloud_codec.dart';
import 'cloud_store.dart';
import 'sync_retry_policy.dart';

/// Why a run stopped before the end.
enum SyncStop {
  /// The Sync Gate closed (sign-out, another account, consent, deletion,
  /// another profile). Claimed events were released; nothing of the run is
  /// applied to the device.
  runNoLongerValid,

  /// The rules refused because the account's consent is not confirmed.
  consentNotConfirmed,

  /// The rules refused because an account deletion has started.
  deletionInProgress,

  /// The server's sync/meta is not valid: kept as a conflict, nothing sent.
  invalidServerMeta,

  /// The epoch could not be brought in line (no connection, a refusal of
  /// the rules): nothing else is sent this run (counted, backed off).
  cloudUnavailable,
}

/// What one run did.
@immutable
class SyncReport {
  const SyncReport({
    this.sent = const [],
    this.conflicted = const [],
    this.failed = const [],
    this.stalled = const [],
    this.adoptedEpoch,
    this.stop,
  });

  /// Subjects written (or found already there) and confirmed.
  final List<String> sent;

  /// Subjects kept as permanent conflicts (never retried automatically).
  final List<String> conflicted;

  /// Subjects that failed this run (released, backed off).
  final List<String> failed;

  /// Subjects that stalled this run (too many failures in a row).
  final List<String> stalled;

  /// The server was at a later epoch (a reset elsewhere): the device moved
  /// to it (its own saves kept as a conflict first).
  final int? adoptedEpoch;

  final SyncStop? stop;
}

class _Stop implements Exception {
  const _Stop(this.reason);

  final SyncStop reason;
}

/// Sends a profile's queued changes to the cloud (Phase 4.3A).
///
/// - The reset epoch goes first (`sync/meta`, one step at a time); a server
///   at a later epoch is adopted, an earlier epoch is never written.
/// - Each case and the season: a transaction reads the server's copy, merges
///   it with the local save when it is not the version we last confirmed,
///   and writes the result as cloudVersion + 1. Up to
///   [SyncRetryPolicy.maxRoundsPerRun] rounds; then back-off, and a stall
///   after too many failed runs.
/// - Each coin entry: its event (`{epoch}_{key}`) and the summary are
///   written together; an event already there with the same amount is just
///   confirmed; another amount is a permanent conflict; a balance below
///   zero is never written.
/// - A transaction's body only reads, decides and writes to the server: the
///   device is changed once, after the commit ([SyncApplier] merge, the
///   confirmed version, the acknowledgement — in one save).
/// - [isStillValid] (the Sync Gate, see `SyncRun`) is asked before every
///   transaction and after every commit: when it fails, the run stops,
///   claimed events are released, and nothing is applied to the device. A
///   commit that may have happened is reconciled by the next run (its base
///   version is then not ours, so it merges with the server first).
/// - An unclear failure never drops a queued change.
class SyncSender {
  SyncSender({
    required this.store,
    required this.repo,
    required this.codec,
    required this.paths,
    required this.episodeIds,
    required this.isStillValid,
    this.policy = SyncRetryPolicy.standard,
    this.onApplied,
    DateTime Function()? now,
    math.Random? random,
  })  : _now = now ?? DateTime.now,
        _random = random ?? math.Random();

  final CloudStore store;
  final SharedPrefsProgressRepository repo;
  final CloudCodec codec;
  final SyncPaths paths;
  final List<String> episodeIds;
  final bool Function() isStillValid;
  final SyncRetryPolicy policy;

  /// Told right after the device's saves were changed from the server
  /// (`case:<id>`, `season`, or `epoch` after a reset elsewhere), in the
  /// same synchronous step, so what is on screen is read again before the
  /// game can save over it. Only while [isStillValid].
  final void Function(String subject)? onApplied;

  final DateTime Function() _now;
  final math.Random _random;

  final _sent = <String>[];
  final _conflicted = <String>[];
  final _failed = <String>[];
  final _stalled = <String>[];
  int? _adopted;

  /// At app start, before the first run: stalled subjects get one more
  /// chance through a full resync; conflicts stay as they are.
  static void prepareAtStart(SharedPrefsProgressRepository repo) {
    if (!repo.cloudSync.anyStalled) return;
    repo.transaction(() {
      repo.updateCloudSync((m) => m.atStart());
      repo.updateOutbox((o) => o.resumeStalled());
    });
  }

  Future<SyncReport> run() async {
    SyncReport report([SyncStop? stop]) => SyncReport(
          sent: List.unmodifiable(_sent),
          conflicted: List.unmodifiable(_conflicted),
          failed: List.unmodifiable(_failed),
          stalled: List.unmodifiable(_stalled),
          adoptedEpoch: _adopted,
          stop: stop,
        );
    try {
      _check();
      // The epoch first; if the server moves under us, once more.
      for (var attempt = 0; attempt < 2; attempt++) {
        final epoch = await _syncEpoch();
        try {
          await _syncSubjects(epoch);
          return report();
        } on _EpochMoved {
          continue;
        }
      }
      return report();
    } on _Stop catch (s) {
      return report(s.reason);
    }
  }

  void _check() {
    if (!isStillValid()) throw const _Stop(SyncStop.runNoLongerValid);
  }

  // ---- epoch ----------------------------------------------------------------

  /// Brings the server's epoch up to ours (one step per write) or ours up to
  /// the server's. Returns the epoch both now share.
  Future<int> _syncEpoch() async {
    while (true) {
      _check();
      final local = repo.epoch;
      final ({int epoch, int version})? r;
      try {
        r = await store.runTransaction((tx) async {
          final raw = await tx.get(paths.meta);
          if (raw == null) {
            tx.set(paths.meta, codec.metaToCloud(epoch: 0, cloudVersion: 1).data!);
            return (epoch: 0, version: 1);
          }
          final read = codec.readMeta(raw);
          if (read is! CloudAccepted<CloudMeta>) return null;
          final m = read.value;
          if (m.epoch < local) {
            tx.set(paths.meta, codec.metaToCloud(epoch: m.epoch + 1, cloudVersion: m.cloudVersion + 1).data!);
            return (epoch: m.epoch + 1, version: m.cloudVersion + 1);
          }
          return (epoch: m.epoch, version: m.cloudVersion);
        });
      } on CloudStoreException catch (e) {
        await _onFailure(e, subject: 'meta', claimed: const []);
        throw const _Stop(SyncStop.cloudUnavailable);
      }
      if (r == null) {
        final raw = await store.get(paths.meta);
        if (raw != null) {
          final read = codec.readMeta(raw);
          if (read is CloudRejected<CloudMeta>) repo.keepConflict(read.conflictRecord());
        }
        throw const _Stop(SyncStop.invalidServerMeta);
      }
      _check();
      if (r.epoch > local) {
        // A reset elsewhere: this device follows (its saves kept as a conflict).
        repo.transaction(() {
          repo.adoptEpoch(r!.epoch, episodeIds: episodeIds);
          repo.updateCloudSync((m) => m.confirmed('meta', cloudVersion: r!.version, epoch: r.epoch));
        });
        _adopted = r.epoch;
        onApplied?.call('epoch');
        return r.epoch;
      }
      repo.updateCloudSync((m) => m.confirmed('meta', cloudVersion: r!.version, epoch: r.epoch));
      if (r.epoch == local) return local;
      // Stepped up by one; go on until it is ours.
    }
  }

  // ---- subjects -------------------------------------------------------------

  Future<void> _syncSubjects(int epoch) async {
    final meta = repo.cloudSync;
    final now = _now();
    final due = <String, List<OutboxEvent>>{};
    for (final e in repo.outbox.pending) {
      // This device's events of this profile (the cloud path may name the
      // same profile under another local id on another device).
      if (e.playtest || e.profileId != repo.profileId) continue;
      final subject = switch (e.kind) {
        OutboxKind.caseRun => 'case:${e.subject}',
        OutboxKind.season => 'season',
        OutboxKind.walletEntry => 'wallet',
      };
      if (!meta.isDue(subject, now)) continue;
      (due[subject] ??= []).add(e);
    }
    // A full resync (after a stall) also compares every case this device has
    // played and the season (cases it never played are restoring, Phase 4.4).
    if (meta.needsFullResync) {
      for (final id in episodeIds) {
        final p = repo.load(id);
        if (p.introSeen || p.completedMissionIds.isNotEmpty || p.startedAt != null) due.putIfAbsent('case:$id', () => []);
      }
      due.putIfAbsent('season', () => []);
    }
    for (final MapEntry(key: subject, value: events) in due.entries) {
      _check();
      if (subject == 'wallet') {
        await _syncWallet(events, epoch);
      } else {
        await _syncDocument(subject, events, epoch);
      }
    }
    if (meta.needsFullResync && _failed.isEmpty && _stalled.isEmpty) repo.updateCloudSync((m) => m.resynced());
  }

  List<String> _claim(List<OutboxEvent> events) {
    final ids = [for (final e in events) e.id];
    if (ids.isNotEmpty) repo.updateOutbox((o) => o.claim(ids));
    return ids;
  }

  void _release(List<String> ids) {
    if (ids.isNotEmpty) repo.updateOutbox((o) => o.release(ids));
  }

  /// A case (`case:<id>`) or the season.
  Future<void> _syncDocument(String subject, List<OutboxEvent> events, int epoch) async {
    final isSeason = subject == 'season';
    final caseId = isSeason ? null : subject.substring('case:'.length);
    final path = isSeason ? paths.season : paths.caseDoc(caseId!);
    final claimed = _claim(events);
    for (var round = 1; round <= policy.maxRoundsPerRun; round++) {
      try {
        _check();
      } on _Stop {
        _release(claimed);
        rethrow;
      }
      // A snapshot of the device, read before the transaction (never changed
      // inside it).
      final base = repo.cloudSync.of(subject).confirmedVersion;
      final localCase = isSeason ? null : repo.load(caseId!);
      final localSeason = isSeason ? repo.loadSeason() : null;
      final _Result r;
      try {
        r = await store.runTransaction((tx) async {
          final serverEpoch = await _serverEpoch(tx);
          if (serverEpoch != epoch) return const _EpochMovedResult();
          final raw = await tx.get(path);
          var version = 1;
          Object next = isSeason ? localSeason! : localCase!;
          CaseMerge? caseMerge;
          if (raw != null) {
            final read = isSeason
                ? codec.readSeason(raw, serverEpoch: serverEpoch)
                : codec.readCase(caseId!, raw, serverEpoch: serverEpoch);
            switch (read) {
              case CloudRejected(:final subject, :final reasons):
                return _Invalid(CloudRejected(subject, reasons));
              case CloudStale(:final cloudVersion):
                version = cloudVersion! + 1; // an earlier epoch's doc: replaced
              case CloudAccepted(:final value, :final cloudVersion):
                version = cloudVersion + 1;
                if (cloudVersion != base) {
                  // Not the version we last confirmed: merge with it first.
                  if (isSeason) {
                    next = mergeSeason(SeasonSnapshot(epoch: epoch, season: localSeason!), value as SeasonSnapshot).merged;
                  } else {
                    caseMerge = mergeCase(CaseSnapshot(epoch: epoch, progress: localCase!), value as CaseSnapshot);
                    next = caseMerge.merged;
                  }
                }
            }
          }
          final w = isSeason
              ? codec.seasonToCloud(season: next as SeasonProgress, epoch: epoch, cloudVersion: version)
              : codec.caseToCloud(caseId: caseId!, progress: next as GameProgress, epoch: epoch, cloudVersion: version);
          if (!w.ok) return _Skipped(w.skip!);
          tx.set(path, w.data!);
          // The server's run that lost to ours (it is overwritten now): kept
          // on this device too (Phase 4.5).
          final lost = caseMerge?.preserved;
          return _Written(next, version,
              serverRun: lost == null || identical(lost, localCase) ? null : lost, reason: caseMerge?.reason);
        });
      } on CloudStoreException catch (e) {
        if (e.failure == CloudFailure.aborted && round < policy.maxRoundsPerRun) continue;
        await _onFailure(e, subject: subject, claimed: claimed, kind: _kindOf(subject), name: _nameOf(subject));
        return;
      }
      // Committed (or decided without writing). The device changes only now.
      if (!isStillValid()) {
        _release(claimed);
        throw const _Stop(SyncStop.runNoLongerValid);
      }
      switch (r) {
        case _Written(:final next, :final version, :final serverRun, :final reason):
          repo.transaction(() {
            final applier = SyncApplier(repo, episodeIds: episodeIds);
            if (isSeason) {
              applier.applySeason(epoch, next! as SeasonProgress);
            } else {
              final sent = next! as GameProgress;
              applier.applyCase(caseId!, CaseSnapshot(epoch: epoch, progress: sent),
                  remotePreserved: serverRun, remoteReason: reason);
              // A choice between two case files is done once the server has it.
              CaseConflicts.noteOnServer(repo, caseId, sent.runId);
            }
            repo.updateCloudSync((m) => m.confirmed(subject, cloudVersion: version, epoch: epoch));
            repo.updateOutbox((o) => o.ack(claimed));
          });
          onApplied?.call(subject);
          _sent.add(subject);
          return;
        case _EpochMovedResult():
          _release(claimed);
          throw const _EpochMoved();
        case _Invalid(:final rejected):
          _conflict(rejected.conflictRecord(), subject, claimed);
          return;
        case _Skipped(:final skip):
          if (skip == CloudSkip.outOfShape) {
            _conflict({'id': 'localShape:$subject', 'kind': 'localShape', 'subject': subject, 'reason': 'does not fit the cloud'},
                subject, claimed);
          } else {
            repo.updateOutbox((o) => o.ack(claimed)); // operator data / not shipped: never sent
          }
          return;
        default:
          _release(claimed);
          return;
      }
    }
    await _fail(subject, claimed, kind: _kindOf(subject), name: _nameOf(subject));
  }

  /// The coin entries, one at a time, in the order they were made.
  Future<void> _syncWallet(List<OutboxEvent> events, int epoch) async {
    for (final event in events) {
      final claimed = _claim([event]);
      final entry = switch (event.payload) {
        final Map<String, dynamic> p => CoinEntry.fromJson(p),
        _ => null,
      };
      if (entry == null || event.epoch != epoch) {
        // Unreadable, or of an earlier epoch (its saves were kept when it
        // ended): nothing to send.
        repo.updateOutbox((o) => o.ack(claimed));
        continue;
      }
      final w = codec.eventToCloud(entry, epoch: epoch);
      if (!w.ok) {
        if (w.skip == CloudSkip.operatorData) {
          repo.updateOutbox((o) => o.ack(claimed));
        } else {
          _conflict({'id': 'localShape:wallet:${entry.key}', 'kind': 'localShape', 'subject': 'wallet:${entry.key}', 'reason': 'not a coin of the game'},
              'wallet:${entry.key}', claimed);
        }
        continue;
      }
      final id = CloudCodec.eventId(epoch, entry.key);
      _Result? r;
      for (var round = 1; round <= policy.maxRoundsPerRun && r == null; round++) {
        try {
          _check();
        } on _Stop {
          _release(claimed);
          rethrow;
        }
        try {
          r = await store.runTransaction((tx) async {
            final serverEpoch = await _serverEpoch(tx);
            if (serverEpoch != epoch) return const _EpochMovedResult();
            final existing = await tx.get(paths.walletEvent(id));
            final summary = await tx.get(paths.walletSummary);
            if (existing != null) {
              // Sent before (maybe the answer was lost): never a second grant.
              final read = codec.readEvent(id, existing, serverEpoch: serverEpoch);
              if (read is CloudAccepted<CoinEntry>) {
                if (read.value.amount != entry.amount) return _Mismatch(read.value.amount);
                // Confirmed only with a valid summary of this epoch (the rules
                // write them together); anything else is kept, never acked.
                final problems = summary == null
                    ? const ['event without a summary']
                    : [
                        ...codec.summaryProblems(summary, serverEpoch: serverEpoch),
                        if (summary['epoch'] != serverEpoch) 'summary of another epoch',
                      ];
                if (problems.isNotEmpty) return _Invalid(CloudRejected('wallet:summary', problems));
                return _Already(summary!['cloudVersion']! as int);
              }
              return _Invalid(read is CloudRejected<CoinEntry>
                  ? CloudRejected(read.subject, read.reasons)
                  : CloudRejected('wallet:$id', const ['earlier epoch under a current id']));
            }
            if (summary != null) {
              final p = codec.summaryProblems(summary, serverEpoch: serverEpoch);
              if (p.isNotEmpty) return _Invalid(CloudRejected('wallet:summary', p));
            }
            final next = CloudCodec.summaryAfter(previous: summary, epoch: epoch, eventId: id, amount: entry.amount);
            if (next == null) return const _BelowZero();
            tx.set(paths.walletEvent(id), w.data!);
            tx.set(paths.walletSummary, next);
            return _Written(null, next['cloudVersion'] as int);
          });
        } on CloudStoreException catch (e) {
          if (e.failure == CloudFailure.aborted && round < policy.maxRoundsPerRun) continue;
          await _onFailure(e, subject: 'wallet', claimed: claimed, kind: OutboxKind.walletEntry, name: event.subject);
          return; // the rest waits for the next run, in order
        }
      }
      if (!isStillValid()) {
        _release(claimed);
        throw const _Stop(SyncStop.runNoLongerValid);
      }
      switch (r) {
        case _Written(:final version) || _Already(:final version):
          repo.transaction(() {
            repo.updateCloudSync((m) => m.confirmed('wallet', cloudVersion: version, epoch: epoch));
            repo.updateOutbox((o) => o.ack(claimed));
          });
          _sent.add('wallet:${entry.key}');
        case _Mismatch(:final cloudAmount):
          _conflict({
            'id': 'wallet:${entry.key}:${entry.amount}:$cloudAmount',
            'kind': 'wallet',
            'subject': entry.key,
            'reason': 'same key, different amount',
            'local': entry.toJson(),
            'cloudAmount': cloudAmount,
            ..._walletV2(epoch),
          }, 'wallet:${entry.key}', claimed);
        case _BelowZero():
          _conflict({
            'id': 'walletBelowZero:$id',
            'kind': 'wallet',
            'subject': entry.key,
            'reason': 'the cloud balance would go below zero',
            'local': entry.toJson(),
            ..._walletV2(epoch),
          }, 'wallet:${entry.key}', claimed);
        case _Invalid(:final rejected):
          _conflict(rejected.conflictRecord(), 'wallet:${entry.key}', claimed);
        case _EpochMovedResult():
          _release(claimed);
          throw const _EpochMoved();
        default:
          await _fail('wallet', claimed, kind: OutboxKind.walletEntry, name: event.subject);
          return;
      }
    }
  }

  // ---- helpers --------------------------------------------------------------

  Future<int> _serverEpoch(CloudTx tx) async {
    final raw = await tx.get(paths.meta);
    final read = raw == null ? null : codec.readMeta(raw);
    return read is CloudAccepted<CloudMeta> ? read.value.epoch : -1;
  }

  /// Record v2 of a coin conflict (Phase 4.5): shown and kept only, no
  /// balance is ever changed for it.
  Map<String, dynamic> _walletV2(int epoch) =>
      {'v': 2, 'epoch': epoch, 'at': _now().toUtc().toIso8601String(), 'status': ConflictStatus.open.name};

  /// A permanent conflict: kept in the conflict store, the events held as
  /// conflicted (never retried or cleared automatically).
  void _conflict(Map<String, dynamic> record, String subject, List<String> claimed) {
    repo.transaction(() {
      repo.keepConflict(record);
      repo.updateOutbox((o) => o.markConflicted(claimed));
    });
    _conflicted.add(subject);
  }

  /// A failed run of [subject]: released (never dropped), backed off,
  /// stalled after too many in a row.
  Future<void> _fail(String subject, List<String> claimed, {OutboxKind? kind, String? name}) async {
    var stalled = false;
    repo.transaction(() {
      repo.updateCloudSync(
        (m) => m.failed(subject, _now(), policy: policy, jitter: SyncRetryPolicy.randomJitter(_random)),
      );
      stalled = repo.cloudSync.of(subject).stalled;
      _release(claimed);
      if (stalled && kind != null && name != null) repo.updateOutbox((o) => o.markStalled(kind, name));
    });
    (stalled ? _stalled : _failed).add(subject);
  }

  /// A cloud call failed. Refusals of the rules are told apart (consent,
  /// deletion) by reading the account's own records; nothing queued is ever
  /// dropped for it.
  Future<void> _onFailure(
    CloudStoreException e, {
    required String subject,
    required List<String> claimed,
    OutboxKind? kind,
    String? name,
  }) async {
    if (e.failure == CloudFailure.permissionDenied) {
      _release(claimed);
      final why = await _whyRefused();
      if (why != null) throw _Stop(why);
    }
    await _fail(subject, claimed, kind: kind, name: name);
  }

  Future<SyncStop?> _whyRefused() async {
    try {
      if (await store.get(paths.deletion) != null) return SyncStop.deletionInProgress;
      final consent = await store.get(paths.consent);
      if (consent?['status'] != 'confirmed') return SyncStop.consentNotConfirmed;
    } on CloudStoreException {
      return SyncStop.consentNotConfirmed; // cannot even read our own records: stop
    }
    return null;
  }

  static OutboxKind? _kindOf(String subject) =>
      subject == 'season' ? OutboxKind.season : subject.startsWith('case:') ? OutboxKind.caseRun : null;

  static String? _nameOf(String subject) =>
      subject == 'season' ? 'season' : subject.startsWith('case:') ? subject.substring('case:'.length) : null;
}

class _EpochMoved implements Exception {
  const _EpochMoved();
}

sealed class _Result {
  const _Result();
}

final class _Written extends _Result {
  const _Written(this.next, this.version, {this.serverRun, this.reason});

  final Object? next;
  final int version;

  /// The server's case run that lost to the one written, to be kept.
  final GameProgress? serverRun;
  final String? reason;
}

final class _Already extends _Result {
  const _Already(this.version);

  final int version;
}

final class _Mismatch extends _Result {
  const _Mismatch(this.cloudAmount);

  final int cloudAmount;
}

final class _BelowZero extends _Result {
  const _BelowZero();
}

final class _Invalid extends _Result {
  const _Invalid(this.rejected);

  final CloudRejected<void> rejected;
}

final class _Skipped extends _Result {
  const _Skipped(this.skip);

  final CloudSkip skip;
}

final class _EpochMovedResult extends _Result {
  const _EpochMovedResult();
}
