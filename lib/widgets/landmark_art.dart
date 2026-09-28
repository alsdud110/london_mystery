import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/models/mission.dart';

/// Flat, storybook-style illustrations of London landmarks, drawn in code so
/// the app ships small and works offline.
class LandmarkArt extends StatelessWidget {
  const LandmarkArt(this.artwork, {super.key, this.borderRadius = 24, this.showSky = true});

  final Artwork artwork;
  final double borderRadius;
  final bool showSky;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: CustomPaint(
        painter: _LandmarkPainter(artwork, showSky: showSky),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _LandmarkPainter extends CustomPainter {
  _LandmarkPainter(this.artwork, {required this.showSky});

  final Artwork artwork;
  final bool showSky;

  static const _stone = Color(0xFFEADFC8);
  static const _stoneShade = Color(0xFFD3C4A3);
  static const _brick = Color(0xFFC98A62);
  static const _leather = Color(0xFF9A5B34);
  static const _leatherDark = Color(0xFF6E3E22);
  static const _window = Color(0xFF8FB3DB);
  static const _guardRed = Color(0xFFD2463C);

  Paint _fill(Color c) => Paint()..color = c;

  Paint get _ink => Paint()
    ..color = AppColors.navy
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.4
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  void _box(Canvas c, double l, double t, double r, double b, Color color, {double radius = 0.6}) {
    final rr = RRect.fromLTRBR(l, t, r, b, Radius.circular(radius));
    c.drawRRect(rr, _fill(color));
    c.drawRRect(rr, _ink);
  }

  void _poly(Canvas c, List<Offset> pts, Color color) {
    final path = Path()..addPolygon(pts, true);
    c.drawPath(path, _fill(color));
    c.drawPath(path, _ink);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Background fills the whole card.
    final bg = Rect.fromLTWH(0, 0, size.width, size.height);
    if (showSky) {
      canvas.drawRect(
        bg,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFCFE2F5), Color(0xFFF7EFDC)],
          ).createShader(bg),
      );
    }

    // Draw the scene in a centred 100x100 unit box.
    final s = math.min(size.width, size.height) / 100;
    canvas.save();
    canvas.translate((size.width - 100 * s) / 2, (size.height - 100 * s) / 2);
    canvas.scale(s);

    if (showSky) {
      // Ground strip extends across the full card width.
      final extra = (size.width / s - 100) / 2 + 1;
      canvas.drawRect(Rect.fromLTRB(-extra, 84, 100 + extra, 140), _fill(_groundColor));
      _clouds(canvas);
    }

    switch (artwork) {
      case Artwork.kingsCross:
        _kingsCross(canvas);
      case Artwork.suitcase:
        _suitcase(canvas);
      case Artwork.britishMuseum:
        _museum(canvas);
      case Artwork.bigBen:
        _bigBen(canvas);
      case Artwork.hydePark:
        _park(canvas);
      case Artwork.buckinghamPalace:
        _palace(canvas);
      case Artwork.towerBridge:
        _towerBridge(canvas);
      case Artwork.londonEye:
        _londonEye(canvas);
      case Artwork.royalBox:
        _royalBox(canvas);
    }
    canvas.restore();
  }

  Color get _groundColor => switch (artwork) {
        Artwork.hydePark || Artwork.londonEye => AppColors.park,
        Artwork.towerBridge => AppColors.river,
        Artwork.royalBox => AppColors.parchmentDark,
        _ => const Color(0xFFD9CBA8),
      };

  void _clouds(Canvas c) {
    final p = _fill(Colors.white.withValues(alpha: 0.85));
    for (final (x, y, r) in [(16.0, 14.0, 5.0), (22.0, 12.0, 6.5), (28.0, 14.5, 4.5), (78.0, 20.0, 4.0), (84.0, 18.0, 5.5)]) {
      c.drawCircle(Offset(x, y), r, p);
    }
  }

  void _kingsCross(Canvas c) {
    _box(c, 8, 44, 92, 86, _brick);
    // Two great arched train sheds.
    for (final left in [14.0, 54.0]) {
      final arch = Path()
        ..moveTo(left, 86)
        ..lineTo(left, 62)
        ..arcToPoint(Offset(left + 32, 62), radius: const Radius.circular(16))
        ..lineTo(left + 32, 86)
        ..close();
      c.drawPath(arch, _fill(_window));
      c.drawPath(arch, _ink);
      for (var i = 1; i < 4; i++) {
        c.drawLine(Offset(left + i * 8, 52), Offset(left + i * 8, 86), _ink..strokeWidth = 0.8);
      }
    }
    // Clock tower.
    _box(c, 43, 20, 57, 46, _brick);
    _poly(c, const [Offset(42, 20), Offset(50, 10), Offset(58, 20)], AppColors.navy);
    c.drawCircle(const Offset(50, 30), 5, _fill(Colors.white));
    c.drawCircle(const Offset(50, 30), 5, _ink);
    c.drawLine(const Offset(50, 30), const Offset(50, 26.5), _ink);
    c.drawLine(const Offset(50, 30), const Offset(52.5, 31), _ink);
  }

  void _suitcase(Canvas c) {
    // Platform sign "9" in the background.
    _box(c, 64, 12, 92, 30, AppColors.navy, radius: 2);
    _text(c, '9', const Offset(78, 21), 14, AppColors.goldLight);
    c.drawLine(const Offset(70, 30), const Offset(70, 40), _ink..strokeWidth = 1.6);
    c.drawLine(const Offset(86, 30), const Offset(86, 40), _ink);

    // Handle.
    final handle = Path()
      ..moveTo(40, 46)
      ..lineTo(40, 38)
      ..quadraticBezierTo(50, 32, 60, 38)
      ..lineTo(60, 46);
    c.drawPath(handle, _ink..strokeWidth = 3.2);
    c.drawPath(handle, Paint()
      ..color = _leatherDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);

    // Body + straps.
    _box(c, 14, 45, 86, 84, _leather, radius: 5);
    _box(c, 28, 45, 34, 84, _leatherDark, radius: 0.5);
    _box(c, 66, 45, 72, 84, _leatherDark, radius: 0.5);
    _box(c, 27, 60, 35, 66, AppColors.gold, radius: 1);
    _box(c, 65, 60, 73, 66, AppColors.gold, radius: 1);

    // Travel stickers.
    c.drawCircle(const Offset(48, 58), 6, _fill(AppColors.royalBlue));
    c.drawCircle(const Offset(48, 58), 6, _ink..strokeWidth = 1.2);
    _text(c, 'L', const Offset(48, 58), 7, Colors.white);
    _box(c, 44, 68, 60, 77, AppColors.goldLight, radius: 1.5);
    _text(c, 'LDN', const Offset(52, 72.5), 4.6, AppColors.navy);

    // A letter peeking out of the suitcase.
    c.save();
    c.translate(76, 44);
    c.rotate(0.25);
    _box(c, -8, -8, 10, 4, Colors.white, radius: 0.8);
    c.drawCircle(const Offset(1, -2), 2.6, _fill(AppColors.waxRed));
    c.restore();
  }

  void _museum(Canvas c) {
    _poly(c, const [Offset(12, 40), Offset(50, 20), Offset(88, 40)], _stone);
    _poly(c, const [Offset(24, 37), Offset(50, 25), Offset(76, 37)], _stoneShade);
    _box(c, 12, 40, 88, 47, _stone);
    for (var i = 0; i < 8; i++) {
      final x = 16 + i * 9.4;
      _box(c, x, 47, x + 5, 78, _stone, radius: 0.4);
      c.drawLine(Offset(x + 2.5, 50), Offset(x + 2.5, 75), _ink..strokeWidth = 0.5);
    }
    _box(c, 10, 78, 90, 82, _stoneShade);
    _box(c, 6, 82, 94, 86, _stone);
    // Banner.
    _box(c, 43, 55, 57, 70, AppColors.waxRed, radius: 0.5);
    _text(c, 'BM', const Offset(50, 62.5), 5.4, AppColors.goldLight);
  }

  void _bigBen(Canvas c) {
    _box(c, 40, 34, 60, 86, _stone);
    for (var y = 58.0; y < 84; y += 7) {
      _box(c, 44, y, 48, y + 4, _window, radius: 1);
      _box(c, 52, y, 56, y + 4, _window, radius: 1);
    }
    // Clock face.
    _box(c, 37, 34, 63, 56, AppColors.goldLight, radius: 1);
    c.drawCircle(const Offset(50, 45), 9.5, _fill(Colors.white));
    c.drawCircle(const Offset(50, 45), 9.5, _ink..strokeWidth = 1.4);
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      c.drawLine(
        Offset(50 + 7.6 * math.cos(a), 45 + 7.6 * math.sin(a)),
        Offset(50 + 8.8 * math.cos(a), 45 + 8.8 * math.sin(a)),
        _ink..strokeWidth = 0.7,
      );
    }
    c.drawLine(const Offset(50, 45), const Offset(50, 38.5), _ink..strokeWidth = 1.2);
    c.drawLine(const Offset(50, 45), const Offset(54.5, 45), _ink);
    // Belfry + spire.
    _box(c, 41, 24, 59, 34, _stone);
    for (var i = 0; i < 3; i++) {
      _box(c, 43.5 + i * 5, 26, 46.5 + i * 5, 32, AppColors.navy, radius: 1.5);
    }
    _poly(c, const [Offset(40, 24), Offset(50, 4), Offset(60, 24)], AppColors.navy);
    c.drawCircle(const Offset(50, 4), 1.6, _fill(AppColors.gold));
  }

  void _park(Canvas c) {
    c.drawCircle(const Offset(82, 16), 7, _fill(AppColors.goldLight));
    // Trees.
    for (final (x, y, r) in [(16.0, 48.0, 11.0), (86.0, 50.0, 9.0), (70.0, 44.0, 7.0)]) {
      _box(c, x - 1.6, y, x + 1.6, 72, _leather, radius: 0.5);
      c.drawCircle(Offset(x, y), r, _fill(AppColors.parkDeep));
      c.drawCircle(Offset(x, y), r, _ink);
    }
    // Lake.
    final lake = Rect.fromLTRB(8, 64, 92, 92);
    c.drawOval(lake, _fill(AppColors.river));
    c.drawOval(lake, _ink);
    // Two swans.
    for (final x in [38.0, 60.0]) {
      c.drawOval(Rect.fromCenter(center: Offset(x, 77), width: 12, height: 6), _fill(Colors.white));
      c.drawOval(Rect.fromCenter(center: Offset(x, 77), width: 12, height: 6), _ink..strokeWidth = 1);
      final neck = Path()
        ..moveTo(x + 4, 76)
        ..quadraticBezierTo(x + 7, 70, x + 4.5, 67.5);
      c.drawPath(neck, _ink..strokeWidth = 2.6);
      c.drawPath(neck, Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4);
      c.drawCircle(Offset(x + 4.5, 67.5), 1.6, _fill(Colors.white));
      c.drawCircle(Offset(x + 3.0, 68.2), 0.9, _fill(AppColors.gold)); // beak
    }
  }

  void _palace(Canvas c) {
    _box(c, 6, 44, 94, 80, _stone);
    _box(c, 36, 36, 64, 44, _stone);
    _poly(c, const [Offset(34, 36), Offset(50, 28), Offset(66, 36)], _stoneShade);
    // Flag.
    c.drawLine(const Offset(50, 28), const Offset(50, 12), _ink..strokeWidth = 1);
    _box(c, 50, 12, 62, 19, AppColors.royalBlue, radius: 0.3);
    c.drawLine(const Offset(50, 12), const Offset(62, 19), Paint()
      ..color = _guardRed
      ..strokeWidth = 1.4);
    c.drawLine(const Offset(50, 19), const Offset(62, 12), Paint()
      ..color = _guardRed
      ..strokeWidth = 1.4);
    // Windows.
    for (var row = 0; row < 2; row++) {
      for (var i = 0; i < 9; i++) {
        final x = 10 + i * 9.2;
        _box(c, x, 48 + row * 11, x + 4, 55 + row * 11, _window, radius: 0.4);
      }
    }
    // Gate with gold tips.
    for (var x = 12.0; x <= 88; x += 4) {
      c.drawLine(Offset(x, 72), Offset(x, 86), _ink..strokeWidth = 1);
      c.drawCircle(Offset(x, 71.5), 0.9, _fill(AppColors.gold));
    }
    c.drawLine(const Offset(10, 76), const Offset(90, 76), _ink..strokeWidth = 1);
    // Two guards: red coats + tall black hats.
    for (final x in [28.0, 72.0]) {
      _box(c, x - 3.6, 71, x + 3.6, 82, _guardRed, radius: 1);
      _box(c, x - 3, 82, x - 0.4, 88, AppColors.navy, radius: 0.3);
      _box(c, x + 0.4, 82, x + 3, 88, AppColors.navy, radius: 0.3);
      c.drawCircle(Offset(x, 68.5), 2.6, _fill(const Color(0xFFF2C9A2)));
      final hat = RRect.fromLTRBR(x - 3.4, 58, x + 3.4, 67.5, const Radius.circular(3.4));
      c.drawRRect(hat, _fill(AppColors.charcoal));
    }
  }

  void _towerBridge(Canvas c) {
    // River shading.
    for (var y = 88.0; y < 100; y += 4) {
      c.drawLine(Offset(10, y), Offset(30, y), _ink..strokeWidth = 0.6);
      c.drawLine(Offset(60, y + 2), Offset(84, y + 2), _ink);
    }
    // Suspension cables.
    final cable = Paint()
      ..color = AppColors.royalBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    c.drawPath(Path()
      ..moveTo(0, 60)
      ..quadraticBezierTo(14, 58, 22, 40), cable);
    c.drawPath(Path()
      ..moveTo(100, 60)
      ..quadraticBezierTo(86, 58, 78, 40), cable);
    // Road deck.
    _box(c, 0, 62, 100, 67, _stoneShade);
    // Towers.
    for (final l in [20.0, 64.0]) {
      _box(c, l, 30, l + 16, 88, _stone);
      _box(c, l + 5, 44, l + 11, 54, _window, radius: 3);
      _poly(c, [Offset(l - 1, 30), Offset(l + 8, 16), Offset(l + 17, 30)], AppColors.navy);
      c.drawCircle(Offset(l + 8, 16), 1.3, _fill(AppColors.gold));
    }
    // High walkways.
    _box(c, 36, 34, 64, 37.5, AppColors.royalBlue, radius: 0.3);
    _box(c, 36, 39.5, 64, 43, AppColors.royalBlue, radius: 0.3);
  }

  void _londonEye(Canvas c) {
    const center = Offset(50, 46);
    const r = 32.0;
    // Legs.
    c.drawLine(center, const Offset(34, 86), _ink..strokeWidth = 2.2);
    c.drawLine(center, const Offset(66, 86), _ink);
    // Spokes & rim.
    for (var i = 0; i < 16; i++) {
      final a = i * math.pi / 8;
      c.drawLine(center, center + Offset(r * math.cos(a), r * math.sin(a)), _ink..strokeWidth = 0.5);
    }
    c.drawCircle(center, r, Paint()
      ..color = AppColors.royalBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
    c.drawCircle(center, r - 3, _ink..strokeWidth = 0.8);
    for (var i = 0; i < 16; i++) {
      final a = i * math.pi / 8;
      final p = center + Offset((r + 2) * math.cos(a), (r + 2) * math.sin(a));
      c.drawOval(Rect.fromCenter(center: p, width: 4.6, height: 3.2), _fill(Colors.white));
      c.drawOval(Rect.fromCenter(center: p, width: 4.6, height: 3.2), _ink..strokeWidth = 0.7);
    }
    c.drawCircle(center, 3, _fill(AppColors.gold));
    c.drawCircle(center, 3, _ink..strokeWidth = 1);
  }

  void _royalBox(Canvas c) {
    // Soft glow.
    c.drawCircle(const Offset(50, 58), 38, Paint()
      ..shader = RadialGradient(colors: [AppColors.goldLight.withValues(alpha: 0.8), AppColors.goldLight.withValues(alpha: 0)])
          .createShader(Rect.fromCircle(center: const Offset(50, 58), radius: 38)));
    _box(c, 18, 52, 82, 86, AppColors.gold, radius: 2);
    final lid = Path()
      ..moveTo(16, 54)
      ..lineTo(16, 44)
      ..quadraticBezierTo(50, 26, 84, 44)
      ..lineTo(84, 54)
      ..close();
    c.drawPath(lid, _fill(AppColors.goldDeep));
    c.drawPath(lid, _ink);
    for (final x in [26.0, 74.0]) {
      _box(c, x - 2.5, 40, x + 2.5, 86, AppColors.goldLight, radius: 0.5);
    }
    _box(c, 44, 56, 56, 68, AppColors.navy, radius: 1.5);
    c.drawCircle(const Offset(50, 60.5), 1.8, _fill(AppColors.goldLight));
    c.drawLine(const Offset(50, 61), const Offset(50, 65), Paint()
      ..color = AppColors.goldLight
      ..strokeWidth = 1.4);
    _crown(c, const Offset(50, 41), 8);
  }

  void _crown(Canvas c, Offset center, double w) {
    final h = w * 0.7;
    final path = Path()
      ..moveTo(center.dx - w, center.dy + h / 2)
      ..lineTo(center.dx - w, center.dy - h / 2)
      ..lineTo(center.dx - w / 2, center.dy)
      ..lineTo(center.dx, center.dy - h)
      ..lineTo(center.dx + w / 2, center.dy)
      ..lineTo(center.dx + w, center.dy - h / 2)
      ..lineTo(center.dx + w, center.dy + h / 2)
      ..close();
    c.drawPath(path, _fill(AppColors.goldLight));
    c.drawPath(path, _ink..strokeWidth = 1);
    c.drawCircle(Offset(center.dx, center.dy + h / 5), w / 6, _fill(AppColors.waxRed));
  }

  void _text(Canvas c, String text, Offset center, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Fredoka',
          fontSize: size,
          fontWeight: FontWeight.w700,
          fontVariations: const [FontVariation('wght', 700)],
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_LandmarkPainter old) => old.artwork != artwork || old.showSky != showSky;
}
