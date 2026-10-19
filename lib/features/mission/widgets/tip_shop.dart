import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/models/mission.dart';
import '../../../widgets/game_button.dart';
import '../../../widgets/ink_icon.dart';
import '../../../widgets/paper.dart';
import '../../game/game_controller.dart';
import '../../game/rewarded_ad_service.dart';
import '../../game/wallet_controller.dart';

/// What the next Detective Hint is (see [requestTip]).
enum TipState {
  /// Already written on the puzzle page.
  onPage,

  /// The detective's (opened in an earlier run): read again for free.
  yours,

  /// The next tip, free (tip 1).
  free,

  /// The next tip, paid for with coins.
  buy,

  /// The next tip costs more coins than the detective has.
  help,

  /// Not yet: the tip before it comes first.
  locked,
}

/// The state of tip [tip] (1-based) of [missionId]: [revealed] tips are on
/// the page in this run, [owns] says which are the detective's, [balance]
/// is the coins in hand.
TipState tipStateOf({
  required int tip,
  required int revealed,
  required bool owns,
  required int balance,
}) {
  if (tip <= revealed) return TipState.onPage;
  if (tip > revealed + 1) return TipState.locked;
  if (owns) return TipState.yours;
  final price = WalletController.priceOf(tip);
  if (price == 0) return TipState.free;
  return balance >= price ? TipState.buy : TipState.help;
}

/// For each game (one per app session), the missions whose free hint was
/// just opened, with the frame it was opened on: a quick second tap on the
/// same link does not open the next (paid) hint's dialog straight after.
final _freeOpenedAt = Expando<Map<String, Duration>>('free hint opened');
const _settle = Duration(milliseconds: 500);

Duration get _frameTime =>
    SchedulerBinding.instance.currentSystemFrameTimeStamp;

/// Get More Hints: asks for the next hint of [mission]. A hint that costs
/// nothing (the free first hint, or one the detective already owns from an
/// earlier run) is written on the page at once, with no dialog. A hint that
/// costs coins (or is given as help when they are short) asks first, in
/// [showTipShop]. Returns true when a hint was revealed.
Future<bool> requestTip(
  BuildContext context,
  WidgetRef ref,
  Mission mission,
) async {
  // A dialog (or sheet) is already over the page: a second tap waits for it.
  if (ModalRoute.of(context)?.isCurrent == false) return false;
  final game = ref.read(gameControllerProvider.notifier);
  final opened = _freeOpenedAt[game] ??= {};
  final tip = ref.read(gameControllerProvider).hintsFor(mission.id) + 1;
  if (tip > mission.hints.length) return false;
  final wallet = ref.read(walletProvider);
  final state = tipStateOf(
    tip: tip,
    revealed: tip - 1,
    owns: wallet.ownsTip(mission.id, tip),
    balance: wallet.balance,
  );
  if (state == TipState.free || state == TipState.yours) {
    if (!_saveTip(ref, mission, tip)) return false;
    opened[mission.id] = _frameTime;
    return true;
  }
  final at = opened[mission.id];
  if (at != null && _frameTime - at < _settle) return false;
  return showTipShop(context, mission);
}

/// Opens hint [tip] of [mission] (coins and page saved together). False,
/// with the error reported, when it could not be saved: the page shows no
/// new hint then.
bool _saveTip(WidgetRef ref, Mission mission, int tip) {
  final before = ref.read(gameControllerProvider).hintsFor(mission.id);
  try {
    ref.read(gameControllerProvider.notifier).revealTip(mission, tip);
  } catch (error, stack) {
    FlutterError.reportError(
      FlutterErrorDetails(exception: error, stack: stack, library: 'tip shop'),
    );
    return false;
  }
  return ref.read(gameControllerProvider).hintsFor(mission.id) > before;
}

/// The coins dialog for a hint that costs coins: a small paper sheet with
/// the question, the price said once, CANCEL and GET MORE HINTS. GET MORE HINTS pays, writes
/// the hint on the puzzle page and closes it; CANCEL (or a tap outside)
/// changes nothing. When coins are short, the ad reward option is shown.
/// Returns true when a hint was
/// revealed.
Future<bool> showTipShop(BuildContext context, Mission mission) async {
  final revealed = await showDialog<bool>(
    context: context,
    barrierColor: AppColors.navyDeep.withValues(alpha: 0.55),
    builder: (context) => _TipDialog(mission: mission),
  );
  return revealed ?? false;
}

class _TipDialog extends ConsumerStatefulWidget {
  const _TipDialog({required this.mission});

  final Mission mission;

  @override
  ConsumerState<_TipDialog> createState() => _TipDialogState();
}

class _TipDialogState extends ConsumerState<_TipDialog> {
  /// Set by the first tap: the dialog reveals one tip, once.
  bool _opening = false;
  bool _watchingAd = false;
  String? _rewardMessage;

  Future<void> _watchAd() async {
    if (_watchingAd) return;
    setState(() => _watchingAd = true);
    try {
      final result = await ref.read(rewardedAdServiceProvider).showAndReward();
      if (!mounted) return;
      setState(() {
        _rewardMessage = result.coins > 0
            ? 'You earned ${result.coins} coins!'
            : result.status == RewardedAdStatus.unavailable
                ? 'Ads are not available yet.'
                : 'No coins earned. Please try again.';
      });
    } catch (error, stack) {
      FlutterError.reportError(FlutterErrorDetails(exception: error, stack: stack, library: 'rewarded ad'));
      if (mounted) setState(() => _rewardMessage = 'Ad unavailable. Please try again.');
    } finally {
      if (mounted) setState(() => _watchingAd = false);
    }
  }

  /// The tip this dialog is about (1-based), fixed when it opens: the page
  /// gains it on REVEAL while the dialog is still closing.
  late final int _tip =
      ref.read(gameControllerProvider).hintsFor(widget.mission.id) + 1;

  void _reveal(int tip) {
    if (_opening) return;
    if (ref.read(walletProvider).balance < WalletController.priceOf(tip) &&
        !ref.read(walletProvider).ownsTip(widget.mission.id, tip)) {
      return;
    }
    _opening = true;
    final saved = _saveTip(ref, widget.mission, tip);
    if (saved) {
      Navigator.of(context).pop(true);
    } else {
      // Not saved: nothing changes on the page; REVEAL can be tried again.
      setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tip = _tip;
    final wallet = ref.watch(walletProvider);
    final state = tipStateOf(tip: tip, revealed: tip - 1,
        owns: wallet.ownsTip(widget.mission.id, tip), balance: wallet.balance);
    return TipShopCard(
      balance: wallet.balance,
      price: WalletController.priceOf(tip),
      state: state,
      onCancel: () => Navigator.of(context).pop(false),
      onReveal: () => _reveal(tip),
      onWatchAd: ref.watch(rewardedAdGatewayProvider).isAvailable ? _watchAd : null,
      watchingAd: _watchingAd,
      rewardMessage: _rewardMessage,
    );
  }
}

/// The coins dialog as it looks: the question, the price said once, how it
/// is paid, CANCEL and GET MORE HINTS. What the buttons do is the caller's (the
/// puzzle's hint shop, or How to Play's practice, which spends nothing).
class TipShopCard extends StatelessWidget {
  const TipShopCard({
    super.key,
    required this.balance,
    required this.price,
    required this.state,
    required this.onCancel,
    required this.onReveal,
    this.onWatchAd,
    this.watchingAd = false,
    this.rewardMessage,
  });

  final int balance;
  final int price;
  final TipState state;
  final VoidCallback onCancel;
  final VoidCallback onReveal;
  final VoidCallback? onWatchAd;
  final bool watchingAd;
  final String? rewardMessage;

  @override
  Widget build(BuildContext context) {
    final paid = state == TipState.buy;
    final short = state == TipState.help;
    // The price leads; the title says what it buys; one line says how.
    final message = switch (state) {
      TipState.buy => 'Spend coins to get another hint.',
      TipState.help =>
        'Not enough coins! You have $balance ${balance == 1 ? 'coin' : 'coins'}.',
      TipState.yours => 'This hint is already yours. Read it again for free.',
      _ => 'This hint is free.',
    };
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: AppSpace.xl,
        vertical: AppSpace.lg,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: PaperSheet(
          ruled: true,
          padding: const EdgeInsets.fromLTRB(
            AppSpace.lg,
            AppSpace.xl,
            AppSpace.lg,
            AppSpace.lg,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Get Another Hint?',
                  textAlign: TextAlign.center,
                  style: AppText.title(size: 20),
                ),
                const SizedBox(height: AppSpace.md),
                // The price, said once and the first thing read.
                Semantics(
                  label: '$price coins',
                  excludeSemantics: true,
                  child: Row(
                    key: const ValueKey('tip-price'),
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const InkIcon(
                        InkGlyph.coin,
                        size: AppIconSize.medium + 4,
                        color: AppColors.goldDeep,
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '$price',
                              style:
                                  AppText.title(
                                    size: 32,
                                    color: AppColors.navy,
                                  ).copyWith(
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                            ),
                            TextSpan(
                              text: ' coins',
                              style: AppText.bodyText(
                                size: 17,
                                weight: FontWeight.w600,
                                color: AppColors.inkBrown,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  message,
                  key: const ValueKey('tip-message'),
                  textAlign: TextAlign.center,
                  style: AppText.bodyText(size: 15, color: AppColors.muted),
                ),
                if (rewardMessage != null) ...[
                  const SizedBox(height: AppSpace.lg),
                  Container(
                    key: const ValueKey('rewarded-ad-result'),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.md,
                      vertical: AppSpace.md,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.paperLight,
                      border: Border.all(color: AppColors.goldDeep),
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    child: Text(
                      rewardMessage!,
                      textAlign: TextAlign.center,
                      style: AppText.bodyText(
                        size: 15,
                        weight: FontWeight.w600,
                        color: AppColors.navy,
                      ),
                    ),
                  ),
                ],
                if (short && onWatchAd == null) ...[
                  const SizedBox(height: AppSpace.md),
                  Text(
                    'Watch an ad for 20 coins — Coming soon',
                    textAlign: TextAlign.center,
                    style: AppText.bodyText(size: 14, color: AppColors.muted),
                  ),
                ],
                const SizedBox(height: AppSpace.xl),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  children: [
                    CompactButton(label: 'CANCEL', onPressed: onCancel),
                    if (short && onWatchAd != null)
                      CompactButton(
                        label: watchingAd ? 'WATCHING...' : 'WATCH AD +20',
                        primary: true,
                        onPressed: watchingAd ? null : onWatchAd,
                      ),
                    if (!short)
                      CompactButton(
                        label: 'GET MORE HINTS',
                        primary: true,
                        semanticLabel: paid
                            ? 'Get more hints, $price coins'
                            : 'Get more hints, free',
                        onPressed: onReveal,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
