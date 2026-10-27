import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../../core/constants/app_constants.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/difficulty.dart';
import '../../data/models/game_progress.dart';
import '../../data/models/profile.dart';
import '../../data/repositories/memory_preferences.dart';
import '../../data/repositories/profile_store.dart';
import '../game/game_controller.dart';
import '../game/game_providers.dart';
import 'playtest_tools.dart' show playtestDetectiveName;

/// What the game knows of developer mode, from inside either session: the
/// player's own (to enter it) or a test session (to leave it). Null: no
/// developer mode in this game (no [DevSessionHost] above it).
@immutable
class DevSession {
  const DevSession({required this.active, required this.enter, required this.exit});

  /// This is a test session (TESTER, nothing saved on the device).
  final bool active;

  /// Starts a new test session (from the player's own; nothing is carried
  /// over from an earlier one).
  final VoidCallback enter;

  /// Ends the test session and returns to the player's own, as it was.
  final VoidCallback exit;
}

final devSessionProvider = Provider<DevSession?>((ref) => null);

/// The test detective: TESTER, the boy's picture, Rookie. Its id names the
/// test session's namespace (in memory only).
const devDetectiveId = '7e57de7e7e57de7e7e57de7e7e57de7e';

DetectiveProfile devDetective() => DetectiveProfile(
      id: devDetectiveId,
      detectiveName: playtestDetectiveName,
      avatar: DetectiveAvatar.boy,
      difficulty: Difficulty.standard,
      createdAt: GameController.now(),
    );

/// Holds the player's own game and, while developer mode is on, a test
/// session in its place.
///
/// The player's own game lives in one provider container made here and kept
/// for the whole run: entering developer mode only takes it off the screen
/// (its play clock stopped), leaving puts it back exactly as it was — the
/// same saves, the same page (the Game Master page it was left on).
///
/// A test session is a container of its own, with no parent — nothing of it
/// can fall back on the player's providers — whose device storage is
/// [MemoryPreferences]: every save the game makes in it (detective, cases,
/// seasons and their levels, coins, tips, How to Play) stays in memory and
/// is thrown away when the session ends. Each entry makes a new one; within
/// a session the pages come and go and its saves stay. The system Back on a
/// test session's first page leaves developer mode rather than the app.
class DevSessionHost extends StatefulWidget {
  const DevSessionHost({super.key, required this.overrides, required this.child});

  /// The player's own game's overrides (device storage, content, session).
  final List<Override> overrides;

  /// The game ([LondonMysteryApp]), built in whichever session is on.
  final Widget child;

  @override
  State<DevSessionHost> createState() => _DevSessionHostState();
}

class _DevSessionHostState extends State<DevSessionHost> with WidgetsBindingObserver {
  late final ProviderContainer _own = ProviderContainer(
    overrides: [
      ...widget.overrides,
      devSessionProvider.overrideWithValue(DevSession(active: false, enter: _enter, exit: _exit)),
    ],
  );

  ProviderContainer? _test;

  /// Counts the test sessions: each entry is a new one, never the last.
  int _sessions = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _test?.dispose();
    _own.dispose();
    super.dispose();
  }

  void _enter() {
    if (_test != null || !_own.read(operatorToolsAvailableProvider)) return;
    // The player's case clock stops while they are away (nothing written).
    _own.read(gameControllerProvider.notifier).holdPlayClock();
    setState(() {
      _sessions++;
      _test = _newTestSession();
    });
  }

  void _exit() {
    final test = _test;
    if (test == null) return;
    setState(() => _test = null);
    // Thrown away once its pages are gone.
    WidgetsBinding.instance.addPostFrameCallback((_) => test.dispose());
    _own.read(gameControllerProvider.notifier).resumePlayClock();
  }

  ProviderContainer _newTestSession() {
    final tester = devDetective();
    final storage = MemoryPreferences({
      AppConstants.detectiveStorageKey: jsonEncode(DetectiveRecord(profile: tester).toJson()),
      // Its first case file already carries its name, as a new detective's.
      AppConstants.profileKey(devDetectiveId, AppConstants.progressStorageKey):
          jsonEncode(const GameProgress(detectiveName: playtestDetectiveName).toJson()),
      // Straight to the tools: How to Play is not in the way (it can still
      // be opened from the title page).
      AppConstants.onboardingSeenKey(devDetectiveId): true,
      // The device's sound setting, as the player has it.
      AppConstants.soundEnabledKey: ?_own.read(sharedPreferencesProvider).getBool(AppConstants.soundEnabledKey),
    });
    final test = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(storage),
        profileSessionProvider.overrideWithValue(ProfileSession(profile: tester)),
        // The same content, maps and build as the player's game.
        episodeRepositoryProvider.overrideWithValue(_own.read(episodeRepositoryProvider)),
        allEpisodesProvider.overrideWithValue(_own.read(allEpisodesProvider)),
        seasonMapsProvider.overrideWithValue(_own.read(seasonMapsProvider)),
        seasonReleasedProvider.overrideWithValue(_own.read(seasonReleasedProvider)),
        operatorToolsAvailableProvider.overrideWithValue(_own.read(operatorToolsAvailableProvider)),
        // One sound for the device: the player's (stopped with their game).
        audioServiceProvider.overrideWithValue(_own.read(audioServiceProvider)),
        devSessionProvider.overrideWithValue(DevSession(active: true, enter: _enter, exit: _exit)),
      ],
    );
    // It opens on the Game Master's tools.
    test.read(gameMasterAccessProvider.notifier).grant();
    test.read(routerProvider).go(Routes.gameMaster);
    return test;
  }

  /// Back on a test session's first page: out of developer mode, not out
  /// of the app.
  @override
  Future<bool> didPopRoute() async {
    final test = _test;
    if (test == null || test.read(routerProvider).canPop()) return false;
    _exit();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final test = _test;
    if (test == null) {
      return UncontrolledProviderScope(key: const ValueKey('own-session'), container: _own, child: widget.child);
    }
    return UncontrolledProviderScope(
      key: ValueKey('test-session-$_sessions'),
      container: test,
      // A corner ribbon on every page: a test session never passes for the
      // player's game.
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Banner(
          key: const ValueKey('developer-mode-banner'),
          message: 'TESTER',
          location: BannerLocation.topEnd,
          color: AppColors.burgundy,
          child: KeyedSubtree(key: ValueKey('test-app-$_sessions'), child: widget.child),
        ),
      ),
    );
  }
}
