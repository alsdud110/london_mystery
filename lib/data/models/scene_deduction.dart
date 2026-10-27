import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter/foundation.dart';

import 'investigation.dart' show InvestigationSpot;
import 'scene_explore.dart' show ScenePixels, hitArea;

/// A trace in a [DeductionScene]'s picture (footprints, a light, scratches):
/// tapped, it is noted with its [line] — one line of the mission's letter,
/// the detective's notes.
@immutable
class DeductionClue {
  const DeductionClue({
    required this.id,
    required this.label,
    required this.areas,
    required this.mark,
    required this.line,
  });

  final String id;

  /// What it is, for screen readers ("Muddy footprints on the wet stones").
  final String label;

  /// Where a tap reaches it (fractions of the picture).
  final List<Rect> areas;

  /// Where its small glass sits (fractions): a tick once it is noted.
  final Offset mark;

  /// The note it gives, word for word one line of the mission's letter.
  final String line;

  /// The same trace with a level's note (its letter's line).
  DeductionClue copyWith({String? line}) =>
      DeductionClue(id: id, label: label, areas: areas, mark: mark, line: line ?? this.line);
}

/// A place the box could be hidden, standing for the puzzle's option
/// [optionId] (its name is the option's label).
@immutable
class DeductionPlace {
  const DeductionPlace({required this.optionId, required this.areas, required this.mark});

  final String optionId;

  /// Where a tap chooses it (fractions of the picture).
  final List<Rect> areas;

  /// Where its marker sits once places can be chosen (fractions).
  final Offset mark;
}

/// A mission played by reading its place (the presentation of the mission's
/// puzzle, never saved): the detective notes the scene's traces, then
/// chooses, in the picture, the one place they all point to. The place is
/// checked as the puzzle's answer (its option), through the same check,
/// feedback, save and rewards as any other answer; noting a trace or
/// tapping elsewhere is never a wrong answer.
@immutable
class DeductionScene {
  const DeductionScene({
    required this.picture,
    required this.pixels,
    required this.place,
    required this.task,
    required this.chooseTask,
    required this.missLine,
    required this.notPlaceLine,
    required this.clues,
    required this.others,
    required this.places,
    required this.guideAt,
    this.inside = const Rect.fromLTRB(0, 0, 1, 1),
    this.opening = const Rect.fromLTRB(0, 0, 1, 1),
    this.tapGuide = 'Tap the picture to investigate.',
    this.action = 'SEARCH HERE',
  });

  /// The place's picture (its file) and its size in pixels.
  final String picture;
  final ScenePixels pixels;

  /// The place, for screen readers ("The foot of Big Ben, at night").
  final String place;

  /// What to do first (find the traces), then once all are noted (choose).
  final String task;
  final String chooseTask;

  /// Said when a tap is on no listed place; [notPlaceLine] once choosing,
  /// when a tap is on no place the box could be.
  final String missLine;
  final String notPlaceLine;

  final List<DeductionClue> clues;

  /// Places that hold nothing: a tap says why.
  final List<InvestigationSpot> others;

  /// The places the box could be: chosen once every clue is noted.
  final List<DeductionPlace> places;

  /// Where the first "tap here" ripple shows how to look (fractions): a
  /// place holding nothing, so it never points at a clue.
  final Offset guideAt;

  /// The picture inside its own printed paper edge, and the part the page
  /// opens on, shown whole and full width (a drag shows the rest).
  final Rect inside;
  final Rect opening;

  final String tapGuide;

  /// The button that searches the chosen place.
  final String action;

  /// The same place in other words (a level's): its picture, traces and
  /// places never change.
  DeductionScene copyWith({
    String? task,
    String? chooseTask,
    String? missLine,
    String? notPlaceLine,
    List<DeductionClue>? clues,
    List<InvestigationSpot>? others,
  }) =>
      DeductionScene(
        picture: picture,
        pixels: pixels,
        place: place,
        task: task ?? this.task,
        chooseTask: chooseTask ?? this.chooseTask,
        missLine: missLine ?? this.missLine,
        notPlaceLine: notPlaceLine ?? this.notPlaceLine,
        clues: clues ?? this.clues,
        others: others ?? this.others,
        places: places,
        guideAt: guideAt,
        inside: inside,
        opening: opening,
        tapGuide: tapGuide,
        action: action,
      );

  DeductionClue clue(String id) => clues.firstWhere((c) => c.id == id);
  DeductionPlace placeOf(String optionId) => places.firstWhere((p) => p.optionId == optionId);

  /// What a tap at [point] (fractions) lands on while traces are looked
  /// for: a clue, then a place holding nothing; null for nothing.
  Object? hitClue(Offset point, {Size slack = Size.zero}) => hitArea<Object>(point, [
        for (final c in clues) (c, c.areas),
        for (final o in others) (o, o.areas),
      ], slack: slack);

  /// The place the box could be at [point] (fractions), once choosing.
  DeductionPlace? hitPlace(Offset point, {Size slack = Size.zero}) =>
      hitArea<DeductionPlace>(point, [for (final p in places) (p, p.areas)], slack: slack);
}

/// How far the detective has got in a [DeductionScene]: the clues noted (in
/// the order found), the place chosen (not yet searched). Kept by the page
/// while it is open; never saved.
class DeductionProgress {
  final List<String> noted = [];
  String? chosen;
  bool guideShown = false;

  bool hasNoted(String id) => noted.contains(id);
  bool allNoted(DeductionScene scene) => scene.clues.every((c) => noted.contains(c.id));
}
