import 'dart:convert' show LineSplitter;
import 'dart:io' show File, FileSystemEntity, FileSystemEntityType;

import 'package:flutter/gestures.dart' show HitTestResult;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/widgets/game_button.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:world_mystery/core/constants/app_constants.dart';
import 'package:world_mystery/core/utils/audio_service.dart';
import 'package:world_mystery/data/repositories/profile_store.dart';
import 'package:world_mystery/data/mock/season1/episode01_mock.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/season.dart' show SeasonIds;
import 'package:world_mystery/data/repositories/episode_repository.dart';
import 'package:world_mystery/features/game/game_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

final episode01 = Episode.fromJson(episode01Json);

/// Looking up a word as a player does: press and hold it.
extension HoldOnText on WidgetTester {
  /// Presses and holds the single text range [range] (as
  /// [WidgetTester.tapOnText] taps it), long enough to be a long press: on
  /// a point of it whose hit lands on its text (a line's box can be taller
  /// than its letters).
  Future<void> holdOnText(FinderBase<TextRangeContext> range) {
    final found = range.evaluate().toList();
    if (found.length != 1) throw FlutterError('$range: needs a single text range, found ${found.length}');
    final r = found.single;
    final boxes = r.renderObject.getBoxesForSelection(
      TextSelection(baseOffset: r.textRange.start, extentOffset: r.textRange.end),
    );
    for (final box in boxes) {
      final rect = box.toRect();
      for (final fy in const [0.5, 0.4, 0.6, 0.3, 0.7, 0.2, 0.8]) {
        for (final fx in const [0.5, 0.35, 0.65]) {
          final at = r.renderObject.localToGlobal(Offset(rect.left + rect.width * fx, rect.top + rect.height * fy));
          final hit = HitTestResult();
          binding.hitTestInView(hit, at, r.view.view.viewId);
          if (hit.path.isNotEmpty && hit.path.first.target is InlineSpan) return longPressAt(at);
        }
      }
    }
    throw FlutterError('$range: no point of it can be pressed');
  }
}

/// Paris as it was before its release (2026-10-21): the screens and rules
/// of a season not yet out for players are tested on it. The game itself
/// ships Paris released (`season2Content.released`), and its own tests
/// check that.
final parisNotYetReleased = seasonReleasedProvider.overrideWithValue((id) => id != SeasonIds.paris);

/// Season 1's cases, in case order: what a test of London's content, saves
/// and screens plays. (`MockEpisodeRepository.bundled()` has every season's
/// cases; Season 2's are tested in their own files.)
List<Episode> season1Cases() =>
    [for (final e in MockEpisodeRepository.bundled()) if (e.seasonId == AppConstants.firstSeasonId) e];

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

/// The entries of the `flutter:` → `assets:` list of a pubspec's [text],
/// each as written (`assets/…/case_02/`), read by its structure: only that
/// list, its comments and blank lines left out, whatever the line endings
/// (LF, or CRLF as a Windows checkout has them). A folder is listed only
/// when this has it exactly.
List<String> pubspecAssetsOf(String text) {
  int indent(String line) => line.length - line.trimLeft().length;
  final out = <String>[];
  int? flutterAt, assetsAt;
  for (final raw in const LineSplitter().convert(text)) {
    final line = raw.trimRight();
    final body = line.trimLeft();
    if (body.isEmpty || body.startsWith('#')) continue;
    final at = indent(line);
    if (flutterAt == null) {
      if (at == 0 && body == 'flutter:') flutterAt = 0;
      continue;
    }
    if (at <= flutterAt) break; // the next top-level key: the section is over
    if (assetsAt == null) {
      if (body == 'assets:') assetsAt = at;
      continue;
    }
    if (at <= assetsAt && !body.startsWith('- ')) break; // the next key of `flutter:`
    if (!body.startsWith('- ')) continue;
    var entry = body.substring(2).trim();
    final comment = entry.indexOf(' #');
    if (comment >= 0) entry = entry.substring(0, comment).trim();
    if (entry.length >= 2 && (entry[0] == '"' || entry[0] == "'") && entry[entry.length - 1] == entry[0]) {
      entry = entry.substring(1, entry.length - 1);
    }
    out.add(entry);
  }
  return out;
}

/// The app's own `flutter: assets:` entries (see [pubspecAssetsOf]).
List<String> pubspecAssets() => pubspecAssetsOf(File('pubspec.yaml').readAsStringSync());

/// The entries of [assets] that name nothing on disk (a folder entry ends
/// in `/` and must be a folder; any other, a file).
List<String> missingAssets(Iterable<String> assets) => [
  for (final a in assets)
    if (a.endsWith('/')
        ? FileSystemEntity.typeSync(a.substring(0, a.length - 1)) != FileSystemEntityType.directory
        : FileSystemEntity.typeSync(a) != FileSystemEntityType.file)
      a,
];

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
  for (var i = 0; i < 20 && find.byKey(const ValueKey('how-to-play-welcome')).evaluate().isEmpty; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
  expect(find.byKey(const ValueKey('how-to-play-welcome')), findsOneWidget, reason: 'How to Play comes first');
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
