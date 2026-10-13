import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/core/cloud/cloud_bootstrap.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/profile.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/models/wallet.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/data/repositories/progress_repository.dart';
import 'package:london_mystery/data/sync/cloud/cloud_catalog.dart';
import 'package:london_mystery/data/sync/cloud/cloud_codec.dart';
import 'package:london_mystery/data/sync/cloud/cloud_sync_meta.dart';
import 'package:london_mystery/data/sync/cloud/sync_retry_policy.dart';
import 'package:london_mystery/data/sync/outbox.dart';
import 'package:london_mystery/features/account/account_controller.dart';
import 'package:london_mystery/features/account/auth_service.dart';
import 'package:london_mystery/features/account/consent.dart';
import 'package:london_mystery/features/sync/sync_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Phase 4.2: local ↔ cloud documents, cloud data checks, cloudVersion
/// bookkeeping, the Sync Gate, Outbox conflicted/stalled, retry and back-off.
/// No Firestore: "the server" here is a map the test hands back.
void main() {
  final season = MockEpisodeRepository.bundled();
  final catalog = CloudCatalog.of(season);
  final codec = CloudCodec(catalog);
  final at = DateTime.utc(2026, 10, 14, 9);

  /// What a server hands back after storing [write]: the server time filled in.
  Map<String, Object?> served(Map<String, Object?> write) =>
      {for (final e in write.entries) e.key: e.value is CloudServerTime ? at : e.value};

  GameProgress played({bool playtest = false}) => GameProgress(
        detectiveName: 'ANNA',
        introSeen: true,
        completedMissionIds: const ['m01', 'm02'],
        attempts: const {'m01': 2, 'm02': 1},
        wrongAnswers: const {'m01': 1},
        hintsUsed: const {'m01': 2},
        missionStartedAt: {'m03': at},
        missionStartPlayMillis: const {'m03': 1200},
        solveSeconds: const {'m01': 40, 'm02': 25},
        badgeIds: const ['firstClue'],
        lookedUpWords: const ['crown'],
        xpRules: const {'m01': 4, 'm02': 3},
        behavior: const BehaviorLog(rechecked: ['m01'], evidenceViewed: ['e01'], words: ['crown']),
        startedAt: at,
        playMillis: 600000,
        runId: 'run-1',
        runSeq: 1,
        rev: 7,
        playtest: playtest,
      );

  Map<String, Object?> caseDoc({Map<String, Object?> progress = const {}, Map<String, Object?> doc = const {}}) {
    final w = codec.caseToCloud(caseId: 'ep01', progress: played(), epoch: 2, cloudVersion: 5).data!;
    return {
      ...served(w),
      'progress': {...(w['progress']! as Map<String, Object?>), ...progress},
      ...doc,
    };
  }

  group('the catalog is the shipped season', () {
    test('cases, missions, tips, coins', () {
      expect(catalog.caseIds, [for (final e in season) e.id]);
      expect(catalog.missionsOf('ep01'), ['m01', 'm02', 'm03', 'm04', 'm05', 'final']);
      expect(catalog.coinsOf('final'), AppConstants.finalCoins);
      expect(catalog.coinsOf('ep02_m1'), AppConstants.missionCoins);
      expect(catalog.coinsOf('made_up'), isNull);
      expect(catalog.hintsOf('m01'), season.first.missions.first.hints.length);
    });

    test('the codec keeps exactly the rules\' progress fields', () {
      final rules = File('firebase/firestore.rules').readAsStringSync();
      final list = RegExp(r"return p\.keys\(\)\.hasOnly\(\[([^\]]+)\]\)").firstMatch(rules)!.group(1)!;
      final fields = RegExp(r"'([A-Za-z]+)'").allMatches(list).map((m) => m.group(1)).toSet();
      expect(fields, CloudCodec.progressFields);
    });
  });

  group('cases: up and back down', () {
    test('a played case goes up in the rules\' shape and comes back the same', () {
      final w = codec.caseToCloud(caseId: 'ep01', progress: played(), epoch: 2, cloudVersion: 5);
      expect(w.ok, isTrue);
      final doc = w.data!;
      expect(doc.keys.toSet(), {'epoch', 'runId', 'runSeq', 'cloudVersion', 'progress', 'updatedAt'});
      expect(doc['updatedAt'], same(CloudServerTime.instance));
      expect((doc['progress']! as Map).containsKey('playtest'), isFalse);
      final back = codec.readCase('ep01', served(doc), serverEpoch: 2);
      expect(back, isA<CloudAccepted>());
      final a = back as CloudAccepted;
      expect(a.cloudVersion, 5);
      expect(jsonEncode(a.value.progress.toJson()), jsonEncode(played().toJson()));
      expect(a.value.epoch, 2);
    });

    test('an old save (no run, no xp rules, legacy shape) goes up and back', () {
      const old = GameProgress(detectiveName: 'TESTER', completedMissionIds: ['m01'], lookupsRecorded: false);
      final doc = codec.caseToCloud(caseId: 'ep01', progress: old, epoch: 0, cloudVersion: 1).data!;
      expect(doc['runId'], isNull);
      expect(doc['runSeq'], 0);
      final back = codec.readCase('ep01', served(doc), serverEpoch: 0) as CloudAccepted;
      expect(jsonEncode(back.value.progress.toJson()), jsonEncode(old.toJson()));
    });

    test('never up: operator runs, unknown cases, another case\'s missions', () {
      expect(codec.caseToCloud(caseId: 'ep01', progress: played(playtest: true), epoch: 0, cloudVersion: 1).skip,
          CloudSkip.operatorData);
      expect(codec.caseToCloud(caseId: 'ep99', progress: played(), epoch: 0, cloudVersion: 1).skip, CloudSkip.unknownId);
      expect(codec.caseToCloud(caseId: 'ep02', progress: played(), epoch: 0, cloudVersion: 1).skip, CloudSkip.outOfShape);
    });

    test('a valid case of an earlier epoch is stale: not applied, not a conflict', () {
      expect(codec.readCase('ep01', caseDoc(), serverEpoch: 3), isA<CloudStale>());
    });

    final bad = <String, Map<String, Object?> Function()>{
      'negative attempts': () => caseDoc(progress: {'attempts': {'m01': -1}}),
      'hints above the mission\'s tips': () => caseDoc(progress: {'hintsUsed': {'m01': 9}}),
      'xp rule 0': () => caseDoc(progress: {'xpRules': {'m01': 0}}),
      'xp rule 5': () => caseDoc(progress: {'xpRules': {'m01': 99}}),
      'fractional count': () => caseDoc(progress: {'solveSeconds': {'m01': 1.5}}),
      'mission of another case': () => caseDoc(progress: {'completedMissionIds': ['ep02_m1']}),
      'map key of another case': () => caseDoc(progress: {'attempts': {'ep02_m1': 1}}),
      'duplicate completion': () => caseDoc(progress: {'completedMissionIds': ['m01', 'm01']}),
      'unknown progress field': () => caseDoc(progress: {'coins': 999}),
      'operator flag': () => caseDoc(progress: {'playtest': true}),
      'bad date': () => caseDoc(progress: {'startedAt': 'yesterday'}),
      'non-string word': () => caseDoc(progress: {'lookedUpWords': [1]}),
      'bad behavior key': () => caseDoc(progress: {'behavior': {'hacked': []}}),
      'bad name': () => caseDoc(progress: {'detectiveName': 'A  B'}),
      'bool as string': () => caseDoc(progress: {'introSeen': 'yes'}),
      'run mismatch': () => caseDoc(doc: {'runSeq': 4}),
      'run id mismatch': () => caseDoc(doc: {'runId': 'other'}),
      'version 0': () => caseDoc(doc: {'cloudVersion': 0}),
      'version as text': () => caseDoc(doc: {'cloudVersion': '5'}),
      'negative epoch': () => caseDoc(doc: {'epoch': -1}),
      'unknown doc field': () => caseDoc(doc: {'extra': 1}),
      'no server time': () => caseDoc(doc: {'updatedAt': null}),
      'epoch ahead of the server': () => caseDoc(doc: {'epoch': 9}),
    };
    for (final MapEntry(key: name, value: make) in bad.entries) {
      test('rejected, never corrected: $name', () {
        final r = codec.readCase('ep01', make(), serverEpoch: 2);
        expect(r, isA<CloudRejected>(), reason: name);
        final c = (r as CloudRejected).conflictRecord();
        expect(c['kind'], 'cloudInvalid');
        expect(c['subject'], 'case:ep01');
      });
    }

    test('an unknown case id is rejected', () {
      expect(codec.readCase('ep99', caseDoc(), serverEpoch: 2), isA<CloudRejected>());
    });
  });

  group('season', () {
    test('up without operator-only cases; down with the server epoch', () {
      const s = SeasonProgress(activeEpisodeId: 'ep03', solvedEpisodeIds: ['ep01', 'ep02'], playtestEpisodeIds: ['ep02']);
      final doc = codec.seasonToCloud(season: s, epoch: 1, cloudVersion: 3).data!;
      expect(doc['solvedEpisodeIds'], ['ep01']);
      final back = codec.readSeason(served(doc), serverEpoch: 1) as CloudAccepted;
      expect(back.value.season.solvedEpisodeIds, ['ep01']);
      expect(codec.readSeason(served(doc), serverEpoch: 2), isA<CloudStale>());
    });

    test('unknown or repeated cases are rejected', () {
      Map<String, Object?> doc(List<Object?> ids) =>
          {'epoch': 0, 'cloudVersion': 1, 'solvedEpisodeIds': ids, 'updatedAt': at};
      expect(codec.readSeason(doc(['ep99']), serverEpoch: 0), isA<CloudRejected>());
      expect(codec.readSeason(doc(['ep01', 'ep01']), serverEpoch: 0), isA<CloudRejected>());
      expect(codec.readSeason(doc([1]), serverEpoch: 0), isA<CloudRejected>());
      expect(codec.readSeason(doc(['ep01', 'ep12']), serverEpoch: 0), isA<CloudAccepted>());
    });
  });

  group('wallet', () {
    CoinEntry e(String key, int amount, CoinSource s, {bool playtest = false}) =>
        CoinEntry(key: key, amount: amount, source: s, at: at, playtest: playtest);

    test('every coin of the game goes up; operator coins and made-up ones never', () {
      for (final c in [
        e('start', 20, CoinSource.start),
        e('mission:m01', 30, CoinSource.mission),
        e('mission:final', 60, CoinSource.mission),
        e('mission:ep02_m1', 30, CoinSource.backfill),
        e('tip:m01:1', 0, CoinSource.tip),
        e('tip:m01:2', -20, CoinSource.tip),
        e('tip:m01:2', 0, CoinSource.tip),
      ]) {
        expect(codec.eventToCloud(c, epoch: 2).ok, isTrue, reason: c.key);
      }
      expect(CloudCodec.eventId(2, 'mission:m01'), '2_mission:m01');
      expect(codec.eventToCloud(e('mission:m01', 30, CoinSource.mission, playtest: true), epoch: 0).skip, CloudSkip.operatorData);
      for (final c in [
        e('mission:made_up', 30, CoinSource.mission),
        e('mission:m01', 60, CoinSource.mission),
        e('tip:m01:2', -40, CoinSource.tip),
        e('start', 30, CoinSource.start),
      ]) {
        expect(codec.eventToCloud(c, epoch: 0).skip, CloudSkip.outOfShape, reason: c.key);
      }
    });

    Map<String, Map<String, Object?>> docs(int epoch, List<CoinEntry> entries, {int? balance, Map<String, Object?> extra = const {}}) => {
          for (final c in entries) CloudCodec.eventId(epoch, c.key): served(codec.eventToCloud(c, epoch: epoch).data!),
          'summary': {
            'epoch': epoch,
            'cloudVersion': entries.length,
            'balance': balance ?? entries.fold<int>(0, (s, c) => s + c.amount),
            'lastEventId': CloudCodec.eventId(epoch, entries.last.key),
            'updatedAt': at,
            ...extra,
          },
        };

    test('only the server epoch is restored; the summary must match the events', () {
      final current = docs(2, [e('start', 20, CoinSource.start), e('mission:m01', 30, CoinSource.mission)]);
      final old = docs(1, [e('start', 20, CoinSource.start), e('mission:m02', 30, CoinSource.mission)])..remove('summary');
      final r = codec.readWallet({...old, ...current}, serverEpoch: 2);
      expect(r.rejected, isEmpty);
      expect(r.wallet.balance, 50);
      expect(r.wallet.has('mission:m02'), isFalse, reason: 'an earlier epoch never comes back');
      expect(r.summaryVersion, 2);
      final wrong = docs(2, [e('start', 20, CoinSource.start)], balance: 999);
      final w = codec.readWallet(wrong, serverEpoch: 2);
      expect(w.rejected.single.subject, 'wallet:summary');
      expect(w.summaryVersion, isNull);
    });

    test('one bad event of the current epoch: nothing of that wallet is applied; every problem reported', () {
      final d = docs(0, [e('start', 20, CoinSource.start)]);
      d['0_mission:m01'] = {'epoch': 0, 'key': 'mission:m01', 'amount': 99, 'source': 'mission', 'at': at};
      d['0_mission:m02'] = {'epoch': 0, 'key': 'mission:m03', 'amount': 30, 'source': 'mission', 'at': at};
      d['0_tip:m01:2'] = {'epoch': 0, 'key': 'tip:m01:2', 'amount': -20, 'source': 'refund', 'at': at};
      d['0_start2'] = {'epoch': 0, 'key': 'start', 'amount': 20, 'source': 'start', 'at': at, 'x': 1};
      final r = codec.readWallet(d, serverEpoch: 0);
      expect(r.accepted, isFalse);
      expect(r.wallet.entries, isEmpty);
      expect(r.summaryVersion, isNull);
      expect(r.rejected.map((x) => x.subject).toSet(),
          containsAll({'wallet:0_mission:m01', 'wallet:0_mission:m02', 'wallet:0_tip:m01:2', 'wallet:0_start2'}));
    });

    test('a bad event of an earlier epoch is reported but does not block the current wallet', () {
      final d = docs(1, [e('start', 20, CoinSource.start)]);
      d['0_mission:m01'] = {'epoch': 0, 'key': 'mission:m01', 'amount': 99, 'source': 'mission', 'at': at};
      final r = codec.readWallet(d, serverEpoch: 1);
      expect(r.accepted, isTrue);
      expect(r.wallet.balance, 20);
      expect(r.rejected.single.subject, 'wallet:0_mission:m01');
    });

    test('summary problems withhold the whole current wallet (never a negative or orphan balance)', () {
      final ok = docs(2, [e('start', 20, CoinSource.start), e('tip:m01:2', -20, CoinSource.tip)]);
      expect(codec.readWallet(ok, serverEpoch: 2).accepted, isTrue);
      final cases = <String, Map<String, Map<String, Object?>>>{
        'no summary': {...ok}..remove('summary'),
        'summary epoch ahead of server': {...ok, 'summary': {...ok['summary']!, 'epoch': 3}},
        'dangling lastEventId': {...ok, 'summary': {...ok['summary']!, 'lastEventId': '2_mission:m05'}},
        'summary of an earlier epoch': {...ok, 'summary': {...ok['summary']!, 'epoch': 1}},
        'balance off': {...ok, 'summary': {...ok['summary']!, 'balance': 5}},
      };
      for (final MapEntry(key: name, value: d) in cases.entries) {
        final r = codec.readWallet(d, serverEpoch: 2);
        expect(r.accepted, isFalse, reason: name);
        expect(r.wallet.entries, isEmpty, reason: name);
        expect(r.rejected.any((x) => x.subject == 'wallet:summary'), isTrue, reason: name);
      }
      // An orphan debit (no start, no summary) would be −20: never exposed.
      final orphan = {'2_tip:m01:2': served(codec.eventToCloud(e('tip:m01:2', -20, CoinSource.tip), epoch: 2).data!)};
      final r = codec.readWallet(orphan, serverEpoch: 2);
      expect(r.accepted, isFalse);
      expect(r.wallet.balance, 0);
      // Nothing of the current epoch and no summary: an empty, accepted wallet.
      expect(codec.readWallet(const {}, serverEpoch: 0).accepted, isTrue);
    });

    test('summaries never go below zero (R3: no refunds, no debt)', () {
      final s1 = CloudCodec.summaryAfter(previous: null, epoch: 0, eventId: '0_start', amount: 20)!;
      expect(s1['balance'], 20);
      expect(s1['cloudVersion'], 1);
      final s2 = CloudCodec.summaryAfter(previous: s1, epoch: 0, eventId: '0_tip:m01:2', amount: -20)!;
      expect(s2['balance'], 0);
      expect(CloudCodec.summaryAfter(previous: s2, epoch: 0, eventId: '0_tip:m02:2', amount: -20), isNull);
      final s3 = CloudCodec.summaryAfter(previous: s2, epoch: 1, eventId: '1_start', amount: 20)!;
      expect(s3['balance'], 20, reason: 'a new epoch starts again from its own events');
      expect(s3['cloudVersion'], 3);
    });
  });

  group('sync/meta', () {
    test('read with checks', () {
      expect(codec.readMeta({'epoch': 2, 'cloudVersion': 3, 'updatedAt': at}), isA<CloudAccepted>());
      expect(codec.readMeta({'epoch': -1, 'cloudVersion': 3, 'updatedAt': at}), isA<CloudRejected>());
      expect(codec.readMeta({'epoch': 1, 'cloudVersion': 0, 'updatedAt': at}), isA<CloudRejected>());
      expect(codec.readMeta({'epoch': 1, 'cloudVersion': 1}), isA<CloudRejected>());
      expect(codec.metaToCloud(epoch: 0, cloudVersion: 1).data!['updatedAt'], same(CloudServerTime.instance));
    });
  });

  group('cloudVersion bookkeeping', () {
    final now = DateTime.utc(2026, 10, 14, 12);

    test('nothing is confirmed until the server committed', () {
      var m = CloudSyncMeta.empty;
      expect(m.of('case:ep01').confirmedVersion, isNull, reason: 'first sync: merge with the server first');
      m = m.confirmed('case:ep01', cloudVersion: 4, epoch: 1);
      expect(m.of('case:ep01').confirmedVersion, 4);
      expect(m.of('case:ep01').confirmedEpoch, 1);
      m = m.failed('case:ep01', now);
      expect(m.of('case:ep01').confirmedVersion, 4, reason: 'a failure keeps the last confirmed version');
      expect(m.of('case:ep01').failures, 1);
      m = m.confirmed('case:ep01', cloudVersion: 5, epoch: 1);
      expect(m.of('case:ep01').failures, 0);
    });

    test('back-off, stall after 10, full resync at the next start', () {
      var m = CloudSyncMeta.empty;
      m = m.failed('season', now);
      expect(m.isDue('season', now), isFalse);
      expect(m.isDue('season', now.add(const Duration(seconds: 30))), isTrue);
      for (var i = 2; i <= 9; i++) {
        m = m.failed('season', now);
      }
      expect(m.of('season').stalled, isFalse);
      m = m.failed('season', now);
      expect(m.of('season').stalled, isTrue);
      expect(m.isDue('season', now.add(const Duration(days: 30))), isFalse, reason: 'no automatic retry');
      final started = m.atStart();
      expect(started.needsFullResync, isTrue);
      expect(started.of('season').stalled, isFalse);
      expect(started.of('season').failures, 0);
      expect(started.isDue('season', now), isTrue);
      expect(started.resynced().needsFullResync, isFalse);
      expect(CloudSyncMeta.empty.atStart(), same(CloudSyncMeta.empty));
    });

    test('kept as JSON; anything unreadable is "never confirmed" (safe)', () {
      final m = CloudSyncMeta.empty.confirmed('meta', cloudVersion: 2, epoch: 1).failed('wallet', now).atStart();
      final back = CloudSyncMeta.decode(m.encode());
      expect(back.encode(), m.encode());
      expect(CloudSyncMeta.decode('{oops').subjects, isEmpty);
      expect(CloudSyncMeta.decode(jsonEncode({'v': 1, 'subjects': {'x': {'v': 0, 'f': -3}}})).of('x').confirmedVersion, isNull);
      // Another format version, or none, with plausible data: never a confirmed base.
      for (final v in [null, 2, '1']) {
        final raw = jsonEncode({'v': ?v, 'subjects': {'case:ep01': {'v': 8, 'e': 2}}});
        expect(CloudSyncMeta.decode(raw).of('case:ep01').confirmedVersion, isNull, reason: 'v=$v');
      }
    });

    test('stored under its own key, apart from every game save; a wipe drops it, an epoch move keeps it', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = SharedPrefsProgressRepository(prefs, profileId: 'abcdef0123456789abcdef0123456789');
      repo.save(const GameProgress(detectiveName: 'ANNA', completedMissionIds: ['m01']), 'ep01');
      final before = {for (final k in prefs.getKeys()) k: prefs.get(k)};
      repo.updateCloudSync((m) => m.confirmed('case:ep01', cloudVersion: 3, epoch: 0));
      final key = AppConstants.cloudSyncKey('abcdef0123456789abcdef0123456789');
      expect(prefs.getKeys().difference(before.keys.toSet()), {key});
      for (final e in before.entries) {
        expect(prefs.get(e.key), e.value, reason: 'game saves unchanged: ${e.key}');
      }
      expect(repo.cloudSync.of('case:ep01').confirmedVersion, 3);
      repo.adoptEpoch(2, episodeIds: const ['ep01']);
      expect(repo.cloudSync.of('case:ep01').confirmedVersion, 3, reason: 'the cloud docs keep their versions');
      await repo.clear();
      expect(prefs.get(key), isNull);
    });
  });

  group('retry policy', () {
    const p = SyncRetryPolicy.standard;
    test('3 rounds per run; 30 s doubling to at most 1 h; stall at 10', () {
      expect(p.maxRoundsPerRun, 3);
      expect([for (var f = 1; f <= 9; f++) p.delayAfter(f).inSeconds], [30, 60, 120, 240, 480, 960, 1920, 3600, 3600]);
      expect(p.delayAfter(40), const Duration(hours: 1));
      expect(p.delayAfter(3, jitter: 0.5).inSeconds, 60);
      expect(p.stalls(9), isFalse);
      expect(p.stalls(10), isTrue);
    });
  });

  group('outbox: conflicted and stalled', () {
    OutboxEvent ev(String id, OutboxKind k, String subject, {OutboxState state = OutboxState.pending}) => OutboxEvent(
          id: id,
          profileId: 'p',
          kind: k,
          subject: subject,
          epoch: 0,
          state: state,
          createdAt: at,
        );

    test('a permanent conflict is kept, never sent or resumed automatically', () {
      var o = Outbox([ev('a', OutboxKind.walletEntry, 'tip:m01:2'), ev('b', OutboxKind.caseRun, 'ep01')]);
      o = o.claim(['a']).markConflicted(['a']);
      expect(o.conflicted.single.id, 'a');
      expect(o.pending.map((e) => e.id), ['b']);
      expect(o.recovered().conflicted.single.id, 'a');
      expect(o.resumeStalled().conflicted.single.id, 'a');
      expect(o.enqueue(ev('c', OutboxKind.walletEntry, 'tip:m01:2')).events.length, 2, reason: 'never queued twice');
      expect(o.release(['a']).conflicted.single.id, 'a');
    });

    test('a stalled subject waits for the next start, newer changes included', () {
      var o = Outbox([ev('a', OutboxKind.caseRun, 'ep01'), ev('w', OutboxKind.walletEntry, 'start')]);
      o = o.claim(['a']).markStalled(OutboxKind.caseRun, 'ep01');
      expect(o.stalled.single.id, 'a');
      expect(o.pending.map((e) => e.id), ['w']);
      o = o.enqueue(ev('a2', OutboxKind.caseRun, 'ep01'));
      expect(o.stalled.single.id, 'a2', reason: 'the newer state replaces it, still stalled');
      expect(o.pending.map((e) => e.id), ['w']);
      o = o.resumeStalled();
      expect(o.pending.map((e) => e.id), containsAll(['w', 'a2']));
      expect(o.events.firstWhere((e) => e.id == 'a2').attempts, 0);
    });

    test('old outboxes read as before; new states are kept across a save', () {
      final old = jsonEncode({
        'v': 1,
        'events': [
          {'id': 'x', 'profileId': 'p', 'kind': 'caseRun', 'subject': 'ep01', 'epoch': 0, 'state': 'pending', 'createdAt': at.toIso8601String()},
          {'id': 'y', 'profileId': 'p', 'kind': 'season', 'subject': 'season', 'epoch': 0, 'state': 'inFlight', 'createdAt': at.toIso8601String()},
        ],
      });
      final o = Outbox.decode(old);
      expect(o.events.map((e) => e.state), [OutboxState.pending, OutboxState.inFlight]);
      final marked = o.markConflicted(['x']).markStalled(OutboxKind.season, 'season');
      expect(jsonDecode(marked.encode())['v'], Outbox.format);
      final back = Outbox.decode(marked.encode());
      expect(back.events.map((e) => e.state), [OutboxState.conflicted, OutboxState.stalled]);
    });

    test('never sent from data this build does not understand (a newer format or state)', () {
      Map<String, Object?> event(String id, String state) =>
          {'id': id, 'profileId': 'p', 'kind': 'caseRun', 'subject': 'ep0$id', 'epoch': 0, 'state': state, 'createdAt': at.toIso8601String()};
      final newer = Outbox.decode(jsonEncode({'v': Outbox.format + 1, 'events': [event('1', 'pending'), event('2', 'inFlight')]}));
      expect(newer.pending, isEmpty);
      expect(newer.conflicted.length, 2);
      expect(newer.recovered().resumeStalled().pending, isEmpty, reason: 'not even after a restart');
      final unknown = Outbox.decode(jsonEncode({'v': Outbox.format, 'events': [event('3', 'awaitingServer')]}));
      expect(unknown.conflicted.single.id, '3');
      expect(unknown.resumeStalled().pending, isEmpty);
    });
  });

  group('Sync Gate', () {
    const uid = 'alice-uid';
    const session = UserSession(uid: uid, emailVerified: true);
    const confirmed = AccountState(AccountStatus.signedIn, session, ConsentStatus.confirmed);
    const mine = DetectiveProfile(id: 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', kind: ProfileKind.account, ownerUid: uid);

    SyncGateResult gate({
      CloudStatus cloud = CloudStatus.ready,
      AccountState account = confirmed,
      DetectiveProfile profile = mine,
      bool deleting = false,
    }) =>
        SyncGate.check(cloud: cloud, account: account, profile: profile, deletionInProgress: deleting);

    test('open only when every condition holds', () {
      expect(gate().open, isTrue);
      expect(gate().uid, uid);
    });

    test('each condition closes it', () {
      expect(gate(cloud: CloudStatus.disabled).block, SyncBlock.cloudUnavailable);
      expect(gate(cloud: CloudStatus.unavailable).block, SyncBlock.cloudUnavailable);
      expect(gate(account: const AccountState(AccountStatus.signedOut)).block, SyncBlock.signedOut);
      expect(gate(account: const AccountState(AccountStatus.signedIn, session)).block, SyncBlock.consentNotConfirmed);
      expect(gate(deleting: true).block, SyncBlock.deletionInProgress);
      expect(gate(profile: const DetectiveProfile(id: 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb')).block, SyncBlock.guestProfile,
          reason: 'the guest is never uploaded automatically');
      expect(gate(profile: DetectiveProfile(id: 'c' * 32, kind: ProfileKind.account, ownerUid: 'bob')).block,
          SyncBlock.otherAccount);
      expect(
        gate(profile: DetectiveProfile(id: 'd' * 32, kind: ProfileKind.account, ownerUid: uid, origin: ProfileOrigin.playtest)).block,
        SyncBlock.operatorProfile,
      );
      expect(gate(profile: DetectiveProfile(id: 'e' * 32, kind: ProfileKind.account, ownerUid: uid, needsReview: true)).block,
          SyncBlock.needsReview);
    });

    test('a run stops on sign-out, another account, consent, deletion or a profile switch', () {
      final run = SyncRun.start(gate(), mine)!;
      bool valid({AccountState account = confirmed, DetectiveProfile profile = mine, bool deleting = false}) =>
          run.stillValid(cloud: CloudStatus.ready, account: account, activeProfile: profile, deletionInProgress: deleting);
      expect(valid(), isTrue);
      expect(valid(account: const AccountState(AccountStatus.signedOut)), isFalse);
      expect(
        valid(account: const AccountState(AccountStatus.signedIn, UserSession(uid: 'bob', emailVerified: true), ConsentStatus.confirmed)),
        isFalse,
        reason: 'another account signed in: nothing of the run reaches it',
      );
      expect(valid(account: const AccountState(AccountStatus.signedIn, session)), isFalse);
      expect(valid(deleting: true), isFalse);
      expect(valid(profile: DetectiveProfile(id: 'f' * 32, kind: ProfileKind.account, ownerUid: uid)), isFalse);
      expect(SyncRun.start(gate(deleting: true), mine), isNull);
    });
  });
}
