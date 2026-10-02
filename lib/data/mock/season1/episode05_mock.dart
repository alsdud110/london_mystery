/// Case 05 — The Locked Room (Tower of London). Theme: directions, commands.
///
/// The room has no keyhole: a dial that turns left and right, then three
/// picture locks. Each lock asks a question in English ("how many ravens?"),
/// and the answers were found on the way (clock → 5, gear → 4, raven → 7).
/// The final letter gives the locks in a different order from the one the
/// clues were found in, so the player must read it, not copy the clues.
const Map<String, dynamic> episode05Json = {
  'id': 'ep05',
  'number': 5,
  'title': 'The Locked Room',
  'synopsis': [
    'A room in the Tower was locked for a hundred years.',
    'Tonight, its door is open.',
    'There is no keyhole — only a dial and a note.',
  ],
  'objectives': ['Find the locked room.', 'Open the last lock.'],
  // The place the intro opens on (its picture behind the story lines).
  'introScene': 'towerOfLondon',
  'intro': [
    'Tower of London, 5:00 PM...',
    'The Raven Society sent its letter from here.',
    'The Ravenmaster meets you at the gate.',
    '"A room in the White Tower was locked for a hundred years," he says.',
    '"Nobody has the key. But this morning, its door was open."',
  ],
  'caseSummary': 'You followed every command, turned the dial the right way and opened the locked room.',
  'keyWords': ['left', 'right', 'turn'],
  'hook': 'On the wall of the room: "At midnight, the Clockmaker will stop London."',
  'missions': [
    {
      'id': 'ep05_m1',
      'number': 1,
      'title': 'The Ravenmaster',
      'location': 'TOWER GREEN',
      'scene': 'towerOfLondon',
      'story': [
        'The gates of the Tower close at five o\'clock.',
        'The Ravenmaster lets you in, and the big gate shuts behind you.',
      ],
      'letterIntro': 'He draws the way to the room on a card.',
      'letter':
          'Walk past the ravens.\n'
          'Turn left at the old cannon.\n'
          'Go up the stairs to the third floor.\n'
          'The door is on the right.\n\n'
          'Hurry. The Tower is closed now.',
      'type': 'multipleChoice',
      'question': 'Where is the locked room?',
      'options': [
        {'id': 'a', 'label': 'On the second floor, on the left'},
        {'id': 'b', 'label': 'On the third floor, on the left'},
        {'id': 'c', 'label': 'On the third floor, on the right'},
        {'id': 'd', 'label': 'Next to the old cannon'},
      ],
      'answer': 'c',
      'hints': [
        'The card has two directions: one outside, one at the top of the stairs.',
        'Read the last two lines: which floor, and which side?',
      ],
      'clue': {
        'id': 'ep05_c1',
        'title': "Five O'Clock",
        'value': '5',
        'symbol': 'clock',
        'note': "The Tower gates close at five o'clock.",
      },
      'evidence': {
        'id': 'ep05_e1',
        'name': "Ravenmaster's Card",
        'icon': 'map',
        'description': 'The way to the locked room.',
        'inscription': 'Left at the cannon. Third floor. On the right.',
      },
      'successMessage': 'Third floor, on the right!',
      'transition': [
        'You climb the old stairs to the third floor.',
        'On the right, there is a heavy wooden door.',
        'It has no keyhole — only a round brass dial.',
      ],
      'nextMissionId': 'ep05_m2',
      'skills': ['reading', 'vocabulary'],
      'mapX': 0.26,
      'mapY': 0.64,
    },
    {
      'id': 'ep05_m2',
      'number': 2,
      'title': 'The Dial Door',
      'location': 'THE WHITE TOWER',
      'scene': 'lockedDoor',
      'story': [
        'Four brass gears are set around the dial.',
        'The dial can turn two ways: left or right.',
      ],
      'letterIntro': 'A note is carved into the door.',
      'letter':
          'First, turn the dial to the left.\n'
          'Next, turn it the other way.\n'
          'Then, turn it the same way as the first time.\n'
          'Last, turn it the same way as the second time.',
      'type': 'sequence',
      'question': 'Turn the dial four times.',
      'options': [
        {'id': 'left', 'label': 'TURN LEFT'},
        {'id': 'right', 'label': 'TURN RIGHT'},
      ],
      'codeLength': 4,
      'answer': 'left,right,left,right',
      'hints': [
        '"The other way" means the opposite of left.',
        'The third turn copies the first. The last turn copies the second.',
      ],
      'clue': {
        'id': 'ep05_c2',
        'title': 'Four Gears',
        'value': '4',
        'symbol': 'gear',
        'note': 'There were four brass gears around the dial.',
      },
      'evidence': {
        'id': 'ep05_e2',
        'name': 'Direction Note',
        'icon': 'letter',
        'description': 'Carved into the door.',
        'inscription': 'LEFT · RIGHT · LEFT · RIGHT',
      },
      'successMessage': 'Click, clack! The door opens.',
      'transition': [
        'Inside, a candle is still warm. Someone was here!',
        'On the table, there is a box for the ravens\' food.',
        'Something shiny is inside it.',
      ],
      'nextMissionId': 'ep05_m3',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.72,
      'mapY': 0.46,
    },
    {
      'id': 'ep05_m3',
      'number': 3,
      'title': 'The Ravens\' Box',
      'location': 'THE RAVEN ROOM',
      'scene': 'raven',
      'story': [
        'A raven hops onto the window and looks at you.',
        'The food box has a lock with a word on it.',
      ],
      'letterIntro': 'The Ravenmaster reads the old sign on the wall.',
      'letter':
          'An old story says:\n'
          'if the ravens leave the Tower, the Tower will fall.\n\n'
          'So there are always six ravens here...\n'
          'and one more, just in case.',
      'type': 'wordInput',
      'question': 'How many ravens live at the Tower? Type the number word.',
      'prompt': '_____ RAVENS',
      'answer': 'SEVEN',
      'acceptedAnswers': ['7', '7 RAVENS', 'SEVEN RAVENS'],
      'hints': [
        'Read the last two lines again: "six ravens" and "one more".',
        'Six and one more. Write the number as a word.',
      ],
      'clue': {
        'id': 'ep05_c3',
        'title': 'Seven Ravens',
        'value': '7',
        'symbol': 'raven',
        'note': 'Six ravens, and one more just in case.',
      },
      'evidence': {
        'id': 'ep05_e3',
        'name': 'Brass Key',
        'icon': 'key',
        'description': "Hidden in the ravens' food box.",
        'inscription': "FOR THE CLOCKMAKER'S DOOR",
      },
      'successMessage': 'Seven ravens!',
      'transition': [
        'Behind the food box, there is an iron chest.',
        'It has three locks. Each lock has a picture.',
        'The Clockmaker... who is that?',
      ],
      'nextMissionId': 'ep05_final',
      'skills': ['reading', 'vocabulary'],
      'mapX': 0.3,
      'mapY': 0.26,
    },
  ],
  'finalMission': {
    'id': 'ep05_final',
    'number': 4,
    'title': 'The Iron Chest',
    'location': 'THE LOCKED ROOM',
    'scene': 'lockedDoor',
    'story': [
      'The iron chest is cold and heavy.',
      'Three picture locks keep it shut.',
    ],
    'letterIntro': 'Words are painted on the lid.',
    'letter':
        'Open the locks from left to right.\n\n'
        'The first lock: how many ravens live at the Tower?\n'
        'The second lock: how many gears are on the door?\n'
        'The third lock: what time do the gates close?\n\n'
        'Your notebook knows.',
    'type': 'finalCode',
    'question': 'Open the three locks.',
    'codeLength': 3,
    'dialSymbols': ['raven', 'gear', 'clock'],
    'answer': '745',
    'hints': [
      'Each lock asks a question. Your clues answer them.',
      'The first lock is the raven. The Raven Room clue gave you that number.',
    ],
    'evidence': {
      'id': 'ep05_e4',
      'name': 'Old Map Fragment',
      'icon': 'map',
      'description': 'Half of an old map of London.',
      'inscription': 'Hyde Park. A small raven is drawn by a bridge.',
    },
    'successMessage': 'The iron chest is open!',
    'skills': ['problemSolving', 'reading'],
    'mapX': 0.78,
    'mapY': 0.8,
  },
  'glossary': {
    'locked': '잠긴',
    'keyhole': '열쇠 구멍',
    'dial': '다이얼',
    'turn': '돌리다',
    'left': '왼쪽',
    'right': '오른쪽',
    'other': '다른',
    'same': '같은',
    'first': '처음, 첫 번째',
    'second': '두 번째',
    'third': '세 번째',
    'last': '마지막',
    'next': '다음',
    'floor': '층',
    'cannon': '대포',
    'stairs': '계단',
    'ravenmaster': '까마귀 관리인',
    'ravens': '까마귀들',
    'raven': '까마귀',
    'gates': '성문들',
    'gate': '문, 정문',
    'shuts': '닫히다',
    'heavy': '무거운',
    'wooden': '나무로 된',
    'carved': '새겨진',
    'candle': '초, 양초',
    'warm': '따뜻한',
    'fall': '무너지다',
    'always': '항상',
    'case': '(만일의) 경우',
    'iron': '쇠, 철',
    'chest': '상자, 궤',
    'lid': '뚜껑',
    'painted': '칠해진',
    'hurry': '서두르다',
    'clockmaker': '시계공',
  },
};
