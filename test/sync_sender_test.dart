import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/models/wallet.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/data/repositories/progress_repository.dart';
import 'package:london_mystery/data/sync/cloud/cloud_catalog.dart';
import 'package:london_mystery/data/sync/cloud/cloud_codec.dart';
import 'package:london_mystery/data/sync/cloud/cloud_store.dart';
import 'package:london_mystery/data/sync/cloud/sync_retry_policy.dart';
import 'package:london_mystery/data/sync/cloud/sync_sender.dart';
import 'package:london_mystery/data/sync/outbox.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/cloud_stores.dart';

/// Phase 4.3A: the sync sender, on an in-memory store (always) and on the
/// Firestore emulator with the real rules (when FIRESTORE_EMULATOR_HOST is
/// set: `cd firebase && npm run test:sync`). Nothing touches a real project.
void main() {
  final season = MockEpisodeRepository.bundled();
  final episodeIds = [for (final e in season) e.id];
  final codec = CloudCodec(CloudCatalog.of(season));
  const uid = 'alice';
  const cloudPid = 'abcdefabcdefabcdefabcdefabcdef12';

  for (final onEmulator in [false, true]) {
    final label = onEmulator ? 'emulator' : 'memory';
    final skip = onEmulator && emulatorHost == null ? 'no Firestore emulator (cd firebase && npm run test:sync)' : null;

    group('sync sender ($label)', () {
      late SharedPreferences prefs;
      late CloudStore Function(String uid) storeFor;
      late MemoryCloudStore memory;
      late EmulatorCloudStore admin;
      var clock = DateTime.utc(2026, 10, 14, 12);

      setUp(() async {
        SharedPreferences.setMockInitialValues({});
        prefs = await SharedPreferences.getInstance();
        clock = DateTime.utc(2026, 10, 14, 12);
        if (onEmulator) {
          await EmulatorCloudStore.clear();
          admin = EmulatorCloudStore(null);
          await admin.put('consents/$uid', {'status': 'confirmed', 'schema': 1});
          await admin.put('users/$uid', {'schema': 1, 'locale': 'ko', 'region': 'KR', 'createdAt': clock});
          await admin.put('users/$uid/profiles/$cloudPid', {'schema': 1, 'detectiveName': 'ANNA', 'createdAt': clock});
          storeFor = (u) => EmulatorCloudStore(u);
        } else {
          memory = MemoryCloudStore();
          memory.docs['consents/$uid'] = {'status': 'confirmed'};
          storeFor = (_) => memory;
        }
      });

      /// A raw write as the admin (seeding bad data, a deletion marker…).
      Future<void> adminPut(String path, Map<String, Object?> data) async =>
          onEmulator ? admin.put(path, data) : memory.put(path, data);

      Future<Map<String, Object?>?> cloud(String path) => (onEmulator ? admin : memory).get(path);

      /// A device: its own saves of the profile, its own sender.
      ({SharedPrefsProgressRepository repo, FaultyStore store, SyncSender Function({bool Function()? valid}) sender})
          device(String localId) {
        final repo = SharedPrefsProgressRepository(prefs, profileId: localId);
        final store = FaultyStore(storeFor(uid));
        return (
          repo: repo,
          store: store,
          sender: ({bool Function()? valid}) => SyncSender(
                store: store,
                repo: repo,
                codec: codec,
                paths: const SyncPaths(uid, cloudPid),
                episodeIds: episodeIds,
                isStillValid: valid ?? () => true,
                now: () => clock,
              ),
        );
      }

      const deviceA = '1111111111111111111111111111aaaa';
      const deviceB = '2222222222222222222222222222bbbb';
      const paths = SyncPaths(uid, cloudPid);

      GameProgress playedA() => GameProgress(
            detectiveName: 'ANNA',
            introSeen: true,
            completedMissionIds: const ['m01'],
            attempts: const {'m01': 1},
            xpRules: const {'m01': 4},
            startedAt: clock,
            runId: 'run-a',
            runSeq: 1,
            rev: 1,
          );

      CoinEntry coin(String key, int amount, CoinSource source) => CoinEntry(key: key, amount: amount, source: source, at: clock);

      Future<void> play(SharedPrefsProgressRepository repo, {GameProgress? progress, List<CoinEntry> coins = const []}) async {
        if (progress != null) await repo.save(progress, 'ep01');
        await repo.saveSeason(const SeasonProgress(activeEpisodeId: 'ep01'));
        var w = repo.loadWallet() ?? Wallet.empty;
        for (final c in coins) {
          w = w.adding(c);
        }
        if (coins.isNotEmpty) await repo.saveWallet(w);
      }

      test('a normal send: epoch, case, season and coins; confirmed and acknowledged', () async {
        final a = device(deviceA);
        await play(a.repo, progress: playedA(), coins: [coin('start', 20, CoinSource.start), coin('mission:m01', 30, CoinSource.mission)]);
        final r = await a.sender().run();
        expect(r.stop, isNull);
        expect(r.sent, containsAll(['case:ep01', 'season', 'wallet:start', 'wallet:mission:m01']));
        expect((await cloud(paths.meta))!['epoch'], 0);
        final c = (await cloud(paths.caseDoc('ep01')))!;
        expect(c['cloudVersion'], 1);
        expect(((c['progress']! as Map)['completedMissionIds']! as List), ['m01']);
        expect((await cloud(paths.walletSummary))!['balance'], 50);
        expect(a.repo.outbox.events, isEmpty, reason: 'every event acknowledged');
        expect(a.repo.cloudSync.of('case:ep01').confirmedVersion, 1);
        expect(a.repo.cloudSync.of('wallet').confirmedVersion, 2);
      }, skip: skip);

      test('sending again: nothing new is written; a change goes up as exactly +1', () async {
        final a = device(deviceA);
        await play(a.repo, progress: playedA(), coins: [coin('start', 20, CoinSource.start)]);
        await a.sender().run();
        final r = await a.sender().run();
        expect(r.sent, isEmpty);
        await a.repo.save(playedA().copyWith(completedMissionIds: ['m01', 'm02'], rev: 2), 'ep01');
        await a.sender().run();
        expect((await cloud(paths.caseDoc('ep01')))!['cloudVersion'], 2);
        expect((await cloud(paths.walletSummary))!['balance'], 20, reason: 'no second grant');
      }, skip: skip);

      test('the server committed but the answer was lost: kept, then reconciled without a second grant', () async {
        final a = device(deviceA);
        await play(a.repo, progress: playedA(), coins: [coin('start', 20, CoinSource.start)]);
        a.store.loseNextAnswer = true; // the epoch step commits, its answer is lost
        var r = await a.sender().run();
        expect(r.stop, SyncStop.cloudUnavailable);
        expect(a.repo.outbox.pending, isNotEmpty, reason: 'nothing dropped on an unclear failure');
        r = await a.sender().run();
        expect(r.stop, isNull);
        // Now lose the answer of the coin event itself.
        await play(a.repo, coins: [coin('mission:m01', 30, CoinSource.mission)]);
        a.store.loseNextAnswer = true;
        // The case and season are already up; the next transaction is the coin.
        r = await a.sender().run();
        expect(a.repo.outbox.pending.where((e) => e.kind == OutboxKind.walletEntry), isNotEmpty);
        clock = clock.add(const Duration(hours: 2)); // past the back-off
        r = await a.sender().run();
        expect(r.sent, contains('wallet:mission:m01'));
        expect((await cloud(paths.walletSummary))!['balance'], 50, reason: 'found already there: not paid twice');
        expect(a.repo.outbox.events, isEmpty);
      }, skip: skip);

      test('a race between read and commit: the transaction reruns, merges, and the device applies it once', () async {
        final a = device(deviceA);
        final b = device(deviceB);
        await play(a.repo, progress: playedA());
        await a.sender().run();
        // B plays another mission of the same run.
        await play(b.repo, progress: playedA().copyWith(completedMissionIds: ['m01', 'm03'], rev: 3));
        await a.repo.save(playedA().copyWith(completedMissionIds: ['m01', 'm02'], rev: 2), 'ep01');
        // B sends while A's transaction is between its reads and its commit.
        a.store.duringNext = () async => b.sender().run();
        final r = await a.sender().run();
        expect(r.stop, isNull);
        expect(a.store.bodies, greaterThan(2), reason: 'the body ran again after the race');
        final c = (await cloud(paths.caseDoc('ep01')))!;
        expect(((c['progress']! as Map)['completedMissionIds']! as List).toSet(), {'m01', 'm02', 'm03'});
        expect(a.repo.load('ep01').completedMissionIds.toSet(), {'m01', 'm02', 'm03'});
        expect(a.repo.conflicts, isEmpty);
        expect(a.repo.outbox.events.where((e) => e.state == OutboxState.inFlight), isEmpty);
      }, skip: skip);

      test('two devices: each version exactly +1; both end with everything; a shared coin once', () async {
        final a = device(deviceA);
        final b = device(deviceB);
        await play(a.repo, progress: playedA(), coins: [coin('start', 20, CoinSource.start), coin('mission:m01', 30, CoinSource.mission)]);
        await play(b.repo, progress: playedA().copyWith(completedMissionIds: ['m02'], runId: 'run-a', rev: 1),
            coins: [coin('start', 20, CoinSource.start), coin('mission:m02', 30, CoinSource.mission)]);
        await a.sender().run();
        await b.sender().run(); // B merges A's version first
        expect(b.repo.load('ep01').completedMissionIds.toSet(), {'m01', 'm02'});
        expect(a.repo.load('ep01').completedMissionIds, ['m01'], reason: 'A has sent nothing new: receiving alone is restore (4.4)');
        // A's next change goes up merged with B's.
        await a.repo.save(a.repo.load('ep01').copyWith(completedMissionIds: ['m01', 'm03'], rev: 5), 'ep01');
        await a.sender().run();
        final c = (await cloud(paths.caseDoc('ep01')))!;
        expect(((c['progress']! as Map)['completedMissionIds']! as List).toSet(), {'m01', 'm02', 'm03'});
        expect(c['cloudVersion'], 3, reason: 'A 1, B 2, A 3: exactly +1 each');
        expect(a.repo.load('ep01').completedMissionIds.toSet(), {'m01', 'm02', 'm03'});
        expect((await cloud(paths.walletSummary))!['balance'], 80, reason: 'start once, two missions');
      }, skip: skip);

      test('New Adventure: the epoch goes up first; a device of the old epoch adopts it and never writes old data', () async {
        final a = device(deviceA);
        final b = device(deviceB);
        await play(a.repo, progress: playedA(), coins: [coin('start', 20, CoinSource.start)]);
        await play(b.repo, progress: playedA(), coins: [coin('start', 20, CoinSource.start)]);
        await a.sender().run();
        await b.sender().run();
        await a.repo.clear(); // New Adventure on A: epoch 1
        expect(a.repo.epoch, 1);
        await play(a.repo, progress: const GameProgress(detectiveName: 'ANNA', introSeen: true), coins: [coin('start', 20, CoinSource.start)]);
        await a.sender().run();
        expect((await cloud(paths.meta))!['epoch'], 1);
        expect((await cloud(paths.caseDoc('ep01')))!['epoch'], 1);
        expect((await cloud(paths.walletEvent('1_start')))!['epoch'], 1);
        // B still plays the old epoch, offline.
        await b.repo.save(playedA().copyWith(completedMissionIds: ['m01', 'm02'], rev: 2), 'ep01');
        final r = await b.sender().run();
        expect(r.adoptedEpoch, 1);
        expect(b.repo.epoch, 1);
        expect(b.repo.conflicts.any((x) => x['kind'] == 'epoch'), isTrue, reason: 'its old saves kept first');
        final c = (await cloud(paths.caseDoc('ep01')))!;
        expect(c['epoch'], 1);
        expect(((c['progress']! as Map)['completedMissionIds'] as List?) ?? const [], isNot(contains('m02')),
            reason: 'old-epoch progress never comes back');
        expect((await cloud(paths.walletSummary))!['balance'], 20);
      }, skip: skip);

      test('bad data on the server: never applied or overwritten; a conflict is kept', () async {
        final a = device(deviceA);
        await play(a.repo, progress: playedA());
        await a.sender().run();
        await adminPut(paths.caseDoc('ep01'), {
          ...(await cloud(paths.caseDoc('ep01')))!,
          'cloudVersion': 9,
          'progress': {'completedMissionIds': ['m01'], 'attempts': {'m01': -1}},
        });
        await a.repo.save(playedA().copyWith(completedMissionIds: ['m01', 'm02'], rev: 2), 'ep01');
        final r = await a.sender().run();
        expect(r.conflicted, contains('case:ep01'));
        expect(a.repo.conflicts.any((x) => x['kind'] == 'cloudInvalid'), isTrue);
        expect(a.repo.outbox.conflicted, isNotEmpty);
        expect((await cloud(paths.caseDoc('ep01')))!['cloudVersion'], 9, reason: 'not overwritten');
        expect(a.repo.load('ep01').completedMissionIds, ['m01', 'm02'], reason: 'local untouched');
      }, skip: skip);

      test('coins: never below zero across devices; a conflicting amount is a permanent conflict', () async {
        final a = device(deviceA);
        final b = device(deviceB);
        await play(a.repo, coins: [coin('start', 20, CoinSource.start), coin('tip:m01:2', -20, CoinSource.tip)]);
        await play(b.repo, coins: [coin('start', 20, CoinSource.start), coin('tip:m02:2', -20, CoinSource.tip), coin('tip:m01:2', 0, CoinSource.tip)]);
        await a.sender().run();
        final r = await b.sender().run();
        expect((await cloud(paths.walletSummary))!['balance'], 0, reason: 'never below zero');
        expect(r.conflicted.toSet(), {'wallet:tip:m02:2', 'wallet:tip:m01:2'});
        expect(b.repo.conflicts.map((x) => x['reason']).toSet(),
            {'the cloud balance would go below zero', 'same key, different amount'});
        expect(b.repo.outbox.conflicted.length, 2);
        // Conflicts are never retried or cleared automatically.
        clock = clock.add(const Duration(days: 2));
        SyncSender.prepareAtStart(b.repo);
        await b.sender().run();
        expect(b.repo.outbox.conflicted.length, 2);
        expect((await cloud(paths.walletSummary))!['balance'], 0);
      }, skip: skip);

      test('an event already there but no valid summary of this epoch: kept as a conflict, never acknowledged', () async {
        for (final (name, summary) in <(String, Map<String, Object?>?)>[
          ('no summary', null),
          ('an earlier epoch summary', {'epoch': 0, 'cloudVersion': 1, 'balance': 20, 'lastEventId': '0_start', 'updatedAt': clock}),
          ('a malformed summary', {'epoch': 1, 'cloudVersion': 'x', 'balance': 20, 'lastEventId': '1_start', 'updatedAt': clock}),
        ]) {
          if (onEmulator) {
            await EmulatorCloudStore.clear();
            await admin.put('consents/$uid', {'status': 'confirmed', 'schema': 1});
            await admin.put('users/$uid', {'schema': 1, 'locale': 'ko', 'region': 'KR', 'createdAt': clock});
            await admin.put('users/$uid/profiles/$cloudPid', {'schema': 1, 'detectiveName': 'ANNA', 'createdAt': clock});
          } else {
            memory.docs.removeWhere((k, _) => k.startsWith('users/'));
          }
          SharedPreferences.setMockInitialValues({});
          prefs = await SharedPreferences.getInstance();
          final a = device(deviceA);
          await a.repo.clear(); // epoch 1, as on the server
          await adminPut(paths.meta, {'epoch': 1, 'cloudVersion': 2, 'updatedAt': clock});
          // The event made it (a lost answer), the summary did not, or is wrong.
          await adminPut(paths.walletEvent('1_start'), {'epoch': 1, 'key': 'start', 'amount': 20, 'source': 'start', 'at': clock});
          if (summary != null) await adminPut(paths.walletSummary, summary);
          await play(a.repo, coins: [coin('start', 20, CoinSource.start)]);
          final r = await a.sender().run();
          expect(r.conflicted, contains('wallet:start'), reason: name);
          expect(a.repo.outbox.conflicted.single.subject, 'start', reason: '$name: kept, not acknowledged');
          expect(a.repo.cloudSync.of('wallet').confirmedVersion, isNull, reason: '$name: nothing confirmed');
          expect(a.repo.conflicts.any((x) => x['subject'] == 'wallet:summary'), isTrue, reason: name);
        }
      }, skip: skip);

      test('refused (consent, deletion): stops, keeps every queued change', () async {
        final a = device(deviceA);
        await play(a.repo, progress: playedA(), coins: [coin('start', 20, CoinSource.start)]);
        await adminPut('consents/$uid', {'status': 'unconfirmed', 'schema': 1});
        if (!onEmulator) a.store.failNext = CloudFailure.permissionDenied;
        var r = await a.sender().run();
        expect(r.stop, SyncStop.consentNotConfirmed);
        expect(a.repo.outbox.pending.length, a.repo.outbox.events.length, reason: 'nothing dropped, nothing in flight');
        await adminPut('consents/$uid', {'status': 'confirmed', 'schema': 1});
        await adminPut('deletions/$uid', {'status': 'started'});
        if (!onEmulator) a.store.failNext = CloudFailure.permissionDenied;
        r = await a.sender().run();
        expect(r.stop, SyncStop.deletionInProgress);
        expect(a.repo.outbox.pending, isNotEmpty);
      }, skip: skip);

      test('offline: nothing dropped; back-off; stalled after 10; resumed with a full resync at the next start', () async {
        final a = device(deviceA);
        await play(a.repo, progress: playedA());
        a.store.down = CloudFailure.unavailable;
        var r = await a.sender().run();
        expect(r.stop, SyncStop.cloudUnavailable);
        expect(a.repo.outbox.pending, isNotEmpty);
        a.store.down = null;
        await a.sender().run(); // meta and case up
        await a.repo.save(playedA().copyWith(completedMissionIds: ['m01', 'm02'], rev: 2), 'ep01');
        for (var i = 1; i <= SyncRetryPolicy.standard.stallAfter; i++) {
          a.store.duringNext = () async => a.store.down = CloudFailure.unavailable; // dies at commit time
          a.store.down = null;
          clock = clock.add(const Duration(hours: 2));
          r = await a.sender().run();
          a.store.down = null;
        }
        expect(a.repo.cloudSync.of('case:ep01').stalled, isTrue);
        expect(a.repo.outbox.stalled, isNotEmpty);
        clock = clock.add(const Duration(days: 1));
        r = await a.sender().run();
        expect(r.sent, isNot(contains('case:ep01')), reason: 'no automatic retry while stalled');
        SyncSender.prepareAtStart(a.repo); // the next start
        expect(a.repo.cloudSync.needsFullResync, isTrue);
        r = await a.sender().run();
        expect(r.sent, contains('case:ep01'));
        expect(a.repo.cloudSync.needsFullResync, isFalse);
        expect(((await cloud(paths.caseDoc('ep01')))!['progress']! as Map)['completedMissionIds'], ['m01', 'm02']);
      }, skip: skip);

      test('the gate closes mid-run (sign-out, account or profile switch): nothing applied, nothing dropped; reconciled later', () async {
        final a = device(deviceA);
        await play(a.repo, progress: playedA());
        var valid = true;
        // The run's own epoch step is fine; the gate closes during the case's transaction.
        await a.sender(valid: () => valid).run();
        await a.repo.save(playedA().copyWith(completedMissionIds: ['m01', 'm02'], rev: 2), 'ep01');
        final before = jsonEncode(a.repo.load('ep01').toJson());
        // Signed out just before the case's commit (the run's first
        // transaction is the epoch check; the second is the case).
        var transactions = 0;
        Future<void> hook() async {
          if (++transactions == 1) {
            a.store.duringNext = hook;
            return;
          }
          valid = false;
        }

        a.store.duringNext = hook;
        final r = await a.sender(valid: () => valid).run();
        expect(r.stop, SyncStop.runNoLongerValid);
        expect(jsonEncode(a.repo.load('ep01').toJson()), before, reason: 'nothing applied to the device');
        expect(a.repo.outbox.pending, isNotEmpty, reason: 'released, not acknowledged');
        expect(a.repo.cloudSync.of('case:ep01').confirmedVersion, 1, reason: 'the commit was not confirmed');
        // The server did commit; the next valid run reconciles (merge, +1).
        valid = true;
        final again = await a.sender(valid: () => valid).run();
        expect(again.stop, isNull);
        expect(a.repo.outbox.events, isEmpty);
        expect((await cloud(paths.caseDoc('ep01')))!['cloudVersion'], 3);
        // Closed from the start: nothing at all.
        expect((await a.sender(valid: () => false).run()).stop, SyncStop.runNoLongerValid);
      }, skip: skip);

      test('older saves and an old (v1) outbox are sent as they are', () async {
        final a = device(deviceA);
        await a.repo.save(const GameProgress(detectiveName: 'TESTER', completedMissionIds: ['m01'], lookupsRecorded: false), 'ep01');
        // Rewrite the outbox as Phase 2 (v1) wrote it.
        final v1 = jsonDecode(prefs.getString(AppConstants.outboxKey(deviceA))!) as Map<String, dynamic>;
        await prefs.setString(AppConstants.outboxKey(deviceA), jsonEncode({...v1, 'v': 1}));
        final r = await SyncSender(
          store: a.store,
          repo: SharedPrefsProgressRepository(prefs, profileId: deviceA),
          codec: codec,
          paths: paths,
          episodeIds: episodeIds,
          isStillValid: () => true,
          now: () => clock,
        ).run();
        expect(r.stop, isNull);
        expect(r.sent, contains('case:ep01'));
        expect((await cloud(paths.caseDoc('ep01')))!['runId'], isNull);
      }, skip: skip);
    });
  }

  group('transaction bodies are pure (memory store)', () {
    test('a body run several times changes the device once and grants once', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final memory = MemoryCloudStore();
      final store = FaultyStore(memory);
      final repo = SharedPrefsProgressRepository(prefs, profileId: '3333333333333333333333333333cccc');
      await repo.saveWallet(Wallet.empty.adding(const CoinEntry(key: 'start', amount: 20, source: CoinSource.start)));
      final sender = SyncSender(
        store: store,
        repo: repo,
        codec: codec,
        paths: const SyncPaths(uid, cloudPid),
        episodeIds: episodeIds,
        isStillValid: () => true,
      );
      await sender.run(); // meta
      await repo.saveWallet(repo.loadWallet()!.adding(const CoinEntry(key: 'mission:m01', amount: 30, source: CoinSource.mission)));
      // Two foreign writes force the coin's body to run three times.
      var races = 2;
      Future<void> race() async {
        memory.put('users/$uid/profiles/$cloudPid/sync/meta', {...memory.docs['users/$uid/profiles/$cloudPid/sync/meta']!});
        if (--races > 0) store.duringNext = race;
      }

      store.duringNext = race;
      final bodiesBefore = store.bodies;
      await SyncSender(
        store: store,
        repo: repo,
        codec: codec,
        paths: const SyncPaths(uid, cloudPid),
        episodeIds: episodeIds,
        isStillValid: () => true,
      ).run();
      expect(store.bodies - bodiesBefore, greaterThanOrEqualTo(3));
      expect(memory.docs['users/$uid/profiles/$cloudPid/wallet/summary']!['balance'], 50);
      expect(repo.outbox.events, isEmpty);
      expect(repo.loadWallet()!.balance, 50, reason: 'the device wallet is as it was: nothing paid twice');
    });
  });
}
