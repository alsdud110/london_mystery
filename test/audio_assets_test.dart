import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/core/utils/audio_service.dart';

/// The sound files: the app carries exactly the takes the game plays, listed
/// one by one in pubspec.yaml. The other takes stay on disk, out of the app:
/// the ElevenLabs originals in `generated/` and the candidates kept for
/// listening.
void main() {
  final played = {
    for (final s in GameSound.values) ...s.takes,
    ...musicLoops.values,
    ...ambienceLoops.values,
    ...accentLoops.values,
  };
  final playedPaths = {for (final f in played) 'assets/${f.assetPath}'};

  /// The sound entries of pubspec.yaml's `flutter: assets:` list.
  Set<String> listedSounds() => {
        for (final m in RegExp(r'^\s+- (assets/sounds/\S*)\s*$', multiLine: true)
            .allMatches(File('pubspec.yaml').readAsStringSync()))
          m.group(1)!,
      };

  test('every sound the game plays is on disk', () {
    for (final f in played) {
      expect(File('assets/${f.assetPath}').existsSync(), isTrue, reason: f.file);
    }
  });

  test('the app carries exactly the sounds that are played, file by file', () {
    final listed = listedSounds();
    expect(listed.where((p) => p.endsWith('/')), isEmpty, reason: 'no whole sound folder: it would carry every kept take');
    expect(listed, playedPaths);
  });

  test('the takes kept for listening stay on disk', () {
    // Paths as the pubspec writes them ('/'), also on Windows ('\').
    final onDisk = {
      for (final f in Directory('assets/sounds').listSync(recursive: true).whereType<File>())
        if (f.path.endsWith('.wav')) f.path.replaceAll(r'\', '/'),
    };
    expect(onDisk.containsAll(playedPaths), isTrue);
    expect(onDisk.difference(playedPaths), isNotEmpty, reason: 'originals and candidates are kept, only not carried');
  });

  test('the top of assets/sounds holds only sounds that are played', () {
    final top = {
      for (final f in Directory('assets/sounds').listSync().whereType<File>())
        if (f.path.endsWith('.wav')) f.uri.pathSegments.last,
    };
    expect(top, {for (final f in played) if (!f.file.contains('/')) f.file});
    expect(top, {'final.wav'});
  });
}
