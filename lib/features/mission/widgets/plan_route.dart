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
import 'letter_papers.dart' show postType;
import 'mark_compare.dart' show WorkshopNote;
import 'workshop_papers.dart';

/// The plan of the building ([PlanScene]): the porter's note, and the plan
/// with the letter on it. A tap on the stairs, then on the statue, moves the
/// letter there, one step at a time (kept: [onReached]); a tap on a door it
/// can reach takes it to that door, and GO THROUGH DOOR … sends the door to
/// [onSubmit], checked as the puzzle's answer. A place it cannot reach yet
/// says what comes first. No dragging: every move is a tap.
class PlanRoutePuzzle extends StatefulWidget {
  const PlanRoutePuzzle({super.key, required this.scene, required this.mission, required this.reached, required this.onReached, required this.onSubmit});

  final PlanScene scene;
  final Mission mission;

  /// The places the letter has been moved to (saved).
  final Set<PlanStep> reached;
  final ValueChanged<PlanStep> onReached;
  final Future<void> Function(String answer) onSubmit;

  @override
  State<PlanRoutePuzzle> createState() => _PlanRoutePuzzleState();
}

class _PlanRoutePuzzleState extends State<PlanRoutePuzzle> {
  /// Where the letter is now: a place moved to, or a door (kept while the
  /// page is open). Null: the last place reached.
  PlanStep? _at;
  String? _door;
  String? _line;
  bool _checking = false;

  PlanScene get _scene => widget.scene;

  /// The furthest place reached, where the letter stands on coming back.
  PlanStep? get _last => [for (final s in PlanStep.values) if (widget.reached.contains(s)) s].lastOrNull;

  Offset get _token {
    if (_door case final id?) return _scene.doorSpot(id).at;
    if ((_at ?? _last) case final step?) return _scene.steps[step]!.at;
    return _scene.start;
  }

  void _moveTo(PlanStep step) {
    if (!PlanRoute.canReach(step, widget.reached)) {
      setState(() => _line = _scene.stairsFirst);
      return;
    }
    if (!widget.reached.contains(step)) widget.onReached(step);
    setState(() {
      _at = step;
      _door = null;
      _line = null;
    });
  }

  void _toDoor(PlanDoorSpot spot) {
    final door = _scene.route.door(spot.id);
    if (!PlanRoute.canOpen(door, widget.reached)) {
      setState(() => _line = widget.reached.contains(PlanStep.stairs) ? _scene.statueFirst : _scene.stairsFirst);
      return;
    }
    setState(() {
      _door = spot.id;
      _line = null;
    });
  }

  Future<void> _go() async {
    final door = _door;
    if (_checking || door == null) return;
    setState(() => _checking = true);
    try {
      await widget.onSubmit(door);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _scene.pixels;
    final v = _scene.view;
    final view = Rect.fromLTRB(v.left / p.width, v.top / p.height, v.right / p.width, v.bottom / p.height);
    final aspect = v.width / v.height;
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final next = !widget.reached.contains(PlanStep.stairs)
        ? PlanStep.stairs
        : !widget.reached.contains(PlanStep.statue)
        ? PlanStep.statue
        : null;
    final door = _door;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The porter's note, read with the plan.
        WorkshopNote(key: const ValueKey('porter-note'), intro: widget.mission.letterIntro, text: widget.mission.letter),
        const SizedBox(height: AppSpace.md),
        Text(_scene.task, key: const ValueKey('plan-task'), textAlign: TextAlign.center, style: AppText.subtitle()),
        const SizedBox(height: AppSpace.md),
        LayoutBuilder(
          builder: (context, box) {
            // Large enough for a finger on every door, even on a small
            // phone: the page scrolls a little round it there.
            final tallest = (MediaQuery.sizeOf(context).height * 0.8).clamp(480.0, 680.0);
            final width = math.min(box.maxWidth, tallest * aspect);
            return Center(
              child: SizedBox(
                width: width,
                child: DecoratedBox(
                  decoration: BoxDecoration(boxShadow: AppShadow.paperLift, borderRadius: BorderRadius.circular(AppRadius.paper)),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.paper),
                    child: Semantics(
                      label: '${_scene.place}.',
                      child: CroppedPicture(
                        key: const ValueKey('plan'),
                        file: _scene.file,
                        pixels: p,
                        crop: view,
                        child: Stack(
                          children: [
                            // Where to go next: a ring on the stairs, then the statue.
                            if (next != null)
                              _ring(_scene.steps[next]!.area, key: ValueKey('plan-next-${next.name}')),
                            for (final d in _scene.doors) _badge(d, chosen: d.id == door),
                            // The letter.
                            AnimatedPositioned(
                              key: const ValueKey('plan-letter'),
                              duration: still ? Duration.zero : const Duration(milliseconds: 450),
                              curve: Curves.easeInOutCubic,
                              left: _token.dx - 46,
                              top: _token.dy - 46,
                              width: 92,
                              height: 92,
                              child: const IgnorePointer(child: _LetterToken()),
                            ),
                            // The taps, over everything.
                            for (final MapEntry(key: step, value: place) in _scene.steps.entries)
                              Positioned.fromRect(
                                rect: place.area,
                                child: Semantics(
                                  button: true,
                                  label: step == PlanStep.stairs ? 'The stairs' : 'The statue',
                                  excludeSemantics: true,
                                  child: GestureDetector(key: ValueKey('plan-${step.name}'), behavior: HitTestBehavior.opaque, onTap: () => _moveTo(step)),
                                ),
                              ),
                            for (final d in _scene.doors)
                              Positioned.fromRect(
                                rect: d.area,
                                child: Semantics(
                                  button: true,
                                  selected: d.id == door,
                                  label: 'Door ${d.id.toUpperCase()}',
                                  excludeSemantics: true,
                                  child: GestureDetector(key: ValueKey('plan-door-${d.id}'), behavior: HitTestBehavior.opaque, onTap: () => _toDoor(d)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpace.md),
        // What comes first, when the letter cannot go there yet; the same
        // room kept, so nothing jumps.
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 26),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _line == null
                ? const SizedBox.shrink()
                : Text(_line!, key: const ValueKey('plan-line'), textAlign: TextAlign.center, style: AppText.bodyText(size: 17, color: AppColors.inkBrown, weight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: AppSpace.sm),
        GameButton(
          key: const ValueKey('plan-go'),
          label: door == null ? _scene.goLabel : '${_scene.goLabel} ${door.toUpperCase()}',
          glyph: InkGlyph.map,
          tap: TapRole.primary,
          onPressed: door != null && !_checking ? _go : null,
        ),
      ],
    );
  }

  /// A ring round the next place (still: it marks, it does not move).
  Widget _ring(Rect area, {Key? key}) {
    final side = math.min(area.width, area.height) * 0.95;
    return Positioned.fromRect(
      key: key,
      rect: Rect.fromCenter(center: area.center, width: side, height: side),
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.goldDeep, width: 7),
            color: AppColors.creamGold.withValues(alpha: 0.25),
          ),
          child: const Center(child: InkIcon(InkGlyph.footprint, size: 52, color: AppColors.goldDeep)),
        ),
      ),
    );
  }

  /// A door's letter, beside it in its room.
  Widget _badge(PlanDoorSpot d, {required bool chosen}) => Positioned(
    left: d.badge.dx - 36,
    top: d.badge.dy - 36,
    width: 72,
    height: 72,
    child: IgnorePointer(
      child: DecoratedBox(
        key: ValueKey('plan-badge-${d.id}'),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: chosen ? AppColors.gold : AppColors.paperLight,
          border: Border.all(color: AppColors.navy, width: 5),
        ),
        child: Center(child: Text(d.id.toUpperCase(), style: postType(44, color: chosen ? AppColors.walnutDeep : AppColors.navy))),
      ),
    ),
  );
}

class _LetterToken extends StatelessWidget {
  const _LetterToken();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: AppColors.navyDeep,
      border: Border.all(color: AppColors.goldLight, width: 6),
      boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 10, offset: Offset(0, 4))],
    ),
    child: const Center(child: InkIcon(InkGlyph.letter, size: 50, color: AppColors.goldLight)),
  );
}
