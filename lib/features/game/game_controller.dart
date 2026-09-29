import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/answer_checker.dart';
import '../../data/models/game_progress.dart';
import '../../data/models/mission.dart';
import 'game_providers.dart';
import 'scoring.dart';

/// Result of submitting an answer.
enum SubmitResult { correct, tryAgain, locked }

class SubmitOutcome {
  const SubmitOutcome(this.result, {this.newBadges = const []});

  final SubmitResult result;

  /// Badges earned by this answer (shown in the success celebration).
  final List<GameBadge> newBadges;
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
    state = next;
    ref.read(progressRepositoryProvider).save(next, _episodeId);
  }

  /// Opens another case file. Refused (false) while the case is still sealed:
  /// the check lives here, not only in the case files UI. The detective
  /// keeps their name; each case keeps its own clues, XP and badges.
  bool openEpisode(String episodeId) {
    final season = ref.read(seasonProvider.notifier);
    if (!season.isUnlocked(episodeId)) return false;
    if (episodeId == _episodeId) return true;

    _update(state); // bank the play time of the case being left
    final repo = ref.read(progressRepositoryProvider);
    final target = repo.load(episodeId);
    final name = state.detectiveName;
    if (name != null && target.detectiveName != name) {
      repo.save(target.copyWith(detectiveName: name), episodeId);
    }
    ref.read(recentUnlockProvider.notifier).set(null);
    season.open(episodeId); // rebuilds this controller with the new case
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
    _update(state.copyWith(detectiveName: cleanName(rawName)));
    return null;
  }

  static final _allowedName = RegExp(r'^[A-Za-z0-9가-힣 .\-]+$');

  static String cleanName(String raw) => raw.trim().replaceAll(RegExp(r'\s+'), ' ').toUpperCase();

  static String? validateName(String? raw) {
    final name = cleanName(raw ?? '');
    if (name.length < AppConstants.nameMinLength) return 'Please type your detective name.';
    if (name.length > AppConstants.nameMaxLength) {
      return 'Use ${AppConstants.nameMaxLength} letters or fewer.';
    }
    if (!_allowedName.hasMatch(name)) return 'Use letters and numbers only.';
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
    if (state.lookedUpWords.contains(w)) return;
    _update(state.copyWith(lookedUpWords: [...state.lookedUpWords, w]));
  }

  /// Checks [answer], records the attempt, and on success completes the
  /// mission (unlocking the next one) and awards badges.
  SubmitOutcome submitAnswer(Mission mission, String answer) {
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

    final solvedAt = now();
    final seconds = _solveSeconds(mission.id, solvedAt);
    var next = state.copyWith(
      attempts: attempts,
      completedMissionIds: [...state.completedMissionIds, mission.id],
      solveSeconds: seconds == null ? null : {...state.solveSeconds, mission.id: seconds},
      completedAt: mission.isFinal ? solvedAt : null,
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
    if (mission.isFinal) ref.read(seasonProvider.notifier).markSolved(episode.id);

    if (mission.nextMissionId != null) {
      ref.read(recentUnlockProvider.notifier).set(mission.nextMissionId);
    }
    return SubmitOutcome(SubmitResult.correct, newBadges: newBadges);
  }

  /// Clears the case but keeps the detective name.
  void playAgain() {
    ref.read(recentUnlockProvider.notifier).set(null);
    _update(state.resetCase());
  }

  /// Wipes everything — every case and the season — including the name.
  Future<void> resetAll() async {
    ref.read(recentUnlockProvider.notifier).set(null);
    state = GameProgress.empty;
    await ref.read(progressRepositoryProvider).clear();
    ref.read(seasonProvider.notifier).reset(); // back to Case 01
  }
}

final gameControllerProvider = NotifierProvider<GameController, GameProgress>(GameController.new);
