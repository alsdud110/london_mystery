/// Season 2, Case 01 — The Ticking Watch (Gare du Nord, Paris).
/// Theme: one stolen hour.
///
/// The detective has followed the Clockmaker from London (Season 1's
/// ending: his watch, still ticking, says PARIS on the back; Season 2's
/// opening). At Gare du Nord, three clocks hang over the hall: two show
/// ten, the old one shows nine.
///
/// Reasoning chain (every step is read in English, never a quiz):
/// 1. The station notice says what to do when ONE clock is ONE HOUR BEHIND:
///    the detective compares the three clocks and finds the old one (9:00
///    against 10:00). Letter T is scratched on its glass.
/// 2. At the Lost Property desk, the clerk's notes say what happened FIRST,
///    NEXT and AFTER THAT: the man with the pocket watch came before the old
///    clock went back. A lost ticket holds the letter I; its front (printed
///    MONTMARTRE, a white church on it) says nothing yet of why.
/// 3. The Clockmaker's own carving on the old clock says to move its hands
///    FORWARD ONE HOUR to match the hall clock: 9:00 → 10:00. A little door
///    opens on the letter M.
/// 4. The brass box under the clock has a letter lock and an E carved on it:
///    T, I, M and E make TIME. Inside: a painting of Montmartre, FIND THE
///    PAINTER on its back (Case 02's place): the white church of the lost
///    ticket (the two pieces of evidence are linked: `season2EvidenceLinks`).
///
/// Who the Clockmaker is, and how he steals the hour, stay untold.
const Map<String, dynamic> season2Episode01Json = {
  'id': 's2_ep01',
  'seasonId': 's2_paris',
  'number': 1,
  'title': 'The Ticking Watch',
  'place': 'GARE DU NORD · PARIS',
  'synopsis': [
    'The clocks at Gare du Nord show different times.',
    'Why is one clock an hour behind?',
    'Find the clues and discover the truth.',
  ],
  'objectives': [
    'Find the clock that is wrong.',
    'Find out who changed it.',
    'Open what the old clock is hiding.',
  ],
  'introScene': 'gareDuNord',
  'intro': [
    'Paris. Gare du Nord.',
    'You step off the train from London.',
    "In your pocket, the Clockmaker's watch is still ticking.",
    'High above the platforms, three clocks are ticking too.',
    'But they do not show the same time.',
  ],
  'caseSummary': 'You found the clock that was one hour behind, put the events in order and opened the Clockmaker\'s hidden box.',
  'keyWords': ['behind', 'first', 'next', 'forward'],
  'hook': 'Inside the box is a painting of Montmartre. On the back: FIND THE PAINTER.',
  'missions': [
    {
      'id': 's2_ep01_m1',
      'number': 1,
      'title': 'The Three Clocks',
      'location': 'THE STATION HALL',
      'scene': 'gareDuNord',
      'story': [
        'The station hall is busy. People hurry to their trains.',
        'Under the glass roof, three clocks are ticking.',
      ],
      'letterIntro': 'A notice hangs beside the departure board.',
      'letter':
          'STATION NOTICE\n\n'
          'All our clocks show Paris time.\n'
          'IF ONE CLOCK IS ONE HOUR BEHIND,\n'
          'REPORT IT TO THE LOST PROPERTY DESK.\n\n'
          'YOUR NOTES\n'
          'The hall clock shows 10:00.\n'
          'The platform clock shows 10:00.\n'
          'The old clock shows 9:00.',
      // The three clocks are the options; the old one is an hour behind.
      // Each wrong pick is a clock that agrees with another one.
      'type': 'multipleChoice',
      'question': 'Which clock is one hour behind?',
      'options': [
        {
          'id': 'a',
          'label': 'The hall clock',
          'feedback': 'The hall clock shows 10:00, like the platform clock. Which clock shows a different hour?',
        },
        {
          'id': 'b',
          'label': 'The platform clock',
          'feedback': 'The platform clock shows 10:00, like the hall clock. Which clock shows a different hour?',
        },
        {'id': 'c', 'label': 'The old clock'},
      ],
      'answer': 'c',
      'hints': [
        'Look at all three clocks. Two of them show the same time.',
        'ONE HOUR BEHIND means one hour less. Which clock shows 9:00 when the others show 10:00?',
      ],
      'clue': {
        'id': 's2_ep01_c1',
        'title': 'Letter T',
        'value': 'T',
        'symbol': 'watch',
        'note': 'The old clock is one hour behind. A letter is scratched on its glass: T.',
      },
      'evidence': {
        'id': 's2_ep01_e1',
        'name': 'Station Notice',
        'icon': 'letter',
        'description': 'It hangs beside the departure board.',
        'inscription': 'IF ONE CLOCK IS ONE HOUR BEHIND, REPORT IT TO THE LOST PROPERTY DESK.',
      },
      'successMessage': 'The old clock is one hour behind!',
      'transition': [
        'The old clock shows nine. The others show ten.',
        'Someone scratched a small letter on its glass: T.',
        'The notice says where to go: the Lost Property desk.',
      ],
      'nextMissionId': 's2_ep01_m2',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.2,
      'mapY': 0.5,
    },
    {
      'id': 's2_ep01_m2',
      'number': 2,
      'title': 'The Lost Ticket',
      'location': 'LOST PROPERTY DESK',
      'scene': 'gareDuNord',
      'story': [
        'At the Lost Property desk, a clerk shows you a train ticket.',
        'Someone dropped it under the old clock this morning.',
      ],
      'letterIntro': 'The clerk gives you the ticket and her notes.',
      // The ticket itself is its own picture beside the notes
      // (`season2Exhibits`): nothing here says what is printed on it.
      'letter':
          "CLERK'S NOTES\n\n"
          // Written as she remembered it, not in order: the order words put
          // them in order.
          'AFTER THAT, the old clock showed nine.\n'
          'FIRST, the hall clock struck ten.\n'
          'NEXT, a man with a pocket watch entered the waiting room.\n\n'
          '— Lost Property, Gare du Nord',
      // The cards are shuffled; FIRST, NEXT and AFTER THAT put them in order.
      'type': 'sequence',
      'question': 'Put what happened in the right order.',
      'options': [
        {'id': 'a', 'label': 'The old clock showed nine.'},
        {'id': 'b', 'label': 'The hall clock struck ten.'},
        {'id': 'c', 'label': 'A man with a pocket watch entered the waiting room.'},
      ],
      'answer': 'b,c,a',
      'codeLength': 3,
      'orderFeedback': 'Read the notes again. What happened FIRST? What came NEXT? What came AFTER THAT?',
      'feedback': {
        'c,b,a': 'The man came NEXT, not first. What happened FIRST?',
        'b,a,c': 'The old clock changed AFTER THAT, at the end. What came NEXT?',
      },
      'hints': [
        'The notes use three order words: FIRST, NEXT and AFTER THAT.',
        'FIRST is the hall clock. AFTER THAT is the old clock. What is in the middle?',
      ],
      'clue': {
        'id': 's2_ep01_c2',
        'title': 'Letter I',
        'value': 'I',
        'symbol': 'ticket',
        'note': 'FIRST, the hall clock struck ten. NEXT, a man with a pocket watch came in. AFTER THAT, the old clock showed nine. On the ticket: I.',
      },
      'evidence': {
        'id': 's2_ep01_e2',
        'name': 'Lost Ticket',
        'icon': 'ticket',
        'description': 'Dropped under the old clock this morning.',
        'inscription': 'MONTMARTRE · PARIS · No. 72831. On the back, a small letter: I.',
      },
      'successMessage': 'You put the events in order!',
      'transition': [
        // The order as the clerk's notes give it, never more: whether the
        // man changed the clock is a question, not a finding.
        'FIRST, the hall clock struck ten.',
        'NEXT, a man with a pocket watch came in.',
        'AFTER THAT, the old clock showed nine.',
        'Did the man change the old clock? Why would anyone hide an hour?',
        'The ticket in your hand has a letter on the back: I.',
      ],
      'nextMissionId': 's2_ep01_m3',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.45,
      'mapY': 0.58,
    },
    {
      'id': 's2_ep01_m3',
      'number': 3,
      'title': "The Clockmaker's Mark",
      'location': 'THE OLD CLOCK',
      'scene': 'gareDuNord',
      'story': [
        'You climb the iron steps to the old clock.',
        'A message is carved into its brass frame.',
      ],
      'letterIntro': 'The carving says:',
      'letter':
          'THE OLD CLOCK IS ONE HOUR BEHIND.\n'
          'MOVE ITS HANDS FORWARD ONE HOUR\n'
          'TO MATCH THE HALL CLOCK.\n\n'
          'Under the words, a tiny gear is carved.',
      // The time set is the answer (hour then two-digit minutes): 9:00 moved
      // forward one hour.
      'type': 'numberCode',
      'question': 'Set the old clock to the right time.',
      'codeLength': 4,
      'answer': '1000',
      'feedback': {
        '900': 'That is the time it shows now. Move the hands FORWARD one hour.',
        '800': 'That is one hour BACK. FORWARD means the hour goes up.',
        '1100': 'That is two hours forward. The carving says ONE hour.',
      },
      'hints': [
        'The old clock shows 9:00. FORWARD means later, not earlier.',
        'FORWARD ONE HOUR: the short hand moves on to the next number. The long hand goes once around, back to 12.',
      ],
      'clue': {
        'id': 's2_ep01_c3',
        'title': 'Letter M',
        'value': 'M',
        'symbol': 'gear',
        'note': 'The old clock shows ten again. A little door clicked open on a letter: M.',
      },
      'evidence': {
        'id': 's2_ep01_e3',
        'name': "The Clockmaker's Mark",
        'icon': 'seal',
        'description': 'Carved into the old clock.',
        'inscription': 'A tiny carved gear, and the letter M.',
      },
      'successMessage': 'The old clock shows ten again!',
      'transition': [
        'The old clock chimes ten.',
        'Under its face, a small brass box slides out.',
        'It has a lock with four letter slots. One letter is carved on it: E.',
      ],
      'nextMissionId': 's2_ep01_final',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.7,
      'mapY': 0.45,
    },
  ],
  'finalMission': {
    'id': 's2_ep01_final',
    'number': 4,
    'title': 'The Hidden Compartment',
    'location': 'UNDER THE OLD CLOCK',
    'scene': 'gareDuNord',
    'story': [
      'The brass box is small and heavy.',
      'Inside, something is ticking.',
    ],
    'letterIntro': 'Your notebook says:',
    'letter':
        'LETTERS FOUND\n\n'
        'T — scratched on the old clock\n'
        'I — on the lost ticket\n'
        "M — behind the Clockmaker's mark\n"
        'E — carved on the box\n\n'
        'The Clockmaker loves one thing more than anything.\n'
        'He steals it. He hides it.',
    'type': 'letterLock',
    'question': 'Make the word that opens the box.',
    // The tiles, loose: never in the order of the word.
    'options': [
      {'id': 'm', 'label': 'M'},
      {'id': 'e', 'label': 'E'},
      {'id': 't', 'label': 'T'},
      {'id': 'i', 'label': 'I'},
    ],
    'answer': 'TIME',
    'orderFeedback': 'You have the right letters. Try another order. What does a clock show?',
    'feedback': {
      'ITEM': 'ITEM is a real word, but not the one. What does the Clockmaker steal? What does a clock show?',
      'EMIT': 'EMIT is a real word, but not the one. What does a clock show?',
      'MITE': 'MITE is a real word, but not the one. What does a clock show?',
    },
    'hints': [
      'The Clockmaker steals an hour. An hour is a part of the day. What is the word for hours and minutes?',
      'Clocks show the T _ _ E.',
    ],
    'evidence': {
      'id': 's2_ep01_e4',
      'name': 'Montmartre Painting',
      'icon': 'frame',
      'description': 'Found in the hidden box.',
      'inscription': 'A white church on a hill, above the roofs of Paris. On the back: FIND THE PAINTER.',
    },
    'successMessage': 'The box clicks open!',
    // After the case is closed: the post-case scene, then the case report.
    'transition': [
      'The lock clicks. The lid lifts.',
      'Inside is a small painting.',
      'A white church on a hill,\nabove the roofs of Paris.',
      'Montmartre.',
      'The same white church is on the lost ticket.',
      'You turn it over.',
      'Three words are written on the back.',
      'FIND THE PAINTER.',
    ],
    'skills': ['problemSolving', 'reading'],
    'mapX': 0.88,
    'mapY': 0.55,
  },
  'glossary': {
    'notice': '안내문, 공지',
    'behind': '(시간이) 늦은, 뒤처진',
    'report': '알리다, 신고하다',
    'property': '물건, 소지품',
    'lost': '잃어버린',
    'desk': '창구, 책상',
    'hall': '홀, 큰 방',
    'platform': '승강장',
    'platforms': '승강장들',
    'departure': '출발',
    'board': '안내판, 게시판',
    'clerk': '직원, 사무원',
    'notes': '메모, 기록',
    'first': '먼저, 첫째로',
    'next': '그다음에',
    'struck': '(시계가) 쳤다',
    'entered': '들어갔다',
    'waiting': '기다리는',
    'dropped': '떨어뜨렸다',
    'carved': '새겨진',
    'carving': '새긴 글씨',
    'frame': '틀, 테두리',
    'brass': '놋쇠',
    'forward': '앞으로',
    'match': '맞추다',
    'gear': '톱니바퀴',
    'chimes': '(시계가) 종을 울리다',
    'slides': '미끄러져 나오다',
    'slots': '구멍, 칸',
    'compartment': '칸, 숨은 공간',
    'scratched': '긁어서 새긴',
    'glass': '유리',
    'ticket': '표, 기차표',
    'steals': '훔치다',
    'painting': '그림',
    'painter': '화가',
    'church': '교회, 성당',
    'hill': '언덕',
    'roofs': '지붕들',
    'ticking': '째깍거리는',
  },
};
