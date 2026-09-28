import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../core/theme/app_tokens.dart';
import 'glossary_text.dart';

/// Aged manila, a shade darker than the letter paper.
const _envelopeColor = Color(0xFFE3D2AE);
const _envelopeInside = Color(0xFFD2BE94);

/// An outline with a slightly uneven, hand-cut edge (deterministic).
Path _deckledRect(Size s, math.Random rnd, {double amp = 1.6, double step = 12}) {
  double j() => rnd.nextDouble() * amp;
  final path = Path()..moveTo(j(), j());
  for (var x = step; x < s.width; x += step) {
    path.lineTo(x, j());
  }
  path.lineTo(s.width - j(), j());
  for (var y = step; y < s.height; y += step) {
    path.lineTo(s.width - j(), y);
  }
  path.lineTo(s.width - j(), s.height - j());
  for (var x = s.width - step; x > 0; x -= step) {
    path.lineTo(x, s.height - j());
  }
  path.lineTo(j(), s.height - j());
  for (var y = s.height - step; y > 0; y -= step) {
    path.lineTo(j(), y);
  }
  return path..close();
}

// ─────────────────────────────────────────────────────────────────────────────
// The letter
// ─────────────────────────────────────────────────────────────────────────────

/// A handwritten case letter: a sheet of aged paper with slightly uneven
/// edges, faint fold creases and a small wax seal, lying on the desk.
class LetterCard extends StatelessWidget {
  const LetterCard({super.key, required this.text, this.tilt = -0.01, this.textOpacity = 1});

  final String text;
  final double tilt;

  /// The writing fades in last when the letter has just been unfolded.
  final double textOpacity;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: tilt,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            painter: const _LetterPaperPainter(),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 30, 28, 40),
              child: SizedBox(
                width: double.infinity,
                child: Opacity(opacity: textOpacity, child: GlossaryText(text, style: AppText.letter())),
              ),
            ),
          ),
          // Pressed into the bottom corner, as if it had sealed the fold
          // (inside the sheet, so it unfolds together with the paper).
          const Positioned(right: 16, bottom: 10, child: WaxSeal(size: 32)),
        ],
      ),
    );
  }
}

class _LetterPaperPainter extends CustomPainter {
  const _LetterPaperPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(29);
    final sheet = _deckledRect(size, rnd);

    canvas.drawShadow(sheet.shift(const Offset(0, 1)), AppColors.ink.withValues(alpha: 0.5), 2.5, false);
    canvas.drawPath(sheet, Paint()..color = AppColors.parchment);

    canvas.save();
    canvas.clipPath(sheet);
    // Barely-there age marks: the paper is not one flat colour.
    for (var i = 0; i < 4; i++) {
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
        size.shortestSide * (0.25 + rnd.nextDouble() * 0.3),
        Paint()..color = AppColors.parchmentDark.withValues(alpha: 0.08),
      );
    }
    // Where the letter was folded in three.
    for (final f in [1 / 3, 2 / 3]) {
      final y = size.height * f;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), Paint()..color = AppColors.ink.withValues(alpha: 0.07));
      canvas.drawLine(Offset(0, y + 1), Offset(size.width, y + 1), Paint()..color = AppColors.paperLight.withValues(alpha: 0.6));
    }
    canvas.restore();

    canvas.drawPath(
      sheet,
      Paint()
        ..color = AppColors.ink.withValues(alpha: 0.16)
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppLine.hairline,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A flat wax seal: burgundy disc, pressed ring, monogram.
class WaxSeal extends StatelessWidget {
  const WaxSeal({super.key, this.size = 48, this.letter = 'LM'});

  final double size;
  final String letter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.burgundy),
      child: Container(
        width: size * 0.74,
        height: size * 0.74,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.paperLight.withValues(alpha: 0.35), width: size / 28),
        ),
        child: Text(
          letter,
          style: AppText.style(AppText.display, size: size * 0.26, weight: FontWeight.w800, color: AppColors.paperLight.withValues(alpha: 0.85)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// The envelope and how it opens
// ─────────────────────────────────────────────────────────────────────────────

/// A sealed Victorian envelope the player taps to open.
///
/// Opening is one quiet physical sequence (~850 ms):
///  1. the wax seal cracks and its halves fall away,
///  2. the flap folds back,
///  3. the folded letter slides up out of the envelope,
///  4. the envelope drops away while the letter comes to the centre and
///     unfolds from its thirds,
///  5. the paper settles and the writing fades in.
///
/// With [initiallyOpen] the letter is shown straight away (no replay).
///
/// The envelope is drawn by separate painters (pocket, flap, seal) so each
/// can later be swapped for a PNG/SVG illustration.
class EnvelopeReveal extends StatefulWidget {
  const EnvelopeReveal({super.key, required this.letterText, this.initiallyOpen = false, this.onOpened});

  final String letterText;
  final bool initiallyOpen;
  final VoidCallback? onOpened;

  @override
  State<EnvelopeReveal> createState() => _EnvelopeRevealState();
}

class _EnvelopeRevealState extends State<EnvelopeReveal> with SingleTickerProviderStateMixin {
  /// Room above the envelope for the letter to come out into.
  static const _headroom = 80.0;
  static const _envelopeHeight = 180.0;
  static const _labelHeight = 36.0;
  static const _tilt = -0.025;

  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
    value: widget.initiallyOpen ? 1 : 0,
  );
  late bool _open = widget.initiallyOpen;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _openEnvelope() async {
    if (_c.isAnimating || _open) return;
    await _c.forward();
    if (!mounted) return;
    setState(() => _open = true);
    widget.onOpened?.call();
  }

  double _phase(double a, double b, [Curve curve = Curves.easeOutCubic]) =>
      curve.transform(((_c.value - a) / (b - a)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    if (_open) return LetterCard(text: widget.letterText);

    return Semantics(
      button: true,
      label: 'Sealed letter. Tap to open.',
      child: GestureDetector(
        onTap: _openEnvelope,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) {
            final seal = _phase(0, 0.2, Curves.easeIn);
            final flap = _phase(0.12, 0.38, Curves.easeInOut);
            final rise = _phase(0.3, 0.52);
            final move = _phase(0.5, 0.72);
            final away = _phase(0.5, 0.7);
            final unfold = _phase(0.58, 0.92);
            final ink = _phase(0.8, 1.0, Curves.easeOut);
            final flapBack = flap > 0.5;

            // The envelope layers share one placement, so the flap, pocket
            // and seal stay together as it is set down and taken away.
            Widget envelope(Widget child) => Align(
                  alignment: Alignment.topCenter,
                  heightFactor: 1 - away, // its space goes with it
                  child: Opacity(
                    opacity: 1 - away,
                    child: Transform.translate(
                      offset: Offset(0, 28 * away),
                      child: Padding(
                        padding: const EdgeInsets.only(top: _headroom),
                        child: SizedBox(
                          height: _envelopeHeight + _labelHeight,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned(
                                left: 10,
                                right: 10,
                                top: 0,
                                height: _envelopeHeight,
                                child: Transform.rotate(angle: _tilt, child: child),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );

            final flapLayer = Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  height: _envelopeHeight * 0.56,
                  child: Transform(
                    alignment: Alignment.topCenter,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.0014)
                      ..rotateX(math.pi * flap),
                    child: CustomPaint(painter: _FlapPainter(inside: flapBack)),
                  ),
                ),
              ],
            );

            return Stack(
              alignment: Alignment.topCenter,
              clipBehavior: Clip.none,
              children: [
                // 1 · An open flap folds back behind everything.
                if (flapBack) envelope(flapLayer),
                // 2 · The letter: folded in thirds inside the envelope, then
                //     drawn up, brought to the centre and unfolded.
                if (rise > 0)
                  Transform.translate(
                    offset: Offset(0, (_headroom + 14) - (_headroom - 6) * rise - 20 * move),
                    child: Transform.rotate(
                      angle: _tilt + (0.015) * move,
                      child: Transform.scale(
                        alignment: Alignment.topCenter,
                        scale: 0.82 + 0.18 * move,
                        child: ClipRect(
                          child: Align(
                            alignment: Alignment.topCenter,
                            heightFactor: 1 / 3 + (2 / 3) * unfold,
                            child: LetterCard(text: widget.letterText, tilt: 0, textOpacity: ink),
                          ),
                        ),
                      ),
                    ),
                  ),
                // 3 · The pocket (the letter slides out from behind it), the
                //     closed flap and the seal.
                envelope(
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Positioned.fill(child: CustomPaint(painter: _PocketPainter())),
                      if (!flapBack) Positioned.fill(child: flapLayer),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: _envelopeHeight * 0.56 - 24,
                        child: Center(child: _CrackingSeal(progress: seal)),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: _headroom + _envelopeHeight + 6,
                  child: Opacity(
                    opacity: 1 - flap,
                    child: Text('TAP TO OPEN', style: AppText.button(size: 15, color: AppColors.burgundy)),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The back of the envelope: aged paper with the side and bottom folds,
/// a little foxing, and a faint London postmark.
class _PocketPainter extends CustomPainter {
  const _PocketPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(41);
    final body = _deckledRect(size, rnd, amp: 1.2, step: 16);
    canvas.drawShadow(body.shift(const Offset(0, 1.5)), AppColors.ink.withValues(alpha: 0.45), 2.5, false);
    canvas.drawPath(body, Paint()..color = _envelopeColor);

    canvas.save();
    canvas.clipPath(body);
    // Speckles and a little foxing near the corners.
    final speck = Paint()..color = AppColors.inkBrown.withValues(alpha: 0.07);
    for (var i = 0; i < 70; i++) {
      canvas.drawCircle(Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height), 0.4 + rnd.nextDouble() * 0.6, speck);
    }
    // Foxing: a few loose clusters of fine brown specks near the corners.
    final fox = Paint()..color = AppColors.inkBrown.withValues(alpha: 0.1);
    for (final (x, y) in [(0.07, 0.88), (0.93, 0.14), (0.9, 0.92)]) {
      final at = Offset(size.width * x, size.height * y);
      for (var i = 0; i < 14; i++) {
        final a = rnd.nextDouble() * 2 * math.pi;
        final d = rnd.nextDouble() * 14;
        canvas.drawCircle(at + Offset(math.cos(a), math.sin(a)) * d, 0.3 + rnd.nextDouble() * 0.7, fox);
      }
    }
    canvas.restore();

    // Side and bottom folds meeting under the flap.
    final fold = Paint()
      ..color = AppColors.ink.withValues(alpha: 0.28)
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppLine.hairline;
    final meet = Offset(size.width * 0.5, size.height * 0.5);
    canvas.drawPath(
      Path()
        ..moveTo(1.5, size.height - 1.5)
        ..quadraticBezierTo(size.width * 0.28, size.height * 0.62, meet.dx, meet.dy)
        ..quadraticBezierTo(size.width * 0.72, size.height * 0.62, size.width - 1.5, size.height - 1.5),
      fold,
    );

    // A faint handstamped postmark: two rings, the city, three wavy lines.
    final pm = Offset(size.width * 0.2, size.height * 0.74);
    final stampInk = Paint()
      ..color = AppColors.navy.withValues(alpha: 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    canvas.drawCircle(pm, 20, stampInk);
    canvas.drawCircle(pm, 15, stampInk..strokeWidth = 0.7);
    final tp = TextPainter(
      text: TextSpan(
        text: 'LONDON',
        style: TextStyle(fontFamily: AppText.display, fontSize: 6.5, fontWeight: FontWeight.w800, letterSpacing: 0.6, color: AppColors.navy.withValues(alpha: 0.4)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    canvas.save();
    canvas.translate(pm.dx, pm.dy);
    canvas.rotate(-0.15);
    tp.paint(canvas, Offset(-tp.width / 2, -tp.height / 2));
    canvas.restore();
    for (var i = 0; i < 3; i++) {
      final y = pm.dy - 8 + i * 8;
      final wave = Path()..moveTo(pm.dx + 24, y);
      for (var x = 0.0; x < 42; x += 7) {
        wave.relativeQuadraticBezierTo(3.5, i.isEven ? -2.5 : 2.5, 7, 0);
      }
      canvas.drawPath(wave, stampInk..strokeWidth = 0.9);
    }

    canvas.drawPath(body, fold..color = AppColors.ink.withValues(alpha: 0.22));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// The top flap. Its outside is manila; once folded back, its darker inside
/// shows.
class _FlapPainter extends CustomPainter {
  const _FlapPainter({required this.inside});

  final bool inside;

  @override
  void paint(Canvas canvas, Size size) {
    final tip = Offset(size.width * 0.505, size.height);
    final flap = Path()
      ..moveTo(0.5, 0.8)
      ..lineTo(size.width - 0.8, 0.4)
      ..quadraticBezierTo(size.width * 0.72, size.height * 0.7, tip.dx + 10, tip.dy - 3)
      ..quadraticBezierTo(tip.dx, tip.dy + 1, tip.dx - 10, tip.dy - 3)
      ..quadraticBezierTo(size.width * 0.28, size.height * 0.7, 0.5, 0.8)
      ..close();
    if (!inside) canvas.drawShadow(flap.shift(const Offset(0, 1)), AppColors.ink.withValues(alpha: 0.3), 1.2, false);
    canvas.drawPath(flap, Paint()..color = inside ? _envelopeInside : _envelopeColor);
    canvas.drawPath(
      flap,
      Paint()
        ..color = AppColors.ink.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppLine.hairline,
    );
  }

  @override
  bool shouldRepaint(_FlapPainter old) => old.inside != inside;
}

/// The wax seal on the flap. As [progress] goes 0 → 1 it cracks down the
/// middle and the two halves part and fade.
class _CrackingSeal extends StatelessWidget {
  const _CrackingSeal({required this.progress});

  final double progress;

  static const _size = 48.0;

  @override
  Widget build(BuildContext context) {
    if (progress >= 1) return const SizedBox(width: _size, height: _size);
    final gap = 5 * progress;
    Widget half(bool left) => ClipRect(
          child: Align(
            alignment: left ? Alignment.centerLeft : Alignment.centerRight,
            widthFactor: 0.5,
            child: const CustomPaint(size: Size.square(_size), painter: _WaxBlobPainter()),
          ),
        );
    return Opacity(
      opacity: (1 - progress * progress).clamp(0.0, 1.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.translate(offset: Offset(-gap, 2 * progress), child: Transform.rotate(angle: -0.12 * progress, child: half(true))),
          Transform.translate(offset: Offset(gap, 2 * progress), child: Transform.rotate(angle: 0.12 * progress, child: half(false))),
        ],
      ),
    );
  }
}

/// An irregular pool of sealing wax with a pressed ring and monogram.
class _WaxBlobPainter extends CustomPainter {
  const _WaxBlobPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(7);
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 1;
    const n = 12;
    final pts = [
      for (var i = 0; i < n; i++)
        c + Offset(math.cos(i * 2 * math.pi / n), math.sin(i * 2 * math.pi / n)) * r * (0.9 + rnd.nextDouble() * 0.1),
    ];
    Offset mid(Offset a, Offset b) => Offset((a.dx + b.dx) / 2, (a.dy + b.dy) / 2);
    final start = mid(pts.last, pts.first);
    final blob = Path()..moveTo(start.dx, start.dy);
    for (var i = 0; i < n; i++) {
      final m = mid(pts[i], pts[(i + 1) % n]);
      blob.quadraticBezierTo(pts[i].dx, pts[i].dy, m.dx, m.dy);
    }
    blob.close();
    canvas.drawShadow(blob, AppColors.ink.withValues(alpha: 0.4), 1, false);
    canvas.drawPath(blob, Paint()..color = AppColors.burgundy);
    canvas.drawCircle(
      c,
      r * 0.66,
      Paint()
        ..color = AppColors.paperLight.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    final tp = TextPainter(
      text: TextSpan(
        text: 'LM',
        style: TextStyle(fontFamily: AppText.display, fontSize: r * 0.55, fontWeight: FontWeight.w800, color: AppColors.paperLight.withValues(alpha: 0.8)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, c - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
