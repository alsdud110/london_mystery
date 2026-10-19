import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/models/mission.dart';
import '../../../data/models/scene_decode.dart';
import '../../../widgets/art_assets.dart';
import '../../../widgets/detective_tips.dart';
import '../../../widgets/game_button.dart';
import '../../../widgets/glossary_text.dart';
import '../../../widgets/ink_icon.dart';
import '../../../widgets/paper_background.dart';
import '../../../widgets/royal_box_picture.dart';
import '../../../widgets/symbol_icon.dart';
import 'investigation_search.dart' show PencilSlip, SearchTapRing;
import 'scene_explore.dart' show LookMark;

/// One thing found at a place, examined ([DecodeScene]): the place's
/// picture fills the screen, a small glass on the thing. Tapped, the thing
/// is brought closer; EXAMINE THE CODE draws a short scan over its code
/// (nothing is really read: no camera, no network), and the code's hidden
/// message is written in its place, in the thing's own ink — the mission's
/// evidence's pictures, in order, with no number. TAKE THE CARD then calls [onTake], which
/// answers the mission (the Discovery Moment follows).
///
/// The step reached lives in [progress], kept by the page that shows it
/// ([onChanged] after each change), so going back keeps it. Not saved.
class SceneDecode extends StatefulWidget {
  const SceneDecode({
    super.key,
    required this.scene,
    required this.mission,
    required this.progress,
    required this.onChanged,
    required this.onTake,
    required this.hintsShown,
    required this.onHint,
  });

  final DecodeScene scene;
  final Mission mission;
  final DecodeProgress progress;
  final VoidCallback onChanged;

  /// The thing is taken: answers the mission.
  final VoidCallback onTake;

  final int hintsShown;
  final VoidCallback onHint;

  /// How long the scan takes, then the message appearing.
  static const scanTime = Duration(milliseconds: 1000);
  static const revealTime = Duration(milliseconds: 1400);

  /// How long the picture takes to come closer.
  static const closerTime = Duration(milliseconds: 450);

  @override
  State<SceneDecode> createState() => _SceneDecodeState();
}

class _SceneDecodeState extends State<SceneDecode> with TickerProviderStateMixin {
  late final AnimationController _scan = AnimationController(vsync: this, duration: SceneDecode.scanTime)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _decoded();
    });
  // TAKE THE CARD wakes once the whole message is shown.
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: SceneDecode.revealTime,
    value: widget.progress.step == DecodeStep.decoded ? 1 : 0,
  )..addStatusListener((s) {
      if (s == AnimationStatus.completed && mounted) setState(() {});
    });

  /// The pencilled slip over the picture: what the last tap found.
  String? _line;

  /// Where the last tap landed (fractions of the picture), and a count so
  /// each tap rings anew.
  Offset? _tapAt;
  int _tapCount = 0;

  /// The thing is being taken: a second press does nothing.
  bool _taking = false;

  /// How far outside the thing a tap still counts for it, in logical pixels.
  static const slack = 14.0;

  DecodeProgress get _p => widget.progress;
  DecodeScene get _scene => widget.scene;
  bool get _still => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // The message's pictures are decoded ahead, so each appears with its
    // name, never after it.
    if (_precached) return;
    _precached = true;
    // And the card's restored paper, so the code fades as the scan ends; and
    // the evidence's own picture, so the Discovery Moment shows it at once.
    precacheImage(AssetImage(widget.scene.cleared), context, onError: (_, _) {});
    final evidencePicture = ArtAssets.evidencePictures[widget.mission.evidence?.id];
    if (evidencePicture != null) precacheImage(AssetImage(evidencePicture), context, onError: (_, _) {});
    for (final s in widget.mission.evidence?.symbols ?? const <String>[]) {
      final p = RoyalBoxPicture.of(s);
      if (p != null) precacheImage(AssetImage(p.file), context, onError: (_, _) {});
    }
  }

  @override
  void didUpdateWidget(SceneDecode old) {
    super.didUpdateWidget(old);
    // Taken back to the place while scanning: the scan stops, and the code
    // is examined again next time.
    if (_p.step != DecodeStep.closer && _scan.isAnimating) _scan.reset();
  }

  @override
  void dispose() {
    _scan.dispose();
    _reveal.dispose();
    super.dispose();
  }

  void _tap(Offset point, Size shown) {
    if (_p.step != DecodeStep.look) return;
    final reach = Size(slack / shown.width, slack / shown.height);
    if (_scene.hits(point, slack: reach)) {
      _closer();
      return;
    }
    setState(() {
      _tapAt = point;
      _tapCount++;
      _line = _scene.missLine;
    });
  }

  void _closer() {
    if (_p.step != DecodeStep.look) return;
    HapticFeedback.selectionClick();
    _p.step = DecodeStep.closer;
    _line = null;
    _tapAt = null;
    widget.onChanged();
  }

  void _examine() {
    if (_p.step != DecodeStep.closer || _scan.isAnimating) return;
    if (_still) {
      _decoded();
    } else {
      setState(() {}); // the button rests while the scan runs
      _scan.forward(from: 0);
    }
  }

  void _decoded() {
    if (!mounted || _p.step != DecodeStep.closer) return;
    HapticFeedback.selectionClick();
    _p.step = DecodeStep.decoded;
    _scan.reset();
    if (_still) {
      _reveal.value = 1;
    } else {
      _reveal.forward(from: 0);
    }
    widget.onChanged();
  }

  void _take() {
    if (_taking || _p.step != DecodeStep.decoded) return;
    setState(() => _taking = true);
    widget.onTake();
  }

  @override
  Widget build(BuildContext context) {
    final scene = _scene;
    final step = _p.step;
    final symbols = widget.mission.evidence?.symbols ?? const <String>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ClipRect(
            child: Stack(
              children: [
                // The place itself, dim, all around the picture.
                Positioned.fill(
                  child: ExcludeSemantics(
                    child: Opacity(opacity: 0.35, child: Image.asset(scene.picture, fit: BoxFit.cover)),
                  ),
                ),
                Positioned.fill(child: ColoredBox(color: AppColors.navyDeep.withValues(alpha: 0.55))),
                Positioned.fill(
                  child: LayoutBuilder(
                    builder: (context, box) => TweenAnimationBuilder<Rect?>(
                      tween: RectTween(
                        end: switch (step) {
                          DecodeStep.look => scene.inside,
                          DecodeStep.closer => scene.closer,
                          DecodeStep.decoded => scene.revealed,
                        },
                      ),
                      duration: _still ? Duration.zero : SceneDecode.closerTime,
                      curve: Curves.easeInOutCubic,
                      builder: (context, view, _) => _framed(view!, box.biggest, symbols),
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
            ),
          ),
        ),
        _DecodePanel(
          scene: scene,
          mission: widget.mission,
          step: step,
          scanning: _scan.isAnimating,
          symbols: symbols,
          hintsShown: widget.hintsShown,
          onTip: widget.onHint,
          onExamine: _examine,
          onTake: _taking || !_reveal.isCompleted ? null : _take,
        ),
      ],
    );
  }

  /// The picture placed so that [view] (fractions of it) fills as much of
  /// [viewport] as it can, centred.
  Widget _framed(Rect view, Size viewport, List<String> symbols) {
    final aspect = _scene.pixels.aspect;
    final viewAspect = view.width * aspect / view.height;
    var regionW = viewport.width;
    var regionH = regionW / viewAspect;
    if (regionH > viewport.height) {
      regionH = viewport.height;
      regionW = regionH * viewAspect;
    }
    final w = regionW / view.width;
    final h = w / aspect;
    final left = (viewport.width - regionW) / 2 - view.left * w;
    final top = (viewport.height - regionH) / 2 - view.top * h;
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned(
          left: left,
          top: top,
          width: w,
          height: h,
          child: _DecodePicture(
            key: const ValueKey('decode-picture'),
            scene: _scene,
            step: _p.step,
            scan: _scan,
            reveal: _reveal,
            symbols: symbols,
            tapAt: _tapAt,
            tapCount: _tapCount,
            still: _still,
            onTap: (point) => _tap(point, Size(w, h)),
            onThing: _closer,
          ),
        ),
      ],
    );
  }
}

/// The place's picture, at whatever size it is shown: the glass on the
/// thing; closer, a gold edge on its code and the scan over it; decoded,
/// the hidden message on its face. Taps are in fractions of the picture.
class _DecodePicture extends StatelessWidget {
  const _DecodePicture({
    super.key,
    required this.scene,
    required this.step,
    required this.scan,
    required this.reveal,
    required this.symbols,
    required this.tapAt,
    required this.tapCount,
    required this.still,
    required this.onTap,
    required this.onThing,
  });

  final DecodeScene scene;
  final DecodeStep step;
  final Animation<double> scan;
  final Animation<double> reveal;
  final List<String> symbols;
  final Offset? tapAt;
  final int tapCount;
  final bool still;
  final ValueChanged<Offset> onTap;
  final VoidCallback onThing;

  static const markSize = 30.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final size = box.biggest;
        Rect place(Rect r) =>
            Rect.fromLTRB(r.left * size.width, r.top * size.height, r.right * size.width, r.bottom * size.height);
        final code = place(scene.code);
        return Semantics(
          label: scene.place,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => onTap(Offset(d.localPosition.dx / size.width, d.localPosition.dy / size.height)),
            child: ClipRect(
              clipper: _InsideClip(place(scene.inside)),
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned.fill(child: Image.asset(scene.picture, fit: BoxFit.fill, excludeFromSemantics: true)),
                  if (step == DecodeStep.look) ...[
                    Positioned(
                      left: scene.mark.dx * size.width - markSize / 2,
                      top: scene.mark.dy * size.height - markSize / 2,
                      child: const LookMark(key: ValueKey('decode-mark'), looked: false),
                    ),
                    // For screen readers: the thing, to look at closer.
                    Positioned.fromRect(
                      rect: place(scene.areas.first),
                      child: Semantics(
                        button: true,
                        label: scene.thing,
                        hint: 'Look closer',
                        onTap: onThing,
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ],
                  // Closer: the code edged in gold, the scan passing over it.
                  if (step == DecodeStep.closer)
                    Positioned.fromRect(
                      key: const ValueKey('decode-code'),
                      rect: code.inflate(6),
                      child: IgnorePointer(child: _ScanOverCode(scan: scan)),
                    ),
                  // Decoded: the code's ink fades off the card (the card's
                  // own paper, restored, comes up in its place: the same
                  // pixels everywhere else), and the message is drawn there.
                  if (step == DecodeStep.decoded) ...[
                    Positioned.fromRect(
                      key: const ValueKey('decode-cleared'),
                      rect: place(scene.clearedArea),
                      child: FadeTransition(
                        opacity: CurvedAnimation(parent: reveal, curve: _HiddenMessage.fade),
                        child: Image.asset(
                          scene.cleared,
                          fit: BoxFit.fill,
                          excludeFromSemantics: true,
                          // The card as it was, rather than nothing.
                          errorBuilder: (context, error, stack) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                    Positioned.fromRect(
                      key: const ValueKey('decode-message'),
                      rect: place(scene.clearedArea),
                      child: Transform.rotate(
                        angle: scene.messageTilt,
                        child: _HiddenMessage(scene: scene, symbols: symbols, reveal: reveal),
                      ),
                    ),
                  ],
                  if (tapAt != null)
                    Positioned(
                      left: tapAt!.dx * size.width - 22,
                      top: tapAt!.dy * size.height - 22,
                      child: SearchTapRing(key: ValueKey('tap-$tapCount'), still: still),
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

/// The code to examine: edged in antique gold; while [scan] runs, a thin
/// gold line passes down over it once, the part it has passed faintly lit.
class _ScanOverCode extends StatelessWidget {
  const _ScanOverCode({required this.scan});

  final Animation<double> scan;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: scan,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(scan.value);
        final running = scan.isAnimating;
        return LayoutBuilder(
          builder: (context, box) {
            final h = box.maxHeight;
            return Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      border: Border.all(color: AppColors.goldLight, width: AppLine.ink + 1),
                      boxShadow: [BoxShadow(color: AppColors.goldLight.withValues(alpha: 0.35), blurRadius: 10)],
                    ),
                  ),
                ),
                if (running) ...[
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: h * t,
                    child: ColoredBox(color: AppColors.goldLight.withValues(alpha: 0.14)),
                  ),
                  Positioned(
                    key: const ValueKey('decode-scan-line'),
                    left: 0,
                    right: 0,
                    top: math.max(0, h * t - 1.5),
                    height: 3,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.goldLight,
                        boxShadow: [BoxShadow(color: AppColors.goldLight.withValues(alpha: 0.7), blurRadius: 8)],
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}

/// What the code hid, drawn where the code was as [reveal] runs (the code's
/// ink fading off the card first): the four lock pictures appear one after
/// another in reading order — two lines of two, left to right — each with
/// its name under it, and a pencilled trail of dots, a little wavy, leads
/// from each to the next with a small arrowhead: along the first line, down
/// and back to the start of the second, along it. Full-colour pictures,
/// never tinted, straight on the card: no paper, frame or shadow; no
/// numbers.
class _HiddenMessage extends StatelessWidget {
  const _HiddenMessage({required this.scene, required this.symbols, required this.reveal});

  final DecodeScene scene;
  final List<String> symbols;
  final Animation<double> reveal;

  /// The order as a screen reader says it ("Clock, then Train, …"), with
  /// the names the pictures are shown with.
  static String spoken(List<String> symbols) =>
      'Hidden message: ${symbols.map(RoyalBoxPicture.nameOf).join(', then ')}.';

  /// When the code's ink fades off, when the [i]th picture appears, and
  /// when the trail to it is pencilled (parts of [reveal]).
  static const fade = Interval(0, 0.3, curve: Curves.easeOut);
  static Interval shown(int i) => Interval(0.22 + 0.16 * i, 0.42 + 0.16 * i, curve: Curves.easeOut);
  static Interval pencilled(int i) => Interval(0.14 + 0.16 * i, 0.32 + 0.16 * i, curve: Curves.easeInOut);

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: spoken(symbols),
      container: true,
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, box) {
          final size = box.biggest;
          final layout = _MessageLayout(size);
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  key: const ValueKey('decode-trail'),
                  painter: _PencilTrail(ink: scene.ink, reveal: reveal, count: symbols.length, layout: layout),
                ),
              ),
              for (final (i, s) in symbols.indexed) ...[
                Positioned.fromRect(
                  key: ValueKey('decode-symbol-$s'),
                  rect: layout.picture(i),
                  child: _InkedIn(
                    reveal: CurvedAnimation(parent: reveal, curve: shown(i)),
                    child: switch (RoyalBoxPicture.of(s)) {
                      final RoyalBoxPicture p => RoyalBoxPictureImage(p, size: layout.side),
                      null => Center(child: GameSymbol.of(s).mark(size: layout.side * 0.7, color: scene.ink)),
                    },
                  ),
                ),
                Positioned.fromRect(
                  key: ValueKey('decode-name-$s'),
                  rect: layout.name(i),
                  child: FadeTransition(
                    opacity: CurvedAnimation(parent: reveal, curve: shown(i)),
                    child: _PictureName(RoyalBoxPicture.nameOf(s)),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Where everything sits where the code was ([size]): two lines of two
/// cells, each a picture with its name under it, in reading order, and the
/// trails between them.
class _MessageLayout {
  _MessageLayout(this.size);

  final Size size;

  double get _padX => size.width * 0.05;
  double get _padY => size.height * 0.04;
  double get _gutter => size.height * 0.07;
  double get _colW => (size.width - 2 * _padX) / 2;
  double get _rowH => (size.height - 2 * _padY - _gutter) / 2;
  double get _nameH => math.max(14.0, _rowH * 0.19);

  /// The pictures' side: as large as a cell allows, the same for all four,
  /// leaving room between the two columns for the trails.
  double get side => math.max(0, math.min(_colW * 0.64, _rowH - _nameH - size.height * 0.02));

  double _rowTop(int row) => _padY + row * (_rowH + _gutter);
  double _cx(int i) => _padX + _colW * ((i % 2) + 0.5);

  Rect picture(int i) {
    final top = _rowTop(i ~/ 2);
    return Rect.fromCenter(center: Offset(_cx(i), top + (_rowH - _nameH) / 2), width: side, height: side);
  }

  Rect name(int i) {
    final top = _rowTop(i ~/ 2);
    return Rect.fromLTWH(_cx(i) - _colW / 2, top + _rowH - _nameH, _colW, _nameH);
  }

  /// The trail from picture [i] to the next, off both pictures and their
  /// names: along the first line, a soft arc over the gap (rising); along
  /// the second, one under it (dipping), so the two never meet; from the
  /// end of the first line to the start of the next, a curve that leaves
  /// the right picture low on its left, sweeps down and to the left through
  /// the middle, and comes in to the left picture's upper right.
  Path trail(int i) {
    final from = picture(i), to = picture(i + 1);
    final gap = side * 0.1;
    if (i ~/ 2 == (i + 1) ~/ 2) {
      final first = i < 2;
      final y = first ? from.center.dy - side * 0.1 : from.center.dy + side * 0.15;
      final a = Offset(from.right + gap, y);
      final b = Offset(to.left - gap, y);
      final bend = first ? -side * 0.32 : side * 0.32;
      return Path()
        ..moveTo(a.dx, a.dy)
        ..cubicTo(a.dx + (b.dx - a.dx) * 0.3, a.dy + bend, a.dx + (b.dx - a.dx) * 0.7, b.dy + bend, b.dx, b.dy);
    }
    final a = Offset(from.left - gap, from.center.dy + side * 0.25);
    final b = Offset(to.right + gap * 0.6, to.top + side * 0.12);
    final drop = (b.dy - a.dy);
    return Path()
      ..moveTo(a.dx, a.dy)
      ..cubicTo(a.dx - side * 0.2, a.dy + drop * 0.8, b.dx + side * 0.35, b.dy - drop * 0.45, b.dx, b.dy);
  }
}

/// A picture's name in capitals, in the casebook's small-caps style, kept
/// to one line in its cell whatever the text size.
class _PictureName extends StatelessWidget {
  const _PictureName(this.name);

  final String name;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.15,
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(name.toUpperCase(), maxLines: 1, style: AppText.eyebrow(color: AppColors.inkBrown)),
        ),
      ),
    );
  }
}

/// The reading order, pencilled in the card's [ink], as a detective marks a
/// notebook: along each [_MessageLayout.trail], dots of slightly uneven
/// size on a gently wavering line, ending in a small open arrowhead; each
/// trail drawn out (from its start) as the picture it leads to appears.
class _PencilTrail extends CustomPainter {
  _PencilTrail({required this.ink, required this.reveal, required this.count, required this.layout})
      : super(repaint: reveal);

  final Color ink;
  final Animation<double> reveal;
  final int count;
  final _MessageLayout layout;

  @override
  void paint(Canvas canvas, Size size) {
    final dot = math.max(1.1, size.shortestSide * 0.0075);
    final step = dot * 3.4;
    final wave = dot * 0.9;
    for (var i = 0; i + 1 < count; i++) {
      final t = _HiddenMessage.pencilled(i + 1).transform(reveal.value);
      if (t == 0) continue;
      final paint = Paint()..color = ink.withValues(alpha: 0.88);
      final jitter = math.Random(31 + i);
      for (final metric in layout.trail(i).computeMetrics()) {
        final drawn = metric.length * t;
        ui.Tangent? last;
        for (var d = 0.0; d <= drawn; d += step) {
          final at = metric.getTangentForOffset(d);
          if (at == null) continue;
          final normal = Offset(-at.vector.dy, at.vector.dx);
          // The hand wavers a little, and presses a little unevenly.
          final p = at.position + normal * (wave * math.sin(d / (step * 2.6)));
          canvas.drawCircle(p, dot * (0.75 + 0.5 * jitter.nextDouble()), paint);
          last = at;
        }
        // The arrowhead once the trail reaches the next picture.
        final end = metric.getTangentForOffset(metric.length);
        if (t >= 1 && end != null && last != null) {
          final dir = end.vector / end.vector.distance;
          final side = Offset(-dir.dy, dir.dx);
          final head = dot * 5.5;
          final tip = end.position;
          final pen = Paint()
            ..color = ink.withValues(alpha: 0.88)
            ..style = PaintingStyle.stroke
            ..strokeWidth = dot * 1.3
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round;
          canvas.drawPath(
            Path()
              ..moveTo((tip - dir * head + side * head * 0.6).dx, (tip - dir * head + side * head * 0.6).dy)
              ..lineTo(tip.dx, tip.dy)
              ..lineTo((tip - dir * head - side * head * 0.6).dx, (tip - dir * head - side * head * 0.6).dy),
            pen,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(_PencilTrail old) =>
      old.ink != ink || old.reveal != reveal || old.count != count || old.layout.size != layout.size;
}

/// A picture appearing: it comes up from nothing, its edges soft at first,
/// as ink soaking into paper — no growing, turning or flashing.
class _InkedIn extends StatelessWidget {
  const _InkedIn({required this.reveal, required this.child});

  final Animation<double> reveal;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: reveal,
      child: child,
      builder: (context, child) {
        final t = reveal.value;
        if (t >= 1) return child!;
        final blur = 2.5 * (1 - t);
        return Opacity(
          opacity: t,
          child: ImageFiltered(imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur), child: child),
        );
      },
    );
  }
}

/// Under the picture: where the detective is with the thing, what to do,
/// and the one action of the step (none while looking: the thing is tapped
/// in the picture); then the hints opened and the tip link, until the code
/// is decoded.
class _DecodePanel extends StatelessWidget {
  const _DecodePanel({
    required this.scene,
    required this.mission,
    required this.step,
    required this.scanning,
    required this.symbols,
    required this.hintsShown,
    required this.onTip,
    required this.onExamine,
    required this.onTake,
  });

  final DecodeScene scene;
  final Mission mission;
  final DecodeStep step;
  final bool scanning;
  final List<String> symbols;
  final int hintsShown;
  final VoidCallback onTip;
  final VoidCallback onExamine;
  final VoidCallback? onTake;

  @override
  Widget build(BuildContext context) {
    final hints = mission.hints;
    final tipLabel = step == DecodeStep.decoded ? null : nextTipLabel(hints, hintsShown);
    final height = MediaQuery.sizeOf(context).height;
    final eyebrow = switch (step) {
      DecodeStep.look => 'MISSION ${mission.numberLabel} · INVESTIGATE',
      DecodeStep.closer => 'LOOK CLOSER',
      DecodeStep.decoded => 'THE HIDDEN MESSAGE',
    };
    // While the code is scanned the line stays (only the button says so):
    // the panel keeps its height, so the card does not move under the scan.
    final line = switch (step) {
      DecodeStep.look => scene.found,
      DecodeStep.closer => scene.closerTask,
      DecodeStep.decoded => mission.letter,
    };
    return DecoratedBox(
      key: const ValueKey('decode-panel'),
      decoration: BoxDecoration(
        color: AppColors.paperLight,
        border: Border(top: BorderSide(color: AppColors.goldLight.withValues(alpha: 0.7), width: AppLine.rule)),
        boxShadow: const [BoxShadow(color: Color(0x59000000), blurRadius: 12, offset: Offset(0, -2))],
      ),
      child: InkSurface(
        night: false,
        // Larger text grows the panel only so far: the card keeps its share
        // of the screen while it is examined.
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
                  Text(eyebrow, key: const ValueKey('decode-step'), textAlign: TextAlign.center, style: AppText.eyebrow()),
                  const SizedBox(height: 2),
                  // One line goes, then the next comes: never two lines
                  // read over each other.
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: const Interval(0.5, 1, curve: Curves.easeOut),
                    switchOutCurve: const Interval(0.5, 1, curve: Curves.easeIn),
                    child: Semantics(
                      key: ValueKey(line),
                      liveRegion: true,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: height * 0.2),
                        child: SingleChildScrollView(
                          child: GlossaryText(
                            line,
                            key: const ValueKey('decode-line'),
                            textAlign: TextAlign.center,
                            style: step == DecodeStep.decoded
                                ? AppText.letter(size: 17, color: AppColors.inkBrown)
                                : AppText.title(size: 19),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpace.sm),
                  switch (step) {
                    DecodeStep.look => Text.rich(
                        TextSpan(
                          children: [
                            const WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Padding(
                                padding: EdgeInsets.only(right: AppSpace.sm),
                                child: InkIcon(InkGlyph.search, size: AppIconSize.small, color: AppColors.burgundy),
                              ),
                            ),
                            TextSpan(text: scene.tapTask),
                          ],
                        ),
                        textAlign: TextAlign.center,
                        style: AppText.bodyText(size: 16, weight: FontWeight.w700, color: AppColors.burgundy),
                      ),
                    DecodeStep.closer => Semantics(
                        liveRegion: scanning,
                        child: GameButton(
                          key: const ValueKey('decode-examine'),
                          label: scanning ? 'EXAMINING THE CODE…' : scene.examine,
                          glyph: InkGlyph.search,
                          singleLine: true,
                          onPressed: scanning ? null : onExamine,
                        ),
                      ),
                    DecodeStep.decoded => GameButton(
                        key: const ValueKey('decode-take'),
                        label: scene.take,
                        arrow: true,
                        singleLine: true,
                        // The order, said with the button that keeps it.
                        semanticLabel: '${scene.take}. ${_HiddenMessage.spoken(symbols)}',
                        onPressed: onTake,
                      ),
                  },
                  if (step != DecodeStep.decoded) ...[
                    if (hintsShown > 0) const SizedBox(height: AppSpace.sm),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: height * 0.16),
                      child: SingleChildScrollView(
                        key: const ValueKey('decode-hints'),
                        child: DetectiveTipNotes(hints: hints, revealed: hintsShown, compact: true),
                      ),
                    ),
                    if (tipLabel != null)
                      Center(
                        child: InkTextButton(label: tipLabel, glyph: InkGlyph.hint, color: tipLinkColor, onPressed: onTip),
                      ),
                  ] else
                    const SizedBox(height: AppSpace.sm),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
