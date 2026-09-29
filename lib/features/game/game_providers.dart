import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/audio_service.dart';
import '../../data/models/episode.dart';
import '../../data/models/season_progress.dart';
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

/// Every case of the season in case order (pre-loaded before the app starts;
/// defaults to the bundled content).
final episodeCatalogProvider = Provider<List<Episode>>((ref) => MockEpisodeRepository.bundled());

/// Which case file is open and which cases are solved. Persisted.
class SeasonNotifier extends Notifier<SeasonProgress> {
  @override
  SeasonProgress build() {
    final repo = ref.read(progressRepositoryProvider);
    var season = repo.loadSeason();
    // Saves from before the season existed: a solved Episode 01 still opens Case 02.
    if (!season.isSolved(AppConstants.currentEpisodeId) && repo.load().isCaseSolved) {
      season = season.markSolved(AppConstants.currentEpisodeId);
    }
    final catalog = ref.read(episodeCatalogProvider);
    if (!catalog.any((e) => e.id == season.activeEpisodeId)) {
      season = season.copyWith(activeEpisodeId: catalog.first.id);
    }
    return season;
  }

  void _set(SeasonProgress next) {
    state = next;
    ref.read(progressRepositoryProvider).saveSeason(next);
  }

  void open(String episodeId) => _set(state.copyWith(activeEpisodeId: episodeId));

  void markSolved(String episodeId) {
    if (!state.isSolved(episodeId)) _set(state.markSolved(episodeId));
  }

  /// Forgets the season in memory (storage is cleared by the repository).
  void reset() => state = SeasonProgress.empty;

  /// Case 01 is always open; every other case opens once the case before it
  /// has been solved.
  bool isUnlocked(String episodeId) {
    final catalog = ref.read(episodeCatalogProvider);
    final i = catalog.indexWhere((e) => e.id == episodeId);
    if (i < 0) return false;
    return i == 0 || state.isSolved(catalog[i - 1].id);
  }
}

final seasonProvider = NotifierProvider<SeasonNotifier, SeasonProgress>(SeasonNotifier.new);

/// The episode being played: the open case file.
final currentEpisodeProvider = Provider<Episode>((ref) {
  final id = ref.watch(seasonProvider.select((s) => s.activeEpisodeId));
  final catalog = ref.watch(episodeCatalogProvider);
  return catalog.firstWhere((e) => e.id == id, orElse: () => catalog.first);
});

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
