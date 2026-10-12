import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/audio_service.dart';
import 'features/game/audio_scenes.dart';
import 'features/game/game_controller.dart';
import 'features/game/game_providers.dart';
import 'features/season/season_overview.dart';

class LondonMysteryApp extends ConsumerStatefulWidget {
  const LondonMysteryApp({super.key});

  @override
  ConsumerState<LondonMysteryApp> createState() => _LondonMysteryAppState();
}

class _LondonMysteryAppState extends ConsumerState<LondonMysteryApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // Play time only runs while the game is on screen: the clock stops when
    // the app is hidden or backgrounded and continues when it comes back.
    _lifecycle = AppLifecycleListener(onStateChange: _onLifecycleChanged);
    // The sound follows the page on top (pushed pages included).
    _router = ref.read(routerProvider)..routerDelegate.addListener(_followPage);
    WidgetsBinding.instance.addPostFrameCallback((_) => _followPage());
    // A page whose sound depends on the case (the final, once solved: Big
    // Ben's clock runs again) follows it too. The same scene changes nothing.
    ref.listenManual(gameControllerProvider, (_, _) => _followPage());
  }

  late final GoRouter _router;

  @override
  void dispose() {
    _router.routerDelegate.removeListener(_followPage);
    _lifecycle.dispose();
    super.dispose();
  }

  /// The page on top before this one (to tell travelling on the map).
  String? _lastPath;

  /// The sound follows the page on top: its scene (music, place, detail)
  /// goes to the audio service, which changes only the layers that differ,
  /// so pages of the same place and the same part of the game carry on.
  void _followPage() {
    if (!mounted) return;
    final GoRouterState state;
    try {
      state = _router.state;
    } catch (_) {
      return; // no page yet
    }
    final path = state.uri.path;
    final scene = audioSceneFor(
      path: path,
      id: state.pathParameters['id'],
      episode: ref.read(currentEpisodeProvider),
      progress: ref.read(gameControllerProvider),
      seasonBegun: ref.read(seasonOverviewProvider).begun,
    );
    // GO on the map: the places meet over the camera's move to the place.
    final travelling = _lastPath == Routes.map && (path.startsWith('/mission/') || path == Routes.finalMission);
    _lastPath = path;
    if (scene == null) return; // a page over the scene (notebook, scanner)
    ref
        .read(audioServiceProvider)
        .setScene(scene, transition: travelling ? AudioTransition.travel : AudioTransition.normal);
  }

  void _onLifecycleChanged(AppLifecycleState state) {
    final game = ref.read(gameControllerProvider.notifier);
    final audio = ref.read(audioServiceProvider);
    switch (state) {
      case AppLifecycleState.resumed:
        game.resumePlayClock();
        audio.setForeground(true);
      case AppLifecycleState.hidden || AppLifecycleState.paused || AppLifecycleState.detached:
        game.pausePlayClock();
        audio.setForeground(false);
      case AppLifecycleState.inactive:
        break; // still visible (e.g. a system dialog on top): keep counting
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sound switched on or off: the music and places start or stop with it.
    ref.listen(soundEnabledProvider, (_, _) => ref.read(audioServiceProvider).refresh());
    return MaterialApp.router(
      title: 'London Mystery',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        // Keep kid-sized text readable without breaking layouts at huge scales.
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(textScaler: media.textScaler.clamp(maxScaleFactor: 1.3)),
          child: child!,
        );
      },
    );
  }
}
