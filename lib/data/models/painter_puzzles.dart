import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter/foundation.dart';

import 'investigation.dart' show InvestigationSpot;
import 'picture_spot.dart';
import 'scene_explore.dart' show ScenePixels, hitArea;

/// The pictures Season 2's Case 02 is played on (the presentation of its
/// puzzles, never their answers): the street and the painting of it, the
/// studio and its paintings, the painted-over sketch, the four canvases.
/// What is found or chosen there is checked as the mission's answer,
/// through the same check, feedback, save and rewards as any other answer.

/// A place and a painting of it, in register (the same size, every thing
/// where it is on both): the changes are found by comparing the two, on
/// either picture ([MissionType.spotDifferences]).
@immutable
class CompareScene {
  const CompareScene({
    required this.real,
    required this.painted,
    required this.pixels,
    required this.realLabel,
    required this.paintedLabel,
    required this.changes,
    required this.task,
    required this.missLine,
    required this.foundLines,
    required this.checklist,
    this.opening = const Rect.fromLTRB(0, 0, 1, 1),
  });

  /// The place as it is, and as it was painted.
  final String real;
  final String painted;
  final ScenePixels pixels;

  /// The two pictures' names on their tabs ("THE STREET", "THE PAINTING").
  final String realLabel;
  final String paintedLabel;

  /// Each change, by the option it answers: where it is (the same on both).
  final List<PictureSpot> changes;

  /// What to do; and what a tap on no change says.
  final String task;
  final String missLine;

  /// What finding each change says, by option id.
  final Map<String, String> foundLines;

  /// The note's line that sends the detective to each change, by option
  /// id: ticked on the page once that change is found.
  final Map<String, String> checklist;

  /// The part the page opens on (fractions).
  final Rect opening;

  /// The change at [point] (fractions), within [slop] (fractions of the
  /// shorter side) for a fingertip; null for none.
  PictureSpot? changeAt(Offset point, {double slop = 0}) {
    for (final c in changes) {
      if (c.contains(point, pixels: pixels)) return c;
    }
    for (final c in changes) {
      if (c.contains(point, pixels: pixels, slop: slop)) return c;
    }
    return null;
  }
}

/// One of the paintings found in a [StudioScene]: where it is in the room,
/// and its own picture, looked at closer.
@immutable
class StudioPainting {
  const StudioPainting({
    required this.id,
    required this.area,
    required this.mark,
    required this.file,
    required this.pixels,
    required this.label,
    required this.line,
  });

  /// The picture it is in the answer (`note:id`).
  final String id;
  final Rect area;
  final Offset mark;
  final String file;
  final ScenePixels pixels;

  /// What it shows, for screen readers.
  final String label;

  /// What finding it says.
  final String line;
}

/// A studio looked round ([MissionType.matchPairs]): its paintings found in
/// the room and its notes read on the desk, then each note joined to its
/// painting. The paintings are laid out in [order], never the notes' one.
@immutable
class StudioScene {
  const StudioScene({
    required this.picture,
    required this.pixels,
    required this.place,
    required this.paintings,
    required this.order,
    required this.desk,
    required this.deskMark,
    required this.others,
    required this.task,
    required this.deskTask,
    required this.matchTask,
    required this.missLine,
    required this.deskFirstLine,
    required this.matchHow,
    required this.matchPainting,
    required this.matchDone,
    required this.matchDrag,
    this.opening = const Rect.fromLTRB(0, 0, 1, 1),
  });

  final String picture;
  final ScenePixels pixels;

  /// The place's name, for screen readers.
  final String place;

  final List<StudioPainting> paintings;

  /// The paintings' ids as the matching page lays them out.
  final List<String> order;

  /// Where the notes are: read there.
  final InvestigationSpot desk;
  final Offset deskMark;

  /// Places that hold nothing: a tap says why.
  final List<InvestigationSpot> others;

  /// What to do now, as the look goes on: find the paintings ([task]),
  /// read the notes ([deskTask]), join them ([matchTask]).
  final String task;
  final String deskTask;
  final String matchTask;

  final String missLine;

  /// The notes before the paintings are all found.
  final String deskFirstLine;

  /// The matching page's step, as it goes: pick a note ([matchHow]), then
  /// its painting ([matchPainting], `{note}`: the note picked), then CHECK
  /// once every note has one ([matchDone]). Dragging is the other way
  /// ([matchDrag]), never needed.
  final String matchHow;
  final String matchPainting;
  final String matchDone;
  final String matchDrag;

  final Rect opening;

  StudioPainting painting(String id) => paintings.firstWhere((p) => p.id == id);

  /// What a tap at [point] (fractions) lands on: a painting, the desk, a
  /// place holding nothing; null for nothing.
  Object? hit(Offset point, {Size? slack}) => hitArea<Object>(point, [
        for (final p in paintings) (p, [p.area]),
        (desk, desk.areas),
        for (final o in others) (o, o.areas),
      ], slack: slack ?? Size.zero);
}

/// A picture painted over another, in register ([MissionType.revealLayer]):
/// the top one ([paint]) slid away across [canvas], left to right, shows the
/// one under it ([sketch]); then its [marks] are found on it.
@immutable
class LayerScene {
  const LayerScene({
    required this.paint,
    required this.sketch,
    required this.pixels,
    required this.view,
    required this.canvas,
    required this.marks,
    required this.paintLabel,
    required this.sketchLabel,
    required this.slideTask,
    required this.findTask,
    required this.missLine,
    required this.paintLine,
    required this.foundLines,
  });

  final String paint;
  final String sketch;
  final ScenePixels pixels;

  /// The part of the pictures shown (fractions): the canvas on its easel.
  final Rect view;

  /// The canvas the paint covers (fractions): the slide runs across it.
  final Rect canvas;

  final List<PictureSpot> marks;

  /// What each picture shows, for screen readers.
  final String paintLabel;
  final String sketchLabel;

  /// What to do: slide the paint ([slideTask]), then find ([findTask]).
  final String slideTask;
  final String findTask;

  /// A tap on nothing; a tap while the paint still covers the sketch.
  final String missLine;
  final String paintLine;

  /// What finding each mark says, by option id.
  final Map<String, String> foundLines;

  /// How far the paint is slid before the sketch can be read: most of it.
  static const readable = 0.85;

  /// Where the paint's edge is, [revealed] (0..1) of the way across the
  /// canvas (fractions of the picture).
  double edgeAt(double revealed) => canvas.left + canvas.width * revealed.clamp(0.0, 1.0);

  /// How far across the canvas a point [x] (fractions of the picture) is.
  double revealedAt(double x) => ((x - canvas.left) / canvas.width).clamp(0.0, 1.0);

  PictureSpot? markAt(Offset point, {double slop = 0}) {
    for (final m in marks) {
      if (m.contains(point, pixels: pixels)) return m;
    }
    for (final m in marks) {
      if (m.contains(point, pixels: pixels, slop: slop)) return m;
    }
    return null;
  }
}

/// One canvas to choose from ([MissionType.canvasChoice]): its picture and
/// its name on the page ("CANVAS A").
@immutable
class ChoiceCanvas {
  const ChoiceCanvas({required this.id, required this.file, required this.name});

  /// The option it stands for.
  final String id;
  final String file;
  final String name;
}

/// Canvases looked at one by one and the right one turned round: its back
/// ([back]) is a picture of its own, the message written on it by the app
/// in [writeOn] (fractions of [back]). Each canvas's picture shows it on
/// its easel in the studio; only its painting ([paint]) is shown.
@immutable
class CanvasScene {
  const CanvasScene({
    required this.canvases,
    required this.pixels,
    required this.paint,
    required this.back,
    required this.backPixels,
    required this.writeOn,
    required this.message,
    required this.backLabel,
    required this.chooseHow,
  });

  final List<ChoiceCanvas> canvases;
  final ScenePixels pixels;

  /// The painted part of every canvas's picture (fractions): inside the
  /// canvas's edges, none of the easel, the stretcher's side or the studio
  /// round it.
  final Rect paint;

  /// Width / height of [paint].
  double get paintAspect => paint.width * pixels.width / (paint.height * pixels.height);

  final String back;
  final ScenePixels backPixels;
  final Rect writeOn;

  /// What is written on the back (`\n`: where a line breaks).
  final String message;

  /// What the back shows, for screen readers.
  final String backLabel;

  final String chooseHow;

  ChoiceCanvas canvas(String id) => canvases.firstWhere((c) => c.id == id);
}

/// How far the detective has got on a [CompareScene], [StudioScene] or
/// [LayerScene]: what was found or looked at (saved too, as
/// `GameProgress.examined`, so it stays after a restart), and what is open
/// or picked on the page (kept while it is open).
class PicturePuzzleProgress {
  final Set<String> found = {};
  bool guideShown = false;

  /// A painting's id, `desk` or `match`: open over the picture.
  String? open;

  /// The matching page: each note's painting, by note id.
  final Map<String, String> pairs = {};

  /// The note picked to be joined next (tap-tap).
  String? pickedNote;

  /// The matching page has shown how a note is dragged onto a painting.
  bool matchDemoShown = false;

  bool has(String id) => found.contains(id);

  bool allFound(Iterable<String> ids) => ids.every(found.contains);

  /// The pairs as an answer (`note:painting`, in the notes' order).
  String answerOf(List<String> notes) => [for (final n in notes) '$n:${pairs[n]}'].join(',');
}

/// The id a studio's desk is saved under once its notes are read.
const deskId = 'desk';
