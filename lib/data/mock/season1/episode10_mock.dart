/// Case 10 — The London Raven (Tower of London). Theme: words, order and a
/// hidden message. A raven brings one word every morning. The player finds
/// which raven it is, puts the words in the order of the days, reads the
/// place they describe, and finally builds the full warning sentence
/// (who → will do what → to what → when).
const Map<String, dynamic> episode10Json = {
  'id': 'ep10',
  'number': 10,
  'title': 'The London Raven',
  'synopsis': [
    'Every morning at seven, a raven flies to your window.',
    'It brings one small paper with one word on it.',
    'Put the words together. Someone is sending you a message.',
  ],
  'objectives': ['Find the raven that brings the words.', 'Read the hidden message.'],
  // The place the intro opens on (its picture behind the story lines).
  'introScene': 'towerOfLondon',
  'intro': [
    'Tower of London, 7:00 AM...',
    'For four mornings, a raven has come to your window.',
    'Each time, it drops a small piece of paper.',
    'Each paper has only one word.',
    'Somebody at the Tower is sending you a secret message.',
  ],
  'caseSummary': 'You put the raven\'s words in order and read the secret warning.',
  'keyWords': ['Monday', 'north', 'message'],
  'hook': 'The Ravenmaster whispers: "Find the Shadow. He knows the whole plan."',
  'missions': [
    {
      'id': 'ep10_m1',
      'number': 1,
      'title': 'Which Raven?',
      'location': 'TOWER GREEN',
      'scene': 'raven',
      'story': [
        'Seven ravens hop across the green grass.',
        'Which one comes to your window?',
      ],
      'letterIntro': 'The Ravenmaster tells you about his ravens.',
      'letter':
          'Jubilee is the biggest raven.\n'
          'Merlin has a white feather on her wing.\n'
          'Poppy is the smallest. She has a gold ring on her leg.\n'
          'Harris is very noisy, and he never flies far.\n\n'
          'Your raven is small, quiet and has a gold ring.',
      'type': 'multipleChoice',
      'question': 'Which raven brings the words?',
      'options': [
        {'id': 'a', 'label': 'Jubilee'},
        {'id': 'b', 'label': 'Merlin'},
        {'id': 'c', 'label': 'Poppy'},
        {'id': 'd', 'label': 'Harris'},
      ],
      'answer': 'c',
      'hints': [
        'Match each thing you know: small, quiet, a gold ring.',
        'Which raven is the smallest? Does she have a ring?',
      ],
      'clue': {
        'id': 'ep10_c1',
        'title': 'The Gold Ring',
        'value': 'Poppy',
        'symbol': 'raven',
        'note': 'Poppy, the smallest raven, brings the words.',
      },
      'evidence': {
        'id': 'ep10_e1',
        'name': "Poppy's Ring",
        'icon': 'raven',
        'description': 'A tiny gold ring on her leg.',
        'inscription': 'Letters inside: R.M.',
      },
      'successMessage': 'It is Poppy!',
      'transition': [
        'R.M. ... Raven Master?',
        'You look at the four papers Poppy brought.',
        'You wrote the day on each one.',
      ],
      'nextMissionId': 'ep10_m2',
      'skills': ['reading', 'vocabulary'],
      'mapX': 0.28,
      'mapY': 0.66,
    },
    {
      'id': 'ep10_m2',
      'number': 2,
      'title': 'Four Mornings',
      'location': 'THE WALL WALK',
      'scene': 'raven',
      'story': [
        'You spread the four papers on the old stone wall.',
        'The wind almost blows them away!',
      ],
      'letterIntro': 'Your notes say:',
      'letter':
          'On Wednesday, the word was BRIDGE.\n'
          'On Monday, the word was NORTH.\n'
          'The Thursday word was THREE.\n'
          'On Tuesday: TOWER.',
      'type': 'sequence',
      'question': 'Put the words in the order they came, starting with Monday.',
      'options': [
        {'id': 'bridge', 'label': 'BRIDGE'},
        {'id': 'three', 'label': 'THREE'},
        {'id': 'north', 'label': 'NORTH'},
        {'id': 'tower', 'label': 'TOWER'},
      ],
      'codeLength': 4,
      'answer': 'north,tower,bridge,three',
      'hints': [
        'The days of the week go: Monday, Tuesday, Wednesday, Thursday...',
        'Find the Monday word first. Then find the word for the next day.',
      ],
      'clue': {
        'id': 'ep10_c2',
        'title': 'Four Words',
        'value': 'North Tower',
        'symbol': 'feather',
        'note': 'NORTH · TOWER · BRIDGE · THREE',
      },
      'evidence': {
        'id': 'ep10_e2',
        'name': 'Raven Papers',
        'icon': 'feather',
        'description': 'Four small papers, four words.',
        'inscription': 'NORTH · TOWER · BRIDGE · THREE',
      },
      'successMessage': 'NORTH · TOWER · BRIDGE · THREE',
      'transition': [
        'North tower... bridge... three...',
        'A bridge with towers? Near the Tower of London?',
        'You look out over the river.',
      ],
      'nextMissionId': 'ep10_m3',
      'skills': ['vocabulary', 'reading'],
      'mapX': 0.72,
      'mapY': 0.44,
    },
    {
      'id': 'ep10_m3',
      'number': 3,
      'title': 'The Meeting Place',
      'location': 'BY THE RIVER',
      'scene': 'towerOfLondon',
      'story': [
        'From the Tower wall, you can see the river Thames.',
        'Boats go under the bridges.',
      ],
      'letterIntro': 'The Ravenmaster points and says:',
      'letter':
          'Look for a BRIDGE with two tall TOWERS.\n'
          'It is next to the Tower of London.\n'
          'Its road can open in the middle to let big ships through.\n\n'
          'Meet me at the NORTH tower at THREE o\'clock.',
      'type': 'imageChoice',
      'question': 'Which place is the message about?',
      'options': [
        {'id': 'a', 'label': 'London Eye', 'artwork': 'londonEye'},
        {'id': 'b', 'label': 'Big Ben', 'artwork': 'bigBen'},
        {'id': 'c', 'label': 'Tower Bridge', 'artwork': 'towerBridge'},
        {'id': 'd', 'label': "King's Cross", 'artwork': 'kingsCross'},
      ],
      'answer': 'c',
      'hints': [
        'The place is a bridge. Look for water under it.',
        'Count the towers. You need two.',
      ],
      'clue': {
        'id': 'ep10_c3',
        'title': 'The North Tower',
        'value': "3 o'clock",
        'symbol': 'clock',
        'note': "Meet at the north tower of the bridge at three o'clock.",
      },
      'evidence': {
        'id': 'ep10_e3',
        'name': "Ravenmaster's Letter",
        'icon': 'letter',
        'description': 'Given to you at the north tower.',
        'inscription': '"The Clockmaker watches me. So Poppy speaks for me."',
      },
      'successMessage': 'Tower Bridge!',
      'transition': [
        "At three o'clock, the Ravenmaster is waiting at the north tower.",
        '"I could not speak," he says. "The Clockmaker is watching me."',
        '"Poppy has one last bag of words for you."',
      ],
      'nextMissionId': 'ep10_final',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.3,
      'mapY': 0.24,
    },
  ],
  'finalMission': {
    'id': 'ep10_final',
    'number': 4,
    'title': "The Raven's Message",
    'location': 'TOWER BRIDGE',
    'scene': 'raven',
    'story': [
      'Poppy lands on the bridge with a small bag in her beak.',
      'Inside are four papers. This time, each has a few words.',
    ],
    'letterIntro': 'The Ravenmaster says:',
    'letter':
        'Make one sentence.\n\n'
        'First: WHO?\n'
        'Next: what WILL they do?\n'
        'Then: to WHAT?\n'
        'Last: WHEN?',
    'type': 'sequence',
    'question': 'Put the papers in order to read the warning.',
    'options': [
      {'id': 'midnight', 'label': 'AT MIDNIGHT'},
      {'id': 'bigben', 'label': 'BIG BEN'},
      {'id': 'clockmaker', 'label': 'THE CLOCKMAKER'},
      {'id': 'stop', 'label': 'WILL STOP'},
    ],
    'codeLength': 4,
    'answer': 'clockmaker,stop,bigben,midnight',
    'hints': [
      '"Who?" is a person. "When?" is a time.',
      'Start with the person. End with the time.',
    ],
    'evidence': {
      'id': 'ep10_e4',
      'name': "The Raven's Warning",
      'icon': 'feather',
      'description': 'Poppy\'s last message.',
      'inscription': 'THE CLOCKMAKER WILL STOP BIG BEN AT MIDNIGHT.',
    },
    'successMessage': 'You read the warning!',
    // After the case is closed: the post-case story scene (existing facts
    // only — the Shadow is not named: Case 11 unmasks him).
    'transition': [
      'The warning is clear.',
      'THE CLOCKMAKER WILL STOP\nBIG BEN AT MIDNIGHT.',
      'The Ravenmaster whispers:\n"The Clockmaker is watching me."',
      'There is not much time.',
      'Then you remember an old ticket:',
      'ROW R\nSEAT 17.',
    ],
    'skills': ['reading', 'vocabulary'],
    'mapX': 0.74,
    'mapY': 0.82,
  },
  'glossary': {
    'raven': '까마귀',
    'ravens': '까마귀들',
    'biggest': '가장 큰',
    'smallest': '가장 작은',
    'wing': '날개',
    'ring': '반지, 고리',
    'leg': '다리',
    'noisy': '시끄러운',
    'quiet': '조용한',
    'hop': '깡충 뛰다',
    'spread': '펼치다',
    'wednesday': '수요일',
    'monday': '월요일',
    'thursday': '목요일',
    'tuesday': '화요일',
    'north': '북쪽',
    'bridge': '다리',
    'towers': '탑들',
    'river': '강',
    'ships': '배들',
    'through': '~을 통과하여',
    'meet': '만나다',
    'beak': '부리',
    'sentence': '문장',
    'warning': '경고',
    'midnight': '자정',
    'spoke': '말했다',
    'speak': '말하다',
    'watching': '지켜보는',
    'message': '메시지',
  },
};
