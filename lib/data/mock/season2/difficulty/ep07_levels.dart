import '../../../models/learning.dart';
import '../season2_case07_scenes.dart';
import 'level_words.dart';

// Case 07 — The Phantom Performance, at each level (PART 7C): the words only
// (`docs/difficulty_reviews/PARIS_CASE_07_09.md`).
//
// Cases 07–09:
//
// Rookie: the game's own words, reviewed; one line made plainer (Case 09
// M3's "mended"), and the words a child may not know added to the
// glossary.
//
// At every level the same: the papers each puzzle is read from (FILE 3 and
// FILE 4, the Lighting Book, the cue card, the Painted Street's line, the
// Amendment Slip and its back, the painter's sketch notes, his tag and his
// note, the evidence list of the final board, the words beside the Little
// Paris and on its gear board, the notebook's marks, the test card), the
// board's questions and conclusions, every answer, id and order, and every
// way to play (Tap…, Turn…, Drag…, Pull…).
//
// Kept untold at every level: who changed FILE 3, and why; whether the
// same hand changed the Eiffel Tower's record; whether P. painted the
// backdrop; who carried the bag, whose badge it is, what the torn paper
// changed; what the little clock was for before the garden shows it;
// whether the gear and the two hands are one person's; who the Clockmaker
// is; whether an hour was really lost; why the bag came to the garden.

const words07 = {'tonight': '오늘 밤', 'hidden': '숨겨진', 'records': '기록들', 'nightingale': '나이팅게일(밤꾀꼬리)'};
const juniorWords07 = {'caption': '사진 설명 글', 'switch': '켜다; 스위치', 'finish': '끝나다', 'explains': '설명한다'};
const masterWords07 = {
  'captioned': '설명 글이 붙은',
  'resembles': '닮았다',
  'altered': '바뀐, 고친',
  'pasted': '붙였다',
  'existed': '존재했다',
  'underneath': '그 아래에',
  'instructs': '지시한다',
};

/// Rookie's glossary for each case.
const rookieWords07 = words07;

/// FILE 3 and FILE 4, as they are in the box (the show is read from them).
const _files =
    'FILE 3 · THE GOLDEN NIGHTINGALE · PERFORMANCE No. 34\n'
    'DOORS OPEN · 3:30 PM\n'
    'CURTAIN UP · 3:00 PM\n'
    'CURTAIN DOWN · 6:10 PM\n\n'
    'FILE 4 · THE PROGRAMME\n'
    'OVERTURE · 10 MIN\n'
    'ACT ONE · 60 MIN\n'
    'INTERVAL · 20 MIN\n'
    'ACT TWO · 40 MIN\n'
    'THE WHOLE SHOW: 2 HOURS 10 MINUTES';

/// The Lighting Book, as written.
const _lightingBook =
    'GHOST LIGHT: one lamp on an empty stage.\n'
    'We use it before the doors open, and at night.\n'
    'HOUSE LIGHTS: for the audience.\n'
    'FOOTLIGHTS and BIG SPOT: for the show.';

const _painted = 'Above the red door: a small clock.';
const _slipLetter = 'FILE 3 · PERFORMANCE No. 34\nCURTAIN UP: 4:00 to 3:00';
const _slipLine = 'FILE 3 · PERFORMANCE No. 34 · CURTAIN UP: 4:00 to 3:00.';
const _cueLine = 'CUE 1 · CURTAIN UP · 4:00.';
const _turnOn = 'Turn on the ghost light.';

const rookie07 = <String, Object?>{'glossary': rookieWords07};

final junior07 = <String, Object?>{
  'synopsis': [
    'The letter said that the show remembers.',
    'In the opera archive, one show has two different start times.',
    'The times are one hour apart. Which one is true?',
  ],
  'objectives': [
    "Check the show's times.",
    'Light the stage the way it looks in the old photo.',
    'Find out what was changed, and show the proof.',
  ],
  'intro': [
    'The letter has led you to the Palais Garnier.',
    'On the back of the letter: OPERA ARCHIVE · FILE 3–4.',
    'Tonight the opera house is dark. The archive is up under the roof.',
    'On the table is a box marked FILE 3–4.',
  ],
  'caseSummary': 'The show really began at 4:00. Later, someone covered the time on FILE 3 with 3:00.',
  'hook': 'What did P. see? And what was inside the bag?',
  'glossary': {...words07, ...juniorWords07},
  'missions': {
    's2_ep07_m1': {
      'story': ['FILE 3 is the office record for one show.', 'FILE 4 is the programme for the same show.'],
      'letterIntro': 'Inside the box marked FILE 3–4:',
      'letter': _files,
      'question': 'What time did the show really start?',
      'hints': ['Look at FILE 3. When do the doors open?', 'A show cannot start before the doors open.'],
      'successMessage': 'The show fits at 4:00!',
      'transition': [
        'The whole show only fits between 4:00 and 6:10.',
        'A show at 3:00 would start too early and finish at 5:10.',
        'An old photo is clipped to FILE 3. Its caption says: 3:00 PM · CURTAIN UP!',
        "Is the photo telling the truth? Let's go and look at the stage.",
      ],
      'clue': {'note': 'FILE 3 says 3:00. But the show only fits between 4:00 and 6:10.'},
      'evidence': {'description': 'FILE 3 and FILE 4, found in a box in the opera archive.'},
    },
    's2_ep07_m2': {
      'story': ['At the back of the hall stands the old lighting desk.', 'The ghost light has a lever of its own.'],
      'letterIntro': 'The Lighting Book explains:',
      'letter': _lightingBook,
      'question': _turnOn,
      'hints': ['Only one lever is for the ghost light.', 'Tap the ghost light lever to turn it on.'],
      'successMessage': 'It matches the photo! Only the ghost light is on.',
      'transition': [
        'The photo shows an empty stage, not a show.',
        'Inside the Lighting Book is a cue card for show No. 34:',
        _cueLine,
        'A scrap of paper is also tucked in the book.',
        'It has a tiny drawing: a small clock above a red door.',
        'Have you seen that somewhere before?',
      ],
      'clue': {'note': 'The old photo shows only the ghost light, so the stage was empty. It was not a show.'},
      'evidence': {'description': 'It was kept at the lighting desk, not in the office.'},
    },
    's2_ep07_m3': {
      'story': ['Next to the stage is the rope rail.', 'When you pull a rope, its painted backdrop comes down.'],
      'letterIntro': 'Your notebook has the Painted Street:',
      'letter': _painted,
      'question': 'Which backdrop looks like the Painted Street?',
      'hints': [
        'Check The Painted Street in your notebook. Both the door and the clock must match.',
        'Bring each backdrop down and look just above its door.',
      ],
      'successMessage': 'There is a hidden pocket!',
      'transition': [
        "It looks just like the painter's street.",
        "Did P. paint it? We can't be sure.",
        'Inside the pocket is an old slip:',
        _slipLine,
        'The slip says to change the record. But was FILE 3 really changed?',
      ],
      'options': {
        'lampRed': {'feedback': 'There is a red door. But what is above the door?'},
        'towerRed': {'feedback': 'That clock is far away from the door. Look just above the door.'},
        'clockBlue': {'feedback': 'There is a small clock. But what colour is the door?'},
      },
      'clue': {'note': 'In a pocket behind the backdrop: a slip asking to change FILE 3.'},
      'evidence': {'description': 'It was in a pocket behind a painted backdrop.'},
    },
    's2_ep07_final': {
      'story': ['You are back in the archive, with two records and two start times.', 'One of the records was changed.'],
      'letterIntro': 'The Amendment Slip reads:',
      'letter': _slipLetter,
      'question': 'What is the new time on FILE 3?',
      'hints': ['First find FILE 3, then switch on the light table.', 'The new time is written on the patch, on top of the old one.'],
      'successMessage': 'Someone changed the record!',
      'transition': [
        'At first, FILE 3 said 4:00. Later, someone stuck 3:00 over it.',
        'The 3:00 show only happened on paper. It was a phantom performance!',
        'Once again it is 3:00 and 4:00, like the notices at the Eiffel Tower.',
        "Did the same person do both? We don't know yet.",
        'On the back of the slip is a sketch of a metro sign: ABBESSES.',
        'Under it: P. KNEW THE BAG.',
        'Next, the mystery leads to Montmartre!',
      ],
      'evidence': {'description': 'FILE 3, lying on the light table in the opera archive.'},
    },
  },
};

final master07 = <String, Object?>{
  'synopsis': [
    '"But the show remembers," the letter said.',
    'In the opera archive, a single show has two start times.',
    'An hour stands between them. Which one tells the truth?',
  ],
  'objectives': [
    "Put the show's times to the test.",
    'Light the stage exactly as the old photo shows it.',
    'Uncover what was changed, and prove it.',
  ],
  'intro': [
    'The letter has brought you to the Palais Garnier.',
    'On its back, the words OPERA ARCHIVE · FILE 3–4.',
    'Tonight the great opera house lies dark; its archive hides beneath the roof.',
    'A single box on the table bears the label FILE 3–4.',
  ],
  'caseSummary': 'The show truly began at 4:00; later, someone patched FILE 3 to read 3:00.',
  'hook': 'What did P. witness — and what did the bag carry?',
  'glossary': {...words07, ...masterWords07},
  'missions': {
    's2_ep07_m1': {
      'story': ["FILE 3 is the office's record of a single show.", "FILE 4 is that same show's programme."],
      'letterIntro': 'Inside FILE 3–4, you find:',
      'letter': _files,
      'question': 'At what time did the show truly begin?',
      'hints': ['FILE 3 tells you when the audience could come in.', 'No show begins before its audience has arrived.'],
      'successMessage': 'Only 4:00 fits!',
      'transition': [
        'The performance fits only between 4:00 and 6:10.',
        'Starting at 3:00, it would begin too early and end at 5:10.',
        'Clipped to FILE 3 is an old photo, captioned: 3:00 PM · CURTAIN UP!',
        'Can the photo be trusted? The stage may tell.',
      ],
      'clue': {'note': 'FILE 3 claims 3:00, yet the show fits only from 4:00 to 6:10.'},
      'evidence': {'description': 'FILE 3 and FILE 4, taken from a box in the opera archive.'},
    },
    's2_ep07_m2': {
      'story': ['The old lighting desk waits at the back of the hall.', 'Among its levers, one belongs to the ghost light alone.'],
      'letterIntro': 'The Lighting Book reads:',
      'letter': _lightingBook,
      'question': _turnOn,
      'hints': ['The photo shows a single lamp. Which lever is its?', 'Tap that lever, and watch the stage.'],
      'successMessage': 'A perfect match: the ghost light alone.',
      'transition': [
        'The photo captures an empty stage, not a performance.',
        'Inside the Lighting Book lies a cue card for show No. 34:',
        _cueLine,
        'Tucked between the pages is a scrap of paper.',
        'On it is a tiny drawing of a small clock above a red door.',
        'Where have you come across that before?',
      ],
      'clue': {'note': 'Only the ghost light glows in the old photo: an empty stage, not a performance.'},
      'evidence': {'description': 'Kept at the lighting desk, far from the office.'},
    },
    's2_ep07_m3': {
      'story': ['Beside the stage runs the rope rail.', 'Each rope, when pulled, lowers a painted backdrop.'],
      'letterIntro': 'From the Painted Street in your notebook:',
      'letter': _painted,
      'question': 'Which backdrop is a match for the Painted Street?',
      'hints': [
        'The Painted Street gives you two details. A backdrop must match both.',
        'As each backdrop comes down, study what sits above the door.',
      ],
      'successMessage': 'A secret pocket behind the backdrop!',
      'transition': [
        "It closely resembles the painter's street.",
        'Was it painted by P.? There is no way to be sure.',
        'Inside the pocket waits an old slip:',
        _slipLine,
        'It asks for the record to be changed. But was FILE 3 ever actually changed?',
      ],
      'options': {
        'lampRed': {'feedback': 'The door is red, but look at what hangs above it.'},
        'towerRed': {'feedback': 'That clock stands far from the door. The Painted Street has one right above it.'},
        'clockBlue': {'feedback': 'The clock is right, but check the colour of the door.'},
      },
      'clue': {'note': 'Hidden in a pocket behind the backdrop: a slip for changing FILE 3.'},
      'evidence': {'description': 'Discovered in a pocket sewn behind a painted backdrop.'},
    },
    's2_ep07_final': {
      'story': ['Back in the archive lie two records with two different start times.', 'One of them has been altered.'],
      'letterIntro': 'The Amendment Slip instructs:',
      'letter': _slipLetter,
      'question': 'Which is the new time on FILE 3?',
      'hints': ['FILE 3 first, then the light: it shows what lies underneath.', 'Whatever was added later sits on top.'],
      'successMessage': 'The record was altered!',
      'transition': [
        'FILE 3 once read 4:00, until someone pasted 3:00 over it.',
        'The 3:00 show existed only on paper: a phantom performance!',
        '3:00 and 4:00 once more, just like the notices at the Eiffel Tower.',
        'Was it the same hand both times? That remains unknown.',
        'On the back of the slip, someone sketched a metro sign: ABBESSES.',
        'Under it: P. KNEW THE BAG.',
        'The trail now climbs to Montmartre!',
      ],
      'evidence': {'description': 'FILE 3, laid on the light table in the opera archive.'},
    },
  },
};

// ═════════════════════════════════════════════════════════════════════════
// The scenes' own words
// ═════════════════════════════════════════════════════════════════════════

/// Case 07's scenes with Junior's words.
final juniorScenes07 = (
  easySteps: {
    's2_ep07_m1': retold(season2Case07Steps['s2_ep07_m1']!, const {
      'start': (
        say: 'What time did the show really start?',
        hints: ['Look at FILE 3. When do the doors open?', 'A show cannot start before the doors open.'],
        feedback: {'3': 'At 3:00 PM, the doors are still closed.'},
        tell: 'The show really started at 4:00 PM.',
        done: 'Yes, 4:00 PM! The show ended at 6:10 PM.',
      ),
    }),
    's2_ep07_m2': retold(season2Case07Steps['s2_ep07_m2']!, const {
      'switch': (
        say: null,
        hints: ['Only one lever is for the ghost light.', 'Tap the ghost light lever to turn it on.'],
        feedback: {},
        tell: null,
        done: 'Only the ghost light is on: an empty stage, not a show.',
      ),
      'scrap': (say: null, hints: ['The scrap was tucked inside the Lighting Book.'], feedback: {}, tell: null, done: null),
    }),
    's2_ep07_final': retold(season2Case07Steps['s2_ep07_final']!, const {
      'file': (
        say: null,
        hints: ['Look at the number at the top of each paper.', 'FILE 3 has a big 3 in the circle at the top.'],
        feedback: {'file4': 'That is FILE 4, the programme. You need FILE 3.'},
        tell: 'This paper is FILE 3.',
        done: 'FILE 3 is now on the light table.',
      ),
      'light': (
        say: null,
        hints: ['Find the switch on the right side of the table.', 'Tap the brass switch.'],
        feedback: {},
        tell: null,
        done: 'Look! There is a hidden 4:00 PM under the patch.',
      ),
      'time': (
        say: 'What is the new time on FILE 3?',
        hints: ['The new time is written on the patch, on top of the old one.', 'The old time is hidden under the patch.'],
        feedback: {'4': '4:00 PM is the old time. It is under the patch.'},
        tell: 'The new time is 3:00 PM. It is on the patch.',
        done: 'Someone changed the time!',
      ),
    }),
  },
);

/// Case 07's scenes with Master's words.
final masterScenes07 = (
  easySteps: {
    's2_ep07_m1': retold(season2Case07Steps['s2_ep07_m1']!, const {
      'start': (
        say: 'At what time did the show truly begin?',
        hints: ['FILE 3 tells you when the audience could come in.', 'No show begins before its audience has arrived.'],
        feedback: {'3': 'At 3:00 PM, the doors had not even opened.'},
        tell: 'The show began at 4:00 PM.',
        done: 'Yes, 4:00 PM! The curtain came down at 6:10 PM.',
      ),
    }),
    's2_ep07_m2': retold(season2Case07Steps['s2_ep07_m2']!, const {
      'switch': (
        say: null,
        hints: ['The photo shows a single lamp. Which lever is its?', 'Tap that lever, and watch the stage.'],
        feedback: {},
        tell: null,
        done: 'The ghost light alone: an empty stage, no performance.',
      ),
      'scrap': (say: null, hints: ['It had been tucked between the pages of the Lighting Book.'], feedback: {}, tell: null, done: null),
    }),
    's2_ep07_final': retold(season2Case07Steps['s2_ep07_final']!, const {
      'file': (
        say: null,
        hints: ['Each paper is numbered at the top.', 'Look for the 3 inside its circle.'],
        feedback: {'file4': 'That is the programme, FILE 4. FILE 3 is the other one.'},
        tell: 'FILE 3 is this one.',
        done: 'FILE 3 lies on the light table.',
      ),
      'light': (
        say: null,
        hints: ['The light table has a switch on its right edge.', 'Tap the brass switch.'],
        feedback: {},
        tell: null,
        done: 'Look! Beneath the patch, a hidden 4:00 PM appears.',
      ),
      'time': (
        say: 'Which is the new time on FILE 3?',
        hints: ['Whatever was added later sits on top.', 'The older time is the one underneath.'],
        feedback: {'4': '4:00 PM lies under the patch: that is the old time.'},
        tell: 'The new time, 3:00 PM, is on the patch.',
        done: 'The time was altered!',
      ),
    }),
  },
);

/// Case 07's scenes whose words are the same at every level (see
/// `season2SameAtEveryLevel`).
const sameAtEveryLevel07 = {
  'flyRails/s2_ep07_m3',
  'lightTables/s2_ep07_final',
};

// ═════════════════════════════════════════════════════════════════════════
// The learning design
// ═════════════════════════════════════════════════════════════════════════

final juniorLearning07 = <String, LearningObjective>{
  's2_ep07_m1': levelObjective('s2_ep07_m1', ['DOORS OPEN · 3:30 PM', 'What time did the show really start?']),
  's2_ep07_m2': levelObjective('s2_ep07_m2', [_turnOn, 'Only one lever is for the ghost light']),
  's2_ep07_m3': levelObjective('s2_ep07_m3', [_painted, 'look just above its door']),
  's2_ep07_final': levelObjective('s2_ep07_final', ['What is the new time on FILE 3?', 'switch on the light table']),
};

final masterLearning07 = <String, LearningObjective>{
  's2_ep07_m1': levelObjective('s2_ep07_m1', ['DOORS OPEN · 3:30 PM', 'No show begins before its audience has arrived']),
  's2_ep07_m2': levelObjective('s2_ep07_m2', [_turnOn, 'The photo shows a single lamp']),
  's2_ep07_m3': levelObjective('s2_ep07_m3', [_painted, 'study what sits above the door']),
  's2_ep07_final': levelObjective('s2_ep07_final', ['Which is the new time on FILE 3?', 'Whatever was added later sits on top']),
};
