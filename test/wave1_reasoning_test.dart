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

/// Reasoning wave 1 (Cases 01, 04, 06, 08, 11): the game gives the clues,
/// the detective names the answer. Before a final is solved, no scene,
/// letter, tip or answer card says the answer or why it is right; the
/// answer comes from evidence the detective already holds (this case's
/// notebook, or an earlier case in the Case Archive).
void main() {
  final season = MockEpisodeRepository.bundled();
  Episode byId(String id) => season.firstWhere((e) => e.id == id);

  /// Every line a player can read in [m] before solving it.
  List<String> puzzleText(Mission m) => [
        m.title,
        m.location,
        ...m.story,
        m.letterIntro,
        m.letter,
        m.question,
        ?m.prompt,
        for (final o in m.options) o.label,
        ...m.hints,
      ];

  /// What solving [m] shows and saves (the success line, its clue and
  /// evidence, the scene after it).
  List<String> afterText(Mission m) => [
        m.successMessage,
        if (m.clue case final c?) ...[c.title, c.value, c.note],
        if (m.evidence case final e?) ...[e.name, e.description, ?e.inscription],
        ...m.transition,
      ];

  /// Everything a player reads in [e] before the final's answer is checked:
  /// the case file, every mission (and what it saved), and the final page,
  /// its question and its tips. Not the final's own solve, evidence or
  /// post-case scene. [except] leaves out lines on purpose (the evidence the
  /// answer must be read from).
  String beforeFinal(Episode e, {Set<String> except = const {}, bool finalOptions = false}) => [
        ...e.synopsis,
        ...e.intro,
        ...e.objectives,
        for (final m in e.missions) ...[...puzzleText(m), ...afterText(m)],
        ...e.finalMission.story,
        e.finalMission.letterIntro,
        e.finalMission.letter,
        e.finalMission.question,
        ?e.finalMission.prompt,
        ...e.finalMission.hints,
        if (finalOptions) for (final o in e.finalMission.options) o.label,
      ].where((l) => !except.contains(l)).join('\n');

  bool word(String text, String w) => RegExp('\\b$w\\b', caseSensitive: false).hasMatch(text);

  group('Case 01: the four locks stay; tips and the box agree', () {
    final e = byId('ep01');
    final m03 = e.missionById('m03')!;

    test('the final is still 7924 from the four places', () {
      expect(e.finalMission.answer, '7924');
      expect(e.finalMission.dialSymbols, ['clock', 'train', 'park', 'museum']);
    });

    test('no tip gives a number of the code', () {
      for (final h in e.finalMission.hints) {
        expect(RegExp(r'\d').hasMatch(h), isFalse, reason: h);
      }
      expect(e.finalMission.hints.last, contains('notebook'), reason: 'tip 2 says where to look');
      expect(e.finalMission.hints.last, contains("King's Cross"));
    });

    test('the box at Big Ben holds the watch and the photo (scene and evidence agree)', () {
      expect(m03.evidence!.name, 'Pocket Watch');
      expect(m03.evidence!.inscription, "It stopped at 7 o'clock.");
      final scene = m03.transition.join(' ').toLowerCase();
      expect(scene, allOf(contains('pocket watch'), contains('photo')));
      expect(m03.evidence!.description, isNot(contains('dropped')), reason: 'it was in the box');
      expect(m03.transition.last, "Let's go to Hyde Park!");
    });

    test('its words stay: SEVEN o\'clock, P.S. I love trains!, no raven', () {
      expect(m03.letter, contains("I left London at SEVEN o'clock."));
      expect(e.missionById('m01')!.evidence!.inscription, 'Signed: The Shadow\nP.S. I love trains!');
      expect(jsonEncode(e.toJson()).toLowerCase(), isNot(contains('raven')));
    });
  });

  group('Case 04: the seal names the society, the game does not', () {
    final e = byId('ep04');
    final seal = e.missionById('ep04_m1')!.evidence!;

    test('the answer is still RAVEN, read from the Black Wax Seal', () {
      expect(e.finalMission.answer, 'RAVEN');
      expect(seal.name, 'Black Wax Seal');
      expect(seal.inscription, 'A raven is pressed into the wax.');
      expect(e.finalMission.letter, contains('every seal'), reason: 'the letter points to the seal');
      expect(e.finalMission.letter, contains('Tower'), reason: 'and to the birds of the Tower (Mission 03)');
      expect(e.missionById('ep04_m3')!.letter, contains('Black birds live there.'));
    });

    test('nothing before the final names the bird, except the seal itself', () {
      final text = beforeFinal(e, except: {seal.inscription!});
      expect(word(text, 'ravens?'), isFalse);
      expect(e.missionById('ep04_m3')!.transition.join(' '), contains('same black seal'));
      expect(e.finalMission.letter, isNot(contains('big black bird')));
    });

    test('the tips point to the seal, not to the word', () {
      for (final h in e.finalMission.hints) {
        expect(h, isNot(contains('letter of the bird')), reason: h);
        expect(RegExp(r'\bR\b').hasMatch(h), isFalse, reason: h);
      }
      expect(e.finalMission.hints.last, contains('seal'));
    });

    test('Platform 4 stays, for Case 12', () {
      final m2 = e.missionById('ep04_m2')!;
      expect(m2.answerLabel, 'Under the red clock on Platform 4');
      expect(m2.clue!.value, '4');
      expect(byId('ep12').missionById('ep12_m2')!.letter, contains('small red clock'));
      expect(byId('ep12').missionById('ep12_m2')!.hints.first, contains('Case 04'));
    });
  });

  group('Case 06: his card names him, the game does not', () {
    final e = byId('ep06');
    final card = e.missionById('ep06_m2')!.evidence!;
    final fin = e.finalMission;

    test('the Detective Card still says who he is; the note points to it', () {
      expect(card.name, 'Detective Card');
      expect(card.inscription, 'INSPECTOR GREY — LONDON DETECTIVE AGENCY');
      expect(fin.letter, contains('I lost my card'));
      expect(fin.letter, contains('I think you found it'));
    });

    test('before the answer, no line says what the man in the grey hat is', () {
      final scene = e.missionById('ep06_m3')!.transition.join(' ');
      expect(scene, isNot(contains('watching')));
      final page = [...fin.story, fin.letterIntro, fin.letter, fin.question, ...fin.hints].join(' ');
      expect(page, isNot(contains('Inspector')));
      expect(page, isNot(contains('on your side')));
      expect(beforeFinal(e), isNot(contains('on your side')));
      expect(fin.question, isNot(contains('Detective')), reason: 'the question does not name what he is');
    });

    test('the answer cards are people only, no reasons', () {
      expect(fin.answerLabel, 'Inspector Grey');
      for (final o in fin.options) {
        expect(o.label, isNot(contains(',')), reason: o.label);
        expect(o.label, isNot(contains('who')), reason: o.label);
        expect(o.label.split(' ').length, lessThanOrEqualTo(4), reason: o.label);
      }
    });

    test('the theatre ticket and the post-case payoff stay', () {
      expect(e.missionById('ep06_m3')!.evidence!.inscription, 'ROW R · SEAT 17');
      expect(e.missionById('ep06_m3')!.transition.first, 'Row R, seat 17. R for Raven. 17, like 8:17.');
      expect(fin.transition.first, 'Inspector Grey is on your side.');
      expect(byId('ep10').finalMission.transition, contains('ROW R\nSEAT 17.'));
      expect(byId('ep11').synopsis.first, contains('Row R, Seat 17'));
    });
  });

  group('Case 08: the detective picks the evidence', () {
    final e = byId('ep08');
    final fin = e.finalMission;
    final redButton = byId('ep03').missionById('ep03_m1')!.evidence!;

    test('the tag still finds the owner (Mission 01 → Mission 02)', () {
      final m1 = e.missionById('ep08_m1')!, m2 = e.missionById('ep08_m2')!;
      expect(m1.letter, allOf(contains('Edinburgh'), contains('alone')));
      expect(m2.answer, 'ROBIN');
      expect(m2.letter, isNot(contains('alone, like the tag')), reason: 'm2 does not repeat the tag');
    });

    test('every card is real evidence; the right one is the Red Button from Case 03', () {
      final names = {for (final x in season) ...x.allEvidence.map((v) => v.name)};
      for (final o in fin.options) {
        expect(names, contains(o.label), reason: '"${o.label}" is evidence the detective holds');
      }
      expect(fin.answerLabel, redButton.name);
      expect(redButton.description, contains('coat'));
      expect(fin.options.map((o) => o.label), isNot(contains('Blue Cloth')), reason: 'her blue scarf: a second answer');
    });

    test('the page shows the empty button place; no card or line explains the answer', () {
      expect(fin.letter, contains('One button is missing'));
      for (final o in fin.options) {
        expect(o.label, isNot(contains('Gallery')), reason: o.label);
      }
      final page = [...fin.story, fin.letterIntro, fin.letter, fin.question, ...fin.hints].join(' ');
      expect(page, isNot(contains('Gallery 8')));
      for (final h in fin.hints) {
        expect(h, isNot(contains('Red Button')), reason: h);
      }
      expect(fin.hints.last, contains('Case Archive'));
    });

    test('Mrs Robin carries on into Case 09', () {
      expect(fin.successMessage, 'Mrs Robin cannot say no!');
      expect(fin.transition, containsAll(['Mrs Robin cannot say no.', 'BUCKINGHAM PALACE.', '"The Clockmaker gives the orders."']));
      expect(fin.transition.join(' '), contains('are the same person'));
      expect(fin.evidence!.inscription, contains('BUCKINGHAM PALACE'));
      expect(redButton.name, 'Red Button');
    });
  });

  group('Case 11: the old letter names him, the game does not', () {
    final e = byId('ep11');
    final fin = e.finalMission;
    final oldLetter = byId('ep01').missionById('m01')!.evidence!;

    test('the card points back to Case 01; the Old Letter is signed', () {
      expect(fin.letter, isNot(contains('Crown')));
      expect(fin.letter, contains('We met at the very start.'));
      expect(fin.letter, contains('I still love trains.'));
      expect(oldLetter.name, 'Old Letter');
      expect(oldLetter.inscription, 'Signed: The Shadow\nP.S. I love trains!');
    });

    test('nothing before the answer names him; the card says only his name', () {
      expect(word(beforeFinal(e), 'shadow'), isFalse);
      expect(fin.answerLabel, 'The Shadow');
      for (final o in fin.options) {
        expect(o.label, isNot(contains('Case 01')), reason: o.label);
        expect(o.label, isNot(contains('thief')), reason: o.label);
      }
      for (final h in fin.hints) {
        expect(word(h, 'shadow'), isFalse, reason: h);
      }
      expect(fin.hints.last, contains('Case 01'));
    });

    test('the case stays: MIDNIGHT, trains, and no door under Big Ben yet', () {
      expect(e.missionById('ep11_m2')!.answer, 'MIDNIGHT');
      expect(e.missionById('ep11_m3')!.letter, contains('I love trains'));
      final all = [beforeFinal(e, finalOptions: true), ...fin.transition].join(' ').toLowerCase();
      expect(all, isNot(contains('under big ben')));
      // Only the theatre's stage door: the Clockmaker's door is Case 12's riddle.
      final page = [...fin.story, fin.letterIntro, fin.letter, ...fin.hints, ...fin.transition].join(' ');
      expect(word(page, 'door'), isFalse);
      expect(RegExp(r'\bdoor\b').allMatches(all).length, RegExp(r'\bstage door\b').allMatches(all).length);
    });
  });

  test('Case 02 → 12 still: the raven-stamped gear', () {
    expect(byId('ep02').missionById('ep02_m2')!.evidence!.inscription, contains('raven'));
    expect(byId('ep12').missionById('ep12_m1')!.letter, allOf(contains('raven stamp'), contains('Case 02')));
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
          startedAt: DateTime(2026, 10, 6, 10),
          completedAt: solved ? DateTime(2026, 10, 6, 10, 40) : null,
          playMillis: 0,
        ).toJson());

    /// [caseId]'s final, every earlier case solved (their files in the archive).
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

    /// The final's question, its cards (each whole, inside the screen) and
    /// both tips.
    Future<void> checkPuzzle(WidgetTester t, Size size, String caseId, String tag) async {
      final fin = byId(caseId).finalMission;
      await reveal(t, find.text(fin.question));
      await capture(t, '${caseId}_final_question_$tag');
      for (final o in fin.options) {
        final card = find.text(o.label);
        await reveal(t, card);
        final r = t.getRect(card);
        expect(r.left, greaterThanOrEqualTo(0), reason: o.label);
        expect(r.right, lessThanOrEqualTo(size.width), reason: o.label);
      }
      await capture(t, '${caseId}_final_cards_$tag');
      for (var i = 0; i < fin.hints.length; i++) {
        await reveal(t, find.text('GET A TIP'));
        await t.tap(find.text('GET A TIP'));
        await wait(t, const Duration(milliseconds: 600));
      }
      await reveal(t, find.text(fin.hints.last));
      await capture(t, '${caseId}_final_tips_$tag');
      expect(t.takeException(), isNull);
    }

    /// The list that scrolls on top (a sheet or page), not a fixed grid in it.
    Finder scroller() =>
        find.byWidgetPredicate((w) => w is Scrollable && w.physics is! NeverScrollableScrollPhysics).last;

    /// OPEN MY NOTEBOOK → the evidence named [evidence] → look closer: [text] shows.
    Future<void> lookCloser(WidgetTester t, String evidence, String text, String shot, {String? archiveCase}) async {
      final notebook = find.text('OPEN MY NOTEBOOK');
      await reveal(t, notebook);
      await t.tap(notebook);
      await wait(t, const Duration(milliseconds: 900));
      if (archiveCase != null) {
        final archive = find.text('OPEN THE CASE ARCHIVE');
        await t.scrollUntilVisible(archive, 300, scrollable: scroller());
        await t.tap(archive);
        await wait(t, const Duration(milliseconds: 900));
        final folder = find.text(archiveCase);
        await t.scrollUntilVisible(folder, 300, scrollable: scroller());
        await t.tap(folder);
        await wait(t, const Duration(milliseconds: 600));
      }
      final tile = find.text(evidence);
      await t.scrollUntilVisible(tile, 200, scrollable: scroller());
      await wait(t, const Duration(milliseconds: 300));
      await t.tap(tile);
      await wait(t, const Duration(milliseconds: 700));
      expect(find.text(text), findsOneWidget, reason: '$evidence: $text');
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 400)));
      await t.pump();
      await capture(t, shot);
      expect(t.takeException(), isNull);
    }

    for (final size in const [Size(360, 640), Size(390, 844)]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}';

      testWidgets('Case 01 final $tag: the tips name places, not numbers', (t) async {
        await openFinal(t, size, 'ep01');
        await capture(t, 'ep01_final_page_$tag');
        for (var i = 0; i < 2; i++) {
          await reveal(t, find.text('GET A TIP'));
          await t.tap(find.text('GET A TIP'));
          await wait(t, const Duration(milliseconds: 600));
        }
        await reveal(t, find.text(byId('ep01').finalMission.hints.last));
        await capture(t, 'ep01_final_tips_$tag');
        expect(t.takeException(), isNull);
        await wait(t, const Duration(seconds: 2));
      });

      testWidgets('Case 04 final $tag: the seal in the notebook names the bird', (t) async {
        await openFinal(t, size, 'ep04');
        await capture(t, 'ep04_final_page_$tag');
        expect(find.textContaining('RAVEN'), findsNothing);
        await checkPuzzle(t, size, 'ep04', tag);
        await lookCloser(t, 'Black Wax Seal', 'A raven is pressed into the wax.', 'ep04_final_seal_$tag');
        await wait(t, const Duration(seconds: 2));
      });

      testWidgets('Case 06 final $tag: the card in the notebook names him', (t) async {
        await openFinal(t, size, 'ep06');
        await capture(t, 'ep06_final_page_$tag');
        await checkPuzzle(t, size, 'ep06', tag);
        await lookCloser(t, 'Detective Card', 'INSPECTOR GREY — LONDON DETECTIVE AGENCY', 'ep06_final_card_$tag');
        await wait(t, const Duration(seconds: 2));
      });

      testWidgets('Case 08 final $tag: the Red Button, from Case 03 in the archive', (t) async {
        await openFinal(t, size, 'ep08');
        await capture(t, 'ep08_final_page_$tag');
        await checkPuzzle(t, size, 'ep08', tag);
        await lookCloser(t, 'Red Button', 'From a coat. It was under the bench.', 'ep08_final_button_$tag',
            archiveCase: 'THE VANISHING PAINTING');
        await wait(t, const Duration(seconds: 2));
      });

      testWidgets('Case 11 final $tag: the Old Letter, from Case 01 in the archive', (t) async {
        await openFinal(t, size, 'ep11');
        await capture(t, 'ep11_final_page_$tag');
        await checkPuzzle(t, size, 'ep11', tag);
        await lookCloser(t, 'Old Letter', 'Signed: The Shadow\nP.S. I love trains!', 'ep11_final_letter_$tag',
            archiveCase: 'THE MISSING CROWN');
        await wait(t, const Duration(seconds: 2));
      });
    }
  });
}
