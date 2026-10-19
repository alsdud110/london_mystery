import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/core/utils/answer_checker.dart';

import 'helpers.dart';

void main() {
  final byId = {for (final m in episode01.allMissions) m.id: m};

  test('multiple choice matches option id exactly', () {
    expect(AnswerChecker.isCorrect(byId['m01']!, 'b'), isTrue);
    expect(AnswerChecker.isCorrect(byId['m01']!, 'a'), isFalse);
  });

  test('word input ignores case, spaces and punctuation', () {
    final m = byId['m02']!;
    for (final ok in ['STONE', 'stone', ' Stone! ', 'rosetta stone']) {
      expect(AnswerChecker.isCorrect(m, ok), isTrue, reason: ok);
    }
    for (final bad in ['', '   ', 'ROCK', 'STONES']) {
      expect(AnswerChecker.isCorrect(m, bad), isFalse, reason: bad);
    }
  });

  test('the box at Big Ben (a place chosen) and the final code', () {
    expect(AnswerChecker.isCorrect(byId['m03']!, 'b'), isTrue);
    expect(AnswerChecker.isCorrect(byId['m03']!, 'a'), isFalse);
    expect(AnswerChecker.isCorrect(byId['final']!, '7924'), isTrue);
    expect(AnswerChecker.isCorrect(byId['final']!, '0000'), isFalse);
  });

  // M5 is a card examined in its scene (2026-10-19): the scene sends the
  // mission's own answer once the card is taken; nothing is typed or
  // scanned, and the old QR code no longer solves it.
  test('the crown card (examined): only the scene\'s own answer solves it', () {
    final m = byId['m05']!;
    expect(AnswerChecker.isCorrect(m, m.answer), isTrue);
    expect(AnswerChecker.isCorrect(m, 'LM-EP01-PALACE'), isFalse);
    expect(AnswerChecker.isCorrect(m, '7924'), isFalse);
    expect(AnswerChecker.isCorrect(m, ''), isFalse);
  });
}
