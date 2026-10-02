import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../widgets/game_toast.dart';
import '../game/game_controller.dart';
import 'season_overview.dart';

/// What the season pages do with a case. They decide no progress
/// themselves: cases open through [GameController.openEpisode] and the
/// case's own flow, exactly as from the case files.
abstract final class SeasonActions {
  /// Opens case [index] of the season: its story intro the first time, its
  /// map while it is under way (its result once solved).
  static void investigate(BuildContext context, WidgetRef ref, int index) {
    final e = ref.read(seasonOverviewProvider).cases[index];
    if (!ref.read(gameControllerProvider.notifier).openEpisode(e.id)) {
      showGameToast(context, 'This case file is still sealed.');
      return;
    }
    final progress = ref.read(gameControllerProvider);
    context.go(
      progress.isCaseSolved
          ? Routes.solved
          : progress.introSeen
          ? Routes.map
          : Routes.intro,
    );
  }
}
