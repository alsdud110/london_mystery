import 'package:flutter/foundation.dart';

import 'episode.dart';
import 'mission.dart';

/// Everything about one player's run that must survive an app restart.
@immutable
class GameProgress {
  const GameProgress({
    this.detectiveName,
    this.introSeen = false,
    this.completedMissionIds = const [],
    this.attempts = const {},
    this.wrongAnswers = const {},
    this.hintsUsed = const {},
    this.missionStartedAt = const {},
    this.missionStartPlayMillis = const {},
    this.solveSeconds = const {},
    this.badgeIds = const [],
    this.lookedUpWords = const [],
    this.lookupsRecorded = true,
    this.xpRules = const {},
    this.behavior = BehaviorLog.empty,
    this.examined = const [],
    this.revealed = const {},
    this.puzzleStates = const {},
    this.startedAt,
    this.completedAt,
    this.playMillis,
  });

  final String? detectiveName;
  final bool introSeen;

  /// Solved mission ids in the order they were solved (includes the final).
  final List<String> completedMissionIds;

  /// Total answer submissions per mission.
  final Map<String, int> attempts;
  final Map<String, int> wrongAnswers;

  /// How many hints (0..2) were opened per mission.
  final Map<String, int> hintsUsed;

  /// When the player first opened each mission (wall clock; marks it as opened).
  final Map<String, DateTime> missionStartedAt;

  /// Play time ([playMillis]) at the moment each mission was first opened,
  /// so the speed bonus only counts time actually spent playing.
  final Map<String, int> missionStartPlayMillis;

  /// Seconds of play from opening to solving, per solved mission.
  final Map<String, int> solveSeconds;

  /// Earned badge ids, in the order they were earned.
  final List<String> badgeIds;

  /// Words the player tapped to see the meaning (unique, lower-case).
  final List<String> lookedUpWords;

  /// False for a save made before looked-up words were recorded: an empty
  /// [lookedUpWords] then means "no record", not "no words". Words looked up
  /// later are still added.
  final bool lookupsRecorded;

  /// The XP rule each mission was solved under (see `XpBreakdown`), recorded
  /// at the moment of the answer. A solved mission without an entry was
  /// solved before rules were recorded and keeps the first rule, so a change
  /// of rules never changes XP already earned.
  final Map<String, int> xpRules;

  /// Detective actions recorded during this run of the case (see
  /// [BehaviorLog]). Null for a save made before actions were recorded: its
  /// past actions are unknown, so nothing is inferred from it and no action
  /// badge can be earned in that run (a new run, e.g. Play again, records).
  final BehaviorLog? behavior;

  /// Whether this run records detective actions.
  bool get recordsBehavior => behavior != null;

  /// What the detective has looked at in a mission's scene, so it stays
  /// seen after a restart: `missionId:thing` (Paris Case 01: its clocks and
  /// departure board, the lost ticket, the painting's back). Never XP.
  final List<String> examined;

  bool hasExamined(String key) => examined.contains(key);

  /// The [examined] key of [thing] looked at in mission [missionId].
  static String examinedKey(String missionId, String thing) => '$missionId:$thing';

  /// How far a painted-over picture's top layer is slid away, by mission id
  /// (0: covered, 1: all slid away), so it stays where it was left after a
  /// restart. Kept apart from the marks found underneath ([examined]):
  /// sliding the paint away finds nothing by itself. Never XP.
  final Map<String, double> revealed;

  /// How far mission [missionId]'s top layer is slid away (0 when never).
  double revealedOf(String missionId) => revealed[missionId] ?? 0;

  /// How a puzzle was left on its page, by mission id, so it is as it was
  /// after a restart (Paris Case 03: the padlock's dials, the evidence
  /// linked on the final's board). The puzzle reads its own string; an
  /// unknown one starts the puzzle afresh. Never XP.
  final Map<String, String> puzzleStates;

  /// How mission [missionId]'s puzzle was left, or null when never touched.
  String? puzzleStateOf(String missionId) => puzzleStates[missionId];

  final DateTime? startedAt;
  final DateTime? completedAt;

  /// Case play time in milliseconds, counted only while the app is in the
  /// foreground (see `GameController`). Null for saves made before play time
  /// was tracked; those fall back to the wall-clock span.
  final int? playMillis;

  static const empty = GameProgress();

  bool get hasDetective => detectiveName != null && detectiveName!.isNotEmpty;
  bool get isCaseSolved => completedAt != null;

  /// Total hints opened across the case.
  int get totalHints => hintsUsed.values.fold(0, (a, b) => a + b);

  int hintsFor(String missionId) => hintsUsed[missionId] ?? 0;

  bool usedHint(String missionId) => hintsFor(missionId) > 0;

  bool isCompleted(String missionId) => completedMissionIds.contains(missionId);

  int wrongCount(String missionId) => wrongAnswers[missionId] ?? 0;

  int completedCount(Episode episode) => episode.missions.where((m) => isCompleted(m.id)).length;

  bool allMissionsDone(Episode episode) => episode.missions.every((m) => isCompleted(m.id));

  /// The mission the player should play next (null once the case is solved).
  /// A final answered whose case is not closed yet (a step after its answer
  /// still to do: Paris Case 08's last drawing) is still the one to play.
  Mission? currentMission(Episode episode) {
    for (final m in episode.missions) {
      if (!isCompleted(m.id)) return m;
    }
    return isCompleted(episode.finalMission.id) && isCaseSolved ? null : episode.finalMission;
  }

  /// The final is answered but the case is not closed: its last step (after
  /// the answer) is still to do.
  bool finalAwaitsLastStep(Episode episode) => isCompleted(episode.finalMission.id) && !isCaseSolved;

  /// A mission is playable once every mission before it is solved.
  bool isUnlocked(Episode episode, String missionId) {
    if (isCompleted(missionId)) return true;
    return currentMission(episode)?.id == missionId;
  }

  /// Clues in the order they were discovered.
  List<Clue> collectedClues(Episode episode) => [
        for (final id in completedMissionIds) ?episode.missionById(id)?.clue,
      ];

  /// Evidence in the order it was found.
  List<Evidence> collectedEvidence(Episode episode) => [
        for (final id in completedMissionIds) ?episode.missionById(id)?.evidence,
      ];

  /// Saved play time of the case. The live value, including the stretch the
  /// app has been open since the last save, is `GameController.playTime`.
  Duration? elapsed({DateTime? now}) {
    final start = startedAt;
    if (start == null) return null;
    final played = playMillis;
    if (played != null) return Duration(milliseconds: played);
    // Saves from before play time was tracked: the old wall-clock span.
    final end = completedAt ?? now ?? DateTime.now();
    final d = end.difference(start);
    return d.isNegative ? Duration.zero : d;
  }

  GameProgress copyWith({
    String? detectiveName,
    bool? introSeen,
    List<String>? completedMissionIds,
    Map<String, int>? attempts,
    Map<String, int>? wrongAnswers,
    Map<String, int>? hintsUsed,
    Map<String, DateTime>? missionStartedAt,
    Map<String, int>? missionStartPlayMillis,
    Map<String, int>? solveSeconds,
    List<String>? badgeIds,
    List<String>? lookedUpWords,
    bool? lookupsRecorded,
    Map<String, int>? xpRules,
    BehaviorLog? behavior,
    List<String>? examined,
    Map<String, double>? revealed,
    Map<String, String>? puzzleStates,
    DateTime? startedAt,
    DateTime? completedAt,
    int? playMillis,
  }) {
    return GameProgress(
      detectiveName: detectiveName ?? this.detectiveName,
      introSeen: introSeen ?? this.introSeen,
      completedMissionIds: completedMissionIds ?? this.completedMissionIds,
      attempts: attempts ?? this.attempts,
      wrongAnswers: wrongAnswers ?? this.wrongAnswers,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      missionStartedAt: missionStartedAt ?? this.missionStartedAt,
      missionStartPlayMillis: missionStartPlayMillis ?? this.missionStartPlayMillis,
      solveSeconds: solveSeconds ?? this.solveSeconds,
      badgeIds: badgeIds ?? this.badgeIds,
      lookedUpWords: lookedUpWords ?? this.lookedUpWords,
      lookupsRecorded: lookupsRecorded ?? this.lookupsRecorded,
      xpRules: xpRules ?? this.xpRules,
      behavior: behavior ?? this.behavior,
      examined: examined ?? this.examined,
      revealed: revealed ?? this.revealed,
      puzzleStates: puzzleStates ?? this.puzzleStates,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      playMillis: playMillis ?? this.playMillis,
    );
  }

  /// Keeps the detective, clears the case (used for "play again").
  GameProgress resetCase() => GameProgress(detectiveName: detectiveName);

  /// Tolerant decoding: unknown or malformed fields fall back to defaults.
  factory GameProgress.fromJson(Map<String, dynamic> json) {
    Map<String, int> intMap(Object? raw) => raw is Map
        ? {
            for (final e in raw.entries)
              if (e.value is num) e.key.toString(): (e.value as num).toInt(),
          }
        : const {};
    Map<String, DateTime> dateMap(Object? raw) => raw is Map
        ? {
            for (final e in raw.entries)
              if (e.value is String && DateTime.tryParse(e.value as String) != null)
                e.key.toString(): DateTime.parse(e.value as String),
          }
        : const {};
    List<String> strList(Object? raw) => raw is List ? raw.whereType<String>().toList() : const [];
    DateTime? date(Object? raw) => raw is String ? DateTime.tryParse(raw) : null;
    final name = json['detectiveName'];

    // v1 saves stored a list of missions where "the" hint was opened.
    final hints = json.containsKey('hintsUsed')
        ? intMap(json['hintsUsed'])
        : {for (final id in strList(json['hintMissionIds'])) id: 1};

    // Saves from before play time was tracked have no playMillis. A solved
    // case keeps its old wall-clock result; a case still in progress starts
    // counting from zero (the time the app was closed was never recorded, so
    // it cannot be separated out).
    final startedAt = date(json['startedAt']);
    final completedAt = date(json['completedAt']);
    final rawPlay = json['playMillis'];
    final playMillis = rawPlay is num
        ? rawPlay.toInt().clamp(0, 1 << 52)
        : (startedAt != null && completedAt == null ? 0 : null);

    return GameProgress(
      detectiveName: name is String ? name : null,
      introSeen: json['introSeen'] == true,
      completedMissionIds: strList(json['completedMissionIds']),
      attempts: intMap(json['attempts']),
      wrongAnswers: intMap(json['wrongAnswers']),
      hintsUsed: hints,
      missionStartedAt: dateMap(json['missionStartedAt']),
      missionStartPlayMillis: intMap(json['missionStartPlayMillis']),
      solveSeconds: intMap(json['solveSeconds']),
      badgeIds: strList(json['badgeIds']),
      lookedUpWords: strList(json['lookedUpWords']),
      // Saves that never had the list cannot say which words were looked up.
      lookupsRecorded: json['lookupsRecorded'] is bool
          ? json['lookupsRecorded'] as bool
          : json.containsKey('lookedUpWords'),
      xpRules: intMap(json['xpRules']),
      behavior: json['behavior'] is Map ? BehaviorLog.fromJson(json['behavior'] as Map) : null,
      examined: strList(json['examined']),
      revealed: json['revealed'] is Map
          ? {
              for (final e in (json['revealed'] as Map).entries)
                if (e.value is num && (e.value as num).isFinite)
                  e.key.toString(): (e.value as num).toDouble().clamp(0.0, 1.0),
            }
          : const {},
      puzzleStates: json['puzzleStates'] is Map
          ? {
              for (final e in (json['puzzleStates'] as Map).entries)
                if (e.value is String) e.key.toString(): e.value as String,
            }
          : const {},
      startedAt: startedAt,
      completedAt: completedAt,
      playMillis: playMillis,
    );
  }

  Map<String, dynamic> toJson() => {
        'detectiveName': detectiveName,
        'introSeen': introSeen,
        'completedMissionIds': completedMissionIds,
        'attempts': attempts,
        'wrongAnswers': wrongAnswers,
        'hintsUsed': hintsUsed,
        'missionStartedAt': {for (final e in missionStartedAt.entries) e.key: e.value.toIso8601String()},
        'missionStartPlayMillis': missionStartPlayMillis,
        'solveSeconds': solveSeconds,
        'badgeIds': badgeIds,
        'lookedUpWords': lookedUpWords,
        if (!lookupsRecorded) 'lookupsRecorded': false,
        if (xpRules.isNotEmpty) 'xpRules': xpRules,
        // Written whenever actions are recorded: an absent key means "not recorded".
        if (behavior != null) 'behavior': behavior!.toJson(),
        if (examined.isNotEmpty) 'examined': examined,
        if (revealed.isNotEmpty) 'revealed': revealed,
        if (puzzleStates.isNotEmpty) 'puzzleStates': puzzleStates,
        'startedAt': startedAt?.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        if (playMillis != null) 'playMillis': playMillis,
      };
}

/// Detective actions of one run of a case, each recorded by a real UI event
/// (never inferred). They can earn optional action badges, never XP.
@immutable
class BehaviorLog {
  const BehaviorLog({this.rechecked = const [], this.evidenceViewed = const [], this.words = const []});

  static const empty = BehaviorLog();

  /// Missions where, after a wrong answer and before solving, the detective
  /// re-read the letter or opened a piece of evidence (Second Look).
  final List<String> rechecked;

  /// Evidence opened for a closer look from the notebook, the Case Archive or
  /// the final case's notebook while the case was unsolved (Notebook Explorer).
  final List<String> evidenceViewed;

  /// Distinct words whose meaning was looked up in this run (Word Collector).
  final List<String> words;

  BehaviorLog copyWith({List<String>? rechecked, List<String>? evidenceViewed, List<String>? words}) => BehaviorLog(
        rechecked: rechecked ?? this.rechecked,
        evidenceViewed: evidenceViewed ?? this.evidenceViewed,
        words: words ?? this.words,
      );

  /// Tolerant decoding: unknown or malformed entries are dropped.
  factory BehaviorLog.fromJson(Map<dynamic, dynamic> json) {
    List<String> strList(Object? raw) => raw is List ? raw.whereType<String>().toList() : const [];
    return BehaviorLog(
      rechecked: strList(json['rechecked']),
      evidenceViewed: strList(json['evidenceViewed']),
      words: strList(json['words']),
    );
  }

  Map<String, dynamic> toJson() => {'rechecked': rechecked, 'evidenceViewed': evidenceViewed, 'words': words};
}
