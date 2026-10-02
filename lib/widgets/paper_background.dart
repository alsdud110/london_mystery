import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import 'london_skyline.dart';

/// The page every screen is printed on.
///
/// Paper: aged paper with a faint fibre grain, a few foxing spots and a soft
/// vignette, as if the page lay under a desk lamp. [night] switches to the
/// London night sky (story intro, title page and big reveals): a deep sky,
/// faint stars and the skyline standing on the bottom edge ([skyline]).
class PaperBackground extends StatelessWidget {
  const PaperBackground({super.key, required this.child, this.night = false, this.skyline = true});

  final Widget child;
  final bool night;

  /// Night only: London's skyline along the bottom of the page.
  final bool skyline;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: night ? AppColors.nightBottom : AppColors.paper,
      child: CustomPaint(
        painter: night ? _NightPainter(skyline: skyline) : const _PaperPainter(),
        child: InkSurface(night: night, child: child),
      ),
    );
  }
}

/// Tells ink widgets below whether they sit on the navy night background or
/// on paper, so a shared style (e.g. the outline `GameButton`) can pick a
/// readable ink. Paper laid on the night desk (`PaperSheet`) sets it back.
class InkSurface extends InheritedWidget {
  const InkSurface({super.key, required this.night, required super.child});

  final bool night;

  /// False (paper) when there is no surface above, e.g. in a bottom sheet.
  static bool isNight(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<InkSurface>()?.night ?? false;

  @override
  bool updateShouldNotify(InkSurface oldWidget) => night != oldWidget.night;
}

class _PaperPainter extends CustomPainter {
  const _PaperPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rnd = math.Random(7);

    // A few soft foxing spots, the age of the paper.
    for (var i = 0; i < 6; i++) {
      final at = Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height);
      final r = 40 + rnd.nextDouble() * 90;
      canvas.drawCircle(
        at,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [AppColors.parchmentDark.withValues(alpha: 0.10), AppColors.parchmentDark.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: at, radius: r)),
      );
    }

    // Fibre grain.
    final fibre = Paint()
      ..color = AppColors.inkBrown.withValues(alpha: 0.05)
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;
    final count = (size.width * size.height / 2600).clamp(40, 500).toInt();
    for (var i = 0; i < count; i++) {
      final at = Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height);
      final a = rnd.nextDouble() * math.pi;
      final len = 1.5 + rnd.nextDouble() * 4;
      canvas.drawLine(at, at + Offset(math.cos(a), math.sin(a)) * len, fibre);
    }

    // Lamp light: the middle of the page bright, the edges a little darker.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.25),
          radius: 1.05,
          colors: [
            AppColors.paperLight.withValues(alpha: 0.55),
            AppColors.paperLight.withValues(alpha: 0),
            AppColors.inkBrown.withValues(alpha: 0.10),
          ],
          stops: const [0, 0.55, 1],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _NightPainter extends CustomPainter {
  const _NightPainter({required this.skyline});

  final bool skyline;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.nightTop, AppColors.navy, AppColors.nightBottom],
          stops: [0, 0.55, 1],
        ).createShader(rect),
    );
    // Moonlight haze over the city, high up on the right.
    final haze = Rect.fromCircle(center: Offset(size.width * 0.78, size.height * 0.08), radius: size.width * 0.8);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [AppColors.goldLight.withValues(alpha: 0.10), AppColors.goldLight.withValues(alpha: 0)],
        ).createShader(haze),
    );

    final rnd = math.Random(11);
    for (var i = 0; i < 46; i++) {
      final paint = Paint()..color = AppColors.paperLight.withValues(alpha: 0.10 + rnd.nextDouble() * 0.3);
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height * 0.65),
        rnd.nextDouble() * 1.0 + 0.3,
        paint,
      );
    }

    if (skyline) {
      // The skyline, a little wider than a phone and never taller than a
      // fifth of the page, standing on the bottom edge.
      final width = math.min(size.width, size.height * 0.62);
      final h = LondonSkylinePainter.heightFor(width);
      canvas.save();
      canvas.translate((size.width - width) / 2, size.height - h);
      // Mist rising off the river behind the buildings.
      final mist = Rect.fromLTWH(-(size.width - width) / 2, -h * 0.6, size.width, h * 1.6);
      canvas.drawRect(
        mist,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.royalBlue.withValues(alpha: 0), AppColors.royalBlue.withValues(alpha: 0.26)],
          ).createShader(mist),
      );
      const LondonSkylinePainter().paint(canvas, Size(width, h));
      canvas.restore();
      if (width < size.width) {
        // The ground carries on to the edges of a wide page.
        canvas.drawRect(
          Rect.fromLTWH(0, size.height - h * 0.02, size.width, h * 0.02),
          Paint()..color = AppColors.nightSkyline,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_NightPainter old) => old.skyline != skyline;
}
