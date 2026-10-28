import 'package:flutter/foundation.dart';

import 'scene_explore.dart' show ScenePixels;

export 'mission.dart' show ArtworkScene, MissionScene, SeasonScene;

/// A place picture a season registers as data (`SeasonContent.places`), so a
/// new season's places need no `Artwork` value. Keyed by a season place id
/// ([ScenePlaceIds]).
///
/// A mission names one by its id (`'sceneKey'`, [SeasonScene]); the screens
/// show its picture as they show an `Artwork` scene's (`PlaceArt`,
/// `LandmarkArt.ofScene`, `PlaceScenery.scene`).
@immutable
class ScenePlace {
  const ScenePlace({required this.file, required this.pixels});

  /// The picture's asset (listed in pubspec.yaml).
  final String file;

  /// Its pixel size (never decoded larger).
  final ScenePixels pixels;
}

/// Season place ids: the season's id, a dot, and the place's own name in
/// lower case (`s3_tokyo.station`), so two seasons never share one.
abstract final class ScenePlaceIds {
  static final _name = RegExp(r'^[a-z][a-z0-9_]*$');

  /// The id of place [name] of season [seasonId].
  static String of(String seasonId, String name) => '$seasonId.$name';

  /// The season [id] belongs to, or null when it is not a season place id.
  static String? seasonOf(String id) {
    final dot = id.indexOf('.');
    if (dot <= 0 || !_name.hasMatch(id.substring(dot + 1))) return null;
    return id.substring(0, dot);
  }

  /// Whether [id] is a place id of season [seasonId].
  static bool isOf(String id, String seasonId) => seasonOf(id) == seasonId;
}
