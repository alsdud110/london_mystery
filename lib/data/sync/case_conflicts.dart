import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/game_progress.dart';
import '../repositories/progress_repository.dart';
import 'merge.dart';

// Phase 4.5: the kept case files of a profile (its sync conflicts, see
// `ProgressRepository.conflicts`) and the player's choice between two of
// them.
//
// A conflict is two runs of one case filed under the same run number (two
// devices each started the case). The sync never throws either away: the
// further-along run plays on, the other is kept here. The player may choose
// the other one instead, or decide later. Rules:
// - Nothing kept is ever removed: a record only changes its status.
// - A choice saves the chosen run under a NEW run number (one more than
//   both), never a new epoch: the merge rule "the later run wins" then takes
//   it everywhere (the server's rules accept a higher run number). The run
//   left is kept (its record stays, or a new one is made for it).
// - The new run's id is made from the chosen run and the new number, so the
//   same choice made twice (or on two devices) is the same run: it never
//   moves the run number on again, and two devices that chose the same file
//   simply agree.
// - A choice is `waiting` until the server has the chosen run; then
//   `resolved`. If another run replaced it meanwhile, it is `archived` (the
//   merge kept the run, and a new choice is offered when one is needed).

/// Where a kept case file came from.
enum FileSide {
  /// Played on this device.
  device,

  /// From the account (the server: another device's play).
  account;

  static FileSide? byName(Object? name) => values.where((v) => v.name == name).firstOrNull;

  FileSide get other => this == device ? account : device;
}

/// The status of a kept record.
enum ConflictStatus {
  /// Two case files: the player has not chosen yet.
  open,

  /// Chosen on this device; the server does not have the choice yet.
  waiting,

  /// Chosen, and the server has it.
  resolved,

  /// Kept for safety only (a run left by a choice or a later run, a run from
  /// before a New Adventure); nothing to choose.
  archived;

  static ConflictStatus? byName(Object? name) => values.where((v) => v.name == name).firstOrNull;
}

/// One case file of a choice.
@immutable
class CaseFile {
  const CaseFile({required this.run, required this.side});

  final GameProgress run;
  final FileSide side;
}

/// Two case files of one case for the player to choose between: the one
/// playing now on this device, and the other kept one.
@immutable
class CaseChoice {
  const CaseChoice({
    required this.caseId,
    required this.epoch,
    required this.playing,
    required this.other,
    required this.recordIds,
    required this.fingerprint,
  });

  final String caseId;
  final int epoch;
  final CaseFile playing;
  final CaseFile other;

  /// The kept records holding [other]'s run.
  final List<String> recordIds;

  /// What the choice was made on: the saves it shows. A choice is applied
  /// only while they are still the same.
  final String fingerprint;
}

/// What a choice did.
enum ChoiceResult {
  /// Saved: the chosen run plays on, under a new run number.
  applied,

  /// This choice was already made: nothing changed.
  alreadyDone,

  /// The case files changed since they were shown (a sync, another screen):
  /// nothing changed; they are shown again.
  changed,

  /// The run that would be left could not be kept safely (too many kept
  /// files for the case, or too much kept data): nothing changed.
  cannotKeep,

  /// The account or the detective changed meanwhile: nothing changed.
  stopped,
}

abstract final class CaseConflicts {
  /// Kept files per case (this epoch) above which a choice that must keep
  /// one more is refused. Nothing is ever removed to make room.
  static const perCaseLimit = 10;

  /// Kept data (encoded) above which a choice that must keep one more is
  /// refused.
  static const maxBytes = 512 * 1024;

  static const reasonSameNumber = 'two runs with the same run number';
  static const reasonNotChosen = 'not chosen';

  // ---- records -------------------------------------------------------------

  /// A kept case run (record v2). [status] defaults to open for a conflict
  /// and archived otherwise.
  static Map<String, dynamic> caseRecord({
    required String caseId,
    required GameProgress run,
    required FileSide side,
    required int epoch,
    required String reason,
    required DateTime at,
    ConflictStatus? status,
  }) =>
      {
        'id': 'case:$caseId:${run.runId}:${run.runSeq}:${run.rev}:${side.name}',
        'kind': 'case',
        'subject': caseId,
        'reason': reason,
        'kept': run.toJson(),
        'v': 2,
        'caseId': caseId,
        'runId': run.runId,
        'runSeq': run.runSeq,
        'side': side.name,
        'epoch': epoch,
        'at': at.toUtc().toIso8601String(),
        'status': (status ?? (reason == reasonSameNumber ? ConflictStatus.open : ConflictStatus.archived)).name,
      };

  /// The case a record is about, or null (not a case record).
  static String? caseOf(Map<String, dynamic> r) {
    if (r['caseId'] case final String id) return id;
    return switch ((r['kind'], r['subject'])) {
      ('restoreHeld', final String s) when s.startsWith('case:') => s.substring('case:'.length),
      ('case', final String s) => s,
      _ => null,
    };
  }

  /// The run a case record keeps.
  static GameProgress? runOf(Map<String, dynamic> r) {
    final raw = r['kind'] == 'restoreHeld' ? r['cloud'] : r['kept'];
    return raw is Map<String, dynamic> ? GameProgress.fromJson(raw) : null;
  }

  /// Where a record's run came from. Records before v2 have no side: a held
  /// restore is the account's; another case record cannot tell, and is
  /// shown as the account's.
  static FileSide sideOf(Map<String, dynamic> r) => FileSide.byName(r['side']) ?? FileSide.account;

  /// A record's status. Records before v2 have none: a held restore or a
  /// conflict of two runs is open, anything else is kept for safety.
  static ConflictStatus statusOf(Map<String, dynamic> r) {
    if (ConflictStatus.byName(r['status']) case final s?) return s;
    return switch (r['kind']) {
      'restoreHeld' => ConflictStatus.open,
      'case' when r['reason'] == reasonSameNumber => ConflictStatus.open,
      'wallet' => ConflictStatus.open,
      _ => ConflictStatus.archived,
    };
  }

  /// Whether [r] belongs to [epoch] (records before v2 have none: they are
  /// archived when the epoch moves on, see [archiveAll]).
  static bool _ofEpoch(Map<String, dynamic> r, int epoch) => r['epoch'] == null || r['epoch'] == epoch;

  static bool _isCaseRecord(Map<String, dynamic> r) => r['kind'] == 'case' || r['kind'] == 'restoreHeld';

  static Map<String, dynamic> _with(Map<String, dynamic> r, ConflictStatus status, DateTime at, [Map<String, dynamic>? more]) => {
        ...r,
        'status': status.name,
        'statusAt': at.toUtc().toIso8601String(),
        ...?more,
      };

  // ---- reading ---------------------------------------------------------------

  /// The cases of [caseIds] that have two case files to choose between.
  static List<CaseChoice> openChoices(SharedPrefsProgressRepository repo, Iterable<String> caseIds) => [
        for (final id in caseIds) ?choiceFor(repo, id),
      ];

  /// Whether any case of the profile has a choice waiting (cheap enough for
  /// a list of detectives).
  static bool hasOpenChoice(SharedPrefsProgressRepository repo) {
    final records = repo.conflicts;
    if (!records.any((r) => _isCaseRecord(r) && statusOf(r) == ConflictStatus.open)) return false;
    final ids = {for (final r in records) if (_isCaseRecord(r)) caseOf(r)}.whereType<String>();
    return ids.any((id) => choiceFor(repo, id) != null);
  }

  /// Whether a coin of this epoch was found under two amounts (Phase 4.5:
  /// shown and kept only; the balance never changes for it, and nothing is
  /// asked).
  static bool hasCoinNote(SharedPrefsProgressRepository repo) {
    final epoch = repo.epoch;
    return repo.conflicts.any((r) => r['kind'] == 'wallet' && statusOf(r) == ConflictStatus.open && _ofEpoch(r, epoch));
  }

  /// The choice waiting for [caseId], or null. The first kept run (oldest
  /// record) that differs from the run playing now is offered; others follow
  /// once it is chosen.
  static CaseChoice? choiceFor(SharedPrefsProgressRepository repo, String caseId) {
    final epoch = repo.epoch;
    final current = repo.load(caseId);
    final byRun = <String, ({GameProgress run, FileSide side, List<String> ids})>{};
    for (final r in repo.conflicts) {
      if (!_isCaseRecord(r) || caseOf(r) != caseId || !_ofEpoch(r, epoch)) continue;
      if (statusOf(r) != ConflictStatus.open) continue;
      final run = runOf(r);
      final id = r['id'];
      // A run under an earlier run number than the one playing lost to a
      // later run (a choice made on another device, or Play again): nothing
      // to choose any more.
      if (run == null || id is! String || isBlankRun(run) || sameProgress(run, current) || run.runSeq < current.runSeq) continue;
      final key = '${run.runId}:${run.runSeq}';
      final had = byRun[key];
      if (had == null) {
        byRun[key] = (run: run, side: sideOf(r), ids: [id]);
      } else {
        // The same run kept twice: the save with more in it is shown.
        final better = run.rev > had.run.rev ? run : had.run;
        byRun[key] = (run: better, side: had.side, ids: [...had.ids, id]);
      }
    }
    if (byRun.isEmpty) return null;
    final first = byRun.values.first;
    return CaseChoice(
      caseId: caseId,
      epoch: epoch,
      playing: CaseFile(run: current, side: first.side.other),
      other: CaseFile(run: first.run, side: first.side),
      recordIds: first.ids,
      fingerprint: _fingerprint(epoch, current, first.run, first.ids),
    );
  }

  /// The play clock and the revision count aside: the clock saved while the
  /// files are shown does not make a choice stale.
  static String _fingerprint(int epoch, GameProgress playing, GameProgress other, List<String> ids) {
    Map<String, dynamic> play(GameProgress p) => p.toJson()..removeWhere((k, _) => k == 'playMillis' || k == 'rev');
    return _hash(canonicalJson([epoch, play(playing), play(other), ids]));
  }

  /// The id of the run a choice makes: from the chosen run and its new run
  /// number only, so the same choice always makes the same run.
  static String choiceRunId(GameProgress chosen, int runSeq) => _hash('choice|${chosen.runId}|${chosen.runSeq}|$runSeq');

  /// FNV-1a, 64 bits, as 16 hex digits (like a run id).
  static String _hash(String s) {
    var h = 0xcbf29ce484222325;
    for (final b in utf8.encode(s)) {
      h ^= b;
      h *= 0x100000001b3;
    }
    return h.toUnsigned(64).toRadixString(16).padLeft(16, '0');
  }

  // ---- choosing --------------------------------------------------------------

  /// Plays on with one of [choice]'s files: the chosen run is saved under
  /// the next run number (queued for the sync like any save, in one save
  /// with its records). Synchronous: nothing else changes the saves while it
  /// runs. Nothing changes unless the saves are still what [choice] showed.
  static ChoiceResult choose(
    SharedPrefsProgressRepository repo,
    CaseChoice choice, {
    required bool keepPlaying,
    required DateTime now,
  }) {
    final runSeq = [choice.playing.run.runSeq, choice.other.run.runSeq].reduce((a, b) => a > b ? a : b) + 1;
    final runId = choiceRunId(keepPlaying ? choice.playing.run : choice.other.run, runSeq);
    final current = choiceFor(repo, choice.caseId);
    final playingNow = repo.load(choice.caseId);
    if (current == null || current.fingerprint != choice.fingerprint || repo.epoch != choice.epoch) {
      return playingNow.runId == runId && repo.epoch == choice.epoch ? ChoiceResult.alreadyDone : ChoiceResult.changed;
    }
    // The run playing now as saved now (its clock may have moved on).
    final chosen = keepPlaying ? playingNow : choice.other.run;
    final records = repo.conflicts;
    Map<String, dynamic>? left;
    if (!keepPlaying) {
      // The run playing now leaves the save: it is kept first.
      left = caseRecord(
        caseId: choice.caseId,
        run: playingNow,
        side: choice.playing.side,
        epoch: choice.epoch,
        reason: reasonNotChosen,
        at: now,
        status: ConflictStatus.archived,
      );
      final kept = records.where((r) => _isCaseRecord(r) && caseOf(r) == choice.caseId && _ofEpoch(r, choice.epoch)).length;
      final bytes = utf8.encode(jsonEncode({'items': [...records, left]})).length;
      if (kept >= perCaseLimit || bytes > maxBytes) return ChoiceResult.cannotKeep;
    }
    final next = chosen.copyWith(runId: runId, runSeq: runSeq);
    final decision = {
      'choice': {
        'runId': runId,
        'runSeq': runSeq,
        'kept': (keepPlaying ? choice.playing.side : choice.other.side).name,
        'at': now.toUtc().toIso8601String(),
      },
    };
    repo.transaction(() {
      if (left != null) repo.keepConflict(left);
      repo.updateConflicts((items) => [
            for (final r in items)
              if (choice.recordIds.contains(r['id'])) _with(r, ConflictStatus.waiting, now, decision) else r,
          ]);
      repo.saveMerged(episodeId: choice.caseId, progress: next, queue: true);
    });
    return ChoiceResult.applied;
  }

  /// Whether the player was told about [choice] once already (when opening
  /// the case).
  static bool noticed(SharedPrefsProgressRepository repo, CaseChoice choice) =>
      repo.conflicts.any((r) => choice.recordIds.contains(r['id']) && r['noticedAt'] != null);

  static void markNoticed(SharedPrefsProgressRepository repo, CaseChoice choice, DateTime now) => repo.updateConflicts((items) => [
        for (final r in items)
          if (choice.recordIds.contains(r['id'])) {...r, 'noticedAt': now.toUtc().toIso8601String()} else r,
      ]);

  // ---- after a sync ----------------------------------------------------------

  /// The server has [runId] of [caseId] (sent, or read back): a choice
  /// waiting for it is resolved.
  static void noteOnServer(SharedPrefsProgressRepository repo, String caseId, String? runId, {DateTime? now}) {
    if (runId == null) return;
    final at = now ?? DateTime.now();
    final items = repo.conflicts;
    bool waitingFor(Map<String, dynamic> r) =>
        caseOf(r) == caseId &&
        statusOf(r) == ConflictStatus.waiting &&
        (r['choice'] is Map && (r['choice'] as Map)['runId'] == runId);
    if (!items.any(waitingFor)) return;
    repo.updateConflicts((items) => [for (final r in items) waitingFor(r) ? _with(r, ConflictStatus.resolved, at) : r]);
  }

  /// The save of [caseId] changed from the sync: open records whose run the
  /// save now holds are resolved (nothing left to choose), and a choice
  /// waiting for a run that another run replaced is archived (that run was
  /// kept by the merge; a new choice is offered when one is needed).
  static void settle(SharedPrefsProgressRepository repo, String caseId, {DateTime? now}) {
    final at = now ?? DateTime.now();
    final current = repo.load(caseId);
    final epoch = repo.epoch;
    Map<String, dynamic> settled(Map<String, dynamic> r) {
      if (!_isCaseRecord(r) || caseOf(r) != caseId || !_ofEpoch(r, epoch)) return r;
      switch (statusOf(r)) {
        case ConflictStatus.open:
          final run = runOf(r);
          if (run == null) return r;
          if (sameProgress(run, current)) return _with(r, ConflictStatus.resolved, at, {'settledBy': 'same as playing'});
          // A later run plays now (chosen elsewhere): kept, not offered.
          if (run.runSeq < current.runSeq) return _with(r, ConflictStatus.archived, at, {'settledBy': 'later run'});
          return r;
        case ConflictStatus.waiting:
          final choice = r['choice'];
          if (choice is! Map) return r;
          final replaced = choice['runId'] != current.runId && current.runSeq >= (choice['runSeq'] as num? ?? 0);
          return replaced ? _with(r, ConflictStatus.archived, at, {'settledBy': 'replaced'}) : r;
        case ConflictStatus.resolved || ConflictStatus.archived:
          return r;
      }
    }

    final items = repo.conflicts;
    final next = [for (final r in items) settled(r)];
    if (!listEquals([for (final r in items) r['status']], [for (final r in next) r['status']])) {
      repo.updateConflicts((_) => next);
    }
  }

  /// A New Adventure (here or elsewhere): every open or waiting record is
  /// archived. Kept, never offered again: its runs belong to the epoch
  /// before.
  static List<Map<String, dynamic>> archiveAll(List<Map<String, dynamic>> items, DateTime at) => [
        for (final r in items)
          if (_isCaseRecord(r) && (statusOf(r) == ConflictStatus.open || statusOf(r) == ConflictStatus.waiting))
            _with(r, ConflictStatus.archived, at, {'settledBy': 'new adventure'})
          else
            r,
      ];
}
