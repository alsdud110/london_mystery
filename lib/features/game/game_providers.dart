import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/audio_service.dart';
import '../../data/models/episode.dart';
import '../../data/repositories/episode_repository.dart';
import '../../data/repositories/progress_repository.dart';

// These are overridden in main() once async setup (prefs, content) is done.

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

final episodeRepositoryProvider = Provider<EpisodeRepository>((ref) => const MockEpisodeRepository());

final progressRepositoryProvider = Provider<ProgressRepository>(
  (ref) => SharedPrefsProgressRepository(ref.watch(sharedPreferencesProvider)),
);

/// The episode being played (pre-loaded before the app starts).
final currentEpisodeProvider = Provider<Episode>(
  (ref) => throw UnimplementedError('currentEpisodeProvider must be overridden'),
);

class SoundEnabledNotifier extends Notifier<bool> {
  @override
  bool build() => ref.read(sharedPreferencesProvider).getBool(AppConstants.soundEnabledKey) ?? true;

  void toggle() {
    state = !state;
    ref.read(sharedPreferencesProvider).setBool(AppConstants.soundEnabledKey, state);
  }
}

final soundEnabledProvider = NotifierProvider<SoundEnabledNotifier, bool>(SoundEnabledNotifier.new);

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AssetAudioService(isEnabled: () => ref.read(soundEnabledProvider));
  ref.onDispose(service.dispose);
  return service;
});

/// Mission id whose pin should play its unlock animation on the map.
/// Transient UI state — deliberately not persisted.
class RecentUnlockNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? missionId) => state = missionId;
}

final recentUnlockProvider = NotifierProvider<RecentUnlockNotifier, String?>(RecentUnlockNotifier.new);

/// Set once a grown-up passes the parent gate; required by the router to
/// open operator tools. Session-only by design.
class GameMasterAccessNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void grant() => state = true;
}

final gameMasterAccessProvider = NotifierProvider<GameMasterAccessNotifier, bool>(GameMasterAccessNotifier.new);

/// One-time pass to the parent report: granted after the parent gate, taken
/// back when the report is closed, so every visit asks a grown-up again.
/// Never persisted, so a restart or a typed URL cannot reuse it.
class ParentReportAccessNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void grant() => state = true;

  void revoke() => state = false;
}

final parentReportAccessProvider =
    NotifierProvider<ParentReportAccessNotifier, bool>(ParentReportAccessNotifier.new);
