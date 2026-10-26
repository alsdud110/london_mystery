import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Where a mission's talk is saved: an entry of the case save's puzzle
/// states (`GameProgress.puzzleStates`, no key of its own), named as the
/// things looked at in a mission are (`missionId:thing`), so a mission
/// played with a talk and a puzzle keeps the two apart.
String caseTalkStateKey(String missionId) => '$missionId:talk';

/// A mission played with its own puzzle and talks around it (Season 2,
/// Cases 11–12): the talk [before] the puzzle (the puzzle opens once it is
/// finished), the puzzle as any mission's (its answer, evidence, XP and save
/// as always), then the talk [after] it (the person's reaction to what was
/// found, evidence shown) before the mission's Discovery Moment.
///
/// Each talk is saved as it goes in the case save's puzzle states, and once
/// the detective goes on from it, that is kept with the things looked at in
/// the mission (`GameProgress.examined`): both under [beforeKey] and
/// [afterKey] (no key of its own), so a talk heard is never played again
/// and the puzzle is never skipped.
@immutable
class TalkMission {
  const TalkMission({this.before, this.after}) : assert(before != null || after != null, 'a talk before or after');

  final TalkScene? before;
  final TalkScene? after;

  static String beforeKey(String missionId) => '$missionId:talk-before';
  static String afterKey(String missionId) => '$missionId:talk-after';
}

/// Who says a [TalkLine]: the person talked to, the story's narrator, or the
/// detective (the player).
enum TalkVoice { speaker, narrator, detective }

/// One line of a talk, one short sentence: what is said, by whom, and (for
/// the person talked to) the face they make while saying it ([mood], a key
/// of [TalkSpeaker.portraits]). A line without a mood keeps the face of the
/// line before it in the same beat.
@immutable
class TalkLine {
  const TalkLine(this.text, {this.mood}) : voice = TalkVoice.speaker;

  const TalkLine.narrator(this.text)
      : voice = TalkVoice.narrator,
        mood = null;

  const TalkLine.detective(this.text)
      : voice = TalkVoice.detective,
        mood = null;

  final String text;
  final TalkVoice voice;
  final String? mood;
}

/// The person talked to in a [TalkScene].
@immutable
class TalkSpeaker {
  const TalkSpeaker({
    required this.id,
    required this.name,
    this.hiddenName,
    this.revealedBy,
    this.portraits = const {},
    this.baseMood = 'base',
    this.description = '',
  });

  final String id;

  /// Their name plate once it is known ("VICTOR DELACROIX").
  final String name;

  /// Their name plate before [revealedBy] is done ("???"), when their name
  /// is not known yet. Null: [name] from the start.
  final String? hiddenName;

  /// The step (question or present) that makes their name known.
  final String? revealedBy;

  /// Their portrait for each mood, by mood ("base", "nervous"...). Empty:
  /// no portrait is shown (never a stand-in picture).
  final Map<String, String> portraits;

  /// The mood of a line that names none, at the start of a beat.
  final String baseMood;

  /// What the portrait shows, for screen readers.
  final String description;

  /// The picture of [mood] (else their [baseMood]'s), or null when none.
  String? portrait(String mood) => portraits[mood] ?? portraits[baseMood];
}

/// A question the detective can ask: its [beat] is the answer. It appears
/// once every step in [requires] is done; it can be asked again.
@immutable
class TalkQuestion {
  const TalkQuestion({required this.id, required this.text, required this.beat, this.requires = const {}});

  final String id;

  /// What the detective asks, in short English (the button).
  final String text;
  final List<TalkLine> beat;
  final Set<String> requires;
}

/// Evidence the detective can show, once every step in [requires] is done:
/// one of [accepted] (notebook evidence ids) plays [beat] and is done; any
/// other plays its line in [misses], else [miss] (never counted as wrong).
@immutable
class TalkPresent {
  const TalkPresent({
    required this.id,
    required this.prompt,
    required this.accepted,
    required this.beat,
    this.misses = const {},
    this.miss = const TalkLine('I don\'t see what that means.'),
    this.requires = const {},
  });

  final String id;

  /// What to show, said over the SHOW button ("Show Victor what you found.").
  final String prompt;
  final Set<String> accepted;
  final List<TalkLine> beat;
  final Map<String, TalkLine> misses;
  final TalkLine miss;
  final Set<String> requires;

  TalkLine missFor(String evidenceId) => misses[evidenceId] ?? miss;
}

/// One talk with one person: what is said first ([opening]), the questions
/// to ask and the evidence to show, in whatever order a case needs (each
/// step opened by the steps it [TalkQuestion.requires]). It is finished once
/// every step in [finishWhen] is done; then the detective goes on with
/// [finishLabel], and [answer] is what the talk gives (a mission's puzzle
/// answer, when the talk is the puzzle).
@immutable
class TalkScene {
  TalkScene({
    required this.id,
    required this.speaker,
    required this.goal,
    required this.opening,
    this.questions = const [],
    this.presents = const [],
    required this.finishWhen,
    this.place = '',
    this.background,
    this.finishLabel = 'CONTINUE',
    this.answer = '',
    this.earlierEvidence = const [],
  }) : assert(finishWhen.isNotEmpty, 'a talk must be able to finish') {
    final ids = [for (final q in questions) q.id, for (final p in presents) p.id];
    assert(ids.toSet().length == ids.length, 'step ids must be unique');
    assert(!ids.contains(openingId), '"$openingId" is the opening');
    assert(ids.toSet().containsAll(finishWhen), 'finishWhen names only steps of the talk');
  }

  /// The opening's beat id (never a step's).
  static const openingId = 'opening';

  final String id;
  final TalkSpeaker speaker;

  /// What the detective is finding out, one line over the talk.
  final String goal;
  final List<TalkLine> opening;
  final List<TalkQuestion> questions;
  final List<TalkPresent> presents;
  final Set<String> finishWhen;

  /// The place's name, and its picture behind the person (null: the night).
  final String place;
  final String? background;
  final String finishLabel;
  final String answer;

  /// Evidence of an earlier season's cases that may be shown here too (a
  /// Season 1 piece in Season 2: `ep12_e4`), when it is in the detective's
  /// hands (see `earlierSeasonEvidence`).
  final List<String> earlierEvidence;

  TalkQuestion? question(String id) {
    for (final q in questions) {
      if (q.id == id) return q;
    }
    return null;
  }

  TalkPresent? present(String id) {
    for (final p in presents) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// The lines of beat [beatId]: the opening, a step's, or a miss
  /// (`miss:presentId:evidenceId`, one line).
  List<TalkLine> beat(String beatId) {
    if (beatId == openingId) return opening;
    final miss = TalkProgress.parseMiss(beatId);
    if (miss != null) {
      final p = present(miss.$1);
      return p == null ? const [] : [p.missFor(miss.$2)];
    }
    return question(beatId)?.beat ?? present(beatId)?.beat ?? const [];
  }
}

/// How far the detective has got in a [TalkScene], saved as a short string
/// in the mission's puzzle state (see [encode]): the steps done (in order),
/// the beat being said and its line, and whether the opening was heard.
/// Pure: every change returns a new progress.
@immutable
class TalkProgress {
  const TalkProgress({this.done = const [], this.beatId = TalkScene.openingId, this.line = 0, this.openingSeen = false});

  /// The start of a talk: the opening, its first line.
  static const start = TalkProgress();

  /// Steps done, in the order they were done.
  final List<String> done;

  /// The beat being said (opening, a step, or a miss), and its line.
  final String beatId;
  final int line;

  /// The opening was heard to its end once (it can be skipped after).
  final bool openingSeen;

  bool isDone(String stepId) => done.contains(stepId);

  bool hasAll(Set<String> steps) => steps.every(done.contains);

  /// The beat id of showing [evidenceId] for [presentId] when it does not fit.
  static String missId(String presentId, String evidenceId) => 'miss:$presentId:$evidenceId';

  /// (presentId, evidenceId) of a miss beat id, or null.
  static (String, String)? parseMiss(String beatId) {
    if (!beatId.startsWith('miss:')) return null;
    final rest = beatId.substring(5);
    final at = rest.indexOf(':');
    if (at <= 0 || at == rest.length - 1) return null;
    return (rest.substring(0, at), rest.substring(at + 1));
  }

  /// The beat's lines are all said (on its last line, or past it).
  bool beatOver(TalkScene scene) => line >= scene.beat(beatId).length - 1;

  /// The line said now (null: an empty beat).
  TalkLine? current(TalkScene scene) {
    final lines = scene.beat(beatId);
    return lines.isEmpty ? null : lines[line.clamp(0, lines.length - 1)];
  }

  /// The face the person makes now: the last mood named up to this line in
  /// the beat, else their base mood.
  String mood(TalkScene scene) {
    final lines = scene.beat(beatId);
    for (var i = line.clamp(0, lines.length - 1); i >= 0 && lines.isNotEmpty; i--) {
      final m = lines[i].mood;
      if (lines[i].voice == TalkVoice.speaker && m != null) return m;
    }
    return scene.speaker.baseMood;
  }

  /// The name plate now ([TalkSpeaker.hiddenName] until it is revealed).
  String speakerName(TalkScene scene) {
    final s = scene.speaker;
    if (s.hiddenName == null || s.revealedBy == null || isDone(s.revealedBy!)) return s.name;
    return s.hiddenName!;
  }

  /// Every step in [TalkScene.finishWhen] is done.
  bool finished(TalkScene scene) => hasAll(scene.finishWhen);

  /// The questions that can be asked now (asked ones included: they can be
  /// asked again), in the scene's order. None while a beat is still said.
  List<TalkQuestion> questions(TalkScene scene) => [
        for (final q in scene.questions)
          if (hasAll(q.requires)) q,
      ];

  /// The evidence that can be shown now: open steps not done yet.
  List<TalkPresent> presents(TalkScene scene) => [
        for (final p in scene.presents)
          if (!isDone(p.id) && hasAll(p.requires)) p,
      ];

  /// What to show next, said over SHOW: the first open present still
  /// needed to finish, else the first open one (null: nothing to show).
  TalkPresent? nextPresent(TalkScene scene) {
    final open = presents(scene);
    for (final p in open) {
      if (scene.finishWhen.contains(p.id)) return p;
    }
    return open.isEmpty ? null : open.first;
  }

  /// The next line of the beat; past its end, it stays on the last line
  /// (the opening heard once is then [openingSeen]).
  TalkProgress next(TalkScene scene) {
    final last = scene.beat(beatId).length - 1;
    if (line < last) return _copy(line: line + 1, openingSeen: openingSeen || (beatId == TalkScene.openingId && line + 1 >= last));
    return _copy(openingSeen: openingSeen || beatId == TalkScene.openingId);
  }

  /// The beat said at once to its last line (a beat heard before, skipped).
  TalkProgress skip(TalkScene scene) {
    final last = scene.beat(beatId).length - 1;
    return _copy(line: last < 0 ? 0 : last, openingSeen: openingSeen || beatId == TalkScene.openingId);
  }

  /// Asks [questionId] (when it can be asked): its beat, from its first
  /// line; the step is done (once).
  TalkProgress ask(TalkScene scene, String questionId) {
    final q = scene.question(questionId);
    if (q == null || !hasAll(q.requires)) return this;
    return TalkProgress(
      done: isDone(q.id) ? done : [...done, q.id],
      beatId: q.id,
      openingSeen: true,
    );
  }

  /// Shows [evidenceId]: the open present that takes it plays its beat and
  /// is done; otherwise the miss line of the present asked for next.
  /// Returns the new progress and whether the evidence fitted.
  (TalkProgress, bool) show(TalkScene scene, String evidenceId) {
    final open = presents(scene);
    for (final p in open) {
      if (p.accepted.contains(evidenceId)) {
        return (TalkProgress(done: [...done, p.id], beatId: p.id, openingSeen: true), true);
      }
    }
    final asked = nextPresent(scene);
    if (asked == null) return (this, false);
    return (TalkProgress(done: done, beatId: missId(asked.id, evidenceId), openingSeen: true), false);
  }

  /// A saved talk as a string (the mission's puzzle state): JSON.
  String encode() => jsonEncode({'d': done, 'b': beatId, 'l': line, if (openingSeen) 'o': 1});

  /// The talk as it was left (see [encode]); unreadable, or naming a step
  /// or beat [scene] does not have, it starts afresh (steps it does not know
  /// are dropped).
  static TalkProgress decode(String? raw, TalkScene scene) {
    if (raw == null || raw.isEmpty) return start;
    try {
      final json = jsonDecode(raw);
      if (json is! Map) return start;
      final ids = {for (final q in scene.questions) q.id, for (final p in scene.presents) p.id};
      final d = json['d'] is List ? [for (final s in json['d'] as List) if (s is String && ids.contains(s)) s] : <String>[];
      final seen = <String>{};
      final done = [for (final s in d) if (seen.add(s)) s];
      var beatId = json['b'] is String ? json['b'] as String : TalkScene.openingId;
      if (scene.beat(beatId).isEmpty) beatId = TalkScene.openingId;
      final lines = scene.beat(beatId).length;
      final rawLine = json['l'] is num ? (json['l'] as num).toInt() : 0;
      return TalkProgress(
        done: done,
        beatId: beatId,
        line: lines == 0 ? 0 : rawLine.clamp(0, lines - 1),
        openingSeen: json['o'] == 1 || done.isNotEmpty,
      );
    } on FormatException {
      return start;
    }
  }

  TalkProgress _copy({int? line, bool? openingSeen}) =>
      TalkProgress(done: done, beatId: beatId, line: line ?? this.line, openingSeen: openingSeen ?? this.openingSeen);

  @override
  bool operator ==(Object other) =>
      other is TalkProgress &&
      listEquals(other.done, done) &&
      other.beatId == beatId &&
      other.line == line &&
      other.openingSeen == openingSeen;

  @override
  int get hashCode => Object.hash(Object.hashAll(done), beatId, line, openingSeen);
}
