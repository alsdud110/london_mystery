import 'dart:convert';

import 'package:flutter/foundation.dart';

import 'sync_retry_policy.dart';

/// What the device knows of one synced subject (`meta`, `case:<id>`,
/// `season`, `wallet`): the cloudVersion and epoch the server last
/// confirmed, and how sending it has been going.
@immutable
class SubjectSync {
  const SubjectSync({
    this.confirmedVersion,
    this.confirmedEpoch,
    this.failures = 0,
    this.nextAttemptAt,
    this.stalled = false,
  });

  /// The cloudVersion the server confirmed for our last committed write or
  /// the last state we merged from it. Null: never confirmed (a first sync,
  /// or bookkeeping lost) — the sender then always merges with the server's
  /// copy before writing, which is always safe.
  final int? confirmedVersion;
  final int? confirmedEpoch;

  /// Failed sync runs in a row (reset by a confirmation).
  final int failures;

  /// Not before this time (back-off). Null: now.
  final DateTime? nextAttemptAt;

  /// Stopped after too many failures: no automatic retry until the next
  /// start's full resync.
  final bool stalled;

  Map<String, dynamic> toJson() => {
        if (confirmedVersion != null) 'v': confirmedVersion,
        if (confirmedEpoch != null) 'e': confirmedEpoch,
        if (failures > 0) 'f': failures,
        if (nextAttemptAt != null) 'next': nextAttemptAt!.toIso8601String(),
        if (stalled) 'stalled': true,
      };

  static SubjectSync fromJson(Object? json) {
    if (json is! Map) return const SubjectSync();
    int? pos(Object? v) => v is int && v >= 0 ? v : null;
    final next = json['next'];
    final version = pos(json['v']);
    return SubjectSync(
      confirmedVersion: version != null && version >= 1 ? version : null,
      confirmedEpoch: pos(json['e']),
      failures: pos(json['f']) ?? 0,
      nextAttemptAt: next is String ? DateTime.tryParse(next) : null,
      stalled: json['stalled'] == true,
    );
  }
}

/// A profile's cloud sync bookkeeping, kept under its own key
/// (`lm.p.<id>.cloud.v1`), apart from every game save: the saves' format
/// never changes for it. Immutable; every change returns a new value.
///
/// A cloudVersion is recorded only by [confirmed] — call it after the
/// server's transaction committed, never before.
@immutable
class CloudSyncMeta {
  const CloudSyncMeta({this.subjects = const {}, this.needsFullResync = false});

  static const empty = CloudSyncMeta();

  final Map<String, SubjectSync> subjects;

  /// Set at start when something had stalled: the next run compares the
  /// whole profile with the cloud (merge both ways) before sending.
  final bool needsFullResync;

  SubjectSync of(String subject) => subjects[subject] ?? const SubjectSync();

  CloudSyncMeta _with(String subject, SubjectSync s) =>
      CloudSyncMeta(subjects: {...subjects, subject: s}, needsFullResync: needsFullResync);

  /// The server committed [subject] at [cloudVersion] in [epoch] (or we
  /// merged that state): recorded, failures cleared.
  CloudSyncMeta confirmed(String subject, {required int cloudVersion, required int epoch}) {
    assert(cloudVersion >= 1);
    return _with(subject, SubjectSync(confirmedVersion: cloudVersion, confirmedEpoch: epoch));
  }

  /// The server's [subject] at [cloudVersion] was merged into the device
  /// (brought down, Phase 4.4): recorded like [confirmed], but how sending
  /// it has been going (failures, back-off, stalled) stays as it was — the
  /// device's own changes still wait for their turn.
  CloudSyncMeta merged(String subject, {required int cloudVersion, required int epoch}) {
    assert(cloudVersion >= 1);
    final s = of(subject);
    return _with(
      subject,
      SubjectSync(
        confirmedVersion: cloudVersion,
        confirmedEpoch: epoch,
        failures: s.failures,
        nextAttemptAt: s.nextAttemptAt,
        stalled: s.stalled,
      ),
    );
  }

  /// A sync run of [subject] failed at [now]: counted, backed off; stalled
  /// after [SyncRetryPolicy.stallAfter] in a row. The confirmed version stays.
  CloudSyncMeta failed(String subject, DateTime now, {SyncRetryPolicy policy = SyncRetryPolicy.standard, double jitter = 1}) {
    final s = of(subject);
    final failures = s.failures + 1;
    final stalled = policy.stalls(failures);
    return _with(
      subject,
      SubjectSync(
        confirmedVersion: s.confirmedVersion,
        confirmedEpoch: s.confirmedEpoch,
        failures: failures,
        nextAttemptAt: stalled ? null : now.add(policy.delayAfter(failures, jitter: jitter)),
        stalled: stalled,
      ),
    );
  }

  /// Whether [subject] may be tried at [now] automatically.
  bool isDue(String subject, DateTime now) {
    final s = of(subject);
    if (s.stalled) return false;
    final next = s.nextAttemptAt;
    return next == null || !now.isBefore(next);
  }

  bool get anyStalled => subjects.values.any((s) => s.stalled);

  /// At app start: stalled subjects get one more chance through a full
  /// resync (their counters start again; confirmed versions stay).
  CloudSyncMeta atStart() {
    if (!anyStalled) return this;
    return CloudSyncMeta(
      subjects: {
        for (final MapEntry(:key, :value) in subjects.entries)
          key: value.stalled
              ? SubjectSync(confirmedVersion: value.confirmedVersion, confirmedEpoch: value.confirmedEpoch)
              : value,
      },
      needsFullResync: true,
    );
  }

  /// The full resync finished.
  CloudSyncMeta resynced() => CloudSyncMeta(subjects: subjects);

  String encode() => jsonEncode({
        'v': 1,
        if (needsFullResync) 'resync': true,
        'subjects': {for (final e in subjects.entries) e.key: e.value.toJson()},
      });

  /// Tolerant: anything unreadable, or of another format version, is "never
  /// confirmed" (safe: the sender then merges with the server's copy first).
  static CloudSyncMeta decode(String? raw) {
    if (raw == null) return empty;
    try {
      final json = jsonDecode(raw);
      // Only the format this build knows; any other is "never confirmed".
      if (json is! Map || json['v'] != 1) return empty;
      final subs = json['subjects'];
      return CloudSyncMeta(
        subjects: subs is Map ? {for (final e in subs.entries) if (e.key is String) e.key as String: SubjectSync.fromJson(e.value)} : const {},
        needsFullResync: json['resync'] == true,
      );
    } on FormatException {
      return empty;
    }
  }
}
