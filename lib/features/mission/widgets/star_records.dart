import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/audio_service.dart' show TapRole;
import '../../../data/models/scene_explore.dart' show ScenePixels;
import '../../../data/models/star_puzzles.dart';
import '../../../widgets/game_button.dart';
import '../../../widgets/ink_icon.dart';
import 'clockwork_garden.dart' show DialFace;
import 'river_papers.dart' show PictureCanvas;

/// Season 2, Case 10 — The Hour of Shadows, played on its pictures
/// (`docs/SEASON2_CASE10_SPEC.md`): T1's tape and its two jumps, the roof
/// photo's clocks found under a glass and sorted, the sundial's shadow made
/// with the sun, the tape laid beside the sun's time and the missing page,
/// and the record list read after the case.

bool _still(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// The case's clock dial (Case 09's) and its pivot and face, in its pixels.
const _dialFile = 'assets/seasons/season_02_paris/cases/case_09/clock_dial.png';
const _dialPixels = ScenePixels(1254, 1254);
const _dialPivot = Offset(625, 616);
const _dialFace = 495.0;

/// Ink in an old photo: the hands and the shadow, printed with it.
const _photoInk = Color(0xFF2B2118);

/// A short line under a puzzle: what just happened (read out as it changes).
class _Say extends StatelessWidget {
  const _Say(this.line, {this.good = false, this.dark = false});

  final String line;
  final bool good;
  final bool dark;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: AnimatedSwitcher(
      duration: _still(context) ? Duration.zero : const Duration(milliseconds: 250),
      child: Text(
        line,
        key: ValueKey('star-line-$line'),
        textAlign: TextAlign.center,
        style: AppText.letter(
          size: 17,
          color: dark ? (good ? AppColors.goldLight : AppColors.paperLight) : (good ? AppColors.success : AppColors.tryAgain),
        ),
      ),
    ),
  );
}

/// A shake each time [trigger] changes (a thing sent back).
class _Shake extends StatelessWidget {
  const _Shake({required this.trigger, required this.child});

  final int trigger;
  final Widget child;

  @override
  Widget build(BuildContext context) => trigger == 0 || _still(context)
      ? child
      : TweenAnimationBuilder<double>(
          key: ValueKey(trigger),
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 360),
          builder: (context, t, child) => Transform.translate(offset: Offset(math.sin(t * math.pi * 4) * 8 * (1 - t), 0), child: child),
          child: child,
        );
}

/// The case's dial at [minutes] (minutes after twelve).
class _Dial extends StatelessWidget {
  const _Dial({required this.minutes});

  final int minutes;

  @override
  Widget build(BuildContext context) => DialFace(
    file: _dialFile,
    pixels: _dialPixels,
    pivot: _dialPivot,
    faceRadius: _dialFace,
    hourDegrees: (minutes / 60 % 12) * 30,
    minuteDegrees: (minutes % 60) * 6,
  );
}

// ── The Star Room ───────────────────────────────────────────────────────

/// The room under the roof, its plate's words engraved by the app ([room]),
/// a soft gold ring round [ring] (pixels) when given.
class StarRoomPicture extends StatelessWidget {
  const StarRoomPicture({super.key, required this.room, this.ring});

  final StarRoom room;
  final Rect? ring;

  @override
  Widget build(BuildContext context) {
    final (w, h) = room.plateSize;
    return Semantics(
      image: true,
      label: room.label,
      excludeSemantics: true,
      child: PictureCanvas(
        pixels: room.pixels,
        child: Stack(
          children: [
            Positioned.fill(child: Image.asset(room.file, fit: BoxFit.fill, excludeFromSemantics: true)),
            // The plate's words, engraved: inside 80% of its panel, turned
            // with it, made smaller (never cut) to fit.
            Positioned(
              key: const ValueKey('star-room-plate'),
              left: room.plateCentre.dx - w * 0.4,
              top: room.plateCentre.dy - h * 0.4,
              width: w * 0.8,
              height: h * 0.8,
              child: Transform.rotate(angle: room.plateAngle * math.pi / 180, child: _PlateWords(lines: room.plateLines)),
            ),
            if (ring case final r?)
              Positioned.fromRect(
                rect: r.inflate(10),
                child: IgnorePointer(
                  child: TweenAnimationBuilder<double>(
                    key: ValueKey('star-room-ring-$r'),
                    tween: Tween(begin: 0, end: 1),
                    duration: _still(context) ? Duration.zero : const Duration(milliseconds: 600),
                    builder: (context, t, _) => DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(math.min(r.width, r.height) / 2),
                        border: Border.all(color: AppColors.goldLight.withValues(alpha: 0.9 * t), width: 9),
                        boxShadow: [BoxShadow(color: AppColors.goldLight.withValues(alpha: 0.35 * t), blurRadius: 24)],
                      ),
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

/// Words engraved in brass: dark, a pale edge under them.
class _PlateWords extends StatelessWidget {
  const _PlateWords({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.contain,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final l in lines)
          Text(
            l,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: AppText.style(AppText.display, size: 40, color: AppColors.leatherDeep, letterSpacing: 3, height: 1.15).copyWith(
              shadows: [Shadow(color: AppColors.creamGold.withValues(alpha: 0.7), offset: const Offset(0, 1.5))],
            ),
          ),
      ],
    ),
  );
}

/// The plate seen up close under the opening's line about it: the room's
/// plate, larger, in a brass-rimmed lens (the words are small in the room).
class PlateCloser extends StatelessWidget {
  const PlateCloser({super.key, required this.room, required this.size});

  final StarRoom room;
  final double size;

  @override
  Widget build(BuildContext context) {
    final (w, _) = room.plateSize;
    // The plate's panel takes about four fifths of the lens.
    final scale = size * 0.8 / w;
    return Container(
      key: const ValueKey('star-room-plate-closer'),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.goldDeep, width: 4),
        boxShadow: AppShadow.onNight,
      ),
      child: ClipOval(
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            Positioned(
              left: size / 2 - room.plateCentre.dx * scale,
              top: size / 2 - room.plateCentre.dy * scale,
              width: room.pixels.width * scale,
              height: room.pixels.height * scale,
              child: StarRoomPicture(room: room),
            ),
          ],
        ),
      ),
    );
  }
}

/// The final's stage: the room under the roof.
class StarRoomStage extends StatelessWidget {
  const StarRoomStage({super.key, required this.room});

  final StarRoom room;

  @override
  Widget build(BuildContext context) => Center(child: StarRoomPicture(room: room));
}

// ── The tape ────────────────────────────────────────────────────────────

/// T1's paper tape drawn: its marks ([DrumTapeScene.marks]), [cell] wide
/// each, holes along both edges. [circled] marks get a gold ring; [band]
/// marks a gold ground. [onTap]: a mark tapped (none: to look at only).
class TapeStrip extends StatelessWidget {
  const TapeStrip({
    super.key,
    required this.scene,
    required this.cell,
    this.height = 84,
    this.circled = const {},
    this.band = const {},
    this.jumpLabels = false,
    this.onTap,
  });

  final DrumTapeScene scene;
  final double cell;
  final double height;
  final Set<String> circled;
  final Set<String> band;

  /// Each circled mark also says what it jumped from ("2:45 → 2:00").
  final bool jumpLabels;
  final ValueChanged<String>? onTap;

  @override
  Widget build(BuildContext context) {
    final marks = scene.marks;
    return SizedBox(
      width: cell * marks.length + cell * 0.5,
      height: height,
      child: CustomPaint(
        painter: _TapePaper(cells: marks.length, cell: cell),
        child: Row(
          children: [
            for (final (i, m) in marks.indexed)
              SizedBox(
                width: cell,
                height: height,
                child: Semantics(
                  button: onTap != null,
                  label: 'Mark ${i + 1}: ${m.printedText}${circled.contains(m.id) ? ', a jump' : ''}',
                  excludeSemantics: true,
                  child: GestureDetector(
                    key: ValueKey('tape-mark-${m.id}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: onTap == null ? null : () => onTap!(m.id),
                    child: _TapeCell(
                      text: m.printedText,
                      circled: circled.contains(m.id),
                      band: band.contains(m.id),
                      label: jumpLabels && circled.contains(m.id) && i > 0 ? '${marks[i - 1].printedText} → ${m.printedText}' : null,
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

class _TapeCell extends StatelessWidget {
  const _TapeCell({required this.text, required this.circled, required this.band, this.label});

  final String text;
  final bool circled;
  final bool band;
  final String? label;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(color: band ? AppColors.creamGold.withValues(alpha: 0.85) : null),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // The drum's little printed tick.
        Container(width: 2, height: 9, color: AppColors.inkBrown.withValues(alpha: 0.7)),
        const SizedBox(height: 3),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: circled ? AppColors.gold : Colors.transparent, width: 2.5),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              maxLines: 1,
              style: AppText.bodyText(size: 18, weight: FontWeight.w700, color: AppColors.ink).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
            ),
          ),
        ),
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(label!, maxLines: 1, style: AppText.bodyText(size: 11, weight: FontWeight.w700, color: AppColors.tryAgain)),
            ),
          ),
      ],
    ),
  );
}

/// The tape's paper: a long cream strip, holes along both edges (as the
/// tape in the room has), a thin rule between marks.
class _TapePaper extends CustomPainter {
  const _TapePaper({required this.cells, required this.cell});

  final int cells;
  final double cell;

  @override
  void paint(Canvas canvas, Size size) {
    final paper = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(paper, Paint()..color = AppColors.paperLight);
    canvas.drawRect(
      paper,
      Paint()
        ..color = AppColors.inkBrown.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke,
    );
    final hole = Paint()..color = AppColors.inkBrown.withValues(alpha: 0.45);
    for (var x = 8.0; x < size.width - 4; x += 14) {
      canvas.drawCircle(Offset(x, 6), 2.1, hole);
      canvas.drawCircle(Offset(x, size.height - 6), 2.1, hole);
    }
  }

  @override
  bool shouldRepaint(_TapePaper old) => old.cells != cells || old.cell != cell;
}

/// The drum with its plate's emblem (the trial's gear, as on Case 09's plan).
class _Drum extends StatelessWidget {
  const _Drum({required this.scene, required this.size});

  final DrumTapeScene scene;
  final double size;

  @override
  Widget build(BuildContext context) {
    final s = size / scene.drumPixels.width;
    final plate = scene.plate;
    return SizedBox.square(
      dimension: size,
      child: Stack(
        children: [
          Positioned.fill(child: Image.asset(scene.drumFile, fit: BoxFit.contain, excludeFromSemantics: true)),
          Positioned(
            left: plate.center.dx * s - plate.height * s * 0.4,
            top: plate.center.dy * s - plate.height * s * 0.4,
            width: plate.height * s * 0.8,
            height: plate.height * s * 0.8,
            child: InkIcon(InkGlyph.gear, size: plate.height * s * 0.8, color: AppColors.leatherDeep),
          ),
        ],
      ),
    );
  }
}

// ── M1 — the drum tape ──────────────────────────────────────────────────

/// M1 ([DrumTapeScene]): the drum, its tape pulled out ([pulled], saved:
/// [onPulled]), then the marks tapped. A jump stays found (saved:
/// [onFound]); any other mark says it follows on, never a wrong answer.
/// Both jumps found: the mission's answer ([onSubmit]).
class DrumTapePuzzle extends StatefulWidget {
  const DrumTapePuzzle({super.key, required this.scene, required this.pulled, required this.found, required this.onPulled, required this.onFound, required this.onSubmit});

  final DrumTapeScene scene;
  final bool pulled;
  final Set<String> found;
  final VoidCallback onPulled;
  final ValueChanged<Set<String>> onFound;
  final Future<void> Function(String answer) onSubmit;

  @override
  State<DrumTapePuzzle> createState() => _DrumTapePuzzleState();
}

class _DrumTapePuzzleState extends State<DrumTapePuzzle> {
  late Set<String> _found = {...widget.found};
  late bool _pulled = widget.pulled;
  double _pull = 0;
  String? _line;
  bool _good = false;
  Timer? _submit;
  final _scroll = ScrollController();

  DrumTapeScene get _scene => widget.scene;
  bool get _done => _found.length == _scene.jumps.length;

  @override
  void initState() {
    super.initState();
    if (_done) _later();
  }

  @override
  void dispose() {
    _submit?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _later() => _submit = Timer(const Duration(milliseconds: 900), () {
    if (mounted) widget.onSubmit(_scene.answerOf(_found));
  });

  void _pullOut() {
    if (_pulled) return;
    setState(() => _pulled = true);
    widget.onPulled();
  }

  void _tap(String id) {
    if (_done) return;
    if (_scene.jumps.contains(id)) {
      if (_found.contains(id)) return;
      setState(() {
        _found = {..._found, id};
        _good = true;
        _line = _done ? _scene.found : _scene.oneMore;
      });
      widget.onFound(_found);
      if (_done) _later();
    } else {
      setState(() {
        _good = false;
        _line = _scene.lineFor(id);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scene = _scene;
    return LayoutBuilder(
      builder: (context, box) {
        final drum = math.min(124.0, box.maxWidth * 0.34);
        final s = drum / scene.drumPixels.width;
        const tapeH = 84.0;
        final slot = Offset(scene.slot.dx * s, scene.slot.dy * s);
        final tapeTop = math.max(0.0, slot.dy - tapeH / 2);
        final stageH = math.max(drum, tapeTop + tapeH);
        // Each mark wide enough for a finger and for "12:45".
        const cell = 64.0;
        final left = slot.dx - 4;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(scene.task, key: const ValueKey('tape-task'), textAlign: TextAlign.center, style: AppText.bodyText(size: 15, weight: FontWeight.w600, color: AppColors.navy)),
            const SizedBox(height: AppSpace.sm),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const InkIcon(InkGlyph.gear, size: 16, color: AppColors.goldDeep),
                const SizedBox(width: AppSpace.xs),
                Flexible(
                  child: Text(scene.header, textAlign: TextAlign.center, style: AppText.eyebrow()),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.xs),
            SizedBox(
              height: stageH,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // The tape, coming out of the drum's slot.
                  Positioned(
                    left: left,
                    right: 0,
                    top: tapeTop,
                    height: tapeH,
                    child: ClipRect(
                      child: AnimatedSwitcher(
                        duration: _still(context) ? Duration.zero : const Duration(milliseconds: 450),
                        transitionBuilder: (child, anim) => SizeTransition(sizeFactor: anim, axis: Axis.horizontal, alignment: Alignment.centerLeft, child: child),
                        child: _pulled
                            ? SingleChildScrollView(
                                key: const ValueKey('tape-scroll'),
                                controller: _scroll,
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.only(left: 6),
                                child: TapeStrip(scene: scene, cell: cell, height: tapeH, circled: _found, jumpLabels: true, onTap: _tap),
                              )
                            : Align(
                                alignment: Alignment.centerLeft,
                                child: _TapeTail(
                                  label: scene.pullLabel,
                                  pull: _pull,
                                  onDrag: (dx) {
                                    setState(() => _pull = (_pull + dx).clamp(0, 80));
                                    if (_pull > 40) _pullOut();
                                  },
                                  onTap: _pullOut,
                                ),
                              ),
                      ),
                    ),
                  ),
                  Positioned(left: 0, top: (stageH - drum) / 2, child: _Drum(scene: scene, size: drum)),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            Semantics(
              label: '${_found.length} of ${scene.jumps.length} jumps found',
              excludeSemantics: true,
              child: Row(
                key: const ValueKey('tape-count'),
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < scene.jumps.length; i++)
                    Container(
                      width: 14,
                      height: 14,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < _found.length ? AppColors.gold : null,
                        border: Border.all(color: AppColors.gold, width: 2),
                      ),
                    ),
                ],
              ),
            ),
            ConstrainedBox(constraints: const BoxConstraints(minHeight: 48), child: Center(child: _line == null ? null : _Say(_line!, good: _good))),
          ],
        );
      },
    );
  }
}

/// The tape's end, still in the drum: pulled to the right (or tapped).
class _TapeTail extends StatelessWidget {
  const _TapeTail({required this.label, required this.pull, required this.onDrag, required this.onTap});

  final String label;
  final double pull;
  final ValueChanged<double> onDrag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    excludeSemantics: true,
    child: GestureDetector(
      key: const ValueKey('tape-pull'),
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: (d) => onDrag(d.delta.dx),
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70 + pull,
            height: 84,
            decoration: BoxDecoration(
              color: AppColors.paperLight,
              border: Border.all(color: AppColors.inkBrown.withValues(alpha: 0.25)),
            ),
            child: const Align(alignment: Alignment.centerRight, child: Padding(padding: EdgeInsets.only(right: 6), child: InkIcon(InkGlyph.arrow, size: 22, color: AppColors.goldDeep))),
          ),
          const SizedBox(width: AppSpace.sm),
          Flexible(child: Text(label, style: AppText.button(size: 14, color: AppColors.goldDeep))),
        ],
      ),
    ),
  );
}

// ── The roof photos ─────────────────────────────────────────────────────

/// The roof photo (its own worn edge), its clocks' hands at the times of
/// Photo [photo], and the sundial's shadow at [shadow] (minutes) when
/// given; laid in the photo's pixels ([PictureCanvas]).
class RoofPhotoView extends StatelessWidget {
  const RoofPhotoView({super.key, required this.photo, required this.at, this.dialAngle, this.dialLength, this.child});

  final RoofPhoto photo;

  /// Which photo: 1 or 2.
  final int at;

  /// The shadow's direction (degrees, from the gnomon) and length (a
  /// fraction of the plate), from the sundial's own lines.
  final double? dialAngle;
  final double? dialLength;
  final Widget? child;

  @override
  Widget build(BuildContext context) => PictureCanvas(
    pixels: photo.pixels,
    child: Stack(
      children: [
        Positioned.fill(child: Image.asset(photo.file, fit: BoxFit.fill, excludeFromSemantics: true)),
        Positioned.fill(child: CustomPaint(painter: _PhotoInk(photo: photo, at: at, dialAngle: dialAngle, dialLength: dialLength))),
        ?child,
      ],
    ),
  );
}

/// The hands of the photo's clocks, and the sundial's shadow, in the
/// photo's own dark ink (no brass: a photo's grey).
class _PhotoInk extends CustomPainter {
  const _PhotoInk({required this.photo, required this.at, this.dialAngle, this.dialLength});

  final RoofPhoto photo;
  final int at;
  final double? dialAngle;
  final double? dialLength;

  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()..color = _photoInk;
    for (final c in photo.clocks) {
      final m = c.timeIn(at);
      canvas
        ..save()
        ..translate(c.centre.dx, c.centre.dy)
        // The faces are seen a little from the side: narrower than tall.
        ..scale(c.rx / c.ry, 1);
      final r = c.ry;
      void hand(double degrees, double length, double width) {
        canvas
          ..save()
          ..rotate(degrees * math.pi / 180);
        final path = Path()
          ..moveTo(-width / 2, r * 0.12)
          ..lineTo(-width * 0.35, -length * 0.8)
          ..lineTo(0, -length)
          ..lineTo(width * 0.35, -length * 0.8)
          ..lineTo(width / 2, r * 0.12)
          ..close();
        canvas.drawPath(path, ink);
        canvas.restore();
      }

      hand((m % 60) * 6.0, r * 0.82, r * 0.075);
      hand((m / 60 % 12) * 30, r * 0.52, r * 0.13);
      canvas.drawCircle(Offset.zero, r * 0.07, ink);
      canvas.restore();
    }
    final a = dialAngle, l = dialLength;
    if (a != null && l != null) _shadow(canvas, photo.dial, a, l);
  }

  /// The shadow on the photo's sundial: from the gnomon's foot to [length]
  /// along [angle], a wedge a few pixels wide on the picture (its width
  /// taken across it on the picture, so the flattened plate never makes it
  /// a hairline).
  static void _shadow(Canvas canvas, PhotoDial d, double angle, double length) {
    final tip = d.along(angle, length);
    final along = tip - d.hub;
    final side = Offset(-along.dy, along.dx) / along.distance * 11;
    final path = Path()
      ..moveTo(d.hub.dx + side.dx, d.hub.dy + side.dy)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(d.hub.dx - side.dx, d.hub.dy - side.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = _photoInk.withValues(alpha: 0.78));
  }

  @override
  bool shouldRepaint(_PhotoInk old) => old.at != at || old.dialAngle != dialAngle || old.dialLength != dialLength;
}

/// A part of the roof photo ([crop], pixels) filling its box.
class _PhotoCrop extends StatelessWidget {
  const _PhotoCrop({required this.photo, required this.crop, required this.at, this.dialAngle, this.dialLength});

  final RoofPhoto photo;
  final Rect crop;
  final int at;
  final double? dialAngle;
  final double? dialLength;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: crop.width / crop.height,
    child: LayoutBuilder(
      builder: (context, box) {
        final s = box.maxWidth / crop.width;
        return ClipRect(
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: -crop.left * s,
                top: -crop.top * s,
                width: photo.pixels.width * s,
                height: photo.pixels.height * s,
                child: RoofPhotoView(photo: photo, at: at, dialAngle: dialAngle, dialLength: dialLength),
              ),
            ],
          ),
        );
      },
    ),
  );
}

// ── M2 — a city of clocks ───────────────────────────────────────────────

/// M2 ([CityClocksScene]): Photo 2 under a glass (dragged, or moved by a
/// tap); a clock under it is found (saved: [onChanged]) and goes to the
/// tray; each found clock sorted (tapped, then its tray tapped; or dragged)
/// into TRIAL CLOCK or NOT A TRIAL CLOCK. A wrong tray sends it back with
/// its line, never a wrong answer. All sorted: their times shown, then the
/// mission's answer ([onSubmit]). [trialMap]: the Trial Map, a tap away.
class CityClocksPuzzle extends StatefulWidget {
  const CityClocksPuzzle({
    super.key,
    required this.scene,
    required this.found,
    required this.sorted,
    required this.onChanged,
    required this.onSubmit,
    this.trialMap,
  });

  final CityClocksScene scene;
  final Set<String> found;
  final Map<String, String> sorted;
  final void Function(Set<String> found, Map<String, String> sorted) onChanged;
  final Future<void> Function(String answer) onSubmit;
  final Widget? trialMap;

  @override
  State<CityClocksPuzzle> createState() => _CityClocksPuzzleState();
}

class _CityClocksPuzzleState extends State<CityClocksPuzzle> {
  late Set<String> _found = {...widget.found};
  late Map<String, String> _sorted = {...widget.sorted};

  /// The point of the photo under the glass (photo pixels).
  Offset _focus = const Offset(560, 300);

  /// Where the finger is on the photo (points), while it is down.
  Offset? _finger;
  String? _picked;
  String? _line;
  bool _good = false;
  final Map<String, int> _sentBack = {};
  Timer? _rest;
  Timer? _submit;

  CityClocksScene get _scene => widget.scene;
  bool get _allFound => _found.length == _scene.photo.clocks.length;
  bool get _done => _sorted.length == _scene.photo.clocks.length;

  @override
  void initState() {
    super.initState();
    if (_done) _later();
  }

  @override
  void dispose() {
    _rest?.cancel();
    _submit?.cancel();
    super.dispose();
  }

  void _later() => _submit = Timer(const Duration(milliseconds: 1800), () {
    if (mounted) widget.onSubmit(_scene.answerOf(_sorted));
  });

  void _save() => widget.onChanged(_found, _sorted);

  /// The glass moved to [p] (photo pixels); [scale]: points per pixel on
  /// screen. A clock under it is found once the glass rests on it, or the
  /// finger is lifted there.
  void _moveTo(Offset p, double scale, {required bool settle}) {
    final px = _scene.photo.pixels;
    setState(() => _focus = Offset(p.dx.clamp(0, px.width), p.dy.clamp(0, px.height)));
    _rest?.cancel();
    // At least a finger's width round each face, on the screen.
    final reach = 24 / scale;
    if (settle) {
      _look(reach);
    } else {
      _rest = Timer(const Duration(milliseconds: 350), () => _look(reach));
    }
  }

  void _look(double reach) {
    if (!mounted) return;
    final c = _scene.clockAt(_focus, reach);
    if (c == null || _found.contains(c.id)) return;
    setState(() {
      _found = {..._found, c.id};
      _good = true;
      // All found: the task above says what to do now, once.
      _line = _allFound ? null : _scene.foundLine;
    });
    _save();
  }

  void _drop(String id, String tray) {
    if (_done || _sorted.containsKey(id)) return;
    final c = _scene.photo.clock(id);
    if (_scene.trayOf(c) == tray) {
      setState(() {
        _sorted = {..._sorted, id: tray};
        _picked = null;
        _good = true;
        _line = _done ? null : 'Yes!';
      });
      _save();
      if (_done) _later();
    } else {
      setState(() {
        _picked = null;
        _good = false;
        _line = c.wrongLine;
        _sentBack[id] = (_sentBack[id] ?? 0) + 1;
      });
    }
  }

  void _tapTray(String tray) {
    final id = _picked;
    if (id == null) {
      setState(() {
        _good = false;
        _line = _found.isEmpty ? _scene.task : 'First tap a clock you found.';
      });
      return;
    }
    _drop(id, tray);
  }

  @override
  Widget build(BuildContext context) {
    final scene = _scene;
    final photo = scene.photo;
    final waiting = [for (final c in photo.clocks) if (_found.contains(c.id) && !_sorted.containsKey(c.id)) c];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(_allFound ? scene.sortTask : scene.task, key: const ValueKey('city-task'), textAlign: TextAlign.center, style: AppText.bodyText(size: 15, weight: FontWeight.w600, color: AppColors.navy)),
        if (widget.trialMap case final map?)
          Center(
            child: InkTextButton(
              key: const ValueKey('city-trial-map'),
              label: 'Look at your Trial Map',
              glyph: InkGlyph.map,
              onPressed: () => showDialog<void>(
                context: context,
                builder: (context) => Dialog(
                  backgroundColor: AppColors.paperLight,
                  insetPadding: const EdgeInsets.all(AppSpace.lg),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpace.md),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('TRIAL MAP', style: AppText.mark()),
                        const SizedBox(height: AppSpace.sm),
                        ClipRRect(borderRadius: BorderRadius.circular(AppRadius.paper), child: map),
                        const SizedBox(height: AppSpace.sm),
                        Text('T1 at the Arc de Triomphe, with a star. T2 at the Seine bridge, with three arches. T3 at Arts et Métiers, with a bell.',
                            textAlign: TextAlign.center, style: AppText.bodyText(size: 14, color: AppColors.ink)),
                        const SizedBox(height: AppSpace.sm),
                        GameButton(label: 'BACK TO THE PHOTO', style: GameButtonStyle.outline, onPressed: () => Navigator.of(context).pop()),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        const SizedBox(height: AppSpace.xs),
        _GlassPhoto(
          scene: scene,
          focus: _focus,
          finger: _finger,
          found: _found,
          onMove: (p, s, settle, finger) {
            setState(() => _finger = finger);
            _moveTo(p, s, settle: settle);
          },
        ),
        const SizedBox(height: AppSpace.sm),
        ConstrainedBox(constraints: const BoxConstraints(minHeight: 48), child: Center(child: _line == null ? null : _Say(_line!, good: _good))),
        Text('FOUND ${_found.length} / ${photo.clocks.length}', key: const ValueKey('city-count'), textAlign: TextAlign.center, style: AppText.eyebrow()),
        const SizedBox(height: AppSpace.xs),
        // The clocks found, waiting to be sorted.
        Wrap(
          alignment: WrapAlignment.center,
          spacing: AppSpace.sm,
          runSpacing: AppSpace.sm,
          children: [
            for (final c in waiting)
              _Shake(
                trigger: _sentBack[c.id] ?? 0,
                child: Draggable<String>(
                  data: c.id,
                  feedback: Material(color: Colors.transparent, child: _ClockCard(photo: photo, clock: c, picked: true, sortedTime: false)),
                  childWhenDragging: Opacity(opacity: 0.3, child: _ClockCard(photo: photo, clock: c, picked: false, sortedTime: false)),
                  child: _ClockCard(
                    photo: photo,
                    clock: c,
                    picked: _picked == c.id,
                    sortedTime: false,
                    onTap: _done
                        ? null
                        : () => setState(() {
                            _picked = _picked == c.id ? null : c.id;
                            _good = true;
                            _line = _picked == null ? null : 'Now tap its tray.';
                          }),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, tray) in [(CityClocksScene.trial, scene.trialTray), (CityClocksScene.other, scene.otherTray)].indexed) ...[
              if (i > 0) const SizedBox(width: AppSpace.sm),
              Expanded(
                child: DragTarget<String>(
                  onAcceptWithDetails: (d) => _drop(d.data, tray.$1),
                  builder: (context, candidates, _) => Semantics(
                    button: true,
                    label: '${tray.$2} tray',
                    child: GestureDetector(
                      key: ValueKey('city-tray-${tray.$1}'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _tapTray(tray.$1),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 96),
                        padding: const EdgeInsets.all(AppSpace.xs),
                        decoration: BoxDecoration(
                          color: candidates.isNotEmpty || _picked != null ? AppColors.creamGold.withValues(alpha: 0.6) : AppColors.parchment.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(AppRadius.paper),
                          border: Border.all(color: _picked != null ? AppColors.gold : AppLine.faint(0.4), width: _picked != null ? 2 : AppLine.hairline),
                        ),
                        child: Column(
                          children: [
                            FittedBox(fit: BoxFit.scaleDown, child: Text(tray.$2, maxLines: 1, style: AppText.button(size: 13, color: AppColors.navy))),
                            const SizedBox(height: AppSpace.xs),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 4,
                              runSpacing: 4,
                              children: [
                                for (final c in photo.clocks)
                                  if (_sorted[c.id] == tray.$1) _ClockCard(photo: photo, clock: c, picked: false, sortedTime: _done, small: true),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        if (_done) ...[
          const SizedBox(height: AppSpace.sm),
          for (final l in scene.sortedLines) _Say(l, good: true),
        ],
      ],
    );
  }
}

/// Photo 2 with the glass over it. The glass shows the photo larger
/// ([CityClocksScene.lensScale] points a pixel) just above the finger, so
/// the finger never hides what it looks at; found clocks are ringed.
class _GlassPhoto extends StatelessWidget {
  const _GlassPhoto({required this.scene, required this.focus, required this.finger, required this.found, required this.onMove});

  final CityClocksScene scene;
  final Offset focus;
  final Offset? finger;
  final Set<String> found;

  /// The point under the glass (photo pixels), the photo's points per pixel,
  /// whether the finger was lifted there, and the finger (points).
  final void Function(Offset p, double scale, bool settle, Offset? finger) onMove;

  @override
  Widget build(BuildContext context) {
    final photo = scene.photo;
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final s = w / photo.pixels.width;
        final h = photo.pixels.height * s;
        final lens = scene.lensSize;
        // The glass above the point it shows; below it near the top edge.
        final at = Offset(focus.dx * s, focus.dy * s);
        var centre = at + Offset(0, -lens * 0.72);
        if (centre.dy - lens / 2 < 0) centre = at + Offset(0, lens * 0.72);
        centre = Offset(centre.dx.clamp(lens / 2, w - lens / 2), centre.dy.clamp(lens / 2, math.max(lens / 2, h - lens / 2)));
        Offset px(Offset local) => Offset(local.dx / s, local.dy / s);
        return Semantics(
          label: 'An old photo from the roof. Move the glass over it to find the clocks. ${found.length} of ${photo.clocks.length} found.',
          child: GestureDetector(
            key: const ValueKey('city-photo'),
            behavior: HitTestBehavior.opaque,
            onTapUp: (d) => onMove(px(d.localPosition), s, true, null),
            // Dragged either way: the glass takes the finger before the page
            // can scroll.
            onVerticalDragStart: (d) => onMove(px(d.localPosition), s, false, d.localPosition),
            onVerticalDragUpdate: (d) => onMove(px(d.localPosition), s, false, d.localPosition),
            onVerticalDragEnd: (_) => onMove(focus, s, true, null),
            onHorizontalDragStart: (d) => onMove(px(d.localPosition), s, false, d.localPosition),
            onHorizontalDragUpdate: (d) => onMove(px(d.localPosition), s, false, d.localPosition),
            onHorizontalDragEnd: (_) => onMove(focus, s, true, null),
            child: SizedBox(
              width: w,
              height: h,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.paper),
                      child: RoofPhotoView(
                        photo: photo,
                        at: 2,
                        child: Stack(
                          children: [
                            for (final c in photo.clocks)
                              if (found.contains(c.id))
                                Positioned(
                                  key: ValueKey('city-ring-${c.id}'),
                                  // Clear of the clock's own rim.
                                  left: c.centre.dx - math.max(c.rx * 1.3, 24 / s) - 8,
                                  top: c.centre.dy - math.max(c.ry * 1.3, 24 / s) - 8,
                                  width: (math.max(c.rx * 1.3, 24 / s) + 8) * 2,
                                  height: (math.max(c.ry * 1.3, 24 / s) + 8) * 2,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.goldLight, width: 4 / s * 0.6)),
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // The glass.
                  Positioned(
                    key: const ValueKey('city-lens'),
                    left: centre.dx - lens / 2,
                    top: centre.dy - lens / 2,
                    width: lens,
                    height: lens,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        position: DecorationPosition.foreground,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.goldDeep, width: 5),
                          boxShadow: AppShadow.onNight,
                        ),
                        child: ClipOval(
                          child: Stack(
                            clipBehavior: Clip.hardEdge,
                            children: [
                              Positioned(
                                left: lens / 2 - focus.dx * scene.lensScale,
                                top: lens / 2 - focus.dy * scene.lensScale,
                                width: photo.pixels.width * scene.lensScale,
                                height: photo.pixels.height * scene.lensScale,
                                child: RoofPhotoView(photo: photo, at: 2),
                              ),
                              // The point it shows: a fine cross.
                              Center(child: Container(width: 10, height: 1.5, color: AppColors.goldLight.withValues(alpha: 0.8))),
                              Center(child: Container(width: 1.5, height: 10, color: AppColors.goldLight.withValues(alpha: 0.8))),
                            ],
                          ),
                        ),
                      ),
                    ),
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

/// A clock found: its part of the photo and its name; once every clock is
/// sorted ([sortedTime]), its face large at the time it shows.
class _ClockCard extends StatelessWidget {
  const _ClockCard({required this.photo, required this.clock, required this.picked, required this.sortedTime, this.onTap, this.small = false});

  final RoofPhoto photo;
  final PhotoClock clock;
  final bool picked;
  final bool sortedTime;
  final VoidCallback? onTap;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final width = small ? 64.0 : 84.0;
    final time = clockText(clock.photo2);
    return Semantics(
      button: onTap != null,
      selected: picked,
      label: '${clock.label}${sortedTime ? ': $time' : ''}',
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('city-card-${clock.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: width,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: picked ? AppColors.navy : AppColors.paperLight,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(color: picked ? AppColors.goldLight : AppLine.faint(0.4), width: picked ? 2 : AppLine.hairline),
            boxShadow: AppShadow.pinned,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: sortedTime
                    ? AspectRatio(aspectRatio: 1, child: _Dial(minutes: clock.photo2))
                    : _PhotoCrop(photo: photo, crop: clock.card, at: 2),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  sortedTime ? '${clock.name} · $time' : clock.name,
                  key: ValueKey('city-card-label-${clock.id}'),
                  maxLines: 1,
                  style: AppText.bodyText(size: 13, weight: FontWeight.w700, color: picked ? AppColors.paperLight : AppColors.navy),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Independent Time Log, drawn: Photo 2 with its clocks' hands.
class PhotoLogView extends StatelessWidget {
  const PhotoLogView({super.key, required this.log});

  final PhotoLog log;

  @override
  Widget build(BuildContext context) => RoofPhotoView(photo: log.photo, at: 2);
}

// ── M3 — the hour of shadows ────────────────────────────────────────────

/// M3 ([ShadowCheckScene]): Photo 1, then Photo 2, over the roof's sundial.
/// The sun dragged round the dial (anywhere on it: the finger never covers
/// the sun) turns and stretches the shadow; let go, the shadow settles on
/// the nearest hour line. The photo's own time is the same shadow (saved:
/// [onMatched]); another line says whether the photo's is longer or
/// shorter, never a wrong answer. The seven points on the sun's path can
/// be tapped too. Both photos matched: the mission's answer ([onSubmit]).
class ShadowCheckPuzzle extends StatefulWidget {
  const ShadowCheckPuzzle({super.key, required this.scene, required this.matched, required this.onMatched, required this.onSubmit});

  final ShadowCheckScene scene;
  final Set<String> matched;
  final ValueChanged<Set<String>> onMatched;
  final Future<void> Function(String answer) onSubmit;

  @override
  State<ShadowCheckPuzzle> createState() => _ShadowCheckPuzzleState();
}

class _ShadowCheckPuzzleState extends State<ShadowCheckPuzzle> {
  late Set<String> _matched = {...widget.matched};

  /// The sun's time now (minutes; between lines while dragged).
  late double _time = _startFor(_current).toDouble();
  bool _dragging = false;
  int? _settled;
  String? _line;
  bool _good = false;
  int _nudge = 0;
  bool _showNext = false;
  Timer? _submit;

  ShadowCheckScene get _scene => widget.scene;
  Sundial get _dial => _scene.sundial;

  /// The photo to match now: the first not matched (the last when all are).
  ShadowPhoto get _current => _scene.photos.firstWhere((p) => !_matched.contains(p.id), orElse: () => _scene.photos.last);
  bool get _done => _matched.length == _scene.photos.length;

  /// Where the sun starts for [p]: an hour before its time, or the last
  /// photo's time.
  int _startFor(ShadowPhoto p) {
    final i = _scene.photos.indexOf(p);
    return i > 0 && _matched.contains(_scene.photos[i - 1].id) ? _scene.photos[i - 1].sun : math.max(_dial.first, p.sun - 60);
  }

  @override
  void initState() {
    super.initState();
    if (_done) {
      _time = _scene.photos.last.sun.toDouble();
      _settled = _scene.photos.last.sun;
      _later();
    }
  }

  @override
  void dispose() {
    _submit?.cancel();
    super.dispose();
  }

  void _later() => _submit = Timer(const Duration(milliseconds: 1400), () {
    if (mounted) widget.onSubmit(_scene.answerOf(_matched));
  });

  /// The sun dragged to [angle] (degrees round the dial, clockwise from the
  /// gnomon): the shadow goes opposite, between the first and last lines.
  void _dragTo(double angle) {
    if (_done || _showNext) return;
    final shadow = ((angle - 180) % 360 + 360) % 360;
    // Off the sun's path: to its nearer end.
    final first = _dial.lines.first.angle, last = _dial.lines.last.angle;
    final a = shadow >= first && shadow <= last
        ? shadow
        : ((shadow - first + 540) % 360 - 180).abs() < ((shadow - last + 540) % 360 - 180).abs()
        ? first
        : last;
    setState(() {
      _dragging = true;
      _time = _dial.timeAt(a);
      _line = null;
    });
  }

  /// Let go (or a point tapped): the shadow settles on the nearest line,
  /// then it is compared with the photo's.
  void _settle([int? at]) {
    if (_done || _showNext) return;
    final line = at ?? _dial.nearest(_time).time;
    final photo = _current;
    setState(() {
      _dragging = false;
      _time = line.toDouble();
      _settled = line;
      if (line == photo.sun) {
        _matched = {..._matched, photo.id};
        _good = true;
        _line = _scene.matchLine;
        _showNext = !_done;
      } else {
        _good = false;
        _line = photo.sun > line ? _scene.longer : _scene.shorter;
        _nudge++;
      }
    });
    if (_matched.contains(photo.id)) {
      widget.onMatched(_matched);
      if (_done) _later();
    }
  }

  void _next() => setState(() {
    _showNext = false;
    _line = null;
    _settled = null;
    _time = _startFor(_current).toDouble();
  });

  @override
  Widget build(BuildContext context) {
    final scene = _scene;
    // The photo on screen: the one just matched until NEXT PHOTO.
    final shown = _showNext ? scene.photos.lastWhere((p) => _matched.contains(p.id)) : _current;
    final matchedShown = _matched.contains(shown.id);
    final settle = _dragging ? _dial.settleAt(_time) : null;
    final drawn = settle?.time.toDouble() ?? _time;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(scene.task, key: const ValueKey('shadow-task'), textAlign: TextAlign.center, style: AppText.bodyText(size: 15, weight: FontWeight.w600, color: AppColors.navy)),
        const SizedBox(height: AppSpace.sm),
        _PhotoCard(scene: scene, photo: shown, matched: matchedShown),
        const SizedBox(height: AppSpace.sm),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: SunDialStage(
              dial: _dial,
              time: drawn,
              plateWords: scene.plateWords,
              nudge: _nudge,
              nudgeUp: _settled != null && shown.sun > _settled!,
              onDrag: _dragTo,
              onRelease: () => _settle(),
              onPoint: (t) => _settle(t),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.xs),
        Text(
          'SUN: ${_settled == null && !_dragging ? '--:--' : clockText(drawn.round())}',
          key: const ValueKey('shadow-reading'),
          textAlign: TextAlign.center,
          style: AppText.title(size: 22).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
        ),
        for (final p in scene.photos)
          if (_matched.contains(p.id))
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '${p.name}: T1 ${clockText(p.t1)} · SUN ${clockText(p.sun)} · ${p.t1 == p.sun ? 'same' : 'one hour apart'}',
                key: ValueKey('shadow-compare-${p.id}'),
                textAlign: TextAlign.center,
                style: AppText.bodyText(size: 14, weight: FontWeight.w700, color: p.t1 == p.sun ? AppColors.success : AppColors.tryAgain),
              ),
            ),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Center(child: _line == null ? (_settled == null && !_done ? _Say(scene.dragLine, good: true) : null) : _Say(_line!, good: _good)),
        ),
        if (_showNext)
          GameButton(key: const ValueKey('shadow-next'), label: scene.nextLabel, arrow: true, style: GameButtonStyle.gold, tap: TapRole.primary, onPressed: _next),
      ],
    );
  }
}

/// A photo's card: its name, T1's face at its time and the sundial with
/// its shadow, cut from the photo.
class _PhotoCard extends StatelessWidget {
  const _PhotoCard({required this.scene, required this.photo, required this.matched});

  final ShadowCheckScene scene;
  final ShadowPhoto photo;
  final bool matched;

  @override
  Widget build(BuildContext context) {
    final dial = scene.sundial;
    final p = scene.photo;
    return Semantics(
      label: '${photo.name}: T1 says ${clockText(photo.t1)}; the sundial has a shadow',
      excludeSemantics: true,
      child: Container(
        key: ValueKey('shadow-photo-${photo.id}'),
        padding: const EdgeInsets.all(AppSpace.xs),
        decoration: BoxDecoration(
          color: AppColors.paperLight,
          borderRadius: BorderRadius.circular(AppRadius.paper),
          border: Border.all(color: matched ? AppColors.success : AppLine.faint(0.4), width: matched ? 2 : AppLine.hairline),
          boxShadow: AppShadow.pinned,
        ),
        child: Column(
          children: [
            Text(photo.name, style: AppText.mark()),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 10,
                  child: Column(
                    children: [
                      ClipRRect(borderRadius: BorderRadius.circular(3), child: _PhotoCrop(photo: p, crop: p.t1Crop, at: photo.number)),
                      const SizedBox(height: 2),
                      Text('T1 · ${clockText(photo.t1)}', style: AppText.bodyText(size: 13, weight: FontWeight.w700, color: AppColors.navy)),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpace.xs),
                Expanded(
                  flex: 21,
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: _PhotoCrop(photo: p, crop: p.dialCrop, at: photo.number, dialAngle: dial.angleAt(photo.sun.toDouble()), dialLength: dial.lengthAt(photo.sun.toDouble())),
                      ),
                      const SizedBox(height: 2),
                      Text(matched ? 'SUN · ${clockText(photo.sun)}' : 'SUN · ?', style: AppText.bodyText(size: 13, weight: FontWeight.w700, color: AppColors.navy)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The roof's sundial from above, the sun on its path round it and the
/// shadow it casts, all from [Sundial.lines]: the sun opposite the shadow,
/// the shadow longer and darker as the afternoon goes. Dragged anywhere on
/// it, the sun follows the finger's direction ([onDrag]: degrees from the
/// gnomon); let go: [onRelease]. The path's seven points can be tapped
/// ([onPoint]: their times).
class SunDialStage extends StatelessWidget {
  const SunDialStage({
    super.key,
    required this.dial,
    required this.time,
    required this.plateWords,
    required this.onDrag,
    required this.onRelease,
    required this.onPoint,
    this.nudge = 0,
    this.nudgeUp = true,
  });

  final Sundial dial;
  final double time;
  final String plateWords;
  final ValueChanged<double> onDrag;
  final VoidCallback onRelease;
  final ValueChanged<int> onPoint;

  /// A short glow along the path, the way to move the sun, each time it
  /// changes ([nudgeUp]: later in the afternoon).
  final int nudge;
  final bool nudgeUp;

  static const _token = 52.0;
  static const _gap = 30.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final side = box.maxWidth;
      // The plate's edge, then the sun's path just outside it.
      final plateR = (side / 2 - _gap - _token / 2) ;
      final scale = plateR / dial.plate;
      final image = dial.pixels.width * scale;
      final centre = Offset(side / 2, side / 2);
      final orbit = plateR + _gap * 0.6;
      Offset onOrbit(double degrees) {
        final a = degrees * math.pi / 180;
        return centre + Offset(math.sin(a) * orbit, -math.cos(a) * orbit);
      }

      double angleOf(Offset local) {
        final d = local - centre;
        return (math.atan2(d.dx, -d.dy) * 180 / math.pi + 360) % 360;
      }

      final sun = onOrbit(dial.sunAngleAt(time));
      return SizedBox(
        width: side,
        height: side,
        // Dragged either way: the dial takes the finger before the page can
        // scroll (a pan would lose an up-and-down drag to the page).
        child: GestureDetector(
          key: const ValueKey('sundial'),
          behavior: HitTestBehavior.opaque,
          onVerticalDragStart: (d) => onDrag(angleOf(d.localPosition)),
          onVerticalDragUpdate: (d) => onDrag(angleOf(d.localPosition)),
          onVerticalDragEnd: (_) => onRelease(),
          onHorizontalDragStart: (d) => onDrag(angleOf(d.localPosition)),
          onHorizontalDragUpdate: (d) => onDrag(angleOf(d.localPosition)),
          onHorizontalDragEnd: (_) => onRelease(),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: centre.dx - image / 2,
                top: centre.dy - image / 2,
                width: image,
                height: image,
                child: Image.asset(dial.file, fit: BoxFit.fill, excludeFromSemantics: true),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _SundialInk(dial: dial, time: time, centre: centre, scale: scale, orbit: orbit, words: plateWords),
                ),
              ),
              if (nudge > 0 && !_still(context))
                Positioned.fill(
                  child: IgnorePointer(
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey('sun-nudge-$nudge'),
                      tween: Tween(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 900),
                      builder: (context, t, _) => CustomPaint(
                        painter: _Nudge(dial: dial, from: time, up: nudgeUp, t: t, centre: centre, orbit: orbit),
                      ),
                    ),
                  ),
                ),
              // The path's points: tapped, the sun goes there.
              for (final l in dial.lines)
                Positioned(
                  left: onOrbit(l.angle + 180).dx - 24,
                  top: onOrbit(l.angle + 180).dy - 24,
                  width: 48,
                  height: 48,
                  child: Semantics(
                    button: true,
                    label: 'Move the sun to ${clockText(l.time)}',
                    excludeSemantics: true,
                    child: GestureDetector(
                      key: ValueKey('sun-point-${l.time}'),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onPoint(l.time),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              // The sun.
              Positioned(
                key: const ValueKey('sun-token'),
                left: sun.dx - _token / 2,
                top: sun.dy - _token / 2,
                width: _token,
                height: _token,
                child: IgnorePointer(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.navy,
                      border: Border.all(color: AppColors.goldLight, width: 2),
                      boxShadow: [BoxShadow(color: AppColors.goldLight.withValues(alpha: 0.55), blurRadius: 14)],
                    ),
                    child: const Center(child: InkIcon(InkGlyph.sun, size: 34, color: AppColors.goldLight)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// On the sundial: the hours' numbers and half-hour dots on its rim, the
/// sun's dotted path, and the shadow.
class _SundialInk extends CustomPainter {
  const _SundialInk({required this.dial, required this.time, required this.centre, required this.scale, required this.orbit, required this.words});

  final Sundial dial;
  final double time;
  final Offset centre;
  final double scale;
  final double orbit;
  final String words;

  Offset _at(double degrees, double r) {
    final a = degrees * math.pi / 180;
    return centre + Offset(math.sin(a) * r, -math.cos(a) * r);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // The sun's path: dots from the first hour's place to the last.
    final pathPaint = Paint()..color = AppColors.goldDeep.withValues(alpha: 0.55);
    final from = dial.lines.first.angle + 180, to = dial.lines.last.angle + 180;
    for (var d = from; d <= to + 0.01; d += 4) {
      canvas.drawCircle(_at(d, orbit), 1.6, pathPaint);
    }
    for (final l in dial.lines) {
      canvas.drawCircle(_at(l.angle + 180, orbit), 4, Paint()..color = AppColors.goldDeep);
    }
    // The hours on the rim, by their own lines (never spread evenly).
    final rim = (dial.radius + (dial.plate - dial.radius) * 0.45) * scale;
    for (final l in dial.lines) {
      if (l.time % 60 == 0) {
        final tp = TextPainter(
          text: TextSpan(text: '${l.time ~/ 60}', style: AppText.style(AppText.italic, size: math.max(14, 34 * scale * 1.6), weight: FontWeight.w700, color: AppColors.walnutDeep)),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, _at(l.angle, rim) - Offset(tp.width / 2, tp.height / 2));
      } else {
        canvas.drawCircle(_at(l.angle, rim), math.max(2.4, 6 * scale), Paint()..color = AppColors.walnutDeep);
      }
    }
    // The shadow: from the hub along the hour, longer and darker later.
    final angle = dial.angleAt(time);
    final length = dial.lengthAt(time) * dial.radius * scale;
    final f = ((time - dial.first) / (dial.last - dial.first)).clamp(0.0, 1.0);
    final tip = _at(angle, length);
    final half = math.max(7.0, 22 * scale);
    final side = _at(angle + 90, half) - centre;
    final path = Path()
      ..moveTo(centre.dx + side.dx, centre.dy + side.dy)
      ..lineTo(tip.dx, tip.dy)
      ..lineTo(centre.dx - side.dx, centre.dy - side.dy)
      ..close();
    canvas.drawPath(path, Paint()..color = AppColors.navyDeep.withValues(alpha: 0.55 + 0.25 * f));
  }

  @override
  bool shouldRepaint(_SundialInk old) => old.time != time || old.scale != scale || old.orbit != orbit;
}

/// A glow running along the sun's path from [from], later ([up]) or
/// earlier: which way to move the sun.
class _Nudge extends CustomPainter {
  const _Nudge({required this.dial, required this.from, required this.up, required this.t, required this.centre, required this.orbit});

  final Sundial dial;
  final double from;
  final bool up;
  final double t;
  final Offset centre;
  final double orbit;

  @override
  void paint(Canvas canvas, Size size) {
    final to = (from + (up ? 1 : -1) * 45 * t).clamp(dial.first.toDouble(), dial.last.toDouble());
    final a = (dial.sunAngleAt(to)) * math.pi / 180;
    final p = centre + Offset(math.sin(a) * orbit, -math.cos(a) * orbit);
    canvas.drawCircle(p, 10, Paint()..color = AppColors.goldLight.withValues(alpha: 0.8 * (1 - t)));
  }

  @override
  bool shouldRepaint(_Nudge old) => old.t != t || old.from != from;
}

/// The Shadow Check, drawn: the sundial in the two photos, each with its
/// shadow and the times.
class ShadowCardView extends StatelessWidget {
  const ShadowCardView({super.key, required this.card});

  final ShadowCard card;

  @override
  Widget build(BuildContext context) {
    final scene = card.scene;
    final dial = scene.sundial;
    return AspectRatio(
      aspectRatio: card.aspect,
      child: ColoredBox(
        color: AppColors.paperLight,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xs),
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: 420,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final (i, p) in scene.photos.indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        children: [
                          _PhotoCrop(photo: scene.photo, crop: scene.photo.dialCrop, at: p.number, dialAngle: dial.angleAt(p.sun.toDouble()), dialLength: dial.lengthAt(p.sun.toDouble())),
                          const SizedBox(height: 4),
                          Text(p.name, style: AppText.mark()),
                          Text('T1 ${clockText(p.t1)} · SUN ${clockText(p.sun)}', style: AppText.bodyText(size: 15, weight: FontWeight.w700, color: p.t1 == p.sun ? AppColors.success : AppColors.tryAgain)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Final — the hour was recorded ───────────────────────────────────────

/// The final's first two steps ([HourRecordScene]): Photo 2 found on the
/// tape ([found]; the sun's times then laid under it), then page 3 found
/// missing from the Trial Log ([pageFound]). A wrong mark or page is said
/// why, never a wrong answer.
class HourRecordPuzzle extends StatefulWidget {
  const HourRecordPuzzle({super.key, required this.scene, required this.found, required this.pageFound, required this.onFound, required this.onPage});

  final HourRecordScene scene;
  final bool found;
  final bool pageFound;
  final VoidCallback onFound;
  final VoidCallback onPage;

  @override
  State<HourRecordPuzzle> createState() => _HourRecordPuzzleState();
}

class _HourRecordPuzzleState extends State<HourRecordPuzzle> {
  String? _line;
  bool _good = false;
  int _wrong = 0;
  late int _page = 0;
  final _scroll = ScrollController();

  HourRecordScene get _scene => widget.scene;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _tapMark(String id) {
    if (widget.found) return;
    if (id == _scene.photo2Mark) {
      setState(() {
        _line = null;
        _good = true;
      });
      widget.onFound();
      // The hour from three to four brought into view.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_scroll.hasClients) return;
        final target = (_scene.tape.indexOf('t5') * 72.0 - 20).clamp(0.0, _scroll.position.maxScrollExtent);
        _still(context) ? _scroll.jumpTo(target) : _scroll.animateTo(target, duration: const Duration(milliseconds: 600), curve: Curves.easeOutCubic);
      });
    } else {
      setState(() {
        _good = false;
        _wrong++;
        _line = _scene.tape.mark(id).printed == _scene.tape.mark(_scene.photo2Mark).printed ? _scene.firstTwoThirty : _scene.notTwoThirty;
      });
    }
  }

  void _tapPage(LogPage p) {
    if (widget.pageFound) return;
    if (!p.inBook) {
      setState(() {
        _line = null;
        _good = true;
      });
      widget.onPage();
    } else {
      setState(() {
        _good = false;
        _wrong++;
        _line = _scene.pageInBook;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scene = _scene;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.found ? scene.pageTask : scene.tapeTask,
          key: const ValueKey('record-task'),
          textAlign: TextAlign.center,
          style: AppText.bodyText(size: 15, weight: FontWeight.w600, color: AppColors.navy),
        ),
        const SizedBox(height: AppSpace.sm),
        _Shake(
          trigger: widget.found ? 0 : _wrong,
          child: TapeTimeline(scene: scene, found: widget.found, controller: _scroll, onTap: widget.found ? null : _tapMark),
        ),
        if (widget.found) ...[
          const SizedBox(height: AppSpace.sm),
          for (final l in scene.foundLines)
            Padding(padding: const EdgeInsets.only(bottom: AppSpace.xs), child: _Say(l, good: true)),
          const SizedBox(height: AppSpace.sm),
          _Shake(
            trigger: widget.pageFound ? 0 : _wrong,
            child: TrialLogView(
              scene: scene,
              page: scene.inBook[_page.clamp(0, scene.inBook.length - 1)],
              pageFound: widget.pageFound,
              onTurn: (d) => setState(() => _page = (_page + d).clamp(0, scene.inBook.length - 1)),
              onPick: _tapPage,
            ),
          ),
          if (widget.pageFound) ...[
            const SizedBox(height: AppSpace.sm),
            _Say(scene.pageFoundLine, good: true),
          ],
        ],
        ConstrainedBox(constraints: const BoxConstraints(minHeight: 40), child: Center(child: _line == null ? null : _Say(_line!, good: _good))),
      ],
    );
  }
}

/// T1's tape on the table: Photo 1 pinned at its mark, Photo 2 once found
/// ([found]); then the sun's times laid under the marks, the hour from
/// three to four in gold, and the two jumps named.
class TapeTimeline extends StatelessWidget {
  const TapeTimeline({super.key, required this.scene, required this.found, this.controller, this.onTap});

  final HourRecordScene scene;
  final bool found;
  final ScrollController? controller;
  final ValueChanged<String>? onTap;

  static const cell = 72.0;

  @override
  Widget build(BuildContext context) {
    final tape = scene.tape;
    final band = found ? {for (final m in tape.marks) if (scene.realAt(m.id) >= 180 && scene.realAt(m.id) < 240) m.id} : <String>{};
    final pins = {
      scene.photo1Mark: scene.photos.first,
      if (found) scene.photo2Mark: scene.photos.last,
    };
    final width = cell * tape.marks.length + cell * 0.5;
    Widget row(double height, Widget Function(TapeMark m, int i) build) => SizedBox(
      width: width,
      height: height,
      child: Row(children: [for (final (i, m) in tape.marks.indexed) SizedBox(width: cell, height: height, child: build(m, i))]),
    );
    final still = _still(context);
    return SingleChildScrollView(
      key: const ValueKey('record-tape'),
      controller: controller,
      scrollDirection: Axis.horizontal,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The photos pinned over their marks.
          row(40, (m, _) {
            final p = pins[m.id];
            if (p == null) return const SizedBox.shrink();
            return Center(
              child: Container(
                key: ValueKey('record-pin-${p.id}'),
                padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
                decoration: BoxDecoration(color: AppColors.navy, borderRadius: BorderRadius.circular(4)),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('${p.name}\nSUN ${clockText(p.sun)}', textAlign: TextAlign.center, style: AppText.bodyText(size: 11, weight: FontWeight.w700, color: AppColors.goldLight).copyWith(height: 1.15)),
                ),
              ),
            );
          }),
          TapeStrip(scene: tape, cell: cell, height: 74, band: band, onTap: onTap),
          if (found) ...[
            // The sun's times, laid one by one.
            row(30, (m, i) => TweenAnimationBuilder<double>(
              tween: Tween(begin: still ? 1 : 0, end: 1),
              duration: Duration(milliseconds: still ? 0 : 300 + i * 160),
              curve: Curves.easeIn,
              builder: (context, t, child) => Opacity(opacity: ((t * (i + 3) - i) / 3).clamp(0, 1), child: child),
              child: Container(
                key: ValueKey('record-sun-${m.id}'),
                alignment: Alignment.center,
                color: band.contains(m.id) ? AppColors.gold.withValues(alpha: 0.35) : null,
                child: Text(
                  clockText(scene.realAt(m.id)),
                  style: AppText.bodyText(size: 15, weight: FontWeight.w700, color: AppColors.goldDeep).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                ),
              ),
            )),
            row(24, (m, i) {
              final text = m.id == 't5' ? scene.backLabel : m.id == 't9' ? scene.rightLabel : null;
              if (text == null) return const SizedBox.shrink();
              return FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('${m.id == 't5' ? '↶' : '↷'} $text', key: ValueKey('record-jump-${m.id}'), style: AppText.bodyText(size: 12, weight: FontWeight.w700, color: AppColors.tryAgain)),
              );
            }),
            Padding(
              padding: const EdgeInsets.only(left: 4, top: 2),
              child: Text("THE SUN'S TIME", style: AppText.eyebrow()),
            ),
          ],
        ],
      ),
    );
  }
}

/// The Trial Log, open: its contents on the left page, the page turned to
/// on the right ([page], turned with ◀ ▶: [onTurn]); under it, the
/// contents again as lines to tap ([onPick]), a finger wide each.
class TrialLogView extends StatelessWidget {
  const TrialLogView({super.key, required this.scene, required this.page, required this.pageFound, required this.onTurn, required this.onPick});

  final HourRecordScene scene;
  final LogPage page;
  final bool pageFound;
  final ValueChanged<int> onTurn;
  final ValueChanged<LogPage> onPick;

  @override
  Widget build(BuildContext context) {
    final inBook = scene.inBook;
    final i = inBook.indexOf(page);
    final l = scene.leftPage, r = scene.rightPage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          label: 'The Trial Log, open on page ${page.number}: ${clockText(page.from)} to ${clockText(page.to)}',
          excludeSemantics: true,
          child: PictureCanvas(
            key: const ValueKey('trial-log'),
            pixels: scene.logPixels,
            child: Stack(
              children: [
                Positioned.fill(child: Image.asset(scene.logFile, fit: BoxFit.fill, excludeFromSemantics: true)),
                Positioned.fromRect(rect: scene.emblem.deflate(4), child: const FittedBox(child: InkIcon(InkGlyph.gear, size: 30, color: AppColors.inkBrown))),
                // The contents.
                Positioned(
                  left: l.left + 60,
                  top: l.top + 70,
                  width: l.width - 110,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(scene.logTitle, style: AppText.style(AppText.display, size: 40, color: AppColors.inkBrown)),
                      const SizedBox(height: 18),
                      Text('CONTENTS', style: AppText.style(AppText.display, size: 30, color: AppColors.muted)),
                      const SizedBox(height: 12),
                      for (final p in scene.pages)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 22),
                          child: Text(
                            p.line,
                            style: AppText.style(AppText.italic, size: 38, color: !p.inBook && pageFound ? AppColors.tryAgain : AppColors.inkBrown, fontStyle: FontStyle.italic),
                          ),
                        ),
                    ],
                  ),
                ),
                // The page turned to: its number and hour; its words too faded to read.
                Positioned(
                  left: r.left + 50,
                  top: r.top + 50,
                  width: r.width - 100,
                  height: r.height - 100,
                  child: AnimatedSwitcher(
                    duration: _still(context) ? Duration.zero : const Duration(milliseconds: 300),
                    child: Column(
                      key: ValueKey('trial-log-page-${page.id}'),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('p.${page.number}', style: AppText.style(AppText.display, size: 120, color: AppColors.inkBrown, height: 1)),
                        Text('${clockText(page.from)} – ${clockText(page.to)}', style: AppText.style(AppText.italic, size: 54, color: AppColors.inkBrown, fontStyle: FontStyle.italic)),
                        const SizedBox(height: 20),
                        const Expanded(child: CustomPaint(painter: _FadedWords(), size: Size.infinite)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpace.xs),
        Row(
          children: [
            IconButton(
              key: const ValueKey('trial-log-back'),
              tooltip: 'Turn back a page',
              onPressed: i > 0 ? () => onTurn(-1) : null,
              icon: const InkIcon(InkGlyph.back, size: 24, color: AppColors.goldDeep),
            ),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'IN THE BOOK: ${[for (final p in inBook) 'p.${p.number}'].join(' · ')}',
                  key: const ValueKey('trial-log-turned'),
                  maxLines: 1,
                  style: AppText.bodyText(size: 14, weight: FontWeight.w700, color: AppColors.navy),
                ),
              ),
            ),
            IconButton(
              key: const ValueKey('trial-log-next'),
              tooltip: 'Turn to the next page',
              onPressed: i < inBook.length - 1 ? () => onTurn(1) : null,
              icon: const InkIcon(InkGlyph.arrow, size: 24, color: AppColors.goldDeep),
            ),
          ],
        ),
        Text('CONTENTS', textAlign: TextAlign.center, style: AppText.eyebrow()),
        const SizedBox(height: AppSpace.xs),
        for (final p in scene.pages)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Semantics(
              button: true,
              label: 'Page ${p.number}: ${clockText(p.from)} to ${clockText(p.to)}',
              excludeSemantics: true,
              child: Material(
                color: !p.inBook && pageFound ? AppColors.tryAgainSoft : AppColors.paperLight,
                borderRadius: BorderRadius.circular(AppRadius.button),
                child: InkWell(
                  key: ValueKey('trial-log-line-${p.id}'),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  onTap: pageFound ? null : () => onPick(p),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
                      child: Row(
                        children: [
                          Expanded(child: Text(p.line, style: AppText.bodyText(size: 16, weight: FontWeight.w600, color: AppColors.ink))),
                          if (!p.inBook && pageFound) Text('NOT IN THE BOOK', style: AppText.bodyText(size: 12, weight: FontWeight.w700, color: AppColors.tryAgain)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Handwriting too faded to read: soft ink strokes on the page's rules.
class _FadedWords extends CustomPainter {
  const _FadedWords();

  @override
  void paint(Canvas canvas, Size size) {
    final ink = Paint()
      ..color = AppColors.inkBrown.withValues(alpha: 0.28)
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    final rnd = math.Random(7);
    for (var y = 20.0; y < size.height - 10; y += 34) {
      var x = 0.0;
      final end = size.width * (0.7 + rnd.nextDouble() * 0.3);
      while (x < end) {
        final w = 30 + rnd.nextDouble() * 70;
        canvas.drawLine(Offset(x, y), Offset(math.min(x + w, end), y + (rnd.nextDouble() - 0.5) * 4), ink);
        x += w + 16;
      }
    }
  }

  @override
  bool shouldRepaint(_FadedWords old) => false;
}

/// T1 Drum Tape (and The Hour Was Recorded), drawn: the tape, its jumps
/// ringed; with the record, the sun's times under it.
class TapeCardView extends StatelessWidget {
  const TapeCardView({super.key, required this.card});

  final TapeCard card;

  @override
  Widget build(BuildContext context) {
    final record = card.record;
    return AspectRatio(
      aspectRatio: card.aspect,
      child: ColoredBox(
        color: AppColors.parchment,
        child: Padding(
          padding: const EdgeInsets.all(AppSpace.xs),
          child: FittedBox(
            fit: BoxFit.contain,
            child: IgnorePointer(
              child: record == null
                  ? TapeStrip(scene: card.scene, cell: 64, circled: card.scene.jumps, jumpLabels: true)
                  : MediaQuery(
                      data: MediaQuery.of(context).copyWith(disableAnimations: true),
                      child: TapeTimeline(scene: record, found: true),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── After the case — the record list ────────────────────────────────────

/// The record list read (the case's last step; true once done): page 3's
/// line found, and the place the list names lit on the map.
Future<bool?> showRecordListLead(BuildContext context, RecordListLead lead) {
  final still = _still(context);
  return Navigator.of(context).push<bool>(
    PageRouteBuilder<bool>(
      opaque: false,
      barrierDismissible: false,
      barrierColor: AppColors.navyDeep.withValues(alpha: 0.975),
      transitionDuration: still ? Duration.zero : const Duration(milliseconds: 250),
      pageBuilder: (context, anim, _) => FadeTransition(opacity: anim, child: _RecordListPage(lead: lead)),
    ),
  );
}

class _RecordListPage extends StatefulWidget {
  const _RecordListPage({required this.lead});

  final RecordListLead lead;

  @override
  State<_RecordListPage> createState() => _RecordListPageState();
}

class _RecordListPageState extends State<_RecordListPage> {
  String? _line;
  bool _found = false;

  RecordListLead get _lead => widget.lead;

  void _pick(String id) => setState(() {
    if (id == _lead.answer) {
      _found = true;
      _line = null;
    } else {
      _line = _lead.otherLine;
    }
  });

  @override
  Widget build(BuildContext context) => Material(
    type: MaterialType.transparency,
    child: SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpace.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(_lead.title, textAlign: TextAlign.center, style: AppText.mark(color: AppColors.goldLight)),
                const SizedBox(height: AppSpace.md),
                // The list, inside the book's back cover.
                Container(
                  key: const ValueKey('record-list'),
                  padding: const EdgeInsets.all(AppSpace.md),
                  decoration: BoxDecoration(
                    color: AppColors.paperLight,
                    borderRadius: BorderRadius.circular(AppRadius.paper),
                    border: Border.all(color: AppColors.goldDeep, width: 2),
                    boxShadow: AppShadow.pinned,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(_lead.heading, textAlign: TextAlign.center, style: AppText.style(AppText.display, size: 19, color: AppColors.inkBrown)),
                      const SizedBox(height: AppSpace.sm),
                      for (final l in _lead.lines)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Semantics(
                            button: !_found,
                            label: l.text,
                            excludeSemantics: true,
                            child: Material(
                              color: _found && l.id == _lead.answer ? AppColors.creamGold : Colors.transparent,
                              borderRadius: BorderRadius.circular(AppRadius.button),
                              child: InkWell(
                                key: ValueKey('record-line-${l.id}'),
                                borderRadius: BorderRadius.circular(AppRadius.button),
                                onTap: _found ? null : () => _pick(l.id),
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(minHeight: 48),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm, vertical: AppSpace.xs),
                                      child: Text(l.text, style: AppText.bodyText(size: 15, weight: FontWeight.w600, color: AppColors.ink)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
                if (!_found) ...[
                  Text(_lead.question, key: const ValueKey('record-question'), textAlign: TextAlign.center, style: AppText.title(size: 20, color: AppColors.goldLight)),
                  if (_line != null) ...[const SizedBox(height: AppSpace.sm), _Say(_line!, dark: true)],
                ] else ...[
                  _RecordMap(lead: _lead),
                  const SizedBox(height: AppSpace.md),
                  for (final l in _lead.doneLines) ...[_Say(l, good: true, dark: true), const SizedBox(height: AppSpace.xs)],
                  const SizedBox(height: AppSpace.md),
                  GameButton(
                    key: const ValueKey('record-done'),
                    label: 'CONTINUE',
                    arrow: true,
                    style: GameButtonStyle.glass,
                    tap: TapRole.primary,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// The map of Paris, the place the list names ringed in gold, its name
/// beside it.
class _RecordMap extends StatelessWidget {
  const _RecordMap({required this.lead});

  final RecordListLead lead;

  @override
  Widget build(BuildContext context) {
    final p = lead.mapPixels;
    final at = Offset(lead.spot.at.dx * p.width, lead.spot.at.dy * p.height);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.paper),
      child: Semantics(
        label: 'A map of Paris: ${lead.spot.name} ringed in gold, just north of the Luxembourg Gardens.',
        child: PictureCanvas(
          key: const ValueKey('record-map'),
          pixels: p,
          child: Stack(
            children: [
              Positioned.fill(child: Image.asset(lead.mapFile, fit: BoxFit.fill, excludeFromSemantics: true)),
              Positioned(
                left: at.dx - 100,
                top: at.dy - 100,
                width: 200,
                height: 200,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: _still(context) ? 1 : 0.4, end: 1),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutBack,
                  builder: (context, s, child) => Transform.scale(scale: s, child: child),
                  child: DecoratedBox(
                    key: const ValueKey('record-map-ring'),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.goldLight, width: 14),
                      boxShadow: [BoxShadow(color: AppColors.navyDeep.withValues(alpha: 0.6), blurRadius: 6)],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: at.dx + 110,
                top: at.dy - 40,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(color: AppColors.navy.withValues(alpha: 0.88), borderRadius: BorderRadius.circular(10)),
                  child: Text(lead.spot.name, style: AppText.style(AppText.display, size: 52, color: AppColors.goldLight)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
