import '../../../models/learning.dart';
import '../season2_case11_scenes.dart';
import 'level_words.dart';

// Case 11 — The Unwritten Hour, at each level (PART 7D): the words only
// (`docs/difficulty_reviews/PARIS_CASE_10_12.md`).
// What Cases 10–12 keep the same, and untold, at every level: ep10_levels.dart.

const words11 = {'ceiling': '천장', 'folder': '서류철', 'anyone': '누구든'};
const juniorWords11 = {'piled': '쌓인', 'charge': '(in charge of) ~을 맡은', 'important': '중요한', 'neither': '둘 다 ~않다'};
const masterWords11 = {
  'initials': '이니셜, 머리글자',
  'responsibility': '책임',
  'deserve': '~을 받을 만하다',
  'buried': '묻었다, 숨겼다',
  'confront': '맞서다, 따져 묻다',
  'expose': '밝혀내다',
  'handless': '바늘 없는',
  'faintly': '희미하게',
};

const _rubbing = 'Page 3 is in Box 9.\nLock it. No one may read it.';
const _victorsPaper = 'CLOCK TEST · V.D.\nAll the clocks were fine.';
const _yourClues = "PAGE 3 · VICTOR'S PAPER · VICTOR'S NAME";
const _stop = 'E.M. said, "Stop!"';
const _keepGoing = 'Victor said, "Keep going."';

const rookie11 = <String, Object?>{'glossary': words11};

final junior11 = <String, Object?>{
  'synopsis': ['The list says page 3 was sent to Saint-Sulpice.', 'Is it really there now?', 'And who hid it?'],
  'objectives': ['Find the missing page 3.', 'Find the paper that is not true.', 'Find out who signed the order.'],
  'intro': [
    'Saint-Sulpice. It is a quiet street.',
    'A small door has a sign: Archive Annex.',
    'Inside, boxes are piled up to the ceiling.',
    'A man is reading some old papers.',
    "Let's look for page 3.",
  ],
  'caseSummary':
      "You found page 3 in Box 9, and it said the clocks were wrong. Victor's paper was not true, and his name was under the order to hide the page. Victor hid the truth.",
  'hook': 'So who left the clues for me?',
  'glossary': {...words11, ...juniorWords11},
  'missions': {
    's2_ep11_m1': {
      'story': ['Page 3 was sent to this place.', 'Every paper here is written down in the big book.'],
      'letterIntro': 'Pressed into a page of the big book:',
      'letter': _rubbing,
      'question': 'Where is page 3? Find it.',
      'hints': ['Rub the empty page with your finger to see the words.', 'Then read the numbers on the boxes.'],
      'successMessage': 'Page 3 was in Box 9!',
      'transition': ['Someone hid page 3 in Box 9.', 'For one hour, the clocks were wrong.', _stop, _keepGoing, "Next, let's read Victor's paper."],
      'clue': {'note': '"Lock it. No one may read it." Under it, there is a name.'},
      'evidence': {'description': 'The missing page, which was found in Box 9.'},
    },
    's2_ep11_m2': {
      'story': ['Victor hands you his paper.', 'But is it true?'],
      'letterIntro': "Victor's paper reads:",
      'letter': _victorsPaper,
      'question': 'Were the clocks right, or wrong?',
      'hints': ['Read page 3 again.', 'Compare the two stamps. Are they the same?'],
      'successMessage': "Victor's paper was not true!",
      'transition': ["Victor's paper did not tell the truth.", 'And his office changed papers as well.', 'So who hid page 3?', 'Remember: there was a name in the big book.'],
      'clue': {'note': 'His office changed papers too.'},
      'evidence': {'description': 'The paper Victor wrote about the clock test.'},
    },
    's2_ep11_m3': {
      'story': ['There was a name pressed into the big book.', 'Today, Victor signed the visitor book.'],
      'letterIntro': 'In the visitor book, you see:',
      'letter': 'There are two names. One of them is the same.',
      'question': 'Which name matches?',
      'hints': ['Compare the V, the line and the dot.', 'Only one name has a long line under it.'],
      'successMessage': "The name is Victor's!",
      'transition': ['Victor was the one who wrote, "Lock it. No one may read it."', 'After that, page 3 was hidden.', "Now it's time to show him the clues."],
      'clue': {'note': 'Victor signed the order that hid page 3.'},
      'evidence': {'description': 'The name that was pressed into the big book.'},
    },
    's2_ep11_final': {
      'story': ['Victor is waiting for you at the long table.', 'Show him what you found.'],
      'letterIntro': 'Your three clues:',
      'letter': _yourClues,
      'question': 'Who really hid the truth?',
      'hints': ['For each question, show him one clue.', 'First page 3, then his paper, then his name.'],
      'successMessage': 'It was Victor who hid the truth!',
      'transition': ['So Victor hid the truth.', 'But then who left the clues for me?', 'Victor said E.M. might know.', 'Next, we will look for E.M. at Arts et Métiers!'],
      'evidence': {'description': 'What Victor told you after you showed him the clues.'},
    },
  },
};

final master11 = <String, Object?>{
  'synopsis': ['According to the list, page 3 was sent to Saint-Sulpice.', 'Is it truly there?', 'And who hid it away?'],
  'objectives': ['Track down page 3.', 'Expose the paper that lies.', 'Discover whose name is signed.'],
  'intro': [
    'Saint-Sulpice, and a quiet old street.',
    'A small door bears a plate: Archive Annex.',
    'Inside, boxes climb all the way to the ceiling.',
    'A man sits reading old papers.',
    'Time to find page 3.',
  ],
  'caseSummary':
      "Page 3 turned up in Box 9, proving the clocks were wrong. Victor's paper was false, and his name sat beneath the order to hide the page. Victor had hidden the truth.",
  'hook': 'Then who left these clues for me?',
  'glossary': {...words11, ...masterWords11},
  'missions': {
    's2_ep11_m1': {
      'story': ['Page 3 was sent here, to the annex.', 'Every paper in this room is listed in the big book.'],
      'letterIntro': 'Pressed faintly into the big book:',
      'letter': _rubbing,
      'question': 'Track down page 3.',
      'hints': ['Rub the blank page: pressed words may appear.', 'Match the box numbers with the words you uncover.'],
      'successMessage': 'Page 3, found at last!',
      'transition': ['Page 3 had been hidden away in Box 9.', 'For a whole hour, the clocks were wrong.', _stop, _keepGoing, "Now for Victor's paper."],
      'clue': {'note': '"Lock it. No one may read it." Beneath it, a name.'},
      'evidence': {'description': 'The missing page, recovered from Box 9.'},
    },
    's2_ep11_m2': {
      'story': ['Victor passes you his report.', 'Can it be trusted?'],
      'letterIntro': "Victor's report states:",
      'letter': _victorsPaper,
      'question': 'Were the clocks really right?',
      'hints': ['Page 3 has something to say about that.', 'Hold the two stamps side by side.'],
      'successMessage': "Victor's report is false!",
      'transition': ["Victor's report was false.", 'His office had changed papers too.', 'Yet who hid page 3?', 'The big book held a name.'],
      'clue': {'note': 'His office had altered papers.'},
      'evidence': {'description': "Victor's report on the clock test."},
    },
    's2_ep11_m3': {
      'story': ['A name was pressed into the big book.', 'And Victor signed the visitor book only today.'],
      'letterIntro': 'The visitor book shows:',
      'letter': 'Two names. Only one matches.',
      'question': 'Find the matching name.',
      'hints': ['A curly V, a line and a dot: compare them carefully.', 'Look for the long line beneath one name.'],
      'successMessage': 'The name belongs to Victor!',
      'transition': ['It was Victor who wrote, "Lock it. No one may read it."', 'And so page 3 was hidden away.', 'Time to confront him.'],
      'clue': {'note': 'Victor put his name to the order hiding page 3.'},
      'evidence': {'description': 'The name left pressed in the big book.'},
    },
    's2_ep11_final': {
      'story': ['Victor waits at the long table.', 'Lay the truth before him.'],
      'letterIntro': 'The clues you carry:',
      'letter': _yourClues,
      'question': 'Who buried the truth?',
      'hints': ['Each question needs its own clue.', 'Begin with page 3, then his paper, and finally his name.'],
      'successMessage': 'Victor had hidden the truth!',
      'transition': ['Victor buried the truth.', 'Yet who left these clues for me?', 'Victor believes E.M. may know.', 'The trail leads to Arts et Métiers, and to E.M.!'],
      'evidence': {'description': 'Victor\'s words, once the clues were laid before him.'},
    },
  },
};

// ═════════════════════════════════════════════════════════════════════════
// The scenes' own words
// ═════════════════════════════════════════════════════════════════════════

const _afraid = 'I was afraid.';
const _peopleToKnow = "I didn't want people to know.";
const _artsEtMetiers = 'His old machine is at Arts et Métiers.';

/// Case 11's scenes with Junior's words.
final juniorScenes11 = (
  talkMissions: {
    's2_ep11_m1': retoldMission(
      season2Case11TalkMissions['s2_ep11_m1']!,
      before: talkWordsOnly('Find the missing page 3.', const [
        'Welcome to the archive annex.',
        'My name is Victor Delacroix.',
        'A long time ago, I was in charge of a clock test.',
        'Victor writes his name in the visitor book.',
        'I need to find page 3.',
        'Page 3?',
        "I don't know where that is.",
        'You could look in the big book, then.',
      ]),
      after: talkWordsOnly('Find the missing page 3.', const [
        'You show page 3 to Victor.',
        'But that box was locked!',
        '…Fine. Yes, there was a page 3.',
        'Who is V.D., then?',
        "V.D.… That's me.",
        'And who is E.M.?',
        'E.M. worked on the test machine.',
        'Here, read my paper.',
      ]),
    ),
    's2_ep11_m2': retoldMission(
      season2Case11TalkMissions['s2_ep11_m2']!,
      before: talkWordsOnly('Find the paper that is not true.', const [
        'This is my paper.',
        'It tells what really happened.',
        'My office has never changed a single paper.',
      ]),
      after: talkWordsOnly('Find the paper that is not true.', const [
        'Fine. My paper was wrong.',
        "But I didn't hide page 3!",
        'Anyone in my office could have done that.',
      ]),
    ),
  },
  talks: {
    's2_ep11_final': retoldTalk(season2Case11Talks['s2_ep11_final']!, (
      goal: 'Show Victor what really happened.',
      opening: const ['Victor sits waiting at the long table.', 'Victor, I have found three clues.', 'Clues? Then show me.'],
      questions: const {
        'bag': ('And what about the office bag?', ['That is one of our office bags.', 'It carried page 3 here.', 'I wanted all the tests to stop.']),
        'clues': ('Then who left all the clues for me?', ['It was not me. I did not change any clocks.', 'Perhaps E.M. knows.', _artsEtMetiers]),
      },
      presents: const {
        'three': ("What happened at three o'clock? Show him.", ['The clocks... went wrong.'], "That doesn't tell us about the clocks.", 'Show Page 3. It says that the clocks were wrong.'),
        'paper': ('Whose paper did not tell the truth? Show him.', ['…It was mine.'], "That paper isn't mine.", "Show Victor's Paper. It said all the clocks were fine."),
        'name': (
          'Who signed the order to hide the page? Show him.',
          ['…It was me.', hidThePage, 'But why?', 'I was in charge of the test.', 'And the clocks went wrong.', _afraid, _peopleToKnow, 'But the truth is important.', 'I know. I am truly sorry.'],
          "There isn't a name on that.",
          "Show Victor's Name. It was pressed into the big book.",
        ),
      },
    )),
  },
  easySteps: {
    's2_ep11_m1': retold(season2Case11Steps['s2_ep11_m1']!, const {
      'book': (say: null, hints: ['The big book lies in the middle.', 'Tap the book.'], feedback: {}, tell: null, done: null),
      'rub': (
        say: 'One page is torn out! Rub the page after it.',
        hints: ['Rub the top part of the right page.', 'Move your finger, or tap it a few times.'],
        feedback: {},
        tell: null,
        done: 'Page 3 is in Box 9! And there is a name.',
      ),
      'box': (
        say: null,
        hints: ['Read the number on each box.', 'Box 9 is the one on the right.'],
        feedback: {'3': 'That one is Box 3. Look for 9.', '12': 'That one is Box 12. Look for 9.'},
        tell: 'Box 9 is the one on the right. Tap it.',
        done: null,
      ),
      'open': (say: 'Box 9 is open now. Tap the folder.', hints: ['Look for the folder inside the box.', 'Tap the folder.'], feedback: {}, tell: null, done: null),
      'page': (say: 'Here is page 3! Read it.', hints: ['It says the clocks were wrong.', 'E.M. said "Stop!" V.D. said "Keep going."'], feedback: {}, tell: null, done: null),
    }),
    's2_ep11_m2': retold(season2Case11Steps['s2_ep11_m2']!, const {
      'clocks': (
        say: null,
        hints: ['Read what page 3 says.', 'Page 3 says: The clocks are wrong!'],
        feedback: {'yes': 'Read page 3 one more time.'},
        tell: 'Page 3 says the clocks were wrong, so tap NO.',
        done: "Victor's paper was not true!",
      ),
      'stamps': (
        say: null,
        hints: ['Look closely at the clock in each stamp.', 'Neither clock has any hands.'],
        feedback: {'no': 'Look again: both show a clock with no hands, in leaves.'},
        tell: 'It is the same stamp, so tap YES.',
        done: "It's the same stamp! His office changed the opera paper.",
      ),
    }),
    's2_ep11_m3': retold(season2Case11Steps['s2_ep11_m3']!, const {
      'names': (say: 'Look at the two names in the visitor book.', hints: ['The book has two names.', 'One was signed by Victor today.'], feedback: {}, tell: null, done: null),
      'match': (
        say: 'Which name matches the big book?',
        hints: ['Compare the V, the line and the dot.', 'Only one name has a long line under it.'],
        feedback: {'old': 'Look again: there is no long line and no dot.'},
        tell: "It has the curly V, the long line and the dot. It is Victor's name!",
        done: "The name is Victor's! He signed it.",
      ),
    }),
  },
);

/// Case 11's scenes with Master's words.
final masterScenes11 = (
  talkMissions: {
    's2_ep11_m1': retoldMission(
      season2Case11TalkMissions['s2_ep11_m1']!,
      before: talkWordsOnly('Track down page 3.', const [
        'Ah, a visitor. Welcome to the archive.',
        'Victor Delacroix, at your service.',
        'Many years ago, I ran a clock test.',
        'Victor signs his name in the visitor book.',
        'I am searching for page 3.',
        'Page 3...?',
        'I have no idea where it might be.',
        'Try the big book, then.',
      ]),
      after: talkWordsOnly('Track down page 3.', const [
        'You lay page 3 before Victor.',
        'That box was supposed to be locked!',
        '…Very well. There was a page 3.',
        'And who is V.D.?',
        'V.D.… Those are my initials.',
        'What about E.M.?',
        'E.M. worked on the machine itself.',
        'Here. Read my own paper.',
      ]),
    ),
    's2_ep11_m2': retoldMission(
      season2Case11TalkMissions['s2_ep11_m2']!,
      before: talkWordsOnly('Expose the paper that lies.', const ['Here is my report.', 'It tells the true story.', 'My office never altered a single paper.']),
      after: talkWordsOnly('Expose the paper that lies.', const ['Very well. My paper was wrong.', 'But I never hid page 3!', 'Anyone in my office could have done it.']),
    ),
  },
  talks: {
    's2_ep11_final': retoldTalk(season2Case11Talks['s2_ep11_final']!, (
      goal: 'Lay the truth before Victor.',
      opening: const ['At the long table, Victor is waiting.', 'Victor, I have three clues for you.', 'Clues? Go on, show me.'],
      questions: const {
        'bag': ('And the bag from your office?', ['That bag belongs to my office.', 'It carried page 3 to this annex.', 'I wanted the tests brought to an end.']),
        'clues': ('Then who has been leaving clues for me?', ['Not I. I never touched a clock.', 'E.M. may have the answer.', _artsEtMetiers]),
      },
      presents: const {
        'three': ('What happened at three? Show him the proof.', ['The clocks were wrong. Yes.'], 'That says nothing about the clocks.', 'Show Page 3: it records the clocks going wrong.'),
        'paper': ('Whose paper was false? Show him.', ['…My own.'], 'That paper did not come from me.', "Show Victor's Paper: it claimed the clocks were fine."),
        'name': (
          'Whose name is on the order to hide it? Show him.',
          [
            '…I signed it.',
            hidThePage,
            'Why would you do that?',
            'The test was my responsibility.',
            'And it failed: the clocks went wrong.',
            _afraid,
            _peopleToKnow,
            'But people deserve the truth.',
            'I know. I am deeply sorry.',
          ],
          'No name appears on that.',
          "Show Victor's Name, from the big book.",
        ),
      },
    )),
  },
  easySteps: {
    's2_ep11_m1': retold(season2Case11Steps['s2_ep11_m1']!, const {
      'book': (say: null, hints: ['Look to the middle of the table.', 'Tap the book.'], feedback: {}, tell: null, done: null),
      'rub': (
        say: 'A page has been torn out! Rub the one beneath it.',
        hints: ['The words wait at the top of the right page.', 'Move your finger, or tap it a few times.'],
        feedback: {},
        tell: null,
        done: 'Page 3 is in Box 9, and a name appears!',
      ),
      'box': (
        say: null,
        hints: ['Each box wears a number.', 'Box 9 sits on the right.'],
        feedback: {'3': 'Box 3. You want 9.', '12': 'Box 12. You want 9.'},
        tell: 'It is the box on the right. Tap it.',
        done: null,
      ),
      'open': (say: 'Box 9 stands open. Tap the folder.', hints: ['A folder lies inside.', 'Tap the folder.'], feedback: {}, tell: null, done: null),
      'page': (say: 'Page 3 at last! Read it.', hints: ['Read the first line: the clocks.', 'E.M. said "Stop!" V.D. said "Keep going."'], feedback: {}, tell: null, done: null),
    }),
    's2_ep11_m2': retold(season2Case11Steps['s2_ep11_m2']!, const {
      'clocks': (
        say: null,
        hints: ['Page 3 has something to say about that.', 'Page 3 says: The clocks are wrong!'],
        feedback: {'yes': 'Page 3 says otherwise.'},
        tell: 'Page 3 tells us the clocks were wrong. Tap NO.',
        done: "Victor's report is false!",
      ),
      'stamps': (
        say: null,
        hints: ['Compare the little clocks inside the stamps.', 'Neither clock has hands.'],
        feedback: {'no': 'Look again. Each has a handless clock in a ring of leaves.'},
        tell: 'The stamps match. Tap YES.',
        done: 'The very same stamp! His office altered the opera paper.',
      ),
    }),
    's2_ep11_m3': retold(season2Case11Steps['s2_ep11_m3']!, const {
      'names': (say: 'Study the names in the visitor book.', hints: ['Two names share the page.', 'Victor signed it only today.'], feedback: {}, tell: null, done: null),
      'match': (
        say: 'Which signature matches the rubbing?',
        hints: ['A curly V, a line and a dot: compare them carefully.', 'Look for the long line beneath one name.'],
        feedback: {'old': 'No long line and no dot: not a match.'},
        tell: "Curly V, long line, dot: the name is Victor's!",
        done: 'The name belongs to Victor. He signed the order.',
      ),
    }),
  },
);

// ═════════════════════════════════════════════════════════════════════════
// The learning design
// ═════════════════════════════════════════════════════════════════════════

final juniorLearning11 = <String, LearningObjective>{
  's2_ep11_m1': levelObjective('s2_ep11_m1', ['Page 3 is in Box 9.', 'Where is page 3?']),
  's2_ep11_m2': levelObjective('s2_ep11_m2', ['Were the clocks right, or wrong?']),
  's2_ep11_m3': levelObjective('s2_ep11_m3', ['Which name matches?']),
  's2_ep11_final': levelObjective('s2_ep11_final', ['Who really hid the truth?']),
};

final masterLearning11 = <String, LearningObjective>{
  's2_ep11_m1': levelObjective('s2_ep11_m1', ['Page 3 is in Box 9.', 'Track down page 3']),
  's2_ep11_m2': levelObjective('s2_ep11_m2', ['Were the clocks really right?']),
  's2_ep11_m3': levelObjective('s2_ep11_m3', ['Find the matching name']),
  's2_ep11_final': levelObjective('s2_ep11_final', ['Who buried the truth?']),
};
