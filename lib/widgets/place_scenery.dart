import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/models/mission.dart';
import 'art_assets.dart';
import 'landmark_art.dart';

/// The unlocked place filling the screen in the dark under the story (the
/// same treatment as the story intro): its picture without its paper edge
/// and name plate, softened a touch and dimmed so the words lead. A place
/// with no picture of its own shows the London map instead.
class PlaceScenery extends StatelessWidget {
  const PlaceScenery(this.place, {super.key});

  final Artwork? place;

  @override
  Widget build(BuildContext context) {
    final scene = place;
    final picture = scene != null && LandmarkArt.hasPicture(scene)
        ? LandmarkArt(scene, showName: false, borderRadius: 0)
        : LayoutBuilder(
            builder: (context, box) => Image.asset(
              ArtAssets.londonMap,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              cacheWidth: math.min(
                (math.max(box.maxWidth, box.maxHeight * ArtAssets.londonMapAspect) *
                        MediaQuery.devicePixelRatioOf(context))
                    .ceil(),
                ArtAssets.londonMapPixels.width.toInt(),
              ),
              excludeFromSemantics: true,
              errorBuilder: (context, error, stack) => const SizedBox.expand(),
            ),
          );
    const shade = AppColors.navyDeep;
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(imageFilter: ui.ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5), child: picture),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 1.0,
                colors: [shade.withValues(alpha: 0.6), shade.withValues(alpha: 0.82)],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  for (final a in const [0.25, 0.0, 0.0, 0.45]) shade.withValues(alpha: a),
                ],
                stops: const [0, 0.2, 0.7, 1],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
