import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/scoring.dart';
import 'package:london_mystery/features/result/detective_report.dart';
import 'package:london_mystery/features/result/parent_report_screen.dart';

import 'full_playthrough_test.dart' show tapText, wait;
import 'game_controller_test.dart' show fullRun;
import 'helpers.dart';
import 'mission_play.dart';

/// XP rule 4 (rule 3's flat XP, smaller) and the detective action badges: every solve is worth the same,
/// a lucky guess is never an achievement, tips and wrong answers cost
/// nothing, action badges need a recorded action (never inferred), and saves
/// from before keep their XP and badges.
void main() {
  final m = {for (final x in episode01.allMissions) x.id: x};
  final ids = episode01.allMissions.map((x) => x.id).toList();

  group('XP rule 4 (controller)', () {
    late ProviderContainer container;
    late DateTime clock;
    GameController ctrl() => container.read(gameControllerProvider.notifier);
    GameProgress state() => container.read(gameControllerProvider);
    int xpOf(String id) => XpBreakdown.of(m[id]!, state()).total;

    setUp(() async {
      clock = DateTime(2026, 10, 12, 10);
      GameController.now = () => clock;
      container = ProviderContainer(overrides: await testOverrides());
      ctrl().registerDetective('Kim');
      ctrl().startInvestigation();
    });
    tearDown(() {
      container.dispose();
      GameController.now = DateTime.now;
    });

    test('1-2. first try (understood or a lucky guess: the same input) = 30 XP, rule 4 recorded', () {
      ctrl().markMissionStarted('m01');
      clock = clock.add(const Duration(seconds: 5)); // fast, too
      ctrl().submitAnswer(m['m01']!, 'b');
      expect(xpOf('m01'), 30);
      expect(state().xpRules['m01'], 4);
    });

    test('3. one wrong answer, then right = 30 XP', () {
      ctrl().submitAnswer(m['m01']!, 'a');
      ctrl().submitAnswer(m['m01']!, 'b');
      expect(xpOf('m01'), 30);
    });

    test('4. three wrong answers, then right = 30 XP', () {
      for (final w in ['a', 'c', 'd']) {
        ctrl().submitAnswer(m['m01']!, w);
      }
      ctrl().submitAnswer(m['m01']!, 'b');
      expect(xpOf('m01'), 30);
    });

    test('5-6. tip 1, or tips 1 and 2, then right = 30 XP', () {
      ctrl().useHint(m['m01']!);
      ctrl().submitAnswer(m['m01']!, 'b');
      expect(xpOf('m01'), 30);
      ctrl().useHint(m['m02']!);
      ctrl().useHint(m['m02']!);
      ctrl().submitAnswer(m['m02']!, 'stone');
      expect(xpOf('m02'), 30);
    });

    test('7. the final case: 60 XP on a first try, after wrong answers, after tips', () {
      for (final (id, answer) in fullRun) {
        ctrl().submitAnswer(m[id]!, answer);
      }
      ctrl().useHint(m['final']!);
      ctrl().useHint(m['final']!);
      ctrl().submitAnswer(m['final']!, '9472');
      ctrl().submitAnswer(m['final']!, '7924');
      expect(xpOf('final'), 60);
      expect(XpBreakdown.totalFor(episode01, state()), 5 * 30 + 60);
    });

    test('9-10. Sharp Eyes and Quick Thinker are never given again, even for a fast first-try case', () {
      final earned = <GameBadge>[];
      for (final (id, answer) in fullRun) {
        ctrl().markMissionStarted(id);
        clock = clock.add(const Duration(seconds: 3));
        earned.addAll(ctrl().submitAnswer(m[id]!, answer).newBadges);
      }
      earned.addAll(ctrl().submitAnswer(m['final']!, '7924').newBadges);
      expect(earned, isNot(contains(GameBadge.sharpEyes)));
      expect(earned, isNot(contains(GameBadge.quickThinker)));
      expect(earned, containsAll([GameBadge.firstClue, GameBadge.masterDetective]));
    });

    test('14. a solved mission submitted again, and Play again, add nothing on top of one run', () {
      ctrl().submitAnswer(m['m01']!, 'b');
      final again = ctrl().submitAnswer(m['m01']!, 'b');
      expect(again.newBadges, isEmpty);
      expect(XpBreakdown.totalFor(episode01, state()), 30);
      ctrl().playAgain();
      ctrl().startInvestigation();
      ctrl().submitAnswer(m['m01']!, 'b');
      expect(XpBreakdown.totalFor(episode01, state()), 30, reason: 'one run per case, never summed');
      expect(state().badgeIds.toSet(), hasLength(state().badgeIds.length));
      expect(state().recordsBehavior, isTrue, reason: 'a new run records actions');
    });
  });

  group('8 & 15. saves from before rule 3', () {
    GameProgress solvedWith(
      Map<String, int> rules, {
      Map<String, int> wrong = const {},
      Map<String, int> hints = const {},
    }) => GameProgress(
      completedMissionIds: const ['m01', 'm02', 'm03'],
      attempts: {
        for (final id in ['m01', 'm02', 'm03']) id: 1 + (wrong[id] ?? 0),
      },
      wrongAnswers: wrong,
      hintsUsed: hints,
      solveSeconds: const {'m01': 30, 'm02': 300, 'm03': 30},
      xpRules: rules,
    );

    test('rule 1 and rule 2 missions keep their XP; rule 3 missions are flat', () {
      final p = solvedWith(const {'m02': 2, 'm03': 3}, wrong: const {'m02': 1, 'm03': 2}, hints: const {'m01': 1});
      expect(XpBreakdown.of(m['m01']!, p).total, 100 + 25 + 20, reason: 'rule 1: one tip, fast');
      expect(XpBreakdown.of(m['m02']!, p).total, 100 + 25, reason: 'rule 2: second try');
      expect(XpBreakdown.of(m['m03']!, p).total, 100, reason: 'rule 3');
    });

    test('an old save loads: XP, badges (retired ones too) and "no action record"', () {
      final old = <String, dynamic>{
        'detectiveName': 'KIM',
        'introSeen': true,
        'completedMissionIds': ['m01', 'm02'],
        'attempts': {'m01': 4, 'm02': 2},
        'wrongAnswers': {'m01': 3, 'm02': 1},
        'hintsUsed': <String, int>{},
        'solveSeconds': {'m01': 30, 'm02': 90},
        'xpRules': {'m02': 2},
        'badgeIds': ['firstClue', 'sharpEyes', 'quickThinker'],
        'lookedUpWords': ['museum', 'thief', 'crown', 'palace'],
      };
      final p = GameProgress.fromJson(old);
      expect(XpBreakdown.of(m['m01']!, p).total, 170, reason: 'rule 1, kept');
      expect(XpBreakdown.of(m['m02']!, p).total, 125, reason: 'rule 2, kept');
      expect(p.badgeIds, ['firstClue', 'sharpEyes', 'quickThinker']);
      expect(p.recordsBehavior, isFalse);
      // Four recorded words, but from before actions were recorded: no badge.
      expect(GameBadge.wordCollector.isEarned(episode01, p), isFalse);
      // Saving keeps "not recorded" (the key stays absent).
      final again = GameProgress.fromJson(jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>);
      expect(again.recordsBehavior, isFalse);
      expect(again.badgeIds, p.badgeIds);
      // Retired badges show only where earned.
      expect(GameBadge.shownFor(episode01, p.badgeIds), containsAll([GameBadge.sharpEyes, GameBadge.quickThinker]));
      expect(GameBadge.shownFor(episode01, const []), isNot(contains(GameBadge.sharpEyes)));
    });

    test('new badges and the action log survive a save and a load; unknown badge ids are skipped', () {
      final p = GameProgress(
        badgeIds: const ['firstClue', 'secondLook', 'notAbadge'],
        behavior: const BehaviorLog(rechecked: ['m01'], evidenceViewed: ['e01'], words: ['museum']),
      );
      final again = GameProgress.fromJson(jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>);
      expect(again.behavior!.rechecked, ['m01']);
      expect(again.behavior!.evidenceViewed, ['e01']);
      expect(again.behavior!.words, ['museum']);
      expect(DetectiveReport.from(episode01, again).badges, [GameBadge.firstClue, GameBadge.secondLook]);
    });

    test('retired badge descriptions are true of every way they were earned', () {
      for (final b in [GameBadge.sharpEyes, GameBadge.quickThinker]) {
        expect(b.retired, isTrue);
        expect(b.description, contains('이전 버전'));
        expect(b.description, isNot(contains('첫 시도')));
        expect(b.description, isNot(contains('힌트')));
      }
    });
  });

  group('action badges (controller)', () {
    late ProviderContainer container;
    GameController ctrl() => container.read(gameControllerProvider.notifier);
    GameProgress state() => container.read(gameControllerProvider);

    setUp(() async {
      container = ProviderContainer(overrides: await testOverrides());
      ctrl().registerDetective('Kim');
      ctrl().startInvestigation();
    });
    tearDown(() => container.dispose());

    test('11. Second Look: wrong → re-check → right; not a wrong answer alone, not a check before it', () {
      // A re-read with no wrong answer yet is not recorded.
      ctrl().recordRecheck(m['m01']!);
      expect(state().behavior!.rechecked, isEmpty);
      // A wrong answer, then right without checking: no badge.
      ctrl().submitAnswer(m['m01']!, 'a');
      final plain = ctrl().submitAnswer(m['m01']!, 'b');
      expect(plain.newBadges, isNot(contains(GameBadge.secondLook)));
      // A re-check after a solve is not recorded.
      ctrl().recordRecheck(m['m01']!);
      expect(state().behavior!.rechecked, isEmpty);
      // Wrong, the letter re-read, right: the badge.
      ctrl().submitAnswer(m['m02']!, 'rock');
      ctrl().recordRecheck(m['m02']!);
      final second = ctrl().submitAnswer(m['m02']!, 'stone');
      expect(second.newBadges, contains(GameBadge.secondLook));
      // Once per case.
      ctrl().submitAnswer(m['m03']!, '000');
      ctrl().recordRecheck(m['m03']!);
      expect(ctrl().submitAnswer(m['m03']!, '417').newBadges, isNot(contains(GameBadge.secondLook)));
    });

    test('11. Second Look: evidence opened after a wrong answer counts as a re-check of that mission', () {
      ctrl().submitAnswer(m['m01']!, 'b');
      ctrl().submitAnswer(m['m02']!, 'rock');
      ctrl().recordEvidenceViewed('e01');
      expect(state().behavior!.rechecked, ['m02']);
      expect(ctrl().submitAnswer(m['m02']!, 'stone').newBadges, contains(GameBadge.secondLook));
    });

    test('12. Notebook Explorer: one piece of evidence opened while solving; once; not after the case', () {
      ctrl().submitAnswer(m['m01']!, 'b');
      ctrl().recordEvidenceViewed('e01');
      ctrl().recordEvidenceViewed('e01');
      expect(state().behavior!.evidenceViewed, ['e01'], reason: 'opening it again adds nothing');
      final out = ctrl().submitAnswer(m['m02']!, 'stone');
      expect(out.newBadges, contains(GameBadge.notebookExplorer));
      ctrl().recordEvidenceViewed('e02');
      expect(ctrl().submitAnswer(m['m03']!, '417').newBadges, isNot(contains(GameBadge.notebookExplorer)));
    });

    test('12. Notebook Explorer: nothing is recorded once the case is solved', () {
      for (final (id, answer) in fullRun) {
        ctrl().submitAnswer(m[id]!, answer);
      }
      ctrl().submitAnswer(m['final']!, '7924');
      ctrl().recordEvidenceViewed('e01');
      expect(state().behavior!.evidenceViewed, isEmpty);
    });

    test('13 & 16. Word Collector: three different words, a word looked up again counts once, given once', () {
      ctrl().lookUpWord('museum');
      ctrl().lookUpWord('Museum');
      ctrl().lookUpWord('museum');
      ctrl().lookUpWord('thief');
      expect(state().behavior!.words, ['museum', 'thief']);
      expect(ctrl().submitAnswer(m['m01']!, 'b').newBadges, isNot(contains(GameBadge.wordCollector)));
      ctrl().lookUpWord('crown');
      expect(ctrl().submitAnswer(m['m02']!, 'stone').newBadges, contains(GameBadge.wordCollector));
      ctrl().lookUpWord('palace');
      expect(ctrl().submitAnswer(m['m03']!, '417').newBadges, isNot(contains(GameBadge.wordCollector)));
      expect(state().badgeIds.where((b) => b == 'wordCollector'), hasLength(1));
    });

    test('action badges add no XP', () {
      ctrl().lookUpWord('museum');
      ctrl().lookUpWord('thief');
      ctrl().lookUpWord('crown');
      ctrl().submitAnswer(m['m01']!, 'a');
      ctrl().recordRecheck(m['m01']!);
      ctrl().submitAnswer(m['m01']!, 'b');
      expect(state().badgeIds, containsAll(['secondLook', 'wordCollector']));
      expect(XpBreakdown.totalFor(episode01, state()), 30);
    });
  });

  group('17-18. what the detective and the parent read', () {
    GameProgress solved({BehaviorLog? behavior = BehaviorLog.empty, Map<String, int> wrong = const {}}) => GameProgress(
      detectiveName: 'KIM',
      completedMissionIds: ids,
      attempts: {for (final id in ids) id: 1 + (wrong[id] ?? 0)},
      wrongAnswers: wrong,
      xpRules: {for (final id in ids) id: 3},
      startedAt: DateTime(2026, 10, 12),
      completedAt: DateTime(2026, 10, 12, 0, 20),
      playMillis: 20 * 60000,
      behavior: behavior,
    );

    test('17. the case summary praises actions, never a first try', () {
      expect(DetectiveReport.from(episode01, solved()).caseSummary, endsWith('Case closed, Detective!'));
      expect(
        DetectiveReport.from(
          episode01,
          solved(
            behavior: const BehaviorLog(rechecked: ['m01']),
            wrong: {'m01': 1},
          ),
        ).caseSummary,
        endsWith('You checked the clues again and never gave up!'),
      );
      expect(
        DetectiveReport.from(episode01, solved(behavior: const BehaviorLog(evidenceViewed: ['e01']))).caseSummary,
        endsWith('Your notebook helped you crack the case!'),
      );
      for (final b in [null, BehaviorLog.empty]) {
        final s = DetectiveReport.from(episode01, solved(behavior: b)).caseSummary;
        expect(s, isNot(contains('first try')));
        expect(s, isNot(contains('hint')));
      }
    });

    test('18. parent notes: actions only when recorded, otherwise "no record"; XP never an English score', () {
      final recorded = DetectiveReport.from(
        episode01,
        solved(
          behavior: const BehaviorLog(rechecked: ['m01'], evidenceViewed: ['e01', 'e02']),
          wrong: {'m01': 1},
        ),
      );
      expect(recorded.actionsRecorded, isTrue);
      expect(recorded.secondLooks, 1);
      expect(recorded.evidenceChecked, 2);
      expect(recorded.parentComments.join(), contains('증거 2개'));
      final old = DetectiveReport.from(episode01, solved(behavior: null));
      expect(old.actionsRecorded, isFalse);
      // A case the playtest tools mark solved has an empty, recording log but
      // was never played: no record either, not "0".
      final seeded = DetectiveReport.from(
        episode01,
        GameProgress(completedMissionIds: ids, startedAt: DateTime(2026, 10, 12), completedAt: DateTime(2026, 10, 12)),
      );
      expect(seeded.actionsRecorded, isFalse);
      expect(old.parentComments.join(), contains('기록이 없어요'));
      for (final r in [recorded, old]) {
        expect(r.parentComments.join(), isNot(contains('실력')));
        expect(r.xp, 5 * 100 + 200);
      }
    });

    for (final size in const [Size(360, 640), Size(390, 844)]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}';

      testWidgets('18. $tag: the report separates actions, marks old saves "기록 없음", and says what first try is not', (
        t,
      ) async {
        t.view.physicalSize = size * 3;
        t.view.devicePixelRatio = 3;
        addTearDown(t.view.reset);
        await t.pumpWidget(
          ProviderScope(
            overrides: await testOverrides(
              prefs: {
                // Saved without the action log, like a save from before.
                AppConstants.progressStorageKey: jsonEncode(solved(behavior: null).toJson()),
              },
            ),
            child: const MaterialApp(home: ParentReportScreen()),
          ),
        );
        await t.pumpAndSettle();
        await t.scrollUntilVisible(find.text('Detective Actions'), 200);
        await t.scrollUntilVisible(find.text('Evidence Checked'), 200);
        expect(find.text('기록 없음'), findsWidgets);
        await t.scrollUntilVisible(find.textContaining('운 좋게 맞힌 경우와 구분할 수 없어서'), 200);
        await t.scrollUntilVisible(find.textContaining('영어 점수가 아닙니다'), 200);
        expect(t.takeException(), isNull);
      });
    }
  });

  group('the real UI events', () {
    testWidgets('11. Second Look in the app: wrong answer → Letter → right answer earns it; no Letter, no badge', (
      t,
    ) async {
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(390, 844), 'm01');
      await tapText(t, 'The Natural History Museum (dinosaur bones)', after: const Duration(milliseconds: 200));
      await tapText(t, 'CHECK ANSWER');
      await tapText(t, 'TRY AGAIN', after: const Duration(milliseconds: 600));
      expect(
        play.ref.read(gameControllerProvider).behavior!.rechecked,
        isEmpty,
        reason: 'closing the sheet is not a check',
      );
      await tapText(t, 'Letter', after: const Duration(milliseconds: 600));
      await tapText(t, 'BACK TO THE PUZZLE', after: const Duration(milliseconds: 600));
      expect(play.ref.read(gameControllerProvider).behavior!.rechecked, ['m01']);
      await tapText(t, 'The British Museum (treasures from long ago)', after: const Duration(milliseconds: 200));
      await tapText(t, 'CHECK ANSWER', after: Duration.zero);
      await wait(t, const Duration(milliseconds: 2800));
      expect(find.textContaining('Second Look'), findsOneWidget, reason: 'the Discovery Moment names the new badge');
      expect(find.text('+30 XP   ·   +30 COINS'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('12. Notebook Explorer in the app: opening the notebook is not enough; opening evidence is', (t) async {
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(390, 844), 'm02');
      await t.tap(find.byTooltip('Detective notebook'));
      await wait(t, const Duration(milliseconds: 1200));
      await t.tap(find.text('EVIDENCE'));
      await wait(t, const Duration(milliseconds: 800));
      expect(
        play.ref.read(gameControllerProvider).behavior!.evidenceViewed,
        isEmpty,
        reason: 'only looked at the page',
      );
      await t.tap(find.text('Old Letter'));
      await wait(t, const Duration(milliseconds: 800));
      expect(play.ref.read(gameControllerProvider).behavior!.evidenceViewed, ['e01']);
      expect(t.takeException(), isNull);
    });
  });
}
