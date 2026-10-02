import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../core/theme/app_tokens.dart';
import 'game_button.dart';
import 'paper.dart';

/// The game's own dialog: a ruled paper document laid over the page,
/// instead of a Material alert.
///
/// [GameDialog.plain] is the grown-ups' version (parent gate, operator
/// tools): the same paper, no ornament, compact themed actions, so it reads
/// as a tool and works outside the game's provider scope.
class GameDialog extends StatelessWidget {
  const GameDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
    this.plain = false,
    this.scrollable = false,
  });

  /// A child-facing yes/no question. Primary action on top, full width;
  /// "keep going" below as a quiet ink link. Returns true for [confirmLabel].
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required String cancelLabel,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => GameDialog(
        title: title,
        content: Text(message, textAlign: TextAlign.center, style: AppText.bodyText(size: 16)),
        actions: [
          GameButton(label: confirmLabel, onPressed: () => Navigator.of(context).pop(true)),
          const SizedBox(height: AppSpace.xs),
          InkTextButton(label: cancelLabel, color: AppColors.inkBrown, onPressed: () => Navigator.of(context).pop(false)),
        ],
      ),
    );
    return ok ?? false;
  }

  /// A grown-ups' confirmation. [destructive] paints the action in the
  /// try-again ink so a reset never looks like an ordinary button.
  static Future<bool> confirmPlain(
    BuildContext context, {
    required String title,
    required String message,
    required String confirmLabel,
    required String cancelLabel,
    bool destructive = false,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => GameDialog(
        plain: true,
        title: title,
        content: Text(message, style: AppText.bodyText(size: 16)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(cancelLabel)),
          FilledButton(
            style: destructive ? FilledButton.styleFrom(backgroundColor: AppColors.tryAgain) : null,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  final String title;
  final Widget content;
  final List<Widget> actions;
  final bool plain;

  /// Scroll inside the paper (e.g. a field above the keyboard on a small phone).
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: plain ? CrossAxisAlignment.start : CrossAxisAlignment.stretch,
      children: [
        Text(title, textAlign: plain ? TextAlign.start : TextAlign.center, style: AppText.title(size: 22)),
        if (!plain) ...[
          const SizedBox(height: AppSpace.sm),
          const Center(child: OrnamentRule(width: 96)),
        ],
        const SizedBox(height: AppSpace.lg),
        content,
        const SizedBox(height: AppSpace.xl),
        if (plain)
          Wrap(alignment: WrapAlignment.end, spacing: AppSpace.sm, runSpacing: AppSpace.sm, children: actions)
        else
          ...actions,
      ],
    );
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpace.xl, vertical: AppSpace.xl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: PaperSheet(
          ruled: !plain,
          padding: const EdgeInsets.fromLTRB(AppSpace.xl, AppSpace.xl, AppSpace.xl, AppSpace.lg),
          child: scrollable ? SingleChildScrollView(child: body) : body,
        ),
      ),
    );
  }
}
