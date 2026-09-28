import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/audio_service.dart';
import '../../data/models/episode.dart';
import '../../data/models/game_progress.dart';
import '../../data/models/mission.dart';
import '../../widgets/badge_medal.dart';
import '../../widgets/clue_card.dart';
import '../../widgets/game_button.dart';
import '../../widgets/game_toast.dart';
import '../../widgets/paper_background.dart';
import '../game/game_controller.dart';
import '../game/game_providers.dart';
import '../game/scoring.dart';
import 'widgets/london_map_painter.dart';
import 'widgets/map_pin.dart';

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
    final state = _stateOf(progress, episode, m);

    switch (state) {
      case PinState.locked:
        final current = progress.currentMission(episode);
        showGameToast(
          context,
          m.isFinal
              ? 'Locked! Solve all ${episode.missions.length} missions to open the final case.'
              : 'Locked! First solve MISSION ${current?.numberLabel ?? ''} at ${current?.location ?? ''}.',
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
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(m.isFinal ? 'FINAL MISSION' : 'MISSION ${m.numberLabel} · SOLVED', style: AppText.eyebrow()),
              const SizedBox(height: 4),
              Text(m.location, style: AppText.title(size: 26)),
              const SizedBox(height: 16),
              if (clueIndex >= 0) ClueCard(clue: m.clue!, index: clueIndex),
              const SizedBox(height: 16),
              if (!m.isFinal)
                GameButton(
                  label: 'READ THE CASE AGAIN',
                  style: GameButtonStyle.outline,
                  icon: Icons.menu_book_rounded,
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    context.push(Routes.mission(m.id));
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => Consumer(
        builder: (context, ref, _) {
          final soundOn = ref.watch(soundEnabledProvider);
          final solved = ref.watch(gameControllerProvider).isCaseSolved;
          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('GAME MENU', style: AppText.eyebrow()),
                const SizedBox(height: 8),
                SwitchListTile(
                  secondary: Icon(soundOn ? Icons.volume_up_rounded : Icons.volume_off_rounded, color: AppColors.navy),
                  title: Text('Sound effects', style: AppText.subtitle()),
                  value: soundOn,
                  onChanged: (_) => ref.read(soundEnabledProvider.notifier).toggle(),
                ),
                ListTile(
                  leading: const Icon(Icons.menu_book_rounded, color: AppColors.navy),
                  title: Text('Detective Notebook', style: AppText.subtitle()),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context.push(Routes.notebook);
                  },
                ),
                if (solved)
                  ListTile(
                    leading: const Icon(Icons.emoji_events_rounded, color: AppColors.navy),
                    title: Text('Case results', style: AppText.subtitle()),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      context.go(Routes.solved);
                    },
                  ),
                ListTile(
                  leading: const Icon(Icons.home_rounded, color: AppColors.navy),
                  title: Text('Title screen', style: AppText.subtitle()),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    context.go(Routes.start);
                  },
                ),
                const SizedBox(height: 8),
              ],
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
    final done = progress.completedCount(episode);

    return Scaffold(
      body: PaperBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                children: [
                  _MapHeader(
                    episode: episode,
                    progress: progress,
                    completed: done,
                    xp: XpBreakdown.totalFor(episode, progress),
                    onMenu: () => _showMenu(context, ref),
                    onPlayTime: () => ref.read(gameControllerProvider.notifier).playTime,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
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
                                  top: (m.mapY * h - (MapPin.circle + 36) / 2).clamp(0, h - 130),
                                  child: MapPin(
                                    key: ValueKey('pin-${m.id}'),
                                    label: m.isFinal && !progress.allMissionsDone(episode)
                                        ? 'FINAL LOCATION'
                                        : m.location,
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
                  _MapBottomBar(
                    current: current,
                    clueCount: progress.collectedClues(episode).length,
                    onPlay: current == null ? () => context.go(Routes.solved) : () => _openMission(context, ref, current),
                    onNotebook: () => context.push(Routes.notebook),
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

class _MapHeader extends StatelessWidget {
  const _MapHeader({
    required this.episode,
    required this.progress,
    required this.completed,
    required this.xp,
    required this.onMenu,
    required this.onPlayTime,
  });

  final Episode episode;
  final GameProgress progress;
  final int completed;
  final int xp;
  final VoidCallback onMenu;
  final Duration Function() onPlayTime;

  @override
  Widget build(BuildContext context) {
    final total = episode.missions.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 4),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('EPISODE ${episode.numberLabel}', style: AppText.eyebrow()),
                    Text(episode.title, style: AppText.title(size: 22), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              _ElapsedClock(progress: progress, playTime: onPlayTime),
              IconButton(
                tooltip: 'Menu',
                onPressed: onMenu,
                icon: const Icon(Icons.more_vert_rounded, color: AppColors.navy, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                const Icon(Icons.badge_rounded, size: 20, color: AppColors.royalBlue),
                const SizedBox(width: 6),
                Expanded(
                  child: Text('Detective ${progress.detectiveName}',
                      style: AppText.button(size: 16, color: AppColors.royalBlue), overflow: TextOverflow.ellipsis),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.goldDeep, width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star_rounded, size: 18, color: AppColors.navy),
                      const SizedBox(width: 4),
                      XpCounter(value: xp, style: AppText.button(size: 14, color: AppColors.navy)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(end: total == 0 ? 0 : completed / total),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutCubic,
                      builder: (context, v, _) => LinearProgressIndicator(
                        value: v,
                        minHeight: 10,
                        backgroundColor: AppColors.parchmentDark,
                        color: AppColors.gold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text('$completed / $total', style: AppText.button(size: 15, color: AppColors.navy)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ElapsedClock extends StatefulWidget {
  const _ElapsedClock({required this.progress, required this.playTime});

  final GameProgress progress;

  /// Live play time (excludes time the app spent closed or in the background).
  final Duration Function() playTime;

  @override
  State<_ElapsedClock> createState() => _ElapsedClockState();
}

class _ElapsedClockState extends State<_ElapsedClock> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && !widget.progress.isCaseSolved) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.progress;
    final elapsed = p.startedAt == null
        ? Duration.zero
        : p.isCaseSolved
            ? p.elapsed()!
            : widget.playTime();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 16, color: AppColors.goldLight),
          const SizedBox(width: 4),
          Text(Formatters.clock(elapsed),
              style: AppText.button(size: 14, color: Colors.white).copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
        ],
      ),
    );
  }
}

class _MapBottomBar extends StatelessWidget {
  const _MapBottomBar({required this.current, required this.clueCount, required this.onPlay, required this.onNotebook});

  final Mission? current;
  final int clueCount;
  final VoidCallback onPlay;
  final VoidCallback onNotebook;

  @override
  Widget build(BuildContext context) {
    final m = current;
    final label = m == null
        ? 'CASE SOLVED!'
        : m.isFinal
            ? 'OPEN THE FINAL CASE'
            : 'PLAY MISSION ${m.numberLabel}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          _NotebookButton(count: clueCount, onTap: onNotebook),
          const SizedBox(width: 12),
          Expanded(
            child: GameButton(
              label: label,
              icon: m == null ? Icons.emoji_events_rounded : Icons.directions_walk_rounded,
              style: GameButtonStyle.gold,
              onPressed: onPlay,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotebookButton extends StatelessWidget {
  const _NotebookButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Detective notebook, $count clues',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 72,
              height: 69,
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.gold, width: 2.5),
                boxShadow: const [BoxShadow(color: AppColors.navyDeep, offset: Offset(0, 5))],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.menu_book_rounded, color: AppColors.goldLight, size: 28),
                  Text('NOTES', style: AppText.button(size: 11, color: Colors.white)),
                ],
              ),
            ),
            if (count > 0)
              Positioned(
                right: -6,
                top: -6,
                child: TweenAnimationBuilder<double>(
                  key: ValueKey(count),
                  tween: Tween(begin: 0.4, end: 1),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.elasticOut,
                  builder: (context, s, child) => Transform.scale(scale: s, child: child),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.waxRed,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text('$count', style: AppText.button(size: 13, color: Colors.white)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
