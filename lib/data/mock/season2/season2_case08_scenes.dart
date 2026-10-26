import 'dart:ui' show Offset, Rect;

import '../../models/abbesses_puzzles.dart';
import '../../models/letter_puzzles.dart' show MapSpot;
import '../../models/river_puzzles.dart' show DrawnEvidenceArt, RiverEvidenceArt;
import '../../models/scene_exhibit.dart' show EvidenceLink;
import '../../models/scene_explore.dart' show ScenePixels;
import '../../models/story_picture.dart';
import '../../models/tower_puzzles.dart' show BoardConclusion, BoardEvidence, BoardQuestion;
import '../../models/workshop_puzzles.dart' show PictureEvidence;
import 'season2_case07_scenes.dart' show season2Case07Slip;

/// Season 2, Case 08's missions, keyed by mission id, as they are played on
/// the case's pictures (every place measured on the delivered pictures, in
/// their pixels). The answers, their feedback, the hints, the solves, their
/// Clue and Evidence, XP, coins and the save are the case's own
/// (`episode08_mock.dart`). The design: `docs/SEASON2_CASE08_SPEC.md`.

const _case08 = 'assets/seasons/season_02_paris/cases/case_08';

const _wide = ScenePixels(1536, 1024);
const _square = ScenePixels(1254, 1254);

/// The case opens on the back of Case 07's Amendment Slip: the sketch of
/// Abbesses and P. KNEW THE BAG., under its third line.
final Map<String, IntroPaper> season2IntroPapers = {
  's2_ep08': IntroPaper(afterLine: 2, paper: season2Case07Slip.turned()),
};

// ── M1 — the square of Abbesses ─────────────────────────────────────────
// The square (1536 × 1024): three corners along its far side, each with
// stone steps, one street lamp and an iron gate between two stone pillars;
// the metro entrance in the right foreground (its sign blank). Left: steps
// on the left, the lamp left of a dark green gate. Middle: the same, a
// black gate. Right: steps on the right, the lamp right of a black gate.
// The corners up close (1536 × 1024 each) are the same three, seen from a
// bench in front of each: the church above the gate in every one.
final Map<String, CornerChoiceScene> season2CornerChoices = {
  's2_ep08_m1': const CornerChoiceScene(
    square: '$_case08/abbesses_square.png',
    squarePixels: _wide,
    cornerPixels: _wide,
    corners: [
      PainterCorner(
        id: 'corner1',
        name: 'CORNER 1',
        area: Rect.fromLTRB(60, 330, 500, 640),
        file: '$_case08/corner_1.png',
        label: 'Stone steps going up on the left, an old lamp left of a dark green iron gate between two pillars, the white church above',
      ),
      PainterCorner(
        id: 'corner2',
        name: 'CORNER 2',
        area: Rect.fromLTRB(520, 330, 960, 640),
        file: '$_case08/corner_2.png',
        label: 'Stone steps going up on the left, an old lamp left of a black iron gate between two pillars, the white church above',
      ),
      PainterCorner(
        id: 'corner3',
        name: 'CORNER 3',
        area: Rect.fromLTRB(960, 320, 1300, 640),
        file: '$_case08/corner_3.png',
        label: 'Stone steps going up on the right, an old lamp right of a black iron gate between two pillars, the white church above',
      ),
    ],
    squareLabel: 'The square of Abbesses: three corners with steps, a lamp and a gate, and the metro entrance',
    task: 'Tap a corner to look closer.',
    chooseLabel: 'THIS CORNER!',
    backLabel: 'BACK TO THE SQUARE',
  ),
};

// ── M2 — the three drawings ─────────────────────────────────────────────
// P.'s drawings (1536 × 1024, cut out: the sheet (10, 15)–(1525, 1005))
// are one drawing of the corner, in register: the steps up to the left, the
// lamp's glass (395, 225)–(495, 360), the gate (640, 470)–(920, 870), the
// right margin blank from x 1150. The first: a dark sky with stars, the
// lamp lit, the gate shut. The second: a grey dawn, the lamp lit, the gate
// open, someone in a hat going up the steps (180, 460)–(380, 890) with a
// flat bag full of papers (280, 600)–(370, 710); in the margin, the badge
// drawn larger (1240, 450)–(1460, 720). The third: a white sky, the lamp
// out, nobody, a paper on the bottom step (280, 850)–(370, 895); in the
// margin, the paper drawn larger (laid by the app: `paper_study.png`).
const _study = MarginStudy(
  file: '$_case08/paper_study.png',
  pixels: _square,
  at: Rect.fromLTRB(1150, 330, 1500, 680),
);

const _dark = MorningSketch(
  id: 'dark',
  file: '$_case08/sketch_morning_1_dark.png',
  pixels: _wide,
  label: 'A pencil drawing of the corner: a dark sky with stars, the lamp lit, the gate shut, nobody on the steps',
);

const _bag = MorningSketch(
  id: 'bag',
  file: '$_case08/sketch_morning_2_bag.png',
  pixels: _wide,
  label:
      'A pencil drawing of the corner: a grey sky getting light, the lamp still lit, the gate open, someone in a hat seen from behind going up the steps with a flat bag full of papers',
  changes: [
    SketchChange(id: 'person', area: Rect.fromLTRB(180, 460, 380, 890), label: 'Someone with a bag'),
    SketchChange(id: 'gate', area: Rect.fromLTRB(640, 470, 920, 870), label: 'The gate is open'),
    SketchChange(id: 'badge', area: Rect.fromLTRB(1230, 440, 1470, 730), label: 'A little drawing in the corner'),
  ],
);

const season2LightSketch = MorningSketch(
  id: 'light',
  file: '$_case08/sketch_morning_3_light.png',
  pixels: _wide,
  label: 'A pencil drawing of the corner: a white morning sky, the lamp out, the gate open, nobody, a paper on the bottom step',
  study: _study,
  changes: [
    SketchChange(id: 'lamp', area: Rect.fromLTRB(380, 215, 510, 370), label: 'The lamp is out'),
    SketchChange(id: 'gone', area: Rect.fromLTRB(180, 460, 380, 840), label: 'The person is gone'),
    SketchChange(id: 'paper', area: Rect.fromLTRB(255, 840, 395, 910), label: 'A paper on the steps'),
    SketchChange(id: 'study', area: Rect.fromLTRB(1150, 330, 1500, 680), label: 'A little drawing in the corner'),
  ],
);

final Map<String, MorningSketchesScene> season2MorningSketches = {
  's2_ep08_m2': const MorningSketchesScene(
    sketches: [_dark, _bag, season2LightSketch],
    // On the table as the bundle opens: drawing 3, 1, 2.
    shown: ['light', 'dark', 'bag'],
    lampOff: 'light',
    slots: ['FIRST', 'NEXT', 'LAST'],
    orderTask: "Put the drawings in order. Use P.'s tag.",
    checkOrderLabel: 'CHECK THE ORDER',
    lampLine: 'This lamp is out. Can it come before the others?',
    skyLine: 'Look at the sky. Which one is darker?',
    orderedLine: 'Dark, then light, then the lamp goes out.',
    compareTask: 'Slide to lay one drawing over the other. Tap what is new.',
    questionTask: 'Where did the paper on the steps come from?',
  ),
};

// ── M3 — the torn paper ─────────────────────────────────────────────────
// The paper (1536 × 1024, cut out: (65, 85)–(1460, 915)): the Amendment
// Slip's form (its navy double border, the band at the top), torn. A deep
// V comes down from the top edge, x 620–930 at the top, its point at
// (805, 510); the right edge is torn away. The band keeps its left part:
// FILE is written there, up to the tear (its number was in the V). The
// change line's minutes start just right of the V's point (its hour was in
// it), the arrow after them; the stamp's place is lower right. A cross of
// folds (y 515, x 805), dust at the lower left. Folded (1254 × 1254, cut
// out), P.'s note clipped to it.
const _form = TornForm(
  file: '$_case08/torn_form_blank.png',
  pixels: _wide,
  paper: Rect.fromLTRB(65, 85, 1460, 915),
  fileWord: 'FILE',
  fileAt: Rect.fromLTRB(430, 152, 612, 252),
  minutes: ':00',
  minutesAt: Rect.fromLTRB(822, 430, 962, 512),
  arrowAt: Rect.fromLTRB(975, 440, 1120, 500),
  stamp: 'assets/seasons/season_02_paris/cases/case_07/office_stamp.png',
  stampAt: Rect.fromLTRB(930, 575, 1200, 845),
);

final Map<String, TornSlipScene> season2TornSlips = {
  's2_ep08_m3': const TornSlipScene(
    folded: '$_case08/folded_paper.png',
    foldedPixels: _square,
    form: _form,
    parts: [
      FormPart(id: 'border', mark: FormMark.same, area: Rect.fromLTRB(80, 115, 172, 900), name: 'The double border'),
      FormPart(id: 'band', mark: FormMark.same, area: Rect.fromLTRB(172, 130, 625, 265), name: 'The FILE band'),
      FormPart(id: 'arrow', mark: FormMark.same, area: Rect.fromLTRB(962, 420, 1140, 520), name: 'An arrow between two times'),
      FormPart(id: 'seal', mark: FormMark.same, area: Rect.fromLTRB(905, 550, 1225, 870), name: 'The purple seal'),
      FormPart(id: 'number', mark: FormMark.missing, area: Rect.fromLTRB(626, 125, 790, 280), name: 'The FILE number'),
      FormPart(id: 'hour', mark: FormMark.missing, area: Rect.fromLTRB(736, 412, 822, 530), name: 'The hour'),
      FormPart(id: 'foldAcross', area: Rect.fromLTRB(172, 490, 736, 545), line: 'Those are folds. P. folded it small.'),
      FormPart(id: 'foldDown', area: Rect.fromLTRB(780, 545, 835, 905), line: 'Those are folds. P. folded it small.'),
      FormPart(id: 'tear', area: Rect.fromLTRB(1250, 230, 1470, 915), line: 'The opera slip is not torn. Is this the same?'),
      FormPart(id: 'dust', area: Rect.fromLTRB(130, 690, 345, 875), line: 'That is dust from the steps.'),
    ],
    sealId: 'seal',
    sealChecks: [
      SealCheck(question: 'How many hands?', choices: ['None', 'One', 'Two'], answer: 'None', wrongLine: 'Look again. Is there a hand on this clock?'),
      SealCheck(question: 'What is around the clock?', choices: ['Gears', 'Leaves', 'Stars'], answer: 'Leaves', wrongLine: 'Look at the ring round the clock.'),
    ],
    folds: 3,
    unfoldTask: 'Tap the paper to unfold it.',
    sameTask: 'Tap what is the SAME as the opera slip.',
    missingTask: 'Tap where something is MISSING. What does the slip have here?',
    checkLabel: 'CHECK',
    sealTitle: 'THE SEAL, CLOSER',
    noteLines: ['I found this paper on the steps.', 'I kept it with my drawings.', '— P.'],
  ),
};

// ── Final — the paper on the drawing, and the board ─────────────────────
// Drawing 3 (above), the paper as M3 left it, turned half round at first
// (its V at the bottom). P.'s last drawing (1536 × 1024, cut out): the
// same figure from behind beside a model clock tower (700, 300)–(820, 710)
// on a stone base, tiny roofs round it; the flat bag at his side (455,
// 435)–(605, 575): its shield badge (500, 470)–(548, 518), its two buckles
// (505, 515)–(600, 562); a round basket on the grass (1085, 715)–(1260,
// 830); behind, a long palace with a dome in the middle, a round pond with
// a fountain, flowerbeds. The map of Paris (1536 × 1024): its buildings
// where `ParisLandmark` has them.
final Map<String, TornHourScene> season2TornHours = {
  's2_ep08_final': const TornHourScene(
    sketch: season2LightSketch,
    form: _form,
    startTurns: 2,
    board: PaperBoard(
      questions: [
        BoardQuestion(id: 'q1', text: 'Where did the paper come from?'),
        BoardQuestion(id: 'q2', text: 'What kind of paper is it?'),
      ],
      evidence: [
        BoardEvidence(id: 'e1', evidenceId: 's2_ep08_e1'),
        BoardEvidence(id: 'e2', evidenceId: 's2_ep08_e2'),
        BoardEvidence(id: 'e3', evidenceId: 's2_ep08_e3'),
        BoardEvidence(id: 'e4', evidenceId: 's2_ep07_e3'),
      ],
      conclusionId: 'why',
      conclusionQuestion: 'What can you say now?',
      conclusions: [
        BoardConclusion(id: 'parts', text: 'The bag was full of clock parts.'),
        BoardConclusion(id: 'fell', text: 'A paper for changing a time fell from the bag.'),
        BoardConclusion(id: 'painter', text: 'The painter carried the bag.'),
        BoardConclusion(id: 'who', text: 'Now we know who changed the opera record.'),
      ],
      linkTask: 'Tap a question. Then tap the evidence that answers it.',
      concludeTask: 'Now choose what the evidence shows.',
      solveLabel: 'SOLVE THE CASE',
    ),
    lead: NextLead(
      file: '$_case08/last_sketch_garden.png',
      pixels: _wide,
      label:
          "P.'s last drawing: a garden with a long palace and a round pond with a fountain; a little clock tower on a stone base with tiny roofs round it; someone in a hat seen from behind, a flat bag at the side; a round basket on the grass",
      bagParts: [
        LeadPart(id: 'flat', area: Rect.fromLTRB(455, 435, 605, 575), line: 'The same flat bag.'),
        LeadPart(id: 'buckles', area: Rect.fromLTRB(505, 515, 600, 562), line: 'The same two buckles.'),
        LeadPart(id: 'badge', area: Rect.fromLTRB(500, 470, 548, 518), line: 'The same shield badge.'),
      ],
      decoy: LeadPart(id: 'basket', area: Rect.fromLTRB(1085, 715, 1260, 830), line: 'That is a round basket. The bag in your notebook is flat.'),
      bagTask: 'Is it the same bag? Tap three things that match the Bag Sketch.',
      bagDone: ['P. saw the bag again, in a garden.'],
      features: ['A long palace', 'A round pond with a fountain', 'Flowerbeds'],
      mapFile: 'assets/seasons/season_02_paris/locations/map/paris_mystery.png',
      mapPixels: _wide,
      spots: [
        MapSpot(id: 'montmartre', name: 'Montmartre', at: Offset(0.555, 0.098)),
        MapSpot(id: 'gareDuNord', name: 'Gare du Nord', at: Offset(0.768, 0.200)),
        MapSpot(id: 'arcDeTriomphe', name: 'Arc de Triomphe', at: Offset(0.128, 0.246)),
        MapSpot(id: 'palaisGarnier', name: 'Palais Garnier', at: Offset(0.391, 0.273)),
        MapSpot(id: 'louvre', name: 'Louvre', at: Offset(0.501, 0.441)),
        MapSpot(id: 'eiffelTower', name: 'Eiffel Tower', at: Offset(0.120, 0.562)),
        MapSpot(id: 'notreDame', name: 'Notre-Dame', at: Offset(0.732, 0.566)),
        MapSpot(id: 'luxembourgGardens', name: 'Luxembourg Gardens', at: Offset(0.475, 0.771)),
      ],
      answer: 'luxembourgGardens',
      feedback: {
        'louvre': 'There is a palace. But where is the glass pyramid? Is there a round pond?',
        'palaisGarnier': 'That is the opera house. Is there a garden with a round pond?',
        'montmartre': 'That is the white church. Is there a palace?',
      },
      otherLine: 'Look for a palace, a round pond and flowerbeds.',
      mapTask: 'Where is this garden? Tap a place on the map.',
      chooseLabel: 'THE GARDEN IS HERE',
      doneLines: [
        'The Luxembourg Gardens!',
        'In the drawing, a little clock stands on the grass. Tiny roofs are all around it.',
        'Why did the bag go to a little clock in a garden?',
      ],
    ),
    placeHeading: 'Is it the same paper?',
    placeTask: 'Turn the paper to match the drawing in the corner. Then drag it there.',
    turnLabel: 'TURN IT',
    layLabel: 'LAY IT ON THE DRAWING',
    tearLine: 'Look at the V-shaped tear. Where is it in the drawing?',
    sealLine: 'Where is the round seal in the drawing?',
    offLine: 'P. drew the paper big in the corner. Lay it there.',
    placedLines: ['The tear, the folds and the seal all match.', 'It is the paper from the steps.'],
    leadLabel: 'LOOK AT HIS LAST DRAWING',
  ),
};

/// Case 08's evidence, one piece to the next: the corner of the Hidden
/// Sketch; the drawings made from it; the paper like the opera slip; the
/// paper in drawing 3.
const season2Case08EvidenceLinks = <String, EvidenceLink>{
  's2_ep08_e1': EvidenceLink(to: 's2_ep02_e3', line: 'The same corner as his hidden sketch.'),
  's2_ep08_e2': EvidenceLink(to: 's2_ep08_e1', line: "Drawn from the painter's corner."),
  's2_ep08_e3': EvidenceLink(to: 's2_ep07_e3', line: 'The same form and seal as the opera slip.'),
  's2_ep08_e4': EvidenceLink(to: 's2_ep08_e2', line: 'The paper on the steps in drawing 3.'),
};

/// Case 08's evidence drawn: the painter's corner, the Bag Sketch whole
/// (its badge in the margin), the torn paper with its words and seal, and
/// drawing 3 with the paper drawn in its margin.
final Map<String, RiverEvidenceArt> season2Case08EvidenceArt = {
  's2_ep08_e1': const DrawnEvidenceArt(PictureEvidence(file: '$_case08/corner_2.png', pixels: _wide)),
  's2_ep08_e2': const DrawnEvidenceArt(_bag, whole: true),
  's2_ep08_e3': const DrawnEvidenceArt(_form, whole: true),
  's2_ep08_e4': const DrawnEvidenceArt(season2LightSketch, whole: true),
};

// ── The story's pictures, mission by mission ────────────────────────────
// Each moment shows what the detective has just reached, never more: the
// square, the corner, the bundle behind the stone, the bag's drawing, the
// folded paper, the torn paper, and after the case P.'s last drawing.
const _squareWhole = StoryPicture(
  file: '$_case08/abbesses_square.png',
  pixels: _wide,
  label: 'The square of Abbesses: three corners with steps and gates, the metro entrance, the white church on the hill',
);

const _cornerWhole = StoryPicture(
  file: '$_case08/corner_2.png',
  pixels: _wide,
  label: 'The corner: steps on the left, an old lamp, a black gate between two pillars, the white church above',
);

const _bundle = StoryPicture(
  file: '$_case08/drawing_bundle.png',
  pixels: _wide,
  label: 'A loose stone pulled from the pillar; behind it, a bundle of drawings tied with string',
);

const _folded = StoryPicture(
  file: '$_case08/folded_paper.png',
  pixels: _square,
  label: 'A paper folded small, a note clipped to it',
  cutOut: true,
);

final Map<String, StoryScenes> season2Case08StoryScenes = {
  // The square; after it, the bundle behind the stone; then the corner.
  's2_ep08_m1': const StoryScenes(place: _squareWhole, after: _bundle, next: _cornerWhole),
  // The bundle; after it, the drawing of the bag; then the folded paper.
  's2_ep08_m2': StoryScenes(
    place: _bundle,
    after: StoryPicture(file: _bag.file, pixels: _wide, label: _bag.label, cutOut: true),
    next: _folded,
  ),
  // The folded paper; after it, the torn paper; then the corner again.
  's2_ep08_m3': const StoryScenes(
    place: _folded,
    after: StoryPicture(file: '$_case08/torn_form_blank.png', pixels: _wide, label: 'A torn paper with a double border, a V-shaped tear at the top', cutOut: true),
    next: _cornerWhole,
  ),
  // After the case: P.'s last drawing.
  's2_ep08_final': const StoryScenes(
    after: StoryPicture(
      file: '$_case08/last_sketch_garden.png',
      pixels: _wide,
      label: "P.'s last drawing: the same bag beside a little clock in a garden, a palace behind",
      cutOut: true,
    ),
  ),
};
