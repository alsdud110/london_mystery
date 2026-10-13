import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/profile.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/models/wallet.dart';
import 'package:london_mystery/data/repositories/profile_store.dart';
import 'package:london_mystery/data/repositories/progress_repository.dart';
import 'package:london_mystery/data/sync/merge.dart';
import 'package:london_mystery/data/sync/outbox.dart';
import 'package:london_mystery/data/sync/sync_applier.dart';
import 'package:london_mystery/data/sync/sync_policy.dart';
import 'package:shared_preferences/shared_preferences.dart';

const pid = 'dddddddddddddddddddddddddddddddd';
const episodes = ['ep01', 'ep02'];

Future<SharedPrefsProgressRepository> repoWith(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPrefsProgressRepository(await SharedPreferences.getInstance(), profileId: pid);
}

Map<String, Object?> snapshot(SharedPrefsProgressRepository repo) => {
      'ep01': repo.load('ep01').toJson(),
      'season': repo.loadSeason().toJson(),
      'wallet': repo.loadWallet()?.toJson(),
      'outbox': repo.outbox.events.length,
      'conflicts': repo.conflicts.length,
    };

GameProgress played(String runId, List<String> solved) => GameProgress(
      detectiveName: 'KIM',
      introSeen: true,
      completedMissionIds: solved,
      startedAt: DateTime(2026, 10, 1),
      playMillis: 0, // as a case under way reads back
      runId: runId,
    );

void main() {
  group('applying another copy of the profile', () {
    test('applying the same data twice changes nothing the second time', () async {
      final repo = await repoWith({});
      repo.save(played('a', ['m01']), 'ep01');
      final applier = SyncApplier(repo, episodeIds: episodes);
      final remote = CaseSnapshot(epoch: 0, progress: played('a', ['m01', 'm02']).copyWith(rev: 3));
      expect(applier.applyCase('ep01', remote), MergeOutcome.tookRemote);
      final after = snapshot(repo);
      expect(applier.applyCase('ep01', remote), MergeOutcome.same);
      expect(snapshot(repo), after);
    });

    test('taken from the other side: stored, not sent back; combined: sent', () async {
      final repo = await repoWith({});
      final applier = SyncApplier(repo, episodeIds: episodes);
      applier.applyCase('ep01', CaseSnapshot(epoch: 0, progress: played('a', ['m01'])));
      expect(repo.outbox.isEmpty, isTrue);
      repo.save(played('a', ['m01', 'm02']).copyWith(rev: 1), 'ep01');
      final queued = repo.outbox.events.length;
      applier.applyCase('ep01', CaseSnapshot(epoch: 0, progress: played('a', ['m01', 'm03']).copyWith(rev: 1)));
      expect(repo.load('ep01').completedMissionIds, ['m01', 'm02', 'm03']);
      expect(repo.outbox.events.where((e) => e.subject == 'ep01'), hasLength(1));
      expect(repo.outbox.events.length, queued, reason: 'the waiting state for ep01 is replaced by the merged one');
    });

    test('a conflict keeps the losing run, once, however often it is applied', () async {
      final repo = await repoWith({});
      repo.save(played('a', ['m01', 'm02']), 'ep01');
      final applier = SyncApplier(repo, episodeIds: episodes);
      final other = CaseSnapshot(epoch: 0, progress: played('b', ['m01']));
      expect(applier.applyCase('ep01', other), MergeOutcome.conflict);
      applier.applyCase('ep01', other);
      expect(repo.load('ep01').runId, 'a');
      expect(repo.conflicts, hasLength(1));
      expect(repo.conflicts.single['kept']['runId'], 'b');
    });

    test('coins: an entry on both sides is paid once; a different amount is kept as a conflict', () async {
      final repo = await repoWith({});
      repo.saveWallet(const Wallet([
        CoinEntry(key: 'start', amount: 20, source: CoinSource.start),
        CoinEntry(key: 'tip:m01:2', amount: 0, source: CoinSource.tip),
      ]));
      final applier = SyncApplier(repo, episodeIds: episodes);
      const remote = Wallet([
        CoinEntry(key: 'start', amount: 20, source: CoinSource.start),
        CoinEntry(key: 'mission:m01', amount: 30, source: CoinSource.mission),
        CoinEntry(key: 'tip:m01:2', amount: -20, source: CoinSource.tip),
      ]);
      expect(applier.applyWallet(0, remote), MergeOutcome.conflict);
      expect(applier.applyWallet(0, remote), MergeOutcome.conflict);
      final w = repo.loadWallet()!;
      expect(w.balance, 50, reason: '20 + 30; the local free tip stays free');
      expect(w.entries.map((e) => e.key), ['start', 'tip:m01:2', 'mission:m01']);
      expect(repo.conflicts.single['subject'], 'tip:m01:2');
      expect(repo.outbox.events.where((e) => e.subject == 'mission:m01'), isEmpty, reason: 'came from there');
    });

    test('a reset made elsewhere: this side moves to it, its own saves kept first', () async {
      final repo = await repoWith({});
      repo.save(played('a', ['m01']), 'ep01');
      repo.saveSeason(const SeasonProgress(solvedEpisodeIds: ['ep01']));
      repo.saveWallet(const Wallet([CoinEntry(key: 'start', amount: 20, source: CoinSource.start)]));
      final applier = SyncApplier(repo, episodeIds: episodes);
      applier.applySeason(1, SeasonProgress.empty);
      expect(repo.epoch, 1);
      expect(repo.loadSeason().solvedEpisodeIds, isEmpty);
      expect(repo.load('ep01').completedMissionIds, isEmpty);
      expect(repo.loadWallet(), isNull);
      expect(repo.outbox.isEmpty, isTrue, reason: 'changes of the old epoch are not sent');
      final kept = repo.conflicts.single;
      expect(kept['kind'], 'epoch');
      expect((kept['local'] as Map).keys, containsAll(['ep01', 'season', 'wallet']));
      // Data from the old epoch is ignored from now on.
      expect(applier.applyCase('ep01', CaseSnapshot(epoch: 0, progress: played('x', ['m01']))), MergeOutcome.keptLocal);
      expect(repo.load('ep01').completedMissionIds, isEmpty);
    });
  });

  group('what may leave the device', () {
    OutboxEvent e(String id, {bool playtest = false, String profileId = pid}) => OutboxEvent(
          id: id,
          profileId: profileId,
          kind: OutboxKind.walletEntry,
          subject: id,
          epoch: 0,
          playtest: playtest,
          createdAt: DateTime(2026),
        );
    final box = Outbox([e('normal'), e('test', playtest: true), e('other', profileId: 'eeeeeeeeeeeeeeee')]);
    const account = DetectiveProfile(id: pid, kind: ProfileKind.account);

    test('operator data stays; normal play next to it goes', () {
      expect(SyncPolicy.uploadable(box, account, operatorToolsInBuild: false).map((x) => x.id), ['normal']);
    });

    test('nothing goes from a guest, a Phase 1 playtest profile, one waiting for review, or a test build', () {
      expect(SyncPolicy.uploadable(box, const DetectiveProfile(id: pid), operatorToolsInBuild: false), isEmpty);
      expect(
        SyncPolicy.uploadable(
          box,
          const DetectiveProfile(id: pid, kind: ProfileKind.account, origin: ProfileOrigin.playtest),
          operatorToolsInBuild: false,
        ),
        isEmpty,
        reason: 'its records cannot be told apart, so none is treated as normal',
      );
      expect(SyncPolicy.uploadable(box, account.copyWith(needsReview: true), operatorToolsInBuild: false), isEmpty);
      expect(SyncPolicy.uploadable(box, account, operatorToolsInBuild: true), isEmpty);
    });

    test('a case run, a season solve and a coin entry made by the operator are left out', () {
      expect(SyncPolicy.caseForUpload(const GameProgress(playtest: true)), isNull);
      expect(SyncPolicy.caseForUpload(const GameProgress(detectiveName: 'KIM')), isNotNull);
      expect(
        SyncPolicy.seasonForUpload(
          const SeasonProgress(solvedEpisodeIds: ['ep01', 'ep02'], playtestEpisodeIds: ['ep01']),
        )['solvedEpisodeIds'],
        ['ep02'],
      );
      expect(SyncPolicy.entryMayUpload(const CoinEntry(key: 'k', amount: 1, source: CoinSource.mission, playtest: true)),
          isFalse);
    });
  });

  group('saves from before stay readable as they were', () {
    test('entries, seasons and case saves without the new fields keep their shape', () {
      final entry = {'key': 'mission:m01', 'amount': 30, 'source': 'mission'};
      expect(CoinEntry.fromJson(entry)!.toJson(), entry);
      final season = {'activeEpisodeId': 'ep02', 'solvedEpisodeIds': ['ep01']};
      expect(SeasonProgress.fromJson(season).toJson(), season);
      final old = GameProgress.fromJson({'detectiveName': 'KIM', 'completedMissionIds': ['m01']});
      expect(old.toJson().containsKey('playtest'), isFalse);
      expect(old.playtest, isFalse);
    });

    test('a season record cannot name an unsolved case as operator data', () {
      final s = SeasonProgress.fromJson({
        'solvedEpisodeIds': ['ep01'],
        'playtestEpisodeIds': ['ep01', 'ep05'],
      });
      expect(s.playtestEpisodeIds, ['ep01']);
      expect(s.markSolved('ep01', playtest: true).playtestEpisodeIds, ['ep01'], reason: 'an operator repeat changes nothing');
      expect(s.markSolved('ep01').playtestEpisodeIds, isEmpty, reason: 'a later normal solve makes it a normal solve');
    });
  });

  group('install id and profile recovery', () {
    test('one install id, kept across starts; not part of any profile', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await ProfileStore(prefs).bootstrap();
      final id = ProfileStore(prefs).installId;
      expect(id, isNotNull);
      await ProfileStore(prefs).bootstrap();
      expect(ProfileStore(prefs).installId, id);
      expect(ProfileStore(prefs).read()!.active.id, isNot(id));
    });

    test('registry unreadable with several saved profiles: all kept, not chosen by size, all wait for review',
        () async {
      const older = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
      const newer = 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb';
      String save(GameProgress p) => jsonEncode(p.toJson());
      SharedPreferences.setMockInitialValues({
        AppConstants.profilesStorageKey: 'garbage',
        // The older profile has more saves (more keys) …
        for (final ep in ['ep01', 'ep02', 'ep03'])
          AppConstants.profileKey(older, AppConstants.progressKeyFor(ep)):
              save(GameProgress(detectiveName: 'OLD', introSeen: true, startedAt: DateTime(2026, 1, 1))),
        // … the newer one was played last.
        AppConstants.profileKey(newer, AppConstants.progressStorageKey):
            save(GameProgress(detectiveName: 'NEW', introSeen: true, startedAt: DateTime(2026, 9, 1))),
      });
      final prefs = await SharedPreferences.getInstance();
      final session = await ProfileStore(prefs).bootstrap();
      expect(session.profileId, newer, reason: 'played last, not the one with the most saves');
      final registry = ProfileStore(prefs).read()!;
      expect(registry.profiles.map((p) => p.id).toSet(), {older, newer}, reason: 'nothing dropped');
      expect(registry.profiles.every((p) => p.needsReview && !p.syncable), isTrue);
      expect(registry.byId(older)!.detectiveName, 'OLD');
      expect(prefs.getString(AppConstants.profileKey(older, AppConstants.progressKeyFor('ep02'))), isNotNull);
    });

    test('the copy record names the guest: it plays, the other profiles found are kept for review', () async {
      const guest = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
      const other = 'ffffffffffffffffffffffffffffffff';
      SharedPreferences.setMockInitialValues({
        AppConstants.legacyMigrationKey: jsonEncode({'state': 'done', 'profileId': guest}),
        AppConstants.profileKey(guest, AppConstants.progressStorageKey): jsonEncode(const GameProgress().toJson()),
        AppConstants.profileKey(other, AppConstants.progressStorageKey): jsonEncode(const GameProgress().toJson()),
      });
      final prefs = await SharedPreferences.getInstance();
      final session = await ProfileStore(prefs).bootstrap();
      expect(session.profileId, guest);
      expect(session.profile.needsReview, isFalse);
      expect(ProfileStore(prefs).read()!.byId(other)!.needsReview, isTrue);
    });
  });
}
