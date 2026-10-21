import 'dart:math' as math;
import 'dart:ui' show Offset, Rect;

import 'package:flutter/foundation.dart';

import 'scene_explore.dart' show ScenePixels;

/// The pictures Season 2's Case 03 is played on (the presentation of its
/// puzzles, never their answers): two records compared line by line, a lift
/// log read against its route plate, a padlock's three dials, and the
/// evidence linked to the case's questions in the hidden service room.
/// What is chosen there is checked as the mission's answer, through the
/// same check, feedback, save and rewards as any other answer. Every word
/// on a document is written by the app, on the picture's blank paper.

/// One line of a [RecordDoc] that can be picked: what it is ([label]) and
/// what it says ([value]).
@immutable
class RecordLine {
  const RecordLine({required this.id, required this.label, required this.value});

  /// The option it stands for (`notice:log` in the answer).
  final String id;
  final String label;
  final String value;
}

/// A record found at the place: its picture ([file], shown as [crop]), and
/// what is written on its blank paper ([writeOn], fractions of the whole
/// picture): a [title], the [lines] to compare and a last, unpicked [note].
@immutable
class RecordDoc {
  const RecordDoc({
    required this.id,
    required this.name,
    required this.file,
    required this.pixels,
    required this.crop,
    required this.writeOn,
    required this.title,
    required this.lines,
    required this.label,
    this.note,
  });

  /// Saved as looked at under this id.
  final String id;

  /// Its name on the page ("THE VISITOR NOTICE").
  final String name;
  final String file;
  final ScenePixels pixels;

  /// The part of the picture shown (fractions).
  final Rect crop;

  /// Where the writing goes (fractions of the whole picture).
  final Rect writeOn;
  final String title;
  final List<RecordLine> lines;
  final String? note;

  /// What the picture shows, for screen readers.
  final String label;

  /// Width / height of the part shown.
  double get aspect => crop.width * pixels.width / (crop.height * pixels.height);

  /// [writeOn] in fractions of the part shown.
  Rect get writeInCrop => Rect.fromLTRB(
        (writeOn.left - crop.left) / crop.width,
        (writeOn.top - crop.top) / crop.height,
        (writeOn.right - crop.left) / crop.width,
        (writeOn.bottom - crop.top) / crop.height,
      );
}

/// Two records of the same job, compared ([MissionType.matchPairs] with
/// one pair): a line picked on each, the answer `noticeLine:logLine`.
@immutable
class RecordsScene {
  const RecordsScene({
    required this.first,
    required this.second,
    required this.readTask,
    required this.compareTask,
    required this.checkLabel,
  });

  final RecordDoc first;
  final RecordDoc second;

  /// What to do before both are read, and once they are.
  final String readTask;
  final String compareTask;

  /// The button that checks the two lines picked.
  final String checkLabel;

  List<RecordDoc> get docs => [first, second];
}

/// A stop on the lift's route plate ([LiftScene]): its stud on the plate
/// ([at], fractions of the plate's picture), its name lettered beside it.
@immutable
class LiftStop {
  const LiftStop({required this.id, required this.name, required this.at, this.service = false});

  final String id;
  final String name;
  final Offset at;

  /// On the service route only (never a passenger stop).
  final bool service;
}

/// One trip in the lift log: when, from where, to where (`?`: not
/// written), and whether it was a service run (marked S).
@immutable
class LiftTrip {
  const LiftTrip({required this.time, required this.from, required this.to, this.service = false});

  final String time;
  final String from;
  final String to;
  final bool service;
}

/// The lift ([MissionType.multipleChoice]): its picture, where its route
/// plate and its log hang, and the two looked at closer. The missing stop
/// is chosen once both are read.
@immutable
class LiftScene {
  const LiftScene({
    required this.picture,
    required this.pixels,
    required this.place,
    required this.plateArea,
    required this.logArea,
    required this.plate,
    required this.platePixels,
    required this.stops,
    required this.passengerRoute,
    required this.serviceRoute,
    required this.legend,
    required this.legendAt,
    required this.log,
    required this.logPixels,
    required this.logCrop,
    required this.logWriteOn,
    required this.logTitle,
    required this.trips,
    required this.readTask,
    required this.chooseTask,
  });

  final String picture;
  final ScenePixels pixels;

  /// The place, for screen readers.
  final String place;

  /// Where the plate and the log are on the lift's picture (fractions).
  final Rect plateArea;
  final Rect logArea;

  final String plate;
  final ScenePixels platePixels;
  final List<LiftStop> stops;

  /// The stops' ids along each route, in order (drawn as lines between
  /// their studs: the passenger route whole, the service run dashed).
  final List<String> passengerRoute;
  final List<String> serviceRoute;

  /// Lettered under the tower on the plate ("S = SERVICE RUN"), at
  /// [legendAt] (fractions of the plate's picture).
  final String legend;
  final Rect legendAt;

  final String log;
  final ScenePixels logPixels;

  /// The page shown (fractions of the log's picture): the written one.
  final Rect logCrop;

  /// Where the trips are written (fractions of the log's picture).
  final Rect logWriteOn;

  /// Width / height of the page shown.
  double get logAspect => logCrop.width * logPixels.width / (logCrop.height * logPixels.height);

  /// [logWriteOn] in fractions of the page shown.
  Rect get logWriteInCrop => Rect.fromLTRB(
        (logWriteOn.left - logCrop.left) / logCrop.width,
        (logWriteOn.top - logCrop.top) / logCrop.height,
        (logWriteOn.right - logCrop.left) / logCrop.width,
        (logWriteOn.bottom - logCrop.top) / logCrop.height,
      );
  final String logTitle;
  final List<LiftTrip> trips;

  final String readTask;
  final String chooseTask;

  LiftStop stop(String id) => stops.firstWhere((s) => s.id == id);

  /// The ids the plate and the log are saved as looked at under.
  static const plateId = 'plate';
  static const logId = 'log';
}

/// A symbol on a [DialLockScene]'s dial: the option it stands for, and
/// where it is on the dial (clockwise from the top, in degrees, measured on
/// the dial's picture).
@immutable
class DialSymbol {
  const DialSymbol({required this.id, required this.name, required this.angle, required this.closeUp});

  final String id;
  final String name;
  final double angle;

  /// The symbol alone on the dial's picture (pixels of the dial), shown
  /// upright and large under its dial once it is set.
  final Rect closeUp;
}

/// A padlock with three dials ([MissionType.sequence]): the lock's picture
/// with three round windows cut through it, and one dial's picture turned
/// behind each window about its own [pivot]. The symbol under the lock's
/// fixed pointer (at the top of a window) is the one set; the three, left
/// to right, are the answer.
@immutable
class DialLockScene {
  const DialLockScene({
    required this.lock,
    required this.pixels,
    required this.view,
    required this.windows,
    required this.windowRadius,
    required this.dial,
    required this.dialPixels,
    required this.pivot,
    required this.showRadius,
    required this.symbols,
    required this.start,
    required this.label,
    required this.task,
    required this.openLabel,
  });

  final String lock;
  final ScenePixels pixels;

  /// The part of the lock shown (pixels of [lock]): its dial panel.
  final Rect view;

  /// The windows' centres, left to right, and their radius (pixels of
  /// [lock], measured on its transparent holes).
  final List<Offset> windows;
  final double windowRadius;

  final String dial;
  final ScenePixels dialPixels;

  /// The dial's centre of turning (pixels of [dial]).
  final Offset pivot;

  /// How far from the [pivot] the dial shows through a window (pixels of
  /// [dial]): its symbols in, its rim and pointer under the lock's bezel.
  final double showRadius;

  /// The dial's symbols, clockwise from the top.
  final List<DialSymbol> symbols;

  /// The symbol each dial starts on (an index into [symbols]): never the
  /// answer, on any dial.
  final List<int> start;

  /// What the lock shows, for screen readers.
  final String label;

  final String task;
  final String openLabel;

  /// How much the dial's picture is scaled to fit a window.
  double get dialScale => windowRadius / showRadius;

  /// The turn (radians, clockwise) that brings symbol [index] under the
  /// pointer.
  double turnFor(int index) => -symbols[index].angle * math.pi / 180;

  /// The symbol nearest the pointer when the dial is turned [turn]
  /// (radians, clockwise).
  int symbolAt(double turn) {
    final top = (-turn * 180 / math.pi) % 360;
    var best = 0;
    var bestGap = double.infinity;
    for (var i = 0; i < symbols.length; i++) {
      final d = (symbols[i].angle - top).abs() % 360;
      final gap = math.min(d, 360 - d);
      if (gap < bestGap) {
        bestGap = gap;
        best = i;
      }
    }
    return best;
  }
}

/// A question of the final, answered with evidence.
@immutable
class BoardQuestion {
  const BoardQuestion({required this.id, required this.text});

  final String id;
  final String text;
}

/// A piece of evidence on the final's board: its short id in the answer
/// (`e1`), the case's evidence it is ([evidenceId]).
@immutable
class BoardEvidence {
  const BoardEvidence({required this.id, required this.evidenceId});

  final String id;
  final String evidenceId;
}

/// What the evidence says, to choose from once every question is linked.
@immutable
class BoardConclusion {
  const BoardConclusion({required this.id, required this.text});

  final String id;
  final String text;
}

/// The final ([MissionType.matchPairs]): the evidence linked to each
/// question (`question:e1+e2`, the ids in [evidence]'s order), and the
/// conclusion chosen (`why:id`). Its stage: the time-recording machine,
/// shut and then open (two pictures in register), and the brass plaque
/// found inside, its message written by the app.
@immutable
class EvidenceBoardScene {
  const EvidenceBoardScene({
    required this.shut,
    required this.open,
    required this.pixels,
    required this.machineLabel,
    required this.questions,
    required this.evidence,
    required this.conclusionId,
    required this.conclusionQuestion,
    required this.conclusions,
    required this.linkTask,
    required this.concludeTask,
    required this.solveLabel,
    required this.plaque,
    required this.plaquePixels,
    required this.plaqueWriteOn,
    required this.plaqueMessage,
    required this.riverAt,
    required this.riverWord,
    required this.plaqueLabel,
  });

  final String shut;
  final String open;
  final ScenePixels pixels;
  final String machineLabel;

  final List<BoardQuestion> questions;
  final List<BoardEvidence> evidence;

  /// The conclusion's part in the answer (`why`), its question and choices.
  final String conclusionId;
  final String conclusionQuestion;
  final List<BoardConclusion> conclusions;

  final String linkTask;
  final String concludeTask;
  final String solveLabel;

  final String plaque;
  final ScenePixels plaquePixels;

  /// Where the message is engraved (fractions of [plaque]), and the word
  /// under its waves ([riverAt], fractions of [plaque]).
  final Rect plaqueWriteOn;
  final String plaqueMessage;
  final Rect riverAt;
  final String riverWord;
  final String plaqueLabel;

  /// The plaque's message, once read, is saved under this id.
  static const plaqueId = 'plaque';

  /// The answer of a board: each question's evidence (in [evidence]'s
  /// order), then the conclusion.
  String answerOf(Map<String, Set<String>> links, String? conclusion) => [
        for (final q in questions)
          '${q.id}:${[for (final e in evidence) if (links[q.id]?.contains(e.id) ?? false) e.id].join('+')}',
        '$conclusionId:${conclusion ?? ''}',
      ].join(',');
}

/// How far the detective has got on a Case 03 puzzle page: what is open
/// over it, and what is picked or set there. What must survive a restart
/// is saved by the page itself (`GameProgress.examined`, `puzzleStates`).
class TowerPuzzleProgress {
  /// A record's or the lift's plate/log id: open over the page.
  String? open;

  /// The records page: the record shown, and the line picked on each.
  int doc = 0;
  final Map<String, String> picked = {};

  /// The board: the question being linked.
  String? question;
}

/// The id a padlock's note is saved under once read (on the way to the
/// dials).
const noteId = 'note';

/// A board's links and conclusion as saved (`q1=e1;q2=e2;q3=e2+e3;why=c`),
/// and back. Unknown parts are dropped.
abstract final class BoardState {
  static String encode(Map<String, Set<String>> links, String? conclusion, EvidenceBoardScene scene) => [
        for (final q in scene.questions)
          '${q.id}=${[for (final e in scene.evidence) if (links[q.id]?.contains(e.id) ?? false) e.id].join('+')}',
        if (conclusion != null) '${scene.conclusionId}=$conclusion',
      ].join(';');

  static (Map<String, Set<String>>, String?) decode(String? saved, EvidenceBoardScene scene) {
    final links = <String, Set<String>>{};
    String? conclusion;
    final questions = {for (final q in scene.questions) q.id};
    final evidence = {for (final e in scene.evidence) e.id};
    final conclusions = {for (final c in scene.conclusions) c.id};
    for (final part in (saved ?? '').split(';')) {
      final [key, value] = switch (part.split('=')) {
        [final k, final v] => [k, v],
        _ => ['', ''],
      };
      if (questions.contains(key)) {
        links[key] = {for (final e in value.split('+')) if (evidence.contains(e)) e};
      } else if (key == scene.conclusionId && conclusions.contains(value)) {
        conclusion = value;
      }
    }
    return (links, conclusion);
  }
}

/// A dial lock's dials as saved (`2,0,1`: each dial's symbol index), and
/// back; anything else is the lock's start.
abstract final class DialState {
  static String encode(List<int> dials) => dials.join(',');

  static List<int> decode(String? saved, DialLockScene scene) {
    final parts = (saved ?? '').split(',');
    final read = [for (final p in parts) int.tryParse(p)];
    if (read.length != scene.windows.length || read.any((i) => i == null || i < 0 || i >= scene.symbols.length)) {
      return [...scene.start];
    }
    return [for (final i in read) i!];
  }
}
