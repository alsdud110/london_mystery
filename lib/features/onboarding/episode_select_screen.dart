import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../widgets/game_button.dart';
import '../../widgets/ink_icon.dart';
import '../../widgets/paper.dart';
import '../../widgets/paper_background.dart';
import '../game/game_controller.dart';
import '../game/game_providers.dart';

/// One episode row in a case folder. Only the loaded episode is playable;
/// the others are sealed files ("Coming soon").
class _EpisodeEntry {
  const _EpisodeEntry(this.number, {this.title, this.synopsis});

  final int number;
  final String? title;
  final String? synopsis;

  bool get playable => title != null;
}

class _CaseEntry {
  const _CaseEntry(this.number, {this.title, required this.episodes});

  final int number;
  final String? title;
  final List<_EpisodeEntry> episodes;
}

String _two(int n) => n.toString().padLeft(2, '0');

/// The detective's shelf of case files: Case → Episode. One purpose: choose
/// what to investigate. Display only — the playable episode is still the one
/// the app loaded (`currentEpisodeProvider`), so the game flow is unchanged.
class EpisodeSelectScreen extends ConsumerStatefulWidget {
  const EpisodeSelectScreen({super.key});

  @override
  ConsumerState<EpisodeSelectScreen> createState() => _EpisodeSelectScreenState();
}

class _EpisodeSelectScreenState extends ConsumerState<EpisodeSelectScreen> {
  /// Index of the open folder (accordion: at most one), or null.
  int? _openCase;
  bool _chosen = false;

  @override
  void initState() {
    super.initState();
    // Every visit starts with the folders closed. A detective already on the
    // case keeps their episode chosen, so CONTINUE works without reopening it.
    _chosen = ref.read(gameControllerProvider).introSeen;
  }

  List<_CaseEntry> _shelf() {
    final e = ref.read(currentEpisodeProvider);
    return [
      _CaseEntry(1, title: e.title.toUpperCase(), episodes: [
        _EpisodeEntry(e.number, title: e.title, synopsis: e.synopsis.first),
        _EpisodeEntry(e.number + 1),
        _EpisodeEntry(e.number + 2),
      ]),
      const _CaseEntry(2, episodes: [_EpisodeEntry(1)]),
    ];
  }

  void _toggle(int i) => setState(() => _openCase = _openCase == i ? null : i);

  @override
  Widget build(BuildContext context) {
    final started = ref.watch(gameControllerProvider).introSeen;
    final shelf = _shelf();

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
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.sm, AppSpace.screen, AppSpace.xl),
                      children: [
                        for (final (i, c) in shelf.indexed) ...[
                          _CaseFolderTile(
                            entry: c,
                            open: _openCase == i,
                            chosen: _chosen,
                            onToggle: () => _toggle(i),
                            onChoose: () => setState(() => _chosen = true),
                          ),
                          const SizedBox(height: AppSpace.xl),
                        ],
                      ],
                    ),
                  ),
                  // The one action, always at the bottom of the page.
                  Container(
                    padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.md, AppSpace.screen, AppSpace.lg),
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: AppLine.faint(), width: AppLine.hairline)),
                    ),
                    child: GameButton(
                      label: started ? 'CONTINUE INVESTIGATION' : 'BEGIN INVESTIGATION',
                      arrow: true,
                      onPressed: _chosen ? () => context.go(started ? Routes.map : Routes.intro) : null,
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

class _CaseFolderTile extends StatelessWidget {
  const _CaseFolderTile({
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
    final sealed = entry.title == null;
    return CaseFolder(
      tab: 'CASE ${_two(entry.number)}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            expanded: open,
            label: 'Case ${entry.number}${sealed ? ', sealed' : ', ${entry.title}'}',
            excludeSemantics: true,
            child: InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.md, AppSpace.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: sealed
                          ? Text('A sealed case', style: AppText.aside())
                          : Text(entry.title!, style: AppText.title(size: 20)),
                    ),
                    if (sealed) ...[
                      const InkStamp('SEALED', color: AppColors.locked, size: 11),
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
                      for (final ep in entry.episodes) _EpisodeRow(entry: ep, chosen: chosen && ep.playable, onChoose: onChoose),
                      const SizedBox(height: AppSpace.sm),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// An episode inside a case: one level down (indented, smaller, ruled).
class _EpisodeRow extends StatelessWidget {
  const _EpisodeRow({required this.entry, required this.chosen, required this.onChoose});

  final _EpisodeEntry entry;
  final bool chosen;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final label = 'EPISODE ${_two(entry.number)}';
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
                Text(label, style: AppText.caption(color: entry.playable ? AppColors.inkBrown : AppColors.locked)),
                const SizedBox(height: 2),
                Text(
                  entry.title ?? 'Coming soon',
                  style: entry.playable ? AppText.subtitle(color: AppColors.navy) : AppText.aside(color: AppColors.locked),
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  alignment: Alignment.topLeft,
                  child: chosen && entry.synopsis != null
                      ? Padding(
                          padding: const EdgeInsets.only(top: AppSpace.xs),
                          child: Text(entry.synopsis!, style: AppText.caption()),
                        )
                      : const SizedBox(width: double.infinity),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.sm),
            child: entry.playable
                ? (chosen ? const InkIcon(InkGlyph.check, size: AppIconSize.medium, color: AppColors.navy) : const SizedBox(width: AppIconSize.medium))
                : const InkIcon(InkGlyph.lock, size: AppIconSize.small, color: AppColors.locked),
          ),
        ],
      ),
    );
    if (!entry.playable) return Semantics(label: '$label, coming soon', excludeSemantics: true, child: row);
    return Semantics(
      button: true,
      selected: chosen,
      label: '$label, ${entry.title}',
      excludeSemantics: true,
      child: InkWell(onTap: onChoose, child: row),
    );
  }
}
