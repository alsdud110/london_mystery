import 'dart:convert';

import 'package:flutter/foundation.dart';

/// What changed. Stored by [name]: never rename one.
enum OutboxKind {
  /// A case save (one run of a case): its latest state is sent.
  caseRun,

  /// The season record: its latest state is sent.
  season,

  /// One coin entry. Entries never change, so each is sent once by its key.
  walletEntry;

  static OutboxKind? byName(Object? name) {
    for (final k in values) {
      if (k.name == name) return k;
    }
    return null;
  }
}

/// Where an event is on its way. Stored by [name]: never rename one.
enum OutboxState {
  /// Waiting to be sent.
  pending,

  /// Handed to a sender, not acknowledged yet. Back to pending at the next
  /// start (or when the send fails); removed only by an acknowledgement.
  inFlight;

  static OutboxState? byName(Object? name) {
    for (final s in values) {
      if (s.name == name) return s;
    }
    return null;
  }
}

/// One change of a profile waiting to be synced.
///
/// A case or season event names the version that changed; the state sent is
/// the save as it is when sending (always as new as the event or newer, and
/// a newer state of the same run or a later run wins any merge). A coin
/// entry event carries the entry itself.
@immutable
class OutboxEvent {
  const OutboxEvent({
    required this.id,
    required this.profileId,
    required this.kind,
    required this.subject,
    required this.epoch,
    this.runId,
    this.runSeq = 0,
    this.rev = 0,
    this.payload,
    this.playtest = false,
    this.state = OutboxState.pending,
    this.attempts = 0,
    required this.createdAt,
  });

  /// Unique (random); what an acknowledgement names.
  final String id;
  final String profileId;
  final OutboxKind kind;

  /// The case id, `season`, or the coin entry key.
  final String subject;

  /// The profile's reset epoch the change belongs to.
  final int epoch;

  /// The case run that changed (case events).
  final String? runId;
  final int runSeq;
  final int rev;

  /// The coin entry (coin entry events).
  final Map<String, dynamic>? payload;

  /// Operator data: never to be sent to a live cloud.
  final bool playtest;
  final OutboxState state;

  /// How many times it was handed to a sender.
  final int attempts;
  final DateTime createdAt;

  OutboxEvent withState(OutboxState s, {int? attempts}) => OutboxEvent(
        id: id,
        profileId: profileId,
        kind: kind,
        subject: subject,
        epoch: epoch,
        runId: runId,
        runSeq: runSeq,
        rev: rev,
        payload: payload,
        playtest: playtest,
        state: s,
        attempts: attempts ?? this.attempts,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'profileId': profileId,
        'kind': kind.name,
        'subject': subject,
        'epoch': epoch,
        if (runId != null) 'runId': runId,
        if (runSeq > 0) 'runSeq': runSeq,
        if (rev > 0) 'rev': rev,
        if (payload != null) 'payload': payload,
        if (playtest) 'playtest': true,
        'state': state.name,
        if (attempts > 0) 'attempts': attempts,
        'createdAt': createdAt.toIso8601String(),
      };

  /// Null for an event that cannot be read.
  static OutboxEvent? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    final profileId = json['profileId'];
    final kind = OutboxKind.byName(json['kind']);
    final subject = json['subject'];
    final created = json['createdAt'];
    if (id is! String || profileId is! String || kind == null || subject is! String) return null;
    int count(Object? v) => v is int && v > 0 ? v : 0;
    final payload = json['payload'];
    final runId = json['runId'];
    return OutboxEvent(
      id: id,
      profileId: profileId,
      kind: kind,
      subject: subject,
      epoch: count(json['epoch']),
      runId: runId is String ? runId : null,
      runSeq: count(json['runSeq']),
      rev: count(json['rev']),
      payload: payload is Map<String, dynamic> ? payload : null,
      playtest: json['playtest'] == true,
      state: OutboxState.byName(json['state']) ?? OutboxState.pending,
      attempts: count(json['attempts']),
      createdAt: (created is String ? DateTime.tryParse(created) : null) ?? DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

/// A profile's changes waiting to be synced, oldest first. Immutable: every
/// change returns a new outbox.
///
/// - Nothing is removed without an acknowledgement ([ack]); an unknown or
///   repeated acknowledgement changes nothing.
/// - A newer change of a case or the season replaces the one still waiting
///   for the same thing (its state supersedes the older one: same run with a
///   higher revision, or a later run). One already handed to a sender stays
///   until it is acknowledged; the newer one waits next to it.
/// - A coin entry is queued once by its key, however often it is saved.
@immutable
class Outbox {
  const Outbox([this.events = const []]);

  final List<OutboxEvent> events;

  static const empty = Outbox();

  List<OutboxEvent> get pending => [for (final e in events) if (e.state == OutboxState.pending) e];

  bool get isEmpty => events.isEmpty;

  Outbox enqueue(OutboxEvent event) {
    switch (event.kind) {
      case OutboxKind.walletEntry:
        if (events.any((e) => e.kind == OutboxKind.walletEntry && e.subject == event.subject)) return this;
        return Outbox([...events, event]);
      case OutboxKind.caseRun || OutboxKind.season:
        bool supersedes(OutboxEvent e) =>
            e.kind == event.kind && e.subject == event.subject && e.state == OutboxState.pending;
        return Outbox([
          for (final e in events)
            if (!supersedes(e)) e,
          event,
        ]);
    }
  }

  /// [ids] handed to a sender.
  Outbox claim(Iterable<String> ids) {
    final set = ids.toSet();
    return Outbox([
      for (final e in events)
        set.contains(e.id) && e.state == OutboxState.pending
            ? e.withState(OutboxState.inFlight, attempts: e.attempts + 1)
            : e,
    ]);
  }

  /// [ids] acknowledged by the server: removed. Others stay.
  Outbox ack(Iterable<String> ids) {
    final set = ids.toSet();
    return Outbox([for (final e in events) if (!set.contains(e.id)) e]);
  }

  /// [ids] not sent after all: waiting again.
  Outbox release(Iterable<String> ids) {
    final set = ids.toSet();
    return Outbox([
      for (final e in events) set.contains(e.id) && e.state == OutboxState.inFlight ? e.withState(OutboxState.pending) : e,
    ]);
  }

  /// At start: whatever was handed to a sender before the app stopped is
  /// waiting again (it is sent again; the server ignores a repeat).
  Outbox recovered() =>
      events.any((e) => e.state == OutboxState.inFlight) ? release([for (final e in events) e.id]) : this;

  String encode() => jsonEncode({'v': 1, 'events': [for (final e in events) e.toJson()]});

  /// Tolerant decoding: unreadable events are dropped, a repeated id keeps
  /// its first event.
  static Outbox decode(String? raw) {
    if (raw == null) return empty;
    try {
      final json = jsonDecode(raw);
      final list = json is Map ? json['events'] : null;
      if (list is! List) return empty;
      final seen = <String>{};
      return Outbox([
        for (final e in list)
          if (OutboxEvent.fromJson(e) case final event? when seen.add(event.id)) event,
      ]);
    } on FormatException {
      debugPrint('The sync outbox was unreadable');
      return empty;
    }
  }
}
