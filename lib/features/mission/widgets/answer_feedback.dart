import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/models/mission.dart';
import '../../../widgets/game_button.dart';
import '../../game/scoring.dart';

/// Full-screen celebration after a correct answer.
Future<void> showSuccessOverlay(
  BuildContext context, {
  required String detectiveName,
  required String message,
  required String buttonLabel,
  required XpBreakdown xp,
  Clue? clue,
  Evidence? evidence,
  List<GameBadge> newBadges = const [],
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    // Opaque once faded in: the page behind must not compete with the moment.
    barrierColor: AppColors.navyDeep,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, _, _) => _SuccessOverlay(
      detectiveName: detectiveName,
      message: message,
      buttonLabel: buttonLabel,
      xp: xp,
      clue: clue,
      evidence: evidence,
      newBadges: newBadges,
    ),
    transitionBuilder: (context, anim, _, child) => FadeTransition(opacity: anim, child: child),
  );
}

class _SuccessOverlay extends StatefulWidget {
  const _SuccessOverlay({
    required this.detectiveName,
    required this.message,
    required this.buttonLabel,
    required this.xp,
    required this.clue,
    required this.evidence,
    required this.newBadges,
  });

  final String detectiveName;
  final String message;
  final String buttonLabel;
  final XpBreakdown xp;
  final Clue? clue;
  final Evidence? evidence;
  final List<GameBadge> newBadges;

  @override
  State<_SuccessOverlay> createState() => _SuccessOverlayState();
}

class _SuccessOverlayState extends State<_SuccessOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))
    ..forward();

  Animation<double> _iv(double begin, double end, [Curve curve = Curves.easeOut]) =>
      CurvedAnimation(parent: _c, curve: Interval(begin, end, curve: curve));

  // Same beats as before: the stamp slams down, the line appears, the XP
  // counts up, a new badge (if any) follows, then the button.
  late final _stamp = _iv(0, 0.2, Curves.easeOutCubic);
  late final _line = _iv(0.2, 0.4);
  late final _xp = _iv(0.3, 0.6);
  late final _badges = _iv(0.55, 0.75);
  late final _button = _iv(0.7, 0.88);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _o(Animation<double> a) => a.value.clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final clue = widget.clue;
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(child: IgnorePointer(child: _Confetti(animation: _c))),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpace.xl),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: AnimatedBuilder(
                    animation: _c,
                    builder: (context, _) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.scale(
                          scale: 1.8 - 0.8 * _stamp.value,
                          child: Opacity(opacity: _o(_stamp), child: const _WellDoneStamp()),
                        ),
                        const SizedBox(height: AppSpace.xxl),
                        Opacity(
                          opacity: _o(_line),
                          child: Column(
                            children: [
                              Text(widget.message,
                                  textAlign: TextAlign.center, style: AppText.subtitle(color: AppColors.paperLight)),
                              if (clue != null) ...[
                                const SizedBox(height: AppSpace.sm),
                                Text('New clue: "${clue.title}"',
                                    textAlign: TextAlign.center, style: AppText.bodyText(size: 16, color: AppColors.goldLight)),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpace.lg),
                        Opacity(
                          opacity: _o(_xp),
                          child: Text(
                            '+${(widget.xp.total * _xp.value).round()} XP',
                            style: AppText.caption(color: AppColors.goldLight)
                                .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                          ),
                        ),
                        // Only when a badge was just earned: one small line.
                        if (widget.newBadges.isNotEmpty) ...[
                          const SizedBox(height: AppSpace.lg),
                          Opacity(
                            opacity: _o(_badges),
                            child: Text(
                              'New badge: ${widget.newBadges.map((b) => b.title).join(' · ')}',
                              textAlign: TextAlign.center,
                              style: AppText.caption(color: AppColors.paperLight.withValues(alpha: 0.75)),
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpace.xxl),
                        Opacity(
                          opacity: _o(_button),
                          child: IgnorePointer(
                            ignoring: _button.value < 0.5,
                            child: GameButton(
                              label: widget.buttonLabel,
                              arrow: true,
                              style: GameButtonStyle.gold,
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The big rubber stamp: "WELL DONE", inked in antique gold.
class _WellDoneStamp extends StatelessWidget {
  const _WellDoneStamp();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.08,
      child: Container(
        padding: const EdgeInsets.fromLTRB(AppSpace.xl, AppSpace.md, AppSpace.xl, AppSpace.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.paper),
          border: Border.all(color: AppColors.goldLight, width: 4),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.sm),
          decoration: BoxDecoration(
            border: Border.symmetric(horizontal: BorderSide(color: AppColors.goldLight.withValues(alpha: 0.6), width: 1.5)),
          ),
          child: Text('WELL DONE', style: AppText.logo(size: 36, color: AppColors.goldLight)),
        ),
      ),
    );
  }
}

class _Confetti extends StatelessWidget {
  const _Confetti({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _ConfettiPainter(animation));
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.animation) : super(repaint: animation);

  final Animation<double> animation;
  static const _colors = [AppColors.gold, AppColors.goldLight, AppColors.royalBlue, AppColors.paperLight, AppColors.burgundy];

  @override
  void paint(Canvas canvas, Size size) {
    final t = animation.value;
    if (t >= 1) return;
    final rnd = math.Random(3);
    for (var i = 0; i < 60; i++) {
      final x = rnd.nextDouble() * size.width;
      final speed = 0.6 + rnd.nextDouble() * 0.8;
      final y = -20 + (size.height + 40) * (t * speed);
      final sway = math.sin(t * 10 + i) * 18;
      final paint = Paint()..color = _colors[i % _colors.length].withValues(alpha: (1 - t).clamp(0, 1));
      canvas.save();
      canvas.translate(x + sway, y);
      canvas.rotate(t * 8 + i);
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-4, -7, 8, 14), const Radius.circular(2)), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => false;
}

enum TryAgainChoice { retry, hint }

/// Gentle, encouraging feedback for a wrong answer.
Future<TryAgainChoice> showTryAgainSheet(BuildContext context, {required bool hintAvailable}) async {
  final choice = await showModalBottomSheet<TryAgainChoice>(
    context: context,
    // Let the sheet grow past the default 9/16 of the screen (both buttons
    // must fit on small phones) and scroll if it still does not fit.
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: const BoxDecoration(color: AppColors.tryAgainSoft, shape: BoxShape.circle),
              child: const Icon(Icons.psychology_alt_rounded, size: 50, color: AppColors.tryAgain),
            ),
            const SizedBox(height: 14),
            Text('Not quite!', style: AppText.title(size: 30, color: AppColors.tryAgain)),
            const SizedBox(height: 6),
            Text(
              'Good detectives look again.\nRead the clue one more time!',
              textAlign: TextAlign.center,
              style: AppText.bodyText(size: 17),
            ),
            const SizedBox(height: 20),
            GameButton(
              label: 'TRY AGAIN',
              icon: Icons.refresh_rounded,
              onPressed: () => Navigator.of(context).pop(TryAgainChoice.retry),
            ),
            if (hintAvailable) ...[
              const SizedBox(height: 12),
              GameButton(
                label: '💡 GET A TIP',
                style: GameButtonStyle.outline,
                onPressed: () => Navigator.of(context).pop(TryAgainChoice.hint),
              ),
            ],
          ],
        ),
      ),
    ),
  );
  return choice ?? TryAgainChoice.retry;
}

/// "Detective Tips": up to two hints, revealed one at a time. Framed as a
/// partner's help (not a failure); the small bonus cost is stated kindly.
class TipsPanel extends StatelessWidget {
  const TipsPanel({super.key, required this.hints, required this.revealed, required this.onReveal, this.dark = false});

  final List<String> hints;
  final int revealed;
  final VoidCallback onReveal;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final canReveal = revealed < hints.length;
    final label = revealed == 0 ? 'NEED A TIP?' : 'ONE MORE TIP';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < revealed && i < hints.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _TipNote(number: i + 1, text: hints[i]),
          ),
        if (canReveal)
          Center(
            child: TextButton.icon(
              onPressed: onReveal,
              style: TextButton.styleFrom(
                minimumSize: const Size(200, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                backgroundColor: dark ? Colors.white.withValues(alpha: 0.08) : AppColors.goldLight.withValues(alpha: 0.35),
              ),
              icon: const Text('💡', style: TextStyle(fontSize: 22)),
              label: Text(label, style: AppText.button(size: 16, color: dark ? AppColors.goldLight : AppColors.goldDeep)),
            ),
          ),
        if (canReveal)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              revealed == 0 ? 'A tip uses a little of your bonus XP.' : 'Tip ${revealed + 1} of ${hints.length}',
              textAlign: TextAlign.center,
              style: AppText.caption(color: dark ? Colors.white60 : AppColors.muted),
            ),
          ),
      ],
    );
  }
}

class _TipNote extends StatelessWidget {
  const _TipNote({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutBack,
      builder: (context, t, child) =>
          Transform.scale(scale: 0.8 + 0.2 * t, child: Opacity(opacity: t.clamp(0, 1), child: child)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1B8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gold, width: 2),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('💡', style: TextStyle(fontSize: 26)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DETECTIVE TIP $number', style: AppText.eyebrow()),
                  const SizedBox(height: 4),
                  Text(text, style: AppText.bodyText(size: 17, weight: FontWeight.w700, color: AppColors.inkBrown)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
