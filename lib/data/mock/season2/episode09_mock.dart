/// Season 2, Case 09 — The Clockwork Garden (Luxembourg Gardens).
/// Theme: what a model can show, and what it cannot.
///
/// Case 08 ended on P.'s last drawing: the same bag beside a little clock
/// in the Luxembourg Gardens (`docs/SEASON2_CASE09_SPEC.md` v1.1; story
/// bible v1.8, §6 Case 09).
///
/// Every step is played on the case's own pictures, with the rules of
/// `season2_case09_scenes.dart`:
/// 1. The little clock is the tower of a tiny Paris. Three little clocks
///    are put back on the map carved on its base: only three places have
///    trial clocks.
/// 2. Two gears fitted on the board under it: the tower turns its three
///    trial clocks together; the garden clock, not joined, stays still.
/// 3. The old plan and its repair note in the drawer: the Clockmaker's
///    gear is the trial's emblem; the two clock hands mended a trial wheel.
///    Two marks on two papers; who made them is not said.
/// 4. The tower set one hour back: only the joined clocks go wrong. Then
///    the drum's star points to the Arc de Triomphe.
///
/// Who carried the bag and why it came to the garden, who made the marks,
/// what happened in Paris long ago, and whether an hour was really lost
/// stay untold.
const Map<String, dynamic> season2Episode09Json = {
  'id': 's2_ep09',
  'seasonId': 's2_paris',
  'number': 9,
  'title': 'The Clockwork Garden',
  'place': 'LUXEMBOURG GARDENS',
  'synopsis': [
    'A paper for changing a time fell from a bag.',
    'P. drew the same bag in a garden, beside a little clock.',
    'What is that little clock?',
  ],
  // Never "three" or "joined": that is found on the model.
  'objectives': [
    'Find out what the little clock is.',
    'Make the clocks move.',
    'Test the clocks.',
  ],
  'introScene': 'luxembourgGarden',
  // P.'s drawing under lines 1–3 (`IntroPicture`), turning into the garden
  // at line 4.
  'intro': [
    "You look at P.'s last drawing again.",
    'A palace. A round pond. A little clock on a stone base.',
    'And beside it, the same flat bag.',
    'You walk into the Luxembourg Gardens.',
    "The palace. The pond. It's the garden from the drawing!",
    "Look! That's the little clock from the drawing!",
    'The same bag was here. But why?',
  ],
  'caseSummary':
      "One wrong setting changed only the joined clocks. T1's star pointed to the Arc de Triomphe.",
  'keyWords': ['joined', 'trial', 'gear', 'big', 'small', 'same', 'one hour back', 'changed', 'still'],
  'hook': 'Was the hour lost — or was the clock wrong?',
  'missions': [
    {
      'id': 's2_ep09_m1',
      'number': 1,
      'title': 'The Little Paris',
      'location': 'THE LITTLE PARIS · LUXEMBOURG GARDENS',
      'scene': 'luxembourgGarden',
      'story': [
        'The stone base has a map of Paris on it.',
        'Three little clocks lie in a box beside it.',
      ],
      'letterIntro': 'Beside the box:',
      'letter': 'Put each clock back where it belongs.',
      // Each little clock laid on its place (see `season2TrialMaps`): a
      // wrong place sends it back to the box with its line, never counted.
      'type': 'matchPairs',
      'question': 'Put the three little clocks back on the map.',
      'options': [
        {'id': 't1', 'label': 'T1 · The arch'},
        {'id': 't2', 'label': 'T2 · The bridge'},
        {'id': 't3', 'label': 'T3 · The spire'},
      ],
      'answer': 't1:arcDeTriomphe,t2:seineQuays,t3:artsEtMetiers',
      'hints': [
        "Look at each clock's shape. Find the same shape on the map.",
        'T1 is an arch. T2 is a bridge. T3 is a tall spire.',
      ],
      'clue': {
        'id': 's2_ep09_c1',
        'title': 'Three Trial Clocks',
        'value': 'T1 · T2 · T3',
        'symbol': 'map',
        'note': 'Only three places in Paris have trial clocks.',
      },
      'evidence': {
        'id': 's2_ep09_e1',
        'name': 'Trial Map',
        'icon': 'map',
        'description': 'The little clocks, put back on the map of Paris.',
        'inscription':
            'T1: Arc de Triomphe, a star. T2: Seine bridge, three arches. '
            'T3: Arts et Métiers, a bell.',
      },
      'successMessage': 'All three are back!',
      'transition': [
        'Only three places in Paris have trial clocks.',
        'Each one has a sign: a star, three arches, a bell.',
        'How does one little tower reach all three?',
      ],
      'nextMissionId': 's2_ep09_m2',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.45,
      'mapY': 0.6,
    },
    {
      'id': 's2_ep09_m2',
      'number': 2,
      'title': 'The Gear Path',
      'location': 'UNDER THE LITTLE PARIS',
      'scene': 'gearBoard',
      'story': [
        'A little door opens under the model.',
        'Gears! But two are missing.',
      ],
      'letterIntro': 'Words on the board:',
      'letter': 'Join the tower to the trial clocks.',
      // Each gear fitted in the place of its size (see `season2GearBoards`):
      // the wrong size goes back to the tray, never counted.
      'type': 'matchPairs',
      'question': 'Join the tower to the trial clocks.',
      'options': [
        {'id': 'slot1', 'label': 'The place by T1'},
        {'id': 'slot2', 'label': 'The place by T2 and T3'},
      ],
      'answer': 'slot1:big,slot2:small',
      'hints': [
        'Look at the dotted circles. Which gear fits each one?',
        'The big gear goes near T1. The small gear goes near T2 and T3.',
      ],
      'clue': {
        'id': 's2_ep09_c2',
        'title': 'The Tower Wheel',
        'value': 'Tower → T1 · T2 · T3',
        'symbol': 'gear',
        'note': 'The tower moves only the clocks joined to it.',
      },
      'evidence': {
        'id': 's2_ep09_e2',
        'name': 'Synchronisation Diagram',
        'icon': 'gear',
        'description': 'The gear board under the Little Paris.',
        'inscription':
            'The tower turns T1, T2 and T3. The garden clock is not joined. '
            'The real trial used wires. '
            'Under T1, a drum. Its tag: TRIAL RECORDS · KEPT AT THE STAR.',
      },
      'successMessage': 'They turn together!',
      'transition': [
        'The gears move the model. The real trial used wires.',
        'Under T1, a little drum writes the time.',
        'Its tag says: TRIAL RECORDS · KEPT AT THE STAR.',
        'A drawer opens. Who planned this machine? Who fixed it?',
      ],
      'nextMissionId': 's2_ep09_m3',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.52,
      'mapY': 0.66,
    },
    {
      'id': 's2_ep09_m3',
      'number': 3,
      'title': "The Maker's Marks",
      'location': 'UNDER THE LITTLE PARIS',
      'scene': 'gearBoard',
      'story': [
        'In the drawer: an old plan, CHRONOS TRIAL, with a repair note.',
        'You know these marks!',
      ],
      'letterIntro': 'Your notebook says:',
      'letter':
          "THE CLOCKMAKER'S MARK (Gare du Nord)\n"
          'A tiny carved gear.\n\n'
          'THE REPAIR CARD (No. 7)\n'
          'Signed with two clock hands.',
      // Each notebook mark joined to the same shape on the paper (see
      // `season2MakerMarks`): a wrong one is said why, never counted.
      'type': 'matchPairs',
      'question': 'Find the same marks on the old paper.',
      'options': [
        {'id': 'a', 'label': "The Clockmaker's gear"},
        {'id': 'b', 'label': 'The two clock hands'},
      ],
      'answer': 'a:emblem,b:repair',
      'hints': [
        'Find the same shape on the old paper.',
        'The gear is on the plan. The two hands are on the repair note.',
      ],
      'clue': {
        'id': 's2_ep09_c3',
        'title': 'Two Marks',
        'value': 'Gear = trial · hands = No. 7',
        'symbol': 'seal',
        'note': 'Two marks on two papers. Who made them? The papers do not say.',
      },
      'evidence': {
        'id': 's2_ep09_e3',
        'name': 'Marks Key',
        'icon': 'seal',
        'description': 'An old trial plan with a repair note.',
        'inscription':
            "The plan's emblem is a gear, like the Clockmaker's mark. "
            'The repair note has a stamp of two clock hands, the No. 7 mark. '
            'The papers do not say who made the marks.',
      },
      'successMessage': 'The same marks!',
      'transition': [
        "The Clockmaker's gear is the trial's emblem.",
        'The two hands are on the repair note. No. 7 mended a trial wheel.',
        'Two marks on two different papers. Did one person make both? The papers do not say.',
        "And the paper from the bag? Is it linked to this machine? We can't tell yet.",
      ],
      'nextMissionId': 's2_ep09_final',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.58,
      'mapY': 0.6,
    },
  ],
  'finalMission': {
    'id': 's2_ep09_final',
    'number': 4,
    'title': 'The Wrong Hour',
    'location': 'THE TOWER CLOCK',
    'scene': 'luxembourgGarden',
    'story': [
      "You put the tower's hands back on. Every clock says four.",
      'What if the tower is set wrong?',
    ],
    'letterIntro': 'The card says:',
    'letter': 'Set the tower one hour back. Then press TEST.',
    // The tower set and tested first (`season2TowerTests`), then this.
    'type': 'multipleChoice',
    'question': 'What happened?',
    'options': [
      {
        'id': 'all',
        'label': 'Every clock in Paris went wrong.',
        'feedback': 'Look at the garden clock. What time does it say?',
      },
      {'id': 'connected', 'label': 'Only the joined clocks went wrong.'},
      {
        'id': 'who',
        'label': 'Now we know who set the wrong hour.',
        'feedback': 'The test shows HOW. Does it show WHO?',
      },
    ],
    'answer': 'connected',
    'hints': [
      'One hour back: the short hand goes from 4 to 3.',
      'Which clocks changed? Which one stayed at four?',
    ],
    'evidence': {
      'id': 's2_ep09_e4',
      'name': 'The Wrong Hour Test',
      'icon': 'clock',
      'description': 'A test on the tower clock in the garden.',
      'inscription':
          'The tower was set one hour back. T1, T2 and T3 went to 3:00. The garden clock stayed at 4:00. '
          'The test does not show who set a wrong hour.',
    },
    'successMessage': 'One wrong setting!',
    // After the case is closed (and the star followed: `TowerTestScene.lead`):
    // the post-case scene, then the case report.
    'transition': [
      'One wrong setting can change several connected clocks.',
      "And the bag? Why it came here, we still don't know.",
      'Was an hour really lost? The records at the star may tell.',
      'The mystery continues at the Arc de Triomphe!',
    ],
    'skills': ['problemSolving', 'reading'],
    'mapX': 0.5,
    'mapY': 0.55,
  },
  'glossary': {
    'model': '모형',
    'tiny': '아주 작은',
    'base': '받침',
    'trial': '시험',
    'joined': '이어진',
    'arch': '아치',
    'bridge': '다리',
    'bookstalls': '책 가판대',
    'spire': '뾰족탑',
    'bell': '종',
    'star': '별',
    'gear': '톱니바퀴',
    'gears': '톱니바퀴들',
    'missing': '빠진',
    'fit': '맞다',
    'fits': '맞다',
    'dotted': '점선의',
    'tower': '탑',
    'turn': '돌다, 돌리다',
    'turns': '돈다',
    'drum': '원통',
    'tag': '꼬리표',
    'record': '기록',
    'records': '기록들',
    'kept': '보관된',
    'drawer': '서랍',
    'plan': '설계도',
    'emblem': '문양',
    'repair': '수리',
    'mended': '고쳤다',
    'stamp': '도장',
    'hands': '(시계) 바늘',
    'back': '뒤로',
    'forward': '앞으로',
    'wrong': '틀린',
    'changed': '바뀌었다',
    'several': '여러 개의',
    'connected': '연결된',
    'roads': '길',
    'wires': '전선',
    'palace': '궁전',
    'pond': '연못',
    'garden': '정원',
    'drawing': '그림',
    'bag': '가방',
    'flat': '납작한',
    'clock': '시계',
    'clocks': '시계들',
  },
};
