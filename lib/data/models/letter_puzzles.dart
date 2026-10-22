import 'dart:ui' show Offset, Rect;

import 'package:flutter/foundation.dart';

import 'river_puzzles.dart' show DrawnEvidence;
import 'scene_explore.dart' show ScenePixels;
import 'workshop_puzzles.dart' show WrittenPaper;

/// Season 2, Case 06's puzzles (The Letter That Never Arrived): the hold
/// rack's tags turned over and compared with the Letter's Trail, the
/// porter's directions followed on the plan of the building, the archive's
/// drawers and the torn envelope the corner from Clock III fits, and the
/// letter's drawing matched to a building on the map of Paris.
///
/// First the rules, which the case's answer and feedback are checked
/// against; then each puzzle as it is played on its pictures (where every
/// tag, door, drawer and envelope is drawn, measured on the delivered
/// pictures: `season2_case06_scenes.dart`). The pictures are blank of
/// words: what is written on them is written by the app.

// ── The hold rack ────────────────────────────────────────────────────────

/// What the post keeps on its hold rack.
enum PostKind {
  letter,
  parcel;

  String get word => name.toUpperCase();
}

/// What the Letter's Trail (Case 05's slip, held at the Louvre post room)
/// says of letter No. 4417.
@immutable
class TagClue {
  const TagClue({required this.kind, required this.number, required this.date, required this.time});

  final PostKind kind;
  final String number;
  final String date;
  final String time;
}

/// A paper tag on the hold rack: its front (what it is for and its number;
/// a `?` is a digit hidden by ink) and its back (when it was held, and why).
@immutable
class HoldTag {
  const HoldTag({
    required this.id,
    required this.kind,
    required this.number,
    required this.date,
    required this.time,
    required this.record,
    this.reason = const [],
  });

  final String id;
  final PostKind kind;

  /// Four digits; `?` where ink hides one.
  final String number;
  final String date;
  final String time;
  final String record;

  /// What the back says after its record (the Preservation Order).
  final List<String> reason;

  String get name => 'TAG ${id.toUpperCase()}';

  List<String> get front => ['${kind.word} No. $number'];

  List<String> get back => ['$date · $time', record, ...reason];

  /// Whether ink hides a digit of its number.
  bool get inked => number.contains('?');

  /// Whether its front could be the clue's: the same kind, and every digit
  /// not hidden by ink the same.
  bool frontFits(TagClue clue) {
    if (kind != clue.kind || number.length != clue.number.length) return false;
    for (var i = 0; i < number.length; i++) {
      if (number[i] != '?' && number[i] != clue.number[i]) return false;
    }
    return true;
  }

  /// Whether its back is the clue's: the same day and time.
  bool backFits(TagClue clue) => date == clue.date && time == clue.time;

  bool fits(TagClue clue) => frontFits(clue) && backFits(clue);
}

/// M1: the hold rack's tags and the clue they are compared with.
@immutable
class HoldRack {
  const HoldRack({required this.clue, required this.tags});

  final TagClue clue;
  final List<HoldTag> tags;

  /// Where a tag counts as turned over (examined key part).
  static String turnedKey(String tagId) => 'turned-$tagId';

  HoldTag tag(String id) => tags.firstWhere((t) => t.id == id);

  /// The tags whose front and back both fit the clue.
  List<HoldTag> get fitting => [for (final t in tags) if (t.fits(clue)) t];
}

// ── The plan of the building ─────────────────────────────────────────────

enum Side { left, right }

/// A place on the plan the letter is moved through, in order: down the
/// stairs, then past the statue.
enum PlanStep { stairs, statue }

/// A door off the corridor: on which side (as the letter walks), whether it
/// is past the statue, and which door it is on its side there (1: the
/// first).
@immutable
class PlanDoor {
  const PlanDoor({required this.id, required this.side, required this.pastStatue, required this.nth});

  final String id;
  final Side side;
  final bool pastStatue;
  final int nth;

  String get name => 'DOOR ${id.toUpperCase()}';
}

/// What the porter's note says to do.
@immutable
class Directions {
  const Directions({required this.pastStatue, required this.side, required this.nth});

  final bool pastStatue;
  final Side side;
  final int nth;
}

/// M2: the plan, its corridor's doors and the note's directions. The
/// letter is moved one step at a time (a tap on the next place); a door can
/// be opened only once the letter has reached it.
@immutable
class PlanRoute {
  const PlanRoute({required this.doors, required this.directions, required this.archive});

  final List<PlanDoor> doors;
  final Directions directions;

  /// The door the archive is behind.
  final String archive;

  /// Where the letter counts as moved to [step] (examined key part).
  static String reachedKey(PlanStep step) => 'reached-${step.name}';

  PlanDoor door(String id) => doors.firstWhere((d) => d.id == id);

  /// Whether the letter can be moved to [step], from the steps [reached]:
  /// the stairs first, then the statue.
  static bool canReach(PlanStep step, Set<PlanStep> reached) => step.index == 0 || reached.contains(PlanStep.values[step.index - 1]);

  /// Whether the letter is at [door] yet: every door is down the stairs,
  /// and the ones past the statue only once it is passed.
  static bool canOpen(PlanDoor door, Set<PlanStep> reached) =>
      reached.contains(PlanStep.stairs) && (!door.pastStatue || reached.contains(PlanStep.statue));

  /// The doors the directions could mean (one, on a fair plan).
  List<PlanDoor> get followed => [
    for (final d in doors)
      if (d.pastStatue == directions.pastStatue && d.side == directions.side && d.nth == directions.nth) d,
  ];
}

// ── The archive ──────────────────────────────────────────────────────────

/// A drawer of the archive and the label on it: what it keeps, numbers
/// [from] to [to].
@immutable
class ArchiveDrawer {
  const ArchiveDrawer({required this.id, required this.kind, required this.from, required this.to});

  final String id;
  final PostKind kind;
  final int from;
  final int to;

  String get label => '${kind.word}S · $from–$to';

  bool keeps(PostKind kind, int number) => kind == this.kind && number >= from && number <= to;
}

/// A torn envelope in the drawer, its number lost with its corner: [tear]
/// names the shape of its torn edge (one of the pictures).
@immutable
class TornEnvelope {
  const TornEnvelope({required this.id, required this.tear});

  final String id;
  final String tear;
}

/// M3: the drawers, the torn envelopes in the one letter No. 4417 is kept
/// in, and the corner from Clock III ([cornerTear], its label [cornerLabel])
/// laid on them: it snaps only where it fits.
@immutable
class ArchiveDrawers {
  const ArchiveDrawers({
    required this.drawers,
    required this.kind,
    required this.number,
    required this.envelopes,
    required this.cornerTear,
    required this.cornerLabel,
  });

  final List<ArchiveDrawer> drawers;
  final PostKind kind;
  final int number;
  final List<TornEnvelope> envelopes;
  final String cornerTear;
  final String cornerLabel;

  /// Where a drawer counts as opened (examined key part).
  static String openedKey(String drawerId) => 'drawer-$drawerId';

  /// Where the seal's little picture counts as looked at, once the
  /// envelope is found.
  static const sealId = 'seal';

  ArchiveDrawer drawer(String id) => drawers.firstWhere((d) => d.id == id);

  /// The drawers whose labels keep this letter (one, on fair labels).
  List<ArchiveDrawer> get keeping => [for (final d in drawers) if (d.keeps(kind, number)) d];

  bool fits(TornEnvelope e) => e.tear == cornerTear;

  List<TornEnvelope> get fitting => [for (final e in envelopes) if (fits(e)) e];
}

// ── The letter and the map ───────────────────────────────────────────────

/// What a building has that a drawing shows.
enum BuildingFeature { dome, roofStatues, archedWindows, twoTowers, spire, pyramid, bigArch, glassRoof, ironTower }

/// A building on the map of Paris (its id is the map's landmark), what it
/// looks like and whether shows are played there.
@immutable
class MapBuilding {
  const MapBuilding({required this.id, required this.features, this.shows = false});

  final String id;
  final Set<BuildingFeature> features;
  final bool shows;
}

/// The final: the letter's drawing, what its words say the place is for,
/// and the buildings on the map it is compared with. Where the letter is
/// laid is the answer; its back is turned over once it is right.
@immutable
class LetterMap {
  const LetterMap({required this.drawing, required this.buildings, required this.back});

  final Set<BuildingFeature> drawing;
  final List<MapBuilding> buildings;

  /// What the back of the letter says (shown only once it is solved).
  final List<String> back;

  /// Where a building counts as looked at closer on the map (examined key
  /// part).
  static String lookedKey(String buildingId) => 'looked-$buildingId';

  MapBuilding building(String id) => buildings.firstWhere((b) => b.id == id);

  /// The buildings with everything the drawing shows, where a show is
  /// played ("the show remembers"): one, on a fair map.
  List<MapBuilding> get matching => [
    for (final b in buildings)
      if (b.shows && b.features.containsAll(drawing)) b,
  ];
}

// ── The hold rack, as drawn ──────────────────────────────────────────────

/// A tag where it hangs on the rack picture: the place a tap looks at it
/// ([spot]) and its paper ([paper], where its letter is written), both
/// pixels of the rack.
@immutable
class RackTag {
  const RackTag({required this.id, required this.spot, required this.paper});

  final String id;
  final Rect spot;
  final Rect paper;
}

/// M1 ([HoldRackScene]): the rack ([rack]'s rules), its picture and the
/// part of it shown ([view], pixels), its four tags; the tag up close (one
/// blank tag picture, its front and back written by the app at [writeOn],
/// pixels of the tag; the back is the same paper, turned) and the ink that
/// hides a digit; and the Letter's Trail to compare with ([trail]: Case
/// 05's slip).
@immutable
class HoldRackScene {
  const HoldRackScene({
    required this.rack,
    required this.file,
    required this.pixels,
    required this.view,
    required this.place,
    required this.tags,
    required this.tagFile,
    required this.tagPixels,
    required this.writeOn,
    required this.ink,
    required this.trail,
    required this.lookTask,
    required this.turnTask,
    required this.turnLabel,
    required this.turnBackLabel,
    required this.chooseLabel,
  });

  final HoldRack rack;
  final String file;
  final ScenePixels pixels;
  final Rect view;
  final String place;
  final List<RackTag> tags;
  final String tagFile;
  final ScenePixels tagPixels;
  final Rect writeOn;
  final String ink;
  final WrittenPaper trail;
  final String lookTask;
  final String turnTask;
  final String turnLabel;
  final String turnBackLabel;
  final String chooseLabel;

  RackTag spotOf(String id) => tags.firstWhere((t) => t.id == id);
}

// ── The plan, as drawn ───────────────────────────────────────────────────

/// A place on the plan the letter can be moved to: where its token stands
/// ([at]) and where a tap moves it there ([area]), pixels of the plan.
@immutable
class PlanPlace {
  const PlanPlace({required this.at, required this.area});

  final Offset at;
  final Rect area;
}

/// A door on the plan: where the letter stands at it, the tap's area, and
/// where its letter is written beside it ([badge]), pixels of the plan.
@immutable
class PlanDoorSpot {
  const PlanDoorSpot({required this.id, required this.at, required this.area, required this.badge});

  final String id;
  final Offset at;
  final Rect area;
  final Offset badge;
}

/// M2 ([PlanScene]): the plan ([route]'s rules), its picture and the part
/// shown ([view], pixels), where the letter starts (the post room), the
/// stairs and the statue, and the six doors.
@immutable
class PlanScene {
  const PlanScene({
    required this.route,
    required this.file,
    required this.pixels,
    required this.view,
    required this.place,
    required this.start,
    required this.steps,
    required this.doors,
    required this.task,
    required this.stairsFirst,
    required this.statueFirst,
    required this.goLabel,
  });

  final PlanRoute route;
  final String file;
  final ScenePixels pixels;
  final Rect view;
  final String place;
  final Offset start;
  final Map<PlanStep, PlanPlace> steps;
  final List<PlanDoorSpot> doors;
  final String task;

  /// Said when a place is tapped before the letter can go there.
  final String stairsFirst;
  final String statueFirst;

  /// The button that takes the letter through the door it is at ('GO
  /// THROUGH DOOR E').
  final String goLabel;

  PlanDoorSpot doorSpot(String id) => doors.firstWhere((d) => d.id == id);
}

// ── The archive, as drawn ────────────────────────────────────────────────

/// A drawer of the cabinet picture: the drawer front ([area], a tap opens
/// it) and its brass label holder's card ([label], its words written by
/// the app), pixels of the cabinet.
@immutable
class CabinetDrawer {
  const CabinetDrawer({required this.id, required this.area, required this.label});

  final String id;
  final Rect area;
  final Rect label;
}

/// A torn envelope: its picture (on the torn corner's own canvas, so the
/// corner laid at the canvas's origin sits where it was torn from) and
/// where it lies in the open drawer ([inDrawer], pixels of the drawer).
@immutable
class DrawerEnvelope {
  const DrawerEnvelope({required this.id, required this.file, required this.inDrawer});

  final String id;
  final String file;
  final Rect inDrawer;
}

/// M3 ([ArchiveScene]): the drawers' rules ([drawers]), the cabinet and the
/// open drawer, the three torn envelopes, and the corner from Clock III:
/// one picture on the same canvas as the envelopes ([envelopePixels]); its
/// paper ([cornerPiece], pixels of that canvas) is what is dragged, and its
/// sticker ([cornerTagAt]) has its number. The right envelope's round spot
/// ([sealAt]) holds the seal.
@immutable
class ArchiveScene {
  const ArchiveScene({
    required this.drawers,
    required this.cabinet,
    required this.cabinetPixels,
    required this.cabinetView,
    required this.cabinetDrawers,
    required this.drawer,
    required this.drawerPixels,
    required this.drawerView,
    required this.felt,
    required this.envelopes,
    required this.envelopePixels,
    required this.corner,
    required this.cornerPiece,
    required this.cornerTagAt,
    required this.numberTag,
    required this.seal,
    required this.sealPixels,
    required this.sealAt,
    required this.cabinetTask,
    required this.drawerTask,
    required this.layTask,
    required this.layLabel,
    required this.notHere,
    required this.notLetters,
    required this.notFit,
    required this.sealLabel,
    required this.sealLine,
  });

  final ArchiveDrawers drawers;
  final String cabinet;
  final ScenePixels cabinetPixels;
  final Rect cabinetView;
  final List<CabinetDrawer> cabinetDrawers;
  final String drawer;
  final ScenePixels drawerPixels;
  final Rect drawerView;

  /// The drawer's felt (pixels of the drawer): what an envelope looked at
  /// closer lies on.
  final Rect felt;
  final List<DrawerEnvelope> envelopes;
  final ScenePixels envelopePixels;
  final String corner;
  final Rect cornerPiece;
  final Rect cornerTagAt;

  /// The archive's round number tag, stuck on every envelope at the same
  /// place (pixels of the envelopes' canvas): over the right one's seal
  /// spot, so no envelope looks different until the corner is fitted.
  final Rect numberTag;
  final String seal;
  final ScenePixels sealPixels;
  final Rect sealAt;
  final String cabinetTask;
  final String drawerTask;
  final String layTask;
  final String layLabel;

  /// Said when a drawer of letters that does not keep 4417 is opened, and
  /// when the parcels' is ("{label}" is its label).
  final String notHere;
  final String notLetters;

  /// Said when the corner is laid on an envelope it does not fit.
  final String notFit;
  final String sealLabel;
  final String sealLine;

  DrawerEnvelope envelope(String id) => envelopes.firstWhere((e) => e.id == id);

  CabinetDrawer cabinetDrawer(String id) => cabinetDrawers.firstWhere((d) => d.id == id);

  /// What the drawer [id] holds is said when it is not the letter's.
  String refusalOf(String id) {
    final d = drawers.drawer(id);
    return (d.kind == drawers.kind ? notHere : notLetters).replaceAll('{label}', d.label);
  }

  /// The right envelope, the corner fitted on it and its seal: Case 06's
  /// torn envelope as evidence.
  FittedEnvelope get fitted => FittedEnvelope(
    envelope: envelope(drawers.fitting.single.id).file,
    corner: corner,
    pixels: envelopePixels,
    tag: drawers.cornerLabel,
    tagAt: cornerTagAt,
    seal: seal,
    sealAt: sealAt,
  );
}

/// The torn envelope with its corner back on it, the number on its sticker
/// and the seal on its round spot (all on the envelopes' one canvas).
@immutable
class FittedEnvelope implements DrawnEvidence {
  const FittedEnvelope({
    required this.envelope,
    required this.corner,
    required this.pixels,
    required this.tag,
    required this.tagAt,
    required this.seal,
    required this.sealAt,
  });

  final String envelope;
  final String corner;
  final ScenePixels pixels;
  final String tag;
  final Rect tagAt;
  final String seal;
  final Rect sealAt;

  @override
  double get aspect => pixels.aspect;
}

// ── The letter and the map, as drawn ─────────────────────────────────────

/// The letter: its paper, its lines written at [writeOn] and its drawing
/// ([sketch]) laid at [sketchAt] (pixels of the paper); its back, the same
/// paper turned over, with [back] written on it.
@immutable
class LetterPaper implements DrawnEvidence {
  const LetterPaper({
    required this.file,
    required this.pixels,
    required this.lines,
    required this.writeOn,
    required this.sketch,
    required this.sketchAt,
    required this.back,
    required this.backOn,
    this.showBack = false,
  });

  final String file;
  final ScenePixels pixels;
  final List<String> lines;
  final Rect writeOn;
  final String sketch;
  final Rect sketchAt;
  final List<String> back;
  final Rect backOn;

  /// Shown turned over (the evidence: front and back together are in its
  /// words).
  final bool showBack;

  @override
  double get aspect => pixels.aspect;
}

/// A building of the final's map where it is drawn on the Paris map
/// ([at], fractions of the map: the map's own landmark).
@immutable
class MapSpot {
  const MapSpot({required this.id, required this.name, required this.at});

  final String id;
  final String name;
  final Offset at;
}

/// The final ([LetterMapScene]): the map's rules ([map]), the letter and
/// its drawing ([sketchPixels]), and the map of Paris with the buildings
/// to look at closer ([spots]); a closer look shows [closer] of the map
/// (its width, a fraction of the map's) round a building.
@immutable
class LetterMapScene {
  const LetterMapScene({
    required this.map,
    required this.letter,
    required this.sketchPixels,
    required this.mapFile,
    required this.mapPixels,
    required this.spots,
    required this.closer,
    required this.mapTask,
    required this.drawingLabel,
    required this.chooseLabel,
    required this.backLabel,
  });

  final LetterMap map;
  final LetterPaper letter;
  final ScenePixels sketchPixels;
  final String mapFile;
  final ScenePixels mapPixels;
  final List<MapSpot> spots;
  final double closer;
  final String mapTask;

  /// What the drawing shows, for screen readers.
  final String drawingLabel;
  final String chooseLabel;
  final String backLabel;

  MapSpot spot(String id) => spots.firstWhere((s) => s.id == id);

  /// The part of the map a closer look at [s] shows (fractions): [closer]
  /// wide, 3:2 in pixels, inside the map.
  Rect closerOf(MapSpot s) {
    final w = closer;
    final h = closer * mapPixels.aspect / 1.5;
    final left = (s.at.dx - w / 2).clamp(0.0, 1 - w);
    final top = (s.at.dy - h / 2).clamp(0.0, 1 - h);
    return Rect.fromLTWH(left, top, w, h);
  }
}
