import 'dart:ui' show Offset;

import '../../../models/dialogue.dart';
import '../../../models/discovery.dart';
import '../../../models/learning.dart';

// Case 06 — The Midnight Detective, at each level (PART 6B).
//
// The facts never move: the market's three witnesses (dark coat, small bag;
// grey hat, small bag; dark coat, big red umbrella — Mission 01's talk keeps
// the base's words at every level, so its notes say the same things), the
// stranger who drops a small card by the fountain, the wet card's back ("the
// colour of my hat", read against the juggler's grey hat: GREY), the guard's
// two nights (a tall man with a small bag; a short woman with a big bag and
// the raven ticket), and the final's man by the fountain: tall, a dark coat,
// a small bag, looking for something lost in the water. The final's page
// never says grey, gray, hat, card, inspector or detective agency, at any
// level. Inspector Grey is an ally; "Find the other half in Hyde Park" (Case
// 07) and Row R, seat 17 (Cases 10 and 11) stay word for word.
//
// The same at every level, on purpose (puzzle data or how to play):
// - ep06_m2.prompt: 'INSPECTOR ____' (the card's front, the word to fill).
// - ep06_m3.letter: the guard's notebook, the two nights the options quote.
// Inside rewritten fields, kept word for word at every level:
// - ep06_m2.letter: the card's front and its back's riddle ("My name is a
//   colour. / It is the colour of my hat, / and of rain clouds and old
//   stones.") — only the line before the riddle changes.
// - ep06_m3.transition: 'Row R, seat 17. The letter R and the number 17 seem
//   familiar.' and 'On the back, a black raven is stamped: the mark of the
//   Raven Society.'
// - ep06_final.transition: 'Inspector Grey is on your side.', '"Blow it if
//   you need help, Detective {detectiveName}."' (the whistle's inscription)
//   and '"Find the other half\nin Hyde Park."'.
//
// Rookie: the base.
//
// Mission 01's talk at Junior and Master (2026-10-30, the London gameplay
// upgrade): written once the engine checked a talk's structure. Its
// witnesses, questions, statement ids, what each statement is about and
// the thing it names stay the base's; each level's witnesses say their own
// letter's words.

const Map<String, Object?> ep06Rookie = {};

// ── Mission 01's talk at each level ──────────────────────────────────────
const _hall = 'assets/seasons/season_01_london/locations/covent_garden/covent_garden_market_hall.png';
const _flower = 'assets/seasons/season_01_london/characters/flower_seller.png';
const _juggler = 'assets/seasons/season_01_london/characters/juggler.png';
const _baker = 'assets/seasons/season_01_london/characters/baker.png';

const Map<String, DialogueScene> ep06JuniorDialogues = {
  'ep06_m1': DialogueScene(
    place: 'MARKET HALL',
    background: _hall,
    goal: 'Find out what the stranger was carrying.',
    how: 'Ask each witness what they saw. Their clues may not be the same.',
    guide: 'Talk to one of the witnesses.',
    questions: [
      DialogueQuestion(id: 'wearing', text: 'What was he wearing?'),
      DialogueQuestion(id: 'carry', text: 'What was he carrying?'),
      DialogueQuestion(id: 'when', text: 'When did you see him?'),
    ],
    speakers: [
      DialogueSpeaker(
        id: 'flowerSeller',
        name: 'The flower seller',
        title: 'THE FLOWER SELLER',
        portrait: _flower,
        description: 'a young woman in a straw bonnet and a red shawl, with a basket of flowers',
        face: Offset(0.50, 0.21),
        greeting: 'The man in the dark coat? Yes, I saw him clearly.',
        answers: {
          'wearing': DialogueAnswer('He was wearing a dark coat.', statementId: 'flowerSeller.wearing'),
          'carry': DialogueAnswer('He was carrying a small bag.', statementId: 'flowerSeller.carry'),
          'when': DialogueAnswer('Last night, a little before midnight.'),
        },
      ),
      DialogueSpeaker(
        id: 'juggler',
        name: 'The juggler',
        title: 'THE JUGGLER',
        portrait: _juggler,
        description: 'a young man in a striped waistcoat, juggling three balls',
        face: Offset(0.56, 0.19),
        greeting: 'I saw him while I was practising my juggling!',
        answers: {
          'wearing': DialogueAnswer('He was wearing a grey hat.', statementId: 'juggler.wearing'),
          'carry': DialogueAnswer('He carried a small bag, too.', statementId: 'juggler.carry'),
          'when': DialogueAnswer('Last night, when the church clock was almost at twelve.'),
        },
      ),
      DialogueSpeaker(
        id: 'baker',
        name: 'The baker',
        title: 'THE BAKER',
        portrait: _baker,
        description: 'a bearded baker in a white cap and apron, holding a round loaf',
        face: Offset(0.50, 0.22),
        greeting: 'That stranger walked right past my bread stall.',
        answers: {
          'wearing': DialogueAnswer('He wore a dark coat.', statementId: 'baker.wearing'),
          'carry': DialogueAnswer('He had a big red umbrella.', statementId: 'baker.carry'),
          'when': DialogueAnswer('Last night, while I was closing my stall.'),
        },
      ),
    ],
    statements: [
      DialogueStatement(id: 'flowerSeller.wearing', speakerId: 'flowerSeller', about: 'wearing', text: 'He was wearing a dark coat.', thing: 'a dark coat'),
      DialogueStatement(id: 'flowerSeller.carry', speakerId: 'flowerSeller', about: 'carry', text: 'He was carrying a small bag.', thing: 'a small bag'),
      DialogueStatement(id: 'juggler.wearing', speakerId: 'juggler', about: 'wearing', text: 'He was wearing a grey hat.', thing: 'a grey hat'),
      DialogueStatement(id: 'juggler.carry', speakerId: 'juggler', about: 'carry', text: 'He carried a small bag, too.', thing: 'a small bag'),
      DialogueStatement(id: 'baker.wearing', speakerId: 'baker', about: 'wearing', text: 'He wore a dark coat.', thing: 'a dark coat'),
      DialogueStatement(id: 'baker.carry', speakerId: 'baker', about: 'carry', text: 'He had a big red umbrella.', thing: 'a big red umbrella'),
    ],
    deduction: DialogueDeduction(
      topic: 'carry',
      pair: {'flowerSeller.carry', 'juggler.carry'},
      answer: 'b',
      askLine: 'Ask them a question.',
      anotherLine: 'Now ask another witness.',
      readyLine: 'Now compare two statements.',
      compareGoal: 'Find two witnesses who saw him carrying the same thing.',
      compareHow: 'Tap two statements to compare them.',
      matchLine: 'Both witnesses saw him carrying the same thing.',
      offTopicLine: 'Both witnesses talked about the same clothes.',
      checkLine: 'Look for something he carried, not something he wore.',
      differentLine: 'These witnesses talked about different things.',
      retryLine: 'Try a different pair.',
      then: {'juggler.wearing'},
      thenGoal: 'Find out what the stranger was wearing.',
      thenHow: "Ask the witnesses about the stranger's clothes.",
      doneLine: 'Now you know more about how the stranger looked.',
      notesLine: 'Your witness notes are ready.',
    ),
  ),
};

const Map<String, DialogueScene> ep06MasterDialogues = {
  'ep06_m1': DialogueScene(
    place: 'MARKET HALL',
    background: _hall,
    goal: 'Discover what the stranger was carrying.',
    how: 'Question each witness. Their accounts may not all agree.',
    guide: 'Approach a witness.',
    questions: [
      DialogueQuestion(id: 'wearing', text: 'What was he dressed in?'),
      DialogueQuestion(id: 'carry', text: 'What did he have in his hand?'),
      DialogueQuestion(id: 'when', text: 'When exactly did you see him?'),
    ],
    speakers: [
      DialogueSpeaker(
        id: 'flowerSeller',
        name: 'The flower seller',
        title: 'THE FLOWER SELLER',
        portrait: _flower,
        description: 'a young woman in a straw bonnet and a red shawl, with a basket of flowers',
        face: Offset(0.50, 0.21),
        greeting: 'The gentleman in the dark coat? I could hardly miss him.',
        answers: {
          'wearing': DialogueAnswer('He had on a dark coat.', statementId: 'flowerSeller.wearing'),
          'carry': DialogueAnswer('In his hand he carried a small bag.', statementId: 'flowerSeller.carry'),
          'when': DialogueAnswer('Last night, shortly before midnight.'),
        },
      ),
      DialogueSpeaker(
        id: 'juggler',
        name: 'The juggler',
        title: 'THE JUGGLER',
        portrait: _juggler,
        description: 'a young man in a striped waistcoat, juggling three balls',
        face: Offset(0.56, 0.19),
        greeting: 'I caught sight of him between two throws!',
        answers: {
          'wearing': DialogueAnswer('He wore a grey hat.', statementId: 'juggler.wearing'),
          'carry': DialogueAnswer('He carried a small bag as well.', statementId: 'juggler.carry'),
          'when': DialogueAnswer('Last night, as the church clock crept towards twelve.'),
        },
      ),
      DialogueSpeaker(
        id: 'baker',
        name: 'The baker',
        title: 'THE BAKER',
        portrait: _baker,
        description: 'a bearded baker in a white cap and apron, holding a round loaf',
        face: Offset(0.50, 0.22),
        greeting: 'That stranger strode straight past my stall.',
        answers: {
          'wearing': DialogueAnswer('A dark coat.', statementId: 'baker.wearing'),
          'carry': DialogueAnswer('A big red umbrella.', statementId: 'baker.carry'),
          'when': DialogueAnswer('Last night, just as I was shutting up my stall.'),
        },
      ),
    ],
    statements: [
      DialogueStatement(id: 'flowerSeller.wearing', speakerId: 'flowerSeller', about: 'wearing', text: 'He had on a dark coat.', thing: 'a dark coat'),
      DialogueStatement(id: 'flowerSeller.carry', speakerId: 'flowerSeller', about: 'carry', text: 'In his hand he carried a small bag.', thing: 'a small bag'),
      DialogueStatement(id: 'juggler.wearing', speakerId: 'juggler', about: 'wearing', text: 'He wore a grey hat.', thing: 'a grey hat'),
      DialogueStatement(id: 'juggler.carry', speakerId: 'juggler', about: 'carry', text: 'He carried a small bag as well.', thing: 'a small bag'),
      DialogueStatement(id: 'baker.wearing', speakerId: 'baker', about: 'wearing', text: 'A dark coat.', thing: 'a dark coat'),
      DialogueStatement(id: 'baker.carry', speakerId: 'baker', about: 'carry', text: 'A big red umbrella.', thing: 'a big red umbrella'),
    ],
    deduction: DialogueDeduction(
      topic: 'carry',
      pair: {'flowerSeller.carry', 'juggler.carry'},
      answer: 'b',
      askLine: 'Put a question to them.',
      anotherLine: 'Question another witness.',
      readyLine: 'Weigh two statements against each other.',
      compareGoal: 'Find two witnesses whose accounts of what he carried agree.',
      compareHow: 'Tap two statements to set them side by side.',
      matchLine: 'Both witnesses describe the very same thing in his hand.',
      offTopicLine: 'Both witnesses describe the same clothing.',
      checkLine: 'You need what he carried, not what he wore.',
      differentLine: 'These accounts describe different things.',
      retryLine: 'Weigh another pair.',
      then: {'juggler.wearing'},
      thenGoal: 'Discover what the stranger was wearing.',
      thenHow: "Question the witnesses about the stranger's clothing.",
      doneLine: "You have pieced together the stranger's appearance.",
      notesLine: 'Your witness notes are complete.',
    ),
  ),
};

// ── Junior ───────────────────────────────────────────────────────────────
const Map<String, Object?> ep06Junior = {
  'synopsis': [
    'Each night, a stranger in a long dark coat visits Covent Garden.',
    'Everybody tells a different story about him.',
    'Compare what the witnesses saw, and find out who he really is.',
  ],
  'intro': [
    'Covent Garden, 11:55 PM...',
    'Every night at this time, a stranger comes to the market.',
    'He wears a long, dark coat.',
    'Some people say he is one of the Raven Society.',
    'Tonight, you will learn the truth about him.',
  ],
  'caseSummary': 'You compared what each witness saw and found the truth about the man in the dark coat.',
  'hook': 'Inspector Grey tells you: "They already have half of an old map. Find the other half in Hyde Park."',
  'glossary': {
    'visits': '방문하다',
    'everybody': '모든 사람',
    'truth': '진실',
    'glowing': '빛나는',
    'spot': '발견하다, 알아보다',
    'disappears': '사라지다',
    'washed': '씻겨 나갔다 (washed away: 씻겨 사라졌다)',
    'leans': '몸을 기울이다',
    'someone': '누군가',
    'instead': '대신에',
    'closely': '자세히',
    'strikes': '(시계가) 치다',
    'hands': '건네주다',
    'growing': '커지는',
    'anyone': '누군가, 아무도',
  },
  'missions': {
    'ep06_m1': {
      'story': [
        'The market is closing, but the lamps are still glowing.',
        'Last night, three people saw the stranger.',
      ],
      'letterIntro': 'You write down what each witness tells you.',
      'letter': 'The flower seller: "He was wearing a dark coat. He was carrying a small bag."\n\n'
          'The juggler: "He was wearing a grey hat. He carried a small bag, too."\n\n'
          'The baker: "He wore a dark coat, and he had a big red umbrella."',
      'question': 'Two of the witnesses agree. What did the stranger carry?',
      'options': {
        'a': {'feedback': 'Only the baker talked about an umbrella. What do TWO witnesses both say?'},
        'c': {'feedback': 'The flower seller sells flowers. But did anyone say he carried flowers?'},
        'd': {'feedback': 'You wear a hat on your head. You do not carry it. What did he hold?'},
      },
      'hints': [
        'Look at what each witness says he carried. Which thing do two of them both name?',
        "'Carried' means held in his hand. You wear a hat; you do not carry it. 'Agree' means two people say the same thing.",
      ],
      'clue': {'note': 'Two of the witnesses saw a small bag.'},
      'evidence': {'description': 'What the three witnesses told you.'},
      'successMessage': 'The stranger carried a small bag!',
      'transition': [
        'At midnight, you spot a figure in a dark coat with a small bag.',
        'He walks over to the fountain... and drops a small card.',
        'Then he disappears.',
      ],
    },
    'ep06_m2': {
      'story': [
        'The fountain has made the card wet.',
        'Some of the letters of the name have washed away.',
      ],
      'letterIntro': 'You hold the card up under the lamp.',
      'letter': 'INSPECTOR ____\n'
          'London Detective Agency\n\n'
          'On the back, in tiny handwriting:\n'
          '"My name is a colour.\n'
          'It is the colour of my hat,\n'
          'and of rain clouds and old stones."',
      // How to play it: the same at every level.
      'prompt': 'INSPECTOR ____',
      'question': 'What name is written on the card?',
      'feedback': {
        'RED': "Red was the colour of the baker's umbrella. Think about the hat of the man who dropped the card.",
        'BLACK': 'Black is near the colour of his coat. But the card talks about his hat.',
        'DARK': 'Dark is the colour of his coat. The card is asking about his hat.',
        'WHITE': 'Are rain clouds white? Read the back of the card one more time.',
        'BLUE': 'Are rain clouds blue? Look at the witness notes: what colour was his hat?',
      },
      'hints': [
        'Who dropped the card? Read the witness notes in your notebook again.',
        "'The colour of my hat' means his name is the colour of the hat he wore. Rain clouds and old stones are that colour too.",
      ],
      'clue': {'note': 'The stranger is an inspector from the London Detective Agency.'},
      'evidence': {'description': 'The stranger dropped it by the fountain.'},
      'successMessage': 'It says Inspector Grey!',
      'transition': [
        'A detective? So why do people say he works for the Raven Society?',
        'The flower seller leans in and whispers:',
        '"I saw someone in a dark coat by the theatre, too."',
      ],
    },
    'ep06_m3': {
      'story': [
        'The theatre is dark inside. Only the stage light is on.',
        'The theatre guard keeps a notebook of every person who walks past.',
      ],
      'letterIntro': 'The guard opens his notebook. It says:',
      // The guard's two nights: the same at every level.
      'letter': 'MONDAY, MIDNIGHT\n'
          'A tall man. A dark coat.\n'
          'A grey hat. A small bag.\n\n'
          'TUESDAY, MIDNIGHT\n'
          'A short woman. A dark coat.\n'
          'A red hat. A big bag.',
      'question': 'The market witnesses saw only one of these two people. Which one was it?',
      'options': {
        'b': {'feedback': 'Look at your witness notes. What colour was the hat? Was the bag big or small?'},
        'c': {'feedback': 'They both wore dark coats, so the coat cannot tell them apart. Look at the hat and the bag instead.'},
      },
      'hints': [
        'Only one detail is the same on both nights. Use the details that are different: the hat and the bag.',
        'Open your notebook and find the Witness Notes from the market. Which night is like them?',
      ],
      'clue': {'note': 'There is a second person in a dark coat, with a red hat.'},
      'evidence': {'description': 'The woman in the red hat dropped it. There is a black raven stamped on the back.'},
      'successMessage': 'Monday matches the market witnesses. Tuesday was a different person!',
      'transition': [
        'The guard gives you a theatre ticket. "The woman in the red hat dropped it," he says.',
        'Row R, seat 17. The letter R and the number 17 seem familiar.',
        'On the back, a black raven is stamped: the mark of the Raven Society.',
        'So who is the tall man?',
      ],
    },
    'ep06_final': {
      'story': [
        'The church clock strikes twelve.',
        'Once again, a stranger in a dark coat stands by the fountain.',
      ],
      'letterIntro': 'You write down everything you can see.',
      'letter': 'MIDNIGHT, AT THE FOUNTAIN\n\n'
          'A tall man in a dark coat.\n'
          'He is carrying a small bag.\n\n'
          'He keeps looking down into the water,\n'
          'as if he has lost something there.',
      'question': 'Who is the man standing by the fountain?',
      'options': {
        'a': {'feedback': 'The raven ticket was dropped by the short woman. Is the man by the fountain short? Does he have a big bag?'},
        'b': {'feedback': 'The theatre guard stayed at the theatre door, writing in his notebook. Did he drop anything by the fountain?'},
        'd': {'feedback': 'The juggler was a witness who saw the stranger. Can he be the stranger himself?'},
      },
      'hints': [
        'Is he tall or short? Is his bag big or small? Which person in your notes is like him?',
        'Think back: the stranger with the small bag dropped something by the fountain. Find it in your notebook and look at it closely.',
      ],
      'evidence': {'description': 'Inspector Grey gave you this.'},
      'successMessage': 'You found out who the man by the fountain is!',
      'transition': [
        'Inspector Grey is on your side.',
        'He hands you a silver whistle.',
        '"Blow it if you need help, Detective {detectiveName}."',
        'Then he tells you something else.',
        '"Find the other half\nin Hyde Park."',
        'The mystery keeps growing.',
      ],
    },
  },
};

// ── Master ───────────────────────────────────────────────────────────────
const Map<String, Object?> ep06Master = {
  'synopsis': [
    'Night after night, a stranger in a dark coat haunts Covent Garden.',
    'No two people tell the same tale about him.',
    'Weigh what each witness saw, and uncover who he truly is.',
  ],
  'intro': [
    'Covent Garden, 11:55 PM...',
    'At this hour every night, a stranger appears among the market stalls.',
    'He is wrapped in a long dark coat.',
    'Whispers say he serves the Raven Society.',
    'Tonight, you will discover who he truly is.',
  ],
  'caseSummary': "You weighed every witness's account and uncovered the truth behind the dark coat.",
  'hook': 'Inspector Grey warns you: "They hold one half of an old map. Find the other half in Hyde Park."',
  'glossary': {
    'haunts': '(유령처럼) 자주 나타나다',
    'tale': '이야기',
    'weigh': '따져 보다, 저울질하다',
    'weighed': '따져 보았다',
    'uncover': '밝혀내다',
    'uncovered': '밝혀냈다',
    'truly': '정말로',
    'stalls': '가판대, 노점',
    'wrapped': '감싸인',
    'whispers': '소문, 속삭임',
    'serves': '~을 섬기다, ~을 위해 일하다',
    'account': '진술, 이야기',
    'accounts': '진술들',
    'burn': '(불이) 타다, 켜져 있다',
    'caught': '(caught sight of: 언뜻 보았다)',
    'record': '기록하다',
    'statements': '진술들',
    'object': '물건',
    'appears': '나타나다',
    'separate': '서로 다른, 별개의',
    'noticed': '알아챘다',
    'slips': '살며시 지나가다',
    'pauses': '잠시 멈추다',
    'shadow': '그림자',
    'soaked': '흠뻑 젖은',
    'tilt': '기울이다',
    'lamplight': '등불 빛',
    'reverse': '뒷면',
    'neat': '단정한',
    'rarely': '좀처럼 ~않다',
    'riddle': '수수께끼',
    'mysterious': '수수께끼 같은',
    'returns': '돌아오다, 다시 나타나다',
    'lowers': '낮추다',
    'darkness': '어둠',
    'figures': '사람의 모습들',
    'proves': '증명하다',
    'differ': '다르다',
    'entirely': '완전히',
    'nod': '고개를 끄덕임',
    'chimes': '(종이) 울리는 소리',
    'observe': '관찰하다',
    'stares': '빤히 바라보다',
    'though': '(as though: 마치 ~처럼)',
    'presses': '(손에) 쥐여 주다',
    'deepening': '깊어지는',
    'description': '묘사',
    'describing': '묘사하는',
  },
  'missions': {
    'ep06_m1': {
      'story': [
        'The market is closing for the night, yet its lamps still burn.',
        'Three people caught sight of the stranger last night.',
      ],
      'letterIntro': "In your notebook, you record each witness's words.",
      'letter': 'The flower seller: "He had on a dark coat, and in his hand he carried a small bag."\n\n'
          'The juggler: "He wore a grey hat. He carried a small bag as well."\n\n'
          'The baker: "A dark coat, and a big red umbrella."',
      'question': 'Two of the witnesses tell the same story. What did the stranger carry?',
      'options': {
        'a': {'feedback': 'The umbrella comes from the baker alone. Which thing do TWO witnesses both describe?'},
        'c': {'feedback': 'Flowers belong to the flower seller. Did a single witness see them in his hands?'},
        'd': {'feedback': 'A hat sits on the head; it is worn, not carried. What was in his hand?'},
      },
      'hints': [
        'Set the three statements side by side. Which object held in the hand appears twice?',
        "A hat is worn, never 'carried'. When two witnesses tell the same story, their words match.",
      ],
      'clue': {'note': 'Two separate witnesses noticed a small bag.'},
      'evidence': {'description': "The three witnesses' accounts, side by side."},
      'successMessage': "A small bag, in the stranger's hand!",
      'transition': [
        'As midnight strikes, a figure in a dark coat slips past, a small bag in his hand.',
        'He pauses at the fountain... and drops a small card.',
        'Then, like a shadow, he is gone.',
      ],
    },
    'ep06_m2': {
      'story': [
        'The card is soaked with fountain water.',
        'Part of the name has been washed away.',
      ],
      'letterIntro': 'You tilt the card beneath the lamplight.',
      'letter': 'INSPECTOR ____\n'
          'London Detective Agency\n\n'
          'On the reverse, in a small, neat hand:\n'
          '"My name is a colour.\n'
          'It is the colour of my hat,\n'
          'and of rain clouds and old stones."',
      // How to play it: the same at every level.
      'prompt': 'INSPECTOR ____',
      'question': 'What name did the water wash from the card?',
      'feedback': {
        'RED': "Red belongs to the baker's umbrella. What colour was the hat worn by the man who dropped this card?",
        'BLACK': 'Black is close to the colour of his coat, but the card speaks of his hat.',
        'DARK': 'Dark describes his coat. The riddle is about his hat.',
        'WHITE': 'Rain clouds are rarely white. Read the back of the card again.',
        'BLUE': 'A rain cloud is not blue. What did the witness notes say about his hat?',
      },
      'hints': [
        "The card's owner is the man from the market. What did the witnesses notice about him? Your notebook keeps their notes.",
        'The riddle ties his name to his hat. Which witness saw what he wore on his head?',
      ],
      'clue': {'note': 'The mysterious stranger is an inspector with the Detective Agency.'},
      'evidence': {'description': 'Found by the fountain, where the stranger let it fall.'},
      'successMessage': 'The name returns: Inspector Grey!',
      'transition': [
        'A detective? Then why do people whisper that he serves the Raven Society?',
        'The flower seller draws closer and lowers her voice:',
        '"I saw someone in a dark coat near the theatre as well."',
      ],
    },
    'ep06_m3': {
      'story': [
        'The theatre lies in darkness. Only the stage light is on.',
        'The theatre guard keeps a notebook of all who pass his door.',
      ],
      'letterIntro': "The guard's notebook reads:",
      // The guard's two nights: the same at every level.
      'letter': 'MONDAY, MIDNIGHT\n'
          'A tall man. A dark coat.\n'
          'A grey hat. A small bag.\n\n'
          'TUESDAY, MIDNIGHT\n'
          'A short woman. A dark coat.\n'
          'A red hat. A big bag.',
      'question': 'Only one of these two figures was seen by the market witnesses. Which one?',
      'options': {
        'b': {'feedback': 'Hold this night against your witness notes. Do the hat and the bag fit?'},
        'c': {'feedback': 'Both nights show a dark coat, so the coat cannot tell the two apart. Compare the hat and the bag.'},
      },
      'hints': [
        'One detail appears on both nights, so it proves nothing. Weigh the details that differ.',
        'The market witnesses left their notes in your notebook (Mission 01). Which night do they describe?',
      ],
      'clue': {'note': 'Another figure in a dark coat, this one in a red hat.'},
      'evidence': {'description': 'Let fall by the woman in the red hat. On its back, a black raven is stamped.'},
      'successMessage': 'Monday fits the market; Tuesday was someone else entirely!',
      'transition': [
        'With a nod, the guard gives you a theatre ticket. "The woman in the red hat dropped it."',
        'Row R, seat 17. The letter R and the number 17 seem familiar.',
        'On the back, a black raven is stamped: the mark of the Raven Society.',
        'Then who, in truth, is the tall man?',
      ],
    },
    'ep06_final': {
      'story': [
        'Twelve slow chimes ring out from the church clock.',
        'By the fountain, a stranger in a dark coat waits once more.',
      ],
      'letterIntro': 'From the shadows, you note down what you observe.',
      'letter': 'MIDNIGHT, BY THE FOUNTAIN\n\n'
          'A tall man, wrapped in a dark coat.\n'
          'A small bag hangs from his hand.\n\n'
          'He stares down into the water,\n'
          'as though he has lost something there.',
      'question': 'Who, then, is the man by the fountain?',
      'options': {
        'a': {'feedback': "The ticket stamped with a raven fell from the short woman's hand. Does this tall man with his small bag look like her?"},
        'b': {'feedback': 'The theatre guard spends his nights at the theatre door with his notebook. Did anything fall from his hands by the fountain?'},
        'd': {'feedback': 'The juggler was one of the witnesses who described the stranger. Could he have been describing himself?'},
      },
      'hints': [
        'Weigh his height and the size of his bag. Whose description in your notes do they fit?',
        "Something once fell from a stranger's hand beside this very fountain. Your notebook still holds it.",
      ],
      'evidence': {'description': 'A gift from Inspector Grey, for when you need help.'},
      'successMessage': 'The man by the fountain is a stranger no more!',
      'transition': [
        'Inspector Grey is on your side.',
        'He presses a silver whistle into your hand.',
        '"Blow it if you need help, Detective {detectiveName}."',
        'Then he leans closer and adds one more thing.',
        '"Find the other half\nin Hyde Park."',
        'The mystery is only deepening.',
      ],
    },
  },
};

// ── Discovery Moments ────────────────────────────────────────────────────
const Map<String, Discovery> ep06JuniorDiscoveries = {
  'ep06_m1': Discovery(
    type: DiscoveryType.deduction,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'A SMALL BAG',
    detail: 'Two of the witnesses agree: the stranger was carrying a small bag.',
  ),
  'ep06_m2': Discovery(
    type: DiscoveryType.deduction,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'INSPECTOR GREY',
    detail: 'The name on the wet card, from the London Detective Agency.',
  ),
  'ep06_m3': Discovery(
    type: DiscoveryType.storyDiscovery,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'TWO DARK COATS',
    detail: 'Monday was the man from the market. Tuesday was a different person.',
  ),
};

const Map<String, Discovery> ep06MasterDiscoveries = {
  'ep06_m1': Discovery(
    type: DiscoveryType.deduction,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'A SMALL BAG',
    detail: "Two accounts match: in the stranger's hand, a small bag.",
  ),
  'ep06_m2': Discovery(
    type: DiscoveryType.deduction,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'INSPECTOR GREY',
    detail: 'The name the fountain nearly washed away: London Detective Agency.',
  ),
  'ep06_m3': Discovery(
    type: DiscoveryType.storyDiscovery,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'TWO DARK COATS',
    detail: "Monday was the market's man; Tuesday, someone else entirely.",
  ),
};

// ── The parent report's English ──────────────────────────────────────────
const Map<String, LearningObjective> ep06JuniorLearning = {
  'ep06_m1': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.vocabulary,
    objective: '"carry"(들고 있던 것)와 입은 것을 구분하고, 두 증언이 일치하는 것을 찾는다.',
    expressions: ['He was carrying a small bag', 'Two of the witnesses agree'],
  ),
  'ep06_m2': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.recall,
    skill: LanguageSkill.sentenceMeaning,
    objective: '카드 뒷면의 "the colour of my hat"을 이해하고, 카드를 떨어뜨린 사람의 모자 색을 앞 증언에서 다시 찾는다(수수께끼 "rain clouds"가 두 번째 길).',
    expressions: ['It is the colour of my hat', 'rain clouds and old stones', 'He was wearing a grey hat'],
    recallFrom: 'ep06_m1',
  ),
  'ep06_m3': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.recall,
    skill: LanguageSkill.vocabulary,
    objective: '두 날의 인물 묘사를 시장 증언(회색 모자, 작은 가방)과 맞춰 증인이 본 사람을 고른다. 둘 다 입은 dark coat로는 구별할 수 없다.',
    expressions: ['A tall man', 'A short woman', 'He was carrying a small bag'],
    recallFrom: 'ep06_m1',
  ),
  'ep06_final': LearningObjective(
    dependency: LanguageDependency.helpful,
    level: LearningLevel.exposure,
    skill: LanguageSkill.sentenceMeaning,
    objective: '인물 묘사를 앞의 기록과 맞춘다. 보기 중 이야기상 두드러지는 인물이 하나라 묘사 없이도 고를 수 있다.',
    expressions: ['A tall man', 'He is carrying a small bag'],
    recallFrom: 'ep06_m3',
  ),
};

const Map<String, LearningObjective> ep06MasterLearning = {
  'ep06_m1': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.vocabulary,
    objective: '"carried"(손에 들고 있던 것)와 입은 것(had on, wore)을 구분하고, 두 증언이 같은 이야기를 하는 것을 찾는다.',
    expressions: ['in his hand he carried a small bag', 'tell the same story'],
  ),
  'ep06_m2': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.recall,
    skill: LanguageSkill.sentenceMeaning,
    objective: '카드 뒷면의 "the colour of my hat"을 이해하고, 카드를 떨어뜨린 사람의 모자 색을 앞 증언에서 다시 찾는다(수수께끼 "rain clouds"가 두 번째 길).',
    expressions: ['It is the colour of my hat', 'rain clouds and old stones', 'He wore a grey hat'],
    recallFrom: 'ep06_m1',
  ),
  'ep06_m3': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.recall,
    skill: LanguageSkill.vocabulary,
    objective: '두 날의 인물 묘사를 시장 증언(회색 모자, 작은 가방)과 맞춰 증인이 본 사람을 고른다. 둘 다 입은 dark coat로는 구별할 수 없다.',
    expressions: ['A tall man', 'A short woman', 'in his hand he carried a small bag'],
    recallFrom: 'ep06_m1',
  ),
  'ep06_final': LearningObjective(
    dependency: LanguageDependency.helpful,
    level: LearningLevel.exposure,
    skill: LanguageSkill.sentenceMeaning,
    objective: '인물 묘사를 앞의 기록과 맞춘다. 보기 중 이야기상 두드러지는 인물이 하나라 묘사 없이도 고를 수 있다.',
    expressions: ['A tall man', 'A small bag hangs from his hand'],
    recallFrom: 'ep06_m3',
  ),
};
