/// Season 2, Case 08 — The Painter's Last Sketch (Abbesses, Montmartre).
/// Theme: what a picture shows, and what can be told from it.
///
/// Case 07 ended on the back of the Amendment Slip: a pencil sketch of
/// Abbesses and P. KNEW THE BAG. (`docs/SEASON2_CASE08_SPEC.md`; story
/// bible v1.6, §6 Case 08.)
///
/// Every step is played on the case's own pictures, with the rules of
/// `season2_case08_scenes.dart`:
/// 1. Three corners of the square, each with steps, a lamp and a gate
///    between two pillars. Case 02's Hidden Sketch decides: its picture
///    (the lamp left of the gate) and its words (the gate is black). The
///    painter's drawings are behind a loose stone.
/// 2. Three drawings of that corner, put in order by the sky and the lamp
///    (P.'s tag gives the rule), then laid over each other: someone with a
///    flat bag full of papers comes out of the gate and goes up the steps;
///    after, a paper lies on the bottom step. It fell from the bag.
/// 3. A folded paper with P.'s note (he found it on the steps): unfolded
///    and set beside the Amendment Slip (Case 07), the same form and seal;
///    its FILE number and its hour torn away.
/// 4. The paper laid on P.'s drawing of it (its V-shaped tear), and the
///    board: a paper for changing a time fell from the bag. P.'s last
///    drawing shows the same bag beside a little clock in a garden.
///
/// Who carried the bag, what the badge means, whose change it was, the
/// paper's file and hour, when P. drew it, and why the bag went to the
/// garden stay untold. Nothing of time itself vanished.
const Map<String, dynamic> season2Episode08Json = {
  'id': 's2_ep08',
  'seasonId': 's2_paris',
  'number': 8,
  'title': "The Painter's Last Sketch",
  'place': 'ABBESSES · MONTMARTRE',
  'synopsis': [
    'A slip from the opera says: P. KNEW THE BAG.',
    'P. is the painter who went away.',
    'What did he see?',
  ],
  // Never what fell from the bag: that is found in the drawings.
  'objectives': [
    'Find where the painter sat.',
    'Read his drawings.',
    'Find out what P. saw.',
  ],
  'introScene': 'abbessesSquare',
  'intro': [
    'You turn the opera slip over again.',
    'A tiny pencil sketch: steps, a lamp, a metro sign. ABBESSES.',
    'Under it: P. KNEW THE BAG.',
    'P. is the painter from Montmartre. He said: I saw who took the hour.',
    'What bag? What did he see?',
    "Abbesses is a metro stop on the hill of Montmartre. Let's go.",
  ],
  'caseSummary':
      "You found the painter's corner, put his morning drawings in order, matched a torn paper to the opera slip, and proved it fell from the bag. Then his last drawing showed the same bag in a garden.",
  'keyWords': ['left', 'right', 'above', 'between', 'first', 'next', 'last', 'same', 'missing', 'torn'],
  'hook': 'Why did the bag go to the little clock in the garden?',
  'missions': [
    {
      'id': 's2_ep08_m1',
      'number': 1,
      'title': 'The Hidden Sketch',
      'location': 'ABBESSES · MONTMARTRE',
      'scene': 'abbessesSquare',
      'story': [
        'Abbesses. A small square on the hill of Montmartre.',
        'There is the metro sign from the slip.',
        'But look around. Steps, lamps and gates are everywhere.',
        'Where did the painter sit to draw?',
      ],
      'letterIntro': 'In your notebook, you wrote:',
      // The sketch's things only: where they stand is in its picture, the
      // gate's colour in its words.
      'letter':
          'The painter hid a sketch in his studio.\n'
          'Steps. An old lamp. A gate between two pillars.\n'
          'The white church above.\n'
          'Which corner did he draw?',
      // Three corners, the pictures only (see `season2CornerChoices`): the
      // first has a dark green gate, the third has its lamp and steps on
      // the right.
      'type': 'multipleChoice',
      'hideOptionNames': true,
      'question': 'Where did the painter sit to draw his sketch?',
      'options': [
        {
          'id': 'corner1',
          'label': 'Corner 1',
          'feedback': 'The steps, the lamp and the church match. Now read the sketch in your notebook. What colour is the gate?',
        },
        {'id': 'corner2', 'label': 'Corner 2'},
        {
          'id': 'corner3',
          'label': 'Corner 3',
          'feedback': 'Look at the sketch again. Is the lamp on the left of the gate, or on the right?',
        },
      ],
      'answer': 'corner2',
      'hints': [
        "Bring the painter's hidden sketch from your notebook. Look at it beside each corner.",
        'Check two things: where the lamp stands, and the colour of the gate. The sketch has no colours. Read its words.',
      ],
      'recall': {
        'evidence': 's2_ep02_e3',
        'title': 'These steps look familiar...',
        'prompt': 'Find the drawing the painter hid.',
        'feedback': {
          's2_ep07_e3': 'That sketch brought you to Abbesses. Find the one he hid in his studio.',
          's2_ep02_e1': 'That street has a red door. Look for steps and a gate.',
          's2_ep02_e4': 'That message was on the back of a canvas. Find the sketch under the paint.',
        },
      },
      'clue': {
        'id': 's2_ep08_c1',
        'title': "The Painter's Corner",
        'value': 'Lamp left · black gate',
        'symbol': 'frame',
        'note': 'The corner in his hidden sketch. His drawings were behind a loose stone.',
      },
      'evidence': {
        'id': 's2_ep08_e1',
        'name': "The Painter's Spot",
        'icon': 'frame',
        'description': 'A corner in Abbesses, behind a loose stone.',
        'inscription':
            'Steps on the left, an old lamp left of the gate, a black iron gate between two pillars, the white church above. '
            'The same place as his hidden sketch. A bundle of drawings was hidden in the left pillar.',
      },
      'successMessage': "You found the painter's corner!",
      'transition': [
        'The lamp on the left. The church above. A black gate.',
        "This is the corner in the painter's sketch.",
        'One stone in the left pillar is loose.',
        'Behind it: a bundle of drawings, tied with string.',
      ],
      'nextMissionId': 's2_ep08_m2',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.5,
      'mapY': 0.2,
    },
    {
      'id': 's2_ep08_m2',
      'number': 2,
      'title': 'The Morning Drawing',
      'location': "THE PAINTER'S CORNER",
      'scene': 'drawingBundle',
      'story': [
        'You untie the string.',
        'Three pencil drawings of this corner.',
        'The same steps. The same lamp. The same gate.',
        'But they are not the same.',
      ],
      'letterIntro': 'A tag on the string says:',
      // The rule only: which drawing is which is for the detective.
      'letter':
          'I drew this corner one morning.\n'
          'First, the sky was dark.\n'
          'Then it grew light.\n'
          'When the sun came up, the lamps went out.\n'
          '— P.',
      // Asked once the drawings are in order and laid over each other
      // (see `season2MorningSketches`).
      'type': 'multipleChoice',
      'question': 'Where did the paper on the steps come from?',
      'options': [
        {
          'id': 'always',
          'label': 'It was on the steps all morning.',
          'feedback': 'Look at drawings 1 and 2. Is there a paper on the steps?',
        },
        {
          'id': 'painter',
          'label': 'The painter dropped it.',
          'feedback': 'The painter was drawing from across the street. The paper is on the steps.',
        },
        {
          'id': 'window',
          'label': 'It fell from a window.',
          'feedback': 'Look at drawing 2. Who was on those steps just before the paper came?',
        },
        {'id': 'bag', 'label': 'It fell from the bag.'},
      ],
      'answer': 'bag',
      'hints': [
        "Read P.'s tag. Dark sky first. When the sun comes up, the lamps go out.",
        'When does the paper come? Who was on those steps just before? Look closely at the bag.',
      ],
      'clue': {
        'id': 's2_ep08_c2',
        'title': 'It Fell from the Bag',
        'value': 'Paper after the bag',
        'symbol': 'frame',
        'note': 'No paper in drawings 1 and 2. The bag went up the steps. Then the paper was there.',
      },
      'evidence': {
        'id': 's2_ep08_e2',
        'name': 'The Bag Sketch',
        'icon': 'frame',
        'description': "Three drawings of one morning, from the painter's corner.",
        'inscription':
            'Someone in a hat, back turned, comes out of the black gate with a flat bag and climbs the steps. '
            'The bag is so full that papers stick out under its flap. Two buckles. '
            'On the flap: a small shield badge with leaves around its edge. '
            'Then a paper lies on the bottom step. No face. No name.',
      },
      'successMessage': 'It fell from the bag!',
      'transition': [
        'Drawing 1: nobody is here.',
        'Drawing 2: someone comes through the gate with a flat bag. It is so full that papers stick out.',
        'Drawing 3: the person is gone. A paper lies on the steps.',
        'The paper fell from the bag!',
        "In the corner, P. drew the bag's badge: a small shield with leaves around its edge.",
        'And the face? P. drew only a hat and a back.',
      ],
      'nextMissionId': 's2_ep08_m3',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.56,
      'mapY': 0.16,
    },
    {
      'id': 's2_ep08_m3',
      'number': 3,
      'title': 'The Purple Seal',
      'location': "THE PAINTER'S CORNER",
      'scene': 'drawingBundle',
      'story': [
        'Behind the three drawings is one more paper.',
        'It is folded small. It is not a drawing.',
        'A note is clipped to it.',
      ],
      'letterIntro': "P.'s note says:",
      // That he picked it up, never where it came from.
      'letter':
          'I found this paper on the steps.\n'
          'I kept it with my drawings.\n'
          '— P.',
      // Every part marked on the paper (`same:` four, `missing:` two, any
      // order). A check before all are marked sends the first thing still
      // to do (`need:`), never a part of the answer.
      'type': 'matchPairs',
      'question': 'What is the same as the opera slip? What is missing?',
      'options': [
        {'id': 'same', 'label': 'The same as the opera slip'},
        {'id': 'missing', 'label': 'Missing from this paper'},
      ],
      'answer': 'same:border,same:band,same:arrow,same:seal,missing:number,missing:hour',
      'feedback': {
        'need:same': 'Look again. Four things on this paper are just like the opera slip.',
        'need:seal': 'Look closely at the seal. Count the hands.',
        'need:hour': 'Read the times on the opera slip. What is in front of :00?',
        'need:number': 'The opera slip says FILE 3. What does this paper say after FILE?',
      },
      'hints': [
        'Bring the opera slip from your notebook. Put it beside this paper.',
        'Look closely at the seal: count the hands, and look around the clock. Then read FILE and the times on both papers.',
      ],
      'recall': {
        'evidence': 's2_ep07_e3',
        'title': 'Have you seen this seal before?',
        'prompt': 'Find the slip from the opera.',
        'feedback': {
          's2_ep01_e3': 'That mark is a gear. Is this a gear?',
          's2_ep05_e1': 'Count the hands. This seal has none.',
          's2_ep07_e4': 'That is FILE 3 itself. Find the small slip that said to change it.',
          's2_ep06_e4': 'That is Letter 4417. Look for a purple seal.',
        },
      },
      'clue': {
        'id': 's2_ep08_c3',
        'title': 'The Same Seal',
        'value': 'No hands · leaves',
        'symbol': 'seal',
        'note': 'Same form and seal as the opera slip. The FILE number and the hour are torn away.',
      },
      'evidence': {
        'id': 's2_ep08_e3',
        'name': 'The Matching Seal',
        'icon': 'seal',
        'description': "A torn, folded paper, kept with P.'s drawings.",
        'inscription':
            "P.'s note: I found this paper on the steps. "
            'The same form as the opera slip: a double border, a FILE band, a time with an arrow, '
            'and the same purple seal, a clock with no hands in a ring of leaves. '
            'The FILE number and the hour are torn away.',
      },
      'successMessage': 'The same seal!',
      'transition': [
        'The same border. The same FILE band. An arrow between two times.',
        'And the same purple seal: a clock with no hands, in a ring of leaves.',
        'But the FILE number is torn away. So is the hour.',
        'This paper is like the opera slip. It is a paper for changing a time.',
        "P. found it on the steps. But is it the paper in his drawing?",
      ],
      'nextMissionId': 's2_ep08_final',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.62,
      'mapY': 0.22,
    },
  ],
  'finalMission': {
    'id': 's2_ep08_final',
    'number': 4,
    'title': 'The Torn Hour',
    'location': "THE PAINTER'S CORNER",
    'scene': 'paintersCorner',
    'story': [
      'You sit where the painter sat.',
      'Drawing 3 is on one side. The torn paper is on the other.',
      'Is it the same paper? And what does it tell us?',
    ],
    'letterIntro': 'Your evidence:',
    'letter':
        'THE BAG SKETCH\n'
        'A paper lies on the steps after the bag goes by.\n\n'
        'THE MATCHING SEAL\n'
        'A torn paper. The same form and seal as the opera slip.\n\n'
        'THE AMENDMENT SLIP\n'
        'FILE 3 · CURTAIN UP: 4:00 to 3:00.',
    // The paper laid on P.'s drawing first (`season2TornHours`), then the
    // board: each question's evidence, and what can be said now.
    'type': 'matchPairs',
    'question': 'What can you say now?',
    // Evidence on the board (`season2TornHours`): e1 the Painter's Spot,
    // e2 the Bag Sketch, e3 the Matching Seal, e4 the Amendment Slip (Case
    // 07, given on the board).
    'options': [
      {'id': 'q1', 'label': 'Where did the paper come from?'},
      {'id': 'q2', 'label': 'What kind of paper is it?'},
      {'id': 'why', 'label': 'What can you say now?'},
    ],
    'answer': 'q1:e2,q2:e3+e4,why:fell',
    'feedback': {
      'q1:e1': "That shows where P. sat. Which drawing shows the paper come?",
      'q1:e1+e2': 'Question 1 needs one piece only: the drawings of that morning.',
      'q1:e3': 'That is the paper itself. Which drawing shows where it came from?',
      'q1:e4': 'That slip was at the opera. Which drawing shows where this paper came from?',
      'q1:e2+e3': 'Question 1 needs one piece only: the drawings of that morning.',
      'q1:e2+e4': 'Question 1 needs one piece only: the drawings of that morning.',
      'q2:e3': 'What does a paper with this seal do? Which old clue shows it?',
      'q2:e4': 'The slip shows what the form is for. Which evidence is the paper itself?',
      'q2:e1': 'That shows where P. sat. Look at the paper and the opera slip.',
      'q2:e2': 'The drawings show where it came from. What kind of paper is it?',
      'q2:e2+e3': 'The drawings show where it came from. Which old clue shows what the form is for?',
      'q2:e1+e3': 'That shows where P. sat. Which old clue shows what the form is for?',
      'q2:e1+e3+e4': 'Question 2 needs two pieces only: the paper, and the opera slip.',
      'q2:e2+e3+e4': 'Question 2 needs two pieces only: the paper, and the opera slip.',
      'why:': 'Choose what the evidence shows.',
      'why:parts': 'What fell from the bag? A clock part, or a paper?',
      'why:painter': 'The painter was drawing. Who walked up the steps?',
      'why:who': 'Did P. draw a face, or write a name? What do we really know?',
    },
    'hints': [
      'First, turn the paper until its V-shaped tear matches the drawing.',
      'Which evidence shows where the paper came from? Which ones show what kind of paper it is?',
    ],
    'evidence': {
      'id': 's2_ep08_e4',
      'name': 'The Torn Hour',
      'icon': 'letter',
      'description': "The torn paper, laid on P.'s drawing of the steps.",
      'inscription':
          'The same V-shaped tear as the paper in drawing 3. It lay on the steps just after the bag went by. '
          'The same form and seal as the opera slip. A paper for changing a time fell from the bag. '
          'Who carried it, and who changed what, is not known.',
    },
    'successMessage': 'It fell from the bag!',
    // After the case is closed (and P.'s last drawing is looked at, its
    // bag and its garden: `TornHourScene.lead`): the post-case scene, then
    // the case report.
    'transition': [
      'The paper fell from the bag.',
      'It is a paper for changing a time, like the opera slip.',
      'So the bag carried a paper for changing a time.',
      'But who carried it? P. never drew a face.',
      "P.'s last drawing showed the same bag in the Luxembourg Gardens.",
      'On the grass in the drawing stands a little clock. Tiny roofs are all around it.',
      'Why did the bag go to a little clock in a garden?',
      'The mystery continues in the Luxembourg Gardens!',
    ],
    'skills': ['problemSolving', 'reading'],
    'mapX': 0.55,
    'mapY': 0.12,
  },
  'glossary': {
    'sketch': '스케치, 밑그림',
    'corner': '모퉁이',
    'metro': '지하철',
    'pillar': '기둥',
    'pillars': '기둥들',
    'gate': '대문',
    'iron': '철로 된',
    'loose': '헐거운, 빠질 듯한',
    'bundle': '묶음, 꾸러미',
    'string': '끈',
    'tied': '묶인',
    'tag': '꼬리표',
    'untie': '풀다',
    'morning': '아침',
    'dark': '어두운',
    'light': '밝은',
    'sun': '해',
    'lamp': '가로등',
    'lamps': '가로등들',
    'drawing': '그림',
    'drawings': '그림들',
    'order': '순서',
    'first': '첫째',
    'next': '다음',
    'last': '마지막',
    'darker': '더 어두운',
    'flat': '납작한',
    'bag': '가방',
    'flap': '(가방의) 덮개',
    'stick': '삐져나오다 (stick out)',
    'full': '꽉 찬',
    'buckles': '버클, 잠금쇠',
    'badge': '배지',
    'shield': '방패',
    'edge': '가장자리',
    'hat': '모자',
    'face': '얼굴',
    'fell': '떨어졌다',
    'dropped': '떨어뜨렸다',
    'folded': '접힌',
    'unfold': '펼치다',
    'torn': '찢긴',
    'tear': '찢어진 곳',
    'seal': '도장, 인장',
    'purple': '보라색의',
    'ring': '고리, 둥근 테',
    'leaves': '잎들',
    'hands': '(시계) 바늘',
    'border': '테두리',
    'band': '띠',
    'arrow': '화살표',
    'same': '같은',
    'missing': '없는, 빠진',
    'hour': '시 (시각의 \'시\')',
    'form': '서식, 양식',
    'dust': '먼지',
    'lay': '놓다',
    'turn': '돌리다',
    'garden': '정원',
    'palace': '궁전',
    'pond': '연못',
    'fountain': '분수',
    'flowerbeds': '꽃밭',
    'basket': '바구니',
    'roofs': '지붕들',
    'tiny': '아주 작은',
    'painter': '화가',
    'church': '교회',
    'steps': '계단',
  },
};
