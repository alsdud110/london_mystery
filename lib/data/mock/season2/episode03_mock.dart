/// Season 2, Case 03 — The Tower's Secret (the Eiffel Tower, Paris).
/// Theme: records that do not agree, and what they hide.
///
/// Case 02 ended on the back of the painter's canvas: TOUJOURS PLUS HAUT,
/// always higher, and beside the words a small drawing of a tall iron
/// tower. The detective follows the drawing to the Eiffel Tower. That the
/// painter went there is never said: the tower is only where the drawing
/// leads.
///
/// Every step is played on the case's own pictures, the words on its
/// papers written by the app (`season2_case03_scenes.dart` measures where):
/// 1. Two records of the same day and the same job: the visitor notice
///    says the lift inspection is at 4:00 PM, the maintenance log 3:00 PM.
///    Only the times differ; the detective picks them on both.
/// 2. The lift log has a trip at 3:20 from Second to a stop not written,
///    marked S, and the return at 4:25. Only the route plate says what S
///    is (a SERVICE RUN) and which stop is on the service route alone: the
///    Service Level. The log alone does not tell.
/// 3. At the Service Level, a padlock with three dials (a clock, a lift, a
///    key) and a note: FIRST check the clock, NEXT stop the lift, FINALLY
///    turn the key.
/// 4. In the hidden room, each question is answered with the evidence that
///    shows it (the records; the lift log; the lift log and the room
///    together), and only what the evidence shows is concluded: someone
///    went into the service area in the hour the records disagree on. That
///    an hour really vanished cannot be proved. Inside the machine, a brass
///    plaque: ONE HOUR IS MISSING. THE CLOCK IS STILL RUNNING. Under its
///    waves, SEINE.
///
/// Who the Clockmaker is stays untold; who left the plaque, too.
const Map<String, dynamic> season2Episode03Json = {
  'id': 's2_ep03',
  'seasonId': 's2_paris',
  'number': 3,
  'title': "The Tower's Secret",
  'place': 'EIFFEL TOWER · PARIS',
  'synopsis': [
    "The painter's last message said: ALWAYS HIGHER.",
    'Beside it, a small drawing of a tall iron tower.',
    'At the Eiffel Tower, two records do not agree.',
  ],
  'objectives': [
    'Compare the two records.',
    'Find where the lift went.',
    'Open the iron door.',
  ],
  // The back of Case 02's last canvas: its tower sketch is where the case
  // begins.
  'introScene': 'paintersMessage',
  'intro': [
    'The painter left one last message. Always higher.',
    'You turn the canvas over once more. Beside the words, you notice a small drawing.',
    'A tall iron tower. The Eiffel Tower.',
    'By the time you arrive, the sky is turning gold. Something strange is waiting near the entrance.',
    'Two records describe the same inspection. But something does not match.',
  ],
  'caseSummary':
      'You compared two records, followed the lift to the Service Level, opened the iron door and linked your evidence. Inside the machine, a brass plaque was waiting.',
  'keyWords': ['inspection', 'record', 'service', 'first', 'next', 'finally'],
  'hook': 'One hour is missing, and the clock is still running. Who left the message, and why does it lead to the river?',
  'missions': [
    {
      'id': 's2_ep03_m1',
      'number': 1,
      'title': 'The Two Notices',
      'location': 'THE TOWER ENTRANCE',
      'scene': 'towerEntrance',
      'story': [
        'At the foot of the Eiffel Tower, the lamps are coming on.',
        'By the gate stands a notice board for visitors.',
        'In the ticket booth, someone has left the maintenance log.',
      ],
      'letterIntro': 'Your notebook says:',
      'letter':
          'Two records.\n'
          'The same day. The same job.\n\n'
          'Read them both, line by line.\n'
          'Find the two lines that do not match.',
      // A line picked on each record (`notice:log`): only the times differ.
      'type': 'matchPairs',
      'question': 'Which lines do not match?',
      'options': [
        {'id': 'date', 'label': 'The date'},
        {'id': 'job', 'label': 'The job'},
        {'id': 'time', 'label': 'The time'},
      ],
      'answer': 'time:time',
      'feedback': {
        'date:date': 'Both records say 12 MAY. The dates match. Look again.',
        'job:job': 'Both records say LIFT INSPECTION. The jobs match. Look again.',
        'date:job': 'Compare the same line on both records: date with date, time with time.',
        'date:time': 'Compare the same line on both records: date with date, time with time.',
        'job:date': 'Compare the same line on both records: date with date, time with time.',
        'job:time': 'Compare the same line on both records: date with date, time with time.',
        'time:date': 'Compare the same line on both records: date with date, time with time.',
        'time:job': 'Compare the same line on both records: date with date, time with time.',
      },
      'hints': [
        'Read each record line by line: the date, the job, the time.',
        'The date and the job are the same on both. What about the time?',
      ],
      'clue': {
        'id': 's2_ep03_c1',
        'title': 'Check the Lift Log',
        'value': 'CHECK THE LIFT LOG.',
        'symbol': 'letter',
        'note': 'At the bottom of the maintenance log, a pencil line: CHECK THE LIFT LOG.',
      },
      'evidence': {
        'id': 's2_ep03_e1',
        'name': 'The Conflicting Notices',
        'icon': 'letter',
        'description': 'Found at the entrance of the Eiffel Tower.',
        'inscription':
            'VISITOR NOTICE: LIFT INSPECTION, 4:00 PM. MAINTENANCE LOG: LIFT INSPECTION, 3:00 PM. '
            'The same day, the same job, one hour apart.',
      },
      'successMessage': 'The times do not match!',
      'transition': [
        "The visitor notice says four o'clock.",
        "The maintenance log says three o'clock.",
        'The same day. The same job. One hour apart.',
        'At the bottom of the log, a pencil line: CHECK THE LIFT LOG.',
      ],
      'nextMissionId': 's2_ep03_m2',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.5,
      'mapY': 0.2,
    },
    {
      'id': 's2_ep03_m2',
      'number': 2,
      'title': 'The Lift That Stopped',
      'location': 'THE TOWER LIFT',
      'scene': 'towerLift',
      'story': [
        'The old lift has brass gates and wooden walls.',
        'On one wall hangs a brass route plate. On the other, the lift log.',
        "Where did the lift go after three o'clock?",
      ],
      'letterIntro': 'Your notebook says:',
      'letter':
          'CHECK THE LIFT LOG.\n\n'
          'Read every trip.\n'
          'One stop is not written.\n'
          'The route plate shows every stop.',
      'type': 'multipleChoice',
      'question': 'Where did the lift go at 3:20?',
      'options': [
        {
          'id': 'ground',
          'label': 'Ground',
          'feedback': 'The lift came back down to Ground at 4:25. Where was it before that?',
        },
        {
          'id': 'first',
          'label': 'First',
          'feedback': 'First is a stop on the passenger route. The 3:20 trip has an S. What does S mean?',
        },
        {
          'id': 'top',
          'label': 'Top',
          'feedback': 'Top is a stop on the passenger route. The 3:20 trip has an S. What does S mean?',
        },
        {'id': 'service', 'label': 'Service Level'},
      ],
      'answer': 'service',
      'hints': [
        'Find the S in the lift log. Then find what S means on the route plate.',
        'S = SERVICE RUN. Which stop is only on the service route?',
      ],
      'clue': {
        'id': 's2_ep03_c2',
        'title': 'Service Access Only',
        'value': 'SERVICE ACCESS ONLY',
        'symbol': 'key',
        'note': 'At the Service Level, a sign on an iron door: SERVICE ACCESS ONLY.',
      },
      'evidence': {
        'id': 's2_ep03_e2',
        'name': 'The Lift Log',
        'icon': 'ticket',
        'description': 'Kept in a holder on the wall of the lift.',
        'inscription':
            '3:05 Ground to First. 3:12 First to Second. 3:20 Second to the Service Level (S: a SERVICE RUN). '
            '4:25 the Service Level to Ground.',
      },
      'successMessage': 'You found the missing stop!',
      'transition': [
        'At 3:20, the lift left the passenger route.',
        'It went up to the Service Level. It came back down at 4:25.',
        'You ride the lift up. The gates open onto a dark iron platform.',
        'On an iron door, a sign: SERVICE ACCESS ONLY.',
      ],
      'nextMissionId': 's2_ep03_m3',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.56,
      'mapY': 0.16,
    },
    {
      'id': 's2_ep03_m3',
      'number': 3,
      'title': 'Behind the Iron Door',
      'location': 'THE SERVICE LEVEL',
      'scene': 'serviceDoor',
      'story': [
        'The Service Level is dark and quiet.',
        'Visitors never come up here.',
        'The iron door is locked with a heavy padlock. It has three dials.',
      ],
      'letterIntro': 'The sign says SERVICE ACCESS ONLY. Beside the door, a note is pinned:',
      'letter':
          'INSPECTION STEPS\n\n'
          'First, check the clock.\n'
          'Next, stop the lift.\n'
          'Finally, turn the key.',
      // The symbols set on the three dials, left to right.
      'type': 'sequence',
      'question': 'Set the three dials. Then open the lock.',
      'options': [
        {'id': 'clock', 'label': 'Clock'},
        {'id': 'lift', 'label': 'Lift'},
        {'id': 'key', 'label': 'Key'},
      ],
      'answer': 'clock,lift,key',
      'codeLength': 3,
      'orderFeedback': 'The right pictures, but not in the right order. Read the note: FIRST, NEXT, FINALLY.',
      'hints': [
        'Read the note again. FIRST, NEXT and FINALLY tell you the order.',
        'Dial 1 is what you do FIRST. Dial 2 is NEXT. Dial 3 is FINALLY.',
      ],
      'clue': {
        'id': 's2_ep03_c3',
        'title': 'The Hidden Room',
        'value': 'A hidden room',
        'symbol': 'key',
        'note': 'Behind the iron door: a small machine room. Only the service staff can come in.',
      },
      'evidence': {
        'id': 's2_ep03_e3',
        'name': 'The Service Room',
        'icon': 'key',
        'description': 'Behind the locked iron door at the Service Level.',
        'inscription':
            'A hidden machine room. Only the service staff can come in. At the back stands an old time-recording machine.',
      },
      'successMessage': 'The lock is open!',
      'transition': [
        'Click. The padlock opens.',
        'Behind the iron door is a small hidden room.',
        'Wheels, cables and gears. And at the back, an old machine with a clock.',
        'Two time cards are still inside it.',
      ],
      'nextMissionId': 's2_ep03_final',
      'skills': ['reading', 'problemSolving'],
      'mapX': 0.62,
      'mapY': 0.22,
    },
  ],
  'finalMission': {
    'id': 's2_ep03_final',
    'number': 4,
    'title': 'The Missing Hour',
    'location': 'THE HIDDEN SERVICE ROOM',
    'scene': 'timeMachine',
    'story': [
      'The old machine has a clock face and a slot for time cards.',
      'Two cards are inside. They show two different times.',
      'What really happened at the tower?',
    ],
    'letterIntro': 'The two time cards say:',
    'letter':
        'OFFICIAL TIME — 4:00\n\n'
        'RECORDED TIME — 3:00',
    // Each question's evidence (`question:e1+e2`, in the evidence's order),
    // then what can be concluded (`why:…`). The order the evidence was found
    // in answers nothing: question 3 needs two pieces.
    'type': 'matchPairs',
    'question': 'Link the evidence to each question.',
    'options': [
      {'id': 'q1', 'label': 'What was wrong with the inspection records?'},
      {'id': 'q2', 'label': 'Where did the lift go?'},
      {'id': 'q3', 'label': 'What supports the conclusion that someone entered the service area?'},
      {'id': 'why', 'label': 'What can we conclude?'},
    ],
    'answer': 'q1:e1,q2:e2,q3:e2+e3,why:entered',
    'feedback': {
      'q1:': 'Question 1 is about the inspection records. Which evidence shows them?',
      'q1:e2': 'Question 1 is about the inspection records. Which evidence shows them?',
      'q1:e3': 'Question 1 is about the inspection records. Which evidence shows them?',
      'q1:e2+e3': 'Question 1 is about the inspection records. Which evidence shows them?',
      'q1:e1+e2': 'Question 1 needs one piece of evidence only: the two records.',
      'q1:e1+e3': 'Question 1 needs one piece of evidence only: the two records.',
      'q1:e1+e2+e3': 'Question 1 needs one piece of evidence only: the two records.',
      'q2:': "Where did the lift go? Which evidence shows the lift's trips?",
      'q2:e1': "Where did the lift go? Which evidence shows the lift's trips?",
      'q2:e3': "Where did the lift go? Which evidence shows the lift's trips?",
      'q2:e1+e3': "Where did the lift go? Which evidence shows the lift's trips?",
      'q2:e1+e2': 'Question 2 needs one piece of evidence only: where the lift went.',
      'q2:e2+e3': 'Question 2 needs one piece of evidence only: where the lift went.',
      'q2:e1+e2+e3': 'Question 2 needs one piece of evidence only: where the lift went.',
      'q3:': 'Question 3 needs two pieces of evidence. Where did the lift go, and what was there?',
      'q3:e1': 'The notices were at the entrance. Question 3 is about the service area.',
      'q3:e1+e2': 'The notices were at the entrance. Question 3 is about the service area.',
      'q3:e1+e3': 'The notices were at the entrance. Question 3 is about the service area.',
      'q3:e1+e2+e3': 'The notices were at the entrance. Question 3 is about the service area.',
      'q3:e2': 'The lift log shows where the lift went. What did you find there, behind the door?',
      'q3:e3': 'You found the room. But what shows that someone went up there?',
      'why:': 'Choose what the evidence shows.',
      'why:vanished': 'We have no proof of that yet.',
      'why:still': 'Read the lift log again. The lift went up at 3:20 and came down at 4:25.',
    },
    'hints': [
      'Open each piece of evidence. What does each one show?',
      'Question 3 needs two pieces of evidence: where the lift went, and what was behind the door.',
    ],
    'evidence': {
      'id': 's2_ep03_e4',
      'name': 'The Brass Plaque',
      'icon': 'seal',
      'description': 'Hidden inside the time-recording machine.',
      'inscription': 'ONE HOUR IS MISSING. THE CLOCK IS STILL RUNNING. Under three small waves: SEINE.',
    },
    'successMessage': 'The evidence fits together!',
    // After the case is closed: the post-case scene, then the case report.
    // The plaque is a riddle someone left, never proof that an hour was
    // taken.
    'transition': [
      'One hour is missing.',
      'The clock is still running.',
      'You look beneath the message.',
      'Three small waves are engraved into the brass.',
      'Below them is a single word.',
      'SEINE.',
      'The river that runs through Paris.',
      'Who left this message?',
      'And why does it lead to the river?',
    ],
    'skills': ['problemSolving', 'reading'],
    'mapX': 0.55,
    'mapY': 0.12,
  },
  'glossary': {
    'tower': '탑',
    'iron': '철로 된, 쇠',
    'drawing': '그림, 스케치',
    'canvas': '캔버스(그림 천)',
    'higher': '더 높이',
    'records': '기록들',
    'record': '기록',
    'inspection': '점검',
    'notice': '안내문, 공지',
    'visitor': '방문객',
    'visitors': '방문객들',
    'maintenance': '관리, 정비',
    'log': '기록부, 일지',
    'entrance': '입구',
    'booth': '부스, 작은 칸막이 방',
    'match': '일치하다',
    'line': '줄',
    'lift': '승강기, 엘리베이터',
    'gates': '문들',
    'route': '노선, 경로',
    'plate': '판, 금속판',
    'trip': '운행, 이동',
    'trips': '운행들',
    'passenger': '승객',
    'service': '점검, 관리 업무',
    'level': '층',
    'stop': '정류장, 멈추다',
    'platform': '발판, 승강장',
    'sign': '표지판',
    'access': '출입',
    'padlock': '자물쇠',
    'dials': '다이얼들',
    'note': '메모',
    'steps': '단계들',
    'first': '먼저, 첫째',
    'next': '다음에',
    'finally': '마지막으로',
    'key': '열쇠',
    'hidden': '숨겨진',
    'machine': '기계',
    'cables': '케이블, 줄',
    'gears': '톱니바퀴들',
    'cards': '카드들',
    'official': '공식적인',
    'recorded': '기록된',
    'evidence': '증거',
    'conclude': '결론을 내리다',
    'conclusion': '결론',
    'supports': '뒷받침하다',
    'entered': '들어갔다',
    'proof': '증거, 증명',
    'missing': '없어진',
    'running': '움직이는, 돌아가는',
    'beneath': '~아래에',
    'engraved': '새겨진',
    'brass': '황동, 놋쇠',
    'waves': '물결들',
    'river': '강',
  },
};
