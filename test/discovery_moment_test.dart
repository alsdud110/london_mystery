import 'dart:ui' show AccessibilityFeatures;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/mock/season1/season1_discoveries.dart';
import 'package:london_mystery/data/models/discovery.dart';
import 'package:london_mystery/data/models/episode.dart';
import 'package:london_mystery/data/models/mission.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/scoring.dart';
import 'package:london_mystery/features/mission/widgets/answer_feedback.dart';

import 'full_playthrough_test.dart' show reveal, tapText, wait;
import 'helpers.dart';
import 'mission_play.dart';
import 'title_screen_test.dart' show capture;

/// The Discovery Moment: after a regular mission's correct answer, what the
/// detective just found or worked out, in the place it happened, then the
/// XP, then CONTINUE (only when the detective taps it).
void main() {
  final season = MockEpisodeRepository.bundled();
  Episode caseOf(String missionId) => season.firstWhere((e) => e.missions.any((m) => m.id == missionId));
  Mission mission(String id) => caseOf(id).missionById(id)!;
  final regular = [for (final e in season) ...e.missions];
  final labels = {for (final t in DiscoveryType.values) t.label};

  group('the discoveries of Season 1', () {
    test('every regular mission has its own; no final case has one', () {
      expect(regular, hasLength(38));
      for (final m in regular) {
        expect(season1Discoveries, contains(m.id), reason: m.id);
      }
      for (final e in season) {
        expect(season1Discoveries, isNot(contains(e.finalMission.id)), reason: e.id);
      }
      expect(season1Discoveries, hasLength(38));
    });

    test('a mission without one falls back to a solved puzzle, its success line', () {
      final m = Mission.fromJson({...regular.first.toJson(), 'id': 'not_in_season'});
      final d = discoveryOf(m);
      expect(d.type, DiscoveryType.puzzleComplete);
      expect(d.title, m.successMessage);
      expect(d.showEvidence, isFalse);
    });

    test('evidence is only shown where the mission has it; one line is not said twice', () {
      for (final m in regular) {
        final d = discoveryOf(m);
        if (d.showEvidence) expect(m.evidence, isNotNull, reason: m.id);
        expect(d.detail, isNot(d.title), reason: m.id);
        expect(d.note, isNot(d.detail), reason: m.id);
        if (d.showEvidence) expect(d.detail, isNot(contains(m.evidence!.inscription!)), reason: '${m.id}: the card says it');
      }
    });

    test('11. what was seen before the puzzle is confirmed or noted, never found', () {
      for (final m in regular) {
        final d = discoveryOf(m);
        if (d.timing == DiscoveryTiming.beforePuzzle) {
          expect(d.type, isNot(DiscoveryType.evidenceFound), reason: m.id);
          expect(d.type, isNot(DiscoveryType.clueFound), reason: m.id);
          expect(d.showEvidence, isFalse, reason: m.id);
        }
        if (d.type == DiscoveryType.evidenceFound) {
          expect(d.timing, DiscoveryTiming.fromPuzzle, reason: m.id);
          expect(d.showEvidence, isTrue, reason: '${m.id}: found evidence is shown');
        }
      }
      // Evidence the detective held before the puzzle is never laid out as new.
      for (final id in ['m01', 'm02', 'm04', 'ep02_m1', 'ep02_m3', 'ep03_m1', 'ep03_m2', 'ep04_m1', 'ep04_m2', 'ep04_m3',
          'ep05_m1', 'ep05_m2', 'ep06_m1', 'ep06_m2', 'ep08_m1', 'ep08_m2', 'ep10_m2', 'ep11_m1', 'ep11_m2', 'ep12_m2']) {
        expect(discoveryOf(mission(id)).showEvidence, isFalse, reason: id);
      }
      expect(discoveryOf(mission('ep08_m1')).type, DiscoveryType.clueConfirmed);
      expect(discoveryOf(mission('ep04_m1')).type, DiscoveryType.newLead);
    });

    test('12–14. the timing exceptions: ticket, letter, seven ravens', () {
      String all(String id) {
        final d = discoveryOf(mission(id));
        return [d.type.label, d.title, d.detail, ?d.note].join(' ');
      }

      final c06 = discoveryOf(mission('ep06_m3'));
      expect(c06.type, DiscoveryType.storyDiscovery);
      expect(c06.showEvidence, isFalse);
      expect(all('ep06_m3').toLowerCase(), allOf(isNot(contains('ticket')), isNot(contains('row r'))));
      expect(mission('ep06_m3').transition.first, contains('gives you a theatre ticket'), reason: 'the scene hands it over');

      final c10 = discoveryOf(mission('ep10_m3'));
      expect(c10.type, DiscoveryType.newLead);
      expect(c10.showEvidence, isFalse);
      expect(all('ep10_m3').toLowerCase(), isNot(contains('letter')));

      final c12 = discoveryOf(mission('ep12_m3'));
      expect(c12.type, DiscoveryType.newLead);
      expect(all('ep12_m3').toLowerCase(), allOf(isNot(contains('seven')), isNot(contains('raven'))));
    });

    test('the discoveries the reasoning needs are on screen', () {
      expect(discoveryOf(mission('ep03_m3')).showEvidence, isTrue);
      expect(mission('ep03_m3').evidence!.inscription, contains('trains and smoke'));
      expect(discoveryOf(mission('ep05_m3')).showEvidence, isTrue);
      expect(discoveryOf(mission('ep05_m3')).seasonClue, isTrue);
      expect(discoveryOf(mission('ep07_m3')).detail, contains('north'));
      expect(discoveryOf(mission('ep07_m3')).showEvidence, isFalse, reason: "its card names the final's spot");
      expect(discoveryOf(mission('ep10_m1')).showEvidence, isTrue);
      expect(discoveryOf(mission('ep11_m1')).title, 'A TRAIN WHISTLE');
      expect(discoveryOf(mission('ep02_m2')).seasonClue, isTrue);
      // Notes keep what a later lock needs (Case 01's numbers, Case 05's).
      for (final id in ['m01', 'm02', 'm04', 'ep05_m1', 'ep05_m2']) {
        expect(discoveryOf(mission(id)).note, isNotNull, reason: id);
      }
    });
  });

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

  group('every discovery on screen', () {
    // 8–9. All 38, at both sizes: nothing overflows; CONTINUE can be reached.
    for (final size in const [Size(360, 640), Size(390, 844)]) {
      testWidgets('all 38 at ${size.width.toInt()}x${size.height.toInt()}', (t) async {
        t.view.physicalSize = size * 3;
        t.view.devicePixelRatio = 3;
        addTearDown(t.view.reset);
        late BuildContext context;
        await t.pumpWidget(ProviderScope(
          overrides: await testOverrides(),
          child: MaterialApp(home: Builder(builder: (c) {
            context = c;
            return const Scaffold();
          })),
        ));
        for (final m in regular) {
          final d = discoveryOf(m);
          final closed = showDiscoveryMoment(context,
              mission: m, discovery: d, xp: const XpBreakdown(base: 100, noHintBonus: 30, speedBonus: 15));
          await t.pump();
          await t.pump(const Duration(milliseconds: 2600));
          expect(t.takeException(), isNull, reason: m.id);
          expect(find.text(d.type.label), findsOneWidget, reason: m.id);
          expect(find.text(d.title), findsOneWidget, reason: m.id);
          expect(find.text('WELL DONE'), findsNothing);
          final cta = find.text('CONTINUE');
          await t.scrollUntilVisible(cta, 200, scrollable: find.byType(Scrollable).last);
          final r = t.getRect(cta);
          expect(r.bottom, lessThanOrEqualTo(size.height), reason: '${m.id}: CONTINUE on screen');
          await t.tap(cta);
          await t.pumpAndSettle();
          await closed;
        }
      });
    }
  });

  group('play', () {
    final play = MissionPlay();
    String path() => play.path();
    Future<Mission> openPuzzle(WidgetTester t, Size size, String id, {double textScale = 1}) =>
        play.openPuzzle(t, size, id, textScale: textScale);
    Future<void> solve(WidgetTester t, Mission m) => play.solve(t, m);

    /// [f] inside the moment (the solved page under it is hidden by it).
    Finder inMoment(Finder f) => find.descendant(of: find.byKey(const ValueKey('discovery-moment')), matching: f);

    double opacityOf(WidgetTester t, Finder f) =>
        t.widget<Opacity>(find.ancestor(of: f, matching: find.byType(Opacity)).first).opacity;

    /// Every line of [d] on screen (title, label, detail, note), whole.
    void expectShown(WidgetTester t, Discovery d) {
      expect(inMoment(find.text(d.type.label)), findsOneWidget);
      expect(inMoment(find.text(d.title)), findsOneWidget);
      if (d.detail.isNotEmpty) expect(inMoment(find.text(d.detail)), findsOneWidget);
      if (d.note case final n?) expect(inMoment(find.text(n)), findsOneWidget);
      expect(inMoment(find.text('NOTED IN YOUR NOTEBOOK')), d.note == null ? findsNothing : findsOneWidget);
      expect(find.text('WELL DONE'), findsNothing);
      expect(find.textContaining('New clue'), findsNothing, reason: 'said once, not twice');
    }

    // 1, 3, 4, 5 — and 15, 17: solve → the moment → (nothing moves on by
    // itself) → CONTINUE → the scene after it.
    for (final (id, shows) in const [
      ('ep03_m3', ['The boot smells of trains and smoke.', 'Wet Footprint']),
      ('ep05_m3', ["FOR THE CLOCKMAKER'S DOOR", 'Brass Key', 'ALSO A SEASON CLUE']),
      ('ep07_m3', ['THE JOINED MAP']),
      ('ep10_m3', ['TOWER BRIDGE']),
    ]) {
      testWidgets('$id: solve → its discovery → CONTINUE → the scene', (t) async {
        final m = await openPuzzle(t, const Size(390, 844), id);
        await solve(t, m);
        await wait(t, const Duration(milliseconds: 2600));
        final d = discoveryOf(m);
        expectShown(t, d);
        for (final s in shows) {
          await reveal(t, inMoment(find.text(s)));
          expect(inMoment(find.text(s)), findsOneWidget, reason: s);
        }
        final state = play.ref.read(gameControllerProvider);
        expect(state.isCompleted(id), isTrue, reason: 'saved before the moment opens');
        expect(find.text('+${XpBreakdown.of(m, state).total} XP'), findsOneWidget, reason: 'the XP stays');
        // Nothing moves on by itself.
        await wait(t, const Duration(seconds: 4));
        expect(path(), Routes.mission(id));
        expect(find.text(d.title), findsOneWidget);
        await tapText(t, 'CONTINUE', after: const Duration(milliseconds: 900));
        expect(path(), Routes.story(id));
        expect(find.text(m.transition.first), findsOneWidget, reason: 'the story scene goes on as before');
        await t.tapAt(const Offset(200, 400));
        await wait(t, const Duration(milliseconds: 900));
        await tapText(t, 'TO THE MAP', after: const Duration(milliseconds: 1400));
        expect(path(), Routes.map);
        await wait(t, const Duration(seconds: 3));
      });
    }

    testWidgets('6. a badge earned by the answer is still named (Case 01, the first clue)', (t) async {
      final m = await openPuzzle(t, const Size(390, 844), 'm01');
      await solve(t, m);
      await wait(t, const Duration(milliseconds: 2600));
      expect(find.textContaining('New badge:'), findsOneWidget);
      await capture(t, 'discovery_badge_m01_390x844');
      // The discovery leads, the badge follows it.
      expect(t.getRect(find.text('THE BRITISH MUSEUM')).top, lessThan(t.getRect(find.textContaining('New badge:')).top));
      await tapText(t, 'CONTINUE', after: const Duration(milliseconds: 900));
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('7. reduced motion: the whole moment at once, CONTINUE ready', (t) async {
      t.platformDispatcher.accessibilityFeaturesTestValue = const _NoMotion();
      addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final m = await openPuzzle(t, const Size(390, 844), 'ep02_m2');
      await solve(t, m);
      await t.pump(const Duration(milliseconds: 350));
      expect(opacityOf(t, find.text('CONTINUE')), 1);
      expect(opacityOf(t, find.text('SMALL BRASS GEAR')), 1);
      await tapText(t, 'CONTINUE', after: const Duration(milliseconds: 900));
      expect(path(), Routes.story('ep02_m2'));
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('a tap while it is being laid out shows all of it at once', (t) async {
      final m = await openPuzzle(t, const Size(390, 844), 'ep07_m3');
      await solve(t, m);
      expect(opacityOf(t, find.text('CONTINUE')), 0, reason: 'the button comes last');
      await t.tapAt(const Offset(20, 120));
      await t.pump();
      expect(opacityOf(t, find.text('CONTINUE')), 1);
      await tapText(t, 'CONTINUE', after: const Duration(milliseconds: 900));
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('Android back on the moment goes on to the scene, as CONTINUE (the answer is saved)', (t) async {
      final m = await openPuzzle(t, const Size(390, 844), 'ep04_m2');
      await solve(t, m);
      await wait(t, const Duration(milliseconds: 2600));
      await t.binding.handlePopRoute();
      await wait(t, const Duration(milliseconds: 900));
      expect(path(), Routes.story('ep04_m2'), reason: 'not the map, not out of the app');
      expect(find.text('PLATFORM 4'), findsNothing, reason: 'the moment is closed');
      await wait(t, const Duration(seconds: 3));
    });

    testWidgets('2. the final case has no Discovery Moment (Case 06)', (t) async {
      // From the last mission's moment to the final, solved there.
      final m = await openPuzzle(t, const Size(390, 844), 'ep06_m3');
      await solve(t, m);
      await wait(t, const Duration(milliseconds: 2600));
      await tapText(t, 'CONTINUE', after: const Duration(milliseconds: 900));
      play.ref.read(routerProvider).go(Routes.finalMission);
      await wait(t, const Duration(milliseconds: 1500));
      await tapText(t, 'Inspector Grey', after: const Duration(milliseconds: 200));
      await tapText(t, 'CHECK ANSWER', after: const Duration(milliseconds: 2600));
      expect(play.ref.read(gameControllerProvider).isCaseSolved, isTrue);
      for (final l in labels) {
        expect(find.text(l), findsNothing, reason: l);
      }
      expect(find.text('NOTED IN YOUR NOTEBOOK'), findsNothing);
      expect(path(), Routes.finalMission, reason: "the final's own solve, as before");
      await wait(t, const Duration(seconds: 3));
    });

    // The representative moments, at both sizes (screenshots with
    // LM_SCREENSHOTS): each kind, the timing exceptions, the longest.
    for (final size in const [Size(360, 640), Size(390, 844)]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}';
      for (final (id, kind, absent) in const [
        ('ep05_m3', 'evidence_found', <String>[]),
        ('ep02_m3', 'deduction', <String>[]),
        ('ep10_m3', 'new_lead', ["Ravenmaster's Letter", 'Given to you at the north tower']),
        ('ep03_m3', 'clue_found', <String>[]),
        ('ep08_m1', 'before_puzzle_confirmed', ['EVIDENCE FOUND', 'Name Tag']),
        ('ep06_m3', 'timing_exception', ['Theatre Ticket', 'ROW R · SEAT 17', 'EVIDENCE FOUND']),
        ('ep02_m2', 'season_clue', <String>[]),
        ('ep12_m3', 'no_seven_ravens', ['Seven Ravens', 'SEASON CLUE']),
        ('ep10_m1', 'r_m_ring', <String>[]),
        ('ep11_m1', 'train_whistle', <String>[]),
      ]) {
        testWidgets('$id $tag: $kind', (t) async {
          final m = await openPuzzle(t, size, id);
          await solve(t, m);
          await wait(t, const Duration(milliseconds: 2600));
          await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500))); // decode the pictures
          await t.pump();
          expect(t.takeException(), isNull);
          final d = discoveryOf(m);
          expectShown(t, d);
          for (final a in absent) {
            expect(inMoment(find.textContaining(a)), findsNothing, reason: a);
          }
          if (d.showEvidence) {
            final ev = m.evidence!;
            await reveal(t, inMoment(find.text(ev.inscription!)));
            expect(inMoment(find.text(ev.name)), findsOneWidget);
            expect(inMoment(find.text(ev.inscription!)), findsOneWidget, reason: 'what is written on it');
          } else if (m.evidence case final ev?) {
            expect(inMoment(find.text(ev.name)), findsNothing, reason: '${ev.name}: not shown as new');
          }
          await capture(t, 'discovery_${kind}_${id}_$tag');
          final cta = find.text('CONTINUE');
          await reveal(t, cta);
          expect(t.getRect(cta).bottom, lessThanOrEqualTo(size.height));
          await capture(t, 'discovery_${kind}_${id}_${tag}_cta');
          await t.tap(cta);
          await wait(t, const Duration(milliseconds: 900));
          expect(path(), Routes.story(id));
          await wait(t, const Duration(seconds: 3));
        });
      }

      // 10. The longest moment (evidence, its writing, a long line) at the
      // largest text size: it scrolls, and CONTINUE is reached.
      testWidgets('10. the longest, text 1.3× $tag: scrolls to CONTINUE', (t) async {
        final m = await openPuzzle(t, size, 'ep05_m3', textScale: 1.3);
        await solve(t, m);
        await wait(t, const Duration(milliseconds: 2600));
        expect(t.takeException(), isNull);
        await capture(t, 'discovery_long_ep05_m3_${tag}_text130');
        final cta = find.text('CONTINUE');
        await reveal(t, cta);
        expect(t.getRect(cta).bottom, lessThanOrEqualTo(size.height));
        await capture(t, 'discovery_long_ep05_m3_${tag}_text130_cta');
        await t.tap(cta);
        await wait(t, const Duration(milliseconds: 900));
        expect(path(), Routes.story('ep05_m3'));
        await wait(t, const Duration(seconds: 3));
      });
    }
  });
}

class _NoMotion implements AccessibilityFeatures {
  const _NoMotion();

  @override
  bool get disableAnimations => true;

  @override
  dynamic noSuchMethod(Invocation invocation) => false;
}
