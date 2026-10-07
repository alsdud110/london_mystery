import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/core/utils/answer_checker.dart';
import 'package:london_mystery/data/models/episode.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/mission.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/widgets/glossary_text.dart';
import 'package:london_mystery/widgets/letter_card.dart';

import 'full_playthrough_test.dart' show reveal, wait;
import 'helpers.dart';
import 'title_screen_test.dart' show capture;

/// Case 09's final asks "whose": R.'s note says the jewel is in the thing of
/// "the one whose key you used". Anna used the key, but it was the guard's
/// (Mission 01, kept in the notebook); the guard is Carl; the detective's
/// notes leave Carl the hat. Without Mission 01, any of the three things
/// could be it.
void main() {
  final season = MockEpisodeRepository.bundled();
  Episode byId(String id) => season.firstWhere((e) => e.id == id);
  final e = byId('ep09');
  final m1 = e.missionById('ep09_m1')!, m2 = e.missionById('ep09_m2')!, m3 = e.missionById('ep09_m3')!;
  final fin = e.finalMission;

  /// What the player reads before the final's answer is checked.
  String beforeFinal() => [
        ...e.synopsis,
        ...e.intro,
        ...e.objectives,
        for (final m in e.missions) ...[
          m.title,
          m.location,
          ...m.story,
          m.letterIntro,
          m.letter,
          m.question,
          ?m.prompt,
          for (final o in m.options) o.label,
          ...m.hints,
          m.successMessage,
          if (m.clue case final c?) ...[c.title, c.value, c.note],
          if (m.evidence case final v?) ...[v.name, v.description, ?v.inscription],
          ...m.transition,
        ],
        fin.title,
        fin.location,
        ...fin.story,
        fin.letterIntro,
        fin.question,
        ?fin.prompt,
        ...fin.hints,
      ].join('\n');

  bool word(String text, String w) => RegExp('\\b$w\\b', caseSensitive: false).hasMatch(text);

  group('data', () {
    test('the final is still the hat, typed (HAT and its accepted forms)', () {
      expect(fin.type, MissionType.wordInput);
      expect(fin.answer, 'HAT');
      expect(fin.prompt, 'IN THE ___');
      expect(AnswerChecker.isCorrect(fin, 'hat'), isTrue);
      expect(AnswerChecker.isCorrect(fin, 'tall black hat'), isTrue);
      for (final wrong in ['umbrella', 'bag', 'red umbrella', 'green bag']) {
        expect(AnswerChecker.isCorrect(fin, wrong), isFalse, reason: wrong);
      }
    });

    test("Mission 01's key is the source: whose key it is, kept in the notebook", () {
      expect(m1.answerLabel, "The guard's key");
      expect(m1.clue!.value, 'Guard');
      expect(m1.clue!.note, "Only the guard's big gold key opens the case.");
      expect(m1.transition.join(' '), contains('Yesterday I gave it to the new helper!'));
      expect(m2.clue!.note, "Anna had the guard's key.");
    });

    test("the final gives the rule and the things, never whose key it was", () {
      expect(fin.letter, contains('whose key you used'));
      expect(fin.letter, allOf(contains('Ben has the green bag.'), contains("Anna's thing is not black.")));
      // Who the key belongs to is not on the final page: Mission 01 tells it.
      final page = [...fin.story, fin.letterIntro, fin.letter, fin.question, ...fin.hints].join(' ');
      expect(page, isNot(contains("guard's")));
      expect(page.toLowerCase(), isNot(contains('belongs')));
      // The people are on the page, so the key's owner can be found among them.
      expect(fin.story.first, allOf(contains('Ben the gardener'), contains('Carl the guard')));
    });

    test('without Mission 01 the notes leave all three things open', () {
      // The notes fix Ben → bag and Anna → not the black hat; the jewel's
      // owner is only "the one whose key you used". Anna (who used it) →
      // umbrella; Ben → bag; Carl (whose it was) → hat. Only the key decides.
      final notes = fin.letter.split('Your notes:').last;
      expect(notes, isNot(contains('Carl')));
      expect(notes, isNot(contains('jewel')));
      expect(fin.letter, isNot(contains("Carl's")));
    });

    test('nothing before the answer says hat, except the list of three things', () {
      expect(word(beforeFinal(), 'hats?'), isFalse);
      expect(fin.title, 'The Three Things', reason: 'the map shows this title before the answer');
      for (final h in fin.hints) {
        expect(AnswerChecker.normalize(h).contains('HAT'), isFalse, reason: h);
        expect(h, isNot(contains('Carl')), reason: h);
      }
    });

    test('Case 08 → 09 → 10 stay', () {
      final ep08 = byId('ep08').finalMission;
      expect(ep08.evidence!.inscription, 'BUCKINGHAM PALACE — it is empty.');
      expect(ep08.transition, contains('"The Clockmaker gives the orders."'));
      expect(e.intro.join(' '), contains("The jewel box from Mrs Robin's suitcase came from here."));
      expect(m2.evidence!.inscription, 'A _ _ A — a raven is drawn on the back.');
      expect(fin.evidence!.name, 'The Blue Star');
      expect(fin.transition, [
        'The Blue Star is safe.',
        "But on the back of Anna's name tag,\na raven is drawn.",
        'And the card inside the hat\nleft a warning:',
        '"The jewel was never the prize."',
        '"Watch the ravens."',
      ]);
      expect(e.hook, 'Inside the hat, a card: "The jewel was never the prize. Watch the ravens."');
      expect(byId('ep10').intro.first, 'Tower of London, 7:00 AM...');
      expect(m3.answer, '12');
      expect(m3.transition.join(' '), contains('Carl the guard'));
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

    String progress(List<String> done, {bool solved = false}) => jsonEncode(GameProgress(
          detectiveName: 'MINYOUNG',
          introSeen: true,
          completedMissionIds: done,
          startedAt: DateTime(2026, 10, 7, 10),
          completedAt: solved ? DateTime(2026, 10, 7, 10, 40) : null,
          playMillis: 0,
        ).toJson());

    Future<void> openFinal(WidgetTester t, Size size) async {
      t.view.physicalSize = size * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
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
      await wait(t, const Duration(milliseconds: 1500));
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 600)));
      await t.pump();
      expect(t.takeException(), isNull);
    }

    Finder shown(String line) =>
        find.byWidgetPredicate((w) => (w is GlossaryText && w.text == line) || (w is Text && w.data == line));

    Finder scroller() =>
        find.byWidgetPredicate((w) => w is Scrollable && w.physics is! NeverScrollableScrollPhysics).last;

    for (final size in const [Size(360, 640), Size(390, 844)]) {
      final tag = '${size.width.toInt()}x${size.height.toInt()}';

      testWidgets('final $tag: the note, the notes, the blank, the tips, the key in the notebook', (t) async {
        await openFinal(t, size);
        await capture(t, 'ep09_final_page_$tag');
        await reveal(t, find.byType(LetterCard));
        await capture(t, 'ep09_final_letter_$tag');
        await reveal(t, shown(fin.question));
        await reveal(t, find.text('CHECK ANSWER'));
        await capture(t, 'ep09_final_puzzle_$tag');
        for (var i = 0; i < fin.hints.length; i++) {
          await reveal(t, find.text('GET A TIP'));
          await t.tap(find.text('GET A TIP'));
          await wait(t, const Duration(milliseconds: 700));
        }
        await reveal(t, find.text(fin.hints.last));
        await capture(t, 'ep09_final_tips_$tag');
        expect(t.takeException(), isNull);

        // The notebook: CLUE #01, the guard's key (and the gold key's card).
        await reveal(t, find.text('OPEN MY NOTEBOOK'));
        await t.tap(find.text('OPEN MY NOTEBOOK'));
        await wait(t, const Duration(milliseconds: 900));
        final key = find.text("Only the guard's big gold key opens the case.");
        await t.scrollUntilVisible(key, 200, scrollable: scroller());
        await wait(t, const Duration(milliseconds: 300));
        expect(key, findsOneWidget);
        expect(find.text('"The Gold Key"'), findsOneWidget);
        await capture(t, 'ep09_final_notebook_$tag');
        expect(t.takeException(), isNull);
        await wait(t, const Duration(seconds: 2));
      });
    }

    testWidgets('final 390x844: Anna\'s thing is the slip; the guard\'s hat solves the case', (t) async {
      await openFinal(t, const Size(390, 844));
      Future<void> type(String answer) async {
        final field = find.byType(TextField);
        await reveal(t, field);
        await t.enterText(field, answer);
        await wait(t, const Duration(milliseconds: 200));
        await reveal(t, find.text('CHECK ANSWER'));
        await t.tap(find.text('CHECK ANSWER'));
        await wait(t, const Duration(milliseconds: 900));
      }

      await type('umbrella'); // she used the key, but it was not hers
      expect(find.text('Not quite!'), findsOneWidget);
      await t.tap(find.text('TRY AGAIN'));
      await wait(t, const Duration(milliseconds: 600));
      await type('hat');
      await wait(t, const Duration(milliseconds: 3500));
      expect(find.text('CASE SOLVED'), findsOneWidget);
      expect(find.text(fin.successMessage), findsOneWidget);
      await capture(t, 'ep09_final_solved_390x844');
      await wait(t, const Duration(seconds: 2));
    });
  });
}
