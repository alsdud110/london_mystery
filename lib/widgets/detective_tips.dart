import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../core/theme/app_tokens.dart';
import 'paper.dart';

/// Detective tips that were opened, as small handwritten notes.
/// (The "Get a tip" link that opens them sits with the puzzle's actions.)
class DetectiveTipNotes extends StatelessWidget {
  const DetectiveTipNotes({super.key, required this.hints, required this.revealed});

  final List<String> hints;
  final int revealed;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < revealed && i < hints.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.md),
            child: TweenAnimationBuilder<double>(
              key: ValueKey('tip-$i'),
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              builder: (context, t, child) => Opacity(opacity: t, child: child),
              child: PaperSheet(
                tilt: i.isEven ? -0.008 : 0.008,
                padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DETECTIVE TIP ${i + 1}', style: AppText.eyebrow()),
                    const SizedBox(height: AppSpace.xs),
                    Text(hints[i], style: AppText.letter(size: 17)),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// One name for asking for a tip, wherever it is offered: the quiet link
/// under a puzzle ([nextTipLabel]) and the buttons of the try-again sheet
/// and the final case ([tipButtonLabel]). Only the letter case follows the
/// component (link vs. engraved button).
const tipButtonLabel = 'GET A TIP';

/// Label for the link that opens the next tip, or null when none are left.
String? nextTipLabel(List<String> hints, int revealed) => revealed >= hints.length ? null : 'Get a tip';

/// Colour of the tip link (gold ink, so it reads as a helper, not an answer).
const tipLinkColor = AppColors.goldDeep;
