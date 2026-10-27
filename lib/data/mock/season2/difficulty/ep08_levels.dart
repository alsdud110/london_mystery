import '../../../models/abbesses_puzzles.dart';
import '../../../models/learning.dart';
import '../season2_case08_scenes.dart';
import 'level_words.dart';

// Case 08 — The Painter's Last Sketch, at each level (PART 7C): the words only
// (`docs/difficulty_reviews/PARIS_CASE_07_09.md`).
// What Cases 07–09 keep the same, and untold, at every level: ep07_levels.dart.

const words08 = {'pyramid': '피라미드', 'entrance': '입구', 'amendment': '수정', 'matching': '일치하는'};
const _familiar = {'familiar': '익숙한'};
const _everywhere = {'everywhere': '어디에나'};
const juniorWords08 = {'arriving': '도착하는, 나타나는', 'placed': '놓인', 'pencil': '연필', 'carefully': '주의 깊게'};
const masterWords08 = {
  'witness': '목격하다',
  'witnessed': '목격했다',
  'shifts': '움직인다, 달라진다',
  'bound': '묶인',
  'identical': '똑같은',
  'supports': '뒷받침하다',
  'ringed': '둘러싸인',
  'stuffed': '가득 채운',
  'untying': '푸는',
  'figure': '사람의 모습',
  'daylight': '햇빛, 낮',
};

const rookieWords08 = {...words08, ..._everywhere, ..._familiar};

const _sketchNote =
    'The sketch he hid in his studio:\n'
    'Steps. An old lamp. A gate between two pillars.\n'
    'The white church above.';
const _tag =
    'I drew this corner one morning.\n'
    'First, the sky was dark.\n'
    'Then it grew light.\n'
    'When the sun came up, the lamps went out.\n'
    '— P.';
const _note = 'I found this paper on the steps.\nI kept it with my drawings.\n— P.';
const _evidenceList =
    'THE BAG SKETCH\n'
    'A paper lies on the steps after the bag goes by.\n\n'
    'THE MATCHING SEAL\n'
    'A torn paper. The same form and seal as the opera slip.\n\n'
    'THE AMENDMENT SLIP\n'
    'FILE 3 · CURTAIN UP: 4:00 to 3:00.';
const _sayNow = 'What can you say now?';
const _knewTheBag = 'Under it: P. KNEW THE BAG.';

/// The final board's lines for each wrong link (keys: the answers, as the
/// base has them).
Map<String, String> _boardLines({
  required String q1e1,
  required String q1One,
  required String q1e3,
  required String q1e4,
  required String q2e3,
  required String q2e4,
  required String q2e1,
  required String q2e2,
  required String q2e2e3,
  required String q2e1e3,
  required String q2Two,
  required String why,
  required String parts,
  required String painter,
  required String who,
}) =>
    {
      'q1:e1': q1e1,
      'q1:e1+e2': q1One,
      'q1:e3': q1e3,
      'q1:e4': q1e4,
      'q1:e2+e3': q1One,
      'q1:e2+e4': q1One,
      'q2:e3': q2e3,
      'q2:e4': q2e4,
      'q2:e1': q2e1,
      'q2:e2': q2e2,
      'q2:e2+e3': q2e2e3,
      'q2:e1+e3': q2e1e3,
      'q2:e1+e3+e4': q2Two,
      'q2:e2+e3+e4': q2Two,
      'why:': why,
      'why:parts': parts,
      'why:painter': painter,
      'why:who': who,
    };

const rookie08 = <String, Object?>{'glossary': rookieWords08};

final junior08 = <String, Object?>{
  'synopsis': [
    'On the back of the opera slip: P. KNEW THE BAG.',
    'P. is the painter who went away on his own.',
    'He said he saw who took the hour. But what did he really see?',
  ],
  'objectives': ['Find the spot where the painter sat.', 'Look closely at his drawings.', 'Find out what P. really saw.'],
  'intro': [
    'You turn the opera slip over once more.',
    'There is a tiny sketch: steps, a lamp and a metro sign. ABBESSES.',
    _knewTheBag,
    'P. is the painter. He once said: I saw who took the hour.',
    'Which bag? And what did he see?',
    "Abbesses is up on the hill of Montmartre. Let's go there.",
  ],
  'caseSummary': 'P. saw the bag, and a paper for changing a time fell from it. Later, he drew the same bag in a garden.',
  'hook': 'Why was the bag beside the little clock in the garden?',
  'glossary': {...words08, ..._everywhere, ...juniorWords08},
  'missions': {
    's2_ep08_m1': {
      'story': ['Abbesses. There are steps, lamps and gates everywhere.', 'Where did the painter sit when he drew?'],
      'letterIntro': 'Your notebook says:',
      'letter': _sketchNote,
      'question': 'Which corner did the painter draw from?',
      'hints': [
        "Take the painter's hidden sketch from your notebook and compare it with each corner.",
        'Look at which side the lamp is on. The sketch is in pencil, so read its words for colours.',
      ],
      'successMessage': 'This is where the painter sat!',
      'transition': [
        "The lamp is on the left and the gate is black. This is the painter's corner.",
        'One stone in the left pillar moves.',
        'Behind the stone is a bundle of drawings tied with string.',
      ],
      'options': {
        'corner1': {'feedback': 'The steps and the lamp are right. Now read the words with the sketch. What colour should the gate be?'},
        'corner3': {'feedback': 'Check the sketch again. Should the lamp be left of the gate, or right?'},
      },
      'recall': {
        'title': 'Have you seen these steps before?',
        'prompt': 'Find the drawing that the painter hid.',
        'feedback': {
          's2_ep07_e3': 'That sketch led you here. Find the one he hid in his studio.',
          's2_ep02_e1': 'That street has a red door. You need steps and a gate.',
          's2_ep02_e4': 'That message was on the back of a canvas. Find the sketch that was under the paint.',
        },
      },
      'clue': {'note': 'This is the corner from his hidden sketch. His drawings were behind a loose stone.'},
      'evidence': {'description': 'The corner in Abbesses where the painter sat to draw.'},
    },
    's2_ep08_m2': {
      'story': ['You untie the string and find three drawings of this corner.', 'The steps, the lamp and the gate are the same. But something changes.'],
      'letterIntro': 'A tag tied to the string says:',
      'letter': _tag,
      'question': 'How did the paper get onto the steps?',
      'hints': [
        "Use P.'s tag to put the drawings in order: dark sky first, lamps out last.",
        'Find the drawing where the paper first appears. Who was on the steps just before it?',
      ],
      'successMessage': 'It came from the bag!',
      'transition': [
        'In drawing 2, someone carries a flat bag full of papers.',
        'In drawing 3, the person is gone, and a paper lies on the steps.',
        'The paper must have fallen from the bag.',
        "P. also drew the bag's badge: a small shield with leaves around it.",
        'But he drew no face. Only a hat and a back.',
      ],
      'options': {
        'always': {'feedback': 'Check drawings 1 and 2. Can you see a paper on the steps?'},
        'painter': {'feedback': 'The painter was sitting across the street, far from the steps.'},
        'window': {'feedback': 'Look at drawing 2. Who was on the steps just before the paper appeared?'},
      },
      'clue': {'note': 'The bag went up the steps, and then a paper was there.'},
      'evidence': {'description': "Three drawings of one morning, drawn from the painter's corner."},
    },
    's2_ep08_m3': {
      'story': ['Behind the drawings, there is one more paper, folded small.', 'It is not a drawing. There is a note clipped to it.'],
      'letterIntro': "P.'s note reads:",
      'letter': _note,
      'question': 'What matches the opera slip, and what is missing?',
      'hints': [
        'Take the opera slip from your notebook and put it next to this paper.',
        'Count the hands on the seal. Then compare FILE and the times on both papers.',
      ],
      'successMessage': 'It has the same seal!',
      'transition': [
        'It is the same kind of form, with the same purple seal.',
        'But the FILE number and the hour have been torn away.',
        'Just like the opera slip, it is a paper for changing a time.',
        'P. found it on the steps. Is it the paper from his drawing?',
      ],
      'feedback': {
        'need:same': 'Four things on this paper look just like the opera slip.',
        'need:seal': 'Look carefully at the seal. How many hands does it have?',
        'need:hour': 'Read the times on the opera slip. What number comes before :00?',
        'need:number': 'The opera slip says FILE 3. What comes after FILE on this paper?',
      },
      'recall': {
        'title': 'Do you know this seal?',
        'prompt': 'Find the slip you found at the opera.',
        'feedback': {
          's2_ep01_e3': 'That mark is a gear. Does this seal look like a gear?',
          's2_ep05_e1': 'That mark has two hands. This seal has none.',
          's2_ep07_e4': 'That is FILE 3. Find the small slip that asked for the change.',
          's2_ep06_e4': 'That is Letter 4417. You need the paper with a purple seal.',
        },
      },
      'clue': {'note': 'It has the same form and seal as the opera slip. The FILE number and the hour are torn away.'},
      'evidence': {'description': 'A torn, folded paper that P. kept with his drawings.'},
    },
    's2_ep08_final': {
      'story': ["You sit in the painter's place with drawing 3 and the torn paper.", 'Is it the same paper? And what does it tell us?'],
      'letterIntro': 'Here is your evidence:',
      'letter': _evidenceList,
      'question': _sayNow,
      'hints': [
        'Start by turning the paper until its V-shaped tear matches the drawing.',
        'One piece of evidence shows where the paper came from. Two others show what kind of paper it is.',
      ],
      'successMessage': 'The paper fell from the bag!',
      'transition': [
        'The paper fell out of the bag.',
        'Like the opera slip, it is a paper for changing a time.',
        'But who carried the bag? P. never drew a face.',
        'And why was the bag next to a little clock in a garden?',
        'Next stop: the Luxembourg Gardens!',
      ],
      'feedback': _boardLines(
        q1e1: 'That shows where P. sat. Which drawings show the paper arriving?',
        q1One: 'Question 1 needs just one piece: the drawings of that morning.',
        q1e3: 'That is the paper itself. Which drawings show where it came from?',
        q1e4: 'That slip was found at the opera. Which drawings show where this paper came from?',
        q2e3: 'What is a paper with this seal for? Which older clue shows that?',
        q2e4: 'The slip shows what this kind of form is for. Now add the paper itself.',
        q2e1: 'That shows where P. sat. Look at the paper and the opera slip instead.',
        q2e2: 'The drawings show where the paper came from, not what kind it is.',
        q2e2e3: 'The drawings show where it came from. Which older clue shows what the form is for?',
        q2e1e3: 'That shows where P. sat. Which older clue shows what the form is for?',
        q2Two: 'Question 2 needs just two pieces: the paper and the opera slip.',
        why: 'Now choose what the evidence shows.',
        parts: 'What fell from the bag: a clock part or a paper?',
        painter: 'The painter was busy drawing. Who walked up the steps?',
        who: 'Did P. draw a face or write a name? What do we really know?',
      ),
      'evidence': {'description': "The torn paper, placed on P.'s drawing of the steps."},
    },
  },
};

final master08 = <String, Object?>{
  'synopsis': [
    'The opera slip bears four words: P. KNEW THE BAG.',
    'P. is the painter who slipped away from Montmartre.',
    'He claimed he saw who took the hour. What exactly did he witness?',
  ],
  'objectives': ['Track down where the painter sat to draw.', 'Study his drawings.', 'Work out what P. witnessed.'],
  'intro': [
    'Once again, you turn the opera slip over.',
    'A tiny sketch of steps, a lamp and a metro sign: ABBESSES.',
    _knewTheBag,
    'P. is the painter, the one who said: I saw who took the hour.',
    'What bag? And what did he truly see?',
    'Abbesses sits high on the hill of Montmartre. Time to go.',
  ],
  'caseSummary': 'P. watched the bag pass, and a paper for changing a time fell from it. Later he sketched that bag again, in a garden.',
  'hook': 'What drew the bag to the little clock in the garden?',
  'glossary': {...words08, ..._familiar, ...masterWords08},
  'missions': {
    's2_ep08_m1': {
      'story': ['Abbesses: steps, lamps and gates wherever you look.', 'From which corner did the painter draw?'],
      'letterIntro': 'Your notebook describes it:',
      'letter': _sketchNote,
      'question': 'From which corner did the painter make his sketch?',
      'hints': [
        'The hidden sketch in your notebook is your guide. Hold it up to each corner.',
        'Mind the side the lamp stands on, and since the sketch has no colour, trust its words.',
      ],
      'successMessage': "The painter's corner, found!",
      'transition': [
        "Lamp on the left, gate painted black: the painter's very corner.",
        'One stone in the left pillar shifts under your hand.',
        'Behind it lies a bundle of drawings, bound with string.',
      ],
      'options': {
        'corner1': {'feedback': "Steps and lamp agree, but the sketch's words name the gate's colour. Does this one match?"},
        'corner3': {'feedback': 'Where does the sketch place the lamp: left of the gate, or right?'},
      },
      'recall': {
        'title': 'These steps seem strangely familiar...',
        'prompt': 'Find the sketch the painter hid away.',
        'feedback': {
          's2_ep07_e3': 'That sketch only brought you here. The one you need was hidden in his studio.',
          's2_ep02_e1': 'A red door belongs to another street. Look for steps and a gate.',
          's2_ep02_e4': 'That message came from the back of a canvas. The sketch you want lay beneath the paint.',
        },
      },
      'clue': {'note': 'The corner of his hidden sketch, where his drawings lay behind a loose stone.'},
      'evidence': {'description': 'The corner of Abbesses from which the painter drew.'},
    },
    's2_ep08_m2': {
      'story': [
        'Untying the string, you find three drawings of this very corner.',
        'Steps, lamp and gate stay the same, yet something shifts from one to the next.',
      ],
      'letterIntro': 'A tag on the string reads:',
      'letter': _tag,
      'question': 'What brought the paper to the steps?',
      'hints': [
        "P.'s tag gives the order: darkness, then light, then the lamps going out.",
        'The paper appears at one moment. What happened on the steps just before?',
      ],
      'successMessage': 'The bag dropped the paper!',
      'transition': [
        'Drawing 2: a figure with a flat bag, stuffed with papers.',
        'Drawing 3: the figure has gone, and a paper lies on the steps.',
        'The bag must have dropped it.',
        "P. even sketched the bag's badge: a small shield ringed with leaves.",
        'Yet there is no face. Only a hat, and a back turned away.',
      ],
      'options': {
        'always': {'feedback': 'In drawings 1 and 2, is there any paper on the steps?'},
        'painter': {'feedback': 'The painter sat across the street, nowhere near the steps.'},
        'window': {'feedback': 'Drawing 2 shows who climbed those steps just before the paper appeared.'},
      },
      'clue': {'note': 'First the bag went up the steps; then a paper lay there.'},
      'evidence': {'description': "Three drawings of a single morning, made from the painter's corner."},
    },
    's2_ep08_m3': {
      'story': ['Behind the drawings lies one more paper, folded tightly.', 'This one is no drawing. A note is clipped to it.'],
      'letterIntro': "In P.'s own hand:",
      'letter': _note,
      'question': 'What does this paper share with the opera slip, and what has it lost?',
      'hints': [
        'Lay the opera slip from your notebook beside this paper.',
        'Compare them part by part: the seal, the FILE band and the times.',
      ],
      'successMessage': 'An identical seal!',
      'transition': [
        'The same form, and the same purple seal.',
        'Yet the FILE number and the hour are torn away.',
        'Like the opera slip, it was made for changing a time.',
        'P. found it on the steps. Could it be the very paper in his drawing?',
      ],
      'feedback': {
        'need:same': 'Four features of this paper match the opera slip exactly.',
        'need:seal': 'Examine the seal. How many hands does its clock have?',
        'need:hour': 'On the opera slip, a number stands before :00. What stands there on this paper?',
        'need:number': 'The opera slip reads FILE 3. What follows FILE here?',
      },
      'recall': {
        'title': 'Where have you seen this seal before?',
        'prompt': 'Find the slip from the opera house.',
        'feedback': {
          's2_ep01_e3': 'That mark is a gear; this seal is no gear.',
          's2_ep05_e1': 'That mark has two hands; this seal has none at all.',
          's2_ep07_e4': 'That is FILE 3 itself. You want the small slip that ordered the change.',
          's2_ep06_e4': 'That is Letter 4417. Seek the paper with a purple seal.',
        },
      },
      'clue': {'note': "The opera slip's form and seal, but with the FILE number and the hour torn off."},
      'evidence': {'description': "A torn, folded paper, tucked among P.'s drawings."},
    },
    's2_ep08_final': {
      'story': ["From the painter's own seat, you hold drawing 3 beside the torn paper.", 'Are they the same paper? And if so, what does it reveal?'],
      'letterIntro': 'The evidence you have gathered:',
      'letter': _evidenceList,
      'question': _sayNow,
      'hints': [
        'Turn the paper until its V-shaped tear lines up with the drawing.',
        'Ask what each piece of evidence proves: where the paper came from, or what it is.',
      ],
      'successMessage': 'The torn paper came from the bag!',
      'transition': [
        'The paper slipped from the bag.',
        'Like the opera slip, it was meant for changing a time.',
        'Yet whose hand carried the bag? P. never drew a face.',
        'And why would the bag stand beside a little clock in a garden?',
        'The trail now leads to the Luxembourg Gardens!',
      ],
      'feedback': _boardLines(
        q1e1: 'That only shows where P. sat. Which evidence shows the paper arriving?',
        q1One: 'One piece answers Question 1: the drawings of that morning.',
        q1e3: 'That is the paper itself, not where it came from.',
        q1e4: 'That slip belongs to the opera. Where did this paper come from?',
        q2e3: 'The paper alone cannot say what it is for. Which older clue can?',
        q2e4: 'The slip explains the form. Now add the paper itself.',
        q2e1: 'That is where P. sat. The paper and the opera slip matter here.',
        q2e2: 'The drawings say where it came from, not what it is.',
        q2e2e3: 'Drop the drawings. Which older clue explains the form?',
        q2e1e3: 'Drop the corner. Which older clue explains the form?',
        q2Two: 'Two pieces answer Question 2: the paper and the opera slip.',
        why: 'Choose the conclusion the evidence supports.',
        parts: 'Was it a clock part that fell from the bag, or a paper?',
        painter: 'The painter sat drawing. Someone else climbed the steps.',
        who: 'P. drew no face and wrote no name. What do we truly know?',
      ),
      'evidence': {'description': "The torn paper, laid over P.'s drawing of the steps."},
    },
  },
};

// ═════════════════════════════════════════════════════════════════════════
// The scenes' own words
// ═════════════════════════════════════════════════════════════════════════

/// The three drawings: what is said when they are put out of order, once
/// they are in order, and the question after them (the mission's own, at
/// its level). The drawings and every way to play are the base's.
MorningSketchesScene _morning(MorningSketchesScene b, {required String lamp, required String sky, required String ordered, required String question}) =>
    MorningSketchesScene(
      sketches: b.sketches,
      shown: b.shown,
      lampOff: b.lampOff,
      slots: b.slots,
      orderTask: b.orderTask,
      checkOrderLabel: b.checkOrderLabel,
      lampLine: lamp,
      skyLine: sky,
      orderedLine: ordered,
      compareTask: b.compareTask,
      questionTask: question,
    );

/// The torn form: what its folds, tear and dust say when tapped, and the
/// seal's lines for a wrong answer. The form, its parts and the seal's
/// questions are the base's.
TornSlipScene _slip(TornSlipScene b, {required Map<String, String> partLines, required List<String> sealWrong}) => TornSlipScene(
      folded: b.folded,
      foldedPixels: b.foldedPixels,
      form: b.form,
      parts: [
        for (final p in b.parts) FormPart(id: p.id, area: p.area, mark: p.mark, name: p.name, line: p.line == null ? null : partLines[p.id]!),
      ],
      sealId: b.sealId,
      sealChecks: [
        for (final (i, c) in b.sealChecks.indexed) SealCheck(question: c.question, choices: c.choices, answer: c.answer, wrongLine: sealWrong[i]),
      ],
      folds: b.folds,
      unfoldTask: b.unfoldTask,
      sameTask: b.sameTask,
      missingTask: b.missingTask,
      checkLabel: b.checkLabel,
      sealTitle: b.sealTitle,
      noteLines: b.noteLines,
    );

/// The final at P.'s corner: what is said as the paper is laid on the
/// drawing, and of his last drawing and its garden. The board, the drawing
/// and the map are the base's.
TornHourScene _corner(
  TornHourScene b, {
  required String heading,
  required String tear,
  required String seal,
  required String off,
  required List<String> placed,
  required Map<String, String> bagLines,
  required List<String> bagDone,
  required Map<String, String> placeLines,
  required String other,
  required List<String> done,
}) {
  final l = b.lead;
  LeadPart part(LeadPart p) => LeadPart(id: p.id, area: p.area, line: bagLines[p.id]!);
  return TornHourScene(
    sketch: b.sketch,
    form: b.form,
    startTurns: b.startTurns,
    board: b.board,
    lead: NextLead(
      file: l.file,
      pixels: l.pixels,
      label: l.label,
      bagParts: [for (final p in l.bagParts) part(p)],
      decoy: part(l.decoy),
      bagTask: l.bagTask,
      bagDone: bagDone,
      features: l.features,
      mapFile: l.mapFile,
      mapPixels: l.mapPixels,
      spots: l.spots,
      answer: l.answer,
      feedback: {for (final k in l.feedback.keys) k: placeLines[k]!},
      otherLine: other,
      mapTask: l.mapTask,
      chooseLabel: l.chooseLabel,
      doneLines: done,
    ),
    placeHeading: heading,
    placeTask: b.placeTask,
    turnLabel: b.turnLabel,
    layLabel: b.layLabel,
    tearLine: tear,
    sealLine: seal,
    offLine: off,
    placedLines: placed,
    leadLabel: b.leadLabel,
  );
}

/// Case 08's scenes with Junior's words.
final juniorScenes08 = (
  morningSketches: {
    's2_ep08_m2': _morning(
      season2MorningSketches['s2_ep08_m2']!,
      lamp: 'This lamp is already out. Can this drawing come before the others?',
      sky: 'Compare the skies. Which one is darker?',
      ordered: 'First dark, then light, and then the lamp goes out.',
      question: 'How did the paper get onto the steps?',
    ),
  },
  tornSlips: {
    's2_ep08_m3': _slip(
      season2TornSlips['s2_ep08_m3']!,
      partLines: const {
        'foldAcross': 'Those are just folds. P. folded the paper small.',
        'foldDown': 'Those are just folds. P. folded the paper small.',
        'tear': 'The opera slip has no tear. Is this part the same?',
        'dust': 'That is only dust from the steps.',
      },
      sealWrong: const ['Look again. Can you see any hands on this clock?', 'Look at what makes the ring around the clock.'],
    ),
  },
  tornHours: {
    's2_ep08_final': _corner(
      season2TornHours['s2_ep08_final']!,
      heading: 'Is this the same paper?',
      tear: 'Find the V-shaped tear. Where is it in the drawing?',
      seal: 'Can you find the round seal in the drawing?',
      off: 'P. drew the paper large in the corner. Put it there.',
      placed: const ['The tear, the folds and the seal are all the same.', 'This is the paper from the steps.'],
      bagLines: const {
        'flat': 'It is the same flat bag.',
        'buckles': 'It has the same two buckles.',
        'badge': 'It has the same shield badge.',
        'basket': 'That is only a round basket. The bag in your notebook is flat.',
      },
      bagDone: const ['P. saw the same bag again, in a garden.'],
      placeLines: const {
        'louvre': 'There is a palace. But the drawing has no glass pyramid. Is there a round pond?',
        'palaisGarnier': 'That is the opera house. Does it have a garden with a round pond?',
        'montmartre': 'That is the white church. Can you see a palace there?',
      },
      other: 'Find a place with a palace, a round pond and flowerbeds.',
      done: const [
        'The Luxembourg Gardens!',
        'In the drawing, a little clock stands on the grass, with tiny roofs all around it.',
        'Why was the bag next to a little clock in a garden?',
      ],
    ),
  },
);

/// Case 08's scenes with Master's words.
final masterScenes08 = (
  morningSketches: {
    's2_ep08_m2': _morning(
      season2MorningSketches['s2_ep08_m2']!,
      lamp: 'The lamp here has gone out. Could this drawing come before the rest?',
      sky: 'Study the skies. Which is the darker one?',
      ordered: 'Darkness, then daylight, and at last the lamp goes out.',
      question: 'What brought the paper to the steps?',
    ),
  },
  tornSlips: {
    's2_ep08_m3': _slip(
      season2TornSlips['s2_ep08_m3']!,
      partLines: const {
        'foldAcross': 'Only folds: P. folded the paper tightly.',
        'foldDown': 'Only folds: P. folded the paper tightly.',
        'tear': 'The opera slip is whole. Can a tear be the same?',
        'dust': 'Just dust, from the steps.',
      },
      sealWrong: const ['Look once more. Does this clock have a single hand?', 'Study the ring that circles the clock.'],
    ),
  },
  tornHours: {
    's2_ep08_final': _corner(
      season2TornHours['s2_ep08_final']!,
      heading: 'Could it be the same paper?',
      tear: 'Match the V-shaped tear. Where does the drawing show it?',
      seal: 'Where does the round seal sit in the drawing?',
      off: 'P. drew the paper large in the corner. Lay it over that.',
      placed: const ['Tear, folds and seal: every detail matches.', 'This is the very paper from the steps.'],
      bagLines: const {
        'flat': 'Flat, just like the bag in the sketch.',
        'buckles': 'Two buckles, just the same.',
        'badge': 'The very same shield badge.',
        'basket': 'A round basket, not a bag. The one in your notebook is flat.',
      },
      bagDone: const ['P. saw the bag once more, this time in a garden.'],
      placeLines: const {
        'louvre': 'A palace, yes. But where is the glass pyramid? And the round pond?',
        'palaisGarnier': 'That is the opera house. Where would its garden and round pond be?',
        'montmartre': 'That is the white church. No palace stands there.',
      },
      other: 'Search for a palace, a round pond and flowerbeds together.',
      done: const [
        'The Luxembourg Gardens!',
        'In the drawing, a little clock rises from the grass, surrounded by tiny roofs.',
        'Why would the bag stand beside a little clock in a garden?',
      ],
    ),
  },
);

/// Case 08's scenes whose words are the same at every level (see
/// `season2SameAtEveryLevel`).
const sameAtEveryLevel08 = {
  'cornerChoices/s2_ep08_m1',
};

// ═════════════════════════════════════════════════════════════════════════
// The learning design
// ═════════════════════════════════════════════════════════════════════════

final juniorLearning08 = <String, LearningObjective>{
  's2_ep08_m1': levelObjective('s2_ep08_m1', ['A gate between two pillars.', 'Which corner did the painter draw from?']),
  's2_ep08_m2': levelObjective('s2_ep08_m2', ['First, the sky was dark.', 'When the sun came up, the lamps went out.', 'How did the paper get onto the steps?']),
  's2_ep08_m3': levelObjective('s2_ep08_m3', ['What matches the opera slip, and what is missing?', 'I found this paper on the steps.']),
  's2_ep08_final': levelObjective('s2_ep08_final', ['Where did the paper come from?', 'What kind of paper is it?', 'One piece of evidence shows where the paper came from']),
};

final masterLearning08 = <String, LearningObjective>{
  's2_ep08_m1': levelObjective('s2_ep08_m1', ['A gate between two pillars.', 'From which corner did the painter make his sketch?']),
  's2_ep08_m2': levelObjective('s2_ep08_m2', ['First, the sky was dark.', 'When the sun came up, the lamps went out.', 'What brought the paper to the steps?']),
  's2_ep08_m3': levelObjective('s2_ep08_m3', ['What does this paper share with the opera slip', 'I found this paper on the steps.']),
  's2_ep08_final': levelObjective('s2_ep08_final', ['Where did the paper come from?', 'What kind of paper is it?', 'Ask what each piece of evidence proves']),
};
