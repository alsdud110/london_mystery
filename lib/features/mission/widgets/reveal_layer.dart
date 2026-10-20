import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/models/mission.dart';
import '../../../data/models/painter_puzzles.dart';
import '../../../data/models/picture_spot.dart';
import '../../../widgets/glossary_text.dart';
import 'investigation_search.dart' show PencilSlip, SearchTapRing;
import 'search_stage.dart';
import 'spot_differences.dart' show PicturePuzzleActions;
import 'zoom_picture.dart';

/// A canvas painted over a sketch ([LayerScene]): the canvas on its easel
/// fills the top of the page (pinch closer); the slider under it slides the
/// paint off, left to right, and the sketch shows where it has gone. Once
/// most of it is gone, a tap on each thing the question names finds it (a
/// gold ring); every one found, [onComplete] checks the mission's answer.
///
/// How far the paint is slid ([revealed], saved through [onReveal] where
/// the slider is let go) and what is found ([progress], saved through
/// [onFound]) are kept apart: sliding finds nothing by itself.
class RevealLayer extends StatefulWidget {
  const RevealLayer({
    super.key,
    required this.scene,
    required this.mission,
    required this.progress,
    required this.revealed,
    required this.onChanged,
    required this.onReveal,
    required this.onFound,
    required this.onComplete,
    required this.onReread,
    required this.hintsShown,
    required this.onHint,
  });

  final LayerScene scene;
  final Mission mission;
  final PicturePuzzleProgress progress;
  final double revealed;
  final VoidCallback onChanged;
  final ValueChanged<double> onReveal;
  final ValueChanged<String> onFound;
  final Future<void> Function() onComplete;
  final VoidCallback onReread;
  final int hintsShown;
  final Future<bool> Function() onHint;

  @override
  State<RevealLayer> createState() => _RevealLayerState();
}

class _RevealLayerState extends State<RevealLayer> {
  final _zoom = TransformationController();
  int _reset = 0;
  late double _revealed = widget.revealed;
  String? _line;
  Offset? _tapAt;
  int _tapCount = 0;
  bool _completing = false;

  PicturePuzzleProgress get _p => widget.progress;
  LayerScene get _scene => widget.scene;
  List<String> get _ids => [for (final m in _scene.marks) m.id];
  bool get _readable => _revealed >= LayerScene.readable;

  @override
  void initState() {
    super.initState();
    if (_p.allFound(_ids)) WidgetsBinding.instance.addPostFrameCallback((_) => _complete());
  }

  @override
  void dispose() {
    _zoom.dispose();
    super.dispose();
  }

  void _slide(double v) {
    final wasReadable = _readable;
    setState(() => _revealed = v);
    if (!wasReadable && _readable) {
      HapticFeedback.lightImpact();
      _line = null;
    }
  }

  void _letGo(double v) {
    widget.onReveal(v);
  }

  void _tap(Offset at, Size shown) {
    setState(() {
      _tapAt = at;
      _tapCount++;
    });
    if (!_readable) {
      setState(() => _line = _scene.canvas.contains(at) ? _scene.paintLine : _scene.missLine);
      return;
    }
    final slop = ZoomPicture.slack / (shown.shortestSide * _zoom.value.getMaxScaleOnAxis());
    _look(_scene.markAt(at, slop: slop));
  }

  void _look(PictureSpot? mark) {
    if (!_readable) {
      setState(() => _line = _scene.paintLine);
      return;
    }
    if (mark == null) {
      setState(() => _line = _scene.missLine);
      return;
    }
    if (_p.has(mark.id)) {
      setState(() => _line = 'You found this one already.');
      return;
    }
    HapticFeedback.mediumImpact();
    _p.found.add(mark.id);
    widget.onFound(mark.id);
    _line = _scene.foundLines[mark.id];
    widget.onChanged();
    if (_p.allFound(_ids)) _complete();
  }

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
    final found = [for (final m in scene.marks) if (_p.has(m.id)) m.id].length;
    return SearchStage(
      idealHeight: (width) => width / (scene.view.width * scene.pixels.width / (scene.view.height * scene.pixels.height)),
      picture: (context, viewport) => ZoomPicture(
        viewport: viewport,
        pixels: scene.pixels,
        opening: scene.view,
        controller: _zoom,
        resetCount: _reset,
        builder: (size) => _LayerPicture(
                key: const ValueKey('layer-picture'),
          scene: scene,
          progress: _p,
          revealed: _revealed,
          readable: _readable,
          size: size,
          tapAt: _tapAt,
          tapCount: _tapCount,
          still: still,
          onTap: (at) => _tap(at, size),
          onMark: _look,
        ),
      ),
      note: PencilSlip(line: _line),
      caption: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Semantics(
                key: ValueKey(_readable),
                liveRegion: true,
                child: GlossaryText(
                  _readable ? scene.findTask : scene.slideTask,
                  key: const ValueKey('layer-task'),
                  textAlign: TextAlign.center,
                  style: AppText.title(size: 19),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            _PaintSlider(value: _revealed, onChanged: _slide, onChangeEnd: _letGo),
            Text(
              _readable ? 'Found: $found of ${scene.marks.length}' : 'Drag the brass handle to the right.',
              key: const ValueKey('layer-count'),
              textAlign: TextAlign.center,
              style: _readable ? AppText.mark(color: AppColors.burgundy, size: 14) : AppText.caption(),
            ),
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

/// The easel: the sketch, the paint over it cut where it has been slid to
/// (a thin gold edge there), a ring on each thing found, the last tap's
/// ring, and a button for screen readers on each thing, once readable.
class _LayerPicture extends StatelessWidget {
  const _LayerPicture({
    super.key,
    required this.scene,
    required this.progress,
    required this.revealed,
    required this.readable,
    required this.size,
    required this.tapAt,
    required this.tapCount,
    required this.still,
    required this.onTap,
    required this.onMark,
  });

  final LayerScene scene;
  final PicturePuzzleProgress progress;
  final double revealed;
  final bool readable;
  final Size size;
  final Offset? tapAt;
  final int tapCount;
  final bool still;
  final ValueChanged<Offset> onTap;
  final ValueChanged<PictureSpot?> onMark;

  @override
  Widget build(BuildContext context) {
    final edge = scene.edgeAt(revealed) * size.width;
    final canvas = placeOn(scene.canvas, size);
    return Semantics(
      label: readable ? scene.sketchLabel : scene.paintLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (d) => onTap(Offset(d.localPosition.dx / size.width, d.localPosition.dy / size.height)),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned.fill(child: Image.asset(scene.sketch, key: const ValueKey('layer-sketch'), fit: BoxFit.fill, excludeFromSemantics: true)),
            // The paint, still over the sketch right of its edge (the two
            // pictures are the same everywhere but on the canvas).
            Positioned.fill(
              child: ClipRect(
                clipper: _RightOf(edge),
                child: Image.asset(scene.paint, key: const ValueKey('layer-paint'), fit: BoxFit.fill, excludeFromSemantics: true),
              ),
            ),
            if (revealed > 0 && revealed < 1)
              Positioned(
                left: edge - 1.5,
                top: canvas.top,
                height: canvas.height,
                width: 3,
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.goldLight,
                      boxShadow: [BoxShadow(color: AppColors.navyDeep.withValues(alpha: 0.5), blurRadius: 4)],
                    ),
                  ),
                ),
              ),
            for (final m in scene.marks)
              if (progress.has(m.id))
                Positioned.fromRect(
                  rect: placeOn(m.area, size).inflate(3),
                  child: FoundRing(key: ValueKey('found-${m.id}'), still: still),
                ),
            if (tapAt != null)
              Positioned(
                left: tapAt!.dx * size.width - 22,
                top: tapAt!.dy * size.height - 22,
                child: SearchTapRing(key: ValueKey('tap-$tapCount'), still: still),
              ),
            if (readable)
              for (final m in scene.marks)
                Positioned.fromRect(
                  rect: placeOn(m.area, size),
                  child: Semantics(
                    button: true,
                    label: progress.has(m.id) ? '${m.label}, found' : m.label,
                    onTap: () => onMark(m),
                    child: const SizedBox.expand(),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _RightOf extends CustomClipper<Rect> {
  const _RightOf(this.x);

  final double x;

  @override
  Rect getClip(Size size) => Rect.fromLTRB(x.clamp(0.0, size.width), 0, size.width, size.height);

  @override
  bool shouldReclip(_RightOf old) => old.x != x;
}

/// The paint's slider: a brass handle on a rail, with room for a thumb.
class _PaintSlider extends StatelessWidget {
  const _PaintSlider({required this.value, required this.onChanged, required this.onChangeEnd});

  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 6,
        activeTrackColor: AppColors.goldDeep,
        inactiveTrackColor: AppColors.parchmentDark,
        thumbColor: AppColors.gold,
        overlayColor: AppColors.gold.withValues(alpha: 0.2),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14, elevation: 2),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 26),
      ),
      child: Semantics(
        label: 'Slide the paint away',
        child: Slider(
          key: const ValueKey('layer-slider'),
          value: value.clamp(0.0, 1.0),
          onChanged: onChanged,
          onChangeEnd: onChangeEnd,
          semanticFormatterCallback: (v) => '${(v * 100).round()} percent of the paint slid away',
        ),
      ),
    );
  }
}
