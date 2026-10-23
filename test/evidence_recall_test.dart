import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/mock/season2/season2_mock.dart';
import 'package:london_mystery/data/mock/season2/season2_scenes.dart';
import 'package:london_mystery/data/mock/season_catalog.dart';
import 'package:london_mystery/data/models/episode.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/mission.dart';
import 'package:london_mystery/data/models/river_puzzles.dart';
import 'package:london_mystery/data/models/scene_explore.dart' show ScenePixels;
import 'package:london_mystery/data/models/season.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/models/workshop_puzzles.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/game/scoring.dart';
import 'package:london_mystery/features/game/wallet_controller.dart';
import 'package:london_mystery/features/mission/widgets/evidence_recall.dart';
import 'package:london_mystery/features/mission/widgets/workshop_papers.dart' show CroppedPicture;
import 'package:london_mystery/features/notebook/notebook_screen.dart';
import 'package:london_mystery/features/notebook/season_archive.dart';
import 'package:london_mystery/widgets/art_assets.dart';

import 'full_playthrough_test.dart' show tapText, wait;
import 'helpers.dart';

/// The Evidence Recall card: a mission played with evidence of an earlier
/// case shows a card on its foot; the detective brings that evidence from
/// the notebook and looks at it beside the puzzle. Only a help: no mission
/// without a recall changes, the puzzle never waits for it, a wrong pick
/// costs nothing. And the notebook shows Case 02's Hidden Sketch as the
/// drawing the detective uncovered.
void main() {
  final inGame = MockEpisodeRepository.bundled();
  final s1 = season1Cases();
  final paris = [for (final e in inGame) if (e.seasonId == SeasonIds.paris) e];

  /// The game with Case 07 Mission 03 played with a recall (a stand-in for
  /// Case 08, still to be written): the Hidden Sketch of Case 02.
  const recall = {
    'evidence': 's2_ep02_e3',
    'feedback': {'s2_ep02_e1': "That's the Painted Street. Where is the black gate?"},
  };
  Episode withRecall(Map<String, dynamic> r) {
    final json = jsonDecode(jsonEncode(season2Json['s2_ep07'])) as Map<String, dynamic>;
    (json['missions'] as List)[2]['recall'] = r;
    return Episode.fromJson({...json, 'seasonId': SeasonIds.paris});
  }

  List<Episode> gameWith(Episode case07) => [for (final e in inGame) e.id == case07.id ? case07 : e];

  group('the data', () {
    test('a mission without a recall reads as before; one with it keeps every field', () {
      // Case 08's M1 (the Hidden Sketch) and M3 (the Amendment Slip) are the
      // game's only missions played with a recall (2026-10-23).
      const recalling = {'s2_ep08_m1': 's2_ep02_e3', 's2_ep08_m3': 's2_ep07_e3'};
      for (final e in inGame) {
        for (final m in e.allMissions) {
          if (recalling[m.id] case final evidence?) {
            expect(m.recall?.evidenceId, evidence, reason: m.id);
            expect(m.toJson()['recall'], m.recall!.toJson(), reason: m.id);
            continue;
          }
          expect(m.recall, isNull, reason: '${m.id}: no other mission of the game recalls');
          expect(m.toJson().containsKey('recall'), isFalse);
        }
      }
      final m = withRecall(recall).allMissions[2];
      expect(m.recall!.evidenceId, 's2_ep02_e3');
      expect(m.recall!.title, isNull);
      expect(m.recall!.missFor('s2_ep02_e1'), "That's the Painted Street. Where is the black gate?");
      expect(m.recall!.missFor('s2_ep07_e1'), EvidenceRecall.defaultMiss);
      final again = Mission.fromJson(m.toJson());
      expect(again.recall!.toJson(), m.recall!.toJson());
      expect(again.answer, m.answer);
    });

    test("the notebook's Hidden Sketch is the very drawing Case 02's easel showed", () {
      final layer = season2Layers['s2_ep02_m3']!;
      final art = SeasonCatalog.evidenceArt('s2_ep02_e3');
      expect(art, isA<DrawnEvidenceArt>());
      final p = (art! as DrawnEvidenceArt).drawn as PictureEvidence;
      expect(p.file, layer.sketch);
      expect(p.file, 'assets/seasons/season_02_paris/cases/case_02/hidden_layer_sketch.png');
      expect(p.crop, layer.view, reason: 'as the puzzle showed it');
      expect(p.crop, season2Case02StoryScenes['s2_ep02_m3']!.after!.crop, reason: 'as the scene after it showed it');
      expect(p.aspect, closeTo(640 / 690, 1e-9));
      expect(ArtAssets.evidencePrints['s2_ep02_e3'], closeTo(p.aspect, 1e-9), reason: 'shown whole in the close look');
      // Its name and id are as they were; no other evidence changed.
      final e = inGame.firstWhere((e) => e.id == 's2_ep02').missionById('s2_ep02_m3')!.evidence!;
      expect((e.id, e.name), ('s2_ep02_e3', 'The Hidden Sketch'));
    });

    test('a picture without a crop is drawn whole, as before', () {
      const p = PictureEvidence(file: 'x.png', pixels: ScenePixels(200, 100));
      expect(p.crop, isNull);
      expect(p.aspect, 2);
    });

    test("what the notebook holds: the archive's evidence, case by case, and nothing else", () {
      final case02 = paris[1];
      final case07 = paris[6];
      final archive = [
        ArchiveEntry(episode: paris[0], status: ArchiveStatus.solved, evidence: paris[0].allEvidence),
        ArchiveEntry(episode: case02, status: ArchiveStatus.solved, evidence: case02.allEvidence),
        ArchiveEntry(episode: case07, status: ArchiveStatus.current, evidence: [case07.allEvidence.first]),
        ArchiveEntry(episode: paris[2], status: ArchiveStatus.sealed),
      ];
      final held = heldEvidence(archive);
      expect([for (final (e, _) in held) e.id], ['s2_ep01', 's2_ep02', 's2_ep07']);
      expect(recalledEvidence(archive, const EvidenceRecall(evidenceId: 's2_ep02_e3'))!.location, "THE PAINTER'S EASEL");
      expect(recalledEvidence(archive, const EvidenceRecall(evidenceId: 's2_ep07_e3')), isNull, reason: 'not found yet');
      expect(recalledEvidence(archive, const EvidenceRecall(evidenceId: 'e01')), isNull, reason: "another season's");
      expect(recalledEvidence(archive, const EvidenceRecall(evidenceId: 'nowhere')), isNull);
    });
  });

  group('a child brings the Hidden Sketch', () {
    setUpAll(() async {
      // Real fonts, so text sizes (and any overflow) match the device.
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

    /// The app at Case 07 Mission 03 (Paris Cases 01–06 and Case 07's first
    /// two missions solved), its cases [episodes].
    Future<WidgetRef> open(WidgetTester t, Size size, List<Episode> episodes) async {
      t.view.physicalSize = size * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      GameProgress solved(Episode e) => GameProgress(
            detectiveName: 'MINYOUNG',
            introSeen: true,
            completedMissionIds: [for (final m in e.allMissions) m.id],
            startedAt: DateTime(2026, 10, 20, 10),
            completedAt: DateTime(2026, 10, 20, 10, 30),
            playMillis: 0,
          );
      late WidgetRef ref;
      // A fresh app each time (a scope is never given new overrides).
      await t.pumpWidget(const SizedBox());
      await t.pumpWidget(ProviderScope(
        overrides: [
          ...await testOverrides(prefs: {
            AppConstants.progressStorageKey: jsonEncode(solved(s1.first).toJson()),
            for (final e in s1.skip(1)) AppConstants.progressKeyFor(e.id): jsonEncode(solved(e).toJson()),
            AppConstants.seasonStorageKey: jsonEncode(SeasonProgress(activeEpisodeId: 'ep12', solvedEpisodeIds: [for (final e in s1) e.id]).toJson()),
          }),
          allEpisodesProvider.overrideWithValue(episodes),
        ],
        child: RepaintBoundary(
          key: const ValueKey('shot'),
          child: Consumer(builder: (context, r, _) {
            ref = r;
            return const LondonMysteryApp();
          }),
        ),
      ));
      await wait(t, const Duration(milliseconds: 300));
      final game = ref.read(gameControllerProvider.notifier);
      expect(game.openSeason(SeasonIds.paris), isTrue);
      for (final e in episodes.where((e) => e.seasonId == SeasonIds.paris).take(6)) {
        expect(game.openEpisode(e.id), isTrue);
        game.startInvestigation();
        for (final m in e.allMissions) {
          game.submitAnswer(m, m.answer);
        }
      }
      expect(game.openEpisode('s2_ep07'), isTrue);
      game.startInvestigation();
      final case07 = episodes.firstWhere((e) => e.id == 's2_ep07');
      for (final m in case07.missions.take(2)) {
        expect(game.submitAnswer(m, m.answer).result, SubmitResult.correct);
      }
      ref.read(routerProvider).go(Routes.mission('s2_ep07_m3'));
      await wait(t, const Duration(milliseconds: 1400));
      await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
      return ref;
    }

    /// Taps [key]: scrolled into view in the page on top (the notebook's
    /// sheet when it is open), as a finger would.
    Future<void> tapKey(WidgetTester t, String key, {Duration after = const Duration(milliseconds: 500)}) async {
      final f = find.byKey(ValueKey(key));
      if (f.evaluate().isEmpty) {
        await t.scrollUntilVisible(f, 200, scrollable: find.byType(Scrollable).last);
      }
      await Scrollable.ensureVisible(t.element(f), alignment: 0.5);
      await t.pump();
      await t.tap(f);
      await wait(t, after);
    }

    /// `LM_SHOTS=folder`: a picture of the screen, every picture decoded.
    Future<void> shot(WidgetTester t, String name) async {
      final folder = Platform.environment['LM_SHOTS'];
      if (folder == null) return;
      await t.runAsync(() async {
        for (final e in find.byType(Image).evaluate()) {
          await precacheImage((e.widget as Image).image, e);
        }
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await t.pump();
      await t.runAsync(() async {
        final image = await t.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('shot'))).toImage(pixelRatio: 1);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        File('$folder/recall_$name.png').writeAsBytesSync(png!.buffer.asUint8List());
      });
    }

    for (final size in const [Size(360, 640), Size(390, 844), Size(820, 1180)]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}';

      testWidgets('$tag: the card, a wrong pick, a closer look, the right one beside the puzzle, the notebook and back', (t) async {
        final ref = await open(t, size, gameWith(withRecall(recall)));
        final m3 = 's2_ep07_m3';
        final key = GameProgress.examinedKey(m3, recallBroughtId);
        final coins = ref.read(walletProvider).balance;

        // The puzzle with the card on its foot, both on screen.
        expect(find.byKey(const ValueKey('rail-task')), findsOneWidget, reason: 'the puzzle');
        expect(find.byKey(const ValueKey('evidence-recall')), findsOneWidget);
        expect(find.text(EvidenceRecall.defaultTitle), findsOneWidget);
        expect(find.text(EvidenceRecall.defaultPrompt), findsOneWidget);
        final card = t.getRect(find.byKey(const ValueKey('evidence-recall')));
        expect(card.bottom, lessThanOrEqualTo(size.height + 0.5));
        expect(t.getRect(find.byKey(const ValueKey('evidence-recall-open'))).height, greaterThanOrEqualTo(48), reason: 'finger-sized');
        expect(t.takeException(), isNull, reason: '$tag: no overflow');
        await shot(t, '${tag}_1_card');

        // The notebook's evidence opens; a wrong pick says why, and stays open.
        await tapKey(t, 'evidence-recall-open', after: const Duration(milliseconds: 700));
        expect(find.text('Which clue fits? Tap it to bring it.'), findsOneWidget);
        expect(find.byKey(const ValueKey('recall-pick-s2_ep01_e1')), findsOneWidget, reason: 'Case 01 is in the notebook');
        expect(find.byKey(const ValueKey('recall-pick-s2_ep07_e3')), findsNothing, reason: 'not found yet');
        await tapKey(t, 'recall-pick-s2_ep02_e1');
        expect(findReadable("That's the Painted Street. Where is the black gate?"), findsOneWidget);
        await shot(t, '${tag}_2_wrong');
        await tapKey(t, 'recall-pick-s2_ep01_e2');
        expect(findReadable(EvidenceRecall.defaultMiss), findsOneWidget);
        expect(ref.read(gameControllerProvider).hasExamined(key), isFalse);
        expect(t.takeException(), isNull, reason: '$tag: the sheet fits');

        // A closer look first: Case 02's drawing, as the easel showed it.
        await tapKey(t, 'recall-look-s2_ep02_e3', after: const Duration(milliseconds: 600));
        final sketch = find.byWidgetPredicate((w) => w is CroppedPicture && w.file == season2Layers['s2_ep02_m3']!.sketch);
        expect(sketch, findsWidgets);
        expect(find.text('The Hidden Sketch'), findsWidgets);
        await tapText(t, 'CLOSE', after: const Duration(milliseconds: 600));

        // The right one: the sheet closes and the sketch lies beside the puzzle.
        await tapKey(t, 'recall-pick-s2_ep02_e3', after: const Duration(milliseconds: 800));
        expect(find.text('Which clue fits? Tap it to bring it.'), findsNothing);
        expect(ref.read(gameControllerProvider).hasExamined(key), isTrue);
        expect(find.byKey(const ValueKey('evidence-recall-brought')), findsOneWidget);
        expect(find.byKey(const ValueKey('evidence-recall-picture')), findsOneWidget);
        expect(find.descendant(of: find.byKey(const ValueKey('evidence-recall-picture')), matching: sketch), findsOneWidget);
        expect(find.text('NOTEBOOK · CASE 02'), findsOneWidget);
        final picture = t.getRect(find.byKey(const ValueKey('evidence-recall-picture')));
        expect(picture.height, lessThanOrEqualTo(size.height * 0.3), reason: 'the puzzle keeps most of the page');
        expect(t.takeException(), isNull, reason: '$tag: no overflow with the sketch open');
        await shot(t, '${tag}_3_brought');

        // Folded away, opened again; its close look.
        await tapKey(t, 'evidence-recall-fold');
        expect(find.byKey(const ValueKey('evidence-recall-picture')), findsNothing);
        await tapKey(t, 'evidence-recall-fold');
        await tapKey(t, 'evidence-recall-picture', after: const Duration(milliseconds: 600));
        expect(find.text('EVIDENCE'), findsOneWidget);
        await tapText(t, 'CLOSE', after: const Duration(milliseconds: 600));

        // The notebook and back: the puzzle and the card as they were.
        await t.tap(find.byTooltip('Detective notebook'));
        await wait(t, const Duration(milliseconds: 900));
        expect(find.byType(NotebookScreen), findsOneWidget);
        await t.tap(find.byTooltip('Close'));
        await wait(t, const Duration(milliseconds: 900));
        expect(find.byType(NotebookScreen), findsNothing);
        expect(ref.read(routerProvider).routerDelegate.currentConfiguration.uri.path, Routes.mission(m3));
        expect(find.byKey(const ValueKey('evidence-recall-brought')), findsOneWidget);
        expect(find.byKey(const ValueKey('rail-task')), findsOneWidget, reason: 'the puzzle as it was');

        // Nothing paid, nothing lost; the puzzle is answered as ever; then no card.
        expect(ref.read(walletProvider).balance, coins);
        expect(ref.read(gameControllerProvider).wrongCount(m3), 0, reason: 'a wrong pick is not a wrong answer');
        expect(ref.read(gameControllerProvider).hintsFor(m3), 0);
        final m = ref.read(currentEpisodeProvider).missionById(m3)!;
        expect(ref.read(gameControllerProvider.notifier).submitAnswer(m, m.answer).result, SubmitResult.correct);
        expect(XpBreakdown.of(m, ref.read(gameControllerProvider)).total, AppConstants.missionXp, reason: 'the full XP');
        await wait(t, const Duration(milliseconds: 600));
        expect(find.byKey(const ValueKey('evidence-recall')), findsNothing);
        expect(t.takeException(), isNull);
      });
    }

    testWidgets('the puzzle is answered without the card; no card on a mission without a recall, or with evidence not held', (t) async {
      const size = Size(390, 844);
      // Without the card: the right answer as ever.
      var ref = await open(t, size, gameWith(withRecall(recall)));
      expect(find.byKey(const ValueKey('evidence-recall-open')), findsOneWidget);
      final m = ref.read(currentEpisodeProvider).missionById('s2_ep07_m3')!;
      expect(ref.read(gameControllerProvider.notifier).submitAnswer(m, m.answer).result, SubmitResult.correct);

      // The game as it is: Case 07 Mission 03 has no card.
      ref = await open(t, size, inGame);
      expect(find.byKey(const ValueKey('evidence-recall')), findsNothing);

      // Evidence of another season, or none: no card, the puzzle as ever.
      for (final id in ['e01', 'nowhere']) {
        ref = await open(t, size, gameWith(withRecall({'evidence': id})));
        expect(find.byKey(const ValueKey('evidence-recall')), findsNothing, reason: id);
        expect(t.takeException(), isNull, reason: id);
      }
    });

    testWidgets('brought once, kept after a restart; played again, asked again', (t) async {
      const size = Size(390, 844);
      final game = gameWith(withRecall(recall));
      var ref = await open(t, size, game);
      await tapKey(t, 'evidence-recall-open', after: const Duration(milliseconds: 700));
      await tapKey(t, 'recall-pick-s2_ep02_e3', after: const Duration(milliseconds: 800));
      final key = GameProgress.examinedKey('s2_ep07_m3', recallBroughtId);
      expect(ref.read(progressRepositoryProvider).load('s2_ep07').hasExamined(key), isTrue, reason: 'saved');

      // A restart on the same storage: the card holds the sketch, folded.
      final prefs = ref.read(sharedPreferencesProvider);
      await t.pumpWidget(const SizedBox());
      await t.pumpWidget(ProviderScope(
        overrides: [...await testOverridesFor(prefs), allEpisodesProvider.overrideWithValue(game)],
        child: Consumer(builder: (context, r, _) {
          ref = r;
          return const LondonMysteryApp();
        }),
      ));
      await wait(t, const Duration(milliseconds: 300));
      ref.read(routerProvider).go(Routes.mission('s2_ep07_m3'));
      await wait(t, const Duration(milliseconds: 1400));
      if (find.text('INVESTIGATE').evaluate().isNotEmpty) {
        await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
      }
      expect(find.byKey(const ValueKey('evidence-recall-brought')), findsOneWidget);
      expect(find.byKey(const ValueKey('evidence-recall-picture')), findsNothing, reason: 'folded until opened');

      // The case played again from its start: the card asks again.
      ref.read(gameControllerProvider.notifier).playAgain();
      expect(ref.read(gameControllerProvider).hasExamined(key), isFalse);
    });
  });
}
