import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/models/episode.dart';
import '../../data/models/game_progress.dart';
import '../../widgets/game_button.dart';
import '../../widgets/game_toast.dart';
import '../../widgets/ink_icon.dart';
import '../../widgets/paper.dart';
import '../../widgets/paper_background.dart';
import '../game/game_controller.dart';
import '../game/game_providers.dart';

/// One case file on the shelf: its episode, and how far the detective got.
class _CaseEntry {
  const _CaseEntry({
    required this.episode,
    required this.unlocked,
    required this.everSolved,
    required this.progress,
    this.previous,
  });

  final Episode episode;
  final bool unlocked;

  /// Solved at least once (season record) — stays true when replayed.
  final bool everSolved;
  final GameProgress progress;

  /// The case that must be solved first (for the sealed note).
  final Episode? previous;

  bool get solved => progress.isCaseSolved;
  bool get started => progress.introSeen;
}

/// The detective's shelf of case files: Case → Episode. One purpose: choose
/// what to investigate. A case stays sealed until the case before it is
/// solved; the game controller checks this again when a case is opened.
class EpisodeSelectScreen extends ConsumerStatefulWidget {
  const EpisodeSelectScreen({super.key, this.focusCase});

  /// A case to show chosen and open on arrival ("OPEN CASE 03" after a
  /// solve). Ignored when it is unknown or still sealed.
  final String? focusCase;

  @override
  ConsumerState<EpisodeSelectScreen> createState() => _EpisodeSelectScreenState();
}

class _EpisodeSelectScreenState extends ConsumerState<EpisodeSelectScreen> {
  /// Id of the open folder (accordion: at most one), or null.
  String? _openCase;

  /// The chosen episode, or null.
  String? _chosen;

  /// The folder of [EpisodeSelectScreen.focusCase], scrolled into view.
  final _focusKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Every visit starts with the folders closed. A detective already on a
    // case keeps it chosen, so CONTINUE works without reopening it.
    if (ref.read(gameControllerProvider).introSeen) _chosen = ref.read(currentEpisodeProvider).id;
    // Coming from "OPEN CASE NN": that case is chosen, open and in view,
    // so the next tap begins it.
    final focus = widget.focusCase;
    final known = ref.read(episodeCatalogProvider).any((e) => e.id == focus);
    if (focus != null && known && ref.read(seasonProvider.notifier).isUnlocked(focus)) {
      _chosen = _openCase = focus;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final target = _focusKey.currentContext;
        if (mounted && target != null) {
          Scrollable.ensureVisible(target, alignment: 0.1, duration: const Duration(milliseconds: 300));
        }
      });
    }
  }

  List<_CaseEntry> _shelf() {
    final catalog = ref.watch(episodeCatalogProvider);
    final active = ref.watch(currentEpisodeProvider);
    final activeProgress = ref.watch(gameControllerProvider);
    ref.watch(seasonProvider); // re-read when a case is solved
    final season = ref.read(seasonProvider.notifier);
    final repo = ref.read(progressRepositoryProvider);
    return [
      for (final (i, e) in catalog.indexed)
        _CaseEntry(
          episode: e,
          unlocked: season.isUnlocked(e.id),
          everSolved: ref.read(seasonProvider).isSolved(e.id),
          progress: e.id == active.id ? activeProgress : repo.load(e.id),
          previous: i > 0 ? catalog[i - 1] : null,
        ),
    ];
  }

  void _toggle(String id) => setState(() => _openCase = _openCase == id ? null : id);

  void _go(_CaseEntry c) {
    if (!ref.read(gameControllerProvider.notifier).openEpisode(c.episode.id)) {
      showGameToast(context, 'This case file is still sealed.');
      return;
    }
    final progress = ref.read(gameControllerProvider);
    context.go(progress.introSeen ? Routes.map : Routes.intro);
  }

  @override
  Widget build(BuildContext context) {
    final shelf = _shelf();
    final chosen = shelf.where((c) => c.episode.id == _chosen && c.unlocked).firstOrNull;
    final status = chosen ?? shelf.firstWhere((c) => c.episode.id == ref.read(currentEpisodeProvider).id);
    final label = status.solved
        ? 'REVIEW THE CASE'
        : status.started
        ? 'CONTINUE INVESTIGATION'
        : 'BEGIN INVESTIGATION';

    return Scaffold(
      appBar: AppBar(
        title: const Text('CASE FILES'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const InkIcon(InkGlyph.back),
          onPressed: () => context.go(Routes.register),
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
                  Expanded(
                    // Twelve folders at most: all built at once, so the one
                    // to focus can be scrolled to even when far down.
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.sm, AppSpace.screen, AppSpace.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final c in shelf) ...[
                            _CaseFolderTile(
                              key: c.episode.id == widget.focusCase ? _focusKey : null,
                              entry: c,
                              open: _openCase == c.episode.id,
                              chosen: _chosen == c.episode.id,
                              onToggle: () => _toggle(c.episode.id),
                              onChoose: () => setState(() => _chosen = c.episode.id),
                            ),
                            const SizedBox(height: AppSpace.xl),
                          ],
                        ],
                      ),
                    ),
                  ),
                  // The one action, always at the bottom of the page.
                  Container(
                    padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.md, AppSpace.screen, AppSpace.lg),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AppLine.faint(), width: AppLine.hairline),
                      ),
                    ),
                    child: GameButton(label: label, arrow: true, onPressed: chosen == null ? null : () => _go(chosen)),
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

class _CaseFolderTile extends StatelessWidget {
  const _CaseFolderTile({
    super.key,
    required this.entry,
    required this.open,
    required this.chosen,
    required this.onToggle,
    required this.onChoose,
  });

  final _CaseEntry entry;
  final bool open;
  final bool chosen;
  final VoidCallback onToggle;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final e = entry.episode;
    final sealed = !entry.unlocked;
    return CaseFolder(
      tab: 'CASE ${e.numberLabel}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: open,
            label:
                'Case ${e.number}, ${e.title}${sealed
                    ? ', sealed'
                    : entry.everSolved
                    ? ', solved'
                    : ''}',
            excludeSemantics: true,
            child: InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.md, AppSpace.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        e.title.toUpperCase(),
                        style: AppText.title(size: 20, color: sealed ? AppColors.locked : AppColors.ink),
                      ),
                    ),
                    if (sealed || entry.everSolved) ...[
                      const SizedBox(width: AppSpace.sm),
                      InkStamp(
                        sealed ? 'SEALED' : 'SOLVED',
                        color: sealed ? AppColors.locked : AppColors.success,
                        size: 11,
                      ),
                      const SizedBox(width: AppSpace.md),
                    ],
                    AnimatedRotation(
                      turns: open ? 0.25 : 0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCubic,
                      child: const InkIcon(InkGlyph.arrow, size: AppIconSize.medium, color: AppColors.inkBrown),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: !open
                ? const SizedBox(width: double.infinity)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _EpisodeRow(entry: entry, chosen: chosen && !sealed, onChoose: onChoose),
                      const SizedBox(height: AppSpace.sm),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// The episode inside a case: one level down (indented, smaller, ruled).
class _EpisodeRow extends StatelessWidget {
  const _EpisodeRow({required this.entry, required this.chosen, required this.onChoose});

  final _CaseEntry entry;
  final bool chosen;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final e = entry.episode;
    final playable = entry.unlocked;
    final label = 'EPISODE ${e.numberLabel}';
    final previous = entry.previous;
    final row = Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
      padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.md, AppSpace.sm, AppSpace.md),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppLine.faint(), width: AppLine.hairline),
          left: BorderSide(color: chosen ? AppColors.navy : Colors.transparent, width: 3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppText.caption(color: playable ? AppColors.inkBrown : AppColors.locked)),
                const SizedBox(height: 2),
                Text(
                  e.title,
                  style: playable ? AppText.subtitle(color: AppColors.navy) : AppText.aside(color: AppColors.locked),
                ),
                if (!playable && previous != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpace.xs),
                    child: Text('Solve Case ${previous.numberLabel} to open this file.', style: AppText.caption()),
                  ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.topLeft,
                  child: chosen
                      ? Padding(
                          padding: const EdgeInsets.only(top: AppSpace.xs),
                          child: Text(e.synopsis.first, style: AppText.caption()),
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.sm),
            child: playable
                ? (chosen
                      ? const InkIcon(InkGlyph.check, size: AppIconSize.medium, color: AppColors.navy)
                      : const SizedBox(width: AppIconSize.medium))
                : const InkIcon(InkGlyph.lock, size: AppIconSize.small, color: AppColors.locked),
          ),
        ],
      ),
    );
    if (!playable) return Semantics(label: '$label, ${e.title}, sealed', excludeSemantics: true, child: row);
    return Semantics(
      button: true,
      selected: chosen,
      label: '$label, ${e.title}',
      excludeSemantics: true,
      child: InkWell(onTap: onChoose, child: row),
    );
  }
}
