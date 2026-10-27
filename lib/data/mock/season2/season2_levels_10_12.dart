import '../../models/case_talk.dart';
import '../../models/learning.dart';
import '../../models/star_puzzles.dart';
import 'season2_case10_scenes.dart';
import 'season2_case11_scenes.dart';
import 'season2_case12_scenes.dart';
import 'season2_learning.dart';
import 'season2_levels_04_06.dart' show retold;

/// Season 2, Cases 10–12 at each level (PART 7D): the words only
/// (`docs/difficulty_reviews/PARIS_CASE_10_12.md`).
///
/// Rookie: the game's own words (written for 8–12 year olds, v2.0),
/// reviewed and kept; the words a child may not know added to the glossary.
///
/// At every level the same: the papers each puzzle is read from (T1's tape
/// head, the back of Photo 2, the sundial's words, the photos' times, the
/// Trial Log's pages and record list, the rubbing, page 3, Victor's paper,
/// the name tag, PARIS, the machine's card, the case board's questions),
/// what the evidence quotes (Victor's "Yes. I hid the page.", "I was
/// afraid.", "I didn't want people to know."; the case file's lines), the
/// story bible's own lines (Big Ben's box: "A secret box is under it.",
/// "Inside is a list of hidden papers.", "It opens only if Big Ben
/// stops."; "His old machine is at Arts et Métiers."), the lines earlier
/// cases are quoted by ("The Clockmaker steals an hour.", "The clocks may
/// lie.", the Eiffel Tower's plaque), every answer, id and order, every
/// beat's number of lines, voices and moods, and every way to play.
///
/// Told at the same moment at every level: that T1 was wrong (Case 10's
/// final), where page 3 was sent, who V.D. is (Case 11 M1, after the box),
/// that Victor hid it (Case 11), E.M.'s name (Case 12 M1), who the
/// Clockmaker is (Case 12 M2), why, and what he did wrong.

// ═════════════════════════════════════════════════════════════════════════
// The glossary
// ═════════════════════════════════════════════════════════════════════════

const words10 = {'twelve': '열둘, 12', 'passed': '지나갔다', 'recorded': '기록했다', 'longer': '더 긴', 'shorter': '더 짧은'};
const juniorWords10 = {'magnifying': '확대하는 (magnifying glass: 돋보기)', 'simply': '그저, 단순히'};
const masterWords10 = {
  'stamped': '찍었다',
  'separate': '사이를 두다',
  'reverse': '뒷면',
  'captures': '담아내다',
  'lags': '뒤처지다',
  'stretch': '늘어나다',
  'rooftop': '옥상의',
  'stairway': '계단',
  'measure': '재다',
};

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

// ═════════════════════════════════════════════════════════════════════════
// Case 10 — The Hour of Shadows
// ═════════════════════════════════════════════════════════════════════════

const _lostOrWrong = 'Was the hour lost — or was the clock wrong?';
const _steals = 'At Gare du Nord we read: The Clockmaker steals an hour.';
const _clocksMayLie = 'The letter at the Louvre said: The clocks may lie.';
const _plaque = 'At the Eiffel Tower, a time-recording machine hid a plaque: ONE HOUR IS MISSING. THE CLOCK IS STILL RUNNING.';
const _sameShadow = 'Move the sun. Make the same shadow as in the photo.';
const _photos = 'PHOTO 1 · T1 2:00 · SUN 2:00\nPHOTO 2 · T1 2:30 · SUN 3:30';

final junior10 = <String, Object?>{
  'synopsis': ['The star under T1 led you to the Arc de Triomphe.', 'The records of the trial may be kept there.', _lostOrWrong],
  'objectives': ['Read the times that T1 printed.', 'Compare T1 with the other clocks.', 'Check the time with the sun.'],
  'intro': [
    'The Arc de Triomphe. Twelve roads meet around it, like the points of a star.',
    "T1's little model clock stood on top of an arch, with a star under it.",
    'You climb all the stairs to the top.',
    'Under the roof, there is a small door with a star on it.',
    'Inside are a brass drum, a box of photos and a thick book.',
    'A brass plate on the wall says: TRIAL RECORDS · KEPT AT THE STAR.',
    'In the garden, we tested a model. These records come from the real trial.',
    "Let's read what T1 printed.",
  ],
  'caseSummary':
      'The hour really passed: the sun and the café, church and post office clocks prove it. T1 was one hour behind, and page 3 is missing. The list says it was sent to Saint-Sulpice.',
  'hook': 'Who sent page 3 away? And why?',
  'glossary': {...words10, ...juniorWords10},
  'missions': {
    's2_ep10_m1': {
      'story': ['Inside the drum is a paper tape.', 'Every fifteen minutes, T1 printed its time on it.'],
      'letterIntro': 'At the top of the tape:',
      'letter': 'T1 · DRUM TAPE · TRIAL DAY',
      'question': 'Find the two places where the time jumps. Tap them.',
      'hints': ['Every time should be fifteen minutes after the one before it.', 'Check what comes right after each 2:45.'],
      'successMessage': 'You found both jumps!',
      'transition': [
        'After 2:45, the tape goes back to 2:00. Later it jumps to 4:00.',
        "The tape never shows three o'clock.",
        _steals,
        'So was an hour stolen, or was T1 wrong?',
        "Let's find out what the other clocks said.",
      ],
      'clue': {'note': "Three o'clock is never printed on T1's tape."},
      'evidence': {'description': 'The paper tape from the drum that sat under T1.'},
    },
    's2_ep10_m2': {
      'story': ['A box says ROOF PHOTOS · TRIAL DAY. Inside are two old photos.', 'Photo 2 shows T1 on the roof, with the city behind it.'],
      'letterIntro': 'Written on the back of Photo 2:',
      'letter': 'T1 · ROOF · PHOTO 2',
      'question': 'Find the clocks in the photo. Is each one a trial clock?',
      'hints': ['Move the magnifying glass over the photo. Look for four clocks.', 'Only T1 has the trial star, so the other three are not trial clocks.'],
      'successMessage': "The clocks don't agree!",
      'transition': [
        'The café clock, the church clock and the post office clock all agree.',
        'But T1 is one hour behind them.',
        'What if those three were all wrong? Is there a time that nobody can set?',
        'Look! In the photo, a sundial stands next to T1.',
      ],
      'clue': {'note': 'Three clocks that are not trial clocks all show the same time.'},
      'evidence': {'description': 'The clocks in Roof Photo 2, all at one moment on the trial day.'},
    },
    's2_ep10_m3': {
      'story': ['The old sundial is still here on the roof.', 'A sundial uses the shadow of the sun to tell the time.'],
      'letterIntro': 'Words are written around the sundial:',
      'letter': 'I COUNT ONLY THE SUNNY HOURS.',
      'question': _sameShadow,
      'hints': ['Move the sun slowly, and watch how the shadow turns and changes.', 'In Photo 2, the shadow points somewhere between 3 and 4.'],
      'successMessage': 'The sun tells the truth!',
      'transition': [
        'In Photo 1, T1 and the sun both said 2:00.',
        'In Photo 2, T1 said 2:30, but the sun said 3:30!',
        'Nobody can set the sun.',
        _clocksMayLie,
        'Then where did the hour between three and four go?',
      ],
      'clue': {'note': 'Nobody can change the time of the sun.'},
      'evidence': {'description': 'The sundial on the roof, in two old photos.'},
    },
    's2_ep10_final': {
      'story': ['You lay the tape on the table. Photo 1 goes at the first 2:00.', 'Now find where Photo 2 belongs on the tape.'],
      'letterIntro': 'Your two photos say:',
      'letter': _photos,
      'question': _lostOrWrong,
      'hints': ['Photo 2 was taken after Photo 1. Count how much later.', 'Look for the page about three to four. Is it in the book?'],
      'successMessage': 'The hour was not lost after all!',
      'transition': [
        'Paris never lost an hour. For one hour, T1 was simply wrong.',
        "Were T2 and T3 wrong too? We can't tell yet.",
        _plaque,
        'Was the plaque about this hour?',
        'Next, the mystery leads to Saint-Sulpice!',
      ],
      'options': {
        'lost': {'feedback': "Look at the sun's times. Did the sun ever jump?"},
        'all': {'feedback': 'Check what the café and church clocks said.'},
      },
      'evidence': {'description': "T1's tape, laid next to the sun's time."},
    },
  },
};

final master10 = <String, Object?>{
  'synopsis': ['The star beneath T1 points to the Arc de Triomphe.', 'The trial records may be waiting there.', _lostOrWrong],
  'objectives': ['Read the record T1 left behind.', 'Test T1 against the clocks around it.', 'Let the sun be the judge.'],
  'intro': [
    'The Arc de Triomphe, where twelve roads meet like the points of a star.',
    "T1's little clock had stood on top of an arch, a star beneath it.",
    'You climb the long stairway to the top.',
    'Beneath the roof, a small door bears a star.',
    'Inside wait a brass drum, a box of photos and a thick book.',
    'On the wall, a brass plate reads: TRIAL RECORDS · KEPT AT THE STAR.',
    'The garden held only a model. These records belong to the real trial.',
    'Time to read what T1 recorded.',
  ],
  'caseSummary':
      'The hour truly passed, as the sun and the café, church and post office clocks prove. T1 ran an hour behind, page 3 is missing, and the list says it went to Saint-Sulpice.',
  'hook': 'Who sent page 3 away, and for what reason?',
  'glossary': {...words10, ...masterWords10},
  'missions': {
    's2_ep10_m1': {
      'story': ['A paper tape is wound inside the drum.', 'Every fifteen minutes, T1 stamped its time onto it.'],
      'letterIntro': 'Printed at the head of the tape:',
      'letter': 'T1 · DRUM TAPE · TRIAL DAY',
      'question': 'Where does the time leap? Tap both places.',
      'hints': ['Fifteen minutes should separate each time from the next.', 'Watch what follows each 2:45.'],
      'successMessage': 'Both jumps uncovered!',
      'transition': [
        'After 2:45, the tape falls back to 2:00, and later leaps to 4:00.',
        "Three o'clock never appears on the tape.",
        _steals,
        'Was an hour stolen, or was T1 simply wrong?',
        'Other clocks may tell a different story.',
      ],
      'clue': {'note': "Not once does T1's tape show three o'clock."},
      'evidence': {'description': 'The paper tape drawn from the drum beneath T1.'},
    },
    's2_ep10_m2': {
      'story': ['ROOF PHOTOS · TRIAL DAY: a box holding two old photos.', 'Photo 2 captures T1 on the roof, the city spread out behind it.'],
      'letterIntro': 'On the reverse of Photo 2:',
      'letter': 'T1 · ROOF · PHOTO 2',
      'question': 'Find every clock in the photo, then sort them: trial clock or not?',
      'hints': ['Sweep the glass across the photo. Four clocks are hiding there.', 'A trial clock carries the star. Which ones do not?'],
      'successMessage': 'The clocks disagree by an hour!',
      'transition': [
        'The café, church and post office clocks all tell the same time.',
        'T1 lags one hour behind them.',
        'Yet what if all three were wrong? Is there any time no one can change?',
        'Look closely: a sundial stands beside T1 in the photo.',
      ],
      'clue': {'note': 'Three clocks outside the trial all agree with one another.'},
      'evidence': {'description': 'The clocks of Roof Photo 2, caught at a single moment on the trial day.'},
    },
    's2_ep10_m3': {
      'story': ['Up on the roof, the old sundial still stands.', 'A sundial reads the hour from the shadow the sun casts.'],
      'letterIntro': 'Around the rim of the sundial:',
      'letter': 'I COUNT ONLY THE SUNNY HOURS.',
      'question': _sameShadow,
      'hints': ['Guide the sun gently and watch the shadow swing and stretch.', 'In Photo 2, the shadow rests between 3 and 4.'],
      'successMessage': 'The sun cannot lie!',
      'transition': [
        'Photo 1: T1 and the sun agreed on 2:00.',
        'Photo 2: T1 claimed 2:30, while the sun showed 3:30!',
        'No hand can turn the sun.',
        _clocksMayLie,
        'Then what became of the hour between three and four?',
      ],
      'clue': {'note': 'The sun answers to no one.'},
      'evidence': {'description': 'The rooftop sundial, as two old photos show it.'},
    },
    's2_ep10_final': {
      'story': ['You spread the tape across the table, Photo 1 pinned at the first 2:00.', 'Where on the tape does Photo 2 belong?'],
      'letterIntro': 'From your two photos:',
      'letter': _photos,
      'question': _lostOrWrong,
      'hints': ['Measure the time between the two photos on the tape.', 'One page of the Trial Log should cover three to four. Is it there?'],
      'successMessage': 'No hour was ever lost!',
      'transition': [
        'Paris lost no hour at all. For one hour, T1 was wrong.',
        'Did T2 and T3 go wrong too? That we cannot tell.',
        _plaque,
        'Could the plaque have meant this very hour?',
        'The trail now leads to Saint-Sulpice!',
      ],
      'options': {
        'lost': {'feedback': "Follow the sun's line. Does the sun ever leap ahead?"},
        'all': {'feedback': 'Then why did the café and church clocks disagree with T1?'},
      },
      'evidence': {'description': "T1's tape, set beside the time the sun kept."},
    },
  },
};

// ═════════════════════════════════════════════════════════════════════════
// Case 11 — The Unwritten Hour
// ═════════════════════════════════════════════════════════════════════════

const _rubbing = 'Page 3 is in Box 9.\nLock it. No one may read it.';
const _victorsPaper = 'CLOCK TEST · V.D.\nAll the clocks were fine.';
const _yourClues = "PAGE 3 · VICTOR'S PAPER · VICTOR'S NAME";
const _stop = 'E.M. said, "Stop!"';
const _keepGoing = 'Victor said, "Keep going."';

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
// Case 12 — The Clockmaker's Truth
// ═════════════════════════════════════════════════════════════════════════

const _tag = 'Made by Émile Moreau';
const _tagLine = 'The tag says: Made by Émile Moreau.';
const _card = 'HOW TO FIX THE MACHINE\n1. Stop. 2. Turn. 3. Fix. 4. Start.';
const _cardSteps = 'Stop, turn, fix, start.';
const _loseAnHour = 'Did Paris lose an hour?';
const _neverGone = 'The hour was never gone.';

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

/// T1's tape: what is said at its start, after one jump and after both.
DrumTapeScene _drum(DrumTapeScene b, {required String start, required String oneMore, required String found}) => DrumTapeScene(
      drumFile: b.drumFile,
      drumPixels: b.drumPixels,
      slot: b.slot,
      plate: b.plate,
      header: b.header,
      marks: b.marks,
      task: b.task,
      pullLabel: b.pullLabel,
      startLine: start,
      oneMore: oneMore,
      found: found,
    );

/// The roof photo's clocks, each with its line for a wrong tray.
RoofPhoto _photo(RoofPhoto b, Map<String, String> wrong) => RoofPhoto(
      file: b.file,
      pixels: b.pixels,
      label: b.label,
      clocks: [
        for (final c in b.clocks)
          PhotoClock(
            id: c.id,
            name: c.name,
            label: c.label,
            centre: c.centre,
            rx: c.rx,
            ry: c.ry,
            trial: c.trial,
            photo1: c.photo1,
            photo2: c.photo2,
            wrongLine: wrong[c.id]!,
            card: c.card,
          ),
      ],
      dial: b.dial,
      t1Crop: b.t1Crop,
      dialCrop: b.dialCrop,
    );

CityClocksScene _city(CityClocksScene b, {required Map<String, String> wrong, required String more, required String found, required List<String> sorted}) =>
    CityClocksScene(
      photo: _photo(b.photo, wrong),
      task: b.task,
      sortTask: b.sortTask,
      trialTray: b.trialTray,
      otherTray: b.otherTray,
      lensScale: b.lensScale,
      lensSize: b.lensSize,
      moreLine: more,
      foundLine: found,
      sortedLines: sorted,
      trialMapId: b.trialMapId,
    );

ShadowCheckScene _shadow(ShadowCheckScene b, {required String longer, required String shorter, required String match}) => ShadowCheckScene(
      sundial: b.sundial,
      photo: b.photo,
      photos: b.photos,
      task: b.task,
      dragLine: b.dragLine,
      longer: longer,
      shorter: shorter,
      matchLine: match,
      nextLabel: b.nextLabel,
      plateWords: b.plateWords,
    );

/// The tape on the table, the Trial Log and its list: what is said at each
/// step. The tape, the pages, the list and the map are the base's.
HourRecordScene _hour(
  HourRecordScene b, {
  required String firstTwoThirty,
  required String notTwoThirty,
  required List<String> found,
  required String pageTask,
  required String pageInBook,
  required String pageFound,
  required List<String> after,
  required String question,
  required String other,
  required List<String> done,
}) =>
    HourRecordScene(
      room: b.room,
      tape: b.tape,
      photo1Mark: b.photo1Mark,
      photo2Mark: b.photo2Mark,
      photos: b.photos,
      tapeTask: b.tapeTask,
      firstTwoThirty: firstTwoThirty,
      notTwoThirty: notTwoThirty,
      foundLines: found,
      backLabel: b.backLabel,
      rightLabel: b.rightLabel,
      logFile: b.logFile,
      logPixels: b.logPixels,
      leftPage: b.leftPage,
      rightPage: b.rightPage,
      emblem: b.emblem,
      logTitle: b.logTitle,
      pages: b.pages,
      pageTask: pageTask,
      pageInBook: pageInBook,
      pageFoundLine: pageFound,
      afterLines: after,
      lead: RecordListLead(
        title: b.lead.title,
        heading: b.lead.heading,
        lines: b.lead.lines,
        question: question,
        answer: b.lead.answer,
        otherLine: other,
        mapFile: b.lead.mapFile,
        mapPixels: b.lead.mapPixels,
        spot: b.lead.spot,
        doneLines: done,
      ),
      leadLabel: b.leadLabel,
    );

/// [base] said as [text], by the same voice and in the same mood.
TalkLine _say(TalkLine base, String text) => switch (base.voice) {
      TalkVoice.narrator => TalkLine.narrator(text),
      TalkVoice.detective => TalkLine.detective(text),
      TalkVoice.speaker => TalkLine(text, mood: base.mood),
    };

/// Each line of [base] said as [texts] (as many, in order).
List<TalkLine> _beat(List<TalkLine> base, List<String> texts) {
  assert(texts.length == base.length, 'a beat keeps its number of lines');
  return [for (final (i, l) in base.indexed) _say(l, texts[i])];
}

/// A talk's words at a level: its goal, its opening, each question's words
/// and beat (by id), each piece to show's prompt, beat, line for a wrong
/// piece and the line that names the right one (by id).
typedef TalkWords = ({
  String goal,
  List<String> opening,
  Map<String, (String, List<String>)> questions,
  Map<String, (String, List<String>, String, String)> presents,
});

/// [base] told in a level's words. Who speaks, the steps, what each needs
/// and accepts, every line's voice and mood, and how the talk ends are the
/// base's.
TalkScene _talk(TalkScene base, TalkWords w) => TalkScene(
      id: base.id,
      speaker: base.speaker,
      goal: w.goal,
      opening: _beat(base.opening, w.opening),
      questions: [
        for (final q in base.questions)
          TalkQuestion(
            id: q.id,
            text: w.questions[q.id]!.$1,
            beat: _beat(q.beat, w.questions[q.id]!.$2),
            requires: q.requires,
            repeatable: q.repeatable,
          ),
      ],
      presents: [
        for (final p in base.presents)
          TalkPresent(
            id: p.id,
            prompt: w.presents[p.id]!.$1,
            accepted: p.accepted,
            beat: _beat(p.beat, w.presents[p.id]!.$2),
            misses: p.misses,
            miss: _say(p.miss, w.presents[p.id]!.$3),
            requires: p.requires,
            choices: p.choices,
            tell: p.tell == null ? null : w.presents[p.id]!.$4,
          ),
      ],
      finishWhen: base.finishWhen,
      place: base.place,
      background: base.background,
      finishLabel: base.finishLabel,
      answer: base.answer,
      earlierEvidence: base.earlierEvidence,
    );

TalkWords _only(String goal, List<String> opening) => (goal: goal, opening: opening, questions: const {}, presents: const {});

TalkMission _mission(TalkMission base, {TalkWords? before, TalkWords? after}) => TalkMission(
      before: base.before == null ? null : _talk(base.before!, before!),
      after: base.after == null ? null : _talk(base.after!, after!),
    );

/// The case's ending at a level: each line said in its words, by the same
/// voice, name, face and place.
List<EndingLine> _ending(List<EndingLine> base, List<String> texts) => [
      for (final (i, l) in base.indexed)
        EndingLine(texts[i], voice: l.voice, name: l.name, portrait: l.portrait, background: l.background, evidenceId: l.evidenceId),
    ];

// Victor's own words, as the case file and his evidence quote them.
const _hidThePage = 'Yes. I hid the page.';
const _afraid = 'I was afraid.';
const _peopleToKnow = "I didn't want people to know.";
const _artsEtMetiers = 'His old machine is at Arts et Métiers.';
// Big Ben's box, as the story bible tells it to a child (v2.0).
const _boxUnder = 'A secret box is under it.';
const _hiddenPapers = 'Inside is a list of hidden papers.';
const _opensOnly = 'It opens only if Big Ben stops.';
const _stopTheTest = 'You said, "Stop the test!"';

// The case file's own lines, said again at the end.
const _clocksWrong = 'The clocks were wrong.';
const _victorHid = 'Victor hid the truth.';
const _emileLeft = 'Émile left the clues.';

/// Cases 10–12's scenes with Junior's words.
final juniorScenes1012 = (
  drumTapes: {
    's2_ep10_m1': _drum(season2DrumTape, start: 'This is where the tape begins.', oneMore: 'That is one jump! Now find the other one.', found: 'You found both jumps!'),
  },
  cityClocks: {
    's2_ep10_m2': _city(
      season2CityClocks,
      wrong: const {
        't1': 'Check the post under T1. Which sign is on it?',
        'cafe': 'Can you see a star, three arches or a bell on it? Look at your Trial Map.',
        'church': 'Can you see a star, three arches or a bell on it? Look at your Trial Map.',
        'post': 'Can you see a star, three arches or a bell on it? Look at your Trial Map.',
      },
      more: 'There are still more clocks in the photo.',
      found: 'You found a clock!',
      sorted: const ['T1 shows 2:30.', 'The café, the church and the post office all show 3:30.'],
    ),
  },
  shadowChecks: {
    's2_ep10_m3': _shadow(
      season2ShadowCheck,
      longer: 'Not yet. In the photo, the shadow is longer.',
      shorter: 'Not yet. In the photo, the shadow is shorter.',
      match: 'It is the same shadow!',
    ),
  },
  hourRecords: {
    's2_ep10_final': _hour(
      season2HourRecord,
      firstTwoThirty: 'This 2:30 is just half an hour after Photo 1. Photo 2 was taken later.',
      notTwoThirty: 'In Photo 2, T1 said 2:30. Find a 2:30 on the tape.',
      found: const [
        'Six marks of fifteen minutes: that is one and a half hours after Photo 1.',
        'There it is: the hour from three to four! It was on the tape the whole time.',
        'At three, T1 went back one hour. At four, it was right again.',
      ],
      pageTask: 'Which page should tell about three to four? Is it in the book?',
      pageInBook: 'That page is here in the book. Keep turning the pages.',
      pageFound: 'Page 3 should tell about three to four, but it is not in the book.',
      after: const [
        'In the garden, a model showed what could happen. This tape shows what really happened to T1.',
        'Time never stopped. T1 was wrong, and page 3 is missing.',
      ],
      question: 'Where was page 3 sent to?',
      other: 'That page is still in the book. Look for page 3.',
      done: const [
        'The list says page 3 was sent to Saint-Sulpice, just north of the Luxembourg Gardens.',
        "Is page 3 really there? Who sent it there, and why? The list doesn't tell us.",
      ],
    ),
  },
  talkMissions: {
    's2_ep11_m1': _mission(
      season2Case11TalkMissions['s2_ep11_m1']!,
      before: _only('Find the missing page 3.', const [
        'Welcome to the archive annex.',
        'My name is Victor Delacroix.',
        'A long time ago, I was in charge of a clock test.',
        'Victor writes his name in the visitor book.',
        'I need to find page 3.',
        'Page 3?',
        "I don't know where that is.",
        'You could look in the big book, then.',
      ]),
      after: _only('Find the missing page 3.', const [
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
    's2_ep11_m2': _mission(
      season2Case11TalkMissions['s2_ep11_m2']!,
      before: _only('Find the paper that is not true.', const [
        'This is my paper.',
        'It tells what really happened.',
        'My office has never changed a single paper.',
      ]),
      after: _only('Find the paper that is not true.', const [
        'Fine. My paper was wrong.',
        "But I didn't hide page 3!",
        'Anyone in my office could have done that.',
      ]),
    ),
    's2_ep12_m1': _mission(
      season2Case12TalkMissions['s2_ep12_m1']!,
      before: _only('Who is this man?', const ['Someone is in here.', 'So, you found me.', 'Who are you?', "Don't ask me that.", 'Use the clues to find out.']),
      after: _only('Who is this man?', const ['Émile made this wheel!', 'Émile Moreau… so he is E.M.!', 'You are getting closer.']),
    ),
    's2_ep12_m2': _mission(
      season2Case12TalkMissions['s2_ep12_m2']!,
      before: _only('Find out who the Clockmaker is.', const [
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
    's2_ep12_m3': _mission(
      season2Case12TalkMissions['s2_ep12_m3']!,
      before: _only('Make the old machine right again.', const [
        'Why is the machine still not right?',
        'On the day of the test, I stopped it.',
        'After that, Victor stopped all the tests.',
        'So nobody ever fixed the machine.',
        'Can I fix it now?',
        'Yes. $_cardSteps',
      ]),
      after: _only('Make the old machine right again.', const ['At last, it is right.', 'Thank you, detective.']),
    ),
  },
  talks: {
    's2_ep11_final': _talk(season2Case11Talks['s2_ep11_final']!, (
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
          ['…It was me.', _hidThePage, 'But why?', 'I was in charge of the test.', 'And the clocks went wrong.', _afraid, _peopleToKnow, 'But the truth is important.', 'I know. I am truly sorry.'],
          "There isn't a name on that.",
          "Show Victor's Name. It was pressed into the big book.",
        ),
      },
    )),
  },
  endings: {
    's2_ep12_final': _ending(season2Case12Ending, const [
      "Victor's words are kept in the case file.",
      _hidThePage,
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

/// Cases 10–12's scenes with Master's words.
final masterScenes1012 = (
  drumTapes: {
    's2_ep10_m1': _drum(season2DrumTape, start: 'The tape begins here.', oneMore: 'One jump found. Another is hiding.', found: 'Both jumps uncovered!'),
  },
  cityClocks: {
    's2_ep10_m2': _city(
      season2CityClocks,
      wrong: const {
        't1': 'What sign is on the post beneath T1?',
        'cafe': 'Does it bear a star, three arches or a bell? Your Trial Map will tell.',
        'church': 'Does it bear a star, three arches or a bell? Your Trial Map will tell.',
        'post': 'Does it bear a star, three arches or a bell? Your Trial Map will tell.',
      },
      more: 'More clocks are hiding in the photo.',
      found: 'A clock, found!',
      sorted: const ['T1 reads 2:30.', 'The café, the church and the post office all read 3:30.'],
    ),
  },
  shadowChecks: {
    's2_ep10_m3': _shadow(
      season2ShadowCheck,
      longer: "Not quite: the photo's shadow is longer.",
      shorter: "Not quite: the photo's shadow is shorter.",
      match: 'A perfect match of shadows!',
    ),
  },
  hourRecords: {
    's2_ep10_final': _hour(
      season2HourRecord,
      firstTwoThirty: 'This 2:30 comes only half an hour after Photo 1. Photo 2 is later still.',
      notTwoThirty: 'Photo 2 shows T1 at 2:30. Look for a 2:30.',
      found: const [
        'Six marks of fifteen minutes: an hour and a half after Photo 1.',
        'There it is, the hour from three to four, on the tape all along!',
        'At three, T1 slipped an hour back; at four, it was right once more.',
      ],
      pageTask: 'Which page should cover three to four? Is it still in the book?',
      pageInBook: 'That page is still in the book. Look further.',
      pageFound: 'Page 3 ought to cover three to four, yet it is missing from the book.',
      after: const [
        'The garden model showed what might happen; this tape shows what did happen to T1.',
        'Time never stood still. T1 was wrong, and page 3 is gone.',
      ],
      question: 'Which place was page 3 sent to?',
      other: 'That page never left the book. Find page 3.',
      done: const [
        'According to the list, page 3 went to Saint-Sulpice, north of the Luxembourg Gardens.',
        'Is it truly there? Who sent it, and why? The list stays silent.',
      ],
    ),
  },
  talkMissions: {
    's2_ep11_m1': _mission(
      season2Case11TalkMissions['s2_ep11_m1']!,
      before: _only('Track down page 3.', const [
        'Ah, a visitor. Welcome to the archive.',
        'Victor Delacroix, at your service.',
        'Many years ago, I ran a clock test.',
        'Victor signs his name in the visitor book.',
        'I am searching for page 3.',
        'Page 3...?',
        'I have no idea where it might be.',
        'Try the big book, then.',
      ]),
      after: _only('Track down page 3.', const [
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
    's2_ep11_m2': _mission(
      season2Case11TalkMissions['s2_ep11_m2']!,
      before: _only('Expose the paper that lies.', const ['Here is my report.', 'It tells the true story.', 'My office never altered a single paper.']),
      after: _only('Expose the paper that lies.', const ['Very well. My paper was wrong.', 'But I never hid page 3!', 'Anyone in my office could have done it.']),
    ),
    's2_ep12_m1': _mission(
      season2Case12TalkMissions['s2_ep12_m1']!,
      before: _only('Who is the stranger?', const ['There is someone here.', 'Ah. You have found me.', 'Who are you?', 'My words will not help you.', 'Let the clues tell you.']),
      after: _only('Who is the stranger?', const ["This wheel is Émile's work!", 'Émile Moreau… E.M.!', 'You are close now. Very close.']),
    ),
    's2_ep12_m2': _mission(
      season2Case12TalkMissions['s2_ep12_m2']!,
      before: _only('Unmask the Clockmaker.', const [
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
    's2_ep12_m3': _mission(
      season2Case12TalkMissions['s2_ep12_m3']!,
      before: _only('Repair the old machine.', const [
        'Why does the machine still run wrong?',
        'On the day of the test, I brought it to a stop.',
        'Then Victor ended every test.',
        'No one ever repaired it.',
        'Could I fix it?',
        'You could. $_cardSteps',
      ]),
      after: _only('Repair the old machine.', const ['At long last, it keeps true time.', 'I am grateful, detective.']),
    ),
  },
  talks: {
    's2_ep11_final': _talk(season2Case11Talks['s2_ep11_final']!, (
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
            _hidThePage,
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
  endings: {
    's2_ep12_final': _ending(season2Case12Ending, const [
      "Victor's own words now rest in the case file.",
      _hidThePage,
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

/// Cases 10–12 have no scene whose words are the same at every level.
const sameAtEveryLevel1012 = <String>{};

// ═════════════════════════════════════════════════════════════════════════
// The learning design
// ═════════════════════════════════════════════════════════════════════════

LearningObjective _learn(String id, List<String> expressions) {
  final base = season2Learning[id]!;
  return LearningObjective(
    dependency: base.dependency,
    level: base.level,
    skill: base.skill,
    recallFrom: base.recallFrom,
    objective: base.objective,
    expressions: expressions,
  );
}

const _hourMissing = 'T1 was one hour behind, and the page about it is missing.';

final juniorLearning1012 = <String, LearningObjective>{
  's2_ep10_m1': _learn('s2_ep10_m1', ['Every time should be fifteen minutes after the one before it', 'Find the two places where the time jumps']),
  's2_ep10_m2': _learn('s2_ep10_m2', ['Is each one a trial clock?', 'the other three are not trial clocks']),
  's2_ep10_m3': _learn('s2_ep10_m3', ['Make the same shadow as in the photo.', 'watch how the shadow turns']),
  's2_ep10_final': _learn('s2_ep10_final', [_lostOrWrong, _hourMissing, 'Count how much later']),
  's2_ep11_m1': _learn('s2_ep11_m1', ['Page 3 is in Box 9.', 'Where is page 3?']),
  's2_ep11_m2': _learn('s2_ep11_m2', ['Were the clocks right, or wrong?']),
  's2_ep11_m3': _learn('s2_ep11_m3', ['Which name matches?']),
  's2_ep11_final': _learn('s2_ep11_final', ['Who really hid the truth?']),
  's2_ep12_m1': _learn('s2_ep12_m1', ["Which wheel is the same as Clock III's?"]),
  's2_ep12_m2': _learn('s2_ep12_m2', ['So who is the Clockmaker?']),
  's2_ep12_m3': _learn('s2_ep12_m3', ['Fix the old machine, step by step']),
  's2_ep12_final': _learn('s2_ep12_final', [_loseAnHour, 'the hour was there']),
};

final masterLearning1012 = <String, LearningObjective>{
  's2_ep10_m1': _learn('s2_ep10_m1', ['Fifteen minutes should separate each time from the next', 'Where does the time leap?']),
  's2_ep10_m2': _learn('s2_ep10_m2', ['trial clock or not?', 'A trial clock carries the star']),
  's2_ep10_m3': _learn('s2_ep10_m3', ['Make the same shadow as in the photo.', 'watch the shadow swing and stretch']),
  's2_ep10_final': _learn('s2_ep10_final', [_lostOrWrong, _hourMissing, 'Measure the time between the two photos']),
  's2_ep11_m1': _learn('s2_ep11_m1', ['Page 3 is in Box 9.', 'Track down page 3']),
  's2_ep11_m2': _learn('s2_ep11_m2', ['Were the clocks really right?']),
  's2_ep11_m3': _learn('s2_ep11_m3', ['Find the matching name']),
  's2_ep11_final': _learn('s2_ep11_final', ['Who buried the truth?']),
  's2_ep12_m1': _learn('s2_ep12_m1', ["Find the wheel that matches Clock III's"]),
  's2_ep12_m2': _learn('s2_ep12_m2', ['Who, then, is the Clockmaker?']),
  's2_ep12_m3': _learn('s2_ep12_m3', ['Repair the old machine']),
  's2_ep12_final': _learn('s2_ep12_final', [_loseAnHour, 'the hour itself was never lost']),
};
