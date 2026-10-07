import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/widgets/game_button.dart';

import 'full_playthrough_test.dart' show wait;
import 'helpers.dart';
import 'title_screen_test.dart' show capture;

/// Case Files as one paper page: the heading printed on it (no bar), the
/// button resting at the bottom (no white bar), the last folder clear of it.
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

  for (final size in const [Size(360, 640), Size(390, 844)]) {
    final tag = '${size.width.toInt()}x${size.height.toInt()}';
    testWidgets('case files $tag: one paper page, Case 02 open and chosen, scrolled to the end, BEGIN, back', (t) async {
      t.view.physicalSize = size * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      await t.pumpWidget(ProviderScope(
        overrides: await testOverrides(prefs: {
          AppConstants.progressStorageKey: jsonEncode(GameProgress(
            detectiveName: 'MINYOUNG',
            introSeen: true,
            completedMissionIds: [for (final m in episode01.allMissions) m.id],
            startedAt: DateTime(2026, 9, 29, 10),
            completedAt: DateTime(2026, 9, 29, 10, 30),
            playMillis: 0,
          ).toJson()),
          AppConstants.seasonStorageKey: jsonEncode(const SeasonProgress(solvedEpisodeIds: ['ep01']).toJson()),
        }),
        child: const RepaintBoundary(key: ValueKey('shot'), child: LondonMysteryApp()),
      ));
      await wait(t, const Duration(milliseconds: 300));
      final router = ProviderScope.containerOf(find.byType(LondonMysteryApp).evaluate().first).read(routerProvider);
      router.go(Routes.caseFile('ep02')); // Case 02 open and chosen
      await wait(t, const Duration(milliseconds: 1200));
      expect(t.takeException(), isNull);
      expect(find.text('SOLVED'), findsOneWidget, reason: 'Case 01');
      expect(find.text('SEALED'), findsWidgets, reason: 'Cases 03 on');
      expect(find.text('Big Ben has stopped. Its hands do not move.'), findsOneWidget, reason: 'Case 02 open');
      expect(find.textContaining('EPISODE'), findsNothing, reason: 'the folder already names the case');

      // No bar: the app bar is see-through and lies on the page itself.
      final bar = t.widget<AppBar>(find.byType(AppBar));
      expect(t.widget<Scaffold>(find.byType(Scaffold).first).extendBodyBehindAppBar, isTrue);
      expect(bar.backgroundColor ?? Theme.of(t.element(find.byType(AppBar))).appBarTheme.backgroundColor, Colors.transparent);
      // The folders begin under the heading, never behind it.
      expect(t.getRect(find.byType(Scrollable).first).top, greaterThanOrEqualTo(t.getRect(find.text('CASE FILES')).bottom),
          reason: 'the list is clipped below the heading');

      // The button: as before (navy on paper), off the bottom edge, no white bar behind it.
      final begin = find.ancestor(of: find.text('BEGIN INVESTIGATION'), matching: find.byType(GameButton));
      expect(t.widget<GameButton>(begin).style, GameButtonStyle.navy);
      final button = t.getRect(begin);
      expect(button.bottom, lessThanOrEqualTo(size.height - 16), reason: 'clear of the bottom edge');
      expect(
        find.byWidgetPredicate((w) => w is Container && w.decoration is BoxDecoration && (w.decoration as BoxDecoration).border != null &&
            (w.decoration as BoxDecoration).boxShadow != null && (w.decoration as BoxDecoration).color != null &&
            find.descendant(of: find.byWidget(w), matching: begin).evaluate().isNotEmpty),
        findsNothing,
        reason: 'no bar of its own',
      );
      await capture(t, 'case_files_$tag');

      // The last folder scrolls clear above the button.
      await t.drag(find.byType(Scrollable).first, const Offset(0, -4000));
      await wait(t, const Duration(milliseconds: 600));
      final last = t.getRect(find.text('THE MIDNIGHT CASE'));
      expect(last.bottom, lessThan(button.top), reason: 'the last case is not under the button');
      await capture(t, 'case_files_${tag}_end');

      // BEGIN: Case 02 begins (its intro), as before.
      await t.tap(find.text('BEGIN INVESTIGATION'));
      await wait(t, const Duration(milliseconds: 900));
      expect(router.routerDelegate.currentConfiguration.uri.path, Routes.intro);

      // Back from the case files: up to the season board, as before.
      router.go(Routes.episodes);
      await wait(t, const Duration(milliseconds: 900));
      await t.tap(find.byTooltip('Back'));
      await wait(t, const Duration(milliseconds: 900));
      expect(router.routerDelegate.currentConfiguration.uri.path, Routes.season);
      await wait(t, const Duration(seconds: 3));
    });
  }
}
