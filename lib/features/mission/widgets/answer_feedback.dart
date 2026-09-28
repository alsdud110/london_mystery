import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../data/models/mission.dart';
import '../../../widgets/badge_medal.dart';
import '../../../widgets/evidence_card.dart';
import '../../../widgets/game_button.dart';
import '../../../widgets/symbol_icon.dart';
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
    barrierColor: AppColors.navyDeep.withValues(alpha: 0.9),
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
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2600))
    ..forward();

  Animation<double> _iv(double begin, double end, [Curve curve = Curves.easeOut]) =>
      CurvedAnimation(parent: _c, curve: Interval(begin, end, curve: curve));

  late final _stamp = _iv(0, 0.18, Curves.easeOutBack);
  late final _xpRows = [_iv(0.2, 0.32), _iv(0.3, 0.42), _iv(0.4, 0.52)];
  late final _total = _iv(0.3, 0.62);
  late final _found = _iv(0.55, 0.72, Curves.easeOutBack);
  late final _badges = _iv(0.68, 0.85, Curves.elasticOut);
  late final _button = _iv(0.75, 0.9);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _o(Animation<double> a) => a.value.clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final xp = widget.xp;
    final rows = [
      ('Mission solved', xp.base, Icons.check_circle_rounded),
      ('No-hint bonus', xp.noHintBonus, Icons.lightbulb_outline_rounded),
      ('Speed bonus', xp.speedBonus, Icons.bolt_rounded),
    ];

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          Positioned.fill(child: IgnorePointer(child: _Confetti(animation: _c))),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: AnimatedBuilder(
                    animation: _c,
                    builder: (context, _) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Transform.scale(
                          scale: 2.2 - 1.2 * _stamp.value,
                          child: Transform.rotate(
                            angle: -0.1,
                            child: Opacity(opacity: _o(_stamp), child: const _SuccessStamp()),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Opacity(
                          opacity: _o(_stamp),
                          child: Column(
                            children: [
                              Text(
                                'Well done, Detective ${widget.detectiveName}!',
                                textAlign: TextAlign.center,
                                style: AppText.title(size: 24, color: AppColors.goldLight),
                              ),
                              const SizedBox(height: 4),
                              Text(widget.message,
                                  textAlign: TextAlign.center, style: AppText.subtitle(color: Colors.white)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        // XP breakdown: each row slides in, the total counts up.
                        Container(
                          padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
                          ),
                          child: Column(
                            children: [
                              for (final (i, (label, value, icon)) in rows.indexed)
                                if (value > 0)
                                  Opacity(
                                    opacity: _o(_xpRows[i]),
                                    child: Transform.translate(
                                      offset: Offset(24 * (1 - _xpRows[i].value), 0),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(vertical: 3),
                                        child: Row(
                                          children: [
                                            Icon(icon, color: AppColors.goldLight, size: 20),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(label, style: AppText.bodyText(size: 16, color: Colors.white)),
                                            ),
                                            Text('+$value', style: AppText.button(size: 17, color: AppColors.goldLight)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                              const Divider(color: Colors.white24, height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.star_rounded, color: AppColors.gold, size: 30),
                                  const SizedBox(width: 6),
                                  Text(
                                    '+${(xp.total * _total.value).round()} XP',
                                    style: AppText.title(size: 28, color: AppColors.gold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (widget.clue != null || widget.evidence != null)
                          Opacity(
                            opacity: _o(_found),
                            child: Transform.translate(
                              offset: Offset(0, 30 * (1 - _found.value)),
                              child: _FoundCard(clue: widget.clue, evidence: widget.evidence),
                            ),
                          ),
                        if (widget.newBadges.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Opacity(
                            opacity: _o(_badges),
                            child: Transform.scale(
                              scale: _badges.value.clamp(0.0, 1.2),
                              child: Column(
                                children: [
                                  Text('NEW BADGE!', style: AppText.eyebrow(color: AppColors.goldLight), textAlign: TextAlign.center),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    alignment: WrapAlignment.center,
                                    spacing: 12,
                                    children: [
                                      for (final b in widget.newBadges)
                                        _OnDark(child: BadgeMedal(badge: b, size: 58)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 22),
                        Opacity(
                          opacity: _o(_button),
                          child: IgnorePointer(
                            ignoring: _button.value < 0.5,
                            child: GameButton(
                              label: widget.buttonLabel,
                              icon: Icons.arrow_forward_rounded,
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

/// Medal labels are navy; give them a light backing on the dark overlay.
class _OnDark extends StatelessWidget {
  const _OnDark({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
        decoration: BoxDecoration(color: AppColors.paper, borderRadius: BorderRadius.circular(18)),
        child: child,
      );
}

class _FoundCard extends StatelessWidget {
  const _FoundCard({this.clue, this.evidence});

  final Clue? clue;
  final Evidence? evidence;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.gold, width: 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.auto_awesome_rounded, color: AppColors.goldDeep, size: 20),
              const SizedBox(width: 6),
              Flexible(child: Text('ADDED TO YOUR NOTEBOOK', style: AppText.eyebrow(), textAlign: TextAlign.center)),
            ],
          ),
          const SizedBox(height: 12),
          if (clue != null)
            Row(
              children: [
                SymbolBadge(clue!.symbol, size: 56),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('CLUE', style: AppText.eyebrow()),
                      Text('"${clue!.title}"', style: AppText.title(size: 20)),
                    ],
                  ),
                ),
              ],
            ),
          if (clue != null && evidence != null) const Divider(height: 22, color: AppColors.parchmentDark),
          if (evidence != null) EvidenceChip(evidence: evidence!),
        ],
      ),
    );
  }
}

class _SuccessStamp extends StatelessWidget {
  const _SuccessStamp();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold, width: 5),
        color: AppColors.navy,
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_rounded, color: AppColors.gold, size: 40),
            const SizedBox(width: 10),
            Text('SUCCESS!', style: AppText.logo(size: 38, color: AppColors.gold)),
          ],
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
  static const _colors = [AppColors.gold, AppColors.goldLight, AppColors.royalBlue, Colors.white, AppColors.waxRed];

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
