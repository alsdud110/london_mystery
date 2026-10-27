import '../../../models/learning.dart';
import '../../../models/star_puzzles.dart';
import '../season2_case10_scenes.dart';
import 'level_words.dart';

// Case 10 — The Hour of Shadows, at each level (PART 7D): the words only
// (`docs/difficulty_reviews/PARIS_CASE_10_12.md`).
//
// Cases 10–12:
//
// Rookie: the game's own words (written for 8–12 year olds, v2.0),
// reviewed and kept; the words a child may not know added to the glossary.
//
// At every level the same: the papers each puzzle is read from (T1's tape
// head, the back of Photo 2, the sundial's words, the photos' times, the
// Trial Log's pages and record list, the rubbing, page 3, Victor's paper,
// the name tag, PARIS, the machine's card, the case board's questions),
// what the evidence quotes (Victor's "Yes. I hid the page.", "I was
// afraid.", "I didn't want people to know."; the case file's lines), the
// story bible's own lines (Big Ben's box: "A secret box is under it.",
// "Inside is a list of hidden papers.", "It opens only if Big Ben
// stops."; "His old machine is at Arts et Métiers."), the lines earlier
// cases are quoted by ("The Clockmaker steals an hour.", "The clocks may
// lie.", the Eiffel Tower's plaque), every answer, id and order, every
// beat's number of lines, voices and moods, and every way to play.
//
// Told at the same moment at every level: that T1 was wrong (Case 10's
// final), where page 3 was sent, who V.D. is (Case 11 M1, after the box),
// that Victor hid it (Case 11), E.M.'s name (Case 12 M1), who the
// Clockmaker is (Case 12 M2), why, and what he did wrong.

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

const _lostOrWrong = 'Was the hour lost — or was the clock wrong?';
const _steals = 'At Gare du Nord we read: The Clockmaker steals an hour.';
const _clocksMayLie = 'The letter at the Louvre said: The clocks may lie.';
const _plaque = 'At the Eiffel Tower, a time-recording machine hid a plaque: ONE HOUR IS MISSING. THE CLOCK IS STILL RUNNING.';
const _sameShadow = 'Move the sun. Make the same shadow as in the photo.';
const _photos = 'PHOTO 1 · T1 2:00 · SUN 2:00\nPHOTO 2 · T1 2:30 · SUN 3:30';

const rookie10 = <String, Object?>{'glossary': words10};

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

// ═════════════════════════════════════════════════════════════════════════
// The learning design
// ═════════════════════════════════════════════════════════════════════════

const _hourMissing = 'T1 was one hour behind, and the page about it is missing.';

// ═════════════════════════════════════════════════════════════════════════
// The scenes' own words
// ═════════════════════════════════════════════════════════════════════════

/// Case 10's scenes with Junior's words.
final juniorScenes10 = (
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
);

/// Case 10's scenes with Master's words.
final masterScenes10 = (
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
);

// ═════════════════════════════════════════════════════════════════════════
// The learning design
// ═════════════════════════════════════════════════════════════════════════

final juniorLearning10 = <String, LearningObjective>{
  's2_ep10_m1': levelObjective('s2_ep10_m1', ['Every time should be fifteen minutes after the one before it', 'Find the two places where the time jumps']),
  's2_ep10_m2': levelObjective('s2_ep10_m2', ['Is each one a trial clock?', 'the other three are not trial clocks']),
  's2_ep10_m3': levelObjective('s2_ep10_m3', ['Make the same shadow as in the photo.', 'watch how the shadow turns']),
  's2_ep10_final': levelObjective('s2_ep10_final', [_lostOrWrong, _hourMissing, 'Count how much later']),
};

final masterLearning10 = <String, LearningObjective>{
  's2_ep10_m1': levelObjective('s2_ep10_m1', ['Fifteen minutes should separate each time from the next', 'Where does the time leap?']),
  's2_ep10_m2': levelObjective('s2_ep10_m2', ['trial clock or not?', 'A trial clock carries the star']),
  's2_ep10_m3': levelObjective('s2_ep10_m3', ['Make the same shadow as in the photo.', 'watch the shadow swing and stretch']),
  's2_ep10_final': levelObjective('s2_ep10_final', [_lostOrWrong, _hourMissing, 'Measure the time between the two photos']),
};
