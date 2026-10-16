import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/core/cloud/cloud_bootstrap.dart';
import 'package:london_mystery/core/cloud/cloud_environment.dart';
import 'package:london_mystery/core/utils/audio_service.dart';
import 'package:london_mystery/data/models/profile.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/data/repositories/profile_store.dart';
import 'package:london_mystery/data/repositories/progress_repository.dart';
import 'package:london_mystery/data/sync/cloud/cloud_catalog.dart';
import 'package:london_mystery/data/sync/cloud/cloud_codec.dart';
import 'package:london_mystery/data/sync/cloud/cloud_store.dart';
import 'package:london_mystery/data/sync/cloud/sync_retry_policy.dart';
import 'package:london_mystery/data/sync/outbox.dart';
import 'package:london_mystery/features/account/account_controller.dart';
import 'package:london_mystery/features/account/fake_auth_service.dart';
import 'package:london_mystery/features/account/firestore_consent_repository.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/game/wallet_controller.dart';
import 'package:london_mystery/features/sync/sync_gate.dart';
import 'package:london_mystery/features/sync/sync_scheduler.dart';
import 'package:london_mystery/features/sync/sync_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/cloud_stores.dart';
import 'support/sync_harness.dart';

/// Phase 4.3B-1: the sync scheduler with the app's sessions (containers),
/// account and consent, on an in-memory store (always) and on the Firestore
/// emulator with the real rules (`cd firebase && npm run test:sync`).
void main() {
  final season = MockEpisodeRepository.bundled();
  final codec = CloudCodec(CloudCatalog.of(season));
  final m01 = season.first.missions.first;

  for (final onEmulator in [false, true]) {
    final label = onEmulator ? 'emulator' : 'memory';
    final skip = onEmulator && emulatorHost == null ? 'no Firestore emulator (cd firebase && npm run test:sync)' : null;

    group('sync scheduler ($label)', () {
      late SharedPreferences prefs;
      late FakeAuthService auth;
      late CloudBootstrap cloud;
      late AccountController account;
      late MemoryCloudStore memory;
      late EmulatorCloudStore admin;
      late WatchStore watch;
      late FaultyStore faulty;
      late SyncScheduler sync;
      final containers = <ProviderContainer>[];

      Future<Map<String, Object?>?> server(String path) => onEmulator ? admin.get(path) : memory.get(path);

      Future<void> adminPut(String path, Map<String, Object?> data) async =>
          onEmulator ? admin.put(path, data) : memory.put(path, data);

      Future<void> adminDelete(String path) async {
        if (onEmulator) {
          await admin.delete(path);
        } else {
          memory.docs.remove(path);
        }
      }

      SyncScheduler newScheduler() => SyncScheduler(
            cloud: cloud,
            account: account,
            createStore: () => faulty,
            saveDelay: const Duration(milliseconds: 40),
            shortDelay: const Duration(milliseconds: 5),
            consentRecheck: Duration.zero,
            policy: const SyncRetryPolicy(baseDelay: Duration(milliseconds: 300)),
          );

      setUp(() async {
        SharedPreferences.setMockInitialValues({});
        prefs = await SharedPreferences.getInstance();
        ProfileStore(prefs).ensureActiveSync();
        if (onEmulator) {
          await EmulatorCloudStore.clear();
          admin = EmulatorCloudStore(null);
        } else {
          memory = MemoryCloudStore();
        }
        auth = FakeAuthService();
        cloud = CloudBootstrap(
          decision: const CloudDecision.start(CloudEnvironment.dev),
          initialize: () async => (projectId: CloudEnvironment.dev.projectId, appId: CloudEnvironment.dev.androidAppId),
        );
        // The consent record as the app reads it (never written by the app).
        account = AccountController(
          cloud: cloud,
          createAuth: () => auth,
          consents: FirestoreConsentRepository.withReader((uid) => server('consents/$uid')),
        );
        await cloud.start();
        await pumpEventQueue();
        // The store as the signed-in user (the rules see that user).
        watch = WatchStore(onEmulator ? AsUserStore(() => account.value.uid) : memory);
        faulty = FaultyStore(watch);
        sync = newScheduler();
      });

      tearDown(() async {
        await settle(sync);
        sync.dispose();
        for (final c in containers) {
          c.dispose();
        }
        containers.clear();
        account.dispose();
      });

      /// A profile session, as `ProfileSessionHost` makes it, followed by [s].
      ProviderContainer open(DetectiveProfile profile, {SyncScheduler? s}) {
        final scheduler = s ?? sync;
        final c = ProviderContainer(overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          audioServiceProvider.overrideWithValue(MockAudioService()),
          profileSessionProvider.overrideWithValue(ProfileSession(profile: profile)),
          syncSaveSignalProvider.overrideWithValue(scheduler.saved),
        ]);
        containers.add(c);
        scheduler.attach(SyncSession.of(c));
        return c;
      }

      Future<String> signUp(String email) async {
        expect((await account.signUp(email: email, password: 'detective42')).ok, isTrue);
        await pumpEventQueue();
        return account.value.uid!;
      }

      Future<void> confirm(String uid) => adminPut('consents/$uid', {'status': 'confirmed', 'schema': 1});

      Future<DetectiveProfile> accountProfile(String uid, String name) =>
          ProfileStore(prefs).addProfile(kind: ProfileKind.account, ownerUid: uid, detectiveName: name);

      SharedPrefsProgressRepository repoOf(ProviderContainer c) =>
          c.read(progressRepositoryProvider) as SharedPrefsProgressRepository;

      /// Plays Case 01's first mission (name, intro, tip 1, the answer).
      void play(ProviderContainer c, String name) {
        final game = c.read(gameControllerProvider.notifier);
        game.registerDetective(name);
        game.startInvestigation();
        c.read(walletProvider.notifier).unlockTip(m01, 1);
        game.useHint(m01);
        expect(game.submitAnswer(m01, 'b').coins, 30);
      }

      String casePath(String uid, String pid) => SyncPaths(uid, pid).caseDoc('ep01');

      /// Signed in with confirmed consent, playing an account profile.
      Future<({String uid, DetectiveProfile profile, ProviderContainer c})> playing() async {
        final uid = await signUp('anna@example.com');
        await confirm(uid);
        await account.refreshConsent();
        final p = await accountProfile(uid, 'ANNA');
        final c = open(p);
        play(c, 'ANNA');
        await settle(sync);
        return (uid: uid, profile: p, c: c);
      }

      test('the guest and a signed-out player never sync', () async {
        final guest = ProfileStore(prefs).ensureActiveSync().profile;
        final c = open(guest);
        play(c, 'GUEST');
        await settle(sync);
        expect(sync.activity.block, SyncBlock.signedOut);
        final uid = await signUp('anna@example.com');
        await confirm(uid);
        await account.refreshConsent();
        c.read(gameControllerProvider.notifier).lookUpWord('fog');
        await settle(sync);
        expect(sync.activity.block, SyncBlock.guestProfile, reason: 'signed in, but the guest stays on the device');
        expect(sync.runs, 0);
        expect(watch.calls, 0, reason: 'not even a read');
        expect(repoOf(c).outbox.pending, isNotEmpty, reason: 'the guest\'s saves stay queued on the device');
      }, skip: skip);

      test('only a confirmed consent syncs: none, declined, revoked block; the app never writes it', () async {
        final uid = await signUp('anna@example.com');
        final p = await accountProfile(uid, 'ANNA');
        final c = open(p);
        play(c, 'ANNA');
        await settle(sync);
        expect(sync.activity.block, SyncBlock.consentNotConfirmed);
        for (final status in ['declined', 'revoked', 'undecided']) {
          await adminPut('consents/$uid', {'status': status, 'schema': 1});
          sync.onLifecycle(AppLifecycleState.resumed);
          await settle(sync);
          expect(sync.activity.block, SyncBlock.consentNotConfirmed, reason: status);
        }
        expect(sync.runs, 0);
        expect(await server(SyncPaths(uid, p.id).profile), isNull, reason: 'nothing reached the cloud');
        expect(watch.writes, isEmpty);

        await confirm(uid);
        sync.onLifecycle(AppLifecycleState.resumed);
        await settle(sync);
        expect(account.value.consentConfirmed, isTrue, reason: 'read again on resume');
        expect(repoOf(c).outbox.events, isEmpty, reason: 'everything sent');
        expect((await server(SyncPaths(uid, p.id).walletSummary))?['balance'], 50);
        expect(watch.writes.where((p) => p.startsWith('consents/')), isEmpty, reason: 'consent is never written');

        // Withdrawn later: the server record is read before sending.
        await adminPut('consents/$uid', {'status': 'revoked', 'schema': 1});
        c.read(gameControllerProvider.notifier).lookUpWord('fog');
        await settle(sync);
        expect(sync.activity.block, SyncBlock.consentNotConfirmed);
        expect(account.value.consentConfirmed, isFalse);
        expect(repoOf(c).outbox.pending, isNotEmpty, reason: 'kept, never dropped');
      }, skip: skip);

      test('sign-in, account profile, save: its cloud profile is made and the play synced', () async {
        final r = await playing();
        final paths = SyncPaths(r.uid, r.profile.id);
        expect((await server(paths.user))?['region'], 'KR');
        expect((await server(paths.profile))?['detectiveName'], 'ANNA');
        expect((await server(paths.caseDoc('ep01')))?['cloudVersion'], 1);
        expect((await server(paths.walletSummary))?['balance'], 50);
        expect(repoOf(r.c).outbox.events, isEmpty);
        expect(r.c.read(gameControllerProvider).isCompleted('m01'), isTrue, reason: 'the game is as it was');
      }, skip: skip);

      test('a burst of saves and resumes: one run at a time, a few runs in all', () async {
        final r = await playing();
        final before = sync.runs;
        watch.delay = const Duration(milliseconds: 20);
        final game = r.c.read(gameControllerProvider.notifier);
        for (var i = 0; i < 12; i++) {
          game.lookUpWord('word$i');
          if (i.isEven) sync.onLifecycle(AppLifecycleState.resumed);
          await Future<void>.delayed(const Duration(milliseconds: 3));
        }
        await settle(sync);
        expect(watch.maxActive, 1, reason: 'never two cloud calls at once');
        expect(sync.runs - before, inInclusiveRange(1, 3));
        expect(repoOf(r.c).outbox.pending, isEmpty);
        final words = (await server(casePath(r.uid, r.profile.id)))!['progress'] as Map;
        expect((words['lookedUpWords'] as List).length, 12, reason: 'the last state went up');
      }, skip: skip);

      test('signed out or another account during a run: nothing of it is applied', () async {
        final b = await signUp('ben@example.com');
        await confirm(b);
        await account.signOut();
        await pumpEventQueue();
        final r = await playing();
        final repo = repoOf(r.c);
        r.c.read(gameControllerProvider.notifier).lookUpWord('fog');
        // As the case is written (before its commit): out, and Ben in.
        watch.onSet = (path) {
          if (path != casePath(r.uid, r.profile.id)) return;
          watch.onSet = null;
          faulty.duringNext = () async {
            await account.signOut();
            await pumpEventQueue();
            await account.signIn(email: 'ben@example.com', password: 'detective42');
            await pumpEventQueue();
          };
        };
        final confirmedBefore = repo.cloudSync.of('case:ep01').confirmedVersion;
        await settle(sync);
        expect(account.value.uid, b);
        expect(sync.activity.block, SyncBlock.otherAccount, reason: 'the next run sees another account');
        expect(repo.cloudSync.of('case:ep01').confirmedVersion, confirmedBefore, reason: 'not confirmed here');
        expect(repo.outbox.events.where((e) => e.state == OutboxState.inFlight), isEmpty, reason: 'released');
        expect(repo.outbox.pending, isNotEmpty, reason: 'kept for its account');
        expect((await server(casePath(r.uid, r.profile.id)))!['cloudVersion'], 2, reason: 'the commit itself happened');
        expect(await server(SyncPaths(b, r.profile.id).profile), isNull, reason: 'never under the other account');
      }, skip: skip);

      test('a profile switch during a run (even back to the same profile) stops it', () async {
        final r = await playing();
        final repo = repoOf(r.c);
        r.c.read(gameControllerProvider.notifier).lookUpWord('fog');
        ProviderContainer? again;
        watch.onSet = (path) {
          if (path != casePath(r.uid, r.profile.id)) return;
          watch.onSet = null;
          again = open(r.profile); // a new session of the same profile, before the commit
        };
        final confirmedBefore = repo.cloudSync.of('case:ep01').confirmedVersion;
        // The old run applies nothing; the new session's run sends it.
        await settle(sync);
        expect(again, isNotNull);
        expect(repo.cloudSync.of('case:ep01').confirmedVersion, greaterThan(confirmedBefore!));
        expect(repoOf(again!).outbox.pending, isEmpty);
        expect((await server(casePath(r.uid, r.profile.id)))!['cloudVersion'], 3,
            reason: 'the old run committed v2; the new one merged it and wrote v3');
      }, skip: skip);

      test('a deletion in progress blocks; once it is gone, the sync resumes', () async {
        final r = await playing();
        await adminPut('deletions/${r.uid}', {'startedAt': DateTime.utc(2026, 10, 14)});
        r.c.read(gameControllerProvider.notifier).lookUpWord('fog');
        await settle(sync);
        expect(sync.activity.block, SyncBlock.deletionInProgress);
        expect(repoOf(r.c).outbox.pending, isNotEmpty);
        sync.onLifecycle(AppLifecycleState.resumed);
        await settle(sync);
        expect(sync.activity.block, SyncBlock.deletionInProgress, reason: 'stays closed');
        await adminDelete('deletions/${r.uid}');
        sync.onLifecycle(AppLifecycleState.resumed);
        await settle(sync);
        expect(repoOf(r.c).outbox.pending, isEmpty);
      }, skip: skip);

      test('offline: kept and backed off, sent when the cloud is back', () async {
        final r = await playing();
        faulty.down = CloudFailure.unavailable;
        r.c.read(gameControllerProvider.notifier).lookUpWord('fog');
        await settle(sync, keepPlanned: true);
        expect(repoOf(r.c).outbox.pending, isNotEmpty);
        expect(sync.planned, isTrue, reason: 'the next try is planned from the back-off');
        faulty.down = null;
        await settle(sync, timeout: const Duration(seconds: 5));
        expect(repoOf(r.c).outbox.pending, isEmpty);
        final progress = (await server(casePath(r.uid, r.profile.id)))!['progress'] as Map;
        expect(progress['lookedUpWords'], contains('fog'));
      }, skip: skip);

      test('the consent and deletion records cannot be read: nothing is read or sent, tried again later', () async {
        final r = await playing();
        watch.failGets = true;
        final before = watch.transactions;
        r.c.read(gameControllerProvider.notifier).lookUpWord('fog');
        await settle(sync, keepPlanned: true);
        expect(sync.activity.hold, SyncHold.unreachable);
        expect(watch.transactions, before, reason: 'no profile, case or wallet read or written');
        expect(repoOf(r.c).outbox.pending, isNotEmpty);
        expect(sync.planned, isTrue, reason: 'a back-off, then again');
        watch.failGets = false;
        await settle(sync, timeout: const Duration(seconds: 5));
        expect(repoOf(r.c).outbox.pending, isEmpty);
      }, skip: skip);

      test('the app in the background plans nothing; coming back sends', () async {
        final r = await playing();
        sync.onLifecycle(AppLifecycleState.paused);
        r.c.read(gameControllerProvider.notifier).lookUpWord('fog');
        await Future<void>.delayed(const Duration(milliseconds: 120));
        expect(sync.planned, isFalse);
        expect(repoOf(r.c).outbox.pending, isNotEmpty);
        sync.onLifecycle(AppLifecycleState.resumed);
        await settle(sync);
        expect(repoOf(r.c).outbox.pending, isEmpty);
      }, skip: skip);

      test('a restart: changes cut off mid-send and stalled ones are sent again', () async {
        final r = await playing();
        final repo = repoOf(r.c);
        sync.onLifecycle(AppLifecycleState.paused); // nothing is sent before the "restart"
        r.c.read(gameControllerProvider.notifier).lookUpWord('fog');
        // Cut off mid-send; the case had stalled before.
        repo.updateOutbox((o) => o.claim([for (final e in o.pending) e.id]));
        for (var i = 0; i < 10; i++) {
          repo.updateCloudSync((m) => m.failed('case:ep01', DateTime.now()));
        }
        repo.updateOutbox((o) => o.markStalled(OutboxKind.caseRun, 'ep01'));
        expect(repo.cloudSync.anyStalled, isTrue);
        sync.dispose();
        containers.remove(r.c..dispose());

        sync = newScheduler(); // the app again: new scheduler, new session
        final c = open(r.profile);
        await settle(sync);
        final after = repoOf(c);
        expect(after.outbox.events, isEmpty);
        expect(after.cloudSync.anyStalled, isFalse);
        expect(after.cloudSync.needsFullResync, isFalse, reason: 'the full resync ran');
        final progress = (await server(casePath(r.uid, r.profile.id)))!['progress'] as Map;
        expect(progress['lookedUpWords'], contains('fog'));
      }, skip: skip);

      test('a merge with another device is on screen at once; the next save keeps it', () async {
        final r = await playing();
        final path = casePath(r.uid, r.profile.id);
        final cloudNow = (await server(path))!;
        // Another device of the same profile added a word to the same run.
        final repo = repoOf(r.c);
        final theirs = repo.load('ep01').copyWith(lookedUpWords: ['lantern'], rev: repo.load('ep01').rev + 1);
        final w = codec.caseToCloud(caseId: 'ep01', progress: theirs, epoch: 0, cloudVersion: (cloudNow['cloudVersion']! as int) + 1);
        await adminPut(path, {...w.data!, 'updatedAt': DateTime.now().toUtc()});

        var seen = <String>[];
        r.c.listen(gameControllerProvider, (_, next) => seen = next.lookedUpWords);
        r.c.read(gameControllerProvider.notifier).lookUpWord('fog');
        await settle(sync);
        expect(r.c.read(gameControllerProvider).lookedUpWords, containsAll(['fog', 'lantern']),
            reason: 'the merged case is what the game shows');
        expect(seen, containsAll(['fog', 'lantern']), reason: 'listeners were told');
        r.c.read(gameControllerProvider.notifier).lookUpWord('bridge');
        expect(repo.load('ep01').lookedUpWords, containsAll(['fog', 'lantern', 'bridge']),
            reason: 'the next save is made on top of the merge');
        await settle(sync);
        final progress = (await server(path))!['progress'] as Map;
        expect(progress['lookedUpWords'], containsAll(['fog', 'lantern', 'bridge']));
      }, skip: skip);

      test('the records change while they are brought down: read again by itself, with nothing to send', () async {
        final r = await playing();
        final paths = SyncPaths(r.uid, r.profile.id);
        expect(repoOf(r.c).outbox.pending, isEmpty, reason: 'nothing waiting: only the pull can plan a run');
        // sync/meta moves between the meta read and the cases (written by the
        // trusted side here, so nothing else on this device reacts to it).
        faulty.beforeList = (path) async {
          if (!path.endsWith('/cases')) return;
          faulty.beforeList = null;
          final meta = (await server(paths.meta))!;
          await adminPut(paths.meta, {...meta, 'cloudVersion': (meta['cloudVersion']! as int) + 1});
        };
        final runs = sync.runs;
        sync.onLifecycle(AppLifecycleState.resumed);
        await settle(sync, timeout: const Duration(seconds: 5));
        expect(sync.runs - runs, 2, reason: 'the changed pull planned one more run by itself');
        expect(sync.activity.pulled, isNotNull, reason: 'that run brought the records down');
        expect(r.c.read(gameControllerProvider).isCompleted('m01'), isTrue);
      }, skip: skip);

      test('a reset on another device: this session starts over at the new epoch', () async {
        final r = await playing();
        final paths = SyncPaths(r.uid, r.profile.id);
        final meta = (await server(paths.meta))!;
        await adminPut(paths.meta, {'epoch': 1, 'cloudVersion': (meta['cloudVersion']! as int) + 1, 'updatedAt': DateTime.now().toUtc()});
        r.c.read(gameControllerProvider.notifier).lookUpWord('fog');
        await settle(sync);
        expect(repoOf(r.c).epoch, 1);
        expect(r.c.read(gameControllerProvider).completedMissionIds, isEmpty, reason: 'the case shows the reset');
        expect(r.c.read(walletProvider).balance, 20, reason: 'a new wallet: the start coins');
        expect(repoOf(r.c).conflicts.where((x) => x['kind'] == 'epoch'), isNotEmpty, reason: 'its play was kept aside');
      }, skip: skip);
    });
  }
}
