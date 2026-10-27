import '../../../models/discovery.dart';
import '../../../models/learning.dart';

// Case 05 — The Locked Room, at each level.
//
// The facts never move: the gates close at five o'clock (M1's clue 5), four
// brass gears around the dial (M2's clue 4), six ravens and one more (M3's
// clue 7), and the lid's three questions — ravens, then gears, then gates —
// give the final's order, 745 (the found order 547 gets the order line).
// The locks have no pictures (TYPE B), so the lid's three question lines are
// puzzle data: word for word at every level. The card's directions (left at
// the cannon, third floor, on the right), the dial's four lines (left, the
// other way, as the first time, as the second time) and the sign's "six …
// and one more" keep their logic at every level. The Old Map Fragment
// (Case 07), the Brass Key "FOR THE CLOCKMAKER'S DOOR" and Seven Ravens
// (Case 12) keep their names and inscriptions.
//
// Intentionally identical at every level (fields still written in both
// patches):
// * ep05_m3.prompt — '_____ RAVENS' (how the answer is typed);
// * ep05_final.question — 'Open the three locks.' (how to play it).
// Lines kept word for word inside otherwise rewritten fields:
// * ep05_final.letter — the three lock questions ("The first lock: how many
//   ravens live at the Tower?", "The second lock: how many gears are on the
//   door?", "The third lock: what time do the gates close?");
// * ep05_final.story[0] — 'The iron chest is cold and heavy.';
// * ep05_m3.transition — first line, the warning on the wall and the last
//   line; the line before the warning still begins "On the wall";
// * ep05_final.transition — 'The iron chest is open.', the remembered
//   warning '"At midnight,\nthe Clockmaker will stop London."' and
//   "FOR THE CLOCKMAKER'S DOOR.";
// * hook — the warning '"At midnight, the Clockmaker will stop London."'.
//
// Rookie: the base.

const Map<String, Object?> ep05Rookie = {};

// ── Junior ───────────────────────────────────────────────────────────────
const Map<String, Object?> ep05Junior = {
  'synopsis': [
    'A room in the Tower of London has been locked for a hundred years.',
    'But tonight, its door is open.',
    'There is no keyhole: just a dial and a note.',
  ],
  'intro': [
    "Tower of London, five o'clock in the evening...",
    'The Raven Society sent its letter from this place.',
    'The Ravenmaster is waiting for you at the gate.',
    '"There is a room in the White Tower that was locked for a hundred years," he tells you.',
    '"Nobody has the key. But this morning, we found its door open."',
  ],
  'caseSummary': 'You followed every direction, turned the dial the right way and got into the locked room.',
  'hook': 'Someone wrote on the wall of the room: "At midnight, the Clockmaker will stop London."',
  'glossary': {
    'bang': '쾅 (하는 소리)',
    'direction': '길 안내, 지시',
    'directions': '길 안내, 지시',
    'climb': '오르다',
    'quick': '빠른 (be quick: 서둘러라)',
    'swings': '휙 움직이다 (swing open: 활짝 열리다)',
    'shining': '반짝이는',
    'stares': '빤히 쳐다보다',
    'digit': '숫자 (0~9)',
    'letters': '글자',
    'tightly': '단단히, 꽉',
    'piece': '조각',
    'order': '순서',
  },
  'missions': {
    'ep05_m1': {
      'story': [
        "At five o'clock, the gates of the Tower close.",
        'The Ravenmaster lets you in, and the big gate shuts behind you with a bang.',
      ],
      'letterIntro': 'On a small card, he draws the way to the room.',
      'letter': 'Walk past the ravens.\n'
          'At the old cannon, turn left.\n'
          'Climb the stairs up to the third floor.\n'
          'The door is on your right.\n\n'
          'Be quick. The Tower is closed now.',
      'question': 'Where will you find the locked room?',
      'options': {
        'a': {'feedback': 'Count the floors again. Which floor does the card tell you to go to?'},
        'b': {'feedback': 'Yes, the third floor! But which side is the door on? Read the line about the door.'},
        'd': {'feedback': 'You turn at the cannon. The door is somewhere else.'},
      },
      'hints': [
        'There are two directions on the card. One is for outside. The other is for the top of the stairs.',
        "The third floor is three floors up. And 'on your right' means the side of your right hand.",
      ],
      'clue': {'note': "The gates of the Tower close at five o'clock."},
      'evidence': {'description': "The Ravenmaster's directions to the locked room."},
      'successMessage': 'You found the way: third floor, on the right!',
      'transition': [
        'You climb the old stairs up to the third floor.',
        'On your right, there is a heavy wooden door.',
        'But it has no keyhole. There is only a round brass dial.',
      ],
    },
    'ep05_m2': {
      'story': [
        'Four brass gears sit around the dial.',
        'The dial turns two ways: to the left or to the right.',
      ],
      'letterIntro': 'Someone has carved a note into the door.',
      'letter': 'First, turn the dial to the left.\n'
          'Next, turn it the other way.\n'
          'After that, turn it the same way as the first time.\n'
          'Last of all, turn it the same way as the second time.',
      'question': 'Turn the dial four times, just as the note says.',
      'hints': [
        'Each line of the note is one turn. You already know turn 1 from the first line.',
        "'The other way' means the opposite way. 'The same way as the first time' is just like turn 1.",
      ],
      'feedback': {
        'left,left,left,left': "'The other way' does not mean the same way again. What is the opposite of left?",
        'left,right,right,left': "Look at turn 3 again: 'the same way as the first time'. Which way was turn 1?",
      },
      'orderFeedback':
          'You have the right number of left turns and right turns, but the order is wrong. Check each turn against its line.',
      'clue': {'note': 'Four brass gears were placed around the dial.'},
      'evidence': {'description': 'Someone carved it into the door.'},
      'successMessage': 'Click, clack! The heavy door swings open.',
      'transition': [
        'Inside, a candle is still warm. Someone was just here!',
        'On the table, there is a box of food for the ravens.',
        'Something inside it is shining.',
      ],
    },
    'ep05_m3': {
      'story': [
        'A raven hops onto the window and stares at you.',
        'There is a lock on the food box, and it needs a word.',
      ],
      'letterIntro': 'The Ravenmaster reads the old sign on the wall out loud.',
      'letter': 'An old story says:\n'
          'if the ravens ever leave the Tower, the Tower will fall.\n\n'
          'So six ravens always live here...\n'
          'and there is one more, just in case.',
      'question': 'How many ravens live at the Tower? Type the number as a word.',
      // How the answer is typed: the same at every level.
      'prompt': '_____ RAVENS',
      'hints': [
        'Look at the last two lines of the sign: "six ravens" and "one more".',
        'Start with six, then add one more. Write the number in letters, not as a digit.',
      ],
      'feedback': {
        'SIX': "Six ravens... is that all? Read the last line: 'one more'.",
        '6': "Six ravens... is that all? Read the last line: 'one more'.",
      },
      'clue': {'note': 'Six ravens, plus one more just in case.'},
      'evidence': {'description': "It was hidden in the ravens' food box."},
      'successMessage': 'There are seven ravens!',
      'transition': [
        'Behind the food box, there is an iron chest.',
        'It has three locks, and there are words painted on its lid.',
        'On the wall above the chest, someone has written:',
        '"At midnight, the Clockmaker will stop London."',
        'The Clockmaker... who is that?',
      ],
    },
    'ep05_final': {
      'story': [
        'The iron chest is cold and heavy.',
        'Three number locks keep it tightly shut.',
      ],
      'letterIntro': 'Some words are painted on the lid.',
      'letter': 'Open the locks one at a time, from left to right.\n\n'
          'The first lock: how many ravens live at the Tower?\n'
          'The second lock: how many gears are on the door?\n'
          'The third lock: what time do the gates close?\n\n'
          'Your notebook has every answer.',
      // How to play it: the same at every level.
      'question': 'Open the three locks.',
      'hints': [
        'Every lock asks its own question, and your clues can answer each one.',
        'Read the questions on the lid from top to bottom. Find each answer in your Notebook, and keep the same order.',
      ],
      'orderFeedback': 'Those numbers are in the order you found them. Read the lid again: which question comes first?',
      'evidence': {'description': 'One half of an old map of London.'},
      'successMessage': 'You opened the iron chest!',
      'transition': [
        'The iron chest is open.',
        'Inside, there is a piece of an old map.',
        'Someone has drawn a small raven\nby a bridge in Hyde Park.',
        'Then you remember the words\nsomeone wrote on the wall:',
        '"At midnight,\nthe Clockmaker will stop London."',
        'And you still have the brass key.',
        "FOR THE CLOCKMAKER'S DOOR.",
      ],
    },
  },
};

// ── Master ───────────────────────────────────────────────────────────────
const Map<String, Object?> ep05Master = {
  'synopsis': [
    'For a hundred years, a room in the Tower has stayed sealed.',
    'Tonight, its door stands open.',
    'No keyhole waits there, only a dial and a note.',
  ],
  'intro': [
    'The Tower of London, 5:00 PM, as the light begins to fade...',
    'It was from here that the Raven Society sent its letter.',
    'At the gate, the Ravenmaster stands waiting for you.',
    '"For a hundred years, a room in the White Tower has stayed locked," he says quietly.',
    '"No one holds its key. Yet this morning, its door stood open."',
  ],
  'caseSummary': 'You obeyed every command, turned the dial the proper way and unlocked the sealed room.',
  'hook': 'Scrawled on the wall of the room: "At midnight, the Clockmaker will stop London."',
  'glossary': {
    'sealed': '봉인된, 꽉 닫힌',
    'fade': '희미해지다',
    'holds': '가지고 있다',
    'obeyed': '따랐다, 복종했다',
    'command': '명령',
    'commands': '명령하다',
    'proper': '올바른',
    'scrawled': '휘갈겨 쓴',
    'sharp': '(시각) 정각에',
    'ushers': '안내하다',
    'thuds': '쿵 하고 닫히다',
    'sketches': '대충 그리다',
    'route': '길, 경로',
    'haste': '서두름 (make haste: 서둘러라)',
    'lie': '있다, 놓여 있다',
    'lies': '있다, 놓여 있다',
    'turning': '방향을 트는 (turning point: 꺾이는 지점)',
    'towards': '~ 쪽으로',
    'worn': '닳은',
    'single': '단 하나의',
    'exactly': '정확히',
    'glints': '반짝 빛나다',
    'ledge': '(창문) 턱',
    'fixes': '(눈길을) 고정하다',
    'fastened': '잠긴, 채워진',
    'legend': '전설',
    'kept': '두어지는, 지켜지는',
    'total': '합계',
    'concealed': '숨겨진',
    'guard': '지키다',
    'poses': '(질문을) 던지다',
    'supply': '제공하다',
    'firmly': '단단히',
    'creaks': '삐걱거리다',
    'within': '~ 안에',
    'fragment': '조각',
    'keeping': '보관 (in your keeping: 네가 지니고 있는)',
    'yields': '(힘에) 굴복하다, 열리다',
    'surrounded': '둘러쌌다',
  },
  'missions': {
    'ep05_m1': {
      'story': [
        "At five o'clock sharp, the gates of the Tower close for the night.",
        'The Ravenmaster ushers you inside, and the great gate thuds shut behind you.',
      ],
      'letterIntro': 'On a card, he sketches the route to the room.',
      'letter': 'Make your way past the ravens.\n'
          'When you reach the old cannon, turn left.\n'
          'Climb the stairs as far as the third floor.\n'
          'The door will be on your right.\n\n'
          'Make haste. The Tower is closed now.',
      'question': 'Where does the locked room lie?',
      'options': {
        'a': {'feedback': 'Count the floors once more. How far up does the card send you?'},
        'b': {'feedback': 'The floor is correct, but which side? The line about the door decides it.'},
        'd': {'feedback': 'The cannon only marks where you turn. The door lies further on.'},
      },
      'hints': [
        'The route has two turning points: one in the open air, and one where the stairs end.',
        'How many floors does the card make you climb? And at the top, which hand does the door lie towards?',
      ],
      'clue': {'note': "The gates of the Tower shut at five o'clock."},
      'evidence': {'description': 'A hand-drawn route to the locked room.'},
      'successMessage': 'The third floor, on the right: the way is clear!',
      'transition': [
        'You climb the worn stone stairs to the third floor.',
        'On your right stands a heavy wooden door.',
        'Yet it has no keyhole, only a round brass dial.',
      ],
    },
    'ep05_m2': {
      'story': [
        'Four brass gears are set in a ring around the dial.',
        'The dial will turn only two ways: left or right.',
      ],
      'letterIntro': 'A note has been carved deep into the door.',
      'letter': 'First, turn the dial to the left.\n'
          'Then, turn it the other way.\n'
          'After that, turn it as you did the first time.\n'
          'Finally, turn it as you did the second time.',
      'question': 'Turn the dial four times, exactly as the door commands.',
      'hints': [
        'Every line of the note commands a single turn, and the first line has already given you turn 1.',
        'Which way is opposite to the first turn? And when a line sends you back to an earlier time, copy that turn exactly.',
      ],
      'feedback': {
        'left,left,left,left': "Turning 'the other way' cannot mean turning the same way again. What is the opposite of left?",
        'left,right,right,left': 'Look closely at turn 3: it repeats the first time. Which way did turn 1 go?',
      },
      'orderFeedback':
          'There is the right number of left and right turns here, but their order does not follow the four lines.',
      'clue': {'note': 'A ring of four brass gears was set around the dial.'},
      'evidence': {'description': 'Carved deep into the wooden door.'},
      'successMessage': 'Click, clack! The lock gives way, and the door swings open.',
      'transition': [
        'Inside, a candle is still warm. Someone has been here, and not long ago!',
        "On the table stands a box that holds the ravens' food.",
        'Something glints inside it.',
      ],
    },
    'ep05_m3': {
      'story': [
        'A raven hops onto the window ledge and fixes you with one black eye.',
        'The food box is fastened with a lock that waits for a word.',
      ],
      'letterIntro': 'The Ravenmaster reads aloud from the old sign on the wall.',
      'letter': 'An old legend says:\n'
          'should the ravens ever leave the Tower, the Tower will fall.\n\n'
          'So six ravens are always kept here...\n'
          'and one more, just in case.',
      'question': 'How many ravens are kept at the Tower? Type the number word.',
      // How the answer is typed: the same at every level.
      'prompt': '_____ RAVENS',
      'hints': [
        'The sign does not end with the six. What does its last line add?',
        'Put together what the last two lines tell you, and spell out the total in letters.',
      ],
      'feedback': {
        'SIX': "Only six? The final line speaks of 'one more'.",
        '6': "Only six? The final line speaks of 'one more'.",
      },
      'clue': {'note': 'Six ravens are always kept, and one more just in case.'},
      'evidence': {'description': "Concealed in the ravens' food box."},
      'successMessage': 'Seven ravens guard the Tower!',
      'transition': [
        'Behind the food box, there is an iron chest.',
        'Three locks hold it shut, and words are painted across its lid.',
        'On the wall above the chest, a hand has scrawled:',
        '"At midnight, the Clockmaker will stop London."',
        'The Clockmaker... who is that?',
      ],
    },
    'ep05_final': {
      'story': [
        'The iron chest is cold and heavy.',
        'Three number locks hold it firmly shut.',
      ],
      'letterIntro': 'Painted across the lid are these words.',
      'letter': 'Open the locks in turn, from left to right.\n\n'
          'The first lock: how many ravens live at the Tower?\n'
          'The second lock: how many gears are on the door?\n'
          'The third lock: what time do the gates close?\n\n'
          'Your notebook holds the answers.',
      // How to play it: the same at every level.
      'question': 'Open the three locks.',
      'hints': [
        'Each lock poses a question. Which of your clues answers which question?',
        'The lid sets its own order, and it is not the order in which you found the clues. Let your Notebook supply each number.',
      ],
      'orderFeedback': 'That is simply the order in which you found the clues. Which question does the lid ask first?',
      'evidence': {'description': 'One half of an aged map of London.'},
      'successMessage': 'The iron chest creaks open!',
      'transition': [
        'The iron chest is open.',
        'Within lies a fragment of an old map.',
        'A small raven has been drawn\nby a bridge in Hyde Park.',
        'Then you remember the words\nscrawled on the wall:',
        '"At midnight,\nthe Clockmaker will stop London."',
        'And the brass key is still in your keeping.',
        "FOR THE CLOCKMAKER'S DOOR.",
      ],
    },
  },
};

// ── Discovery Moments ────────────────────────────────────────────────────
const Map<String, Discovery> ep05JuniorDiscoveries = {
  'ep05_m1': Discovery(
    type: DiscoveryType.newLead,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'THIRD FLOOR, ON THE RIGHT',
    detail: 'Turn left at the old cannon, then climb the stairs: that is the way to the locked room.',
    note: "The gates of the Tower close at five o'clock.",
  ),
  'ep05_m2': Discovery(
    type: DiscoveryType.newLead,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'THE DOOR IS OPEN',
    detail: 'Left, right, left, right: the dial turns, and the locked room opens.',
    note: 'Four brass gears sat around the dial.',
  ),
  'ep05_m3': Discovery(
    type: DiscoveryType.evidenceFound,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'BRASS KEY',
    detail: 'Seven ravens: the food box opens, and there is a key hidden inside.',
    showEvidence: true,
    seasonClue: true,
  ),
};

const Map<String, Discovery> ep05MasterDiscoveries = {
  'ep05_m1': Discovery(
    type: DiscoveryType.newLead,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'THIRD FLOOR, ON THE RIGHT',
    detail: 'A left turn at the old cannon, a climb up the stairs: the route to the locked room.',
    note: "At five o'clock, the gates of the Tower are shut.",
  ),
  'ep05_m2': Discovery(
    type: DiscoveryType.newLead,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'THE DOOR IS OPEN',
    detail: 'Left, right, left, right: the dial yields, and the sealed room lies open.',
    note: 'A ring of four brass gears surrounded the dial.',
  ),
  'ep05_m3': Discovery(
    type: DiscoveryType.evidenceFound,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'BRASS KEY',
    detail: 'Seven ravens: the food box gives way, and a key lies hidden within.',
    showEvidence: true,
    seasonClue: true,
  ),
};

// ── The parent report's English ──────────────────────────────────────────
const Map<String, LearningObjective> ep05JuniorLearning = {
  'ep05_m1': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.sentenceMeaning,
    objective: '길 안내 지시문(왼쪽·층·오른쪽)을 읽고 방의 위치를 고른다.',
    expressions: ['At the old cannon, turn left', 'the stairs up to the third floor', 'The door is on your right'],
  ),
  'ep05_m2': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.application,
    skill: LanguageSkill.grammarInContext,
    objective: '"the other way", "the same way as"를 이해하고 다이얼을 실제로 돌린다.',
    expressions: ['After that, turn it the same way as the first time', 'the same way as the second time'],
  ),
  'ep05_m3': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.sentenceMeaning,
    objective: '"six ravens … and one more"를 읽고 까마귀 수를 알아낸다.',
    expressions: ['six ravens always live here', 'there is one more, just in case'],
  ),
  'ep05_final': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.recall,
    skill: LanguageSkill.sentenceMeaning,
    objective: '자물쇠에 그림이 없다. 뚜껑의 질문 세 개를 읽고, 수첩의 단서(찾은 순서와 다름)를 질문 순서대로 맞춘다.',
    expressions: ['The first lock: how many ravens live at the Tower?', 'one at a time, from left to right'],
    recallFrom: 'ep05_m1',
  ),
};

const Map<String, LearningObjective> ep05MasterLearning = {
  'ep05_m1': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.sentenceMeaning,
    objective: '길 안내 지시문(왼쪽·층·오른쪽)을 읽고 방의 위치를 고른다.',
    expressions: [
      'When you reach the old cannon, turn left',
      'Climb the stairs as far as the third floor',
      'The door will be on your right',
    ],
  ),
  'ep05_m2': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.application,
    skill: LanguageSkill.grammarInContext,
    objective: '"the other way", "as you did the first time"를 이해하고 다이얼을 실제로 돌린다.',
    expressions: ['Then, turn it the other way', 'as you did the first time'],
  ),
  'ep05_m3': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.sentenceMeaning,
    objective: '"six ravens … and one more"를 읽고 까마귀 수를 알아낸다.',
    expressions: ['six ravens are always kept here', 'and one more, just in case'],
  ),
  'ep05_final': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.recall,
    skill: LanguageSkill.sentenceMeaning,
    objective: '자물쇠에 그림이 없다. 뚜껑의 질문 세 개를 읽고, 수첩의 단서(찾은 순서와 다름)를 질문 순서대로 맞춘다.',
    expressions: ['The first lock: how many ravens live at the Tower?', 'Open the locks in turn, from left to right'],
    recallFrom: 'ep05_m1',
  ),
};
