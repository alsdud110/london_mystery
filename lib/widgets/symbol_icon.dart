import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_tokens.dart';
import 'art_assets.dart';
import 'ink_icon.dart';

/// Picture keys used by clues, evidence and the Royal Box locks.
///
/// Each symbol is drawn with the Ink Icon System. [glyph] is null while its
/// drawing is still a Custom Asset Required; until then [InkMark] shows the
/// label's initial. Add the glyph to [InkGlyph] and set it here — no screen
/// needs to change.
class GameSymbol {
  const GameSymbol(this.label, this.color, {this.glyph, this.initial, this.asset});

  final String label;
  final Color color;
  final InkGlyph? glyph;

  /// Monogram override; defaults to the label's first letter.
  final String? initial;

  /// The finished picture file, once one is listed in [ArtAssets.symbols].
  final String? asset;

  String get monogram => initial ?? label.substring(0, 1).toUpperCase();

  static const _symbols = {
    // World symbols (Royal Box locks).
    'train': GameSymbol('Train', AppColors.burgundy, glyph: InkGlyph.train), // King's Cross
    'museum': GameSymbol('Museum', AppColors.navy), // British Museum
    'clock': GameSymbol('Clock', AppColors.royalBlue, glyph: InkGlyph.clock), // Big Ben
    'park': GameSymbol('Park', AppColors.success), // Hyde Park — tree
    'palace': GameSymbol('Palace', AppColors.burgundy), // Buckingham Palace
    'crown': GameSymbol('Crown', AppColors.goldDeep), // The Royal Box
    'raven': GameSymbol('Raven', AppColors.ink, glyph: InkGlyph.raven), // The Raven Society
    'gear': GameSymbol(
      'Gear',
      AppColors.inkBrown,
      glyph: InkGlyph.gear,
    ), // The Clockmaker (not gold: it sits on brass locks)
    // Evidence objects.
    'letter': GameSymbol('Letter', AppColors.inkBrown, glyph: InkGlyph.letter),
    'key': GameSymbol('Key', AppColors.goldDeep, glyph: InkGlyph.key),
    'watch': GameSymbol('Watch', AppColors.navy, glyph: InkGlyph.clock),
    'map': GameSymbol('Map', AppColors.royalBlue, glyph: InkGlyph.map),
    'ticket': GameSymbol('Card', AppColors.inkBrown, glyph: InkGlyph.ticket),
    'feather': GameSymbol('Feather', AppColors.ink, glyph: InkGlyph.feather),
    'footprint': GameSymbol('Footprint', AppColors.royalBlue, glyph: InkGlyph.footprint),
    'button': GameSymbol('Button', AppColors.burgundy, glyph: InkGlyph.button),
    'cloth': GameSymbol('Cloth', AppColors.royalBlue, glyph: InkGlyph.cloth),
    'seal': GameSymbol('Seal', AppColors.burgundy, glyph: InkGlyph.seal),
    'frame': GameSymbol('Painting', AppColors.goldDeep, glyph: InkGlyph.frame),
    'mask': GameSymbol('Mask', AppColors.navy, glyph: InkGlyph.mask),
    'gem': GameSymbol('Jewel', AppColors.royalBlue, glyph: InkGlyph.gem),
    'bag': GameSymbol('Bag', AppColors.inkBrown, glyph: InkGlyph.bag),
    'umbrella': GameSymbol('Umbrella', AppColors.burgundy, glyph: InkGlyph.umbrella),
    'whistle': GameSymbol('Whistle', AppColors.navy, glyph: InkGlyph.whistle),
  };

  static GameSymbol of(String? key) {
    final s = _symbols[key] ?? const GameSymbol('Mystery', AppColors.muted, initial: '?');
    final file = ArtAssets.symbols[key];
    return file == null ? s : GameSymbol(s.label, s.color, glyph: s.glyph, initial: s.initial, asset: file);
  }

  /// The symbol drawn at [size] (its picture file, its glyph, or its monogram for now).
  Widget mark({double size = AppIconSize.regular, Color? color}) =>
      InkMark(glyph: glyph, monogram: monogram, size: size, color: color ?? this.color, asset: asset);
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
          color: light ? AppColors.paperLight : s.color.withValues(alpha: 0.14),
          shape: BoxShape.circle,
          border: Border.all(color: s.color, width: size / 16),
        ),
        child: s.mark(size: size * 0.56),
      ),
    );
  }
}
