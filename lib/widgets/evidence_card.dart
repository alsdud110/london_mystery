import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../core/theme/app_tokens.dart';
import '../data/mock/season1/season1_dialogues.dart';
import '../data/models/mission.dart';
import '../features/game/game_controller.dart';
import '../features/game/game_providers.dart';
import '../features/mission/widgets/dialogue_investigation.dart';
import 'art_assets.dart';
import 'game_button.dart';
import 'glossary_text.dart';
import 'ink_icon.dart';
import 'paper.dart';
import 'royal_box_picture.dart';
import 'symbol_icon.dart';

/// The grid every [EvidenceTile] sits in (notebook, case archive, the final
/// case's notebook peek): two columns of a fixed height, not a ratio, so a
/// two-line name at large text sizes still fits on a 360-wide phone.
SliverGridDelegate evidenceGridDelegate(BuildContext context) => SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 2,
      mainAxisSpacing: AppSpace.md,
      crossAxisSpacing: AppSpace.md,
      mainAxisExtent: evidenceTileHeight(context),
    );

/// The height of an [EvidenceTile], growing with the text size (up to the
/// app's 1.3× cap).
double evidenceTileHeight(BuildContext context) => 196 * MediaQuery.textScalerOf(context).scale(1).clamp(1.0, 1.3);

/// A square evidence tile for the notebook grid. Tap to zoom in.
class EvidenceTile extends StatelessWidget {
  const EvidenceTile({super.key, required this.evidence, this.location, this.onOpened});

  final Evidence evidence;
  final String? location;

  /// Called when the detective opens it for a closer look. The notebook, the
  /// Case Archive and the final case's notebook pass one (a recorded
  /// detective action); other places do not.
  final VoidCallback? onOpened;

  @override
  Widget build(BuildContext context) {
    final s = GameSymbol.of(evidence.icon);
    return Semantics(
      button: true,
      label: '${evidence.name}. Tap to look closer.',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          onOpened?.call();
          showEvidenceZoom(context, evidence, location: location);
        },
        // An evidence tag: paper, a printed frame, the object in the middle.
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.paperLight,
            borderRadius: BorderRadius.circular(AppRadius.paper),
            border: Border.all(color: AppLine.faint(0.2), width: AppLine.hairline),
            boxShadow: AppShadow.paperLift,
          ),
          foregroundDecoration: const RuledFrame(),
          // The picture gives way on short tiles (small phones, large text,
          // two-line names) so the name and "Look closer" always fit.
          child: LayoutBuilder(
            builder: (context, box) => Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Hero(
                  tag: 'evidence-${evidence.id}',
                  child: _EvidenceArt(
                    evidence: evidence,
                    size: box.hasBoundedHeight
                        ? (box.maxHeight - 12 - 72 * MediaQuery.textScalerOf(context).scale(1)).clamp(32.0, 70.0)
                        : 70,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  evidence.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.title(size: 15, color: AppColors.navy),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InkIcon(InkGlyph.search, size: AppIconSize.small, color: s.color),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        'Look closer',
                        style: AppText.caption(color: s.color),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens the evidence in a large, inspectable view.
Future<void> showEvidenceZoom(BuildContext context, Evidence evidence, {String? location}) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: AppColors.navyDeep.withValues(alpha: 0.85),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, anim, _) => FadeTransition(
        opacity: anim,
        child: _EvidenceZoom(evidence: evidence, location: location),
      ),
    ),
  );
}

class _EvidenceZoom extends StatelessWidget {
  const _EvidenceZoom({required this.evidence, this.location});

  final Evidence evidence;
  final String? location;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              // CLOSE always stays on screen: on a small phone only the
              // evidence card scrolls (e.g. the Crown Symbol and its locks).
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('EVIDENCE', style: AppText.mark(color: AppColors.goldLight)),
                  const SizedBox(height: 12),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                        decoration: BoxDecoration(
                          color: AppColors.paperLight,
                          borderRadius: BorderRadius.circular(AppRadius.paper),
                          boxShadow: AppShadow.onNight,
                        ),
                        foregroundDecoration: const RuledFrame(inset: 8),
                        child: Column(
                          children: [
                            Hero(
                              tag: 'evidence-${evidence.id}',
                              child: _EvidenceArt(evidence: evidence, size: 150),
                            ),
                            const SizedBox(height: 18),
                            Text(evidence.name, style: AppText.placeTitle(size: 28), textAlign: TextAlign.center),
                            if (location != null) Text(location!, style: AppText.eyebrow(color: AppColors.royalBlue)),
                            const SizedBox(height: 10),
                            // The evidence's own case explains its words (also in the archive).
                            _Words(evidence.description, evidenceId: evidence.id, style: AppText.bodyText(size: 17)),
                            if (evidence.inscription != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppColors.parchment.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(AppRadius.paper),
                                  border: Border.all(color: AppColors.parchmentDark, width: AppLine.hairline),
                                ),
                                child: _Words(evidence.inscription!, evidenceId: evidence.id, style: AppText.letter(size: 18)),
                              ),
                            ],
                            if (evidence.symbols.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              SymbolSequence(symbols: evidence.symbols),
                            ],
                            _WitnessesSaid(evidenceId: evidence.id),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 200,
                    child: GameButton(
                      label: 'CLOSE',
                      style: GameButtonStyle.glass, // on the dark shade, as the game's other buttons
                      onPressed: () => Navigator.of(context).pop(),
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

/// A row of pictures in order (left to right), e.g. the Royal Box lock
/// order. The Royal Box's own pictures are shown with their names, joined
/// by small ink arrows — no numbers, so the order is never mistaken for the
/// code — exactly as on the crown card and the locks; any other symbol keeps
/// its numbered stamp.
class SymbolSequence extends StatelessWidget {
  const SymbolSequence({super.key, required this.symbols, this.size = 52});

  final List<String> symbols;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (symbols.isNotEmpty && symbols.every((s) => RoyalBoxPicture.of(s) != null)) {
      return Semantics(
        label: 'In order: ${symbols.map(RoyalBoxPicture.nameOf).join(', then ')}.',
        container: true,
        excludeSemantics: true,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (i, s) in symbols.indexed) ...[
                if (i > 0)
                  const Padding(
                    padding: EdgeInsets.only(left: 2, right: 2, bottom: 18),
                    child: InkIcon(InkGlyph.arrow, size: AppIconSize.small, color: AppColors.goldDeep),
                  ),
                Column(
                  key: ValueKey('sequence-$s'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RoyalBoxPictureImage(RoyalBoxPicture.of(s)!, size: size),
                    const SizedBox(height: 2),
                    MediaQuery.withNoTextScaling(
                      child: Text(
                        RoyalBoxPicture.nameOf(s).toUpperCase(),
                        style: AppText.eyebrow(color: AppColors.inkBrown),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    }
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final (i, s) in symbols.indexed)
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SymbolBadge(s, size: size, light: true),
              const SizedBox(height: 4),
              Text('${i + 1}', style: AppText.button(size: 14, color: AppColors.inkBrown)),
            ],
          ),
      ],
    );
  }
}

/// The evidence's picture in a round paper frame: its real picture where it
/// has one (ArtAssets.evidencePictures), else its ink symbol. A picture
/// that fails to load shows the symbol too.
class _EvidenceArt extends StatelessWidget {
  const _EvidenceArt({required this.evidence, required this.size});

  final Evidence evidence;
  final double size;

  @override
  Widget build(BuildContext context) {
    final s = GameSymbol.of(evidence.icon);
    final mark = s.mark(size: size * 0.55);
    final picture = ArtAssets.evidencePictures[evidence.id];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.paperLight,
        border: Border.all(color: s.color.withValues(alpha: 0.6), width: size / 30),
      ),
      // The object is drawn in the middle of its square parchment, so the
      // round frame shows all of it (only plain parchment is left out).
      child: picture == null
          ? mark
          : ClipOval(
              child: Transform.scale(
                // Closer where the object sits small in its margin.
                scale: ArtAssets.evidencePictureZoom[evidence.id] ?? 1,
                child: Image.asset(
                  picture,
                  fit: BoxFit.cover,
                  width: size,
                  height: size,
                  cacheWidth: (size * (ArtAssets.evidencePictureZoom[evidence.id] ?? 1) * MediaQuery.devicePixelRatioOf(context)).ceil(),
                  excludeFromSemantics: true,
                  // Its symbol until the picture is ready: never an empty ring.
                  frameBuilder: (context, child, frame, sync) => sync || frame != null ? child : Center(child: mark),
                  errorBuilder: (context, error, stack) => Center(child: mark),
                ),
              ),
            ),
    );
  }
}

/// Small evidence chip used in celebrations (and after a case is closed,
/// with what is written on the evidence).
class EvidenceChip extends StatelessWidget {
  const EvidenceChip({super.key, required this.evidence, this.note});

  final Evidence evidence;

  /// A line under the name (e.g. the evidence's inscription).
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _EvidenceArt(evidence: evidence, size: 56),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('EVIDENCE', style: AppText.mark()),
              Text(evidence.name, style: AppText.title(size: 20)),
              if (note != null) ...[
                const SizedBox(height: 2),
                Text(note!, style: AppText.letter(size: 15)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// English on a piece of evidence, its harder words explained by the
/// glossary of the case the evidence was found in.
class _Words extends ConsumerWidget {
  const _Words(this.text, {required this.evidenceId, required this.style});

  final String text;
  final String evidenceId;
  final TextStyle style;

  @override
  Widget build(BuildContext context, WidgetRef ref) => GlossaryText(
        text,
        style: style,
        textAlign: TextAlign.center,
        episode: caseOfEvidence(ref.watch(episodeCatalogProvider), evidenceId),
      );
}

/// Under evidence kept from a talk (Case 06 M1's Witness Notes), once that
/// mission is solved: what the witnesses told the detective, word for word,
/// who said it and where — the statements a solved talk is sure to have
/// heard (presentation only: nothing new is saved). Nothing for other
/// evidence.
class _WitnessesSaid extends ConsumerWidget {
  const _WitnessesSaid({required this.evidenceId});

  final String evidenceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episode = ref.watch(currentEpisodeProvider);
    final progress = ref.watch(gameControllerProvider);
    final mission = episode.allMissions.where((m) => m.evidence?.id == evidenceId).firstOrNull;
    final scene = mission == null ? null : dialogueOf(mission);
    if (mission == null || scene == null || !progress.isCompleted(mission.id)) return const SizedBox.shrink();
    final where = 'Heard at the ${scene.place.toLowerCase().split(' ').map((w) => '${w[0].toUpperCase()}${w.substring(1)}').join(' ')} · Mission ${mission.number}';
    return Padding(
      key: const ValueKey('evidence-statements'),
      padding: const EdgeInsets.only(top: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('WHAT THE WITNESSES TOLD YOU', style: AppText.eyebrow(color: AppColors.inkBrown)),
          Text(where, key: const ValueKey('evidence-statements-where'), style: AppText.caption()),
          for (final st in scene.recorded()) ...[
            const SizedBox(height: 10),
            WitnessStatementLine(scene: scene, statement: st),
          ],
        ],
      ),
    );
  }
}
