import 'dart:math' as math;
import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter/foundation.dart';

import 'scene_explore.dart' show ScenePixels;

/// How a picture fills a full-screen backdrop (the place behind the story,
/// the Discovery Moment, the scene after a mission).
enum BackdropFit {
  /// The allowed part of the picture covers the screen, centred on its
  /// focus: nothing else is drawn, whatever is cut.
  cover,

  /// The picture covers the screen, drawn as close to its focus as the
  /// focus allows whole (a close-up, never past [BackdropLook.maxScale]),
  /// centred on it. Never a fill: for a focus narrow enough to show whole
  /// while covering.
  focusCrop,

  /// The picture covers the screen when its focus then shows whole; when
  /// it would not, the picture is drawn just small enough for the focus to
  /// show whole, and the room left around it is filled with the same
  /// picture, softly blurred, its edges faded into that fill.
  containWithFill,
}

/// How one picture is laid as a backdrop: the part that must be seen
/// ([focus]) and the only part that may ever be seen ([bounds]), both in
/// fractions of the picture. [anchor]: where the focus sits on the screen
/// when the picture does not fill it (0 top, 1 bottom). [maxScale]: the
/// most screen points one picture pixel may take (a small print is never
/// blown up into a blur; the fill takes the room left).
@immutable
class BackdropLook {
  const BackdropLook({
    this.fit = BackdropFit.containWithFill,
    this.focus = whole,
    this.bounds = whole,
    this.anchor = 0.42,
    this.maxScale,
  });

  static const whole = Rect.fromLTRB(0, 0, 1, 1);

  final BackdropFit fit;
  final Rect focus;
  final Rect bounds;
  final double anchor;
  final double? maxScale;
}

/// Where a backdrop's picture lies on a screen of [box] ([BackdropLayout.of]).
@immutable
class BackdropLayout {
  const BackdropLayout({
    required this.picture,
    required this.shown,
    required this.fill,
    required this.scale,
    required this.window,
  });

  /// The whole picture, on the screen (it may run past the screen's edges).
  final Rect picture;

  /// What is drawn of it, sharp: its allowed part, inside the screen.
  final Rect shown;

  /// The blurred fill under it, where [shown] does not reach (null: none
  /// needed). It covers the screen with the allowed part only.
  final Rect? fill;

  /// Screen points per picture pixel.
  final double scale;

  /// The part of the picture on screen, sharp (fractions of the picture).
  final Rect window;

  bool get filled => fill != null;

  static BackdropLayout of(Size box, ScenePixels pixels, BackdropLook look) {
    final w = pixels.width, h = pixels.height;
    final bounds = look.bounds.intersect(BackdropLook.whole);
    var focus = look.focus.intersect(bounds);
    if (focus.width <= 0 || focus.height <= 0) focus = bounds;
    final b = Rect.fromLTRB(bounds.left * w, bounds.top * h, bounds.right * w, bounds.bottom * h);
    final f = Rect.fromLTRB(focus.left * w, focus.top * h, focus.right * w, focus.bottom * h);
    // Covering the screen with the allowed part / showing the focus whole.
    final cover = math.max(box.width / b.width, box.height / b.height);
    final fit = math.min(box.width / f.width, box.height / f.height);
    final k = switch (look.fit) {
      BackdropFit.cover => cover,
      BackdropFit.focusCrop => math.max(cover, math.min(fit, look.maxScale ?? double.infinity)),
      BackdropFit.containWithFill => math.min(math.min(cover, fit), look.maxScale ?? double.infinity),
    };
    final centre = look.fit == BackdropFit.cover ? b.center : f.center;
    final left = _place(box.width / 2 - centre.dx * k, b.left * k, b.right * k, box.width);
    // (Vertically, a picture smaller than the screen holds its focus at the
    // [BackdropLook.anchor] line.)
    final top = _place(
      (look.fit == BackdropFit.containWithFill ? box.height * look.anchor : box.height / 2) - centre.dy * k,
      b.top * k,
      b.bottom * k,
      box.height,
    );
    final picture = Rect.fromLTWH(left, top, w * k, h * k);
    final allowed = Rect.fromLTRB(left + b.left * k, top + b.top * k, left + b.right * k, top + b.bottom * k);
    final shown = allowed.intersect(Offset.zero & box);
    // Less than half a point uncovered is no gap.
    final gap = shown.left > 0.5 || shown.top > 0.5 || shown.right < box.width - 0.5 || shown.bottom < box.height - 0.5;
    Rect? fill;
    if (gap) {
      final kf = cover;
      final fl = _place(box.width / 2 - b.center.dx * kf, b.left * kf, b.right * kf, box.width);
      final ft = _place(box.height / 2 - b.center.dy * kf, b.top * kf, b.bottom * kf, box.height);
      fill = Rect.fromLTWH(fl, ft, w * kf, h * kf);
    }
    return BackdropLayout(
      picture: picture,
      shown: shown,
      fill: fill,
      scale: k,
      window: Rect.fromLTRB(
        (shown.left - left) / (w * k),
        (shown.top - top) / (h * k),
        (shown.right - left) / (w * k),
        (shown.bottom - top) / (h * k),
      ),
    );
  }

  /// The picture's offset along one axis: [want], moved just enough that
  /// its allowed span [from]..[to] (picture points) covers the screen's
  /// [length] when it is long enough to, else stays inside it.
  static double _place(double want, double from, double to, double length) {
    final a = -from, b = length - to;
    return want.clamp(math.min(a, b), math.max(a, b)).toDouble();
  }
}
