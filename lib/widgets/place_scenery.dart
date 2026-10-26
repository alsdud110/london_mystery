import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/models/mission.dart';
import '../data/models/story_picture.dart';
import '../features/mission/widgets/station_clocks.dart' show PaintedClockHands;
import '../features/mission/widgets/story_picture_view.dart';
import '../features/mission_map/map_world.dart' show SeasonMap;
import 'backdrop_art.dart';
import 'landmark_art.dart';
import 'scene_backdrop.dart';

/// A place filling the screen in the dark under the story: the case's
/// opening, the Discovery Moment, the scene after a mission. Its picture is
/// laid by its [BackdropArt] look (its landmark never cut, never blown up
/// into a blur), softened a touch and dimmed so the words lead. A place
/// with no picture of its own shows its season's [map] instead (London by
/// default), or only the night when that season has no map.
class PlaceScenery extends StatelessWidget {
  const PlaceScenery(this.place, {super.key, this.map = SeasonMap.london}) : file = null, story = null, imageKey = null;

  /// A place's own picture file that is no scene of the map (a room the
  /// people of a mission stand in), with the same treatment.
  const PlaceScenery.file(String this.file, {super.key}) : place = null, map = null, story = null, imageKey = null;

  /// A picture of the story at this moment (Paris: the scene after a
  /// mission), with the same treatment: a part of a scene shown whole and
  /// close, or an object cut out, whole in the middle of the night.
  const PlaceScenery.story(StoryPicture this.story, {super.key, this.imageKey}) : place = null, map = null, file = null;

  final Artwork? place;
  final String? file;
  final StoryPicture? story;

  /// The story picture's own key (tests find it by it).
  final Key? imageKey;

  /// The map shown when the place has no picture (null: none, the night).
  final SeasonMap? map;

  @override
  Widget build(BuildContext context) {
    final scene = place;
    final own = file;
    final map = this.map;
    final story = this.story;
    final ownArt = own == null ? null : BackdropArt.of(own);
    final Widget picture;
    if (story != null) {
      picture = story.cutOut
          ? StoryPictureView(story, imageKey: imageKey)
          : SceneBackdrop(
              file: story.file,
              pixels: story.pixels,
              look: BackdropArt.storyLook(story),
              imageKey: imageKey,
              overlay: story.clocks.isEmpty ? null : CustomPaint(painter: PaintedClockHands(story.clocks)),
            );
    } else if (own != null && ownArt != null) {
      picture = SceneBackdrop(file: own, pixels: ownArt.pixels, look: ownArt.look);
    } else if (own != null) {
      picture = LayoutBuilder(
        builder: (context, box) => Image.asset(
          own,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          cacheWidth: box.maxWidth.isFinite ? (box.maxWidth * MediaQuery.devicePixelRatioOf(context)).ceil() : null,
          excludeFromSemantics: true,
          errorBuilder: (context, error, stack) => const SizedBox.expand(),
        ),
      );
    } else if (scene != null && LandmarkArt.hasPicture(scene)) {
      picture = LandmarkArt.backdrop(scene);
    } else if (map == null) {
      picture = const SizedBox.expand();
    } else {
      picture = LayoutBuilder(
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
    }
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
