/// Case 12 — The Midnight Case (all of London). The season finale.
///
/// Every step leans on an earlier case: the raven gear from Big Ben
/// (Case 02), the small red clock on Platform 4 (Case 04), the seven ravens
/// (Case 05), the Brass Key "for the Clockmaker's door" (Case 05) and the
/// warning sentence (Case 10). Tips point back to those cases, so a child who
/// forgot can still go on. Final case: three locks on the Clockmaker's door;
/// the door's riddle gives them in a different order from the one the
/// numbers were found in. The Clockmaker is gone — a watch marked PARIS
/// is left behind for Season 2.
const Map<String, dynamic> episode12Json = {
  'id': 'ep12',
  'number': 12,
  'title': 'The Midnight Case',
  'synopsis': [
    "Tonight, the Clockmaker will stop London's great clock at midnight.",
    'Every case you solved was a piece of this night.',
    'Use everything you learned to stop the Raven Society.',
  ],
  'objectives': ["Stop the Clockmaker's plan.", "Open the Clockmaker's door."],
  // The place the intro opens on (its picture behind the story lines).
  'introScene': 'bigBen',
  'intro': [
    'London, 11:00 PM...',
    'The Shadow told you everything.',
    '"At midnight, the Clockmaker will stop the great clock again."',
    '"When London is silent, the Raven Society will open his secret door."',
    'You have one hour. Every case you solved will help you now.',
  ],
  'caseSummary': 'You used every clue of the season, stopped the Raven Society and saved London\'s midnight.',
  'keyWords': ['midnight', 'arrives', 'riddle'],
  'hook': 'The Clockmaker is gone. On his desk, a pocket watch is still ticking. On the back: PARIS.',
  'missions': [
    {
      'id': 'ep12_m1',
      'number': 1,
      'title': 'The Real Gear',
      'location': 'BIG BEN',
      'scene': 'clockFace',
      'story': [
        'You run up the three hundred steps of Big Ben again.',
        'On the table, there are four brass gears. Only one is real.',
      ],
      'letterIntro': 'Mrs Bell, the clockkeeper, whispers:',
      'letter':
          'The Raven Society wants to put a fake gear into the clock.\n'
          'Then it will stop at midnight.\n\n'
          'The real gear is brass.\n'
          'It has eight teeth.\n'
          'And it has the small raven stamp — the one you found in Case 02.',
      'type': 'multipleChoice',
      'question': 'Which gear is the real one?',
      'options': [
        {'id': 'a', 'label': 'Silver, eight teeth, a raven stamp'},
        {'id': 'b', 'label': 'Brass, six teeth, a raven stamp'},
        {'id': 'c', 'label': 'Brass, eight teeth, no stamp'},
        {'id': 'd', 'label': 'Brass, eight teeth, a raven stamp'},
      ],
      'answer': 'd',
      'hints': [
        'Check three things for every gear: the metal, the teeth, the stamp.',
        'Cross out each gear that gets one thing wrong.',
      ],
      'clue': {
        'id': 'ep12_c1',
        'title': 'Eight Teeth',
        'value': '8',
        'symbol': 'gear',
        'note': 'The real gear has eight teeth.',
      },
      'evidence': {
        'id': 'ep12_e1',
        'name': 'The Real Gear',
        'icon': 'gear',
        'description': 'Big Ben will not stop tonight.',
        'inscription': 'Brass · eight teeth · the raven stamp',
      },
      'successMessage': 'You kept the real gear safe!',
      'transition': [
        'Mrs Bell locks the real gear inside the clock.',
        '"The Clockmaker is coming by train tonight," she says.',
        '"Hurry to King\'s Cross!"',
      ],
      'nextMissionId': 'ep12_m2',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.72,
      'mapY': 0.74,
    },
    {
      'id': 'ep12_m2',
      'number': 2,
      'title': 'The Last Train In',
      'location': "KING'S CROSS",
      'scene': 'kingsCross',
      'story': [
        'The station is quiet. The big board shows the last trains.',
        'Inspector Grey is waiting for you.',
      ],
      'letterIntro': 'The board says:',
      'letter':
          'ARRIVALS\n'
          '10:15  from York — Platform 2\n'
          '11:04  from Edinburgh — Platform 9\n'
          '11:40  from Paris — Platform 4\n'
          '11:55  from Oxford — Platform 7\n\n'
          'Inspector Grey: "The Clockmaker always arrives\n'
          'on the platform with the small red clock."',
      'type': 'numberCode',
      'question': "What time does the Clockmaker's train arrive?",
      'codeLength': 4,
      'answer': '1140',
      'hints': [
        'Open Case 04 in your Case Archive. Which platform had the small red clock?',
        'Find that platform on the board. Type its time as four numbers.',
      ],
      'clue': {
        'id': 'ep12_c2',
        'title': 'Platform 4',
        'value': '4',
        'symbol': 'train',
        'note': 'The Clockmaker came in on Platform 4, from Paris.',
      },
      'evidence': {
        'id': 'ep12_e2',
        'name': 'Arrivals Board',
        'icon': 'ticket',
        'description': 'The last trains of the night.',
        'inscription': '11:40 from Paris — Platform 4',
      },
      'successMessage': 'The train from Paris, on Platform 4!',
      'transition': [
        'At 11:40, a tall figure steps off the Paris train.',
        'A black coat. A top hat. A ticking sound.',
        'He jumps into a taxi. "To the Tower!" he says.',
      ],
      'nextMissionId': 'ep12_m3',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.3,
      'mapY': 0.48,
    },
    {
      'id': 'ep12_m3',
      'number': 3,
      'title': "The Raven's Riddle",
      'location': 'THE TOWER OF LONDON',
      'scene': 'raven',
      'story': [
        'All the ravens of the Tower are awake. Poppy flies to you.',
        'She drops her very last paper: a riddle.',
      ],
      'letterIntro': 'The Ravenmaster reads it with you:',
      'letter':
          'I have hands, but I cannot clap.\n'
          'I have a face, but I cannot smile.\n'
          'I am very tall, and I ring every hour.\n\n'
          "The Clockmaker's door is under me.",
      'type': 'wordInput',
      'question': "Where is the Clockmaker's door?",
      'prompt': 'UNDER ______',
      'answer': 'BIG BEN',
      'acceptedAnswers': ['BIGBEN', 'THE CLOCK TOWER', 'CLOCK TOWER', 'ELIZABETH TOWER'],
      'hints': [
        'A clock has hands and a face, too.',
        'Which tall place in London rings every hour? You were there in Case 02.',
      ],
      'clue': {
        'id': 'ep12_c3',
        'title': 'Seven Ravens',
        'value': '7',
        'symbol': 'raven',
        'note': 'All seven ravens are safe. The door is under Big Ben.',
      },
      'evidence': {
        'id': 'ep12_e3',
        'name': "Poppy's Riddle",
        'icon': 'feather',
        'description': 'The very last raven paper.',
        'inscription': 'Hands, a face, very tall, rings every hour.',
      },
      'successMessage': "The door is under Big Ben!",
      'transition': [
        "It is 11:55. You run back to Big Ben with the Shadow and Inspector Grey.",
        'Under the tower, there is a small iron door.',
        "You take out the Brass Key from Case 05: FOR THE CLOCKMAKER'S DOOR.",
      ],
      'nextMissionId': 'ep12_final',
      'skills': ['reading', 'vocabulary'],
      'mapX': 0.3,
      'mapY': 0.16,
    },
  ],
  'finalMission': {
    'id': 'ep12_final',
    'number': 4,
    'title': "The Clockmaker's Door",
    'location': 'UNDER BIG BEN',
    'scene': 'lockedDoor',
    'story': [
      'The Brass Key turns. But there are three more locks.',
      'Above you, Big Ben begins to ring for midnight.',
    ],
    'letterIntro': 'Words are carved into the door:',
    'letter':
        'Only a true detective can open me.\n\n'
        'The first lock is a train: its platform number.\n'
        'The second lock is a gear: count its teeth.\n'
        'The third lock is a raven: how many guard the Tower?\n\n'
        'Your notebook knows.',
    'type': 'finalCode',
    'question': 'Open the three locks before the last bell!',
    'codeLength': 3,
    'dialSymbols': ['train', 'gear', 'raven'],
    'answer': '487',
    'hints': [
      'Each lock asks a question. Tonight\'s three clues answer them.',
      'The train lock is first. Which platform did the Clockmaker arrive on?',
    ],
    'evidence': {
      'id': 'ep12_e4',
      'name': "The Clockmaker's Watch",
      'icon': 'watch',
      'description': 'Left on his empty desk.',
      'inscription': 'Still ticking. On the back: PARIS.',
    },
    'successMessage': 'London is safe at midnight!',
    'skills': ['problemSolving', 'reading'],
    'mapX': 0.76,
    'mapY': 0.46,
  },
  'glossary': {
    'midnight': '자정',
    'fake': '가짜의',
    'real': '진짜의',
    'teeth': '(톱니) 이들',
    'stamp': '도장, 무늬',
    'metal': '금속',
    'arrivals': '도착',
    'arrives': '도착하다',
    'platform': '승강장',
    'figure': '사람의 모습',
    'ticking': '째깍거리는',
    'riddle': '수수께끼',
    'hands': '(시계) 바늘, 손',
    'clap': '박수 치다',
    'face': '(시계) 문자판, 얼굴',
    'ring': '울리다',
    'awake': '깨어 있는',
    'carved': '새겨진',
    'true': '진정한',
    'guard': '지키다',
    'secret': '비밀의',
    'silent': '조용한',
    'hurry': '서두르다',
    'clockmaker': '시계공',
    'society': '모임',
  },
};
