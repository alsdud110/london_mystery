import '../../../models/discovery.dart';
import '../../../models/learning.dart';

// Case 09 — The Missing Jewel, at each level (PART 6B).
//
// The facts never move: three keys (the maid's small and silver, the cook's
// old and iron, "The guard's key is big and gold."), only a big gold key
// opens the case, the guard lent his key to the new helper ("Yesterday I gave
// it to the new helper!"), A _ _ A with the letter after M twice (ANNA), the
// guards change every two hours from eight, "Anna was seen at the third
// change." (12), "Carl, the guard who lent her his key", and the final's
// note and notes word for word: "Hide it in the thing of the one whose key
// you used.", "Ben has the green bag.", "Anna's thing is not black." Every
// `whose` sentence is kept verbatim at every level (Case 12 reads "whose"
// again): "Whose key opened the jewel case?", "Whose key is big and gold?",
// "But whose key was it?", "Find out whose things hide the secret.",
// "whose key, whose name and whose hat". The final's page never says
// "guard's", "belongs" or Carl's name in a tip; nothing before the answer
// says "hat" but the notes' list of three things; no tip spells HAT, ANNA,
// 12 or "the guard's key", even across words.
//
// Intentionally identical at every level (puzzle data / how to play):
//   ep09_m2.prompt      'NAME: ____'                (how to play)
//   ep09_final.prompt   'IN THE ___'                (how to play)
//   ep09_final.letter   R.'s note + the notes       (puzzle data, whose)
//   ep09_m1.clue.note   "Only the guard's big gold key opens the case."
//                       (the notebook line the final is solved from)
//   ep09_m2.clue.note   "Anna had the guard's key." (puzzle data)
//
// Rookie: the base.

const Map<String, Object?> ep09Rookie = {};

// ── Junior ───────────────────────────────────────────────────────────────
const Map<String, Object?> ep09Junior = {
  'synopsis': [
    'The Blue Star, a jewel of the royal family, is missing from its box.',
    'But the thief never took it out of the palace.',
    'Find out whose things hide the secret.',
  ],
  'intro': [
    'Buckingham Palace, at ten in the morning...',
    "The jewel box from Mrs Robin's suitcase came from this palace.",
    'Now the Blue Star, a royal jewel, has gone.',
    'But the palace gates stayed locked all night long.',
    'So the jewel is still somewhere inside the palace.',
  ],
  'caseSummary': 'You worked out whose key, whose name and whose hat — and you found the Blue Star again.',
  'hook': 'A card was hidden inside the hat: "The jewel was never the prize. Watch the ravens."',
  'glossary': {
    'missing': '없어진, 사라진',
    'explains': '설명하다',
    'tries': '애쓰다, 해 보다',
    'remember': '기억하다',
    'slowly': '천천히',
    'twice': '두 번',
    'brought': '가져왔다',
    'along': '가지고, 함께',
    'drops': '떨어지다',
    'owner': '주인',
    'rightful': '원래의, 정당한',
    'warning': '경고',
  },
  'missions': {
    'ep09_m1': {
      'story': [
        'The glass case stands open, and the velvet cushion is empty.',
        'Nobody broke the lock. Somebody opened it with a key.',
      ],
      'letterIntro': 'The head butler explains who has the keys.',
      'letter': 'Only three people have a key to this room.\n\n'
          "The maid's key is small and silver.\n"
          "The cook's key is old and made of iron.\n"
          "The guard's key is big and gold.\n\n"
          'Only a big gold key can open the jewel case.',
      'question': 'Look at the three keys. Whose key opened the jewel case?',
      'options': {
        'a': {'feedback': "The maid's key is small and silver. Look for the key that is big and gold."},
        'b': {'feedback': "The cook's key is old and iron. What does the last line say?"},
        'd': {'feedback': "The butler talks about three keys only. Is the King's key one of them?"},
      },
      'hints': [
        'Read the last line again. What kind of key opens the jewel case?',
        "'The maid's key' is the key that belongs to the maid. Whose key is big and gold?",
      ],
      'clue': {'note': "Only the guard's big gold key opens the case."},
      'evidence': {'description': 'Someone left it on the empty cushion.'},
      'successMessage': "So it was the guard's key!",
      'transition': [
        'The guard looks very surprised.',
        '"My key? Yesterday I gave it to the new helper!"',
        "But what is the new helper's name?",
      ],
    },
    'ep09_m2': {
      'story': [
        'Coats hang on a row of hooks, and each hook has a name tag.',
        "The tag on the new helper's hook is torn.",
      ],
      'letterIntro': 'The guard thinks hard and tries to remember.',
      'letter': 'Her name is only four letters long.\n'
          'It starts with A, and it ends with A.\n'
          'The two letters in the middle are the same.\n'
          'They are the letter that comes after M in the alphabet.',
      'question': 'What is the name of the new helper?',
      // How to play it: the same at every level.
      'prompt': 'NAME: ____',
      'feedback': {
        'AMMA': 'Say the alphabet out loud. Which letter comes AFTER M?',
        'ALLA': 'L comes before M, not after it. Try the next letter after M.',
      },
      'hints': [
        'Say the alphabet slowly: ... K, L, M, and what comes next?',
        'Write that letter twice, between the two As.',
      ],
      'clue': {'note': "Anna had the guard's key."},
      'evidence': {'description': "Taken from the new helper's hook."},
      'successMessage': 'The torn tag says Anna!',
      'transition': [
        'But Anna is not in the staff room.',
        'The guard says: "The guards change in the courtyard."',
        '"Then nobody is watching the jewel room."',
      ],
    },
    'ep09_m3': {
      'story': [
        'Soldiers in red coats march in lines across the courtyard.',
        'The guard hands you the timetable.',
      ],
      'letterIntro': 'This is what the timetable says:',
      'letter': 'The guards change every two hours.\n'
          "The first change of the day is at eight o'clock.\n\n"
          'Someone has written a note in pencil at the bottom:\n'
          '"Anna was seen at the third change."',
      'question': 'At what hour was Anna seen in the courtyard?',
      'feedback': {
        '3': "'The third change' is asking for a time, not a number of changes.",
        '6': "'Every two hours' means you add two hours each time.",
        '10': 'That is only the second change. Count three changes: the first one is at eight.',
        '14': "Count again. The first change is at eight o'clock.",
      },
      'hints': [
        'Look at the timetable. When is the first change, and how often do the guards change?',
        "'Every two hours' means add two hours each time. And 'the third change' counts the first one too.",
      ],
      'clue': {'note': "At twelve o'clock, Anna hid the jewel."},
      'evidence': {'description': 'It shows when the guards change.'},
      'successMessage': "It was twelve o'clock!",
      'transition': [
        "Three people were in the courtyard at twelve o'clock:",
        'Anna, Ben the gardener and Carl, the guard who lent her his key.',
        'Each one had brought one thing along.',
      ],
    },
    'ep09_final': {
      'story': [
        'Anna, Ben the gardener and Carl the guard stand by the palace gate.',
        'The Blue Star is hidden in one of their things.',
      ],
      'letterIntro': "A small note drops out of Anna's pocket. R. has signed it.",
      // Puzzle data: R.'s rule and the notes, the same at every level.
      'letter': 'Hide it in the thing of the one whose key you used.\n'
          '— R.\n\n'
          'Your notes:\n'
          'Three things: a red umbrella, a green bag and a tall black hat.\n'
          'Ben has the green bag.\n'
          "Anna's thing is not black.",
      'question': 'Where is the Blue Star hidden? Type the thing.',
      // How to play it: the same at every level.
      'prompt': 'IN THE ___',
      'feedback': {
        'UMBRELLA': "Anna borrowed the key, but the note asks for the one WHOSE key you used. Was it really Anna's key?",
        'RED UMBRELLA': "The red umbrella is Anna's. But the note says the one WHOSE key you used: did the key belong to Anna?",
        'BAG': "Ben has the green bag. Did Ben's key open the jewel case?",
        'GREEN BAG': 'Ben owns the green bag. Whose key opened the jewel case?',
        'ANNA': 'The note wants a thing, not a person.',
      },
      'hints': [
        'Anna was the one who used the key. But whose key was it? Remember the Jewel Room.',
        "Open your notebook: whose key opened the jewel case? Find the owner at the gate, then check your notes to work out the owner's thing.",
      ],
      'evidence': {'description': 'The royal jewel, back in its rightful place.'},
      'successMessage': 'The Blue Star was hidden in the hat!',
      'transition': [
        'The Blue Star is safe again.',
        "But a raven is drawn on the back\nof Anna's name tag.",
        'And the card inside the hat\ngave a warning:',
        '"The jewel was never the prize."',
        '"Watch the ravens."',
      ],
    },
  },
};

// ── Master ───────────────────────────────────────────────────────────────
const Map<String, Object?> ep09Master = {
  'synopsis': [
    'The Blue Star, a priceless royal jewel, has disappeared from its box.',
    'Yet the thief never carried it beyond the palace walls.',
    'Find out whose things hide the secret.',
  ],
  'intro': [
    "Buckingham Palace, ten o'clock in the morning...",
    "The jewel box in Mrs Robin's suitcase came from these very halls.",
    'And now the Blue Star, a royal jewel, has vanished.',
    'Yet the palace gates stood locked from dusk until dawn.',
    'The jewel has not left the palace. It is hidden here, somewhere.',
  ],
  'caseSummary': 'You untangled whose key, whose name and whose hat — and brought the Blue Star back to light.',
  'hook': 'Tucked inside the hat was a card: "The jewel was never the prize. Watch the ravens."',
  'glossary': {
    'priceless': '값을 매길 수 없이 귀한',
    'disappeared': '사라졌다',
    'beyond': '~ 너머로',
    'vanished': '사라졌다',
    'dusk': '해 질 녘',
    'dawn': '새벽',
    'untangled': '(엉킨 것을) 풀어냈다',
    'tucked': '끼워 넣은',
    'remains': '남아 있다',
    'grave': '진지한, 엄숙한',
    'forged': '(쇠를) 두드려 만든',
    'yields': '(눌려) 열리다, 굴복하다',
    'condition': '조건',
    'demand': '요구하다',
    'owns': '소유하다',
    'astonishment': '깜짝 놀람',
    'frowns': '얼굴을 찌푸리다',
    'memory': '기억',
    'begins': '시작하다',
    'finishes': '끝나다',
    'alike': '서로 같은',
    'follows': '뒤따르다',
    'recite': '외우다, 소리 내어 읊다',
    'ranks': '(군인들의) 줄',
    'scarlet': '진홍색의',
    'sharp': '(시각) 정각에',
    'beneath': '~ 아래에',
    'pencilled': '연필로 쓴',
    'rhythm': '규칙적인 흐름',
    'precisely': '정확히',
    'stroke': '(시계가) 치는 순간',
    'figures': '사람의 모습',
    'folded': '접힌',
    'slips': '미끄러져 나오다',
    'owning': '가지고 있는 것, 소유',
    'proper': '알맞은, 제자리의',
    'bore': '(글을) 담고 있었다',
  },
  'missions': {
    'ep09_m1': {
      'story': [
        'The glass case stands open; upon the velvet cushion, nothing remains.',
        'The lock is unbroken. Someone came with a key.',
      ],
      'letterIntro': 'The head butler, grave and quiet, tells you about the keys.',
      'letter': 'Three people in the palace carry a key to this room.\n\n'
          "The maid's key is small and silver.\n"
          "The cook's key is old and forged from iron.\n"
          "The guard's key is big and gold.\n\n"
          'The jewel case yields to one key alone: a big gold one.',
      'question': 'Three keys, one lock. Whose key opened the jewel case?',
      'options': {
        'a': {'feedback': 'A small silver key? Which key is the big gold one?'},
        'b': {'feedback': "An old iron key would not fit. Read the butler's final line once more."},
        'd': {'feedback': "Only three keys are named. Was the King's among them?"},
      },
      'hints': [
        'The butler ends with a single condition. Which kind of key does the case demand?',
        "An 's tells you who owns a thing: 'the cook's key' is the cook's own. Whose key is big and gold?",
      ],
      'clue': {'note': "Only the guard's big gold key opens the case."},
      'evidence': {'description': 'Left lying upon the empty velvet cushion.'},
      'successMessage': "It was the guard's key all along!",
      'transition': [
        'The guard stares at you in astonishment.',
        '"My key? Yesterday I gave it to the new helper!"',
        "But what, then, is the new helper's name?",
      ],
    },
    'ep09_m2': {
      'story': [
        'Coats hang in a neat row of hooks, each marked with a name tag.',
        "The new helper's tag, though, is badly torn.",
      ],
      'letterIntro': 'The guard frowns, searching his memory.',
      'letter': 'Her name is just four letters long.\n'
          'It begins with an A and finishes with an A.\n'
          'Between them sit two letters, both alike:\n'
          'each is the one that follows M in the alphabet.',
      'question': 'By what name is the new helper known?',
      // How to play it: the same at every level.
      'prompt': 'NAME: ____',
      'feedback': {
        'AMMA': 'M itself is not the letter. What follows it?',
        'ALLA': 'L comes before M. You need the letter just beyond it.',
      },
      'hints': [
        'Recite the alphabet up to M. Which letter waits just after it?',
        'Place that letter in both empty middle spaces, with an A at each end.',
      ],
      'clue': {'note': "Anna had the guard's key."},
      'evidence': {'description': "Found on the new helper's hook."},
      'successMessage': 'The torn tag gives up its secret: Anna!',
      'transition': [
        'Anna is nowhere to be found in the staff room.',
        'The guard lowers his voice: "The guards change in the courtyard."',
        '"And while they do, no one watches the jewel room."',
      ],
    },
    'ep09_m3': {
      'story': [
        'Ranks of soldiers in scarlet coats march across the courtyard.',
        'The guard holds out the timetable for you to read.',
      ],
      'letterIntro': 'The timetable reads:',
      'letter': 'The guards change every two hours,\n'
          "beginning at eight o'clock sharp.\n\n"
          'Beneath, a pencilled note has been added:\n'
          '"Anna was seen at the third change."',
      'question': 'At what hour of the day was Anna seen?',
      'feedback': {
        '3': "'The third change' names a moment, not a count.",
        '6': 'Two hours pass between each change. Count forward from eight.',
        '10': 'That would be the second change. The first is at eight — count on once more.',
        '14': "You started counting too late. The first change falls at eight o'clock.",
      },
      'hints': [
        'The timetable gives a starting hour and a steady rhythm. What are they?',
        'Begin at the first change and step forward two hours at a time, until you reach the third.',
      ],
      'clue': {'note': "Twelve o'clock: the hour when Anna hid the jewel."},
      'evidence': {'description': 'The hours at which the guards change.'},
      'successMessage': "Twelve o'clock, precisely!",
      'transition': [
        'At the stroke of twelve, three figures stood in the courtyard:',
        'Anna, Ben the gardener and Carl, the guard who lent her his key.',
        'Each of them carried a single thing.',
      ],
    },
    'ep09_final': {
      'story': [
        'Anna, Ben the gardener and Carl the guard wait in silence at the palace gate.',
        'Somewhere among their things, the Blue Star lies hidden.',
      ],
      'letterIntro': "A folded note slips from Anna's pocket, signed with a single R.",
      // Puzzle data: R.'s rule and the notes, the same at every level.
      'letter': 'Hide it in the thing of the one whose key you used.\n'
          '— R.\n\n'
          'Your notes:\n'
          'Three things: a red umbrella, a green bag and a tall black hat.\n'
          'Ben has the green bag.\n'
          "Anna's thing is not black.",
      'question': 'In which thing does the jewel lie hidden? Type the thing.',
      // How to play it: the same at every level.
      'prompt': 'IN THE ___',
      'feedback': {
        'UMBRELLA': 'Anna borrowed the key, yet the note speaks of WHOSE key you used. Did it ever belong to her?',
        'RED UMBRELLA': "The red umbrella is Anna's — but the note means the one WHOSE key you used. Was it ever hers?",
        'BAG': "The bag belongs to Ben. Was it Ben's key in the lock?",
        'GREEN BAG': "Ben's green bag, true. Whose key opened the jewel case?",
        'ANNA': 'Anna is a person. The note asks for a thing.',
      },
      'hints': [
        'Using a key is not the same as owning it. But whose key was it? The Jewel Room remembers.',
        'Your notebook holds the answer to whose key opened the jewel case. Match the owner to one of the three at the gate, then let your notes do the rest.',
      ],
      'evidence': {'description': 'The royal jewel, at last returned to its proper place.'},
      'successMessage': 'The Blue Star lay hidden inside the hat all along!',
      'transition': [
        'The Blue Star is safe at last.',
        "Yet on the back of Anna's name tag,\na raven has been drawn.",
        'And the card tucked inside the hat\nbore a warning:',
        '"The jewel was never the prize."',
        '"Watch the ravens."',
      ],
    },
  },
};

// ── Discovery Moments ────────────────────────────────────────────────────
const Map<String, Discovery> ep09JuniorDiscoveries = {
  'ep09_m1': Discovery(
    type: DiscoveryType.deduction,
    timing: DiscoveryTiming.fromPuzzle,
    title: "THE GUARD'S KEY",
    detail: 'Only a big gold key can open the jewel case.',
  ),
  'ep09_m2': Discovery(
    type: DiscoveryType.deduction,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'ANNA',
    detail: "The new helper's name is A, two Ns, then A.",
  ),
  'ep09_m3': Discovery(
    type: DiscoveryType.storyDiscovery,
    timing: DiscoveryTiming.fromPuzzle,
    title: "TWELVE O'CLOCK",
    detail: 'Eight, then ten, then twelve: the third change of the guard, when Anna was seen.',
  ),
};

const Map<String, Discovery> ep09MasterDiscoveries = {
  'ep09_m1': Discovery(
    type: DiscoveryType.deduction,
    timing: DiscoveryTiming.fromPuzzle,
    title: "THE GUARD'S KEY",
    detail: 'The jewel case yields to one key alone: the big gold one.',
  ),
  'ep09_m2': Discovery(
    type: DiscoveryType.deduction,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'ANNA',
    detail: "A, a pair of Ns, and A once more: the new helper's name.",
  ),
  'ep09_m3': Discovery(
    type: DiscoveryType.storyDiscovery,
    timing: DiscoveryTiming.fromPuzzle,
    title: "TWELVE O'CLOCK",
    detail: 'Eight, ten, twelve — at the third changing of the guard, Anna was seen.',
  ),
};

// ── The parent report's English ──────────────────────────────────────────
const Map<String, LearningObjective> ep09JuniorLearning = {
  'ep09_m1': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.grammarInContext,
    objective: "소유 표현('s)을 이해하고 열쇠의 주인을 찾는다.",
    expressions: ["The guard's key is big and gold", 'Only a big gold key can open the jewel case'],
  ),
  'ep09_m2': LearningObjective(
    dependency: LanguageDependency.helpful,
    level: LearningLevel.exposure,
    skill: LanguageSkill.vocabulary,
    objective: '이름의 글자 설명을 읽고 이름을 쓴다. 알파벳 순서 퍼즐에 가깝다.',
    expressions: ['Her name is only four letters long', 'the letter that comes after M'],
  ),
  'ep09_m3': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.sentenceMeaning,
    objective: '"every two hours", "the third change"를 읽고 시각을 계산한다.',
    expressions: ["The first change of the day is at eight o'clock", 'Anna was seen at the third change'],
  ),
  'ep09_final': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.recall,
    skill: LanguageSkill.grammarInContext,
    objective: '"whose key"(누구의 열쇠인가)와 "누가 썼는가"를 구분하고, 앞 미션의 열쇠 주인을 다시 확인한다.',
    expressions: ['the one whose key you used'],
    recallFrom: 'ep09_m1',
  ),
};

const Map<String, LearningObjective> ep09MasterLearning = {
  'ep09_m1': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.grammarInContext,
    objective: "소유 표현('s)을 이해하고 열쇠의 주인을 찾는다.",
    expressions: ["The guard's key is big and gold", 'The jewel case yields to one key alone'],
  ),
  'ep09_m2': LearningObjective(
    dependency: LanguageDependency.helpful,
    level: LearningLevel.exposure,
    skill: LanguageSkill.vocabulary,
    objective: '이름의 글자 설명을 읽고 이름을 쓴다. 알파벳 순서 퍼즐에 가깝다.',
    expressions: ['It begins with an A and finishes with an A', 'the one that follows M in the alphabet'],
  ),
  'ep09_m3': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.sentenceMeaning,
    objective: '"every two hours", "the third change"를 읽고 시각을 계산한다.',
    expressions: ["beginning at eight o'clock sharp", 'Anna was seen at the third change'],
  ),
  'ep09_final': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.recall,
    skill: LanguageSkill.grammarInContext,
    objective: '"whose key"(누구의 열쇠인가)와 "누가 썼는가"를 구분하고, 앞 미션의 열쇠 주인을 다시 확인한다.',
    expressions: ['the one whose key you used'],
    recallFrom: 'ep09_m1',
  ),
};
