import '../../../models/learning.dart';
import '../../../models/letter_puzzles.dart';
import '../season2_case06_scenes.dart';
import 'level_words.dart';

// Case 06 — The Letter That Never Arrived, at each level (PART 7B): the words only
// (`docs/difficulty_reviews/PARIS_CASE_04_06.md`).
// What Cases 04–06 keep the same, and untold, at every level: ep04_levels.dart.

const words06 = {'building': '건물', 'hundreds': '수백 개', 'domes': '둥근 지붕들', 'secret': '비밀', 'continues': '계속된다'};
const _churchSlowlyBetween = {'church': '교회', 'slowly': '천천히', 'between': '~사이에'};

const rookieWords06 = {...words06, ..._churchSlowlyBetween};

const juniorWords06 = {'belongs': '~의 것이다', 'stored': '보관된', 'covers': '덮다, 가리다'};

const masterWords06 = {
  'hushed': '조용한',
  'dangle': '매달려 있다',
  'range': '범위',
  'recovered': '되찾은',
  'refuse': '~하려 하지 않다',
  'uncover': '밝혀내다',
  'trace': '따라가 찾다',
};

/// The Letter's Trail, as the slip has it.
const _trailLines = 'LETTER No. 4417\n16 MAY · 4:00 PM\nHELD · LOUVRE POST ROOM';

/// The porter's note, as pinned (the story bible's words; the route is
/// read from it).
const _porterNote =
    'Letters to keep safe go downstairs.\n'
    'Go down the stairs.\n'
    'Walk past the statue.\n'
    'Take the second door on the left.';

/// The post room book's two lines.
const _bookLines = ['16 MAY · 4:00 PM · HELD.', '17 MAY · MORNING · MOVED.'];

/// The story bible's own lines (Case 06, v1.4), the same at every level.
const _notStolen = "Wait! It wasn't stolen.";
const _nextClue = 'We found our next clue!';
const _hook06 = 'What is in File 3–4 of the opera archive?';

/// The letter, as written (its two lines are the clue).
const _letterLines = 'The clocks may lie.\nBut the show remembers.';

const rookie06 = <String, Object?>{'glossary': rookieWords06};

final junior06 = <String, Object?>{
  'synopsis': [
    'Letter No. 4417 was stopped and held at the Louvre post room.',
    'But now it is not there. Was it stolen, or is it hidden?',
    'And what can it tell us about the missing hour?',
  ],
  'objectives': [
    'Find the tag for Letter 4417.',
    'Follow the path the letter took through the building.',
    'Find the letter and read what it says.',
  ],
  'intro': [
    'Letter No. 4417 stopped here, at the Louvre post room.',
    'It never reached its address.',
    'The post room is quiet, and nobody is at the desk.',
    'Letter 4417 should be somewhere here.',
  ],
  'caseSummary': 'Letter 4417 was not stolen. It was kept safe, and its back points to the opera archive.',
  'hook': _hook06,
  'glossary': {...words06, ..._churchSlowlyBetween, ...juniorWords06},
  'missions': {
    's2_ep06_m1': {
      'story': ['Behind the desk stands a wooden rack, and one of its slots is empty.', 'Four paper tags hang from it. Every tag has two sides.'],
      'letterIntro': "Your notebook has the Letter's Trail:",
      'letter': _trailLines,
      'question': 'Which tag belongs to Letter 4417?',
      'successMessage': _notStolen,
      'hints': [
        'Read the front of each tag first. Does it say LETTER? Is the number 4417?',
        'On two tags, ink covers part of the number. Turn those over and compare the day and time.',
      ],
      'transition': ['Tag D reads PRESERVATION ORDER: keep it safe.', 'Someone kept it safe.', 'So where is the letter now?'],
      'options': {
        'a': {'feedback': 'Check the first word. Does it say LETTER or PARCEL?'},
        'b': {'feedback': 'Read the number again, slowly. Does it say 4417?'},
        'c': {'feedback': 'Turn the tag over. Do the day and the time match?'},
      },
      'clue': {'note': 'It was held on 16 MAY at 4:00 PM. PRESERVATION ORDER: keep it safe.'},
      'evidence': {'description': 'It was hanging on the hold rack in the Louvre post room.'},
    },
    's2_ep06_m2': {
      'story': ['In the post room book, there are two lines for Letter 4417.', ..._bookLines, 'On the wall hangs a plan of the building.'],
      'letterIntro': "Someone has pinned a porter's note to the plan:",
      'letter': _porterNote,
      'question': 'Through which door was the letter taken?',
      'hints': [
        'Follow the note line by line. Go down the stairs, then walk past the statue.',
        'Once you are past the statue, count the doors on the left only.',
      ],
      'successMessage': 'The letter was taken to the archive!',
      'transition': ['The archive is behind Door E.', 'There are tall cabinets with hundreds of small drawers.', 'Letter 4417 must be somewhere in here.'],
      'options': {
        'a': {'feedback': 'Too early. You have not walked past the statue yet.'},
        'b': {'feedback': 'Too early. You have not walked past the statue yet.'},
        'c': {'feedback': 'That is only the first door on the left. Keep counting.'},
        'd': {'feedback': 'That door is on the right side. Which side is the left?'},
        'f': {'feedback': 'That door is on the right side. Which side is the left?'},
      },
      'clue': {'note': 'Down the stairs, past the statue, then the second door on the left. It is the archive.'},
      'evidence': {'description': 'It was pinned to the plan of the building in the post room.'},
    },
    's2_ep06_m3': {
      'story': ['Torn letters are stored here, and each drawer has a label.', 'Many of these torn letters have lost their numbers.'],
      'letterIntro': 'The torn envelope corner from Clock III has a label:',
      'letter': 'No. 4417\n\nWhich envelope was it torn from?',
      'question': 'Which envelope is the one for Letter 4417?',
      'hints': [
        'First find the right drawer. It must be for letters, and 4417 must be between its two numbers.',
        'Try the torn corner on each envelope. Only one torn edge fits it.',
      ],
      'successMessage': 'You found it! Letter 4417!',
      'transition': ['The corner fits perfectly. This is Letter 4417.', 'But what is this little picture on the seal?', 'There is a letter inside the envelope.'],
      'options': {
        'x': {'feedback': 'These torn edges do not fit together.'},
        'z': {'feedback': 'Look closely at the torn edge. Does the corner fit it?'},
      },
      'clue': {'note': 'The torn corner from Clock III fits only one envelope. On its seal is a tiny picture of a building.'},
      'evidence': {'description': 'It was in one of the archive drawers.'},
    },
    's2_ep06_final': {
      'story': ['The letter has two lines, and a drawing of the building from the seal.', 'On the wall hangs a map of Paris.'],
      'letterIntro': 'The letter reads:',
      'letter': _letterLines,
      'question': 'Which building does the drawing show?',
      'successMessage': _nextClue,
      'hints': [
        'Look carefully at the roof in the drawing. What shape is it, and what stands on top?',
        'The letter says "the show remembers". Which building is a place for shows?',
      ],
      'transition': [
        'The drawing shows the Palais Garnier, the opera house.',
        'On the back: OPERA ARCHIVE · FILE 3–4.',
        'The mystery continues at the opera house!',
      ],
      'options': {
        'montmartre': {'feedback': 'Its church does have domes, but there are no statues on its roof.'},
        'louvre': {'feedback': 'We are already at the Louvre. Look again at the roof in the drawing.'},
        'arcDeTriomphe': {'feedback': 'That is a huge arch, but the drawing shows a dome.'},
        'gareDuNord': {'feedback': 'That is a train station. People go there for trains, not shows!'},
        'notreDame': {'feedback': 'It has two tall towers, but the drawing has a dome.'},
        'eiffelTower': {'feedback': 'The tower has no dome and no statues at all.'},
      },
      'evidence': {'description': 'This is Letter No. 4417. It was found in the archive.'},
    },
  },
};

final master06 = <String, Object?>{
  'synopsis': [
    'Letter No. 4417 was held back at the Louvre post room.',
    'Now it is nowhere to be seen. Was it stolen, or hidden away?',
    'And what might it reveal about the missing hour?',
  ],
  'objectives': [
    'Track down the tag for Letter 4417.',
    "Trace the letter's route through the building.",
    'Find the letter and uncover its secret.',
  ],
  'intro': [
    'Letter No. 4417 went no further than the Louvre post room.',
    'Its journey ended here, undelivered.',
    'The post room is hushed. No one sits at the desk.',
    'Somewhere in this room, Letter 4417 should be waiting.',
  ],
  'caseSummary': 'Letter 4417 was never stolen, only kept safe, and its back points the way to the opera archive.',
  'hook': _hook06,
  'glossary': {...words06, ...masterWords06},
  'missions': {
    's2_ep06_m1': {
      'story': ['Behind the desk rises a wooden rack. One of its slots sits empty.', 'Four paper tags dangle from it, each with a front and a back.'],
      'letterIntro': "The Letter's Trail, copied in your notebook:",
      'letter': _trailLines,
      'question': 'Which of the tags is the one for Letter 4417?',
      'successMessage': _notStolen,
      'hints': [
        'Begin with what each front says: the kind of post, and the number.',
        'Where ink hides a digit, the back must decide. Compare it with your notebook.',
      ],
      'transition': ['The back of Tag D reads: PRESERVATION ORDER: keep it safe.', 'Someone kept it safe.', 'But where has it gone since?'],
      'options': {
        'a': {'feedback': 'Mind the first word: a LETTER is not a PARCEL.'},
        'b': {'feedback': 'Read the digits one by one. Is that really 4417?'},
        'c': {'feedback': 'The front cannot tell you enough. What do the day and time on the back say?'},
      },
      'clue': {'note': 'Held on 16 MAY at 4:00 PM, under a PRESERVATION ORDER: keep it safe.'},
      'evidence': {'description': 'Taken from the hold rack of the Louvre post room.'},
    },
    's2_ep06_m2': {
      'story': ['The post room book records two entries for Letter 4417.', ..._bookLines, 'A plan of the whole building hangs on the wall.'],
      'letterIntro': 'Pinned to the plan is a note from a porter:',
      'letter': _porterNote,
      'question': 'Which door did the letter pass through?',
      'hints': ['Let the note lead you, one line at a time.', 'Past the statue, ignore the doors on the right. Count along the left.'],
      'successMessage': 'The letter was moved down to the archive!',
      'transition': ['Door E opens onto the archive.', 'Tall cabinets rise to the ceiling, with hundreds of small drawers.', 'Letter 4417 must be among them.'],
      'options': {
        'a': {'feedback': 'Too soon. The note says to pass the statue first.'},
        'b': {'feedback': 'Too soon. The note says to pass the statue first.'},
        'c': {'feedback': 'The first door on the left. The note asks for another.'},
        'd': {'feedback': 'That door lies on the right. The note says left.'},
        'f': {'feedback': 'That door lies on the right. The note says left.'},
      },
      'clue': {'note': 'Down the stairs, past the statue, through the second door on the left: the archive.'},
      'evidence': {'description': 'Found pinned to the building plan in the post room.'},
    },
    's2_ep06_m3': {
      'story': ['This is where torn letters are kept, each drawer marked with a label.', 'Many of them have lost their numbers along the way.'],
      'letterIntro': 'The torn envelope corner you found in Clock III reads:',
      'letter': 'No. 4417\n\nFind the envelope this corner was torn from.',
      'question': 'Which envelope belongs to Letter 4417?',
      'hints': ['The drawer comes first: the right kind of post, and a range that includes 4417.', 'Only one torn edge will meet the corner exactly.'],
      'successMessage': 'At last, Letter 4417!',
      'transition': ['The corner fits exactly. This is Letter 4417.', 'But what is the tiny picture pressed into the seal?', 'Inside the envelope, a letter is waiting.'],
      'options': {
        'x': {'feedback': 'The torn edges refuse to line up.'},
        'z': {'feedback': 'Study the torn edge. Would the corner fit it exactly?'},
      },
      'clue': {'note': 'Only one envelope matches the torn corner from Clock III. Its seal shows a tiny building.'},
      'evidence': {'description': 'Recovered from a drawer in the archive.'},
    },
    's2_ep06_final': {
      'story': ['Two short lines, and a drawing of the very building on the seal.', 'A map of Paris hangs on the archive wall.'],
      'letterIntro': 'The letter holds just two lines:',
      'letter': _letterLines,
      'question': 'Which building has been drawn on the letter?',
      'successMessage': _nextClue,
      'hints': ['The roof is the key: its shape, and what stands upon it.', 'Think about "the show remembers". Where would a show be remembered?'],
      'transition': [
        "The building in the drawing is the Palais Garnier, the city's grand opera house.",
        'On the back: OPERA ARCHIVE · FILE 3–4.',
        'The mystery continues at the opera house!',
      ],
      'options': {
        'montmartre': {'feedback': 'Domes, yes, but not a single statue on its roof.'},
        'louvre': {'feedback': 'We are already at the Louvre. Compare its roof with the drawing.'},
        'arcDeTriomphe': {'feedback': 'An arch, however grand, is not a dome.'},
        'gareDuNord': {'feedback': 'A railway station: trains, not shows!'},
        'notreDame': {'feedback': 'Two tall towers rise from it. The drawing shows a dome.'},
        'eiffelTower': {'feedback': 'An iron tower, with neither a dome nor statues.'},
      },
      'evidence': {'description': 'Letter No. 4417, recovered at last from the archive.'},
    },
  },
};

// ═════════════════════════════════════════════════════════════════════════
// The scenes' own words
// ═════════════════════════════════════════════════════════════════════════

/// The archive: what a wrong drawer or envelope says, and the seal's line.
/// The drawers, the envelopes and every way to play are the base's.
ArchiveScene _archive(ArchiveScene base, {required String notHere, required String notLetters, required String notFit, required String sealLine}) =>
    ArchiveScene(
      drawers: base.drawers,
      cabinet: base.cabinet,
      cabinetPixels: base.cabinetPixels,
      cabinetView: base.cabinetView,
      cabinetDrawers: base.cabinetDrawers,
      drawer: base.drawer,
      drawerPixels: base.drawerPixels,
      drawerView: base.drawerView,
      felt: base.felt,
      envelopes: base.envelopes,
      envelopePixels: base.envelopePixels,
      corner: base.corner,
      cornerPiece: base.cornerPiece,
      cornerTagAt: base.cornerTagAt,
      numberTag: base.numberTag,
      seal: base.seal,
      sealPixels: base.sealPixels,
      sealAt: base.sealAt,
      cabinetTask: base.cabinetTask,
      drawerTask: base.drawerTask,
      layTask: base.layTask,
      layLabel: base.layLabel,
      notHere: notHere,
      notLetters: notLetters,
      notFit: notFit,
      sealLabel: base.sealLabel,
      sealLine: sealLine,
    );

/// Case 06's scenes with Junior's words.
final juniorScenes06 = (
  archives: {
    's2_ep06_m3': _archive(
      season2ArchiveScenes['s2_ep06_m3']!,
      notHere: '{label}. Does 4417 fall between these two numbers?',
      notLetters: '{label}. This drawer is only for parcels.',
      notFit: 'These torn edges do not fit together.',
      sealLine: 'A tiny picture of a big, grand building.',
    ),
  },
);

/// Case 06's scenes with Master's words.
final masterScenes06 = (
  archives: {
    's2_ep06_m3': _archive(
      season2ArchiveScenes['s2_ep06_m3']!,
      notHere: '{label}. Is 4417 inside this range?',
      notLetters: '{label}. Parcels only: not the drawer you need.',
      notFit: 'The torn edges refuse to line up.',
      sealLine: 'A tiny drawing of a grand building, pressed into the wax.',
    ),
  },
);

/// Case 06's scenes whose words are the same at every level (see
/// `season2SameAtEveryLevel`).
const sameAtEveryLevel06 = {
  'holdRacks/s2_ep06_m1',
  'planRoutes/s2_ep06_m2',
  'letterMaps/s2_ep06_final',
};

// ═════════════════════════════════════════════════════════════════════════
// The learning design
// ═════════════════════════════════════════════════════════════════════════

final juniorLearning06 = <String, LearningObjective>{
  's2_ep06_m1': levelObjective('s2_ep06_m1', ['LETTER No. 4417', 'Which tag belongs to Letter 4417?']),
  's2_ep06_m2': levelObjective('s2_ep06_m2', ['Walk past the statue.', 'Take the second door on the left.', 'count the doors on the left only']),
  's2_ep06_m3': levelObjective('s2_ep06_m3', ['Which envelope was it torn from?']),
  's2_ep06_final': levelObjective('s2_ep06_final', ['But the show remembers.', 'Which building is a place for shows?']),
};

final masterLearning06 = <String, LearningObjective>{
  's2_ep06_m1': levelObjective('s2_ep06_m1', ['LETTER No. 4417', 'Where ink hides a digit, the back must decide']),
  's2_ep06_m2': levelObjective('s2_ep06_m2', ['Walk past the statue.', 'Take the second door on the left.', 'Count along the left']),
  's2_ep06_m3': levelObjective('s2_ep06_m3', ['Find the envelope this corner was torn from']),
  's2_ep06_final': levelObjective('s2_ep06_final', ['But the show remembers.', 'Where would a show be remembered?']),
};
