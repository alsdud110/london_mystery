import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/difficulty.dart';
import '../../data/models/game_progress.dart';
import '../../data/models/profile.dart';
import '../game/game_controller.dart';
import '../game/game_providers.dart';
import '../onboarding/how_to_play_state.dart';
import 'dev_session.dart';

/// Playtest tools appear in debug builds, or in a build made with
/// `--dart-define=LM_PLAYTEST=true`. A normal release build never shows them.
const playtestToolsEnabled = operatorToolsInBuild;

/// Name used when the device has no detective yet, and developer mode's
/// test detective.
const playtestDetectiveName = 'TESTER';

/// In a game with developer mode (a [DevSessionHost] above it), the test
/// tools run in a test session only, never on the player's own saves. A
/// game without one (a test of the tools themselves) runs them where it is.
bool onPlayerSaves(WidgetRef ref) => ref.read(devSessionProvider)?.active == false;

/// Sets the device up to play [episodeId] from its beginning, as if the
/// cases before it had been solved: they count as solved for the season
/// (so the case is open and the Case Archive shows their evidence), with no
/// XP-relevant history (no hints, no badges). Everything else of the
/// detective is wiped (the saves from before profiles stay); the detective
/// keeps its name and picture. Only the saves change; the game rules are the
/// same as in play. A case of the first season only: the wipe starts the
/// game over in it (refused before anything is wiped otherwise). Refused on
/// the player's own saves (see [onPlayerSaves]).
Future<void> startPlaytestAt(WidgetRef ref, String episodeId) async {
  if (onPlayerSaves(ref)) throw StateError('test tools run in a developer test session only');
  final firstSeason = ref.read(seasonsProvider).first.id;
  final catalog = SeasonAvailability.casesOf(firstSeason, ref.read(allEpisodesProvider));
  final at = catalog.indexWhere((e) => e.id == episodeId);
  if (at < 0) throw ArgumentError.value(episodeId, 'episodeId', 'not a case of the first season');
  final name = ref.read(gameControllerProvider).detectiveName ?? playtestDetectiveName;
  final avatar = ref.read(detectiveProfileProvider).avatar ?? DetectiveAvatar.boy;

  await ref.read(gameControllerProvider.notifier).newAdventure();
  final profile = ref.read(detectiveProfileProvider);
  await ref.read(detectiveProfileProvider.notifier).change((p) => p.copyWith(
        detectiveName: name,
        avatar: avatar,
        createdAt: profile.createdAt ?? DateTime.now(),
      ));
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
        ),
        e.id,
      );
      season.markSolved(e.id);
    }
    repo.save(GameProgress(detectiveName: name), episodeId);
    season.open(episodeId);
  });
  ref.invalidate(gameControllerProvider); // load the prepared save
}

/// Why [jumpToCase] did not open a case (null: it opened).
enum CaseJumpRefusal {
  /// Not a build with operator tools (a release build).
  noOperatorTools,

  /// The device has no detective yet: one is created first, as in play.
  noDetective,

  /// No such case in that season, or the season cannot be entered.
  notOpen,

  /// The player's own saves (developer mode is not on): the shortcut runs in
  /// a test session only (see [onPlayerSaves]).
  playerSaves,
}

/// The Game Master's case shortcut: opens case [episodeId] of season
/// [seasonId] at its case file, whatever is solved, without changing any
/// save. It switches on the two session-only operator switches the tools
/// already have — the season preview (an unreleased or still locked season
/// opens, see [SeasonAvailability.of]) for a season after the first, and
/// operator access (every case of the season opens, out of order, see
/// [SeasonNotifier.isUnlocked]) — then opens the season and the case as
/// the case files do. Nothing is wiped or marked solved: the only things
/// saved are which season and which case file are open, as when a player
/// opens them. Both switches end with the session, so a restart is back to
/// the player's own unlocks. A mission solved meanwhile is saved as in play.
CaseJumpRefusal? jumpToCase(WidgetRef ref, String seasonId, String episodeId) {
  if (!ref.read(operatorToolsAvailableProvider)) return CaseJumpRefusal.noOperatorTools;
  if (onPlayerSaves(ref)) return CaseJumpRefusal.playerSaves;
  if (!ref.read(gameControllerProvider).hasDetective) return CaseJumpRefusal.noDetective;
  final cases = SeasonAvailability.casesOf(seasonId, ref.read(allEpisodesProvider));
  if (!cases.any((e) => e.id == episodeId)) return CaseJumpRefusal.notOpen;
  if (seasonId != ref.read(seasonsProvider).first.id) ref.read(seasonPreviewSwitchProvider.notifier).set(true);
  ref.read(operatorAccessSwitchProvider.notifier).set(true);
  final game = ref.read(gameControllerProvider.notifier);
  if (!game.openSeason(seasonId) || !ref.read(gameControllerProvider.notifier).openEpisode(episodeId)) {
    return CaseJumpRefusal.notOpen;
  }
  return null;
}

/// Developer mode: the test session plays at [level] from now on — TESTER's
/// level, and the season played if its level is fixed already. A case under
/// way starts again from its Mission 1 (the level changed in the middle of
/// it); a case not begun is only played at the new level. No question asked
/// (a test session's saves are thrown away anyway). Refused (false) outside
/// a test session: the player's own level changes only by the season rules.
/// Returns whether the case played started again.
bool changeTestLevel(WidgetRef ref, Difficulty level) {
  if (!(ref.read(devSessionProvider)?.active ?? false)) return false;
  ref.read(detectiveProfileProvider.notifier).setDifficulty(level);
  if (ref.read(seasonProvider).difficulty != null) ref.read(seasonProvider.notifier).fixDifficulty(level);
  final p = ref.read(gameControllerProvider);
  final begun = p.introSeen || p.completedMissionIds.isNotEmpty;
  if (begun) ref.read(gameControllerProvider.notifier).playAgain();
  return begun;
}

/// Clears the open case only (clues, XP, badges, hints), keeping the name
/// and every other case: the same as "Play again" on the Case Solved page.
/// Nothing on the player's own saves (see [onPlayerSaves]).
void restartCurrentCase(WidgetRef ref) {
  if (onPlayerSaves(ref)) return;
  ref.read(gameControllerProvider.notifier).playAgain();
}

/// The game master's reset for the next player: wipes the game and the
/// detective (the next child creates their own and sees How to Play again)
/// and also the saves this device kept from before profiles. The only way those originals are ever removed. Returns
/// false if some saved record could not be removed; running it again is
/// safe and removes what is left. A reset cut short never brings the old
/// progress back: the originals are copied only once.
Future<bool> resetForNextPlayer(WidgetRef ref) async {
  await ref.read(gameControllerProvider.notifier).resetAll();
  // A new child: How to Play from its first page, after their detective.
  await ref.read(howToPlaySeenProvider.notifier).forget();
  return ref.read(profileStoreProvider).wipeLegacy();
}
