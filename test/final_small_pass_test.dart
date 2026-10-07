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
import 'package:london_mystery/data/models/mission.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';

import 'full_playthrough_test.dart' show reveal, wait;
import 'helpers.dart';
import 'title_screen_test.dart' show capture;

/// Reasoning: the final small pass (Cases 06 and 08). Each final is solved
/// with what the detective found, not by matching a word on the page:
/// Case 06 matches the man by the fountain to the one who dropped the card;
/// Case 08 answers Mrs Robin's lie with the Red Button from Case 03.
void main() {
  final season = MockEpisodeRepository.bundled();
  Episode byId(String id) => season.firstWhere((e) => e.id == id);

  /// What the final page shows before it is solved (not its options).
  String page(Mission f) => [...f.story, f.letterIntro, f.letter, f.question, ?f.prompt, ...f.hints].join('\n');

  /// Everything read in [e] before the final is answered: every mission
  /// (what it saved, its scene after) and the final page with its options.
  String beforeFinal(Episode e) => [
        ...e.synopsis,
        ...e.intro,
        for (final m in e.missions) ...[
          ...m.story, m.letterIntro, m.letter, m.question, for (final o in m.options) o.label, ...m.hints,
          m.successMessage,
          if (m.clue case final c?) ...[c.title, c.value, c.note],
          if (m.evidence case final v?) ...[v.name, v.description, ?v.inscription],
          ...m.transition,
        ],
        page(e.finalMission),
        for (final o in e.finalMission.options) o.label,
      ].join('\n');

  group('Case 06: the man by the fountain is matched, not named', () {
    final e = byId('ep06');
    final fin = e.finalMission;
    final m1 = e.missionById('ep06_m1')!, m2 = e.missionById('ep06_m2')!, m3 = e.missionById('ep06_m3')!;

    test('1. the answer is still Inspector Grey', () {
      expect(fin.type, MissionType.multipleChoice);
      expect(fin.answerLabel, 'Inspector Grey');
    });

    test('2. the final page never says grey, his name or his hat', () {
      final p = page(fin);
      for (final w in ['grey', 'gray', 'inspector', 'hat', 'card', 'detective agency']) {
        expect(RegExp('\\b$w\\b', caseSensitive: false).hasMatch(p), isFalse, reason: w);
      }
      expect(m3.transition.join(' ').toLowerCase(), isNot(contains('grey')), reason: 'the scene just before the final');
    });

    test("3. the page gives what he is like; earlier missions tie that to the card", () {
      // On the page: tall, a small bag, something lost by the water.
      expect(fin.letter, allOf(contains('tall man'), contains('small bag'), contains('lost something')));
      // Mission 01: the stranger carried a small bag and dropped a card by the fountain.
      expect(m1.answer, 'b');
      expect(m1.answerLabel, 'A small bag');
      expect(m1.transition.join(' '), allOf(contains('small bag'), contains('fountain'), contains('card')));
      // Mission 03: the tall man had the small bag; the short woman (the Raven Society) a big bag.
      expect(m3.letter, allOf(contains('A tall man'), contains('A small bag'), contains('A short woman'), contains('A big bag')));
      expect(m3.transition.join(' '), contains('The woman in the red hat is with the Raven Society!'));
      // Mission 02: the card names him.
      expect(m2.evidence!.inscription, 'INSPECTOR GREY — LONDON DETECTIVE AGENCY');
      expect(m2.evidence!.description, contains('fountain'));
    });

    test('4. no direct leak: no line before the answer says who he is', () {
      final text = beforeFinal(e);
      expect(text, isNot(contains('on your side')));
      expect(text, isNot(contains('the man in the grey hat is')));
      for (final h in fin.hints) {
        expect(h.toLowerCase(), isNot(contains('grey')), reason: h);
        expect(h, isNot(contains('Inspector')), reason: h);
      }
      expect(fin.hints.last, contains('notebook'));
    });

    test('5. the notebook holds what the final needs', () {
      expect(m1.clue!.note, contains('small bag'));
      expect(m1.evidence!.inscription, contains('small bag'));
      expect(m2.evidence!.name, 'Detective Card');
      expect(m3.clue!.note, contains('red hat'));
    });

    test('6–9. the story stays: on your side, the whistle, Hyde Park, Row R seat 17', () {
      expect(fin.transition.first, 'Inspector Grey is on your side.');
      expect(fin.evidence!.name, 'Silver Whistle');
      expect(fin.transition, contains('"Find the other half\nin Hyde Park."'));
      expect(e.hook, contains('Hyde Park'));
      expect(m3.evidence!.inscription, 'ROW R · SEAT 17');
      expect(m3.transition, contains('Row R, seat 17. R for Raven. 17, like 8:17.'));
      expect(m3.transition.first, contains('ticket'), reason: 'the scene shows where the ticket comes from');
      expect(byId('ep10').finalMission.transition, contains('ROW R\nSEAT 17.'));
      expect(byId('ep11').synopsis.first, contains('Row R, Seat 17'));
    });
  });

  group('Case 08: the Red Button from Case 03 answers her lie', () {
    final e = byId('ep08');
    final fin = e.finalMission;
    final m2 = e.missionById('ep08_m2')!;
    final c03 = byId('ep03');
    final redButton = c03.missionById('ep03_m1')!.evidence!;
    final footprint = c03.missionById('ep03_m3')!.evidence!;

    test('10. the answer is the Red Button; only Case 03 tells which card came from Gallery 8', () {
      expect(fin.answerLabel, 'Red Button');
      expect(fin.answerLabel, redButton.name);
      expect(fin.question, contains('Gallery 8'));
      // The Red Button: from a coat, found in Gallery 8. The Wet Footprint: a
      // boot, found in the Great Court. The two cards of this case say nothing
      // about Gallery 8.
      expect(redButton.description, contains('coat'));
      expect(c03.missionById('ep03_m1')!.location, 'GALLERY 8');
      expect(c03.missionById('ep03_m3')!.location, isNot('GALLERY 8'));
      expect(footprint.description, isNot(contains('coat')));
      final labels = fin.options.map((o) => o.label).toList();
      expect(labels, containsAll(['Red Button', 'Wet Footprint']));
      for (final x in [e.missionById('ep08_m1')!.evidence!, m2.evidence!]) {
        expect(labels, contains(x.name));
        expect('${x.description} ${x.inscription}', isNot(contains('Gallery')));
      }
      // Her coat: seen in Mission 02 and kept in its clue (not on the final page).
      expect(m2.letter, contains('long red coat'));
      expect(m2.clue!.note, contains('long red coat'));
    });

    test('11. the final page names neither the button nor her coat', () {
      final p = page(fin).toLowerCase();
      for (final w in ['button', 'coat', 'red', 'miss rose']) {
        expect(p, isNot(contains(w)), reason: w);
      }
      expect(fin.options.map((o) => o.label), isNot(contains('Blue Cloth')), reason: 'her blue scarf: a second answer');
      expect(fin.options.map((o) => o.label), isNot(contains('The Raven Tower')), reason: 'from Gallery 8, but not hers, she says');
    });

    test('12. the tips lead to Case 03 in the archive, never to the card', () {
      for (final h in fin.hints) {
        expect(h.toLowerCase(), isNot(contains('button')), reason: h);
      }
      expect(fin.hints.last, allOf(contains('Case Archive'), contains('Case 03')));
    });

    test('13. before the final, no line says Miss Rose is Mrs Robin', () {
      final text = beforeFinal(e).toLowerCase();
      expect(text, isNot(contains('miss rose')));
      expect(text, isNot(contains('same person')));
    });

    test('14. the post-case scene confirms what the detective proved', () {
      final scene = fin.transition.join(' ');
      expect(fin.transition.first, 'Mrs Robin cannot say no.');
      expect(scene, contains('You were right.'));
      expect(scene, contains('Miss Rose was Mrs Robin all along.'));
      expect(scene, isNot(contains('are the same person')));
      expect(fin.successMessage, 'Mrs Robin cannot say no!');
    });

    test('15–16. The Raven Tower and the way into Case 09 stay', () {
      final painting = e.missionById('ep08_m3')!.evidence!;
      expect(painting.name, 'The Raven Tower');
      expect(painting.inscription, 'On the back: a small drawing of a jewel.');
      expect(fin.evidence!.name, 'Empty Jewel Box');
      expect(fin.evidence!.inscription, contains('BUCKINGHAM PALACE'));
      expect(fin.transition, containsAll(['BUCKINGHAM PALACE.', '"The Clockmaker gives the orders."']));
      expect(byId('ep09').intro.join(' '), contains("Mrs Robin's suitcase"));
    });
  });

  test('17. no other case changed in this pass', () {
    // FNV-1a of each case's JSON, as it was before this pass. Changing
    // another case on purpose means updating its value here.
    int fnv(String s) {
      var h = 0x811c9dc5;
      for (final c in utf8.encode(s)) {
        h = ((h ^ c) * 0x01000193) & 0xffffffff;
      }
      return h;
    }

    final now = {for (final e in season) e.id: fnv(jsonEncode(e.toJson()))};
    expect({for (final id in now.keys) if (id != 'ep06' && id != 'ep08') id: now[id]}, _otherCases);
  });

  group('screens', () {
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

    String progress(List<String> done, {bool solved = false}) => jsonEncode(GameProgress(
          detectiveName: 'MINYOUNG',
          introSeen: true,
          completedMissionIds: done,
          startedAt: DateTime(2026, 10, 7, 10),
          completedAt: solved ? DateTime(2026, 10, 7, 10, 40) : null,
          playMillis: 0,
        ).toJson());

    Future<void> openFinal(WidgetTester t, Size size, String caseId) async {
      t.view.physicalSize = size * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      final e = byId(caseId);
      final earlier = [for (final x in season) if (x.number < e.number) x];
      await t.pumpWidget(ProviderScope(
        overrides: await testOverrides(prefs: {
          for (final x in earlier)
            AppConstants.progressKeyFor(x.id): progress([for (final m in x.allMissions) m.id], solved: true),
          AppConstants.progressKeyFor(e.id): progress([for (final m in e.missions) m.id]),
          AppConstants.seasonStorageKey: jsonEncode(
            SeasonProgress(activeEpisodeId: e.id, solvedEpisodeIds: [for (final x in earlier) x.id]).toJson(),
          ),
        }),
        child: const RepaintBoundary(key: ValueKey('shot'), child: LondonMysteryApp()),
      ));
      await wait(t, const Duration(milliseconds: 300));
      ProviderScope.containerOf(find.byType(LondonMysteryApp).evaluate().first).read(routerProvider).go(Routes.finalMission);
      await wait(t, const Duration(milliseconds: 1200));
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
      await t.pump();
      expect(t.takeException(), isNull);
    }

    Finder scroller() =>
        find.byWidgetPredicate((w) => w is Scrollable && w.physics is! NeverScrollableScrollPhysics).last;

    /// The letter, the question, every card (whole, inside the screen, tall
    /// enough to tap) and both tips.
    Future<void> checkPage(WidgetTester t, Size size, Mission fin, String tag) async {
      await reveal(t, find.text(fin.question));
      await capture(t, '${fin.id}_small_pass_question_$tag');
      for (final o in fin.options) {
        final card = find.text(o.label);
        await reveal(t, card);
        final r = t.getRect(card);
        expect(r.left, greaterThanOrEqualTo(0), reason: o.label);
        expect(r.right, lessThanOrEqualTo(size.width), reason: o.label);
        final button = find.ancestor(of: card, matching: find.byWidgetPredicate((w) => w is Semantics || w is InkWell)).first;
        expect(t.getSize(button).height, greaterThanOrEqualTo(44), reason: '${o.label}: a comfortable target');
      }
      await capture(t, '${fin.id}_small_pass_cards_$tag');
      for (var i = 0; i < fin.hints.length; i++) {
        await reveal(t, find.text('GET A TIP'));
        await t.tap(find.text('GET A TIP'));
        await wait(t, const Duration(milliseconds: 600));
      }
      for (final h in fin.hints) {
        await reveal(t, find.text(h));
      }
      await capture(t, '${fin.id}_small_pass_tips_$tag');
      expect(t.takeException(), isNull);
    }

    /// OPEN MY NOTEBOOK (→ the archive → [archiveCase]) → [evidence] → look
    /// closer: every one of [texts] shows.
    Future<void> lookCloser(WidgetTester t, String evidence, List<String> texts, String shot, {String? archiveCase}) async {
      final notebook = find.text('OPEN MY NOTEBOOK');
      await reveal(t, notebook);
      await t.tap(notebook);
      await wait(t, const Duration(milliseconds: 900));
      if (archiveCase != null) {
        final archive = find.text('OPEN THE CASE ARCHIVE');
        await t.scrollUntilVisible(archive, 300, scrollable: scroller());
        // Built is not on screen: the list builds a little past its edge.
        await t.ensureVisible(archive);
        await wait(t, const Duration(milliseconds: 300));
        await t.tap(archive);
        await wait(t, const Duration(milliseconds: 900));
        final folder = find.text(archiveCase);
        await t.scrollUntilVisible(folder, 300, scrollable: scroller());
        await t.ensureVisible(folder);
        await wait(t, const Duration(milliseconds: 300));
        await t.tap(folder);
        await wait(t, const Duration(milliseconds: 600));
        await capture(t, '${shot}_archive');
      }
      final tile = find.text(evidence);
      await t.scrollUntilVisible(tile, 200, scrollable: scroller());
      await wait(t, const Duration(milliseconds: 300));
      await t.tap(tile);
      await wait(t, const Duration(milliseconds: 700));
      for (final text in texts) {
        expect(find.text(text), findsWidgets, reason: '$evidence: $text');
      }
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
      await t.pump();
      await capture(t, shot);
      expect(t.takeException(), isNull);
    }

    for (final size in const [Size(360, 640), Size(390, 844)]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}';

      testWidgets('Case 06 final $tag: what he is like on the page; the card in the notebook', (t) async {
        await openFinal(t, size, 'ep06');
        await capture(t, 'ep06_small_pass_page_$tag');
        expect(find.textContaining('Grey'), findsOneWidget, reason: 'the name is only on its answer card');
        await checkPage(t, size, byId('ep06').finalMission, tag);
        await lookCloser(t, 'Detective Card', ['INSPECTOR GREY — LONDON DETECTIVE AGENCY', 'Dropped by the fountain.'],
            'ep06_small_pass_card_$tag');
        await wait(t, const Duration(seconds: 2));
      });

      testWidgets('Case 06 final $tag: the witness notes in the notebook', (t) async {
        await openFinal(t, size, 'ep06');
        await lookCloser(t, 'Witness Notes', ['Dark coat · grey hat · small bag'], 'ep06_small_pass_witness_$tag');
        await wait(t, const Duration(seconds: 2));
      });

      testWidgets('Case 08 final $tag: her lie on the page; the Red Button from Gallery 8 in the archive', (t) async {
        await openFinal(t, size, 'ep08');
        await capture(t, 'ep08_small_pass_page_$tag');
        expect(find.textContaining('button'), findsNothing);
        expect(find.textContaining('Button'), findsOneWidget, reason: 'only the answer card');
        await checkPage(t, size, byId('ep08').finalMission, tag);
        await lookCloser(t, 'Red Button', ['From a coat. It was under the bench.', 'GALLERY 8'], 'ep08_small_pass_button_$tag',
            archiveCase: 'THE VANISHING PAINTING');
        await wait(t, const Duration(seconds: 2));
      });

      testWidgets('Case 08 final $tag: the Wet Footprint is from the Great Court', (t) async {
        await openFinal(t, size, 'ep08');
        await lookCloser(t, 'Wet Footprint', ['THE GREAT COURT'], 'ep08_small_pass_footprint_$tag',
            archiveCase: 'THE VANISHING PAINTING');
        await wait(t, const Duration(seconds: 2));
      });
    }
  });
}

/// See test 17.
const _otherCases = <String, int>{
  'ep01': 2405520550,
  'ep02': 3212340141,
  'ep03': 257964675,
  'ep04': 963358578,
  'ep05': 96539243,
  // Post-discovery small pass: one transition line each (07 M3, 10 M2).
  'ep07': 2868419332,
  'ep09': 4238785963,
  'ep10': 1767566211,
  'ep11': 1724552176,
  'ep12': 2472749342,
};
