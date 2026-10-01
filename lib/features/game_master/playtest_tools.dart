import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/game_progress.dart';
import '../game/game_controller.dart';
import '../game/game_providers.dart';

/// Playtest tools appear in debug builds, or in a build made with
/// `--dart-define=LM_PLAYTEST=true`. A normal release build never shows them.
const playtestToolsEnabled = operatorToolsInBuild;

/// Name used when the device has no detective yet.
const playtestDetectiveName = 'TESTER';

/// Sets the device up to play [episodeId] from its beginning, as if the
/// cases before it had been solved: they count as solved for the season
/// (so the case is open and the Case Archive shows their evidence), with no
/// XP-relevant history (no hints, no badges). Everything else on the device
/// is wiped. Only the saves change; the game rules are the same as in play.
Future<void> startPlaytestAt(WidgetRef ref, String episodeId) async {
  final catalog = ref.read(episodeCatalogProvider);
  final at = catalog.indexWhere((e) => e.id == episodeId);
  if (at < 0) throw ArgumentError.value(episodeId, 'episodeId', 'not in the season');
  final name = ref.read(gameControllerProvider).detectiveName ?? playtestDetectiveName;

  await ref.read(gameControllerProvider.notifier).resetAll();
  final repo = ref.read(progressRepositoryProvider);
  final season = ref.read(seasonProvider.notifier);
  final now = DateTime.now();
  for (final e in catalog.take(at)) {
    await repo.save(
      GameProgress(
        detectiveName: name,
        introSeen: true,
        completedMissionIds: [for (final m in e.allMissions) m.id],
        startedAt: now,
        completedAt: now,
        playMillis: 0,
      ),
      e.id,
    );
    season.markSolved(e.id);
  }
  await repo.save(GameProgress(detectiveName: name), episodeId);
  season.open(episodeId);
  ref.invalidate(gameControllerProvider); // load the prepared save
}

/// Clears the open case only (clues, XP, badges, hints), keeping the name
/// and every other case: the same as "Play again" on the Case Solved page.
void restartCurrentCase(WidgetRef ref) => ref.read(gameControllerProvider.notifier).playAgain();
