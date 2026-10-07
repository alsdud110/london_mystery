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
import 'package:london_mystery/widgets/art_assets.dart';
import 'package:london_mystery/widgets/glossary_text.dart';

import 'full_playthrough_test.dart' show reveal, wait;
import 'helpers.dart';
import 'title_screen_test.dart' show capture;

/// Reasoning wave 2 (Cases 03, 07, 10): a clue the detective already found
/// becomes the one the next step needs. Case 03: the boot that "smells of
/// trains and smoke" picks the building. Case 07: the joined map's arrow
/// picks where to stop. Case 10: two of Poppy's words name the place.
void main() {
  final season = MockEpisodeRepository.bundled();
  Episode byId(String id) => season.firstWhere((e) => e.id == id);

  /// What the player reads of [m] before answering it. Option names show
  /// only for landmark pictures (a park map is a picture without a name).
  List<String> puzzleText(Mission m) => [
        m.title,
        m.location,
        ...m.story,
        m.letterIntro,
        m.letter,
        m.question,
        ?m.prompt,
        for (final o in m.options)
          if (m.type != MissionType.imageChoice || ArtAssets.landmarkScenes.containsKey(o.artwork)) o.label,
        ...m.hints,
      ];

  /// What solving [m] shows and saves.
  List<String> afterText(Mission m) => [
        m.successMessage,
        if (m.clue case final c?) ...[c.title, c.value, c.note],
        if (m.evidence case final e?) ...[e.name, e.description, ?e.inscription],
        ...m.transition,
      ];

  /// Everything read in [e] before [until] is answered (its own page, cards
  /// and tips included); [except] leaves out the evidence lines the answer
  /// must be read from.
  String before(Episode e, String until, {Set<String> except = const {}, bool withOptions = true}) {
    final lines = [...e.synopsis, ...e.intro, ...e.objectives];
    for (final m in e.allMissions) {
      if (m.id == until) {
        lines.addAll(withOptions ? puzzleText(m) : [...m.story, m.letterIntro, m.letter, m.question, ...m.hints]);
        break;
      }
      lines.addAll([...puzzleText(m), ...afterText(m)]);
    }
    return lines.where((l) => !except.contains(l)).join('\n');
  }

  bool word(String text, String w) => RegExp('\\b$w\\b', caseSensitive: false).hasMatch(text);

  group('Case 03: the boot picks the building', () {
    final e = byId('ep03');
    final m1 = e.missionById('ep03_m1')!, m2 = e.missionById('ep03_m2')!, m3 = e.missionById('ep03_m3')!;
    final fin = e.finalMission;
    final boot = m3.evidence!;

    test("Mission 02 needs Mission 01's red button: the letter no longer repeats it", () {
      expect(m1.evidence!.name, 'Red Button');
      expect(m1.evidence!.description, contains('coat'));
      expect(m1.letter, contains('The button is red.'));
      expect(m2.letter, isNot(contains('button')));
      expect(m2.letter, isNot(contains('Remember')));
      expect(m2.story.join(' '), contains('blue cloth'), reason: 'the cloth is found here');
      expect(m2.answerLabel, 'Miss Rose');
      expect(m2.letter, allOf(contains('red coat and a blue scarf'), contains('black coat and a red scarf')));
    });

    test('the boot still smells of trains and smoke; the final is still King\'s Cross', () {
      expect(boot.name, 'Wet Footprint');
      expect(boot.inscription, 'The boot smells of trains and smoke.');
      expect(fin.type, MissionType.imageChoice);
      expect(fin.answerLabel, "King's Cross");
      expect(fin.options.map((o) => o.label), ['Big Ben', 'Tower Bridge', 'Hyde Park', "King's Cross"]);
    });

    test('nothing before the final says where she went, except the boot', () {
      final text = before(e, fin.id, except: {boot.inscription!}, withOptions: false);
      expect(word(text, 'stations?'), isFalse);
      expect(word(text, 'trains?'), isFalse);
      expect(text, isNot(contains("King's Cross")));
      expect(m3.transition.join(' '), isNot(contains('station')));
    });

    test('the letter alone fits two pictures; the boot decides', () {
      expect(fin.letter, contains('north'));
      expect(fin.letter, contains('clock tower'), reason: 'Big Ben and King\'s Cross both have one');
      expect(fin.letter, isNot(contains('arches')));
      expect(fin.hints.last, allOf(contains('footprint'), contains('notebook')));
      for (final h in fin.hints) {
        expect(word(h, 'stations?|trains?'), isFalse, reason: h);
        expect(h, isNot(contains("King's Cross")), reason: h);
      }
    });

    test('Case 03 → 04 and → 08 stay', () {
      expect(fin.evidence!.name, 'Luggage Tag');
      expect(fin.evidence!.inscription, "KING'S CROSS — LOST PROPERTY");
      expect(fin.transition, contains("KING'S CROSS\nLOST PROPERTY"));
      expect(fin.transition.join(' '), contains('full of ravens'));
      expect(m2.evidence!.name, 'Blue Cloth');
      expect(byId('ep08').finalMission.answerLabel, m1.evidence!.name);
    });
  });

  group("Case 07: the joined map's arrow picks where to stop", () {
    final e = byId('ep07');
    final m3 = e.missionById('ep07_m3')!;
    final fin = e.finalMission;
    final joined = m3.evidence!;

    test('the pieces still come together into the joined map', () {
      expect(e.missionById('ep07_m1')!.evidence!.name, 'River Map Piece');
      expect(e.missionById('ep07_m2')!.evidence!.name, 'Station Map Piece');
      expect(joined.name, 'Joined Map');
      expect(joined.inscription, 'An arrow goes north, to the old gate of the park.');
      expect(m3.answer, 'station,park,river');
    });

    test('the final is still the old gate, on the same four maps', () {
      expect(fin.type, MissionType.imageChoice);
      expect(fin.options.firstWhere((o) => o.id == fin.answer).artwork, Artwork.parkMapD);
      expect({for (final o in fin.options) o.artwork}, {Artwork.parkMapA, Artwork.parkMapB, Artwork.parkMapC, Artwork.parkMapD});
    });

    test('nothing before the final names the spot, except the joined map', () {
      final text = before(e, fin.id, except: {joined.inscription!});
      expect(text.toLowerCase(), isNot(contains('old gate')));
    });

    test("Grey gives the way, not the end: his note alone leaves two maps", () {
      expect(fin.letter, contains('turn left'));
      expect(fin.letter, contains('joined map'));
      expect(fin.letter.toLowerCase(), isNot(contains('gate')));
      expect(fin.letter.toLowerCase(), isNot(contains('bench')));
      // The joined map's arrow (north) is told on the way to the final.
      expect(m3.transition.first, contains('north'));
      for (final h in fin.hints) {
        expect(h.toLowerCase(), isNot(contains('gate')), reason: h);
      }
      expect(fin.hints.last, contains('joined map'));
    });

    test('Case 05 → 07 → 08 stay', () {
      expect(byId('ep05').finalMission.evidence!.name, 'Old Map Fragment');
      expect(e.intro.join(' '), contains('You have one piece from the Tower.'));
      expect(fin.evidence!.inscription, 'Nine small ravens are drawn around Platform 9.');
      expect(fin.transition, containsAll(['PLATFORM 9.', "King's Cross is waiting."]));
      expect(byId('ep08').intro.join(' '), contains('nine ravens around Platform 9'));
    });
  });

  group("Case 10: two of Poppy's words name the place", () {
    final e = byId('ep10');
    final m1 = e.missionById('ep10_m1')!, m2 = e.missionById('ep10_m2')!, m3 = e.missionById('ep10_m3')!;
    final fin = e.finalMission;

    test('Poppy, R.M. and the four words stay', () {
      expect(m1.answerLabel, 'Poppy');
      expect(m1.evidence!.inscription, 'Letters inside: R.M.');
      expect(m2.evidence!.inscription, 'NORTH · TOWER · BRIDGE · THREE');
      expect(m2.clue!.note, 'NORTH · TOWER · BRIDGE · THREE');
      expect(m2.answer, 'north,tower,bridge,three');
    });

    test('no scene or note reads the place out before Mission 03 is answered', () {
      final text = before(e, m3.id, withOptions: false);
      expect(text.toLowerCase(), isNot(contains('tower bridge')));
      expect(m2.transition.join(' '), isNot(contains('Tower of London')));
      expect(m2.transition.join(' ').toLowerCase(), isNot(contains('bridge with')));
      for (final w in ['north', 'tower', 'bridge', 'three']) {
        expect(word(m3.letter, w), isFalse, reason: 'the note does not repeat "$w"');
      }
      for (final h in m3.hints) {
        expect(h.toLowerCase(), isNot(contains('tower bridge')), reason: h);
      }
    });

    test('Mission 03 needs the words: TOWER + BRIDGE is the only name among the pictures', () {
      expect(m3.type, MissionType.imageChoice);
      expect(m3.answerLabel, 'Tower Bridge');
      final words = m2.options.map((o) => o.label.toLowerCase()).toSet();
      for (final o in m3.options) {
        final made = o.label.toLowerCase().split(' ').every(words.contains);
        expect(made, o.id == m3.answer, reason: '${o.label}: made of the four words?');
      }
      expect(m3.hints.first, contains('notebook'));
    });

    test('NORTH and THREE still tell where and when; the final is kept', () {
      expect(m3.clue!.note, "Meet at the north tower of the bridge at three o'clock.");
      expect(m3.transition.first, "At three o'clock, the Ravenmaster is waiting at the north tower.");
      expect(m3.transition, contains('"I could not speak," he says. "The Clockmaker is watching me."'));
      expect(fin.type, MissionType.sequence);
      expect(fin.answer, 'clockmaker,stop,bigben,midnight');
      expect(fin.evidence!.inscription, 'THE CLOCKMAKER WILL STOP BIG BEN AT MIDNIGHT.');
      expect(fin.transition, containsAll(['The warning is clear.', 'ROW R\nSEAT 17.']));
      expect(fin.transition.join(' ').toLowerCase(), isNot(contains('shadow')));
    });
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

    String progress(List<String> done, {bool solved = false, String? opened}) => jsonEncode(GameProgress(
          detectiveName: 'MINYOUNG',
          introSeen: true,
          completedMissionIds: done,
          missionStartedAt: opened == null ? const {} : {opened: DateTime(2026, 10, 6, 10)},
          startedAt: DateTime(2026, 10, 6, 10),
          completedAt: solved ? DateTime(2026, 10, 6, 10, 40) : null,
          playMillis: 0,
        ).toJson());

    /// [caseId] open with [done] solved, every earlier case solved; then [location].
    Future<void> open(WidgetTester t, Size size, String caseId, List<String> done, String location,
        {String? opened}) async {
      t.view.physicalSize = size * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      final e = byId(caseId);
      final earlier = [for (final x in season) if (x.number < e.number) x];
      await t.pumpWidget(ProviderScope(
        overrides: await testOverrides(prefs: {
          for (final x in earlier)
            AppConstants.progressKeyFor(x.id): progress([for (final m in x.allMissions) m.id], solved: true),
          AppConstants.progressKeyFor(e.id): progress(done, opened: opened),
          AppConstants.seasonStorageKey: jsonEncode(
            SeasonProgress(activeEpisodeId: e.id, solvedEpisodeIds: [for (final x in earlier) x.id]).toJson(),
          ),
        }),
        child: const RepaintBoundary(key: ValueKey('shot'), child: LondonMysteryApp()),
      ));
      await wait(t, const Duration(milliseconds: 300));
      ProviderScope.containerOf(find.byType(LondonMysteryApp).evaluate().first).read(routerProvider).go(location);
      await wait(t, const Duration(milliseconds: 1500));
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 600)));
      await t.pump();
      expect(t.takeException(), isNull);
    }

    /// A line on screen, plain or with glossary words (drawn as GlossaryText).
    Finder shown(String line) => find.byWidgetPredicate(
        (w) => (w is GlossaryText && w.text == line) || (w is Text && w.data == line));

    Finder scroller() =>
        find.byWidgetPredicate((w) => w is Scrollable && w.physics is! NeverScrollableScrollPhysics).last;

    /// The page's tips, both opened (a mission page: "Get a tip"; a final: GET A TIP).
    Future<void> openTips(WidgetTester t, Mission m, String label) async {
      for (var i = 0; i < m.hints.length; i++) {
        await reveal(t, find.text(label));
        await t.tap(find.text(label));
        await wait(t, const Duration(milliseconds: 700));
        // A mission page asks again in the try-again sheet only on a wrong answer: none here.
      }
      await reveal(t, find.text(m.hints.last, findRichText: true));
    }

    /// The final's notebook sheet → [evidence] → look closer → [text].
    Future<void> lookCloser(WidgetTester t, String evidence, String text, String shot) async {
      final notebook = find.text('OPEN MY NOTEBOOK');
      await reveal(t, notebook);
      await t.tap(notebook);
      await wait(t, const Duration(milliseconds: 900));
      final tile = find.text(evidence);
      await t.scrollUntilVisible(tile, 200, scrollable: scroller());
      await wait(t, const Duration(milliseconds: 300));
      await t.tap(tile);
      await wait(t, const Duration(milliseconds: 700));
      expect(find.text(text), findsOneWidget, reason: '$evidence: $text');
      await capture(t, shot);
      expect(t.takeException(), isNull);
    }

    for (final size in const [Size(360, 640), Size(390, 844)]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}';

      testWidgets('Case 03 Mission 02 $tag: the letter, three cards, the red button in the notebook', (t) async {
        final m2 = byId('ep03').missionById('ep03_m2')!;
        await open(t, size, 'ep03', ['ep03_m1'], Routes.mission(m2.id), opened: m2.id);
        expect(shown(m2.question), findsOneWidget);
        await capture(t, 'ep03_m2_puzzle_$tag');
        for (final o in m2.options) {
          await reveal(t, find.text(o.label));
          final r = t.getRect(find.text(o.label));
          expect(r.right, lessThanOrEqualTo(size.width), reason: o.label);
        }
        await t.tap(find.text('Letter'));
        await wait(t, const Duration(milliseconds: 800));
        await capture(t, 'ep03_m2_letter_$tag');
        expect(find.textContaining('button', findRichText: true), findsNothing, reason: 'the letter does not repeat the button');
        await t.tap(find.text('BACK TO THE PUZZLE'));
        await wait(t, const Duration(milliseconds: 800));
        await t.tap(find.byTooltip('Detective notebook'));
        await wait(t, const Duration(milliseconds: 900));
        await t.tap(find.text('EVIDENCE'));
        await wait(t, const Duration(milliseconds: 600));
        expect(find.text('Red Button'), findsOneWidget);
        await capture(t, 'ep03_m2_notebook_$tag');
        expect(t.takeException(), isNull);
        await wait(t, const Duration(seconds: 2));
      });

      testWidgets('Case 03 final $tag: two clock towers; the boot decides', (t) async {
        final e = byId('ep03');
        await open(t, size, 'ep03', [for (final m in e.missions) m.id], Routes.finalMission);
        await capture(t, 'ep03_final_page_$tag');
        await reveal(t, shown(e.finalMission.question));
        await capture(t, 'ep03_final_question_$tag');
        await reveal(t, find.text('CHECK ANSWER'));
        await capture(t, 'ep03_final_pictures_$tag');
        await openTips(t, e.finalMission, 'GET A TIP');
        await capture(t, 'ep03_final_tips_$tag');
        await lookCloser(t, 'Wet Footprint', 'The boot smells of trains and smoke.', 'ep03_final_boot_$tag');
        await wait(t, const Duration(seconds: 2));
      });

      testWidgets('Case 07 final $tag: Grey turns you left; the joined map says where', (t) async {
        final e = byId('ep07');
        await open(t, size, 'ep07', [for (final m in e.missions) m.id], Routes.finalMission);
        await capture(t, 'ep07_final_page_$tag');
        await reveal(t, shown(e.finalMission.question));
        await capture(t, 'ep07_final_question_$tag');
        await reveal(t, find.text('CHECK ANSWER'));
        await capture(t, 'ep07_final_maps_$tag');
        await openTips(t, e.finalMission, 'GET A TIP');
        await capture(t, 'ep07_final_tips_$tag');
        await lookCloser(t, 'Joined Map', 'An arrow goes north, to the old gate of the park.', 'ep07_final_map_$tag');
        await wait(t, const Duration(seconds: 2));
      });

      testWidgets("Case 10 Mission 03 $tag: the note, four pictures, Poppy's words in the notebook", (t) async {
        final m3 = byId('ep10').missionById('ep10_m3')!;
        await open(t, size, 'ep10', ['ep10_m1', 'ep10_m2'], Routes.mission(m3.id), opened: m3.id);
        expect(shown(m3.question), findsOneWidget);
        await capture(t, 'ep10_m3_puzzle_$tag');
        await reveal(t, find.text('CHECK ANSWER'));
        for (final o in m3.options) {
          expect(find.text(o.label), findsOneWidget, reason: '${o.label}: named under its picture');
        }
        await capture(t, 'ep10_m3_pictures_$tag');
        await t.tap(find.text('Letter'));
        await wait(t, const Duration(milliseconds: 800));
        await capture(t, 'ep10_m3_letter_$tag');
        await t.tap(find.text('BACK TO THE PUZZLE'));
        await wait(t, const Duration(milliseconds: 800));
        await t.tap(find.byTooltip('Detective notebook'));
        await wait(t, const Duration(milliseconds: 900));
        expect(find.text('NORTH · TOWER · BRIDGE · THREE'), findsOneWidget, reason: "Poppy's words, the second clue");
        await capture(t, 'ep10_m3_notebook_$tag');
        expect(t.takeException(), isNull);
        await wait(t, const Duration(seconds: 2));
      });
    }
  });
}
