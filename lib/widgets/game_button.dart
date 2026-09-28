import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../core/utils/audio_service.dart';
import '../features/game/game_providers.dart';

enum GameButtonStyle { navy, gold, outline }

/// Large, kid-friendly button with a tactile press animation.
class GameButton extends ConsumerStatefulWidget {
  const GameButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.style = GameButtonStyle.navy,
    this.icon,
    this.expand = true,
    this.playTapSound = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final GameButtonStyle style;
  final IconData? icon;
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
    final (bg, fg, border) = switch (widget.style) {
      GameButtonStyle.navy => (AppColors.navy, Colors.white, AppColors.gold),
      GameButtonStyle.gold => (AppColors.gold, AppColors.navy, AppColors.goldDeep),
      GameButtonStyle.outline => (Colors.white, AppColors.navy, AppColors.navy),
    };
    final shadowColor = widget.style == GameButtonStyle.outline ? AppColors.parchmentDark : AppColors.navyDeep;

    final content = Row(
      mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, color: fg, size: 24),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: AppText.button(color: fg),
          ),
        ),
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
          opacity: _enabled ? 1 : 0.45,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 90),
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            transform: Matrix4.translationValues(0, _pressed ? 4 : 0, 0),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: border, width: 2.5),
              boxShadow: [
                BoxShadow(color: shadowColor, offset: Offset(0, _pressed ? 1 : 5), blurRadius: 0),
              ],
            ),
            child: content,
          ),
        ),
      ),
    );
  }
}
