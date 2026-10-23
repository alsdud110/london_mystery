import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/data/models/mission.dart';

import 'helpers.dart';

/// The free tip of a final that needs an earlier case's evidence says where
/// that evidence is kept — the notebook's CASE ARCHIVE, then the case's
/// file — never the answer (2026-10-23, approved): Case 08 (the Red Button
/// of Case 03) and Case 11 (the Old Letter of Case 01). Their tip 2, answer
/// and wrong-answer lines are as they were.
void main() {
  final season = season1Cases();
  Mission m(String id) => season.expand((e) => e.allMissions).firstWhere((x) => x.id == id);

  test('Case 08 final: tip 1 leads to Case 03 in the Case Archive, and names no evidence', () {
    final f = m('ep08_final');
    expect(f.hints.first,
        "Think back to an earlier case. Gallery 8 was in Case 03. Open your notebook, then the Case Archive, then Case 03: what was left in Gallery 8?");
    for (final answer in ['button', 'red', 'coat', 'luggage', 'tag']) {
      expect(f.hints.first.toLowerCase(), isNot(contains(answer)), reason: answer);
    }
    expect(f.hints.last, allOf(contains('Case Archive'), contains('Case 03')), reason: 'tip 2 as it was');
    expect((f.answer, f.answerLabel), ('c', 'Red Button'));
    // Case 03's Gallery 8 holds the Red Button the tip leads to.
    final gallery = m('ep03_m1');
    expect(gallery.location, 'GALLERY 8');
    expect(gallery.evidence!.name, 'Red Button');
  });

  test('Case 11 final: tip 1 leads to Case 01 in the Case Archive, and names nobody', () {
    final f = m('ep11_final');
    expect(f.hints.first,
        "'The very start' means your first case. Open your Case Archive, then Case 01. What did you find in a suitcase there?");
    for (final answer in ['shadow', 'signed', 'letter']) {
      expect(f.hints.first.toLowerCase(), isNot(contains(answer)), reason: answer);
    }
    expect(f.hints.last, contains('Case 01'), reason: 'tip 2 as it was');
    expect((f.answer, f.answerLabel), ('d', 'The Shadow'));
    // Case 01's suitcase holds the letter the tip leads to.
    final suitcase = m('m01');
    expect(suitcase.story.join(' '), contains('suitcase'));
    expect(suitcase.evidence!.inscription, contains('Signed: The Shadow'));
  });
}
