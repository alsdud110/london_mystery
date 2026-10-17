import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/widgets/letter_card.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/profile.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/game/wallet_controller.dart';
import 'package:london_mystery/features/onboarding/how_to_play_screen.dart';
import 'package:london_mystery/features/mission/widgets/tip_shop.dart';
import 'package:london_mystery/features/onboarding/how_to_play_state.dart';
import 'package:london_mystery/widgets/art_assets.dart';
import 'package:london_mystery/widgets/game_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'full_playthrough_test.dart' show reveal, tapText, wait;
import 'helpers.dart';
import 'title_screen_test.dart' show capture;

/// How to Play: once for a new detective, after registration and before the
/// season's casebook; never by surprise for one already playing; again from
/// the map's menu. Every page has a thing to try, and nothing tried there
/// touches the game (coins, tips, words, clues, badges, the case).
void main() {
  setUpAll(() async {
    for (final (family, files) in [
      ('Sentient', ['Sentient-Variable.ttf']),
      ('IMFellEnglishSC', ['IMFellEnglishSC-Regular.ttf']),
      ('LibreBaskerville', ['LibreBaskerville.ttf', 'LibreBaskerville-Italic.ttf']),
    ]) {
      final loader = FontLoader(family);
      for (final f in files) {
        loader.addFont(rootBundle.load('assets/fonts/$f'));
      }
      await loader.load();
    }
  });

  const titles = [
    'Hello, Detective MinYoung!',
    'Read the Letter',
    'Talk to People',
    'Solve the Mystery',
    'Discover New Words',
    'Hints When You Need Them',
    'Your Detective Notebook',
    'Your First Case Awaits!',
  ];

  ProviderContainer app(WidgetTester t) => ProviderScope.containerOf(find.byType(LondonMysteryApp).evaluate().first);
  String path(WidgetTester t) => app(t).read(routerProvider).routerDelegate.currentConfiguration.uri.toString();

  Future<void> pump(WidgetTester t, {Size size = const Size(390, 844), double scale = 1, Map<String, Object> prefs = const {}}) async {
    t.view.physicalSize = size * 3;
    t.view.devicePixelRatio = 3;
    t.platformDispatcher.textScaleFactorTestValue = scale;
    addTearDown(t.view.reset);
    addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
    await t.pumpWidget(ProviderScope(
      overrides: await testOverrides(prefs: prefs),
      child: const RepaintBoundary(key: ValueKey('shot'), child: LondonMysteryApp()),
    ));
    await wait(t, const Duration(milliseconds: 300));
  }

  /// A new player, from the title page through registration.
  Future<void> register(WidgetTester t) async {
    await tapText(t, 'START ADVENTURE');
    await t.tap(find.byKey(const ValueKey('avatar-boy')));
    await t.pump();
    await t.enterText(find.byType(TextField), 'MinYoung');
    await tapText(t, 'START INVESTIGATION', after: const Duration(milliseconds: 900));
  }

  Future<void> next(WidgetTester t) async {
    await t.tap(find.text('NEXT').hitTestable());
    await wait(t, const Duration(milliseconds: 450));
  }

  String saved(ProviderContainer c, String legacyKey) => savedString(c.read(sharedPreferencesProvider), legacyKey) ?? '';

  testWidgets('1, 4, 5. a new detective: registration → How to Play → START FIRST CASE → the casebook; kept after a restart',
      (t) async {
    final semantics = t.ensureSemantics(); // the page dots, by what they say
    await pump(t);
    await register(t);
    expect(path(t), Routes.howToPlay, reason: 'straight after registration');
    expect(find.text(titles.first), findsOneWidget);
    expect(find.bySemanticsLabel('Page 1 of 8'), findsOneWidget);
    // The opening spread: the game's name over London at night, the detective,
    // the welcome on its card.
    expect(find.text('LONDON'), findsOneWidget);
    expect(find.text('MYSTERY'), findsOneWidget);
    expect(
        find.text("Your first mystery awaits. Let's find clues and solve mysteries in London!"),
        findsOneWidget,
        reason: 'the welcome under the greeting by name');
    expect(find.text("I'm your detective partner."), findsNothing, reason: 'the detective in the picture is the player');
    expect(find.bySemanticsLabel('Detective MinYoung'), findsOneWidget, reason: 'the picture, by the detective\'s name');
    for (var i = 1; i < titles.length; i++) {
      await next(t);
      expect(find.text(titles[i]), findsOneWidget, reason: 'page ${i + 1}');
      expect(find.bySemanticsLabel('Page ${i + 1} of 8'), findsOneWidget);
    }
    expect(find.text('SKIP'), findsNothing, reason: 'nothing to skip on the last page');
    await tapText(t, 'START FIRST CASE', after: const Duration(milliseconds: 1500));
    expect(path(t), Routes.season);
    expect(find.text('BEGIN SEASON ONE'), findsOneWidget, reason: 'the casebook and its opening are not skipped');
    expect(app(t).read(howToPlaySeenProvider), isTrue);

    // A restart: the same storage, a new app. START goes to the casebook.
    final prefs = await SharedPreferences.getInstance();
    await t.pumpWidget(const SizedBox());
    await t.pumpWidget(ProviderScope(overrides: await testOverridesFor(prefs), child: const LondonMysteryApp()));
    await wait(t, const Duration(milliseconds: 400));
    expect(app(t).read(howToPlaySeenProvider), isTrue, reason: 'saved');
    await tapText(t, 'CONTINUE ADVENTURE', after: const Duration(milliseconds: 1500));
    expect(path(t), Routes.season, reason: 'not How to Play again');
    await wait(t, const Duration(seconds: 3));
    semantics.dispose();
  });

  testWidgets('2. a detective already playing never gets it by surprise', (t) async {
    await pump(t, prefs: {
      AppConstants.progressStorageKey: jsonEncode(const GameProgress(detectiveName: 'MINYOUNG', introSeen: true).toJson()),
    });
    expect(app(t).read(howToPlaySeenProvider), isFalse, reason: 'from before How to Play');
    expect(app(t).read(needsHowToPlayProvider), isFalse, reason: 'the season is begun');
    await tapText(t, 'CONTINUE ADVENTURE', after: const Duration(milliseconds: 1500));
    expect(path(t), Routes.map);
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('2b. registered, season not begun: once, and then not again (also after NEW ADVENTURE)', (t) async {
    await pump(t, prefs: {
      AppConstants.progressStorageKey: jsonEncode(const GameProgress(detectiveName: 'MINYOUNG').toJson()),
    });
    await tapText(t, 'CONTINUE ADVENTURE', after: const Duration(milliseconds: 900));
    expect(path(t), Routes.howToPlay, reason: 'left before it was seen');
    await tapText(t, 'SKIP', after: const Duration(milliseconds: 1500));
    expect(path(t), Routes.season);
    expect(app(t).read(howToPlaySeenProvider), isTrue, reason: 'SKIP counts as seen');

    app(t).read(routerProvider).go(Routes.start);
    await wait(t, const Duration(milliseconds: 1200));
    await tapText(t, 'NEW ADVENTURE');
    await tapText(t, 'START NEW ADVENTURE', after: const Duration(milliseconds: 1500));
    expect(path(t), Routes.season, reason: 'learnt once: not again after a new adventure');
    expect(app(t).read(gameControllerProvider).detectiveName, 'MINYOUNG', reason: 'the detective stays');
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('3, 14. NEXT, BACK (arrow and system back), quick taps, SKIP', (t) async {
    await pump(t);
    await register(t);
    await next(t);
    await next(t);
    expect(find.text(titles[2]), findsOneWidget);
    // Two taps in a row move one page, not two.
    await t.tap(find.text('NEXT').hitTestable());
    await t.pump(const Duration(milliseconds: 60));
    await t.tap(find.text('NEXT').hitTestable());
    await wait(t, const Duration(milliseconds: 450));
    expect(find.text(titles[3]), findsOneWidget, reason: 'one page for a double tap');
    await t.tap(find.byTooltip('Back'));
    await wait(t, const Duration(milliseconds: 450));
    expect(find.text(titles[2]), findsOneWidget);
    // Android back: the page before, then (from the first) the title page.
    await t.binding.handlePopRoute();
    await wait(t, const Duration(milliseconds: 450));
    expect(find.text(titles[1]), findsOneWidget);
    await t.binding.handlePopRoute();
    await wait(t, const Duration(milliseconds: 450));
    expect(find.text(titles[0]), findsOneWidget);
    await t.binding.handlePopRoute();
    await wait(t, const Duration(milliseconds: 900));
    expect(path(t), Routes.start);
    expect(app(t).read(howToPlaySeenProvider), isFalse, reason: 'left, not finished: it comes back');
    await tapText(t, 'CONTINUE ADVENTURE', after: const Duration(milliseconds: 900));
    expect(path(t), Routes.howToPlay);
    await tapText(t, 'SKIP', after: const Duration(milliseconds: 1500));
    expect(path(t), Routes.season);
    expect(app(t).read(howToPlaySeenProvider), isTrue);
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('6–12. every practice works, and none of it touches the game', (t) async {
    final semantics = t.ensureSemantics(); // the envelope, the answer cards, the coins and badges, by what they say
    await pump(t);
    await register(t);
    final c = app(t);
    final progressBefore = saved(c, AppConstants.progressStorageKey);
    final walletBefore = c.read(walletProvider).balance;
    final seasonBefore = jsonEncode(c.read(seasonProvider).toJson());

    // 6. The letter: tap to open, then read it again.
    await next(t);
    expect(find.text('TAP TO OPEN'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Sealed letter. Tap to open.')), findsOneWidget, reason: 'for screen readers too');
    await t.tap(find.text('TAP TO OPEN'));
    await wait(t, const Duration(milliseconds: 1400));
    // The letter, written line by line on the one sheet.
    for (final line in ['Dear Detective MinYoung,', 'My little cat, Pip, is lost!', 'Pip loves warm places.', 'Please help me find her.', '— Mr Finch']) {
      expect(find.descendant(of: find.byType(LetterCard), matching: findReadable(line)), findsOneWidget, reason: line);
    }
    await reveal(t, find.text('Letter'));
    await t.tap(find.text('Letter'));
    await wait(t, const Duration(milliseconds: 700));
    expect(find.text('BACK'), findsOneWidget, reason: 'the letter again, in a sheet');
    await t.tap(find.text('BACK'));
    await wait(t, const Duration(milliseconds: 600));

    // BACK and NEXT find the letter open, as it was left.
    await next(t);
    await t.tap(find.byTooltip('Back'));
    await wait(t, const Duration(milliseconds: 450));
    expect(find.text('TAP TO OPEN'), findsNothing, reason: 'still open');
    await next(t);

    // 7. A witness: a question, her answer.
    expect(find.text('MRS MOSS'), findsOneWidget);
    await reveal(t, find.text('Where did she go?'));
    await t.tap(find.text('Where did she go?'));
    await wait(t, const Duration(milliseconds: 400));
    expect(find.text('"She jumped up to the roof, next to the warm chimney."'), findsOneWidget);
    await next(t);

    // 8. The practice puzzle: CHECK ANSWER waits for a choice; wrong, then right.
    final check = find.widgetWithText(GameButton, 'CHECK ANSWER');
    await reveal(t, check);
    expect(t.widget<GameButton>(check).onPressed, isNull, reason: 'choose first');
    await t.tap(find.bySemanticsLabel('In the cold river'));
    await t.pump();
    await t.tap(check);
    await wait(t, const Duration(milliseconds: 400));
    expect(find.text('Not quite!'), findsOneWidget);
    await t.tap(find.bySemanticsLabel('On the warm roof'));
    await t.pump();
    await t.tap(check);
    await wait(t, const Duration(milliseconds: 400));
    expect(find.text('Well done!'), findsOneWidget);
    await next(t);

    // 9. A dotted word: its word card.
    await t.tapOnText(find.textRange.ofSubstring('chimney'));
    await wait(t, const Duration(milliseconds: 600));
    expect(find.text('WORD CARD'), findsOneWidget);
    expect(find.text('= 굴뚝'), findsOneWidget);
    await tapText(t, 'GOT IT!', after: const Duration(milliseconds: 500));
    await next(t);

    // 10. Hints, as on a case's page: the first free and at once, the second
    // for (practice) coins, asked first in the game's own coins dialog.
    expect(find.text('Good detectives use hints.'), findsOneWidget);
    const hint1 = 'Read the letter again. What does Pip love?';
    const hint2 = 'Mrs Moss saw Pip next to the warm chimney. Where are chimneys?';
    expect(find.text(hint1), findsNothing, reason: 'not before it is asked for');
    await reveal(t, find.text('GET A FREE HINT'));
    await t.tap(find.text('GET A FREE HINT'));
    await wait(t, const Duration(milliseconds: 500));
    final dialog = find.byType(TipShopCard);
    expect(dialog, findsNothing, reason: 'a free hint asks nothing');
    expect(find.text(hint1), findsOneWidget, reason: 'hint 1 written on its card');
    expect(find.bySemanticsLabel('Practice coins: ${AppConstants.startCoins}'), findsOneWidget);
    await reveal(t, find.text('GET MORE HINTS'));
    await t.tap(find.text('GET MORE HINTS'));
    await wait(t, const Duration(milliseconds: 500));
    final price = WalletController.priceOf(2);
    expect(find.descendant(of: dialog, matching: find.text('Get Another Hint?')), findsOneWidget);
    expect(find.descendant(of: dialog, matching: find.bySemanticsLabel('$price coins')), findsOneWidget,
        reason: "the game's own price");
    await t.tap(find.descendant(of: dialog, matching: find.text('GET MORE HINTS')));
    await wait(t, const Duration(milliseconds: 600));
    expect(dialog, findsNothing);
    expect(find.text(hint2), findsOneWidget, reason: 'hint 2 on its card, open');
    expect(find.text(hint1), findsNothing, reason: 'hint 1 folded shut meanwhile');
    // A card opened before folds open again with a tap.
    await t.tap(find.text('DETECTIVE HINT 1'));
    await wait(t, const Duration(milliseconds: 400));
    expect(find.text(hint1), findsOneWidget);
    expect(find.bySemanticsLabel('Practice coins: ${AppConstants.startCoins - price}'), findsOneWidget);
    await next(t);

    // 11. The notebook's tabs.
    expect(find.text('"Warm Places"'), findsOneWidget, reason: 'CLUES first');
    await t.tap(find.text('EVIDENCE'));
    await wait(t, const Duration(milliseconds: 400));
    expect(find.text("Mr Finch's Letter"), findsOneWidget);
    await t.tap(find.text('BADGES'));
    await wait(t, const Duration(milliseconds: 400));
    expect(find.bySemanticsLabel('First Clue, earned'), findsOneWidget);

    // 12. Nothing of the game changed.
    expect(c.read(walletProvider).balance, walletBefore, reason: 'real coins');
    expect(saved(c, AppConstants.progressStorageKey), progressBefore, reason: 'the case save: tips, words, clues, badges');
    final progress = c.read(gameControllerProvider);
    expect(progress.hintsUsed, isEmpty);
    expect(progress.lookedUpWords, isEmpty);
    expect(progress.badgeIds, isEmpty);
    expect(progress.completedMissionIds, isEmpty);
    expect(jsonEncode(c.read(seasonProvider).toJson()), seasonBefore, reason: 'the season');
    await tapText(t, 'SKIP', after: const Duration(milliseconds: 1500));
    expect(c.read(walletProvider).balance, walletBefore);
    await wait(t, const Duration(seconds: 3));
    semantics.dispose();
  });

  testWidgets('again, from the map menu: back to the map, the game untouched', (t) async {
    await pump(t, prefs: {
      AppConstants.progressStorageKey: jsonEncode(const GameProgress(detectiveName: 'MINYOUNG', introSeen: true).toJson()),
    });
    app(t).read(routerProvider).go(Routes.map);
    await wait(t, const Duration(milliseconds: 1600));
    await t.tap(find.byTooltip('Menu'));
    await wait(t);
    await tapText(t, 'How to play', after: const Duration(milliseconds: 900));
    expect(find.byType(HowToPlayScreen), findsOneWidget);
    for (var i = 1; i < titles.length; i++) {
      await next(t);
    }
    expect(find.text('BACK TO MY CASE'), findsOneWidget, reason: 'not START FIRST CASE');
    await tapText(t, 'BACK TO MY CASE', after: const Duration(milliseconds: 1200));
    expect(path(t), Routes.map);
    await wait(t, const Duration(seconds: 3));
  });

  // 13. Every page whole on a small phone and with large text; the pictures.
  for (final (size, scale) in const [(Size(360, 640), 1.0), (Size(360, 640), 1.3), (Size(390, 844), 1.0), (Size(390, 844), 1.3)]) {
    final tag = '${size.width.toInt()}x${size.height.toInt()}${scale == 1 ? '' : '_text13'}';
    testWidgets('every page at $tag: no overflow, the way on always on screen', (t) async {
      await pump(t, size: size, scale: scale);
      await register(t);
      for (var i = 0; i < titles.length; i++) {
        if (i > 0) await next(t);
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 300))); // the pictures
        await t.pump();
        expect(t.takeException(), isNull, reason: 'page ${i + 1}');
        final button = find.text(i == titles.length - 1 ? 'START FIRST CASE' : 'NEXT');
        expect(t.getRect(button).bottom, lessThanOrEqualTo(size.height), reason: 'page ${i + 1}: the way on');
        expect(t.getRect(find.byTooltip('Back')).height, greaterThanOrEqualTo(44));
        await capture(t, 'how_to_play_${i + 1}_$tag');
      }
      await wait(t, const Duration(seconds: 2));
    });
  }

  test('the guide has its own pictures, none of a case', () {
    final own = [
      for (final a in [...DetectiveAvatar.values, null]) ...[ArtAssets.onboardingWelcome(a), ArtAssets.onboardingReady(a)],
      ArtAssets.onboardingWitness,
      ArtAssets.onboardingCat,
    ];
    for (final f in own) {
      expect(f, startsWith('assets/art/onboarding/'));
    }
    final caseArt = {...ArtAssets.characters.values, ...ArtAssets.objects.values, ...ArtAssets.evidencePictures.values};
    expect(caseArt.intersection(own.toSet()), isEmpty);
  });
}
