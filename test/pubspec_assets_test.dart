import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// How the tests read pubspec.yaml's `flutter: assets:` list
/// ([pubspecAssetsOf]): by its structure, the same with LF and CRLF line
/// endings (a Windows checkout with `core.autocrlf` has CRLF), so a missing
/// or misspelt folder still fails and nothing else does.
void main() {
  const lf = '''
name: app
dependencies:
  flutter:
    sdk: flutter
  - assets/not/an/asset/
flutter:
  uses-material-design: true
  assets:
    # A comment, then the list.
    - assets/seasons/season_02_paris/cases/case_02/
    - assets/sounds/final.wav   # a file, with a note

    - "assets/quoted/"
  fonts:
    - family: Sentient
      fonts:
        - asset: assets/fonts/Sentient-Variable.ttf
flutter_launcher_icons:
  - assets/not/an/asset/either/
''';
  const listed = ['assets/seasons/season_02_paris/cases/case_02/', 'assets/sounds/final.wav', 'assets/quoted/'];

  test('the list is read by its structure: only flutter: assets:, comments and other keys left out', () {
    expect(pubspecAssetsOf(lf), listed);
  });

  test('CRLF reads exactly as LF', () {
    expect(pubspecAssetsOf(lf.replaceAll('\n', '\r\n')), listed);
    expect(pubspecAssetsOf(lf.replaceAll('\n', '\r\n')), pubspecAssetsOf(lf));
  });

  test('a folder not listed, or listed under another name, is not there', () {
    final read = pubspecAssetsOf(lf);
    expect(read, isNot(contains('assets/seasons/season_02_paris/cases/case_03/')), reason: 'missing');
    expect(read, isNot(contains('assets/seasons/season_02_paris/cases/case_0/')), reason: 'only a prefix');
    expect(read, isNot(contains('assets/seasons/season_02_paris/cases/case_02')), reason: 'a folder entry keeps its /');
    final misspelt = pubspecAssetsOf(lf.replaceAll('case_02/', 'case_2/'));
    expect(misspelt, isNot(contains('assets/seasons/season_02_paris/cases/case_02/')));
  });

  test('an entry that names nothing on disk is found', () {
    expect(missingAssets(['assets/seasons/season_02_paris/cases/case_02/', 'assets/sounds/final.wav']), isEmpty);
    expect(missingAssets(['assets/seasons/season_02_paris/cases/case_99/', 'assets/sounds/nothing.wav']),
        ['assets/seasons/season_02_paris/cases/case_99/', 'assets/sounds/nothing.wav']);
    expect(missingAssets(['assets/sounds/final.wav/']), ['assets/sounds/final.wav/'], reason: 'a file is not a folder');
  });

  test("the game's pubspec: its list is read whatever its line endings, and every entry is on disk", () {
    final text = File('pubspec.yaml').readAsStringSync();
    final assets = pubspecAssets();
    expect(assets, isNotEmpty);
    expect(pubspecAssetsOf(text.replaceAll('\r\n', '\n')), assets);
    expect(pubspecAssetsOf(text.replaceAll('\r\n', '\n').replaceAll('\n', '\r\n')), assets);
    for (var n = 1; n <= 7; n++) {
      expect(assets, contains('assets/seasons/season_02_paris/cases/case_0$n/'));
    }
    expect(missingAssets(assets), isEmpty, reason: 'every listed folder and file exists');
    expect(assets.toSet(), hasLength(assets.length), reason: 'nothing listed twice');
  });
}
