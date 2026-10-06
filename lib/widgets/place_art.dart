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
    Artwork.gallery,
    Artwork.auditorium,
    Artwork.theatreDoor,
    Artwork.gearDoor,
    Artwork.ironDoor,
    Artwork.ironChest,
    Artwork.royalArchive,
  };

  /// Missions whose data names their landmark's scene but that happen in a
  /// room inside it (the mission data is left as it is).
  static const missionScenes = <String, Artwork>{
    'ep03_m2': Artwork.egyptRoom, // THE EGYPT ROOM
    'ep03_m3': Artwork.greatCourt, // THE GREAT COURT
    // The theatre's auditorium: "red seats, gold lamps and a big dark stage".
    'ep11_m1': Artwork.auditorium, // THE THEATRE
    // Its door at night: "The theatre is dark. Only the stage light is on."
    'ep06_m3': Artwork.theatreDoor, // THE THEATRE DOOR
    // The data's `lockedDoor` is two different doors.
    'ep05_m2': Artwork.gearDoor, // THE WHITE TOWER: a dial, four brass gears
    // Behind it, the final: "The iron chest is cold and heavy."
    'ep05_final': Artwork.ironChest, // THE LOCKED ROOM
    'ep12_final': Artwork.ironDoor, // UNDER BIG BEN: "a small iron door"
    // Mrs Robin's black suitcase, its name tag washed blank (Case 11's
    // final recalls Case 01's suitcase on Platform 9: it stays drawn).
    'ep08_m1': Artwork.blackSuitcase, // PLATFORM 9
    'ep08_m3': Artwork.blackSuitcase, // THE STATION OFFICE
    // The old brown suitcase the story finds.
    'm01': Artwork.oldSuitcase, // KING'S CROSS: a mysterious suitcase
    'ep04_m1': Artwork.oldSuitcase, // LOST PROPERTY: an old brown suitcase
    // The same suitcase's letters, read on Platform 4 and on the last train
    // (the drawn suitcase is Platform 9's).
    'ep04_m3': Artwork.oldSuitcase, // PLATFORM 4
    'ep04_final': Artwork.oldSuitcase, // THE LAST TRAIN
    // Big Ben itself: its clock is not stopped in Case 12 (the drawn clock
    // face is Case 02's, stopped at 8:17).
    'ep12_m1': Artwork.bigBen, // BIG BEN
  };

  /// The scene of [m] on its mission page, final case, case photo and board
  /// print: its own scene (a puzzle scene such as the suitcase stays), or
  /// the room it happens in.
  static Artwork sceneOf(Mission m) => missionScenes[m.id] ?? m.scene;

  /// Places that stand on the map at a landmark whose picture is not them,
  /// as the story arrives there: the Royal Archive (Case 01's final) is
  /// pinned at Buckingham Palace, down its secret stairs. Only the arrival
  /// (story scenes, the unlocked card); the final's own scene stays the
  /// Royal Box (the final case, its photo, the board).
  static const _missionPlaces = <String, Artwork>{'final': Artwork.royalArchive};

  /// The picture to fill a screen with for [m]'s place.
  static Artwork? sceneryOf(Mission m) => placeOf(m);

  /// The place [m] happens at, as the detective arrives there: the room
  /// inside a landmark if it has one, else the landmark itself (King's
  /// Cross, not the suitcase found there), else its scene.
  static Artwork placeOf(Mission m) {
    final own = _missionPlaces[m.id];
    if (own != null) return own;
    final scene = sceneOf(m);
    if (inside.contains(scene)) return scene;
    return MapWorld.missionLandmarks[m.id]?.artwork ?? scene;
  }
}
