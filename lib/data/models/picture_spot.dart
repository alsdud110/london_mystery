import 'dart:math' as math;
import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart' show BoxFit, Matrix4, MatrixUtils;

import 'scene_explore.dart' show ScenePixels;

/// A place on a picture that answers a puzzle (a difference, a hidden mark,
/// a canvas), as fractions (0..1) of the picture's own width and height:
/// measured once on the file, the same on every screen, at every zoom.
@immutable
class PictureSpot {
  const PictureSpot(this.id, this.area, {this.label = ''});

  /// The option of the mission it answers.
  final String id;

  /// Where it is, for screen readers (never the answer itself).
  final String label;

  /// Where it is, fractions of the picture.
  final Rect area;

  /// Whether [at] (fractions of the picture) is on it, or within [slop]
  /// (fractions of the picture's shorter side, for a fingertip) of it.
  bool contains(Offset at, {required ScenePixels pixels, double slop = 0}) {
    if (area.contains(at)) return true;
    if (slop <= 0) return false;
    // Measured in pixels, so the slop is as wide across as down.
    final short = math.min(pixels.width, pixels.height);
    final px = Offset(at.dx * pixels.width, at.dy * pixels.height);
    final r = Rect.fromLTRB(
      area.left * pixels.width,
      area.top * pixels.height,
      area.right * pixels.width,
      area.bottom * pixels.height,
    ).inflate(slop * short);
    return r.contains(px);
  }
}

/// Where a touch is on a picture shown in a box: the picture fitted into
/// the box ([fit]: whole, or covering it), then zoomed and moved by the
/// player ([viewer], an `InteractiveViewer`'s transform; none: as fitted).
/// Fractions (0..1) of the picture, or null off the picture.
Offset? pictureFraction(
  Offset touch, {
  required Size box,
  required ScenePixels pixels,
  BoxFit fit = BoxFit.contain,
  Matrix4? viewer,
}) {
  // Back through the zoom and move: where the touch is on the unzoomed box.
  var at = touch;
  if (viewer != null) {
    final inverse = Matrix4.tryInvert(viewer);
    if (inverse == null) return null;
    at = MatrixUtils.transformPoint(inverse, touch);
  }
  final shown = fittedPicture(box: box, pixels: pixels, fit: fit);
  final f = Offset((at.dx - shown.left) / shown.width, (at.dy - shown.top) / shown.height);
  if (f.dx < 0 || f.dy < 0 || f.dx > 1 || f.dy > 1) return null;
  return f;
}

/// Where the picture lies in [box] when fitted ([BoxFit.contain]: whole,
/// centred; [BoxFit.cover]: covering it, centred). Other fits are not used.
Rect fittedPicture({required Size box, required ScenePixels pixels, BoxFit fit = BoxFit.contain}) {
  final sx = box.width / pixels.width, sy = box.height / pixels.height;
  final k = switch (fit) {
    BoxFit.cover => math.max(sx, sy),
    BoxFit.contain => math.min(sx, sy),
    _ => throw UnsupportedError('$fit'),
  };
  final w = pixels.width * k, h = pixels.height * k;
  return Rect.fromLTWH((box.width - w) / 2, (box.height - h) / 2, w, h);
}
