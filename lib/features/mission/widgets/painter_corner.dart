import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/audio_service.dart' show TapRole;
import '../../../data/models/abbesses_puzzles.dart';
import '../../../data/models/mission.dart';
import '../../../widgets/game_button.dart';
import '../../../widgets/ink_icon.dart';
import 'opera_papers.dart' show showOperaCloser;
import 'river_papers.dart' show PictureCanvas;

/// M1, the square of Abbesses ([CornerChoiceScene]): the square with its
/// three corners ringed; a corner tapped (on the square, or by its button)
/// is shown under it as seen from its bench (kept looked at: [onLooked]),
/// to compare with the Hidden Sketch brought from the notebook below the
/// page. THE PAINTER SAT HERE sends the corner shown as the answer. A tap
/// on the corner looks at it closer.
class PainterCornerPuzzle extends StatefulWidget {
  const PainterCornerPuzzle({super.key, required this.scene, required this.mission, required this.looked, required this.onLooked, required this.onSubmit});

  final CornerChoiceScene scene;
  final Mission mission;

  /// The corners looked at before, by id.
  final Set<String> looked;
  final ValueChanged<String> onLooked;
  final Future<void> Function(String answer) onSubmit;

  @override
  State<PainterCornerPuzzle> createState() => _PainterCornerPuzzleState();
}

class _PainterCornerPuzzleState extends State<PainterCornerPuzzle> {
  /// The corner shown under the square.
  String? _showing;
  bool _checking = false;

  void _show(String id) {
    setState(() => _showing = id);
    widget.onLooked(id);
  }

  Future<void> _choose() async {
    final id = _showing;
    if (id == null || _checking) return;
    setState(() => _checking = true);
    try {
      await widget.onSubmit(id);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _closer(PainterCorner c) => showOperaCloser<void>(
    context,
    title: c.name,
    closeLabel: widget.scene.backLabel,
    closeKey: const ValueKey('corner-close-done'),
    maxWidth: 720,
    child: Semantics(
      image: true,
      label: c.label,
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: widget.scene.cornerPixels.aspect,
        child: Image.asset(c.file, key: ValueKey('corner-close-${c.id}'), fit: BoxFit.contain, excludeFromSemantics: true),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final scene = widget.scene;
    final showing = _showing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Square(scene: scene, showing: showing, looked: widget.looked, onTap: _show),
        const SizedBox(height: AppSpace.sm),
        Text(scene.task, key: const ValueKey('corner-task'), textAlign: TextAlign.center, style: AppText.bodyText(size: 15, weight: FontWeight.w600, color: AppColors.navy)),
        const SizedBox(height: AppSpace.sm),
        Row(
          children: [
            for (final (i, c) in scene.corners.indexed) ...[
              if (i > 0) const SizedBox(width: AppSpace.xs),
              Expanded(
                child: _CornerTab(
                  key: ValueKey('corner-tab-${c.id}'),
                  corner: c,
                  selected: showing == c.id,
                  looked: widget.looked.contains(c.id),
                  onTap: () => _show(c.id),
                ),
              ),
            ],
          ],
        ),
        if (showing != null) ...[
          const SizedBox(height: AppSpace.md),
          Text('${scene.corner(showing).name} · FROM THE BENCH', textAlign: TextAlign.center, style: AppText.eyebrow()),
          const SizedBox(height: AppSpace.xs),
          Semantics(
            button: true,
            label: '${scene.corner(showing).label}. Tap to look closer.',
            excludeSemantics: true,
            child: GestureDetector(
              key: const ValueKey('corner-view'),
              onTap: () => _closer(scene.corner(showing)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.paper),
                child: AspectRatio(
                  aspectRatio: scene.cornerPixels.aspect,
                  child: Image.asset(scene.corner(showing).file, key: ValueKey('corner-view-$showing'), fit: BoxFit.cover, excludeFromSemantics: true),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: AppSpace.md),
        GameButton(
          key: const ValueKey('corner-choose'),
          label: scene.chooseLabel,
          glyph: InkGlyph.check,
          tap: TapRole.primary,
          onPressed: showing == null || _checking ? null : _choose,
        ),
      ],
    );
  }
}

/// The square, its three corners ringed (the one shown in gold, filled).
class _Square extends StatelessWidget {
  const _Square({required this.scene, required this.showing, required this.looked, required this.onTap});

  final CornerChoiceScene scene;
  final String? showing;
  final Set<String> looked;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(AppRadius.paper),
    child: Semantics(
      label: scene.squareLabel,
      child: PictureCanvas(
        key: const ValueKey('corner-square'),
        pixels: scene.squarePixels,
        child: Stack(
          children: [
            Positioned.fill(child: Image.asset(scene.square, fit: BoxFit.fill, excludeFromSemantics: true)),
            for (final c in scene.corners)
              Positioned.fromRect(
                rect: c.area,
                child: Semantics(
                  button: true,
                  selected: showing == c.id,
                  label: '${c.name}${looked.contains(c.id) ? ', looked at' : ''}. Tap to look at it from the bench.',
                  excludeSemantics: true,
                  child: GestureDetector(
                    key: ValueKey('corner-spot-${c.id}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(c.id),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: showing == c.id ? AppColors.goldLight.withValues(alpha: 0.18) : null,
                        border: Border.all(color: showing == c.id ? AppColors.goldLight : AppColors.paperLight.withValues(alpha: 0.85), width: showing == c.id ? 10 : 6),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          margin: const EdgeInsets.all(12),
                          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                          decoration: BoxDecoration(color: AppColors.navyDeep.withValues(alpha: 0.85), borderRadius: BorderRadius.circular(16)),
                          child: Text(c.name, style: AppText.button(size: 40, color: AppColors.goldLight)),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// A corner's button under the square: its name, ticked once looked at.
class _CornerTab extends StatelessWidget {
  const _CornerTab({super.key, required this.corner, required this.selected, required this.looked, required this.onTap});

  final PainterCorner corner;
  final bool selected;
  final bool looked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: '${corner.name}${looked ? ', looked at' : ''}',
    excludeSemantics: true,
    child: Material(
      color: selected ? AppColors.navy : AppColors.paperLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        side: BorderSide(color: selected ? AppColors.navy : AppLine.faint(0.35), width: AppLine.hairline),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.button),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(corner.name, style: AppText.button(size: 15, color: selected ? AppColors.paperLight : AppColors.navy)),
                  ),
                ),
                if (looked) ...[
                  const SizedBox(width: 4),
                  InkIcon(InkGlyph.check, size: AppIconSize.small, color: selected ? AppColors.goldLight : AppColors.success),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
