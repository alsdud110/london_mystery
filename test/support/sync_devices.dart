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
import 'package:london_mystery/features/account/account_controller.dart';
import 'package:london_mystery/features/account/auth_service.dart';
import 'package:london_mystery/features/account/fake_auth_service.dart';
import 'package:london_mystery/features/account/firestore_consent_repository.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/sync/profile_restore.dart';
import 'package:london_mystery/features/sync/sync_scheduler.dart';
import 'package:london_mystery/features/sync/sync_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'cloud_stores.dart';
import 'sync_harness.dart';

// Shared by the restore and case-file tests (Phase 4.4, 4.5).

/// One device: its saves, sign-in, scheduler and restore.
class SyncDevice {
  SyncDevice(this.prefs, this.auth);

  final SharedPreferences prefs;
  FakeAuthService auth;
  late CloudBootstrap cloud;
  late AccountController account;
  late WatchStore watch;
  late FaultyStore faulty;
  late SyncScheduler sync;
  late ProfileRestore restore;
  final containers = <ProviderContainer>[];

  static final _season = MockEpisodeRepository.bundled();

  /// A device with its own saves; [restored]: an account's sign-in kept
  /// from before (another device of the same account). [server] reads the
  /// shared cloud as the admin; [store] is the cloud as this device sees it.
  static Future<SyncDevice> create({
    UserSession? restored,
    required Future<Map<String, Object?>?> Function(String path) server,
    required CloudStore Function(SyncDevice d) store,
  }) async {
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
    d.watch = WatchStore(store(d));
    d.faulty = FaultyStore(d.watch);
    d.start();
    return d;
  }

  void start() {
    sync = SyncScheduler(
      cloud: cloud,
      account: account,
      createStore: () => faulty,
      saveDelay: const Duration(milliseconds: 40),
      shortDelay: const Duration(milliseconds: 5),
      consentRecheck: Duration.zero,
      policy: const SyncRetryPolicy(baseDelay: Duration(milliseconds: 300)),
    );
    restore = ProfileRestore(
      sync: sync,
      profiles: ProfileStore(prefs),
      repoFor: repoFor,
      codec: CloudCodec(CloudCatalog.of(_season)),
      episodeIds: [for (final e in _season) e.id],
    );
  }

  /// The app started again: a new account (with [auth], which may have been
  /// replaced) and a new scheduler, on the same saves.
  Future<void> restart() async {
    await stop();
    account.dispose();
    account = AccountController(cloud: cloud, createAuth: () => auth, consents: account.consents);
    start();
  }

  Future<void> stop() async {
    await settle(sync);
    sync.dispose();
    for (final c in containers) {
      c.dispose();
    }
    containers.clear();
  }

  SharedPrefsProgressRepository repoFor(String id) => SharedPrefsProgressRepository(prefs, profileId: id);

  SharedPrefsProgressRepository repoOf(ProviderContainer c) =>
      c.read(progressRepositoryProvider) as SharedPrefsProgressRepository;

  ProviderContainer open(DetectiveProfile profile) {
    final c = ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      audioServiceProvider.overrideWithValue(MockAudioService()),
      profileSessionProvider.overrideWithValue(ProfileSession(profile: profile)),
      syncSaveSignalProvider.overrideWithValue(sync.saved),
    ]);
    containers.add(c);
    sync.attach(SyncSession.of(c));
    return c;
  }
}
