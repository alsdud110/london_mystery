import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/models/season.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/widgets/desk_background.dart';
import 'package:london_mystery/widgets/game_button.dart';

import 'full_playthrough_test.dart' show wait;
import 'helpers.dart';
import 'title_screen_test.dart' show capture;

/// Case Closed on the detective's desk: the case file as before, the next
/// step as the game's cinematic button, Case 12's ending untouched.
void main() {
  final catalog = MockEpisodeRepository.bundled();

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
    // Case 12 closes the season: Paris is out (released), so GO TO PARIS
    // leads its report.
    for (final (id, next) in const [('ep01', 'OPEN CASE 02'), ('ep05', 'OPEN CASE 06'), ('ep12', 'GO TO PARIS')]) {
      final tag = '${id}_${size.width.toInt()}x${size.height.toInt()}';
      testWidgets('case closed $tag: on the desk, $next as the glass button, and on to it', (t) async {
        t.view.physicalSize = size * 3;
        t.view.devicePixelRatio = 3;
        addTearDown(t.view.reset);
        final e = catalog.firstWhere((c) => c.id == id);
        final upTo = catalog.indexOf(e);
        await t.pumpWidget(ProviderScope(
          overrides: await testOverrides(prefs: {
            AppConstants.progressKeyFor(id): jsonEncode(GameProgress(
              detectiveName: 'MINYOUNG',
              introSeen: true,
              completedMissionIds: [for (final m in e.allMissions) m.id],
              startedAt: DateTime(2026, 9, 29, 10),
              completedAt: DateTime(2026, 9, 29, 10, 30),
              playMillis: 0,
            ).toJson()),
            if (id != AppConstants.currentEpisodeId)
              AppConstants.progressStorageKey: jsonEncode(const GameProgress(detectiveName: 'MINYOUNG').toJson()),
            AppConstants.seasonStorageKey: jsonEncode(
              SeasonProgress(activeEpisodeId: id, solvedEpisodeIds: [for (final c in catalog.take(upTo + 1)) c.id]).toJson(),
            ),
          }),
          child: const RepaintBoundary(key: ValueKey('shot'), child: LondonMysteryApp()),
        ));
        await wait(t, const Duration(milliseconds: 300));
        final router = ProviderScope.containerOf(find.byType(LondonMysteryApp).evaluate().first).read(routerProvider);
        router.go(Routes.solved);
        await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 600)));
        await wait(t, const Duration(milliseconds: 3200)); // the file, stamp, XP and buttons all in
        expect(t.takeException(), isNull);
        expect(find.text('CASE CLOSED'), findsOneWidget, reason: 'the case file, as before');
        expect(find.byType(DeskBackground), findsOneWidget, reason: 'on the desk, not the night sky');
        await capture(t, 'case_closed_${tag}_top');

        await t.scrollUntilVisible(find.text(next), 300, scrollable: find.byType(Scrollable).first);
        await wait(t, const Duration(milliseconds: 300));
        final button = t.widget<GameButton>(find.ancestor(of: find.text(next), matching: find.byType(GameButton)));
        expect(button.style, GameButtonStyle.glass);
        expect(find.text('Play again'), findsOneWidget);
        // The hook is told by the post-case scene before the report, not here.
        if (e.hook != null) expect(find.text(e.hook!), findsNothing, reason: 'no hook on the report');
        if (id == 'ep12') {
          // The season's finale, as shipped (Paris released): on to Paris,
          // the one strong action; the board after it, quieter; the case
          // file, its badges and report as before.
          expect(find.text('But the watch says PARIS.'), findsOneWidget);
          expect(find.text('London needs you again.'), findsNothing);
          expect(find.byKey(const ValueKey('finale-ticket')), findsOneWidget);
          expect(find.text('COMING SOON'), findsNothing, reason: 'the journey can be made');
          expect(find.byKey(const ValueKey('go-to-next-season')), findsOneWidget);
          final board = t.widget<GameButton>(find.ancestor(of: find.text('INVESTIGATION BOARD'), matching: find.byType(GameButton)));
          expect(board.style, GameButtonStyle.outline, reason: 'the board, quieter');
          expect(find.text('View my detective report'), findsOneWidget, reason: 'the grown-ups\' report, quieter');
          expect(find.byType(GameButton), findsNWidgets(2), reason: 'two boxes: Paris, then the board');
        } else {
          expect(find.text('VIEW MY DETECTIVE REPORT'), findsOneWidget, reason: 'the grown-ups\' report, as before');
          expect(find.textContaining('PARIS'), findsNothing);
        }
        await capture(t, 'case_closed_${tag}_actions');

        await t.tap(find.text(next));
        await wait(t, const Duration(milliseconds: 1500));
        final path = router.routerDelegate.currentConfiguration.uri.toString();
        if (id == 'ep12') {
          expect(path, Routes.seasonOf(SeasonIds.paris), reason: "to Paris's cover");
        } else {
          expect(path, Routes.season, reason: 'to the investigation board, the next case current on it');
        }
        await wait(t, const Duration(seconds: 3));
      });
    }
  }
}
