/// Season 2, Case 10 — The Hour of Shadows (Arc de Triomphe).
/// Theme: the hour that was there all along.
///
/// Case 09 ended on the star under T1: TRIAL RECORDS · KEPT AT THE STAR
/// (`docs/SEASON2_CASE10_SPEC.md` v1.1; story bible v1.9, §6 Case 10).
///
/// Every step is played on the case's own pictures, with the rules of
/// `season2_case10_scenes.dart`:
/// 1. T1's drum tape: the time jumps twice, and there is no three o'clock.
/// 2. Photo 2's clocks: T1, the trial clock, is one hour behind three clocks
///    that are not trial clocks, and agree with each other.
/// 3. The roof's sundial: its shadow in Photo 1 says 2:00 (as T1 does); in
///    Photo 2 it says 3:30.
/// 4. The sun's times laid under the tape: the hour from three to four is on
///    it, T1 one hour behind through it; page 3 of the Trial Log is missing.
///    Then the record list says where page 3 was sent.
///
/// Why T1 went wrong and who put it right, whether T2 and T3 went wrong too,
/// what page 3 says, who sent it away and why, and any name, stay untold.
const Map<String, dynamic> season2Episode10Json = {
  'id': 's2_ep10',
  'seasonId': 's2_paris',
  'number': 10,
  'title': 'The Hour of Shadows',
  'place': 'ARC DE TRIOMPHE',
  'synopsis': [
    'A star under T1 pointed to the Arc de Triomphe.',
    'The trial records may be kept there.',
    'Was the hour lost — or was the clock wrong?',
  ],
  // Never the answer: what the records show is found in them.
  'objectives': [
    'Read what T1 wrote.',
    'Check the other clocks.',
    'Ask the sun.',
  ],
  'introScene': 'arcStarView',
  // The arch under lines 1–3 (T1's star over it, lines 2–3), turning into
  // the room under the roof at line 4 (`IntroPicture`).
  'intro': [
    'The Arc de Triomphe. Twelve roads meet around it, like a star.',
    "T1's little clock stood on top of an arch, with a star under it.",
    'You climb the stairs to the top.',
    'Under the roof, a small door has a star on it.',
    'Inside: a brass drum, a box of photos, and a thick book.',
    'A brass plate on the wall: TRIAL RECORDS · KEPT AT THE STAR.',
    'In the garden, we tested a model. These records are from the real trial.',
    "Let's read what T1 wrote.",
  ],
  'caseSummary':
      'The hour really passed: the sun and the café, church and post office clocks show it. T1 was one hour behind. Page 3 is missing. The list says it was sent to Saint-Sulpice.',
  'keyWords': ['tape', 'jump', 'fifteen minutes', 'trial clock', 'agree', 'shadow', 'sun', 'behind', 'missing', 'sent'],
  'hook': 'Who sent page 3 away — and why?',
  'missions': [
    {
      'id': 's2_ep10_m1',
      'number': 1,
      'title': 'The Drum Tape',
      'location': 'THE STAR ROOM · ARC DE TRIOMPHE',
      'scene': 'starRoom',
      'story': [
        'The drum holds a paper tape.',
        'T1 printed its time on it every fifteen minutes.',
      ],
      'letterIntro': 'On the tape:',
      'letter': 'T1 · DRUM TAPE · TRIAL DAY',
      // The jumps tapped on the tape (see `season2DrumTapes`): a mark that
      // follows on fifteen minutes is said so, never counted.
      'type': 'matchPairs',
      'question': 'Where does the time jump? Tap the two places.',
      'options': [
        {'id': 'jump', 'label': 'A jump in the time'},
      ],
      'answer': 'jump:t5,jump:t9',
      'hints': [
        'Each one should be fifteen minutes after the last.',
        'Look at what comes after each 2:45.',
      ],
      'clue': {
        'id': 's2_ep10_c1',
        'title': "No Three O'Clock",
        'value': '2:45 → 2:00 · 2:45 → 4:00',
        'symbol': 'clock',
        'note': "T1's tape never shows three o'clock.",
      },
      'evidence': {
        'id': 's2_ep10_e1',
        'name': 'T1 Drum Tape',
        'icon': 'clock',
        'description': 'The paper tape from the drum under T1.',
        'inscription':
            "T1 printed 2:00 to 2:45, then 2:00 to 2:45 again, then 4:00. No three o'clock.",
      },
      'successMessage': 'Two jumps!',
      'transition': [
        'After 2:45, the tape goes back to 2:00. Then it jumps to 4:00.',
        "There is no three o'clock on the tape.",
        'At Gare du Nord we read: The Clockmaker steals an hour.',
        'Was an hour stolen? Or was T1 wrong?',
        "Let's see what other clocks said.",
      ],
      'nextMissionId': 's2_ep10_m2',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.42,
      'mapY': 0.6,
    },
    {
      'id': 's2_ep10_m2',
      'number': 2,
      'title': 'A City of Clocks',
      'location': 'THE STAR ROOM · ROOF PHOTOS',
      'scene': 'starRoom',
      'story': [
        'ROOF PHOTOS · TRIAL DAY. Two old photos.',
        'Photo 2 shows T1 on the roof, and the city behind it.',
      ],
      'letterIntro': 'On the back of Photo 2:',
      'letter': 'T1 · ROOF · PHOTO 2',
      // Every clock found under the glass, then sorted (see
      // `season2CityClocksScenes`): a wrong tray sends it back with its line,
      // never counted.
      'type': 'matchPairs',
      'question': 'Is it a trial clock? Find and sort the clocks.',
      'options': [
        {'id': 't1', 'label': 'T1'},
        {'id': 'cafe', 'label': 'The café clock'},
        {'id': 'church', 'label': 'The church clock'},
        {'id': 'post', 'label': 'The post office clock'},
      ],
      'answer': 't1:trial,cafe:not,church:not,post:not',
      'hints': [
        'Move the glass over the photo. There are four clocks.',
        'Only T1 has the trial star. The other clocks are not trial clocks.',
      ],
      'clue': {
        'id': 's2_ep10_c2',
        'title': 'One Hour Apart',
        'value': 'T1 2:30 · others 3:30',
        'symbol': 'clock',
        'note': 'Three clocks that are not trial clocks all agree.',
      },
      'evidence': {
        'id': 's2_ep10_e2',
        'name': 'Independent Time Log',
        'icon': 'clock',
        'description': 'The clocks in Roof Photo 2, at one moment on the trial day.',
        'inscription':
            'T1, the trial clock, said 2:30. The café, church and post office clocks said 3:30. T1 was one hour behind them.',
      },
      'successMessage': "They don't agree!",
      'transition': [
        'The café, church and post office clocks agree.',
        'T1 is one hour behind them.',
        'What if all three were wrong? Is there a time no one can set?',
        'Look! A sundial stands next to T1 in the photo.',
      ],
      'nextMissionId': 's2_ep10_m3',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.5,
      'mapY': 0.66,
    },
    {
      'id': 's2_ep10_m3',
      'number': 3,
      'title': 'The Hour of Shadows',
      'location': 'THE ROOF · ARC DE TRIOMPHE',
      'scene': 'arcStarView',
      'story': [
        'On the roof, the old sundial is still here.',
        "A sundial tells the time with the sun's shadow.",
      ],
      'letterIntro': 'Around the sundial:',
      'letter': 'I COUNT ONLY THE SUNNY HOURS.',
      // The sun moved round the dial (see `season2ShadowChecks`): the shadow
      // settles on any line; another photo's time is said so, never counted.
      'type': 'matchPairs',
      'question': 'Move the sun. Make the same shadow as in the photo.',
      'options': [
        {'id': 'photo1', 'label': 'Photo 1'},
        {'id': 'photo2', 'label': 'Photo 2'},
      ],
      'answer': 'photo1:t200,photo2:t330',
      'hints': [
        'Move the sun slowly. Watch the shadow turn and grow.',
        'In Photo 2, the shadow points between 3 and 4.',
      ],
      'clue': {
        'id': 's2_ep10_c3',
        'title': "The Sun's Time",
        'value': 'Photo 2 · SUN 3:30',
        'symbol': 'clock',
        'note': 'No one can set the sun.',
      },
      'evidence': {
        'id': 's2_ep10_e3',
        'name': 'The Shadow Check',
        'icon': 'clock',
        'description': 'The roof sundial in two old photos.',
        'inscription': 'Photo 1: T1 2:00, the sun 2:00. Photo 2: T1 2:30, the sun 3:30. No one can set the sun.',
      },
      'successMessage': 'The sun knows!',
      'transition': [
        'Photo 1: T1 and the sun both said 2:00.',
        'Photo 2: T1 said 2:30. But the sun said 3:30!',
        'No one can set the sun.',
        'The letter at the Louvre said: The clocks may lie.',
        'So where did the hour from three to four go?',
      ],
      'nextMissionId': 's2_ep10_final',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.58,
      'mapY': 0.58,
    },
  ],
  'finalMission': {
    'id': 's2_ep10_final',
    'number': 4,
    'title': 'The Hour Was Recorded',
    'location': 'THE STAR ROOM · THE TABLE',
    'scene': 'starRoom',
    'story': [
      'You lay the tape on the table. Photo 1 is at the first 2:00.',
      'Now find Photo 2 on the tape.',
    ],
    'letterIntro': 'Your photos:',
    'letter': 'PHOTO 1 · T1 2:00 · SUN 2:00\nPHOTO 2 · T1 2:30 · SUN 3:30',
    // Photo 2 found on the tape and page 3 found missing first
    // (`season2HourRecords`), then this.
    'type': 'multipleChoice',
    'question': 'Was the hour lost — or was the clock wrong?',
    'options': [
      {
        'id': 'lost',
        'label': 'The hour was lost. Time jumped from 2:45 to 4:00.',
        'feedback': "Look at the sun's line. Did the sun jump?",
      },
      {'id': 'wrong', 'label': 'The hour was there. T1 was one hour behind, and the page about it is missing.'},
      {
        'id': 'all',
        'label': 'Every clock in Paris was one hour behind.',
        'feedback': 'What did the café and church clocks say?',
      },
    ],
    'answer': 'wrong',
    'hints': [
      'Photo 2 was taken later than Photo 1. How much later?',
      'Find the page for three to four. Is it in the book?',
    ],
    'evidence': {
      'id': 's2_ep10_e4',
      'name': 'The Hour Was Recorded',
      'icon': 'letter',
      'description': "T1's tape, laid beside the sun's time.",
      'inscription':
          'The hour from 3:00 to 4:00 really passed. The sun and three clocks that are not trial clocks show it. In that hour, T1 was one hour behind: it printed 2:00 to 2:45. At 4:00 it was right again. Page 3 of the Trial Log, for that hour, is not in the book.',
    },
    'successMessage': 'The hour was never lost!',
    // After the case is closed (and the record list read:
    // `HourRecordScene.lead`): the post-case scene, then the case report.
    'transition': [
      'Paris did not lose an hour. For one hour, T1 was wrong.',
      "Were T2 and T3 wrong too? We can't tell.",
      'At the Eiffel Tower, a time-recording machine hid a plaque: ONE HOUR IS MISSING. THE CLOCK IS STILL RUNNING.',
      'Was it about this hour?',
      'The mystery continues at Saint-Sulpice!',
    ],
    'skills': ['problemSolving', 'reading'],
    'mapX': 0.5,
    'mapY': 0.55,
  },
  'glossary': {
    'tape': '종이 테이프',
    'drum': '원통',
    'printed': '찍었다',
    'fifteen': '15',
    'minutes': '분',
    'after': '~ 뒤에',
    'jump': '건너뛰다',
    'jumps': '건너뛴다',
    'again': '다시',
    'back': '뒤로',
    'stolen': '도둑맞은',
    'steals': '훔친다',
    'photo': '사진',
    'photos': '사진들',
    'roof': '지붕',
    'café': '카페',
    'church': '교회',
    'post office': '우체국',
    'trial': '시험',
    'agree': '일치하다',
    'sundial': '해시계',
    'shadow': '그림자',
    'shadows': '그림자들',
    'sun': '해',
    'set': '맞추다',
    'sunny': '해가 비치는',
    'behind': '(시간이) 늦은',
    'right': '맞는',
    'page': '쪽',
    'book': '책',
    'missing': '없어진',
    'list': '목록',
    'sent': '보냈다',
    'archive': '기록 보관소',
    'annex': '별관',
    'record': '기록',
    'records': '기록들',
    'plaque': '명판',
    'machine': '기계',
    'arch': '아치',
    'roads': '길',
    'stairs': '계단',
    'plate': '명판',
    'brass': '황동',
    'kept': '보관된',
    'star': '별',
    'model': '모형',
    'clock': '시계',
    'clocks': '시계들',
    'wrong': '틀린',
    'hour': '시간(한 시간)',
    'lost': '잃어버린',
  },
};
