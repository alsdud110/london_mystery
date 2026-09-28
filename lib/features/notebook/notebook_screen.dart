import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/episode.dart';
import '../../data/models/game_progress.dart';
import '../../widgets/badge_medal.dart';
import '../../widgets/clue_card.dart';
import '../../widgets/evidence_card.dart';
import '../../widgets/paper_background.dart';
import '../game/game_controller.dart';
import '../game/game_providers.dart';
import '../game/scoring.dart';

/// The Detective Notebook: clues, evidence and badges collected so far.
class NotebookScreen extends ConsumerWidget {
  const NotebookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episode = ref.watch(currentEpisodeProvider);
    final progress = ref.watch(gameControllerProvider);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('DETECTIVE NOTEBOOK'),
          leading: IconButton(
            tooltip: 'Close',
            icon: const Icon(Icons.close_rounded),
            onPressed: () => context.canPop() ? context.pop() : context.go(Routes.map),
          ),
        ),
        body: PaperBackground(
          child: SafeArea(
            top: false,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                      child: _NotebookCover(episode: episode, progress: progress),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.parchment,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: TabBar(
                          dividerHeight: 0,
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            color: AppColors.navy,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          labelColor: AppColors.goldLight,
                          unselectedLabelColor: AppColors.inkBrown,
                          labelStyle: AppText.button(size: 15),
                          unselectedLabelStyle: AppText.button(size: 15),
                          tabs: const [
                            Tab(height: 52, icon: Icon(Icons.search_rounded, size: 20), text: 'CLUES'),
                            Tab(height: 52, icon: Icon(Icons.inventory_2_rounded, size: 20), text: 'EVIDENCE'),
                            Tab(height: 52, icon: Icon(Icons.emoji_events_rounded, size: 20), text: 'BADGES'),
                          ],
                        ),
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          _CluesTab(episode: episode, progress: progress),
                          _EvidenceTab(episode: episode, progress: progress),
                          _BadgesTab(episode: episode, progress: progress),
                        ],
                      ),
                    ),
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

class _NotebookCover extends StatelessWidget {
  const _NotebookCover({required this.episode, required this.progress});

  final Episode episode;
  final GameProgress progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.gold, width: 3),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle),
            child: const Icon(Icons.search_rounded, size: 34, color: AppColors.navy),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CASE NOTES OF', style: AppText.eyebrow(color: AppColors.goldLight)),
                Text('Detective ${progress.detectiveName ?? ''}',
                    style: AppText.title(size: 21, color: Colors.white), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Icon(Icons.star_rounded, color: AppColors.gold),
              XpCounter(value: XpBreakdown.totalFor(episode, progress),
                  style: AppText.button(size: 15, color: AppColors.goldLight)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CluesTab extends StatelessWidget {
  const _CluesTab({required this.episode, required this.progress});

  final Episode episode;
  final GameProgress progress;

  @override
  Widget build(BuildContext context) {
    final clues = progress.collectedClues(episode);
    final total = episode.allClues.length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        for (final (i, clue) in clues.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _Appear(
              index: i,
              child: ClueCard(
                clue: clue,
                index: i,
                location: episode.allMissions.firstWhere((m) => m.clue?.id == clue.id).location,
              ),
            ),
          ),
        for (var i = clues.length; i < total; i++)
          Padding(padding: const EdgeInsets.only(bottom: 12), child: _EmptySlot(label: Formatters.clueNumber(i))),
        _Footer(
          text: clues.length < total
              ? 'Solve missions to find more clues!'
              : 'All clues found! Match each picture to its number.',
        ),
      ],
    );
  }
}

class _EvidenceTab extends StatelessWidget {
  const _EvidenceTab({required this.episode, required this.progress});

  final Episode episode;
  final GameProgress progress;

  @override
  Widget build(BuildContext context) {
    final found = progress.collectedEvidence(episode);
    final total = episode.allEvidence.length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      children: [
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.95,
          children: [
            for (final (i, e) in found.indexed)
              _Appear(
                index: i,
                child: EvidenceTile(
                  evidence: e,
                  location: episode.allMissions.firstWhere((m) => m.evidence?.id == e.id).location,
                ),
              ),
            for (var i = found.length; i < total; i++) const _EmptySlot(label: '?', square: true),
          ],
        ),
        const SizedBox(height: 12),
        _Footer(text: found.isEmpty ? 'Evidence you find will appear here.' : 'Tap evidence to look closer.'),
      ],
    );
  }
}

class _BadgesTab extends StatelessWidget {
  const _BadgesTab({required this.episode, required this.progress});

  final Episode episode;
  final GameProgress progress;

  @override
  Widget build(BuildContext context) {
    final earned = progress.badgeIds.toSet();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 20,
          children: [
            for (final b in GameBadge.values) BadgeMedal(badge: b, earned: earned.contains(b.name), size: 72),
          ],
        ),
        const SizedBox(height: 16),
        _Footer(text: '${earned.length} / ${GameBadge.values.length} badges'),
      ],
    );
  }
}

class _Appear extends StatelessWidget {
  const _Appear({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + index * 120),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) =>
          Opacity(opacity: t, child: Transform.translate(offset: Offset(0, 24 * (1 - t)), child: child)),
      child: child,
    );
  }
}

class _EmptySlot extends StatelessWidget {
  const _EmptySlot({required this.label, this.square = false});

  final String label;
  final bool square;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: square ? null : 84,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.parchmentDark, width: 2),
        color: Colors.white.withValues(alpha: 0.35),
      ),
      child: square
          ? const Center(child: Icon(Icons.lock_rounded, color: AppColors.locked, size: 36))
          : Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.parchment, borderRadius: BorderRadius.circular(14)),
                  child: Text('?', style: AppText.title(size: 26, color: AppColors.locked)),
                ),
                const SizedBox(width: 16),
                Text(label, style: AppText.eyebrow(color: AppColors.locked)),
                const Spacer(),
                const Icon(Icons.lock_rounded, color: AppColors.locked),
              ],
            ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(text, textAlign: TextAlign.center, style: AppText.bodyText(size: 16, color: AppColors.muted)),
      );
}
