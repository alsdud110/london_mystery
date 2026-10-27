import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/answer_checker.dart';
import '../../data/mock/season_catalog.dart';
import '../../data/models/detective_name.dart';
import '../../data/models/difficulty.dart';
import '../../data/models/episode.dart';
import '../../data/models/game_progress.dart';
import '../../data/models/mission.dart';
import '../../data/models/profile.dart';
import '../../data/models/wallet.dart';
import 'game_providers.dart';
import 'scoring.dart';
import 'wallet_controller.dart';

/// Result of submitting an answer.
enum SubmitResult { correct, tryAgain, locked }

class SubmitOutcome {
  const SubmitOutcome(this.result, {this.newBadges = const [], this.coins = 0, this.firstSolve = true});

  final SubmitResult result;

  /// Badges earned by this answer (shown in the success celebration).
  final List<GameBadge> newBadges;

  /// Coins this answer paid (0 for a mission paid before).
  final int coins;

  /// False when the mission was solved (and rewarded) before, in an earlier
  /// run of the case: nothing new is earned, so nothing new is announced.
  final bool firstSolve;
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

  /// Plays another season: its own open case file and records load, and the
  /// season left keeps everything (its record, its case saves). Refused
  /// (false) while the season cannot be entered: locked, or no cases yet.
  /// Profile, coins and badges are the detective's, in every season.
  bool openSeason(String seasonId) {
    if (seasonId == ref.read(selectedSeasonIdProvider)) return true;
    if (!(ref.read(seasonAvailabilityProvider(seasonId))?.canEnter ?? false)) return false;
    final repo = ref.read(progressRepositoryProvider);
    return repo.transaction(() {
      _update(state); // bank the play time of the case being left
      // The case that season opens on (its open case file, or its Case 01)
      // takes the detective's name, as a case file opened does.
      final cases = SeasonAvailability.casesOf(seasonId, ref.read(allEpisodesProvider));
      final open = repo.loadSeason(seasonId).activeEpisodeId;
      final target = cases.any((e) => e.id == open) ? open : cases.first.id;
      final saved = repo.load(target);
      final name = state.detectiveName ?? sessionProfile(ref).detectiveName;
      if (name != null && saved.detectiveName != name) repo.save(saved.copyWith(detectiveName: name), target);
      ref.read(recentUnlockProvider.notifier).set(null);
      // Rebuilds the season record and this controller with that season's case.
      return ref.read(selectedSeasonIdProvider.notifier).select(seasonId);
    });
  }

  /// The app went to the background (or is closing): stop and save the clock.
  void pausePlayClock() {
    if (_activeSince == null) return;
    _update(state);
    _activeSince = null;
  }

  /// The app is in the foreground again: the clock continues from here.
  void resumePlayClock() => _activeSince ??= now();

  /// Creates the device's detective: [rawName], [avatar] and the level its
  /// seasons start at ([difficulty]). Returns an error message (kid-friendly)
  /// or null on success. There is only ever one detective: refused while one
  /// exists (NEW ADVENTURE empties the slot first).
  String? createDetective(String rawName, DetectiveAvatar? avatar, {Difficulty difficulty = Difficulty.standard}) {
    if (state.hasDetective || sessionProfile(ref).isCreated) return 'You already have a detective.';
    if (avatar == null) return 'Choose your detective first.';
    final error = validateName(rawName);
    if (error != null) return error;
    final name = cleanName(rawName);
    _update(state.copyWith(detectiveName: name));
    ref
        .read(detectiveProfileProvider.notifier)
        .change((p) => p.copyWith(detectiveName: name, avatar: avatar, createdAt: now(), difficulty: difficulty));
    return null;
  }

  /// A new name for the detective. Everything played stays: every case save
  /// keeps its progress and takes the new name, saved together. Returns an
  /// error message or null on success.
  String? renameDetective(String rawName) {
    if (!state.hasDetective) return 'Create your detective first.';
    final error = validateName(rawName);
    if (error != null) return error;
    final name = cleanName(rawName);
    final repo = ref.read(progressRepositoryProvider);
    repo.transaction(() {
      // Every season's saves take the name, not only those of the season played.
      for (final e in ref.read(allEpisodesProvider)) {
        if (e.id == _episodeId) continue;
        final saved = repo.load(e.id);
        if (saved.hasDetective && saved.detectiveName != name) repo.save(saved.copyWith(detectiveName: name), e.id);
      }
      _update(state.copyWith(detectiveName: name));
    });
    ref.read(detectiveProfileProvider.notifier).change((p) => p.copyWith(detectiveName: name));
    return null;
  }

  /// The name as the game writes it: [DetectiveName.normalize]d, with the
  /// letters exactly as typed (Lee stays Lee, MIN stays MIN).
  static String cleanName(String raw) => DetectiveName.normalize(raw);

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
        final result = ref.read(walletProvider.notifier).unlockTip(mission, tip);
        if (result != TipUnlock.insufficientCoins) useHint(mission);
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

  /// The detective looked at [key] (`missionId:thing`) in a mission's
  /// scene: kept, so it stays seen after a restart. Once only.
  void recordExamined(String key) {
    if (state.hasExamined(key)) return;
    _update(state.copyWith(examined: [...state.examined, key]));
  }

  /// How far mission [missionId]'s top layer is slid away (0..1), saved where
  /// the detective lets go (see [GameProgress.revealed]).
  void recordReveal(String missionId, double amount) {
    final at = amount.clamp(0.0, 1.0);
    if (state.revealedOf(missionId) == at) return;
    _update(state.copyWith(revealed: {...state.revealed, missionId: at}));
  }

  /// How mission [missionId]'s puzzle is left on its page ([state]: the
  /// puzzle's own string), saved as it changes (see
  /// [GameProgress.puzzleStates]).
  void recordPuzzleState(String missionId, String state) {
    if (this.state.puzzleStateOf(missionId) == state) return;
    _update(this.state.copyWith(puzzleStates: {...this.state.puzzleStates, missionId: state}));
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

    // Paid before the solve is saved: a wallet made right now (a save from
    // before coins) then pays it as this solve, not as an old one. A mission
    // pays once ever: solving it again (Play again) pays nothing.
    final firstSolve = !ref.read(walletProvider).has(Wallet.missionKey(mission.id));
    final coins = ref.read(walletProvider.notifier).rewardMission(mission);
    final solvedAt = now();
    final seconds = _solveSeconds(mission.id, solvedAt);
    // A final closes its case with its answer, unless a last step comes
    // after it (Paris Case 08's last drawing): then [closeCase] does.
    final closes = mission.isFinal && !SeasonCatalog.closesAfterLastStep(mission);
    var next = state.copyWith(
      attempts: attempts,
      completedMissionIds: [...state.completedMissionIds, mission.id],
      solveSeconds: seconds == null ? null : {...state.solveSeconds, mission.id: seconds},
      // The XP rule this answer is scored under, kept with it for good.
      xpRules: {...state.xpRules, mission.id: XpBreakdown.currentRule},
      completedAt: closes ? solvedAt : null,
    );

    final newBadges = _earnedBadges(episode, next);
    if (newBadges.isNotEmpty) {
      next = next.copyWith(badgeIds: [...next.badgeIds, for (final b in newBadges) b.name]);
    }
    _update(next);
    if (closes) _markCaseSolved(episode.id);

    if (mission.nextMissionId != null) {
      ref.read(recentUnlockProvider.notifier).set(mission.nextMissionId);
    }
    return SubmitOutcome(SubmitResult.correct, newBadges: newBadges, coins: coins, firstSolve: firstSolve);
  }

  /// Closes the case whose final was answered but waited for its last step
  /// ([GameProgress.finalAwaitsLastStep]; Paris Case 08's last drawing), once
  /// that step is done ([stepKey] kept with it): the case is solved, its
  /// badges are earned and the next case file opens, together. Nothing for
  /// a case not waiting (its final not answered, or already closed). True
  /// when it was closed now.
  bool closeCase(String stepKey) => ref.read(progressRepositoryProvider).transaction(() {
        final episode = ref.read(currentEpisodeProvider);
        // The step is done only after the final's answer (a case closed by
        // an earlier build keeps it too, and stays as it was).
        if (!state.isCompleted(episode.finalMission.id)) return false;
        if (!state.hasExamined(stepKey)) _update(state.copyWith(examined: [...state.examined, stepKey]));
        if (!state.finalAwaitsLastStep(episode)) return false;
        var next = state.copyWith(completedAt: now());
        final newBadges = _earnedBadges(episode, next);
        if (newBadges.isNotEmpty) {
          next = next.copyWith(badgeIds: [...next.badgeIds, for (final b in newBadges) b.name]);
        }
        _update(next);
        _markCaseSolved(episode.id);
        return true;
      });

  List<GameBadge> _earnedBadges(Episode episode, GameProgress next) => [
        for (final b in GameBadge.forEpisode(episode))
          if (!next.badgeIds.contains(b.name) && b.isEarned(episode, next)) b,
      ];

  /// The case is solved: the next case file opens (and stays open, even if
  /// this case is replayed).
  void _markCaseSolved(String episodeId) {
    // A first solve is news for the season board; a replay is not.
    if (!ref.read(seasonProvider).isSolved(episodeId)) ref.read(recentSolveProvider.notifier).add(episodeId);
    ref.read(seasonProvider.notifier).markSolved(episodeId);
  }

  /// Clears the case but keeps the detective name.
  void playAgain() {
    ref.read(recentUnlockProvider.notifier).set(null);
    _update(state.resetCase());
  }

  /// NEW ADVENTURE: the same detective (id, name, picture) starts the game
  /// over. Every case, the season, XP, badges and coins start again as for
  /// a new player (a new wallet with the start coins). The saves made before
  /// profiles stay (only the game master's reset removes those).
  Future<void> newAdventure() async {
    final name = state.detectiveName ?? sessionProfile(ref).detectiveName;
    _wipe(keepName: name);
    // Nothing is paid back any more: the coins start with this wallet.
    await ref
        .read(detectiveProfileProvider.notifier)
        .change((p) => p.copyWith(walletBackfill: WalletBackfill.never));
  }

  /// The game master's reset for the next player: the game starts over and
  /// the detective's slot is emptied (no name, no picture; the id stays), so
  /// the next child creates their own detective.
  Future<void> resetAll() async {
    _wipe();
    await ref.read(detectiveProfileProvider.notifier).change((p) => p.startedOver());
  }

  /// Wipes every save of the detective (and plays nothing back), keeping
  /// [keepName] on the first case when given.
  void _wipe({String? keepName}) {
    ref.read(recentUnlockProvider.notifier).set(null);
    ref.read(recentSolveProvider.notifier).clear();
    final fresh = GameProgress(detectiveName: keepName);
    // The wipe, the new wallet and the name kept are saved together.
    final repo = ref.read(progressRepositoryProvider);
    repo.transaction(() {
      repo.clear();
      ref.read(walletProvider.notifier).startFresh();
      if (keepName != null) repo.save(fresh, AppConstants.currentEpisodeId);
    });
    state = fresh;
    ref.read(selectedSeasonIdProvider.notifier).reset(); // back to Season 1
    ref.read(seasonProvider.notifier).reset(); // back to Case 01
  }
}

final gameControllerProvider = NotifierProvider<GameController, GameProgress>(GameController.new);
