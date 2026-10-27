import '../../../models/discovery.dart';
import '../../../models/learning.dart';

// Case 10 — The London Raven, at each level.
//
// The facts never move: Poppy is the small, quiet raven with the gold ring
// (R.M. inside it); the four words came Monday NORTH, Tuesday TOWER,
// Wednesday BRIDGE, Thursday THREE (the notes keep their jumbled order:
// Wednesday, Monday, Thursday, Tuesday — the wrong order "of your notes"
// depends on it); two of them put together name the place (Tower of London
// is the trap that holds only TOWER, so the option names never change).
// Before Mission 03 is answered no line, at any level, writes "Tower
// Bridge", "north tower" or three o'clock; Mission 03's note never repeats
// any of the four words; Mission 02's scene after never reads them again.
// The final's papers ARE the puzzle (WHO → WILL do → to WHAT → WHEN), so
// its option labels are never patched. The Shadow is never named.
//
// Kept the same at every level on purpose (the key is still in both
// patches where it is a coverage field):
// * ep10_final.question — how the puzzle is played ("Put the papers in
//   order to read the warning.").
// * ep10_m2 clue note "NORTH · TOWER · BRIDGE · THREE" — puzzle data that
//   Mission 03 reads from the notebook (not patched).
// * intro line 1 "Tower of London, 7:00 AM..." (the rest of the intro
//   differs).
// * ep10_final.transition lines 2 and 6: "THE CLOCKMAKER WILL STOP\nBIG BEN
//   AT MIDNIGHT." and "ROW R\nSEAT 17." (load-bearing; the other lines
//   differ), and the whisper "The Clockmaker is watching me."
//
// Rookie: the base.

const Map<String, Object?> ep10Rookie = {};

// ── Junior ───────────────────────────────────────────────────────────────
const Map<String, Object?> ep10Junior = {
  'synopsis': [
    "Each morning at seven o'clock, a raven flies up to your window.",
    'It carries a small paper with just one word on it.',
    'Put the words together. Someone is trying to send you a message.',
  ],
  'intro': [
    'Tower of London, 7:00 AM...',
    'For four mornings now, a raven has come to your window.',
    'Every time, it drops a little piece of paper.',
    'On each paper, there is only one word.',
    'Someone at the Tower is sending you a secret message.',
  ],
  'caseSummary': "You put the raven's words in the right order and read the secret warning.",
  'hook': 'The Ravenmaster whispers: "Find the Shadow. He knows all of the plan."',
  'glossary': {
    'wears': '(몸에) 하고 있다, 착용하다',
    'noise': '소음, 시끄러운 소리',
    'brought': '가져왔다',
    'nearly': '거의',
    'arrived': '도착했다',
    'jumbled': '뒤죽박죽인',
    'gaze': '바라보다',
    'sail': '(배가) 나아가다',
    'talk': '말하다, 이야기하다',
    'holding': '들고 있는',
    'quietly': '조용히',
    'person': '사람',
  },
  'missions': {
    'ep10_m1': {
      'story': [
        'Seven black ravens hop about on the green grass.',
        'Which one flies to your window each morning?',
      ],
      'letterIntro': 'The Ravenmaster tells you a little about each of his ravens.',
      'letter': 'Jubilee is the biggest of all my ravens.\n'
          'Merlin has one white feather on her wing.\n'
          'Poppy is the smallest, and she wears a gold ring on her leg.\n'
          'Harris makes a lot of noise, and he never flies very far.\n\n'
          'The raven at your window is small and quiet, and it has a gold ring.',
      'question': 'Which raven brings you the words?',
      'options': {
        'a': {'feedback': 'Jubilee is the biggest of all. The raven at your window is small.'},
        'b': {'feedback': 'Merlin has a white feather. Does the note say anything about a gold ring?'},
        'd': {'feedback': 'Harris makes a lot of noise. The raven at your window is quiet.'},
      },
      'hints': [
        'Your raven has three things: it is small, it is quiet and it has a gold ring. Check each raven.',
        "'The smallest' means smaller than every other raven. In the Ravenmaster's note, which raven is small, quiet AND wears a ring?",
      ],
      'clue': {'note': 'The smallest raven, Poppy, is the one bringing the words.'},
      'evidence': {'description': "A very small gold ring from Poppy's leg."},
      'successMessage': "It's Poppy, the smallest raven!",
      'transition': [
        'R.M. ... could it mean Raven Master?',
        'You take out the four papers Poppy has brought you.',
        'On each one, you wrote the day it came.',
      ],
    },
    'ep10_m2': {
      'story': [
        'You lay the four papers out on the old stone wall.',
        'The wind nearly blows them all away!',
      ],
      'letterIntro': 'This is what you wrote in your notes:',
      'letter': 'On Wednesday, Poppy brought the word BRIDGE.\n'
          'On Monday, she brought NORTH.\n'
          'The word on Thursday was THREE.\n'
          'And on Tuesday: TOWER.',
      'question': 'Put the words in the order they arrived. Start with Monday.',
      'feedback': {
        'bridge,north,three,tower': 'That is how your notes are written, not the order of the days. Which day comes first?',
        'bridge,three,north,tower': 'That is how the papers lie on the wall. Which word arrived on Monday?',
      },
      'orderFeedback': 'Begin with Monday. Then, which day comes next?',
      'hints': [
        'Which word came on Monday? Find that one first.',
        'Your notes are all jumbled. Say the days in order, starting with Monday, and match each word to its day.',
      ],
      'evidence': {'description': 'Four small papers, each with one word.'},
      'successMessage': 'NORTH · TOWER · BRIDGE · THREE — in the right order!',
      'transition': [
        'Slowly, you read the four papers one more time.',
        'These words must be telling you about a place.',
        'You gaze out across the river.',
      ],
    },
    'ep10_m3': {
      'story': [
        'From the top of the Tower wall, you can see the river Thames.',
        'Boats sail under the bridges.',
      ],
      'letterIntro': 'The Ravenmaster cannot talk here, so he writes you a note:',
      'letter': "Poppy's four words tell you a place and a time.\n\n"
          'Put two of them together, and you have the name of a place in London.\n'
          'The other two say where and when I will meet you.',
      'question': 'Which place is the message talking about?',
      'options': {
        'a': {'feedback': "Look at Poppy's words in your notebook. Is 'London' or 'Eye' one of them?"},
        'b': {'feedback': "This name has only one of Poppy's words in it. The note says TWO words, put together."},
        'd': {'feedback': "Look again: is 'King's' or 'Cross' one of Poppy's words?"},
      },
      'hints': [
        "Poppy's four words are written in your notebook. Look at them again.",
        "'Put together' means two words next to each other make one name. One word by itself is not enough.",
      ],
      'clue': {'note': "The north tower of the bridge, at three o'clock: that is where and when to meet."},
      'evidence': {'description': 'The Ravenmaster gave it to you at the north tower.'},
      'successMessage': 'It is Tower Bridge!',
      'transition': [
        "At three o'clock, the Ravenmaster is waiting for you at the north tower.",
        '"I could not talk to you," he says. "The Clockmaker is watching me."',
        '"Poppy has brought you one last bag of words."',
      ],
    },
    'ep10_final': {
      'story': [
        'Poppy lands on the bridge, holding a small bag in her beak.',
        'There are four papers inside. This time, each one has a few words.',
      ],
      'letterIntro': 'The Ravenmaster tells you:',
      'letter': 'Make one sentence from the papers.\n\n'
          'First comes WHO?\n'
          'Next: what WILL they do?\n'
          'Then: to WHAT?\n'
          'At the end: WHEN?',
      // How to play it: the same at every level.
      'question': 'Put the papers in order to read the warning.',
      'feedback': {
        'midnight,clockmaker,stop,bigben': "'At midnight' tells you WHEN. The note puts WHEN at the end.",
        'clockmaker,bigben,stop,midnight': 'After WHO, the note asks what they WILL do.',
        'bigben,stop,clockmaker,midnight': 'Big Ben is not a person. The sentence must begin with WHO.',
      },
      'orderFeedback': 'Follow the note: WHO, then what they WILL do, then to WHAT, then WHEN.',
      'hints': [
        'The note asks four questions, one after another. Find one paper for each question.',
        "A 'who' is a person. 'Will stop' tells what someone will do. A 'when' is a time.",
      ],
      'evidence': {'description': 'The last message Poppy brought.'},
      'successMessage': 'The four papers make a warning!',
      'transition': [
        'Now the warning is clear.',
        'THE CLOCKMAKER WILL STOP\nBIG BEN AT MIDNIGHT.',
        'The Ravenmaster says quietly:\n"The Clockmaker is watching me."',
        'There is very little time.',
        'Then you think of an old ticket:',
        'ROW R\nSEAT 17.',
      ],
    },
  },
};

// ── Master ───────────────────────────────────────────────────────────────
const Map<String, Object?> ep10Master = {
  'synopsis': [
    'Every morning at seven, a raven alights upon your windowsill.',
    'In its beak is a scrap of paper bearing a single word.',
    'Piece the words together: someone is sending you a message.',
  ],
  'intro': [
    'Tower of London, 7:00 AM...',
    'Four mornings in a row, a raven has visited your window.',
    'Each time, it lets fall a small scrap of paper.',
    'Every scrap bears a single word, and nothing more.',
    'Someone within the Tower is sending you a secret message.',
  ],
  'caseSummary': "You set the raven's words in order and uncovered the secret warning.",
  'hook': 'The Ravenmaster breathes: "Find the Shadow. He knows the plan from start to finish."',
  'glossary': {
    'alights': '(새가) 내려앉다',
    'windowsill': '창턱',
    'scrap': '(종이) 조각',
    'bearing': '(글자를) 지닌',
    'bears': '(글자를) 지니다',
    'piece': '(조각을) 맞추다',
    'uncovered': '알아냈다, 밝혀냈다',
    'strut': '뽐내며 걷다',
    'damp': '축축한',
    'lawn': '잔디밭',
    'describes': '묘사하다',
    'largest': '가장 큰',
    'single': '단 하나의',
    'terribly': '몹시',
    'strays': '(멀리) 벗어나다',
    'visitor': '방문자',
    'details': '세부 사항들',
    'messenger': '전달자',
    'delivered': '배달했다',
    'arrival': '도착',
    'ancient': '아주 오래된',
    'gust': '돌풍',
    'snatches': '낚아채다',
    'arrange': '배열하다',
    'proper': '올바른',
    'pair': '짝짓다',
    'drift': '(시선이) 흘러가다',
    'glide': '미끄러지듯 나아가다',
    'beneath': '~ 아래로',
    'dares': '감히 ~하다 (dares not: 감히 ~하지 못하다)',
    'scribbles': '휘갈겨 쓰다',
    'landmark': '명소, 랜드마크',
    'remaining': '나머지의',
    'shall': '~할 것이다',
    'neither': '둘 다 아닌',
    'consult': '찾아보다',
    'forgive': '용서하다',
    'murmurs': '중얼거리다',
    'clutched': '꽉 쥔',
    'several': '몇몇의',
    'fixed': '정해진',
    'plain': '분명한',
  },
  'missions': {
    'ep10_m1': {
      'story': [
        'Seven ravens strut and hop across the damp green lawn.',
        'Which of them is the one that visits your window?',
      ],
      'letterIntro': 'The Ravenmaster describes his ravens, one by one.',
      'letter': 'Jubilee is the largest of my ravens.\n'
          'Merlin carries a single white feather on her wing.\n'
          'Poppy is the smallest of them all, with a gold ring about her leg.\n'
          'Harris is terribly noisy, and he never strays far.\n\n'
          'The raven who visits you is small, quiet, and wears a gold ring.',
      'question': 'Which raven is carrying the words to you?',
      'options': {
        'a': {'feedback': 'Jubilee is the largest of them all. Is your visitor large or small?'},
        'b': {'feedback': 'Merlin is known for her white feather. Is a gold ring ever mentioned for her?'},
        'd': {'feedback': 'Harris is terribly noisy. Would a noisy bird be called quiet?'},
      },
      'hints': [
        'Three details describe your visitor. Test each raven against all three, not just one.',
        "One raven is 'the smallest of them all'. Does that same raven also fit the other two details in the note?",
      ],
      'clue': {'note': 'Poppy, the smallest of the ravens, is the one carrying the words.'},
      'evidence': {'description': "A tiny gold band worn on Poppy's leg."},
      'successMessage': 'Poppy is your messenger!',
      'transition': [
        'R.M. ... the Raven Master, perhaps?',
        'You lay out the four papers Poppy has delivered.',
        'On each, you had written the day of its arrival.',
      ],
    },
    'ep10_m2': {
      'story': [
        'You spread the four papers along the ancient stone wall.',
        'A gust of wind almost snatches them from your fingers!',
      ],
      'letterIntro': 'Your notes read:',
      'letter': 'Wednesday: the word was BRIDGE.\n'
          'Monday brought the word NORTH.\n'
          "Thursday's paper read THREE.\n"
          'Tuesday: TOWER.',
      'question': 'Arrange the words in the order they arrived, beginning with Monday.',
      'feedback': {
        'bridge,north,three,tower': 'That simply follows your notes. The days themselves come in a different order. Which is first?',
        'bridge,three,north,tower': 'That is merely how the papers lie on the wall. Which word arrived on Monday?',
      },
      'orderFeedback': 'Monday comes first. Which day follows it?',
      'hints': [
        'Begin with the word that arrived on the first day of the week.',
        'The notes are jumbled. Set the days in their proper order, then pair each day with its word.',
      ],
      'evidence': {'description': 'Four scraps of paper, a single word on each.'},
      'successMessage': 'NORTH · TOWER · BRIDGE · THREE: in the order of the days.',
      'transition': [
        'Once more, slowly, you read the four papers.',
        'Somehow, the words must lead to a place.',
        'Your eyes drift out over the river.',
      ],
    },
    'ep10_m3': {
      'story': [
        'From the Tower walls, the river Thames stretches out below you.',
        'Boats glide beneath its many bridges.',
      ],
      'letterIntro': 'The Ravenmaster dares not speak here. Instead, he scribbles a note:',
      'letter': "Poppy's four words hide both a place and a time.\n\n"
          'Join two of them, and they form the name of a London landmark.\n'
          'The remaining two tell you where, and when, we shall meet.',
      'question': 'Which place does the message describe?',
      'options': {
        'a': {'feedback': "Neither 'London' nor 'Eye' appears among Poppy's words. Consult your notebook."},
        'b': {'feedback': "Just one of Poppy's words hides in this name. The note asks for TWO, joined together."},
        'd': {'feedback': "Do 'King's' or 'Cross' appear anywhere among Poppy's words?"},
      },
      'hints': [
        "Turn back to Poppy's four words in your notebook.",
        'Two words joined side by side must form the whole name. A name holding only one of them will not do.',
      ],
      'clue': {'note': "The meeting: the bridge's north tower, at three o'clock."},
      'evidence': {'description': 'Pressed into your hand at the north tower.'},
      'successMessage': 'Tower Bridge — the meeting place!',
      'transition': [
        "At three o'clock, the Ravenmaster stands waiting by the north tower.",
        '"Forgive my silence," he murmurs. "The Clockmaker is watching me."',
        '"Poppy carries one final bag of words for you."',
      ],
    },
    'ep10_final': {
      'story': [
        'Poppy alights on the bridge, a small bag clutched in her beak.',
        'Within lie four papers — and this time, each bears several words.',
      ],
      'letterIntro': 'The Ravenmaster murmurs:',
      'letter': 'Build a single sentence.\n\n'
          'Begin with WHO.\n'
          'Next, what WILL they do?\n'
          'Then, to WHAT will it be done?\n'
          'Finish with WHEN.',
      // How to play it: the same at every level.
      'question': 'Put the papers in order to read the warning.',
      'feedback': {
        'midnight,clockmaker,stop,bigben': "'At midnight' answers WHEN, and the note finishes with WHEN.",
        'clockmaker,bigben,stop,midnight': 'Once you know WHO, what does the note ask next?',
        'bigben,stop,clockmaker,midnight': 'Can a clock tower be a WHO? Read how the note begins.',
      },
      'orderFeedback': 'Keep to the note: WHO, what they WILL do, to WHAT, and finally WHEN.',
      'hints': [
        'Four questions, in a fixed order: each paper answers exactly one of them.',
        'Ask which paper names a person, which an action still to come, which a thing, and which a moment in time.',
      ],
      'evidence': {'description': "Poppy's final message."},
      'successMessage': 'Together, the four papers spell out a warning!',
      'transition': [
        'At last, the warning is plain.',
        'THE CLOCKMAKER WILL STOP\nBIG BEN AT MIDNIGHT.',
        "The Ravenmaster's voice drops to a whisper:\n\"The Clockmaker is watching me.\"",
        'Time is running short.',
        'And then an old ticket comes back to you:',
        'ROW R\nSEAT 17.',
      ],
    },
  },
};

// ── Discovery Moments ────────────────────────────────────────────────────
const Map<String, Discovery> ep10JuniorDiscoveries = {
  'ep10_m1': Discovery(
    type: DiscoveryType.evidenceFound,
    timing: DiscoveryTiming.fromPuzzle,
    title: "POPPY'S RING",
    detail: 'Poppy is the small, quiet raven with the gold ring, and there are letters written inside it.',
    showEvidence: true,
  ),
  'ep10_m2': Discovery(
    type: DiscoveryType.clueConfirmed,
    timing: DiscoveryTiming.beforePuzzle,
    title: 'NORTH · TOWER · BRIDGE · THREE',
    detail: 'Monday, Tuesday, Wednesday, Thursday: the four words in the order Poppy brought them.',
  ),
  'ep10_m3': Discovery(
    type: DiscoveryType.newLead,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'TOWER BRIDGE',
    detail: "Put two of Poppy's words together, and you get the name of a place in London.",
  ),
};

const Map<String, Discovery> ep10MasterDiscoveries = {
  'ep10_m1': Discovery(
    type: DiscoveryType.evidenceFound,
    timing: DiscoveryTiming.fromPuzzle,
    title: "POPPY'S RING",
    detail: 'The small, quiet raven wearing the gold ring is Poppy, and something is written inside the band.',
    showEvidence: true,
  ),
  'ep10_m2': Discovery(
    type: DiscoveryType.clueConfirmed,
    timing: DiscoveryTiming.beforePuzzle,
    title: 'NORTH · TOWER · BRIDGE · THREE',
    detail: 'Monday through Thursday, day by day: the words in the order Poppy delivered them.',
  ),
  'ep10_m3': Discovery(
    type: DiscoveryType.newLead,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'TOWER BRIDGE',
    detail: "Joined side by side, two of Poppy's words name a London landmark.",
  ),
};

// ── The parent report's English ──────────────────────────────────────────
const Map<String, LearningObjective> ep10JuniorLearning = {
  'ep10_m1': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.vocabulary,
    objective: '까마귀 묘사(smallest, quiet, gold ring)를 세 조건으로 맞춘다.',
    expressions: ['Poppy is the smallest', 'small and quiet, and it has a gold ring'],
  ),
  'ep10_m2': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.application,
    skill: LanguageSkill.vocabulary,
    objective: '요일 단어를 이해하고 쪽지를 월요일부터 순서대로 놓는다.',
    expressions: ['On Monday, she brought NORTH', 'And on Tuesday: TOWER'],
  ),
  'ep10_m3': LearningObjective(
    dependency: LanguageDependency.helpful,
    level: LearningLevel.exposure,
    skill: LanguageSkill.vocabulary,
    objective: '두 단어를 합쳐 장소 이름을 만든다(그림 이름이 퍼즐 자체). TOWER 하나만 맞는 이름이 함정이라 두 단어를 모두 확인해야 하지만, 단어 맞춰 보기 수준이다.',
    expressions: ['Put two of them together', 'the name of a place in London'],
    recallFrom: 'ep10_m2',
  ),
  'ep10_final': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.application,
    skill: LanguageSkill.grammarInContext,
    objective: '누가(WHO) → 무엇을 할지(WILL) → 무엇에(WHAT) → 언제(WHEN) 순서로 영어 문장을 조립한다.',
    expressions: ['First comes WHO?', 'what WILL they do?', 'Then: to WHAT?', 'At the end: WHEN?'],
  ),
};

const Map<String, LearningObjective> ep10MasterLearning = {
  'ep10_m1': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.vocabulary,
    objective: '까마귀 묘사(smallest of them all, quiet, gold ring)를 세 조건으로 맞춘다.',
    expressions: ['Poppy is the smallest of them all', 'small, quiet, and wears a gold ring'],
  ),
  'ep10_m2': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.application,
    skill: LanguageSkill.vocabulary,
    objective: '요일 단어를 이해하고 쪽지를 월요일부터 순서대로 놓는다.',
    expressions: ['Monday brought the word NORTH', "Thursday's paper read THREE"],
  ),
  'ep10_m3': LearningObjective(
    dependency: LanguageDependency.helpful,
    level: LearningLevel.exposure,
    skill: LanguageSkill.vocabulary,
    objective: '두 단어를 합쳐 장소 이름을 만든다(그림 이름이 퍼즐 자체). TOWER 하나만 맞는 이름이 함정이라 두 단어를 모두 확인해야 하지만, 단어 맞춰 보기 수준이다.',
    expressions: ['Join two of them', 'the name of a London landmark'],
    recallFrom: 'ep10_m2',
  ),
  'ep10_final': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.application,
    skill: LanguageSkill.grammarInContext,
    objective: '누가(WHO) → 무엇을 할지(WILL) → 무엇에(WHAT) → 언제(WHEN) 순서로 영어 문장을 조립한다.',
    expressions: ['Begin with WHO', 'what WILL they do?', 'to WHAT will it be done?', 'Finish with WHEN'],
  ),
};
