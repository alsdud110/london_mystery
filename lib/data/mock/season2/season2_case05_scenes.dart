import 'dart:ui' show Offset, Rect;

import '../../models/easy_steps.dart';
import '../../models/river_puzzles.dart' show DrawnEvidenceArt, RiverEvidenceArt;
import '../../models/scene_exhibit.dart' show EvidenceLink;
import '../../models/scene_explore.dart' show ScenePixels;
import '../../models/story_picture.dart';
import '../../models/workshop_puzzles.dart';

/// Season 2, Case 05's missions played in their scenes (presentation only:
/// the case data is left as it is). Each table is keyed by mission id; the
/// answer, its feedback, the hints, the solve, its Clue and Evidence, XP,
/// coins and the save are the puzzle's own. Every place is measured on the
/// delivered picture (pixels, then fractions).

const _case04 = 'assets/seasons/season_02_paris/cases/case_04';
const _case05 = 'assets/seasons/season_02_paris/cases/case_05';

// ── The maker's mark (M1, M3) ───────────────────────────────────────────
// Case 04's two clock hands (1254 × 1254, cut out): two hands apart, the
// long one above, from (41, 57) to (1217, 834), the short one below, from
// (294, 495) to (1222, 1191); [split] runs between them. The copy with
// another tip (1254 × 1254, cut out) is drawn a little apart: laid 16
// across and 38 up, its hands sit on the maker's.
const _hands = ScenePixels(1254, 1254);

const makerMark = MakerMark(
  file: '$_case04/hands_sign.png',
  pixels: _hands,
  split: [
    Offset(0, 880),
    Offset(240, 880),
    Offset(300, 930),
    Offset(360, 890),
    Offset(424, 870),
    Offset(488, 800),
    Offset(552, 740),
    Offset(616, 700),
    Offset(680, 610),
    Offset(744, 560),
    Offset(808, 540),
    Offset(872, 520),
    Offset(936, 520),
    Offset(1000, 470),
    Offset(1064, 420),
    Offset(1128, 380),
    Offset(1192, 300),
    Offset(1254, 280),
  ],
  // Towards the long hand, across the two (they run up to the right).
  shift: Offset(-52, -76),
  tipFile: '$_case05/maker_mark_a.png',
  tipShift: Offset(16, -38),
);

// ── M1 — the workbench ──────────────────────────────────────────────────
// The bench (1536 × 1024): the toolbox, the tin of parts, the clock case and
// the small drawer in a row, each with a blank round stamp, measured on its
// rim (centre, radius): (295, 524) 82, (692, 553) 68, (975, 522) 82,
// (1311, 503) 56. An empty crate behind them, its paper out (Box 23's,
// never said). The tracing sheet (1254 × 1254, cut out): crumpled paper,
// from (26, 48) to (1236, 1218), nearly opaque (shown see-through).
const _bench = ScenePixels(1536, 1024);
const _sheet = ScenePixels(1254, 1254);

// The repair card (1480 × 1062, cut out): a tag, its string at the left,
// its card from (148, 195) to (1450, 872), the eyelet at (248, 530).
const _card = ScenePixels(1480, 1062);

const repairCard = WrittenPaper(
  file: '$_case05/repair_card_blank.png',
  pixels: _card,
  writeOn: Rect.fromLTRB(360, 250, 1390, 660),
  lines: ['I changed one clock.', 'I added one small wheel.', 'Now its hands turn', 'the wrong way.'],
  label: 'A repair card on a string, signed with two clock hands',
  markAt: Rect.fromLTRB(1120, 640, 1360, 860),
  signedWith: makerMark,
  size: 64,
);

final Map<String, MarkCompareScene> season2MarkCompares = {
  's2_ep05_m1': MarkCompareScene(
    bench: '$_case05/workbench_marks.png',
    pixels: _bench,
    place: 'A long workbench in a dim workshop: a toolbox, a tin, a clock case and a small drawer, each with a round stamp',
    seals: [
      BenchSeal(
        id: 'a',
        name: 'A · THE TOOLBOX',
        thing: 'the toolbox',
        area: _bench.rect(52, 335, 548, 625),
        seal: _bench.rect(213, 442, 377, 606),
        copy: MarkCopy.tip,
      ),
      BenchSeal(
        id: 'b',
        name: 'B · THE TIN OF PARTS',
        thing: 'the tin of parts',
        area: _bench.rect(577, 388, 810, 652),
        seal: _bench.rect(624, 485, 760, 621),
        copy: MarkCopy.shifted,
      ),
      BenchSeal(
        id: 'c',
        name: 'C · THE CLOCK CASE',
        thing: 'the clock case',
        area: _bench.rect(848, 330, 1095, 645),
        seal: _bench.rect(893, 440, 1057, 604),
        copy: MarkCopy.oneHand,
      ),
      BenchSeal(
        id: 'd',
        name: 'D · THE SMALL DRAWER',
        thing: 'the small drawer',
        area: _bench.rect(1128, 368, 1465, 658),
        seal: _bench.rect(1255, 447, 1367, 559),
        copy: MarkCopy.exact,
      ),
    ],
    mark: makerMark,
    sheet: '$_case05/tracing_sheet.png',
    sheetPixels: _sheet,
    sheetMarkAt: const Rect.fromLTRB(200, 210, 1060, 1070),
    note: 'My mark is on everything I make.\nA copy is never the same.',
    card: repairCard,
    readTask: 'Tap a stamp. Lay the tracing sheet over it.',
    chooseTask: "Which one has the maker's own mark? Choose it.",
    chooseLabel: 'THIS IS THE MARK',
    sheetLabel: 'LAY THE SHEET ON IT',
  ),
};

// ── M2 — the wall of clocks ─────────────────────────────────────────────
// The wall (1536 × 1024): four clocks in a row, their dials blank with no
// hands, measured on their centre pins and the paper's edge: I (332, 342)
// 82, II (641, 341) 90, III (949, 343) 82, IV (1252, 343) 86. Their blank
// brass plates under them, from y 673 to 728. The part shown, the four
// clocks and their plates, (180, 80)–(1400, 740).
// The backs (1024 × 1024; Clock I's 1254 × 1254, the same picture larger):
// the same open case and gears; II's new spring in the middle, III's small
// wheel at the right, IV's pendulum hook broken at the bottom.
const _wall = ScenePixels(1536, 1024);
const _back = ScenePixels(1024, 1024);

final Map<String, ClockWallScene> season2ClockWalls = {
  's2_ep05_m2': ClockWallScene(
    wall: '$_case05/wall_of_clocks.png',
    pixels: _wall,
    place: 'Four old clocks in a row on a workshop wall, their dials pale, a brass plate under each',
    view: _wall.rect(180, 80, 1400, 740),
    clocks: [
      WallClock(
        id: 'i',
        numeral: 'I',
        centre: const Offset(332, 342),
        radius: 82,
        area: _wall.rect(195, 95, 478, 660),
        plateAt: _wall.rect(258, 673, 420, 728),
        shows: 3 * 60 + 10,
        change: 1,
        back: '$_case05/clock_back_normal.png',
        backLabel: 'The back of Clock I: brass gears and two weights',
        backNote: 'Brass gears and two weights.',
      ),
      WallClock(
        id: 'ii',
        numeral: 'II',
        centre: const Offset(641, 341),
        radius: 90,
        area: _wall.rect(510, 95, 772, 662),
        plateAt: _wall.rect(561, 673, 720, 728),
        shows: 7 * 60 + 25,
        change: 5,
        back: '$_case05/clock_back_spring.png',
        backLabel: 'The back of Clock II: a big, shiny spring in the middle of the gears',
        backNote: 'A big, shiny spring.',
      ),
      WallClock(
        id: 'iii',
        numeral: 'III',
        centre: const Offset(949, 343),
        radius: 82,
        area: _wall.rect(815, 110, 1082, 672),
        plateAt: _wall.rect(866, 673, 1023, 728),
        shows: 10 * 60 + 40,
        change: -1,
        back: '$_case05/clock_back_extra_wheel.png',
        backLabel: 'The back of Clock III: one small brass wheel at the side of the gears',
        backNote: 'A small brass wheel at the side of the gears.',
      ),
      WallClock(
        id: 'iv',
        numeral: 'IV',
        centre: const Offset(1252, 343),
        radius: 86,
        area: _wall.rect(1115, 95, 1378, 662),
        plateAt: _wall.rect(1169, 673, 1323, 728),
        shows: 1 * 60 + 55,
        change: 0,
        back: '$_case05/clock_back_broken.png',
        backLabel: 'The back of Clock IV: its pendulum hook broken and hanging loose',
        backNote: 'The pendulum hook is broken.',
      ),
    ],
    backPixels: _back,
    watch: const Duration(seconds: 6),
    watchLabel: 'WATCH THE CLOCKS',
    againLabel: 'WATCH AGAIN',
    later: 'ONE MINUTE LATER…',
    watchTask: 'Watch the four clocks for one minute.',
    backTask: 'Tap a clock to look at its back.',
    chooseTask: 'Which clock did the maker change? Choose it.',
    chooseLabel: 'THIS IS THE CLOCK',
  ),
};

// ── M3 — the writing desk ───────────────────────────────────────────────
// The desk (1264 × 848, seen from above): the blotting paper in its green
// felt, from (228, 170) to (1036, 762); ink bottles round it (blue at the
// top left, brown at the right). The three notes are blotted inside it. The
// hand mirror (896 × 1200, cut out): its glass clear (transparent), its
// centre (448, 382), radius 208.
// Clock III's back once opened, and in it the torn envelope corner (1216 ×
// 880, cut out): its blank sticker (172, 157)–(550, 372), the receipt
// clipped to it, (548, 392)–(1133, 797).
const _desk = ScenePixels(1264, 848);
const _mirror = ScenePixels(896, 1200);
const _envelope = ScenePixels(1216, 880);

const hideaway = WrittenPaper(
  file: '$_case05/envelope_corner.png',
  pixels: _envelope,
  writeOn: Rect.fromLTRB(600, 440, 1090, 770),
  lines: ['16 MAY', 'ONE LETTER COLLECTED', 'FROM No. 7', 'LETTER No. 4417'],
  label: 'A torn envelope corner with a small receipt clipped to it',
  size: 44,
  tag: 'No. 4417',
  tagAt: Rect.fromLTRB(200, 190, 525, 340),
);

final Map<String, BlotterScene> season2Blotters = {
  's2_ep05_m3': BlotterScene(
    desk: '$_case05/writing_desk_blotter.png',
    pixels: _desk,
    place: 'A writing desk seen from above: a big sheet of blotting paper, ink bottles and pens round it',
    blotter: const Rect.fromLTRB(228, 170, 1036, 762),
    notes: const [
      BlotNote(
        id: 'blue',
        ink: NoteInk.blue,
        lines: ['Please put my letter', 'in the post box at the corner.'],
        at: Rect.fromLTRB(280, 205, 990, 365),
        mark: null,
      ),
      BlotNote(
        id: 'black',
        ink: NoteInk.black,
        lines: ['The letter is in', 'the tin of springs.'],
        at: Rect.fromLTRB(280, 390, 990, 550),
        mark: MarkCopy.oneHand,
      ),
      BlotNote(
        id: 'brown',
        ink: NoteInk.brown,
        lines: ['The letter is ready.', 'I hid it in the clock that turns back.', 'On 16 May, it goes to the post.'],
        at: Rect.fromLTRB(280, 572, 990, 752),
        mark: MarkCopy.exact,
      ),
    ],
    mirror: '$_case05/hand_mirror.png',
    mirrorPixels: _mirror,
    glassCentre: const Offset(448, 382),
    glassRadius: 208,
    glassOnDesk: 150,
    mark: makerMark,
    readTask: 'Drag the mirror over each note. You can tap a note too.',
    chooseTask: "Which note has the maker's own mark? Choose the place it names.",
    chooseLabel: 'THIS IS WHERE',
    hideaway: hideaway,
    receipt: const ['16 MAY — ONE LETTER COLLECTED FROM No. 7.', 'LETTER No. 4417'],
    hideawayBack: '$_case05/clock_back_extra_wheel.png',
    hideawayLines: const ['Inside Clock III, there is no letter.', 'Only a torn envelope corner and a small receipt.'],
  ),
};

// ── Final — the post's slips ────────────────────────────────────────────
// A post slip (1376 × 768, cut out): a blank card from (172, 75) to (1216,
// 694). The stage: the workshop's door, the light under it, (1000, 100)–
// (1536, 820) of the workshop (1536 × 1024).
const _slip = ScenePixels(1376, 768);
const _workshop = ScenePixels(1536, 1024);

final Map<String, PostTrailScene> season2PostTrails = {
  's2_ep05_final': PostTrailScene(
    slip: '$_case05/post_slip_blank.png',
    slipPixels: _slip,
    slipWriteOn: const Rect.fromLTRB(250, 125, 1140, 650),
    // In the order they lie under the door (not the trail's).
    slips: const [
      PostSlip(id: 's3', letter: '4417', date: '16 MAY', time: '4:00 PM', record: 'HELD', where: 'LOUVRE POST ROOM'),
      PostSlip(id: 's5', letter: '4471', date: '16 MAY', time: null, record: 'COLLECTED', where: 'CORNER BOX'),
      PostSlip(id: 's1', letter: '4417', date: '16 MAY', time: '9:00 AM', record: 'COLLECTED', where: 'PASSAGE BOX'),
      PostSlip(id: 's4', letter: '2903', date: '3 MAY', time: null, record: 'DELIVERED', where: 'RUE DU BAC'),
      PostSlip(id: 's2', letter: '4417', date: '16 MAY', time: '11:00 AM', record: 'SORTED', where: 'CENTRAL OFFICE'),
    ],
    slots: const ['first', 'second', 'third'],
    slotLabels: const ['1st', '2nd', '3rd'],
    receipt: hideaway,
    stage: '$_case05/workshop_interior.png',
    stagePixels: _workshop,
    stageView: _workshop.rect(1000, 100, 1536, 820),
    stageLabel: 'The workshop door, a line of light under it',
    pickTask: 'Tap a slip, then tap its place on the trail.',
    placeTask: 'Now tap its place above: 1st, 2nd or 3rd.',
    submitLabel: 'FOLLOW THE LETTER',
  ),
};

// ── M3 and the final, very easy (the user's rules of 2026-10-27) ─────────
// M3: one note, blotted backwards on the blotter; a tap on the hand mirror
// reads it (the words in its glass); then which clock: Clock II and Clock
// III as they hang on the wall (M2's, each with what M2 found), the
// mirror's words over them. Clock III opened: the envelope corner and its receipt,
// LETTER No. 4417. The final: which slip is letter 4417's (4471's beside
// it), then its trail written out, to the Louvre post room. The mirror's
// glass, (240, 174)–(656, 590) of its picture, holds the words.
const _deskPicture = EasyPicture(
  file: '$_case05/writing_desk_blotter.png',
  pixels: _desk,
  crop: Rect.fromLTRB(228, 170, 1036, 762),
  label: 'A big sheet of blotting paper; one note is blotted on it, backwards',
);

const _mirrorPicture = EasyPicture(
  file: '$_case05/hand_mirror.png',
  pixels: _mirror,
  label: 'A small hand mirror with a brass frame',
);

const _blotted = PicturePanel(
  id: 'blotter',
  picture: _deskPicture,
  writing: [
    EasyWriting('THE CLOCK', at: Rect.fromLTRB(300, 340, 964, 440), size: 88, mirrored: true),
    EasyWriting('THAT TURNS BACK.', at: Rect.fromLTRB(300, 480, 964, 580), size: 88, mirrored: true),
  ],
);

/// A clock of the wall (M2's picture), its numeral on its plate.
PicturePanel _wallClock(String id) {
  final c = season2ClockWalls['s2_ep05_m2']!.clocks.firstWhere((c) => c.id == id);
  return PicturePanel(
    id: 'clock-$id',
    picture: EasyPicture(
      file: '$_case05/wall_of_clocks.png',
      pixels: _wall,
      crop: Rect.fromLTRB(c.centre.dx - 150, 90, c.centre.dx + 150, 742),
      label: 'Clock ${c.numeral} on the workshop wall',
    ),
    writing: [
      EasyWriting(
        c.numeral,
        at: Rect.fromLTRB(c.plateAt.left * _wall.width + 20, c.plateAt.top * _wall.height + 8, c.plateAt.right * _wall.width - 20, c.plateAt.bottom * _wall.height - 8),
        size: 40,
        ink: EasyInk.typed,
      ),
    ],
  );
}

const _mirrorRead = PicturePanel(
  id: 'mirror',
  picture: _mirrorPicture,
  writing: [
    EasyWriting('THE CLOCK', at: Rect.fromLTRB(290, 262, 606, 352), size: 80, strong: true),
    EasyWriting('THAT TURNS', at: Rect.fromLTRB(262, 356, 634, 436), size: 70, strong: true),
    EasyWriting('BACK.', at: Rect.fromLTRB(304, 440, 592, 520), size: 80, strong: true),
  ],
);

final _trail = season2PostTrails['s2_ep05_final']!;

/// Case 05's M3 and final played one small step at a time. Their answers
/// are the missions' own (the place the maker's note names; letter 4417's
/// three slips in order), so the saves and the Case Archive are as before.
final Map<String, EasyStepsScene> season2Case05Steps = {
  's2_ep05_m3': EasyStepsScene(
    title: 'THE BLOTTED PAGE',
    answer: 'clock3',
    steps: [
      const EasyStep(
        id: 'mirror',
        say: 'Tap the mirror.',
        panels: [
          _blotted,
          PicturePanel(id: 'mirror', picture: _mirrorPicture),
        ],
        does: EasyDo.tap,
        target: EasyMark('mirror'),
        hints: ['The note is backwards. A mirror turns it round.', 'Tap the hand mirror.'],
        done: 'THE CLOCK THAT TURNS BACK.',
        after: [_blotted, _mirrorRead],
      ),
      EasyStep(
        id: 'clock',
        say: 'Which clock?',
        panels: const [
          PaperPanel(
            id: 'mirror-words',
            title: 'THE MIRROR SAYS',
            lines: [EasyLine('THE CLOCK THAT TURNS BACK.', strong: true)],
            old: false,
            aspect: 2.4,
          ),
        ],
        does: EasyDo.choose,
        options: [
          EasyOption(id: 'ii', label: 'CLOCK II\nruns fast', panel: _wallClock('ii'), feedback: 'Clock II runs fast. Which clock turns back?'),
          EasyOption(id: 'iii', label: 'CLOCK III\nturns back', panel: _wallClock('iii')),
        ],
        answer: 'iii',
        hints: const ['The mirror says: the clock that turns back.', 'Find "turns back" under the clocks.'],
        lookHere: const [EasyMark('mirror-words')],
        tell: 'Clock III turns back.',
        done: 'Clock III! No letter inside. Only a receipt.',
        after: const [
          PicturePanel(
            id: 'clock',
            picture: EasyPicture(file: '$_case05/clock_back_extra_wheel.png', pixels: _back, label: 'The back of Clock III, opened'),
            caption: 'Clock III, opened',
          ),
          DrawnPanel(id: 'receipt', drawn: hideaway, caption: 'LETTER No. 4417'),
        ],
      ),
    ],
  ),
  's2_ep05_final': EasyStepsScene(
    title: "THE LETTER'S TRAIL",
    answer: 'first:s1,second:s2,third:s3',
    finishLabel: 'FOLLOW THE LETTER',
    steps: [
      EasyStep(
        id: 'letter',
        say: 'Find letter 4417.',
        does: EasyDo.choose,
        options: [
          EasyOption(
            id: '4471',
            label: 'LETTER 4471',
            panel: DrawnPanel(id: 'slip4471', drawn: _trail.paperOf(_trail.slipOf('s5'))),
            feedback: 'This is 4471. Read the numbers again: 4417.',
          ),
          EasyOption(id: '4417', label: 'LETTER 4417', panel: DrawnPanel(id: 'slip4417', drawn: _trail.paperOf(_trail.slipOf('s1')))),
        ],
        answer: '4417',
        hints: ['Read each number: 4, 4, 1, 7.', 'Find 4417, not 4471.'],
        tell: 'Look: this slip says 4417.',
        done: 'Letter 4417! Here is where it went.',
        after: [
          PaperPanel(
            id: 'trail',
            title: 'LETTER No. 4417 · 16 MAY',
            lines: [
              EasyLine('9:00 AM — COLLECTED'),
              EasyLine('11:00 AM — SORTED'),
              EasyLine('4:00 PM — HELD', strong: true),
              EasyLine('LOUVRE POST ROOM', strong: true),
            ],
            old: false,
            aspect: 1.1,
          ),
        ],
      ),
    ],
  ),
};

/// What Case 05's evidence shows, drawn with its words (the papers are
/// blank): the repair card, Clock III's back, the receipt in its envelope
/// corner, and the slip that says where the letter stopped.
final Map<String, RiverEvidenceArt> season2Case05EvidenceArt = {
  's2_ep05_e1': const DrawnEvidenceArt(repairCard),
  's2_ep05_e2': const DrawnEvidenceArt(PictureEvidence(file: '$_case05/clock_back_extra_wheel.png', pixels: _back)),
  's2_ep05_e3': const DrawnEvidenceArt(hideaway),
  's2_ep05_e4': DrawnEvidenceArt(season2PostTrails['s2_ep05_final']!.paperOf(season2PostTrails['s2_ep05_final']!.slipOf('s3'))),
};

/// Case 05's evidence matched with what came before: the card's mark is the
/// ledger's; the clock is the card's; the note names the clock; the trail
/// starts at the receipt, from the address of the label.
const Map<String, EvidenceLink> season2Case05EvidenceLinks = {
  's2_ep05_e1': EvidenceLink(to: 's2_ep04_e2', line: "The same two clock hands as in the keeper's ledger."),
  's2_ep05_e2': EvidenceLink(to: 's2_ep05_e1', line: 'One small wheel added: the clock the repair card is about.'),
  's2_ep05_e3': EvidenceLink(to: 's2_ep05_e2', line: 'The clock that turns back: Clock III.'),
  's2_ep05_e4': EvidenceLink(to: 's2_ep05_e3', line: 'LETTER No. 4417, the number on the receipt.'),
};

// ── The story's pictures, mission by mission ────────────────────────────
// Each moment shows what the detective has just reached, never more: the
// drawer only once its mark is found, Clock III's back only once it is
// caught, the envelope corner only once the place is found.
const _workshopWhole = StoryPicture(
  file: '$_case05/workshop_interior.png',
  pixels: _workshop,
  label: 'Inside a dim workshop: clocks on every wall, a long workbench, a desk and a closed door',
);

const _wallWhole = StoryPicture(
  file: '$_case05/wall_of_clocks.png',
  pixels: _wall,
  label: 'Four old clocks in a row on the workshop wall',
);

const _deskWhole = StoryPicture(
  file: '$_case05/writing_desk_blotter.png',
  pixels: _desk,
  label: 'A writing desk with a big sheet of blotting paper and ink bottles',
);

final Map<String, StoryScenes> season2Case05StoryScenes = {
  // The workshop; after it, the small drawer; then the wall of clocks.
  's2_ep05_m1': StoryScenes(
    place: _workshopWhole,
    after: StoryPicture(
      file: '$_case05/workbench_marks.png',
      pixels: _bench,
      crop: _bench.rect(1060, 300, 1536, 720),
      label: "The small drawer on the workbench, the maker's mark on its front",
    ),
    next: _wallWhole,
  ),
  // The wall; after it, Clock III's back; then the desk.
  's2_ep05_m2': const StoryScenes(
    place: _wallWhole,
    after: StoryPicture(
      file: '$_case05/clock_back_extra_wheel.png',
      pixels: _back,
      label: 'The back of Clock III: one small brass wheel among the gears',
    ),
    next: _deskWhole,
  ),
  // The desk; after it, what is in Clock III; then the workshop door.
  's2_ep05_m3': StoryScenes(
    place: _deskWhole,
    after: const StoryPicture(
      file: '$_case05/envelope_corner.png',
      pixels: _envelope,
      label: 'A torn envelope corner with a small receipt clipped to it',
      cutOut: true,
    ),
    next: StoryPicture(
      file: '$_case05/workshop_interior.png',
      pixels: _workshop,
      crop: _workshop.rect(1000, 100, 1536, 820),
      label: 'The workshop door, a line of light under it',
    ),
  ),
  // After the case: the workshop, quiet, its door shut.
  's2_ep05_final': const StoryScenes(after: _workshopWhole),
};
