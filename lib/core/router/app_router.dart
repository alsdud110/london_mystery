import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/season.dart' show SeasonIds;
import '../../features/game/game_controller.dart';
import '../../features/game/game_providers.dart';
import '../../features/game_master/game_master_screen.dart';
import '../../features/mission/final_mission_screen.dart';
import '../../features/mission/mission_screen.dart';
import '../../features/mission/story_scene_screen.dart';
import '../../features/mission_map/mission_map_screen.dart';
import '../../features/notebook/notebook_screen.dart';
import '../../features/onboarding/detective_settings_screen.dart';
import '../../features/onboarding/episode_select_screen.dart';
import '../../features/onboarding/how_to_play_screen.dart';
import '../../features/onboarding/register_screen.dart';
import '../../features/onboarding/start_screen.dart';
import '../../features/onboarding/story_intro_screen.dart';
import '../../features/result/case_solved_screen.dart';
import '../../features/result/parent_report_screen.dart';
import '../../features/season/season_prologue_screen.dart';
import '../../features/season/season_screen.dart';
import '../../features/season/world_archive_screen.dart';
import '../../features/world_map/world_map_screen.dart';
import '../../widgets/back_to.dart';

abstract final class Routes {
  static const start = '/';

  /// CREATE YOUR DETECTIVE: the device's one detective (no detective yet).
  static const register = '/register';

  /// The detective's name and picture, changed later (progress stays).
  static const detective = '/detective';

  /// How to Play: once after registration, before the season (see
  /// `needsHowToPlayProvider`); [howToPlayAgain] opens it from the map menu.
  static const howToPlay = '/how-to-play';
  static const howToPlayAgain = '/how-to-play?again=1';
  static const season = '/season';

  /// The season board opened from the Detective Archives: its back goes
  /// back to the archives (the board opened any other way goes to the map).
  static const seasonFromArchive = '/season?from=archive';

  /// The season page of season [seasonId], just chosen (GO TO PARIS on the
  /// completed board or on the last case's report): a location of its own,
  /// so the page is built anew for that season.
  static String seasonOf(String seasonId) => '/season?season=$seasonId';

  /// The Detective Archives: every season's file, to choose the next one.
  static const seasons = '/seasons';

  /// The World Map: the main hub. CONTINUE on the title and the end of How
  /// to Play lead to it; a season's back leads back to it.
  static const worldMap = '/world-map';
  static const prologue = '/season/prologue';

  /// Season 2's opening sequence: for the season being played, or as a
  /// preview in a build with operator tools (never in a release build).
  static const parisPrologue = '/season/paris-prologue';
  static const episodes = '/episodes';
  static const intro = '/intro';
  static const map = '/map';
  static const notebook = '/notebook';
  static const archive = '/notebook?view=archive';
  static const finalMission = '/final';
  static const solved = '/solved';

  /// The report of a case solved before, come back to (the app reopened on
  /// it): already closed and stamped, nothing comes down or counts up again.
  static const solvedSettled = '/solved?settled=1';
  static const report = '/report';
  static const gameMaster = '/game-master';

  static String mission(String id) => '/mission/$id';

  static String story(String id) => '/story/$id';

  /// Case Files with one case chosen and its folder open ("OPEN CASE 03").
  static String caseFile(String episodeId) => '$episodes?case=$episodeId';
}

CustomTransitionPage<void> _fade(GoRouterState state, Widget child) => CustomTransitionPage<void>(
  key: state.pageKey,
  child: child,
  transitionDuration: const Duration(milliseconds: 380),
  transitionsBuilder: (context, animation, secondary, child) {
    final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween(begin: const Offset(0, 0.03), end: Offset.zero).animate(curved),
        child: child,
      ),
    );
  },
);

/// These pages are reached with `go`, so nothing lies under them: Android
/// back would close the app. Back goes where a player expects instead
/// (the same place as the page's own back arrow, or the step before it).
Widget _backTo(BuildContext context, String location, Widget page) =>
    BackTo(onBack: () => GoRouter.of(context).go(location), child: page);

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: Routes.start,
    // Server-style access control for a local game: the guard, not the UI,
    // decides whether a screen may open, so typing a URL (web) or deep link
    // cannot skip ahead to locked missions or results.
    redirect: (context, state) {
      final progress = ref.read(gameControllerProvider);
      final episode = ref.read(currentEpisodeProvider);
      final path = state.uri.path;

      // The parent report pass ends as soon as the app navigates anywhere
      // else (browser back/forward or a typed URL while the report is open);
      // a normal pop is handled by the case file screen. Nothing watches this
      // provider, so changing it here does not trigger a rebuild.
      if (path != Routes.report && ref.read(parentReportAccessProvider)) {
        ref.read(parentReportAccessProvider.notifier).revoke();
      }

      if (path == Routes.gameMaster) {
        return ref.read(gameMasterAccessProvider) ? null : Routes.start;
      }
      if (path == Routes.start) return null;
      // One detective per device: CREATE YOUR DETECTIVE only while there is none.
      if (path == Routes.register) return progress.hasDetective ? Routes.start : null;

      if (!progress.hasDetective) return Routes.register;

      if (path == Routes.parisPrologue) {
        // Season 2 is not unlocked for anyone by its opening: only the season
        // being played, or an operator build's preview, may show it.
        final playing = ref.read(selectedSeasonIdProvider) == SeasonIds.paris;
        return playing || ref.read(operatorToolsAvailableProvider) ? null : Routes.seasons;
      }

      if (path == Routes.episodes) {
        // A case file of another season (one not played, or still locked)
        // never opens from a link: the case files of the season played do.
        final focus = state.uri.queryParameters['case'];
        if (focus == null || ref.read(episodeCatalogProvider).any((e) => e.id == focus)) return null;
        return Routes.episodes;
      }
      if (path == Routes.map || path == Routes.notebook) {
        return progress.introSeen ? null : Routes.episodes;
      }
      if (path.startsWith('/mission/')) {
        final id = state.pathParameters['id'] ?? path.substring('/mission/'.length);
        final mission = episode.missionById(id);
        if (!progress.introSeen) return Routes.episodes;
        if (mission == null || mission.isFinal || !progress.isUnlocked(episode, id)) return Routes.map;
        return null;
      }
      if (path.startsWith('/story/')) {
        // Story scenes play only after their mission is solved.
        final id = state.pathParameters['id'] ?? path.substring('/story/'.length);
        final mission = episode.missionById(id);
        // The story after the case: only once the case is closed (a final
        // answered whose last step waits goes back to that step).
        if (mission != null && mission.isFinal && progress.isCompleted(id) && !progress.isCaseSolved) return Routes.finalMission;
        return mission != null && progress.isCompleted(id) ? null : Routes.map;
      }
      if (path == Routes.finalMission) {
        return progress.allMissionsDone(episode) ? null : Routes.map;
      }
      if (path == Routes.solved) {
        return progress.isCaseSolved ? null : Routes.map;
      }
      if (path == Routes.report) {
        // Grown-ups only: opens only right after the parent gate was passed.
        if (!progress.isCaseSolved) return Routes.map;
        return ref.read(parentReportAccessProvider) ? null : Routes.solved;
      }
      return null;
    },
    errorBuilder: (context, state) => const StartScreen(),
    routes: [
      GoRoute(path: Routes.start, pageBuilder: (c, s) => _fade(s, const StartScreen())),
      GoRoute(path: Routes.register, pageBuilder: (c, s) => _fade(s, _backTo(c, Routes.start, const RegisterScreen()))),
      // Pushed over the page it was opened from (back returns there).
      GoRoute(path: Routes.detective, pageBuilder: (c, s) => _fade(s, const DetectiveSettingsScreen())),
      // Needs a detective, like every page below. It handles back itself
      // (the page before, then where it was opened from).
      GoRoute(
        path: Routes.howToPlay,
        pageBuilder: (c, s) => _fade(s, HowToPlayScreen(again: s.uri.queryParameters['again'] == '1')),
      ),
      // The season above its cases (needs a detective, like every page below).
      // Back goes where it was opened from: the archives, else the World Map.
      GoRoute(
        path: Routes.season,
        pageBuilder: (c, s) {
          final back = s.uri.queryParameters['from'] == 'archive' ? Routes.seasons : Routes.worldMap;
          // Its own state per season: GO TO PARIS on the completed
          // board opens the next season on this same page, from its cover.
          return _fade(s, _backTo(c, back, SeasonScreen(key: ValueKey(ref.read(selectedSeasonIdProvider)), backTo: back)));
        },
      ),
      // The Detective Archives: the seasons' files (back: the World Map).
      GoRoute(path: Routes.seasons, pageBuilder: (c, s) => _fade(s, _backTo(c, Routes.worldMap, const WorldArchiveScreen()))),
      // The World Map (back: the title).
      GoRoute(path: Routes.worldMap, pageBuilder: (c, s) => _fade(s, _backTo(c, Routes.start, const WorldMapScreen()))),
      // The season's opening, before Case 01: from the casebook, or straight
      // from How to Play's START FIRST CASE. It handles back itself: the
      // scene before, or the casebook.
      GoRoute(path: Routes.prologue, pageBuilder: (c, s) => _fade(s, const SeasonPrologueScreen())),
      // Season 2's opening (it handles back itself, as Season 1's does).
      GoRoute(path: Routes.parisPrologue, pageBuilder: (c, s) => _fade(s, const ParisPrologueScreen())),
      GoRoute(
        path: Routes.episodes,
        // The case files sit under the season: back goes up to it.
        pageBuilder: (c, s) =>
            _fade(s, _backTo(c, Routes.season, EpisodeSelectScreen(focusCase: s.uri.queryParameters['case']))),
      ),
      GoRoute(path: Routes.intro, pageBuilder: (c, s) => _fade(s, _backTo(c, Routes.episodes, const StoryIntroScreen()))),
      GoRoute(path: Routes.map, pageBuilder: (c, s) => _fade(s, const MissionMapScreen())),
      GoRoute(
        path: Routes.notebook,
        pageBuilder: (c, s) => _fade(s, NotebookScreen(startInArchive: s.uri.queryParameters['view'] == 'archive')),
      ),
      GoRoute(
        path: '/mission/:id',
        pageBuilder: (c, s) => _fade(s, MissionScreen(missionId: s.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/story/:id',
        // The mission is solved: back is the same as TO THE MAP. After the
        // final case, the same as SEE MY CASE REPORT.
        pageBuilder: (c, s) {
          final id = s.pathParameters['id']!;
          final afterCase = ref.read(currentEpisodeProvider).missionById(id)?.isFinal ?? false;
          return _fade(s, _backTo(c, afterCase ? Routes.solved : Routes.map, StorySceneScreen(missionId: id)));
        },
      ),
      GoRoute(path: Routes.finalMission, pageBuilder: (c, s) => _fade(s, const FinalMissionScreen())),
      GoRoute(
        path: Routes.solved,
        pageBuilder: (c, s) =>
            _fade(s, _backTo(c, Routes.map, CaseSolvedScreen(settled: s.uri.queryParameters['settled'] == '1'))),
      ),
      GoRoute(path: Routes.report, pageBuilder: (c, s) => _fade(s, const ParentReportScreen())),
      GoRoute(path: Routes.gameMaster, pageBuilder: (c, s) => _fade(s, const GameMasterScreen())),
    ],
  );
});
