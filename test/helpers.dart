import 'package:flutter_riverpod/misc.dart';
import 'package:london_mystery/core/utils/audio_service.dart';
import 'package:london_mystery/data/mock/season1/episode01_mock.dart';
import 'package:london_mystery/data/models/episode.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

final episode01 = Episode.fromJson(episode01Json);

/// Overrides that make the app run without platform plugins.
Future<List<Override>> testOverrides({Map<String, Object> prefs = const {}, AudioService? audio}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final instance = await SharedPreferences.getInstance();
  return [
    sharedPreferencesProvider.overrideWithValue(instance),
    audioServiceProvider.overrideWithValue(audio ?? MockAudioService()),
  ];
}
