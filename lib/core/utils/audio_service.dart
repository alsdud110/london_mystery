import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Every sound the game can play. To replace a sound, drop a new file into
/// `assets/sounds/` and change its file name here (.wav, .mp3 and .ogg work).
enum GameSound {
  tap('tap.wav'),
  success('success.wav'),
  wrong('wrong.wav'),
  unlock('unlock.wav'),
  clue('clue.wav'),
  finale('final.wav');

  const GameSound(this.file);
  final String file;

  String get assetPath => 'sounds/$file';
}

/// Plays game sounds. Implementations must never throw: sound is optional
/// and must not break play.
abstract interface class AudioService {
  Future<void> play(GameSound sound);

  void dispose();
}

/// Plays bundled assets with audioplayers (one player per sound, so quick
/// repeats restart instead of stacking).
class AssetAudioService implements AudioService {
  AssetAudioService({required this.isEnabled});

  final bool Function() isEnabled;
  final Map<GameSound, AudioPlayer> _players = {};

  @override
  Future<void> play(GameSound sound) async {
    if (sound == GameSound.success || sound == GameSound.finale || sound == GameSound.unlock) {
      HapticFeedback.mediumImpact();
    }
    if (!isEnabled()) return;
    try {
      final player = _players.putIfAbsent(sound, () => AudioPlayer()..setReleaseMode(ReleaseMode.stop));
      await player.stop();
      await player.play(AssetSource(sound.assetPath), volume: 0.8);
    } catch (e) {
      debugPrint('Sound ${sound.name} could not play: $e');
    }
  }

  @override
  void dispose() {
    for (final p in _players.values) {
      p.dispose();
    }
    _players.clear();
  }
}

/// Silent stand-in (tests, previews, or before real audio exists).
/// Records what would have played so behaviour can be checked.
class MockAudioService implements AudioService {
  MockAudioService();

  final List<GameSound> played = [];

  @override
  Future<void> play(GameSound sound) async => played.add(sound);

  @override
  void dispose() {}
}
