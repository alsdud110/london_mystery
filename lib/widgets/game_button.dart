import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../core/theme/app_tokens.dart';
import '../core/utils/audio_service.dart';
import '../features/game/game_providers.dart';
import 'ink_icon.dart';

/// [navy] is the primary action on paper, [gold] the primary action on the
/// dark night screens, [outline] a secondary action. One primary per screen.
enum GameButtonStyle { navy, gold, outline }

/// Large, flat, kid-friendly button ("INVESTIGATE →").
class GameButton extends ConsumerStatefulWidget {
  const GameButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = GameButtonStyle.navy,
    this.icon,
    this.arrow = false,
    this.singleLine = false,
    this.expand = true,
    this.playTapSound = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final GameButtonStyle style;
  final IconData? icon;

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

  @override
  Widget build(BuildContext context) {
    var (bg, fg, border) = switch (widget.style) {
      GameButtonStyle.navy => (AppColors.navy, AppColors.paperLight, AppColors.navy),
      GameButtonStyle.gold => (AppColors.goldLight, AppColors.navyDeep, AppColors.goldLight),
      GameButtonStyle.outline => (Colors.transparent, AppColors.ink, AppLine.faint(0.45)),
    };
    // Not ready yet (e.g. no answer chosen): a faint pencilled outline
    // instead of a grey block, so it does not draw the eye.
    if (!_enabled && widget.style == GameButtonStyle.navy) {
      (bg, fg, border) = (Colors.transparent, AppColors.navy, AppLine.faint(0.35));
    }

    const arrowBox = 22.0 + AppSpace.md;
    final content = widget.singleLine
        ? Row(
            children: [
              // Balances the arrow so the label stays centred.
              if (widget.arrow) const SizedBox(width: arrowBox),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(widget.label, maxLines: 1, style: AppText.button(color: fg).copyWith(letterSpacing: 0.8)),
                ),
              ),
              if (widget.arrow) ...[
                const SizedBox(width: AppSpace.md),
                InkIcon(InkGlyph.arrow, size: 22, color: fg),
              ],
            ],
          )
        : Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, color: fg, size: 22),
          const SizedBox(width: AppSpace.md),
        ],
        Flexible(
          child: Text(widget.label, textAlign: TextAlign.center, style: AppText.button(color: fg)),
        ),
        if (widget.arrow) ...[
          const SizedBox(width: AppSpace.md),
          InkIcon(InkGlyph.arrow, size: 22, color: fg),
        ],
      ],
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.label,
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
          opacity: !_enabled ? 0.5 : (_pressed ? 0.82 : 1),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 90),
            scale: _pressed ? 0.98 : 1,
            child: Container(
              constraints: widget.singleLine ? const BoxConstraints.tightFor(height: 56) : const BoxConstraints(minHeight: 56),
              padding: EdgeInsets.symmetric(
                horizontal: widget.singleLine ? AppSpace.lg : AppSpace.xl,
                vertical: widget.singleLine ? 0 : AppSpace.lg,
              ),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(AppRadius.button),
                border: Border.all(color: border, width: AppLine.rule),
              ),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

/// A quiet ink text action with an optional glyph ("✎ Letter", "Need a tip?").
class InkTextButton extends StatelessWidget {
  const InkTextButton({super.key, required this.label, required this.onPressed, this.glyph, this.color = AppColors.royalBlue});

  final String label;
  final VoidCallback? onPressed;
  final InkGlyph? glyph;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (glyph != null) ...[
            InkIcon(glyph!, size: 20, color: color),
            const SizedBox(width: AppSpace.sm),
          ],
          Flexible(
            child: Text(label, textAlign: TextAlign.center, style: AppText.button(size: 15, color: color).copyWith(letterSpacing: 0.3)),
          ),
        ],
      ),
    );
  }
}
