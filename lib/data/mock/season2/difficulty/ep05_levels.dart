import '../../../models/learning.dart';
import '../../../models/workshop_puzzles.dart';
import '../season2_case05_scenes.dart';
import 'level_words.dart';

// Case 05 — The Silent Workshop, at each level (PART 7B): the words only
// (`docs/difficulty_reviews/PARIS_CASE_04_06.md`).
// What Cases 04–06 keep the same, and untold, at every level: ep04_levels.dart.

const words05 = {'workshop': '작업장, 공방', 'shape': '모양', 'colour': '색깔', 'arrived': '도착했다', 'bench': '작업대'};
const _backward = {'backward': '거꾸로 가는'};
const _nobodyCovered = {'nobody': '아무도 ~않다', 'covered': '덮인'};

const juniorWords05 = {'reads': '(글이) ~라고 쓰여 있다', 'pile': '더미'};

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

const _hook05 = 'Who held the letter at the Louvre post room?';

// ═════════════════════════════════════════════════════════════════════════
// The scenes' own words
// ═════════════════════════════════════════════════════════════════════════

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

/// Case 05's scenes with Junior's words.
final juniorScenes05 = (
  clockWalls: {
    's2_ep05_m2': _clocks(season2ClockWalls['s2_ep05_m2']!, const {
      'i': 'Only brass gears and two weights.',
      'ii': 'There is a big, shiny spring.',
      'iii': 'There is a small brass wheel beside the gears.',
      'iv': 'The hook for the pendulum is broken.',
    }),
  },
  easySteps: {
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

/// Case 05's scenes with Master's words.
final masterScenes05 = (
  clockWalls: {
    's2_ep05_m2': _clocks(season2ClockWalls['s2_ep05_m2']!, const {
      'i': 'Ordinary brass gears and two weights.',
      'ii': 'A large, gleaming spring.',
      'iii': 'A small brass wheel tucked beside the gears.',
      'iv': 'The pendulum hook has snapped.',
    }),
  },
  easySteps: {
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

/// Case 05's scenes whose words are the same at every level (see
/// `season2SameAtEveryLevel`).
const sameAtEveryLevel05 = {
  'markCompares/s2_ep05_m1',
  'postTrails/s2_ep05_final',
};

// ═════════════════════════════════════════════════════════════════════════
// The learning design
// ═════════════════════════════════════════════════════════════════════════

final juniorLearning05 = <String, LearningObjective>{
  's2_ep05_m1': levelObjective('s2_ep05_m1', ['A copy is never the same.', "Which thing has the maker's real mark?"]),
  's2_ep05_m2': levelObjective('s2_ep05_m2', ['I added one small wheel.', 'Now its hands turn the wrong way.', 'Which clock was changed by the maker?']),
  's2_ep05_m3': levelObjective('s2_ep05_m3', ['the clock that turns back', 'Use the mirror to read it']),
  's2_ep05_final': levelObjective('s2_ep05_final', ['Which slip is for letter 4417?']),
};

final masterLearning05 = <String, LearningObjective>{
  's2_ep05_m1': levelObjective('s2_ep05_m1', ['A copy is never the same.', "Which object carries the maker's true mark?"]),
  's2_ep05_m2': levelObjective('s2_ep05_m2', ['I added one small wheel.', 'Now its hands turn the wrong way.', 'Which clock has the maker altered?']),
  's2_ep05_m3': levelObjective('s2_ep05_m3', ['Let the mirror turn it round', 'Which clock does the note point to?']),
  's2_ep05_final': levelObjective('s2_ep05_final', ['Pick out the slip for letter 4417']),
};
