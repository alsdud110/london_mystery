import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Offset, Rect;

import 'letter_puzzles.dart' show MapSpot;
import 'river_puzzles.dart' show DrawnEvidence;
import 'scene_explore.dart' show ScenePixels;

/// Season 2, Case 09 — The Clockwork Garden: its puzzles as they are played
/// on the case's pictures (`docs/SEASON2_CASE09_SPEC.md`). Every place is
/// in the delivered picture's own pixels.

// ── The opening ─────────────────────────────────────────────────────────

/// A picture over the case's opening lines, shown from the first one (its
/// [afterLine]: 0), that turns into another at a later line ([turnAtLine]): P.'s last drawing ([from]) gives
/// way to the garden it shows ([to]), the same view.
@immutable
class IntroPicture {
  const IntroPicture({
    required this.afterLine,
    required this.turnAtLine,
    required this.from,
    required this.to,
    required this.pixels,
    required this.fromLabel,
    required this.toLabel,
    this.clock,
  });

  final int afterLine;
  final int turnAtLine;
  final String from;
  final String to;
  final ScenePixels pixels;
  final String fromLabel;
  final String toLabel;

  /// A clock in [to] shown at four, as the story has it ([GardenClock]).
  final GardenClock? clock;
}

/// A clock painted in a picture whose hands the story does not want: its
/// face ([face], in the picture's pixels) is covered by [dial] with the
/// app's own hands at [hour] o'clock.
@immutable
class GardenClock {
  const GardenClock({required this.face, required this.dial, required this.dialPixels, required this.pivot, required this.faceRadius, this.hour = 4});

  final Rect face;
  final String dial;
  final ScenePixels dialPixels;

  /// The dial's pivot and its white face's radius, in its own pixels.
  final Offset pivot;
  final double faceRadius;
  final int hour;
}

// ── M1 — the little clocks on the map ───────────────────────────────────

/// One of the three little clocks of the Little Paris: its picture, where
/// it belongs on the map ([spot]: a [MapSpot] id) and the line said when it
/// is laid somewhere else.
@immutable
class TrialModel {
  const TrialModel({required this.id, required this.name, required this.file, required this.label, required this.spot, required this.wrongLine, required this.sign});

  /// Its part of the answer, and its name on the page (T1…).
  final String id;
  final String name;
  final String file;
  final String label;
  final String spot;
  final String wrongLine;

  /// The sign carved on its base (a star, three arches, a bell).
  final String sign;
}

/// M1 ([MissionType.matchPairs], `model:spot`): the map of Paris carved on
/// the stone base, its places ([spots]), and the three little clocks to put
/// back. A clock laid on its own place snaps there and stays; laid
/// elsewhere it goes back to the box with its line. Every clock in its
/// place answers the mission.
@immutable
class TrialMapScene {
  const TrialMapScene({
    required this.mapFile,
    required this.mapPixels,
    required this.spots,
    required this.models,
    required this.modelPixels,
    required this.task,
    required this.dropRadius,
    required this.specialLines,
    required this.placedLine,
  });

  final String mapFile;
  final ScenePixels mapPixels;
  final List<MapSpot> spots;
  final List<TrialModel> models;
  final ScenePixels modelPixels;
  final String task;

  /// How near a place a clock must be let go (map pixels) to be laid there.
  final double dropRadius;

  /// A line for a clock laid on one place in particular (`model:spot`),
  /// said instead of its own.
  final Map<String, String> specialLines;

  /// Said each time a clock snaps into its place.
  final String placedLine;

  TrialModel model(String id) => models.firstWhere((m) => m.id == id);

  /// The place nearest [p] (map pixels), within [dropRadius]; else null.
  MapSpot? spotNear(Offset p) {
    MapSpot? best;
    var bestDistance = dropRadius;
    for (final s in spots) {
      final d = (Offset(s.at.dx * mapPixels.width, s.at.dy * mapPixels.height) - p).distance;
      if (d <= bestDistance) {
        best = s;
        bestDistance = d;
      }
    }
    return best;
  }

  /// The line for [model] laid on [spot] (wrongly).
  String lineFor(String model, String spot) => specialLines['$model:$spot'] ?? this.model(model).wrongLine;

  /// The answer of the clocks laid ([placed]: model → spot).
  String answerOf(Map<String, String> placed) => [
    for (final m in models)
      if (placed[m.id] case final s?) '${m.id}:$s',
  ].join(',');
}

/// The little clocks laid in their places, saved (`t1=arcDeTriomphe;…`).
abstract final class TrialMapState {
  static String encode(Map<String, String> placed) => [for (final e in placed.entries) '${e.key}=${e.value}'].join(';');

  /// Only clocks the scene has, each in its own place (nothing else is
  /// ever saved).
  static Map<String, String> decode(String? saved, TrialMapScene scene) {
    final placed = <String, String>{};
    for (final part in (saved ?? '').split(';')) {
      final [id, spot] = switch (part.split('=')) {
        [final a, final b] => [a, b],
        _ => ['', ''],
      };
      if (scene.models.any((m) => m.id == id && m.spot == spot)) placed[id] = spot;
    }
    return placed;
  }
}

// ── M2 — the gear board ─────────────────────────────────────────────────

enum GearSize { big, small }

/// An empty place on the board for a gear of [size], at [at] (board
/// pixels). [branch] is what it joins to the tower: the clocks of that
/// branch turn once it is filled.
@immutable
class GearSlot {
  const GearSlot({required this.id, required this.size, required this.at, required this.branch});

  final String id;
  final GearSize size;
  final Offset at;
  final String branch;
}

/// A gear fixed on the board (the tower's wheel, the one that carries two
/// clocks) or under a clock's dial; it turns when its [branch] is joined
/// (the tower's always turns once any slot is filled).
@immutable
class FixedGear {
  const FixedGear({required this.at, required this.radius, this.branch, this.clockwise = true});

  final Offset at;
  final double radius;

  /// Which way it turns (gears that touch turn opposite ways; the places'
  /// gears turn against the tower).
  final bool clockwise;

  /// Null: the tower's own wheel.
  final String? branch;
}

/// A clock on the board: a dial over its gear. A joined clock turns with
/// its [branch]; the garden clock ([branch] null) never does.
@immutable
class BoardClock {
  const BoardClock({required this.id, required this.name, required this.at, required this.radius, this.branch, this.clockwise = true});

  final String id;
  final String name;
  final Offset at;
  final double radius;
  final String? branch;

  /// Which way its gear turns (its hands always go forward).
  final bool clockwise;

  bool get joined => branch != null;
}

/// M2 ([MissionType.matchPairs], `slot:size`): the brass board under the
/// model, the tower's wheel, two empty places ([slots]) and the two gears
/// in the tray. A gear fits only the place of its size; both in, the tower
/// turns its three trial clocks and the garden clock stays still.
@immutable
class GearBoardScene {
  const GearBoardScene({
    required this.file,
    required this.pixels,
    required this.view,
    required this.gearFile,
    required this.gearPixels,
    required this.dialFile,
    required this.dialPixels,
    required this.dialPivot,
    required this.radii,
    required this.slots,
    required this.fixed,
    required this.clocks,
    required this.tray,
    required this.task,
    required this.tooBig,
    required this.tooSmall,
    required this.oneMore,
    required this.turningLine,
  });

  final String file;
  final ScenePixels pixels;

  /// The part of the board shown (its pixels): the brass plate, without
  /// the stone round it or the tray under it (the gears wait under the
  /// board, larger).
  final Rect view;
  final String gearFile;
  final ScenePixels gearPixels;
  final String dialFile;
  final ScenePixels dialPixels;

  /// The dial's centre, in its own pixels.
  final Offset dialPivot;

  /// The radius of a gear of each size (board pixels).
  final Map<GearSize, double> radii;
  final List<GearSlot> slots;
  final List<FixedGear> fixed;
  final List<BoardClock> clocks;

  /// Where the two gears wait in the tray (board pixels), by size.
  final Map<GearSize, Offset> tray;
  final String task;
  final String tooBig;
  final String tooSmall;
  final String oneMore;
  final String turningLine;

  /// The place nearest [p] (board pixels) within reach of a gear let go
  /// there, else null.
  GearSlot? slotNear(Offset p) {
    GearSlot? best;
    var bestDistance = double.infinity;
    for (final s in slots) {
      final d = (s.at - p).distance;
      if (d <= radii[s.size]! + 60 && d < bestDistance) {
        best = s;
        bestDistance = d;
      }
    }
    return best;
  }

  /// Whether [branch] is joined to the tower by [placed] (slot → size).
  bool joined(String branch, Map<String, GearSize> placed) =>
      slots.any((s) => s.branch == branch && placed[s.id] == s.size);

  String answerOf(Map<String, GearSize> placed) => [
    for (final s in slots)
      if (placed[s.id] case final g?) '${s.id}:${g.name}',
  ].join(',');
}

/// The gears set on the board, saved (`slot1=big;…`): only a gear in the
/// place of its own size.
abstract final class GearBoardState {
  static String encode(Map<String, GearSize> placed) => [for (final e in placed.entries) '${e.key}=${e.value.name}'].join(';');

  static Map<String, GearSize> decode(String? saved, GearBoardScene scene) {
    final placed = <String, GearSize>{};
    for (final part in (saved ?? '').split(';')) {
      if (part.split('=') case [final id, final size]) {
        final slot = scene.slots.where((s) => s.id == id).firstOrNull;
        if (slot != null && slot.size.name == size) placed[id] = slot.size;
      }
    }
    return placed;
  }
}

// ── M3 — the maker's marks ──────────────────────────────────────────────

enum MarkKind { gear, hands, key }

/// A mark from the notebook (Case 01's gear, Case 05's two clock hands),
/// laid beside the plan: [id] is its part of the answer.
@immutable
class NotebookMark {
  const NotebookMark({required this.id, required this.kind, required this.name, required this.source, required this.evidenceId});

  final String id;
  final MarkKind kind;
  final String name;

  /// Where it was found ("Gare du Nord").
  final String source;
  final String evidenceId;
}

/// A mark on the old paper: drawn by the app at [markAt] (plan pixels),
/// its words at [wordsAt]; [crop] is the paper round it, shown larger to be
/// tapped. [id] is its part of the answer.
@immutable
class PaperMark {
  const PaperMark({required this.id, required this.kind, required this.name, required this.words, required this.markAt, required this.wordsAt, required this.crop, this.light = false, this.angle = 0});

  final String id;
  final MarkKind kind;
  final String name;
  final String words;
  final Rect markAt;
  final Rect wordsAt;
  final Rect crop;

  /// Drawn in white (on the blue plan) rather than in ink (on the note).
  final bool light;

  /// How far the paper it is on is turned (radians, clockwise): its words
  /// and mark are turned with it, and its [crop] is taken along it
  /// ([markAt], [wordsAt] and [crop] are given unturned, round their
  /// centres).
  final double angle;
}

/// M3 ([MissionType.matchPairs], `mark:paper`): the two marks from the
/// notebook and the old plan with its repair note. A notebook mark tapped,
/// then the same shape on the paper: joined. A wrong one is said why and
/// nothing is joined; both joined answer the mission.
@immutable
class MakerMarksScene {
  const MakerMarksScene({
    required this.file,
    required this.pixels,
    required this.handsFile,
    required this.handsPixels,
    required this.marks,
    required this.paper,
    required this.task,
    required this.pickFirst,
    required this.lines,
  });

  final String file;
  final ScenePixels pixels;
  final String handsFile;
  final ScenePixels handsPixels;
  final List<NotebookMark> marks;
  final List<PaperMark> paper;
  final String task;
  final String pickFirst;

  /// What a wrong joining says (`mark:paper`).
  final Map<String, String> lines;

  NotebookMark mark(String id) => marks.firstWhere((m) => m.id == id);
  PaperMark paperMark(String id) => paper.firstWhere((p) => p.id == id);

  /// Whether [mark] and [paperId] are the same shape.
  bool same(String mark, String paperId) => this.mark(mark).kind == paperMark(paperId).kind;

  String answerOf(Map<String, String> joined) => [
    for (final m in marks)
      if (joined[m.id] case final p?) '${m.id}:$p',
  ].join(',');
}

/// The marks joined, saved (`a=emblem;…`): only a right pair.
abstract final class MakerMarksState {
  static String encode(Map<String, String> joined) => [for (final e in joined.entries) '${e.key}=${e.value}'].join(';');

  static Map<String, String> decode(String? saved, MakerMarksScene scene) {
    final joined = <String, String>{};
    for (final part in (saved ?? '').split(';')) {
      if (part.split('=') case [final id, final paper]) {
        if (scene.marks.any((m) => m.id == id) && scene.paper.any((p) => p.id == paper) && scene.same(id, paper)) joined[id] = paper;
      }
    }
    return joined;
  }
}

// ── Final — the wrong hour ──────────────────────────────────────────────

/// The star's trail after the case (its last step, the case closes with
/// it): the drum's tag, the little clock with the same sign, and its place
/// on the map lit.
@immutable
class StarLead {
  const StarLead({
    required this.title,
    required this.tag,
    required this.question,
    required this.models,
    required this.modelPixels,
    required this.answer,
    required this.otherLine,
    required this.foundLine,
    required this.mapFile,
    required this.mapPixels,
    required this.spot,
    required this.doneLines,
  });

  final String title;
  final String tag;
  final String question;
  final List<TrialModel> models;
  final ScenePixels modelPixels;
  final String answer;
  final String otherLine;
  final String foundLine;
  final String mapFile;
  final ScenePixels mapPixels;
  final MapSpot spot;
  final List<String> doneLines;
}

/// A clock on the test's row: joined to the tower or not.
@immutable
class TestClock {
  const TestClock({required this.id, required this.name, required this.joined});

  final String id;
  final String name;
  final bool joined;
}

/// The final: the tower's hands put back on (a moment), the tower set one
/// hour back, TEST; then the question ([MissionType.multipleChoice]). The
/// answer leaves the case open until the star is followed ([lead]).
@immutable
class TowerTestScene {
  const TowerTestScene({
    required this.garden,
    required this.gardenPixels,
    required this.gardenLabel,
    required this.gardenClock,
    required this.dialFile,
    required this.dialPixels,
    required this.dialPivot,
    required this.dialRadius,
    required this.startHour,
    required this.targetHour,
    required this.clocks,
    required this.handsLine,
    required this.testLabel,
    required this.hourLines,
    required this.testedLines,
    required this.afterLines,
    required this.lead,
    required this.leadLabel,
  });

  final String garden;
  final ScenePixels gardenPixels;
  final String gardenLabel;
  final GardenClock gardenClock;
  final String dialFile;
  final ScenePixels dialPixels;
  final Offset dialPivot;
  final double dialRadius;
  final int startHour;
  final int targetHour;
  final List<TestClock> clocks;
  final String handsLine;
  final String testLabel;

  /// What TEST says when the tower is set to an hour other than the one
  /// asked (by hour; any other: [hourLines]'s `0`).
  final Map<int, String> hourLines;
  final List<String> testedLines;

  /// Said under the solve, before the star is followed: a model shows what
  /// could happen, never what did.
  final List<String> afterLines;
  final StarLead lead;
  final String leadLabel;

  /// Kept once TEST was pressed at the right hour, and once the star was
  /// followed (the case closes with it).
  static const testedId = 'tested';
  static const leadId = 'star';

  String lineFor(int hour) => hourLines[hour] ?? hourLines[0]!;

  /// The hour each clock shows: before the test, at four; after it, the
  /// joined ones at the tower's hour.
  int hourOf(TestClock c, {required bool tested}) => tested && c.joined ? targetHour : startHour;
}

// ── The evidence, drawn ─────────────────────────────────────────────────

/// The Trial Map: the map with the three little clocks in their places.
final class TrialMapPaper implements DrawnEvidence {
  const TrialMapPaper(this.scene);

  final TrialMapScene scene;

  @override
  double get aspect => scene.mapPixels.aspect;
}

/// The Synchronisation Diagram: the board with both gears in.
final class GearDiagram implements DrawnEvidence {
  const GearDiagram(this.scene);

  final GearBoardScene scene;

  @override
  double get aspect => scene.view.width / scene.view.height;
}

/// The Marks Key: the plan and its note, their marks drawn.
final class MarksPaper implements DrawnEvidence {
  const MarksPaper(this.scene);

  final MakerMarksScene scene;

  @override
  double get aspect => scene.pixels.aspect;
}

/// The Wrong Hour Test: the clocks after the test.
final class TestCard implements DrawnEvidence {
  const TestCard(this.scene);

  final TowerTestScene scene;

  @override
  double get aspect => 2.2;
}
