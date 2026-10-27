import '../../../models/discovery.dart';
import '../../../models/learning.dart';

// Case 07 — The Lost Map, at each level (PART 7, London).
//
// The facts never move: the thief's note "Go past the tree. / Turn right at
// the bridge. / Look beside the bench." (Mission 01 picks the right bench);
// the box not on the shelf but under the table, behind the green watering
// can; the two lines of Mission 03 (the river piece is not at the top; the
// station and river pieces do not touch), which leave one order, station,
// park, river; the Joined Map's arrow north, to the top of the park; and
// Grey's way (past the tree, across the bridge, then LEFT) which, with the
// arrow, picks map B. The final's spot is named nowhere before it is
// chosen, and never in a Discovery Moment, at any level.
//
// Kept the same at every level on purpose (puzzle data: the exact words are
// what the player reasons from), still written into both patches:
//   ep07_m1.letter    — the thief's three directions
//   ep07_m3.letter    — the instructions' two lines (one order)
//   ep07_final.letter — Inspector Grey's way
// Kept word for word inside otherwise rewritten fields:
//   ep07_m2.transition '"Put me together, and I will show you the way."'
//   ep07_m3.transition '"The last piece waits where my arrow points."'
//   ep07_m3.clue.note  'Station at the top'
//   ep07_final.transition 'PLATFORM 9.'
//
// Rookie: the base.

const Map<String, Object?> ep07Rookie = {};

// ── Junior ───────────────────────────────────────────────────────────────
const Map<String, Object?> ep07Junior = {
  'synopsis': [
    'Someone has stolen an old map of London from Hyde Park.',
    'All that is left are a few pieces and some directions.',
    'Follow the directions and put the map back together.',
  ],
  'intro': [
    'Hyde Park, 7:00 in the morning...',
    'Inspector Grey was right after all.',
    "The old map of London has gone from the park keeper's lodge.",
    'You have one piece from the Tower, but the Raven Society has the rest.',
    'Why would the Raven Society want an old map?',
  ],
  'caseSummary': 'You followed every direction, put the pieces together and found the lost map of London.',
  'hook': 'Nine black ravens are drawn on the map, all around Platform 9.',
  'glossary': {
    'stolen': '훔친 (steal의 과거분사)',
    'dusty': '먼지투성이의',
    'message': '메시지, 적힌 글',
    'allowed': '허락된',
    'complete': '완성된',
    'spot': '지점, 장소',
  },
  'missions': {
    'ep07_m1': {
      'story': [
        'The park keeper is waiting for you at the park gate.',
        'Last night, a thief dropped a note and a map piece here.',
      ],
      'letterIntro': 'This is what the note says:',
      // Puzzle data: the same at every level.
      'letter': 'Go past the tree.\n'
          'Turn right at the bridge.\n'
          'Look beside the bench.',
      'question': 'Which map shows the right spot to look?',
      'options': {
        'a': {'feedback': 'The note says to go PAST the tree. Do not stop there.'},
        'b': {'feedback': 'Look at the turn at the bridge again. Which way does the note say?'},
        'd': {'feedback': 'That spot is far past the bridge. The note tells you to look beside the bench.'},
      },
      'hints': [
        'Put your finger at the bottom of the map. Walk it up the path, one line of the note at a time.',
        "'Go past the tree' means walk on by it. Then the turn at the bridge and the bench tell you where to stop.",
      ],
      'clue': {'note': 'Turn right at the bridge, then look beside the bench.'},
      'evidence': {'description': 'You found it beside the bench.'},
      'successMessage': 'The directions took you to the map piece beside the bench!',
      'transition': [
        'There, in the grass beside the bench, lies a map piece.',
        'The park keeper looks worried.',
        '"Someone has been in my boathouse, too!"',
      ],
    },
    'ep07_m2': {
      'story': [
        'The old boathouse is full of oars, ropes and dusty boxes.',
        'You can see a table, a shelf and a green watering can.',
      ],
      'letterIntro': 'Someone has scratched a message on the door:',
      'letter': 'The next map piece is hidden in a box.\n'
          'The box is not on the shelf.\n'
          'Look under the table,\n'
          'behind the green watering can.',
      'question': 'Where is the box with the next map piece?',
      'options': {
        'a': {'feedback': 'Read the second line again: the box is NOT on the shelf.'},
        'b': {'feedback': "Under the table is right! But 'behind' does not mean 'in front of'."},
        'd': {'feedback': 'Is the box ON the table, or UNDER it? Read the third line.'},
      },
      'hints': [
        'Read all four lines. One of them tells you where the box is NOT.',
        '"Behind" means at the back of something. It is the opposite of "in front of".',
      ],
      'clue': {'note': 'The box was under the table, behind the green watering can.'},
      'evidence': {'description': 'Found in a box in the boathouse.'},
      'successMessage': 'It was behind the watering can!',
      'transition': [
        'Now you have three pieces of the map.',
        'On the back of one of them, there are instructions.',
        '"Put me together, and I will show you the way."',
      ],
    },
    'ep07_m3': {
      'story': [
        'In the rose garden, you put the three pieces down on a bench.',
        'There is a river piece, a park piece and a station piece.',
      ],
      'letterIntro': 'On the back, the instructions say:',
      // Puzzle data: the same at every level.
      'letter': 'Put me together, from the top to the bottom.\n'
          'The river piece is not at the top.\n'
          'The station piece and the river piece do not touch.',
      'question': 'Put the map pieces in order, from the top to the bottom.',
      'feedback': {
        'river,park,station': 'Can the river piece go at the top? Read the second line.',
        'river,station,park': 'The river piece is at the top again. Does the note allow that?',
        'station,river,park': 'Now the station piece and the river piece touch. Are they allowed to?',
        'park,station,river': 'The station piece is right on top of the river piece. Can they touch?',
        'park,river,station': 'The river piece is right on top of the station piece. Can they touch?',
      },
      'orderFeedback': 'Read both lines again: the river piece cannot be at the top, and the station and river pieces must not touch.',
      'hints': [
        'Look first at the two pieces that must not touch. Where could they go?',
        'If two of three pieces cannot touch, one is at the top and one is at the bottom. Which of them may NOT be at the top?',
      ],
      'clue': {'note': 'Station at the top, park in the middle and river at the bottom.'},
      'evidence': {'description': 'Three pieces that make one picture.'},
      'successMessage': 'The pieces fit together!',
      'transition': [
        'With the joined map in your hand, you hurry north along the park paths.',
        '"The last piece waits where my arrow points."',
        'But a man in a dark coat is walking that way fast!',
      ],
    },
    'ep07_final': {
      'story': [
        'Quick, there is no time to lose!',
        'Inspector Grey shouts the way to you.',
      ],
      'letterIntro': 'Inspector Grey calls out:',
      // Puzzle data: the same at every level.
      'letter': 'Go past the tree.\n'
          'Cross the bridge and turn left!\n'
          'Then follow your joined map!',
      'question': 'Which map shows the place where you should stop?',
      'options': {
        'a': {'feedback': 'Yes, it is left after the bridge. But where does the arrow on your joined map point?'},
        'c': {'feedback': 'Inspector Grey says to turn LEFT after the bridge, not right.'},
        'd': {'feedback': 'Inspector Grey says to go PAST the tree, not to stop there.'},
      },
      'hints': [
        "Put two clues together: Inspector Grey's directions and the arrow on your joined map.",
        "After Grey's way, two places are left. Which one is at the top of the park, where the arrow points? Check the Joined Map in your Notebook.",
      ],
      'evidence': {'description': 'Every piece is back together again.'},
      'successMessage': 'You found the lost map at last!',
      'transition': [
        'Now the map is complete.',
        'Nine small ravens\nare drawn around one place.',
        'PLATFORM 9.',
        'You have read those words before.',
        "King's Cross is waiting for you.",
      ],
    },
  },
};

// ── Master ───────────────────────────────────────────────────────────────
const Map<String, Object?> ep07Master = {
  'synopsis': [
    'An old map of London has vanished from Hyde Park.',
    'Nothing remains but a few scattered pieces and a trail of directions.',
    'Follow them, and piece the map together once more.',
  ],
  'intro': [
    'Hyde Park, 7:00 AM, under a pale morning sky...',
    'Inspector Grey, it seems, was right.',
    "The old London map kept in the park keeper's lodge has vanished.",
    'One piece is yours, from the Tower. The Raven Society holds the rest.',
    'What could the Raven Society want with an old map?',
  ],
  'caseSummary': 'You followed every direction, joined the scattered pieces and recovered the lost map of London.',
  'hook': 'Nine black ravens circle a single spot on the map: Platform 9.',
  'glossary': {
    'vanished': '사라졌다',
    'remains': '남아 있다',
    'scattered': '흩어진',
    'trail': '(이어진) 자취',
    'piece': '조각 (piece together: 맞춰 붙이다)',
    'pale': '옅은, 창백한',
    'holds': '가지고 있다',
    'fled': '달아났다',
    'reads': '(~라고) 적혀 있다',
    'marks': '표시하다',
    'beneath': '~ 아래에',
    'beyond': '~ 너머에',
    'trace': '(손가락으로) 따라가다',
    'obeying': '따르는',
    'frowns': '얼굴을 찌푸리다',
    'uneasy': '불안한',
    'poking': '뒤지는 (poke about: 여기저기 뒤지다)',
    'coils': '(둘둘 감은) 타래',
    'crowd': '가득 메우다',
    'dim': '어둑한',
    'rests': '놓여 있다',
    'waste': '낭비하다',
    'tucked': '(안쪽에) 넣어 둔',
    'rules': '(rule out: 제외하다)',
    'opposites': '반대말들',
    'spread': '펼쳐 놓다',
    'reverse': '뒷면',
    'forbids': '금지하다',
    'permitted': '허락된',
    'directly': '바로',
    'column': '세로줄',
    'pair': '한 쌍',
    'centre': '가운데',
    'recovered': '되찾았다',
    'hasten': '서두르다',
    'winding': '구불구불한',
    'striding': '성큼성큼 걷는',
    'wasted': '낭비된',
    'settle': '결정하다',
    'remain': '남다',
    'restored': '원래대로 돌아온',
    'whole': '온전한',
    'encircle': '둘러싸다',
    'awaits': '기다리다',
  },
  'missions': {
    'ep07_m1': {
      'story': [
        'At the park gate, the keeper hurries to meet you.',
        'Last night, he says, a thief fled this way, dropping a note and a piece of the map.',
      ],
      'letterIntro': 'The note reads:',
      // Puzzle data: the same at every level.
      'letter': 'Go past the tree.\n'
          'Turn right at the bridge.\n'
          'Look beside the bench.',
      'question': 'Which map marks the right spot?',
      'options': {
        'a': {'feedback': 'To go PAST the tree is to keep walking, not to stop beneath it.'},
        'b': {'feedback': 'Which way does the note send you at the bridge?'},
        'd': {'feedback': 'That spot lies well beyond the bridge, yet the note ends beside a bench.'},
      },
      'hints': [
        'Trace the path from the bottom of the map, obeying each line of the note in turn.',
        'To go past something is to carry on past it. Which way does the bridge send you, and what waits at the end?',
      ],
      'clue': {'note': 'Right at the bridge, and there, beside the bench.'},
      'evidence': {'description': 'Discovered in the grass beside the bench.'},
      'successMessage': 'Step by step, the directions led you to the map piece beside the bench!',
      'transition': [
        'In the long grass beside the bench, a piece of the map lies waiting.',
        'The park keeper frowns, uneasy.',
        '"Someone has been poking about in my boathouse as well!"',
      ],
    },
    'ep07_m2': {
      'story': [
        'Oars, coils of rope and old boxes crowd the dim boathouse.',
        'Among them stand a table, a shelf and a green watering can.',
      ],
      'letterIntro': 'Words have been scratched into the boathouse door:',
      'letter': 'My next piece rests inside a box.\n'
          'Do not waste your time on the shelf: the box is not there.\n'
          'It waits beneath the table,\n'
          'tucked behind the green watering can.',
      'question': 'Where has the box with the map piece been hidden?',
      'options': {
        'a': {'feedback': 'The message rules out the shelf. Read its second line again.'},
        'b': {'feedback': "Beneath the table, yes, but the message says 'behind' the can, not in front of it."},
        'd': {'feedback': 'Does the message put the box on the table, or beneath it?'},
      },
      'hints': [
        'Every line of the scratched message matters, and one of them tells you where the box is not.',
        'Behind and in front of are opposites. Which one does the message choose?',
      ],
      'clue': {'note': 'Hidden beneath the table, behind the green watering can.'},
      'evidence': {'description': 'Recovered from a box hidden in the boathouse.'},
      'successMessage': 'Behind the watering can, just as the message said!',
      'transition': [
        'Three pieces of the map are now in your hands.',
        'On the back of one, someone has written instructions.',
        '"Put me together, and I will show you the way."',
      ],
    },
    'ep07_m3': {
      'story': [
        'In the quiet of the rose garden, you spread the three pieces across a bench.',
        'A river piece, a park piece and a station piece lie side by side.',
      ],
      'letterIntro': 'The instructions on the reverse read:',
      // Puzzle data: the same at every level.
      'letter': 'Put me together, from the top to the bottom.\n'
          'The river piece is not at the top.\n'
          'The station piece and the river piece do not touch.',
      'question': 'In what order do the pieces go, from the top to the bottom?',
      'feedback': {
        'river,park,station': 'The river piece at the top? The note forbids exactly that.',
        'river,station,park': 'Once more the river piece sits at the top. Is that permitted?',
        'station,river,park': 'Here the station and river pieces touch, and the note says they must not.',
        'park,station,river': 'The station piece rests directly on the river piece. May they touch?',
        'park,river,station': 'The river piece rests directly on the station piece. May they touch?',
      },
      'orderFeedback': 'Weigh both lines together: the river piece is never at the top, and the station and river pieces never touch.',
      'hints': [
        'Begin with the pair that may never touch. Where in a column of three can they possibly sit?',
        'Two pieces kept apart must take the two ends. Which line forbids one of them the top?',
      ],
      'clue': {'note': 'Station at the top, park at the centre, river at the bottom.'},
      'evidence': {'description': 'Three pieces, joined at last into a single picture.'},
      'successMessage': 'The pieces fit perfectly!',
      'transition': [
        'Joined map in hand, you hasten north along the winding park paths.',
        '"The last piece waits where my arrow points."',
        'Yet a man in a dark coat is striding there, fast!',
      ],
    },
    'ep07_final': {
      'story': [
        'Not a moment can be wasted!',
        'Across the paths, Inspector Grey calls out the way.',
      ],
      'letterIntro': "Inspector Grey's voice rings across the park:",
      // Puzzle data: the same at every level.
      'letter': 'Go past the tree.\n'
          'Cross the bridge and turn left!\n'
          'Then follow your joined map!',
      'question': 'Which map marks the place to stop?',
      'options': {
        'a': {'feedback': "Left after the bridge, true. But is this where your joined map's arrow ends?"},
        'c': {'feedback': 'Grey called for a LEFT turn after the bridge.'},
        'd': {'feedback': 'Grey told you to go PAST the tree, not to stop beneath it.'},
      },
      'hints': [
        "Grey's directions alone will not settle it. What else do you carry that shows a direction?",
        'Turn left after the bridge and two places remain. Read the Joined Map in your Notebook again: which of them lies where its arrow points?',
      ],
      'evidence': {'description': 'Every piece restored, the map whole once more.'},
      'successMessage': 'The lost map of London is found!',
      'transition': [
        'At last, the map is whole.',
        'Nine small ravens\nencircle a single place.',
        'PLATFORM 9.',
        'Those words are not new to you.',
        "King's Cross awaits.",
      ],
    },
  },
};

// ── Discovery Moments ────────────────────────────────────────────────────
const Map<String, Discovery> ep07JuniorDiscoveries = {
  'ep07_m1': Discovery(
    type: DiscoveryType.evidenceFound,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'RIVER MAP PIECE',
    detail: 'Turn right at the bridge and look beside the bench: there lies the first piece of the map.',
    showEvidence: true,
  ),
  'ep07_m2': Discovery(
    type: DiscoveryType.evidenceFound,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'STATION MAP PIECE',
    detail: 'It was under the table, behind the green watering can.',
    showEvidence: true,
  ),
  'ep07_m3': Discovery(
    type: DiscoveryType.clueFound,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'THE JOINED MAP',
    detail: 'The three pieces fit together, and an arrow points north, to the top of the park.',
  ),
};

const Map<String, Discovery> ep07MasterDiscoveries = {
  'ep07_m1': Discovery(
    type: DiscoveryType.evidenceFound,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'RIVER MAP PIECE',
    detail: 'Right at the bridge, then beside the bench: there the first piece of the stolen map lay hidden.',
    showEvidence: true,
  ),
  'ep07_m2': Discovery(
    type: DiscoveryType.evidenceFound,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'STATION MAP PIECE',
    detail: 'Beneath the table, tucked behind the green watering can, the next piece was waiting.',
    showEvidence: true,
  ),
  'ep07_m3': Discovery(
    type: DiscoveryType.clueFound,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'THE JOINED MAP',
    detail: 'Three pieces, one map — and on it, an arrow pointing north, to the very top of the park.',
  ),
};

// ── The parent report's English ──────────────────────────────────────────
const Map<String, LearningObjective> ep07JuniorLearning = {
  'ep07_m1': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.application,
    skill: LanguageSkill.grammarInContext,
    objective: '길 안내(past, turn right, beside)를 따라 지도에서 위치를 찾는다.',
    expressions: ['Go past the tree', 'walk on by it', 'Turn right at the bridge', 'Look beside the bench'],
  ),
  'ep07_m2': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.grammarInContext,
    objective: '부정문(not on)과 위치 전치사(under, behind)를 함께 읽고 상자의 위치를 고른다.',
    expressions: ['The box is not on the shelf', 'Look under the table', 'behind the green watering can'],
  ),
  'ep07_m3': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.application,
    skill: LanguageSkill.grammarInContext,
    objective: '"not at the top"과 "do not touch" 두 조건을 함께 써서 지도 조각을 위에서 아래로 배열한다.',
    expressions: ['from the top to the bottom', 'The river piece is not at the top', 'do not touch'],
  ),
  'ep07_final': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.recall,
    skill: LanguageSkill.sentenceMeaning,
    objective: '새 길 안내와 앞에서 맞춘 지도의 화살표 글귀를 함께 읽어 멈출 곳을 정한다.',
    expressions: ['Cross the bridge and turn left', 'follow your joined map', 'An arrow points north'],
    recallFrom: 'ep07_m3',
  ),
};

const Map<String, LearningObjective> ep07MasterLearning = {
  'ep07_m1': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.application,
    skill: LanguageSkill.grammarInContext,
    objective: '길 안내(past, turn right, beside)를 따라 지도에서 위치를 찾는다.',
    expressions: ['Go past the tree', 'carry on past it', 'Turn right at the bridge', 'Look beside the bench'],
  ),
  'ep07_m2': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.grammarInContext,
    objective: '부정문(the box is not there)과 위치 표현(beneath, behind)을 함께 읽고 상자의 위치를 고른다.',
    expressions: ['the box is not there', 'It waits beneath the table', 'tucked behind the green watering can'],
  ),
  'ep07_m3': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.application,
    skill: LanguageSkill.grammarInContext,
    objective: '"not at the top"과 "do not touch" 두 조건을 함께 써서 지도 조각을 위에서 아래로 배열한다.',
    expressions: [
      'The river piece is not at the top',
      'The station piece and the river piece do not touch',
      'may never touch',
    ],
  ),
  'ep07_final': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.recall,
    skill: LanguageSkill.sentenceMeaning,
    objective: '새 길 안내와 앞에서 맞춘 지도의 화살표 글귀를 함께 읽어 멈출 곳을 정한다.',
    expressions: ['Cross the bridge and turn left', 'An arrow points north', 'to the top of the park'],
    recallFrom: 'ep07_m3',
  ),
};
