import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/audio_service.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/episode.dart';
import '../../data/models/game_progress.dart';
import '../../data/models/mission.dart';
import '../../widgets/clue_card.dart';
import '../../widgets/game_button.dart';
import '../../widgets/game_toast.dart';
import '../../widgets/ink_icon.dart';
import '../../widgets/paper.dart';
import '../../widgets/paper_background.dart';
import '../game/game_controller.dart';
import '../game/game_providers.dart';
import '../game/scoring.dart';
import 'widgets/london_map_painter.dart';
import 'widgets/map_pin.dart';

/// The detective's map of London. One purpose: go to the next place.
/// Case status (name, XP, play time) lives in the menu, not on the map.
class MissionMapScreen extends ConsumerWidget {
  const MissionMapScreen({super.key});

  PinState _stateOf(GameProgress p, Episode e, Mission m) {
    if (p.isCompleted(m.id)) return PinState.completed;
    if (p.isUnlocked(e, m.id)) return PinState.current;
    return PinState.locked;
  }

  void _openMission(BuildContext context, WidgetRef ref, Mission m) {
    final progress = ref.read(gameControllerProvider);
    final episode = ref.read(currentEpisodeProvider);

    switch (_stateOf(progress, episode, m)) {
      case PinState.locked:
        final current = progress.currentMission(episode);
        showGameToast(
          context,
          m.isFinal
              ? 'Locked! Solve all ${episode.missions.length} places to open the final case.'
              : 'Locked! First solve the case at ${current?.location ?? ''}.',
        );
      case PinState.current:
        context.push(m.isFinal ? Routes.finalMission : Routes.mission(m.id));
      case PinState.completed:
        _showSolvedSheet(context, progress, episode, m);
    }
  }

  void _showSolvedSheet(BuildContext context, GameProgress progress, Episode episode, Mission m) {
    final clues = progress.collectedClues(episode);
    final clueIndex = m.clue == null ? -1 : clues.indexWhere((c) => c.id == m.clue!.id);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, AppSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text(m.location, style: AppText.title(size: 24))),
                  const InkStamp('SOLVED', color: AppColors.success, size: 13),
                ],
              ),
              const SizedBox(height: AppSpace.lg),
              if (clueIndex >= 0) ClueCard(clue: m.clue!, index: clueIndex),
              if (!m.isFinal) ...[
                const SizedBox(height: AppSpace.lg),
                GameButton(
                  label: 'READ THE CASE AGAIN',
                  style: GameButtonStyle.outline,
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    context.push(Routes.mission(m.id));
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => Consumer(
        builder: (context, ref, _) {
          final soundOn = ref.watch(soundEnabledProvider);
          final progress = ref.watch(gameControllerProvider);
          final episode = ref.watch(currentEpisodeProvider);
          final playTime = ref.read(gameControllerProvider.notifier).playTime;
          final xp = XpBreakdown.totalFor(episode, progress);

          Widget item(InkGlyph glyph, String label, VoidCallback onTap) => ListTile(
                leading: InkIcon(glyph, color: AppColors.ink),
                title: Text(label, style: AppText.subtitle()),
                onTap: onTap,
              );

          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Case status: shown here, on request, instead of on the map.
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, AppSpace.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(episode.title, style: AppText.aside()),
                        Text('Detective ${progress.detectiveName}', style: AppText.title(size: 22)),
                        const SizedBox(height: AppSpace.xs),
                        Text(
                          '$xp XP  ·  ${Formatters.clock(playTime)}',
                          style: AppText.caption(color: AppColors.goldDeep)
                              .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  SwitchListTile(
                    secondary: InkIcon(soundOn ? InkGlyph.speaker : InkGlyph.speakerOff, color: AppColors.ink),
                    title: Text('Sound effects', style: AppText.subtitle()),
                    value: soundOn,
                    onChanged: (_) => ref.read(soundEnabledProvider.notifier).toggle(),
                  ),
                  item(InkGlyph.notebook, 'Detective Notebook', () {
                    Navigator.of(sheetContext).pop();
                    context.push(Routes.notebook);
                  }),
                  if (progress.isCaseSolved)
                    item(InkGlyph.folder, 'Case results', () {
                      Navigator.of(sheetContext).pop();
                      context.go(Routes.solved);
                    }),
                  item(InkGlyph.home, 'Title screen', () {
                    Navigator.of(sheetContext).pop();
                    context.go(Routes.start);
                  }),
                  const SizedBox(height: AppSpace.sm),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episode = ref.watch(currentEpisodeProvider);
    final progress = ref.watch(gameControllerProvider);
    final recentUnlock = ref.watch(recentUnlockProvider);
    final current = progress.currentMission(episode);
    final all = episode.allMissions;

    final ctaLabel = current == null
        ? 'SEE MY CASE FILE'
        : current.isFinal
            ? 'OPEN THE FINAL CASE'
            : 'GO TO ${current.location}';

    return Scaffold(
      body: PaperBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.sm, AppSpace.sm, AppSpace.xs),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(episode.title, style: AppText.title(size: 20), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ),
                        IconButton(
                          tooltip: 'Menu',
                          onPressed: () => _showMenu(context, ref),
                          icon: const InkIcon(InkGlyph.menu, size: 26),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.xs, AppSpace.lg, AppSpace.md),
                      child: LayoutBuilder(
                        builder: (context, box) {
                          final w = box.maxWidth;
                          final h = box.maxHeight;
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: LondonMapPainter(
                                    route: [for (final m in all) Offset(m.mapX, m.mapY)],
                                    completedLegs: progress.completedMissionIds.length,
                                  ),
                                ),
                              ),
                              for (final m in all)
                                Positioned(
                                  left: (m.mapX * w - MapPin.width / 2).clamp(0, w - MapPin.width),
                                  top: (m.mapY * h - MapPin.anchorY).clamp(0, h - MapPin.height),
                                  child: MapPin(
                                    key: ValueKey('pin-${m.id}'),
                                    label: m.location,
                                    isFinal: m.isFinal,
                                    state: _stateOf(progress, episode, m),
                                    celebrateUnlock: recentUnlock == m.id,
                                    onUnlockBurst: () => ref.read(audioServiceProvider).play(GameSound.unlock),
                                    onUnlockShown: () => ref.read(recentUnlockProvider.notifier).set(null),
                                    onTap: () => _openMission(context, ref, m),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.md),
                    child: Row(
                      children: [
                        _NotebookButton(onTap: () => context.push(Routes.notebook)),
                        const SizedBox(width: AppSpace.md),
                        Expanded(
                          child: GameButton(
                            label: ctaLabel,
                            arrow: true,
                            singleLine: true,
                            onPressed: current == null ? () => context.go(Routes.solved) : () => _openMission(context, ref, current),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The notebook, one tap away (secondary action next to the main button).
class _NotebookButton extends StatelessWidget {
  const _NotebookButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Detective notebook',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(color: AppLine.faint(0.45), width: AppLine.rule),
            ),
            child: const InkIcon(InkGlyph.notebook, size: 28, semanticLabel: 'Detective notebook'),
          ),
        ),
      ),
    );
  }
}
