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
