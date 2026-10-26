import 'dart:ui' show Rect;

import '../../models/case_talk.dart';
import '../../models/easy_steps.dart';
import '../../models/garden_puzzles.dart' show IntroPicture;
import '../../models/river_puzzles.dart' show DrawnEvidenceArt, RiverEvidenceArt;
import '../../models/scene_exhibit.dart' show EvidenceLink;
import '../../models/scene_explore.dart' show ScenePixels;
import '../../models/story_picture.dart';

/// Season 2, Case 11's missions as they are played (every place measured on
/// the delivered pictures, in their pixels): the talks with Victor around
/// the puzzles, the puzzles' steps, the final talk. The answers, the
/// solves, their Clue and Evidence, XP, coins and the save are the case's
/// own (`episode11_mock.dart`). The design: `docs/SEASON2_CASE11_SPEC.md`,
/// played very easy (2026-10-27): one thing at a time, two answers, the
/// clue on screen, free hints.

const _case07 = 'assets/seasons/season_02_paris/cases/case_07';
const _case11 = 'assets/seasons/season_02_paris/cases/case_11';
const _people = 'assets/seasons/season_02_paris/characters';

const _wide = ScenePixels(1536, 1024);
const _square = ScenePixels(1254, 1254);
const _tall = ScenePixels(1024, 1536);

const _stamp = '$_case07/office_stamp.png';

// ── Victor ──────────────────────────────────────────────────────────────
const season2Victor = TalkSpeaker(
  id: 'victor',
  name: 'VICTOR DELACROIX',
  portraits: {
    'base': '$_people/victor_base.png',
    'nervous': '$_people/victor_nervous.png',
    'sad': '$_people/victor_sad.png',
  },
  description: 'A tall, thin man in his sixties: silver hair, a grey coat, reading glasses in his hand.',
);

const _readingRoom = '$_case11/annex_reading_room.png';

// ── The big book (1536 × 1024, cut out) ──────────────────────────────────
// Open, seen from above: the torn page's stub along the spine
// (726, 96)–(768, 883); the right page's paper (797, 134)–(1379, 845), its
// top third rubbed. The pen pressed through: two lines and a name.
const _book = EasyPicture(
  file: '$_case11/big_book_torn.png',
  pixels: _wide,
  label: 'A thick old book lying open. One page is torn out by the spine.',
);
/// The torn page's stub and the next page, close (the words come out large).
const _bookClose = EasyPicture(
  file: '$_case11/big_book_torn.png',
  pixels: _wide,
  crop: Rect.fromLTRB(640, 80, 1440, 900),
  label: 'The big book, close: the stub of the torn page, and the next page',
);
const _rubArea = Rect.fromLTRB(805, 140, 1385, 470);
const _rubLines = [
  EasyWriting('Page 3 is in Box 9.', at: Rect.fromLTRB(830, 160, 1360, 236), size: 58, ink: EasyInk.graphite),
  EasyWriting('Lock it. No one may read it.', at: Rect.fromLTRB(830, 244, 1360, 318), size: 52, ink: EasyInk.graphite),
];
const _rubSignature = EasyLayer(
  file: '$_case11/victor_signature.png',
  at: Rect.fromLTRB(925, 322, 1295, 470),
  graphite: true,
  opacity: 0.85,
);

/// The rubbed page, close: the two lines and the name.
const _rubbedPage = PicturePanel(
  id: 'rubbing',
  picture: EasyPicture(
    file: '$_case11/big_book_torn.png',
    pixels: _wide,
    crop: Rect.fromLTRB(785, 120, 1405, 490),
    label: 'The rubbed page of the big book',
  ),
  writing: _rubLines,
  layers: [_rubSignature],
  caption: 'From the big book',
);

// ── The shelves (1536 × 1024) ────────────────────────────────────────────
// Four archive boxes with blank paper labels; the top two shelves are shown
// (three boxes). Their numbers are the app's: 3 (top left), 12 (middle),
// 9 (right). Boxes: (186, 52)–(551, 301), (568, 399)–(889, 637),
// (1048, 399)–(1388, 637); labels (265, 148)–(440, 244),
// (641, 492)–(803, 580), (1148, 490)–(1313, 580).
const _box3 = Rect.fromLTRB(186, 52, 551, 301);
const _box12 = Rect.fromLTRB(568, 399, 889, 637);
const _box9 = Rect.fromLTRB(1048, 399, 1388, 637);
const _shelves = PicturePanel(
  id: 'shelves',
  picture: EasyPicture(
    file: '$_case11/annex_shelves.png',
    pixels: _wide,
    crop: Rect.fromLTRB(150, 20, 1420, 680),
    label: 'Dark wooden shelves with three archive boxes and old books',
  ),
  writing: [
    EasyWriting('3', at: Rect.fromLTRB(265, 148, 440, 244), size: 86),
    EasyWriting('12', at: Rect.fromLTRB(641, 492, 803, 580), size: 80),
    EasyWriting('9', at: Rect.fromLTRB(1148, 490, 1313, 580), size: 86),
  ],
);

// ── Box 9, open (1254 × 1254, cut out) ───────────────────────────────────
// A purple wax circle on the lid, (517, 203)–(753, 439), pressed with the
// office stamp; a folder inside, (204, 600)–(1081, 880); a label on the
// front, (451, 972)–(799, 1105).
const _openBox = PicturePanel(
  id: 'box',
  picture: EasyPicture(file: '$_case11/box9_open.png', pixels: _square, label: 'An open archive box with a folder inside and a purple seal on its lid'),
  writing: [EasyWriting('BOX 9', at: Rect.fromLTRB(471, 985, 779, 1092), size: 72)],
  layers: [EasyLayer(file: _stamp, at: Rect.fromLTRB(527, 213, 743, 429), opacity: 0.8, turns: 0.02)],
);
const _folder = Rect.fromLTRB(204, 600, 1081, 880);

// ── Page 3 (written by the app, on an old yellow page) ──────────────────
const season2Page3 = PaperPanel(
  id: 'page3',
  title: 'TRIAL LOG · PAGE 3',
  lines: [
    EasyLine('3:00  The clocks are wrong!', strong: true),
    EasyLine('3:10  E.M.: "Stop the test!"', strong: true),
    EasyLine('3:20  V.D.: "No. Keep going."', strong: true),
    EasyLine('4:00  E.M. stops the machine.'),
  ],
  aspect: 0.95,
);

/// Page 3's first line only, beside Victor's paper.
const _page3Line = PaperPanel(
  id: 'page3',
  title: 'PAGE 3 · 3:00',
  lines: [EasyLine('The clocks are wrong!', strong: true)],
  aspect: 2.1,
  caption: 'Page 3',
);

// ── Victor's paper (1024 × 1536, cut out) ───────────────────────────────
// A neat report under a pale blue cover: its header box (122, 361)–(906,
// 481); ruled lines from 518 to 1190; a stamp circle round (512, 1312),
// 102 across its inner ring, where the office stamp is pressed.
const _victorsPaperFile = '$_case11/victors_paper.png';
const _victorsWriting = [
  EasyWriting('CLOCK TEST · V.D.', at: Rect.fromLTRB(150, 375, 880, 467), size: 64, ink: EasyInk.typed),
  EasyWriting('All the clocks were fine.', at: Rect.fromLTRB(130, 545, 900, 650), size: 64, ink: EasyInk.typed, strong: true),
];
const _victorsStamp = EasyLayer(file: _stamp, at: Rect.fromLTRB(402, 1202, 622, 1422), opacity: 0.85, turns: -0.03);

const season2VictorsPaper = PicturePanel(
  id: 'victor',
  picture: EasyPicture(file: _victorsPaperFile, pixels: _tall, label: "Victor's paper: a neat report under a pale blue cover"),
  writing: _victorsWriting,
  layers: [_victorsStamp],
);

/// Its top: the heading and the line that matters.
const _victorsLine = PicturePanel(
  id: 'victor',
  picture: EasyPicture(
    file: _victorsPaperFile,
    pixels: _tall,
    crop: Rect.fromLTRB(60, 300, 965, 720),
    label: "Victor's paper",
  ),
  writing: _victorsWriting,
  caption: "Victor's paper",
);

/// Its stamp, close.
const _victorsStampClose = PicturePanel(
  id: 'victorStamp',
  picture: EasyPicture(
    file: _victorsPaperFile,
    pixels: _tall,
    crop: Rect.fromLTRB(300, 1110, 724, 1500),
    label: "The stamp on Victor's paper: a clock with no hands in a ring of leaves",
  ),
  layers: [_victorsStamp],
  caption: "Victor's paper",
);

/// The opera's Amendment Slip (Case 07), its stamp close: the same office
/// stamp, pressed at (1090, 585)–(1300, 795) of the slip's 1536 × 1024.
const _slipStampClose = PicturePanel(
  id: 'slipStamp',
  picture: EasyPicture(
    file: '$_case07/amendment_slip_blank.png',
    pixels: _wide,
    crop: Rect.fromLTRB(880, 470, 1375, 853),
    label: 'The stamp on the opera slip: a clock with no hands in a ring of leaves',
  ),
  writing: [EasyWriting('3:00', at: Rect.fromLTRB(890, 590, 1070, 700), size: 80)],
  layers: [EasyLayer(file: _stamp, at: Rect.fromLTRB(1090, 585, 1300, 795), opacity: 0.85)],
  caption: 'The opera slip',
);

// ── The visitor book (1536 × 1024, cut out) ─────────────────────────────
// Four empty lines on its right page, at y 340, 445, 551 and 655, from
// x 822 to 1350. An old visitor's name on the first (no line under it, no
// dot), Victor's today on the third.
const _visitorFile = '$_case11/visitor_book_open.png';
const _oldName = EasyLayer(file: '$_case11/signature_old_b.png', at: Rect.fromLTRB(840, 225, 1230, 357), opacity: 0.85);
const _victorsName = EasyLayer(file: '$_case11/victor_signature.png', at: Rect.fromLTRB(850, 420, 1220, 568));
const _visitorBook = PicturePanel(
  id: 'visitor',
  picture: EasyPicture(file: _visitorFile, pixels: _wide, label: 'The visitor book, open, with two names on its right page'),
  layers: [_oldName, _victorsName],
);

// ── The steps ───────────────────────────────────────────────────────────
final Map<String, EasyStepsScene> season2Case11Steps = {
  // M1: the book, the rubbing, Box 9, the folder, page 3.
  's2_ep11_m1': const EasyStepsScene(
    title: 'THE BIG BOOK',
    answer: 'page3',
    finishLabel: 'TAKE PAGE 3',
    steps: [
      EasyStep(
        id: 'book',
        say: 'Tap the big book.',
        does: EasyDo.tap,
        panels: [PicturePanel(id: 'book', picture: _book)],
        hints: ['The big book is in the middle.', 'Tap the book.'],
      ),
      EasyStep(
        id: 'rub',
        say: 'A page is torn out! Rub the next page.',
        does: EasyDo.rub,
        panels: [RubPanel(id: 'book', book: _bookClose, area: _rubArea, lines: _rubLines, signature: _rubSignature)],
        hints: ['Rub the top of the right page.', 'Move your finger. Or tap it a few times.'],
        lookHere: [EasyMark('book', _rubArea)],
        done: 'Page 3 is in Box 9! And a name.',
        doneButton: 'FIND BOX 9',
      ),
      EasyStep(
        id: 'box',
        say: 'Find Box 9.',
        does: EasyDo.choose,
        panels: [_shelves],
        options: [
          EasyOption(id: '3', label: 'Box 3', area: _box3, feedback: 'That is Box 3. Find 9.'),
          EasyOption(id: '12', label: 'Box 12', area: _box12, feedback: 'That is Box 12. Find 9.'),
          EasyOption(id: '9', label: 'Box 9', area: _box9),
        ],
        answer: '9',
        hints: ['Look at the numbers on the boxes.', 'Box 9 is on the right.'],
        lookHere: [
          EasyMark('shelves', Rect.fromLTRB(265, 148, 440, 244)),
          EasyMark('shelves', Rect.fromLTRB(641, 492, 803, 580)),
          EasyMark('shelves', Rect.fromLTRB(1148, 490, 1313, 580)),
        ],
        tell: 'Box 9 is on the right. Tap it.',
      ),
      EasyStep(
        id: 'open',
        say: 'Box 9 is open. Tap the folder.',
        does: EasyDo.tap,
        panels: [_openBox],
        target: EasyMark('box', _folder),
        hints: ['The folder is inside the box.', 'Tap the folder.'],
      ),
      EasyStep(
        id: 'page',
        say: 'You found page 3! Read it.',
        panels: [season2Page3],
        button: 'TAKE PAGE 3',
        hints: ['The clocks were wrong.', 'E.M. said "Stop!" V.D. said "Keep going."'],
      ),
    ],
  ),
  // M2: page 3 against Victor's paper; then the two stamps.
  's2_ep11_m2': const EasyStepsScene(
    title: 'TWO PAPERS',
    answer: 'notTrue',
    finishLabel: 'DONE',
    steps: [
      EasyStep(
        id: 'clocks',
        say: 'Look at the two papers.',
        panels: [_victorsLine, _page3Line],
        does: EasyDo.choose,
        question: 'Were the clocks right?',
        options: [
          EasyOption(id: 'yes', label: 'YES', feedback: 'Read page 3 again.'),
          EasyOption(id: 'no', label: 'NO'),
        ],
        answer: 'no',
        hints: ['Read page 3.', 'Page 3 says: The clocks are wrong!'],
        lookHere: [EasyMark('page3')],
        tell: 'Page 3 says the clocks were wrong. Tap NO.',
        done: "Victor's paper is not true!",
      ),
      EasyStep(
        id: 'stamps',
        say: 'Look at the two stamps.',
        panels: [_slipStampClose, _victorsStampClose],
        does: EasyDo.choose,
        question: 'Are they the same?',
        options: [
          EasyOption(id: 'yes', label: 'YES'),
          EasyOption(id: 'no', label: 'NO', feedback: 'Look again: a clock with no hands, in leaves.'),
        ],
        answer: 'yes',
        hints: ['Look at the clock in each stamp.', 'Both clocks have no hands.'],
        lookHere: [EasyMark('slipStamp', Rect.fromLTRB(1090, 585, 1300, 795)), EasyMark('victorStamp', Rect.fromLTRB(402, 1202, 622, 1422))],
        tell: 'They are the same stamp. Tap YES.',
        done: 'The same stamp! His office changed the opera paper.',
      ),
    ],
  ),
  // M3: the visitor book; the name from the big book matched to one of its
  // two names.
  's2_ep11_m3': const EasyStepsScene(
    title: 'THE VISITOR BOOK',
    answer: 'victor',
    finishLabel: 'DONE',
    steps: [
      EasyStep(
        id: 'names',
        say: 'Look at the names in the visitor book.',
        panels: [_visitorBook],
        button: 'NEXT',
        hints: ['There are two names.', 'Victor signed it today.'],
      ),
      EasyStep(
        id: 'match',
        say: 'Which name is the same?',
        does: EasyDo.choose,
        panels: [_rubbedPage],
        options: [
          EasyOption(
            id: 'old',
            label: 'A visitor, long ago',
            panel: PicturePanel(
              id: 'old',
              picture: EasyPicture(file: _visitorFile, pixels: _wide, crop: Rect.fromLTRB(800, 190, 1380, 380), label: 'An old name: a curly V, no line under it, no dot'),
              layers: [_oldName],
            ),
            feedback: 'Look: no long line, no dot.',
          ),
          EasyOption(
            id: 'victor',
            label: 'Victor, today',
            panel: PicturePanel(
              id: 'victorName',
              picture: EasyPicture(file: _visitorFile, pixels: _wide, crop: Rect.fromLTRB(800, 395, 1380, 585), label: "Victor's name: a curly V, a long line under it, a dot"),
              layers: [_victorsName],
            ),
          ),
        ],
        answer: 'victor',
        hints: ['Look at the V, the line and the dot.', 'One name has a long line under it.'],
        lookHere: [EasyMark('rubbing')],
        tell: 'The curly V, the long line, the dot: it is Victor\'s name!',
        done: "It's Victor's name! Victor signed it.",
      ),
    ],
  ),
};

// ── The talks ───────────────────────────────────────────────────────────
final Map<String, TalkMission> season2Case11TalkMissions = {
  's2_ep11_m1': TalkMission(
    before: TalkScene(
      id: 's2_ep11_m1:before',
      speaker: season2Victor,
      goal: 'Find page 3.',
      place: 'ARCHIVE ANNEX',
      background: _readingRoom,
      opening: const [
        TalkLine('Welcome to the archive.'),
        TalkLine('I am Victor Delacroix.'),
        TalkLine('Long ago, I ran a clock test.'),
        TalkLine.narrator('Victor signs the visitor book.'),
        TalkLine.detective("I'm looking for page 3."),
        TalkLine('Page 3?', mood: 'nervous'),
        TalkLine("I don't know where it is."),
        TalkLine('Look in the big book, then.', mood: 'base'),
      ],
      finishWhen: const {},
      finishLabel: 'LOOK IN THE BIG BOOK',
    ),
    after: TalkScene(
      id: 's2_ep11_m1:after',
      speaker: season2Victor,
      goal: 'Find page 3.',
      place: 'ARCHIVE ANNEX',
      background: _readingRoom,
      opening: const [
        TalkLine.narrator('You show Victor page 3.'),
        TalkLine('That box was locked!', mood: 'nervous'),
        TalkLine('…All right. There was a page 3.'),
        TalkLine.detective('Who is V.D.?'),
        TalkLine('V.D.… That is me.', mood: 'nervous'),
        TalkLine.detective('And E.M.?'),
        TalkLine('E.M. worked on the machine.', mood: 'base'),
        TalkLine('Here. Read my paper.'),
      ],
      finishWhen: const {},
    ),
  ),
  's2_ep11_m2': TalkMission(
    before: TalkScene(
      id: 's2_ep11_m2:before',
      speaker: season2Victor,
      goal: 'Find the wrong paper.',
      place: 'ARCHIVE ANNEX',
      background: _readingRoom,
      opening: const [
        TalkLine('Here is my paper.'),
        TalkLine('It tells the real story.'),
        TalkLine('My office never changed any papers.', mood: 'nervous'),
      ],
      finishWhen: const {},
      finishLabel: 'READ HIS PAPER',
    ),
    after: TalkScene(
      id: 's2_ep11_m2:after',
      speaker: season2Victor,
      goal: 'Find the wrong paper.',
      place: 'ARCHIVE ANNEX',
      background: _readingRoom,
      opening: const [
        TalkLine('All right. My paper was wrong.', mood: 'nervous'),
        TalkLine('But I did not hide page 3!'),
        TalkLine('Anyone in my office could do that.', mood: 'base'),
      ],
      finishWhen: const {},
    ),
  ),
};

/// The final: Victor's three questions, a clue shown for each from two
/// cards; then why, and who left the clues.
final Map<String, TalkScene> season2Case11Talks = {
  's2_ep11_final': TalkScene(
    id: 's2_ep11_final',
    speaker: season2Victor,
    goal: 'Show Victor the truth.',
    place: 'ARCHIVE ANNEX',
    background: _readingRoom,
    opening: const [
      TalkLine.narrator('Victor is waiting at the long table.'),
      TalkLine.detective('Victor, I found three clues.'),
      TalkLine('Clues? Show me.', mood: 'nervous'),
    ],
    presents: const [
      TalkPresent(
        id: 'three',
        prompt: 'What happened at three? Show him.',
        accepted: {'s2_ep11_e1'},
        choices: ['s2_ep11_e1', 's2_ep11_e3'],
        beat: [TalkLine('The clocks went wrong.', mood: 'nervous')],
        miss: TalkLine("That doesn't show the clocks.", mood: 'base'),
        tell: 'Show Page 3. It says the clocks were wrong.',
      ),
      TalkPresent(
        id: 'paper',
        prompt: 'Whose paper was not true? Show him.',
        accepted: {'s2_ep11_e2'},
        choices: ['s2_ep11_e1', 's2_ep11_e2'],
        requires: {'three'},
        beat: [TalkLine('…Mine.', mood: 'nervous')],
        miss: TalkLine('That paper is not mine.', mood: 'base'),
        tell: "Show Victor's Paper. It said the clocks were fine.",
      ),
      TalkPresent(
        id: 'name',
        prompt: 'Who signed the order to hide it? Show him.',
        accepted: {'s2_ep11_e3'},
        choices: ['s2_ep11_e3', 's2_ep11_e2'],
        requires: {'paper'},
        beat: [
          TalkLine('…I did.', mood: 'sad'),
          TalkLine('Yes. I hid the page.'),
          TalkLine.detective('Why?'),
          TalkLine('The test was my job.', mood: 'sad'),
          TalkLine('The clocks went wrong.'),
          TalkLine('I was afraid.'),
          TalkLine("I didn't want people to know."),
          TalkLine.detective('But the truth matters.'),
          TalkLine('I know. I am sorry.', mood: 'sad'),
        ],
        miss: TalkLine("There's no name on that.", mood: 'base'),
        tell: "Show Victor's Name. It was in the big book.",
      ),
    ],
    questions: const [
      TalkQuestion(
        id: 'bag',
        text: 'What about the office bag?',
        requires: {'name'},
        repeatable: false,
        beat: [
          TalkLine("That's one of our office bags.", mood: 'sad'),
          TalkLine('It took page 3 here.'),
          TalkLine('I wanted the tests to stop.'),
        ],
      ),
      TalkQuestion(
        id: 'clues',
        text: 'Then who left the clues for me?',
        requires: {'name'},
        repeatable: false,
        beat: [
          TalkLine('Not me. I changed no clocks.', mood: 'base'),
          TalkLine('Maybe E.M. knows.'),
          TalkLine('His old machine is at Arts et Métiers.'),
        ],
      ),
    ],
    finishWhen: const {'three', 'paper', 'name', 'clues'},
    finishLabel: 'CLOSE THE CASE',
    answer: 'victor',
  ),
};

// ── The opening ─────────────────────────────────────────────────────────
final Map<String, IntroPicture> season2Case11IntroPictures = {
  's2_ep11': const IntroPicture(
    afterLine: 0,
    turnAtLine: 2,
    from: '$_case11/annex_street.png',
    to: _readingRoom,
    pixels: _wide,
    fromLabel: 'A quiet street in old Paris, a small wooden door with a brass plate',
    toLabel: 'The archive reading room: tall shelves of old boxes and a long table',
  ),
};

// ── The notebook ────────────────────────────────────────────────────────
const season2Case11EvidenceLinks = <String, EvidenceLink>{
  's2_ep11_e1': EvidenceLink(to: 's2_ep10_e4', line: "The page missing from the Star Room's book."),
  's2_ep11_e2': EvidenceLink(to: 's2_ep07_e3', line: 'The same office stamp.'),
  's2_ep11_e3': EvidenceLink(to: 's2_ep11_e1', line: 'The order to hide this page.'),
  's2_ep11_e4': EvidenceLink(to: 's2_ep11_e3', line: 'His own name.'),
};

/// Victor's last words, as said (on Case 12's ending too).
const season2VictorsWords = QuotePanel(
  id: 'victorsWords',
  name: 'Victor',
  quote: 'Yes. I hid the page.',
  portrait: '$_people/victor_sad.png',
);

final Map<String, RiverEvidenceArt> season2Case11EvidenceArt = {
  's2_ep11_e1': const DrawnEvidenceArt(EasyEvidence(season2Page3), whole: true),
  's2_ep11_e2': const DrawnEvidenceArt(EasyEvidence(season2VictorsPaper), whole: true),
  's2_ep11_e3': const DrawnEvidenceArt(EasyEvidence(_rubbedPage), whole: true),
  's2_ep11_e4': const DrawnEvidenceArt(EasyEvidence(season2VictorsWords), whole: true),
};

// ── The story's pictures ────────────────────────────────────────────────
const _room = StoryPicture(
  file: _readingRoom,
  pixels: _wide,
  label: 'The archive reading room: tall shelves of old boxes and a long table',
);
const _street = StoryPicture(
  file: '$_case11/annex_street.png',
  pixels: _wide,
  label: 'The quiet street at Saint-Sulpice, the Archive Annex door',
);
const _boxPicture = StoryPicture(
  file: '$_case11/box9_open.png',
  pixels: _square,
  label: 'Box 9, open, a purple seal on its lid',
  cutOut: true,
);
const _paperPicture = StoryPicture(
  file: _victorsPaperFile,
  pixels: _tall,
  label: "Victor's paper under its pale blue cover",
  cutOut: true,
);
const _visitorPicture = StoryPicture(
  file: _visitorFile,
  pixels: _wide,
  label: 'The visitor book, open',
  cutOut: true,
);

final Map<String, StoryScenes> season2Case11StoryScenes = {
  's2_ep11_m1': const StoryScenes(place: _room, after: _boxPicture, next: _paperPicture),
  's2_ep11_m2': const StoryScenes(place: _room, after: _paperPicture, next: _visitorPicture),
  's2_ep11_m3': const StoryScenes(place: _room, after: _visitorPicture, next: _room),
  's2_ep11_final': const StoryScenes(after: _street),
};
