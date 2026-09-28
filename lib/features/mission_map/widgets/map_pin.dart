import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

enum PinState { completed, current, locked }

/// A location marker on the mission map.
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

  static const width = 124.0;
  static const circle = 58.0;

  final String label;
  final PinState state;
  final VoidCallback onTap;
  final bool isFinal;

  /// Plays the LOCKED → UNLOCKED ceremony once.
  final bool celebrateUnlock;

  /// Called at the moment the lock breaks open (play the sound here).
  final VoidCallback? onUnlockBurst;
  final VoidCallback? onUnlockShown;

  @override
  State<MapPin> createState() => _MapPinState();
}

class _MapPinState extends State<MapPin> with TickerProviderStateMixin {
  static const _burstAt = 0.3;

  late final AnimationController _pulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  late final AnimationController _unlock = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));

  /// True from the moment an unlock is requested until the ceremony ends, so
  /// the pin keeps looking locked until the lock actually "breaks".
  bool _ceremony = false;
  bool _burstFired = false;

  @override
  void initState() {
    super.initState();
    _unlock.addListener(_checkBurst);
    _syncPulse();
    if (widget.celebrateUnlock) _playUnlock();
  }

  @override
  void didUpdateWidget(MapPin old) {
    super.didUpdateWidget(old);
    _syncPulse();
    if (widget.celebrateUnlock && !old.celebrateUnlock) _playUnlock();
  }

  void _checkBurst() {
    if (!_burstFired && _unlock.value >= _burstAt) {
      _burstFired = true;
      widget.onUnlockBurst?.call();
    }
  }

  void _syncPulse() {
    if (widget.state == PinState.current && !_ceremony) {
      if (!_pulse.isAnimating) _pulse.repeat();
    } else {
      _pulse.stop();
    }
  }

  Future<void> _playUnlock() async {
    setState(() {
      _ceremony = true;
      _burstFired = false;
    });
    _syncPulse();
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    await _unlock.forward(from: 0);
    if (!mounted) return;
    setState(() => _ceremony = false);
    _syncPulse();
    widget.onUnlockShown?.call();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _unlock.dispose();
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
          child: AnimatedBuilder(
            animation: Listenable.merge([_pulse, _unlock]),
            builder: (context, _) {
              final u = _unlock.value;
              final beforeBurst = _ceremony && u < _burstAt;
              final afterBurst = _ceremony && u >= _burstAt;
              // During the ceremony the pin looks locked until the burst.
              final state = beforeBurst ? PinState.locked : widget.state;

              final (fill, border, icon, iconColor) = switch (state) {
                PinState.completed => (AppColors.gold, AppColors.navy, Icons.check_rounded, AppColors.navy),
                PinState.current => (
                    AppColors.navy,
                    AppColors.gold,
                    afterBurst && u < 0.7
                        ? Icons.lock_open_rounded
                        : (widget.isFinal ? Icons.vpn_key_rounded : Icons.search_rounded),
                    AppColors.goldLight,
                  ),
                PinState.locked => (const Color(0xFFE5DFD0), AppColors.locked, Icons.lock_rounded, AppColors.locked),
              };

              // Locked pin wiggles, then pops open with an elastic bounce.
              final shake = beforeBurst ? math.sin(u * 60) * 5 * (u / _burstAt) : 0.0;
              final pop = afterBurst ? Curves.elasticOut.transform(((u - _burstAt) / (1 - _burstAt)).clamp(0, 1)) : 1.0;
              final burst = afterBurst ? ((u - _burstAt) / 0.5).clamp(0.0, 1.0) : 0.0;
              final showUnlockedLabel = afterBurst && u < 0.92;

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: MapPin.circle + 36,
                    height: MapPin.circle + 36,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        if (afterBurst) _Glow(progress: burst),
                        if (state == PinState.current && !_ceremony) ...[
                          _ring(_pulse.value, AppColors.gold),
                          _ring((_pulse.value + 0.5) % 1, AppColors.gold),
                        ],
                        if (afterBurst) _Sparkles(progress: burst),
                        Transform.translate(
                          offset: Offset(shake, 0),
                          child: Transform.scale(
                            scale: afterBurst ? 0.6 + 0.4 * pop : 1.0,
                            child: Container(
                              width: MapPin.circle,
                              height: MapPin.circle,
                              decoration: BoxDecoration(
                                color: fill,
                                shape: BoxShape.circle,
                                border: Border.all(color: border, width: 3.5),
                                boxShadow: [
                                  if (state != PinState.locked)
                                    BoxShadow(
                                      color: (state == PinState.current ? AppColors.gold : AppColors.navy)
                                          .withValues(alpha: 0.45),
                                      blurRadius: state == PinState.current ? 16 : 6,
                                      offset: const Offset(0, 3),
                                    ),
                                ],
                              ),
                              child: Icon(icon, color: iconColor, size: 30),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                    child: beforeBurst
                        ? _Label(key: const ValueKey('locked'), text: 'LOCKED', state: PinState.locked)
                        : showUnlockedLabel
                            ? const _Label(key: ValueKey('unlocked'), text: 'UNLOCKED!', unlocked: true)
                            : _Label(key: const ValueKey('name'), text: widget.label, state: state),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _ring(double t, Color color) {
    return Container(
      width: MapPin.circle + 34 * t,
      height: MapPin.circle + 34 * t,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: (1 - t) * 0.8), width: 3),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({super.key, required this.text, this.state = PinState.current, this.unlocked = false});

  final String text;
  final PinState state;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final locked = state == PinState.locked;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: unlocked ? AppColors.success : (locked ? Colors.white.withValues(alpha: 0.7) : Colors.white),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: unlocked ? Colors.white : (state == PinState.current ? AppColors.gold : AppColors.parchmentDark),
          width: state == PinState.current || unlocked ? 2 : 1,
        ),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        maxLines: 2,
        style: AppText.style(
          AppText.heading,
          size: 12.5,
          weight: FontWeight.w600,
          color: unlocked ? Colors.white : (locked ? AppColors.muted : AppColors.navy),
          height: 1.1,
        ),
      ),
    );
  }
}

/// Soft golden light that brightens the pin as it unlocks.
class _Glow extends StatelessWidget {
  const _Glow({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final size = MapPin.circle + 70 * progress;
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.goldLight.withValues(alpha: 0.9 * (1 - progress)),
              AppColors.goldLight.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _Sparkles extends StatelessWidget {
  const _Sparkles({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        size: const Size.square(MapPin.circle + 36),
        painter: _SparklePainter(progress),
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  _SparklePainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final paint = Paint()..color = AppColors.gold.withValues(alpha: (1 - t).clamp(0, 1));
    for (var i = 0; i < 10; i++) {
      final a = i * math.pi / 5;
      final d = 20 + 34 * Curves.easeOut.transform(t);
      canvas.drawCircle(c + Offset(math.cos(a), math.sin(a)) * d, 4 * (1 - t) + 1, paint);
    }
  }

  @override
  bool shouldRepaint(_SparklePainter old) => old.t != t;
}
