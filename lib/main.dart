import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/cloud/cloud_bootstrap.dart';
import 'core/cloud/cloud_environment.dart';
import 'data/repositories/episode_repository.dart';
import 'data/repositories/profile_store.dart';
import 'features/account/account_controller.dart';
import 'features/account/firebase_auth_service.dart';
import 'features/game/game_providers.dart';
import 'features/profile/profile_session.dart';

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
  final cloud = CloudBootstrap(
    decision: CloudDecision.of(
      flavor: appFlavor,
      androidApp: !kIsWeb && defaultTargetPlatform == TargetPlatform.android,
      operatorToolsInBuild: operatorToolsInBuild,
    ),
  );

  // The user account: its sign-in service is made only once Firebase is
  // ready. Signing out (or another user signing in) closes a profile of the
  // account before; the guest plays on.
  final account = AccountController(cloud: cloud, createAuth: () => FirebaseAuthService());
  final host = GlobalKey<ProfileSessionHostState>();
  account.addListener(() => host.currentState?.enforceAccess());

  runApp(
    ProfileSessionHost(
      key: host,
      session: session,
      signedInUid: () => account.value.uid,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        episodeRepositoryProvider.overrideWithValue(episodes),
        episodeCatalogProvider.overrideWithValue(catalog),
        cloudBootstrapProvider.overrideWithValue(cloud),
        accountControllerProvider.overrideWithValue(account),
      ],
      child: const LondonMysteryApp(),
    ),
  );
  WidgetsBinding.instance.addPostFrameCallback((_) => cloud.start());
}
