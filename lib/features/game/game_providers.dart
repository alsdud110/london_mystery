import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/audio_service.dart';
import '../../data/mock/season_catalog.dart';
import '../../data/models/case_talk.dart';
import '../../data/models/episode.dart';
import '../../data/models/mission.dart';
import '../../data/models/profile.dart';
import '../../data/models/season.dart';
import '../../data/models/season_progress.dart';
import '../../data/repositories/episode_repository.dart';
import '../../data/repositories/profile_store.dart';
import '../../data/repositories/progress_repository.dart';
import '../mission_map/map_world.dart' show SeasonMap;

// These are overridden in main() once async setup (prefs, content) is done.

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

final episodeRepositoryProvider = Provider<EpisodeRepository>((ref) => const MockEpisodeRepository());

/// The device's one detective, as saved (see [ProfileStore]).
final profileStoreProvider = Provider<ProfileStore>((ref) => ProfileStore(ref.watch(sharedPreferencesProvider)));

/// The detective this game session plays: given by `main()` from
/// [ProfileStore.bootstrap]; without it (tests) found, or made, here.
final profileSessionProvider = Provider<ProfileSession>((ref) => ref.watch(profileStoreProvider).ensureActiveSync());

/// The session's profile as saved now (name, avatar, pay-back), or as the
/// session started when it is not saved (safe mode).
DetectiveProfile sessionProfile(Ref ref) =>
    ref.read(profileStoreProvider).profile ?? ref.read(profileSessionProvider).profile;

/// The detective as saved (name, avatar), for the pages that show them.
/// Changed only through [change] (see `GameController.createDetective`,
/// `renameDetective`): the name in the case saves changes with it.
class DetectiveProfileNotifier extends Notifier<DetectiveProfile> {
  @override
  DetectiveProfile build() => sessionProfile(ref);

  /// Saves [update] of the detective. In safe mode (nothing saved yet) it
  /// holds for this session only.
  Future<void> change(DetectiveProfile Function(DetectiveProfile p) update) async {
    final store = ref.read(profileStoreProvider);
    final saved = store.read();
    // Shown at once (nothing waits on the write); written behind it.
    final next = update(saved?.profile ?? state);
    state = next;
    if (saved != null) await store.write(saved.withProfile(next));
  }

  /// A new picture for the detective (nothing else changes).
  Future<void> setAvatar(DetectiveAvatar avatar) => change((p) => p.copyWith(avatar: avatar));
}

final detectiveProfileProvider =
    NotifierProvider<DetectiveProfileNotifier, DetectiveProfile>(DetectiveProfileNotifier.new);

/// The detective's saves.
final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  final session = ref.watch(profileSessionProvider);
  return SharedPrefsProgressRepository(
    ref.watch(sharedPreferencesProvider),
    profileId: session.profileId,
    legacyFallback: session.legacyFallback,
  );
});

/// Every case of every season, season by season in case order (pre-loaded
/// before the app starts; defaults to the bundled content).
final allEpisodesProvider = Provider<List<Episode>>((ref) => MockEpisodeRepository.bundled());

/// The talk a mission is played as ([SeasonCatalog.caseTalk]) and the talks
/// around a mission's puzzle ([SeasonCatalog.talkMission]), as the mission
/// page finds them: providers, so a test can give a mission a talk.
final caseTalkOfProvider = Provider<TalkScene? Function(Mission m)>((ref) => SeasonCatalog.caseTalk);
final talkMissionOfProvider = Provider<TalkMission? Function(Mission m)>((ref) => SeasonCatalog.talkMission);

/// Every season of the game, in play order.
final seasonsProvider = Provider<List<Season>>((ref) => [for (final s in SeasonCatalog.all) s.season]);

/// Every case of the season being played, in case order. Every page of a
/// case (case files, map, notebook, report) reads its cases here.
final episodeCatalogProvider = Provider<List<Episode>>((ref) {
  final seasonId = ref.watch(selectedSeasonIdProvider);
  return [for (final e in ref.watch(allEpisodesProvider)) if (e.seasonId == seasonId) e];
});

/// The case [evidenceId] was found in (its glossary explains its words), or
/// null when no case has it.
Episode? caseOfEvidence(List<Episode> catalog, String evidenceId) {
  for (final e in catalog) {
    if (e.allEvidence.any((v) => v.id == evidenceId)) return e;
  }
  return null;
}

/// The case [clueId] was found in, or null when no case has it.
Episode? caseOfClue(List<Episode> catalog, String clueId) {
  for (final e in catalog) {
    if (e.allClues.any((c) => c.id == clueId)) return e;
  }
  return null;
}

/// The season the catalog's cases belong to (its title, casebook lines and
/// who is behind it).
final seasonInfoProvider = Provider<Season>((ref) {
  final id = ref.watch(selectedSeasonIdProvider);
  return ref.watch(seasonsProvider).firstWhere((s) => s.id == id);
});

/// Whether a season can be played yet.
enum SeasonStatus {
  /// The season before it is not finished (its last case is not solved).
  locked,

  /// Unlocked, but not ready: its cases or its map are not in the game yet
  /// (see [SeasonAvailability.hasCases], [SeasonAvailability.hasMap]). It
  /// cannot be entered.
  comingSoon,

  /// Unlocked, with its cases and its map: it can be played.
  open,
}

/// Every season's map by season id (see [SeasonMap.bySeason]); a season
/// missing here is not ready to be played.
final seasonMapsProvider = Provider<Map<String, SeasonMap>>((ref) => SeasonMap.bySeason);

/// Where the detective stands with one season. Worked out from the saves
/// every time (nothing of it is saved itself).
@immutable
class SeasonAvailability {
  const SeasonAvailability({
    required this.season,
    required this.status,
    required this.caseCount,
    required this.solvedCount,
    required this.hasMap,
    this.released = true,
  });

  /// Whether the season is out for players (see [SeasonContent.released]).
  final bool released;

  final Season season;
  final SeasonStatus status;
  final int caseCount;
  final int solvedCount;

  /// Whether the season's map is in the game (see [seasonMapsProvider]).
  final bool hasMap;

  bool get hasCases => caseCount > 0;

  /// How many cases the season has, planned ones included (a season still
  /// being written has fewer in the game).
  int get plannedCount => math.max(caseCount, season.plannedCases ?? 0);

  bool get isUnlocked => status != SeasonStatus.locked;

  /// Whether the detective may play it now (see [SelectedSeasonNotifier]).
  bool get canEnter => status == SeasonStatus.open;

  /// Every case of the season solved, and as many as planned.
  bool get isCompleted => caseCount > 0 && solvedCount == caseCount && caseCount >= (season.plannedCases ?? 0);

  /// The season's cases (of [allEpisodes]), in case order.
  static List<Episode> casesOf(String seasonId, List<Episode> allEpisodes) => [
    for (final e in allEpisodes) if (e.seasonId == seasonId) e,
  ];

  /// The one rule: the first season is always unlocked; every later season
  /// unlocks once the last case of the season before it is solved (Season 2:
  /// Season 1's Case 12). A season needs its cases and its map to be entered:
  /// without them it is not ready, never shown on another season's map.
  /// Operator access does not open a season (it opens the cases of the
  /// season played). Null for a season the game does not have.
  ///
  /// A season not [released] stays COMING SOON for everyone, whatever is
  /// solved or in the game. Only [preview] (an operator build's season
  /// preview: never a release build) opens it, unsealed, to be played.
  static SeasonAvailability? of(
    String seasonId, {
    required List<Season> seasons,
    required List<Episode> allEpisodes,
    required SeasonProgress Function(String seasonId) record,
    required Map<String, SeasonMap> maps,
    bool Function(String seasonId) released = seasonReleased,
    bool preview = false,
  }) {
    final i = seasons.indexWhere((s) => s.id == seasonId);
    if (i < 0) return null;
    final cases = casesOf(seasonId, allEpisodes);
    final own = record(seasonId);
    var unlocked = i == 0 || preview;
    if (!unlocked) {
      final before = casesOf(seasons[i - 1].id, allEpisodes);
      // The season before is all in the game (as many cases as planned), and
      // its last case is solved.
      unlocked = before.isNotEmpty &&
          before.length >= (seasons[i - 1].plannedCases ?? 0) &&
          record(seasons[i - 1].id).isSolved(before.last.id);
    }
    final hasMap = maps.containsKey(seasonId);
    final out = released(seasonId) || preview;
    return SeasonAvailability(
      season: seasons[i],
      status: !unlocked
          ? SeasonStatus.locked
          : cases.isEmpty || !hasMap || !out
          ? SeasonStatus.comingSoon
          : SeasonStatus.open,
      caseCount: cases.length,
      solvedCount: cases.where((e) => own.isSolved(e.id)).length,
      hasMap: hasMap,
      released: released(seasonId),
    );
  }
}

/// Whether a season is out for players: the catalog's word
/// ([seasonReleased]). A provider so tests can play a season as released.
final seasonReleasedProvider = Provider<bool Function(String seasonId)>((ref) => seasonReleased);

/// [SeasonAvailability.of] [seasonId] from the saves, read now.
SeasonAvailability? _availabilityNow(Ref ref, String seasonId) {
  final repo = ref.read(progressRepositoryProvider);
  return SeasonAvailability.of(
    seasonId,
    seasons: ref.read(seasonsProvider),
    allEpisodes: ref.read(allEpisodesProvider),
    record: repo.loadSeason,
    maps: ref.read(seasonMapsProvider),
    released: ref.read(seasonReleasedProvider),
    preview: ref.read(seasonPreviewProvider),
  );
}

/// [SeasonAvailability] of every season by id (null: no such season),
/// worked out again whenever the season played changes.
final seasonAvailabilityProvider = Provider.family<SeasonAvailability?, String>((ref, seasonId) {
  final playing = ref.watch(selectedSeasonIdProvider);
  final playingRecord = ref.watch(seasonProvider);
  final repo = ref.watch(progressRepositoryProvider);
  return SeasonAvailability.of(
    seasonId,
    seasons: ref.watch(seasonsProvider),
    allEpisodes: ref.watch(allEpisodesProvider),
    // The season played as it is now; the others as saved.
    record: (id) => id == playing ? playingRecord : repo.loadSeason(id),
    maps: ref.watch(seasonMapsProvider),
    released: ref.watch(seasonReleasedProvider),
    preview: ref.watch(seasonPreviewProvider),
  );
});

/// The season after the one being played, and whether it can be played now
/// (null: none). Its availability is [seasonAvailabilityProvider]'s: released
/// (or an operator build's season preview) and unlocked, never less.
final nextSeasonProvider = Provider<SeasonAvailability?>((ref) {
  final seasons = ref.watch(seasonsProvider);
  final i = seasons.indexWhere((s) => s.id == ref.watch(selectedSeasonIdProvider));
  if (i < 0 || i + 1 >= seasons.length) return null;
  return ref.watch(seasonAvailabilityProvider(seasons[i + 1].id));
});

/// How many seasons can be entered now (unlocked, with cases and a map).
/// Only Season 1 today: the title then goes straight to its board.
final playableSeasonCountProvider = Provider<int>((ref) => [
  for (final s in ref.watch(seasonsProvider))
    if (ref.watch(seasonAvailabilityProvider(s.id))?.canEnter ?? false) s,
].length);

/// The season the detective is playing: its cases are the case files, its
/// map and notebook. Season 1 until another is chosen; persisted, so the
/// app reopens on it. Only a season that can be entered is ever chosen (see
/// [select]), and a saved choice that cannot be entered (yet) is not resumed.
class SelectedSeasonNotifier extends Notifier<String> {
  @override
  String build() {
    final saved = ref.read(progressRepositoryProvider).loadSelectedSeason();
    if (saved != null && (_availabilityNow(ref, saved)?.canEnter ?? false)) return saved;
    return SeasonIds.london;
  }

  /// Plays season [seasonId]. Refused (false) for a season that is locked,
  /// has no cases yet or does not exist: the check lives here, not only in
  /// the UI. Use `GameController.openSeason`, which also banks the play time.
  bool select(String seasonId) {
    if (seasonId == state) return true;
    if (!(_availabilityNow(ref, seasonId)?.canEnter ?? false)) return false;
    state = seasonId;
    ref.read(progressRepositoryProvider).saveSelectedSeason(seasonId);
    return true;
  }

  /// Back to Season 1 in memory (storage is cleared by the repository).
  void reset() => state = SeasonIds.london;
}

final selectedSeasonIdProvider = NotifierProvider<SelectedSeasonNotifier, String>(SelectedSeasonNotifier.new);

/// Which case file is open and which cases are solved, of the season being
/// played. Persisted: each season keeps its own record.
class SeasonNotifier extends Notifier<SeasonProgress> {
  /// The season this record belongs to.
  late String _seasonId;

  @override
  SeasonProgress build() {
    // Rebuilt when another season is played: that season's own record loads.
    _seasonId = ref.watch(selectedSeasonIdProvider);
    return _fromSaves();
  }

  /// The season as saved (with the fix-ups of older saves).
  SeasonProgress _fromSaves() {
    final repo = ref.read(progressRepositoryProvider);
    var season = repo.loadSeason(_seasonId);
    // Saves from before the season existed: a solved Episode 01 still opens Case 02.
    if (_seasonId == SeasonIds.london &&
        !season.isSolved(AppConstants.currentEpisodeId) &&
        repo.load().isCaseSolved) {
      season = season.markSolved(AppConstants.currentEpisodeId);
    }
    final catalog = ref.read(episodeCatalogProvider);
    if (catalog.isNotEmpty && !catalog.any((e) => e.id == season.activeEpisodeId)) {
      season = season.copyWith(activeEpisodeId: catalog.first.id);
    }
    return season;
  }

  void _set(SeasonProgress next) {
    state = next;
    ref.read(progressRepositoryProvider).saveSeason(next, _seasonId);
  }

  void open(String episodeId) => _set(state.copyWith(activeEpisodeId: episodeId));

  /// [episodeId] solved.
  void markSolved(String episodeId) {
    final next = state.markSolved(episodeId);
    if (!identical(next, state)) _set(next);
  }

  /// The season's opening was watched to its first case's file (once).
  void markPrologueSeen() {
    if (!state.prologueSeen) _set(state.copyWith(prologueSeen: true));
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
  // Off until the player switches it on (the map's sound toggle): the sounds
  // stay in the game, they are simply not heard by default for now.
  bool build() => ref.read(sharedPreferencesProvider).getBool(AppConstants.soundEnabledKey) ?? false;

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
/// operator tools. Turning it on marks no case solved and gives nothing; a
/// mission solved while it is on is saved (progress, XP, coins) as in normal
/// play. Session-only, never saved, so a restart turns it off.
class OperatorAccessNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool on) => state = on && ref.read(operatorToolsAvailableProvider);
}

/// Operator season preview, for building a season before its release: an
/// unreleased season opens, unsealed, to be played from its first case
/// (see [SeasonAvailability.of]). Switched on in the Game Master tools,
/// behind the parent gate; never on in a build without operator tools.
/// Session-only, never saved, so a restart turns it off and a season it
/// opened is no longer resumed (Season 1 is played again). Players are
/// never shown an unreleased season.
class SeasonPreviewNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool on) => state = on && ref.read(operatorToolsAvailableProvider);
}

final seasonPreviewSwitchProvider = NotifierProvider<SeasonPreviewNotifier, bool>(SeasonPreviewNotifier.new);

/// True while the operator season preview is on (and allowed in this build).
final seasonPreviewProvider = Provider<bool>(
  (ref) => ref.watch(operatorToolsAvailableProvider) && ref.watch(seasonPreviewSwitchProvider),
);

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
