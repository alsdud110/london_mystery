import 'dart:ui' show Offset, Rect;

import '../../models/garden_puzzles.dart';
import '../../models/letter_puzzles.dart' show MapSpot;
import '../../models/river_puzzles.dart' show DrawnEvidenceArt, RiverEvidenceArt;
import '../../models/scene_exhibit.dart' show EvidenceLink;
import '../../models/scene_explore.dart' show ScenePixels;
import '../../models/story_picture.dart';

/// Season 2, Case 09's missions, keyed by mission id, as they are played on
/// the case's pictures (every place measured on the delivered pictures, in
/// their pixels). The answers, the hints, the solves, their Clue and
/// Evidence, XP, coins and the save are the case's own
/// (`episode09_mock.dart`). The design: `docs/SEASON2_CASE09_SPEC.md`.

const _case08 = 'assets/seasons/season_02_paris/cases/case_08';
const _case09 = 'assets/seasons/season_02_paris/cases/case_09';
const _map = 'assets/seasons/season_02_paris/locations/map/paris_mystery.png';

const _wide = ScenePixels(1536, 1024);
const _square = ScenePixels(1254, 1254);

// ── The garden ──────────────────────────────────────────────────────────
// The garden (1536 × 1024, as P. drew it): the palace with its dome, the
// round pond and its fountain, the little clock tower on its stone base
// (its face (693, 479)–(753, 544), no hands), three tiny roofs round it.
// At the right edge, the garden clock on its post: its face, round
// (1412, 325)–(1506, 420), has painted hands at ten past ten. The story
// wants it at four: it is covered with the case's own dial and the app's
// hands, or left out of the picture.
const _dial = '$_case09/clock_dial.png';

/// The dial's pivot (its brass dot) and its white face's radius, in its
/// own pixels (1254 × 1254, cut out).
const _dialPivot = Offset(625, 616);
const _dialFace = 495.0;

const _gardenClock = GardenClock(
  face: Rect.fromLTRB(1412, 325, 1506, 420),
  dial: _dial,
  dialPixels: _square,
  pivot: _dialPivot,
  faceRadius: _dialFace,
);

/// The garden without its clock's edge (the story's pictures): the part
/// left of the garden clock.
const _gardenNoClock = Rect.fromLTRB(0, 0, 1380 / 1536, 1);

/// The case opens on P.'s last drawing (Case 08's), shown from the first
/// line ("You look at P.'s last drawing again."), which turns into the
/// garden it shows as the detective walks in.
final Map<String, IntroPicture> season2IntroPictures = {
  's2_ep09': const IntroPicture(
    afterLine: 0,
    turnAtLine: 3,
    from: '$_case08/last_sketch_garden.png',
    to: '$_case09/garden_model_view.png',
    pixels: _wide,
    fromLabel: "P.'s last drawing: a palace, a round pond, a little clock on a stone base, the same flat bag beside it",
    toLabel: 'The Luxembourg Gardens: the palace, the round pond, the little clock tower on its stone base, the garden clock at four',
    clock: _gardenClock,
  ),
};

// ── M1 — the little clocks back on the map ──────────────────────────────
// The map of Paris (1536 × 1024): its places where `ParisLandmark` has
// them. The three little clocks (1254 × 1254, cut out): T1 the arch, a
// twelve-point star on its base; T2 the bridge of three arches with its
// green bookstalls, three arches on its base; T3 the long hall with one
// tall spire, a bell on its base.
const _spots = [
  MapSpot(id: 'montmartre', name: 'Montmartre', at: Offset(0.555, 0.098)),
  MapSpot(id: 'gareDuNord', name: 'Gare du Nord', at: Offset(0.768, 0.200)),
  MapSpot(id: 'arcDeTriomphe', name: 'Arc de Triomphe', at: Offset(0.128, 0.246)),
  MapSpot(id: 'palaisGarnier', name: 'Palais Garnier', at: Offset(0.391, 0.273)),
  MapSpot(id: 'artsEtMetiers', name: 'Arts et Métiers', at: Offset(0.684, 0.381)),
  MapSpot(id: 'louvre', name: 'Louvre', at: Offset(0.501, 0.441)),
  MapSpot(id: 'eiffelTower', name: 'Eiffel Tower', at: Offset(0.120, 0.562)),
  MapSpot(id: 'notreDame', name: 'Notre-Dame', at: Offset(0.732, 0.566)),
  MapSpot(id: 'seineQuays', name: 'Seine Quays', at: Offset(0.602, 0.596)),
  MapSpot(id: 'luxembourgGardens', name: 'Luxembourg Gardens', at: Offset(0.475, 0.771)),
];

const _t1 = TrialModel(
  id: 't1',
  name: 'T1',
  file: '$_case09/clock_model_t1.png',
  label: 'T1: a little arch with a clock on top, a star carved on its base',
  spot: 'arcDeTriomphe',
  wrongLine: 'Look for a big arch.',
  sign: 'a star',
);

const _t2 = TrialModel(
  id: 't2',
  name: 'T2',
  file: '$_case09/clock_model_t2.png',
  label: 'T2: a little bridge of three arches with green bookstalls and a clock, three arches carved on its base',
  spot: 'seineQuays',
  wrongLine: 'Look for a bridge with green bookstalls.',
  sign: 'three arches',
);

const _t3 = TrialModel(
  id: 't3',
  name: 'T3',
  file: '$_case09/clock_model_t3.png',
  label: 'T3: a little long hall with one tall spire and a clock, a bell carved on its base',
  spot: 'artsEtMetiers',
  wrongLine: 'Look for one tall spire, north of the river.',
  sign: 'a bell',
);

const season2TrialMap = TrialMapScene(
  mapFile: _map,
  mapPixels: _wide,
  spots: _spots,
  models: [_t1, _t2, _t3],
  modelPixels: _square,
  task: 'Drag each little clock to its place on the map.',
  // About half the way to the nearest other place.
  dropRadius: 120,
  specialLines: {'t3:notreDame': 'Notre-Dame has two towers. Find one tall spire.'},
  placedLine: 'Click! It fits.',
);

final Map<String, TrialMapScene> season2TrialMaps = {'s2_ep09_m1': season2TrialMap};

// ── M2 — the gear board ─────────────────────────────────────────────────
// The board (1536 × 1024): a brass panel, a blank band along its top
// (148, 62)–(1392, 152), the plate (150, 160)–(1390, 680), and a tray
// sunk along the bottom (215, 695)–(1330, 885). Nothing is on it: the
// tower's wheel, the gears, the dials and the places are the app's, laid
// where gears that touch turn each other (centres (r₁ + r₂) × 0.88 apart).
// Only the plate is shown (`view`), as large as the page allows: the two
// gears wait under it, not in the picture's tray.
// The gear (1254 × 1254, cut out): ten teeth, centred; its teeth reach
// 589 from the centre.
const season2GearBoard = GearBoardScene(
  file: '$_case09/gear_board.png',
  pixels: _wide,
  view: Rect.fromLTRB(110, 140, 1426, 735),
  gearFile: '$_case09/gear_brass.png',
  gearPixels: _square,
  dialFile: _dial,
  dialPixels: _square,
  dialPivot: _dialPivot,
  radii: {GearSize.big: 135, GearSize.small: 95},
  slots: [
    GearSlot(id: 'slot1', size: GearSize.big, at: Offset(530, 299), branch: 'top'),
    GearSlot(id: 'slot2', size: GearSize.small, at: Offset(490, 594), branch: 'low'),
  ],
  fixed: [
    FixedGear(at: Offset(330, 450), radius: 150),
    FixedGear(at: Offset(670, 594), radius: 110, branch: 'low'),
  ],
  clocks: [
    BoardClock(id: 't1', name: 'T1', at: Offset(728, 299), radius: 90, branch: 'top'),
    BoardClock(id: 't2', name: 'T2', at: Offset(846, 594), radius: 90, branch: 'low', clockwise: false),
    BoardClock(id: 't3', name: 'T3', at: Offset(1004, 594), radius: 90, branch: 'low'),
    BoardClock(id: 'garden', name: 'GARDEN', at: Offset(1240, 330), radius: 90),
  ],
  tray: {GearSize.big: Offset(560, 790), GearSize.small: Offset(900, 790)},
  task: 'Drag each gear into a dotted circle.',
  tooBig: 'Too big!',
  tooSmall: 'Too small!',
  oneMore: 'One more gear!',
  turningLine: 'T1, T2 and T3 turn. The garden clock stays still.',
);

final Map<String, GearBoardScene> season2GearBoards = {'s2_ep09_m2': season2GearBoard};

// ── M3 — the maker's marks ──────────────────────────────────────────────
// The plan (1536 × 1024, cut out: the sheet (30, 74)–(1518, 942)): a
// blueprint of a gear board. Lower right, an empty circle (1240, 806) and a
// blank line (1280, 783)–(1411, 810): the emblem's place. Pinned top right,
// a cream note turned 12.3° clockwise (its rules rise 0.218 a pixel): two
// ruled rows, (1177, 200)–(1388, 246) and (1159, 272)–(1370, 318), each
// ending in an empty square, centred (1438, 246) and (1414, 324). The words
// sit on the rules and the marks in the squares, turned with the note.
const season2MakerMarks = MakerMarksScene(
  file: '$_case09/chronos_plan.png',
  pixels: _wide,
  handsFile: 'assets/seasons/season_02_paris/cases/case_04/hands_sign.png',
  handsPixels: _square,
  marks: [
    NotebookMark(id: 'a', kind: MarkKind.gear, name: "The Clockmaker's Mark", source: 'Gare du Nord', evidenceId: 's2_ep01_e3'),
    NotebookMark(id: 'b', kind: MarkKind.hands, name: 'The Repair Card', source: 'No. 7', evidenceId: 's2_ep05_e1'),
  ],
  paper: [
    PaperMark(
      id: 'emblem',
      kind: MarkKind.gear,
      name: 'The plan',
      words: 'CHRONOS TRIAL\nEMBLEM',
      markAt: Rect.fromLTRB(1200, 766, 1280, 846),
      wordsAt: Rect.fromLTRB(1150, 690, 1440, 762),
      crop: Rect.fromLTRB(1110, 670, 1470, 900),
      light: true,
    ),
    PaperMark(
      id: 'repair',
      kind: MarkKind.hands,
      name: 'The repair note',
      words: 'REPAIRS · T2 WHEEL',
      markAt: Rect.fromLTRB(1413, 221, 1463, 271),
      wordsAt: Rect.fromLTRB(1184, 193, 1380, 223),
      crop: Rect.fromLTRB(1145, 186, 1475, 248),
      angle: 0.2146,
    ),
    PaperMark(
      id: 'key',
      kind: MarkKind.key,
      name: 'The repair note',
      words: 'REPAIRS · T3 GLASS',
      markAt: Rect.fromLTRB(1389, 299, 1439, 349),
      wordsAt: Rect.fromLTRB(1166, 266, 1362, 296),
      crop: Rect.fromLTRB(1125, 258, 1455, 320),
      angle: 0.2146,
    ),
  ],
  task: 'Tap a mark from your notebook. Then tap the same mark on the old paper.',
  pickFirst: 'First tap a mark from your notebook.',
  lines: {
    'a:repair': 'Is that a gear?',
    'a:key': 'Is that a gear?',
    'b:emblem': 'Count the hands.',
    'b:key': 'That is a key. Look for two hands.',
  },
);

final Map<String, MakerMarksScene> season2MakerMarksScenes = {'s2_ep09_m3': season2MakerMarks};

// ── Final — the wrong hour ──────────────────────────────────────────────
const season2TowerTest = TowerTestScene(
  garden: '$_case09/garden_model_view.png',
  gardenPixels: _wide,
  gardenLabel: 'The Luxembourg Gardens: the little clock tower on its stone base; the garden clock at four',
  gardenClock: _gardenClock,
  dialFile: _dial,
  dialPixels: _square,
  dialPivot: _dialPivot,
  dialRadius: _dialFace,
  startHour: 4,
  targetHour: 3,
  clocks: [
    TestClock(id: 't1', name: 'T1', joined: true),
    TestClock(id: 't2', name: 'T2', joined: true),
    TestClock(id: 't3', name: 'T3', joined: true),
    TestClock(id: 'garden', name: 'GARDEN', joined: false),
  ],
  handsLine: 'Click, click. The hands are back on.',
  testLabel: 'TEST',
  hourLines: {
    5: 'That is one hour forward. Go back.',
    2: 'That is two hours back. Just one.',
    4: 'The tower still says four. Move it one hour back.',
    0: 'Just one hour back: from 4 to 3.',
  },
  testedLines: ['The tower says three.', 'T1, T2 and T3 went to three with it. The garden clock still says four.'],
  afterLines: ['The model shows what could happen. But what really happened?', 'We know what the model can do.', 'The records may tell us.'],
  lead: StarLead(
    title: 'THE DRUM UNDER T1',
    tag: 'TRIAL RECORDS · KEPT AT THE STAR',
    question: 'Which trial clock has the star?',
    models: [_t1, _t2, _t3],
    modelPixels: _square,
    answer: 't1',
    otherLine: 'Look at the sign on its base. Find the star.',
    foundLine: 'The star is under T1.',
    mapFile: _map,
    mapPixels: _wide,
    spot: MapSpot(id: 'arcDeTriomphe', name: 'Arc de Triomphe', at: Offset(0.128, 0.246)),
    doneLines: ['T1 stands at the Arc de Triomphe.', 'Twelve roads meet there, like a star.', 'The real records may be kept there. We must read them.'],
  ),
  leadLabel: 'FOLLOW THE STAR',
);

final Map<String, TowerTestScene> season2TowerTests = {'s2_ep09_final': season2TowerTest};

/// Case 09's evidence, one piece to the next: the clocks on the map; the
/// board that turns them; the marks like the Clockmaker's; the test on the
/// clocks the board turns.
const season2Case09EvidenceLinks = <String, EvidenceLink>{
  's2_ep09_e2': EvidenceLink(to: 's2_ep09_e1', line: 'The same three trial clocks.'),
  's2_ep09_e3': EvidenceLink(to: 's2_ep01_e3', line: "The same gear as the Clockmaker's mark."),
  's2_ep09_e4': EvidenceLink(to: 's2_ep09_e2', line: 'The same three clocks the tower turns.'),
};

/// Case 09's evidence drawn: the map with its little clocks, the board with
/// its gears in, the plan with its marks, and the clocks after the test.
final Map<String, RiverEvidenceArt> season2Case09EvidenceArt = {
  's2_ep09_e1': const DrawnEvidenceArt(TrialMapPaper(season2TrialMap), whole: true),
  's2_ep09_e2': const DrawnEvidenceArt(GearDiagram(season2GearBoard), whole: true),
  's2_ep09_e3': const DrawnEvidenceArt(MarksPaper(season2MakerMarks), whole: true),
  's2_ep09_e4': const DrawnEvidenceArt(TestCard(season2TowerTest), whole: true),
};

// ── The story's pictures, mission by mission ────────────────────────────
// Each moment shows what the detective has just reached, never more: the
// garden (left of its clock, whose painted hands the story does not
// want), T1 with its star, the board, the gear, the plan.
const _garden = StoryPicture(
  file: '$_case09/garden_model_view.png',
  pixels: _wide,
  crop: _gardenNoClock,
  label: 'The Luxembourg Gardens: the palace, the round pond, the little clock tower on its stone base',
);

const _starClock = StoryPicture(
  file: '$_case09/clock_model_t1.png',
  pixels: _square,
  label: 'T1: a little arch with a clock on top, a star carved on its base',
  cutOut: true,
);

const _board = StoryPicture(
  file: '$_case09/gear_board.png',
  pixels: _wide,
  label: 'A brass board in a little stone niche under the model',
);

const _plan = StoryPicture(
  file: '$_case09/chronos_plan.png',
  pixels: _wide,
  label: 'An old blue plan of gears, a repair note pinned to it',
  cutOut: true,
);

final Map<String, StoryScenes> season2Case09StoryScenes = {
  // The garden; after it, T1 and its star; then the board.
  's2_ep09_m1': const StoryScenes(place: _garden, after: _starClock, next: _board),
  // The board; after it, a gear; then the plan.
  's2_ep09_m2': const StoryScenes(
    place: _board,
    after: StoryPicture(file: '$_case09/gear_brass.png', pixels: _square, label: 'A brass gear', cutOut: true),
    next: _plan,
  ),
  // The plan; after it, the plan again; then the tower in the garden.
  's2_ep09_m3': const StoryScenes(place: _plan, after: _plan, next: _garden),
  // After the case: T1 and its star.
  's2_ep09_final': const StoryScenes(after: _starClock),
};
