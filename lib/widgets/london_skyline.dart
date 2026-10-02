import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// London at night: the skyline (terraces, St Paul's, Big Ben, Parliament,
/// the London Eye, Tower Bridge) as one dark silhouette with a few lit
/// windows, standing on the bottom edge of the night sky.
class LondonSkyline extends StatelessWidget {
  const LondonSkyline({super.key, this.color = AppColors.nightSkyline});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: AspectRatio(aspectRatio: 100 / 30, child: CustomPaint(painter: LondonSkylinePainter(color: color))),
    );
  }
}

/// Drawn on a 100 × 30 grid, scaled evenly to the width it is given and
/// standing on the bottom of the canvas (so it can sit under any page).
class LondonSkylinePainter extends CustomPainter {
  const LondonSkylinePainter({this.color = AppColors.nightSkyline, this.windows = true});

  final Color color;
  final bool windows;

  /// Height of the skyline for a page [width].
  static double heightFor(double width) => width * 0.3;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 100;
    canvas.save();
    canvas.translate(0, size.height - 30 * s);
    canvas.scale(s, s);

    final body = Paint()..color = color;
    final far = Paint()..color = Color.lerp(color, AppColors.nightTop, 0.45)!;
    Path rect(double l, double t, double r, double b) => Path()..addRect(Rect.fromLTRB(l, t, r, b));
    Path poly(List<Offset> pts) => Path()..addPolygon(pts, true);

    // The far row: St Paul's dome and the London Eye, softer in the haze.
    final back = Path()
      ..addPath(rect(18, 20, 31, 30), Offset.zero)
      ..addPath(rect(21, 15, 28, 20), Offset.zero)
      ..addPath(
        Path()
          ..moveTo(20, 15.5)
          ..arcToPoint(const Offset(29, 15.5), radius: const Radius.circular(4.5))
          ..close(),
        Offset.zero,
      )
      ..addPath(rect(24.2, 8.5, 24.8, 11.5), Offset.zero);
    canvas.drawPath(back, far);
    final eye = Paint()
      ..color = far.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.45;
    const hub = Offset(69, 15);
    canvas.drawCircle(hub, 9, eye);
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      canvas.drawLine(hub, hub + Offset(math.cos(a), math.sin(a)) * 9, eye..strokeWidth = 0.18);
    }
    canvas.drawPath(poly(const [Offset(66, 30), Offset(69, 15), Offset(72, 30)]), far);

    // The near row, one dark mass.
    final near = Path()
      // Terraced houses with chimneys.
      ..addPath(poly(const [Offset(0, 30), Offset(0, 21), Offset(3, 18), Offset(6, 21), Offset(6, 30)]), Offset.zero)
      ..addPath(poly(const [Offset(6, 30), Offset(6, 22), Offset(9, 19.5), Offset(12, 22), Offset(12, 30)]), Offset.zero)
      ..addPath(poly(const [Offset(12, 30), Offset(12, 23.5), Offset(15, 21), Offset(18, 23.5), Offset(18, 30)]), Offset.zero)
      ..addPath(rect(1.5, 17, 2.4, 19.5), Offset.zero)
      ..addPath(rect(10, 18.5, 10.9, 21), Offset.zero)
      ..addPath(rect(30, 24, 36, 30), Offset.zero)
      // Big Ben.
      ..addPath(rect(36.5, 9, 41, 30), Offset.zero)
      ..addPath(rect(36, 8, 41.5, 9.5), Offset.zero)
      ..addPath(poly(const [Offset(36.3, 8), Offset(38.75, 1.5), Offset(41.2, 8)]), Offset.zero)
      // The Houses of Parliament, with their little spires.
      ..addPath(rect(41, 19.5, 62, 30), Offset.zero)
      ..addPath(rect(62, 14, 65.5, 30), Offset.zero)
      ..addPath(poly(const [Offset(62, 14), Offset(63.75, 11), Offset(65.5, 14)]), Offset.zero);
    for (var x = 43.0; x < 61; x += 3.5) {
      near.addPath(poly([Offset(x, 19.5), Offset(x + 0.6, 16.5), Offset(x + 1.2, 19.5)]), Offset.zero);
    }
    near
      // Tower Bridge.
      ..addPath(rect(76, 12, 80, 30), Offset.zero)
      ..addPath(rect(88, 12, 92, 30), Offset.zero)
      ..addPath(poly(const [Offset(75.7, 12), Offset(78, 7.5), Offset(80.3, 12)]), Offset.zero)
      ..addPath(poly(const [Offset(87.7, 12), Offset(90, 7.5), Offset(92.3, 12)]), Offset.zero)
      ..addPath(rect(80, 13.6, 88, 14.6), Offset.zero)
      ..addPath(rect(72, 23.5, 100, 25), Offset.zero)
      ..addPath(rect(0, 29.4, 100, 30), Offset.zero);
    canvas.drawPath(near, body);
    final cable = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.4;
    canvas.drawPath(Path()..moveTo(72, 21)..quadraticBezierTo(74.5, 20, 76, 13), cable);
    canvas.drawPath(Path()..moveTo(100, 21)..quadraticBezierTo(94, 20, 92, 13), cable);

    if (windows) {
      // The clock face, and a few windows still lit at 10:42 pm.
      canvas.drawCircle(const Offset(38.75, 11.6), 1.25, Paint()..color = AppColors.goldLight.withValues(alpha: 0.55));
      final lit = Paint()..color = AppColors.goldLight.withValues(alpha: 0.4);
      for (final w in const [
        Offset(2.5, 24), Offset(8.5, 25.5), Offset(14.5, 26), Offset(32, 26.5),
        Offset(44, 23), Offset(50, 25), Offset(55.5, 23), Offset(59, 26), Offset(63, 18),
        Offset(77.4, 16), Offset(89.4, 19),
      ]) {
        canvas.drawRect(Rect.fromLTWH(w.dx, w.dy, 0.9, 1.3), lit);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(LondonSkylinePainter old) => old.color != color || old.windows != windows;
}
