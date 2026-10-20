import '../../models/cipher_note.dart';
import '../../models/mission.dart';

/// Missions whose note is decoded on the page (presentation only: nothing
/// here is saved). Mission id → its [CipherNote]. A mission not listed is
/// played as before.
///
/// The case data is left as it is: the note is the mission's letter, word
/// for word; the code is typed on its own keypad and checked as its answer,
/// so the feedback for the right numbers in the wrong order, the hints, the
/// solve, its Clue and Evidence, XP, coins and the save are the ones the
/// puzzle always gave.
const Map<String, CipherNote> season1Ciphers = {
  // ── Case 01 M3 — the box at the foot of Big Ben ─────────────────────────
  // The note's code is in its three number words in BIG letters (FOUR, ONE,
  // SEVEN); "three sentences" and "at one o'clock" are number words too,
  // not in BIG letters: not the code. Each circled word is turned into its
  // number by the detective (never shown), then the numbers go on the lock
  // in the order of the sentences (417), typed by the detective.
  'm03': CipherNote(
    secrets: {'FOUR': 4, 'ONE': 1, 'SEVEN': 7},
    task: 'Tap the secret number words in the note.',
    lockTask: 'Now open the lock. Put the numbers in order!',
    trapLine: 'A number word, but not in BIG letters.',
    plainLine: 'Not a secret number. Look for BIG letters.',
    pickWrongLine: 'Not quite. Count in English: one, two, three… Which number is {word}?',
  ),
};

/// The note of [m] to decode, or null when [m] is played as before.
CipherNote? cipherOf(Mission m) => season1Ciphers[m.id];
