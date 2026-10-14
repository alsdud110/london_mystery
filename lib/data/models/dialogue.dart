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
  const DialogueStatement({required this.id, required this.speakerId, required this.about, required this.text});

  final String id;
  final String speakerId;

  /// The question it answers (what it is about: what he wore, what he
  /// carried).
  final String about;

  /// The statement as it was said, word for word.
  final String text;
}

/// What a pair of statements tells the detective when they are put side by
/// side and are not the answer: one line, the first rule that fits. A rule
/// fits when the pair holds [all] of its statements, or any of [any].
@immutable
class DialoguePairRule {
  const DialoguePairRule({this.all = const {}, this.any = const {}, required this.line});

  final Set<String> all;
  final Set<String> any;
  final String line;

  bool fits(Set<String> pair) =>
      (all.isNotEmpty && pair.containsAll(all)) || (any.isNotEmpty && pair.any(any.contains));
}

/// The deduction that ends the talk: two statements put side by side.
@immutable
class DialogueDeduction {
  const DialogueDeduction({
    required this.question,
    required this.pair,
    required this.conclusion,
    required this.answer,
    required this.rules,
    required this.differentLine,
    required this.missingLine,
    required this.topic,
    required this.prompt,
    required this.askLine,
    required this.askMoreLine,
    required this.readyLine,
    this.witnesses = 2,
  });

  /// What the detective works out, as the comparing page asks it ("Which
  /// two witnesses saw the same thing?").
  final String question;

  /// How to answer it there ("Choose two statements that match.").
  final String prompt;

  /// The question the deduction is about ("carry"): only statements about
  /// it are compared, and asking it is what opens comparing.
  final String topic;

  /// Witnesses whose statement about [topic] must be heard before comparing:
  /// any of them, matching or not (comparing is the detective's to do).
  final int witnesses;

  /// What to do next, said under the questions while comparing is not open
  /// yet: none about [topic] heard ([askLine]), one ([askMoreLine]); and
  /// once it is open ([readyLine]).
  final String askLine;
  final String askMoreLine;
  final String readyLine;

  /// The two statements that answer it.
  final Set<String> pair;

  /// What they show, said once the pair is linked.
  final String conclusion;

  /// The mission's puzzle answer the deduction gives (submitted once).
  final String answer;

  /// What a wrong pair shows, in order (the first that fits).
  final List<DialoguePairRule> rules;

  /// A wrong pair no rule fits: two statements that say different things.
  final String differentLine;

  /// Added to a wrong link's line when no two of the statements compared
  /// match: there is someone else to ask (never who).
  final String missingLine;

  /// What linking statements [a] and [b] shows: null when they answer the
  /// deduction, else the line that says why not.
  String? judge(String a, String b) {
    final picked = {a, b};
    if (picked.length == 2 && picked.containsAll(pair)) return null;
    for (final r in rules) {
      if (r.fits(picked)) return r.line;
    }
    return differentLine;
  }
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
  /// carried."), shown as the mission, and how ("Ask the witnesses. Look
  /// for two matching stories."). Never the answer.
  final String goal;
  final String how;

  /// The first thing to do, in one line ("Choose a witness to begin.").
  final String guide;

  final List<DialogueSpeaker> speakers;
  final List<DialogueQuestion> questions;
  final List<DialogueStatement> statements;
  final DialogueDeduction deduction;

  DialogueSpeaker speaker(String id) => speakers.firstWhere((s) => s.id == id);

  DialogueStatement statement(String id) => statements.firstWhere((s) => s.id == id);

  /// Of [heard], the statements the deduction compares (about its topic),
  /// in the order heard.
  List<String> comparable(List<String> heard) => [
        for (final id in heard)
          if (statement(id).about == deduction.topic) id,
      ];

  /// How many witnesses' statements about the topic are in [heard].
  int witnessesHeard(List<String> heard) => {for (final id in comparable(heard)) statement(id).speakerId}.length;

  /// Whether comparing is open: enough witnesses heard on the topic.
  bool canCompare(List<String> heard) => witnessesHeard(heard) >= deduction.witnesses;
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
