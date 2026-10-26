import 'dart:ui' show Rect;

import '../../models/easy_steps.dart';
import '../../models/river_puzzles.dart';
import '../../models/scene_exhibit.dart' show EvidenceLink;
import '../../models/scene_explore.dart' show ScenePixels;
import '../../models/story_picture.dart';
import '../../models/tower_puzzles.dart' show BoardEvidence;
import 'season2_case03_scenes.dart' show season2EvidenceBoards;

/// Season 2, Case 04's missions played in their scenes (presentation only:
/// the case data is left as it is). Each table is keyed by mission id; the
/// answer, its feedback, the hints, the solve, its Clue and Evidence, XP,
/// coins and the save are the puzzle's own. Every place is measured on the
/// delivered picture (pixels, then fractions).

const _case04 = 'assets/seasons/season_02_paris/cases/case_04';
const _hands = '$_case04/hands_sign.png';

// ── The plaque's back (the opening and M1) ─────────────────────────────
// The back of Case 03's plaque (1536 × 1024, cut out on the front's own
// outline): flat dark brass, its inner panel from (206, 319) to (1344, 656).
const _brass = ScenePixels(1536, 1024);

final plaqueBack = PlaqueBack(
  file: '$_case04/brass_plaque_back.png',
  pixels: _brass,
  writeOn: _brass.rect(260, 360, 1290, 620),
  lines: const [
    'Three waves mark the place.',
    'Follow the arrow towards the river.',
    'Find the one who watches the water.',
  ],
  label: 'The back of the brass plaque, three lines scratched into it',
);

/// The case's opening: the plaque turned over, from its third line on.
final Map<String, IntroPlaque> season2IntroPlaques = {
  's2_ep04': IntroPlaque(afterLine: 2, plaque: plaqueBack),
};

// ── M1 — the quay wall's four marks ─────────────────────────────────────
// The wall (1536 × 1024): four carved stones in a row, measured on their
// raised frames, their word panels blank; a cream enamel sign above them,
// (647, 244)–(838, 313); the keeper's steps at the right, from x 1398. The
// close-ups (1254 × 1254) are the same stones: the wave count and the
// arrow measured on both (A three, up; B three, down; C two, down; D
// three, down); their word panel inside (260, 885)–(1005, 1025).
const _wall = ScenePixels(1536, 1024);
const _mark = ScenePixels(1254, 1254);

final Map<String, RiverMarksScene> season2RiverMarks = {
  's2_ep04_m1': RiverMarksScene(
    wall: '$_case04/quay_wall_marks.png',
    pixels: _wall,
    place: 'An old stone quay wall by the river at dusk, four carved marks in a row, steps down to the water',
    marks: [
      RiverMark(
        id: 'a',
        name: 'MARK A',
        area: _wall.rect(181, 371, 373, 580),
        wordAt: _wall.rect(202, 519, 350, 552),
        closeUp: '$_case04/river_mark_a.png',
        closeWordAt: _mark.rect(260, 885, 1005, 1025),
        word: 'RIVER KEEPER',
        waves: 3,
        arrowDown: false,
      ),
      RiverMark(
        id: 'b',
        name: 'MARK B',
        area: _wall.rect(472, 382, 656, 583),
        wordAt: _wall.rect(494, 526, 634, 563),
        closeUp: '$_case04/river_mark_b.png',
        closeWordAt: _mark.rect(260, 885, 1005, 1025),
        word: 'BOOKSELLERS',
        waves: 3,
        arrowDown: true,
      ),
      RiverMark(
        id: 'c',
        name: 'MARK C',
        area: _wall.rect(751, 395, 918, 585),
        wordAt: _wall.rect(769, 530, 898, 566),
        closeUp: '$_case04/river_mark_c.png',
        closeWordAt: _mark.rect(260, 885, 1005, 1025),
        word: 'RIVER KEEPER',
        waves: 2,
        arrowDown: true,
      ),
      RiverMark(
        id: 'd',
        name: 'MARK D',
        area: _wall.rect(1005, 401, 1164, 588),
        wordAt: _wall.rect(1022, 532, 1148, 572),
        closeUp: '$_case04/river_mark_d.png',
        closeWordAt: _mark.rect(260, 885, 1005, 1025),
        word: 'RIVER KEEPER',
        waves: 3,
        arrowDown: true,
      ),
    ],
    closePixels: _mark,
    signAt: _wall.rect(647, 244, 838, 313),
    sign: 'QUAY 3',
    plaqueFront: season2EvidenceBoards['s2_ep03_final']!,
    plaqueBack: plaqueBack,
    readTask: 'Check each mark with the three lines.',
    chooseTask: 'Which mark follows all three lines? Tap it.',
    chooseLabel: 'THIS IS THE MARK',
    // Said only once Mark D is chosen and checked right: line by line.
    rightLines: const [
      'Three waves.',
      'Its arrow points down, towards the river.',
      'RIVER KEEPER: he watches the water.',
    ],
  ),
};

// ── M2 — the keeper's hut and ledger ────────────────────────────────────
// The hut outside and inside (1536 × 1024 each). Outside: its door open on
// the right of the front, the doorway and the door from (745, 360) to
// (1050, 850). Inside: the ledger open on the desk, (95, 640)–(705, 865).
// The ledger (1536 × 1024, cut out): an open book, both pages blank; the
// left page (140, 75)–(760, 830), written inside (215, 120)–(720, 785),
// clear of the ink stains at its edge; the right page (755, 75)–(1375,
// 830), written inside (800, 120)–(1290, 790), clear of the coffee ring.
const _hut = ScenePixels(1536, 1024);
const _ledger = ScenePixels(1536, 1024);

LedgerPart _t(String text) => LedgerPart(text);
LedgerPart _box(String id, String text) => LedgerPart(text, box: id);

final Map<String, KeeperHutScene> season2KeeperHuts = {
  's2_ep04_m2': KeeperHutScene(
    outside: '$_case04/keeper_hut.png',
    outsideLabel: 'A small wooden hut by the river at night, its door open, a lamp burning inside',
    doorArea: _hut.rect(745, 360, 1050, 850),
    inside: '$_case04/keeper_hut_interior.png',
    insideLabel: "Inside the keeper's hut: a desk with an open ledger, keys on the wall, the river through the door",
    ledgerArea: _hut.rect(95, 640, 705, 865),
    pixels: _hut,
    ledger: '$_case04/keeper_ledger.png',
    ledgerPixels: _ledger,
    ledgerLabel: "The river keeper's ledger, open",
    pages: [
      LedgerPage(
        title: 'BOXES IN AND MOVED',
        crop: _ledger.rect(140, 75, 760, 830),
        writeOn: _ledger.rect(215, 120, 720, 785),
        entries: [
          LedgerEntry(date: '13 MAY', parts: [_t('Old books, from the bookstalls. Quay 1, '), _box('box4', 'Box 4'), _t('.')], initials: 'J.M.'),
          LedgerEntry(date: '13 MAY', parts: [_t('A small crate, from the Eiffel Tower. Quay 1, '), _box('box9', 'Box 9'), _t('.')], initials: 'J.M.'),
          LedgerEntry(date: '13 MAY', parts: [_t('Lamp oil, from Pont Neuf. Quay 3, '), _box('box12', 'Box 12'), _t('.')], initials: 'J.M.'),
          LedgerEntry(date: '13 MAY', parts: [_t('A heavy crate, from the Eiffel Tower. Quay 3, '), _box('box17', 'Box 17'), _t('.')], hands: true),
          LedgerEntry(date: '13 MAY', parts: [_t('An iron chain, from the Eiffel Tower. Quay 2, '), _box('box6', 'Box 6'), _t('.')], initials: 'J.M.'),
          LedgerEntry(date: '14 MAY', parts: [_box('box17', 'Box 17'), _t(' moved to '), _box('box23', 'Box 23'), _t('. Quay 3.')], hands: true),
        ],
      ),
      LedgerPage(
        title: 'BOXES COLLECTED',
        crop: _ledger.rect(755, 75, 1375, 830),
        writeOn: _ledger.rect(800, 120, 1290, 790),
        entries: [
          LedgerEntry(date: '15 MAY', parts: [_box('box4', 'Box 4'), _t(' — collected by the bookseller.')], initials: 'J.M.'),
          LedgerEntry(date: '15 MAY', parts: [_box('box12', 'Box 12'), _t(' — collected for the street lamps.')], initials: 'J.M.'),
          LedgerEntry(
            date: '15 MAY',
            parts: [_box('box23', 'Box 23'), _t(" — collected for No. 7. Delivery: through the keeper's steps.")],
            hands: true,
          ),
        ],
      ),
    ],
    hands: _hands,
    doorTask: 'The door is open. Tap it to go in.',
    ledgerTask: 'Tap the ledger on the desk to read it.',
    circleTask: 'Tap a box number to circle it. Then check it.',
    checkLabel: 'THIS IS THE BOX',
    solvedLine: 'The crate is in Box 23 now.',
    turnLabel: 'TURN THE PAGE',
    findTask: 'Find Box 23 on this page. Tap it.',
    foundLine: 'Box 23 was collected for No. 7.',
    findBox: 'box23',
  ),
};

// ── M3 — the green boxes and the torn label ─────────────────────────────
// The quay (1536 × 1024): four green boxes in a row on the river wall,
// each with a blank brass plate on its front, measured on the plates; the
// part shown, the four boxes, (250, 490)–(1310, 910). The open box (1536 ×
// 1024): brown paper and string at its edges. The scrap (1842 × 854, cut
// out): a long torn strip, its words inside (230, 300)–(1180, 600). The
// label (1377 × 1142, cut out): its printed border inside (232, 163)–
// (1145, 1040), the eyelet at (689, 88), a water stain at (260, 864)–(386,
// 985), under where the number was; its back (the same card turned over,
// drawn on its own, a little wider round its edge).
const _quay = ScenePixels(1536, 1024);
const _label = ScenePixels(1377, 1142);
const _decoy = ScenePixels(1842, 854);

const deliveryLabel = DeliveryLabel(
  file: '$_case04/delivery_label_blank.png',
  back: '$_case04/delivery_label_back.png',
  pixels: _label,
  lines: [
    LabelLine(piece: DeliveryLabel.top, text: 'PARIS PARCEL SERVICE', left: 0, top: 196, size: 50, centred: true),
    LabelLine(piece: DeliveryLabel.top, text: 'FROM: EIFFEL TOWER', left: 285, top: 280, size: 46),
    LabelLine(piece: DeliveryLabel.top, text: 'SERVICE LEVEL', left: 285, top: 346, size: 40, faint: true),
    LabelLine(piece: DeliveryLabel.middle, text: 'CONTENTS: CLOCK PARTS', left: 285, top: 474, size: 46),
    LabelLine(piece: DeliveryLabel.middle, text: 'HANDLE WITH CARE', left: 285, top: 556, size: 36, stamp: true),
    LabelLine(piece: DeliveryLabel.bottom, text: 'TO: THE WATCHMAKERS', left: 285, top: 690, size: 46),
  ],
  // Measured on the label's transparency: the paper from x 200 to 1185
  // across every tear, down to y 1095.
  tear1: 440,
  tear2: 658,
  tear3: 788,
  paperLeft: 200,
  paperRight: 1185,
  paperBottom: 1095,
  numberLabel: 'No.',
  numberAt: Rect.fromLTRB(285, 800, 470, 862),
  addressLeft: 285,
  addressTop: 902,
  addressSize: 46,
  addressStart: 'PASSAGE D',
  addressRest: 'ES HORLOGERS',
  stampAt: Rect.fromLTRB(950, 462, 1110, 622),
  hands: _hands,
  backLines: ['Do not trust the clocks.', 'Follow the hands', 'that made them.'],
  backAt: Rect.fromLTRB(190, 826, 712, 1062),
);

final Map<String, BoxesScene> season2QuayBoxes = {
  's2_ep04_m3': BoxesScene(
    picture: '$_case04/quay_boxes.png',
    pixels: _quay,
    place: 'Four green boxes in a row on the river wall at night, each with a small brass plate',
    view: _quay.rect(250, 490, 1310, 910),
    boxes: [
      QuayBox(
        id: 'box12',
        number: '12',
        area: _quay.rect(282, 538, 448, 758),
        plateAt: _quay.rect(329, 654, 371, 698),
        note: 'Box 12 is empty. The lamp oil was collected on 15 May.',
      ),
      QuayBox(
        id: 'box17',
        number: '17',
        area: _quay.rect(448, 550, 640, 791),
        plateAt: _quay.rect(499, 681, 548, 731),
        note: 'Box 17 is empty. It was moved to Box 23.',
      ),
      QuayBox(
        id: 'box21',
        number: '21',
        area: _quay.rect(640, 560, 882, 835),
        plateAt: _quay.rect(704, 712, 764, 770),
        note: 'Box 21 is locked. It is not in the ledger.',
      ),
      QuayBox(id: 'box23', number: '23', area: _quay.rect(882, 571, 1283, 880), plateAt: _quay.rect(968, 751, 1044, 814)),
    ],
    open: '$_case04/metal_box_open.png',
    openPixels: _quay,
    openLabel: 'Inside Box 23: brown paper, string, and torn scraps of paper',
    decoy: '$_case04/decoy_label_piece.png',
    decoyPixels: _decoy,
    decoyAt: _decoy.rect(230, 300, 1180, 600),
    decoyLines: const ['TO: BOOKSTALL 12', 'QUAY 1'],
    label: deliveryLabel,
    slots: const ['top', 'middle', 'bottom'],
    boxTask: 'Which box holds the crate from the tower? Tap a box.',
    labelTask: 'Tap a piece, then tap where it goes. Or drag it.',
    checkLabel: 'CHECK THE LABEL',
  ),
};

// ── Final — the street book, then the gate ──────────────────────────────
// The street book (1024 × 1536, cut out): two tall blank pages, the left
// one written inside (115, 290)–(455, 1190), the right one (530, 290)–(920,
// 1190). The gate (1024 × 1536, cut out): its blank iron sign under the
// arch, (280, 150)–(745, 248); its lower crossbar at y 1145–1200, the
// scrap caught there; on the stage, its arch and upper gate, (0, 40)–
// (1024, 723).
const _book = ScenePixels(1024, 1536);
const _gate = ScenePixels(1024, 1536);

final Map<String, StreetBookScene> season2StreetBooks = {
  's2_ep04_final': StreetBookScene(
    book: '$_case04/street_book.png',
    bookPixels: _book,
    pages: [_book.rect(115, 290, 455, 1190), _book.rect(530, 290, 920, 1190)],
    // The keeper's own street book, as the story tells it (not a guide to
    // real streets).
    entries: const [
      StreetEntry(id: 'quai', name: "QUAI DE L'HORLOGE", lines: ["Watchmakers' shops.", 'Houses 1 to 40.'], page: 0),
      StreetEntry(
        id: 'pont',
        name: 'PASSAGE DU PONT',
        lines: ["Watchmakers' workshops.", 'Houses 1 to 20.', 'Its gate is at the top of the steps on Quay 1.'],
        page: 0,
      ),
      StreetEntry(
        id: 'horloge',
        name: "PASSAGE DE L'HORLOGE",
        lines: ["Watchmakers' shops.", 'Houses 1 to 5.', "Its gate is at the top of the keeper's steps, Quay 3."],
        page: 1,
      ),
      StreetEntry(
        id: 'horlogers',
        name: 'PASSAGE DES HORLOGERS',
        lines: ["Watchmakers' workshops.", 'Houses 1 to 12.', "Its gate is at the top of the keeper's steps, Quay 3."],
        page: 1,
      ),
    ],
    evidence: const [
      BoardEvidence(id: 'e1', evidenceId: 's2_ep04_e1'),
      BoardEvidence(id: 'e2', evidenceId: 's2_ep04_e2'),
      BoardEvidence(id: 'e3', evidenceId: 's2_ep04_e3'),
    ],
    maxEvidence: 2,
    hut: '$_case04/keeper_hut_interior.png',
    hutLabel: "Inside the keeper's hut, the street book on a shelf",
    hutPixels: _hut,
    pickTask: 'Tap an address in the street book.',
    evidenceTask: 'Choose the evidence that rules it out (one or two).',
    crossLabel: 'CROSS IT OUT',
    addressTask: 'One address is left.',
    submitLabel: 'THIS IS THE ADDRESS',
    gate: '$_case04/passage_gate.png',
    gatePixels: _gate,
    gateLabel: 'A wrought-iron gate under a stone arch, lamps on each side, its sign: PASSAGE DES HORLOGERS',
    gateView: _gate.rect(0, 40, 1024, 723),
    signAt: _gate.rect(280, 150, 745, 248),
    signLines: const ['PASSAGE DES', 'HORLOGERS'],
    scrapAt: _gate.rect(560, 1080, 850, 1240),
    label: deliveryLabel,
    hands: _hands,
  ),
};

/// What Case 04's evidence shows, drawn with its words (the stones and
/// papers are blank pictures): the River Mark, the ledger's second page,
/// the label as put back together, and its last piece in place.
final Map<String, RiverEvidenceArt> season2Case04EvidenceArt = {
  's2_ep04_e1': MarkEvidenceArt(season2RiverMarks['s2_ep04_m1']!, 'd'),
  's2_ep04_e2': LedgerEvidenceArt(season2KeeperHuts['s2_ep04_m2']!, 1),
  's2_ep04_e3': const LabelEvidenceArt(deliveryLabel, last: false),
  's2_ep04_e4': const LabelEvidenceArt(deliveryLabel, last: true),
};

/// Case 04's evidence matched with what came before: the mark follows the
/// plaque's waves; the ledger's quay is the mark's; the label was in the
/// ledger's box; the last piece is the label's own.
const Map<String, EvidenceLink> season2Case04EvidenceLinks = {
  's2_ep04_e1': EvidenceLink(to: 's2_ep03_e4', line: 'The three small waves on the brass plaque led here.'),
  's2_ep04_e2': EvidenceLink(to: 's2_ep04_e1', line: 'QUAY 3, where the River Mark is.'),
  's2_ep04_e3': EvidenceLink(to: 's2_ep04_e2', line: 'Box 23, where the ledger said the crate went.'),
  's2_ep04_e4': EvidenceLink(to: 's2_ep04_e3', line: 'The piece torn off the label.'),
};

// ── The story's pictures, mission by mission ────────────────────────────
// Each moment shows what the detective has just reached, never more: the
// hut's inside only once its door is opened, the open box only once the
// label is whole, the gate only after the case.
const _wallWhole = StoryPicture(
  file: '$_case04/quay_wall_marks.png',
  pixels: _wall,
  label: 'An old stone quay wall by the river at dusk, four carved marks in a row',
);

const _hutOutside = StoryPicture(
  file: '$_case04/keeper_hut.png',
  pixels: _hut,
  label: 'A small wooden hut by the river at night, its door open',
);

const _boxesWhole = StoryPicture(
  file: '$_case04/quay_boxes.png',
  pixels: _quay,
  label: 'Four green boxes in a row on the river wall at night',
);

const _hutInside = StoryPicture(
  file: '$_case04/keeper_hut_interior.png',
  pixels: _hut,
  label: "Inside the keeper's hut: a desk, a lamp, books on the shelves",
);

final Map<String, StoryScenes> season2Case04StoryScenes = {
  // The wall; after it, the mark by the keeper's steps; then the hut.
  's2_ep04_m1': StoryScenes(
    place: _wallWhole,
    after: StoryPicture(
      file: '$_case04/quay_wall_marks.png',
      pixels: _wall,
      crop: _wall.rect(900, 160, 1536, 760),
      label: "The fourth mark on the quay wall, beside the keeper's steps",
    ),
    next: _hutOutside,
  ),
  // The hut; after it, the ledger open on the desk; then the boxes.
  's2_ep04_m2': StoryScenes(
    place: _hutOutside,
    after: StoryPicture(
      file: '$_case04/keeper_hut_interior.png',
      pixels: _hut,
      crop: _hut.rect(0, 420, 900, 1020),
      label: "The keeper's ledger open on the desk, a lamp beside it",
    ),
    next: _boxesWhole,
  ),
  // The boxes; after it, the open box; then the hut's shelf.
  's2_ep04_m3': const StoryScenes(
    place: _boxesWhole,
    after: StoryPicture(
      file: '$_case04/metal_box_open.png',
      pixels: _quay,
      label: 'Box 23 open: brown paper and string inside',
    ),
    next: _hutInside,
  ),
  // After the case: the gate of the address.
  's2_ep04_final': StoryScenes(
    after: StoryPicture(
      file: '$_case04/passage_gate.png',
      pixels: _gate,
      crop: _gate.rect(0, 40, 1024, 1064),
      label: 'A wrought-iron gate under a stone arch, its lamps lit',
    ),
  ),
};

// ── The final, very easy (the user's rules of 2026-10-27) ────────────────
// Two addresses, not four; the label's two clues on the same screen, each
// under the evidence it comes from (the label: PASSAGE; the ledger: No. 7).
// The address itself is the story's: PASSAGE DES HORLOGERS, No. 7. The
// street book, the crossing out and the gate's scrap stay as they were for
// the page after the answer (the gate is looked at there).

/// Case 04's final played one small step at a time. Its answer is the
/// mission's own (each wrong address of the street book ruled out), so the
/// save and the Case Archive are as before.
const Map<String, EasyStepsScene> season2Case04Steps = {
  's2_ep04_final': EasyStepsScene(
    title: "THE WATCHMAKER'S ADDRESS",
    answer: 'quai:e3,pont:e1+e2,horloge:e2',
    finishLabel: 'GO TO THE GATE',
    steps: [
      EasyStep(
        id: 'address',
        say: 'Find the address.',
        panels: [
          EvidencePanel(id: 'label', evidenceId: 's2_ep04_e3', caption: 'CLUE 1: PASSAGE'),
          EvidencePanel(id: 'ledger', evidenceId: 's2_ep04_e2', caption: 'CLUE 2: No. 7'),
        ],
        does: EasyDo.choose,
        options: [
          EasyOption(id: 'pont', label: 'PASSAGE DU PONT — No. 3', feedback: 'Look at CLUE 2. Is it No. 3?'),
          EasyOption(id: 'horlogers', label: 'PASSAGE DES HORLOGERS — No. 7'),
        ],
        answer: 'horlogers',
        hints: ['Both streets are a PASSAGE. Now read CLUE 2.', 'CLUE 2 is No. 7. Which address has No. 7?'],
        lookHere: [EasyMark('ledger')],
        tell: 'PASSAGE DES HORLOGERS has No. 7.',
        done: 'PASSAGE DES HORLOGERS, No. 7!',
      ),
    ],
  ),
};
