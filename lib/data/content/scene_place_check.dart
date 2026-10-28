import '../mock/season_catalog.dart';
import '../models/scene_place.dart';

/// Checks of the places seasons register as data ([SeasonContent.places])
/// and of the scenes their missions name ([MissionScene]). Run by the
/// tests, like `DifficultyContent.problems`; whether a place's picture is
/// on disk and bundled is the tests' (they read the files).
abstract final class ScenePlaceCheck {
  /// What is wrong in [seasons] (all of the game's by default), or nothing.
  static List<String> problems({Iterable<SeasonContent>? seasons}) {
    final all = (seasons ?? SeasonCatalog.all).toList();
    return [for (final s in all) ...problemsOf(s), ...sharedPlaces(all)];
  }

  /// The place ids registered by more than one of [seasons].
  static List<String> sharedPlaces(Iterable<SeasonContent> seasons) {
    final out = <String>[];
    final owner = <String, String>{};
    for (final s in seasons) {
      for (final id in s.places.keys) {
        final first = owner.putIfAbsent(id, () => s.id);
        if (first != s.id) out.add('$id: registered by both $first and ${s.id}');
      }
    }
    return out;
  }

  /// What is wrong in [season]'s places and its missions' scenes.
  static List<String> problemsOf(SeasonContent season) {
    final out = <String>[];
    season.places.forEach((id, place) {
      if (!ScenePlaceIds.isOf(id, season.id)) {
        out.add('${season.id} place $id: not a place id of ${season.id} (${season.id}.name)');
      }
      if (!place.file.startsWith('assets/') || place.file.endsWith('/')) {
        out.add('${season.id} place $id: its picture is not an asset file (${place.file})');
      }
      if (place.pixels.width <= 0 || place.pixels.height <= 0) {
        out.add('${season.id} place $id: its pixel size is empty');
      }
    });
    for (final scene in scenesOf(season).entries) {
      final at = '${season.id} ${scene.key}';
      final MissionScene named;
      try {
        named = MissionScene.fromJson(scene.value);
      } on FormatException catch (e) {
        out.add('$at: ${e.message}');
        continue;
      }
      if (named case SeasonScene(:final id)) {
        if (!ScenePlaceIds.isOf(id, season.id)) {
          out.add('$at: $id is not a place of ${season.id}');
        } else if (!season.places.containsKey(id)) {
          out.add('$at: $id is not registered');
        }
      }
    }
    return out;
  }

  /// Every mission of [season] (its cases and those awaiting their
  /// pictures), as JSON, by mission id.
  static Map<String, Map<String, dynamic>> scenesOf(SeasonContent season) => {
    for (final json in {...season.episodes, ...season.awaitingArt}.values)
      for (final m in [...json['missions'] as List, json['finalMission']])
        if (m is Map<String, dynamic>) '${m['id']}': m,
  };
}
