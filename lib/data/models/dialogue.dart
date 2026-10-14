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

/// The deduction that ends the talk: two witnesses' stories about its
/// [topic] put side by side, and the detective saying whether they match.
@immutable
class DialogueDeduction {
  const DialogueDeduction({
    required this.topic,
    required this.pair,
    required this.answer,
    required this.question,
    required this.choose,
    required this.foundLine,
    required this.readyLine,
    required this.matchLine,
    required this.differentLine,
    required this.otherPairLine,
    required this.lookAgainLine,
    this.witnesses = 2,
  });

  /// The question the deduction is about ("carry"): only statements about
  /// it are compared, and asking it is what opens comparing.
  final String topic;

  /// Witnesses whose statement about [topic] must be heard before comparing:
  /// any of them, matching or not (comparing is the detective's to do).
  final int witnesses;

  /// The two statements that match (the answer).
  final Set<String> pair;

  /// The mission's puzzle answer the deduction gives (submitted once).
  final String answer;

  /// What the comparing page asks of two stories ("Do their stories
  /// match?"), and, with more stories than two, how to begin ("Choose two
  /// witnesses to compare.").
  final String question;
  final String choose;

  /// What to do next, said in the talk: one witness heard on [topic]
  /// ([foundLine]); enough to compare ([readyLine]).
  final String foundLine;
  final String readyLine;

  /// Said when the detective is right: the stories match ([matchLine]);
  /// they differ and someone else is still to be asked ([differentLine]), or
  /// every witness was heard and another pair is to be compared
  /// ([otherPairLine]).
  final String matchLine;
  final String differentLine;
  final String otherPairLine;

  /// Said when the detective is wrong about two stories (never which way).
  final String lookAgainLine;

  /// Whether statements [a] and [b] say the same thing (they answer it).
  bool matches(String a, String b) => a != b && {a, b}.containsAll(pair);
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
  /// carried."), shown as the mission, and how ("Two witnesses may have
  /// seen the same thing."). Never the answer.
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

  /// The questions besides the mission's are shown (the detective opened
  /// them; they stay open from witness to witness until closed).
  bool othersOpen = false;

  /// How many statements on the topic had been heard when two were rightly
  /// found different and there was no one else to compare them with: until
  /// another is heard, the next thing to do is ask another witness.
  int? differentAt;

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
