import '../../../models/discovery.dart';
import '../../../models/learning.dart';

// Case 08 — The Mystery on Platform 9, at each level (PART 6B).
//
// The facts never move: the name tag (TO: Edinburgh, 1 adult, alone, the
// 9:30 to Edinburgh); the four answers, with Mrs Robin "in a long red coat"
// saying "I am going to Edinburgh. I am travelling alone." (word for word at
// every level, and her coat in the clue note too) and Lily's "My dad and I";
// seat forty-two, then the hour of the 9:30 (429, the order 942 and 930 keep
// their lines); her lie "I was never in Gallery 8." (word for word at every
// level). The final's page — story, letter, question, tips and the cards'
// lines — names no button, no coat and nothing red at any level; its tips
// lead to the Case Archive and Case 03 only. Miss Rose is named only after
// the case is closed ("Miss Rose was Mrs Robin all along."), and
// "nine ravens around Platform 9", "BUCKINGHAM PALACE." and
// "The Clockmaker gives the orders." are kept for Cases 07 and 09.
//
// The same at every level on purpose (puzzle data the player reasons from,
// and how a puzzle is played): ep08_m1.letter (the name tag),
// ep08_m2.prompt ("MRS _____"), ep08_m3.letter (the ticket and the lock's
// note).
//
// Rookie: the base.

const Map<String, Object?> ep08Rookie = {};

// ── Junior ───────────────────────────────────────────────────────────────
const _nameTag = 'NAME: ~~~~~~~~\n'
    'FROM: London\n'
    'TO: Edinburgh\n'
    'TRAVELLER: 1 adult, alone\n'
    'TRAIN: the 9:30 to Edinburgh';

const _ticket = 'TICKET\n'
    'Train: the 9:30 to Edinburgh\n'
    'Coach: B\n'
    'Seat: forty-two\n\n'
    'NOTE ON THE LOCK\n'
    'My code: first my seat number,\n'
    'then the hour of my train.';

const Map<String, Object?> ep08Junior = {
  'synopsis': [
    'A suitcase is standing all alone on Platform 9.',
    'The rain has washed the name off its tag.',
    'Ask the right questions to find out who owns it.',
  ],
  'intro': [
    "King's Cross, nine o'clock at night...",
    'The old map brought you here: nine ravens around Platform 9.',
    'On the platform, a suitcase is standing all by itself.',
    'The rain has washed away the name on its tag.',
    'Four passengers are waiting for the last train. One of them owns the suitcase.',
  ],
  'caseSummary': 'You asked good questions, listened carefully to every answer and found who owns the suitcase.',
  'hook': 'Mrs Robin leans close and whispers: "I only carry things. The Clockmaker gives the orders."',
  'glossary': {
    'owns': '가지고 있다, ~의 주인이다',
    'friendly': '친절한, 다정한',
    'weather': '날씨',
    'together': '함께',
    'hurrying': '서둘러 가는',
    'proves': '증명하다',
    'links': '연결하다',
    'bottom': '바닥',
  },
  'missions': {
    'ep08_m1': {
      'story': [
        'The suitcase is black, and it has a small silver lock.',
        'Most of the name tag is gone, but part of it can still be read.',
      ],
      'letterIntro': 'This is what is left on the name tag:',
      // The name tag itself: the same at every level.
      'letter': _nameTag,
      'question': 'You may ask the passengers just one question. Which one will help you most?',
      'options': {
        'a': {'feedback': 'A friendly question! But the tag says nothing about what the owner likes.'},
        'c': {'feedback': "You could just look at a clock for that. Which part of the tag could a passenger's answer check?"},
        'd': {'feedback': "The rain washed the name away, but talking about the weather won't find the owner. What does the tag still say?"},
      },
      'hints': [
        'The name is gone. Which parts of the tag can you still read and check?',
        "Look at 'TO: Edinburgh' on the tag. Which question would get that kind of answer from every passenger?",
      ],
      'clue': {'note': 'The owner is travelling to Edinburgh, all alone.'},
      'evidence': {'description': 'The name has washed away, but the rest is still there.'},
      'successMessage': 'That is a good question, Detective {detectiveName}!',
      'transition': [
        'You walk slowly along the platform.',
        '"Excuse me," you say to each passenger. "Where are you going?"',
        'One by one, they all answer.',
      ],
    },
    'ep08_m2': {
      'story': [
        'The waiting room is nice and warm. The big clock says 9:20.',
        'You write down every answer you hear.',
      ],
      'letterIntro': 'Here are your notes:',
      'letter': 'Mrs Patel: "I am going to York. I want to see my sister."\n\n'
          'Mr Brown: "Edinburgh? No, no. I am off to Cambridge."\n\n'
          'Lily: "My dad and I are going to Edinburgh together!"\n\n'
          'Mrs Robin, in a long red coat: "I am going to Edinburgh. I am travelling alone."',
      'question': 'Which passenger owns the suitcase? Write the name.',
      // How to play it: the same at every level.
      'prompt': 'MRS _____',
      'feedback': {
        'LILY': 'Lily is going to Edinburgh too, but she is going with her dad. The tag says 1 adult, alone.',
        'PATEL': 'Mrs Patel is going to York. Where is the owner of the suitcase going?',
        'BROWN': "Mr Brown says 'No, no': he is on his way to Cambridge, not Edinburgh.",
      },
      'hints': [
        'Two passengers say they are going to Edinburgh. Now read the name tag again.',
        "'Alone' means with nobody else. 'My dad and I' means two people are travelling.",
      ],
      'clue': {'note': 'Only Mrs Robin is going to Edinburgh alone. She is wearing a long red coat.'},
      'evidence': {'description': 'Four passengers, four answers to one question.'},
      'successMessage': 'The owner must be Mrs Robin!',
      'transition': [
        'Mrs Robin is wearing a long red coat and a blue scarf.',
        'A robin is a bird... and a raven is a bird too.',
        'A station guard comes to help you open the suitcase.',
      ],
    },
    'ep08_m3': {
      'story': [
        'The small silver lock needs a code with three numbers.',
        'Mrs Robin has dropped her ticket, and there is a note stuck to the lock.',
      ],
      'letterIntro': 'You read the ticket, then the note.',
      // The ticket and the lock's note: the same at every level.
      'letter': _ticket,
      'question': 'Open the small silver lock.',
      'feedback': {
        '930': 'That is the whole train time. The note asks for the seat first, and then just the hour.',
      },
      'orderFeedback': 'The numbers are right, but the order is wrong. The seat comes first, then the hour.',
      'hints': [
        'Read the note on the lock again. What comes first, and what comes after it?',
        "'Forty-two' is a number written in words, so write it in numbers. 'The hour of my train' means only the hour, not the minutes.",
      ],
      'clue': {'note': 'The missing painting was hidden inside the suitcase.'},
      'evidence': {'description': 'The painting that went missing from Gallery 8.'},
      'successMessage': 'Click! The missing painting is inside!',
      'transition': [
        'It is the painting from Gallery 8 — The Raven Tower!',
        'Mrs Robin is hurrying toward the last train.',
        'The whistle blows, and the doors begin to close.',
        'Find the right words to stop her!',
      ],
    },
    'ep08_final': {
      'story': [
        'Mrs Robin stops at the door of the train.',
        '"That is not my suitcase!" she says. "I have never seen it before."',
      ],
      'letterIntro': 'She turns to you and says:',
      'letter': '"My name is Mrs Robin.\n'
          'I have never even been to the British Museum.\n'
          'I was never in Gallery 8.\n\n'
          'You cannot prove that, Detective {detectiveName}!"',
      'question': 'Which evidence proves that she was in Gallery 8?',
      'options': {
        'a': {'feedback': 'The name tag comes from this case. Does it tell you anything about Gallery 8?'},
        'b': {'feedback': 'Take a closer look at the luggage tag in the Case Archive. Where was it found?'},
        'd': {'feedback': 'Your passenger notes tell you where people are going. Do they show who was in Gallery 8?'},
      },
      'hints': [
        'Think back to an earlier case. Gallery 8 was in Case 03. Open your notebook, then the Case Archive, then Case 03. What was found in Gallery 8?',
        'In your notebook, open the Case Archive and then Case 03. Look closer at each thing: where was it found? Then look at what Mrs Robin is wearing.',
      ],
      'evidence': {'description': 'Found at the very bottom of the suitcase.'},
      'successMessage': 'The red button links Mrs Robin to Gallery 8!',
      'transition': [
        'You hold up the red button from Gallery 8.',
        'It fits the empty place\non her long red coat.',
        'You were right.\nMiss Rose was Mrs Robin all along.',
        'Before you go,\nyou look inside her suitcase.',
        'At the very bottom is an empty jewel box.',
        'BUCKINGHAM PALACE.',
        'Then Mrs Robin whispers to you:',
        '"The Clockmaker gives the orders."',
      ],
    },
  },
};

// ── Master ───────────────────────────────────────────────────────────────
const Map<String, Object?> ep08Master = {
  'synopsis': [
    'On Platform 9, a suitcase stands alone and unclaimed.',
    'The rain has washed the name from its tag.',
    'Only the right questions will reveal its owner.',
  ],
  'intro': [
    "King's Cross, 9:00 PM, under a steady rain...",
    'The old map has led you here, to the nine ravens around Platform 9.',
    'On the platform, a lone suitcase waits.',
    'The rain has washed the name clean from its tag.',
    'Four passengers are waiting for the last train. The suitcase belongs to one of them.',
  ],
  'caseSummary': 'You chose your questions well, weighed every answer and unmasked the owner of the suitcase.',
  'hook': 'Mrs Robin\'s voice drops to a whisper: "I only carry things. The Clockmaker gives the orders."',
  'glossary': {
    'unclaimed': '주인이 찾아가지 않은',
    'reveal': '드러내다',
    'steady': '꾸준한, 계속되는',
    'lone': '홀로 있는',
    'weighed': '따져 보았다',
    'unmasked': '정체를 밝혀냈다',
    'fastened': '잠긴, 고정된',
    'serve': '도움이 되다',
    'pleasant': '기분 좋은, 상냥한',
    'destination': '목적지',
    'confirm': '확인해 주다',
    'bound': '(~로) 향하는',
    'heading': '(~로) 향하는',
    'company': '동행, 함께 있는 사람',
    'digits': '숫자(0~9)',
    'striding': '성큼성큼 걷는',
    'shrieks': '날카롭게 울리다',
    'halts': '멈춰 서다',
    'declares': '단언하다',
    'proof': '증거',
    'places': '(장소에 있었음을) 보여 주다',
    'stare': '응시, 노려봄',
    'record': '기록하다',
    'ties': '묶다, 연결하다',
    'softly': '조용히, 부드럽게',
  },
  'missions': {
    'ep08_m1': {
      'story': [
        'The suitcase is black, fastened with a small silver lock.',
        'Of its name tag, only a few lines can still be made out.',
      ],
      'letterIntro': 'What remains of the name tag reads:',
      // The name tag itself: the same at every level.
      'letter': _nameTag,
      'question': 'You may put a single question to the passengers. Which question will serve you best?',
      'options': {
        'a': {'feedback': 'A pleasant question, but the tag reveals nothing of what its owner enjoys.'},
        'c': {'feedback': "Any clock could answer that. Which line of the tag could a passenger's reply put to the test?"},
        'd': {'feedback': 'The rain may have stolen the name, but the weather will not lead you to the owner. What does the tag still tell you?'},
      },
      'hints': [
        "The name is lost. Which of the lines that remain could a stranger's reply confirm?",
        'The tag still names a destination. Which question would draw that answer from every passenger?',
      ],
      'clue': {'note': 'Whoever owns it is bound for Edinburgh, and travelling alone.'},
      'evidence': {'description': 'The name has been washed away; the rest survives.'},
      'successMessage': 'A well-chosen question, Detective {detectiveName}!',
      'transition': [
        'You make your way down the platform.',
        '"Excuse me," you ask each traveller in turn. "Where are you going?"',
        'Every one of them gives an answer.',
      ],
    },
    'ep08_m2': {
      'story': [
        'The waiting room is warm after the cold platform. The great clock reads 9:20.',
        'You note down each answer with care.',
      ],
      'letterIntro': 'From your notebook:',
      'letter': 'Mrs Patel: "York. I am visiting my sister there."\n\n'
          'Mr Brown: "Edinburgh? Oh, no, no. Cambridge is where I am going."\n\n'
          'Lily: "My dad and I are both going to Edinburgh!"\n\n'
          'Mrs Robin, in a long red coat: "I am going to Edinburgh. I am travelling alone."',
      'question': 'To whom does the suitcase belong? Write the name.',
      // How to play it: the same at every level.
      'prompt': 'MRS _____',
      'feedback': {
        'LILY': 'Lily is bound for Edinburgh, yes, but with her dad beside her. The tag says 1 adult, alone.',
        'PATEL': 'Mrs Patel is heading for York. Where is the owner bound?',
        'BROWN': "Mr Brown's 'No, no' says it all: Cambridge is where he is going.",
      },
      'hints': [
        'Two of the four are bound for Edinburgh. What else does the name tag say about its owner?',
        "Compare 'alone' with 'My dad and I'. How many people does each one mean?",
      ],
      'clue': {'note': 'Of the four, only Mrs Robin travels to Edinburgh alone. She wears a long red coat.'},
      'evidence': {'description': 'One question, four very different answers.'},
      'successMessage': 'The suitcase must belong to Mrs Robin!',
      'transition': [
        'Mrs Robin wears a long red coat, with a blue scarf at her throat.',
        'A robin is a bird... and so, of course, is a raven.',
        "With the station guard's help, you open the suitcase.",
      ],
    },
    'ep08_m3': {
      'story': [
        'The small silver lock will only open to a three-number code.',
        'Mrs Robin let her ticket fall, and a note is stuck fast to the lock.',
      ],
      'letterIntro': 'You study the ticket, then the note.',
      // The ticket and the lock's note: the same at every level.
      'letter': _ticket,
      'question': 'Work the silver lock open.',
      'feedback': {
        '930': 'That is the whole train time. The note wants the seat first, and of the train time, only its hour.',
      },
      'orderFeedback': 'The right numbers, in the wrong order. The note puts the seat before the hour.',
      'hints': [
        'The note on the lock sets out an order. Which part comes first?',
        "Turn the seat's number word into digits. Of the train's time, keep the hour alone.",
      ],
      'clue': {'note': 'The missing painting had been hidden in the suitcase all along.'},
      'evidence': {'description': 'The very painting taken from Gallery 8.'},
      'successMessage': 'Click! Inside lies the missing painting!',
      'transition': [
        'The painting from Gallery 8 — The Raven Tower itself!',
        'Mrs Robin is striding fast toward the last train.',
        'A whistle shrieks. The doors are sliding shut.',
        'Only the right words can stop her now!',
      ],
    },
    'ep08_final': {
      'story': [
        'At the door of the train, Mrs Robin halts.',
        '"That suitcase is not mine!" she declares. "I have never laid eyes on it."',
      ],
      'letterIntro': 'She fixes you with a cold stare:',
      'letter': '"I am Mrs Robin, and I have never set foot in the British Museum.\n'
          'I was never in Gallery 8.\n\n'
          'You have no proof, Detective {detectiveName}. None at all!"',
      'question': 'Which piece of evidence places her in Gallery 8?',
      'options': {
        'a': {'feedback': 'The name tag belongs to this case. Does it say a single word about Gallery 8?'},
        'b': {'feedback': 'Study the luggage tag in the Case Archive once more: where was it found?'},
        'd': {'feedback': 'Your passenger notes record where each traveller is bound. Do they place anyone in Gallery 8?'},
      },
      'hints': [
        'Her lie names a room from an earlier case: Case 03. In the Case Archive, what was left behind in that gallery?',
        'Notebook, Case Archive, Case 03: ask of each thing where it was found. Then study what Mrs Robin has on.',
      ],
      'evidence': {'description': 'Hidden at the very bottom of the suitcase.'},
      'successMessage': 'The red button ties Mrs Robin to Gallery 8!',
      'transition': [
        'You hold the red button from Gallery 8 up before Mrs Robin.',
        'It fits the empty place\non her long red coat exactly.',
        'You were right.\nMiss Rose was Mrs Robin all along.',
        'Before you leave,\nyou search her suitcase.',
        'At its bottom lies an empty jewel box.',
        'BUCKINGHAM PALACE.',
        'Then, very softly, Mrs Robin whispers:',
        '"The Clockmaker gives the orders."',
      ],
    },
  },
};

// ── Discovery Moments ────────────────────────────────────────────────────
const Map<String, Discovery> ep08JuniorDiscoveries = {
  'ep08_m1': Discovery(
    type: DiscoveryType.clueConfirmed,
    timing: DiscoveryTiming.beforePuzzle,
    title: 'TO EDINBURGH, ALONE',
    detail: 'The name has washed away, but the city has not: ask every passenger where they are going.',
  ),
  'ep08_m2': Discovery(
    type: DiscoveryType.deduction,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'MRS ROBIN',
    detail: 'She is the only passenger going to Edinburgh on her own.',
  ),
  'ep08_m3': Discovery(
    type: DiscoveryType.evidenceFound,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'THE RAVEN TOWER',
    detail: 'First seat forty-two, then nine from the 9:30 train: the lock opens, and the missing painting is inside.',
    showEvidence: true,
  ),
};

const Map<String, Discovery> ep08MasterDiscoveries = {
  'ep08_m1': Discovery(
    type: DiscoveryType.clueConfirmed,
    timing: DiscoveryTiming.beforePuzzle,
    title: 'TO EDINBURGH, ALONE',
    detail: 'The rain stole the name, yet the city survives: ask each passenger where they are going.',
  ),
  'ep08_m2': Discovery(
    type: DiscoveryType.deduction,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'MRS ROBIN',
    detail: 'Of all the passengers, only she travels to Edinburgh alone.',
  ),
  'ep08_m3': Discovery(
    type: DiscoveryType.evidenceFound,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'THE RAVEN TOWER',
    detail: 'Seat forty-two, then the nine of the 9:30 train: the lock gives way to the missing painting.',
    showEvidence: true,
  ),
};

// ── The parent report's English ──────────────────────────────────────────
const Map<String, LearningObjective> ep08JuniorLearning = {
  'ep08_m1': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.sentenceMeaning,
    objective: '이름표에 남은 정보를 확인할 수 있는 질문을 고른다(질문의 쓰임 이해).',
    expressions: ['Where are you going?', 'what is left on the name tag'],
  ),
  'ep08_m2': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.sentenceMeaning,
    objective: '"travelling alone"과 "My dad and I"를 구분해 혼자 가는 승객을 찾는다.',
    expressions: ['I am travelling alone', 'My dad and I are going to Edinburgh together'],
    recallFrom: 'ep08_m1',
  ),
  'ep08_m3': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.vocabulary,
    objective: '숫자 단어(forty-two)와 "the hour of my train"을 읽고 번호를 만든다.',
    expressions: ['Seat: forty-two', 'only the hour, not the minutes'],
  ),
  'ep08_final': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.recall,
    skill: LanguageSkill.sentenceMeaning,
    objective: '용의자의 부정 진술을 읽고, Case 03 증거 글귀("from a coat")를 다시 찾아 반박한다.',
    expressions: ['I was never in Gallery 8', 'You cannot prove that', 'from a coat'],
    recallFrom: 'ep03_m1',
  ),
};

const Map<String, LearningObjective> ep08MasterLearning = {
  'ep08_m1': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.sentenceMeaning,
    objective: '이름표에 남은 정보를 확인할 수 있는 질문을 고른다(질문의 쓰임 이해).',
    expressions: ['Where are you going?', 'What remains of the name tag'],
  ),
  'ep08_m2': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.sentenceMeaning,
    objective: '"travelling alone"과 "My dad and I"를 구분해 혼자 가는 승객을 찾는다.',
    expressions: ['I am travelling alone', 'My dad and I are both going to Edinburgh'],
    recallFrom: 'ep08_m1',
  ),
  'ep08_m3': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.vocabulary,
    objective: '숫자 단어(forty-two)와 "the hour of my train"을 읽고 번호를 만든다.',
    expressions: ['Seat: forty-two', 'keep the hour alone'],
  ),
  'ep08_final': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.recall,
    skill: LanguageSkill.sentenceMeaning,
    objective: '용의자의 부정 진술을 읽고, Case 03 증거 글귀("from a coat")를 다시 찾아 반박한다.',
    expressions: ['I was never in Gallery 8', 'You have no proof', 'from a coat'],
    recallFrom: 'ep03_m1',
  ),
};
