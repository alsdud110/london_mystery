import '../../models/clock_puzzle.dart';
import '../../models/difficulty.dart';
import '../../models/investigation.dart' show InvestigationSpot;
import '../../models/learning.dart';
import '../../models/painter_puzzles.dart';
import '../../models/scene_exhibit.dart';
import '../../models/station_clocks.dart';
import '../season_catalog.dart';
import 'season2_case03_scenes.dart';
import 'season2_learning.dart';
import 'season2_scenes.dart';

/// Season 2's words at each level (the game's own words are Rookie's).
///
/// Written (PART 7A): Cases 01–03, every page, at Junior and Master — the
/// case file, each mission's story, papers, question, hints, wrong-answer
/// lines, success line (also its Discovery Moment's title), the scene after
/// it, its clue and evidence notes, its scene's own words and its learning
/// design. Rookie: the game's own words, reviewed, with the words a child
/// may not know added to the glossary (`docs/difficulty_reviews/
/// PARIS_CASE_01_03.md`).
///
/// At every level the same: the times, the answers, every id and order, the
/// papers the puzzles are read from (the station notice, the clerk's three
/// order lines, the painter's three note headings and the instructions of
/// his notes, the inspection steps, the time cards), the painter's own
/// words ("I saw who took the hour.", "A city can lose an hour. But who can
/// steal it?"), the plaque, the names of the evidence (other cases name
/// them), and every way to play (Tap…, Drag…, Slide…).
///
/// Kept untold at every level: who the Clockmaker is; that the man with the
/// pocket watch changed the clock; where Case 03 is before Case 02 ends;
/// that an hour really vanished.
final Map<Difficulty, Map<String, Map<String, Object?>>> season2CasePatches = {
  // ── Rookie: the game's own words; only the glossary grows ──────────────
  Difficulty.rookie: {
    's2_ep01': {'glossary': _words01},
    's2_ep02': {'glossary': {..._words02, ..._rookieOnly02}},
    's2_ep03': {'glossary': {..._words03, ..._rookieOnly03}},
  },
  Difficulty.junior: {
    's2_ep01': _junior01,
    's2_ep02': _junior02,
    's2_ep03': _junior03,
  },
  Difficulty.master: {
    's2_ep01': _master01,
    's2_ep02': _master02,
    's2_ep03': _master03,
  },
};

/// The cases whose words are written at a level: nothing of theirs falls
/// back on another level's (`DifficultyContent.missingAt`, enforced by the
/// tests). Rookie: reviewed (the game's own words are Rookie's).
const Map<String, Set<Difficulty>> season2WrittenLevels = {
  's2_ep01': {Difficulty.rookie, Difficulty.junior, Difficulty.master},
  's2_ep02': {Difficulty.rookie, Difficulty.junior, Difficulty.master},
  's2_ep03': {Difficulty.rookie, Difficulty.junior, Difficulty.master},
};

// ═════════════════════════════════════════════════════════════════════════
// The glossary: words of the game's own pages a child may not know, found
// on every level's pages (and on Rookie's only, below).
// ═════════════════════════════════════════════════════════════════════════

const _words01 = {
  'events': '일어난 일들',
  'order': '순서',
  'pocket': '주머니',
  'hands': '(시계) 바늘',
  'heavy': '무거운',
};

const _words02 = {
  'pinned': '핀으로 꽂힌',
  'tucked': '끼워 넣은',
  'narrow': '좁은',
  'square': '광장',
  'uncovered': '드러난, 덮개를 벗긴',
  'atelier': '작업실 (프랑스어)',
  'toujours': '항상 (프랑스어)',
};

/// "in the same hand" (Rookie's page; Junior and Master say handwriting).
const _rookieOnly02 = {'hand': '손; (in the same hand) 같은 사람의 글씨로', ..._alike};

/// "They look alike" (Rookie's and Junior's pages; Master's are identical).
const _alike = {'alike': '비슷한'};

const _words03 = {
  'apart': '(시간이) 떨어진, 차이가 나는',
  'agree': '일치하다',
  'holder': '꽂이, 거치대',
  'staff': '직원',
  'plaque': '명판',
  'recording': '기록하는',
  'piece': '한 개, 조각',
  'pieces': '여러 개, 조각들',
  'wheels': '바퀴들',
  'locked': '잠긴',
};

const _rookieOnly03 = {'describe': '설명하다'};

// ═════════════════════════════════════════════════════════════════════════
// Case 01 — The Ticking Watch
// ═════════════════════════════════════════════════════════════════════════

/// The station notice, as it hangs in the hall (the same at every level:
/// it is the station's own sign, and its evidence).
const _notice =
    'STATION NOTICE\n\n'
    'All our clocks show Paris time.\n'
    'If one clock is ONE HOUR BEHIND,\n'
    'report it to the LOST PROPERTY DESK.\n\n';

/// The clerk's notes, as she wrote them (not in order).
const _clerkLines =
    'AFTER THAT, the old clock showed nine.\n'
    'FIRST, the hall clock struck ten.\n'
    'NEXT, a man with a pocket watch came in.\n\n';

const _junior01 = <String, Object?>{
  'synopsis': [
    'The clocks at Gare du Nord do not agree.',
    'One of them is running an hour behind. Who changed it, and why?',
    'This is where the missing hour begins.',
  ],
  'objectives': [
    'Find the clock that is running behind.',
    'Work out what happened, and in what order.',
    'Open what the old clock is hiding.',
  ],
  // The prologue has told that the watch is still ticking: the case begins
  // at the station, the watch in the detective's pocket.
  'intro': [
    'Paris. Gare du Nord.',
    "You step off the train with the Clockmaker's watch in your pocket.",
    'High above the platforms, three clocks are ticking.',
    'But they do not show the same time.',
  ],
  'caseSummary': "You found the clock that was running behind, put the events in order and opened the Clockmaker's box.",
  'hook': 'Inside the box is a painting of Montmartre. On the back, three words: FIND THE PAINTER.',
  'glossary': {
    ..._words01,
    'agree': '일치하다, 같다',
    'running': '(시계가) 가고 있는',
    'step': '내리다, 걷다',
    'travellers': '여행자들',
    'compare': '비교하다',
    'disagrees': '다르다, 일치하지 않다',
    'remembered': '기억했다',
    'between': '사이에',
    'sure': '확실한',
    'fix': '고치다',
    'leave': '그대로 두다',
    'fill': '채우다',
    'slides': '미끄러져 나오다',
    'opens': '열리다',
  },
  'missions': {
    's2_ep01_m1': {
      // PART 5 sample, kept: story, question, hints and success line.
      'story': [
        'The station hall is full of busy travellers.',
        'High under the glass roof, three clocks keep ticking.',
      ],
      'letterIntro': 'A notice hangs next to the departure board.',
      'letter':
          '${_notice}YOUR NOTES\n'
          'The hall clock says 10:00.\n'
          'The platform clock says 10:00.\n'
          'The old clock says 9:00.',
      'question': 'Which clock is running one hour behind?',
      'options': {
        'a': {'feedback': 'The hall clock shows 10:00, the same as the platform clock. Look for the one that disagrees.'},
        'b': {'feedback': 'The platform clock shows 10:00, the same as the hall clock. Look for the one that disagrees.'},
      },
      'hints': [
        'Compare the three clocks. Two of them agree with each other.',
        'One hour behind means one hour less than the others. Which clock shows 9:00?',
      ],
      'successMessage': 'The old clock is running one hour behind!',
      'transition': [
        'The old clock says nine. The other two say ten.',
        'Someone has scratched a letter on its glass: T.',
        'Next stop: the Lost Property desk.',
      ],
      'clue': {'note': 'The old clock is running one hour behind. Scratched on its glass: T.'},
      'evidence': {'description': 'It hangs next to the departure board in the station hall.'},
    },
    's2_ep01_m2': {
      'story': [
        'The clerk at the desk holds up a train ticket.',
        'Someone dropped it under the old clock this morning.',
      ],
      'letterIntro': 'She hands you the ticket and her notes.',
      'letter':
          "CLERK'S NOTES\n\n"
          '$_clerkLines'
          'I wrote them down as I remembered them.\n'
          '— Lost Property, Gare du Nord',
      'question': 'In what order did these things happen?',
      'orderFeedback': 'Look at the notes again. Which came FIRST, which came NEXT, and which came AFTER THAT?',
      'feedback': {
        'c,b,a': 'The man came in NEXT, not first. What happened FIRST?',
        'b,a,c': 'The old clock changed AFTER THAT, at the very end. So what came NEXT?',
      },
      'hints': [
        'Look for the order words: FIRST, NEXT and AFTER THAT. Each one starts a line.',
        'Start with FIRST and finish with AFTER THAT. The NEXT line goes in between.',
      ],
      'successMessage': 'You put the events in the right order!',
      // The order as the notes give it, never more: whether the man changed
      // the clock is still a question.
      'transition': [
        'FIRST, the hall clock struck ten.',
        'NEXT, a man with a pocket watch came in.',
        'AFTER THAT, the old clock showed nine.',
        'Did the man change the old clock? You cannot be sure yet.',
        'On the back of the ticket, there is a small letter: I.',
      ],
      'clue': {'note': 'The man came in before the old clock went back an hour. On the back of the ticket: I.'},
      'evidence': {'description': 'Someone dropped it under the old clock this morning.'},
    },
    's2_ep01_m3': {
      'story': [
        'You climb the iron steps up to the old clock.',
        'Someone has carved a message into its brass frame.',
      ],
      'letterIntro': 'The carving reads:',
      'letter':
          'This clock is one hour behind.\n'
          'Move its hands FORWARD one hour\n'
          'so it matches the hall clock.\n\n'
          'Below the words: a tiny carved gear.',
      'question': 'What should the old clock show? Set its hands.',
      'feedback': {
        '900': 'That is the time it shows now. Move the hands FORWARD.',
        '800': 'That moves it one hour BACK. FORWARD means later.',
        '1100': 'That is two hours forward. The carving says ONE hour.',
      },
      'hints': [
        'The old clock shows 9:00 now. FORWARD one hour means one hour later.',
        'Move the short hand to the next number. Leave the long hand on 12.',
      ],
      'successMessage': "The old clock shows ten o'clock again!",
      'transition': [
        'Ding, ding! The old clock chimes ten.',
        'Click! A small brass box slides out from under it.',
        'Its lock has four slots for letters. One letter is carved on the box: E.',
      ],
      'clue': {'note': 'The old clock shows ten again. Behind a little door: M.'},
      'evidence': {'description': 'Carved into the frame of the old clock.'},
    },
    's2_ep01_final': {
      'story': [
        'The brass box is small but heavy.',
        'Something inside it is ticking.',
      ],
      'letterIntro': 'You open your notebook:',
      'letter':
          'LETTERS FOUND\n\n'
          'T — scratched on the old clock\n'
          'I — on the back of the lost ticket\n'
          "M — behind the Clockmaker's mark\n"
          'E — carved on the box\n\n'
          'The Clockmaker loves one thing most.\n'
          'He steals it. He hides it.',
      'question': 'Which word opens the box? Put the four letters in order.',
      'orderFeedback': 'The letters are right, but the order is not. What does every clock show?',
      'feedback': {
        'ITEM': 'ITEM is a real word, but it is not the one. What does a clock show?',
        'EMIT': 'EMIT is a real word, but it is not the one. What does a clock show?',
        'MITE': 'MITE is a real word, but it is not the one. What does a clock show?',
      },
      // "The Clockmaker steals an hour." stays as it is (the story bible: the
      // player's first reading of the case).
      'hints': [
        'The Clockmaker steals an hour. Which word means hours and minutes?',
        'Clocks show the T _ _ E. Fill in the two letters in the middle.',
      ],
      'successMessage': 'Click! The box opens!',
      'transition': [
        'The lid opens. Inside is a small painting.',
        'It shows Montmartre: a white church on a hill,\nabove the roofs of Paris.',
        'The same white church is on the lost ticket.',
        'On the back, someone has written three words:',
        'FIND THE PAINTER.',
      ],
      'evidence': {'description': 'Found inside the hidden box.'},
    },
  },
};

const _master01 = <String, Object?>{
  'synopsis': [
    'The clocks of Gare du Nord refuse to agree.',
    'One has slipped an hour behind the rest. Who turned it back, and why?',
    'Here, the mystery of the missing hour begins.',
  ],
  'objectives': [
    'Find the clock that has fallen behind.',
    'Piece together what happened, and when.',
    'Discover what the old clock is hiding.',
  ],
  'intro': [
    'Paris. Gare du Nord.',
    "The Clockmaker's watch rests in your pocket as you step onto the platform.",
    'High above the trains, three clocks are ticking.',
    'Yet no two of them seem to share the same time.',
  ],
  'caseSummary': "You exposed the clock that had fallen behind, pieced the events together and opened the Clockmaker's box.",
  'hook': 'Inside the box lies a painting of Montmartre. On its back, a command: FIND THE PAINTER.',
  'glossary': {
    ..._words01,
    'refuse': '거부하다',
    'slipped': '(조금씩) 뒤처졌다',
    'fallen': '(behind) 뒤처진',
    'piece': '(together) 맞추다, 짜 맞추다',
    'pieced': '짜 맞췄다',
    'discover': '알아내다, 발견하다',
    'rests': '놓여 있다',
    'share': '같이 가지다, 공유하다',
    'seem': '~처럼 보이다',
    'exposed': '드러냈다, 밝혀냈다',
    'command': '명령',
    'hums': '웅성거리다',
    'hurrying': '서두르는',
    'beneath': '~아래에',
    'reads': '(시계가) 가리키다, ~라고 쓰여 있다',
    'exactly': '정확히',
    'odd': '(one out) 혼자 다른 것',
    'elsewhere': '다른 곳에',
    'printed': '인쇄된',
    'crumpled': '구겨진',
    'hurried': '서둘러 쓴',
    'hurry': '서두름',
    'arrange': '배열하다, 정리하다',
    'arrived': '도착했다',
    'proves': '증명하다',
    'gap': '빈칸, 틈',
    'remaining': '남은',
    'agrees': '일치하다',
    'travel': '움직이다, 이동하다',
    'single': '하나의',
    'lid': '뚜껑',
    'velvet': '벨벳 천',
    'surprisingly': '놀랍게도',
    'measures': '재다, 측정하다',
    'springs': '튀어 오르다',
  },
  'missions': {
    's2_ep01_m1': {
      // PART 5 sample, kept: story, question, hints and success line.
      'story': [
        'The station hall hums with hurrying travellers.',
        'High beneath the glass roof, three clocks tick away. But do they all agree?',
      ],
      'letterIntro': 'Beside the departure board hangs a printed notice.',
      'letter':
          '${_notice}YOUR NOTES\n'
          'The great hall clock reads 10:00.\n'
          'The platform clock reads 10:00.\n'
          'The old brass clock reads 9:00.',
      'question': 'Which clock has fallen one hour behind the others?',
      'options': {
        'a': {'feedback': 'The hall clock reads 10:00, exactly like the platform clock. The odd one out must be elsewhere.'},
        'b': {'feedback': 'The platform clock reads 10:00, exactly like the hall clock. The odd one out must be elsewhere.'},
      },
      'hints': [
        'Two of the clocks tell the same story. Which one disagrees?',
        'A clock one hour behind shows an hour less. Your notes hold the odd time out.',
      ],
      'successMessage': 'The old clock has fallen one hour behind!',
      'transition': [
        'The old clock reads nine, while the others read ten.',
        'Someone has scratched a single letter into its glass: T.',
        'The notice is clear. The Lost Property desk is next.',
      ],
      'clue': {'note': 'The old clock has fallen one hour behind. Scratched into its glass: T.'},
      'evidence': {'description': 'A printed notice beside the departure board, easy to walk past.'},
    },
    's2_ep01_m2': {
      'story': [
        'Behind the Lost Property desk, the clerk holds up a crumpled train ticket.',
        'It was found under the old clock early this morning.',
      ],
      'letterIntro': 'She passes you the ticket, along with her hurried notes.',
      'letter':
          "CLERK'S NOTES\n\n"
          '$_clerkLines'
          '(Written in a hurry, not in order.)\n'
          '— Lost Property, Gare du Nord',
      'question': 'Arrange the events in the order they happened.',
      'orderFeedback': 'The cards are right, but the order is not. Let FIRST, NEXT and AFTER THAT guide you.',
      'feedback': {
        'c,b,a': 'The man arrived NEXT. Something else came FIRST.',
        'b,a,c': 'The old clock changed AFTER THAT, at the very end. What happened in between?',
      },
      'hints': [
        'The clerk wrote in a hurry. Her order words matter more than the order of her lines.',
        'One line begins the story and one ends it. The remaining card fills the gap.',
      ],
      'successMessage': 'The events fall into place!',
      'transition': [
        'FIRST, the hall clock struck ten.',
        'NEXT, a man with a pocket watch came in.',
        'AFTER THAT, the old clock showed nine.',
        'Did the man turn the old clock back? Nothing proves it yet.',
        'On the back of the ticket, a small letter is written: I.',
      ],
      'clue': {'note': 'The man arrived before the old clock went back an hour. On the back of the ticket: I.'},
      'evidence': {'description': 'Found under the old clock early this morning.'},
    },
    's2_ep01_m3': {
      'story': [
        'You climb the narrow iron steps up to the old clock.',
        'Carved into its brass frame, a message is waiting.',
      ],
      'letterIntro': 'The carved words read:',
      'letter':
          'This clock has fallen one hour behind.\n'
          'Turn its hands FORWARD by one hour\n'
          'until it agrees with the hall clock.\n\n'
          'Beneath the words: a tiny carved gear.',
      'question': 'Set the old clock to the time the carving asks for.',
      'feedback': {
        '900': 'The clock already shows that. The carving says FORWARD.',
        '800': 'That turns it BACK an hour. FORWARD means later, not earlier.',
        '1100': 'Two hours is too far. The carving asks for just ONE.',
      },
      'hints': [
        'Where does the old clock stand now? FORWARD always means later.',
        'Only the short hand needs to travel, one number on. The long hand stays at the top.',
      ],
      'successMessage': 'The old clock is back at ten!',
      'transition': [
        'The old clock chimes ten, loud and clear.',
        'With a soft click, a small brass box slides out from beneath it.',
        'Its lock has four letter slots. A single letter is carved into the lid: E.',
      ],
      'clue': {'note': 'Put right, the old clock opened a little door. Inside: M.'},
      'evidence': {'description': 'Carved into the brass frame of the old clock.'},
    },
    's2_ep01_final': {
      'story': [
        'The brass box is small, but surprisingly heavy.',
        'From somewhere inside, something is ticking.',
      ],
      'letterIntro': 'Your notebook reads:',
      'letter':
          'LETTERS FOUND\n\n'
          "T — scratched into the old clock's glass\n"
          'I — on the back of the lost ticket\n'
          "M — behind the Clockmaker's mark\n"
          'E — carved into the box\n\n'
          'The Clockmaker loves one thing most.\n'
          'He steals it. He hides it.',
      'question': 'Arrange the four letters into the word that opens the box.',
      'orderFeedback': 'The right letters in the wrong order. What does every clock measure?',
      'feedback': {
        'ITEM': 'ITEM is a real word, but not the right one. Think of what a clock measures.',
        'EMIT': 'EMIT is a real word, but not the right one. Think of what a clock measures.',
        'MITE': 'MITE is a real word, but not the right one. Think of what a clock measures.',
      },
      'hints': [
        'The Clockmaker steals an hour. What do hours and minutes add up to?',
        'Every clock measures it. It begins with T and ends with E.',
      ],
      'successMessage': 'With a click, the lid springs open!',
      'transition': [
        'The lid lifts. On red velvet lies a small painting.',
        'Montmartre: a white church on a hill,\nhigh above the roofs of Paris.',
        'The same white church is on the lost ticket.',
        'Turned over, it carries three words:',
        'FIND THE PAINTER.',
      ],
      'evidence': {'description': 'Found on red velvet inside the hidden box.'},
    },
  },
};

// ═════════════════════════════════════════════════════════════════════════
// Case 02 — The Vanishing Painter
// ═════════════════════════════════════════════════════════════════════════

/// The painter's three notes, their headings as he wrote them (the same at
/// every level: the matching is read from them).
const _rain = 'A — I painted this BEFORE THE RAIN.\n';
const _after = 'B — I painted this AFTER THE RAIN STOPPED.\n';
const _gold = 'C — I painted this WHEN THE SKY TURNED GOLD.\n';

/// The note on the easel: what to slide and what to look under.
const _sketchNote =
    'I painted over my sketch.\n'
    'Slide the paint away\n'
    'and look UNDERNEATH.\n\n';

/// What the notebook keeps of the three clues (their evidence's names).
const _yourClues =
    'YOUR CLUES\n\n'
    'THE PAINTED STREET\n'
    'Not the street with the red door.\n\n'
    "THE ARTIST'S NOTES\n"
    'I hid my secret on a blue-sky day.\n\n'
    'THE HIDDEN SKETCH\n'
    'Steps, a lamp and a black gate.\n\n';

/// After the case: his studio, his words and what the evidence says of
/// him, in that order. The line Case 03 begins from (TOUJOURS PLUS HAUT),
/// his own words and the case's last line stay as they are.
List<String> _painterGone({
  required String below,
  required String brassBox,
  String found = 'He hid his own sketch. He left his notes for you.',
  String onHisOwn = 'He left on his own.',
}) => [
      'On the back: ATELIER MONTMARTRE, his studio.',
      'And three French words: TOUJOURS PLUS HAUT. Always higher.',
      below,
      'A city can lose an hour.\nBut who can steal it?',
      '"I saw who took the hour. I went away to keep the secret safe. — P."',
      found,
      brassBox,
      onHisOwn,
      'But someone is still stealing the hours of Paris.',
    ];

final _junior02 = <String, Object?>{
  'synopsis': [
    'The painting from the brass box shows Montmartre.',
    'On the back, someone wrote: FIND THE PAINTER.',
    'But the painter has disappeared. Does he know who took the hour?',
  ],
  'objectives': [
    'Find the street from the painting.',
    "Search the painter's studio for clues.",
    'Find the message he left behind.',
  ],
  'intro': [
    'Montmartre, a hill high above Paris.',
    'The lost ticket said MONTMARTRE, and the painting shows this hill.',
    'On its back: FIND THE PAINTER.',
    'Who is he? And why was his painting hidden under an old clock?',
  ],
  'caseSummary': "You followed three of the painter's clues to his hidden message.",
  'hook': 'Nobody took the painter. He went away to keep a secret. But who took the hour?',
  'glossary': {
    ..._words02,
    ..._alike,
    'disappeared': '사라졌다',
    'exactly': '정확히',
    'followed': '따라갔다',
    'empty': '비어 있는',
    'trunk': '큰 상자, 트렁크',
    'drawer': '서랍',
    'crate': '나무 상자',
    'smock': '작업복',
    'palette': '팔레트',
    'appears': '나타나다',
    'handwriting': '손글씨, 필체',
    'row': '줄',
  },
  'missions': {
    's2_ep02_m1': {
      'story': [
        'Near the white church is a quiet street with a red door, stone steps and an old lamp.',
        'On the corner stands an easel with a painting of this street. But nobody is painting.',
      ],
      'letterIntro': 'Someone has pinned a note to the painting:',
      'letter':
          'I did not paint this street exactly as it is.\n'
          'I changed three things.\n\n'
          'Look above the red door.\n'
          'Find the window that is missing.\n'
          'Check the lamp beside the steps.\n\n'
          '— P.',
      'question': 'Find the three things he changed.',
      'hints': [
        'Each line of the note tells you where to look. Read them one by one.',
        'ABOVE means higher up. MISSING means it is not there. BESIDE means right next to.',
      ],
      'successMessage': 'You found all three changes!',
      'transition': [
        'You turn his note over. There is one more line:',
        '"My secret is not on this street. Look far from the red door."',
        'You find a key under the easel. Its tag says: STUDIO, TOP FLOOR.',
      ],
      'clue': {'note': 'On the back of his note: "My secret is not on this street. Look far from the red door."'},
      'evidence': {'description': 'Left on the easel at the corner of the street.'},
    },
    's2_ep02_m2': {
      'story': [
        'The key opens a door at the top of some narrow stairs.',
        'Sunlight. The smell of paint. But the studio is empty.',
      ],
      'letterIntro': 'There are three notes on his desk:',
      'letter':
          '${_rain}Dark clouds were coming, but the stones were still dry.\n\n'
          '${_after}The stones were wet and shiny. A few dark clouds were still in the sky.\n\n'
          '${_gold}The whole sky was gold, with no dark clouds. The stones were dry.',
      'question': 'Which painting goes with each note? Match them.',
      'feedback': {
        'a:p1': 'Look at note A again. Can you see the dark clouds in this painting?',
        'a:p3': 'Look at note A again. BEFORE THE RAIN, the stones were still dry.',
        'b:p1': 'Look at note B again. AFTER THE RAIN, the stones are wet and shiny.',
        'b:p2': 'Look at note B again. AFTER THE RAIN, the stones are wet and shiny.',
        'c:p2': 'Look at note C again. Is the whole sky gold here?',
        'c:p3': 'Look at note C again. There are no dark clouds, and the stones are dry.',
      },
      'hints': [
        'Each note says WHEN he painted it. Look at the clouds and the stones in each painting.',
        'BEFORE THE RAIN: dry stones. AFTER THE RAIN: wet, shiny stones. Which one has a gold sky and no clouds?',
      ],
      'successMessage': 'Each note has its painting!',
      'transition': [
        'Under note C, there is one more line in pencil:',
        '"My secret is not in a gold sky. I hid it on a blue-sky day."',
        'By the window, a big easel holds a canvas covered in thick paint.',
      ],
      'clue': {'note': 'Written under note C: "My secret is not in a gold sky. I hid it on a blue-sky day."'},
      'evidence': {'description': 'Found on his desk, next to his paintings of one square.'},
    },
    's2_ep02_m3': {
      'story': [
        'The canvas is covered in thick paint: blue, red and yellow. There is no picture at all.',
        'Why would a painter do that?',
      ],
      'letterIntro': 'Someone has tucked a note into the frame:',
      'letter':
          '$_sketchNote'
          'My pencil has no colours,\n'
          'so remember this: the gate is black.\n\n'
          '— P.',
      'question': 'Find the lamp, the steps and the gate in the sketch.',
      'hints': [
        'First, slide the paint away. The sketch is hidden underneath.',
        'The lamp is tall and thin. The steps are at the bottom. The gate stands between two pillars.',
      ],
      'successMessage': 'You uncovered the sketch!',
      // The three questions after a find, as at every level.
      'transition': [
        'What changed? The painter covered his own sketch with paint.',
        'What was hidden? A place with stone steps, an old lamp and a black gate.',
        'Why does it matter? The painter hid it himself, on purpose.',
        'Against the wall, four canvases are standing in a row.',
      ],
      'clue': {'note': 'Under the paint: stone steps, an old lamp and an iron gate. The note says the gate is black.'},
      'evidence': {'description': 'Found under the thick paint on his big easel.'},
    },
    's2_ep02_final': {
      'story': [
        'Four canvases lean against the wall. They look very alike.',
        'Only one of them has a message on the back.',
      ],
      'letterIntro': 'You check your notebook:',
      'letter': '${_yourClues}Only one canvas matches all three clues.',
      'question': 'Which canvas has the message on its back?',
      'options': {
        'a': {'feedback': 'Check the clue from the painted street. Does this canvas have a red door?'},
        'b': {'feedback': "Check the artist's notes. Is this sky blue?"},
        'd': {'feedback': 'Check the hidden sketch. What colour should the gate be?'},
      },
      'hints': [
        'Check each canvas against all three clues, one by one.',
        'You need: no red door, a blue sky, and a black gate beside the steps.',
      ],
      'successMessage': 'That is the right canvas!',
      'transition': _painterGone(
        below: 'Below, in the same handwriting as FIND THE PAINTER:',
        brassBox: 'Did he also leave his painting in the brass box for you?',
      ),
      'evidence': {'description': 'Written on the back of his canvas. His note says: "I saw who took the hour."'},
    },
  },
};

final _master02 = <String, Object?>{
  'synopsis': [
    'The painting from the brass box shows Montmartre.',
    'On its back, a command: FIND THE PAINTER.',
    'Yet the painter has vanished. Could he know who took the hour?',
  ],
  'objectives': [
    'Track down the street in the painting.',
    "Search the painter's deserted studio.",
    'Uncover the message he left behind.',
  ],
  'intro': [
    'Montmartre: a hill of narrow streets, high above Paris.',
    'The lost ticket read MONTMARTRE, and the painting shows this very hill.',
    'On its back: FIND THE PAINTER.',
    'But who is he? And why was his painting waiting beneath an old clock?',
  ],
  'caseSummary': "Three of the painter's clues, read together, led you to his hidden message.",
  'hook': 'Nobody took the painter. He slipped away to keep a secret safe. But who took the hour?',
  'glossary': {
    ..._words02,
    'command': '명령',
    'track': '(down) 찾아내다',
    'deserted': '텅 빈, 버려진',
    'uncover': '드러내다, 밝혀내다',
    'beneath': '~아래에',
    'slipped': '(away) 몰래 떠났다',
    'worn': '닳은',
    'nowhere': '어디에도 없는',
    'truly': '정말로',
    'seek': '찾다',
    'map': '지도',
    'points': '가리키다',
    'compare': '비교하다',
    'creaking': '삐걱거리는',
    'staircase': '계단',
    'pours': '쏟아져 들어오다',
    'side': '(by side) 나란히',
    'gathering': '모여들고 있었다',
    'yet': '그런데도, 아직',
    'gleamed': '반짝였다',
    'lingered': '남아 있었다',
    'glowed': '빛났다',
    'single': '단 하나의',
    'pair': '짝짓다',
    'describes': '묘사하다',
    'mentions': '언급하다',
    'fool': '속이다',
    'signs': '표시, 단서',
    'smothered': '두껍게 뒤덮인',
    'smothers': '두껍게 뒤덮다',
    'bury': '묻다, 덮어 감추다',
    'buried': '덮어 감췄다',
    'whatever': '무엇이든',
    'clear': '치우다',
    'search': '찾아보다',
    'climb': '오르다',
    'revealed': '드러난',
    'insists': '강조하다, 우기다',
    'identical': '똑같은',
    'glance': '흘끗 봄',
    'carries': '지니다, 가지고 있다',
    'fits': '맞다, 들어맞다',
    'rules': '(out) 제외하다',
    'fails': '맞지 않다, 실패하다',
    'survives': '끝까지 남다',
    'labelled': '이름표가 붙은',
    'spattered': '튀어 묻은',
    'dried': '말랐다',
    'strokes': '붓질',
    'elegant': '우아한',
    'climbing': '올라가는',
    'aside': '옆으로',
    'handwriting': '손글씨, 필체',
    'deliberately': '일부러, 고의로',
  },
  'missions': {
    's2_ep02_m1': {
      'story': [
        'Close to the white church lies a quiet street: a red door, worn stone steps, an old lamp.',
        'At the corner, an easel holds a painting of this very street. The painter is nowhere to be seen.',
      ],
      'letterIntro': 'A note is pinned to the corner of the painting:',
      'letter':
          'I did not paint this street as it truly is.\n'
          'Three things are different.\n\n'
          'Look above the red door.\n'
          'Seek out the window that has gone missing.\n'
          'Check the lamp beside the steps.\n\n'
          '— P.',
      'question': 'Spot the three changes the painter made.',
      'hints': [
        'The note is a map: each line points to one place. Compare that place on the street and in the painting.',
        'What sits ABOVE the door? What has gone MISSING? What looks different BESIDE the steps?',
      ],
      'successMessage': 'All three changes uncovered!',
      'transition': [
        'You turn his note over. One more line is written on the back:',
        '"My secret is not on this street. Look far from the red door."',
        'Beneath the easel lies a key. Its tag reads: STUDIO, TOP FLOOR.',
      ],
      'clue': {'note': 'Written on the back of his note: "My secret is not on this street. Look far from the red door."'},
      'evidence': {'description': 'Left behind on the easel at the corner of the street.'},
    },
    's2_ep02_m2': {
      'story': [
        'The key turns in a door at the top of a narrow, creaking staircase.',
        'Sunlight pours in. The air smells of paint. The studio is deserted.',
      ],
      'letterIntro': 'Three notes lie side by side on his desk:',
      'letter':
          '${_rain}Dark clouds were gathering, yet the stones were still dry.\n\n'
          '${_after}The stones gleamed, wet and shiny, and a few dark clouds still lingered.\n\n'
          '${_gold}The whole sky glowed gold, without a single dark cloud. The stones were dry.',
      'question': 'Pair each note with the painting it describes.',
      'feedback': {
        'a:p1': 'Note A mentions dark clouds. Do you see any here?',
        'a:p3': 'Note A was painted BEFORE THE RAIN. The stones should still be dry.',
        'b:p1': 'Note B comes AFTER THE RAIN. Look for stones that are wet and shiny.',
        'b:p2': 'Note B comes AFTER THE RAIN. Look for stones that are wet and shiny.',
        'c:p2': 'Note C describes a whole sky of gold. Is that what you see?',
        'c:p3': 'Note C has no dark clouds and dry stones. Look again.',
      },
      'hints': [
        'The sky alone can fool you. Each note gives two signs: the clouds and the stones.',
        'Wet, shiny stones can only come AFTER the rain. Which painting has dark clouds over dry stones?',
      ],
      'successMessage': 'Every note is matched to its painting!',
      'transition': [
        'Beneath note C, a final line in pencil:',
        '"My secret is not in a gold sky. I hid it on a blue-sky day."',
        'By the window, a big easel holds a canvas smothered in thick paint.',
      ],
      'clue': {'note': 'Pencilled under note C: "My secret is not in a gold sky. I hid it on a blue-sky day."'},
      'evidence': {'description': 'Lying on his desk, beside his paintings of one square.'},
    },
    's2_ep02_m3': {
      'story': [
        'Thick paint smothers the canvas: blue, red, yellow, and no picture at all.',
        'Why would a painter bury his own work?',
      ],
      'letterIntro': 'A note is tucked into the edge of the frame:',
      'letter':
          '$_sketchNote'
          'My pencil knows no colours,\n'
          'so remember: the gate is black.\n\n'
          '— P.',
      'question': 'Uncover the sketch, then find its lamp, its steps and its gate.',
      'hints': [
        'Whatever he hid lies beneath the paint. Clear it away first.',
        'Search high for something tall, low for something you climb, and between two pillars for the last.',
      ],
      'successMessage': 'The hidden sketch is revealed!',
      'transition': [
        'What changed? The painter buried his own sketch under paint.',
        'What was hidden? A place of stone steps, an old lamp and a black gate.',
        'Why does it matter? He hid it himself, deliberately.',
        'Against the wall, four canvases stand waiting.',
      ],
      'clue': {'note': 'Beneath the paint: stone steps, an old lamp and an iron gate. His note insists the gate is black.'},
      'evidence': {'description': 'Uncovered beneath the thick paint on his big easel.'},
    },
    's2_ep02_final': {
      'story': [
        'Four canvases lean against the wall, almost identical at first glance.',
        'Only one carries a message on its back.',
      ],
      'letterIntro': 'Your notebook reads:',
      'letter': '${_yourClues}Only one canvas fits every clue.',
      'question': 'Which canvas is hiding the message?',
      'options': {
        'a': {'feedback': 'Remember the painted street. A red door rules this one out.'},
        'b': {'feedback': "Remember the artist's notes. Is this the sky of a blue-sky day?"},
        'd': {'feedback': 'Remember the hidden sketch. His pencil had no colours, but his note told you the colour of the gate.'},
      },
      'hints': [
        'No single clue is enough. Test every canvas against all three.',
        'One canvas fails the street clue, one fails the sky and one fails the gate. Which one survives?',
      ],
      'successMessage': 'The right canvas at last!',
      'transition': _painterGone(
        below: 'Below it, in the same handwriting as FIND THE PAINTER:',
        found: 'He hid his own sketch, and left his notes for you to find.',
        brassBox: 'Was it he who left his painting in the brass box for you, too?',
        onHisOwn: 'Nobody took him. He left on his own.',
      ),
      'evidence': {'description': 'Written on the back of his canvas, beside his note: "I saw who took the hour."'},
    },
  },
};

// ═════════════════════════════════════════════════════════════════════════
// Case 03 — The Tower's Secret
// ═════════════════════════════════════════════════════════════════════════

/// The inspection note at the iron door, as pinned (not in order).
const _steps =
    'INSPECTION STEPS\n\n'
    'Finally, turn the key.\n'
    'First, check the clock.\n'
    'Next, stop the lift.';

/// The two time cards.
const _cards =
    'OFFICIAL TIME — 4:00\n'
    'RECORDED TIME — 3:00\n\n';

/// The evidence board's lines for each wrong link (the keys are the
/// answers, as the base has them), written per level.
Map<String, String> _boardLines({
  required String records,
  required String onlyRecords,
  required String trips,
  required String onlyTrips,
  required String twoPieces,
  required String notThere,
  required String door,
  required String why,
  required String still,
}) => {
      for (final s in ['', 'e2', 'e3', 'e2+e3']) 'q1:$s': records,
      for (final s in ['e1+e2', 'e1+e3', 'e1+e2+e3']) 'q1:$s': onlyRecords,
      for (final s in ['', 'e1', 'e3', 'e1+e3']) 'q2:$s': trips,
      for (final s in ['e1+e2', 'e2+e3', 'e1+e2+e3']) 'q2:$s': onlyTrips,
      'q3:': twoPieces,
      for (final s in ['e1', 'e1+e2', 'e1+e3', 'e1+e2+e3']) 'q3:$s': notThere,
      'q3:e2': door,
      // The room alone: the same question at every level.
      'q3:e3': 'You found the room. But what shows that someone went up there?',
      'why:': why,
      // No level says more than the evidence does.
      'why:vanished': 'We have no proof of that yet.',
      'why:still': still,
    };

/// The plaque, then the tag that sends the case to the river. Its riddle,
/// SEINE and the last two questions stay as they are.
List<String> _plaque({required String under, required String river, required String tag}) => [
      'One hour is missing.',
      'The clock is still running.',
      under,
      'SEINE.',
      river,
      tag,
      'FROM: SERVICE LEVEL. TO: THE RIVER.',
      'Who left this message?',
      'And why does it lead to the river?',
    ];

final _junior03 = <String, Object?>{
  'synopsis': [
    "The painter's last message said: ALWAYS HIGHER.",
    'Next to it, he drew a small picture of a tall iron tower.',
    'At the Eiffel Tower, two records do not agree.',
  ],
  'objectives': [
    'Compare the two records line by line.',
    'Find out where the lift went.',
    'Open the locked iron door.',
  ],
  // Second person; no time and no number of hours before the records are
  // read (as the game's own words).
  'intro': [
    'The painter left one last message: Always higher.',
    'You turn the canvas over again. Next to the words is a small drawing.',
    'It shows a tall iron tower: the Eiffel Tower.',
    'At its entrance, two records tell you about the same inspection. But they do not match.',
  ],
  'caseSummary': 'Two records were one hour apart. In that hour, someone went up to the Service Level.',
  'hook': 'Who left the plaque about the missing hour? And why does it point to the river?',
  'glossary': {
    ..._words03,
    'compare': '비교하다',
    'drew': '그렸다',
    'point': '가리키다',
    'written': '쓰인',
    'ride': '타다',
    'stands': '서 있다',
    'link': '연결하다',
    'answers': '답하다',
  },
  'missions': {
    's2_ep03_m1': {
      'story': [
        'At the foot of the tower, the lamps are coming on.',
        'By the gate is a notice for visitors. In the ticket booth is the maintenance log.',
      ],
      'letterIntro': 'You write in your notebook:',
      'letter':
          'Two records.\n'
          'The same day. The same job.\n\n'
          'Compare them line by line.\n'
          'Find the two lines that do not match.',
      'question': 'Which two lines do not match?',
      'feedback': {
        'date:date': 'Both records say 12 MAY. The dates are the same.',
        'job:job': 'Both records say LIFT INSPECTION. The jobs are the same.',
        for (final pair in ['date:job', 'date:time', 'job:date', 'job:time', 'time:date', 'time:job'])
          pair: 'Compare the same line on both records: date with date, time with time.',
      },
      'hints': [
        'Read each record one line at a time: the date, the job, the time.',
        'The date is the same on both. So is the job. Now look at the time.',
      ],
      'successMessage': 'The times on the two records do not match!',
      'transition': [
        'The visitor notice says 4:00, but the maintenance log says 3:00.',
        'Same day. Same job. But one hour apart.',
        'At the bottom of the log, someone has written in pencil: CHECK THE LIFT LOG.',
      ],
      'clue': {'note': 'At the bottom of the maintenance log, a pencil note: CHECK THE LIFT LOG.'},
      'evidence': {'description': 'Two records found at the entrance of the Eiffel Tower.'},
    },
    's2_ep03_m2': {
      'story': [
        'On one wall of the old lift is a brass route plate. On the other is the lift log.',
        "Where did the lift go after three o'clock?",
      ],
      'letterIntro': 'You check your notebook:',
      'letter':
          'CHECK THE LIFT LOG.\n\n'
          'Read every trip in the log.\n'
          'One stop is not written.\n'
          'The route plate shows every stop.',
      'question': 'At 3:20, where did the lift go?',
      'options': {
        'ground': {'feedback': 'At 4:25, the lift came back down to Ground. Where was it before that?'},
        'first': {'feedback': 'First is a stop for passengers. The 3:20 trip has an S next to it. What does S mean?'},
        'top': {'feedback': 'Top is a stop for passengers. The 3:20 trip has an S next to it. What does S mean?'},
      },
      'hints': [
        'Find the S in the lift log. Then look for S on the route plate.',
        'On the plate, S = SERVICE RUN. Which stop is only on the service route?',
      ],
      'successMessage': 'You found the stop that was missing from the log!',
      'transition': [
        'At 3:20, the lift went up to the Service Level. It did not come back down until 4:25.',
        'You ride the lift up. The gates open onto a dark iron platform.',
        'On an iron door, there is a sign: SERVICE ACCESS ONLY.',
      ],
      'clue': {'note': 'At the Service Level, there is a sign on an iron door: SERVICE ACCESS ONLY.'},
      'evidence': {'description': 'It hangs in a holder on the wall of the lift.'},
    },
    's2_ep03_m3': {
      'story': [
        'The Service Level is dark and quiet. Visitors never come up here.',
        'A heavy padlock with three dials keeps the iron door shut.',
      ],
      'letterIntro': 'Next to the door, someone has pinned a note:',
      'letter': _steps,
      'question': 'Set the three dials in the right order. Then open the lock.',
      'orderFeedback': 'The pictures are right, but the order is wrong. Read the note: FIRST, NEXT, FINALLY.',
      'hints': [
        'Read the note again. The words FIRST, NEXT and FINALLY tell you the order.',
        'Dial 1 is the step you do FIRST. Dial 2 is NEXT. Dial 3 is FINALLY.',
      ],
      'successMessage': 'The padlock is open!',
      'transition': [
        'Click! Behind the iron door is a small hidden room.',
        'There are wheels, cables and gears. At the back stands an old machine with a clock.',
        'On the floor is a square mark in the dust. A heavy crate stood here. Now it is gone.',
      ],
      'clue': {'note': 'Behind the iron door is a small machine room. Only the service staff can go in.'},
      'evidence': {'description': 'Found behind the locked iron door at the Service Level.'},
    },
    's2_ep03_final': {
      'story': [
        'The old machine has a slot for time cards. There are two cards inside.',
        'What really happened at the tower?',
      ],
      'letterIntro': 'You read the two time cards:',
      'letter':
          '${_cards}One hour apart, just like the two records\n'
          'at the entrance.',
      'question': 'Link each question to the evidence that answers it.',
      'feedback': _boardLines(
        records: 'Question 1 is about the inspection records. Which evidence shows those records?',
        onlyRecords: 'Question 1 needs just one piece: the two records.',
        trips: 'Which evidence shows where the lift went?',
        onlyTrips: 'Question 2 needs just one piece: the one that shows where the lift went.',
        twoPieces: 'Question 3 needs two pieces. Where did the lift go? And what was up there?',
        notThere: 'The notices were down at the entrance. Question 3 is about the service area.',
        door: 'The lift log shows where the lift went. What did you find behind the iron door?',
        why: 'Choose what the evidence really shows.',
        still: 'Look at the lift log again. The lift went up at 3:20.',
      ),
      'hints': [
        'Open each piece of evidence and ask: what does this one show?',
        'Question 3 needs two pieces: one shows where the lift went, one shows what was behind the door.',
      ],
      'successMessage': 'All the evidence fits together!',
      'transition': _plaque(
        under: 'Under the words are three small waves and one word.',
        river: 'It is the river that runs through Paris.',
        tag: 'Next to the square mark in the dust is a torn shipping tag:',
      ),
      'evidence': {'description': 'It was hidden inside the time-recording machine.'},
    },
  },
};

final _master03 = <String, Object?>{
  'synopsis': [
    "The painter's final message read: ALWAYS HIGHER.",
    'Beside it, he had sketched a tall iron tower.',
    'At the Eiffel Tower, two official records refuse to agree.',
  ],
  'objectives': [
    'Compare the two records closely.',
    "Trace the lift's secret journey.",
    'Get past the locked iron door.',
  ],
  'intro': [
    'The painter left one last message: Always higher.',
    'You turn the canvas over again. Beside the words, a small drawing catches your eye.',
    'A tall iron tower. The Eiffel Tower.',
    'At its entrance, two records describe the very same inspection, yet they disagree.',
  ],
  'caseSummary': 'Two records, one hour apart. In that hour, someone slipped up to the Service Level.',
  'hook': 'Who left the plaque about the missing hour, and why does it lead to the river?',
  'glossary': {
    ..._words03,
    ..._rookieOnly03,
    'final': '마지막의',
    'sketched': '스케치했다',
    'refuse': '거부하다',
    'closely': '자세히',
    'trace': '추적하다',
    'journey': '이동, 여정',
    'catches': '(your eye) 눈길을 끌다',
    'disagree': '일치하지 않다',
    'slipped': '몰래 들어갔다',
    'evening': '저녁',
    'flicker': '깜빡이다',
    'reminds': '상기시키다',
    'somewhere': '어딘가에서',
    'claims': '주장하다',
    'insists': '우기다, 강조하다',
    'scrawled': '휘갈겨 쓴',
    'gleams': '반짝이다',
    'hangs': '걸려 있다',
    'really': '실제로',
    'study': '살펴보다',
    'unwritten': '쓰이지 않은',
    'heading': '향하는',
    'returned': '돌아왔다',
    'single': '하나의',
    'climbed': '올라갔다',
    'bears': '(표시를) 달고 있다',
    'silent': '조용한',
    'guards': '지키다',
    'demands': '요구하다',
    'jumbled': '뒤죽박죽인',
    'purpose': '(on purpose) 일부러',
    'swings': '활짝 열리다',
    'crouches': '웅크리고 있다',
    'once': '예전에; ~하면',
    'meant': '~을 위한',
    'truly': '정말로',
    'connect': '연결하다',
    'concerns': '~에 관한 것이다',
    'holds': '담고 있다',
    'traces': '추적하다, 보여 주다',
    'prove': '증명하다',
    'proves': '증명하다',
    'waited': '기다리고 있었다',
    'examine': '살펴보다',
    'pair': '짝짓다',
    'destination': '목적지',
    'concealed': '숨겨진',
    'winds': '굽이굽이 흐르다',
    'alone': '~만으로',
    'enough': '충분한',
  },
  'missions': {
    's2_ep03_m1': {
      'story': [
        'At the foot of the tower, the evening lamps flicker on.',
        'By the gate hangs a notice for visitors. Inside the ticket booth lies the maintenance log.',
      ],
      'letterIntro': 'Your notebook reminds you:',
      'letter':
          'Two records.\n'
          'The same day. The same job.\n\n'
          'Somewhere, they disagree.\n'
          'Find the two lines that do not match.',
      'question': 'Where do the two records disagree?',
      'feedback': {
        'date:date': 'Both records give 12 MAY. No difference there.',
        'job:job': 'Both records name LIFT INSPECTION. No difference there.',
        for (final pair in ['date:job', 'date:time', 'job:date', 'job:time', 'time:date', 'time:job'])
          pair: 'Compare like with like: date with date, time with time.',
      },
      'hints': [
        'A careful detective reads every line on both records.',
        'Two of the three lines agree perfectly. The last one tells a different story.',
      ],
      'successMessage': 'The two records disagree on the time!',
      'transition': [
        'The visitor notice claims 4:00. The maintenance log insists on 3:00.',
        'Same day, same job, yet one hour apart.',
        'Scrawled in pencil at the bottom of the log: CHECK THE LIFT LOG.',
      ],
      'clue': {'note': 'Scrawled in pencil at the bottom of the maintenance log: CHECK THE LIFT LOG.'},
      'evidence': {'description': 'Two records from the entrance of the Eiffel Tower.'},
    },
    's2_ep03_m2': {
      'story': [
        'On one wall of the old lift gleams a brass route plate. On the other hangs the lift log.',
        "After three o'clock, where did the lift really go?",
      ],
      'letterIntro': 'Your notebook reads:',
      'letter':
          'CHECK THE LIFT LOG.\n\n'
          'Study every trip.\n'
          'One stop has been left unwritten.\n'
          'The route plate knows every stop.',
      'question': 'Where was the lift heading at 3:20?',
      'options': {
        'ground': {'feedback': 'The lift returned to Ground at 4:25. But where had it been until then?'},
        'first': {'feedback': 'First is a passenger stop. Yet the 3:20 trip carries an S. What could that mean?'},
        'top': {'feedback': 'Top is a passenger stop. Yet the 3:20 trip carries an S. What could that mean?'},
      },
      'hints': [
        'The log keeps a secret in a single letter. The route plate can explain it.',
        'Once you know that S = SERVICE RUN, ask which stop only a service run can reach.',
      ],
      'successMessage': 'The unwritten stop is found!',
      'transition': [
        'At 3:20, the lift climbed to the Service Level. It did not return to Ground until 4:25.',
        'You ride up. The brass gates slide open onto a dark iron platform.',
        'An iron door bears a sign: SERVICE ACCESS ONLY.',
      ],
      'clue': {'note': 'At the Service Level, an iron door bears a sign: SERVICE ACCESS ONLY.'},
      'evidence': {'description': 'Kept in a brass holder on the wall of the lift.'},
    },
    's2_ep03_m3': {
      'story': [
        'The Service Level is dark and silent. No visitor ever comes this far.',
        'A heavy padlock with three dials guards the iron door.',
      ],
      'letterIntro': 'Pinned beside the door is a note:',
      'letter': _steps,
      'question': 'Set the dials in the order the note demands, then open the lock.',
      'orderFeedback': "The right pictures, but in the wrong order. The note's FIRST, NEXT and FINALLY decide it.",
      'hints': [
        'The note is jumbled on purpose. Its order words matter more than the order of its lines.',
        'Each dial is one step. Let the first dial hold the step that comes FIRST.',
      ],
      'successMessage': 'The padlock gives way!',
      'transition': [
        'Click. The iron door swings open onto a small hidden room.',
        'Wheels, cables and gears fill the space. At the back crouches an old machine with a clock.',
        'On the floor, a square mark in the dust. A heavy crate once stood here. Now it is gone.',
      ],
      'clue': {'note': 'Behind the iron door: a small machine room, meant only for the service staff.'},
      'evidence': {'description': 'Hidden behind the locked iron door at the Service Level.'},
    },
    's2_ep03_final': {
      'story': [
        'The old machine has a slot for time cards. Two cards are still inside.',
        'So what truly happened at the tower?',
      ],
      'letterIntro': 'The two time cards read:',
      'letter':
          '${_cards}One hour apart, exactly like the two records\n'
          'at the entrance.',
      'question': 'Connect each question to the evidence that answers it.',
      'feedback': _boardLines(
        records: 'Question 1 concerns the inspection records. Which evidence holds them?',
        onlyRecords: 'For question 1, the two records alone are enough.',
        trips: "Which evidence traces the lift's trips?",
        onlyTrips: 'Question 2 needs only one piece: the record of where the lift went.',
        twoPieces: 'Question 3 needs two pieces. Where did the lift go, and what waited there?',
        notThere: 'The notices stayed down at the entrance. Question 3 concerns the service area.',
        door: 'The lift log proves where the lift went. But what was behind the door?',
        why: 'Choose only what the evidence can prove.',
        still: 'Check the lift log again. The lift went up at 3:20.',
      ),
      'hints': [
        'Examine each piece of evidence. Ask what it proves, and what it does not.',
        'One question cannot be answered by a single piece. Pair the journey with its destination.',
      ],
      'successMessage': 'Every piece of evidence falls into place!',
      'transition': _plaque(
        under: 'Beneath the words: three small waves, and a single word.',
        river: 'The river that winds through Paris.',
        tag: 'Beside the square mark in the dust lies a torn shipping tag:',
      ),
      'evidence': {'description': 'Concealed inside the time-recording machine.'},
    },
  },
};

// ═════════════════════════════════════════════════════════════════════════
// The scenes' own words
// ═════════════════════════════════════════════════════════════════════════

/// [base] with a level's words for what is round the hall and what it says
/// when nothing is there. Every way to play (the tasks, Tap…, Pinch…), the
/// clocks, the board, the notice and the desk are the base's.
StationClocksScene _hall(
  StationClocksScene base, {
  required List<String> others,
  required String missLine,
  required String boardFirstLine,
  required String clocksFirstLine,
}) =>
    StationClocksScene(
      picture: base.picture,
      pixels: base.pixels,
      place: base.place,
      task: base.task,
      boardTask: base.boardTask,
      reportTask: base.reportTask,
      clocks: base.clocks,
      board: base.board,
      desk: base.desk,
      others: [for (final (i, o) in base.others.indexed) InvestigationSpot(label: o.label, areas: o.areas, line: others[i])],
      missLine: missLine,
      boardTitle: base.boardTitle,
      departures: base.departures,
      noticeTitle: base.noticeTitle,
      notice: base.notice,
      noticeKeys: base.noticeKeys,
      boardFirstLine: boardFirstLine,
      clocksFirstLine: clocksFirstLine,
      reportHow: base.reportHow,
      guideAt: base.guideAt,
      inside: base.inside,
      opening: base.opening,
      tapGuide: base.tapGuide,
      zoomGuide: base.zoomGuide,
    );

/// The lost ticket, its printed words said as printed.
Exhibit _ticket(Exhibit base, {required String description, required String caption}) =>
    Exhibit(id: base.id, picture: base.picture, pixels: base.pixels, title: base.title, description: description, caption: caption);

/// The old clock's face: how to drag its hands is the base's.
ClockPuzzle _oldClock(ClockPuzzle base, {required String question, required String lead}) => ClockPuzzle(
      face: base.face,
      question: question,
      lead: lead,
      guide: base.guide,
      dialLabel: base.dialLabel,
      start: base.start,
      submitLabel: base.submitLabel,
    );

/// The street and its painting: [checklist] is the note's own lines.
CompareScene _street(CompareScene base, {required Map<String, String> found, required String missLine, Map<String, String>? checklist}) =>
    CompareScene(
      real: base.real,
      painted: base.painted,
      pixels: base.pixels,
      realLabel: base.realLabel,
      paintedLabel: base.paintedLabel,
      changes: base.changes,
      task: base.task,
      missLine: missLine,
      foundLines: {for (final id in base.foundLines.keys) id: found[id]!},
      checklist: {for (final id in base.checklist.keys) id: (checklist ?? base.checklist)[id]!},
      opening: base.opening,
    );

/// The studio: what each place says when it is searched. How to match is
/// the base's.
StudioScene _studio(
  StudioScene base, {
  required Map<String, String> paintings,
  required String desk,
  required List<String> others,
  required String missLine,
  required String deskFirstLine,
}) =>
    StudioScene(
      picture: base.picture,
      pixels: base.pixels,
      place: base.place,
      paintings: [
        for (final p in base.paintings)
          StudioPainting(id: p.id, area: p.area, mark: p.mark, file: p.file, pixels: p.pixels, label: p.label, line: paintings[p.id]!),
      ],
      order: base.order,
      desk: InvestigationSpot(label: base.desk.label, areas: base.desk.areas, line: desk),
      deskMark: base.deskMark,
      others: [for (final (i, o) in base.others.indexed) InvestigationSpot(label: o.label, areas: o.areas, line: others[i])],
      task: base.task,
      deskTask: base.deskTask,
      matchTask: base.matchTask,
      missLine: missLine,
      deskFirstLine: deskFirstLine,
      matchHow: base.matchHow,
      matchPainting: base.matchPainting,
      matchDone: base.matchDone,
      matchDrag: base.matchDrag,
      opening: base.opening,
    );

/// The painted-over sketch: how to slide is the base's.
LayerScene _easel(LayerScene base, {required Map<String, String> found, required String missLine, required String paintLine}) => LayerScene(
      paint: base.paint,
      sketch: base.sketch,
      pixels: base.pixels,
      view: base.view,
      canvas: base.canvas,
      marks: base.marks,
      paintLabel: base.paintLabel,
      sketchLabel: base.sketchLabel,
      slideTask: base.slideTask,
      findTask: base.findTask,
      missLine: missLine,
      paintLine: paintLine,
      foundLines: {for (final id in base.foundLines.keys) id: found[id]!},
    );

/// [id]'s learning design at a level: its own English (and its aim, where
/// the aim quotes it); what the mission depends on, its level and skill as
/// they are.
LearningObjective _learn(String id, {required List<String> expressions, String? objective}) {
  final base = season2Learning[id]!;
  return LearningObjective(
    dependency: base.dependency,
    level: base.level,
    skill: base.skill,
    recallFrom: base.recallFrom,
    objective: objective ?? base.objective,
    expressions: expressions,
  );
}

/// The scenes whose words are the same at every level, by `table/mission`:
/// they hold only ways to play (Tap…, Turn…), the documents their puzzles
/// are read from (the two records, the lift log and its plate, the evidence
/// board's questions and conclusions) and what screen readers say of the
/// pictures. Reviewed and kept on purpose: each level's table names them,
/// so nothing falls back unseen.
const Set<String> season2SameAtEveryLevel = {
  'canvases/s2_ep02_final',
  'records/s2_ep03_m1',
  'lifts/s2_ep03_m2',
  'dialLocks/s2_ep03_m3',
  'evidenceBoards/s2_ep03_final',
};

/// Season 2's puzzle tables at Junior and Master: only what differs (and
/// the scenes kept the same on purpose, [season2SameAtEveryLevel]).
final Map<Difficulty, SeasonContent> season2Variants = {
  Difficulty.junior: SeasonContent(
    info: const {},
    episodes: const {},
    stationClocks: {
      's2_ep01_m1': _hall(
        season2StationClocks['s2_ep01_m1']!,
        others: [
          'Wooden benches. People sit here and wait for their trains.',
          'A train is waiting at the platform.',
          'Suitcases on a trolley. Every one of them is locked.',
          'Stone statues. They cannot tell you anything.',
          'The glass roof. Morning light shines in.',
        ],
        missLine: 'There is nothing here. Look at the clocks and the departure board.',
        boardFirstLine: 'What should you report? Read the departure board first.',
        clocksFirstLine: 'Look at all three clocks first. Which one is different?',
      ),
    },
    exhibits: {
      's2_ep01_m2': _ticket(
        season2Exhibits['s2_ep01_m2']!,
        description:
            'An old train ticket. On the red stub: PARIS. In the middle: a white church. '
            'On the right: MONTMARTRE, PARIS, number 72831.',
        caption: 'Someone dropped it under the old clock this morning.',
      ),
    },
    clocks: {
      's2_ep01_m3': _oldClock(
        season2Clocks['s2_ep01_m3']!,
        question: "Move the old clock's hands one hour forward.",
        lead: 'The carving tells you how to fix the old clock.',
      ),
    },
    compares: {
      's2_ep02_m1': _street(
        season2Compares['s2_ep02_m1']!,
        found: {
          'clock': 'Above the red door, the painting has a small clock. The real street has none.',
          'window': 'The street has a window here. In the painting, it is missing.',
          'lamp': 'In the painting, the lamp beside the steps is bright. On the street, it is not.',
        },
        missLine: 'This looks the same in both. Read the note again.',
      ),
    },
    studios: {
      's2_ep02_m2': _studio(
        season2Studios['s2_ep02_m2']!,
        paintings: {
          'p1': 'You open the old trunk. Inside is a painting of a square.',
          'p2': 'You open the desk drawer. Inside is a painting of a square.',
          'p3': 'You look in the crate under the desk. There is a painting of a square.',
        },
        desk: 'Three notes, marked A, B and C.',
        others: [
          'A canvas with some paint on it, but no picture yet.',
          'His straw hat and his painting smock hang on a hook.',
          'You can see the white church on the hill from here.',
          'Brushes and a palette. The paint on the palette is dry.',
          'Paintings of Paris on the wall. The white church appears again and again.',
        ],
        missLine: 'Nothing here. Where would a painter put things away?',
        deskFirstLine: 'Three notes. But first, find the paintings. Where did he put them away?',
      ),
    },
    layers: {
      's2_ep02_m3': _easel(
        season2Layers['s2_ep02_m3']!,
        found: {
          'lamp': 'An old lamp, tall and thin.',
          'steps': 'Stone steps, going up.',
          'gate': 'An iron gate between two stone pillars. The note says it is black.',
        },
        missLine: 'Look again. Find a lamp, some steps and a gate.',
        paintLine: 'This is thick paint. Slide it away first.',
      ),
    },
    canvases: {'s2_ep02_final': season2Canvases['s2_ep02_final']!},
    records: {'s2_ep03_m1': season2Records['s2_ep03_m1']!},
    lifts: {'s2_ep03_m2': season2Lifts['s2_ep03_m2']!},
    dialLocks: {'s2_ep03_m3': season2DialLocks['s2_ep03_m3']!},
    evidenceBoards: {'s2_ep03_final': season2EvidenceBoards['s2_ep03_final']!},
    learning: {
      // Case 01 (M1: the PART 5 sample, kept).
      's2_ep01_m1': _learn('s2_ep01_m1', expressions: ['running one hour behind', 'report it to the LOST PROPERTY DESK']),
      's2_ep01_m2': _learn('s2_ep01_m2', expressions: ['FIRST', 'NEXT', 'AFTER THAT', 'In what order did these things happen?']),
      's2_ep01_m3': _learn(
        's2_ep01_m3',
        objective: '"Move its hands FORWARD one hour so it matches the hall clock"을 이해하고 9:00에서 한 시간 앞으로 시계를 맞춘다(10:00).',
        expressions: ['Move its hands FORWARD one hour', 'so it matches the hall clock'],
      ),
      's2_ep01_final': _learn('s2_ep01_final', expressions: ['LETTERS FOUND', 'hours and minutes', 'Put the four letters in order']),
      // Case 02.
      's2_ep02_m1': _learn('s2_ep02_m1', expressions: ['Look above the red door', 'Find the window that is missing', 'Check the lamp beside the steps']),
      's2_ep02_m2': _learn(
        's2_ep02_m2',
        expressions: ['BEFORE THE RAIN', 'AFTER THE RAIN STOPPED', 'WHEN THE SKY TURNED GOLD', 'Which painting goes with each note?'],
      ),
      's2_ep02_m3': _learn('s2_ep02_m3', expressions: ['Slide the paint away', 'look UNDERNEATH', 'remember this: the gate is black']),
      's2_ep02_final': _learn('s2_ep02_final', expressions: ['Not the street with the red door', 'Only one canvas matches all three clues']),
      // Case 03.
      's2_ep03_m1': _learn('s2_ep03_m1', expressions: ['The same day. The same job.', 'Compare them line by line', 'Find the two lines that do not match']),
      's2_ep03_m2': _learn('s2_ep03_m2', expressions: ['One stop is not written', 'S = SERVICE RUN']),
      's2_ep03_m3': _learn('s2_ep03_m3', expressions: ['First, check the clock.', 'Next, stop the lift.', 'Finally, turn the key.']),
      's2_ep03_final': _learn(
        's2_ep03_final',
        expressions: ['What was wrong with the inspection records?', 'What can we conclude?', 'the evidence that answers it'],
      ),
    },
  ),
  Difficulty.master: SeasonContent(
    info: const {},
    episodes: const {},
    stationClocks: {
      's2_ep01_m1': _hall(
        season2StationClocks['s2_ep01_m1']!,
        others: [
          'Wooden benches, worn smooth by travellers waiting for their trains.',
          'A train stands ready at the platform.',
          'Suitcases piled on a trolley, every one of them locked tight.',
          'Stone statues gaze down at the hall. They keep their secrets.',
          'The glass roof. Morning light pours in from above.',
        ],
        missLine: 'Nothing of interest here. The clocks and the departure board matter more.',
        boardFirstLine: 'What is there to report? The departure board will tell you. Read it first.',
        clocksFirstLine: 'Study all three clocks first. Which one is out of step?',
      ),
    },
    exhibits: {
      's2_ep01_m2': _ticket(
        season2Exhibits['s2_ep01_m2']!,
        description:
            'A worn train ticket: PARIS on its red stub, a white church printed in the middle, '
            'and on the right MONTMARTRE, PARIS, number 72831.',
        caption: 'Found under the old clock early this morning.',
      ),
    },
    clocks: {
      's2_ep01_m3': _oldClock(
        season2Clocks['s2_ep01_m3']!,
        question: "Turn the old clock's hands one hour forward.",
        lead: 'The carving explains how to put the old clock right.',
      ),
    },
    compares: {
      's2_ep02_m1': _street(
        season2Compares['s2_ep02_m1']!,
        found: {
          'clock': 'A small clock hangs above the red door, but only in the painting.',
          'window': 'The real street has a window here. The painter left it out.',
          'lamp': 'In the painting, the lamp beside the steps glows brightly. On the street, its flame is small.',
        },
        missLine: 'No difference here. Let the note guide you.',
        // The note's lines, as Master's note has them.
        checklist: {
          'clock': 'Look above the red door.',
          'window': 'Seek out the window that has gone missing.',
          'lamp': 'Check the lamp beside the steps.',
        },
      ),
    },
    studios: {
      's2_ep02_m2': _studio(
        season2Studios['s2_ep02_m2']!,
        paintings: {
          'p1': 'The old trunk creaks open. Inside lies a painting of a square.',
          'p2': 'Tucked away in the desk drawer: a painting of a square.',
          'p3': 'Hidden in the crate beneath the desk: a painting of a square.',
        },
        desk: 'Three notes, labelled A, B and C.',
        others: [
          'A canvas with a few strokes of paint, but no picture yet.',
          'His straw hat and paint-spattered smock, hanging on a hook.',
          'The white church on its hill fills the window.',
          'Brushes and a palette. The paint on it has dried hard.',
          'Paintings of Paris cover the wall. The white church, over and over again.',
        ],
        missLine: 'Nothing of interest. Where might a painter tuck things away?',
        deskFirstLine: 'Three notes, but they need their paintings. Where did he put them away?',
      ),
    },
    layers: {
      's2_ep02_m3': _easel(
        season2Layers['s2_ep02_m3']!,
        found: {
          'lamp': 'A tall, thin lamp, old and elegant.',
          'steps': 'Worn stone steps, climbing upward.',
          'gate': 'An iron gate between two stone pillars. Black, the note insists.',
        },
        missLine: 'Nothing there. A lamp, some steps, a gate: keep looking.',
        paintLine: 'Only thick paint. Slide it aside first.',
      ),
    },
    canvases: {'s2_ep02_final': season2Canvases['s2_ep02_final']!},
    records: {'s2_ep03_m1': season2Records['s2_ep03_m1']!},
    lifts: {'s2_ep03_m2': season2Lifts['s2_ep03_m2']!},
    dialLocks: {'s2_ep03_m3': season2DialLocks['s2_ep03_m3']!},
    evidenceBoards: {'s2_ep03_final': season2EvidenceBoards['s2_ep03_final']!},
    learning: {
      's2_ep01_m1': _learn('s2_ep01_m1', expressions: ['fallen one hour behind the others', 'report it to the LOST PROPERTY DESK']),
      's2_ep01_m2': _learn('s2_ep01_m2', expressions: ['FIRST', 'NEXT', 'AFTER THAT', 'Arrange the events in the order they happened']),
      's2_ep01_m3': _learn(
        's2_ep01_m3',
        objective: '"Turn its hands FORWARD by one hour until it agrees with the hall clock"을 이해하고 9:00에서 한 시간 앞으로 시계를 맞춘다(10:00).',
        expressions: ['Turn its hands FORWARD by one hour', 'until it agrees with the hall clock'],
      ),
      's2_ep01_final': _learn('s2_ep01_final', expressions: ['LETTERS FOUND', 'hours and minutes', 'Every clock measures it']),
      's2_ep02_m1': _learn(
        's2_ep02_m1',
        objective: '화가의 메모 "Look above the red door", "Seek out the window that has gone missing", "Check the lamp beside the steps"를 읽고 실제 거리와 그림의 차이 세 곳을 찾는다.',
        expressions: ['Look above the red door', 'the window that has gone missing', 'Check the lamp beside the steps'],
      ),
      's2_ep02_m2': _learn(
        's2_ep02_m2',
        expressions: ['BEFORE THE RAIN', 'AFTER THE RAIN STOPPED', 'WHEN THE SKY TURNED GOLD', 'Pair each note with the painting it describes'],
      ),
      's2_ep02_m3': _learn('s2_ep02_m3', expressions: ['Slide the paint away', 'look UNDERNEATH', 'Whatever he hid lies beneath the paint']),
      's2_ep02_final': _learn('s2_ep02_final', expressions: ['Not the street with the red door', 'Only one canvas fits every clue']),
      's2_ep03_m1': _learn('s2_ep03_m1', expressions: ['The same day. The same job.', 'Somewhere, they disagree', 'Where do the two records disagree?']),
      's2_ep03_m2': _learn('s2_ep03_m2', expressions: ['One stop has been left unwritten', 'S = SERVICE RUN']),
      's2_ep03_m3': _learn(
        's2_ep03_m3',
        expressions: ['First, check the clock.', 'Next, stop the lift.', 'Finally, turn the key.', 'the order the note demands'],
      ),
      's2_ep03_final': _learn(
        's2_ep03_final',
        expressions: ['What was wrong with the inspection records?', 'What can we conclude?', 'what it proves, and what it does not'],
      ),
    },
  ),
};
