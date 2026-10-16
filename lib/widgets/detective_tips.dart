import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../core/theme/app_tokens.dart';
import 'glossary_text.dart';
import 'ink_icon.dart';
import 'paper.dart';

/// Detective hints that were opened, as small notes on the puzzle itself
/// (never a sheet over it): a bulb, DETECTIVE HINT n and the hint, in the
/// order they were opened. Each folds to its label and opens again with a
/// tap on it. A hint opened while this is on screen unfolds in (about a
/// quarter second, none with Reduce Motion) and is scrolled into view;
/// hints already open when the page is built are simply there.
/// (The "Get More Hints" link that opens them sits with the puzzle's actions.)
class DetectiveTipNotes extends StatefulWidget {
  const DetectiveTipNotes({
    super.key,
    required this.hints,
    required this.revealed,
    this.compact = false,
  });

  final List<String> hints;
  final int revealed;

  /// In a panel under a picture or a talk: a flat note, smaller ink.
  final bool compact;

  @override
  State<DetectiveTipNotes> createState() => _DetectiveTipNotesState();
}

class _DetectiveTipNotesState extends State<DetectiveTipNotes> {
  /// Hints opened before this was built: shown at once, no unfolding.
  late final int _shownAtStart = widget.revealed;

  /// Hints folded to their label (by index).
  final _folded = <int>{};

  @override
  Widget build(BuildContext context) {
    final count = widget.revealed.clamp(0, widget.hints.length);
    final gap = widget.compact ? AppSpace.sm : AppSpace.md;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < count; i++)
          Padding(
            key: ValueKey('tip-$i'),
            padding: EdgeInsets.only(bottom: gap),
            child: _HintNote(
              number: i + 1,
              text: widget.hints[i],
              compact: widget.compact,
              fresh: i >= _shownAtStart,
              folded: _folded.contains(i),
              onToggle: () => setState(
                () => _folded.contains(i) ? _folded.remove(i) : _folded.add(i),
              ),
            ),
          ),
      ],
    );
  }
}

class _HintNote extends StatefulWidget {
  const _HintNote({
    required this.number,
    required this.text,
    required this.compact,
    required this.fresh,
    required this.folded,
    required this.onToggle,
  });

  final int number;
  final String text;
  final bool compact;

  /// Opened just now: unfolds in and is scrolled into view.
  final bool fresh;
  final bool folded;
  final VoidCallback onToggle;

  @override
  State<_HintNote> createState() => _HintNoteState();
}

class _HintNoteState extends State<_HintNote>
    with SingleTickerProviderStateMixin {
  static const _reveal = Duration(milliseconds: 260);

  late final _in = AnimationController(
    vsync: this,
    duration: _reveal,
    value: widget.fresh ? 0 : 1,
  );
  late final _curve = CurvedAnimation(parent: _in, curve: Curves.easeOutCubic);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!widget.fresh || _in.value == 1 || _in.isAnimating) return;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _in.value = 1;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _bringIntoView(Duration.zero),
      );
    } else {
      _in.forward();
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _bringIntoView(_reveal),
      );
    }
  }

  /// The new hint in sight in whatever scrolls it (the page or the panel).
  void _bringIntoView(Duration duration) {
    if (!mounted || Scrollable.maybeOf(context) == null) return;
    Scrollable.ensureVisible(
      context,
      duration: duration,
      curve: Curves.easeOutCubic,
      alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
    );
  }

  @override
  void dispose() {
    _curve.dispose();
    _in.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final compact = widget.compact;
    final open = !widget.folded;
    final label = 'DETECTIVE HINT ${widget.number}';
    final header = Semantics(
      button: true,
      expanded: open,
      label: label,
      hint: open ? 'Fold this hint' : 'Open this hint',
      excludeSemantics: true,
      child: InkWell(
        onTap: widget.onToggle,
        borderRadius: BorderRadius.circular(AppRadius.paper),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Row(
            children: [
              HintBulb(key: ValueKey('hint-bulb-${widget.number}'), lit: open),
              const SizedBox(width: AppSpace.sm),
              Expanded(child: Text(label, style: AppText.eyebrow())),
              AnimatedRotation(
                turns: open ? 0.5 : 0,
                duration:
                    (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
                    ? Duration.zero
                    : const Duration(milliseconds: 200),
                child: const InkIcon(
                  InkGlyph.chevron,
                  size: AppIconSize.small,
                  color: AppColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final body = Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.xs),
      child: GlossaryText(
        widget.text,
        style: AppText.letter(size: compact ? 16 : 17, color: AppColors.navy),
      ),
    );
    final shown = open ? body : const SizedBox(width: double.infinity);
    final note = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        // Reduce Motion: folds at once (an AnimatedSize with no duration
        // would relayout itself mid-layout).
        if (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
          shown
        else
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: shown,
          ),
      ],
    );
    final padding = compact
        ? const EdgeInsets.fromLTRB(AppSpace.md, 0, AppSpace.md, AppSpace.sm)
        : const EdgeInsets.fromLTRB(
            AppSpace.lg,
            AppSpace.xs,
            AppSpace.lg,
            AppSpace.md,
          );
    // On a panel (already paper) a flat note with a fine rule; on the page a
    // small sheet laid on it.
    final card = compact
        ? DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.paper,
              borderRadius: BorderRadius.circular(AppRadius.paper),
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.45),
                width: AppLine.hairline,
              ),
            ),
            child: Padding(padding: padding, child: note),
          )
        : PaperSheet(padding: padding, child: note);
    return SizeTransition(
      sizeFactor: _curve,
      alignment: Alignment.topCenter,
      child: FadeTransition(opacity: _curve, child: card),
    );
  }
}

/// The bulb of a hint note: the gold ink outline, lit while the hint is
/// open (pale gold inside, a faint warm glow around it) and dark while it
/// is folded. It lights and goes out in about a fifth of a second (at once
/// with Reduce Motion); it never flickers. Same size as the plain glyph.
class HintBulb extends StatelessWidget {
  const HintBulb({super.key, required this.lit, this.size = AppIconSize.small});

  final bool lit;
  final double size;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: lit ? 1 : 0),
      duration: still ? Duration.zero : const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      builder: (context, level, outline) =>
          CustomPaint(painter: HintBulbLight(level), child: outline),
      child: InkIcon(InkGlyph.hint, size: size, color: AppColors.goldDeep),
    );
  }
}

/// The light under a [HintBulb]'s outline: [level] 0 (dark) to 1 (lit).
/// Drawn on the hint glyph's 24-unit grid: the glass (its round top and
/// the neck to the base) filled, and a soft glow around the round.
class HintBulbLight extends CustomPainter {
  const HintBulbLight(this.level);

  final double level;

  @override
  void paint(Canvas canvas, Size size) {
    if (level <= 0) return;
    canvas.save();
    canvas.scale(size.width / 24, size.height / 24);
    // The glow: faint, just past the glass.
    canvas.drawCircle(
      const Offset(12, 11),
      7.5,
      Paint()
        ..color = AppColors.gold.withValues(alpha: 0.6 * level)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.5),
    );
    // The glass, inside the outline.
    final glass = Path()
      ..addOval(Rect.fromCircle(center: const Offset(12, 10), radius: 5.6))
      ..addPolygon(const [
        Offset(8.3, 13.6),
        Offset(15.7, 13.6),
        Offset(14.3, 16.6),
        Offset(9.7, 16.6),
      ], true);
    canvas.drawPath(
      glass,
      Paint()..color = AppColors.goldLight.withValues(alpha: 2 * level),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(HintBulbLight old) => old.level != level;
}

/// One name for asking for a hint, wherever it is offered: the quiet link
/// under a puzzle ([nextTipLabel]) and the buttons of the try-again sheet
/// and the final case ([tipButtonLabel]). Only the letter case follows the
/// component (link vs. engraved button).
const tipButtonLabel = 'GET MORE HINTS';

/// Label for the link that opens the next hint ("Get a Free Hint" while the
/// next one costs nothing, then "Get More Hints"), or null when none are left.
String? nextTipLabel(List<String> hints, int revealed) {
  if (revealed >= hints.length) return null;
  final free =
      revealed < AppConstants.tipPrices.length &&
      AppConstants.tipPrices[revealed] == 0;
  return free ? 'Get a Free Hint' : 'Get More Hints';
}

/// Colour of the tip link (gold ink, so it reads as a helper, not an answer).
const tipLinkColor = AppColors.goldDeep;
