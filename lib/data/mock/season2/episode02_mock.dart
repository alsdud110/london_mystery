/// Season 2, Case 02 — The Vanishing Painter (Montmartre, Paris).
/// Theme: looking closer — a painting says more than it shows.
///
/// Case 01 ended on a painting from the Clockmaker's brass box: Montmartre's
/// white church, the same as on the lost ticket, and FIND THE PAINTER on its
/// back. The detective follows the ticket to Montmartre. The painter is
/// gone; his paintings, his notes and one hidden sketch are left behind.
///
/// Every step is played on the case's own pictures, and says only what they
/// show (`season2_scenes.dart` measures where):
/// 1. The painter's note says where to look: ABOVE the red door, the window
///    that is MISSING, the lamp BESIDE the steps. Comparing the real street
///    with his painting of it, the detective finds the three changes (a
///    small clock added, the right-hand window left out, the lamp made
///    bright). The back of the note: his secret is not on this street.
/// 2. In his studio, three paintings of one square are found and joined to
///    three notes by their sky and their stones (BEFORE THE RAIN, AFTER THE
///    RAIN STOPPED, WHEN THE SKY TURNED GOLD). Under note C: his secret was
///    hidden on a blue-sky day.
/// 3. The canvas on his big easel is thick paint and no picture: slid away,
///    a pencil sketch is underneath — stone steps, an old lamp and an iron
///    gate between two pillars. His note: the gate is black.
/// 4. Four canvases. Each clue rules out at least one and none is enough
///    alone: A has the red door, B a gold sky (and no gate), D a blue gate.
///    C, steps, a lamp and a black gate under a blue sky, is turned round:
///    "A city can lose an hour. But who can steal it?" He hid his own sketch
///    and left his notes for the detective: nobody took him; he left on his
///    own, to keep the secret safe.
///
/// Who the Clockmaker is stays untold; Case 03's place is not named.
const Map<String, dynamic> season2Episode02Json = {
  'id': 's2_ep02',
  'seasonId': 's2_paris',
  'number': 2,
  'title': 'The Vanishing Painter',
  'place': 'MONTMARTRE · PARIS',
  'synopsis': [
    'The painting from the brass box shows Montmartre.',
    'On its back: FIND THE PAINTER.',
    'But the painter has vanished.',
  ],
  'objectives': [
    'Find the street in the painting.',
    "Search the painter's studio.",
    'Find the message he left behind.',
  ],
  // The painting found in Case 01's brass box: the place it shows is where
  // the case begins.
  'introScene': 'montmartrePainting',
  'intro': [
    'Montmartre. A hill high above Paris.',
    'The lost ticket said MONTMARTRE. The painting showed this hill.',
    'On its back, three words: FIND THE PAINTER.',
    'But who is the painter?',
    'And why was his painting hidden under an old clock?',
  ],
  'caseSummary':
      "You compared the painted street, matched the painter's notes and uncovered his hidden sketch. Behind the right canvas, he left a message.",
  'keyWords': ['above', 'missing', 'beside', 'before', 'after', 'underneath'],
  'hook': 'Nobody took the painter. He left to keep a secret. Who can steal an hour?',
  'missions': [
    {
      'id': 's2_ep02_m1',
      'number': 1,
      'title': 'The Painted Street',
      'location': 'A STREET IN MONTMARTRE',
      'scene': 'montmartreStreet',
      'story': [
        'Near the white church, you find a quiet street.',
        'A red door. Stone steps. An old lamp.',
        'On the corner stands an easel. Nobody is painting.',
        'But a painting of this street is still on it.',
      ],
      'letterIntro': 'A note is pinned to the painting:',
      'letter':
          'I did not paint this street as it is.\n'
          'I changed three things.\n\n'
          'Look above the red door.\n'
          'Find the window that is missing.\n'
          'Check the lamp beside the steps.\n\n'
          '— P.',
      // The three changes, found on the street or on the painting (the same
      // place on both); any order.
      'type': 'spotDifferences',
      'question': 'Find the three changes.',
      'options': [
        {'id': 'clock', 'label': 'A small clock above the red door'},
        {'id': 'window', 'label': 'A window is missing'},
        {'id': 'lamp', 'label': 'The lamp beside the steps is bright'},
      ],
      'answer': 'clock,window,lamp',
      'hints': [
        'Read the note one line at a time. Each line tells you where to look.',
        'ABOVE means higher than. MISSING means it is not there. BESIDE means next to.',
      ],
      'clue': {
        'id': 's2_ep02_c1',
        'title': 'Not This Street',
        'value': 'Not the red door',
        'symbol': 'frame',
        'note': 'On the back of his note: "My secret is not on this street. Look far from the red door."',
      },
      'evidence': {
        'id': 's2_ep02_e1',
        'name': 'The Painted Street',
        'icon': 'frame',
        'description': 'Left on the easel, on the corner of the street.',
        'inscription':
            'Above the red door: a small clock. The real street has none. One window is missing. The lamp is bright. '
            'On the back of the note: My secret is not on this street.',
      },
      'successMessage': 'You found all three!',
      'transition': [
        'The painter changed three things.',
        'A clock above the red door. A missing window. A bright lamp.',
        'You turn his note over. One more line:',
        '"My secret is not on this street. Look far from the red door."',
        'Under the easel, you find a key. Its tag says: STUDIO, TOP FLOOR.',
      ],
      'nextMissionId': 's2_ep02_m2',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.5,
      'mapY': 0.16,
    },
    {
      'id': 's2_ep02_m2',
      'number': 2,
      'title': "The Artist's Studio",
      'location': "THE PAINTER'S STUDIO",
      'scene': 'paintersStudio',
      'story': [
        'The key opens a door at the top of narrow stairs.',
        'Sunlight. The smell of paint. The studio is quiet.',
        'Nobody is here. But the painter left his things behind.',
      ],
      'letterIntro': 'Three notes lie on his desk:',
      // Found on the desk in the studio. The three paintings show the same
      // square; only their sky and their stones tell them apart.
      'letter':
          'A — I painted this BEFORE THE RAIN.\n'
          'Dark clouds were coming. The stones were still dry.\n\n'
          'B — I painted this AFTER THE RAIN STOPPED.\n'
          'The stones were wet and shiny.\n\n'
          'C — I painted this WHEN THE SKY TURNED GOLD.\n'
          'The whole sky was gold. The stones were dry.',
      // Each note joined to its painting (`note:painting`, any order): p1 the
      // gold sky over dry stones, p2 dark clouds over dry stones, p3 wet and
      // shiny stones. The notes' order is never the paintings'.
      'type': 'matchPairs',
      'question': 'Match each note to its painting.',
      'options': [
        {'id': 'a', 'label': 'A — BEFORE THE RAIN'},
        {'id': 'b', 'label': 'B — AFTER THE RAIN STOPPED'},
        {'id': 'c', 'label': 'C — WHEN THE SKY TURNED GOLD'},
      ],
      'answer': 'a:p2,b:p3,c:p1',
      'feedback': {
        'a:p1': 'Read note A again. Where are the dark clouds?',
        'a:p3': 'Read note A again. BEFORE THE RAIN, the stones were still dry.',
        'b:p1': 'Read note B again. AFTER THE RAIN, the stones are wet and shiny.',
        'b:p2': 'Read note B again. AFTER THE RAIN, the stones are wet and shiny.',
        'c:p2': 'Read note C again. Is the whole sky gold?',
        'c:p3': 'Read note C again. Were the stones dry?',
      },
      'hints': [
        'Each note says WHEN it was painted. Look at the sky and the stones in each painting.',
        'BEFORE THE RAIN, the stones are dry. AFTER THE RAIN, they are wet and shiny.',
      ],
      'clue': {
        'id': 's2_ep02_c2',
        'title': 'A Blue-Sky Day',
        'value': 'A blue sky',
        'symbol': 'letter',
        'note': 'Under note C, one more line: "My secret is not in a gold sky. I hid it on a blue-sky day."',
      },
      'evidence': {
        'id': 's2_ep02_e2',
        'name': "The Artist's Notes",
        'icon': 'letter',
        'description': 'On his desk, beside his paintings of one square.',
        'inscription':
            'BEFORE THE RAIN. AFTER THE RAIN STOPPED. WHEN THE SKY TURNED GOLD. '
            'Under note C: I hid my secret on a blue-sky day.',
      },
      'successMessage': 'Every note has its painting!',
      'transition': [
        'Every note matches its painting.',
        'Under note C, one more line in pencil:',
        '"My secret is not in a gold sky. I hid it on a blue-sky day."',
        'By the window stands a big easel.',
        'Its canvas is covered in thick paint. Is something underneath?',
      ],
      'nextMissionId': 's2_ep02_m3',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.58,
      'mapY': 0.13,
    },
    {
      'id': 's2_ep02_m3',
      'number': 3,
      'title': 'The Hidden Layer',
      'location': "THE PAINTER'S EASEL",
      'scene': 'paintersStudio',
      'story': [
        'The big easel stands by the window.',
        'Its canvas is covered in thick paint. Blue, red, yellow. No picture at all.',
        'Why would a painter do that?',
      ],
      'letterIntro': 'A note is tucked into the frame:',
      'letter':
          'I painted over my sketch.\n'
          'Slide the paint away\n'
          'and look UNDERNEATH.\n\n'
          'My pencil has no colours.\n'
          'So remember: the gate is black.\n\n'
          '— P.',
      // The paint slid away, the three things of the sketch found (any
      // order). How far the paint is slid and what is found are kept apart.
      'type': 'revealLayer',
      'question': 'Find the lamp, the steps and the gate.',
      'options': [
        {'id': 'lamp', 'label': 'An old lamp'},
        {'id': 'steps', 'label': 'Stone steps'},
        {'id': 'gate', 'label': 'An iron gate between two stone pillars'},
      ],
      'answer': 'lamp,steps,gate',
      'hints': [
        'Slide the paint away first. The sketch is underneath.',
        'The lamp is tall and thin. The steps are at the bottom. The gate is between two stone pillars.',
      ],
      'clue': {
        'id': 's2_ep02_c3',
        'title': 'The Hidden Sketch',
        'value': 'Steps, a lamp, a black gate',
        'symbol': 'seal',
        'note': 'Under the paint: stone steps, an old lamp and an iron gate between two pillars. His note says: the gate is black.',
      },
      'evidence': {
        'id': 's2_ep02_e3',
        'name': 'The Hidden Sketch',
        'icon': 'seal',
        'description': 'Found underneath the thick paint on his big easel.',
        'inscription':
            'A pencil sketch: stone steps, an old lamp, an iron gate between two pillars, the white church above. The gate is black.',
      },
      'successMessage': 'The sketch is uncovered!',
      'transition': [
        'What changed? The painter covered his own sketch with paint.',
        'What was hidden? A place: stone steps, an old lamp and a black iron gate.',
        'Why does it matter? Nobody else hid it. He did, on purpose.',
        'Against the wall, four canvases are waiting.',
      ],
      'nextMissionId': 's2_ep02_final',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.64,
      'mapY': 0.18,
    },
  ],
  'finalMission': {
    'id': 's2_ep02_final',
    'number': 4,
    'title': 'Behind the Canvas',
    'location': "THE PAINTER'S STUDIO",
    'scene': 'paintersStudio',
    'story': [
      'Four canvases lean against the wall.',
      'Streets, steps and sky. They look alike.',
      'Only one has a message on its back.',
    ],
    'letterIntro': 'Your notebook says:',
    'letter':
        'YOUR CLUES\n\n'
        'THE PAINTED STREET\n'
        'Not the street with the red door.\n\n'
        "THE ARTIST'S NOTES\n"
        'I hid my secret on a blue-sky day.\n\n'
        'THE HIDDEN SKETCH\n'
        'Steps, a lamp and a black gate.\n\n'
        'One canvas matches all three.',
    // Four canvases, each a different place; no clue alone finds the right
    // one: A has the red door, B a gold sky (and no gate by any steps), D a
    // blue gate. C has steps, a lamp and a black gate under a blue sky. The
    // labels say what each shows (for screen readers and the parents'
    // report); the page shows the canvases, never these words.
    'type': 'canvasChoice',
    'question': 'Which canvas hides the message?',
    'options': [
      {
        'id': 'a',
        'label': 'A red door, a lamp and stone steps',
        'feedback': 'Check the clue from the painted street. Is there a red door?',
      },
      {
        'id': 'b',
        'label': 'A café square under a gold sky',
        'feedback': "Check the artist's notes. Is the sky blue?",
      },
      {'id': 'c', 'label': 'Stone steps, a lamp and a black iron gate'},
      {
        'id': 'd',
        'label': 'Stone steps, a lamp and a blue gate',
        'feedback': 'Check the hidden sketch. What colour is the gate?',
      },
    ],
    'answer': 'c',
    'hints': [
      'Check every canvas against all three clues. Three clues, one canvas.',
      'No red door. A blue sky. A black gate beside the steps.',
    ],
    'evidence': {
      'id': 's2_ep02_e4',
      'name': "The Painter's Message",
      'icon': 'letter',
      'description': 'Written on the back of his canvas.',
      'inscription': 'A city can lose an hour. But who can steal it?',
    },
    'successMessage': 'You found the right canvas!',
    // After the case is closed: the post-case scene, then the case report.
    // What the detective found says it, before the painter's words do: he
    // hid his own sketch (M3) and left his notes to be found (M1, M2).
    'transition': [
      'On the back: ATELIER MONTMARTRE, his studio.',
      'And three words in French: TOUJOURS PLUS HAUT. Always higher.',
      'Below, in the same hand as FIND THE PAINTER:',
      'A city can lose an hour.\nBut who can steal it?',
      '"I saw who took the hour. So I hid my sketch, left my notes for you, and went away to keep the secret safe. — P."',
      'Nobody took the painter.',
      'He hid his own sketch. He left his notes for you.',
      'He left on his own.',
      'But someone is still stealing the hours of Paris.',
    ],
    'skills': ['problemSolving', 'reading'],
    'mapX': 0.55,
    'mapY': 0.1,
  },
  'glossary': {
    'painter': '화가',
    'painting': '그림',
    'paintings': '그림들',
    'painted': '그렸다',
    'vanished': '사라졌다',
    'easel': '이젤',
    'above': '~위에',
    'missing': '없어진, 빠진',
    'beside': '~옆에',
    'lamp': '가로등, 등',
    'bright': '밝은',
    'steps': '계단',
    'window': '창문',
    'changed': '바꿨다',
    'secret': '비밀',
    'studio': '작업실',
    'floor': '층',
    'stairs': '계단',
    'sunlight': '햇빛',
    'notes': '메모들',
    'desk': '책상',
    'before': '~전에',
    'after': '~후에',
    'rain': '비',
    'clouds': '구름',
    'stones': '돌, 돌바닥',
    'dry': '마른',
    'wet': '젖은',
    'shiny': '반짝이는',
    'gold': '금빛',
    'match': '맞추다, 짝짓다',
    'sketch': '밑그림, 스케치',
    'underneath': '밑에, 아래에',
    'layer': '층, 겹',
    'thick': '두꺼운',
    'covered': '덮인',
    'pencil': '연필',
    'colours': '색깔들',
    'gate': '문, 대문',
    'iron': '철로 된',
    'pillars': '기둥들',
    'purpose': '목적 (on purpose: 일부러)',
    'canvas': '캔버스(그림 천)',
    'canvases': '캔버스들',
    'lean': '기대어 있다',
    'message': '메시지, 전하는 말',
    'steal': '훔치다',
    'higher': '더 높이',
  },
};
