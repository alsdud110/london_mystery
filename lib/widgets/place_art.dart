import '../data/models/mission.dart';
import '../features/mission_map/map_world.dart';

/// Which picture shows a mission's place. One place for the choice, so the
/// screens (mission scene, the arrival at a place, the unlocked-place card)
/// never pick files themselves; the files are in `ArtAssets.scenes`.
abstract final class PlaceArt {
  /// Places inside a landmark: they have a picture of their own.
  static const inside = {
    Artwork.greatCourt,
    Artwork.egyptRoom,
    Artwork.boathouse,
    Artwork.roseGarden,
    Artwork.staffRoom,
    Artwork.courtyard,
    Artwork.dressingRoom,
    Artwork.waitingRoom,
  };

  /// Missions whose data names their landmark's scene but that happen in a
  /// room inside it (the mission data is left as it is).
  static const missionScenes = <String, Artwork>{
    'ep03_m2': Artwork.egyptRoom, // THE EGYPT ROOM
    'ep03_m3': Artwork.greatCourt, // THE GREAT COURT
    // The old brown suitcase the story finds (Case 08's is black: drawn).
    'm01': Artwork.oldSuitcase, // KING'S CROSS: a mysterious suitcase
    'ep04_m1': Artwork.oldSuitcase, // LOST PROPERTY: an old brown suitcase
  };

  /// The scene of [m] on its mission page: its own scene (a puzzle scene
  /// such as the suitcase stays), or the room it happens in.
  static Artwork sceneOf(Mission m) => missionScenes[m.id] ?? m.scene;

  /// The place [m] happens at, as the detective arrives there: the room
  /// inside a landmark if it has one, else the landmark itself (King's
  /// Cross, not the suitcase found there), else its scene.
  static Artwork placeOf(Mission m) {
    final scene = sceneOf(m);
    if (inside.contains(scene)) return scene;
    return MapWorld.missionLandmarks[m.id]?.artwork ?? scene;
  }
}
