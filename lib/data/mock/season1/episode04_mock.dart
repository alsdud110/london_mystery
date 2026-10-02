/// Case 04 — The Secret Letter (King's Cross). Theme: reading letters.
///
/// Every step is a letter or a card that must be read to find the next
/// place: the station guide ("never sleep"), the four-word card (RED · FOUR ·
/// CLOCK · PLATFORM) and the postmark. Final case: the last letter describes
/// the sender's name without saying it; the wax seal in the notebook shows it.
const Map<String, dynamic> episode04Json = {
  'id': 'ep04',
  'number': 4,
  'title': 'The Secret Letter',
  'synopsis': [
    'An old suitcase waits in the Lost Property office.',
    'Inside, there is a letter with a black wax seal.',
    'Read it carefully. It is written for you.',
  ],
  'objectives': ['Follow the secret letter.', 'Find out who wrote it.'],
  // The place the intro opens on (its picture behind the story lines).
  'introScene': 'kingsCross',
  'intro': [
    "King's Cross, 11:00 AM...",
    'Miss Rose came here with the painting.',
    'She is gone. But she left her suitcase behind.',
    'Inside, there is a letter with a black wax seal.',
    'On the envelope, it says: "For the detective."',
  ],
  'caseSummary': 'You read every letter, followed the words across the station and found out who is behind it.',
  'keyWords': ['platform', 'letter', 'seal'],
  'hook': 'The postmark says the next letter came from the Tower of London.',
  'missions': [
    {
      'id': 'ep04_m1',
      'number': 1,
      'title': 'The Black Seal',
      'location': 'LOST PROPERTY',
      'scene': 'suitcase',
      'story': [
        'The Lost Property office is full of forgotten umbrellas and bags.',
        'A man gives you an old brown suitcase.',
      ],
      'letterIntro': 'You break the black wax seal. The letter says:',
      'letter':
          'To the detective who finds this letter,\n\n'
          'Meet me where trains never sleep.\n\n'
          '— R.\n\n'
          'STATION GUIDE\n'
          'Ticket office: open 6 AM to 10 PM\n'
          'Café: open 7 AM to 8 PM\n'
          'Platforms: open day and night\n'
          'Shop: open 8 AM to 9 PM',
      'type': 'multipleChoice',
      'question': 'Where should you go to meet the writer?',
      'options': [
        {'id': 'a', 'label': 'The ticket office'},
        {'id': 'b', 'label': 'The café'},
        {'id': 'c', 'label': 'The platforms'},
        {'id': 'd', 'label': 'The shop'},
      ],
      'answer': 'c',
      'hints': [
        'A place that "never sleeps" never closes.',
        'Look for the place that is open at night too.',
      ],
      'clue': {
        'id': 'ep04_c1',
        'title': 'Day and Night',
        'value': 'Platforms',
        'symbol': 'train',
        'note': 'The platforms never sleep. They are open day and night.',
      },
      'evidence': {
        'id': 'ep04_e1',
        'name': 'Black Wax Seal',
        'icon': 'seal',
        'description': 'It closed the secret letter.',
        'inscription': 'A raven is pressed into the wax.',
      },
      'successMessage': 'The platforms never sleep!',
      'transition': [
        'You walk to the platforms. Trains come and go.',
        'Inside the envelope, you find one more card.',
        'It has only four words on it.',
      ],
      'nextMissionId': 'ep04_m2',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.3,
      'mapY': 0.16,
    },
    {
      'id': 'ep04_m2',
      'number': 2,
      'title': 'The Four Words',
      'location': 'THE PLATFORMS',
      'scene': 'kingsCross',
      'story': [
        'The card says: RED · FOUR · CLOCK · PLATFORM.',
        'You look at the clocks above the platforms.',
      ],
      'letterIntro': 'A porter tells you about the clocks.',
      'letter':
          'Platform 1 has a big white clock.\n'
          'Platform 4 has a small red clock.\n'
          'Platform 7 has a red door, but no clock.\n'
          'Platform 9 has a green clock.\n\n'
          'Your card says: RED · FOUR · CLOCK · PLATFORM.',
      'type': 'multipleChoice',
      'question': 'Where is the next clue?',
      'options': [
        {'id': 'a', 'label': 'Under the white clock on Platform 1'},
        {'id': 'b', 'label': 'Under the red clock on Platform 4'},
        {'id': 'c', 'label': 'Behind the red door on Platform 7'},
        {'id': 'd', 'label': 'Under the green clock on Platform 9'},
      ],
      'answer': 'b',
      'hints': [
        'Use all four words together, not just one.',
        'You need a clock that is red, on the right platform number.',
      ],
      'clue': {
        'id': 'ep04_c2',
        'title': 'Platform 4',
        'value': '4',
        'symbol': 'clock',
        'note': 'The next letter was under the red clock on Platform 4.',
      },
      'evidence': {
        'id': 'ep04_e2',
        'name': 'Word Card',
        'icon': 'ticket',
        'description': 'Four words, one place.',
        'inscription': 'RED · FOUR · CLOCK · PLATFORM',
      },
      'successMessage': 'Under the red clock on Platform 4!',
      'transition': [
        'Under the small red clock, there is a second envelope.',
        'It has a postmark, but the rain washed the words away.',
        'Only a small picture is left.',
      ],
      'nextMissionId': 'ep04_m3',
      'skills': ['reading', 'vocabulary'],
      'mapX': 0.72,
      'mapY': 0.36,
    },
    {
      'id': 'ep04_m3',
      'number': 3,
      'title': 'The Postmark',
      'location': 'PLATFORM 4',
      'scene': 'suitcase',
      'story': [
        'A postmark shows where a letter was sent from.',
        'This one has a picture of a place in London.',
      ],
      'letterIntro': 'The second letter is short.',
      'letter':
          'Detective,\n\n'
          'I sent this letter from an old castle by the river.\n'
          'It has four towers and thick stone walls.\n'
          'Black birds live there.\n\n'
          '— R.',
      'type': 'imageChoice',
      'question': 'Which picture is on the postmark?',
      'options': [
        {'id': 'a', 'label': 'Buckingham Palace', 'artwork': 'buckinghamPalace'},
        {'id': 'b', 'label': 'Tower of London', 'artwork': 'towerOfLondon'},
        {'id': 'c', 'label': 'British Museum', 'artwork': 'britishMuseum'},
        {'id': 'd', 'label': 'London Eye', 'artwork': 'londonEye'},
      ],
      'answer': 'b',
      'hints': [
        'A castle is a strong old building with walls and towers.',
        'Count the towers in each picture.',
      ],
      'clue': {
        'id': 'ep04_c3',
        'title': 'An Old Castle',
        'value': 'Tower',
        'symbol': 'letter',
        'note': 'The letter came from the Tower of London.',
      },
      'evidence': {
        'id': 'ep04_e3',
        'name': 'Postmark',
        'icon': 'letter',
        'description': 'From the second envelope.',
        'inscription': 'TOWER OF LONDON',
      },
      'successMessage': 'It came from the Tower of London!',
      'transition': [
        'There is one more letter in the envelope.',
        'It is sealed with the same black raven.',
        'This time, the writer tells you who they are... almost.',
      ],
      'nextMissionId': 'ep04_final',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.24,
      'mapY': 0.58,
    },
  ],
  'finalMission': {
    'id': 'ep04_final',
    'number': 4,
    'title': 'The Last Letter',
    'location': 'THE LAST TRAIN',
    'scene': 'suitcase',
    'story': [
      'You sit on the last train of the night and open the letter.',
      'The writing is small and neat.',
    ],
    'letterIntro': 'The last letter says:',
    'letter':
        'Dear Detective,\n\n'
        'You read very well. Now read one more time.\n\n'
        'My friends and I have a secret name.\n'
        'We are named after a big black bird.\n'
        'The bird lives at the Tower. It is on every seal.\n\n'
        'We are the _____ Society.',
    'type': 'wordInput',
    'question': 'What is the secret name?',
    'prompt': 'THE _____ SOCIETY',
    'answer': 'RAVEN',
    'acceptedAnswers': ['RAVENS', 'THE RAVEN SOCIETY'],
    'hints': [
      'Look at the Black Wax Seal in your notebook. What is pressed into it?',
      'The letter signs every page with the first letter of the bird: R.',
    ],
    'evidence': {
      'id': 'ep04_e4',
      'name': 'The Secret Letter',
      'icon': 'letter',
      'description': 'Signed by the Raven Society.',
      'inscription': 'We are the Raven Society. We are watching.',
    },
    'successMessage': 'The Raven Society!',
    'skills': ['reading', 'vocabulary'],
    'mapX': 0.74,
    'mapY': 0.8,
  },
  'glossary': {
    'secret': '비밀의',
    'seal': '봉인',
    'wax': '밀랍',
    'envelope': '봉투',
    'property': '물건, 소유물',
    'lost': '잃어버린',
    'forgotten': '잊힌',
    'umbrellas': '우산들',
    'platform': '승강장',
    'platforms': '승강장들',
    'porter': '역무원, 짐꾼',
    'guide': '안내',
    'ticket': '표',
    'office': '사무실',
    'open': '열려 있는',
    'never': '결코 ~않다',
    'sleep': '자다',
    'postmark': '우편 소인',
    'washed': '씻겨 나갔다',
    'castle': '성',
    'towers': '탑들',
    'thick': '두꺼운',
    'walls': '벽들',
    'birds': '새들',
    'bird': '새',
    'named': '이름 붙여진',
    'society': '모임, 협회',
    'neat': '깔끔한',
    'pressed': '눌러 찍힌',
    'watching': '지켜보고 있는',
  },
};
