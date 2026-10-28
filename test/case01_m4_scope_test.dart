import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/data/repositories/episode_repository.dart';
import 'personalized_lines.dart';

/// Case 01 M4 was made to match the palace artwork (commit 3ea9964): the
/// note's description, option a's feedback and the two tips. Its new words
/// got meanings later (QA 2026-10-13). The hash guards in
/// final_small_pass_test.dart and audit_fix_d4_d5_test.dart were updated for
/// exactly this; these tests pin what changed, so nothing else in Case 01
/// can hide behind the new hashes. (No git history needed.) Since then, only
/// M1's tip 2 (the season copy pass, 2026-10-16), pinned below too.
void main() {
  final ep01 = MockEpisodeRepository.bundled().firstWhere((e) => e.id == 'ep01');
  final m4 = ep01.missionById('m04')!;

  int fnv(String s) {
    var h = 0x811c9dc5;
    for (final c in utf8.encode(s)) {
      h = ((h ^ c) * 0x01000193) & 0xffffffff;
    }
    return h;
  }

  test('M4: the note describes what the artwork shows', () {
    expect(
      m4.letter,
      'My last stop is a big palace.\n'
      'A red flag flies on top.\n'
      'There is a fountain in front.\n'
      'The King lives there!',
    );
    expect(m4.options.firstWhere((o) => o.id == 'a').feedback,
        'That is a bridge over a river. The note talks about a palace and a fountain.');
    expect(m4.hints, [
      'Look for a big building with a red flag and a fountain.',
      'The King lives in a palace. Find the fountain in front of it.',
    ]);
  });

  test('M4: its new words have meanings', () {
    expect(ep01.meaningOf('flag'), '깃발');
    expect(ep01.meaningOf('flies'), '(깃발이) 휘날리다');
    expect(ep01.meaningOf('fountain'), '분수');
  });

  // The season copy pass (approved 2026-10-16): M1's tip 2 points to what
  // the letter's two things are not, and asks the child to find the museum
  // (no new words: its words all have meanings already).
  test('M1: tip 2 says what to look for again, not which museum', () {
    final m1 = ep01.missionById('m01')!;
    expect(m1.hints, [
      'Read the letter again. What two things does the next museum have?',
      'Mummies and a famous stone are not dinosaur bones, buses or rockets. Which museum has old things like these?',
    ]);
    expect(m1.hints.last, isNot(contains('British')));
    expect(m1.hints.last, isNot(contains('treasures')), reason: 'the right card\'s own word');
    for (final w in ['mummies', 'famous', 'stone', 'dinosaur', 'bones', 'buses', 'rockets']) {
      expect(ep01.meaningOf(w), isNotNull, reason: w);
    }
  });

  test('Case 01 is commit 3ea9964 plus those three meanings and M1 tip 2, nothing else', () {
    final json = ep01.toJson();
    final glossary = Map<String, dynamic>.of(json['glossary'] as Map<String, dynamic>)
      ..remove('flag')
      ..remove('flies')
      ..remove('fountain');
    // Was 433367548 before M1 tip 2 (2026-10-16, pinned above).
    // The letters that name the detective are read as they were (2026-10-17).
    // Was 1590700020 before M3 was redesigned as the foot of Big Ben read
    // for its traces (2026-10-19, requested; see case01_deduction_test).
    // Was 376694330 before M5 was redesigned as the crown card examined on
    // the device, no QR code (2026-10-19, requested; see case01_decode_test).
    // Was 1565212565 before its hidden message was shortened (same day,
    // requested). Was 2004498282 before the final's box was found behind
    // the secret door Mission 05 opens (2026-10-23, approved). Was
    // 3339709869 before the golden key's tag named the next stop, the bell,
    // and M2's scene after it read the bell as Big Ben (same day, approved).
    expect(fnv(withoutNames(jsonEncode({...json, 'glossary': glossary}))), 3330943963);
  });
}
