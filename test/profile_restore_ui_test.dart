import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/cloud/cloud_bootstrap.dart';
import 'package:london_mystery/core/cloud/cloud_environment.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/profile.dart';
import 'package:london_mystery/data/models/wallet.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/data/repositories/profile_store.dart';
import 'package:london_mystery/data/repositories/progress_repository.dart';
import 'package:london_mystery/data/sync/cloud/cloud_catalog.dart';
import 'package:london_mystery/data/sync/cloud/cloud_codec.dart';
import 'package:london_mystery/data/sync/cloud/cloud_store.dart';
import 'package:london_mystery/features/account/account_controller.dart';
import 'package:london_mystery/features/account/auth_service.dart';
import 'package:london_mystery/features/account/fake_auth_service.dart';
import 'package:london_mystery/features/account/firestore_consent_repository.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/wallet_controller.dart';
import 'package:london_mystery/features/profile/profile_session.dart';
import 'package:london_mystery/features/sync/profile_restore.dart';
import 'package:london_mystery/features/sync/sync_scheduler.dart';
import 'package:london_mystery/widgets/game_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'full_playthrough_test.dart' show wait;
import 'helpers.dart';
import 'support/cloud_stores.dart';
import 'title_screen_test.dart' show capture;

const _uid = 'anna-uid';
const _profileId = 'abcdef0123456789abcdef0123456789';

/// Phase 4.4: the detectives screen restores the account's detective kept in
/// the cloud (an in-memory cloud with the records another device sent).
void main() {
  final season = MockEpisodeRepository.bundled();
  final codec = CloudCodec(CloudCatalog.of(season));
  final m01 = season.first.missions.first;

  /// What another device of Anna's sent: Case 01's first mission solved, 50 coins.
  MemoryCloudStore cloudWithAnna() {
    final cloud = MemoryCloudStore();
    final paths = SyncPaths(_uid, _profileId);
    final at = DateTime.utc(2026, 10, 14, 9);
    cloud
      ..put('consents/$_uid', {'status': 'confirmed', 'schema': 1})
      ..put(paths.user, {'schema': 1, 'createdAt': at, 'locale': 'ko', 'region': 'KR'})
      ..put(paths.profile, {'schema': 1, 'detectiveName': 'ANNA', 'createdAt': at})
      ..put(paths.meta, codec.metaToCloud(epoch: 0, cloudVersion: 1).data!);
    final progress = GameProgress(
      detectiveName: 'ANNA',
      introSeen: true,
      completedMissionIds: [m01.id],
      attempts: {m01.id: 1},
      runId: 'run-from-a',
      startedAt: at,
      xpRules: {m01.id: 4},
    );
    cloud.put(paths.caseDoc('ep01'), codec.caseToCloud(caseId: 'ep01', progress: progress, epoch: 0, cloudVersion: 1).data!);
    Map<String, Object?>? summary;
    for (final e in [
      CoinEntry(key: Wallet.startKey, amount: 20, source: CoinSource.start, at: at),
      CoinEntry(key: Wallet.missionKey(m01.id), amount: 30, source: CoinSource.mission, at: at.add(const Duration(minutes: 5))),
    ]) {
      final id = CloudCodec.eventId(0, e.key);
      cloud.put(paths.walletEvent(id), codec.eventToCloud(e, epoch: 0).data!);
      summary = CloudCodec.summaryAfter(previous: summary, epoch: 0, eventId: id, amount: e.amount);
      cloud.put(paths.walletSummary, summary!);
    }
    return cloud;
  }

  Future<({GlobalKey<ProfileSessionHostState> host, SharedPreferences prefs, FaultyStore line})> open(
    WidgetTester t, {
    Size size = const Size(390, 844),
  }) async {
    t.view.physicalSize = size * 3;
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    final overrides = await testOverrides();
    final prefs = await SharedPreferences.getInstance();
    final session = ProfileStore(prefs).ensureActiveSync();
    final cloudStore = cloudWithAnna();
    final line = FaultyStore(cloudStore);
    final cloud = CloudBootstrap(
      decision: const CloudDecision.start(CloudEnvironment.dev),
      initialize: () async => (projectId: CloudEnvironment.dev.projectId, appId: CloudEnvironment.dev.androidAppId),
    );
    // Anna signed in on this new device (a session kept by the sign-in service).
    final auth = FakeAuthService(restored: const UserSession(uid: _uid, emailVerified: true));
    final account = AccountController(
      cloud: cloud,
      createAuth: () => auth,
      consents: FirestoreConsentRepository.withReader((uid) => cloudStore.get('consents/$uid')),
    );
    final host = GlobalKey<ProfileSessionHostState>();
    final sync = SyncScheduler(cloud: cloud, account: account, createStore: () => line);
    addTearDown(sync.dispose);
    final restore = ProfileRestore(
      sync: sync,
      profiles: ProfileStore(prefs),
      repoFor: (id) => SharedPrefsProgressRepository(prefs, profileId: id),
      codec: codec,
      episodeIds: [for (final e in season) e.id],
    );
    cloud.start();
    await t.pump();
    await t.pump();
    await t.pumpWidget(ProfileSessionHost(
      key: host,
      session: session,
      signedInUid: () => account.value.uid,
      overrides: [
        ...overrides,
        cloudBootstrapProvider.overrideWithValue(cloud),
        accountControllerProvider.overrideWithValue(account),
        profileRestoreProvider.overrideWithValue(restore),
      ],
      child: const RepaintBoundary(key: ValueKey('shot'), child: LondonMysteryApp()),
    ));
    await wait(t, const Duration(milliseconds: 400));
    expect(account.value.consentConfirmed, isTrue);
    return (host: host, prefs: prefs, line: line);
  }

  ProviderContainer c(GlobalKey<ProfileSessionHostState> host) => host.currentState!.container;

  Future<void> go(WidgetTester t, GlobalKey<ProfileSessionHostState> host, String location) async {
    c(host).read(routerProvider).go(location);
    await wait(t, const Duration(milliseconds: 700));
  }

  Map<String, Object?> guestSaves(SharedPreferences prefs) {
    final prefix = AppConstants.profilePrefix(ProfileStore(prefs).guest!.id);
    return {for (final k in prefs.getKeys()) if (k.startsWith(prefix)) k: prefs.get(k)};
  }

  testWidgets('a new device: the account\'s detective is listed; restoring it plays it with its cases and coins', (t) async {
    final app = await open(t);
    final guest = app.host.currentState!.session.profileId;
    // The guest of this device has played.
    final game = c(app.host).read(gameControllerProvider.notifier);
    game.registerDetective('GUEST');
    c(app.host).read(walletProvider);
    await t.pump();
    await go(t, app.host, Routes.profiles);
    final guestBefore = guestSaves(app.prefs);
    expect(guestBefore, isNotEmpty, reason: 'the guest has saves');
    expect(find.text('IN YOUR ACCOUNT'), findsOneWidget);
    expect(find.text('ON ANOTHER DEVICE · RESTORE'), findsOneWidget);
    expect(find.text('ANNA'), findsOneWidget);
    await capture(t, 'restore_list');

    await t.tap(find.byKey(const ValueKey('cloud-profile-$_profileId')));
    await wait(t, const Duration(milliseconds: 900));
    expect(app.host.currentState!.session.profileId, _profileId, reason: 'restored, then playing');
    final p = ProfileStore(app.prefs).profile(_profileId)!;
    expect((p.kind, p.ownerUid, p.detectiveName), (ProfileKind.account, _uid, 'ANNA'));
    expect(c(app.host).read(gameControllerProvider).isCompleted(m01.id), isTrue);
    expect(c(app.host).read(walletProvider).balance, 50);
    expect(guestSaves(app.prefs), guestBefore, reason: 'the guest untouched');
    expect(ProfileStore(app.prefs).guest!.id, guest);

    // Listed again: it is now one of this device's detectives.
    await go(t, app.host, Routes.profiles);
    expect(find.text('IN YOUR ACCOUNT'), findsNothing);
    expect(find.text('YOUR ACCOUNT'), findsOneWidget);
  });

  testWidgets('no connection: said plainly, nothing changes; TRY AGAIN lists it', (t) async {
    final app = await open(t, size: const Size(320, 568));
    app.line.down = CloudFailure.unavailable;
    final before = ProfileStore(app.prefs).read()!.toJson().toString();
    await go(t, app.host, Routes.profiles);
    expect(find.text("Couldn't reach your account's case files. Nothing on this device changed."), findsOneWidget);
    expect(find.text('IN YOUR ACCOUNT'), findsNothing);
    await capture(t, 'restore_offline_small');
    expect(ProfileStore(app.prefs).read()!.toJson().toString(), before);

    app.line.down = null;
    final retry = find.widgetWithText(GameButton, 'TRY AGAIN');
    await t.ensureVisible(retry);
    await t.tap(retry);
    await wait(t, const Duration(milliseconds: 700));
    expect(find.text('ON ANOTHER DEVICE · RESTORE'), findsOneWidget);
    expect(find.widgetWithText(GameButton, 'TRY AGAIN'), findsNothing);
  });

  testWidgets('a record that is not valid: nothing restored, the reason shown', (t) async {
    final app = await open(t);
    await go(t, app.host, Routes.profiles);
    // The case on the server is changed into something the game never writes.
    final store = app.line.inner as MemoryCloudStore;
    final path = SyncPaths(_uid, _profileId).caseDoc('ep01');
    final doc = store.docs[path]!;
    store.put(path, {
      ...doc,
      'progress': {...(doc['progress']! as Map<String, Object?>), 'hintsUsed': {m01.id: 99}},
    });
    await t.tap(find.byKey(const ValueKey('cloud-profile-$_profileId')));
    await wait(t, const Duration(milliseconds: 900));
    expect(
      find.text("This detective's records could not be checked, so nothing was restored. Your other detectives are safe."),
      findsOneWidget,
    );
    expect(ProfileStore(app.prefs).profile(_profileId), isNull);
    expect(app.host.currentState!.session.profile.kind, ProfileKind.guest);
  });
}
