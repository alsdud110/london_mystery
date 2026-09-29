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
        {'id': 'a', 'label': 'Under the tree', 'artwork': 'parkMapC'},
        {'id': 'b', 'label': 'Beside the left bench', 'artwork': 'parkMapB'},
        {'id': 'c', 'label': 'Beside the right bench', 'artwork': 'parkMapA'},
        {'id': 'd', 'label': 'At the old gate', 'artwork': 'parkMapD'},
      ],
      'answer': 'c',
      'hints': [
        'Start at the bottom of the map. Walk up the path with your finger.',
        'After the bridge, the path goes two ways. The note says which way to turn.',
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
      'successMessage': 'The map piece was beside the bench!',
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
        {'id': 'a', 'label': 'On the shelf'},
        {'id': 'b', 'label': 'Under the table, in front of the watering can'},
        {'id': 'c', 'label': 'Under the table, behind the watering can'},
        {'id': 'd', 'label': 'On the table, next to the ropes'},
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
      'letter':
          'The station piece goes at the top.\n'
          'The river piece goes at the bottom.\n'
          'The park piece goes above the river\n'
          'and below the station.',
      'type': 'sequence',
      'question': 'Put the pieces in order, from the top to the bottom.',
      'options': [
        {'id': 'river', 'label': 'The river piece'},
        {'id': 'park', 'label': 'The park piece'},
        {'id': 'station', 'label': 'The station piece'},
      ],
      'codeLength': 3,
      'answer': 'station,park,river',
      'hints': [
        'The first line tells you the top. The second line tells you the bottom.',
        '"Above" means higher. "Below" means lower.',
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
        'inscription': 'An arrow goes north, to the old gate of the park.',
      },
      'successMessage': 'The pieces fit!',
      'transition': [
        'The joined map has an arrow and a message:',
        '"The last piece waits by the old gate."',
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
    'title': 'The Old Gate',
    'location': 'THE OLD GATE',
    'scene': 'hydePark',
    'story': [
      'There is no time to lose!',
      'Inspector Grey calls out the way to you.',
    ],
    'letterIntro': 'Inspector Grey shouts:',
    'letter':
        'Go past the tree.\n'
        'Cross the bridge and turn left.\n'
        'Walk past the bench.\n'
        'Stop at the old gate!',
    'type': 'imageChoice',
    'question': 'Which map shows where to stop?',
    'options': [
      {'id': 'a', 'label': 'Beside the left bench', 'artwork': 'parkMapB'},
      {'id': 'b', 'label': 'At the old gate', 'artwork': 'parkMapD'},
      {'id': 'c', 'label': 'Beside the right bench', 'artwork': 'parkMapA'},
      {'id': 'd', 'label': 'Under the tree', 'artwork': 'parkMapC'},
    ],
    'answer': 'b',
    'hints': [
      'This time you turn the other way after the bridge.',
      'Do not stop at the bench. Walk past it, to the end of the path.',
    ],
    'evidence': {
      'id': 'ep07_e4',
      'name': 'The Old London Map',
      'icon': 'map',
      'description': 'All the pieces together again.',
      'inscription': 'Nine small ravens are drawn around Platform 9.',
    },
    'successMessage': 'You found the lost map!',
    'skills': ['reading', 'problemSolving'],
    'mapX': 0.7,
    'mapY': 0.12,
  },
  'glossary': {
    'directions': '길 안내',
    'past': '~을 지나서',
    'turn': '돌다',
    'right': '오른쪽',
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
    'above': '~위에',
    'below': '~아래에',
    'garden': '정원',
    'instructions': '설명, 지시',
    'cross': '건너다',
    'keeper': '관리인',
    'lodge': '관리소',
    'worried': '걱정하는',
    'shouts': '외친다',
  },
};
