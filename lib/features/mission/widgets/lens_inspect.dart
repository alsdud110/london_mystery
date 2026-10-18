import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/audio_service.dart';
import '../../../data/models/mission.dart';
import '../../../data/models/scene_inspect.dart';
import '../../../widgets/detective_tips.dart';
import '../../../widgets/game_button.dart';
import '../../../widgets/glossary_text.dart';
import '../../../widgets/ink_icon.dart';
import '../../../widgets/paper.dart';
import '../../game/game_providers.dart';
import 'investigation_search.dart' show PencilSlip;
import 'question_widgets.dart' show ShakeOnChange, WordInputQuestion;
import 'scene_explore.dart' show ExplorePanel, LookMark, OverPicture;

/// A room whose exhibits are examined under a magnifying glass
/// ([InspectScene]). The glass is dragged over the picture and shows it
/// enlarged; resting on an exhibit (or lifting the finger there) examines
/// it, and a tap carries the glass to the spot tapped. The note above the
/// room ticks its lines as the exhibits confirm them. The exhibit the note
/// describes opens its card, then its label, where the mission's word is
/// written and checked by [onSubmit] as the puzzle's answer. Examining is
/// never a wrong answer.
///
/// What was examined lives in [progress], kept by the page that shows it
/// ([onChanged] after each change), so going back keeps it. Not saved.
class LensInspect extends ConsumerStatefulWidget {
  const LensInspect({
    super.key,
    required this.scene,
    required this.mission,
    required this.progress,
    required this.onChanged,
    required this.onSubmit,
    required this.onReread,
    required this.hintsShown,
    required this.onHint,
    required this.wrongPulse,
  });

  final InspectScene scene;
  final Mission mission;
  final InspectProgress progress;
  final VoidCallback onChanged;

  /// Checks the word written on the label as the puzzle's answer.
  final Future<void> Function(String word) onSubmit;

  /// The note read again on its own sheet (the page records it).
  final VoidCallback onReread;

  final int hintsShown;
  final Future<bool> Function() onHint;

  /// Bumped by the page on a wrong answer: the label shakes.
  final int wrongPulse;

  @override
  ConsumerState<LensInspect> createState() => _LensInspectState();
}

class _LensInspectState extends ConsumerState<LensInspect> {
  /// The pencilled slip over the room: what the glass last showed.
  String? _line;

  /// Resting the glass on one exhibit this long examines it.
  static const dwell = Duration(milliseconds: 450);
  Timer? _dwell;
  InspectSpot? _resting;

  /// The glass is being dragged (its finger down).
  bool _dragging = false;

  /// How far outside an exhibit the glass still counts for it, in logical
  /// pixels on screen.
  static const slack = 10.0;

  InspectProgress get _p => widget.progress;
  InspectScene get _scene => widget.scene;

  @override
  void dispose() {
    _dwell?.cancel();
    super.dispose();
  }

  /// The glass moved to [point] (fractions of the picture), kept inside the
  /// picture's own paper edge.
  void _moveLens(Offset point) {
    final r = _scene.inside;
    _p.lens = Offset(point.dx.clamp(r.left, r.right), point.dy.clamp(r.top, r.bottom));
    widget.onChanged();
  }

  InspectSpot? _under(Size shown) {
    final at = _p.lens ?? _scene.lensAt;
    return _scene.hit(at, slack: Size(slack / shown.width, slack / shown.height));
  }

  void _dragStart(Offset point) {
    if (_p.open != null) return;
    _dragging = true;
    _moveLens(point);
  }

  void _dragUpdate(Offset point, Size shown) {
    if (_p.open != null || !_dragging) return;
    _moveLens(point);
    final under = _under(shown);
    if (under != _resting) {
      _resting = under;
      _dwell?.cancel();
      if (under != null) _dwell = Timer(dwell, () => _examine(under));
    }
  }

  void _dragEnd(Size shown) {
    if (!_dragging) return;
    _dragging = false;
    _dwell?.cancel();
    final under = _under(shown);
    final already = _resting == under && under != null && _p.hasExamined(under.id) && under.kind == InspectKind.exhibit;
    _resting = null;
    if (_p.open == null && !already) _examine(under);
  }

  /// A tap: the glass is carried there, and what is under it examined.
  void _tapAt(Offset point, Size shown) {
    if (_p.open != null) return;
    _dwell?.cancel();
    _moveLens(point);
    _examine(_under(shown));
  }

  /// A screen reader's button for [s]: the glass to its middle, examined.
  void _examineSpot(InspectSpot s) {
    if (_p.open != null) return;
    _moveLens(s.areas.first.center);
    _examine(s);
  }

  void _examine(InspectSpot? s) {
    if (_p.open != null || !mounted) return;
    if (s == null) {
      setState(() => _line = _scene.missLine);
      return;
    }
    if (!_p.canOpen(s)) {
      setState(() => _line = s.lockedLine);
      return;
    }
    final audio = ref.read(audioServiceProvider);
    HapticFeedback.selectionClick();
    switch (s.kind) {
      case InspectKind.exhibit:
        audio.play(GameSound.pencilNote);
        _p.examined.add(s.id);
        _line = s.line;
      case InspectKind.match || InspectKind.hidden:
        audio.play(GameSound.pencilNote);
        _p.examined.add(s.id);
        _p.open = s.id;
        _line = null;
      case InspectKind.label:
        _openLabel();
        return;
    }
    widget.onChanged();
  }

  void _openLabel() {
    ref.read(audioServiceProvider).play(GameSound.paperRustle);
    final label = _scene.label;
    _p.examined.add(label.id);
    _p.labelRead = true;
    _p.open = label.id;
    _line = null;
    widget.onChanged();
  }

  void _close() {
    if (_p.open == null) return;
    _p.open = null;
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final scene = _scene;
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final open = _p.open == null ? null : scene.spot(_p.open!);
    final matchFound = _p.hasExamined(scene.match.id);
    return Stack(
      children: [
        // The note and the panel take at most their share of the height
        // (they scroll beyond it), so the room always keeps the rest: on a
        // small phone, with large text, with the keyboard up.
        LayoutBuilder(
          builder: (context, box) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _NoteMemo(
              intro: widget.mission.letterIntro,
              lines: noteLines(widget.mission),
              confirmed: _p.confirmed(scene),
              task: _p.labelRead ? scene.taskLine : null,
              maxHeight: box.maxHeight * 0.26,
            ),
            Expanded(
              child: _LensRoom(
                scene: scene,
                progress: _p,
                line: _line,
                onDragStart: _dragStart,
                onDragUpdate: _dragUpdate,
                onDragEnd: _dragEnd,
                onTap: _tapAt,
                onSpot: _examineSpot,
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: box.maxHeight * 0.34),
              child: SingleChildScrollView(
                key: const ValueKey('inspect-panel-scroll'),
                child: ExplorePanel(
                  task: matchFound ? scene.nextTask : scene.task,
                  tapGuide: scene.dragGuide,
                  zoomGuide: scene.tapGuide,
                  hints: widget.mission.hints,
                  hintsShown: widget.hintsShown,
                  documentLabel: matchFound ? scene.labelLink : null,
                  onDocument: _openLabel,
                  onTip: widget.onHint,
                  hintsHeight: 0.12,
                ),
              ),
            ),
          ],
        ),
        ),
        if (open != null)
          Positioned.fill(
            child: switch (open.kind) {
              InspectKind.match => _MatchCard(
                key: ValueKey('inspect-card-${open.id}'),
                spot: open,
                confirms: [for (final i in open.checks) noteLines(widget.mission)[i]],
                action: scene.matchAction,
                still: still,
                onLabel: _openLabel,
                onClose: _close,
              ),
              InspectKind.hidden => _FoundCard(
                key: ValueKey('inspect-card-${open.id}'),
                spot: open,
                still: still,
                onClose: _close,
              ),
              InspectKind.label => _LabelCard(
                key: ValueKey('inspect-card-${open.id}'),
                scene: scene,
                mission: widget.mission,
                wrongPulse: widget.wrongPulse,
                hintsShown: widget.hintsShown,
                onHint: widget.onHint,
                onReread: widget.onReread,
                onSubmit: widget.onSubmit,
                onClose: _close,
              ),
              InspectKind.exhibit => const SizedBox.shrink(),
            },
          ),
      ],
    );
  }
}

/// The note's lines, as the mission's letter has them.
List<String> noteLines(Mission m) => [
      for (final l in m.letter.split('\n'))
        if (l.trim().isNotEmpty) l.trim(),
    ];

/// The note, pinned above the room: its lines, each ticked once the
/// exhibits confirm it; once the label is read, the line still to answer
/// carries the pencil ([task]).
class _NoteMemo extends StatefulWidget {
  const _NoteMemo({
    required this.intro,
    required this.lines,
    required this.confirmed,
    required this.task,
    required this.maxHeight,
  });

  /// The most it takes; it scrolls beyond.
  final double maxHeight;

  final String intro;
  final List<String> lines;
  final Set<int> confirmed;
  final int? task;

  @override
  State<_NoteMemo> createState() => _NoteMemoState();
}

class _NoteMemoState extends State<_NoteMemo> {
  late final _lines = [for (final _ in widget.lines) GlobalKey()];

  /// A line just ticked (or just given the pencil) is brought into view:
  /// with large text the note scrolls, and the tick is the news.
  @override
  void didUpdateWidget(_NoteMemo old) {
    super.didUpdateWidget(old);
    final fresh = [
      ...widget.confirmed.difference(old.confirmed),
      if (widget.task != null && widget.task != old.task) widget.task!,
    ];
    if (fresh.isEmpty) return;
    final last = fresh.reduce(math.max);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final line = _lines[last].currentContext;
      if (line != null && line.mounted) {
        Scrollable.ensureVisible(line, duration: const Duration(milliseconds: 250), alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final lines = widget.lines;
    final confirmed = widget.confirmed;
    final task = widget.task;
    final intro = widget.intro;
    return DecoratedBox(
      key: const ValueKey('inspect-note'),
      decoration: BoxDecoration(
        color: AppColors.paperLight,
        border: Border(bottom: BorderSide(color: AppColors.goldLight.withValues(alpha: 0.7), width: AppLine.rule)),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: widget.maxHeight),
        child: SingleChildScrollView(
          key: const ValueKey('inspect-note-scroll'),
          padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.sm, AppSpace.lg, AppSpace.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text('THE NOTE', style: AppText.eyebrow()),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Semantics(
                      label: 'Confirmed ${confirmed.length} of ${lines.length}',
                      excludeSemantics: true,
                      child: Text(
                        '${confirmed.length} / ${lines.length}',
                        key: const ValueKey('inspect-note-count'),
                        textAlign: TextAlign.end,
                        style: AppText.mark(size: 13),
                      ),
                    ),
                  ),
                ],
              ),
              GlossaryText(intro, style: AppText.aside(size: 13, color: AppColors.inkBrown)),
              for (final (i, line) in lines.indexed)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: _NoteLine(
                    key: _lines[i],
                    id: i,
                    line: line,
                    confirmed: confirmed.contains(i),
                    task: task == i && !confirmed.contains(i),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoteLine extends StatelessWidget {
  const _NoteLine({super.key, required this.id, required this.line, required this.confirmed, required this.task});

  final int id;
  final String line;
  final bool confirmed;
  final bool task;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: ValueKey('note-line-$id'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: confirmed ? 'Confirmed' : (task ? 'Still to answer' : 'Not confirmed yet'),
          excludeSemantics: true,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            width: 18,
            height: 18,
            margin: const EdgeInsets.only(top: 1),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: confirmed ? AppColors.success : Colors.transparent,
              border: Border.all(
                color: confirmed ? AppColors.success : (task ? AppColors.burgundy : AppLine.faint(0.4)),
                width: AppLine.rule,
              ),
            ),
            child: confirmed
                ? const InkIcon(InkGlyph.check, size: AppIconSize.tiny, color: AppColors.paperLight)
                : (task ? const InkIcon(InkGlyph.pen, size: AppIconSize.tiny, color: AppColors.burgundy) : null),
          ),
        ),
        const SizedBox(width: AppSpace.sm),
        Expanded(
          child: GlossaryText(
            line,
            style: AppText.letter(
              size: 14,
              color: confirmed ? AppColors.muted : (task ? AppColors.burgundy : AppColors.inkBrown),
            ),
          ),
        ),
      ],
    );
  }
}

/// The room, its picture whole (its own proportions, inside its paper
/// edge), with the glass over it: a round window that shows the picture
/// enlarged around the point under the finger, held just above the finger
/// so the finger never hides what it shows (below it near the top).
class _LensRoom extends StatelessWidget {
  const _LensRoom({
    required this.scene,
    required this.progress,
    required this.line,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onTap,
    required this.onSpot,
  });

  final InspectScene scene;
  final InspectProgress progress;
  final String? line;
  final ValueChanged<Offset> onDragStart;
  final void Function(Offset point, Size shown) onDragUpdate;
  final ValueChanged<Size> onDragEnd;
  final void Function(Offset point, Size shown) onTap;
  final ValueChanged<InspectSpot> onSpot;

  /// How much the glass enlarges.
  static const magnification = 2.4;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, box) {
          final viewport = box.biggest;
          // The part of the picture inside its paper edge fills as much of
          // the room as it can, in its own proportions.
          final inside = scene.inside;
          final insideAspect = scene.pixels.aspect * inside.width / inside.height;
          var iw = viewport.width;
          var ih = iw / insideAspect;
          if (ih > viewport.height) {
            ih = viewport.height;
            iw = ih * insideAspect;
          }
          // The whole picture, placed so its inside part is that rectangle.
          final w = iw / inside.width;
          final h = ih / inside.height;
          final insideOrigin = Offset((viewport.width - iw) / 2, (viewport.height - ih) / 2);
          final origin = insideOrigin - Offset(inside.left * w, inside.top * h);
          final picture = origin & Size(w, h);
          final shown = Size(w, h);

          Offset fraction(Offset local) => Offset((local.dx - origin.dx) / w, (local.dy - origin.dy) / h);

          final focal = progress.lens ?? scene.lensAt;
          final focalOnScreen = origin + Offset(focal.dx * w, focal.dy * h);
          final d = (math.min(iw, ih) * 0.42).clamp(88.0, 150.0);
          // The glass sits above the finger, or below it near the top, and
          // never off the side of the room: it shows the point under the
          // finger wherever it sits ([focalOffset]).
          final lift = focalOnScreen.dy - d * 1.05 < 0 ? -d * 0.75 : d * 0.75;
          final lensCentre = Offset(
            focalOnScreen.dx.clamp(d / 2, math.max(d / 2, viewport.width - d / 2)),
            focalOnScreen.dy - lift,
          );
          final focalOffset = focalOnScreen - lensCentre;

          return Stack(
            children: [
              // The room itself, dim, all around its picture.
              Positioned.fill(
                child: ExcludeSemantics(
                  child: Opacity(opacity: 0.3, child: Image.asset(scene.picture, fit: BoxFit.cover)),
                ),
              ),
              Positioned.fill(child: ColoredBox(color: AppColors.navyDeep.withValues(alpha: 0.6))),
              Positioned.fromRect(
                rect: insideOrigin & Size(iw, ih),
                child: ClipRect(
                  child: OverflowBox(
                    alignment: Alignment.topLeft,
                    minWidth: w,
                    maxWidth: w,
                    minHeight: h,
                    maxHeight: h,
                    child: Transform.translate(
                      offset: Offset(-inside.left * w, -inside.top * h),
                      child: SizedBox(
                        width: w,
                        height: h,
                        child: Semantics(
                          label: scene.place,
                          child: Stack(
                            children: [
                              Positioned.fill(
                                child: Image.asset(
                                  scene.picture,
                                  key: const ValueKey('inspect-picture'),
                                  fit: BoxFit.fill,
                                  excludeFromSemantics: true,
                                ),
                              ),
                              for (final s in scene.spots)
                                if (progress.hasExamined(s.id) && s.kind != InspectKind.label)
                                  Positioned(
                                    left: s.areas.first.right * w - 24,
                                    top: s.areas.first.top * h - 6,
                                    child: Transform.scale(
                                      scale: 0.8,
                                      child: LookMark(key: ValueKey('tick-${s.id}'), looked: true),
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
              // The finger on the room: drag the glass, or tap to carry it.
              Positioned.fill(
                child: GestureDetector(
                  key: const ValueKey('inspect-room'),
                  behavior: HitTestBehavior.opaque,
                  onPanStart: (d) => onDragStart(fraction(d.localPosition)),
                  onPanUpdate: (d) => onDragUpdate(fraction(d.localPosition), shown),
                  onPanEnd: (_) => onDragEnd(shown),
                  onPanCancel: () => onDragEnd(shown),
                  onTapUp: (d) => onTap(fraction(d.localPosition), shown),
                ),
              ),
              // Screen readers: one button per exhibit (an empty box: a
              // finger passes through it to the room).
              for (final s in scene.spots)
                Positioned.fromRect(
                  rect: Rect.fromLTRB(
                    picture.left + s.areas.first.left * w,
                    picture.top + s.areas.first.top * h,
                    picture.left + s.areas.first.right * w,
                    picture.top + s.areas.first.bottom * h,
                  ),
                  child: Semantics(
                    button: true,
                    label: progress.hasExamined(s.id) ? '${s.label}, examined' : s.label,
                    onTap: () => onSpot(s),
                    child: const SizedBox.expand(),
                  ),
                ),
              // The point the glass shows, and the glass.
              Positioned(
                left: focalOnScreen.dx - 7,
                top: focalOnScreen.dy - 7,
                child: const IgnorePointer(child: _FocalRing()),
              ),
              Positioned(
                left: lensCentre.dx - d / 2,
                top: lensCentre.dy - d / 2,
                child: IgnorePointer(
                  child: _Glass(
                    key: const ValueKey('inspect-lens'),
                    size: d,
                    focalOffset: focalOffset,
                    magnification: magnification,
                  ),
                ),
              ),
              Positioned(
                left: AppSpace.md,
                right: AppSpace.md,
                top: AppSpace.sm,
                child: IgnorePointer(child: PencilSlip(line: line)),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The magnifying glass: the picture under it enlarged ([RawMagnifier]),
/// in a brass ring with a short handle.
class _Glass extends StatelessWidget {
  const _Glass({super.key, required this.size, required this.focalOffset, required this.magnification});

  final double size;
  final Offset focalOffset;
  final double magnification;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The handle, down and to the right of the ring.
          Positioned(
            left: size * 0.80,
            top: size * 0.80,
            child: Transform.rotate(
              angle: -math.pi / 4,
              alignment: Alignment.topLeft,
              child: Container(
                width: size * 0.13,
                height: size * 0.34,
                decoration: BoxDecoration(
                  color: AppColors.inkBrown,
                  borderRadius: BorderRadius.circular(size * 0.05),
                  border: Border.all(color: AppColors.goldDeep, width: AppLine.rule),
                ),
              ),
            ),
          ),
          RawMagnifier(
            size: Size.square(size),
            magnificationScale: magnification,
            focalPointOffset: focalOffset,
            decoration: MagnifierDecoration(
              shape: const CircleBorder(side: BorderSide(color: AppColors.gold, width: 4)),
              shadows: [BoxShadow(color: AppColors.navyDeep.withValues(alpha: 0.55), blurRadius: 10, offset: const Offset(0, 4))],
            ),
          ),
          // A thin inner ring, the glass's own edge.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.goldLight.withValues(alpha: 0.6), width: AppLine.hairline),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The small ring on the point the glass shows (where the finger is).
class _FocalRing extends StatelessWidget {
  const _FocalRing();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.goldLight, width: AppLine.rule),
        boxShadow: [BoxShadow(color: AppColors.navyDeep.withValues(alpha: 0.6), blurRadius: 3)],
      ),
    );
  }
}

/// The exhibit the note describes, examined: what the glass shows, the
/// note's line it confirms, and the way to its label.
class _MatchCard extends StatelessWidget {
  const _MatchCard({
    super.key,
    required this.spot,
    required this.confirms,
    required this.action,
    required this.still,
    required this.onLabel,
    required this.onClose,
  });

  final InspectSpot spot;
  final List<String> confirms;
  final String action;
  final bool still;
  final VoidCallback onLabel;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return OverPicture(
      still: still,
      child: PaperSheet(
        ruled: true,
        padding: EdgeInsets.zero,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('EXAMINED', style: AppText.eyebrow()),
              const SizedBox(height: AppSpace.sm),
              Text(spot.title, textAlign: TextAlign.center, style: AppText.placeTitle(size: 26)),
              const SizedBox(height: AppSpace.xs),
              const OrnamentRule(),
              const SizedBox(height: AppSpace.sm),
              GlossaryText(spot.line, textAlign: TextAlign.center, style: AppText.letter(size: 18)),
              if (confirms.isNotEmpty) ...[
                const SizedBox(height: AppSpace.md),
                Text('It matches the note:', textAlign: TextAlign.center, style: AppText.caption()),
                for (final c in confirms)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpace.xs),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const InkIcon(InkGlyph.check, size: AppIconSize.small, color: AppColors.success),
                        const SizedBox(width: AppSpace.sm),
                        Flexible(
                          child: GlossaryText(c, style: AppText.letter(size: 16, color: AppColors.inkBrown)),
                        ),
                      ],
                    ),
                  ),
              ],
              const SizedBox(height: AppSpace.lg),
              GameButton(key: const ValueKey('inspect-read-label'), label: action, arrow: true, onPressed: onLabel),
              const SizedBox(height: AppSpace.sm),
              GameButton(
                key: const ValueKey('inspect-close'),
                label: 'BACK TO THE ROOM',
                style: GameButtonStyle.outline,
                onPressed: onClose,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Something hidden, found: the key's own picture (the ink key), its name
/// and what was seen; a tap anywhere goes back to the room.
class _FoundCard extends StatelessWidget {
  const _FoundCard({super.key, required this.spot, required this.still, required this.onClose});

  final InspectSpot spot;
  final bool still;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${spot.title}. ${spot.line} Keep looking',
      excludeSemantics: true,
      onTap: onClose,
      child: OverPicture(
        still: still,
        onTapOutside: onClose,
        child: GestureDetector(
          key: const ValueKey('inspect-close'),
          onTap: onClose,
          child: PaperSheet(
            ruled: true,
            padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('FOUND', style: AppText.eyebrow()),
                const SizedBox(height: AppSpace.sm),
                Container(
                  width: 72,
                  height: 72,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.navy,
                    border: Border.all(color: AppColors.gold, width: AppLine.ink),
                  ),
                  child: const InkIcon(InkGlyph.key, size: AppIconSize.emblem, color: AppColors.goldLight),
                ),
                const SizedBox(height: AppSpace.sm),
                Text(spot.title, textAlign: TextAlign.center, style: AppText.placeTitle(size: 24)),
                const SizedBox(height: AppSpace.xs),
                const OrnamentRule(),
                const SizedBox(height: AppSpace.sm),
                Text(spot.line, textAlign: TextAlign.center, style: AppText.letter(size: 17)),
                const SizedBox(height: AppSpace.md),
                Text('Tap to keep looking', textAlign: TextAlign.center, style: AppText.caption()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The label of the exhibit the note describes, read close: the room it
/// names, the name with its second word worn away, and the word written
/// in (the mission's own word puzzle: its label, its field, CHECK ANSWER).
class _LabelCard extends StatefulWidget {
  const _LabelCard({
    super.key,
    required this.scene,
    required this.mission,
    required this.wrongPulse,
    required this.hintsShown,
    required this.onHint,
    required this.onReread,
    required this.onSubmit,
    required this.onClose,
  });

  final InspectScene scene;
  final Mission mission;
  final int wrongPulse;
  final int hintsShown;
  final Future<bool> Function() onHint;
  final VoidCallback onReread;
  final Future<void> Function(String word) onSubmit;
  final VoidCallback onClose;

  @override
  State<_LabelCard> createState() => _LabelCardState();
}

class _LabelCardState extends State<_LabelCard> {
  /// A check is on its way: no second one (nor a second reward) meanwhile.
  bool _checking = false;

  Future<void> _check(String word) async {
    if (_checking) return;
    _checking = true;
    try {
      await widget.onSubmit(word);
    } finally {
      _checking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.mission;
    final scene = widget.scene;
    final tip = nextTipLabel(m.hints, widget.hintsShown);
    return ColoredBox(
      key: const ValueKey('inspect-label'),
      color: AppColors.navyDeep.withValues(alpha: 0.78),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: PaperSheet(
                padding: EdgeInsets.zero,
                child: SingleChildScrollView(
                  key: const ValueKey('inspect-label-scroll'),
                  padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.md),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(scene.labelTitle, textAlign: TextAlign.center, style: AppText.eyebrow()),
                      const SizedBox(height: AppSpace.xs),
                      const Center(child: OrnamentRule()),
                      const SizedBox(height: AppSpace.md),
                      // The room, on the label's brass plate.
                      Center(
                        child: Container(
                          key: const ValueKey('inspect-room-plate'),
                          padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.xs),
                          decoration: BoxDecoration(
                            color: AppColors.navy,
                            borderRadius: BorderRadius.circular(AppRadius.paper),
                            border: Border.all(color: AppColors.gold, width: AppLine.rule),
                          ),
                          child: Text(
                            scene.labelRoom,
                            style: AppText.title(size: 20, color: AppColors.goldLight).copyWith(letterSpacing: 3),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpace.sm),
                      Text(scene.labelWorn, textAlign: TextAlign.center, style: AppText.caption(color: AppColors.inkBrown)),
                      const SizedBox(height: AppSpace.sm),
                      GlossaryText(m.question, textAlign: TextAlign.center, style: AppText.title(size: 20)),
                      const SizedBox(height: AppSpace.md),
                      ShakeOnChange(
                        trigger: widget.wrongPulse,
                        child: WordInputQuestion(mission: m, onSubmit: _check),
                      ),
                      DetectiveTipNotes(hints: m.hints, revealed: widget.hintsShown, compact: true),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: AppSpace.sm,
                        children: [
                          InkTextButton(label: 'Reread Letter', glyph: InkGlyph.letter, onPressed: widget.onReread),
                          if (tip != null)
                            InkTextButton(label: tip, glyph: InkGlyph.hint, color: tipLinkColor, onPressed: widget.onHint),
                        ],
                      ),
                      const SizedBox(height: AppSpace.xs),
                      GameButton(
                        key: const ValueKey('inspect-label-close'),
                        label: 'BACK TO THE ROOM',
                        style: GameButtonStyle.outline,
                        onPressed: widget.onClose,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
