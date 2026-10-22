import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/audio_service.dart' show TapRole;
import '../../../data/models/letter_puzzles.dart';
import '../../../data/models/mission.dart';
import '../../../widgets/game_button.dart';
import '../../../widgets/ink_icon.dart';
import 'letter_papers.dart';
import 'river_papers.dart' show PictureCanvas;
import 'workshop_papers.dart';

/// The final's stage ([LetterMapScene]): the letter, its two lines and its
/// drawing (a tap on the drawing looks at it closer); with the solve, it is
/// turned over, and its back is read.
class LetterStage extends StatelessWidget {
  const LetterStage({super.key, required this.scene, required this.open, this.onDrawing});

  final LetterMapScene scene;
  final Animation<double> open;
  final VoidCallback? onDrawing;

  @override
  Widget build(BuildContext context) => Center(
    child: AspectRatio(
      aspectRatio: scene.letter.pixels.aspect,
      child: AnimatedBuilder(
        animation: open,
        builder: (context, _) {
          final t = ((open.value - 0.1) / 0.5).clamp(0.0, 1.0);
          final back = t > 0.5;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(back ? (t - 1) * math.pi : t * math.pi),
            child: LetterPaperView(key: ValueKey('letter-face-${back ? 'back' : 'front'}'), paper: scene.letter, back: back, onDrawing: back ? null : onDrawing),
          );
        },
      ),
    ),
  );
}

/// The drawing in the letter, looked at closer.
Future<void> showLetterDrawing(BuildContext context, LetterMapScene scene) => Navigator.of(context).push<void>(
  PageRouteBuilder<void>(
    opaque: false,
    barrierDismissible: true,
    barrierColor: AppColors.navyDeep.withValues(alpha: 0.94),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (context, anim, _) => FadeTransition(
      opacity: anim,
      child: Material(
        type: MaterialType.transparency,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpace.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('THE DRAWING IN THE LETTER', style: AppText.mark(color: AppColors.goldLight)),
                    const SizedBox(height: AppSpace.md),
                    _Drawing(key: const ValueKey('drawing-close'), scene: scene),
                    const SizedBox(height: AppSpace.lg),
                    Builder(
                      builder: (context) => GameButton(
                        key: const ValueKey('drawing-done'),
                        label: 'BACK',
                        style: GameButtonStyle.glass,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);

/// The letter's drawing on its paper colour, whole.
class _Drawing extends StatelessWidget {
  const _Drawing({super.key, required this.scene});

  final LetterMapScene scene;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(color: AppColors.paperLight, borderRadius: BorderRadius.circular(AppRadius.paper)),
    child: Padding(
      padding: const EdgeInsets.all(AppSpace.sm),
      child: Semantics(
        image: true,
        label: scene.drawingLabel,
        excludeSemantics: true,
        child: PictureCanvas(pixels: scene.sketchPixels, child: Image.asset(scene.letter.sketch, fit: BoxFit.fill, excludeFromSemantics: true)),
      ),
    ),
  );
}

/// The map of Paris ([LetterMapScene]): a ring round each building to look
/// at; a tap looks at it closer, beside the letter's drawing (kept looked
/// at: [onLooked]), where it is chosen. The building chosen goes to
/// [onSubmit], checked as the puzzle's answer.
class LetterMapPuzzle extends StatelessWidget {
  const LetterMapPuzzle({super.key, required this.scene, required this.mission, required this.looked, required this.onLooked, required this.onSubmit});

  final LetterMapScene scene;
  final Mission mission;
  final Set<String> looked;
  final ValueChanged<String> onLooked;
  final Future<void> Function(String answer) onSubmit;

  /// The part of the map shown (pixels): every building in it.
  static const _view = Rect.fromLTRB(90, 30, 1290, 700);

  /// A building's ring, and its round tap, on the map (pixels): the tap is
  /// as wide as the closest two buildings allow (the Palais Garnier and the
  /// Louvre, 242 apart), and round, so no two taps meet.
  static const _ring = 150.0;
  static const tap = 224.0;

  Future<void> _closer(BuildContext context, MapSpot s) async {
    onLooked(s.id);
    final chosen = await Navigator.of(context).push<String>(
      PageRouteBuilder<String>(
        opaque: false,
        barrierDismissible: true,
        barrierColor: AppColors.navyDeep.withValues(alpha: 0.94),
        transitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (context, anim, _) => FadeTransition(opacity: anim, child: _BuildingCloser(scene: scene, spot: s)),
      ),
    );
    if (chosen != null) await onSubmit(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final p = scene.mapPixels;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(scene.mapTask, key: const ValueKey('map-task'), textAlign: TextAlign.center, style: AppText.subtitle()),
        const SizedBox(height: AppSpace.md),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.paper),
          child: Semantics(
            label: 'A map of Paris.',
            child: CroppedPicture(
              key: const ValueKey('letter-map'),
              file: scene.mapFile,
              pixels: p,
              crop: Rect.fromLTRB(_view.left / p.width, _view.top / p.height, _view.right / p.width, _view.bottom / p.height),
              child: Stack(
                children: [
                  for (final s in scene.spots) ...[
                    Positioned(
                      left: s.at.dx * p.width - _ring / 2,
                      top: s.at.dy * p.height - _ring / 2,
                      width: _ring,
                      height: _ring,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.goldLight, width: 8),
                            boxShadow: const [BoxShadow(color: Color(0x99000000), blurRadius: 6, spreadRadius: 1)],
                          ),
                          child: looked.contains(s.id)
                              ? const Align(
                                  alignment: Alignment.topRight,
                                  child: CircleAvatar(radius: 24, backgroundColor: AppColors.navyDeep, child: InkIcon(InkGlyph.check, size: 28, color: AppColors.goldLight)),
                                )
                              : null,
                        ),
                      ),
                    ),
                    Positioned(
                      left: s.at.dx * p.width - tap / 2,
                      top: s.at.dy * p.height - tap / 2,
                      width: tap,
                      height: tap,
                      child: Semantics(
                        button: true,
                        label: '${s.name}${looked.contains(s.id) ? ', looked at' : ''}. Tap to look at it closely.',
                        excludeSemantics: true,
                        // A round tap: only inside its circle.
                        child: ClipOval(
                          child: GestureDetector(key: ValueKey('map-spot-${s.id}'), behavior: HitTestBehavior.opaque, onTap: () => _closer(context, s)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A building on the map up close, the letter's drawing under it to
/// compare: THIS IS THE BUILDING returns its id.
class _BuildingCloser extends StatelessWidget {
  const _BuildingCloser({required this.scene, required this.spot});

  final LetterMapScene scene;
  final MapSpot spot;

  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(spot.name.toUpperCase(), key: const ValueKey('building-name'), style: AppText.mark(color: AppColors.goldLight)),
                const SizedBox(height: AppSpace.sm),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.3),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.paper),
                    child: Semantics(
                      image: true,
                      label: '${spot.name} on the map, up close',
                      excludeSemantics: true,
                      child: PicturePart(key: ValueKey('building-close-${spot.id}'), file: scene.mapFile, pixels: scene.mapPixels, crop: scene.closerOf(spot)),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                Text('THE DRAWING IN THE LETTER', style: AppText.mark(color: AppColors.paperLight, size: 13)),
                const SizedBox(height: AppSpace.xs),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.22),
                  child: AspectRatio(aspectRatio: scene.sketchPixels.aspect, child: _Drawing(scene: scene)),
                ),
                const SizedBox(height: AppSpace.lg),
                GameButton(
                  key: const ValueKey('building-choose'),
                  label: scene.chooseLabel,
                  glyph: InkGlyph.check,
                  style: GameButtonStyle.gold,
                  tap: TapRole.primary,
                  onPressed: () => Navigator.of(context).pop(spot.id),
                ),
                const SizedBox(height: AppSpace.xs),
                TextButton(
                  key: const ValueKey('building-done'),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(scene.backLabel, style: AppText.button(size: 15, color: AppColors.goldLight)),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
