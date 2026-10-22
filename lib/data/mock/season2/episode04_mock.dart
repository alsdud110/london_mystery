/// Season 2, Case 04 — The River's Secret (the Seine quays, Paris).
/// Theme: following what was written, and ruling out what cannot be.
///
/// Case 03 ended on the brass plaque: three small waves, and under them
/// SEINE. Its back, turned over under a street lamp, has three lines
/// scratched on it; they lead to the river.
///
/// Every step is played on the case's own pictures, the words on its
/// stones and papers written by the app (`season2_case04_scenes.dart`
/// measures where):
/// 1. Four marks on the quay wall, each wrong on exactly one of the
///    plaque's three lines (the waves, the arrow towards the river, the one
///    who watches the water). Mark D: RIVER KEEPER, by the keeper's steps,
///    QUAY 3.
/// 2. The river keeper's hut: its door, the ledger on the desk, the first
///    page. Of the crates from the Eiffel Tower, only one is on Quay 3, and
///    it was moved: Box 17 to Box 23. The second page opens only then: Box
///    23 was collected for No. 7, delivered through the keeper's steps.
/// 3. The green boxes on the quay: only Box 23 opens. Inside, a torn label
///    and a scrap that is not its own; put back together, it was sent TO:
///    THE WATCHMAKERS, its number washed away, PASSAGE D… and torn.
/// 4. The street book's four watchmakers' streets: each wrong one crossed
///    out with what rules it out (the label starts PASSAGE; the keeper's
///    steps are on Quay 3 and the delivery went through them; No. 7 is
///    past houses 1 to 5). One is left: PASSAGE DES HORLOGERS. At its
///    gate, the label's last piece fits: …ES HORLOGERS.
///
/// The street book is the keeper's own, as the game tells it: Quai de
/// l'Horloge is a real quay of the Île de la Cité, but its "houses 1 to
/// 40" and the three passages are the story's, never given as fact.
/// Who the Clockmaker is stays untold; that an hour truly vanished, too.
const Map<String, dynamic> season2Episode04Json = {
  'id': 's2_ep04',
  'seasonId': 's2_paris',
  'number': 4,
  'title': "The River's Secret",
  'place': 'SEINE QUAYS · PARIS',
  'synopsis': [
    'The brass plaque had three small waves and one word: SEINE.',
    'On its back, three short lines lead you to the river.',
    'Somewhere on the quays, a mark is waiting.',
  ],
  'objectives': [
    'Find the right mark on the quay wall.',
    "Read the river keeper's ledger.",
    'Put the torn label back together.',
  ],
  'introScene': 'seineQuays',
  'intro': [
    'Three small waves. One word: SEINE.',
    'You hold the brass plaque up to a street lamp.',
    'On its back, someone has scratched three short lines.',
    'The river is only a short walk away.',
    'Old stone walls. Green bookstalls. Dark, quiet water.',
    'Somewhere on these quays, a mark is waiting for you.',
  ],
  'caseSummary':
      "You followed three waves to the River Keeper, read the keeper's ledger, put a torn label back together and crossed out three wrong addresses. One address was left.",
  'keyWords': ['waves', 'arrow', 'towards', 'moved', 'collected', 'delivery'],
  'hook': 'Do not trust the clocks. Whose hands made them?',
  'missions': [
    {
      'id': 's2_ep04_m1',
      'number': 1,
      'title': 'Three Waves',
      'location': 'THE QUAY WALL',
      'scene': 'quayWall',
      'story': [
        'Down by the river, the old stone wall is cold and wet.',
        'Four marks are carved into it, side by side.',
        'Each mark has waves, an arrow and a word.',
      ],
      'letterIntro': 'The back of the brass plaque says:',
      'letter':
          'Three waves mark the place.\n'
          'Follow the arrow towards the river.\n'
          'Find the one who watches the water.',
      // One mark of four, each of the others wrong on one line only.
      'type': 'multipleChoice',
      'question': 'Which mark follows all three lines?',
      'options': [
        {
          'id': 'a',
          'label': 'Mark A',
          // Each wrong mark breaks one line: the feedback names that line
          // (as numbered on the puzzle page), never the right mark.
          'feedback': 'Look at line 2 again: the arrow. Where does the arrow on Mark A point? Is the river up there?',
        },
        {
          'id': 'b',
          'label': 'Mark B',
          'feedback': 'Look at line 3 again: the word. Mark B has three waves and points down to the river. But read its word. Do booksellers watch the water?',
        },
        {
          'id': 'c',
          'label': 'Mark C',
          'feedback': 'Look at line 1 again: the waves. Count the waves on Mark C. How many does the plaque say?',
        },
        {'id': 'd', 'label': 'Mark D'},
      ],
      'answer': 'd',
      'hints': [
        'The back of the plaque gives you three things to check. Read it one line at a time.',
        'Check every mark three ways. How many waves? Does the arrow point towards the river? Does it name someone who watches the water?',
      ],
      'clue': {
        'id': 's2_ep04_c1',
        'title': "The Keeper's Steps",
        'value': 'QUAY 3',
        'symbol': 'map',
        'note': "Beside the mark, the keeper's steps go down to the water. A small sign says QUAY 3.",
      },
      'evidence': {
        'id': 's2_ep04_e1',
        'name': 'The River Mark',
        'icon': 'map',
        'description': 'Carved into the quay wall, beside stone steps to the water.',
        'inscription':
            "Three waves and an arrow pointing down towards the river: RIVER KEEPER. Beside it, the keeper's steps go down to the water. QUAY 3.",
      },
      'successMessage': "You found the River Keeper's mark!",
      'transition': [
        'Three waves. An arrow pointing down to the river. RIVER KEEPER.',
        "Beside the mark, the keeper's steps go down to the water.",
        'A small sign on the wall says QUAY 3.',
        'At the bottom of the steps stands a little wooden hut.',
      ],
      'nextMissionId': 's2_ep04_m2',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.5,
      'mapY': 0.2,
    },
    {
      'id': 's2_ep04_m2',
      'number': 2,
      'title': 'The River Keeper',
      'location': "THE KEEPER'S HUT",
      'scene': 'keeperHut',
      'story': [
        'The little hut stands right by the water.',
        'Its door is open, and a lamp is burning inside.',
        'The river keeper writes down every box that comes and goes.',
      ],
      'letterIntro': 'Your notebook says:',
      'letter':
          // Case 03's end: the crate gone from the service room, its tag
          // TO: THE RIVER.
          'The crate from the tower went to the river.\n'
          'The River Mark says QUAY 3.\n\n'
          "Find the keeper's ledger.\n"
          'Where is the crate now?',
      // The box circled in the ledger.
      'type': 'multipleChoice',
      'question': "Which box did the tower's crate end up in?",
      'options': [
        {
          'id': 'box4',
          'label': 'Box 4',
          'feedback': 'Box 4 holds old books from the bookstalls. You are looking for something from the Eiffel Tower.',
        },
        {
          'id': 'box9',
          'label': 'Box 9',
          'feedback': 'Box 9 came from the Eiffel Tower, but it is on Quay 1. Your River Mark says QUAY 3.',
        },
        {
          'id': 'box12',
          'label': 'Box 12',
          'feedback': 'Box 12 is lamp oil from Pont Neuf. You are looking for something from the Eiffel Tower.',
        },
        {
          'id': 'box17',
          'label': 'Box 17',
          'feedback': 'Yes, the heavy crate went into Box 17. But read the last line of the page. Did it stay there?',
        },
        {
          'id': 'box6',
          'label': 'Box 6',
          'feedback': 'Box 6 came from the Eiffel Tower, but it is on Quay 2. Your River Mark says QUAY 3.',
        },
        {'id': 'box23', 'label': 'Box 23'},
      ],
      'answer': 'box23',
      'hints': [
        'Look for the things that came from the Eiffel Tower. Which one is on Quay 3?',
        'Find that box number again lower down the page. What happened to it on 14 May?',
      ],
      'clue': {
        'id': 's2_ep04_c2',
        'title': 'Collected for No. 7',
        'value': 'No. 7',
        'symbol': 'letter',
        'note': "Box 23 was collected for No. 7. Delivery: through the keeper's steps.",
      },
      'evidence': {
        'id': 's2_ep04_e2',
        'name': "The Keeper's Ledger",
        'icon': 'ticket',
        'description': "Open on the desk in the river keeper's hut.",
        'inscription':
            '13 MAY: a heavy crate from the Eiffel Tower, Quay 3, Box 17. '
            '14 MAY: Box 17 moved to Box 23. '
            "15 MAY: Box 23 collected for No. 7. Delivery: through the keeper's steps. "
            'These lines are signed with two clock hands.',
      },
      'successMessage': 'You found the box!',
      'transition': [
        'Box 17 was moved to Box 23.',
        'Then Box 23 was collected for No. 7.',
        'Those lines are signed with the same mark: two clock hands.',
        'Outside, green boxes stand in a row along the quay.',
      ],
      'nextMissionId': 's2_ep04_m3',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.56,
      'mapY': 0.16,
    },
    {
      'id': 's2_ep04_m3',
      'number': 3,
      'title': 'The Hidden Message',
      'location': 'THE GREEN BOXES',
      'scene': 'quayBoxes',
      'story': [
        'Four green boxes stand on the river wall.',
        'Each one has a number on its lid.',
        'One of them holds what came from the tower.',
      ],
      'letterIntro': 'Your notebook says:',
      'letter':
          'BOX 23.\n\n'
          'Open the right box.\n'
          'Put the torn label back together.\n'
          'Read where it was sent.',
      // Each piece set in its slot (`piece:slot`); the scrap from another
      // paper fits none.
      'type': 'matchPairs',
      'question': 'Put the torn label back together.',
      'options': [
        {'id': 'p1', 'label': 'The piece with the eyelet'},
        {'id': 'p2', 'label': 'The piece with CONTENTS'},
        {'id': 'p3', 'label': 'The piece with TO'},
        {'id': 'decoy', 'label': 'The blue-grey scrap'},
      ],
      'answer': 'p1:top,p2:middle,p3:bottom',
      'feedback': {
        'decoy:top': 'That scrap is a different paper: thinner, blue-grey, with blue ink. It is not from this label.',
        'decoy:middle': 'That scrap is a different paper: thinner, blue-grey, with blue ink. It is not from this label.',
        'decoy:bottom': 'That scrap is a different paper: thinner, blue-grey, with blue ink. It is not from this label.',
        'p1:middle': 'The piece with the brass eyelet is where a label is tied. It goes at the top.',
        'p1:bottom': 'The piece with the brass eyelet is where a label is tied. It goes at the top.',
        'p2:top': 'A label says where it is FROM first. What it holds comes next.',
        'p2:bottom': 'What the parcel holds comes before where it is going. Read the torn edges: do they meet?',
        'p3:top': 'Where a parcel goes comes last on a label. Look for the line with TO.',
        'p3:middle': 'Where a parcel goes comes last on a label. Look for the line with TO.',
      },
      'hints': [
        'One scrap is a different paper: thinner, blue-grey, with blue ink. Leave it out.',
        'A label is read from the top: FROM, then CONTENTS, then TO. The piece with the brass eyelet goes at the top.',
      ],
      'clue': {
        'id': 's2_ep04_c3',
        'title': 'Passage D…',
        'value': 'PASSAGE D…',
        'symbol': 'letter',
        'note': 'The label was sent TO: THE WATCHMAKERS. The number is washed away. The address stops at PASSAGE D…',
      },
      'evidence': {
        'id': 's2_ep04_e3',
        'name': 'The Torn Delivery Label',
        'icon': 'letter',
        'description': 'Found in Box 23 on the quay.',
        'inscription':
            'FROM: EIFFEL TOWER — SERVICE LEVEL. CONTENTS: CLOCK PARTS. TO: THE WATCHMAKERS. '
            'No. — washed away. PASSAGE D… The rest is torn off.',
      },
      'successMessage': 'The label fits together!',
      'transition': [
        'FROM: EIFFEL TOWER — SERVICE LEVEL.',
        'CONTENTS: CLOCK PARTS.',
        'TO: THE WATCHMAKERS. PASSAGE D…',
        'The rest of the label is torn off.',
        "In the keeper's hut, an old street book sits on a shelf.",
      ],
      'nextMissionId': 's2_ep04_final',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.62,
      'mapY': 0.22,
    },
  ],
  'finalMission': {
    'id': 's2_ep04_final',
    'number': 4,
    'title': "The Watchmaker's Address",
    'location': "THE KEEPER'S HUT",
    'scene': 'keeperHutInside',
    'story': [
      'You take the old street book down from the shelf.',
      'Four of its streets are full of watchmakers.',
      'Only one of them can be the address on the label.',
    ],
    'letterIntro': 'Your notebook says:',
    'letter':
        'Cross out every address that cannot be right.\n'
        'Use your evidence to show why.\n\n'
        'The one that is left is the address.',
    // Each wrong address crossed out with what rules it out (`address:e1+e2`,
    // in the evidence's order, up to two pieces). The address left is not
    // part of the answer: it is what is left.
    'type': 'matchPairs',
    'question': 'Which address is the right one?',
    'options': [
      {'id': 'quai', 'label': "QUAI DE L'HORLOGE"},
      {'id': 'pont', 'label': 'PASSAGE DU PONT'},
      {'id': 'horloge', 'label': "PASSAGE DE L'HORLOGE"},
      {'id': 'horlogers', 'label': 'PASSAGE DES HORLOGERS'},
    ],
    'answer': 'quai:e3,pont:e1+e2,horloge:e2',
    'feedback': {
      'quai:e1': 'The River Mark is about the steps. Look at how the address on the label starts.',
      'quai:e2': 'This street has a No. 7 too. Look at how the address on the label starts.',
      'quai:e1+e2': 'Look at the torn label. Does its address start with QUAI?',
      'quai:e1+e3': 'The label is all you need here. One piece of evidence is enough.',
      'quai:e2+e3': 'The label is all you need here. One piece of evidence is enough.',
      'pont:e1': "Yes, the keeper's steps are on Quay 3. But how was the crate delivered? Add the evidence that tells you.",
      'pont:e2': "Yes, the delivery went through the keeper's steps. But where are those steps? Add the evidence that tells you.",
      'pont:e3': 'PASSAGE DU PONT starts with PASSAGE D. The label fits it. Think about its gate on Quay 1.',
      'pont:e1+e3': 'The label fits PASSAGE DU PONT. Think about its gate: how was the crate delivered, and where are the steps?',
      'pont:e2+e3': 'The label fits PASSAGE DU PONT. Think about its gate: how was the crate delivered, and where are the steps?',
      'horloge:e1': "This gate is at the keeper's steps on Quay 3, just as the River Mark says. Look at the house numbers.",
      'horloge:e3': "PASSAGE DE L'HORLOGE starts with PASSAGE D. The label fits it. Look at the house numbers.",
      'horloge:e1+e2': 'The ledger is all you need here. Which house number was the box for?',
      'horloge:e2+e3': 'The ledger is all you need here. Which house number was the box for?',
      'horloge:e1+e3': 'Look at the house numbers. Which evidence gives you a house number?',
      'horlogers:e1': 'Check every line again: how the name starts, the house numbers, and where the gate is. Does your evidence rule this address out?',
      'horlogers:e2': 'Check every line again: how the name starts, the house numbers, and where the gate is. Does your evidence rule this address out?',
      'horlogers:e3': 'Check every line again: how the name starts, the house numbers, and where the gate is. Does your evidence rule this address out?',
      'horlogers:e1+e2': 'Check every line again: how the name starts, the house numbers, and where the gate is. Does your evidence rule this address out?',
      'horlogers:e1+e3': 'Check every line again: how the name starts, the house numbers, and where the gate is. Does your evidence rule this address out?',
      'horlogers:e2+e3': 'Check every line again: how the name starts, the house numbers, and where the gate is. Does your evidence rule this address out?',
    },
    'hints': [
      'Read each address line by line: its name, its house numbers, and where its gate is.',
      'Each wrong address breaks one thing you found: how the label starts, the house number in the ledger, or the steps the delivery went through.',
    ],
    'evidence': {
      'id': 's2_ep04_e4',
      'name': 'The Workshop Address',
      'icon': 'seal',
      'description': 'The last piece of the label, caught in the gate of PASSAGE DES HORLOGERS.',
      'inscription':
          'ES HORLOGERS. The last piece fits the label: PASSAGE DES HORLOGERS. '
          'On its back: Do not trust the clocks. Follow the hands that made them.',
    },
    'successMessage': 'You found the address!',
    // After the case is closed: the post-case scene, then the case report.
    'transition': [
      'PASSAGE DES HORLOGERS.',
      'The passage of the watchmakers.',
      'Behind the iron gate, the workshops are dark and quiet.',
      'Do not trust the clocks.',
      'Follow the hands that made them.',
      'But whose hands are they?',
    ],
    'skills': ['problemSolving', 'reading'],
    'mapX': 0.55,
    'mapY': 0.12,
  },
  'glossary': {
    'waves': '물결들',
    'wave': '물결',
    'brass': '황동, 놋쇠',
    'plaque': '명판, 금속판',
    'scratched': '긁어서 새긴',
    'lines': '줄들',
    'river': '강',
    'quays': '강둑길들',
    'quay': '강둑길, 부두',
    'bookstalls': '책 가판대들',
    'carved': '새겨진',
    'mark': '표식',
    'marks': '표식들',
    'arrow': '화살표',
    'towards': '~쪽으로',
    'watches': '지켜보다',
    'keeper': '관리인',
    'steps': '계단',
    'sign': '표지판',
    'hut': '오두막',
    'ledger': '장부',
    'crate': '나무 상자',
    'box': '상자, 보관함',
    'boxes': '상자들, 보관함들',
    'moved': '옮겨졌다',
    'collected': '가져갔다, 수거했다',
    'delivery': '배달',
    'lamp': '등불, 램프',
    'oil': '기름',
    'heavy': '무거운',
    'booksellers': '책 파는 사람들',
    'signed': '서명한',
    'hands': '(시계) 바늘',
    'label': '배송표, 꼬리표',
    'torn': '찢어진',
    'scrap': '조각',
    'eyelet': '끈 구멍',
    'contents': '내용물',
    'parcel': '소포',
    'watchmakers': '시계공들',
    'washed': '씻겨 나간',
    'address': '주소',
    'cross': '(줄을 그어) 지우다',
    'passage': '좁은 골목길',
    'gate': '대문, 철문',
    'workshops': '작업장, 공방',
    'trust': '믿다',
    'evidence': '증거',
    'bookseller': '책 파는 사람',
    'chain': '쇠사슬',
    'houses': '집들 (번지)',
    'shops': '가게들',
    'iron': '철로 된',
  },
};
