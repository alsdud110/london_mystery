import 'dart:ui' show Offset;

import '../../models/dialogue.dart';
import '../../models/mission.dart';

/// Missions played by talking to the people at their place (presentation
/// only: nothing here is saved). Mission id → its [DialogueScene]. A mission
/// not listed is played through its puzzle as before.
///
/// The case data is left as it is: the talk ends with the puzzle's own
/// answer, so the solve, its Clue and Evidence, XP, coins and the save are
/// the ones the puzzle always gave.
const Map<String, DialogueScene> season1Dialogues = {
  // ── Case 06 M1 — The Market Hall ──────────────────────────────────────
  // The three witnesses of the case (their notes are the mission's letter):
  // asked what he wore and what he carried, they say what the notes say; two
  // of them agree on what he CARRIED (a small bag, `b`). The juggler's grey
  // hat is the colour Mission 02's card asks for. "When" tells the night,
  // not a clue: not every question gives a statement.
  'ep06_m1': DialogueScene(
    place: 'MARKET HALL',
    background: 'assets/seasons/season_01_london/locations/covent_garden/covent_garden_market_hall.png',
    // Wave 2.5: what to do, never which answer — the mission, then how
    // (talk, ask, the clues may differ). The three questions stand alike: the
    // one about what he carried is not marked out.
    goal: 'Find out what the stranger carried.',
    how: 'Ask what they saw. You may find different clues.',
    guide: 'Talk to a witness.',
    questions: [
      DialogueQuestion(id: 'wearing', text: 'What was he wearing?'),
      DialogueQuestion(id: 'carry', text: 'What did he carry?'),
      DialogueQuestion(id: 'when', text: 'When did you see him?'),
    ],
    speakers: [
      DialogueSpeaker(
        id: 'flowerSeller',
        name: 'The flower seller',
        title: 'THE FLOWER SELLER',
        portrait: 'assets/art/characters/flower_seller.png',
        description: 'a young woman in a straw bonnet and a red shawl, with a basket of flowers',
        face: Offset(0.50, 0.21),
        greeting: 'The man in the dark coat? Oh yes, I saw him.',
        answers: {
          'wearing': DialogueAnswer('He was wearing a dark coat.', statementId: 'flowerSeller.wearing'),
          'carry': DialogueAnswer('He carried a small bag.', statementId: 'flowerSeller.carry'),
          'when': DialogueAnswer('Last night, just before midnight.'),
        },
      ),
      DialogueSpeaker(
        id: 'juggler',
        name: 'The juggler',
        title: 'THE JUGGLER',
        portrait: 'assets/art/characters/juggler.png',
        description: 'a young man in a striped waistcoat, juggling three balls',
        face: Offset(0.56, 0.19),
        greeting: 'I saw him while I was juggling!',
        answers: {
          'wearing': DialogueAnswer('He had a grey hat.', statementId: 'juggler.wearing'),
          'carry': DialogueAnswer('He carried a small bag.', statementId: 'juggler.carry'),
          'when': DialogueAnswer('Last night. The church clock was nearly at twelve.'),
        },
      ),
      DialogueSpeaker(
        id: 'baker',
        name: 'The baker',
        title: 'THE BAKER',
        portrait: 'assets/art/characters/baker.png',
        description: 'a bearded baker in a white cap and apron, holding a round loaf',
        face: Offset(0.50, 0.22),
        greeting: 'That stranger? He walked right past my stall.',
        answers: {
          'wearing': DialogueAnswer('He had a dark coat.', statementId: 'baker.wearing'),
          'carry': DialogueAnswer('He had a big red umbrella.', statementId: 'baker.carry'),
          'when': DialogueAnswer('Last night, when I was closing my stall.'),
        },
      ),
    ],
    statements: [
      DialogueStatement(id: 'flowerSeller.wearing', speakerId: 'flowerSeller', about: 'wearing', text: 'He was wearing a dark coat.', thing: 'a dark coat'),
      DialogueStatement(id: 'flowerSeller.carry', speakerId: 'flowerSeller', about: 'carry', text: 'He carried a small bag.', thing: 'a small bag'),
      DialogueStatement(id: 'juggler.wearing', speakerId: 'juggler', about: 'wearing', text: 'He had a grey hat.', thing: 'a grey hat'),
      DialogueStatement(id: 'juggler.carry', speakerId: 'juggler', about: 'carry', text: 'He carried a small bag.', thing: 'a small bag'),
      DialogueStatement(id: 'baker.wearing', speakerId: 'baker', about: 'wearing', text: 'He had a dark coat.', thing: 'a dark coat'),
      DialogueStatement(id: 'baker.carry', speakerId: 'baker', about: 'carry', text: 'He had a big red umbrella.', thing: 'a big red umbrella'),
    ],
    // Wave 2.5 / 2.5.1: the detective chooses two of the statements heard —
    // about anything — and the game says at once what they show (two coats
    // match too, but he wore them). A wrong pair is never recorded, never
    // says which is right. The two bags answer it (`b`); then what he wore is
    // still to be found if it was not heard (the next mission asks the
    // colour of his hat) — asked for without naming it.
    deduction: DialogueDeduction(
      topic: 'carry',
      pair: {'flowerSeller.carry', 'juggler.carry'},
      answer: 'b',
      askLine: 'Ask a question.',
      anotherLine: 'Ask another witness.',
      readyLine: 'Compare two statements.',
      compareGoal: 'Find two witnesses who saw him carry the same thing.',
      compareHow: 'Tap two statements to compare them.',
      matchLine: 'Both witnesses saw the same thing being carried.',
      offTopicLine: 'Both witnesses described the same clothing.',
      checkLine: "You're looking for something he carried, not wore.",
      differentLine: 'These witnesses described different things.',
      retryLine: 'Try another pair.',
      then: {'juggler.wearing'},
      thenGoal: 'Find out what the stranger was wearing.',
      thenHow: "Ask the witnesses about the stranger's clothes.",
      doneLine: "You learned something about the stranger's appearance.",
      notesLine: 'Your witness notes are ready.',
    ),
  ),
};

/// The talk of [m], or null when [m] is played through its puzzle.
DialogueScene? dialogueOf(Mission m) => season1Dialogues[m.id];
