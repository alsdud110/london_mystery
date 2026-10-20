import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../core/theme/app_tokens.dart';
import 'ink_icon.dart';
import 'paper.dart';

/// A train ticket on paper, from [from] to [to], in the [passenger]'s name:
/// the ticket of Season 2's opening (THE JOURNEY), and the same ticket held
/// out on the report of the last case of the season before it. [stamp]
/// ("COMING SOON") is pressed across its corner while the journey cannot be
/// made yet. Laid flat: the page tilts and moves it.
class TrainTicket extends StatelessWidget {
  const TrainTicket({super.key, required this.from, required this.to, this.passenger, this.stamp, this.width = 300});

  final String from;
  final String to;
  final String? passenger;
  final String? stamp;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: PaperSheet(
        ruled: true,
        padding: const EdgeInsets.fromLTRB(AppSpace.xl, AppSpace.lg, AppSpace.xl, AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Smaller rather than cut, as the route below.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const InkIcon(InkGlyph.train, size: AppIconSize.medium, color: AppColors.burgundy),
                  const SizedBox(width: AppSpace.sm),
                  Text('TRAIN TICKET', style: AppText.mark(color: AppColors.burgundy)),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.md),
            // The route, on one line: smaller rather than cut with larger text.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(from, style: AppText.logo(size: 24, color: AppColors.navy)),
                  const SizedBox(width: AppSpace.sm),
                  Container(width: 40, height: AppLine.rule, color: AppColors.inkBrown.withValues(alpha: 0.5)),
                  const SizedBox(width: AppSpace.sm),
                  Text(to, style: AppText.logo(size: 24, color: AppColors.navy)),
                ],
              ),
            ),
            if (passenger != null) ...[
              const SizedBox(height: AppSpace.md),
              Text('PASSENGER', style: AppText.eyebrow(color: AppColors.inkBrown)),
              Text(passenger!, style: AppText.title(size: 18, color: AppColors.navy)),
            ],
            // Pressed in the ticket's lower corner, on a line of its own:
            // never over the route or a long name.
            if (stamp != null) ...[
              const SizedBox(height: AppSpace.sm),
              Align(alignment: Alignment.centerRight, child: InkStamp(stamp!, size: 13, tilt: -0.1)),
            ],
          ],
        ),
      ),
    );
  }
}
