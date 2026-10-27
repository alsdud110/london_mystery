import '../../models/abbesses_puzzles.dart';
import '../../models/garden_puzzles.dart';
import '../../models/learning.dart';
import 'season2_case07_scenes.dart';
import 'season2_case08_scenes.dart';
import 'season2_case09_scenes.dart';
import 'season2_learning.dart';
import 'season2_levels_04_06.dart' show retold;

/// Season 2, Cases 07–09 at each level (PART 7C): the words only
/// (`docs/difficulty_reviews/PARIS_CASE_07_09.md`).
///
/// Rookie: the game's own words, reviewed; one line made plainer (Case 09
/// M3's "mended"), and the words a child may not know added to the
/// glossary.
///
/// At every level the same: the papers each puzzle is read from (FILE 3 and
/// FILE 4, the Lighting Book, the cue card, the Painted Street's line, the
/// Amendment Slip and its back, the painter's sketch notes, his tag and his
/// note, the evidence list of the final board, the words beside the Little
/// Paris and on its gear board, the notebook's marks, the test card), the
/// board's questions and conclusions, every answer, id and order, and every
/// way to play (Tap…, Turn…, Drag…, Pull…).
///
/// Kept untold at every level: who changed FILE 3, and why; whether the
/// same hand changed the Eiffel Tower's record; whether P. painted the
/// backdrop; who carried the bag, whose badge it is, what the torn paper
/// changed; what the little clock was for before the garden shows it;
/// whether the gear and the two hands are one person's; who the Clockmaker
/// is; whether an hour was really lost; why the bag came to the garden.

// ═════════════════════════════════════════════════════════════════════════
// The glossary
// ═════════════════════════════════════════════════════════════════════════

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

const words08 = {'pyramid': '피라미드', 'entrance': '입구', 'amendment': '수정', 'matching': '일치하는'};
const _familiar = {'familiar': '익숙한'};
const _everywhere = {'everywhere': '어디에나'};
const juniorWords08 = {'arriving': '도착하는, 나타나는', 'placed': '놓인', 'pencil': '연필', 'carefully': '주의 깊게'};
const masterWords08 = {
  'witness': '목격하다',
  'witnessed': '목격했다',
  'shifts': '움직인다, 달라진다',
  'bound': '묶인',
  'identical': '똑같은',
  'supports': '뒷받침하다',
  'ringed': '둘러싸인',
  'stuffed': '가득 채운',
  'untying': '푸는',
  'figure': '사람의 모습',
  'daylight': '햇빛, 낮',
};

const words09 = {'chronos': '크로노스(시험 이름)', 'twelve': '열둘, 12', 'arches': '아치들', 'setting': '설정'};
const juniorWords09 = {'repaired': '수리했다', 'slides': '미끄러지듯 움직인다', 'happens': '일어난다'};
const masterWords09 = {
  'designed': '설계했다',
  'repaired': '수리했다',
  'copies': '본뜨다',
  'returned': '돌려놓은',
  'carried': '(실험을) 실시한',
  'refuse': '~하려 하지 않다',
  'separate': '서로 다른',
  'spreading': '퍼져 나가는',
};

/// Rookie's glossary for each case.
const rookieWords07 = words07;
const rookieWords08 = {...words08, ..._everywhere, ..._familiar};

// ═════════════════════════════════════════════════════════════════════════
// Rookie: one line made plainer
// ═════════════════════════════════════════════════════════════════════════

/// Case 09 at Rookie: "mended" said as "fixed" (the same repair).
const rookie09 = <String, Object?>{
  'glossary': words09,
  'missions': {
    's2_ep09_m3': {
      'transition': [
        "The Clockmaker's gear is the trial's emblem.",
        'The two hands are on the repair note. No. 7 fixed a trial wheel.',
        'Two marks on two different papers. Did one person make both? The papers do not say.',
        "And the paper from the bag? Is it linked to this machine? We can't tell yet.",
      ],
    },
  },
};

// ═════════════════════════════════════════════════════════════════════════
// Case 07 — The Phantom Performance
// ═════════════════════════════════════════════════════════════════════════

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
// Case 08 — The Painter's Last Sketch
// ═════════════════════════════════════════════════════════════════════════

const _sketchNote =
    'The sketch he hid in his studio:\n'
    'Steps. An old lamp. A gate between two pillars.\n'
    'The white church above.';
const _tag =
    'I drew this corner one morning.\n'
    'First, the sky was dark.\n'
    'Then it grew light.\n'
    'When the sun came up, the lamps went out.\n'
    '— P.';
const _note = 'I found this paper on the steps.\nI kept it with my drawings.\n— P.';
const _evidenceList =
    'THE BAG SKETCH\n'
    'A paper lies on the steps after the bag goes by.\n\n'
    'THE MATCHING SEAL\n'
    'A torn paper. The same form and seal as the opera slip.\n\n'
    'THE AMENDMENT SLIP\n'
    'FILE 3 · CURTAIN UP: 4:00 to 3:00.';
const _sayNow = 'What can you say now?';
const _knewTheBag = 'Under it: P. KNEW THE BAG.';

/// The final board's lines for each wrong link (keys: the answers, as the
/// base has them).
Map<String, String> _boardLines({
  required String q1e1,
  required String q1One,
  required String q1e3,
  required String q1e4,
  required String q2e3,
  required String q2e4,
  required String q2e1,
  required String q2e2,
  required String q2e2e3,
  required String q2e1e3,
  required String q2Two,
  required String why,
  required String parts,
  required String painter,
  required String who,
}) =>
    {
      'q1:e1': q1e1,
      'q1:e1+e2': q1One,
      'q1:e3': q1e3,
      'q1:e4': q1e4,
      'q1:e2+e3': q1One,
      'q1:e2+e4': q1One,
      'q2:e3': q2e3,
      'q2:e4': q2e4,
      'q2:e1': q2e1,
      'q2:e2': q2e2,
      'q2:e2+e3': q2e2e3,
      'q2:e1+e3': q2e1e3,
      'q2:e1+e3+e4': q2Two,
      'q2:e2+e3+e4': q2Two,
      'why:': why,
      'why:parts': parts,
      'why:painter': painter,
      'why:who': who,
    };

final junior08 = <String, Object?>{
  'synopsis': [
    'On the back of the opera slip: P. KNEW THE BAG.',
    'P. is the painter who went away on his own.',
    'He said he saw who took the hour. But what did he really see?',
  ],
  'objectives': ['Find the spot where the painter sat.', 'Look closely at his drawings.', 'Find out what P. really saw.'],
  'intro': [
    'You turn the opera slip over once more.',
    'There is a tiny sketch: steps, a lamp and a metro sign. ABBESSES.',
    _knewTheBag,
    'P. is the painter. He once said: I saw who took the hour.',
    'Which bag? And what did he see?',
    "Abbesses is up on the hill of Montmartre. Let's go there.",
  ],
  'caseSummary': 'P. saw the bag, and a paper for changing a time fell from it. Later, he drew the same bag in a garden.',
  'hook': 'Why was the bag beside the little clock in the garden?',
  'glossary': {...words08, ..._everywhere, ...juniorWords08},
  'missions': {
    's2_ep08_m1': {
      'story': ['Abbesses. There are steps, lamps and gates everywhere.', 'Where did the painter sit when he drew?'],
      'letterIntro': 'Your notebook says:',
      'letter': _sketchNote,
      'question': 'Which corner did the painter draw from?',
      'hints': [
        "Take the painter's hidden sketch from your notebook and compare it with each corner.",
        'Look at which side the lamp is on. The sketch is in pencil, so read its words for colours.',
      ],
      'successMessage': 'This is where the painter sat!',
      'transition': [
        "The lamp is on the left and the gate is black. This is the painter's corner.",
        'One stone in the left pillar moves.',
        'Behind the stone is a bundle of drawings tied with string.',
      ],
      'options': {
        'corner1': {'feedback': 'The steps and the lamp are right. Now read the words with the sketch. What colour should the gate be?'},
        'corner3': {'feedback': 'Check the sketch again. Should the lamp be left of the gate, or right?'},
      },
      'recall': {
        'title': 'Have you seen these steps before?',
        'prompt': 'Find the drawing that the painter hid.',
        'feedback': {
          's2_ep07_e3': 'That sketch led you here. Find the one he hid in his studio.',
          's2_ep02_e1': 'That street has a red door. You need steps and a gate.',
          's2_ep02_e4': 'That message was on the back of a canvas. Find the sketch that was under the paint.',
        },
      },
      'clue': {'note': 'This is the corner from his hidden sketch. His drawings were behind a loose stone.'},
      'evidence': {'description': 'The corner in Abbesses where the painter sat to draw.'},
    },
    's2_ep08_m2': {
      'story': ['You untie the string and find three drawings of this corner.', 'The steps, the lamp and the gate are the same. But something changes.'],
      'letterIntro': 'A tag tied to the string says:',
      'letter': _tag,
      'question': 'How did the paper get onto the steps?',
      'hints': [
        "Use P.'s tag to put the drawings in order: dark sky first, lamps out last.",
        'Find the drawing where the paper first appears. Who was on the steps just before it?',
      ],
      'successMessage': 'It came from the bag!',
      'transition': [
        'In drawing 2, someone carries a flat bag full of papers.',
        'In drawing 3, the person is gone, and a paper lies on the steps.',
        'The paper must have fallen from the bag.',
        "P. also drew the bag's badge: a small shield with leaves around it.",
        'But he drew no face. Only a hat and a back.',
      ],
      'options': {
        'always': {'feedback': 'Check drawings 1 and 2. Can you see a paper on the steps?'},
        'painter': {'feedback': 'The painter was sitting across the street, far from the steps.'},
        'window': {'feedback': 'Look at drawing 2. Who was on the steps just before the paper appeared?'},
      },
      'clue': {'note': 'The bag went up the steps, and then a paper was there.'},
      'evidence': {'description': "Three drawings of one morning, drawn from the painter's corner."},
    },
    's2_ep08_m3': {
      'story': ['Behind the drawings, there is one more paper, folded small.', 'It is not a drawing. There is a note clipped to it.'],
      'letterIntro': "P.'s note reads:",
      'letter': _note,
      'question': 'What matches the opera slip, and what is missing?',
      'hints': [
        'Take the opera slip from your notebook and put it next to this paper.',
        'Count the hands on the seal. Then compare FILE and the times on both papers.',
      ],
      'successMessage': 'It has the same seal!',
      'transition': [
        'It is the same kind of form, with the same purple seal.',
        'But the FILE number and the hour have been torn away.',
        'Just like the opera slip, it is a paper for changing a time.',
        'P. found it on the steps. Is it the paper from his drawing?',
      ],
      'feedback': {
        'need:same': 'Four things on this paper look just like the opera slip.',
        'need:seal': 'Look carefully at the seal. How many hands does it have?',
        'need:hour': 'Read the times on the opera slip. What number comes before :00?',
        'need:number': 'The opera slip says FILE 3. What comes after FILE on this paper?',
      },
      'recall': {
        'title': 'Do you know this seal?',
        'prompt': 'Find the slip you found at the opera.',
        'feedback': {
          's2_ep01_e3': 'That mark is a gear. Does this seal look like a gear?',
          's2_ep05_e1': 'That mark has two hands. This seal has none.',
          's2_ep07_e4': 'That is FILE 3. Find the small slip that asked for the change.',
          's2_ep06_e4': 'That is Letter 4417. You need the paper with a purple seal.',
        },
      },
      'clue': {'note': 'It has the same form and seal as the opera slip. The FILE number and the hour are torn away.'},
      'evidence': {'description': 'A torn, folded paper that P. kept with his drawings.'},
    },
    's2_ep08_final': {
      'story': ["You sit in the painter's place with drawing 3 and the torn paper.", 'Is it the same paper? And what does it tell us?'],
      'letterIntro': 'Here is your evidence:',
      'letter': _evidenceList,
      'question': _sayNow,
      'hints': [
        'Start by turning the paper until its V-shaped tear matches the drawing.',
        'One piece of evidence shows where the paper came from. Two others show what kind of paper it is.',
      ],
      'successMessage': 'The paper fell from the bag!',
      'transition': [
        'The paper fell out of the bag.',
        'Like the opera slip, it is a paper for changing a time.',
        'But who carried the bag? P. never drew a face.',
        'And why was the bag next to a little clock in a garden?',
        'Next stop: the Luxembourg Gardens!',
      ],
      'feedback': _boardLines(
        q1e1: 'That shows where P. sat. Which drawings show the paper arriving?',
        q1One: 'Question 1 needs just one piece: the drawings of that morning.',
        q1e3: 'That is the paper itself. Which drawings show where it came from?',
        q1e4: 'That slip was found at the opera. Which drawings show where this paper came from?',
        q2e3: 'What is a paper with this seal for? Which older clue shows that?',
        q2e4: 'The slip shows what this kind of form is for. Now add the paper itself.',
        q2e1: 'That shows where P. sat. Look at the paper and the opera slip instead.',
        q2e2: 'The drawings show where the paper came from, not what kind it is.',
        q2e2e3: 'The drawings show where it came from. Which older clue shows what the form is for?',
        q2e1e3: 'That shows where P. sat. Which older clue shows what the form is for?',
        q2Two: 'Question 2 needs just two pieces: the paper and the opera slip.',
        why: 'Now choose what the evidence shows.',
        parts: 'What fell from the bag: a clock part or a paper?',
        painter: 'The painter was busy drawing. Who walked up the steps?',
        who: 'Did P. draw a face or write a name? What do we really know?',
      ),
      'evidence': {'description': "The torn paper, placed on P.'s drawing of the steps."},
    },
  },
};

final master08 = <String, Object?>{
  'synopsis': [
    'The opera slip bears four words: P. KNEW THE BAG.',
    'P. is the painter who slipped away from Montmartre.',
    'He claimed he saw who took the hour. What exactly did he witness?',
  ],
  'objectives': ['Track down where the painter sat to draw.', 'Study his drawings.', 'Work out what P. witnessed.'],
  'intro': [
    'Once again, you turn the opera slip over.',
    'A tiny sketch of steps, a lamp and a metro sign: ABBESSES.',
    _knewTheBag,
    'P. is the painter, the one who said: I saw who took the hour.',
    'What bag? And what did he truly see?',
    'Abbesses sits high on the hill of Montmartre. Time to go.',
  ],
  'caseSummary': 'P. watched the bag pass, and a paper for changing a time fell from it. Later he sketched that bag again, in a garden.',
  'hook': 'What drew the bag to the little clock in the garden?',
  'glossary': {...words08, ..._familiar, ...masterWords08},
  'missions': {
    's2_ep08_m1': {
      'story': ['Abbesses: steps, lamps and gates wherever you look.', 'From which corner did the painter draw?'],
      'letterIntro': 'Your notebook describes it:',
      'letter': _sketchNote,
      'question': 'From which corner did the painter make his sketch?',
      'hints': [
        'The hidden sketch in your notebook is your guide. Hold it up to each corner.',
        'Mind the side the lamp stands on, and since the sketch has no colour, trust its words.',
      ],
      'successMessage': "The painter's corner, found!",
      'transition': [
        "Lamp on the left, gate painted black: the painter's very corner.",
        'One stone in the left pillar shifts under your hand.',
        'Behind it lies a bundle of drawings, bound with string.',
      ],
      'options': {
        'corner1': {'feedback': "Steps and lamp agree, but the sketch's words name the gate's colour. Does this one match?"},
        'corner3': {'feedback': 'Where does the sketch place the lamp: left of the gate, or right?'},
      },
      'recall': {
        'title': 'These steps seem strangely familiar...',
        'prompt': 'Find the sketch the painter hid away.',
        'feedback': {
          's2_ep07_e3': 'That sketch only brought you here. The one you need was hidden in his studio.',
          's2_ep02_e1': 'A red door belongs to another street. Look for steps and a gate.',
          's2_ep02_e4': 'That message came from the back of a canvas. The sketch you want lay beneath the paint.',
        },
      },
      'clue': {'note': 'The corner of his hidden sketch, where his drawings lay behind a loose stone.'},
      'evidence': {'description': 'The corner of Abbesses from which the painter drew.'},
    },
    's2_ep08_m2': {
      'story': [
        'Untying the string, you find three drawings of this very corner.',
        'Steps, lamp and gate stay the same, yet something shifts from one to the next.',
      ],
      'letterIntro': 'A tag on the string reads:',
      'letter': _tag,
      'question': 'What brought the paper to the steps?',
      'hints': [
        "P.'s tag gives the order: darkness, then light, then the lamps going out.",
        'The paper appears at one moment. What happened on the steps just before?',
      ],
      'successMessage': 'The bag dropped the paper!',
      'transition': [
        'Drawing 2: a figure with a flat bag, stuffed with papers.',
        'Drawing 3: the figure has gone, and a paper lies on the steps.',
        'The bag must have dropped it.',
        "P. even sketched the bag's badge: a small shield ringed with leaves.",
        'Yet there is no face. Only a hat, and a back turned away.',
      ],
      'options': {
        'always': {'feedback': 'In drawings 1 and 2, is there any paper on the steps?'},
        'painter': {'feedback': 'The painter sat across the street, nowhere near the steps.'},
        'window': {'feedback': 'Drawing 2 shows who climbed those steps just before the paper appeared.'},
      },
      'clue': {'note': 'First the bag went up the steps; then a paper lay there.'},
      'evidence': {'description': "Three drawings of a single morning, made from the painter's corner."},
    },
    's2_ep08_m3': {
      'story': ['Behind the drawings lies one more paper, folded tightly.', 'This one is no drawing. A note is clipped to it.'],
      'letterIntro': "In P.'s own hand:",
      'letter': _note,
      'question': 'What does this paper share with the opera slip, and what has it lost?',
      'hints': [
        'Lay the opera slip from your notebook beside this paper.',
        'Compare them part by part: the seal, the FILE band and the times.',
      ],
      'successMessage': 'An identical seal!',
      'transition': [
        'The same form, and the same purple seal.',
        'Yet the FILE number and the hour are torn away.',
        'Like the opera slip, it was made for changing a time.',
        'P. found it on the steps. Could it be the very paper in his drawing?',
      ],
      'feedback': {
        'need:same': 'Four features of this paper match the opera slip exactly.',
        'need:seal': 'Examine the seal. How many hands does its clock have?',
        'need:hour': 'On the opera slip, a number stands before :00. What stands there on this paper?',
        'need:number': 'The opera slip reads FILE 3. What follows FILE here?',
      },
      'recall': {
        'title': 'Where have you seen this seal before?',
        'prompt': 'Find the slip from the opera house.',
        'feedback': {
          's2_ep01_e3': 'That mark is a gear; this seal is no gear.',
          's2_ep05_e1': 'That mark has two hands; this seal has none at all.',
          's2_ep07_e4': 'That is FILE 3 itself. You want the small slip that ordered the change.',
          's2_ep06_e4': 'That is Letter 4417. Seek the paper with a purple seal.',
        },
      },
      'clue': {'note': "The opera slip's form and seal, but with the FILE number and the hour torn off."},
      'evidence': {'description': "A torn, folded paper, tucked among P.'s drawings."},
    },
    's2_ep08_final': {
      'story': ["From the painter's own seat, you hold drawing 3 beside the torn paper.", 'Are they the same paper? And if so, what does it reveal?'],
      'letterIntro': 'The evidence you have gathered:',
      'letter': _evidenceList,
      'question': _sayNow,
      'hints': [
        'Turn the paper until its V-shaped tear lines up with the drawing.',
        'Ask what each piece of evidence proves: where the paper came from, or what it is.',
      ],
      'successMessage': 'The torn paper came from the bag!',
      'transition': [
        'The paper slipped from the bag.',
        'Like the opera slip, it was meant for changing a time.',
        'Yet whose hand carried the bag? P. never drew a face.',
        'And why would the bag stand beside a little clock in a garden?',
        'The trail now leads to the Luxembourg Gardens!',
      ],
      'feedback': _boardLines(
        q1e1: 'That only shows where P. sat. Which evidence shows the paper arriving?',
        q1One: 'One piece answers Question 1: the drawings of that morning.',
        q1e3: 'That is the paper itself, not where it came from.',
        q1e4: 'That slip belongs to the opera. Where did this paper come from?',
        q2e3: 'The paper alone cannot say what it is for. Which older clue can?',
        q2e4: 'The slip explains the form. Now add the paper itself.',
        q2e1: 'That is where P. sat. The paper and the opera slip matter here.',
        q2e2: 'The drawings say where it came from, not what it is.',
        q2e2e3: 'Drop the drawings. Which older clue explains the form?',
        q2e1e3: 'Drop the corner. Which older clue explains the form?',
        q2Two: 'Two pieces answer Question 2: the paper and the opera slip.',
        why: 'Choose the conclusion the evidence supports.',
        parts: 'Was it a clock part that fell from the bag, or a paper?',
        painter: 'The painter sat drawing. Someone else climbed the steps.',
        who: 'P. drew no face and wrote no name. What do we truly know?',
      ),
      'evidence': {'description': "The torn paper, laid over P.'s drawing of the steps."},
    },
  },
};

// ═════════════════════════════════════════════════════════════════════════
// Case 09 — The Clockwork Garden
// ═════════════════════════════════════════════════════════════════════════

const _putBack = 'Put each clock back where it belongs.';
const _join = 'Join the tower to the trial clocks.';
const _marks =
    "THE CLOCKMAKER'S MARK (Gare du Nord)\n"
    'A tiny carved gear.\n\n'
    'THE REPAIR CARD (No. 7)\n'
    'Signed with two clock hands.';
const _testCard = 'Set the tower one hour back. Then press TEST.';
const _drumTag = 'Its tag says: TRIAL RECORDS · KEPT AT THE STAR.';
const _lostOrWrong = 'Was the hour lost — or was the clock wrong?';

final junior09 = <String, Object?>{
  'synopsis': [
    'A paper for changing a time fell out of a bag.',
    'P. drew the same bag in a garden, next to a little clock.',
    'And what is that little clock?',
  ],
  'objectives': ['Find out what the little clock really is.', 'Get the clocks moving.', 'Test what the clocks do.'],
  'intro': [
    "You look at P.'s last drawing once more.",
    'There is a palace, a round pond and a little clock on a stone base.',
    'And next to it is the same flat bag.',
    'You walk into the Luxembourg Gardens.',
    "There's the palace, and there's the pond. It's the garden from the drawing!",
    "Look! There's the little clock from the drawing!",
    'The same bag was here once. But why?',
  ],
  'caseSummary': "One wrong setting changed only the clocks that were joined. T1's star pointed to the Arc de Triomphe.",
  'hook': _lostOrWrong,
  'glossary': {...words09, ...juniorWords09},
  'missions': {
    's2_ep09_m1': {
      'story': ['There is a map of Paris on the stone base.', 'Next to it, three little clocks lie in a box.'],
      'letterIntro': 'A note beside the box says:',
      'letter': _putBack,
      'question': 'Put each little clock back in its place on the map.',
      'hints': ['Look at the shape of each clock, then find that shape on the map.', 'T1 looks like an arch, T2 like a bridge, and T3 has a tall spire.'],
      'successMessage': 'All three clocks are back in place!',
      'transition': [
        'There are trial clocks in only three places in Paris.',
        'Each one has its own sign: a star, three arches or a bell.',
        'How can one little tower reach all three?',
      ],
      'clue': {'note': 'Trial clocks stand in only three places in Paris.'},
      'evidence': {'description': 'The little clocks, back in their places on the map of Paris.'},
    },
    's2_ep09_m2': {
      'story': ['Under the model, a little door opens.', 'There are gears inside! But two of them are missing.'],
      'letterIntro': 'The board says:',
      'letter': _join,
      'question': 'Use the gears to join the tower and the trial clocks.',
      'hints': ['Look at the size of each dotted circle. Which gear fits it?', 'The big gear goes next to T1, and the small gear goes next to T2 and T3.'],
      'successMessage': 'All the joined clocks turn together!',
      'transition': [
        'Gears move the model, but the real trial used wires.',
        'Under T1, a little drum writes down the time.',
        _drumTag,
        'A drawer slides open. Who planned this machine? And who fixed it?',
      ],
      'clue': {'note': 'The tower only moves the clocks that are joined to it.'},
      'evidence': {'description': 'The gear board under the Little Paris model.'},
    },
    's2_ep09_m3': {
      'story': ['In the drawer is an old plan called CHRONOS TRIAL, with a repair note.', 'You have seen these marks before!'],
      'letterIntro': 'Your notebook has these marks:',
      'letter': _marks,
      'question': 'Find the same two marks on the old paper.',
      'hints': ['Look for the same shapes on the old paper.', 'Look for the gear on the plan, and the two hands on the repair note.'],
      'successMessage': 'They are the same marks!',
      'transition': [
        "The Clockmaker's gear is the emblem of the trial.",
        'The two hands are on the repair note. No. 7 repaired a trial wheel.',
        'There are two marks on two different papers. Did one person make both? The papers do not say.',
        "And the paper from the bag? Is it connected to this machine? We can't tell yet.",
      ],
      'clue': {'note': 'Two marks on two different papers. Who made them? The papers do not say.'},
      'evidence': {'description': 'An old plan of the trial, with a repair note.'},
    },
    's2_ep09_final': {
      'story': ["You put the hands back on the tower. Every clock says four o'clock.", 'What happens if the tower is set to the wrong time?'],
      'letterIntro': 'The card reads:',
      'letter': _testCard,
      'question': 'What happened to the clocks?',
      'hints': ['To go one hour back, move the short hand from 4 to 3.', 'Check which clocks changed and which one stayed at four.'],
      'successMessage': 'One wrong setting did it!',
      'transition': [
        'One wrong setting can change many joined clocks at once.',
        "And the bag? We still don't know why it came here.",
        'Was an hour really lost? The records at the star may tell us.',
        'Next, the mystery leads to the Arc de Triomphe!',
      ],
      'options': {
        'all': {'feedback': 'Check the garden clock. What time does it show?'},
        'who': {'feedback': 'The test shows HOW it happened. Does it show WHO did it?'},
      },
      'evidence': {'description': 'A test you did on the tower clock in the garden.'},
    },
  },
};

final master09 = <String, Object?>{
  'synopsis': [
    'A paper for changing a time slipped from a bag.',
    'P. drew that same bag in a garden, beside a little clock.',
    'What could the little clock be?',
  ],
  'objectives': ['Discover the secret of the little clock.', 'Set the clocks in motion.', 'Put the clocks to the test.'],
  'intro': [
    "Once more, you study P.'s last drawing.",
    'A palace, a round pond, and a little clock on a stone base.',
    'Beside it, that same flat bag.',
    'You step through the gates of the Luxembourg Gardens.',
    'The palace. The pond. This is the garden in the drawing!',
    'And there stands the little clock, exactly as he drew it!',
    'The bag was here too. What brought it?',
  ],
  'caseSummary': "A single wrong setting changed only the joined clocks, and T1's star pointed the way to the Arc de Triomphe.",
  'hook': _lostOrWrong,
  'glossary': {...words09, ...masterWords09},
  'missions': {
    's2_ep09_m1': {
      'story': ['The stone base carries a map of Paris.', 'Beside it, three little clocks rest in a box.'],
      'letterIntro': 'Written beside the box:',
      'letter': _putBack,
      'question': 'Return the three little clocks to their places on the map.',
      'hints': ['Each little clock copies a building. Match the shapes.', 'An arch, a bridge, a tall spire: where does each stand in Paris?'],
      'successMessage': 'Every clock is home again!',
      'transition': [
        'Just three places in Paris hold trial clocks.',
        'Each bears a sign: a star, three arches, a bell.',
        'How could one little tower reach all three?',
      ],
      'clue': {'note': 'Just three places in Paris hold trial clocks.'},
      'evidence': {'description': 'The little clocks, returned to the map of Paris.'},
    },
    's2_ep09_m2': {
      'story': ['A little door swings open beneath the model.', 'Gears fill the space, but two are missing.'],
      'letterIntro': 'Written on the board:',
      'letter': _join,
      'question': 'Connect the tower to the trial clocks.',
      'hints': ['The dotted circles differ in size. Let each one choose its gear.', 'The larger space is near T1; the smaller one is near T2 and T3.'],
      'successMessage': 'The clocks turn as one!',
      'transition': [
        'Gears drive the model, though the real trial used wires.',
        'Beneath T1, a little drum records the time.',
        _drumTag,
        'A drawer slides open. Who designed this machine, and who repaired it?',
      ],
      'clue': {'note': 'The tower moves only the clocks connected to it.'},
      'evidence': {'description': 'The gear board hidden beneath the Little Paris.'},
    },
    's2_ep09_m3': {
      'story': ['The drawer holds an old plan marked CHRONOS TRIAL, with a repair note pinned to it.', 'These marks are familiar!'],
      'letterIntro': 'From your notebook:',
      'letter': _marks,
      'question': 'Find where both marks appear on the old paper.',
      'hints': ['Compare each mark with the shapes on the old paper.', 'One mark belongs to the plan itself; the other to the repair note.'],
      'successMessage': 'Both marks match!',
      'transition': [
        "The Clockmaker's gear turns out to be the trial's emblem.",
        'The two hands appear on the repair note: No. 7 once repaired a trial wheel.',
        'Two marks, on two separate papers. Were both made by one person? The papers stay silent.',
        'And the paper from the bag: is it linked to this machine? Nothing tells us yet.',
      ],
      'clue': {'note': 'Two marks, two papers, and no name to say who made them.'},
      'evidence': {'description': 'An old trial plan, a repair note pinned to it.'},
    },
    's2_ep09_final': {
      'story': ["With the tower's hands back in place, every clock reads four.", 'But what if the tower were set wrong?'],
      'letterIntro': 'A card gives the instructions:',
      'letter': _testCard,
      'question': 'What did the test show?',
      'hints': [
        'One hour back means the short hand moves from 4 to 3.',
        'After the test, compare the clocks. Did any of them refuse to move?',
      ],
      'successMessage': 'A single wrong setting!',
      'transition': [
        'A single wrong setting can change several connected clocks at once.',
        'As for the bag, why it came here remains a mystery.',
        'Was an hour truly lost? The records at the star may hold the answer.',
        'The trail now leads to the Arc de Triomphe!',
      ],
      'options': {
        'all': {'feedback': 'Did the garden clock change too?'},
        'who': {'feedback': 'A test can show how. Can it show who?'},
      },
      'evidence': {'description': "A test carried out on the garden's tower clock."},
    },
  },
};

// ═════════════════════════════════════════════════════════════════════════
// The scenes' own words
// ═════════════════════════════════════════════════════════════════════════

/// The three drawings: what is said when they are put out of order, once
/// they are in order, and the question after them (the mission's own, at
/// its level). The drawings and every way to play are the base's.
MorningSketchesScene _morning(MorningSketchesScene b, {required String lamp, required String sky, required String ordered, required String question}) =>
    MorningSketchesScene(
      sketches: b.sketches,
      shown: b.shown,
      lampOff: b.lampOff,
      slots: b.slots,
      orderTask: b.orderTask,
      checkOrderLabel: b.checkOrderLabel,
      lampLine: lamp,
      skyLine: sky,
      orderedLine: ordered,
      compareTask: b.compareTask,
      questionTask: question,
    );

/// The torn form: what its folds, tear and dust say when tapped, and the
/// seal's lines for a wrong answer. The form, its parts and the seal's
/// questions are the base's.
TornSlipScene _slip(TornSlipScene b, {required Map<String, String> partLines, required List<String> sealWrong}) => TornSlipScene(
      folded: b.folded,
      foldedPixels: b.foldedPixels,
      form: b.form,
      parts: [
        for (final p in b.parts) FormPart(id: p.id, area: p.area, mark: p.mark, name: p.name, line: p.line == null ? null : partLines[p.id]!),
      ],
      sealId: b.sealId,
      sealChecks: [
        for (final (i, c) in b.sealChecks.indexed) SealCheck(question: c.question, choices: c.choices, answer: c.answer, wrongLine: sealWrong[i]),
      ],
      folds: b.folds,
      unfoldTask: b.unfoldTask,
      sameTask: b.sameTask,
      missingTask: b.missingTask,
      checkLabel: b.checkLabel,
      sealTitle: b.sealTitle,
      noteLines: b.noteLines,
    );

/// The final at P.'s corner: what is said as the paper is laid on the
/// drawing, and of his last drawing and its garden. The board, the drawing
/// and the map are the base's.
TornHourScene _corner(
  TornHourScene b, {
  required String heading,
  required String tear,
  required String seal,
  required String off,
  required List<String> placed,
  required Map<String, String> bagLines,
  required List<String> bagDone,
  required Map<String, String> placeLines,
  required String other,
  required List<String> done,
}) {
  final l = b.lead;
  LeadPart part(LeadPart p) => LeadPart(id: p.id, area: p.area, line: bagLines[p.id]!);
  return TornHourScene(
    sketch: b.sketch,
    form: b.form,
    startTurns: b.startTurns,
    board: b.board,
    lead: NextLead(
      file: l.file,
      pixels: l.pixels,
      label: l.label,
      bagParts: [for (final p in l.bagParts) part(p)],
      decoy: part(l.decoy),
      bagTask: l.bagTask,
      bagDone: bagDone,
      features: l.features,
      mapFile: l.mapFile,
      mapPixels: l.mapPixels,
      spots: l.spots,
      answer: l.answer,
      feedback: {for (final k in l.feedback.keys) k: placeLines[k]!},
      otherLine: other,
      mapTask: l.mapTask,
      chooseLabel: l.chooseLabel,
      doneLines: done,
    ),
    placeHeading: heading,
    placeTask: b.placeTask,
    turnLabel: b.turnLabel,
    layLabel: b.layLabel,
    tearLine: tear,
    sealLine: seal,
    offLine: off,
    placedLines: placed,
    leadLabel: b.leadLabel,
  );
}

/// A trial clock's model with its line for a wrong place.
TrialModel _model(TrialModel m, String wrongLine) =>
    TrialModel(id: m.id, name: m.name, file: m.file, label: m.label, spot: m.spot, wrongLine: wrongLine, sign: m.sign);

/// The Little Paris: each clock's line for a wrong place.
TrialMapScene _map(TrialMapScene b, {required Map<String, String> wrong, required Map<String, String> special}) => TrialMapScene(
      mapFile: b.mapFile,
      mapPixels: b.mapPixels,
      spots: b.spots,
      models: [for (final m in b.models) _model(m, wrong[m.id]!)],
      modelPixels: b.modelPixels,
      task: b.task,
      dropRadius: b.dropRadius,
      specialLines: {for (final k in b.specialLines.keys) k: special[k]!},
      placedLine: b.placedLine,
    );

/// The gear board: what is said once it turns.
GearBoardScene _gears(GearBoardScene b, String turning) => GearBoardScene(
      file: b.file,
      pixels: b.pixels,
      view: b.view,
      gearFile: b.gearFile,
      gearPixels: b.gearPixels,
      dialFile: b.dialFile,
      dialPixels: b.dialPixels,
      dialPivot: b.dialPivot,
      radii: b.radii,
      slots: b.slots,
      fixed: b.fixed,
      clocks: b.clocks,
      tray: b.tray,
      task: b.task,
      tooBig: b.tooBig,
      tooSmall: b.tooSmall,
      oneMore: b.oneMore,
      turningLine: turning,
    );

/// The old plan: the lines for a wrong pairing of marks.
MakerMarksScene _plan(MakerMarksScene b, Map<String, String> lines) => MakerMarksScene(
      file: b.file,
      pixels: b.pixels,
      handsFile: b.handsFile,
      handsPixels: b.handsPixels,
      marks: b.marks,
      paper: b.paper,
      task: b.task,
      pickFirst: b.pickFirst,
      lines: {for (final k in b.lines.keys) k: lines[k]!},
    );

/// The tower test: its lines for a wrong hour, after the test, and the way
/// to the star. The clocks, the hours and the map are the base's.
TowerTestScene _tower(
  TowerTestScene b, {
  required Map<int, String> hours,
  required List<String> tested,
  required List<String> after,
  required String question,
  required String other,
  required String found,
  required List<String> done,
}) {
  final l = b.lead;
  return TowerTestScene(
    garden: b.garden,
    gardenPixels: b.gardenPixels,
    gardenLabel: b.gardenLabel,
    gardenClock: b.gardenClock,
    dialFile: b.dialFile,
    dialPixels: b.dialPixels,
    dialPivot: b.dialPivot,
    dialRadius: b.dialRadius,
    startHour: b.startHour,
    targetHour: b.targetHour,
    clocks: b.clocks,
    handsLine: b.handsLine,
    testLabel: b.testLabel,
    hourLines: {for (final k in b.hourLines.keys) k: hours[k]!},
    testedLines: tested,
    afterLines: after,
    lead: StarLead(
      title: l.title,
      tag: l.tag,
      question: question,
      models: l.models,
      modelPixels: l.modelPixels,
      answer: l.answer,
      otherLine: other,
      foundLine: found,
      mapFile: l.mapFile,
      mapPixels: l.mapPixels,
      spot: l.spot,
      doneLines: done,
    ),
    leadLabel: b.leadLabel,
  );
}

/// Cases 07–09's scenes with Junior's words.
final juniorScenes0709 = (
  morningSketches: {
    's2_ep08_m2': _morning(
      season2MorningSketches['s2_ep08_m2']!,
      lamp: 'This lamp is already out. Can this drawing come before the others?',
      sky: 'Compare the skies. Which one is darker?',
      ordered: 'First dark, then light, and then the lamp goes out.',
      question: 'How did the paper get onto the steps?',
    ),
  },
  tornSlips: {
    's2_ep08_m3': _slip(
      season2TornSlips['s2_ep08_m3']!,
      partLines: const {
        'foldAcross': 'Those are just folds. P. folded the paper small.',
        'foldDown': 'Those are just folds. P. folded the paper small.',
        'tear': 'The opera slip has no tear. Is this part the same?',
        'dust': 'That is only dust from the steps.',
      },
      sealWrong: const ['Look again. Can you see any hands on this clock?', 'Look at what makes the ring around the clock.'],
    ),
  },
  tornHours: {
    's2_ep08_final': _corner(
      season2TornHours['s2_ep08_final']!,
      heading: 'Is this the same paper?',
      tear: 'Find the V-shaped tear. Where is it in the drawing?',
      seal: 'Can you find the round seal in the drawing?',
      off: 'P. drew the paper large in the corner. Put it there.',
      placed: const ['The tear, the folds and the seal are all the same.', 'This is the paper from the steps.'],
      bagLines: const {
        'flat': 'It is the same flat bag.',
        'buckles': 'It has the same two buckles.',
        'badge': 'It has the same shield badge.',
        'basket': 'That is only a round basket. The bag in your notebook is flat.',
      },
      bagDone: const ['P. saw the same bag again, in a garden.'],
      placeLines: const {
        'louvre': 'There is a palace. But the drawing has no glass pyramid. Is there a round pond?',
        'palaisGarnier': 'That is the opera house. Does it have a garden with a round pond?',
        'montmartre': 'That is the white church. Can you see a palace there?',
      },
      other: 'Find a place with a palace, a round pond and flowerbeds.',
      done: const [
        'The Luxembourg Gardens!',
        'In the drawing, a little clock stands on the grass, with tiny roofs all around it.',
        'Why was the bag next to a little clock in a garden?',
      ],
    ),
  },
  trialMaps: {
    's2_ep09_m1': _map(
      season2TrialMaps['s2_ep09_m1']!,
      wrong: const {'t1': 'Find a big arch on the map.', 't2': 'Find a bridge with green bookstalls.', 't3': 'Find one tall spire, north of the river.'},
      special: const {'t3:notreDame': 'Notre-Dame has two towers. You need one tall spire.'},
    ),
  },
  gearBoards: {'s2_ep09_m2': _gears(season2GearBoards['s2_ep09_m2']!, 'T1, T2 and T3 turn, but the garden clock stays still.')},
  makerMarks: {
    's2_ep09_m3': _plan(season2MakerMarksScenes['s2_ep09_m3']!, const {
      'a:repair': 'Is that shape a gear?',
      'a:key': 'Is that shape a gear?',
      'b:emblem': 'How many hands can you count?',
      'b:key': 'That is a key, not two hands.',
    }),
  },
  towerTests: {
    's2_ep09_final': _tower(
      season2TowerTests['s2_ep09_final']!,
      hours: const {
        5: 'That moves it one hour forward. Go back instead.',
        2: 'That is two hours back. You only need one.',
        4: 'The tower still says four. Turn it one hour back.',
        0: 'Only one hour back: from 4 to 3.',
      },
      tested: const ['Now the tower says three.', 'T1, T2 and T3 changed with it, but the garden clock still says four.'],
      after: const ['The model shows what could happen, but not what really happened.', 'The records may be able to tell us.'],
      question: 'Which trial clock has a star on it?',
      other: 'Look at the sign on each base. You need the star.',
      found: 'The star is on the base of T1.',
      done: const [
        'On the map, T1 stands at the Arc de Triomphe.',
        'Twelve roads meet there, like the points of a star.',
        'Maybe the real records are kept there.',
      ],
    ),
  },
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

/// Cases 07–09's scenes with Master's words.
final masterScenes0709 = (
  morningSketches: {
    's2_ep08_m2': _morning(
      season2MorningSketches['s2_ep08_m2']!,
      lamp: 'The lamp here has gone out. Could this drawing come before the rest?',
      sky: 'Study the skies. Which is the darker one?',
      ordered: 'Darkness, then daylight, and at last the lamp goes out.',
      question: 'What brought the paper to the steps?',
    ),
  },
  tornSlips: {
    's2_ep08_m3': _slip(
      season2TornSlips['s2_ep08_m3']!,
      partLines: const {
        'foldAcross': 'Only folds: P. folded the paper tightly.',
        'foldDown': 'Only folds: P. folded the paper tightly.',
        'tear': 'The opera slip is whole. Can a tear be the same?',
        'dust': 'Just dust, from the steps.',
      },
      sealWrong: const ['Look once more. Does this clock have a single hand?', 'Study the ring that circles the clock.'],
    ),
  },
  tornHours: {
    's2_ep08_final': _corner(
      season2TornHours['s2_ep08_final']!,
      heading: 'Could it be the same paper?',
      tear: 'Match the V-shaped tear. Where does the drawing show it?',
      seal: 'Where does the round seal sit in the drawing?',
      off: 'P. drew the paper large in the corner. Lay it over that.',
      placed: const ['Tear, folds and seal: every detail matches.', 'This is the very paper from the steps.'],
      bagLines: const {
        'flat': 'Flat, just like the bag in the sketch.',
        'buckles': 'Two buckles, just the same.',
        'badge': 'The very same shield badge.',
        'basket': 'A round basket, not a bag. The one in your notebook is flat.',
      },
      bagDone: const ['P. saw the bag once more, this time in a garden.'],
      placeLines: const {
        'louvre': 'A palace, yes. But where is the glass pyramid? And the round pond?',
        'palaisGarnier': 'That is the opera house. Where would its garden and round pond be?',
        'montmartre': 'That is the white church. No palace stands there.',
      },
      other: 'Search for a palace, a round pond and flowerbeds together.',
      done: const [
        'The Luxembourg Gardens!',
        'In the drawing, a little clock rises from the grass, surrounded by tiny roofs.',
        'Why would the bag stand beside a little clock in a garden?',
      ],
    ),
  },
  trialMaps: {
    's2_ep09_m1': _map(
      season2TrialMaps['s2_ep09_m1']!,
      wrong: const {'t1': 'Seek out a great arch.', 't2': 'Seek a bridge lined with green bookstalls.', 't3': 'Seek a single tall spire, north of the river.'},
      special: const {'t3:notreDame': 'Notre-Dame has two towers, not one tall spire.'},
    ),
  },
  gearBoards: {'s2_ep09_m2': _gears(season2GearBoards['s2_ep09_m2']!, 'T1, T2 and T3 turn together; the garden clock never moves.')},
  makerMarks: {
    's2_ep09_m3': _plan(season2MakerMarksScenes['s2_ep09_m3']!, const {
      'a:repair': 'Does that look like a gear?',
      'a:key': 'Does that look like a gear?',
      'b:emblem': 'Count the hands there.',
      'b:key': 'A key, not two hands. Look again.',
    }),
  },
  towerTests: {
    's2_ep09_final': _tower(
      season2TowerTests['s2_ep09_final']!,
      hours: const {
        5: 'That is forward, not back.',
        2: 'Too far: that is two hours back.',
        4: 'The tower still reads four. One hour back, please.',
        0: 'Only a single hour back, from 4 to 3.',
      },
      tested: const ['The tower now reads three.', 'T1, T2 and T3 followed it. The garden clock still reads four.'],
      after: const ['A model can show what might happen. What truly happened is another matter.', 'Perhaps the records will tell.'],
      question: 'Which trial clock bears the star?',
      other: 'Check the sign on its base. Only one shows a star.',
      found: 'The star sits beneath T1.',
      done: const ['T1 belongs to the Arc de Triomphe.', 'Twelve roads meet there, spreading out like a star.', 'Perhaps the real records are kept there.'],
    ),
  },
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

/// The scenes of Cases 07–09 whose words are the same at every level: only
/// ways to play, the papers their puzzles are read from (the Painted
/// Street's line, FILE 3, the programme, the cue card and the slip) and
/// what screen readers say of the pictures.
const sameAtEveryLevel0709 = {
  'flyRails/s2_ep07_m3',
  'lightTables/s2_ep07_final',
  'cornerChoices/s2_ep08_m1',
};

// ═════════════════════════════════════════════════════════════════════════
// The learning design
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

final juniorLearning0709 = <String, LearningObjective>{
  's2_ep07_m1': _learn('s2_ep07_m1', ['DOORS OPEN · 3:30 PM', 'What time did the show really start?']),
  's2_ep07_m2': _learn('s2_ep07_m2', [_turnOn, 'Only one lever is for the ghost light']),
  's2_ep07_m3': _learn('s2_ep07_m3', [_painted, 'look just above its door']),
  's2_ep07_final': _learn('s2_ep07_final', ['What is the new time on FILE 3?', 'switch on the light table']),
  's2_ep08_m1': _learn('s2_ep08_m1', ['A gate between two pillars.', 'Which corner did the painter draw from?']),
  's2_ep08_m2': _learn('s2_ep08_m2', ['First, the sky was dark.', 'When the sun came up, the lamps went out.', 'How did the paper get onto the steps?']),
  's2_ep08_m3': _learn('s2_ep08_m3', ['What matches the opera slip, and what is missing?', 'I found this paper on the steps.']),
  's2_ep08_final': _learn('s2_ep08_final', ['Where did the paper come from?', 'What kind of paper is it?', 'One piece of evidence shows where the paper came from']),
  's2_ep09_m1': _learn('s2_ep09_m1', [_putBack, 'find that shape on the map']),
  's2_ep09_m2': _learn('s2_ep09_m2', [_join, 'Which gear fits it?']),
  's2_ep09_m3': _learn('s2_ep09_m3', ['Find the same two marks on the old paper', 'Signed with two clock hands.']),
  's2_ep09_final': _learn('s2_ep09_final', ['Set the tower one hour back.', 'Only the joined clocks went wrong.', 'What happened to the clocks?']),
};

final masterLearning0709 = <String, LearningObjective>{
  's2_ep07_m1': _learn('s2_ep07_m1', ['DOORS OPEN · 3:30 PM', 'No show begins before its audience has arrived']),
  's2_ep07_m2': _learn('s2_ep07_m2', [_turnOn, 'The photo shows a single lamp']),
  's2_ep07_m3': _learn('s2_ep07_m3', [_painted, 'study what sits above the door']),
  's2_ep07_final': _learn('s2_ep07_final', ['Which is the new time on FILE 3?', 'Whatever was added later sits on top']),
  's2_ep08_m1': _learn('s2_ep08_m1', ['A gate between two pillars.', 'From which corner did the painter make his sketch?']),
  's2_ep08_m2': _learn('s2_ep08_m2', ['First, the sky was dark.', 'When the sun came up, the lamps went out.', 'What brought the paper to the steps?']),
  's2_ep08_m3': _learn('s2_ep08_m3', ['What does this paper share with the opera slip', 'I found this paper on the steps.']),
  's2_ep08_final': _learn('s2_ep08_final', ['Where did the paper come from?', 'What kind of paper is it?', 'Ask what each piece of evidence proves']),
  's2_ep09_m1': _learn('s2_ep09_m1', [_putBack, 'Each little clock copies a building']),
  's2_ep09_m2': _learn('s2_ep09_m2', [_join, 'Connect the tower to the trial clocks']),
  's2_ep09_m3': _learn('s2_ep09_m3', ['Find where both marks appear on the old paper', 'Signed with two clock hands.']),
  's2_ep09_final': _learn('s2_ep09_final', ['Set the tower one hour back.', 'Only the joined clocks went wrong.', 'What did the test show?']),
};
