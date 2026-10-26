import 'dart:ui' show Offset, Rect;

import 'package:flutter/foundation.dart';

import 'river_puzzles.dart' show DrawnEvidence;
import 'scene_explore.dart' show ScenePixels;

/// Season 2, Cases 11–12: puzzles played one small step at a time, made for
/// a child playing alone (`docs/SEASON2_CASE11_SPEC.md`, the very-easy
/// rules of 2026-10-27). Every step asks for one thing, said in a few words
/// at the top ("Tap the big book."); what it needs is on the same screen
/// (never a notebook to search, never a memory test); a choice has two
/// answers; a wrong answer costs nothing (the first time the place to look
/// is lit, the second time the answer is said); a hint is free at any time,
/// as often as wanted, and its last level lights the answer. The puzzle's
/// answer is the mission's ([EasyStepsScene.answer]), sent once the last
/// step is done; the step reached is saved (`step=n`).

/// A picture of the case: its file at its size in pixels, and the part of it
/// shown ([crop], in its pixels; all of it by default).
@immutable
class EasyPicture {
  const EasyPicture({required this.file, required this.pixels, required this.label, this.crop});

  final String file;
  final ScenePixels pixels;

  /// What it shows, for screen readers.
  final String label;
  final Rect? crop;

  /// The part shown, in the picture's pixels.
  Rect get view => crop ?? Rect.fromLTWH(0, 0, pixels.width, pixels.height);

  double get aspect => view.width / view.height;
}

/// How words are written on a picture by the app (the pictures carry no
/// words of their own).
enum EasyInk {
  /// A pen's dark ink, handwritten.
  pen,

  /// Typed, on a neat new paper.
  typed,

  /// A pencil rubbing: grey graphite.
  graphite,

  /// Engraved in brass.
  brass,
}

/// Words written on a picture at [at] (the picture's pixels), [size] pixels
/// high; [strong]: underlined in red, the line that matters.
@immutable
class EasyWriting {
  const EasyWriting(this.text, {required this.at, this.size = 48, this.ink = EasyInk.pen, this.strong = false});

  final String text;
  final Rect at;
  final double size;
  final EasyInk ink;
  final bool strong;
}

/// Another picture laid on a picture at [at] (its pixels): a stamp in its
/// circle, a signature on its line. [graphite]: drawn as a pencil rubbing
/// (grey, a little faint), not in its own ink.
@immutable
class EasyLayer {
  const EasyLayer({required this.file, required this.at, this.opacity = 1, this.graphite = false, this.turns = 0});

  final String file;
  final Rect at;
  final double opacity;
  final bool graphite;

  /// Turned by this much (a stamp pressed a little askew).
  final double turns;
}

/// A place on a panel ([area], the panel's pixels; null: all of it).
@immutable
class EasyMark {
  const EasyMark(this.panel, [this.area]);

  final String panel;
  final Rect? area;
}

/// What a step shows. Panels keep their [id] from step to step: the same
/// panel in the next step changes in place (a wheel turns, a lid opens).
@immutable
sealed class EasyPanel {
  const EasyPanel({required this.id, this.caption});

  final String id;

  /// A few words under it ("Clock III's wheel").
  final String? caption;

  /// Width / height of what is shown (an evidence panel: its own).
  double get aspect;
}

/// A picture of the case, with the app's words and pictures laid on it.
final class PicturePanel extends EasyPanel {
  const PicturePanel({
    required super.id,
    required this.picture,
    this.writing = const [],
    this.layers = const [],
    super.caption,
  });

  final EasyPicture picture;
  final List<EasyWriting> writing;
  final List<EasyLayer> layers;

  @override
  double get aspect => picture.aspect;
}

/// One line of a [PaperPanel]: [strong] lines are the ones that matter
/// (bigger, underlined).
@immutable
class EasyLine {
  const EasyLine(this.text, {this.strong = false});

  final String text;
  final bool strong;
}

/// A paper written by the app (no picture of its own): an old yellow page
/// ([old]) or a clean card, its [title] and [lines]; a stamp or a picture
/// at its foot ([foot], with its label).
final class PaperPanel extends EasyPanel {
  const PaperPanel({
    required super.id,
    required this.title,
    required this.lines,
    this.old = true,
    this.foot,
    this.footLabel,
    super.caption,
    this.aspect = 0.8,
  });

  final String title;
  final List<EasyLine> lines;
  final bool old;
  final String? foot;
  final String? footLabel;

  @override
  final double aspect;
}

/// A piece of evidence held, shown as the notebook shows it (its drawing
/// or picture) with its name: what the step is about, on the same screen.
final class EvidencePanel extends EasyPanel {
  const EvidencePanel({required super.id, required this.evidenceId, super.caption});

  final String evidenceId;

  @override
  double get aspect => 1;
}

/// Someone's words, as said: their portrait, name and the line.
final class QuotePanel extends EasyPanel {
  const QuotePanel({required super.id, required this.name, required this.quote, this.portrait, super.caption});

  final String name;
  final String quote;
  final String? portrait;

  @override
  double get aspect => 1.6;
}

/// The Clockmaker's mark (Case 01's eight-toothed gear), drawn as the
/// notebook draws it, on a small card ([label] on it): or the paper the
/// gear stamp is pressed on ([stamped]: the mark is on it).
final class GearMarkPanel extends EasyPanel {
  const GearMarkPanel({required super.id, required this.label, this.stamped = true, super.caption});

  final String label;
  final bool stamped;

  @override
  double get aspect => 0.9;
}

/// A page rubbed with a pencil (Case 11 M1): the [book] picture, the part
/// of it to rub ([area], its pixels), and what the rubbing brings out —
/// [lines] written in graphite and [signature] (a picture laid in grey),
/// each at its place.
final class RubPanel extends EasyPanel {
  const RubPanel({
    required super.id,
    required this.book,
    required this.area,
    required this.lines,
    this.signature,
    super.caption,
  });

  final EasyPicture book;
  final Rect area;
  final List<EasyWriting> lines;
  final EasyLayer? signature;

  @override
  double get aspect => book.aspect;
}

/// Where the old machine is in its repair (Case 12 M3).
enum MachineState {
  /// Running wrong: lever up, its three little clocks one hour behind.
  running,

  /// Stopped: lever down.
  stopped,

  /// The big wheel turned one hour on: the clocks set right.
  turned,

  /// The pin in: the wheel held.
  pinned,

  /// Started again: lever up, all the clocks agree.
  fixed,
}

/// The old test machine with its parts laid on it, at [state], beside the
/// wall clock (Case 12 M3): every place measured on its pictures.
final class MachinePanel extends EasyPanel {
  const MachinePanel({required super.id, required this.scene, required this.state, super.caption});

  final MachineScene scene;
  final MachineState state;

  @override
  double get aspect => scene.machine.pixels.aspect;
}

/// The old machine's pictures and where each part goes on it (its pixels):
/// the big wheel in its round recess, the window under it where its time
/// shows, the lever in its slot (turning on [leverPivot]), the pin by its
/// hole, the three little white dials ([dials], centres; [dialRadius]).
/// The clocks show [wrong] (minutes after midnight) until the wheel is
/// turned, then [right] — the wall clock's time.
@immutable
class MachineScene {
  const MachineScene({
    required this.machine,
    required this.wheel,
    required this.wheelPixels,
    required this.wheelHub,
    required this.wheelAt,
    required this.window,
    required this.lever,
    required this.leverPixels,
    required this.leverAt,
    required this.pin,
    required this.pinPixels,
    required this.pinOut,
    required this.pinIn,
    required this.dials,
    required this.dialRadius,
    required this.wallDial,
    required this.wallDialPixels,
    required this.wallDialPivot,
    required this.wrong,
    required this.right,
  });

  final EasyPicture machine;
  final String wheel;
  final ScenePixels wheelPixels;

  /// The wheel's hub in its own picture (it turns round it).
  final Offset wheelHub;
  final Rect wheelAt;
  final Rect window;
  final String lever;
  final ScenePixels leverPixels;
  final Rect leverAt;
  final String pin;
  final ScenePixels pinPixels;
  final Rect pinOut;
  final Rect pinIn;
  final List<Offset> dials;
  final double dialRadius;
  final String wallDial;
  final ScenePixels wallDialPixels;
  final Offset wallDialPivot;
  final int wrong;
  final int right;

  /// Where to tap for the wheel and the pin (the machine's pixels).
  Rect get wheelTarget => wheelAt.inflate(wheelAt.width * 0.04);
  Rect get pinTarget => pinOut.inflate(pinOut.width * 0.6);

  static String timeOf(int minutes) {
    final h = (minutes ~/ 60) % 12;
    final m = minutes % 60;
    return '${h == 0 ? 12 : h}:${m.toString().padLeft(2, '0')}';
  }
}

/// What a step asks the detective to do.
enum EasyDo {
  /// Look, then go on with its button ([EasyStep.button]: NEXT, STOP…).
  next,

  /// Tap the thing lit ([EasyStep.target]).
  tap,

  /// Rub the page with a finger (a tap rubs too) until the words come out.
  rub,

  /// Choose one of two answers ([EasyStep.options]).
  choose,
}

/// An answer to choose: words on a big button ([label]); or a picture card
/// ([panel], [label] under it); or a place on the step's first panel
/// ([area], its pixels: a box on the shelf). [feedback]: said when it is
/// chosen and wrong (else the step's [EasyStep.wrong]).
@immutable
class EasyOption {
  const EasyOption({required this.id, this.label, this.panel, this.area, this.feedback});

  final String id;
  final String? label;
  final EasyPanel? panel;
  final Rect? area;
  final String? feedback;
}

/// One step of an [EasyStepsScene].
@immutable
class EasyStep {
  const EasyStep({
    required this.id,
    required this.say,
    this.panels = const [],
    this.does = EasyDo.next,
    this.button = 'NEXT',
    this.target,
    this.lit = const [],
    this.question,
    this.options = const [],
    this.answer,
    required this.hints,
    this.lookHere = const [],
    this.wrong = defaultWrong,
    this.tell,
    this.done,
    this.after,
    this.doneButton,
  }) : assert(does != EasyDo.choose || answer != null, 'a choice needs its answer');

  static const defaultWrong = 'Try again! Look here.';

  final String id;

  /// What to do, in a few words ("Tap the big book.").
  final String say;
  final List<EasyPanel> panels;
  final EasyDo does;

  /// The way on from a [EasyDo.next] step.
  final String button;

  /// The thing to tap ([EasyDo.tap]); null: the first panel.
  final EasyMark? target;

  /// Always lit while the step is on (what to look at in a large target:
  /// the wheel in the watch, which is tapped anywhere on the watch).
  final List<EasyMark> lit;

  /// A choice's question ("Were the clocks right?").
  final String? question;
  final List<EasyOption> options;
  final String? answer;

  /// Said one after another as HINT is pressed (any time, as often as
  /// wanted); once all are said, the answer is lit too.
  final List<String> hints;

  /// Lit after a first wrong answer, and with the hints.
  final List<EasyMark> lookHere;

  /// Said after a first wrong answer.
  final String wrong;

  /// Said after a second wrong answer: the answer, plainly ("Victor signed
  /// this page."). The right answer is lit with it.
  final String? tell;

  /// Said once the step is done, before going on ("The same stamp!").
  final String? done;

  /// What is shown once the step is done (null: its panels).
  final List<EasyPanel>? after;

  /// The way on once done (null: NEXT; the last step: the puzzle's own).
  final String? doneButton;

  /// The panel with [id], among this step's ([panels], then [after]).
  EasyPanel? panel(String id) {
    for (final p in [...panels, ...?after]) {
      if (p.id == id) return p;
    }
    return null;
  }

  EasyOption? option(String id) {
    for (final o in options) {
      if (o.id == id) return o;
    }
    return null;
  }
}

/// A puzzle played in [steps], one at a time; once the last one is done,
/// [answer] answers the mission (or the final). [title]: over the steps
/// ("THE BIG BOOK").
@immutable
class EasyStepsScene {
  const EasyStepsScene({required this.title, required this.steps, required this.answer, this.finishLabel = 'DONE'});

  final String title;
  final List<EasyStep> steps;
  final String answer;

  /// The way on from the last step's done line.
  final String finishLabel;
}

/// The saved step: how many steps are done ("step=2"); a save that cannot
/// be read starts at the first step, one past the end is all done.
abstract final class EasyStepsState {
  static String encode(int done) => 'step=$done';

  static int decode(String? raw, EasyStepsScene scene) {
    final n = int.tryParse((raw ?? '').replaceFirst('step=', ''));
    if (n == null || n < 0) return 0;
    return n > scene.steps.length ? scene.steps.length : n;
  }
}

/// Evidence of Cases 11–12 drawn as one of their panels (Page 3 written
/// out, Victor's paper with its stamp, the name tag on its wheel).
final class EasyEvidence implements DrawnEvidence {
  const EasyEvidence(this.panel);

  final EasyPanel panel;

  @override
  double get aspect => panel.aspect;
}
