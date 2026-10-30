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

/// Finals whose number lock is set on a clock's hands (presentation only,
/// as [season1Clocks]): the time set is the lock's typed answer ("917").
const Map<String, ClockPuzzle> season1FinalClocks = {
  // ── Case 02 Final — inside Big Ben ───────────────────────────────────
  // The gear is back: the detective sets the Great Clock to the thief's
  // time, worked out from the stopped time and the plan's "one hour after".
  // Its hands start where they froze (8:17, known since Mission 01), never
  // at the answer; the face is the case's own, so the final's stage shows
  // it only once solved, turning on to the time set.
  'ep02_final': ClockPuzzle(
    face: Artwork.clockFace,
    question: 'Set the time on the Great Clock.',
    lead: 'The hands are frozen where the clock stopped. Move them to the thief\'s time.',
    guide: 'Drag the short hand for the hour and the long hand for the minutes.',
    dialLabel: "Big Ben's Great Clock",
    start: (hour: 8, minute: 17),
    submitLabel: 'START THE CLOCK',
  ),
};

/// The clock of [m], or null when [m] is played through its puzzle.
ClockPuzzle? clockPuzzleOf(Mission m) => season1Clocks[m.id];
