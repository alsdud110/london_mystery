import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../core/theme/app_tokens.dart';
import '../core/utils/audio_service.dart';
import '../features/game/game_providers.dart';
import 'ink_icon.dart';
import 'paper_background.dart';

/// [navy] is the primary action on paper, [gold] the primary action on the
/// dark night screens, [outline] a secondary action. One primary per screen.
/// - [navy]: primary on paper. [gold]: primary on the night page.
/// - [outline]: secondary (paper ink, or gold ink on the night page).
/// - [glass]: primary over a full-screen painting (the season cover): dark
///   translucent navy with a thin gold edge, so the picture stays first.
enum GameButtonStyle { navy, gold, outline, glass }

/// Large, flat, kid-friendly button ("INVESTIGATE →").
class GameButton extends ConsumerStatefulWidget {
  const GameButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.semanticLabel,
    this.style = GameButtonStyle.navy,
    this.glyph,
    this.arrow = false,
    this.singleLine = false,
    this.expand = true,
    this.playTapSound = true,
  });

  final String label;
  final VoidCallback? onPressed;

  /// What a screen reader says when the short [label] needs its context
  /// ("GO" on the map is "GO TO KING'S CROSS"). Defaults to [label].
  final String? semanticLabel;
  final GameButtonStyle style;
  final InkGlyph? glyph;

  /// Shows a trailing ink arrow: the button moves the story forward.
  final bool arrow;

  /// Fixed size whatever the label: one line, fixed height, the arrow always
  /// in the same place. Long labels shrink slightly to fit instead of
  /// wrapping (e.g. "GO TO BUCKINGHAM PALACE").
  final bool singleLine;
  final bool expand;
  final bool playTapSound;

  @override
  ConsumerState<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends ConsumerState<GameButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null;

  void _setPressed(bool value) {
    if (_enabled && _pressed != value) setState(() => _pressed = value);
  }

  /// Labels are actions: set in the reading face (Sentient), never in the
  /// display face that names the world.
  TextStyle _label(Color color) =>
      AppText.style(AppText.body, size: 16.5, weight: FontWeight.w600, color: color, letterSpacing: 1.6, height: 1.2);

  @override
  Widget build(BuildContext context) {
    // Fill, ink, outer edge, the printed inner rule, and the pressed-in
    // edge underneath (null: flat, it does not stand off the page).
    var (bg, fg, border, rule, depth) = switch (widget.style) {
      GameButtonStyle.navy => (
          AppColors.navy,
          AppColors.paperLight,
          AppColors.navyDeep,
          AppColors.goldLight.withValues(alpha: 0.35),
          AppColors.navyDeep as Color?,
        ),
      GameButtonStyle.gold => (
          AppColors.goldLight,
          AppColors.navyDeep,
          AppColors.goldDeep,
          AppColors.navyDeep.withValues(alpha: 0.28),
          AppColors.goldDeep as Color?,
        ),
      GameButtonStyle.glass => (
          AppColors.navyDeep.withValues(alpha: 0.48),
          // A touch brighter than the painting's lights, so it reads as a
          // button at first glance (no glow, no extra shadow).
          Color.lerp(AppColors.goldLight, AppColors.paperLight, 0.2)!,
          AppColors.goldLight.withValues(alpha: 0.92),
          AppColors.goldLight.withValues(alpha: 0.32),
          null,
        ),
      // Ink on paper; gold ink on the navy night background, where dark
      // ink would disappear (e.g. "OPEN MY NOTEBOOK" in the final case).
      GameButtonStyle.outline =>
        InkSurface.isNight(context)
            ? (
                Colors.transparent,
                AppColors.goldLight,
                AppColors.goldLight.withValues(alpha: 0.7),
                AppColors.goldLight.withValues(alpha: 0.3),
                null,
              )
            : (
                AppColors.paperLight.withValues(alpha: 0.55),
                AppColors.ink,
                AppLine.faint(0.45),
                AppLine.faint(0.22),
                null,
              ),
    };
    // Not ready yet (e.g. no answer chosen): a faint pencilled outline
    // instead of a grey block, so it does not draw the eye.
    if (!_enabled && widget.style == GameButtonStyle.navy) {
      (bg, fg, border, rule, depth) = (Colors.transparent, AppColors.navy, AppLine.faint(0.35), AppLine.faint(0.15), null);
    }
    const depthPx = 3.0;
    final raised = depth != null;

    const arrowBox = AppIconSize.medium + AppSpace.md;
    final content = widget.singleLine
        ? Row(
            children: [
              // Balances the arrow so the label stays centred.
              if (widget.arrow && widget.glyph == null) const SizedBox(width: arrowBox),
              if (widget.glyph != null) ...[
                InkIcon(widget.glyph!, size: AppIconSize.medium, color: fg),
                const SizedBox(width: AppSpace.md),
              ],
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(widget.label, maxLines: 1, style: _label(fg).copyWith(letterSpacing: 1.2)),
                ),
              ),
              if (widget.arrow) ...[
                const SizedBox(width: AppSpace.md),
                InkIcon(InkGlyph.arrow, size: AppIconSize.medium, color: fg),
              ],
            ],
          )
        : Row(
            mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.glyph != null) ...[
                InkIcon(widget.glyph!, size: AppIconSize.medium, color: fg),
                const SizedBox(width: AppSpace.md),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: _label(fg),
                ),
              ),
              if (widget.arrow) ...[
                const SizedBox(width: AppSpace.md),
                InkIcon(InkGlyph.arrow, size: AppIconSize.medium, color: fg),
              ],
            ],
          );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel ?? widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        onTap: _enabled
            ? () {
                if (widget.playTapSound) ref.read(audioServiceProvider).play(GameSound.tap);
                widget.onPressed!();
              }
            : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: !_enabled ? 0.5 : 1,
          // A raised button stands on a darker edge and presses down into
          // it; the box keeps the same size, so nothing around it moves.
          child: Container(
            constraints: widget.singleLine
                ? const BoxConstraints.tightFor(height: 56)
                : const BoxConstraints(minHeight: 56),
            decoration: raised
                ? BoxDecoration(
                    color: depth,
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    boxShadow: _pressed ? null : const [BoxShadow(color: Color(0x332A2622), blurRadius: 8, offset: Offset(0, 4))],
                  )
                : null,
            child: AnimatedPadding(
              duration: const Duration(milliseconds: 70),
              padding: EdgeInsets.only(
                top: raised && _pressed ? depthPx : 0,
                bottom: raised && !_pressed ? depthPx : 0,
              ),
              child: Container(
                constraints: widget.singleLine ? const BoxConstraints.expand() : const BoxConstraints(minHeight: 56 - depthPx),
                padding: EdgeInsets.symmetric(
                  horizontal: widget.singleLine ? AppSpace.lg : AppSpace.xl,
                  vertical: widget.singleLine ? 0 : AppSpace.md + 2,
                ),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  border: Border.all(color: border, width: AppLine.hairline),
                ),
                // The printed inner rule: an engraved ticket, not a web button.
                foregroundDecoration: _InnerRule(rule),
                child: content,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A quiet ink text action with an optional glyph ("Letter", "Get a tip").
class InkTextButton extends StatelessWidget {
  const InkTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.glyph,
    this.color = AppColors.royalBlue,
  });

  final String label;
  final VoidCallback? onPressed;
  final InkGlyph? glyph;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Disabled (e.g. Undo with nothing to undo): the ink greys out, so it
    // does not look like it can be tapped.
    final ink = onPressed == null ? AppColors.locked : color;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: color,
        disabledForegroundColor: AppColors.locked,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (glyph != null) ...[
            InkIcon(glyph!, size: AppIconSize.small, color: ink),
            const SizedBox(width: AppSpace.sm),
          ],
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppText.button(size: 15, color: ink).copyWith(letterSpacing: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}

/// The hairline printed just inside a [GameButton]'s edge.
class _InnerRule extends Decoration {
  const _InnerRule(this.color);

  final Color color;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _InnerRulePainter(color);
}

class _InnerRulePainter extends BoxPainter {
  _InnerRulePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final r = RRect.fromRectAndRadius((offset & configuration.size!).deflate(4), const Radius.circular(AppRadius.button - 3));
    canvas.drawRRect(
      r,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppLine.hairline,
    );
  }
}
