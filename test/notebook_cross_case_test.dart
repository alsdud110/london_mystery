import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/data/models/profile.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/game/scoring.dart';
import 'package:london_mystery/features/notebook/season_archive.dart';

import 'full_playthrough_test.dart' show wait;
import 'helpers.dart';
import 'mission_play.dart';
import 'title_screen_test.dart' show capture;

/// Phase 4 (P1-2, P1-1): the English in the notebook explains its own words
/// (by the glossary of the case it was found in), and operator mode can
/// open every other case file for reference without solving anything.
void main() {
  final season = MockEpisodeRepository.bundled();

  /// The archive's own list (the evidence grids inside it do not scroll).
  Finder archiveList() => find.descendant(of: find.byType(SeasonArchive), matching: find.byType(Scrollable)).first;

  group('which case a piece of evidence or a clue belongs to', () {
    test('every evidence and clue of the season has exactly its own case', () {
      for (final e in season) {
        for (final v in e.allEvidence) {
          expect(caseOfEvidence(season, v.id)?.id, e.id, reason: v.id);
        }
        for (final c in e.allClues) {
          expect(caseOfClue(season, c.id)?.id, e.id, reason: c.id);
        }
      }
      expect(caseOfEvidence(season, 'nothing'), isNull);
    });
  });

  group('word meanings in the notebook (P1-2)', () {
    for (final size in const [Size(360, 640), Size(390, 844)]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}';

      testWidgets("$tag: in Case 12, Case 04's seal in the archive explains 'wax' by Case 04's words", (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'ep12_m2');
        expect(season.firstWhere((e) => e.id == 'ep12').meaningOf('wax'), isNull, reason: 'not a Case 12 word');
        play.ref.read(routerProvider).push(Routes.archive);
        await wait(t, const Duration(milliseconds: 1200));
        final folder = find.text('THE SECRET LETTER');
        await t.scrollUntilVisible(folder, 200, scrollable: archiveList());
        await t.ensureVisible(folder); // centred, not at the very edge of a small screen
        await t.pump();
        await t.tap(folder);
        await wait(t, const Duration(milliseconds: 600));
        final seal = find.text('Black Wax Seal');
        await t.scrollUntilVisible(seal, 200, scrollable: archiveList());
        await t.ensureVisible(seal); // centred, not at the very edge of a small screen
        await t.pump();
        await t.tap(seal);
        await wait(t, const Duration(milliseconds: 800));
        expect(findReadable('A raven is pressed into the wax.'), findsOneWidget, reason: 'the close-up, as before');
        await capture(t, 'phase4_seal_words_$tag');
        await t.holdOnText(find.textRange.ofSubstring('wax').first);
        await wait(t, const Duration(milliseconds: 600));
        expect(find.text('WORD CARD'), findsOneWidget);
        expect(find.text('= 밀랍'), findsOneWidget, reason: "Case 04's glossary");
        final p = play.ref.read(gameControllerProvider);
        expect(p.lookedUpWords, contains('wax'), reason: 'recorded for the parent report, as in a mission');
        expect(p.behavior!.words, contains('wax'), reason: 'counts toward Word Collector in this run');
        expect(t.takeException(), isNull);
      });

      testWidgets('$tag: a clue note in the notebook opens its word cards too', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'ep04_m2');
        play.ref.read(routerProvider).push(Routes.notebook);
        await wait(t, const Duration(milliseconds: 1200));
        // THIS CASE → CLUES: "The platforms never sleep. They are open day and night."
        final note = find.textRange.ofSubstring('never');
        expect(note, findsWidgets);
        await t.holdOnText(note.first);
        await wait(t, const Duration(milliseconds: 600));
        expect(find.text('WORD CARD'), findsOneWidget);
        expect(t.takeException(), isNull);
      });
    }

    test('Word Collector counts notebook look-ups like mission look-ups, once per word', () async {
      final container = ProviderContainer(overrides: await testOverrides());
      addTearDown(container.dispose);
      final c = container.read(gameControllerProvider.notifier);
      c.createDetective('KIM', DetectiveAvatar.boy);
      c.startInvestigation();
      for (final w in ['wax', 'Wax', 'seal', 'pressed']) {
        c.lookUpWord(w); // what the notebook's word cards call
      }
      expect(container.read(gameControllerProvider).behavior!.words, ['wax', 'seal', 'pressed']);
      final m01 = season.first.missionById('m01')!;
      expect(c.submitAnswer(m01, 'b').newBadges, contains(GameBadge.wordCollector));
    });

    test('a save from before action records still only adds to the word list', () {
      final old = GameProgress.fromJson({'detectiveName': 'KIM', 'lookedUpWords': <String>[]});
      expect(old.recordsBehavior, isFalse);
    });
  });

  group('operator mode: every other case file for reference (P1-1)', () {
    Future<ProviderContainer> containerAt(String episodeId, {bool operator = true}) async {
      final container = ProviderContainer(
        overrides: await testOverrides(prefs: {
          AppConstants.progressKeyFor(episodeId): jsonEncode(const GameProgress(detectiveName: 'KIM', introSeen: true).toJson()),
          AppConstants.seasonStorageKey: jsonEncode(SeasonProgress(activeEpisodeId: episodeId).toJson()),
        }),
      );
      container.read(operatorAccessSwitchProvider.notifier).set(operator);
      return container;
    }

    test('with operator mode on, unsolved cases are shown in full, for reference; nothing is solved', () async {
      final container = await containerAt('ep08');
      addTearDown(container.dispose);
      final entries = {for (final x in container.read(seasonArchiveProvider)) x.episode.id: x};
      final c03 = entries['ep03']!;
      expect(c03.status, ArchiveStatus.reference);
      expect(c03.canOpen, isTrue);
      expect(c03.evidence.map((v) => v.name), contains('Red Button'));
      expect(entries['ep08']!.status, ArchiveStatus.current, reason: 'the open case shows only what was found');
      expect(entries['ep08']!.evidence, isEmpty);
      expect(entries['ep12']!.status, ArchiveStatus.reference);
      expect(container.read(seasonProvider).solvedEpisodeIds, isEmpty, reason: 'no case is marked solved');
    });

    test('without operator mode the archive keeps its locks', () async {
      final container = await containerAt('ep08', operator: false);
      addTearDown(container.dispose);
      final entries = {for (final x in container.read(seasonArchiveProvider)) x.episode.id: x};
      expect(entries['ep03']!.status, isNot(ArchiveStatus.reference));
      expect(entries['ep03']!.canOpen, isFalse);
      expect(entries.values.where((x) => x.isReference), isEmpty);
    });

    for (final size in const [Size(360, 640), Size(390, 844)]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}';

      testWidgets("$tag: in Case 08, Case 03's Red Button for reference: no badge, no XP, no solve", (t) async {
        t.view.physicalSize = size * 3;
        t.view.devicePixelRatio = 3;
        addTearDown(t.view.reset);
        late WidgetRef ref;
        await t.pumpWidget(ProviderScope(
          overrides: await testOverrides(prefs: {
            AppConstants.progressStorageKey: jsonEncode(const GameProgress(detectiveName: 'KIM').toJson()),
            AppConstants.progressKeyFor('ep08'): jsonEncode(
              GameProgress(detectiveName: 'KIM', introSeen: true, startedAt: DateTime(2026, 10, 12), playMillis: 0).toJson(),
            ),
            AppConstants.seasonStorageKey: jsonEncode(const SeasonProgress(activeEpisodeId: 'ep08').toJson()),
          }),
          child: RepaintBoundary(
            key: const ValueKey('shot'), // for screenshots (LM_SCREENSHOTS)
            child: Consumer(builder: (context, r, _) {
              ref = r;
              return const LondonMysteryApp();
            }),
          ),
        ));
        await wait(t, const Duration(milliseconds: 300));
        ref.read(operatorAccessSwitchProvider.notifier).set(true);
        ref.read(routerProvider).go(Routes.archive);
        await wait(t, const Duration(milliseconds: 1200));
        final folder = find.text('THE VANISHING PAINTING');
        await t.scrollUntilVisible(folder, 200, scrollable: archiveList());
        expect(find.text('REFERENCE'), findsWidgets);
        await t.ensureVisible(folder); // centred, not at the very edge of a small screen
        await t.pump();
        await t.tap(folder);
        await wait(t, const Duration(milliseconds: 600));
        final button = find.text('Red Button');
        await t.scrollUntilVisible(button, 200, scrollable: archiveList());
        await t.ensureVisible(button); // centred, not at the very edge of a small screen
        await t.pump();
        await t.tap(button);
        await wait(t, const Duration(milliseconds: 800));
        expect(findReadable('From a coat. It was under the bench.'), findsOneWidget);
        await capture(t, 'phase4_operator_reference_$tag');
        final p = ref.read(gameControllerProvider);
        expect(p.behavior!.evidenceViewed, isEmpty, reason: 'a reference file earns no Notebook Explorer');
        expect(p.completedMissionIds, isEmpty);
        expect(p.badgeIds, isEmpty);
        expect(ref.read(seasonProvider).solvedEpisodeIds, isEmpty);
        expect(t.takeException(), isNull);
      });
    }
  });
}
