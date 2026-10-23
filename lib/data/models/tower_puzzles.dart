import 'dart:math' as math;
import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter/foundation.dart';

import 'scene_explore.dart' show ScenePixels;

/// The pictures Season 2's Case 03 is played on (the presentation of its
/// puzzles, never their answers): two records compared line by line, a lift
/// log read against its route plate, a padlock's three dials, and the
/// evidence linked to the case's questions in the hidden service room.
/// What is chosen there is checked as the mission's answer, through the
/// same check, feedback, save and rewards as any other answer. Every word
/// on a document is written by the app, on the picture's blank paper.

/// One line of a [RecordDoc] that can be picked: what it is ([label]) and
/// what it says ([value]).
@immutable
class RecordLine {
  const RecordLine({required this.id, required this.label, required this.value});

  /// The option it stands for (`notice:log` in the answer).
  final String id;
  final String label;
  final String value;
}

/// A sheet of paper as a picture shows it: its four corners (pixels of the
/// picture, clockwise from the top left: a sheet seen at a slant is no
/// rectangle), and its own size seen face on ([flat], in units of its own).
/// What is written on it is laid out face on in [flat]'s units, then put on
/// the sheet in the picture's perspective.
@immutable
class PaperQuad {
  const PaperQuad({
    required this.topLeft,
    required this.topRight,
    required this.bottomRight,
    required this.bottomLeft,
    required this.flat,
  });

  final Offset topLeft;
  final Offset topRight;
  final Offset bottomRight;
  final Offset bottomLeft;
  final Size flat;

  List<Offset> get corners => [topLeft, topRight, bottomRight, bottomLeft];

  /// The corners in fractions of [crop] (itself fractions of a picture
  /// [pixels] large).
  List<Offset> inCrop(Rect crop, ScenePixels pixels) => [
        for (final c in corners)
          Offset(
            (c.dx / pixels.width - crop.left) / crop.width,
            (c.dy / pixels.height - crop.top) / crop.height,
          ),
      ];
}

/// Where a record's words go on its sheet, face on (units of the sheet's
/// [PaperQuad.flat]): the [title] in its box; each line on its own row
/// ([rows]: each row's top, [rowHeight] tall), its label between
/// [labelLeft] and [labelRight], its value between [valueLeft] and
/// [valueRight]; the [note] on a row of its own ([noteRow], from [noteLeft]
/// — the values' column by default — to [valueRight]). A line is picked
/// anywhere within [reach] above or below its row (the rows between the
/// lines are left empty for it).
@immutable
class RecordLayout {
  const RecordLayout({
    required this.title,
    required this.rows,
    required this.rowHeight,
    required this.labelLeft,
    required this.labelRight,
    required this.valueLeft,
    required this.valueRight,
    this.noteRow,
    this.noteLeft,
    this.reach = 0,
    this.ink = 0.9,
  });

  final Rect title;
  final List<double> rows;
  final double rowHeight;
  final double labelLeft;
  final double labelRight;
  final double valueLeft;
  final double valueRight;
  final double? noteRow;
  final double? noteLeft;
  final double reach;

  /// The words' size, in rows (capitals only: no tails below the line).
  final double ink;
}

/// A record found at the place: its picture ([file], shown as [crop]), and
/// what is written on its blank paper ([sheet], laid out by [layout]): a
/// [title], the [lines] to compare and a last, unpicked [note].
@immutable
class RecordDoc {
  const RecordDoc({
    required this.id,
    required this.name,
    required this.file,
    required this.pixels,
    required this.crop,
    required this.sheet,
    required this.layout,
    required this.title,
    required this.lines,
    required this.label,
    this.note,
  });

  /// Saved as looked at under this id.
  final String id;

  /// Its name on the page ("THE VISITOR NOTICE").
  final String name;
  final String file;
  final ScenePixels pixels;

  /// The part of the picture shown (fractions).
  final Rect crop;

  /// The blank paper the words are written on, and where they go on it.
  final PaperQuad sheet;
  final RecordLayout layout;
  final String title;
  final List<RecordLine> lines;
  final String? note;

  /// What the picture shows, for screen readers.
  final String label;

  /// Width / height of the part shown.
  double get aspect => crop.width * pixels.width / (crop.height * pixels.height);

  /// The sheet's corners in fractions of the part shown.
  List<Offset> get sheetInCrop => sheet.inCrop(crop, pixels);
}

/// A ruled table on a sheet, face on (units of the sheet's
/// [PaperQuad.flat]): its title box ([titleBox]), the left edges of its
/// columns ([columns], the last one's right edge last), and the top of its
/// first row ([top]), [rows] rows of [rowHeight] each.
@immutable
class LedgerTable {
  const LedgerTable({
    required this.titleBox,
    required this.columns,
    required this.top,
    required this.rows,
    required this.rowHeight,
  });

  final Rect titleBox;
  final List<double> columns;
  final double top;
  final int rows;
  final double rowHeight;

  /// The cell of column [column], row [row] (from 0).
  Rect cell(int column, int row) =>
      Rect.fromLTRB(columns[column], top + row * rowHeight, columns[column + 1], top + (row + 1) * rowHeight);
}

/// Two records of the same job, compared ([MissionType.matchPairs] with
/// one pair): a line picked on each, the answer `noticeLine:logLine`.
@immutable
class RecordsScene {
  const RecordsScene({
    required this.first,
    required this.second,
    required this.readTask,
    required this.compareTask,
    required this.checkLabel,
  });

  final RecordDoc first;
  final RecordDoc second;

  /// What to do before both are read, and once they are.
  final String readTask;
  final String compareTask;

  /// The button that checks the two lines picked.
  final String checkLabel;

  List<RecordDoc> get docs => [first, second];
}

/// A stop on the lift's route plate ([LiftScene]): its stud on the plate
/// ([at], fractions of the plate's picture), its name lettered beside it.
@immutable
class LiftStop {
  const LiftStop({required this.id, required this.name, required this.at, this.service = false});

  final String id;
  final String name;
  final Offset at;

  /// On the service route only (never a passenger stop).
  final bool service;
}

/// One trip in the lift log: when, from where, to where (`?`: not
/// written), and whether it was a service run (marked S).
@immutable
class LiftTrip {
  const LiftTrip({required this.time, required this.from, required this.to, this.service = false});

  final String time;
  final String from;
  final String to;
  final bool service;
}

/// The lift ([MissionType.multipleChoice]): its picture, where its route
/// plate and its log hang, and the two looked at closer. The missing stop
/// is chosen once both are read.
@immutable
class LiftScene {
  const LiftScene({
    required this.picture,
    required this.pixels,
    required this.place,
    required this.plateArea,
    required this.logArea,
    required this.plate,
    required this.platePixels,
    required this.stops,
    required this.passengerRoute,
    required this.serviceRoute,
    required this.legend,
    required this.legendAt,
    required this.log,
    required this.logPixels,
    required this.logCrop,
    required this.logSheet,
    required this.logTable,
    required this.logHeadings,
    required this.logTitle,
    required this.trips,
    required this.readTask,
    required this.chooseTask,
  });

  final String picture;
  final ScenePixels pixels;

  /// The place, for screen readers.
  final String place;

  /// Where the plate and the log are on the lift's picture (fractions).
  final Rect plateArea;
  final Rect logArea;

  final String plate;
  final ScenePixels platePixels;
  final List<LiftStop> stops;

  /// The stops' ids along each route, in order (drawn as lines between
  /// their studs: the passenger route whole, the service run dashed).
  final List<String> passengerRoute;
  final List<String> serviceRoute;

  /// Lettered under the tower on the plate ("S = SERVICE RUN"), at
  /// [legendAt] (fractions of the plate's picture).
  final String legend;
  final Rect legendAt;

  final String log;
  final ScenePixels logPixels;

  /// The page shown (fractions of the log's picture): the written one.
  final Rect logCrop;

  /// The page's ruled table as the picture shows it ([logSheet]), and its
  /// title box, columns and rows face on ([logTable]): the title in its box,
  /// the column headings ([logHeadings]) on the first row, each trip on a
  /// row of its own after them.
  final PaperQuad logSheet;
  final LedgerTable logTable;
  final List<String> logHeadings;

  /// Width / height of the page shown.
  double get logAspect => logCrop.width * logPixels.width / (logCrop.height * logPixels.height);

  /// The table's corners in fractions of the page shown.
  List<Offset> get logSheetInCrop => logSheet.inCrop(logCrop, logPixels);
  final String logTitle;
  final List<LiftTrip> trips;

  final String readTask;
  final String chooseTask;

  LiftStop stop(String id) => stops.firstWhere((s) => s.id == id);

  /// The ids the plate and the log are saved as looked at under.
  static const plateId = 'plate';
  static const logId = 'log';
}

/// A symbol on a [DialLockScene]'s dial: the option it stands for, and
/// where it is on the dial (clockwise from the top, in degrees, measured on
/// the dial's picture).
@immutable
class DialSymbol {
  const DialSymbol({required this.id, required this.name, required this.angle, required this.closeUp, required this.outline});

  final String id;
  final String name;
  final double angle;

  /// The symbol alone on the dial's picture (pixels of the dial): the box
  /// round its [outline], shown upright and large under its dial once it
  /// is set.
  final Rect closeUp;

  /// The symbol's own shape on the dial (pixels of the dial): what of
  /// [closeUp] is shown, cut out along it (the dial round it, its hub, rim
  /// and spokes, never shown).
  final SymbolOutline outline;
}

/// A symbol's shape: [ovals] and a [polygon] together (pixels of the dial).
@immutable
class SymbolOutline {
  const SymbolOutline({this.ovals = const [], this.polygon = const []});

  final List<Rect> ovals;
  final List<Offset> polygon;
}

/// A padlock with three dials ([MissionType.sequence]): the lock's picture
/// with three round windows cut through it, and one dial's picture turned
/// behind each window about its own [pivot]. The symbol under the lock's
/// fixed pointer (at the top of a window) is the one set; the three, left
/// to right, are the answer.
@immutable
class DialLockScene {
  const DialLockScene({
    required this.lock,
    required this.pixels,
    required this.view,
    required this.windows,
    required this.windowRadius,
    required this.dial,
    required this.dialPixels,
    required this.pivot,
    required this.showRadius,
    required this.symbols,
    required this.start,
    required this.label,
    required this.task,
    required this.openLabel,
  });

  final String lock;
  final ScenePixels pixels;

  /// The part of the lock shown (pixels of [lock]): its dial panel.
  final Rect view;

  /// The windows' centres, left to right, and their radius (pixels of
  /// [lock], measured on its transparent holes).
  final List<Offset> windows;
  final double windowRadius;

  final String dial;
  final ScenePixels dialPixels;

  /// The dial's centre of turning (pixels of [dial]).
  final Offset pivot;

  /// How far from the [pivot] the dial shows through a window (pixels of
  /// [dial]): its symbols in, its rim and pointer under the lock's bezel.
  final double showRadius;

  /// The dial's symbols, clockwise from the top.
  final List<DialSymbol> symbols;

  /// The symbol each dial starts on (an index into [symbols]): never the
  /// answer, on any dial.
  final List<int> start;

  /// What the lock shows, for screen readers.
  final String label;

  final String task;
  final String openLabel;

  /// How much the dial's picture is scaled to fit a window.
  double get dialScale => windowRadius / showRadius;

  /// The turn (radians, clockwise) that brings symbol [index] under the
  /// pointer.
  double turnFor(int index) => -symbols[index].angle * math.pi / 180;

  /// The symbol nearest the pointer when the dial is turned [turn]
  /// (radians, clockwise).
  int symbolAt(double turn) {
    final top = (-turn * 180 / math.pi) % 360;
    var best = 0;
    var bestGap = double.infinity;
    for (var i = 0; i < symbols.length; i++) {
      final d = (symbols[i].angle - top).abs() % 360;
      final gap = math.min(d, 360 - d);
      if (gap < bestGap) {
        bestGap = gap;
        best = i;
      }
    }
    return best;
  }
}

/// A question of the final, answered with evidence.
@immutable
class BoardQuestion {
  const BoardQuestion({required this.id, required this.text});

  final String id;
  final String text;
}

/// A piece of evidence on the final's board: its short id in the answer
/// (`e1`), the case's evidence it is ([evidenceId]).
@immutable
class BoardEvidence {
  const BoardEvidence({required this.id, required this.evidenceId});

  final String id;
  final String evidenceId;
}

/// What the evidence says, to choose from once every question is linked.
@immutable
class BoardConclusion {
  const BoardConclusion({required this.id, required this.text});

  final String id;
  final String text;
}

/// A final's board of questions answered with evidence, then a conclusion
/// (Case 03's, with its machine; Case 08's). Its answer: each question's
/// evidence (`question:e1+e2`, the ids in [evidence]'s order), then the
/// conclusion chosen (`why:id`).
abstract interface class EvidenceBoardSpec {
  List<BoardQuestion> get questions;
  List<BoardEvidence> get evidence;
  String get conclusionId;
  String get conclusionQuestion;
  List<BoardConclusion> get conclusions;
  String get linkTask;
  String get concludeTask;
  String get solveLabel;
}

/// The answer of a board: each question's evidence (in its evidence's
/// order), then the conclusion.
String boardAnswerOf(EvidenceBoardSpec board, Map<String, Set<String>> links, String? conclusion) => [
      for (final q in board.questions)
        '${q.id}:${[for (final e in board.evidence) if (links[q.id]?.contains(e.id) ?? false) e.id].join('+')}',
      '${board.conclusionId}:${conclusion ?? ''}',
    ].join(',');

/// The final ([MissionType.matchPairs]): the evidence linked to each
/// question (`question:e1+e2`, the ids in [evidence]'s order), and the
/// conclusion chosen (`why:id`). Its stage: the time-recording machine,
/// shut and then open (two pictures in register), and the brass plaque
/// found inside, its message written by the app.
@immutable
class EvidenceBoardScene implements EvidenceBoardSpec {
  const EvidenceBoardScene({
    required this.shut,
    required this.open,
    required this.pixels,
    required this.machineLabel,
    required this.questions,
    required this.evidence,
    required this.conclusionId,
    required this.conclusionQuestion,
    required this.conclusions,
    required this.linkTask,
    required this.concludeTask,
    required this.solveLabel,
    required this.plaque,
    required this.plaquePixels,
    required this.plaqueWriteOn,
    required this.plaqueMessage,
    required this.riverAt,
    required this.riverWord,
    required this.plaqueLabel,
  });

  final String shut;
  final String open;
  final ScenePixels pixels;
  final String machineLabel;

  @override
  final List<BoardQuestion> questions;
  @override
  final List<BoardEvidence> evidence;

  /// The conclusion's part in the answer (`why`), its question and choices.
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

  final String plaque;
  final ScenePixels plaquePixels;

  /// Where the message is engraved (fractions of [plaque]), and the word
  /// under its waves ([riverAt], fractions of [plaque]).
  final Rect plaqueWriteOn;
  final String plaqueMessage;
  final Rect riverAt;
  final String riverWord;
  final String plaqueLabel;

  /// The plaque's message, once read, is saved under this id.
  static const plaqueId = 'plaque';

  /// The answer of a board: each question's evidence (in [evidence]'s
  /// order), then the conclusion.
  String answerOf(Map<String, Set<String>> links, String? conclusion) => boardAnswerOf(this, links, conclusion);
}

/// How far the detective has got on a Case 03 puzzle page: what is open
/// over it, and what is picked or set there. What must survive a restart
/// is saved by the page itself (`GameProgress.examined`, `puzzleStates`).
class TowerPuzzleProgress {
  /// A record's or the lift's plate/log id: open over the page.
  String? open;

  /// The records page: the record shown, and the line picked on each.
  int doc = 0;
  final Map<String, String> picked = {};

  /// The board: the question being linked.
  String? question;
}

/// The id a padlock's note is saved under once read (on the way to the
/// dials).
const noteId = 'note';

/// A board's links and conclusion as saved (`q1=e1;q2=e2;q3=e2+e3;why=c`),
/// and back. Unknown parts are dropped.
abstract final class BoardState {
  static String encode(Map<String, Set<String>> links, String? conclusion, EvidenceBoardSpec scene) => [
        for (final q in scene.questions)
          '${q.id}=${[for (final e in scene.evidence) if (links[q.id]?.contains(e.id) ?? false) e.id].join('+')}',
        if (conclusion != null) '${scene.conclusionId}=$conclusion',
      ].join(';');

  static (Map<String, Set<String>>, String?) decode(String? saved, EvidenceBoardSpec scene) {
    final links = <String, Set<String>>{};
    String? conclusion;
    final questions = {for (final q in scene.questions) q.id};
    final evidence = {for (final e in scene.evidence) e.id};
    final conclusions = {for (final c in scene.conclusions) c.id};
    for (final part in (saved ?? '').split(';')) {
      final [key, value] = switch (part.split('=')) {
        [final k, final v] => [k, v],
        _ => ['', ''],
      };
      if (questions.contains(key)) {
        links[key] = {for (final e in value.split('+')) if (evidence.contains(e)) e};
      } else if (key == scene.conclusionId && conclusions.contains(value)) {
        conclusion = value;
      }
    }
    return (links, conclusion);
  }
}

/// A dial lock's dials as saved (`2,0,1`: each dial's symbol index), and
/// back; anything else is the lock's start.
abstract final class DialState {
  static String encode(List<int> dials) => dials.join(',');

  static List<int> decode(String? saved, DialLockScene scene) {
    final parts = (saved ?? '').split(',');
    final read = [for (final p in parts) int.tryParse(p)];
    if (read.length != scene.windows.length || read.any((i) => i == null || i < 0 || i >= scene.symbols.length)) {
      return [...scene.start];
    }
    return [for (final i in read) i!];
  }
}
