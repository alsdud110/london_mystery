import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';

/// Case 01 M4 was made to match the palace artwork (commit 3ea9964): the
/// note's description, option a's feedback and the two tips. Its new words
/// got meanings later (QA 2026-10-13). The hash guards in
/// final_small_pass_test.dart and audit_fix_d4_d5_test.dart were updated for
/// exactly this; these tests pin what changed, so nothing else in Case 01
/// can hide behind the new hashes. (No git history needed.)
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

  test('Case 01 is commit 3ea9964 plus those three meanings, nothing else', () {
    final json = ep01.toJson();
    final glossary = Map<String, dynamic>.of(json['glossary'] as Map<String, dynamic>)
      ..remove('flag')
      ..remove('flies')
      ..remove('fountain');
    expect(fnv(jsonEncode({...json, 'glossary': glossary})), 433367548);
  });
}
