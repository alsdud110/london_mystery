import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/constants/app_constants.dart';
import 'data/repositories/episode_repository.dart';
import 'features/game/game_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  final prefs = await SharedPreferences.getInstance();
  const episodes = MockEpisodeRepository();
  final episode = await episodes.fetchEpisode(AppConstants.currentEpisodeId);

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        episodeRepositoryProvider.overrideWithValue(episodes),
        currentEpisodeProvider.overrideWithValue(episode),
      ],
      child: const LondonMysteryApp(),
    ),
  );
}
