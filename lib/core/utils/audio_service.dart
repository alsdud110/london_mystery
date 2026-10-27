import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'audio_scene.dart';

export 'audio_scene.dart';

/// One recorded take of a sound (under `assets/sounds/`) and the volume it
/// plays at, so takes recorded louder or softer sit at the same level.
///
/// `generated/` holds the takes as ElevenLabs made them (never edited);
/// `processed/` holds copies made from them for the app (trimmed, levelled).
@immutable
class SoundFile {
  const SoundFile(this.file, [this.volume = 1]);

  final String file;

  /// 0..1 (audioplayers cannot play louder than the file itself).
  final double volume;

  String get assetPath => 'sounds/$file';

  @override
  bool operator ==(Object other) => other is SoundFile && other.file == file && other.volume == volume;

  @override
  int get hashCode => Object.hash(file, volume);
}

/// Every sound the game can play: one or more takes of it. A sound with
/// several takes plays one of them at random, never the same twice in a
/// row, so a sound heard all season (the envelope, the dial) does not wear.
///
/// Volumes level the takes against each other (measured on their loudest
/// 100 ms, about -24 dBFS for a puzzle sound).
///
/// A sound with no take is still played where its moment comes (and its
/// haptic still felt), it is simply not heard: adding its file here is all
/// it takes to hear it. For now only the typing and the casebook tap sound.
enum GameSound {
  /// An old envelope opened by hand: the seal, the flap, the letter out
  /// (TAP TO OPEN).
  envelopeOpen([]),

  /// A regular puzzle solved: a small clue falling into place, dark and
  /// quiet, not a reward.
  puzzleCorrect([]),

  /// Not quite.
  puzzleWrong([]),

  /// One notch of a lock's number wheel (keypad digits, the final's dials).
  lockDialClick([]),

  /// A real lock opening (a box, a suitcase; a new place on the map).
  padlockOpen([]),

  /// A card or a piece of paper laid down on the desk.
  paperPlace([]),

  /// The rubber stamp coming down on a case file (CASE CLOSED, ASSIGNED).
  caseStamp([]),

  /// One key of a heavy old typewriter, under the story as it is typed:
  /// its strike and short body, cut before the key comes back up. Below the
  /// puzzle sounds (about -33 dBFS), so a long story does not tire.
  typewriterKey([
    SoundFile('processed/typewriter_key_v4_01.wav', 0.21),
    SoundFile('processed/typewriter_key_v4_02.wav', 0.29),
    SoundFile('processed/typewriter_key_v4_03.wav', 0.23),
    SoundFile('processed/typewriter_key_v4_04.wav', 0.24),
  ]),

  /// A finger on the casebook: a soft, dry tap of heavy paper card over
  /// leather, for the buttons that move the investigation on (never with a
  /// sound of the world, never on story taps or Back). One family of three
  /// takes, cut to the tap and its body (160 ms) and levelled to each other
  /// in the phone band, just above the typing at full volume. How loud a
  /// button taps is its [TapRole]. Provisional, listening pending.
  uiTap([
    SoundFile('processed/ui_tap_01.wav', 0.25),
    SoundFile('processed/ui_tap_02.wav', 0.38),
    SoundFile('processed/ui_tap_03.wav', 0.4),
  ]),

  /// A final case solved, where the case has no sound of its own (see the
  /// signatures below).
  finale([]),

  // Signatures of the world. Each is the one physical event of its moment:
  // no casebook tap, no cue with it.

  /// Case 01: the Royal Box opens, its brass latch then its lid (as the lid
  /// lifts on screen). Instead of the final cue.
  royalBoxOpen([]),

  /// Case 02: the Great Clock catches and runs again (no bell in it).
  clockRestart([]),

  /// Case 02: Big Ben rings again, one deep strike and its long decay.
  bigBenBell([]),

  /// A heavy iron lock and its bolt (the White Tower's dial door, the iron
  /// chest, the Clockmaker's door). Small locks keep [padlockOpen].
  lockOpenHeavy([]),

  /// The detective's leather notebook opened (once per opening).
  notebookOpen([]),

  /// A tip written into the notebook, asked for by the player.
  pencilNote([]),

  /// A paper handled to be read again (the letter re-read).
  paperRustle([]),

  /// A case photo pinned to the investigation board as it is solved.
  pinPush([]);

  const GameSound(this.takes);

  final List<SoundFile> takes;
}

/// How firmly a button taps ([GameSound.uiTap]): the same tap, softer for
/// lesser actions.
enum TapRole {
  /// The screen's one primary action (START ADVENTURE, GO, INVESTIGATE).
  primary(1),

  /// A secondary action (VIEW ALL CASE FILES, OPEN MY NOTEBOOK): -3 dB.
  secondary(0.71),

  /// Choosing from a list (a case on the case files page): -6 dB.
  select(0.5);

  const TapRole(this.volume);

  final double volume;
}

/// The loops that exist for each music theme, place and place detail. A
/// theme or place without one is still the scene's state (it is followed,
/// compared, kept), it is simply not heard yet: adding its file here is
/// all it takes to hear it.
const musicLoops = <MusicTheme, SoundFile>{};

const ambienceLoops = <AmbienceBase, SoundFile>{};

/// Details over a place's bed.
const accentLoops = <AmbienceAccent, SoundFile>{};

/// The loop of [layer]'s [state] (a [MusicTheme], [AmbienceBase] or
/// [AmbienceAccent]), or null when there is none (yet).
SoundFile? loopOf(AudioLayer layer, Enum? state) => switch (layer) {
  AudioLayer.music => musicLoops[state],
  AudioLayer.ambience => ambienceLoops[state],
  AudioLayer.accent => accentLoops[state],
};

/// Plays game sounds. Implementations must never throw: sound is optional
/// and must not break play.
abstract interface class AudioService {
  /// Plays one take of [sound], [volume] (0..1) times its own level.
  Future<void> play(GameSound sound, {double volume = 1});

  /// Cuts off [sound] wherever it is still sounding (a story's typing that
  /// has stopped).
  void stop(GameSound sound);

  /// What the page in front of the player should sound like. Only the
  /// layers that differ from what is playing change ([transition] says how);
  /// the same scene again changes nothing.
  void setScene(AudioScene scene, {AudioTransition transition = AudioTransition.normal});

  /// Lowers the music by [db] for [hold], then brings it back (a major
  /// moment that must be heard over it). Not for everyday sounds.
  void duckMusic(double db, {required Duration hold});

  /// The app went to the background (false) or came back (true).
  void setForeground(bool foreground);

  /// Sound was switched on or off: start or stop the lasting layers to match.
  void refresh();

  void dispose();
}

/// What every audio service shares, whatever plays the files: nothing
/// plays while sound is off or the app is in the background, takes are
/// chosen without repeating, and the lasting layers (music, place, detail)
/// follow the scene layer by layer while sound is on and the app in front.
abstract class GatedAudioService implements AudioService {
  GatedAudioService({bool Function()? isEnabled, math.Random? random})
    : isEnabled = isEnabled ?? _on,
      _random = random ?? math.Random();

  static bool _on() => true;

  /// Coming back (app in front again, sound on again): the layers fade in.
  static const restore = Duration(milliseconds: 1200);

  /// Sound switched off: the layers fade out.
  static const silence = Duration(milliseconds: 600);

  /// A duck comes in this fast, and goes back this slowly.
  static const duckIn = Duration(milliseconds: 300);
  static const duckOut = Duration(milliseconds: 600);

  final bool Function() isEnabled;
  final math.Random _random;
  final Map<GameSound, int> _lastTake = {};
  bool _foreground = true;

  /// The scene the game wants, and the scene the layers are in now (silence
  /// while sound is off or the app away).
  AudioScene _target = AudioScene.silence;
  AudioScene _active = AudioScene.silence;

  /// The music's duck now (dB), and which duck may release it.
  double _duck = 0;
  int _duckToken = 0;
  Timer? _duckTimer;

  AudioScene get target => _target;
  AudioScene get active => _active;

  /// The place playing now (null: silence).
  AmbienceBase? get ambience => _active.ambienceBase;

  /// The music theme playing now (null: none).
  MusicTheme? get music => _active.music;

  @override
  Future<void> play(GameSound sound, {double volume = 1}) async {
    if (!isEnabled() || !_foreground || sound.takes.isEmpty) return;
    final take = sound.takes[_pickTake(sound)];
    await playFile(sound, take, (take.volume * volume).clamp(0.0, 1.0));
  }

  int _pickTake(GameSound sound) {
    final count = sound.takes.length;
    if (count == 1) return 0;
    final last = _lastTake[sound];
    var i = _random.nextInt(last == null ? count : count - 1);
    if (last != null && i >= last) i++;
    return _lastTake[sound] = i;
  }

  @override
  void setScene(AudioScene scene, {AudioTransition transition = AudioTransition.normal}) {
    _target = scene;
    _apply(transition);
  }

  @override
  void setForeground(bool foreground) {
    _foreground = foreground;
    refresh();
  }

  @override
  void refresh() {
    // Typing still sounding stops with the sound or the app.
    if (!isEnabled() || !_foreground) stop(GameSound.typewriterKey);
    _apply(AudioTransition.normal);
  }

  @override
  void duckMusic(double db, {required Duration hold}) {
    final token = ++_duckToken;
    _duckTimer?.cancel();
    _duck = db;
    _levelMusic(duckIn);
    _duckTimer = Timer(hold, () {
      if (token != _duckToken) return; // a newer duck holds the music
      _duck = 0;
      _levelMusic(duckOut);
    });
  }

  void _levelMusic(Duration fade) {
    if (_active.music == null) return;
    applyLevel(AudioLayer.music, _volume(AudioLayer.music, _active), fade);
  }

  static double _gain(double db) => math.pow(10, db / 20).toDouble();

  /// The playing volume (0..1) of [layer] in [scene]: its loop's own level,
  /// the scene's level for it and, for the music, the duck.
  double _volume(AudioLayer layer, AudioScene scene) {
    final (state, db) = _layer(layer, scene);
    final own = loopOf(layer, state)?.volume ?? 1;
    final duck = layer == AudioLayer.music ? _duck : 0;
    return (own * _gain(db + duck)).clamp(0.0, 1.0);
  }

  static (Enum?, double) _layer(AudioLayer layer, AudioScene s) => switch (layer) {
    AudioLayer.music => (s.music, s.musicLevel),
    AudioLayer.ambience => (s.ambienceBase, s.ambienceLevel),
    AudioLayer.accent => (s.ambienceAccent, s.accentLevel),
  };

  /// Brings the layers from the active scene to the one wanted, layer by
  /// layer: a layer whose theme / place / detail is the same keeps playing
  /// (only its level moves, if it changed); a different one crosses over.
  void _apply(AudioTransition transition) {
    if (!_foreground) {
      // Leaving the app: at once (timers may not run in the background).
      if (_active != AudioScene.silence) stopLayersNow();
      _active = AudioScene.silence;
      return;
    }
    final next = isEnabled() ? _target : AudioScene.silence;
    final from = _active;
    if (next == from) return;
    final restoring = from == AudioScene.silence;
    final silencing = next == AudioScene.silence;
    _active = next;
    for (final layer in AudioLayer.values) {
      final (was, wasDb) = _layer(layer, from);
      final (now, nowDb) = _layer(layer, next);
      final fade = restoring
          ? restore
          : silencing
          ? silence
          : layer == AudioLayer.music
          ? transition.music
          : transition.ambience;
      if (was != now) {
        applyLayer(layer, now, loopOf(layer, now), _volume(layer, next), fade);
      } else if (now != null && wasDb != nowDb) {
        applyLevel(layer, _volume(layer, next), fade);
      }
    }
  }

  /// Plays [take] of [sound] at [volume].
  @protected
  Future<void> playFile(GameSound sound, SoundFile take, double volume);

  /// Crosses [layer] over to [state] ([loop] its file, null when there is
  /// none yet or [state] is null: then the layer only fades out), reaching
  /// [volume] over [fade].
  @protected
  void applyLayer(AudioLayer layer, Enum? state, SoundFile? loop, double volume, Duration fade);

  /// Moves [layer]'s volume (same loop, not restarted).
  @protected
  void applyLevel(AudioLayer layer, double volume, Duration fade);

  /// Stops every lasting layer at once.
  @protected
  void stopLayersNow();

  @mustCallSuper
  @override
  void dispose() {
    _duckTimer?.cancel();
    _duckToken++;
  }
}

/// One loop player a [LoopChannel] uses (an audioplayers player in the
/// app, a stand-in in tests).
abstract interface class LoopPlayer {
  /// Starts [loop] looping, silent.
  Future<void> start(SoundFile loop);

  Future<void> setVolume(double volume);

  double get volume;

  Future<void> stop();

  void dispose();
}

class _AudioLoopPlayer implements LoopPlayer {
  final AudioPlayer _player = AudioPlayer();

  @override
  Future<void> start(SoundFile loop) async {
    await _player.setReleaseMode(ReleaseMode.loop);
    await _player.play(AssetSource(loop.assetPath), volume: 0);
  }

  @override
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  @override
  double get volume => _player.volume;

  @override
  Future<void> stop() => _player.stop();

  @override
  void dispose() => _player.dispose();
}

/// One lasting layer: the loop playing now, and the ones fading out after
/// a crossover. Each change takes a new token, so a loop that finishes
/// loading after a newer change only retires itself; every player made is
/// retired (stopped, disposed) once it is silent or no longer wanted.
class LoopChannel {
  LoopChannel([LoopPlayer Function()? create]) : _create = create ?? _AudioLoopPlayer.new;

  final LoopPlayer Function() _create;

  static const _step = Duration(milliseconds: 50);

  LoopPlayer? _current;
  SoundFile? _loop;
  int _token = 0;
  final Set<LoopPlayer> _live = {};
  final Map<LoopPlayer, Timer> _fades = {};

  /// The loop this channel is playing (or loading).
  SoundFile? get loop => _loop;

  /// Players not yet retired (the current one and those fading out).
  int get players => _live.length;

  /// Crosses over to [loop] at [volume] over [fade]: the old loop fades out
  /// while the new one fades in. The same loop only moves its volume.
  void switchTo(SoundFile? loop, double volume, Duration fade) {
    if (loop != null && loop == _loop) return setVolume(volume, fade);
    final token = ++_token;
    final old = _current;
    _current = null;
    _loop = loop;
    if (old != null) _fade(old, 0, fade, then: () => _retire(old));
    if (loop == null) return;
    final player = _create();
    _live.add(player);
    _current = player;
    player.start(loop).then((_) {
      if (token != _token || _current != player) return _retire(player);
      _fade(player, volume, fade);
    }).catchError((Object e) {
      debugPrint('Loop ${loop.file} could not play: $e');
      if (_current == player) _current = null;
      _retire(player);
    });
  }

  /// Moves the playing loop's volume (it is not restarted).
  void setVolume(double volume, Duration fade) {
    final player = _current;
    if (player != null) _fade(player, volume, fade);
  }

  /// Everything stops now (the app going away).
  void stopNow() {
    _token++;
    _current = null;
    _loop = null;
    for (final p in [..._live]) {
      _retire(p);
    }
  }

  void _fade(LoopPlayer player, double target, Duration over, {void Function()? then}) {
    _fades.remove(player)?.cancel();
    if (!_live.contains(player)) return;
    final steps = over.inMilliseconds ~/ _step.inMilliseconds;
    if (steps <= 0) {
      player.setVolume(target).catchError((Object _) {});
      then?.call();
      return;
    }
    final from = player.volume;
    var step = 0;
    _fades[player] = Timer.periodic(_step, (timer) {
      if (!_live.contains(player)) return timer.cancel();
      step++;
      player.setVolume((from + (target - from) * step / steps).clamp(0.0, 1.0)).catchError((Object _) {});
      if (step >= steps) {
        timer.cancel();
        _fades.remove(player);
        then?.call();
      }
    });
  }

  void _retire(LoopPlayer player) {
    if (!_live.remove(player)) return;
    _fades.remove(player)?.cancel();
    if (_current == player) _current = null;
    player.stop().catchError((Object _) {}).whenComplete(player.dispose);
  }

  void dispose() => stopNow();
}

/// Plays bundled assets with audioplayers: one player per sound (a quick
/// repeat restarts it instead of stacking), and one [LoopChannel] per
/// lasting layer. Sounds that come many times a second (typing, dial
/// clicks) play from a small pool of players per take instead, so they
/// overlap a little and never wait for a player to be made.
class AssetAudioService extends GatedAudioService {
  AssetAudioService({required super.isEnabled}) {
    for (final sound in _pooled) {
      for (final take in sound.takes) {
        _pool(take);
      }
    }
    // Copied out of the bundle once, so the first tap is not late.
    AudioCache.instance
        .loadAll([
          for (final s in GameSound.values) ...s.takes.map((t) => t.assetPath),
          for (final loops in [musicLoops, ambienceLoops, accentLoops]) ...loops.values.map((l) => l.assetPath),
        ])
        .catchError((Object e) {
          debugPrint('Sounds could not be preloaded: $e');
          return <Uri>[];
        });
  }

  static const _felt = {
    GameSound.puzzleCorrect,
    GameSound.padlockOpen,
    GameSound.caseStamp,
    GameSound.finale,
    GameSound.royalBoxOpen,
    GameSound.clockRestart,
    GameSound.lockOpenHeavy,
  };
  static const _pooled = {GameSound.typewriterKey, GameSound.lockDialClick};

  final Map<GameSound, AudioPlayer> _players = {};
  final Map<String, Future<AudioPool>> _pools = {};

  /// How to cut off what a pooled sound still has sounding.
  final Map<GameSound, List<StopFunction>> _sounding = {};

  final Map<AudioLayer, LoopChannel> _channels = {for (final l in AudioLayer.values) l: LoopChannel()};

  @override
  Future<void> play(GameSound sound, {double volume = 1}) {
    // Felt even with the sound off.
    if (_felt.contains(sound)) HapticFeedback.mediumImpact();
    return super.play(sound, volume: volume);
  }

  Future<AudioPool> _pool(SoundFile take) => _pools.putIfAbsent(
        take.assetPath,
        () => AudioPool.createFromAsset(path: take.assetPath, maxPlayers: 3),
      );

  @override
  Future<void> playFile(GameSound sound, SoundFile take, double volume) async {
    try {
      if (_pooled.contains(sound)) {
        final stop = await (await _pool(take)).start(volume: volume);
        final sounding = _sounding.putIfAbsent(sound, () => []);
        sounding.add(stop);
        if (sounding.length > 4) sounding.removeAt(0); // long finished
        return;
      }
      final player = _players.putIfAbsent(sound, () => AudioPlayer()..setReleaseMode(ReleaseMode.stop));
      await player.stop();
      await player.play(AssetSource(take.assetPath), volume: volume);
    } catch (e) {
      debugPrint('Sound ${sound.name} could not play: $e');
    }
  }

  @override
  void stop(GameSound sound) {
    for (final stop in _sounding.remove(sound) ?? const <StopFunction>[]) {
      stop().catchError((Object _) {});
    }
    _players[sound]?.stop().catchError((Object _) {});
  }

  @override
  void applyLayer(AudioLayer layer, Enum? state, SoundFile? loop, double volume, Duration fade) =>
      _channels[layer]!.switchTo(loop, volume, fade);

  @override
  void applyLevel(AudioLayer layer, double volume, Duration fade) => _channels[layer]!.setVolume(volume, fade);

  @override
  void stopLayersNow() {
    for (final c in _channels.values) {
      c.stopNow();
    }
  }

  @override
  void dispose() {
    super.dispose();
    for (final p in _players.values) {
      p.dispose();
    }
    _players.clear();
    for (final pool in _pools.values) {
      pool.then((p) => p.dispose()).catchError((Object _) {});
    }
    _pools.clear();
    _sounding.clear();
    for (final c in _channels.values) {
      c.dispose();
    }
  }
}

/// Silent stand-in (tests, previews). Plays nothing but follows the same
/// rules as the real service (sound off, takes, scenes layer by layer), and
/// records what would have happened so behaviour can be checked.
class MockAudioService extends GatedAudioService {
  MockAudioService({super.isEnabled, super.random});

  /// Every sound played at its moment, heard or not (one with no take yet).
  final List<GameSound> played = [];

  /// The take and volume of each sound of [played] that was heard.
  final List<(SoundFile, double)> takes = [];

  /// Every sound cut off, in order.
  final List<GameSound> stopped = [];

  /// Every scene asked for, with how.
  final List<(AudioScene, AudioTransition)> scenes = [];

  /// Every crossover of a layer (to a new state, or to nothing), in order.
  final List<({AudioLayer layer, Enum? to, double volume, Duration fade})> changes = [];

  /// Every level move of a layer that kept playing.
  final List<({AudioLayer layer, double volume, Duration fade})> levels = [];

  /// Every duck asked for.
  final List<({double db, Duration hold})> ducks = [];

  /// How many times everything was stopped at once.
  int stopsNow = 0;

  /// The places started, in order (a fresh start each time).
  List<AmbienceBase> get ambienceStarts => [
    for (final c in changes)
      if (c.layer == AudioLayer.ambience && c.to != null) c.to! as AmbienceBase,
  ];

  /// The crossovers of [layer] only.
  List<Enum?> changesOf(AudioLayer layer) => [
    for (final c in changes)
      if (c.layer == layer) c.to,
  ];

  @override
  Future<void> play(GameSound sound, {double volume = 1}) async {
    if (sound.takes.isEmpty && isEnabled() && _foreground) played.add(sound);
    return super.play(sound, volume: volume);
  }

  @override
  Future<void> playFile(GameSound sound, SoundFile take, double volume) async {
    played.add(sound);
    takes.add((take, volume));
  }

  @override
  void stop(GameSound sound) => stopped.add(sound);

  @override
  void setScene(AudioScene scene, {AudioTransition transition = AudioTransition.normal}) {
    scenes.add((scene, transition));
    super.setScene(scene, transition: transition);
  }

  @override
  void duckMusic(double db, {required Duration hold}) {
    ducks.add((db: db, hold: hold));
    super.duckMusic(db, hold: hold);
  }

  @override
  void applyLayer(AudioLayer layer, Enum? state, SoundFile? loop, double volume, Duration fade) =>
      changes.add((layer: layer, to: state, volume: volume, fade: fade));

  @override
  void applyLevel(AudioLayer layer, double volume, Duration fade) =>
      levels.add((layer: layer, volume: volume, fade: fade));

  @override
  void stopLayersNow() => stopsNow++;
}
