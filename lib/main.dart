import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/cloud/cloud_bootstrap.dart';
import 'core/cloud/cloud_emulator.dart';
import 'core/cloud/cloud_environment.dart';
import 'core/cloud/cloud_sync_mode.dart';
import 'data/repositories/episode_repository.dart';
import 'data/repositories/profile_store.dart';
import 'data/repositories/progress_repository.dart';
import 'data/sync/cloud/cloud_catalog.dart';
import 'data/sync/cloud/cloud_codec.dart';
import 'data/sync/cloud/firestore_cloud_store.dart';
import 'features/account/account_controller.dart';
import 'features/account/consent.dart';
import 'features/account/firebase_auth_service.dart';
import 'features/account/firestore_consent_repository.dart';
import 'features/game/game_providers.dart';
import 'features/profile/profile_session.dart';
import 'features/sync/case_file_choice.dart';
import 'features/sync/profile_restore.dart';
import 'features/sync/sync_scheduler.dart';
import 'features/sync/sync_session.dart';

/// What `main` made, for the app's integration tests.
@visibleForTesting
({
  GlobalKey<ProfileSessionHostState> host,
  CloudBootstrap cloud,
  AccountController account,
  SyncScheduler? sync,
  ProfileRestore? restore,
})? debugApp;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final prefs = await SharedPreferences.getInstance();
  // The detective to play: saves from before profiles are copied to the
  // guest profile (read back and verified) before anything reads them.
  final session = await ProfileStore(prefs).bootstrap();
  const episodes = MockEpisodeRepository();
  // The whole season is loaded up front; the open case is chosen in the
  // case files (see `seasonProvider` / `currentEpisodeProvider`).
  final catalog = MockEpisodeRepository.sortedByNumber([
    for (final id in await episodes.availableEpisodeIds()) await episodes.fetchEpisode(id),
  ]);

  // Firebase (user accounts, later sync) starts only after the game is on
  // screen, and the game never waits for it or needs it.
  final decision = CloudDecision.of(
    flavor: appFlavor,
    androidApp: !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
    iosApp: !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS,
    operatorToolsInBuild: operatorToolsInBuild,
  );
  // A DEV build given LM_CLOUD_EMULATOR talks to the local emulators only;
  // one given LM_CLOUD_SYNC=dev syncs with the real DEV project. Nothing
  // else syncs (PROD never).
  final syncMode = CloudSyncMode.forBuild(decision);
  final emulator = syncMode == CloudSyncMode.emulator ? CloudEmulator.forBuild(decision) : null;
  final cloud = CloudBootstrap(decision: decision, beforeReady: emulator?.connect);

  // The user account: its sign-in service is made only once Firebase is
  // ready. Signing out (or another user signing in) closes a profile of the
  // account before; the guest plays on.
  final account = AccountController(
    cloud: cloud,
    createAuth: () => FirebaseAuthService(),
    consents: syncMode == CloudSyncMode.off
        ? const UndecidedConsent()
        : FirestoreConsentRepository.lazy(() => FirebaseFirestore.instance),
  );
  final host = GlobalKey<ProfileSessionHostState>();
  account.addListener(() => host.currentState?.enforceAccess());

  // The cloud sync of the profile being played (test builds only, see
  // CloudSyncMode).
  final sync = syncMode == CloudSyncMode.off
      ? null
      : (SyncScheduler(
          cloud: cloud,
          account: account,
          createStore: () {
            cloud.requireReady();
            final db = FirebaseFirestore.instance;
            if (emulator != null) {
              if (!emulator.uses(db)) throw StateError('sync outside the emulators');
            } else {
              CloudSyncMode.requireDevApp(decision, Firebase.app().options);
            }
            return FirestoreCloudStore(db);
          },
        )..watchLifecycle());

  // The account's detectives restored on this device (with the sync only).
  final restore = sync == null
      ? null
      : ProfileRestore(
          sync: sync,
          profiles: ProfileStore(prefs),
          repoFor: (id) => SharedPrefsProgressRepository(prefs, profileId: id),
          codec: CloudCodec(CloudCatalog.of(catalog)),
          episodeIds: [for (final e in catalog) e.id],
        );

  debugApp = (host: host, cloud: cloud, account: account, sync: sync, restore: restore);
  runApp(
    ProfileSessionHost(
      key: host,
      session: session,
      signedInUid: () => account.value.uid,
      onSessionStarted: sync == null ? null : (c) => sync.attach(SyncSession.of(c)),
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        episodeRepositoryProvider.overrideWithValue(episodes),
        episodeCatalogProvider.overrideWithValue(catalog),
        cloudBootstrapProvider.overrideWithValue(cloud),
        accountControllerProvider.overrideWithValue(account),
        if (sync != null) syncSaveSignalProvider.overrideWithValue(sync.saved),
        if (restore != null) profileRestoreProvider.overrideWithValue(restore),
        if (sync != null) caseFileChooserProvider.overrideWithValue(CaseFileChooser(sync: sync)),
      ],
      child: const LondonMysteryApp(),
    ),
  );
  WidgetsBinding.instance.addPostFrameCallback((_) => cloud.start());
}
