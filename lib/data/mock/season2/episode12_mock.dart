/// Season 2, Case 12 — The Clockmaker's Truth (Arts et Métiers). Theme: who
/// is the Clockmaker, and why did he leave the clues? The season's last
/// case.
///
/// Case 11 ended on Victor's words: E.M.'s old machine is at Arts et
/// Métiers (`docs/SEASON2_CASE12_SPEC.md` v1.0; story bible v2.0, §6 Case
/// 12), played very easy (the user's rules of 2026-10-27), with the steps,
/// talks and ending of `season2_case12_scenes.dart`:
/// 1. A wheel in the machine is the same as Clock III's small wheel; its
///    tag says Made by Émile Moreau: E.M. is Émile.
/// 2. The Clockmaker's watch (Season 1's `ep12_e4`) holds the same wheel;
///    Émile's little stamp makes the Clockmaker's gear mark (Case 01):
///    Émile is the Clockmaker. He says why: he wanted people to find the
///    missing page. But he scared people, and that was wrong.
/// 3. The old machine, left wrong since the test day, is set right.
/// 4. The final case board: six questions, two answers each, the clue for
///    each on screen. Then the ending, one line at a time.
///
/// The exact moment Big Ben had to stop, how the papers got into the box
/// under it, who kept Letter 4417, P., and any punishment stay untold.
const Map<String, dynamic> season2Episode12Json = {
  'id': 's2_ep12',
  'seasonId': 's2_paris',
  'number': 12,
  'title': "The Clockmaker's Truth",
  'place': 'ARTS ET MÉTIERS',
  'synopsis': [
    "E.M.'s old machine is here.",
    'Who left the clues?',
  ],
  'objectives': [
    'Find his name.',
    'Find the Clockmaker.',
    'Fix the old machine.',
  ],
  'introScene': 'artsMetiersHall',
  // The museum hall under line 1, the room of old machines from line 2
  // (`IntroPicture`).
  'intro': [
    'Arts et Métiers. A museum of old machines.',
    'In a quiet room, a big machine ticks.',
    'Its three little clocks are one hour behind!',
    'Someone is standing by the machine.',
  ],
  'caseSummary':
      "You found Émile's name on an old wheel. The same wheel was in the Clockmaker's watch, and Émile's tool made the Clockmaker's mark. Émile was the Clockmaker. He left clues so the truth would be found, but he scared people. You fixed the machine and closed the case.",
  'keyWords': ['wheel', 'the same', 'watch', 'mark', 'Clockmaker', 'wrong', 'fix', 'truth'],
  'hook': 'The hour was never gone.',
  'missions': [
    {
      'id': 's2_ep12_m1',
      'number': 1,
      'title': 'Find the Wheel',
      'location': 'THE MACHINE ROOM',
      'scene': 'oldMachineRoom',
      'story': [
        'The machine has a little door.',
        'Wheels are inside.',
      ],
      'letterIntro': 'On a little tag:',
      'letter': 'Made by Émile Moreau',
      // Played in steps (`season2Case12Steps`): Clock III's wheel beside two
      // wheels of the machine, then the tag on the right one.
      'type': 'examine',
      'question': 'Find the same wheel.',
      'answer': 'emile',
      'hints': [
        'Count the spokes.',
        'Look at the size too.',
      ],
      'clue': {
        'id': 's2_ep12_c1',
        'title': 'E.M.',
        'value': 'Émile Moreau',
        'symbol': 'gear',
        'note': "He made Clock III's small wheel.",
      },
      'evidence': {
        'id': 's2_ep12_e1',
        'name': 'The Name Tag',
        'icon': 'seal',
        'description': 'A tag on a wheel inside the old machine.',
        'inscription': "Made by Émile Moreau. Two clock hands, the No. 7 mark. Clock III's small wheel is the same.",
      },
      'successMessage': 'E.M. is Émile Moreau!',
      'transition': [
        'The tag says: Made by Émile Moreau.',
        'E.M. is Émile Moreau!',
        'He made the same wheel for Clock III.',
        'But who is the Clockmaker?',
      ],
      'nextMissionId': 's2_ep12_m2',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.44,
      'mapY': 0.6,
    },
    {
      'id': 's2_ep12_m2',
      'number': 2,
      'title': 'Who Is the Clockmaker?',
      'location': 'THE WORKBENCH',
      'scene': 'oldMachineRoom',
      'story': [
        "You still have the Clockmaker's watch.",
        'You found it in London.',
      ],
      'letterIntro': 'On the back of the watch:',
      'letter': 'PARIS',
      // Played in steps (`season2Case12Steps`): the watch opened, its wheel,
      // the stamp pressed, the marks, then who it is.
      'type': 'examine',
      'question': 'Who is the Clockmaker?',
      'answer': 'clockmaker',
      'hints': [
        'Open the watch. Then try the stamp.',
        'Are the marks the same?',
      ],
      'clue': {
        'id': 's2_ep12_c2',
        'title': 'Three Clues',
        'value': 'Wheel · Watch · Mark',
        'symbol': 'gear',
        'note': 'The wheel, the watch and the mark lead to one man.',
      },
      'evidence': {
        'id': 's2_ep12_e2',
        'name': "The Clockmaker's Mark Tool",
        'icon': 'gear',
        'description': "Émile's tool, and the watch from London.",
        'inscription':
            "Inside the Clockmaker's watch: the same small wheel Émile made. Émile's tool makes the Clockmaker's gear mark. Émile is the Clockmaker.",
      },
      'successMessage': 'Émile is the Clockmaker!',
      'transition': [
        'Émile is the Clockmaker.',
        'He wanted people to find page 3.',
        'But he scared people. That was wrong.',
        'And the old machine is still wrong.',
      ],
      'nextMissionId': 's2_ep12_m3',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.5,
      'mapY': 0.68,
    },
    {
      'id': 's2_ep12_m3',
      'number': 3,
      'title': 'Fix the Machine',
      'location': 'THE MACHINE ROOM',
      'scene': 'oldMachineRoom',
      'story': [
        'The old machine is still wrong.',
        'Its clocks are one hour behind.',
      ],
      'letterIntro': 'A card on the machine:',
      'letter': 'HOW TO FIX THE MACHINE\n1. Stop. 2. Turn. 3. Fix. 4. Start.',
      // Played in steps (`season2Case12Steps`): STOP, the wheel, the pin,
      // START. Every part moves by itself once tapped.
      'type': 'examine',
      'question': 'Fix the old machine.',
      'answer': 'fixed',
      'hints': [
        'Do the steps in order.',
        'Stop, turn, fix, start.',
      ],
      'clue': {
        'id': 's2_ep12_c3',
        'title': 'All Agree',
        'value': '11:20',
        'symbol': 'clock',
        'note': 'Only this machine was fixed.',
      },
      'evidence': {
        'id': 's2_ep12_e3',
        'name': 'The Fixed Machine',
        'icon': 'clock',
        'description': 'The old test machine, fixed at last.',
        'inscription': 'It stayed wrong after the test day. Nobody fixed it. You turned the wheel one hour. Now all three little clocks agree with the wall clock.',
      },
      'successMessage': 'You fixed the machine!',
      'transition': [
        'The old machine is right at last.',
        'All its clocks agree.',
        "Now, let's put the case together.",
      ],
      'nextMissionId': 's2_ep12_final',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.56,
      'mapY': 0.6,
    },
  ],
  'finalMission': {
    'id': 's2_ep12_final',
    'number': 4,
    'title': 'The Final Case Board',
    'location': 'THE MACHINE ROOM · THE CASE BOARD',
    'scene': 'oldMachineRoom',
    'story': [
      'Six questions. One at a time.',
      'Your clues will help.',
    ],
    'letterIntro': 'The case board:',
    'letter': 'Did Paris lose an hour?',
    // Played in steps (`season2Case12Steps`): six questions, two answers
    // each, the clue for each on screen; then the ending
    // (`season2Case12Endings`).
    'type': 'examine',
    'question': 'Did Paris lose an hour?',
    'answer': 'truth',
    'hints': [
      'Look at the clue for each question.',
      'The clocks were wrong. The hour was there.',
    ],
    'evidence': {
      'id': 's2_ep12_e4',
      'name': 'The Case File',
      'icon': 'letter',
      'description': 'The whole case, in four lines.',
      'inscription':
          'Paris did not lose an hour. The clocks were wrong. Victor hid page 3. Émile, the Clockmaker, left clues so we would find it. But scaring people was wrong.',
    },
    'successMessage': 'You solved the case!',
    // After the ending: its last two lines, over the morning.
    'transition': [
      'The hour was never gone.',
      'The truth was waiting to be found.',
    ],
    'skills': ['reading', 'problemSolving'],
    'mapX': 0.5,
    'mapY': 0.55,
  },
  'glossary': {
    'museum': '박물관',
    'machine': '기계',
    'machines': '기계들',
    'wheel': '바퀴',
    'wheels': '바퀴들',
    'spokes': '바큇살',
    'size': '크기',
    'same': '같은',
    'tag': '이름표',
    'watch': '회중시계',
    'stamp': '도장',
    'mark': '표식',
    'marks': '표식들',
    'teeth': '톱니',
    'clockmaker': '시계 장인(그의 별명)',
    'scared': '겁을 주었다',
    'wrong': '잘못된, 틀린',
    'fix': '고치다',
    'fixed': '고쳤다',
    'stop': '멈추다',
    'turn': '돌리다',
    'start': '켜다',
    'agree': '일치하다',
    'truth': '진실',
    'behind': '(시간이) 늦은',
    'quiet': '조용한',
    'board': '판, 게시판',
    'card': '카드',
    'hour': '한 시간',
  },
};
