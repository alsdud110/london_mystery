import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/core/cloud/cloud_bootstrap.dart';
import 'package:london_mystery/core/cloud/cloud_environment.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/profile.dart';
import 'package:london_mystery/data/models/wallet.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/data/repositories/profile_store.dart';
import 'package:london_mystery/data/repositories/progress_repository.dart';
import 'package:london_mystery/data/sync/cloud/cloud_codec.dart';
import 'package:london_mystery/data/sync/cloud/cloud_store.dart';
import 'package:london_mystery/data/sync/cloud/sync_restorer.dart';
import 'package:london_mystery/data/sync/merge.dart';
import 'package:london_mystery/features/account/account_controller.dart';
import 'package:london_mystery/features/account/auth_service.dart';
import 'package:london_mystery/features/account/fake_auth_service.dart';
import 'package:london_mystery/features/account/firestore_consent_repository.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/scoring.dart';
import 'package:london_mystery/features/game/wallet_controller.dart';
import 'package:london_mystery/features/sync/profile_restore.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/cloud_stores.dart';
import 'support/sync_devices.dart';
import 'support/sync_harness.dart';

/// Phase 4.4: restoring an account's detective on a new device, and bringing
/// down what another device sent. Two devices in one test: each has its own
/// saves (a SharedPreferences instance of its own), sign-in, scheduler and
/// restore; the cloud is shared — in memory (always) or the Firestore
/// emulator with the real rules (`cd firebase && npm run test:sync`).
void main() {
  final season = MockEpisodeRepository.bundled();
  final ep01 = season.first;
  final episodeIds = [for (final e in season) e.id];
  final m01 = ep01.missions.first;
  final m02 = ep01.missions[1];

  group('restore, the pure steps', () {
    late SharedPrefsProgressRepository repo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      repo = SharedPrefsProgressRepository(await SharedPreferences.getInstance(), profileId: 'a' * 32);
    });

    GameProgress run(String runId, List<String> solved) => GameProgress(
          detectiveName: 'ANNA',
          introSeen: true,
          completedMissionIds: solved,
          runId: runId,
          startedAt: DateTime.utc(2026, 10, 14),
        );

    CloudProfileState cloudWith(GameProgress p, {int epoch = 0, Wallet? wallet}) => CloudProfileState(
          meta: CloudMeta(epoch: epoch, cloudVersion: 3),
          cases: {'ep01': CloudAccepted(CaseSnapshot(epoch: epoch, progress: p), cloudVersion: 5)},
          wallet: wallet,
          walletVersion: wallet == null ? null : 2,
        );

    test('two runs that cannot both be kept: the device\'s play stays, the server\'s is held beside it', () {
      repo.save(run('local-run', ['m01']), 'ep01');
      final before = jsonEncode(repo.load('ep01').toJson());
      final r = SyncRestorer.apply(repo, cloudWith(run('cloud-run', ['m01', 'm02'])),
          episodeIds: episodeIds, isStillValid: () => true);
      expect(r.held, ['case:ep01']);
      expect(r.restored, isEmpty);
      expect(jsonEncode(repo.load('ep01').toJson()), before, reason: 'not overwritten');
      final held = repo.conflicts.singleWhere((c) => c['kind'] == 'restoreHeld');
      expect((held['cloud'] as Map)['runId'], 'cloud-run', reason: 'the server\'s run kept, not dropped');
      expect(repo.cloudSync.of('case:ep01').confirmedVersion, isNull, reason: 'not confirmed: merged again later');
    });

    test('the same coin under another amount: the device\'s entry stays, the rest comes down', () {
      final at = DateTime.utc(2026, 10, 14);
      repo.saveWallet(Wallet.empty
          .adding(CoinEntry(key: Wallet.startKey, amount: 20, source: CoinSource.start, at: at))
          .adding(CoinEntry(key: Wallet.tipKey('m01', 2), amount: -20, source: CoinSource.tip, at: at)));
      final cloud = Wallet.empty
          .adding(CoinEntry(key: Wallet.startKey, amount: 20, source: CoinSource.start, at: at))
          .adding(CoinEntry(key: Wallet.tipKey('m01', 2), amount: 0, source: CoinSource.tip, at: at))
          .adding(CoinEntry(key: Wallet.missionKey('m02'), amount: 30, source: CoinSource.mission, at: at));
      final r = SyncRestorer.apply(repo, cloudWith(GameProgress.empty, wallet: cloud),
          episodeIds: episodeIds, isStillValid: () => true);
      expect(r.held, contains('wallet'));
      final w = repo.loadWallet()!;
      expect(w.entries.firstWhere((e) => e.key == Wallet.tipKey('m01', 2)).amount, -20, reason: 'local kept');
      expect(w.has(Wallet.missionKey('m02')), isTrue, reason: 'what does not clash comes down');
      expect(repo.conflicts.where((c) => c['kind'] == 'wallet'), hasLength(1));
    });

    test('a merged record keeps the device\'s own changes waiting where they were (back-off, stalled)', () {
      repo.save(run('same-run', ['m01']), 'ep01');
      for (var i = 0; i < 10; i++) {
        repo.updateCloudSync((m) => m.failed('case:ep01', DateTime.utc(2026, 10, 14)));
      }
      expect(repo.cloudSync.of('case:ep01').stalled, isTrue);
      final r = SyncRestorer.apply(repo, cloudWith(run('same-run', ['m01', 'm02'])),
          episodeIds: episodeIds, isStillValid: () => true);
      expect(r.restored, ['case:ep01']);
      expect(repo.load('ep01').completedMissionIds, containsAll(['m01', 'm02']));
      final sub = repo.cloudSync.of('case:ep01');
      expect((sub.confirmedVersion, sub.stalled, sub.failures), (5, true, 10),
          reason: 'still resumed by the next start, as before');
    });

    test('nothing is applied when the run is no longer valid, or the device is at a later epoch', () {
      repo.save(run('local-run', ['m01']), 'ep01');
      final before = jsonEncode(repo.load('ep01').toJson());
      final cloud = cloudWith(run('local-run', ['m01', 'm02']));
      expect(SyncRestorer.apply(repo, cloud, episodeIds: episodeIds, isStillValid: () => false).restored, isEmpty);
      expect(jsonEncode(repo.load('ep01').toJson()), before);
      repo.clear(); // a New Adventure here, not sent yet: epoch 1
      repo.save(run('new-run', []), 'ep01');
      final after = SyncRestorer.apply(repo, cloud, episodeIds: episodeIds, isStillValid: () => true);
      expect(after.localAhead, isTrue);
      expect(repo.load('ep01').runId, 'new-run', reason: 'the server\'s earlier epoch is never applied');
    });
  });

  for (final onEmulator in [false, true]) {
    final label = onEmulator ? 'emulator' : 'memory';
    final skip = onEmulator && emulatorHost == null ? 'no Firestore emulator (cd firebase && npm run test:sync)' : null;

    group('restore ($label)', () {
      late MemoryCloudStore memory;
      late EmulatorCloudStore admin;
      final devices = <SyncDevice>[];

      Future<Map<String, Object?>?> server(String path) => onEmulator ? admin.get(path) : memory.get(path);

      Future<void> adminPut(String path, Map<String, Object?> data) async =>
          onEmulator ? admin.put(path, data) : memory.put(path, data);

      /// A device with its own saves; [restored]: an account's sign-in kept
      /// from before (another device of the same account).
      Future<SyncDevice> device({UserSession? restored}) async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        ProfileStore(prefs).ensureActiveSync();
        final d = SyncDevice(prefs, FakeAuthService(restored: restored));
        d.cloud = CloudBootstrap(
          decision: const CloudDecision.start(CloudEnvironment.dev),
          initialize: () async => (projectId: CloudEnvironment.dev.projectId, appId: CloudEnvironment.dev.androidAppId),
        );
        d.account = AccountController(
          cloud: d.cloud,
          createAuth: () => d.auth,
          consents: FirestoreConsentRepository.withReader((uid) => server('consents/$uid')),
        );
        await d.cloud.start();
        await pumpEventQueue();
        d.watch = WatchStore(onEmulator ? AsUserStore(() => d.account.value.uid) : memory);
        d.faulty = FaultyStore(d.watch);
        d.start();
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

      Future<void> confirm(String uid) => adminPut('consents/$uid', {'status': 'confirmed', 'schema': 1});

      void play(ProviderContainer c, String name) {
        final game = c.read(gameControllerProvider.notifier);
        game.registerDetective(name);
        game.startInvestigation();
        c.read(walletProvider.notifier).unlockTip(m01, 1);
        game.useHint(m01);
        expect(game.submitAnswer(m01, m01.answer).coins, 30);
      }

      /// Device A: Anna signs up (consent confirmed), plays Case 01's first
      /// mission as ANNA, and it is all sent.
      Future<({SyncDevice a, String uid, DetectiveProfile profile, ProviderContainer c})> annaOnA() async {
        final a = await device();
        expect((await a.account.signUp(email: 'anna@example.com', password: 'detective42')).ok, isTrue);
        await pumpEventQueue();
        final uid = a.account.value.uid!;
        await confirm(uid);
        await a.account.refreshConsent();
        final p = await ProfileStore(a.prefs).addProfile(kind: ProfileKind.account, ownerUid: uid, detectiveName: 'ANNA');
        final c = a.open(p);
        play(c, 'ANNA');
        await settle(a.sync);
        expect(a.repoOf(c).outbox.pending, isEmpty, reason: 'A sent everything');
        return (a: a, uid: uid, profile: p, c: c);
      }

      /// Device B: Anna's sign-in (a new device); its guest has played.
      Future<SyncDevice> annaOnB(String uid) async {
        final b = await device(restored: UserSession(uid: uid, emailVerified: true));
        await pumpEventQueue();
        await b.account.refreshConsent();
        expect(b.account.value.consentConfirmed, isTrue);
        final guest = b.open(ProfileStore(b.prefs).ensureActiveSync().profile);
        play(guest, 'GUEST');
        await settle(b.sync);
        return b;
      }

      /// The guest's saves on [d], byte for byte.
      Map<String, Object?> guestSaves(SyncDevice d) {
        final prefix = AppConstants.profilePrefix(ProfileStore(d.prefs).guest!.id);
        return {for (final k in d.prefs.getKeys()) if (k.startsWith(prefix)) k: d.prefs.get(k)};
      }

      List<String> profileKeys(SyncDevice d, String id) =>
          [for (final k in d.prefs.getKeys()) if (k.startsWith(AppConstants.profilePrefix(id))) k];

      String caseJson(SharedPrefsProgressRepository r) => jsonEncode(r.load('ep01').toJson());

      test('a new device: sign-in lists the detective; restoring brings its cases, coins, XP and season', () async {
        final a = await annaOnA();
        final b = await annaOnB(a.uid);
        final guestBefore = guestSaves(b);

        final listed = await b.restore.accountDetectives();
        expect(listed.problem, isNull);
        expect([for (final d in listed.detectives) (d.id, d.detectiveName, d.onThisDevice)], [(a.profile.id, 'ANNA', false)]);
        expect(await b.restore.restore(listed.detectives.single), isNull);

        final restored = ProfileStore(b.prefs).profile(a.profile.id)!;
        expect((restored.kind, restored.ownerUid, restored.detectiveName), (ProfileKind.account, a.uid, 'ANNA'));
        expect(restored.syncable, isTrue);
        final c = b.open(restored);
        final repoA = a.a.repoOf(a.c);
        final repoB = b.repoOf(c);
        expect(caseJson(repoB), caseJson(repoA), reason: 'the case as on A');
        expect(c.read(gameControllerProvider).isCompleted(m01.id), isTrue);
        expect(XpBreakdown.totalFor(ep01, c.read(gameControllerProvider)), XpBreakdown.totalFor(ep01, a.c.read(gameControllerProvider)));
        expect(c.read(walletProvider).balance, 50);
        expect([for (final e in c.read(walletProvider).entries) e.key],
            unorderedEquals([for (final e in repoA.loadWallet()!.entries) e.key]));
        expect(jsonEncode(repoB.loadSeason().toJson()), jsonEncode(repoA.loadSeason().toJson()));
        expect(repoB.conflicts, isEmpty);
        await settle(b.sync);
        expect(repoB.outbox.pending, isEmpty, reason: 'nothing of A\'s play is sent back as new');
        expect(guestSaves(b), guestBefore, reason: 'the guest is untouched');
        expect(await server(SyncPaths(a.uid, ProfileStore(b.prefs).guest!.id).profile), isNull,
            reason: 'the guest never reaches the account');
      }, skip: skip);

      test('only the account\'s own detectives; one on the device is chosen, not restored', () async {
        final a = await annaOnA();
        // Carl, another account, on A too.
        await a.a.account.signOut();
        await pumpEventQueue();
        expect((await a.a.account.signUp(email: 'carl@example.com', password: 'detective42')).ok, isTrue);
        await pumpEventQueue();
        final carl = a.a.account.value.uid!;
        await confirm(carl);
        await a.a.account.refreshConsent();
        final cp = await ProfileStore(a.a.prefs).addProfile(kind: ProfileKind.account, ownerUid: carl, detectiveName: 'CARL');
        play(a.a.open(cp), 'CARL');
        await settle(a.a.sync);
        expect(await server(SyncPaths(carl, cp.id).meta), isNotNull);

        final b = await annaOnB(a.uid);
        final listed = await b.restore.accountDetectives();
        expect([for (final d in listed.detectives) d.detectiveName], ['ANNA'], reason: 'never another account\'s');
        expect(await b.restore.restore(listed.detectives.single), isNull);
        final again = await b.restore.accountDetectives();
        expect(again.detectives.single.onThisDevice, isTrue);
        final saved = caseJson(b.repoFor(a.profile.id));
        expect(await b.restore.restore(again.detectives.single), isNull, reason: 'on the device: just chosen');
        expect(caseJson(b.repoFor(a.profile.id)), saved);

        // A device where that id is someone else's: refused, nothing replaced.
        final other = await device(restored: UserSession(uid: a.uid, emailVerified: true));
        await pumpEventQueue();
        final store = ProfileStore(other.prefs);
        await store.write(store.read()!.upsert(DetectiveProfile(id: a.profile.id, kind: ProfileKind.account, ownerUid: carl)));
        expect(await other.restore.restore(listed.detectives.single), RestoreProblem.notYours);
        expect(store.profile(a.profile.id)!.ownerUid, carl);
      }, skip: skip);

      test('both devices play on: the same progress, coins and XP on each', () async {
        final a = await annaOnA();
        final b = await annaOnB(a.uid);
        expect(await b.restore.restore((await b.restore.accountDetectives()).detectives.single), isNull);
        final cb = b.open(ProfileStore(b.prefs).profile(a.profile.id)!);
        // B solves the second mission.
        expect(cb.read(gameControllerProvider.notifier).submitAnswer(m02, m02.answer).coins, 30);
        await settle(b.sync);
        expect(b.repoOf(cb).outbox.pending, isEmpty);
        // A comes back to the app: it brings B's play down.
        a.a.sync.onLifecycle(AppLifecycleState.resumed);
        await settle(a.a.sync);
        final ga = a.c.read(gameControllerProvider);
        final gb = cb.read(gameControllerProvider);
        expect(ga.isCompleted(m02.id), isTrue, reason: 'on A\'s screen');
        expect(caseJson(a.a.repoOf(a.c)), caseJson(b.repoOf(cb)));
        expect(a.c.read(walletProvider).balance, 80);
        expect(cb.read(walletProvider).balance, 80);
        expect(XpBreakdown.totalFor(ep01, ga), XpBreakdown.totalFor(ep01, gb));
        expect((await server(SyncPaths(a.uid, a.profile.id).walletSummary))!['balance'], 80);
        // A plays on; B brings it down on its next sign-in / resume.
        a.c.read(gameControllerProvider.notifier).lookUpWord('lantern');
        await settle(a.a.sync);
        b.sync.onLifecycle(AppLifecycleState.resumed);
        await settle(b.sync);
        expect(cb.read(gameControllerProvider).lookedUpWords, contains('lantern'));
        expect(a.a.repoOf(a.c).conflicts, isEmpty);
        expect(b.repoOf(cb).conflicts, isEmpty);
      }, skip: skip);

      test('offline while restoring (from the start or midway): nothing changes; trying again restores', () async {
        final a = await annaOnA();
        final b = await annaOnB(a.uid);
        final d = (await b.restore.accountDetectives()).detectives.single;
        final registry = jsonEncode(ProfileStore(b.prefs).read()!.toJson());

        b.faulty.down = CloudFailure.unavailable;
        expect(await b.restore.restore(d), RestoreProblem.unreachable);
        expect((await b.restore.accountDetectives()).problem, RestoreProblem.unreachable);
        b.faulty.down = null;
        // The connection drops after the first records were read.
        b.faulty.beforeList = (path) async {
          if (path.endsWith('/wallet')) b.faulty.down = CloudFailure.unavailable;
        };
        expect(await b.restore.restore(d), RestoreProblem.unreachable);
        expect(jsonEncode(ProfileStore(b.prefs).read()!.toJson()), registry, reason: 'no detective added');
        expect(profileKeys(b, d.id), isEmpty, reason: 'nothing of it saved');

        b.faulty
          ..beforeList = null
          ..down = null;
        expect(await b.restore.restore(d), isNull);
        expect(b.repoFor(d.id).load('ep01').isCompleted(m01.id), isTrue);
      }, skip: skip);

      test('a New Adventure on another device while restoring: the old epoch is not restored', () async {
        final a = await annaOnA();
        final b = await annaOnB(a.uid);
        final d = (await b.restore.accountDetectives()).detectives.single;
        final paths = SyncPaths(a.uid, a.profile.id);
        // After meta was read (epoch 0), before the cases: the reset lands.
        b.faulty.beforeList = (path) async {
          if (!path.endsWith('/cases')) return;
          b.faulty.beforeList = null;
          final meta = (await server(paths.meta))!;
          await adminPut(paths.meta, {'epoch': 1, 'cloudVersion': (meta['cloudVersion']! as int) + 1, 'updatedAt': DateTime.now().toUtc()});
        };
        expect(await b.restore.restore(d), RestoreProblem.unreachable, reason: 'changed meanwhile: read again');
        expect(ProfileStore(b.prefs).profile(d.id), isNull);
        expect(profileKeys(b, d.id), isEmpty);
        // Read again: only epoch 1 (nothing played there yet).
        expect(await b.restore.restore(d), isNull);
        final repo = b.repoFor(d.id);
        expect(repo.epoch, 1);
        expect(repo.load('ep01').isCompleted(m01.id), isFalse, reason: 'the play before the reset does not come back');
        expect(repo.loadWallet(), isNull);
      }, skip: skip);

      test('signed out, or another account, while restoring: nothing is applied', () async {
        final a = await annaOnA();
        final b = await annaOnB(a.uid);
        final d = (await b.restore.accountDetectives()).detectives.single;
        final guestBefore = guestSaves(b);

        b.faulty.beforeList = (path) async {
          if (!path.endsWith('/cases')) return;
          await b.account.signOut();
          await pumpEventQueue();
        };
        expect(await b.restore.restore(d), anyOf(RestoreProblem.accountChanged, RestoreProblem.notAllowed));
        expect(ProfileStore(b.prefs).profile(d.id), isNull);
        expect(profileKeys(b, d.id), isEmpty);

        // Another account (Ben) signs in midway instead.
        b.faulty.beforeList = (path) async {
          if (!path.endsWith('/cases')) return;
          b.faulty.beforeList = null;
          // (This device's sign-in service numbers its own accounts: the
          // second one made here is not Anna's id.)
          await b.account.signUp(email: 'zoe@example.com', password: 'detective42');
          await b.account.signUp(email: 'ben@example.com', password: 'detective42');
          await pumpEventQueue();
        };
        await b.auth.signOut();
        b.auth = FakeAuthService(restored: UserSession(uid: a.uid, emailVerified: true));
        await b.restart();
        await pumpEventQueue();
        await b.account.refreshConsent();
        expect(b.account.value.uid, a.uid);
        expect(await b.restore.restore(d), anyOf(RestoreProblem.accountChanged, RestoreProblem.notAllowed));
        expect(b.account.value.uid, isNot(a.uid));
        expect(ProfileStore(b.prefs).profile(d.id), isNull);
        expect(profileKeys(b, d.id), isEmpty);
        // Ben sees none of Anna's detectives.
        await confirm(b.account.value.uid!);
        await b.account.refreshConsent();
        expect((await b.restore.accountDetectives()).detectives, isEmpty);
        expect(guestSaves(b), guestBefore);
      }, skip: skip);

      test('a record on the server that is not valid: nothing is restored', () async {
        final a = await annaOnA();
        final b = await annaOnB(a.uid);
        final d = (await b.restore.accountDetectives()).detectives.single;
        final paths = SyncPaths(a.uid, a.profile.id);
        final good = (await server(paths.caseDoc('ep01')))!;
        await adminPut(paths.caseDoc('ep01'), {
          ...good,
          'progress': {...(good['progress']! as Map<String, Object?>), 'attempts': {m01.id: -1}},
        });
        expect(await b.restore.restore(d), RestoreProblem.invalidData);
        expect(ProfileStore(b.prefs).profile(d.id), isNull);
        expect(profileKeys(b, d.id), isEmpty);

        // The case fixed, the coins' summary wrong: still nothing.
        await adminPut(paths.caseDoc('ep01'), good);
        final summary = (await server(paths.walletSummary))!;
        await adminPut(paths.walletSummary, {...summary, 'balance': 999});
        expect(await b.restore.restore(d), RestoreProblem.invalidData);
        expect(profileKeys(b, d.id), isEmpty);

        await adminPut(paths.walletSummary, summary);
        expect(await b.restore.restore(d), isNull);
      }, skip: skip);

      test('after a New Adventure: only the new epoch comes down, the old play does not come back', () async {
        final a = await annaOnA();
        final game = a.c.read(gameControllerProvider.notifier);
        game.lookUpWord('before-reset');
        await game.resetAll();
        play(a.c, 'ANNA');
        game.lookUpWord('after-reset');
        await settle(a.a.sync);
        final paths = SyncPaths(a.uid, a.profile.id);
        expect((await server(paths.meta))!['epoch'], 1);

        final b = await annaOnB(a.uid);
        expect(await b.restore.restore((await b.restore.accountDetectives()).detectives.single), isNull);
        final repo = b.repoFor(a.profile.id);
        expect(repo.epoch, 1);
        final p = repo.load('ep01');
        expect(p.lookedUpWords, contains('after-reset'));
        expect(p.lookedUpWords, isNot(contains('before-reset')));
        expect(repo.loadWallet()!.balance, 50, reason: 'the new epoch\'s coins only');
        expect(repo.conflicts, isEmpty);
      }, skip: skip);

      test('a restart after restoring, then playing on: the saves stay, nothing comes down twice', () async {
        final a = await annaOnA();
        final b = await annaOnB(a.uid);
        expect(await b.restore.restore((await b.restore.accountDetectives()).detectives.single), isNull);
        var c = b.open(ProfileStore(b.prefs).profile(a.profile.id)!);
        await settle(b.sync);
        final before = caseJson(b.repoOf(c));
        final version = (await server(SyncPaths(a.uid, a.profile.id).caseDoc('ep01')))!['cloudVersion'];

        // The app again: a new scheduler and session on the same saves.
        await b.restart();
        await pumpEventQueue();
        await b.account.refreshConsent();
        c = b.open(ProfileStore(b.prefs).profile(a.profile.id)!);
        await settle(b.sync);
        expect(caseJson(b.repoOf(c)), before);
        expect(b.repoOf(c).conflicts, isEmpty);
        expect((await server(SyncPaths(a.uid, a.profile.id).caseDoc('ep01')))!['cloudVersion'], version,
            reason: 'nothing written for a restore');

        // Play on: from where it was.
        expect(c.read(gameControllerProvider.notifier).submitAnswer(m02, m02.answer).coins, 30);
        await settle(b.sync);
        expect(c.read(walletProvider).balance, 80);
        final cloud = (await server(SyncPaths(a.uid, a.profile.id).caseDoc('ep01')))!['progress'] as Map;
        expect(cloud['completedMissionIds'], containsAll([m01.id, m02.id]));
        expect((await server(SyncPaths(a.uid, a.profile.id).walletSummary))!['balance'], 80);
      }, skip: skip);
    });
  }
}
