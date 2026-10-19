import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/core/utils/answer_checker.dart';
import 'package:london_mystery/data/models/mission.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/mission/widgets/answer_feedback.dart';

import 'helpers.dart';

/// TYPE B representative-case pass (Case 01, 05, 12): wrong answers get a
/// line about what was misread, never the answer; the finals of Case 05 and
/// 12 are read, not matched by picture; answers are unchanged.
void main() {
  final season = MockEpisodeRepository.bundled();
  final missions = {for (final e in season) for (final m in e.allMissions) m.id: m};
  Mission m(String id) => missions[id]!;

  String answerOf(Mission x) => switch (x.type) {
        MissionType.multipleChoice || MissionType.imageChoice => x.answerLabel,
        _ => x.answer,
      };

  group('feedback rules (every case)', () {
    test('no line is attached to a right answer', () {
      for (final x in missions.values) {
        for (final o in x.options.where((o) => o.feedback != null)) {
          expect(o.id, isNot(x.answer), reason: '${x.id}: the right option has no "wrong" line');
        }
        for (final key in x.feedback.keys) {
          expect(AnswerChecker.isCorrect(x, key), isFalse, reason: '${x.id}: "$key" is a right answer');
        }
        expect(AnswerChecker.feedbackFor(x, x.answer), isNull, reason: x.id);
      }
    });

    test('no line, and no tip, gives the answer away', () {
      for (final x in missions.values) {
        if (x.type == MissionType.sequence) continue; // its steps are the options themselves
        final answer = AnswerChecker.normalize(answerOf(x));
        final lines = [
          ...x.hints,
          ...x.feedback.values,
          ?x.orderFeedback,
          for (final o in x.options) ?o.feedback,
        ];
        for (final line in lines) {
          expect(AnswerChecker.normalize(line).contains(answer), isFalse, reason: '${x.id}: "$line"');
        }
      }
    });

    test('lines are short: one thought each', () {
      for (final x in missions.values) {
        for (final line in [...x.feedback.values, ?x.orderFeedback, for (final o in x.options) ?o.feedback]) {
          expect(line.length, lessThanOrEqualTo(110), reason: '${x.id}: "$line"');
        }
      }
    });
  });

  group('Case 01', () {
    test('M1: the museums are told apart by what the letter says is inside', () {
      final m1 = m('m01');
      expect(m1.answer, 'b');
      expect(AnswerChecker.feedbackFor(m1, 'a'), contains('Dinosaur'));
      expect(AnswerChecker.feedbackFor(m1, 'c'), contains('Trains'));
      for (final o in m1.options) {
        expect(o.label.toLowerCase(), isNot(contains('mummies')), reason: 'no option repeats the letter');
        expect(o.label.toLowerCase(), isNot(contains('egypt')));
      }
    });

    test('M2: STONE is not on its screens before the puzzle', () {
      final m2 = m('m02');
      final screens = [m2.title, ...m2.story, m2.letterIntro, m2.letter, m2.question].join(' ').toUpperCase();
      expect(RegExp(r'\bSTONE\b').hasMatch(screens), isFalse);
      expect(AnswerChecker.feedbackFor(m2, 'rock'), contains('Very close'));
      expect(AnswerChecker.isCorrect(m2, 'stone'), isTrue);
    });

    test('M3: each wrong hiding place sends the detective back to where the footprints stop', () {
      final m3 = m('m03');
      for (final wrong in ['a', 'c']) {
        expect(AnswerChecker.feedbackFor(m3, wrong), contains('footprints'), reason: wrong);
        expect(AnswerChecker.feedbackFor(m3, wrong)!.toLowerCase(), isNot(contains('stone')), reason: 'never the answer');
      }
      expect(AnswerChecker.feedbackFor(m3, 'b'), isNull);
    });

    test('M4: no names under the pictures; Final keeps its picture locks (the tutorial)', () {
      expect(m('m04').hideOptionNames, isTrue);
      expect(m('m04').answer, 'c');
      expect(m('final').dialSymbols, ['clock', 'train', 'park', 'museum']);
      expect(m('final').answer, '7924');
    });
  });

  group('Case 05', () {
    test('M2: "the other way" and "the same way as" slips', () {
      final m2 = m('ep05_m2');
      expect(AnswerChecker.feedbackFor(m2, 'left,left,left,left'), contains('opposite'));
      expect(AnswerChecker.feedbackFor(m2, 'left,right,right,left'), contains('turn 1'));
      expect(AnswerChecker.feedbackFor(m2, 'left,left,right,right'), m2.orderFeedback);
      expect(AnswerChecker.feedbackFor(m2, 'right,right,right,right'), isNull);
      expect(m2.answer, 'left,right,left,right');
    });

    test('M3: six without "one more"', () {
      final m3 = m('ep05_m3');
      expect(AnswerChecker.feedbackFor(m3, 'six'), contains('one more'));
      expect(AnswerChecker.feedbackFor(m3, ' 6 '), contains('one more'));
    });

    test('Final: no pictures on the locks, so the lid is read; copying the clues in order is caught', () {
      final f = m('ep05_final');
      expect(f.dialSymbols, isEmpty);
      expect(f.answer, '745');
      expect(AnswerChecker.feedbackFor(f, '547'), f.orderFeedback, reason: 'the order the clues were found in');
      expect(m('ep05_final').story.join(' '), isNot(contains('picture')));
      expect(m('ep05_m3').transition.join(' '), isNot(contains('picture')));
    });
  });

  group('Case 12', () {
    test('M1 and M2: what was misread', () {
      expect(AnswerChecker.feedbackFor(m('ep12_m1'), 'a'), contains('metal'));
      // Phase 4 (P1-3 A): two trains on Platform 4; 'after' decides.
      expect(AnswerChecker.feedbackFor(m('ep12_m2'), '11:04'), contains('Edinburgh train itself'));
      expect(AnswerChecker.feedbackFor(m('ep12_m2'), '1015'), allOf(contains('before'), contains('after')));
      expect(AnswerChecker.feedbackFor(m('ep12_m2'), '1155'), contains('small red clock'));
    });

    test('Final: no pictures on the locks; the door\'s questions decide; same answer', () {
      final f = m('ep12_final');
      expect(f.dialSymbols, isEmpty);
      expect(f.answer, '487');
      expect(AnswerChecker.feedbackFor(f, '847'), f.orderFeedback);
      // Phase 4 (P1-3 B): the first lock is read in Case 09's 'whose' structure.
      expect(f.letter, contains('The first lock: the number of the platform whose clock is small and red.'));
    });

    test('M3 is unchanged (Big Ben is where the season has been heading)', () {
      expect(m('ep12_m3').answer, 'BIG BEN');
    });
  });

  group('the try-again sheet', () {
    for (final size in const [Size(360, 640), Size(390, 844)]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}';

      testWidgets('$tag: a mission line replaces the general one; without it, the general one', (t) async {
        t.view.physicalSize = size * 3;
        t.view.devicePixelRatio = 3;
        addTearDown(t.view.reset);
        late BuildContext ctx;
        await t.pumpWidget(ProviderScope(
          overrides: await testOverrides(),
          child: MaterialApp(home: Builder(builder: (c) {
            ctx = c;
            return const Scaffold();
          })),
        ));

        showTryAgainSheet(ctx, hintAvailable: true, message: m('ep05_m1').options[1].feedback);
        await t.pumpAndSettle();
        expect(find.text('Not quite!'), findsOneWidget);
        expect(find.textContaining('which side is the door on?'), findsOneWidget);
        expect(find.textContaining('Good detectives look again'), findsNothing);
        expect(find.text('TRY AGAIN'), findsOneWidget);
        expect(t.takeException(), isNull);
        await t.tap(find.text('TRY AGAIN'));
        await t.pumpAndSettle();

        showTryAgainSheet(ctx, hintAvailable: false);
        await t.pumpAndSettle();
        expect(find.textContaining('Good detectives look again'), findsOneWidget);
        expect(t.takeException(), isNull);
      });
    }
  });
}
