import '../../models/easy_steps.dart';
import '../../models/learning.dart';
import '../../models/letter_puzzles.dart';
import '../../models/river_puzzles.dart';
import '../../models/workshop_puzzles.dart';
import 'season2_case04_scenes.dart';
import 'season2_case05_scenes.dart';
import 'season2_case06_scenes.dart';
import 'season2_learning.dart';

/// Season 2, Cases 04–06 at each level (PART 7B): the words only
/// (`docs/difficulty_reviews/PARIS_CASE_04_06.md`).
///
/// Rookie: the game's own words, reviewed; two lines made plainer (Case 05
/// M1's crate, M3's evidence), and the words a child may not know added to
/// the glossary.
///
/// At every level the same: the papers each puzzle is read from (the
/// plaque's back, the marks' words, the ledger, the label and its scrap, the
/// street book, the note and the repair card, the receipt, the slips, the
/// tags, the porter's note, the drawers, the letter and its back), the lines
/// the story bible gives as they are ("Wait! It wasn't stolen.", "Someone
/// kept it safe.", "We found our next clue!", the cases' end questions of
/// Cases 05 and 06), every answer, id and order, and every way to play
/// (Tap…, Turn…, Drag…).
///
/// Kept untold at every level: who the Clockmaker is; whose the two clock
/// hands are; what the clock parts were for; that the letter was really in
/// Clock III, or who took it out; what the letter says before it is found,
/// who wrote it, who held it and why; where the letter leads before the
/// drawing is placed.

// ═════════════════════════════════════════════════════════════════════════
// The glossary
// ═════════════════════════════════════════════════════════════════════════

/// Words of the game's own pages a child may not know, on every level's
/// pages; and those on some levels' pages only.
const words04 = {'stone': '돌', 'wooden': '나무로 된', 'shelf': '선반', 'somewhere': '어딘가에'};
const _burning = {'burning': '타고 있는, 켜져 있는'};
const _rookieOnly04 = {..._burning, 'caught': '걸린, 끼인', 'lists': '목록에 싣다'};

const words05 = {'workshop': '작업장, 공방', 'shape': '모양', 'colour': '색깔', 'arrived': '도착했다', 'bench': '작업대'};
const _backward = {'backward': '거꾸로 가는'};
const _nobodyCovered = {'nobody': '아무도 ~않다', 'covered': '덮인'};

const words06 = {'building': '건물', 'hundreds': '수백 개', 'domes': '둥근 지붕들', 'secret': '비밀', 'continues': '계속된다'};
const _churchSlowlyBetween = {'church': '교회', 'slowly': '천천히', 'between': '~사이에'};

/// Rookie's glossary for each case.
const rookieWords04 = {...words04, ..._rookieOnly04};
const rookieWords06 = {...words06, ..._churchSlowlyBetween};

/// Junior's own words, found on Junior's pages (Master's too, unless
/// Master says it its own way).
const juniorWords04 = {'matches': '일치하다, 맞다', 'mention': '언급하다', 'stuck': '끼인, 걸린', 'reminds': '다시 알려 주다'};
const juniorWords05 = {'reads': '(글이) ~라고 쓰여 있다', 'pile': '더미'};
const juniorWords06 = {'belongs': '~의 것이다', 'stored': '보관된', 'covers': '덮다, 가리다'};

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
const masterWords05 = {
  'identical': '똑같은',
  'altered': '바꿨다, 고쳤다',
  'decipher': '해독하다, 알아보다',
  'deciphered': '해독한',
  'gleaming': '반짝이는',
  'snapped': '부러졌다',
  'stained': '얼룩진',
  'carries': '지니고 있다',
};
const masterWords06 = {
  'hushed': '조용한',
  'dangle': '매달려 있다',
  'range': '범위',
  'recovered': '되찾은',
  'refuse': '~하려 하지 않다',
  'uncover': '밝혀내다',
  'trace': '따라가 찾다',
};

// ═════════════════════════════════════════════════════════════════════════
// Rookie: two lines made plainer
// ═════════════════════════════════════════════════════════════════════════

/// Case 05 at Rookie: "just like in Box 23" said plainly (the crate is
/// only like the one from Box 23: nothing says it is the same); "What it
/// named was inside Clock III" said as what the note did.
const rookie05 = <String, Object?>{
  'glossary': {...words05, ..._backward, ..._nobodyCovered},
  'missions': {
    's2_ep05_m1': {
      'story': [
        'Behind the workbench is an empty crate. It looks like the crate from Box 23.',
        'Four things on the bench are stamped with two clock hands.',
        'They look the same. Are they?',
      ],
    },
    's2_ep05_m3': {
      'evidence': {'description': 'You read it in the hand mirror. It named Clock III.'},
    },
  },
};

// ═════════════════════════════════════════════════════════════════════════
// Case 04 — The River's Secret
// ═════════════════════════════════════════════════════════════════════════

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
// Case 05 — The Silent Workshop
// ═════════════════════════════════════════════════════════════════════════

/// The note on the workbench and the repair card, as written (their own
/// words are the puzzles').
const _workbenchNote = 'My mark is on everything I make.\nA copy is never the same.';
const _repairCard = 'I changed one clock.\nI added one small wheel.\nNow its hands turn the wrong way.';

/// The receipt from Clock III, as printed.
const _receipt = '16 MAY — ONE LETTER COLLECTED FROM No. 7.\nLETTER No. 4417.\n\n';

/// Case 04's last words, read at No. 7's gate (the label's back).
const _labelBack = 'Do not trust the clocks. Follow the hands that made them.';

final junior05 = <String, Object?>{
  'synopsis': [
    'The torn label brought you to No. 7, Passage des Horlogers.',
    'Inside, the clocks are moving, but nobody is there.',
    'The clock parts from the tower came here. But why?',
  ],
  'objectives': [
    'Find the mark the maker really made.',
    'Find out which clock the maker changed.',
    'Read the backwards notes on the writing desk.',
  ],
  'intro': [
    _labelBack,
    'The gate is not locked. Behind it is a door marked No. 7.',
    'Inside, the walls are covered with clocks.',
    'Their hands are moving, but the room is silent.',
    'Someone was working here, and not long ago.',
  ],
  'caseSummary': 'A mark, a clock that turns backwards and a mirror led you to letter No. 4417. It never arrived.',
  'hook': _hook05,
  'glossary': {...words05, ..._nobodyCovered, ...juniorWords05},
  'missions': {
    's2_ep05_m1': {
      'story': [
        'Behind the workbench stands an empty crate, like the one from Box 23.',
        'Four things on the bench have a stamp of two clock hands.',
        'They all look the same. But are they?',
      ],
      'letterIntro': 'There is a note on the workbench:',
      'letter': _workbenchNote,
      'question': "Which thing has the maker's real mark?",
      'hints': [
        'Put the tracing sheet over each stamp in turn. Compare the lines, not the colour.',
        'For each stamp, count the hands, check where the short hand is and look at each tip.',
      ],
      'successMessage': "That is the maker's real mark!",
      'transition': [
        "Only the small drawer has the maker's real mark.",
        'Inside the drawer is a repair card. It says:',
        'I changed one clock. I added one small wheel.',
        'Now its hands turn the wrong way.',
        'On the wall, four clocks are hanging in a row.',
      ],
      'options': {
        'a': {'feedback': 'Compare the tip of the long hand. Does it have the same shape?'},
        'b': {'feedback': 'Put the sheet over it. Is the short hand in the same place?'},
        'c': {'feedback': "How many hands can you count? The maker's mark has two."},
      },
      'clue': {'note': "Inside the small drawer: a repair card, signed with the maker's real mark."},
      'evidence': {'description': 'It was found in the small drawer of the workbench.'},
    },
    's2_ep05_m2': {
      'story': ['Four silent clocks are hanging in a row on the wall.', 'Every clock shows a different time.'],
      'letterIntro': 'You read the repair card again:',
      'letter': _repairCard,
      'question': 'Which clock was changed by the maker?',
      'hints': [
        'Watch all four clocks for one minute. Read each time, before and after.',
        'The right clock has two things: an added wheel, and hands that turn the wrong way.',
      ],
      'successMessage': 'You found the clock that goes backwards!',
      'transition': [
        'Clock III moved back, from 10:40 to 10:39.',
        'At its back, there is one small brass wheel that does not belong.',
        'By the window stands a writing desk covered in ink.',
      ],
      'options': {
        'i': {'feedback': 'Clock I moved from 3:10 to 3:11. It turns the right way.'},
        'ii': {'feedback': 'Clock II is running fast, but it still turns the right way.'},
        'iv': {'feedback': 'Clock IV has stopped. It is not turning the wrong way.'},
      },
      'clue': {'note': 'Clock III turns backwards. At its back: one small brass wheel that does not belong.'},
      'evidence': {'description': 'The third clock in the row on the workshop wall.'},
    },
    's2_ep05_m3': {
      'story': ['Ink has dried on the blotting paper, and the words are backwards.', 'There is a small hand mirror next to it.'],
      'letterIntro': 'In your notebook, you wrote:',
      'letter':
          'The note is written backwards.\n'
          'Use the mirror to read it.\n'
          'Which clock does it name?',
      'question': 'Which clock does the note name?',
      'hints': ['The note is written backwards. A mirror can turn it round.', 'In the mirror, the note says: the clock that turns back.'],
      'successMessage': 'You found the clock the note named!',
      'transition': [
        'There is no letter inside Clock III.',
        'There is only a torn envelope corner and a small receipt.',
        '16 MAY — ONE LETTER COLLECTED FROM No. 7.',
        "The maker's note says the letter was hidden in this clock.",
        'But it is not here now. Did someone take it out?',
        'Under the door, a pile of post slips has built up.',
      ],
      'clue': {'note': 'No letter inside Clock III, only a receipt: 16 MAY — ONE LETTER COLLECTED FROM No. 7. LETTER No. 4417.'},
      'evidence': {'description': 'You read it with the hand mirror. The note pointed to Clock III.'},
    },
    's2_ep05_final': {
      'story': ['Every time a letter moves, the post leaves a slip.', 'The passage has a post box, right outside No. 7.'],
      'letterIntro': 'The receipt from Clock III reads:',
      'letter': '${_receipt}Which slip is for this letter?',
      'question': 'Which slip is for letter 4417?',
      'hints': ['Read the numbers one by one: 4, 4, 1, 7.', 'Be careful: 4417 and 4471 look alike.'],
      'successMessage': "You followed the letter's trail!",
      'transition': [
        'On 16 May, Letter No. 4417 left No. 7.',
        'First it was collected, then it was sorted.',
        'After that, it stopped: HELD at the Louvre post room.',
        'It was never delivered to anyone.',
        'Who stopped it, and why?',
      ],
      'evidence': {'description': 'Three post slips found under the workshop door.'},
    },
  },
};

final master05 = <String, Object?>{
  'synopsis': [
    'The torn label has led you to No. 7, Passage des Horlogers.',
    'Inside, every clock is moving, yet the workshop is empty.',
    'The clock parts from the tower ended up here. Why?',
  ],
  'objectives': [
    "Tell the maker's true mark from its copies.",
    'Discover which clock the maker altered.',
    'Decipher the backwards notes on the desk.',
  ],
  'intro': [
    _labelBack,
    'The gate swings open. Beyond it, a door is marked No. 7.',
    'Inside, clocks crowd every wall.',
    'Their hands keep moving, yet the room is utterly silent.',
    'Someone worked here, and not very long ago.',
  ],
  'caseSummary': "A maker's mark, a backward clock and a mirror led you to letter No. 4417, a letter that never arrived.",
  'hook': _hook05,
  'glossary': {...words05, ..._backward, ...masterWords05},
  'missions': {
    's2_ep05_m1': {
      'story': [
        'An empty crate stands behind the workbench, much like the one from Box 23.',
        'Four objects on the bench each bear a stamp of two clock hands.',
        'At first glance they look identical. Are they?',
      ],
      'letterIntro': 'A note lies on the workbench:',
      'letter': _workbenchNote,
      'question': "Which object carries the maker's true mark?",
      'hints': [
        'The tracing sheet holds the true mark. Colour can fool you; the lines cannot.',
        'A copy gives itself away in small things: a missing hand, a hand out of place, a different tip.',
      ],
      'successMessage': "The maker's true mark stands out!",
      'transition': [
        "Of the four, only the small drawer bears the maker's true mark.",
        'Inside lies a repair card:',
        'I changed one clock. I added one small wheel.',
        'Now its hands turn the wrong way.',
        'Across the room, four clocks hang side by side on the wall.',
      ],
      'options': {
        'a': {'feedback': 'Study the tip of the long hand. Is its shape quite right?'},
        'b': {'feedback': 'With the sheet laid over it, does the short hand line up?'},
        'c': {'feedback': "Count again. The maker's mark always has two hands."},
      },
      'clue': {'note': "Tucked in the small drawer: a repair card bearing the maker's true mark."},
      'evidence': {'description': 'Discovered in the small drawer of the workbench.'},
    },
    's2_ep05_m2': {
      'story': ['Four silent clocks hang side by side on the wall.', 'No two of them agree on the time.'],
      'letterIntro': 'The repair card reads:',
      'letter': _repairCard,
      'question': 'Which clock has the maker altered?',
      'hints': [
        'A minute will tell you which way each clock turns. Compare the times before and after.',
        'The card describes two changes. Only one clock shows both.',
      ],
      'successMessage': 'There it is: the clock that turns back!',
      'transition': [
        'Clock III slipped backwards, from 10:40 to 10:39.',
        'Behind it sits one small brass wheel that does not belong.',
        'By the window, a writing desk lies stained with ink.',
      ],
      'options': {
        'i': {'feedback': 'Clock I crept from 3:10 to 3:11: forward, as a clock should.'},
        'ii': {'feedback': 'Clock II may race ahead, but its hands still turn the right way.'},
        'iv': {'feedback': 'Clock IV has not moved at all, so it cannot be turning the wrong way.'},
      },
      'clue': {'note': 'Clock III runs backwards. Hidden behind it: one small brass wheel that does not belong.'},
      'evidence': {'description': 'Third in the row of clocks on the workshop wall.'},
    },
    's2_ep05_m3': {
      'story': ['Dried ink has left words on the blotting paper, all of them backwards.', 'Beside it rests a small hand mirror.'],
      'letterIntro': 'Your notebook reminds you:',
      'letter':
          'The writing runs backwards.\n'
          'Let the mirror turn it round.\n'
          'Which clock does it point to?',
      'question': 'Which clock does the note point to?',
      'hints': ['Backwards writing becomes clear in a mirror.', 'The mirror names a clock by what it does, not by its number.'],
      'successMessage': 'You found the hiding place the note described!',
      'transition': [
        'Clock III holds no letter.',
        'Just a torn envelope corner and a small receipt.',
        '16 MAY — ONE LETTER COLLECTED FROM No. 7.',
        "According to the maker's note, the letter was hidden here.",
        'Yet it is no longer here. Did someone take it out?',
        'Beneath the door, post slips have piled up.',
      ],
      'clue': {'note': 'Clock III held no letter, only a receipt: 16 MAY — ONE LETTER COLLECTED FROM No. 7. LETTER No. 4417.'},
      'evidence': {'description': 'Deciphered in the hand mirror, it pointed to Clock III.'},
    },
    's2_ep05_final': {
      'story': ['Each time a letter changes hands, the post leaves a slip behind.', 'The passage post box stands just outside No. 7.'],
      'letterIntro': 'The receipt you found in Clock III:',
      'letter': '${_receipt}Find the slip that belongs to it.',
      'question': 'Pick out the slip for letter 4417.',
      'hints': ['Read every digit in order. One wrong digit makes another letter.', 'Two numbers use the same digits. Only one has them in the right order.'],
      'successMessage': "The letter's trail is clear now!",
      'transition': [
        'Letter No. 4417 left No. 7 on the morning of 16 May.',
        'It was collected, then sorted.',
        'Then, at 4:00 PM, it went no further: HELD at the Louvre post room.',
        'It never reached its address.',
        'Who held it back, and why?',
      ],
      'evidence': {'description': 'Three post slips gathered from under the workshop door.'},
    },
  },
};

// ═════════════════════════════════════════════════════════════════════════
// Case 06 — The Letter That Never Arrived
// ═════════════════════════════════════════════════════════════════════════

/// The Letter's Trail, as the slip has it.
const _trailLines = 'LETTER No. 4417\n16 MAY · 4:00 PM\nHELD · LOUVRE POST ROOM';

/// The porter's note, as pinned (the story bible's words; the route is
/// read from it).
const _porterNote =
    'Letters to keep safe go downstairs.\n'
    'Go down the stairs.\n'
    'Walk past the statue.\n'
    'Take the second door on the left.';

/// The post room book's two lines.
const _bookLines = ['16 MAY · 4:00 PM · HELD.', '17 MAY · MORNING · MOVED.'];

/// The story bible's own lines (Case 06, v1.4), the same at every level.
const _notStolen = "Wait! It wasn't stolen.";
const _nextClue = 'We found our next clue!';
const _hook06 = 'What is in File 3–4 of the opera archive?';
const _hook05 = 'Who held the letter at the Louvre post room?';

/// The letter, as written (its two lines are the clue).
const _letterLines = 'The clocks may lie.\nBut the show remembers.';

final junior06 = <String, Object?>{
  'synopsis': [
    'Letter No. 4417 was stopped and held at the Louvre post room.',
    'But now it is not there. Was it stolen, or is it hidden?',
    'And what can it tell us about the missing hour?',
  ],
  'objectives': [
    'Find the tag for Letter 4417.',
    'Follow the path the letter took through the building.',
    'Find the letter and read what it says.',
  ],
  'intro': [
    'Letter No. 4417 stopped here, at the Louvre post room.',
    'It never reached its address.',
    'The post room is quiet, and nobody is at the desk.',
    'Letter 4417 should be somewhere here.',
  ],
  'caseSummary': 'Letter 4417 was not stolen. It was kept safe, and its back points to the opera archive.',
  'hook': _hook06,
  'glossary': {...words06, ..._churchSlowlyBetween, ...juniorWords06},
  'missions': {
    's2_ep06_m1': {
      'story': ['Behind the desk stands a wooden rack, and one of its slots is empty.', 'Four paper tags hang from it. Every tag has two sides.'],
      'letterIntro': "Your notebook has the Letter's Trail:",
      'letter': _trailLines,
      'question': 'Which tag belongs to Letter 4417?',
      'successMessage': _notStolen,
      'hints': [
        'Read the front of each tag first. Does it say LETTER? Is the number 4417?',
        'On two tags, ink covers part of the number. Turn those over and compare the day and time.',
      ],
      'transition': ['Tag D reads PRESERVATION ORDER: keep it safe.', 'Someone kept it safe.', 'So where is the letter now?'],
      'options': {
        'a': {'feedback': 'Check the first word. Does it say LETTER or PARCEL?'},
        'b': {'feedback': 'Read the number again, slowly. Does it say 4417?'},
        'c': {'feedback': 'Turn the tag over. Do the day and the time match?'},
      },
      'clue': {'note': 'It was held on 16 MAY at 4:00 PM. PRESERVATION ORDER: keep it safe.'},
      'evidence': {'description': 'It was hanging on the hold rack in the Louvre post room.'},
    },
    's2_ep06_m2': {
      'story': ['In the post room book, there are two lines for Letter 4417.', ..._bookLines, 'On the wall hangs a plan of the building.'],
      'letterIntro': "Someone has pinned a porter's note to the plan:",
      'letter': _porterNote,
      'question': 'Through which door was the letter taken?',
      'hints': [
        'Follow the note line by line. Go down the stairs, then walk past the statue.',
        'Once you are past the statue, count the doors on the left only.',
      ],
      'successMessage': 'The letter was taken to the archive!',
      'transition': ['The archive is behind Door E.', 'There are tall cabinets with hundreds of small drawers.', 'Letter 4417 must be somewhere in here.'],
      'options': {
        'a': {'feedback': 'Too early. You have not walked past the statue yet.'},
        'b': {'feedback': 'Too early. You have not walked past the statue yet.'},
        'c': {'feedback': 'That is only the first door on the left. Keep counting.'},
        'd': {'feedback': 'That door is on the right side. Which side is the left?'},
        'f': {'feedback': 'That door is on the right side. Which side is the left?'},
      },
      'clue': {'note': 'Down the stairs, past the statue, then the second door on the left. It is the archive.'},
      'evidence': {'description': 'It was pinned to the plan of the building in the post room.'},
    },
    's2_ep06_m3': {
      'story': ['Torn letters are stored here, and each drawer has a label.', 'Many of these torn letters have lost their numbers.'],
      'letterIntro': 'The torn envelope corner from Clock III has a label:',
      'letter': 'No. 4417\n\nWhich envelope was it torn from?',
      'question': 'Which envelope is the one for Letter 4417?',
      'hints': [
        'First find the right drawer. It must be for letters, and 4417 must be between its two numbers.',
        'Try the torn corner on each envelope. Only one torn edge fits it.',
      ],
      'successMessage': 'You found it! Letter 4417!',
      'transition': ['The corner fits perfectly. This is Letter 4417.', 'But what is this little picture on the seal?', 'There is a letter inside the envelope.'],
      'options': {
        'x': {'feedback': 'These torn edges do not fit together.'},
        'z': {'feedback': 'Look closely at the torn edge. Does the corner fit it?'},
      },
      'clue': {'note': 'The torn corner from Clock III fits only one envelope. On its seal is a tiny picture of a building.'},
      'evidence': {'description': 'It was in one of the archive drawers.'},
    },
    's2_ep06_final': {
      'story': ['The letter has two lines, and a drawing of the building from the seal.', 'On the wall hangs a map of Paris.'],
      'letterIntro': 'The letter reads:',
      'letter': _letterLines,
      'question': 'Which building does the drawing show?',
      'successMessage': _nextClue,
      'hints': [
        'Look carefully at the roof in the drawing. What shape is it, and what stands on top?',
        'The letter says "the show remembers". Which building is a place for shows?',
      ],
      'transition': [
        'The drawing shows the Palais Garnier, the opera house.',
        'On the back: OPERA ARCHIVE · FILE 3–4.',
        'The mystery continues at the opera house!',
      ],
      'options': {
        'montmartre': {'feedback': 'Its church does have domes, but there are no statues on its roof.'},
        'louvre': {'feedback': 'We are already at the Louvre. Look again at the roof in the drawing.'},
        'arcDeTriomphe': {'feedback': 'That is a huge arch, but the drawing shows a dome.'},
        'gareDuNord': {'feedback': 'That is a train station. People go there for trains, not shows!'},
        'notreDame': {'feedback': 'It has two tall towers, but the drawing has a dome.'},
        'eiffelTower': {'feedback': 'The tower has no dome and no statues at all.'},
      },
      'evidence': {'description': 'This is Letter No. 4417. It was found in the archive.'},
    },
  },
};

final master06 = <String, Object?>{
  'synopsis': [
    'Letter No. 4417 was held back at the Louvre post room.',
    'Now it is nowhere to be seen. Was it stolen, or hidden away?',
    'And what might it reveal about the missing hour?',
  ],
  'objectives': [
    'Track down the tag for Letter 4417.',
    "Trace the letter's route through the building.",
    'Find the letter and uncover its secret.',
  ],
  'intro': [
    'Letter No. 4417 went no further than the Louvre post room.',
    'Its journey ended here, undelivered.',
    'The post room is hushed. No one sits at the desk.',
    'Somewhere in this room, Letter 4417 should be waiting.',
  ],
  'caseSummary': 'Letter 4417 was never stolen, only kept safe, and its back points the way to the opera archive.',
  'hook': _hook06,
  'glossary': {...words06, ...masterWords06},
  'missions': {
    's2_ep06_m1': {
      'story': ['Behind the desk rises a wooden rack. One of its slots sits empty.', 'Four paper tags dangle from it, each with a front and a back.'],
      'letterIntro': "The Letter's Trail, copied in your notebook:",
      'letter': _trailLines,
      'question': 'Which of the tags is the one for Letter 4417?',
      'successMessage': _notStolen,
      'hints': [
        'Begin with what each front says: the kind of post, and the number.',
        'Where ink hides a digit, the back must decide. Compare it with your notebook.',
      ],
      'transition': ['The back of Tag D reads: PRESERVATION ORDER: keep it safe.', 'Someone kept it safe.', 'But where has it gone since?'],
      'options': {
        'a': {'feedback': 'Mind the first word: a LETTER is not a PARCEL.'},
        'b': {'feedback': 'Read the digits one by one. Is that really 4417?'},
        'c': {'feedback': 'The front cannot tell you enough. What do the day and time on the back say?'},
      },
      'clue': {'note': 'Held on 16 MAY at 4:00 PM, under a PRESERVATION ORDER: keep it safe.'},
      'evidence': {'description': 'Taken from the hold rack of the Louvre post room.'},
    },
    's2_ep06_m2': {
      'story': ['The post room book records two entries for Letter 4417.', ..._bookLines, 'A plan of the whole building hangs on the wall.'],
      'letterIntro': 'Pinned to the plan is a note from a porter:',
      'letter': _porterNote,
      'question': 'Which door did the letter pass through?',
      'hints': ['Let the note lead you, one line at a time.', 'Past the statue, ignore the doors on the right. Count along the left.'],
      'successMessage': 'The letter was moved down to the archive!',
      'transition': ['Door E opens onto the archive.', 'Tall cabinets rise to the ceiling, with hundreds of small drawers.', 'Letter 4417 must be among them.'],
      'options': {
        'a': {'feedback': 'Too soon. The note says to pass the statue first.'},
        'b': {'feedback': 'Too soon. The note says to pass the statue first.'},
        'c': {'feedback': 'The first door on the left. The note asks for another.'},
        'd': {'feedback': 'That door lies on the right. The note says left.'},
        'f': {'feedback': 'That door lies on the right. The note says left.'},
      },
      'clue': {'note': 'Down the stairs, past the statue, through the second door on the left: the archive.'},
      'evidence': {'description': 'Found pinned to the building plan in the post room.'},
    },
    's2_ep06_m3': {
      'story': ['This is where torn letters are kept, each drawer marked with a label.', 'Many of them have lost their numbers along the way.'],
      'letterIntro': 'The torn envelope corner you found in Clock III reads:',
      'letter': 'No. 4417\n\nFind the envelope this corner was torn from.',
      'question': 'Which envelope belongs to Letter 4417?',
      'hints': ['The drawer comes first: the right kind of post, and a range that includes 4417.', 'Only one torn edge will meet the corner exactly.'],
      'successMessage': 'At last, Letter 4417!',
      'transition': ['The corner fits exactly. This is Letter 4417.', 'But what is the tiny picture pressed into the seal?', 'Inside the envelope, a letter is waiting.'],
      'options': {
        'x': {'feedback': 'The torn edges refuse to line up.'},
        'z': {'feedback': 'Study the torn edge. Would the corner fit it exactly?'},
      },
      'clue': {'note': 'Only one envelope matches the torn corner from Clock III. Its seal shows a tiny building.'},
      'evidence': {'description': 'Recovered from a drawer in the archive.'},
    },
    's2_ep06_final': {
      'story': ['Two short lines, and a drawing of the very building on the seal.', 'A map of Paris hangs on the archive wall.'],
      'letterIntro': 'The letter holds just two lines:',
      'letter': _letterLines,
      'question': 'Which building has been drawn on the letter?',
      'successMessage': _nextClue,
      'hints': ['The roof is the key: its shape, and what stands upon it.', 'Think about "the show remembers". Where would a show be remembered?'],
      'transition': [
        "The building in the drawing is the Palais Garnier, the city's grand opera house.",
        'On the back: OPERA ARCHIVE · FILE 3–4.',
        'The mystery continues at the opera house!',
      ],
      'options': {
        'montmartre': {'feedback': 'Domes, yes, but not a single statue on its roof.'},
        'louvre': {'feedback': 'We are already at the Louvre. Compare its roof with the drawing.'},
        'arcDeTriomphe': {'feedback': 'An arch, however grand, is not a dome.'},
        'gareDuNord': {'feedback': 'A railway station: trains, not shows!'},
        'notreDame': {'feedback': 'Two tall towers rise from it. The drawing shows a dome.'},
        'eiffelTower': {'feedback': 'An iron tower, with neither a dome nor statues.'},
      },
      'evidence': {'description': 'Letter No. 4417, recovered at last from the archive.'},
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

/// The wall of clocks: what is seen at each clock's back. The times, how
/// each clock turns and every way to play are the base's.
ClockWallScene _clocks(ClockWallScene base, Map<String, String> backNotes) => ClockWallScene(
      wall: base.wall,
      pixels: base.pixels,
      place: base.place,
      view: base.view,
      clocks: [
        for (final c in base.clocks)
          WallClock(
            id: c.id,
            numeral: c.numeral,
            centre: c.centre,
            radius: c.radius,
            area: c.area,
            plateAt: c.plateAt,
            shows: c.shows,
            change: c.change,
            back: c.back,
            backLabel: c.backLabel,
            backNote: backNotes[c.id]!,
          ),
      ],
      backPixels: base.backPixels,
      watch: base.watch,
      watchLabel: base.watchLabel,
      againLabel: base.againLabel,
      later: base.later,
      watchTask: base.watchTask,
      backTask: base.backTask,
      chooseTask: base.chooseTask,
      chooseLabel: base.chooseLabel,
    );

/// The archive: what a wrong drawer or envelope says, and the seal's line.
/// The drawers, the envelopes and every way to play are the base's.
ArchiveScene _archive(ArchiveScene base, {required String notHere, required String notLetters, required String notFit, required String sealLine}) =>
    ArchiveScene(
      drawers: base.drawers,
      cabinet: base.cabinet,
      cabinetPixels: base.cabinetPixels,
      cabinetView: base.cabinetView,
      cabinetDrawers: base.cabinetDrawers,
      drawer: base.drawer,
      drawerPixels: base.drawerPixels,
      drawerView: base.drawerView,
      felt: base.felt,
      envelopes: base.envelopes,
      envelopePixels: base.envelopePixels,
      corner: base.corner,
      cornerPiece: base.cornerPiece,
      cornerTagAt: base.cornerTagAt,
      numberTag: base.numberTag,
      seal: base.seal,
      sealPixels: base.sealPixels,
      sealAt: base.sealAt,
      cabinetTask: base.cabinetTask,
      drawerTask: base.drawerTask,
      layTask: base.layTask,
      layLabel: base.layLabel,
      notHere: notHere,
      notLetters: notLetters,
      notFit: notFit,
      sealLabel: base.sealLabel,
      sealLine: sealLine,
    );

/// A step's words at a level: null keeps the base's (a way to play, or a
/// paper's words read out).
typedef StepWords = ({String? say, List<String> hints, Map<String, String> feedback, String? tell, String? done});

/// [base]'s steps told in a level's words (also Cases 07–12's) ([words], by step id). What each
/// step shows, its choices, its answer and how many free hints lead to it
/// are the base's.
EasyStepsScene retold(EasyStepsScene base, Map<String, StepWords> words) => EasyStepsScene(
      title: base.title,
      answer: base.answer,
      finishLabel: base.finishLabel,
      seen: base.seen,
      steps: [
        for (final s in base.steps)
          if (words[s.id] case final w?)
            EasyStep(
              id: s.id,
              say: w.say ?? s.say,
              panels: s.panels,
              does: s.does,
              button: s.button,
              target: s.target,
              lit: s.lit,
              question: s.question,
              options: [
                for (final o in s.options) EasyOption(id: o.id, label: o.label, panel: o.panel, area: o.area, feedback: o.feedback == null ? null : w.feedback[o.id]!),
              ],
              answer: s.answer,
              hints: w.hints,
              lookHere: s.lookHere,
              wrong: s.wrong,
              tell: s.tell == null ? null : w.tell!,
              done: w.done ?? s.done,
              after: s.after,
              doneButton: s.doneButton,
            )
          else
            s,
      ],
    );

/// Cases 04–06's scenes with Junior's words.
final juniorScenes0406 = (
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
  clockWalls: {
    's2_ep05_m2': _clocks(season2ClockWalls['s2_ep05_m2']!, const {
      'i': 'Only brass gears and two weights.',
      'ii': 'There is a big, shiny spring.',
      'iii': 'There is a small brass wheel beside the gears.',
      'iv': 'The hook for the pendulum is broken.',
    }),
  },
  archives: {
    's2_ep06_m3': _archive(
      season2ArchiveScenes['s2_ep06_m3']!,
      notHere: '{label}. Does 4417 fall between these two numbers?',
      notLetters: '{label}. This drawer is only for parcels.',
      notFit: 'These torn edges do not fit together.',
      sealLine: 'A tiny picture of a big, grand building.',
    ),
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
    's2_ep05_m3': retold(season2Case05Steps['s2_ep05_m3']!, const {
      'mirror': (
        say: null,
        hints: ['The note is written backwards. A mirror can turn it round.', 'Tap the hand mirror.'],
        feedback: {},
        tell: null,
        done: null,
      ),
      'clock': (
        say: 'Which clock does the note name?',
        hints: ['In the mirror, the note says: the clock that turns back.', 'Read the words under each clock. Find "turns back".'],
        feedback: {'ii': 'Clock II only runs fast. Which clock turns back?'},
        tell: 'Clock III is the one that turns back.',
        done: 'Clock III! There is no letter inside, only a receipt.',
      ),
    }),
    's2_ep05_final': retold(season2Case05Steps['s2_ep05_final']!, const {
      'letter': (
        say: 'Which slip is for letter 4417?',
        hints: ['Read the numbers one by one: 4, 4, 1, 7.', 'Be careful: 4417 and 4471 look alike.'],
        feedback: {'4471': 'This slip says 4471. Look again for 4417.'},
        tell: 'This is the one. Its slip says 4417.',
        done: 'Letter 4417! Now you can see where it went.',
      ),
    }),
  },
);

/// Cases 04–06's scenes with Master's words.
final masterScenes0406 = (
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
  clockWalls: {
    's2_ep05_m2': _clocks(season2ClockWalls['s2_ep05_m2']!, const {
      'i': 'Ordinary brass gears and two weights.',
      'ii': 'A large, gleaming spring.',
      'iii': 'A small brass wheel tucked beside the gears.',
      'iv': 'The pendulum hook has snapped.',
    }),
  },
  archives: {
    's2_ep06_m3': _archive(
      season2ArchiveScenes['s2_ep06_m3']!,
      notHere: '{label}. Is 4417 inside this range?',
      notLetters: '{label}. Parcels only: not the drawer you need.',
      notFit: 'The torn edges refuse to line up.',
      sealLine: 'A tiny drawing of a grand building, pressed into the wax.',
    ),
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
    's2_ep05_m3': retold(season2Case05Steps['s2_ep05_m3']!, const {
      'mirror': (
        say: null,
        hints: ['Backwards writing becomes clear in a mirror.', 'Tap the hand mirror.'],
        feedback: {},
        tell: null,
        done: null,
      ),
      'clock': (
        say: 'Which clock does the note point to?',
        hints: ['The mirror names a clock by what it does, not by its number.', 'Under each clock are a few words. Which match the mirror?'],
        feedback: {'ii': 'Clock II runs fast, but it never turns back. Look again.'},
        tell: 'It is Clock III: the clock that turns back.',
        done: 'Clock III! But no letter waits inside, only a receipt.',
      ),
    }),
    's2_ep05_final': retold(season2Case05Steps['s2_ep05_final']!, const {
      'letter': (
        say: 'Pick out the slip for letter 4417.',
        hints: ['Read every digit in order. One wrong digit makes another letter.', 'Two numbers use the same digits. Only one has them in the right order.'],
        feedback: {'4471': 'This one reads 4471: the right digits, in the wrong order.'},
        tell: 'Here: this slip reads 4417.',
        done: 'Letter 4417! Here is the path it took.',
      ),
    }),
  },
);

/// The scenes of Cases 04–06 whose words are the same at every level: only
/// ways to play and the papers their puzzles are read from (the street book
/// and the gate, the note and the repair card, the slips, the tags, the
/// porter's plan, the letter and the map's names), and what screen readers
/// say of the pictures.
const sameAtEveryLevel0406 = {
  'streetBooks/s2_ep04_final',
  'markCompares/s2_ep05_m1',
  'postTrails/s2_ep05_final',
  'holdRacks/s2_ep06_m1',
  'planRoutes/s2_ep06_m2',
  'letterMaps/s2_ep06_final',
};

// ═════════════════════════════════════════════════════════════════════════
// The learning design: each level's own English, on its own pages
// ═════════════════════════════════════════════════════════════════════════

LearningObjective _learn(String id, List<String> expressions) {
  final base = season2Learning[id]!;
  return LearningObjective(
    dependency: base.dependency,
    level: base.level,
    skill: base.skill,
    recallFrom: base.recallFrom,
    objective: base.objective,
    expressions: expressions,
  );
}

final juniorLearning0406 = <String, LearningObjective>{
  's2_ep04_m1': _learn('s2_ep04_m1', ['Follow the arrow towards the river.', 'Find the one who watches the water.', 'Which mark matches all three lines?']),
  's2_ep04_m2': _learn('s2_ep04_m2', ['was sent to the river', "Which box holds the tower's crate now?"]),
  's2_ep04_m3': _learn('s2_ep04_m3', ['Fit the pieces of the torn label together', 'Read where the box was sent']),
  's2_ep04_final': _learn('s2_ep04_final', ['Which address fits both clues?', 'CLUE 2: No. 7']),
  's2_ep05_m1': _learn('s2_ep05_m1', ['A copy is never the same.', "Which thing has the maker's real mark?"]),
  's2_ep05_m2': _learn('s2_ep05_m2', ['I added one small wheel.', 'Now its hands turn the wrong way.', 'Which clock was changed by the maker?']),
  's2_ep05_m3': _learn('s2_ep05_m3', ['the clock that turns back', 'Use the mirror to read it']),
  's2_ep05_final': _learn('s2_ep05_final', ['Which slip is for letter 4417?']),
  's2_ep06_m1': _learn('s2_ep06_m1', ['LETTER No. 4417', 'Which tag belongs to Letter 4417?']),
  's2_ep06_m2': _learn('s2_ep06_m2', ['Walk past the statue.', 'Take the second door on the left.', 'count the doors on the left only']),
  's2_ep06_m3': _learn('s2_ep06_m3', ['Which envelope was it torn from?']),
  's2_ep06_final': _learn('s2_ep06_final', ['But the show remembers.', 'Which building is a place for shows?']),
};

final masterLearning0406 = <String, LearningObjective>{
  's2_ep04_m1': _learn('s2_ep04_m1', ['Follow the arrow towards the river.', 'Find the one who watches the water.', 'Which mark satisfies all three lines?']),
  's2_ep04_m2': _learn('s2_ep04_m2', ['Where has the crate ended up?', 'Trace that crate through the later lines of the page']),
  's2_ep04_m3': _learn('s2_ep04_m3', ['Piece the torn label back together', 'discover where it was being sent']),
  's2_ep04_final': _learn('s2_ep04_final', ['Only one address fits both', 'CLUE 2: No. 7']),
  's2_ep05_m1': _learn('s2_ep05_m1', ['A copy is never the same.', "Which object carries the maker's true mark?"]),
  's2_ep05_m2': _learn('s2_ep05_m2', ['I added one small wheel.', 'Now its hands turn the wrong way.', 'Which clock has the maker altered?']),
  's2_ep05_m3': _learn('s2_ep05_m3', ['Let the mirror turn it round', 'Which clock does the note point to?']),
  's2_ep05_final': _learn('s2_ep05_final', ['Pick out the slip for letter 4417']),
  's2_ep06_m1': _learn('s2_ep06_m1', ['LETTER No. 4417', 'Where ink hides a digit, the back must decide']),
  's2_ep06_m2': _learn('s2_ep06_m2', ['Walk past the statue.', 'Take the second door on the left.', 'Count along the left']),
  's2_ep06_m3': _learn('s2_ep06_m3', ['Find the envelope this corner was torn from']),
  's2_ep06_final': _learn('s2_ep06_final', ['But the show remembers.', 'Where would a show be remembered?']),
};
