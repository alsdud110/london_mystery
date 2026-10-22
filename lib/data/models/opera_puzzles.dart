import 'dart:ui' show Offset, Rect;

import 'package:flutter/foundation.dart';

import 'river_puzzles.dart' show DrawnEvidence;
import 'scene_explore.dart' show ScenePixels;

/// Season 2, Case 07's puzzles (The Phantom Performance): the show's parts
/// slid along the clock until they fit the office record's doors and
/// curtain, the stage lit like the old photo, the backdrop the Painted
/// Street names lowered from the rope rail, and FILE 3 laid on the light
/// table, the Amendment Slip pinned to its change.
///
/// First the rules, which the case's answers and feedback are checked
/// against; then each puzzle as it is played on its pictures (measured on
/// the delivered pictures: `season2_case07_scenes.dart`). The pictures are
/// blank of words: what is written on them is written by the app.

/// A time of day as minutes after midnight, read on a 12-hour clock
/// (`4:00`), with PM where a record writes it (`4:00 PM`).
String clockOf(int minutes) {
  final h = (minutes ~/ 60) % 12;
  return '${h == 0 ? 12 : h}:${(minutes % 60).toString().padLeft(2, '0')}';
}

String clockPm(int minutes) => '${clockOf(minutes)} PM';

/// Minutes after midnight of [hour]:[minute] in the afternoon (3:00 → 15:00).
int pm(int hour, [int minute = 0]) => (hour + 12) * 60 + minute;

// ── M1 · The show strip ──────────────────────────────────────────────────

/// A part of the show, as the programme (FILE 4) lists it.
@immutable
class ShowPart {
  const ShowPart(this.name, this.minutes);

  final String name;
  final int minutes;
}

/// What the start the strip is slid to says (the case's option ids).
enum StripVerdict {
  /// The office's own 3:00: before the doors open.
  office,

  /// Before the doors open, or as they open: nobody is in the seats yet.
  early,

  /// The audience is in, but the show does not end at CURTAIN DOWN.
  end,

  /// In after the doors open, down at CURTAIN DOWN: the show fits.
  fit,
}

/// M1: the office record's times (FILE 3) and the programme's parts (FILE
/// 4). The show's strip is as long as the show (it never grows or
/// shrinks); it is slid along the clock [step] minutes at a time, its start
/// from [earliest] to [latest].
@immutable
class ShowStrip {
  const ShowStrip({
    required this.parts,
    required this.doorsOpen,
    required this.officeStart,
    required this.curtainDown,
    required this.from,
    required this.to,
    required this.earliest,
    required this.latest,
    required this.step,
    required this.initial,
  });

  final List<ShowPart> parts;

  /// FILE 3's lines: DOORS OPEN, CURTAIN UP (the office's), CURTAIN DOWN.
  final int doorsOpen;
  final int officeStart;
  final int curtainDown;

  /// The clock's line: from [from] to [to].
  final int from;
  final int to;

  /// Where the strip's start can be slid.
  final int earliest;
  final int latest;
  final int step;

  /// Where the strip starts: on the office's own time.
  final int initial;

  /// The whole show, in minutes.
  int get length => parts.fold(0, (sum, p) => sum + p.minutes);

  int endOf(int start) => start + length;

  /// Every start the strip can be slid to, in order.
  List<int> get starts => [for (var s = earliest; s <= latest; s += step) s];

  /// [start] moved to the nearest start the strip can have.
  int snap(num start) {
    final steps = ((start - earliest) / step).round();
    return (earliest + steps * step).clamp(earliest, latest);
  }

  StripVerdict verdict(int start) {
    if (start == officeStart) return StripVerdict.office;
    if (start <= doorsOpen) return StripVerdict.early;
    if (endOf(start) != curtainDown) return StripVerdict.end;
    return StripVerdict.fit;
  }

  /// The starts where the show fits (one, on a fair record).
  List<int> get fitting => [for (final s in starts) if (verdict(s) == StripVerdict.fit) s];
}

// ── M2 · The ghost light ─────────────────────────────────────────────────

/// The lighting desk's four levers, left to right.
enum StageLight {
  ghost('GHOST LIGHT'),
  house('HOUSE LIGHTS'),
  foot('FOOTLIGHTS'),
  spot('BIG SPOT');

  const StageLight(this.label);

  final String label;
}

/// M2: the lights the old photo shows ([photo]: the ghost light only).
/// Every lever is OFF at first; any of the sixteen settings can be checked.
@immutable
class LightBoard {
  const LightBoard({required this.photo});

  final Set<StageLight> photo;

  /// Where the old photo counts as looked at closer, the cue card as read
  /// and the scrap in the Lighting Book as found (examined key parts).
  static const photoId = 'photo';
  static const cueId = 'cue';
  static const scrapId = 'scrap';

  /// What the lights [on] say, checked against the photo light by light in
  /// the desk's order: the first that differs (`ghostOff`: a light of the
  /// photo left off; `house`: a light the photo has not, on), or `match`.
  String verdict(Set<StageLight> on) {
    for (final l in StageLight.values) {
      if (on.contains(l) != photo.contains(l)) return photo.contains(l) ? '${l.name}Off' : l.name;
    }
    return matchId;
  }

  static const matchId = 'match';

  /// Every setting of the four levers.
  static List<Set<StageLight>> get settings => [
    for (var bits = 0; bits < 1 << StageLight.values.length; bits++)
      {for (final l in StageLight.values) if (bits & (1 << l.index) != 0) l},
  ];
}

// ── M3 · The painted sky ─────────────────────────────────────────────────

enum DoorColour { red, blue }

/// What is painted right above a backdrop's door.
enum AboveDoor { smallClock, lamp, nothing }

/// A painted backdrop on the rope rail: its door's colour, what is right
/// above the door, and whether a clock tower stands far off in the sky.
@immutable
class Backdrop {
  const Backdrop({required this.id, required this.door, required this.above, this.tower = false});

  final String id;
  final DoorColour door;
  final AboveDoor above;
  final bool tower;
}

/// M3: the Painted Street (Case 02's evidence: "Above the red door: a small
/// clock.") and the backdrops on the rail, in rope order. Lowering one
/// counts as looking at it; the right one hides the pocket.
@immutable
class FlyRail {
  const FlyRail({required this.door, required this.above, required this.ropes});

  final DoorColour door;
  final AboveDoor above;

  /// The backdrops, rope 1 first.
  final List<Backdrop> ropes;

  /// Where a backdrop counts as lowered, and where the pocket behind the
  /// right one counts as opened (examined key parts).
  static String loweredKey(String backdropId) => 'backdrop-$backdropId';
  static const pocketId = 'pocket';

  Backdrop backdrop(String id) => ropes.firstWhere((b) => b.id == id);

  bool matches(Backdrop b) => b.door == door && b.above == above;

  /// The backdrops that match the Painted Street (one, on a fair rail).
  List<Backdrop> get matching => [for (final b in ropes) if (matches(b)) b];

  /// How many of the clue's two things [b] gets wrong.
  int misses(Backdrop b) => (b.door == door ? 0 : 1) + (b.above == above ? 0 : 1);
}

// ── Final · The changed record ───────────────────────────────────────────

/// Where a pin can be pressed into FILE 3 on the light table: a line that
/// was never patched, the new time on the patch, or the old time under it
/// (seen only with the light on).
enum RecordSpot { doors, patch, under, down }

/// The final: which record was changed ([changed], of [files]), FILE 3 on
/// the light table, and the Amendment Slip's two times pinned to the
/// change: its old time ([oldPin]) on the time under the patch, its new
/// time ([newPin]) on the patch.
@immutable
class ChangedRecord {
  const ChangedRecord({required this.files, required this.changed, required this.oldTime, required this.newTime});

  /// The records on the archive table (`file3`, `file4`).
  final List<String> files;
  final String changed;

  /// The slip's two times (minutes after midnight).
  final int oldTime;
  final int newTime;

  static const oldPin = 'old';
  static const newPin = 'new';

  /// Where each of the slip's pins belongs.
  static const homes = {oldPin: RecordSpot.under, newPin: RecordSpot.patch};

  /// Saved as the final goes (examined key parts): FILE 3 chosen, laid on
  /// the light table, seen with the light on; each pin pressed in; the
  /// slip turned over once the case is solved.
  static const chosenId = 'file3';
  static const placedId = 'placed';
  static const litId = 'lit';
  static String pinnedKey(String pin) => 'pin-$pin';
  static const slipBackId = 'slip-back';

  /// The answer of a record chosen ([file]): checked as the case's answer
  /// when it is the wrong one.
  static String pickPart(String file) => 'pick:$file';

  /// The spots a pin can go to: under the patch only with the light on.
  static List<RecordSpot> spots({required bool lit}) => [
    for (final s in RecordSpot.values)
      if (s != RecordSpot.under || lit) s,
  ];

  /// Whether [pin] pressed into [spot] is right.
  static bool fits(String pin, RecordSpot spot) => homes[pin] == spot;

  /// The part [pin] pressed into [spot] answers (`old:under`); the old
  /// time pressed onto the patch in the dark is its own (`old:unlit`: the
  /// light first).
  static String partOf(String pin, RecordSpot spot, {required bool lit}) =>
      !lit && pin == oldPin && spot == RecordSpot.patch ? '$oldPin:unlit' : '$pin:${spot.name}';

  /// The whole answer: both pins where they belong.
  static String get answer => [for (final MapEntry(key: pin, value: spot) in homes.entries) '$pin:${spot.name}'].join(',');
}

// ── The papers, as drawn ─────────────────────────────────────────────────

/// A line of FILE 3: its words ([label]) and its time ([time]), written at
/// [labelAt] and [timeAt] (pixels of the record).
@immutable
class RecordRow {
  const RecordRow({required this.id, required this.label, required this.time, required this.labelAt, required this.timeAt});

  final RecordSpot id;
  final String label;
  final String time;
  final Rect labelAt;
  final Rect timeAt;
}

/// The thicker, whiter paper glued over FILE 3's CURTAIN UP time: its
/// picture ([file], cut out; the paper is [paper], pixels of it), where it
/// lies ([at], pixels of the record), the new time written on it
/// ([newAt]) and the old one under it ([oldAt]).
@immutable
class RecordPatch {
  const RecordPatch({
    required this.file,
    required this.pixels,
    required this.paper,
    required this.at,
    required this.newTime,
    required this.newAt,
    required this.oldTime,
    required this.oldAt,
  });

  final String file;
  final ScenePixels pixels;
  final Rect paper;
  final Rect at;
  final String newTime;
  final Rect newAt;
  final String oldTime;
  final Rect oldAt;
}

/// The old photo as it is mounted: the mount ([file], cut out, its window
/// [window]) with the stage in it ([stage], sepia: the ghost light only)
/// and what is written under it ([caption], at [captionAt]); all pixels of
/// the mount.
@immutable
class PhotoPrint implements DrawnEvidence {
  const PhotoPrint({
    required this.file,
    required this.pixels,
    required this.window,
    required this.stage,
    required this.stagePixels,
    required this.caption,
    required this.captionAt,
  });

  final String file;
  final ScenePixels pixels;
  final Rect window;
  final String stage;
  final ScenePixels stagePixels;
  final String caption;
  final Rect captionAt;

  @override
  double get aspect => pixels.aspect;
}

/// How FILE 3 is seen: on a desk, or on the light table with its light off
/// or on (the patch's edge and the old time under it show through).
enum RecordLight { desk, unlit, lit }

/// FILE 3, the office record: its paper, the file's number in the
/// heading's oval ([fileAt]), the show's name and number ([titleAt]), its
/// three lines, the patch over CURTAIN UP's time, and the old photo
/// mounted below ([photoAt]).
@immutable
class OfficeRecord implements DrawnEvidence {
  const OfficeRecord({
    required this.file,
    required this.pixels,
    required this.fileLabel,
    required this.fileAt,
    required this.title,
    required this.titleAt,
    required this.rows,
    required this.patch,
    required this.photo,
    required this.photoAt,
    this.light = RecordLight.desk,
  });

  final String file;
  final ScenePixels pixels;
  final String fileLabel;
  final Rect fileAt;
  final List<String> title;
  final Rect titleAt;
  final List<RecordRow> rows;
  final RecordPatch patch;
  final PhotoPrint photo;
  final Rect photoAt;
  final RecordLight light;

  RecordRow row(RecordSpot id) => rows.firstWhere((r) => r.id == id);

  OfficeRecord seen(RecordLight light) => OfficeRecord(
    file: file,
    pixels: pixels,
    fileLabel: fileLabel,
    fileAt: fileAt,
    title: title,
    titleAt: titleAt,
    rows: rows,
    patch: patch,
    photo: photo,
    photoAt: photoAt,
    light: light,
  );

  @override
  double get aspect => pixels.aspect;
}

/// FILE 4, the programme: its paper, the show's name ([titleAt]), its
/// parts ([partsAt]) and the whole show ([wholeAt]). No start time is
/// written on it.
@immutable
class ProgrammePage implements DrawnEvidence {
  const ProgrammePage({
    required this.file,
    required this.pixels,
    required this.title,
    required this.titleAt,
    required this.parts,
    required this.partsAt,
    required this.whole,
    required this.wholeAt,
  });

  final String file;
  final ScenePixels pixels;
  final List<String> title;
  final Rect titleAt;
  final List<ShowPart> parts;
  final Rect partsAt;
  final String whole;
  final Rect wholeAt;

  @override
  double get aspect => pixels.aspect;
}

/// The stage cue card: its heading ([headingAt]) and its lines ([lines],
/// at [linesAt]); the time is the last line, written large.
@immutable
class CueCard implements DrawnEvidence {
  const CueCard({required this.file, required this.pixels, required this.heading, required this.headingAt, required this.lines, required this.linesAt});

  final String file;
  final ScenePixels pixels;
  final String heading;
  final Rect headingAt;
  final List<String> lines;
  final Rect linesAt;

  @override
  double get aspect => pixels.aspect;
}

/// The Amendment Slip: its header ([header]), its lines and the change
/// (`CURTAIN UP:` [changeLabel] from the old time to the new: each time
/// written where its pin is, [oldAt] and [newAt]); the office's stamp, a
/// clock with no hands in a ring of leaves ([stampAt]), and no name. Its
/// back ([back]): the sketch and its words.
@immutable
class AmendmentSlip implements DrawnEvidence {
  const AmendmentSlip({
    required this.file,
    required this.pixels,
    required this.paper,
    required this.header,
    required this.headerAt,
    required this.lines,
    required this.linesAt,
    required this.changeLabel,
    required this.changeAt,
    required this.oldTime,
    required this.oldAt,
    required this.newTime,
    required this.newAt,
    required this.stamp,
    required this.stampAt,
    required this.back,
    this.showBack = false,
  });

  final String file;
  final ScenePixels pixels;

  /// The slip's paper (pixels of its picture): what is shown of it.
  final Rect paper;
  final String header;
  final Rect headerAt;
  final List<String> lines;
  final Rect linesAt;
  final String changeLabel;
  final Rect changeAt;
  final String oldTime;
  final Rect oldAt;
  final String newTime;
  final Rect newAt;
  final String stamp;
  final Rect stampAt;
  final SlipBack back;
  final bool showBack;

  /// The words of its front, in order.
  List<String> get words => [header, ...lines, '$changeLabel $oldTime to $newTime'];

  AmendmentSlip turned() => AmendmentSlip(
    file: file,
    pixels: pixels,
    paper: paper,
    header: header,
    headerAt: headerAt,
    lines: lines,
    linesAt: linesAt,
    changeLabel: changeLabel,
    changeAt: changeAt,
    oldTime: oldTime,
    oldAt: oldAt,
    newTime: newTime,
    newAt: newAt,
    stamp: stamp,
    stampAt: stampAt,
    back: back,
    showBack: true,
  );

  @override
  double get aspect => paper.width / paper.height;
}

/// The back of the Amendment Slip: a small pencil sketch ([sketch], cut
/// out, laid at [sketchAt], pixels of the slip), the name on its metro
/// sign ([signAt], pixels of the sketch) and the line under it ([note], at
/// [noteAt]).
@immutable
class SlipBack {
  const SlipBack({
    required this.sketch,
    required this.sketchPixels,
    required this.sketchAt,
    required this.sign,
    required this.signAt,
    required this.note,
    required this.noteAt,
  });

  final String sketch;
  final ScenePixels sketchPixels;
  final Rect sketchAt;
  final String sign;
  final Rect signAt;
  final String note;
  final Rect noteAt;
}

// ── M1, as drawn ─────────────────────────────────────────────────────────

/// M1 ([ShowStripScene]): the rules ([strip]), FILE 3 and FILE 4, and the
/// paper strip the show is drawn on ([stripFile]: its paper is
/// [stripPaper]; [stripSlice] is the part that stretches, so its printed
/// edges keep their size).
@immutable
class ShowStripScene {
  const ShowStripScene({
    required this.strip,
    required this.record,
    required this.programme,
    required this.stripFile,
    required this.stripPixels,
    required this.stripPaper,
    required this.stripSlice,
    required this.task,
    required this.checkLabel,
  });

  final ShowStrip strip;
  final OfficeRecord record;
  final ProgrammePage programme;
  final String stripFile;
  final ScenePixels stripPixels;
  final Rect stripPaper;
  final Rect stripSlice;
  final String task;
  final String checkLabel;
}

// ── M2, as drawn ─────────────────────────────────────────────────────────

/// A lever's slot on the lighting desk ([slot]) and its name plate
/// ([plate]), pixels of the desk.
@immutable
class DeskSlot {
  const DeskSlot({required this.light, required this.slot, required this.plate});

  final StageLight light;
  final Rect slot;
  final Rect plate;
}

/// The Lighting Book open ([file]): its two pages ([left], [right], pixels
/// of the book).
@immutable
class LightingBook {
  const LightingBook({required this.file, required this.pixels, required this.left, required this.right, required this.title, required this.entries});

  final String file;
  final ScenePixels pixels;
  final Rect left;
  final Rect right;
  final String title;

  /// What the book says of each light (`GHOST LIGHT` → its lines).
  final List<(String, List<String>)> entries;
}

/// M2 ([LightBoardScene]): the rules ([board]); the stage seen from the
/// back of the hall, all lights off ([stage]) and with each light on
/// ([lit]: the same picture, one light on), laid over it lighter-only so
/// any lights can be on together; the lighting desk and its lever; the
/// Lighting Book; the old photo; and, once the stage matches, the book's
/// page for show No. 34 with the cue card on it and the scrap tucked in.
@immutable
class LightBoardScene {
  const LightBoardScene({
    required this.board,
    required this.stage,
    required this.stagePixels,
    required this.lit,
    required this.desk,
    required this.deskPixels,
    required this.deskPaper,
    required this.slots,
    required this.lever,
    required this.leverPixels,
    required this.leverPaper,
    required this.book,
    required this.photo,
    required this.cue,
    required this.cueOnPage,
    required this.scrap,
    required this.scrapPixels,
    required this.scrapAt,
    required this.pageTitle,
    required this.task,
    required this.checkLabel,
    required this.emptyLine,
    required this.scrapLine,
  });

  final LightBoard board;
  final String stage;
  final ScenePixels stagePixels;
  final Map<StageLight, String> lit;
  final String desk;
  final ScenePixels deskPixels;

  /// The desk's panel (pixels of its picture): what is shown of it.
  final Rect deskPaper;
  final List<DeskSlot> slots;
  final String lever;
  final ScenePixels leverPixels;

  /// The lever itself (pixels of its picture).
  final Rect leverPaper;
  final LightingBook book;
  final PhotoPrint photo;
  final CueCard cue;

  /// Where the cue card lies on the book's right page (pixels of the book).
  final Rect cueOnPage;
  final String scrap;
  final ScenePixels scrapPixels;

  /// Where the scrap is tucked (pixels of the book).
  final Rect scrapAt;

  /// The book's page for the show, written on its left page.
  final List<String> pageTitle;
  final String task;
  final String checkLabel;

  /// Said once the stage matches: what the photo shows.
  final String emptyLine;

  /// Said of the scrap, found.
  final String scrapLine;

  DeskSlot slotOf(StageLight l) => slots.firstWhere((s) => s.light == l);
}

// ── M3, as drawn ─────────────────────────────────────────────────────────

/// A backdrop's picture (cut out: canvas, top batten, bottom pole).
@immutable
class BackdropArt {
  const BackdropArt({required this.id, required this.file, required this.label});

  final String id;
  final String file;

  /// What it shows, for screen readers.
  final String label;
}

/// M3 ([FlyRailScene]): the rules ([rail]); the stage (where a backdrop
/// comes down: [opening], pixels of the stage, inside the part shown,
/// [stageView]); the rope rail ([railFile], shown [railView]) with a rope
/// at each lock ([ropeX], pixels of the rail, rope 1 first) and its card
/// ([plates]); the backdrops ([backdrops], [backdropPixels]: their canvas
/// is [canvas]) and what to look at closer ([closer]); the Painted Street
/// from the notebook ([clueFile], [clueCrop]); and, once the right one is
/// chosen, its back ([back]) with the pocket ([pocket]) and the slip in it.
@immutable
class FlyRailScene {
  const FlyRailScene({
    required this.rail,
    required this.stage,
    required this.stagePixels,
    required this.stageView,
    required this.opening,
    required this.railFile,
    required this.railPixels,
    required this.railView,
    required this.ropeX,
    required this.plates,
    required this.lockTop,
    required this.rope,
    required this.ropePixels,
    required this.ropeStrand,
    required this.backdrops,
    required this.backdropPixels,
    required this.canvas,
    required this.closer,
    required this.clueFile,
    required this.cluePixels,
    required this.clueCrop,
    required this.clueLine,
    required this.back,
    required this.backPixels,
    required this.pocket,
    required this.slip,
    required this.task,
    required this.chooseLabel,
    required this.pocketTask,
  });

  final FlyRail rail;
  final String stage;
  final ScenePixels stagePixels;
  final Rect stageView;
  final Rect opening;
  final String railFile;
  final ScenePixels railPixels;
  final Rect railView;
  final List<double> ropeX;
  final List<Rect> plates;

  /// Where the locks start (pixels of the rail): a rope passes behind them.
  final double lockTop;
  final String rope;
  final ScenePixels ropePixels;

  /// The rope itself in its picture (pixels: its left and right edge).
  final (double, double) ropeStrand;
  final List<BackdropArt> backdrops;
  final ScenePixels backdropPixels;
  final Rect canvas;
  final Rect closer;
  final String clueFile;
  final ScenePixels cluePixels;
  final Rect clueCrop;
  final String clueLine;
  final String back;
  final ScenePixels backPixels;
  final Rect pocket;
  final AmendmentSlip slip;
  final String task;
  final String chooseLabel;
  final String pocketTask;

  BackdropArt art(String id) => backdrops.firstWhere((b) => b.id == id);
}

// ── Final, as drawn ──────────────────────────────────────────────────────

/// A place on FILE 3 a pin can be pressed into ([area]: where a tap or a
/// drop counts; [at]: where the pin goes), pixels of the record.
@immutable
class PinSpot {
  const PinSpot({required this.spot, required this.area, required this.at, this.via = const []});

  final RecordSpot spot;
  final Rect area;
  final Offset at;

  /// The way a red thread comes to the pin across the record (pixels of
  /// it), after it comes in from the record's left edge at the first
  /// point's height (the pin's own, with none): only through blank paper
  /// between the lines, never over their words.
  final List<Offset> via;

  /// The thread's way on the record, from its left edge at [left] to the
  /// pin.
  List<Offset> threadOn(double left) => [Offset(left, (via.isEmpty ? at : via.first).dy), ...via, at];
}

/// The final ([LightTableScene]): the rules ([record]); the archive table
/// (its box's label [labelAt], written [label]); FILE 3 and FILE 4 with
/// the cue card; the light table off and on ([table], [tableOn]): its
/// glass ([glass]) and brass switch ([switchAt]); the part of FILE 3 laid
/// on the glass up close ([closeUp], pixels of the record) and the places
/// a pin can go ([pins]); and the Amendment Slip.
@immutable
class LightTableScene {
  const LightTableScene({
    required this.record,
    required this.archive,
    required this.archivePixels,
    required this.archiveView,
    required this.label,
    required this.labelAt,
    required this.file3,
    required this.programme,
    required this.cue,
    required this.table,
    required this.tableOn,
    required this.tablePixels,
    required this.glass,
    required this.switchAt,
    required this.closeUp,
    required this.pins,
    required this.slip,
    required this.chooseTask,
    required this.placeTask,
    required this.lightTask,
    required this.pinTask,
  });

  final ChangedRecord record;
  final String archive;
  final ScenePixels archivePixels;
  final Rect archiveView;
  final String label;
  final Rect labelAt;
  final OfficeRecord file3;
  final ProgrammePage programme;
  final CueCard cue;
  final String table;
  final String tableOn;
  final ScenePixels tablePixels;
  final Rect glass;
  final Rect switchAt;
  final Rect closeUp;
  final List<PinSpot> pins;
  final AmendmentSlip slip;
  final String chooseTask;
  final String placeTask;
  final String lightTask;
  final String pinTask;

  PinSpot pin(RecordSpot s) => pins.firstWhere((p) => p.spot == s);
}
