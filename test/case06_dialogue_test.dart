import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/core/theme/app_colors.dart';
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

import 'full_playthrough_test.dart' show reveal, tapText, wait;
import 'helpers.dart' show findReadable, findReadableContaining, takeTipFromSheet;
import 'mission_play.dart';
import 'title_screen_test.dart' show capture;

/// Wave 2 – 2.5 — Case 06 M1 (the Market Hall) is played by talking to its
/// three witnesses. The mission is said first (find out what the stranger
/// carried); the detective asks whom they like, what they like; the
/// statements heard are written down; two of them, chosen by the detective
/// and said to match, answer the mission's puzzle (`b`) — and before it
/// ends, what he wore is still to be found if it was not heard (the next
/// mission asks the colour of his hat). Its Clue, Evidence, XP, coins and
/// save are the ones it always gave.
///
/// Wave 2.5 changed what earlier tests checked, on purpose (a playtest: the
/// arrows meant nothing, the dotted words looked like clues, comparing was
/// unclear, the grey hat could be missed): no guide arrows — every step is
/// said in words and every choice says what it does (TALK, SPOKEN TO,
/// COMPARE TWO STATEMENTS); the three questions are alike again (the one
/// about what he carried is not marked out or put first); comparing lists
/// every statement heard, about anything, and the detective chooses two
/// (two coats match too, but he wore them); after the deduction, what he wore
/// must be heard; no word in the talk is dotted (WORDS lists them); the
/// Notebook's Witness Notes show what the witnesses said, and where.
///
/// Wave 2.5.1: no YES / NO — choosing the second statement is judged at once
/// (what the two show; the answer never named); the three TALK tags glow
/// alike until a witness is chosen; the chosen print flies to the talk.
///
/// Wave 2.5.2: two that match but not about what he carried are a GOOD
/// MATCH first (never shown as an error), then the mission recalled; the
/// verdict sits under the two cards; the words come after the portrait
/// lands; everything found is DESCRIPTION RECORDED, and the mission ends on
/// CONTINUE (no longer by itself).
void main() {
  final season = MockEpisodeRepository.bundled();
  final c06 = season.firstWhere((e) => e.id == 'ep06');
  final m1 = c06.missionById('ep06_m1')!;
  final m2 = c06.missionById('ep06_m2')!;
  final talk = dialogueOf(m1)!;
  final d = talk.deduction;

  group('the talk data (the approved script)', () {
    test('only Case 06 M1 is talked through; the deduction gives its own answer', () {
      expect(season1Dialogues.keys, ['ep06_m1']);
      expect(d.answer, m1.answer);
      expect(m1.answer, 'b');
      expect(m1.answerLabel, 'A small bag');
      expect(talk.place, 'MARKET HALL');
    });

    test('what to do is said, never which answer', () {
      expect(talk.goal, 'Find out what the stranger carried.');
      expect(talk.how, 'Ask what they saw. You may find different clues.');
      expect(talk.guide, 'Talk to a witness.');
      final lines = [
        talk.goal, talk.how, talk.guide, d.askLine, d.anotherLine, d.readyLine, d.compareGoal, d.compareHow, //
        d.matchLine, d.offTopicLine, d.checkLine, d.differentLine, d.retryLine, d.thenGoal, d.thenHow, d.doneLine, //
        d.notesLine,
      ];
      for (final line in lines) {
        for (final word in ['bag', 'grey', 'hat', 'umbrella', 'coat', 'juggler', 'flower', 'baker']) {
          expect(RegExp('\\b$word\\b').hasMatch(line.toLowerCase()), isFalse, reason: '"$line" names "$word"');
        }
      }
      expect(d.thenGoal, 'Find out what the stranger was wearing.');
      expect(d.thenHow, "Ask the witnesses about the stranger's clothes.");
    });

    test('three witnesses of the case; the same three questions, alike; answers word for word', () {
      expect(talk.speakers.map((s) => s.name), ['The flower seller', 'The juggler', 'The baker']);
      for (final s in talk.speakers) {
        expect(m1.letter.toLowerCase(), contains(s.name.toLowerCase()), reason: 'a witness of the case: ${s.name}');
      }
      expect(talk.questions.map((q) => q.text), ['What was he wearing?', 'What did he carry?', 'When did you see him?']);
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

    test('six statements, each what a witness said and the thing it describes; "when" is never one', () {
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
          expect(e.value.line.toLowerCase(), contains(talk.statement(id).thing.replaceFirst('a ', '')));
        }
      }
      for (final words in ['dark coat', 'small bag', 'grey hat', 'big red umbrella']) {
        expect(m1.letter, contains(words));
      }
    });

    test("the juggler's grey hat must be heard before the mission ends: Mission 02's card asks for it", () {
      expect(d.then, {'juggler.wearing'});
      expect(talk.statement('juggler.wearing').text, 'He had a grey hat.');
      expect(m1.evidence!.inscription, contains('grey hat'));
      expect(m2.letter, contains('It is the colour of my hat,'));
      expect(m2.answer, 'GREY');
      expect(learningOf(m2)!.recallFrom, 'ep06_m1');
      expect(learningOf(m1)!.expressions, ['He carried a small bag', 'Two witnesses agree']);
      expect(talk.described(['flowerSeller.carry', 'juggler.carry']), isFalse);
      expect(talk.described(['juggler.wearing']), isTrue);
    });

    test('comparing opens at statements from two witnesses — about anything — and never from one', () {
      expect(talk.canCompare(['flowerSeller.wearing', 'flowerSeller.carry']), isFalse, reason: 'one witness');
      expect(talk.canCompare(['flowerSeller.wearing', 'baker.wearing']), isTrue, reason: 'two coats: compare them');
      expect(talk.canCompare(['juggler.wearing', 'baker.carry']), isTrue);
      expect(talk.canCompare(['flowerSeller.carry', 'juggler.carry']), isTrue);
    });

    test('two statements match when they describe the same thing; only the two bags answer it', () {
      final ids = talk.statements.map((s) => s.id).toList();
      final matching = <Set<String>>[];
      for (var i = 0; i < ids.length; i++) {
        for (var j = i + 1; j < ids.length; j++) {
          if (talk.matches(ids[i], ids[j])) matching.add({ids[i], ids[j]});
          if (d.solves(ids[i], ids[j])) expect({ids[i], ids[j]}, d.pair);
        }
      }
      expect(matching, unorderedEquals([
        {'flowerSeller.carry', 'juggler.carry'},
        {'flowerSeller.wearing', 'baker.wearing'},
      ]));
      expect(d.solves('juggler.carry', 'flowerSeller.carry'), isTrue);
      expect(d.solves('flowerSeller.wearing', 'baker.wearing'), isFalse, reason: 'they match, but he wore them');
    });

    test('a statement is written down once, however often it is heard', () {
      final p = DialogueProgress()..talkTo('flowerSeller');
      p.ask(talk, 'carry');
      expect(p.fresh, 'flowerSeller.carry');
      p.ask(talk, 'carry');
      expect(p.fresh, isNull);
      p.ask(talk, 'when');
      expect(p.heard, ['flowerSeller.carry']);
    });

    test('the notebook keeps what a solved talk is sure to have heard', () {
      expect(talk.recorded().map((s) => s.id), ['flowerSeller.carry', 'juggler.wearing', 'juggler.carry']);
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
  final recorded = find.byKey(const ValueKey('new-statement'));
  final compare = find.byKey(const ValueKey('compare-statements'));
  final feedback = find.byKey(const ValueKey('compare-feedback'));
  final back = find.byKey(const ValueKey('back-to-witnesses'));
  final yesNo = find.byWidgetPredicate(
    (w) => w.key == const ValueKey('say-same') || w.key == const ValueKey('say-different'),
  );
  final anotherPair = find.byKey(const ValueKey('choose-another-pair'));
  final mark = find.byKey(const ValueKey('talk-mark'));
  final next = find.byKey(const ValueKey('talk-next'));
  Finder dotted() => find.bySemanticsLabel(RegExp('tap for meaning'));
  Finder marked(String words) => find.descendant(of: mark, matching: find.text(words), matchRoot: true);
  Finder line(String words) => find.descendant(of: next, matching: find.text(words), matchRoot: true);
  Finder verdict(String words) => find.descendant(of: feedback, matching: find.text(words));

  /// No line of what two chosen show is inked as an error.
  void noErrorInk(WidgetTester t) {
    for (final e in find.descendant(of: feedback, matching: find.byType(Text)).evaluate()) {
      expect((e.widget as Text).style?.color, isNot(AppColors.tryAgain), reason: (e.widget as Text).data);
    }
  }
  final cont = find.byKey(const ValueKey('continue-investigation'));
  Finder story(String id) => find.byKey(ValueKey('story-$id'));
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
  /// and asks [question].
  Future<void> ask(MissionPlay play, WidgetTester t, String who, String question) async {
    final print = find.byKey(ValueKey('lineup-$who'));
    // From a print, the portrait flies in first and the questions follow it.
    final arriving = print.evaluate().isNotEmpty;
    await play.tapKey(
      t,
      arriving ? 'lineup-$who' : 'speaker-$who',
      after: Duration(milliseconds: arriving ? 900 : 400),
    );
    await play.tapKey(t, 'question-$question');
  }

  Future<void> openCompare(MissionPlay play, WidgetTester t) =>
      play.tapKey(t, 'compare-statements', after: const Duration(milliseconds: 600));

  /// Chooses two statements; the second is judged a moment later.
  Future<void> pickTwo(MissionPlay play, WidgetTester t, String a, String b) async {
    await play.tapKey(t, 'pick-$a');
    await play.tapKey(t, 'pick-$b', after: const Duration(milliseconds: 200));
  }

  /// The verdict on two chosen (it comes after a moment, and holds a moment).
  Future<void> judged(WidgetTester t) => wait(t, const Duration(milliseconds: 900));

  void expectRewardedOnce(MissionPlay play) {
    final progress = play.ref.read(gameControllerProvider);
    expect(progress.isCompleted('ep06_m1'), isTrue);
    expect(progress.attempts['ep06_m1'], 1, reason: 'answered once');
    expect(progress.wrongCount('ep06_m1'), 0, reason: 'a wrong yes / no is never recorded');
    expect(progress.collectedEvidence(c06).map((e) => e.id), contains('ep06_e1'));
    expect(progress.collectedClues(c06).map((c) => c.id), contains('ep06_c1'));
    expect(XpBreakdown.of(m1, progress).total, 30);
    expect(progress.isUnlocked(c06, 'ep06_m2'), isTrue);
    expect(play.ref.read(walletProvider).entries.where((e) => e.key == 'mission:ep06_m1'), hasLength(1));
  }

  for (final size in const [Size(360, 640), Size(390, 844), Size(412, 915)]) {
    final tag = '${size.width.toInt()}x${size.height.toInt()}';
    final screen = Offset.zero & size;
    bool inside(Rect r) => screen.contains(r.topLeft) && screen.contains(r.bottomRight - const Offset(1, 1));

    group('playing it at $tag', () {
      testWidgets('arriving: the mission, what to do, three prints each saying TALK; no arrow, no dotted word', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'ep06_m1');
        await wait(t, const Duration(milliseconds: 1800));
        expect(find.text('YOUR MISSION'), findsOneWidget);
        expect(findReadable(talk.goal), findsOneWidget);
        expect(findReadable(talk.how), findsOneWidget);
        expect(find.text(talk.guide), findsOneWidget);
        expect(find.text('TALK'), findsNWidgets(3), reason: 'every witness alike');
        for (final s in talk.speakers) {
          expect(inside(t.getRect(find.byKey(ValueKey('lineup-${s.id}')))), isTrue);
        }
        expect(find.byKey(const ValueKey('guide-arrow')), findsNothing);
        expect(find.byKey(const ValueKey('talk-faces')), findsNothing, reason: 'one way to choose when arriving');
        expect(dotted(), findsNothing, reason: 'no dotted word that looks like a clue');
        expect(find.byKey(const ValueKey('open-words')), findsOneWidget, reason: 'the words are under WORDS');
        await shot(t, 'case06_m1_w25_${tag}_1_arrival');
      });

      testWidgets('path A: two bags matched, then his clothes still to find; the grey hat ends it; Discovery once', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'ep06_m1');
        await ask(play, t, 'flowerSeller', 'carry');
        expect(says('He carried a small bag.'), findsOneWidget);
        expect(find.text('STATEMENT RECORDED'), findsOneWidget);
        expect(marked('1 STATEMENT'), findsOneWidget);
        expect(line(d.anotherLine), findsOneWidget);
        expect(find.byKey(const ValueKey('spoken-flowerSeller')), findsOneWidget);
        expect(find.byKey(const ValueKey('talk-juggler')), findsOneWidget);
        expect(find.byKey(const ValueKey('talk-baker')), findsOneWidget);
        expect(compare, findsNothing, reason: 'one witness: ask another');
        await shot(t, 'case06_m1_w25_${tag}_2_first_statement');

        await ask(play, t, 'juggler', 'carry');
        expect(compare, findsOneWidget);
        expect(find.descendant(of: compare, matching: find.text('COMPARE TWO STATEMENTS')), findsOneWidget);
        expect(line(d.readyLine), findsOneWidget);
        await openCompare(play, t);
        expect(find.text(d.compareGoal), findsOneWidget);
        expect(find.text(d.compareHow), findsOneWidget);
        expect(yesNo, findsNothing, reason: 'no YES / NO: choosing two is the deciding');
        expect(story('flowerSeller.carry'), findsNothing, reason: 'none chosen for the detective');
        expect(find.bySemanticsLabel(RegExp('chosen')), findsNothing);
        expect(find.byKey(const ValueKey('compare-pair')), findsNothing, reason: 'no empty cards before a first choice');
        await play.tapKey(t, 'pick-flowerSeller.carry');
        expect(story('flowerSeller.carry'), findsOneWidget, reason: 'the first choice shown');
        await play.tapKey(t, 'pick-juggler.carry', after: const Duration(milliseconds: 200));
        // The two, side by side, seen before what they show is said.
        final a = t.getRect(story('flowerSeller.carry')), b = t.getRect(story('juggler.carry'));
        expect(a.right, lessThanOrEqualTo(b.left), reason: 'side by side');
        expect(find.descendant(of: story('juggler.carry'), matching: findReadable('"He carried a small bag."')), findsOneWidget);
        expect(find.text('THE STORIES MATCH!'), findsNothing, reason: 'a moment to see the two first');
        await shot(t, 'case06_m1_w25_${tag}_3_compare_two');
        await play.tapKey(t, 'pick-flowerSeller.carry', after: const Duration(milliseconds: 400));
        expect(story('flowerSeller.carry'), findsOneWidget, reason: 'no tap counts while two are judged');
        expect(find.text('THE STORIES MATCH!'), findsOneWidget);
        expect(find.text(d.matchLine), findsOneWidget);
        final view = t.getRect(find.byKey(const ValueKey('compare-sheet')));
        expect(t.getRect(find.byKey(const ValueKey('compare-match'))).top, lessThan(view.bottom), reason: 'the verdict in sight');
        await shot(t, 'case06_m1_w25_${tag}_4_match');
        await wait(t, const Duration(milliseconds: 2000));
        expect(done(play), isFalse, reason: 'what he wore is still to find');

        // One more thing: what he wore — asked for, never named.
        expect(marked('ONE MORE THING'), findsOneWidget);
        expect(line(d.thenHow), findsOneWidget);
        expect(find.text(d.thenGoal), findsOneWidget, reason: 'the goal on top says it');
        expect(compare, findsNothing);
        await shot(t, 'case06_m1_w25_${tag}_5_one_more');
        await ask(play, t, 'flowerSeller', 'wearing');
        expect(says('He was wearing a dark coat.'), findsOneWidget);
        await wait(t, const Duration(milliseconds: 2000));
        expect(done(play), isFalse, reason: 'a coat, not yet the hat');
        await ask(play, t, 'juggler', 'wearing');
        expect(says('He had a grey hat.'), findsOneWidget);
        // Recorded — a find, not a deduction, and not yet the end.
        expect(marked('DESCRIPTION RECORDED'), findsOneWidget);
        expect(line(d.doneLine), findsOneWidget);
        expect(find.text(d.notesLine), findsOneWidget);
        expect(find.text('THE STORIES MATCH!'), findsNothing);
        await shot(t, 'case06_m1_w25_${tag}_6_grey_hat');
        await wait(t, const Duration(milliseconds: 3000));
        expect(done(play), isFalse, reason: 'it never ends by itself');
        expect(find.byKey(const ValueKey('talk-faces')), findsNothing, reason: 'nothing more to ask');
        // VIEW WITNESS NOTES and back: the same step.
        await play.tapKey(t, 'view-witness-notes', after: const Duration(milliseconds: 600));
        final notes = find.byKey(const ValueKey('statements-sheet'));
        expect(find.descendant(of: notes, matching: findReadable('"He had a grey hat."')), findsOneWidget);
        await tapText(t, 'BACK TO THE WITNESSES', after: const Duration(milliseconds: 600));
        expect(marked('DESCRIPTION RECORDED'), findsOneWidget);
        expect(done(play), isFalse);
        // CONTINUE, tapped twice: one answer, one Discovery.
        await reveal(t, cont);
        final at = t.getCenter(cont);
        await t.tapAt(at);
        await t.pump(const Duration(milliseconds: 30));
        await t.tapAt(at);
        await wait(t, const Duration(milliseconds: 900));
        expect(find.byKey(const ValueKey('discovery-moment')), findsOneWidget);
        expectRewardedOnce(play);
      });

      testWidgets('the grey hat heard first: no question again, the match ends it', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'ep06_m1');
        await ask(play, t, 'juggler', 'wearing');
        await ask(play, t, 'juggler', 'carry');
        await ask(play, t, 'flowerSeller', 'carry');
        await openCompare(play, t);
        await pickTwo(play, t, 'juggler.carry', 'flowerSeller.carry');
        await wait(t, const Duration(milliseconds: 3200));
        expect(marked('DESCRIPTION RECORDED'), findsOneWidget, reason: 'the same way on');
        expect(done(play), isFalse);
        await play.tapKey(t, 'continue-investigation', after: const Duration(milliseconds: 900));
        expect(find.byKey(const ValueKey('discovery-moment')), findsOneWidget);
        expectRewardedOnce(play);
      });

      testWidgets('different things, matching coats: said at once; choose again; nothing recorded', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'ep06_m1');
        await ask(play, t, 'baker', 'wearing');
        await ask(play, t, 'baker', 'carry');
        await ask(play, t, 'flowerSeller', 'wearing');
        await ask(play, t, 'flowerSeller', 'carry');
        await openCompare(play, t);
        final backAt = t.getRect(back);
        // An umbrella and a bag: different things, said at once.
        await pickTwo(play, t, 'baker.carry', 'flowerSeller.carry');
        await judged(t);
        expect(verdict('THE STORIES ARE DIFFERENT'), findsOneWidget);
        expect(verdict(d.differentLine), findsOneWidget);
        expect(verdict(d.retryLine), findsOneWidget);
        noErrorInk(t);
        expect(story('baker.carry'), findsOneWidget, reason: 'the two stay to look at');
        expect(story('flowerSeller.carry'), findsOneWidget);
        expect(anotherPair, findsOneWidget);
        expect(t.getRect(back), backAt, reason: 'the way back never moves');
        expect(yesNo, findsNothing);
        await shot(t, 'case06_m1_w25_${tag}_7_wrong');
        // Choosing again: a tap starts a new pair with that statement.
        await play.tapKey(t, 'pick-flowerSeller.wearing');
        expect(feedback, findsNothing);
        expect(story('flowerSeller.wearing'), findsOneWidget);
        expect(story('baker.carry'), findsNothing);
        // Two coats: they match — but he wore them.
        await play.tapKey(t, 'pick-baker.wearing', after: const Duration(milliseconds: 200));
        await judged(t);
        // A true find, acknowledged; then the mission, calmly.
        expect(verdict('GOOD MATCH!'), findsOneWidget);
        expect(verdict(d.offTopicLine), findsOneWidget);
        expect(verdict('BUT CHECK YOUR MISSION'), findsOneWidget);
        expect(verdict(d.checkLine), findsOneWidget);
        expect(t.widget<Text>(verdict('GOOD MATCH!')).style?.color, AppColors.success);
        noErrorInk(t);
        final fb = t.getRect(feedback), pairAt = t.getRect(find.byKey(const ValueKey('compare-pair')));
        expect(fb.top - pairAt.bottom, lessThan(16), reason: 'right under the two');
        expect(find.text('THE STORIES MATCH!'), findsNothing);
        expect(done(play), isFalse);
        await shot(t, 'case06_m1_w25_${tag}_7b_off_topic');
        await play.tapKey(t, 'choose-another-pair');
        expect(find.bySemanticsLabel(RegExp('chosen')), findsNothing, reason: 'cleared, none chosen for you');
        expect(feedback, findsNothing);
        // The same wrong pair again and again: never the answer shown.
        for (var i = 0; i < 3; i++) {
          await pickTwo(play, t, 'baker.carry', 'flowerSeller.carry');
          await judged(t);
          expect(verdict(d.differentLine), findsOneWidget);
          await play.tapKey(t, 'choose-another-pair');
        }
        expect(find.bySemanticsLabel(RegExp('chosen')), findsNothing);
        expect(done(play), isFalse);
        // BACK TO WITNESSES: everything kept; one more witness; the right pair.
        await play.tapKey(t, 'back-to-witnesses', after: const Duration(milliseconds: 600));
        expect(marked('4 STATEMENTS'), findsOneWidget);
        await ask(play, t, 'juggler', 'carry');
        await openCompare(play, t);
        await pickTwo(play, t, 'flowerSeller.carry', 'juggler.carry');
        await wait(t, const Duration(milliseconds: 3200));
        expect(marked('ONE MORE THING'), findsOneWidget);
        final progress = play.ref.read(gameControllerProvider);
        expect(progress.attempts['ep06_m1'] ?? 0, 0, reason: 'no pair that was not the answer was recorded');
        expect(progress.wrongCount('ep06_m1'), 0);
      });

      testWidgets('layout: the portrait leads; questions alike; the compare page fits with four statements', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'ep06_m1');
        await ask(play, t, 'baker', 'carry');
        expect(t.getRect(find.byKey(const ValueKey('talk-panel'))).width, size.width);
        final portrait = t.getRect(find.byKey(const ValueKey('talk-portrait')));
        expect(inside(portrait), isTrue);
        expect(portrait.width / portrait.height, closeTo(ArtAssets.witnessPortraitAspect, 0.02));
        final card = t.getRect(speech);
        final answer = t.getRect(find.descendant(of: speech, matching: findReadableContaining('He had a big red umbrella.')));
        expect(answer.bottom, lessThanOrEqualTo(card.bottom), reason: 'the answer reads without scrolling');
        for (final q in talk.questions) {
          expect(t.getRect(find.byKey(ValueKey('question-${q.id}'))).height, greaterThanOrEqualTo(48), reason: q.text);
        }
        expect(find.descendant(of: speech, matching: dotted()), findsNothing);
        await shot(t, 'case06_m1_w25_${tag}_layout');

        await ask(play, t, 'baker', 'wearing');
        await ask(play, t, 'juggler', 'carry');
        await ask(play, t, 'juggler', 'wearing');
        await openCompare(play, t);
        await pickTwo(play, t, 'baker.carry', 'juggler.wearing');
        await judged(t);
        final sheetView = t.getRect(find.byKey(const ValueKey('compare-sheet')));
        expect(t.getRect(feedback).bottom, lessThanOrEqualTo(sheetView.bottom + 0.5), reason: 'the verdict whole in sight');
        for (final b in [anotherPair, back]) {
          final r = t.getRect(b);
          expect(inside(r), isTrue);
          expect(r.height, greaterThanOrEqualTo(48));
        }
        final view = t.getRect(find.byKey(const ValueKey('compare-sheet')));
        for (final s in ['baker.carry', 'juggler.wearing']) {
          final r = t.getRect(story(s));
          expect(r.top >= view.top && r.bottom <= view.bottom + 0.5, isTrue, reason: '$s whole in sight: $r in $view');
        }
        expect(t.takeException(), isNull);
      });

      testWidgets('a tip; back to the place keeps the talk; a restart begins again', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'ep06_m1');
        await ask(play, t, 'juggler', 'carry');
        // The free hint is written on the talk panel at once (no dialog) …
        await tapText(t, 'Get a Free Hint', after: const Duration(milliseconds: 500));
        await takeTipFromSheet(t);
        expect(
          find.descendant(of: find.byKey(const ValueKey('talk-hints')), matching: find.text('DETECTIVE HINT 1')),
          findsOneWidget,
        );
        // … and kept with the statements in the notes.
        await play.tapKey(t, 'open-statements', after: const Duration(milliseconds: 600));
        expect(
          find.descendant(of: find.byKey(const ValueKey('statements-sheet')), matching: find.text('DETECTIVE HINT 1')),
          findsOneWidget,
        );
        await tapText(t, 'BACK TO THE WITNESSES', after: const Duration(milliseconds: 500));

        await t.tap(find.byTooltip('Back'));
        await wait(t, const Duration(milliseconds: 600));
        await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 600));
        expect(find.text('THE JUGGLER'), findsOneWidget);
        expect(line(d.anotherLine), findsOneWidget);

        await play.restart(t);
        play.ref.read(routerProvider).go(Routes.mission('ep06_m1'));
        await wait(t, const Duration(milliseconds: 1400));
        expect(find.text('YOUR MISSION'), findsOneWidget);
        expect(done(play), isFalse);
      });
    });
  }

  for (final first in ['flowerSeller', 'juggler', 'baker']) {
    testWidgets('$first first, a question about clothes first: it goes on; spoken to and not, told apart', (t) async {
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(390, 844), 'ep06_m1');
      await play.tapKey(t, 'lineup-$first', after: const Duration(milliseconds: 900));
      expect(line(d.askLine), findsOneWidget);
      // The questions alike: same look, none marked out.
      final looks = {
        for (final q in talk.questions)
          (t.widget<Material>(find.descendant(of: find.byKey(ValueKey('question-${q.id}')), matching: find.byType(Material)).first)
                  .shape as RoundedRectangleBorder)
              .side,
      };
      expect(looks, hasLength(1), reason: 'no question looks like the one');
      await play.tapKey(t, 'question-wearing');
      expect(recorded, findsOneWidget, reason: 'every statement recorded alike');
      for (final w in talk.speakers) {
        expect(find.byKey(ValueKey('${w.id == first ? 'spoken' : 'talk'}-${w.id}')), findsOneWidget, reason: w.id);
      }
      await shot(t, 'case06_m1_w25_390x844_${first}_first');
      final other = talk.speakers.firstWhere((w) => w.id != first).id;
      await ask(play, t, other, 'carry');
      expect(compare, findsOneWidget, reason: 'two witnesses: compare what they said');
    });
  }

  group('arriving: TALK, and the portrait flying to the talk', () {
    final tags = find.byKey(const ValueKey('talk-tag'));
    List<BoxDecoration> looks(WidgetTester t) =>
        [for (final e in tags.evaluate()) (e.widget as Container).decoration! as BoxDecoration];
    final flight = find.byKey(const ValueKey('portrait-flight'));
    double portraitOpacity(WidgetTester t) =>
        t.widget<Opacity>(find.ancestor(of: find.byKey(const ValueKey('talk-portrait')), matching: find.byType(Opacity)).first).opacity;

    testWidgets('the three TALK tags glow alike, softly, without moving; the glow ends once a witness is chosen', (t) async {
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(390, 844), 'ep06_m1');
      await wait(t, const Duration(milliseconds: 1800));
      expect(tags, findsNWidgets(3));
      final rects = [for (final e in tags.evaluate()) t.getRect(find.byElementPredicate((x) => x == e))];
      final borders = <Color>{};
      for (var i = 0; i < 10; i++) {
        final now = looks(t);
        expect({for (final l in now) l.border}, hasLength(1), reason: 'all three alike at every moment');
        borders.add((now.first.border! as Border).top.color);
        await t.pump(const Duration(milliseconds: 200));
      }
      expect(borders.length, greaterThan(3), reason: 'it glows (about 2 s a round)');
      expect([for (final e in tags.evaluate()) t.getRect(find.byElementPredicate((x) => x == e))], rects,
          reason: 'never moves or grows');
      expect(t.getRect(find.byKey(const ValueKey('lineup-baker'))).height, greaterThanOrEqualTo(48));
      await play.tapKey(t, 'lineup-baker', after: const Duration(milliseconds: 700));
      expect(tags, findsNothing, reason: 'the glow ends with the arrival');
      expect(t.takeException(), isNull);
    });

    testWidgets("the chosen print flies to the talk's portrait; the portrait waits unseen, then shows", (t) async {
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(390, 844), 'ep06_m1');
      await wait(t, const Duration(milliseconds: 1800));
      final start = t.getRect(find.byKey(const ValueKey('lineup-juggler')));
      await t.tap(find.byKey(const ValueKey('lineup-juggler')));
      await t.pump();
      await t.pump(const Duration(milliseconds: 16));
      expect(flight, findsOneWidget);
      final first = t.getRect(flight);
      expect(start.contains(first.center), isTrue, reason: 'it leaves from the print');
      expect(portraitOpacity(t), 0, reason: 'never two portraits at once');
      double speechOpacity() =>
          t.widget<AnimatedOpacity>(find.ancestor(of: speech, matching: find.byType(AnimatedOpacity)).first).opacity;
      expect(speechOpacity(), 0, reason: 'the words wait for the portrait');
      await t.pump(const Duration(milliseconds: 380));
      final late = t.getRect(flight);
      final portrait = t.getRect(find.byKey(const ValueKey('talk-portrait')));
      expect((late.center - portrait.center).distance, lessThan(12), reason: 'it lands on the portrait');
      expect(late.height, greaterThan(first.height), reason: 'it grows as it goes');
      await t.pump(const Duration(milliseconds: 100));
      expect(flight, findsNothing);
      expect(portraitOpacity(t), 1);
      expect(speechOpacity(), 0, reason: 'a short beat after landing');
      await t.pump(const Duration(milliseconds: 200));
      expect(speechOpacity(), 1, reason: 'then the words come in');
      expect(find.text('THE JUGGLER'), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('quick taps on two prints: one flight, one witness; a face mid-flight waits', (t) async {
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(390, 844), 'ep06_m1');
      await wait(t, const Duration(milliseconds: 1800));
      await t.tap(find.byKey(const ValueKey('lineup-flowerSeller')));
      await t.pump(const Duration(milliseconds: 30));
      await t.tap(find.byKey(const ValueKey('lineup-baker')), warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 30));
      expect(flight, findsOneWidget);
      await t.tap(find.byKey(const ValueKey('speaker-juggler')), warnIfMissed: false);
      await wait(t, const Duration(milliseconds: 700));
      expect(find.byKey(const ValueKey('statements-sheet')), findsNothing, reason: 'no tap went through to a tip');
      expect(find.text('THE FLOWER SELLER'), findsOneWidget);
      expect(flight, findsNothing);
      // Then other witnesses as usual (no flight between them).
      await play.tapKey(t, 'speaker-baker');
      expect(find.text('THE BAKER'), findsOneWidget);
      expect(flight, findsNothing);
      expect(t.takeException(), isNull);
    });

    testWidgets('back in the middle of the flight: no error; coming back, the talk is there', (t) async {
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(360, 640), 'ep06_m1');
      await wait(t, const Duration(milliseconds: 1800));
      await t.tap(find.byKey(const ValueKey('lineup-baker')));
      await t.pump(const Duration(milliseconds: 100));
      await t.tap(find.byTooltip('Back'));
      await wait(t, const Duration(milliseconds: 600));
      await tapText(t, 'INVESTIGATE', after: const Duration(milliseconds: 700));
      expect(find.text('THE BAKER'), findsOneWidget);
      expect(flight, findsNothing);
      expect(portraitOpacity(t), 1);
      expect(t.takeException(), isNull);
    });

    testWidgets('reduced motion: TALK is a steady gold; the talk opens at once, no flight', (t) async {
      t.platformDispatcher.accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(disableAnimations: true);
      addTearDown(t.platformDispatcher.clearAccessibilityFeaturesTestValue);
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(390, 844), 'ep06_m1');
      final before = looks(t).first.border;
      await t.pump(const Duration(milliseconds: 700));
      expect(looks(t).first.border, before, reason: 'still');
      expect((before! as Border).top.color.a, closeTo(1, 0.01), reason: 'at its brightest, steady');
      await t.tap(find.byKey(const ValueKey('lineup-flowerSeller')));
      await t.pump();
      expect(flight, findsNothing);
      await t.pump();
      expect(find.text('THE FLOWER SELLER'), findsOneWidget);
      expect(portraitOpacity(t), 1);
    });
  });

  group('the notebook and the words', () {
    testWidgets("the Notebook's Witness Notes keep what the witnesses said, and where — also from Mission 02", (t) async {
      final play = MissionPlay();
      // Mission 02 open: Mission 01 solved (also an old save, from before talks).
      await play.openPuzzle(t, const Size(390, 844), 'ep06_m2');
      await t.tap(find.byTooltip('Detective notebook'));
      await wait(t, const Duration(milliseconds: 800));
      await tapText(t, 'EVIDENCE', after: const Duration(milliseconds: 600));
      await tapText(t, 'Witness Notes', after: const Duration(milliseconds: 800));
      final said = find.byKey(const ValueKey('evidence-statements'));
      expect(said, findsOneWidget);
      expect(find.descendant(of: said, matching: find.text('WHAT THE WITNESSES TOLD YOU')), findsOneWidget);
      for (final s in talk.recorded()) {
        expect(find.descendant(of: said, matching: find.text('"${s.text}"')), findsWidgets, reason: s.id);
        expect(find.descendant(of: said, matching: find.text(talk.speaker(s.speakerId).title)), findsWidgets);
      }
      expect(find.descendant(of: said, matching: find.text('Heard at the Market Hall · Mission 1')), findsOneWidget);
      expect(find.descendant(of: said, matching: find.text('"He had a big red umbrella."')), findsNothing,
          reason: 'only what a solved talk is sure to have heard');
      expect(play.ref.read(gameControllerProvider).isCompleted('ep06_m2'), isFalse, reason: 'nothing answered for you');
      await shot(t, 'case06_m1_w25_390x844_8_notebook_m2');
    });

    testWidgets('before Mission 01 is solved, the Witness Notes show no statements', (t) async {
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(390, 844), 'ep06_m1');
      expect(play.ref.read(gameControllerProvider).isCompleted('ep06_m1'), isFalse);
      expect(find.byKey(const ValueKey('evidence-statements')), findsNothing);
    });

    testWidgets('WORDS lists the words on screen; a tap shows the word card', (t) async {
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(390, 844), 'ep06_m1');
      await ask(play, t, 'juggler', 'carry');
      expect(dotted(), findsNothing);
      await play.tapKey(t, 'open-words', after: const Duration(milliseconds: 600));
      expect(find.byKey(const ValueKey('words-sheet')), findsOneWidget);
      expect(find.byKey(const ValueKey('word-carried')), findsOneWidget);
      expect(find.byKey(const ValueKey('word-stranger')), findsOneWidget, reason: 'from the goal on top');
      await play.tapKey(t, 'word-carried', after: const Duration(milliseconds: 600));
      expect(find.text('WORD CARD'), findsOneWidget);
    });
  });

  group('larger text and still motion', () {
    testWidgets('text 1.3× at 360×640: arriving, talk, comparing with three statements — whole and in sight', (t) async {
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(360, 640), 'ep06_m1', textScale: 1.3);
      await wait(t, const Duration(milliseconds: 1800));
      expect(findReadable(talk.goal), findsOneWidget);
      await shot(t, 'case06_m1_w25_360x640_text13_arrival');
      await ask(play, t, 'flowerSeller', 'carry');
      expect(t.renderObject<RenderParagraph>(find.text('MARKET HALL')).didExceedMaxLines, isFalse);
      await ask(play, t, 'baker', 'carry');
      await ask(play, t, 'juggler', 'carry');
      await shot(t, 'case06_m1_w25_360x640_text13');
      await openCompare(play, t);
      await pickTwo(play, t, 'flowerSeller.carry', 'juggler.carry');
      await wait(t, const Duration(milliseconds: 200));
      final view = t.getRect(find.byKey(const ValueKey('compare-sheet')));
      for (final s in ['flowerSeller.carry', 'juggler.carry']) {
        final r = t.getRect(story(s));
        expect(r.top >= view.top && r.bottom <= view.bottom + 0.5, isTrue, reason: '$s whole in sight: $r in $view');
      }
      await shot(t, 'case06_m1_w25_360x640_text13_compare');
      await wait(t, const Duration(milliseconds: 2800));
      await ask(play, t, 'juggler', 'wearing');
      expect(marked('DESCRIPTION RECORDED'), findsOneWidget);
      final screen13 = Offset.zero & const Size(360, 640);
      expect(t.getRect(mark).top, greaterThanOrEqualTo(t.getRect(find.byKey(const ValueKey('talk-panel'))).top),
          reason: 'the whole step in sight, no scrolling');
      for (final b in [find.byKey(const ValueKey('view-witness-notes')), cont]) {
        expect(screen13.contains(t.getRect(b).bottomCenter - const Offset(0, 1)), isTrue);
        expect(t.getRect(b).height, greaterThanOrEqualTo(48));
      }
      await shot(t, 'case06_m1_w25_360x640_text13_recorded');
      await play.tapKey(t, 'continue-investigation', after: const Duration(milliseconds: 900));
      expect(find.byKey(const ValueKey('discovery-moment')), findsOneWidget);
      expect(t.takeException(), isNull);
    });

    testWidgets('a long answer at 1.3× still reads in its card (360×640)', (t) async {
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(360, 640), 'ep06_m1', textScale: 1.3);
      await ask(play, t, 'juggler', 'when');
      final card = t.getRect(speech);
      final answer =
          t.getRect(find.descendant(of: speech, matching: findReadableContaining('The church clock was nearly at twelve.')));
      expect(answer.bottom, lessThanOrEqualTo(card.bottom + 0.5));
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
