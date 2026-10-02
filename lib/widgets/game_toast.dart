import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../core/theme/app_tokens.dart';
import 'ink_icon.dart';

OverlayEntry? _current;

/// A short message at the top of the screen that never blocks taps
/// (unlike a SnackBar, which would cover the big bottom buttons).
void showGameToast(BuildContext context, String message, {InkGlyph glyph = InkGlyph.lock}) {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;
  _current?.remove();
  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (context) => _Toast(
      message: message,
      glyph: glyph,
      onDone: () {
        if (_current == entry) _current = null;
        if (entry.mounted) entry.remove();
      },
    ),
  );
  _current = entry;
  overlay.insert(entry);
}

class _Toast extends StatefulWidget {
  const _Toast({required this.message, required this.glyph, required this.onDone});

  final String message;
  final InkGlyph glyph;
  final VoidCallback onDone;

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    await _c.forward();
    await Future<void>.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;
    await _c.reverse();
    if (mounted) widget.onDone();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 16,
      right: 16,
      top: MediaQuery.paddingOf(context).top + 12,
      child: IgnorePointer(
        child: FadeTransition(
          opacity: _c,
          child: SlideTransition(
            position: Tween(begin: const Offset(0, -0.4), end: Offset.zero).animate(_c),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Material(
                  color: AppColors.navy,
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    side: BorderSide(color: AppColors.goldLight.withValues(alpha: 0.4), width: AppLine.hairline),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                    child: Row(
                      children: [
                        InkIcon(widget.glyph, color: AppColors.goldLight),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(widget.message, style: AppText.bodyText(size: 16, color: AppColors.paperLight)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
