import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../widgets/art_assets.dart';
import '../../../widgets/ink_icon.dart';
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
    // Room around a neighbour's place: its touch at the sides and above,
    // its marker's tip and name below.
    const side = _PinLayer.touch * 0.75;
    final room = Rect.fromLTRB(side, top + _PinLayer.touch / 2, v.width - side, v.height - bottom - _PinLayer.touch);
    var fit = double.infinity;
    for (final n in _neighbours(city)) {
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
                    painted: _world.width * _scale,
                    others: [
                      for (final m in ArtAssets.worldMapOtherMarkers)
                        MatrixUtils.transformPoint(_view.value, Offset(m.dx * _world.width, m.dy * _world.height)),
                    ],
                    selectedId: widget.selectedId,
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

/// How a city's mark is drawn. A chosen city that cannot be entered keeps
/// its own mark (the lock, the dashed ring) in a gold ring: the gold drop
/// is only for a chosen city that can be played.
enum _Mark {
  selected,
  open,
  locked,
  comingSoon,
  selectedLocked,
  selectedComingSoon;

  bool get chosen => this == selected || this == selectedLocked || this == selectedComingSoon;
}

_Mark _markOf(WorldCityState s, {required bool selected}) => switch (s.status) {
  WorldCityStatus.locked => selected ? _Mark.selectedLocked : _Mark.locked,
  WorldCityStatus.comingSoon => selected ? _Mark.selectedComingSoon : _Mark.comingSoon,
  _ => selected ? _Mark.selected : _Mark.open,
};

/// The screen box of a city's mark at [p] (the place, the middle of the
/// marker painted on the map; the selected pin's drop has its round head
/// there).
Rect _markRect(Offset p, _Mark m) => switch (m) {
  _Mark.selected => Rect.fromLTRB(p.dx - _PinMark.drop / 2, p.dy - _PinMark.head, p.dx + _PinMark.drop / 2, p.dy - _PinMark.head + _PinMark.drop + 2),
  _Mark.open => Rect.fromCircle(center: p, radius: _PinMark.dot / 2),
  _Mark.locked => Rect.fromCircle(center: p, radius: _PinMark.lockedDot / 2),
  _Mark.comingSoon => Rect.fromCircle(center: p, radius: _PinMark.soonDot / 2),
  _Mark.selectedLocked || _Mark.selectedComingSoon => Rect.fromCircle(center: p, radius: _PinMark.ring / 2),
};

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
    bool clear(Rect r) =>
        screen.contains(r.topLeft) &&
        screen.contains(r.bottomRight) &&
        !placed.any((o) => o.overlaps(r)) &&
        !avoid.any((o) => o.overlaps(r)) &&
        !marks.indexed.any((e) => e.$1 != i && e.$2.overlaps(r));
    final at = candidates.where(clear).firstOrNull ?? (i == selected ? below : null);
    out[i] = at;
    if (at != null) placed.add(at);
  }
  return out;
}

/// The cities' marks and names over the world, at their places on screen
/// ([points]). One tap layer under them picks the nearest mark within
/// reach (or the name tapped), so neighbouring cities never cover each
/// other's touch; drags and pinches pass through to the map.
class _PinLayer extends StatelessWidget {
  const _PinLayer({
    required this.cities,
    required this.points,
    required this.viewport,
    required this.painted,
    required this.others,
    required this.selectedId,
    required this.avoid,
    required this.still,
    required this.onTap,
  });

  final List<WorldCityState> cities;
  final List<Offset> points;
  final Size viewport;

  /// The world's width on screen now: the size of the markers the artwork
  /// paints under the cities ([ArtAssets.worldMapMarkerRadius]).
  final double painted;

  /// The painted markers that are no city ([ArtAssets.worldMapOtherMarkers]),
  /// on screen: names keep off them.
  final List<Offset> others;

  final String selectedId;
  final List<Rect> avoid;
  final bool still;
  final ValueChanged<String> onTap;

  /// A mark's touch: this square around its place, or its painted marker
  /// when bigger (where a neighbour's place is nearer, the tap is the
  /// neighbour's).
  static const touch = 48.0;

  static final _sizes = <String, Size>{};

  static Size _measure(String text, _Mark mark) => _sizes.putIfAbsent('${mark.chosen}|$text', () {
    final tp = TextPainter(
      text: TextSpan(text: text, style: _CityName.styleOf(mark)),
      textDirection: TextDirection.ltr,
      maxLines: 1,
      textScaler: TextScaler.noScaling,
    )..layout();
    final pad = _CityName.paddingOf(mark);
    final size = Size(tp.width.ceilToDouble() + pad.horizontal, tp.height.ceilToDouble() + pad.vertical);
    tp.dispose();
    return size;
  });

  @override
  Widget build(BuildContext context) {
    final n = cities.length;
    final sel = cities.indexWhere((c) => c.city.id == selectedId);
    final marks = [for (var i = 0; i < n; i++) _markOf(cities[i], selected: i == sel)];
    // A city on a painted marker takes the marker's room too (circle and
    // tip), so names stay off it.
    final r = painted * ArtAssets.worldMapMarkerRadius;
    final tip = painted * ArtAssets.worldMapMarkerTip;
    Rect paintedAt(Offset p) => Rect.fromLTRB(p.dx - r, p.dy - r, p.dx + r, p.dy + tip);
    final markRects = [
      for (var i = 0; i < n; i++)
        cities[i].city.mapAt == null ? _markRect(points[i], marks[i]) : _markRect(points[i], marks[i]).expandToInclude(paintedAt(points[i])),
    ];
    final within = math.max(touch / 2, r);
    final order = [
      if (sel >= 0) sel,
      for (var i = 0; i < n; i++)
        if (i != sel) i,
    ];
    final labels = placeLabels(
      points: points,
      marks: markRects,
      sizes: [for (var i = 0; i < n; i++) _measure(cities[i].city.name, marks[i])],
      order: order,
      viewport: viewport,
      selected: sel >= 0 ? sel : null,
      avoid: [...avoid, for (final o in others) paintedAt(o)],
    );
    final reach = Rect.fromLTWH(-touch, -touch, viewport.width + 2 * touch, viewport.height + 2 * touch);
    final shown = [for (var i = 0; i < n; i++) reach.contains(points[i])];

    /// The city a tap at [at] chooses: the nearest place within reach (the
    /// selected drop counts all over), else the name tapped.
    String? hit(Offset at) {
      int? best;
      var nearest = double.infinity;
      for (var i = 0; i < n; i++) {
        if (!shown[i]) continue;
        final d = (at - points[i]).distance;
        final onDrop = i == sel && markRects[i].inflate(4).contains(at);
        if ((d <= within || onDrop) && d < nearest) {
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
                  child: _CityName(key: ValueKey('city-label-${cities[i].city.id}'), name: cities[i].city.name, mark: marks[i]),
                ),
              ),
            Positioned(
              left: points[i].dx - touch / 2,
              top: points[i].dy - touch / 2,
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

/// A city's mark, centred in its touch square on the place (inside the
/// marker painted there, so the two read as one): the gold drop of the
/// chosen city (its round head on the place), a navy dot for one that can
/// be played, a dim dot with a lock for one still locked, a dashed ring
/// for one coming soon.
class _PinMark extends StatelessWidget {
  const _PinMark({super.key, required this.mark, required this.still});

  final _Mark mark;
  final bool still;

  static const drop = 28.0;

  /// From the drop's top to the middle of its round head ([_DropPainter]).
  static const head = drop * 0.38 + 1;
  static const dot = 14.0;
  static const lockedDot = 16.0;
  static const soonDot = 10.0;

  /// The gold ring round a chosen city that cannot be entered.
  static const ring = 26.0;

  static const _shade = [BoxShadow(color: Color(0x80000000), blurRadius: 4, offset: Offset(0, 1))];

  @override
  Widget build(BuildContext context) {
    const mid = _PinLayer.touch / 2;
    return switch (mark) {
      _Mark.selected => Stack(
        clipBehavior: Clip.none,
        children: [
          // A soft glow on the ground under the drop.
          Positioned(
            left: mid - 22,
            top: mid - head + drop - 10,
            width: 44,
            height: 20,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: RadialGradient(colors: [AppColors.goldLight.withValues(alpha: 0.6), AppColors.goldLight.withValues(alpha: 0)]),
              ),
            ),
          ),
          Positioned(
            left: mid - drop / 2,
            top: mid - head,
            width: drop,
            height: drop,
            // A short drop into place when chosen.
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: still ? 1 : 0.55, end: 1),
              duration: still ? Duration.zero : const Duration(milliseconds: 260),
              curve: Curves.easeOutBack,
              builder: (context, s, child) => Transform.scale(scale: s, alignment: Alignment.bottomCenter, child: child),
              child: const CustomPaint(painter: _DropPainter()),
            ),
          ),
        ],
      ),
      _Mark.open => Center(
        child: Container(
          width: dot,
          height: dot,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.navy,
            border: Border.all(color: AppColors.goldLight, width: AppLine.rule),
            boxShadow: _shade,
          ),
        ),
      ),
      _Mark.locked => Center(
        child: Container(
          width: lockedDot,
          height: lockedDot,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.locked,
            border: Border.all(color: AppColors.creamGold.withValues(alpha: 0.6), width: AppLine.hairline),
            boxShadow: _shade,
          ),
          child: const InkIcon(InkGlyph.lock, size: 9, color: AppColors.paperLight),
        ),
      ),
      _Mark.comingSoon => const Center(
        child: CustomPaint(size: Size.square(soonDot), painter: _DashedRingPainter()),
      ),
      _Mark.selectedLocked => _chosen(const _PinMark(mark: _Mark.locked, still: true)),
      _Mark.selectedComingSoon => _chosen(const _PinMark(mark: _Mark.comingSoon, still: true)),
    };
  }

  /// [inner] in a gold ring with a soft glow: chosen, but not to be entered.
  Widget _chosen(Widget inner) => Center(
    child: Container(
      width: ring,
      height: ring,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.navyDeep.withValues(alpha: 0.55),
        border: Border.all(color: AppColors.goldLight, width: 1.5),
        boxShadow: [BoxShadow(color: AppColors.goldLight.withValues(alpha: 0.45), blurRadius: 10)],
      ),
      child: OverflowBox(maxWidth: _PinLayer.touch, maxHeight: _PinLayer.touch, child: inner),
    ),
  );
}

/// The chosen city's gold drop: round above, narrowing to its tip at the
/// bottom middle, with a navy eye.
class _DropPainter extends CustomPainter {
  const _DropPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width * 0.38;
    final c = Offset(size.width / 2, r + 1);
    final tip = Offset(size.width / 2, size.height);
    // From the tip along a tangent, round the head, back down the other.
    final t = math.acos(r / (tip.dy - c.dy));
    final path = Path()
      ..moveTo(tip.dx, tip.dy)
      ..arcTo(Rect.fromCircle(center: c, radius: r), math.pi / 2 + t, 2 * math.pi - 2 * t, false)
      ..close();
    canvas.drawShadow(path, const Color(0xFF000000), 2.5, false);
    canvas.drawPath(path, Paint()..color = AppColors.gold);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppLine.hairline
        ..color = AppColors.goldLight,
    );
    canvas.drawCircle(c, r * 0.42, Paint()..color = AppColors.navyDeep);
  }

  @override
  bool shouldRepaint(_DropPainter old) => false;
}

/// An empty dashed ring: a city whose season is not made yet.
class _DashedRingPainter extends CustomPainter {
  const _DashedRingPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final ring = Rect.fromCircle(center: size.center(Offset.zero), radius: size.width / 2 - 0.75);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = AppColors.creamGold.withValues(alpha: 0.85);
    const dashes = 8;
    for (var k = 0; k < dashes; k++) {
      canvas.drawArc(ring, 2 * math.pi * k / dashes, math.pi / dashes, false, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedRingPainter old) => false;
}

/// A city's name on the map: the chosen city's on a navy tag, the others
/// in light letters over the map (dimmer when locked, dimmest when coming
/// soon).
class _CityName extends StatelessWidget {
  const _CityName({super.key, required this.name, required this.mark});

  final String name;
  final _Mark mark;

  static const _halo = [Shadow(color: Color(0xE6151D30), blurRadius: 3), Shadow(color: Color(0xB3151D30), blurRadius: 6)];

  static TextStyle styleOf(_Mark m) => m.chosen
      ? AppText.style(AppText.body, size: 13, weight: FontWeight.w700, color: AppColors.paperLight, letterSpacing: 0.4, height: 1.2)
      : AppText.style(
          AppText.body,
          size: 11,
          weight: FontWeight.w700,
          color: AppColors.paperLight,
          letterSpacing: 0.4,
          height: 1.2,
        ).copyWith(shadows: _halo);

  static EdgeInsets paddingOf(_Mark m) =>
      m.chosen ? const EdgeInsets.symmetric(horizontal: 9, vertical: 3) : const EdgeInsets.symmetric(horizontal: 2);

  @override
  Widget build(BuildContext context) {
    final text = Padding(
      padding: paddingOf(mark),
      child: Text(name, maxLines: 1, softWrap: false, textScaler: TextScaler.noScaling, style: styleOf(mark)),
    );
    return switch (mark) {
      _Mark.selected || _Mark.selectedLocked || _Mark.selectedComingSoon => DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.navyDeep.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.goldLight.withValues(alpha: 0.55), width: AppLine.hairline),
        ),
        child: text,
      ),
      _Mark.open => text,
      _Mark.locked => Opacity(opacity: 0.7, child: text),
      _Mark.comingSoon => Opacity(opacity: 0.5, child: text),
    };
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
