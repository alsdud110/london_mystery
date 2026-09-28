import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Illustrated, treasure-map style London. Pins are laid over it as widgets.
class LondonMapPainter extends CustomPainter {
  LondonMapPainter({required this.route, required this.completedLegs});

  /// Pin centres (fractions of the map size) in play order.
  final List<Offset> route;

  /// How many legs of [route] are already travelled.
  final int completedLegs;

  Offset _p(Size s, double x, double y) => Offset(x * s.width, y * s.height);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paper = RRect.fromRectAndRadius(rect, const Radius.circular(28));
    canvas.drawRRect(
      paper,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFFFF9EA), AppColors.parchment, Color(0xFFE6D2A5)],
          stops: [0, 0.7, 1],
        ).createShader(rect),
    );
    canvas.save();
    canvas.clipRRect(paper);

    _grid(canvas, size);
    _parks(canvas, size);
    _roads(canvas, size);
    _river(canvas, size);
    _route(canvas, size);
    _compass(canvas, _p(size, 0.86, 0.13), math.min(size.width, size.height) * 0.075);
    canvas.restore();

    canvas.drawRRect(
      paper.deflate(1.5),
      Paint()
        ..color = AppColors.inkBrown.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawRRect(
      paper.deflate(9),
      Paint()
        ..color = AppColors.inkBrown.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  void _grid(Canvas c, Size s) {
    final p = Paint()
      ..color = AppColors.inkBrown.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (var x = 0.0; x < s.width; x += 36) {
      c.drawLine(Offset(x, 0), Offset(x, s.height), p);
    }
    for (var y = 0.0; y < s.height; y += 36) {
      c.drawLine(Offset(0, y), Offset(s.width, y), p);
    }
  }

  void _parks(Canvas c, Size s) {
    final fill = Paint()..color = AppColors.park.withValues(alpha: 0.85);
    final edge = Paint()
      ..color = AppColors.parkDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final parks = [
      Rect.fromLTRB(s.width * 0.03, s.height * 0.31, s.width * 0.32, s.height * 0.53), // Hyde Park
      Rect.fromLTRB(s.width * 0.28, s.height * 0.03, s.width * 0.46, s.height * 0.17), // Regent's Park
      Rect.fromLTRB(s.width * 0.34, s.height * 0.60, s.width * 0.54, s.height * 0.70), // St James's Park
    ];
    for (final r in parks) {
      final rr = RRect.fromRectAndRadius(r, Radius.circular(r.shortestSide * 0.45));
      c.drawRRect(rr, fill);
      c.drawRRect(rr, edge);
      // Little trees.
      final rnd = math.Random(r.left.toInt());
      for (var i = 0; i < 6; i++) {
        final pt = Offset(
          r.left + r.width * (0.15 + rnd.nextDouble() * 0.7),
          r.top + r.height * (0.2 + rnd.nextDouble() * 0.6),
        );
        c.drawCircle(pt, 5, Paint()..color = AppColors.parkDeep);
      }
    }
    // The Serpentine lake in Hyde Park.
    final lake = Path()
      ..moveTo(s.width * 0.12, s.height * 0.47)
      ..quadraticBezierTo(s.width * 0.19, s.height * 0.44, s.width * 0.25, s.height * 0.37);
    c.drawPath(lake, Paint()
      ..color = AppColors.river
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round);
  }

  void _roads(Canvas c, Size s) {
    final casing = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    final line = Paint()
      ..color = AppColors.parchmentDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final roads = <Path>[
      Path()
        ..moveTo(0, s.height * 0.22)
        ..quadraticBezierTo(s.width * 0.5, s.height * 0.18, s.width, s.height * 0.26),
      Path()
        ..moveTo(s.width * 0.62, 0)
        ..quadraticBezierTo(s.width * 0.55, s.height * 0.4, s.width * 0.58, s.height * 0.7),
      Path()
        ..moveTo(0, s.height * 0.58)
        ..quadraticBezierTo(s.width * 0.4, s.height * 0.5, s.width * 0.95, s.height * 0.46),
      Path()
        ..moveTo(s.width * 0.34, s.height * 0.17)
        ..lineTo(s.width * 0.34, s.height * 0.57),
    ];
    for (final r in roads) {
      c.drawPath(r, casing);
      c.drawPath(r, line);
    }
  }

  void _river(Canvas c, Size s) {
    final river = Path()
      ..moveTo(-10, s.height * 0.80)
      ..cubicTo(s.width * 0.25, s.height * 0.95, s.width * 0.55, s.height * 0.92, s.width * 0.66, s.height * 0.74)
      ..cubicTo(s.width * 0.72, s.height * 0.60, s.width * 0.86, s.height * 0.66, s.width + 10, s.height * 0.62);
    c.drawPath(river, Paint()
      ..color = AppColors.riverDeep
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.width * 0.085
      ..strokeCap = StrokeCap.round);
    c.drawPath(river, Paint()
      ..color = AppColors.river
      ..style = PaintingStyle.stroke
      ..strokeWidth = s.width * 0.07
      ..strokeCap = StrokeCap.round);

    // Label along the river.
    final tp = TextPainter(
      text: TextSpan(
        text: 'RIVER THAMES',
        style: TextStyle(
          fontFamily: 'Cinzel',
          fontSize: math.max(10, s.width * 0.028),
          fontWeight: FontWeight.w700,
          fontVariations: const [FontVariation('wght', 700)],
          letterSpacing: 3,
          color: Colors.white.withValues(alpha: 0.9),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    c.save();
    c.translate(s.width * 0.28, s.height * 0.895);
    c.rotate(0.12);
    tp.paint(c, Offset(-tp.width / 2, -tp.height / 2));
    c.restore();
  }

  void _route(Canvas c, Size s) {
    if (route.length < 2) return;
    final done = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    final todo = Paint()
      ..color = AppColors.inkBrown.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < route.length - 1; i++) {
      final a = _p(s, route[i].dx, route[i].dy);
      final b = _p(s, route[i + 1].dx, route[i + 1].dy);
      final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2) + Offset((b.dy - a.dy) * 0.18, (a.dx - b.dx) * 0.18);
      final leg = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, b.dx, b.dy);
      if (i < completedLegs) {
        c.drawPath(leg, done);
      } else {
        _dashed(c, leg, todo);
      }
    }
  }

  void _dashed(Canvas c, Path path, Paint paint) {
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 16) {
        c.drawPath(metric.extractPath(d, math.min(d + 8, metric.length)), paint);
      }
    }
  }

  void _compass(Canvas c, Offset center, double r) {
    final ring = Paint()
      ..color = AppColors.inkBrown.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    c.drawCircle(center, r, Paint()..color = Colors.white.withValues(alpha: 0.5));
    c.drawCircle(center, r, ring);
    for (var i = 0; i < 4; i++) {
      final a = i * math.pi / 2 - math.pi / 2;
      final tip = center + Offset(math.cos(a), math.sin(a)) * r * 0.9;
      final left = center + Offset(math.cos(a - math.pi / 2), math.sin(a - math.pi / 2)) * r * 0.18;
      final right = center + Offset(math.cos(a + math.pi / 2), math.sin(a + math.pi / 2)) * r * 0.18;
      c.drawPath(
        Path()..addPolygon([tip, left, right], true),
        Paint()..color = i == 0 ? AppColors.waxRed : AppColors.navy,
      );
    }
    final tp = TextPainter(
      text: const TextSpan(
        text: 'N',
        style: TextStyle(fontFamily: 'Cinzel', fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.waxRed),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, center + Offset(-tp.width / 2, -r - tp.height - 1));
  }

  @override
  bool shouldRepaint(LondonMapPainter old) => old.completedLegs != completedLegs || old.route != route;
}
