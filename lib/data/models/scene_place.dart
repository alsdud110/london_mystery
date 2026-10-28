import 'package:flutter/foundation.dart';

import 'mission.dart';
import 'scene_explore.dart' show ScenePixels;

/// A place picture a season registers as data (`SeasonContent.places`), so a
/// new season's places need no [Artwork] value. Keyed by a season place id
/// ([ScenePlaceIds]).
///
/// Data only for now: no screen shows a season place yet, and a mission
/// that names one is not played (`Mission.fromJson` refuses it) until the
/// screens do.
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

/// Where a mission happens, as its data names it: one of the shared
/// [Artwork] scenes (`'scene'`, every case of Seasons 1 and 2), or a place
/// its season registers (`'sceneKey'`). A mission names exactly one.
@immutable
sealed class MissionScene {
  const MissionScene();

  /// The scene a mission's JSON names. Throws a [FormatException] when it
  /// names both, or neither, or an [Artwork] that does not exist.
  factory MissionScene.fromJson(Map<String, dynamic> json) {
    final scene = json['scene'];
    final key = json['sceneKey'];
    final id = json['id'];
    return switch ((scene, key)) {
      (final String name, null) => ArtworkScene(Artwork.fromJson(name)),
      (null, final String key) => SeasonScene(key),
      (null, null) => throw FormatException('Mission $id names no scene (scene or sceneKey)'),
      _ => throw FormatException('Mission $id must name either scene or sceneKey, of text, not both'),
    };
  }

  /// The scene of [m]: its [Artwork] (every mission played today).
  factory MissionScene.of(Mission m) = ArtworkScene.ofMission;
}

/// A shared [Artwork] scene.
final class ArtworkScene extends MissionScene {
  const ArtworkScene(this.artwork);

  ArtworkScene.ofMission(Mission m) : artwork = m.scene;

  final Artwork artwork;

  @override
  bool operator ==(Object other) => other is ArtworkScene && other.artwork == artwork;

  @override
  int get hashCode => artwork.hashCode;

  @override
  String toString() => 'ArtworkScene(${artwork.name})';
}

/// A place its season registers ([ScenePlace]), by its id.
final class SeasonScene extends MissionScene {
  const SeasonScene(this.id);

  final String id;

  @override
  bool operator ==(Object other) => other is SeasonScene && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'SeasonScene($id)';
}
