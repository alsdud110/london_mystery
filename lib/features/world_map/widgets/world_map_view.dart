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
/// it. The pins stay the same size on screen whatever the zoom; pins that
/// would cover each other step apart, each still tied to its place.
class WorldMapView extends StatefulWidget {
  const WorldMapView({
    super.key,
    required this.cities,
    required this.selectedId,
    required this.homeId,
    required this.onSelect,
  });

  final List<WorldCityState> cities;

  /// The city whose card is shown.
  final String selectedId;

  /// The city the map opens on and goes back to.
  final String homeId;

  final ValueChanged<String> onSelect;

  /// How far the map can be magnified beyond covering the viewport.
  static const maxScale = 6.0;

  /// One tap of + or −.
  static const zoomStep = 1.6;

  /// How far past its east and west edges the world can be dragged (navy
  /// sea), so a city near an edge comes out from under the map's buttons.
  static const edge = 80.0;

  @override
  State<WorldMapView> createState() => _WorldMapViewState();
}

class _WorldMapViewState extends State<WorldMapView> with SingleTickerProviderStateMixin {
  final _view = TransformationController();
  late final AnimationController _move = AnimationController(vsync: this, duration: const Duration(milliseconds: 450))
    ..addListener(_step);
  Animation<Matrix4>? _tween;

  /// The viewport and the world (the artwork covering it) last laid out.
  Size? _viewport;
  Size _world = Size.zero;

  void _step() {
    final t = _tween;
    if (t != null) _view.value = t.value;
  }

  @override
  void dispose() {
    _move.dispose();
    _view.dispose();
    super.dispose();
  }

  WorldCity _city(String id) => widget.cities.firstWhere((c) => c.city.id == id).city;

  double get _scale => _view.value.getMaxScaleOnAxis();

  /// The view with world point [p] at the viewport's centre, magnified
  /// [scale] times, the world still covering the viewport (but for [edge]
  /// east and west).
  Matrix4 _centredOn(Offset p, double scale) {
    final v = _viewport!;
    final s = scale.clamp(1.0, WorldMapView.maxScale);
    const e = WorldMapView.edge;
    final x = (v.width / 2 - p.dx * s).clamp(math.min(e, v.width - _world.width * s - e), e);
    final y = (v.height / 2 - p.dy * s).clamp(math.min(0.0, v.height - _world.height * s), 0.0);
    return Matrix4.diagonal3Values(s, s, 1)..setTranslationRaw(x.toDouble(), y.toDouble(), 0);
  }

  Offset _onWorld(WorldCity c) => Offset(c.at.dx * _world.width, c.at.dy * _world.height);

  /// The world point at the viewport's centre now.
  Offset get _centre {
    final t = _view.value.getTranslation();
    final v = _viewport!;
    return Offset((v.width / 2 - t.x) / _scale, (v.height / 2 - t.y) / _scale);
  }

  void _go(Matrix4 to) {
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _move.stop();
      _view.value = to;
      return;
    }
    _tween = Matrix4Tween(begin: _view.value.clone(), end: to).animate(CurvedAnimation(parent: _move, curve: Curves.easeInOutCubic));
    _move.forward(from: 0);
  }

  void _focus(String cityId) => _go(_centredOn(_onWorld(_city(cityId)), _scale));

  void _zoom(double by) => _go(_centredOn(_centre, _scale * by));

  void _select(String cityId) {
    widget.onSelect(cityId);
    _focus(cityId);
  }

  void _home() {
    widget.onSelect(widget.homeId);
    _focus(widget.homeId);
  }

  /// Laid out at [viewport]: the first time, the map opens on the home
  /// city; after that, the view only stays inside the world.
  void _layOut(Size viewport) {
    if (_viewport == viewport) return;
    final first = _viewport == null;
    _viewport = viewport;
    final h = math.max(viewport.height, viewport.width / ArtAssets.worldMapAspect);
    _world = Size(h * ArtAssets.worldMapAspect, h);
    _move.stop();
    _view.value = first ? _centredOn(_onWorld(_city(widget.homeId)), 1) : _centredOn(_centre, _scale);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        _layOut(box.biggest);
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
                    boundaryMargin: const EdgeInsets.symmetric(horizontal: WorldMapView.edge),
                    onInteractionStart: (_) => _move.stop(),
                    child: SizedBox.fromSize(
                      size: _world,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: Image.asset(
                              ArtAssets.worldMap,
                              fit: BoxFit.fill,
                              filterQuality: FilterQuality.medium,
                              excludeFromSemantics: true,
                              errorBuilder: (context, error, stack) =>
                                  const ColoredBox(key: ValueKey('world-map-missing'), color: AppColors.navyDeep),
                            ),
                          ),
                          // On the world, so a drag that starts on a pin
                          // still moves the map; sized back down by the zoom.
                          Positioned.fill(
                            child: AnimatedBuilder(
                              animation: _view,
                              builder: (context, _) => _Pins(
                                cities: widget.cities,
                                at: [for (final c in widget.cities) _onWorld(c.city)],
                                view: _view.value,
                                viewport: box.biggest,
                                selectedId: widget.selectedId,
                                homeId: widget.homeId,
                                onTap: _select,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: AppSpace.md,
                top: AppSpace.md,
                child: Column(
                  children: [
                    _MapButton(
                      key: const ValueKey('world-map-home'),
                      tooltip: 'Back to my city',
                      onTap: _home,
                      child: const InkIcon(InkGlyph.pin, size: AppIconSize.medium, color: AppColors.goldLight),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    _MapButton(
                      key: const ValueKey('world-map-zoom-in'),
                      tooltip: 'Zoom in',
                      onTap: () => _zoom(WorldMapView.zoomStep),
                      child: const _Sign('+'),
                    ),
                    const SizedBox(height: AppSpace.xs),
                    _MapButton(
                      key: const ValueKey('world-map-zoom-out'),
                      tooltip: 'Zoom out',
                      onTap: () => _zoom(1 / WorldMapView.zoomStep),
                      child: const _Sign('−'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Screen positions for pins at [points] such that no two lie within
/// [gap] across and [rise] up or down of each other: pins that would,
/// step apart around their middle (up to three side by side, west to east;
/// more on a ring). Others stay where they are.
@visibleForTesting
List<Offset> spreadPins(List<Offset> points, {double gap = _Pins.gap, double rise = _Pins.rise}) {
  final n = points.length;
  final group = List<int>.generate(n, (i) => i);
  int root(int i) => group[i] == i ? i : group[i] = root(group[i]);
  for (var i = 0; i < n; i++) {
    for (var j = i + 1; j < n; j++) {
      final d = points[i] - points[j];
      if (d.dx.abs() < gap && d.dy.abs() < rise) group[root(i)] = root(j);
    }
  }
  final out = [...points];
  final groups = <int, List<int>>{};
  for (var i = 0; i < n; i++) {
    (groups[root(i)] ??= []).add(i);
  }
  for (final members in groups.values) {
    if (members.length < 2) continue;
    final mid = members.fold(Offset.zero, (s, i) => s + points[i]) / members.length.toDouble();
    if (members.length <= 3) {
      // Side by side, west to east, as they lie.
      members.sort((a, b) => points[a].dx.compareTo(points[b].dx));
      for (final (k, i) in members.indexed) {
        out[i] = mid + Offset(gap * (k - (members.length - 1) / 2), 0);
      }
      continue;
    }
    // Around the middle, in the order they lie around it, the first where
    // it lies.
    members.sort((a, b) => (points[a] - mid).direction.compareTo((points[b] - mid).direction));
    final radius = gap / (2 * math.sin(math.pi / members.length));
    final first = points[members.first] == mid ? -math.pi : (points[members.first] - mid).direction;
    for (final (k, i) in members.indexed) {
      final a = first + 2 * math.pi * k / members.length;
      out[i] = mid + Offset(math.cos(a), math.sin(a)) * radius;
    }
  }
  return out;
}

/// The cities' pins on the world, at their places ([at], world points),
/// laid out on screen ([view]: the world's zoom and move) so they keep
/// their size and stay clear of each other at every zoom.
class _Pins extends StatelessWidget {
  const _Pins({
    required this.cities,
    required this.at,
    required this.view,
    required this.viewport,
    required this.selectedId,
    required this.homeId,
    required this.onTap,
  });

  final List<WorldCityState> cities;
  final List<Offset> at;
  final Matrix4 view;
  final Size viewport;
  final String selectedId;
  final String homeId;
  final ValueChanged<String> onTap;

  /// Pins closer than this across (or [rise] up and down) step apart.
  static const gap = 84.0;
  static const rise = 64.0;

  @override
  Widget build(BuildContext context) {
    final scale = view.getMaxScaleOnAxis();
    final move = view.getTranslation();
    Offset toWorld(Offset p) => Offset((p.dx - move.x) / scale, (p.dy - move.y) / scale);
    final onScreen = [for (final p in at) MatrixUtils.transformPoint(view, p)];
    final spread = spreadPins(onScreen);
    final drawn = [for (final p in spread) toWorld(p)];
    final shown = Rect.fromLTWH(-gap, -gap, viewport.width + 2 * gap, viewport.height + 2 * gap);
    // The selected pin on top.
    final order = [
      for (var i = 0; i < cities.length; i++)
        if (cities[i].city.id != selectedId) i,
      for (var i = 0; i < cities.length; i++)
        if (cities[i].city.id == selectedId) i,
    ];
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // A pin stepped aside is tied to its place by a thread.
        Positioned.fill(
          child: IgnorePointer(child: CustomPaint(painter: _Threads(from: at, to: drawn, scale: scale))),
        ),
        for (final i in order)
          if (shown.contains(spread[i]))
            Positioned(
              left: drawn[i].dx - _CityPin.width / 2,
              top: drawn[i].dy - _CityPin.tipY,
              // The same size on screen at every zoom, its tip on the place.
              child: Transform.scale(
                scale: 1 / scale,
                alignment: Alignment.topCenter,
                origin: const Offset(0, _CityPin.tipY),
                child: _CityPin(
                  key: ValueKey('city-pin-${cities[i].city.id}'),
                  state: cities[i],
                  selected: cities[i].city.id == selectedId,
                  home: cities[i].city.id == homeId,
                  onTap: () => onTap(cities[i].city.id),
                ),
              ),
            ),
      ],
    );
  }
}

/// A thin gold line and a dot at a city's true place, under a pin that
/// stepped aside from it.
class _Threads extends CustomPainter {
  const _Threads({required this.from, required this.to, required this.scale});

  /// World points; [scale]: the zoom (lines keep their width on screen).
  final List<Offset> from;
  final List<Offset> to;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = AppColors.goldLight.withValues(alpha: 0.8)
      ..strokeWidth = AppLine.hairline / scale;
    final dot = Paint()..color = AppColors.goldLight;
    for (var i = 0; i < from.length; i++) {
      if ((from[i] - to[i]).distance * scale < 1) continue;
      canvas.drawLine(from[i], to[i], line);
      canvas.drawCircle(from[i], 3 / scale, dot);
    }
  }

  @override
  bool shouldRepaint(_Threads old) => old.from != from || old.to != to || old.scale != scale;
}

/// A city's pin: a round badge on a short stem whose tip is the place, and
/// the city's name on a paper tag under it.
class _CityPin extends StatelessWidget {
  const _CityPin({super.key, required this.state, required this.selected, required this.home, required this.onTap});

  final WorldCityState state;
  final bool selected;
  final bool home;
  final VoidCallback onTap;

  static const width = 96.0;
  static const badge = 32.0;
  static const stem = 7.0;

  /// From the pin's top to its tip.
  static const tipY = badge + stem;

  @override
  Widget build(BuildContext context) {
    final status = state.status;
    final open = status != WorldCityStatus.locked && status != WorldCityStatus.comingSoon;
    final fill = selected ? AppColors.gold : (open ? AppColors.navy : AppColors.leatherDeep);
    final ink = selected ? AppColors.navyDeep : (open ? AppColors.goldLight : AppColors.creamGold);
    final glyph = switch (status) {
      WorldCityStatus.locked || WorldCityStatus.comingSoon => InkGlyph.lock,
      WorldCityStatus.completed => InkGlyph.check,
      _ => InkGlyph.pin,
    };
    final name = state.city.name.toUpperCase();
    return Semantics(
      button: true,
      selected: selected,
      label: '$name, ${_say(status)}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: badge,
                height: badge,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: fill,
                  border: Border.all(
                    color: home || selected ? AppColors.goldLight : AppColors.gold,
                    width: home || selected ? AppLine.ink + 0.5 : AppLine.rule,
                  ),
                  boxShadow: AppShadow.pinned,
                ),
                child: InkIcon(glyph, size: AppIconSize.small, color: ink),
              ),
              CustomPaint(size: const Size(10, stem), painter: _Stem(fill)),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected ? AppColors.paperLight : AppColors.parchment,
                  border: Border.all(color: AppColors.gold, width: AppLine.hairline),
                  boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 3, offset: Offset(0.5, 1.5))],
                ),
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textScaler: TextScaler.noScaling,
                  style: AppText.eyebrow(color: open ? AppColors.navy : AppColors.inkBrown).copyWith(fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
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

/// The pin's stem, narrowing to its tip.
class _Stem extends CustomPainter {
  const _Stem(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_Stem old) => old.color != color;
}

/// A round control on the map (back to my city, zoom).
class _MapButton extends StatelessWidget {
  const _MapButton({super.key, required this.tooltip, required this.onTap, required this.child});

  final String tooltip;
  final VoidCallback onTap;
  final Widget child;

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
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.navyDeep.withValues(alpha: 0.88),
              border: Border.all(color: AppColors.gold, width: AppLine.rule),
              boxShadow: AppShadow.pinned,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// + or − on a zoom button.
class _Sign extends StatelessWidget {
  const _Sign(this.sign);

  final String sign;

  @override
  Widget build(BuildContext context) => Text(
    sign,
    textScaler: TextScaler.noScaling,
    style: AppText.title(size: 24, color: AppColors.goldLight).copyWith(height: 1),
  );
}
