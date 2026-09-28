import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/game/game_controller.dart';

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
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  void _onLifecycleChanged(AppLifecycleState state) {
    final game = ref.read(gameControllerProvider.notifier);
    switch (state) {
      case AppLifecycleState.resumed:
        game.resumePlayClock();
      case AppLifecycleState.hidden || AppLifecycleState.paused || AppLifecycleState.detached:
        game.pausePlayClock();
      case AppLifecycleState.inactive:
        break; // still visible (e.g. a system dialog on top): keep counting
    }
  }

  @override
  Widget build(BuildContext context) {
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
