/// Season 2, Case 07 — The Phantom Performance (the Palais Garnier, Paris).
/// Theme: two records, two start times; trust the record that did not
/// change.
///
/// Case 06 ended on the back of the letter: OPERA ARCHIVE · FILE 3–4. In
/// the opera archive, FILE 3 (the office record of show No. 34, The Golden
/// Nightingale) says CURTAIN UP · 3:00 PM; FILE 4 (its programme) gives
/// only the show's parts.
///
/// Every step is played on the case's own pictures, with the rules of
/// `season2_case07_scenes.dart`:
/// 1. The show's strip (2 hours 10 minutes, as FILE 4 lists its parts) slid
///    along the clock: in after the doors open (3:30), down at CURTAIN DOWN
///    (6:10). It fits only from 4:00.
/// 2. The lighting desk at the back of the hall: the stage lit like the old
///    photo marked "3:00 PM · CURTAIN UP!" is the ghost light alone, an
///    empty stage. The Lighting Book's cue card for show No. 34: CURTAIN UP ·
///    4:00. A scrap in it: a small clock above a red door.
/// 3. The rope rail: of four painted backdrops, only one has a small clock
///    right above a red door (Case 02's Painted Street). Behind it, in a
///    pocket: the Amendment Slip, FILE 3 · CURTAIN UP: 4:00 to 3:00, stamped
///    with a clock with no hands in a ring of leaves. No name.
/// 4. FILE 3 on the light table: a patch over CURTAIN UP, 3:00 PM on it,
///    4:00 PM under it. The slip's two times pinned to the change.
///
/// Who changed the record and why, who left the scrap, why the slip was
/// behind the backdrop, and whether P. painted it stay untold. No name or
/// initials of anyone behind the change are shown. Nothing of time itself
/// vanished: only a record was changed.
const Map<String, dynamic> season2Episode07Json = {
  'id': 's2_ep07',
  'seasonId': 's2_paris',
  'number': 7,
  'title': 'The Phantom Performance',
  'place': 'PALAIS GARNIER',
  'synopsis': [
    'The letter said: the show remembers.',
    'In the opera archive, one show has two start times.',
    'They are one hour apart. Which one is true?',
  ],
  'objectives': [
    "Test the show's times.",
    'Light the stage like the old photo.',
    'Find what was changed, and prove it.',
  ],
  'introScene': 'palaisGarnierNight',
  'intro': [
    'The letter led you to the Palais Garnier.',
    'On its back: OPERA ARCHIVE · FILE 3–4.',
    'Tonight the opera house is dark. The archive is under the roof.',
    'One box on the table says: FILE 3–4.',
  ],
  'caseSummary': 'The show began at 4:00. Later, someone covered FILE 3 with 3:00.',
  'keyWords': ['programme', 'doors open', 'curtain up', 'ghost light', 'cue', 'above', 'patch', 'changed'],
  'hook': 'What did P. see — and what was in the bag?',
  'missions': [
    {
      'id': 's2_ep07_m1',
      'number': 1,
      'title': 'The Show Strip',
      'location': 'THE ARCHIVE TABLE',
      'scene': 'operaArchive',
      'story': [
        'FILE 3 is the office record of one show.',
        "FILE 4 is the show's programme.",
      ],
      'letterIntro': 'Inside FILE 3–4:',
      'letter':
          'FILE 3 · THE GOLDEN NIGHTINGALE · PERFORMANCE No. 34\n'
          'DOORS OPEN · 3:30 PM\n'
          'CURTAIN UP · 3:00 PM\n'
          'CURTAIN DOWN · 6:10 PM\n\n'
          'FILE 4 · THE PROGRAMME\n'
          'OVERTURE · 10 MIN\n'
          'ACT ONE · 60 MIN\n'
          'INTERVAL · 20 MIN\n'
          'ACT TWO · 40 MIN\n'
          'THE WHOLE SHOW: 2 HOURS 10 MINUTES',
      // When the show started: only after the doors open (3:30), so 4:00.
      // Played very easy since 2026-10-27 (`season2Case07Steps`): 3:00 PM
      // or 4:00 PM, FILE 3's DOORS OPEN beside the question.
      'type': 'multipleChoice',
      'question': 'When did the show start?',
      'options': [
        {
          'id': 'office',
          'label': 'Start at 3:00',
          'feedback': "That's the office's 3:00. But the doors open at 3:30.",
        },
        {
          'id': 'early',
          'label': 'Start before the doors open',
          'feedback': 'The doors are not open yet. Nobody is in the seats.',
        },
        {
          'id': 'end',
          'label': 'End away from CURTAIN DOWN',
          'feedback': 'The audience is in. Now look at the END flag. Is it at CURTAIN DOWN?',
        },
        {'id': 'fit', 'label': 'Start at 4:00, end at 6:10'},
      ],
      'answer': 'fit',
      'hints': [
        'Read FILE 3: DOORS OPEN · 3:30 PM.',
        'The show starts after 3:30 PM.',
      ],
      'clue': {
        'id': 's2_ep07_c1',
        'title': 'Two Start Times',
        'value': '3:00 OR 4:00?',
        'symbol': 'watch',
        'note': 'FILE 3 says 3:00. But the show only fits from 4:00 to 6:10.',
      },
      'evidence': {
        'id': 's2_ep07_e1',
        'name': 'The Office Record',
        'icon': 'letter',
        'description': 'FILE 3 and FILE 4, from a box in the opera archive.',
        'inscription':
            'FILE 3: DOORS OPEN 3:30 PM · CURTAIN UP 3:00 PM · CURTAIN DOWN 6:10 PM. FILE 4: the whole show is 2 hours 10 minutes. It only fits from 4:00 to 6:10.',
      },
      'successMessage': 'It fits at 4:00!',
      'transition': [
        'The show fits only from 4:00 to 6:10.',
        'A 3:00 show would start too early and end at 5:10.',
        'An old photo is clipped to FILE 3. It says: 3:00 PM · CURTAIN UP!',
        "Is that true? Let's look at the stage.",
      ],
      'nextMissionId': 's2_ep07_m2',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.5,
      'mapY': 0.2,
    },
    {
      'id': 's2_ep07_m2',
      'number': 2,
      'title': 'The Ghost Light',
      'location': 'THE LIGHTING DESK',
      'scene': 'operaStage',
      'story': [
        'At the back of the hall is the old lighting desk.',
        'The ghost light has its own lever.',
      ],
      'letterIntro': 'The Lighting Book says:',
      'letter':
          'GHOST LIGHT: one lamp on an empty stage.\n'
          'We use it before the doors open, and at night.\n'
          'HOUSE LIGHTS: for the audience.\n'
          'FOOTLIGHTS and BIG SPOT: for the show.',
      // The stage lit like the old photo: the ghost light alone. Played
      // very easy since 2026-10-27 (`season2Case07Steps`): its one switch.
      'type': 'multipleChoice',
      'question': 'Turn on the ghost light.',
      'options': [
        {
          'id': 'ghostOff',
          'label': 'The ghost light is off',
          'feedback': 'Look at the middle of the photo. One small lamp is glowing.',
        },
        {
          'id': 'house',
          'label': 'The house lights are on',
          'feedback': 'In the photo, the seats are dark.',
        },
        {
          'id': 'foot',
          'label': 'The footlights are on',
          'feedback': 'In the photo, the front of the stage is dark.',
        },
        {
          'id': 'spot',
          'label': 'The big spot is on',
          'feedback': 'Do you see a big circle of light in the photo?',
        },
        {'id': 'match', 'label': 'Only the ghost light'},
      ],
      'answer': 'match',
      'hints': [
        'The ghost light has one lever.',
        'Tap the lever. It is lit.',
      ],
      'clue': {
        'id': 's2_ep07_c2',
        'title': 'An Empty Stage',
        'value': 'GHOST LIGHT',
        'symbol': 'mask',
        'note': 'The old photo shows only the ghost light. It was an empty stage, not a show.',
      },
      'evidence': {
        'id': 's2_ep07_e2',
        'name': 'The Stage Cue Card',
        'icon': 'ticket',
        'description': 'Kept at the lighting desk, not in the office.',
        'inscription':
            'SHOW No. 34 · CUE 1 · CURTAIN UP · 4:00. The old photo marked “3:00 PM · CURTAIN UP!” shows only the ghost light: an empty stage.',
      },
      'successMessage': 'It matches! Only the ghost light.',
      'transition': [
        'The photo shows an empty stage, not a performance.',
        'In the Lighting Book, a cue card for show No. 34:',
        'CUE 1 · CURTAIN UP · 4:00.',
        'A scrap of paper is tucked in the book.',
        'On it, a tiny drawing: a small clock above a red door.',
        'Where have you seen that before?',
      ],
      'nextMissionId': 's2_ep07_m3',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.56,
      'mapY': 0.16,
    },
    {
      'id': 's2_ep07_m3',
      'number': 3,
      'title': 'The Painted Sky',
      'location': 'THE ROPE RAIL',
      'scene': 'flyRail',
      'story': [
        'Beside the stage is the rope rail.',
        'Pull a rope, and its painted backdrop comes down.',
      ],
      'letterIntro': 'The Painted Street in your notebook says:',
      'letter': 'Above the red door: a small clock.',
      // The backdrop that has both of the Painted Street's things (see
      // `season2FlyRails`); each wrong one misses one of them.
      'type': 'multipleChoice',
      'question': 'Which backdrop matches the Painted Street?',
      'options': [
        {
          'id': 'lampRed',
          'label': 'Backdrop 1',
          'feedback': 'There is a red door. But what is above it?',
        },
        {
          'id': 'towerRed',
          'label': 'Backdrop 2',
          'feedback': 'That clock is far from the door. Look right above the door.',
        },
        {'id': 'clockRed', 'label': 'Backdrop 3'},
        {
          'id': 'clockBlue',
          'label': 'Backdrop 4',
          'feedback': 'There is a small clock. But what color is the door?',
        },
      ],
      'answer': 'clockRed',
      'hints': [
        'Open your notebook: The Painted Street. Two things must match.',
        'Lower each backdrop. Each time, look right above the door.',
      ],
      'clue': {
        'id': 's2_ep07_c3',
        'title': 'A Hidden Pocket',
        'value': '4:00 to 3:00',
        'symbol': 'frame',
        'note': 'Behind the backdrop, in a pocket: a slip to change FILE 3.',
      },
      'evidence': {
        'id': 's2_ep07_e3',
        'name': 'The Amendment Slip',
        'icon': 'seal',
        'description': 'Found in a pocket behind a painted backdrop.',
        'inscription': 'FILE 3 · PERFORMANCE No. 34 · CURTAIN UP: 4:00 to 3:00. A round stamp: a clock with no hands, in a ring of leaves. No name.',
      },
      'successMessage': 'A hidden pocket!',
      'transition': [
        "It looks like the painter's street.",
        "Did P. paint this? We can't be sure.",
        'In the pocket is an old slip:',
        'FILE 3 · PERFORMANCE No. 34 · CURTAIN UP: 4:00 to 3:00.',
        'It says to change the record. But was FILE 3 really changed?',
      ],
      'nextMissionId': 's2_ep07_final',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.62,
      'mapY': 0.22,
    },
  ],
  'finalMission': {
    'id': 's2_ep07_final',
    'number': 4,
    'title': 'The Changed Record',
    'location': 'THE ARCHIVE LIGHT TABLE',
    'scene': 'lightTable',
    'story': [
      'Back in the archive: two records, two start times.',
      'One of them was changed.',
    ],
    'letterIntro': 'The Amendment Slip says:',
    'letter': 'FILE 3 · PERFORMANCE No. 34\nCURTAIN UP: 4:00 to 3:00',
    // The slip's two times on FILE 3 (`pin:spot`): its old time under the
    // patch, its new time on the patch. Played very easy since 2026-10-27
    // (`season2Case07Steps`): FILE 3 found, the light turned on, the new
    // time chosen; the answer is as before, so saves and the archive are.
    'type': 'matchPairs',
    'question': 'What is the new time?',
    'options': [
      {'id': 'old', 'label': '4:00 on the slip'},
      {'id': 'new', 'label': '3:00 on the slip'},
    ],
    'answer': 'old:under,new:patch',
    'feedback': {
      'pick:file4': 'The programme and the stage cue card agree on 4:00. Look at the other one.',
      'old:doors': 'No extra paper on this line. Look for the patch.',
      'old:down': 'No extra paper on this line. Look for the patch.',
      'new:doors': 'No extra paper on this line. Look for the patch.',
      'new:down': 'No extra paper on this line. Look for the patch.',
      'old:unlit': 'Turn on the light first. What is under the patch?',
      'old:patch': "That's the new time on top. Where is the old one?",
      'new:under': "That's the old time, under the patch. Where is the new one?",
    },
    'hints': [
      'Find FILE 3. Then turn on the light.',
      'The new time is on the patch, on top.',
    ],
    'evidence': {
      'id': 's2_ep07_e4',
      'name': 'The Changed Record',
      'icon': 'letter',
      'description': 'FILE 3, on the light table in the opera archive.',
      'inscription':
          'FILE 3 has a patch over CURTAIN UP. On it: 3:00 PM. Under it: 4:00 PM. Who changed it, and why, is not known.',
    },
    'successMessage': 'The record was changed!',
    // After the case is closed: the post-case scene, then the case report.
    'transition': [
      'At first, FILE 3 said 4:00. Later, someone covered it with 3:00.',
      'The 3:00 show was only on paper. A phantom performance!',
      '3:00 and 4:00 again, like the notices at the Eiffel Tower.',
      "Is it the same hand? We don't know yet.",
      'On the back of the slip: a sketch of a metro sign. ABBESSES.',
      'Under it: P. KNEW THE BAG.',
      'The mystery continues in Montmartre!',
    ],
    'skills': ['problemSolving', 'reading'],
    'mapX': 0.55,
    'mapY': 0.12,
  },
  'glossary': {
    'phantom': '유령 같은, 실제로 없는',
    'performance': '공연',
    'opera': '오페라',
    'archive': '기록 보관실',
    'roof': '지붕',
    'programme': '공연 안내서, 프로그램',
    'record': '기록',
    'office': '사무실',
    'file': '서류철',
    'doors': '문들 (DOORS OPEN: 입장 시작)',
    'curtain': '막, 커튼 (CURTAIN UP: 막이 오름 / CURTAIN DOWN: 막이 내림)',
    'overture': '서곡',
    'act': '막 (공연의 한 부분)',
    'interval': '중간 휴식',
    'whole': '전체의',
    'start': '시작하다',
    'times': '시각들',
    'apart': '떨어져 (one hour apart: 한 시간 차이)',
    'fits': '꼭 맞는다',
    'audience': '관객',
    'seats': '좌석들',
    'clipped': '클립으로 끼워진',
    'photo': '사진',
    'stage': '무대',
    'hall': '공연장, 홀',
    'lighting': '조명',
    'desk': '책상, 조작대',
    'ghost': '유령 (GHOST LIGHT: 빈 무대에 켜 두는 등)',
    'lamp': '등, 램프',
    'empty': '빈',
    'footlights': '무대 앞쪽 조명',
    'spot': '스포트라이트',
    'glowing': '빛나는',
    'circle': '원',
    'matches': '맞다, 일치하다',
    'cue': '신호, 큐',
    'card': '카드',
    'scrap': '종잇조각',
    'tucked': '끼워져 있는',
    'drawing': '그림',
    'rope': '밧줄',
    'rail': '난간, 걸이대',
    'backdrop': '무대 배경막',
    'painted': '그려진',
    'pull': '당기다',
    'above': '~ 위에',
    'pocket': '주머니',
    'slip': '쪽지, 전표',
    'amendment': '수정',
    'stamp': '도장',
    'leaves': '잎들',
    'patch': '덧붙인 종이 조각',
    'changed': '바뀌었다',
    'covered': '덮었다',
    'light': '빛, 조명',
    'table': '탁자',
    'line': '줄',
    'sketch': '스케치, 밑그림',
    'metro': '지하철',
    'sign': '표지판',
    'bag': '가방',
    'painter': '화가',
    'later': '나중에',
    'notices': '안내문들',
    'hand': '손, 손글씨',
  },
};
