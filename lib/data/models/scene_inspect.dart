import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter/foundation.dart';

import 'scene_explore.dart' show ScenePixels, hitArea;

/// What examining an [InspectSpot] does.
enum InspectKind {
  /// An exhibit that is not it: a short line of what the glass shows.
  exhibit,

  /// The exhibit the note describes: its card, then its label.
  match,

  /// The match's label: the word to complete (the mission's puzzle).
  label,

  /// Something hidden near the match, seen once the match is found (a
  /// glint): its card. Never needed to go on.
  hidden,
}

/// A thing in an [InspectScene] to look at under the glass.
@immutable
class InspectSpot {
  const InspectSpot({
    required this.id,
    required this.kind,
    required this.title,
    required this.label,
    required this.areas,
    required this.line,
    this.checks = const {},
    this.requires,
    this.lockedLine = '',
  });

  final String id;
  final InspectKind kind;

  /// Its name on its card ("STRANGE WRITING").
  final String title;

  /// What it is, for screen readers ("The golden mask of a king").
  final String label;

  /// Where it is (fractions of the picture): the first is where its tick
  /// is shown once examined.
  final List<Rect> areas;

  /// What the glass shows ("A king's face. Made of gold.").
  final String line;

  /// The note's lines (their index) that examining it confirms.
  final Set<int> checks;

  /// A spot to examine first; until then [lockedLine] is what the glass
  /// shows.
  final String? requires;
  final String lockedLine;
}

/// A mission played by examining its exhibits under a magnifying glass
/// (the presentation of the mission's puzzle, never saved): the note's
/// lines are ticked as the exhibits confirm them; the exhibit the note
/// describes leads to its label, where the mission's word is completed
/// and checked as its answer, through the same check, feedback, save and
/// rewards as the word it always asked for. Examining is never a wrong
/// answer.
@immutable
class InspectScene {
  const InspectScene({
    required this.picture,
    required this.pixels,
    required this.place,
    required this.task,
    required this.nextTask,
    required this.dragGuide,
    required this.tapGuide,
    required this.missLine,
    required this.spots,
    required this.labelTitle,
    required this.labelRoom,
    required this.labelWorn,
    required this.taskLine,
    this.inside = const Rect.fromLTRB(0, 0, 1, 1),
    this.lensAt = const Offset(0.5, 0.5),
    this.matchAction = 'READ THE LABEL',
    this.labelLink = 'Label',
  });

  /// The room's picture (its file) and its size in pixels.
  final String picture;
  final ScenePixels pixels;

  /// The room, for screen readers ("Room 4 of the British Museum").
  final String place;

  /// What to do first ("Look closely at the exhibits…"), then once the
  /// match is found ([nextTask]).
  final String task;
  final String nextTask;

  /// How to look: drag the glass (the main line), or tap an exhibit.
  final String dragGuide;
  final String tapGuide;

  /// Said when the glass is over nothing listed.
  final String missLine;

  final List<InspectSpot> spots;

  /// The label's card: its heading, the room it names ("ROOM 4"), and why
  /// a word is missing ("The second word is worn away.").
  final String labelTitle;
  final String labelRoom;
  final String labelWorn;

  /// The note's line still to answer once the label is read (its index):
  /// the word to complete. Ticked only by the answer.
  final int taskLine;

  /// The picture inside its own printed paper edge (fractions).
  final Rect inside;

  /// Where the glass waits before it is first moved (fractions): over the
  /// floor, on no exhibit.
  final Offset lensAt;

  /// The match card's way to its label, and the quiet link that opens the
  /// label again.
  final String matchAction;
  final String labelLink;

  InspectSpot spot(String id) => spots.firstWhere((s) => s.id == id);

  InspectSpot get match => spots.firstWhere((s) => s.kind == InspectKind.match);
  InspectSpot get label => spots.firstWhere((s) => s.kind == InspectKind.label);

  /// The spot under [point] (fractions), if any; within [slack] of one,
  /// the nearest.
  InspectSpot? hit(Offset point, {Size slack = Size.zero}) =>
      hitArea<InspectSpot>(point, [for (final s in spots) (s, s.areas)], slack: slack);
}

/// How far the detective has got in an [InspectScene]: what was examined,
/// whether the label was read, what is open over the room, and where the
/// glass is. Kept by the page while it is open; never saved (the mission is
/// saved when it is solved, as any puzzle).
class InspectProgress {
  final Set<String> examined = {};
  bool labelRead = false;

  /// The spot whose card is open over the room, if any.
  String? open;

  /// Where the glass is (fractions of the picture); null: where it waits.
  Offset? lens;

  bool hasExamined(String id) => examined.contains(id);

  /// Whether [s] can be examined now (what it needs was examined).
  bool canOpen(InspectSpot s) => s.requires == null || examined.contains(s.requires);

  /// The note's lines confirmed so far (their index): by the spots
  /// examined, and the label's own lines once it is read.
  Set<int> confirmed(InspectScene scene) => {
        for (final s in scene.spots)
          if (s.kind != InspectKind.label && examined.contains(s.id)) ...s.checks,
        if (labelRead) ...scene.label.checks,
      };
}
