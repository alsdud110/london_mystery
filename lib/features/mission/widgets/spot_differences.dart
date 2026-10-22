import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/models/mission.dart';
import '../../../data/models/painter_puzzles.dart';
import '../../../data/models/picture_spot.dart';
import '../../../widgets/detective_tips.dart';
import '../../../widgets/game_button.dart';
import '../../../widgets/glossary_text.dart';
import '../../../widgets/ink_icon.dart';
import 'investigation_search.dart' show PencilSlip, SearchTapRing;
import 'search_stage.dart';
import 'zoom_picture.dart';

/// A place compared with a painting of it ([CompareScene]): one picture at a
/// time fills the top of the page, THE STREET or THE PAINTING (switched
/// under it, the same spot kept in view), looked at closer with a pinch.
/// A tap on a change, on either picture, finds it (a gold ring on both, its
/// line of the note ticked); a tap anywhere else is never wrong. Every
/// change found, [onComplete] checks the mission's answer.
///
/// What was found lives in [progress] and is saved through [onFound], so it
/// stays found after a restart.
class SpotDifferences extends StatefulWidget {
  const SpotDifferences({
    super.key,
    required this.scene,
    required this.mission,
    required this.progress,
    required this.onChanged,
    required this.onFound,
    required this.onComplete,
    required this.onReread,
    required this.hintsShown,
    required this.onHint,
  });

  final CompareScene scene;
  final Mission mission;
  final PicturePuzzleProgress progress;
  final VoidCallback onChanged;
  final ValueChanged<String> onFound;
  final Future<void> Function() onComplete;
  final VoidCallback onReread;
  final int hintsShown;
  final Future<bool> Function() onHint;

  @override
  State<SpotDifferences> createState() => _SpotDifferencesState();
}

class _SpotDifferencesState extends State<SpotDifferences> {
  final _zoom = TransformationController();
  int _reset = 0;
  String? _line;
  Offset? _tapAt;
  int _tapCount = 0;
  bool _completing = false;

  PicturePuzzleProgress get _p => widget.progress;
  CompareScene get _scene => widget.scene;

  List<String> get _ids => [for (final c in _scene.changes) c.id];

  @override
  void initState() {
    super.initState();
    // Back on a page where everything was found (a restart before the check).
    if (_p.allFound(_ids)) WidgetsBinding.instance.addPostFrameCallback((_) => _complete());
  }

  @override
  void dispose() {
    _zoom.dispose();
    super.dispose();
  }

  void _show(bool painted) {
    if (_p.showPainted == painted) return;
    HapticFeedback.selectionClick();
    _p.showPainted = painted;
    widget.onChanged();
  }

  void _tap(Offset at, Size shown) {
    setState(() {
      _tapAt = at;
      _tapCount++;
    });
    // A fingertip's width, whatever the zoom.
    final slop = ZoomPicture.slack / (shown.shortestSide * _zoom.value.getMaxScaleOnAxis());
    _look(_scene.changeAt(at, slop: slop));
  }

  void _look(PictureSpot? change) {
    if (change == null) {
      setState(() => _line = _scene.missLine);
      return;
    }
    if (_p.has(change.id)) {
      setState(() => _line = 'You found this one already.');
      return;
    }
    HapticFeedback.mediumImpact();
    _p.found.add(change.id);
    widget.onFound(change.id);
    _line = _scene.foundLines[change.id];
    widget.onChanged();
    if (_p.allFound(_ids)) _complete();
  }

  /// Every change found: a moment to see the last ring, then the check.
  Future<void> _complete() async {
    if (_completing) return;
    _completing = true;
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    try {
      await widget.onComplete();
    } finally {
      if (mounted) _completing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scene = _scene;
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final painted = _p.showPainted;
    final name = painted ? scene.paintedLabel : scene.realLabel;
    return SearchStage(
      // Taller than the picture at the screen's width: it opens a little
      // closer, on the door, the windows above it and the lamp.
      idealHeight: (width) => width / scene.pixels.aspect * 1.6,
      picture: (context, viewport) => Stack(
        children: [
          Positioned.fill(
            child: ZoomPicture(
              viewport: viewport,
              pixels: scene.pixels,
              opening: scene.opening,
              controller: _zoom,
              resetCount: _reset,
              builder: (size) => _ComparePicture(
                key: const ValueKey('compare-picture'),
                scene: scene,
                progress: _p,
                size: size,
                tapAt: _tapAt,
                tapCount: _tapCount,
                still: still,
                onTap: (at) => _tap(at, size),
                onChange: _look,
              ),
            ),
          ),
          // What is shown now, named on it (small, over its top corner).
          Positioned(
            left: AppSpace.sm,
            top: AppSpace.sm,
            child: IgnorePointer(child: _PictureTag(key: const ValueKey('compare-tag'), label: name)),
          ),
        ],
      ),
      note: PencilSlip(line: _line),
      caption: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _Switch(
              left: scene.realLabel,
              right: scene.paintedLabel,
              rightOn: painted,
              onLeft: () => _show(false),
              onRight: () => _show(true),
            ),
            const SizedBox(height: AppSpace.sm),
            GlossaryText(scene.task, key: const ValueKey('compare-task'), textAlign: TextAlign.center, style: AppText.task()),
            const SizedBox(height: AppSpace.xs),
            // The note's lines, ticked as their changes are found; on a short
            // phone, one line (the note is a tap away), the picture larger.
            if (MediaQuery.sizeOf(context).height >= _CheckLine.fullFrom)
              for (final c in scene.changes)
                _CheckLine(key: ValueKey('check-${c.id}'), line: scene.checklist[c.id]!, done: _p.has(c.id))
            else
              _FoundDots(key: const ValueKey('check-dots'), done: [for (final c in scene.changes) _p.has(c.id)]),
          ],
        ),
      ),
      actions: PicturePuzzleActions(
        hints: widget.mission.hints,
        hintsShown: widget.hintsShown,
        onTip: widget.onHint,
        documentLabel: "Painter's Note",
        onDocument: widget.onReread,
        onWhole: () => setState(() => _reset++),
      ),
    );
  }
}

/// The picture shown: the street or the painting, a ring on every change
/// found (the same place on both), the last tap's ring, and a button for
/// screen readers on each place the note sends the detective to.
class _ComparePicture extends StatelessWidget {
  const _ComparePicture({
    super.key,
    required this.scene,
    required this.progress,
    required this.size,
    required this.tapAt,
    required this.tapCount,
    required this.still,
    required this.onTap,
    required this.onChange,
  });

  final CompareScene scene;
  final PicturePuzzleProgress progress;
  final Size size;
  final Offset? tapAt;
  final int tapCount;
  final bool still;
  final ValueChanged<Offset> onTap;
  final ValueChanged<PictureSpot?> onChange;

  @override
  Widget build(BuildContext context) {
    final painted = progress.showPainted;
    return Semantics(
      label: painted ? 'The painting of the street' : 'The street as it really is',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => onTap(Offset(d.localPosition.dx / size.width, d.localPosition.dy / size.height)),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(
              child: Image.asset(
                painted ? scene.painted : scene.real,
                key: ValueKey(painted ? 'compare-painted' : 'compare-real'),
                fit: BoxFit.fill,
                gaplessPlayback: true,
                excludeFromSemantics: true,
              ),
            ),
            for (final c in scene.changes)
              if (progress.has(c.id))
                Positioned.fromRect(
                  rect: placeOn(c.area, size).inflate(4),
                  child: FoundRing(key: ValueKey('found-${c.id}'), still: still),
                ),
            if (tapAt != null)
              Positioned(
                left: tapAt!.dx * size.width - 22,
                top: tapAt!.dy * size.height - 22,
                child: SearchTapRing(key: ValueKey('tap-$tapCount'), still: still),
              ),
            for (final c in scene.changes)
              Positioned.fromRect(
                rect: placeOn(c.area, size),
                child: Semantics(
                  button: true,
                  label: progress.has(c.id) ? '${c.label}, found' : c.label,
                  onTap: () => onChange(c),
                  child: const SizedBox.expand(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// The two pictures' names, side by side: the one shown is navy.
class _Switch extends StatelessWidget {
  const _Switch({required this.left, required this.right, required this.rightOn, required this.onLeft, required this.onRight});

  final String left;
  final String right;
  final bool rightOn;
  final VoidCallback onLeft;
  final VoidCallback onRight;

  @override
  Widget build(BuildContext context) {
    Widget side(String label, bool on, VoidCallback onTap, Key key) => Expanded(
          child: Semantics(
            button: true,
            selected: on,
            label: 'Show $label',
            excludeSemantics: true,
            child: GestureDetector(
              key: key,
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                constraints: const BoxConstraints(minHeight: 48),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.xs),
                decoration: BoxDecoration(
                  color: on ? AppColors.navy : AppColors.parchment.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  border: Border.all(color: on ? AppColors.navyDeep : AppLine.faint(0.3), width: AppLine.hairline),
                ),
                child: MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 1.3,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: AppText.button(size: 15, color: on ? AppColors.goldLight : AppColors.navy),
                  ),
                ),
              ),
            ),
          ),
        );
    return Row(
      children: [
        side(left, !rightOn, onLeft, const ValueKey('compare-show-real')),
        const SizedBox(width: AppSpace.sm),
        side(right, rightOn, onRight, const ValueKey('compare-show-painted')),
      ],
    );
  }
}

/// How many changes are found, as ticks in a row (a short phone's
/// checklist).
class _FoundDots extends StatelessWidget {
  const _FoundDots({super.key, required this.done});

  final List<bool> done;

  @override
  Widget build(BuildContext context) {
    final n = done.where((d) => d).length;
    return Semantics(
      label: 'Found $n of ${done.length}',
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Found $n of ${done.length}', style: AppText.tally()),
          const SizedBox(width: AppSpace.sm),
          for (final d in done)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs / 2),
              child: _Tick(done: d),
            ),
        ],
      ),
    );
  }
}

/// A round tick: gold once found.
class _Tick extends StatelessWidget {
  const _Tick({required this.done});

  final bool done;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 20,
      height: 20,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? AppColors.gold : Colors.transparent,
        border: Border.all(color: done ? AppColors.goldDeep : AppColors.inkBrown.withValues(alpha: 0.5), width: AppLine.rule),
      ),
      child: done ? const InkIcon(InkGlyph.check, size: 12, color: AppColors.navyDeep) : null,
    );
  }
}

/// A line of the note, ticked once what it points to is found.
class _CheckLine extends StatelessWidget {
  const _CheckLine({super.key, required this.line, required this.done});

  /// The screen height from which the note's lines are listed in full.
  static const fullFrom = 720.0;

  final String line;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: done ? '$line Found.' : '$line Not found yet.',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _Tick(done: done),
            const SizedBox(width: AppSpace.sm),
            Flexible(
              child: Text(
                line,
                style: AppText.letter(size: 16, color: done ? AppColors.muted : AppColors.inkBrown).copyWith(
                  decoration: done ? TextDecoration.lineThrough : null,
                  decorationColor: AppColors.muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The small name on the picture shown ("THE PAINTING").
class _PictureTag extends StatelessWidget {
  const _PictureTag({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.navyDeep.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(AppRadius.paper),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.7), width: AppLine.hairline),
      ),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.1,
        child: Text(label, style: AppText.eyebrow(color: AppColors.goldLight)),
      ),
    );
  }
}

/// In reach of the thumb, under a picture puzzle: the hints opened, then the
/// whole picture again, the document and the tips.
class PicturePuzzleActions extends StatelessWidget {
  const PicturePuzzleActions({
    super.key,
    required this.hints,
    required this.hintsShown,
    required this.onTip,
    this.documentLabel,
    this.onDocument,
    this.onWhole,
    this.extra,
  });

  final List<String> hints;
  final int hintsShown;
  final VoidCallback onTip;
  final String? documentLabel;
  final VoidCallback? onDocument;

  /// Back to the opening view (null: no such link).
  final VoidCallback? onWhole;

  /// A main button over the links (the next step, once it can be taken).
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final tipLabel = nextTipLabel(hints, hintsShown);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.xs),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.18),
            child: SingleChildScrollView(
              key: const ValueKey('puzzle-hints'),
              child: DetectiveTipNotes(hints: hints, revealed: hintsShown, compact: true),
            ),
          ),
          if (extra != null) ...[const SizedBox(height: AppSpace.xs), extra!],
          Wrap(
            alignment: WrapAlignment.center,
            spacing: AppSpace.sm,
            children: [
              if (onWhole != null)
                InkTextButton(key: const ValueKey('picture-whole'), label: 'Whole Picture', glyph: InkGlyph.eye, onPressed: onWhole),
              if (documentLabel != null && onDocument != null)
                InkTextButton(label: documentLabel!, glyph: InkGlyph.letter, onPressed: onDocument),
              if (tipLabel != null) InkTextButton(label: tipLabel, glyph: InkGlyph.hint, color: tipLinkColor, onPressed: onTip),
            ],
          ),
        ],
      ),
    );
  }
}
