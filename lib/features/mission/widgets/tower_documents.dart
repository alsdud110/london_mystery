import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/models/scene_explore.dart' show ScenePixels;
import '../../../widgets/game_button.dart';

/// A part of a picture ([crop], fractions of it), filling its box at the
/// part's own ratio, with [overlay] laid over [overlayAt] (fractions of the
/// part). The papers of Paris Case 03 are blank: their words are the
/// overlay, written by the app.
class CroppedPicture extends StatelessWidget {
  const CroppedPicture({
    super.key,
    required this.file,
    required this.pixels,
    this.crop = const Rect.fromLTRB(0, 0, 1, 1),
    this.overlay,
    this.overlayAt = const Rect.fromLTRB(0, 0, 1, 1),
    this.label,
  });

  final String file;
  final ScenePixels pixels;
  final Rect crop;
  final Widget? overlay;
  final Rect overlayAt;

  /// What the picture shows, for screen readers (null: decoration only).
  final String? label;

  double get aspect => crop.width * pixels.width / (crop.height * pixels.height);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: aspect,
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth / crop.width;
          final h = box.maxHeight / crop.height;
          return ClipRect(
            child: Stack(
              children: [
                Positioned(
                  left: -crop.left * w,
                  top: -crop.top * h,
                  width: w,
                  height: h,
                  child: Semantics(
                    image: label != null,
                    label: label,
                    excludeSemantics: true,
                    child: Image.asset(
                      file,
                      fit: BoxFit.fill,
                      cacheWidth: (w * MediaQuery.devicePixelRatioOf(context)).ceil().clamp(1, pixels.width.toInt()),
                      excludeFromSemantics: true,
                    ),
                  ),
                ),
                if (overlay case final o?)
                  Positioned(
                    left: overlayAt.left * box.maxWidth,
                    top: overlayAt.top * box.maxHeight,
                    width: overlayAt.width * box.maxWidth,
                    height: overlayAt.height * box.maxHeight,
                    child: o,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Words written on a sheet of a picture as if printed on it: [child] laid
/// out face on, [flat] large (the sheet's own units), then put on the sheet
/// as the picture shows it — its four [corners] (fractions of the box,
/// clockwise from the top left), the far edge narrower, a leaning one
/// leaning. Taps on [child] land where its words are seen.
class SheetWriting extends StatelessWidget {
  const SheetWriting({super.key, required this.corners, required this.flat, required this.child});

  final List<Offset> corners;
  final Size flat;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final at = [for (final c in corners) Offset(c.dx * box.maxWidth, c.dy * box.maxHeight)];
        return Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              top: 0,
              width: flat.width,
              height: flat.height,
              child: Transform(transform: sheetTransform(at, flat), child: child),
            ),
          ],
        );
      },
    );
  }
}

/// The perspective that puts a [flat] rectangle (its top left at the
/// origin) on the four corners [to] (clockwise from the top left): the
/// projective map of a square onto a quadrilateral (Heckbert), scaled to
/// [flat].
Matrix4 sheetTransform(List<Offset> to, Size flat) {
  final [p0, p1, p2, p3] = to;
  final dx1 = p1.dx - p2.dx, dx2 = p3.dx - p2.dx, dx3 = p0.dx - p1.dx + p2.dx - p3.dx;
  final dy1 = p1.dy - p2.dy, dy2 = p3.dy - p2.dy, dy3 = p0.dy - p1.dy + p2.dy - p3.dy;
  final den = dx1 * dy2 - dx2 * dy1;
  final g = (dx3 * dy2 - dx2 * dy3) / den;
  final h = (dx1 * dy3 - dx3 * dy1) / den;
  final a = p1.dx - p0.dx + g * p1.dx, b = p3.dx - p0.dx + h * p3.dx;
  final d = p1.dy - p0.dy + g * p1.dy, e = p3.dy - p0.dy + h * p3.dy;
  final w = flat.width, ht = flat.height;
  // Column by column: x and y go to (a·u + b·v + c) / (g·u + h·v + 1).
  return Matrix4(
    a / w, d / w, 0, g / w,
    b / ht, e / ht, 0, h / ht,
    0, 0, 1, 0,
    p0.dx, p0.dy, 0, 1,
  );
}

/// [child] (a paper of the case, its words on it) over the page, to pinch
/// closer, with [title] above it.
Future<void> showDocumentCloser(BuildContext context, {required String title, required Widget child, double aspect = 1}) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: AppColors.navyDeep.withValues(alpha: 0.92),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim, _) => FadeTransition(
        opacity: anim,
        child: Material(
          type: MaterialType.transparency,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.lg),
              child: Column(
                children: [
                  Text(title, textAlign: TextAlign.center, style: AppText.mark(color: AppColors.goldLight)),
                  const SizedBox(height: AppSpace.md),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 560),
                        child: AspectRatio(
                          aspectRatio: aspect,
                          child: ClipRect(child: InteractiveViewer(maxScale: 4, child: child)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Text('Pinch to look closer.', style: AppText.caption(color: AppColors.paperLight)),
                  const SizedBox(height: AppSpace.sm),
                  Builder(
                    builder: (context) => GameButton(
                      key: const ValueKey('document-close'),
                      label: 'CLOSE',
                      style: GameButtonStyle.glass,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Words written on a paper of the case: dark ink, a typed hand, scaled
/// down (never cut) to fit the paper at any size.
TextStyle paperInk({double size = 20, FontWeight weight = FontWeight.w600, Color color = AppColors.ink}) =>
    AppText.style(AppText.body, size: size, weight: weight, color: color, letterSpacing: 0.6, height: 1.15);
