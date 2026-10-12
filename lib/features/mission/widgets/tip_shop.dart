import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/models/mission.dart';
import '../../../widgets/game_button.dart';
import '../../../widgets/ink_icon.dart';
import '../../../widgets/paper.dart';
import '../../game/game_controller.dart';
import '../../game/wallet_controller.dart';

/// What the next Detective Tip is, in the GET A TIP dialog.
enum TipState {
  /// Already written on the puzzle page.
  onPage,

  /// The detective's (opened in an earlier run): read again for free.
  yours,

  /// The next tip, free (tip 1).
  free,

  /// The next tip, paid for with coins.
  buy,

  /// The next tip, more than the coins in hand: given free as help.
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

/// GET A TIP: a small paper dialog over the puzzle. The detective's coins,
/// the next tip's price (or FREE), CANCEL and REVEAL. REVEAL writes the tip
/// on the puzzle page and closes it; CANCEL (or a tap outside) changes
/// nothing. Returns true when a tip was revealed.
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

  /// The tip this dialog is about (1-based), fixed when it opens: the page
  /// gains it on REVEAL while the dialog is still closing.
  late final int _tip = ref.read(gameControllerProvider).hintsFor(widget.mission.id) + 1;

  void _reveal(int tip) {
    if (_opening) return;
    _opening = true;
    final m = widget.mission;
    ref.read(walletProvider.notifier).unlockTip(m, tip);
    ref.read(gameControllerProvider.notifier).useHint(m);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mission;
    final wallet = ref.watch(walletProvider);
    final balance = wallet.balance;
    final tip = _tip;
    final price = WalletController.priceOf(tip);
    final state = tipStateOf(tip: tip, revealed: tip - 1, owns: wallet.ownsTip(m.id, tip), balance: balance);
    final paid = state == TipState.buy;
    final message = switch (state) {
      TipState.buy => 'Use $price coins to reveal this clue.',
      TipState.help => 'Your partner helps you for free this time.',
      TipState.yours => 'This tip is already yours. Read it again for free.',
      _ => 'Reveal this clue for free.',
    };
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpace.xl, vertical: AppSpace.lg),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: PaperSheet(
          ruled: true,
          padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.lg, AppSpace.lg),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // The coins in hand.
                Text('YOUR TOTAL COINS', textAlign: TextAlign.center, style: AppText.eyebrow()),
                const SizedBox(height: AppSpace.xs),
                Semantics(
                  label: 'Your total coins: $balance',
                  excludeSemantics: true,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const InkIcon(InkGlyph.coin, size: AppIconSize.medium, color: AppColors.goldDeep),
                      const SizedBox(width: AppSpace.sm),
                      Text(
                        '$balance',
                        key: const ValueKey('tip-shop-balance'),
                        style: AppText.title(size: 28, color: AppColors.navy)
                            .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.sm),
                const Center(child: OrnamentRule(width: 96)),
                const SizedBox(height: AppSpace.md),
                // The question, and what it costs.
                Text('Reveal a tip?', textAlign: TextAlign.center, style: AppText.title(size: 22)),
                const SizedBox(height: AppSpace.xs),
                Text(message, textAlign: TextAlign.center, style: AppText.bodyText(size: 16, color: AppColors.inkBrown)),
                const SizedBox(height: AppSpace.sm),
                Row(
                  key: const ValueKey('tip-price'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (paid) ...[
                      const InkIcon(InkGlyph.coin, size: AppIconSize.small, color: AppColors.goldDeep),
                      const SizedBox(width: AppSpace.xs),
                    ],
                    Text(
                      paid ? '$price\u00A0Coins' : 'FREE',
                      style: AppText.bodyText(size: 18, weight: FontWeight.w700, color: AppColors.navy),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.lg),
                Row(
                  children: [
                    Expanded(
                      child: GameButton(
                        label: 'CANCEL',
                        style: GameButtonStyle.outline,
                        singleLine: true,
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ),
                    const SizedBox(width: AppSpace.sm),
                    Expanded(
                      child: GameButton(
                        label: 'REVEAL',
                        semanticLabel: paid ? 'Reveal, $price coins' : 'Reveal, free',
                        singleLine: true,
                        onPressed: () => _reveal(tip),
                      ),
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
