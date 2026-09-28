import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../data/models/mission.dart';
import '../../widgets/game_button.dart';
import '../../widgets/landmark_art.dart';
import '../../widgets/letter_card.dart';
import '../../widgets/paper_background.dart';
import '../game/game_controller.dart';
import '../game/game_providers.dart';

class EpisodeSelectScreen extends ConsumerWidget {
  const EpisodeSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episode = ref.watch(currentEpisodeProvider);
    final progress = ref.watch(gameControllerProvider);
    final started = progress.introSeen;

    return Scaffold(
      appBar: AppBar(
        title: const Text('CASE FILES'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(Routes.register),
        ),
      ),
      body: PaperBackground(
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                children: [
                  Text('Detective ${progress.detectiveName},\nchoose your case.',
                      style: AppText.subtitle(color: AppColors.inkBrown), textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  _CaseFile(
                    episodeLabel: 'EPISODE ${episode.numberLabel}',
                    title: episode.title.toUpperCase(),
                    synopsis: episode.synopsis,
                    objectives: episode.objectives,
                    missionCount: episode.missions.length,
                  ),
                  const SizedBox(height: 24),
                  GameButton(
                    label: started ? 'CONTINUE INVESTIGATION' : 'BEGIN INVESTIGATION',
                    icon: Icons.search_rounded,
                    style: GameButtonStyle.gold,
                    onPressed: () => context.go(started ? Routes.map : Routes.intro),
                  ),
                  const SizedBox(height: 20),
                  const _LockedEpisode(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CaseFile extends StatelessWidget {
  const _CaseFile({
    required this.episodeLabel,
    required this.title,
    required this.synopsis,
    required this.objectives,
    required this.missionCount,
  });

  final String episodeLabel;
  final String title;
  final List<String> synopsis;
  final List<String> objectives;
  final int missionCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.parchment,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.parchmentDark, width: 2),
        boxShadow: const [BoxShadow(color: Color(0x26000000), blurRadius: 18, offset: Offset(0, 8))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 170,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const LandmarkArt(Artwork.royalBox, borderRadius: 0),
                Positioned(
                  left: 16,
                  top: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(10)),
                    child: Text(episodeLabel, style: AppText.eyebrow(color: AppColors.goldLight)),
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 12,
                  child: Transform.rotate(
                    angle: -0.18,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.waxRed, width: 2.5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('TOP SECRET', style: AppText.eyebrow(color: AppColors.waxRed)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.logo(size: 26)),
                const SizedBox(height: 14),
                for (final line in synopsis)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(line, style: AppText.bodyText(size: 17)),
                  ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      const WaxSeal(size: 46),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('YOUR MISSION', style: AppText.eyebrow()),
                            for (final o in objectives) Text(o, style: AppText.subtitle(color: AppColors.navy)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.place_rounded, color: AppColors.royalBlue, size: 20),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text('$missionCount missions + final case', style: AppText.caption(color: AppColors.royalBlue)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LockedEpisode extends StatelessWidget {
  const _LockedEpisode();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.parchmentDark, width: 2),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_rounded, color: AppColors.locked, size: 30),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('EPISODE 02', style: AppText.eyebrow(color: AppColors.locked)),
                Text('Coming soon...', style: AppText.subtitle(color: AppColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
