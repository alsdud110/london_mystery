/// Season 2, Case 11 — The Unwritten Hour (Saint-Sulpice, the Archive
/// Annex). Theme: who hid the truth?
///
/// Case 10 ended on the record list: page 3 of the Trial Log was SENT TO
/// SAINT-SULPICE · ARCHIVE ANNEX (`docs/SEASON2_CASE11_SPEC.md` v1.0; story
/// bible v2.0, §6 Case 11), played very easy (the user's rules of
/// 2026-10-27): one small thing at a time, two answers at most, the clue on
/// the same screen, a free hint at any time, and a wrong answer never
/// counted.
///
/// Every step is played on the case's own pictures, with the steps and the
/// talks of `season2_case11_scenes.dart`:
/// 1. The big book: a page is torn out; rubbing the next page brings out
///    "Page 3 is in Box 9. Lock it. No one may read it." and a name. Box 9
///    holds page 3: the clocks were wrong; E.M. said "Stop!", V.D. said
///    "Keep going."
/// 2. Victor's paper says all the clocks were fine: page 3 says no. Its
///    stamp is the opera slip's (Case 07): his office changed papers too.
/// 3. The name in the big book is Victor's, as he signed the visitor book.
/// 4. Victor, shown the three clues, says he hid the page.
///
/// E.M.'s name and face, the Clockmaker, London, the trial's date, the
/// opera show's date and why its paper was changed, and who carried the
/// office bag, stay untold.
const Map<String, dynamic> season2Episode11Json = {
  'id': 's2_ep11',
  'seasonId': 's2_paris',
  'number': 11,
  'title': 'The Unwritten Hour',
  'place': 'SAINT-SULPICE',
  'synopsis': [
    'Page 3 was sent to Saint-Sulpice.',
    'Is it really there?',
    'Who hid it?',
  ],
  'objectives': [
    'Find page 3.',
    'Find the wrong paper.',
    'Find who signed it.',
  ],
  'introScene': 'annexStreet',
  // The street under lines 1–2, the reading room from line 3
  // (`IntroPicture`).
  'intro': [
    'Saint-Sulpice. A quiet street.',
    'A small door says: Archive Annex.',
    'Inside, boxes go up to the ceiling.',
    'A man is reading old papers.',
    "Let's find page 3.",
  ],
  'caseSummary':
      "You found page 3 in Box 9. It said the clocks were wrong. Victor's paper was not true. His name was under the order to hide the page. Victor hid the truth.",
  'keyWords': ['missing', 'hidden', 'true', 'not true', 'stamp', 'signed', 'afraid'],
  'hook': 'Who left the clues for me?',
  'missions': [
    {
      'id': 's2_ep11_m1',
      'number': 1,
      'title': 'The Missing Page',
      'location': 'ARCHIVE ANNEX · THE BIG BOOK',
      'scene': 'annexReadingRoom',
      'story': [
        'Page 3 was sent here.',
        'Every paper here is in the big book.',
      ],
      'letterIntro': 'Pressed into the big book:',
      'letter': 'Page 3 is in Box 9.\nLock it. No one may read it.',
      // Played in steps (`season2Case11Steps`): the book, the rubbing, Box 9,
      // the folder, page 3. Nothing to type; never a wrong answer.
      'type': 'examine',
      'question': 'Find page 3.',
      'answer': 'page3',
      'hints': [
        'Rub the page with your finger.',
        'Look at the numbers on the boxes.',
      ],
      'clue': {
        'id': 's2_ep11_c1',
        'title': 'The Rubbing',
        'value': 'Page 3 is in Box 9',
        'symbol': 'letter',
        'note': '"Lock it. No one may read it." And a name.',
      },
      'evidence': {
        'id': 's2_ep11_e1',
        'name': 'Page 3',
        'icon': 'letter',
        'description': 'The missing page, found in Box 9.',
        'inscription': '3:00: The clocks are wrong! E.M.: "Stop the test!" V.D.: "No. Keep going." 4:00: E.M. stops the machine.',
      },
      'successMessage': 'You found page 3!',
      'transition': [
        'Page 3 was hidden in Box 9.',
        'The clocks were wrong for one hour.',
        'E.M. said, "Stop!"',
        'Victor said, "Keep going."',
        "Now, let's read Victor's paper.",
      ],
      'nextMissionId': 's2_ep11_m2',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.44,
      'mapY': 0.62,
    },
    {
      'id': 's2_ep11_m2',
      'number': 2,
      'title': 'Two Papers',
      'location': 'ARCHIVE ANNEX · THE LONG TABLE',
      'scene': 'annexReadingRoom',
      'story': [
        'Victor gives you his paper.',
        'Is it true?',
      ],
      'letterIntro': "Victor's paper says:",
      'letter': 'CLOCK TEST · V.D.\nAll the clocks were fine.',
      // Played in steps (`season2Case11Steps`): page 3 beside his paper, then
      // the two stamps. A wrong answer is said why, never counted.
      'type': 'examine',
      'question': 'Were the clocks right?',
      'answer': 'notTrue',
      'hints': [
        'Read page 3.',
        'Look at the stamps. Are they the same?',
      ],
      'clue': {
        'id': 's2_ep11_c2',
        'title': 'The Same Stamp',
        'value': "Opera slip = Victor's office",
        'symbol': 'seal',
        'note': 'His office changed papers.',
      },
      'evidence': {
        'id': 's2_ep11_e2',
        'name': "Victor's Paper",
        'icon': 'letter',
        'description': "Victor's paper about the clock test.",
        'inscription': 'It says all the clocks were fine. Page 3 says no. Its stamp is the same as the stamp on the opera slip.',
      },
      'successMessage': "Victor's paper is not true!",
      'transition': [
        "Victor's paper was not true.",
        'His office changed papers too.',
        'But who hid page 3?',
        'There was a name in the big book.',
      ],
      'nextMissionId': 's2_ep11_m3',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.5,
      'mapY': 0.68,
    },
    {
      'id': 's2_ep11_m3',
      'number': 3,
      'title': 'Who Signed It?',
      'location': 'ARCHIVE ANNEX · THE VISITOR BOOK',
      'scene': 'annexReadingRoom',
      'story': [
        'The big book had a name in it.',
        'Victor signed the visitor book today.',
      ],
      'letterIntro': 'In the visitor book:',
      'letter': 'Two names. One is the same.',
      // Played in steps (`season2Case11Steps`): the visitor book, then the
      // name from the big book matched to one of its names.
      'type': 'examine',
      'question': 'Match the names.',
      'answer': 'victor',
      'hints': [
        'Look at the V, the line and the dot.',
        'One name has a long line under it.',
      ],
      'clue': {
        'id': 's2_ep11_c3',
        'title': 'The Same Name',
        'value': 'Big book = visitor book',
        'symbol': 'seal',
        'note': 'Victor signed the order to hide page 3.',
      },
      'evidence': {
        'id': 's2_ep11_e3',
        'name': "Victor's Name",
        'icon': 'seal',
        'description': 'The name pressed into the big book.',
        'inscription': '"Page 3 is in Box 9. Lock it. No one may read it." Under it: the same curly V, long line and dot as Victor\'s name in the visitor book.',
      },
      'successMessage': "It's Victor's name!",
      'transition': [
        'Victor wrote, "Lock it. No one may read it."',
        'Then page 3 was hidden.',
        "It's time to show him.",
      ],
      'nextMissionId': 's2_ep11_final',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.56,
      'mapY': 0.6,
    },
  ],
  'finalMission': {
    'id': 's2_ep11_final',
    'number': 4,
    'title': "Victor's Truth",
    'location': 'ARCHIVE ANNEX · THE LONG TABLE',
    'scene': 'annexReadingRoom',
    'story': [
      'Victor is waiting at the long table.',
      'Show him the truth.',
    ],
    'letterIntro': 'Your clues:',
    'letter': "PAGE 3 · VICTOR'S PAPER · VICTOR'S NAME",
    // Played as a talk with Victor (`season2Case11Talks`): a clue shown for
    // each of his three questions, from two cards. Nothing is counted wrong.
    'type': 'examine',
    'question': 'Who hid the truth?',
    'answer': 'victor',
    'hints': [
      'Show him one clue for each question.',
      'Page 3, then his paper, then his name.',
    ],
    'evidence': {
      'id': 's2_ep11_e4',
      'name': "Victor's Truth",
      'icon': 'seal',
      'description': 'What Victor said after you showed him the clues.',
      'inscription':
          '"Yes. I hid the page. I was afraid. I didn\'t want people to know." His office bag took page 3 away. He wanted the tests to stop. He did not change any clocks this year.',
    },
    'successMessage': 'Victor hid the truth!',
    'transition': [
      'Victor hid the truth.',
      'But who left the clues for me?',
      'Victor said E.M. may know.',
      "Let's find E.M. at Arts et Métiers!",
    ],
    'skills': ['reading', 'problemSolving'],
    'mapX': 0.5,
    'mapY': 0.55,
  },
  'glossary': {
    'archive': '기록 보관소',
    'annex': '별관',
    'page': '쪽',
    'missing': '사라진',
    'torn': '찢긴',
    'rub': '문지르다',
    'finger': '손가락',
    'box': '상자',
    'lock': '잠그다',
    'locked': '잠긴',
    'stamp': '도장',
    'stamps': '도장들',
    'test': '시험',
    'wrong': '틀린',
    'right': '맞는',
    'machine': '기계',
    'paper': '서류',
    'papers': '서류들',
    'fine': '괜찮은',
    'true': '사실인',
    'office': '사무실',
    'changed': '바꿨다',
    'signed': '서명했다',
    'visitor': '방문자',
    'name': '이름',
    'names': '이름들',
    'match': '맞추다',
    'same': '같은',
    'hide': '숨기다',
    'hidden': '숨겨진',
    'hid': '숨겼다',
    'truth': '진실',
    'afraid': '두려운',
    'clue': '단서',
    'clues': '단서들',
    'pressed': '눌린',
    'waiting': '기다리는',
    'table': '탁자',
  },
};
