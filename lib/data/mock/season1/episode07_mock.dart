/// Case 07 — The Lost Map (Hyde Park). Theme: directions and places
/// ("past", "at", "beside", "behind", "above", "below").
///
/// Mission 01 and the final case show the same four park maps, each with a
/// different spot marked X; only the directions in the note tell which one
/// is right (the wrong maps are one wrong turn away). Mission 03 joins the
/// map pieces by reading "top / above / bottom".
const Map<String, dynamic> episode07Json = {
  'id': 'ep07',
  'number': 7,
  'title': 'The Lost Map',
  'synopsis': [
    'An old map of London has been stolen from Hyde Park.',
    'Only a few pieces and some directions are left.',
    'Follow the directions and put the map together again.',
  ],
  'objectives': ['Follow the directions.', 'Find the lost map.'],
  // The place the intro opens on (its picture behind the story lines).
  'introScene': 'hydePark',
  'intro': [
    'Hyde Park, 7:00 AM...',
    'Inspector Grey was right.',
    'The old London map in the park keeper\'s lodge is gone.',
    'You have one piece from the Tower. The Raven Society has the rest.',
    'Why does the Raven Society want an old map?',
  ],
  'caseSummary': 'You followed every direction, joined the pieces and found the lost map of London.',
  'keyWords': ['past', 'beside', 'behind'],
  'hook': 'Nine black ravens are drawn on the map — all around Platform 9.',
  'missions': [
    {
      'id': 'ep07_m1',
      'number': 1,
      'title': 'The First Directions',
      'location': 'THE PARK GATE',
      'scene': 'hydePark',
      'story': [
        'The park keeper meets you at the gate.',
        'A thief dropped a note and a map piece here last night.',
      ],
      'letterIntro': 'The note says:',
      'letter':
          'Go past the tree.\n'
          'Turn right at the bridge.\n'
          'Look beside the bench.',
      'type': 'imageChoice',
      'question': 'Which map shows the right spot?',
      'options': [
        {'id': 'a', 'label': 'Under the tree', 'artwork': 'parkMapC', 'feedback': 'The note says to go PAST the tree, not to stop at it.'},
        {'id': 'b', 'label': 'Beside the left bench', 'artwork': 'parkMapB', 'feedback': 'Check the turn at the bridge: which way does the note say?'},
        {'id': 'c', 'label': 'Beside the right bench', 'artwork': 'parkMapA'},
        {'id': 'd', 'label': 'At the old gate', 'artwork': 'parkMapD', 'feedback': 'That spot is far past the bridge. The note says to look beside the bench.'},
      ],
      'answer': 'c',
      'hints': [
        'Start at the bottom of the map. Walk up the path with your finger.',
        "'Go past the tree' means go on by it. 'Turn right' and 'beside the bench' tell you where to stop.",
      ],
      'clue': {
        'id': 'ep07_c1',
        'title': 'The Bench',
        'value': 'Right',
        'symbol': 'map',
        'note': 'Right at the bridge, beside the bench.',
      },
      'evidence': {
        'id': 'ep07_e1',
        'name': 'River Map Piece',
        'icon': 'map',
        'description': 'Found beside the bench.',
        'inscription': 'It shows a river and a small raven.',
      },
      'successMessage': 'The directions led you to the map piece beside the bench!',
      'transition': [
        'Beside the bench, you find a map piece in the grass.',
        'The keeper looks worried.',
        '"Somebody was in my boathouse, too!"',
      ],
      'nextMissionId': 'ep07_m2',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.3,
      'mapY': 0.72,
    },
    {
      'id': 'ep07_m2',
      'number': 2,
      'title': 'The Boathouse',
      'location': 'THE BOATHOUSE',
      'scene': 'boathouse',
      'story': [
        'The boathouse is full of oars, ropes and old boxes.',
        'There is a table, a shelf and a green watering can.',
      ],
      'letterIntro': 'Scratched on the door:',
      'letter':
          'The next piece is in a box.\n'
          'The box is not on the shelf.\n'
          'It is under the table,\n'
          'behind the green watering can.',
      'type': 'multipleChoice',
      'question': 'Where is the box with the map piece?',
      'options': [
        {'id': 'a', 'label': 'On the shelf', 'feedback': 'Read the second line: the box is NOT on the shelf.'},
        {'id': 'b', 'label': 'Under the table, in front of the watering can', 'feedback': "Under the table, yes! But 'behind' is not 'in front of'."},
        {'id': 'c', 'label': 'Under the table, behind the watering can'},
        {'id': 'd', 'label': 'On the table, next to the ropes', 'feedback': 'Is the box ON the table, or UNDER it?'},
      ],
      'answer': 'c',
      'hints': [
        'Read every line. The second line says where it is NOT.',
        '"Behind" is the opposite of "in front of".',
      ],
      'clue': {
        'id': 'ep07_c2',
        'title': 'Behind the Can',
        'value': 'Behind',
        'symbol': 'map',
        'note': 'Under the table, behind the watering can.',
      },
      'evidence': {
        'id': 'ep07_e2',
        'name': 'Station Map Piece',
        'icon': 'map',
        'description': 'Found in the boathouse.',
        'inscription': 'It shows a big station with many platforms.',
      },
      'successMessage': 'Behind the watering can!',
      'transition': [
        'Now you have three map pieces.',
        'On the back of one, there are instructions.',
        '"Put me together, and I will show you the way."',
      ],
      'nextMissionId': 'ep07_m3',
      'skills': ['reading', 'vocabulary'],
      'mapX': 0.74,
      'mapY': 0.52,
    },
    {
      'id': 'ep07_m3',
      'number': 3,
      'title': 'The Three Pieces',
      'location': 'THE ROSE GARDEN',
      'scene': 'roseGarden',
      'story': [
        'You lay the three pieces on a bench in the rose garden.',
        'A river piece, a park piece and a station piece.',
      ],
      'letterIntro': 'The instructions on the back say:',
      // Two lines, read together, leave one order (2026-10-23, approved):
      // the pieces that do not touch are the top and the bottom, and the
      // river is not the top.
      'letter':
          'Put me together, from the top to the bottom.\n'
          'The river piece is not at the top.\n'
          'The station piece and the river piece do not touch.',
      'type': 'sequence',
      'question': 'Put the pieces in order, from the top to the bottom.',
      'options': [
        {'id': 'river', 'label': 'The river piece'},
        {'id': 'park', 'label': 'The park piece'},
        {'id': 'station', 'label': 'The station piece'},
      ],
      'codeLength': 3,
      'answer': 'station,park,river',
      // Every wrong order says which line it breaks.
      'feedback': {
        'river,park,station': 'Can the river piece be at the top?',
        'river,station,park': 'The river piece is at the top again. Is it allowed there?',
        'station,river,park': 'Here the station piece and the river piece touch. Do they?',
        'park,station,river': 'The station piece sits right on the river piece. Can they touch?',
        'park,river,station': 'The river piece sits right on the station piece. Can they touch?',
      },
      'orderFeedback': 'Read both lines again: the river piece is not at the top, and the station and river pieces do not touch.',
      'hints': [
        'Start with the two pieces that do not touch. Where can they go?',
        'Pieces that do not touch are at the top and the bottom. Which one is NOT at the top?',
      ],
      'clue': {
        'id': 'ep07_c3',
        'title': 'North to South',
        'value': 'Station',
        'symbol': 'map',
        'note': 'Station at the top, park in the middle, river at the bottom.',
      },
      'evidence': {
        'id': 'ep07_e3',
        'name': 'Joined Map',
        'icon': 'map',
        'description': 'Three pieces, one picture.',
        // Its direction only (2026-10-23, approved; it named the old gate):
        // the final puts it together with Grey's way.
        'inscription': 'An arrow points north, to the top of the park.',
      },
      'successMessage': 'The pieces fit!',
      'transition': [
        // The arrow's spot is the final's answer: nothing names it; the
        // Discovery Moment, the scene and the Joined Map give its direction
        // only (north, the top of the park).
        'You hurry north along the park paths, the joined map in your hand.',
        '"The last piece waits where my arrow points."',
        'But a man in a dark coat is walking there fast!',
      ],
      'nextMissionId': 'ep07_final',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.3,
      'mapY': 0.3,
    },
  ],
  'finalMission': {
    'id': 'ep07_final',
    'number': 4,
    // Named for the chase, not the spot: the spot is the answer, and this
    // name shows before it (the unlocked card, the final's page).
    'title': 'The Last Piece',
    'location': 'THE PARK PATHS',
    'scene': 'hydePark',
    'story': [
      'There is no time to lose!',
      'Inspector Grey calls out the way to you.',
    ],
    'letterIntro': 'Inspector Grey shouts:',
    'letter':
        'Go past the tree.\n'
        'Cross the bridge and turn left!\n'
        'Then follow your joined map!',
    // Grey gives the way (left after the bridge: the left bench or the old
    // gate); the Joined Map (Mission 03) gives the end (its arrow: north, the
    // top of the park, where the old gate is drawn above the left bench).
    // Only both together pick one map.
    'type': 'imageChoice',
    'question': 'Which map shows where to stop?',
    'options': [
      {'id': 'a', 'label': 'Beside the left bench', 'artwork': 'parkMapB', 'feedback': "Left after the bridge, yes. But where does your joined map's arrow point?"},
      {'id': 'b', 'label': 'At the old gate', 'artwork': 'parkMapD'},
      {'id': 'c', 'label': 'Beside the right bench', 'artwork': 'parkMapA', 'feedback': 'Inspector Grey says turn LEFT after the bridge.'},
      {'id': 'd', 'label': 'Under the tree', 'artwork': 'parkMapC', 'feedback': 'Inspector Grey says go PAST the tree.'},
    ],
    'answer': 'b',
    'hints': [
      'Use both clues: Inspector Grey’s directions and the arrow on your joined map.',
      "Grey's way leaves two places. Which one is at the top of the park, where the arrow points?",
    ],
    'evidence': {
      'id': 'ep07_e4',
      'name': 'The Old London Map',
      'icon': 'map',
      'description': 'All the pieces together again.',
      'inscription': 'Nine small ravens are drawn around Platform 9.',
    },
    'successMessage': 'You found the lost map!',
    // After the case is closed: the post-case story scene (existing facts only).
    'transition': [
      'The map is complete.',
      'Nine small ravens\ncircle one place.',
      'PLATFORM 9.',
      'You have seen those words before.',
      "King's Cross is waiting.",
    ],
    'skills': ['reading', 'problemSolving'],
    'mapX': 0.7,
    'mapY': 0.12,
  },
  'glossary': {
    'directions': '길 안내',
    'past': '~을 지나서',
    'turn': '돌다',
    'right': '오른쪽 (또는: 맞는, 옳은)',
    'left': '왼쪽',
    'bridge': '다리',
    'beside': '~옆에',
    'bench': '벤치',
    'boathouse': '보트 창고',
    'oars': '노들',
    'ropes': '밧줄들',
    'shelf': '선반',
    'under': '~아래에',
    'behind': '~뒤에',
    'front': '앞',
    'watering': '물 주는',
    'can': '통, 깡통',
    'scratched': '긁어서 쓴',
    'pieces': '조각들',
    'piece': '조각',
    'top': '맨 위',
    'bottom': '맨 아래',
    'touch': '닿다, 맞닿다',
    'together': '함께, 하나로',
    'above': '~위에',
    'below': '~아래에',
    'garden': '정원',
    'instructions': '설명, 지시',
    'cross': '건너다',
    'keeper': '관리인',
    'lodge': '관리소',
    'worried': '걱정하는',
    'shouts': '외친다',
    'upside': '위쪽 (upside down: 거꾸로)',
  },
};
