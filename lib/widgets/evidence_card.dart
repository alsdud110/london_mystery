import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../core/theme/app_tokens.dart';
import '../data/models/mission.dart';
import 'art_assets.dart';
import 'game_button.dart';
import 'ink_icon.dart';
import 'paper.dart';
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
  const EvidenceTile({super.key, required this.evidence, this.location});

  final Evidence evidence;
  final String? location;

  @override
  Widget build(BuildContext context) {
    final s = GameSymbol.of(evidence.icon);
    return Semantics(
      button: true,
      label: '${evidence.name}. Tap to look closer.',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () => showEvidenceZoom(context, evidence, location: location),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('EVIDENCE', style: AppText.eyebrow(color: AppColors.goldLight)),
                  const SizedBox(height: 12),
                  Container(
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
                        Text(evidence.name, style: AppText.title(size: 28), textAlign: TextAlign.center),
                        if (location != null) Text(location!, style: AppText.eyebrow(color: AppColors.royalBlue)),
                        const SizedBox(height: 10),
                        Text(evidence.description, style: AppText.bodyText(size: 17), textAlign: TextAlign.center),
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
                            child: Text(
                              evidence.inscription!,
                              textAlign: TextAlign.center,
                              style: AppText.letter(size: 18),
                            ),
                          ),
                        ],
                        if (evidence.symbols.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          SymbolSequence(symbols: evidence.symbols),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 200,
                    child: GameButton(
                      label: 'CLOSE',
                      style: GameButtonStyle.glass, // on the dark shade, as the game's other buttons
                      playTapSound: false,
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

/// A numbered row of pictures (left to right), e.g. the Royal Box lock order.
class SymbolSequence extends StatelessWidget {
  const SymbolSequence({super.key, required this.symbols, this.size = 52});

  final List<String> symbols;
  final double size;

  @override
  Widget build(BuildContext context) {
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
              child: Image.asset(
                picture,
                fit: BoxFit.cover,
                width: size,
                height: size,
                cacheWidth: (size * MediaQuery.devicePixelRatioOf(context)).ceil(),
                excludeFromSemantics: true,
                // Its symbol until the picture is ready: never an empty ring.
                frameBuilder: (context, child, frame, sync) => sync || frame != null ? child : Center(child: mark),
                errorBuilder: (context, error, stack) => Center(child: mark),
              ),
            ),
    );
  }
}

/// Small evidence chip used in celebrations.
class EvidenceChip extends StatelessWidget {
  const EvidenceChip({super.key, required this.evidence});

  final Evidence evidence;

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
              Text('EVIDENCE', style: AppText.eyebrow()),
              Text(evidence.name, style: AppText.title(size: 20)),
            ],
          ),
        ),
      ],
    );
  }
}
