import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';

/// A question the detective can put to any witness of a [DialogueScene].
@immutable
class DialogueQuestion {
  const DialogueQuestion({required this.id, required this.text});

  final String id;

  /// What the detective asks, in short English ("What did he carry?").
  final String text;
}

/// What one witness says to one question. When it is something the case
/// needs, it is also a statement ([statementId]) written in the
/// detective's notes the first time it is heard.
@immutable
class DialogueAnswer {
  const DialogueAnswer(this.line, {this.statementId});

  final String line;
  final String? statementId;
}

/// A person the detective talks to.
@immutable
class DialogueSpeaker {
  const DialogueSpeaker({
    required this.id,
    required this.name,
    required this.title,
    required this.portrait,
    required this.description,
    required this.greeting,
    required this.answers,
    this.face = const Offset(0.5, 0.25),
  });

  final String id;

  /// How the story names them ("The flower seller").
  final String name;

  /// Their name plate ("THE FLOWER SELLER").
  final String title;

  /// Their portrait (a paper print, see `ArtAssets.characters`).
  final String portrait;

  /// What the portrait shows, for screen readers.
  final String description;

  /// What they say first, before any question.
  final String greeting;

  /// Their answer to each question, by question id.
  final Map<String, DialogueAnswer> answers;

  /// Where their face is in the portrait (fractions): the small round
  /// picture used to choose them shows this part.
  final Offset face;
}

/// A statement: what a witness said that the detective writes down.
@immutable
class DialogueStatement {
  const DialogueStatement({
    required this.id,
    required this.speakerId,
    required this.about,
    required this.text,
    required this.thing,
  });

  final String id;
  final String speakerId;

  /// The question it answers (what it is about: what he wore, what he
  /// carried).
  final String about;

  /// The statement as it was said, word for word.
  final String text;

  /// The thing it describes ("a small bag", "a dark coat"): two statements
  /// match when they describe the same thing. Never shown; the detective
  /// reads the words.
  final String thing;
}

/// The deduction that ends the talk: two of the statements heard, chosen
/// by the detective and put side by side; the game says at once what the
/// two show. The two that match about the [topic]
/// ([pair]) answer it; then the [then] statements, if not heard yet, are
/// still to be found before the mission ends (one more thing to check, for
/// the missions after it).
@immutable
class DialogueDeduction {
  const DialogueDeduction({
    required this.topic,
    required this.pair,
    required this.answer,
    required this.askLine,
    required this.anotherLine,
    required this.readyLine,
    required this.compareGoal,
    required this.compareHow,
    required this.matchLine,
    required this.offTopicLine,
    required this.checkLine,
    required this.differentLine,
    required this.retryLine,
    this.then = const {},
    this.thenGoal = '',
    this.thenHow = '',
    this.doneLine = '',
    this.notesLine = '',
    this.witnesses = 2,
  });

  /// What the deduction is about ("carry").
  final String topic;

  /// The two statements that match about [topic] (the answer).
  final Set<String> pair;

  /// The mission's puzzle answer the deduction gives (submitted once).
  final String answer;

  /// What to do next, said in the talk: a witness chosen, nothing heard
  /// yet ([askLine]); statements from one witness only ([anotherLine]);
  /// enough to compare ([readyLine]).
  final String askLine;
  final String anotherLine;
  final String readyLine;

  /// Witnesses whose statements must be heard before comparing (about
  /// anything: sorting them out is the detective's).
  final int witnesses;

  /// The comparing page: what to find ([compareGoal]) and how ([compareHow]).
  final String compareGoal;
  final String compareHow;

  /// What two chosen statements show: the two that answer it ([matchLine]);
  /// two that match but not about [topic] — the match acknowledged
  /// ([offTopicLine]), then the mission recalled ([checkLine], never what
  /// the answer is); two about different things ([differentLine], then
  /// [retryLine]).
  final String matchLine;
  final String offTopicLine;
  final String checkLine;
  final String differentLine;
  final String retryLine;

  /// Statements still to be found once the deduction is made (if not heard
  /// already), and the lines that ask for them without naming them: what to
  /// find out ([thenGoal]), how ([thenHow]), and once everything is found
  /// (the deduction made, they heard): what was found ([doneLine]) and where
  /// it is kept ([notesLine]).
  final Set<String> then;
  final String thenGoal;
  final String thenHow;
  final String doneLine;
  final String notesLine;

  /// Whether [a] and [b] answer the deduction (in either order).
  bool solves(String a, String b) => a != b && {a, b}.containsAll(pair);
}

/// A mission played by talking to the people at its place (presentation
/// only: nothing here is saved). The detective chooses who to talk to and
/// what to ask; the statements heard are written down; two of them, put
/// side by side, answer the mission's puzzle with [DialogueDeduction.answer],
/// through the same check, save and rewards as any other answer.
@immutable
class DialogueScene {
  const DialogueScene({
    required this.place,
    required this.background,
    required this.goal,
    required this.how,
    required this.guide,
    required this.speakers,
    required this.questions,
    required this.statements,
    required this.deduction,
  });

  /// The place's name on the bar ("MARKET HALL").
  final String place;

  /// The place, behind the people (a picture file).
  final String background;

  /// What the detective is here to find out ("Find out what the stranger
  /// carried."), shown as the mission, and how ("Ask what they saw. You
  /// may find different clues."). Never the answer.
  final String goal;
  final String how;

  /// The first thing to do, in one line ("Talk to a witness.").
  final String guide;

  final List<DialogueSpeaker> speakers;
  final List<DialogueQuestion> questions;
  final List<DialogueStatement> statements;
  final DialogueDeduction deduction;

  DialogueSpeaker speaker(String id) => speakers.firstWhere((s) => s.id == id);

  DialogueStatement statement(String id) => statements.firstWhere((s) => s.id == id);

  /// Whether statements [a] and [b] describe the same thing.
  bool matches(String a, String b) => a != b && statement(a).thing == statement(b).thing;

  /// How many witnesses have given a statement in [heard].
  int witnessesHeard(List<String> heard) => {for (final id in heard) statement(id).speakerId}.length;

  /// Whether comparing is open: statements from enough witnesses.
  bool canCompare(List<String> heard) => witnessesHeard(heard) >= deduction.witnesses;

  /// Whether every statement still to be found once the deduction is made
  /// is in [heard] (the mission can end).
  bool described(List<String> heard) => heard.toSet().containsAll(deduction.then);

  /// The statements a finished talk is sure to have heard: the two that
  /// answered it and the ones found after (what the notebook keeps).
  List<DialogueStatement> recorded() => [
        for (final s in statements)
          if (deduction.pair.contains(s.id) || deduction.then.contains(s.id)) s,
      ];
}

/// How far the detective has got in a [DialogueScene]: who they are talking
/// to, what they asked whom, and the statements heard (in the order heard).
/// Kept by the page while it is open; never saved.
class DialogueProgress {
  String? speakerId;

  /// The question last asked of the current speaker (null: their greeting).
  String? questionId;

  /// Asked questions, as `speakerId/questionId`.
  final Set<String> asked = {};
  final List<String> heard = [];

  /// The statement heard for the first time by the last question, if any.
  String? fresh;

  bool introSeen = false;

  /// The deduction is made (the two that answer it were matched): what is
  /// left is [DialogueDeduction.then].
  bool solved = false;

  bool hasAsked(String speakerId, String questionId) => asked.contains('$speakerId/$questionId');

  /// Talk to [id]: their greeting, until a question is asked.
  void talkTo(String id) {
    speakerId = id;
    questionId = null;
    fresh = null;
  }

  /// Ask the current speaker [question] in [scene]: their answer, and its
  /// statement written down the first time it is heard (never twice).
  DialogueAnswer ask(DialogueScene scene, String question) {
    final speaker = scene.speaker(speakerId!);
    final answer = speaker.answers[question]!;
    questionId = question;
    asked.add('${speaker.id}/$question');
    final s = answer.statementId;
    fresh = s != null && !heard.contains(s) ? s : null;
    if (fresh != null) heard.add(fresh!);
    return answer;
  }
}
