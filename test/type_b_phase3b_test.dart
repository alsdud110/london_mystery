import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/data/models/profile.dart';
import 'package:world_mystery/core/utils/answer_checker.dart';
import 'package:world_mystery/data/mock/season1/season1_learning.dart';
import 'package:world_mystery/data/models/learning.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/features/game/game_providers.dart';
import 'package:world_mystery/features/game/scoring.dart';

import 'helpers.dart';
import 'mission_play.dart';
import 'title_screen_test.dart' show capture;

/// TYPE B Phase 3B (Case 09-11): wrong answers say what was misread, the
/// protected reasoning of each case holds for feedback lines too, Case 11 M3
/// is read from the driver's description, and pictures shown without a name
/// are described to screen readers (never named).
void main() {
  final season = season1Cases();
  final all = {for (final e in season) for (final m in e.allMissions) m.id: m};
  final cases = [for (final id in ['ep09', 'ep10', 'ep11']) season.firstWhere((e) => e.id == id)];
  final missions = {for (final e in cases) for (final m in e.allMissions) m.id: m};
  Mission m(String id) => all[id]!;
  bool word(String text, String w) => RegExp('\\b$w\\b', caseSensitive: false).hasMatch(text);
  List<String> feedbackOf(Mission x) => [for (final o in x.options) ?o.feedback, ...x.feedback.values, ?x.orderFeedback];

  test('the answers of Case 09-11 are unchanged', () {
    expect({for (final x in missions.values) x.id: x.answer}, {
      'ep09_m1': 'c', 'ep09_m2': 'ANNA', 'ep09_m3': '12', 'ep09_final': 'HAT',
      'ep10_m1': 'c', 'ep10_m2': 'north,tower,bridge,three', 'ep10_m3': 'c', 'ep10_final': 'clockmaker,stop,bigben,midnight',
      'ep11_m1': 'c', 'ep11_m2': 'MIDNIGHT', 'ep11_m3': 'a', 'ep11_final': 'd',
    });
    expect(m('ep10_m3').answerLabel, 'Tower Bridge');
    expect(m('ep11_m3').answerLabel, "King's Cross");
  });

  test('every wrong option has its own line, the right one none; tips: two, different', () {
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

  group('protected reasoning, feedback lines included', () {
    test("Case 09: nothing says hat before the answer; the final's lines keep its secrets", () {
      for (final x in cases[0].allMissions) {
        for (final line in feedbackOf(x)) {
          expect(word(line, 'hats?'), isFalse, reason: '${x.id}: "$line"');
        }
      }
      for (final line in feedbackOf(m('ep09_final'))) {
        expect(line, isNot(contains("guard's")), reason: line);
        expect(line.toLowerCase(), isNot(contains('belongs')), reason: line);
        expect(word(line, 'carl'), isFalse, reason: line);
        expect(AnswerChecker.normalize(line).contains('HAT'), isFalse, reason: line);
      }
      expect(AnswerChecker.feedbackFor(m('ep09_final'), 'umbrella'), contains('WHOSE key'));
    });

    test('Case 10: no line names the meeting place before Mission 03 is answered; its names stay', () {
      for (final id in ['ep10_m1', 'ep10_m2', 'ep10_m3']) {
        for (final line in [...feedbackOf(m(id)), ...m(id).hints]) {
          expect(line.toLowerCase(), isNot(contains('tower bridge')), reason: '$id: "$line"');
        }
      }
      final m3 = m('ep10_m3');
      expect(m3.hideOptionNames, isFalse, reason: 'making the name from two words is the puzzle');
      final words = m('ep10_m2').options.map((o) => o.label.toLowerCase()).toSet();
      for (final o in m3.options) {
        expect(o.label.toLowerCase().split(' ').every(words.contains), o.id == m3.answer, reason: o.label);
      }
      final trap = m3.options.firstWhere((o) => o.label == 'Tower of London');
      expect(trap.artwork, Artwork.towerOfLondon);
      expect(trap.feedback, contains('TWO'));
    });

    test('Case 11: no line names him, no door but the stage door, nothing under Big Ben', () {
      for (final x in cases[2].allMissions) {
        for (final line in feedbackOf(x)) {
          expect(word(line, 'shadow'), isFalse, reason: '${x.id}: "$line"');
          expect(word(line, 'door'), isFalse, reason: '${x.id}: "$line"');
          expect(line.toLowerCase(), isNot(contains('under big ben')), reason: x.id);
        }
      }
      expect(m('ep11_final').hints.last, contains('Case 01'));
    });

    test('the links stay: Case 01 → 11, Case 08 → 09, Case 04 → 11', () {
      expect(m('m01').evidence!.inscription, 'Signed: The Shadow\nP.S. I love trains!');
      expect(m('ep11_final').letter, contains('We met at the very start.'));
      expect(cases[0].intro.join(' '), contains("The jewel box from Mrs Robin's suitcase came from here."));
      expect(m('ep11_m2').transition.join(' '), contains('the station that never sleeps'), reason: "Case 04's phrase, read again");
      expect(m('ep11_m3').letter, contains('I love trains'));
    });
  });

  group('pictures without names, for every child', () {
    final unnamed = [for (final x in all.values) if (x.hideOptionNames) x];

    test('every unnamed picture is described, never named', () {
      expect(unnamed.map((x) => x.id), containsAll(['m04', 'ep04_m3', 'ep11_m3']));
      for (final x in unnamed) {
        for (final o in x.options) {
          expect(o.altText, isNotNull, reason: '${x.id} ${o.id}');
          expect(o.altText!.toLowerCase(), isNot(contains(o.label.toLowerCase())), reason: '${x.id}: names ${o.label}');
          expect(x.letter.toLowerCase(), isNot(contains(o.altText!.toLowerCase())), reason: 'not the letter copied');
        }
      }
      // The same picture is described the same way everywhere.
      // (A landmark by its artwork; a drawn picture by its file, 2026-10-30.)
      final byArt = <String, String>{};
      for (final x in unnamed) {
        for (final o in x.options) {
          final art = o.artwork?.name ?? o.picture!;
          expect(byArt.putIfAbsent(art, () => o.altText!), o.altText, reason: art);
        }
      }
      expect(m('ep11_m3').options.first.altText, isNot(contains('station')));
    });

    test('Case 11 Mission 03 now needs the description', () {
      final l = learningOf(m('ep11_m3'))!;
      expect(l.dependency, LanguageDependency.essential);
      expect(AnswerChecker.feedbackFor(m('ep11_m3'), 'd'), contains('arches'));
    });

    for (final size in const [Size(360, 640), Size(390, 844)]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}';

      testWidgets('$tag: Case 11 M3 shows no names; a screen reader hears what each picture shows', (t) async {
        final semantics = t.ensureSemantics();
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'ep11_m3');
        for (final o in m('ep11_m3').options) {
          expect(find.text(o.label), findsNothing, reason: o.label);
        }
        expect(find.bySemanticsLabel(RegExp(r'^Picture A: a long building with a great arched glass roof')), findsOneWidget);
        expect(find.bySemanticsLabel(RegExp(r"King's Cross")), findsNothing);
        expect(t.takeException(), isNull);
        await capture(t, 'phase3b_case11_m3_$tag');
        semantics.dispose();
      });
    }
  });

  test('Case 11 Mission 02: the first tip walks the written word from right to left', () {
    final m2 = m('ep11_m2');
    final written = m2.letter.split('\n').first;
    expect(written, 'THGINDIM');
    // How to read it is not on the mask (2026-10-23, approved): the child
    // finds it out; tip 1 walks it.
    expect(m2.letter, 'THGINDIM');
    expect(m2.letter.toLowerCase(), isNot(contains('right to left')));
    expect(m2.hints.first, startsWith('Start with the last letter'));
    final reversed = written.split('').reversed.join();
    expect(reversed, m2.answer);
    // "Start with the last letter, M. Then go left: I, D, N..." — the letters
    // the tip names are the first letters of the word read right to left.
    final tip = m2.hints.first;
    final named = RegExp(r'\b([A-Z])\b').allMatches(tip).map((x) => x.group(1)!).toList();
    expect(named, isNotEmpty);
    expect(named.first, written[written.length - 1], reason: 'the last letter of $written');
    expect(named.join(), reversed.substring(0, named.length), reason: tip);
    expect(AnswerChecker.isCorrect(m2, reversed), isTrue);
    expect(AnswerChecker.isCorrect(m2, written), isFalse);
  });

  test('the slips of Case 09-11', () {
    expect(AnswerChecker.feedbackFor(m('ep09_m1'), 'a'), contains('small and silver'));
    expect(AnswerChecker.feedbackFor(m('ep09_m2'), 'amma'), contains('AFTER M'));
    expect(AnswerChecker.feedbackFor(m('ep09_m3'), '10'), contains('second change'));
    expect(AnswerChecker.feedbackFor(m('ep09_final'), 'green bag'), contains("Ben's bag"));
    expect(AnswerChecker.feedbackFor(m('ep10_m2'), 'bridge,north,three,tower'), contains('order of your notes'));
    expect(AnswerChecker.feedbackFor(m('ep10_final'), 'midnight,clockmaker,stop,bigben'), contains('WHEN comes last'));
    expect(AnswerChecker.feedbackFor(m('ep10_final'), 'stop,clockmaker,bigben,midnight'), m('ep10_final').orderFeedback);
    expect(AnswerChecker.feedbackFor(m('ep11_m2'), 'thgindim'), contains('right to left'));
    expect(AnswerChecker.feedbackFor(m('ep11_final'), 'b'), contains('the very start'));
  });

  // The season count includes Wave 1's 03-M1 (a search: essential).
  // The season was 42 of 50 until Case 01 M3 was read for its traces
  // (2026-10-19: essential → helpful, see learning_objectives_test).
  test('Essential: Case 09-11 has 9 of 12; the season 41 of 50', () {
    final essential = missions.values.where((x) => learningOf(x)!.dependency == LanguageDependency.essential);
    expect(essential, hasLength(9));
    expect(all.values.where((x) => learningOf(x)!.dependency == LanguageDependency.essential), hasLength(41));
  });

  test('XP rule 4 holds: Case 10 with tips and wrong orders is 3 × 30 + 60', () async {
    final container = ProviderContainer(overrides: await testOverrides());
    addTearDown(container.dispose);
    container.read(gameControllerProvider.notifier).createDetective('KIM', DetectiveAvatar.boy);
    for (final id in ['ep01', 'ep02', 'ep03', 'ep04', 'ep05', 'ep06', 'ep07', 'ep08', 'ep09']) {
      container.read(seasonProvider.notifier).markSolved(id);
    }
    expect(container.read(gameControllerProvider.notifier).openEpisode('ep10'), isTrue);
    final c = container.read(gameControllerProvider.notifier);
    c.startInvestigation();
    c.submitAnswer(m('ep10_m1'), 'a');
    c.submitAnswer(m('ep10_m1'), 'c');
    c.useHint(m('ep10_m2'));
    c.useHint(m('ep10_m2'));
    c.submitAnswer(m('ep10_m2'), 'north,tower,bridge,three');
    c.submitAnswer(m('ep10_m3'), 'b');
    c.submitAnswer(m('ep10_m3'), 'c');
    c.submitAnswer(m('ep10_final'), 'midnight,clockmaker,stop,bigben');
    c.submitAnswer(m('ep10_final'), 'clockmaker,stop,bigben,midnight');
    final p = container.read(gameControllerProvider);
    expect(p.isCaseSolved, isTrue);
    expect(XpBreakdown.totalFor(cases[1], p), 3 * 30 + 60);
  });
}
