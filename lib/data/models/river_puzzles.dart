import 'dart:ui' show Rect;

import 'package:flutter/foundation.dart';

import 'scene_explore.dart' show ScenePixels;
import 'tower_puzzles.dart' show BoardEvidence, EvidenceBoardScene;

/// The pictures Season 2's Case 04 is played on (the presentation of its
/// puzzles, never their answers): four marks carved in a quay wall, the
/// river keeper's hut and ledger, a torn delivery label put back together,
/// and a street book whose wrong addresses are crossed out with evidence.
/// What is chosen there is checked as the mission's answer, through the
/// same check, feedback, save and rewards as any other answer. Every word
/// on a paper, a stone or a sign is written by the app, on blank pictures.

/// The back of Case 03's brass plaque: its blank brass ([file]), and the
/// three lines scratched on it ([lines], written by the app at [writeOn],
/// fractions of the picture).
@immutable
class PlaqueBack {
  const PlaqueBack({required this.file, required this.pixels, required this.writeOn, required this.lines, required this.label});

  final String file;
  final ScenePixels pixels;
  final Rect writeOn;
  final List<String> lines;

  /// What the brass shows, for screen readers (the lines are added).
  final String label;
}

/// A picture shown under a case's opening lines, from line [afterLine] on
/// (its index): Case 04's plaque turned over.
@immutable
class IntroPlaque {
  const IntroPlaque({required this.afterLine, required this.plaque});

  final int afterLine;
  final PlaqueBack plaque;
}

/// A mark carved in the quay wall ([RiverMarksScene]): where it is on the
/// wall ([area]) and where its word is carved there ([wordAt]), both
/// fractions of the wall; its close-up picture and the word's place on it
/// ([closeWordAt], fractions of the close-up). The waves and the arrow are
/// in the pictures; the word is written by the app.
@immutable
class RiverMark {
  const RiverMark({
    required this.id,
    required this.name,
    required this.area,
    required this.wordAt,
    required this.closeUp,
    required this.closeWordAt,
    required this.word,
    required this.waves,
    required this.arrowDown,
  });

  /// The option it stands for.
  final String id;

  /// "MARK A".
  final String name;
  final Rect area;
  final Rect wordAt;
  final String closeUp;
  final Rect closeWordAt;
  final String word;

  /// What the pictures show (measured on them; read to screen readers, and
  /// checked against the answer by the tests): the number of waves, and
  /// whether the arrow points down, towards the river.
  final int waves;
  final bool arrowDown;

  String get spoken => '$name: $waves waves, an arrow pointing ${arrowDown ? 'down' : 'up'}, and the word $word';
}

/// The quay wall ([MissionType.multipleChoice]): four marks, each looked at
/// closer, the plaque's two sides to read again, and the mark chosen.
@immutable
class RiverMarksScene {
  const RiverMarksScene({
    required this.wall,
    required this.pixels,
    required this.place,
    required this.marks,
    required this.closePixels,
    required this.signAt,
    required this.sign,
    required this.plaqueFront,
    required this.plaqueBack,
    required this.readTask,
    required this.chooseTask,
    required this.chooseLabel,
  });

  final String wall;
  final ScenePixels pixels;
  final String place;
  final List<RiverMark> marks;
  final ScenePixels closePixels;

  /// The small enamel sign on the wall, and what it says (QUAY 3).
  final Rect signAt;
  final String sign;

  /// Case 03's plaque, front (its message and SEINE) and back.
  final EvidenceBoardScene plaqueFront;
  final PlaqueBack plaqueBack;

  final String readTask;
  final String chooseTask;
  final String chooseLabel;

  RiverMark mark(String id) => marks.firstWhere((m) => m.id == id);

  /// The plaque's back, once read, is saved under this id; each mark under
  /// its own.
  static const backId = 'back';
}

/// A part of a ledger line: plain words, or a box number that can be
/// circled ([box]: the option it stands for).
@immutable
class LedgerPart {
  const LedgerPart(this.text, {this.box});

  final String text;
  final String? box;
}

/// One line of the river keeper's ledger: its date, its words (box numbers
/// among them), and who signed it: initials, or the two clock hands
/// ([hands]).
@immutable
class LedgerEntry {
  const LedgerEntry({required this.date, required this.parts, this.initials, this.hands = false});

  final String date;
  final List<LedgerPart> parts;
  final String? initials;
  final bool hands;

  String get words => parts.map((p) => p.text).join();

  String get spoken => '$date. $words ${hands ? 'Signed with two clock hands.' : 'Signed ${initials ?? ''}.'}';

  Iterable<String> get boxes => [for (final p in parts) ?p.box];
}

/// One page of the ledger: its heading, the part of the ledger's picture
/// shown ([crop]) and where the lines are written ([writeOn]), fractions of
/// the whole picture.
@immutable
class LedgerPage {
  const LedgerPage({required this.title, required this.crop, required this.writeOn, required this.entries});

  final String title;
  final Rect crop;
  final Rect writeOn;
  final List<LedgerEntry> entries;

  /// [writeOn] in fractions of the part shown.
  Rect get writeInCrop => Rect.fromLTRB(
        (writeOn.left - crop.left) / crop.width,
        (writeOn.top - crop.top) / crop.height,
        (writeOn.right - crop.left) / crop.width,
        (writeOn.bottom - crop.top) / crop.height,
      );
}

/// Where the detective is at the keeper's hut: outside it, inside it, at
/// the ledger.
enum HutStep { outside, inside, ledger }

/// The river keeper's hut ([MissionType.multipleChoice]): its door tapped
/// outside, the ledger tapped on the desk inside, then the ledger's first
/// page read and a box number circled. Its second page opens only once the
/// box is right.
@immutable
class KeeperHutScene {
  const KeeperHutScene({
    required this.outside,
    required this.outsideLabel,
    required this.doorArea,
    required this.inside,
    required this.insideLabel,
    required this.ledgerArea,
    required this.pixels,
    required this.ledger,
    required this.ledgerPixels,
    required this.ledgerLabel,
    required this.pages,
    required this.hands,
    required this.doorTask,
    required this.ledgerTask,
    required this.circleTask,
    required this.checkLabel,
    required this.solvedLine,
    required this.turnLabel,
    required this.findTask,
    required this.foundLine,
    required this.findBox,
  });

  final String outside;
  final String outsideLabel;
  final Rect doorArea;
  final String inside;
  final String insideLabel;
  final Rect ledgerArea;

  /// The hut's two pictures (outside and inside) share their size.
  final ScenePixels pixels;
  final String ledger;
  final ScenePixels ledgerPixels;
  final String ledgerLabel;

  /// The first page (read before the answer) and the second (after it).
  final List<LedgerPage> pages;

  /// The two clock hands a line is signed with.
  final String hands;

  final String doorTask;
  final String ledgerTask;
  final String circleTask;
  final String checkLabel;

  /// Said once the box is right, over TURN THE PAGE.
  final String solvedLine;
  final String turnLabel;

  /// The second page: what to find on it, said once found, and the box.
  final String findTask;
  final String foundLine;
  final String findBox;

  /// The ledger, once opened, and its second page, once its line is found
  /// (and the story goes on), are saved under these ids.
  static const ledgerId = 'ledger';
  static const page2Id = 'page2';
}

/// How far the detective got at the hut and the box circled
/// (`at=ledger;box=box17`), and back; anything unknown is the start.
abstract final class HutState {
  static String encode(HutStep at, String? box) => ['at=${at.name}', if (box != null) 'box=$box'].join(';');

  static (HutStep, String?) decode(String? saved, KeeperHutScene scene) {
    var at = HutStep.outside;
    String? box;
    final boxes = {for (final p in scene.pages.first.entries) ...p.boxes};
    for (final part in (saved ?? '').split(';')) {
      final [key, value] = switch (part.split('=')) {
        [final k, final v] => [k, v],
        _ => ['', ''],
      };
      if (key == 'at') at = HutStep.values.firstWhere((s) => s.name == value, orElse: () => HutStep.outside);
      if (key == 'box' && boxes.contains(value)) box = value;
    }
    return (at, box);
  }
}

/// A green box on the quay ([BoxesScene]): its number, where it stands
/// ([area]) and where its number plate is ([plateAt]), fractions of the
/// picture; what is found when it is tried ([note]; null: the box opens).
@immutable
class QuayBox {
  const QuayBox({required this.id, required this.number, required this.area, required this.plateAt, this.note});

  final String id;
  final String number;
  final Rect area;
  final Rect plateAt;
  final String? note;
}

/// A line printed on the delivery label: its words, the piece it is on,
/// where it starts ([left], [top], label pixels), its size, and how it is
/// printed.
@immutable
class LabelLine {
  const LabelLine({
    required this.piece,
    required this.text,
    required this.left,
    required this.top,
    required this.size,
    this.centred = false,
    this.stamp = false,
    this.faint = false,
  });

  final String piece;
  final String text;
  final double left;
  final double top;
  final double size;

  /// Centred on the label (the header), not from [left].
  final bool centred;

  /// Stamped in red ink in a box (HANDLE WITH CARE).
  final bool stamp;

  /// A little paler (the line under FROM).
  final bool faint;
}

/// The delivery label torn into pieces ([BoxesScene], the final's gate):
/// one blank picture ([file]) and its back ([back]), cut by the app along
/// three tears: the first two across it ([tear1], [tear2]: their height,
/// label pixels), the third ([tear3]) across its lower right corner, where
/// the address goes on: that corner ([lastPiece]) is torn off and found
/// only at the gate. The address line is split there ([addressStart],
/// [addressRest]); the number before it is washed away by the picture's
/// stain ([numberAt]).
@immutable
class DeliveryLabel {
  const DeliveryLabel({
    required this.file,
    required this.back,
    required this.pixels,
    required this.lines,
    required this.tear1,
    required this.tear2,
    required this.tear3,
    required this.paperLeft,
    required this.paperRight,
    required this.paperBottom,
    required this.numberLabel,
    required this.numberAt,
    required this.addressLeft,
    required this.addressTop,
    required this.addressSize,
    required this.addressStart,
    required this.addressRest,
    required this.stampAt,
    required this.hands,
    required this.backLines,
    required this.backAt,
  });

  final String file;
  final String back;
  final ScenePixels pixels;
  final List<LabelLine> lines;
  final double tear1;
  final double tear2;
  final double tear3;

  /// Where the paper is across the tears and down to (label pixels,
  /// measured on its transparency): the tears' frayed edge is drawn there
  /// only.
  final double paperLeft;
  final double paperRight;
  final double paperBottom;

  /// "No." and where its number was (label pixels: left, top, size).
  final String numberLabel;
  final Rect numberAt;

  /// The address line: where it starts, its size, and its two parts.
  final double addressLeft;
  final double addressTop;
  final double addressSize;
  final String addressStart;
  final String addressRest;

  /// The two clock hands stamped on the middle piece ([hands]: their
  /// picture), and where (label pixels).
  final Rect stampAt;
  final String hands;

  /// The last piece's back: its message and where it is written (pixels
  /// of the back, which is the front turned over).
  final List<String> backLines;
  final Rect backAt;

  static const top = 'p1';
  static const middle = 'p2';
  static const bottom = 'p3';
  static const last = 'p5';

  /// The pieces found in the box, in label order.
  static const boxPieces = [top, middle, bottom];
}

/// The green boxes on the quay, then the open one and the torn label in it
/// ([MissionType.matchPairs]: each piece set in a slot, `piece:slot`).
@immutable
class BoxesScene {
  const BoxesScene({
    required this.picture,
    required this.pixels,
    required this.place,
    required this.view,
    required this.boxes,
    required this.open,
    required this.openPixels,
    required this.openLabel,
    required this.decoy,
    required this.decoyPixels,
    required this.decoyAt,
    required this.decoyLines,
    required this.label,
    required this.slots,
    required this.boxTask,
    required this.labelTask,
    required this.checkLabel,
  });

  final String picture;
  final ScenePixels pixels;
  final String place;

  /// The part of the quay shown (fractions of [picture]): the four boxes.
  final Rect view;
  final List<QuayBox> boxes;
  final String open;
  final ScenePixels openPixels;
  final String openLabel;

  /// The scrap that is not the label's: its picture, where its words go
  /// (fractions of it), and its words.
  final String decoy;
  final ScenePixels decoyPixels;
  final Rect decoyAt;
  final List<String> decoyLines;
  final DeliveryLabel label;

  /// The frame's slots, top to bottom (`top`, `middle`, `bottom`).
  final List<String> slots;
  final String boxTask;
  final String labelTask;
  final String checkLabel;

  QuayBox box(String id) => boxes.firstWhere((b) => b.id == id);

  /// The box that opens (the one with no note).
  QuayBox get right => boxes.firstWhere((b) => b.note == null);

  static const decoyId = 'decoy';

  /// The id a box is saved under once opened or tried.
  static String boxKey(String id) => id;

  /// The answer of the frame: each piece set, by its slot (in the slots'
  /// order).
  String answerOf(Map<String, String> placed) => [
        for (final s in slots)
          if (placed[s] case final p?) '$p:$s',
      ].join(',');
}

/// What is set in each slot of the label's frame (`top=p1;middle=decoy`),
/// and back. Unknown parts, and a piece set twice, are dropped.
abstract final class LabelState {
  static String encode(Map<String, String> placed, BoxesScene scene) => [
        for (final s in scene.slots)
          if (placed[s] case final p?) '$s=$p',
      ].join(';');

  static Map<String, String> decode(String? saved, BoxesScene scene) {
    final placed = <String, String>{};
    final pieces = {...DeliveryLabel.boxPieces, BoxesScene.decoyId};
    for (final part in (saved ?? '').split(';')) {
      final [slot, piece] = switch (part.split('=')) {
        [final k, final v] => [k, v],
        _ => ['', ''],
      };
      if (scene.slots.contains(slot) && pieces.contains(piece) && !placed.containsValue(piece)) placed[slot] = piece;
    }
    return placed;
  }
}

/// An address in the street book ([StreetBookScene]): its name and lines,
/// and the page it is on (0: left, 1: right).
@immutable
class StreetEntry {
  const StreetEntry({required this.id, required this.name, required this.lines, required this.page});

  final String id;
  final String name;
  final List<String> lines;
  final int page;
}

/// The final ([MissionType.matchPairs]): the street book's addresses, each
/// wrong one crossed out with the evidence that rules it out
/// (`address:e1+e2`, up to [maxEvidence] pieces, in [evidence]'s order).
/// The one left is the address. Then the gate there, its sign written by
/// the app, and the label's last piece caught in it.
@immutable
class StreetBookScene {
  const StreetBookScene({
    required this.book,
    required this.bookPixels,
    required this.pages,
    required this.entries,
    required this.evidence,
    required this.maxEvidence,
    required this.hut,
    required this.hutLabel,
    required this.hutPixels,
    required this.pickTask,
    required this.evidenceTask,
    required this.crossLabel,
    required this.addressTask,
    required this.submitLabel,
    required this.gate,
    required this.gatePixels,
    required this.gateLabel,
    required this.gateView,
    required this.signAt,
    required this.signLines,
    required this.scrapAt,
    required this.label,
    required this.hands,
  });

  final String book;
  final ScenePixels bookPixels;

  /// Where each page's addresses are written (fractions of [book]).
  final List<Rect> pages;
  final List<StreetEntry> entries;
  final List<BoardEvidence> evidence;
  final int maxEvidence;

  /// The stage before the solve: the keeper's hut, where the book is.
  final String hut;
  final String hutLabel;
  final ScenePixels hutPixels;

  final String pickTask;
  final String evidenceTask;
  final String crossLabel;
  final String addressTask;
  final String submitLabel;

  /// The gate of the address, found after the solve: its picture, the part
  /// on the stage ([gateView], fractions), its sign ([signAt], fractions;
  /// [signLines]) and where the last piece is caught ([scrapAt]).
  final String gate;
  final ScenePixels gatePixels;
  final String gateLabel;
  final Rect gateView;
  final Rect signAt;
  final List<String> signLines;
  final Rect scrapAt;
  final DeliveryLabel label;
  final String hands;

  StreetEntry entry(String id) => entries.firstWhere((e) => e.id == id);

  /// Once the gate's scrap is taken and turned over, saved under this id.
  static const gateId = 'gate';

  /// The answer: each address crossed out, with its evidence (in
  /// [evidence]'s order), in the book's order.
  String answerOf(Map<String, Set<String>> crossed) => [
        for (final e in entries)
          if (crossed[e.id] case final ev? when ev.isNotEmpty) partOf(e.id, ev),
      ].join(',');

  /// One address crossed out with [evidence] (`pont:e1+e2`).
  String partOf(String entry, Set<String> evidence) =>
      '$entry:${[for (final e in this.evidence) if (evidence.contains(e.id)) e.id].join('+')}';
}

/// What a piece of Case 04's evidence shows, drawn with its words (its
/// stones and papers are blank pictures).
@immutable
sealed class RiverEvidenceArt {
  const RiverEvidenceArt();

  /// Width / height of what is shown.
  double get aspect;
}

/// A mark of the quay wall up close, its word carved on it.
final class MarkEvidenceArt extends RiverEvidenceArt {
  const MarkEvidenceArt(this.scene, this.mark);

  final RiverMarksScene scene;
  final String mark;

  @override
  double get aspect => scene.closePixels.aspect;
}

/// A page of the keeper's ledger ([page]: its index), its lines written.
final class LedgerEvidenceArt extends RiverEvidenceArt {
  const LedgerEvidenceArt(this.scene, this.page);

  final KeeperHutScene scene;
  final int page;

  @override
  double get aspect {
    final crop = scene.pages[page].crop;
    return crop.width * scene.ledgerPixels.width / (crop.height * scene.ledgerPixels.height);
  }
}

/// The delivery label as put back together: its three pieces from the box,
/// or ([last]) its lower part with the last piece in place.
final class LabelEvidenceArt extends RiverEvidenceArt {
  const LabelEvidenceArt(this.label, {required this.last});

  final DeliveryLabel label;
  final bool last;

  /// The part of the label shown with the last piece (label pixels): the
  /// lower piece and the corner.
  Rect get lowerPart => Rect.fromLTRB(0, label.tear2 - 30, label.pixels.width, label.pixels.height);

  @override
  double get aspect => last ? lowerPart.width / lowerPart.height : label.pixels.aspect;
}

/// The addresses crossed out and their evidence (`quai=e3;pont=e1+e2`), and
/// back. Unknown parts are dropped.
abstract final class CrossOutState {
  static String encode(Map<String, Set<String>> crossed, StreetBookScene scene) => [
        for (final e in scene.entries)
          if (crossed[e.id] case final ev? when ev.isNotEmpty)
            '${e.id}=${[for (final b in scene.evidence) if (ev.contains(b.id)) b.id].join('+')}',
      ].join(';');

  static Map<String, Set<String>> decode(String? saved, StreetBookScene scene) {
    final crossed = <String, Set<String>>{};
    final entries = {for (final e in scene.entries) e.id};
    final evidence = {for (final e in scene.evidence) e.id};
    for (final part in (saved ?? '').split(';')) {
      final [key, value] = switch (part.split('=')) {
        [final k, final v] => [k, v],
        _ => ['', ''],
      };
      if (!entries.contains(key)) continue;
      final ev = {for (final e in value.split('+')) if (evidence.contains(e)) e};
      if (ev.isNotEmpty && ev.length <= scene.maxEvidence) crossed[key] = ev;
    }
    return crossed;
  }
}
