import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/audio_service.dart' show TapRole;
import '../../../data/models/mission.dart';
import '../../../data/models/workshop_puzzles.dart';
import '../../../widgets/game_button.dart';
import '../../../widgets/ink_icon.dart';
import 'workshop_papers.dart';

/// The final's slips ([PostTrailScene]): the receipt to start from, the five
/// slips from under the door (a tap picks one, shown large under them), and
/// the trail's three places (a tap sets the slip picked there, or takes a
/// slip off). FOLLOW THE LETTER sends the trail to [onSubmit].
class PostTrailPuzzle extends StatelessWidget {
  const PostTrailPuzzle({
    super.key,
    required this.scene,
    required this.mission,
    required this.placed,
    required this.picked,
    required this.checking,
    required this.onPick,
    required this.onSlot,
    required this.onSubmit,
  });

  final PostTrailScene scene;
  final Mission mission;

  /// Slot → slip.
  final Map<String, String> placed;
  final String? picked;
  final bool checking;
  final ValueChanged<String> onPick;
  final ValueChanged<String> onSlot;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final picked = this.picked;
    final full = scene.slots.every(placed.containsKey);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Where the trail starts: the receipt from Clock III.
        Row(
          children: [
            SizedBox(width: 110, child: WrittenPaperView(paper: scene.receipt)),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Text(
                scene.receipt.lines.join('\n'),
                key: const ValueKey('trail-receipt'),
                style: AppText.bodyText(size: 15, weight: FontWeight.w600).copyWith(height: 1.35),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        Text(picked == null ? scene.pickTask : scene.placeTask, key: const ValueKey('trail-task'), textAlign: TextAlign.center, style: AppText.subtitle()),
        const SizedBox(height: AppSpace.sm),
        LayoutBuilder(
          builder: (context, box) => Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              for (final s in scene.slips)
                SizedBox(
                  width: (box.maxWidth - AppSpace.sm) / 2,
                  child: _SlipCard(
                    key: ValueKey('slip-${s.id}'),
                    scene: scene,
                    slip: s,
                    picked: picked == s.id,
                    placedAt: [for (final e in placed.entries) if (e.value == s.id) scene.slotLabels[scene.slots.indexOf(e.key)]].firstOrNull,
                    onTap: () => onPick(s.id),
                  ),
                ),
            ],
          ),
        ),
        // The slip picked, large enough to read every line.
        if (picked != null) ...[
          const SizedBox(height: AppSpace.md),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: WrittenPaperView(key: const ValueKey('slip-large'), paper: scene.paperOf(scene.slipOf(picked))),
            ),
          ),
        ],
        const SizedBox(height: AppSpace.md),
        Text('THE LETTER\'S TRAIL', textAlign: TextAlign.center, style: AppText.eyebrow()),
        const SizedBox(height: AppSpace.sm),
        for (final (i, slot) in scene.slots.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.sm),
            child: _Slot(
              key: ValueKey('trail-slot-$slot'),
              label: scene.slotLabels[i],
              slip: placed[slot] == null ? null : scene.slipOf(placed[slot]!),
              ready: picked != null,
              onTap: () => onSlot(slot),
            ),
          ),
        const SizedBox(height: AppSpace.sm),
        GameButton(
          key: const ValueKey('trail-submit'),
          label: scene.submitLabel,
          glyph: InkGlyph.map,
          tap: TapRole.primary,
          onPressed: full && !checking ? onSubmit : null,
        ),
      ],
    );
  }
}

/// A slip from under the door, small: its letter number and record read
/// at a glance; picked, it is ringed; set on the trail, it says where.
class _SlipCard extends StatelessWidget {
  const _SlipCard({super.key, required this.scene, required this.slip, required this.picked, required this.placedAt, required this.onTap});

  final PostTrailScene scene;
  final PostSlip slip;
  final bool picked;
  final String? placedAt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: picked,
    label: '${slip.lines.join(', ')}${placedAt == null ? '' : '. On the trail: $placedAt'}',
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: placedAt != null && !picked ? 0.55 : 1,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: picked ? AppColors.navy : Colors.transparent, width: 2.5),
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          child: Stack(
            children: [
              WrittenPaperView(paper: scene.cardOf(slip)),
              if (placedAt != null)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.navyDeep, borderRadius: BorderRadius.circular(3)),
                    child: Text(placedAt!, style: AppText.style(AppText.body, size: 12, weight: FontWeight.w800, color: AppColors.goldLight)),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// A place on the trail: its order, and the slip set there.
class _Slot extends StatelessWidget {
  const _Slot({super.key, required this.label, required this.slip, required this.ready, required this.onTap});

  final String label;
  final PostSlip? slip;
  final bool ready;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final slip = this.slip;
    return Semantics(
      button: true,
      label: '$label on the trail: ${slip == null ? 'empty' : slip.lines.join(', ')}',
      excludeSemantics: true,
      child: Material(
        color: slip == null ? AppColors.paper : AppColors.paperLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          side: BorderSide(color: ready ? AppColors.navy : AppLine.faint(0.35), width: ready ? 2 : AppLine.hairline),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.button),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
              child: Row(
                children: [
                  SizedBox(width: 44, child: Text(label, style: AppText.mark(color: AppColors.navy, size: 17))),
                  Expanded(
                    child: slip == null
                        ? Text(ready ? 'Tap to put the slip here' : 'Empty', style: AppText.aside(size: 15))
                        : Text(
                            '${slip.time == null ? slip.date : '${slip.date} · ${slip.time}'}\n${slip.record} · ${slip.where}',
                            style: AppText.bodyText(size: 15, weight: FontWeight.w600).copyWith(height: 1.3),
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

/// The final's stage: the workshop door, the slips under it; with the
/// solve, the slip that says where the letter stopped is laid over it.
class TrailStage extends StatelessWidget {
  const TrailStage({super.key, required this.scene, required this.open});

  final PostTrailScene scene;
  final Animation<double> open;

  @override
  Widget build(BuildContext context) {
    final held = scene.slips.firstWhere((s) => s.record == 'HELD');
    return Semantics(
      image: true,
      label: scene.stageLabel,
      excludeSemantics: true,
      child: Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: scene.stageView.width * scene.stagePixels.width,
              height: scene.stageView.height * scene.stagePixels.height,
              child: CroppedPicture(file: scene.stage, pixels: scene.stagePixels, crop: scene.stageView),
            ),
          ),
          AnimatedBuilder(
            animation: open,
            builder: (context, child) {
              final t = ((open.value - 0.2) / 0.5).clamp(0.0, 1.0);
              return t == 0 ? const SizedBox.shrink() : Opacity(opacity: t, child: Transform.translate(offset: Offset(0, 30 * (1 - t)), child: child));
            },
            child: Center(
              child: FractionallySizedBox(
                widthFactor: 0.8,
                child: WrittenPaperView(key: const ValueKey('trail-held'), paper: scene.paperOf(held)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
