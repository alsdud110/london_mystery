import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:world_mystery/app.dart';
import 'package:world_mystery/core/router/app_router.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/mission.dart';
import 'package:world_mystery/data/models/profile.dart';
import 'package:world_mystery/data/models/scene_explore.dart';
import 'package:world_mystery/features/game/game_controller.dart';
import 'package:world_mystery/features/game/game_providers.dart';

import '../test/helpers.dart' show testOverrides;
import '../test/sandbox/rome_c01_08_season.dart';

/// STEP 3-15B B1, B2: Rome's Cases 01–08 (test-only, never in
/// `SeasonCatalog`) on a device or emulator, the screens the asset
/// pipeline's pictures are shown on captured by the app itself
/// (`takeScreenshot`), written on the host by `test_driver/rome_qa_driver.dart`
/// under `qa/screenshots/rome/<width>x<height>/`: the two measured look rounds
/// (opening view, a note, a hint opened, the document, the choice, a wrong
/// answer), the talks over the new places (Pia, Aldo, Livia), the places of
/// Cases 06–08 and Case 08's three bridges. Missions before a captured screen
/// are answered through the controller, not played: the play itself is
/// `test/sandbox/s3_rome_c01_08_test.dart`.
///
/// The game runs on in-memory storage only (`testOverrides`).
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  final episodes = romeC0108Episodes();

  testWidgets('Rome Cases 01–08, the pictures on screen, captured', (t) async {
    registerRomeC0108();
    addTearDown(unregisterRomeC0108);
    final c = ProviderContainer(overrides: [...await testOverrides(), ...romeC0108Overrides()]);
    addTearDown(c.dispose);
    final ctrl = c.read(gameControllerProvider.notifier);
    ctrl.createDetective('Minyoung', DetectiveAvatar.girl);
    c.read(seasonPreviewSwitchProvider.notifier).set(true);
    c.read(operatorAccessSwitchProvider.notifier).set(true); // later cases opened directly
    expect(ctrl.openSeason(romeC0108SeasonId), isTrue);
    expect(ctrl.openEpisode('s3_ep01'), isTrue);
    await t.pumpWidget(UncontrolledProviderScope(container: c, child: const WorldMysteryApp()));

    Future<void> pause(int ms) async {
      await Future<void>.delayed(Duration(milliseconds: ms));
      await t.pump();
    }

    await pause(1500);
    await binding.convertFlutterSurfaceToImage();
    await pause(300);
    final size = t.view.physicalSize / t.view.devicePixelRatio;
    final tag = '${size.width.round()}x${size.height.round()}';

    Future<void> shot(String name) async {
      await pause(500);
      await binding.takeScreenshot('$tag/$name');
      await pause(150);
    }

    Future<void> until(Finder f, {int limitMs = 20000}) async {
      for (var waited = 0; waited < limitMs && f.evaluate().isEmpty; waited += 100) {
        await pause(100);
      }
      expect(f, findsWidgets);
    }

    Future<void> tapF(Finder f, {int after = 600}) async {
      await until(f);
      await Scrollable.ensureVisible(t.element(f.last), alignment: 0.5);
      await pause(250);
      await t.tap(f.last);
      await pause(after);
    }

    Future<void> tapText(String text, {int after = 600}) => tapF(find.text(text), after: after);

    /// Straight to [m]'s place, as the map's GO opens it (the map itself is
    /// Paris's, lent: not what is checked here); [before] captures the
    /// place's page first.
    Future<void> toPlace(Mission m, {String? before}) async {
      c.read(routerProvider).go(Routes.map);
      await pause(1500);
      c.read(routerProvider).go(Routes.mission(m.id));
      final go = find.text('INVESTIGATE');
      for (var waited = 0; waited < 10000 && go.evaluate().isEmpty; waited += 100) {
        await pause(100);
      }
      if (go.evaluate().isEmpty) await shot('no_investigate_${m.id}');
      if (before != null) {
        await pause(2500);
        await shot(before);
      }
      await tapText('INVESTIGATE', after: 1200);
    }

    /// Answered through the controller (not played on screen).
    void answered(Mission m) => ctrl.submitAnswer(m, m.answer);

    Future<void> openCase(Episode e) async {
      expect(ctrl.openEpisode(e.id), isTrue);
      c.read(routerProvider).go(Routes.intro);
      await pause(1500);
      await tapText('SKIP ›', after: 1200);
      await tapText("I'M READY", after: 2500);
    }

    Future<void> tapPicture(Offset point, {int after = 900}) async {
      final r = t.getRect(find.byKey(const ValueKey('explore-picture')));
      await t.tapAt(Offset(r.left + point.dx * r.width, r.top + point.dy * r.height));
      await pause(after);
    }

    Future<void> closeCard() => tapF(find.byKey(const ValueKey('explore-close')), after: 700);

    /// A measured look round: as it opens, a note, a hint, the document
    /// (its way back on screen), the view after it with the hint still
    /// open, the choice, a wrong answer.
    Future<void> lookRound(String prefix, Mission m, String note) async {
      final explore = romeC0108Content.explores[m.id]!;
      await until(find.byKey(const ValueKey('explore-picture')));
      await pause(1500);
      await shot('${prefix}a_opening');
      await tapPicture(explore.spots.firstWhere((s) => s.id == note).areas.first.center);
      await shot('${prefix}b_note_$note');
      await closeCard();
      await tapText('Get a Free Hint', after: 1200);
      await shot('${prefix}c_hint_opened');
      await tapPicture(explore.document!.areas.first.center, after: 1500);
      if (find.text('TAP TO OPEN').evaluate().isNotEmpty) await tapText('TAP TO OPEN', after: 2000);
      await shot('${prefix}d_document');
      await t.tap(find.byKey(const ValueKey('explore-close')));
      await pause(900);
      await shot('${prefix}e_hint_and_document_read');
      final choice = explore.spots.firstWhere((s) => s.kind == ExploreKind.choice);
      final view = t.getRect(find.byType(InteractiveViewer));
      final r = t.getRect(find.byKey(const ValueKey('explore-picture')));
      final at = Offset(r.left + choice.areas.first.center.dx * r.width, r.top + choice.areas.first.center.dy * r.height);
      if (!view.deflate(12).contains(at)) {
        // ignore: avoid_print
        print('$tag ${m.id}: the choice is out of view after the hint, dragged into it');
        await t.dragFrom(view.center, view.center - at);
        await pause(900);
      }
      await tapPicture(choice.areas.first.center, after: 1500);
      await shot('${prefix}f_choice');
      final wrong = m.options.firstWhere((o) => o.id != m.answer && (o.feedback ?? '').isNotEmpty);
      await tapF(find.byKey(ValueKey('poster-${wrong.id}')), after: 400);
      await tapF(find.byKey(const ValueKey('explore-check')), after: 1500);
      await shot('${prefix}g_wrong');
      await tapText('TRY AGAIN', after: 900);
    }

    final [e01, _, e03, e04, _, e06, e07, e08] = episodes;

    // ── Case 01 M3: the map hall, its look round.
    await openCase(e01);
    answered(e01.missions[0]);
    answered(e01.missions[1]);
    await toPlace(e01.missions[2]);
    await lookRound('01_c01_m3_', e01.missions[2], 'statue');

    // ── Case 03 M1: Pia's talk over the flower market drawn again in B2.
    await openCase(e03);
    await toPlace(e03.missions[0], before: '02_c03_m1_place_flower_market');
    await pause(1500);
    await shot('03_c03_m1_talk_pia');

    // ── Case 04 M1: the Pantheon, its eye and its four stones.
    await openCase(e04);
    await toPlace(e04.missions[0]);
    await lookRound('04_c04_m1_', e04.missions[0], 'eye');

    // ── Case 06: Piazza Navona (Giulia's talk), Hall B (Aldo's talk).
    await openCase(e06);
    await toPlace(e06.missions[0], before: '05_c06_m1_place_navona');
    await pause(1500);
    await shot('06_c06_m1_talk_giulia');
    answered(e06.missions[0]);
    await toPlace(e06.missions[1], before: '07_c06_m2_place_lecture_hall');
    await pause(1500);
    await shot('08_c06_m2_talk_aldo');

    // ── Case 07 M1: the Spanish Steps.
    await openCase(e07);
    await toPlace(e07.missions[0], before: '09_c07_m1_place_spanish_steps');

    // ── Case 08: the three bridges, the Owl's talk, the lab.
    await openCase(e08);
    final bridges = e08.missions[0];
    await toPlace(bridges, before: '10_c08_m1_place_tiber_bridge');
    await tapText('TAP TO OPEN', after: 2000);
    await tapText('SOLVE THE PUZZLE', after: 1500);
    await pause(2500);
    await shot('11_c08_m1_three_bridges');
    final wrong = bridges.options.indexWhere((o) => o.id != bridges.answer);
    final o = bridges.options[wrong];
    await tapF(find.bySemanticsLabel('Picture ${String.fromCharCode(65 + wrong)}${o.altText == null ? '' : ': ${o.altText}'}'));
    await tapText('CHECK ANSWER', after: 1500);
    await shot('12_c08_m1_wrong_bridge');
    await tapText('TRY AGAIN', after: 900);
    answered(bridges);
    await toPlace(e08.missions[1]);
    await pause(1500);
    await shot('13_c08_m2_talk_livia_hood');
    answered(e08.missions[1]);
    await toPlace(e08.missions[2], before: '14_c08_m3_place_restoration_lab');
  });
}
