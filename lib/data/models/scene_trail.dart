import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter/foundation.dart';

import 'scene_explore.dart' show ScenePixels, hitArea;

/// One place of a [TrailScene] where a trace was left (a footprint by the
/// shop), standing for the puzzle's option [optionId] (its name is the
/// option's label).
@immutable
class TrailStop {
  const TrailStop({required this.optionId, required this.areas, required this.mark});

  final String optionId;

  /// Where a tap picks it (fractions of the picture).
  final List<Rect> areas;

  /// Where its step number is written once picked (fractions): on the trace.
  final Offset mark;
}

/// A sequence puzzle played on its place (the presentation of the mission's
/// `sequence` puzzle, never saved): the detective taps the traces in the
/// picture in the order the letter's words give, each one numbered as it is
/// picked. The order is checked as the puzzle's answer (its option ids
/// joined by commas), through the same check, feedback, save and rewards as
/// the buttons it replaces. Every trace looks the same in the picture: only
/// the English tells their order.
@immutable
class TrailScene {
  const TrailScene({
    required this.picture,
    required this.pixels,
    required this.place,
    required this.lead,
    required this.guide,
    required this.stops,
    this.inside = const Rect.fromLTRB(0, 0, 1, 1),
  });

  /// The place's picture (its file) and its size in pixels.
  final String picture;
  final ScenePixels pixels;

  /// The place, for screen readers ("The Great Court, its floor").
  final String place;

  /// One line above the picture: what the traces are and what to do.
  final String lead;

  /// How to play, one quiet line under it.
  final String guide;

  final List<TrailStop> stops;

  /// The picture inside its own printed paper edge: the part shown.
  final Rect inside;

  /// The same trail in other words (a level's): its picture and stops never
  /// change.
  TrailScene copyWith({String? lead, String? guide}) => TrailScene(
        picture: picture,
        pixels: pixels,
        place: place,
        lead: lead ?? this.lead,
        guide: guide ?? this.guide,
        stops: stops,
        inside: inside,
      );

  /// The stop at [point] (fractions of the picture), if any; a tap just
  /// outside an area ([slack]) counts for the nearest one that close.
  TrailStop? hit(Offset point, {Size slack = Size.zero}) =>
      hitArea<TrailStop>(point, [for (final s in stops) (s, s.areas)], slack: slack);
}
