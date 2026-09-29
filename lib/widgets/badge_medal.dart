import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../features/game/scoring.dart';
import 'ink_icon.dart';

/// A round medal for a [GameBadge]. Locked badges are shown as grey outlines
/// so children can see what is still to discover.
class BadgeMedal extends StatelessWidget {
  const BadgeMedal({super.key, required this.badge, this.earned = true, this.size = 64, this.showLabel = true});

  final GameBadge badge;
  final bool earned;
  final double size;
  final bool showLabel;

  @override
  Widget build(BuildContext context) {
    final color = earned ? badge.color : AppColors.locked;
    return Semantics(
      label: '${badge.title}, ${earned ? 'earned' : 'not yet earned'}',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // A flat pressed medal: one ink colour, gold rim (no gradient or glow).
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: earned ? color : AppColors.parchment,
              border: Border.all(color: earned ? AppColors.gold : AppColors.parchmentDark, width: size / 16),
            ),
            child: earned
                ? InkMark(
                    glyph: badge.glyph,
                    monogram: badge.title.substring(0, 1),
                    size: size * 0.5,
                    color: AppColors.paperLight,
                  )
                : InkIcon(InkGlyph.lock, size: size * 0.5, color: color),
          ),
          if (showLabel) ...[
            const SizedBox(height: 6),
            _TwoLineText(
              badge.title,
              width: size + 36,
              style: AppText.button(size: 13, color: earned ? AppColors.navy : AppColors.muted),
            ),
            _TwoLineText(badge.description, width: size + 36, style: AppText.caption()),
          ],
        ],
      ),
    );
  }
}

/// Text that always takes the height of two lines, so medals line up at the
/// same size whether a label wraps or not (at any text scale).
class _TwoLineText extends StatelessWidget {
  const _TwoLineText(this.text, {required this.width, required this.style});

  final String text;
  final double width;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Opacity(opacity: 0, child: Text('\n', style: style)), // reserves two lines
          Text(text, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: style),
        ],
      ),
    );
  }
}

/// Smoothly counts from the previous value to [value] ("340 XP").
class XpCounter extends StatelessWidget {
  const XpCounter({super.key, required this.value, this.style, this.suffix = ' XP'});

  final int value;
  final TextStyle? style;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(end: value),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(
        '$v$suffix',
        style: (style ?? AppText.button(size: 14, color: Colors.white))
            .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
      ),
    );
  }
}
