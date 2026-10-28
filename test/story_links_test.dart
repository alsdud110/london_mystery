import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/data/mock/season1/season1_inspections.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/features/mission/widgets/lens_inspect.dart' show noteLines;

import 'helpers.dart';

/// Story links a child can follow (2026-10-23, approved):
/// - Case 01 M2: the golden key's tag names the next stop ("where London's
///   biggest bell rings"), and the bell rings after the case: Big Ben. ROOM 4
///   stays the final lock's number.
/// - Case 04 M2: the card says RED · SMALL · CLOCK · PLATFORM; the porter's
///   four lines leave one platform with all three: Platform 4, the one Case
///   12 needs.
void main() {
  final season = season1Cases();
  Mission m(String id) => season.expand((e) => e.allMissions).firstWhere((x) => x.id == id);
  const tag = "My next stop is where London's biggest bell rings.";

  group('Case 01 M2: the key\'s tag, then the bell', () {
    final m02 = m('m02');
    final key = season1Inspections['m02']!.spots.firstWhere((s) => s.id == 'plinth');

    test('the tag is read where the key is found, and kept in the notebook with ROOM 4', () {
      expect(key.line, allOf(contains('ROOM 4 is cut into it.'), contains(tag)));
      expect((m02.evidence!.id, m02.evidence!.name), ('e02', 'Golden Key'));
      expect(m02.evidence!.inscription, allOf(startsWith('ROOM 4'), contains(tag)));
      expect(m02.clue!.value, '4', reason: 'the final lock still needs 4');
    });

    test('the scene after it reads the bell as Big Ben; the note, the answer and the final stay', () {
      expect(m02.transition, [
        'The old stone shines in the dark.',
        'Ding dong! Far away, a big bell rings.',
        "London's biggest bell… It must be Big Ben!",
      ]);
      expect(noteLines(m02), hasLength(4), reason: 'THE NOTE keeps its four lines');
      expect(m02.letter, isNot(contains('bell')));
      expect(m02.answer, 'STONE');
      expect(m('m03').location, 'BIG BEN');
      expect(season.first.finalMission.answer, '7924');
      expect(season.first.finalMission.story.first, contains('behind the secret door'));
    });
  });

  group('Case 07 M3: two lines, one order', () {
    final m3 = m('ep07_m3');
    const pieces = ['station', 'park', 'river'];
    List<List<String>> orders() => [
          for (final a in pieces)
            for (final b in pieces)
              for (final c in pieces)
                if ({a, b, c}.length == 3) [a, b, c],
        ];
    bool riverNotTop(List<String> o) => o.first != 'river';
    bool apart(List<String> o) => (o.indexOf('station') - o.indexOf('river')).abs() > 1;

    test('the letter gives the two lines, never where a piece goes', () {
      expect(m3.letter.split('\n'), [
        'Put me together, from the top to the bottom.',
        'The river piece is not at the top.',
        'The station piece and the river piece do not touch.',
      ]);
      for (final placed in ['goes at the top', 'goes at the bottom', 'in the middle']) {
        expect(m3.letter, isNot(contains(placed)));
      }
    });

    test('each line alone leaves more than one order; both leave only the answer', () {
      expect(orders(), hasLength(6));
      expect(orders().where(riverNotTop), hasLength(4));
      expect(orders().where(apart), hasLength(2));
      final both = orders().where((o) => riverNotTop(o) && apart(o)).toList();
      expect(both, [['station', 'park', 'river']]);
      expect(m3.answer, 'station,park,river');
    });

    test('every wrong order says which line it breaks', () {
      for (final o in orders()) {
        final key = o.join(',');
        if (key == m3.answer) continue;
        final line = m3.feedback[key];
        expect(line, isNotNull, reason: key);
        expect(line, !riverNotTop(o) ? allOf(contains('river piece'), contains('at the top')) : contains('touch'), reason: key);
      }
      final lines = [for (final o in orders()) ?m3.feedback[o.join(',')]];
      expect(lines.toSet(), hasLength(5), reason: 'each wrong order its own line');
    });

    test('the tips lead to the two lines, not to the order', () {
      expect(m3.hints, [
        'Start with the two pieces that do not touch. Where can they go?',
        'Pieces that do not touch are at the top and the bottom. Which one is NOT at the top?',
      ]);
      for (final h in m3.hints) {
        expect(h.toLowerCase(), isNot(contains('station')), reason: h);
      }
      expect((m3.clue!.title, m3.evidence!.id), ('North to South', 'ep07_e3'));
    });
  });

  group('Case 06 M3: the market witnesses saw Monday\'s man', () {
    final m1 = m('ep06_m1'), m2 = m('ep06_m2'), m3 = m('ep06_m3'), fin = m('ep06_final');

    test("the Witness Notes match Monday only; the coat both wear tells nobody apart", () {
      final notes = m1.evidence!.inscription!.toLowerCase(); // Dark coat · grey hat · small bag
      expect(notes, allOf(contains('dark coat'), contains('grey hat'), contains('small bag')));
      final monday = m3.letter.split('TUESDAY').first.toLowerCase();
      final tuesday = m3.letter.split('TUESDAY').last.toLowerCase();
      for (final d in ['grey hat', 'small bag']) {
        expect(monday, contains(d), reason: d);
        expect(tuesday, isNot(contains(d)), reason: d);
      }
      expect(monday, contains('dark coat'));
      expect(tuesday, contains('dark coat'), reason: 'the one detail on both nights');
      expect((m3.type, m3.answer, m3.answerLabel), (MissionType.multipleChoice, 'a', 'Monday: a tall man, a grey hat, a small bag'));
      expect(m3.options.firstWhere((o) => o.id == 'b').feedback, contains('witness notes'));
      expect(m3.options.firstWhere((o) => o.id == 'c').feedback, contains('cannot tell them apart'));
      expect(m3.hints.first, contains('Witness Notes'));
    });

    test("Monday's man is the card's Inspector Grey; Tuesday's woman is someone else, never called the thief", () {
      // M1: the stranger with the small bag drops the card; M2: his name is
      // the colour of his hat.
      expect(m1.transition.join(' '), allOf(contains('small bag'), contains('drops a small card')));
      expect(m2.answer, 'GREY');
      expect(m2.letter, contains('the colour of my hat'));
      // M3: Tuesday's woman drops the ticket with the raven: the Society's mark.
      expect(m3.transition, contains('On the back, a black raven is stamped: the mark of the Raven Society.'));
      expect((m3.clue!.id, m3.evidence!.id, m3.evidence!.name), ('ep06_c3', 'ep06_e3', 'Theatre Ticket'));
      for (final line in [m3.question, m3.successMessage, for (final o in m3.options) ?o.feedback, ...m3.hints]) {
        expect(line.toLowerCase(), isNot(contains('thief')), reason: line);
      }
      // The final still stands on it.
      expect((fin.answer, fin.answerLabel), ('c', 'Inspector Grey'));
      expect(fin.options.firstWhere((o) => o.id == 'a').feedback, allOf(contains('short woman'), contains('big bag')));
    });
  });

  group('Case 07 final: Grey\'s way and the map\'s arrow, together', () {
    final m3 = m('ep07_m3'), fin = m('ep07_final');

    test('the joined map gives the direction, never the spot', () {
      expect(m3.evidence!.inscription, 'An arrow points north, to the top of the park.');
      expect(m3.evidence!.inscription!.toLowerCase(), isNot(contains('gate')));
      expect(m3.clue!.note, contains('Station at the top'), reason: 'north is the top, as the pieces were laid');
    });

    test("Grey's way alone leaves two maps; the arrow's north leaves one", () {
      expect(fin.letter, allOf(contains('Go past the tree.'), contains('turn left')));
      final byId = {for (final o in fin.options) o.id: o};
      // Grey rules out two: the right bench (not left) and the tree (go past).
      expect(byId['c']!.feedback, contains('LEFT'));
      expect(byId['d']!.feedback, contains('PAST the tree'));
      // Two are left after the bridge: the left bench and the old gate; the
      // arrow (north, the top of the park) picks the gate.
      expect(byId['a']!.label, 'Beside the left bench');
      expect(byId['a']!.feedback, contains('arrow'));
      expect((fin.answer, byId['b']!.label, byId['b']!.artwork), ('b', 'At the old gate', Artwork.parkMapD));
      expect(fin.hints, [
        'Use both clues: Inspector Grey’s directions and the arrow on your joined map.',
        "Grey's way leaves two places. Which one is at the top of the park, where the arrow points?",
      ]);
      expect(fin.evidence!.id, 'ep07_e4');
    });
  });

  group('Case 04 M2: red, small, clock', () {
    final m2 = m('ep04_m2');

    test('the card says the same everywhere, and never the number', () {
      const card = 'RED · SMALL · CLOCK · PLATFORM';
      expect(m2.story.first, 'The card says: $card.');
      expect(m2.letter, endsWith('Your card says: $card.'));
      expect(m2.evidence!.inscription, card);
      for (final text in [...m2.story, m2.letter, ...m2.hints, m2.evidence!.inscription!]) {
        expect(text, isNot(contains('FOUR')), reason: text);
      }
    });

    test("the porter's lines leave one platform that is red, small and a clock: Platform 4", () {
      final lines = m2.letter.split('\n').where((l) => l.startsWith('Platform')).toList();
      expect(lines, hasLength(4));
      final fits = [
        for (final l in lines)
          if (l.contains('small red clock')) l,
      ];
      expect(fits, ['Platform 4 has a small red clock.']);
      expect(lines, contains('Platform 7 has a red door, but no clock.'), reason: 'red, but no clock');
      expect(m2.answerLabel, 'Platform 4');
      expect((m2.clue!.value, m2.evidence!.id), ('4', 'ep04_e2'));
      // Case 12 still asks for the platform with the small red clock.
      expect(m('ep12_m2').letter.replaceAll('\n', ' '), contains('the platform with the small red clock'));
    });
  });
}
