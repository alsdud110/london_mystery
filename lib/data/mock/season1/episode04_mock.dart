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
  'hook': 'The picture on the postmark shows the Tower of London.',
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
        {'id': 'a', 'label': 'The ticket office', 'feedback': "At 10 PM the ticket office closes. Does it 'never sleep'?"},
        {'id': 'b', 'label': 'The café', 'feedback': 'The café closes at 8 PM: it sleeps at night!'},
        {'id': 'c', 'label': 'The platforms'},
        {'id': 'd', 'label': 'The shop', 'feedback': 'The shop closes at 9 PM. Which place is open day AND night?'},
      ],
      'answer': 'c',
      'hints': [
        'Read the station guide: when does each place close?',
        "'Never sleeps' means it never closes, not even at night.",
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
        {'id': 'a', 'label': 'Platform 1', 'feedback': "Platform 1's clock is white. Your card says RED."},
        {'id': 'b', 'label': 'Platform 4'},
        {'id': 'c', 'label': 'Platform 7', 'feedback': 'Platform 7 has a red door. Read to the end of the line: is there a clock?'},
        {'id': 'd', 'label': 'Platform 9', 'feedback': "Platform 9's clock is green. Which colour is on your card?"},
      ],
      'answer': 'b',
      'hints': [
        'Your card has four words. Check each platform against all four.',
        'Match the colour, object and platform number together. A red door is not the same as a red clock.',
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
          'Detective {detectiveName},\n\n'
          'I sent this letter from an old castle by the river.\n'
          'It has four towers and thick stone walls.\n'
          'Black birds live there.\n\n'
          '— R.',
      'type': 'imageChoice',
      'question': 'Which picture is on the postmark?',
      // TYPE B: no names under the pictures; the letter's description decides.
      'hideOptionNames': true,
      'options': [
        {'id': 'a', 'label': 'Buckingham Palace', 'artwork': 'buckinghamPalace', 'altText': 'a wide grand building with a flag on top and a fountain in front', 'feedback': 'A palace, not a castle: where are the four towers and thick walls?'},
        {'id': 'b', 'label': 'Tower of London', 'artwork': 'towerOfLondon', 'altText': 'an old fortress with many square towers and high walls'},
        {'id': 'c', 'label': 'British Museum', 'artwork': 'britishMuseum', 'altText': 'a large building with tall columns and a round dome', 'feedback': 'A museum with tall columns. The letter talks about an old castle by the river.'},
        {'id': 'd', 'label': 'London Eye', 'artwork': 'londonEye', 'altText': 'a giant wheel with little cabins, beside a river', 'feedback': 'A big wheel by the river. Is it an old castle with four towers?'},
      ],
      'answer': 'b',
      'hints': [
        'The letter describes the place in parts: a castle, a river, four towers, black birds. Look for each one.',
        'A castle is a strong old building with thick stone walls and towers.',
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
        'inscription': 'A small picture of the Tower of London.',
      },
      'successMessage': 'It came from the Tower of London!',
      'transition': [
        'There is one more letter in the envelope.',
        // The same seal as the first letter (Mission 01): the bird is the
        // final's answer, so the scene does not name it.
        'It is sealed with the same black seal as the first letter.',
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
        'Dear Detective {detectiveName},\n\n'
        'You read very well. Now read one more time.\n\n'
        'My friends and I have a secret name.\n'
        'We are named after a bird.\n'
        'It lives at the Tower.\n'
        'It is pressed into every seal we send.\n\n'
        'We are the _____ Society.',
    'type': 'wordInput',
    'question': 'What is the secret name?',
    'prompt': 'THE _____ SOCIETY',
    'answer': 'RAVEN',
    'feedback': {
      'CROW': 'Close! A crow is a black bird too. But which bird is pressed into the seal?',
      'BIRD': 'Which bird? Look closer at the seal from the first letter.',
      'BLACK': 'Black is its colour. What is the bird called?',
      'TOWER': "The bird lives at the Tower. What is the bird's name?",
    },
    'acceptedAnswers': ['RAVENS', 'THE RAVEN SOCIETY'],
    'hints': [
      // The seal (Mission 01) and the Tower's birds (Mission 03) give the
      // name: the tips point there, never to the word.
      'Open your notebook and look closer at the seal from the first letter.',
      "'Named after a bird' means their name is a bird's name: the bird pressed into every seal.",
    ],
    'evidence': {
      'id': 'ep04_e4',
      'name': 'The Secret Letter',
      'icon': 'letter',
      'description': 'Signed by the Raven Society.',
      'inscription': 'We are the Raven Society. We are watching.',
    },
    'successMessage': 'The secret name is the Raven Society!',
    // After the case is closed: the post-case story scene (existing facts only).
    'transition': [
      'The message is finally clear.',
      'THE RAVEN SOCIETY.',
      'The raven was not just a picture.',
      'It was on every seal.',
      'You turn the envelope over.',
      'The little picture on the postmark',
      'is the Tower of London.',
    ],
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
    'open': '열려 있는, 열다',
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
    'describes': '묘사하다, 설명하다',
  },
};
