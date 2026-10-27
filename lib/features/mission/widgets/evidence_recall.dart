import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/audio_service.dart';
import '../../../data/models/episode.dart';
import '../../../data/models/game_progress.dart';
import '../../../data/models/mission.dart';
import '../../../widgets/evidence_card.dart';
import '../../../widgets/glossary_text.dart';
import '../../../widgets/ink_icon.dart';
import '../../../widgets/paper.dart';
import '../../game/game_controller.dart';
import '../../game/game_providers.dart';
import '../../notebook/season_archive.dart';

/// The [GameProgress.examined] thing saved once a mission's recalled
/// evidence is brought from the notebook (`missionId:recall`), so the card
/// keeps it after a restart. Never XP, never coins.
const recallBroughtId = 'recall';

/// A piece of evidence the detective has, with where it was found.
typedef HeldEvidence = ({Evidence evidence, Episode episode, String location});

/// Every piece of evidence in the detective's notebook this season, case by
/// case (the Case Archive's: a solved case's all, the others' found so far;
/// operator mode's reference files too). Cases with nothing are left out.
List<(Episode, List<HeldEvidence>)> heldEvidence(List<ArchiveEntry> archive) => [
  for (final entry in archive)
    if (entry.evidence.isNotEmpty)
      (
        entry.episode,
        [
          for (final e in entry.evidence)
            (
              evidence: e,
              episode: entry.episode,
              location: entry.episode.allMissions.firstWhere((m) => m.evidence?.id == e.id).location,
            ),
        ],
      ),
];

/// The evidence [recall] asks for, if it is in the notebook; else null (an
/// id of another season or no case, or not found yet): then no card.
HeldEvidence? recalledEvidence(List<ArchiveEntry> archive, EvidenceRecall recall) {
  for (final (_, held) in heldEvidence(archive)) {
    for (final h in held) {
      if (h.evidence.id == recall.evidenceId) return h;
    }
  }
  return null;
}

/// Pieces of evidence of an earlier season ([ids]: Season 1's `ep12_e4`,
/// the Clockmaker's watch, shown in Season 2) that the detective holds:
/// their case is solved in its own season's record ([solved]), or shown for
/// reference ([reference]: operator access or the season preview, where an
/// earlier season need not be played). Pieces of the season played
/// ([seasonId]), or of no case, are never here. Ids are kept unique across
/// seasons (Season 2's begin `s2_`), so a piece is found by its id alone.
List<HeldEvidence> earlierSeasonEvidence({
  required Iterable<String> ids,
  required List<Episode> allEpisodes,
  required String seasonId,
  required bool Function(Episode episode) solved,
  required bool reference,
}) => [
  for (final id in ids)
    for (final e in allEpisodes)
      if (e.seasonId != seasonId && (reference || solved(e)))
        for (final m in e.allMissions)
          if (m.evidence case final v? when v.id == id) (evidence: v, episode: e, location: m.location),
];

/// [earlierSeasonEvidence] from the saves, read now.
List<HeldEvidence> heldEarlierEvidence(WidgetRef ref, Iterable<String> ids) {
  if (ids.isEmpty) return const [];
  final repo = ref.read(progressRepositoryProvider);
  return earlierSeasonEvidence(
    ids: ids,
    allEpisodes: ref.read(playedEpisodesProvider),
    seasonId: ref.read(selectedSeasonIdProvider),
    solved: (e) => repo.loadSeason(e.seasonId).isSolved(e.id),
    reference: ref.read(operatorAccessProvider) || ref.read(seasonPreviewProvider),
  );
}

/// Under a mission played with evidence of an earlier case
/// ([Mission.recall]): a small card on the page's foot. Tapped, the
/// notebook's evidence opens to pick from; the right one is laid on the
/// card, to look at beside the puzzle (folded or open; tapped, its close
/// look). Only a help: the puzzle never waits for it, a wrong pick only
/// says why, and nothing is paid. No card when the evidence is not in the
/// notebook.
class EvidenceRecallDock extends ConsumerStatefulWidget {
  const EvidenceRecallDock({super.key, required this.mission, required this.recall});

  final Mission mission;
  final EvidenceRecall recall;

  @override
  ConsumerState<EvidenceRecallDock> createState() => _EvidenceRecallDockState();
}

class _EvidenceRecallDockState extends ConsumerState<EvidenceRecallDock> {
  /// Whether the brought evidence's picture is shown (open just after it is
  /// brought; folded when the page comes back to it).
  bool _open = false;

  String get _key => GameProgress.examinedKey(widget.mission.id, recallBroughtId);

  Future<void> _pick() async {
    ref.read(audioServiceProvider).play(GameSound.notebookOpen);
    final recall = widget.recall;
    final brought = await showEvidencePicker(
      context,
      judge: (e) => e.id == recall.evidenceId ? null : recall.missFor(e.id),
    );
    if (brought == recall.evidenceId && mounted) {
      final game = ref.read(gameControllerProvider.notifier);
      game.recordExamined(_key);
      game.recordEvidenceViewed(widget.recall.evidenceId);
      setState(() => _open = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final held = recalledEvidence(ref.watch(seasonArchiveProvider), widget.recall);
    if (held == null) return const SizedBox.shrink();
    final brought = ref.watch(gameControllerProvider).hasExamined(_key);
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final pictureHeight = (MediaQuery.sizeOf(context).height * 0.26).clamp(120.0, 240.0);
    return DecoratedBox(
      key: const ValueKey('evidence-recall'),
      decoration: BoxDecoration(
        color: AppColors.paperLight,
        border: Border(top: BorderSide(color: AppLine.faint(0.2), width: AppLine.hairline)),
        boxShadow: AppShadow.paperLift,
      ),
      child: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.sm, AppSpace.screen, AppSpace.sm),
              child: AnimatedSize(
                duration: reduce ? Duration.zero : const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                alignment: Alignment.bottomCenter,
                child: !brought ? _emptyCard() : _broughtCard(held, reduce, pictureHeight),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Before: what to look for, and where.
  Widget _emptyCard() {
    final title = widget.recall.title ?? EvidenceRecall.defaultTitle;
    final prompt = widget.recall.prompt ?? EvidenceRecall.defaultPrompt;
    return Semantics(
      button: true,
      label: '$title. $prompt Tap to open your notebook.',
      excludeSemantics: true,
      child: InkWell(
        key: const ValueKey('evidence-recall-open'),
        onTap: _pick,
        borderRadius: BorderRadius.circular(AppRadius.paper),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Row(
            children: [
              const InkIcon(InkGlyph.notebook, size: AppIconSize.medium, color: AppColors.burgundy),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.title(size: 18)),
                    Text(prompt, style: AppText.letter(size: 15)),
                  ],
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              const InkIcon(InkGlyph.search, size: AppIconSize.small, color: AppColors.burgundy),
            ],
          ),
        ),
      ),
    );
  }

  /// After: the evidence itself, folded to a line or open to its picture.
  Widget _broughtCard(HeldEvidence held, bool reduce, double pictureHeight) {
    final e = held.evidence;
    void look() {
      ref.read(gameControllerProvider.notifier).recordEvidenceViewed(e.id);
      showEvidenceZoom(context, e, location: held.location);
    }

    return Column(
      key: const ValueKey('evidence-recall-brought'),
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_open) ...[
          Semantics(
            button: true,
            label: '${e.name}. Tap to look closer.',
            excludeSemantics: true,
            child: GestureDetector(
              key: const ValueKey('evidence-recall-picture'),
              behavior: HitTestBehavior.opaque,
              onTap: look,
              child: EvidencePicture(evidence: e, maxHeight: pictureHeight),
            ),
          ),
          const SizedBox(height: AppSpace.sm),
        ],
        Semantics(
          button: true,
          expanded: _open,
          label: 'From your notebook: ${e.name}, Case ${held.episode.number}. ${_open ? 'Tap to fold it away.' : 'Tap to see it.'}',
          excludeSemantics: true,
          child: InkWell(
            key: const ValueKey('evidence-recall-fold'),
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(AppRadius.paper),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: [
                  EvidenceThumb(evidence: e, size: 40),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('NOTEBOOK · CASE ${held.episode.numberLabel}', style: AppText.eyebrow(color: AppColors.inkBrown)),
                        Text(e.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.title(size: 17)),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: reduce ? Duration.zero : const Duration(milliseconds: 200),
                    child: const InkIcon(InkGlyph.chevron, size: AppIconSize.small, color: AppColors.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Opens the notebook's evidence to pick one (see [EvidencePickSheet]):
/// the id of the piece taken, or null when the sheet is closed without one.
Future<String?> showEvidencePicker(
  BuildContext context, {
  String? Function(Evidence evidence)? judge,
  String ask = EvidencePickSheet.defaultAsk,
  List<HeldEvidence> earlier = const [],
}) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  shape: paperSheetShape,
  showDragHandle: false,
  builder: (context) => EvidencePickSheet(judge: judge, ask: ask, earlier: earlier),
);

/// The notebook's evidence, case by case, to pick from. [judge] says why a
/// piece does not fit (the detective then picks again) or null when it
/// does: then the sheet closes with its id. Without [judge] every piece is
/// taken (a talk answers what was shown itself). Each piece can be looked
/// at closer first. [earlier]: pieces of earlier seasons also in the
/// detective's hands, after this season's cases.
class EvidencePickSheet extends ConsumerStatefulWidget {
  const EvidencePickSheet({super.key, this.judge, this.ask = defaultAsk, this.earlier = const []});

  static const defaultAsk = 'Which clue fits? Tap it to bring it.';

  final String? Function(Evidence evidence)? judge;
  final String ask;
  final List<HeldEvidence> earlier;

  @override
  ConsumerState<EvidencePickSheet> createState() => _EvidencePickSheetState();
}

class _EvidencePickSheetState extends ConsumerState<EvidencePickSheet> {
  /// The line for the last piece picked that does not fit, or null.
  String? _miss;

  void _choose(Evidence e) {
    final miss = widget.judge?.call(e);
    if (miss == null) {
      Navigator.of(context).pop(e.id);
      return;
    }
    setState(() => _miss = miss);
  }

  @override
  Widget build(BuildContext context) {
    final seasons = ref.watch(seasonsProvider);
    String cityOf(Episode e) => seasons.firstWhere((s) => s.id == e.seasonId, orElse: () => seasons.first).city;
    final cases = <(String, List<HeldEvidence>)>[
      for (final (episode, held) in heldEvidence(ref.watch(seasonArchiveProvider)))
        ('CASE ${episode.numberLabel} · ${episode.title.toUpperCase()}', held),
      // An earlier season's case, named by its city too (its Case 12 is not
      // this season's).
      for (final h in widget.earlier)
        ('${cityOf(h.episode).toUpperCase()} · CASE ${h.episode.numberLabel} · ${h.episode.title.toUpperCase()}', [h]),
    ];
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.8,
      builder: (context, scroll) => Column(
        children: [
          const PaperSheetTab(),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, AppSpace.md),
            child: Column(
              children: [
                Text('DETECTIVE NOTEBOOK', style: AppText.mark(), textAlign: TextAlign.center),
                const SizedBox(height: AppSpace.sm),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _miss == null
                      ? Text(
                          widget.ask,
                          key: const ValueKey('recall-ask'),
                          textAlign: TextAlign.center,
                          style: AppText.title(size: 18),
                        )
                      : Semantics(
                          liveRegion: true,
                          child: GlossaryText(
                            _miss!,
                            key: ValueKey('recall-miss-$_miss'),
                            textAlign: TextAlign.center,
                            style: AppText.letter(size: 17, color: AppColors.tryAgain),
                          ),
                        ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, AppSpace.xl),
              children: [
                for (final (header, held) in cases) ...[
                  Text(header, style: AppText.eyebrow(color: AppColors.inkBrown)),
                  const SizedBox(height: AppSpace.sm),
                  GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: evidenceGridDelegate(context),
                    children: [
                      for (final h in held)
                        _PickTile(
                          held: h,
                          onPick: () => _choose(h.evidence),
                          onLook: () {
                            ref.read(gameControllerProvider.notifier).recordEvidenceViewed(h.evidence.id);
                            showEvidenceZoom(context, h.evidence, location: h.location);
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpace.lg),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A notebook tile to pick: tapped, it is brought; its glass, a closer look.
class _PickTile extends StatelessWidget {
  const _PickTile({required this.held, required this.onPick, required this.onLook});

  final HeldEvidence held;
  final VoidCallback onPick;
  final VoidCallback onLook;

  @override
  Widget build(BuildContext context) {
    final e = held.evidence;
    return Stack(
      children: [
        Positioned.fill(
          child: Semantics(
            button: true,
            label: '${e.name}, Case ${held.episode.number}. Tap to bring it.',
            excludeSemantics: true,
            child: GestureDetector(
              key: ValueKey('recall-pick-${e.id}'),
              behavior: HitTestBehavior.opaque,
              onTap: onPick,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.paperLight,
                  borderRadius: BorderRadius.circular(AppRadius.paper),
                  border: Border.all(color: AppLine.faint(0.2), width: AppLine.hairline),
                  boxShadow: AppShadow.paperLift,
                ),
                foregroundDecoration: const RuledFrame(),
                child: LayoutBuilder(
                  builder: (context, box) => Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      EvidenceThumb(
                        evidence: e,
                        size: box.hasBoundedHeight
                            ? (box.maxHeight - 12 - 72 * MediaQuery.textScalerOf(context).scale(1)).clamp(32.0, 70.0)
                            : 70,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        e.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.title(size: 15, color: AppColors.navy),
                      ),
                      const SizedBox(height: 2),
                      Text('Bring this', style: AppText.caption(color: AppColors.burgundy), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Semantics(
            button: true,
            label: 'Look closer at ${e.name}',
            excludeSemantics: true,
            child: InkWell(
              key: ValueKey('recall-look-${e.id}'),
              onTap: onLook,
              customBorder: const CircleBorder(),
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Center(child: InkIcon(InkGlyph.search, size: AppIconSize.small, color: AppColors.inkBrown)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
