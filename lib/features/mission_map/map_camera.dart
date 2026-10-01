import 'dart:ui' show Offset, Size;

/// The camera over the London map: which part of the map world shows in
/// the viewport. Pure geometry, so it is easy to test; the animation lives
/// in the map viewport widget.
///
/// Positions on the map are fractions of the world (0..1). An offset is
/// where the world's top-left corner sits in the viewport (zero or less).
class MapCamera {
  const MapCamera({required this.viewport, required this.world, this.focusDrop = defaultFocusDrop});

  /// A camera whose world is the map at [aspect] (width / height), scaled
  /// to cover the whole viewport and then [zoom]ed in, so the map is always
  /// larger than the viewport and never shows an empty edge.
  factory MapCamera.cover(Size viewport, {required double aspect, double zoom = defaultZoom}) {
    final height = (viewport.width / aspect > viewport.height ? viewport.width / aspect : viewport.height) * zoom;
    return MapCamera(viewport: viewport, world: Size(height * aspect, height));
  }

  /// How far the map is magnified beyond just covering the viewport: enough
  /// to show one part of London, not the whole map.
  static const defaultZoom = 1.2;

  /// How far below the viewport centre the focused place sits. Its
  /// "YOU'RE HERE" note is written above the pin, so this keeps the pin and
  /// the note together around the centre.
  static const defaultFocusDrop = 20.0;

  final Size viewport;
  final Size world;
  final double focusDrop;

  /// The point of the world at [place] (fractions of the world).
  Offset toWorld(Offset place) => Offset(place.dx * world.width, place.dy * world.height);

  /// The offset that brings [place] to the focus point (the centre, dropped
  /// by [focusDrop]), clamped so the world always covers the viewport. On
  /// an axis where the world is smaller than the viewport, it is centred.
  Offset offsetFor(Offset place) {
    final p = toWorld(place);
    return Offset(
      _clamp(viewport.width / 2 - p.dx, viewport.width - world.width),
      _clamp(viewport.height / 2 + focusDrop - p.dy, viewport.height - world.height),
    );
  }

  /// Clamps [v] to [min, 0]; when the world is smaller (min > 0), centres.
  static double _clamp(double v, double min) => min > 0 ? min / 2 : v.clamp(min, 0.0);

  /// This camera with the world magnified [scale] times (1 or more) and the
  /// focus point at the exact centre: the camera moving in on a place, still
  /// clamped so the world covers the viewport.
  MapCamera zoomed(double scale) => MapCamera(viewport: viewport, world: world * scale, focusDrop: 0);

  /// Where [place] appears in the viewport with the camera at [offset].
  Offset onScreen(Offset place, Offset offset) => toWorld(place) + offset;
}
