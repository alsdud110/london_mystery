import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Picture keys used by clues, evidence and the Royal Box locks.
/// Drawn with Material icons so they render offline on every platform.
class GameSymbol {
  const GameSymbol(this.icon, this.color, this.label);

  final IconData icon;
  final Color color;
  final String label;

  static const _symbols = {
    'train': GameSymbol(Icons.train_rounded, Color(0xFFB8403A), 'Train'),
    'museum': GameSymbol(Icons.account_balance_rounded, Color(0xFF8A5CC7), 'Museum'),
    'clock': GameSymbol(Icons.access_time_filled_rounded, AppColors.royalBlue, 'Clock'),
    'park': GameSymbol(Icons.park_rounded, Color(0xFF3E9B6A), 'Park'),
    'crown': GameSymbol(Icons.workspace_premium_rounded, AppColors.goldDeep, 'Crown'),
    // Evidence objects.
    'letter': GameSymbol(Icons.mail_rounded, AppColors.inkBrown, 'Letter'),
    'key': GameSymbol(Icons.key_rounded, AppColors.goldDeep, 'Key'),
    'watch': GameSymbol(Icons.watch_later_rounded, AppColors.navy, 'Watch'),
    'map': GameSymbol(Icons.map_rounded, Color(0xFF2E8FA3), 'Map'),
  };

  static GameSymbol of(String? key) =>
      _symbols[key] ?? const GameSymbol(Icons.help_rounded, AppColors.muted, 'Mystery');
}

/// A round "stamp" showing a symbol.
class SymbolBadge extends StatelessWidget {
  const SymbolBadge(this.symbol, {super.key, this.size = 44, this.light = false});

  final String? symbol;
  final double size;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final s = GameSymbol.of(symbol);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: light ? Colors.white : s.color.withValues(alpha: 0.14),
        shape: BoxShape.circle,
        border: Border.all(color: s.color, width: size / 16),
      ),
      child: Icon(s.icon, color: s.color, size: size * 0.56, semanticLabel: s.label),
    );
  }
}
