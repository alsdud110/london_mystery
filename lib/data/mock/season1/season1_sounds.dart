import '../../../core/utils/audio_service.dart';
import '../../models/mission.dart';

/// What the player's hands do in a Season 1 puzzle, where it is a real
/// thing in the story (presentation only: which sound plays). Like the
/// discoveries, it is data: the puzzle widgets never branch on a mission.

/// Missions whose answer opens a real lock on the scene: the box at Big Ben
/// ("Click! The box opens."), the ravens' food box with its word lock, and
/// Mrs Robin's silver suitcase lock ("Click! Inside…"). Their correct answer
/// is the lock opening, not the usual discovery cue.
const season1LockMissions = {'m03', 'ep05_m3', 'ep08_m3'};

/// Answers that open a great iron lock: the White Tower's dial door, the
/// Iron Chest in the locked room, and the Clockmaker's door under Big Ben.
/// Heavier than a padlock, and never with it.
const season1HeavyLocks = {'ep05_m2', 'ep05_final', 'ep12_final'};

/// Finals whose solving is a thing of the story with its own sound: the
/// Royal Box opening (Case 01), the Great Clock running again (Case 02).
const season1FinalSignatures = <String, GameSound>{
  'final': GameSound.royalBoxOpen,
  'ep02_final': GameSound.clockRestart,
};

/// Finals after which Big Ben rings ("Big Ben rings again!"), as the news
/// of the solve comes up.
const season1BellFinals = {'ep02_final'};

/// Order puzzles whose steps are pieces of paper laid down one by one: the
/// three map pieces, Poppy's four papers on the wall, the warning's papers.
const season1PaperSequences = {'ep07_m3', 'ep10_m2', 'ep10_final'};

/// Order puzzles whose steps turn a real dial: the White Tower's door.
const season1DialSequences = {'ep05_m2'};

/// Whether solving [m] opens a real lock.
bool opensLock(Mission m) => season1LockMissions.contains(m.id);

/// What is heard as [m] is solved: one physical event where the scene has
/// one (a heavy lock, a padlock, the Royal Box, the Great Clock), else the
/// final's cue or the usual discovery cue.
GameSound solveSoundOf(Mission m) {
  if (season1HeavyLocks.contains(m.id)) return GameSound.lockOpenHeavy;
  if (opensLock(m)) return GameSound.padlockOpen;
  final signature = season1FinalSignatures[m.id];
  if (signature != null) return signature;
  return m.isFinal ? GameSound.finale : GameSound.puzzleCorrect;
}

/// Whether Big Ben rings once [m] is solved.
bool ringsBellOnSolve(Mission m) => season1BellFinals.contains(m.id);

/// What one step of the order puzzle [m] does in the scene.
enum SequenceTouch { none, paper, dial }

SequenceTouch sequenceTouchOf(Mission m) {
  if (season1PaperSequences.contains(m.id)) return SequenceTouch.paper;
  if (season1DialSequences.contains(m.id)) return SequenceTouch.dial;
  return SequenceTouch.none;
}

/// Where a Season 1 page happens, as it sounds: the place's bed and, where
/// the place has one, its detail. One entry per case's opening and per
/// mission (the places of the audio audit), so the sound of a place is
/// data: no page decides it.
typedef SoundPlace = (AmbienceBase, AmbienceAccent?);

/// Where each case's story opens: where its narration puts the player
/// (the picture only where the words say nothing more).
const season1IntroPlaces = <String, SoundPlace>{
  'ep01': (AmbienceBase.londonNight, null), // London, 10:42 PM
  // Early morning, London too quiet, Big Ben stopped: a day street, not the
  // river (not recorded yet: silent).
  'ep02': (AmbienceBase.londonDay, null),
  'ep03': (AmbienceBase.grandInterior, null), // British Museum, 9:18 AM
  'ep04': (AmbienceBase.station, null), // King's Cross, 11:00 AM
  'ep05': (AmbienceBase.towerGrounds, AmbienceAccent.ravenCalls), // Tower of London, 5:00 PM
  'ep06': (AmbienceBase.londonNight, AmbienceAccent.fountain), // Covent Garden, 11:55 PM: the piazza with its fountain
  'ep07': (AmbienceBase.park, null), // Hyde Park, 7:00 AM
  'ep08': (AmbienceBase.station, null), // King's Cross, 9:00 PM
  'ep09': (AmbienceBase.londonDay, null), // Buckingham Palace, 10:00 AM
  'ep10': (AmbienceBase.towerGrounds, AmbienceAccent.ravenCalls), // Tower of London, 7:00 AM
  // Covent Garden, 10:30 PM: the narration is inside the theatre ("The show
  // is over… in Row R, Seat 17"), whatever the street picture shows.
  'ep11': (AmbienceBase.grandInterior, null),
  'ep12': (AmbienceBase.londonNight, null), // London, 11:00 PM: one hour left
};

/// Where each mission and final case happens.
const season1Places = <String, SoundPlace>{
  // Case 01 — one night across London.
  'm01': (AmbienceBase.station, null), // KING'S CROSS
  'm02': (AmbienceBase.grandInterior, null), // BRITISH MUSEUM
  'm03': (AmbienceBase.londonNight, null), // BIG BEN, the box at its foot: a street at night, no river
  'm04': (AmbienceBase.park, null), // HYDE PARK at night (PARK_NIGHT_VARIANT_REQUIRED)
  'm05': (AmbienceBase.londonNight, null), // BUCKINGHAM PALACE, at the gate
  'final': (AmbienceBase.stoneRoom, null), // THE ROYAL ARCHIVE, down the stairs
  // Case 02 — inside the stopped clock: no clockwork until it runs again.
  'ep02_m1': (AmbienceBase.river, null), // WESTMINSTER BRIDGE
  'ep02_m2': (AmbienceBase.towerInterior, null), // THE CLOCK ROOM
  'ep02_m3': (AmbienceBase.towerInterior, null), // THE BELFRY
  'ep02_final': (AmbienceBase.towerInterior, null), // INSIDE BIG BEN
  // Case 03 — the museum, then out into the street.
  'ep03_m1': (AmbienceBase.grandInterior, null), // GALLERY 8
  'ep03_m2': (AmbienceBase.grandInterior, null), // THE EGYPT ROOM
  'ep03_m3': (AmbienceBase.grandInterior, null), // THE GREAT COURT
  'ep03_final': (AmbienceBase.londonDay, null), // MUSEUM STREET
  // Case 04 — King's Cross, then the last train.
  'ep04_m1': (AmbienceBase.smallInterior, null), // LOST PROPERTY, the office
  'ep04_m2': (AmbienceBase.station, null), // THE PLATFORMS
  'ep04_m3': (AmbienceBase.station, null), // PLATFORM 4
  'ep04_final': (AmbienceBase.trainCarriage, null), // THE LAST TRAIN
  // Case 05 — the Tower: its green, then the locked rooms.
  'ep05_m1': (AmbienceBase.towerGrounds, AmbienceAccent.ravenCalls), // TOWER GREEN
  'ep05_m2': (AmbienceBase.stoneRoom, null), // THE WHITE TOWER, the dial door
  'ep05_m3': (AmbienceBase.stoneRoom, AmbienceAccent.ravenCalls), // THE RAVEN ROOM, a raven at the window
  'ep05_final': (AmbienceBase.stoneRoom, null), // THE LOCKED ROOM
  // Case 06 — Covent Garden at midnight.
  'ep06_m1': (AmbienceBase.smallInterior, null), // THE MARKET HALL, inside, closing: no fountain
  'ep06_m2': (AmbienceBase.londonNight, AmbienceAccent.fountain), // THE FOUNTAIN
  'ep06_m3': (AmbienceBase.grandInterior, null), // THE THEATRE DOOR, inside the dark theatre
  'ep06_final': (AmbienceBase.londonNight, AmbienceAccent.fountain), // MIDNIGHT, by the fountain
  // Case 07 — Hyde Park all morning.
  'ep07_m1': (AmbienceBase.park, null), // THE PARK GATE
  'ep07_m2': (AmbienceBase.boathouseInterior, null), // THE BOATHOUSE, inside (BOATHOUSE_INTERIOR_REQUIRED)
  'ep07_m3': (AmbienceBase.park, null), // THE ROSE GARDEN
  'ep07_final': (AmbienceBase.park, null), // THE PARK PATHS
  // Case 08 — King's Cross at night.
  'ep08_m1': (AmbienceBase.station, null), // PLATFORM 9
  'ep08_m2': (AmbienceBase.smallInterior, null), // THE WAITING ROOM
  'ep08_m3': (AmbienceBase.smallInterior, null), // THE STATION OFFICE
  'ep08_final': (AmbienceBase.station, null), // THE 9:30 TO EDINBURGH
  // Case 09 — inside the palace, then its courtyard and gate.
  'ep09_m1': (AmbienceBase.grandInterior, null), // THE JEWEL ROOM
  'ep09_m2': (AmbienceBase.smallInterior, null), // THE STAFF ROOM
  'ep09_m3': (AmbienceBase.londonDay, AmbienceAccent.guardMarch), // THE COURTYARD, the guard changing
  'ep09_final': (AmbienceBase.londonDay, null), // THE PALACE GATE
  // Case 10 — the Tower, then the river.
  'ep10_m1': (AmbienceBase.towerGrounds, AmbienceAccent.ravenCalls), // TOWER GREEN
  'ep10_m2': (AmbienceBase.towerGrounds, AmbienceAccent.ravenCalls), // THE WALL WALK
  'ep10_m3': (AmbienceBase.towerGrounds, null), // BY THE RIVER: seen from the Tower wall, far below
  'ep10_final': (AmbienceBase.river, null), // TOWER BRIDGE
  // Case 11 — the theatre, the street, the station.
  'ep11_m1': (AmbienceBase.grandInterior, null), // THE THEATRE
  'ep11_m2': (AmbienceBase.smallInterior, null), // BEHIND THE STAGE, the dressing room
  'ep11_m3': (AmbienceBase.londonNight, null), // THE STAGE DOOR
  'ep11_final': (AmbienceBase.station, null), // PLATFORM 9
  // Case 12 — midnight: the clock running this time.
  'ep12_m1': (AmbienceBase.towerInterior, AmbienceAccent.clockMechanism), // BIG BEN, inside
  'ep12_m2': (AmbienceBase.station, null), // KING'S CROSS
  'ep12_m3': (AmbienceBase.towerGrounds, AmbienceAccent.ravenCalls), // THE TOWER OF LONDON
  'ep12_final': (AmbienceBase.stoneRoom, null), // UNDER BIG BEN
};

/// Places that change once their final case is solved: Big Ben's clockwork
/// runs again after Case 02 (in the scene after the case).
const season1SolvedAccents = <String, AmbienceAccent>{'ep02_final': AmbienceAccent.clockMechanism};

/// Scenes whose place is mapped right but whose recording is not yet the
/// right one, or whose place is not recorded at all. The scenes stay as
/// they are (or silent) until it is made: a wrong sound is worse than none.
const season1AmbienceRequired = <String, String>{
  'm04': 'PARK_NIGHT_VARIANT_REQUIRED', // Hyde Park at night: the park bed has day birds
  'ep07_m2': 'BOATHOUSE_INTERIOR_REQUIRED',
};

/// Where [m] happens, or null for a mission outside this table.
SoundPlace? soundPlaceOf(Mission m) => season1Places[m.id];

/// Where the case [episodeId] opens.
SoundPlace? introSoundPlaceOf(String episodeId) => season1IntroPlaces[episodeId];
