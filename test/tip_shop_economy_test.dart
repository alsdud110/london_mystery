import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:london_mystery/app.dart';
import 'package:london_mystery/core/constants/app_constants.dart';
import 'package:london_mystery/core/router/app_router.dart';
import 'package:london_mystery/core/theme/app_colors.dart';
import 'package:london_mystery/data/models/game_progress.dart';
import 'package:london_mystery/data/models/mission.dart';
import 'package:london_mystery/data/models/season_progress.dart';
import 'package:london_mystery/data/models/wallet.dart';
import 'package:london_mystery/data/repositories/episode_repository.dart';
import 'package:london_mystery/features/game/game_controller.dart';
import 'package:london_mystery/features/game/game_providers.dart';
import 'package:london_mystery/features/game/scoring.dart';
import 'package:london_mystery/features/game/wallet_controller.dart';
import 'package:london_mystery/features/mission/widgets/tip_shop.dart';
import 'package:london_mystery/features/result/detective_report.dart';
import 'package:london_mystery/widgets/game_button.dart';
import 'package:london_mystery/widgets/paper.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'full_playthrough_test.dart' show reveal, tapText, wait;
import 'helpers.dart';
import 'mission_play.dart';
import 'title_screen_test.dart' show capture;

/// GET A TIP and the coins: tip 1 free, tip 2 for coins (or free help when
/// they are short), coins paid once per mission, XP rule 4, and saves from
/// before coins keep everything they had.
void main() {
  final season = MockEpisodeRepository.bundled();
  final m = {for (final x in episode01.allMissions) x.id: x};

  group('the wallet (controller)', () {
    late ProviderContainer c;
    GameController game() => c.read(gameControllerProvider.notifier);
    WalletController wallet() => c.read(walletProvider.notifier);
    Wallet coins() => c.read(walletProvider);

    setUp(() async => c = ProviderContainer(overrides: await testOverrides()));
    tearDown(() => c.dispose());

    test('every price and reward comes from one place', () {
      expect(AppConstants.tipPrices, [0, 20]);
      expect(WalletController.priceOf(1), 0);
      expect(WalletController.priceOf(2), 20);
      expect(WalletController.coinsFor(m['m01']!), AppConstants.missionCoins);
      expect(WalletController.coinsFor(m['final']!), AppConstants.finalCoins);
      expect((AppConstants.missionCoins, AppConstants.finalCoins, AppConstants.startCoins), (30, 60, 20));
      expect((AppConstants.missionXp, AppConstants.finalXp), (30, 60));
    });

    test('a new detective starts with the start coins', () {
      expect(coins().balance, AppConstants.startCoins);
      expect(coins().entries.single.source, CoinSource.start);
    });

    test('tip 1 is free; tip 2 is paid once; a second tap changes nothing', () {
      expect(wallet().unlockTip(m['m01']!, 1), TipUnlock.free);
      expect(coins().balance, 20);
      expect(wallet().unlockTip(m['m01']!, 2), TipUnlock.paid);
      expect(coins().balance, 0);
      expect(wallet().unlockTip(m['m01']!, 2), TipUnlock.alreadyYours, reason: 'a quick second tap');
      expect(wallet().unlockTip(m['m01']!, 1), TipUnlock.alreadyYours);
      expect(coins().balance, 0, reason: 'never charged twice');
      expect(coins().ownsTip('m01', 1) && coins().ownsTip('m01', 2), isTrue);
    });

    test('short of coins: tip 2 is given as help, and the balance never goes below zero', () {
      wallet().unlockTip(m['m01']!, 2); // 20 → 0
      expect(wallet().unlockTip(m['m02']!, 2), TipUnlock.help);
      expect(coins().balance, 0);
      expect(coins().ownsTip('m02', 2), isTrue, reason: 'help is the detective’s too: read again free');
      for (final e in coins().entries) {
        expect(e.amount >= -AppConstants.tipPrices.last, isTrue);
      }
    });

    test('a solve pays its coins once; Play again pays nothing more; XP rule 4 is recorded', () {
      game().startInvestigation();
      expect(game().submitAnswer(m['m01']!, 'b').coins, 30);
      expect(coins().balance, 20 + 30);
      expect(game().submitAnswer(m['m01']!, 'b').coins, 0, reason: 'a solved mission submitted again');
      expect(c.read(gameControllerProvider).xpRules['m01'], 4);
      expect(XpBreakdown.of(m['m01']!, c.read(gameControllerProvider)).total, 30);
      game().playAgain();
      game().startInvestigation();
      expect(game().submitAnswer(m['m01']!, 'b').coins, 0, reason: 'paid once ever');
      expect(coins().balance, 50);
      expect(XpBreakdown.of(m['m01']!, c.read(gameControllerProvider)).total, 30, reason: 'XP is per run, as before');
    });

    test('a wrong answer pays nothing', () {
      game().startInvestigation();
      expect(game().submitAnswer(m['m01']!, 'a').coins, 0);
      expect(coins().balance, 20);
    });

    test('the final pays 60', () {
      game().startInvestigation();
      for (final (id, answer) in [('m01', 'b'), ('m02', 'stone'), ('m03', '417'), ('m04', 'c'), ('m05', 'LM-EP01-PALACE')]) {
        game().submitAnswer(m[id]!, answer);
      }
      expect(game().submitAnswer(m['final']!, '7924').coins, 60);
      expect(coins().balance, 20 + 5 * 30 + 60);
    });

    test('Reset everything: a new wallet, start coins only', () async {
      game().startInvestigation();
      game().submitAnswer(m['m01']!, 'b');
      wallet().unlockTip(m['m02']!, 2);
      await game().resetAll();
      expect(coins().balance, AppConstants.startCoins);
      expect(coins().ownsTip('m02', 2), isFalse);
    });
  });

  group('saved and restored', () {
    test('the wallet survives a restart, exactly', () async {
      final first = ProviderContainer(overrides: await testOverrides());
      first.read(gameControllerProvider.notifier).startInvestigation();
      first.read(gameControllerProvider.notifier).submitAnswer(m['m01']!, 'b');
      first.read(walletProvider.notifier).unlockTip(m['m02']!, 1);
      first.read(walletProvider.notifier).unlockTip(m['m02']!, 2);
      final saved = first.read(walletProvider);
      first.dispose();

      final prefs = await SharedPreferences.getInstance();
      final again = ProviderContainer(overrides: [sharedPreferencesProvider.overrideWithValue(prefs)]);
      final wallet = again.read(walletProvider);
      expect(wallet.balance, saved.balance);
      expect(wallet.balance, 20 + 30 - 20);
      expect(wallet.ownsTip('m02', 2), isTrue);
      expect(again.read(walletProvider.notifier).unlockTip(m['m02']!, 2), TipUnlock.alreadyYours);
      expect(again.read(walletProvider).balance, 30, reason: 'no charge after a restart');
      again.dispose();
    });

    test('an unreadable wallet entry is dropped; the rest loads', () {
      final w = Wallet.fromJson({
        'entries': [
          {'key': 'start', 'amount': 20, 'source': 'start'},
          {'key': 'x', 'amount': 'lots', 'source': 'start'},
          {'key': 'start', 'amount': 999, 'source': 'start'},
          'junk',
        ],
      });
      expect(w.balance, 20);
      expect(w.entries, hasLength(1));
    });
  });

  group('saves from before coins', () {
    String save(GameProgress p) => jsonEncode(p.toJson());

    test('solved missions are paid once; tips already opened stay free; XP stays as earned', () async {
      final ids = [for (final x in episode01.allMissions) x.id];
      final old = GameProgress(
        detectiveName: 'KIM',
        introSeen: true,
        completedMissionIds: ids,
        hintsUsed: const {'m01': 2, 'm03': 1},
        xpRules: {for (final id in ids) id: 3},
        startedAt: DateTime(2026, 10, 1),
        completedAt: DateTime(2026, 10, 1, 0, 20),
      );
      final ep02 = season[1];
      final ep02Old = GameProgress(
        detectiveName: 'KIM',
        introSeen: true,
        completedMissionIds: [ep02.missions.first.id],
        hintsUsed: {ep02.missions[1].id: 1},
        xpRules: {ep02.missions.first.id: 3},
        startedAt: DateTime(2026, 10, 2),
      );
      final c = ProviderContainer(overrides: await testOverrides(prefs: {
        AppConstants.progressStorageKey: save(old),
        AppConstants.progressKeyFor('ep02'): save(ep02Old),
      }));
      final wallet = c.read(walletProvider);
      expect(wallet.balance, 20 + 5 * 30 + 60 + 30, reason: 'start + Case 01 + one Case 02 mission');
      expect(wallet.entries.where((e) => e.source == CoinSource.backfill), hasLength(7));
      for (final (id, tip) in [('m01', 1), ('m01', 2), ('m03', 1), (ep02.missions[1].id, 1)]) {
        expect(wallet.ownsTip(id, tip), isTrue, reason: '$id tip $tip: opened before, free');
      }
      expect(wallet.ownsTip('m03', 2), isFalse);
      // XP: rule 3 missions keep 100 / 200.
      expect(XpBreakdown.totalFor(episode01, c.read(gameControllerProvider)), 5 * 100 + 200);
      // Paid once: the made wallet is saved, so nothing is paid again.
      expect(c.read(progressRepositoryProvider).loadWallet()!.balance, wallet.balance);
      c.read(gameControllerProvider.notifier).playAgain();
      c.read(gameControllerProvider.notifier).startInvestigation();
      expect(c.read(gameControllerProvider.notifier).submitAnswer(m['m01']!, 'b').coins, 0);
      // The parent report still counts the tips of its run.
      final report = DetectiveReport.from(episode01, old);
      expect(report.hintsUsed, 3);
      c.dispose();
    });

    test('a mission solved right as the wallet is made is paid as a new solve, once', () async {
      final c = ProviderContainer(overrides: await testOverrides(prefs: {
        AppConstants.progressStorageKey: save(const GameProgress(detectiveName: 'KIM', introSeen: true)),
      }));
      // The wallet is first read by this answer.
      final outcome = c.read(gameControllerProvider.notifier).submitAnswer(m['m01']!, 'b');
      expect(outcome.coins, 30);
      expect(c.read(walletProvider).balance, 50);
      expect(c.read(walletProvider).entries.where((e) => e.source == CoinSource.backfill), isEmpty);
      c.dispose();
    });
  });

  group('tip states', () {
    test('one next tip at a time; tip 2 waits for tip 1', () {
      TipState s(int tip, {int revealed = 0, bool owns = false, int balance = 20}) =>
          tipStateOf(tip: tip, revealed: revealed, owns: owns, balance: balance);
      expect(s(1), TipState.free);
      expect(s(2), TipState.locked);
      expect(s(1, revealed: 1), TipState.onPage);
      expect(s(2, revealed: 1), TipState.buy);
      expect(s(2, revealed: 1, balance: 19), TipState.help);
      expect(s(2, revealed: 1, owns: true, balance: 0), TipState.yours);
      expect(s(1, owns: true), TipState.yours);
    });
  });

  group('GET A TIP on screen: a small confirm dialog', () {
    Finder inDialog(Finder f) => find.descendant(of: find.byType(Dialog), matching: f);
    Finder dialogText(String s) => inDialog(find.text(s));
    int balanceShown(WidgetTester t) => int.parse(t.widget<Text>(find.byKey(const ValueKey('tip-shop-balance'))).data!);
    final cancel = find.byWidgetPredicate((w) => w is GameButton && w.label == 'CANCEL');

    /// The dialog is the small confirm: coins, question, price, two buttons
    /// side by side; none of the old shop.
    void isConfirm(WidgetTester t, Size size, {required String message, required String price}) {
      expect(find.byType(BottomSheet), findsNothing, reason: 'no shop sheet');
      expect(dialogText('YOUR TOTAL COINS'), findsOneWidget);
      expect(dialogText('Reveal a tip?'), findsOneWidget);
      expect(dialogText(message), findsOneWidget);
      expect(inDialog(find.byKey(const ValueKey('tip-price'))), findsOneWidget);
      expect(find.descendant(of: find.byKey(const ValueKey('tip-price')), matching: find.text(price)), findsOneWidget);
      for (final gone in ['DETECTIVE TIPS', 'TIP 01', 'TIP 02', 'A Little Help', 'A Closer Look', 'Back to the puzzle']) {
        expect(find.text(gone), findsNothing, reason: gone);
      }
      for (final gone in ['UNLOCK', 'After this', 'Tips you open stay yours', '→']) {
        expect(inDialog(find.textContaining(gone)), findsNothing, reason: gone);
      }
      final c = t.getRect(cancel), r = t.getRect(tipSheetButton);
      expect(c.top, r.top, reason: 'side by side');
      expect(c.right, lessThan(r.left), reason: 'CANCEL left, REVEAL right');
      _whole(t, cancel, size);
      _whole(t, tipSheetButton, size);
      final paper = t.getRect(inDialog(find.byType(PaperSheet)).first);
      expect(paper.left, greaterThanOrEqualTo(0));
      expect(paper.right, lessThanOrEqualTo(size.width));
      expect(paper.height, lessThan(size.height * 0.7), reason: 'it does not cover the puzzle');
    }

    for (final (size, scale, tag) in const [
      (Size(360, 640), 1.0, '360x640'),
      (Size(390, 844), 1.0, '390x844'),
      (Size(360, 640), 1.3, '360x640_x1.3'),
    ]) {
      testWidgets('$tag: tip 1 FREE, tip 2 for 20 coins; REVEAL writes it on the page', (t) async {
        final play = MissionPlay();
        final mission = await play.openPuzzle(t, size, 'm01', textScale: scale);
        await tapText(t, 'Get a tip', after: const Duration(milliseconds: 600));
        expect(balanceShown(t), 20);
        isConfirm(t, size, message: 'Reveal this clue for free.', price: 'FREE');
        await capture(t, 'tip_dialog_tip1_$tag');
        await takeTipFromSheet(t);
        await wait(t, const Duration(milliseconds: 500));
        expect(find.byType(Dialog), findsNothing, reason: 'the dialog closes');
        expect(play.ref.read(walletProvider).balance, 20, reason: 'tip 1 is free');
        await reveal(t, findReadable(mission.hints[0]));
        expect(findReadable(mission.hints[0]), findsOneWidget, reason: 'tip 1 on the page');

        await tapText(t, 'Get a tip', after: const Duration(milliseconds: 600));
        expect(balanceShown(t), 20);
        isConfirm(t, size, message: 'Use 20 coins to reveal this clue.', price: '20\u00A0Coins');
        await capture(t, 'tip_dialog_tip2_$tag');
        await takeTipFromSheet(t);
        await wait(t, const Duration(milliseconds: 500));
        expect(play.ref.read(walletProvider).balance, 0);
        expect(play.ref.read(gameControllerProvider).hintsFor('m01'), 2);
        await reveal(t, findReadable(mission.hints[1]));
        expect(findReadable(mission.hints[1]), findsOneWidget, reason: 'tip 2 on the page');
        expect(find.text('Get a tip'), findsNothing, reason: 'no tips left');
        expect(t.takeException(), isNull);
      });
    }

    testWidgets('CANCEL (and a tap outside) closes it: nothing revealed, nothing paid', (t) async {
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(360, 640), 'm01');
      await tapText(t, 'Get a tip', after: const Duration(milliseconds: 600));
      await takeTipFromSheet(t); // tip 1
      await wait(t, const Duration(milliseconds: 400));
      await tapText(t, 'Get a tip', after: const Duration(milliseconds: 600));
      await t.tap(cancel);
      await wait(t, const Duration(milliseconds: 400));
      expect(find.byType(Dialog), findsNothing);
      await tapText(t, 'Get a tip', after: const Duration(milliseconds: 600));
      await t.tapAt(const Offset(8, 8)); // outside the paper
      await wait(t, const Duration(milliseconds: 400));
      expect(find.byType(Dialog), findsNothing);
      expect(play.ref.read(gameControllerProvider).hintsFor('m01'), 1);
      expect(play.ref.read(walletProvider).balance, 20);
      expect(play.ref.read(walletProvider).ownsTip('m01', 2), isFalse);
    });

    testWidgets('short of coins: tip 2 is FREE help, no charge', (t) async {
      final play = MissionPlay();
      final mission = await play.openPuzzle(t, const Size(360, 640), 'm02');
      // Spend down below one tip (the solved m01 was paid when the wallet was made).
      for (final other in season.skip(1).expand((e) => e.allMissions)) {
        if (play.ref.read(walletProvider).balance < 20) break;
        play.ref.read(walletProvider.notifier).unlockTip(other, 2);
      }
      final left = play.ref.read(walletProvider).balance;
      expect(left, lessThan(20));
      await tapText(t, 'Get a tip', after: const Duration(milliseconds: 600));
      await takeTipFromSheet(t); // tip 1, free
      await wait(t, const Duration(milliseconds: 400));
      await tapText(t, 'Get a tip', after: const Duration(milliseconds: 600));
      expect(balanceShown(t), left);
      isConfirm(t, const Size(360, 640), message: 'Your partner helps you for free this time.', price: 'FREE');
      await capture(t, 'tip_dialog_help_360x640');
      await takeTipFromSheet(t);
      await wait(t, const Duration(milliseconds: 400));
      expect(play.ref.read(walletProvider).balance, left, reason: 'help costs nothing');
      await reveal(t, findReadable(mission.hints[1]));
      expect(findReadable(mission.hints[1]), findsOneWidget);
    });

    testWidgets('a quick double tap on REVEAL reveals one tip and charges once', (t) async {
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(390, 844), 'm01');
      await tapText(t, 'Get a tip', after: const Duration(milliseconds: 600));
      await takeTipFromSheet(t);
      await wait(t, const Duration(milliseconds: 400));
      await tapText(t, 'Get a tip', after: const Duration(milliseconds: 600));
      await t.tap(tipSheetButton);
      await t.tap(tipSheetButton, warnIfMissed: false);
      await t.pump();
      await wait(t, const Duration(milliseconds: 500));
      expect(play.ref.read(walletProvider).balance, 0, reason: '20 once');
      expect(play.ref.read(gameControllerProvider).hintsFor('m01'), 2);
      expect(play.ref.read(walletProvider).entries.where((e) => e.key == Wallet.tipKey('m01', 2)), hasLength(1));
    });

    testWidgets('a tip already yours (a case played again) is revealed again for free', (t) async {
      final play = MissionPlay();
      await play.openPuzzle(t, const Size(390, 844), 'm01');
      play.ref.read(walletProvider.notifier).unlockTip(m['m01']!, 1);
      play.ref.read(walletProvider.notifier).unlockTip(m['m01']!, 2);
      final before = play.ref.read(walletProvider).balance;
      await tapText(t, 'Get a tip', after: const Duration(milliseconds: 600));
      isConfirm(t, const Size(390, 844), message: 'This tip is already yours. Read it again for free.', price: 'FREE');
      await takeTipFromSheet(t);
      await wait(t, const Duration(milliseconds: 400));
      await tapText(t, 'Get a tip', after: const Duration(milliseconds: 600));
      isConfirm(t, const Size(390, 844), message: 'This tip is already yours. Read it again for free.', price: 'FREE');
      await takeTipFromSheet(t);
      await wait(t, const Duration(milliseconds: 400));
      expect(play.ref.read(walletProvider).balance, before, reason: 'nothing paid again');
      expect(play.ref.read(gameControllerProvider).hintsFor('m01'), 2);
    });

    testWidgets('from the try-again sheet: GET A TIP opens the same dialog', (t) async {
      final play = MissionPlay();
      final mission = await play.openPuzzle(t, const Size(390, 844), 'm01');
      final wrong = mission.options.firstWhere((o) => o.id != mission.answer).label;
      await tapText(t, wrong, after: const Duration(milliseconds: 200));
      await tapText(t, 'CHECK ANSWER', after: const Duration(milliseconds: 900));
      await tapText(t, 'GET A TIP', after: const Duration(milliseconds: 900));
      isConfirm(t, const Size(390, 844), message: 'Reveal this clue for free.', price: 'FREE');
      await takeTipFromSheet(t);
      await wait(t, const Duration(milliseconds: 500));
      expect(play.ref.read(gameControllerProvider).hintsFor('m01'), 1);
      await reveal(t, findReadable(mission.hints[0]));
      expect(findReadable(mission.hints[0]), findsOneWidget);
    });

    testWidgets('a solve shows its XP and coins', (t) async {
      final play = MissionPlay();
      final mission = await play.openPuzzle(t, const Size(390, 844), 'm01');
      await play.solve(t, mission);
      await wait(t, const Duration(milliseconds: 2600));
      expect(find.text('+30 XP   ·   +30 COINS'), findsOneWidget);
    });
  });

  group('Final Mission: what the solve paid, above CONTINUE', () {
    final f = episode01.finalMission;
    final reward = find.byKey(const ValueKey('final-reward'));

    /// Case 01 at its final: every mission solved ([finalSolved]: the final
    /// too), with [wallet] saved (none: made on load, as for an old save).
    Future<ProviderContainer> openFinal(WidgetTester t, {bool finalSolved = false, Wallet? wallet}) async {
      t.view.physicalSize = const Size(390, 844) * 3;
      t.view.devicePixelRatio = 3;
      addTearDown(t.view.reset);
      final at = DateTime.now().subtract(const Duration(minutes: 5));
      await t.pumpWidget(ProviderScope(
        overrides: await testOverrides(prefs: {
          AppConstants.progressKeyFor(episode01.id): jsonEncode(GameProgress(
            detectiveName: 'MINYOUNG',
            introSeen: true,
            completedMissionIds: [for (final x in episode01.missions) x.id, if (finalSolved) f.id],
            xpRules: {for (final x in episode01.allMissions) x.id: XpBreakdown.currentRule},
            startedAt: at,
            completedAt: finalSolved ? at : null,
            playMillis: 0,
          ).toJson()),
          AppConstants.seasonStorageKey: jsonEncode(SeasonProgress(
            activeEpisodeId: episode01.id,
            solvedEpisodeIds: [if (finalSolved) episode01.id],
          ).toJson()),
          if (wallet != null) AppConstants.walletStorageKey: jsonEncode(wallet.toJson()),
        }),
        child: const RepaintBoundary(key: ValueKey('shot'), child: LondonMysteryApp()),
      ));
      await wait(t, const Duration(milliseconds: 300));
      final c = ProviderScope.containerOf(find.byType(LondonMysteryApp).evaluate().first);
      c.read(routerProvider).go(Routes.finalMission);
      await wait(t, const Duration(milliseconds: 1200));
      return c;
    }

    /// Turns the locks to the answer and opens them; waits for the box.
    Future<void> openTheLocks(WidgetTester t) async {
      final digits = f.answer.split('').map(int.parse).toList();
      for (var i = 0; i < digits.length; i++) {
        for (var n = 0; n < digits[i]; n++) {
          final up = find.byTooltip('Lock ${i + 1} up');
          await reveal(t, up);
          await t.tap(up);
          await t.pump(const Duration(milliseconds: 50));
        }
      }
      final open = find.text(f.scene == Artwork.royalBox ? 'OPEN THE BOX' : 'UNLOCK');
      await reveal(t, open);
      await t.tap(open);
      await wait(t, const Duration(seconds: 6));
    }

    String text(WidgetTester t) => t.widget<Text>(reward).data!;

    testWidgets('first solve: +60 XP · +60 COINS, gold, right above CONTINUE', (t) async {
      final c = await openFinal(t);
      final before = c.read(walletProvider).balance;
      await openTheLocks(t);
      expect(text(t), '+${AppConstants.finalXp} XP   ·   +${AppConstants.finalCoins} COINS');
      expect(c.read(walletProvider).balance - before, AppConstants.finalCoins, reason: 'shown = paid');
      expect(XpBreakdown.of(f, c.read(gameControllerProvider)).total, AppConstants.finalXp, reason: 'shown = earned');
      expect(t.widget<Text>(reward).style!.color, AppColors.goldLight);
      final next = find.ancestor(of: find.text('CONTINUE'), matching: find.byType(GameButton));
      await reveal(t, next);
      expect(t.getRect(reward).bottom, lessThanOrEqualTo(t.getRect(next).top));
      expect(t.getRect(next).top - t.getRect(reward).bottom, lessThan(40), reason: 'one line, just above it');
      await capture(t, 'final_reward_first_390x844');
      expect(t.takeException(), isNull);
    });

    testWidgets('played again (coins paid before): +60 XP only, no coins shown', (t) async {
      final paid = Wallet.empty
          .adding(const CoinEntry(key: Wallet.startKey, amount: 20, source: CoinSource.start))
          .adding(CoinEntry(key: Wallet.missionKey(f.id), amount: AppConstants.finalCoins, source: CoinSource.mission));
      final c = await openFinal(t, wallet: paid);
      await openTheLocks(t);
      expect(text(t), '+${AppConstants.finalXp} XP');
      expect(find.textContaining('COINS'), findsNothing, reason: 'no coins were added');
      await capture(t, 'final_reward_replay_390x844');
      expect(c.read(walletProvider).balance, paid.balance);
      expect(XpBreakdown.totalFor(episode01, c.read(gameControllerProvider)),
          AppConstants.missionXp * episode01.missions.length + AppConstants.finalXp,
          reason: "the XP shown is in this run's case total");
    });

    testWidgets('an already solved final, opened again: no reward line', (t) async {
      await openFinal(t, finalSolved: true);
      await t.scrollUntilVisible(find.text('CONTINUE'), 300, scrollable: find.byType(Scrollable).first);
      expect(reward, findsNothing, reason: 'nothing was paid now');
    });
  });

  // Last: the real fonts stay loaded for the rest of the file.
  group('GET A TIP dialog with the real fonts', () {
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

    for (final (size, scale, tag) in const [
      (Size(360, 640), 1.0, '360x640'),
      (Size(390, 844), 1.0, '390x844'),
      (Size(360, 640), 1.3, '360x640_x1.3'),
    ]) {
      testWidgets('$tag: the dialog is small, whole, and its buttons sit side by side', (t) async {
        final play = MissionPlay();
        await play.openPuzzle(t, size, 'm01', textScale: scale);
        await tapText(t, 'Get a tip', after: const Duration(milliseconds: 700));
        await capture(t, 'tip_dialog_fonts_tip1_$tag');
        await takeTipFromSheet(t);
        await wait(t, const Duration(milliseconds: 500));
        await tapText(t, 'Get a tip', after: const Duration(milliseconds: 700));
        final paper = t.getRect(find.descendant(of: find.byType(Dialog), matching: find.byType(PaperSheet)).first);
        expect(paper.top, greaterThanOrEqualTo(0));
        expect(paper.bottom, lessThanOrEqualTo(size.height));
        expect(paper.height, lessThan(size.height * 0.7));
        final cancel = find.byWidgetPredicate((w) => w is GameButton && w.label == 'CANCEL');
        expect(t.getRect(cancel).top, t.getRect(tipSheetButton).top);
        _whole(t, cancel, size);
        _whole(t, tipSheetButton, size);
        expect(find.text('20\u00A0Coins'), findsOneWidget);
        await capture(t, 'tip_dialog_fonts_tip2_$tag');
        expect(t.takeException(), isNull, reason: 'no overflow');
      });
    }
  });
}

/// [f] is inside the screen and at least 44 px tall.
void _whole(WidgetTester t, Finder f, Size size) {
  final r = t.getRect(f);
  expect(r.left, greaterThanOrEqualTo(0));
  expect(r.right, lessThanOrEqualTo(size.width));
  expect(r.bottom, lessThanOrEqualTo(size.height));
  expect(r.height, greaterThanOrEqualTo(44));
}
