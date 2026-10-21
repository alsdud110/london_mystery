import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/audio_service.dart' show TapRole;
import '../../../data/models/mission.dart';
import '../../../data/models/workshop_puzzles.dart';
import '../../../widgets/game_button.dart';
import '../../../widgets/ink_icon.dart';
import 'mark_compare.dart' show WorkshopChoice, WorkshopNote;
import 'river_papers.dart' show PictureCanvas, carved;
import 'workshop_papers.dart';

/// The wall of clocks ([ClockWallScene]): the four clocks, their hands drawn
/// on their dials; WATCH THE CLOCKS plays one minute of them in a few
/// seconds (with Reduce Motion, the minute is over at once), then says what
/// each one shows now; a tap on a clock looks at its back (kept looked at:
/// [onLooked]); the clock chosen goes to [onSubmit], checked as the
/// puzzle's answer. Watched once ([watched]), the minute stays watched.
class ClockWall extends StatefulWidget {
  const ClockWall({
    super.key,
    required this.scene,
    required this.mission,
    required this.watched,
    required this.looked,
    required this.onWatched,
    required this.onLooked,
    required this.onSubmit,
  });

  final ClockWallScene scene;
  final Mission mission;
  final bool watched;

  /// The clocks whose backs were looked at.
  final Set<String> looked;
  final VoidCallback onWatched;
  final ValueChanged<String> onLooked;
  final Future<void> Function(String answer) onSubmit;

  @override
  State<ClockWall> createState() => _ClockWallState();
}

class _ClockWallState extends State<ClockWall> with SingleTickerProviderStateMixin {
  late final AnimationController _minute = AnimationController(vsync: this, duration: widget.scene.watch, value: widget.watched ? 1 : 0)
    ..addStatusListener((s) {
      if (s == AnimationStatus.completed) _done();
    });
  bool _watching = false;
  String? _choice;
  bool _checking = false;

  ClockWallScene get _scene => widget.scene;

  void _done() {
    if (!mounted) return;
    setState(() => _watching = false);
    widget.onWatched();
  }

  void _watch() {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (still) {
      // No motion: the minute is over at once (the times before and after
      // are said under the clocks).
      _minute.value = 1;
      _done();
      return;
    }
    setState(() => _watching = true);
    _minute.forward(from: 0);
  }

  Future<void> _check() async {
    if (_checking || _choice == null) return;
    setState(() => _checking = true);
    try {
      await widget.onSubmit(_choice!);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _back(WallClock c) async {
    widget.onLooked(c.id);
    await showClockBack(context, scene: _scene, clock: c);
  }

  @override
  void dispose() {
    _minute.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final watched = widget.watched && !_watching;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // The repair card, read with the clocks.
        WorkshopNote(key: const ValueKey('repair-card-note'), intro: widget.mission.letterIntro, text: widget.mission.letter),
        const SizedBox(height: AppSpace.md),
        Text(
          watched ? _scene.chooseTask : _scene.watchTask,
          key: const ValueKey('clocks-task'),
          textAlign: TextAlign.center,
          style: AppText.subtitle(),
        ),
        const SizedBox(height: AppSpace.md),
        DecoratedBox(
          decoration: BoxDecoration(boxShadow: AppShadow.paperLift, borderRadius: BorderRadius.circular(AppRadius.paper)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.paper),
            child: Semantics(
              label: '${_scene.place}. ${[for (final c in _scene.clocks) '${c.name} shows ${clockTime(watched ? c.after : c.shows)}'].join('. ')}.',
              excludeSemantics: true,
              child: AnimatedBuilder(
                animation: _minute,
                builder: (context, _) => CroppedPicture(
                  file: _scene.wall,
                  pixels: _scene.pixels,
                  crop: _scene.view,
                  child: Stack(
                    children: [
                      // The hands and the plates, under the taps.
                      for (final c in _scene.clocks) ...[
                        Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: ClockHandsPainter(clock: c, t: _minute.value)))),
                        Positioned.fromRect(
                          rect: _px(c.plateAt),
                          child: Center(child: Text(c.numeral, key: ValueKey('clock-plate-${c.id}'), style: carved(40, color: AppColors.walnutDeep))),
                        ),
                      ],
                      for (final c in _scene.clocks) ...[
                        Positioned.fromRect(
                          rect: _px(c.area),
                          child: _ClockSpot(
                            key: ValueKey('clock-spot-${c.id}'),
                            clock: c,
                            looked: widget.looked.contains(c.id),
                            onTap: () => _back(c),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.md),
        if (_watching)
          Text(
            'Watch the hands…',
            key: const ValueKey('clocks-watching'),
            textAlign: TextAlign.center,
            style: AppText.title(size: 20),
          )
        else if (watched) ...[
          Text(_scene.later, key: const ValueKey('clocks-later'), textAlign: TextAlign.center, style: AppText.title(size: 22)),
          const SizedBox(height: AppSpace.sm),
          for (final c in _scene.clocks) _TimeRow(clock: c),
        ],
        const SizedBox(height: AppSpace.sm),
        GameButton(
          key: const ValueKey('clocks-watch'),
          label: widget.watched ? _scene.againLabel : _scene.watchLabel,
          glyph: InkGlyph.clock,
          style: widget.watched ? GameButtonStyle.outline : GameButtonStyle.navy,
          tap: widget.watched ? TapRole.secondary : TapRole.primary,
          onPressed: _watching ? null : _watch,
        ),
        const SizedBox(height: AppSpace.sm),
        Text(_scene.backTask, textAlign: TextAlign.center, style: AppText.aside()),
        const SizedBox(height: AppSpace.md),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpace.sm,
          crossAxisSpacing: AppSpace.sm,
          childAspectRatio: 3.0,
          children: [
            for (final o in widget.mission.options)
              WorkshopChoice(key: ValueKey('clock-${o.id}'), label: o.label, selected: _choice == o.id, onTap: () => setState(() => _choice = o.id)),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        GameButton(
          key: const ValueKey('clocks-check'),
          label: _scene.chooseLabel,
          glyph: InkGlyph.check,
          tap: TapRole.primary,
          onPressed: _choice != null && !_checking && !_watching ? _check : null,
        ),
      ],
    );
  }

  Rect _px(Rect f) => Rect.fromLTRB(f.left * _scene.pixels.width, f.top * _scene.pixels.height, f.right * _scene.pixels.width, f.bottom * _scene.pixels.height);
}

/// What a clock showed, and shows one minute later.
class _TimeRow extends StatelessWidget {
  const _TimeRow({required this.clock});

  final WallClock clock;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Semantics(
      label: '${clock.name}: it was ${clockTime(clock.shows)}, now ${clockTime(clock.after)}.',
      excludeSemantics: true,
      child: Row(
        key: ValueKey('clock-time-${clock.id}'),
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(width: 104, child: Text(clock.name, style: AppText.mark(color: AppColors.navy, size: 16))),
          Text('was ${clockTime(clock.shows)}', style: AppText.bodyText(size: 17)),
          const SizedBox(width: AppSpace.md),
          Text('now ${clockTime(clock.after)}', style: AppText.bodyText(size: 17, weight: FontWeight.w700)),
        ],
      ),
    ),
  );
}

class _ClockSpot extends StatelessWidget {
  const _ClockSpot({super.key, required this.clock, required this.looked, required this.onTap});

  final WallClock clock;
  final bool looked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '${clock.name}${looked ? ', its back looked at' : ''}. Tap to look at its back.',
    excludeSemantics: true,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: CircleAvatar(
            radius: 30,
            backgroundColor: AppColors.navyDeep.withValues(alpha: 0.8),
            child: InkIcon(looked ? InkGlyph.check : InkGlyph.search, size: 34, color: AppColors.goldLight),
          ),
        ),
      ),
    ),
  );
}

/// A wall clock's hands at [t] of the minute watched (0: as found, 1: one
/// minute later): the hour and minute hands, and the seconds hand, which
/// goes round once for each minute the clock moves (five times on a fast
/// clock, once backwards on one that turns back, not at all on a stopped
/// one). Drawn in the wall's own pixels.
class ClockHandsPainter extends CustomPainter {
  const ClockHandsPainter({required this.clock, required this.t});

  final WallClock clock;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final minutes = clock.shows + clock.change * t;
    final r = clock.radius;
    final c = clock.centre;
    void hand(double turns, double length, double width, Color color, {double tail = 0}) {
      final a = turns * 2 * math.pi - math.pi / 2;
      final dir = Offset(math.cos(a), math.sin(a));
      canvas.drawLine(
        c - dir * tail,
        c + dir * length,
        Paint()
          ..color = color
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round,
      );
    }

    final shade = Paint()..color = AppColors.navyDeep.withValues(alpha: 0.25);
    canvas.save();
    canvas.translate(1.5, 2);
    hand(minutes / 720, r * 0.5, r * 0.085, shade.color);
    hand(minutes / 60, r * 0.78, r * 0.06, shade.color);
    canvas.restore();
    hand(minutes / 720, r * 0.5, r * 0.085, AppColors.walnutDeep);
    hand(minutes / 60, r * 0.78, r * 0.06, AppColors.walnutDeep);
    hand(clock.change * t, r * 0.84, r * 0.025, AppColors.burgundy, tail: r * 0.18);
    canvas.drawCircle(c, r * 0.07, Paint()..color = AppColors.walnutDeep);
  }

  @override
  bool shouldRepaint(ClockHandsPainter old) => old.t != t || old.clock != clock;
}

/// A clock up close: its dial as it is now, and its back.
Future<void> showClockBack(BuildContext context, {required ClockWallScene scene, required WallClock clock}) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: AppColors.navyDeep.withValues(alpha: 0.94),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim, _) => FadeTransition(
        opacity: anim,
        child: Material(
          type: MaterialType.transparency,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpace.lg),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('THE BACK OF ${clock.name}', key: const ValueKey('clock-back-title'), style: AppText.mark(color: AppColors.goldLight)),
                      const SizedBox(height: AppSpace.md),
                      ConstrainedBox(
                        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.5),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.paper),
                          child: Semantics(
                            image: true,
                            label: clock.backLabel,
                            excludeSemantics: true,
                            child: PictureCanvas(
                              key: ValueKey('clock-back-${clock.id}'),
                              pixels: scene.backPixels,
                              child: Image.asset(clock.back, fit: BoxFit.fill, excludeFromSemantics: true),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpace.md),
                      ExcludeSemantics(
                        child: Text(clock.backNote, key: const ValueKey('clock-back-note'), textAlign: TextAlign.center, style: AppText.title(size: 21, color: AppColors.goldLight)),
                      ),
                      const SizedBox(height: AppSpace.lg),
                      Builder(
                        builder: (context) => GameButton(
                          key: const ValueKey('clock-back-done'),
                          label: 'BACK TO THE WALL',
                          style: GameButtonStyle.glass,
                          onPressed: () => Navigator.of(context).pop(),
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
    ),
  );
}
