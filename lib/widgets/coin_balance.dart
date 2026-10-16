import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../core/theme/app_tokens.dart';
import '../features/game/wallet_controller.dart';
import 'ink_icon.dart';

/// The detective's coins, quietly in the app bar beside the notebook: the
/// gold coin and the number, nothing to tap. The wallet is read from the
/// saves when the game starts, so the number is there from the first frame
/// (never a 0 that flickers). A change fades in briefly (not with Reduce
/// Motion).
class CoinBalance extends ConsumerWidget {
  const CoinBalance({super.key, this.dark = false});

  /// On the night bar (search, talk): lighter ink.
  final bool dark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(walletProvider.select((w) => w.balance));
    final still = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      label: 'Coins: $balance',
      excludeSemantics: true,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.2,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkIcon(InkGlyph.coin, size: AppIconSize.small, color: dark ? AppColors.goldLight : AppColors.goldDeep),
            const SizedBox(width: AppSpace.xs + 2),
            AnimatedSwitcher(
              duration: still ? Duration.zero : const Duration(milliseconds: 220),
              transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
              child: Text(
                '$balance',
                key: ValueKey(balance),
                style: AppText.bodyText(
                  size: 15,
                  weight: FontWeight.w700,
                  color: dark ? AppColors.paperLight : AppColors.navy,
                ).copyWith(fontFeatures: const [FontFeature.tabularFigures()], height: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
