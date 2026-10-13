import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import '../models/game_progress.dart';
import '../models/season_progress.dart';
import '../models/wallet.dart';

// Pure merge rules for one profile's saves seen on two sides (this device and
// another copy, e.g. the cloud). No storage, no clock: the same inputs give
// the same result, and merging a result with either input again changes
// nothing. Ties are broken towards [local].
//
// Every save belongs to the profile's reset epoch (how many times
// everything was wiped): a later epoch always wins, so a reset is never
// undone by data from before it.

/// How a merge came out.
enum MergeOutcome {
  /// Both sides were the same.
  same,

  /// The local side holds everything.
  keptLocal,

  /// The other side holds everything.
  tookRemote,

  /// Neither held everything; the result has both.
  combined,

  /// The two sides cannot both be kept and the rules cannot tell which one
  /// is right. A winner is chosen so play can go on; the other side is
  /// returned to be kept, never thrown away.
  conflict,
}

/// A case save with the epoch it belongs to.
@immutable
class CaseSnapshot {
  const CaseSnapshot({required this.epoch, required this.progress});

  final int epoch;
  final GameProgress progress;
}

@immutable
class CaseMerge {
  const CaseMerge(this.merged, this.outcome, {this.preserved, required this.reason});

  final GameProgress merged;
  final MergeOutcome outcome;

  /// The side that lost and still holds play of its own: to be kept (in a
  /// conflict, or data from before a reset made elsewhere).
  final GameProgress? preserved;
  final String reason;
}

/// Whether [p] holds nothing played (a case never opened, or a new run just
/// started by Play again).
bool isBlankRun(GameProgress p) =>
    !p.introSeen &&
    p.startedAt == null &&
    p.completedMissionIds.isEmpty &&
    p.attempts.isEmpty &&
    p.hintsUsed.isEmpty &&
    p.lookedUpWords.isEmpty &&
    p.badgeIds.isEmpty;

String _content(GameProgress p) => jsonEncode(p.copyWith(rev: 0).toJson());

/// Merges one case's save.
///
/// 1. Different epochs: the later epoch wins. A losing side with play of its
///    own is returned as [CaseMerge.preserved].
/// 2. Different runs (`runSeq`): the later run wins — Play again started it
///    on purpose, so the run before it never comes back.
/// 3. The same run (`runId`): combined. Solved missions, evidence, words and
///    badges are kept from both; counts take the larger value; the first
///    start and solve times are kept; play time takes the longer.
/// 4. The same run number but different runs (two devices each started the
///    case, or both played it again from the same run): one side with
///    nothing played gives way to the other. Otherwise it is a conflict: the
///    side with more solved missions plays on (then the higher revision, then
///    the longer play, then local), the other is preserved.
CaseMerge mergeCase(CaseSnapshot local, CaseSnapshot remote) {
  final l = local.progress;
  final r = remote.progress;
  if (local.epoch != remote.epoch) {
    final localWins = local.epoch > remote.epoch;
    final loser = localWins ? r : l;
    return CaseMerge(
      localWins ? l : r,
      localWins ? MergeOutcome.keptLocal : MergeOutcome.tookRemote,
      preserved: isBlankRun(loser) ? null : loser,
      reason: 'epoch',
    );
  }
  if (_content(l) == _content(r)) {
    return CaseMerge(l.rev >= r.rev ? l : r, MergeOutcome.same, reason: 'same');
  }
  if (l.runSeq != r.runSeq) {
    final localWins = l.runSeq > r.runSeq;
    return CaseMerge(localWins ? l : r, localWins ? MergeOutcome.keptLocal : MergeOutcome.tookRemote,
        reason: 'later run');
  }
  if (l.runId != null && l.runId == r.runId) return _sameRun(l, r);
  if (isBlankRun(r)) return CaseMerge(l, MergeOutcome.keptLocal, reason: 'other side blank');
  if (isBlankRun(l)) return CaseMerge(r, MergeOutcome.tookRemote, reason: 'local blank');
  final localWins = _furtherAlong(l, r);
  return CaseMerge(
    localWins ? l : r,
    MergeOutcome.conflict,
    preserved: localWins ? r : l,
    reason: 'two runs with the same run number',
  );
}

bool _furtherAlong(GameProgress l, GameProgress r) {
  int cmp(int a, int b) => a.compareTo(b);
  for (final c in [
    cmp(l.completedMissionIds.length, r.completedMissionIds.length),
    cmp(l.rev, r.rev),
    cmp(l.playMillis ?? 0, r.playMillis ?? 0),
  ]) {
    if (c != 0) return c > 0;
  }
  return true;
}

List<String> _union(List<String> a, List<String> b) => [...a, ...b.where((x) => !a.contains(x))];

Map<String, int> _max(Map<String, int> a, Map<String, int> b) => {
      ...a,
      for (final MapEntry(:key, :value) in b.entries)
        if (!a.containsKey(key) || a[key]! < value) key: value,
    };

Map<String, int> _min(Map<String, int> a, Map<String, int> b) => {
      ...a,
      for (final MapEntry(:key, :value) in b.entries)
        if (!a.containsKey(key) || a[key]! > value) key: value,
    };

DateTime? _earlier(DateTime? a, DateTime? b) => a == null ? b : (b == null || !b.isBefore(a) ? a : b);

CaseMerge _sameRun(GameProgress l, GameProgress r) {
  final lb = l.behavior;
  final rb = r.behavior;
  final merged = GameProgress(
    detectiveName: l.detectiveName ?? r.detectiveName,
    introSeen: l.introSeen || r.introSeen,
    completedMissionIds: _union(l.completedMissionIds, r.completedMissionIds),
    attempts: _max(l.attempts, r.attempts),
    wrongAnswers: _max(l.wrongAnswers, r.wrongAnswers),
    hintsUsed: _max(l.hintsUsed, r.hintsUsed),
    missionStartedAt: {
      ...r.missionStartedAt,
      for (final MapEntry(:key, :value) in l.missionStartedAt.entries) key: _earlier(value, r.missionStartedAt[key])!,
    },
    missionStartPlayMillis: _min(l.missionStartPlayMillis, r.missionStartPlayMillis),
    solveSeconds: _min(l.solveSeconds, r.solveSeconds),
    badgeIds: _union(l.badgeIds, r.badgeIds),
    lookedUpWords: _union(l.lookedUpWords, r.lookedUpWords),
    lookupsRecorded: l.lookupsRecorded || r.lookupsRecorded,
    // The rule a mission was solved under is kept as recorded first here.
    xpRules: {...r.xpRules, ...l.xpRules},
    behavior: lb == null && rb == null
        ? null
        : BehaviorLog(
            rechecked: _union(lb?.rechecked ?? const [], rb?.rechecked ?? const []),
            evidenceViewed: _union(lb?.evidenceViewed ?? const [], rb?.evidenceViewed ?? const []),
            words: _union(lb?.words ?? const [], rb?.words ?? const []),
          ),
    startedAt: _earlier(l.startedAt, r.startedAt),
    completedAt: _earlier(l.completedAt, r.completedAt),
    playMillis: l.playMillis == null && r.playMillis == null
        ? null
        : ((l.playMillis ?? 0) >= (r.playMillis ?? 0) ? l.playMillis : r.playMillis),
    runId: l.runId,
    runSeq: l.runSeq,
    playtest: l.playtest || r.playtest,
  );
  final m = _content(merged);
  if (m == _content(l)) return CaseMerge(l, MergeOutcome.keptLocal, reason: 'same run');
  if (m == _content(r)) return CaseMerge(r, MergeOutcome.tookRemote, reason: 'same run');
  return CaseMerge(merged.copyWith(rev: (l.rev > r.rev ? l.rev : r.rev) + 1), MergeOutcome.combined, reason: 'same run');
}

/// The season record with the epoch it belongs to.
@immutable
class SeasonSnapshot {
  const SeasonSnapshot({required this.epoch, required this.season});

  final int epoch;
  final SeasonProgress season;
}

@immutable
class SeasonMerge {
  const SeasonMerge(this.merged, this.outcome, {this.preserved});

  final SeasonProgress merged;
  final MergeOutcome outcome;
  final SeasonProgress? preserved;
}

bool _blankSeason(SeasonProgress s) =>
    s.solvedEpisodeIds.isEmpty && s.activeEpisodeId == AppConstants.currentEpisodeId;

/// Merges the season record. A later epoch wins. Otherwise a case solved on
/// either side is solved; it stays operator data only if every side that
/// solved it solved it as such. The open case file is this device's own
/// choice (taken from the other side only when this side has none).
SeasonMerge mergeSeason(SeasonSnapshot local, SeasonSnapshot remote) {
  final l = local.season;
  final r = remote.season;
  if (local.epoch != remote.epoch) {
    final localWins = local.epoch > remote.epoch;
    final loser = localWins ? r : l;
    return SeasonMerge(localWins ? l : r, localWins ? MergeOutcome.keptLocal : MergeOutcome.tookRemote,
        preserved: _blankSeason(loser) ? null : loser);
  }
  final solved = _union(l.solvedEpisodeIds, r.solvedEpisodeIds);
  bool playtestOn(SeasonProgress s, String id) => !s.isSolved(id) || s.playtestEpisodeIds.contains(id);
  final merged = SeasonProgress(
    activeEpisodeId: _blankSeason(l) ? r.activeEpisodeId : l.activeEpisodeId,
    solvedEpisodeIds: solved,
    playtestEpisodeIds: [for (final id in solved) if (playtestOn(l, id) && playtestOn(r, id)) id],
  );
  String c(SeasonProgress s) => jsonEncode(s.toJson());
  final m = c(merged);
  return SeasonMerge(
    merged,
    m == c(l) && m == c(r)
        ? MergeOutcome.same
        : m == c(l)
            ? MergeOutcome.keptLocal
            : m == c(r)
                ? MergeOutcome.tookRemote
                : MergeOutcome.combined,
  );
}

/// The wallet with the epoch it belongs to.
@immutable
class WalletSnapshot {
  const WalletSnapshot({required this.epoch, required this.wallet});

  final int epoch;
  final Wallet wallet;
}

/// The same coin entry key with a different amount on the two sides.
@immutable
class WalletConflict {
  const WalletConflict({required this.local, required this.remote});

  final CoinEntry local;
  final CoinEntry remote;

  String get key => local.key;
}

@immutable
class WalletMerge {
  const WalletMerge(this.merged, this.outcome, {this.conflicts = const [], this.preserved});

  final Wallet merged;
  final MergeOutcome outcome;

  /// Keys whose amounts differ. The local entry stays in [merged] as it is:
  /// no balance is changed until a policy decides.
  final List<WalletConflict> conflicts;

  /// A losing wallet from an earlier epoch, to be kept.
  final Wallet? preserved;
}

/// Merges the wallet by entry key. A later epoch wins. Otherwise an entry on
/// only one side is added; the same key with the same amount is one entry
/// (the local one); the same key with a different amount is a conflict and
/// the local entry is kept unchanged. Tips owned stay owned either way (the
/// key is there). No entry is ever made up to correct a balance.
WalletMerge mergeWallet(WalletSnapshot local, WalletSnapshot remote) {
  final l = local.wallet;
  final r = remote.wallet;
  if (local.epoch != remote.epoch) {
    final localWins = local.epoch > remote.epoch;
    final loser = localWins ? r : l;
    return WalletMerge(localWins ? l : r, localWins ? MergeOutcome.keptLocal : MergeOutcome.tookRemote,
        preserved: loser.entries.isEmpty ? null : loser);
  }
  var merged = l;
  final conflicts = <WalletConflict>[];
  for (final e in r.entries) {
    final mine = l.entries.where((x) => x.key == e.key).firstOrNull;
    if (mine == null) {
      merged = merged.adding(e);
    } else if (mine.amount != e.amount) {
      conflicts.add(WalletConflict(local: mine, remote: e));
    }
  }
  final added = merged.entries.length > l.entries.length;
  final remoteHasAll = l.entries.every((x) => r.has(x.key));
  return WalletMerge(
    merged,
    conflicts.isNotEmpty
        ? MergeOutcome.conflict
        : !added && remoteHasAll
            ? MergeOutcome.same
            : !added
                ? MergeOutcome.keptLocal
                : remoteHasAll
                    ? MergeOutcome.tookRemote
                    : MergeOutcome.combined,
    conflicts: conflicts,
  );
}
