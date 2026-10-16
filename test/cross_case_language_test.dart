import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/data/models/profile.dart';
import 'package:london_mystery/core/utils/answer_checker.dart';
import 'package:london_mystery/data/mock/season1/season1_learning.dart';
import 'package:london_mystery/data/models/learning.dart';
import 'package:london_mystery/data/models/mission.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/game/scoring.dart';

import 'full_playthrough_test.dart' show tapText, wait;
import 'helpers.dart';
import 'mission_play.dart';
import 'title_screen_test.dart' show capture;

/// Phase 4 (P1-3, P1-4): English from an earlier case is needed again —
/// "after" (Case 02) and the small red clock (Case 04) in Case 12 Mission 02,
/// "whose" (Case 09) on the Clockmaker's door, and "never sleep" (Case 04)
/// in Case 11 Mission 03 — with every answer, piece of evidence and ending
/// as before, and a way on for a child who cannot open the archive.
void main() {
  final season = MockEpisodeRepository.bundled();
  Mission m(String id) => season.expand((e) => e.allMissions).firstWhere((x) => x.id == id);
  bool word(String text, String w) => RegExp('\\b$w\\b', caseSensitive: false).hasMatch(text);

  group('(A) Case 12 Mission 02: the small red clock, then "after"', () {
    final m2 = m('ep12_m2');

    /// The arrivals on the board: time (minutes), from, platform.
    List<(int, String, int)> board() => [
          for (final r in RegExp(r'(\d\d):(\d\d)\s+from (\w+) — Platform (\d)').allMatches(m2.letter))
            (int.parse(r[1]!) * 60 + int.parse(r[2]!), r[3]!, int.parse(r[4]!)),
        ];

    test('the board, Case 04 and "after" leave exactly one train: 11:40, the answer', () {
      final trains = board();
      expect(trains, hasLength(4));
      // Case 04: the small red clock is on Platform 4.
      expect(m('ep04_m2').letter, contains('Platform 4 has a small red clock.'));
      final platform = 4;
      final onIt = trains.where((t) => t.$3 == platform).toList();
      expect(onIt, hasLength(2), reason: 'the platform alone is not enough any more');
      // "after the train from Edinburgh"
      expect(m2.letter.replaceAll('\n', ' '), contains('after the train from Edinburgh'));
      final edinburgh = trains.firstWhere((t) => t.$2 == 'Edinburgh');
      expect(edinburgh.$3, isNot(platform));
      final left = onIt.where((t) => t.$1 > edinburgh.$1).toList();
      expect(left, hasLength(1));
      final time = left.single.$1;
      final code = '${time ~/ 60}${(time % 60).toString().padLeft(2, '0')}';
      expect(code, m2.answer);
      expect(m2.answer, '1140');
      // "after" alone is not enough either: two trains come after Edinburgh.
      expect(trains.where((t) => t.$1 > edinburgh.$1), hasLength(2));
    });

    test('the evidence, the clue and the scene after still agree with 11:40 on Platform 4', () {
      expect(m2.evidence!.inscription, '11:40 from Paris — Platform 4');
      expect(m2.clue!.value, '4');
      expect(m2.clue!.note, 'The Clockmaker came in on Platform 4, from Paris.');
      expect(m2.transition.first, 'At 11:40, a tall figure steps off the Paris train.');
      expect(season.firstWhere((e) => e.id == 'ep12').intro.first, 'London, 11:00 PM...');
    });

    test('the tips: the archive first; without it, Tip 2 still gives a way on (not the time)', () {
      expect(m2.hints.first, allOf(contains('Case 04'), contains('Case Archive')));
      expect(m2.hints.last, allOf(contains('Platform 4'), contains("'after the train from Edinburgh'")));
      for (final h in m2.hints) {
        expect(AnswerChecker.normalize(h).contains('1140'), isFalse, reason: h);
      }
    });

    test('each other time says what was misread', () {
      expect(AnswerChecker.feedbackFor(m2, '10:15'), allOf(contains('Platform 4 too'), contains('before')));
      expect(AnswerChecker.feedbackFor(m2, '1104'), contains('Edinburgh train itself'));
      expect(AnswerChecker.feedbackFor(m2, '1155'), contains('another platform'));
      expect(AnswerChecker.feedbackFor(m2, '1140'), isNull);
    });
  });

  group('(B) Case 12 Final: the first lock in "whose"', () {
    final f = m('ep12_final');

    test("the first lock reads like Case 09's note: 'whose' + its noun", () {
      expect(f.letter, contains('The first lock: the number of the platform whose clock is small and red.'));
      expect(m('ep09_final').letter, contains('the one whose key you used'));
      expect(RegExp(r'\bwhose (clock|key)\b').allMatches('${f.letter} ${m('ep09_final').letter}'), hasLength(2));
    });

    test('nothing on the door or in the tips gives a number; the answer and the ending stay', () {
      for (final line in [f.letter, ...f.hints, ...f.feedback.values, ?f.orderFeedback]) {
        expect(RegExp(r'\d').hasMatch(line), isFalse, reason: line);
      }
      expect(f.answer, '487');
      expect(f.dialSymbols, isEmpty);
      expect(f.transition.last, 'PARIS.');
      expect(f.evidence!.name, "The Clockmaker's Watch");
    });

    test('without the archive the first lock is answered by tonight\'s clue', () {
      expect(m('ep12_m2').clue!.title, 'Platform 4');
      expect(f.hints.last, contains('small red clock'));
    });
  });

  group('(C) Case 11 Mission 03: "never sleeps" from Case 04', () {
    final m3 = m('ep11_m3');

    test("the guard's words are Case 04's words, and Case 04 was at the station", () {
      expect(m('ep11_m2').transition, contains('A guard shouts: "He went to the station that never sleeps!"'));
      expect(m3.hints.first, allOf(contains("'the station that never sleeps'"), contains('Case 04')));
      expect(m('ep04_m1').letter, contains('Meet me where trains never sleep.'));
      expect(m('ep04_m1').clue!.note, 'The platforms never sleep. They are open day and night.');
      final case04 = season.firstWhere((e) => e.id == 'ep04');
      expect(case04.introScene, Artwork.kingsCross, reason: 'the picture seen in Case 04');
    });

    test('no tip names the place; the pictures stay unnamed; the answer stays', () {
      for (final h in m3.hints) {
        expect(h.toLowerCase(), isNot(contains('king')), reason: h);
        expect(word(h, 'shadow'), isFalse, reason: h);
        expect(word(h, 'door'), isFalse, reason: h);
      }
      expect(m3.hideOptionNames, isTrue);
      expect(m3.answerLabel, "King's Cross");
      // Without the archive, Tip 2 and the driver's words still describe it.
      expect(m3.hints.last, allOf(contains('station'), contains('Arches')));
      expect(m3.letter, contains('two big arches and a clock tower'));
    });
  });

  test('the learning design names the reused English', () {
    final m2 = learningOf(m('ep12_m2'))!;
    expect(m2.expressions, contains('after the train from Edinburgh'));
    expect(m2.recallFrom, 'ep04_m2');
    final fin = learningOf(m('ep12_final'))!;
    expect(fin.expressions, contains('the platform whose clock is small and red'));
    expect(fin.skill, LanguageSkill.grammarInContext);
    final m3 = learningOf(m('ep11_m3'))!;
    expect(m3.level, LearningLevel.recall);
    expect(m3.recallFrom, 'ep04_m1');
    expect(m3.expressions, containsAll(['the station that never sleeps', 'Meet me where trains never sleep']));
  });

  test('XP rule 4 holds: Case 12 with a "before" slip is 3 × 30 + 60', () async {
    final container = ProviderContainer(overrides: await testOverrides());
    addTearDown(container.dispose);
    container.read(gameControllerProvider.notifier).createDetective('KIM', DetectiveAvatar.boy);
    for (final e in season.take(11)) {
      container.read(seasonProvider.notifier).markSolved(e.id);
    }
    expect(container.read(gameControllerProvider.notifier).openEpisode('ep12'), isTrue);
    final c = container.read(gameControllerProvider.notifier);
    c.startInvestigation();
    c.submitAnswer(m('ep12_m1'), 'd');
    c.submitAnswer(m('ep12_m2'), '1015');
    c.submitAnswer(m('ep12_m2'), '1140');
    c.submitAnswer(m('ep12_m3'), 'big ben');
    c.submitAnswer(m('ep12_final'), '847');
    c.submitAnswer(m('ep12_final'), '487');
    final p = container.read(gameControllerProvider);
    expect(p.isCaseSolved, isTrue);
    expect(XpBreakdown.totalFor(season.last, p), 3 * 30 + 60);
  });

  group('on screen', () {
    for (final size in const [Size(360, 640), Size(390, 844)]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}';

      testWidgets('$tag: Case 12 Mission 02, 10:15 says it came before the Edinburgh train', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'ep12_m2');
        for (final d in '1015'.split('')) {
          await tapText(t, d, after: const Duration(milliseconds: 120));
        }
        await tapText(t, 'UNLOCK', after: const Duration(milliseconds: 400));
        expect(find.text('Not quite!'), findsOneWidget);
        expect(find.textContaining('before the Edinburgh train'), findsOneWidget);
        // The board, one line longer, still reads on the letter sheet.
        await tapText(t, 'TRY AGAIN', after: const Duration(milliseconds: 600));
        await tapText(t, 'Reread Letter', after: const Duration(milliseconds: 800));
        expect(findReadable('after the train from Edinburgh."'), findsNothing, reason: 'one letter, many lines');
        expect(find.textContaining('10:15', findRichText: true), findsWidgets);
        await capture(t, 'phase4_board_letter_$tag');
        expect(t.takeException(), isNull);
      });

      testWidgets("$tag: Case 11 Mission 03, the first tip points back to Case 04's words", (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'ep11_m3');
        await tapText(t, 'Get a Free Hint', after: const Duration(milliseconds: 500));
        await takeTipFromSheet(t);
        expect(find.textContaining('never sleeps'), findsOneWidget);
        expect(t.takeException(), isNull);
        await wait(t, const Duration(milliseconds: 200));
      });
    }
  });
}
