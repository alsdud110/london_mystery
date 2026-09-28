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

  test('number code and final code', () {
    expect(AnswerChecker.isCorrect(byId['m03']!, '417'), isTrue);
    expect(AnswerChecker.isCorrect(byId['m03']!, '147'), isFalse);
    expect(AnswerChecker.isCorrect(byId['final']!, '7924'), isTrue);
    expect(AnswerChecker.isCorrect(byId['final']!, '0000'), isFalse);
  });

  test('QR payload accepts scanned or typed code', () {
    final m = byId['m05']!;
    expect(AnswerChecker.isCorrect(m, 'LM-EP01-PALACE'), isTrue);
    expect(AnswerChecker.isCorrect(m, 'lm-ep01-palace'), isTrue);
    expect(AnswerChecker.isCorrect(m, 'https://example.com'), isFalse);
  });
}
