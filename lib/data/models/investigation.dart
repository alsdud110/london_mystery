import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter/foundation.dart';

import 'mission.dart';

/// A thing to find in an [InvestigationScene]: where it is in the picture,
/// the line of the mission's document that says where (the English the
/// detective has to read), and how it is laid on the picture once found.
///
/// Areas and positions are fractions (0..1) of the picture's width and
/// height, so a tap lands on the same spot at every screen size.
@immutable
class InvestigationFind {
  const InvestigationFind({
    required this.id,
    required this.name,
    required this.title,
    required this.reportLine,
    required this.spot,
    required this.areas,
    required this.foundLine,
    required this.picture,
    required this.at,
    required this.width,
    this.pictureAspect = 1,
    this.squash = 1,
    this.turn = 0,
  });

  final String id;

  /// What it is, as the report names it ("The red button").
  final String name;

  /// Its name on the find card ("RED BUTTON").
  final String title;

  /// The document's line that says where it is, word for word.
  final String reportLine;

  /// Where it is, for screen readers ("Under the bench"): the place of the
  /// spot, never the thing.
  final String spot;

  /// Where a tap finds it.
  final List<Rect> areas;

  /// Said on the find card ("You found a red button under the bench!").
  final String foundLine;

  /// The picture of the thing on transparency, laid where it was found.
  final String picture;

  /// The centre of [picture] on the scene, and its width (both fractions of
  /// the scene); [pictureAspect] is the picture file's width / height.
  final Offset at;
  final double width;
  final double pictureAspect;

  /// Vertical scale of [picture] on the scene (below 1: lying flat on the
  /// floor, seen in perspective) and its turn in radians.
  final double squash;
  final double turn;
}

/// A place in the picture that holds nothing to find. Tapping it says why
/// ("On the bench? The report says under it."), so a wrong place teaches the
/// word instead of only saying no.
@immutable
class InvestigationSpot {
  const InvestigationSpot({required this.label, required this.areas, required this.line});

  /// What it is, for screen readers.
  final String label;
  final List<Rect> areas;
  final String line;
}

/// A mission played by searching its place (the presentation of the
/// mission's puzzle, never saved): find every [finds] where the mission's
/// document says it is; the last one found answers the puzzle with
/// [answer], through the same check, save and rewards as any other answer.
@immutable
class InvestigationScene {
  const InvestigationScene({
    required this.artwork,
    required this.task,
    required this.documentTitle,
    required this.finds,
    required this.spots,
    required this.answer,
    required this.missLine,
    required this.doneLine,
    required this.arrival,
    required this.guideAt,
    this.opening = const Rect.fromLTRB(0, 0, 1, 1),
    this.inside = const Rect.fromLTRB(0, 0, 1, 1),
    this.startLabel = 'START THE SEARCH',
    this.documentLabel = 'Report',
    this.tapGuide = 'Tap the picture to investigate!',
    this.zoomGuide = 'Pinch to zoom in for a closer look.',
  });

  /// The picture searched (its file: `ArtAssets.scenes`).
  final Artwork artwork;

  /// What to do, in one line (the search's heading).
  final String task;

  /// The heading of the document's lines pinned under the picture.
  final String documentTitle;

  final List<InvestigationFind> finds;
  final List<InvestigationSpot> spots;

  /// The mission's answer the search gives (its puzzle's answer).
  final String answer;

  /// Said when a tap finds nothing and is no listed place.
  final String missLine;

  /// Said when the last thing is found.
  final String doneLine;

  /// What the detective sees on arriving, before the document is handed
  /// over (one or two short lines): why the document is read.
  final List<String> arrival;

  /// Where the first "tap here" ripple shows how to search (fractions of
  /// the picture): a place holding nothing, so it never points at a thing.
  final Offset guideAt;

  /// The part of the picture the search opens on (fractions): every thing
  /// to find is in it, so the opening view is as close as it can be while
  /// none of them is off the screen. It also sets how tall the picture's
  /// place is: this part full width (a drag shows the rest).
  final Rect opening;

  /// The picture inside its own printed paper edge (fractions): only this
  /// part is shown in the search, the room seen as a room, not a print.
  final Rect inside;

  /// How to search: tap the picture (the main line), and look closer (the
  /// quiet line).
  final String tapGuide;
  final String zoomGuide;

  /// The document page's button that starts the search.
  final String startLabel;

  /// The quiet link that opens the whole document again.
  final String documentLabel;

  /// What a tap at [point] (fractions of the picture) lands on: a thing
  /// (found or not) or a listed place; null for nothing. Things come first:
  /// a place never hides a thing.
  ///
  /// A tap just outside every area ([slack]: how far, as fractions of the
  /// picture's width and height) counts for the nearest one it is that
  /// close to, so a small place is still a fingertip wide. A tap inside an
  /// area always counts for that area.
  Object? hit(Offset point, {Size slack = Size.zero}) {
    for (final f in finds) {
      if (f.areas.any((r) => r.contains(point))) return f;
    }
    for (final s in spots) {
      if (s.areas.any((r) => r.contains(point))) return s;
    }
    if (slack.isEmpty) return null;
    Object? nearest;
    var best = double.infinity;
    void check(Object target, List<Rect> areas) {
      for (final r in areas) {
        final dx = (point.dx < r.left ? r.left - point.dx : (point.dx > r.right ? point.dx - r.right : 0)) / slack.width;
        final dy = (point.dy < r.top ? r.top - point.dy : (point.dy > r.bottom ? point.dy - r.bottom : 0)) / slack.height;
        final d = dx > dy ? dx : dy;
        if (d <= 1 && d < best) {
          best = d;
          nearest = target;
        }
      }
    }

    for (final f in finds) {
      check(f, f.areas);
    }
    for (final s in spots) {
      check(s, s.areas);
    }
    return nearest;
  }
}
