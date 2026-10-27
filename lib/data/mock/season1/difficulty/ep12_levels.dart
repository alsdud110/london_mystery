import '../../../models/discovery.dart';
import '../../../models/learning.dart';

// Case 12 — The Midnight Case, at each level (the season finale).
//
// The facts never move: the real gear (brass, eight teeth, the raven stamp
// from Case 02), the arrivals board with two trains on Platform 4 (10:15 and
// 11:40) and Grey's "after the train from Edinburgh" (Case 02's after; Case
// 04's small red clock), Poppy's riddle (hands, a face, very tall, rings
// every hour → under Big Ben), and the door's three questions in their order
// (platform, teeth, ravens → 487; the found order 847 → orderFeedback). The
// first lock reads "the platform whose clock is small and red" (Case 09's
// whose). No digit on the door, its tips or its order line at any level.
// The Clockmaker never appears directly; the last line is "PARIS.".
//
// Intentionally identical to the base at every level (keys still given):
// * ep12_m2.letter — the arrivals board (puzzle data) and Grey's words
//   "The Clockmaker always arrives / on the platform with the small red
//   clock, / after the train from Edinburgh." (load-bearing callback).
// * ep12_m2.clue.note — "The Clockmaker came in on Platform 4, from Paris."
//   (asserted word for word by the cross-case tests).
// * ep12_m3.prompt — "UNDER ___ ___" (the answer's blanks; how to play).
// Kept word for word inside otherwise rewritten fields:
// * intro line 1 "London, 11:00 PM..."; ep12_m1.letter "raven stamp" and
//   "Case 02"; ep12_m2.transition line 1 "At 11:40, a tall figure steps off
//   the Paris train."; ep12_m3.transition "small iron door" and "FOR THE
//   CLOCKMAKER'S DOOR"; ep12_final.letter's first line "Only a true
//   detective can open me." and its three lock lines; ep12_final
//   .transition "Tick." ×3, "A pocket watch is still ticking." and the last
//   line "PARIS.".
//
// Rookie: the base.

const Map<String, Object?> ep12Rookie = {};

// ── Junior ───────────────────────────────────────────────────────────────
const Map<String, Object?> ep12Junior = {
  'synopsis': [
    "Tonight at midnight, the Clockmaker plans to stop London's great clock.",
    'Every case you have solved was one piece of this night.',
    'Now use everything you have learned to stop the Raven Society.',
  ],
  'intro': [
    'London, 11:00 PM...',
    'The Shadow has told you the whole plan.',
    '"At midnight, the Clockmaker will stop the great clock once more."',
    '"And while London is silent, the Raven Society will open his secret door."',
    'You have just one hour. Every case you have solved will help you tonight.',
  ],
  'caseSummary': "You used every clue from the season, stopped the Raven Society and kept London's midnight safe.",
  'hook': 'The Clockmaker has gone. But on his desk, a pocket watch is still ticking. On its back is one word: PARIS.',
  'glossary': {
    'race': '서둘러 달리다',
    'exactly': '정확히',
    'leans': '몸을 기울이다',
    'later': '더 늦은',
    'foot': '(탑의) 아래쪽, 밑',
    'together': '함께',
  },
  'missions': {
    'ep12_m1': {
      'story': [
        'Once again, you race up the three hundred steps of Big Ben.',
        'Four brass gears lie on a table. Only one of them is real.',
      ],
      'letterIntro': 'Mrs Bell, the clockkeeper, leans close and whispers:',
      'letter': 'The Raven Society wants to put a fake gear into the clock.\n'
          'If they do, it will stop at midnight.\n\n'
          'The real gear is made of brass.\n'
          'It has exactly eight teeth.\n'
          'And it has the small raven stamp — the same one you found in Case 02.',
      'question': 'Which of the four gears is the real one?',
      'options': {
        'a': {'feedback': 'Look at the metal first. What did Mrs Bell say the real gear is made of?'},
        'b': {'feedback': 'Count the teeth again. How many does the real gear have?'},
        'c': {'feedback': 'Brass and eight teeth, good! But something is missing. Read the last line again.'},
      },
      'hints': [
        'Check each gear for three things: its metal, its teeth and its stamp.',
        "Go through Mrs Bell's note and cross out every gear that gets even one thing wrong.",
      ],
      'clue': {'note': 'The real gear has exactly eight teeth.'},
      'evidence': {'description': 'Big Ben will keep going tonight.'},
      'successMessage': 'The real gear is safe with you!',
      'transition': [
        'Mrs Bell locks the real gear safely inside the clock.',
        '"The Clockmaker is coming by train tonight," she tells you.',
        '"Quick, hurry to King\'s Cross!"',
      ],
    },
    'ep12_m2': {
      'story': [
        'The station is very quiet. The big board shows the last trains of the night.',
        'Inspector Grey is already waiting for you.',
      ],
      'letterIntro': 'The arrivals board reads:',
      // The board and Grey's words: the same at every level.
      'letter': 'ARRIVALS\n'
          '10:15  from York — Platform 4\n'
          '11:04  from Edinburgh — Platform 9\n'
          '11:40  from Paris — Platform 4\n'
          '11:55  from Oxford — Platform 7\n\n'
          'Inspector Grey: "The Clockmaker always arrives\n'
          'on the platform with the small red clock,\n'
          'after the train from Edinburgh."',
      'question': "When does the Clockmaker's train come in?",
      'hints': [
        'Look back at Case 04 in your Case Archive. On which platform was the small red clock?',
        "In Case 04, the small red clock was on Platform 4. Two trains come in there, and 'after the train from Edinburgh' means the later of the two.",
      ],
      'feedback': {
        '1015': 'That train comes in on Platform 4 too, but it arrives before the Edinburgh train. Grey said after.',
        '1104': 'That is the Edinburgh train itself. The Clockmaker comes after it, and on another platform.',
        '1155': 'That train does come after Edinburgh, but on another platform. Which platform has the small red clock?',
      },
      // Word for word at every level.
      'clue': {'note': 'The Clockmaker came in on Platform 4, from Paris.'},
      'evidence': {'description': 'The last trains coming in tonight.'},
      'successMessage': 'The train from Paris, on Platform 4! You found it!',
      'transition': [
        'At 11:40, a tall figure steps off the Paris train.',
        'He wears a black coat and a top hat, and something is ticking.',
        'He jumps into a taxi. "To the Tower!" he calls.',
      ],
    },
    'ep12_m3': {
      'story': [
        'All seven ravens of the Tower are wide awake. Poppy flies down to you.',
        'She drops her very last paper. It is a riddle.',
      ],
      'letterIntro': 'The Ravenmaster reads it together with you:',
      'letter': 'I have hands, but I can never clap.\n'
          'I have a face, but I can never smile.\n'
          'I am very tall, and I ring every hour.\n\n'
          "The Clockmaker's door is under me.",
      'question': "Where can you find the Clockmaker's door?",
      // How to play it (the answer's blanks): the same at every level.
      'prompt': 'UNDER ___ ___',
      'hints': [
        'A clock has hands and a face too. What else does the riddle tell you?',
        'Which tall place in London rings every hour? You climbed it in Case 02.',
      ],
      'clue': {'note': 'All seven ravens are safe, and the door is under Big Ben.'},
      'evidence': {'description': 'The very last paper from the ravens.'},
      'successMessage': "The Clockmaker's door is under Big Ben!",
      'transition': [
        'It is 11:55. You race back to Big Ben with the Shadow and Inspector Grey.',
        'At the foot of the tower, you find a small iron door.',
        "You pull out the Brass Key from Case 05: FOR THE CLOCKMAKER'S DOOR.",
      ],
    },
    'ep12_final': {
      'story': [
        'The Brass Key turns, but three more locks are waiting.',
        'High above you, Big Ben starts to ring for midnight.',
      ],
      'letterIntro': 'Words are carved deep into the door:',
      'letter': 'Only a true detective can open me.\n\n'
          'The first lock: the number of the platform whose clock is small and red.\n'
          'The second lock: how many teeth on the real gear?\n'
          'The third lock: how many ravens guard the Tower?\n\n'
          'The answers are all in your notebook.',
      'question': 'Open all three locks before the last bell rings!',
      'hints': [
        'Each lock asks for a different number. Find the three answers in your notebook and match each one to its lock. '
            'For the ravens: use your clue from the Tower tonight, or the Tower case in your Case Archive.',
        "'The platform whose clock is small and red' is the platform with the small red clock.",
      ],
      'orderFeedback': 'You used the order you found the numbers in tonight. Read the door again: which lock comes first?',
      'evidence': {'description': 'He left it on his empty desk.'},
      'successMessage': 'The last locks open before the final bell!',
      'transition': [
        'It is midnight.',
        'Big Ben rings out.',
        'London is safe at last.',
        'But the Clockmaker has gone.',
        'For a moment,\neverything is still.',
        'Then you hear something.',
        'Tick.',
        'Tick.',
        'Tick.',
        'A pocket watch is still ticking.',
        'You turn it over in your hand.',
        'One word is written\non its back.',
        'PARIS.',
      ],
    },
  },
};

// ── Master ───────────────────────────────────────────────────────────────
const Map<String, Object?> ep12Master = {
  'synopsis': [
    "Tonight, as midnight strikes, the Clockmaker means to silence London's great clock.",
    'Every case you have closed was a piece of this one night.',
    'Now draw on all you have learned to stop the Raven Society.',
  ],
  'intro': [
    'London, 11:00 PM...',
    'The Shadow has revealed everything.',
    '"At the stroke of midnight, the Clockmaker will silence the great clock once again."',
    '"And while London lies silent, the Raven Society will open his secret door."',
    'One hour remains. Every case you have solved will serve you now.',
  ],
  'caseSummary': "You drew on every clue of the season, thwarted the Raven Society and saved London's midnight.",
  'hook': 'The Clockmaker has vanished. On his desk, a pocket watch ticks on. On the back, a single word: PARIS.',
  'glossary': {
    'strikes': '(시계가) 치다',
    'stroke': '(시계가) 치는 소리',
    'revealed': '밝혔다',
    'remains': '남아 있다',
    'serve': '도움이 되다',
    'thwarted': '좌절시켰다',
    'vanished': '사라졌다',
    'pounding': '쿵쾅거리는',
    'gleam': '반짝이다',
    'genuine': '진짜의',
    'cast': '(금속으로) 주조된',
    'bears': '지니고 있다',
    'bore': '지니고 있었다',
    'precisely': '정확히',
    'absent': '빠져 있는',
    'mismatch': '맞지 않는 점',
    'secures': '단단히 넣어 두다',
    'murmurs': '중얼거리다',
    'haste': '서두름',
    'hushed': '조용한',
    'flickers': '깜빡이다',
    'faint': '희미한',
    'leaps': '뛰어들다',
    'snaps': '날카롭게 말하다',
    'restless': '들썩이는',
    'swoops': '급강하하다',
    'landmark': '랜드마크, 이름난 건물',
    'toll': '(종이) 울리다',
    'tolls': '(종이) 울리다',
    'trace': '찾아 따라가다',
    'uncovered': '찾아냈다',
    'abandoned': '버려진',
    'yield': '(자물쇠가) 열리다',
  },
  'missions': {
    'ep12_m1': {
      'story': [
        'Once more you climb the three hundred steps of Big Ben, your heart pounding.',
        'Four brass gears gleam on the table. Only one of them is genuine.',
      ],
      'letterIntro': 'Mrs Bell, the clockkeeper, lowers her voice to a whisper:',
      'letter': 'The Raven Society means to slip a fake gear into the clock,\n'
          'so that it stops dead at midnight.\n\n'
          'The genuine gear is cast in brass.\n'
          'It bears precisely eight teeth.\n'
          'And it carries the small raven stamp — the very one you found in Case 02.',
      'question': 'Which of these gears is genuine?',
      'options': {
        'a': {'feedback': 'Begin with the metal. What did Mrs Bell say the genuine gear is cast in?'},
        'b': {'feedback': 'Count once more: how many teeth does the genuine gear bear?'},
        'c': {'feedback': 'Brass, and eight teeth: so far, so good. Yet something is absent. Look again at her final line.'},
      },
      'hints': [
        'Every gear must pass three tests: its metal, its teeth and its stamp.',
        "Hold each gear up against Mrs Bell's words. A single mismatch rules it out.",
      ],
      'clue': {'note': 'The genuine gear bears eight teeth.'},
      'evidence': {'description': 'Big Ben shall not fall silent tonight.'},
      'successMessage': 'The genuine gear is safe in your keeping!',
      'transition': [
        'Mrs Bell secures the genuine gear deep inside the clock.',
        '"The Clockmaker arrives by train tonight," she murmurs.',
        '"Make haste to King\'s Cross!"',
      ],
    },
    'ep12_m2': {
      'story': [
        'The station lies hushed. The great board lists the last trains of the night.',
        'Inspector Grey stands waiting in the shadows.',
      ],
      'letterIntro': 'The great board flickers:',
      // The board and Grey's words: the same at every level.
      'letter': 'ARRIVALS\n'
          '10:15  from York — Platform 4\n'
          '11:04  from Edinburgh — Platform 9\n'
          '11:40  from Paris — Platform 4\n'
          '11:55  from Oxford — Platform 7\n\n'
          'Inspector Grey: "The Clockmaker always arrives\n'
          'on the platform with the small red clock,\n'
          'after the train from Edinburgh."',
      'question': "At what time does the Clockmaker's train pull in?",
      'hints': [
        'Your Case Archive remembers Case 04. Which platform kept the small red clock?',
        "In Case 04, the small red clock stood on Platform 4. Two trains pull in there; 'after the train from Edinburgh' leaves only one of them.",
      ],
      'feedback': {
        '1015': 'That one uses Platform 4 too, yet it arrives before the Edinburgh train. Grey said after.',
        '1104': 'That is the Edinburgh train itself. The Clockmaker follows it, onto another platform.',
        '1155': 'It comes after Edinburgh, true, but on another platform. Which one bears the small red clock?',
      },
      // Word for word at every level.
      'clue': {'note': 'The Clockmaker came in on Platform 4, from Paris.'},
      'evidence': {'description': 'The final arrivals of the night.'},
      'successMessage': 'The train from Paris, pulling in on Platform 4!',
      'transition': [
        'At 11:40, a tall figure steps off the Paris train.',
        'A black coat. A top hat. And beneath it all, a faint ticking.',
        'He leaps into a waiting taxi. "To the Tower!" he snaps.',
      ],
    },
    'ep12_m3': {
      'story': [
        "All seven of the Tower's ravens are restless and awake. Poppy swoops down to you.",
        'She lets fall her very last paper: a riddle.',
      ],
      'letterIntro': 'The Ravenmaster studies it beside you:',
      'letter': 'I have hands, yet I never clap.\n'
          'I have a face, yet I never smile.\n'
          'I stand very tall, and I ring out every hour.\n\n'
          "The Clockmaker's door lies under me.",
      'question': "Where does the Clockmaker's door lie hidden?",
      // How to play it (the answer's blanks): the same at every level.
      'prompt': 'UNDER ___ ___',
      'hints': [
        'What else has hands and a face, yet is no person at all?',
        'Which tall landmark of London rings out every hour? Your Case 02 notes remember it.',
      ],
      'clue': {'note': 'Every one of the seven ravens is safe. The door lies under Big Ben.'},
      'evidence': {'description': 'The last of the raven papers.'},
      'successMessage': "The Clockmaker's door lies under Big Ben!",
      'transition': [
        '11:55. You hurry back to Big Ben with the Shadow and Inspector Grey at your side.',
        'Beneath the tower waits a small iron door.',
        "You draw out the Brass Key from Case 05: FOR THE CLOCKMAKER'S DOOR.",
      ],
    },
    'ep12_final': {
      'story': [
        'The Brass Key turns with a heavy click. Yet three more locks remain.',
        'Far above, Big Ben begins to toll for midnight.',
      ],
      'letterIntro': 'Words have been carved into the iron door:',
      'letter': 'Only a true detective can open me.\n\n'
          'The first lock: the number of the platform whose clock is small and red.\n'
          'The second lock: how many teeth on the real gear?\n'
          'The third lock: how many ravens guard the Tower?\n\n'
          'Your notebook holds every answer.',
      'question': 'Open the three locks before the final bell falls silent!',
      'hints': [
        'Three locks, three different numbers. Trace each one to its source in your notebook, then match it to its lock. '
            "The ravens were counted at the Tower: tonight's clue, or the Tower case in your Case Archive.",
        "Read 'whose' with care: the platform whose clock is small and red is the platform that keeps the small red clock.",
      ],
      'orderFeedback': 'Those numbers stand in the order you uncovered them tonight. What does the door say comes first?',
      'evidence': {'description': 'Abandoned on his empty desk.'},
      'successMessage': 'The last locks yield before the final bell!',
      'transition': [
        'The stroke of midnight.',
        'Big Ben tolls across the city.',
        'London is saved.',
        'But the Clockmaker has vanished.',
        'For a moment,\nall is silent.',
        'Then, faintly, you hear it.',
        'Tick.',
        'Tick.',
        'Tick.',
        'A pocket watch is still ticking.',
        'Slowly, you turn it over.',
        'A single word is written\non the back.',
        'PARIS.',
      ],
    },
  },
};

// ── Discovery Moments ────────────────────────────────────────────────────
const Map<String, Discovery> ep12JuniorDiscoveries = {
  'ep12_m1': Discovery(
    type: DiscoveryType.deduction,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'THE REAL GEAR',
    detail: 'Made of brass, with eight teeth and the raven stamp: it is the only gear with all three.',
    showEvidence: true,
  ),
  'ep12_m2': Discovery(
    type: DiscoveryType.deduction,
    timing: DiscoveryTiming.fromPuzzle,
    title: '11:40 · PLATFORM 4',
    detail: 'The small red clock is on Platform 4, and the later train there is the one from Paris.',
  ),
  'ep12_m3': Discovery(
    type: DiscoveryType.newLead,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'UNDER BIG BEN',
    detail: "It has hands and a face, it is very tall and it rings every hour. The Clockmaker's door is under Big Ben.",
  ),
};

const Map<String, Discovery> ep12MasterDiscoveries = {
  'ep12_m1': Discovery(
    type: DiscoveryType.deduction,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'THE REAL GEAR',
    detail: 'Brass, eight teeth, the raven stamp: only one gear bore all three marks.',
    showEvidence: true,
  ),
  'ep12_m2': Discovery(
    type: DiscoveryType.deduction,
    timing: DiscoveryTiming.fromPuzzle,
    title: '11:40 · PLATFORM 4',
    detail: 'Platform 4 keeps the small red clock, and its later arrival comes from Paris.',
  ),
  'ep12_m3': Discovery(
    type: DiscoveryType.newLead,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'UNDER BIG BEN',
    detail: "Hands, a face, great height and an hourly bell: the Clockmaker's door lies under Big Ben.",
  ),
};

// ── The parent report's English ──────────────────────────────────────────
// ep12_m2 recalls Case 04 (written elsewhere): its expressions are on this
// mission's own page at each level. The final's are the door's lock lines,
// word for word at every level.
const Map<String, LearningObjective> ep12JuniorLearning = {
  'ep12_m1': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.application,
    skill: LanguageSkill.sentenceMeaning,
    objective: '세 가지 조건(금속·톱니 수·도장)을 읽고 맞지 않는 보기를 지워 진짜를 찾는다.',
    expressions: ['The real gear is made of brass', 'It has exactly eight teeth'],
    recallFrom: 'ep02_m2',
  ),
  'ep12_m2': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.recall,
    skill: LanguageSkill.sentenceMeaning,
    objective: '도착 시간표를 읽고, Case 04의 "small red clock"으로 승강장을, Case 02에서 쓴 "after"로 그 승강장의 두 열차 중 하나를 정한다.',
    expressions: [
      'always arrives on the platform with the small red clock',
      'after the train from Edinburgh',
      'the small red clock was on Platform 4',
    ],
    recallFrom: 'ep04_m2',
  ),
  'ep12_m3': LearningObjective(
    dependency: LanguageDependency.helpful,
    level: LearningLevel.exposure,
    skill: LanguageSkill.vocabulary,
    objective: '시계를 사람처럼 묘사한 수수께끼(hands, face)를 푼다. 정답 장소가 같은 사건 앞에서 이미 나온다.',
    expressions: ['I have hands, but I can never clap', 'I have a face, but I can never smile'],
  ),
  'ep12_final': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.recall,
    skill: LanguageSkill.grammarInContext,
    objective: '자물쇠에 그림이 없다. 문에 새겨진 질문 세 개를 순서대로 읽고 오늘 밤의 단서를 맞춘다. 첫 질문은 Case 09의 whose 구조("the platform whose clock is small and red")로 읽는다.',
    expressions: [
      'the platform whose clock is small and red',
      'how many teeth on the real gear?',
      'how many ravens guard the Tower?',
    ],
    recallFrom: 'ep12_m2',
  ),
};

const Map<String, LearningObjective> ep12MasterLearning = {
  'ep12_m1': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.application,
    skill: LanguageSkill.sentenceMeaning,
    objective: '세 가지 조건(금속·톱니 수·도장)을 읽고 맞지 않는 보기를 지워 진짜를 찾는다.',
    expressions: ['The genuine gear is cast in brass', 'It bears precisely eight teeth'],
    recallFrom: 'ep02_m2',
  ),
  'ep12_m2': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.recall,
    skill: LanguageSkill.sentenceMeaning,
    objective: '도착 시간표를 읽고, Case 04의 "small red clock"으로 승강장을, Case 02에서 쓴 "after"로 그 승강장의 두 열차 중 하나를 정한다.',
    expressions: [
      'always arrives on the platform with the small red clock',
      'after the train from Edinburgh',
      'the small red clock stood on Platform 4',
    ],
    recallFrom: 'ep04_m2',
  ),
  'ep12_m3': LearningObjective(
    dependency: LanguageDependency.helpful,
    level: LearningLevel.exposure,
    skill: LanguageSkill.vocabulary,
    objective: '시계를 사람처럼 묘사한 수수께끼(hands, face)를 푼다. 정답 장소가 같은 사건 앞에서 이미 나온다.',
    expressions: ['I have hands, yet I never clap', 'I have a face, yet I never smile'],
  ),
  'ep12_final': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.recall,
    skill: LanguageSkill.grammarInContext,
    objective: '자물쇠에 그림이 없다. 문에 새겨진 질문 세 개를 순서대로 읽고 오늘 밤의 단서를 맞춘다. 첫 질문은 Case 09의 whose 구조("the platform whose clock is small and red")로 읽는다.',
    expressions: [
      'the platform whose clock is small and red',
      'how many teeth on the real gear?',
      'how many ravens guard the Tower?',
    ],
    recallFrom: 'ep12_m2',
  ),
};
