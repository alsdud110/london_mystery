import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/models/discovery.dart';
import '../../../data/models/mission.dart';
import '../../../widgets/evidence_card.dart';
import '../../../widgets/game_button.dart';
import '../../../widgets/ink_icon.dart';
import '../../../widgets/detective_tips.dart';
import '../../../widgets/paper.dart';
import '../../../widgets/place_art.dart';
import '../../../widgets/place_scenery.dart';
import '../../game/scoring.dart';

/// The Discovery Moment, after a regular mission's correct answer: in the
/// place the puzzle was solved, what the detective just found or worked
/// out ([discovery]), then the XP and any new badge, then [buttonLabel].
/// Everything is already saved before it opens; it only shows it. Returns
/// when the detective continues (or goes back).
Future<void> showDiscoveryMoment(
  BuildContext context, {
  required Mission mission,
  required Discovery discovery,
  required XpBreakdown xp,
  String buttonLabel = 'CONTINUE',
  List<GameBadge> newBadges = const [],
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierLabel: discovery.type.label,
    // The same night as the place's scenery, so the page dims into it.
    barrierColor: AppColors.navyDeep,
    transitionDuration: const Duration(milliseconds: 300),
    pageBuilder: (context, _, _) => _DiscoveryMoment(
      mission: mission,
      discovery: discovery,
      buttonLabel: buttonLabel,
      xp: xp,
      newBadges: newBadges,
    ),
    transitionBuilder: (context, anim, _, child) => FadeTransition(opacity: anim, child: child),
  );
}

class _DiscoveryMoment extends StatefulWidget {
  const _DiscoveryMoment({
    required this.mission,
    required this.discovery,
    required this.buttonLabel,
    required this.xp,
    required this.newBadges,
  });

  final Mission mission;
  final Discovery discovery;
  final String buttonLabel;
  final XpBreakdown xp;
  final List<GameBadge> newBadges;

  @override
  State<_DiscoveryMoment> createState() => _DiscoveryMomentState();
}

class _DiscoveryMomentState extends State<_DiscoveryMoment> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));
  bool _closing = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.isDismissed) {
      // Reduced motion: show the finished page at once (no reveal, no count-up).
      if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
        _c.value = 1;
      } else {
        _c.forward();
      }
    }
  }

  /// A tap anywhere while the discovery is still being laid out finishes
  /// it at once, so a child never has to wait for the button.
  void _finishNow() {
    if (_c.isAnimating) _c.value = 1;
  }

  /// Continue exactly once, however many times the button is tapped.
  void _close() {
    if (_closing) return;
    _closing = true;
    Navigator.of(context).pop();
  }

  Animation<double> _iv(double begin, double end) =>
      CurvedAnimation(parent: _c, curve: Interval(begin, end, curve: Curves.easeOutCubic));

  // What was found leads; the reward follows; the button comes last.
  late final _label = _iv(0.05, 0.25);
  late final _title = _iv(0.15, 0.4);
  late final _evidence = _iv(0.3, 0.55);
  late final _detail = _iv(0.4, 0.6);
  late final _xp = _iv(0.55, 0.75);
  late final _badges = _iv(0.65, 0.8);
  late final _button = _iv(0.75, 0.9);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _o(Animation<double> a) => a.value.clamp(0.0, 1.0);

  /// Fades in, rising a few pixels: a quiet reveal, no bounce.
  Widget _rise(Animation<double> a, Widget child) => Opacity(
        opacity: _o(a),
        child: Transform.translate(offset: Offset(0, 8 * (1 - _o(a))), child: child),
      );

  @override
  Widget build(BuildContext context) {
    final d = widget.discovery;
    final m = widget.mission;
    final evidence = d.showEvidence ? m.evidence : null;
    final soft = AppColors.paperLight.withValues(alpha: 0.88);
    return Material(
      key: const ValueKey('discovery-moment'),
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _finishNow,
        child: Stack(
          children: [
            // Still at the scene: the place of the puzzle, in the dark.
            Positioned.fill(child: IgnorePointer(child: PlaceScenery(PlaceArt.sceneryOf(m)))),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(AppSpace.xl, AppSpace.xl, AppSpace.xl, AppSpace.xl),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: AnimatedBuilder(
                      animation: _c,
                      builder: (context, _) => Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 1. What kind of discovery, in words.
                          _rise(
                            _label,
                            Semantics(
                              header: true,
                              child: Column(
                                children: [
                                  Text(d.type.label,
                                      textAlign: TextAlign.center, style: AppText.mark(color: AppColors.goldLight, size: 17)),
                                  const SizedBox(height: AppSpace.xs),
                                  const OrnamentRule(color: AppColors.goldLight),
                                  if (d.seasonClue) ...[
                                    const SizedBox(height: AppSpace.sm),
                                    Text('ALSO A SEASON CLUE',
                                        textAlign: TextAlign.center,
                                        style: AppText.eyebrow(color: AppColors.paperLight.withValues(alpha: 0.75))),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpace.lg),
                          // 2. What was found or worked out.
                          _rise(
                            _title,
                            Text(d.title,
                                textAlign: TextAlign.center,
                                style: AppText.placeTitle(size: 30, color: AppColors.paperLight).copyWith(height: 1.2)),
                          ),
                          // 3. The evidence itself, laid down at the scene.
                          if (evidence != null) ...[
                            const SizedBox(height: AppSpace.lg),
                            _rise(_evidence, _EvidenceSlip(evidence: evidence, location: m.location)),
                          ],
                          // 4. One supporting sentence, and what the notebook keeps.
                          if (d.detail.isNotEmpty) ...[
                            const SizedBox(height: AppSpace.lg),
                            _rise(
                              _detail,
                              Text(d.detail,
                                  textAlign: TextAlign.center, style: AppText.bodyText(size: 18, color: soft).copyWith(height: 1.4)),
                            ),
                          ],
                          if (d.note case final note?) ...[
                            const SizedBox(height: AppSpace.md),
                            _rise(_detail, _NotebookNote(note)),
                          ],
                          const SizedBox(height: AppSpace.xl),
                          // 5. The reward, small.
                          Opacity(
                            opacity: _o(_xp),
                            child: Text(
                              '+${(widget.xp.total * _xp.value).round()} XP',
                              style: AppText.style(AppText.body,
                                      size: 16, weight: FontWeight.w700, color: AppColors.goldLight, letterSpacing: 2)
                                  .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                            ),
                          ),
                          // Only when a badge was just earned: one small line.
                          if (widget.newBadges.isNotEmpty) ...[
                            const SizedBox(height: AppSpace.sm),
                            Opacity(
                              opacity: _o(_badges),
                              child: Text(
                                'New badge: ${widget.newBadges.map((b) => b.title).join(' · ')}',
                                textAlign: TextAlign.center,
                                style: AppText.caption(color: AppColors.paperLight.withValues(alpha: 0.75)),
                              ),
                            ),
                          ],
                          const SizedBox(height: AppSpace.xl),
                          // 6. On only when the detective chooses.
                          Opacity(
                            opacity: _o(_button),
                            child: IgnorePointer(
                              ignoring: _button.value < 0.5,
                              child: GameButton(
                                label: widget.buttonLabel,
                                arrow: true,
                                style: GameButtonStyle.glass,
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

/// The evidence on a paper card, with what is written on it: the same card
/// as after a case is closed. Tap to look closer (as in the notebook).
class _EvidenceSlip extends StatelessWidget {
  const _EvidenceSlip({required this.evidence, required this.location});

  final Evidence evidence;
  final String location;

  @override
  Widget build(BuildContext context) {
    final note = evidence.inscription;
    return Semantics(
      button: true,
      label: '${evidence.name}. ${note ?? ''} Tap to look closer.',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => showEvidenceZoom(context, evidence, location: location),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: PaperSheet(
            ruled: true,
            tilt: -0.012,
            padding: const EdgeInsets.all(AppSpace.lg),
            child: EvidenceChip(evidence: evidence, note: note),
          ),
        ),
      ),
    );
  }
}

/// A fact the notebook keeps from before the puzzle: small, as noted.
class _NotebookNote extends StatelessWidget {
  const _NotebookNote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.paperLight.withValues(alpha: 0.78);
    return Semantics(
      label: 'Noted in your notebook: $text',
      excludeSemantics: true,
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkIcon(InkGlyph.notebook, size: AppIconSize.small, color: color),
              const SizedBox(width: AppSpace.xs),
              Flexible(child: Text('NOTED IN YOUR NOTEBOOK', textAlign: TextAlign.center, style: AppText.eyebrow(color: color))),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          Text(text, textAlign: TextAlign.center, style: AppText.bodyText(size: 16, color: color)),
        ],
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
    // A paper slip on the casebook (this sheet only; the others keep the
    // app's sheet theme): nearly square corners, and a thin ink-brown tab
    // in place of the grey handle (the whole sheet still drags to close).
    shape: paperSheetShape,
    showDragHandle: false,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PaperSheetTab(),
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
