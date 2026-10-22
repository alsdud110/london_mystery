import 'dart:math' as math;

import 'package:flutter/gestures.dart' show DragStartBehavior;
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/audio_service.dart' show TapRole;
import '../../../data/models/mission.dart';
import '../../../data/models/opera_puzzles.dart';
import '../../../widgets/game_button.dart';
import '../../../widgets/ink_icon.dart';
import 'opera_papers.dart';

/// M1, the archive table ([ShowStripScene]): FILE 3 and FILE 4 (a tap
/// reads either up close), and the show's strip on the clock. The strip is
/// as long as the show and never changes length: it is dragged, or moved
/// with ◀ ▶, ten minutes at a time; its START and END say where it is. The
/// clock shows FILE 3's DOORS OPEN, its CURTAIN UP and its CURTAIN DOWN.
/// CHECK sends what the start says ([ShowStrip.verdict]) as the answer.
class ShowStripPuzzle extends StatefulWidget {
  const ShowStripPuzzle({super.key, required this.scene, required this.mission, required this.onSubmit});

  final ShowStripScene scene;
  final Mission mission;
  final Future<void> Function(String answer) onSubmit;

  @override
  State<ShowStripPuzzle> createState() => _ShowStripPuzzleState();
}

class _ShowStripPuzzleState extends State<ShowStripPuzzle> {
  late int _start = widget.scene.strip.initial;
  bool _checking = false;

  ShowStrip get _strip => widget.scene.strip;

  void _move(int start) {
    final s = _strip.snap(start);
    if (s != _start) setState(() => _start = s);
  }

  Future<void> _check() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      await widget.onSubmit(_strip.verdict(_start).name);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _open(String title, Widget paper) => showOperaCloser<void>(context, title: title, child: paper, closeLabel: 'BACK TO THE TABLE', closeKey: const ValueKey('paper-done'));

  @override
  Widget build(BuildContext context) {
    final scene = widget.scene;
    final strip = _strip;
    final r = scene.record;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PaperRow(
          key: const ValueKey('paper-file3'),
          thumb: OfficeRecordView(record: r, semantics: false),
          aspect: r.pixels.aspect,
          heading: 'FILE 3 · OFFICE RECORD',
          lines: [for (final row in r.rows) '${row.label} ${row.time}'],
          onOpen: () => _open('FILE 3 · THE OFFICE RECORD', OfficeRecordView(record: r)),
        ),
        const SizedBox(height: AppSpace.sm),
        _PaperRow(
          key: const ValueKey('paper-file4'),
          thumb: ExcludeSemantics(child: ProgrammeView(page: scene.programme)),
          aspect: scene.programme.pixels.aspect,
          heading: 'FILE 4 · THE PROGRAMME',
          lines: [
            [for (final p in strip.parts) '${p.name} ${p.minutes}'].join(' · '),
            scene.programme.whole.replaceAll('\n', ' '),
          ],
          onOpen: () => _open('FILE 4 · THE PROGRAMME', ProgrammeView(page: scene.programme)),
        ),
        const SizedBox(height: AppSpace.lg),
        Text(
          scene.task,
          key: const ValueKey('strip-task'),
          textAlign: TextAlign.center,
          style: AppText.bodyText(size: 16, weight: FontWeight.w600, color: AppColors.navy).copyWith(height: 1.35),
        ),
        const SizedBox(height: AppSpace.md),
        MediaQuery.withClampedTextScaling(
          maxScaleFactor: 1.15,
          child: _Timeline(scene: scene, start: _start, onMove: _move),
        ),
        const SizedBox(height: AppSpace.md),
        Row(
          children: [
            _StepButton(
              key: const ValueKey('strip-earlier'),
              glyph: InkGlyph.back,
              label: 'Ten minutes earlier',
              onPressed: _start > strip.earliest ? () => _move(_start - strip.step) : null,
            ),
            const SizedBox(width: AppSpace.sm),
            Expanded(
              child: GameButton(
                key: const ValueKey('strip-check'),
                label: scene.checkLabel,
                glyph: InkGlyph.check,
                style: GameButtonStyle.navy,
                tap: TapRole.primary,
                singleLine: true,
                onPressed: _checking ? null : _check,
              ),
            ),
            const SizedBox(width: AppSpace.sm),
            _StepButton(
              key: const ValueKey('strip-later'),
              glyph: InkGlyph.arrow,
              label: 'Ten minutes later',
              onPressed: _start < strip.latest ? () => _move(_start + strip.step) : null,
            ),
          ],
        ),
      ],
    );
  }
}

/// A file on the table: small, beside what it says; a tap reads it up
/// close.
class _PaperRow extends StatelessWidget {
  const _PaperRow({super.key, required this.thumb, required this.aspect, required this.heading, required this.lines, required this.onOpen});

  final Widget thumb;
  final double aspect;
  final String heading;
  final List<String> lines;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '$heading. ${lines.join('. ')}. Tap to read it closer.',
    excludeSemantics: true,
    child: Material(
      color: AppColors.paperLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.paper),
        side: BorderSide(color: AppLine.faint(0.3), width: AppLine.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.sm),
          child: Row(
            children: [
              SizedBox(width: 50, child: AspectRatio(aspectRatio: aspect, child: thumb)),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(heading, style: AppText.eyebrow()),
                    const SizedBox(height: 2),
                    for (final l in lines) Text(l, style: AppText.bodyText(size: 14, weight: FontWeight.w700).copyWith(height: 1.3)),
                  ],
                ),
              ),
              const InkIcon(InkGlyph.search, size: AppIconSize.small, color: AppColors.goldDeep),
            ],
          ),
        ),
      ),
    ),
  );
}

/// A square ◀ or ▶ beside CHECK.
class _StepButton extends StatelessWidget {
  const _StepButton({super.key, required this.glyph, required this.label, required this.onPressed});

  final InkGlyph glyph;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final on = onPressed != null;
    return Semantics(
      button: true,
      enabled: on,
      label: label,
      excludeSemantics: true,
      child: SizedBox(
        width: 56,
        height: 56,
        child: Material(
          color: on ? AppColors.paper : AppColors.parchment,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
            side: BorderSide(color: on ? AppColors.gold : AppColors.parchmentDark, width: AppLine.rule),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.button),
            onTap: onPressed,
            child: Center(child: InkIcon(glyph, size: AppIconSize.regular, color: on ? AppColors.navy : AppColors.locked)),
          ),
        ),
      ),
    );
  }
}

/// The clock from 2:30 to 6:30, FILE 3's three times pinned on it, and the
/// show's strip under it.
class _Timeline extends StatefulWidget {
  const _Timeline({required this.scene, required this.start, required this.onMove});

  final ShowStripScene scene;
  final int start;
  final ValueChanged<int> onMove;

  /// Heights of its rows, top to bottom.
  static const pinRow = 18.0;
  static const axisAt = 66.0;
  static const stripTop = 92.0;
  static const stripHeight = 44.0;
  static const height = 190.0;

  @override
  State<_Timeline> createState() => _TimelineState();
}

class _TimelineState extends State<_Timeline> {
  /// The drag: where it started, and the start then; while held, the strip
  /// is lifted off the page.
  double _dragX = 0;
  int _dragFrom = 0;
  bool _held = false;

  @override
  Widget build(BuildContext context) {
    final scene = widget.scene;
    final strip = scene.strip;
    return LayoutBuilder(
      builder: (context, box) {
        // A little room at each end, so the end labels are never cut.
        const pad = 14.0;
        final width = box.maxWidth;
        final k = (width - 2 * pad) / (strip.to - strip.from);
        double x(int minutes) => pad + (minutes - strip.from) * k;
        final start = widget.start;
        final end = strip.endOf(start);
        final label = AppText.style(AppText.body, size: 11.5, weight: FontWeight.w700, letterSpacing: 0.6, color: AppColors.ink);

        // A pin's label, beside its pin: to its right, or (near the end of
        // the clock) to its left.
        Widget pinLabel(int at, int row, String text, Color color, {required bool right, required Key key}) {
          final px = x(at);
          return Positioned(
            key: key,
            top: row * _Timeline.pinRow,
            left: right ? px + 4 : 0,
            right: right ? 0 : width - px + 4,
            height: _Timeline.pinRow,
            child: Align(
              alignment: right ? Alignment.centerLeft : Alignment.centerRight,
              child: FittedBox(fit: BoxFit.scaleDown, child: Text(text, style: label.copyWith(color: color))),
            ),
          );
        }

        final stripLeft = x(start);
        final stripWidth = strip.length * k;
        return Semantics(
          slider: true,
          label: 'The show strip',
          value: 'Starts at ${clockOf(start)}, ends at ${clockOf(end)}',
          increasedValue: start < strip.latest ? 'Starts at ${clockOf(start + strip.step)}' : null,
          decreasedValue: start > strip.earliest ? 'Starts at ${clockOf(start - strip.step)}' : null,
          onIncrease: start < strip.latest ? () => widget.onMove(start + strip.step) : null,
          onDecrease: start > strip.earliest ? () => widget.onMove(start - strip.step) : null,
          child: SizedBox(
            key: const ValueKey('strip-timeline'),
            height: _Timeline.height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _ClockPainter(
                      strip: strip,
                      x: x,
                      pins: [
                        (strip.officeStart, 0, AppColors.muted, true),
                        (strip.doorsOpen, 1, AppColors.goldDeep, false),
                        (strip.curtainDown, 2, AppColors.burgundy, false),
                      ],
                    ),
                  ),
                ),
                // FILE 3's three times, each on its own row.
                pinLabel(strip.officeStart, 0, 'FILE 3: CURTAIN UP ${clockOf(strip.officeStart)}', AppColors.muted, right: true, key: const ValueKey('pin-office')),
                pinLabel(strip.doorsOpen, 1, 'DOORS OPEN ${clockOf(strip.doorsOpen)}', AppColors.goldDeep, right: true, key: const ValueKey('pin-doors')),
                pinLabel(strip.curtainDown, 2, 'CURTAIN DOWN ${clockOf(strip.curtainDown)}', AppColors.burgundy, right: false, key: const ValueKey('pin-down')),
                // The hours under the clock's line.
                for (var h = (strip.from + 59) ~/ 60 * 60; h <= strip.to; h += 60)
                  Positioned(
                    left: x(h) - 24,
                    width: 48,
                    top: _Timeline.axisAt + 6,
                    // On a dab of paper, so a pin's line never runs through it.
                    child: Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: AppColors.paper, borderRadius: BorderRadius.circular(3)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Text(clockOf(h), textAlign: TextAlign.center, style: label.copyWith(color: AppColors.navy, fontSize: 12.5)),
                        ),
                      ),
                    ),
                  ),
                // The strip: dragged along the clock.
                AnimatedPositioned(
                  duration: MediaQuery.disableAnimationsOf(context) ? Duration.zero : const Duration(milliseconds: 140),
                  curve: Curves.easeOut,
                  left: stripLeft,
                  width: stripWidth,
                  top: _Timeline.stripTop,
                  height: _Timeline.stripHeight,
                  child: GestureDetector(
                    key: const ValueKey('show-strip'),
                    behavior: HitTestBehavior.opaque,
                    // It moves with the finger from where it is touched.
                    dragStartBehavior: DragStartBehavior.down,
                    onHorizontalDragStart: (d) {
                      _dragX = 0;
                      _dragFrom = start;
                      setState(() => _held = true);
                    },
                    onHorizontalDragUpdate: (d) {
                      _dragX += d.delta.dx;
                      widget.onMove(strip.snap(_dragFrom + _dragX / k));
                    },
                    onHorizontalDragEnd: (_) => setState(() => _held = false),
                    onHorizontalDragCancel: () => setState(() => _held = false),
                    child: AnimatedScale(
                      scale: _held ? 1.04 : 1,
                      duration: const Duration(milliseconds: 120),
                      child: DecoratedBox(
                        decoration: BoxDecoration(boxShadow: _held ? AppShadow.pinned : const []),
                        child: _StripPaper(scene: scene, k: k),
                      ),
                    ),
                  ),
                ),
                // START and END under the strip's ends; never off the clock.
                _flag('START', stripLeft, width, label, const ValueKey('flag-start')),
                _flag('END', stripLeft + stripWidth, width, label, const ValueKey('flag-end')),
                Positioned(
                  left: 0,
                  right: 0,
                  top: _Timeline.stripTop + _Timeline.stripHeight + 22,
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'START '),
                        TextSpan(text: clockPm(start), style: const TextStyle(color: AppColors.navy)),
                        const TextSpan(text: '     END '),
                        TextSpan(text: clockPm(end), style: TextStyle(color: end == strip.curtainDown ? AppColors.success : AppColors.navy)),
                      ],
                    ),
                    key: const ValueKey('strip-readout'),
                    textAlign: TextAlign.center,
                    style: AppText.style(AppText.body, size: 17, weight: FontWeight.w700, color: AppColors.muted, letterSpacing: 0.8),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _flag(String text, double at, double width, TextStyle style, Key key) {
    const w = 44.0;
    final left = (at - w / 2).clamp(0.0, math.max(0.0, width - w)).toDouble();
    return Positioned(
      key: key,
      left: left,
      width: w,
      top: _Timeline.stripTop + _Timeline.stripHeight + 3,
      height: 16,
      child: FittedBox(fit: BoxFit.scaleDown, child: Text(text, style: style.copyWith(color: AppColors.navy))),
    );
  }
}

/// The show's strip: the paper strip (its printed edges kept their size),
/// its parts marked off and their minutes written in them.
class _StripPaper extends StatelessWidget {
  const _StripPaper({required this.scene, required this.k});

  final ShowStripScene scene;

  /// Screen pixels a minute.
  final double k;

  @override
  Widget build(BuildContext context) {
    final strip = scene.strip;
    final paper = scene.stripPaper;
    final pixels = scene.stripPixels;
    // The picture drawn at a quarter of its size: its edges and flourishes
    // keep that size; only the middle stretches. Its clear margin is drawn
    // outside the strip.
    const scale = 4.0;
    // Where each part starts, minutes into the show.
    final starts = [for (var i = 0, m = 0; i < strip.parts.length; m += strip.parts[i].minutes, i++) m];
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: -paper.left / scale,
          top: -paper.top / scale,
          right: -(pixels.width - paper.right) / scale,
          bottom: -(pixels.height - paper.bottom) / scale,
          child: Image.asset(
            scene.stripFile,
            scale: scale,
            centerSlice: scene.stripSlice,
            fit: BoxFit.fill,
            excludeFromSemantics: true,
          ),
        ),
        for (final (i, p) in strip.parts.indexed)
          Positioned(
            key: ValueKey('strip-part-$i'),
            left: starts[i] * k,
            width: p.minutes * k,
            top: 5,
            bottom: 5,
            // Printed on the strip: a dotted line between two parts (no
            // coloured box), its name and minutes in the programme's ink.
            child: CustomPaint(
              painter: _Perforation(first: i == 0),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (p.minutes * k >= 40)
                        Text(p.name, style: AppText.style(AppText.body, size: 9, weight: FontWeight.w700, color: const Color(0xCC5C4630), letterSpacing: 0.4)),
                      Text('${p.minutes}', style: AppText.style(AppText.body, size: 13, weight: FontWeight.w800, color: const Color(0xE02A211B))),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A dotted line printed across the strip at a part's start.
class _Perforation extends CustomPainter {
  _Perforation({required this.first});

  final bool first;

  @override
  void paint(Canvas canvas, Size size) {
    if (first) return;
    final ink = Paint()
      ..color = const Color(0xB05C4630)
      ..strokeWidth = 1.4;
    for (var y = 1.0; y < size.height; y += 5) {
      canvas.drawLine(Offset(0, y), Offset(0, y + 2.5), ink);
    }
  }

  @override
  bool shouldRepaint(_Perforation old) => old.first != first;
}

/// The clock's line, its ticks, and FILE 3's pins down to the strip.
class _ClockPainter extends CustomPainter {
  _ClockPainter({required this.strip, required this.x, required this.pins});

  final ShowStrip strip;
  final double Function(int minutes) x;

  /// Each pin: its time, its label's row, its colour, dashed (a claim).
  final List<(int, int, Color, bool)> pins;

  @override
  void paint(Canvas canvas, Size size) {
    const axis = _Timeline.axisAt;
    final line = Paint()
      ..color = AppColors.navy
      ..strokeWidth = 2;
    canvas.drawLine(Offset(x(strip.from), axis), Offset(x(strip.to), axis), line);
    for (var m = strip.from; m <= strip.to; m += strip.step) {
      final tall = m % 60 == 0 ? 9.0 : m % 30 == 0 ? 6.0 : 3.0;
      canvas.drawLine(Offset(x(m), axis - tall), Offset(x(m), axis + tall), line..strokeWidth = m % 60 == 0 ? 2 : 1.2);
    }
    const bottom = _Timeline.stripTop + _Timeline.stripHeight + 2;
    for (final (at, row, colour, dashed) in pins) {
      final top = row * _Timeline.pinRow + 2;
      final p = Paint()
        ..color = colour
        ..strokeWidth = 2;
      if (dashed) {
        for (var y = top; y < bottom; y += 7) {
          canvas.drawLine(Offset(x(at), y), Offset(x(at), math.min(y + 4, bottom)), p);
        }
      } else {
        canvas.drawLine(Offset(x(at), top), Offset(x(at), bottom), p);
      }
      canvas.drawCircle(Offset(x(at), top + 2), 3.5, p);
    }
  }

  @override
  bool shouldRepaint(_ClockPainter old) => old.strip != strip || old.x(strip.from) != x(strip.from) || old.x(strip.to) != x(strip.to);
}
