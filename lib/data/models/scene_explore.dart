import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter/foundation.dart';

import 'investigation.dart' show InvestigationSpot;

/// A picture's own size in pixels, to write places on it as they are
/// measured on the file and keep them as fractions (0..1) of its width and
/// height: a tap lands on the same spot at every screen size.
@immutable
class ScenePixels {
  const ScenePixels(this.width, this.height);

  final double width;
  final double height;

  double get aspect => width / height;

  Rect rect(double left, double top, double right, double bottom) =>
      Rect.fromLTRB(left / width, top / height, right / width, bottom / height);

  Offset at(double x, double y) => Offset(x / width, y / height);
}

/// What looking at a [ExploreSpot] does.
enum ExploreKind {
  /// Opens the mission's document where it was left (the letter in the
  /// suitcase): read there, sealed the first time.
  document,

  /// A short note of something worth remembering (a sign, a number): its
  /// card says it, and the search goes on. Never needed to go on.
  note,

  /// Opens the choice the mission's puzzle asks for (the poster board): the
  /// detective picks one, and it is checked as the puzzle's answer.
  choice,
}

/// A thing to look at in an [ExploreScene]: where it is, what it is, and
/// what looking at it does ([kind]).
@immutable
class ExploreSpot {
  const ExploreSpot({
    required this.id,
    required this.kind,
    required this.title,
    required this.label,
    required this.areas,
    required this.mark,
    this.line = '',
    this.requires,
    this.lockedLine = '',
    this.unreadLine = '',
  });

  final String id;
  final ExploreKind kind;

  /// Its name on its card ("THE OLD SUITCASE").
  final String title;

  /// What it is, for screen readers ("The old suitcase on the bench").
  final String label;

  /// Where a tap reaches it (fractions of the picture).
  final List<Rect> areas;

  /// Where its small glass sits on the picture, showing it can be looked at
  /// (fractions of the picture): a tick once it has been.
  final Offset mark;

  /// A [ExploreKind.note]'s words on its card.
  final String line;

  /// A spot that must be looked at first ([lockedLine] says so until then;
  /// [unreadLine] once it was, while its document is still sealed).
  final String? requires;
  final String lockedLine;
  final String unreadLine;
}

/// One picture of an [ExploreScene]'s choice, standing for the puzzle's
/// option [optionId] (its name and words are the option's label).
@immutable
class ExplorePicture {
  const ExplorePicture({required this.optionId, required this.picture, required this.description});

  final String optionId;

  /// Its file, shown whole.
  final String picture;

  /// What it shows, for screen readers (never which one is right).
  final String description;
}

/// A mission played by looking round its place (the presentation of the
/// mission's puzzle, never saved): the detective taps what they see; one
/// thing holds the mission's document, one the choice its puzzle asks for.
/// The choice is checked as the puzzle's answer, through the same check,
/// feedback, save and rewards as any other answer; looking is never a
/// wrong answer.
@immutable
class ExploreScene {
  const ExploreScene({
    required this.picture,
    required this.pixels,
    required this.place,
    required this.task,
    required this.nextTask,
    required this.spots,
    required this.others,
    required this.missLine,
    required this.choiceTitle,
    required this.choiceHow,
    required this.choices,
    required this.pictureAspect,
    required this.guideAt,
    this.inside = const Rect.fromLTRB(0, 0, 1, 1),
    this.opening = const Rect.fromLTRB(0, 0, 1, 1),
    this.tapGuide = 'Tap what you see to investigate.',
    this.zoomGuide = 'Pinch to look closer.',
    this.documentLabel = 'Letter',
  });

  /// The place's picture (its file) and its size in pixels.
  final String picture;
  final ScenePixels pixels;

  /// The place's name, for screen readers ("King's Cross, at night").
  final String place;

  /// What to do first ("Look around the station…"), then once the
  /// document is read ([nextTask]).
  final String task;
  final String nextTask;

  final List<ExploreSpot> spots;

  /// Places that hold nothing: a tap says why (`InvestigationSpot.line`).
  final List<InvestigationSpot> others;

  /// Said when a tap is on no listed place.
  final String missLine;

  /// The choice's page: its heading ("NEXT DESTINATION"), how to choose,
  /// and its pictures (each the file's width / height: [pictureAspect]).
  final String choiceTitle;
  final String choiceHow;
  final List<ExplorePicture> choices;
  final double pictureAspect;

  /// Where the first "tap here" rings show how to look (fractions): on the
  /// first thing to look at.
  final Offset guideAt;

  /// The picture inside its own printed paper edge, and the part the page
  /// opens on (every [spots] in it; pinching out shows the rest).
  final Rect inside;
  final Rect opening;

  final String tapGuide;
  final String zoomGuide;

  /// The quiet link that opens the document again, once it is read.
  final String documentLabel;

  ExploreSpot spot(String id) => spots.firstWhere((s) => s.id == id);

  ExploreSpot? get document => spots.where((s) => s.kind == ExploreKind.document).firstOrNull;

  /// What a tap at [point] (fractions) lands on: a spot, then a place
  /// holding nothing; null for nothing. A tap just outside every area
  /// ([slack], fractions of the width and height) counts for the nearest
  /// one that close, so a small place is still a fingertip wide.
  Object? hit(Offset point, {Size slack = Size.zero}) => hitArea<Object>(point, [
        for (final s in spots) (s, s.areas),
        for (final o in others) (o, o.areas),
      ], slack: slack);
}

/// What a tap at [point] (fractions of a picture) lands on among
/// [targets] (each with its areas, in order of priority): the first whose
/// area holds it; else, within [slack] (fractions of the width and height)
/// of an area, the nearest; else null. A small place is still a fingertip
/// wide, and a tap inside an area always counts for it.
T? hitArea<T>(Offset point, List<(T, List<Rect>)> targets, {Size slack = Size.zero}) {
  for (final (t, areas) in targets) {
    if (areas.any((r) => r.contains(point))) return t;
  }
  if (slack.isEmpty) return null;
  T? nearest;
  var best = double.infinity;
  for (final (t, areas) in targets) {
    for (final r in areas) {
      final dx = (point.dx < r.left ? r.left - point.dx : (point.dx > r.right ? point.dx - r.right : 0)) / slack.width;
      final dy = (point.dy < r.top ? r.top - point.dy : (point.dy > r.bottom ? point.dy - r.bottom : 0)) / slack.height;
      final d = dx > dy ? dx : dy;
      if (d <= 1 && d < best) {
        best = d;
        nearest = t;
      }
    }
  }
  return nearest;
}

/// How far the detective has got in an [ExploreScene]: what was looked at,
/// whether the document was opened, what is open over the picture, the
/// picture chosen. Kept by the page while it is open; never saved (the
/// mission is saved when it is solved, as any puzzle).
class ExploreProgress {
  final Set<String> looked = {};
  bool documentOpened = false;
  bool guideShown = false;

  /// The spot whose card or choice is open over the picture, if any.
  String? open;

  /// The option chosen on the choice page (not yet checked).
  String? chosen;

  bool hasLooked(String id) => looked.contains(id);

  /// Whether [s] can be looked at now (what it needs was looked at, and a
  /// choice needs the document read).
  bool canOpen(ExploreScene scene, ExploreSpot s) {
    final need = s.requires;
    if (need == null) return true;
    final first = scene.spot(need);
    return looked.contains(need) && (first.kind != ExploreKind.document || documentOpened);
  }
}
