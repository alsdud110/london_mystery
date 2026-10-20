/// STEP 4 draft content for Paris Case 01. NOT wired into SeasonCatalog yet.
/// This is intentionally isolated: registering even one Paris case currently
/// makes SeasonAvailability treat the season as playable after London Case 12.
/// Also, FinalMissionScreen currently assumes a numeric combination lock.
/// Both must be addressed before this case is exposed to players.
const Map<String, dynamic> parisCase01DraftJson = {
  'id': 's2_ep01',
  'seasonId': 's2_paris',
  'number': 1,
  'title': 'The Ticking Watch',
  'synopsis': [
    'Three clocks at Gare du Nord show two different times.',
    'Someone turned one clock back by exactly one hour.',
    'A hidden compartment may reveal where the Clockmaker went.',
  ],
  'objectives': [
    'Investigate the station clocks.',
    'Read the station records.',
    'Open the hidden compartment.',
  ],
  'intro': [
    'Paris. Gare du Nord. 10:00 AM.',
    'Two station clocks say ten. The oldest clock says nine.',
    'A small brass mark is scratched beneath its face.',
    'The same mark was on the watch you found in London.',
  ],
  'missions': [
    {
      'id': 's2_ep01_m1',
      'number': 1,
      'title': 'The Three Clocks',
      'location': 'GARE DU NORD',
      'scene': 'clockFace',
      'story': [
        'Three clocks hang above the busy station hall.',
        'Two read 10:00. The oldest reads 9:00.',
      ],
      'letterIntro': 'A station notice is fixed beside the clocks.',
      'letter': 'ALL PLATFORM CLOCKS ARE CHECKED AT TEN.\n'
          'IF ONE CLOCK IS ONE HOUR BEHIND, REPORT IT TO THE LOST PROPERTY DESK.',
      'type': 'multipleChoice',
      'question': 'Which clock should you report?',
      'options': [
        {'id': 'old', 'label': 'The oldest clock: 9:00'},
        {'id': 'hall', 'label': 'The hall clock: 10:00'},
        {'id': 'platform', 'label': 'The platform clock: 10:00'},
      ],
      'answer': 'old',
      'hints': [
        'Look for the clock that is one hour behind ten.',
        'Behind means earlier. Which clock reads nine?',
      ],
      'successMessage': 'The oldest clock is one hour behind.',
      'clue': {
        'id': 's2_c01_clock',
        'title': 'One Hour Behind',
        'value': '9:00',
        'note': 'The old clock shows nine while the others show ten.',
      },
      'evidence': {
        'id': 's2_e01_clock_mark',
        'name': 'Brass Clock Mark',
        'icon': 'watch',
        'description': 'A tiny brass mark under the oldest station clock.',
        'inscription': 'T',
      },
      'transition': [
        'A station worker points to the lost property desk.',
        'Someone left an old train ticket there.',
      ],
      'nextMissionId': 's2_ep01_m2',
      'mapX': 0.42,
      'mapY': 0.45,
    },
    {
      'id': 's2_ep01_m2',
      'number': 2,
      'title': 'The Lost Ticket',
      'location': 'GARE DU NORD',
      'scene': 'waitingRoom',
      'story': [
        'At the lost property desk, you find a ticket and a folded note.',
        'The note describes what happened before the clocks changed.',
      ],
      'letterIntro': 'You unfold the station worker’s note.',
      'letter': 'FIRST, the hall clock struck ten.\n'
          'NEXT, a man with a pocket watch entered the waiting room.\n'
          'AFTER THAT, the old clock showed nine.',
      'type': 'sequence',
      'question': 'Put the events in the order written in the note.',
      'options': [
        {'id': 'bell', 'label': 'The hall clock struck ten'},
        {'id': 'man', 'label': 'The man entered the waiting room'},
        {'id': 'old', 'label': 'The old clock showed nine'},
      ],
      'answer': 'bell,man,old',
      'hints': [
        'FIRST tells you the beginning. NEXT tells you what follows.',
        'The hall clock rang, then the man arrived, then the old clock showed nine.',
      ],
      'successMessage': 'The clock changed after the stranger arrived.',
      'clue': {
        'id': 's2_c01_order',
        'title': 'The Station Timeline',
        'value': 'BELL → MAN → CLOCK',
        'note': 'The man arrived before the old clock showed nine.',
      },
      'evidence': {
        'id': 's2_e01_ticket',
        'name': 'Lost Train Ticket',
        'icon': 'letter',
        'description': 'A ticket found beside the station worker’s note.',
        'inscription': 'I',
      },
      'transition': [
        'The ticket has the same brass mark as the old clock.',
        'You return to the clock and find a small winding dial.',
      ],
      'nextMissionId': 's2_ep01_m3',
      'mapX': 0.55,
      'mapY': 0.52,
    },
    {
      'id': 's2_ep01_m3',
      'number': 3,
      'title': 'The Clockmaker’s Mark',
      'location': 'GARE DU NORD',
      'scene': 'clockFace',
      'story': [
        'Behind the old clock is a brass dial with movable hands.',
        'A message is engraved around the rim.',
      ],
      'letterIntro': 'You brush the dust from the engraved words.',
      'letter': 'THE OLD CLOCK IS ONE HOUR BEHIND.\n'
          'MOVE ITS HANDS FORWARD ONE HOUR TO MATCH THE HALL CLOCK.',
      'type': 'numberCode',
      'question': 'Set the old clock to the correct time.',
      'answer': '1000',
      'codeLength': 4,
      'hints': [
        'Forward means later, not earlier.',
        'One hour after 9:00 is 10:00.',
      ],
      'successMessage': 'The hands reach ten. A hidden latch clicks open.',
      'clue': {
        'id': 's2_c01_correct_time',
        'title': 'Restored Time',
        'value': '10:00',
        'note': 'The old clock must be moved forward one hour.',
      },
      'evidence': {
        'id': 's2_e01_winding_dial',
        'name': 'Winding Dial',
        'icon': 'watch',
        'description': 'The old clock’s brass dial, marked with another letter.',
        'inscription': 'M',
      },
      'transition': [
        'Behind the dial is a narrow compartment.',
        'Its lock has four letter slots. The final letter is stamped on the latch: E.',
      ],
      'mapX': 0.68,
      'mapY': 0.45,
    },
  ],
  'finalMission': {
    'id': 's2_ep01_final',
    'number': 4,
    'title': 'The Hidden Compartment',
    'location': 'GARE DU NORD',
    'scene': 'lockedDoor',
    'story': [
      'The compartment has four letter slots.',
      'Three letters came from the clock, ticket and winding dial. The latch holds the fourth.',
    ],
    'letterIntro': 'An instruction is engraved above the slots.',
    'letter': 'WHAT WAS STOLEN FROM PARIS?\n'
        'PUT THE FOUR LETTERS IN THE RIGHT ORDER.',
    'type': 'wordInput',
    'question': 'Arrange the collected letters to open the compartment.',
    'answer': 'TIME',
    'hints': [
      'Check the letters on your evidence and the latch.',
      'The clocks did not lose a person or a place. They lost TIME.',
    ],
    'successMessage': 'The lock opens. Inside is a sketch of Montmartre.',
    'transition': [
      'A charcoal drawing shows a hill above Paris.',
      'On the back, someone wrote: FIND THE PAINTER.',
      'Your next case begins in Montmartre.',
    ],
    'mapX': 0.74,
    'mapY': 0.56,
  },
  'glossary': {
    'behind': '뒤처진, 더 이른',
    'forward': '앞으로',
    'compartment': '숨겨진 수납칸',
    'engraved': '새겨진',
    'latch': '걸쇠',
  },
  'caseSummary': 'You restored the station clock and found the next clue in Montmartre.',
  'keyWords': ['behind', 'forward', 'first', 'next', 'after'],
  'hook': 'Who drew the Montmartre sketch, and why did the Clockmaker leave it?',
};
