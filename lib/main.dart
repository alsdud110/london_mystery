import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/repositories/episode_repository.dart';
import 'data/repositories/profile_store.dart';
import 'features/game/game_providers.dart';
import 'features/onboarding/detective_hold_screen.dart';

/// The game runs entirely on the device: no account, no server, no network.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final prefs = await SharedPreferences.getInstance();
  // The device's one detective: earlier saves are brought to it (copied,
  // read back and verified) before anything reads them.
  final store = ProfileStore(prefs);
  final start = await store.bootstrap();
  const episodes = MockEpisodeRepository();
  // The whole season is loaded up front; the open case is chosen in the
  // case files (see `seasonProvider` / `currentEpisodeProvider`).
  final catalog = MockEpisodeRepository.sortedByNumber([
    for (final id in await episodes.availableEpisodeIds())
      await episodes.fetchEpisode(id),
  ]);

  runApp(
    DeviceDetectiveGate(
      start: start,
      store: store,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        episodeRepositoryProvider.overrideWithValue(episodes),
        episodeCatalogProvider.overrideWithValue(catalog),
      ],
      child: const LondonMysteryApp(),
    ),
  );
}
