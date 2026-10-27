import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/core/utils/audio_service.dart';

/// The sound files: the app carries exactly the takes the game plays, listed
/// one by one in pubspec.yaml, and nothing else is kept on disk.
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

  test('only the typing and the casebook tap are heard, and only their takes are on disk', () {
    expect({for (final s in GameSound.values) if (s.takes.isNotEmpty) s}, {GameSound.typewriterKey, GameSound.uiTap});
    expect([...musicLoops.values, ...ambienceLoops.values, ...accentLoops.values], isEmpty);
    // Paths as the pubspec writes them ('/'), also on Windows ('\'); the
    // folder files an operating system leaves (macOS's .DS_Store, Windows'
    // Thumbs.db) are not the game's.
    const osFiles = {'.DS_Store', 'Thumbs.db', 'desktop.ini'};
    final onDisk = {
      for (final f in Directory('assets/sounds').listSync(recursive: true).whereType<File>())
        if (!osFiles.contains(f.uri.pathSegments.last)) f.path.replaceAll(r'\', '/'),
    };
    expect(onDisk, playedPaths);
  });
}
