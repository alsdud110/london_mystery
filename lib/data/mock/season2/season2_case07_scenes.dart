import 'dart:ui' show Offset, Rect;

import '../../models/opera_puzzles.dart';
import '../../models/river_puzzles.dart' show DrawnEvidenceArt, RiverEvidenceArt;
import '../../models/scene_exhibit.dart' show EvidenceLink;
import '../../models/scene_explore.dart' show ScenePixels;
import '../../models/story_picture.dart';

/// Season 2, Case 07's missions, keyed by mission id: first as rules, then
/// as they are played on the case's pictures (every place measured on the
/// delivered pictures, in their pixels). The answers, their feedback, the
/// hints, the solves, their Clue and Evidence, XP, coins and the save are
/// the case's own (`episode07_mock.dart`).

/// M1: FILE 3's three times and FILE 4's four parts. The strip starts on
/// the office's own 3:00 and slides from 2:30 to 4:20 (it ends by 6:30, the
/// clock's end), ten minutes at a time.
final season2ShowStrips = <String, ShowStrip>{
  's2_ep07_m1': ShowStrip(
    parts: const [ShowPart('OVERTURE', 10), ShowPart('ACT ONE', 60), ShowPart('INTERVAL', 20), ShowPart('ACT TWO', 40)],
    doorsOpen: pm(3, 30),
    officeStart: pm(3),
    curtainDown: pm(6, 10),
    from: pm(2, 30),
    to: pm(6, 30),
    earliest: pm(2, 30),
    latest: pm(4, 20),
    step: 10,
    initial: pm(3),
  ),
};

/// M2: the old photo shows the ghost light alone.
const season2LightBoards = <String, LightBoard>{
  's2_ep07_m2': LightBoard(photo: {StageLight.ghost}),
};

/// M3: the Painted Street (Case 02: "Above the red door: a small clock.")
/// and the four backdrops, rope 1 first. Each wrong one misses one thing:
/// a lamp above the door, a big clock far off on a tower (nothing above the
/// door), a blue door.
const season2FlyRails = <String, FlyRail>{
  's2_ep07_m3': FlyRail(
    door: DoorColour.red,
    above: AboveDoor.smallClock,
    ropes: [
      Backdrop(id: 'lampRed', door: DoorColour.red, above: AboveDoor.lamp),
      Backdrop(id: 'towerRed', door: DoorColour.red, above: AboveDoor.nothing, tower: true),
      Backdrop(id: 'clockRed', door: DoorColour.red, above: AboveDoor.smallClock),
      Backdrop(id: 'clockBlue', door: DoorColour.blue, above: AboveDoor.smallClock),
    ],
  ),
};

/// The final: FILE 3 was changed (FILE 4 and the stage cue card agree on
/// 4:00); the slip's change, 4:00 to 3:00.
final season2ChangedRecords = <String, ChangedRecord>{
  's2_ep07_final': ChangedRecord(files: const ['file3', 'file4'], changed: 'file3', oldTime: pm(4), newTime: pm(3)),
};

/// Case 07's evidence, one piece to the next: the letter's back named
/// FILE 3–4; the stage's own card against the office's record; the slip
/// behind the backdrop the Painted Street names; the patch the slip asks
/// for.
const season2Case07EvidenceLinks = <String, EvidenceLink>{
  's2_ep07_e1': EvidenceLink(to: 's2_ep06_e4', line: 'The back of the letter: OPERA ARCHIVE · FILE 3–4.'),
  's2_ep07_e2': EvidenceLink(to: 's2_ep07_e1', line: 'The office record says 3:00. The stage cue says 4:00.'),
  's2_ep07_e3': EvidenceLink(to: 's2_ep02_e1', line: 'Behind the backdrop with a small clock above a red door.'),
  's2_ep07_e4': EvidenceLink(to: 's2_ep07_e3', line: 'The same change as on the slip: 4:00 to 3:00.'),
};

// ── The pictures ────────────────────────────────────────────────────────

const _case07 = 'assets/seasons/season_02_paris/cases/case_07';

// ── The papers ──────────────────────────────────────────────────────────
// FILE 3 (1055 × 1491, cut out): its paper (52, 65)–(1016, 1444); the
// heading's band, its oval (492, 170)–(580, 290); the band's last rule at
// y 335; three ruled lines across at y 603, 791 and 979 (x 108–962); two
// pairs of photo corners, (167, 1122)–(899, 1392). Each line's words are
// written just above its rule, words and time kept within x 150–845 (so
// the lines up close are large enough to pin). The patch (1983 × 793, cut
// out: its paper (154, 134)–(1831, 655)) is glued over CURTAIN UP's time,
// from under the first rule to over the second: 3:00 PM written on it on
// the line, beside CURTAIN UP; the old 4:00 PM shows through above it,
// only with the light on. The mount (1536 × 1024, cut out): its window (199, 130)–
// (1337, 687), a wide margin below it.
const _record = ScenePixels(1055, 1491);
const _patch = ScenePixels(1983, 793);
const _mount = ScenePixels(1536, 1024);
const _stage = ScenePixels(1536, 1024);
const _programme = ScenePixels(1024, 1536);
const _card = ScenePixels(1536, 1024);
const _slip = ScenePixels(1536, 1024);
const _sketch = ScenePixels(1536, 1024);

const _photo = PhotoPrint(
  file: '$_case07/photo_frame.png',
  pixels: _mount,
  window: Rect.fromLTRB(199, 130, 1337, 687),
  stage: '$_case07/stage_ghost.png',
  stagePixels: _stage,
  caption: '3:00 PM · CURTAIN UP!',
  captionAt: Rect.fromLTRB(240, 718, 1296, 925),
);

final _file3 = OfficeRecord(
  file: '$_case07/office_record_blank.png',
  pixels: _record,
  fileLabel: 'FILE 3',
  fileAt: const Rect.fromLTRB(494, 176, 578, 286),
  title: const ['THE GOLDEN NIGHTINGALE', 'PERFORMANCE No. 34'],
  titleAt: const Rect.fromLTRB(170, 360, 840, 500),
  rows: [
    RecordRow(id: RecordSpot.doors, label: 'DOORS OPEN ·', time: clockPm(pm(3, 30)), labelAt: const Rect.fromLTRB(150, 520, 540, 598), timeAt: const Rect.fromLTRB(575, 520, 845, 598)),
    RecordRow(id: RecordSpot.patch, label: 'CURTAIN UP ·', time: clockPm(pm(3)), labelAt: const Rect.fromLTRB(150, 708, 540, 786), timeAt: const Rect.fromLTRB(575, 708, 845, 786)),
    RecordRow(id: RecordSpot.down, label: 'CURTAIN DOWN ·', time: clockPm(pm(6, 10)), labelAt: const Rect.fromLTRB(150, 896, 540, 974), timeAt: const Rect.fromLTRB(575, 896, 845, 974)),
  ],
  patch: RecordPatch(
    file: '$_case07/record_patch.png',
    pixels: _patch,
    paper: const Rect.fromLTRB(154, 134, 1831, 655),
    at: const Rect.fromLTRB(560, 610, 860, 800),
    newTime: clockPm(pm(3)),
    newAt: const Rect.fromLTRB(575, 708, 845, 786),
    oldTime: clockPm(pm(4)),
    oldAt: const Rect.fromLTRB(590, 622, 845, 692),
  ),
  photo: _photo,
  photoAt: const Rect.fromLTRB(337, 1125, 735, 1390),
);

// FILE 4 (1024 × 1536, cut out): its card (34, 44)–(989, 1483), a gold
// frame round it (x 78–947, down to y 1435), the nightingale's ornament
// down to y 293. Its words in the frame below it.
const _file4 = ProgrammePage(
  file: '$_case07/programme_page_blank.png',
  pixels: _programme,
  title: ['THE GOLDEN NIGHTINGALE', 'THE PROGRAMME'],
  titleAt: Rect.fromLTRB(150, 345, 875, 515),
  parts: [ShowPart('OVERTURE', 10), ShowPart('ACT ONE', 60), ShowPart('INTERVAL', 20), ShowPart('ACT TWO', 40)],
  partsAt: Rect.fromLTRB(170, 570, 855, 1060),
  whole: 'THE WHOLE SHOW:\n2 HOURS 10 MINUTES',
  // Inside the frame, above its corner flowers (they reach up to y 1300).
  wholeAt: Rect.fromLTRB(215, 1100, 810, 1280),
);

// The cue card (1536 × 1024, cut out): the card (73, 149)–(1466, 873), its
// hole top left, a red rule at y 313 under the heading's space, blue rules
// from y 388 down.
const _cue = CueCard(
  file: '$_case07/cue_card_blank.png',
  pixels: _card,
  heading: 'SHOW No. 34',
  headingAt: Rect.fromLTRB(200, 168, 1430, 300),
  lines: ['CUE 1 · CURTAIN UP', '4:00'],
  linesAt: Rect.fromLTRB(180, 384, 1420, 756),
);

// The Amendment Slip (1536 × 1024, cut out): its paper (160, 159)–(1375,
// 853); a double border (x 196–1340, y 200–814), its header band down to
// the rule at y 318–329. The stamp (1254 × 1254, cut out) in the lower
// right. Its back is the same paper turned over: the sketch of Abbesses
// (1536 × 1024, cut out: its metro sign's empty panel (1130, 352)–(1305,
// 415)) laid in the border, the line under it.
const _amendment = AmendmentSlip(
  file: '$_case07/amendment_slip_blank.png',
  pixels: _slip,
  paper: Rect.fromLTRB(160, 159, 1375, 853),
  header: 'FILE 3',
  headerAt: Rect.fromLTRB(240, 222, 1300, 314),
  lines: ['PERFORMANCE No. 34'],
  linesAt: Rect.fromLTRB(250, 345, 1300, 440),
  changeLabel: 'CURTAIN UP:',
  changeAt: Rect.fromLTRB(250, 455, 1060, 545),
  oldTime: '4:00',
  oldAt: Rect.fromLTRB(290, 575, 560, 715),
  newTime: '3:00',
  newAt: Rect.fromLTRB(720, 575, 990, 715),
  stamp: '$_case07/office_stamp.png',
  stampAt: Rect.fromLTRB(1090, 585, 1300, 795),
  back: SlipBack(
    sketch: '$_case07/abbesses_sketch.png',
    sketchPixels: _sketch,
    sketchAt: Rect.fromLTRB(395, 232, 1140, 729),
    sign: 'ABBESSES',
    signAt: Rect.fromLTRB(1130, 352, 1305, 415),
    note: 'P. KNEW THE BAG.',
    noteAt: Rect.fromLTRB(240, 733, 1296, 800),
  ),
);

// ── M1 — the archive table ──────────────────────────────────────────────
// The strip (2172 × 724, cut out): its paper (37, 275)–(2137, 448), an
// ornamental line along its top and bottom and a flourish at each end; the
// middle stretches.
final Map<String, ShowStripScene> season2ShowStripScenes = {
  's2_ep07_m1': ShowStripScene(
    strip: season2ShowStrips['s2_ep07_m1']!,
    record: _file3,
    programme: _file4,
    stripFile: '$_case07/show_strip_blank.png',
    stripPixels: const ScenePixels(2172, 724),
    stripPaper: const Rect.fromLTRB(37, 275, 2137, 448),
    stripSlice: const Rect.fromLTRB(150, 300, 2024, 423),
    task: 'Slide the show. The audience must be in first. The show must end at CURTAIN DOWN.',
    checkLabel: 'CHECK',
  ),
};

// ── M2 — the lighting desk ──────────────────────────────────────────────
// The stage (1536 × 1024, seen from the back of the stalls): the ghost
// light's stand at the middle (x 768; its bulb at y 470, its foot at
// y 670), brass footlights along the stage's edge (y 700–740), the boxes'
// sconces at both sides, seats below. Each lit picture is the same stage
// with one light on (checked: none is moved). The desk (1536 × 1024, cut
// out): its panel (34, 175)–(1501, 829); four lever slots (inner (342,
// 332)–(378, 564), (613, …)–(649), (886)–(922), (1158)–(1195)) above four
// enamel plates (y 621–670). The lever (1024 × 1536, cut out): (308, 70)–
// (710, 1455), its knob on top. The book (1536 × 1024, cut out): its pages
// (152, 100)–(688, 818) and (816, 102)–(1388, 814). The scrap (1254 ×
// 1254, cut out): (161, 182)–(1076, 1073).
const _desk = ScenePixels(1536, 1024);
const _book = ScenePixels(1536, 1024);

const _lightingBook = LightingBook(
  file: '$_case07/lighting_book_open.png',
  pixels: _book,
  left: Rect.fromLTRB(185, 125, 665, 800),
  right: Rect.fromLTRB(845, 125, 1365, 800),
  title: 'THE LIGHTING BOOK',
  entries: [
    ('GHOST LIGHT', ['One lamp on an empty stage.', 'We use it before the doors open, and at night.']),
    ('HOUSE LIGHTS', ['For the audience.']),
    ('FOOTLIGHTS and BIG SPOT', ['For the show.']),
  ],
);

final Map<String, LightBoardScene> season2LightBoardScenes = {
  's2_ep07_m2': LightBoardScene(
    board: season2LightBoards['s2_ep07_m2']!,
    stage: '$_case07/stage_base.png',
    stagePixels: _stage,
    lit: const {
      StageLight.ghost: '$_case07/stage_ghost.png',
      StageLight.house: '$_case07/stage_house.png',
      StageLight.foot: '$_case07/stage_foot.png',
      StageLight.spot: '$_case07/stage_spot.png',
    },
    desk: '$_case07/lighting_desk.png',
    deskPixels: _desk,
    deskPaper: const Rect.fromLTRB(34, 175, 1501, 829),
    slots: const [
      DeskSlot(light: StageLight.ghost, slot: Rect.fromLTRB(342, 332, 378, 564), plate: Rect.fromLTRB(288, 621, 430, 670)),
      DeskSlot(light: StageLight.house, slot: Rect.fromLTRB(613, 332, 649, 564), plate: Rect.fromLTRB(559, 621, 702, 670)),
      DeskSlot(light: StageLight.foot, slot: Rect.fromLTRB(886, 332, 922, 564), plate: Rect.fromLTRB(832, 621, 976, 670)),
      DeskSlot(light: StageLight.spot, slot: Rect.fromLTRB(1158, 332, 1195, 564), plate: Rect.fromLTRB(1104, 621, 1248, 670)),
    ],
    lever: '$_case07/lighting_lever.png',
    leverPixels: const ScenePixels(1024, 1536),
    leverPaper: const Rect.fromLTRB(308, 70, 710, 1455),
    book: _lightingBook,
    photo: _photo,
    cue: _cue,
    cueOnPage: const Rect.fromLTRB(826, 160, 1378, 528),
    scrap: '$_case07/scrap_clock_door.png',
    scrapPixels: const ScenePixels(1254, 1254),
    scrapAt: const Rect.fromLTRB(1080, 500, 1420, 840),
    pageTitle: const ['SHOW No. 34', 'THE GOLDEN NIGHTINGALE'],
    task: 'Tap a lever, or slide it up or down.',
    checkLabel: 'IT MATCHES THE PHOTO',
    emptyLine: 'Only the ghost light: an empty stage, not a show.',
    scrapLine: 'A tiny drawing: a small clock above a red door.',
  ),
};

// ── M3 — the rope rail ──────────────────────────────────────────────────
// The stage again, all lights off: its opening between the curtains,
// (340, 112)–(1210, 700), where a backdrop comes down. The rail (1536 ×
// 1024): four brass locks in a row (centres x 337, 637, 943, 1250; from
// y 396) under four card plates (y 323–382). A rope (1024 × 1536, cut out:
// the rope x 460–568, top to bottom) hangs through each lock. The
// backdrops (1536 × 1024, cut out: canvas, batten and pole (4, 0)–(1529,
// 985)) are one painting: the red door (565, 500)–(670, 770), above it the
// small clock (580, 395)–(655, 470), the lamp in its place on rope 1's,
// nothing there on rope 2's (a clock tower far right, its face (955, 222)–
// (1020, 292)), the door blue on rope 4's. The back of the right one (1536
// × 1024): a canvas pocket (598, 700)–(828, 872), a paper in it.
const _rail = ScenePixels(1536, 1024);
const _backdrop = ScenePixels(1536, 1024);

final Map<String, FlyRailScene> season2FlyRailScenes = {
  's2_ep07_m3': FlyRailScene(
    rail: season2FlyRails['s2_ep07_m3']!,
    stage: '$_case07/stage_base.png',
    stagePixels: _stage,
    stageView: const Rect.fromLTRB(250, 40, 1290, 760),
    opening: const Rect.fromLTRB(340, 112, 1210, 700),
    railFile: '$_case07/fly_rail.png',
    railPixels: _rail,
    railView: const Rect.fromLTRB(170, 250, 1420, 750),
    ropeX: const [337, 637, 943, 1250],
    plates: const [
      Rect.fromLTRB(262, 323, 412, 382),
      Rect.fromLTRB(562, 323, 713, 382),
      Rect.fromLTRB(870, 323, 1016, 382),
      Rect.fromLTRB(1177, 323, 1323, 382),
    ],
    lockTop: 396,
    rope: '$_case07/rope_line.png',
    ropePixels: const ScenePixels(1024, 1536),
    ropeStrand: (460, 568),
    backdrops: const [
      BackdropArt(id: 'lampRed', file: '$_case07/backdrop_lamp_red.png', label: 'A painted street at night: a red door, a small wall lamp above it'),
      BackdropArt(id: 'towerRed', file: '$_case07/backdrop_tower_red.png', label: 'A painted street at night: a red door, plain wall above it, a clock tower far off on the right'),
      BackdropArt(id: 'clockRed', file: '$_case07/backdrop_clock_red.png', label: 'A painted street at night: a red door, a small round clock right above it'),
      BackdropArt(id: 'clockBlue', file: '$_case07/backdrop_clock_blue.png', label: 'A painted street at night: a blue door, a small round clock right above it'),
    ],
    backdropPixels: _backdrop,
    canvas: const Rect.fromLTRB(4, 0, 1529, 985),
    closer: const Rect.fromLTRB(450, 330, 790, 800),
    clueFile: 'assets/seasons/season_02_paris/cases/case_02/montmartre_street_painted.png',
    cluePixels: const ScenePixels(1536, 1024),
    clueCrop: const Rect.fromLTRB(565, 290, 830, 620),
    clueLine: 'Above the red door: a small clock.',
    back: '$_case07/backdrop_back_pocket.png',
    backPixels: _backdrop,
    pocket: const Rect.fromLTRB(598, 700, 828, 872),
    slip: _amendment,
    task: 'Pull a rope to lower its backdrop.',
    chooseLabel: 'THIS ONE!',
    pocketTask: 'Something is in the pocket. Tap it.',
  ),
};

// ── Final — the light table ─────────────────────────────────────────────
// The archive (1536 × 1024): on the long table, a dark green box with a
// blank label card (755, 626)–(891, 690). The light table (1536 × 1024,
// off; on: the same table, lit): its frosted glass (213, 165)–(1315, 699),
// a brass switch on the right edge (1375, 525)–(1465, 655), down when off,
// up when on. FILE 3 up close on the glass: its title and three lines,
// (150, 340)–(860, 1010) of the record. A pin can go into each line; on
// CURTAIN UP's, the patch's 3:00 PM or, the light on, the 4:00 PM under it
// (each place at least 44 points tall on a 360-wide phone). A red thread
// comes to a pin from the record's left edge through blank paper: to the
// old time along the gap between DOORS OPEN and CURTAIN UP (y 657); to the
// new one under CURTAIN UP's rule (y 840), then up the blank strip between
// the words and the times (x 556) to the pin.
const _archive = ScenePixels(1536, 1024);
const _table = ScenePixels(1536, 1024);

final Map<String, LightTableScene> season2LightTableScenes = {
  's2_ep07_final': LightTableScene(
    record: season2ChangedRecords['s2_ep07_final']!,
    archive: '$_case07/opera_archive_room.png',
    archivePixels: _archive,
    archiveView: const Rect.fromLTRB(300, 230, 1260, 870),
    label: 'FILE 3–4',
    labelAt: const Rect.fromLTRB(762, 632, 884, 684),
    file3: _file3,
    programme: _file4,
    cue: _cue,
    table: '$_case07/light_table_off.png',
    tableOn: '$_case07/light_table_on.png',
    tablePixels: _table,
    glass: const Rect.fromLTRB(213, 165, 1315, 699),
    switchAt: const Rect.fromLTRB(1355, 500, 1490, 680),
    closeUp: const Rect.fromLTRB(150, 340, 860, 1010),
    pins: const [
      PinSpot(spot: RecordSpot.doors, area: Rect.fromLTRB(150, 440, 860, 576), at: Offset(578, 559)),
      PinSpot(spot: RecordSpot.under, area: Rect.fromLTRB(540, 576, 860, 699), at: Offset(590, 657)),
      PinSpot(spot: RecordSpot.patch, area: Rect.fromLTRB(540, 699, 860, 850), at: Offset(578, 747), via: [Offset(556, 840), Offset(556, 747)]),
      PinSpot(spot: RecordSpot.down, area: Rect.fromLTRB(150, 850, 860, 1006), at: Offset(578, 935)),
    ],
    slip: _amendment,
    chooseTask: 'Tap the record that was changed.',
    placeTask: 'Drag FILE 3 onto the glass, or tap PUT IT ON THE TABLE.',
    lightTask: 'Turn on the light. Look at each line.',
    pinTask: 'Pin the slip to the change.',
  ),
};

/// Case 07's evidence, drawn with its words: FILE 3 (and its photo), the
/// stage cue card, the Amendment Slip, and FILE 3 on the lit light table.
final Map<String, RiverEvidenceArt> season2Case07EvidenceArt = {
  's2_ep07_e1': DrawnEvidenceArt(_file3, whole: true),
  's2_ep07_e2': const DrawnEvidenceArt(_cue, whole: true),
  's2_ep07_e3': const DrawnEvidenceArt(_amendment, whole: true),
  's2_ep07_e4': DrawnEvidenceArt(_file3.seen(RecordLight.lit), whole: true),
};

// ── The story's pictures, mission by mission ────────────────────────────
// Each moment shows what the detective has just reached, never more: the
// box on the archive table, the dark stage, the ghost light alone, the
// rope rail, the backdrop's back, the light table, and after the case the
// sketch on the slip's back.
const _archiveWhole = StoryPicture(
  file: '$_case07/opera_archive_room.png',
  pixels: _archive,
  label: 'An archive under the roof of the opera house: shelves of boxes, a long table, one green box on it',
);

const _stageDark = StoryPicture(
  file: '$_case07/stage_base.png',
  pixels: _stage,
  label: 'A dark opera stage seen from the back of the hall, its curtain open',
);

const _railWhole = StoryPicture(
  file: '$_case07/fly_rail.png',
  pixels: _rail,
  label: 'Backstage: a wooden rail on a brick wall, four brass rope locks',
);

const _tableWhole = StoryPicture(
  file: '$_case07/light_table_off.png',
  pixels: _table,
  label: 'A wooden light table with a frosted glass top, its light off',
);

final Map<String, StoryScenes> season2Case07StoryScenes = {
  // The archive; after it, the box on the table; then the dark stage.
  's2_ep07_m1': StoryScenes(
    place: _archiveWhole,
    after: StoryPicture(
      file: '$_case07/opera_archive_room.png',
      pixels: _archive,
      crop: _archive.rect(420, 380, 1180, 880),
      label: 'The green archive box on the long table, under a brass lamp',
    ),
    next: _stageDark,
  ),
  // The dark stage; after it, the ghost light alone; then the rope rail.
  's2_ep07_m2': const StoryScenes(
    place: _stageDark,
    after: StoryPicture(
      file: '$_case07/stage_ghost.png',
      pixels: _stage,
      label: 'The empty stage, lit only by one bare bulb on a stand',
    ),
    next: _railWhole,
  ),
  // The rail; after it, the back of the backdrop; then the light table.
  's2_ep07_m3': const StoryScenes(
    place: _railWhole,
    after: StoryPicture(
      file: '$_case07/backdrop_back_pocket.png',
      pixels: _backdrop,
      label: 'The back of a painted backdrop, a canvas pocket sewn at its foot',
    ),
    next: _tableWhole,
  ),
  // After the case: the sketch on the back of the slip.
  's2_ep07_final': const StoryScenes(
    after: StoryPicture(
      file: '$_case07/abbesses_sketch.png',
      pixels: _sketch,
      label: 'A pencil sketch of Montmartre: stone steps, a street lamp, a metro entrance',
      cutOut: true,
    ),
  ),
};
