/// Case 09 — The Missing Jewel (Buckingham Palace). Theme: possession
/// ("whose", "'s", "has", "is not") and logic.
///
/// The thief never took the jewel out of the palace: she hid it in
/// something that belongs to someone else. Final case: R.'s note says to hide
/// it in the thing of "the one whose key you used". Anna used the key, but it
/// is the guard's (Mission 01: only the guard's big gold key opens the case;
/// the guard lent it to her) — "whose" is not "who had it". The guard is
/// Carl; the detective's notes on the three things leave Carl the hat.
const Map<String, dynamic> episode09Json = {
  'id': 'ep09',
  'number': 9,
  'title': 'The Missing Jewel',
  'synopsis': [
    'The Blue Star, a royal jewel, has gone from its box.',
    'But the thief did not take it out of the palace.',
    'Find out whose things hide the secret.',
  ],
  'objectives': ['Find out who opened the jewel box.', 'Find where the jewel is hidden.'],
  // The place the intro opens on (its picture behind the story lines).
  'introScene': 'buckinghamPalace',
  'intro': [
    'Buckingham Palace, 10:00 AM...',
    'The jewel box from Mrs Robin\'s suitcase came from here.',
    'The Blue Star, a royal jewel, is gone.',
    'But the palace gates were locked all night.',
    'The jewel is still inside the palace. Somewhere.',
  ],
  'caseSummary': 'You worked out whose key, whose name and whose hat — and found the Blue Star.',
  'keyWords': ['whose', 'belongs', 'has'],
  'hook': 'Inside the hat, a card: "The jewel was never the prize. Watch the ravens."',
  'missions': [
    {
      'id': 'ep09_m1',
      'number': 1,
      'title': 'The Empty Box',
      'location': 'THE JEWEL ROOM',
      'scene': 'jewelCase',
      'story': [
        'The glass case is open. The velvet cushion is empty.',
        'The lock was not broken. Somebody used a key.',
      ],
      'letterIntro': 'The head butler tells you about the keys.',
      'letter':
          'Three people have a key to this room.\n\n'
          "The maid's key is small and silver.\n"
          "The cook's key is old and iron.\n"
          "The guard's key is big and gold.\n\n"
          'The jewel case opens only with a big gold key.',
      'type': 'multipleChoice',
      'question': 'Whose key opened the jewel case?',
      'options': [
        {'id': 'a', 'label': "The maid's key"},
        {'id': 'b', 'label': "The cook's key"},
        {'id': 'c', 'label': "The guard's key"},
        {'id': 'd', 'label': "The King's key"},
      ],
      'answer': 'c',
      'hints': [
        "\"The maid's key\" means the key that belongs to the maid.",
        'Read the last line. Then find the key that is big and gold.',
      ],
      'clue': {
        'id': 'ep09_c1',
        'title': 'The Gold Key',
        'value': 'Guard',
        'symbol': 'key',
        'note': "Only the guard's big gold key opens the case.",
      },
      'evidence': {
        'id': 'ep09_e1',
        'name': 'Velvet Card',
        'icon': 'gem',
        'description': 'Left on the empty cushion.',
        'inscription': '"I did not take it far." — R.',
      },
      'successMessage': "It was the guard's key!",
      'transition': [
        'The guard looks surprised.',
        '"My key? Yesterday I gave it to the new helper!"',
        'But what is the new helper\'s name?',
      ],
      'nextMissionId': 'ep09_m2',
      'skills': ['reading', 'vocabulary'],
      'mapX': 0.26,
      'mapY': 0.62,
    },
    {
      'id': 'ep09_m2',
      'number': 2,
      'title': 'The New Helper',
      'location': 'THE STAFF ROOM',
      'scene': 'staffRoom',
      'story': [
        'Coats hang on hooks. Each hook has a name tag.',
        "The new helper's tag is torn.",
      ],
      'letterIntro': 'The guard tries to remember.',
      'letter':
          'Her name has four letters.\n'
          'It starts with A, and it ends with A.\n'
          'The two letters in the middle are the same.\n'
          'They are the letter after M in the alphabet.',
      'type': 'wordInput',
      'question': "What is the new helper's name?",
      'prompt': 'NAME: ____',
      'answer': 'ANNA',
      'hints': [
        'Say the alphabet: ... K, L, M, and then?',
        'Put that letter two times between the two As.',
      ],
      'clue': {
        'id': 'ep09_c2',
        'title': 'The New Helper',
        'value': 'Anna',
        'symbol': 'ticket',
        'note': "Anna had the guard's key.",
      },
      'evidence': {
        'id': 'ep09_e2',
        'name': 'Torn Name Tag',
        'icon': 'ticket',
        'description': 'From the hook of the new helper.',
        'inscription': 'A _ _ A — a raven is drawn on the back.',
      },
      'successMessage': 'The new helper is Anna!',
      'transition': [
        'Anna is not in the staff room.',
        'The guard says: "The guards change in the courtyard."',
        '"That is when nobody is watching the jewel room."',
      ],
      'nextMissionId': 'ep09_m3',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.72,
      'mapY': 0.44,
    },
    {
      'id': 'ep09_m3',
      'number': 3,
      'title': 'The Changing of the Guard',
      'location': 'THE COURTYARD',
      'scene': 'courtyard',
      'story': [
        'Soldiers in red coats march across the courtyard.',
        'The guard shows you the timetable.',
      ],
      'letterIntro': 'The timetable says:',
      'letter':
          'The guards change every two hours.\n'
          "The first change is at eight o'clock.\n\n"
          'A note in pencil at the bottom:\n'
          '"Anna was seen at the third change."',
      'type': 'numberCode',
      'question': 'At what hour was Anna seen?',
      'codeLength': 2,
      'answer': '12',
      'hints': [
        'Write down the first change. Then add two hours for the next one.',
        'First, second, third: count three changes.',
      ],
      'clue': {
        'id': 'ep09_c3',
        'title': 'The Third Change',
        'value': '12',
        'symbol': 'clock',
        'note': "Anna hid the jewel at twelve o'clock.",
      },
      'evidence': {
        'id': 'ep09_e3',
        'name': 'Guard Timetable',
        'icon': 'clock',
        'description': 'When the guards change.',
        'inscription': '8 · 10 · 12 · 2 · 4',
      },
      'successMessage': "Twelve o'clock!",
      'transition': [
        "At twelve o'clock, three people were in the courtyard:",
        'Anna, Ben the gardener and Carl the guard.',
        'Each of them had one thing with them.',
      ],
      'nextMissionId': 'ep09_final',
      'skills': ['problemSolving', 'reading'],
      'mapX': 0.3,
      'mapY': 0.24,
    },
  ],
  'finalMission': {
    'id': 'ep09_final',
    'number': 4,
    // The title shows on the map before the answer: it names neither the
    // owner nor the thing.
    'title': 'The Three Things',
    'location': 'THE PALACE GATE',
    'scene': 'buckinghamPalace',
    'story': [
      'Anna, Ben the gardener and Carl the guard stand at the palace gate.',
      'One of their things is hiding the Blue Star.',
    ],
    'letterIntro': 'A small note falls out of Anna\'s pocket. It is signed R.',
    // R.'s note gives the rule; which key it was is Mission 01's (the
    // guard's, lent to Anna); the detective's notes give whose thing is
    // whose. Typing Anna's thing (she used the key) is the slip to avoid.
    'letter':
        'Hide it in the thing of the one whose key you used.\n'
        '— R.\n\n'
        'Your notes:\n'
        'Three things: a red umbrella, a green bag and a tall black hat.\n'
        'Ben has the green bag.\n'
        "Anna's thing is not black.",
    'type': 'wordInput',
    'question': 'Where is the jewel? Type the thing.',
    'prompt': 'IN THE ___',
    'answer': 'HAT',
    'acceptedAnswers': ['BLACK HAT', 'TALL BLACK HAT', 'THE HAT', 'THE BLACK HAT', 'CARLS HAT'],
    'hints': [
      'Anna used the key. But whose key was it? Think back to the Jewel Room.',
      'Open your notebook: whose key opened the jewel case? Find the owner here, then use your notes to find the owner\'s thing.',
    ],
    'evidence': {
      'id': 'ep09_e4',
      'name': 'The Blue Star',
      'icon': 'gem',
      'description': 'The royal jewel. Back where it belongs.',
      'inscription': 'Found inside a guard\'s tall black hat.',
    },
    'successMessage': 'The Blue Star was in the hat!',
    // After the case is closed: the post-case story scene (existing facts only).
    'transition': [
      'The Blue Star is safe.',
      "But on the back of Anna's name tag,\na raven is drawn.",
      'And the card inside the hat\nleft a warning:',
      '"The jewel was never the prize."',
      '"Watch the ravens."',
    ],
    'skills': ['problemSolving', 'reading'],
    'mapX': 0.74,
    'mapY': 0.82,
  },
  'glossary': {
    'jewel': '보석',
    'royal': '왕실의',
    'velvet': '벨벳',
    'cushion': '쿠션, 방석',
    'broken': '부서진',
    'butler': '집사',
    'maid': '하녀, 가정부',
    'cook': '요리사',
    'guard': '경비병',
    'silver': '은색의',
    'iron': '쇠',
    'gold': '금색의',
    'whose': '누구의',
    'belongs': '~의 것이다',
    'helper': '도우미',
    'surprised': '놀란',
    'hooks': '고리들',
    'hook': '고리',
    'torn': '찢어진',
    'alphabet': '알파벳',
    'middle': '가운데',
    'staff': '직원',
    'courtyard': '안뜰',
    'soldiers': '군인들',
    'march': '행진하다',
    'timetable': '시간표',
    'change': '교대',
    'changes': '교대하다',
    'pencil': '연필',
    'seen': '보였다',
    'gardener': '정원사',
    'umbrella': '우산',
    'hiding': '숨기고 있는',
    'prize': '상, 목표물',
  },
};
