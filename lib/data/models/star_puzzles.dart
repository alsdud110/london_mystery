import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart' show Offset, Rect;

import 'letter_puzzles.dart' show MapSpot;
import 'river_puzzles.dart' show DrawnEvidence;
import 'scene_explore.dart' show ScenePixels;

/// Season 2, Case 10 — The Hour of Shadows: its puzzles as they are played
/// on the case's pictures (`docs/SEASON2_CASE10_SPEC.md`). Every place is
/// in the delivered picture's own pixels.

/// A time of day as minutes after twelve (2:30 → 150), written "2:30".
String clockText(int minutes) => '${(minutes ~/ 60 + 11) % 12 + 1}:${(minutes % 60).toString().padLeft(2, '0')}';

// ── The Star Room ───────────────────────────────────────────────────────

/// The little stone room under the roof (`star_room.png`): its blank brass
/// plate, where the app engraves its words ([plateLines]) turned with it,
/// the star on its door, and the three things on its table.
@immutable
class StarRoom {
  const StarRoom({
    required this.file,
    required this.pixels,
    required this.label,
    required this.plateCentre,
    required this.plateSize,
    required this.plateAngle,
    required this.plateLines,
    required this.doorStar,
    required this.things,
  });

  final String file;
  final ScenePixels pixels;
  final String label;

  /// The plate's inner panel: its centre and size (pixels), and how far it
  /// is turned (degrees, clockwise; it leans up to the right).
  final Offset plateCentre;
  final (double, double) plateSize;
  final double plateAngle;
  final List<String> plateLines;

  /// The star on the door (a circle round it, pixels).
  final Rect doorStar;

  /// The drum, the box of photos and the book (pixels), in that order.
  final List<Rect> things;
}

// ── M1 — the drum tape ──────────────────────────────────────────────────

/// One mark on T1's tape: what T1 printed there ([printed], minutes) and
/// the real time it was printed at ([real], minutes; told only in the
/// final, never on the tape). Marks are fifteen real minutes apart.
@immutable
class TapeMark {
  const TapeMark({required this.id, required this.printed, required this.real});

  final String id;
  final int printed;
  final int real;

  String get printedText => clockText(printed);
  String get realText => clockText(real);
}

/// T1's paper tape ([MissionType.matchPairs], `jump:mark`): pulled from the
/// drum (`record_drum.png`, its slot at [slot]), then the two marks where
/// the time jumps tapped. A mark that follows on fifteen minutes is said so,
/// never a wrong answer.
@immutable
class DrumTapeScene {
  const DrumTapeScene({
    required this.drumFile,
    required this.drumPixels,
    required this.slot,
    required this.plate,
    required this.header,
    required this.marks,
    required this.task,
    required this.pullLabel,
    required this.startLine,
    required this.oneMore,
    required this.found,
  });

  final String drumFile;
  final ScenePixels drumPixels;

  /// Where the tape comes out of the drum, and its blank plate (pixels).
  final Offset slot;
  final Rect plate;

  /// Printed at the head of the tape.
  final String header;
  final List<TapeMark> marks;
  final String task;
  final String pullLabel;
  final String startLine;
  final String oneMore;
  final String found;

  /// Kept once the tape is pulled out.
  static const pulledId = 'pulled';

  TapeMark mark(String id) => marks.firstWhere((m) => m.id == id);

  int indexOf(String id) => marks.indexWhere((m) => m.id == id);

  /// The marks where the time jumps: not fifteen minutes after the mark
  /// before them.
  Set<String> get jumps => {
    for (var i = 1; i < marks.length; i++)
      if (marks[i].printed - marks[i - 1].printed != 15) marks[i].id,
  };

  /// What a tap on [id] says when it is no jump.
  String lineFor(String id) {
    final i = indexOf(id);
    if (i <= 0) return startLine;
    return '${marks[i].printedText} comes fifteen minutes after ${marks[i - 1].printedText}. That\'s fine.';
  }

  /// The jumps found, in the tape's order, as the mission's answer.
  String answerOf(Set<String> found) => [
    for (final m in marks)
      if (found.contains(m.id)) 'jump:${m.id}',
  ].join(',');
}

/// The jumps found on the tape, saved (`t5;t9`): only jumps.
abstract final class DrumTapeState {
  static String encode(Set<String> found) => found.join(';');

  static Set<String> decode(String? saved, DrumTapeScene scene) {
    final jumps = scene.jumps;
    return {
      for (final id in (saved ?? '').split(';'))
        if (jumps.contains(id)) id,
    };
  }
}

// ── The roof photos ─────────────────────────────────────────────────────

/// A clock in the roof photos: its face's centre and half-axes (pixels,
/// the faces are seen a little from the side), whether it is a trial clock,
/// and the time it shows in Photo 1 and in Photo 2 (minutes).
@immutable
class PhotoClock {
  const PhotoClock({
    required this.id,
    required this.name,
    required this.label,
    required this.centre,
    required this.rx,
    required this.ry,
    required this.trial,
    required this.photo1,
    required this.photo2,
    required this.wrongLine,
    required this.card,
  });

  final String id;
  final String name;
  final String label;
  final Offset centre;
  final double rx;
  final double ry;
  final bool trial;
  final int photo1;
  final int photo2;

  /// The part of the photo on its card once found (pixels): the clock and
  /// what it hangs on (T1's post and its star; the café's corner…).
  final Rect card;

  /// Said when it is put in the wrong tray.
  final String wrongLine;

  int timeIn(int photo) => photo == 1 ? photo1 : photo2;
}

/// The sundial in the roof photos, seen from the side: where its lines meet
/// ([hub]), its plate's half-axes on the picture, and how far its gnomon is
/// turned on the plate (degrees, clockwise from straight away from the
/// camera). A direction on the plate ([SundialLine.angle], from the gnomon)
/// is drawn on the picture through these.
@immutable
class PhotoDial {
  const PhotoDial({required this.hub, required this.rx, required this.ry, required this.gnomonTurn});

  final Offset hub;
  final double rx;
  final double ry;
  final double gnomonTurn;

  /// The point on the picture [length] (a fraction of the plate's radius)
  /// along the plate direction [angle] (degrees from the gnomon).
  Offset along(double angle, double length) {
    final b = (angle + gnomonTurn) * math.pi / 180;
    return hub + Offset(math.sin(b) * rx * length, -math.cos(b) * ry * length);
  }
}

/// Both roof photos: one picture (`roof_photo.png`, taken from the same
/// place twice), its four clocks and its sundial. The hands and the shadow
/// are the app's.
@immutable
class RoofPhoto {
  const RoofPhoto({required this.file, required this.pixels, required this.label, required this.clocks, required this.dial, required this.t1Crop, required this.dialCrop});

  final String file;
  final ScenePixels pixels;
  final String label;
  final List<PhotoClock> clocks;
  final PhotoDial dial;

  /// T1's face and the sundial, cut from the photo for a photo card.
  final Rect t1Crop;
  final Rect dialCrop;

  PhotoClock clock(String id) => clocks.firstWhere((c) => c.id == id);
}

// ── M2 — a city of clocks ───────────────────────────────────────────────

/// M2 ([MissionType.matchPairs], `clock:tray`): Photo 2 looked at under a
/// glass; every clock found goes to the tray; each sorted into TRIAL CLOCK
/// or NOT A TRIAL CLOCK. A wrong tray sends it back with its line. All
/// four sorted answer the mission.
@immutable
class CityClocksScene {
  const CityClocksScene({
    required this.photo,
    required this.task,
    required this.sortTask,
    required this.trialTray,
    required this.otherTray,
    required this.lensScale,
    required this.lensSize,
    required this.moreLine,
    required this.foundLine,
    required this.sortedLines,
    required this.trialMapId,
  });

  final RoofPhoto photo;

  /// The Trial Map (Case 09's evidence), shown beside the photo: where the
  /// trial clocks are and their signs.
  final String trialMapId;
  final String task;
  final String sortTask;
  final String trialTray;
  final String otherTray;

  /// The glass: how many screen points one photo pixel takes in it, and
  /// its width (points).
  final double lensScale;
  final double lensSize;
  final String moreLine;
  final String foundLine;

  /// Shown once every clock is sorted (what the photo says, no more).
  final List<String> sortedLines;

  static const trial = 'trial';
  static const other = 'not';

  /// The clock whose face [p] (photo pixels) is on, or within [reach]
  /// pixels of, else null; the nearest one.
  PhotoClock? clockAt(Offset p, double reach) {
    PhotoClock? best;
    var bestD = double.infinity;
    for (final c in photo.clocks) {
      final d = (c.centre - p).distance;
      final r = math.max(math.max(c.rx, c.ry) * 1.25, reach);
      if (d <= r && d < bestD) {
        best = c;
        bestD = d;
      }
    }
    return best;
  }

  String trayOf(PhotoClock c) => c.trial ? trial : other;

  String answerOf(Map<String, String> sorted) => [
    for (final c in photo.clocks)
      if (sorted[c.id] case final t?) '${c.id}:$t',
  ].join(',');
}

/// The clocks found and sorted, saved (`found=t1,cafe;sorted=t1:trial`):
/// only clocks of the photo, and only a clock in its own tray.
abstract final class CityClocksState {
  static String encode(Set<String> found, Map<String, String> sorted) =>
      'found=${found.join(',')};sorted=${[for (final e in sorted.entries) '${e.key}:${e.value}'].join(',')}';

  static (Set<String>, Map<String, String>) decode(String? saved, CityClocksScene scene) {
    final found = <String>{};
    final sorted = <String, String>{};
    final ids = {for (final c in scene.photo.clocks) c.id};
    for (final part in (saved ?? '').split(';')) {
      if (part.startsWith('found=')) {
        found.addAll(part.substring(6).split(',').where(ids.contains));
      } else if (part.startsWith('sorted=')) {
        for (final pair in part.substring(7).split(',')) {
          if (pair.split(':') case [final id, final tray] when ids.contains(id) && scene.trayOf(scene.photo.clock(id)) == tray) sorted[id] = tray;
        }
      }
    }
    found.addAll(sorted.keys);
    return (found, sorted);
  }
}

// ── M3 — the hour of shadows ────────────────────────────────────────────

/// One hour line of the sundial: its time (minutes) and its direction
/// (degrees, clockwise from the gnomon, measured on `sundial_top.png`).
@immutable
class SundialLine {
  const SundialLine(this.time, this.angle);

  final int time;
  final double angle;
}

/// The roof's sundial seen from above (`sundial_top.png`): its hub, its
/// plate's radius and its seven hour lines, 1:00 to 4:00. Everything about
/// the sun and the shadow comes from [lines] alone (never an even spread:
/// the lines are not evenly apart). The straight line down from the hub is
/// the gnomon's own line, never an hour.
@immutable
class Sundial {
  const Sundial({
    required this.file,
    required this.pixels,
    required this.hub,
    required this.radius,
    required this.plate,
    required this.lines,
    required this.shortest,
    required this.longest,
    this.snap = 0.4,
  });

  final String file;
  final ScenePixels pixels;
  final Offset hub;

  /// Where the hour lines end (pixels from the hub), and the plate's edge.
  final double radius;
  final double plate;
  final List<SundialLine> lines;

  /// The shadow's length at the first and at the last line (fractions of
  /// [radius]); in between, by the time.
  final double shortest;
  final double longest;

  /// How near a line (a fraction of the gap to the next line) a shadow
  /// settles on it.
  final double snap;

  int get first => lines.first.time;
  int get last => lines.last.time;

  /// The direction of the shadow at [time] (minutes), between the lines.
  double angleAt(double time) {
    final t = time.clamp(first.toDouble(), last.toDouble());
    for (var i = 1; i < lines.length; i++) {
      final a = lines[i - 1], b = lines[i];
      if (t <= b.time) return a.angle + (b.angle - a.angle) * (t - a.time) / (b.time - a.time);
    }
    return lines.last.angle;
  }

  /// The time whose shadow points at [angle] (degrees), between the lines.
  double timeAt(double angle) {
    final a0 = angle.clamp(lines.first.angle, lines.last.angle);
    for (var i = 1; i < lines.length; i++) {
      final a = lines[i - 1], b = lines[i];
      if (a0 <= b.angle) return a.time + (b.time - a.time) * (a0 - a.angle) / (b.angle - a.angle);
    }
    return last.toDouble();
  }

  /// The shadow's length at [time] (a fraction of [radius]).
  double lengthAt(double time) {
    final f = ((time - first) / (last - first)).clamp(0.0, 1.0);
    return shortest + (longest - shortest) * f;
  }

  /// The line nearest [time].
  SundialLine nearest(double time) => lines.reduce((a, b) => (a.time - time).abs() <= (b.time - time).abs() ? a : b);

  /// The line the shadow settles on at [time] while moving: the nearest one
  /// when within [snap] of the gap to its neighbour, else null.
  SundialLine? settleAt(double time) {
    final n = nearest(time);
    final i = lines.indexOf(n);
    final angle = angleAt(time);
    final gaps = [
      if (i > 0) n.angle - lines[i - 1].angle,
      if (i < lines.length - 1) lines[i + 1].angle - n.angle,
    ];
    final gap = gaps.reduce(math.min);
    return (angle - n.angle).abs() <= gap * snap ? n : null;
  }

  /// The sun's direction at [time]: opposite its shadow.
  double sunAngleAt(double time) => angleAt(time) + 180;
}

/// A roof photo to make the shadow of: what T1 shows in it, and the sun's
/// time its shadow tells ([sun], minutes).
@immutable
class ShadowPhoto {
  const ShadowPhoto({required this.id, required this.number, required this.t1, required this.sun});

  final String id;
  final int number;
  final int t1;
  final int sun;

  String get name => 'PHOTO $number';
}

/// M3 ([MissionType.matchPairs], `photo:time`): the sun moved round the
/// roof's sundial until its shadow is the shadow in Photo 1, then Photo 2.
/// The shadow settles on any line; only the photo's own time answers it.
@immutable
class ShadowCheckScene {
  const ShadowCheckScene({
    required this.sundial,
    required this.photo,
    required this.photos,
    required this.task,
    required this.dragLine,
    required this.longer,
    required this.shorter,
    required this.matchLine,
    required this.nextLabel,
    required this.plateWords,
  });

  final Sundial sundial;
  final RoofPhoto photo;
  final List<ShadowPhoto> photos;
  final String task;
  final String dragLine;

  /// Said when the shadow settles on another line: the photo's is longer,
  /// or shorter.
  final String longer;
  final String shorter;
  final String matchLine;
  final String nextLabel;

  /// The words round the sundial's rim.
  final String plateWords;

  static String timeId(int minutes) => 't${clockText(minutes).replaceAll(':', '')}';

  String answerOf(Set<String> matched) => [
    for (final p in photos)
      if (matched.contains(p.id)) '${p.id}:${timeId(p.sun)}',
  ].join(',');
}

/// The photos whose shadow is made, saved (`photo1;photo2`).
abstract final class ShadowCheckState {
  static String encode(Set<String> matched) => matched.join(';');

  static Set<String> decode(String? saved, ShadowCheckScene scene) => {
    for (final id in (saved ?? '').split(';'))
      if (scene.photos.any((p) => p.id == id)) id,
  };
}

// ── Final — the hour was recorded ───────────────────────────────────────

/// A page of the Trial Log's contents: its number and its hour; [inBook]:
/// whether the page is in the book.
@immutable
class LogPage {
  const LogPage({required this.id, required this.number, required this.from, required this.to, required this.inBook});

  final String id;
  final int number;
  final int from;
  final int to;
  final bool inBook;

  String get line => 'p.$number · ${clockText(from)} – ${clockText(to)}';
}

/// A line of the Trial Log's record list, at the back of the book.
@immutable
class RecordLine {
  const RecordLine({required this.id, required this.text});

  final String id;
  final String text;
}

/// The record list after the case (its last step; the case closes with
/// it): page 3's line tapped, Saint-Sulpice lit on the map. Where the list
/// says page 3 was sent, no more.
@immutable
class RecordListLead {
  const RecordListLead({
    required this.title,
    required this.heading,
    required this.lines,
    required this.question,
    required this.answer,
    required this.otherLine,
    required this.mapFile,
    required this.mapPixels,
    required this.spot,
    required this.doneLines,
  });

  final String title;
  final String heading;
  final List<RecordLine> lines;
  final String question;
  final String answer;
  final String otherLine;
  final String mapFile;
  final ScenePixels mapPixels;
  final MapSpot spot;
  final List<String> doneLines;
}

/// The final: Photo 2 found on T1's tape (the sun's times laid under it),
/// page 3 found missing from the Trial Log, then the question
/// ([MissionType.multipleChoice]). The answer leaves the case open until
/// the record list is read ([lead]).
@immutable
class HourRecordScene {
  const HourRecordScene({
    required this.room,
    required this.tape,
    required this.photo1Mark,
    required this.photo2Mark,
    required this.photos,
    required this.tapeTask,
    required this.firstTwoThirty,
    required this.notTwoThirty,
    required this.foundLines,
    required this.backLabel,
    required this.rightLabel,
    required this.logFile,
    required this.logPixels,
    required this.leftPage,
    required this.rightPage,
    required this.emblem,
    required this.logTitle,
    required this.pages,
    required this.pageTask,
    required this.pageInBook,
    required this.pageFoundLine,
    required this.afterLines,
    required this.lead,
    required this.leadLabel,
  });

  final StarRoom room;
  final DrumTapeScene tape;

  /// Where Photo 1 is pinned already, and where Photo 2 belongs.
  final String photo1Mark;
  final String photo2Mark;
  final List<ShadowPhoto> photos;
  final String tapeTask;

  /// Said for the other 2:30, and for a mark that is not 2:30.
  final String firstTwoThirty;
  final String notTwoThirty;

  /// Said once the sun's times are laid under the tape.
  final List<String> foundLines;

  /// The small words over the two jumps, once the times are laid.
  final String backLabel;
  final String rightLabel;

  final String logFile;
  final ScenePixels logPixels;

  /// The book's two pages, and the empty circle on the left one (pixels).
  final Rect leftPage;
  final Rect rightPage;
  final Rect emblem;
  final String logTitle;
  final List<LogPage> pages;
  final String pageTask;
  final String pageInBook;
  final String pageFoundLine;

  /// Said under the solve, before the record list is read.
  final List<String> afterLines;
  final RecordListLead lead;
  final String leadLabel;

  /// Kept once Photo 2 is found on the tape, once page 3 is found missing,
  /// and once the record list is read (the case closes with it).
  static const photoId = 'photo2';
  static const pageId = 'page3';
  static const leadId = 'list';

  /// The page whose hour is [from] to [to], its absence the question.
  LogPage get missing => pages.firstWhere((p) => !p.inBook);

  List<LogPage> get inBook => [for (final p in pages) if (p.inBook) p];

  /// The real time at [mark], once Photo 2 is found: fifteen minutes a mark
  /// from Photo 1's.
  int realAt(String mark) => tape.mark(photo1Mark).real + 15 * (tape.indexOf(mark) - tape.indexOf(photo1Mark));
}

// ── The evidence, drawn ─────────────────────────────────────────────────

/// T1 Drum Tape: the tape, its two jumps marked; with [sun], the sun's
/// times laid under it (The Hour Was Recorded).
final class TapeCard implements DrawnEvidence {
  const TapeCard(this.scene, {this.record});

  final DrumTapeScene scene;
  final HourRecordScene? record;

  @override
  double get aspect => record == null ? 3.2 : 2.3;
}

/// Independent Time Log: Photo 2 with its clocks' hands.
final class PhotoLog implements DrawnEvidence {
  const PhotoLog(this.photo);

  final RoofPhoto photo;

  @override
  double get aspect => photo.pixels.aspect;
}

/// The Shadow Check: the sundial in the two photos, each with its shadow.
final class ShadowCard implements DrawnEvidence {
  const ShadowCard(this.scene);

  final ShadowCheckScene scene;

  @override
  double get aspect => 1.6;
}
