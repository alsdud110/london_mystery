import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';

/// Where a [GuidedActionIndicator] stands next to its target, pointing at it.
enum GuideSide { above, below, left }

/// What ties a [GuidedActionIndicator] to the thing it points at: put the
/// target in a [GuideTarget] with the same link.
class GuideLink {
  final LayerLink layer = LayerLink();
  final GlobalKey key = GlobalKey();
}

/// The thing a [GuidedActionIndicator] points at (its layout is unchanged).
class GuideTarget extends StatelessWidget {
  const GuideTarget({super.key, required this.link, required this.child});

  final GuideLink link;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      CompositedTransformTarget(link: link.layer, child: KeyedSubtree(key: link.key, child: child));
}

/// A small inked arrow pointing at the next thing to do (a [GuideTarget]).
///
/// It follows its target wherever layout puts it — scrolled, in a sheet that
/// grows, with larger text — and never takes a touch. It comes in softly
/// and nods toward the target a few times, then rests (still with motion
/// reduced: it simply shows). Give it a new key for each new step: the same
/// step never nods again. When there is no room on [side] (the target is at
/// the edge of where the arrow can be seen), it stands on the other side.
///
/// Place it as a direct child of a [Stack] that covers the target.
class GuidedActionIndicator extends StatefulWidget {
  const GuidedActionIndicator({
    super.key,
    required this.link,
    this.side = GuideSide.above,
    this.along = 0,
    this.color = AppColors.goldDeep,
    this.delay = Duration.zero,
    this.span = false,
  });

  final GuideLink link;
  final GuideSide side;

  /// Where along the target's side it points, from -1 (start) to 1 (end).
  final double along;
  final Color color;

  /// How long to wait before showing (e.g. until the target has come in).
  final Duration delay;

  /// Points at the target as a whole (a row of choices, none favoured): a
  /// thin bracket along its whole side, the arrow at the bracket.
  final bool span;

  /// The bracket's depth (its line and end ticks).
  static const bracket = 7.0;

  /// The arrow's length and width, its gap to the target, and how far it nods.
  static const length = 18.0;
  static const width = 14.0;
  static const gap = 2.0;
  static const nod = 8.0;

  /// One nod, and how many before it rests.
  static const period = Duration(milliseconds: 1000);
  static const nods = 3;

  @override
  State<GuidedActionIndicator> createState() => _GuidedActionIndicatorState();
}

class _GuidedActionIndicatorState extends State<GuidedActionIndicator> with SingleTickerProviderStateMixin {
  late final AnimationController _motion = AnimationController(
    vsync: this,
    duration: GuidedActionIndicator.period * GuidedActionIndicator.nods,
  );
  Timer? _wait;
  bool _shown = false;
  late GuideSide _side = widget.side;

  /// The target's length along its side, for the [GuidedActionIndicator.span]
  /// bracket (known after the first layout).
  double? _length;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_shown || _wait != null) return;
    if (widget.delay == Duration.zero) {
      _show();
    } else {
      _wait = Timer(widget.delay, _show);
    }
  }

  void _show() {
    if (!mounted) return;
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    setState(() => _shown = true);
    if (still) {
      _motion.value = 1;
    } else {
      _motion.forward();
    }
  }

  @override
  void dispose() {
    _wait?.cancel();
    _motion.dispose();
    super.dispose();
  }

  /// The side with room: [GuidedActionIndicator.side], or the other one when
  /// the arrow would stand outside this layer.
  void _checkRoom() {
    final target = widget.link.key.currentContext?.findRenderObject();
    final host = context.findRenderObject();
    if (target is! RenderBox || host is! RenderBox || !target.attached || !host.attached) return;
    final rect = MatrixUtils.transformRect(target.getTransformTo(host), Offset.zero & target.size);
    final reach = GuidedActionIndicator.length +
        GuidedActionIndicator.gap +
        GuidedActionIndicator.nod +
        (widget.span ? GuidedActionIndicator.bracket : 0);
    final side = switch (widget.side) {
      GuideSide.above when rect.top < reach => GuideSide.below,
      GuideSide.below when host.size.height - rect.bottom < reach => GuideSide.above,
      final s => s,
    };
    final length = widget.span ? (side == GuideSide.left ? rect.height : rect.width) : null;
    if (side != _side || length != _length) {
      setState(() {
        _side = side;
        _length = length;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _checkRoom();
    });
    const l = GuidedActionIndicator.length, w = GuidedActionIndicator.width, g = GuidedActionIndicator.gap;
    // With a bracket, the arrow stands off it.
    final off = widget.span ? GuidedActionIndicator.bracket + g : 0.0;
    final (Alignment target, Alignment follower, Offset away, int turns) = switch (_side) {
      GuideSide.above => (Alignment(widget.along, -1), Alignment.bottomCenter, const Offset(0, -1), 0),
      GuideSide.below => (Alignment(widget.along, 1), Alignment.topCenter, const Offset(0, 1), 2),
      GuideSide.left => (Alignment(-1, widget.along), Alignment.centerRight, const Offset(-1, 0), 3),
    };
    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (widget.span && _length != null)
              Positioned(
                left: 0,
                top: 0,
                child: AnimatedBuilder(
                  animation: _motion,
                  builder: (context, child) {
                    final ms = (GuidedActionIndicator.period * GuidedActionIndicator.nods).inMilliseconds;
                    final fade = _shown ? (_motion.value * ms / 250).clamp(0.0, 1.0) : 0.0;
                    final (Alignment target, Alignment follower) = switch (_side) {
                      GuideSide.above => (Alignment.topCenter, Alignment.bottomCenter),
                      GuideSide.below => (Alignment.bottomCenter, Alignment.topCenter),
                      GuideSide.left => (Alignment.centerLeft, Alignment.centerRight),
                    };
                    return CompositedTransformFollower(
                      link: widget.link.layer,
                      showWhenUnlinked: false,
                      targetAnchor: target,
                      followerAnchor: follower,
                      offset: away * g,
                      child: Opacity(opacity: fade, child: child),
                    );
                  },
                  child: RotatedBox(
                    quarterTurns: turns,
                    child: CustomPaint(
                      key: const ValueKey('guide-bracket'),
                      size: Size(_length!, GuidedActionIndicator.bracket),
                      painter: _InkBracket(widget.color),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 0,
              top: 0,
              child: AnimatedBuilder(
                animation: _motion,
                builder: (context, child) {
                  final t = _motion.value;
                  // Nods toward the target and back, ending at rest beside it.
                  final nod = GuidedActionIndicator.nod * (1 - math.cos(2 * math.pi * GuidedActionIndicator.nods * t)) / 2;
                  final ms = (GuidedActionIndicator.period * GuidedActionIndicator.nods).inMilliseconds;
                  final fade = _shown ? (t * ms / 250).clamp(0.0, 1.0) : 0.0;
                  return CompositedTransformFollower(
                    link: widget.link.layer,
                    showWhenUnlinked: false,
                    targetAnchor: target,
                    followerAnchor: follower,
                    offset: away * (g + off + nod),
                    child: Opacity(opacity: fade, child: child),
                  );
                },
                child: RotatedBox(
                  quarterTurns: turns,
                  child: CustomPaint(
                    key: const ValueKey('guide-arrow'),
                    size: const Size(w, l),
                    painter: _InkArrow(widget.color),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A small hand-inked arrow pointing down: a slightly bowed stroke and a
/// filled head, its ink a little heavier at the point.
class _InkArrow extends CustomPainter {
  const _InkArrow(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final ink = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;
    // The shaft, a touch bowed like a pen stroke.
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.52, 1)
        ..quadraticBezierTo(w * 0.40, h * 0.35, w * 0.5, h * 0.62),
      ink,
    );
    // The head.
    final head = Path()
      ..moveTo(w * 0.06, h * 0.52)
      ..quadraticBezierTo(w * 0.32, h * 0.62, w * 0.5, h - 0.5)
      ..quadraticBezierTo(w * 0.68, h * 0.62, w * 0.94, h * 0.52)
      ..quadraticBezierTo(w * 0.5, h * 0.66, w * 0.06, h * 0.52)
      ..close();
    canvas.drawPath(head, Paint()..color = color);
    canvas.drawPath(head, ink..strokeWidth = 1.2..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(_InkArrow old) => old.color != color;
}

/// A thin bracket along a row of choices (drawn above it, ticks pointing
/// down at its ends): "these, all of them".
class _InkBracket extends CustomPainter {
  const _InkBracket(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()
      ..color = color.withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    const inset = 6.0;
    final y = 1.0;
    canvas.drawPath(
      Path()
        ..moveTo(inset, size.height - 1)
        ..lineTo(inset + 2, y)
        ..lineTo(size.width - inset - 2, y)
        ..lineTo(size.width - inset, size.height - 1),
      ink,
    );
  }

  @override
  bool shouldRepaint(_InkBracket old) => old.color != color;
}

/// The same inked arrow, small and still: one of several equal choices
/// (each marked alike, none favoured). It never takes a touch, and comes in
/// with a short fade (at once with motion reduced).
class GuideMark extends StatelessWidget {
  const GuideMark({super.key, this.color = AppColors.goldDeep});

  final Color color;

  static const width = 11.0;
  static const length = 14.0;

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: still ? 1 : 0, end: 1),
        duration: const Duration(milliseconds: 250),
        builder: (context, t, child) => Opacity(opacity: t, child: child),
        child: CustomPaint(size: const Size(width, length), painter: _InkArrow(color)),
      ),
    );
  }
}
