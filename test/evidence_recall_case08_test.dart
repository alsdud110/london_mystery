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
import 'package:london_mystery/data/models/episode.dart';
import 'package:london_mystery/data/mock/season_catalog.dart';
import 'package:london_mystery/data/models/abbesses_puzzles.dart' show TornHourScene;
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/garden_puzzles.dart' show TowerTestScene;
import 'package:london_mystery/data/models/star_puzzles.dart' show HourRecordScene;
import 'package:london_mystery/data/models/mission.dart' show EvidenceRecall;
import 'package:london_mystery/data/models/season.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/game/wallet_controller.dart';
import 'package:london_mystery/features/mission/widgets/evidence_recall.dart';
import 'package:london_mystery/features/mission/widgets/opera_papers.dart' show AmendmentSlipView;
import 'package:london_mystery/features/mission/widgets/workshop_papers.dart' show CroppedPicture;
import 'package:london_mystery/features/notebook/notebook_screen.dart';
import 'package:london_mystery/widgets/game_button.dart';

import 'full_playthrough_test.dart' show tapText, wait;
import 'helpers.dart';

/// Written while Season 2 Case 08 was being planned (it is in the game now,
/// played on its own pictures: `paris_case08_test.dart`). These tests play
/// two missions shaped like its M1 and M3 as plain choices (a stand-in case
/// of this file only, after the real Case 08; the game's own cases
/// unchanged) in the real app — its mission page, router, saves and
/// notebook — with the Evidence Recall card:
///
/// - M1: the Hidden Sketch of Case 02 brought, to compare with the places
///   where the painter may have sat (four choices);
/// - M3: the Amendment Slip of Case 07 brought, its stamp to compare with
///   a badge; the Clockmaker's Mark and the Repair Card picked instead say
///   why they do not fit.
///
/// `LM_SHOTS=folder` saves a picture of the main steps.
void main() {
  final inGame = MockEpisodeRepository.bundled();
  final s1 = season1Cases();

  /// A stand-in case after the real Case 10: Case 07's missions under ids of
  /// their own (so none of Case 07's scenes: plain choices), M1 and M3
  /// played with a recall.
  Episode case08() {
    final text = jsonEncode(season2Json['s2_ep07']).replaceAll('"s2_ep07', '"s2_ep11');
    final json = jsonDecode(text) as Map<String, dynamic>;
    final missions = json['missions'] as List;
    missions[0] = {
      ...missions[0] as Map<String, dynamic>,
      'title': 'A View from Above',
      'question': 'Where did the painter sit to draw this?',
      'options': [
        {'id': 'a', 'label': 'At the bottom of the steps', 'feedback': 'Where is the white church?'},
        {'id': 'b', 'label': 'At the café table', 'feedback': 'Is the lamp left of the gate?'},
        {'id': 'c', 'label': 'By the metro sign', 'feedback': 'Can you see the black gate?'},
        {'id': 'd', 'label': 'On the bench above the steps'},
      ],
      'answer': 'd',
      'hints': ['Remember the drawing the painter hid?', 'Look at the lamp, the gate and the church.'],
      'recall': {
        'evidence': 's2_ep02_e3',
        'title': 'These steps look familiar...',
        'prompt': 'Find the drawing the painter hid.',
        'feedback': {
          's2_ep02_e1': 'That street has a red door. Look for steps and a gate.',
          's2_ep07_e3': 'That one led you here. Find the one he hid.',
        },
      },
    };
    missions[2] = {
      ...missions[2] as Map<String, dynamic>,
      'title': 'The Badge in the Border',
      'question': 'Where have you seen this badge before?',
      'options': [
        {'id': 'gear', 'label': 'On the old station clock', 'feedback': 'That mark is a gear.'},
        {'id': 'hands', 'label': 'On the repair card', 'feedback': 'Count the hands.'},
        {'id': 'slip', 'label': 'On the opera slip'},
      ],
      'answer': 'slip',
      'hints': ['A clock with no hands, in a ring of leaves.', 'Look at the stamps in your notebook.'],
      'recall': {
        'evidence': 's2_ep07_e3',
        'feedback': {
          's2_ep01_e3': 'That mark is a gear. Is this a gear?',
          's2_ep05_e1': 'Count the hands. This badge has none.',
        },
      },
    };
    return Episode.fromJson({...json, 'number': 11, 'seasonId': SeasonIds.paris});
  }

  final fixture = case08();
  final game = [...inGame, fixture];
  final [m1, m2, m3, _] = fixture.allMissions;

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

  /// The app with Season 1 and Paris Cases 01–10 solved, the stand-in case
  /// open, its missions before [missionId] solved; [missionId] opened at
  /// its place.
  Future<WidgetRef> open(WidgetTester t, Size size, String missionId) async {
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
    await t.pumpWidget(const SizedBox());
    await t.pumpWidget(ProviderScope(
      overrides: [
        ...await testOverrides(prefs: {
          AppConstants.progressStorageKey: jsonEncode(solved(s1.first).toJson()),
          for (final e in s1.skip(1)) AppConstants.progressKeyFor(e.id): jsonEncode(solved(e).toJson()),
          AppConstants.seasonStorageKey: jsonEncode(SeasonProgress(activeEpisodeId: 'ep12', solvedEpisodeIds: [for (final e in s1) e.id]).toJson()),
        }),
        allEpisodesProvider.overrideWithValue(game),
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
    final g = ref.read(gameControllerProvider.notifier);
    expect(g.openSeason(SeasonIds.paris), isTrue);
    for (final e in game.where((e) => e.seasonId == SeasonIds.paris && e.number <= 10)) {
      expect(g.openEpisode(e.id), isTrue, reason: e.id);
      g.startInvestigation();
      for (final m in e.allMissions) {
        g.submitAnswer(m, m.answer);
      }
      // Case 08 closes with its last drawing, Case 09 with its star, Case 10
      // with its record list, after their finals' answers.
      if (SeasonCatalog.closesAfterLastStep(e.finalMission)) {
        final step = SeasonCatalog.hourRecord(e.finalMission) != null
            ? HourRecordScene.leadId
            : SeasonCatalog.towerTest(e.finalMission) != null
            ? TowerTestScene.leadId
            : TornHourScene.leadId;
        expect(g.closeCase(GameProgress.examinedKey(e.finalMission.id, step)), isTrue, reason: e.id);
      }
    }
    expect(g.openEpisode('s2_ep11'), isTrue, reason: 'the stand-in case opens after the real Case 10');
    g.startInvestigation();
    for (final m in fixture.missions.takeWhile((m) => m.id != missionId)) {
      expect(g.submitAnswer(m, m.answer).result, SubmitResult.correct);
    }
    ref.read(routerProvider).go(Routes.mission(missionId));
    await wait(t, const Duration(milliseconds: 1400));
    return ref;
  }

  /// Taps [key], scrolled into view in the page on top (the notebook's sheet
  /// when it is open).
  Future<void> tapKey(WidgetTester t, String key, {Duration after = const Duration(milliseconds: 500)}) async {
    final f = find.byKey(ValueKey(key));
    if (f.evaluate().isEmpty) {
      // The sheet's own list (its grids do not scroll).
      final list = find.descendant(of: find.byType(DraggableScrollableSheet), matching: find.byType(Scrollable)).first;
      // Up to the top first, then down until it is there.
      t.state<ScrollableState>(list).position.jumpTo(0);
      await t.pump();
      if (f.evaluate().isEmpty) await t.scrollUntilVisible(f, 200, scrollable: list);
    }
    await Scrollable.ensureVisible(t.element(f), alignment: 0.5);
    await t.pump();
    await t.tap(f);
    await wait(t, after);
  }

  /// Scrolls the mission page (never the card) until [f] is in view.
  Future<void> revealOnPage(WidgetTester t, Finder f) async {
    await Scrollable.ensureVisible(t.element(f), alignment: 0.3);
    await t.pump();
  }

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
      File('$folder/case08_$name.png').writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  /// CHECK ANSWER, and whether it can be pressed (an answer is chosen).
  bool canCheck(WidgetTester t) => t.widget<GameButton>(find.widgetWithText(GameButton, 'CHECK ANSWER')).onPressed != null;

  final dock = find.byKey(const ValueKey('evidence-recall'));
  final picture = find.byKey(const ValueKey('evidence-recall-picture'));
  final layer = season2Layers['s2_ep02_m3']!;
  final sketch = find.byWidgetPredicate((w) => w is CroppedPicture && w.file == layer.sketch && w.crop == layer.view);

  for (final size in const [Size(360, 640), Size(390, 844), Size(820, 1180)]) {
    final tag = '${size.width.toInt()}x${size.height.toInt()}';

    testWidgets('$tag M1: the Hidden Sketch brought beside the four places, the answer kept through looks, the notebook and back', (t) async {
      final ref = await open(t, size, m1.id);
      final coins = ref.read(walletProvider).balance;

      // The place, then the sealed letter: no card before the letter is open.
      await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
      expect(find.text('TAP TO OPEN'), findsOneWidget);
      expect(dock, findsNothing, reason: 'the letter first');
      await tapText(t, 'TAP TO OPEN', after: const Duration(milliseconds: 1800));
      expect(dock, findsOneWidget, reason: 'under the open letter');
      expect(find.text('These steps look familiar...'), findsOneWidget);
      expect(find.text('Find the drawing the painter hid.'), findsOneWidget);
      // SOLVE THE PUZZLE is never under the card.
      await revealOnPage(t, find.text('SOLVE THE PUZZLE'));
      expect(t.getRect(find.text('SOLVE THE PUZZLE')).bottom, lessThanOrEqualTo(t.getRect(dock).top));
      expect(t.takeException(), isNull, reason: '$tag letter');
      await tapText(t, 'SOLVE THE PUZZLE', after: const Duration(milliseconds: 900));
      expect(dock, findsOneWidget, reason: 'one card, on to the puzzle');
      await shot(t, '${tag}_m1_puzzle');

      // An answer chosen before anything is brought: it is kept through all that follows.
      await tapText(t, 'On the bench above the steps', after: const Duration(milliseconds: 300));
      expect(canCheck(t), isTrue);

      // The notebook's evidence: two wrong picks say why; the right one is brought.
      await tapKey(t, 'evidence-recall-open', after: const Duration(milliseconds: 700));
      await tapKey(t, 'recall-pick-s2_ep07_e3');
      expect(findReadable('That one led you here. Find the one he hid.'), findsOneWidget);
      await tapKey(t, 'recall-pick-s2_ep02_e1');
      expect(findReadable('That street has a red door. Look for steps and a gate.'), findsOneWidget);
      await shot(t, '${tag}_m1_wrong');
      await tapKey(t, 'recall-pick-s2_ep02_e3', after: const Duration(milliseconds: 800));
      expect(dock, findsOneWidget);
      expect(find.descendant(of: picture, matching: sketch), findsOneWidget, reason: "Case 02's sketch, as its easel showed it");
      expect(t.takeException(), isNull, reason: '$tag sketch open');
      await shot(t, '${tag}_m1_brought');

      // Compared without scrolling the card: each place and CHECK ANSWER can
      // be brought into view above it, the sketch still open.
      final cardTop = t.getRect(dock).top;
      for (final label in ['At the bottom of the steps', 'On the bench above the steps', 'CHECK ANSWER']) {
        await revealOnPage(t, find.text(label));
        final r = t.getRect(find.text(label));
        expect(r.bottom, lessThanOrEqualTo(cardTop), reason: '$tag $label above the card');
        expect(r.top, greaterThanOrEqualTo(0), reason: '$tag $label on screen');
        expect(picture, findsOneWidget, reason: 'the sketch stays open');
      }
      expect(canCheck(t), isTrue, reason: 'the answer chosen is kept');

      // Folded and opened again.
      await tapKey(t, 'evidence-recall-fold');
      expect(picture, findsNothing);
      await tapKey(t, 'evidence-recall-fold');
      expect(picture, findsOneWidget);

      // A closer look, closed with Android's back: the page as it was.
      await tapKey(t, 'evidence-recall-picture', after: const Duration(milliseconds: 600));
      expect(find.text('EVIDENCE'), findsOneWidget);
      await t.binding.handlePopRoute();
      await wait(t, const Duration(milliseconds: 600));
      expect(find.text('EVIDENCE'), findsNothing);
      expect(ref.read(routerProvider).routerDelegate.currentConfiguration.uri.path, Routes.mission(m1.id));
      expect(canCheck(t), isTrue);
      expect(picture, findsOneWidget);

      // The notebook, left with Android's back, then with its own close.
      for (final leave in ['system back', 'close']) {
        await t.tap(find.byTooltip('Detective notebook'));
        await wait(t, const Duration(milliseconds: 900));
        expect(find.byType(NotebookScreen), findsOneWidget, reason: leave);
        if (leave == 'close') {
          await t.tap(find.byTooltip('Close'));
        } else {
          await t.binding.handlePopRoute();
        }
        await wait(t, const Duration(milliseconds: 900));
        expect(find.byType(NotebookScreen), findsNothing, reason: leave);
        expect(dock, findsOneWidget, reason: '$leave: one card, as it was');
        expect(find.byKey(const ValueKey('evidence-recall-brought')), findsOneWidget, reason: leave);
        expect(canCheck(t), isTrue, reason: '$leave: the answer chosen is kept');
      }

      // Nothing paid or lost for the picks; the answer as ever, then no card.
      expect(ref.read(walletProvider).balance, coins);
      expect(ref.read(gameControllerProvider).wrongCount(m1.id), 0);
      expect(ref.read(gameControllerProvider).hintsFor(m1.id), 0);
      await revealOnPage(t, find.text('CHECK ANSWER'));
      await t.tap(find.text('CHECK ANSWER'));
      await wait(t, const Duration(milliseconds: 1500));
      expect(ref.read(gameControllerProvider).isCompleted(m1.id), isTrue);
      expect(dock, findsNothing, reason: 'solved: the card is gone');
      expect(t.takeException(), isNull, reason: '$tag solved');
    });
  }

  testWidgets('M1 without the card: the place is chosen from memory, the answer as ever', (t) async {
    final ref = await open(t, const Size(390, 844), m1.id);
    await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
    await tapText(t, 'TAP TO OPEN', after: const Duration(milliseconds: 1800));
    await tapText(t, 'SOLVE THE PUZZLE', after: const Duration(milliseconds: 900));
    expect(find.byKey(const ValueKey('evidence-recall-open')), findsOneWidget);
    await tapText(t, 'On the bench above the steps', after: const Duration(milliseconds: 300));
    await revealOnPage(t, find.text('CHECK ANSWER'));
    await t.tap(find.text('CHECK ANSWER'));
    await wait(t, const Duration(milliseconds: 1500));
    expect(ref.read(gameControllerProvider).isCompleted(m1.id), isTrue);
    expect(ref.read(gameControllerProvider).hasExamined(GameProgress.examinedKey(m1.id, recallBroughtId)), isFalse);
    expect(t.takeException(), isNull);
  });

  testWidgets('M3: the Amendment Slip brought beside the badge; the gear and the two hands say why not; turned and back', (t) async {
    const size = Size(390, 844);
    final ref = await open(t, size, m3.id);
    expect(ref.read(gameControllerProvider).isCompleted(m2.id), isTrue);
    await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 900));
    await tapText(t, 'TAP TO OPEN', after: const Duration(milliseconds: 1800));
    await tapText(t, 'SOLVE THE PUZZLE', after: const Duration(milliseconds: 900));
    expect(find.text(EvidenceRecall.defaultTitle), findsOneWidget, reason: "the app's words when the mission gives none");

    await tapKey(t, 'evidence-recall-open', after: const Duration(milliseconds: 700));
    // Case 01's mark has no picture yet: its tile shows its ink symbol.
    expect(find.byKey(const ValueKey('recall-pick-s2_ep01_e3')), findsOneWidget);
    await tapKey(t, 'recall-pick-s2_ep01_e3');
    expect(findReadable('That mark is a gear. Is this a gear?'), findsOneWidget);
    await tapKey(t, 'recall-pick-s2_ep05_e1');
    expect(findReadable('Count the hands. This badge has none.'), findsOneWidget);
    // Looked at closer before it is brought: its words and its stamp.
    await tapKey(t, 'recall-look-s2_ep07_e3', after: const Duration(milliseconds: 600));
    expect(find.text('The Amendment Slip'), findsWidgets);
    expect(findReadableContaining('A round stamp: a clock with no hands'), findsOneWidget);
    expect(find.byType(AmendmentSlipView), findsWidgets);
    await tapText(t, 'CLOSE', after: const Duration(milliseconds: 600));
    await tapKey(t, 'recall-pick-s2_ep07_e3', after: const Duration(milliseconds: 800));
    expect(find.descendant(of: picture, matching: find.byType(AmendmentSlipView)), findsOneWidget, reason: 'the slip with its stamp, beside the puzzle');
    expect(find.text('NOTEBOOK · CASE 07'), findsOneWidget);
    expect(t.getRect(picture).height, lessThanOrEqualTo(size.height * 0.3));
    await shot(t, 'm3_brought');
    await tapKey(t, 'evidence-recall-picture', after: const Duration(milliseconds: 600));
    await shot(t, 'm3_zoom');
    await tapText(t, 'CLOSE', after: const Duration(milliseconds: 600));

    // The three choices and CHECK ANSWER come into view above the open slip.
    final cardTop = t.getRect(dock).top;
    for (final label in ['On the old station clock', 'On the opera slip', 'CHECK ANSWER']) {
      await revealOnPage(t, find.text(label));
      expect(t.getRect(find.text(label)).bottom, lessThanOrEqualTo(cardTop), reason: label);
    }

    // Turned on its side and back (a rebuild): no overflow, the slip still open.
    await tapText(t, 'On the opera slip', after: const Duration(milliseconds: 300));
    t.view.physicalSize = const Size(844, 390) * 3;
    await wait(t, const Duration(milliseconds: 400));
    expect(t.takeException(), isNull, reason: 'landscape');
    expect(picture, findsOneWidget);
    t.view.physicalSize = size * 3;
    await wait(t, const Duration(milliseconds: 400));
    expect(t.takeException(), isNull, reason: 'portrait again');
    expect(picture, findsOneWidget);
    expect(dock, findsOneWidget);
    expect(canCheck(t), isTrue, reason: 'the answer chosen is kept');
  });
}
