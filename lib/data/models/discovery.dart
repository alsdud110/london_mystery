import 'package:flutter/foundation.dart';

import 'mission.dart';

/// What solving a regular mission gave the detective, as the Discovery
/// Moment names it. Presentation only: nothing here is saved.
enum DiscoveryType {
  /// A real object or paper, newly in the detective's hands.
  evidenceFound('EVIDENCE FOUND', 'Clue Discovered!'),

  /// A fact needed later, found by solving the puzzle.
  clueFound('CLUE FOUND', 'Clue Discovered!'),

  /// A fact the detective had already seen before the puzzle, now made
  /// sure of. Never called "found".
  clueConfirmed('CLUE CONFIRMED', 'Excellent Detective Work!'),

  /// A conclusion the puzzle worked out.
  deduction('DEDUCTION', 'Brilliant Deduction!'),

  /// The next place or person.
  newLead('NEW LEAD', 'You Made It!'),

  /// An important fact about the case.
  storyDiscovery('STORY DISCOVERY', 'Excellent Detective Work!'),

  /// Nothing to show beyond the solved puzzle (also the fallback).
  puzzleComplete('PUZZLE COMPLETE', 'You Made It!');

  const DiscoveryType(this.label, this.cheer);

  /// What kind of discovery it is, in words (read out with the moment).
  final String label;

  /// The line that greets the solve, first and largest on the Discovery
  /// Moment. Like [label] it keeps the timing rule: what was seen before
  /// the puzzle is never "discovered".
  final String cheer;
}

/// When the detective first had the discovery's information: before the
/// puzzle (seen in the place or the letter), from the puzzle itself, or only
/// in the scene after it. Only what comes from the puzzle may be "found".
enum DiscoveryTiming { beforePuzzle, fromPuzzle, afterPuzzle }

/// The Discovery Moment of one regular mission: what the detective just
/// found or worked out, said once.
@immutable
class Discovery {
  const Discovery({
    required this.type,
    required this.timing,
    required this.title,
    required this.detail,
    this.showEvidence = false,
    this.seasonClue = false,
    this.note,
  });

  final DiscoveryType type;
  final DiscoveryTiming timing;

  /// The discovery itself, in a few words (the largest line).
  final String title;

  /// One short supporting sentence.
  final String detail;

  /// Lay the mission's evidence (picture, name, what is written on it) on
  /// screen. Only for evidence the puzzle itself puts in the detective's
  /// hands: never one seen before the puzzle, nor one the next scene hands
  /// over.
  final bool showEvidence;

  /// Also a clue to the season's mystery (the ravens, the Clockmaker).
  final bool seasonClue;

  /// A fact seen before the puzzle that the notebook keeps for later
  /// (e.g. "Room 4"): shown small, as noted, not as found.
  final String? note;

  /// The moment for a mission that has no Discovery of its own: its success
  /// line, as a solved puzzle.
  factory Discovery.fallback(Mission m) => Discovery(
        type: DiscoveryType.puzzleComplete,
        timing: DiscoveryTiming.fromPuzzle,
        title: m.successMessage,
        detail: '',
      );
}
