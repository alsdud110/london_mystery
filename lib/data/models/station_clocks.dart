import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter/foundation.dart';

import 'investigation.dart' show InvestigationSpot;
import 'scene_explore.dart' show ScenePixels, hitArea;

/// A clock painted on a place's picture without hands: the app draws them,
/// pointing where the picture's own numerals are (a painted dial is never a
/// perfect circle, so the hands aim at its numerals, not at angles).
///
/// It stands for the puzzle's option [optionId]: choosing it is checked as
/// that answer.
@immutable
class PaintedClock {
  const PaintedClock({
    required this.optionId,
    required this.name,
    required this.label,
    required this.time,
    required this.centre,
    required this.twelve,
    required this.hourNumeral,
    required this.area,
    required this.closeUp,
    required this.mark,
  });

  final String optionId;

  /// Its name on its card ("THE HALL CLOCK").
  final String name;

  /// What it is, for screen readers ("The big clock on the hall's wall").
  final String label;

  /// The time it shows ("10:00"): its hour hand on [hourNumeral], its
  /// minute hand on XII.
  final String time;

  /// The pivot of its hands, its XII, and the numeral its hour hand points
  /// at (fractions of the picture).
  final Offset centre;
  final Offset twelve;
  final Offset hourNumeral;

  /// Where a tap reaches it, and the part of the picture its close-up shows
  /// (a square on screen: fractions of the picture).
  final Rect area;
  final Rect closeUp;

  /// Where its small glass sits (fractions of the picture).
  final Offset mark;
}

/// One train on a [StationClocksScene]'s departure board.
@immutable
class Departure {
  const Departure({required this.time, required this.to, required this.platform});

  final String time;
  final String to;
  final String platform;
}

/// A place in a [StationClocksScene] with its own page: the departure board
/// (read), or the desk where the odd clock is reported (the choice).
@immutable
class StationSpot {
  const StationSpot({
    required this.id,
    required this.title,
    required this.label,
    required this.area,
    required this.mark,
    this.outline,
  });

  final String id;
  final String title;
  final String label;
  final Rect area;
  final Offset mark;

  /// The thing itself on the picture (the board's panel), outlined in gold
  /// when it is the next place to look; its [area] when null.
  final Rect? outline;
}

/// A mission played in a station hall with clocks to compare (the
/// presentation of the mission's choice puzzle, never its answer): the
/// detective looks at each clock up close, reads the notice on the
/// departure board, then reports one clock at the desk the notice names.
/// The clock reported is checked as the puzzle's answer, through the same
/// check, feedback, save and rewards as any other answer; looking is never
/// a wrong answer.
@immutable
class StationClocksScene {
  const StationClocksScene({
    required this.picture,
    required this.pixels,
    required this.place,
    required this.task,
    required this.boardTask,
    required this.reportTask,
    required this.clocks,
    required this.board,
    required this.desk,
    required this.others,
    required this.missLine,
    required this.boardTitle,
    required this.departures,
    required this.noticeTitle,
    required this.notice,
    required this.noticeKeys,
    required this.boardFirstLine,
    required this.clocksFirstLine,
    required this.reportHow,
    required this.guideAt,
    this.inside = const Rect.fromLTRB(0, 0, 1, 1),
    this.opening = const Rect.fromLTRB(0, 0, 1, 1),
    this.tapGuide = 'Tap what you see to investigate.',
    this.zoomGuide = 'Pinch to look closer.',
  });

  /// The place's picture (its file) and its size in pixels.
  final String picture;
  final ScenePixels pixels;

  /// The place's name, for screen readers.
  final String place;

  /// What to do now, as the look goes on: the clocks first ([task]); every
  /// clock seen, the departure board ([boardTask]); the clocks and the
  /// notice seen, the report at the desk ([reportTask]). Where to look,
  /// never which clock.
  final String task;
  final String boardTask;
  final String reportTask;

  final List<PaintedClock> clocks;
  final StationSpot board;
  final StationSpot desk;

  /// Places that hold nothing: a tap says why.
  final List<InvestigationSpot> others;
  final String missLine;

  /// The departure board's page: its heading, its trains, and the notice
  /// under them (its lines; [noticeKeys] are set in gold).
  final String boardTitle;
  final List<Departure> departures;
  final String noticeTitle;
  final List<String> notice;
  final List<String> noticeKeys;

  /// The desk before it can be used: the notice not read yet, or a clock
  /// not looked at yet.
  final String boardFirstLine;
  final String clocksFirstLine;

  /// How to choose on the desk's page.
  final String reportHow;

  /// Where the first "tap here" rings show (fractions).
  final Offset guideAt;

  /// The picture inside its paper edge, and the part the page opens on.
  final Rect inside;
  final Rect opening;

  final String tapGuide;
  final String zoomGuide;

  PaintedClock clock(String optionId) => clocks.firstWhere((c) => c.optionId == optionId);

  /// What a tap at [point] (fractions) lands on: a clock, the board, the
  /// desk, a place holding nothing; null for nothing.
  Object? hit(Offset point, {Size slack = Size.zero}) => hitArea<Object>(point, [
        for (final c in clocks) (c, [c.area]),
        (board, [board.area]),
        (desk, [desk.area]),
        for (final o in others) (o, o.areas),
      ], slack: slack);
}

/// How far the detective has got in a [StationClocksScene]: what was looked
/// at (saved, so the clocks and the notice stay seen after a restart: see
/// `GameProgress.examined`), what is open over the picture and the clock
/// chosen on the desk's page (kept while the page is open).
class StationClocksProgress {
  final Set<String> looked = {};
  bool guideShown = false;

  /// A clock's option id, `board` or `desk`: open over the picture.
  String? open;

  /// The clock picked on the desk's page (not yet checked).
  String? chosen;

  bool hasLooked(String id) => looked.contains(id);

  bool allClocksLooked(StationClocksScene scene) => scene.clocks.every((c) => looked.contains(c.optionId));

  bool boardRead(StationClocksScene scene) => looked.contains(scene.board.id);

  bool canReport(StationClocksScene scene) => boardRead(scene) && allClocksLooked(scene);

  /// The desk has been gone to (its guide stops once it has).
  bool deskVisited(StationClocksScene scene) => looked.contains(scene.desk.id);

  /// What to do now (see [StationClocksScene.task]).
  String taskOf(StationClocksScene scene) => !allClocksLooked(scene)
      ? scene.task
      : !boardRead(scene)
      ? scene.boardTask
      : scene.reportTask;

  /// The next place to look, to be pointed out on the picture: the board
  /// once every clock is seen, the desk once the notice is read too (until
  /// it is gone to); null while the clocks are still to see.
  String? guideTo(StationClocksScene scene) => !allClocksLooked(scene)
      ? null
      : !boardRead(scene)
      ? scene.board.id
      : deskVisited(scene)
      ? null
      : scene.desk.id;
}
