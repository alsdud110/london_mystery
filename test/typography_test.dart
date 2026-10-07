import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/core/theme/app_text.dart';
import 'package:london_mystery/core/theme/app_theme.dart';
import 'package:london_mystery/widgets/game_button.dart';
import 'package:london_mystery/widgets/paper.dart';

/// Two faces, two jobs: IM Fell English SC names the world (the season, a
/// case, a place, a document); Sentient is everything read or pressed.
void main() {
  test('the two families are bundled, the old ones are gone', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    for (final (family, file) in [
      ('Sentient', 'assets/fonts/Sentient-Variable.ttf'),
      ('IMFellEnglishSC', 'assets/fonts/IMFellEnglishSC-Regular.ttf'),
    ]) {
      expect(pubspec, contains('- family: $family'));
      expect(pubspec, contains('- asset: $file'));
      expect(File(file).existsSync(), isTrue, reason: file);
    }
    for (final old in ['Cinzel', 'Nunito', 'Fredoka']) {
      expect(pubspec, isNot(contains('- family: $old')), reason: old);
    }
    // No screen names a family of its own.
    for (final f in Directory('lib').listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      final s = f.readAsStringSync();
      for (final old in ["'Cinzel'", "'Nunito'", "'Fredoka'"]) {
        expect(s, isNot(contains(old)), reason: '${f.path}: $old');
      }
    }
  });

  test('Sentient is the default; the display face names the world', () {
    expect(AppText.body, 'Sentient');
    expect(AppText.display, 'IMFellEnglishSC');
    expect(AppTheme.light().textTheme.bodyMedium?.fontFamily ?? AppTheme.light().textTheme.bodyLarge?.fontFamily, 'Sentient');

    // Display (names, and the cinematic prompt): IM Fell, never emboldened.
    for (final s in [AppText.logo(), AppText.placeTitle(), AppText.mark(), AppText.cinematicPrompt()]) {
      expect(s.fontFamily, 'IMFellEnglishSC');
      expect(s.fontWeight, FontWeight.w400);
    }
    expect(AppText.style(AppText.display, weight: FontWeight.w800).fontWeight, FontWeight.w400);

    // Reading and action: Sentient, its weight on the variable axis.
    for (final (s, w) in [
      (AppText.bodyText(), FontWeight.w400),
      (AppText.caption(), FontWeight.w500),
      (AppText.letter(), FontWeight.w500),
      (AppText.title(), FontWeight.w600),
      (AppText.subtitle(), FontWeight.w600),
      (AppText.eyebrow(), FontWeight.w600),
      (AppText.button(), FontWeight.w600),
    ]) {
      expect(s.fontFamily, 'Sentient');
      expect(s.fontWeight, w);
      expect(s.fontVariations, [FontVariation('wght', w.value.toDouble())]);
    }
  });

  testWidgets('a place title is set in IM Fell; a button and a story line in Sentient', (t) async {
    await t.pumpWidget(MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(
        body: Column(children: [
          const PageHeading(eyebrow: 'MISSION 01', title: 'THE CLOCK ROOM', subtitle: 'The Missing Gear'),
          GameButton(label: 'SOLVE THE PUZZLE', onPressed: () {}),
          const Text('The huge gears have stopped moving.'),
        ]),
      ),
    ));
    TextStyle styleOf(String s) {
      final w = t.widget<Text>(find.text(s));
      return DefaultTextStyle.of(t.element(find.text(s))).style.merge(w.style);
    }

    expect(styleOf('THE CLOCK ROOM').fontFamily, 'IMFellEnglishSC');
    expect(styleOf('MISSION 01').fontFamily, 'Sentient', reason: 'a label with a number is read');
    expect(styleOf('SOLVE THE PUZZLE').fontFamily, 'Sentient');
    expect(styleOf('SOLVE THE PUZZLE').fontWeight, FontWeight.w600);
    expect(styleOf('The huge gears have stopped moving.').fontFamily, 'Sentient');
  });
}
