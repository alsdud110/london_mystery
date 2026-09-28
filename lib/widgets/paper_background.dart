import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Flat aged-paper backdrop used across the game (no gradients: just the
/// paper colour and a faint fibre grain). [night] switches to the navy
/// night sky used for the story intro and big reveals.
class PaperBackground extends StatelessWidget {
  const PaperBackground({super.key, required this.child, this.night = false});

  final Widget child;
  final bool night;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: night ? AppColors.navy : AppColors.paper,
      child: CustomPaint(
        painter: night ? const _StarsPainter() : const _PaperGrainPainter(),
        child: child,
      ),
    );
  }
}

class _PaperGrainPainter extends CustomPainter {
  const _PaperGrainPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    final fibre = Paint()
      ..color = AppColors.inkBrown.withValues(alpha: 0.05)
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;
    final count = (size.width * size.height / 3200).clamp(40, 400).toInt();
    for (var i = 0; i < count; i++) {
      final at = Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height);
      final a = rnd.nextDouble() * math.pi;
      final len = 1.5 + rnd.nextDouble() * 4;
      canvas.drawLine(at, at + Offset(math.cos(a), math.sin(a)) * len, fibre);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _StarsPainter extends CustomPainter {
  const _StarsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(11);
    for (var i = 0; i < 40; i++) {
      final paint = Paint()..color = AppColors.paperLight.withValues(alpha: 0.12 + rnd.nextDouble() * 0.3);
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height * 0.7),
        rnd.nextDouble() * 1.1 + 0.3,
        paint,
      );
    }
    // A thin crescent moon, drawn as ink on the night paper.
    final moon = Offset(size.width * 0.82, size.height * 0.1);
    final crescent = Path.combine(
      PathOperation.difference,
      Path()..addOval(Rect.fromCircle(center: moon, radius: 16)),
      Path()..addOval(Rect.fromCircle(center: moon + const Offset(6, -4), radius: 14)),
    );
    canvas.drawPath(crescent, Paint()..color = AppColors.goldLight.withValues(alpha: 0.55));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
