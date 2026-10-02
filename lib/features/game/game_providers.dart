import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/audio_service.dart';
import '../../data/mock/season1/season1_mock.dart';
import '../../data/models/episode.dart';
import '../../data/models/season.dart';
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

/// The season the catalog's cases belong to (its title, casebook lines and
/// who is behind it).
final seasonInfoProvider = Provider<Season>((ref) => Season.fromJson(season1InfoJson));

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
  /// has been solved. With operator access on (test builds only), every case
  /// of the season opens. This is the one place that decides it: the case
  /// files, the case-file link and [GameController.openEpisode] all ask here.
  bool isUnlocked(String episodeId) =>
      unlockRule(ref.read(episodeCatalogProvider), state, episodeId, operator: ref.read(operatorAccessProvider));

  /// [isUnlocked] for any season record (the season board also asks it of
  /// the season as it was a moment ago, to animate what just opened).
  static bool unlockRule(List<Episode> catalog, SeasonProgress season, String episodeId, {required bool operator}) {
    final i = catalog.indexWhere((e) => e.id == episodeId);
    if (i < 0) return false;
    if (operator) return true;
    return i == 0 || season.isSolved(catalog[i - 1].id);
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

/// Cases solved for the first time that the season board has not shown yet:
/// it plays their photo, pin and thread when it next opens, then clears
/// them. Transient UI state, like [recentUnlockProvider] — not persisted.
class RecentSolveNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => const [];

  void add(String episodeId) => state = [...state.where((id) => id != episodeId), episodeId];

  void clear() => state = const [];
}

final recentSolveProvider = NotifierProvider<RecentSolveNotifier, List<String>>(RecentSolveNotifier.new);

/// Set once a grown-up passes the parent gate; required by the router to
/// open operator tools. Session-only by design.
class GameMasterAccessNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void grant() => state = true;
}

final gameMasterAccessProvider = NotifierProvider<GameMasterAccessNotifier, bool>(GameMasterAccessNotifier.new);

/// Whether this build has operator (playtest) tools: debug builds, or a
/// build made with `--dart-define=LM_PLAYTEST=true`. A compile-time
/// constant, so a normal release build has none of them.
const operatorToolsInBuild = kDebugMode || bool.fromEnvironment('LM_PLAYTEST');

/// [operatorToolsInBuild], as a provider so tests can check a release build.
final operatorToolsAvailableProvider = Provider<bool>((ref) => operatorToolsInBuild);

/// Operator full case access, for QA: every case file of the season opens,
/// out of order (see [SeasonNotifier.isUnlocked]). Switched on in the Game
/// Master tools, behind the parent gate; never on in a build without
/// operator tools. Access only: it marks no case solved and gives no XP,
/// badges or evidence — those still come from playing. Session-only, never
/// saved, so a restart turns it off.
class OperatorAccessNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool on) => state = on && ref.read(operatorToolsAvailableProvider);
}

/// The operator access switch (see [operatorAccessProvider] for the effect).
final operatorAccessSwitchProvider = NotifierProvider<OperatorAccessNotifier, bool>(OperatorAccessNotifier.new);

/// True while operator full case access is on (and allowed in this build).
final operatorAccessProvider = Provider<bool>(
  (ref) => ref.watch(operatorToolsAvailableProvider) && ref.watch(operatorAccessSwitchProvider),
);

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
