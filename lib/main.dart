import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/repositories/episode_repository.dart';
import 'features/game/game_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final prefs = await SharedPreferences.getInstance();
  const episodes = MockEpisodeRepository();
  // The whole season is loaded up front; the open case is chosen in the
  // case files (see `seasonProvider` / `currentEpisodeProvider`).
  final catalog = MockEpisodeRepository.sortedByNumber([
    for (final id in await episodes.availableEpisodeIds()) await episodes.fetchEpisode(id),
  ]);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        episodeRepositoryProvider.overrideWithValue(episodes),
        episodeCatalogProvider.overrideWithValue(catalog),
      ],
      child: const LondonMysteryApp(),
    ),
  );
}
