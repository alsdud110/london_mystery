import '../../../models/case_talk.dart';
import '../../../models/learning.dart';
import '../season2_case12_scenes.dart';
import 'level_words.dart';

// Case 12 — The Clockmaker's Truth, at each level (PART 7D): the words only
// (`docs/difficulty_reviews/PARIS_CASE_10_12.md`).
// What Cases 10–12 keep the same, and untold, at every level: ep10_levels.dart.

const words12 = {'workbench': '작업대', 'confused': '혼란스러운', 'choices': '선택들', 'button': '버튼'};
const juniorWords12 = {'stamping': '도장을 찍는', 'discover': '찾아내다', 'engraved': '새겨진', 'ticking': '똑딱거리는'};
const masterWords12 = {
  'unmask': '정체를 밝히다',
  'frightened': '겁을 주었다',
  'regret': '후회하다',
  'admitted': '인정했다',
  'erred': '틀렸다',
  'halt': '멈춤',
  'grateful': '고마운',
  'meanwhile': '그동안에',
  'hushed': '조용한',
};

const _tag = 'Made by Émile Moreau';
const _tagLine = 'The tag says: Made by Émile Moreau.';
const _card = 'HOW TO FIX THE MACHINE\n1. Stop. 2. Turn. 3. Fix. 4. Start.';
const _cardSteps = 'Stop, turn, fix, start.';
const _loseAnHour = 'Did Paris lose an hour?';
const _neverGone = 'The hour was never gone.';

const rookie12 = <String, Object?>{'glossary': words12};

final junior12 = <String, Object?>{
  'synopsis': ["E.M.'s old machine is kept here.", 'But who left the clues?'],
  'objectives': ['Find out his full name.', 'Find out who the Clockmaker is.', 'Make the old machine work right.'],
  'intro': [
    'Arts et Métiers. It is a museum full of old machines.',
    'In a quiet room, a big machine is ticking.',
    'Look: its three little clocks are one hour behind!',
    'Someone is standing next to the machine.',
  ],
  'caseSummary':
      "You found Émile's name on an old wheel. The same wheel was inside the Clockmaker's watch, and Émile's tool made the Clockmaker's mark. So Émile was the Clockmaker. He left clues so the truth would be found, but he scared people. You fixed the machine and closed the case.",
  'hook': _neverGone,
  'glossary': {...words12, ...juniorWords12},
  'missions': {
    's2_ep12_m1': {
      'story': ['There is a little door in the machine.', 'Behind it are some wheels.'],
      'letterIntro': 'There is a little tag:',
      'letter': _tag,
      'question': "Which wheel is the same as Clock III's?",
      'hints': ['Count the spokes on each wheel.', 'Check the size as well.'],
      'successMessage': 'E.M. stands for Émile Moreau!',
      'transition': [_tagLine, 'So E.M. is Émile Moreau!', 'He also made the same wheel for Clock III.', 'But who is the Clockmaker, then?'],
      'clue': {'note': 'He made the small wheel in Clock III.'},
      'evidence': {'description': 'A tag tied to a wheel inside the old machine.'},
    },
    's2_ep12_m2': {
      'story': ["You still have the Clockmaker's pocket watch.", 'You found it back in London.'],
      'letterIntro': 'Engraved on the back of the watch:',
      'letter': 'PARIS',
      'question': 'So who is the Clockmaker?',
      'hints': ['First open the watch. Then try the stamp.', 'Compare the two marks. Are they the same?'],
      'successMessage': 'Émile Moreau is the Clockmaker!',
      'transition': ['So Émile is the Clockmaker.', 'He wanted people to discover page 3.', 'But he scared people, and that was wrong.', 'And the old machine is still not right.'],
      'clue': {'note': 'The wheel, the watch and the mark all lead to one man.'},
      'evidence': {'description': "Émile's stamping tool, and the watch from London."},
    },
    's2_ep12_m3': {
      'story': ['The old machine is still not right.', 'Its three clocks are one hour behind.'],
      'letterIntro': 'There is a card on the machine:',
      'letter': _card,
      'question': 'Fix the old machine, step by step.',
      'hints': ['Follow the steps in order.', _cardSteps],
      'successMessage': 'The machine is fixed!',
      'transition': ['At last, the old machine is right.', 'All of its clocks agree now.', "Now let's put the whole case together."],
      'clue': {'note': 'Only this one machine was fixed.'},
      'evidence': {'description': 'The old test machine, finally fixed.'},
    },
    's2_ep12_final': {
      'story': ['There are six questions. Answer them one at a time.', 'Your clues will help you.'],
      'letterIntro': 'The case board asks:',
      'letter': _loseAnHour,
      'question': _loseAnHour,
      'hints': ['Each question comes with a clue. Look at it.', 'The clocks were wrong, but the hour was there.'],
      'successMessage': 'You solved the whole case!',
      'transition': [_neverGone, 'The truth was just waiting for someone to find it.'],
      'evidence': {'description': 'The whole case, told in four lines.'},
    },
  },
};

final master12 = <String, Object?>{
  'synopsis': ["E.M.'s old machine waits here.", 'And who has been leaving the clues?'],
  'objectives': ['Uncover his name.', 'Unmask the Clockmaker.', 'Repair the old machine.'],
  'intro': [
    'Arts et Métiers, a museum of old machines.',
    'In a hushed room, a great machine ticks on.',
    'All three of its little clocks are an hour behind!',
    'Someone stands beside the machine.',
  ],
  'caseSummary':
      "Émile's name was on an old wheel. That same wheel sat inside the Clockmaker's watch, and Émile's tool made the Clockmaker's mark: Émile was the Clockmaker. He left clues so the truth would come out, but he frightened people along the way. You repaired the machine and closed the case.",
  'hook': _neverGone,
  'glossary': {...words12, ...masterWords12},
  'missions': {
    's2_ep12_m1': {
      'story': ['A little door is set into the machine.', 'Brass wheels wait inside.'],
      'letterIntro': 'A little tag reads:',
      'letter': _tag,
      'question': "Find the wheel that matches Clock III's.",
      'hints': ['The spokes tell wheels apart.', 'Size matters too.'],
      'successMessage': 'E.M. means Émile Moreau!',
      'transition': [_tagLine, 'E.M. was Émile Moreau all along!', 'He made the very same wheel for Clock III.', 'Yet who is the Clockmaker?'],
      'clue': {'note': 'The small wheel in Clock III is his work.'},
      'evidence': {'description': 'A tag fixed to a wheel within the old machine.'},
    },
    's2_ep12_m2': {
      'story': ["The Clockmaker's watch is still in your pocket.", 'It has been with you since London.'],
      'letterIntro': "On the watch's back, one word:",
      'letter': 'PARIS',
      'question': 'Who, then, is the Clockmaker?',
      'hints': ['Look inside the watch, then use the stamp.', 'Do the two marks agree?'],
      'successMessage': 'The Clockmaker is Émile!',
      'transition': ['Émile and the Clockmaker are one and the same.', 'He wanted page 3 to be found.', 'But he frightened people, and that was wrong.', 'Meanwhile, the old machine is still wrong.'],
      'clue': {'note': 'Wheel, watch and mark all point to a single man.'},
      'evidence': {'description': "Émile's tool, beside the watch from London."},
    },
    's2_ep12_m3': {
      'story': ['The old machine still runs wrong.', 'All its clocks lag an hour behind.'],
      'letterIntro': 'A card is fixed to the machine:',
      'letter': _card,
      'question': 'Repair the old machine.',
      'hints': ['The card lists four steps. Follow them in order.', _cardSteps],
      'successMessage': 'The machine runs true again!',
      'transition': ['At long last, the old machine keeps true time.', 'Every one of its clocks agrees.', 'Time to piece the whole case together.'],
      'clue': {'note': 'This machine alone was put right.'},
      'evidence': {'description': 'The old test machine, set right at last.'},
    },
    's2_ep12_final': {
      'story': ['Six questions await, one at a time.', 'Let your clues guide you.'],
      'letterIntro': 'The case board begins:',
      'letter': _loseAnHour,
      'question': _loseAnHour,
      'hints': ['Read each clue before you answer.', 'The clocks erred; the hour itself was never lost.'],
      'successMessage': 'The case is solved at last!',
      'transition': [_neverGone, 'All along, the truth was waiting to be found.'],
      'evidence': {'description': 'The entire case, in four lines.'},
    },
  },
};

// ═════════════════════════════════════════════════════════════════════════
// The scenes' own words
// ═════════════════════════════════════════════════════════════════════════

/// The case's ending at a level: each line said in its words, by the same
/// voice, name, face and place.
List<EndingLine> _ending(List<EndingLine> base, List<String> texts) => [
      for (final (i, l) in base.indexed)
        EndingLine(texts[i], voice: l.voice, name: l.name, portrait: l.portrait, background: l.background, evidenceId: l.evidenceId),
    ];

// Big Ben's box, as the story bible tells it to a child (v2.0).
const _boxUnder = 'A secret box is under it.';
const _hiddenPapers = 'Inside is a list of hidden papers.';
const _opensOnly = 'It opens only if Big Ben stops.';
const _stopTheTest = 'You said, "Stop the test!"';

// The case file's own lines, said again at the end.
const _clocksWrong = 'The clocks were wrong.';
const _victorHid = 'Victor hid the truth.';
const _emileLeft = 'Émile left the clues.';

/// Case 12's scenes with Junior's words.
final juniorScenes12 = (
  talkMissions: {
    's2_ep12_m1': retoldMission(
      season2Case12TalkMissions['s2_ep12_m1']!,
      before: talkWordsOnly('Who is this man?', const ['Someone is in here.', 'So, you found me.', 'Who are you?', "Don't ask me that.", 'Use the clues to find out.']),
      after: talkWordsOnly('Who is this man?', const ['Émile made this wheel!', 'Émile Moreau… so he is E.M.!', 'You are getting closer.']),
    ),
    's2_ep12_m2': retoldMission(
      season2Case12TalkMissions['s2_ep12_m2']!,
      before: talkWordsOnly('Find out who the Clockmaker is.', const [
        'The man turns around.',
        'Hello there, detective.',
        "You still have the Clockmaker's watch.",
        'Go on, open it.',
        "Don't trust what I say. Trust the clues.",
      ]),
      after: (
        goal: 'Find out why he left the clues.',
        opening: const [
          'You made this wheel.',
          'Yes. I made it.',
          "And it is inside the Clockmaker's watch.",
          'That is right.',
          'And your stamp makes his mark.',
          'So you found it.',
        ],
        questions: const {
          'clockmaker': ('So are you the Clockmaker?', ['Yes. I am the Clockmaker.', 'My name is Émile Moreau.', _stopTheTest, 'I did. But nobody listened.']),
          'why': ('Why did you do all of this?', ['I wanted people to start looking.', 'Looking for what?', 'For the missing page.', 'But you scared people.', 'I know. I was wrong.']),
          'bigBen': ('And what about Big Ben?', ['I tried to make Big Ben stop.', _boxUnder, _hiddenPapers, _opensOnly, 'But I stopped your plan.', 'Yes. The box never opened.']),
          'clues': (
            'Why did you leave the clues for me?',
            ['You stopped me by using clues.', 'People believe clues.', 'I hoped you would find the page.', 'But I also set clocks wrong here in Paris.', 'People were confused, and that was wrong.'],
          ),
        },
        presents: const {},
      ),
    ),
    's2_ep12_m3': retoldMission(
      season2Case12TalkMissions['s2_ep12_m3']!,
      before: talkWordsOnly('Make the old machine right again.', const [
        'Why is the machine still not right?',
        'On the day of the test, I stopped it.',
        'After that, Victor stopped all the tests.',
        'So nobody ever fixed the machine.',
        'Can I fix it now?',
        'Yes. $_cardSteps',
      ]),
      after: talkWordsOnly('Make the old machine right again.', const ['At last, it is right.', 'Thank you, detective.']),
    ),
  },
  endings: {
    's2_ep12_final': _ending(season2Case12Ending, const [
      "Victor's words are kept in the case file.",
      hidThePage,
      'And I made bad choices too.',
      "I scared people, and I'm sorry.",
      'I will tell everyone the truth about what I did.',
      _clocksWrong,
      _victorHid,
      _emileLeft,
      'But now everyone can know the truth.',
      'Page 3 is placed in a glass case.',
      'Nobody can ever hide it again.',
    ]),
  },
  easySteps: {
    's2_ep12_m1': retold(season2Case12Steps['s2_ep12_m1']!, const {
      'wheel': (
        say: 'Look at this wheel. Which one is the same?',
        hints: ['Count the spokes on each wheel.', "Clock III's wheel has 4 spokes that make an X."],
        feedback: {'six': 'Count the spokes. Wheel A has six.'},
        tell: 'Wheel B has 4 spokes, like an X. Tap Wheel B.',
        done: "It's the same wheel! There is a tag on it.",
      ),
      'tag': (say: 'This wheel was made by Émile Moreau!', hints: ['Read what the tag says.', 'E.M. stands for Émile Moreau.'], feedback: {}, tell: null, done: null),
    }),
    's2_ep12_m2': retold(season2Case12Steps['s2_ep12_m2']!, const {
      'open': (say: null, hints: ['Tap the pocket watch.', 'You can tap anywhere on the watch.'], feedback: {}, tell: null, done: null),
      'wheel': (
        say: null,
        hints: ['Look for a wheel with 4 spokes, like an X.', 'It is on the right side, inside the watch.'],
        feedback: {},
        tell: null,
        done: 'Look! It is the same wheel! But anyone could use a wheel like this.',
      ),
      'stamp': (say: null, hints: ["This is Émile's little stamp.", 'Tap the stamp to make a mark.'], feedback: {}, tell: null, done: 'It made a mark! Look at it.'),
      'marks': (
        say: null,
        hints: ['Count the teeth on both gears.', 'Each gear has 8 teeth.'],
        feedback: {'no': 'Count the teeth on each gear again.'},
        tell: 'Both gears have 8 teeth, so they are the same. Tap YES.',
        done: 'It is the same mark, with eight teeth!',
      ),
      'who': (
        say: 'Look at all three of your clues.',
        hints: ['Think: whose stamp made the mark?', 'Émile made both the wheel and the stamp.'],
        feedback: {'victor': 'Think: whose stamp made the mark?'},
        tell: "Émile's stamp makes the Clockmaker's mark, so tap Émile.",
        done: 'Émile Moreau is the Clockmaker!',
      ),
    }),
    's2_ep12_m3': retold(season2Case12Steps['s2_ep12_m3']!, const {
      'stop': (say: null, hints: ['Step 1 is to stop the machine.', 'Press the big STOP button.'], feedback: {}, tell: null, done: null),
      'turn': (say: null, hints: ['Step 2 is to turn the wheel.', 'The big wheel is at the top of the machine.'], feedback: {}, tell: null, done: null),
      'pin': (say: 'Now the clocks say 11:20! Tap the pin.', hints: ['Step 3: the pin keeps the wheel in place.', 'The pin is on the left of the wheel.'], feedback: {}, tell: null, done: null),
      'start': (
        say: null,
        hints: ['Step 4 is to start the machine again.', 'Press the big START button.'],
        feedback: {},
        tell: null,
        done: 'Every clock agrees now! The machine is fixed!',
      ),
    }),
    's2_ep12_final': retold(season2Case12Steps['s2_ep12_final']!, const {
      'q1': (
        say: null,
        hints: ['The sun showed that the hour passed.', 'The hour was there; only the clocks were wrong.'],
        feedback: {'yes': 'Think about the sun. Did it lose an hour?'},
        tell: 'The hour was really there. Tap NO.',
        done: 'No. Only the clocks were wrong.',
      ),
      'q2': (
        say: null,
        hints: ['Read what page 3 says.', 'Page 3 says: The clocks are wrong!'],
        feedback: {'no': 'Read the first line of page 3 again.'},
        tell: 'Page 3 says the clocks are wrong, so tap YES.',
        done: 'Yes. Page 3 says so in writing.',
      ),
      'q3': (
        say: null,
        hints: ['Think: whose name was in the big book?', 'It matched the name in the visitor book.'],
        feedback: {'emile': 'Think: whose name was in the big book?'},
        tell: "The name is Victor's. Tap Victor.",
        done: 'Victor was the one who hid it.',
      ),
      'q4': (
        say: null,
        hints: ['Think: whose stamp made the mark?', "It was made by Émile's stamp."],
        feedback: {'victor': 'Think: whose stamp made the mark?'},
        tell: "The mark was made by Émile's stamp. Tap Émile.",
        done: 'So Émile is the Clockmaker.',
      ),
      'q5': (
        say: null,
        hints: ["Read Émile's words again.", 'He hoped people would find page 3.'],
        feedback: {'hide': 'No. He wanted people to find the page.'},
        tell: 'He wanted people to find the page. Tap: To show the truth.',
        done: 'He left clues to show the truth.',
      ),
      'q6': (
        say: null,
        hints: ["Read Émile's words again.", 'He said that he was wrong.'],
        feedback: {'yes': 'Having a good reason does not make it OK.'},
        tell: 'Émile said himself that he was wrong. Tap NO.',
        done: 'No. Those were bad choices.',
      ),
    }),
  },
);

/// Case 12's scenes with Master's words.
final masterScenes12 = (
  talkMissions: {
    's2_ep12_m1': retoldMission(
      season2Case12TalkMissions['s2_ep12_m1']!,
      before: talkWordsOnly('Who is the stranger?', const ['There is someone here.', 'Ah. You have found me.', 'Who are you?', 'My words will not help you.', 'Let the clues tell you.']),
      after: talkWordsOnly('Who is the stranger?', const ["This wheel is Émile's work!", 'Émile Moreau… E.M.!', 'You are close now. Very close.']),
    ),
    's2_ep12_m2': retoldMission(
      season2Case12TalkMissions['s2_ep12_m2']!,
      before: talkWordsOnly('Unmask the Clockmaker.', const [
        'Slowly, he turns to face you.',
        'Good day, detective.',
        "I see you carry the Clockmaker's watch.",
        'Open it.',
        'Do not trust my words. Trust the clues.',
      ]),
      after: (
        goal: 'Learn why he left the clues.',
        opening: const [
          'This wheel is your work.',
          'It is.',
          "And it sits inside the Clockmaker's watch.",
          'Correct.',
          'And your stamp makes his mark.',
          'You have found it, then.',
        ],
        questions: const {
          'clockmaker': (
            'Is it you? Are you the Clockmaker?',
            ['Yes. I am.', 'I am Émile Moreau, the Clockmaker.', 'You were the one who said, "Stop the test!"', 'I did. No one would listen.'],
          ),
          'why': ('What made you do it?', ['I wanted people to search.', 'Search for what?', 'For the page that went missing.', 'But you frightened people.', 'I know. I was wrong to do that.']),
          'bigBen': (
            'And Big Ben? What was that for?',
            ['I tried to bring Big Ben to a halt.', _boxUnder, _hiddenPapers, _opensOnly, 'But I stopped you in London.', 'You did. The box stayed shut.'],
          ),
          'clues': (
            'Why leave the clues for me?',
            ['You stopped me with clues alone.', 'People trust clues more than words.', 'I hoped you would find the page.', 'But I set clocks wrong here in Paris, too.', 'I confused people. That was wrong.'],
          ),
        },
        presents: const {},
      ),
    ),
    's2_ep12_m3': retoldMission(
      season2Case12TalkMissions['s2_ep12_m3']!,
      before: talkWordsOnly('Repair the old machine.', const [
        'Why does the machine still run wrong?',
        'On the day of the test, I brought it to a stop.',
        'Then Victor ended every test.',
        'No one ever repaired it.',
        'Could I fix it?',
        'You could. $_cardSteps',
      ]),
      after: talkWordsOnly('Repair the old machine.', const ['At long last, it keeps true time.', 'I am grateful, detective.']),
    ),
  },
  endings: {
    's2_ep12_final': _ending(season2Case12Ending, const [
      "Victor's own words now rest in the case file.",
      hidThePage,
      'And I made choices I regret.',
      'I frightened people. I am sorry for that.',
      'I will tell everyone what I have done.',
      _clocksWrong,
      _victorHid,
      _emileLeft,
      'But now the whole city can know.',
      'Page 3 is laid in a glass case.',
      'No one will ever hide it again.',
    ]),
  },
  easySteps: {
    's2_ep12_m1': retold(season2Case12Steps['s2_ep12_m1']!, const {
      'wheel': (
        say: 'Study this wheel. Which one matches it?',
        hints: ['The spokes tell wheels apart.', "Clock III's wheel has four spokes, crossed like an X."],
        feedback: {'six': 'Wheel A has six spokes. Count again.'},
        tell: 'Wheel B has four spokes in an X. Tap B.',
        done: 'A perfect match, and a tag hangs from it.',
      ),
      'tag': (say: 'The maker of this wheel: Émile Moreau!', hints: ['The tag names the maker.', 'E.M. means Émile Moreau.'], feedback: {}, tell: null, done: null),
    }),
    's2_ep12_m2': retold(season2Case12Steps['s2_ep12_m2']!, const {
      'open': (say: null, hints: ['Open it with a tap.', 'Tap anywhere on the watch.'], feedback: {}, tell: null, done: null),
      'wheel': (
        say: null,
        hints: ['Search for four spokes crossed like an X.', 'It sits on the right, inside the watch.'],
        feedback: {},
        tell: null,
        done: 'The same wheel! Still, anyone might use such a wheel.',
      ),
      'stamp': (say: null, hints: ["Émile's little stamp waits beside the paper.", 'Tap the stamp. It makes a mark.'], feedback: {}, tell: null, done: 'A mark appears. Examine it.'),
      'marks': (
        say: null,
        hints: ['The teeth will tell you.', 'Each gear has eight teeth.'],
        feedback: {'no': 'Count the teeth of each gear once more.'},
        tell: 'Eight teeth each: the marks match. Tap YES.',
        done: 'An identical mark, eight teeth and all.',
      ),
      'who': (
        say: 'Consider your three clues.',
        hints: ['Whose stamp left that mark?', "The wheel and the stamp are both Émile's."],
        feedback: {'victor': 'Whose stamp left that mark?'},
        tell: "The Clockmaker's mark comes from Émile's stamp. Tap Émile.",
        done: 'The Clockmaker is Émile!',
      ),
    }),
    's2_ep12_m3': retold(season2Case12Steps['s2_ep12_m3']!, const {
      'stop': (say: null, hints: ['First, the machine must stop.', 'Press the big STOP button.'], feedback: {}, tell: null, done: null),
      'turn': (say: null, hints: ['Next, the wheel must turn.', 'The big wheel sits at the top.'], feedback: {}, tell: null, done: null),
      'pin': (say: 'The clocks read 11:20! Now tap the pin.', hints: ['Third, the pin locks the wheel in place.', 'Look just left of the wheel.'], feedback: {}, tell: null, done: null),
      'start': (
        say: null,
        hints: ['Finally, set the machine running.', 'Press the big START button.'],
        feedback: {},
        tell: null,
        done: 'Every clock agrees! The machine runs true again!',
      ),
    }),
    's2_ep12_final': retold(season2Case12Steps['s2_ep12_final']!, const {
      'q1': (
        say: null,
        hints: ['The sun kept the hour.', 'The hour passed; the clocks simply showed it wrong.'],
        feedback: {'yes': 'The sun lost no hour. Did Paris?'},
        tell: 'No hour was lost. Tap NO.',
        done: 'No. It was the clocks that were wrong.',
      ),
      'q2': (
        say: null,
        hints: ['Page 3 holds the answer.', 'Page 3 says: The clocks are wrong!'],
        feedback: {'no': 'Page 3 begins with the answer.'},
        tell: 'Page 3 records that the clocks were wrong. Tap YES.',
        done: 'Yes. Page 3 proves it.',
      ),
      'q3': (
        say: null,
        hints: ['Remember the name in the big book.', 'It matched a signature in the visitor book.'],
        feedback: {'emile': 'Remember the name in the big book.'},
        tell: 'The name belonged to Victor. Tap Victor.',
        done: 'Victor hid it away.',
      ),
      'q4': (
        say: null,
        hints: ['Whose stamp left that mark?', "The mark came from Émile's stamp."],
        feedback: {'victor': 'Whose stamp left that mark?'},
        tell: "Émile's stamp left the mark. Tap Émile.",
        done: 'Émile was the Clockmaker.',
      ),
      'q5': (
        say: null,
        hints: ["Émile's own words hold the answer.", 'He wanted page 3 to be found.'],
        feedback: {'hide': 'He hoped the page would be found, not hidden.'},
        tell: 'He wanted page 3 found. Tap: To show the truth.',
        done: 'His clues were meant to reveal the truth.',
      ),
      'q6': (
        say: null,
        hints: ["Émile's own words hold the answer.", 'He admitted: I was wrong.'],
        feedback: {'yes': 'Even a good reason cannot make that right.'},
        tell: 'Émile admitted he was wrong. Tap NO.',
        done: 'No. His choices were wrong.',
      ),
    }),
  },
);

// ═════════════════════════════════════════════════════════════════════════
// The learning design
// ═════════════════════════════════════════════════════════════════════════

final juniorLearning12 = <String, LearningObjective>{
  's2_ep12_m1': levelObjective('s2_ep12_m1', ["Which wheel is the same as Clock III's?"]),
  's2_ep12_m2': levelObjective('s2_ep12_m2', ['So who is the Clockmaker?']),
  's2_ep12_m3': levelObjective('s2_ep12_m3', ['Fix the old machine, step by step']),
  's2_ep12_final': levelObjective('s2_ep12_final', [_loseAnHour, 'the hour was there']),
};

final masterLearning12 = <String, LearningObjective>{
  's2_ep12_m1': levelObjective('s2_ep12_m1', ["Find the wheel that matches Clock III's"]),
  's2_ep12_m2': levelObjective('s2_ep12_m2', ['Who, then, is the Clockmaker?']),
  's2_ep12_m3': levelObjective('s2_ep12_m3', ['Repair the old machine']),
  's2_ep12_final': levelObjective('s2_ep12_final', [_loseAnHour, 'the hour itself was never lost']),
};
