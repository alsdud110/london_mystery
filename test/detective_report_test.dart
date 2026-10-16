import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/features/game/scoring.dart';
import 'package:london_mystery/features/result/detective_report.dart';

import 'helpers.dart';

void main() {
  final ids = episode01.allMissions.map((m) => m.id).toList();
  final start = DateTime(2026, 9, 28, 10);

  // Saves without `xpRules`: every mission keeps XP rule 1, as before.
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

  test('first-try run: clues, evidence, unchanged rule-1 XP; the summary does not praise first tries', () {
    final r = DetectiveReport.from(episode01, run());
    expect(r.missionsCompleted, 5);
    expect(r.missionsTotal, 5);
    expect(r.cluesFound, r.cluesTotal);
    expect(r.evidenceFound, r.evidenceTotal);
    expect(r.hasPlayRecord, isTrue);
    expect(r.firstTryCount, 6);
    expect(r.hintsUsed, 0);
    expect(r.xp, 5 * 170 + 270, reason: 'XP earned before rule 2 does not change');
    expect(r.elapsed, const Duration(minutes: 42, seconds: 18));
    expect(r.topBadge, GameBadge.masterDetective);
    expect(r.caseSummary, contains('Case closed, Detective!'));
    expect(r.caseSummary, isNot(contains('first try')));
    expect(r.parentComments, isNotEmpty);
  });

  test('mistakes and tips: the record says what happened, XP of old saves is unchanged', () {
    final r = DetectiveReport.from(
      episode01,
      run(wrong: {'m02': 2, 'm03': 1}, hints: {'m02': 2, 'final': 1}, secondsEach: 600, words: ['museum', 'thief']),
    );
    expect(r.hintsUsed, 3);
    expect(r.firstTryCount, 4);
    expect(r.xp, 5 * 100 + 200 + 4 * 50 + 0 + 25);
    expect(r.wordsLookedUp, ['museum', 'thief']);
    expect(r.parentComments.join(), contains('단어 2개'));
    expect(r.parentComments.join(), contains('Detective Hint를 3번'));
    expect(r.caseSummary, contains('Case closed, Detective!'), reason: 'wrong answers are not held against the detective');
    expect(r.caseSummary, isNot(contains('hint')), reason: 'tips are never framed as a failure');
  });
}
