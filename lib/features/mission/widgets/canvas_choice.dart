import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/audio_service.dart' show TapRole;
import '../../../data/models/mission.dart';
import '../../../data/models/painter_puzzles.dart';
import '../../../widgets/evidence_card.dart' show EvidenceLinkRow;
import '../../../widgets/game_button.dart';
import '../../../widgets/glossary_text.dart';
import '../../../widgets/ink_icon.dart';
import 'studio_match.dart' show PictureCloser;
import 'tower_documents.dart' show CroppedPicture;

/// The final's stage over a [CanvasScene]: the canvas being looked at, whole
/// (a tap looks closer). Once the right one is chosen, [turn] (0..1) turns
/// it round: it swings edge-on, and its back (a picture of its own, never
/// assumed to be the same shape) swings in, the message written on it.
class CanvasStage extends StatelessWidget {
  const CanvasStage({super.key, required this.scene, required this.looking, required this.turn, required this.turned, this.onCloser});

  final CanvasScene scene;
  final String looking;
  final Animation<double> turn;

  /// Shown turned round (the case is solved).
  final bool turned;
  final VoidCallback? onCloser;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final c = scene.canvas(looking);
    return AnimatedBuilder(
      animation: turn,
      builder: (context, _) {
        // Edge-on at a quarter of the way; the back in from there.
        final t = !turned ? 0.0 : (still ? 1.0 : (turn.value / 0.45).clamp(0.0, 1.0));
        final back = t >= 0.5;
        final angle = back ? (1 - t) * math.pi : t * math.pi;
        final face = back
            ? CanvasBack(key: const ValueKey('canvas-back'), scene: scene, writing: still ? 1 : ((turn.value - 0.45) / 0.3).clamp(0.0, 1.0))
            : Semantics(
                button: onCloser != null,
                label: '${c.name}. Tap to look closer.',
                excludeSemantics: true,
                onTap: onCloser,
                child: GestureDetector(
                  onTap: onCloser,
                  // The painting itself (not its easel nor the studio).
                  child: CroppedPicture(key: ValueKey('canvas-front-${c.id}'), file: c.file, pixels: scene.pixels, crop: scene.paint),
                ),
              );
        return Center(
          child: AspectRatio(
            aspectRatio: scene.paintAspect,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateY(angle),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.paper),
                  boxShadow: AppShadow.onNight,
                ),
                child: ClipRRect(borderRadius: BorderRadius.circular(AppRadius.paper), child: face),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The back of the canvas: its own picture, the message written in ink on
/// its bare panel ([writing]: how much of it is in, 0..1).
class CanvasBack extends StatelessWidget {
  const CanvasBack({super.key, required this.scene, this.writing = 1});

  final CanvasScene scene;
  final double writing;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: '${scene.backLabel}. Written on it: ${scene.message.replaceAll('\n', ' ')}',
      excludeSemantics: true,
      child: AspectRatio(
        aspectRatio: scene.backPixels.aspect,
        child: LayoutBuilder(
          builder: (context, box) {
            final r = scene.writeOn;
            return Stack(
              children: [
                Positioned.fill(child: Image.asset(scene.back, fit: BoxFit.fill, excludeFromSemantics: true)),
                Positioned(
                  left: r.left * box.maxWidth,
                  top: r.top * box.maxHeight,
                  width: r.width * box.maxWidth,
                  height: r.height * box.maxHeight,
                  child: Opacity(
                    opacity: writing,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        scene.message,
                        key: const ValueKey('canvas-message'),
                        textAlign: TextAlign.center,
                        style: AppText.letter(size: 34, color: AppColors.ink).copyWith(height: 1.25),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Under the stage: the four canvases to look at (the one on the stage
/// framed in navy, a tick on each looked at), and TURN IT AROUND for the
/// one on the stage once every canvas has been looked at.
class CanvasPicker extends StatelessWidget {
  const CanvasPicker({
    super.key,
    required this.scene,
    required this.mission,
    required this.looking,
    required this.looked,
    required this.checking,
    required this.onLook,
    required this.onTurn,
  });

  final CanvasScene scene;
  final Mission mission;
  final String looking;
  final Set<String> looked;
  final bool checking;
  final ValueChanged<String> onLook;
  final VoidCallback onTurn;

  @override
  Widget build(BuildContext context) {
    final all = scene.canvases.every((c) => looked.contains(c.id));
    final name = scene.canvas(looking).name;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(scene.chooseHow, textAlign: TextAlign.center, style: AppText.caption(color: AppColors.paperLight.withValues(alpha: 0.85))),
        const SizedBox(height: AppSpace.md),
        LayoutBuilder(
          builder: (context, box) {
            const gap = AppSpace.sm;
            final n = scene.canvases.length;
            final tile = (box.maxWidth - gap * (n - 1)) / n;
            return Row(
              children: [
                for (final (i, c) in scene.canvases.indexed) ...[
                  if (i > 0) const SizedBox(width: gap),
                  SizedBox(
                    width: tile,
                    child: _CanvasTile(
                      key: ValueKey('canvas-${c.id}'),
                      canvas: c,
                      label: mission.options.firstWhere((o) => o.id == c.id).label,
                      on: c.id == looking,
                      looked: looked.contains(c.id),
                      scene: scene,
                      onTap: () => onLook(c.id),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: AppSpace.md),
        if (!all)
          Text(
            'Look at all four canvases first (${looked.length} of ${scene.canvases.length}).',
            key: const ValueKey('canvas-look-first'),
            textAlign: TextAlign.center,
            style: AppText.aside(size: 15, color: AppColors.goldLight),
          ),
        if (!all) const SizedBox(height: AppSpace.sm),
        GameButton(
          key: const ValueKey('canvas-turn'),
          label: 'TURN $name AROUND',
          tap: TapRole.primary,
          style: GameButtonStyle.gold,
          onPressed: all && !checking ? onTurn : null,
        ),
      ],
    );
  }
}

class _CanvasTile extends StatelessWidget {
  const _CanvasTile({
    super.key,
    required this.canvas,
    required this.label,
    required this.on,
    required this.looked,
    required this.scene,
    required this.onTap,
  });

  final ChoiceCanvas canvas;
  final String label;
  final bool on;
  final bool looked;
  final CanvasScene scene;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: on,
      label: '${canvas.name}: $label.${looked ? ' Looked at.' : ''}',
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: on ? AppColors.goldLight : AppColors.navyDeep.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppRadius.paper),
              border: Border.all(color: on ? AppColors.gold : AppColors.paperLight.withValues(alpha: 0.3), width: on ? AppLine.ink : AppLine.hairline),
            ),
            child: Column(
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: CroppedPicture(file: canvas.file, pixels: scene.pixels, crop: scene.paint),
                    ),
                    if (looked)
                      const Positioned(
                        right: 2,
                        top: 2,
                        child: CircleAvatar(
                          radius: 9,
                          backgroundColor: AppColors.gold,
                          child: InkIcon(InkGlyph.check, size: 10, color: AppColors.navyDeep),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    canvas.name.split(' ').last,
                    style: AppText.mark(color: on ? AppColors.navyDeep : AppColors.goldLight, size: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A canvas over the page, whole, to pinch closer.
Future<void> showCanvasCloser(BuildContext context, CanvasScene scene, String id, String label) {
  final c = scene.canvas(id);
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: AppColors.navyDeep.withValues(alpha: 0.92),
      pageBuilder: (context, anim, _) => FadeTransition(
        opacity: anim,
        child: PictureCloser(file: c.file, aspect: scene.paintAspect, label: '${c.name}: $label', pixels: scene.pixels, crop: scene.paint),
      ),
    ),
  );
}

/// The back of the right canvas, read up close: the message, and the
/// evidence it matches ([evidence]'s link).
Future<void> showCanvasBack(BuildContext context, {required CanvasScene scene, required Evidence? evidence}) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: AppColors.navyDeep.withValues(alpha: 0.92),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, anim, _) => FadeTransition(
        opacity: anim,
        child: Material(
          type: MaterialType.transparency,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpace.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('ON THE BACK', style: AppText.mark(color: AppColors.goldLight)),
                      const SizedBox(height: AppSpace.lg),
                      ClipRect(child: InteractiveViewer(maxScale: 4, child: CanvasBack(key: const ValueKey('canvas-back-close'), scene: scene))),
                      const SizedBox(height: AppSpace.md),
                      GlossaryText(
                        'Written in the same hand as FIND THE PAINTER.',
                        textAlign: TextAlign.center,
                        linkColor: AppColors.goldLight,
                        style: AppText.aside(size: 17, color: AppColors.paperLight),
                      ),
                      if (evidence != null) EvidenceLinkRow(evidenceId: evidence.id, dark: true),
                      const SizedBox(height: AppSpace.xl),
                      Builder(
                        builder: (context) => GameButton(
                          key: const ValueKey('canvas-back-done'),
                          label: 'BACK TO THE STUDIO',
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
}
