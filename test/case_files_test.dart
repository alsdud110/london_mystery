import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/mission.dart';
import 'package:london_mystery/data/models/profile.dart';
import 'package:london_mystery/data/models/wallet.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/data/repositories/profile_store.dart';
import 'package:london_mystery/data/repositories/progress_repository.dart';
import 'package:london_mystery/data/sync/case_conflicts.dart';
import 'package:london_mystery/data/sync/cloud/cloud_catalog.dart';
import 'package:london_mystery/data/sync/cloud/cloud_codec.dart';
import 'package:london_mystery/data/sync/cloud/cloud_store.dart';
import 'package:london_mystery/data/sync/cloud/sync_restorer.dart';
import 'package:london_mystery/data/sync/cloud/sync_sender.dart';
import 'package:london_mystery/data/sync/merge.dart';
import 'package:london_mystery/data/sync/outbox.dart';
import 'package:london_mystery/data/sync/sync_applier.dart';
import 'package:london_mystery/features/account/auth_service.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/scoring.dart';
import 'package:london_mystery/features/game/wallet_controller.dart';
import 'package:london_mystery/features/sync/case_file_choice.dart';
import 'package:london_mystery/features/sync/sync_scheduler.dart';
import 'package:london_mystery/features/sync/sync_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/cloud_stores.dart';
import 'support/sync_devices.dart';
import 'support/sync_harness.dart';

/// Phase 4.5: two case files of one case (two devices each played it under
/// the same run number) and the player's choice between them. Nothing kept is
/// ever lost, a choice never touches coins or the epoch, and every device
/// ends on the same run.
void main() {
  final season = MockEpisodeRepository.bundled();
  final ep01 = season.first;
  final episodeIds = [for (final e in season) e.id];
  final codec = CloudCodec(CloudCatalog.of(season));
  final m01 = ep01.missions[0];
  final m02 = ep01.missions[1];
  final m03 = ep01.missions[2];

  GameProgress run(String? id, List<Mission> solved, {int seq = 0, int rev = 1, int playMillis = 60000}) => GameProgress(
        detectiveName: 'ANNA',
        introSeen: true,
        completedMissionIds: [for (final m in solved) m.id],
        attempts: {for (final m in solved) m.id: 1},
        xpRules: {for (final m in solved) m.id: 4},
        startedAt: DateTime.utc(2026, 10, 14, 9),
        playMillis: playMillis,
        runId: id,
        runSeq: seq,
        rev: rev,
      );

  String j(GameProgress p) => jsonEncode(p.toJson());

  group('the merge rules (Phase 4.5)', () {
    CaseSnapshot snap(GameProgress p) => CaseSnapshot(epoch: 0, progress: p);

    test('a tie (the same progress, revision and play time): the same winner whichever side is this device', () {
      final x = run('run-x', [m01], seq: 2);
      final y = run('run-y', [m01], seq: 2);
      final xy = mergeCase(snap(x), snap(y));
      final yx = mergeCase(snap(y), snap(x));
      expect((xy.outcome, yx.outcome), (MergeOutcome.conflict, MergeOutcome.conflict));
      expect(xy.merged.runId, yx.merged.runId, reason: 'never "this device wins"');
      expect(xy.merged.runId, 'run-y');
      expect(xy.preserved?.runId, 'run-x', reason: 'the other run kept');
      expect(yx.preserved?.runId, 'run-x');
    });

    test('runs without an id that tie: decided by the saves themselves, the same both ways', () {
      final x = run(null, [m01]).copyWith(lookedUpWords: ['fog']);
      final y = run(null, [m01]).copyWith(lookedUpWords: ['rain']);
      expect(j(mergeCase(snap(x), snap(y)).merged), j(mergeCase(snap(y), snap(x)).merged));
    });

    test('a later run wins; the run before is kept only when it holds play the winner does not', () {
      final before = run('a', [m01, m02]);
      final later = run('b', [m01], seq: 1);
      final m = mergeCase(snap(before), snap(later));
      expect((m.merged.runId, m.outcome), ('b', MergeOutcome.tookRemote));
      expect(m.preserved?.runId, 'a');
      // The same play under the next number (a choice made elsewhere): nothing to keep.
      final chosen = before.copyWith(runId: 'c', runSeq: 1);
      expect(mergeCase(snap(before), snap(chosen)).preserved, isNull);
      // A blank run before: nothing to keep.
      expect(mergeCase(snap(GameProgress.empty), snap(later)).preserved, isNull);
    });

    test('nothing else changed: the same run combines, one side ahead is taken, a further-along run wins', () {
      final l = run('a', [m01], rev: 2);
      final r = run('a', [m01, m02], rev: 5);
      expect(mergeCase(snap(l), snap(r)).outcome, MergeOutcome.tookRemote);
      expect(mergeCase(snap(r), snap(l)).outcome, MergeOutcome.keptLocal);
      final both = mergeCase(snap(run('a', [m01, m02], rev: 3)), snap(run('a', [m01, m03], rev: 4)));
      expect(both.outcome, MergeOutcome.combined);
      expect(both.merged.completedMissionIds, [m01.id, m02.id, m03.id]);
      final ahead = mergeCase(snap(run('x', [m01])), snap(run('y', [m01, m02])));
      expect((ahead.merged.runId, ahead.preserved?.runId), ('y', 'x'));
    });
  });

  group('case files on one device', () {
    late SharedPreferences prefs;
    late SharedPrefsProgressRepository repo;
    const pid = 'abcdefabcdefabcdefabcdefabcdef01';
    final at = DateTime.utc(2026, 10, 14, 12);

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      repo = SharedPrefsProgressRepository(prefs, profileId: pid);
      repo.saveWallet(Wallet.empty
          .adding(CoinEntry(key: Wallet.startKey, amount: 20, source: CoinSource.start, at: at))
          .adding(CoinEntry(key: Wallet.missionKey(m01.id), amount: 30, source: CoinSource.mission, at: at))
          .adding(CoinEntry(key: Wallet.missionKey(m02.id), amount: 30, source: CoinSource.mission, at: at)));
    });

    /// This device played m01 and m02; the account's run (another device)
    /// only m01, under the same run number: the device's plays on, the
    /// account's is kept.
    CaseChoice twoFiles() {
      repo.save(run('dev-run', [m01, m02]), 'ep01');
      SyncApplier(repo, episodeIds: episodeIds).applyCase('ep01', CaseSnapshot(epoch: 0, progress: run('acc-run', [m01])));
      return CaseConflicts.choiceFor(repo, 'ep01')!;
    }

    String wallet() => jsonEncode(repo.loadWallet()!.toJson());
    int caseEvents() => repo.outbox.events.where((e) => e.kind == OutboxKind.caseRun).length;

    test('two files: the one playing (this device) and the account\'s, both kept', () {
      final c = twoFiles();
      expect((c.playing.run.runId, c.playing.side), ('dev-run', FileSide.device));
      expect((c.other.run.runId, c.other.side), ('acc-run', FileSide.account));
      final record = repo.conflicts.single;
      expect((record['v'], record['status'], record['side'], record['epoch'], record['caseId'], record['runSeq']),
          (2, 'open', 'account', 0, 'ep01', 0));
      expect(DateTime.tryParse(record['at'] as String), isNotNull);
      expect(CaseConflicts.hasOpenChoice(repo), isTrue);
    });

    test('the account\'s file chosen: it plays on under the next run number; the device\'s run kept; coins untouched', () {
      final c = twoFiles();
      final coins = wallet();
      final events = caseEvents();
      expect(CaseConflicts.choose(repo, c, keepPlaying: false, now: at), ChoiceResult.applied);
      final now = repo.load('ep01');
      expect(now.completedMissionIds, [m01.id]);
      expect((now.runSeq, now.runId), (1, CaseConflicts.choiceRunId(c.other.run, 1)));
      expect(repo.epoch, 0, reason: 'a choice is never a New Adventure');
      expect(XpBreakdown.totalFor(ep01, now), XpBreakdown.totalFor(ep01, c.other.run), reason: 'the chosen file\'s XP');
      expect(wallet(), coins, reason: 'no coin paid or taken');
      // Queued to be sent (the case's latest state: one event for it).
      expect(caseEvents(), events);
      expect(repo.outbox.events.lastWhere((e) => e.subject == 'ep01').runSeq, 1);
      final kept = repo.conflicts.firstWhere((r) => r['reason'] == CaseConflicts.reasonNotChosen);
      expect((CaseConflicts.runOf(kept)!.runId, kept['status'], kept['side']), ('dev-run', 'archived', 'device'));
      final chosen = repo.conflicts.firstWhere((r) => r['runId'] == 'acc-run');
      expect(chosen['status'], 'waiting', reason: 'not resolved until the server has it');
      expect((chosen['choice'] as Map)['runId'], now.runId);
      expect(CaseConflicts.choiceFor(repo, 'ep01'), isNull);
    });

    test('the device\'s file kept: the same play under the next run number; nothing new to keep', () {
      final c = twoFiles();
      final before = repo.load('ep01');
      expect(CaseConflicts.choose(repo, c, keepPlaying: true, now: at), ChoiceResult.applied);
      final now = repo.load('ep01');
      expect(sameProgress(now, before), isTrue);
      expect(now.runSeq, 1);
      expect(repo.conflicts, hasLength(1), reason: 'the account\'s run stays where it was kept');
      expect(repo.conflicts.single['status'], 'waiting');
    });

    test('decide later: nothing changes, and the files are offered again after a restart', () {
      final c = twoFiles();
      final saves = {for (final k in prefs.getKeys()) k: prefs.get(k)};
      final again = CaseConflicts.choiceFor(SharedPrefsProgressRepository(prefs, profileId: pid), 'ep01')!;
      expect(again.fingerprint, c.fingerprint);
      expect({for (final k in prefs.getKeys()) k: prefs.get(k)}, saves);
    });

    test('the files read back with their maps in another key order (a cloud round trip): the choice still applies', () {
      final c = twoFiles();
      Object? reversed(Object? v) => switch (v) {
            Map() => {for (final k in v.keys.toList().reversed) k: reversed(v[k])},
            List() => [for (final e in v) reversed(e)],
            _ => v,
          };
      final key = AppConstants.conflictsKey(pid);
      prefs.setString(key, jsonEncode(reversed(jsonDecode(prefs.getString(key)!))));
      repo.save(GameProgress.fromJson(jsonDecode(jsonEncode(reversed(repo.load('ep01').toJson()))) as Map<String, dynamic>), 'ep01');
      final again = CaseConflicts.choiceFor(SharedPrefsProgressRepository(prefs, profileId: pid), 'ep01')!;
      expect(again.fingerprint, c.fingerprint);
      expect(CaseConflicts.choose(repo, c, keepPlaying: false, now: at), ChoiceResult.applied);
    });

    test('the same choice twice: done once — the run number does not move again, nothing is queued twice', () {
      final c = twoFiles();
      expect(CaseConflicts.choose(repo, c, keepPlaying: false, now: at), ChoiceResult.applied);
      final once = (j(repo.load('ep01')), caseEvents(), jsonEncode(repo.conflicts), wallet());
      expect(CaseConflicts.choose(repo, c, keepPlaying: false, now: at), ChoiceResult.alreadyDone);
      expect((j(repo.load('ep01')), caseEvents(), jsonEncode(repo.conflicts), wallet()), once);
      expect(repo.load('ep01').runSeq, 1);
    });

    test('the case changed after the files were shown: nothing is chosen', () {
      final c = twoFiles();
      repo.save(repo.load('ep01').copyWith(completedMissionIds: [m01.id, m02.id, m03.id], rev: 9), 'ep01');
      final before = (j(repo.load('ep01')), jsonEncode(repo.conflicts));
      expect(CaseConflicts.choose(repo, c, keepPlaying: false, now: at), ChoiceResult.changed);
      expect((j(repo.load('ep01')), jsonEncode(repo.conflicts)), before);
    });

    test('only the play clock saved meanwhile: the choice still holds, and keeps that time', () {
      final c = twoFiles();
      repo.save(repo.load('ep01').copyWith(playMillis: 99000), 'ep01');
      expect(CaseConflicts.choose(repo, c, keepPlaying: true, now: at), ChoiceResult.applied);
      expect(repo.load('ep01').playMillis, 99000);
    });

    test('sent: resolved. Replaced by a later run first: archived (kept)', () {
      final c = twoFiles();
      CaseConflicts.choose(repo, c, keepPlaying: false, now: at);
      CaseConflicts.noteOnServer(repo, 'ep01', 'some-other-run');
      expect(repo.conflicts.firstWhere((r) => r['runId'] == 'acc-run')['status'], 'waiting');
      CaseConflicts.noteOnServer(repo, 'ep01', repo.load('ep01').runId);
      expect(repo.conflicts.firstWhere((r) => r['runId'] == 'acc-run')['status'], 'resolved');

      repo.updateConflicts((items) => [for (final r in items) r['runId'] == 'acc-run' ? {...r, 'status': 'waiting'} : r]);
      repo.saveMerged(episodeId: 'ep01', progress: run('elsewhere', [m01], seq: 5), queue: false);
      CaseConflicts.settle(repo, 'ep01');
      expect(repo.conflicts.firstWhere((r) => r['runId'] == 'acc-run')['status'], 'archived');
      expect(repo.conflicts, hasLength(2), reason: 'nothing removed');
    });

    test('a New Adventure: the kept files stay (archived) and are not offered in the new epoch', () async {
      twoFiles();
      final count = repo.conflicts.length;
      await repo.clear();
      expect(repo.epoch, 1);
      expect(repo.conflicts, hasLength(count), reason: 'kept through the New Adventure');
      expect(repo.conflicts.every((r) => r['status'] == 'archived'), isTrue);
      expect(CaseConflicts.choiceFor(repo, 'ep01'), isNull);
      expect(repo.load('ep01').completedMissionIds, isEmpty);
    });

    test('a New Adventure elsewhere (a later epoch adopted): the files are archived the same way', () {
      twoFiles();
      repo.adoptEpoch(1, episodeIds: episodeIds);
      expect(repo.conflicts.where((r) => r['kind'] == 'case').every((r) => r['status'] == 'archived'), isTrue);
      expect(repo.conflicts.where((r) => r['kind'] == 'epoch'), hasLength(1));
      expect(CaseConflicts.choiceFor(repo, 'ep01'), isNull);
    });

    test('ten files kept for the case: a choice that must keep one more is refused; nothing is removed', () {
      final c = twoFiles();
      for (var i = 0; i < CaseConflicts.perCaseLimit - 1; i++) {
        repo.keepConflict(CaseConflicts.caseRecord(
          caseId: 'ep01',
          run: run('old-$i', [m01], seq: 0),
          side: FileSide.device,
          epoch: 0,
          reason: 'later run',
          at: at,
        ));
      }
      expect(repo.conflicts, hasLength(CaseConflicts.perCaseLimit));
      final before = (j(repo.load('ep01')), jsonEncode(repo.conflicts), wallet());
      expect(CaseConflicts.choose(repo, c, keepPlaying: false, now: at), ChoiceResult.cannotKeep);
      expect((j(repo.load('ep01')), jsonEncode(repo.conflicts), wallet()), before);
      // Keeping the file playing now keeps nothing new: it still works.
      expect(CaseConflicts.choose(repo, c, keepPlaying: true, now: at), ChoiceResult.applied);
      expect(repo.conflicts, hasLength(CaseConflicts.perCaseLimit));
    });

    test('a kept record is never removed by a change', () {
      twoFiles();
      expect(() => repo.updateConflicts((_) => []), throwsStateError);
      expect(repo.conflicts, hasLength(1));
    });

    test('each detective has its own files', () {
      twoFiles();
      final other = SharedPrefsProgressRepository(prefs, profileId: 'b' * 32);
      expect(other.conflicts, isEmpty);
      expect(CaseConflicts.choiceFor(other, 'ep01'), isNull);
      expect(prefs.getKeys().where((k) => k.contains('conflicts')), [AppConstants.conflictsKey(pid)]);
    });

    test('records from before this version are read: a held restore is offered, other kept runs are not', () {
      repo.save(run('dev-run', [m01, m02]), 'ep01');
      repo.keepConflict({
        'id': 'restoreHeld:case:ep01:old:0:3',
        'kind': 'restoreHeld',
        'subject': 'case:ep01',
        'reason': CaseConflicts.reasonSameNumber,
        'cloud': run('old', [m01]).toJson(),
        'cloudVersion': 3,
      });
      repo.keepConflict({'id': 'case:ep01:x:0:1', 'kind': 'case', 'subject': 'ep01', 'reason': 'epoch', 'kept': run('x', [m03]).toJson()});
      final c = CaseConflicts.choiceFor(repo, 'ep01')!;
      expect((c.other.run.runId, c.other.side), ('old', FileSide.account));
      expect(c.recordIds, ['restoreHeld:case:ep01:old:0:3']);
    });

    test('a coin with two amounts: kept and shown, the balance never changed', () {
      final balance = repo.loadWallet()!.balance;
      final remote = Wallet.empty.adding(CoinEntry(key: Wallet.missionKey(m01.id), amount: 60, source: CoinSource.mission, at: at));
      SyncApplier(repo, episodeIds: episodeIds).applyWallet(0, remote);
      final record = repo.conflicts.singleWhere((r) => r['kind'] == 'wallet');
      expect((record['v'], record['status'], record['epoch']), (2, 'open', 0));
      expect(repo.loadWallet()!.balance, balance);
      expect(CaseConflicts.hasCoinNote(repo), isTrue, reason: 'said, not asked');
      expect(CaseConflicts.hasOpenChoice(repo), isFalse, reason: 'nothing to choose');
      // A New Adventure: kept, no longer said for the new epoch's coins.
      repo.clear();
      expect(repo.conflicts.where((r) => r['kind'] == 'wallet'), hasLength(1));
      expect(CaseConflicts.hasCoinNote(repo), isFalse);
    });
  });

  for (final onEmulator in [false, true]) {
    final label = onEmulator ? 'emulator' : 'memory';
    final skip = onEmulator && emulatorHost == null ? 'no Firestore emulator (cd firebase && npm run test:sync)' : null;

    group('the same choice number on two devices ($label)', () {
      const uid = 'anna-uid';
      const pid = 'abcdefabcdefabcdefabcdefabcdef02';
      const paths = SyncPaths(uid, pid);
      late CloudStore cloud;
      late SharedPreferences prefs;

      setUp(() async {
        SharedPreferences.setMockInitialValues({});
        prefs = await SharedPreferences.getInstance();
        final at = DateTime.utc(2026, 10, 14, 12);
        if (onEmulator) {
          await EmulatorCloudStore.clear();
          final admin = EmulatorCloudStore(null);
          await admin.put('consents/$uid', {'status': 'confirmed', 'schema': 1});
          await admin.put('users/$uid', {'schema': 1, 'locale': 'ko', 'region': 'KR', 'createdAt': at});
          await admin.put('users/$uid/profiles/$pid', {'schema': 1, 'detectiveName': 'ANNA', 'createdAt': at});
          cloud = EmulatorCloudStore(uid);
        } else {
          cloud = MemoryCloudStore()..docs['consents/$uid'] = {'status': 'confirmed'};
        }
      });

      SyncSender sender(SharedPrefsProgressRepository repo) => SyncSender(
            store: cloud,
            repo: repo,
            codec: codec,
            paths: paths,
            episodeIds: episodeIds,
            isStillValid: () => true,
          );

      Future<void> pull(SharedPrefsProgressRepository repo) async {
        final down = await SyncRestorer.download(cloud, paths, codec);
        SyncRestorer.apply(repo, (down as DownloadOk).state, episodeIds: episodeIds, isStillValid: () => true);
      }

      for (final aFirst in [true, false]) {
        test('two choices with the same progress, sent ${aFirst ? 'A then B' : 'B then A'}: the same run on the server and both devices', () async {
          final a = SharedPrefsProgressRepository(prefs, profileId: '1' * 32);
          final b = SharedPrefsProgressRepository(prefs, profileId: '2' * 32);
          // Each device chose a file offline: the same play, revision and
          // clock, the same new run number, different runs.
          await a.save(run('choice-from-a', [m01], seq: 2), 'ep01');
          await b.save(run('choice-from-b', [m01], seq: 2).copyWith(lookedUpWords: ['fog']), 'ep01');
          for (final d in aFirst ? [a, b] : [b, a]) {
            await sender(d).run();
          }
          await pull(a);
          await pull(b);
          final server = (await cloud.get(paths.caseDoc('ep01')))!;
          expect(server['runId'], a.load('ep01').runId);
          expect(server['runId'], b.load('ep01').runId);
          expect(server['runId'], 'choice-from-b', reason: 'the rule\'s winner, whichever device sent last');
          // The other run is kept where it was played.
          expect(a.conflicts.where((r) => CaseConflicts.runOf(r)?.runId == 'choice-from-a'), isNotEmpty);
          // Sending again changes nothing (no flip back).
          final version = server['cloudVersion'];
          await sender(a).run();
          await sender(b).run();
          expect((await cloud.get(paths.caseDoc('ep01')))!['cloudVersion'], version);
        }, skip: skip);
      }
    });

    group('choosing between two case files, two devices ($label)', () {
      late MemoryCloudStore memory;
      late EmulatorCloudStore admin;
      final devices = <SyncDevice>[];

      Future<Map<String, Object?>?> server(String path) => onEmulator ? admin.get(path) : memory.get(path);

      Future<SyncDevice> device({UserSession? restored}) async {
        final d = await SyncDevice.create(
          restored: restored,
          server: server,
          store: (d) => onEmulator ? AsUserStore(() => d.account.value.uid) : memory,
        );
        devices.add(d);
        return d;
      }

      setUp(() async {
        if (onEmulator) {
          await EmulatorCloudStore.clear();
          admin = EmulatorCloudStore(null);
        } else {
          memory = MemoryCloudStore();
        }
      });

      tearDown(() async {
        for (final d in devices) {
          await d.stop();
          d.account.dispose();
        }
        devices.clear();
      });

      Future<void> confirm(String uid) async {
        final consent = {'status': 'confirmed', 'schema': 1};
        onEmulator ? await admin.put('consents/$uid', consent) : memory.put('consents/$uid', consent);
      }

      Future<void> resume(SyncDevice d) async {
        d.sync.request(SyncTrigger.resume);
        await settle(d.sync);
      }

      /// A and B play Case 01 again each (B offline), both solving m01 —
      /// B m02 too. Back online, each device has two case files: the run
      /// further along (B's) plays on everywhere, A's is kept.
      Future<({SyncDevice a, SyncDevice b, ProviderContainer ca, ProviderContainer cb, String uid, DetectiveProfile p})>
          twoFiles() async {
        final a = await device();
        expect((await a.account.signUp(email: 'anna@example.com', password: 'detective42')).ok, isTrue);
        await pumpEventQueue();
        final uid = a.account.value.uid!;
        await confirm(uid);
        await a.account.refreshConsent();
        final p = await ProfileStore(a.prefs).addProfile(kind: ProfileKind.account, ownerUid: uid, detectiveName: 'ANNA');
        final ca = a.open(p);
        final ga = ca.read(gameControllerProvider.notifier);
        ga.registerDetective('ANNA');
        ga.startInvestigation();
        expect(ga.submitAnswer(m01, m01.answer).coins, 30);
        await settle(a.sync);

        final b = await device(restored: UserSession(uid: uid, emailVerified: true));
        await pumpEventQueue();
        await b.account.refreshConsent();
        expect(await b.restore.restore((await b.restore.accountDetectives()).detectives.single), isNull);
        final cb = b.open(ProfileStore(b.prefs).profile(p.id)!);
        await settle(b.sync);

        b.faulty.down = CloudFailure.unavailable;
        ga.playAgain();
        ga.startInvestigation();
        expect(ga.submitAnswer(m01, m01.answer).coins, 0, reason: 'a mission pays once ever');
        await settle(a.sync);
        final gb = cb.read(gameControllerProvider.notifier);
        gb.playAgain();
        gb.startInvestigation();
        gb.submitAnswer(m01, m01.answer);
        expect(gb.submitAnswer(m02, m02.answer).coins, 30);
        await settle(b.sync, keepPlanned: true);
        b.faulty.down = null;
        await resume(b);
        await resume(a);
        await resume(b);
        return (a: a, b: b, ca: ca, cb: cb, uid: uid, p: p);
      }

      CaseChoice choiceOf(SyncDevice d, ProviderContainer c) => CaseConflicts.choiceFor(d.repoOf(c), 'ep01')!;

      Future<ChoiceResult> choose(SyncDevice d, ProviderContainer c, CaseChoice choice,
              {required bool keepPlaying, bool Function()? valid, void Function()? after}) =>
          CaseFileChooser(sync: d.sync).choose(
            repo: d.repoOf(c),
            choice: choice,
            keepPlaying: keepPlaying,
            isStillValid: valid ?? () => true,
            applied: (id) {
              refreshFromSaves(c, 'case:$id');
              after?.call();
            },
          );

      Future<Map<String, Object?>> serverCase(String uid, DetectiveProfile p) async =>
          (await server(SyncPaths(uid, p.id).caseDoc('ep01')))!;

      test('both devices play the run further along; each keeps the other run as a second file', () async {
        final t = await twoFiles();
        final onA = choiceOf(t.a, t.ca);
        final onB = choiceOf(t.b, t.cb);
        expect(onA.playing.run.completedMissionIds, [m01.id, m02.id]);
        expect(onB.playing.run.completedMissionIds, [m01.id, m02.id]);
        expect(onA.other.run.completedMissionIds, [m01.id]);
        expect(onA.other.run.runId, onB.other.run.runId, reason: 'the same two files on both');
        expect((onA.other.side, onB.other.side), (FileSide.device, FileSide.account));
        final cloud = await serverCase(t.uid, t.p);
        expect(cloud['runId'], onA.playing.run.runId);
        expect(t.ca.read(walletProvider).balance, t.cb.read(walletProvider).balance);
      }, skip: skip);

      test('on B, the account\'s file (A\'s run): the server and A play it; coins unchanged; XP of that file', () async {
        final t = await twoFiles();
        final coins = (t.ca.read(walletProvider).balance, t.cb.read(walletProvider).balance);
        final summary = (await server(SyncPaths(t.uid, t.p.id).walletSummary))!['balance'];
        final c = choiceOf(t.b, t.cb);
        expect(await choose(t.b, t.cb, c, keepPlaying: false), ChoiceResult.applied);
        await settle(t.b.sync);
        final cloud = await serverCase(t.uid, t.p);
        expect((cloud['runSeq'], cloud['runId']), (2, CaseConflicts.choiceRunId(c.other.run, 2)));
        expect(t.b.repoOf(t.cb).conflicts.where((r) => r['status'] == 'waiting'), isEmpty, reason: 'resolved once sent');
        expect(t.b.repoOf(t.cb).conflicts.where((r) => r['status'] == 'resolved'), isNotEmpty);
        await resume(t.a);
        for (final (d, ctr) in [(t.a, t.ca), (t.b, t.cb)]) {
          final now = ctr.read(gameControllerProvider);
          expect(now.runId, cloud['runId']);
          expect(now.completedMissionIds, [m01.id]);
          expect(XpBreakdown.totalFor(ep01, now), 30);
          expect(CaseConflicts.choiceFor(d.repoOf(ctr), 'ep01'), isNull, reason: 'chosen: not asked again');
        }
        expect((t.ca.read(walletProvider).balance, t.cb.read(walletProvider).balance), coins);
        expect((await server(SyncPaths(t.uid, t.p.id).walletSummary))!['balance'], summary);
        // B's run (the one left) is kept on both devices.
        bool keeps(SyncDevice d, ProviderContainer ctr) => d.repoOf(ctr).conflicts.any(
            (r) => CaseConflicts.runOf(r)?.completedMissionIds.length == 2 && r['status'] == 'archived');
        expect((keeps(t.a, t.ca), keeps(t.b, t.cb)), (true, true));
      }, skip: skip);

      test('on A, the device\'s own file: the same, from the other side', () async {
        final t = await twoFiles();
        final c = choiceOf(t.a, t.ca);
        expect(c.other.side, FileSide.device);
        expect(await choose(t.a, t.ca, c, keepPlaying: false), ChoiceResult.applied);
        await settle(t.a.sync);
        await resume(t.b);
        final cloud = await serverCase(t.uid, t.p);
        expect(t.cb.read(gameControllerProvider).runId, cloud['runId']);
        expect(t.ca.read(gameControllerProvider).runId, cloud['runId']);
        expect(t.cb.read(gameControllerProvider).completedMissionIds, [m01.id]);
        expect(CaseConflicts.choiceFor(t.b.repoOf(t.cb), 'ep01'), isNull);
      }, skip: skip);

      test('keep playing the file playing now: everyone stays on it; nothing asked again', () async {
        final t = await twoFiles();
        final before = t.cb.read(gameControllerProvider);
        expect(await choose(t.b, t.cb, choiceOf(t.b, t.cb), keepPlaying: true), ChoiceResult.applied);
        await settle(t.b.sync);
        await resume(t.a);
        for (final ctr in [t.ca, t.cb]) {
          expect(sameProgress(ctr.read(gameControllerProvider), before), isTrue);
        }
        expect(CaseConflicts.choiceFor(t.a.repoOf(t.ca), 'ep01'), isNull);
        expect(CaseConflicts.choiceFor(t.b.repoOf(t.cb), 'ep01'), isNull);
      }, skip: skip);

      test('decide later: nothing changes on the server or the devices, the files stay offered', () async {
        final t = await twoFiles();
        final version = (await serverCase(t.uid, t.p))['cloudVersion'];
        await resume(t.a);
        await resume(t.b);
        expect((await serverCase(t.uid, t.p))['cloudVersion'], version);
        expect(CaseConflicts.choiceFor(t.a.repoOf(t.ca), 'ep01'), isNotNull);
        expect(CaseConflicts.choiceFor(t.b.repoOf(t.cb), 'ep01'), isNotNull);
      }, skip: skip);

      test('the same choice made twice: one new run on the server', () async {
        final t = await twoFiles();
        final c = choiceOf(t.b, t.cb);
        expect(await choose(t.b, t.cb, c, keepPlaying: false), ChoiceResult.applied);
        await settle(t.b.sync);
        final version = (await serverCase(t.uid, t.p))['cloudVersion'];
        expect(await choose(t.b, t.cb, c, keepPlaying: false), ChoiceResult.alreadyDone);
        await settle(t.b.sync);
        final cloud = await serverCase(t.uid, t.p);
        expect((cloud['runSeq'], cloud['cloudVersion']), (2, version));
      }, skip: skip);

      test('offline: chosen on the device, waiting; sent when the connection is back', () async {
        final t = await twoFiles();
        final before = await serverCase(t.uid, t.p);
        t.b.faulty.down = CloudFailure.unavailable;
        expect(await choose(t.b, t.cb, choiceOf(t.b, t.cb), keepPlaying: false), ChoiceResult.applied);
        await settle(t.b.sync, keepPlanned: true);
        final repo = t.b.repoOf(t.cb);
        expect(repo.conflicts.where((r) => r['status'] == 'waiting'), isNotEmpty);
        expect(repo.outbox.events.where((e) => e.kind == OutboxKind.caseRun && e.subject == 'ep01'), isNotEmpty);
        expect((await serverCase(t.uid, t.p))['runSeq'], before['runSeq']);
        t.b.faulty.down = null;
        await resume(t.b);
        expect((await serverCase(t.uid, t.p))['runSeq'], 2);
        expect(repo.conflicts.where((r) => r['status'] == 'waiting'), isEmpty);
      }, skip: skip);

      test('a send that fails: the choice and its change wait, and go once retried', () async {
        final t = await twoFiles();
        expect(
          await choose(t.b, t.cb, choiceOf(t.b, t.cb), keepPlaying: false, after: () => t.b.faulty.failNext = CloudFailure.unavailable),
          ChoiceResult.applied,
        );
        await settle(t.b.sync, keepPlanned: true);
        final repo = t.b.repoOf(t.cb);
        expect(repo.conflicts.where((r) => r['status'] == 'waiting'), isNotEmpty);
        expect(repo.outbox.events.where((e) => e.kind == OutboxKind.caseRun), isNotEmpty, reason: 'never dropped');
        await resume(t.b);
        expect((await serverCase(t.uid, t.p))['runSeq'], 2);
        expect(repo.conflicts.where((r) => r['status'] == 'waiting'), isEmpty);
      }, skip: skip);

      test('the server changed before the choice (chosen on A first): B\'s older view is not applied', () async {
        final t = await twoFiles();
        final stale = choiceOf(t.b, t.cb);
        expect(await choose(t.a, t.ca, choiceOf(t.a, t.ca), keepPlaying: true), ChoiceResult.applied);
        await settle(t.a.sync);
        final afterA = await serverCase(t.uid, t.p);
        expect(await choose(t.b, t.cb, stale, keepPlaying: false), ChoiceResult.changed);
        await settle(t.b.sync);
        final cloud = await serverCase(t.uid, t.p);
        expect((cloud['runId'], cloud['runSeq']), (afterA['runId'], afterA['runSeq']));
        expect(t.cb.read(gameControllerProvider).runId, afterA['runId'], reason: 'B follows the choice made first');
        expect(CaseConflicts.choiceFor(t.b.repoOf(t.cb), 'ep01'), isNull);
      }, skip: skip);

      test('both devices choose offline, different files: the same run everywhere; the other offered again, kept', () async {
        final t = await twoFiles();
        t.a.faulty.down = CloudFailure.unavailable;
        t.b.faulty.down = CloudFailure.unavailable;
        expect(await choose(t.a, t.ca, choiceOf(t.a, t.ca), keepPlaying: false), ChoiceResult.applied); // A's run
        expect(await choose(t.b, t.cb, choiceOf(t.b, t.cb), keepPlaying: true), ChoiceResult.applied); // B's run
        await settle(t.a.sync, keepPlanned: true);
        await settle(t.b.sync, keepPlanned: true);
        t.a.faulty.down = null;
        t.b.faulty.down = null;
        await resume(t.a);
        await resume(t.b);
        await resume(t.a);
        final cloud = await serverCase(t.uid, t.p);
        expect(t.ca.read(gameControllerProvider).runId, cloud['runId']);
        expect(t.cb.read(gameControllerProvider).runId, cloud['runId']);
        expect(t.ca.read(gameControllerProvider).completedMissionIds, [m01.id, m02.id], reason: 'further along wins');
        for (final (d, ctr) in [(t.a, t.ca), (t.b, t.cb)]) {
          final again = CaseConflicts.choiceFor(d.repoOf(ctr), 'ep01');
          expect(again?.other.run.completedMissionIds, [m01.id], reason: 'kept and offered again');
        }
      }, skip: skip);

      test('both devices choose the same file offline: one run, nothing to ask again', () async {
        final t = await twoFiles();
        t.a.faulty.down = CloudFailure.unavailable;
        t.b.faulty.down = CloudFailure.unavailable;
        // Both choose A's run (on A it is "this device", on B "the account").
        expect(await choose(t.a, t.ca, choiceOf(t.a, t.ca), keepPlaying: false), ChoiceResult.applied);
        expect(await choose(t.b, t.cb, choiceOf(t.b, t.cb), keepPlaying: false), ChoiceResult.applied);
        expect(t.ca.read(gameControllerProvider).runId, t.cb.read(gameControllerProvider).runId, reason: 'the same choice is the same run');
        await settle(t.a.sync, keepPlanned: true);
        await settle(t.b.sync, keepPlanned: true);
        t.a.faulty.down = null;
        t.b.faulty.down = null;
        await resume(t.a);
        await resume(t.b);
        await resume(t.a);
        final cloud = await serverCase(t.uid, t.p);
        expect(cloud['runSeq'], 2);
        expect(t.ca.read(gameControllerProvider).runId, cloud['runId']);
        expect(t.cb.read(gameControllerProvider).runId, cloud['runId']);
        expect(CaseConflicts.choiceFor(t.a.repoOf(t.ca), 'ep01'), isNull);
        expect(CaseConflicts.choiceFor(t.b.repoOf(t.cb), 'ep01'), isNull);
      }, skip: skip);

      test('signed out, or another account, while choosing: nothing is changed', () async {
        final t = await twoFiles();
        final repo = t.b.repoOf(t.cb);
        final before = (j(repo.load('ep01')), jsonEncode(repo.conflicts));
        t.b.faulty.beforeList = (_) async {
          t.b.faulty.beforeList = null;
          await t.b.account.signOut();
          await pumpEventQueue();
        };
        final r = await choose(t.b, t.cb, choiceOf(t.b, t.cb), keepPlaying: false, valid: () => t.b.account.value.uid == t.uid);
        expect(r, ChoiceResult.stopped);
        expect((j(repo.load('ep01')), jsonEncode(repo.conflicts)), before);
      }, skip: skip);

      test('another detective chosen while choosing: nothing is changed; the guest is untouched', () async {
        final t = await twoFiles();
        final repo = t.b.repoOf(t.cb);
        final guest = ProfileStore(t.b.prefs).guest!;
        final prefix = AppConstants.profilePrefix(guest.id);
        Map<String, Object?> guestSaves() => {for (final k in t.b.prefs.getKeys()) if (k.startsWith(prefix)) k: t.b.prefs.get(k)};
        final guestBefore = guestSaves();
        final before = (j(repo.load('ep01')), jsonEncode(repo.conflicts));
        var playing = t.p.id;
        t.b.faulty.beforeList = (_) async {
          t.b.faulty.beforeList = null;
          t.b.open(guest);
          playing = guest.id;
        };
        final r = await choose(t.b, t.cb, choiceOf(t.b, t.cb), keepPlaying: false, valid: () => playing == t.p.id);
        expect(r, ChoiceResult.stopped);
        expect((j(repo.load('ep01')), jsonEncode(repo.conflicts)), before);
        expect(guestSaves(), guestBefore);
      }, skip: skip);
    });
  }
}
