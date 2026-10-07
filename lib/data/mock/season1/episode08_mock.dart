/// Case 08 — The Mystery on Platform 9 (King's Cross). Theme: questions and
/// answers. The player chooses what to ask, reads the passengers' answers
/// against the name tag, and finally answers a lie with evidence.
/// Final case: Mrs Robin says she was never in Gallery 8. Only one thing of
/// Case 03 can tie her to that room: the Red Button (from a coat, found in
/// Gallery 8; in the Case Archive) and her long red coat (Mission 02). The
/// final page names neither the button nor the coat; that she is Miss Rose
/// is the detective's to see, and the post-case scene only confirms it.
const Map<String, dynamic> episode08Json = {
  'id': 'ep08',
  'number': 8,
  'title': 'The Mystery on Platform 9',
  'synopsis': [
    'A suitcase is standing alone on Platform 9.',
    'The name on its tag has been washed away.',
    'Ask the right questions and find its owner.',
  ],
  'objectives': ['Ask the passengers the right questions.', "Find the suitcase's owner."],
  // The place the intro opens on (its picture behind the story lines).
  'introScene': 'kingsCross',
  'intro': [
    "King's Cross, 9:00 PM...",
    'The old map led you here: nine ravens around Platform 9.',
    'On the platform, a suitcase stands alone.',
    'The rain has washed the name off its tag.',
    'Four passengers are waiting for the last train. One of them is the owner.',
  ],
  'caseSummary': 'You asked the right questions, listened to every answer and found the owner of the suitcase.',
  'keyWords': ['where', 'alone', 'ticket'],
  'hook': 'Mrs Robin whispers: "I only carry things. The Clockmaker gives the orders."',
  'missions': [
    {
      'id': 'ep08_m1',
      'number': 1,
      'title': 'The Name Tag',
      'location': 'PLATFORM 9',
      'scene': 'suitcase',
      'story': [
        'The suitcase is black, with a small silver lock.',
        'Only part of the name tag can still be read.',
      ],
      'letterIntro': 'The name tag says:',
      'letter':
          'NAME: ~~~~~~~~\n'
          'FROM: London\n'
          'TO: Edinburgh\n'
          'TRAVELLER: 1 adult, alone\n'
          'TRAIN: the 9:30 to Edinburgh',
      'type': 'multipleChoice',
      'question': 'You can ask the passengers one question. Which question helps most?',
      'options': [
        {'id': 'a', 'label': '"Do you like trains?"'},
        {'id': 'b', 'label': '"Where are you going?"'},
        {'id': 'c', 'label': '"What time is it?"'},
        {'id': 'd', 'label': '"Is it raining?"'},
      ],
      'answer': 'b',
      'hints': [
        'The name is gone. Which part of the tag can you still check?',
        'The tag tells you the city the owner is travelling to.',
      ],
      'clue': {
        'id': 'ep08_c1',
        'title': 'To Edinburgh',
        'value': 'Edinburgh',
        'symbol': 'train',
        'note': 'The owner is going to Edinburgh, alone.',
      },
      'evidence': {
        'id': 'ep08_e1',
        'name': 'Name Tag',
        'icon': 'ticket',
        'description': 'The name is gone. The rest is not.',
        'inscription': 'TO: EDINBURGH · 1 ADULT, ALONE',
      },
      'successMessage': 'Good question, Detective!',
      'transition': [
        'You walk along the platform.',
        '"Excuse me," you say. "Where are you going?"',
        'Every passenger answers.',
      ],
      'nextMissionId': 'ep08_m2',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.28,
      'mapY': 0.18,
    },
    {
      'id': 'ep08_m2',
      'number': 2,
      'title': 'Four Passengers',
      'location': 'THE WAITING ROOM',
      'scene': 'waitingRoom',
      'story': [
        'The waiting room is warm. The big clock says 9:20.',
        'You write down every answer.',
      ],
      'letterIntro': 'Your notes:',
      'letter':
          'Mrs Patel: "I am going to York to see my sister."\n\n'
          'Mr Brown: "Edinburgh? No, no. I am going to Cambridge."\n\n'
          'Lily: "My dad and I are going to Edinburgh!"\n\n'
          'Mrs Robin, in a long red coat: "I am going to Edinburgh. I am travelling alone."',
      'type': 'wordInput',
      'question': 'Who is the owner of the suitcase? Write the name.',
      'prompt': 'MRS _____',
      'answer': 'ROBIN',
      'acceptedAnswers': ['MRS ROBIN'],
      'hints': [
        'Two passengers are going to Edinburgh. Look at the name tag again.',
        'The owner travels with nobody else.',
      ],
      'clue': {
        'id': 'ep08_c2',
        'title': 'Travelling Alone',
        'value': 'Mrs Robin',
        'symbol': 'bag',
        // Her coat is noted here too, so the final can be checked in the
        // notebook (the final page does not say it).
        'note': 'Only Mrs Robin goes to Edinburgh alone. She wears a long red coat.',
      },
      'evidence': {
        'id': 'ep08_e2',
        'name': 'Passenger Notes',
        'icon': 'letter',
        'description': 'Four answers to one question.',
        'inscription': 'York · Cambridge · Edinburgh (2) · Edinburgh (1)',
      },
      'successMessage': 'It must be Mrs Robin!',
      'transition': [
        'Mrs Robin wears a long red coat and a blue scarf.',
        'A robin is a bird... and so is a raven.',
        'The station guard helps you open the suitcase.',
      ],
      'nextMissionId': 'ep08_m3',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.72,
      'mapY': 0.4,
    },
    {
      'id': 'ep08_m3',
      'number': 3,
      'title': 'Inside the Suitcase',
      'location': 'THE STATION OFFICE',
      'scene': 'suitcase',
      'story': [
        'The small silver lock needs a three-number code.',
        'Mrs Robin dropped her ticket. A note is stuck to the lock.',
      ],
      'letterIntro': 'You read the ticket and the note.',
      'letter':
          'TICKET\n'
          'Train: the 9:30 to Edinburgh\n'
          'Coach: B\n'
          'Seat: forty-two\n\n'
          'NOTE ON THE LOCK\n'
          'My code: first my seat number,\n'
          'then the hour of my train.',
      'type': 'numberCode',
      'question': 'Open the silver lock.',
      'codeLength': 3,
      'answer': '429',
      'hints': [
        'Write the seat number with numbers, not words.',
        'The hour is the first number of the train time. Put it after the seat.',
      ],
      'clue': {
        'id': 'ep08_c3',
        'title': 'Picture 17',
        'value': 'Found',
        'symbol': 'frame',
        'note': 'The missing painting was in the suitcase.',
      },
      'evidence': {
        'id': 'ep08_e3',
        'name': 'The Raven Tower',
        'icon': 'frame',
        'description': 'The painting from Gallery 8.',
        'inscription': 'On the back: a small drawing of a jewel.',
      },
      'successMessage': 'Click! Inside: the missing painting!',
      'transition': [
        'The painting from Gallery 8 — The Raven Tower!',
        'Mrs Robin walks fast toward the last train.',
        'The whistle blows. The doors are closing.',
        'Stop her with the right words!',
      ],
      'nextMissionId': 'ep08_final',
      'skills': ['reading', 'vocabulary'],
      'mapX': 0.3,
      'mapY': 0.62,
    },
  ],
  'finalMission': {
    'id': 'ep08_final',
    'number': 4,
    'title': 'The Last Train',
    'location': 'THE 9:30 TO EDINBURGH',
    'scene': 'kingsCross',
    'story': [
      'Mrs Robin stops at the train door.',
      '"That is not my suitcase!" she says. "I have never seen it."',
    ],
    'letterIntro': 'She looks at you and says:',
    // Her lie, and nothing about her coat: the detective brings the coat
    // (Mission 02) and the Red Button (Case 03: from a coat, found in
    // Gallery 8) together. The Wet Footprint is Case 03's too, but it was
    // found in the Great Court and nothing ties it to her; the two cards of
    // this case say nothing about Gallery 8. Not the Blue Cloth (her blue
    // scarf: a second answer) nor The Raven Tower (from Gallery 8, but she
    // says the suitcase is not hers).
    'letter':
        '"My name is Mrs Robin.\n'
        'I have never been to the British Museum.\n'
        'I was never in Gallery 8.\n\n'
        'You cannot prove it, Detective!"',
    'type': 'multipleChoice',
    'question': 'Which evidence shows that she was in Gallery 8?',
    'options': [
      {'id': 'a', 'label': 'Name Tag'},
      {'id': 'b', 'label': 'Wet Footprint'},
      {'id': 'c', 'label': 'Red Button'},
      {'id': 'd', 'label': 'Passenger Notes'},
    ],
    'answer': 'c',
    'hints': [
      'Think back to an earlier case. The thief left small things in Gallery 8. Which one could have come from Mrs Robin?',
      'Open your notebook, then the Case Archive, then Case 03. Look closer at each thing: where was it found? Then think about what Mrs Robin is wearing.',
    ],
    'evidence': {
      'id': 'ep08_e4',
      'name': 'Empty Jewel Box',
      'icon': 'gem',
      'description': 'At the bottom of the suitcase.',
      'inscription': 'BUCKINGHAM PALACE — it is empty.',
    },
    'successMessage': 'Mrs Robin cannot say no!',
    // After the case is closed: the post-case story scene (existing facts only).
    'transition': [
      'Mrs Robin cannot say no.',
      // Confirmation of what the detective proved, not a new deduction.
      'The button fits the empty place\non her long red coat.',
      'You were right.\nMiss Rose was Mrs Robin all along.',
      'Before you leave,\nyou look inside her suitcase.',
      'At the bottom is an empty jewel box.',
      'BUCKINGHAM PALACE.',
      'Then Mrs Robin whispers:',
      '"The Clockmaker gives the orders."',
    ],
    'skills': ['reading', 'problemSolving'],
    'mapX': 0.74,
    'mapY': 0.84,
  },
  'glossary': {
    'passengers': '승객들',
    'passenger': '승객',
    'owner': '주인',
    'tag': '꼬리표',
    'traveller': '여행자',
    'travelling': '여행하는',
    'adult': '어른',
    'alone': '혼자',
    'edinburgh': '에든버러(스코틀랜드의 도시)',
    'york': '요크(영국의 도시)',
    'cambridge': '케임브리지(영국의 도시)',
    'sister': '언니, 누나, 여동생',
    'excuse': '실례하다',
    'answers': '대답하다',
    'waiting': '기다리는',
    'parcel': '꾸러미',
    'carefully': '조심스럽게',
    'coach': '(기차의) 객차',
    'seat': '좌석',
    'forty': '40',
    'code': '암호, 번호',
    'hour': '시(時)',
    'robin': '울새(작은 새)',
    'whistle': '호루라기, 기적 소리',
    'closing': '닫히는',
    'lie': '거짓말',
    'missing': '없어진',
    'buttons': '단추들',
    'shiny': '반짝이는',
    'tired': '피곤한',
    'trip': '여행',
    'scarf': '목도리',
    'suitcase': '여행 가방',
    'platform': '승강장',
  },
};
