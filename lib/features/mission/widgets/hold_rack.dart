import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/audio_service.dart' show TapRole;
import '../../../data/models/letter_puzzles.dart';
import '../../../data/models/mission.dart';
import '../../../data/models/workshop_puzzles.dart' show WrittenPaper;
import '../../../widgets/game_button.dart';
import '../../../widgets/glossary_text.dart';
import '../../../widgets/ink_icon.dart';
import 'letter_papers.dart';
import 'workshop_papers.dart';

/// The hold rack ([HoldRackScene]): the Letter's Trail to compare with, and
/// the rack with its four tags, lettered on their paper; a tap on a tag
/// looks at it up close, where it is turned over (kept turned: [onTurned])
/// and chosen. The tag chosen goes to [onSubmit], checked as the puzzle's
/// answer.
class HoldRackPuzzle extends StatelessWidget {
  const HoldRackPuzzle({super.key, required this.scene, required this.mission, required this.turned, required this.onTurned, required this.onSubmit});

  final HoldRackScene scene;
  final Mission mission;

  /// The tags turned over so far, by id.
  final Set<String> turned;
  final ValueChanged<String> onTurned;
  final Future<void> Function(String answer) onSubmit;

  Future<void> _look(BuildContext context, RackTag spot) async {
    final chosen = await showHoldTag(context, scene: scene, mission: mission, tag: scene.rack.tag(spot.id), onTurned: onTurned);
    if (chosen != null) await onSubmit(chosen);
  }

  @override
  Widget build(BuildContext context) {
    final p = scene.pixels;
    final view = Rect.fromLTRB(scene.view.left / p.width, scene.view.top / p.height, scene.view.right / p.width, scene.view.bottom / p.height);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The Letter's Trail (Case 05's slip): what the tag must say.
        TrailClue(key: const ValueKey('rack-clue'), slip: scene.trail, intro: mission.letterIntro, text: mission.letter),
        const SizedBox(height: AppSpace.md),
        Text(scene.lookTask, key: const ValueKey('rack-task'), textAlign: TextAlign.center, style: AppText.subtitle()),
        const SizedBox(height: AppSpace.md),
        DecoratedBox(
          decoration: BoxDecoration(boxShadow: AppShadow.paperLift, borderRadius: BorderRadius.circular(AppRadius.paper)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.paper),
            child: Semantics(
              label: '${scene.place}.',
              child: CroppedPicture(
                key: const ValueKey('rack'),
                file: scene.file,
                pixels: p,
                crop: view,
                child: Stack(
                  children: [
                    for (final t in scene.tags) ...[
                      // The tag's letter, written on its paper.
                      Positioned.fromRect(
                        rect: t.paper.deflate(6).translate(0, 12),
                        child: IgnorePointer(
                          child: Center(
                            child: Text(t.id.toUpperCase(), style: postType(48, color: AppColors.walnutDeep)),
                          ),
                        ),
                      ),
                      Positioned.fromRect(
                        rect: t.spot,
                        child: Semantics(
                          button: true,
                          label: 'Tag ${t.id.toUpperCase()}${turned.contains(t.id) ? ', turned over before' : ''}. Tap to look at it closely.',
                          excludeSemantics: true,
                          child: GestureDetector(
                            key: ValueKey('rack-tag-${t.id}'),
                            behavior: HitTestBehavior.opaque,
                            onTap: () => _look(context, t),
                            child: turned.contains(t.id)
                                ? Align(
                                    alignment: Alignment.topRight,
                                    child: CircleAvatar(
                                      radius: 26,
                                      backgroundColor: AppColors.navyDeep.withValues(alpha: 0.85),
                                      child: const InkIcon(InkGlyph.check, size: 30, color: AppColors.goldLight),
                                    ),
                                  )
                                : const SizedBox.expand(),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The Letter's Trail as it is in the notebook: Case 05's slip, small,
/// beside its words.
class TrailClue extends StatelessWidget {
  const TrailClue({super.key, required this.slip, required this.intro, required this.text});

  final WrittenPaper slip;
  final String intro;
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpace.sm),
    decoration: BoxDecoration(
      color: AppColors.paperLight,
      border: Border.all(color: AppLine.faint(0.25), width: AppLine.hairline),
      borderRadius: BorderRadius.circular(AppRadius.paper),
    ),
    child: Row(
      children: [
        SizedBox(width: 84, child: ExcludeSemantics(child: WrittenPaperView(paper: slip))),
        const SizedBox(width: AppSpace.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(intro, style: AppText.caption()),
              const SizedBox(height: AppSpace.xs),
              GlossaryText(text, style: AppText.bodyText(size: 16, weight: FontWeight.w700).copyWith(height: 1.3)),
            ],
          ),
        ),
      ],
    ),
  );
}

/// A tag up close, over the post room: TURN IT OVER shows its back (the
/// first time, it counts as turned: [onTurned]); THIS IS THE TAG returns
/// its id. With Reduce Motion it turns at once.
Future<String?> showHoldTag(
  BuildContext context, {
  required HoldRackScene scene,
  required Mission mission,
  required HoldTag tag,
  required ValueChanged<String> onTurned,
}) {
  return Navigator.of(context).push<String>(
    PageRouteBuilder<String>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: AppColors.navyDeep.withValues(alpha: 0.94),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim, _) => FadeTransition(
        opacity: anim,
        child: _TagCloser(scene: scene, mission: mission, tag: tag, onTurned: onTurned),
      ),
    ),
  );
}

class _TagCloser extends StatefulWidget {
  const _TagCloser({required this.scene, required this.mission, required this.tag, required this.onTurned});

  final HoldRackScene scene;
  final Mission mission;
  final HoldTag tag;
  final ValueChanged<String> onTurned;

  @override
  State<_TagCloser> createState() => _TagCloserState();
}

class _TagCloserState extends State<_TagCloser> with SingleTickerProviderStateMixin {
  late final AnimationController _turn = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
  bool _back = false;

  void _turnOver() {
    final back = !_back;
    setState(() => _back = back);
    if (back) widget.onTurned(widget.tag.id);
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still) {
      _turn.value = back ? 1 : 0;
    } else {
      back ? _turn.forward() : _turn.reverse();
    }
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tag = widget.tag;
    final scene = widget.scene;
    return Material(
      type: MaterialType.transparency,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // The clue, kept in view while the tag is read.
                  Text('YOUR CLUE', style: AppText.eyebrow(color: AppColors.goldLight)),
                  const SizedBox(height: AppSpace.xs),
                  Text(
                    widget.mission.letter.replaceAll('\n', '  ·  '),
                    key: const ValueKey('tag-clue'),
                    textAlign: TextAlign.center,
                    style: AppText.bodyText(size: 15, color: AppColors.paperLight, weight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSpace.md),
                  Text(tag.name, key: const ValueKey('tag-title'), style: AppText.mark(color: AppColors.goldLight)),
                  const SizedBox(height: AppSpace.sm),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.48),
                    child: AspectRatio(
                      aspectRatio: scene.tagPixels.aspect,
                      child: GestureDetector(
                        key: ValueKey('tag-close-${tag.id}'),
                        onTap: _turnOver,
                        child: AnimatedBuilder(
                          animation: _turn,
                          builder: (context, _) {
                            // Round its string: the front until halfway, then the back.
                            final a = _turn.value * math.pi;
                            final back = _turn.value > 0.5;
                            return Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()
                                ..setEntry(3, 2, 0.0012)
                                ..rotateY(back ? a - math.pi : a),
                              child: HoldTagView(key: ValueKey('tag-${back ? 'back' : 'front'}-view'), scene: scene, tag: tag, back: back),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Text(_back ? 'THE BACK' : 'THE FRONT', style: AppText.eyebrow(color: AppColors.goldLight)),
                  const SizedBox(height: AppSpace.md),
                  GameButton(
                    key: const ValueKey('tag-turn'),
                    label: _back ? scene.turnBackLabel : scene.turnLabel,
                    glyph: InkGlyph.puzzle,
                    style: GameButtonStyle.glass,
                    onPressed: _turnOver,
                  ),
                  const SizedBox(height: AppSpace.sm),
                  GameButton(
                    key: const ValueKey('tag-choose'),
                    label: scene.chooseLabel,
                    glyph: InkGlyph.check,
                    style: GameButtonStyle.gold,
                    tap: TapRole.primary,
                    onPressed: () => Navigator.of(context).pop(tag.id),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  InkTextButton(
                    key: const ValueKey('tag-done'),
                    label: 'BACK TO THE RACK',
                    color: AppColors.goldLight,
                    onPressed: () => Navigator.of(context).pop(),
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
