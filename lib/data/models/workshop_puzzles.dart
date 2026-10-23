import 'dart:ui' show Offset, Rect;

import 'package:flutter/foundation.dart';

import 'river_puzzles.dart' show DrawnEvidence;
import 'scene_explore.dart' show ScenePixels;

/// Season 2, Case 05's puzzles (The Silent Workshop, No. 7 of the Passage
/// des Horlogers): the maker's mark compared under a tracing sheet, the
/// wall of clocks watched for a minute and their backs looked at, the
/// blotting paper read in a hand mirror, and the post's slips put in order.
/// Every picture is blank of words; what is written on it is written by the
/// app, at the places measured on it (`season2_case05_scenes.dart`).

// ── The maker's mark ─────────────────────────────────────────────────────

/// How a mark stamped on the workbench differs from the maker's own (the
/// two clock hands of `hands_sign.png`).
enum MarkCopy {
  /// The long hand's tip is another shape (its own picture).
  tip,

  /// The short hand sits closer to the long one.
  shifted,

  /// The short hand is missing.
  oneHand,

  /// The maker's own mark.
  exact,
}

/// The maker's mark ([file], at [pixels]) and its copies: [split] runs
/// between its two hands (pixels, left to right: the long hand above it,
/// the short one below), [shift] is how far the short hand is moved on a
/// [MarkCopy.shifted] copy; [tipFile] is the copy with another tip, laid
/// [tipShift] over so its hands sit where the maker's do.
@immutable
class MakerMark {
  const MakerMark({
    required this.file,
    required this.pixels,
    required this.split,
    required this.shift,
    required this.tipFile,
    required this.tipShift,
  });

  final String file;
  final ScenePixels pixels;
  final List<Offset> split;
  final Offset shift;
  final String tipFile;
  final Offset tipShift;
}

/// A thing on the workbench with a mark stamped on it: where it is on the
/// bench ([area]) and its round stamp ([seal]), both fractions of the bench
/// picture.
@immutable
class BenchSeal {
  const BenchSeal({required this.id, required this.name, required this.thing, required this.area, required this.seal, required this.copy});

  final String id;

  /// Its name on the page ('A · THE TOOLBOX').
  final String name;

  /// What it is, in words ('the toolbox').
  final String thing;
  final Rect area;
  final Rect seal;
  final MarkCopy copy;
}

/// A card or slip of paper written by the app: its picture, the place its
/// lines are written ([writeOn], pixels) and, when it is signed, the
/// maker's mark at [markAt] (pixels).
@immutable
class WrittenPaper implements DrawnEvidence {
  const WrittenPaper({
    required this.file,
    required this.pixels,
    required this.writeOn,
    required this.lines,
    required this.label,
    this.markAt,
    this.signedWith,
    this.size = 44,
    this.tag,
    this.tagAt,
  });

  final String file;
  final ScenePixels pixels;
  final Rect writeOn;
  final List<String> lines;

  /// What the paper is, for screen readers (the lines are added).
  final String label;
  final Rect? markAt;

  /// The mark it is signed with at [markAt] (the maker's own).
  final MakerMark? signedWith;

  /// The lines' size, in picture pixels.
  final double size;

  /// A second, short thing written on it ([tag], at [tagAt], pixels): the
  /// number on the envelope's sticker.
  final String? tag;
  final Rect? tagAt;

  @override
  double get aspect => pixels.aspect;
}

/// M1 ([MarkCompareScene]): the workbench with four stamped things, the
/// tracing sheet with the maker's mark on it ([sheetMarkAt], pixels of the
/// sheet), and the card found in the drawer once the mark is right.
@immutable
class MarkCompareScene {
  const MarkCompareScene({
    required this.bench,
    required this.pixels,
    required this.place,
    required this.seals,
    required this.mark,
    required this.sheet,
    required this.sheetPixels,
    required this.sheetMarkAt,
    required this.note,
    required this.card,
    required this.readTask,
    required this.chooseTask,
    required this.chooseLabel,
    required this.sheetLabel,
  });

  final String bench;
  final ScenePixels pixels;
  final String place;
  final List<BenchSeal> seals;
  final MakerMark mark;
  final String sheet;
  final ScenePixels sheetPixels;
  final Rect sheetMarkAt;

  /// The maker's note on the bench.
  final String note;
  final WrittenPaper card;
  final String readTask;
  final String chooseTask;
  final String chooseLabel;

  /// What the tracing sheet is, on its button.
  final String sheetLabel;

  /// Where the sheet counts as laid over a stamp (examined key part).
  static String sheetKey(String sealId) => 'sheet-$sealId';

  BenchSeal seal(String id) => seals.firstWhere((s) => s.id == id);
}

// ── The wall of clocks ───────────────────────────────────────────────────

/// A clock on the wall: its dial's centre and radius (pixels of the wall),
/// where it hangs ([area], fractions) and its blank plate ([plateAt],
/// fractions); the time it shows (minutes past 12) and how many minutes it
/// moves in one minute; its back, and what is changed there.
@immutable
class WallClock {
  const WallClock({
    required this.id,
    required this.numeral,
    required this.centre,
    required this.radius,
    required this.area,
    required this.plateAt,
    required this.shows,
    required this.change,
    required this.back,
    required this.backLabel,
    required this.backNote,
  });

  final String id;
  final String numeral;
  final Offset centre;
  final double radius;
  final Rect area;
  final Rect plateAt;
  final int shows;
  final int change;
  final String back;

  /// What its back shows, for screen readers.
  final String backLabel;

  /// What the detective notes about its back, in words.
  final String backNote;

  /// The time it shows after one minute.
  int get after => (shows + change) % 720;

  String get name => 'CLOCK $numeral';
}

/// M2 ([ClockWallScene]): the wall, its four clocks (their hands drawn by
/// the app), one minute watched in [watch], and each clock's back.
@immutable
class ClockWallScene {
  const ClockWallScene({
    required this.wall,
    required this.pixels,
    required this.place,
    required this.view,
    required this.clocks,
    required this.backPixels,
    required this.watch,
    required this.watchLabel,
    required this.againLabel,
    required this.later,
    required this.watchTask,
    required this.backTask,
    required this.chooseTask,
    required this.chooseLabel,
  });

  final String wall;
  final ScenePixels pixels;
  final String place;

  /// The part of the wall shown (fractions): the four clocks.
  final Rect view;
  final List<WallClock> clocks;
  final ScenePixels backPixels;

  /// One minute of the clocks, played this long.
  final Duration watch;
  final String watchLabel;
  final String againLabel;
  final String later;
  final String watchTask;
  final String backTask;
  final String chooseTask;
  final String chooseLabel;

  /// Where one minute counts as watched (examined key part).
  static const watchedId = 'watched';

  static String backKey(String clockId) => 'back-$clockId';

  WallClock clock(String id) => clocks.firstWhere((c) => c.id == id);
}

/// A time of a clock (minutes past 12) as it is read: 3:10.
String clockTime(int minutes) {
  final m = minutes % 720;
  final h = m ~/ 60;
  return '${h == 0 ? 12 : h}:${(m % 60).toString().padLeft(2, '0')}';
}

// ── The blotting paper ───────────────────────────────────────────────────

/// The ink a note on the blotter was written in.
enum NoteInk { blue, black, brown }

/// A note blotted on the blotter, backwards: its ink, its lines, where it
/// is ([at], pixels of the desk) and the mark it is signed with (none, a
/// copy, or the maker's own).
@immutable
class BlotNote {
  const BlotNote({required this.id, required this.ink, required this.lines, required this.at, required this.mark});

  final String id;
  final NoteInk ink;
  final List<String> lines;
  final Rect at;

  /// Null: not signed.
  final MarkCopy? mark;

  String get name => '${ink.name.toUpperCase()} INK';
}

/// M3 ([BlotterScene]): the desk and its blotter, the three notes blotted
/// on it, the hand mirror ([glassCentre] and [glassRadius], pixels of the
/// mirror) that shows them the right way round, and what is in Clock III
/// once the right place is found.
@immutable
class BlotterScene {
  const BlotterScene({
    required this.desk,
    required this.pixels,
    required this.place,
    required this.blotter,
    required this.notes,
    required this.mirror,
    required this.mirrorPixels,
    required this.glassCentre,
    required this.glassRadius,
    required this.glassOnDesk,
    required this.mark,
    required this.readTask,
    required this.chooseTask,
    required this.chooseLabel,
    required this.hideaway,
    required this.receipt,
    required this.hideawayBack,
    required this.hideawayLines,
  });

  final String desk;
  final ScenePixels pixels;
  final String place;

  /// The blotting paper (pixels of the desk).
  final Rect blotter;
  final List<BlotNote> notes;
  final String mirror;
  final ScenePixels mirrorPixels;
  final Offset glassCentre;
  final double glassRadius;

  /// The glass's radius on the desk (pixels of the desk).
  final double glassOnDesk;
  final MakerMark mark;
  final String readTask;
  final String chooseTask;
  final String chooseLabel;

  /// Inside Clock III: the torn envelope corner and its receipt.
  final WrittenPaper hideaway;

  /// The receipt's lines alone, large.
  final List<String> receipt;
  final String hideawayBack;
  final List<String> hideawayLines;

  static String noteKey(String id) => 'note-$id';

  /// Where Clock III counts as opened and its receipt read.
  static const openedId = 'opened';
}

// ── The post's slips ─────────────────────────────────────────────────────

/// A slip the post leaves each time a letter moves: the letter's number,
/// when and what happened, and where.
@immutable
class PostSlip {
  const PostSlip({required this.id, required this.letter, required this.date, required this.time, required this.record, required this.where});

  final String id;
  final String letter;
  final String date;

  /// Null: no time on it.
  final String? time;
  final String record;
  final String where;

  List<String> get lines => ['LETTER No. $letter', time == null ? date : '$date · $time', record, where];
}

/// The final ([PostTrailScene]): the slips under the workshop door, the
/// receipt from Clock III to start from, and the trail of three places they
/// are set in.
@immutable
class PostTrailScene {
  const PostTrailScene({
    required this.slip,
    required this.slipPixels,
    required this.slipWriteOn,
    required this.slips,
    required this.slots,
    required this.slotLabels,
    required this.receipt,
    required this.stage,
    required this.stagePixels,
    required this.stageView,
    required this.stageLabel,
    required this.pickTask,
    required this.placeTask,
    required this.submitLabel,
  });

  final String slip;
  final ScenePixels slipPixels;
  final Rect slipWriteOn;
  final List<PostSlip> slips;
  final List<String> slots;
  final List<String> slotLabels;
  final WrittenPaper receipt;
  final String stage;
  final ScenePixels stagePixels;
  final Rect stageView;
  final String stageLabel;
  final String pickTask;
  final String placeTask;
  final String submitLabel;

  /// Where the slips under the door count as looked at.
  static const slipsId = 'slips';

  PostSlip slipOf(String id) => slips.firstWhere((s) => s.id == id);

  /// A slip drawn on the slip picture.
  WrittenPaper paperOf(PostSlip s) =>
      WrittenPaper(file: slip, pixels: slipPixels, writeOn: slipWriteOn, lines: s.lines, label: 'A post slip', size: 70);

  /// A slip small among the others: its letter number and what happened,
  /// large enough to read at a glance (the rest is read on [paperOf]).
  WrittenPaper cardOf(PostSlip s) =>
      WrittenPaper(file: slip, pixels: slipPixels, writeOn: slipWriteOn, lines: ['No. ${s.letter}', s.record], label: 'A post slip', size: 150);

  /// The answer the trail gives: `slot:slip` for each slot filled.
  String answerOf(Map<String, String> placed) => [for (final s in slots) if (placed[s] case final id?) '$s:$id'].join(',');
}

/// The trail as saved: `first=s1;second=s2` (unknown slots and slips, and a
/// slip set twice, are left out).
abstract final class TrailState {
  static String encode(Map<String, String> placed, PostTrailScene scene) => [for (final s in scene.slots) if (placed[s] case final id?) '$s=$id'].join(';');

  static Map<String, String> decode(String? saved, PostTrailScene scene) {
    final out = <String, String>{};
    for (final part in (saved ?? '').split(';')) {
      final [slot, id, ...] = [...part.split('='), '', ''];
      if (!scene.slots.contains(slot) || !scene.slips.any((s) => s.id == id) || out.containsValue(id) || out.containsKey(slot)) continue;
      out[slot] = id;
    }
    return out;
  }
}

/// Case 05's evidence drawn: a written paper, or a picture alone — the
/// whole of it, or the part of it ([crop], fractions) the detective found it
/// in (Case 02's sketch, as the easel showed it).
@immutable
class PictureEvidence implements DrawnEvidence {
  const PictureEvidence({required this.file, required this.pixels, this.crop});

  final String file;
  final ScenePixels pixels;
  final Rect? crop;

  @override
  double get aspect => switch (crop) {
    final c? => c.width * pixels.width / (c.height * pixels.height),
    null => pixels.aspect,
  };
}
