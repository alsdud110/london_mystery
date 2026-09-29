import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/mission.dart';
import 'package:london_mystery/features/game/scoring.dart';
import 'package:london_mystery/features/result/detective_report.dart';

import 'helpers.dart';

void main() {
  final ids = episode01.allMissions.map((m) => m.id).toList();
  final start = DateTime(2026, 9, 28, 10);

  GameProgress run({
    Map<String, int> wrong = const {},
    Map<String, int> hints = const {},
    int secondsEach = 60,
    List<String> words = const [],
  }) =>
      GameProgress(
        detectiveName: 'MINYOUNG',
        introSeen: true,
        completedMissionIds: ids,
        attempts: {for (final id in ids) id: 1 + (wrong[id] ?? 0)},
        wrongAnswers: wrong,
        hintsUsed: hints,
        solveSeconds: {for (final id in ids) id: secondsEach},
        badgeIds: [for (final b in GameBadge.forEpisode(episode01)) b.name],
        lookedUpWords: words,
        startedAt: start,
        completedAt: start.add(const Duration(minutes: 42, seconds: 18)),
      );

  test('perfect fast run: full stars, clues, evidence and max XP', () {
    final r = DetectiveReport.from(episode01, run());
    expect(r.missionsCompleted, 5);
    expect(r.missionsTotal, 5);
    expect(r.cluesFound, r.cluesTotal);
    expect(r.evidenceFound, r.evidenceTotal);
    expect(r.accuracyPercent, 100);
    expect(r.hintsUsed, 0);
    expect(r.xp, 5 * 170 + 270);
    expect(r.elapsed, const Duration(minutes: 42, seconds: 18));
    expect(r.topBadge, GameBadge.masterDetective);
    expect(r.skillStars.values, everyElement(5));
    expect(r.caseSummary, contains('without a single hint'));
    expect(r.parentComments, isNotEmpty);
  });

  test('mistakes, hints and slow solves lower XP and stars but stay positive', () {
    final r = DetectiveReport.from(
      episode01,
      run(wrong: {'m02': 2, 'm03': 1}, hints: {'m02': 2, 'final': 1}, secondsEach: 600, words: ['museum', 'thief']),
    );
    expect(r.accuracyPercent, (6 * 100 / 9).round());
    expect(r.hintsUsed, 3);
    expect(r.xp, 5 * 100 + 200 + 4 * 50 + 0 + 25);
    expect(r.skillStars[Skill.vocabulary], lessThan(5));
    expect(r.skillStars.values, everyElement(greaterThanOrEqualTo(1)));
    expect(r.wordsLookedUp, 2);
    expect(r.parentComments.join(), contains('단어 2개'));
    expect(r.caseSummary, contains('never gave up'));
  });
}
