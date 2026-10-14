import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/data/mock/season1/season1_dialogues.dart';
import 'package:london_mystery/data/mock/season1/season1_discoveries.dart';
import 'package:london_mystery/data/mock/season1/season1_learning.dart';
import 'package:london_mystery/data/models/dialogue.dart';
import 'package:london_mystery/data/models/discovery.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/scoring.dart';
import 'package:london_mystery/features/game/wallet_controller.dart';
import 'package:london_mystery/widgets/art_assets.dart';
import 'package:london_mystery/widgets/game_button.dart';

import 'full_playthrough_test.dart' show reveal, tapText, wait;
import 'helpers.dart' show findReadable, findReadableContaining, tipSheetButton;
import 'mission_play.dart';
import 'title_screen_test.dart' show capture;

/// Wave 2 / 2.1 / 2.2 — Case 06 M1 (the Market Hall) is played by talking to
/// its three witnesses. The mission is said first (find out what the
/// stranger carried); the detective asks whom they like, what they like;
/// once two witnesses have said what he carried, their statements can be
/// compared, and the two that match, linked, answer the mission's puzzle
/// (`b`): its Clue, Evidence, XP, coins and save are the ones it always gave.
///
/// Wave 2.2 changed what earlier tests checked, on purpose (playtest: "I
/// don't know how to solve it; in COMPARE I don't know how to go back"):
/// comparing opened at any three statements (it could open with no two that
/// could match) — now at two witnesses' statements about what he carried;
/// the comparing page listed every statement — now those about what he
/// carried; the intro told who is here — now the mission; the bar counted
/// "n / 6" — gone (not every statement is needed).
void main() {
  final season = MockEpisodeRepository.bundled();
  final c06 = season.firstWhere((e) => e.id == 'ep06');
  final m1 = c06.missionById('ep06_m1')!;
  final m2 = c06.missionById('ep06_m2')!;
  final talk = dialogueOf(m1)!;
  final d = talk.deduction;

  group('the talk data (the approved script)', () {
    test('only Case 06 M1 is talked through; the link gives its own answer', () {
      expect(season1Dialogues.keys, ['ep06_m1']);
      expect(d.answer, m1.answer);
      expect(m1.answer, 'b');
      expect(m1.answerLabel, 'A small bag');
      expect(talk.place, 'MARKET HALL');
    });

    test('the mission is said first, never its answer', () {
      expect(talk.goal, 'Find out what the stranger carried.');
      expect(talk.how, 'Ask the witnesses. Look for two matching stories.');
      expect(talk.guide, 'Choose a witness to begin.');
      for (final line in [talk.goal, talk.how, talk.guide, d.askLine, d.askMoreLine, d.readyLine, d.question, d.prompt]) {
        expect(line.toLowerCase(), isNot(contains('bag')), reason: line);
      }
    });

    test("three witnesses of the case; the same three questions, the mission's first; answers word for word", () {
      expect(talk.speakers.map((s) => s.name), ['The flower seller', 'The juggler', 'The baker']);
      for (final s in talk.speakers) {
        expect(m1.letter.toLowerCase(), contains(s.name.toLowerCase()), reason: 'a witness of the case: ${s.name}');
      }
      expect(talk.questions.map((q) => q.text), ['What did he carry?', 'What was he wearing?', 'When did you see him?']);
      expect(talk.questions.first.id, d.topic);
      String say(String who, String q) => talk.speaker(who).answers[q]!.line;
      expect(talk.speaker('flowerSeller').greeting, 'The man in the dark coat? Oh yes, I saw him.');
      expect(say('flowerSeller', 'wearing'), 'He was wearing a dark coat.');
      expect(say('flowerSeller', 'carry'), 'He carried a small bag.');
      expect(say('flowerSeller', 'when'), 'Last night, just before midnight.');
      expect(talk.speaker('juggler').greeting, 'I saw him while I was juggling!');
      expect(say('juggler', 'wearing'), 'He had a grey hat.');
      expect(say('juggler', 'carry'), 'He carried a small bag.');
      expect(say('juggler', 'when'), 'Last night. The church clock was nearly at twelve.');
      expect(talk.speaker('baker').greeting, 'That stranger? He walked right past my stall.');
      expect(say('baker', 'wearing'), 'He had a dark coat.');
      expect(say('baker', 'carry'), 'He had a big red umbrella.');
      expect(say('baker', 'when'), 'Last night, when I was closing my stall.');
    });

    test('six statements, each what a witness said, about what they answer; "when" is never one', () {
      expect(talk.statements, hasLength(6));
      for (final s in talk.speakers) {
        for (final e in s.answers.entries) {
          final id = e.value.statementId;
          if (e.key == 'when') {
            expect(id, isNull, reason: '${s.id}: when');
            continue;
          }
          expect(talk.statement(id!).text, e.value.line);
          expect(talk.statement(id).speakerId, s.id);
          expect(talk.statement(id).about, e.key);
        }
      }
      for (final words in ['dark coat', 'small bag', 'grey hat', 'big red umbrella']) {
        expect(m1.letter, contains(words));
      }
    });

    test("the juggler's grey hat is kept for Mission 02's card", () {
      expect(talk.speaker('juggler').answers['wearing']!.line, 'He had a grey hat.');
      expect(m1.letter, contains('He had a grey hat.'));
      expect(m1.evidence!.inscription, contains('grey hat'));
      expect(m2.letter, contains('It is the colour of my hat,'));
      expect(learningOf(m2)!.recallFrom, 'ep06_m1');
      expect(learningOf(m1)!.expressions, ['He carried a small bag', 'Two witnesses agree']);
    });

    test('comparing opens at two witnesses on what he carried — matching or not — and never otherwise (A–G)', () {
      bool open(List<String> heard) => talk.canCompare(heard);
      // A. three statements on what he wore.
      expect(open(['flowerSeller.wearing', 'juggler.wearing', 'baker.wearing']), isFalse);
      // B. one witness on what he carried.
      expect(open(['flowerSeller.carry']), isFalse);
      // C, D, E. any two witnesses on what he carried.
      expect(open(['flowerSeller.carry', 'baker.carry']), isTrue, reason: 'they need not match');
      expect(open(['juggler.carry', 'baker.carry']), isTrue);
      expect(open(['flowerSeller.carry', 'juggler.carry']), isTrue);
      // G. many statements, but not two on what he carried.
      expect(open(['flowerSeller.wearing', 'juggler.wearing', 'baker.wearing', 'baker.carry']), isFalse);
      // Only those are compared, in the order heard.
      expect(talk.comparable(['baker.wearing', 'juggler.carry', 'flowerSeller.wearing', 'baker.carry']),
          ['juggler.carry', 'baker.carry']);
    });

    test('linking two statements: the right pair (either order), and why every other pair is not', () {
      expect(d.pair, {'flowerSeller.carry', 'juggler.carry'});
      expect(d.judge('flowerSeller.carry', 'juggler.carry'), isNull);
      expect(d.judge('juggler.carry', 'flowerSeller.carry'), isNull);
      expect(d.judge('flowerSeller.wearing', 'baker.wearing'), 'They agree — but a coat is worn, not carried.');
      expect(d.judge('juggler.wearing', 'flowerSeller.carry'), 'A hat is worn on the head, not carried. What did he hold?');
      expect(d.judge('baker.carry', 'juggler.carry'), 'Only the baker saw an umbrella. Which thing do TWO witnesses agree on?');
      expect(d.judge('flowerSeller.wearing', 'juggler.carry'), 'These two say different things. Find two that say the same.');
      final ids = talk.statements.map((s) => s.id).toList();
      var right = 0;
      for (var i = 0; i < ids.length; i++) {
        for (var j = i + 1; j < ids.length; j++) {
          if (d.judge(ids[i], ids[j]) == null) right++;
        }
      }
      expect(right, 1, reason: 'one right pair only');
    });

    test('a statement is written down once, however often it is heard', () {
      final p = DialogueProgress()..talkTo('flowerSeller');
      p.ask(talk, 'carry');
      expect(p.fresh, 'flowerSeller.carry');
      p.ask(talk, 'carry');
      expect(p.fresh, isNull);
      p.ask(talk, 'when');
      expect(p.heard, ['flowerSeller.carry']);
      p.talkTo('juggler');
      p.ask(talk, 'carry');
      expect(p.heard, ['flowerSeller.carry', 'juggler.carry']);
    });

    test('its pictures: three portraits and the market hall, registered and on disk', () {
      final portraits = {for (final s in talk.speakers) s.portrait};
      expect(ArtAssets.characters.values, containsAll(portraits));
      expect(talk.background, ArtAssets.marketHall);
      for (final f in [...portraits, ArtAssets.marketHall]) {
        expect(File(f).existsSync(), isTrue, reason: f);
      }
    });

    test('the mission keeps its Clue, Evidence and Discovery', () {
      expect(m1.clue!.title, 'A Small Bag');
      expect(m1.evidence!.name, 'Witness Notes');
      final disc = discoveryOf(m1);
      expect(disc.type, DiscoveryType.deduction);
      expect(disc.title, 'A SMALL BAG');
      expect(m1.nextMissionId, 'ep06_m2');
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

  final speech = find.byKey(const ValueKey('talk-speech'));
  Finder says(String words) => find.descendant(of: speech, matching: findReadableContaining(words));
  final fresh = find.byKey(const ValueKey('new-statement'));
  final compare = find.byKey(const ValueKey('compare-statements'));
  final feedback = find.byKey(const ValueKey('compare-feedback'));
  final back = find.byKey(const ValueKey('back-to-witnesses'));
  final link = find.byKey(const ValueKey('link-statements'));
  Finder next(String line) => find.text(line);

  Future<void> shot(WidgetTester t, String name) async {
    if (Platform.environment['LM_SCREENSHOTS'] == null) return;
    final context = t.element(find.byType(Scaffold).first);
    await t.runAsync(() async {
      for (final f in [talk.background, for (final s in talk.speakers) s.portrait]) {
        await precacheImage(AssetImage(f), context);
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await t.pump(const Duration(milliseconds: 100));
    await capture(t, name);
  }

  Future<void> ask(MissionPlay play, WidgetTester t, String who, String question) async {
    await play.tapKey(t, 'speaker-$who');
    await play.tapKey(t, 'question-$question');
  }

  Future<void> openCompare(MissionPlay play, WidgetTester t) =>
      play.tapKey(t, 'compare-statements', after: const Duration(milliseconds: 600));

  for (final size in const [Size(360, 640), Size(390, 844), Size(412, 915)]) {
    final tag = '${size.width.toInt()}x${size.height.toInt()}';

    group('playing it at $tag', () {
      testWidgets('arriving: YOUR MISSION, the people; no count of statements to fill', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'ep06_m1');
        await wait(t, const Duration(milliseconds: 1800));
        expect(find.text('YOUR MISSION'), findsOneWidget);
        expect(findReadable(talk.goal), findsOneWidget);
        expect(findReadable(talk.how), findsOneWidget);
        expect(find.text(talk.guide), findsOneWidget);
        expect(find.text('MARKET HALL'), findsOneWidget);
        expect(find.textContaining('/ 6'), findsNothing, reason: 'no "n / 6" to fill');
        expect(find.text('TAP TO OPEN'), findsNothing);
        expect(find.byKey(const ValueKey('talk-lineup')), findsOneWidget);
        await shot(t, 'case06_m1_w22_${tag}_arrival');

        // A witness: the mission stays in sight; the mission's question first and marked.
        await play.tapKey(t, 'lineup-flowerSeller');
        expect(find.byKey(const ValueKey('talk-mission')), findsOneWidget);
        final tops = [for (final q in talk.questions) t.getRect(find.byKey(ValueKey('question-${q.id}'))).top];
        expect(tops, orderedEquals([...tops]..sort()));
        expect(next(d.askLine), findsOneWidget);
        expect(compare, findsNothing, reason: 'no disabled COMPARE in its place');
        await shot(t, 'case06_m1_w22_${tag}_first_witness');
      });

      testWidgets('path A: two witnesses asked what he carried, and nothing else; linked; Discovery', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'ep06_m1');
        await ask(play, t, 'flowerSeller', 'carry');
        expect(says('He carried a small bag.'), findsOneWidget);
        expect(fresh, findsOneWidget);
        expect(compare, findsNothing);
        expect(next(d.askMoreLine), findsOneWidget, reason: 'one witness heard: ask another');
        await ask(play, t, 'juggler', 'carry');
        expect(compare, findsOneWidget);
        expect(find.byKey(const ValueKey('compare-ready')), findsOneWidget, reason: 'announced once');
        expect(next(d.readyLine), findsOneWidget);
        expect(find.descendant(of: compare, matching: find.text('COMPARE CLUES')), findsOneWidget);
        await shot(t, 'case06_m1_w22_${tag}_compare_ready');

        await openCompare(play, t);
        expect(find.text('COMPARE CLUES'), findsWidgets);
        expect(findReadable(d.question), findsOneWidget);
        expect(find.text(d.prompt), findsOneWidget);
        expect(t.widget<GameButton>(link).onPressed, isNull, reason: 'two to choose first');
        expect(t.widget<GameButton>(back).onPressed, isNotNull);
        await play.tapKey(t, 'pick-flowerSeller.carry');
        expect(t.widget<GameButton>(link).onPressed, isNull);
        await play.tapKey(t, 'pick-juggler.carry');
        expect(t.widget<GameButton>(link).onPressed, isNotNull);
        await shot(t, 'case06_m1_w22_${tag}_compare_two');
        await play.tapKey(t, 'link-statements', after: const Duration(milliseconds: 500));
        expect(find.byKey(const ValueKey('compare-match')), findsOneWidget);
        expect(play.ref.read(gameControllerProvider).isCompleted('ep06_m1'), isFalse, reason: 'the MATCH is seen first');
        await wait(t, const Duration(milliseconds: 2400));
        expect(find.byKey(const ValueKey('discovery-moment')), findsOneWidget);

        final progress = play.ref.read(gameControllerProvider);
        expect(progress.isCompleted('ep06_m1'), isTrue);
        expect(progress.attempts['ep06_m1'], 1, reason: 'answered once');
        expect(progress.collectedEvidence(c06).map((e) => e.id), contains('ep06_e1'));
        expect(progress.collectedClues(c06).map((c) => c.id), contains('ep06_c1'));
        expect(XpBreakdown.of(m1, progress).total, 30);
        expect(progress.isUnlocked(c06, 'ep06_m2'), isTrue);
        expect(play.ref.read(walletProvider).entries.where((e) => e.key == 'mission:ep06_m1'), hasLength(1));
      });

      testWidgets('path B: a wrong link, BACK TO WITNESSES, one more witness, the right link', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'ep06_m1');
        await ask(play, t, 'baker', 'carry');
        await ask(play, t, 'flowerSeller', 'carry');
        expect(compare, findsOneWidget, reason: 'two witnesses on what he carried: matching or not');

        await openCompare(play, t);
        expect(find.byKey(const ValueKey('pick-baker.carry')), findsOneWidget);
        expect(find.byKey(const ValueKey('pick-flowerSeller.carry')), findsOneWidget);
        await play.tapKey(t, 'pick-baker.carry');
        await play.tapKey(t, 'pick-flowerSeller.carry');
        await play.tapKey(t, 'link-statements');
        expect(
          find.descendant(
            of: feedback,
            matching: find.text('Only the baker saw an umbrella. Which thing do TWO witnesses agree on? Try another witness.'),
            matchRoot: true,
          ),
          findsOneWidget,
          reason: 'none of these match: there is someone else to ask',
        );
        expect(t.widget<GameButton>(back).onPressed, isNotNull);
        await shot(t, 'case06_m1_w22_${tag}_compare_wrong');

        // BACK TO WITNESSES: the talk as it was.
        await play.tapKey(t, 'back-to-witnesses', after: const Duration(milliseconds: 600));
        expect(find.text(d.prompt), findsNothing);
        expect(find.text('THE FLOWER SELLER'), findsOneWidget, reason: 'the same witness');
        expect(find.bySemanticsLabel('What did he carry?, asked'), findsOneWidget);
        expect(compare, findsOneWidget);

        await ask(play, t, 'juggler', 'carry');
        await openCompare(play, t);
        expect(find.byKey(const ValueKey('pick-juggler.carry')), findsOneWidget);
        await play.tapKey(t, 'pick-flowerSeller.carry');
        await play.tapKey(t, 'pick-juggler.carry');
        await play.tapKey(t, 'link-statements', after: const Duration(milliseconds: 2600));
        await wait(t, const Duration(milliseconds: 800));
        expect(find.byKey(const ValueKey('discovery-moment')), findsOneWidget);
        final progress = play.ref.read(gameControllerProvider);
        expect(progress.attempts['ep06_m1'], 1, reason: 'the wrong link was not recorded');
        expect(progress.wrongCount('ep06_m1'), 0);
      });

      testWidgets('what he wore never opens comparing; it stays in the statements', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'ep06_m1');
        await ask(play, t, 'flowerSeller', 'wearing');
        await ask(play, t, 'juggler', 'wearing');
        await ask(play, t, 'baker', 'wearing');
        await ask(play, t, 'baker', 'when');
        expect(compare, findsNothing);
        expect(next(d.askLine), findsOneWidget);
        await ask(play, t, 'baker', 'carry');
        expect(compare, findsNothing, reason: 'one witness on what he carried');
        expect(next(d.askMoreLine), findsOneWidget);

        await play.tapKey(t, 'open-statements', after: const Duration(milliseconds: 500));
        final sheet = find.byKey(const ValueKey('statements-sheet'));
        expect(find.descendant(of: sheet, matching: findReadable('"He had a grey hat."')), findsOneWidget);
        await tapText(t, 'BACK TO THE WITNESSES', after: const Duration(milliseconds: 500));

        // The flower seller's bag: comparing opens; it shows only what was carried.
        await ask(play, t, 'flowerSeller', 'carry');
        await openCompare(play, t);
        expect(find.byKey(const ValueKey('pick-baker.carry')), findsOneWidget);
        expect(find.byKey(const ValueKey('pick-flowerSeller.carry')), findsOneWidget);
        expect(find.byKey(const ValueKey('pick-juggler.wearing')), findsNothing);
        expect(find.byKey(const ValueKey('pick-flowerSeller.wearing')), findsNothing);
        // The system back closes it too.
        await t.binding.handlePopRoute();
        await wait(t, const Duration(milliseconds: 600));
        expect(find.text(d.prompt), findsNothing);
        expect(find.text('THE FLOWER SELLER'), findsOneWidget);
        expect(play.ref.read(gameControllerProvider).attempts['ep06_m1'] ?? 0, 0);
      });

      testWidgets('a tip; back to the place keeps the talk; a restart begins again', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'ep06_m1');
        await ask(play, t, 'juggler', 'carry');
        await reveal(t, find.text('Get a tip'));
        await tapText(t, 'Get a tip', after: const Duration(milliseconds: 500));
        await t.tap(tipSheetButton);
        await wait(t, const Duration(milliseconds: 800));
        expect(
          find.descendant(of: find.byKey(const ValueKey('statements-sheet')), matching: find.text('DETECTIVE TIP 1')),
          findsOneWidget,
        );
        await tapText(t, 'BACK TO THE WITNESSES', after: const Duration(milliseconds: 500));

        await t.tap(find.byTooltip('Back'));
        await wait(t, const Duration(milliseconds: 600));
        await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 600));
        expect(find.text('THE JUGGLER'), findsOneWidget);
        expect(next(d.askMoreLine), findsOneWidget);

        await play.restart(t);
        play.ref.read(routerProvider).go(Routes.mission('ep06_m1'));
        await wait(t, const Duration(milliseconds: 1400));
        expect(find.text('YOUR MISSION'), findsOneWidget);
        expect(play.ref.read(gameControllerProvider).isCompleted('ep06_m1'), isFalse);
      });

      testWidgets('layout: the portrait leads, questions and both compare buttons fit', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'ep06_m1');
        await ask(play, t, 'baker', 'carry');
        final screen = Offset.zero & size;
        expect(t.getRect(find.byKey(const ValueKey('talk-panel'))).width, size.width);
        final portrait = t.getRect(find.byKey(const ValueKey('talk-portrait')));
        expect(screen.contains(portrait.topLeft) && screen.contains(portrait.bottomRight - const Offset(1, 1)), isTrue);
        expect(portrait.width / portrait.height, closeTo(ArtAssets.witnessPortraitAspect, 0.02));
        final least = {360.0: 150.0, 390.0: 190.0, 412.0: 210.0}[size.width]!;
        expect(portrait.height, greaterThanOrEqualTo(least), reason: 'portrait ${portrait.size}');
        final card = t.getRect(speech);
        final answer = t.getRect(find.descendant(of: speech, matching: findReadableContaining('He had a big red umbrella.')));
        expect(answer.bottom, lessThanOrEqualTo(card.bottom), reason: 'the answer reads without scrolling');
        for (final q in talk.questions) {
          expect(t.getRect(find.byKey(ValueKey('question-${q.id}'))).height, greaterThanOrEqualTo(48), reason: q.text);
        }
        expect(screen.contains(t.getRect(next(d.askMoreLine)).bottomCenter - const Offset(0, 1)), isTrue);
        await shot(t, 'case06_m1_w22_${tag}_layout');

        await ask(play, t, 'juggler', 'carry');
        await openCompare(play, t);
        for (final b in [link, back]) {
          final r = t.getRect(b);
          expect(screen.contains(r.topLeft) && screen.contains(r.bottomRight - const Offset(1, 1)), isTrue);
          expect(r.height, greaterThanOrEqualTo(48));
        }
      });
    });
  }

  group('larger text and still motion', () {
    testWidgets('text 1.3× at 360×640: mission, talk, comparing and both buttons fit', (t) async {
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(360, 640), 'ep06_m1', textScale: 1.3);
      await wait(t, const Duration(milliseconds: 1800));
      expect(findReadable(talk.goal), findsOneWidget);
      await shot(t, 'case06_m1_w22_360x640_text13_arrival');
      await ask(play, t, 'flowerSeller', 'carry');
      expect(t.renderObject<RenderParagraph>(find.text('MARKET HALL')).didExceedMaxLines, isFalse);
      final card = t.getRect(speech);
      final answer = t.getRect(find.descendant(of: speech, matching: findReadableContaining('He carried a small bag.')));
      expect(answer.bottom, lessThanOrEqualTo(card.bottom));
      await ask(play, t, 'juggler', 'carry');
      await shot(t, 'case06_m1_w22_360x640_text13');
      await openCompare(play, t);
      final screen = Offset.zero & const Size(360, 640);
      for (final b in [link, back]) {
        expect(screen.contains(t.getRect(b).bottomCenter - const Offset(0, 1)), isTrue);
      }
      await play.tapKey(t, 'pick-flowerSeller.carry');
      await play.tapKey(t, 'pick-juggler.carry');
      await shot(t, 'case06_m1_w22_360x640_text13_compare');
      await play.tapKey(t, 'link-statements', after: const Duration(milliseconds: 2600));
      expect(find.byKey(const ValueKey('discovery-moment')), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('reduced motion: the mission shows at once; COMPARE is marked in gold without the glow', (t) async {
      t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(390, 844), 'ep06_m1');
      expect(find.text('YOUR MISSION'), findsOneWidget);
      await ask(play, t, 'flowerSeller', 'carry');
      await ask(play, t, 'juggler', 'carry');
      expect(t.widget<TweenAnimationBuilder<double>>(find.byKey(const ValueKey('compare-ready'))).tween.begin, 1);
    });
  });
}
