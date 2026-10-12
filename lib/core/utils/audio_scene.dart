import 'package:flutter/foundation.dart';

/// The music themes of the game. A theme carries on across every page of
/// its part of the game; only its level changes from page to page.
enum MusicTheme {
  /// The detective's casebook: title, season, board, case files.
  casebook,

  /// A case under way: its story, the map, the missions.
  investigation,

  /// The final case of a case.
  finalMission,

  /// The case is closed: the scene after it and the closed file.
  resolution,
}

/// The place the detective is in, as it sounds: one shared bed per kind of
/// place. Chosen by what the player stands in and looks at on the screen,
/// not by the landmark nearby (Big Ben is by the river, but its foot is a
/// street at night).
enum AmbienceBase {
  officeRain,
  londonNight,
  londonDay,
  station,
  grandInterior,
  river,
  park,
  towerGrounds,
  stoneRoom,
  towerInterior,
  trainCarriage,

  /// A small, closed old room off a larger place (a station office, a
  /// waiting room, a staff room, backstage): quiet wooden room tone, little
  /// of the outside. Not recorded yet: silent until it is.
  smallInterior,

  /// The boathouse by the Serpentine: its own wooden, watery inside. Not
  /// recorded yet (a later wave, if needed): silent until it is.
  boathouseInterior,
}

/// A detail of one place, over its bed (Big Ben's clockwork over the
/// tower's inside, the fountain over the night market).
enum AmbienceAccent { clockMechanism, fountain, ravenCalls, guardMarch }

/// The three lasting layers of sound, each changed on its own.
enum AudioLayer { music, ambience, accent }

/// How a change of scene sounds.
enum AudioTransition {
  /// From page to page: a slow crossfade.
  normal(music: Duration(milliseconds: 2200), ambience: Duration(milliseconds: 1500)),

  /// Travelling to a place on the map: the places meet over the camera's
  /// move (about 1.2 s); the music, which does not change place, as usual.
  travel(music: Duration(milliseconds: 2200), ambience: Duration(milliseconds: 1200));

  const AudioTransition({required this.music, required this.ambience});

  final Duration music;
  final Duration ambience;
}

/// What should be heard on the page in front of the player: a declaration,
/// not a list of commands. The audio service compares it with what is
/// playing, layer by layer, and changes only what differs.
///
/// Levels are in dB relative to each sound's own level (0 = as made).
@immutable
class AudioScene {
  const AudioScene({
    this.music,
    this.musicLevel = 0,
    this.ambienceBase,
    this.ambienceLevel = 0,
    this.ambienceAccent,
    this.accentLevel = 0,
  });

  /// Nothing at all (grown-ups' pages; sound off; the app away).
  static const silence = AudioScene();

  final MusicTheme? music;
  final double musicLevel;
  final AmbienceBase? ambienceBase;
  final double ambienceLevel;
  final AmbienceAccent? ambienceAccent;
  final double accentLevel;

  @override
  bool operator ==(Object other) =>
      other is AudioScene &&
      other.music == music &&
      other.musicLevel == musicLevel &&
      other.ambienceBase == ambienceBase &&
      other.ambienceLevel == ambienceLevel &&
      other.ambienceAccent == ambienceAccent &&
      other.accentLevel == accentLevel;

  @override
  int get hashCode => Object.hash(music, musicLevel, ambienceBase, ambienceLevel, ambienceAccent, accentLevel);

  @override
  String toString() =>
      'AudioScene(${music?.name} ${musicLevel}dB · ${ambienceBase?.name} ${ambienceLevel}dB · ${ambienceAccent?.name} ${accentLevel}dB)';
}
