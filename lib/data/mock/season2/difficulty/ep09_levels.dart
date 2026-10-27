import '../../../models/garden_puzzles.dart';
import '../../../models/learning.dart';
import '../season2_case09_scenes.dart';
import 'level_words.dart';

// Case 09 — The Clockwork Garden, at each level (PART 7C): the words only
// (`docs/difficulty_reviews/PARIS_CASE_07_09.md`).
// What Cases 07–09 keep the same, and untold, at every level: ep07_levels.dart.

const words09 = {'chronos': '크로노스(시험 이름)', 'twelve': '열둘, 12', 'arches': '아치들', 'setting': '설정'};
const juniorWords09 = {'repaired': '수리했다', 'slides': '미끄러지듯 움직인다', 'happens': '일어난다'};
const masterWords09 = {
  'designed': '설계했다',
  'repaired': '수리했다',
  'copies': '본뜨다',
  'returned': '돌려놓은',
  'carried': '(실험을) 실시한',
  'refuse': '~하려 하지 않다',
  'separate': '서로 다른',
  'spreading': '퍼져 나가는',
};

/// Case 09 at Rookie: "mended" said as "fixed" (the same repair).
const rookie09 = <String, Object?>{
  'glossary': words09,
  'missions': {
    's2_ep09_m3': {
      'transition': [
        "The Clockmaker's gear is the trial's emblem.",
        'The two hands are on the repair note. No. 7 fixed a trial wheel.',
        'Two marks on two different papers. Did one person make both? The papers do not say.',
        "And the paper from the bag? Is it linked to this machine? We can't tell yet.",
      ],
    },
  },
};

const _putBack = 'Put each clock back where it belongs.';
const _join = 'Join the tower to the trial clocks.';
const _marks =
    "THE CLOCKMAKER'S MARK (Gare du Nord)\n"
    'A tiny carved gear.\n\n'
    'THE REPAIR CARD (No. 7)\n'
    'Signed with two clock hands.';
const _testCard = 'Set the tower one hour back. Then press TEST.';
const _drumTag = 'Its tag says: TRIAL RECORDS · KEPT AT THE STAR.';
const _lostOrWrong = 'Was the hour lost — or was the clock wrong?';

final junior09 = <String, Object?>{
  'synopsis': [
    'A paper for changing a time fell out of a bag.',
    'P. drew the same bag in a garden, next to a little clock.',
    'And what is that little clock?',
  ],
  'objectives': ['Find out what the little clock really is.', 'Get the clocks moving.', 'Test what the clocks do.'],
  'intro': [
    "You look at P.'s last drawing once more.",
    'There is a palace, a round pond and a little clock on a stone base.',
    'And next to it is the same flat bag.',
    'You walk into the Luxembourg Gardens.',
    "There's the palace, and there's the pond. It's the garden from the drawing!",
    "Look! There's the little clock from the drawing!",
    'The same bag was here once. But why?',
  ],
  'caseSummary': "One wrong setting changed only the clocks that were joined. T1's star pointed to the Arc de Triomphe.",
  'hook': _lostOrWrong,
  'glossary': {...words09, ...juniorWords09},
  'missions': {
    's2_ep09_m1': {
      'story': ['There is a map of Paris on the stone base.', 'Next to it, three little clocks lie in a box.'],
      'letterIntro': 'A note beside the box says:',
      'letter': _putBack,
      'question': 'Put each little clock back in its place on the map.',
      'hints': ['Look at the shape of each clock, then find that shape on the map.', 'T1 looks like an arch, T2 like a bridge, and T3 has a tall spire.'],
      'successMessage': 'All three clocks are back in place!',
      'transition': [
        'There are trial clocks in only three places in Paris.',
        'Each one has its own sign: a star, three arches or a bell.',
        'How can one little tower reach all three?',
      ],
      'clue': {'note': 'Trial clocks stand in only three places in Paris.'},
      'evidence': {'description': 'The little clocks, back in their places on the map of Paris.'},
    },
    's2_ep09_m2': {
      'story': ['Under the model, a little door opens.', 'There are gears inside! But two of them are missing.'],
      'letterIntro': 'The board says:',
      'letter': _join,
      'question': 'Use the gears to join the tower and the trial clocks.',
      'hints': ['Look at the size of each dotted circle. Which gear fits it?', 'The big gear goes next to T1, and the small gear goes next to T2 and T3.'],
      'successMessage': 'All the joined clocks turn together!',
      'transition': [
        'Gears move the model, but the real trial used wires.',
        'Under T1, a little drum writes down the time.',
        _drumTag,
        'A drawer slides open. Who planned this machine? And who fixed it?',
      ],
      'clue': {'note': 'The tower only moves the clocks that are joined to it.'},
      'evidence': {'description': 'The gear board under the Little Paris model.'},
    },
    's2_ep09_m3': {
      'story': ['In the drawer is an old plan called CHRONOS TRIAL, with a repair note.', 'You have seen these marks before!'],
      'letterIntro': 'Your notebook has these marks:',
      'letter': _marks,
      'question': 'Find the same two marks on the old paper.',
      'hints': ['Look for the same shapes on the old paper.', 'Look for the gear on the plan, and the two hands on the repair note.'],
      'successMessage': 'They are the same marks!',
      'transition': [
        "The Clockmaker's gear is the emblem of the trial.",
        'The two hands are on the repair note. No. 7 repaired a trial wheel.',
        'There are two marks on two different papers. Did one person make both? The papers do not say.',
        "And the paper from the bag? Is it connected to this machine? We can't tell yet.",
      ],
      'clue': {'note': 'Two marks on two different papers. Who made them? The papers do not say.'},
      'evidence': {'description': 'An old plan of the trial, with a repair note.'},
    },
    's2_ep09_final': {
      'story': ["You put the hands back on the tower. Every clock says four o'clock.", 'What happens if the tower is set to the wrong time?'],
      'letterIntro': 'The card reads:',
      'letter': _testCard,
      'question': 'What happened to the clocks?',
      'hints': ['To go one hour back, move the short hand from 4 to 3.', 'Check which clocks changed and which one stayed at four.'],
      'successMessage': 'One wrong setting did it!',
      'transition': [
        'One wrong setting can change many joined clocks at once.',
        "And the bag? We still don't know why it came here.",
        'Was an hour really lost? The records at the star may tell us.',
        'Next, the mystery leads to the Arc de Triomphe!',
      ],
      'options': {
        'all': {'feedback': 'Check the garden clock. What time does it show?'},
        'who': {'feedback': 'The test shows HOW it happened. Does it show WHO did it?'},
      },
      'evidence': {'description': 'A test you did on the tower clock in the garden.'},
    },
  },
};

final master09 = <String, Object?>{
  'synopsis': [
    'A paper for changing a time slipped from a bag.',
    'P. drew that same bag in a garden, beside a little clock.',
    'What could the little clock be?',
  ],
  'objectives': ['Discover the secret of the little clock.', 'Set the clocks in motion.', 'Put the clocks to the test.'],
  'intro': [
    "Once more, you study P.'s last drawing.",
    'A palace, a round pond, and a little clock on a stone base.',
    'Beside it, that same flat bag.',
    'You step through the gates of the Luxembourg Gardens.',
    'The palace. The pond. This is the garden in the drawing!',
    'And there stands the little clock, exactly as he drew it!',
    'The bag was here too. What brought it?',
  ],
  'caseSummary': "A single wrong setting changed only the joined clocks, and T1's star pointed the way to the Arc de Triomphe.",
  'hook': _lostOrWrong,
  'glossary': {...words09, ...masterWords09},
  'missions': {
    's2_ep09_m1': {
      'story': ['The stone base carries a map of Paris.', 'Beside it, three little clocks rest in a box.'],
      'letterIntro': 'Written beside the box:',
      'letter': _putBack,
      'question': 'Return the three little clocks to their places on the map.',
      'hints': ['Each little clock copies a building. Match the shapes.', 'An arch, a bridge, a tall spire: where does each stand in Paris?'],
      'successMessage': 'Every clock is home again!',
      'transition': [
        'Just three places in Paris hold trial clocks.',
        'Each bears a sign: a star, three arches, a bell.',
        'How could one little tower reach all three?',
      ],
      'clue': {'note': 'Just three places in Paris hold trial clocks.'},
      'evidence': {'description': 'The little clocks, returned to the map of Paris.'},
    },
    's2_ep09_m2': {
      'story': ['A little door swings open beneath the model.', 'Gears fill the space, but two are missing.'],
      'letterIntro': 'Written on the board:',
      'letter': _join,
      'question': 'Connect the tower to the trial clocks.',
      'hints': ['The dotted circles differ in size. Let each one choose its gear.', 'The larger space is near T1; the smaller one is near T2 and T3.'],
      'successMessage': 'The clocks turn as one!',
      'transition': [
        'Gears drive the model, though the real trial used wires.',
        'Beneath T1, a little drum records the time.',
        _drumTag,
        'A drawer slides open. Who designed this machine, and who repaired it?',
      ],
      'clue': {'note': 'The tower moves only the clocks connected to it.'},
      'evidence': {'description': 'The gear board hidden beneath the Little Paris.'},
    },
    's2_ep09_m3': {
      'story': ['The drawer holds an old plan marked CHRONOS TRIAL, with a repair note pinned to it.', 'These marks are familiar!'],
      'letterIntro': 'From your notebook:',
      'letter': _marks,
      'question': 'Find where both marks appear on the old paper.',
      'hints': ['Compare each mark with the shapes on the old paper.', 'One mark belongs to the plan itself; the other to the repair note.'],
      'successMessage': 'Both marks match!',
      'transition': [
        "The Clockmaker's gear turns out to be the trial's emblem.",
        'The two hands appear on the repair note: No. 7 once repaired a trial wheel.',
        'Two marks, on two separate papers. Were both made by one person? The papers stay silent.',
        'And the paper from the bag: is it linked to this machine? Nothing tells us yet.',
      ],
      'clue': {'note': 'Two marks, two papers, and no name to say who made them.'},
      'evidence': {'description': 'An old trial plan, a repair note pinned to it.'},
    },
    's2_ep09_final': {
      'story': ["With the tower's hands back in place, every clock reads four.", 'But what if the tower were set wrong?'],
      'letterIntro': 'A card gives the instructions:',
      'letter': _testCard,
      'question': 'What did the test show?',
      'hints': [
        'One hour back means the short hand moves from 4 to 3.',
        'After the test, compare the clocks. Did any of them refuse to move?',
      ],
      'successMessage': 'A single wrong setting!',
      'transition': [
        'A single wrong setting can change several connected clocks at once.',
        'As for the bag, why it came here remains a mystery.',
        'Was an hour truly lost? The records at the star may hold the answer.',
        'The trail now leads to the Arc de Triomphe!',
      ],
      'options': {
        'all': {'feedback': 'Did the garden clock change too?'},
        'who': {'feedback': 'A test can show how. Can it show who?'},
      },
      'evidence': {'description': "A test carried out on the garden's tower clock."},
    },
  },
};

// ═════════════════════════════════════════════════════════════════════════
// The scenes' own words
// ═════════════════════════════════════════════════════════════════════════

/// A trial clock's model with its line for a wrong place.
TrialModel _model(TrialModel m, String wrongLine) =>
    TrialModel(id: m.id, name: m.name, file: m.file, label: m.label, spot: m.spot, wrongLine: wrongLine, sign: m.sign);

/// The Little Paris: each clock's line for a wrong place.
TrialMapScene _map(TrialMapScene b, {required Map<String, String> wrong, required Map<String, String> special}) => TrialMapScene(
      mapFile: b.mapFile,
      mapPixels: b.mapPixels,
      spots: b.spots,
      models: [for (final m in b.models) _model(m, wrong[m.id]!)],
      modelPixels: b.modelPixels,
      task: b.task,
      dropRadius: b.dropRadius,
      specialLines: {for (final k in b.specialLines.keys) k: special[k]!},
      placedLine: b.placedLine,
    );

/// The gear board: what is said once it turns.
GearBoardScene _gears(GearBoardScene b, String turning) => GearBoardScene(
      file: b.file,
      pixels: b.pixels,
      view: b.view,
      gearFile: b.gearFile,
      gearPixels: b.gearPixels,
      dialFile: b.dialFile,
      dialPixels: b.dialPixels,
      dialPivot: b.dialPivot,
      radii: b.radii,
      slots: b.slots,
      fixed: b.fixed,
      clocks: b.clocks,
      tray: b.tray,
      task: b.task,
      tooBig: b.tooBig,
      tooSmall: b.tooSmall,
      oneMore: b.oneMore,
      turningLine: turning,
    );

/// The old plan: the lines for a wrong pairing of marks.
MakerMarksScene _plan(MakerMarksScene b, Map<String, String> lines) => MakerMarksScene(
      file: b.file,
      pixels: b.pixels,
      handsFile: b.handsFile,
      handsPixels: b.handsPixels,
      marks: b.marks,
      paper: b.paper,
      task: b.task,
      pickFirst: b.pickFirst,
      lines: {for (final k in b.lines.keys) k: lines[k]!},
    );

/// The tower test: its lines for a wrong hour, after the test, and the way
/// to the star. The clocks, the hours and the map are the base's.
TowerTestScene _tower(
  TowerTestScene b, {
  required Map<int, String> hours,
  required List<String> tested,
  required List<String> after,
  required String question,
  required String other,
  required String found,
  required List<String> done,
}) {
  final l = b.lead;
  return TowerTestScene(
    garden: b.garden,
    gardenPixels: b.gardenPixels,
    gardenLabel: b.gardenLabel,
    gardenClock: b.gardenClock,
    dialFile: b.dialFile,
    dialPixels: b.dialPixels,
    dialPivot: b.dialPivot,
    dialRadius: b.dialRadius,
    startHour: b.startHour,
    targetHour: b.targetHour,
    clocks: b.clocks,
    handsLine: b.handsLine,
    testLabel: b.testLabel,
    hourLines: {for (final k in b.hourLines.keys) k: hours[k]!},
    testedLines: tested,
    afterLines: after,
    lead: StarLead(
      title: l.title,
      tag: l.tag,
      question: question,
      models: l.models,
      modelPixels: l.modelPixels,
      answer: l.answer,
      otherLine: other,
      foundLine: found,
      mapFile: l.mapFile,
      mapPixels: l.mapPixels,
      spot: l.spot,
      doneLines: done,
    ),
    leadLabel: b.leadLabel,
  );
}

/// Case 09's scenes with Junior's words.
final juniorScenes09 = (
  trialMaps: {
    's2_ep09_m1': _map(
      season2TrialMaps['s2_ep09_m1']!,
      wrong: const {'t1': 'Find a big arch on the map.', 't2': 'Find a bridge with green bookstalls.', 't3': 'Find one tall spire, north of the river.'},
      special: const {'t3:notreDame': 'Notre-Dame has two towers. You need one tall spire.'},
    ),
  },
  gearBoards: {'s2_ep09_m2': _gears(season2GearBoards['s2_ep09_m2']!, 'T1, T2 and T3 turn, but the garden clock stays still.')},
  makerMarks: {
    's2_ep09_m3': _plan(season2MakerMarksScenes['s2_ep09_m3']!, const {
      'a:repair': 'Is that shape a gear?',
      'a:key': 'Is that shape a gear?',
      'b:emblem': 'How many hands can you count?',
      'b:key': 'That is a key, not two hands.',
    }),
  },
  towerTests: {
    's2_ep09_final': _tower(
      season2TowerTests['s2_ep09_final']!,
      hours: const {
        5: 'That moves it one hour forward. Go back instead.',
        2: 'That is two hours back. You only need one.',
        4: 'The tower still says four. Turn it one hour back.',
        0: 'Only one hour back: from 4 to 3.',
      },
      tested: const ['Now the tower says three.', 'T1, T2 and T3 changed with it, but the garden clock still says four.'],
      after: const ['The model shows what could happen, but not what really happened.', 'The records may be able to tell us.'],
      question: 'Which trial clock has a star on it?',
      other: 'Look at the sign on each base. You need the star.',
      found: 'The star is on the base of T1.',
      done: const [
        'On the map, T1 stands at the Arc de Triomphe.',
        'Twelve roads meet there, like the points of a star.',
        'Maybe the real records are kept there.',
      ],
    ),
  },
);

/// Case 09's scenes with Master's words.
final masterScenes09 = (
  trialMaps: {
    's2_ep09_m1': _map(
      season2TrialMaps['s2_ep09_m1']!,
      wrong: const {'t1': 'Seek out a great arch.', 't2': 'Seek a bridge lined with green bookstalls.', 't3': 'Seek a single tall spire, north of the river.'},
      special: const {'t3:notreDame': 'Notre-Dame has two towers, not one tall spire.'},
    ),
  },
  gearBoards: {'s2_ep09_m2': _gears(season2GearBoards['s2_ep09_m2']!, 'T1, T2 and T3 turn together; the garden clock never moves.')},
  makerMarks: {
    's2_ep09_m3': _plan(season2MakerMarksScenes['s2_ep09_m3']!, const {
      'a:repair': 'Does that look like a gear?',
      'a:key': 'Does that look like a gear?',
      'b:emblem': 'Count the hands there.',
      'b:key': 'A key, not two hands. Look again.',
    }),
  },
  towerTests: {
    's2_ep09_final': _tower(
      season2TowerTests['s2_ep09_final']!,
      hours: const {
        5: 'That is forward, not back.',
        2: 'Too far: that is two hours back.',
        4: 'The tower still reads four. One hour back, please.',
        0: 'Only a single hour back, from 4 to 3.',
      },
      tested: const ['The tower now reads three.', 'T1, T2 and T3 followed it. The garden clock still reads four.'],
      after: const ['A model can show what might happen. What truly happened is another matter.', 'Perhaps the records will tell.'],
      question: 'Which trial clock bears the star?',
      other: 'Check the sign on its base. Only one shows a star.',
      found: 'The star sits beneath T1.',
      done: const ['T1 belongs to the Arc de Triomphe.', 'Twelve roads meet there, spreading out like a star.', 'Perhaps the real records are kept there.'],
    ),
  },
);

// ═════════════════════════════════════════════════════════════════════════
// The learning design
// ═════════════════════════════════════════════════════════════════════════

final juniorLearning09 = <String, LearningObjective>{
  's2_ep09_m1': levelObjective('s2_ep09_m1', [_putBack, 'find that shape on the map']),
  's2_ep09_m2': levelObjective('s2_ep09_m2', [_join, 'Which gear fits it?']),
  's2_ep09_m3': levelObjective('s2_ep09_m3', ['Find the same two marks on the old paper', 'Signed with two clock hands.']),
  's2_ep09_final': levelObjective('s2_ep09_final', ['Set the tower one hour back.', 'Only the joined clocks went wrong.', 'What happened to the clocks?']),
};

final masterLearning09 = <String, LearningObjective>{
  's2_ep09_m1': levelObjective('s2_ep09_m1', [_putBack, 'Each little clock copies a building']),
  's2_ep09_m2': levelObjective('s2_ep09_m2', [_join, 'Connect the tower to the trial clocks']),
  's2_ep09_m3': levelObjective('s2_ep09_m3', ['Find where both marks appear on the old paper', 'Signed with two clock hands.']),
  's2_ep09_final': levelObjective('s2_ep09_final', ['Set the tower one hour back.', 'Only the joined clocks went wrong.', 'What did the test show?']),
};
