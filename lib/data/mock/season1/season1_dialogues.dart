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
    background: 'assets/art/scenes/covent_garden/covent_garden_market_hall.png',
    // Wave 2.2: the mission said first — what to find out and how — so the
    // questions are asked for a reason (never the answer: a small bag).
    goal: 'Find out what the stranger carried.',
    how: 'Ask the witnesses. Look for two matching stories.',
    guide: 'Choose a witness to begin.',
    // The mission's question first (the same three questions and answers).
    questions: [
      DialogueQuestion(id: 'carry', text: 'What did he carry?'),
      DialogueQuestion(id: 'wearing', text: 'What was he wearing?'),
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
      DialogueStatement(id: 'flowerSeller.wearing', speakerId: 'flowerSeller', about: 'wearing', text: 'He was wearing a dark coat.'),
      DialogueStatement(id: 'flowerSeller.carry', speakerId: 'flowerSeller', about: 'carry', text: 'He carried a small bag.'),
      DialogueStatement(id: 'juggler.wearing', speakerId: 'juggler', about: 'wearing', text: 'He had a grey hat.'),
      DialogueStatement(id: 'juggler.carry', speakerId: 'juggler', about: 'carry', text: 'He carried a small bag.'),
      DialogueStatement(id: 'baker.wearing', speakerId: 'baker', about: 'wearing', text: 'He had a dark coat.'),
      DialogueStatement(id: 'baker.carry', speakerId: 'baker', about: 'carry', text: 'He had a big red umbrella.'),
    ],
    deduction: DialogueDeduction(
      topic: 'carry',
      question: 'Which two witnesses saw the same thing?',
      prompt: 'Choose two statements that match.',
      askLine: 'Ask two witnesses what the stranger carried.',
      askMoreLine: 'Good! Ask another witness what they saw him carry.',
      readyLine: 'Compare what the witnesses said he carried.',
      pair: {'flowerSeller.carry', 'juggler.carry'},
      conclusion: 'He carried a small bag.',
      answer: 'b',
      // The mission's own wrong-answer lines where they fit (the hat, the
      // umbrella), and the coat: two who agree, on what he wore.
      rules: [
        DialoguePairRule(
          all: {'flowerSeller.wearing', 'baker.wearing'},
          line: 'They agree — but a coat is worn, not carried.',
        ),
        DialoguePairRule(any: {'juggler.wearing'}, line: 'A hat is worn on the head, not carried. What did he hold?'),
        DialoguePairRule(
          any: {'baker.carry'},
          line: 'Only the baker saw an umbrella. Which thing do TWO witnesses agree on?',
        ),
      ],
      differentLine: 'These two say different things. Find two that say the same.',
      missingLine: 'Try another witness.',
    ),
  ),
};

/// The talk of [m], or null when [m] is played through its puzzle.
DialogueScene? dialogueOf(Mission m) => season1Dialogues[m.id];
