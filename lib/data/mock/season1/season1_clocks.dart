import '../../models/clock_puzzle.dart';
import '../../models/mission.dart';

/// Missions played by setting the hands of a clock (presentation only:
/// nothing here is saved). Mission id → its [ClockPuzzle]. A mission not
/// listed is played through its puzzle as before.
///
/// The case data is left as it is: the time set is the keypad's answer
/// ("817"), so the check, the feedback for a known wrong time, the solve,
/// its Clue and Evidence, XP, coins and the save are the ones the puzzle
/// always gave.
const Map<String, ClockPuzzle> season1Clocks = {
  // ── Case 02 M1 — Westminster Bridge ──────────────────────────────────
  // Big Ben stays out of sight from the bridge (its stopped time is the
  // puzzle): Mrs Bell hands over a clock face, and the detective sets its
  // hands where her note says she saw them. The hands start at 12:00, never
  // at the answer, and nothing here writes a time.
  'ep02_m1': ClockPuzzle(
    face: Artwork.clockFace,
    question: 'What time did Big Ben stop? Set the hands.',
    lead: "Mrs Bell hands you her clock face. Put the hands where she saw them.",
    guide: 'Drag the short hand for the hour and the long hand for the minutes.',
    dialLabel: "Mrs Bell's clock face",
  ),
};

/// The clock of [m], or null when [m] is played through its puzzle.
ClockPuzzle? clockPuzzleOf(Mission m) => season1Clocks[m.id];
