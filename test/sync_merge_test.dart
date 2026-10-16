import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/models/wallet.dart';
import 'package:london_mystery/data/sync/merge.dart';

String j(GameProgress p) => jsonEncode(p.toJson());

CaseSnapshot snap(GameProgress p, {int epoch = 0}) => CaseSnapshot(epoch: epoch, progress: p);

GameProgress run(String id, {int seq = 0, int rev = 1, List<String> solved = const [], Map<String, int> hints = const {}}) =>
    GameProgress(
      detectiveName: 'KIM',
      introSeen: true,
      completedMissionIds: solved,
      hintsUsed: hints,
      startedAt: DateTime(2026, 10, 1),
      playMillis: 1000 * solved.length,
      runId: id,
      runSeq: seq,
      rev: rev,
    );

void main() {
  group('case runs', () {
    test('Play again: the run before never comes back, whichever side holds it', () {
      final before = run('a', seq: 0, rev: 9, solved: ['m01', 'm02', 'm03']);
      final again = run('b', seq: 1, rev: 1, solved: const []).copyWith(introSeen: false);
      for (final (l, r) in [(again, before), (before, again)]) {
        final m = mergeCase(snap(l), snap(r));
        expect(m.merged.runId, 'b');
        expect(m.merged.completedMissionIds, isEmpty, reason: 'the cleared missions stay cleared');
        // Replaying was on purpose: the run before never plays again. It is
        // still kept (Phase 4.5): a device may have played it on unsent.
        expect(m.preserved?.runId, 'a', reason: 'kept, never played again');
        expect(m.reason, 'later run');
      }
    });

    test('the same run on two devices is combined: nothing either side did is lost', () {
      final l = run('a', rev: 3, solved: ['m01', 'm02'], hints: {'m02': 1});
      final r = run('a', rev: 4, solved: ['m01', 'm03'], hints: {'m02': 2, 'm03': 1});
      final m = mergeCase(snap(l), snap(r));
      expect(m.outcome, MergeOutcome.combined);
      expect(m.merged.completedMissionIds, ['m01', 'm02', 'm03']);
      expect(m.merged.hintsUsed, {'m02': 2, 'm03': 1});
      expect(m.merged.rev, 5, reason: 'a new revision, above both');
      expect(m.merged.playMillis, 2000);
      expect(m.preserved, isNull);
    });

    test('same run, one side ahead: that side, unchanged', () {
      final l = run('a', rev: 2, solved: ['m01']);
      final r = run('a', rev: 5, solved: ['m01', 'm02']);
      expect(mergeCase(snap(l), snap(r)).outcome, MergeOutcome.tookRemote);
      expect(j(mergeCase(snap(l), snap(r)).merged), j(r));
      expect(mergeCase(snap(r), snap(l)).outcome, MergeOutcome.keptLocal);
    });

    test('two different runs with the same run number: a conflict, the other run is kept', () {
      final l = run('a', solved: ['m01']);
      final r = run('b', solved: ['m01', 'm02']);
      final m = mergeCase(snap(l), snap(r));
      expect(m.outcome, MergeOutcome.conflict);
      expect(m.merged.runId, 'b', reason: 'more solved plays on');
      expect(j(m.preserved!), j(l), reason: 'never thrown away');
    });

    test('a side with nothing played gives way without a conflict', () {
      final played = run('a', solved: ['m01']);
      final blank = const GameProgress(detectiveName: 'KIM', runId: 'z');
      expect(mergeCase(snap(blank), snap(played)).outcome, MergeOutcome.tookRemote);
      expect(mergeCase(snap(played), snap(blank)).outcome, MergeOutcome.keptLocal);
    });

    test('two saves from before runs that differ are not mixed: a conflict', () {
      final l = const GameProgress(detectiveName: 'KIM', introSeen: true, completedMissionIds: ['m01']);
      final r = const GameProgress(detectiveName: 'KIM', introSeen: true, completedMissionIds: ['m02']);
      final m = mergeCase(snap(l), snap(r));
      expect(m.outcome, MergeOutcome.conflict);
      expect(m.preserved, isNotNull);
    });

    test('a later epoch (a reset) wins; play from before it is returned to be kept', () {
      final old = run('a', solved: ['m01', 'm02']);
      final fresh = const GameProgress(runId: 'n');
      final m = mergeCase(snap(old, epoch: 0), snap(fresh, epoch: 1));
      expect(m.merged.runId, 'n');
      expect(j(m.preserved!), j(old));
      expect(mergeCase(snap(fresh, epoch: 1), snap(old, epoch: 0)).merged.runId, 'n');
    });

    test('idempotent: merging the result again with either side changes nothing', () {
      final cases = [
        (run('a', rev: 3, solved: ['m01', 'm02']), run('a', rev: 4, solved: ['m01', 'm03'])),
        (run('a', solved: ['m01']), run('b', seq: 1)),
        (run('a', solved: ['m01']), run('b', solved: ['m01', 'm02'])),
      ];
      for (final (l, r) in cases) {
        final once = mergeCase(snap(l), snap(r)).merged;
        expect(j(mergeCase(snap(once), snap(r)).merged), j(once));
        expect(j(mergeCase(snap(once), snap(once)).merged), j(once));
      }
    });

    test('the same play with its maps in another key order (a cloud round trip) is the same play', () {
      Object? reversed(Object? v) => switch (v) {
            Map() => {for (final k in v.keys.toList().reversed) k: reversed(v[k])},
            List() => [for (final e in v) reversed(e)],
            _ => v,
          };
      final l = run('a', rev: 3, solved: ['m01', 'm02'], hints: {'m01': 1, 'm02': 2})
          .copyWith(attempts: {'m01': 2, 'm02': 1}, xpRules: {'m01': 3, 'm02': 4});
      final r = GameProgress.fromJson(jsonDecode(jsonEncode(reversed(l.toJson()))) as Map<String, dynamic>);
      expect(jsonEncode(r.hintsUsed), isNot(jsonEncode(l.hintsUsed)), reason: 'the key order really differs');
      expect(sameProgress(l, r), isTrue);
      expect(canonicalJson(r.toJson()), canonicalJson(l.toJson()));
      expect(mergeCase(snap(l), snap(r)).outcome, MergeOutcome.same);
      expect(mergeCase(snap(r), snap(l)).outcome, MergeOutcome.same);
    });

    test('XP rules recorded on both sides are kept; operator data stays marked', () {
      final l = run('a', solved: ['m01']).copyWith(xpRules: {'m01': 3});
      final r = run('a', solved: ['m02']).copyWith(xpRules: {'m02': 4}, playtest: true);
      final m = mergeCase(snap(l), snap(r)).merged;
      expect(m.xpRules, {'m01': 3, 'm02': 4});
      expect(m.playtest, isTrue);
    });
  });

  group('season record', () {
    test('a case solved on either side is solved; the open case file is this device\'s', () {
      const l = SeasonProgress(activeEpisodeId: 'ep03', solvedEpisodeIds: ['ep01', 'ep02']);
      const r = SeasonProgress(activeEpisodeId: 'ep02', solvedEpisodeIds: ['ep01']);
      final m = mergeSeason(const SeasonSnapshot(epoch: 0, season: l), const SeasonSnapshot(epoch: 0, season: r));
      expect(m.merged.solvedEpisodeIds, ['ep01', 'ep02']);
      expect(m.merged.activeEpisodeId, 'ep03');
      expect(m.outcome, MergeOutcome.keptLocal);
    });

    test('operator data only if every side that solved it solved it as such', () {
      const l = SeasonProgress(solvedEpisodeIds: ['ep01', 'ep02'], playtestEpisodeIds: ['ep01', 'ep02']);
      const r = SeasonProgress(solvedEpisodeIds: ['ep01'], playtestEpisodeIds: []);
      final m = mergeSeason(const SeasonSnapshot(epoch: 0, season: l), const SeasonSnapshot(epoch: 0, season: r));
      expect(m.merged.playtestEpisodeIds, ['ep02'], reason: 'ep01 was solved in normal play on the other side');
    });

    test('a later epoch wins', () {
      const old = SeasonProgress(solvedEpisodeIds: ['ep01']);
      final m = mergeSeason(
        const SeasonSnapshot(epoch: 0, season: old),
        const SeasonSnapshot(epoch: 1, season: SeasonProgress.empty),
      );
      expect(m.merged.solvedEpisodeIds, isEmpty);
      expect(m.preserved!.solvedEpisodeIds, ['ep01']);
    });
  });

  group('wallet', () {
    const start = CoinEntry(key: 'start', amount: 20, source: CoinSource.start);
    const m01 = CoinEntry(key: 'mission:m01', amount: 30, source: CoinSource.mission);
    const m01Backfill = CoinEntry(key: 'mission:m01', amount: 30, source: CoinSource.backfill);
    const tipPaid = CoinEntry(key: 'tip:m01:2', amount: -20, source: CoinSource.tip);
    const tipHelp = CoinEntry(key: 'tip:m01:2', amount: 0, source: CoinSource.tip);
    WalletSnapshot w(List<CoinEntry> e, {int epoch = 0}) => WalletSnapshot(epoch: epoch, wallet: Wallet(e));

    test('the same key with the same amount is one entry: never paid twice', () {
      final m = mergeWallet(w([start, m01]), w([start, m01Backfill]));
      expect(m.merged.entries, hasLength(2));
      expect(m.merged.balance, 50);
      expect(m.conflicts, isEmpty);
      expect(m.outcome, MergeOutcome.same);
    });

    test('entries on one side only are added', () {
      final m = mergeWallet(w([start]), w([start, m01]));
      expect(m.merged.balance, 50);
      expect(m.outcome, MergeOutcome.tookRemote);
      expect(mergeWallet(w([start, m01]), w([start, tipPaid])).outcome, MergeOutcome.combined);
    });

    test('the same key with a different amount is a conflict: the local entry and the balance stay', () {
      final local = w([start, m01, tipHelp]);
      final m = mergeWallet(local, w([start, m01, tipPaid]));
      expect(m.outcome, MergeOutcome.conflict);
      expect(m.conflicts.single.key, 'tip:m01:2');
      expect(m.conflicts.single.local.amount, 0);
      expect(m.conflicts.single.remote.amount, -20);
      expect(m.merged.balance, local.wallet.balance, reason: 'no balance is adjusted');
      expect(m.merged.ownsTip('m01', 2), isTrue, reason: 'the tip stays owned');
    });

    test('nothing is made up: a merged balance below zero stays as it is (policy pending)', () {
      // Two devices each bought a different tip with the same 20 coins offline.
      const a = CoinEntry(key: 'tip:m01:2', amount: -20, source: CoinSource.tip);
      const b = CoinEntry(key: 'tip:m02:2', amount: -20, source: CoinSource.tip);
      final m = mergeWallet(w([start, a]), w([start, b]));
      expect(m.merged.balance, -20);
      expect(m.merged.entries.map((e) => e.key), ['start', 'tip:m01:2', 'tip:m02:2']);
    });

    test('a later epoch wins; the earlier wallet is returned to be kept', () {
      final m = mergeWallet(w([start, m01], epoch: 0), w([start], epoch: 1));
      expect(m.merged.balance, 20);
      expect(m.preserved!.balance, 50);
    });

    test('idempotent', () {
      final once = mergeWallet(w([start, m01]), w([start, tipPaid])).merged;
      expect(mergeWallet(w(once.entries), w([start, tipPaid])).outcome, MergeOutcome.keptLocal);
      expect(mergeWallet(w(once.entries), w(once.entries)).outcome, MergeOutcome.same);
    });
  });
}
