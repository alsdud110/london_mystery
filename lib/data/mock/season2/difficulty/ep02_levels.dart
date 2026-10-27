import '../../../models/investigation.dart' show InvestigationSpot;
import '../../../models/learning.dart';
import '../../../models/painter_puzzles.dart';
import '../season2_scenes.dart';
import 'level_words.dart';

// Case 02 — The Vanishing Painter, at each level (PART 7A): the words only
// (`docs/difficulty_reviews/PARIS_CASE_01_03.md`).

const _words02 = {
  'pinned': '핀으로 꽂힌',
  'tucked': '끼워 넣은',
  'narrow': '좁은',
  'square': '광장',
  'uncovered': '드러난, 덮개를 벗긴',
  'atelier': '작업실 (프랑스어)',
  'toujours': '항상 (프랑스어)',
};

/// "in the same hand" (Rookie's page; Junior and Master say handwriting).
const _rookieOnly02 = {'hand': '손; (in the same hand) 같은 사람의 글씨로', ..._alike};

/// "They look alike" (Rookie's and Junior's pages; Master's are identical).
const _alike = {'alike': '비슷한'};

/// The painter's three notes, their headings as he wrote them (the same at
/// every level: the matching is read from them).
const _rain = 'A — I painted this BEFORE THE RAIN.\n';
const _after = 'B — I painted this AFTER THE RAIN STOPPED.\n';
const _gold = 'C — I painted this WHEN THE SKY TURNED GOLD.\n';

/// The note on the easel: what to slide and what to look under.
const _sketchNote =
    'I painted over my sketch.\n'
    'Slide the paint away\n'
    'and look UNDERNEATH.\n\n';

/// What the notebook keeps of the three clues (their evidence's names).
const _yourClues =
    'YOUR CLUES\n\n'
    'THE PAINTED STREET\n'
    'Not the street with the red door.\n\n'
    "THE ARTIST'S NOTES\n"
    'I hid my secret on a blue-sky day.\n\n'
    'THE HIDDEN SKETCH\n'
    'Steps, a lamp and a black gate.\n\n';

/// After the case: his studio, his words and what the evidence says of
/// him, in that order. The line Case 03 begins from (TOUJOURS PLUS HAUT),
/// his own words and the case's last line stay as they are.
List<String> _painterGone({
  required String below,
  required String brassBox,
  String found = 'He hid his own sketch. He left his notes for you.',
  String onHisOwn = 'He left on his own.',
}) => [
      'On the back: ATELIER MONTMARTRE, his studio.',
      'And three French words: TOUJOURS PLUS HAUT. Always higher.',
      below,
      'A city can lose an hour.\nBut who can steal it?',
      '"I saw who took the hour. I went away to keep the secret safe. — P."',
      found,
      brassBox,
      onHisOwn,
      'But someone is still stealing the hours of Paris.',
    ];

const rookie02 = <String, Object?>{'glossary': {..._words02, ..._rookieOnly02}};

final junior02 = <String, Object?>{
  'synopsis': [
    'The painting from the brass box shows Montmartre.',
    'On the back, someone wrote: FIND THE PAINTER.',
    'But the painter has disappeared. Does he know who took the hour?',
  ],
  'objectives': [
    'Find the street from the painting.',
    "Search the painter's studio for clues.",
    'Find the message he left behind.',
  ],
  'intro': [
    'Montmartre, a hill high above Paris.',
    'The lost ticket said MONTMARTRE, and the painting shows this hill.',
    'On its back: FIND THE PAINTER.',
    'Who is he? And why was his painting hidden under an old clock?',
  ],
  'caseSummary': "You followed three of the painter's clues to his hidden message.",
  'hook': 'Nobody took the painter. He went away to keep a secret. But who took the hour?',
  'glossary': {
    ..._words02,
    ..._alike,
    'disappeared': '사라졌다',
    'exactly': '정확히',
    'followed': '따라갔다',
    'empty': '비어 있는',
    'trunk': '큰 상자, 트렁크',
    'drawer': '서랍',
    'crate': '나무 상자',
    'smock': '작업복',
    'palette': '팔레트',
    'appears': '나타나다',
    'handwriting': '손글씨, 필체',
    'row': '줄',
  },
  'missions': {
    's2_ep02_m1': {
      'story': [
        'Near the white church is a quiet street with a red door, stone steps and an old lamp.',
        'On the corner stands an easel with a painting of this street. But nobody is painting.',
      ],
      'letterIntro': 'Someone has pinned a note to the painting:',
      'letter':
          'I did not paint this street exactly as it is.\n'
          'I changed three things.\n\n'
          'Look above the red door.\n'
          'Find the window that is missing.\n'
          'Check the lamp beside the steps.\n\n'
          '— P.',
      'question': 'Find the three things he changed.',
      'hints': [
        'Each line of the note tells you where to look. Read them one by one.',
        'ABOVE means higher up. MISSING means it is not there. BESIDE means right next to.',
      ],
      'successMessage': 'You found all three changes!',
      'transition': [
        'You turn his note over. There is one more line:',
        '"My secret is not on this street. Look far from the red door."',
        'You find a key under the easel. Its tag says: STUDIO, TOP FLOOR.',
      ],
      'clue': {'note': 'On the back of his note: "My secret is not on this street. Look far from the red door."'},
      'evidence': {'description': 'Left on the easel at the corner of the street.'},
    },
    's2_ep02_m2': {
      'story': [
        'The key opens a door at the top of some narrow stairs.',
        'Sunlight. The smell of paint. But the studio is empty.',
      ],
      'letterIntro': 'There are three notes on his desk:',
      'letter':
          '${_rain}Dark clouds were coming, but the stones were still dry.\n\n'
          '${_after}The stones were wet and shiny. A few dark clouds were still in the sky.\n\n'
          '${_gold}The whole sky was gold, with no dark clouds. The stones were dry.',
      'question': 'Which painting goes with each note? Match them.',
      'feedback': {
        'a:p1': 'Look at note A again. Can you see the dark clouds in this painting?',
        'a:p3': 'Look at note A again. BEFORE THE RAIN, the stones were still dry.',
        'b:p1': 'Look at note B again. AFTER THE RAIN, the stones are wet and shiny.',
        'b:p2': 'Look at note B again. AFTER THE RAIN, the stones are wet and shiny.',
        'c:p2': 'Look at note C again. Is the whole sky gold here?',
        'c:p3': 'Look at note C again. There are no dark clouds, and the stones are dry.',
      },
      'hints': [
        'Each note says WHEN he painted it. Look at the clouds and the stones in each painting.',
        'BEFORE THE RAIN: dry stones. AFTER THE RAIN: wet, shiny stones. Which one has a gold sky and no clouds?',
      ],
      'successMessage': 'Each note has its painting!',
      'transition': [
        'Under note C, there is one more line in pencil:',
        '"My secret is not in a gold sky. I hid it on a blue-sky day."',
        'By the window, a big easel holds a canvas covered in thick paint.',
      ],
      'clue': {'note': 'Written under note C: "My secret is not in a gold sky. I hid it on a blue-sky day."'},
      'evidence': {'description': 'Found on his desk, next to his paintings of one square.'},
    },
    's2_ep02_m3': {
      'story': [
        'The canvas is covered in thick paint: blue, red and yellow. There is no picture at all.',
        'Why would a painter do that?',
      ],
      'letterIntro': 'Someone has tucked a note into the frame:',
      'letter':
          '$_sketchNote'
          'My pencil has no colours,\n'
          'so remember this: the gate is black.\n\n'
          '— P.',
      'question': 'Find the lamp, the steps and the gate in the sketch.',
      'hints': [
        'First, slide the paint away. The sketch is hidden underneath.',
        'The lamp is tall and thin. The steps are at the bottom. The gate stands between two pillars.',
      ],
      'successMessage': 'You uncovered the sketch!',
      // The three questions after a find, as at every level.
      'transition': [
        'What changed? The painter covered his own sketch with paint.',
        'What was hidden? A place with stone steps, an old lamp and a black gate.',
        'Why does it matter? The painter hid it himself, on purpose.',
        'Against the wall, four canvases are standing in a row.',
      ],
      'clue': {'note': 'Under the paint: stone steps, an old lamp and an iron gate. The note says the gate is black.'},
      'evidence': {'description': 'Found under the thick paint on his big easel.'},
    },
    's2_ep02_final': {
      'story': [
        'Four canvases lean against the wall. They look very alike.',
        'Only one of them has a message on the back.',
      ],
      'letterIntro': 'You check your notebook:',
      'letter': '${_yourClues}Only one canvas matches all three clues.',
      'question': 'Which canvas has the message on its back?',
      'options': {
        'a': {'feedback': 'Check the clue from the painted street. Does this canvas have a red door?'},
        'b': {'feedback': "Check the artist's notes. Is this sky blue?"},
        'd': {'feedback': 'Check the hidden sketch. What colour should the gate be?'},
      },
      'hints': [
        'Check each canvas against all three clues, one by one.',
        'You need: no red door, a blue sky, and a black gate beside the steps.',
      ],
      'successMessage': 'That is the right canvas!',
      'transition': _painterGone(
        below: 'Below, in the same handwriting as FIND THE PAINTER:',
        brassBox: 'Did he also leave his painting in the brass box for you?',
      ),
      'evidence': {'description': 'Written on the back of his canvas. His note says: "I saw who took the hour."'},
    },
  },
};

final master02 = <String, Object?>{
  'synopsis': [
    'The painting from the brass box shows Montmartre.',
    'On its back, a command: FIND THE PAINTER.',
    'Yet the painter has vanished. Could he know who took the hour?',
  ],
  'objectives': [
    'Track down the street in the painting.',
    "Search the painter's deserted studio.",
    'Uncover the message he left behind.',
  ],
  'intro': [
    'Montmartre: a hill of narrow streets, high above Paris.',
    'The lost ticket read MONTMARTRE, and the painting shows this very hill.',
    'On its back: FIND THE PAINTER.',
    'But who is he? And why was his painting waiting beneath an old clock?',
  ],
  'caseSummary': "Three of the painter's clues, read together, led you to his hidden message.",
  'hook': 'Nobody took the painter. He slipped away to keep a secret safe. But who took the hour?',
  'glossary': {
    ..._words02,
    'command': '명령',
    'track': '(down) 찾아내다',
    'deserted': '텅 빈, 버려진',
    'uncover': '드러내다, 밝혀내다',
    'beneath': '~아래에',
    'slipped': '(away) 몰래 떠났다',
    'worn': '닳은',
    'nowhere': '어디에도 없는',
    'truly': '정말로',
    'seek': '찾다',
    'map': '지도',
    'points': '가리키다',
    'compare': '비교하다',
    'creaking': '삐걱거리는',
    'staircase': '계단',
    'pours': '쏟아져 들어오다',
    'side': '(by side) 나란히',
    'gathering': '모여들고 있었다',
    'yet': '그런데도, 아직',
    'gleamed': '반짝였다',
    'lingered': '남아 있었다',
    'glowed': '빛났다',
    'single': '단 하나의',
    'pair': '짝짓다',
    'describes': '묘사하다',
    'mentions': '언급하다',
    'fool': '속이다',
    'signs': '표시, 단서',
    'smothered': '두껍게 뒤덮인',
    'smothers': '두껍게 뒤덮다',
    'bury': '묻다, 덮어 감추다',
    'buried': '덮어 감췄다',
    'whatever': '무엇이든',
    'clear': '치우다',
    'search': '찾아보다',
    'climb': '오르다',
    'revealed': '드러난',
    'insists': '강조하다, 우기다',
    'identical': '똑같은',
    'glance': '흘끗 봄',
    'carries': '지니다, 가지고 있다',
    'fits': '맞다, 들어맞다',
    'rules': '(out) 제외하다',
    'fails': '맞지 않다, 실패하다',
    'survives': '끝까지 남다',
    'labelled': '이름표가 붙은',
    'spattered': '튀어 묻은',
    'dried': '말랐다',
    'strokes': '붓질',
    'elegant': '우아한',
    'climbing': '올라가는',
    'aside': '옆으로',
    'handwriting': '손글씨, 필체',
    'deliberately': '일부러, 고의로',
  },
  'missions': {
    's2_ep02_m1': {
      'story': [
        'Close to the white church lies a quiet street: a red door, worn stone steps, an old lamp.',
        'At the corner, an easel holds a painting of this very street. The painter is nowhere to be seen.',
      ],
      'letterIntro': 'A note is pinned to the corner of the painting:',
      'letter':
          'I did not paint this street as it truly is.\n'
          'Three things are different.\n\n'
          'Look above the red door.\n'
          'Seek out the window that has gone missing.\n'
          'Check the lamp beside the steps.\n\n'
          '— P.',
      'question': 'Spot the three changes the painter made.',
      'hints': [
        'The note is a map: each line points to one place. Compare that place on the street and in the painting.',
        'What sits ABOVE the door? What has gone MISSING? What looks different BESIDE the steps?',
      ],
      'successMessage': 'All three changes uncovered!',
      'transition': [
        'You turn his note over. One more line is written on the back:',
        '"My secret is not on this street. Look far from the red door."',
        'Beneath the easel lies a key. Its tag reads: STUDIO, TOP FLOOR.',
      ],
      'clue': {'note': 'Written on the back of his note: "My secret is not on this street. Look far from the red door."'},
      'evidence': {'description': 'Left behind on the easel at the corner of the street.'},
    },
    's2_ep02_m2': {
      'story': [
        'The key turns in a door at the top of a narrow, creaking staircase.',
        'Sunlight pours in. The air smells of paint. The studio is deserted.',
      ],
      'letterIntro': 'Three notes lie side by side on his desk:',
      'letter':
          '${_rain}Dark clouds were gathering, yet the stones were still dry.\n\n'
          '${_after}The stones gleamed, wet and shiny, and a few dark clouds still lingered.\n\n'
          '${_gold}The whole sky glowed gold, without a single dark cloud. The stones were dry.',
      'question': 'Pair each note with the painting it describes.',
      'feedback': {
        'a:p1': 'Note A mentions dark clouds. Do you see any here?',
        'a:p3': 'Note A was painted BEFORE THE RAIN. The stones should still be dry.',
        'b:p1': 'Note B comes AFTER THE RAIN. Look for stones that are wet and shiny.',
        'b:p2': 'Note B comes AFTER THE RAIN. Look for stones that are wet and shiny.',
        'c:p2': 'Note C describes a whole sky of gold. Is that what you see?',
        'c:p3': 'Note C has no dark clouds and dry stones. Look again.',
      },
      'hints': [
        'The sky alone can fool you. Each note gives two signs: the clouds and the stones.',
        'Wet, shiny stones can only come AFTER the rain. Which painting has dark clouds over dry stones?',
      ],
      'successMessage': 'Every note is matched to its painting!',
      'transition': [
        'Beneath note C, a final line in pencil:',
        '"My secret is not in a gold sky. I hid it on a blue-sky day."',
        'By the window, a big easel holds a canvas smothered in thick paint.',
      ],
      'clue': {'note': 'Pencilled under note C: "My secret is not in a gold sky. I hid it on a blue-sky day."'},
      'evidence': {'description': 'Lying on his desk, beside his paintings of one square.'},
    },
    's2_ep02_m3': {
      'story': [
        'Thick paint smothers the canvas: blue, red, yellow, and no picture at all.',
        'Why would a painter bury his own work?',
      ],
      'letterIntro': 'A note is tucked into the edge of the frame:',
      'letter':
          '$_sketchNote'
          'My pencil knows no colours,\n'
          'so remember: the gate is black.\n\n'
          '— P.',
      'question': 'Uncover the sketch, then find its lamp, its steps and its gate.',
      'hints': [
        'Whatever he hid lies beneath the paint. Clear it away first.',
        'Search high for something tall, low for something you climb, and between two pillars for the last.',
      ],
      'successMessage': 'The hidden sketch is revealed!',
      'transition': [
        'What changed? The painter buried his own sketch under paint.',
        'What was hidden? A place of stone steps, an old lamp and a black gate.',
        'Why does it matter? He hid it himself, deliberately.',
        'Against the wall, four canvases stand waiting.',
      ],
      'clue': {'note': 'Beneath the paint: stone steps, an old lamp and an iron gate. His note insists the gate is black.'},
      'evidence': {'description': 'Uncovered beneath the thick paint on his big easel.'},
    },
    's2_ep02_final': {
      'story': [
        'Four canvases lean against the wall, almost identical at first glance.',
        'Only one carries a message on its back.',
      ],
      'letterIntro': 'Your notebook reads:',
      'letter': '${_yourClues}Only one canvas fits every clue.',
      'question': 'Which canvas is hiding the message?',
      'options': {
        'a': {'feedback': 'Remember the painted street. A red door rules this one out.'},
        'b': {'feedback': "Remember the artist's notes. Is this the sky of a blue-sky day?"},
        'd': {'feedback': 'Remember the hidden sketch. His pencil had no colours, but his note told you the colour of the gate.'},
      },
      'hints': [
        'No single clue is enough. Test every canvas against all three.',
        'One canvas fails the street clue, one fails the sky and one fails the gate. Which one survives?',
      ],
      'successMessage': 'The right canvas at last!',
      'transition': _painterGone(
        below: 'Below it, in the same handwriting as FIND THE PAINTER:',
        found: 'He hid his own sketch, and left his notes for you to find.',
        brassBox: 'Was it he who left his painting in the brass box for you, too?',
        onHisOwn: 'Nobody took him. He left on his own.',
      ),
      'evidence': {'description': 'Written on the back of his canvas, beside his note: "I saw who took the hour."'},
    },
  },
};

// ═════════════════════════════════════════════════════════════════════════
// The scenes' own words
// ═════════════════════════════════════════════════════════════════════════

/// The street and its painting: [checklist] is the note's own lines.
CompareScene _street(CompareScene base, {required Map<String, String> found, required String missLine, Map<String, String>? checklist}) =>
    CompareScene(
      real: base.real,
      painted: base.painted,
      pixels: base.pixels,
      realLabel: base.realLabel,
      paintedLabel: base.paintedLabel,
      changes: base.changes,
      task: base.task,
      missLine: missLine,
      foundLines: {for (final id in base.foundLines.keys) id: found[id]!},
      checklist: {for (final id in base.checklist.keys) id: (checklist ?? base.checklist)[id]!},
      opening: base.opening,
    );

/// The studio: what each place says when it is searched. How to match is
/// the base's.
StudioScene _studio(
  StudioScene base, {
  required Map<String, String> paintings,
  required String desk,
  required List<String> others,
  required String missLine,
  required String deskFirstLine,
}) =>
    StudioScene(
      picture: base.picture,
      pixels: base.pixels,
      place: base.place,
      paintings: [
        for (final p in base.paintings)
          StudioPainting(id: p.id, area: p.area, mark: p.mark, file: p.file, pixels: p.pixels, label: p.label, line: paintings[p.id]!),
      ],
      order: base.order,
      desk: InvestigationSpot(label: base.desk.label, areas: base.desk.areas, line: desk),
      deskMark: base.deskMark,
      others: [for (final (i, o) in base.others.indexed) InvestigationSpot(label: o.label, areas: o.areas, line: others[i])],
      task: base.task,
      deskTask: base.deskTask,
      matchTask: base.matchTask,
      missLine: missLine,
      deskFirstLine: deskFirstLine,
      matchHow: base.matchHow,
      matchPainting: base.matchPainting,
      matchDone: base.matchDone,
      matchDrag: base.matchDrag,
      opening: base.opening,
    );

/// The painted-over sketch: how to slide is the base's.
LayerScene _easel(LayerScene base, {required Map<String, String> found, required String missLine, required String paintLine}) => LayerScene(
      paint: base.paint,
      sketch: base.sketch,
      pixels: base.pixels,
      view: base.view,
      canvas: base.canvas,
      marks: base.marks,
      paintLabel: base.paintLabel,
      sketchLabel: base.sketchLabel,
      slideTask: base.slideTask,
      findTask: base.findTask,
      missLine: missLine,
      paintLine: paintLine,
      foundLines: {for (final id in base.foundLines.keys) id: found[id]!},
    );

/// Case 02's scenes with Junior's words.
final juniorScenes02 = (
  compares: {
    's2_ep02_m1': _street(
      season2Compares['s2_ep02_m1']!,
      found: {
        'clock': 'Above the red door, the painting has a small clock. The real street has none.',
        'window': 'The street has a window here. In the painting, it is missing.',
        'lamp': 'In the painting, the lamp beside the steps is bright. On the street, it is not.',
      },
      missLine: 'This looks the same in both. Read the note again.',
    ),
  },
  studios: {
    's2_ep02_m2': _studio(
      season2Studios['s2_ep02_m2']!,
      paintings: {
        'p1': 'You open the old trunk. Inside is a painting of a square.',
        'p2': 'You open the desk drawer. Inside is a painting of a square.',
        'p3': 'You look in the crate under the desk. There is a painting of a square.',
      },
      desk: 'Three notes, marked A, B and C.',
      others: [
        'A canvas with some paint on it, but no picture yet.',
        'His straw hat and his painting smock hang on a hook.',
        'You can see the white church on the hill from here.',
        'Brushes and a palette. The paint on the palette is dry.',
        'Paintings of Paris on the wall. The white church appears again and again.',
      ],
      missLine: 'Nothing here. Where would a painter put things away?',
      deskFirstLine: 'Three notes. But first, find the paintings. Where did he put them away?',
    ),
  },
  layers: {
    's2_ep02_m3': _easel(
      season2Layers['s2_ep02_m3']!,
      found: {
        'lamp': 'An old lamp, tall and thin.',
        'steps': 'Stone steps, going up.',
        'gate': 'An iron gate between two stone pillars. The note says it is black.',
      },
      missLine: 'Look again. Find a lamp, some steps and a gate.',
      paintLine: 'This is thick paint. Slide it away first.',
    ),
  },
);

/// Case 02's scenes with Master's words.
final masterScenes02 = (
  compares: {
    's2_ep02_m1': _street(
      season2Compares['s2_ep02_m1']!,
      found: {
        'clock': 'A small clock hangs above the red door, but only in the painting.',
        'window': 'The real street has a window here. The painter left it out.',
        'lamp': 'In the painting, the lamp beside the steps glows brightly. On the street, its flame is small.',
      },
      missLine: 'No difference here. Let the note guide you.',
      // The note's lines, as Master's note has them.
      checklist: {
        'clock': 'Look above the red door.',
        'window': 'Seek out the window that has gone missing.',
        'lamp': 'Check the lamp beside the steps.',
      },
    ),
  },
  studios: {
    's2_ep02_m2': _studio(
      season2Studios['s2_ep02_m2']!,
      paintings: {
        'p1': 'The old trunk creaks open. Inside lies a painting of a square.',
        'p2': 'Tucked away in the desk drawer: a painting of a square.',
        'p3': 'Hidden in the crate beneath the desk: a painting of a square.',
      },
      desk: 'Three notes, labelled A, B and C.',
      others: [
        'A canvas with a few strokes of paint, but no picture yet.',
        'His straw hat and paint-spattered smock, hanging on a hook.',
        'The white church on its hill fills the window.',
        'Brushes and a palette. The paint on it has dried hard.',
        'Paintings of Paris cover the wall. The white church, over and over again.',
      ],
      missLine: 'Nothing of interest. Where might a painter tuck things away?',
      deskFirstLine: 'Three notes, but they need their paintings. Where did he put them away?',
    ),
  },
  layers: {
    's2_ep02_m3': _easel(
      season2Layers['s2_ep02_m3']!,
      found: {
        'lamp': 'A tall, thin lamp, old and elegant.',
        'steps': 'Worn stone steps, climbing upward.',
        'gate': 'An iron gate between two stone pillars. Black, the note insists.',
      },
      missLine: 'Nothing there. A lamp, some steps, a gate: keep looking.',
      paintLine: 'Only thick paint. Slide it aside first.',
    ),
  },
);

// ═════════════════════════════════════════════════════════════════════════
// The learning design
// ═════════════════════════════════════════════════════════════════════════

final juniorLearning02 = <String, LearningObjective>{
  's2_ep02_m1': levelObjectiveWith('s2_ep02_m1', expressions: ['Look above the red door', 'Find the window that is missing', 'Check the lamp beside the steps']),
  's2_ep02_m2': levelObjectiveWith(
    's2_ep02_m2',
    expressions: ['BEFORE THE RAIN', 'AFTER THE RAIN STOPPED', 'WHEN THE SKY TURNED GOLD', 'Which painting goes with each note?'],
  ),
  's2_ep02_m3': levelObjectiveWith('s2_ep02_m3', expressions: ['Slide the paint away', 'look UNDERNEATH', 'remember this: the gate is black']),
  's2_ep02_final': levelObjectiveWith('s2_ep02_final', expressions: ['Not the street with the red door', 'Only one canvas matches all three clues']),
};

final masterLearning02 = <String, LearningObjective>{
  's2_ep02_m1': levelObjectiveWith(
    's2_ep02_m1',
    objective: '화가의 메모 "Look above the red door", "Seek out the window that has gone missing", "Check the lamp beside the steps"를 읽고 실제 거리와 그림의 차이 세 곳을 찾는다.',
    expressions: ['Look above the red door', 'the window that has gone missing', 'Check the lamp beside the steps'],
  ),
  's2_ep02_m2': levelObjectiveWith(
    's2_ep02_m2',
    expressions: ['BEFORE THE RAIN', 'AFTER THE RAIN STOPPED', 'WHEN THE SKY TURNED GOLD', 'Pair each note with the painting it describes'],
  ),
  's2_ep02_m3': levelObjectiveWith('s2_ep02_m3', expressions: ['Slide the paint away', 'look UNDERNEATH', 'Whatever he hid lies beneath the paint']),
  's2_ep02_final': levelObjectiveWith('s2_ep02_final', expressions: ['Not the street with the red door', 'Only one canvas fits every clue']),
};
