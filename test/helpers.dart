import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/widgets/game_button.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/utils/audio_service.dart';
import 'package:london_mystery/data/repositories/profile_store.dart';
import 'package:london_mystery/data/mock/season1/episode01_mock.dart';
import 'package:london_mystery/data/models/episode.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

final episode01 = Episode.fromJson(episode01Json);

/// Overrides that make the app run without platform plugins.
///
/// [prefs] may hold saves under the keys used before profiles: on the first
/// read the game copies them to the device's detective, as an updated app
/// does.
Future<List<Override>> testOverrides({
  Map<String, Object> prefs = const {},
  AudioService? audio,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  return testOverridesFor(await SharedPreferences.getInstance(), audio: audio);
}

/// [testOverrides] for storage that already exists (an app restart).
Future<List<Override>> testOverridesFor(
  SharedPreferences prefs, {
  AudioService? audio,
}) async => [
  sharedPreferencesProvider.overrideWithValue(prefs),
  audioServiceProvider.overrideWithValue(audio ?? MockAudioService()),
];

/// The detective's key for a save kept under [legacyKey] before profiles
/// (e.g. `AppConstants.progressStorageKey`).
String savedKey(SharedPreferences prefs, String legacyKey) =>
    AppConstants.profileKey(ProfileStore(prefs).read()!.profile.id, legacyKey);

/// The detective's saved JSON under [legacyKey], or null.
String? savedString(SharedPreferences prefs, String legacyKey) =>
    prefs.getString(savedKey(prefs, legacyKey));

/// Text as a reader sees it, in a plain or a rich [Text]. Notebook and
/// evidence English is rich text (harder words open their meaning), and
/// `find.text` reads the screen-reader labels of those words ("… (tap for
/// meaning)") instead of the words themselves.
Finder findReadable(String text) => find.byWidgetPredicate(
  (w) =>
      w is Text &&
      (w.data ?? w.textSpan?.toPlainText(includeSemanticsLabels: false)) ==
          text,
  description: 'text "$text" (as read)',
);

/// Like [findReadable], for a part of the text.
Finder findReadableContaining(String part) => find.byWidgetPredicate(
  (w) =>
      w is Text &&
      (w.data ?? w.textSpan?.toPlainText(includeSemanticsLabels: false) ?? '')
          .contains(part),
  description: 'text containing "$part" (as read)',
);

/// Right after a new detective's registration: How to Play is there (its
/// first page), and SKIP goes on — to the season's casebook, as
/// registration did before it. Pumps through the page change.
Future<void> skipHowToPlay(WidgetTester t) async {
  for (var i = 0; i < 20 && find.text('Welcome, Detective!').evaluate().isEmpty; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
  expect(find.text('Welcome, Detective!'), findsOneWidget, reason: 'How to Play comes first');
  await t.tap(find.text('SKIP'));
  for (var i = 0; i < 24; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
}

/// The way to ask for the next hint: the link under a puzzle ("Get a Free
/// Hint", then "Get More Hints") or, [upper], the final case's button.
Finder hintAction({bool upper = false}) => find.byWidgetPredicate(
  (w) =>
      w is Text &&
      (upper
              ? const {'GET A FREE HINT', 'GET MORE HINTS'}
              : const {'Get a Free Hint', 'Get More Hints'})
          .contains(w.data),
  description: 'the hint ${upper ? 'button' : 'link'}',
);

/// GET MORE HINTS, in the coins dialog of a hint that costs coins.
final tipSheetButton = find.byWidgetPredicate(
  (w) => w is CompactButton && w.label == 'GET MORE HINTS',
  description: 'the hint dialog GET MORE HINTS button',
);

/// After asking for a hint: a free hint is already on the page (no dialog);
/// a hint that costs coins is taken with GET MORE HINTS, which closes the dialog and
/// writes it on the page.
Future<void> takeTipFromSheet(WidgetTester t) async {
  await t.pump(const Duration(milliseconds: 400));
  if (tipSheetButton.evaluate().isEmpty) {
    await t.pump(const Duration(milliseconds: 500));
    return;
  }
  await t.ensureVisible(tipSheetButton);
  await t.pump();
  await t.tap(tipSheetButton);
  await t.pump();
  await t.pump(const Duration(milliseconds: 500));
}
