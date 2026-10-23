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

/// TYPE B Phase 3A (Case 06-08): wrong answers say what was misread, the
/// card in Case 06 points back to the witness notes, every answer and every
/// protected reasoning rule stays, and the rules now cover feedback lines too.
void main() {
  final season = MockEpisodeRepository.bundled();
  Mission byId(String id) => season.expand((e) => e.allMissions).firstWhere((m) => m.id == id);
  final cases = [for (final id in ['ep06', 'ep07', 'ep08']) season.firstWhere((e) => e.id == id)];
  final missions = {for (final e in cases) for (final m in e.allMissions) m.id: m};
  Mission m(String id) => missions[id]!;

  /// Every line a wrong answer can show in [x].
  List<String> feedbackOf(Mission x) => [for (final o in x.options) ?o.feedback, ...x.feedback.values, ?x.orderFeedback];

  test('the answers of Case 06-08 are unchanged', () {
    expect({for (final x in missions.values) x.id: x.answer}, {
      'ep06_m1': 'b', 'ep06_m2': 'GREY', 'ep06_m3': 'a', 'ep06_final': 'c', // 06-M3: which night (2026-10-23, was the count 4)
      'ep07_m1': 'c', 'ep07_m2': 'c', 'ep07_m3': 'station,park,river', 'ep07_final': 'b',
      'ep08_m1': 'b', 'ep08_m2': 'ROBIN', 'ep08_m3': '429', 'ep08_final': 'c',
    });
    expect(m('ep06_m2').acceptedAnswers, containsAll(['GRAY', 'INSPECTOR GREY']));
  });

  test('every wrong option has its own line, the right one none; no line repeats in a mission', () {
    for (final x in missions.values) {
      for (final o in x.options) {
        if (o.id == x.answer) {
          expect(o.feedback, isNull, reason: '${x.id}: the right option');
        } else if (x.type == MissionType.multipleChoice || x.type == MissionType.imageChoice) {
          expect(o.feedback, isNotNull, reason: '${x.id} option ${o.id}');
        }
      }
      final lines = feedbackOf(x);
      expect(lines.toSet(), hasLength(lines.length), reason: x.id);
      expect(x.hints, hasLength(2), reason: x.id);
      expect(x.hints[0], isNot(x.hints[1]), reason: x.id);
    }
  });

  group('the protected reasoning, now with feedback lines', () {
    test('Case 06: no feedback line on the final names him, his hat or his card', () {
      for (final line in feedbackOf(m('ep06_final'))) {
        for (final w in ['grey', 'gray', 'inspector', 'hat', 'card', 'detective agency']) {
          expect(RegExp('\\b$w\\b', caseSensitive: false).hasMatch(line), isFalse, reason: '"$line": $w');
        }
      }
      for (final x in cases[0].allMissions) {
        for (final line in feedbackOf(x)) {
          expect(line, isNot(contains('on your side')), reason: x.id);
          expect(line, isNot(contains('the man in the grey hat is')), reason: x.id);
        }
      }
    });

    test('Case 07: no feedback line names the spot', () {
      for (final x in cases[1].allMissions) {
        for (final line in feedbackOf(x)) {
          expect(line.toLowerCase(), isNot(contains('gate')), reason: '${x.id}: "$line"');
        }
      }
      expect(AnswerChecker.feedbackFor(m('ep07_m1'), 'c'), isNull, reason: 'Mission 01: this map is the answer');
      expect(AnswerChecker.feedbackFor(m('ep07_final'), 'c'), contains('LEFT'), reason: 'the final: the same map is wrong');
    });

    test('Case 08: no feedback line names the button, her coat, or Miss Rose', () {
      for (final line in feedbackOf(m('ep08_final'))) {
        for (final w in ['button', 'coat', 'red', 'miss rose']) {
          expect(line.toLowerCase(), isNot(contains(w)), reason: '"$line": $w');
        }
      }
      for (final x in cases[2].allMissions) {
        for (final line in feedbackOf(x)) {
          expect(line.toLowerCase(), isNot(contains('miss rose')), reason: x.id);
          expect(line.toLowerCase(), isNot(contains('same person')), reason: x.id);
        }
      }
    });

    test('Case 03 → 08 stays: the Red Button from a coat, found in Gallery 8, answers her lie', () {
      final redButton = byId('ep03_m1').evidence!;
      expect(redButton.name, 'Red Button');
      expect(redButton.description, contains('coat'));
      expect(byId('ep03_m1').location, 'GALLERY 8');
      expect(m('ep08_final').answerLabel, redButton.name);
      expect(m('ep08_final').hints.last, allOf(contains('Case Archive'), contains('Case 03')));
    });
  });

  group('Case 06 Mission 02: the card points to his hat', () {
    test('the back of the card names his hat; the witness notes keep the colour', () {
      final m2 = m('ep06_m2');
      expect(m2.letter, contains('It is the colour of my hat,'));
      expect(m2.letter, contains('rain clouds and old stones'), reason: 'the riddle stays as a second way');
      expect(m('ep06_m1').letter, contains('He had a grey hat.'));
      expect(m('ep06_m1').evidence!.inscription, contains('grey hat'), reason: 'in the notebook to check');
      expect(m2.hints.first, allOf(contains('witness notes'), contains('notebook')));
      for (final h in m2.hints) {
        expect(h.toLowerCase(), isNot(contains('grey')), reason: h);
      }
      final learning = learningOf(m2)!;
      expect(learning.dependency, LanguageDependency.essential);
      expect(learning.level, LearningLevel.recall);
      expect(learning.recallFrom, 'ep06_m1');
    });

    test('each wrong colour says what to check', () {
      final m2 = m('ep06_m2');
      expect(AnswerChecker.feedbackFor(m2, 'red'), contains('umbrella'));
      expect(AnswerChecker.feedbackFor(m2, 'Black'), contains('coat'));
      expect(AnswerChecker.feedbackFor(m2, 'dark'), contains('coat'));
      expect(AnswerChecker.feedbackFor(m2, 'white'), contains('rain clouds'));
      expect(AnswerChecker.feedbackFor(m2, 'gray'), isNull, reason: 'still accepted');
    });
  });

  test('the slips of Case 06-08', () {
    expect(AnswerChecker.feedbackFor(m('ep06_m1'), 'd'), contains('worn'));
    expect(AnswerChecker.feedbackFor(m('ep06_m3'), 'c'), contains('coat')); // both nights' dark coat (2026-10-23)
    expect(AnswerChecker.feedbackFor(m('ep07_m2'), 'b'), contains("'behind'"));
    // Case 07 M3's two lines (2026-10-23, approved): each wrong order names
    // the line it breaks — the river at the top, or the station and the
    // river touching.
    expect(AnswerChecker.feedbackFor(m('ep07_m3'), 'river,park,station'), contains('river piece be at the top'));
    expect(AnswerChecker.feedbackFor(m('ep07_m3'), 'park,station,river'), contains('touch'));
    expect(AnswerChecker.feedbackFor(m('ep08_m2'), 'lily'), contains('her dad'));
    expect(AnswerChecker.feedbackFor(m('ep08_m3'), '9:30'), contains('whole train time'));
    expect(AnswerChecker.feedbackFor(m('ep08_m3'), '942'), m('ep08_m3').orderFeedback);
    expect(AnswerChecker.feedbackFor(m('ep08_final'), 'b'), contains('where was it found'));
  });

  test('Essential: Case 06-08 has 11 of 12 (06-F stays helpful)', () {
    final essential = missions.values.where((x) => learningOf(x)!.dependency == LanguageDependency.essential);
    expect(essential, hasLength(11));
    expect(learningOf(m('ep06_final'))!.dependency, LanguageDependency.helpful);
  });

  test('XP rule 4 holds: Case 06 with tips and wrong answers is 3 × 30 + 60', () async {
    final container = ProviderContainer(overrides: await testOverrides());
    addTearDown(container.dispose);
    container.read(gameControllerProvider.notifier).createDetective('KIM', DetectiveAvatar.boy);
    for (final id in ['ep01', 'ep02', 'ep03', 'ep04', 'ep05']) {
      container.read(seasonProvider.notifier).markSolved(id);
    }
    expect(container.read(gameControllerProvider.notifier).openEpisode('ep06'), isTrue);
    final c = container.read(gameControllerProvider.notifier);
    c.startInvestigation();
    c.submitAnswer(m('ep06_m1'), 'd');
    c.submitAnswer(m('ep06_m1'), 'b');
    c.useHint(m('ep06_m2'));
    c.useHint(m('ep06_m2'));
    c.submitAnswer(m('ep06_m2'), 'red');
    c.submitAnswer(m('ep06_m2'), 'grey');
    c.submitAnswer(m('ep06_m3'), 'c');
    c.submitAnswer(m('ep06_m3'), 'a');
    c.submitAnswer(m('ep06_final'), 'a');
    c.submitAnswer(m('ep06_final'), 'c');
    final p = container.read(gameControllerProvider);
    expect(p.isCaseSolved, isTrue);
    expect(XpBreakdown.totalFor(cases[0], p), 3 * 30 + 60);
  });

  group('on screen', () {
    for (final size in const [Size(360, 640), Size(390, 844)]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}';

      testWidgets('$tag: Case 06 Mission 02, a wrong colour says what to check', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'ep06_m2');
        await t.enterText(find.byType(TextField), 'red');
        await tapText(t, 'CHECK ANSWER');
        expect(find.text('Not quite!'), findsOneWidget);
        expect(find.textContaining('umbrella'), findsOneWidget);
        expect(t.takeException(), isNull);
      });

      testWidgets('$tag: Case 08 Mission 02, Lily is not alone', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'ep08_m2');
        await t.enterText(find.byType(TextField), 'lily');
        await tapText(t, 'CHECK ANSWER');
        expect(find.textContaining('with her dad'), findsOneWidget);
        expect(t.takeException(), isNull);
        await wait(t, const Duration(milliseconds: 200));
      });
    }
  });
}
