import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Warm "old paper" backdrop used across the game. [night] switches to the
/// friendly navy night-sky used for the story intro and big reveals.
class PaperBackground extends StatelessWidget {
  const PaperBackground({super.key, required this.child, this.night = false});

  final Widget child;
  final bool night;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: night
            ? const RadialGradient(
                center: Alignment(0, -0.4),
                radius: 1.3,
                colors: [Color(0xFF2A3E6B), AppColors.navy, AppColors.navyDeep],
                stops: [0, 0.55, 1],
              )
            : const RadialGradient(
                center: Alignment(0, -0.3),
                radius: 1.25,
                colors: [Color(0xFFFFFBF1), AppColors.paper, Color(0xFFF0E4C8)],
                stops: [0, 0.6, 1],
              ),
      ),
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
    final speck = Paint()..color = AppColors.inkBrown.withValues(alpha: 0.05);
    final count = (size.width * size.height / 2600).clamp(60, 600).toInt();
    for (var i = 0; i < count; i++) {
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
        rnd.nextDouble() * 1.3 + 0.3,
        speck,
      );
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
    for (var i = 0; i < 70; i++) {
      final paint = Paint()..color = Colors.white.withValues(alpha: 0.15 + rnd.nextDouble() * 0.5);
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height * 0.75),
        rnd.nextDouble() * 1.4 + 0.3,
        paint,
      );
    }
    // Moon.
    final moon = Offset(size.width * 0.82, size.height * 0.12);
    canvas.drawCircle(moon, 34, Paint()..color = AppColors.goldLight.withValues(alpha: 0.12));
    canvas.drawCircle(moon, 20, Paint()..color = AppColors.goldLight.withValues(alpha: 0.45));
    canvas.drawCircle(moon + const Offset(8, -5), 17, Paint()..color = AppColors.navy.withValues(alpha: 0.95));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
