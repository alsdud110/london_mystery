import 'dart:ui' show Offset, Rect;

import 'package:flutter/foundation.dart';

import 'letter_puzzles.dart' show MapSpot;
import 'river_puzzles.dart' show DrawnEvidence;
import 'scene_explore.dart' show ScenePixels;
import 'tower_puzzles.dart';

/// Season 2, Case 08's puzzles (Abbesses, Montmartre), as played on the
/// case's pictures (`season2_case08_scenes.dart`). Every place is measured
/// in the pixels of the picture it is on.

// ── Shown before a case's opening lines are done ────────────────────────

/// A paper shown under one of a case's opening lines (Case 08: the back of
/// Case 07's Amendment Slip, where the case begins).
@immutable
class IntroPaper {
  const IntroPaper({required this.afterLine, required this.paper});

  final int afterLine;
  final DrawnEvidence paper;
}

// ── M1 — the painter's corner ───────────────────────────────────────────

/// A corner of the square: where it is in the square's picture ([area]),
/// its own picture seen from the bench in front of it ([file]), and what
/// that shows (for screen readers). [id] is its option.
@immutable
class PainterCorner {
  const PainterCorner({required this.id, required this.name, required this.area, required this.file, required this.label});

  final String id;
  final String name;
  final Rect area;
  final String file;
  final String label;
}

/// M1 ([MissionType.multipleChoice]): the square of Abbesses with its three
/// corners; each looked at closer (its own picture) is kept looked at, and
/// the corner chosen there is the answer. The Hidden Sketch (Case 02) is
/// brought from the notebook beside them (the mission's recall).
@immutable
class CornerChoiceScene {
  const CornerChoiceScene({
    required this.square,
    required this.squarePixels,
    required this.cornerPixels,
    required this.corners,
    required this.squareLabel,
    required this.task,
    required this.chooseLabel,
    required this.backLabel,
  });

  final String square;
  final ScenePixels squarePixels;
  final ScenePixels cornerPixels;
  final List<PainterCorner> corners;
  final String squareLabel;
  final String task;
  final String chooseLabel;
  final String backLabel;

  PainterCorner corner(String id) => corners.firstWhere((c) => c.id == id);

  /// A corner looked at closer is saved under this key part.
  static String lookedKey(String id) => 'corner-$id';
}

// ── M2 — the morning drawings ───────────────────────────────────────────

/// Something drawn in one of P.'s drawings that is new since the drawing
/// before it ([area], pixels of the drawing).
@immutable
class SketchChange {
  const SketchChange({required this.id, required this.area, required this.label});

  final String id;
  final Rect area;
  final String label;
}

/// A study P. drew in a drawing's margin, laid there by the app: its own
/// picture ([file], pencil on transparency) at [at] (pixels of the
/// drawing).
@immutable
class MarginStudy {
  const MarginStudy({required this.file, required this.pixels, required this.at});

  final String file;
  final ScenePixels pixels;
  final Rect at;
}

/// One of P.'s drawings of the corner: what is new in it since the one
/// before ([changes]; none for the first), and its margin study, if any.
@immutable
class MorningSketch implements DrawnEvidence {
  const MorningSketch({required this.id, required this.file, required this.pixels, required this.label, this.changes = const [], this.study});

  final String id;
  final String file;
  final ScenePixels pixels;
  final String label;
  final List<SketchChange> changes;
  final MarginStudy? study;

  @override
  double get aspect => pixels.aspect;
}

/// M2 ([MissionType.multipleChoice]): three drawings of one corner, one
/// morning, shown out of order ([shown]); put in order by the sky and the
/// lamp (P.'s tag gives the rule), then each laid over the one before to
/// find what is new; then the question is asked.
@immutable
class MorningSketchesScene {
  const MorningSketchesScene({
    required this.sketches,
    required this.shown,
    required this.lampOff,
    required this.slots,
    required this.orderTask,
    required this.checkOrderLabel,
    required this.lampLine,
    required this.skyLine,
    required this.orderedLine,
    required this.compareTask,
    required this.questionTask,
  });

  /// In the true order (the first has no changes).
  final List<MorningSketch> sketches;

  /// Their order on the table before they are put in order (ids).
  final List<String> shown;

  /// The drawing whose lamp is out (the last).
  final String lampOff;
  final List<String> slots;
  final String orderTask;
  final String checkOrderLabel;

  /// Why an order is not right: the lamp out before the end, or the two
  /// lamp-lit drawings the wrong way round.
  final String lampLine;
  final String skyLine;
  final String orderedLine;
  final String compareTask;
  final String questionTask;

  MorningSketch sketch(String id) => sketches.firstWhere((s) => s.id == id);

  List<String> get order => [for (final s in sketches) s.id];

  /// Every change to find, in order.
  List<SketchChange> get changes => [for (final s in sketches) ...s.changes];

  /// The line for an order put down: null when it is right.
  String? lineFor(List<String> placed) {
    if (listEquals(placed, order)) return null;
    if (placed.indexOf(lampOff) != placed.length - 1) return lampLine;
    return skyLine;
  }
}

/// How far the drawings are: their order on the slots (null: empty), the
/// order checked right, and the changes found; as saved
/// (`order=a,b,;ok=1;found=x+y`), and back. Unknown parts are dropped.
@immutable
class SketchState {
  const SketchState({this.placed = const [null, null, null], this.ordered = false, this.found = const {}});

  final List<String?> placed;
  final bool ordered;
  final Set<String> found;

  SketchState copyWith({List<String?>? placed, bool? ordered, Set<String>? found}) =>
      SketchState(placed: placed ?? this.placed, ordered: ordered ?? this.ordered, found: found ?? this.found);

  String encode() => [
    'order=${placed.map((p) => p ?? '').join(',')}',
    if (ordered) 'ok=1',
    'found=${found.join('+')}',
  ].join(';');

  static SketchState decode(String? saved, MorningSketchesScene scene) {
    final ids = scene.order.toSet();
    final changes = {for (final c in scene.changes) c.id};
    var placed = <String?>[null, null, null];
    var ordered = false;
    var found = <String>{};
    for (final part in (saved ?? '').split(';')) {
      final i = part.indexOf('=');
      if (i < 0) continue;
      final key = part.substring(0, i);
      final value = part.substring(i + 1);
      switch (key) {
        case 'order':
          final ps = value.split(',');
          if (ps.length == 3) placed = [for (final p in ps) ids.contains(p) ? p : null];
        case 'ok':
          ordered = value == '1';
        case 'found':
          found = {for (final f in value.split('+')) if (changes.contains(f)) f};
      }
    }
    // Checked right only when it still is.
    if (ordered && !listEquals(placed, scene.order)) ordered = false;
    return SketchState(placed: placed, ordered: ordered, found: found);
  }
}

// ── M3 — the torn paper ─────────────────────────────────────────────────

/// The torn paper (one blank picture, cut out): what is left of a form
/// like the Amendment Slip's. Its words are written by the app ([fileWord]
/// up to the tear, then [minutes] and an arrow after it); the seal is the
/// slip's own stamp picture.
@immutable
class TornForm implements DrawnEvidence {
  const TornForm({
    required this.file,
    required this.pixels,
    required this.paper,
    required this.fileWord,
    required this.fileAt,
    required this.minutes,
    required this.minutesAt,
    required this.arrowAt,
    required this.stamp,
    required this.stampAt,
  });

  final String file;
  final ScenePixels pixels;

  /// The paper (pixels of [file]): what is shown of it.
  final Rect paper;
  final String fileWord;
  final Rect fileAt;
  final String minutes;
  final Rect minutesAt;
  final Rect arrowAt;
  final String stamp;
  final Rect stampAt;

  @override
  double get aspect => paper.width / paper.height;
}

/// What a part of the torn paper is when it is marked: the same as the
/// slip, or missing from it.
enum FormMark { same, missing }

/// A place on the torn paper ([area], pixels of it): a part to mark
/// ([mark]), or something that is neither (a fold, the tear, dust) and only
/// says so ([line]).
@immutable
class FormPart {
  const FormPart({required this.id, required this.area, this.mark, this.line, this.name});

  final String id;
  final Rect area;
  final FormMark? mark;
  final String? line;

  /// What it is, once marked (for the list under the paper).
  final String? name;
}

/// A question about the seal, looked at closer: marked the same only once
/// both are answered right.
@immutable
class SealCheck {
  const SealCheck({required this.question, required this.choices, required this.answer, required this.wrongLine});

  final String question;
  final List<String> choices;
  final String answer;
  final String wrongLine;
}

/// M3 ([MissionType.matchPairs]): the folded paper, unfolded (three
/// folds); its parts marked SAME or MISSING beside the Amendment Slip (the
/// mission's recall). The seal is marked only after its checks.
@immutable
class TornSlipScene {
  const TornSlipScene({
    required this.folded,
    required this.foldedPixels,
    required this.form,
    required this.parts,
    required this.sealId,
    required this.sealChecks,
    required this.folds,
    required this.unfoldTask,
    required this.sameTask,
    required this.missingTask,
    required this.checkLabel,
    required this.sealTitle,
    required this.noteLines,
  });

  final String folded;
  final ScenePixels foldedPixels;
  final TornForm form;
  final List<FormPart> parts;
  final String sealId;
  final List<SealCheck> sealChecks;
  final int folds;
  final String unfoldTask;
  final String sameTask;
  final String missingTask;
  final String checkLabel;
  final String sealTitle;

  /// P.'s note clipped to the folded paper.
  final List<String> noteLines;

  /// The part at [p] (pixels of the paper's picture): a part to mark before
  /// anything that only says what it is.
  FormPart? partAt(double x, double y) {
    FormPart? say;
    for (final part in parts) {
      if (!part.area.contains(Offset(x, y))) continue;
      if (part.mark != null) return part;
      say ??= part;
    }
    return say;
  }

  Iterable<FormPart> partsMarked(FormMark mark) => parts.where((p) => p.mark == mark);

  /// The answer sent for what is marked: every mark (`same:border`, …),
  /// then, when something is still to do, the first of it (`need:same`,
  /// `need:seal`, `need:hour`, `need:number`), which is never right.
  String answerOf(Set<String> same, Set<String> missing) {
    final need = <String>[];
    final sameParts = {for (final p in partsMarked(FormMark.same)) p.id};
    if (!sameParts.difference({sealId}).every(same.contains)) {
      need.add('need:same');
    } else if (!same.contains(sealId)) {
      need.add('need:seal');
    }
    for (final p in partsMarked(FormMark.missing).toList().reversed) {
      if (need.isEmpty && !missing.contains(p.id)) need.add('need:${p.id}');
    }
    return [
      for (final p in partsMarked(FormMark.same))
        if (same.contains(p.id)) 'same:${p.id}',
      for (final p in partsMarked(FormMark.missing))
        if (missing.contains(p.id)) 'missing:${p.id}',
      ...need.take(1),
    ].join(',');
  }
}

/// How far the torn paper is: folds opened, and what is marked; as saved
/// (`open=3;same=a+b;missing=c`), and back.
@immutable
class SlipState {
  const SlipState({this.opened = 0, this.same = const {}, this.missing = const {}});

  final int opened;
  final Set<String> same;
  final Set<String> missing;

  SlipState copyWith({int? opened, Set<String>? same, Set<String>? missing}) =>
      SlipState(opened: opened ?? this.opened, same: same ?? this.same, missing: missing ?? this.missing);

  String encode() => 'open=$opened;same=${same.join('+')};missing=${missing.join('+')}';

  static SlipState decode(String? saved, TornSlipScene scene) {
    final same = {for (final p in scene.partsMarked(FormMark.same)) p.id};
    final missing = {for (final p in scene.partsMarked(FormMark.missing)) p.id};
    var s = const SlipState();
    for (final part in (saved ?? '').split(';')) {
      final i = part.indexOf('=');
      if (i < 0) continue;
      final value = part.substring(i + 1);
      switch (part.substring(0, i)) {
        case 'open':
          s = s.copyWith(opened: (int.tryParse(value) ?? 0).clamp(0, scene.folds));
        case 'same':
          s = s.copyWith(same: {for (final v in value.split('+')) if (same.contains(v)) v});
        case 'missing':
          s = s.copyWith(missing: {for (final v in value.split('+')) if (missing.contains(v)) v});
      }
    }
    return s;
  }
}

// ── Final — the paper on the drawing, and the board ─────────────────────

/// A board of the final's questions and evidence (Case 08's: the papers
/// and drawings, with Case 07's slip given on it).
@immutable
class PaperBoard implements EvidenceBoardSpec {
  const PaperBoard({
    required this.questions,
    required this.evidence,
    required this.conclusionId,
    required this.conclusionQuestion,
    required this.conclusions,
    required this.linkTask,
    required this.concludeTask,
    required this.solveLabel,
  });

  @override
  final List<BoardQuestion> questions;
  @override
  final List<BoardEvidence> evidence;
  @override
  final String conclusionId;
  @override
  final String conclusionQuestion;
  @override
  final List<BoardConclusion> conclusions;
  @override
  final String linkTask;
  @override
  final String concludeTask;
  @override
  final String solveLabel;
}

/// A part of P.'s last drawing ([area], pixels of it) to tap: what it is
/// when it matches the Bag Sketch ([line]), or why it does not.
@immutable
class LeadPart {
  const LeadPart({required this.id, required this.area, required this.line});

  final String id;
  final Rect area;
  final String line;
}

/// After the case: P.'s last drawing. The same bag is found in it (its
/// [bagParts], all three; [decoy] only says why not), then its garden on
/// the map of Paris ([spots]; [answer] the one). Never scored.
@immutable
class NextLead {
  const NextLead({
    required this.file,
    required this.pixels,
    required this.label,
    required this.bagParts,
    required this.decoy,
    required this.bagTask,
    required this.bagDone,
    required this.features,
    required this.mapFile,
    required this.mapPixels,
    required this.spots,
    required this.answer,
    required this.feedback,
    required this.otherLine,
    required this.mapTask,
    required this.chooseLabel,
    required this.doneLines,
  });

  final String file;
  final ScenePixels pixels;
  final String label;
  final List<LeadPart> bagParts;
  final LeadPart decoy;
  final String bagTask;
  final List<String> bagDone;

  /// What the drawing's garden has, to find on the map.
  final List<String> features;
  final String mapFile;
  final ScenePixels mapPixels;
  final List<MapSpot> spots;
  final String answer;
  final Map<String, String> feedback;
  final String otherLine;
  final String mapTask;
  final String chooseLabel;
  final List<String> doneLines;

  /// The part at a tap (pixels of the drawing): the smallest one there.
  LeadPart? partAt(double x, double y) {
    LeadPart? best;
    for (final p in [...bagParts, decoy]) {
      if (!p.area.contains(Offset(x, y))) continue;
      if (best == null || p.area.width * p.area.height < best.area.width * best.area.height) best = p;
    }
    return best;
  }

  String lineFor(String spot) => feedback[spot] ?? otherLine;
}

/// The final ([MissionType.matchPairs]): the torn paper laid on P.'s
/// drawing of it (turned until it fits: [startTurns] quarter turns off at
/// first), then the board; after the case, P.'s last drawing ([lead]).
@immutable
class TornHourScene {
  const TornHourScene({
    required this.sketch,
    required this.form,
    required this.startTurns,
    required this.board,
    required this.lead,
    required this.placeHeading,
    required this.placeTask,
    required this.turnLabel,
    required this.layLabel,
    required this.tearLine,
    required this.sealLine,
    required this.offLine,
    required this.placedLines,
    required this.leadLabel,
  });

  /// Drawing 3, its margin study the place the paper is laid on.
  final MorningSketch sketch;
  final TornForm form;
  final int startTurns;
  final PaperBoard board;
  final NextLead lead;
  final String placeHeading;
  final String placeTask;
  final String turnLabel;
  final String layLabel;

  /// Why it does not fit: the tear somewhere else, or (asked again) the
  /// seal; laid off the study.
  final String tearLine;
  final String sealLine;
  final String offLine;
  final List<String> placedLines;
  final String leadLabel;

  MarginStudy get study => sketch.study!;

  /// The paper laid on the drawing, and P.'s last drawing looked at, are
  /// saved under these keys.
  static const placedId = 'placed';
  static const leadId = 'last-drawing';
}
