import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../core/theme/app_tokens.dart';
import '../core/utils/formatters.dart';
import '../data/models/mission.dart';
import 'ink_icon.dart';
import 'symbol_icon.dart';

/// A notebook page entry: "CLUE #01 — Platform 9".
class ClueCard extends StatelessWidget {
  const ClueCard({super.key, required this.clue, required this.index, this.location, this.highlight = false});

  final Clue clue;
  final int index;
  final String? location;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    // An index card: a red rule along the top, pale blue lines below.
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.paperLight,
        borderRadius: BorderRadius.circular(AppRadius.paper),
        border: Border.all(color: highlight ? AppColors.gold : AppLine.faint(0.2), width: highlight ? 2.5 : AppLine.hairline),
        boxShadow: AppShadow.paperLift,
      ),
      foregroundDecoration: const _IndexCardRules(),
      child: Row(
        children: [
          SizedBox(
            width: 76,
            height: 72,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.gold.withValues(alpha: 0.7), width: AppLine.rule),
                  ),
                  child: FittedBox(
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Text(clue.value, style: AppText.title(size: 26, color: AppColors.goldLight)),
                    ),
                  ),
                ),
                // The picture that links this clue to a lock on the Royal Box.
                if (clue.symbol != null)
                  Positioned(right: 0, bottom: 0, child: SymbolBadge(clue.symbol, size: 32, light: true)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(Formatters.clueNumber(index), style: AppText.eyebrow()),
                const SizedBox(height: 2),
                Text('"${clue.title}"', style: AppText.title(size: 21)),
                const SizedBox(height: 4),
                Text(clue.note, style: AppText.bodyText(size: 15, color: AppColors.muted)),
                if (location != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const InkIcon(InkGlyph.pin, size: AppIconSize.small, color: AppColors.royalBlue),
                      const SizedBox(width: 4),
                      Flexible(child: Text(location!, style: AppText.caption(color: AppColors.royalBlue))),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The printed lines of an index card, over the card's paper.
class _IndexCardRules extends Decoration {
  const _IndexCardRules();

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _IndexCardRulesPainter();
}

class _IndexCardRulesPainter extends BoxPainter {
  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final r = offset & configuration.size!;
    canvas.drawLine(
      Offset(r.left, r.top + 8),
      Offset(r.right, r.top + 8),
      Paint()
        ..color = AppColors.burgundy.withValues(alpha: 0.45)
        ..strokeWidth = AppLine.hairline,
    );
  }
}
