import '../../../models/learning.dart';
import '../../../models/river_puzzles.dart';
import '../season2_case04_scenes.dart';
import 'level_words.dart';

// Case 04 — The River's Secret, at each level (PART 7B): the words only
// (`docs/difficulty_reviews/PARIS_CASE_04_06.md`).
//
// Cases 04–06:
//
// Rookie: the game's own words, reviewed; two lines made plainer (Case 05
// M1's crate, M3's evidence), and the words a child may not know added to
// the glossary.
//
// At every level the same: the papers each puzzle is read from (the
// plaque's back, the marks' words, the ledger, the label and its scrap, the
// street book, the note and the repair card, the receipt, the slips, the
// tags, the porter's note, the drawers, the letter and its back), the lines
// the story bible gives as they are ("Wait! It wasn't stolen.", "Someone
// kept it safe.", "We found our next clue!", the cases' end questions of
// Cases 05 and 06), every answer, id and order, and every way to play
// (Tap…, Turn…, Drag…).
//
// Kept untold at every level: who the Clockmaker is; whose the two clock
// hands are; what the clock parts were for; that the letter was really in
// Clock III, or who took it out; what the letter says before it is found,
// who wrote it, who held it and why; where the letter leads before the
// drawing is placed.

/// Words of the game's own pages a child may not know, on every level's
/// pages; and those on some levels' pages only.
const words04 = {'stone': '돌', 'wooden': '나무로 된', 'shelf': '선반', 'somewhere': '어딘가에'};
const _burning = {'burning': '타고 있는, 켜져 있는'};
const _rookieOnly04 = {..._burning, 'caught': '걸린, 끼인', 'lists': '목록에 싣다'};

/// Rookie's glossary for each case.
const rookieWords04 = {...words04, ..._rookieOnly04};

/// Junior's own words, found on Junior's pages (Master's too, unless
/// Master says it its own way).
const juniorWords04 = {'matches': '일치하다, 맞다', 'mention': '언급하다', 'stuck': '끼인, 걸린', 'reminds': '다시 알려 주다'};

const masterWords04 = {
  'weathered': '비바람에 닳은',
  'bears': '(표시를) 지니고 있다',
  'descend': '내려가다',
  'enamel': '에나멜(유약을 바른)',
  'satisfies': '충족하다, 맞다',
  'destination': '목적지',
  'snagged': '걸린',
  'tracked': '추적했다',
};

/// The plaque's three lines, as scratched (the puzzle is read from them).
const _plaqueLines =
    'Three waves mark the place.\n'
    'Follow the arrow towards the river.\n'
    'Find the one who watches the water.';

/// The label, read back once it is whole (its own printed words).
const _labelLines = ['FROM: EIFFEL TOWER — SERVICE LEVEL.', 'CONTENTS: CLOCK PARTS.', 'TO: THE WATCHMAKERS. PASSAGE D…'];

/// The notebook's two clues for the address (the step shows them under
/// their evidence, as written).
const _twoClues = 'CLUE 1: PASSAGE\nCLUE 2: No. 7\n\n';

const rookie04 = <String, Object?>{'glossary': rookieWords04};

final junior04 = <String, Object?>{
  'synopsis': [
    'The brass plaque showed three small waves and one word: SEINE.',
    'Three lines scratched on its back lead you down to the river.',
    'The crate from the tower went there too. Where is it now?',
  ],
  'objectives': [
    'Find the mark on the quay wall that fits all three lines.',
    "Read the river keeper's ledger carefully.",
    'Put the torn delivery label back together.',
  ],
  'intro': [
    'Three small waves, and one word: SEINE.',
    'You lift the brass plaque up to the light of a street lamp.',
    'On the back, someone has scratched three short lines.',
    'Down by the river, there are old stone walls and dark, quiet water.',
    'Somewhere along these quays, a mark is waiting to be found.',
  ],
  'caseSummary': "Three waves, the keeper's ledger and a torn label led you to a single address.",
  'hook': 'Do not trust the clocks. So whose hands made them?',
  'glossary': {...words04, ..._burning, ...juniorWords04},
  'missions': {
    's2_ep04_m1': {
      'story': ['Four marks are carved into the old stone wall by the river.', 'Each mark has some waves, an arrow and a word.'],
      'letterIntro': 'On the back of the brass plaque, you read:',
      'letter': _plaqueLines,
      'question': 'Which mark matches all three lines?',
      'hints': [
        'Each line of the plaque is one thing to check. Take them one at a time.',
        'Check every mark: count the waves, follow the arrow and read the word.',
      ],
      'successMessage': "That's the River Keeper's mark!",
      'transition': [
        "Next to the mark, the keeper's steps lead down to the water.",
        'A small sign on the wall reads QUAY 3.',
        'At the bottom of the steps, there is a little wooden hut.',
      ],
      'options': {
        'a': {'feedback': 'Read line 2 again. Which way does the arrow on Mark A point?'},
        'b': {'feedback': 'Read line 3 again, then the word on Mark B. Do booksellers watch the water?'},
        'c': {'feedback': 'Read line 1 again. How many waves does Mark C have?'},
      },
      'clue': {'note': "Next to the mark, the keeper's steps lead down to the water. QUAY 3."},
      'evidence': {'description': 'Carved into the quay wall, next to stone steps that lead to the water.'},
    },
    's2_ep04_m2': {
      'story': ["The door of the keeper's hut is open. A lamp is burning inside.", 'The river keeper writes down every box that arrives and leaves.'],
      'letterIntro': 'Your notebook reminds you:',
      'letter':
          'The crate from the tower was sent to the river.\n'
          'The River Mark says QUAY 3.\n\n'
          "Read the keeper's ledger.\n"
          "Which box holds the tower's crate now?",
      'question': "Which box holds the tower's crate now?",
      'hints': [
        'Look for the lines that say "from the Eiffel Tower". Only one of them is on Quay 3.',
        'Follow that box down the page. What happened to it on 14 May?',
      ],
      'successMessage': 'You found the right box!',
      'transition': [
        'On 14 May, Box 17 was moved to Box 23.',
        'Then, on 15 May, Box 23 was collected for No. 7.',
        'Every one of these lines is signed with the same mark: two clock hands.',
        'Outside, a row of green boxes stands along the quay.',
      ],
      'options': {
        'box4': {'feedback': 'Box 4 is full of old books from the bookstalls, not things from the Eiffel Tower.'},
        'box9': {'feedback': 'Box 9 came from the tower, but it is on Quay 1. The River Mark says QUAY 3.'},
        'box12': {'feedback': 'Box 12 holds lamp oil from Pont Neuf. It did not come from the Eiffel Tower.'},
        'box17': {'feedback': 'The heavy crate did go into Box 17. Now read the last line. Is it still there?'},
        'box6': {'feedback': 'Box 6 came from the tower, but it is on Quay 2. The River Mark says QUAY 3.'},
      },
      'clue': {'note': "Box 23 was collected for No. 7. It was to be delivered through the keeper's steps."},
      'evidence': {'description': "It lies open on the desk in the river keeper's hut."},
    },
    's2_ep04_m3': {
      'story': ['Four green boxes stand in a row on the river wall.', 'One of them holds the things that came from the tower.'],
      'letterIntro': 'In your notebook, you wrote:',
      'letter':
          'Open BOX 23.\n'
          'Fit the pieces of the torn label together.\n'
          'Read where the box was sent.',
      'question': 'Fit the torn label back together.',
      'hints': [
        'One scrap does not belong to this label. It is thin and blue-grey, so leave it out.',
        'A label reads FROM, then CONTENTS, then TO. Start with the piece that has the eyelet.',
      ],
      'successMessage': 'The label is back in one piece!',
      'transition': [..._labelLines, "Back in the keeper's hut, there is an old street book on a shelf."],
      'feedback': {
        for (final slot in ['top', 'middle', 'bottom']) 'decoy:$slot': 'That scrap is not from this label. It is thin and blue-grey, and its ink is blue.',
        'p1:middle': 'A label hangs from its brass eyelet, so that piece belongs at the top.',
        'p1:bottom': 'A label hangs from its brass eyelet, so that piece belongs at the top.',
        'p2:top': 'A label starts with FROM. CONTENTS comes after it.',
        'p2:bottom': 'CONTENTS comes before TO. Check that the torn edges meet.',
        'p3:top': 'Where a parcel is going is written last. Find the line with TO.',
        'p3:middle': 'Where a parcel is going is written last. Find the line with TO.',
      },
      'clue': {'note': 'TO: THE WATCHMAKERS. The house number has been washed away. Then PASSAGE D…'},
      'evidence': {'description': 'It was found inside Box 23 on the quay.'},
    },
    's2_ep04_final': {
      'story': ["The keeper's street book has a list of the watchmakers' streets.", 'Only one of them can be the address on the label.'],
      'letterIntro': 'Your notebook has two clues:',
      'letter': '${_twoClues}Which address fits both clues?',
      'question': 'Which address is it?',
      'hints': [
        'Both streets start with PASSAGE, so CLUE 1 fits both. Now check CLUE 2.',
        'CLUE 2 says No. 7. Find the address with that number.',
      ],
      'successMessage': 'You found the right address!',
      'transition': [
        'PASSAGE DES HORLOGERS.',
        'Behind the iron gate, the workshops are dark and silent.',
        'Do not trust the clocks.',
        'Follow the hands that made them.',
        'But whose hands made them?',
      ],
      'evidence': {'description': 'The last piece of the label, stuck in the gate of PASSAGE DES HORLOGERS.'},
    },
  },
};

final master04 = <String, Object?>{
  'synopsis': [
    'The brass plaque bore three small waves and a single word: SEINE.',
    'Three lines scratched on its back point you towards the river.',
    'The crate from the tower travelled there too. Where is it now?',
  ],
  'objectives': [
    'Find the one mark on the quay wall that satisfies all three lines.',
    "Follow the boxes through the river keeper's ledger.",
    'Piece the torn delivery label back together.',
  ],
  'intro': [
    'Three small waves above a single word: SEINE.',
    'You tilt the brass plaque towards the glow of a street lamp.',
    'Scratched into its back are three short lines.',
    'Below, the river runs dark and quiet between old stone walls.',
    'Somewhere along these quays, a mark is waiting for you to find it.',
  ],
  'caseSummary': "A carved mark, a keeper's ledger and a torn label pointed you to one address.",
  'hook': '"Do not trust the clocks." But whose hands made them?',
  'glossary': {...words04, ...masterWords04},
  'missions': {
    's2_ep04_m1': {
      'story': ['Four marks have been carved into the weathered quay wall.', 'Each one bears waves, an arrow and a single word.'],
      'letterIntro': 'Scratched into the back of the brass plaque:',
      'letter': _plaqueLines,
      'question': 'Which mark satisfies all three lines?',
      'hints': [
        'The plaque sets three tests. The right mark must pass all of them.',
        'Waves, arrow, word: a mark that fails even one test is not the one.',
      ],
      'successMessage': "The River Keeper's mark, at last!",
      'transition': [
        "Beside the mark, the keeper's steps descend to the water's edge.",
        'A small enamel sign on the wall reads QUAY 3.',
        'At the foot of the steps waits a little wooden hut.',
      ],
      'options': {
        'a': {'feedback': 'Line 2 tells you where the arrow should point. Does Mark A agree?'},
        'b': {'feedback': "Line 3 asks for the one who watches the water. Is that a bookseller's job?"},
        'c': {'feedback': "Line 1 names a number of waves. Count Mark C's carefully."},
      },
      'clue': {'note': "The keeper's steps descend beside the mark, down to the water. QUAY 3."},
      'evidence': {'description': 'Carved into the quay wall, beside stone steps that descend to the river.'},
    },
    's2_ep04_m2': {
      'story': ["The keeper's hut stands open, a lamp glowing inside.", 'Every box that comes and goes along the river is written down here.'],
      'letterIntro': 'Your notebook holds what you know so far:',
      'letter':
          'The crate from the tower was sent down to the river.\n'
          'The River Mark points to QUAY 3.\n\n'
          "The keeper's ledger should tell you more.\n"
          'Where has the crate ended up?',
      'question': "In which box does the tower's crate sit now?",
      'hints': [
        'Three things came from the Eiffel Tower, but your River Mark leaves only one quay.',
        'A box can change. Trace that crate through the later lines of the page.',
      ],
      'successMessage': 'The crate is tracked down!',
      'transition': [
        'On 14 May, the crate was moved from Box 17 to Box 23.',
        'A day later, Box 23 was collected for No. 7.',
        'Each of these entries bears the same signature: two clock hands.',
        'Outside, a row of green boxes lines the quay.',
      ],
      'options': {
        'box4': {'feedback': 'Box 4 holds old books from the bookstalls. Nothing from the Eiffel Tower there.'},
        'box9': {'feedback': 'Box 9 did come from the tower, but it sits on Quay 1, not QUAY 3.'},
        'box12': {'feedback': 'Box 12 is lamp oil, sent from Pont Neuf rather than the Eiffel Tower.'},
        'box17': {'feedback': 'The heavy crate began in Box 17. But read on: did it stay there?'},
        'box6': {'feedback': 'Box 6 did come from the tower, but it sits on Quay 2, not QUAY 3.'},
      },
      'clue': {'note': "Box 23 was collected for No. 7, to be delivered by way of the keeper's steps."},
      'evidence': {'description': "Left open on the desk inside the river keeper's hut."},
    },
    's2_ep04_m3': {
      'story': ['Four green boxes are lined up along the river wall.', 'Somewhere among them is what came down from the tower.'],
      'letterIntro': 'Your notebook spells out the next step:',
      'letter':
          'Open BOX 23.\n'
          'Piece the torn label back together.\n'
          'Then discover where it was being sent.',
      'question': 'Piece the torn label back together.',
      'hints': [
        'Not every scrap in the box is part of the label. Compare the paper and the ink.',
        'Think of how any label is written, from top to bottom, and where it is tied on.',
      ],
      'successMessage': 'The torn label is whole again!',
      'transition': [..._labelLines, "Back in the keeper's hut, an old street book waits on a shelf."],
      'feedback': {
        for (final slot in ['top', 'middle', 'bottom']) 'decoy:$slot': 'That scrap belongs to another paper altogether: thin, blue-grey, written in blue ink.',
        'p1:middle': 'A label is tied on by its brass eyelet. That piece must go at the top.',
        'p1:bottom': 'A label is tied on by its brass eyelet. That piece must go at the top.',
        'p2:top': 'FROM always opens a label. CONTENTS follows it.',
        'p2:bottom': 'CONTENTS belongs above TO. Do the torn edges line up?',
        'p3:top': "A parcel's destination is written last. Look for TO.",
        'p3:middle': "A parcel's destination is written last. Look for TO.",
      },
      'clue': {'note': 'TO: THE WATCHMAKERS. The house number is lost to the water. Then PASSAGE D…'},
      'evidence': {'description': 'Found tucked inside Box 23, down on the quay.'},
    },
    's2_ep04_final': {
      'story': ["The keeper's street book records every street of watchmakers.", 'Only one of them can match the address on the label.'],
      'letterIntro': 'Two clues are written in your notebook:',
      'letter': '${_twoClues}Only one address fits both.',
      'question': 'Which address fits both clues?',
      'hints': ['CLUE 1 cannot decide between them. Let CLUE 2 settle it.', 'Compare each house number with CLUE 2.'],
      'successMessage': 'You tracked down the address!',
      'transition': [
        'PASSAGE DES HORLOGERS.',
        'Beyond the iron gate, the workshops lie dark and still.',
        'Do not trust the clocks.',
        'Follow the hands that made them.',
        'Yet whose hands could they be?',
      ],
      'evidence': {'description': "The label's missing piece, snagged on the gate of PASSAGE DES HORLOGERS."},
    },
  },
};

// ═════════════════════════════════════════════════════════════════════════
// The scenes' own words
// ═════════════════════════════════════════════════════════════════════════

/// The quay wall: what is said, line by line, once Mark D is checked. The
/// marks, the plaque and every way to play are the base's.
RiverMarksScene _wall(RiverMarksScene base, List<String> rightLines) => RiverMarksScene(
      wall: base.wall,
      pixels: base.pixels,
      place: base.place,
      marks: base.marks,
      closePixels: base.closePixels,
      signAt: base.signAt,
      sign: base.sign,
      plaqueFront: base.plaqueFront,
      plaqueBack: base.plaqueBack,
      readTask: base.readTask,
      chooseTask: base.chooseTask,
      chooseLabel: base.chooseLabel,
      rightLines: rightLines,
    );

/// The keeper's hut: what is said once the box is circled, and once it is
/// found on the second page. The ledger is the base's.
KeeperHutScene _hut(KeeperHutScene base, {required String solvedLine, required String foundLine}) => KeeperHutScene(
      outside: base.outside,
      outsideLabel: base.outsideLabel,
      doorArea: base.doorArea,
      inside: base.inside,
      insideLabel: base.insideLabel,
      ledgerArea: base.ledgerArea,
      pixels: base.pixels,
      ledger: base.ledger,
      ledgerPixels: base.ledgerPixels,
      ledgerLabel: base.ledgerLabel,
      pages: base.pages,
      hands: base.hands,
      doorTask: base.doorTask,
      ledgerTask: base.ledgerTask,
      circleTask: base.circleTask,
      checkLabel: base.checkLabel,
      solvedLine: solvedLine,
      turnLabel: base.turnLabel,
      findTask: base.findTask,
      foundLine: foundLine,
      findBox: base.findBox,
    );

/// The green boxes: what each box says when it is not the one. The label
/// and its scrap are the base's.
BoxesScene _boxes(BoxesScene base, Map<String, String> notes) => BoxesScene(
      picture: base.picture,
      pixels: base.pixels,
      place: base.place,
      view: base.view,
      boxes: [
        for (final b in base.boxes) QuayBox(id: b.id, number: b.number, area: b.area, plateAt: b.plateAt, note: b.note == null ? null : notes[b.id]!),
      ],
      open: base.open,
      openPixels: base.openPixels,
      openLabel: base.openLabel,
      decoy: base.decoy,
      decoyPixels: base.decoyPixels,
      decoyAt: base.decoyAt,
      decoyLines: base.decoyLines,
      label: base.label,
      slots: base.slots,
      boxTask: base.boxTask,
      labelTask: base.labelTask,
      checkLabel: base.checkLabel,
    );

/// Case 04's scenes with Junior's words.
final juniorScenes04 = (
  riverMarks: {
    's2_ep04_m1': _wall(season2RiverMarks['s2_ep04_m1']!, const [
      'Three waves, just as line 1 says.',
      'The arrow points down, towards the river.',
      'RIVER KEEPER: the one who watches the water.',
    ]),
  },
  keeperHuts: {
    's2_ep04_m2': _hut(season2KeeperHuts['s2_ep04_m2']!, solvedLine: 'Box 23 holds the crate now.', foundLine: 'Look: Box 23 was collected for No. 7.'),
  },
  quayBoxes: {
    's2_ep04_m3': _boxes(season2QuayBoxes['s2_ep04_m3']!, const {
      'box12': 'Box 12 is empty. Its lamp oil was collected on 15 May.',
      'box17': 'Box 17 is empty. Its crate was moved to Box 23.',
      'box21': 'Box 21 is locked, and the ledger does not mention it.',
    }),
  },
  easySteps: {
    's2_ep04_final': retold(season2Case04Steps['s2_ep04_final']!, const {
      'address': (
        say: 'Which address is it?',
        hints: ['Both streets start with PASSAGE, so CLUE 1 fits both. Now check CLUE 2.', 'CLUE 2 says No. 7. Find the address with that number.'],
        feedback: {'pont': 'Read CLUE 2 again. Does it say No. 3?'},
        tell: 'PASSAGE DES HORLOGERS is the one with No. 7.',
        done: 'It is No. 7, PASSAGE DES HORLOGERS!',
      ),
    }),
  },
);

/// Case 04's scenes with Master's words.
final masterScenes04 = (
  riverMarks: {
    's2_ep04_m1': _wall(season2RiverMarks['s2_ep04_m1']!, const [
      'Three waves, exactly as line 1 asks.',
      'An arrow pointing down, towards the river.',
      'RIVER KEEPER: the one who keeps watch over the water.',
    ]),
  },
  keeperHuts: {
    's2_ep04_m2': _hut(season2KeeperHuts['s2_ep04_m2']!, solvedLine: 'The crate now rests in Box 23.', foundLine: 'There it is: Box 23, collected for No. 7.'),
  },
  quayBoxes: {
    's2_ep04_m3': _boxes(season2QuayBoxes['s2_ep04_m3']!, const {
      'box12': 'Box 12 stands empty; its lamp oil was collected on 15 May.',
      'box17': 'Box 17 is bare. Whatever it held was moved to Box 23.',
      'box21': 'Box 21 is locked tight, and the ledger never mentions it.',
    }),
  },
  easySteps: {
    's2_ep04_final': retold(season2Case04Steps['s2_ep04_final']!, const {
      'address': (
        say: 'Which address fits both clues?',
        hints: ['CLUE 1 cannot decide between them. Let CLUE 2 settle it.', 'Compare each house number with CLUE 2.'],
        feedback: {'pont': 'CLUE 2 gives a house number. Is it 3?'},
        tell: 'Only PASSAGE DES HORLOGERS has No. 7.',
        done: "No. 7, PASSAGE DES HORLOGERS: the watchmakers' address!",
      ),
    }),
  },
);

/// Case 04's scenes whose words are the same at every level (see
/// `season2SameAtEveryLevel`).
const sameAtEveryLevel04 = {
  'streetBooks/s2_ep04_final',
};

// ═════════════════════════════════════════════════════════════════════════
// The learning design
// ═════════════════════════════════════════════════════════════════════════

final juniorLearning04 = <String, LearningObjective>{
  's2_ep04_m1': levelObjective('s2_ep04_m1', ['Follow the arrow towards the river.', 'Find the one who watches the water.', 'Which mark matches all three lines?']),
  's2_ep04_m2': levelObjective('s2_ep04_m2', ['was sent to the river', "Which box holds the tower's crate now?"]),
  's2_ep04_m3': levelObjective('s2_ep04_m3', ['Fit the pieces of the torn label together', 'Read where the box was sent']),
  's2_ep04_final': levelObjective('s2_ep04_final', ['Which address fits both clues?', 'CLUE 2: No. 7']),
};

final masterLearning04 = <String, LearningObjective>{
  's2_ep04_m1': levelObjective('s2_ep04_m1', ['Follow the arrow towards the river.', 'Find the one who watches the water.', 'Which mark satisfies all three lines?']),
  's2_ep04_m2': levelObjective('s2_ep04_m2', ['Where has the crate ended up?', 'Trace that crate through the later lines of the page']),
  's2_ep04_m3': levelObjective('s2_ep04_m3', ['Piece the torn label back together', 'discover where it was being sent']),
  's2_ep04_final': levelObjective('s2_ep04_final', ['Only one address fits both', 'CLUE 2: No. 7']),
};
