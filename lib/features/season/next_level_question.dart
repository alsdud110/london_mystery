import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/models/difficulty.dart';
import '../../widgets/game_button.dart';
import '../../widgets/game_dialog.dart';
import '../../widgets/game_toast.dart';
import '../../widgets/ink_icon.dart';
import '../game/game_controller.dart';
import '../game/game_providers.dart';
import '../onboarding/detective_form.dart';

/// READY FOR YOUR NEXT MYSTERY? Under a complete season's last report,
/// before the next season begins: the detective keeps their level or
/// chooses a new one for it. Asked once (see [nextLevelQuestionProvider]);
/// the way on (GO TO PARIS) stays the one strong action, so both answers
/// are quiet ink links. Shows nothing when there is nothing to ask (the
/// question answered, the next season begun, or no season after this one).
class NextLevelQuestion extends ConsumerWidget {
  const NextLevelQuestion({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = ref.watch(nextLevelQuestionProvider);
    if (next == null) return const SizedBox.shrink();
    final city = next.season.city;
    final level = ref.watch(detectiveProfileProvider.select((p) => p.difficulty));
    final quiet = AppColors.paperLight.withValues(alpha: 0.85);
    return Padding(
      key: const ValueKey('next-level-question'),
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: Column(
        children: [
          Text(
            'READY FOR YOUR NEXT MYSTERY?',
            textAlign: TextAlign.center,
            style: AppText.eyebrow(color: AppColors.goldLight).copyWith(letterSpacing: 1.5),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            'You can keep your level or choose a new one for $city.',
            textAlign: TextAlign.center,
            style: AppText.caption(color: quiet),
          ),
          const SizedBox(height: AppSpace.xs),
          Text(
            'Your level: ${level.label}',
            key: const ValueKey('next-level-current'),
            textAlign: TextAlign.center,
            style: AppText.caption(color: AppColors.goldLight),
          ),
          Row(
            children: [
              Expanded(
                child: InkTextButton(
                  label: 'KEEP MY LEVEL',
                  color: quiet,
                  onPressed: () => ref.read(gameControllerProvider.notifier).answerNextLevel(null),
                ),
              ),
              Expanded(
                child: InkTextButton(
                  label: 'CHANGE LEVEL',
                  color: AppColors.goldLight,
                  onPressed: () async {
                    final chosen = await ChooseLevelDialog.ask(context, current: level, city: city);
                    if (chosen == null) return;
                    await ref.read(gameControllerProvider.notifier).answerNextLevel(chosen);
                    if (context.mounted) {
                      showGameToast(context, '$city starts as ${chosen.label}.', glyph: InkGlyph.check);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The level for the next season, chosen on a paper laid over the page: the
/// same three cards as CHOOSE YOUR LEVEL. Returns the level chosen, or null
/// when the paper was put away.
class ChooseLevelDialog extends StatefulWidget {
  const ChooseLevelDialog._({required this.current, required this.city});

  final Difficulty current;
  final String city;

  static Future<Difficulty?> ask(BuildContext context, {required Difficulty current, required String city}) =>
      showDialog<Difficulty>(
        context: context,
        builder: (_) => ChooseLevelDialog._(current: current, city: city),
      );

  @override
  State<ChooseLevelDialog> createState() => _ChooseLevelDialogState();
}

class _ChooseLevelDialogState extends State<ChooseLevelDialog> {
  late Difficulty _level = widget.current;

  @override
  Widget build(BuildContext context) {
    return GameDialog(
      key: const ValueKey('choose-level-dialog'),
      title: 'Choose your level',
      scrollable: true,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'For ${widget.city}. Your solved cases stay as they are.',
            textAlign: TextAlign.center,
            style: AppText.bodyText(size: 15),
          ),
          const SizedBox(height: AppSpace.md),
          DifficultyChoice(selected: _level, onChanged: (d) => setState(() => _level = d)),
        ],
      ),
      actions: [
        GameButton(label: 'CHOOSE ${_level.label}', onPressed: () => Navigator.of(context).pop(_level)),
        const SizedBox(height: AppSpace.xs),
        InkTextButton(label: 'Not now', color: AppColors.inkBrown, onPressed: () => Navigator.of(context).pop()),
      ],
    );
  }
}
