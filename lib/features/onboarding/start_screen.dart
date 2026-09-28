import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../widgets/game_button.dart';
import '../../widgets/landmark_art.dart';
import '../../widgets/paper_background.dart';
import '../../data/models/mission.dart';
import '../game/game_controller.dart';
import '../game/game_providers.dart';
import '../game_master/parent_gate.dart';

class StartScreen extends ConsumerStatefulWidget {
  const StartScreen({super.key});

  @override
  ConsumerState<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends ConsumerState<StartScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

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
        backgroundColor: AppColors.paper,
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
    final episode = ref.watch(currentEpisodeProvider);
    final hasSave = progress.hasDetective;

    return Scaffold(
      body: PaperBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                child: Column(
                  children: [
                    const Spacer(),
                    GestureDetector(
                      onLongPress: _openGameMaster,
                      child: AnimatedBuilder(
                        animation: _float,
                        builder: (context, child) => Transform.translate(
                          offset: Offset(0, -6 * Curves.easeInOut.transform(_float.value)),
                          child: child,
                        ),
                        child: const _Emblem(),
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text('LONDON', style: AppText.logo(size: 50), textAlign: TextAlign.center),
                    Text('MYSTERY', style: AppText.logo(size: 50, color: AppColors.goldDeep), textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    Text('Become a Detective.', style: AppText.subtitle(color: AppColors.inkBrown)),
                    const Spacer(),
                    if (hasSave) ...[
                      Text('Welcome back, Detective ${progress.detectiveName}!',
                          style: AppText.bodyText(size: 16, color: AppColors.muted), textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                    ],
                    GameButton(
                      label: hasSave ? 'CONTINUE ADVENTURE' : 'START ADVENTURE',
                      icon: Icons.explore_rounded,
                      style: GameButtonStyle.gold,
                      onPressed: _continue,
                    ),
                    if (hasSave)
                      TextButton(
                        onPressed: _confirmNewGame,
                        child: Text('Start a new case', style: AppText.button(size: 16, color: AppColors.royalBlue)),
                      ),
                    const SizedBox(height: 24),
                    Text('EPISODE ${episode.numberLabel}', style: AppText.eyebrow(color: AppColors.muted)),
                    const SizedBox(height: 4),
                    Text(episode.title, style: AppText.title(size: 20, color: AppColors.navy)),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Emblem extends StatelessWidget {
  const _Emblem();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      height: 180,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.navy,
        border: Border.all(color: AppColors.gold, width: 5),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, 10))],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          const ClipOval(child: LandmarkArt(Artwork.bigBen, borderRadius: 0)),
          Positioned(
            bottom: 6,
            right: 10,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.gold,
                border: Border.all(color: AppColors.navy, width: 3),
              ),
              child: const Icon(Icons.search_rounded, color: AppColors.navy, size: 30),
            ),
          ),
        ],
      ),
    );
  }
}
