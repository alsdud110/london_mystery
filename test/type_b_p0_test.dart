import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/game/scoring.dart';
import 'package:london_mystery/features/result/detective_report.dart';
import 'package:london_mystery/features/result/parent_report_screen.dart';

import 'game_controller_test.dart' show fullRun;
import 'helpers.dart';

/// TYPE B P0: an honest parent report, rewards that never favour guessing
/// over reading, and saves from before the change left as they were.
void main() {
  final m = {for (final x in episode01.allMissions) x.id: x};
  final ids = episode01.allMissions.map((x) => x.id).toList();

  /// A case marked solved without being played (as the playtest tools do).
  GameProgress seeded() => GameProgress(
        detectiveName: 'TESTER',
        introSeen: true,
        completedMissionIds: ids,
        startedAt: DateTime(2026, 10, 1),
        completedAt: DateTime(2026, 10, 1),
        playMillis: 0,
      );

  group('saves from before TYPE B', () {
    test('a save without xpRules keeps rule-1 XP (no retroactive change)', () {
      final old = GameProgress.fromJson({
        'detectiveName': 'KIM',
        'completedMissionIds': ['m01'],
        'attempts': {'m01': 3},
        'wrongAnswers': {'m01': 2},
        'hintsUsed': <String, int>{},
        'solveSeconds': {'m01': 30},
        'lookedUpWords': <String>[],
      });
      final xp = XpBreakdown.of(m['m01']!, old);
      expect((xp.base, xp.noHintBonus, xp.speedBonus, xp.carefulBonus), (100, 50, 20, 0));
    });

    test('a save without a word list says "no record", and keeps saying it', () {
      final old = GameProgress.fromJson({'detectiveName': 'KIM', 'completedMissionIds': <String>[]});
      expect(old.lookupsRecorded, isFalse);
      final again = GameProgress.fromJson(jsonDecode(jsonEncode(old.toJson())) as Map<String, dynamic>);
      expect(again.lookupsRecorded, isFalse, reason: 'saving does not turn "no record" into "no words"');
      expect(GameProgress.fromJson({'lookedUpWords': <String>[]}).lookupsRecorded, isTrue);
      expect(GameProgress.empty.lookupsRecorded, isTrue);
      expect(GameProgress.empty.resetCase().lookupsRecorded, isTrue);
    });

    test('xpRules survive a save and a load', () {
      final p = GameProgress(xpRules: const {'m01': 2});
      expect(GameProgress.fromJson(jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>).xpRules, {'m01': 2});
      expect(GameProgress.empty.toJson().containsKey('xpRules'), isFalse, reason: 'old-shaped JSON for old-shaped saves');
    });
  });

  group('rewards (rule 2)', () {
    late ProviderContainer container;
    GameController ctrl() => container.read(gameControllerProvider.notifier);
    GameProgress state() => container.read(gameControllerProvider);

    setUp(() async {
      container = ProviderContainer(overrides: await testOverrides());
      ctrl().registerDetective('Kim');
      ctrl().startInvestigation();
    });
    tearDown(() => container.dispose());

    // XP rule 3 (replaced rule 2, which paid a lucky first guess more than a
    // detective who misread once and corrected it).
    test('guessing through the options and reading with both tips earn the same XP', () {
      // The guesser taps every wrong option first, quickly, without tips.
      for (final guess in ['a', 'c', 'd']) {
        ctrl().submitAnswer(m['m01']!, guess);
      }
      ctrl().submitAnswer(m['m01']!, 'b');
      final guessed = XpBreakdown.of(m['m01']!, state()).total;

      // The reader opens both tips and answers once.
      ctrl().useHint(m['m02']!);
      ctrl().useHint(m['m02']!);
      ctrl().submitAnswer(m['m02']!, 'stone');
      final read = XpBreakdown.of(m['m02']!, state()).total;

      expect(guessed, AppConstants.missionXp);
      expect(read, AppConstants.missionXp);
      expect(GameBadge.sharpEyes.isEarned(episode01, state()), isFalse, reason: 'retired');
      expect(GameBadge.quickThinker.isEarned(episode01, state()), isFalse, reason: 'retired');
    });

    test('no tip ever lowers XP', () {
      ctrl().submitAnswer(m['m01']!, 'b');
      final noTips = XpBreakdown.of(m['m01']!, state()).total;
      ctrl().useHint(m['m02']!);
      ctrl().useHint(m['m02']!);
      ctrl().submitAnswer(m['m02']!, 'stone');
      expect(XpBreakdown.of(m['m02']!, state()).total, noTips);
    });

    test('playing a case again does not add XP or badges on top of the first run', () {
      void playCase() {
        for (final (id, answer) in fullRun) {
          ctrl().submitAnswer(m[id]!, answer);
        }
        ctrl().submitAnswer(m['final']!, '7924');
      }

      playCase();
      final firstXp = XpBreakdown.totalFor(episode01, state());
      final firstBadges = [...state().badgeIds];
      expect(container.read(seasonProvider).isSolved('ep01'), isTrue);

      ctrl().playAgain();
      expect(XpBreakdown.totalFor(episode01, state()), 0);
      ctrl().startInvestigation();
      playCase();

      expect(XpBreakdown.totalFor(episode01, state()), firstXp, reason: 'one run per case, never summed');
      expect(state().badgeIds, firstBadges);
      expect(state().badgeIds.toSet(), hasLength(state().badgeIds.length), reason: 'no badge twice');
      expect(container.read(seasonProvider).isSolved('ep01'), isTrue);
    });
  });

  group('parent report: measured facts only', () {
    const claims = ['돋보', '잘 알아보고', '능력', '실력', '향상', '숙달', '뛰어'];

    void expectNoClaims(DetectiveReport r) {
      final text = [...r.parentComments, r.caseSummary].join('\n');
      for (final c in claims) {
        expect(text, isNot(contains(c)), reason: 'no unmeasured claim ("$c")');
      }
    }

    test('a first-try run and a guessing run make no claims about English', () {
      final played = GameProgress(
        detectiveName: 'KIM',
        completedMissionIds: ids,
        attempts: {for (final id in ids) id: 1},
        startedAt: DateTime(2026, 10, 1),
        completedAt: DateTime(2026, 10, 1, 0, 30),
        playMillis: 30 * 60 * 1000,
      );
      final guessed = played.copyWith(
        attempts: {for (final id in ids) id: 4},
        wrongAnswers: {for (final id in ids) id: 3},
      );
      for (final p in [played, guessed]) {
        final r = DetectiveReport.from(episode01, p);
        expectNoClaims(r);
        expect(r.languageTopic, isNotNull);
      }
      expect(DetectiveReport.from(episode01, guessed).firstTryCount, 0);
    });

    test('a case solved without play shows "no record", not a perfect run', () {
      final r = DetectiveReport.from(episode01, seeded());
      expect(r.hasPlayRecord, isFalse);
      expect(r.firstTryCount, 0);
      expect(r.elapsed, isNull);
      expect(r.performances.every((p) => !p.recorded && !p.firstTry), isTrue);
      expect(r.parentComments.join(), contains('기록 없이'));
      expect(r.parentComments.join(), isNot(contains('열지 않았어요')), reason: 'no tip record, so no tip claim');
      expect(r.caseSummary, isNot(contains('first try')));
      expectNoClaims(r);
    });

    test('every solved mission of every case carries its learning design', () {
      final r = DetectiveReport.from(episode01, seeded());
      expect(r.performances.every((p) => p.learning != null), isTrue);
    });
  });

  group('parent report screen', () {
    Future<void> pump(WidgetTester t, Size size, GameProgress progress) async {
      t.view.physicalSize = size * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(ProviderScope(
        overrides: await testOverrides(prefs: {AppConstants.progressStorageKey: jsonEncode(progress.toJson())}),
        child: const MaterialApp(home: ParentReportScreen()),
      ));
      await t.pumpAndSettle();
    }

    for (final size in const [Size(360, 640), Size(390, 844)]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}';

      testWidgets('$tag: learning design, words and play record; no skill stars', (t) async {
        await pump(
          t,
          size,
          GameProgress(
            detectiveName: 'ALEXANDRINA',
            introSeen: true,
            completedMissionIds: ids,
            attempts: {for (final id in ids) id: 1},
            hintsUsed: const {'m02': 2},
            lookedUpWords: const ['museum', 'thief'],
            startedAt: DateTime(2026, 10, 1),
            completedAt: DateTime(2026, 10, 1, 0, 25),
            playMillis: 25 * 60 * 1000,
          ),
        );
        expect(t.takeException(), isNull);
        expect(find.text('English Skills'), findsNothing);
        expect(find.text('Accuracy'), findsNothing);
        await t.scrollUntilVisible(find.text('English in This Case'), 200);
        expect(find.textContaining('측정한 결과가 아니에요'), findsOneWidget);
        // The looked-up word with its meaning (one rich line).
        await t.scrollUntilVisible(find.textContaining('museum  박물관', findRichText: true), 200);
        await t.scrollUntilVisible(find.text('Play Record'), 200);
        expect(t.takeException(), isNull);
      });

      testWidgets('$tag: a case solved without play says "기록 없음"', (t) async {
        await pump(t, size, seeded());
        await t.scrollUntilVisible(find.text('Play Record'), 200);
        await t.scrollUntilVisible(find.text('First Try'), 200);
        expect(find.text('기록 없음'), findsWidgets);
        expect(t.takeException(), isNull);
      });
    }
  });
}
