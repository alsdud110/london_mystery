import 'package:flutter/foundation.dart';

/// What a word of a [CipherNote] is, when tapped.
enum CipherWord {
  /// A secret number: a number word in BIG letters ("FOUR").
  secret,

  /// A number word that is not in BIG letters ("three"): not part of the
  /// code.
  trap,

  /// Any other word.
  plain,
}

/// A mission whose note is decoded on the page (the presentation of the
/// mission's puzzle, never saved): the secret number words are circled in
/// pencil, each is turned into its number, and then the code is typed on
/// the mission's own keypad and checked as its answer, through the same
/// check, feedback, save and rewards as before. Circling and turning words
/// into numbers is never a wrong answer.
@immutable
class CipherNote {
  const CipherNote({
    required this.secrets,
    required this.task,
    required this.lockTask,
    required this.trapLine,
    required this.plainLine,
    required this.pickWrongLine,
  });

  /// The secret words, as written in the note, and the number each is.
  final Map<String, int> secrets;

  /// What to do on the note, then once every secret word is a number
  /// ([lockTask]).
  final String task;
  final String lockTask;

  /// Said for a number word not in BIG letters, and for any other word.
  final String trapLine;
  final String plainLine;

  /// Said when a wrong number is picked for a word (`{word}`: the word).
  final String pickWrongLine;

  /// The number words a trap can be (never the code).
  static const numberWords = {
    'zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten', 'eleven', 'twelve',
  };

  /// [token] without the punctuation around it ("o'clock." → "o'clock").
  static String bare(String token) => token.replaceAll(RegExp(r"^[^A-Za-z0-9']+|[^A-Za-z0-9']+$"), '');

  /// What the word [token] is.
  CipherWord kindOf(String token) {
    final w = bare(token);
    if (secrets.containsKey(w)) return CipherWord.secret;
    if (numberWords.contains(w.toLowerCase())) return CipherWord.trap;
    return CipherWord.plain;
  }
}

/// How far the detective has got in a [CipherNote]: the secret words
/// circled (in the order found) and the number written for each. Kept by
/// the page while it is open; never saved.
class CipherProgress {
  final List<String> circled = [];
  final Map<String, int> numbers = {};

  bool isCircled(String word) => circled.contains(word);

  /// Every secret word circled and turned into its number: the lock is
  /// next.
  bool decoded(CipherNote note) => note.secrets.keys.every(numbers.containsKey);
}
