import '../../../models/clock_puzzle.dart';
import '../../../models/discovery.dart';
import '../../../models/investigation.dart';
import '../../../models/learning.dart';
import '../../../models/mission.dart';
import '../season1_investigations.dart';
import 'level_words.dart';

// Case 02 — The Silent Clock, at each level (PART 6A; Mission 01 from the
// PART 5 sample, kept and finished).
//
// The facts never move: the hour hand between eight and nine, the minute
// hand on the three and two more small marks (8:17, typed 817; the wrong
// answers 815, 832 and 917 keep their lines' keys), the gear "not under the
// biggest bell" but under its opposite, the plan's "The hour is the
// gallery. The minutes are the picture." and "One hour after the clock
// stops" (word for word at every level: Case 12 reads "after" again).
// 9:17 is written nowhere before the final's lock, at any level.
//
// Rookie: the base, with one line of the final's letter made plainer.

const Map<String, Object?> ep02Rookie = {
  'missions': {
    'ep02_final': {
      'letter': 'Clever detective!\n\n'
          'Set the hands to the time the thief will take the picture.\n'
          'Then I will ring the great bell.\n'
          'The museum guards will hear it and be ready.\n\n'
          'Your notebook tells you when the clock stopped.\n'
          "The Time Card has the thief's plan.",
    },
  },
};

// ── Junior ───────────────────────────────────────────────────────────────
const Map<String, Object?> ep02Junior = {
  'synopsis': [
    'Big Ben has stopped, and its hands will not move.',
    'A great clock does not stop by itself.',
    'Why did it stop at that exact minute? The answer is hidden inside the tower.',
  ],
  'intro': [
    'London, early in the morning...',
    'The Crown is safe again. But this morning, the city is much too quiet.',
    'Big Ben has stopped.',
    'Its hands are frozen, and nobody heard the bell ring.',
    'A clock does not stop by itself. Someone stopped it on purpose.',
  ],
  'caseSummary': 'You read the frozen clock, found the missing gear and got Big Ben going again.',
  'hook': 'Someone stamped a small raven on the gear. Who are the ravens?',
  'glossary': {
    'exact': '정확한',
    'purpose': '목적 (on purpose: 일부러)',
    'passed': '지났다',
    'reached': '도착했다, 닿았다',
    'crept': '살금살금 움직였다',
    'forward': '앞으로',
    'pinned': '(핀으로) 꽂힌',
    'worry': '걱정하다',
    'galleries': '전시실들',
    'planning': '계획하는',
    'perfectly': '완벽하게',
    'leans': '몸을 기울이다',
  },
  'missions': {
    'ep02_m1': {
      'story': [
        'From Westminster Bridge, you look up at Big Ben.',
        'The great clock has gone silent. Its hands are not moving at all.',
      ],
      'letterIntro': 'Mrs Bell, the clockkeeper, hands you her notebook.',
      'letter': 'Detective {detectiveName},\n\n'
          'I was watching the clock when it stopped.\n'
          'The short hour hand had passed eight, but it had not reached nine.\n'
          'The long minute hand pointed at the three...\n'
          'then it crept forward two more small marks.\n\n'
          '— Mrs Bell, Clockkeeper',
      'question': 'At what time did Big Ben stop? Type the hour, then the minutes.',
      'hints': [
        "Go through Mrs Bell's note one line at a time. Find the hour hand first, then the minute hand.",
        'Between eight and nine, the hour is still eight. On a clock, the three means fifteen minutes. Now add the small marks.',
      ],
      'feedback': {
        '815': 'Read the last line again: the minute hand crept forward two more small marks.',
        '832': 'On a clock, the three means fifteen minutes, not three minutes.',
        '917': 'The hour hand had not reached nine yet, so the hour is still eight.',
      },
      'clue': {'note': 'Big Ben stopped at 8:17. That was no accident.'},
      'evidence': {'description': "A page from Mrs Bell's notebook."},
      'successMessage': 'Big Ben stopped at 8:17 exactly.',
      'transition': [
        'Mrs Bell unlocks a small door at the foot of the tower.',
        'Three hundred steps climb up into the dark.',
        'The answer is waiting inside the clock.',
      ],
    },
    'ep02_m2': {
      'story': [
        'Behind the four clock faces, the room is full of big wheels and gears.',
        'One small gear is missing. Without it, the clock cannot turn!',
      ],
      'letterIntro': 'Someone has pinned a note to the empty place.',
      'letter': 'Dear Detective {detectiveName},\n\n'
          'A clock cannot turn without all of its gears.\n'
          'So I took one small brass gear.\n\n'
          'Do not worry. I did not take it far.\n'
          'It is not under the biggest bell.\n'
          'It is under the bell that is the opposite of the biggest.\n\n'
          '— R.',
      'question': 'Where did R. hide the missing gear?',
      'options': {
        'a': {'feedback': "Read that line again. Which small word comes before 'under the biggest bell'?"},
        'b': {'feedback': 'The note does not say anything about the clock face. Which line tells you where the gear IS?'},
        'd': {'feedback': 'The note does not talk about the stairs. Find the line that says where the gear IS.'},
      },
      'hints': [
        'Read the last two lines of the note. One of them says "not". What does the other one say?',
        'What is the opposite of big? Now think about the bells.',
      ],
      'clue': {'note': 'The thief signs the note with an R. There is a raven stamped on the gear.'},
      'evidence': {'description': 'The missing gear. Without it, Big Ben stopped.'},
      'successMessage': 'You found the missing gear at last!',
      'transition': [
        'You lift the brass gear up to the light.',
        'Then a small card falls out of the smallest bell.',
        'It is covered with numbers and times.',
      ],
    },
    'ep02_m3': {
      'story': [
        'At the top of the tower, five great bells hang in the cold wind.',
        'The card from the smallest bell is a time card.',
      ],
      'letterIntro': 'On the back of the card, the thief has written a plan.',
      'letter': 'MY PLAN\n\n'
          'First, I stop Big Ben.\n'
          'Then, before the museum opens, I hide in one of its galleries.\n'
          'One hour after the clock stops, I take a picture.\n\n'
          'Which gallery? Which picture?\n'
          'The answer is in my stopped clock.\n'
          'The hour is the gallery. The minutes are the picture.\n\n'
          '— R.',
      'question': 'Which picture is the thief going to take, and from which gallery?',
      'options': {
        'a': {'feedback': 'The hour hand was past eight but not yet at nine. So which hour is it?'},
        'c': {'feedback': 'Read the plan again: the hour is the GALLERY, and the minutes are the PICTURE.'},
        'd': {'feedback': "Those numbers come from Mrs Bell's note. The plan says to use the TIME the clock stopped."},
      },
      'hints': [
        'The plan hides two numbers in the stopped clock. What time did the clock stop?',
        'Find the stopped time in your notebook. Use the hour for the GALLERY and the minutes for the PICTURE.',
      ],
      'clue': {'note': 'The stopped clock was a message: the hour is the gallery and the minutes are the picture.'},
      'evidence': {'description': "The thief's plan, written on the back of the card."},
      'successMessage': 'It is Gallery 8, Picture 17!',
      'transition': [
        'The stopped time was a message!',
        'Mrs Bell looks up at the frozen hands.',
        'Quick, start the clock again!',
      ],
    },
    'ep02_final': {
      'story': [
        'You put the brass gear back in its place. It fits perfectly.',
        'The great wheels are ready to turn again.',
      ],
      'letterIntro': 'Mrs Bell leans close and whispers.',
      'letter': 'Clever detective!\n\n'
          'Set the hands to the time when the thief will take the picture.\n'
          'Then I will ring the great bell.\n'
          'The museum guards will hear it, and they will be ready.\n\n'
          'Your notebook shows when the clock stopped,\n'
          "and the Time Card shows the thief's plan.",
      // How to play it: the same at every level.
      'question': 'Set the time on the Great Clock.',
      'feedback': {
        '817': 'That is when the clock stopped. The plan says the thief takes the picture ONE HOUR AFTER that.',
        '717': 'The plan says AFTER, not before. Should the hour go up or down?',
        '818': 'In one hour, the hour hand moves on. Do the minutes change too?',
      },
      'hints': [
        "Use two clues together: the time the clock stopped, and the thief's plan on the Time Card.",
        "The plan says 'one hour after the clock stops'. Add one to the hour. What happens to the minutes?",
      ],
      'evidence': {'description': 'You found it inside the clock.'},
      'successMessage': 'Big Ben is ringing again!',
      'transition': [
        'Big Ben is ringing again.',
        'In your hand, there is a black feather.',
        'A raven feather.',
        'The same raven was stamped on the gear.',
        'And the stopped time was not just a time.',
        'It was a message.',
        'At the museum,\nthe guards hear the bell.',
      ],
    },
  },
};

// ── Master ───────────────────────────────────────────────────────────────
const Map<String, Object?> ep02Master = {
  'synopsis': [
    'Big Ben has fallen silent, its hands frozen in place.',
    'A clock like this does not simply stop on its own.',
    'Why did it stop at that very minute? The answer lies hidden within the tower.',
  ],
  'intro': [
    'London, in the grey light of early morning...',
    'The Crown is safe once more. Yet this morning, an odd silence hangs over the city.',
    'Big Ben has stopped.',
    'Its hands are frozen, and not a single chime was heard.',
    'A clock like this does not stop by itself. Someone made it stop.',
  ],
  'caseSummary': 'You read the frozen clock, recovered the missing gear and set Big Ben ringing once more.',
  'hook': 'A tiny raven was stamped on the gear. Who, or what, are the ravens?',
  'glossary': {
    'fallen': '(상태가) 되었다',
    'simply': '그냥, 단순히',
    'within': '~ 안에',
    'odd': '이상한',
    'chime': '(종이) 울리는 소리',
    'gaze': '바라보다',
    'glance': '흘끗 보다',
    'rested': '머물러 있었다',
    'short': '(~에) 못 미치는',
    'lay': '놓여 있었다',
    'froze': '얼어붙었다, 멈췄다',
    'ticked': '똑딱 움직였다',
    'presses': '(손에) 쥐여 주다',
    'unlocks': '(자물쇠를) 열다',
    'narrow': '좁은',
    'spiral': '나선형으로 돌다',
    'maze': '미로',
    'helpless': '아무것도 못 하는',
    'borrowed': '빌렸다',
    'carried': '옮겼다',
    'beneath': '~ 아래에',
    'instead': '대신에',
    'silenced': '조용하게 만들었다',
    'silence': '조용하게 하다',
    'loss': '잃음, 없어짐',
    'sway': '흔들리다',
    'gently': '부드럽게',
    'slip': '몰래 들어가다',
    'target': '목표물',
    'painting': '그림',
    'mean': '~할 작정이다',
    'raise': '들어 올리다',
    'flutters': '팔랑이며 떨어지다',
    'whisper': '속삭임',
    'shall': '~할 것이다',
    'remembers': '기억하다',
    'reveals': '드러내다',
    'evidence': '증거',
    'travel': '움직이다, 이동하다',
    'palm': '손바닥',
    'recovered': '되찾았다',
  },
  'missions': {
    'ep02_m1': {
      'story': [
        'From the middle of Westminster Bridge, you gaze up at Big Ben.',
        'The great clock stands silent, its hands frozen in place.',
      ],
      'letterIntro': 'Mrs Bell, the old clockkeeper, presses her notebook into your hands.',
      'letter': 'Detective {detectiveName},\n\n'
          'I happened to glance up at the very moment the clock fell silent.\n'
          'The hour hand rested somewhere past eight, still short of nine.\n'
          'The minute hand lay upon the three...\n'
          'yet before it froze, it ticked on by two more of the small marks.\n\n'
          '— Mrs Bell, Clockkeeper',
      'question': 'When exactly did Big Ben stop? Type the hour, then the minutes.',
      'hints': [
        'Mrs Bell describes each hand on its own line. Which line gives you the hour, and which the minutes?',
        "An hour hand still short of nine belongs to the eight o'clock hour. Work out what the three means for the minute hand, then count on.",
      ],
      'feedback': {
        '815': 'The note does not end at the three. What happened just before the clock froze?',
        '832': 'The numbers on a clock face are not minutes. What does the three stand for?',
        '917': 'Was the hour hand past nine, or still short of it?',
      },
      'clue': {'note': 'Big Ben stopped at 8:17, and not by accident.'},
      'evidence': {'description': 'The page Mrs Bell wrote as the clock stopped.'},
      'successMessage': 'Big Ben fell silent at precisely 8:17.',
      'transition': [
        'Mrs Bell unlocks a narrow door at the foot of the tower.',
        'Three hundred steps spiral up into darkness.',
        'The answer lies somewhere inside the great clock.',
      ],
    },
    'ep02_m2': {
      'story': [
        'Behind the four great clock faces, a maze of wheels and gears fills the room.',
        'One small gear is missing, and without it, the whole clock stands still.',
      ],
      'letterIntro': 'Pinned where the gear should be is a note.',
      'letter': 'Dear Detective {detectiveName},\n\n'
          'A clock is helpless without every one of its gears,\n'
          'so I borrowed a small brass gear.\n\n'
          'I have not carried it far.\n'
          'You will not find it beneath the biggest bell.\n'
          'Look instead beneath the bell that is its very opposite.\n\n'
          '— R.',
      'question': 'Where has R. hidden the missing gear?',
      'options': {
        'a': {'feedback': 'Read that line again: will you find it beneath the biggest bell?'},
        'b': {'feedback': 'The clock face is never mentioned. Which line tells you where to look?'},
        'd': {'feedback': 'Nothing in the note points to the stairs. Which line tells you where to look?'},
      },
      'hints': [
        'Two lines of the note concern the bells. One tells you where the gear is not. What does the other tell you?',
        'If the gear lies beneath the opposite of the biggest bell, which bell must that be?',
      ],
      'clue': {'note': 'The thief signs only with an R, and a raven is stamped on the gear.'},
      'evidence': {'description': 'The missing gear whose loss silenced Big Ben.'},
      'successMessage': 'The missing gear is back in your hands!',
      'transition': [
        'You raise the brass gear to the light.',
        'As you do, a small card flutters out of the smallest bell.',
        'It is covered in numbers and times.',
      ],
    },
    'ep02_m3': {
      'story': [
        'High at the top of the tower, five great bells sway gently in the wind.',
        'The card that fell from the smallest bell turns out to be a time card.',
      ],
      'letterIntro': 'On its back, the thief has written out a plan.',
      'letter': 'MY PLAN\n\n'
          'First, I silence Big Ben.\n'
          'Before the museum opens its doors, I slip into a gallery and wait.\n'
          'One hour after the clock stops, I take a picture.\n\n'
          'Which gallery? Which picture?\n'
          'My stopped clock holds both numbers.\n'
          'The hour is the gallery. The minutes are the picture.\n\n'
          '— R.',
      'question': 'Which painting does the thief mean to take, and from which gallery?',
      'options': {
        'a': {'feedback': 'The hour hand never reached nine. Which hour was the clock really in?'},
        'c': {'feedback': 'You have them the wrong way round. Which number does the plan give to the GALLERY?'},
        'd': {'feedback': 'Those are only the marks Mrs Bell described. The plan asks for the stopped TIME itself.'},
      },
      'hints': [
        'The plan never writes its numbers down. Where else have you already seen them today?',
        'Read the time you found on the frozen clock the way the plan tells you to.',
      ],
      'clue': {'note': 'The stopped clock hid a message: its hour named the gallery, its minutes the picture.'},
      'evidence': {'description': "The thief's plan, written on the back of a time card."},
      'successMessage': 'Gallery 8, Picture 17: the target is clear!',
      'transition': [
        'The stopped time was never just a time. It was a message.',
        'Mrs Bell gazes up at the frozen hands.',
        'Quick — the clock must run again!',
      ],
    },
    'ep02_final': {
      'story': [
        'You slide the brass gear back into its place. It fits perfectly.',
        'The great wheels wait, ready to turn once more.',
      ],
      'letterIntro': 'Mrs Bell lowers her voice to a whisper.',
      'letter': 'Clever detective!\n\n'
          'Set the hands to the moment the thief plans to take the picture.\n'
          'Once they are set, I shall ring the great bell,\n'
          'and the museum guards will hear it and be waiting.\n\n'
          'Your notebook remembers when the clock stopped;\n'
          "the Time Card reveals the rest of the thief's plan.",
      // How to play it: the same at every level.
      'question': 'Set the time on the Great Clock.',
      'feedback': {
        '817': 'That is the moment the clock stopped. When does the plan say the picture will be taken?',
        '717': 'That is an hour before, not after. Which way should the hour move?',
        '818': 'After exactly one hour, would the minute hand be anywhere different?',
      },
      'hints': [
        "Two pieces of evidence meet here: the moment the clock stopped, and the timing in the thief's plan.",
        'How far does each hand travel in exactly one hour?',
      ],
      'evidence': {'description': 'Discovered deep inside the clock.'},
      'successMessage': 'Big Ben rings out across London once more!',
      'transition': [
        "Big Ben's great bell rings out again.",
        'In your palm lies a single black feather.',
        "A raven's.",
        'The very same raven was stamped on the gear.',
        'And the stopped time was never only a time.',
        'It was a message.',
        'Across the city, at the museum,\nthe guards hear the bell.',
      ],
    },
  },
};

// ── Mission 01's clock (the face, its hands' start and the answer never) ─
const Map<String, ClockPuzzle> ep02JuniorClocks = {
  'ep02_m1': ClockPuzzle(
    face: Artwork.clockFace,
    question: 'At what time did Big Ben stop? Set the hands.',
    lead: 'Mrs Bell passes you her clock face. Move the hands to where she saw them stop.',
    guide: 'Drag the short hand for the hour and the long hand for the minutes.',
    dialLabel: "Mrs Bell's clock face",
  ),
};

// ── The final's Great Clock (the face, its start at 8:17 and the answer never)
const Map<String, ClockPuzzle> ep02JuniorFinalClocks = {
  'ep02_final': ClockPuzzle(
    face: Artwork.clockFace,
    question: 'Set the time on the Great Clock.',
    lead: 'The hands are still frozen at the moment the clock stopped. Move them to the time of the thief\'s plan.',
    guide: 'Drag the short hand for the hour and the long hand for the minutes.',
    dialLabel: "Big Ben's Great Clock",
    start: (hour: 8, minute: 17),
    submitLabel: 'START THE CLOCK',
  ),
};

const Map<String, ClockPuzzle> ep02MasterClocks = {
  'ep02_m1': ClockPuzzle(
    face: Artwork.clockFace,
    question: 'When exactly did Big Ben stop? Set the hands to show it.',
    lead: 'Mrs Bell entrusts you with her clock face. Place the hands just as she remembers them.',
    guide: 'Drag the short hand for the hour and the long hand for the minutes.',
    dialLabel: "Mrs Bell's clock face",
  ),
};

const Map<String, ClockPuzzle> ep02MasterFinalClocks = {
  'ep02_final': ClockPuzzle(
    face: Artwork.clockFace,
    question: 'Set the time on the Great Clock.',
    lead: 'The great hands remain frozen at the very moment the clock fell silent. Bring them to the hour the thief has planned.',
    guide: 'Drag the short hand for the hour and the long hand for the minutes.',
    dialLabel: "Big Ben's Great Clock",
    start: (hour: 8, minute: 17),
    submitLabel: 'START THE CLOCK',
  ),
};

// ── Mission 02's belfry (its picture, bells, places and answer the base's) ─
// The find's line is the level letter's own line, word for word.
final InvestigationScene _belfry = season1Investigations['ep02_m2']!;

final Map<String, InvestigationScene> ep02JuniorInvestigations = {
  'ep02_m2': _belfry.copyWith(
    task: 'Read the note and find the gear.',
    missLine: 'Nothing here. The note says the gear is under one of the bells.',
    doneLine: 'You found the missing gear at last!',
    arrival: const [
      'A ladder climbs from the clock room up to the belfry, where five bells hang.',
      'Someone has pinned a note to the empty place where the gear should be.',
    ],
    finds: [
      _belfry.finds.single.copyWith(
        reportLine: 'It is under the bell that is the opposite of the biggest.',
        foundLine: 'There it is, under the smallest bell: the brass gear!',
      ),
    ],
    spots: relined(_belfry.spots, const [
      'This is the biggest bell. The note says the gear is NOT under it.',
      'There is nothing under this bell. Which bell is the opposite of the biggest?',
      'The back of the clock face. The note says the gear is under a bell.',
      'The stairs lead down. The note does not say anything about the stairs.',
      'An old rope hangs on a beam. There is nothing here.',
    ]),
  ),
};

final Map<String, InvestigationScene> ep02MasterInvestigations = {
  'ep02_m2': _belfry.copyWith(
    task: 'Track down the gear the note hides.',
    missLine: 'Nothing here. According to the note, the gear lies beneath a bell.',
    doneLine: 'The missing gear is back in your hands!',
    arrival: const [
      'A narrow ladder leads from the clock room up into the belfry, home to five bells.',
      'Pinned where the gear ought to be is a note.',
    ],
    finds: [
      _belfry.finds.single.copyWith(
        reportLine: 'Look instead beneath the bell that is its very opposite.',
        foundLine: 'Beneath the smallest bell lies the brass gear!',
      ),
    ],
    spots: relined(_belfry.spots, const [
      'The biggest bell of all. The note says you will NOT find the gear beneath it.',
      'Nothing beneath this one. Which bell is the very opposite of the biggest?',
      'The back of a clock face. The note sends you beneath a bell instead.',
      'The stairs spiral down. The note never mentions them.',
      'A coil of old rope on a beam, and nothing more.',
    ]),
  ),
};

// ── Discovery Moments ────────────────────────────────────────────────────
const Map<String, Discovery> ep02JuniorDiscoveries = {
  'ep02_m1': Discovery(
    type: DiscoveryType.deduction,
    timing: DiscoveryTiming.fromPuzzle,
    title: '8:17',
    detail: 'The hour hand past eight, the minute hand at seventeen: the moment Big Ben stopped.',
  ),
  'ep02_m2': Discovery(
    type: DiscoveryType.evidenceFound,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'SMALL BRASS GEAR',
    detail: 'It was under the smallest bell: the gear that stopped Big Ben.',
    showEvidence: true,
    seasonClue: true,
  ),
  'ep02_m3': Discovery(
    type: DiscoveryType.deduction,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'GALLERY 8 · PICTURE 17',
    detail: 'The stopped clock was a message. Its hour is the gallery, and its minutes are the picture.',
  ),
};

const Map<String, Discovery> ep02MasterDiscoveries = {
  'ep02_m1': Discovery(
    type: DiscoveryType.deduction,
    timing: DiscoveryTiming.fromPuzzle,
    title: '8:17',
    detail: 'An hour hand short of nine, a minute hand at seventeen: the very moment Big Ben fell silent.',
  ),
  'ep02_m2': Discovery(
    type: DiscoveryType.evidenceFound,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'SMALL BRASS GEAR',
    detail: 'Beneath the smallest bell lay the gear that silenced Big Ben.',
    showEvidence: true,
    seasonClue: true,
  ),
  'ep02_m3': Discovery(
    type: DiscoveryType.deduction,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'GALLERY 8 · PICTURE 17',
    detail: 'The frozen clock was a message all along: its hour the gallery, its minutes the picture.',
  ),
};

// ── The parent report's English ──────────────────────────────────────────
const Map<String, LearningObjective> ep02JuniorLearning = {
  'ep02_m1': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.sentenceMeaning,
    objective: '시계 바늘을 설명한 영어 문장을 읽고 멈춘 시각(8:17)을 알아낸다.',
    expressions: ['had passed eight, but it had not reached nine', 'crept forward two more small marks'],
  ),
  'ep02_m2': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.grammarInContext,
    objective: '부정문(not)과 긍정문을 구분해 톱니바퀴가 있는 곳을 찾는다.',
    expressions: ['It is not under the biggest bell', 'the opposite of the biggest'],
  ),
  'ep02_m3': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.application,
    skill: LanguageSkill.sentenceMeaning,
    objective: '"시는 전시실, 분은 그림"이라는 규칙을 앞에서 찾은 시각에 적용한다.',
    expressions: ['The answer is in my stopped clock', 'The hour is the gallery. The minutes are the picture.'],
    recallFrom: 'ep02_m1',
  ),
  'ep02_final': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.recall,
    skill: LanguageSkill.grammarInContext,
    objective: '앞 미션 계획서의 "one hour after"를 다시 읽고 시각을 계산한다(8:17 → 9:17).',
    expressions: ['One hour after the clock stops'],
    recallFrom: 'ep02_m3',
  ),
};

const Map<String, LearningObjective> ep02MasterLearning = {
  'ep02_m1': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.sentenceMeaning,
    objective: '시계 바늘을 설명한 영어 문장을 읽고 멈춘 시각(8:17)을 알아낸다.',
    expressions: ['somewhere past eight, still short of nine', 'two more of the small marks'],
  ),
  'ep02_m2': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.grammarInContext,
    objective: '부정문(will not find)과 지시문(look instead)을 구분하고, "its very opposite"가 가리키는 종을 찾는다.',
    expressions: ['You will not find it beneath the biggest bell', 'its very opposite'],
  ),
  'ep02_m3': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.application,
    skill: LanguageSkill.sentenceMeaning,
    objective: '"시는 전시실, 분은 그림"이라는 규칙을 앞에서 찾은 시각에 적용한다.',
    expressions: ['My stopped clock holds both numbers', 'The hour is the gallery. The minutes are the picture.'],
    recallFrom: 'ep02_m1',
  ),
  'ep02_final': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.recall,
    skill: LanguageSkill.grammarInContext,
    objective: '앞 미션 계획서의 "one hour after"를 다시 읽고 시각을 계산한다(8:17 → 9:17).',
    expressions: ['One hour after the clock stops'],
    recallFrom: 'ep02_m3',
  ),
};
