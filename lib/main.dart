import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/repositories/episode_repository.dart';
import 'data/repositories/profile_store.dart';
import 'features/game/game_providers.dart';
import 'features/onboarding/detective_hold_screen.dart';
import 'features/onboarding/launch_reveal.dart';

/// The game runs entirely on the device: no account, no server, no network.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
    // iOS describes the background brightness: dark means white status text.
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
    );
  }
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final prefs = await SharedPreferences.getInstance();
  // The device's one detective: earlier saves are brought to it (copied,
  // read back and verified) before anything reads them.
  final store = ProfileStore(prefs);
  final start = await store.bootstrap();
  const episodes = MockEpisodeRepository();
  // Every season is loaded up front; the season played and its open case are
  // chosen in the game (see `selectedSeasonIdProvider` / `seasonProvider`).
  final catalog = MockEpisodeRepository.inPlayOrder([
    for (final id in await episodes.availableEpisodeIds())
      await episodes.fetchEpisode(id),
  ]);
  // The launch screen's glass, ready for the title's first frame (not when
  // the detective must be chosen first: that page comes before the title).
  await LaunchReveal.prepare(armed: start is ProfileSession);

  runApp(
    DeviceDetectiveGate(
      start: start,
      store: store,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        episodeRepositoryProvider.overrideWithValue(episodes),
        allEpisodesProvider.overrideWithValue(catalog),
      ],
      child: const WorldMysteryApp(),
    ),
  );
}
