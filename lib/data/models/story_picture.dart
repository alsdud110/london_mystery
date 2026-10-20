import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';

import 'scene_explore.dart' show ScenePixels;
import 'station_clocks.dart' show PaintedClock;

/// How a [StoryPicture] is laid on a mission's place page.
enum StoryFrame {
  /// A paper print, a little askew: a place seen whole or in part.
  print,

  /// A round magnifying lens ringed in brass: a thing looked at up close.
  lens,
}

/// A picture of the story at one moment of a case: one of its files, or a
/// part of it ([crop], fractions; the whole by default), with the hands of
/// any [clocks] painted on it drawn over it. [cutOut]: an object on
/// transparency, shown whole (never cropped to fill).
@immutable
class StoryPicture {
  const StoryPicture({
    required this.file,
    required this.pixels,
    required this.label,
    this.crop = const Rect.fromLTRB(0, 0, 1, 1),
    this.clocks = const [],
    this.frame = StoryFrame.print,
    this.cutOut = false,
  });

  final String file;
  final ScenePixels pixels;

  /// What it shows, for screen readers.
  final String label;

  final Rect crop;
  final List<PaintedClock> clocks;
  final StoryFrame frame;
  final bool cutOut;

  /// Width / height of the part shown.
  double get aspect => crop.width * pixels.width / (crop.height * pixels.height);
}

/// A mission's pictures as the story goes through it (presentation only):
/// its place page before the letter ([place]), and the scene after it is
/// solved — the picture under the words ([after]) and the next place, on
/// its NEW PLACE UNLOCKED card ([next]). The final case: [after] is under
/// the scene after the case.
@immutable
class StoryScenes {
  const StoryScenes({this.place, this.after, this.next});

  final StoryPicture? place;
  final StoryPicture? after;
  final StoryPicture? next;
}
