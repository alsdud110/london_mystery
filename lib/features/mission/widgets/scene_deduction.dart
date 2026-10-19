import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/models/investigation.dart' show InvestigationSpot;
import '../../../data/models/mission.dart';
import '../../../data/models/scene_deduction.dart';
import '../../../widgets/detective_tips.dart';
import '../../../widgets/game_button.dart';
import '../../../widgets/glossary_text.dart';
import '../../../widgets/ink_icon.dart';
import '../../../widgets/paper_background.dart';
import 'investigation_search.dart' show PencilSlip, SearchTapRing, TapGuide;
import 'question_widgets.dart' show ShakeOnChange;
import 'scene_explore.dart' show LookMark;

/// A place read for its traces ([DeductionScene]): its picture fills the
/// screen and can be looked at closer (pinch, drag). Each trace carries a
/// small glass; tapped, it is written in the detective's notes under the
/// picture (a tick on the glass). Once every trace is noted, the places the
/// box could be are marked, and the detective chooses one, in the picture,
/// and searches it: [onChoose] checks it as the puzzle's answer. Noting a
/// trace, or tapping anywhere else, is never a wrong answer.
///
/// What was noted lives in [progress], kept by the page that shows it
/// ([onChanged] after each change), so going back keeps it. Not saved.
class SceneDeduction extends StatefulWidget {
  const SceneDeduction({
    super.key,
    required this.scene,
    required this.mission,
    required this.progress,
    required this.onChanged,
    required this.onChoose,
    required this.hintsShown,
    required this.onHint,
    required this.wrongPulse,
  });

  final DeductionScene scene;
  final Mission mission;
  final DeductionProgress progress;
  final VoidCallback onChanged;

  /// Checks the place chosen (an option id) as the puzzle's answer.
  final void Function(String optionId) onChoose;

  final int hintsShown;
  final VoidCallback onHint;

  /// Bumped by the page on a wrong answer: the picture shakes.
  final int wrongPulse;

  @override
  State<SceneDeduction> createState() => _SceneDeductionState();
}

class _SceneDeductionState extends State<SceneDeduction> {
  /// The pencilled slip over the picture: what the last tap found.
  String? _line;

  /// Where the last tap landed (fractions of the picture), and a count so
  /// each tap rings anew.
  Offset? _tapAt;
  int _tapCount = 0;

  final _zoom = TransformationController();
  Size? _homeViewport;
  bool _homeShown = false;
  bool _moved = false;

  /// How far outside a place a tap still counts for it, in logical pixels.
  static const slack = 14.0;
  static const maxScale = 3.0;

  DeductionProgress get _p => widget.progress;
  DeductionScene get _scene => widget.scene;
  bool get _choosing => _p.allNoted(_scene);

  @override
  void dispose() {
    _zoom.dispose();
    super.dispose();
  }

  void _guideDone() {
    if (_p.guideShown) return;
    _p.guideShown = true;
    widget.onChanged();
  }

  void _tap(Offset point, Size shown) {
    _guideDone();
    setState(() {
      _tapAt = point;
      _tapCount++;
    });
    final reach = Size(slack / shown.width, slack / shown.height);
    _choosing ? _choose(_scene.hitPlace(point, slack: reach)) : _look(_scene.hitClue(point, slack: reach));
  }

  /// A trace, a place holding nothing, or nothing, while traces are looked for.
  void _look(Object? target) {
    switch (target) {
      case DeductionClue c:
        if (!_p.hasNoted(c.id)) {
          HapticFeedback.selectionClick();
          _p.noted.add(c.id);
        }
        _line = c.line;
        widget.onChanged();
      case InvestigationSpot o:
        setState(() => _line = o.line);
      default:
        setState(() => _line = _scene.missLine);
    }
  }

  /// A place the box could be (chosen), or none, once choosing.
  void _choose(DeductionPlace? place) {
    if (place == null) {
      setState(() => _line = _scene.notPlaceLine);
      return;
    }
    HapticFeedback.selectionClick();
    _p.chosen = place.optionId;
    _line = null;
    widget.onChanged();
  }

  String _labelOf(String optionId) => widget.mission.options.firstWhere((o) => o.id == optionId).label;

  /// The opening view: the scene's [DeductionScene.opening] filling as much
  /// of the [viewport] as it can, never smaller than the whole picture
  /// ([size] at [origin]).
  Matrix4 _homeFor(Size viewport, Size size, Offset origin) {
    final o = _scene.opening;
    final s = math
        .min(viewport.width / (size.width * o.width), viewport.height / (size.height * o.height))
        .clamp(1.0, maxScale);
    final centre = origin + Offset(o.center.dx * size.width, o.center.dy * size.height);
    final onScreen = viewport.center(Offset.zero);
    final dx = (onScreen.dx - s * centre.dx).clamp(-(s - 1) * viewport.width, 0.0);
    final dy = (onScreen.dy - s * centre.dy).clamp(-(s - 1) * viewport.height, 0.0);
    return Matrix4.identity()
      ..translateByDouble(dx, dy, 0, 1)
      ..scaleByDouble(s, s, 1, 1);
  }

  @override
  Widget build(BuildContext context) {
    final scene = _scene;
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final chosen = _p.chosen;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ClipRect(
            child: LayoutBuilder(
              builder: (context, box) {
                final viewport = box.biggest;
                final aspect = scene.pixels.aspect;
                var w = viewport.width;
                var h = w / aspect;
                if (h > viewport.height) {
                  h = viewport.height;
                  w = h * aspect;
                }
                final origin = Offset((viewport.width - w) / 2, (viewport.height - h) / 2);
                if (!_moved && _homeViewport != viewport) {
                  _homeViewport = viewport;
                  final home = _homeFor(viewport, Size(w, h), origin);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted || _moved) return;
                    _zoom.value = home;
                    setState(() => _homeShown = true);
                  });
                }
                return Stack(
                  children: [
                    // The place itself, dim, all around the picture.
                    Positioned.fill(
                      child: ExcludeSemantics(
                        child: Opacity(opacity: 0.35, child: Image.asset(scene.picture, fit: BoxFit.cover)),
                      ),
                    ),
                    Positioned.fill(child: ColoredBox(color: AppColors.navyDeep.withValues(alpha: 0.55))),
                    Opacity(
                      opacity: _homeShown ? 1 : 0,
                      child: ShakeOnChange(
                        trigger: widget.wrongPulse,
                        child: InteractiveViewer(
                          transformationController: _zoom,
                          minScale: 1,
                          maxScale: maxScale,
                          boundaryMargin: EdgeInsets.zero,
                          onInteractionStart: (_) {
                            _moved = true;
                            _guideDone();
                          },
                          child: SizedBox.fromSize(
                            size: viewport,
                            child: Stack(
                              children: [
                                Positioned(
                                  left: origin.dx,
                                  top: origin.dy,
                                  width: w,
                                  height: h,
                                  child: _DeductionPicture(
                                    key: const ValueKey('deduction-picture'),
                                    scene: scene,
                                    progress: _p,
                                    choosing: _choosing,
                                    labelOf: _labelOf,
                                    tapAt: _tapAt,
                                    tapCount: _tapCount,
                                    guide: !_p.guideShown && !still,
                                    onGuideEnd: _guideDone,
                                    onTap: (point) {
                                      final s = _zoom.value.getMaxScaleOnAxis();
                                      _tap(point, Size(w * s, h * s));
                                    },
                                    onClue: _look,
                                    onPlace: _choose,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: AppSpace.md,
                      right: AppSpace.md,
                      top: AppSpace.sm,
                      child: IgnorePointer(child: PencilSlip(line: _line)),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        _DeductionPanel(
          scene: scene,
          progress: _p,
          choosing: _choosing,
          chosenLabel: chosen == null ? null : _labelOf(chosen),
          hints: widget.mission.hints,
          hintsShown: widget.hintsShown,
          onTip: widget.onHint,
          onSearch: chosen == null ? null : () => widget.onChoose(chosen),
        ),
      ],
    );
  }
}

/// The picture read for its traces: a small glass on each trace (a tick
/// once noted); once choosing, a marker on each place the box could be,
/// the chosen one ringed. An invisible button on each for screen readers.
/// Its taps are in fractions of the picture, wherever it is enlarged or
/// moved to.
class _DeductionPicture extends StatelessWidget {
  const _DeductionPicture({
    super.key,
    required this.scene,
    required this.progress,
    required this.choosing,
    required this.labelOf,
    required this.tapAt,
    required this.tapCount,
    required this.guide,
    required this.onGuideEnd,
    required this.onTap,
    required this.onClue,
    required this.onPlace,
  });

  final DeductionScene scene;
  final DeductionProgress progress;
  final bool choosing;
  final String Function(String optionId) labelOf;
  final Offset? tapAt;
  final int tapCount;
  final bool guide;
  final VoidCallback onGuideEnd;
  final ValueChanged<Offset> onTap;
  final ValueChanged<Object> onClue;
  final ValueChanged<DeductionPlace> onPlace;

  static const markSize = 30.0;
  static const placeSize = 40.0;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return LayoutBuilder(
      builder: (context, box) {
        final size = box.biggest;
        Rect place(Rect r) =>
            Rect.fromLTRB(r.left * size.width, r.top * size.height, r.right * size.width, r.bottom * size.height);
        final inside = place(scene.inside);
        final chosen = progress.chosen == null ? null : scene.placeOf(progress.chosen!);
        return Semantics(
          label: scene.place,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => onTap(Offset(d.localPosition.dx / size.width, d.localPosition.dy / size.height)),
            child: ClipRect(
              clipper: _InsideClip(inside),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned.fill(child: Image.asset(scene.picture, fit: BoxFit.fill, excludeFromSemantics: true)),
                  // The chosen place, ringed in gold where it is.
                  if (choosing && chosen != null)
                    Positioned.fromRect(
                      key: const ValueKey('deduction-chosen'),
                      rect: place(chosen.areas.first).inflate(4),
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadius.button),
                            border: Border.all(color: AppColors.goldLight, width: AppLine.ink + 1),
                            boxShadow: [BoxShadow(color: AppColors.goldLight.withValues(alpha: 0.45), blurRadius: 10)],
                          ),
                        ),
                      ),
                    ),
                  for (final c in scene.clues)
                    Positioned(
                      left: c.mark.dx * size.width - markSize / 2,
                      top: c.mark.dy * size.height - markSize / 2,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 240),
                        // Once choosing, the noted traces step back.
                        opacity: choosing ? 0.55 : 1,
                        child: LookMark(key: ValueKey('mark-${c.id}'), looked: progress.hasNoted(c.id)),
                      ),
                    ),
                  if (choosing)
                    for (final p in scene.places)
                      Positioned(
                        left: p.mark.dx * size.width - placeSize / 2,
                        top: p.mark.dy * size.height - placeSize / 2,
                        child: _PlaceMark(key: ValueKey('place-${p.optionId}'), chosen: progress.chosen == p.optionId),
                      ),
                  if (tapAt != null)
                    Positioned(
                      left: tapAt!.dx * size.width - 22,
                      top: tapAt!.dy * size.height - 22,
                      child: SearchTapRing(key: ValueKey('tap-$tapCount'), still: still),
                    ),
                  if (guide)
                    Positioned(
                      left: scene.guideAt.dx * size.width - TapGuide.size / 2,
                      top: scene.guideAt.dy * size.height - TapGuide.size / 2,
                      child: TapGuide(key: const ValueKey('tap-guide'), onEnd: onGuideEnd),
                    ),
                  // For screen readers: the traces and places, then the rest.
                  if (!choosing) ...[
                    for (final c in scene.clues)
                      Positioned.fromRect(
                        rect: place(c.areas.first),
                        child: Semantics(
                          button: true,
                          label: progress.hasNoted(c.id) ? '${c.label}, noted' : c.label,
                          onTap: () => onClue(c),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    for (final o in scene.others)
                      Positioned.fromRect(
                        rect: place(o.areas.first),
                        child: Semantics(
                          button: true,
                          label: o.label,
                          onTap: () => onClue(o),
                          child: const SizedBox.expand(),
                        ),
                      ),
                  ] else
                    for (final p in scene.places)
                      Positioned.fromRect(
                        rect: place(p.areas.first),
                        child: Semantics(
                          button: true,
                          selected: progress.chosen == p.optionId,
                          label: labelOf(p.optionId),
                          onTap: () => onPlace(p),
                          child: const SizedBox.expand(),
                        ),
                      ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _InsideClip extends CustomClipper<Rect> {
  const _InsideClip(this.inside);

  final Rect inside;

  @override
  Rect getClip(Size size) => inside;

  @override
  bool shouldReclip(_InsideClip old) => old.inside != inside;
}

/// A place the box could be: a paper disc with a question mark; chosen, it
/// is filled in navy ink with a gold tick, like a chosen answer.
class _PlaceMark extends StatelessWidget {
  const _PlaceMark({super.key, required this.chosen});

  final bool chosen;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: _DeductionPicture.placeSize,
        height: _DeductionPicture.placeSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: chosen ? AppColors.navy : AppColors.paperLight.withValues(alpha: 0.94),
          border: Border.all(color: chosen ? AppColors.goldLight : AppColors.burgundy, width: AppLine.ink),
          boxShadow: [
            BoxShadow(color: AppColors.navyDeep.withValues(alpha: 0.5), blurRadius: 6, offset: const Offset(0, 1)),
          ],
        ),
        child: chosen
            ? const InkIcon(InkGlyph.check, size: AppIconSize.small, color: AppColors.goldLight)
            : ExcludeSemantics(
                child: Text(
                  '?',
                  textScaler: TextScaler.noScaling,
                  style: AppText.title(size: 20, color: AppColors.burgundy),
                ),
              ),
      ),
    );
  }
}

/// Under the picture: how far the reading has got, what to do now, the
/// detective's notes, and — once choosing — the place chosen and the
/// search; then the hints opened and the tip link.
class _DeductionPanel extends StatelessWidget {
  const _DeductionPanel({
    required this.scene,
    required this.progress,
    required this.choosing,
    required this.chosenLabel,
    required this.hints,
    required this.hintsShown,
    required this.onTip,
    required this.onSearch,
  });

  final DeductionScene scene;
  final DeductionProgress progress;
  final bool choosing;
  final String? chosenLabel;
  final List<String> hints;
  final int hintsShown;
  final VoidCallback onTip;
  final VoidCallback? onSearch;

  @override
  Widget build(BuildContext context) {
    final tipLabel = nextTipLabel(hints, hintsShown);
    final task = choosing ? scene.chooseTask : scene.task;
    final height = MediaQuery.sizeOf(context).height;
    return DecoratedBox(
      key: const ValueKey('deduction-panel'),
      decoration: BoxDecoration(
        color: AppColors.paperLight,
        border: Border(top: BorderSide(color: AppColors.goldLight.withValues(alpha: 0.7), width: AppLine.rule)),
        boxShadow: const [BoxShadow(color: Color(0x59000000), blurRadius: 12, offset: Offset(0, -2))],
      ),
      child: InkSurface(
        night: false,
        // Larger text grows the panel only so far: the picture keeps its
        // share while the notes are read and the place is chosen.
        child: MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.15,
          child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.xs),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  choosing ? 'YOUR NOTES' : 'CLUES ${progress.noted.length} / ${scene.clues.length}',
                  key: const ValueKey('deduction-count'),
                  textAlign: TextAlign.center,
                  style: AppText.eyebrow(),
                ),
                const SizedBox(height: 2),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  child: Semantics(
                    key: ValueKey(task),
                    liveRegion: true,
                    child: GlossaryText(
                      task,
                      key: const ValueKey('deduction-task'),
                      textAlign: TextAlign.center,
                      style: AppText.title(size: 19),
                    ),
                  ),
                ),
                // The notes, as the traces are found (they scroll beyond a
                // short strip on a small screen).
                if (progress.noted.isNotEmpty) ...[
                  const SizedBox(height: AppSpace.sm),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: height * 0.22),
                    child: SingleChildScrollView(
                      key: const ValueKey('deduction-notes'),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (final id in progress.noted)
                            Padding(
                              key: ValueKey('note-$id'),
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Padding(
                                    padding: EdgeInsets.only(top: 3, right: AppSpace.sm),
                                    child: InkIcon(InkGlyph.check, size: AppIconSize.small, color: AppColors.success),
                                  ),
                                  Expanded(
                                    child: GlossaryText(
                                      scene.clue(id).line,
                                      style: AppText.letter(size: 15, color: AppColors.inkBrown),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpace.sm),
                if (!choosing)
                  Text.rich(
                    TextSpan(
                      children: [
                        const WidgetSpan(
                          alignment: PlaceholderAlignment.middle,
                          child: Padding(
                            padding: EdgeInsets.only(right: AppSpace.sm),
                            child: InkIcon(InkGlyph.search, size: AppIconSize.small, color: AppColors.burgundy),
                          ),
                        ),
                        TextSpan(text: scene.tapGuide),
                      ],
                    ),
                    textAlign: TextAlign.center,
                    style: AppText.bodyText(size: 16, weight: FontWeight.w700, color: AppColors.burgundy),
                  )
                else ...[
                  // The place chosen, in words (the task says how to choose).
                  if (chosenLabel != null) ...[
                    Text(
                      'Your choice: $chosenLabel',
                      key: const ValueKey('deduction-choice'),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.bodyText(size: 15, weight: FontWeight.w700, color: AppColors.burgundy),
                    ),
                    const SizedBox(height: AppSpace.sm),
                  ],
                  GameButton(key: const ValueKey('deduction-search'), label: scene.action, onPressed: onSearch),
                ],
                if (hintsShown > 0) const SizedBox(height: AppSpace.sm),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: height * 0.16),
                  child: SingleChildScrollView(
                    key: const ValueKey('deduction-hints'),
                    child: DetectiveTipNotes(hints: hints, revealed: hintsShown, compact: true),
                  ),
                ),
                if (tipLabel != null)
                  Center(
                    child: InkTextButton(label: tipLabel, glyph: InkGlyph.hint, color: tipLinkColor, onPressed: onTip),
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
