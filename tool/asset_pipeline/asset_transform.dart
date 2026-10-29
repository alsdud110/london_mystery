import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Which part of a picture a crop keeps.
///
/// * `center`: scenes and objects (the subject drawn in the middle).
/// * `top`: characters (drawn from the head down: a crop takes the legs).
enum CropAnchor { center, top }

/// How the API's picture becomes the game's: scaled to cover the game's
/// size, its proportions kept, then the part beyond it cropped away.
class TransformPlan {
  const TransformPlan({
    required this.fromWidth,
    required this.fromHeight,
    required this.toWidth,
    required this.toHeight,
    required this.anchor,
    required this.scale,
    required this.problems,
  });

  final int fromWidth, fromHeight, toWidth, toHeight;
  final CropAnchor anchor;

  /// The factor both edges are scaled by (above 1: enlarged).
  final double scale;

  /// Why it is refused (none: it may be made).
  final List<String> problems;

  bool get needed => fromWidth != toWidth || fromHeight != toHeight;

  /// The share of the scaled picture cropped away (0 when only scaled).
  double get cropped => 1 - (toWidth * toHeight) / (fromWidth * scale * fromHeight * scale);

  Map<String, Object?> toJson() => {
    'from': '${fromWidth}x$fromHeight',
    'to': '${toWidth}x$toHeight',
    'scale': double.parse(scale.toStringAsFixed(4)),
    'cropped': double.parse(cropped.toStringAsFixed(4)),
    'anchor': anchor.name,
  };
}

/// Fits a PNG to the game's size (STEP 3-12A), with `package:image` (the
/// game's dev dependency, as `tool/prepare_splash.dart` uses it).
///
/// The policy:
/// * The original is never changed: the result is new bytes, written
///   elsewhere by the caller.
/// * Proportions are kept: scaled to cover, never stretched; what lies
///   beyond the game's frame is cropped ([CropAnchor]).
/// * Shrinking uses area averaging; enlarging (cubic) is allowed up to
///   [maxUpscale], beyond which it is refused (a blurred picture is worse
///   than a request at the right size).
/// * A crop of more than [maxCrop] of the picture is refused: the
///   composition would be lost (ask for the right shape instead).
/// * Transparency is kept: a picture with alpha stays RGBA.
abstract final class AssetTransform {
  static const maxUpscale = 1.25;
  static const maxCrop = 0.25;

  /// The plan from [fromWidth]×[fromHeight] to [toWidth]×[toHeight].
  static TransformPlan plan(int fromWidth, int fromHeight, int toWidth, int toHeight, {CropAnchor anchor = CropAnchor.center}) {
    final scale = math.max(toWidth / fromWidth, toHeight / fromHeight);
    final problems = <String>[];
    if (toWidth <= 0 || toHeight <= 0 || fromWidth <= 0 || fromHeight <= 0) problems.add('no pixels');
    final p = TransformPlan(
      fromWidth: fromWidth,
      fromHeight: fromHeight,
      toWidth: toWidth,
      toHeight: toHeight,
      anchor: anchor,
      scale: scale,
      problems: problems,
    );
    if (problems.isEmpty) {
      if (scale > maxUpscale) problems.add('enlarged ${scale.toStringAsFixed(2)}x (at most ${maxUpscale}x): ask for a larger picture');
      if (p.cropped > maxCrop + 1e-9) {
        problems.add('${(p.cropped * 100).toStringAsFixed(0)}% cropped away (at most ${(maxCrop * 100).toStringAsFixed(0)}%): ask for the right shape');
      }
    }
    return p;
  }

  /// [png] made as [p] says: new PNG bytes of exactly its size.
  static Uint8List apply(Uint8List png, TransformPlan p) {
    if (p.problems.isNotEmpty) throw StateError('refused: ${p.problems.join('; ')}');
    var src = img.decodePng(png);
    if (src == null) throw const FormatException('not a PNG');
    if (src.width != p.fromWidth || src.height != p.fromHeight) {
      throw StateError('the picture is ${src.width}x${src.height}, the plan is for ${p.fromWidth}x${p.fromHeight}');
    }
    if (!p.needed) return png;
    if (src.hasPalette) src = src.convert(numChannels: 4);
    final w = math.max(p.toWidth, (p.fromWidth * p.scale).round());
    final h = math.max(p.toHeight, (p.fromHeight * p.scale).round());
    final scaled = img.copyResize(
      src,
      width: w,
      height: h,
      interpolation: p.scale < 1 ? img.Interpolation.average : img.Interpolation.cubic,
    );
    final x = (w - p.toWidth) ~/ 2;
    final y = p.anchor == CropAnchor.top ? 0 : (h - p.toHeight) ~/ 2;
    final out = img.copyCrop(scaled, x: x, y: y, width: p.toWidth, height: p.toHeight);
    return img.encodePng(out);
  }
}
