import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../core/theme/app_tokens.dart';
import '../data/models/mission.dart';
import 'ink_icon.dart';
import 'symbol_icon.dart';

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
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.parchmentDark, width: 1.5),
            boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 3))],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Hero(
                tag: 'evidence-${evidence.id}',
                child: _EvidenceArt(icon: evidence.icon, size: 70),
              ),
              const SizedBox(height: 10),
              Text(evidence.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.button(size: 15, color: AppColors.navy)),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkIcon(InkGlyph.search, size: AppIconSize.small, color: s.color),
                  const SizedBox(width: 2),
                  Flexible(child: Text('Look closer', style: AppText.caption(color: s.color), overflow: TextOverflow.ellipsis)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens the evidence in a large, inspectable view.
Future<void> showEvidenceZoom(BuildContext context, Evidence evidence, {String? location}) {
  return Navigator.of(context).push(PageRouteBuilder<void>(
    opaque: false,
    barrierDismissible: true,
    barrierColor: AppColors.navyDeep.withValues(alpha: 0.85),
    transitionDuration: const Duration(milliseconds: 350),
    pageBuilder: (context, anim, _) => FadeTransition(
      opacity: anim,
      child: _EvidenceZoom(evidence: evidence, location: location),
    ),
  ));
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
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFFF8E6), AppColors.parchment],
                      ),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: AppColors.gold, width: 3),
                    ),
                    child: Column(
                      children: [
                        Hero(tag: 'evidence-${evidence.id}', child: _EvidenceArt(icon: evidence.icon, size: 150)),
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
                              color: Colors.white.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.parchmentDark, width: 1.5),
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
                    height: 56,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.navy,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('CLOSE', style: AppText.button(size: 17, color: AppColors.navy)),
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

class _EvidenceArt extends StatelessWidget {
  const _EvidenceArt({required this.icon, required this.size});

  final String icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final s = GameSymbol.of(icon);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.paperLight,
        border: Border.all(color: s.color.withValues(alpha: 0.6), width: size / 30),
      ),
      child: s.mark(size: size * 0.55),
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
        _EvidenceArt(icon: evidence.icon, size: 56),
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
