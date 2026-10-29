import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../widgets/art_assets.dart';
import '../world_cities.dart';
import '../world_map_state.dart';

/// The world, dragged and pinched ([InteractiveViewer]), with the cities on
/// it. The map fills the screen; [obscured] is how much of its top and
/// bottom the page lays over it (the header, the city card), so the camera
/// frames the cities in the part left in view.
///
/// The pins are drawn over the world at their places, the same size on
/// screen at every zoom. A tap picks the nearest pin, so cities close
/// together (London, Paris) can each be chosen.
class WorldMapView extends StatefulWidget {
  const WorldMapView({
    super.key,
    required this.cities,
    required this.selectedId,
    required this.homeId,
    required this.onSelect,
    this.obscured = EdgeInsets.zero,
  });

  final List<WorldCityState> cities;

  /// The city whose card is shown.
  final String selectedId;

  /// The city the map opens on and goes back to.
  final String homeId;

  final ValueChanged<String> onSelect;

  /// The map's top and bottom covered by the page (header, card).
  final EdgeInsets obscured;

  /// How far the map can be magnified beyond covering the viewport.
  static const maxScale = 6.0;

  /// One tap of + or −.
  static const zoomStep = 1.6;

  /// How far past its east and west edges the world can be dragged (navy
  /// sea), so a city near an edge comes out from under the map's buttons.
  static const edge = 80.0;

  /// The opening view shows this many degrees of longitude across the
  /// screen (as the artwork's edges in [ArtAssets] count them): the city
  /// with its neighbours (London, Paris and Rome), not the whole world.
  static const openingSpan = 65.0;

  /// Where the chosen city sits in the part of the map in view (between
  /// the header and the card), from its top.
  static const focusHeight = 0.45;

  @override
  State<WorldMapView> createState() => _WorldMapViewState();
}

class _WorldMapViewState extends State<WorldMapView> with SingleTickerProviderStateMixin {
  final _view = TransformationController();
  late final AnimationController _move = AnimationController(vsync: this, duration: const Duration(milliseconds: 450))..addListener(_step);
  Animation<Matrix4>? _tween;

  /// Where the running move is going, worked out again if the page's
  /// layout (the card's height) changes on the way.
  Matrix4 Function()? _aim;

  /// The viewport and the world (the artwork covering it) last laid out.
  Size? _viewport;
  Size _world = Size.zero;

  /// The player has moved the map or chosen on it: the view is theirs, and
  /// is no longer set back to the opening when the page's layout settles.
  bool _touched = false;

  void _step() {
    final t = _tween;
    if (t != null) _view.value = t.value;
  }

  @override
  void didUpdateWidget(WorldMapView old) {
    super.didUpdateWidget(old);
    if (old.obscured != widget.obscured && _viewport != null) {
      final aim = _aim;
      if (_move.isAnimating && aim != null) {
        _go(aim);
      } else {
        _move.stop();
        _view.value = _touched ? _bounded(_view.value) : _opening();
      }
    }
  }

  @override
  void dispose() {
    _move.dispose();
    _view.dispose();
    super.dispose();
  }

  WorldCity _city(String id) => widget.cities.firstWhere((c) => c.city.id == id).city;

  double get _scale => _view.value.getMaxScaleOnAxis();

  /// The obscured top and bottom, never more than the viewport.
  (double, double) get _cover {
    final v = _viewport!;
    final top = widget.obscured.top.clamp(0.0, v.height);
    return (top, widget.obscured.bottom.clamp(0.0, v.height - top));
  }

  /// The screen point the chosen city is brought to.
  Offset get _focal {
    final v = _viewport!;
    final (top, bottom) = _cover;
    return Offset(v.width / 2, top + (v.height - top - bottom) * WorldMapView.focusHeight);
  }

  /// The view at [scale] with its translation [x], [y] kept inside the
  /// world: east and west by [WorldMapView.edge] of sea; north and south
  /// the world's edge may come down to the header and up to the card, no
  /// further (so a northern city like London can still reach the middle).
  Matrix4 _at(double x, double y, double scale) {
    final v = _viewport!;
    final s = scale.clamp(1.0, WorldMapView.maxScale);
    final (top, bottom) = _cover;
    const e = WorldMapView.edge;
    final cx = x.clamp(math.min(e, v.width - _world.width * s - e), e);
    final cy = y.clamp(math.min(top, v.height - _world.height * s - bottom), top);
    return Matrix4.diagonal3Values(s, s, 1)..setTranslationRaw(cx.toDouble(), cy.toDouble(), 0);
  }

  /// The view with world point [p] at the focal point, magnified [scale]
  /// times (as near as the world's edges allow).
  Matrix4 _centredOn(Offset p, double scale) {
    final s = scale.clamp(1.0, WorldMapView.maxScale);
    final f = _focal;
    return _at(f.dx - p.dx * s, f.dy - p.dy * s, s);
  }

  /// [m] moved back inside the world's edges.
  Matrix4 _bounded(Matrix4 m) {
    final t = m.getTranslation();
    return _at(t.x, t.y, m.getMaxScaleOnAxis());
  }

  Offset _onWorld(WorldCity c) => Offset(c.at.dx * _world.width, c.at.dy * _world.height);

  /// The world point at the focal point now.
  Offset get _atFocal {
    final t = _view.value.getTranslation();
    final f = _focal;
    return Offset((f.dx - t.x) / _scale, (f.dy - t.y) / _scale);
  }

  /// The scale the map opens at on [city]: [WorldMapView.openingSpan]
  /// degrees of longitude across the screen, and at least enough for the
  /// city to reach the focal point without the world's edge showing; but
  /// never so close that a neighbour ([_neighbours]) or its touch leaves
  /// the part in view (then the world's edge holds the city a little above
  /// the focal point).
  double _openingScale(WorldCity city) {
    final v = _viewport!;
    final (top, bottom) = _cover;
    final p = _onWorld(city);
    final f = _focal;
    const across = ArtAssets.worldMapEast - ArtAssets.worldMapWest;
    final span = v.width * across / WorldMapView.openingSpan / _world.width;
    final north = p.dy > 0 ? (f.dy - top) / p.dy : 1.0;
    final south = _world.height > p.dy ? (v.height - bottom - f.dy) / (_world.height - p.dy) : 1.0;
    final framed = [span, north, south].reduce(math.max);
    var fit = double.infinity;
    for (final n in _neighbours(city)) {
      // Room around a neighbour's place (its pin's tip): its touch, or its
      // name when wider, at the sides; its pin above; its name below.
      final name = _PinLayer.measure(n.name);
      final side = math.max(_PinLayer.touch * 0.75, name.width / 2 + 4);
      final room = Rect.fromLTRB(side, top + _PinMark.height + 4, v.width - side, v.height - bottom - name.height - 8);
      final d = _onWorld(n) - p;
      if (d.dx > 0) fit = math.min(fit, (room.right - f.dx) / d.dx);
      if (d.dx < 0) fit = math.min(fit, (room.left - f.dx) / d.dx);
      if (d.dy > 0) fit = math.min(fit, (room.bottom - f.dy) / d.dy);
      if (d.dy < 0) fit = math.min(fit, (room.top - f.dy) / d.dy);
    }
    return math.min(framed, fit).clamp(1.0, WorldMapView.maxScale);
  }

  /// The cities the opening view on [home] shows with it: those within half
  /// [WorldMapView.openingSpan] degrees east or west of it (London: Paris
  /// and Rome).
  Iterable<WorldCity> _neighbours(WorldCity home) {
    const across = ArtAssets.worldMapEast - ArtAssets.worldMapWest;
    return widget.cities
        .map((c) => c.city)
        .where((c) => c.id != home.id && (c.at.dx - home.at.dx).abs() * across <= WorldMapView.openingSpan / 2);
  }

  /// Where the map's buttons are: bottom right, above the card.
  Rect get _controls {
    final v = _viewport!;
    final (_, bottom) = _cover;
    return Rect.fromLTWH(
      v.width - AppSpace.md - _MapControls.width,
      v.height - bottom - AppSpace.md - _MapControls.height,
      _MapControls.width,
      _MapControls.height,
    );
  }

  /// The opening view: the home city at the focal point, its neighbours'
  /// touch clear of the map's buttons (the view a little wider for them,
  /// and at the widest the city slid a little west).
  Matrix4 _opening() {
    final home = _city(widget.homeId);
    final p = _onWorld(home);
    var s = _openingScale(home);
    final buttons = _controls.inflate(_PinLayer.touch / 2);
    var shift = 0.0;
    for (final n in _neighbours(home)) {
      final q = _onWorld(n);
      Offset at(double scale) => MatrixUtils.transformPoint(_centredOn(p, scale), q);
      if (!buttons.contains(at(s))) continue;
      if (q.dx > p.dx) s = math.max(1.0, s - (at(s).dx - buttons.left) / (q.dx - p.dx));
      if (buttons.contains(at(s))) shift = math.max(shift, at(s).dx - buttons.left);
    }
    final m = _centredOn(p, s);
    if (shift == 0) return m;
    final t = m.getTranslation();
    return _at(t.x - shift, t.y, s);
  }

  void _go(Matrix4 Function() aim) {
    _aim = aim;
    final to = aim();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _move.stop();
      _view.value = to;
      return;
    }
    _tween = Matrix4Tween(begin: _view.value.clone(), end: to).animate(CurvedAnimation(parent: _move, curve: Curves.easeInOutCubic));
    _move.forward(from: 0);
  }

  void _zoom(double by) {
    _touched = true;
    final to = _scale * by;
    final p = _atFocal;
    _go(() => _centredOn(p, to));
  }

  void _select(String cityId) {
    _touched = true;
    widget.onSelect(cityId);
    final s = _scale;
    _go(() => _centredOn(_onWorld(_city(cityId)), s));
  }

  /// Back to my city: the opening view again.
  void _home() {
    _touched = true;
    widget.onSelect(widget.homeId);
    _go(_opening);
  }

  /// A drag or pinch let go past the world's north or south edge settles
  /// back inside it.
  void _settle() {
    final inside = _bounded(_view.value);
    if (inside != _view.value) _go(() => _bounded(inside));
  }

  /// Laid out at [viewport]: the first time, the map opens on the home
  /// city; after that, the view only stays inside the world.
  void _layOut(Size viewport) {
    if (_viewport == viewport) return;
    final first = _viewport == null;
    final keep = first ? null : _atFocal;
    _viewport = viewport;
    final h = math.max(viewport.height, viewport.width / ArtAssets.worldMapAspect);
    _world = Size(h * ArtAssets.worldMapAspect, h);
    _move.stop();
    _view.value = keep == null || !_touched ? _opening() : _centredOn(keep, _scale);
  }

  @override
  Widget build(BuildContext context) {
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return LayoutBuilder(
      builder: (context, box) {
        _layOut(box.biggest);
        final (top, bottom) = _cover;
        final controls = _controls;
        return ClipRect(
          child: Stack(
            children: [
              Positioned.fill(
                child: ColoredBox(
                  color: AppColors.navyDeep,
                  child: InteractiveViewer(
                    key: const ValueKey('world-map-viewer'),
                    transformationController: _view,
                    constrained: false,
                    minScale: 1,
                    maxScale: WorldMapView.maxScale,
                    boundaryMargin: EdgeInsets.fromLTRB(WorldMapView.edge, top, WorldMapView.edge, bottom),
                    onInteractionStart: (_) {
                      _touched = true;
                      _aim = null;
                      _move.stop();
                    },
                    onInteractionEnd: (_) => _settle(),
                    child: SizedBox.fromSize(
                      size: _world,
                      child: Image.asset(
                        ArtAssets.worldMap,
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.medium,
                        excludeFromSemantics: true,
                        errorBuilder: (context, error, stack) => const ColoredBox(key: ValueKey('world-map-missing'), color: AppColors.navyDeep),
                      ),
                    ),
                  ),
                ),
              ),
              // Over the world, in screen points: drags and pinches still go
              // through to the map; a tap picks the nearest pin.
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: _view,
                  builder: (context, _) => _PinLayer(
                    cities: widget.cities,
                    points: [for (final c in widget.cities) MatrixUtils.transformPoint(_view.value, _onWorld(c.city))],
                    viewport: box.biggest,
                    selectedId: widget.selectedId,
                    homeId: widget.homeId,
                    avoid: [controls],
                    still: still,
                    onTap: _select,
                  ),
                ),
              ),
              Positioned.fromRect(
                rect: controls,
                child: _MapControls(onHome: _home, onZoomIn: () => _zoom(WorldMapView.zoomStep), onZoomOut: () => _zoom(1 / WorldMapView.zoomStep)),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// How a city's pin is drawn (the pins in [ArtAssets]): the floating gold
/// pin on the city of the season under way (the map's home, chosen or
/// not), the navy sealed pin on a city whose season is complete, the
/// locked pin on every other. Another city chosen has the gold ring round
/// its pin's head.
enum _Mark { home, open, locked, openChosen, lockedChosen }

_Mark _markOf(WorldCityState s, {required bool home, required bool selected}) {
  if (home) return _Mark.home;
  if (s.status == WorldCityStatus.completed) return selected ? _Mark.openChosen : _Mark.open;
  return selected ? _Mark.lockedChosen : _Mark.locked;
}

/// The middle of the round head of the pin whose tip is at [p].
Offset _head(Offset p) => p - const Offset(0, _PinMark.headAbove);

/// The screen box of the pin whose tip is at [p] (the place): the home pin
/// floats up to [_PinMark.float] higher; a chosen pin's ring reaches a
/// little round its head.
Rect _markRect(Offset p, _Mark m) {
  final pin = Rect.fromLTWH(p.dx - _PinMark.width / 2, p.dy - _PinMark.height, _PinMark.width, _PinMark.height);
  return switch (m) {
    _Mark.home => pin.expandToInclude(pin.shift(const Offset(0, -_PinMark.float))),
    _Mark.open || _Mark.locked => pin,
    _Mark.openChosen || _Mark.lockedChosen => pin.expandToInclude(Rect.fromCircle(center: _head(p), radius: _PinMark.ring / 2)),
  };
}

/// Where each city's name goes on screen (null: not shown). Names are laid
/// out in [order] (the selected city first), each in the first of below,
/// above, right and left of its mark ([marks]) that stays on screen and
/// clear of the marks, of the names placed before it and of [avoid]. A name
/// with no room is hidden, except the [selected] city's, which always
/// shows (below its mark).
@visibleForTesting
List<Rect?> placeLabels({
  required List<Offset> points,
  required List<Rect> marks,
  required List<Size> sizes,
  required List<int> order,
  required Size viewport,
  int? selected,
  List<Rect> avoid = const [],
}) {
  const gap = 3.0;
  final screen = Offset.zero & viewport;
  final placed = <Rect>[];
  final out = List<Rect?>.filled(points.length, null);
  for (final i in order) {
    final m = marks[i];
    final s = sizes[i];
    final p = points[i];
    final below = Rect.fromLTWH(p.dx - s.width / 2, m.bottom + gap, s.width, s.height);
    final candidates = [
      below,
      Rect.fromLTWH(p.dx - s.width / 2, m.top - gap - s.height, s.width, s.height),
      Rect.fromLTWH(m.right + gap + 1, p.dy - s.height / 2, s.width, s.height),
      Rect.fromLTWH(m.left - gap - 1 - s.width, p.dy - s.height / 2, s.width, s.height),
    ];
    // Boxes that only touch (within half a point) are clear of each other.
    bool hits(Rect o, Rect r) => o.deflate(0.5).overlaps(r);
    bool clear(Rect r) =>
        screen.contains(r.topLeft) &&
        screen.contains(r.bottomRight) &&
        !placed.any((o) => hits(o, r)) &&
        !avoid.any((o) => hits(o, r)) &&
        !marks.indexed.any((e) => e.$1 != i && hits(e.$2, r));
    final at = candidates.where(clear).firstOrNull ?? (i == selected ? below : null);
    out[i] = at;
    if (at != null) placed.add(at);
  }
  return out;
}

/// The cities' pins and names over the world, their tips at the places on
/// screen ([points]). One tap layer under them picks the nearest mark within
/// reach (or the name tapped), so neighbouring cities never cover each
/// other's touch; drags and pinches pass through to the map.
class _PinLayer extends StatelessWidget {
  const _PinLayer({
    required this.cities,
    required this.points,
    required this.viewport,
    required this.selectedId,
    required this.homeId,
    required this.avoid,
    required this.still,
    required this.onTap,
  });

  final List<WorldCityState> cities;
  final List<Offset> points;
  final Size viewport;
  final String selectedId;

  /// The city of the season under way: the gold pin.
  final String homeId;

  final List<Rect> avoid;
  final bool still;
  final ValueChanged<String> onTap;

  /// A pin's touch: this square round its head (where a neighbour's head is
  /// nearer, the tap is the neighbour's).
  static const touch = 48.0;

  static final _sizes = <String, Size>{};

  static Size measure(String text) => _sizes.putIfAbsent(text, () {
    final tp = TextPainter(
      text: TextSpan(text: text, style: _CityName.style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      textScaler: TextScaler.noScaling,
    )..layout();
    const pad = _CityName.padding;
    final size = Size(tp.width.ceilToDouble() + pad.horizontal, tp.height.ceilToDouble() + pad.vertical);
    tp.dispose();
    return size;
  });

  @override
  Widget build(BuildContext context) {
    final n = cities.length;
    final sel = cities.indexWhere((c) => c.city.id == selectedId);
    final marks = [for (var i = 0; i < n; i++) _markOf(cities[i], home: cities[i].city.id == homeId, selected: i == sel)];
    final heads = [for (final p in points) _head(p)];
    final markRects = [for (var i = 0; i < n; i++) _markRect(points[i], marks[i])];
    final order = [
      if (sel >= 0) sel,
      for (var i = 0; i < n; i++)
        if (i != sel) i,
    ];
    final labels = placeLabels(
      points: heads,
      marks: markRects,
      sizes: [for (var i = 0; i < n; i++) measure(cities[i].city.name)],
      order: order,
      viewport: viewport,
      selected: sel >= 0 ? sel : null,
      avoid: avoid,
    );
    final reach = Rect.fromLTWH(-touch, -touch, viewport.width + 2 * touch, viewport.height + 2 * touch);
    final shown = [for (var i = 0; i < n; i++) reach.contains(points[i])];

    /// The city a tap at [at] chooses: the nearest pin's head within reach
    /// (the home pin counts all over), else the name tapped.
    String? hit(Offset at) {
      int? best;
      var nearest = double.infinity;
      for (var i = 0; i < n; i++) {
        if (!shown[i]) continue;
        final d = (at - heads[i]).distance;
        final onPin = marks[i] == _Mark.home && markRects[i].inflate(4).contains(at);
        if ((d <= touch / 2 || onPin) && d < nearest) {
          best = i;
          nearest = d;
        }
      }
      if (best != null) return cities[best].city.id;
      for (final i in order) {
        if (shown[i] && (labels[i]?.inflate(4).contains(at) ?? false)) return cities[i].city.id;
      }
      return null;
    }

    // The selected city on top.
    final layers = order.reversed.toList();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTapUp: (d) {
              final id = hit(d.localPosition);
              if (id != null) onTap(id);
            },
          ),
        ),
        for (final i in layers)
          if (shown[i]) ...[
            if (labels[i] case final r?)
              Positioned.fromRect(
                rect: r,
                child: IgnorePointer(
                  child: _CityName(key: ValueKey('city-label-${cities[i].city.id}'), name: cities[i].city.name),
                ),
              ),
            Positioned(
              left: heads[i].dx - touch / 2,
              top: heads[i].dy - touch / 2,
              width: touch,
              height: touch,
              child: Semantics(
                button: true,
                selected: i == sel,
                label: '${cities[i].city.name}, ${_say(cities[i].status)}',
                onTap: () => onTap(cities[i].city.id),
                excludeSemantics: true,
                // Seen by a tap here, never stopping it: the tap layer under
                // the pins decides which city (and drags reach the map).
                child: Listener(
                  key: ValueKey('city-pin-${cities[i].city.id}'),
                  behavior: HitTestBehavior.translucent,
                  child: IgnorePointer(
                    child: _PinMark(key: ValueKey('mark-${cities[i].city.id}-${marks[i].name}'), mark: marks[i], still: still),
                  ),
                ),
              ),
            ),
          ],
      ],
    );
  }

  static String _say(WorldCityStatus s) => switch (s) {
    WorldCityStatus.playable => 'ready to play',
    WorldCityStatus.inProgress => 'in progress',
    WorldCityStatus.completed => 'completed',
    WorldCityStatus.locked => 'locked',
    WorldCityStatus.comingSoon => 'coming soon',
  };
}

/// A city's pin in its touch square, the middle of its round head at the
/// square's middle and its tip on the place: the gold pin of the home city
/// floating gently, the sealed pin of a city whose season is complete, the
/// locked pin of every other; another city chosen, the gold ring round its
/// pin's head. A soft shadow (a gold glow under home) on the ground.
class _PinMark extends StatelessWidget {
  const _PinMark({super.key, required this.mark, required this.still});

  final _Mark mark;
  final bool still;

  /// The pin's size on screen (its art is 96 × 120, the tip at the bottom
  /// middle).
  static const width = 40.0;
  static const height = 50.0;

  /// From the tip up to the middle of the pin's round head (44 of the
  /// art's 120 from its top).
  static const headAbove = height * (1 - 44 / 120);

  /// How high the home pin floats up.
  static const float = 4.0;

  /// The ring round a chosen pin's head.
  static const ring = 50.0;

  @override
  Widget build(BuildContext context) {
    const mid = _PinLayer.touch / 2;
    const top = mid - (height - headAbove);
    final home = mark == _Mark.home;
    final chosen = mark == _Mark.openChosen || mark == _Mark.lockedChosen;
    Widget pin = Image.asset(
      switch (mark) {
        _Mark.home => ArtAssets.worldMapPinInProgress,
        _Mark.open || _Mark.openChosen => ArtAssets.worldMapPinCompleted,
        _Mark.locked || _Mark.lockedChosen => ArtAssets.worldMapPinLocked,
      },
      key: const ValueKey('pin-art'),
      width: width,
      height: height,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
    );
    if (home) pin = _Floating(still: still, child: pin);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: mid - (home ? 18 : 11),
          top: top + height - (home ? 6 : 3),
          width: home ? 36 : 22,
          height: home ? 12 : 6,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: RadialGradient(
                colors: home
                    ? [AppColors.goldLight.withValues(alpha: 0.6), AppColors.goldLight.withValues(alpha: 0)]
                    : const [Color(0x73000000), Color(0x00000000)],
              ),
            ),
          ),
        ),
        if (chosen)
          Positioned(
            left: mid - ring / 2,
            top: mid - ring / 2,
            width: ring,
            height: ring,
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: AppColors.goldLight.withValues(alpha: 0.5), blurRadius: 12, spreadRadius: 1)],
              ),
              child: Image.asset(ArtAssets.worldMapPinRing, filterQuality: FilterQuality.medium, excludeFromSemantics: true),
            ),
          ),
        Positioned(left: mid - width / 2, top: top, width: width, height: height, child: pin),
      ],
    );
  }
}

/// [child] floating slowly up [_PinMark.float] and down again, over and
/// over; still when animations are off.
class _Floating extends StatefulWidget {
  const _Floating({required this.still, required this.child});

  final bool still;
  final Widget child;

  @override
  State<_Floating> createState() => _FloatingState();
}

class _FloatingState extends State<_Floating> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
  late final Animation<double> _up = CurvedAnimation(parent: _c, curve: Curves.easeInOut);

  void _sync() {
    if (widget.still) {
      _c.value = 0;
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(_Floating old) {
    super.didUpdateWidget(old);
    if (old.still != widget.still) _sync();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _up,
    builder: (context, child) => Transform.translate(offset: Offset(0, -_PinMark.float * _up.value), child: child),
    child: widget.child,
  );
}

/// A city's name on the map, every one on a navy tag (the pins tell which
/// city is which).
class _CityName extends StatelessWidget {
  const _CityName({super.key, required this.name});

  final String name;

  static final style = AppText.style(AppText.body, size: 13, weight: FontWeight.w700, color: AppColors.paperLight, letterSpacing: 0.4, height: 1.2);

  static const padding = EdgeInsets.symmetric(horizontal: 9, vertical: 3);

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.navyDeep.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.goldLight.withValues(alpha: 0.55), width: AppLine.hairline),
      ),
      child: Padding(
        padding: padding,
        child: Text(name, maxLines: 1, softWrap: false, textScaler: TextScaler.noScaling, style: style),
      ),
    );
  }
}

/// Back to my city, zoom in, zoom out: one slim panel on the map.
class _MapControls extends StatelessWidget {
  const _MapControls({required this.onHome, required this.onZoomIn, required this.onZoomOut});

  final VoidCallback onHome;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;

  static const width = 44.0;
  static const cell = 44.0;
  static const height = cell * 3 + 2;

  @override
  Widget build(BuildContext context) {
    Widget rule() => Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 10), color: AppColors.goldLight.withValues(alpha: 0.25));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.navyDeep.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x4D000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      position: DecorationPosition.background,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.goldLight.withValues(alpha: 0.35), width: AppLine.hairline),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MapButton(key: const ValueKey('world-map-home'), tooltip: 'Back to my city', onTap: onHome, painter: const _LocatePainter()),
            rule(),
            _MapButton(key: const ValueKey('world-map-zoom-in'), tooltip: 'Zoom in', onTap: onZoomIn, painter: const _SignPainter(plus: true)),
            rule(),
            _MapButton(key: const ValueKey('world-map-zoom-out'), tooltip: 'Zoom out', onTap: onZoomOut, painter: const _SignPainter(plus: false)),
          ],
        ),
      ),
    );
  }
}

/// One control in the panel: a 44 × 44 touch with a small sign.
class _MapButton extends StatelessWidget {
  const _MapButton({super.key, required this.tooltip, required this.onTap, required this.painter});

  final String tooltip;
  final VoidCallback onTap;
  final CustomPainter painter;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        excludeSemantics: true,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            width: _MapControls.width,
            height: _MapControls.cell,
            child: Center(
              child: CustomPaint(size: const Size.square(16), painter: painter),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Back to my city": a ring with four ticks and a dot (find me), never the
/// cities' pin.
class _LocatePainter extends CustomPainter {
  const _LocatePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width * 0.32;
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..color = AppColors.goldLight;
    canvas.drawCircle(c, r, line);
    canvas.drawCircle(c, 2, Paint()..color = AppColors.goldLight);
    final out = size.width / 2;
    for (final d in const [Offset(1, 0), Offset(-1, 0), Offset(0, 1), Offset(0, -1)]) {
      canvas.drawLine(c + d * (r + 1), c + d * out, line);
    }
  }

  @override
  bool shouldRepaint(_LocatePainter old) => false;
}

/// + or −, drawn.
class _SignPainter extends CustomPainter {
  const _SignPainter({required this.plus});

  final bool plus;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final h = size.width * 0.42;
    final line = Paint()
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..color = AppColors.goldLight;
    canvas.drawLine(c - Offset(h, 0), c + Offset(h, 0), line);
    if (plus) canvas.drawLine(c - Offset(0, h), c + Offset(0, h), line);
  }

  @override
  bool shouldRepaint(_SignPainter old) => old.plus != plus;
}
