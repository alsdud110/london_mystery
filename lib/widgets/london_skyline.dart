import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// A pen-and-ink London skyline (terraces, St Paul's, Big Ben, Parliament,
/// Tower Bridge) standing on the bottom edge of the page.
class LondonSkyline extends StatelessWidget {
  const LondonSkyline({super.key});

  @override
  Widget build(BuildContext context) {
    return const ExcludeSemantics(
      child: AspectRatio(aspectRatio: 100 / 30, child: CustomPaint(painter: _SkylinePainter())),
    );
  }
}

/// Drawn on a 100 × 30 grid, scaled evenly to the available width.
class _SkylinePainter extends CustomPainter {
  const _SkylinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    final s = size.width / 100;
    canvas.scale(s, s);

    final wash = Paint()..color = AppColors.parchment;
    final ink = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.35
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    final sketch = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.2;

    void shape(Path p) {
      canvas.drawPath(p, wash);
      canvas.drawPath(p, ink);
      canvas.drawPath(p.shift(const Offset(0.15, 0.12)), sketch);
    }

    Path rect(double l, double t, double r, double b) => Path()..addRect(Rect.fromLTRB(l, t, r, b));
    Path poly(List<Offset> pts) => Path()..addPolygon(pts, true);

    // Terraced houses on the left.
    for (final (l, r, top) in [(0.0, 6.0, 22.0), (6.0, 11.0, 20.0), (11.0, 16.0, 23.0)]) {
      shape(poly([Offset(l, 30), Offset(l, top), Offset((l + r) / 2, top - 3), Offset(r, top), Offset(r, 30)]));
      canvas.drawLine(Offset((l + r) / 2, top + 2), Offset((l + r) / 2, top + 4), ink);
    }

    // St Paul's Cathedral.
    shape(rect(17, 21, 30, 30));
    shape(rect(20, 16, 27, 21));
    shape(Path()
      ..moveTo(19.5, 16)
      ..arcToPoint(const Offset(27.5, 16), radius: const Radius.circular(4))
      ..close());
    canvas.drawLine(const Offset(23.5, 12), const Offset(23.5, 9.5), ink);

    // Big Ben.
    shape(rect(36, 8, 40.5, 30));
    shape(poly(const [Offset(36, 8), Offset(38.25, 2), Offset(40.5, 8)]));
    canvas.drawCircle(const Offset(38.25, 11), 1.4, wash);
    canvas.drawCircle(const Offset(38.25, 11), 1.4, ink);

    // Houses of Parliament.
    shape(rect(40.5, 19, 63, 30));
    for (var x = 43.0; x < 62; x += 4) {
      shape(rect(x, 16.5, x + 1.2, 19));
      canvas.drawLine(Offset(x + 0.6, 22), Offset(x + 0.6, 27), sketch);
    }
    shape(rect(63, 13, 67, 30));

    // Tower Bridge.
    for (final l in [73.0, 86.0]) {
      shape(rect(l, 12, l + 4, 30));
      shape(poly([Offset(l - 0.3, 12), Offset(l + 2, 8), Offset(l + 4.3, 12)]));
    }
    canvas.drawLine(const Offset(77, 14), const Offset(86, 14), ink);
    canvas.drawLine(const Offset(77, 15.5), const Offset(86, 15.5), ink);
    canvas.drawLine(const Offset(67, 24), const Offset(100, 24), ink);
    canvas.drawPath(
      Path()
        ..moveTo(67, 20)
        ..quadraticBezierTo(71, 20, 73, 13),
      ink,
    );
    canvas.drawPath(
      Path()
        ..moveTo(100, 20)
        ..quadraticBezierTo(92, 20, 90, 13),
      ink,
    );

    // The ground line.
    canvas.drawLine(const Offset(0, 30), const Offset(100, 30), ink..strokeWidth = 0.5);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
