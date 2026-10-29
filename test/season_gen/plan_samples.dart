/// A small season plan and case plan of a made-up season (`s3_sample`),
/// fresh JSON each call so a test may change it. Never a season of the
/// game: they exist for the season content pipeline's tests only.
library;

Map<String, Object?> sampleSeasonJson() => {
  'schemaVersion': 1,
  'seasonId': 's3_sample',
  'number': 3,
  'city': 'Sample City',
  'title': 'The Sample Case',
  'tagline': 'ONE TEST',
  'plannedCases': 12,
  'mainMystery': {
    'truth': 'The station clock was set back on purpose.',
    'culprit': 'The guide',
    'motive': 'To hide a late train.',
    'revealCase': 's3_ep12',
  },
  'characters': [
    {'charId': 'guide', 'name': 'The Guide', 'role': 'Shows the detective round', 'firstCase': 's3_ep01', 'revealCase': 's3_ep12', 'secretUntil': 's3_ep11'},
    {'charId': 'porter', 'name': 'The Porter', 'role': 'Carries the bags', 'firstCase': 's3_ep02'},
  ],
  'locations': [
    {'locId': 'station', 'name': 'Central Station', 'landmarkKey': 'centralStation'},
  ],
  'acts': [
    for (final (i, theme) in ['ONE', 'TWO', 'THREE'].indexed)
      {
        'actId': 'act${i + 1}',
        'theme': 'ACT $theme',
        'caseIds': [for (var c = i * 4 + 1; c <= i * 4 + 4; c++) 's3_ep${c.toString().padLeft(2, '0')}'],
      },
  ],
  'prologue': {
    'city': 'Sample City at night.',
    'question': 'Who stopped the clock?',
    'firstCase': {'picture': 'station', 'line': 'It starts at the station.'},
  },
  'outro': ['The clock runs again.'],
  'finale': ['Sample City is safe.'],
  'figures': [
    {'after': 's3_ep12', 'figure': 'guide', 'label': 'The Guide'},
  ],
  'languageArc': ['Act 1: time words.'],
  'notes': ['A made-up season for tests.'],
};

Map<String, Object?> sampleMissionJson(int n) => {
  'missionId': 's3_ep01_m$n',
  'slot': 'm$n',
  'placeId': 's3_sample.station',
  'puzzle': {
    'paletteId': 'text_choice',
    'surface': 'mission',
    'engineTable': null,
    'missionType': 'multipleChoice',
    'answerSpec': {
      'answer': 'b',
      'options': [
        {'id': 'a', 'label': 'Platform 1', 'feedback': 'Read the board again.'},
        {'id': 'b', 'label': 'Platform 2'},
        {'id': 'c', 'label': 'Platform 3'},
      ],
    },
    'assetNeeds': <Object?>[],
    'status': 'ready',
  },
  'clueInputs': [
    if (n > 1) {'ref': 's3_ep01_c${n - 1}', 'use': 'recall'},
  ],
  'clueOutputs': {
    'clue': 's3_ep01_c$n',
    'evidence': 's3_ep01_e$n',
    'facts': ['s3_ep01_f$n'],
  },
  'learning': {
    'dependency': 'essential',
    'level': 'comprehension',
    'objective': '안내판의 문장을 읽고 승강장을 찾는다.',
    'skill': 'sentenceMeaning',
    'expressions': ['The 9:10 train leaves from Platform 2.'],
    if (n > 1) 'recallFrom': 's3_ep01_m${n - 1}',
  },
};

Map<String, Object?> sampleFinalJson() => {
  'missionId': 's3_ep01_final',
  'slot': 'final',
  'placeId': 's3_sample.station',
  'puzzle': {
    'paletteId': 'scene_explore_choose',
    'surface': 'finalMission',
    'engineTable': 'explores',
    'missionType': 'letterLock',
    'answerSpec': {
      'answer': 'TIME',
      'acceptedAnswers': ['time'],
      'options': [
        {'id': 't', 'label': 'T'},
        {'id': 'i', 'label': 'I'},
        {'id': 'm', 'label': 'M'},
        {'id': 'e', 'label': 'E'},
      ],
      'codeLength': 4,
    },
    'assetNeeds': ['s3_sample.asset.station_hall'],
    'status': 'awaitingAssets',
    'notes': ['Surface and palette fit are STEP 3-3\'s to check.'],
  },
  'clueInputs': [
    {'ref': 's3_ep01_c1', 'use': 'answerDerivation', 'note': 'T'},
    {'ref': 's3_ep01_e2', 'use': 'talkPresent'},
    {'ref': 's3_ep01_f3', 'use': 'textMention'},
  ],
  'clueOutputs': {'evidence': 's3_ep01_e4'},
  'learning': {'dependency': 'low', 'level': 'exposure', 'objective': '모은 글자로 단어를 만든다.'},
};

/// [sampleSeasonJson] with its places' pictures (STEP 3-8).
Map<String, Object?> samplePlaySeasonJson() => {
  ...sampleSeasonJson(),
  'places': [
    {'placeId': 's3_sample.station', 'file': 'assets/sample/station.png', 'pixels': {'width': 1536, 'height': 1024}},
  ],
  'storyGreeting': false,
};

/// [sampleCaseJson] with the words the game shows (STEP 3-8), every field
/// of them given (Mission 2's: a recall and an evidence link besides).
Map<String, Object?> samplePlayCaseJson() {
  final json = sampleCaseJson();
  final missions = json['missions'] as List;
  final m2 = missions[1] as Map<String, Object?>;
  (m2['clueInputs'] as List).add({'ref': 's3_ep01_e1', 'use': 'evidenceLink'});
  m2['play'] = {
    'title': 'The Board',
    'location': 'CENTRAL STATION',
    'story': ['The board lists three platforms.'],
    'letterIntro': 'Your notebook says:',
    'letter': 'The 9:10 train leaves from Platform 2.',
    'question': 'Which platform?',
    'prompt': 'PLATFORM _',
    'hints': ['Read the note again.', 'Find the number.'],
    'successMessage': 'You found the platform!',
    'transition': ['A train comes in.'],
    'feedback': {'1': 'That train left at 9:00.'},
    'orderFeedback': 'Right numbers, wrong order.',
    'mapX': 0.4,
    'mapY': 0.6,
    'clue': {'title': 'The Platform', 'value': 'PLATFORM 2', 'note': 'The 9:10 train left from Platform 2.', 'symbol': 'train'},
    'evidence': {'name': 'The Board', 'icon': 'map', 'description': 'The station board.', 'inscription': 'PLATFORM 2', 'symbols': ['train']},
    'recall': {'title': 'Find an old clue', 'prompt': 'Look in your Notebook.', 'feedback': {'s3_ep01_e3': 'Not that one.'}, 'miss': 'Look again.'},
    'evidenceLinkLine': 'Both name Platform 2.',
    'lockTitle': 'THE PLATFORM LOCK',
    // The story around the puzzle (STEP 3-13B).
    'talk': {
      'speaker': 'guide',
      'portrait': 'assets/sample/guide.png',
      'goal': 'Find the platform.',
      'before': {
        'lines': [
          {'by': 'speaker', 'text': 'Look at the board.'},
          {'by': 'detective', 'text': 'Which train?'},
        ],
        'finishLabel': 'READ THE BOARD',
      },
      'after': {
        'lines': [
          {'by': 'narrator', 'text': 'The guide nods.'},
        ],
      },
    },
    'discovery': {
      'type': 'clueFound',
      'timing': 'fromPuzzle',
      'title': 'PLATFORM 2',
      'detail': 'The 9:10 train left from there.',
      'note': 'The board was by the clock.',
      'showEvidence': false,
      'seasonClue': true,
    },
  };
  (json['final'] as Map<String, Object?>)['play'] = {
    'ending': [
      {'by': 'speaker', 'text': 'You found it!', 'speaker': 'guide', 'portrait': 'assets/sample/guide.png', 'evidence': 's3_ep01_e2'},
      {'by': 'narrator', 'text': 'The clock starts again.'},
    ],
  };
  json['play'] = {
    'objectives': ['Find the platform.'],
    'intro': ['The station is quiet.'],
    'caseSummary': 'A platform and a clock closed the case.',
    'place': 'CENTRAL STATION · SAMPLE CITY',
    'keyWords': ['platform'],
    'glossary': {'platform': '승강장'},
  };
  return json;
}

Map<String, Object?> sampleCaseJson() => {
  'schemaVersion': 1,
  'caseId': 's3_ep01',
  'seasonId': 's3_sample',
  'number': 1,
  'actId': 'act1',
  'title': 'The Stopped Clock',
  'synopsis': ['The station clock has stopped.'],
  'goal': 'Find who stopped it.',
  'characters': ['guide'],
  'locations': ['station'],
  'missions': [for (var n = 1; n <= 3; n++) sampleMissionJson(n)],
  'final': sampleFinalJson(),
  'hook': 'Where did the guide go?',
  'learningGoal': {'title': 'Time words', 'titleKo': '시간 표현'},
};
