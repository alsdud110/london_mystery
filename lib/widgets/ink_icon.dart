import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../core/theme/app_tokens.dart';

/// London Mystery Ink Icon System — the game's one icon language: simple
/// monochrome ink line drawings (24 × 24 grid, 1.9 stroke, round ends, flat).
///
/// Every icon in the game is `InkIcon(InkGlyph.x)`, sized with [AppIconSize]
/// and coloured from [AppColors]. No Material icons, emoji or other icon
/// packs (the camera/flash controls of the QR scanner are the one exception).
/// A picture that has no glyph yet is shown with [InkMark] until its drawing
/// is added here.
enum InkGlyph {
  // Navigation
  back,
  arrow,
  close,
  menu,
  down,

  // Investigation
  search,
  notebook,
  letter,
  lock,
  pin,
  hint,

  // Game
  check,
  qr,
  pen,
  backspace,
  clear,

  // System
  speaker,
  speakerOff,
  home,
  folder,

  // Objects (clue symbols, evidence, badges)
  clock,
  gear,
  key,
  footprint,
  button,
  cloth,
  map,
  ticket,
  feather,
  mask,
  gem,
  bag,
  raven,
  umbrella,
  seal,
  frame,
  whistle,
  train,
}

class InkIcon extends StatelessWidget {
  const InkIcon(this.glyph, {super.key, this.size = AppIconSize.regular, this.color, this.semanticLabel});

  final InkGlyph glyph;
  final double size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color ?? AppColors.ink;
    // Keeps its size inside slots with a minimum (text-field prefix,
    // 48 px tap targets), like Material's Icon.
    final icon = Center(
      widthFactor: 1,
      heightFactor: 1,
      child: CustomPaint(size: Size.square(size), painter: _InkGlyphPainter(glyph, c)),
    );
    return semanticLabel == null ? ExcludeSemantics(child: icon) : Semantics(label: semanticLabel, child: icon);
  }
}

/// A data-driven picture (clue symbol, evidence, badge): its finished
/// [asset] picture when one has been added (see `ArtAssets`), else its
/// [glyph] when one exists, otherwise its [monogram] lettered like a
/// wax-seal initial.
///
/// A monogram marks "Custom Asset Required" — the drawing is still to come.
/// Never stand in a different icon family instead.
class InkMark extends StatelessWidget {
  const InkMark({
    super.key,
    required this.glyph,
    required this.monogram,
    this.size = AppIconSize.regular,
    this.color,
    this.asset,
  });

  final InkGlyph? glyph;
  final String monogram;
  final double size;
  final Color? color;

  /// A one-colour picture file, tinted with [color] like the ink glyphs.
  final String? asset;

  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color ?? AppColors.ink;
    final drawn = glyph != null
        ? InkIcon(glyph!, size: size, color: c)
        : ExcludeSemantics(
            child: SizedBox.square(
              dimension: size,
              child: Center(
                child: Text(
                  monogram,
                  maxLines: 1,
                  textScaler: TextScaler.noScaling,
                  style: AppText.style(AppText.display, size: size * 0.8, weight: FontWeight.w700, color: c, height: 1),
                ),
              ),
            ),
          );
    if (asset == null) return drawn;
    return Image.asset(
      asset!,
      width: size,
      height: size,
      color: c,
      colorBlendMode: BlendMode.srcIn,
      excludeFromSemantics: true,
      errorBuilder: (context, error, stack) => drawn, // a missing file keeps the drawing
    );
  }
}

/// A rating star. Custom Asset Required: there is no ink star yet, so this
/// sets the typographic ★ / ☆ (text, not emoji) in one place until the
/// drawing is added to [InkGlyph].
class InkStar extends StatelessWidget {
  const InkStar({super.key, this.filled = true, this.size = AppIconSize.regular, this.color});

  final bool filled;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? IconTheme.of(context).color ?? AppColors.gold;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: Center(
          child: Text(
            filled ? '★' : '☆',
            textScaler: TextScaler.noScaling,
            style: TextStyle(fontSize: size * 0.9, height: 1, color: c),
          ),
        ),
      ),
    );
  }
}

/// Glyphs are drawn on a 24 × 24 grid.
class _InkGlyphPainter extends CustomPainter {
  _InkGlyphPainter(this.glyph, this.color);

  final InkGlyph glyph;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    void line(double x1, double y1, double x2, double y2) => canvas.drawLine(Offset(x1, y1), Offset(x2, y2), p);
    void poly(List<Offset> pts, {bool close = false}) => canvas.drawPath(Path()..addPolygon(pts, close), p);
    void rect(double l, double t, double r, double b, [double radius = 1.5]) =>
        canvas.drawRRect(RRect.fromLTRBR(l, t, r, b, Radius.circular(radius)), p);

    switch (glyph) {
      case InkGlyph.back:
        line(19, 12, 5, 12);
        poly(const [Offset(11, 6), Offset(5, 12), Offset(11, 18)]);
      case InkGlyph.arrow:
        line(5, 12, 19, 12);
        poly(const [Offset(13, 6), Offset(19, 12), Offset(13, 18)]);
      case InkGlyph.close:
        line(6, 6, 18, 18);
        line(18, 6, 6, 18);
      case InkGlyph.menu:
        for (final y in [7.0, 12.0, 17.0]) {
          line(4, y, 20, y);
        }
      case InkGlyph.notebook:
        rect(6, 3, 19.5, 21);
        line(9.5, 3, 9.5, 21);
        line(12.5, 8, 16.5, 8);
        line(12.5, 12, 16.5, 12);
        for (final y in [7.0, 12.0, 17.0]) {
          line(4, y, 6, y);
        }
      case InkGlyph.letter:
        rect(3, 6, 21, 18);
        poly(const [Offset(3.5, 7), Offset(12, 13.5), Offset(20.5, 7)]);
      case InkGlyph.hint:
        canvas.drawArc(
          Rect.fromCircle(center: const Offset(12, 10), radius: 6),
          math.pi * 0.75,
          math.pi * 1.5,
          false,
          p,
        );
        line(7.8, 14.2, 9.5, 17);
        line(16.2, 14.2, 14.5, 17);
        line(9.5, 17, 14.5, 17);
        line(10.2, 20, 13.8, 20);
      case InkGlyph.lock:
        rect(5, 11, 19, 21, 2);
        canvas.drawPath(
          Path()
            ..moveTo(8, 11)
            ..lineTo(8, 8)
            ..arcToPoint(const Offset(16, 8), radius: const Radius.circular(4))
            ..lineTo(16, 11),
          p,
        );
        line(12, 15, 12, 17.5);
      case InkGlyph.check:
        poly(const [Offset(5, 12.5), Offset(10, 17), Offset(19, 7)]);
      case InkGlyph.search:
        canvas.drawCircle(const Offset(10.5, 10.5), 6, p);
        line(15, 15, 20, 20);
      case InkGlyph.backspace:
        poly(const [Offset(8, 5), Offset(20, 5), Offset(20, 19), Offset(8, 19), Offset(3, 12)], close: true);
        line(11.5, 9.5, 16.5, 14.5);
        line(16.5, 9.5, 11.5, 14.5);
      case InkGlyph.clear:
        canvas.drawCircle(const Offset(12, 12), 8, p);
        line(9, 9, 15, 15);
        line(15, 9, 9, 15);
      case InkGlyph.qr:
        rect(4, 4, 10, 10, 1);
        rect(14, 4, 20, 10, 1);
        rect(4, 14, 10, 20, 1);
        line(14, 14, 14, 16);
        line(17, 14, 20, 14);
        line(17, 17, 17, 20);
        line(20, 17, 20, 20);
      case InkGlyph.speaker:
      case InkGlyph.speakerOff:
        poly(const [
          Offset(4, 9),
          Offset(8, 9),
          Offset(13, 5),
          Offset(13, 19),
          Offset(8, 15),
          Offset(4, 15),
        ], close: true);
        if (glyph == InkGlyph.speaker) {
          canvas.drawArc(Rect.fromCircle(center: const Offset(13, 12), radius: 4), -math.pi / 4, math.pi / 2, false, p);
          canvas.drawArc(
            Rect.fromCircle(center: const Offset(13, 12), radius: 7.5),
            -math.pi / 4,
            math.pi / 2,
            false,
            p,
          );
        } else {
          line(16, 9, 21, 15);
          line(21, 9, 16, 15);
        }
      case InkGlyph.home:
        poly(const [Offset(3.5, 11.5), Offset(12, 4), Offset(20.5, 11.5)]);
        poly(const [Offset(6, 10), Offset(6, 20), Offset(18, 20), Offset(18, 10)]);
        poly(const [Offset(10, 20), Offset(10, 15), Offset(14, 15), Offset(14, 20)]);
      case InkGlyph.folder:
        poly(const [
          Offset(3, 6),
          Offset(9.5, 6),
          Offset(11.5, 8.5),
          Offset(21, 8.5),
          Offset(21, 19),
          Offset(3, 19),
        ], close: true);
      case InkGlyph.pen:
        poly(const [Offset(4, 20), Offset(5, 16), Offset(16, 5), Offset(19, 8), Offset(8, 19)], close: true);
        line(14, 7, 17, 10);
      case InkGlyph.pin:
        canvas.drawPath(
          Path()
            ..moveTo(12, 21.5)
            ..lineTo(6.8, 12.5)
            ..arcToPoint(const Offset(17.2, 12.5), radius: const Radius.circular(6), largeArc: true)
            ..close(),
          p,
        );
        canvas.drawCircle(const Offset(12, 9.5), 2.2, p);
      case InkGlyph.down:
        line(12, 4, 12, 19);
        poly(const [Offset(7, 14), Offset(12, 19), Offset(17, 14)]);
      case InkGlyph.clock:
        canvas.drawCircle(const Offset(12, 12), 8.5, p);
        line(12, 12, 12, 7);
        line(12, 12, 15.5, 13.5);
        for (final (x, y) in const [(12.0, 4.8), (19.2, 12.0), (12.0, 19.2), (4.8, 12.0)]) {
          canvas.drawCircle(Offset(x, y), 0.2, p);
        }
      case InkGlyph.gear:
        canvas.drawCircle(const Offset(12, 12), 5.5, p);
        canvas.drawCircle(const Offset(12, 12), 1.8, p);
        for (var i = 0; i < 8; i++) {
          final a = i * math.pi / 4;
          line(12 + 5.5 * math.cos(a), 12 + 5.5 * math.sin(a), 12 + 8.5 * math.cos(a), 12 + 8.5 * math.sin(a));
        }
      case InkGlyph.key:
        canvas.drawCircle(const Offset(7.5, 12), 3.5, p);
        line(11, 12, 21, 12);
        line(17.5, 12, 17.5, 15.5);
        line(20.5, 12, 20.5, 14.5);
      case InkGlyph.footprint:
        canvas.drawOval(const Rect.fromLTRB(7.5, 2.5, 16, 13.5), p);
        canvas.drawOval(const Rect.fromLTRB(8.5, 15, 14.5, 21.5), p);
      case InkGlyph.button:
        canvas.drawCircle(const Offset(12, 12), 8.5, p);
        canvas.drawCircle(const Offset(12, 12), 6, p);
        for (final (x, y) in const [(10.3, 10.3), (13.7, 10.3), (10.3, 13.7), (13.7, 13.7)]) {
          canvas.drawCircle(Offset(x, y), 0.5, p);
        }
      case InkGlyph.cloth:
        poly(const [
          Offset(4, 6), Offset(9, 4.5), Offset(14, 6), Offset(20, 4.5), Offset(19, 11), //
          Offset(20.5, 18), Offset(15, 19.5), Offset(11, 17.5), Offset(5, 19.5), Offset(5.5, 12),
        ], close: true);
        line(8, 9, 16, 9);
        line(8, 13, 16, 13);
      case InkGlyph.map:
        poly(const [
          Offset(3, 6),
          Offset(9, 4),
          Offset(15, 6),
          Offset(21, 4),
          Offset(21, 18),
          Offset(15, 20),
          Offset(9, 18),
          Offset(3, 20),
        ], close: true);
        line(9, 4, 9, 18);
        line(15, 6, 15, 20);
      case InkGlyph.ticket:
        rect(3, 7, 21, 17, 1);
        for (final y in const [8.8, 11.2, 13.6]) {
          line(15.5, y, 15.5, y + 1.4);
        }
        line(6, 10.5, 12, 10.5);
        line(6, 13.5, 10, 13.5);
      case InkGlyph.feather:
        line(5, 20, 18.5, 4.5);
        canvas.drawPath(
          Path()
            ..moveTo(18.5, 4.5)
            ..quadraticBezierTo(21, 13, 9.5, 15.5),
          p,
        );
        canvas.drawPath(
          Path()
            ..moveTo(18.5, 4.5)
            ..quadraticBezierTo(9.5, 5, 8.2, 15),
          p,
        );
      case InkGlyph.mask:
        canvas.drawPath(
          Path()
            ..moveTo(3, 9)
            ..quadraticBezierTo(12, 6.5, 21, 9)
            ..quadraticBezierTo(20.5, 16.5, 15.5, 16.5)
            ..quadraticBezierTo(12, 13.5, 8.5, 16.5)
            ..quadraticBezierTo(3.5, 16.5, 3, 9)
            ..close(),
          p,
        );
        canvas.drawOval(const Rect.fromLTRB(6.5, 10.2, 10.5, 13.2), p);
        canvas.drawOval(const Rect.fromLTRB(13.5, 10.2, 17.5, 13.2), p);
      case InkGlyph.gem:
        poly(const [Offset(7, 5), Offset(17, 5), Offset(21, 10), Offset(12, 20), Offset(3, 10)], close: true);
        line(3, 10, 21, 10);
        line(9.5, 10, 12, 20);
        line(14.5, 10, 12, 20);
      case InkGlyph.bag:
        rect(4, 9, 20, 20, 2);
        canvas.drawPath(
          Path()
            ..moveTo(8.5, 9)
            ..lineTo(8.5, 7)
            ..arcToPoint(const Offset(15.5, 7), radius: const Radius.circular(3.5))
            ..lineTo(15.5, 9),
          p,
        );
        line(4, 13.5, 20, 13.5);
        line(12, 13.5, 12, 15.5);
      case InkGlyph.raven:
        canvas.drawPath(
          Path()
            ..moveTo(3.5, 15)
            ..quadraticBezierTo(8, 8.5, 15, 8.5)
            ..lineTo(21, 7)
            ..lineTo(17.5, 11)
            ..quadraticBezierTo(16, 16.5, 9, 16.5)
            ..close(),
          p,
        );
        line(10, 16.5, 9, 20.5);
        line(13, 16.5, 13, 20.5);
        canvas.drawCircle(const Offset(15.3, 9.8), 0.3, p);
      case InkGlyph.umbrella:
        canvas.drawPath(
          Path()
            ..moveTo(3.5, 12)
            ..arcToPoint(const Offset(20.5, 12), radius: const Radius.circular(8.5))
            ..close(),
          p,
        );
        canvas.drawPath(
          Path()
            ..moveTo(12, 12)
            ..lineTo(12, 18.5)
            ..arcToPoint(const Offset(15, 18.5), radius: const Radius.circular(1.5), clockwise: false),
          p,
        );
      case InkGlyph.seal:
        canvas.drawCircle(const Offset(12, 12), 8.5, p);
        canvas.drawCircle(const Offset(12, 12), 5, p);
        line(12, 9.5, 12, 14.5);
        line(9.5, 12, 14.5, 12);
      case InkGlyph.frame:
        rect(3, 4, 21, 20, 1);
        rect(6, 7, 18, 17, 0.5);
        poly(const [Offset(7, 16), Offset(10.5, 11.5), Offset(13, 14), Offset(14.5, 12.5), Offset(17, 16)]);
      case InkGlyph.whistle:
        canvas.drawCircle(const Offset(14.5, 13.5), 5.5, p);
        poly(const [Offset(14.5, 8), Offset(3, 8), Offset(3, 12), Offset(9.5, 12)]);
        canvas.drawCircle(const Offset(14.5, 13.5), 1.4, p);
        line(19, 9.5, 21, 5.5);
      case InkGlyph.train:
        rect(3, 9.5, 14.5, 17, 1);
        rect(14.5, 5.5, 21, 17, 1);
        rect(6, 5, 9, 9.5, 0.5);
        line(16.5, 8.5, 19, 8.5);
        canvas.drawCircle(const Offset(7.5, 19), 2, p);
        canvas.drawCircle(const Offset(17, 19), 2, p);
    }
  }

  @override
  bool shouldRepaint(_InkGlyphPainter old) => old.glyph != glyph || old.color != color;
}
