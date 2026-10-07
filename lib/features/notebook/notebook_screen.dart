import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/episode.dart';
import '../../data/models/game_progress.dart';
import '../../widgets/badge_medal.dart';
import '../../widgets/clue_card.dart';
import '../../widgets/evidence_card.dart';
import '../../widgets/ink_icon.dart';
import '../../widgets/paper.dart';
import '../../widgets/paper_background.dart';
import '../game/game_controller.dart';
import '../game/game_providers.dart';
import '../game/scoring.dart';
import 'season_archive.dart';

/// The Detective Notebook, in two parts: THIS CASE (clues, evidence and
/// badges of the open case) and the CASE ARCHIVE (every case of the season,
/// so evidence from earlier cases can be checked again, e.g. in Case 12).
///
/// Switching parts is state inside this one screen: closing the notebook
/// always returns to the mission exactly as it was.
class NotebookScreen extends ConsumerStatefulWidget {
  const NotebookScreen({super.key, this.startInArchive = false});

  final bool startInArchive;

  @override
  ConsumerState<NotebookScreen> createState() => _NotebookScreenState();
}

class _NotebookScreenState extends ConsumerState<NotebookScreen> {
  late bool _archive = widget.startInArchive;

  @override
  Widget build(BuildContext context) {
    final episode = ref.watch(currentEpisodeProvider);
    final progress = ref.watch(gameControllerProvider);

    final Widget casePage = Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: _NotebookCover(episode: episode, progress: progress),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          // Index tabs of the notebook: the open one underlined in ink.
          child: TabBar(
              dividerHeight: AppLine.hairline,
              dividerColor: AppLine.faint(),
              indicatorSize: TabBarIndicatorSize.label,
              indicator: const UnderlineTabIndicator(borderSide: BorderSide(color: AppColors.burgundy, width: AppLine.ink + 0.5)),
              labelColor: AppColors.navy,
              unselectedLabelColor: AppColors.muted,
              // Three equal tabs on a 360-wide phone: a narrow side padding so
              // "EVIDENCE" is not clipped.
              labelPadding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
              labelStyle: AppText.style(AppText.body, size: 13, weight: FontWeight.w600, letterSpacing: 0.8),
              unselectedLabelStyle: AppText.style(AppText.body, size: 13, weight: FontWeight.w600, letterSpacing: 0.8),
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              // Lettered tabs until the evidence and badge glyphs
              // exist (Custom Asset Required) — all three match.
              tabs: const [
                Tab(height: 52, text: 'CLUES'),
                Tab(height: 52, text: 'EVIDENCE'),
                Tab(height: 52, text: 'BADGES'),
              ],
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
    );

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('DETECTIVE NOTEBOOK'),
          leading: IconButton(
            tooltip: 'Close',
            icon: const InkIcon(InkGlyph.close),
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
                    _NotebookParts(archive: _archive, onChanged: (a) => setState(() => _archive = a)),
                    Expanded(child: _archive ? const SeasonArchive() : casePage),
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
    // The notebook's leather cover, gold-tooled at the edge.
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.leather, AppColors.leatherDeep],
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: AppShadow.paperLift,
      ),
      foregroundDecoration: RuledFrame(color: AppColors.goldLight, inset: 6),
      child: Row(
        children: [
          const BrassEmblem(size: 56),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CASE NOTES OF', style: AppText.eyebrow(color: AppColors.goldLight)),
                // The whole name, a little smaller if it must be ("Detective MI…" hid it).
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text('Detective ${progress.detectiveName ?? ''}',
                      maxLines: 1, style: AppText.title(size: 21, color: AppColors.paperLight)),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('XP', style: AppText.eyebrow(color: AppColors.goldLight.withValues(alpha: 0.7))),
              XpCounter(value: XpBreakdown.totalFor(episode, progress), suffix: '',
                  style: AppText.title(size: 22, color: AppColors.goldLight)),
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
              : episode.finalMission.dialSymbols.isNotEmpty
                  ? 'All clues found! Match each picture to its number.'
                  : 'All clues found! Now solve the final case.',
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
        GridView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: evidenceGridDelegate(context),
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
            for (final b in GameBadge.forEpisode(episode)) BadgeMedal(badge: b, earned: earned.contains(b.name), size: 72),
          ],
        ),
        const SizedBox(height: 16),
        _Footer(text: '${earned.length} / ${GameBadge.forEpisode(episode).length} badges'),
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
    // A short cascade, capped: the tenth clue is not kept waiting, and with
    // reduced motion the page is simply there.
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: still ? Duration.zero : Duration(milliseconds: 350 + (index * 80).clamp(0, 320)),
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
    // An empty pocket of the notebook, pencilled in.
    return Container(
      height: square ? null : 84,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.paper),
        border: Border.all(color: AppColors.parchmentDark, width: AppLine.rule),
        color: AppColors.parchment.withValues(alpha: 0.5),
      ),
      child: square
          ? const Center(child: InkIcon(InkGlyph.lock, color: AppColors.locked, size: AppIconSize.emblem))
          : Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: AppColors.parchment, borderRadius: BorderRadius.circular(6)),
                  child: Text('?', style: AppText.title(size: 26, color: AppColors.locked)),
                ),
                const SizedBox(width: 16),
                Text(label, style: AppText.eyebrow(color: AppColors.muted)),
                const Spacer(),
                const InkIcon(InkGlyph.lock, color: AppColors.locked),
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

/// The notebook's two parts, written like section headings in a detective's
/// notebook: the chosen one is underlined in ink.
class _NotebookParts extends StatelessWidget {
  const _NotebookParts({required this.archive, required this.onChanged});

  final bool archive;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget part(String label, bool selected, bool value) => Expanded(
          child: Semantics(
            button: true,
            selected: selected,
            label: label,
            excludeSemantics: true,
            child: InkWell(
              onTap: () => onChanged(value),
              child: Container(
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(
                    bottom: selected
                        ? const BorderSide(color: AppColors.navy, width: AppLine.ink)
                        : BorderSide(color: AppLine.faint(), width: AppLine.hairline),
                  ),
                ),
                child: Text(label, style: AppText.eyebrow(color: selected ? AppColors.navy : AppColors.muted)),
              ),
            ),
          ),
        );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        children: [
          part('THIS CASE', !archive, false),
          part('CASE ARCHIVE', archive, true),
        ],
      ),
    );
  }
}
