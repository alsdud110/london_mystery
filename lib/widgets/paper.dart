import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../core/theme/app_tokens.dart';

/// A sheet of paper lying on the desk: the base surface for documents,
/// letters, notes and scene pictures (instead of rounded app cards).
class PaperSheet extends StatelessWidget {
  const PaperSheet({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.xl),
    this.tilt = 0,
    this.color = AppColors.paperLight,
    this.lifted = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Small rotation in radians, for a hand-placed look (keep under 0.03).
  final double tilt;
  final Color color;
  final bool lifted;

  @override
  Widget build(BuildContext context) {
    final sheet = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.paper),
        border: Border.all(color: AppLine.faint(), width: AppLine.hairline),
        boxShadow: lifted ? AppShadow.paperLift : null,
      ),
      child: child,
    );
    return tilt == 0 ? sheet : Transform.rotate(angle: tilt, child: sheet);
  }
}

/// A manila case folder: a labelled tab on top of a paper body.
class CaseFolder extends StatelessWidget {
  const CaseFolder({super.key, required this.tab, required this.child});

  final String tab;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final edge = BorderSide(color: AppLine.faint(0.3), width: AppLine.hairline);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(left: AppSpace.md),
          padding: const EdgeInsets.fromLTRB(AppSpace.md, 5, AppSpace.md, 3),
          decoration: BoxDecoration(
            color: AppColors.parchment,
            border: Border(top: edge, left: edge, right: edge),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.paper)),
          ),
          child: Text(tab, style: AppText.eyebrow(color: AppColors.inkBrown)),
        ),
        PaperSheet(color: AppColors.parchment, padding: EdgeInsets.zero, child: child),
      ],
    );
  }
}

/// A rubber-stamp mark ("SOLVED", "UNLOCKED"). Status colours belong here —
/// on a stamp, never as a filled card.
class InkStamp extends StatelessWidget {
  const InkStamp(this.text, {super.key, this.color = AppColors.burgundy, this.size = 16, this.tilt = -0.12});

  final String text;
  final Color color;
  final double size;
  final double tilt;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: tilt,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: size * 0.6, vertical: size * 0.25),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.paper),
          border: Border.all(color: color.withValues(alpha: 0.85), width: size / 8),
        ),
        child: Text(
          text,
          style: AppText.style(AppText.display, size: size, weight: FontWeight.w800, color: color.withValues(alpha: 0.9), letterSpacing: 2),
        ),
      ),
    );
  }
}
