import '../../models/discovery.dart';
import '../../models/mission.dart';

/// The Discovery Moment of [m]: its own, or a solved puzzle for a mission
/// without one.
Discovery discoveryOf(Mission m) => season1Discoveries[m.id] ?? Discovery.fallback(m);

/// Regular missions whose evidence is handed over in the scene after the
/// puzzle (the guard gives the theatre ticket, the Ravenmaster his letter),
/// not by the puzzle itself: the scene lays it down as a card once its lines
/// are read. Presentation only: the evidence is saved with the answer, as
/// every evidence is.
const Set<String> season1StoryEvidence = {'ep06_m3', 'ep10_m3'};

/// The evidence the scene after [m] hands over, if any.
Evidence? storyEvidenceOf(Mission m) => season1StoryEvidence.contains(m.id) ? m.evidence : null;

/// The Discovery Moment of every regular mission of Season 1, by mission id.
///
/// Each one says what solving that puzzle gave the detective, once (no
/// success line and clue saying the same thing twice), and only what the
/// detective really has at that moment:
/// - evidence seen before the puzzle (the letter in the suitcase, the seal,
///   the name tag) is never "found": the moment confirms it or names the
///   deduction instead;
/// - evidence the next scene hands over (Case 06's theatre ticket, Case
///   10's letter) is left to that scene;
/// - a clue that was not found in the mission (Case 12's seven ravens) is
///   not shown.
/// Lines are the cases' own facts; nothing new is told here, and nothing
/// the next scene tells is told first.
const Map<String, Discovery> season1Discoveries = {
  // ── Case 01 — The Missing Crown ─────────────────────────────────────
  'm01': Discovery(
    type: DiscoveryType.newLead,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'THE BRITISH MUSEUM',
    detail: 'Old mummies and a famous stone: the thief is going to the big museum.',
    note: 'The suitcase stood next to Platform 9.',
  ),
  'm02': Discovery(
    type: DiscoveryType.deduction,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'THE ROSETTA STONE',
    detail: 'The stone that helped people read old Egyptian writing.',
    note: 'The stone is in Room 4.',
  ),
  'm03': Discovery(
    type: DiscoveryType.evidenceFound,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'POCKET WATCH',
    detail: 'The lock clicks open. The thief left a watch inside the box.',
    showEvidence: true,
  ),
  'm04': Discovery(
    type: DiscoveryType.newLead,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'BUCKINGHAM PALACE',
    detail: "Soldiers in red coats, and the King lives there: the thief's last stop.",
    note: 'Two white swans were swimming on the lake.',
  ),
  'm05': Discovery(
    type: DiscoveryType.evidenceFound,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'CROWN SYMBOL',
    detail: 'The golden crown code opens the last door, and a card with four pictures.',
    showEvidence: true,
  ),

  // ── Case 02 — The Silent Clock ──────────────────────────────────────
  'ep02_m1': Discovery(
    type: DiscoveryType.deduction,
    timing: DiscoveryTiming.fromPuzzle,
    title: '8:17',
    detail: 'The hour hand between eight and nine, the minutes at seventeen: the moment Big Ben stopped.',
  ),
  'ep02_m2': Discovery(
    type: DiscoveryType.evidenceFound,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'SMALL BRASS GEAR',
    detail: 'Under the smallest bell: the gear that stopped Big Ben.',
    showEvidence: true,
    seasonClue: true,
  ),
  'ep02_m3': Discovery(
    type: DiscoveryType.deduction,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'GALLERY 8 · PICTURE 17',
    detail: 'The stopped clock was a message: the hour is the gallery, the minutes are the picture.',
  ),

  // ── Case 03 — The Vanishing Painting ────────────────────────────────
  // The guard's report named all three things before the puzzle: the
  // footprint is confirmed, the button noted; both are picked up in the
  // scene after.
  'ep03_m1': Discovery(
    type: DiscoveryType.clueConfirmed,
    timing: DiscoveryTiming.beforePuzzle,
    title: 'A WET FOOTPRINT',
    detail: 'It is next to the door: the way the thief went out.',
    note: 'A red button from a coat was under the bench.',
  ),
  'ep03_m2': Discovery(
    type: DiscoveryType.deduction,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'MISS ROSE',
    detail: 'A red coat and a blue scarf: the button and the cloth both point to her.',
  ),
  'ep03_m3': Discovery(
    type: DiscoveryType.clueFound,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'THE NORTH DOOR',
    detail: 'From the wettest step to the driest: she left by the north door.',
    showEvidence: true,
  ),

  // ── Case 04 — The Secret Letter ─────────────────────────────────────
  // The seal was broken before the puzzle: noted, never found.
  'ep04_m1': Discovery(
    type: DiscoveryType.newLead,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'THE PLATFORMS',
    detail: 'Open day and night: the place where trains never sleep.',
    note: 'The letter was closed with a black wax seal.',
  ),
  'ep04_m2': Discovery(
    type: DiscoveryType.clueFound,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'PLATFORM 4',
    detail: 'Red, four, clock, platform: the small red clock on Platform 4.',
  ),
  'ep04_m3': Discovery(
    type: DiscoveryType.newLead,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'THE TOWER OF LONDON',
    detail: 'An old castle by the river with four towers: the letter came from there.',
  ),

  // ── Case 05 — The Locked Room ───────────────────────────────────────
  'ep05_m1': Discovery(
    type: DiscoveryType.newLead,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'THIRD FLOOR, ON THE RIGHT',
    detail: 'Left at the old cannon, up the stairs: the way to the locked room.',
    note: "The Tower gates close at five o'clock.",
  ),
  'ep05_m2': Discovery(
    type: DiscoveryType.newLead,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'THE DOOR IS OPEN',
    detail: 'Left, right, left, right: the dial turns, and the room is open.',
    note: 'Four brass gears were set around the dial.',
  ),
  'ep05_m3': Discovery(
    type: DiscoveryType.evidenceFound,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'BRASS KEY',
    detail: 'Seven ravens: the food box opens. A key was hidden inside.',
    showEvidence: true,
    seasonClue: true,
  ),

  // ── Case 06 — The Midnight Detective ────────────────────────────────
  'ep06_m1': Discovery(
    type: DiscoveryType.deduction,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'A SMALL BAG',
    detail: 'Two witnesses agree: the stranger carried a small bag.',
  ),
  'ep06_m2': Discovery(
    type: DiscoveryType.deduction,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'INSPECTOR GREY',
    detail: 'The name on the wet card: London Detective Agency.',
  ),
  // The theatre ticket is handed over in the scene after: not shown here.
  'ep06_m3': Discovery(
    type: DiscoveryType.storyDiscovery,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'TWO DARK COATS',
    detail: 'Four things are different: Monday and Tuesday were two different people.',
  ),

  // ── Case 07 — The Lost Map ──────────────────────────────────────────
  'ep07_m1': Discovery(
    type: DiscoveryType.evidenceFound,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'RIVER MAP PIECE',
    detail: 'Right at the bridge, beside the bench: the first piece of the map.',
    showEvidence: true,
  ),
  'ep07_m2': Discovery(
    type: DiscoveryType.evidenceFound,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'STATION MAP PIECE',
    detail: 'Under the table, behind the green watering can.',
    showEvidence: true,
  ),
  'ep07_m3': Discovery(
    type: DiscoveryType.clueFound,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'THE JOINED MAP',
    detail: 'The three pieces fit. An arrow points north, to the top of the park.',
    // No card: what is written on it names the spot the final asks for.
    // The direction is told here; the map itself waits in the notebook.
  ),

  // ── Case 08 — The Mystery on Platform 9 ─────────────────────────────
  // The name tag was read before the puzzle: confirmed, never found.
  'ep08_m1': Discovery(
    type: DiscoveryType.clueConfirmed,
    timing: DiscoveryTiming.beforePuzzle,
    title: 'TO EDINBURGH, ALONE',
    detail: 'The name is washed away, but the city is not: ask every passenger where they are going.',
  ),
  'ep08_m2': Discovery(
    type: DiscoveryType.deduction,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'MRS ROBIN',
    detail: 'The only passenger going to Edinburgh alone.',
  ),
  'ep08_m3': Discovery(
    type: DiscoveryType.evidenceFound,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'THE RAVEN TOWER',
    detail: "Seat forty-two, the nine o'clock train: the lock opens on the missing painting.",
    showEvidence: true,
  ),

  // ── Case 09 — The Missing Jewel ─────────────────────────────────────
  'ep09_m1': Discovery(
    type: DiscoveryType.deduction,
    timing: DiscoveryTiming.fromPuzzle,
    title: "THE GUARD'S KEY",
    detail: 'Only the big gold key opens the jewel case.',
  ),
  'ep09_m2': Discovery(
    type: DiscoveryType.deduction,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'ANNA',
    detail: "The new helper's name: A, two Ns, A.",
  ),
  // A small fact, not a big reveal.
  'ep09_m3': Discovery(
    type: DiscoveryType.storyDiscovery,
    timing: DiscoveryTiming.fromPuzzle,
    title: "TWELVE O'CLOCK",
    detail: 'Eight, ten, twelve: Anna was seen at the third change of the guard.',
  ),

  // ── Case 10 — The London Raven ──────────────────────────────────────
  'ep10_m1': Discovery(
    type: DiscoveryType.evidenceFound,
    timing: DiscoveryTiming.fromPuzzle,
    title: "POPPY'S RING",
    detail: 'Poppy is the small, quiet raven with the gold ring. Letters are written inside it.',
    showEvidence: true,
  ),
  // The four words were on the papers before the puzzle: their order is
  // what was worked out.
  'ep10_m2': Discovery(
    type: DiscoveryType.clueConfirmed,
    timing: DiscoveryTiming.beforePuzzle,
    title: 'NORTH · TOWER · BRIDGE · THREE',
    detail: 'Monday, Tuesday, Wednesday, Thursday: the words in the order Poppy brought them.',
  ),
  // The Ravenmaster's letter is given at the north tower, in the scene
  // after: not shown here.
  'ep10_m3': Discovery(
    type: DiscoveryType.newLead,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'TOWER BRIDGE',
    detail: "Two of Poppy's words, put together, are a place in London.",
  ),

  // ── Case 11 — The Masked Stranger ───────────────────────────────────
  // The whistle was in the actor's story before the puzzle; which stories
  // to trust is what was worked out.
  'ep11_m1': Discovery(
    type: DiscoveryType.clueConfirmed,
    timing: DiscoveryTiming.beforePuzzle,
    title: 'A TRAIN WHISTLE',
    detail: 'Two stories agree: a white mask and a long black cloak. And the actor heard a train whistle.',
  ),
  'ep11_m2': Discovery(
    type: DiscoveryType.deduction,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'MIDNIGHT',
    detail: 'Read from right to left, the word inside the mask is a time.',
  ),
  'ep11_m3': Discovery(
    type: DiscoveryType.newLead,
    timing: DiscoveryTiming.fromPuzzle,
    title: "KING'S CROSS",
    detail: 'Two big arches and a clock tower: the station the stranger ran to.',
  ),

  // ── Case 12 — The Midnight Case ─────────────────────────────────────
  'ep12_m1': Discovery(
    type: DiscoveryType.deduction,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'THE REAL GEAR',
    detail: 'Brass, eight teeth and the raven stamp: the only gear with all three.',
    showEvidence: true,
  ),
  'ep12_m2': Discovery(
    type: DiscoveryType.deduction,
    timing: DiscoveryTiming.fromPuzzle,
    title: '11:40 · PLATFORM 4',
    detail: 'The small red clock is on Platform 4: the train from Paris.',
  ),
  // Its saved clue (seven ravens) was not found here: not shown.
  'ep12_m3': Discovery(
    type: DiscoveryType.newLead,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'UNDER BIG BEN',
    detail: "Hands, a face, very tall, rings every hour: the Clockmaker's door is under Big Ben.",
  ),
};
