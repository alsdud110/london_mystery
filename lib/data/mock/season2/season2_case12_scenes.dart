import 'dart:ui' show Offset, Rect;

import '../../models/case_talk.dart';
import '../../models/easy_steps.dart';
import '../../models/garden_puzzles.dart' show IntroPicture;
import '../../models/river_puzzles.dart' show DrawnEvidenceArt, RiverEvidenceArt;
import '../../models/scene_exhibit.dart' show EvidenceLink;
import '../../models/scene_explore.dart' show ScenePixels;
import '../../models/story_picture.dart';

/// Season 2, Case 12's missions as they are played (every place measured on
/// the delivered pictures, in their pixels): the talks with the man by the
/// machine, the puzzles' steps, the final case board and the ending. The
/// answers, the solves, their Clue and Evidence, XP, coins and the save
/// are the case's own (`episode12_mock.dart`). The design:
/// `docs/SEASON2_CASE12_SPEC.md`, played very easy (2026-10-27).

const _case04 = 'assets/seasons/season_02_paris/cases/case_04';
const _case05 = 'assets/seasons/season_02_paris/cases/case_05';
const _case09 = 'assets/seasons/season_02_paris/cases/case_09';
const _case12 = 'assets/seasons/season_02_paris/cases/case_12';
const _people = 'assets/seasons/season_02_paris/characters';

const _wide = ScenePixels(1536, 1024);
const _square = ScenePixels(1254, 1254);
const _tallTool = ScenePixels(1024, 1536);
const _clockBack = ScenePixels(1024, 1024);

const _room = '$_case12/old_machine_room.png';
const _morning = '$_case12/finale_morning.png';

// ── Émile ───────────────────────────────────────────────────────────────
const _emileFaces = {
  'base': '$_people/emile_base.png',
  'sad': '$_people/emile_sad.png',
  'back': '$_people/emile_back.png',
};
const _emileDescription = 'A lean clockmaker in his fifties: dark hair going grey, a short beard, a leather apron.';

/// By the machine, his back turned; his name not known (M1).
const _stranger = TalkSpeaker(
  id: 'emile',
  name: 'ÉMILE MOREAU',
  hiddenName: '???',
  revealedBy: 'clockmaker',
  portraits: _emileFaces,
  baseMood: 'back',
  description: 'A man by the machine, his back turned.',
);

/// Turned round; his name known only once he says who he is (M2).
const _emileUnknown = TalkSpeaker(
  id: 'emile',
  name: 'ÉMILE MOREAU',
  hiddenName: '???',
  revealedBy: 'clockmaker',
  portraits: _emileFaces,
  description: _emileDescription,
);

const _emile = TalkSpeaker(id: 'emile', name: 'ÉMILE MOREAU', portraits: _emileFaces, description: _emileDescription);

// ── The wheels ──────────────────────────────────────────────────────────
// Clock III's small wheel (Case 05, `clock_back_extra_wheel.png`, 1024 ×
// 1024): four straight spokes like an X, round (671, 522), 59 across its
// teeth. The machine's open side (`machine_wheel_row.png`, 1536 × 1024):
// a six-spoked wheel round (313, 538), the four-spoked one round
// (707, 538) — Émile's — and a large four-spoked one round (1162, 480).
const _clockIIIWheel = PicturePanel(
  id: 'ref',
  picture: EasyPicture(
    file: '$_case05/clock_back_extra_wheel.png',
    pixels: _clockBack,
    crop: Rect.fromLTRB(596, 447, 746, 597),
    label: "Clock III's small wheel: four spokes like an X",
  ),
  caption: "Clock III's wheel (No. 7)",
);
const _rowFile = '$_case12/machine_wheel_row.png';
const _sixSpokes = PicturePanel(
  id: 'six',
  picture: EasyPicture(file: _rowFile, pixels: _wide, crop: Rect.fromLTRB(113, 338, 513, 738), label: 'A wheel with six spokes'),
);
const _emilesWheel = PicturePanel(
  id: 'emilesWheel',
  picture: EasyPicture(file: _rowFile, pixels: _wide, crop: Rect.fromLTRB(507, 338, 907, 738), label: 'A wheel with four spokes like an X'),
  caption: "Émile's wheel",
);

/// The tag on Émile's wheel: his name, and the two clock hands of No. 7.
const season2NameTag = PaperPanel(
  id: 'tag',
  title: 'NAME TAG',
  lines: [EasyLine('Made by'), EasyLine('Émile Moreau', strong: true)],
  old: false,
  foot: '$_case04/hands_sign.png',
  footLabel: 'Two clock hands: the mark of No. 7',
  aspect: 1.5,
);

// ── The Clockmaker's watch (1254 × 1254, cut out) ───────────────────────
// Its back: a blank oval round (490, 643), PARIS engraved on it (Season 1:
// "On the back: PARIS."). Open: Émile's wheel, four spokes like an X,
// round (793, 685), 113 across its teeth.
const _watchClosed = PicturePanel(
  id: 'watch',
  picture: EasyPicture(file: '$_case12/watch_back_closed.png', pixels: _square, label: "The Clockmaker's pocket watch, face down"),
  writing: [EasyWriting('PARIS', at: Rect.fromLTRB(330, 585, 650, 700), size: 92, ink: EasyInk.brass)],
);
const _watchWheel = Rect.fromLTRB(680, 572, 906, 798);
const _watchOpen = PicturePanel(
  id: 'watch',
  picture: EasyPicture(file: '$_case12/watch_back_open.png', pixels: _square, label: "The Clockmaker's watch, open: small wheels inside"),
  caption: "The Clockmaker's watch",
);

// ── Émile's little stamp (1024 × 1536, cut out) ─────────────────────────
const _tool = PicturePanel(
  id: 'tool',
  picture: EasyPicture(file: '$_case12/emile_gear_stamp.png', pixels: _tallTool, label: "Émile's little stamp: its end is a gear with eight teeth"),
  caption: "Émile's stamp",
);
const _blankPaper = GearMarkPanel(id: 'paper', label: '', stamped: false);
const _stampedPaper = GearMarkPanel(id: 'paper', label: "Émile's stamp", caption: 'Your paper');
const _clockmakersMark = GearMarkPanel(id: 'mark', label: "The Clockmaker's mark", caption: 'Gare du Nord (Case 01)');

// ── The old machine (1254 × 1254, cut out) ──────────────────────────────
// Its round recess for the big wheel, (467, 185)–(803, 521); the window
// under it, (509, 583)–(718, 630); the lever's slot (259, 404)–(298, 627);
// the pin hole round (343, 348); three little white dials round (337, 792),
// (599, 803), (867, 812), 80 across. The picture is shown with a band above
// it, where the wall clock hangs. The big wheel (1254 × 1254) turns on its
// hub (622, 622); twelve spokes, so one spoke is one hour.
const season2Machine = MachineScene(
  machine: EasyPicture(
    file: '$_case12/chronos_machine.png',
    pixels: _square,
    crop: Rect.fromLTRB(0, -130, 1254, 1254),
    label: 'The old test machine: a big brass wheel on top, a lever, a pin, and three little clocks',
  ),
  wheel: '$_case12/machine_big_wheel.png',
  wheelPixels: _square,
  wheelHub: Offset(622, 622),
  wheelAt: Rect.fromLTRB(437, 155, 835, 553),
  window: Rect.fromLTRB(509, 583, 718, 630),
  lever: '$_case12/machine_lever.png',
  leverPixels: _tallTool,
  leverAt: Rect.fromLTRB(171, 321, 387, 645),
  pin: '$_case12/machine_pin.png',
  pinPixels: _square,
  pinOut: Rect.fromLTRB(230, 180, 370, 320),
  pinIn: Rect.fromLTRB(293, 295, 393, 395),
  dials: [Offset(337, 792), Offset(599, 803), Offset(867, 812)],
  dialRadius: 80,
  wallDial: '$_case09/clock_dial.png',
  wallDialPixels: _square,
  wallDialPivot: Offset(625, 616),
  wrong: 10 * 60 + 20,
  right: 11 * 60 + 20,
);

MachinePanel _machine(MachineState state) => MachinePanel(id: 'machine', scene: season2Machine, state: state);

// ── Émile's words, for the case board ───────────────────────────────────
const _emileLook = QuotePanel(
  id: 'emileWords',
  name: 'Émile',
  quote: 'I wanted people to find the page.',
  portrait: '$_people/emile_base.png',
);
const _emileSorry = QuotePanel(
  id: 'emileWords',
  name: 'Émile',
  quote: 'I scared people. I was wrong.',
  portrait: '$_people/emile_sad.png',
);

// ── The steps ───────────────────────────────────────────────────────────
final Map<String, EasyStepsScene> season2Case12Steps = {
  // M1: the same wheel, then its tag.
  's2_ep12_m1': const EasyStepsScene(
    title: 'THE WHEELS',
    answer: 'emile',
    finishLabel: 'TAKE THE TAG',
    steps: [
      EasyStep(
        id: 'wheel',
        say: 'Look at this wheel. Find the same one.',
        does: EasyDo.choose,
        panels: [_clockIIIWheel],
        options: [
          EasyOption(id: 'six', label: 'Wheel A', panel: _sixSpokes, feedback: 'Count the spokes. Wheel A has 6.'),
          EasyOption(id: 'four', label: 'Wheel B', panel: _emilesWheel),
        ],
        answer: 'four',
        hints: ['Count the spokes.', "Clock III's wheel has 4 spokes, like an X."],
        lookHere: [EasyMark('ref')],
        tell: 'Wheel B has 4 spokes, like an X. Tap B.',
        done: 'The same wheel! A tag is on it.',
        after: [_emilesWheel, season2NameTag],
        doneButton: 'READ THE TAG',
      ),
      EasyStep(
        id: 'tag',
        say: 'Émile Moreau made this wheel!',
        panels: [_emilesWheel, season2NameTag],
        button: 'TAKE THE TAG',
        hints: ['Read the tag.', 'E.M. is Émile Moreau.'],
      ),
    ],
  ),
  // M2: the watch opened, its wheel; the stamp pressed; the marks; who.
  's2_ep12_m2': const EasyStepsScene(
    title: "THE CLOCKMAKER'S WATCH",
    answer: 'clockmaker',
    finishLabel: 'ASK HIM',
    steps: [
      EasyStep(
        id: 'open',
        say: 'Tap to open the watch.',
        does: EasyDo.tap,
        // Season 1's own evidence beside it: the watch from London.
        panels: [EvidencePanel(id: 'london', evidenceId: 'ep12_e4', caption: 'Found in London'), _watchClosed],
        target: EasyMark('watch'),
        hints: ['Tap the watch.', 'Tap anywhere on the watch.'],
      ),
      EasyStep(
        id: 'wheel',
        say: 'Tap the wheel in the watch.',
        does: EasyDo.tap,
        panels: [_watchOpen, _emilesWheel],
        // Tapped anywhere on the watch; its wheel lit.
        target: EasyMark('watch'),
        lit: [EasyMark('watch', _watchWheel)],
        hints: ['Look for 4 spokes, like an X.', 'It is on the right, inside the watch.'],
        done: 'Look! The same wheel! But anyone can use a wheel.',
        doneButton: 'FIND ONE MORE CLUE',
      ),
      EasyStep(
        id: 'stamp',
        say: 'Tap the stamp.',
        does: EasyDo.tap,
        panels: [_tool, _blankPaper],
        target: EasyMark('tool'),
        hints: ["It is Émile's little stamp.", 'Tap the stamp. It makes a mark.'],
        done: 'A mark! Look at it.',
        after: [_tool, _stampedPaper],
      ),
      EasyStep(
        id: 'marks',
        say: 'Look at the two marks.',
        panels: [_stampedPaper, _clockmakersMark],
        does: EasyDo.choose,
        question: 'Are the marks the same?',
        options: [
          EasyOption(id: 'yes', label: 'YES'),
          EasyOption(id: 'no', label: 'NO', feedback: 'Count the teeth on each gear.'),
        ],
        answer: 'yes',
        hints: ['Count the teeth.', 'Both gears have 8 teeth.'],
        lookHere: [EasyMark('paper'), EasyMark('mark')],
        tell: 'Both have 8 teeth. They are the same. Tap YES.',
        done: 'The same mark! Eight teeth.',
      ),
      EasyStep(
        id: 'who',
        say: 'Look at your three clues.',
        panels: [
          PicturePanel(
            id: 'clue1',
            picture: EasyPicture(file: _rowFile, pixels: _wide, crop: Rect.fromLTRB(507, 338, 907, 738), label: "Émile's wheel"),
            caption: 'Émile made it.',
          ),
          PicturePanel(
            id: 'clue2',
            picture: EasyPicture(file: '$_case12/watch_back_open.png', pixels: _square, crop: Rect.fromLTRB(520, 410, 960, 850), label: "The wheel in the Clockmaker's watch"),
            caption: 'It is in the watch.',
          ),
          GearMarkPanel(id: 'clue3', label: "Émile's stamp", caption: 'His stamp, the same mark.'),
        ],
        does: EasyDo.choose,
        question: 'Who is the Clockmaker?',
        options: [
          EasyOption(id: 'emile', label: 'Émile'),
          EasyOption(id: 'victor', label: 'Victor', feedback: 'Whose stamp made the mark?'),
        ],
        answer: 'emile',
        hints: ['Whose stamp made the mark?', 'Émile made the wheel and the stamp.'],
        lookHere: [EasyMark('clue3')],
        tell: "Émile's stamp makes the Clockmaker's mark. Tap Émile.",
        done: 'Émile is the Clockmaker!',
      ),
    ],
  ),
  // M3: stop, turn, fix, start.
  's2_ep12_m3': EasyStepsScene(
    title: 'FIX THE MACHINE',
    answer: 'fixed',
    finishLabel: 'DONE',
    steps: [
      EasyStep(
        id: 'stop',
        say: 'Press STOP.',
        panels: [_machine(MachineState.running)],
        button: 'STOP',
        hints: ['Step 1: stop the machine.', 'Press the big STOP button.'],
      ),
      EasyStep(
        id: 'turn',
        say: 'Tap the big wheel.',
        does: EasyDo.tap,
        panels: [_machine(MachineState.stopped)],
        target: EasyMark('machine', season2Machine.wheelTarget),
        hints: ['Step 2: turn the wheel.', 'The big wheel is at the top.'],
      ),
      EasyStep(
        id: 'pin',
        say: 'The clocks say 11:20! Tap the pin.',
        does: EasyDo.tap,
        panels: [_machine(MachineState.turned)],
        target: EasyMark('machine', season2Machine.pinTarget),
        hints: ['Step 3: the pin holds the wheel.', 'The pin is left of the wheel.'],
      ),
      EasyStep(
        id: 'start',
        say: 'Press START.',
        panels: [_machine(MachineState.pinned)],
        button: 'START',
        hints: ['Step 4: start the machine.', 'Press the big START button.'],
        done: 'All the clocks agree! You fixed the machine!',
        after: [_machine(MachineState.fixed)],
      ),
    ],
  ),
  // The final case board: six questions, one at a time, two answers each,
  // the clue for each on screen.
  's2_ep12_final': const EasyStepsScene(
    title: 'THE FINAL CASE BOARD',
    answer: 'truth',
    finishLabel: 'CLOSE THE CASE',
    steps: [
      EasyStep(
        id: 'q1',
        say: 'Question 1. Look at the clue.',
        panels: [EvidencePanel(id: 'e', evidenceId: 's2_ep10_e4', caption: 'The sun and the clocks')],
        does: EasyDo.choose,
        question: 'Did Paris lose an hour?',
        options: [EasyOption(id: 'yes', label: 'YES', feedback: 'Did the sun lose an hour?'), EasyOption(id: 'no', label: 'NO')],
        answer: 'no',
        hints: ['The sun showed the hour.', 'The hour was there. The clocks were wrong.'],
        lookHere: [EasyMark('e')],
        tell: 'The hour was there. Tap NO.',
        done: 'No. The clocks were wrong.',
      ),
      EasyStep(
        id: 'q2',
        say: 'Question 2. Look at page 3.',
        panels: [EvidencePanel(id: 'e', evidenceId: 's2_ep11_e1', caption: 'Page 3')],
        does: EasyDo.choose,
        question: 'Were the clocks wrong?',
        options: [EasyOption(id: 'yes', label: 'YES'), EasyOption(id: 'no', label: 'NO', feedback: 'Read the first line of page 3.')],
        answer: 'yes',
        hints: ['Read page 3.', 'Page 3 says: The clocks are wrong!'],
        lookHere: [EasyMark('e')],
        tell: 'Page 3 says the clocks are wrong. Tap YES.',
        done: 'Yes. Page 3 says so.',
      ),
      EasyStep(
        id: 'q3',
        say: 'Question 3. Look at the name.',
        panels: [EvidencePanel(id: 'e', evidenceId: 's2_ep11_e3', caption: 'The name in the big book')],
        does: EasyDo.choose,
        question: 'Who hid page 3?',
        options: [EasyOption(id: 'victor', label: 'Victor'), EasyOption(id: 'emile', label: 'Émile', feedback: 'Whose name was in the big book?')],
        answer: 'victor',
        hints: ['Whose name was in the big book?', 'It was the same as in the visitor book.'],
        lookHere: [EasyMark('e')],
        tell: "It is Victor's name. Tap Victor.",
        done: 'Victor hid it.',
      ),
      EasyStep(
        id: 'q4',
        say: 'Question 4. Look at the mark.',
        panels: [EvidencePanel(id: 'e', evidenceId: 's2_ep12_e2', caption: "The Clockmaker's mark")],
        does: EasyDo.choose,
        question: 'Who is the Clockmaker?',
        options: [EasyOption(id: 'victor', label: 'Victor', feedback: 'Whose stamp made the mark?'), EasyOption(id: 'emile', label: 'Émile')],
        answer: 'emile',
        hints: ['Whose stamp made the mark?', "Émile's stamp made it."],
        lookHere: [EasyMark('e')],
        tell: "Émile's stamp made the mark. Tap Émile.",
        done: 'Émile is the Clockmaker.',
      ),
      EasyStep(
        id: 'q5',
        say: 'Question 5. Read what Émile said.',
        panels: [_emileLook],
        does: EasyDo.choose,
        question: 'Why did Émile leave clues?',
        options: [
          EasyOption(id: 'show', label: 'To show the truth'),
          EasyOption(id: 'hide', label: 'To hide the truth', feedback: 'He wanted people to find the page.'),
        ],
        answer: 'show',
        hints: ['Read what Émile said.', 'He wanted people to find page 3.'],
        lookHere: [EasyMark('emileWords')],
        tell: 'He wanted the page found. Tap: To show the truth.',
        done: 'To show the truth.',
      ),
      EasyStep(
        id: 'q6',
        say: 'Question 6. Read what Émile said.',
        panels: [_emileSorry],
        does: EasyDo.choose,
        question: 'Was Émile right to scare people?',
        options: [
          EasyOption(id: 'yes', label: 'YES', feedback: 'A good reason does not make it OK.'),
          EasyOption(id: 'no', label: 'NO'),
        ],
        answer: 'no',
        hints: ['Read what Émile said.', 'He said: I was wrong.'],
        lookHere: [EasyMark('emileWords')],
        tell: 'Émile said he was wrong. Tap NO.',
        done: 'No. He made bad choices.',
      ),
    ],
  ),
};

// ── The talks ───────────────────────────────────────────────────────────
final Map<String, TalkMission> season2Case12TalkMissions = {
  's2_ep12_m1': TalkMission(
    before: TalkScene(
      id: 's2_ep12_m1:before',
      speaker: _stranger,
      goal: 'Who is he?',
      place: 'THE MACHINE ROOM',
      background: _room,
      opening: const [
        TalkLine.detective('Someone is here.'),
        TalkLine('You found me.'),
        TalkLine.detective('Who are you?'),
        TalkLine("Don't ask me."),
        TalkLine('Find out with clues.'),
      ],
      finishWhen: const {},
      finishLabel: 'OPEN THE MACHINE',
    ),
    after: TalkScene(
      id: 's2_ep12_m1:after',
      speaker: _stranger,
      goal: 'Who is he?',
      place: 'THE MACHINE ROOM',
      background: _room,
      opening: const [
        TalkLine.detective('Émile made this wheel!'),
        TalkLine.detective('Émile Moreau… E.M.!'),
        TalkLine('You are getting close.'),
      ],
      finishWhen: const {},
    ),
  ),
  's2_ep12_m2': TalkMission(
    before: TalkScene(
      id: 's2_ep12_m2:before',
      speaker: _emileUnknown,
      goal: 'Find the Clockmaker.',
      place: 'THE WORKBENCH',
      background: _room,
      opening: const [
        TalkLine.narrator('He turns around.'),
        TalkLine('Hello, detective.'),
        TalkLine("You have the Clockmaker's watch."),
        TalkLine('Open it.'),
        TalkLine("Don't trust my words. Trust clues."),
      ],
      finishWhen: const {},
      finishLabel: 'OPEN THE WATCH',
    ),
    after: TalkScene(
      id: 's2_ep12_m2:after',
      speaker: _emileUnknown,
      goal: 'Why did he leave the clues?',
      place: 'THE WORKBENCH',
      background: _room,
      opening: const [
        TalkLine.detective('You made this wheel.'),
        TalkLine('Yes, I did.'),
        TalkLine.detective("It is in the Clockmaker's watch."),
        TalkLine("That's right."),
        TalkLine.detective('And your stamp makes his mark.'),
        TalkLine('You found it.'),
      ],
      questions: const [
        TalkQuestion(
          id: 'clockmaker',
          text: 'Are you the Clockmaker?',
          repeatable: false,
          beat: [
            TalkLine('Yes. I am.'),
            TalkLine('I am Émile Moreau.'),
            TalkLine.detective('You said, "Stop the test!"'),
            TalkLine('I did. Nobody listened.', mood: 'sad'),
          ],
        ),
        TalkQuestion(
          id: 'why',
          text: 'Why did you do it?',
          requires: {'clockmaker'},
          repeatable: false,
          beat: [
            TalkLine('I wanted people to look.', mood: 'base'),
            TalkLine.detective('Look for what?'),
            TalkLine('The missing page.'),
            TalkLine.detective('But you scared people.'),
            TalkLine('I know. I was wrong.', mood: 'sad'),
          ],
        ),
        TalkQuestion(
          id: 'bigBen',
          text: 'And Big Ben?',
          requires: {'why'},
          repeatable: false,
          beat: [
            TalkLine('I tried to stop Big Ben.', mood: 'base'),
            TalkLine('A secret box is under it.'),
            TalkLine('Inside is a list of hidden papers.'),
            TalkLine('It opens only if Big Ben stops.'),
            TalkLine.detective('But I stopped you.'),
            TalkLine('Yes. It never opened.', mood: 'sad'),
          ],
        ),
        TalkQuestion(
          id: 'clues',
          text: 'Why did you leave clues for me?',
          requires: {'bigBen'},
          repeatable: false,
          beat: [
            TalkLine('You stopped me with clues.', mood: 'base'),
            TalkLine('People trust clues.'),
            TalkLine("I hoped you'd find the page."),
            TalkLine('But I set clocks wrong in Paris too.', mood: 'sad'),
            TalkLine('People were confused. That was wrong.'),
          ],
        ),
      ],
      finishWhen: const {'clockmaker', 'why', 'bigBen', 'clues'},
    ),
  ),
  's2_ep12_m3': TalkMission(
    before: TalkScene(
      id: 's2_ep12_m3:before',
      speaker: _emile,
      goal: 'Fix the old machine.',
      place: 'THE MACHINE ROOM',
      background: _room,
      opening: const [
        TalkLine.detective('Why is the machine still wrong?'),
        TalkLine('On the test day, I stopped it.'),
        TalkLine('Then Victor stopped all the tests.', mood: 'sad'),
        TalkLine('Nobody fixed the machine.'),
        TalkLine.detective('Can I fix it?'),
        TalkLine('Yes. Stop, turn, fix, start.', mood: 'base'),
      ],
      finishWhen: const {},
      finishLabel: 'FIX THE MACHINE',
    ),
    after: TalkScene(
      id: 's2_ep12_m3:after',
      speaker: _emile,
      goal: 'Fix the old machine.',
      place: 'THE MACHINE ROOM',
      background: _room,
      opening: const [
        TalkLine("It's right at last."),
        TalkLine('Thank you, detective.'),
      ],
      finishWhen: const {},
    ),
  ),
};

// ── The ending ──────────────────────────────────────────────────────────
/// After the final case board: Victor's words in the case file, Émile's,
/// the detective's three lines, page 3 kept safe. One line at a time; its
/// last two lines follow, over the morning (the final's story).
const season2Case12Ending = <EndingLine>[
  EndingLine("Victor's words are in the case file.", background: _room, evidenceId: 's2_ep11_e4'),
  EndingLine('Yes. I hid the page.', voice: TalkVoice.speaker, name: "VICTOR'S RECORD", background: _room, evidenceId: 's2_ep11_e4'),
  EndingLine('And I made bad choices.', voice: TalkVoice.speaker, name: 'ÉMILE MOREAU', portrait: '$_people/emile_sad.png', background: _room),
  EndingLine("I scared people. I'm sorry.", voice: TalkVoice.speaker, name: 'ÉMILE MOREAU', portrait: '$_people/emile_sad.png', background: _room),
  EndingLine('I will tell everyone what I did.', voice: TalkVoice.speaker, name: 'ÉMILE MOREAU', portrait: '$_people/emile_base.png', background: _room),
  EndingLine('The clocks were wrong.', voice: TalkVoice.detective, background: _room),
  EndingLine('Victor hid the truth.', voice: TalkVoice.detective, background: _room),
  EndingLine('Émile left the clues.', voice: TalkVoice.detective, background: _room),
  EndingLine('But now everyone can know.', voice: TalkVoice.detective, background: _room),
  EndingLine('Page 3 goes into a glass case.', background: _morning),
  EndingLine('No one can hide it again.', background: _morning),
];

final Map<String, List<EndingLine>> season2Case12Endings = {'s2_ep12_final': season2Case12Ending};

// ── The opening ─────────────────────────────────────────────────────────
final Map<String, IntroPicture> season2Case12IntroPictures = {
  's2_ep12': const IntroPicture(
    afterLine: 0,
    turnAtLine: 1,
    from: '$_case12/arts_metiers_hall.png',
    to: _room,
    pixels: _wide,
    fromLabel: 'A tall old museum hall full of historic machines',
    toLabel: 'A small quiet room for old machines, a workbench with a green lamp',
  ),
};

// ── The notebook ────────────────────────────────────────────────────────
const season2Case12EvidenceLinks = <String, EvidenceLink>{
  's2_ep12_e1': EvidenceLink(to: 's2_ep05_e2', line: 'The same small wheel.'),
  's2_ep12_e2': EvidenceLink(to: 's2_ep01_e3', line: 'The same gear mark.'),
  's2_ep12_e3': EvidenceLink(to: 's2_ep09_e4', line: 'In the garden, a model went wrong. Here, you fixed the real machine.'),
  's2_ep12_e4': EvidenceLink(to: 's2_ep11_e1', line: 'Page 3, safe in a glass case.'),
};

final Map<String, RiverEvidenceArt> season2Case12EvidenceArt = {
  's2_ep12_e1': const DrawnEvidenceArt(EasyEvidence(season2NameTag), whole: true),
  's2_ep12_e2': const DrawnEvidenceArt(EasyEvidence(GearMarkPanel(id: 'mark', label: "The Clockmaker's mark")), whole: true),
  's2_ep12_e3': DrawnEvidenceArt(EasyEvidence(_machine(MachineState.fixed)), whole: true),
  's2_ep12_e4': const DrawnEvidenceArt(
    EasyEvidence(
      PaperPanel(
        id: 'caseFile',
        title: 'CASE FILE · PARIS',
        lines: [
          EasyLine('The clocks were wrong.', strong: true),
          EasyLine('Victor hid the truth.', strong: true),
          EasyLine('Émile left the clues.', strong: true),
          EasyLine('But he scared people.'),
        ],
        old: false,
        aspect: 0.95,
      ),
    ),
    whole: true,
  ),
};

// ── The story's pictures ────────────────────────────────────────────────
const _roomPicture = StoryPicture(file: _room, pixels: _wide, label: 'A small quiet room for old machines');
const _rowPicture = StoryPicture(file: _rowFile, pixels: _wide, label: 'Three brass wheels inside the machine', cutOut: true);
const _watchPicture = StoryPicture(file: '$_case12/watch_back_closed.png', pixels: _square, label: "The Clockmaker's pocket watch", cutOut: true);
const _toolPicture = StoryPicture(file: '$_case12/emile_gear_stamp.png', pixels: _tallTool, label: "Émile's little stamp", cutOut: true);
const _machinePicture = StoryPicture(file: '$_case12/chronos_machine.png', pixels: _square, label: 'The old test machine', cutOut: true);
const _morningPicture = StoryPicture(file: _morning, pixels: _wide, label: 'Morning in the machine room: page 3 safe in a glass case');

final Map<String, StoryScenes> season2Case12StoryScenes = {
  's2_ep12_m1': const StoryScenes(place: _roomPicture, after: _rowPicture, next: _watchPicture),
  's2_ep12_m2': const StoryScenes(place: _roomPicture, after: _toolPicture, next: _machinePicture),
  's2_ep12_m3': const StoryScenes(place: _roomPicture, after: _machinePicture, next: _roomPicture),
  's2_ep12_final': const StoryScenes(after: _morningPicture),
};
