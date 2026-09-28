import 'dart:math' as math;

import 'package:flutter/material.dart';


import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import 'glossary_text.dart';

/// An aged parchment letter with a wax seal.
class LetterCard extends StatelessWidget {
  const LetterCard({super.key, required this.text, this.tilt = -0.012});

  final String text;
  final double tilt;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: tilt,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 30),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF8E6), AppColors.parchment, Color(0xFFEBD9AF)],
          ),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.parchmentDark, width: 1.5),
          boxShadow: const [
            BoxShadow(color: Color(0x33000000), blurRadius: 14, offset: Offset(0, 6)),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              right: -8,
              top: -14,
              child: const WaxSeal(size: 44),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 24),
              child: GlossaryText(text, style: AppText.letter()),
            ),
          ],
        ),
      ),
    );
  }
}

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
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          center: Alignment(-0.3, -0.3),
          colors: [Color(0xFFD6574F), AppColors.waxRed, Color(0xFF8E2C27)],
        ),
        boxShadow: const [BoxShadow(color: Color(0x44000000), blurRadius: 4, offset: Offset(1, 2))],
        border: Border.all(color: const Color(0xFF9E3530), width: 2),
      ),
      child: Text(
        letter,
        style: AppText.style(AppText.display, size: size * 0.3, weight: FontWeight.w800, color: const Color(0xFFF7D2C8)),
      ),
    );
  }
}

/// A sealed envelope the player taps to open; it then reveals the letter.
class EnvelopeReveal extends StatefulWidget {
  const EnvelopeReveal({super.key, required this.letterText, this.initiallyOpen = false, this.onOpened});

  final String letterText;
  final bool initiallyOpen;
  final VoidCallback? onOpened;

  @override
  State<EnvelopeReveal> createState() => _EnvelopeRevealState();
}

class _EnvelopeRevealState extends State<EnvelopeReveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
    value: widget.initiallyOpen ? 1 : 0,
  );
  late bool _open = widget.initiallyOpen;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openEnvelope() async {
    if (_controller.isAnimating || _open) return;
    await _controller.forward();
    if (!mounted) return;
    setState(() => _open = true);
    widget.onOpened?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (_open) {
      return TweenAnimationBuilder<double>(
        tween: Tween(begin: widget.initiallyOpen ? 1 : 0, end: 1),
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeOutBack,
        builder: (context, t, child) => Opacity(
          opacity: t.clamp(0, 1),
          child: Transform.translate(offset: Offset(0, 30 * (1 - t)), child: child),
        ),
        child: LetterCard(text: widget.letterText),
      );
    }

    return Semantics(
      button: true,
      label: 'Sealed letter. Tap to open.',
      child: GestureDetector(
        onTap: _openEnvelope,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final flap = Curves.easeInOut.transform((_controller.value / 0.45).clamp(0, 1));
            final rise = Curves.easeOut.transform(((_controller.value - 0.4) / 0.6).clamp(0, 1));
            return SizedBox(
              height: 210,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // Letter sliding out.
                  Positioned(
                    top: 40 - 70 * rise,
                    left: 40,
                    right: 40,
                    child: Opacity(
                      opacity: rise,
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.parchment,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.parchmentDark),
                        ),
                      ),
                    ),
                  ),
                  // Envelope body.
                  Positioned(
                    top: 50,
                    left: 12,
                    right: 12,
                    height: 150,
                    child: CustomPaint(painter: _EnvelopeBodyPainter()),
                  ),
                  // Flap folding back.
                  Positioned(
                    top: 50,
                    left: 12,
                    right: 12,
                    height: 90,
                    child: Transform(
                      alignment: Alignment.topCenter,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.0015)
                        ..rotateX(math.pi * flap),
                      child: CustomPaint(painter: _EnvelopeFlapPainter(back: flap > 0.5)),
                    ),
                  ),
                  if (flap < 0.5)
                    const Positioned(top: 104, child: WaxSeal(size: 56)),
                  Positioned(
                    bottom: -6,
                    child: Opacity(
                      opacity: 1 - flap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.navy,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text('TAP TO OPEN', style: AppText.button(size: 14, color: AppColors.goldLight)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _EnvelopeBodyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(10));
    canvas.drawRRect(rect.shift(const Offset(0, 5)), Paint()..color = const Color(0x22000000));
    canvas.drawRRect(rect, Paint()..color = const Color(0xFFEAD6A8));
    final fold = Paint()
      ..color = const Color(0xFFD7BF88)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawLine(Offset(0, size.height), Offset(size.width / 2, size.height * 0.45), fold);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width / 2, size.height * 0.45), fold);
    canvas.drawRRect(rect, Paint()
      ..color = AppColors.parchmentDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _EnvelopeFlapPainter extends CustomPainter {
  _EnvelopeFlapPainter({required this.back});

  final bool back;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = back ? const Color(0xFFD9C08A) : const Color(0xFFF1DFB5));
    canvas.drawPath(path, Paint()
      ..color = AppColors.parchmentDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
  }

  @override
  bool shouldRepaint(_EnvelopeFlapPainter old) => old.back != back;
}
