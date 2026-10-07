import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/models/episode.dart';
import '../../data/models/mission.dart';
import '../../widgets/clue_card.dart';
import '../../widgets/evidence_card.dart';
import '../../widgets/ink_icon.dart';
import '../../widgets/paper.dart';
import '../game/game_controller.dart';
import '../game/game_providers.dart';

/// How far the detective got in one case, as the archive shows it.
enum ArchiveStatus { solved, current, started, notOpened, sealed }

/// One case of the season in the archive, with what the detective found.
///
/// Nothing is stored for the archive: it is read from the season record
/// (`lm.season.v1`) and the case saves (`lm.progress.v1`, `lm.progress.v1.epNN`).
class ArchiveEntry {
  const ArchiveEntry({required this.episode, required this.status, this.evidence = const [], this.clues = const []});

  final Episode episode;
  final ArchiveStatus status;
  final List<Evidence> evidence;
  final List<Clue> clues;

  bool get canOpen => status != ArchiveStatus.sealed && status != ArchiveStatus.notOpened;
}

/// Every case of the season, in case order.
///
/// A case solved once shows everything it holds (the detective found all of
/// it), even while it is being played again. The open case shows what has
/// been found so far; other started cases read their own save.
final seasonArchiveProvider = Provider<List<ArchiveEntry>>((ref) {
  final catalog = ref.watch(episodeCatalogProvider);
  final season = ref.watch(seasonProvider);
  final active = ref.watch(currentEpisodeProvider);
  final activeProgress = ref.watch(gameControllerProvider);
  ref.watch(operatorAccessProvider); // which files are sealed
  final unlocks = ref.read(seasonProvider.notifier);
  final repo = ref.read(progressRepositoryProvider);

  return [
    for (final e in catalog)
      if (season.isSolved(e.id))
        ArchiveEntry(episode: e, status: ArchiveStatus.solved, evidence: e.allEvidence, clues: e.allClues)
      else if (!unlocks.isUnlocked(e.id))
        ArchiveEntry(episode: e, status: ArchiveStatus.sealed)
      else
        () {
          final p = e.id == active.id ? activeProgress : repo.load(e.id);
          final status = e.id == active.id
              ? ArchiveStatus.current
              : (p.introSeen ? ArchiveStatus.started : ArchiveStatus.notOpened);
          return ArchiveEntry(episode: e, status: status, evidence: p.collectedEvidence(e), clues: p.collectedClues(e));
        }(),
  ];
});

/// The CASE ARCHIVE part of the notebook: the season's case files on a shelf.
/// Open a case file to look at its evidence and clues again.
class SeasonArchive extends ConsumerStatefulWidget {
  const SeasonArchive({super.key});

  @override
  ConsumerState<SeasonArchive> createState() => _SeasonArchiveState();
}

class _SeasonArchiveState extends ConsumerState<SeasonArchive> {
  /// The open case file (accordion: at most one).
  String? _open;

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(seasonArchiveProvider);
    final solved = entries.where((e) => e.status == ArchiveStatus.solved).length;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      children: [
        Text(
          '$solved of ${entries.length} cases solved',
          textAlign: TextAlign.center,
          style: AppText.aside(),
        ),
        const SizedBox(height: AppSpace.lg),
        for (final entry in entries) ...[
          _ArchiveCase(
            entry: entry,
            open: _open == entry.episode.id,
            onToggle: entry.canOpen
                ? () => setState(() => _open = _open == entry.episode.id ? null : entry.episode.id)
                : null,
          ),
          const SizedBox(height: AppSpace.xl),
        ],
      ],
    );
  }
}

class _ArchiveCase extends StatelessWidget {
  const _ArchiveCase({required this.entry, required this.open, required this.onToggle});

  final ArchiveEntry entry;
  final bool open;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final e = entry.episode;
    final muted = !entry.canOpen;
    final (String? stamp, Color stampColor) = switch (entry.status) {
      ArchiveStatus.solved => ('SOLVED', AppColors.success),
      ArchiveStatus.current => ('THIS CASE', AppColors.navy),
      ArchiveStatus.started => ('OPEN', AppColors.inkBrown),
      ArchiveStatus.notOpened => (null, AppColors.locked),
      ArchiveStatus.sealed => ('SEALED', AppColors.locked),
    };
    final status = switch (entry.status) {
      ArchiveStatus.solved => 'solved',
      ArchiveStatus.current => 'this case',
      ArchiveStatus.started => 'open',
      ArchiveStatus.notOpened => 'not opened yet',
      ArchiveStatus.sealed => 'sealed',
    };

    return CaseFolder(
      tab: 'CASE ${e.numberLabel}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: onToggle != null,
            expanded: open,
            label: 'Case ${e.number}, ${e.title}, $status',
            excludeSemantics: true,
            child: InkWell(
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.md, AppSpace.lg),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            e.title.toUpperCase(),
                            style: AppText.placeTitle(size: 18, color: muted ? AppColors.locked : AppColors.ink),
                          ),
                          if (entry.status == ArchiveStatus.notOpened)
                            Text('Not opened yet.', style: AppText.caption(color: AppColors.muted)),
                        ],
                      ),
                    ),
                    if (stamp != null) ...[
                      const SizedBox(width: AppSpace.sm),
                      InkStamp(stamp, color: stampColor, size: 11),
                      const SizedBox(width: AppSpace.md),
                    ],
                    if (onToggle != null)
                      AnimatedRotation(
                        turns: open ? 0.25 : 0,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        child: const InkIcon(InkGlyph.arrow, size: AppIconSize.medium, color: AppColors.inkBrown),
                      )
                    else
                      const InkIcon(InkGlyph.lock, size: AppIconSize.small, color: AppColors.locked),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: open ? _CaseRecord(entry: entry) : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// The inside of an open case file: its evidence and clues.
class _CaseRecord extends StatelessWidget {
  const _CaseRecord({required this.entry});

  final ArchiveEntry entry;

  String _placeOf(bool Function(Mission m) test) {
    for (final m in entry.episode.allMissions) {
      if (test(m)) return m.location;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(height: AppLine.hairline, color: AppLine.faint()),
          const SizedBox(height: AppSpace.md),
          Text('EVIDENCE', style: AppText.eyebrow(color: AppColors.inkBrown)),
          const SizedBox(height: AppSpace.sm),
          if (entry.evidence.isEmpty)
            Text('No evidence yet.', style: AppText.caption())
          else
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: evidenceGridDelegate(context),
              children: [
                for (final v in entry.evidence)
                  EvidenceTile(evidence: v, location: _placeOf((m) => m.evidence?.id == v.id)),
              ],
            ),
          if (entry.clues.isNotEmpty) ...[
            const SizedBox(height: AppSpace.lg),
            Text('CLUES', style: AppText.eyebrow(color: AppColors.inkBrown)),
            const SizedBox(height: AppSpace.sm),
            for (final (i, c) in entry.clues.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpace.sm),
                child: ClueCard(clue: c, index: i, location: _placeOf((m) => m.clue?.id == c.id)),
              ),
          ],
        ],
      ),
    );
  }
}
