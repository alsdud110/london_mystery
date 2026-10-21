import 'dart:ui' show Offset, Rect;

import '../../models/scene_exhibit.dart' show EvidenceLink;
import '../../models/scene_explore.dart' show ScenePixels;
import '../../models/story_picture.dart';
import '../../models/tower_puzzles.dart';

/// Season 2, Case 03's missions played in their scenes (presentation only:
/// the case data is left as it is). Each table is keyed by mission id; the
/// answer, its feedback, the hints, the solve, its Clue and Evidence, XP,
/// coins and the save are the puzzle's own. Every place is measured on the
/// delivered picture (pixels, then fractions).

const _case03 = 'assets/seasons/season_02_paris/cases/case_03';

// ── M1 — the two records ────────────────────────────────────────────────
// The notice board at the tower's entrance (1536 × 1024): its blank cream
// notice, pinned at its four corners, from (295, 348) to (660, 665). The
// maintenance log (1254 × 1254, cut out): a clipboard, its ruled sheet's
// header box (322, 318)–(948, 402) and ruled lines down to 1060.
const _entrance = ScenePixels(1536, 1024);
const _clipboard = ScenePixels(1254, 1254);

final Map<String, RecordsScene> season2Records = {
  's2_ep03_m1': RecordsScene(
    first: RecordDoc(
      id: 'notice',
      name: 'THE VISITOR NOTICE',
      file: '$_case03/tower_notice_board.png',
      pixels: _entrance,
      crop: _entrance.rect(236, 286, 720, 716),
      writeOn: _entrance.rect(322, 376, 634, 640),
      title: 'VISITOR NOTICE',
      lines: const [
        RecordLine(id: 'date', label: 'DATE', value: '12 MAY'),
        RecordLine(id: 'job', label: 'JOB', value: 'LIFT INSPECTION'),
        RecordLine(id: 'time', label: 'TIME', value: '4:00 PM'),
      ],
      note: 'The lift will close for a short time.',
      label: 'The notice board at the entrance of the Eiffel Tower',
    ),
    second: RecordDoc(
      id: 'log',
      name: 'THE MAINTENANCE LOG',
      file: '$_case03/inspection_log.png',
      pixels: _clipboard,
      crop: _clipboard.rect(176, 8, 1132, 1232),
      writeOn: _clipboard.rect(334, 326, 944, 1040),
      title: 'MAINTENANCE LOG',
      lines: const [
        RecordLine(id: 'date', label: 'DATE', value: '12 MAY'),
        RecordLine(id: 'job', label: 'JOB', value: 'LIFT INSPECTION'),
        RecordLine(id: 'time', label: 'TIME', value: '3:00 PM'),
      ],
      note: 'CHECK THE LIFT LOG.',
      label: 'The maintenance log on a clipboard, a pencil beside it',
    ),
    readTask: 'Tap each record to read it.',
    compareTask: 'Tap the line on each record that does not match.',
    checkLabel: 'THESE DO NOT MATCH',
  ),
};

// ── M2 — the lift, its route plate and its log ───────────────────────────
// The lift (1536 × 1024): the brass route plate on the left wall, the log
// in its holder on the right. The plate (1024 × 1536): an engraved tower
// with four studs down its middle (the top, the second floor, the first,
// the ground) and one set apart at its right, joined by an engraved line
// to the second floor's: the Service Level. The log (1254 × 1254, cut
// out): an open ledger; the trips are written on its left page.
const _lift = ScenePixels(1536, 1024);
const _plate = ScenePixels(1024, 1536);
const _ledger = ScenePixels(1254, 1254);

final Map<String, LiftScene> season2Lifts = {
  's2_ep03_m2': LiftScene(
    picture: '$_case03/tower_lift.png',
    pixels: _lift,
    place: 'Inside the old lift: brass gates, wooden walls, Paris far below',
    plateArea: _lift.rect(52, 26, 302, 716),
    logArea: _lift.rect(1222, 300, 1468, 702),
    plate: '$_case03/lift_route_diagram.png',
    platePixels: _plate,
    stops: [
      LiftStop(id: 'top', name: 'TOP', at: _plate.at(512, 283)),
      LiftStop(id: 'second', name: 'SECOND', at: _plate.at(512, 572)),
      LiftStop(id: 'service', name: 'SERVICE LEVEL', at: _plate.at(705, 617), service: true),
      LiftStop(id: 'first', name: 'FIRST', at: _plate.at(512, 850)),
      LiftStop(id: 'ground', name: 'GROUND', at: _plate.at(512, 1160)),
    ],
    passengerRoute: const ['ground', 'first', 'second', 'top'],
    serviceRoute: const ['second', 'service'],
    legend: 'S = SERVICE RUN',
    legendAt: _plate.rect(170, 1340, 854, 1440),
    log: '$_case03/lift_log.png',
    logPixels: _ledger,
    // The left page, its leather edge and ribbon in view.
    logCrop: _ledger.rect(70, 190, 676, 1030),
    logWriteOn: _ledger.rect(152, 272, 590, 940),
    logTitle: 'LIFT LOG — 12 MAY',
    trips: const [
      LiftTrip(time: '3:05', from: 'Ground', to: 'First'),
      LiftTrip(time: '3:12', from: 'First', to: 'Second'),
      LiftTrip(time: '3:20', from: 'Second', to: '?', service: true),
      LiftTrip(time: '4:25', from: '?', to: 'Ground'),
    ],
    readTask: 'Tap the route plate and the lift log to read them.',
    chooseTask: 'Compare the log with the plate. Then choose the stop.',
  ),
};

// ── M3 — the padlock's three dials ──────────────────────────────────────
// The padlock (1536 × 1024, cut out): three round windows cut clean
// through its dial panel, measured on their transparent holes — centres
// (482.0, 671.1), (768.6, 671.3), (1055.2, 671.2), radius 78.3 — each
// under a fixed brass pointer. The dial (1254 × 1254, cut out): its centre
// hole at (624.2, 624.8); a clock at the top (0°), a key at 113° and a
// lift at 252°, clockwise, measured on their middles. Shown 405 px round
// its centre, the dial's own rim and pointer stay under the lock's bezel.
const _padlock = ScenePixels(1536, 1024);
const _dial = ScenePixels(1254, 1254);

const Map<String, DialLockScene> season2DialLocks = {
  's2_ep03_m3': DialLockScene(
    lock: '$_case03/mechanical_lock.png',
    pixels: _padlock,
    view: Rect.fromLTRB(362, 492, 1176, 852),
    windows: [Offset(482.0, 671.1), Offset(768.6, 671.3), Offset(1055.2, 671.2)],
    windowRadius: 78.3,
    dial: '$_case03/lock_dial.png',
    dialPixels: _dial,
    pivot: Offset(624.2, 624.8),
    showRadius: 405,
    symbols: [
      // Each symbol alone on the dial (upright there), for its close-up.
      DialSymbol(id: 'clock', name: 'CLOCK', angle: 0, closeUp: Rect.fromLTRB(490, 200, 760, 470)),
      DialSymbol(id: 'key', name: 'KEY', angle: 113, closeUp: Rect.fromLTRB(785, 545, 1015, 940)),
      DialSymbol(id: 'lift', name: 'LIFT', angle: 252, closeUp: Rect.fromLTRB(245, 580, 435, 855)),
    ],
    // Key, clock, lift: no dial starts on its answer.
    start: [1, 0, 2],
    label: 'A heavy brass padlock with three dials, each under a pointer',
    task: 'Turn each dial. The picture under the pointer is the one set.',
    openLabel: 'OPEN THE LOCK',
  ),
};

// ── Final — the time-recording machine and the brass plaque ─────────────
// The machine (1536 × 1024), shut and open in register: only its lower
// hatch differs (the open one shows a blank brass plaque inside). The
// plaque (1536 × 1024, cut out): a blank panel from (200, 330) to
// (1340, 660), three engraved waves under it (640–895, 690–745), a screw
// below them; the word under the waves is written just below the plaque.
const _machine = ScenePixels(1536, 1024);
const _brass = ScenePixels(1536, 1024);

final Map<String, EvidenceBoardScene> season2EvidenceBoards = {
  's2_ep03_final': EvidenceBoardScene(
    shut: '$_case03/time_recording_machine.png',
    open: '$_case03/time_recording_machine_open.png',
    pixels: _machine,
    machineLabel: 'An old time-recording machine with a clock face and a small hatch',
    questions: const [
      BoardQuestion(id: 'q1', text: 'What was wrong with the inspection records?'),
      BoardQuestion(id: 'q2', text: 'Where did the lift go?'),
      BoardQuestion(id: 'q3', text: 'What supports the conclusion that someone entered the service area?'),
    ],
    evidence: const [
      BoardEvidence(id: 'e1', evidenceId: 's2_ep03_e1'),
      BoardEvidence(id: 'e2', evidenceId: 's2_ep03_e2'),
      BoardEvidence(id: 'e3', evidenceId: 's2_ep03_e3'),
    ],
    conclusionId: 'why',
    conclusionQuestion: 'What can we conclude?',
    conclusions: const [
      BoardConclusion(id: 'entered', text: 'Someone entered the service area during the unexplained time difference.'),
      BoardConclusion(id: 'vanished', text: 'An hour really vanished from Paris.'),
      BoardConclusion(id: 'still', text: 'The lift never moved.'),
    ],
    linkTask: 'Tap a question. Then tap the evidence that answers it.',
    concludeTask: 'Now choose what the evidence shows.',
    solveLabel: 'SOLVE THE CASE',
    plaque: '$_case03/brass_plaque.png',
    plaquePixels: _brass,
    plaqueWriteOn: _brass.rect(270, 372, 1266, 620),
    plaqueMessage: 'ONE HOUR IS MISSING.\nTHE CLOCK IS STILL RUNNING.',
    riverAt: _brass.rect(560, 858, 976, 944),
    riverWord: 'SEINE',
    plaqueLabel: 'A brass plaque, three small waves engraved under its message',
  ),
};

/// Case 03's evidence matched with what came before: the records lead on
/// from the painter's message (its tower drawing), and the plaque's hour
/// is the hour the records disagree on.
const Map<String, EvidenceLink> season2Case03EvidenceLinks = {
  's2_ep03_e1': EvidenceLink(to: 's2_ep02_e4', line: "The tower drawn beside ALWAYS HIGHER on the painter's canvas."),
  's2_ep03_e4': EvidenceLink(to: 's2_ep03_e1', line: 'The two records were one hour apart too.'),
};

// ── The story's pictures, mission by mission ────────────────────────────
// Each moment shows what the detective has just reached, never more: the
// hidden room only once the door is open, the open hatch only after the
// case.
const _tower = ScenePixels(1024, 1536);

const _entranceWhole = StoryPicture(
  file: '$_case03/tower_notice_board.png',
  pixels: _entrance,
  label: 'The entrance of the Eiffel Tower at dusk: a notice board, a gate and a ticket booth',
);

const _liftWhole = StoryPicture(
  file: '$_case03/tower_lift.png',
  pixels: _lift,
  label: 'Inside the old lift: brass gates, wooden walls, Paris far below',
);

const _doorWhole = StoryPicture(
  file: '$_case03/service_door.png',
  pixels: ScenePixels(1536, 1024),
  label: 'An iron door at the Service Level, locked with a heavy padlock',
);

const _machineShut = StoryPicture(
  file: '$_case03/time_recording_machine.png',
  pixels: _machine,
  label: 'An old time-recording machine with a clock face and a small hatch',
);

final Map<String, StoryScenes> season2Case03StoryScenes = {
  // The entrance; after it, the tower above; then the lift.
  's2_ep03_m1': StoryScenes(
    place: _entranceWhole,
    after: StoryPicture(
      file: '$_case03/eiffel_tower_exterior.png',
      pixels: _tower,
      crop: _tower.rect(0, 200, 1024, 1300),
      label: 'The Eiffel Tower at dusk, its lamps coming on',
    ),
    next: _liftWhole,
  ),
  // The lift; after it, Paris through its gates as it rises; then the door.
  's2_ep03_m2': StoryScenes(
    place: _liftWhole,
    after: StoryPicture(
      file: '$_case03/tower_lift.png',
      pixels: _lift,
      crop: _lift.rect(430, 140, 1090, 950),
      label: 'Paris far below, through the brass gates of the lift',
    ),
    next: _doorWhole,
  ),
  // The door; after it, the hidden room behind it; then the machine.
  's2_ep03_m3': const StoryScenes(
    place: _doorWhole,
    after: StoryPicture(
      file: '$_case03/service_room.png',
      pixels: ScenePixels(1536, 1024),
      label: 'A hidden machine room: wheels, cables and gears inside the tower',
    ),
    next: _machineShut,
  ),
  // After the case: the machine, its hatch open.
  's2_ep03_final': StoryScenes(
    after: StoryPicture(
      file: '$_case03/time_recording_machine_open.png',
      pixels: _machine,
      crop: _machine.rect(380, 120, 1200, 960),
      label: 'The machine, its hatch open, a brass plaque inside',
    ),
  ),
};
