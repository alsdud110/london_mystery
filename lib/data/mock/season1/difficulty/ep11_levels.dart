import '../../../models/discovery.dart';
import '../../../models/learning.dart';

// Case 11 — The Masked Stranger, at each level (PART 6A).
//
// The facts never move: the usher and the actor agree (a white mask, a long
// black cloak, a train whistle), the child does not (a gold mask, a short
// green cloak); THGINDIM read from right to left is MIDNIGHT; the guard's
// "the station that never sleeps" (Case 04's "where trains never sleep",
// which Mission 03's Tip 1 links); the taxi driver's "two big arches and a
// clock tower" decides the unnamed pictures; Case 01's Old Letter
// ("Signed: The Shadow / P.S. I love trains!") names the stranger. Nothing
// before the final's answer names the Shadow, and no tip names the station.
// "door" is only ever the theatre's stage door, and nothing after the case
// says where the Clockmaker's door is (Case 12 M3's riddle) — so the hook,
// unlike the base's, leaves the door out at Junior and Master.
// ROW R / SEAT 17 (Case 06 / 10) stays in the synopsis and the intro.
//
// Intentionally the same as the base at every level (puzzle data, kept so
// the player reasons from the exact words):
//   * ep11_m2.letter  'THGINDIM' (the backwards word itself)
//   * ep11_m2.prompt  '________' (the answer's blanks)
//   * ep11_m3.letter  the taxi driver's words ("He ran north, to a big
//     station. / It has two big arches and a clock tower. / He kept saying:
//     I love trains, I love trains!")
// Load-bearing words kept inside rewritten fields: "Row R, Seat 17"
// (synopsis/intro); "Start with the last letter, M" and the letters I, D, N
// (ep11_m2 Tip 1); "right to left" (ep11_m2 feedback); "the station that
// never sleeps" (ep11_m2 transition, ep11_m3 Tip 1); "where trains never
// sleep" and "Case 04" (ep11_m3 Tip 1); "station" and "Arches" (ep11_m3 Tip
// 2); "arches" (ep11_m3 option d); "We met at the very start.", "I left you
// a letter in a suitcase", "I still love trains." (ep11_final letter);
// "the very start" (ep11_final option b); "Case 01" (ep11_final tips).
//
// Rookie: the base.

const Map<String, Object?> ep11Rookie = {};

// ── Junior ───────────────────────────────────────────────────────────────
const Map<String, Object?> ep11Junior = {
  'synopsis': [
    'After every show, a masked stranger sits alone in Row R, Seat 17.',
    'Three people saw the stranger, but their stories are not all the same.',
    'Compare what they say, and find out who is hiding behind the mask.',
  ],
  'intro': [
    'Covent Garden, half past ten at night...',
    'The show has ended, and the theatre is nearly empty.',
    'But in Row R, Seat 17, a masked stranger is still sitting there.',
    'When the lights come on again, the seat is empty.',
    "The Clockmaker's plan is getting close. And this stranger knows about it.",
  ],
  'caseSummary': 'You compared what every witness said and found out who was hiding behind the mask.',
  'hook': 'The Shadow tells you: "At midnight, the Clockmaker will open his door under Big Ben."',
  'glossary': {
    'alone': '혼자',
    'nearly': '거의',
    'witness': '목격자',
    'witnesses': '목격자들',
    'match': '일치하다',
    'finally': '마침내',
    'wrapped': '감싸인',
    'bow': '(고개 숙여 하는) 인사',
    'hands': '건네주다',
    'closely': '자세히',
    'part': '일부, 한편',
  },
  'missions': {
    'ep11_m1': {
      'story': [
        'Red seats, gold lamps and a big, dark stage fill the theatre.',
        'Tonight, three different people saw the masked stranger.',
      ],
      'letterIntro': 'You write down what each of them says.',
      'letter': 'The usher: "The mask was white. The stranger had on a long black cloak."\n\n'
          'The actor: "It was a white mask with a black cloak. Oh, and I heard a train whistle!"\n\n'
          'The child: "The mask was gold, and the cloak was short and green."',
      'question': 'One of the witnesses does not agree with the other two. Which one?',
      'options': {
        'a': {'feedback': 'The usher and the actor say the same thing: a white mask and a black cloak.'},
        'b': {'feedback': 'The actor tells the same story as the usher. Whose story is different?'},
      },
      'hints': [
        'Look at each story. What colour is the mask? What colour is the cloak?',
        "'Does not agree' means it says something different. Two witnesses tell the same story. Find the one that is not the same in your notes.",
      ],
      'clue': {'note': 'A white mask, a long black cloak, and the sound of a train whistle.'},
      'evidence': {'description': 'Two of the stories match. One does not.'},
      'successMessage': 'The child saw someone who looked quite different!',
      'transition': [
        'The child points at the stage. An actor in a gold mask and a green cloak is standing there.',
        'Behind the stage, you find a white mask lying on a chair.',
        'There is something written inside it.',
      ],
    },
    'ep11_m2': {
      'story': [
        'The white mask feels cold and smooth in your hands.',
        'Inside it, one word is written backwards.',
      ],
      'letterIntro': 'Written inside the mask:',
      // Puzzle data: the same at every level.
      'letter': 'THGINDIM',
      'question': 'What word is written inside the mask?',
      // The answer's blanks: the same at every level.
      'prompt': '________',
      'feedback': {
        'THGINDIM': 'That is the word just as it is written. Try reading it from right to left.',
      },
      'hints': [
        'Start with the last letter, M. Then keep going left: I, D, N...',
        "It is a time of day: twelve o'clock at night.",
      ],
      'clue': {'note': 'The plan will happen at midnight.'},
      'evidence': {'description': 'Someone left it behind the stage.'},
      'successMessage': 'The word is MIDNIGHT!',
      'transition': [
        'Footsteps! The stranger runs out through the stage door.',
        'Then you hear a sound: toot-toot, like a little train whistle.',
        'A guard calls out: "He went to the station that never sleeps!"',
      ],
    },
    'ep11_m3': {
      'story': [
        'Outside, the street is dark and wet with rain.',
        'A taxi driver saw the stranger run past him.',
      ],
      'letterIntro': 'The taxi driver tells you:',
      // Puzzle data (TYPE B): the driver's words, the same at every level.
      'letter': '"He ran north, to a big station.\n'
          'It has two big arches and a clock tower.\n'
          'He kept saying: I love trains, I love trains!"',
      'question': 'Where did the stranger run to?',
      'options': {
        'b': {'feedback': 'A palace with a flag on top. Does it have two big arches and a clock tower?'},
        'c': {'feedback': "A park does not have a clock tower. Read the driver's words again."},
        'd': {'feedback': 'Yes, a tall clock tower. But can you see the two big arches?'},
      },
      'hints': [
        "The guard said 'the station that never sleeps'. In Case 04, a letter talked about the place 'where trains never sleep'. Which place was that?",
        'A station is where trains stop. Arches are big round shapes, like the top of a tunnel. Look for arches and a clock tower together.',
      ],
      'clue': {'note': 'The stranger loves trains, just like someone from your very first case.'},
      'evidence': {'description': 'Someone dropped it by the stage door.'},
      'successMessage': 'He ran to the big station!',
      'transition': [
        'On Platform 9, you finally catch up with the stranger.',
        'He turns to face you, wrapped in a long black cloak.',
        'Who can it be?',
      ],
    },
    'ep11_final': {
      'story': [
        'The stranger smiles and gives a little bow.',
        '"Hello again, Detective {detectiveName}," he says. "Do you still remember me?"',
      ],
      'letterIntro': 'He hands you a small card.',
      'letter': 'We met at the very start.\n'
          'I left you a letter in a suitcase.\n'
          'I still love trains.\n\n'
          'I am not with the Raven Society any more. Now I want to help you.',
      'question': 'Who is the stranger behind the mask?',
      'options': {
        'a': {'feedback': 'Inspector Grey helped you in Case 06. But did he leave you a letter at the very start?'},
        'b': {'feedback': "Mrs Robin had a suitcase in Case 08. But 'the very start' means your first case."},
        'c': {'feedback': 'The Ravenmaster sent words with Poppy. Who signed the letter in your first case?'},
      },
      'hints': [
        "'The very start' means your first case. Open your Case Archive and go to Case 01. What was inside a suitcase there?",
        'Open Case 01 in your Case Archive. Look closely at the letter from the suitcase. Whose name is at the bottom?',
      ],
      'evidence': {'description': 'He was a thief. Is he a friend now?'},
      'successMessage': 'It is the Shadow, from your first case!',
      'transition': [
        'The mask comes off.',
        'It is the Shadow.',
        'But this time,\nhe wants to help you.',
        'He is not part of the Raven Society any more.',
        'And he knows\nwhat the Clockmaker is going to do.',
        'Midnight is coming closer.',
        'Big Ben is waiting for it.',
      ],
    },
  },
};

// ── Master ───────────────────────────────────────────────────────────────
const Map<String, Object?> ep11Master = {
  'synopsis': [
    'Night after night, when the curtain falls, a masked stranger waits in Row R, Seat 17.',
    'Three witnesses saw this stranger, yet their accounts do not all agree.',
    'Weigh one account against another, and uncover who hides behind the mask.',
  ],
  'intro': [
    'Covent Garden, 10:30 PM, and the night is cold...',
    'The final curtain has fallen. The theatre is all but empty.',
    'Yet in Row R, Seat 17, a masked stranger sits perfectly still.',
    'The moment the lights come up, the seat stands empty.',
    "The Clockmaker's plan draws near — and this stranger knows it.",
  ],
  'caseSummary': 'You weighed every account against the others and unmasked the stranger at last.',
  'hook': 'The Shadow leans close: "When midnight strikes, the Clockmaker opens his door under Big Ben."',
  'glossary': {
    'curtain': '(무대의) 막',
    'witnesses': '목격자들',
    'accounts': '진술, 이야기',
    'weigh': '(비교해) 따져 보다',
    'uncover': '밝혀내다',
    'perfectly': '완전히',
    'draws': '(가까이) 다가오다',
    'velvet': '벨벳',
    'vast': '아주 넓은',
    'wrapped': '감싸인',
    'strangest': '가장 이상한',
    'apart': '따로, 동떨어져',
    'entirely': '완전히',
    'backstage': '무대 뒤에서',
    'leftwards': '왼쪽으로',
    'dead': '(dead of night: 한밤중)',
    'flees': '달아나다',
    'fled': '달아났다',
    'flee': '달아나다',
    'drifts': '(소리가) 흘러오다',
    'glistens': '반짝이다',
    'dash': '급히 달려가다',
    'mouth': '입구',
    'curved': '굽은',
    'adores': '아주 좋아하다',
    'abandoned': '버려진',
    'sweeps': '휙 움직이다',
    'presses': '(손에) 쥐여 주다',
    'ally': '협력자, 아군',
    'wish': '바라다',
    'perhaps': '어쩌면',
    'unmasked': '가면을 벗겼다',
    'creeps': '살금살금 다가오다',
  },
  'missions': {
    'ep11_m1': {
      'story': [
        'Rows of red velvet seats, glowing gold lamps and a vast, dark stage.',
        'Three people caught sight of the masked stranger tonight.',
      ],
      'letterIntro': 'You note down each account in turn.',
      'letter': 'The usher: "The mask was white, and the stranger was wrapped in a long black cloak."\n\n'
          'The actor: "White mask, black cloak. And — strangest of all — I heard a train whistle!"\n\n'
          'The child: "His mask was gold! And his cloak was green, and short."',
      'question': 'One witness does not agree with the other two. Whose story is it?',
      'options': {
        'a': {'feedback': "The usher's account matches the actor's: a white mask and a black cloak."},
        'b': {'feedback': 'The actor and the usher agree. Look for the account that stands apart.'},
      },
      'hints': [
        'Set the three accounts side by side. Do the colours match?',
        "To 'not agree' is to tell a different story. Two accounts in your notes match almost word for word; which one stands apart?",
      ],
      'clue': {'note': 'A white mask, a long black cloak — and, oddly, a train whistle.'},
      'evidence': {'description': 'Two accounts match; the third stands alone.'},
      'successMessage': 'The child was describing someone else entirely!',
      'transition': [
        'The child points towards the stage, where an actor stands in a gold mask and a green cloak.',
        'Backstage, a white mask has been left on a chair.',
        'Something is written on the inside.',
      ],
    },
    'ep11_m2': {
      'story': [
        'The white mask is cold and smooth as glass.',
        'Inside, a single word has been written backwards.',
      ],
      'letterIntro': 'On the inside of the mask:',
      // Puzzle data: the same at every level.
      'letter': 'THGINDIM',
      'question': 'What does the word inside the mask really say?',
      // The answer's blanks: the same at every level.
      'prompt': '________',
      'feedback': {
        'THGINDIM': 'That is only how the word was written. Read it from right to left instead.',
      },
      'hints': [
        'Start with the last letter, M, and move leftwards: I, D, N...',
        "The word names an hour: twelve o'clock, in the dead of night.",
      ],
      'clue': {'note': 'The plan is set for midnight.'},
      'evidence': {'description': 'Abandoned behind the stage.'},
      'successMessage': 'MIDNIGHT — the hidden word!',
      'transition': [
        'Hurried footsteps! The stranger flees through the stage door.',
        'A sound drifts back: toot-toot, like a tiny train whistle.',
        'A guard cries out: "He went to the station that never sleeps!"',
      ],
    },
    'ep11_m3': {
      'story': [
        'Outside, rain glistens on the dark street.',
        'A taxi driver watched the stranger dash past.',
      ],
      'letterIntro': 'The taxi driver leans out of his window:',
      // Puzzle data (TYPE B): the driver's words, the same at every level.
      'letter': '"He ran north, to a big station.\n'
          'It has two big arches and a clock tower.\n'
          'He kept saying: I love trains, I love trains!"',
      'question': 'Where did the stranger flee?',
      'options': {
        'b': {'feedback': 'A grand palace beneath a flag. Can you see two big arches, or a clock tower?'},
        'c': {'feedback': "A park, with no clock tower in sight. Go back to the driver's words."},
        'd': {'feedback': 'A tall clock tower, certainly. But where are the two big arches?'},
      },
      'hints': [
        "The guard spoke of 'the station that never sleeps'. Think back to Case 04, and a letter about the place 'where trains never sleep'.",
        'Trains come and go at a station. Arches are great curved shapes, like the mouth of a tunnel. Which picture shows them beside a clock tower?',
      ],
      'clue': {'note': 'The stranger adores trains — much like someone from your very first case.'},
      'evidence': {'description': 'Found lying by the stage door.'},
      'successMessage': 'He fled to the station!',
      'transition': [
        'On Platform 9, at last, you close in on the stranger.',
        'Slowly, he turns. A long black cloak sweeps around him.',
        'Who is he?',
      ],
    },
    'ep11_final': {
      'story': [
        'The stranger smiles and sweeps into a low bow.',
        '"We meet again, Detective {detectiveName}," he says softly. "Do you remember me?"',
      ],
      'letterIntro': 'He presses a small card into your hand.',
      'letter': 'We met at the very start.\n'
          'I left you a letter in a suitcase.\n'
          'I still love trains.\n\n'
          'I have turned my back on the Raven Society. Now I wish to help you.',
      'question': 'Whose face is hidden behind the mask?',
      'options': {
        'a': {'feedback': 'Inspector Grey was your ally in Case 06. Was it he who left a letter at the very start?'},
        'b': {'feedback': "Mrs Robin carried a suitcase in Case 08 — yet 'the very start' points to your first case."},
        'c': {'feedback': 'The Ravenmaster sent his words with Poppy. Whose name was signed on the letter in your first case?'},
      },
      'hints': [
        "'The very start' takes you back to your first case. In your Case Archive, what waited inside a suitcase in Case 01?",
        'Return to Case 01 in your Case Archive and study the letter from the suitcase. How did its writer sign it?',
      ],
      'evidence': {'description': 'Once a thief. Now, perhaps, a friend?'},
      'successMessage': 'The Shadow, unmasked at last!',
      'transition': [
        'The mask falls away.',
        'It is the Shadow.',
        'Yet this time,\nhe stands with you.',
        'He has turned his back on the Raven Society.',
        'And he knows\nexactly what the Clockmaker is planning.',
        'Midnight creeps ever closer.',
        'And Big Ben waits.',
      ],
    },
  },
};

// ── Discovery Moments ────────────────────────────────────────────────────
const Map<String, Discovery> ep11JuniorDiscoveries = {
  'ep11_m1': Discovery(
    type: DiscoveryType.clueConfirmed,
    timing: DiscoveryTiming.beforePuzzle,
    title: 'A TRAIN WHISTLE',
    detail: 'Two stories match: a white mask and a long black cloak. And the actor heard a train whistle too.',
  ),
  'ep11_m2': Discovery(
    type: DiscoveryType.deduction,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'MIDNIGHT',
    detail: 'Read from right to left, the word inside the mask is a time of day.',
  ),
  'ep11_m3': Discovery(
    type: DiscoveryType.newLead,
    timing: DiscoveryTiming.fromPuzzle,
    title: "KING'S CROSS",
    detail: 'Two big arches and a clock tower: this is the station the stranger ran to.',
  ),
};

const Map<String, Discovery> ep11MasterDiscoveries = {
  'ep11_m1': Discovery(
    type: DiscoveryType.clueConfirmed,
    timing: DiscoveryTiming.beforePuzzle,
    title: 'A TRAIN WHISTLE',
    detail: 'Two accounts match — a white mask, a long black cloak — and the actor caught the sound of a train whistle.',
  ),
  'ep11_m2': Discovery(
    type: DiscoveryType.deduction,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'MIDNIGHT',
    detail: 'Read from right to left, the backwards word turns out to be an hour.',
  ),
  'ep11_m3': Discovery(
    type: DiscoveryType.newLead,
    timing: DiscoveryTiming.fromPuzzle,
    title: "KING'S CROSS",
    detail: 'Two big arches and a clock tower: the station where the stranger fled.',
  ),
};

// ── The parent report's English ──────────────────────────────────────────
const Map<String, LearningObjective> ep11JuniorLearning = {
  'ep11_m1': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.sentenceMeaning,
    objective: '세 증언을 비교해 다른 하나("does not agree")를 찾는다.',
    expressions: ['does not agree with the other two', 'the cloak was short and green'],
  ),
  'ep11_m2': LearningObjective(
    dependency: LanguageDependency.low,
    level: LearningLevel.exposure,
    objective: '거꾸로 쓴 글자를 바로 읽는 철자 해독. 영어 의미 이해와는 거의 관계가 없다.',
    expressions: ['Start with the last letter', 'keep going left'],
  ),
  'ep11_m3': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.recall,
    skill: LanguageSkill.vocabulary,
    objective: '그림에 이름이 없다. 경비원의 "the station that never sleeps"를 Case 04의 "where trains never sleep"과 연결하고, 택시 기사의 묘사(two big arches, a clock tower)로 고른다. 시계탑만 있는 그림이 함정이다.',
    expressions: ['the station that never sleeps', 'two big arches and a clock tower', 'where trains never sleep'],
    recallFrom: 'ep04_m1',
  ),
  'ep11_final': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.recall,
    skill: LanguageSkill.sentenceMeaning,
    objective: '"the very start"가 첫 사건임을 이해하고, Case 01 편지의 서명을 다시 찾아 읽는다.',
    expressions: ['We met at the very start', 'I left you a letter in a suitcase', 'Signed: The Shadow'],
    recallFrom: 'm01',
  ),
};

const Map<String, LearningObjective> ep11MasterLearning = {
  'ep11_m1': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.sentenceMeaning,
    objective: '세 증언을 비교해 다른 하나("does not agree")를 찾는다.',
    expressions: ['One witness does not agree with the other two', 'His mask was gold'],
  ),
  'ep11_m2': LearningObjective(
    dependency: LanguageDependency.low,
    level: LearningLevel.exposure,
    objective: '거꾸로 쓴 글자를 바로 읽는 철자 해독. 영어 의미 이해와는 거의 관계가 없다.',
    expressions: ['Start with the last letter', 'move leftwards'],
  ),
  'ep11_m3': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.recall,
    skill: LanguageSkill.vocabulary,
    objective: '그림에 이름이 없다. 경비원의 "the station that never sleeps"를 Case 04의 "where trains never sleep"과 연결하고, 택시 기사의 묘사(two big arches, a clock tower)로 고른다. 시계탑만 있는 그림이 함정이다.',
    expressions: ['the station that never sleeps', 'two big arches and a clock tower', 'where trains never sleep'],
    recallFrom: 'ep04_m1',
  ),
  'ep11_final': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.recall,
    skill: LanguageSkill.sentenceMeaning,
    objective: '"the very start"가 첫 사건임을 이해하고, Case 01 편지의 서명을 다시 찾아 읽는다.',
    expressions: ['We met at the very start', 'I left you a letter in a suitcase', 'Signed: The Shadow'],
    recallFrom: 'm01',
  ),
};
