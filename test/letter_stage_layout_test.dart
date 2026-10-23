import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/mock/season1/episode01_mock.dart';
import 'package:london_mystery/data/mock/season1/episode04_mock.dart';
import 'package:london_mystery/data/models/episode.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/widgets/game_button.dart';
import 'package:london_mystery/widgets/glossary_text.dart';
import 'package:london_mystery/widgets/letter_card.dart';

import 'full_playthrough_test.dart' show wait;
import 'helpers.dart';
import 'mission_play.dart' show prefsAt;
import 'title_screen_test.dart' show capture;

/// The mission letter page: the intro, the letter, the dotted-word note and
/// SOLVE THE PUZZLE are one group, centred under the bar when the letter is
/// short and read from the top (scrolled) when it is long, with the same
/// gaps whatever its length.
void main() {
  setUpAll(() async {
    for (final (family, files) in [
      ('Sentient', ['Sentient-Variable.ttf']),
      ('IMFellEnglishSC', ['IMFellEnglishSC-Regular.ttf']),
      (
        'LibreBaskerville',
        ['LibreBaskerville.ttf', 'LibreBaskerville-Italic.ttf'],
      ),
    ]) {
      final loader = FontLoader(family);
      for (final f in files) {
        loader.addFont(rootBundle.load('assets/fonts/$f'));
      }
      await loader.load();
    }
  });

  // A sentence a line (Case 01's last note): the sentences must read apart.
  const lines =
      'My last stop is a big palace.\n'
      'A red flag flies on top.\n'
      'There is a fountain in front.\n'
      'The King lives there!';
  // One long sentence that wraps over several lines on its own.
  const wrapping =
      'Dear Detective,\n\nI walked past the old museum, along the river, over '
      'the bridge and under the clock before the sun went down.\n\n— The Shadow';
  const short = 'Dear Detective,\n\nMeet me at the museum.\n\n— The Shadow';
  final medium = (episode01Json['missions'] as List).first['letter'] as String;
  final long = [
    'Dear Detective,',
    for (var i = 0; i < 6; i++)
      'I took the Crown! Ha ha!\nMy next stop is a very big museum.\n'
          'It has old mummies from Egypt and a famous stone.',
    '— The Shadow',
  ].join('\n\n');

  /// The bundled catalog, with Case 04's first mission reading [letter].
  /// Case 04 is the case of letters, and its first mission keeps the
  /// letter page (Case 01's first two are played in their places).
  List<Episode> catalogWith(String letter) {
    final json = jsonDecode(jsonEncode(episode04Json)) as Map<String, dynamic>;
    (json['missions'] as List).first['letter'] = letter;
    // The sample letters are Case 01's: their dotted words keep Case 01's
    // meanings.
    final words = episode01Json['glossary'] as Map<String, dynamic>;
    (json['glossary'] as Map<String, dynamic>).addAll({for (final w in ['museum', 'palace']) w: words[w]});
    final changed = Episode.fromJson(json);
    return [
      for (final e in MockEpisodeRepository.bundled())
        e.id == changed.id ? changed : e,
    ];
  }

  Future<void> openLetter(
    WidgetTester t,
    Size size,
    String letter, {
    double textScale = 1,
  }) async {
    t.view.physicalSize = size * 3;
    t.view.devicePixelRatio = 3;
    // A notched phone: status bar above, home indicator below.
    t.view.padding = const FakeViewPadding(top: 47 * 3, bottom: 34 * 3);
    t.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(t.view.reset);
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          ...await testOverrides(
            prefs: prefsAt(MockEpisodeRepository.bundled(), 'ep04_m1', started: false),
          ),
          episodeCatalogProvider.overrideWithValue(catalogWith(letter)),
        ],
        child: const RepaintBoundary(
          key: ValueKey('shot'),
          child: LondonMysteryApp(),
        ),
      ),
    );
    await wait(t, const Duration(milliseconds: 300));
    ProviderScope.containerOf(find.byType(LondonMysteryApp).evaluate().first)
        .read(routerProvider)
        .go(Routes.mission('ep04_m1'));
    await wait(t, const Duration(milliseconds: 1200));
    final investigate = find.text('INVESTIGATE');
    await t.scrollUntilVisible(
      investigate,
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await t.tap(investigate);
    await wait(t, const Duration(milliseconds: 600));
    await t.tap(find.text('TAP TO OPEN'));
    await wait(t, const Duration(milliseconds: 1600));
    expect(find.text('SOLVE THE PUZZLE'), findsOneWidget);
    expect(t.takeException(), isNull);
  }

  Finder scrollView() => find.byType(SingleChildScrollView);
  Finder intro() => find.byType(GlossaryText).first;
  Finder button() => find.ancestor(
    of: find.text('SOLVE THE PUZZLE'),
    matching: find.byType(GameButton),
  );
  Finder note() => find.text('Press and hold a word to see what it means.');

  /// The group's gaps: intro → letter, letter → note, note → button.
  List<double> gaps(WidgetTester t) => [
    t.getTopLeft(find.byType(LetterCard)).dy - t.getBottomLeft(intro()).dy,
    t.getTopLeft(note()).dy - t.getBottomLeft(find.byType(LetterCard)).dy,
    t.getTopLeft(button()).dy - t.getBottomLeft(note()).dy,
  ];

  for (final size in const [Size(360, 640), Size(390, 844), Size(430, 932)]) {
    for (final scale in const [1.0, 1.3]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}@$scale';
      final gapsSeen = <String, List<double>>{};

      for (final (name, letter) in [
        ('short', short),
        ('medium', medium),
        ('long', long),
        ('lines', lines),
        ('wrapping', wrapping),
      ]) {
        testWidgets(
          '$name letter $tag: centred when it fits, scrolled from the top when not',
          (t) async {
            await openLetter(t, size, letter, textScale: scale);
            final view = t.getRect(scrollView());
            // The page sits under the bar and above the home indicator.
            expect(view.top, greaterThanOrEqualTo(47 + kToolbarHeight - 0.5));
            expect(view.bottom, lessThanOrEqualTo(size.height - 34 + 0.5));

            final top = t.getTopLeft(intro()).dy;
            final bottom = t.getBottomLeft(button()).dy;
            final fits = bottom - top + 2 * 24 <= view.height;
            if (fits) {
              expect(
                (top - view.top) - (view.bottom - bottom),
                moreOrLessEquals(0, epsilon: 1),
                reason: 'centred',
              );
              expect(top - view.top, greaterThanOrEqualTo(24 - 0.5));
            } else {
              expect(
                top - view.top,
                moreOrLessEquals(24, epsilon: 0.5),
                reason: 'read from the top',
              );
              // The button is reached by scrolling, and works.
              await t.dragUntilVisible(
                button(),
                scrollView(),
                const Offset(0, -200),
              );
              await t.pumpAndSettle();
              expect(
                t.getBottomLeft(button()).dy,
                lessThanOrEqualTo(view.bottom + 0.5),
              );
            }

            // The gaps are the same whatever the letter's length.
            final g = gaps(t);
            for (final other in gapsSeen.values) {
              for (var i = 0; i < g.length; i++) {
                expect(g[i], moreOrLessEquals(other[i], epsilon: 0.5));
              }
            }
            gapsSeen[name] = g;
            await capture(t, 'letter_${name}_$tag');

            // A dotted word still opens its card.
            final word = find.textRange
                .ofSubstring(letter.contains('museum') ? 'museum' : 'palace')
                .first;
            await t.ensureVisible(find.byType(LetterCard));
            await t.pumpAndSettle();
            await t.holdOnText(word);
            await wait(t, const Duration(milliseconds: 600));
            expect(find.text('WORD CARD'), findsOneWidget);
            await t.tap(find.text('GOT IT!'));
            await wait(t, const Duration(milliseconds: 600));
            expect(find.text('WORD CARD'), findsNothing);

            // And the button still takes the detective to the puzzle.
            await t.ensureVisible(button());
            await t.pumpAndSettle();
            await t.tap(button());
            await wait(t, const Duration(milliseconds: 800));
            expect(find.textContaining('THE PUZZLE'), findsWidgets);
            expect(find.text('SOLVE THE PUZZLE'), findsNothing);
            expect(t.takeException(), isNull);
          },
        );
      }
    }
  }

  testWidgets('coming back to the letter: it stays open, still centred', (
    t,
  ) async {
    await openLetter(t, const Size(390, 844), short);
    // Back to the place and in again: the letter stays open, still centred.
    await t.tap(find.byTooltip('Back'));
    await wait(t, const Duration(milliseconds: 600));
    await t.scrollUntilVisible(
      find.text('INVESTIGATE'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await t.tap(find.text('INVESTIGATE'));
    await wait(t, const Duration(milliseconds: 600));
    final view = t.getRect(scrollView());
    final top = t.getTopLeft(intro()).dy;
    final bottom = t.getBottomLeft(button()).dy;
    expect(
      (top - view.top) - (view.bottom - bottom),
      moreOrLessEquals(0, epsilon: 1),
    );
  });

  testWidgets(
    'a long letter with the keyboard up: nothing overflows, the button scrolls into reach',
    (t) async {
      await openLetter(t, const Size(360, 640), long, textScale: 1.3);
      t.view.viewInsets = const FakeViewPadding(bottom: 300 * 3);
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await t.dragUntilVisible(button(), scrollView(), const Offset(0, -200));
      await t.pumpAndSettle();
      expect(
        t.getBottomLeft(button()).dy,
        lessThanOrEqualTo(t.getRect(scrollView()).bottom + 0.5),
      );
    },
  );
}
