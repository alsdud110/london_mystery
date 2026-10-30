import '../../../models/discovery.dart';
import '../../../models/learning.dart';
import '../../../models/scene_deduction.dart';
import '../season1_deductions.dart';
import 'level_words.dart';

// ── Mission 02's platforms (2026-10-30): the picture, its places and the
// porter's four lines (puzzle data, word for word) are the base's; only
// what the page says around them is each level's.
final DeductionScene _platforms = season1Deductions['ep04_m2']!;

final Map<String, DeductionScene> ep04JuniorDeductions = {
  'ep04_m2': _platforms.copyWith(
    task: 'Tap each platform. What does the porter say?',
    chooseTask: 'RED · SMALL · CLOCK. Which platform?',
    missLine: 'Nothing here. Look up above each platform.',
    notPlaceLine: 'Choose one of the four platforms.',
    others: relined(_platforms.others, const [
      "A porter's trolley. There is nothing on it.",
      'A wooden bench. Nobody is sitting here.',
    ]),
  ),
};

final Map<String, DeductionScene> ep04MasterDeductions = {
  'ep04_m2': _platforms.copyWith(
    task: 'Tap each platform and note what the porter says.',
    chooseTask: 'RED · SMALL · CLOCK: which platform fits all three?',
    missLine: 'Nothing of note. Look above each platform.',
    notPlaceLine: 'Choose one of the four platforms to search.',
    others: relined(_platforms.others, const [
      "An empty porter's trolley, and nothing more.",
      'A wooden bench, with no one waiting on it.',
    ]),
  ),
};

// Case 04 — The Secret Letter, at each level (PART 6B).
//
// The facts never move: the Black Wax Seal (a raven pressed into the wax,
// its inscription never patched) and the castle where "Black birds live
// there." (word for word at every level) give the RAVEN Society; no line
// before the final names the bird. "Meet me where trains never sleep." is
// read again by Case 11, and "Platform 4 has a small red clock." by Case 12:
// both stay word for word, as do the porter's four lines ("…a red door, but
// no clock.") and the card RED · SMALL · CLOCK · PLATFORM. The postmark
// keeps only its picture: "the rain washed the words away" / "Only a small
// picture is left." at every level, and no later line prints the place in
// capitals.
//
// Kept the same at every level on purpose (the keys are still written in
// both patches):
// * ep04_m1.letter — the letter and its station guide are the puzzle data
//   ("Meet me where trains never sleep." is quoted by Case 11).
// * ep04_m2.letter — the porter's four lines and the card are the puzzle
//   data ("Platform 4 has a small red clock." is quoted by Case 12).
// * ep04_final.prompt — how the answer is typed: THE _____ SOCIETY.
// (ep04_m2.story's first line, the card, is also kept; its second line
// differs, so the field differs.)
//
// Rookie: the base, word for word.

const Map<String, Object?> ep04Rookie = {};

// ── Junior ───────────────────────────────────────────────────────────────
const Map<String, Object?> ep04Junior = {
  'synopsis': [
    'An old suitcase is waiting in the Lost Property office.',
    'Inside it is a letter with a black wax seal.',
    'Read it carefully. It was written for you.',
  ],
  'intro': [
    "King's Cross, 11 o'clock in the morning...",
    'Miss Rose came to this station with the painting.',
    'Now she is gone. But she left her suitcase behind.',
    'Inside it is a letter with a black wax seal.',
    'On the envelope, it says: "For the detective."',
  ],
  'caseSummary': 'You read every letter, followed the clues across the station and found out who is behind it all.',
  'hook': 'The little picture on the postmark is the Tower of London.',
  'glossary': {
    'hands': '건네다',
    'forgot': '잊어버렸다',
    'closes': '닫다, 문을 닫다',
    'arrive': '도착하다',
    'leave': '떠나다',
    'match': '맞다, 일치하다',
    'bit': '조금 (bit by bit: 하나씩 차례로)',
    'handwriting': '손글씨',
    'tidy': '깔끔한',
    'share': '함께 가지다',
    'home': '집, 사는 곳',
  },
  'missions': {
    'ep04_m1': {
      'story': [
        'The Lost Property office is full of umbrellas and bags that people forgot.',
        'A man hands you an old brown suitcase.',
      ],
      'letterIntro': 'You break the black wax seal and read the letter:',
      // Puzzle data: the same at every level.
      'letter': 'To the detective who finds this letter,\n\n'
          'Meet me where trains never sleep.\n\n'
          '— R.\n\n'
          'STATION GUIDE\n'
          'Ticket office: open 6 AM to 10 PM\n'
          'Café: open 7 AM to 8 PM\n'
          'Platforms: open day and night\n'
          'Shop: open 8 AM to 9 PM',
      'question': 'Where should you go to meet the person who wrote the letter?',
      'options': {
        'a': {'feedback': "The ticket office closes at 10 PM. Does it really 'never sleep'?"},
        'b': {'feedback': 'The café closes at 8 PM, so it sleeps at night!'},
        'd': {'feedback': 'The shop closes at 9 PM. Which place is open in the day AND at night?'},
      },
      'hints': [
        'Look at the station guide. When does each place close?',
        'If a place never sleeps, it never closes, even late at night.',
      ],
      'clue': {'note': 'The platforms never sleep. They stay open all day and all night.'},
      'evidence': {'description': 'This seal kept the secret letter closed.'},
      'successMessage': 'The platforms are open all night. They never sleep!',
      'transition': [
        'You walk out to the platforms. Trains arrive and leave.',
        'In the envelope, there is one more card.',
        'Only four words are written on it.',
      ],
    },
    'ep04_m2': {
      'story': [
        'The card says: RED · SMALL · CLOCK · PLATFORM.',
        'You look up at the clocks over the platforms.',
      ],
      'letterIntro': 'A porter tells you about the clock on each platform.',
      // Puzzle data: the same at every level.
      'letter': 'Platform 1 has a big white clock.\n'
          'Platform 4 has a small red clock.\n'
          'Platform 7 has a red door, but no clock.\n'
          'Platform 9 has a green clock.\n\n'
          'Your card says: RED · SMALL · CLOCK · PLATFORM.',
      'question': 'Where will you find the next clue?',
      'options': {
        'a': {'feedback': "Platform 1's clock is white, but your card says RED."},
        'c': {'feedback': 'Platform 7 has a red door. Read the whole line: does it have a clock?'},
        'd': {'feedback': "Platform 9's clock is green. What colour does your card say?"},
      },
      'hints': [
        'Your card has four words. Check every platform against all of them.',
        'The colour, the size and the thing must all match. A red door is not a red clock.',
      ],
      'clue': {'note': 'The next letter was hidden under the small red clock on Platform 4.'},
      'evidence': {'description': 'Four words that point to one place.'},
      'successMessage': 'It was under the red clock on Platform 4!',
      'transition': [
        'Under the small red clock, you find a second envelope.',
        'It has a postmark, but the rain washed the words away.',
        'Only a small picture is left.',
      ],
    },
    'ep04_m3': {
      'story': [
        'A postmark shows the place a letter was sent from.',
        'This postmark has a picture of a place in London.',
      ],
      'letterIntro': 'The second letter is very short.',
      'letter': 'Detective {detectiveName},\n\n'
          'I sent this letter from an old castle next to the river.\n'
          'It has four towers and very thick stone walls.\n'
          'Black birds live there.\n\n'
          '— R.',
      'question': 'Which picture do you see on the postmark?',
      'options': {
        'a': {'feedback': 'This is a palace, not a castle. Can you see four towers and thick walls?'},
        'c': {'feedback': 'This is a museum with tall columns. The letter talks about an old castle next to the river.'},
        'd': {'feedback': 'This is a big wheel by the river. Is it an old castle with four towers?'},
      },
      'hints': [
        'The letter tells you about the place bit by bit: a castle, a river, four towers and black birds. Find each one.',
        'A castle is a strong old building with thick stone walls and towers. Read the letter in your Notebook again.',
      ],
      'clue': {'note': 'The second letter was sent from the Tower of London.'},
      'evidence': {'description': 'It was on the second envelope.'},
      'successMessage': 'The letter came from the Tower of London!',
      'transition': [
        'There is one more letter inside the envelope.',
        'It has the same black seal as the first letter.',
        'This time, the writer almost tells you who they are...',
      ],
    },
    'ep04_final': {
      'story': [
        'On the last train of the night, you sit down and open the letter.',
        'The handwriting is small and tidy.',
      ],
      'letterIntro': 'This is what the last letter says:',
      'letter': 'Dear Detective {detectiveName},\n\n'
          'You are a very good reader. Now read one more time.\n\n'
          'My friends and I share a secret name.\n'
          'Our name comes from a bird.\n'
          'It makes its home at the Tower.\n'
          'It is pressed into every seal we send.\n\n'
          'We are the _____ Society.',
      'question': 'What is the secret name of the society?',
      // How the answer is typed: the same at every level.
      'prompt': 'THE _____ SOCIETY',
      'feedback': {
        'CROW': 'Close! A crow is black too. But which bird is pressed into the seal?',
        'BIRD': 'Yes, but which bird? Look again at the seal from the first letter.',
        'BLACK': 'That is its colour. What is the bird called?',
        'TOWER': "The Tower is its home. But what is the bird's name?",
      },
      'hints': [
        'Two things meet here: the bird pressed into the seal, and the black birds that live at the Tower.',
        'Look at the Black Wax Seal in your Notebook. Their name is the name of the bird on every seal.',
      ],
      'evidence': {'description': 'This letter is signed by the Raven Society.'},
      'successMessage': 'You found it: the Raven Society!',
      'transition': [
        'At last, the message is clear.',
        'THE RAVEN SOCIETY.',
        'The raven was more than a picture.',
        'It was pressed into every seal.',
        'You turn the envelope over.',
        'The small picture on the postmark',
        'is the Tower of London.',
      ],
    },
  },
};

// ── Master ───────────────────────────────────────────────────────────────
const Map<String, Object?> ep04Master = {
  'synopsis': [
    'An old suitcase sits unclaimed in the Lost Property office.',
    'Within lies a letter, closed with a black wax seal.',
    'Read it closely. It was meant for you alone.',
  ],
  'intro': [
    "King's Cross, eleven o'clock in the morning...",
    'Miss Rose arrived here with the painting.',
    'She has vanished, leaving only her suitcase behind.',
    'Inside lies a letter, closed with a black wax seal.',
    'Across the envelope are the words: "For the detective."',
  ],
  'caseSummary': 'You read every letter closely, traced its words across the station and uncovered who stands behind them.',
  'hook': 'The faded picture on the postmark shows the Tower of London.',
  'glossary': {
    'unclaimed': '찾아가지 않은',
    'within': '~ 안에',
    'vanished': '사라졌다',
    'crowded': '붐비는, 가득 찬',
    'abandoned': '버려진',
    'counter': '창구, 계산대',
    'slides': '밀어서 건네다',
    'crack': '깨뜨리다',
    'unfold': '펼치다',
    'shut': '닫다, 닫힌',
    'tucked': '끼워 넣어진',
    'bears': '(글자·모양을) 지니고 있다',
    'passing': '지나가던',
    'object': '물건',
    'records': '기록하다',
    'journey': '여정, 이동',
    'carries': '지니고 있다',
    'brief': '짧은',
    'ancient': '아주 오래된',
    'rise': '솟아 있다',
    'printed': '찍힌',
    'grand': '웅장한',
    'columns': '기둥들',
    'dome': '둥근 지붕',
    'posted': '(우편으로) 부쳤다',
    'revealing': '드러내는, 밝히는',
    'aboard': '~에 타고',
    'settle': '자리를 잡다',
    'careful': '정성 들인, 조심스러운',
    'remarkably': '놀랍도록',
    'companions': '동료들',
    'dwells': '살다',
    'mark': '표시, 문양',
    'merely': '단지',
    'study': '자세히 살펴보다',
    'signature': '서명',
    'focus': '초점 (come into focus: 또렷해지다)',
    'faded': '바랜, 흐려진',
    'traced': '따라갔다',
    'uncovered': '밝혀냈다',
  },
  'missions': {
    'ep04_m1': {
      'story': [
        'The Lost Property office is crowded with forgotten umbrellas and abandoned bags.',
        'A man behind the counter slides an old brown suitcase towards you.',
      ],
      'letterIntro': 'You crack the black wax seal and unfold the letter:',
      // Puzzle data: the same at every level.
      'letter': 'To the detective who finds this letter,\n\n'
          'Meet me where trains never sleep.\n\n'
          '— R.\n\n'
          'STATION GUIDE\n'
          'Ticket office: open 6 AM to 10 PM\n'
          'Café: open 7 AM to 8 PM\n'
          'Platforms: open day and night\n'
          'Shop: open 8 AM to 9 PM',
      'question': 'Where does the writer want to meet you?',
      'options': {
        'a': {'feedback': "The ticket office shuts at 10 PM. Is that a place that 'never sleeps'?"},
        'b': {'feedback': 'The café shuts at 8 PM. It sleeps at night like everyone else!'},
        'd': {'feedback': 'The shop shuts at 9 PM. Which place stays open by day AND by night?'},
      },
      'hints': [
        'Set the letter beside the station guide: which places shut their doors at night?',
        "A place that 'never sleeps' stays open through the night as well as the day.",
      ],
      'clue': {'note': 'The platforms never sleep: they are open day and night, every night.'},
      'evidence': {'description': 'The seal that kept the secret letter shut.'},
      'successMessage': 'Of course: the platforms never sleep!',
      'transition': [
        'You make your way to the platforms as trains come and go.',
        'Tucked inside the envelope is one more card.',
        'It bears just four words.',
      ],
    },
    'ep04_m2': {
      'story': [
        'The card says: RED · SMALL · CLOCK · PLATFORM.',
        'You raise your eyes to the clocks hanging above the platforms.',
      ],
      'letterIntro': 'A passing porter describes the station clocks for you.',
      // Puzzle data: the same at every level.
      'letter': 'Platform 1 has a big white clock.\n'
          'Platform 4 has a small red clock.\n'
          'Platform 7 has a red door, but no clock.\n'
          'Platform 9 has a green clock.\n\n'
          'Your card says: RED · SMALL · CLOCK · PLATFORM.',
      'question': 'Which platform hides the next clue?',
      'options': {
        'a': {'feedback': "Platform 1's clock is big and white. Does that match your card?"},
        'c': {'feedback': 'A red door, yes. But read on to the end of that line: is there any clock at all?'},
        'd': {'feedback': "Platform 9's clock is green. Which colour did the card ask for?"},
      },
      'hints': [
        'Every word on the card must fit at once. Which platform passes all of the tests?',
        "Colour, size and object must belong to the same thing. Read each of the porter's lines to its very end.",
      ],
      'clue': {'note': 'The next letter lay waiting under the small red clock on Platform 4.'},
      'evidence': {'description': 'Four words, and only one place fits them all.'},
      'successMessage': 'Beneath the small red clock on Platform 4!',
      'transition': [
        'Beneath the small red clock lies a second envelope.',
        'It bears a postmark, but the rain washed the words away.',
        'Only a small picture is left.',
      ],
    },
    'ep04_m3': {
      'story': [
        'A postmark records where a letter began its journey.',
        'This one carries a small picture of somewhere in London.',
      ],
      'letterIntro': 'The second letter is brief.',
      'letter': 'Detective {detectiveName},\n\n'
          'I sent this letter from an ancient castle beside the river.\n'
          'Four towers rise above its thick stone walls.\n'
          'Black birds live there.\n\n'
          '— R.',
      'question': 'Which of these pictures is printed on the postmark?',
      'options': {
        'a': {'feedback': 'A grand palace, but no castle: where are the four towers and the thick stone walls?'},
        'c': {'feedback': 'Tall columns and a dome belong to a museum, not to an ancient castle beside the river.'},
        'd': {'feedback': 'It stands by the river, but a giant wheel is no ancient castle with four towers.'},
      },
      'hints': [
        'Each line of the letter adds one detail. Which picture shows every one of them together?',
        'Think of what makes a castle a castle: towers and thick stone walls, built to be strong.',
      ],
      'clue': {'note': 'The second letter was posted from the Tower of London.'},
      'evidence': {'description': 'Taken from the second envelope.'},
      'successMessage': 'It was sent from the Tower of London!',
      'transition': [
        'One final letter waits inside the envelope.',
        'It is closed with the same black seal as the first.',
        'This time, the writer comes close to revealing who they are...',
      ],
    },
    'ep04_final': {
      'story': [
        'Aboard the last train of the night, you settle into a seat and open the letter.',
        'The handwriting is small, careful and neat.',
      ],
      'letterIntro': 'The last letter reads:',
      'letter': 'Dear Detective {detectiveName},\n\n'
          'You read remarkably well. So read once more.\n\n'
          'My companions and I go by a secret name.\n'
          'We take our name from a bird.\n'
          'It dwells at the Tower.\n'
          'Its mark is pressed into every seal we send.\n\n'
          'We are the _____ Society.',
      'question': 'What secret name does the society go by?',
      // How the answer is typed: the same at every level.
      'prompt': 'THE _____ SOCIETY',
      'feedback': {
        'CROW': 'Close! A crow is a black bird as well, but is it the one pressed into the seal?',
        'BIRD': 'Quite right, but which bird? Study the seal from the first letter.',
        'BLACK': 'Black is only its colour. What do we call the bird itself?',
        'TOWER': 'The Tower is merely its home. What is the bird named?',
      },
      'hints': [
        'Their name and their seal share one secret. What was pressed into the wax of the first letter?',
        'Turn back in your Notebook to the Black Wax Seal: whatever bird it bears gives the society its name.',
      ],
      'evidence': {'description': 'A letter bearing the signature of the Raven Society.'},
      'successMessage': 'The secret name is out: the Raven Society!',
      'transition': [
        'At last, the message comes into focus.',
        'THE RAVEN SOCIETY.',
        'The raven was never merely a picture.',
        'It was their mark, on every seal.',
        'You turn the envelope over in your hands.',
        'The faded picture on the postmark',
        'shows the Tower of London.',
      ],
    },
  },
};

// ── Discovery Moments ────────────────────────────────────────────────────
const Map<String, Discovery> ep04JuniorDiscoveries = {
  'ep04_m1': Discovery(
    type: DiscoveryType.newLead,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'THE PLATFORMS',
    detail: 'Open all day and all night: the place where trains never sleep.',
    note: 'A black wax seal kept the letter closed.',
  ),
  'ep04_m2': Discovery(
    type: DiscoveryType.clueFound,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'PLATFORM 4',
    detail: 'Red, small, clock, platform: only the small red clock on Platform 4 matches them all.',
  ),
  'ep04_m3': Discovery(
    type: DiscoveryType.newLead,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'THE TOWER OF LONDON',
    detail: 'An old castle next to the river, with four towers: the letter was sent from there.',
  ),
};

const Map<String, Discovery> ep04MasterDiscoveries = {
  'ep04_m1': Discovery(
    type: DiscoveryType.newLead,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'THE PLATFORMS',
    detail: 'Never closed, by day or by night: the place where trains never sleep.',
    note: 'The letter had been closed with a seal of black wax.',
  ),
  'ep04_m2': Discovery(
    type: DiscoveryType.clueFound,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'PLATFORM 4',
    detail: 'Red, small, clock, platform: every word points to the small red clock on Platform 4.',
  ),
  'ep04_m3': Discovery(
    type: DiscoveryType.newLead,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'THE TOWER OF LONDON',
    detail: 'An ancient castle beside the river, guarded by four towers: the letter began its journey there.',
  ),
};

// ── The parent report's English ──────────────────────────────────────────
const Map<String, LearningObjective> ep04JuniorLearning = {
  'ep04_m1': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.sentenceMeaning,
    objective: '비유 표현 "never sleep"을 "밤에도 문을 닫지 않는다(never closes)"로 이해한다.',
    expressions: ['Meet me where trains never sleep', 'never closes'],
  ),
  'ep04_m2': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.sentenceMeaning,
    objective: '보기는 승강장 번호뿐이다. 짐꾼의 네 문장을 끝까지 읽고 RED·SMALL·CLOCK을 모두 맞는 곳을 찾는다("a red door, but no clock"은 시계가 아니다).',
    expressions: ['Platform 4 has a small red clock', 'Platform 7 has a red door, but no clock'],
  ),
  'ep04_m3': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.vocabulary,
    objective: '그림에 이름이 없다. 편지의 묘사(an old castle next to the river, four towers, black birds)를 읽고 그림을 고른다.',
    expressions: ['an old castle next to the river', 'four towers and very thick stone walls', 'Black birds live there'],
  ),
  'ep04_final': LearningObjective(
    dependency: LanguageDependency.helpful,
    level: LearningLevel.exposure,
    skill: LanguageSkill.vocabulary,
    objective: '봉인 글귀를 다시 읽고 모임의 이름을 쓴다. 정답 단어가 앞 사건들에서 여러 번 나온다.',
    expressions: ['Our name comes from a bird', 'It makes its home at the Tower'],
    recallFrom: 'ep04_m1',
  ),
};

const Map<String, LearningObjective> ep04MasterLearning = {
  'ep04_m1': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.sentenceMeaning,
    objective: '비유 표현 "never sleep"을 "밤새 열려 있다(stays open through the night)"로 이해한다.',
    expressions: ['Meet me where trains never sleep', 'stays open through the night'],
  ),
  'ep04_m2': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.sentenceMeaning,
    objective: '보기는 승강장 번호뿐이다. 짐꾼의 네 문장을 끝까지 읽고 RED·SMALL·CLOCK을 모두 맞는 곳을 찾는다("a red door, but no clock"은 시계가 아니다).',
    expressions: ['Platform 4 has a small red clock', 'Platform 7 has a red door, but no clock'],
  ),
  'ep04_m3': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.vocabulary,
    objective: '그림에 이름이 없다. 편지의 묘사(an ancient castle beside the river, four towers, black birds)를 읽고 그림을 고른다.',
    expressions: ['an ancient castle beside the river', 'Four towers rise above its thick stone walls', 'Black birds live there'],
  ),
  'ep04_final': LearningObjective(
    dependency: LanguageDependency.helpful,
    level: LearningLevel.exposure,
    skill: LanguageSkill.vocabulary,
    objective: '봉인 글귀를 다시 읽고 모임의 이름을 쓴다. 정답 단어가 앞 사건들에서 여러 번 나온다.',
    expressions: ['We take our name from a bird', 'Its mark is pressed into every seal we send'],
    recallFrom: 'ep04_m1',
  ),
};
