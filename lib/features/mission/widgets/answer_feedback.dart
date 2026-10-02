import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/models/mission.dart';
import '../../../widgets/game_button.dart';
import '../../../widgets/ink_icon.dart';
import '../../../widgets/detective_tips.dart';
import '../../../widgets/paper.dart';
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
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
  bool _closing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.isDismissed) {
      // Reduced motion: show the finished page at once (no slam, no count-up).
      if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
        _c.value = 1;
      } else {
        _c.forward();
      }
    }
  }

  /// A tap anywhere while the stamp is still coming down finishes the
  /// moment at once, so a child never has to wait for the button.
  void _finishNow() {
    if (_c.isAnimating) _c.value = 1;
  }

  /// Continue exactly once, however many times the button is tapped.
  void _close() {
    if (_closing) return;
    _closing = true;
    Navigator.of(context).pop();
  }

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
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _finishNow,
        child: Stack(
        children: [
          // A pool of lamplight on the dark desk, where the stamp comes down.
          const Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _LampLightPainter()))),
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
                                  textAlign: TextAlign.center,
                                  style: AppText.title(size: 21, color: AppColors.paperLight).copyWith(height: 1.35)),
                              if (clue != null) ...[
                                const SizedBox(height: AppSpace.lg),
                                // The clue, pinned to the desk on a slip of paper.
                                Transform.rotate(
                                  angle: -0.02,
                                  child: Container(
                                    padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.md),
                                    decoration: BoxDecoration(
                                      color: AppColors.paperLight,
                                      borderRadius: BorderRadius.circular(AppRadius.paper),
                                      boxShadow: AppShadow.onNight,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const InkIcon(InkGlyph.search, size: AppIconSize.medium, color: AppColors.burgundy),
                                        const SizedBox(width: AppSpace.sm),
                                        Flexible(
                                          child: Text('New clue: "${clue.title}"',
                                              textAlign: TextAlign.center, style: AppText.letter(size: 18)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpace.lg),
                        Opacity(
                          opacity: _o(_xp),
                          child: Text(
                            '+${(widget.xp.total * _xp.value).round()} XP',
                            style: AppText.style(AppText.display, size: 20, weight: FontWeight.w700, color: AppColors.goldLight, letterSpacing: 2)
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
                              onPressed: _close,
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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.paper,
                border: Border.all(color: AppColors.tryAgain.withValues(alpha: 0.6), width: AppLine.ink),
              ),
              foregroundDecoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.tryAgain.withValues(alpha: 0.25), width: AppLine.hairline),
              ),
              // "Good detectives look again": the magnifier.
              child: const InkIcon(InkGlyph.search, size: AppIconSize.hero - 8, color: AppColors.tryAgain),
            ),
            const SizedBox(height: 14),
            Text('Not quite!', style: AppText.title(size: 30, color: AppColors.tryAgain)),
            const SizedBox(height: AppSpace.sm),
            const OrnamentRule(color: AppColors.tryAgain),
            const SizedBox(height: AppSpace.sm),
            Text(
              'Good detectives look again.\nRead the clue one more time!',
              textAlign: TextAlign.center,
              style: AppText.bodyText(size: 17),
            ),
            const SizedBox(height: 20),
            // Custom Asset Required: a retry glyph.
            GameButton(
              label: 'TRY AGAIN',
              onPressed: () => Navigator.of(context).pop(TryAgainChoice.retry),
            ),
            if (hintAvailable) ...[
              const SizedBox(height: 12),
              GameButton(
                label: tipButtonLabel,
                glyph: InkGlyph.hint,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < revealed && i < hints.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.md),
            child: _TipNote(number: i + 1, text: hints[i]),
          ),
        // The same secondary button and words as the try-again sheet.
        if (canReveal)
          GameButton(
            label: tipButtonLabel,
            glyph: InkGlyph.hint,
            style: GameButtonStyle.outline,
            onPressed: onReveal,
          ),
        if (canReveal)
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.xs),
            child: Text(
              revealed == 0 ? 'A tip uses a little of your bonus XP.' : 'Tip ${revealed + 1} of ${hints.length}',
              textAlign: TextAlign.center,
              style: AppText.caption(color: dark ? AppColors.paperLight.withValues(alpha: 0.8) : AppColors.muted),
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
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(opacity: t.clamp(0, 1), child: child),
      // A handwritten note, the same as the tips of every mission.
      child: PaperSheet(
        tilt: number.isOdd ? -0.008 : 0.008,
        padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('DETECTIVE TIP $number', style: AppText.eyebrow()),
            const SizedBox(height: AppSpace.xs),
            Text(text, style: AppText.letter(size: 17)),
          ],
        ),
      ),
    );
  }
}

/// Warm light falling on the dark desk behind the "WELL DONE" stamp.
class _LampLightPainter extends CustomPainter {
  const _LampLightPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final pool = Rect.fromCircle(center: Offset(size.width / 2, size.height * 0.36), radius: size.longestSide * 0.55);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [AppColors.royalBlue.withValues(alpha: 0.30), AppColors.navy.withValues(alpha: 0.30), Colors.transparent],
          stops: const [0, 0.5, 1],
        ).createShader(pool),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
