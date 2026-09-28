import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../widgets/game_button.dart';
import '../../widgets/ink_icon.dart';
import '../../widgets/london_skyline.dart';
import '../../widgets/paper_background.dart';
import '../game/game_controller.dart';
import '../game/game_providers.dart';
import '../game_master/parent_gate.dart';

/// Title page of the storybook: the name of the game, London, and one way in.
class StartScreen extends ConsumerStatefulWidget {
  const StartScreen({super.key});

  @override
  ConsumerState<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends ConsumerState<StartScreen> {
  void _continue() {
    final progress = ref.read(gameControllerProvider);
    if (progress.isCaseSolved) {
      context.go(Routes.solved);
    } else if (progress.introSeen) {
      context.go(Routes.map);
    } else if (progress.hasDetective) {
      context.go(Routes.episodes);
    } else {
      context.go(Routes.register);
    }
  }

  Future<void> _confirmNewGame() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Start a new case?', style: AppText.title(size: 22)),
        content: Text('Your current case will be closed and the clues will be cleared.', style: AppText.bodyText(size: 16)),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text('Keep playing')),
          FilledButton(onPressed: () => context.pop(true), child: const Text('New case')),
        ],
      ),
    );
    if (ok == true && mounted) {
      await ref.read(gameControllerProvider.notifier).resetAll();
      if (mounted) context.go(Routes.register);
    }
  }

  Future<void> _openGameMaster() async {
    if (await ParentGate.show(context) && mounted) {
      ref.read(gameMasterAccessProvider.notifier).grant();
      context.push(Routes.gameMaster);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(gameControllerProvider);
    final hasSave = progress.hasDetective;

    return Scaffold(
      body: PaperBackground(
        child: SafeArea(
          bottom: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
                      child: Column(
                        children: [
                          const Spacer(flex: 3),
                          // Long-press: grown-ups' game master tools.
                          GestureDetector(onLongPress: _openGameMaster, child: const _Seal()),
                          const SizedBox(height: AppSpace.xl),
                          Text('LONDON', style: AppText.logo(size: 46), textAlign: TextAlign.center),
                          Text('MYSTERY', style: AppText.logo(size: 46, color: AppColors.burgundy), textAlign: TextAlign.center),
                          const SizedBox(height: AppSpace.md),
                          Text('Become a Detective.', style: AppText.aside(size: 18), textAlign: TextAlign.center),
                          const Spacer(flex: 2),
                          if (hasSave) ...[
                            Text('Welcome back, Detective ${progress.detectiveName}!',
                                style: AppText.caption(), textAlign: TextAlign.center),
                            const SizedBox(height: AppSpace.md),
                          ],
                          GameButton(
                            label: hasSave ? 'CONTINUE ADVENTURE' : 'START ADVENTURE',
                            arrow: true,
                            onPressed: _continue,
                          ),
                          SizedBox(
                            height: 56,
                            child: hasSave
                                ? Center(child: InkTextButton(label: 'Start a new case', onPressed: _confirmNewGame))
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const LondonSkyline(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The detective agency's round ink seal.
class _Seal extends StatelessWidget {
  const _Seal();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.navy, width: AppLine.ink),
      ),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppLine.faint(0.35), width: AppLine.hairline),
        ),
        child: const InkIcon(InkGlyph.search, size: 40, color: AppColors.navy),
      ),
    );
  }
}
