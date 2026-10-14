import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/core/theme/app_tokens.dart';
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
import 'package:london_mystery/widgets/guided_action_indicator.dart';
import 'package:london_mystery/widgets/paper.dart';

import 'full_playthrough_test.dart' show reveal, tapText, wait;
import 'helpers.dart' show findReadable, findReadableContaining, tipSheetButton;
import 'mission_play.dart';
import 'title_screen_test.dart' show capture;

/// Wave 2 / 2.1 / 2.2 / 2.3 — Case 06 M1 (the Market Hall) is played by talking to
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
///
/// Wave 2.3 changed them again, on purpose (one next thing at a time, for
/// an 8-year-old): arriving shows only the three prints to choose from (no
/// row of faces); the mission's question stands alone, the others under
/// "Other questions"; comparing shows two stories side by side and asks
/// YES / NO (with three, two witnesses are chosen first) instead of picking
/// two statements and LINK; the comparing page is COMPARE STORIES.
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
      expect(talk.how, 'Two witnesses may have seen the same thing.');
      expect(talk.guide, 'Choose a witness to begin.');
      for (final line in [
        talk.goal, talk.how, talk.guide, d.foundLine, d.readyLine, d.question, d.choose, //
        d.matchLine, d.differentLine, d.otherPairLine, d.lookAgainLine,
      ]) {
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

    test('two stories match only for the right pair (either order); every other pair is different', () {
      expect(d.pair, {'flowerSeller.carry', 'juggler.carry'});
      expect(d.matches('flowerSeller.carry', 'juggler.carry'), isTrue);
      expect(d.matches('juggler.carry', 'flowerSeller.carry'), isTrue);
      expect(d.matches('flowerSeller.carry', 'flowerSeller.carry'), isFalse);
      expect(d.matches('flowerSeller.carry', 'baker.carry'), isFalse);
      expect(d.matches('juggler.carry', 'baker.carry'), isFalse);
      final ids = talk.statements.map((s) => s.id).toList();
      var right = 0;
      for (var i = 0; i < ids.length; i++) {
        for (var j = i + 1; j < ids.length; j++) {
          if (d.matches(ids[i], ids[j])) right++;
        }
      }
      expect(right, 1, reason: 'one right pair only');
      // Being wrong never says which way.
      for (final w in ['yes', 'no', 'bag', 'umbrella', 'same thing.']) {
        expect(d.lookAgainLine.toLowerCase().endsWith(w), isFalse, reason: w);
      }
      expect(d.lookAgainLine, 'Look again. Are they carrying the same thing?');
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
  final yes = find.byKey(const ValueKey('say-same'));
  final no = find.byKey(const ValueKey('say-different'));
  final askAnother = find.byKey(const ValueKey('ask-another-witness'));
  final anotherPair = find.byKey(const ValueKey('choose-another-pair'));
  final mark = find.byKey(const ValueKey('talk-mark'));
  Finder next(String line) => find.text(line);
  Finder marked(String words, {bool sheet = false}) => find.descendant(
        of: find.byKey(ValueKey(sheet ? 'compare-mark' : 'talk-mark')),
        matching: find.text(words),
        matchRoot: true,
      );
  Finder verdict(String line) =>
      find.descendant(of: feedback, matching: find.textContaining(line, findRichText: true), matchRoot: true);
  Finder story(String id) => find.byKey(ValueKey('story-$id'));
  Finder faces() => find.byWidgetPredicate((w) => w.key is ValueKey<String> && (w.key as ValueKey<String>).value.startsWith('speaker-'));
  bool done(MissionPlay play) => play.ref.read(gameControllerProvider).isCompleted('ep06_m1');

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

  /// Talks to [who] (from the prints when arriving, the faces when talking)
  /// and asks [question] (opening "Other questions" for it when it is shut).
  Future<void> ask(MissionPlay play, WidgetTester t, String who, String question) async {
    final print = find.byKey(ValueKey('lineup-$who'));
    await play.tapKey(t, print.evaluate().isNotEmpty ? 'lineup-$who' : 'speaker-$who');
    if (find.byKey(ValueKey('question-$question')).evaluate().isEmpty) await play.tapKey(t, 'other-questions');
    await play.tapKey(t, 'question-$question');
  }

  Future<void> openCompare(MissionPlay play, WidgetTester t) =>
      play.tapKey(t, 'compare-statements', after: const Duration(milliseconds: 600));

  void expectRewardedOnce(MissionPlay play) {
    final progress = play.ref.read(gameControllerProvider);
    expect(progress.isCompleted('ep06_m1'), isTrue);
    expect(progress.attempts['ep06_m1'], 1, reason: 'answered once');
    expect(progress.wrongCount('ep06_m1'), 0, reason: 'wrong yes / no is never recorded');
    expect(progress.collectedEvidence(c06).map((e) => e.id), contains('ep06_e1'));
    expect(progress.collectedClues(c06).map((c) => c.id), contains('ep06_c1'));
    expect(XpBreakdown.of(m1, progress).total, 30);
    expect(progress.isUnlocked(c06, 'ep06_m2'), isTrue);
    expect(play.ref.read(walletProvider).entries.where((e) => e.key == 'mission:ep06_m1'), hasLength(1));
  }

  for (final size in const [Size(360, 640), Size(390, 844), Size(412, 915)]) {
    final tag = '${size.width.toInt()}x${size.height.toInt()}';

    group('playing it at $tag', () {
      testWidgets('step 1 → 2: the mission and three prints only; then the question first, the others folded', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'ep06_m1');
        await wait(t, const Duration(milliseconds: 1800));
        expect(find.text('YOUR MISSION'), findsOneWidget);
        expect(findReadable(talk.goal), findsOneWidget);
        expect(findReadable(talk.how), findsOneWidget);
        expect(find.text(talk.guide), findsOneWidget);
        expect(find.text('MARKET HALL'), findsOneWidget);
        expect(find.textContaining('/ 6'), findsNothing, reason: 'no "n / 6" to fill');
        expect(find.byKey(const ValueKey('talk-lineup')), findsOneWidget);
        for (final s in talk.speakers) {
          expect(find.byKey(ValueKey('lineup-${s.id}')), findsOneWidget);
        }
        expect(faces(), findsNothing, reason: 'one way to choose a witness when arriving');
        expect(find.byKey(const ValueKey('question-carry')), findsNothing);
        expect(find.byKey(const ValueKey('open-statements')), findsNothing);
        expect(compare, findsNothing);
        final screen = Offset.zero & size;
        for (final s in talk.speakers) {
          final r = t.getRect(find.byKey(ValueKey('lineup-${s.id}')));
          expect(screen.contains(r.topLeft) && screen.contains(r.bottomRight - const Offset(1, 1)), isTrue);
          expect(r.height, greaterThanOrEqualTo(110), reason: 'a large print to tap');
        }
        await shot(t, 'case06_m1_w24_${tag}_1_arrival');

        await play.tapKey(t, 'lineup-baker');
        expect(find.byKey(const ValueKey('talk-mission')), findsOneWidget);
        expect(faces(), findsNWidgets(3), reason: 'talking: the faces to change witness');
        expect(find.byKey(const ValueKey('question-carry')), findsOneWidget);
        expect(find.byKey(const ValueKey('question-wearing')), findsNothing, reason: 'folded under Other questions');
        expect(find.byKey(const ValueKey('question-when')), findsNothing);
        expect(find.text('Other questions'), findsOneWidget);
        expect(mark, findsNothing, reason: 'nothing found yet');
        expect(t.getRect(find.byKey(const ValueKey('question-carry'))).height, greaterThanOrEqualTo(56));
        await play.tapKey(t, 'other-questions');
        expect(find.byKey(const ValueKey('question-wearing')), findsOneWidget);
        expect(find.byKey(const ValueKey('question-when')), findsOneWidget);
        await shot(t, 'case06_m1_w24_${tag}_2_questions');
        // Still open with another witness; closed when closed.
        await play.tapKey(t, 'speaker-juggler');
        expect(find.byKey(const ValueKey('question-wearing')), findsOneWidget);
        await play.tapKey(t, 'other-questions');
        expect(find.byKey(const ValueKey('question-wearing')), findsNothing);
      });

      testWidgets('path A: two witnesses on what he carried, nothing else; side by side; YES; Discovery', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'ep06_m1');
        await ask(play, t, 'flowerSeller', 'carry');
        expect(says('He carried a small bag.'), findsOneWidget);
        expect(fresh, findsOneWidget);
        expect(compare, findsNothing);
        expect(marked('CLUE FOUND'), findsOneWidget);
        expect(next(d.foundLine), findsOneWidget);
        expect(find.byKey(const ValueKey('found-flowerSeller')), findsOneWidget, reason: 'ticked');
        expect(find.byKey(const ValueKey('found-juggler')), findsNothing);
        await shot(t, 'case06_m1_w24_${tag}_3_clue_found');

        await ask(play, t, 'juggler', 'carry');
        expect(compare, findsOneWidget);
        expect(find.descendant(of: compare, matching: find.text('COMPARE STORIES')), findsOneWidget);
        expect(find.byKey(const ValueKey('compare-ready')), findsOneWidget, reason: 'announced once');
        expect(marked('TWO STORIES COLLECTED'), findsOneWidget);
        expect(next(d.readyLine), findsOneWidget);
        expect(find.byKey(const ValueKey('found-juggler')), findsOneWidget);
        await shot(t, 'case06_m1_w24_${tag}_4_two_stories');

        await openCompare(play, t);
        expect(find.text('COMPARE STORIES'), findsWidgets);
        expect(find.byKey(const ValueKey('compare-choose')), findsNothing, reason: 'two stories: shown at once');
        expect(story('flowerSeller.carry'), findsOneWidget);
        expect(story('juggler.carry'), findsOneWidget);
        final left = t.getRect(story('flowerSeller.carry')), right = t.getRect(story('juggler.carry'));
        expect(left.right, lessThanOrEqualTo(right.left), reason: 'side by side');
        expect(left.top, closeTo(right.top, 1));
        expect(findReadable(d.question), findsOneWidget);
        expect(t.widget<GameButton>(yes).onPressed, isNotNull);
        expect(t.widget<GameButton>(no).onPressed, isNotNull);
        await shot(t, 'case06_m1_w24_${tag}_5_compare_two');
        await play.tapKey(t, 'say-same', after: const Duration(milliseconds: 500));
        expect(find.byKey(const ValueKey('compare-match')), findsOneWidget);
        expect(find.text('THE STORIES MATCH!'), findsOneWidget);
        expect(findReadable(d.matchLine), findsOneWidget);
        expect(done(play), isFalse, reason: 'the match is seen first');
        await shot(t, 'case06_m1_w24_${tag}_6_match');
        await wait(t, const Duration(milliseconds: 2600));
        expect(find.byKey(const ValueKey('discovery-moment')), findsOneWidget);
        expectRewardedOnce(play);
      });

      testWidgets('path B: different stories, NO, back, one more witness, choose two, YES', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'ep06_m1');
        await ask(play, t, 'flowerSeller', 'carry');
        await ask(play, t, 'baker', 'carry');
        expect(compare, findsOneWidget, reason: 'two witnesses on what he carried: matching or not');

        await openCompare(play, t);
        expect(story('flowerSeller.carry'), findsOneWidget);
        expect(story('baker.carry'), findsOneWidget);
        final yesAt = t.getRect(yes), noAt = t.getRect(no);
        await play.tapKey(t, 'say-different');
        expect(verdict(d.differentLine), findsOneWidget);
        expect(marked('DIFFERENT STORIES', sheet: true), findsOneWidget);
        // Answered: YES / NO stay where they were, put aside; the way on is
        // ASK ANOTHER WITNESS, in place of BACK TO WITNESSES (not both).
        expect(t.widget<GameButton>(yes).onPressed, isNull);
        expect(t.widget<GameButton>(no).onPressed, isNull);
        expect(t.getRect(yes), yesAt, reason: 'nothing moves under the finger');
        expect(t.getRect(no), noAt);
        expect(back, findsNothing);
        expect(t.widget<GameButton>(askAnother).style, GameButtonStyle.navy);
        expect(done(play), isFalse);
        await shot(t, 'case06_m1_w24_${tag}_7_different');

        // ASK ANOTHER WITNESS: the talk as it was; the next thing is another witness.
        await play.tapKey(t, 'ask-another-witness', after: const Duration(milliseconds: 600));
        expect(find.byKey(const ValueKey('compare-pair')), findsNothing);
        expect(find.text('THE BAKER'), findsOneWidget, reason: 'the same witness');
        expect(find.bySemanticsLabel('What did he carry?, asked'), findsOneWidget);
        expect(marked('DIFFERENT STORIES'), findsOneWidget);
        expect(t.widget<GameButton>(compare).style, GameButtonStyle.outline, reason: 'not the next thing now');
        expect(find.byKey(const ValueKey('found-flowerSeller')), findsOneWidget);
        expect(find.byKey(const ValueKey('found-baker')), findsOneWidget);
        await shot(t, 'case06_m1_w24_${tag}_8_back');

        await ask(play, t, 'juggler', 'carry');
        expect(marked('THREE STORIES COLLECTED'), findsOneWidget);
        expect(t.widget<GameButton>(compare).style, GameButtonStyle.navy);
        await openCompare(play, t);
        expect(find.byKey(const ValueKey('compare-choose')), findsOneWidget);
        expect(story('flowerSeller.carry'), findsNothing, reason: 'none chosen for the detective');
        expect(t.widget<GameButton>(yes).onPressed, isNull, reason: 'two witnesses to choose first');
        expect(t.widget<GameButton>(no).onPressed, isNull);
        await play.tapKey(t, 'pick-flowerSeller');
        expect(t.widget<GameButton>(yes).onPressed, isNull);
        await play.tapKey(t, 'pick-juggler');
        expect(story('flowerSeller.carry'), findsOneWidget);
        expect(story('juggler.carry'), findsOneWidget);
        await shot(t, 'case06_m1_w24_${tag}_9_compare_three');
        await play.tapKey(t, 'say-same', after: const Duration(milliseconds: 2800));
        await wait(t, const Duration(milliseconds: 800));
        expect(find.byKey(const ValueKey('discovery-moment')), findsOneWidget);
        expectRewardedOnce(play);
      });

      testWidgets('path C: a wrong YES, look again, NO, ask another; wrong answers are never recorded', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'ep06_m1');
        await ask(play, t, 'baker', 'carry');
        await ask(play, t, 'juggler', 'carry');
        await openCompare(play, t);
        await play.tapKey(t, 'say-same');
        expect(verdict(d.lookAgainLine), findsOneWidget);
        expect(t.widget<GameButton>(no).onPressed, isNotNull, reason: 'the same page, to say again');
        expect(story('baker.carry'), findsOneWidget);
        await shot(t, 'case06_m1_w24_${tag}_wrong_yes');
        await play.tapKey(t, 'say-different');
        expect(verdict(d.differentLine), findsOneWidget);
        await play.tapKey(t, 'ask-another-witness', after: const Duration(milliseconds: 600));
        expect(next(d.differentLine), findsOneWidget);
        expect(play.ref.read(gameControllerProvider).attempts['ep06_m1'] ?? 0, 0);
        expect(play.ref.read(gameControllerProvider).wrongCount('ep06_m1'), 0);

        // A matching pair called different: look again too.
        await ask(play, t, 'flowerSeller', 'carry');
        await openCompare(play, t);
        await play.tapKey(t, 'pick-flowerSeller');
        await play.tapKey(t, 'pick-juggler');
        await play.tapKey(t, 'say-different');
        expect(verdict(d.lookAgainLine), findsOneWidget);
        expect(done(play), isFalse);
        // Changing who is compared: the third choice takes the first's place.
        await play.tapKey(t, 'pick-baker');
        expect(story('flowerSeller.carry'), findsNothing);
        expect(story('baker.carry'), findsOneWidget);
        expect(feedback, findsNothing, reason: 'a new pair, a new look');
        final noAt3 = t.getRect(no), backAt3 = t.getRect(back);
        await play.tapKey(t, 'say-different');
        expect(verdict(d.otherPairLine), findsOneWidget);
        expect(marked('DIFFERENT STORIES', sheet: true), findsOneWidget);
        // Everyone heard: the way on is another pair, here; back stays too.
        expect(yes, findsNothing, reason: 'CHOOSE ANOTHER PAIR in their place');
        expect(t.widget<GameButton>(anotherPair).style, GameButtonStyle.navy);
        expect(t.widget<GameButton>(back).style, GameButtonStyle.outline);
        expect(askAnother, findsNothing, reason: 'no one is left to ask');
        expect(t.getRect(anotherPair), noAt3, reason: 'where NO was');
        expect(t.getRect(back), backAt3, reason: 'the way back does not move');
        await shot(t, 'case06_m1_w24_${tag}_another_pair');
        await play.tapKey(t, 'choose-another-pair');
        expect(story('baker.carry'), findsNothing, reason: 'the choice cleared, none chosen for the detective');
        expect(story('juggler.carry'), findsNothing);
        expect(find.bySemanticsLabel(RegExp('chosen')), findsNothing);
        expect(t.widget<GameButton>(yes).onPressed, isNull, reason: 'two to choose first');
        expect(feedback, findsNothing);
        await play.tapKey(t, 'pick-baker');
        await play.tapKey(t, 'pick-flowerSeller');
        expect(t.widget<GameButton>(yes).onPressed, isNotNull);
        // The system back closes it too, keeping everything.
        await t.binding.handlePopRoute();
        await wait(t, const Duration(milliseconds: 600));
        expect(find.byKey(const ValueKey('compare-pair')), findsNothing);
        expect(find.byKey(const ValueKey('found-baker')), findsOneWidget);
        expect(play.ref.read(gameControllerProvider).attempts['ep06_m1'] ?? 0, 0);
      });

      testWidgets('path D: other questions first, any order; the statements kept; then solved', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'ep06_m1');
        await ask(play, t, 'juggler', 'wearing');
        expect(says('He had a grey hat.'), findsOneWidget);
        expect(fresh, findsOneWidget);
        await ask(play, t, 'juggler', 'when');
        await ask(play, t, 'baker', 'wearing');
        expect(compare, findsNothing);
        expect(mark, findsNothing, reason: 'nothing about what he carried yet');
        await ask(play, t, 'baker', 'carry');
        expect(compare, findsNothing, reason: 'one witness on what he carried');
        expect(next(d.foundLine), findsOneWidget);

        await play.tapKey(t, 'open-statements', after: const Duration(milliseconds: 500));
        final sheet = find.byKey(const ValueKey('statements-sheet'));
        expect(find.descendant(of: sheet, matching: findReadable('"He had a grey hat."')), findsOneWidget);
        expect(find.descendant(of: sheet, matching: find.text('3 / 6')), findsOneWidget);
        await tapText(t, 'BACK TO THE WITNESSES', after: const Duration(milliseconds: 500));

        await ask(play, t, 'flowerSeller', 'carry');
        await ask(play, t, 'juggler', 'carry');
        await openCompare(play, t);
        expect(find.byKey(const ValueKey('pick-juggler')), findsOneWidget);
        expect(find.byKey(const ValueKey('story-juggler.wearing')), findsNothing, reason: 'only what was carried');
        await play.tapKey(t, 'pick-juggler');
        await play.tapKey(t, 'pick-flowerSeller');
        await play.tapKey(t, 'say-same', after: const Duration(milliseconds: 2800));
        await wait(t, const Duration(milliseconds: 800));
        expect(find.byKey(const ValueKey('discovery-moment')), findsOneWidget);
        expectRewardedOnce(play);
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
        expect(next(d.foundLine), findsOneWidget);

        await play.restart(t);
        play.ref.read(routerProvider).go(Routes.mission('ep06_m1'));
        await wait(t, const Duration(milliseconds: 1400));
        expect(find.text('YOUR MISSION'), findsOneWidget);
        expect(done(play), isFalse);
      });

      testWidgets('layout: the portrait leads; a long answer reads; questions, compare and its buttons fit', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'ep06_m1');
        await ask(play, t, 'baker', 'carry');
        final screen = Offset.zero & size;
        bool inside(Rect r) => screen.contains(r.topLeft) && screen.contains(r.bottomRight - const Offset(1, 1));
        expect(t.getRect(find.byKey(const ValueKey('talk-panel'))).width, size.width);
        final portrait = t.getRect(find.byKey(const ValueKey('talk-portrait')));
        expect(inside(portrait), isTrue);
        expect(portrait.width / portrait.height, closeTo(ArtAssets.witnessPortraitAspect, 0.02));
        final least = {360.0: 140.0, 390.0: 190.0, 412.0: 210.0}[size.width]!;
        expect(portrait.height, greaterThanOrEqualTo(least), reason: 'portrait ${portrait.size}');
        final card = t.getRect(speech);
        final answer = t.getRect(find.descendant(of: speech, matching: findReadableContaining('He had a big red umbrella.')));
        expect(answer.bottom, lessThanOrEqualTo(card.bottom), reason: 'the answer reads without scrolling');
        expect(inside(t.getRect(find.byKey(const ValueKey('question-carry')))), isTrue);
        expect(inside(t.getRect(next(d.foundLine))), isTrue);
        await play.tapKey(t, 'other-questions');
        for (final q in talk.questions) {
          expect(t.getRect(find.byKey(ValueKey('question-${q.id}'))).height, greaterThanOrEqualTo(48), reason: q.text);
        }
        await shot(t, 'case06_m1_w24_${tag}_layout');

        await ask(play, t, 'juggler', 'carry');
        expect(inside(t.getRect(compare)), isTrue, reason: 'COMPARE in sight, others open or not');
        await ask(play, t, 'flowerSeller', 'carry');
        await openCompare(play, t);
        await play.tapKey(t, 'pick-baker');
        await play.tapKey(t, 'pick-flowerSeller');
        for (final b in [yes, no, back]) {
          final r = t.getRect(b);
          expect(inside(r), isTrue);
          expect(r.height, greaterThanOrEqualTo(48));
        }
        for (final s in ['baker.carry', 'flowerSeller.carry']) {
          expect(inside(t.getRect(story(s))), isTrue, reason: s);
        }
        expect(t.takeException(), isNull);
      });
    });
  }

  // Wave 2.4 — one small arrow at the next place to act, never at a witness
  // or an answer, never in the way.
  final arrow = find.byKey(const ValueKey('guide-arrow'));
  /// COMPARE with its gold ring when it has just come in.
  Finder compareBox() {
    final ring = find.byKey(const ValueKey('compare-ready'));
    return ring.evaluate().isNotEmpty ? ring : compare;
  }

  Future<void> rest(WidgetTester t) => wait(t, const Duration(milliseconds: 3400));

  /// The arrow at rest just above [target], at [along] (-1..1) of its width.
  /// With [span], over a bracket along the whole target (none favoured).
  final bracket = find.byKey(const ValueKey('guide-bracket'));
  final lineupRow = find.ancestor(of: find.byKey(const ValueKey('lineup-juggler')), matching: find.byType(GuideTarget));
  void pointsDown(WidgetTester t, Finder target, {double along = 0, bool span = false}) {
    expect(arrow, findsOneWidget);
    final a = t.getRect(arrow), r = t.getRect(target);
    const g = GuidedActionIndicator.gap;
    final off = span ? GuidedActionIndicator.bracket + g : 0;
    expect(a.bottom, closeTo(r.top - g - off, 1.5), reason: 'just above $r: $a');
    expect(a.center.dx, closeTo(r.left + r.width * (along + 1) / 2, 1.5));
    if (span) {
      final b = t.getRect(bracket);
      expect(b.width, closeTo(r.width, 1.5), reason: 'along the whole row');
      expect(b.bottom, closeTo(r.top - g, 1.5));
    } else {
      expect(bracket, findsNothing);
    }
  }

  /// The arrow at rest just left of [target], level with its middle.
  void pointsRight(WidgetTester t, Finder target) {
    expect(arrow, findsOneWidget);
    final a = t.getRect(arrow), r = t.getRect(target);
    expect(a.right, closeTo(r.left - GuidedActionIndicator.gap, 1.5), reason: 'left of $r: $a');
    expect(a.center.dy, closeTo(r.center.dy, 1.5));
    expect(a.left, greaterThanOrEqualTo(0), reason: 'on screen');
  }

  /// Another witness is next: every witness in [open] (not asked yet) is
  /// marked alike — a small still arrow over their face — and no one else;
  /// no moving arrow anywhere.
  void invited(WidgetTester t, Set<String> open) {
    expect(arrow, findsNothing, reason: 'no single arrow choosing for the detective');
    Rect? first;
    for (final w in talk.speakers) {
      final mark = find.byKey(ValueKey('invite-${w.id}'));
      if (!open.contains(w.id)) {
        expect(mark, findsNothing, reason: '${w.id} was asked: not pointed at');
        continue;
      }
      expect(mark, findsOneWidget, reason: w.id);
      final m = t.getRect(mark), face = t.getRect(find.byKey(ValueKey('speaker-${w.id}')));
      expect(m.center.dx, closeTo(face.center.dx, 1.5), reason: 'over ${w.id}\'s face');
      expect(m.bottom, lessThanOrEqualTo(face.top + AppSpace.xs), reason: 'above the face, not on it');
      expect(m.top, greaterThan(t.getRect(find.byKey(const ValueKey('talk-next'))).bottom), reason: 'under the line, not on it');
      if (first != null) expect(m.size, first.size, reason: 'alike');
      first = m;
      expect(find.descendant(of: mark, matching: find.byWidgetPredicate((x) => x is IgnorePointer && x.ignoring)), findsWidgets);
    }
  }

  void clearOf(WidgetTester t, List<Finder> things) {
    final a = t.getRect(arrow);
    for (final f in things) {
      for (final e in f.evaluate()) {
        final r = t.getRect(find.byElementPredicate((x) => x == e));
        expect(a.overlaps(r), isFalse, reason: 'the arrow covers $f');
      }
    }
  }

  for (final size in const [Size(360, 640), Size(390, 844), Size(412, 915)]) {
    final tag = '${size.width.toInt()}x${size.height.toInt()}';

    group('the guide arrow at $tag', () {
      testWidgets('path B: the people, the question, another witness, COMPARE, ASK ANOTHER WITNESS, two to choose, YES', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'ep06_m1');
        await rest(t);
        // 1. The whole row of people (its middle: not one of them chosen for
        // you), right over the prints themselves.
        pointsDown(t, lineupRow, span: true);
        final prints = [for (final w in talk.speakers) t.getRect(find.byKey(ValueKey('lineup-${w.id}')))];
        expect(t.getRect(bracket).bottom, closeTo(prints.first.top - GuidedActionIndicator.gap, 4), reason: '$prints');
        final picture = t.getRect(find.descendant(of: find.byKey(const ValueKey('lineup-juggler')), matching: find.byType(PaperSheet)));
        expect(picture.top - t.getRect(bracket).bottom, lessThan(8), reason: 'over the pictures, not empty space above');
        clearOf(t, [findReadable(talk.how)]);
        expect(find.ancestor(of: arrow, matching: find.byWidgetPredicate((w) => w is IgnorePointer && w.ignoring)),
            findsWidgets, reason: 'never takes a touch');
        await shot(t, 'case06_m1_w24_${tag}_g1_lineup');

        // 2. The mission's question, between the faces above it.
        await play.tapKey(t, 'lineup-flowerSeller');
        await rest(t);
        final carry = find.byKey(const ValueKey('question-carry'));
        pointsDown(t, carry, along: -0.28);
        clearOf(t, [find.text('flower seller'), find.text('juggler'), find.text('baker'), carry]);
        await shot(t, 'case06_m1_w24_${tag}_g2_question');
        // A tap right under its point is the question's.
        final a = t.getRect(arrow);
        await t.tapAt(Offset(a.center.dx, t.getRect(carry).top + 6));
        await wait(t, const Duration(milliseconds: 400));
        expect(fresh, findsOneWidget, reason: 'asked through the arrow');

        // 3. Another witness: the juggler and the baker, marked alike.
        await rest(t);
        invited(t, {'juggler', 'baker'});
        // The marks never take a touch: a tap just under one is that witness.
        await t.tapAt(t.getRect(find.byKey(const ValueKey('invite-baker'))).bottomCenter + const Offset(0, 6));
        await wait(t, const Duration(milliseconds: 400));
        expect(find.text('THE BAKER'), findsOneWidget);
        await play.tapKey(t, 'speaker-flowerSeller');
        invited(t, {'juggler', 'baker'});
        await shot(t, 'case06_m1_w24_${tag}_g3_another');

        await ask(play, t, 'baker', 'carry');
        // 4. COMPARE STORIES.
        await rest(t);
        pointsDown(t, compareBox());
        clearOf(t, [find.byKey(const ValueKey('talk-next'))]);
        await shot(t, 'case06_m1_w24_${tag}_g4_compare');

        // 5. Saying YES or NO: nothing pointed at (the detective's to decide).
        await openCompare(play, t);
        await rest(t);
        expect(arrow, findsNothing);
        expect(find.byKey(const ValueKey('compare-witnesses')), findsNothing, reason: 'two stories: no one to choose');

        // 6. Rightly different, one witness left: ASK ANOTHER WITNESS.
        await play.tapKey(t, 'say-different');
        await rest(t);
        pointsRight(t, askAnother);
        await shot(t, 'case06_m1_w24_${tag}_g6_ask_another');
        await play.tapKey(t, 'ask-another-witness', after: const Duration(milliseconds: 600));
        // Back at the talk: another witness again — the one not asked yet.
        await rest(t);
        invited(t, {'juggler'});

        await ask(play, t, 'juggler', 'carry');
        await rest(t);
        pointsDown(t, compareBox());
        // 7. Three stories: the whole row of witnesses to choose two from.
        await openCompare(play, t);
        await rest(t);
        final witnesses = find.byKey(const ValueKey('compare-witnesses'));
        pointsDown(t, witnesses, span: true);
        clearOf(t, [find.byKey(const ValueKey('compare-choose'))]);
        await shot(t, 'case06_m1_w24_${tag}_g7_choose_two');
        await play.tapKey(t, 'pick-juggler');
        expect(arrow, findsOneWidget, reason: 'one more to choose');
        await play.tapKey(t, 'pick-baker');
        expect(arrow, findsNothing, reason: 'two chosen: saying is the detective\'s');

        // 8. Rightly different, everyone heard: CHOOSE ANOTHER PAIR.
        await play.tapKey(t, 'say-different');
        await rest(t);
        pointsRight(t, anotherPair);
        await shot(t, 'case06_m1_w24_${tag}_g8_another_pair');
        await play.tapKey(t, 'choose-another-pair');
        await rest(t);
        pointsDown(t, witnesses, span: true);
        await play.tapKey(t, 'pick-flowerSeller');
        await play.tapKey(t, 'pick-juggler');
        await play.tapKey(t, 'say-same', after: const Duration(milliseconds: 2800));
        await wait(t, const Duration(milliseconds: 800));
        expect(find.byKey(const ValueKey('discovery-moment')), findsOneWidget);
        expectRewardedOnce(play);
      });
    });
  }

  group('the guide arrow moves gently, then rests', () {
    testWidgets('nods a few times on a new step, then rests; the same step never nods again; ignoring it is fine', (t) async {
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(390, 844), 'ep06_m1');
      await play.tapKey(t, 'lineup-baker', after: const Duration(milliseconds: 100));
      final ys = <double>[];
      for (var i = 0; i < 12; i++) {
        await t.pump(const Duration(milliseconds: 100));
        ys.add(t.getRect(arrow).top);
      }
      final travel = ys.reduce(math.max) - ys.reduce(math.min);
      expect(travel, inInclusiveRange(GuidedActionIndicator.nod - 2.5, GuidedActionIndicator.nod + 0.5), reason: '$ys');
      await rest(t);
      final still = t.getRect(arrow);
      await wait(t, const Duration(milliseconds: 1500));
      expect(t.getRect(arrow), still, reason: 'at rest');

      // The same step: another question asked first, the arrow stays put.
      await play.tapKey(t, 'other-questions');
      await play.tapKey(t, 'question-wearing', after: const Duration(milliseconds: 100));
      final x = t.getRect(arrow);
      await t.pump(const Duration(milliseconds: 300));
      expect(t.getRect(arrow).top, closeTo(x.top, 0.01), reason: 'no new nod for the same step');
      pointsDown(t, find.byKey(const ValueKey('question-carry')), along: -0.28);
      // Another witness instead of the question: allowed, the arrow follows.
      await play.tapKey(t, 'speaker-juggler');
      expect(find.text('THE JUGGLER'), findsOneWidget);
      await rest(t);
      pointsDown(t, find.byKey(const ValueKey('question-carry')), along: -0.28);
      expect(t.takeException(), isNull);
    });

    testWidgets('reduced motion: the arrow simply shows, still', (t) async {
      t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(390, 844), 'ep06_m1');
      expect(arrow, findsOneWidget);
      final at = t.getRect(arrow);
      for (var i = 0; i < 6; i++) {
        await t.pump(const Duration(milliseconds: 150));
        expect(t.getRect(arrow), at);
      }
      pointsDown(t, lineupRow, span: true);
      await ask(play, t, 'flowerSeller', 'carry');
      invited(t, {'juggler', 'baker'});
    });

    for (final (first, open) in const [
      ('flowerSeller', {'juggler', 'baker'}),
      ('juggler', {'flowerSeller', 'baker'}),
      ('baker', {'flowerSeller', 'juggler'}),
    ]) {
      testWidgets('$first first: the two not asked are marked alike; $first is not', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, const Size(390, 844), 'ep06_m1');
        await ask(play, t, first, 'carry');
        await rest(t);
        invited(t, open);
        // The marks cover no name and no face.
        for (final id in open) {
          final m = t.getRect(find.byKey(ValueKey('invite-$id')));
          for (final w in talk.speakers) {
            expect(m.overlaps(t.getRect(find.text(w.name.replaceFirst('The ', '')))), isFalse);
          }
        }
        await shot(t, 'case06_m1_w241_390x844_${first}_first');
        // Ignoring the marks is fine: another question to the same witness.
        await play.tapKey(t, 'other-questions');
        await play.tapKey(t, 'question-wearing');
        invited(t, open);
        // A marked witness, asked: comparing is next, and the marks are gone.
        await ask(play, t, open.first, 'carry');
        for (final w in talk.speakers) {
          expect(find.byKey(ValueKey('invite-${w.id}')), findsNothing);
        }
        await rest(t);
        pointsDown(t, compareBox());
      });
    }

    testWidgets('text 1.3× at 360×640: each arrow beside its target, on screen', (t) async {
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(360, 640), 'ep06_m1', textScale: 1.3);
      await rest(t);
      final screen = Offset.zero & const Size(360, 640);
      void onScreen() {
        final a = t.getRect(arrow);
        expect(screen.contains(a.topLeft) && screen.contains(a.bottomRight - const Offset(1, 1)), isTrue, reason: '$a');
      }

      pointsDown(t, lineupRow, span: true);
      onScreen();
      await play.tapKey(t, 'lineup-flowerSeller');
      await rest(t);
      pointsDown(t, find.byKey(const ValueKey('question-carry')), along: -0.28);
      onScreen();
      await play.tapKey(t, 'question-carry');
      await rest(t);
      invited(t, {'juggler', 'baker'});
      await ask(play, t, 'baker', 'carry');
      await rest(t);
      pointsDown(t, compareBox());
      onScreen();
      await shot(t, 'case06_m1_w24_360x640_text13_g4_compare');
      await openCompare(play, t);
      await play.tapKey(t, 'say-different');
      await rest(t);
      pointsRight(t, askAnother);
      onScreen();
      await shot(t, 'case06_m1_w24_360x640_text13_g6_ask_another');
      expect(t.takeException(), isNull);
    });
  });

  group('larger text and still motion', () {
    testWidgets('text 1.3× at 360×640: arriving, talk, comparing and its buttons fit', (t) async {
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(360, 640), 'ep06_m1', textScale: 1.3);
      await wait(t, const Duration(milliseconds: 1800));
      expect(findReadable(talk.goal), findsOneWidget);
      expect(find.byKey(const ValueKey('lineup-baker')), findsOneWidget);
      await shot(t, 'case06_m1_w24_360x640_text13_arrival');
      await ask(play, t, 'flowerSeller', 'carry');
      expect(t.renderObject<RenderParagraph>(find.text('MARKET HALL')).didExceedMaxLines, isFalse);
      final card = t.getRect(speech);
      final answer = t.getRect(find.descendant(of: speech, matching: findReadableContaining('He carried a small bag.')));
      expect(answer.bottom, lessThanOrEqualTo(card.bottom));
      await ask(play, t, 'baker', 'carry');
      await shot(t, 'case06_m1_w24_360x640_text13');
      await openCompare(play, t);
      final screen = Offset.zero & const Size(360, 640);
      for (final b in [yes, no, back]) {
        expect(screen.contains(t.getRect(b).bottomCenter - const Offset(0, 1)), isTrue);
      }
      await shot(t, 'case06_m1_w24_360x640_text13_compare');
      await play.tapKey(t, 'say-different');
      await play.tapKey(t, 'ask-another-witness', after: const Duration(milliseconds: 600));
      await ask(play, t, 'juggler', 'carry');
      await openCompare(play, t);
      await play.tapKey(t, 'pick-flowerSeller');
      await play.tapKey(t, 'pick-juggler');
      await shot(t, 'case06_m1_w24_360x640_text13_compare_three');
      await play.tapKey(t, 'say-same', after: const Duration(milliseconds: 2800));
      expect(find.byKey(const ValueKey('discovery-moment')), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('a long answer at 1.3× still reads in its card (the baker, 360×640)', (t) async {
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(360, 640), 'ep06_m1', textScale: 1.3);
      await ask(play, t, 'juggler', 'when');
      await shot(t, 'case06_m1_w24_360x640_text13_long');
      final card = t.getRect(speech);
      final answer =
          t.getRect(find.descendant(of: speech, matching: findReadableContaining('The church clock was nearly at twelve.')));
      expect(answer.bottom, lessThanOrEqualTo(card.bottom + 0.5));
      expect(t.takeException(), isNull);
    });

    testWidgets('reduced motion: the mission and prints show at once; COMPARE is marked in gold without the glow', (t) async {
      t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(390, 844), 'ep06_m1');
      expect(find.text('YOUR MISSION'), findsOneWidget);
      expect(
        t.widget<AnimatedOpacity>(
          find.ancestor(of: find.byKey(const ValueKey('talk-lineup')), matching: find.byType(AnimatedOpacity)).first,
        ).opacity,
        1,
      );
      await ask(play, t, 'flowerSeller', 'carry');
      await ask(play, t, 'juggler', 'carry');
      expect(t.widget<TweenAnimationBuilder<double>>(find.byKey(const ValueKey('compare-ready'))).tween.begin, 1);
    });
  });
}
