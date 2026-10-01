import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// An old paper map of London on which the detective marks the route in ink.
/// Pins are laid over it as widgets.
///
/// Route legs: solid ink between places already investigated, a red dashed
/// line to the current place (the way the detective is heading), and nothing
/// beyond it (the next stop is unknown).
class LondonMapPainter extends CustomPainter {
  LondonMapPainter({required this.route, required this.completedLegs, this.drawMap = true, this.heading})
    : super(repaint: heading);

  /// False when the map artwork is under this painter: only the route is
  /// inked on top of it.
  final bool drawMap;

  /// How much of the red dashed leg to the current place is drawn (0..1):
  /// it follows the camera as it travels there. Null draws all of it.
  final Animation<double>? heading;

  /// Pin centres (fractions of the map size) in play order.
  final List<Offset> route;

  /// How many places of [route] are already solved.
  final int completedLegs;

  Offset _p(Size s, double x, double y) => Offset(x * s.width, y * s.height);

  Paint _stroke(Color color, double width, {double alpha = 1}) => Paint()
    ..color = color.withValues(alpha: alpha)
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  @override
  void paint(Canvas canvas, Size size) {
    if (!drawMap) {
      _route(canvas, size);
      return;
    }
    final rect = Offset.zero & size;
    final paper = RRect.fromRectAndRadius(rect, const Radius.circular(6));
    canvas.drawRRect(paper, Paint()..color = AppColors.paperLight);
    canvas.save();
    canvas.clipRRect(paper);

    _parks(canvas, size);
    _roads(canvas, size);
    _river(canvas, size);
    _route(canvas, size);
    _compass(canvas, _p(size, 0.88, 0.1), math.min(size.width, size.height) * 0.055);
    canvas.restore();

    // Printed map frame: a line and a hairline.
    canvas.drawRRect(paper.deflate(1), _stroke(AppColors.ink, 1.5, alpha: 0.45));
    canvas.drawRRect(paper.deflate(7), _stroke(AppColors.ink, 0.8, alpha: 0.25));
  }

  void _parks(Canvas c, Size s) {
    final fill = Paint()..color = AppColors.park.withValues(alpha: 0.6);
    final edge = _stroke(AppColors.parkDeep, 1, alpha: 0.7);
    final parks = [
      Rect.fromLTRB(s.width * 0.03, s.height * 0.31, s.width * 0.32, s.height * 0.53), // Hyde Park
      Rect.fromLTRB(s.width * 0.28, s.height * 0.03, s.width * 0.46, s.height * 0.17), // Regent's Park
      Rect.fromLTRB(s.width * 0.34, s.height * 0.60, s.width * 0.54, s.height * 0.70), // St James's Park
    ];
    final tuft = _stroke(AppColors.parkDeep, 1, alpha: 0.8);
    for (final r in parks) {
      final shape = _blob(r, r.left.toInt());
      c.drawPath(shape, fill);
      c.drawPath(shape, edge);
      // A few pen-drawn trees.
      final rnd = math.Random(r.left.toInt());
      for (var i = 0; i < 3; i++) {
        final pt = Offset(r.left + r.width * (0.2 + rnd.nextDouble() * 0.6), r.top + r.height * (0.25 + rnd.nextDouble() * 0.5));
        c.drawCircle(pt, 3.5, tuft);
      }
    }
    // The Serpentine lake in Hyde Park.
    final lake = Path()
      ..moveTo(s.width * 0.12, s.height * 0.47)
      ..quadraticBezierTo(s.width * 0.19, s.height * 0.44, s.width * 0.25, s.height * 0.37);
    c.drawPath(lake, _stroke(AppColors.river, 6));
  }

  /// An irregular, hand-drawn outline filling [r] (same shape every frame).
  Path _blob(Rect r, int seed) {
    final rnd = math.Random(seed);
    const n = 9;
    final pts = [
      for (var i = 0; i < n; i++)
        () {
          final a = i * 2 * math.pi / n;
          final k = 0.86 + rnd.nextDouble() * 0.14;
          return r.center + Offset(math.cos(a) * r.width / 2 * k, math.sin(a) * r.height / 2 * k);
        }(),
    ];
    Offset mid(Offset a, Offset b) => Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    final start = mid(pts.last, pts.first);
    final path = Path()..moveTo(start.dx, start.dy);
    for (var i = 0; i < n; i++) {
      final m = mid(pts[i], pts[(i + 1) % n]);
      path.quadraticBezierTo(pts[i].dx, pts[i].dy, m.dx, m.dy);
    }
    return path..close();
  }

  void _roads(Canvas c, Size s) {
    final road = _stroke(AppColors.ink, 1.1, alpha: 0.18);
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
      // Double-line streets, as on printed maps.
      c.drawPath(r.shift(const Offset(0, -2.5)), road);
      c.drawPath(r.shift(const Offset(0, 2.5)), road);
    }
  }

  void _river(Canvas c, Size s) {
    final river = Path()
      ..moveTo(-10, s.height * 0.80)
      ..cubicTo(s.width * 0.25, s.height * 0.95, s.width * 0.55, s.height * 0.92, s.width * 0.66, s.height * 0.74)
      ..cubicTo(s.width * 0.72, s.height * 0.60, s.width * 0.86, s.height * 0.66, s.width + 10, s.height * 0.62);
    final w = s.width * 0.065;
    c.drawPath(river, _stroke(AppColors.riverDeep, w + 2, alpha: 0.6)); // inked banks
    c.drawPath(river, _stroke(AppColors.river, w));

    final tp = TextPainter(
      text: TextSpan(
        text: 'RIVER THAMES',
        style: TextStyle(
          fontFamily: 'Cinzel',
          fontSize: math.max(9, s.width * 0.024),
          fontWeight: FontWeight.w700,
          fontVariations: const [FontVariation('wght', 700)],
          letterSpacing: 3,
          color: AppColors.ink.withValues(alpha: 0.4),
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
    if (route.length < 2 || completedLegs == 0) return;
    final travelled = _stroke(AppColors.navy, 3);
    final shown = (heading?.value ?? 1).clamp(0.0, 1.0);

    for (var i = 0; i < route.length - 1; i++) {
      // Leg i leads from place i to place i + 1.
      final solvedTarget = i < completedLegs - 1;
      final toCurrent = i == completedLegs - 1;
      if (!solvedTarget && !toCurrent) break;
      final a = _p(s, route[i].dx, route[i].dy);
      final b = _p(s, route[i + 1].dx, route[i + 1].dy);
      final mid = Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2) + Offset((b.dy - a.dy) * 0.18, (a.dx - b.dx) * 0.18);
      final leg = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, b.dx, b.dy);
      if (solvedTarget) {
        c.drawPath(leg, travelled);
      } else {
        _heading(c, leg, shown);
      }
    }
  }

  /// The way to the current place: red ink dashes on a thin paper outline
  /// (so they read on the busy map), drawn up to [shown] of the way, with a
  /// small red dot at the pen while it is still drawing.
  void _heading(Canvas c, Path leg, double shown) {
    if (shown <= 0) return;
    final metric = leg.computeMetrics().first;
    final end = metric.length * shown;
    final outline = _stroke(AppColors.paperLight, 4.6, alpha: 0.85);
    final ink = _stroke(AppColors.burgundy, 2.6);
    for (final paint in [outline, ink]) {
      for (var d = 0.0; d < end; d += 14) {
        c.drawPath(metric.extractPath(d, math.min(d + 7, end)), paint);
      }
    }
    if (shown < 1) {
      final pen = metric.getTangentForOffset(end)?.position;
      if (pen != null) {
        c.drawCircle(pen, 4, Paint()..color = AppColors.paperLight);
        c.drawCircle(pen, 3, Paint()..color = AppColors.burgundy);
      }
    }
  }

  void _compass(Canvas c, Offset center, double r) {
    final ink = _stroke(AppColors.ink, 1.2, alpha: 0.6);
    c.drawCircle(center, r, ink);
    c.drawLine(center + Offset(0, -r * 1.25), center + Offset(0, r * 1.25), ink);
    c.drawLine(center + Offset(-r * 1.25, 0), center + Offset(r * 1.25, 0), ink);
    c.drawPath(
      Path()
        ..moveTo(center.dx, center.dy - r * 0.95)
        ..lineTo(center.dx - r * 0.25, center.dy)
        ..lineTo(center.dx + r * 0.25, center.dy)
        ..close(),
      Paint()..color = AppColors.burgundy.withValues(alpha: 0.8),
    );
    final tp = TextPainter(
      text: TextSpan(
        text: 'N',
        style: TextStyle(fontFamily: 'Cinzel', fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.ink.withValues(alpha: 0.7)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, center + Offset(-tp.width / 2, -r * 1.25 - tp.height - 1));
  }

  @override
  bool shouldRepaint(LondonMapPainter old) =>
      old.completedLegs != completedLegs || old.route != route || old.drawMap != drawMap || old.heading != heading;
}
