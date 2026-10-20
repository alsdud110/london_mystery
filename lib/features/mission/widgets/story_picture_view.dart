import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../data/models/story_picture.dart';
import 'station_clocks.dart' show PaintedClockHands;

/// A [StoryPicture] filling its box: its part ([StoryPicture.crop]) covering
/// the box at its own proportions (never stretched; the picture's edges
/// never shown), or a cut-out object whole in the middle of it. The hands
/// of its clocks are drawn over the picture, where its painted dials are.
class StoryPictureView extends StatelessWidget {
  const StoryPictureView(this.picture, {super.key, this.imageKey});

  final StoryPicture picture;

  /// The picture's own key (tests find it by it).
  final Key? imageKey;

  @override
  Widget build(BuildContext context) {
    final p = picture;
    return Semantics(
      image: true,
      label: p.label,
      child: LayoutBuilder(
        builder: (context, box) {
          final size = box.biggest;
          final w = p.pixels.width, h = p.pixels.height;
          final Rect at;
          if (p.cutOut) {
            // Whole, centred: as large as the box allows.
            final k = math.min(size.width / w, size.height / h);
            at = Rect.fromCenter(center: size.center(Offset.zero), width: w * k, height: h * k);
          } else {
            // Its part covers the box, centred on it, kept inside the picture.
            final crop = Rect.fromLTRB(p.crop.left * w, p.crop.top * h, p.crop.right * w, p.crop.bottom * h);
            final k = math.max(size.width / crop.width, size.height / crop.height);
            final left = (size.width / 2 - crop.center.dx * k).clamp(size.width - w * k, 0.0);
            final top = (size.height / 2 - crop.center.dy * k).clamp(size.height - h * k, 0.0);
            at = Rect.fromLTWH(left, top, w * k, h * k);
          }
          final dpr = MediaQuery.devicePixelRatioOf(context);
          return ClipRect(
            child: Stack(
              children: [
                Positioned.fromRect(
                  rect: at,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        p.file,
                        key: imageKey,
                        fit: BoxFit.fill,
                        excludeFromSemantics: true,
                        // Decoded at the size shown, never beyond the file.
                        cacheWidth: math.min(w, at.width * dpr).ceil(),
                        errorBuilder: (context, error, stack) => const SizedBox.expand(),
                      ),
                      if (p.clocks.isNotEmpty) CustomPaint(painter: PaintedClockHands(p.clocks)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
