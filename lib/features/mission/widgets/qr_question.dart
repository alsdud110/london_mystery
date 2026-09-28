import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/models/mission.dart';
import '../../../widgets/game_button.dart';
import '../../../widgets/ink_icon.dart';
import '../../../widgets/paper.dart';
import 'question_widgets.dart';

/// TYPE 5 — Scan a real QR code placed in the play space.
///
/// A typed fallback exists for when a camera is unavailable; the code is
/// printed under each QR card (see the Game Master screen).
class QrQuestion extends StatefulWidget {
  const QrQuestion({super.key, required this.mission, required this.onSubmit});

  final Mission mission;
  final AnswerCallback onSubmit;

  @override
  State<QrQuestion> createState() => _QrQuestionState();
}

class _QrQuestionState extends State<QrQuestion> {
  final _manual = TextEditingController();
  bool _showManual = false;

  @override
  void initState() {
    super.initState();
    _manual.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _manual.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final value = await context.push<String>(Routes.qrScanner);
    if (!mounted || value == null) return;
    widget.onSubmit(value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PaperSheet(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Row(
            children: [
              const InkIcon(InkGlyph.qr, size: 52, color: AppColors.navy),
              const SizedBox(width: AppSpace.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SECRET CODE', style: AppText.eyebrow()),
                    const SizedBox(height: AppSpace.xs),
                    Text('Look for the golden crown sticker!', style: AppText.subtitle()),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        GameButton(label: 'SCAN QR CODE', onPressed: _scan),
        const SizedBox(height: AppSpace.sm),
        Center(
          child: InkTextButton(
            label: "Can't scan? Type the code",
            glyph: InkGlyph.pen,
            onPressed: () => setState(() => _showManual = !_showManual),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          child: !_showManual
              ? const SizedBox(width: double.infinity)
              : Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _manual,
                        textAlign: TextAlign.center,
                        textCapitalization: TextCapitalization.characters,
                        autocorrect: false,
                        maxLength: 24,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9\-]')),
                          LengthLimitingTextInputFormatter(24),
                        ],
                        style: AppText.title(size: 22, color: AppColors.navy).copyWith(letterSpacing: 2),
                        decoration: InputDecoration(
                          hintText: 'CODE UNDER THE QR',
                          hintStyle: AppText.bodyText(size: 16, color: AppColors.muted),
                          counterText: '',
                        ),
                        onSubmitted: (v) => v.trim().isEmpty ? null : widget.onSubmit(v),
                      ),
                      const SizedBox(height: 12),
                      GameButton(
                        label: 'CHECK CODE',
                        style: GameButtonStyle.outline,
                        onPressed: _manual.text.trim().isEmpty ? null : () => widget.onSubmit(_manual.text),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}
