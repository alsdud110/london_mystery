/// Case 03 — The Vanishing Painting (British Museum). Theme: descriptions.
///
/// Three small things were left behind: a red button, a blue cloth and a
/// wet footprint. Each one is read in English (colour, place, "wet / dry")
/// and together they point to the thief and the door she left by.
/// Final case: the exit is only described ("two big arches and a clock
/// tower"), so the player must match the description to a picture.
const Map<String, dynamic> episode03Json = {
  'id': 'ep03',
  'number': 3,
  'title': 'The Vanishing Painting',
  'synopsis': [
    'A painting has vanished from Gallery 8.',
    'The thief left three small things behind.',
    'Read every clue and find the way she went.',
  ],
  'objectives': ['Find out who took the painting.', 'Find the way the thief went.'],
  // The place the intro opens on (its picture behind the story lines).
  'introScene': 'britishMuseum',
  'intro': [
    'British Museum, 9:18 AM...',
    'Big Ben rang, and the guards ran to Gallery 8.',
    'But they were one minute too late.',
    'The frame of Picture 17 is empty.',
    'The thief was in a hurry. Three small things were left behind.',
  ],
  'caseSummary': 'You read every small clue and followed the thief out of the museum.',
  'keyWords': ['button', 'cloth', 'footprint'],
  'hook': 'The missing painting shows a tower full of ravens.',
  'missions': [
    {
      'id': 'ep03_m1',
      'number': 1,
      'title': 'The Empty Frame',
      'location': 'GALLERY 8',
      'scene': 'gallery',
      'story': [
        'Picture 17 was called "The Raven Tower".',
        'Now there is only an empty golden frame on the wall.',
      ],
      'letterIntro': 'The museum guard shows you his report.',
      'letter':
          'GUARD REPORT — GALLERY 8\n\n'
          'I found three things on the floor.\n'
          'The button is red. It is under the bench.\n'
          'The cloth is blue. It is on the frame.\n'
          'The footprint is wet. It is next to the door.',
      'type': 'multipleChoice',
      'question': 'Which clue is next to the door?',
      'options': [
        {'id': 'a', 'label': 'The red button'},
        {'id': 'b', 'label': 'The blue cloth'},
        {'id': 'c', 'label': 'The wet footprint'},
        {'id': 'd', 'label': 'The golden frame'},
      ],
      'answer': 'c',
      'hints': [
        'Every line of the report says what a thing is like, and where it is.',
        'Find the line with the word "door".',
      ],
      'clue': {
        'id': 'ep03_c1',
        'title': 'Wet Footprint',
        'value': 'Door',
        'symbol': 'footprint',
        'note': 'The wet footprint was next to the door.',
      },
      'evidence': {
        'id': 'ep03_e1',
        'name': 'Red Button',
        'icon': 'button',
        'description': 'From a coat. It was under the bench.',
        'inscription': 'A shiny red coat button.',
      },
      'successMessage': 'The footprint shows the way out!',
      'transition': [
        'You pick up the red button and the blue cloth.',
        'The guard points to a list of visitors.',
        'Three people were in Gallery 8 this morning.',
      ],
      'nextMissionId': 'ep03_m2',
      'skills': ['reading', 'vocabulary'],
      'mapX': 0.28,
      'mapY': 0.2,
    },
    {
      'id': 'ep03_m2',
      'number': 2,
      'title': 'The Three Visitors',
      'location': 'THE EGYPT ROOM',
      'scene': 'britishMuseum',
      'story': [
        'In the Egypt Room, old mummies sleep in their glass cases.',
        'Another piece of the same blue cloth is caught on one case.',
      ],
      'letterIntro': 'The guard reads his notes about the three visitors.',
      'letter':
          'Mr Green wore a brown coat and a green hat.\n\n'
          'Miss Rose wore a red coat and a blue scarf.\n\n'
          'Mr Grey wore a black coat and a red scarf.\n\n'
          'Remember: the button is red. The cloth is blue.',
      'type': 'multipleChoice',
      'question': 'Who took the painting?',
      'options': [
        {'id': 'a', 'label': 'Mr Green'},
        {'id': 'b', 'label': 'Miss Rose'},
        {'id': 'c', 'label': 'Mr Grey'},
      ],
      'answer': 'b',
      'hints': [
        'A button comes from a coat. A piece of cloth can come from a scarf.',
        'Look for a red coat and a blue scarf on the same person.',
      ],
      'clue': {
        'id': 'ep03_c2',
        'title': 'Miss Rose',
        'value': 'Red coat',
        'symbol': 'cloth',
        'note': 'Red coat, blue scarf. Miss Rose is the thief.',
      },
      'evidence': {
        'id': 'ep03_e2',
        'name': 'Blue Cloth',
        'icon': 'cloth',
        'description': 'Torn from a blue scarf.',
        'inscription': 'A small raven is sewn on it.',
      },
      'successMessage': 'Miss Rose is the thief!',
      'transition': [
        'Miss Rose is not in the museum any more.',
        'But her wet footprints go across the Great Court.',
        'Follow them!',
      ],
      'nextMissionId': 'ep03_m3',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.74,
      'mapY': 0.4,
    },
    {
      'id': 'ep03_m3',
      'number': 3,
      'title': 'The Wet Footprints',
      'location': 'THE GREAT COURT',
      'scene': 'britishMuseum',
      'story': [
        'The Great Court has a glass roof and a white floor.',
        'Four footprints cross the floor. Some are wetter than others.',
      ],
      'letterIntro': 'A cleaner stops you. She saw the footprints first.',
      'letter':
          'The footprint by the café was a little wet.\n'
          'The footprint by the shop was very wet.\n'
          'The footprint by the north door was almost dry.\n'
          'The footprint by the stairs was wet.\n\n'
          'Wet shoes get drier with every step!',
      'type': 'sequence',
      'question': 'In what order did Miss Rose walk? Start with her first step.',
      'options': [
        {'id': 'cafe', 'label': 'The café'},
        {'id': 'door', 'label': 'The north door'},
        {'id': 'shop', 'label': 'The shop'},
        {'id': 'stairs', 'label': 'The stairs'},
      ],
      'codeLength': 4,
      'answer': 'shop,stairs,cafe,door',
      'hints': [
        'Her first step is the wettest one. Her last step is the driest one.',
        'Very wet, wet, a little wet, almost dry.',
      ],
      'clue': {
        'id': 'ep03_c3',
        'title': 'The North Door',
        'value': 'North',
        'symbol': 'footprint',
        'note': 'Miss Rose left by the north door.',
      },
      'evidence': {
        'id': 'ep03_e3',
        'name': 'Wet Footprint',
        'icon': 'footprint',
        'description': 'A small boot. It goes to the north door.',
        'inscription': 'The boot smells of trains and smoke.',
      },
      'successMessage': 'She left by the north door!',
      'transition': [
        'Outside the north door, a taxi driver is waiting.',
        '"A lady in a red coat?" he says. "I took her to the station."',
        'Which station?',
      ],
      'nextMissionId': 'ep03_final',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.3,
      'mapY': 0.62,
    },
  ],
  'finalMission': {
    'id': 'ep03_final',
    'number': 4,
    'title': 'The Way Out',
    'location': 'MUSEUM STREET',
    'scene': 'britishMuseum',
    'story': [
      'The taxi driver tells you what he saw.',
      'Miss Rose had a long, flat parcel under her arm — the painting!',
    ],
    'letterIntro': 'He writes it down for you.',
    'letter':
        'The lady said: "Take me north, to the station."\n\n'
        'It is a big station.\n'
        'It has two big arches and a clock tower.\n'
        'Trains to the north leave from there.',
    'type': 'imageChoice',
    'question': 'Which picture shows where Miss Rose went?',
    'options': [
      {'id': 'a', 'label': 'Big Ben', 'artwork': 'bigBen'},
      {'id': 'b', 'label': 'Tower Bridge', 'artwork': 'towerBridge'},
      {'id': 'c', 'label': 'Hyde Park', 'artwork': 'hydePark'},
      {'id': 'd', 'label': "King's Cross", 'artwork': 'kingsCross'},
    ],
    'answer': 'd',
    'hints': [
      'Big Ben has a clock too. But is it a station with arches?',
      'Look for two big round arches where trains come in.',
    ],
    'evidence': {
      'id': 'ep03_e4',
      'name': 'Luggage Tag',
      'icon': 'ticket',
      'description': 'It fell out of the taxi.',
      'inscription': "KING'S CROSS — LOST PROPERTY",
    },
    'successMessage': "Miss Rose went to King's Cross!",
    // After the case is closed: the post-case story scene (existing facts only).
    'transition': [
      'Miss Rose is gone.',
      'But something fell out of her taxi.',
      'A luggage tag.',
      "KING'S CROSS\nLOST PROPERTY",
      'And the missing painting?',
      'It shows a tower\nfull of ravens.',
    ],
    'skills': ['reading', 'problemSolving'],
    'mapX': 0.76,
    'mapY': 0.84,
  },
  'glossary': {
    'vanishing': '사라지는',
    'vanished': '사라졌다',
    'painting': '그림',
    'frame': '액자, 틀',
    'empty': '비어 있는',
    'hurry': '서두름',
    'button': '단추',
    'cloth': '천 조각',
    'footprint': '발자국',
    'footprints': '발자국들',
    'wet': '젖은',
    'wetter': '더 젖은',
    'dry': '마른',
    'drier': '더 마른',
    'almost': '거의',
    'bench': '벤치, 긴 의자',
    'report': '보고서',
    'visitors': '방문객들',
    'wore': '입었다',
    'scarf': '목도리',
    'coat': '코트, 외투',
    'caught': '걸린',
    'mummies': '미라들',
    'court': '안뜰',
    'roof': '지붕',
    'cleaner': '청소부',
    'step': '걸음',
    'north': '북쪽',
    'arches': '아치들',
    'station': '기차역',
    'parcel': '꾸러미',
    'sewn': '바느질된',
    'taxi': '택시',
    'museum': '박물관',
  },
};
