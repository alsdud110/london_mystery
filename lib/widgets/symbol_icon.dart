import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_tokens.dart';
import 'ink_icon.dart';

/// Picture keys used by clues, evidence and the Royal Box locks.
///
/// Each symbol is drawn with the Ink Icon System. [glyph] is null while its
/// drawing is still a Custom Asset Required; until then [InkMark] shows the
/// label's initial. Add the glyph to [InkGlyph] and set it here — no screen
/// needs to change.
class GameSymbol {
  const GameSymbol(this.label, this.color, {this.glyph, this.initial});

  final String label;
  final Color color;
  final InkGlyph? glyph;

  /// Monogram override; defaults to the label's first letter.
  final String? initial;

  String get monogram => initial ?? label.substring(0, 1).toUpperCase();

  static const _symbols = {
    // World symbols (Royal Box locks).
    'train': GameSymbol('Train', AppColors.burgundy), // King's Cross — steam train
    'museum': GameSymbol('Museum', AppColors.navy), // British Museum
    'clock': GameSymbol('Clock', AppColors.royalBlue), // Big Ben — clock tower
    'park': GameSymbol('Park', AppColors.success), // Hyde Park — tree
    'palace': GameSymbol('Palace', AppColors.burgundy), // Buckingham Palace
    'crown': GameSymbol('Crown', AppColors.goldDeep), // The Royal Box
    // Evidence objects.
    'letter': GameSymbol('Letter', AppColors.inkBrown, glyph: InkGlyph.letter),
    'key': GameSymbol('Key', AppColors.goldDeep),
    'watch': GameSymbol('Watch', AppColors.navy),
    'map': GameSymbol('Map', AppColors.royalBlue),
  };

  static GameSymbol of(String? key) =>
      _symbols[key] ?? const GameSymbol('Mystery', AppColors.muted, initial: '?');

  /// The symbol drawn at [size] (its glyph, or its monogram for now).
  Widget mark({double size = AppIconSize.regular, Color? color}) =>
      InkMark(glyph: glyph, monogram: monogram, size: size, color: color ?? this.color);
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
    return Semantics(
      label: s.label,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: light ? Colors.white : s.color.withValues(alpha: 0.14),
          shape: BoxShape.circle,
          border: Border.all(color: s.color, width: size / 16),
        ),
        child: s.mark(size: size * 0.56),
      ),
    );
  }
}
