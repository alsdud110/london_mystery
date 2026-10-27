import '../../../models/discovery.dart';
import '../../../models/learning.dart';
import '../../../models/scene_decode.dart';
import '../../../models/scene_deduction.dart';
import '../../../models/scene_explore.dart';
import '../../../models/scene_inspect.dart';
import '../season1_decodes.dart';
import '../season1_deductions.dart';
import '../season1_explores.dart';
import '../season1_inspections.dart';
import '../season1_learning.dart';
import 'level_words.dart';

// Case 01 — The Missing Crown, at each level (PART 6A).
//
// The facts never move: the suitcase by Platform 9 and its letter ("old
// mummies from Egypt" and "a famous stone" — the stone's word comes back in
// Mission 02's tip), Room 4 and a word for "a hard piece of rock" (STONE is
// never written before it is answered), the footprints, lamp and scratches
// that all point to one stone (never "behind" before the choice), the palace
// with a red flag, a fountain and the King, the crown card whose message is
// drawn on the card itself (its letter is the same at every level), and the
// four locks 7924. "P.S. I love trains!" (Case 11) is the evidence's own and
// the post-case line, word for word.

// ── Rookie: the base, with two lines made shorter ─────────────────────────
const Map<String, Object?> ep01Rookie = {
  'intro': [
    'London, 10:42 PM...',
    'Something strange happened at the Royal Archive.',
    'The Crown is missing.',
    'The thief left a trail of clues all over London.',
    'Now you are the detective. Find the Crown!',
  ],
  'missions': {
    'final': {
      'story': [
        'Behind the secret door, you find a heavy golden box.',
        'The Crown is inside it.',
      ],
    },
  },
};

// ── Junior ───────────────────────────────────────────────────────────────
const Map<String, Object?> ep01Junior = {
  'synopsis': [
    'The Crown has disappeared from the Royal Archive in London!',
    'The thief left a trail of clues behind.',
    'Follow the clues across the city and find the Crown.',
  ],
  'intro': [
    'London, 10:42 PM...',
    'Something strange has happened at the Royal Archive.',
    'The Crown of London has disappeared!',
    'The thief left a trail of clues across the city.',
    'You have been chosen to follow it, Detective.',
  ],
  'glossary': {
    'disappeared': '사라졌다',
    'trail': '흔적, 자취',
    'across': '~를 가로질러, 곳곳에',
    'empty': '텅 빈',
    'alone': '혼자, 홀로',
    'closely': '자세히',
    'trolley': '손수레',
    'luggage': '여행 짐',
    'railway': '철도',
    'shining': '빛나는',
    'painted': '색칠된',
    'belong': '~에 속하다',
    'muddy': '진흙투성이의',
    'hurry': '서두르다',
    'hidden': '숨겨진',
    'close': '가까운',
    'escaped': '달아났다',
    'decode': '(암호를) 풀다',
  },
  'missions': {
    'm01': {
      'story': [
        "You step off the train at King's Cross Station. The platform is almost empty.",
        'Next to Platform 9, an old suitcase sits all alone on a bench.',
      ],
      'letterIntro': 'You open the suitcase. Inside, there is a letter.',
      'letter': 'Dear Detective {detectiveName},\n\n'
          'Yes, I took the Crown! Ha ha!\n'
          'Can you catch me? My next stop is a very big museum.\n'
          'Inside, there are old mummies from Egypt and a famous stone.\n\n'
          '— The Shadow',
      'question': 'Which museum is the thief going to next?',
      'options': {
        'a': {'feedback': 'Dinosaur bones are old too. But the letter names two other things. What are they?'},
        'c': {'feedback': 'The thief might like trains! But what does the letter say is inside the museum?'},
        'd': {'feedback': 'Rockets and machines are not in the letter. Find the two things it names.'},
      },
      'hints': [
        'Find the line in the letter about the museum. It names two things inside.',
        'Look at each poster. Which museum could keep old mummies and a famous stone?',
      ],
      'clue': {'note': 'The suitcase was on a bench next to Platform 9.'},
      'evidence': {'description': 'The letter the thief left in the suitcase.'},
      'successMessage': 'The thief is heading to the British Museum!',
      'transition': [
        'Suddenly, the letter begins to glow...',
        'Someone has left a strange symbol near the British Museum.',
      ],
    },
    'm02': {
      'story': [
        'The British Museum is full of treasures from long ago.',
        'In Room 4, you find something big and grey. It is covered in strange writing.',
      ],
      'letterIntro': 'Someone has left a note next to it!',
      'letter': 'Long ago, it helped people read old Egyptian writing.\n'
          'Its name has two words.\n'
          'The first word is ROSETTA.\n'
          'The second word means a hard piece of rock.',
      'question': 'Write the missing word in its name.',
      // The label as the puzzle shows it: the same at every level.
      'prompt': 'ROSETTA _____',
      'hints': [
        'Read the last line of the note. Which word means almost the same as rock?',
        "Think back to the thief's first letter. The museum had 'a famous ____'. The same word fits here.",
      ],
      'feedback': {'ROCK': 'Very close! Rock is right in meaning, but the name uses another word.'},
      'clue': {'note': 'The Rosetta Stone stands in Room 4.'},
      'evidence': {'description': 'A small golden key, hidden under the stone.'},
      'successMessage': 'You found it: the Rosetta Stone!',
      'transition': [
        'The old stone shines in the dark.',
        'Ding dong! Far away, a great bell is ringing.',
        "London's biggest bell… That must be Big Ben!",
      ],
    },
    'm03': {
      'story': [
        'You hurry to the tall clock tower: Big Ben!',
        'Somewhere at the foot of the tower, the thief has hidden a small box.',
      ],
      'letterIntro': 'Here are your notes from the foot of Big Ben:',
      // Line for line the scene's three clues (see ep01JuniorDeductions).
      'letter': 'The muddy footprints stop at the tower wall.\n'
          'The lamp light falls on one stone in the wall.\n'
          'That stone has fresh scratches all around it.',
      'question': 'Where has the thief hidden the box?',
      'options': {
        'a': {'feedback': 'The bench is close to the lamp, but no footprints lead to it. Where do they stop?'},
        'c': {'feedback': 'The footprints go past the drain cover. Check your notes: where do they stop?'},
      },
      'hints': [
        'Follow the footprints. Where do they stop? Look closely at that part of the wall.',
        'Read your three notes again. The footprints, the light and the scratches all lead to one place.',
      ],
      'clue': {'note': "The thief's pocket watch stopped at 7 o'clock."},
      'evidence': {'description': 'The thief left this pocket watch inside the box.'},
      'successMessage': 'Click! The little box opens.',
      'transition': [
        'Inside the box, you find a pocket watch and a photo.',
        'The photo shows a big green park with a lake.',
        "It must be Hyde Park. Let's go!",
      ],
    },
    'm04': {
      'story': [
        'You arrive at Hyde Park. The night air is cool and still.',
        'On the lake, two white swans are swimming.',
      ],
      'letterIntro': 'Under a bench, you find another note from the thief.',
      'letter': 'My last stop is a big palace.\n'
          'A red flag is flying on top of it.\n'
          'There is a fountain in front of it.\n'
          'The King lives there!',
      'question': "Which picture matches the thief's last stop?",
      'options': {
        'a': {'feedback': 'That is a bridge over a river. The note describes a palace with a fountain.'},
        'b': {'feedback': 'A giant wheel! Is there a wheel in the note?'},
        'd': {'feedback': 'That is a clock tower, not a palace. Who lives at the last stop?'},
      },
      'hints': [
        'Read the note one line at a time. Then look for a picture with a flag and a fountain.',
        'A palace is a big home for a king. Which picture has a fountain in front?',
      ],
      'clue': {'note': 'There were two white swans on the lake.'},
      'evidence': {'description': 'A map of London, left under the bench.'},
      'successMessage': "It is Buckingham Palace, the King's home!",
      'transition': [
        'The swans rise up into the night sky.',
        'They fly away toward a big palace...',
        "The thief's last stop is close!",
      ],
    },
    'm05': {
      'story': [
        'You reach Buckingham Palace at last.',
        'A guard in a red coat gives you a small smile.',
      ],
      'letterIntro': 'The crown card, after you decode it:',
      // Drawn on the card where its code was: the same at every level.
      'letter': 'Four pictures. Four locks.\n'
          'Remember the order.',
      // How to play it: the same at every level.
      'question': 'Examine the card near the palace gate.',
      'hints': [
        'Find the card by the palace gate and look at it closely.',
        'Tap the strange square symbol next to the crown. Then press EXAMINE THE CODE.',
      ],
      'clue': {'note': 'The Crown is locked inside a box with 4 locks.'},
      'evidence': {'description': 'A golden card with a crown and a secret code.'},
      'successMessage': 'The way to the Crown is open!',
      'transition': [
        'The guard opens a secret door in the wall.',
        'Behind it, old stone stairs go down into the dark.',
        'The Royal Archive is waiting.',
      ],
    },
    'final': {
      'story': [
        'Behind the secret door, deep in the Royal Archive, you find a heavy golden box.',
        'The Crown is locked inside.',
      ],
      'letterIntro': 'Words are carved on the lid.',
      'letter': 'Four locks keep the Crown safe.\n'
          'There is a picture on each lock.\n\n'
          'Each picture is a place you visited tonight.\n'
          'Find the number from that place in your Detective Notebook!',
      // How to play it: the same at every level.
      'question': 'Open the four locks.',
      'hints': [
        "Each picture stands for one place. The train is King's Cross!",
        "Find the clue from King's Cross in your notebook. Then do the same for the clock, the park and the museum.",
      ],
      'evidence': {'description': 'The real Crown of London. You got it back!'},
      'successMessage': 'You found the Crown!',
      'transition': [
        'The Crown is safe again.',
        'The Royal Box stands open.',
        'But the Shadow has escaped.',
        "The watch in the box at Big Ben\nhad stopped at 7 o'clock.",
        'And his letter ended with these words:',
        '"P.S. I love trains!"',
        'London is quiet tonight.',
        'But not for long.',
      ],
    },
  },
};

// ── Master ───────────────────────────────────────────────────────────────
const Map<String, Object?> ep01Master = {
  'synopsis': [
    'The Crown has vanished from the Royal Archive in London!',
    'Its thief has left a trail of clues scattered across the city.',
    'Follow it, piece by piece, before the trail goes cold.',
  ],
  'intro': [
    'London, 10:42 PM...',
    'Behind the locked doors of the Royal Archive, something is terribly wrong.',
    'The Crown of London has vanished without a sound.',
    'Yet the thief has left a trail of clues, scattered across the city.',
    'Tonight, you have been chosen to follow it.',
  ],
  'glossary': {
    'vanished': '사라졌다',
    'scattered': '흩어진',
    'trail': '흔적, 자취',
    'terribly': '몹시, 끔찍하게',
    'hush': '고요함',
    'tucked': '(안에) 넣어 둔',
    'addressed': '(~ 앞으로) 보낸',
    'lid': '뚜껑',
    'grand': '웅장한',
    'ancient': '고대의, 아주 오래된',
    'rest': '쉬다, 놓여 있다',
    'wish': '바라다',
    'heading': '향하는',
    'tempt': '유혹하다',
    'collection': '소장품',
    'crisscrossed': '이리저리 교차된',
    'piled': '쌓인',
    'deserves': '~할 만하다',
    'gleams': '희미하게 빛나다',
    'mighty': '거대한, 강력한',
    'looms': '어렴풋이 나타나다',
    'surface': '표면',
    'unlocked': '(비밀을) 풀었다',
    'restore': '되살리다',
    'defines': '뜻을 설명하다',
    'study': '자세히 살피다',
    'crafted': '만들어진',
    'figure': '(작은) 조각상',
    'upon': '~ 위에',
    'carved': '새겨진',
    'glints': '반짝이다',
    'railed': '난간이 둘린',
    'abruptly': '갑자기',
    'casts': '(빛을) 비추다',
    'concealed': '숨겨진',
    'agree': '일치하다',
    'traces': '흔적들',
    'undisturbed': '아무도 건드리지 않은',
    'rainsoaked': '비에 흠뻑 젖은',
    'examine': '자세히 살펴보다',
    'springs': '(갑자기) 튀어 열리다',
    'photograph': '사진',
    'glide': '미끄러지듯 나아가다',
    'gliding': '미끄러지듯 나아가는',
    'final': '마지막의',
    'roof': '지붕',
    'description': '묘사, 설명',
    'spanning': '(다리가) 가로지르는',
    'royal': '왕실의',
    'residence': '저택, 거처',
    'resident': '거주자',
    'distance': '먼 곳',
    'scarlet': '진홍색의',
    'knowing': '다 안다는 듯한',
    'beyond': '~ 너머에',
    'spiral': '나선형으로 돌다',
    'awaits': '기다리고 있다',
    'leaning': '기대어 있는',
    'sealed': '봉인된',
    'bearing': '(표시를) 지닌',
    'guard': '지키다, 경비병',
    'bears': '(표시를) 지니다',
    'stands': '나타내다, 서 있다',
    'journey': '여정',
    'recovered': '되찾은',
    'slipped': '빠져나갔다',
    'peace': '평화',
  },
  'missions': {
    'm01': {
      'story': [
        "You step off the train into the hush of King's Cross Station.",
        'Beside Platform 9, an old suitcase waits on a bench, as if someone left it there for you.',
      ],
      'letterIntro': 'You lift the lid. Tucked inside is a letter, addressed to you.',
      'letter': 'Dear Detective {detectiveName},\n\n'
          'The Crown is mine! Ha ha!\n'
          'If you wish to catch me, follow me to a grand museum.\n'
          'There, mummies from ancient Egypt rest beside a famous stone.\n\n'
          '— The Shadow',
      'question': 'Where is the Shadow heading next?',
      'options': {
        'a': {'feedback': 'Dinosaur bones are ancient as well, but are they what the letter describes?'},
        'c': {'feedback': 'A museum of trains would tempt this thief. Yet what does the letter say waits inside?'},
        'd': {'feedback': 'Rockets and machines? Look again at what the letter says rests inside.'},
      },
      'hints': [
        'The letter describes the museum by what lies inside it. Which two things does it name?',
        'Each museum on the board keeps a different kind of collection. Which one would keep mummies?',
      ],
      'clue': {'note': 'The suitcase was waiting beside Platform 9.'},
      'evidence': {'description': "The thief's taunting letter, left in the suitcase."},
      'successMessage': 'The trail leads to the British Museum.',
      'transition': [
        'All at once, the letter begins to glow in your hands...',
        'Somewhere near the British Museum, someone has left a strange symbol.',
      ],
    },
    'm02': {
      'story': [
        'Night has fallen over the British Museum and its ancient treasures.',
        'In Room 4, a great grey shape looms in the dark, its surface covered in strange writing.',
      ],
      'letterIntro': 'Beside it, someone has left a note.',
      'letter': 'It once unlocked the secret of old Egyptian writing.\n'
          'Its name is made of two words.\n'
          'The first of them is ROSETTA.\n'
          'The second is a word for a hard piece of rock.',
      'question': 'Restore the missing word of its name.',
      // The label as the puzzle shows it: the same at every level.
      'prompt': 'ROSETTA _____',
      'hints': [
        'The note defines the missing word rather than naming it. What else might you call a hard piece of rock?',
        "The thief's first letter has already used this word. What was famous in that museum?",
      ],
      'feedback': {'ROCK': 'Very close! Rock has the right meaning, but this famous name uses a different word.'},
      'clue': {'note': 'The Rosetta Stone is kept in Room 4.'},
      'evidence': {'description': 'A small golden key that was hidden beneath the stone.'},
      'successMessage': 'The Rosetta Stone, of course!',
      'transition': [
        'For a moment, the ancient stone gleams in the darkness.',
        'Then, far across the city, a mighty bell begins to ring.',
        "London's biggest bell… It can only be Big Ben!",
      ],
    },
    'm03': {
      'story': [
        'You race through the night to the great clock tower: Big Ben!',
        'Somewhere at its foot, the thief has hidden a small box.',
      ],
      'letterIntro': 'Notes from the foot of Big Ben, in your own hand:',
      // Line for line the scene's three clues (see ep01MasterDeductions).
      'letter': 'The muddy footprints end abruptly at the tower wall.\n'
          'The lamp casts its light on a single stone in that wall.\n'
          'Around that stone, the scratches look fresh.',
      'question': 'Where is the box concealed?',
      'options': {
        'a': {'feedback': 'The bench sits near the lamp, yet no footprints lead there. Do all three clues agree?'},
        'c': {'feedback': 'The footprints pass the drain cover by. Which place do all your notes point to?'},
      },
      'hints': [
        'Where the trail of footprints ends, what does the lamp light up?',
        'One place is named, in some way, by all three of your notes. Which is it?',
      ],
      'clue': {'note': "The hands of the thief's watch froze at 7 o'clock."},
      'evidence': {'description': 'A pocket watch the thief left behind in the box.'},
      'successMessage': 'Click! The lid of the box springs open.',
      'transition': [
        'Inside lie a pocket watch and a photograph.',
        'The photograph shows a wide green park around a lake.',
        'Hyde Park! The trail goes on.',
      ],
    },
    'm04': {
      'story': [
        'You reach Hyde Park, silent under the night sky.',
        'Two white swans glide across the dark lake.',
      ],
      'letterIntro': 'Beneath a bench, another note from the thief is waiting.',
      'letter': 'My final stop is a grand palace.\n'
          'A red flag flies from its roof,\n'
          'and a fountain stands before it.\n'
          'It is the home of the King himself!',
      'question': "Which picture fits the thief's description of the final stop?",
      'options': {
        'a': {'feedback': 'A bridge spanning a river. The note describes a palace, not a bridge.'},
        'b': {'feedback': 'A great wheel turning by the river. Nothing in the note mentions one.'},
        'd': {'feedback': 'A clock tower, however tall, is no home for a king.'},
      },
      'hints': [
        'Each line of the note describes one part of the picture. Which picture has every part?',
        'Only one of these places could be a royal home. What stands in front of it?',
      ],
      'clue': {'note': 'Two white swans were gliding across the lake.'},
      'evidence': {'description': 'A map of London, tucked under the bench.'},
      'successMessage': 'Buckingham Palace: the residence of the King.',
      'transition': [
        'With a beat of their wings, the swans rise into the night.',
        'They fly toward a great palace in the distance...',
        'The end of the trail is near!',
      ],
    },
    'm05': {
      'story': [
        'At last, you stand before Buckingham Palace.',
        'A guard in a scarlet coat gives you a knowing smile.',
      ],
      'letterIntro': 'The crown card, its code broken:',
      // Drawn on the card where its code was: the same at every level.
      'letter': 'Four pictures. Four locks.\n'
          'Remember the order.',
      // How to play it: the same at every level.
      'question': 'Examine the card near the palace gate.',
      'hints': [
        'Something near the palace gate hides a secret. What is leaning against the gate?',
        'The square symbol beside the crown is a code. Tap it, then press EXAMINE THE CODE.',
      ],
      'clue': {'note': 'The Crown lies inside a box sealed by 4 locks.'},
      'evidence': {'description': 'A golden card bearing a crown and a hidden code.'},
      'successMessage': 'The final door swings open!',
      'transition': [
        'Without a word, the guard opens a secret door.',
        'Beyond it, ancient stairs spiral down into darkness.',
        'The Royal Archive awaits.',
      ],
    },
    'final': {
      'story': [
        'Deep within the Royal Archive, past the secret door, a heavy golden box gleams in the dark.',
        'The Crown rests inside, guarded by four locks.',
      ],
      'letterIntro': 'Words have been carved into its lid.',
      'letter': 'Four locks guard the Crown.\n'
          'Each one bears a picture.\n\n'
          'Every picture stands for a place you have visited.\n'
          'Your Detective Notebook holds the number that belongs to each.',
      // How to play it: the same at every level.
      'question': 'Open the four locks.',
      'hints': [
        'Think of each picture as a place on your journey tonight. Where did you see trains?',
        'Every place left you a number in your notebook. Match each picture to its place, then read the numbers in order.',
      ],
      'evidence': {'description': 'The true Crown of London, recovered by you.'},
      'successMessage': 'The Crown of London is safe at last!',
      'transition': [
        'The Crown is safe once more.',
        'The Royal Box lies open.',
        'Yet the Shadow has slipped away.',
        "The watch in the box at Big Ben\nhad frozen at 7 o'clock.",
        'And his letter closed with a strange line:',
        '"P.S. I love trains!"',
        'Tonight, London sleeps in peace.',
        'For now.',
      ],
    },
  },
};

// ── The scenes at Junior and Master ──────────────────────────────────────
// Only words: every picture, place, spot and choice is the base's. The
// ways to play ("Tap…", "Drag…", the buttons) are the base's at every level.

final ExploreScene _m01 = season1Explores['m01']!;
final InspectScene _m02 = season1Inspections['m02']!;
final DeductionScene _m03 = season1Deductions['m03']!;
final DecodeScene _m05 = season1Decodes['m05']!;

final Map<String, ExploreScene> ep01JuniorExplores = {
  'm01': _m01.copyWith(
    task: 'Look around the station. The thief left something here for you.',
    nextTask: 'Which museum is next? Find it on the poster board.',
    missLine: 'Nothing useful here. What could the thief have left behind?',
    choiceHow: 'Which museum has the two things in the letter? Tap one poster.',
    spots: [
      for (final s in _m01.spots)
        switch (s.id) {
          // The case's own clue note at this level.
          'platform' => s.copyWith(line: 'The suitcase was on a bench next to Platform 9.'),
          'posters' => s.copyWith(lockedLine: "Posters for London's museums. But which one? Find a clue first."),
          _ => s,
        },
    ],
    others: relined(_m01.others, const [
      "The King's Cross sign. You are at the right station.",
      'A map of the railway lines. There is no message on it.',
      'The station clock. It is very late at night.',
      'Bags on a luggage trolley. They are all locked.',
      'A train is waiting at the platform. There is nothing to find here.',
      'A wooden bench. Look closely at what is on it!',
      'A red post box. There is nothing inside for you.',
    ]),
  ),
};

final Map<String, ExploreScene> ep01MasterExplores = {
  'm01': _m01.copyWith(
    task: 'Search the quiet station. Somewhere here, the thief has left something behind.',
    nextTask: 'Where is the thief heading? Match the letter to a poster.',
    missLine: 'Nothing of interest. Look for something out of place.',
    choiceHow: 'Which museum matches the letter? Tap one poster.',
    spots: [
      for (final s in _m01.spots)
        switch (s.id) {
          'platform' => s.copyWith(line: 'The suitcase was waiting beside Platform 9.'),
          'posters' => s.copyWith(lockedLine: 'A board of museum posters. Without a clue, any of them could be next.'),
          _ => s,
        },
    ],
    others: relined(_m01.others, const [
      "King's Cross, says the sign. You are in the right place.",
      'A map of the railway, criss-crossed with lines. No message hides here.',
      'The station clock. The night is already late.',
      'Bags piled on a trolley, every one of them locked.',
      'A train stands waiting. It holds no clues.',
      'A wooden bench. Something on it deserves a closer look.',
      'A post box. Nothing inside is meant for you.',
    ]),
  ),
};

// Never "stone" before it is written (the answer).
final Map<String, InspectScene> ep01JuniorInspections = {
  'm02': _m02.copyWith(
    task: 'Look at each exhibit. Which one matches the note?',
    nextTask: 'Now read its label. One word is missing.',
    missLine: 'Nothing here. Try one of the exhibits.',
    labelWorn: 'The second word has worn away.',
    spots: [
      for (final s in _m02.spots)
        switch (s.id) {
          'mask' => s.copyWith(line: "A king's face, made of shining gold."),
          'mummyCase' => s.copyWith(line: 'A mummy case. It is made of painted wood.'),
          'cats' => s.copyWith(line: 'Two black cats and a little jar. There is no writing on them.'),
          'treasures' => s.copyWith(line: 'A blue beetle, a little gold man and a bowl. They are all very small.'),
          'king' => s.copyWith(line: 'A king sits on his throne. There is no writing on him.'),
          'queen' => s.copyWith(line: "A queen's head. It is painted blue and gold."),
          'slab' => s.copyWith(line: 'Strange writing… on something big and grey.'),
          'label' => s.copyWith(
              line: 'A label. One word of the name is missing.',
              lockedLine: 'A small label. Which exhibit does it belong to?',
            ),
          // The key's tag says it word for word, as its evidence does.
          'plinth' => s.copyWith(
              line: "Something shines in the shadow. It is a small golden key! ROOM 4 is cut into it. "
                  "Its tag says: 'My next stop is where London's biggest bell rings.'",
              lockedLine: 'A plinth with a rail around it. What stands on top?',
            ),
          _ => s,
        },
    ],
  ),
};

final Map<String, InspectScene> ep01MasterInspections = {
  'm02': _m02.copyWith(
    task: 'Study the exhibits. Which one fits every line of the note?',
    nextTask: 'Read its label. A word has worn away.',
    missLine: 'Nothing here. Turn the glass to the exhibits.',
    labelWorn: 'Time has worn the second word away.',
    spots: [
      for (final s in _m02.spots)
        switch (s.id) {
          'mask' => s.copyWith(line: 'The face of a king, crafted in gold.'),
          'mummyCase' => s.copyWith(line: 'A mummy case of painted wood.'),
          'cats' => s.copyWith(line: 'Two black cats beside a little jar. Not a word is written on them.'),
          'treasures' => s.copyWith(line: 'A blue beetle, a tiny gold figure and a bowl. Too small to hold much writing.'),
          'king' => s.copyWith(line: 'A king upon his throne. He carries no writing.'),
          'queen' => s.copyWith(line: 'The head of a queen, painted in blue and gold.'),
          'slab' => s.copyWith(line: 'Rows of strange writing, carved into something big and grey.'),
          'label' => s.copyWith(
              line: 'A label. Part of the name has worn away.',
              lockedLine: 'A small label. Find the exhibit it describes first.',
            ),
          'plinth' => s.copyWith(
              line: 'Something glints in the shadows: a small golden key, with ROOM 4 cut into it. '
                  "Its tag reads: 'My next stop is where London's biggest bell rings.'",
              lockedLine: 'A railed plinth. First, see what it holds.',
            ),
          _ => s,
        },
    ],
  ),
};

/// [scene]'s traces noted in [letter]'s lines, one each, in order.
List<DeductionClue> _notes(DeductionScene scene, String letter) {
  final lines = letter.split('\n');
  return [for (final (i, c) in scene.clues.indexed) c.copyWith(line: lines[i])];
}

final Map<String, DeductionScene> ep01JuniorDeductions = {
  'm03': _m03.copyWith(
    // Never "behind" before the choice: the box is behind the stone.
    task: 'Find the three clues the thief left here.',
    chooseTask: 'Now, where is the box? Tap the place.',
    missLine: 'Nothing here. Look for marks the thief left.',
    clues: _notes(_m03, ((ep01Junior['missions'] as Map)['m03'] as Map)['letter'] as String),
    others: relined(_m03.others, const [
      'A wet bench. Nobody has sat here tonight.',
      'A heavy iron drain cover. There is nothing on it.',
      'An iron railing. There are only wet leaves here.',
      "Big Ben's great clock, high above you.",
      'The Houses of Parliament. Their windows are glowing.',
      'The old stones of the clock tower. Look at them closely.',
    ]),
  ),
};

final Map<String, DeductionScene> ep01MasterDeductions = {
  'm03': _m03.copyWith(
    task: 'The thief left three traces. Find them all.',
    chooseTask: 'Where do all three clues point? Tap the place.',
    missLine: 'Nothing here. Look for signs that someone was here tonight.',
    notPlaceLine: 'Nothing could be hidden there. Tap a possible hiding place.',
    clues: _notes(_m03, ((ep01Master['missions'] as Map)['m03'] as Map)['letter'] as String),
    others: relined(_m03.others, const [
      'A rain-soaked bench. No one has sat here tonight.',
      'A heavy iron drain cover, undisturbed.',
      'An iron railing, with only wet leaves caught in it.',
      "Big Ben's clock face glows high above you.",
      'The Houses of Parliament, their windows glowing in the dark.',
      'The old stones of the clock tower. Examine them closely.',
    ]),
  ),
};

final Map<String, DecodeScene> ep01JuniorDecodes = {
  'm05': _m05.copyWith(
    found: 'You found a strange card by the palace gate.',
    closerTask: 'A crown and a strange square symbol. What is it hiding?',
    missLine: 'Only wet stones and leaves here. Look for the card.',
  ),
};

final Map<String, DecodeScene> ep01MasterDecodes = {
  'm05': _m05.copyWith(
    found: 'Leaning against the palace gate is a mysterious card.',
    closerTask: 'A crown beside a strange square symbol. What secret does it keep?',
    missLine: 'Just wet stones and fallen leaves. The card is what matters.',
  ),
};

// ── Discovery Moments (titles are names: the same; the timing rule kept) ─
const Map<String, Discovery> ep01JuniorDiscoveries = {
  'm01': Discovery(
    type: DiscoveryType.newLead,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'THE BRITISH MUSEUM',
    detail: 'Old mummies and a famous stone: only one museum has both.',
    note: 'The suitcase was next to Platform 9.',
  ),
  'm02': Discovery(
    type: DiscoveryType.deduction,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'THE ROSETTA STONE',
    detail: 'Long ago, this stone helped people read old Egyptian writing.',
    note: 'The stone is in Room 4.',
  ),
  'm03': Discovery(
    type: DiscoveryType.evidenceFound,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'POCKET WATCH',
    detail: "The loose stone slides out. Behind it is the box, with the thief's pocket watch inside. "
        "Its hands have stopped at 7 o'clock.",
    showEvidence: true,
  ),
  'm04': Discovery(
    type: DiscoveryType.newLead,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'BUCKINGHAM PALACE',
    detail: "A red flag, a fountain and the King's home: the thief's last stop.",
    note: 'There were two white swans on the lake.',
  ),
  'm05': Discovery(
    type: DiscoveryType.evidenceFound,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'CROWN SYMBOL',
    detail: 'The crown code is decoded: four pictures, in the order of the four locks. Keep the card for the Royal Box.',
    showEvidence: true,
  ),
};

const Map<String, Discovery> ep01MasterDiscoveries = {
  'm01': Discovery(
    type: DiscoveryType.newLead,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'THE BRITISH MUSEUM',
    detail: 'Mummies from ancient Egypt and a famous stone: the letter could only mean one museum.',
    note: 'The suitcase was left beside Platform 9.',
  ),
  'm02': Discovery(
    type: DiscoveryType.deduction,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'THE ROSETTA STONE',
    detail: 'The stone that unlocked the secret of old Egyptian writing.',
    note: 'It stands in Room 4.',
  ),
  'm03': Discovery(
    type: DiscoveryType.evidenceFound,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'POCKET WATCH',
    detail: "The scratched stone slides free. Behind it waits the box, and in it, the thief's pocket watch, "
        "its hands frozen at 7 o'clock.",
    showEvidence: true,
  ),
  'm04': Discovery(
    type: DiscoveryType.newLead,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'BUCKINGHAM PALACE',
    detail: "A red flag, a fountain and a royal resident: the end of the thief's trail.",
    note: 'Two white swans glided across the lake.',
  ),
  'm05': Discovery(
    type: DiscoveryType.evidenceFound,
    timing: DiscoveryTiming.fromPuzzle,
    title: 'CROWN SYMBOL',
    detail: 'The code is broken: four pictures, in the very order of the locks. Guard the card well; the Royal Box awaits.',
    showEvidence: true,
  ),
};

// ── The parent report's English: as each level has it on its pages ──────
// M05 and the final ask little English at any level: their design is the
// base's, unchanged (no expressions to name).
final Map<String, LearningObjective> ep01JuniorLearning = {
  'm01': const LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.vocabulary,
    objective: '편지의 "old mummies from Egypt and a famous stone"을 이해하고, 공룡·기차·로켓이 아닌 박물관을 고른다. 보기에는 편지와 같은 단어가 없다.',
    expressions: ['old mummies from Egypt', 'a famous stone'],
  ),
  'm02': const LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.vocabulary,
    objective: '뜻풀이(a hard piece of rock)나 첫 편지의 "a famous stone"으로 단어를 떠올려 쓴다.',
    expressions: ['means a hard piece of rock', 'a famous stone'],
    recallFrom: 'm01',
  ),
  'm03': const LearningObjective(
    dependency: LanguageDependency.helpful,
    level: LearningLevel.exposure,
    skill: LanguageSkill.vocabulary,
    objective: '현장에서 찾은 단서 메모(footprints, lamp light, scratches)를 읽고 세 단서가 가리키는 숨긴 장소를 고른다.',
    expressions: ['footprints stop at the tower wall', 'The lamp light falls on one stone', 'fresh scratches'],
  ),
  'm04': const LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.vocabulary,
    objective: '그림에 이름이 없다. 편지의 묘사(a big palace, a red flag, a fountain in front of it)를 읽고 그림을 고른다.',
    expressions: ['a big palace', 'There is a fountain in front of it'],
  ),
  'm05': season1Learning['m05']!,
  'final': season1Learning['final']!,
};

final Map<String, LearningObjective> ep01MasterLearning = {
  'm01': const LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.vocabulary,
    objective: '편지의 "mummies from ancient Egypt rest beside a famous stone"을 이해하고, 공룡·기차·로켓이 아닌 박물관을 고른다. 보기에는 편지와 같은 단어가 없다.',
    expressions: ['mummies from ancient Egypt', 'a famous stone'],
  ),
  'm02': const LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.vocabulary,
    objective: '뜻풀이(a word for a hard piece of rock)나 첫 편지의 "a famous stone"으로 단어를 떠올려 쓴다.',
    expressions: ['a word for a hard piece of rock', 'a famous stone'],
    recallFrom: 'm01',
  ),
  'm03': const LearningObjective(
    dependency: LanguageDependency.helpful,
    level: LearningLevel.exposure,
    skill: LanguageSkill.vocabulary,
    objective: '현장에서 찾은 단서 메모(footprints end abruptly, casts its light, scratches look fresh)를 읽고 세 단서가 가리키는 숨긴 장소를 고른다.',
    expressions: ['end abruptly at the tower wall', 'casts its light on a single stone', 'the scratches look fresh'],
  ),
  'm04': const LearningObjective(
    dependency: LanguageDependency.essential,
    level: LearningLevel.comprehension,
    skill: LanguageSkill.vocabulary,
    objective: '그림에 이름이 없다. 편지의 묘사(a grand palace, a red flag from its roof, a fountain before it)를 읽고 그림을 고른다.',
    expressions: ['a grand palace', 'a fountain stands before it'],
  ),
  'm05': season1Learning['m05']!,
  'final': season1Learning['final']!,
};
