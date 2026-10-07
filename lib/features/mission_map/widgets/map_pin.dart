import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../widgets/ink_icon.dart';
import '../../../widgets/paper.dart';

enum PinState { completed, current, locked }

/// A place marked on the detective's map. One visual point per place:
/// - current: "YOU'RE HERE", a small ink arrow, an ink location pin whose tip
///   sits on the place, and the place name lettered onto the map,
/// - completed: a small ink check stamp,
/// - locked: a faint "?" (the place is still a mystery).
class MapPin extends StatefulWidget {
  const MapPin({
    super.key,
    required this.label,
    required this.state,
    required this.onTap,
    this.isFinal = false,
    this.celebrateUnlock = false,
    this.onUnlockBurst,
    this.onUnlockShown,
  });

  /// Hit box of a pin: the note above the place, the name below it.
  static const width = 132.0;
  static const hereBox = 34.0;
  static const markerBox = 64.0;
  static const height = hereBox + markerBox + 34;

  /// Distance from the top of the pin to the point that sits on the map
  /// position (the pin's tip / the centre of the other marks).
  static const anchorY = hereBox + markerBox / 2;

  /// What a current pin draws around its point (relative to it): the
  /// "YOU'RE HERE" note with its arrow, the pin, the place name (up to two
  /// lines). Other marks on the map are kept out of these.
  static const currentMarks = [
    Rect.fromLTRB(-43, -64, 43, -33),
    Rect.fromLTRB(-14, -34, 14, 0),
    Rect.fromLTRB(-66, 2, 66, 32),
  ];

  /// Half the size of a solved (check) or locked mark, with its border.
  static const markRadius = 17.0;

  static const _pinSize = Size(26, 34);

  final String label;
  final PinState state;
  final VoidCallback onTap;
  final bool isFinal;

  /// Plays the LOCKED → UNLOCKED stamp once.
  final bool celebrateUnlock;

  /// Called at the moment the lock opens (play the sound here).
  final VoidCallback? onUnlockBurst;
  final VoidCallback? onUnlockShown;

  @override
  State<MapPin> createState() => _MapPinState();
}

class _MapPinState extends State<MapPin> with TickerProviderStateMixin {
  static const _openAt = 0.25;

  late final AnimationController _unlock = AnimationController(vsync: this, duration: const Duration(milliseconds: 2000));

  /// A very slow 2px drift of the "YOU'RE HERE" arrow (no pulse, no glow).
  late final AnimationController _drift = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  /// True from the moment an unlock is requested until the stamp has faded,
  /// so the pin keeps looking locked until the lock actually opens.
  bool _ceremony = false;
  bool _opened = false;

  void _syncDrift() {
    // Reduced motion: the arrow simply stands still.
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (widget.state == PinState.current && !still) {
      if (!_drift.isAnimating) _drift.repeat(reverse: true);
    } else {
      _drift.stop();
    }
  }

  @override
  void initState() {
    super.initState();
    _unlock.addListener(_checkOpen);
    if (widget.celebrateUnlock) _playUnlock();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncDrift();
  }

  @override
  void didUpdateWidget(MapPin old) {
    super.didUpdateWidget(old);
    _syncDrift();
    if (widget.celebrateUnlock && !old.celebrateUnlock) _playUnlock();
  }

  void _checkOpen() {
    if (!_opened && _unlock.value >= _openAt) {
      _opened = true;
      widget.onUnlockBurst?.call();
    }
  }

  Future<void> _playUnlock() async {
    setState(() {
      _ceremony = true;
      _opened = false;
    });
    await Future<void>.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    await _unlock.forward(from: 0);
    if (!mounted) return;
    setState(() => _ceremony = false);
    widget.onUnlockShown?.call();
  }

  @override
  void dispose() {
    _unlock.dispose();
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '${widget.label}, ${widget.state.name}',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: MapPin.width,
          height: MapPin.height,
          child: AnimatedBuilder(
            animation: Listenable.merge([_unlock, _drift]),
            builder: (context, _) {
              final u = _unlock.value;
              final beforeOpen = _ceremony && u < _openAt;
              final afterOpen = _ceremony && u >= _openAt;
              final state = beforeOpen ? PinState.locked : widget.state;
              // A short nudge while locked, then the new mark settles in.
              final nudge = beforeOpen ? math.sin(u * 50) * 2.5 : 0.0;
              final settle = afterOpen ? Curves.easeOutCubic.transform(((u - _openAt) / 0.2).clamp(0.0, 1.0)) : 1.0;
              // The stamp shows for most of the ceremony, then fades.
              final stamp = afterOpen ? (1 - ((u - 0.8) / 0.2).clamp(0.0, 1.0)) : 0.0;
              const a = MapPin.anchorY;
              final pinTop = a - MapPin._pinSize.height;

              return Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  if (state == PinState.current) ...[
                    // The note, drifting a hair above the pin.
                    Positioned(
                      top: pinTop - 30 + Curves.easeInOut.transform(_drift.value) * 2,
                      child: Opacity(opacity: settle, child: const _YouAreHere()),
                    ),
                    Positioned(
                      top: pinTop + 8 * (1 - settle),
                      child: Opacity(opacity: settle, child: const _InkPin()),
                    ),
                  ] else
                    Positioned(
                      top: MapPin.hereBox,
                      left: 0,
                      right: 0,
                      height: MapPin.markerBox,
                      child: Center(
                        child: Transform.translate(offset: Offset(nudge, 0), child: _Mark(state: state, isFinal: widget.isFinal)),
                      ),
                    ),
                  if (state == PinState.current && stamp == 0) Positioned(top: a + 3, child: _PlaceName(widget.label)),
                  if (stamp > 0)
                    Positioned(
                      top: a + 2,
                      child: Opacity(opacity: stamp, child: const InkStamp('UNLOCKED', color: AppColors.success, size: 13)),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Marks for places that are not the current one.
class _Mark extends StatelessWidget {
  const _Mark({required this.state, required this.isFinal});

  final PinState state;
  final bool isFinal;

  @override
  Widget build(BuildContext context) {
    if (state == PinState.completed) {
      return Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.paperLight,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.success, width: AppLine.ink),
        ),
        child: const InkIcon(InkGlyph.check, size: AppIconSize.small, color: AppColors.success),
      );
    }
    return CustomPaint(
      painter: const _DashedCirclePainter(),
      child: SizedBox(
        width: isFinal ? 34 : 28,
        height: isFinal ? 34 : 28,
        child: Center(child: Text('?', style: AppText.title(size: isFinal ? 18 : 15, color: AppColors.locked))),
      ),
    );
  }
}

/// Text lettered straight onto the map, with a thin paper outline so the
/// roads and the route pass behind it (as on printed maps — not a glow).
class MapLettering extends StatelessWidget {
  const MapLettering(this.text, {super.key, required this.style, this.maxLines = 2});

  final String text;
  final TextStyle style;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final halo = style.copyWith(
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round
        ..color = AppColors.paperLight,
      color: null,
    );
    return Stack(
      children: [
        // The outline is decoration only: not read out, not a second label.
        ExcludeSemantics(
          child: RichText(
            textAlign: TextAlign.center,
            maxLines: maxLines,
            textScaler: MediaQuery.textScalerOf(context),
            text: TextSpan(text: text, style: halo),
          ),
        ),
        Text(text, textAlign: TextAlign.center, maxLines: maxLines, style: style),
      ],
    );
  }
}

/// "YOU'RE HERE" with a small ink arrow, written in the margin of the map.
class _YouAreHere extends StatelessWidget {
  const _YouAreHere();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MapLettering(
          "YOU'RE HERE",
          maxLines: 1,
          style: AppText.style(AppText.body, size: 11, weight: FontWeight.w700, color: AppColors.burgundy, letterSpacing: 1.2),
        ),
        const InkIcon(InkGlyph.down, size: AppIconSize.tiny, color: AppColors.burgundy),
      ],
    );
  }
}

/// The place name under the pin.
class _PlaceName extends StatelessWidget {
  const _PlaceName(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: MapPin.width),
      child: MapLettering(
        text,
        style: AppText.style(AppText.heading, size: 13.5, weight: FontWeight.w700, color: AppColors.navy, height: 1.15, letterSpacing: 0.3),
      ),
    );
  }
}

/// An ink location pin; its tip is the exact place.
class _InkPin extends StatelessWidget {
  const _InkPin();

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: MapPin._pinSize, painter: const _InkPinPainter());
}

class _InkPinPainter extends CustomPainter {
  const _InkPinPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final r = w / 2 - 1;
    final c = Offset(w / 2, r + 1);
    final pin = Path()
      ..moveTo(w / 2, h - 0.5)
      ..quadraticBezierTo(w * 0.12, h * 0.55, c.dx - r, c.dy)
      ..arcToPoint(Offset(c.dx + r, c.dy), radius: Radius.circular(r))
      ..quadraticBezierTo(w * 0.88, h * 0.55, w / 2, h - 0.5)
      ..close();
    canvas.drawPath(pin, Paint()..color = AppColors.navy);
    canvas.drawPath(
      pin,
      Paint()
        ..color = AppColors.paperLight
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
    canvas.drawCircle(c, r * 0.36, Paint()..color = AppColors.paperLight);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DashedCirclePainter extends CustomPainter {
  const _DashedCirclePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    canvas.drawCircle(c, r, Paint()..color = AppColors.paperLight.withValues(alpha: 0.8));
    final dash = Paint()
      ..color = AppColors.locked
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppLine.rule
      ..strokeCap = StrokeCap.round;
    const n = 10;
    for (var i = 0; i < n; i++) {
      canvas.drawArc(Rect.fromCircle(center: c, radius: r), i * 2 * math.pi / n, math.pi / n, false, dash);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
