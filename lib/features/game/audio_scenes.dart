import '../../core/router/app_router.dart';
import '../../core/utils/audio_scene.dart';
import '../../data/mock/season1/season1_sounds.dart';
import '../../data/models/episode.dart';
import '../../data/models/game_progress.dart';
import '../../data/models/mission.dart';

/// Music levels (dB) by page: the theme carries on, only its level moves.
/// The places lead during a case; the music sits under the story.
abstract final class MusicLevels {
  static const casebook = 0.0;
  static const map = -4.0;
  static const mission = -6.0;
  static const story = -6.0;
  static const finalMission = -2.0;
  static const afterCase = -6.0; // the scene after the case is typed out
  static const caseClosed = -2.0;
}

/// Places sound lower under the map (still where the detective is).
const mapAmbienceLevel = -6.0;

/// The scene for the page at [path] (route [id] for a mission or story),
/// or null when the page keeps the scene under it (the notebook and the
/// QR scanner open over a mission, the map or a case). Pure: it only reads
/// the case, its progress and whether the season has begun.
AudioScene? audioSceneFor({
  required String path,
  String? id,
  required Episode episode,
  required GameProgress progress,
  required bool seasonBegun,
}) {
  AudioScene office(MusicTheme music, double level) =>
      AudioScene(music: music, musicLevel: level, ambienceBase: AmbienceBase.officeRain);

  AudioScene at(SoundPlace? place, MusicTheme music, double musicLevel, {double placeLevel = 0}) => AudioScene(
    music: music,
    musicLevel: musicLevel,
    ambienceBase: place?.$1,
    ambienceLevel: placeLevel,
    ambienceAccent: place?.$2,
    accentLevel: placeLevel,
  );

  Mission? mission(String? id) => id == null ? null : episode.missionById(id);

  switch (path) {
    case Routes.start || Routes.register || Routes.episodes:
      return office(MusicTheme.casebook, MusicLevels.casebook);
    case Routes.season:
      // The board is on the office desk; before the season begins the page
      // is its cover, London at night.
      return seasonBegun
          ? office(MusicTheme.casebook, MusicLevels.casebook)
          : const AudioScene(music: MusicTheme.casebook, ambienceBase: AmbienceBase.londonNight);
    case Routes.prologue:
      return const AudioScene(music: MusicTheme.casebook, ambienceBase: AmbienceBase.londonNight);
    case Routes.intro:
      return at(introSoundPlaceOf(episode.id), MusicTheme.investigation, MusicLevels.story);
    case Routes.map:
      return at(_whereNow(episode, progress), MusicTheme.investigation, MusicLevels.map, placeLevel: mapAmbienceLevel);
    case Routes.finalMission:
      // Solved (just now, or back at it): its after-case music, and the
      // place as the solve left it (Big Ben's clock running again).
      final place = soundPlaceOf(episode.finalMission);
      final solvedAccent = progress.isCaseSolved ? season1SolvedAccents[episode.finalMission.id] : null;
      return at(
        place == null ? null : (place.$1, solvedAccent ?? place.$2),
        progress.isCaseSolved ? MusicTheme.resolution : MusicTheme.finalMission,
        progress.isCaseSolved ? MusicLevels.afterCase : MusicLevels.finalMission,
      );
    case Routes.solved:
      return office(MusicTheme.resolution, MusicLevels.caseClosed);
    case Routes.notebook:
      return null; // over the page below: its scene goes on
    case Routes.report || Routes.gameMaster:
      return AudioScene.silence; // grown-ups' pages
  }
  if (path.startsWith('/mission/')) {
    final m = mission(id);
    return at(m == null ? null : soundPlaceOf(m), MusicTheme.investigation, MusicLevels.mission);
  }
  if (path.startsWith('/story/')) {
    final m = mission(id);
    if (m == null) return at(null, MusicTheme.investigation, MusicLevels.story);
    // The story after a final case closes it (the same page shows both).
    if (m.isFinal) {
      final place = soundPlaceOf(m);
      return at(
        place == null ? null : (place.$1, season1SolvedAccents[m.id] ?? place.$2),
        MusicTheme.resolution,
        MusicLevels.afterCase,
      );
    }
    return at(soundPlaceOf(m), MusicTheme.investigation, MusicLevels.story);
  }
  return null;
}

/// Where the detective is while looking at the map: the last place solved
/// in this case (the story ends there; the next place starts on GO), or
/// where the case opened.
SoundPlace? _whereNow(Episode episode, GameProgress progress) {
  for (final id in progress.completedMissionIds.reversed) {
    final m = episode.missionById(id);
    if (m == null) continue;
    final place = soundPlaceOf(m);
    if (m.isFinal && place != null) return (place.$1, season1SolvedAccents[m.id] ?? place.$2);
    return place;
  }
  return introSoundPlaceOf(episode.id);
}
