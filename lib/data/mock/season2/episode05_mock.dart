/// Season 2, Case 05 — The Silent Workshop (No. 7, Passage des Horlogers,
/// Paris). Theme: a copy is never the same; trust what the hands made, not
/// what the clocks say.
///
/// Case 04 ended at the gate of the watchmakers' passage: the label's last
/// piece said "Do not trust the clocks. Follow the hands that made them."
/// Behind the gate, a door says No. 7.
///
/// Every step is played on the case's own pictures, the words on its papers
/// and the hands of its clocks drawn by the app (`season2_case05_scenes.dart`
/// measures where):
/// 1. Four things on the workbench stamped with two clock hands. Under the
///    tracing sheet, three are copies, each different in one way (the long
///    hand's tip, where the short hand sits, the short hand missing); the
///    small drawer has the maker's own mark. In it, a repair card.
/// 2. Four clocks watched for one minute: I goes on 1, II on 5, III goes
///    back 1, IV stays still. Their backs: good gears, a new spring, one
///    small brass wheel added, a broken pendulum hook. The card's clock is
///    the one that does both things it says: Clock III.
/// 3. The blotting paper read in a hand mirror: three notes, one signed
///    with the maker's own mark. It says the letter is in the clock that
///    turns back. Inside Clock III: no letter, only a torn envelope corner
///    and a receipt, LETTER No. 4417.
/// 4. The post's slips under the door: three are letter No. 4417's
///    (collected, sorted, held at the Louvre post room); one is another
///    letter from 3 May, one is a customer's letter, No. 4471.
///
/// The maker is never named: the two clock hands are a mark, and whose
/// hands they are stays untold. So is why the letter was held, who it was
/// for and what it says. The Clockmaker's gear mark (Case 01) is never
/// compared with the hands: whether they are one person is left open.
const Map<String, dynamic> season2Episode05Json = {
  'id': 's2_ep05',
  'seasonId': 's2_paris',
  'number': 5,
  'title': 'The Silent Workshop',
  'place': 'PASSAGE DES HORLOGERS · No. 7',
  'synopsis': [
    'The torn label led you to No. 7, Passage des Horlogers.',
    'Inside, the clocks move, but nobody is there.',
    'Someone worked here. Not long ago.',
  ],
  'objectives': [
    "Find the maker's own mark.",
    'Find the clock the maker changed.',
    'Read the backwards notes on the desk.',
  ],
  'introScene': 'passageGate',
  'intro': [
    'The last piece of the label said two things.',
    'Do not trust the clocks. Follow the hands that made them.',
    'The iron gate is not locked. Behind it, a door says No. 7.',
    'Inside, dozens of clocks hang on the walls.',
    'Their hands are moving, but the room is strangely silent.',
    'Someone worked here. Not long ago.',
  ],
  'caseSummary':
      "You found the maker's own mark, caught the clock that turns back, read the blotted notes in a mirror and followed a letter through the post. It never arrived.",
  'keyWords': ['copy', 'backwards', 'wrong way', 'collected', 'sorted', 'held'],
  'hook': 'Who held the letter at the Louvre post room?',
  'missions': [
    {
      'id': 's2_ep05_m1',
      'number': 1,
      'title': "The Maker's Mark",
      'location': 'THE WORKBENCH',
      'scene': 'workbenchMarks',
      'story': [
        'Inside No. 7, tools lie on a long workbench.',
        // Case 04's Box 23: its crate came here (ledger: for No. 7; label:
        // CLOCK PARTS, the watchmakers).
        'Behind it stands an empty crate, with brown paper and string, just like in Box 23.',
        'The clock parts from the tower came here.',
        'Four things on it are stamped with two clock hands.',
        'They look the same. Are they?',
      ],
      'letterIntro': 'A note on the workbench says:',
      'letter': 'My mark is on everything I make.\nA copy is never the same.',
      // The stamp that matches the maker's own mark under the tracing sheet.
      'type': 'multipleChoice',
      'question': "Which one has the maker's own mark?",
      'options': [
        {
          'id': 'a',
          'label': 'A · The toolbox',
          'feedback': 'Look at the tip of the long hand. Is it the same shape?',
        },
        {
          'id': 'b',
          'label': 'B · The tin of parts',
          'feedback': 'Lay the sheet over it. Does the short hand sit in the same place?',
        },
        {
          'id': 'c',
          'label': 'C · The clock case',
          'feedback': "Count the hands. The maker's mark has two.",
        },
        {'id': 'd', 'label': 'D · The small drawer'},
      ],
      'answer': 'd',
      'hints': [
        'Lay the tracing sheet over each stamp. Look at the lines, not the colour.',
        'Check three things: how many hands, where the short hand sits, and the shape of each tip.',
      ],
      'clue': {
        'id': 's2_ep05_c1',
        'title': 'The Small Drawer',
        'value': 'REPAIR CARD',
        'symbol': 'letter',
        'note': "In the small drawer: a repair card, signed with the maker's own mark.",
      },
      'evidence': {
        'id': 's2_ep05_e1',
        'name': 'The Repair Card',
        'icon': 'ticket',
        'description': 'Found in the small drawer of the workbench.',
        'inscription':
            'I changed one clock. I added one small wheel. Now its hands turn the wrong way. Signed with two clock hands.',
      },
      'successMessage': "You found the maker's own mark!",
      'transition': [
        'The marks were not all the same.',
        "Only the small drawer has the maker's own mark.",
        'Inside it, a repair card says:',
        'I changed one clock. I added one small wheel.',
        'Now its hands turn the wrong way.',
        'On the wall, four clocks hang in a row.',
      ],
      'nextMissionId': 's2_ep05_m2',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.5,
      'mapY': 0.2,
    },
    {
      'id': 's2_ep05_m2',
      'number': 2,
      'title': 'The Clocks That Lie',
      'location': 'THE WALL OF CLOCKS',
      'scene': 'wallOfClocks',
      'story': [
        'Four clocks hang in a row on the wall.',
        'Their hands move, but they make no sound.',
        'Each one shows a different time.',
      ],
      'letterIntro': 'The repair card says:',
      'letter': 'I changed one clock.\nI added one small wheel.\nNow its hands turn the wrong way.',
      // The clock that both turns back and has the added wheel.
      'type': 'multipleChoice',
      'question': 'Which clock did the maker change?',
      'options': [
        {
          'id': 'i',
          'label': 'Clock I',
          'feedback': 'Clock I went from 3:10 to 3:11. That is the right way. And nothing was added at its back.',
        },
        {
          'id': 'ii',
          'label': 'Clock II',
          'feedback': 'Clock II runs fast, but its hands still turn the right way. Read the card again.',
        },
        {'id': 'iii', 'label': 'Clock III'},
        {
          'id': 'iv',
          'label': 'Clock IV',
          'feedback': 'Clock IV does not move at all. Its hands do not turn the wrong way.',
        },
      ],
      'answer': 'iii',
      'hints': [
        'Watch the clocks for one minute. Read each time before and after.',
        'The card says two things: one small wheel was added, and the hands turn the wrong way. Find the clock that does both.',
      ],
      'clue': {
        'id': 's2_ep05_c2',
        'title': 'The Wrong Way',
        'value': 'CLOCK III',
        'symbol': 'watch',
        'note': 'Clock III turns back. Behind it, one small brass wheel that does not belong.',
      },
      'evidence': {
        'id': 's2_ep05_e2',
        'name': 'The Backward Clock',
        'icon': 'watch',
        'description': 'The third clock on the workshop wall.',
        'inscription':
            'Clock III turns back: one minute later, it showed 10:39, not 10:41. Behind it, one small brass wheel that does not belong.',
      },
      'successMessage': 'You found the clock that turns back!',
      'transition': [
        'Clock III went from 10:40 to 10:39.',
        'Its hands turn the wrong way.',
        'Behind it, one small brass wheel does not belong.',
        'By the window, a writing desk is covered in ink.',
      ],
      'nextMissionId': 's2_ep05_m3',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.56,
      'mapY': 0.16,
    },
    {
      'id': 's2_ep05_m3',
      'number': 3,
      'title': 'The Blotted Page',
      'location': 'THE WRITING DESK',
      'scene': 'writingDesk',
      'story': [
        'On the desk lies a big sheet of blotting paper.',
        'Ink has dried on it, but the words are backwards.',
        'A small hand mirror lies beside it.',
      ],
      'letterIntro': 'Your notebook says:',
      'letter':
          'Read the backwards notes in the mirror.\n'
          "Trust only the maker's own mark.\n"
          'What does it say? Where should you look?',
      // The place the note with the maker's own mark names.
      'type': 'multipleChoice',
      'question': "Which place does the maker's own note name?",
      'options': [
        {
          'id': 'corner',
          'label': 'The post box at the corner',
          'feedback': 'That note has no mark at all. A customer wrote it.',
        },
        {
          'id': 'springs',
          'label': 'The tin of springs',
          'feedback': 'Look at the mark on that note. How many hands?',
        },
        {'id': 'clock3', 'label': 'Clock III'},
        {
          'id': 'drawer',
          'label': 'The desk drawer',
          'feedback': 'No note says the drawer. Read the brown note again.',
        },
      ],
      'answer': 'clock3',
      'hints': [
        'Hold the mirror over each note. Then look at the mark under it.',
        "The note with the maker's own mark says: the clock that turns back. Which clock was that?",
      ],
      'clue': {
        'id': 's2_ep05_c3',
        'title': 'Collected',
        'value': 'No. 4417',
        'symbol': 'letter',
        'note': 'Inside Clock III: no letter. A receipt: 16 MAY — ONE LETTER COLLECTED FROM No. 7. LETTER No. 4417.',
      },
      'evidence': {
        'id': 's2_ep05_e3',
        'name': 'The Blotted Note',
        'icon': 'letter',
        'description': 'Read in the hand mirror. What it named was inside Clock III.',
        'inscription':
            'The letter is ready. I hid it in the clock that turns back. On 16 May, it goes to the post. '
            'Inside Clock III: no letter. A receipt: ONE LETTER COLLECTED FROM No. 7. LETTER No. 4417.',
      },
      'successMessage': 'You found where the letter was!',
      'transition': [
        'Inside Clock III, there is no letter.',
        'Only a torn envelope corner and a small receipt.',
        '16 MAY — ONE LETTER COLLECTED FROM No. 7.',
        // What is known, then what is asked: the maker's own note says the
        // letter was hidden here; who took it out, nothing tells.
        "The maker's note said the letter was hidden here.",
        'Now it is gone. Did someone take it out?',
        'Under the door, post slips have piled up.',
      ],
      'nextMissionId': 's2_ep05_final',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.62,
      'mapY': 0.22,
    },
  ],
  'finalMission': {
    'id': 's2_ep05_final',
    'number': 4,
    'title': "The Letter's Trail",
    'location': 'THE WORKSHOP DOOR',
    'scene': 'workshopInterior',
    'story': [
      'Under the door, post slips have piled up.',
      'The post leaves one each time a letter moves.',
      'Nobody was here to read them.',
      // "Collected from No. 7" (the receipt) and "the passage box" (a
      // slip) are one place.
      'The post box of the passage stands right outside No. 7.',
    ],
    'letterIntro': 'The receipt from Clock III says:',
    'letter':
        '16 MAY — ONE LETTER COLLECTED FROM No. 7.\n'
        'LETTER No. 4417.\n\n'
        'Find its slips.\n'
        'Put them in order.',
    // Each of the letter's slips in its place on the trail (`slot:slip`);
    // the slips of other letters fit nowhere.
    'type': 'matchPairs',
    'question': 'Where did the letter go? Put its slips in order.',
    'options': [
      {'id': 's1', 'label': 'COLLECTED · PASSAGE BOX'},
      {'id': 's2', 'label': 'SORTED · CENTRAL OFFICE'},
      {'id': 's3', 'label': 'HELD · LOUVRE POST ROOM'},
      {'id': 's4', 'label': 'DELIVERED · RUE DU BAC'},
      {'id': 's5', 'label': 'COLLECTED · CORNER BOX'},
    ],
    'answer': 'first:s1,second:s2,third:s3',
    'feedback': {
      'first:s4': 'That slip is from 3 May, for another letter.',
      'second:s4': 'That slip is from 3 May, for another letter.',
      'third:s4': 'That slip is from 3 May, for another letter.',
      'first:s5': 'Look at the letter number. Is it 4417?',
      'second:s5': 'Look at the letter number. Is it 4417?',
      'third:s5': 'Look at the letter number. Is it 4417?',
      'first:s2': 'Put the times in order: which came first?',
      'first:s3': 'Put the times in order: which came first?',
      'second:s1': 'Read the time on each slip again. Which one came in the middle?',
      'second:s3': 'Read the time on each slip again. Which one came in the middle?',
      'third:s1': 'Read the time on each slip again. Which one came last?',
      'third:s2': 'Read the time on each slip again. Which one came last?',
    },
    'hints': [
      'Look at the letter number on each slip. Is it the same as on the receipt?',
      'Three slips are for letter No. 4417. Put them in time order.',
    ],
    'evidence': {
      'id': 's2_ep05_e4',
      'name': "The Letter's Trail",
      'icon': 'map',
      'description': 'Three post slips from under the workshop door.',
      // The times its slips give (Case 06 tells its tags apart by the last).
      'inscription':
          'Letter No. 4417, 16 May: collected at 9:00 AM, sorted at 11:00 AM, then HELD at the Louvre post room at 4:00 PM. Never delivered.',
    },
    'successMessage': 'You followed the letter!',
    // After the case is closed: the post-case scene, then the case report.
    'transition': [
      'Letter No. 4417 left No. 7 on 16 May.',
      'It was collected. It was sorted.',
      'Then it stopped: HELD at the Louvre post room.',
      'It was never delivered.',
      'Who stopped it? And why?',
    ],
    'skills': ['problemSolving', 'reading'],
    'mapX': 0.55,
    'mapY': 0.12,
  },
  'glossary': {
    'label': '배송표, 꼬리표',
    'trust': '믿다',
    'hands': '(시계) 바늘',
    'gate': '대문, 철문',
    'silent': '조용한, 소리 없는',
    'workbench': '작업대',
    'tools': '공구들',
    'stamped': '도장이 찍힌',
    'mark': '표식',
    'copy': '복사본, 따라 만든 것',
    'tracing': '본뜨기(용)',
    'sheet': '종이 한 장',
    'stamp': '도장, 찍힌 자국',
    'tip': '끝, 끝부분',
    'toolbox': '공구함',
    'tin': '깡통',
    'parts': '부품들',
    'drawer': '서랍',
    'repair': '수리',
    'card': '카드',
    'changed': '바꿨다',
    'added': '더했다, 달았다',
    'wheel': '바퀴, 톱니바퀴',
    'wrong': '틀린, 잘못된',
    'wall': '벽',
    'row': '줄, 열',
    'sound': '소리',
    'fast': '빠르게',
    'back': '뒤로; 뒷면',
    'brass': '황동, 놋쇠',
    'belong': '제자리이다, ~에 속하다',
    'blotting': '(잉크를) 빨아들이는',
    'ink': '잉크',
    'dried': '말랐다',
    'backwards': '거꾸로',
    'mirror': '거울',
    'note': '쪽지',
    'notes': '쪽지들',
    'letter': '편지',
    'hid': '숨겼다',
    'ready': '준비된',
    'customer': '손님',
    'springs': '태엽들, 용수철들',
    'envelope': '봉투',
    'corner': '모서리; 길모퉁이',
    'receipt': '영수증',
    'collected': '가져갔다, 수거했다',
    'post': '우편',
    'slips': '쪽지들, 전표들',
    'piled': '쌓였다',
    'sorted': '분류됐다',
    'held': '보관됐다, 멈춰 있었다',
    'delivered': '배달됐다',
    'trail': '지나간 길, 흔적',
    'order': '순서',
    'gears': '톱니바퀴들',
    'spring': '태엽, 용수철',
    'pendulum': '시계추',
    'hook': '고리',
    'broken': '부러진, 고장 난',
    'turns': '돌아간다',
    'central': '중앙의',
    'office': '사무소',
    'crate': '나무 상자',
    'empty': '빈',
  },
};
