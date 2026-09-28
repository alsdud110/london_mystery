import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../data/models/mission.dart';
import '../../../widgets/game_button.dart';
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
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.gold, width: 3),
                ),
                child: const Icon(Icons.qr_code_2_rounded, size: 56, color: AppColors.navy),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SECRET CODE', style: AppText.eyebrow(color: AppColors.goldLight)),
                    const SizedBox(height: 4),
                    Text('Look for the golden crown sticker!',
                        style: AppText.subtitle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        GameButton(
          label: 'SCAN QR CODE',
          icon: Icons.qr_code_scanner_rounded,
          style: GameButtonStyle.gold,
          onPressed: _scan,
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: () => setState(() => _showManual = !_showManual),
          icon: Icon(_showManual ? Icons.expand_less_rounded : Icons.keyboard_rounded, color: AppColors.royalBlue),
          label: Text("Can't scan? Type the code", style: AppText.button(size: 15, color: AppColors.royalBlue)),
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
                        icon: Icons.check_circle_rounded,
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
