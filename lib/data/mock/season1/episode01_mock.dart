/// Episode 01 content, shaped exactly like the JSON a backend would return.
///
/// Final case design: each lock on the Royal Box shows a picture. The order of
/// the pictures is only found on the "Crown Symbol" evidence (Mission 05).
/// Each picture points to a place, and each place gave a numbered clue:
///   clock → Big Ben 7, train → King's Cross 9, park → Hyde Park 2,
///   museum → British Museum 4   ⇒   code 7924.
const Map<String, dynamic> episode01Json = {
  'id': 'ep01',
  'number': 1,
  'title': 'The Missing Crown',
  'synopsis': [
    'The Crown has disappeared from the Royal Archive in London!',
    'The thief left a trail of clues.',
    'The clues are hidden all over the city.',
  ],
  'objectives': ['Find the crown.', 'Solve the mystery.'],
  'intro': [
    'London, 10:42 PM...',
    'Something strange happened at the Royal Archive.',
    'The Crown is missing.',
    'The thief left a trail of clues all over London.',
    'You have been chosen as a detective.',
  ],
  'missions': [
    {
      'id': 'm01',
      'number': 1,
      'title': 'The Mysterious Suitcase',
      'location': "KING'S CROSS",
      'scene': 'suitcase',
      'story': [
        "You step off the train at King's Cross Station.",
        'Next to Platform 9, you find a mysterious suitcase.',
      ],
      'letterIntro': 'Inside the suitcase, there is a letter.',
      'letter':
          'Dear Detective,\n\n'
          'I took the Crown! Ha ha!\n'
          'My next stop is a very big museum.\n'
          'It has old mummies from Egypt and a famous stone.\n\n'
          '— The Shadow',
      'type': 'multipleChoice',
      'question': 'Where is the thief going next?',
      'options': [
        {'id': 'a', 'label': 'Tower Bridge'},
        {'id': 'b', 'label': 'The British Museum'},
        {'id': 'c', 'label': 'Big Ben'},
        {'id': 'd', 'label': 'Hyde Park'},
      ],
      'answer': 'b',
      'hints': [
        "Read the letter again. Look for the word 'museum'.",
        'The answer is a museum in London. It starts with B.',
      ],
      'clue': {
        'id': 'c01',
        'title': 'Platform 9',
        'value': '9',
        'symbol': 'train',
        'note': 'The suitcase was next to Platform 9.',
      },
      'evidence': {
        'id': 'e01',
        'name': 'Old Letter',
        'icon': 'letter',
        'description': 'A letter from the thief.',
        'inscription': 'Signed: The Shadow\nP.S. I love trains!',
      },
      'successMessage': 'The thief is going to the British Museum.',
      'transition': [
        'The letter suddenly begins to glow...',
        'Someone left a strange symbol near the British Museum.',
      ],
      'nextMissionId': 'm02',
      'skills': ['reading', 'vocabulary'],
      'mapX': 0.62,
      'mapY': 0.12,
    },
    {
      'id': 'm02',
      'number': 2,
      'title': 'The Famous Stone',
      'location': 'BRITISH MUSEUM',
      'scene': 'britishMuseum',
      'story': [
        'The British Museum is full of old treasures.',
        'In Room 4, you see a big grey stone with strange writing.',
      ],
      'letterIntro': 'Someone left a note next to the stone!',
      'letter':
          'This stone helped people read old Egyptian writing.\n'
          'Its name has two words.\n'
          'The first word is ROSETTA.\n'
          'The second word means a hard piece of rock.',
      'type': 'wordInput',
      'question': 'Complete the name of the famous stone.',
      'prompt': 'ROSETTA _____',
      'answer': 'STONE',
      'acceptedAnswers': ['ROSETTA STONE'],
      'hints': ['It is another word for rock.', 'It has 5 letters: S _ _ _ E'],
      'clue': {
        'id': 'c02',
        'title': 'Room 4',
        'value': '4',
        'symbol': 'museum',
        'note': 'The Rosetta Stone is in Room 4.',
      },
      'evidence': {
        'id': 'e02',
        'name': 'Golden Key',
        'icon': 'key',
        'description': 'A small golden key under the stone.',
        'inscription': 'ROOM 4',
      },
      'successMessage': 'It is the Rosetta Stone!',
      'transition': [
        'The old stone shines in the dark.',
        'Ding dong! Far away, a big bell rings.',
        'The next clue is at Big Ben.',
      ],
      'nextMissionId': 'm03',
      'skills': ['vocabulary', 'reading'],
      'mapX': 0.56,
      'mapY': 0.29,
    },
    {
      'id': 'm03',
      'number': 3,
      'title': 'The Locked Box',
      'location': 'BIG BEN',
      'scene': 'bigBen',
      'story': [
        'You run to the tall clock tower: Big Ben!',
        'At the bottom, there is a small metal box with a 3-number lock.',
      ],
      'letterIntro': 'A note is stuck on the box.',
      'letter':
          'My code is in three sentences:\n\n'
          '1. The tower has FOUR clock faces.\n'
          '2. At one o\'clock, the bell rings ONE time.\n'
          '3. I left London at SEVEN o\'clock.\n\n'
          'Put the numbers in order!',
      'type': 'numberCode',
      'question': 'Find the three numbers hidden in the clues.',
      'codeLength': 3,
      'answer': '417',
      'hints': [
        'Look for the number words in BIG letters.',
        'FOUR, ONE, SEVEN. Change them into numbers.',
      ],
      'clue': {
        'id': 'c03',
        'title': "7 o'clock",
        'value': '7',
        'symbol': 'clock',
        'note': "The Shadow left at 7 o'clock.",
      },
      'evidence': {
        'id': 'e03',
        'name': 'Pocket Watch',
        'icon': 'watch',
        'description': 'The thief left this watch in the box.',
        'inscription': "It stopped at 7 o'clock.",
      },
      'successMessage': 'Click! The box opens.',
      // The box holds both: the watch (the evidence, kept) and the photo
      // that sends the detective on (the story).
      'transition': [
        'Inside the box, there is a pocket watch and a photo.',
        'The photo shows a big green park with a lake.',
        "Let's go to Hyde Park!",
      ],
      'nextMissionId': 'm04',
      'skills': ['problemSolving', 'vocabulary', 'reading'],
      'mapX': 0.68,
      'mapY': 0.63,
    },
    {
      'id': 'm04',
      'number': 4,
      'title': 'The Secret Drawing',
      'location': 'HYDE PARK',
      'scene': 'hydePark',
      'story': [
        'You arrive at Hyde Park.',
        'Two white swans are swimming on the lake.',
      ],
      'letterIntro': 'Under a bench, you find a note from the thief.',
      'letter':
          'My last stop is a big palace.\n'
          'Soldiers stand at the gate.\n'
          'They wear red coats and tall black hats.\n'
          'The King lives there!',
      'type': 'imageChoice',
      'question': "Which picture shows the thief's last stop?",
      'options': [
        {'id': 'a', 'label': 'Tower Bridge', 'artwork': 'towerBridge'},
        {'id': 'b', 'label': 'London Eye', 'artwork': 'londonEye'},
        {
          'id': 'c',
          'label': 'Buckingham Palace',
          'artwork': 'buckinghamPalace',
        },
        {'id': 'd', 'label': 'Big Ben', 'artwork': 'bigBen'},
      ],
      'answer': 'c',
      'hints': [
        'Think about the place where the King and Queen live.',
        'Look for a big building with a gate and guards in red coats.',
      ],
      'clue': {
        'id': 'c04',
        'title': '2 Swans',
        'value': '2',
        'symbol': 'park',
        'note': 'Two white swans were swimming on the lake.',
      },
      'evidence': {
        'id': 'e04',
        'name': 'London Map',
        'icon': 'map',
        'description': 'A map left under the bench.',
        'inscription': 'Two swans are drawn on the lake.',
      },
      'successMessage': 'Buckingham Palace is the home of the King.',
      'transition': [
        'The swans fly up into the sky.',
        'They fly toward a big palace...',
        "The thief's last stop is near!",
      ],
      'nextMissionId': 'm05',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.18,
      'mapY': 0.42,
    },
    {
      'id': 'm05',
      'number': 5,
      'title': 'The Royal Guard',
      'location': 'BUCKINGHAM PALACE',
      'scene': 'buckinghamPalace',
      'story': [
        'You reach Buckingham Palace.',
        'A guard in a red coat smiles at you.',
      ],
      'letterIntro': 'The guard gives you a small card.',
      'letter':
          'Detective, the thief hid a secret code near the gate.\n\n'
          'Look for the QR code with the golden crown sticker.\n'
          'Scan it to open the last door!',
      'type': 'qrScan',
      'question': 'Find the secret QR code and scan it.',
      'answer': 'LM-EP01-PALACE',
      'hints': [
        'Look near the gate for a golden crown sticker.',
        'Ask your game guide in English: "Where is the golden crown?"',
      ],
      'clue': {
        'id': 'c05',
        'title': 'The Royal Box',
        'value': '4 locks',
        'symbol': 'crown',
        'note': 'The Crown is inside a box with 4 locks.',
      },
      'evidence': {
        'id': 'e05',
        'name': 'Crown Symbol',
        'icon': 'crown',
        'description': 'A golden card with a crown on it.',
        'inscription':
            'Four pictures for four locks.\nRead them from left to right.',
        'symbols': ['clock', 'train', 'park', 'museum'],
      },
      'successMessage': 'The last door is open!',
      'transition': [
        'The guard opens a secret door.',
        'Behind it, old stairs go down into the dark.',
        'The Royal Archive is waiting for you.',
      ],
      'nextMissionId': 'final',
      'skills': ['problemSolving', 'reading'],
      'mapX': 0.26,
      'mapY': 0.66,
    },
  ],
  'finalMission': {
    'id': 'final',
    'number': 6,
    'title': 'The Royal Box',
    'location': 'THE ROYAL ARCHIVE',
    'scene': 'royalBox',
    'story': [
      'Deep inside the Royal Archive, you find a heavy golden box.',
      'The Crown is inside.',
    ],
    'letterIntro': 'A message is carved on the lid.',
    'letter':
        'Four locks keep the Crown safe.\n'
        'Each lock has a picture.\n\n'
        'Every picture is a place you visited.\n'
        'Find its number in your Detective Notebook!',
    'type': 'finalCode',
    'question': 'Open the four locks.',
    'codeLength': 4,
    'dialSymbols': ['clock', 'train', 'park', 'museum'],
    'answer': '7924',
    'hints': [
      "Each picture is a place. The train is King's Cross!",
      "Open your notebook and find the clue from King's Cross. Then find the clues for the clock, the park and the museum.",
    ],
    'evidence': {
      'id': 'e06',
      'name': 'The Missing Crown',
      'icon': 'crown',
      'description': 'The real Crown of London. You found it!',
      'inscription': 'Returned by a great detective.',
    },
    'successMessage': 'The Crown has been found!',
    // After the case is closed: the post-case story scene (existing facts only).
    'transition': [
      'The Crown is safe again.',
      'The Royal Box is open.',
      'But the Shadow is gone.',
      'The note at Big Ben said:\n"I left London at SEVEN o\'clock."',
      'And his letter ended:',
      '"P.S. I love trains!"',
      'London is quiet tonight.',
      'For now.',
    ],
    'skills': ['problemSolving', 'reading'],
    'mapX': 0.84,
    'mapY': 0.45,
  },
  // Only these words get a dotted underline; tapping one shows its meaning.
  'glossary': {
    'mysterious': '수상한, 이상한',
    'suitcase': '여행 가방',
    'platform': '(기차역) 승강장',
    'thief': '도둑',
    'crown': '왕관',
    'museum': '박물관',
    'mummies': '미라들',
    'egypt': '이집트',
    'egyptian': '이집트의',
    'famous': '유명한',
    'treasures': '보물들',
    'stone': '돌',
    'rock': '바위, 돌',
    'writing': '글, 글씨',
    'tower': '탑',
    'clock': '시계',
    'faces': '(시계의) 면',
    'bell': '종',
    'rings': '(종이) 울리다',
    'palace': '궁전',
    'soldiers': '군인들',
    'guard': '경비병',
    'gate': '문, 정문',
    'swans': '백조들',
    'lake': '호수',
    'bench': '벤치, 긴 의자',
    'sticker': '스티커',
    'scan': '스캔하다(찍다)',
    'secret': '비밀의',
    'archive': '기록 보관소',
    'heavy': '무거운',
    'locks': '자물쇠들',
    'carved': '새겨진',
    'king': '왕',
    'queen': '여왕',
    'strange': '이상한',
    'symbol': '기호, 표시',
    'glow': '빛나다',
    'shines': '빛나다',
    'chosen': '뽑힌, 선택된',
    'missing': '사라진',
    'visited': '방문했던',
    'notebook': '수첩',
  },
};
