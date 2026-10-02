import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../core/theme/app_tokens.dart';
import '../features/game/scoring.dart';
import 'art_assets.dart';
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
          // A pressed award rosette: scalloped brass edge, an enamel face in
          // the badge's colour and a fine gold ring. Still to win: a pencil
          // outline of the same rosette with a lock.
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: _RosetteDecoration(earned: earned, face: color),
            child: earned
                ? InkMark(
                    glyph: badge.glyph,
                    asset: ArtAssets.badges[badge],
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
        style: (style ?? AppText.button(size: 14, color: Colors.white)).copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _RosetteDecoration extends Decoration {
  const _RosetteDecoration({required this.earned, required this.face});

  final bool earned;
  final Color face;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _RosettePainter(earned, face);
}

class _RosettePainter extends BoxPainter {
  _RosettePainter(this.earned, this.face);

  final bool earned;
  final Color face;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size!;
    final c = offset + size.center(Offset.zero);
    final r = size.shortestSide / 2;

    // The scalloped edge: 18 small bumps around the disc.
    const bumps = 18;
    final edge = Path();
    for (var i = 0; i <= bumps * 8; i++) {
      final a = i * 2 * math.pi / (bumps * 8);
      final rr = r * (0.93 + 0.07 * math.cos(a * bumps).abs());
      final p = c + Offset(math.cos(a) * rr, math.sin(a) * rr);
      i == 0 ? edge.moveTo(p.dx, p.dy) : edge.lineTo(p.dx, p.dy);
    }
    edge.close();

    if (!earned) {
      canvas.drawPath(edge, Paint()..color = AppColors.parchment);
      canvas.drawPath(
        edge,
        Paint()
          ..color = AppColors.parchmentDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = AppLine.rule,
      );
      return;
    }
    canvas.drawPath(edge.shift(Offset(0, r * 0.05)), Paint()..color = const Color(0x332A2622));
    canvas.drawPath(
      edge,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.goldLight, AppColors.gold, AppColors.goldDeep],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawCircle(c, r * 0.76, Paint()..color = face);
    canvas.drawCircle(
      c,
      r * 0.68,
      Paint()
        ..color = AppColors.goldLight.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, r / 40),
    );
  }
}
