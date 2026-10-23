/// Case 06 — The Midnight Detective (Covent Garden). Theme: people and
/// clothes. Witnesses describe the stranger in a dark coat differently; the
/// player compares what they agree on, reads a smudged card, and finds out
/// there are two people in dark coats. Final case: who the stranger really
/// is — a detective watching the Raven Society (an ally, not a new enemy).
/// The final page never says his name or his hat: the detective matches
/// what he carries (Mission 01's small bag, the tall man of Mission 03, not
/// the short woman of the Raven Society) to the one who dropped the card by
/// the fountain, and the card (Mission 02) names him.
const Map<String, dynamic> episode06Json = {
  'id': 'ep06',
  'number': 6,
  'title': 'The Midnight Detective',
  'synopsis': [
    'Every night, a stranger in a dark coat comes to Covent Garden.',
    'Everyone tells a different story about him.',
    'Compare what they saw, and find out who he is.',
  ],
  'objectives': [
    'Compare what the witnesses saw.',
    'Find out who the stranger is.',
  ],
  // The place the intro opens on (its picture behind the story lines).
  'introScene': 'coventGarden',
  'intro': [
    'Covent Garden, 11:55 PM...',
    'Every night at this time, a stranger appears in the market.',
    'He wears a long dark coat.',
    'People say he works for the Raven Society.',
    'Tonight, you will find out who he really is.',
  ],
  'caseSummary': 'You compared what every witness saw and found the truth behind the dark coat.',
  'keyWords': ['coat', 'hat', 'carried'],
  'hook': 'Inspector Grey says: "They have half of an old map. Find the other half in Hyde Park."',
  'missions': [
    {
      'id': 'ep06_m1',
      'number': 1,
      'title': 'Three Witnesses',
      'location': 'THE MARKET HALL',
      'scene': 'coventGarden',
      'story': [
        'The market is closing. The lamps are still on.',
        'Three people saw the stranger last night.',
      ],
      'letterIntro': 'You write down what each witness says.',
      'letter':
          'The flower seller: "He was wearing a dark coat. He carried a small bag."\n\n'
          'The juggler: "He had a grey hat. He carried a small bag, too."\n\n'
          'The baker: "He had a dark coat and a big red umbrella."',
      'type': 'multipleChoice',
      'question': 'Two witnesses agree. What did the stranger carry?',
      'options': [
        {
          'id': 'a',
          'label': 'A big red umbrella',
          'feedback': 'Only the baker saw an umbrella. Which thing do TWO witnesses agree on?',
        },
        {'id': 'b', 'label': 'A small bag'},
        {
          'id': 'c',
          'label': 'A bunch of flowers',
          'feedback': 'The flower seller sells flowers. Did any witness say he carried flowers?',
        },
        {
          'id': 'd',
          'label': 'A grey hat',
          'feedback':
              'A hat is worn on the head, not carried. What did he hold?',
        },
      ],
      'answer': 'b',
      'hints': [
        'Read what each witness says he carried. Which thing do two of them say?',
        "'Carried' is what he held in his hand. A hat is worn, not carried. 'Agree' means two people say the same thing.",
      ],
      'clue': {
        'id': 'ep06_c1',
        'title': 'A Small Bag',
        'value': 'Bag',
        'symbol': 'bag',
        'note': 'Two witnesses saw a small bag.',
      },
      'evidence': {
        'id': 'ep06_e1',
        'name': 'Witness Notes',
        'icon': 'letter',
        'description': 'What three witnesses saw.',
        'inscription': 'Dark coat · grey hat · small bag',
      },
      'successMessage': 'He carried a small bag!',
      'transition': [
        'At midnight, you see a figure in a dark coat carrying a small bag.',
        'He walks to the fountain... and drops a small card.',
        'Then he is gone.',
      ],
      'nextMissionId': 'ep06_m2',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.28,
      'mapY': 0.7,
    },
    {
      'id': 'ep06_m2',
      'number': 2,
      'title': 'The Wet Card',
      'location': 'THE FOUNTAIN',
      'scene': 'coventGarden',
      'story': [
        'The card is wet from the fountain.',
        'Some letters of the name are gone.',
      ],
      'letterIntro': 'You hold the card under the lamp.',
      'letter':
          'INSPECTOR ____\n'
          'London Detective Agency\n\n'
          'On the back, in small writing:\n'
          '"My name is a colour.\n'
          'It is the colour of my hat,\n'
          'and of rain clouds and old stones."',
      'type': 'wordInput',
      'question': 'What is the name on the card?',
      'prompt': 'INSPECTOR ____',
      'answer': 'GREY',
      'feedback': {
        'RED': "The red thing was the baker's umbrella. What colour was the hat of the man who dropped the card?",
        'BLACK': 'Black is close to the colour of his coat. The card talks about his hat.',
        'DARK': 'Dark is the colour of his coat. The card talks about his hat.',
        'WHITE': 'Are rain clouds white? Read the back of the card again.',
        'BLUE': 'Is a rain cloud blue? Check the witness notes: what colour was his hat?',
      },
      'acceptedAnswers': ['GRAY', 'INSPECTOR GREY', 'INSPECTOR GRAY'],
      'hints': [
        'Who dropped the card? Look at the witness notes in your notebook.',
        "'The colour of my hat' means his name is the same colour as the hat he wore. Rain clouds are that colour too.",
      ],
      'clue': {
        'id': 'ep06_c2',
        'title': 'A Detective',
        'value': 'Inspector',
        'symbol': 'ticket',
        'note': 'The stranger is an inspector from the Detective Agency.',
      },
      'evidence': {
        'id': 'ep06_e2',
        'name': 'Detective Card',
        'icon': 'ticket',
        'description': 'Dropped by the fountain.',
        'inscription': 'INSPECTOR GREY — LONDON DETECTIVE AGENCY',
      },
      'successMessage': 'Inspector Grey!',
      'transition': [
        'A detective? Then why do people say he is with the Raven Society?',
        'The flower seller whispers:',
        '"I saw a person in a dark coat by the theatre, too."',
      ],
      'nextMissionId': 'ep06_m3',
      'skills': ['reading', 'vocabulary'],
      'mapX': 0.74,
      'mapY': 0.48,
    },
    {
      'id': 'ep06_m3',
      'number': 3,
      'title': 'Two Dark Coats',
      'location': 'THE THEATRE DOOR',
      'scene': 'theatre',
      'story': [
        'The theatre is dark. Only the stage light is on.',
        'The theatre guard keeps a notebook of everyone who walks past.',
      ],
      'letterIntro': "The guard's notebook says:",
      'letter':
          'MONDAY, MIDNIGHT\n'
          'A tall man. A dark coat.\n'
          'A grey hat. A small bag.\n\n'
          'TUESDAY, MIDNIGHT\n'
          'A short woman. A dark coat.\n'
          'A red hat. A big bag.',
      // The guard's two nights, held against the market's Witness Notes
      // (Mission 01: dark coat, grey hat, small bag): only Monday matches.
      // The dark coat is on both nights, so it tells nobody apart
      // (2026-10-23, approved; was a count of the differences, 4).
      'type': 'multipleChoice',
      'question': 'The market witnesses saw one of these two people. Which one?',
      'options': [
        {'id': 'a', 'label': 'Monday: a tall man, a grey hat, a small bag'},
        {
          'id': 'b',
          'label': 'Tuesday: a short woman, a red hat, a big bag',
          'feedback': 'Check your witness notes. What colour was the hat? How big was the bag?',
        },
        {
          'id': 'c',
          'label': 'Both of them: they both wore a dark coat',
          'feedback': 'Both wore dark coats, so the coat cannot tell them apart. Look at the hat and the bag.',
        },
      ],
      'answer': 'a',
      'hints': [
        'Open your notebook: the Witness Notes from the market. Which night matches them?',
        'Only one detail is the same on both nights. Use the details that are different.',
      ],
      'clue': {
        'id': 'ep06_c3',
        'title': 'Two People',
        'value': 'Red hat',
        'symbol': 'mask',
        'note': 'A second person in a dark coat wears a red hat.',
      },
      'evidence': {
        'id': 'ep06_e3',
        'name': 'Theatre Ticket',
        'icon': 'ticket',
        // The raven on the back is kept here too, so the notebook still shows
        // why she is the Raven Society's (the final rules her out by it).
        'description': 'Dropped by the woman in the red hat. A black raven is stamped on the back.',
        'inscription': 'ROW R · SEAT 17',
      },
      'successMessage': 'Monday matches the market. Tuesday was someone else!',
      'transition': [
        // Where the ticket comes from: the guard hands it over.
        'The guard gives you a theatre ticket. "The woman in the red hat dropped it."',
        // R and 17 are left for the child to connect (Case 02's 8:17): the
        // scene hints, it does not explain.
        'Row R, seat 17. The letter R and the number 17 seem familiar.',
        // The fact the final needs, seen on the ticket (the mark of Cases 03,
        // 04): she is the Raven Society's, so the tall man is someone else.
        'On the back, a black raven is stamped: the mark of the Raven Society.',
        // Who the man is, is the final's question: the scene only asks it
        // (not by his hat: "grey" would hand over the name).
        'But who is the tall man?',
      ],
      'nextMissionId': 'ep06_final',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.3,
      'mapY': 0.26,
    },
  ],
  'finalMission': {
    'id': 'ep06_final',
    'number': 4,
    'title': 'The Midnight Detective',
    'location': 'MIDNIGHT',
    'scene': 'coventGarden',
    'story': [
      'The church clock rings twelve times.',
      'A stranger in a dark coat is standing by the fountain again.',
    ],
    'letterIntro': 'You write down what you see.',
    // What he is like, never his name or his hat. The small bag and "tall"
    // match the man of Missions 01 and 03 (not the short woman with the big
    // bag); that man dropped his card by the fountain, and the card
    // (Mission 02) names him. That he is on your side is the post-case
    // scene's to tell.
    'letter':
        'MIDNIGHT, BY THE FOUNTAIN\n\n'
        'A tall man. A dark coat.\n'
        'He carries a small bag.\n\n'
        'He looks down into the water,\n'
        'as if he lost something there.',
    'type': 'multipleChoice',
    'question': 'Who is the man by the fountain?',
    'options': [
      {
        'id': 'a',
        'label': 'A Raven Society thief',
        'feedback': 'The ticket with the raven was dropped by the short woman. Is the man by the fountain short, with a big bag?',
      },
      {
        'id': 'b',
        'label': 'The theatre guard',
        'feedback': 'The theatre guard was writing in his notebook at the theatre door. Did he drop anything by the fountain?',
      },
      {'id': 'c', 'label': 'Inspector Grey'},
      {
        'id': 'd',
        'label': 'The juggler',
        'feedback': 'The juggler was a witness: he saw the stranger. Is he the stranger?',
      },
    ],
    'answer': 'c',
    'hints': [
      'Is he tall or short? Is his bag big or small? Find the person in your notes who matches him.',
      'The stranger with the small bag dropped something by the fountain. Open your notebook and look closer at it.',
    ],
    'evidence': {
      'id': 'ep06_e4',
      'name': 'Silver Whistle',
      'icon': 'whistle',
      'description': 'A gift from Inspector Grey.',
      'inscription': '"Blow it if you need help."',
    },
    'successMessage': 'You identified the man by the fountain!',
    // After the case is closed: the post-case story scene (existing facts only).
    'transition': [
      'Inspector Grey is on your side.',
      'He gives you a silver whistle.',
      '"Blow it if you need help, Detective {detectiveName}."',
      'Then he tells you one more thing.',
      '"Find the other half\nin Hyde Park."',
      'The mystery is getting bigger.',
    ],
    'skills': ['reading', 'problemSolving'],
    'mapX': 0.72,
    'mapY': 0.84,
  },
  'glossary': {
    'midnight': '자정, 밤 12시',
    'stranger': '낯선 사람',
    'appears': '나타나다',
    'witness': '목격자',
    'witnesses': '목격자들',
    'seller': '판매원',
    'juggler': '저글링하는 사람',
    'baker': '제빵사',
    'carried': '들고 다녔다',
    'carries': '들고 다닌다',
    'wearing': '입고 있는',
    'wore': '입었다',
    'agree': '의견이 같다',
    'umbrella': '우산',
    'fountain': '분수',
    'inspector': '형사, 경감',
    'agency': '사무소, 기관',
    'colour': '색깔',
    'clouds': '구름들',
    'smudged': '번진',
    'tall': '키가 큰',
    'short': '키가 작은',
    'same': '같은',
    'different': '다른',
    'theatre': '극장',
    'stage': '무대',
    'costume': '의상, 변장',
    'side': '편',
    'whispers': '속삭인다',
    'lamps': '등불들',
    'church': '교회',
    'ticket': '표',
    'row': '줄, 열',
    'seat': '좌석',
    'compare': '비교하다',
    'matches': '~와 맞다, 일치하다',
    // The five details 06-M3 asks to compare, and the ticket's raven mark.
    'details': '세부 사항, 특징',
    // 06-M3's two nights held against the market's notes (2026-10-23).
    'detail': '세부 사항, 특징',
    'apart': '따로 (tell apart: 구별하다)',
    'height': '키',
    'person': '사람 (남자인지 여자인지)',
    'raven': '까마귀',
    'stamped': '(도장으로) 찍혀 있다',
    'mark': '표시, 상징',
  },
};
