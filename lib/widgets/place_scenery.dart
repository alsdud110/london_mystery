import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/models/mission.dart';
import '../features/mission_map/map_world.dart' show SeasonMap;
import 'landmark_art.dart';

/// The unlocked place filling the screen in the dark under the story (the
/// same treatment as the story intro): its picture without its paper edge
/// and name plate, softened a touch and dimmed so the words lead. A place
/// with no picture of its own shows its season's [map] instead (London by
/// default), or only the night when that season has no map.
class PlaceScenery extends StatelessWidget {
  const PlaceScenery(this.place, {super.key, this.map = SeasonMap.london}) : file = null;

  /// A place's own picture file that is no scene of the map (a room the
  /// people of a mission stand in), with the same treatment.
  const PlaceScenery.file(String this.file, {super.key}) : place = null, map = null;

  final Artwork? place;
  final String? file;

  /// The map shown when the place has no picture (null: none, the night).
  final SeasonMap? map;

  @override
  Widget build(BuildContext context) {
    final scene = place;
    final own = file;
    final map = this.map;
    final picture = own != null
        ? LayoutBuilder(
            builder: (context, box) => Image.asset(
              own,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              cacheWidth: box.maxWidth.isFinite ? (box.maxWidth * MediaQuery.devicePixelRatioOf(context)).ceil() : null,
              excludeFromSemantics: true,
              errorBuilder: (context, error, stack) => const SizedBox.expand(),
            ),
          )
        : scene != null && LandmarkArt.hasPicture(scene)
        ? LandmarkArt(scene, showName: false, borderRadius: 0)
        : map == null
        ? const SizedBox.expand()
        : LayoutBuilder(
            builder: (context, box) => Image.asset(
              map.artwork,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              cacheWidth: math.min(
                (math.max(box.maxWidth, box.maxHeight * map.aspect) * MediaQuery.devicePixelRatioOf(context)).ceil(),
                map.pixels.width.toInt(),
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
