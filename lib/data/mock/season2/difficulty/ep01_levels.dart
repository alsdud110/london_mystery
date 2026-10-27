import '../../../models/clock_puzzle.dart';
import '../../../models/investigation.dart' show InvestigationSpot;
import '../../../models/learning.dart';
import '../../../models/scene_exhibit.dart';
import '../../../models/station_clocks.dart';
import '../season2_scenes.dart';
import 'level_words.dart';

// Case 01 — The Ticking Watch, at each level (PART 7A): the words only
// (`docs/difficulty_reviews/PARIS_CASE_01_03.md`).

const _words01 = {
  'events': '일어난 일들',
  'order': '순서',
  'pocket': '주머니',
  'hands': '(시계) 바늘',
  'heavy': '무거운',
};

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

const rookie01 = <String, Object?>{'glossary': _words01};

const junior01 = <String, Object?>{
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

const master01 = <String, Object?>{
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

/// Case 01's scenes with Junior's words.
final juniorScenes01 = (
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
);

/// Case 01's scenes with Master's words.
final masterScenes01 = (
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
);

// ═════════════════════════════════════════════════════════════════════════
// The learning design
// ═════════════════════════════════════════════════════════════════════════

final juniorLearning01 = <String, LearningObjective>{
  // Case 01 (M1: the PART 5 sample, kept).
  's2_ep01_m1': levelObjectiveWith('s2_ep01_m1', expressions: ['running one hour behind', 'report it to the LOST PROPERTY DESK']),
  's2_ep01_m2': levelObjectiveWith('s2_ep01_m2', expressions: ['FIRST', 'NEXT', 'AFTER THAT', 'In what order did these things happen?']),
  's2_ep01_m3': levelObjectiveWith(
    's2_ep01_m3',
    objective: '"Move its hands FORWARD one hour so it matches the hall clock"을 이해하고 9:00에서 한 시간 앞으로 시계를 맞춘다(10:00).',
    expressions: ['Move its hands FORWARD one hour', 'so it matches the hall clock'],
  ),
  's2_ep01_final': levelObjectiveWith('s2_ep01_final', expressions: ['LETTERS FOUND', 'hours and minutes', 'Put the four letters in order']),
};

final masterLearning01 = <String, LearningObjective>{
  's2_ep01_m1': levelObjectiveWith('s2_ep01_m1', expressions: ['fallen one hour behind the others', 'report it to the LOST PROPERTY DESK']),
  's2_ep01_m2': levelObjectiveWith('s2_ep01_m2', expressions: ['FIRST', 'NEXT', 'AFTER THAT', 'Arrange the events in the order they happened']),
  's2_ep01_m3': levelObjectiveWith(
    's2_ep01_m3',
    objective: '"Turn its hands FORWARD by one hour until it agrees with the hall clock"을 이해하고 9:00에서 한 시간 앞으로 시계를 맞춘다(10:00).',
    expressions: ['Turn its hands FORWARD by one hour', 'until it agrees with the hall clock'],
  ),
  's2_ep01_final': levelObjectiveWith('s2_ep01_final', expressions: ['LETTERS FOUND', 'hours and minutes', 'Every clock measures it']),
};
