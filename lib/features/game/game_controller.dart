import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/answer_checker.dart';
import '../../data/models/detective_name.dart';
import '../../data/models/game_progress.dart';
import '../../data/models/mission.dart';
import '../../data/models/profile.dart';
import '../../data/sync/merge.dart';
import 'game_providers.dart';
import 'scoring.dart';
import 'wallet_controller.dart';

/// Result of submitting an answer.
enum SubmitResult { correct, tryAgain, locked }

class SubmitOutcome {
  const SubmitOutcome(this.result, {this.newBadges = const [], this.coins = 0});

  final SubmitResult result;

  /// Badges earned by this answer (shown in the success celebration).
  final List<GameBadge> newBadges;

  /// Coins this answer paid (0 for a mission paid before).
  final int coins;
}

/// Owns the player's run. Every change is persisted immediately so the game
/// can be resumed after the app is closed.
class GameController extends Notifier<GameProgress> {
  /// Clock injection point for tests.
  static DateTime Function() now = DateTime.now;

  /// Start of the current foreground stretch; null while the app is in the
  /// background. Kept in memory only: time the app spends closed or in the
  /// background is never added to the play time.
  DateTime? _activeSince;

  /// The case this run belongs to (the open case file).
  late String _episodeId;

  @override
  GameProgress build() {
    // Rebuilt when another case file is opened: that case's own save loads.
    _episodeId = ref.watch(seasonProvider.select((s) => s.activeEpisodeId));
    _activeSince = now(); // the app is starting, so it is in the foreground
    return ref.read(progressRepositoryProvider).load(_episodeId);
  }

  /// The saves changed under the game (a cloud merge): the open case is
  /// read again if [episodeId] is it (null: whichever is open). The play
  /// clock carries on; what is typed on a page is not part of the save and
  /// stays. Returns whether the case differed.
  bool reloadFromSaves([String? episodeId]) {
    if (episodeId != null && episodeId != _episodeId) return false;
    final saved = ref.read(progressRepositoryProvider).load(_episodeId);
    if (jsonEncode(saved.toJson()) == jsonEncode(state.toJson())) return false;
    state = saved;
    return true;
  }

  /// The case clock runs from the story intro until the case is solved.
  static bool _clockRunning(GameProgress p) => p.startedAt != null && !p.isCaseSolved;

  int _stretchMillis(DateTime at) {
    final since = _activeSince;
    if (since == null || !_clockRunning(state)) return 0;
    final ms = at.difference(since).inMilliseconds;
    return ms < 0 ? 0 : ms;
  }

  /// Live play time of the case: the saved total plus the current stretch.
  Duration get playTime => Duration(milliseconds: (state.playMillis ?? 0) + _stretchMillis(now()));

  void _update(GameProgress next) {
    // Bank the current foreground stretch with every save, so a restart loses
    // at most the time since the last action. It only belongs to the same run:
    // not to a case that is just starting or being reset.
    final at = now();
    final stretch = _stretchMillis(at);
    if (stretch > 0 && next.startedAt == state.startedAt) {
      next = next.copyWith(playMillis: (next.playMillis ?? 0) + stretch);
    }
    if (_activeSince != null) _activeSince = at;
    // Played in a case only operator access opened: the run is operator data.
    if (!next.playtest && !isBlankRun(next) && openedOnlyByOperator(ref, _episodeId)) {
      next = next.copyWith(playtest: true);
    }
    next = _stamped(next);
    state = next;
    ref.read(progressRepositoryProvider).save(next, _episodeId);
  }

  /// [next] with its run recorded. A new run (Play again) keeps what it was
  /// given. Otherwise only a real change counts: it gets the save a run if
  /// it has none (a save from before runs), or one more revision. A save
  /// with nothing changed stays exactly as it was.
  GameProgress _stamped(GameProgress next) {
    if (next.runId != null && next.runId != state.runId) return next;
    final changed = jsonEncode(next.copyWith(rev: state.rev).toJson()) != jsonEncode(state.toJson());
    if (!changed) return next.copyWith(rev: state.rev);
    return next.runId == null ? next.copyWith(runId: newRunId(), rev: 0) : next.copyWith(rev: state.rev + 1);
  }

  static final _random = Random.secure();

  /// A new run id (16 hex digits).
  static String newRunId() =>
      [for (var i = 0; i < 8; i++) _random.nextInt(256).toRadixString(16).padLeft(2, '0')].join();

  /// Opens another case file. Refused (false) while the case is still sealed:
  /// the check lives here, not only in the case files UI. The detective
  /// keeps their name; each case keeps its own clues, XP and badges.
  bool openEpisode(String episodeId) {
    final season = ref.read(seasonProvider.notifier);
    if (!season.isUnlocked(episodeId)) return false;
    if (episodeId == _episodeId) return true;

    final repo = ref.read(progressRepositoryProvider);
    repo.transaction(() {
      _update(state); // bank the play time of the case being left
      final target = repo.load(episodeId);
      final name = state.detectiveName;
      if (name != null && target.detectiveName != name) {
        repo.save(target.copyWith(detectiveName: name), episodeId);
      }
      ref.read(recentUnlockProvider.notifier).set(null);
      season.open(episodeId); // rebuilds this controller with the new case
    });
    return true;
  }

  /// The app went to the background (or is closing): stop and save the clock.
  void pausePlayClock() {
    if (_activeSince == null) return;
    _update(state);
    _activeSince = null;
  }

  /// The app is in the foreground again: the clock continues from here.
  void resumePlayClock() => _activeSince ??= now();

  /// Validates and stores the detective name. Returns an error message
  /// (kid-friendly) or null on success.
  String? registerDetective(String rawName) {
    final error = validateName(rawName);
    if (error != null) return error;
    final name = cleanName(rawName);
    _update(state.copyWith(detectiveName: name));
    // The profile shows the same name (the game reads the case save's).
    ref
        .read(profileStoreProvider)
        .update(ref.read(profileSessionProvider).profileId, (p) => p.copyWith(detectiveName: name));
    return null;
  }

  /// The name as the game writes it: [DetectiveName.normalize]d, in capitals.
  static String cleanName(String raw) => DetectiveName.normalize(raw).toUpperCase();

  static String? validateName(String? raw) {
    final name = cleanName(raw ?? '');
    if (name.length < AppConstants.nameMinLength) return 'Please type your detective name.';
    if (name.length > AppConstants.nameMaxLength) {
      return 'Use ${AppConstants.nameMaxLength} letters or fewer.';
    }
    if (!DetectiveName.isValid(name)) return 'Use letters and numbers only.';
    return null;
  }

  /// Called when the story intro finishes. Starts the case clock once.
  void startInvestigation() {
    _update(state.copyWith(
      introSeen: true,
      startedAt: state.startedAt ?? now(),
      playMillis: state.playMillis ?? 0,
    ));
  }

  /// Starts the per-mission timer the first time a mission is opened.
  void markMissionStarted(String missionId) {
    if (state.isCompleted(missionId) || state.missionStartedAt.containsKey(missionId)) return;
    _update(state.copyWith(
      missionStartedAt: {...state.missionStartedAt, missionId: now()},
      missionStartPlayMillis: {...state.missionStartPlayMillis, missionId: playTime.inMilliseconds},
    ));
  }

  /// Seconds of play between opening [missionId] and now, or null if unknown.
  int? _solveSeconds(String missionId, DateTime solvedAt) {
    final startPlay = state.missionStartPlayMillis[missionId];
    if (startPlay != null) {
      final ms = playTime.inMilliseconds - startPlay;
      return (ms < 0 ? 0 : ms) ~/ 1000;
    }
    // Mission opened before play time was tracked: the old wall-clock span.
    final started = state.missionStartedAt[missionId];
    return started == null ? null : solvedAt.difference(started).inSeconds.abs();
  }

  /// Reveals tip [tip] (1 or 2) of [mission]: makes it the detective's (see
  /// [WalletController.unlockTip]) and opens it on the page, saved together.
  TipUnlock revealTip(Mission mission, int tip) => ref.read(progressRepositoryProvider).transaction(() {
        final playtest = state.playtest || openedOnlyByOperator(ref, _episodeId);
        final result = ref.read(walletProvider.notifier).unlockTip(mission, tip, playtest: playtest);
        useHint(mission);
        return result;
      });

  /// Opens the next hint for [mission] (at most its number of hints).
  /// Returns how many hints are now visible.
  int useHint(Mission mission) {
    final current = state.hintsFor(mission.id);
    final max = mission.hints.length.clamp(0, AppConstants.maxHints);
    if (current >= max || state.isCompleted(mission.id)) return current;
    _update(state.copyWith(hintsUsed: {...state.hintsUsed, mission.id: current + 1}));
    return current + 1;
  }

  /// Records a tapped glossary word (for the parent report).
  void lookUpWord(String word) {
    final w = word.toLowerCase();
    final log = state.behavior;
    final newForLog = log != null && !log.words.contains(w);
    if (state.lookedUpWords.contains(w) && !newForLog) return;
    _update(state.copyWith(
      lookedUpWords: state.lookedUpWords.contains(w) ? null : [...state.lookedUpWords, w],
      behavior: newForLog ? log.copyWith(words: [...log.words, w]) : null,
    ));
  }

  /// The detective re-read [mission]'s letter. Recorded for Second Look only
  /// after a wrong answer and before the mission is solved.
  void recordRecheck(Mission mission) {
    final log = state.behavior;
    if (log == null || state.isCompleted(mission.id) || state.wrongCount(mission.id) == 0) return;
    if (log.rechecked.contains(mission.id)) return;
    _update(state.copyWith(behavior: log.copyWith(rechecked: [...log.rechecked, mission.id])));
  }

  /// The detective opened [evidenceId] for a closer look from the notebook,
  /// the Case Archive or the final case's notebook. While the case is being
  /// solved it counts for Notebook Explorer, and as a recheck of the mission
  /// being played if that mission already had a wrong answer.
  void recordEvidenceViewed(String evidenceId) {
    final log = state.behavior;
    if (log == null || state.isCaseSolved) return;
    final current = state.currentMission(ref.read(currentEpisodeProvider));
    final recheck = current != null && state.wrongCount(current.id) > 0 && !log.rechecked.contains(current.id);
    final viewed = !log.evidenceViewed.contains(evidenceId);
    if (!recheck && !viewed) return;
    _update(state.copyWith(
      behavior: log.copyWith(
        rechecked: recheck ? [...log.rechecked, current.id] : null,
        evidenceViewed: viewed ? [...log.evidenceViewed, evidenceId] : null,
      ),
    ));
  }

  /// Checks [answer], records the attempt, and on success completes the
  /// mission (unlocking the next one) and awards badges. The solve, its
  /// coins and the season record are saved together.
  SubmitOutcome submitAnswer(Mission mission, String answer) =>
      ref.read(progressRepositoryProvider).transaction(() => _submitAnswer(mission, answer));

  SubmitOutcome _submitAnswer(Mission mission, String answer) {
    final episode = ref.read(currentEpisodeProvider);
    if (!state.isUnlocked(episode, mission.id)) return const SubmitOutcome(SubmitResult.locked);
    if (state.isCompleted(mission.id)) return const SubmitOutcome(SubmitResult.correct);

    final correct = AnswerChecker.isCorrect(mission, answer);
    final attempts = {...state.attempts, mission.id: (state.attempts[mission.id] ?? 0) + 1};

    if (!correct) {
      _update(state.copyWith(
        attempts: attempts,
        wrongAnswers: {...state.wrongAnswers, mission.id: state.wrongCount(mission.id) + 1},
      ));
      return const SubmitOutcome(SubmitResult.tryAgain);
    }

    // A solve in a case only operator access opened, or in a run the
    // operator tools set up: its run, coins and season solve are operator
    // data. A case a child could reach is normal play, switch on or off.
    final playtest = state.playtest || openedOnlyByOperator(ref, episode.id);

    // Paid before the solve is saved: a wallet made right now (a save from
    // before coins) then pays it as this solve, not as an old one.
    final coins = ref.read(walletProvider.notifier).rewardMission(mission, playtest: playtest);
    final solvedAt = now();
    final seconds = _solveSeconds(mission.id, solvedAt);
    var next = state.copyWith(
      attempts: attempts,
      completedMissionIds: [...state.completedMissionIds, mission.id],
      solveSeconds: seconds == null ? null : {...state.solveSeconds, mission.id: seconds},
      // The XP rule this answer is scored under, kept with it for good.
      xpRules: {...state.xpRules, mission.id: XpBreakdown.currentRule},
      completedAt: mission.isFinal ? solvedAt : null,
      playtest: playtest,
    );

    final newBadges = [
      for (final b in GameBadge.forEpisode(episode))
        if (!next.badgeIds.contains(b.name) && b.isEarned(episode, next)) b,
    ];
    if (newBadges.isNotEmpty) {
      next = next.copyWith(badgeIds: [...next.badgeIds, for (final b in newBadges) b.name]);
    }
    _update(next);
    // The next case file opens (and stays open, even if this case is replayed).
    if (mission.isFinal) {
      // A first solve is news for the season board; a replay is not.
      if (!ref.read(seasonProvider).isSolved(episode.id)) ref.read(recentSolveProvider.notifier).add(episode.id);
      ref.read(seasonProvider.notifier).markSolved(episode.id, playtest: playtest);
    }

    if (mission.nextMissionId != null) {
      ref.read(recentUnlockProvider.notifier).set(mission.nextMissionId);
    }
    return SubmitOutcome(SubmitResult.correct, newBadges: newBadges, coins: coins);
  }

  /// Clears the case but keeps the detective name.
  /// A new run of the case: the run before it is over for good, so it can
  /// never come back in its place.
  void playAgain() {
    ref.read(recentUnlockProvider.notifier).set(null);
    _update(state.resetCase().copyWith(runId: newRunId(), runSeq: state.runSeq + 1));
  }

  /// Wipes everything of this detective — every case and the season —
  /// including the name. Other profiles and the saves made before profiles
  /// stay (only the game master's reset removes those, see
  /// `resetForNextPlayer`).
  Future<void> resetAll() async {
    ref.read(recentUnlockProvider.notifier).set(null);
    ref.read(recentSolveProvider.notifier).clear();
    state = GameProgress.empty;
    // The wipe, the next epoch and the new wallet are saved together.
    final repo = ref.read(progressRepositoryProvider);
    repo.transaction(() {
      repo.clear();
      ref.read(walletProvider.notifier).startFresh();
    });
    ref.read(seasonProvider.notifier).reset(); // back to Case 01
    // Nothing of the profile is left, test data included.
    await ref
        .read(profileStoreProvider)
        .update(ref.read(profileSessionProvider).profileId, (p) => p.startedOver(origin: ProfileOrigin.fresh));
  }
}

final gameControllerProvider = NotifierProvider<GameController, GameProgress>(GameController.new);
