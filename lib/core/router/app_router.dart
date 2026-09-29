import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/game/game_controller.dart';
import '../../features/game/game_providers.dart';
import '../../features/game_master/game_master_screen.dart';
import '../../features/mission/final_mission_screen.dart';
import '../../features/mission/mission_screen.dart';
import '../../features/mission/qr_scanner_screen.dart';
import '../../features/mission/story_scene_screen.dart';
import '../../features/mission_map/mission_map_screen.dart';
import '../../features/notebook/notebook_screen.dart';
import '../../features/onboarding/episode_select_screen.dart';
import '../../features/onboarding/register_screen.dart';
import '../../features/onboarding/start_screen.dart';
import '../../features/onboarding/story_intro_screen.dart';
import '../../features/result/case_solved_screen.dart';
import '../../features/result/parent_report_screen.dart';

abstract final class Routes {
  static const start = '/';
  static const register = '/register';
  static const episodes = '/episodes';
  static const intro = '/intro';
  static const map = '/map';
  static const notebook = '/notebook';
  static const archive = '/notebook?view=archive';
  static const finalMission = '/final';
  static const solved = '/solved';
  static const report = '/report';
  static const qrScanner = '/scan';
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
      const open = {Routes.start, Routes.register};
      if (open.contains(path)) return null;
      if (!progress.hasDetective) return Routes.register;

      if (path == Routes.map || path == Routes.notebook || path == Routes.qrScanner) {
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
        return episode.missionById(id) != null && progress.isCompleted(id) ? null : Routes.map;
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
      GoRoute(path: Routes.register, pageBuilder: (c, s) => _fade(s, const RegisterScreen())),
      GoRoute(
        path: Routes.episodes,
        pageBuilder: (c, s) => _fade(s, EpisodeSelectScreen(focusCase: s.uri.queryParameters['case'])),
      ),
      GoRoute(path: Routes.intro, pageBuilder: (c, s) => _fade(s, const StoryIntroScreen())),
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
        pageBuilder: (c, s) => _fade(s, StorySceneScreen(missionId: s.pathParameters['id']!)),
      ),
      GoRoute(path: Routes.qrScanner, pageBuilder: (c, s) => _fade(s, const QrScannerScreen())),
      GoRoute(path: Routes.finalMission, pageBuilder: (c, s) => _fade(s, const FinalMissionScreen())),
      GoRoute(path: Routes.solved, pageBuilder: (c, s) => _fade(s, const CaseSolvedScreen())),
      GoRoute(path: Routes.report, pageBuilder: (c, s) => _fade(s, const ParentReportScreen())),
      GoRoute(path: Routes.gameMaster, pageBuilder: (c, s) => _fade(s, const GameMasterScreen())),
    ],
  );
});
