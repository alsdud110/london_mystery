/// Case 02 — The Silent Clock (Westminster / Big Ben). Theme: time.
///
/// Final case design: Big Ben must be restarted at the exact time the thief
/// plans to strike. That time is only written on the Time Card (Mission 03),
/// and reading it needs the "before / after / then" words of its note.
/// 8:17 itself turns out to be a message: Gallery 8, Picture 17 (→ Case 03).
const Map<String, dynamic> episode02Json = {
  'id': 'ep02',
  'number': 2,
  'title': 'The Silent Clock',
  'synopsis': [
    'Big Ben has stopped. Its hands do not move.',
    'A clock does not stop by itself.',
    'Why did it stop at that minute? The answer is hidden in the tower.',
  ],
  'objectives': ['Find out why the clock stopped.', 'Start Big Ben again.'],
  // The place the intro opens on (its picture behind the story lines).
  'introScene': 'bigBen',
  'intro': [
    'London, early in the morning...',
    'The Crown is safe again. But this morning, London is too quiet.',
    'Big Ben has stopped.',
    'Its hands are frozen. Nobody heard the bell.',
    'A clock does not stop by itself. Someone stopped it.',
  ],
  'caseSummary': 'You read the frozen clock, found the missing gear and started Big Ben again.',
  'keyWords': ['minute', 'before', 'after'],
  'hook': 'A small raven is stamped on the gear. Who are the ravens?',
  'missions': [
    {
      'id': 'ep02_m1',
      'number': 1,
      'title': 'The Frozen Hands',
      'location': 'WESTMINSTER BRIDGE',
      'scene': 'clockFace',
      'story': [
        'You stand on Westminster Bridge and look up at Big Ben.',
        'The great clock is silent. Its hands do not move.',
      ],
      'letterIntro': 'Mrs Bell, the clockkeeper, gives you her notebook.',
      'letter':
          'Detective,\n\n'
          'I looked at the clock at the moment it stopped.\n'
          'The hour hand was between eight and nine.\n'
          'The minute hand was on the three...\n'
          'and then it moved two more small marks.\n\n'
          '— Mrs Bell, Clockkeeper',
      'type': 'numberCode',
      'question': 'What time did Big Ben stop? Type the hour and the minutes.',
      'codeLength': 3,
      'answer': '817',
      'hints': [
        'Every big number on a clock is five minutes. The three means fifteen minutes.',
        'The hour is the smaller number: eight. Now add two small marks to fifteen minutes.',
      ],
      'clue': {
        'id': 'ep02_c1',
        'title': '8:17',
        'value': '8:17',
        'symbol': 'clock',
        'note': 'Big Ben stopped at 8:17. That is no accident.',
      },
      'evidence': {
        'id': 'ep02_e1',
        'name': 'Broken Clock Note',
        'icon': 'clock',
        'description': "The clockkeeper's page.",
        'inscription': 'STOPPED AT 8:17',
      },
      'successMessage': 'Big Ben stopped at 8:17.',
      'transition': [
        'Mrs Bell opens a small door at the bottom of the tower.',
        'Three hundred steps go up into the dark.',
        'The answer is inside the clock.',
      ],
      'nextMissionId': 'ep02_m2',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.72,
      'mapY': 0.74,
    },
    {
      'id': 'ep02_m2',
      'number': 2,
      'title': 'The Missing Gear',
      'location': 'THE CLOCK ROOM',
      'scene': 'bigBen',
      'story': [
        'Behind the four clock faces, big wheels and gears fill the room.',
        'One small gear is missing. That is why the clock stopped!',
      ],
      'letterIntro': 'A note is pinned to the empty place.',
      'letter':
          'Dear Detective,\n\n'
          'A clock needs every gear to turn.\n'
          'I took one small brass gear.\n\n'
          'I did not take it far.\n'
          'It is not under the biggest bell.\n'
          'It is under the smallest bell.\n\n'
          '— R.',
      'type': 'multipleChoice',
      'question': 'Where is the missing gear?',
      'options': [
        {'id': 'a', 'label': 'Under the biggest bell'},
        {'id': 'b', 'label': 'Behind the clock face'},
        {'id': 'c', 'label': 'Under the smallest bell'},
        {'id': 'd', 'label': 'On the stairs'},
      ],
      'answer': 'c',
      'hints': [
        'Read the last two lines of the note again. One says "not".',
        "Big and small are opposites. The gear is not with the big one.",
      ],
      'clue': {
        'id': 'ep02_c2',
        'title': 'A Raven Stamp',
        'value': 'R.',
        'symbol': 'raven',
        'note': 'The thief signs with an R. A raven is stamped on the gear.',
      },
      'evidence': {
        'id': 'ep02_e2',
        'name': 'Small Brass Gear',
        'icon': 'gear',
        'description': 'The gear that stopped Big Ben.',
        'inscription': 'A tiny raven is stamped on it.',
      },
      'successMessage': 'You found the missing gear!',
      'transition': [
        'You hold the brass gear up to the light.',
        'A small card falls out of the smallest bell.',
        'It is covered with numbers and times.',
      ],
      'nextMissionId': 'ep02_m3',
      'skills': ['reading', 'vocabulary'],
      'mapX': 0.26,
      'mapY': 0.52,
    },
    {
      'id': 'ep02_m3',
      'number': 3,
      'title': 'The Time Card',
      'location': 'THE BELFRY',
      'scene': 'clockFace',
      'story': [
        'At the top of the tower, the five great bells hang in the wind.',
        'The card from the smallest bell is a time card.',
      ],
      'letterIntro': 'On the back of the card, the thief wrote a plan.',
      'letter':
          'MY PLAN\n\n'
          'After I stop the clock, I walk to the museum.\n'
          'Before the doors open, I hide in Gallery 8.\n'
          'Then, at 9:17, I take Picture 17.\n\n'
          'But first of all, I stop Big Ben.\n'
          '— R.',
      'type': 'sequence',
      'question': 'Put the plan in the right order.',
      'options': [
        {'id': 'hide', 'label': 'Hide in Gallery 8'},
        {'id': 'stop', 'label': 'Stop Big Ben'},
        {'id': 'take', 'label': 'Take Picture 17'},
        {'id': 'walk', 'label': 'Walk to the museum'},
      ],
      'codeLength': 4,
      'answer': 'stop,walk,hide,take',
      'hints': [
        'Look for the words "first of all", "after", "before" and "then".',
        '"First of all" is the start. "Then" comes at the end.',
      ],
      'clue': {
        'id': 'ep02_c3',
        'title': 'Picture 17',
        'value': '9:17',
        'symbol': 'ticket',
        'note': 'The thief will take Picture 17 at 9:17.',
      },
      'evidence': {
        'id': 'ep02_e3',
        'name': 'Time Card',
        'icon': 'ticket',
        'description': "The thief's plan.",
        'inscription': 'GALLERY 8 · PICTURE 17 · 9:17',
      },
      'successMessage': 'You read the whole plan!',
      'transition': [
        'Gallery 8. Picture 17.',
        '8... 17... The clock stopped at 8:17!',
        'The time was a message. Quick — start the clock!',
      ],
      'nextMissionId': 'ep02_final',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.7,
      'mapY': 0.3,
    },
  ],
  'finalMission': {
    'id': 'ep02_final',
    'number': 4,
    'title': 'The Great Clock',
    'location': 'INSIDE BIG BEN',
    'scene': 'clockFace',
    'story': [
      'You put the brass gear back in its place.',
      'The great wheels are ready to turn again.',
    ],
    'letterIntro': 'Mrs Bell whispers to you.',
    'letter':
        'Clever detective!\n\n'
        'Set the hands to the time the thief will take the picture.\n'
        'When Big Ben rings at that time, the museum guards will hear it\n'
        'and they will be ready.\n\n'
        'Look at the Time Card in your notebook.',
    'type': 'finalCode',
    'question': 'Set the time on the Great Clock.',
    'codeLength': 3,
    'answer': '917',
    'hints': [
      'The Time Card says when the thief takes Picture 17.',
      'It is one hour after the clock stopped. The minutes are the same.',
    ],
    'evidence': {
      'id': 'ep02_e4',
      'name': 'Raven Feather',
      'icon': 'feather',
      'description': 'Found inside the clock.',
      'inscription': 'A black feather. The same raven as on the gear.',
    },
    'successMessage': 'Big Ben rings again!',
    // After the case is closed: the post-case story scene (existing facts only).
    'transition': [
      'Big Ben rings again.',
      'In your hand is a black feather.',
      'A raven.',
      'The same raven was stamped on the gear.',
      'And the time was not just a time.',
      'It was a message.',
      'At the museum,\nthe guards hear the bell.',
    ],
    'skills': ['problemSolving', 'reading'],
    'mapX': 0.36,
    'mapY': 0.12,
  },
  'glossary': {
    'frozen': '얼어붙은, 멈춘',
    'silent': '조용한, 소리 없는',
    'clockkeeper': '시계 관리인',
    'hour': '시간(시)',
    'minute': '분',
    'hand': '(시계) 바늘',
    'hands': '(시계) 바늘들',
    'between': '~사이에',
    'marks': '눈금들',
    'gear': '톱니바퀴',
    'gears': '톱니바퀴들',
    'brass': '놋쇠',
    'wheels': '바퀴들',
    'biggest': '가장 큰',
    'smallest': '가장 작은',
    'bell': '종',
    'bells': '종들',
    'belfry': '종탑',
    'stamped': '찍힌, 새겨진',
    'raven': '까마귀',
    'plan': '계획',
    'before': '~전에',
    'after': '~후에',
    'then': '그다음에',
    'gallery': '전시실',
    'hide': '숨다',
    'museum': '박물관',
    'whispers': '속삭이다',
    'guards': '경비원들',
    'accident': '사고, 우연',
    'feather': '깃털',
    'stairs': '계단',
  },
};
