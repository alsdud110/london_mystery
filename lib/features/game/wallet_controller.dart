import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../data/models/mission.dart';
import '../../data/models/profile.dart';
import '../../data/models/wallet.dart';
import 'game_controller.dart';
import 'game_providers.dart';

/// How a Detective Tip was opened (see [WalletController.unlockTip]).
enum TipUnlock {
  /// Already the detective's: read again, nothing paid.
  alreadyYours,

  /// A tip that costs nothing (tip 1).
  free,

  /// Paid for with coins.
  paid,

  /// Not enough coins: given free all the same, so no one is ever stuck.
  help,

  /// Insufficient coins; the paid tip was not unlocked.
  insufficientCoins,
}

/// The detective's coins, for the whole profile (every case, every run).
///
/// Every change is an entry with a key that can be written once (see
/// [Wallet]): a mission pays once ever, a tip is charged once ever, and a
/// quick second tap changes nothing. Every change is saved at once.
class WalletController extends Notifier<Wallet> {
  @override
  Wallet build() {
    final repo = ref.read(progressRepositoryProvider);
    final saved = repo.loadWallet();
    if (saved != null) return saved;
    // No wallet yet: a new player, or a save from before coins existed. Only
    // a save copied from before coins (marked when it was copied) is paid
    // back, and only once: a wallet lost later is not paid back again.
    final backfill = sessionProfile(ref).walletBackfill == WalletBackfill.pending;
    final made = _firstWallet(backfill: backfill);
    repo.saveWallet(made);
    if (backfill) ref.read(profileStoreProvider).update((p) => p.copyWith(walletBackfill: WalletBackfill.done));
    return made;
  }

  /// The coins a solved [mission] pays.
  static int coinsFor(Mission mission) => mission.isFinal ? AppConstants.finalCoins : AppConstants.missionCoins;

  /// The price of tip [tip] (1 or 2).
  static int priceOf(int tip) => AppConstants.tipPrices[tip - 1];

  /// A new wallet: the start coins, and (for a save from before coins
  /// existed) what its solved missions would have paid and the tips it had
  /// already opened, which stay free.
  Wallet _firstWallet({required bool backfill}) {
    final at = GameController.now();
    var wallet = Wallet.empty.adding(
      CoinEntry(key: Wallet.startKey, amount: AppConstants.startCoins, source: CoinSource.start, at: at),
    );
    if (!backfill) return wallet;
    final repo = ref.read(progressRepositoryProvider);
    for (final e in ref.read(allEpisodesProvider)) {
      final p = repo.load(e.id);
      for (final m in e.allMissions) {
        if (p.isCompleted(m.id)) {
          wallet = wallet.adding(
            CoinEntry(key: Wallet.missionKey(m.id), amount: coinsFor(m), source: CoinSource.backfill, at: at),
          );
        }
        final opened = p.hintsFor(m.id).clamp(0, AppConstants.tipPrices.length);
        for (var tip = 1; tip <= opened; tip++) {
          wallet = wallet.adding(CoinEntry(key: Wallet.tipKey(m.id, tip), amount: 0, source: CoinSource.tip, at: at));
        }
      }
    }
    return wallet;
  }

  void _set(Wallet next) {
    if (identical(next, state)) return;
    state = next;
    ref.read(progressRepositoryProvider).saveWallet(next);
  }

  /// Pays a solved [mission]'s coins, once ever. Returns the coins added
  /// (0 when it was paid before, e.g. a case played again).
  int rewardMission(Mission mission) {
    final key = Wallet.missionKey(mission.id);
    if (state.has(key)) return 0;
    final coins = coinsFor(mission);
    _set(state.adding(
      CoinEntry(key: key, amount: coins, source: CoinSource.mission, at: GameController.now()),
    ));
    return coins;
  }

  /// Unlocks a tip only if it is free, already owned, or affordable.
  /// Insufficient balance never unlocks or charges the tip.
  TipUnlock unlockTip(Mission mission, int tip) {
    assert(tip >= 1 && tip <= AppConstants.tipPrices.length);
    if (state.ownsTip(mission.id, tip)) return TipUnlock.alreadyYours;
    final price = priceOf(tip);
    if (price > state.balance) return TipUnlock.insufficientCoins;
    final (amount, result) = price == 0
        ? (0, TipUnlock.free)
        : (-price, TipUnlock.paid);
    _set(state.adding(
      CoinEntry(
        key: Wallet.tipKey(mission.id, tip),
        amount: amount,
        source: CoinSource.tip,
        at: GameController.now(),
      ),
    ));
    return result;
  }

  /// Credits one completed ad event. Call only from a trusted reward callback.
  /// [rewardId] must be stable and unique for that event. Returns 0 for a
  /// duplicate or invalid id; never credit on load, click or dismissal.
  int rewardCompletedAd(String rewardId) {
    final id = rewardId.trim();
    if (id.isEmpty) return 0;
    final key = 'rewarded-ad:$id';
    if (state.has(key)) return 0;
    _set(state.adding(CoinEntry(
      key: key,
      amount: AppConstants.rewardedAdCoins,
      source: CoinSource.rewardedAd,
      at: GameController.now(),
    )));
    return AppConstants.rewardedAdCoins;
  }

  /// Everything was wiped (a new detective): a new wallet with the start
  /// coins only. Nothing is paid back for saves written after the wipe.
  void startFresh() => _set(_firstWallet(backfill: false));
}

final walletProvider = NotifierProvider<WalletController, Wallet>(WalletController.new);
