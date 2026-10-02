import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'paper_background.dart';

/// The detective's desk: dark walnut with a faint grain, lit by a lamp from
/// above. The season pages lay their casebook, briefing and board on it.
///
/// Ink widgets below read it as a dark surface ([InkSurface] night), like
/// the night page: outline buttons and links turn to gold ink.
class DeskBackground extends StatelessWidget {
  const DeskBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.walnutDeep,
      child: CustomPaint(
        painter: const _DeskPainter(),
        child: InkSurface(night: true, child: child),
      ),
    );
  }
}

class _DeskPainter extends CustomPainter {
  const _DeskPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // The wood, a little lighter where the lamp falls.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.walnut, AppColors.walnutDeep],
        ).createShader(rect),
    );
    // Long, faint grain lines running across the top.
    final rnd = math.Random(11);
    final grain = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (var i = 0; i < 46; i++) {
      final y = rnd.nextDouble() * size.height;
      final wave = 2 + rnd.nextDouble() * 5;
      final path = Path()..moveTo(-10, y);
      for (var x = 0.0; x <= size.width + 40; x += 40) {
        path.lineTo(x, y + math.sin(x / 90 + i) * wave);
      }
      grain.color = (i.isEven ? Colors.black : AppColors.goldLight).withValues(alpha: i.isEven ? 0.10 : 0.025);
      canvas.drawPath(path, grain);
    }
    // The lamp: warm light from above, the corners in shadow.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.75),
          radius: 1.1,
          colors: [AppColors.goldLight.withValues(alpha: 0.13), Colors.transparent, Colors.black.withValues(alpha: 0.45)],
          stops: const [0, 0.55, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_DeskPainter old) => false;
}
