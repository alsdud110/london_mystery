import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/models/episode.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/season/season_overview.dart';

import 'full_playthrough_test.dart' show reveal, tapText, wait;
import 'helpers.dart';
import 'title_screen_test.dart' show capture;

/// After a case is closed, OPEN CASE NN goes to the investigation board:
/// the solved case lands on it, the season's figure moves on, and the next
/// case waits as the current case under BEGIN INVESTIGATION — the same taps
/// as through the case files. Case 12 still ends on the completed board.
void main() {
  final catalog = MockEpisodeRepository.bundled();
  Episode byNumber(int n) => catalog[n - 1];

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

  /// Case [n] just closed (its final solved), the cases before it solved.
  Map<String, Object> closed(int n) {
    final e = byNumber(n);
    final start = DateTime(2026, 10, 7, 10);
    return {
      AppConstants.progressKeyFor(e.id): jsonEncode(GameProgress(
        detectiveName: 'MINYOUNG',
        introSeen: true,
        completedMissionIds: [for (final m in e.allMissions) m.id],
        startedAt: start,
        completedAt: start.add(const Duration(minutes: 12)),
        playMillis: 0,
      ).toJson()),
      if (e.id != AppConstants.currentEpisodeId)
        AppConstants.progressStorageKey: jsonEncode(const GameProgress(detectiveName: 'MINYOUNG').toJson()),
      AppConstants.seasonStorageKey: jsonEncode(
        SeasonProgress(activeEpisodeId: e.id, solvedEpisodeIds: [for (final c in catalog.take(n)) c.id]).toJson(),
      ),
    };
  }

  late WidgetRef ref;
  String path() => ref.read(routerProvider).routerDelegate.currentConfiguration.uri.toString();
  Map<String, Object?> saved() {
    final p = ref.read(sharedPreferencesProvider);
    return {for (final k in p.getKeys()) k: p.get(k)};
  }

  Future<void> pumpApp(WidgetTester t, Size size, Map<String, Object> prefs) async {
    t.view.physicalSize = size * 3;
    t.view.devicePixelRatio = 3;
    addTearDown(t.view.reset);
    await t.pumpWidget(ProviderScope(
      overrides: await testOverrides(prefs: prefs),
      child: RepaintBoundary(
        key: const ValueKey('shot'),
        child: Consumer(builder: (context, r, _) {
          ref = r;
          return const LondonMysteryApp();
        }),
      ),
    ));
    await wait(t, const Duration(milliseconds: 300));
  }

  /// The case report of case [n] → its main button: where it leads.
  Future<void> fromReport(WidgetTester t, String button) async {
    ref.read(routerProvider).go(Routes.solved);
    await wait(t, const Duration(milliseconds: 3800));
    await reveal(t, find.text(button));
    await t.tap(find.text(button));
    await wait(t, const Duration(milliseconds: 2400)); // the board's reveal, if any
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500))); // decode the pictures
    await t.pump();
  }

  // 1–6, 10. Every case 01–11: OPEN CASE NN → the board; the case solved on
  // it, the next one current and open; nothing saved by going there.
  for (var n = 1; n <= 11; n++) {
    final shots = const {1, 4, 5, 8, 11}.contains(n);
    for (final size in shots ? const [Size(360, 640), Size(390, 844)] : const [Size(390, 844)]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}';
      final next = byNumber(n + 1);
      testWidgets('Case ${byNumber(n).numberLabel} closed $tag: OPEN CASE ${next.numberLabel} → the board', (t) async {
        await pumpApp(t, size, closed(n));
        final before = saved();
        await fromReport(t, 'OPEN CASE ${next.numberLabel}');
        expect(path(), Routes.season, reason: 'the investigation board, not the case files');
        expect(t.takeException(), isNull);

        final overview = ref.read(seasonOverviewProvider);
        expect(overview.marks[n - 1], CaseMark.solved, reason: 'the case just closed is on the board');
        expect(overview.currentCase?.id, next.id, reason: 'the next case is the one to work on');
        expect(find.text('$n / 12'), findsOneWidget);
        expect(find.text('CURRENT CASE'), findsOneWidget);
        expect(find.text(next.title), findsOneWidget);
        // The season's figure, as far as the cases solved tell.
        final figure = switch (n) { >= 5 => 'the clockmaker', 4 => 'the raven society', >= 2 => 'who are the ravens?', _ => null };
        if (figure != null) {
          expect(overview.figure!.label.toLowerCase(), figure);
          expect(find.textContaining(RegExp(RegExp.escape(figure), caseSensitive: false)), findsWidgets);
        }
        final cta = find.text('BEGIN INVESTIGATION');
        expect(cta, findsOneWidget);
        expect(t.getRect(cta).bottom, lessThanOrEqualTo(size.height), reason: 'the way on is on screen');
        if (shots) await capture(t, 'board_after_case${byNumber(n).numberLabel}_$tag');
        expect(saved(), before, reason: 'going to the board saves nothing');
        await wait(t, const Duration(seconds: 3));
      });
    }
  }

  testWidgets('7. BEGIN INVESTIGATION on the board opens the next case, its story first', (t) async {
    await pumpApp(t, const Size(390, 844), closed(4));
    await fromReport(t, 'OPEN CASE 05');
    await tapText(t, 'BEGIN INVESTIGATION', after: const Duration(milliseconds: 1200));
    expect(path(), Routes.intro);
    expect(ref.read(currentEpisodeProvider).id, 'ep05');
    expect(find.text(byNumber(5).intro.first), findsOneWidget);
    await capture(t, 'board_begin_case05_intro_390x844');
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('8. Back on the board does not go back to the case report (no ceremony again)', (t) async {
    await pumpApp(t, const Size(390, 844), closed(8));
    await fromReport(t, 'OPEN CASE 09');
    await t.binding.handlePopRoute();
    await wait(t, const Duration(milliseconds: 1500));
    expect(path(), isNot(Routes.solved));
    expect(path(), Routes.start, reason: 'the board goes back to the title, as before');
    expect(find.text('CASE CLOSED'), findsNothing);
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('9. Case 12: INVESTIGATION BOARD → the completed season, unchanged', (t) async {
    await pumpApp(t, const Size(390, 844), closed(12));
    expect(find.text('OPEN CASE 13'), findsNothing);
    await fromReport(t, 'INVESTIGATION BOARD');
    expect(path(), Routes.season);
    expect(find.text('12 / 12'), findsOneWidget);
    expect(find.text('COMPLETED'), findsOneWidget);
    expect(find.text('VIEW ALL CASE FILES'), findsOneWidget);
    expect(find.textContaining('PARIS'), findsNothing, reason: 'PARIS is the post-case scene\'s');
    expect(byNumber(12).finalMission.transition.last, 'PARIS.');
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('a solved case played again: OPEN CASE NN still opens case NN\'s file', (t) async {
    // Case 03 closed again while Case 07 is the season's current case.
    final prefs = closed(3);
    prefs[AppConstants.seasonStorageKey] = jsonEncode(
      SeasonProgress(activeEpisodeId: 'ep03', solvedEpisodeIds: [for (final c in catalog.take(6)) c.id]).toJson(),
    );
    await pumpApp(t, const Size(390, 844), prefs);
    await fromReport(t, 'OPEN CASE 04');
    expect(path(), Routes.caseFile('ep04'), reason: 'the board would offer Case 07, not 04');
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('re-entry: closed and opened again on the board, the season is as it was', (t) async {
    await pumpApp(t, const Size(390, 844), closed(5));
    await fromReport(t, 'OPEN CASE 06');
    final kept = {for (final e in saved().entries) e.key: e.value!};
    await t.pumpWidget(const SizedBox());
    await pumpApp(t, const Size(390, 844), kept);
    ref.read(routerProvider).go(Routes.season);
    await wait(t, const Duration(milliseconds: 1500));
    final overview = ref.read(seasonOverviewProvider);
    expect(overview.marks[4], CaseMark.solved);
    expect(overview.currentCase?.id, 'ep06');
    expect(overview.figure!.label, 'The Clockmaker');
    expect(find.text('BEGIN INVESTIGATION'), findsOneWidget);
    await wait(t, const Duration(seconds: 3));
  });

  testWidgets('the real flow: Case 04 final → post-case → report → OPEN CASE 05 → the board reveal', (t) async {
    // Case 04's missions solved, its final open.
    final e = byNumber(4);
    final prefs = closed(4);
    prefs[AppConstants.progressKeyFor(e.id)] = jsonEncode(GameProgress(
      detectiveName: 'MINYOUNG',
      introSeen: true,
      completedMissionIds: [for (final m in e.missions) m.id],
      startedAt: DateTime(2026, 10, 7, 10),
      playMillis: 0,
    ).toJson());
    prefs[AppConstants.seasonStorageKey] = jsonEncode(
      SeasonProgress(activeEpisodeId: e.id, solvedEpisodeIds: [for (final c in catalog.take(3)) c.id]).toJson(),
    );
    await pumpApp(t, const Size(360, 640), prefs);
    ref.read(routerProvider).go(Routes.finalMission);
    await wait(t, const Duration(milliseconds: 1500));
    await reveal(t, find.byType(TextField));
    await t.enterText(find.byType(TextField), 'RAVEN');
    await tapText(t, 'CHECK ANSWER', after: const Duration(milliseconds: 3200));
    expect(ref.read(gameControllerProvider).isCaseSolved, isTrue);
    await tapText(t, 'CONTINUE', after: const Duration(milliseconds: 1000));
    await t.tapAt(const Offset(180, 320)); // the post-case scene at once
    await wait(t, const Duration(milliseconds: 1200));
    await tapText(t, 'SEE MY CASE REPORT', after: const Duration(milliseconds: 3800));
    await reveal(t, find.text('OPEN CASE 05'));
    await capture(t, 'board_flow_case04_report_360x640');
    await t.tap(find.text('OPEN CASE 05'));
    await wait(t, const Duration(milliseconds: 600));
    expect(path(), Routes.season);
    await capture(t, 'board_flow_case04_reveal_360x640');
    await wait(t, const Duration(milliseconds: 2400));
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
    await t.pump();
    expect(find.textContaining(RegExp('the raven society', caseSensitive: false)), findsWidgets);
    expect(find.text(byNumber(5).title), findsOneWidget);
    await capture(t, 'board_flow_case04_board_360x640');
    await tapText(t, 'BEGIN INVESTIGATION', after: const Duration(milliseconds: 1200));
    expect(path(), Routes.intro);
    expect(ref.read(currentEpisodeProvider).id, 'ep05');
    await wait(t, const Duration(seconds: 3));
  });
}
