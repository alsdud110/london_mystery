import 'dart:math' as math;
import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/models/episode.dart';
import '../../../widgets/art_assets.dart';
import '../../../widgets/ink_icon.dart';
import '../../../widgets/paper.dart';
import '../../../widgets/place_art.dart';
import '../season_overview.dart';
import 'season_props.dart';

/// The detective's investigation board for the season: an old London map in
/// a walnut frame, the photo of every solved case pinned to it with its
/// number tag, red thread along the trail, and in the middle whoever is
/// behind it all — as far as the story has told.
///
/// Everything on it comes from [overview]: nothing is painted in advance,
/// so it grows as cases are solved. While [before] is given, [t] (0 → 1)
/// plays what changed since then: the new photo, its pin, its thread, its
/// tag, then the next case and the figure in the middle.
class InvestigationBoard extends StatelessWidget {
  const InvestigationBoard({super.key, required this.overview, this.before, this.t = 1, required this.onCase});

  final SeasonOverview overview;
  final SeasonOverview? before;
  final double t;

  /// A case on the board was tapped (by its index in the season).
  final ValueChanged<int> onCase;

  /// The walnut frame around the board.
  static const frame = 6.0;

  /// Part [a]..[b] of the reveal, eased.
  double _iv(double a, double b) => Curves.easeOutCubic.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        // Never taller than a tall sheet: on a tall phone the board keeps
        // its shape and sits in the middle of the space.
        final outer = Size(box.maxWidth, math.min(box.maxHeight, box.maxWidth * 1.4));
        final size = Size(outer.width - 2 * frame, outer.height - 2 * frame);
        final layout = BoardLayout(size, overview.total);
        return Center(
          child: Container(
            width: outer.width,
            height: outer.height,
            padding: const EdgeInsets.all(frame),
            decoration: BoxDecoration(
              color: AppColors.walnutDeep,
              borderRadius: BorderRadius.circular(AppRadius.paper),
              border: Border.all(color: AppColors.goldLight.withValues(alpha: 0.18), width: AppLine.hairline),
              boxShadow: AppShadow.onNight,
            ),
            child: ClipRect(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Positioned.fill(child: MapPrint(strength: 0.62)),
                  // The lamp falls on the middle of the board; its edges are in shadow.
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          radius: 0.85,
                          colors: [Colors.transparent, Color(0x661B130D)],
                          stops: [0.55, 1],
                        ),
                      ),
                    ),
                  ),
                  ..._scraps(layout),
                  Positioned.fill(
                    child: CustomPaint(painter: _ThreadPainter(layout: layout, threads: _threads())),
                  ),
                  _figure(layout),
                  for (var i = 0; i < overview.total; i++) _case(layout, i),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Blank notes and a postmark left on the board between the cases: the
  /// clutter of a long investigation. They say nothing.
  List<Widget> _scraps(BoardLayout layout) {
    final s = layout.size;
    final n = layout.node;
    Widget at(double fx, double fy, Widget child, double tilt) => Positioned(
          left: s.width * fx - n.width * 0.4,
          top: s.height * fy - n.height * 0.35,
          child: IgnorePointer(child: Transform.rotate(angle: tilt, child: child)),
        );
    return [
      at(0.27, 0.29, _Scrap(Size(n.width * 0.85, n.height * 0.62)), -0.14),
      at(0.73, 0.73, _Scrap(Size(n.width * 0.8, n.height * 0.7), lines: 4), 0.1),
      at(0.3, 0.72, _Postmark(n.height * 0.62), -0.3),
    ];
  }

  /// Every thread with how far it is drawn (0..1) and how strongly.
  List<(BoardThread, double, double)> _threads() {
    final now = overview.threads;
    final was = {for (final th in before?.threads ?? now) th.id};
    final nowIds = {for (final th in now) th.id};
    return [
      for (final th in now)
        (
          th,
          was.contains(th.id)
              ? 1.0
              : switch (th.kind) {
                  ThreadKind.chain => _iv(0.3, 0.6),
                  ThreadKind.spoke => _iv(0.45, 0.75),
                  ThreadKind.lead => _iv(0.55, 0.8),
                },
          1.0,
        ),
      // A lead that is now a solved trail fades away as the trail is drawn.
      if (before != null)
        for (final th in before!.threads)
          if (!nowIds.contains(th.id)) (th, 1.0, 1 - _iv(0, 0.3)),
    ];
  }

  Widget _case(BoardLayout layout, int i) {
    final e = overview.cases[i];
    final mark = overview.marks[i];
    final was = before?.marks[i] ?? mark;
    final slot = layout.slot(i);
    final n = layout.node;

    Widget child;
    if (mark == CaseMark.solved && was != CaseMark.solved) {
      // Just solved: the photo settles, then its pin, then its tag.
      final photo = _iv(0, 0.3);
      child = Stack(
        clipBehavior: Clip.none,
        children: [
          if (photo < 1) Opacity(opacity: 1 - photo, child: _CaseNote(e, was, n)),
          if (photo > 0)
            Opacity(
              opacity: photo,
              child: Transform.scale(
                scale: 1.08 - 0.08 * photo,
                child: _CasePhoto(e, n, pin: _iv(0.2, 0.4), tag: _iv(0.5, 0.7)),
              ),
            ),
        ],
      );
    } else if (was != mark) {
      // The case it opens follows.
      final p = _iv(0.45, 0.65);
      child = p >= 1
          ? _CaseNote(e, mark, n)
          : Stack(
              clipBehavior: Clip.none,
              children: [
                Opacity(opacity: 1 - p, child: _CaseNote(e, was, n)),
                if (p > 0) Opacity(opacity: p, child: _CaseNote(e, mark, n)),
              ],
            );
    } else {
      child = mark == CaseMark.solved ? _CasePhoto(e, n) : _CaseNote(e, mark, n);
    }

    final status = switch (mark) {
      CaseMark.solved => 'solved',
      CaseMark.current => 'current case',
      CaseMark.open => 'open',
      CaseMark.sealed => 'sealed',
    };
    return Positioned(
      key: ValueKey('board-${e.id}'),
      left: slot.center.dx - n.width / 2,
      top: slot.center.dy - n.height / 2,
      width: n.width,
      height: n.height,
      child: Semantics(
        button: true,
        // A sealed case says only that it is sealed.
        label: mark == CaseMark.sealed ? 'Case ${e.numberLabel}, $status' : 'Case ${e.numberLabel}, ${e.title}, $status',
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onCase(i),
          child: Transform.rotate(angle: slot.tilt, child: child),
        ),
      ),
    );
  }

  Widget _figure(BoardLayout layout) {
    final now = overview.figure;
    final was = before == null ? now : before!.figure;
    final rect = layout.figure;
    Widget note(SeasonFigureView v) => _FigureNote(view: v, size: rect.size, closed: overview.complete);
    final view = SeasonFigureView.of(overview);
    Widget child = note(view);
    if (was?.figure != now?.figure) {
      final p = _iv(0.6, 0.88);
      if (p <= 0) {
        child = note(SeasonFigureView.of(before!));
      } else if (p < 1) {
        child = Stack(
          children: [
            Opacity(opacity: 1 - p, child: note(SeasonFigureView.of(before!))),
            Opacity(opacity: p, child: Transform.scale(scale: 0.94 + 0.06 * p, child: child)),
          ],
        );
      }
    }
    final stamp = overview.complete ? (before != null && !before!.complete ? _iv(0.85, 1) : 1.0) : 0.0;
    return Positioned.fromRect(
      key: const ValueKey('board-figure'),
      rect: rect,
      child: Semantics(
        label: view.semantics,
        excludeSemantics: true,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: Transform.rotate(angle: -0.02, child: child)),
            if (stamp > 0)
              // Pressed on the corner of the note, clear of the picture and its name.
              Positioned(
                right: -AppSpace.lg,
                bottom: -AppSpace.md,
                child: Opacity(
                  opacity: stamp,
                  child: Transform.scale(scale: 1.3 - 0.3 * stamp, child: const InkStamp('CLOSED', size: 11)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Where everything sits on a board of [size]: the cases around a ring, in
/// order from the top (the last case comes round to the top and closes it),
/// and the figure in the middle. Fractions of the size, so the board fits
/// any phone; spaced by length along the ring, so a wide board does not
/// crowd its sides. Prints are large enough to overlap a little, as on a
/// real board.
class BoardLayout {
  BoardLayout(this.size, this.count) {
    final h = (math.sqrt(size.width * size.height) * 0.19).clamp(40.0, 96.0);
    node = Size(h * 1.1, h);
    final fw = (math.min(size.width, size.height) * 0.38).clamp(96.0, 180.0);
    final fh = math.min(fw * 1.0, size.height - 2 * node.height - AppSpace.sm);
    figure = Rect.fromCenter(center: size.center(Offset.zero), width: fw, height: fh);
    _slots = _ring();
  }

  final Size size;
  final int count;
  late final Size node;
  late final Rect figure;
  late final List<({Offset center, double tilt})> _slots;

  /// Case [i]: where its middle is and how it is turned.
  ({Offset center, double tilt}) slot(int i) => _slots[i];

  /// Where a thread is tied: the pin at the top of a case.
  Offset pinOf(int i) => _slots[i].center.translate(0, -node.height / 2 + 3);

  /// The pin of the figure in the middle.
  Offset get figurePin => figure.topCenter.translate(0, 5);

  List<({Offset center, double tilt})> _ring() {
    const edge = AppSpace.xs;
    final rx = size.width / 2 - node.width / 2 - edge;
    final ry = size.height / 2 - node.height / 2 - edge;
    final c = size.center(Offset.zero);
    // A rounded square ring (superellipse), traced clockwise from the top.
    Offset at(double a) {
      final x = math.cos(a), y = math.sin(a);
      return c + Offset(rx * x.sign * math.sqrt(x.abs()), ry * y.sign * math.sqrt(y.abs()));
    }

    const steps = 720;
    final points = [for (var k = 0; k <= steps; k++) at(-math.pi / 2 + 2 * math.pi * k / steps)];
    final lengths = [0.0];
    for (var k = 1; k < points.length; k++) {
      lengths.add(lengths.last + (points[k] - points[k - 1]).distance);
    }
    final total = lengths.last;
    Offset along(double s) {
      var k = 1;
      while (k < lengths.length - 1 && lengths[k] < s) {
        k++;
      }
      final f = (s - lengths[k - 1]) / math.max(lengths[k] - lengths[k - 1], 1e-6);
      return Offset.lerp(points[k - 1], points[k], f)!;
    }

    return [
      for (var i = 0; i < count; i++)
        () {
          // Case 1 just after the top, the last case at the top.
          final p = along(total * ((i + 1) % count) / count);
          // Pinned by hand: a little off the line, a little turned.
          final dx = node.width * 0.08 * math.sin(i * 2.3 + 0.4);
          final dy = node.height * 0.08 * math.cos(i * 1.7);
          final x = (p.dx + dx).clamp(node.width / 2 + 1, size.width - node.width / 2 - 1);
          final y = (p.dy + dy).clamp(node.height / 2 + 1, size.height - node.height / 2 - 1);
          return (center: Offset(x, y), tilt: 0.09 * math.sin(i * 3.1 + 1));
        }(),
    ];
  }
}

/// A solved case: its photo (the scene of the case's final mission, as on
/// the Case Closed file), a red pin, and its number on a paper tag.
/// [pin] and [tag] (0..1) bring those in when the case has just been solved.
class _CasePhoto extends StatelessWidget {
  const _CasePhoto(this.episode, this.size, {this.pin = 1, this.tag = 1});

  final Episode episode;
  final Size size;
  final double pin;
  final double tag;

  @override
  Widget build(BuildContext context) {
    final pinSize = (size.height * 0.17).clamp(8.0, 13.0);
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        SizedBox.fromSize(size: size, child: PhotoPrint(PlaceArt.sceneOf(episode.finalMission), border: math.max(2.5, size.height * 0.05))),
        if (tag > 0)
          Positioned(
            left: -size.width * 0.08,
            bottom: -size.height * 0.1,
            child: Opacity(
              opacity: tag,
              child: Transform.rotate(
                angle: -0.12,
                child: PaperTag(episode.numberLabel, size: (size.height * 0.15).clamp(9.0, 12.0)),
              ),
            ),
          ),
        if (pin > 0)
          Positioned(
            top: -pinSize * 0.3 - 6 * (1 - pin),
            child: Opacity(opacity: pin, child: PushPin(size: pinSize)),
          ),
      ],
    );
  }
}

/// A case not solved yet. The current case is a blank note with a question
/// on it and a red pin; a sealed case is a sealed envelope (nothing of it
/// shows); with operator access, an open case is a plain note.
class _CaseNote extends StatelessWidget {
  const _CaseNote(this.episode, this.mark, this.size);

  final Episode episode;
  final CaseMark mark;
  final Size size;

  @override
  Widget build(BuildContext context) {
    final tagSize = (size.height * 0.15).clamp(9.0, 12.0);
    if (mark == CaseMark.sealed) {
      // Smaller and fainter: the photos and the current case lead the eye.
      return Transform.scale(
        scale: 0.82,
        child: Opacity(
          opacity: 0.78,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(size: size, painter: const _EnvelopePainter()),
              Align(
                alignment: const Alignment(0, 0.15),
                child: Container(
                  width: size.height * 0.2,
                  height: size.height * 0.2,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.leather.withValues(alpha: 0.8)),
                ),
              ),
              Positioned(
                left: AppSpace.xs,
                bottom: AppSpace.xs,
                child: Text(
                  episode.numberLabel,
                  style: AppText.eyebrow(color: AppColors.inkBrown.withValues(alpha: 0.75)).copyWith(fontSize: tagSize),
                ),
              ),
            ],
          ),
        ),
      );
    }
    final current = mark == CaseMark.current;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          width: size.width,
          height: size.height,
          decoration: BoxDecoration(
            color: AppColors.paperLight,
            border: Border.all(
              color: current ? AppColors.burgundy.withValues(alpha: 0.75) : AppLine.faint(0.3),
              width: current ? AppLine.rule : AppLine.hairline,
            ),
            boxShadow: const [BoxShadow(color: Color(0x55000000), blurRadius: 5, offset: Offset(1.5, 3))],
          ),
          alignment: Alignment.center,
          child: Text('?', style: AppText.title(size: size.height * 0.5, color: current ? AppColors.burgundy : AppColors.inkBrown)),
        ),
        Positioned(
          left: -size.width * 0.08,
          bottom: -size.height * 0.1,
          child: Transform.rotate(angle: -0.12, child: PaperTag(episode.numberLabel, size: tagSize)),
        ),
        Positioned(
          top: -(size.height * 0.17).clamp(8.0, 13.0) * 0.3,
          child: PushPin(size: (size.height * 0.17).clamp(8.0, 13.0), color: current ? AppColors.burgundy : AppColors.gold),
        ),
      ],
    );
  }
}

/// A sealed manila envelope seen from the back: its flap folded down.
class _EnvelopePainter extends CustomPainter {
  const _EnvelopePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawShadow(Path()..addRect(rect), Colors.black, 3, false);
    canvas.drawRect(rect, Paint()..color = AppColors.parchmentDark);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppLine.hairline
      ..color = AppColors.inkBrown.withValues(alpha: 0.35);
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(size.width / 2, size.height * 0.55)
        ..lineTo(size.width, 0),
      line,
    );
    canvas.drawRect(rect.deflate(0.5), line);
  }

  @override
  bool shouldRepaint(_EnvelopePainter old) => false;
}

/// A blank note pinned somewhere on the board: ruled, a few ink lines.
class _Scrap extends StatelessWidget {
  const _Scrap(this.size, {this.lines = 3});

  final Size size;
  final int lines;

  @override
  Widget build(BuildContext context) => CustomPaint(size: size, painter: _ScrapPainter(lines));
}

class _ScrapPainter extends CustomPainter {
  const _ScrapPainter(this.lines);

  final int lines;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawShadow(Path()..addRect(rect), Colors.black, 2, false);
    canvas.drawRect(rect, Paint()..color = AppColors.paperLight.withValues(alpha: 0.92));
    final ink = Paint()
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round
      ..color = AppColors.inkBrown.withValues(alpha: 0.45);
    final rnd = math.Random(lines);
    for (var i = 0; i < lines; i++) {
      final y = size.height * (0.25 + 0.55 * i / math.max(lines - 1, 1));
      canvas.drawLine(Offset(size.width * 0.14, y), Offset(size.width * (0.5 + 0.35 * rnd.nextDouble()), y), ink);
    }
  }

  @override
  bool shouldRepaint(_ScrapPainter old) => false;
}

/// A faint round postmark inked on the map.
class _Postmark extends StatelessWidget {
  const _Postmark(this.size);

  final double size;

  @override
  Widget build(BuildContext context) {
    final ink = AppColors.burgundy.withValues(alpha: 0.45);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: ink, width: 1.5)),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xs),
          child: Text('LONDON', style: AppText.eyebrow(color: ink).copyWith(fontSize: 9, letterSpacing: 1)),
        ),
      ),
    );
  }
}

/// What the middle of the board shows: the season's figure as far as it
/// is known, or the question itself.
class SeasonFigureView {
  const SeasonFigureView({required this.figure, required this.label, required this.societyKnown});

  /// `ravens`, `ravenSociety`, `clockmaker`, `clockmakerWatch`, or null for "?".
  final String? figure;
  final String label;

  /// The Raven Society has been named (its seal is kept on the note once
  /// someone further behind it is known).
  final bool societyKnown;

  factory SeasonFigureView.of(SeasonOverview o) {
    final f = o.figure;
    final societyAt = o.info.figures.indexWhere((x) => x.figure == 'ravenSociety');
    final at = f == null ? -1 : o.info.figures.indexOf(f);
    return SeasonFigureView(
      figure: f?.figure,
      label: (f?.label ?? o.info.tagline).toUpperCase(),
      societyKnown: societyAt >= 0 && at > societyAt,
    );
  }

  String get semantics => figure == null ? 'One mystery: who is behind it?' : 'Behind it all: $label';
}

class _FigureNote extends StatelessWidget {
  const _FigureNote({required this.view, required this.size, required this.closed});

  final SeasonFigureView view;
  final Size size;
  final bool closed;

  @override
  Widget build(BuildContext context) {
    final art = size.height * 0.58;
    Widget picture(String file, InkGlyph fallback, {bool round = false}) {
      final image = Image.asset(
        file,
        width: art,
        height: art,
        fit: BoxFit.cover,
        cacheWidth: (art * MediaQuery.devicePixelRatioOf(context)).ceil(),
        excludeFromSemantics: true,
        errorBuilder: (context, error, stack) => InkIcon(fallback, size: art * 0.7, color: AppColors.ink),
      );
      return round ? ClipOval(child: image) : ClipRRect(borderRadius: BorderRadius.circular(2), child: image);
    }

    final center = switch (view.figure) {
      'ravens' => InkIcon(InkGlyph.raven, size: art * 0.8, color: AppColors.ink),
      'ravenSociety' => picture(ArtAssets.ravenMark, InkGlyph.raven, round: true),
      'clockmaker' => Stack(
          alignment: Alignment.center,
          children: [
            InkIcon(InkGlyph.gear, size: art * 0.85, color: AppColors.inkBrown.withValues(alpha: 0.55)),
            Text('?', style: AppText.title(size: art * 0.45, color: AppColors.burgundy)),
          ],
        ),
      'clockmakerWatch' => picture(ArtAssets.objects['pocketWatch']!, InkGlyph.clock),
      _ => Text('?', style: AppText.title(size: art * 0.75, color: AppColors.burgundy)),
    };

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topCenter,
      children: [
        Container(
          width: size.width,
          height: size.height,
          padding: const EdgeInsets.fromLTRB(AppSpace.sm, AppSpace.md, AppSpace.sm, AppSpace.sm),
          decoration: BoxDecoration(
            color: AppColors.paperLight,
            border: Border.all(color: AppLine.faint(0.3), width: AppLine.hairline),
            boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 8, offset: Offset(2, 4))],
          ),
          foregroundDecoration: RuledFrame(color: closed ? AppColors.goldDeep : AppColors.inkBrown, inset: 3),
          child: Column(
            children: [
              Expanded(child: FittedBox(fit: BoxFit.scaleDown, child: center)),
              const SizedBox(height: AppSpace.xs),
              SizedBox(
                height: size.height * 0.2,
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    view.label,
                    textAlign: TextAlign.center,
                    style: AppText.eyebrow(color: AppColors.ink).copyWith(letterSpacing: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ),
        // The Society's seal, kept on the note: they answer to this figure.
        if (view.societyKnown)
          Positioned(
            left: -AppSpace.sm,
            top: size.height * 0.08,
            child: Transform.rotate(
              angle: -0.2,
              child: SizedBox.square(
                dimension: size.height * 0.3,
                child: ClipOval(
                  child: Image.asset(
                    ArtAssets.ravenMark,
                    fit: BoxFit.cover,
                    cacheWidth: (size.height * 0.3 * MediaQuery.devicePixelRatioOf(context)).ceil(),
                    excludeFromSemantics: true,
                    errorBuilder: (context, error, stack) => const InkIcon(InkGlyph.raven, color: AppColors.ink),
                  ),
                ),
              ),
            ),
          ),
        const Positioned(top: -3, child: PushPin(size: 12)),
      ],
    );
  }
}

/// The threads: red string from pin to pin, hanging a little and casting a
/// faint shadow on the board. A lead is dashed (the trail goes on from
/// here); a thread to the middle is lighter.
class _ThreadPainter extends CustomPainter {
  _ThreadPainter({required this.layout, required this.threads});

  final BoardLayout layout;
  final List<(BoardThread, double, double)> threads;

  @override
  void paint(Canvas canvas, Size size) {
    for (final (th, drawn, strength) in threads) {
      if (drawn <= 0 || strength <= 0) continue;
      final a = layout.pinOf(th.from);
      final b = th.to == null ? layout.figurePin : layout.pinOf(th.to!);
      final sag = (b - a).distance * 0.08;
      final mid = Offset.lerp(a, b, 0.5)!.translate(0, sag);
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, b.dx, b.dy);
      final alpha = switch (th.kind) {
            ThreadKind.chain => 0.92,
            ThreadKind.lead => 0.85,
            ThreadKind.spoke => 0.6,
          } *
          strength;
      final width = th.kind == ThreadKind.spoke ? 1.3 : 2.0;
      final shadow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = width
        ..color = Colors.black.withValues(alpha: 0.22 * strength);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = width
        ..color = AppColors.burgundy.withValues(alpha: alpha);
      for (final metric in path.computeMetrics()) {
        final end = metric.length * drawn;
        if (th.kind == ThreadKind.lead) {
          _dashed(canvas, metric, end, paint);
        } else {
          canvas.drawPath(metric.extractPath(0, end).shift(const Offset(1, 2)), shadow);
          canvas.drawPath(metric.extractPath(0, end), paint);
        }
      }
    }
  }

  void _dashed(Canvas canvas, PathMetric metric, double end, Paint paint) {
    const dash = 5.0, gap = 4.0;
    for (var d = 0.0; d < end; d += dash + gap) {
      canvas.drawPath(metric.extractPath(d, math.min(d + dash, end)), paint);
    }
  }

  @override
  bool shouldRepaint(_ThreadPainter old) => true;
}
