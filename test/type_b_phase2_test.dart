import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

/// TYPE B Phase 2 (Case 02-04): every wrong option says what was misread,
/// tips go "where to look" then "what the English means", Case 04 M2 and M3
/// are read rather than matched, and every answer is unchanged.
void main() {
  final season = MockEpisodeRepository.bundled();
  final cases = [for (final id in ['ep02', 'ep03', 'ep04']) season.firstWhere((e) => e.id == id)];
  final missions = {for (final e in cases) for (final m in e.allMissions) m.id: m};
  Mission m(String id) => missions[id]!;

  test('the answers of Case 02-04 are unchanged', () {
    expect({for (final x in missions.values) x.id: x.answer}, {
      'ep02_m1': '817', 'ep02_m2': 'c', 'ep02_m3': 'b', 'ep02_final': '917',
      'ep03_m1': 'c', 'ep03_m2': 'b', 'ep03_m3': 'shop,stairs,cafe,door', 'ep03_final': 'd',
      'ep04_m1': 'c', 'ep04_m2': 'b', 'ep04_m3': 'b', 'ep04_final': 'RAVEN',
    });
  });

  test('every wrong option has its own line; no line is repeated in a mission', () {
    for (final x in missions.values) {
      final wrong = [for (final o in x.options) if (o.id != x.answer) o];
      if (x.type == MissionType.multipleChoice || x.type == MissionType.imageChoice) {
        for (final o in wrong) {
          expect(o.feedback, isNotNull, reason: '${x.id} option ${o.id}');
        }
      }
      final lines = [for (final o in x.options) ?o.feedback, ...x.feedback.values, ?x.orderFeedback];
      expect(lines.toSet(), hasLength(lines.length), reason: '${x.id}: each misreading gets its own line');
    }
  });

  test('two tips each, and Tip 2 is not Tip 1 again', () {
    for (final x in missions.values) {
      expect(x.hints, hasLength(2), reason: x.id);
      expect(x.hints[0], isNot(x.hints[1]), reason: x.id);
    }
  });

  group('the slips the cases are about', () {
    test('Case 02: the clock read wrong, and before / after', () {
      expect(AnswerChecker.feedbackFor(m('ep02_m1'), '917'), contains('not reached nine'));
      expect(AnswerChecker.feedbackFor(m('ep02_m1'), '8:15'), contains('two more small marks'));
      expect(AnswerChecker.feedbackFor(m('ep02_m1'), '832'), contains('fifteen minutes'));
      expect(AnswerChecker.feedbackFor(m('ep02_m2'), 'a'), contains("'under the biggest bell'"));
      expect(AnswerChecker.feedbackFor(m('ep02_m3'), 'c'), contains('GALLERY'));
      expect(AnswerChecker.feedbackFor(m('ep02_final'), '817'), contains('ONE HOUR AFTER'));
      expect(AnswerChecker.feedbackFor(m('ep02_final'), '7:17'), contains('AFTER, not before'));
      expect(AnswerChecker.feedbackFor(m('ep02_final'), '818'), contains('minutes'));
    });

    test('Case 03: colours and the coat, wet and drier, the boot', () {
      expect(AnswerChecker.feedbackFor(m('ep03_m2'), 'c'), contains('his scarf'));
      final m3 = m('ep03_m3');
      expect(AnswerChecker.feedbackFor(m3, 'door,cafe,stairs,shop'), contains('driest'));
      expect(AnswerChecker.feedbackFor(m3, 'shop,cafe,stairs,door'), contains("'a little wet'"));
      expect(AnswerChecker.feedbackFor(m3, 'stairs,shop,cafe,door'), m3.orderFeedback);
      expect(AnswerChecker.feedbackFor(m('ep03_final'), 'a'), contains('boot'));
      expect(m('ep03_final').hideOptionNames, isFalse, reason: 'two clock towers: the names do not give it away');
    });

    test("Case 04: 'never sleeps', 'but no clock', a castle, and the bird", () {
      expect(AnswerChecker.feedbackFor(m('ep04_m1'), 'b'), contains('sleeps at night'));
      final m2 = m('ep04_m2');
      expect([for (final o in m2.options) o.label], ['Platform 1', 'Platform 4', 'Platform 7', 'Platform 9']);
      for (final o in m2.options) {
        expect(o.label.toLowerCase(), isNot(contains('red')), reason: 'the options do not repeat the card');
        expect(o.label.toLowerCase(), isNot(contains('clock')));
      }
      expect(m2.letter, contains('Platform 7 has a red door, but no clock.'));
      expect(AnswerChecker.feedbackFor(m2, 'c'), contains('is there a clock?'));
      expect(m('ep04_m3').hideOptionNames, isTrue);
      expect(AnswerChecker.feedbackFor(m('ep04_m3'), 'a'), contains('not a castle'));
      expect(AnswerChecker.feedbackFor(m('ep04_final'), 'crow'), contains('Close!'));
      expect(AnswerChecker.feedbackFor(m('ep04_final'), 'ravens'), isNull, reason: 'still accepted');
    });
  });

  test('learning design: Case 04 M2 and M3 now need the English; 03-M1 and 04-F stay helpful', () {
    for (final id in ['ep04_m2', 'ep04_m3']) {
      expect(learningOf(m(id))!.dependency, LanguageDependency.essential, reason: id);
    }
    for (final id in ['ep03_m1', 'ep04_final']) {
      expect(learningOf(m(id))!.dependency, LanguageDependency.helpful, reason: id);
    }
    final essential = missions.values.where((x) => learningOf(x)!.dependency == LanguageDependency.essential);
    expect(essential, hasLength(10));
  });

  test('XP rule 3 holds: tips and wrong answers in Case 02-04 change nothing', () async {
    final container = ProviderContainer(overrides: await testOverrides());
    addTearDown(container.dispose);
    final ctrl = container.read(gameControllerProvider.notifier);
    ctrl.registerDetective('KIM');
    expect(ctrl.openEpisode('ep01'), isTrue);
    // Case 02 is opened as the active case once Case 01 counts as solved.
    container.read(seasonProvider.notifier).markSolved('ep01');
    expect(ctrl.openEpisode('ep02'), isTrue);
    final c = container.read(gameControllerProvider.notifier);
    c.startInvestigation();
    c.useHint(m('ep02_m1'));
    c.useHint(m('ep02_m1'));
    c.submitAnswer(m('ep02_m1'), '917');
    c.submitAnswer(m('ep02_m1'), '817');
    c.submitAnswer(m('ep02_m2'), 'c');
    c.submitAnswer(m('ep02_m3'), 'a');
    c.submitAnswer(m('ep02_m3'), 'b');
    c.submitAnswer(m('ep02_final'), '717');
    c.submitAnswer(m('ep02_final'), '917');
    final p = container.read(gameControllerProvider);
    expect(p.isCaseSolved, isTrue);
    expect(XpBreakdown.totalFor(cases[0], p), 3 * 100 + 200);
  });

  group('on screen', () {
    for (final size in const [Size(360, 640), Size(390, 844)]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}';

      testWidgets("$tag: 04-M2 Platform 7 says what was missed ('but no clock')", (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'ep04_m2');
        await tapText(t, 'Platform 7', after: const Duration(milliseconds: 200));
        await tapText(t, 'CHECK ANSWER');
        expect(find.text('Not quite!'), findsOneWidget);
        expect(find.textContaining('is there a clock?'), findsOneWidget);
        expect(t.takeException(), isNull);
      });

      testWidgets('$tag: 04-M3 pictures carry no names (screen reader: Picture B)', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'ep04_m3');
        for (final o in m('ep04_m3').options) {
          expect(find.text(o.label), findsNothing, reason: o.label);
        }
        expect(find.bySemanticsLabel(RegExp(r'^Picture B: ')), findsOneWidget, reason: 'described to screen readers (Phase 3B), never named');
        expect(t.takeException(), isNull);
        await wait(t, const Duration(milliseconds: 200));
      });
    }
  });
}
