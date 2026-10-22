/// Season 2, Case 06 — The Letter That Never Arrived (the Louvre post
/// room, Paris). Theme: held is not stolen; follow the record, not the
/// worry.
///
/// Case 05 ended on the post's slips: letter No. 4417 was collected and
/// sorted on 16 May, then HELD at the Louvre post room at 4:00 PM. It was
/// never delivered. Who stopped it? And why?
///
/// Every step is played on the case's own pictures (waiting for them: the
/// case is not in the game until they are), with the rules of
/// `season2_case06_scenes.dart`:
/// 1. Four paper tags on the post room's hold rack, turned over to read
///    both sides. A is a PARCEL No. 4417, B is letter No. 4471; ink hides
///    one digit on C and on D, so only their backs tell them apart: C was
///    held on 15 May, D on 16 May at 4:00 PM, PRESERVATION ORDER: keep it
///    safe. It was never stolen.
/// 2. The post room book: held on 16 May, moved on 17 May in the morning.
///    The porter's note on the building's plan: down the stairs, past the
///    statue, the second door on the left (the letter token is moved one
///    step at a time). Door E: the archive.
/// 3. The archive's drawers by their labels (LETTERS 4400–4599, not the
///    parcels'); in it, three torn envelopes with no number left on them.
///    The torn corner from Clock III (Case 05), its label No. 4417, fits
///    one. On its seal, a tiny drawing of a grand building.
/// 4. The letter: two lines and a drawing. The drawing (a dome, statues on
///    the roof, arched windows) and "the show remembers" match one building
///    on the map of Paris: the Palais Garnier, the opera house. On the back:
///    OPERA ARCHIVE · FILE 3–4 (Case 07).
///
/// Who wrote the letter, who gave the Preservation Order and why, who moved
/// the letter, and what was removed stay untold (the bible's "THE RECORD
/// WAS REMOVED" is kept for later in the season). Nobody at the post is
/// blamed: holding a letter, moving it and stealing it are three things.
const Map<String, dynamic> season2Episode06Json = {
  'id': 's2_ep06',
  'seasonId': 's2_paris',
  'number': 6,
  'title': 'The Letter That Never Arrived',
  'place': 'LOUVRE POST ROOM',
  'synopsis': [
    'Letter No. 4417 was held at the Louvre post room.',
    'Now it is not there.',
    'Was it stolen? Or is it hidden?',
  ],
  'objectives': [
    'Find the tag of Letter 4417.',
    'Follow the letter through the building.',
    'Find the letter and read its secret.',
  ],
  'introScene': 'louvrePostRoom',
  'intro': [
    'Letter No. 4417 stopped at the Louvre post room.',
    'It was held there. It was never delivered.',
    'You follow its trail to a small door near the Louvre.',
    'Behind it is a quiet post room. Nobody is at the desk.',
    'Letter 4417 should be here.',
  ],
  'caseSummary':
      "You turned over the tags, followed the porter's note to the archive, fitted the torn corner to its envelope and read the letter. It was never stolen. Someone kept it safe.",
  'keyWords': ['tag', 'parcel', 'keep it safe', 'past', 'second', 'left', 'torn', 'show'],
  'hook': 'What is in File 3–4 of the opera archive?',
  'missions': [
    {
      'id': 's2_ep06_m1',
      'number': 1,
      'title': 'Find Letter 4417',
      'location': 'THE HOLD RACK',
      'scene': 'holdRack',
      'story': [
        'Behind the desk is a wooden rack with many slots.',
        'One slot is empty.',
        'Paper tags hang on four slots. Each tag has two sides.',
        'Look closely. Which one matches our clue?',
      ],
      'letterIntro': "The Letter's Trail in your notebook says:",
      'letter': 'LETTER No. 4417\n16 MAY · 4:00 PM\nHELD · LOUVRE POST ROOM',
      // The tag whose both sides fit the Letter's Trail (Case 05's slip).
      'type': 'multipleChoice',
      'question': 'Which tag is for Letter 4417?',
      'options': [
        {
          'id': 'a',
          'label': 'Tag A',
          'feedback': 'Read the first word. Is it a LETTER or a PARCEL?',
        },
        {
          'id': 'b',
          'label': 'Tag B',
          'feedback': 'Read the number slowly. Is it 4417?',
        },
        {
          'id': 'c',
          'label': 'Tag C',
          'feedback': 'Turn it over. Check the day and the time.',
        },
        {'id': 'd', 'label': 'Tag D'},
      ],
      'answer': 'd',
      'hints': [
        "Read each tag's front. Is it a LETTER? Is the number 4417?",
        'Ink hides a number on two tags. Turn them over. Check the day and the time.',
      ],
      'clue': {
        'id': 's2_ep06_c1',
        'title': 'Kept Safe',
        'value': 'PRESERVATION ORDER',
        'symbol': 'letter',
        'note': 'The tag of Letter 4417: 16 MAY · 4:00 PM · HELD. PRESERVATION ORDER: keep it safe.',
      },
      'evidence': {
        'id': 's2_ep06_e1',
        'name': 'The Hold Tag',
        'icon': 'ticket',
        'description': 'Found on the hold rack of the Louvre post room.',
        'inscription':
            'LETTER No. 4417 · 16 MAY · 4:00 PM · HELD. PRESERVATION ORDER: Keep it safe. Do not send it. Do not throw it away.',
      },
      'successMessage': "Wait! It wasn't stolen.",
      'transition': [
        'The back of Tag D says PRESERVATION ORDER.',
        'That means: keep it safe.',
        'Someone kept it safe.',
        'But where is it now?',
      ],
      'nextMissionId': 's2_ep06_m2',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.5,
      'mapY': 0.2,
    },
    {
      'id': 's2_ep06_m2',
      'number': 2,
      'title': 'Follow the Letter',
      'location': 'THE PLAN ON THE WALL',
      'scene': 'archiveFloorPlan',
      'story': [
        'The post room book has two lines for Letter 4417.',
        '16 MAY · 4:00 PM · HELD.',
        '17 MAY · MORNING · MOVED.',
        'First it was held. The next morning, it was moved.',
        'A plan of the building hangs on the wall.',
      ],
      'letterIntro': "A porter's note is pinned to the plan:",
      'letter':
          'Letters that must be kept safe go downstairs.\n'
          'Go down the stairs.\n'
          'Walk past the statue.\n'
          'Take the second door on the left.',
      // The door the note names (see `season2PlanRoutes`): past the
      // statue, the second on the left.
      'type': 'multipleChoice',
      'question': 'Which door did the letter go through?',
      'options': [
        {
          'id': 'a',
          'label': 'Door A',
          'feedback': 'Not yet! Walk past the statue first.',
        },
        {
          'id': 'b',
          'label': 'Door B',
          'feedback': 'Not yet! Walk past the statue first.',
        },
        {
          'id': 'c',
          'label': 'Door C',
          'feedback': "That's the first door on the left. Count one more.",
        },
        {
          'id': 'd',
          'label': 'Door D',
          'feedback': 'That door is on the right. Which side is left?',
        },
        {'id': 'e', 'label': 'Door E'},
        {
          'id': 'f',
          'label': 'Door F',
          'feedback': 'That door is on the right. Which side is left?',
        },
      ],
      'answer': 'e',
      'hints': [
        'Move one step at a time: the stairs first, then the statue.',
        'After the statue, count only the doors on the left: one, two.',
      ],
      'clue': {
        'id': 's2_ep06_c2',
        'title': 'The Second Door',
        'value': 'THE ARCHIVE',
        'symbol': 'map',
        'note': 'Down the stairs, past the statue, the second door on the left: the archive.',
      },
      'evidence': {
        'id': 's2_ep06_e2',
        'name': "The Porter's Note",
        'icon': 'letter',
        'description': 'Pinned to the plan of the building, in the post room.',
        'inscription':
            'Letters that must be kept safe go downstairs: down the stairs, past the statue, the second door on the left. '
            '17 MAY, morning: Letter No. 4417 moved to the archive.',
      },
      'successMessage': 'The letter went to the archive!',
      'transition': [
        'Behind the second door on the left is the archive.',
        'Tall cabinets. Hundreds of small drawers.',
        'Letter 4417 must be here somewhere.',
      ],
      'nextMissionId': 's2_ep06_m3',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.56,
      'mapY': 0.16,
    },
    {
      'id': 's2_ep06_m3',
      'number': 3,
      'title': 'The Hidden Envelope',
      'location': 'THE ARCHIVE',
      'scene': 'archiveRoom',
      'story': [
        'Each drawer in the archive has a label.',
        'Torn letters are kept here, safe and flat.',
        'But a torn letter often loses its number.',
      ],
      'letterIntro': 'Inside Clock III, you found a torn envelope corner. Its label says:',
      'letter': 'No. 4417\n\nFind the envelope it was torn from.',
      // The envelope whose torn edge the corner from Clock III fits.
      'type': 'multipleChoice',
      'question': 'Which envelope is Letter 4417?',
      'options': [
        {
          'id': 'x',
          'label': 'Envelope 1',
          'feedback': 'The torn edges do not match. Try another one.',
        },
        {'id': 'y', 'label': 'Envelope 2'},
        {
          'id': 'z',
          'label': 'Envelope 3',
          'feedback': 'Look at the torn edge. Does the corner fit there?',
        },
      ],
      'answer': 'y',
      'hints': [
        'Find the drawer first. Is it for letters? Is 4417 between its two numbers?',
        'Lay the torn corner on each envelope. Only one torn edge fits.',
      ],
      'clue': {
        'id': 's2_ep06_c3',
        'title': 'A Perfect Fit',
        'value': 'LETTER No. 4417',
        'symbol': 'letter',
        'note': 'The torn corner from Clock III fits one envelope. On its seal: a tiny picture of a building.',
      },
      'evidence': {
        'id': 's2_ep06_e3',
        'name': 'The Torn Envelope',
        'icon': 'letter',
        'description': 'Found in a drawer of the archive.',
        'inscription':
            'The corner from Clock III fits it exactly: Letter No. 4417. On its seal, a tiny drawing of a grand building.',
      },
      'successMessage': 'There it is! Letter 4417!',
      'transition': [
        'The corner fits. This is Letter 4417!',
        "But what's this little picture on the seal?",
        'A grand building, drawn very small.',
        'You open the envelope. Inside is a letter.',
      ],
      'nextMissionId': 's2_ep06_final',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.62,
      'mapY': 0.22,
    },
  ],
  'finalMission': {
    'id': 's2_ep06_final',
    'number': 4,
    'title': 'The Secret in the Letter',
    'location': 'THE ARCHIVE TABLE',
    'scene': 'archiveRoom',
    'story': [
      'You unfold the letter on the table.',
      'It has only two lines, and a small drawing.',
      'The same building as on the seal.',
      'A map of Paris hangs on the wall.',
    ],
    'letterIntro': 'The letter says:',
    'letter': 'The clocks may lie.\nBut the show remembers.',
    // The building on the map that the drawing shows (see
    // `season2LetterMaps`); ids are the map's landmarks.
    'type': 'multipleChoice',
    'question': 'Which building is in the drawing?',
    'options': [
      {
        'id': 'montmartre',
        'label': 'Montmartre',
        'feedback': 'Its church has domes, but no statues on the roof.',
      },
      {
        'id': 'louvre',
        'label': 'Louvre',
        'feedback': 'We are at the Louvre already. Look at the roof in the drawing.',
      },
      {
        'id': 'arcDeTriomphe',
        'label': 'Arc de Triomphe',
        'feedback': 'That is a big arch. The drawing has a dome.',
      },
      {
        'id': 'gareDuNord',
        'label': 'Gare du Nord',
        'feedback': 'That is a station. Trains, not shows!',
      },
      {
        'id': 'notreDame',
        'label': 'Notre-Dame',
        'feedback': 'Look at its two tall towers. The drawing has a dome.',
      },
      {
        'id': 'eiffelTower',
        'label': 'Eiffel Tower',
        'feedback': 'The tower has no dome and no statues.',
      },
      {'id': 'palaisGarnier', 'label': 'Palais Garnier'},
    ],
    'answer': 'palaisGarnier',
    'hints': [
      'Look at the top of the drawing. What shape is the roof? What stands on it?',
      'The letter says "the show remembers". Where do people go to see a show?',
    ],
    'evidence': {
      'id': 's2_ep06_e4',
      'name': 'The Letter',
      'icon': 'letter',
      'description': 'Letter No. 4417, found in the archive.',
      'inscription':
          'The clocks may lie. But the show remembers. A drawing of the Palais Garnier. On the back: OPERA ARCHIVE · FILE 3–4.',
    },
    'successMessage': 'We found our next clue!',
    // After the case is closed: the post-case scene, then the case report.
    'transition': [
      'The drawing is the Palais Garnier, the opera house.',
      'You turn the letter over.',
      'On the back: OPERA ARCHIVE · FILE 3–4.',
      'The mystery continues at the opera house!',
    ],
    'skills': ['problemSolving', 'reading'],
    'mapX': 0.55,
    'mapY': 0.12,
  },
  'glossary': {
    'held': '보관됐다, 멈춰 있었다',
    'delivered': '배달됐다',
    'stolen': '도난당한',
    'hidden': '숨겨진',
    'trail': '지나간 길, 흔적',
    'desk': '책상, 접수대',
    'rack': '선반, 걸이',
    'slots': '칸들',
    'slot': '칸',
    'empty': '빈',
    'tag': '꼬리표',
    'tags': '꼬리표들',
    'sides': '면들',
    'closely': '자세히',
    'matches': '맞다, 일치하다',
    'clue': '단서',
    'parcel': '소포',
    'ink': '잉크',
    'hides': '가린다, 숨긴다',
    'turn': '돌리다, 뒤집다',
    'preservation': '보존',
    'order': '지시, 명령',
    'safe': '안전한',
    'throw': '던지다 (throw away: 버리다)',
    'moved': '옮겨졌다',
    'morning': '아침',
    'plan': '평면도',
    'porter': '짐꾼, 우편 운반원',
    'pinned': '핀으로 꽂힌',
    'downstairs': '아래층으로',
    'stairs': '계단',
    'past': '~을 지나',
    'statue': '조각상',
    'second': '두 번째',
    'left': '왼쪽',
    'right': '오른쪽',
    'count': '세다',
    'archive': '기록 보관실',
    'cabinets': '보관장들',
    'drawers': '서랍들',
    'drawer': '서랍',
    'label': '이름표, 라벨',
    'torn': '찢어진',
    'flat': '평평하게',
    'loses': '잃어버린다',
    'envelope': '봉투',
    'corner': '모서리',
    'edge': '가장자리',
    'edges': '가장자리들',
    'fits': '꼭 맞는다',
    'seal': '봉인',
    'grand': '웅장한',
    'unfold': '펼치다',
    'drawing': '그림',
    'lie': '거짓말하다',
    'show': '공연',
    'remembers': '기억한다',
    'dome': '둥근 지붕',
    'roof': '지붕',
    'statues': '조각상들',
    'station': '역',
    'towers': '탑들',
    'arch': '아치, 둥근 문',
    'opera': '오페라',
  },
};
