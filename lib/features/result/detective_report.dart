import '../../data/models/episode.dart';
import '../../data/models/game_progress.dart';
import '../../data/models/mission.dart';
import '../game/scoring.dart';

class MissionPerformance {
  const MissionPerformance({
    required this.mission,
    required this.wrongAnswers,
    required this.hints,
    required this.xp,
    required this.score,
    this.solveSeconds,
  });

  final Mission mission;
  final int wrongAnswers;
  final int hints;
  final XpBreakdown xp;
  final int? solveSeconds;

  /// 0..1 — 1.0 means solved first try without a hint.
  final double score;

  bool get firstTry => wrongAnswers == 0;
  bool get usedHint => hints > 0;
}

/// Everything shown on the Case Closed and Parent Report screens,
/// derived purely from [GameProgress] + [Episode].
class DetectiveReport {
  DetectiveReport._({
    required this.detectiveName,
    required this.episode,
    required this.progress,
    required this.performances,
    required this.skillStars,
  });

  factory DetectiveReport.from(Episode episode, GameProgress progress) {
    final performances = <MissionPerformance>[
      for (final m in episode.allMissions)
        if (progress.isCompleted(m.id)) performanceFor(m, progress),
    ];

    final skillStars = <Skill, int>{};
    for (final skill in Skill.values) {
      final scores = [for (final p in performances) if (p.mission.skills.contains(skill)) p.score];
      final avg = scores.isEmpty ? 0.0 : scores.reduce((a, b) => a + b) / scores.length;
      skillStars[skill] = (avg * 5).round().clamp(1, 5);
    }

    return DetectiveReport._(
      detectiveName: progress.detectiveName ?? 'DETECTIVE',
      episode: episode,
      progress: progress,
      performances: performances,
      skillStars: skillStars,
    );
  }

  static MissionPerformance performanceFor(Mission m, GameProgress progress) {
    final wrong = progress.wrongCount(m.id);
    final hints = progress.hintsFor(m.id);
    final score = (1.0 - 0.2 * (wrong > 3 ? 3 : wrong) - 0.15 * hints).clamp(0.3, 1.0);
    return MissionPerformance(
      mission: m,
      wrongAnswers: wrong,
      hints: hints,
      xp: XpBreakdown.of(m, progress),
      score: score,
      solveSeconds: progress.solveSeconds[m.id],
    );
  }

  final String detectiveName;
  final Episode episode;
  final GameProgress progress;
  final List<MissionPerformance> performances;
  final Map<Skill, int> skillStars;

  int get missionsCompleted => progress.completedCount(episode);
  int get missionsTotal => episode.missions.length;
  int get hintsUsed => progress.totalHints;
  int get cluesFound => progress.collectedClues(episode).length;
  int get cluesTotal => episode.allClues.length;
  int get evidenceFound => progress.collectedEvidence(episode).length;
  int get evidenceTotal => episode.allEvidence.length;
  int get wordsLookedUp => progress.lookedUpWords.length;
  Duration get elapsed => progress.elapsed() ?? Duration.zero;
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

  int get totalAttempts => episode.allMissions.fold(0, (sum, m) => sum + (progress.attempts[m.id] ?? 0));

  /// Share of answers that were correct, as a whole percentage.
  int get accuracyPercent => totalAttempts == 0 ? 0 : (performances.length * 100 / totalAttempts).round();

  int get firstTryCount => performances.where((p) => p.firstTry).length;

  /// Short English case summary for the kid-facing report.
  String get caseSummary {
    final buffer = StringBuffer(episode.caseSummary ?? 'You followed the clues across London and found the missing crown.');
    if (hintsUsed == 0) {
      buffer.write(' You did it without a single hint!');
    } else if (firstTryCount >= performances.length - 1) {
      buffer.write(' Sharp thinking, Detective!');
    } else {
      buffer.write(' You never gave up!');
    }
    return buffer.toString();
  }

  static String skillLabel(Skill s) => switch (s) {
        Skill.vocabulary => 'Vocabulary',
        Skill.reading => 'Reading',
        Skill.problemSolving => 'Problem Solving',
      };

  static String skillLabelKo(Skill s) => switch (s) {
        Skill.vocabulary => '어휘',
        Skill.reading => '읽기',
        Skill.problemSolving => '문제 해결',
      };

  /// Key words of the case named in the parent comment (Episode 01 keeps its
  /// original three).
  List<String> get _keyWords => episode.keyWords.isEmpty ? const ['museum', 'stone', 'palace'] : episode.keyWords;

  /// Warm, game-report style comment for parents (not a report card).
  List<String> get parentComments {
    final name = detectiveName;
    final comments = <String>[
      '$name 탐정은 영어로 된 편지와 단서를 읽고 핵심 정보를 찾아내는 활동을 게임 속에서 자연스럽게 경험했습니다.',
    ];

    final sorted = skillStars.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final best = sorted.first;
    final weakest = sorted.last;
    comments.add(switch (best.key) {
      Skill.reading => '특히 문장 속에서 장소와 인물의 단서를 찾아내는 읽기 능력이 돋보였어요.',
      Skill.vocabulary => '특히 ${_keyWords.join(', ')} 같은 핵심 단어를 잘 알아보고 활용했어요.',
      Skill.problemSolving => '특히 여러 단서를 조합해 최종 암호를 푸는 논리적 사고력이 돋보였어요.',
    });

    if (weakest.value < best.value) {
      comments.add(switch (weakest.key) {
        Skill.reading => '다음 모험에서는 긴 문장을 끝까지 읽고 정보를 정리해 보는 연습을 함께 해보면 좋아요.',
        Skill.vocabulary => '숫자·장소 관련 영어 단어를 일상에서 함께 말해보면 다음 사건이 더 쉬워질 거예요.',
        Skill.problemSolving => '단서를 수첩에 적고 순서대로 정리해 보는 습관을 함께 칭찬해 주세요.',
      });
    }

    if (wordsLookedUp > 0) {
      comments.add('모르는 단어 $wordsLookedUp개를 스스로 찾아보며 읽었어요. 궁금한 단어를 확인하는 좋은 읽기 습관이에요.');
    }

    comments.add(hintsUsed == 0
        ? '힌트 없이 스스로 모든 미션을 해결했어요. 끈기와 집중력을 칭찬해 주세요!'
        : '막히는 순간 힌트를 활용해 다시 도전했어요. 포기하지 않고 끝까지 해결한 점을 칭찬해 주세요!');
    return comments;
  }
}
