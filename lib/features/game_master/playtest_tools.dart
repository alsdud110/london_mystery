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
/// XP-relevant history (no hints, no badges). Everything else of the
/// detective is wiped (the saves from before profiles stay). Only the saves
/// change; the game rules are the same as in play. What it sets up is
/// operator data, record by record: the solved runs and their solves in the
/// season record — so the case it opens, and what is played in it, are too
/// (see `openedOnlyByOperator`). None of it is synced to a live cloud.
Future<void> startPlaytestAt(WidgetRef ref, String episodeId) async {
  final catalog = ref.read(episodeCatalogProvider);
  final at = catalog.indexWhere((e) => e.id == episodeId);
  if (at < 0) throw ArgumentError.value(episodeId, 'episodeId', 'not in the season');
  final name = ref.read(gameControllerProvider).detectiveName ?? playtestDetectiveName;

  await ref.read(gameControllerProvider.notifier).resetAll();
  await ref
      .read(profileStoreProvider)
      .update(ref.read(profileSessionProvider).profileId, (p) => p.copyWith(detectiveName: name));
  final repo = ref.read(progressRepositoryProvider);
  final season = ref.read(seasonProvider.notifier);
  final now = DateTime.now();
  repo.transaction(() {
    for (final e in catalog.take(at)) {
      repo.save(
        GameProgress(
          detectiveName: name,
          introSeen: true,
          completedMissionIds: [for (final m in e.allMissions) m.id],
          startedAt: now,
          completedAt: now,
          playMillis: 0,
          playtest: true,
        ),
        e.id,
      );
      season.markSolved(e.id, playtest: true);
    }
    repo.save(GameProgress(detectiveName: name), episodeId);
    season.open(episodeId);
  });
  ref.invalidate(gameControllerProvider); // load the prepared save
}

/// Clears the open case only (clues, XP, badges, hints), keeping the name
/// and every other case: the same as "Play again" on the Case Solved page.
void restartCurrentCase(WidgetRef ref) => ref.read(gameControllerProvider.notifier).playAgain();

/// The game master's reset for the next player: wipes the detective (as
/// "Start a New Adventure" does) and also the saves this device kept from
/// before profiles. The only way those originals are ever removed. Returns
/// false if some saved record could not be removed; running it again is
/// safe and removes what is left. A reset cut short never brings the old
/// progress back: the originals are copied only once.
Future<bool> resetForNextPlayer(WidgetRef ref) async {
  await ref.read(gameControllerProvider.notifier).resetAll();
  return ref.read(profileStoreProvider).wipeLegacy();
}
