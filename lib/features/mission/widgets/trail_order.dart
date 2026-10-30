import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/models/mission.dart';
import '../../../data/models/scene_trail.dart';
import '../../../widgets/game_button.dart';
import '../../../widgets/ink_icon.dart';
import 'question_widgets.dart' show AnswerCallback;

/// A sequence puzzle played on its place ([TrailScene]): the traces are
/// tapped in the picture in the order the letter gives, each numbered as it
/// is picked; a numbered one tapped again takes it (and every step after
/// it) back. CHECK ANSWER sends the order as the puzzle's answer.
///
/// The order is kept by the page ([order], [onChanged]), so going back to
/// the letter and returning finds the steps where they were. Tapping is
/// quiet: only the answer has a sound.
class TrailOrderQuestion extends StatelessWidget {
  const TrailOrderQuestion({
    super.key,
    required this.mission,
    required this.scene,
    required this.order,
    required this.onChanged,
    required this.onSubmit,
  });

  final Mission mission;
  final TrailScene scene;
  final List<String> order;
  final ValueChanged<List<String>> onChanged;
  final AnswerCallback onSubmit;

  /// How far outside a stop a tap still picks it (fractions of the picture):
  /// a fingertip at the smallest phone.
  static const slack = Size(0.04, 0.05);

  String _label(String optionId) => mission.options.firstWhere((o) => o.id == optionId).label;

  void _tap(TrailStop stop) {
    HapticFeedback.selectionClick();
    final at = order.indexOf(stop.optionId);
    onChanged(at < 0 ? [...order, stop.optionId] : order.sublist(0, at));
  }

  @override
  Widget build(BuildContext context) {
    final inside = scene.inside;
    final aspect = inside.width * scene.pixels.width / (inside.height * scene.pixels.height);
    final done = order.length == scene.stops.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(scene.lead, textAlign: TextAlign.center, style: AppText.bodyText(size: 16, color: AppColors.inkBrown)),
        const SizedBox(height: AppSpace.md),
        DecoratedBox(
          decoration: const BoxDecoration(boxShadow: AppShadow.paperLift),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.paper),
            child: AspectRatio(
              key: const ValueKey('trail-picture'),
              aspectRatio: aspect,
              child: LayoutBuilder(
                builder: (context, box) {
                  final w = box.maxWidth / inside.width;
                  final h = box.maxHeight / inside.height;
                  Offset onScreen(Offset p) => Offset((p.dx - inside.left) * w, (p.dy - inside.top) * h);
                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (d) {
                      final p = Offset(inside.left + d.localPosition.dx / w, inside.top + d.localPosition.dy / h);
                      if (scene.hit(p, slack: slack) case final stop?) _tap(stop);
                    },
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        Positioned(
                          left: -inside.left * w,
                          top: -inside.top * h,
                          width: w,
                          height: h,
                          child: Semantics(
                            label: scene.place,
                            image: true,
                            child: Image.asset(scene.picture, fit: BoxFit.fill, excludeFromSemantics: true),
                          ),
                        ),
                        for (final stop in scene.stops)
                          _StopMark(
                            key: ValueKey('trail-${stop.optionId}'),
                            centre: onScreen(stop.mark),
                            step: order.indexOf(stop.optionId) + 1,
                            label: _label(stop.optionId),
                            onTap: () => _tap(stop),
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        Text(scene.guide, textAlign: TextAlign.center, style: AppText.caption(color: AppColors.inkBrown)),
        const SizedBox(height: AppSpace.md),
        // The order so far, in words: the place names are the English read.
        Semantics(
          liveRegion: true,
          child: Wrap(
            key: const ValueKey('trail-order'),
            alignment: WrapAlignment.center,
            spacing: AppSpace.sm,
            runSpacing: AppSpace.xs,
            children: [
              for (final (i, id) in order.indexed)
                Text('${i + 1}. ${_label(id)}', style: AppText.style(AppText.body, size: 15, weight: FontWeight.w700, color: AppColors.navy)),
            ],
          ),
        ),
        if (order.isNotEmpty)
          Center(
            child: InkTextButton(
              key: const ValueKey('trail-clear'),
              label: 'Start again',
              glyph: InkGlyph.back,
              onPressed: () => onChanged(const []),
            ),
          ),
        const SizedBox(height: AppSpace.md),
        GameButton(
          key: const ValueKey('trail-check'),
          label: 'CHECK ANSWER',
          onPressed: done ? () => onSubmit(order.join(',')) : null,
        ),
      ],
    );
  }
}

/// A stop's mark on the trace: a soft gold ring while it is still to pick,
/// its step number in navy once picked. The ring is a fingertip wide.
class _StopMark extends StatelessWidget {
  const _StopMark({super.key, required this.centre, required this.step, required this.label, required this.onTap});

  final Offset centre;

  /// 1.. once picked; 0 not yet.
  final int step;
  final String label;
  final VoidCallback onTap;

  static const size = 44.0;

  @override
  Widget build(BuildContext context) {
    final picked = step > 0;
    return Positioned(
      left: centre.dx - size / 2,
      top: centre.dy - size / 2,
      width: size,
      height: size,
      child: Semantics(
        button: true,
        label: 'Footprint by ${label.replaceFirst(RegExp('^The ', caseSensitive: false), 'the ')}',
        value: picked ? 'step $step' : null,
        excludeSemantics: true,
        onTap: onTap,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: picked ? 30 : 34,
              height: picked ? 30 : 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: picked ? AppColors.navy : AppColors.goldLight.withValues(alpha: 0.18),
                border: Border.all(color: picked ? AppColors.goldLight : AppColors.goldLight.withValues(alpha: 0.9), width: AppLine.rule),
              ),
              child: picked
                  ? MediaQuery.withNoTextScaling(
                      child: Text('$step', style: AppText.title(size: 16, color: AppColors.goldLight)),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}
