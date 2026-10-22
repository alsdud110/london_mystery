import 'dart:ui' show Offset, Rect;

import '../../models/letter_puzzles.dart';
import '../../models/river_puzzles.dart' show DrawnEvidenceArt, RiverEvidenceArt;
import '../../models/scene_exhibit.dart' show EvidenceLink;
import '../../models/scene_explore.dart' show ScenePixels;
import '../../models/story_picture.dart';
import '../../models/workshop_puzzles.dart' show PictureEvidence, WrittenPaper;
import 'season2_case05_scenes.dart' show season2PostTrails;

/// Season 2, Case 06's missions, keyed by mission id: first as rules, then
/// as they are played on the case's pictures (every place measured on the
/// delivered pictures, in their pixels). The answers, their feedback, the
/// hints, the solves, their Clue and Evidence, XP, coins and the save are
/// the case's own (`episode06_mock.dart`).

/// M1: what Case 05's Letter's Trail says of letter No. 4417 (its third
/// slip: 16 MAY · 4:00 PM · HELD · LOUVRE POST ROOM), and the four tags.
/// A and B are told apart by their fronts; ink hides a digit on C and D,
/// so only their backs tell which was held on 16 May at 4:00 PM.
const season2HoldRacks = <String, HoldRack>{
  's2_ep06_m1': HoldRack(
    clue: TagClue(kind: PostKind.letter, number: '4417', date: '16 MAY', time: '4:00 PM'),
    tags: [
      HoldTag(id: 'a', kind: PostKind.parcel, number: '4417', date: '16 MAY', time: '4:00 PM', record: 'HELD', reason: ['NO STAMP']),
      HoldTag(id: 'b', kind: PostKind.letter, number: '4471', date: '16 MAY', time: '4:00 PM', record: 'HELD', reason: ['ADDRESS NOT CLEAR']),
      HoldTag(id: 'c', kind: PostKind.letter, number: '44?7', date: '15 MAY', time: '11:00 AM', record: 'HELD', reason: ['WRONG ADDRESS']),
      HoldTag(
        id: 'd',
        kind: PostKind.letter,
        number: '4?17',
        date: '16 MAY',
        time: '4:00 PM',
        record: 'HELD',
        reason: ['PRESERVATION ORDER', 'Keep it safe.', 'Do not send it.', 'Do not throw it away.'],
      ),
    ],
  ),
};

/// M2: the corridor down the stairs, as the letter walks it (left is the
/// letter's left). Before the statue, one door each side; past it, two.
/// The note: past the statue, the second door on the left.
const season2PlanRoutes = <String, PlanRoute>{
  's2_ep06_m2': PlanRoute(
    doors: [
      PlanDoor(id: 'a', side: Side.left, pastStatue: false, nth: 1),
      PlanDoor(id: 'b', side: Side.right, pastStatue: false, nth: 1),
      PlanDoor(id: 'c', side: Side.left, pastStatue: true, nth: 1),
      PlanDoor(id: 'd', side: Side.right, pastStatue: true, nth: 1),
      PlanDoor(id: 'e', side: Side.left, pastStatue: true, nth: 2),
      PlanDoor(id: 'f', side: Side.right, pastStatue: true, nth: 2),
    ],
    directions: Directions(pastStatue: true, side: Side.left, nth: 2),
    archive: 'e',
  ),
};

/// M3: four drawers (the parcels' has the same numbers as the right one),
/// and in LETTERS 4400–4599 three torn envelopes. The corner from Clock III
/// (Case 05, its label No. 4417) fits the second.
const season2ArchiveDrawers = <String, ArchiveDrawers>{
  's2_ep06_m3': ArchiveDrawers(
    drawers: [
      ArchiveDrawer(id: 'l4000', kind: PostKind.letter, from: 4000, to: 4199),
      ArchiveDrawer(id: 'l4200', kind: PostKind.letter, from: 4200, to: 4399),
      ArchiveDrawer(id: 'l4400', kind: PostKind.letter, from: 4400, to: 4599),
      ArchiveDrawer(id: 'p4400', kind: PostKind.parcel, from: 4400, to: 4599),
    ],
    kind: PostKind.letter,
    number: 4417,
    envelopes: [
      TornEnvelope(id: 'x', tear: 'straight'),
      TornEnvelope(id: 'y', tear: 'clock3'),
      TornEnvelope(id: 'z', tear: 'jagged'),
    ],
    cornerTear: 'clock3',
    cornerLabel: 'No. 4417',
  ),
};

/// The final: the letter's drawing (a dome, statues on the roof, arched
/// windows: the opera house) and the buildings of the map of Paris
/// (`paris_mystery.png`), as drawn there. Montmartre's church has domes
/// and arches but no statues on its roof and no shows; the Louvre has
/// statues and arches but a glass pyramid, no dome.
const season2LetterMaps = <String, LetterMap>{
  's2_ep06_final': LetterMap(
    drawing: {BuildingFeature.dome, BuildingFeature.roofStatues, BuildingFeature.archedWindows},
    buildings: [
      MapBuilding(id: 'montmartre', features: {BuildingFeature.dome, BuildingFeature.archedWindows}),
      MapBuilding(id: 'louvre', features: {BuildingFeature.roofStatues, BuildingFeature.archedWindows, BuildingFeature.pyramid}),
      MapBuilding(id: 'arcDeTriomphe', features: {BuildingFeature.bigArch}),
      MapBuilding(id: 'gareDuNord', features: {BuildingFeature.glassRoof, BuildingFeature.archedWindows}),
      MapBuilding(id: 'notreDame', features: {BuildingFeature.twoTowers, BuildingFeature.spire}),
      MapBuilding(id: 'eiffelTower', features: {BuildingFeature.ironTower}),
      MapBuilding(
        id: 'palaisGarnier',
        features: {BuildingFeature.dome, BuildingFeature.roofStatues, BuildingFeature.archedWindows},
        shows: true,
      ),
    ],
    back: ['OPERA ARCHIVE', 'FILE 3–4'],
  ),
};

/// Case 06's evidence, one piece to the next: the tag is letter No. 4417's
/// of the Letter's Trail (Case 05); the note follows the tag's order; the
/// envelope is found by the corner from Clock III; the letter is in it.
const season2Case06EvidenceLinks = <String, EvidenceLink>{
  's2_ep06_e1': EvidenceLink(to: 's2_ep05_e4', line: 'LETTER No. 4417, held on 16 May at 4:00 PM, as on its slip.'),
  's2_ep06_e2': EvidenceLink(to: 's2_ep06_e1', line: 'Letters that must be kept safe go downstairs.'),
  's2_ep06_e3': EvidenceLink(to: 's2_ep05_e3', line: 'The torn corner from Clock III, No. 4417 on its label.'),
  's2_ep06_e4': EvidenceLink(to: 's2_ep06_e3', line: 'Found inside the torn envelope.'),
};

// ── The pictures ────────────────────────────────────────────────────────

const _case06 = 'assets/seasons/season_02_paris/cases/case_06';

// ── M1 — the hold rack ──────────────────────────────────────────────────
// The rack (1536 × 1024): twelve slots, 4 × 3, one empty (the middle row's
// second). Four blank tags hang from it, measured on their paper (the
// string above it): under the top row's first slot (380, 322)–(460, 462),
// its third (912, 322)–(988, 462) and its fourth (1196, 322)–(1278, 465),
// and under the bottom row's first (390, 775)–(465, 908). The rack itself,
// (225, 70)–(1360, 925). A tag up close (1254 × 1254, cut out): its paper
// (322, 262)–(932, 1236), the eyelet at (626, 380); it is written below the
// eyelet. The ink (1254 × 1254, cut out): a blot, (113, 256)–(1178, 983).
const _rack = ScenePixels(1536, 1024);
const _wide = ScenePixels(1536, 1024);
const _tag = ScenePixels(1254, 1254);

final Map<String, HoldRackScene> season2HoldRackScenes = {
  's2_ep06_m1': HoldRackScene(
    rack: season2HoldRacks['s2_ep06_m1']!,
    file: '$_case06/post_room_hold_rack.png',
    pixels: _rack,
    view: const Rect.fromLTRB(215, 60, 1370, 935),
    place: 'A wooden rack of slots full of letters and parcels, one slot empty, four paper tags hanging from it',
    tags: const [
      RackTag(id: 'a', spot: Rect.fromLTRB(330, 280, 510, 485), paper: Rect.fromLTRB(380, 322, 460, 462)),
      RackTag(id: 'b', spot: Rect.fromLTRB(862, 280, 1038, 485), paper: Rect.fromLTRB(912, 322, 988, 462)),
      RackTag(id: 'c', spot: Rect.fromLTRB(1146, 280, 1328, 488), paper: Rect.fromLTRB(1196, 322, 1278, 465)),
      RackTag(id: 'd', spot: Rect.fromLTRB(340, 740, 515, 925), paper: Rect.fromLTRB(390, 775, 465, 908)),
    ],
    tagFile: '$_case06/hold_tag_blank.png',
    tagPixels: _tag,
    writeOn: const Rect.fromLTRB(372, 478, 882, 1186),
    ink: '$_case06/ink_blot.png',
    trail: season2PostTrails['s2_ep05_final']!.paperOf(season2PostTrails['s2_ep05_final']!.slipOf('s3')),
    lookTask: 'Tap a tag to look at it closely.',
    turnTask: 'Turn the tag over to read its back.',
    turnLabel: 'TURN IT OVER',
    turnBackLabel: 'TURN IT BACK',
    chooseLabel: 'THIS IS THE TAG',
  ),
};

// ── M2 — the plan on the wall ───────────────────────────────────────────
// The plan (1024 × 1536, seen from above, read from the bottom up): the
// post room (295, 1135)–(725, 1470), its door at the bottom; the stairs
// (425, 945)–(600, 1125); the corridor x 415–605 up to the top; the statue
// on its plinth at (512, 650). Doors open off the corridor's walls (a gap
// and its swing): before the statue one each side at y 810–905; past it,
// two each side, at y 475–585 and y 245–360. The letter walks up the page:
// its left is the plan's left.
const _plan = ScenePixels(1024, 1536);

final Map<String, PlanScene> season2PlanScenes = {
  's2_ep06_m2': PlanScene(
    route: season2PlanRoutes['s2_ep06_m2']!,
    file: '$_case06/archive_floor_plan.png',
    pixels: _plan,
    view: const Rect.fromLTRB(250, 180, 774, 1490),
    place: 'A plan of the building seen from above: the post room at the bottom, stairs, a long corridor with a statue, and doors on both sides',
    start: const Offset(512, 1400),
    steps: const {
      PlanStep.stairs: PlanPlace(at: Offset(512, 1035), area: Rect.fromLTRB(420, 940, 605, 1128)),
      PlanStep.statue: PlanPlace(at: Offset(512, 565), area: Rect.fromLTRB(458, 600, 568, 770)),
    },
    doors: const [
      PlanDoorSpot(id: 'a', at: Offset(448, 858), area: Rect.fromLTRB(275, 788, 455, 932), badge: Offset(342, 858)),
      PlanDoorSpot(id: 'b', at: Offset(576, 858), area: Rect.fromLTRB(569, 788, 749, 932), badge: Offset(682, 858)),
      PlanDoorSpot(id: 'c', at: Offset(448, 530), area: Rect.fromLTRB(275, 456, 455, 598), badge: Offset(342, 530)),
      PlanDoorSpot(id: 'd', at: Offset(576, 530), area: Rect.fromLTRB(569, 456, 749, 598), badge: Offset(682, 530)),
      PlanDoorSpot(id: 'e', at: Offset(448, 305), area: Rect.fromLTRB(275, 228, 455, 380), badge: Offset(342, 305)),
      PlanDoorSpot(id: 'f', at: Offset(576, 305), area: Rect.fromLTRB(569, 228, 749, 380), badge: Offset(682, 305)),
    ],
    task: 'Tap the plan to move the letter, one step at a time.',
    stairsFirst: 'Go down the stairs first.',
    statueFirst: 'Walk past the statue first.',
    goLabel: 'GO THROUGH DOOR',
  ),
};

// ── M3 — the archive ────────────────────────────────────────────────────
// The cabinet (1254 × 1254): four drawers, 2 × 2, each a brass label
// holder with a blank card and a cup handle: top left (185, 240)–(612,
// 605), its card (300, 315)–(505, 420); top right (657, 240)–(1083, 605),
// (773, 315)–(982, 420); bottom left (185, 655)–(612, 1040), (300, 733)–
// (505, 838); bottom right (657, 655)–(1083, 1040), (773, 733)–(982, 838).
// The open drawer (1536 × 1024, from above): empty green felt (245, 85)–
// (1375, 715), its front and handle below. The envelopes and the corner
// (1474 × 1067 each, cut out) share one canvas: laid at its origin, the
// corner sits on the right envelope where it was torn from. The corner's
// paper (118, 105)–(1023, 811), its sticker (203, 180)–(665, 438); the right
// envelope's round seal spot, centre (1195, 780), radius 100. Only the
// right one has the spot: the archive's number tag is stuck over that place
// on all three (on paper on each), so the torn edge alone tells them apart.
const _cabinet = ScenePixels(1254, 1254);
const _drawer = ScenePixels(1536, 1024);
const _envelopes = ScenePixels(1474, 1067);
const _seal = ScenePixels(1254, 1254);

final Map<String, ArchiveScene> season2ArchiveScenes = {
  's2_ep06_m3': ArchiveScene(
    drawers: season2ArchiveDrawers['s2_ep06_m3']!,
    cabinet: '$_case06/archive_cabinet.png',
    cabinetPixels: _cabinet,
    cabinetView: const Rect.fromLTRB(105, 140, 1150, 1190),
    // Where each drawer of the rules is in the cabinet: the parcels' beside
    // the letters with the same numbers.
    cabinetDrawers: const [
      CabinetDrawer(id: 'l4000', area: Rect.fromLTRB(185, 240, 612, 605), label: Rect.fromLTRB(302, 318, 503, 418)),
      CabinetDrawer(id: 'p4400', area: Rect.fromLTRB(657, 240, 1083, 605), label: Rect.fromLTRB(775, 318, 980, 418)),
      CabinetDrawer(id: 'l4400', area: Rect.fromLTRB(185, 655, 612, 1040), label: Rect.fromLTRB(302, 736, 503, 836)),
      CabinetDrawer(id: 'l4200', area: Rect.fromLTRB(657, 655, 1083, 1040), label: Rect.fromLTRB(775, 736, 980, 836)),
    ],
    drawer: '$_case06/archive_drawer_open.png',
    drawerPixels: _drawer,
    drawerView: const Rect.fromLTRB(170, 50, 1450, 830),
    felt: const Rect.fromLTRB(300, 140, 1330, 690),
    envelopes: const [
      DrawerEnvelope(id: 'x', file: '$_case06/torn_envelope_decoy_a.png', inDrawer: Rect.fromLTRB(196, 180, 636, 498.5)),
      DrawerEnvelope(id: 'y', file: '$_case06/torn_envelope_match.png', inDrawer: Rect.fromLTRB(538, 142, 978, 460.5)),
      DrawerEnvelope(id: 'z', file: '$_case06/torn_envelope_decoy_b.png', inDrawer: Rect.fromLTRB(880, 196, 1320, 514.5)),
    ],
    envelopePixels: _envelopes,
    corner: '$_case06/torn_corner_4417.png',
    cornerPiece: const Rect.fromLTRB(118, 105, 1023, 811),
    cornerTagAt: const Rect.fromLTRB(225, 200, 645, 418),
    // On every envelope, over the seal spot (centre (1195, 780), radius 100).
    numberTag: Rect.fromCircle(center: const Offset(1195, 780), radius: 122),
    seal: '$_case06/opera_seal.png',
    sealPixels: _seal,
    sealAt: const Rect.fromLTRB(1083, 668, 1307, 892),
    cabinetTask: 'Read the labels. Tap the drawer for Letter 4417.',
    drawerTask: 'Tap an envelope to look at its torn edge.',
    layTask: 'Drag the torn corner onto the envelope.',
    layLabel: 'LAY THE CORNER ON IT',
    notHere: '{label}. Is 4417 between these two numbers?',
    notLetters: '{label}. This drawer is for parcels.',
    notFit: 'The torn edges do not match.',
    sealLabel: 'A red wax seal with a tiny drawing of a grand building: a dome, statues on the roof, arched windows',
    sealLine: 'A tiny picture of a grand building.',
  ),
};

// ── Final — the letter and the map ──────────────────────────────────────
// The letter (1086 × 1448, cut out): its paper (42, 47)–(1056, 1408),
// folded in three (the folds at y 533 and y 938). Its two lines are written
// in the top third; the drawing (1448 × 1086, cut out: the opera house's
// front in ink, (41, 123)–(1404, 1031)) is laid across the other two. The
// map of Paris (1536 × 1024): the buildings where the map's landmarks are.
const _letter = ScenePixels(1086, 1448);
const _sketch = ScenePixels(1448, 1086);
const _map = ScenePixels(1536, 1024);

const _letterPaper = LetterPaper(
  file: '$_case06/letter_paper_open.png',
  pixels: _letter,
  lines: ['The clocks may lie.', 'But the show remembers.'],
  writeOn: Rect.fromLTRB(110, 150, 980, 470),
  sketch: '$_case06/opera_sketch.png',
  sketchAt: Rect.fromLTRB(120, 640, 966, 1274),
  back: ['OPERA ARCHIVE', 'FILE 3–4'],
  backOn: Rect.fromLTRB(140, 560, 950, 900),
);

final Map<String, LetterMapScene> season2LetterMapScenes = {
  's2_ep06_final': LetterMapScene(
    map: season2LetterMaps['s2_ep06_final']!,
    letter: _letterPaper,
    sketchPixels: _sketch,
    mapFile: 'assets/seasons/season_02_paris/locations/map/paris_mystery.png',
    mapPixels: _map,
    // The map's own landmarks (`ParisLandmark`), in the order of the
    // case's options.
    spots: const [
      MapSpot(id: 'montmartre', name: 'Montmartre', at: Offset(0.555, 0.098)),
      MapSpot(id: 'louvre', name: 'Louvre', at: Offset(0.501, 0.441)),
      MapSpot(id: 'arcDeTriomphe', name: 'Arc de Triomphe', at: Offset(0.128, 0.246)),
      MapSpot(id: 'gareDuNord', name: 'Gare du Nord', at: Offset(0.768, 0.200)),
      MapSpot(id: 'notreDame', name: 'Notre-Dame', at: Offset(0.732, 0.566)),
      MapSpot(id: 'eiffelTower', name: 'Eiffel Tower', at: Offset(0.120, 0.562)),
      MapSpot(id: 'palaisGarnier', name: 'Palais Garnier', at: Offset(0.391, 0.273)),
    ],
    closer: 0.3,
    mapTask: 'Tap a building on the map to look at it closely.',
    drawingLabel: 'An ink drawing of a grand building: a low dome, statues on the roof corners, rows of arched windows and columns',
    chooseLabel: 'THIS IS THE BUILDING',
    backLabel: 'BACK TO THE MAP',
  ),
};

/// Case 06's evidence, drawn with its words: Tag D's back, the plan the
/// note is pinned to, the envelope with its corner and seal, the letter.
final Map<String, RiverEvidenceArt> season2Case06EvidenceArt = {
  's2_ep06_e1': DrawnEvidenceArt(
    WrittenPaper(
      file: '$_case06/hold_tag_blank.png',
      pixels: _tag,
      writeOn: const Rect.fromLTRB(372, 478, 882, 1186),
      lines: season2HoldRacks['s2_ep06_m1']!.tag('d').back,
      label: 'The back of a paper tag',
      size: 52,
    ),
  ),
  's2_ep06_e2': const DrawnEvidenceArt(PictureEvidence(file: '$_case06/archive_floor_plan.png', pixels: _plan)),
  's2_ep06_e3': DrawnEvidenceArt(season2ArchiveScenes['s2_ep06_m3']!.fitted),
  's2_ep06_e4': const DrawnEvidenceArt(_letterPaper),
};

// ── The story's pictures, mission by mission ────────────────────────────
// Each moment shows what the detective has just reached, never more: Tag D
// once it is found, the archive once the door is found, the seal once the
// envelope is, the drawing's building once the letter is read.
const _rackWhole = StoryPicture(
  file: '$_case06/post_room_hold_rack.png',
  pixels: _rack,
  label: 'A wooden rack of slots in a quiet post room, paper tags hanging from it',
);

const _planWhole = StoryPicture(
  file: '$_case06/archive_floor_plan.png',
  pixels: _plan,
  crop: Rect.fromLTRB(0.18, 0.1, 0.82, 0.97),
  label: 'A plan of the building: stairs, a corridor with a statue, doors on both sides',
);

const _archiveWhole = StoryPicture(
  file: '$_case06/archive_room.png',
  pixels: _wide,
  label: 'A dim archive room: tall cabinets full of small drawers, a lamp on a reading table',
);

final Map<String, StoryScenes> season2Case06StoryScenes = {
  // The post room's rack; after it, Tag D; then the plan on the wall.
  's2_ep06_m1': StoryScenes(
    place: _rackWhole,
    after: StoryPicture(
      file: '$_case06/post_room_hold_rack.png',
      pixels: _rack,
      crop: _rack.rect(250, 640, 640, 960),
      label: 'Tag D, hanging under the bottom row of the rack',
    ),
    next: _planWhole,
  ),
  // The plan; after it, the archive; then its cabinet.
  's2_ep06_m2': const StoryScenes(
    place: _planWhole,
    after: _archiveWhole,
    next: StoryPicture(
      file: '$_case06/archive_cabinet.png',
      pixels: _cabinet,
      label: 'An archive cabinet of four drawers, each with a brass label holder',
    ),
  ),
  // The archive; after it, the seal through a lens; then the reading table.
  's2_ep06_m3': StoryScenes(
    place: _archiveWhole,
    after: const StoryPicture(
      file: '$_case06/opera_seal.png',
      pixels: _seal,
      label: 'A red wax seal with a tiny drawing of a grand building',
      cutOut: true,
    ),
    next: StoryPicture(
      file: '$_case06/archive_room.png',
      pixels: _wide,
      crop: _wide.rect(0, 500, 960, 1024),
      label: 'The reading table in the archive, under its green lamp',
    ),
  ),
  // After the case: the letter's drawing, the building the case goes to.
  's2_ep06_final': const StoryScenes(
    after: StoryPicture(
      file: '$_case06/opera_sketch.png',
      pixels: _sketch,
      label: 'An ink drawing of the Palais Garnier, the opera house',
      cutOut: true,
    ),
  ),
};
