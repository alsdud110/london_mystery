import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/audio_service.dart';
import '../../../data/models/discovery.dart';
import '../../../data/models/mission.dart';
import '../../../widgets/detective_character.dart';
import '../../../widgets/evidence_card.dart';
import '../../../widgets/game_button.dart';
import '../../../widgets/glossary_text.dart';
import '../../../widgets/ink_icon.dart';
import '../../../widgets/detective_tips.dart';
import '../../../widgets/paper.dart';
import '../../../widgets/place_art.dart';
import '../../../widgets/place_scenery.dart';
import '../../game/scoring.dart';
import '../../mission_map/map_world.dart' show SeasonMap;

/// The Discovery Moment, after a regular mission's correct answer: in the
/// place the puzzle was solved, a short cheer ("Brilliant Deduction!"), what
/// the detective just found or worked out ([discovery]), then the XP and any
/// new badge, then [buttonLabel]. A mission solved before ([firstSolve]
/// false: Play again) earns nothing new, and says so instead of the reward.
/// Everything is already saved before it opens; it only shows it. Returns
/// when the detective continues (or goes back).
/// The way on from a solve (the Discovery Moment, the final case opened).
const continueInvestigation = 'CONTINUE INVESTIGATION';

/// Said in place of the reward when a mission solved before is solved again
/// (Play again): its XP and coins were counted the first time.
const alreadyRewarded = 'Already in your case file';

Future<void> showDiscoveryMoment(
  BuildContext context, {
  required Mission mission,
  required Discovery discovery,
  required XpBreakdown xp,
  int coins = 0,
  bool firstSolve = true,
  String buttonLabel = continueInvestigation,
  List<GameBadge> newBadges = const [],
  VoidCallback? onEvidenceLaid,
  bool showDetective = false,
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
      coins: coins,
      firstSolve: firstSolve,
      newBadges: newBadges,
      onEvidenceLaid: onEvidenceLaid,
      showDetective: showDetective,
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
    this.coins = 0,
    this.firstSolve = true,
    this.onEvidenceLaid,
    this.showDetective = false,
  });

  final Mission mission;
  final Discovery discovery;
  final String buttonLabel;
  final XpBreakdown xp;

  /// Coins this solve paid (0 for a mission paid before: not shown).
  final int coins;

  /// False for a mission solved before: no reward is announced.
  final bool firstSolve;
  final List<GameBadge> newBadges;

  /// The evidence card has just been laid down (only when one is shown).
  final VoidCallback? onEvidenceLaid;

  /// The player's detective greets the solve, small, with the cheer:
  /// surprised by a new find, happy otherwise (see [DetectiveMoment]).
  final bool showDetective;

  @override
  State<_DiscoveryMoment> createState() => _DiscoveryMomentState();
}

class _DiscoveryMomentState extends State<_DiscoveryMoment> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1650))
    ..addListener(_layEvidence);
  bool _closing = false;

  /// Where the evidence card, rising into place over 0.3..0.55, lands.
  static const _evidenceLands = 0.38;
  bool _evidenceLaid = false;

  /// Once, as the card lands (at once when a tap or reduced motion
  /// finishes the page).
  void _layEvidence() {
    if (_evidenceLaid || _c.value < _evidenceLands) return;
    if (!widget.discovery.showEvidence || widget.mission.evidence == null) return;
    _evidenceLaid = true;
    widget.onEvidenceLaid?.call();
  }

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
  late final _label = _iv(0.0, 0.2);
  late final _title = _iv(0.12, 0.34);
  late final _evidence = _iv(0.28, 0.5);
  late final _detail = _iv(0.38, 0.58);
  late final _xp = _iv(0.53, 0.73);
  late final _badges = _iv(0.63, 0.78);
  late final _button = _iv(0.73, 0.88);

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
    // Something new in hand is a surprise; any other solve, a joy.
    final moment = switch (d.type) {
      DiscoveryType.evidenceFound || DiscoveryType.clueFound => DetectiveMoment.newFind,
      _ => DetectiveMoment.missionSolved,
    };
    final detective = widget.showDetective && DetectiveCast.shows(moment);
    // The detective at the scene, waist up (their hands and what they hold),
    // above the cheer: no wider than the evidence card, shorter on a short
    // phone so the find and the button keep their room.
    final detectiveSize = MediaQuery.sizeOf(context).height < 700 ? 120.0 : 160.0;
    return Material(
      key: const ValueKey('discovery-moment'),
      type: MaterialType.transparency,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _finishNow,
        child: Stack(
          children: [
            // Still at the scene: the place of the puzzle, in the dark.
            Positioned.fill(
              child: IgnorePointer(child: PlaceScenery(PlaceArt.sceneryOf(m), map: SeasonMap.ofMission(m.id))),
            ),
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
                          // 1. The cheer: the solve is greeted first.
                          _rise(
                            _label,
                            Semantics(
                              header: true,
                              label: '${d.type.cheer} ${d.type.label}',
                              excludeSemantics: true,
                              child: Column(
                                children: [
                                  if (detective) ...[
                                    // Its foot fades out: the cheer sits just under it.
                                    PlayerDetective(moment: moment, size: detectiveSize, entrance: false, halo: true),
                                    const SizedBox(height: AppSpace.xs),
                                  ],
                                  Text(d.type.cheer,
                                      textAlign: TextAlign.center,
                                      style: AppText.cinematicPrompt(size: 28, color: AppColors.goldLight)),
                                  const SizedBox(height: AppSpace.sm),
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
                                style: AppText.placeTitle(size: 26, color: AppColors.paperLight).copyWith(height: 1.2)),
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
                          // 5. The reward, small (counted once: a mission
                          // solved before only says it is already counted).
                          Opacity(
                            opacity: _o(_xp),
                            child: widget.firstSolve
                                ? Text(
                                    '+${(widget.xp.total * _xp.value).round()} XP'
                                    '${widget.coins > 0 ? '   ·   +${(widget.coins * _xp.value).round()} COINS' : ''}',
                                    style: AppText.style(AppText.body,
                                            size: 16, weight: FontWeight.w700, color: AppColors.goldLight, letterSpacing: 2)
                                        .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                                  )
                                : Text(alreadyRewarded,
                                    textAlign: TextAlign.center,
                                    style: AppText.aside(size: 15, color: AppColors.paperLight.withValues(alpha: 0.8))),
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
                                tap: TapRole.primary,
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
///
/// [message] is the mission's line for this wrong answer (what was probably
/// misread); without one, the general "look again" line is shown.
/// [showDetective]: the player's detective, thinking, in place of the
/// magnifier (the game's pages; needs the app's providers).
Future<TryAgainChoice> showTryAgainSheet(
  BuildContext context, {
  required bool hintAvailable,
  String? message,
  bool showDetective = false,
}) async {
  // The medallion takes the magnifier's place, at the same size.
  const mark = 84.0;
  final detective = showDetective && DetectiveCast.shows(DetectiveMoment.lookAgain);
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
            if (detective)
              // "Good detectives look again": the player's detective, thinking.
              const PlayerDetective(moment: DetectiveMoment.lookAgain, size: mark - 2 * DetectiveCharacter.rim)
            else
              Container(
                width: mark,
                height: mark,
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
            GlossaryText(
              message ?? 'Good detectives look again.\nRead the clue one more time!',
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

/// "Detective Hints": up to two hints, revealed one at a time. Framed as
/// help on the way (not a failure). Hints never cost XP; hint 2 costs coins,
/// or is given free when the coins are short (see tip_shop.dart).
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
        // The same hint notes as on every puzzle (they fold and unfold).
        DetectiveTipNotes(hints: hints, revealed: revealed),
        // The same secondary button and words as the try-again sheet.
        if (canReveal)
          GameButton(
            label: nextTipLabel(hints, revealed)!.toUpperCase(),
            glyph: InkGlyph.hint,
            style: GameButtonStyle.outline,
            onPressed: onReveal,
          ),
        if (canReveal)
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.xs),
            child: Text(
              revealed == 0 ? 'Good detectives use hints.' : 'Hint ${revealed + 1} of ${hints.length}',
              textAlign: TextAlign.center,
              style: AppText.caption(color: dark ? AppColors.paperLight.withValues(alpha: 0.8) : AppColors.muted),
            ),
          ),
      ],
    );
  }
}
