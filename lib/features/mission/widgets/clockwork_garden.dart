import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/audio_service.dart' show TapRole;
import '../../../data/models/garden_puzzles.dart';
import '../../../data/models/scene_explore.dart' show ScenePixels;
import '../../../widgets/game_button.dart';
import '../../../widgets/ink_icon.dart';
import '../../../widgets/landmark_art.dart' show ClockHandsPainter;
import 'river_papers.dart' show PictureCanvas;
import 'star_records.dart' show PlateCloser, StarRoomPicture;

/// Season 2, Case 09 — The Clockwork Garden, played on its pictures
/// (`docs/SEASON2_CASE09_SPEC.md`): the little clocks put back on the map,
/// the gears fitted on the board, the marks joined on the old plan, the
/// tower set one hour back, and the star followed after the case.

bool _still(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

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
        key: ValueKey('garden-line-$line'),
        textAlign: TextAlign.center,
        style: AppText.letter(
          size: 17,
          color: dark
              ? (good ? AppColors.goldLight : AppColors.paperLight)
              : (good ? AppColors.success : AppColors.tryAgain),
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

// ── Clock faces ─────────────────────────────────────────────────────────

/// The case's dial ([file]) with the app's hands at [hourDegrees] and
/// [minuteDegrees] (clockwise from 12). [hands] 0 → 1 brings the hands in
/// (0: none on it).
class DialFace extends StatelessWidget {
  const DialFace({
    super.key,
    required this.file,
    required this.pixels,
    required this.pivot,
    required this.faceRadius,
    required this.hourDegrees,
    this.minuteDegrees = 0,
    this.hands = 1,
  });

  final String file;
  final ScenePixels pixels;
  final Offset pivot;
  final double faceRadius;
  final double hourDegrees;
  final double minuteDegrees;
  final double hands;

  static double degreesAt(num hour) => (hour % 12) * 30.0;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: pixels.aspect,
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(file, fit: BoxFit.fill, excludeFromSemantics: true),
        CustomPaint(painter: _DialHands(dial: this)),
      ],
    ),
  );
}

class _DialHands extends CustomPainter {
  const _DialHands({required this.dial});

  final DialFace dial;

  @override
  void paint(Canvas canvas, Size size) {
    if (dial.hands <= 0) return;
    final scale = size.width / dial.pixels.width;
    final r = dial.faceRadius * scale;
    // The hands come in from above, settling on the pivot.
    final slide = (1 - Curves.easeOutCubic.transform(dial.hands.clamp(0, 1))) * r * 0.9;
    final pivot = Offset(dial.pivot.dx * scale, dial.pivot.dy * scale - slide);
    if (dial.hands < 1) canvas.saveLayer(Offset.zero & size, Paint()..color = Color.fromRGBO(0, 0, 0, dial.hands.clamp(0, 1)));
    ClockHandsPainter.paintHand(canvas, pivot, dial.minuteDegrees, length: r * 0.84, width: r * 0.075, tip: 1.1);
    ClockHandsPainter.paintHand(canvas, pivot, dial.hourDegrees, length: r * 0.56, width: r * 0.11, tip: 1.6);
    ClockHandsPainter.paintCap(canvas, pivot, r * 0.09);
    if (dial.hands < 1) canvas.restore();
  }

  @override
  bool shouldRepaint(_DialHands old) =>
      old.dial.hourDegrees != dial.hourDegrees || old.dial.minuteDegrees != dial.minuteDegrees || old.dial.hands != dial.hands;
}

/// A picture with a painted clock covered by the case's dial at its hour
/// ([GardenClock]); its other parts [child], in the picture's pixels.
class GardenPicture extends StatelessWidget {
  const GardenPicture({super.key, required this.file, required this.pixels, required this.clock, required this.label, this.child});

  final String file;
  final ScenePixels pixels;
  final GardenClock clock;
  final String label;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final face = clock.face;
    // The dial sized so its white face fills the painted one, its pivot on
    // the painted face's centre.
    final s = (face.width / 2) / clock.faceRadius;
    final size = clock.dialPixels.width * s;
    return Semantics(
      image: true,
      label: label,
      excludeSemantics: true,
      child: PictureCanvas(
        pixels: pixels,
        child: Stack(
          children: [
            Positioned.fill(child: Image.asset(file, fit: BoxFit.fill, excludeFromSemantics: true)),
            Positioned(
              key: const ValueKey('garden-clock-cover'),
              left: face.center.dx - clock.pivot.dx * s,
              top: face.center.dy - clock.pivot.dy * s,
              width: size,
              height: size,
              child: DialFace(
                file: clock.dial,
                pixels: clock.dialPixels,
                pivot: clock.pivot,
                faceRadius: clock.faceRadius,
                hourDegrees: DialFace.degreesAt(clock.hour),
              ),
            ),
            ?child,
          ],
        ),
      ),
    );
  }
}

// ── The opening ─────────────────────────────────────────────────────────

/// P.'s last drawing under the opening's lines, turning into the garden
/// once the detective walks in ([turned]). Case 10: the arch, T1's star laid
/// over it for its lines ([IntroPicture.inset]), turning into the room
/// under the roof, its things ringed line by line ([line]) and its plate
/// shown up close on the plate's line.
class IntroPictureView extends StatelessWidget {
  const IntroPictureView({super.key, required this.picture, required this.turned, this.line = -1});

  final IntroPicture picture;
  final bool turned;

  /// The opening's line being told (-1: none in particular).
  final int line;

  @override
  Widget build(BuildContext context) {
    final inset = picture.inset;
    final insetShown = inset != null && line >= inset.fromLine && line < inset.toLine;
    final drawing = Semantics(
      image: true,
      label: insetShown ? '${picture.fromLabel}. ${inset.label}' : picture.fromLabel,
      excludeSemantics: true,
      child: PictureCanvas(
        key: const ValueKey('intro-picture-drawing'),
        pixels: picture.pixels,
        child: Stack(
          children: [
            Positioned.fill(child: Image.asset(picture.from, fit: BoxFit.fill, excludeFromSemantics: true)),
            if (inset != null)
              // T1 and its star, in the corner while the lines tell of it.
              Positioned(
                right: picture.pixels.width * 0.03,
                bottom: picture.pixels.height * 0.03,
                width: picture.pixels.width * 0.32,
                height: picture.pixels.width * 0.32,
                child: AnimatedOpacity(
                  key: const ValueKey('intro-picture-inset'),
                  opacity: insetShown ? 1 : 0,
                  duration: _still(context) ? Duration.zero : const Duration(milliseconds: 500),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.navyDeep.withValues(alpha: 0.72),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.goldLight, width: 8),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(36),
                      child: Image.asset(inset.file, fit: BoxFit.contain, excludeFromSemantics: true),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    final clock = picture.clock;
    final room = picture.room;
    final ring = [for (final m in picture.marks) if (m.line == line) m.area].firstOrNull;
    final plateUp = room != null && ring != null && ring.contains(room.plateCentre);
    final garden = room != null
        ? LayoutBuilder(
            builder: (context, box) => Stack(
              children: [
                StarRoomPicture(room: room, ring: ring),
                // The plate's words are small in the room: up close, here.
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: AnimatedOpacity(
                    opacity: plateUp ? 1 : 0,
                    duration: _still(context) ? Duration.zero : const Duration(milliseconds: 450),
                    child: PlateCloser(room: room, size: math.min(box.maxWidth * 0.5, 170)),
                  ),
                ),
              ],
            ),
          )
        : clock == null
        ? PictureCanvas(pixels: picture.pixels, child: Image.asset(picture.to, fit: BoxFit.fill, excludeFromSemantics: true))
        : GardenPicture(file: picture.to, pixels: picture.pixels, clock: clock, label: picture.toLabel);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.paper),
      child: AnimatedCrossFade(
        duration: _still(context) ? Duration.zero : const Duration(milliseconds: 1400),
        sizeCurve: Curves.easeInOut,
        firstCurve: Curves.easeIn,
        secondCurve: Curves.easeOut,
        crossFadeState: turned ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        firstChild: drawing,
        secondChild: KeyedSubtree(key: const ValueKey('intro-picture-garden'), child: garden),
      ),
    );
  }
}

// ── M1 — the little clocks back on the map ──────────────────────────────

/// M1 ([TrialMapScene]): the map of Paris carved on the base and the three
/// little clocks in their box under it. A clock dragged (or tapped, then a
/// place tapped) onto its own place snaps there and stays ([onPlaced],
/// saved); anywhere else it goes back to the box with its line, never a
/// wrong answer. All three in: the mission's answer ([onSubmit]).
class TrialMapPuzzle extends StatefulWidget {
  const TrialMapPuzzle({super.key, required this.scene, required this.placed, required this.onPlaced, required this.onSubmit});

  final TrialMapScene scene;
  final Map<String, String> placed;
  final ValueChanged<Map<String, String>> onPlaced;
  final Future<void> Function(String answer) onSubmit;

  @override
  State<TrialMapPuzzle> createState() => _TrialMapPuzzleState();
}

class _TrialMapPuzzleState extends State<TrialMapPuzzle> {
  final _mapKey = GlobalKey();
  late Map<String, String> _placed = {...widget.placed};
  String? _picked;
  String? _line;
  bool _good = false;
  final Map<String, int> _sentBack = {};
  bool _done = false;
  Timer? _submit;

  TrialMapScene get _scene => widget.scene;

  @override
  void initState() {
    super.initState();
    _done = _placed.length == _scene.models.length;
    if (_done) _later();
  }

  @override
  void dispose() {
    _submit?.cancel();
    super.dispose();
  }

  void _later() => _submit = Timer(const Duration(milliseconds: 900), () {
    if (mounted) widget.onSubmit(_scene.answerOf(_placed));
  });

  /// Map pixels of a point [global] on the screen, or null off the map.
  Offset? _onMap(Offset global) {
    final box = _mapKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final local = box.globalToLocal(global);
    if (!(Offset.zero & box.size).contains(local)) return null;
    return local * (_scene.mapPixels.width / box.size.width);
  }

  void _drop(String id, Offset? px) {
    if (_done || _placed.containsKey(id)) return;
    final spot = px == null ? null : _scene.spotNear(px);
    setState(() {
      _picked = null;
      if (spot == null) {
        _line = 'Lay it on a place on the map.';
        _good = false;
        _sentBack[id] = (_sentBack[id] ?? 0) + 1;
      } else if (spot.id == _scene.model(id).spot) {
        _placed = {..._placed, id: spot.id};
        _line = _scene.placedLine;
        _good = true;
        _done = _placed.length == _scene.models.length;
      } else {
        _line = _scene.lineFor(id, spot.id);
        _good = false;
        _sentBack[id] = (_sentBack[id] ?? 0) + 1;
      }
    });
    if (_placed.containsKey(id)) {
      widget.onPlaced(_placed);
      if (_done) _later();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scene = _scene;
    final waiting = [for (final m in scene.models) if (!_placed.containsKey(m.id)) m];
    return LayoutBuilder(
      builder: (context, box) {
        // Three in a row, each with its margins, never wider than the page.
        final tile = math.min(120.0, (box.maxWidth - AppSpace.xs * 6) / 3);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(scene.task, key: const ValueKey('trial-task'), textAlign: TextAlign.center, style: AppText.bodyText(size: 15, weight: FontWeight.w600, color: AppColors.navy)),
            const SizedBox(height: AppSpace.sm),
            DragTarget<String>(
              // Laid where its base is: just above the finger (the clock is
              // held above it, never under it).
              onAcceptWithDetails: (d) => _drop(d.data, _onMap(d.offset - const Offset(0, 10))),
              builder: (context, candidates, _) => ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.paper),
                child: Semantics(
                  label: 'A map of Paris carved on the stone base.',
                  child: GestureDetector(
                    key: const ValueKey('trial-map'),
                    behavior: HitTestBehavior.opaque,
                    onTapUp: _picked == null
                        ? (_) => setState(() {
                            _line = 'First tap a little clock in the box.';
                            _good = false;
                          })
                        : (d) => _drop(_picked!, _onMap(d.globalPosition)),
                    child: PictureCanvas(
                      key: _mapKey,
                      pixels: scene.mapPixels,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(child: Image.asset(scene.mapFile, fit: BoxFit.fill, excludeFromSemantics: true)),
                          // Every place a little clock could go, ringed.
                          for (final s in scene.spots)
                            Positioned(
                              left: s.at.dx * scene.mapPixels.width - 46,
                              top: s.at.dy * scene.mapPixels.height - 46,
                              width: 92,
                              height: 92,
                              child: IgnorePointer(
                                child: _Ring(color: candidates.isNotEmpty || _picked != null ? AppColors.goldLight : AppColors.paperLight, width: 7),
                              ),
                            ),
                          for (final m in scene.models)
                            if (_placed[m.id] case final spotId?)
                              _PlacedModel(scene: scene, model: m, at: scene.spots.firstWhere((s) => s.id == spotId).at),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            ConstrainedBox(constraints: const BoxConstraints(minHeight: 48), child: Center(child: _line == null ? null : _Say(_line!, good: _good))),
            Text(
              waiting.isEmpty ? 'ALL BACK IN PLACE' : 'IN THE BOX',
              textAlign: TextAlign.center,
              style: AppText.eyebrow(),
            ),
            const SizedBox(height: AppSpace.xs),
            SizedBox(
              height: tile + 28,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final m in scene.models)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
                      child: _placed.containsKey(m.id)
                          ? SizedBox(width: tile)
                          : _Shake(
                              trigger: _sentBack[m.id] ?? 0,
                              child: _ModelTile(
                                model: m,
                                size: tile,
                                picked: _picked == m.id,
                                enabled: !_done,
                                onTap: () => setState(() {
                                  _picked = _picked == m.id ? null : m.id;
                                  _line = _picked == null ? null : 'Now tap its place on the map.';
                                  _good = true;
                                }),
                              ),
                            ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A little clock in its place on the map: it lands with a small settle.
class _PlacedModel extends StatelessWidget {
  const _PlacedModel({required this.scene, required this.model, required this.at});

  final TrialMapScene scene;
  final TrialModel model;
  final Offset at;

  static const _size = 240.0;

  @override
  Widget build(BuildContext context) => Positioned(
    left: at.dx * scene.mapPixels.width - _size / 2,
    top: at.dy * scene.mapPixels.height - _size * 0.86,
    width: _size,
    height: _size,
    child: IgnorePointer(
      child: TweenAnimationBuilder<double>(
        key: ValueKey('trial-placed-${model.id}'),
        tween: Tween(begin: _still(context) ? 1 : 1.35, end: 1),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutBack,
        builder: (context, s, child) => Transform.scale(scale: s, child: child),
        child: Semantics(
          label: '${model.name} in its place',
          child: Image.asset(model.file, fit: BoxFit.contain, excludeFromSemantics: true),
        ),
      ),
    ),
  );
}

/// A little clock in the box: dragged to the map, or tapped then its place.
class _ModelTile extends StatelessWidget {
  const _ModelTile({required this.model, required this.size, required this.picked, required this.enabled, required this.onTap});

  final TrialModel model;
  final double size;
  final bool picked;
  final bool enabled;
  final VoidCallback onTap;

  Widget _card({double opacity = 1}) => Opacity(
    opacity: opacity,
    child: Container(
      width: size,
      padding: const EdgeInsets.all(AppSpace.xs),
      decoration: BoxDecoration(
        color: picked ? AppColors.goldLight.withValues(alpha: 0.35) : AppColors.paperLight,
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: picked ? AppColors.gold : AppLine.faint(0.35), width: picked ? 2.5 : AppLine.hairline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(width: size - 16, height: size - 16, child: Image.asset(model.file, fit: BoxFit.contain, excludeFromSemantics: true)),
          Text(model.name, style: AppText.button(size: 15, color: AppColors.navy)),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: picked,
    label: '${model.label}. Drag it to its place on the map, or tap it and then tap the place.',
    excludeSemantics: true,
    child: Draggable<String>(
      key: ValueKey('trial-model-${model.id}'),
      data: model.id,
      maxSimultaneousDrags: enabled ? 1 : 0,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      // Held above the finger, its base just over the fingertip.
      feedback: Transform.translate(
        offset: Offset(-size * 0.4, -size * 0.8 - 10),
        child: SizedBox(width: size * 0.8, height: size * 0.8, child: Image.asset(model.file, fit: BoxFit.contain)),
      ),
      childWhenDragging: _card(opacity: 0.3),
      child: GestureDetector(onTap: enabled ? onTap : null, child: _card()),
    ),
  );
}

/// The Trial Map, drawn: the map with each little clock in its place.
class TrialMapPaperView extends StatelessWidget {
  const TrialMapPaperView({super.key, required this.paper});

  final TrialMapPaper paper;

  @override
  Widget build(BuildContext context) {
    final scene = paper.scene;
    return PictureCanvas(
      pixels: scene.mapPixels,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: Image.asset(scene.mapFile, fit: BoxFit.fill, excludeFromSemantics: true)),
          for (final m in scene.models) _PlacedModel(scene: scene, model: m, at: scene.spots.firstWhere((s) => s.id == m.spot).at),
        ],
      ),
    );
  }
}

// ── M2 — the gear board ─────────────────────────────────────────────────

/// M2 ([GearBoardScene]): the board, the tower's wheel, two dotted places
/// and two gears in the tray. A gear dragged (or tapped, then a place
/// tapped) into the place of its size stays there ([onPlaced], saved), and
/// its branch turns; the wrong size goes back to the tray ("Too big!").
/// Both in: the tower turns T1, T2 and T3 while the garden clock stays
/// still; a moment later, the mission's answer ([onSubmit]).
class GearBoardPuzzle extends StatefulWidget {
  const GearBoardPuzzle({super.key, required this.scene, required this.placed, required this.onPlaced, required this.onSubmit});

  final GearBoardScene scene;
  final Map<String, GearSize> placed;
  final ValueChanged<Map<String, GearSize>> onPlaced;
  final Future<void> Function(String answer) onSubmit;

  @override
  State<GearBoardPuzzle> createState() => _GearBoardPuzzleState();
}

class _GearBoardPuzzleState extends State<GearBoardPuzzle> with SingleTickerProviderStateMixin {
  final _boardKey = GlobalKey();
  late final AnimationController _turn = AnimationController(vsync: this, duration: const Duration(seconds: 6));
  late Map<String, GearSize> _placed = {...widget.placed};
  GearSize? _picked;
  String? _line;
  bool _good = false;
  final Map<GearSize, int> _sentBack = {};
  Timer? _submit;

  GearBoardScene get _scene => widget.scene;
  bool get _done => _scene.slots.every((s) => _placed[s.id] == s.size);

  @override
  void initState() {
    super.initState();
    if (_done) {
      _line = _scene.turningLine;
      _good = true;
      _later();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _spin();
  }

  void _spin() {
    if (_placed.isEmpty || _still(context)) {
      _turn.stop();
    } else if (!_turn.isAnimating) {
      _turn.repeat();
    }
  }

  @override
  void dispose() {
    _submit?.cancel();
    _turn.dispose();
    super.dispose();
  }

  void _later() => _submit = Timer(const Duration(milliseconds: 2800), () {
    if (mounted) widget.onSubmit(_scene.answerOf(_placed));
  });

  /// The board's pixels at a point [global] on the screen (null off it).
  Offset? _onBoard(Offset global) {
    final box = _boardKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final local = box.globalToLocal(global);
    if (!(Offset.zero & box.size).contains(local)) return null;
    final view = _scene.view;
    return view.topLeft + local * (view.width / box.size.width);
  }

  /// How far above the finger a dragged gear is held (its centre, screen
  /// points): the finger never hides it, nor the circle it is put in.
  double _lift(GearSize g, double scale) => _scene.radii[g]! * scale + 14;

  void _drop(GearSize gear, Offset? px) {
    if (_done || _placed.containsValue(gear)) return;
    final slot = px == null ? null : _scene.slotNear(px);
    setState(() {
      _picked = null;
      if (slot == null || _placed.containsKey(slot.id)) {
        _line = 'Put it in an empty dotted circle.';
        _good = false;
        _sentBack[gear] = (_sentBack[gear] ?? 0) + 1;
      } else if (slot.size != gear) {
        _line = gear == GearSize.big ? _scene.tooBig : _scene.tooSmall;
        _good = false;
        _sentBack[gear] = (_sentBack[gear] ?? 0) + 1;
      } else {
        _placed = {..._placed, slot.id: gear};
        _good = true;
        _line = _done ? _scene.turningLine : _scene.oneMore;
      }
    });
    if (_placed.containsValue(gear)) {
      widget.onPlaced(_placed);
      _spin();
      if (_done) _later();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scene = _scene;
    return LayoutBuilder(
      builder: (context, box) {
        // Screen points per board pixel: the plate fills the page's width.
        final scale = box.maxWidth / scene.view.width;
        // The whole puzzle takes a dropped gear: the finger may be under the
        // board's edge while the gear it holds is over a circle.
        return DragTarget<GearSize>(
          onAcceptWithDetails: (d) => _drop(d.data, _onBoard(d.offset - Offset(0, _lift(d.data, scale)))),
          builder: (context, candidates, _) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(scene.task, key: const ValueKey('gear-task'), textAlign: TextAlign.center, style: AppText.bodyText(size: 15, weight: FontWeight.w600, color: AppColors.navy)),
              const SizedBox(height: AppSpace.sm),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.paper),
                child: Semantics(
                  label: 'A brass board: the tower wheel, two empty dotted circles, the trial clocks T1, T2 and T3, and the garden clock.',
                  child: GestureDetector(
                    key: const ValueKey('gear-board'),
                    behavior: HitTestBehavior.opaque,
                    onTapUp: _picked == null ? null : (d) => _drop(_picked!, _onBoard(d.globalPosition)),
                    child: _BoardView(
                      key: _boardKey,
                      scene: scene,
                      child: AnimatedBuilder(
                        animation: _turn,
                        builder: (context, _) => _Board(
                          scene: scene,
                          placed: _placed,
                          turn: _turn.value,
                          still: _still(context),
                          glow: candidates.isNotEmpty || _picked != null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              ConstrainedBox(constraints: const BoxConstraints(minHeight: 44), child: Center(child: _line == null ? null : _Say(_line!, good: _good))),
              // The two gears, under the board, at the size they are on it.
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final g in GearSize.values)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpace.md),
                      child: _placed.containsValue(g)
                          ? SizedBox(width: scene.radii[g]! * 2 * scale, height: 1)
                          : _Shake(
                              trigger: _sentBack[g] ?? 0,
                              child: _TrayGear(
                                scene: scene,
                                size: g,
                                scale: scale,
                                lift: _lift(g, scale),
                                picked: _picked == g,
                                enabled: !_done,
                                onTap: () => setState(() {
                                  _picked = _picked == g ? null : g;
                                  _line = _picked == null ? null : 'Now tap a dotted circle.';
                                  _good = true;
                                }),
                              ),
                            ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The plate of the board ([GearBoardScene.view]), filling its width;
/// [child] is laid in the whole board's pixels.
class _BoardView extends StatelessWidget {
  const _BoardView({super.key, required this.scene, required this.child});

  final GearBoardScene scene;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final view = scene.view;
    return AspectRatio(
      aspectRatio: view.width / view.height,
      child: LayoutBuilder(
        builder: (context, box) {
          final s = box.maxWidth / view.width;
          return ClipRect(
            child: Stack(
              children: [
                Positioned(
                  left: -view.left * s,
                  top: -view.top * s,
                  width: scene.pixels.width * s,
                  height: scene.pixels.height * s,
                  child: FittedBox(
                    fit: BoxFit.fill,
                    child: MediaQuery.withNoTextScaling(
                      child: SizedBox(width: scene.pixels.width, height: scene.pixels.height, child: child),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The board in its own pixels: the tower's wheel, the places (a gear in
/// them or a dotted circle), the fixed gear and the clocks over their
/// gears. [turn] 0 → 1 is one round of the tower's wheel.
class _Board extends StatelessWidget {
  const _Board({required this.scene, required this.placed, required this.turn, required this.still, required this.glow});

  final GearBoardScene scene;
  final Map<String, GearSize> placed;
  final double turn;
  final bool still;
  final bool glow;

  static const _tower = 150.0;

  bool _turning(String? branch) => placed.isNotEmpty && (branch == null || scene.joined(branch, placed));

  /// A gear of [radius] turning [clockwise] when [on]: the smaller, the
  /// faster, as gears that touch go.
  double _angle(double radius, {required bool clockwise, required bool on}) =>
      on ? (clockwise ? 1 : -1) * turn * 2 * math.pi * _tower / radius : 0;

  Widget _gear(Offset at, double radius, double angle, {Key? key}) => Positioned(
    key: key,
    left: at.dx - radius,
    top: at.dy - radius,
    width: radius * 2,
    height: radius * 2,
    child: IgnorePointer(
      child: Transform.rotate(angle: angle, child: Image.asset(scene.gearFile, fit: BoxFit.contain, excludeFromSemantics: true)),
    ),
  );

  Widget _label(String text, Offset at) => Positioned(
    left: at.dx - 120,
    top: at.dy,
    width: 240,
    child: IgnorePointer(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: AppText.button(size: 46, color: AppColors.paperLight).copyWith(shadows: const [Shadow(color: Color(0xE6000000), blurRadius: 8)]),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final tower = scene.fixed.firstWhere((f) => f.branch == null);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(child: Image.asset(scene.file, fit: BoxFit.fill, excludeFromSemantics: true)),
        // The fixed gears (the tower's wheel first).
        for (final f in scene.fixed)
          _gear(f.at, f.radius, _angle(f.radius, clockwise: f.clockwise, on: _turning(f.branch))),
        _label('TOWER', tower.at + Offset(0, tower.radius * 0.15)),
        // The places: a gear in them, or a dotted circle.
        for (final s in scene.slots)
          if (placed[s.id] == s.size)
            _gear(s.at, scene.radii[s.size]!, _angle(scene.radii[s.size]!, clockwise: false, on: true), key: ValueKey('gear-in-${s.id}'))
          else
            Positioned(
              key: ValueKey('gear-slot-${s.id}'),
              left: s.at.dx - scene.radii[s.size]!,
              top: s.at.dy - scene.radii[s.size]!,
              width: scene.radii[s.size]! * 2,
              height: scene.radii[s.size]! * 2,
              child: IgnorePointer(child: CustomPaint(painter: _DottedCircle(glow: glow))),
            ),
        // The clocks: a dial over its gear; the joined ones' hands go round.
        for (final c in scene.clocks) ...[
          _gear(c.at, c.radius, _angle(c.radius, clockwise: c.clockwise, on: c.joined && _turning(c.branch))),
          Positioned(
            key: ValueKey('gear-clock-${c.id}'),
            left: c.at.dx - c.radius * 0.78,
            top: c.at.dy - c.radius * 0.78,
            width: c.radius * 1.56,
            height: c.radius * 1.56,
            child: IgnorePointer(
              child: DialFace(
                file: scene.dialFile,
                pixels: scene.dialPixels,
                pivot: scene.dialPivot,
                faceRadius: 495,
                // Four o'clock; a joined clock's hands go round with the
                // tower (with reduced motion, simply moved on an hour).
                hourDegrees: DialFace.degreesAt(4) + (c.joined && _turning(c.branch) ? (still ? 30 : turn * 360) : 0),
                minuteDegrees: c.joined && _turning(c.branch) ? (still ? 0 : turn * 360 * 12) : 0,
              ),
            ),
          ),
          _label(c.name, c.at + Offset(0, c.radius * 0.82)),
        ],
      ],
    );
  }
}

/// A gear waiting under the board, at its size on the board, named:
/// dragged into a place (held just above the finger, [lift]), or tapped
/// then a place.
class _TrayGear extends StatelessWidget {
  const _TrayGear({required this.scene, required this.size, required this.scale, required this.lift, required this.picked, required this.enabled, required this.onTap});

  final GearBoardScene scene;
  final GearSize size;
  final double scale;
  final double lift;
  final bool picked;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final gear = Image.asset(scene.gearFile, fit: BoxFit.contain, excludeFromSemantics: true);
    final r = scene.radii[size]! * scale;
    return Semantics(
      button: true,
      selected: picked,
      label: '${size == GearSize.big ? 'The big' : 'The small'} gear. Drag it into a dotted circle, or tap it and then tap the circle.',
      excludeSemantics: true,
      child: Draggable<GearSize>(
        key: ValueKey('gear-tray-${size.name}'),
        data: size,
        maxSimultaneousDrags: enabled ? 1 : 0,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        feedback: Transform.translate(offset: Offset(-r, -r - lift), child: SizedBox(width: r * 2, height: r * 2, child: gear)),
        childWhenDragging: _tile(Opacity(opacity: 0.25, child: gear), r),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? onTap : null,
          child: _tile(
            DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: picked ? [BoxShadow(color: AppColors.gold.withValues(alpha: 0.8), blurRadius: 18, spreadRadius: 4)] : null,
              ),
              child: gear,
            ),
            r,
          ),
        ),
      ),
    );
  }
}

/// A waiting gear with its name under it; at least a finger wide.
Widget _tile(Widget gear, double r) => Column(
  mainAxisSize: MainAxisSize.min,
  children: [
    SizedBox(width: math.max(r * 2, 48), height: math.max(r * 2, 48), child: Center(child: SizedBox(width: r * 2, height: r * 2, child: gear))),
    const SizedBox(height: AppSpace.xs),
    Text(r > 30 ? 'BIG GEAR' : 'SMALL GEAR', style: AppText.button(size: 13, color: AppColors.navy)),
  ],
);

class _DottedCircle extends CustomPainter {
  const _DottedCircle({required this.glow});

  final bool glow;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 6;
    if (glow) canvas.drawCircle(c, r, Paint()..color = AppColors.goldLight.withValues(alpha: 0.22));
    final dot = Paint()..color = AppColors.paperLight;
    final shade = Paint()..color = const Color(0x99000000);
    const n = 28;
    for (var i = 0; i < n; i++) {
      final a = i * 2 * math.pi / n;
      final p = c + Offset(math.cos(a), math.sin(a)) * r;
      canvas.drawCircle(p + const Offset(2, 2), 8, shade);
      canvas.drawCircle(p, 8, dot);
    }
  }

  @override
  bool shouldRepaint(_DottedCircle old) => old.glow != glow;
}

/// The Synchronisation Diagram, drawn: the board with both gears in.
class GearDiagramView extends StatelessWidget {
  const GearDiagramView({super.key, required this.diagram});

  final GearDiagram diagram;

  @override
  Widget build(BuildContext context) {
    final scene = diagram.scene;
    return _BoardView(
      scene: scene,
      child: _Board(scene: scene, placed: {for (final s in scene.slots) s.id: s.size}, turn: 0, still: true, glow: false),
    );
  }
}

// ── M3 — the maker's marks ──────────────────────────────────────────────

/// A mark drawn: the gear (Case 01's, as the notebook draws it), the two
/// clock hands (Case 04's picture, in ink), or the key.
class MarkGlyph extends StatelessWidget {
  const MarkGlyph({super.key, required this.kind, required this.scene, required this.color, required this.size});

  final MarkKind kind;
  final MakerMarksScene scene;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: switch (kind) {
      MarkKind.gear => InkIcon(InkGlyph.gear, size: size, color: color),
      MarkKind.key => InkIcon(InkGlyph.key, size: size, color: color),
      MarkKind.hands => ColorFiltered(
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        child: Image.asset(scene.handsFile, fit: BoxFit.contain, excludeFromSemantics: true),
      ),
    },
  );
}

/// The plan's marks and words, in its own pixels (on the turned note,
/// turned with it).
List<Widget> _planLayer(MakerMarksScene scene) => [
  for (final p in scene.paper) ...[
    Positioned.fromRect(
      rect: p.wordsAt,
      child: IgnorePointer(
        child: Transform.rotate(
          angle: p.angle,
          child: FittedBox(
            fit: BoxFit.contain,
            child: Text(
              p.words,
              textAlign: TextAlign.center,
              style: AppText.style(AppText.body, size: 40, weight: FontWeight.w700, color: p.light ? AppColors.paperLight : AppColors.navy, letterSpacing: 2, height: 1.1),
            ),
          ),
        ),
      ),
    ),
    Positioned.fromRect(
      rect: p.markAt,
      child: IgnorePointer(
        child: Transform.rotate(
          angle: p.angle,
          child: MarkGlyph(kind: p.kind, scene: scene, color: p.light ? AppColors.paperLight : AppColors.navy, size: p.markAt.width),
        ),
      ),
    ),
  ],
];

/// The plan round [crop] (its pixels, unturned round its centre), turned
/// by [angle] so a line on the turned note reads level; [crop]'s shape.
class _TurnedCrop extends StatelessWidget {
  const _TurnedCrop({required this.scene, required this.crop, required this.angle});

  final MakerMarksScene scene;
  final Rect crop;
  final double angle;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: crop.width / crop.height,
    child: LayoutBuilder(
      builder: (context, box) {
        final s = box.maxWidth / crop.width;
        final w = scene.pixels.width * s;
        final h = scene.pixels.height * s;
        final c = crop.center * s;
        return ClipRect(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: box.maxWidth / 2 - c.dx,
                top: box.maxHeight / 2 - c.dy,
                width: w,
                height: h,
                child: Transform.rotate(
                  angle: -angle,
                  origin: c - Offset(w / 2, h / 2),
                  child: FittedBox(
                    fit: BoxFit.fill,
                    child: MediaQuery.withNoTextScaling(
                      child: SizedBox(
                        width: scene.pixels.width,
                        height: scene.pixels.height,
                        child: Stack(children: [Positioned.fill(child: Image.asset(scene.file, fit: BoxFit.fill, excludeFromSemantics: true)), ..._planLayer(scene)]),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

/// M3 ([MakerMarksScene]): the old plan whole; the two marks from the
/// notebook; and the marks on the paper, each shown larger. A notebook
/// mark tapped, then a mark on the paper: the same shape is joined (saved:
/// [onJoined]); another is said why and nothing is joined. Both joined:
/// the mission's answer ([onSubmit]).
class MakerMarksPuzzle extends StatefulWidget {
  const MakerMarksPuzzle({super.key, required this.scene, required this.joined, required this.onJoined, required this.onSubmit});

  final MakerMarksScene scene;
  final Map<String, String> joined;
  final ValueChanged<Map<String, String>> onJoined;
  final Future<void> Function(String answer) onSubmit;

  @override
  State<MakerMarksPuzzle> createState() => _MakerMarksPuzzleState();
}

class _MakerMarksPuzzleState extends State<MakerMarksPuzzle> {
  late Map<String, String> _joined = {...widget.joined};
  String? _picked;
  String? _line;
  bool _good = false;
  int _wrong = 0;
  Timer? _submit;

  MakerMarksScene get _scene => widget.scene;
  bool get _done => _joined.length == _scene.marks.length;

  @override
  void initState() {
    super.initState();
    if (_done) _later();
  }

  @override
  void dispose() {
    _submit?.cancel();
    super.dispose();
  }

  void _later() => _submit = Timer(const Duration(milliseconds: 900), () {
    if (mounted) widget.onSubmit(_scene.answerOf(_joined));
  });

  void _tapPaper(String paperId) {
    if (_done) return;
    final mark = _picked;
    if (mark == null) {
      setState(() {
        _line = _scene.pickFirst;
        _good = false;
      });
      return;
    }
    if (_joined.containsValue(paperId)) return;
    if (_scene.same(mark, paperId)) {
      setState(() {
        _joined = {..._joined, mark: paperId};
        _picked = null;
        _good = true;
        _line = 'The same mark!';
      });
      widget.onJoined(_joined);
      if (_done) _later();
    } else {
      setState(() {
        _line = _scene.lines['$mark:$paperId'] ?? 'Look again. Is it the same shape?';
        _good = false;
        _wrong++;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scene = _scene;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(scene.task, key: const ValueKey('marks-task'), textAlign: TextAlign.center, style: AppText.bodyText(size: 15, weight: FontWeight.w600, color: AppColors.navy)),
        const SizedBox(height: AppSpace.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.paper),
          child: Semantics(
            image: true,
            label: 'An old blue plan of gears with a repair note pinned to it. In its corner: CHRONOS TRIAL, EMBLEM, and a gear. On the note: REPAIRS, T2 WHEEL, stamped with two clock hands; REPAIRS, T3 GLASS, stamped with a key.',
            excludeSemantics: true,
            child: PictureCanvas(
              key: const ValueKey('marks-plan'),
              pixels: scene.pixels,
              child: Stack(children: [Positioned.fill(child: Image.asset(scene.file, fit: BoxFit.fill, excludeFromSemantics: true)), ..._planLayer(scene)]),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.md),
        Text('FROM YOUR NOTEBOOK', textAlign: TextAlign.center, style: AppText.eyebrow()),
        const SizedBox(height: AppSpace.xs),
        _Shake(
          trigger: _wrong,
          child: Row(
            children: [
              for (final (i, m) in scene.marks.indexed) ...[
                if (i > 0) const SizedBox(width: AppSpace.sm),
                Expanded(
                  child: _NotebookMarkCard(
                    mark: m,
                    scene: scene,
                    picked: _picked == m.id,
                    joinedTo: _joined[m.id] == null ? null : scene.paperMark(_joined[m.id]!).name,
                    onTap: _done || _joined.containsKey(m.id)
                        ? null
                        : () => setState(() {
                            _picked = _picked == m.id ? null : m.id;
                            _line = _picked == null ? null : 'Now tap the same mark on the old paper.';
                            _good = true;
                          }),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpace.md),
        Text('ON THE OLD PAPER', textAlign: TextAlign.center, style: AppText.eyebrow()),
        const SizedBox(height: AppSpace.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, p) in scene.paper.indexed) ...[
              if (i > 0) const SizedBox(width: AppSpace.xs),
              Expanded(
                child: _PaperMarkTile(
                  paper: p,
                  scene: scene,
                  joinedBy: _joined.entries.where((e) => e.value == p.id).map((e) => e.key).firstOrNull,
                  onTap: () => _tapPaper(p.id),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpace.sm),
        ConstrainedBox(constraints: const BoxConstraints(minHeight: 48), child: Center(child: _line == null ? null : _Say(_line!, good: _good))),
      ],
    );
  }
}

class _NotebookMarkCard extends StatelessWidget {
  const _NotebookMarkCard({required this.mark, required this.scene, required this.picked, required this.joinedTo, required this.onTap});

  final NotebookMark mark;
  final MakerMarksScene scene;
  final bool picked;
  final String? joinedTo;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final joined = joinedTo != null;
    return Semantics(
      button: true,
      selected: picked,
      label: '${mark.name}, from ${mark.source}${joined ? ': joined to $joinedTo' : ''}',
      excludeSemantics: true,
      child: Material(
        key: ValueKey('marks-card-${mark.id}'),
        color: joined ? AppColors.successSoft : (picked ? AppColors.navy : AppColors.paperLight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
          side: BorderSide(color: joined ? AppColors.success : (picked ? AppColors.navy : AppLine.faint(0.35)), width: picked ? 2 : AppLine.hairline),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.button),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 72),
            child: Padding(
              padding: const EdgeInsets.all(AppSpace.sm),
              child: Row(
                children: [
                  MarkGlyph(kind: mark.kind, scene: scene, color: picked ? AppColors.goldLight : AppColors.inkBrown, size: 36),
                  const SizedBox(width: AppSpace.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(mark.name, maxLines: 3, style: AppText.bodyText(size: 13, weight: FontWeight.w700, color: picked ? AppColors.paperLight : AppColors.navy)),
                        Text(joined ? '✓ $joinedTo' : mark.source, maxLines: 2, style: AppText.caption(color: picked ? AppColors.goldLight : (joined ? AppColors.success : AppColors.muted))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PaperMarkTile extends StatelessWidget {
  const _PaperMarkTile({required this.paper, required this.scene, required this.joinedBy, required this.onTap});

  final PaperMark paper;
  final MakerMarksScene scene;
  final String? joinedBy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: '${paper.name}: ${paper.words.replaceAll('\n', ' ')}, ${switch (paper.kind) {
      MarkKind.gear => 'a gear',
      MarkKind.hands => 'two clock hands',
      MarkKind.key => 'a key',
    }}${joinedBy != null ? ', joined' : ''}',
    excludeSemantics: true,
    child: GestureDetector(
      key: ValueKey('marks-paper-${paper.id}'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.paper),
          border: Border.all(color: joinedBy != null ? AppColors.success : AppLine.faint(0.4), width: joinedBy != null ? 3 : AppLine.hairline),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.paper),
          child: _TurnedCrop(scene: scene, crop: paper.crop, angle: paper.angle),
        ),
      ),
    ),
  );
}

/// The Marks Key, drawn: the plan and its note with their marks.
class MarksPaperView extends StatelessWidget {
  const MarksPaperView({super.key, required this.paper});

  final MarksPaper paper;

  @override
  Widget build(BuildContext context) => PictureCanvas(
    pixels: paper.scene.pixels,
    child: Stack(children: [Positioned.fill(child: Image.asset(paper.scene.file, fit: BoxFit.fill, excludeFromSemantics: true)), ..._planLayer(paper.scene)]),
  );
}

// ── Final — the wrong hour ──────────────────────────────────────────────

/// The final's stage: the garden, its clock at four.
class TowerStage extends StatelessWidget {
  const TowerStage({super.key, required this.scene});

  final TowerTestScene scene;

  @override
  Widget build(BuildContext context) => Center(
    child: GardenPicture(file: scene.garden, pixels: scene.gardenPixels, clock: scene.gardenClock, label: scene.gardenLabel),
  );
}

/// The row of clocks under the tower: T1, T2, T3 and the garden clock, at
/// their hours; the joined ones move to the tower's hour once [tested].
class TestClocksRow extends StatelessWidget {
  const TestClocksRow({super.key, required this.scene, required this.tested, this.dark = false});

  final TowerTestScene scene;
  final bool tested;
  final bool dark;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final c in scene.clocks)
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
            child: Semantics(
              label: '${c.name}${c.joined ? ', joined to the tower' : ', not joined'}: ${scene.hourOf(c, tested: tested)} o\'clock',
              excludeSemantics: true,
              child: Column(
                key: ValueKey('test-clock-${c.id}'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(end: DialFace.degreesAt(scene.hourOf(c, tested: tested))),
                    duration: _still(context) ? Duration.zero : const Duration(milliseconds: 1100),
                    curve: Curves.easeInOutCubic,
                    builder: (context, hour, _) => DialFace(
                      file: scene.dialFile,
                      pixels: scene.dialPixels,
                      pivot: scene.dialPivot,
                      faceRadius: scene.dialRadius,
                      hourDegrees: hour,
                    ),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(c.name, style: AppText.button(size: 14, color: dark ? AppColors.goldLight : AppColors.navy)),
                  ),
                  Text(
                    '${scene.hourOf(c, tested: tested)}:00',
                    key: ValueKey('test-clock-time-${c.id}'),
                    style: AppText.bodyText(
                      size: 14,
                      weight: FontWeight.w700,
                      color: tested && c.joined ? AppColors.tryAgain : (dark ? AppColors.paperLight : AppColors.ink),
                    ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                  ),
                ],
              ),
            ),
          ),
        ),
    ],
  );
}

/// The final's first step ([TowerTestScene]): the tower's hands put back on
/// (a moment, the first time), the tower set with − / +, and TEST. At the
/// asked hour the joined clocks move with it ([onTested], saved); at
/// another, a line, never a wrong answer. [hour] is kept by the page.
class TowerTestPuzzle extends StatefulWidget {
  const TowerTestPuzzle({super.key, required this.scene, required this.hour, required this.tested, required this.onHour, required this.onTested});

  final TowerTestScene scene;
  final int hour;
  final bool tested;
  final ValueChanged<int> onHour;
  final VoidCallback onTested;

  @override
  State<TowerTestPuzzle> createState() => _TowerTestPuzzleState();
}

class _TowerTestPuzzleState extends State<TowerTestPuzzle> {
  String? _line;
  bool _handsOn = false;

  TowerTestScene get _scene => widget.scene;

  void _set(int delta) {
    if (widget.tested) return;
    final h = (widget.hour + delta - 1) % 12 + 1;
    setState(() => _line = null);
    widget.onHour(h);
  }

  void _test() {
    if (widget.tested) return;
    if (widget.hour == _scene.targetHour) {
      setState(() => _line = null);
      widget.onTested();
    } else {
      setState(() => _line = _scene.lineFor(widget.hour));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scene = _scene;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: math.min(240, MediaQuery.sizeOf(context).height * 0.28)),
            child: Semantics(
              label: 'The tower clock: ${widget.hour} o\'clock',
              excludeSemantics: true,
              child: TweenAnimationBuilder<double>(
                // The hands put back on: they slide in once.
                tween: Tween(begin: widget.tested ? 1 : 0, end: 1),
                duration: _still(context) || widget.tested ? Duration.zero : const Duration(milliseconds: 1600),
                onEnd: () => setState(() => _handsOn = true),
                builder: (context, hands, _) => TweenAnimationBuilder<double>(
                  tween: Tween(end: DialFace.degreesAt(widget.hour)),
                  duration: _still(context) ? Duration.zero : const Duration(milliseconds: 450),
                  curve: Curves.easeOutCubic,
                  builder: (context, hour, _) => DialFace(
                    key: const ValueKey('tower-dial'),
                    file: scene.dialFile,
                    pixels: scene.dialPixels,
                    pivot: scene.dialPivot,
                    faceRadius: scene.dialRadius,
                    hourDegrees: hour,
                    hands: hands,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.xs),
        Text('THE TOWER', textAlign: TextAlign.center, style: AppText.eyebrow()),
        AnimatedOpacity(
          opacity: _handsOn || widget.tested || _still(context) ? 1 : 0,
          duration: const Duration(milliseconds: 300),
          child: Text(scene.handsLine, textAlign: TextAlign.center, style: AppText.aside(size: 15)),
        ),
        const SizedBox(height: AppSpace.sm),
        if (!widget.tested) ...[
          Text(
            '${widget.hour}:00',
            key: const ValueKey('tower-time'),
            textAlign: TextAlign.center,
            style: AppText.title(size: 26).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
          ),
          const SizedBox(height: AppSpace.xs),
          Row(
            children: [
              Expanded(
                child: GameButton(
                  key: const ValueKey('tower-back'),
                  label: '1 HOUR BACK',
                  semanticLabel: 'Move the tower one hour back',
                  style: GameButtonStyle.outline,
                  singleLine: true,
                  onPressed: () => _set(-1),
                ),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: GameButton(
                  key: const ValueKey('tower-forward'),
                  label: '1 HOUR ON',
                  semanticLabel: 'Move the tower one hour forward',
                  style: GameButtonStyle.outline,
                  singleLine: true,
                  onPressed: () => _set(1),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          GameButton(
            key: const ValueKey('tower-test'),
            label: scene.testLabel,
            glyph: InkGlyph.clock,
            style: GameButtonStyle.gold,
            tap: TapRole.primary,
            onPressed: _test,
          ),
        ],
        const SizedBox(height: AppSpace.md),
        TestClocksRow(scene: scene, tested: widget.tested),
        if (_line != null) ...[const SizedBox(height: AppSpace.sm), _Say(_line!)],
      ],
    );
  }
}

/// The Wrong Hour Test, drawn: the clocks after the test.
class TestCardView extends StatelessWidget {
  const TestCardView({super.key, required this.card});

  final TestCard card;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: card.aspect,
    child: ColoredBox(
      color: AppColors.paperLight,
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xs),
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(width: 360, child: TestClocksRow(scene: card.scene, tested: true)),
        ),
      ),
    ),
  );
}

// ── After the case — the star ───────────────────────────────────────────

/// The star followed (the case's last step; true once done): the drum's
/// tag, the little clock with the same sign, and its place on the map lit.
Future<bool?> showStarLead(BuildContext context, StarLead lead) {
  final still = _still(context);
  return Navigator.of(context).push<bool>(
    PageRouteBuilder<bool>(
      opaque: false,
      barrierDismissible: false,
      barrierColor: AppColors.navyDeep.withValues(alpha: 0.975),
      transitionDuration: still ? Duration.zero : const Duration(milliseconds: 250),
      pageBuilder: (context, anim, _) => FadeTransition(opacity: anim, child: _StarLeadPage(lead: lead)),
    ),
  );
}

class _StarLeadPage extends StatefulWidget {
  const _StarLeadPage({required this.lead});

  final StarLead lead;

  @override
  State<_StarLeadPage> createState() => _StarLeadPageState();
}

class _StarLeadPageState extends State<_StarLeadPage> {
  String? _line;
  bool _found = false;

  StarLead get _lead => widget.lead;

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
                // The drum's tag.
                Center(
                  child: Container(
                    key: const ValueKey('star-tag'),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.md),
                    decoration: BoxDecoration(
                      color: AppColors.creamGold,
                      borderRadius: BorderRadius.circular(AppRadius.paper),
                      border: Border.all(color: AppColors.goldDeep, width: 2),
                      boxShadow: AppShadow.pinned,
                    ),
                    child: Text(_lead.tag, textAlign: TextAlign.center, style: AppText.style(AppText.body, size: 18, weight: FontWeight.w700, color: AppColors.navy, letterSpacing: 1.5)),
                  ),
                ),
                const SizedBox(height: AppSpace.lg),
                if (!_found) ...[
                  Text(_lead.question, key: const ValueKey('star-question'), textAlign: TextAlign.center, style: AppText.title(size: 20, color: AppColors.goldLight)),
                  const SizedBox(height: AppSpace.sm),
                  Row(
                    children: [
                      for (final m in _lead.models)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
                            child: Semantics(
                              button: true,
                              label: m.label,
                              excludeSemantics: true,
                              child: Material(
                                color: AppColors.paperLight,
                                borderRadius: BorderRadius.circular(AppRadius.button),
                                child: InkWell(
                                  key: ValueKey('star-model-${m.id}'),
                                  borderRadius: BorderRadius.circular(AppRadius.button),
                                  onTap: () => _pick(m.id),
                                  child: Padding(
                                    padding: const EdgeInsets.all(AppSpace.xs),
                                    child: Column(
                                      children: [
                                        AspectRatio(aspectRatio: 1, child: Image.asset(m.file, fit: BoxFit.contain, excludeFromSemantics: true)),
                                        Text(m.name, style: AppText.button(size: 15, color: AppColors.navy)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (_line != null) ...[const SizedBox(height: AppSpace.sm), _Say(_line!, dark: true)],
                ] else ...[
                  _Say(_lead.foundLine, good: true, dark: true),
                  const SizedBox(height: AppSpace.sm),
                  _StarMap(lead: _lead),
                  const SizedBox(height: AppSpace.md),
                  for (final l in _lead.doneLines) ...[_Say(l, good: true, dark: true), const SizedBox(height: AppSpace.xs)],
                  const SizedBox(height: AppSpace.md),
                  GameButton(
                    key: const ValueKey('star-done'),
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

/// The map of Paris, the star's place ringed in gold (pulsing gently).
class _StarMap extends StatelessWidget {
  const _StarMap({required this.lead});

  final StarLead lead;

  @override
  Widget build(BuildContext context) {
    final p = lead.mapPixels;
    final at = Offset(lead.spot.at.dx * p.width, lead.spot.at.dy * p.height);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.paper),
      child: Semantics(
        label: 'A map of Paris: the ${lead.spot.name} ringed in gold.',
        child: PictureCanvas(
          key: const ValueKey('star-map'),
          pixels: p,
          child: Stack(
            children: [
              Positioned.fill(child: Image.asset(lead.mapFile, fit: BoxFit.fill, excludeFromSemantics: true)),
              Positioned(
                left: at.dx - 110,
                top: at.dy - 110,
                width: 220,
                height: 220,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: _still(context) ? 1 : 0.4, end: 1),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutBack,
                  builder: (context, s, child) => Transform.scale(scale: s, child: child),
                  child: const _Ring(key: ValueKey('star-map-ring'), color: AppColors.goldLight, width: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A ring round a place on a map: [color] with a thin dark edge either
/// side, so it reads on any part of the picture (no shadow under it).
class _Ring extends StatelessWidget {
  const _Ring({super.key, required this.color, required this.width});

  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.navyDeep.withValues(alpha: 0.7), width: 3)),
    child: Padding(
      padding: const EdgeInsets.all(3),
      child: DecoratedBox(
        decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: width)),
        child: Padding(
          padding: EdgeInsets.all(width),
          child: DecoratedBox(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.navyDeep.withValues(alpha: 0.7), width: 3))),
        ),
      ),
    ),
  );
}
