import '../../../models/learning.dart';
import 'level_words.dart';

// Case 03 — The Tower's Secret, at each level (PART 7A): the words only
// (`docs/difficulty_reviews/PARIS_CASE_01_03.md`).

const _words03 = {
  'apart': '(시간이) 떨어진, 차이가 나는',
  'agree': '일치하다',
  'holder': '꽂이, 거치대',
  'staff': '직원',
  'plaque': '명판',
  'recording': '기록하는',
  'piece': '한 개, 조각',
  'pieces': '여러 개, 조각들',
  'wheels': '바퀴들',
  'locked': '잠긴',
};

const _rookieOnly03 = {'describe': '설명하다'};

/// The inspection note at the iron door, as pinned (not in order).
const _steps =
    'INSPECTION STEPS\n\n'
    'Finally, turn the key.\n'
    'First, check the clock.\n'
    'Next, stop the lift.';

/// The two time cards.
const _cards =
    'OFFICIAL TIME — 4:00\n'
    'RECORDED TIME — 3:00\n\n';

/// The evidence board's lines for each wrong link (the keys are the
/// answers, as the base has them), written per level.
Map<String, String> _boardLines({
  required String records,
  required String onlyRecords,
  required String trips,
  required String onlyTrips,
  required String twoPieces,
  required String notThere,
  required String door,
  required String why,
  required String still,
}) => {
      for (final s in ['', 'e2', 'e3', 'e2+e3']) 'q1:$s': records,
      for (final s in ['e1+e2', 'e1+e3', 'e1+e2+e3']) 'q1:$s': onlyRecords,
      for (final s in ['', 'e1', 'e3', 'e1+e3']) 'q2:$s': trips,
      for (final s in ['e1+e2', 'e2+e3', 'e1+e2+e3']) 'q2:$s': onlyTrips,
      'q3:': twoPieces,
      for (final s in ['e1', 'e1+e2', 'e1+e3', 'e1+e2+e3']) 'q3:$s': notThere,
      'q3:e2': door,
      // The room alone: the same question at every level.
      'q3:e3': 'You found the room. But what shows that someone went up there?',
      'why:': why,
      // No level says more than the evidence does.
      'why:vanished': 'We have no proof of that yet.',
      'why:still': still,
    };

/// The plaque, then the tag that sends the case to the river. Its riddle,
/// SEINE and the last two questions stay as they are.
List<String> _plaque({required String under, required String river, required String tag}) => [
      'One hour is missing.',
      'The clock is still running.',
      under,
      'SEINE.',
      river,
      tag,
      'FROM: SERVICE LEVEL. TO: THE RIVER.',
      'Who left this message?',
      'And why does it lead to the river?',
    ];

const rookie03 = <String, Object?>{'glossary': {..._words03, ..._rookieOnly03}};

final junior03 = <String, Object?>{
  'synopsis': [
    "The painter's last message said: ALWAYS HIGHER.",
    'Next to it, he drew a small picture of a tall iron tower.',
    'At the Eiffel Tower, two records do not agree.',
  ],
  'objectives': [
    'Compare the two records line by line.',
    'Find out where the lift went.',
    'Open the locked iron door.',
  ],
  // Second person; no time and no number of hours before the records are
  // read (as the game's own words).
  'intro': [
    'The painter left one last message: Always higher.',
    'You turn the canvas over again. Next to the words is a small drawing.',
    'It shows a tall iron tower: the Eiffel Tower.',
    'At its entrance, two records tell you about the same inspection. But they do not match.',
  ],
  'caseSummary': 'Two records were one hour apart. In that hour, someone went up to the Service Level.',
  'hook': 'Who left the plaque about the missing hour? And why does it point to the river?',
  'glossary': {
    ..._words03,
    'compare': '비교하다',
    'drew': '그렸다',
    'point': '가리키다',
    'written': '쓰인',
    'ride': '타다',
    'stands': '서 있다',
    'link': '연결하다',
    'answers': '답하다',
  },
  'missions': {
    's2_ep03_m1': {
      'story': [
        'At the foot of the tower, the lamps are coming on.',
        'By the gate is a notice for visitors. In the ticket booth is the maintenance log.',
      ],
      'letterIntro': 'You write in your notebook:',
      'letter':
          'Two records.\n'
          'The same day. The same job.\n\n'
          'Compare them line by line.\n'
          'Find the two lines that do not match.',
      'question': 'Which two lines do not match?',
      'feedback': {
        'date:date': 'Both records say 12 MAY. The dates are the same.',
        'job:job': 'Both records say LIFT INSPECTION. The jobs are the same.',
        for (final pair in ['date:job', 'date:time', 'job:date', 'job:time', 'time:date', 'time:job'])
          pair: 'Compare the same line on both records: date with date, time with time.',
      },
      'hints': [
        'Read each record one line at a time: the date, the job, the time.',
        'The date is the same on both. So is the job. Now look at the time.',
      ],
      'successMessage': 'The times on the two records do not match!',
      'transition': [
        'The visitor notice says 4:00, but the maintenance log says 3:00.',
        'Same day. Same job. But one hour apart.',
        'At the bottom of the log, someone has written in pencil: CHECK THE LIFT LOG.',
      ],
      'clue': {'note': 'At the bottom of the maintenance log, a pencil note: CHECK THE LIFT LOG.'},
      'evidence': {'description': 'Two records found at the entrance of the Eiffel Tower.'},
    },
    's2_ep03_m2': {
      'story': [
        'On one wall of the old lift is a brass route plate. On the other is the lift log.',
        "Where did the lift go after three o'clock?",
      ],
      'letterIntro': 'You check your notebook:',
      'letter':
          'CHECK THE LIFT LOG.\n\n'
          'Read every trip in the log.\n'
          'One stop is not written.\n'
          'The route plate shows every stop.',
      'question': 'At 3:20, where did the lift go?',
      'options': {
        'ground': {'feedback': 'At 4:25, the lift came back down to Ground. Where was it before that?'},
        'first': {'feedback': 'First is a stop for passengers. The 3:20 trip has an S next to it. What does S mean?'},
        'top': {'feedback': 'Top is a stop for passengers. The 3:20 trip has an S next to it. What does S mean?'},
      },
      'hints': [
        'Find the S in the lift log. Then look for S on the route plate.',
        'On the plate, S = SERVICE RUN. Which stop is only on the service route?',
      ],
      'successMessage': 'You found the stop that was missing from the log!',
      'transition': [
        'At 3:20, the lift went up to the Service Level. It did not come back down until 4:25.',
        'You ride the lift up. The gates open onto a dark iron platform.',
        'On an iron door, there is a sign: SERVICE ACCESS ONLY.',
      ],
      'clue': {'note': 'At the Service Level, there is a sign on an iron door: SERVICE ACCESS ONLY.'},
      'evidence': {'description': 'It hangs in a holder on the wall of the lift.'},
    },
    's2_ep03_m3': {
      'story': [
        'The Service Level is dark and quiet. Visitors never come up here.',
        'A heavy padlock with three dials keeps the iron door shut.',
      ],
      'letterIntro': 'Next to the door, someone has pinned a note:',
      'letter': _steps,
      'question': 'Set the three dials in the right order. Then open the lock.',
      'orderFeedback': 'The pictures are right, but the order is wrong. Read the note: FIRST, NEXT, FINALLY.',
      'hints': [
        'Read the note again. The words FIRST, NEXT and FINALLY tell you the order.',
        'Dial 1 is the step you do FIRST. Dial 2 is NEXT. Dial 3 is FINALLY.',
      ],
      'successMessage': 'The padlock is open!',
      'transition': [
        'Click! Behind the iron door is a small hidden room.',
        'There are wheels, cables and gears. At the back stands an old machine with a clock.',
        'On the floor is a square mark in the dust. A heavy crate stood here. Now it is gone.',
      ],
      'clue': {'note': 'Behind the iron door is a small machine room. Only the service staff can go in.'},
      'evidence': {'description': 'Found behind the locked iron door at the Service Level.'},
    },
    's2_ep03_final': {
      'story': [
        'The old machine has a slot for time cards. There are two cards inside.',
        'What really happened at the tower?',
      ],
      'letterIntro': 'You read the two time cards:',
      'letter':
          '${_cards}One hour apart, just like the two records\n'
          'at the entrance.',
      'question': 'Link each question to the evidence that answers it.',
      'feedback': _boardLines(
        records: 'Question 1 is about the inspection records. Which evidence shows those records?',
        onlyRecords: 'Question 1 needs just one piece: the two records.',
        trips: 'Which evidence shows where the lift went?',
        onlyTrips: 'Question 2 needs just one piece: the one that shows where the lift went.',
        twoPieces: 'Question 3 needs two pieces. Where did the lift go? And what was up there?',
        notThere: 'The notices were down at the entrance. Question 3 is about the service area.',
        door: 'The lift log shows where the lift went. What did you find behind the iron door?',
        why: 'Choose what the evidence really shows.',
        still: 'Look at the lift log again. The lift went up at 3:20.',
      ),
      'hints': [
        'Open each piece of evidence and ask: what does this one show?',
        'Question 3 needs two pieces: one shows where the lift went, one shows what was behind the door.',
      ],
      'successMessage': 'All the evidence fits together!',
      'transition': _plaque(
        under: 'Under the words are three small waves and one word.',
        river: 'It is the river that runs through Paris.',
        tag: 'Next to the square mark in the dust is a torn shipping tag:',
      ),
      'evidence': {'description': 'It was hidden inside the time-recording machine.'},
    },
  },
};

final master03 = <String, Object?>{
  'synopsis': [
    "The painter's final message read: ALWAYS HIGHER.",
    'Beside it, he had sketched a tall iron tower.',
    'At the Eiffel Tower, two official records refuse to agree.',
  ],
  'objectives': [
    'Compare the two records closely.',
    "Trace the lift's secret journey.",
    'Get past the locked iron door.',
  ],
  'intro': [
    'The painter left one last message: Always higher.',
    'You turn the canvas over again. Beside the words, a small drawing catches your eye.',
    'A tall iron tower. The Eiffel Tower.',
    'At its entrance, two records describe the very same inspection, yet they disagree.',
  ],
  'caseSummary': 'Two records, one hour apart. In that hour, someone slipped up to the Service Level.',
  'hook': 'Who left the plaque about the missing hour, and why does it lead to the river?',
  'glossary': {
    ..._words03,
    ..._rookieOnly03,
    'final': '마지막의',
    'sketched': '스케치했다',
    'refuse': '거부하다',
    'closely': '자세히',
    'trace': '추적하다',
    'journey': '이동, 여정',
    'catches': '(your eye) 눈길을 끌다',
    'disagree': '일치하지 않다',
    'slipped': '몰래 들어갔다',
    'evening': '저녁',
    'flicker': '깜빡이다',
    'reminds': '상기시키다',
    'somewhere': '어딘가에서',
    'claims': '주장하다',
    'insists': '우기다, 강조하다',
    'scrawled': '휘갈겨 쓴',
    'gleams': '반짝이다',
    'hangs': '걸려 있다',
    'really': '실제로',
    'study': '살펴보다',
    'unwritten': '쓰이지 않은',
    'heading': '향하는',
    'returned': '돌아왔다',
    'single': '하나의',
    'climbed': '올라갔다',
    'bears': '(표시를) 달고 있다',
    'silent': '조용한',
    'guards': '지키다',
    'demands': '요구하다',
    'jumbled': '뒤죽박죽인',
    'purpose': '(on purpose) 일부러',
    'swings': '활짝 열리다',
    'crouches': '웅크리고 있다',
    'once': '예전에; ~하면',
    'meant': '~을 위한',
    'truly': '정말로',
    'connect': '연결하다',
    'concerns': '~에 관한 것이다',
    'holds': '담고 있다',
    'traces': '추적하다, 보여 주다',
    'prove': '증명하다',
    'proves': '증명하다',
    'waited': '기다리고 있었다',
    'examine': '살펴보다',
    'pair': '짝짓다',
    'destination': '목적지',
    'concealed': '숨겨진',
    'winds': '굽이굽이 흐르다',
    'alone': '~만으로',
    'enough': '충분한',
  },
  'missions': {
    's2_ep03_m1': {
      'story': [
        'At the foot of the tower, the evening lamps flicker on.',
        'By the gate hangs a notice for visitors. Inside the ticket booth lies the maintenance log.',
      ],
      'letterIntro': 'Your notebook reminds you:',
      'letter':
          'Two records.\n'
          'The same day. The same job.\n\n'
          'Somewhere, they disagree.\n'
          'Find the two lines that do not match.',
      'question': 'Where do the two records disagree?',
      'feedback': {
        'date:date': 'Both records give 12 MAY. No difference there.',
        'job:job': 'Both records name LIFT INSPECTION. No difference there.',
        for (final pair in ['date:job', 'date:time', 'job:date', 'job:time', 'time:date', 'time:job'])
          pair: 'Compare like with like: date with date, time with time.',
      },
      'hints': [
        'A careful detective reads every line on both records.',
        'Two of the three lines agree perfectly. The last one tells a different story.',
      ],
      'successMessage': 'The two records disagree on the time!',
      'transition': [
        'The visitor notice claims 4:00. The maintenance log insists on 3:00.',
        'Same day, same job, yet one hour apart.',
        'Scrawled in pencil at the bottom of the log: CHECK THE LIFT LOG.',
      ],
      'clue': {'note': 'Scrawled in pencil at the bottom of the maintenance log: CHECK THE LIFT LOG.'},
      'evidence': {'description': 'Two records from the entrance of the Eiffel Tower.'},
    },
    's2_ep03_m2': {
      'story': [
        'On one wall of the old lift gleams a brass route plate. On the other hangs the lift log.',
        "After three o'clock, where did the lift really go?",
      ],
      'letterIntro': 'Your notebook reads:',
      'letter':
          'CHECK THE LIFT LOG.\n\n'
          'Study every trip.\n'
          'One stop has been left unwritten.\n'
          'The route plate knows every stop.',
      'question': 'Where was the lift heading at 3:20?',
      'options': {
        'ground': {'feedback': 'The lift returned to Ground at 4:25. But where had it been until then?'},
        'first': {'feedback': 'First is a passenger stop. Yet the 3:20 trip carries an S. What could that mean?'},
        'top': {'feedback': 'Top is a passenger stop. Yet the 3:20 trip carries an S. What could that mean?'},
      },
      'hints': [
        'The log keeps a secret in a single letter. The route plate can explain it.',
        'Once you know that S = SERVICE RUN, ask which stop only a service run can reach.',
      ],
      'successMessage': 'The unwritten stop is found!',
      'transition': [
        'At 3:20, the lift climbed to the Service Level. It did not return to Ground until 4:25.',
        'You ride up. The brass gates slide open onto a dark iron platform.',
        'An iron door bears a sign: SERVICE ACCESS ONLY.',
      ],
      'clue': {'note': 'At the Service Level, an iron door bears a sign: SERVICE ACCESS ONLY.'},
      'evidence': {'description': 'Kept in a brass holder on the wall of the lift.'},
    },
    's2_ep03_m3': {
      'story': [
        'The Service Level is dark and silent. No visitor ever comes this far.',
        'A heavy padlock with three dials guards the iron door.',
      ],
      'letterIntro': 'Pinned beside the door is a note:',
      'letter': _steps,
      'question': 'Set the dials in the order the note demands, then open the lock.',
      'orderFeedback': "The right pictures, but in the wrong order. The note's FIRST, NEXT and FINALLY decide it.",
      'hints': [
        'The note is jumbled on purpose. Its order words matter more than the order of its lines.',
        'Each dial is one step. Let the first dial hold the step that comes FIRST.',
      ],
      'successMessage': 'The padlock gives way!',
      'transition': [
        'Click. The iron door swings open onto a small hidden room.',
        'Wheels, cables and gears fill the space. At the back crouches an old machine with a clock.',
        'On the floor, a square mark in the dust. A heavy crate once stood here. Now it is gone.',
      ],
      'clue': {'note': 'Behind the iron door: a small machine room, meant only for the service staff.'},
      'evidence': {'description': 'Hidden behind the locked iron door at the Service Level.'},
    },
    's2_ep03_final': {
      'story': [
        'The old machine has a slot for time cards. Two cards are still inside.',
        'So what truly happened at the tower?',
      ],
      'letterIntro': 'The two time cards read:',
      'letter':
          '${_cards}One hour apart, exactly like the two records\n'
          'at the entrance.',
      'question': 'Connect each question to the evidence that answers it.',
      'feedback': _boardLines(
        records: 'Question 1 concerns the inspection records. Which evidence holds them?',
        onlyRecords: 'For question 1, the two records alone are enough.',
        trips: "Which evidence traces the lift's trips?",
        onlyTrips: 'Question 2 needs only one piece: the record of where the lift went.',
        twoPieces: 'Question 3 needs two pieces. Where did the lift go, and what waited there?',
        notThere: 'The notices stayed down at the entrance. Question 3 concerns the service area.',
        door: 'The lift log proves where the lift went. But what was behind the door?',
        why: 'Choose only what the evidence can prove.',
        still: 'Check the lift log again. The lift went up at 3:20.',
      ),
      'hints': [
        'Examine each piece of evidence. Ask what it proves, and what it does not.',
        'One question cannot be answered by a single piece. Pair the journey with its destination.',
      ],
      'successMessage': 'Every piece of evidence falls into place!',
      'transition': _plaque(
        under: 'Beneath the words: three small waves, and a single word.',
        river: 'The river that winds through Paris.',
        tag: 'Beside the square mark in the dust lies a torn shipping tag:',
      ),
      'evidence': {'description': 'Concealed inside the time-recording machine.'},
    },
  },
};

// ═════════════════════════════════════════════════════════════════════════
// The learning design
// ═════════════════════════════════════════════════════════════════════════

final juniorLearning03 = <String, LearningObjective>{
  's2_ep03_m1': levelObjectiveWith('s2_ep03_m1', expressions: ['The same day. The same job.', 'Compare them line by line', 'Find the two lines that do not match']),
  's2_ep03_m2': levelObjectiveWith('s2_ep03_m2', expressions: ['One stop is not written', 'S = SERVICE RUN']),
  's2_ep03_m3': levelObjectiveWith('s2_ep03_m3', expressions: ['First, check the clock.', 'Next, stop the lift.', 'Finally, turn the key.']),
  's2_ep03_final': levelObjectiveWith(
    's2_ep03_final',
    expressions: ['What was wrong with the inspection records?', 'What can we conclude?', 'the evidence that answers it'],
  ),
};

final masterLearning03 = <String, LearningObjective>{
  's2_ep03_m1': levelObjectiveWith('s2_ep03_m1', expressions: ['The same day. The same job.', 'Somewhere, they disagree', 'Where do the two records disagree?']),
  's2_ep03_m2': levelObjectiveWith('s2_ep03_m2', expressions: ['One stop has been left unwritten', 'S = SERVICE RUN']),
  's2_ep03_m3': levelObjectiveWith(
    's2_ep03_m3',
    expressions: ['First, check the clock.', 'Next, stop the lift.', 'Finally, turn the key.', 'the order the note demands'],
  ),
  's2_ep03_final': levelObjectiveWith(
    's2_ep03_final',
    expressions: ['What was wrong with the inspection records?', 'What can we conclude?', 'what it proves, and what it does not'],
  ),
};
