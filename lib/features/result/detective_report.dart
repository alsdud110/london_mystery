import '../../data/mock/season1/season1_learning.dart';
import '../../data/models/episode.dart';
import '../../data/models/game_progress.dart';
import '../../data/models/learning.dart';
import '../../data/models/mission.dart';
import '../game/scoring.dart';

/// What the save records about one solved mission.
class MissionPerformance {
  const MissionPerformance({
    required this.mission,
    required this.recorded,
    required this.wrongAnswers,
    required this.hints,
    required this.xp,
    this.learning,
    this.solveSeconds,
  });

  final Mission mission;

  /// False when the save has no attempt record for this solved mission (a
  /// case marked solved by the playtest tools, or a very old save): its
  /// first try, wrong answers and tips are then unknown, not zero.
  final bool recorded;
  final int wrongAnswers;
  final int hints;
  final XpBreakdown xp;

  /// What the mission is designed to do with English (content, not a result).
  final LearningObjective? learning;
  final int? solveSeconds;

  bool get firstTry => recorded && wrongAnswers == 0;
  bool get usedHint => hints > 0;
}

/// Everything shown on the Case Closed and Parent Report screens,
/// derived purely from [GameProgress] + [Episode] + the case's learning
/// design. It reports what the save recorded (play) and what the case was
/// designed to offer (learning objectives), and keeps the two apart: nothing
/// here measures a child's English.
class DetectiveReport {
  DetectiveReport._({
    required this.detectiveName,
    required this.episode,
    required this.progress,
    required this.performances,
  });

  factory DetectiveReport.from(Episode episode, GameProgress progress) => DetectiveReport._(
    detectiveName: progress.detectiveName ?? 'DETECTIVE',
    episode: episode,
    progress: progress,
    performances: [
      for (final m in episode.allMissions)
        if (progress.isCompleted(m.id)) performanceFor(m, progress),
    ],
  );

  static MissionPerformance performanceFor(Mission m, GameProgress progress) => MissionPerformance(
    mission: m,
    recorded: progress.attempts.containsKey(m.id),
    wrongAnswers: progress.wrongCount(m.id),
    hints: progress.hintsFor(m.id),
    xp: XpBreakdown.of(m, progress),
    learning: learningOf(m),
    solveSeconds: progress.solveSeconds[m.id],
  );

  final String detectiveName;
  final Episode episode;
  final GameProgress progress;
  final List<MissionPerformance> performances;

  int get missionsCompleted => progress.completedCount(episode);
  int get missionsTotal => episode.missions.length;
  int get cluesFound => progress.collectedClues(episode).length;
  int get cluesTotal => episode.allClues.length;
  int get evidenceFound => progress.collectedEvidence(episode).length;
  int get evidenceTotal => episode.allEvidence.length;
  int get xp => performances.fold(0, (sum, p) => sum + p.xp.total);

  List<GameBadge> get badges => [for (final id in progress.badgeIds) ?GameBadge.byId(id)];

  /// The badge shown in the report's headline.
  GameBadge? get topBadge {
    final earned = badges;
    if (earned.isEmpty) return null;
    for (final b in earned) {
      if (b.isCaseBadge) return b; // the case's own badge headlines its report
    }
    return earned.contains(GameBadge.masterDetective) ? GameBadge.masterDetective : earned.last;
  }

  // ── Play record (measured) ─────────────────────────────────────────

  /// Solved missions the save has an attempt record for.
  List<MissionPerformance> get recordedPerformances => [
    for (final p in performances)
      if (p.recorded) p,
  ];

  /// False when no solved mission of the case has a play record (the case
  /// was marked solved without being played on this save).
  bool get hasPlayRecord => recordedPerformances.isNotEmpty;

  /// Tips opened in the case.
  int get hintsUsed => progress.totalHints;

  /// Missions answered on the first try, among the recorded ones.
  int get firstTryCount => recordedPerformances.where((p) => p.firstTry).length;

  /// Play time, or null when the save cannot tell it.
  Duration? get elapsed => hasPlayRecord ? progress.elapsed() : null;

  /// The words the child tapped to see their meaning, as recorded.
  List<String> get wordsLookedUp => progress.lookedUpWords;

  /// False when the save is older than the word record: an empty list then
  /// means "no record", not "no words".
  bool get lookupsRecorded => progress.lookupsRecorded;

  // ── Learning design (content, not a result) ────────────────────────

  CaseLanguageTopic? get languageTopic => languageTopicOf(episode.id);

  /// Solved missions designed so the answer depends on the English.
  int get englishEssentialCount =>
      performances.where((p) => p.learning?.dependency == LanguageDependency.essential).length;

  // ── Detective actions (recorded since action recording began) ──────

  /// False when this run's save is older than action recording, or the case
  /// was marked solved without being played (playtest tools): its actions
  /// are then unknown ("no record"), not zero.
  bool get actionsRecorded => progress.recordsBehavior && hasPlayRecord;

  /// Missions where the letter or evidence was checked again after a wrong
  /// answer, before solving.
  int get secondLooks => progress.behavior?.rechecked.length ?? 0;

  /// Evidence opened from the notebook or the Case Archive during the case.
  int get evidenceChecked => progress.behavior?.evidenceViewed.length ?? 0;

  /// Short English case summary for the kid-facing report. It praises what
  /// the detective did (solving, checking clues again, using the notebook),
  /// never a first-try or fast answer, and never treats tips as a failure.
  String get caseSummary {
    final buffer = StringBuffer(
      episode.caseSummary ?? 'You followed the clues across London and found the missing crown.',
    );
    if (secondLooks > 0) {
      buffer.write(' You checked the clues again and never gave up!');
    } else if (evidenceChecked > 0) {
      buffer.write(' Your notebook helped you crack the case!');
    } else {
      buffer.write(' Case closed, Detective!');
    }
    return buffer.toString();
  }

  /// The game master's note for parents: what was recorded and what the case
  /// was about. Observed facts only: no grades, no claims about ability.
  List<String> get parentComments {
    final name = detectiveName;
    final topic = languageTopic;
    final comments = <String>[
      '$name 탐정은 이번 사건에서 미션 $missionsCompleted개와 최종 사건을 영어 편지와 단서로 진행했어요.',
      if (topic != null) '이 사건의 영어 주제는 "${topic.titleKo}"였어요. 아래 표현들이 사건 속 편지와 증거에 나왔어요.',
      if (englishEssentialCount > 0) '해결한 미션 중 $englishEssentialCount개는 영어 문장의 뜻을 알아야 풀리도록 만들어진 미션이에요.',
    ];

    if (!hasPlayRecord) {
      comments.add('이 사건은 플레이 기록 없이 해결된 것으로 저장되어 있어요(테스트 도구 또는 이전 버전의 저장 데이터). 시도·힌트 기록은 없어요.');
      return comments;
    }

    if (wordsLookedUp.isNotEmpty) {
      comments.add('모르는 단어 ${wordsLookedUp.length}개를 스스로 눌러 뜻을 확인했어요.');
    } else if (lookupsRecorded) {
      comments.add('이번 사건에서는 단어 뜻 보기를 사용하지 않았어요.');
    }

    comments.add(
      hintsUsed > 0 ? '막힐 때 Detective Hint를 $hintsUsed번 열어 보고 다시 도전했어요.' : '이번 사건에서는 Detective Hint를 열지 않았어요.',
    );

    if (!actionsRecorded) {
      comments.add('편지·증거를 다시 확인한 기록은 이번 업데이트 이후의 플레이부터 남아요. 이번 사건은 기록이 없어요.');
    } else {
      if (secondLooks > 0) comments.add('막혔을 때 편지나 증거를 다시 확인하고 해결한 미션이 $secondLooks개 있었어요.');
      if (evidenceChecked > 0) comments.add('수첩·사건 기록에서 증거 $evidenceChecked개를 자세히 살펴봤어요.');
    }
    return comments;
  }
}
