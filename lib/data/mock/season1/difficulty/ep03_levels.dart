import '../../../models/discovery.dart';
import '../../../models/investigation.dart';
import '../../../models/learning.dart';
import '../../../models/scene_trail.dart';
import '../season1_investigations.dart';
import '../season1_trails.dart';
import 'level_words.dart';

// Case 03 — The Vanishing Painting, at each level (PART 6A).
//
// The facts never move: 9:18 and one minute too late (Case 02's bell); the
// red button under the bench, the blue cloth on the frame, the wet
// footprint next to the door (each report line names its place, and the
// search finds each thing where its line says); Miss Rose in a red coat and
// a blue scarf, Mr Grey's red only a scarf; very wet → wet → a little wet →
// almost dry (shop, stairs, café, north door); "Take me north" and a tall
// clock tower, which fits Big Ben and King's Cross alike — only the boot's
// "trains and smoke" (its evidence, the same words at every level) decides.
// So nothing before the final names a station, a train or King's Cross,
// and its tips never do. The Red Button (Case 08) and the lost-property tag
// (Case 04) are kept by name and words.
//
// Rookie: the base, with the order tip cut into short sentences.

const Map<String, Object?> ep03Rookie = {
  'missions': {
    'ep03_m3': {
      'hints': [
        'Each line says how wet one footprint was. Find the wettest and the driest.',
        'Wet shoes get drier with every step. Her first footprint is the wettest. Her last one is the driest. Put the other two in between.',
      ],
    },
  },
};

// The guard's report at each level: its lines are the search's own.
const _juniorButton = 'The button is red. I saw it under the bench.';
const _juniorCloth = 'The cloth is blue. It is caught on the frame.';
const _juniorFootprint = 'The footprint is wet. It is right next to the door.';
const _masterButton = 'A red button lies under the bench.';
const _masterCloth = 'A scrap of blue cloth hangs on the frame.';
const _masterFootprint = 'A wet footprint marks the floor next to the door.';

// ── Junior ───────────────────────────────────────────────────────────────
const Map<String, Object?> ep03Junior = {
  'synopsis': [
    'A famous painting has vanished from Gallery 8.',
    'The thief left three small things behind.',
    'Read every clue carefully and find out where she went.',
  ],
  'intro': [
    'British Museum, 9:18 AM...',
    'Big Ben rang, and the guards ran to Gallery 8.',
    'But they were one minute too late.',
    'The frame of Picture 17 is empty now.',
    'The thief was in a hurry. She left three small things behind.',
  ],
  'caseSummary': 'You read each small clue and followed the thief out of the museum.',
  'hook': 'The stolen painting shows a tower full of ravens.',
  'glossary': {
    'famous': '유명한',
    'carefully': '주의 깊게',
    'noticed': '알아차렸다',
    'strange': '이상한',
    'caught': '걸린',
    'facts': '사실들',
    'search': '찾다, 조사하다',
    'visited': '방문했다',
    'wearing': '입고 있는',
    'matches': '일치하다',
    'remember': '기억하다',
    'order': '순서',
    'carrying': '들고 있는',
    'hurried': '서둘러 갔다',
    'outside': '바깥에',
    'stolen': '도난당한',
  },
  'missions': {
    'ep03_m1': {
      'story': [
        'Picture 17 was a painting called "The Raven Tower".',
        'Now only an empty golden frame hangs on the wall.',
      ],
      'letterIntro': 'The museum guard hands you his report.',
      'letter': 'GUARD REPORT — GALLERY 8\n\n'
          'I noticed three strange things in the gallery.\n'
          '$_juniorButton\n'
          '$_juniorCloth\n'
          '$_juniorFootprint',
      'question': 'Which thing did the guard find next to the door?',
      'options': {
        'a': {'feedback': 'Read the line about the button again. Where is it?'},
        'b': {'feedback': 'The blue cloth was on the frame. Which thing was next to the door?'},
        'd': {'feedback': "The cloth was on the frame. Find the line that ends with 'the door'."},
      },
      'hints': [
        'Each line of the report gives two facts: what a thing looks like, and where it is.',
        "Look at the small place words: 'under', 'on' and 'next to'. Then search those places in the gallery.",
      ],
      'clue': {'note': 'The wet footprint was right next to the door.'},
      'evidence': {'description': 'A button from a coat. It was under the bench.'},
      'successMessage': 'The wet footprint shows the way out!',
      'transition': [
        'You pick up the red button and the blue cloth.',
        'The guard shows you a list of visitors.',
        'Three people visited Gallery 8 this morning.',
      ],
    },
    'ep03_m2': {
      'story': [
        'In the Egypt Room, old mummies lie in their glass cases.',
        'Another piece of the same blue cloth is caught on one of the cases.',
      ],
      'letterIntro': 'The guard reads out his notes about the three visitors.',
      'letter': 'Mr Green was wearing a brown coat and a green hat.\n\n'
          'Miss Rose was wearing a red coat and a blue scarf.\n\n'
          'Mr Grey was wearing a black coat and a red scarf.',
      'question': 'Which visitor took the painting?',
      'options': {
        'a': {'feedback': 'Mr Green wore brown and green. What colours were the things in Gallery 8?'},
        'c': {'feedback': 'Mr Grey has something red, but it is his scarf. Buttons come from coats.'},
      },
      'hints': [
        'Check your notebook. What colour was the button, and what colour was the cloth?',
        'Buttons are found on coats. The cloth could come from a scarf. Who matches both?',
      ],
      'clue': {'note': 'A red coat and a blue scarf. Miss Rose is the thief.'},
      'evidence': {'description': 'A piece torn from a blue scarf.'},
      'successMessage': 'A red coat and a blue scarf: it was Miss Rose!',
      'transition': [
        'Miss Rose has already left the museum.',
        'But her wet footprints cross the Great Court.',
        'Follow them!',
      ],
    },
    'ep03_m3': {
      'story': [
        'The Great Court has a big glass roof and a white floor.',
        'Four footprints cross the floor. Some are wetter than others.',
      ],
      'letterIntro': 'A cleaner stops you. She saw the footprints before anyone else.',
      'letter': 'The footprint by the café was only a little wet.\n'
          'The footprint by the shop was very wet.\n'
          'The footprint by the north door was almost dry.\n'
          'The footprint by the stairs was wet.\n\n'
          'Remember: wet shoes get drier with every step!',
      'question': 'In what order did Miss Rose walk past these places? Start with her first step.',
      'feedback': {
        'door,cafe,stairs,shop': 'You started with the driest footprint. Her first step was the wettest one.',
        'shop,cafe,stairs,door': "Look at 'wet' and 'a little wet' again. Which one is wetter?",
      },
      'orderFeedback': 'Some steps are in the right place. Order them from very wet to almost dry.',
      'hints': [
        'Each line tells you how wet one footprint was. Which was the wettest? Which was the driest?',
        'Her first step was the wettest, and her last step was the driest. Now place the other two between them.',
      ],
      'clue': {'note': 'Miss Rose went out by the north door.'},
      'evidence': {'description': 'From a small boot. The trail goes to the north door.'},
      'successMessage': 'She went out by the north door!',
      'transition': [
        'Outside the north door, a taxi driver is waiting.',
        '"A lady in a red coat?" he says. "Yes, I drove her away in my taxi."',
        'But where did he take her?',
      ],
    },
    'ep03_final': {
      'story': [
        'The taxi driver tells you what he saw.',
        'Miss Rose was carrying a long, flat parcel under her arm. It was the painting!',
      ],
      'letterIntro': 'He writes it all down for you.',
      'letter': 'The lady said: "Take me north, please!"\n\n'
          'I stopped outside a big building with a tall clock tower.\n'
          'She hurried inside with her parcel.',
      'question': 'Which picture shows where the taxi took Miss Rose?',
      'options': {
        'a': {'feedback': 'Big Ben has a tall clock tower too. Check the clue from her boot.'},
        'b': {'feedback': 'The driver talked about a big building with a tall clock tower. Is this one?'},
        'c': {'feedback': 'A park does not have a clock tower. Read what the driver said again.'},
      },
      'hints': [
        "Two pictures have a tall clock tower. The driver's words cannot tell them apart. Look at today's evidence.",
        'Open your notebook and read the wet footprint again. What did the boot smell of? Which place fits that smell?',
      ],
      'evidence': {'description': 'It fell out of the taxi Miss Rose took.'},
      'successMessage': "The taxi took Miss Rose to King's Cross!",
      'transition': [
        'Miss Rose has gone.',
        'But something fell out of her taxi.',
        'It is a luggage tag.',
        "KING'S CROSS\nLOST PROPERTY",
        'And the missing painting?',
        'It shows a tower\nfull of ravens.',
      ],
    },
  },
};

// ── Master ───────────────────────────────────────────────────────────────
const Map<String, Object?> ep03Master = {
  'synopsis': [
    'A painting has vanished from Gallery 8 of the British Museum.',
    'In her hurry, the thief left three small things behind.',
    'Read every clue closely and follow the path she took.',
  ],
  'intro': [
    'British Museum, 9:18 AM...',
    'The moment Big Ben rang, the guards rushed to Gallery 8.',
    'Even so, they were one minute too late.',
    'The frame of Picture 17 hangs empty.',
    'In her haste, the thief left three small things behind.',
  ],
  'caseSummary': 'You read every small clue and tracked the thief out of the museum.',
  'hook': 'The stolen painting shows a tower crowded with ravens.',
  'glossary': {
    'path': '길, 경로',
    'rushed': '급히 달려갔다',
    'haste': '서두름',
    'hangs': '걸려 있다',
    'known': '~라고 알려진',
    'remains': '남아 있다',
    'passes': '건네주다',
    'caught': '(눈길을) 끌었다, 걸린',
    'scrap': '조각',
    'marks': '자국을 남기다',
    'places': '(~에) 두다',
    'pairs': '짝짓다',
    'exactly': '정확히',
    'reveals': '드러내다',
    'escaped': '달아났다',
    'collect': '모으다',
    'entered': '들어갔다',
    'torn': '찢어진',
    'uneasy': '불안한',
    'hush': '고요함',
    'touched': '건드린',
    'unusual': '이상한, 흔치 않은',
    'clings': '달라붙어 있다',
    'glistens': '반짝이다',
    'firmly': '단단히',
    'beyond': '~ 너머의',
    'ancient': '고대의, 아주 오래된',
    'snagged': '(걸려서) 걸린',
    'aloud': '소리 내어',
    'dressed': '(옷을) 입은',
    'arrived': '도착했다',
    'neither': '어느 것도 ~아니다',
    'stole': '훔쳤다',
    'slipped': '빠져나갔다',
    'trail': '흔적, 자취',
    'pours': '쏟아지다',
    'notice': '알아차리다',
    'indeed': '정말로',
    'simply': '그냥, 단지',
    'retrace': '되짚다',
    'begin': '시작하다',
    'arrange': '정리하다, 배열하다',
    'begins': '시작하다',
    'drier': '더 마른',
    'cab': '택시',
    'escape': '탈출',
    'clutched': '꼭 움켜쥐었다',
    'surely': '틀림없이',
    'scribbles': '휘갈겨 쓰다',
    'pulled': '(차를) 세웠다',
    'crowned': '꼭대기에 ~가 있는',
    'tight': '꽉',
    'fits': '들어맞다',
    'fled': '달아났다',
    'vanished': '사라졌다',
    'dropped': '떨어졌다',
    'stolen': '도난당한',
    'crowded': '가득 찬',
    'tracked': '추적했다',
  },
  'missions': {
    'ep03_m1': {
      'story': [
        'Picture 17 was a painting known as "The Raven Tower".',
        'All that remains is an empty golden frame on the wall.',
      ],
      'letterIntro': 'The museum guard passes you the report he wrote.',
      'letter': 'GUARD REPORT — GALLERY 8\n\n'
          'Three things in this gallery caught my eye.\n'
          '$_masterButton\n'
          '$_masterCloth\n'
          '$_masterFootprint',
      'question': 'Which of the three things lay next to the door?',
      'options': {
        'a': {'feedback': 'Look again at where the report places the button.'},
        'b': {'feedback': 'The cloth was hanging on the frame, not by the door.'},
        'd': {'feedback': 'The frame is only where the cloth was caught. Which line mentions the door?'},
      },
      'hints': [
        'Every line of the report pairs a thing with a place. Where does each one lead you?',
        "'Under', 'on' and 'next to' each point to a different spot. Search each one exactly where the report says.",
      ],
      'clue': {'note': 'A wet footprint was left beside the door.'},
      'evidence': {'description': 'Torn from a coat, it was lying under the bench.'},
      'successMessage': 'The wet footprint reveals the way she escaped!',
      'transition': [
        'You carefully collect the red button and the blue cloth.',
        "The guard points to the morning's list of visitors.",
        'Only three people entered Gallery 8 this morning.',
      ],
    },
    'ep03_m2': {
      'story': [
        'In the Egypt Room, ancient mummies rest in their glass cases.',
        'Snagged on the corner of one case is another scrap of the same blue cloth.',
      ],
      'letterIntro': 'The guard reads aloud from his notes on the three visitors.',
      'letter': 'Mr Green arrived in a brown coat and a green hat.\n\n'
          'Miss Rose was dressed in a red coat and a blue scarf.\n\n'
          'Mr Grey came in a black coat and a red scarf.',
      'question': 'Which of the three visitors stole the painting?',
      'options': {
        'a': {'feedback': 'Brown and green: neither matches what was left in Gallery 8.'},
        'c': {'feedback': 'Mr Grey does wear red, but only on his scarf. Where does a button come from?'},
      },
      'hints': [
        'Two pieces of evidence, two colours. Which visitor matches both?',
        'Think about where each thing came from: a button from a coat, a cloth from a scarf.',
      ],
      'clue': {'note': 'Her red coat and blue scarf give Miss Rose away.'},
      'evidence': {'description': 'A scrap torn from a blue scarf.'},
      'successMessage': 'The red coat and the blue scarf both lead to Miss Rose!',
      'transition': [
        'Miss Rose has already slipped out of the museum.',
        'Yet her wet footprints still cross the Great Court.',
        'Follow her trail!',
      ],
    },
    'ep03_m3': {
      'story': [
        'Light pours through the glass roof of the Great Court onto its white floor.',
        'Four footprints cross it, some wetter than others.',
      ],
      'letterIntro': 'A cleaner calls you over. She was the first to notice the footprints.',
      'letter': 'By the café, the footprint was only a little wet.\n'
          'By the shop, it was very wet indeed.\n'
          'By the north door, it was almost dry.\n'
          'By the stairs, it was simply wet.\n\n'
          'After all, wet shoes get drier with every step.',
      'question': 'In what order did Miss Rose pass these places? Begin with her first step.',
      'feedback': {
        'door,cafe,stairs,shop': 'That order runs backwards. Which footprint was made first?',
        'shop,cafe,stairs,door': "Compare 'simply wet' and 'only a little wet'. Which came first?",
      },
      'orderFeedback': 'Some steps are already in place. Arrange the rest from wettest to driest.',
      'hints': [
        'The cleaner describes four footprints, each a little wetter or drier. Which one begins the trail?',
        'If shoes dry with every step, the wettest print came first. Order the rest by how wet they were.',
      ],
      'clue': {'note': 'Miss Rose made her escape through the north door.'},
      'evidence': {'description': 'The print of a small boot, leading to the north door.'},
      'successMessage': 'She slipped out through the north door!',
      'transition': [
        'Beyond the north door, a taxi driver leans against his cab.',
        '"A lady in a red coat?" he says. "Oh yes, I drove her away."',
        'But where did she go?',
      ],
    },
    'ep03_final': {
      'story': [
        'The taxi driver tells you everything he saw.',
        'Under her arm, Miss Rose clutched a long, flat parcel — the painting, surely!',
      ],
      'letterIntro': 'He scribbles it down on a scrap of paper.',
      'letter': 'The lady said: "Take me north, and quickly!"\n\n'
          'I pulled up outside a large building crowned by a tall clock tower.\n'
          'She rushed inside, her parcel held tight.',
      'question': 'Which of these places did Miss Rose run into?',
      'options': {
        'a': {'feedback': "Big Ben fits the driver's words, but does it fit the smell of her boot?"},
        'b': {'feedback': 'Does this place have the tall clock tower the driver described?'},
        'c': {'feedback': "A park has no tall clock tower. Read the driver's words once more."},
      },
      'hints': [
        "The driver's words fit more than one picture. Something you found earlier today can tell them apart.",
        'In your notebook, the footprint holds a clue about where she had been. Which clock tower does it point to?',
      ],
      'evidence': {'description': 'It dropped from the taxi as Miss Rose left.'},
      'successMessage': "Miss Rose fled to King's Cross!",
      'transition': [
        'Miss Rose has vanished.',
        'But something slipped out of her taxi.',
        'A luggage tag.',
        "KING'S CROSS\nLOST PROPERTY",
        'And the stolen painting?',
        'It shows a tower\nfull of ravens.',
      ],
    },
  },
};

// ── Gallery 8's search (its picture, things, places and answer the base's)
final InvestigationScene _search = season1Investigations['ep03_m1']!;

List<InvestigationFind> _finds(Map<String, (String, String)> words) => [
      for (final f in _search.finds)
        if (words[f.id] case (final report, final found)) f.copyWith(reportLine: report, foundLine: found) else f,
    ];

final Map<String, InvestigationScene> ep03JuniorInvestigations = {
  'ep03_m1': _search.copyWith(
    task: 'Find the three things from the report.',
    missLine: 'Nothing here. Check the report: where is each thing?',
    doneLine: 'You found all three things!',
    arrival: const [
      'Gallery 8 is very quiet. Nobody has moved anything since the theft.',
      'The museum guard hands you his report about three strange things.',
    ],
    finds: _finds(const {
      'button': (_juniorButton, 'You found the red button under the bench!'),
      'cloth': (_juniorCloth, 'A piece of blue cloth is caught on the frame!'),
      'footprint': (_juniorFootprint, 'You found a wet footprint next to the door!'),
    }),
    spots: relined(_search.spots, const [
      'There is nothing on the bench. The report says UNDER it.',
      'The door is shut. The report says NEXT TO the door, not on it.',
      'This frame still has its painting in it.',
      'A marble statue. There is nothing hidden here.',
      'The glass case is locked. The vase inside is safe.',
      'A marble head. There is nothing here.',
      'Not this bench. The report means the one near you.',
      'Only the glass roof and the sky above.',
    ]),
  ),
};

final Map<String, InvestigationScene> ep03MasterInvestigations = {
  'ep03_m1': _search.copyWith(
    task: 'Track down all three things in the report.',
    missLine: 'Nothing here. What does the report say about each place?',
    doneLine: 'Every one of the three things is found!',
    arrival: const [
      'An uneasy hush fills Gallery 8. Nothing has been touched since the theft.',
      'The museum guard hands you his report on three unusual things.',
    ],
    finds: _finds(const {
      'button': (_masterButton, 'Under the bench lies a small red button.'),
      'cloth': (_masterCloth, 'A scrap of blue cloth clings to the frame.'),
      'footprint': (_masterFootprint, 'Beside the door, a wet footprint glistens on the floor.'),
    }),
    spots: relined(_search.spots, const [
      'Nothing on top of the bench. The report says UNDER it.',
      'The door is firmly shut. The report says NEXT TO the door.',
      'This frame still holds its painting.',
      'A marble statue, with nothing hidden at its feet.',
      'The glass case is locked tight; its vase is safe.',
      'A marble head, and nothing more.',
      'Not this bench. The report means the one beside you.',
      'Nothing but the glass roof and the sky beyond.',
    ]),
  ),
};

// ── Mission 03's footprints (the picture and the four places the base's) ──
final TrailScene _court = season1Trails['ep03_m3']!;

final Map<String, TrailScene> ep03JuniorTrails = {
  'ep03_m3': _court.copyWith(
    lead: 'Four footprints cross the white floor. Tap them in the order Miss Rose made them.',
    guide: 'Tap a footprint to give it a number. Tap it again to take it back.',
  ),
};

final Map<String, TrailScene> ep03MasterTrails = {
  'ep03_m3': _court.copyWith(
    lead: 'Four footprints cross the floor of the court. Retrace her steps by tapping them in order.',
    guide: 'Tap a footprint to number it; tap it again to undo that step.',
  ),
};

// ── Discovery Moments ────────────────────────────────────────────────────
const Map<String, Discovery> ep03JuniorDiscoveries = {
  'ep03_m1': Discovery(
    type: DiscoveryType.evidenceFound,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'A RED BUTTON',
    detail: 'And next to the door, a wet footprint: the way the thief went out.',
    showEvidence: true,
  ),
  'ep03_m2': Discovery(
    type: DiscoveryType.deduction,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'MISS ROSE',
    detail: 'A red coat and a blue scarf: the button and the cloth both lead to her.',
  ),
  'ep03_m3': Discovery(
    type: DiscoveryType.clueFound,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'THE NORTH DOOR',
    detail: 'From the wettest step to the driest: she went out by the north door.',
    showEvidence: true,
  ),
};

const Map<String, Discovery> ep03MasterDiscoveries = {
  'ep03_m1': Discovery(
    type: DiscoveryType.evidenceFound,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'A RED BUTTON',
    detail: 'And beside the door, a wet footprint marks the way the thief escaped.',
    showEvidence: true,
  ),
  'ep03_m2': Discovery(
    type: DiscoveryType.deduction,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'MISS ROSE',
    detail: 'A red coat and a blue scarf: the button and the cloth agree on one visitor.',
  ),
  'ep03_m3': Discovery(
    type: DiscoveryType.clueFound,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'THE NORTH DOOR',
    detail: 'From the wettest print to the driest, her trail ends at the north door.',
    showEvidence: true,
  ),
};

// ── The parent report's English ──────────────────────────────────────────
const Map<String, LearningObjective> ep03JuniorLearning = {
  'ep03_m1': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.application,
    skill: LanguageSkill.grammarInContext,
    objective: '보고서의 위치 표현(under / on / next to)을 읽고, 그 자리를 갤러리에서 직접 조사해 세 물건을 찾는다.',
    expressions: ['I saw it under the bench', 'It is caught on the frame', 'right next to the door'],
  ),
  'ep03_m2': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.sentenceMeaning,
    objective: '옷차림 묘사(색깔 + 옷)를 두 조건으로 비교해 범인을 찾는다.',
    expressions: ['Miss Rose was wearing a red coat and a blue scarf'],
    recallFrom: 'ep03_m1',
  ),
  'ep03_m3': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.application,
    skill: LanguageSkill.grammarInContext,
    objective: '정도 표현(very wet → almost dry)으로 발자국의 순서를 정한다.',
    expressions: ['very wet', 'only a little wet', 'almost dry', 'wet shoes get drier with every step'],
  ),
  'ep03_final': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.recall,
    skill: LanguageSkill.sentenceMeaning,
    objective: '택시 기사의 말과 앞에서 찾은 증거 글귀(기차 냄새)를 함께 읽어 장소를 정한다.',
    expressions: ['Take me north', 'a tall clock tower', 'The boot smells of trains and smoke'],
    recallFrom: 'ep03_m3',
  ),
};

const Map<String, LearningObjective> ep03MasterLearning = {
  'ep03_m1': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.application,
    skill: LanguageSkill.grammarInContext,
    objective: '보고서의 위치 표현(lies under / hangs on / next to)을 읽고, 그 자리를 갤러리에서 직접 조사해 세 물건을 찾는다.',
    expressions: ['lies under the bench', 'hangs on the frame', 'marks the floor next to the door'],
  ),
  'ep03_m2': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.sentenceMeaning,
    objective: '옷차림 묘사(arrived in / dressed in / came in + 색깔 + 옷)를 두 조건으로 비교해 범인을 찾는다.',
    expressions: ['Miss Rose was dressed in a red coat and a blue scarf'],
    recallFrom: 'ep03_m1',
  ),
  'ep03_m3': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.application,
    skill: LanguageSkill.grammarInContext,
    objective: '정도 표현(very wet indeed → simply wet → only a little wet → almost dry)으로 발자국의 순서를 정한다.',
    expressions: ['very wet indeed', 'simply wet', 'only a little wet', 'almost dry'],
  ),
  'ep03_final': LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.recall,
    skill: LanguageSkill.sentenceMeaning,
    objective: '택시 기사의 말과 앞에서 찾은 증거 글귀(기차 냄새)를 함께 읽어 장소를 정한다.',
    expressions: ['Take me north', 'crowned by a tall clock tower', 'The boot smells of trains and smoke'],
    recallFrom: 'ep03_m3',
  ),
};
