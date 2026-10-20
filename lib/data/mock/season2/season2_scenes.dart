import 'dart:ui' show Offset, Rect;

import '../../models/clock_puzzle.dart';
import '../../models/investigation.dart' show InvestigationSpot;
import '../../models/mission.dart';
import '../../models/painter_puzzles.dart';
import '../../models/picture_spot.dart';
import '../../models/scene_exhibit.dart';
import '../../models/scene_explore.dart' show ScenePixels;
import '../../models/station_clocks.dart';
import '../../models/story_picture.dart';

/// Season 2's missions played in their scenes (presentation only: the case
/// data is left as it is). Each table is keyed by mission id, as Season 1's
/// are; the answer, its feedback, the hints, the solve, its Clue and
/// Evidence, XP, coins and the save are the puzzle's own.

const _case01 = 'assets/seasons/season_02_paris/cases/case_01';
const _case02 = 'assets/seasons/season_02_paris/cases/case_02';

// ── Case 01 M1 — the station hall (1536 × 1024) ─────────────────────────
// Three painted clocks with no hands (the app draws them, aimed at each
// dial's own numerals: the painted dials are not true circles), the
// departure board left blank for the app to write on, and the Lost
// Property desk under the old clock. The hall clock is the great one on
// the wall, the platform clock hangs on the iron pillar, the old clock is
// the brass one over the desk.
const _hall = ScenePixels(1536, 1024);

final _hallClocks = [
    PaintedClock(
      optionId: 'a',
      name: 'THE HALL CLOCK',
      label: 'The big clock on the wall of the hall',
      time: '10:00',
      centre: _hall.at(339, 274),
      twelve: _hall.at(341, 189),
      hourNumeral: _hall.at(275, 216), // X
      area: _hall.rect(228, 152, 452, 398),
      closeUp: _hall.rect(219, 154, 459, 394),
      mark: _hall.at(446, 172),
    ),
    PaintedClock(
      optionId: 'b',
      name: 'THE PLATFORM CLOCK',
      label: 'The round clock on the iron pillar',
      time: '10:00',
      centre: _hall.at(950, 280),
      twelve: _hall.at(949, 215),
      hourNumeral: _hall.at(897, 254), // X
      area: _hall.rect(858, 180, 1052, 386),
      closeUp: _hall.rect(850, 180, 1050, 380),
      mark: _hall.at(1046, 196),
    ),
    PaintedClock(
      optionId: 'c',
      name: 'THE OLD CLOCK',
      label: 'The old brass clock over the Lost Property desk',
      time: '9:00',
      centre: _hall.at(1302, 306),
      twelve: _hall.at(1302, 245),
      hourNumeral: _hall.at(1252, 316), // IX
      area: _hall.rect(1214, 214, 1396, 402),
      closeUp: _hall.rect(1212, 216, 1392, 396),
      // Upper left of the dial: in the page's opening view on a small phone.
      mark: _hall.at(1222, 230),
    ),
];

final Map<String, StationClocksScene> season2StationClocks = {
  's2_ep01_m1': StationClocksScene(
    picture: '$_case01/station_hall_clocks.png',
    pixels: _hall,
    place: 'The station hall at Gare du Nord',
    task: 'Tap the three clocks to investigate.',
    boardTask: 'Great! Now check the departure board.',
    reportTask: 'One clock is one hour behind!\nReport it to the Lost Property Desk.',
    missLine: 'Nothing here. Look at the clocks and the departure board.',
    guideAt: _hall.at(339, 274),
    // The page opens a little closer than the whole hall: the three clocks,
    // the board and the desk's counter (a drag shows the edges).
    opening: _hall.rect(150, 140, 1420, 900),
    clocks: _hallClocks,
    board: StationSpot(
      id: 'board',
      title: 'DEPARTURE BOARD',
      label: 'The departure board, with a notice on it',
      // The black board, from its iron crest to its feet.
      area: _hall.rect(112, 470, 524, 795),
      mark: _hall.at(506, 520),
      // The black panel itself, under its iron crest.
      outline: _hall.rect(116, 506, 520, 792),
    ),
    desk: StationSpot(
      id: 'desk',
      title: 'LOST PROPERTY DESK',
      label: 'The Lost Property desk',
      // The wooden kiosk under the old clock, its counter and shelves.
      area: _hall.rect(1100, 520, 1536, 870),
      mark: _hall.at(1318, 566),
    ),
    others: [
      InvestigationSpot(
        label: 'Wooden benches',
        areas: [_hall.rect(0, 862, 572, 1010)],
        line: 'Wooden benches. People wait here for their trains.',
      ),
      InvestigationSpot(
        label: 'A train at the platform',
        areas: [_hall.rect(540, 722, 760, 862), _hall.rect(872, 748, 1062, 834)],
        line: 'A train is waiting at the platform.',
      ),
      InvestigationSpot(
        label: 'A luggage trolley',
        areas: [_hall.rect(972, 778, 1176, 1000)],
        line: 'Suitcases on a trolley. They are all locked.',
      ),
      InvestigationSpot(
        label: 'Stone statues',
        areas: [_hall.rect(84, 184, 166, 352), _hall.rect(464, 294, 532, 442)],
        line: 'Stone statues. They are not telling you anything.',
      ),
      InvestigationSpot(
        label: 'The glass roof',
        areas: [_hall.rect(880, 0, 1262, 170)],
        line: 'The glass roof. The morning light comes in.',
      ),
    ],
    boardTitle: 'DEPARTURES',
    // Trains after ten: the hall clock's time, so the board never says
    // which clock is right.
    departures: [
      Departure(time: '10:15', to: 'LONDON', platform: '3'),
      Departure(time: '10:40', to: 'LILLE', platform: '7'),
      Departure(time: '11:05', to: 'BRUSSELS', platform: '5'),
      Departure(time: '11:30', to: 'AMSTERDAM', platform: '9'),
    ],
    noticeTitle: 'STATION NOTICE',
    notice: [
      'All our clocks show Paris time.',
      'IF ONE CLOCK IS ONE HOUR BEHIND, REPORT IT TO THE LOST PROPERTY DESK.',
    ],
    noticeKeys: ['ONE HOUR BEHIND', 'LOST PROPERTY DESK'],
    boardFirstLine: 'The Lost Property desk. What should you report? Read the departure board first.',
    clocksFirstLine: 'Look at all three clocks first. Which one is different?',
    reportHow: 'Compare the three clocks. Tap the one to report.',
  ),
};

// ── Case 01 M2 — the lost ticket (1774 × 887, cut out) ──────────────────
// Handed over with the clerk's notes. Its words are said as printed, no
// more: PARIS on the red stub, MONTMARTRE, PARIS and its number on the
// right. Where it leads is told by the painting at the end of the case.
final Map<String, Exhibit> season2Exhibits = {
  's2_ep01_m2': Exhibit(
    id: 'ticket',
    picture: '$_case01/lost_ticket.png',
    pixels: ScenePixels(1774, 887),
    title: 'THE LOST TICKET',
    description:
        'An old train ticket, torn at the edges. PARIS is printed on its red stub. '
        'In the middle, a white church on a hill. On the right: MONTMARTRE, PARIS, number 72831.',
    caption: 'Someone dropped it under the old clock this morning.',
  ),
};

// ── Case 01 M3 — the old clock's face (1254 × 1254, cut out) ────────────
// The face of the brass clock over the desk, close up, with no hands. They
// start where the old clock stands (9:00), never at the answer.
const Map<String, ClockPuzzle> season2Clocks = {
  's2_ep01_m3': ClockPuzzle(
    face: Artwork.oldClockFace,
    question: "Move the old clock's hands forward one hour.",
    lead: 'The carving says how to put the old clock right.',
    guide: 'Drag the short hand for the hour and the long hand for the minutes.',
    dialLabel: "The old clock's face",
    start: (hour: 9, minute: 0),
  ),
};

// ── Case 01 Final — the brass box (shut 1447 × 1087, open 1446 × 1088) ──
// Its four letter slots on the front, in both pictures; the painting lies
// on the red velvet of the open box.
const _shut = ScenePixels(1447, 1087);
const _open = ScenePixels(1446, 1088);

final Map<String, LockBoxArt> season2LockBoxes = {
  's2_ep01_final': LockBoxArt(
    closed: '$_case01/brass_box_closed.png',
    closedPixels: _shut,
    closedSlots: [
      _shut.rect(360, 682, 438, 828),
      _shut.rect(507, 705, 588, 843),
      _shut.rect(665, 730, 745, 868),
      _shut.rect(822, 755, 913, 900),
    ],
    open: '$_case01/brass_box_open.png',
    openPixels: _open,
    openSlots: [
      _open.rect(372, 722, 443, 840),
      _open.rect(497, 747, 573, 863),
      _open.rect(635, 775, 710, 903),
      _open.rect(767, 803, 843, 925),
    ],
    inside: _open.rect(372, 398, 1152, 735),
    insideLabel: 'A small painting in the box, on red velvet',
    found: '$_case01/montmartre_painting.png',
    foundPixels: ScenePixels(1774, 887),
    foundTitle: 'THE PAINTING',
    foundLine: 'A white church on a hill, above the roofs of Paris.',
    back: 'FIND THE PAINTER.',
    examineId: 'painting',
  ),
};

/// Evidence that matches other evidence of its case (shown with it once
/// both are found): the painting's church is the one on the lost ticket.
const Map<String, EvidenceLink> season2EvidenceLinks = {
  's2_ep01_e4': EvidenceLink(to: 's2_ep01_e2', line: 'The same white church is on the lost ticket.'),
  's2_ep01_e2': EvidenceLink(to: 's2_ep01_e4', line: 'The same white church is in the painting from the brass box.'),
  // Case 02, back to what Case 01 found.
  's2_ep02_e1': EvidenceLink(to: 's2_ep01_e4', line: 'The same painter made the painting from the brass box.'),
  's2_ep02_e4': EvidenceLink(to: 's2_ep01_e4', line: 'Written in the same hand as FIND THE PAINTER.'),
};

// ── Case 01 — the story's pictures, mission by mission ──────────────────
// Each moment shows what the detective has just found, never more: the
// open box only once it is open, the painting only after the case. Parts
// of the hall's picture keep its clocks' hands (the old one at nine until
// it is put right); the old clock's face, put right, shows ten.
const _face = ScenePixels(1254, 1254);

final _oldClock = _hallClocks.last;

/// The old clock's face at ten, put right (its numerals lie on a true
/// circle round the pivot: XII and X at 317 px).
const _faceAtTen = PaintedClock(
  optionId: 'c',
  name: 'THE OLD CLOCK',
  label: "The old clock's face",
  time: '10:00',
  centre: Offset(625 / 1254, 617 / 1254),
  twelve: Offset(625 / 1254, 300 / 1254),
  hourNumeral: Offset(350.5 / 1254, 458.5 / 1254),
  area: Rect.fromLTRB(0, 0, 1, 1),
  closeUp: Rect.fromLTRB(0, 0, 1, 1),
  mark: Offset(0.5, 0.5),
);

final _hallWhole = StoryPicture(
  file: '$_case01/station_hall_clocks.png',
  pixels: _hall,
  label: 'The station hall at Gare du Nord, its three clocks high on the walls',
  clocks: _hallClocks,
);

/// The Lost Property desk, the old clock above it.
final _desk = StoryPicture(
  file: '$_case01/station_hall_clocks.png',
  pixels: _hall,
  crop: _hall.rect(1060, 190, 1536, 900),
  label: 'The Lost Property desk, under the old brass clock',
  clocks: [_oldClock],
);

/// The old clock in its brass bracket, high over the hall.
final _oldClockHigh = StoryPicture(
  file: '$_case01/station_hall_clocks.png',
  pixels: _hall,
  crop: _hall.rect(1120, 130, 1490, 560),
  label: 'The old brass clock, high over the hall',
  clocks: [_oldClock],
);

/// The old clock's face, close: its hands at nine.
final _oldClockClose = StoryPicture(
  file: '$_case01/station_hall_clocks.png',
  pixels: _hall,
  crop: _hall.rect(1196, 200, 1408, 412),
  label: 'The old clock up close, its hands at nine',
  clocks: [_oldClock],
  frame: StoryFrame.lens,
);

const _boxShut = StoryPicture(
  file: '$_case01/brass_box_closed.png',
  pixels: _shut,
  label: 'A small brass box, an E on its lid and four letter slots on its front',
  cutOut: true,
);

final Map<String, StoryScenes> season2StoryScenes = {
  // The hall whole; after it, the old clock that is wrong, and the desk
  // the notice sends the detective to.
  's2_ep01_m1': StoryScenes(place: _hallWhole, after: _oldClockHigh, next: _desk),
  // The desk; after it, the ticket with its letter, and the old clock to
  // climb to.
  's2_ep01_m2': StoryScenes(
    place: _desk,
    after: StoryPicture(
      file: '$_case01/lost_ticket.png',
      pixels: ScenePixels(1774, 887),
      label: 'The lost ticket',
      cutOut: true,
    ),
    next: _oldClockClose,
  ),
  // The old clock close; after it, its face put right at ten, and the box
  // that slid out from under it.
  's2_ep01_m3': StoryScenes(
    place: _oldClockClose,
    after: const StoryPicture(
      file: '$_case01/old_clock_face.png',
      pixels: _face,
      label: "The old clock's face, its hands at ten",
      clocks: [_faceAtTen],
      cutOut: true,
    ),
    next: _boxShut,
  ),
  // After the case: the box open, the painting in it.
  's2_ep01_final': StoryScenes(
    after: StoryPicture(
      file: '$_case01/brass_box_open.png',
      pixels: _open,
      label: 'The brass box open, a small painting on red velvet inside',
      cutOut: true,
    ),
  ),
};

// ── Case 02 M1 — the street and its painting (1536 × 1024, in register) ──
// The same street, every thing where it is on both. The painting has three
// changes and only three: a small round clock on the wall above the red
// door, the right-hand upstairs window (blue shutters, flower box) left
// out, and the lamp beside the steps shining bright (on the street its
// flame is small).
const _street = ScenePixels(1536, 1024);

final Map<String, CompareScene> season2Compares = {
  's2_ep02_m1': CompareScene(
    real: '$_case02/montmartre_street_real.png',
    painted: '$_case02/montmartre_street_painted.png',
    pixels: _street,
    realLabel: 'THE STREET',
    paintedLabel: 'THE PAINTING',
    changes: [
      PictureSpot('clock', _street.rect(648, 305, 745, 420), label: 'The wall above the red door'),
      PictureSpot('window', _street.rect(745, 90, 895, 340), label: 'The upstairs window on the right'),
      PictureSpot('lamp', _street.rect(395, 135, 550, 330), label: 'The lamp beside the steps'),
    ],
    task: 'Find the three changes.',
    missLine: 'The same on both. Read the note again: where should you look?',
    foundLines: {
      'clock': 'Above the red door: a small clock in the painting. The street has none!',
      'window': 'The street has a window here. In the painting, it is missing!',
      'lamp': 'The lamp beside the steps: bright in the painting, dim on the street.',
    },
    checklist: {
      'clock': 'Look above the red door.',
      'window': 'Find the window that is missing.',
      'lamp': 'Check the lamp beside the steps.',
    },
    // The door, the windows above it and the lamp: every change in view.
    opening: _street.rect(300, 40, 1000, 560),
  ),
};

// ── Case 02 M2 — the painter's studio (1024 × 1536) ──────────────────────
// Three paintings of one square (1254 × 1254 each) are put away in the
// room, out of sight: in the old trunk, a desk drawer, the crate under the
// desk. His notes lie on the desk top. The paintings are laid out p3, p1,
// p2 on the matching page: never the notes' A, B, C order.
const _studio = ScenePixels(1024, 1536);
const _square = ScenePixels(1254, 1254);

final Map<String, StudioScene> season2Studios = {
  's2_ep02_m2': StudioScene(
    picture: '$_case02/painters_studio.png',
    pixels: _studio,
    place: "The painter's studio, sunlight through a big window",
    paintings: [
      StudioPainting(
        id: 'p1',
        area: _studio.rect(884, 1195, 1024, 1410),
        mark: _studio.at(950, 1230),
        file: '$_case02/studio_painting_p1.png',
        pixels: _square,
        label: 'A painting of a café square: the whole sky gold, the stones dry',
        line: 'In the old trunk: a painting of a square.',
      ),
      StudioPainting(
        id: 'p2',
        area: _studio.rect(676, 850, 860, 985),
        mark: _studio.at(770, 905),
        file: '$_case02/studio_painting_p2.png',
        pixels: _square,
        label: 'A painting of the same square: dark grey clouds, the stones dry',
        line: 'In the desk drawer: a painting of a square.',
      ),
      StudioPainting(
        id: 'p3',
        area: _studio.rect(762, 1040, 866, 1160),
        mark: _studio.at(815, 1085),
        file: '$_case02/studio_painting_p3.png',
        pixels: _square,
        label: 'A painting of the same square: the stones wet and shiny after rain',
        line: 'In the crate under the desk: a painting of a square.',
      ),
    ],
    order: ['p3', 'p1', 'p2'],
    desk: InvestigationSpot(
      label: 'Papers on the desk',
      areas: [_studio.rect(790, 790, 1000, 848)],
      line: 'Three notes, A, B and C.',
    ),
    deskMark: _studio.at(905, 800),
    others: [
      InvestigationSpot(
        label: 'A canvas on the small easel',
        areas: [_studio.rect(108, 492, 400, 860)],
        line: 'Some paint on a canvas, but no picture yet.',
      ),
      InvestigationSpot(
        label: 'A straw hat and a painting smock on a hook',
        areas: [_studio.rect(890, 250, 1024, 790)],
        line: 'His straw hat and his painting smock, on a hook.',
      ),
      InvestigationSpot(
        label: 'The big window',
        areas: [_studio.rect(584, 100, 876, 700)],
        line: 'The white church on the hill. You can see it from here.',
      ),
      InvestigationSpot(
        label: 'Brushes and a palette on a table',
        areas: [_studio.rect(0, 860, 370, 1170)],
        line: 'Brushes and a palette. The paint on it is dry.',
      ),
      InvestigationSpot(
        label: 'Paintings of Paris on the wall',
        areas: [_studio.rect(0, 90, 175, 560)],
        line: 'Paintings of Paris on the wall. The white church, again and again.',
      ),
    ],
    task: 'Find the three paintings he put away.',
    deskTask: 'Now read the notes on his desk.',
    matchTask: 'Match each note to its painting.',
    missLine: 'Nothing here. Look in the places where things are put away.',
    deskFirstLine: 'Three notes. Find the paintings first: where did he put them away?',
    matchHow: 'Tap a note, then tap its painting. Or drag the note onto it.',
    // The desk, the trunk, the crate and the window above them.
    opening: _studio.rect(0, 640, 1024, 1440),
  ),
};

// ── Case 02 M3 — the painted-over sketch (1536 × 1024, in register) ──────
// The studio's big easel, the same on both pictures but for its canvas:
// thick paint and no picture on one, a pencil sketch on the other — a tall
// lamp, stone steps, an iron gate between two stone pillars, the white
// church above. The paint slides off left to right across the canvas.
const _easel = ScenePixels(1536, 1024);

final Map<String, LayerScene> season2Layers = {
  's2_ep02_m3': LayerScene(
    paint: '$_case02/hidden_layer_paint.png',
    sketch: '$_case02/hidden_layer_sketch.png',
    pixels: _easel,
    view: _easel.rect(140, 190, 780, 880),
    canvas: _easel.rect(225, 255, 690, 795),
    marks: [
      PictureSpot('lamp', _easel.rect(270, 430, 362, 655), label: 'The tall lamp in the sketch'),
      PictureSpot('steps', _easel.rect(340, 660, 436, 760), label: 'The steps in the sketch'),
      PictureSpot('gate', _easel.rect(440, 640, 575, 725), label: 'The gate in the sketch'),
    ],
    paintLabel: 'A canvas on the big easel, covered in thick paint',
    sketchLabel: 'A pencil sketch: a lamp, stone steps, an iron gate between pillars, the white church above',
    slideTask: 'Slide the paint away.',
    findTask: 'Find the lamp, the steps and the gate.',
    missLine: 'Look again. A lamp, steps, a gate.',
    paintLine: 'Thick paint. Slide it away first.',
    foundLines: {
      'lamp': 'An old lamp, tall and thin.',
      'steps': 'Stone steps, going up.',
      'gate': 'An iron gate between two stone pillars. The gate is black.',
    },
  ),
};

// ── Case 02 Final — the four canvases (1536 × 1024 each) ─────────────────
// Four different places, each on an easel. A: the red door street. B: a
// café square under a gold sky (no steps, no gate). C: stone steps, a lamp
// and a black iron gate between pillars, a blue sky. D: stone steps, a lamp
// and a blue gate, a blue sky. The back (its own picture: the stretcher,
// ATELIER MONTMARTRE on a label, "Paris, toujours plus haut") has a bare
// lower panel: the message is written there.
const _canvas = ScenePixels(1536, 1024);

final Map<String, CanvasScene> season2Canvases = {
  's2_ep02_final': CanvasScene(
    canvases: [
      ChoiceCanvas(id: 'a', file: '$_case02/canvas_a.png', name: 'CANVAS A'),
      ChoiceCanvas(id: 'b', file: '$_case02/canvas_b.png', name: 'CANVAS B'),
      ChoiceCanvas(id: 'c', file: '$_case02/canvas_c.png', name: 'CANVAS C'),
      ChoiceCanvas(id: 'd', file: '$_case02/canvas_d.png', name: 'CANVAS D'),
    ],
    pixels: _canvas,
    back: '$_case02/canvas_back.png',
    backPixels: _canvas,
    writeOn: _canvas.rect(300, 600, 1290, 870),
    message: 'A city can lose an hour.\nBut who can steal it?',
    backLabel: 'The back of the canvas: a label, ATELIER MONTMARTRE, and the words Paris, toujours plus haut',
    chooseHow: 'Tap a canvas to look closer. Then turn the right one around.',
  ),
};

// ── Case 02 — the story's pictures, mission by mission ──────────────────
const _streetWhole = StoryPicture(
  file: '$_case02/montmartre_street_real.png',
  pixels: _street,
  label: 'A quiet street in Montmartre: a red door, stone steps and an old lamp',
);

const _studioWhole = StoryPicture(
  file: '$_case02/painters_studio.png',
  pixels: _studio,
  label: "The painter's studio, sunlight through a big window",
);

final _easelPainted = StoryPicture(
  file: '$_case02/hidden_layer_paint.png',
  pixels: _easel,
  crop: _easel.rect(140, 190, 780, 880),
  label: 'A canvas on the big easel, covered in thick paint',
);

final Map<String, StoryScenes> season2Case02StoryScenes = {
  // The street; after it, the painting's door and its clock; then the
  // studio the key opens.
  's2_ep02_m1': StoryScenes(
    place: _streetWhole,
    after: StoryPicture(
      file: '$_case02/montmartre_street_painted.png',
      pixels: _street,
      crop: _street.rect(360, 40, 1000, 600),
      label: 'The painting: a small clock above the red door',
    ),
    next: _studioWhole,
  ),
  // The studio; after it, the gold-sky painting of note C; then the easel.
  's2_ep02_m2': StoryScenes(
    place: _studioWhole,
    after: const StoryPicture(
      file: '$_case02/studio_painting_p1.png',
      pixels: _square,
      label: 'The painting of the square under a gold sky',
    ),
    next: _easelPainted,
  ),
  // The easel; after it, the sketch uncovered; then the studio, where the
  // canvases wait (they are shown only in the final itself).
  's2_ep02_m3': StoryScenes(
    place: _easelPainted,
    after: StoryPicture(
      file: '$_case02/hidden_layer_sketch.png',
      pixels: _easel,
      crop: _easel.rect(140, 190, 780, 880),
      label: 'The pencil sketch under the paint: a lamp, stone steps and an iron gate',
    ),
    next: _studioWhole,
  ),
  // After the case: the back of the canvas.
  's2_ep02_final': StoryScenes(
    after: StoryPicture(
      file: '$_case02/canvas_back.png',
      pixels: _canvas,
      label: 'The back of the canvas: ATELIER MONTMARTRE, and Paris, toujours plus haut',
    ),
  ),
};
