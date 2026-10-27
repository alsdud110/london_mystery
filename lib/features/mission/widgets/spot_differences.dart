import 'dart:async';
import 'dart:math' as math;

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
import '../../../widgets/paper_background.dart';
import 'investigation_search.dart' show PencilSlip, SearchTapRing;
import 'search_stage.dart';
import 'zoom_picture.dart';

/// A place compared with a painting of it ([CompareScene]): THE PAINTING
/// over THE STREET at the top of the page, each whole, looked at closer
/// together with a pinch on either. A tap on a change, on either picture,
/// finds it (a gold ring on both, its line of the note ticked); a tap
/// anywhere else is never wrong. Every change found, [onComplete] checks
/// the mission's answer.
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
  /// The paper between the two pictures.
  static const _gap = AppSpace.sm;

  /// Each picture opens whole.
  static const _whole = Rect.fromLTRB(0, 0, 1, 1);

  final _zoom = TransformationController();
  int _reset = 0;
  String? _line;
  Timer? _lineTimer;
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
    _lineTimer?.cancel();
    _zoom.dispose();
    super.dispose();
  }

  /// Shows [line] under the street for a moment, then clears the picture
  /// again.
  void _say(String? line) {
    _lineTimer?.cancel();
    setState(() => _line = line);
    if (line == null) return;
    _lineTimer = Timer(PencilSlip.shown, () {
      if (mounted) setState(() => _line = null);
    });
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
      _say(_scene.missLine);
      return;
    }
    if (_p.has(change.id)) {
      _say('You found this one already.');
      return;
    }
    HapticFeedback.mediumImpact();
    _p.found.add(change.id);
    widget.onFound(change.id);
    _say(_scene.foundLines[change.id]);
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
    final aspect = scene.pixels.aspect;
    // One picture, whole: the painting or the street, its name on it. Both
    // share one zoom, so a pinch on either looks closer at the same spot.
    Widget panel(bool painted, Size size) => Container(
          width: size.width,
          height: size.height,
          // A print's fine edge on the paper.
          foregroundDecoration: BoxDecoration(border: Border.all(color: AppLine.faint(0.4), width: AppLine.hairline)),
          child: Stack(
            children: [
              Positioned.fill(
                child: ZoomPicture(
                  viewport: size,
                  pixels: scene.pixels,
                  opening: _whole,
                  controller: _zoom,
                  resetCount: _reset,
                  builder: (pictureSize) => _ComparePicture(
                    key: ValueKey(painted ? 'compare-picture-painted' : 'compare-picture-real'),
                    scene: scene,
                    progress: _p,
                    painted: painted,
                    size: pictureSize,
                    tapAt: _tapAt,
                    tapCount: _tapCount,
                    still: still,
                    onTap: (at) => _tap(at, pictureSize),
                    onChange: _look,
                  ),
                ),
              ),
              Positioned(
                left: AppSpace.sm,
                top: AppSpace.sm,
                child: IgnorePointer(
                  child: _PictureTag(
                    key: ValueKey(painted ? 'compare-tag-painted' : 'compare-tag-real'),
                    label: painted ? scene.paintedLabel : scene.realLabel,
                  ),
                ),
              ),
              // What the last tap found, a subtitle over the street's
              // cobbles: every change is in the pictures' upper part.
              if (!painted)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: IgnorePointer(child: _Subtitle(line: _line)),
                ),
            ],
          ),
        );
    return SearchStage(
      // The painting over the street, each whole at the screen's width.
      idealHeight: (width) => 2 * width / aspect + _gap,
      picture: (context, viewport) {
        // Each picture whole in its half; narrower than the screen when the
        // page is short, centred.
        final half = math.max(0.0, (viewport.height - _gap) / 2);
        final size = Size(math.min(viewport.width, half * aspect), math.min(half, viewport.width / aspect));
        return PaperBackground(
          child: Column(
            children: [
              SizedBox(height: half, child: Center(child: panel(true, size))),
              const SizedBox(height: _gap),
              SizedBox(height: half, child: Center(child: panel(false, size))),
            ],
          ),
        );
      },
      note: const SizedBox.shrink(),
      caption: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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

/// One of the two pictures: the street or the painting, a ring on every
/// change found (the same place on both), the last tap's ring (on both),
/// and, on the painting only, a button for screen readers on each place
/// the note sends the detective to.
class _ComparePicture extends StatelessWidget {
  const _ComparePicture({
    super.key,
    required this.scene,
    required this.progress,
    required this.painted,
    required this.size,
    required this.tapAt,
    required this.tapCount,
    required this.still,
    required this.onTap,
    required this.onChange,
  });

  final CompareScene scene;
  final PicturePuzzleProgress progress;
  final bool painted;
  final Size size;
  final Offset? tapAt;
  final int tapCount;
  final bool still;
  final ValueChanged<Offset> onTap;
  final ValueChanged<PictureSpot?> onChange;

  @override
  Widget build(BuildContext context) {
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
                  child: FoundRing(key: ValueKey(painted ? 'found-${c.id}' : 'found-${c.id}-real'), still: still),
                ),
            if (tapAt != null)
              Positioned(
                left: tapAt!.dx * size.width - 22,
                top: tapAt!.dy * size.height - 22,
                child: SearchTapRing(key: ValueKey('tap-$tapCount'), still: still),
              ),
            if (painted)
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

/// What the last tap found, along the bottom of the street's picture
/// (read aloud by screen readers as it changes). Nothing before the first
/// tap.
class _Subtitle extends StatelessWidget {
  const _Subtitle({required this.line});

  final String? line;

  @override
  Widget build(BuildContext context) {
    final text = line;
    return Semantics(
      liveRegion: true,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: text == null
            ? const SizedBox.shrink(key: ValueKey('no-subtitle'))
            : Container(
                key: ValueKey(text),
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.sm),
                color: AppColors.navyDeep.withValues(alpha: 0.82),
                child: MediaQuery.withClampedTextScaling(
                  maxScaleFactor: 1.2,
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.letter(size: 15, color: AppColors.parchment),
                  ),
                ),
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
