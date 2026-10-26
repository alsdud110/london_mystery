import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/models/backdrop.dart';
import '../data/models/scene_explore.dart' show ScenePixels;

/// A picture laid as a full-screen backdrop by its [look] (see
/// [BackdropLayout]): only its allowed part is ever drawn. Where the picture
/// stops short of the screen's edges, the room around it is filled with
/// the same allowed part, softly blurred: covering the screen, and each
/// edge the picture stops at drawn on out towards the screen's edge (its
/// last strip stretched, fading away), while the picture's own edges there
/// fade into it. So the picture never reads as a card floating on the
/// night: it runs out into its own colours.
///
/// [overlay] is drawn over the whole picture, clipped with it (painted
/// clock hands). [fallback] stands in for a picture that cannot be read.
class SceneBackdrop extends StatelessWidget {
  const SceneBackdrop({
    super.key,
    required this.file,
    required this.pixels,
    this.look = const BackdropLook(),
    this.imageKey,
    this.overlay,
    this.fallback,
  });

  final String file;
  final ScenePixels pixels;
  final BackdropLook look;

  /// The sharp picture's own key (tests find it by it).
  final Key? imageKey;
  final Widget? overlay;
  final Widget? fallback;

  /// How far the picture's inner edges fade into the fill (screen points,
  /// at most this share of the picture's shown size).
  static const _feather = 56.0;
  static const _featherShare = 0.2;

  static double featherOf(double length) => math.min(_feather, length * _featherShare);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final size = box.biggest;
        if (!size.isFinite || size.isEmpty) return const SizedBox.expand();
        final at = BackdropLayout.of(size, pixels, look);
        final dpr = MediaQuery.devicePixelRatioOf(context);
        // One decode for the picture and its fill, at the size the picture
        // shows, never beyond the file.
        final decode = math.min(pixels.width, at.picture.width * dpr).ceil();
        final provider = ResizeImage.resizeIfNeeded(decode, null, AssetImage(file));
        final shown = at.shown;
        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (at.filled) _Fill(provider: provider, at: at, bounds: look.bounds.intersect(BackdropLook.whole)),
              Positioned.fromRect(
                rect: shown,
                child: ClipRect(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fromRect(
                        rect: at.picture.shift(-shown.topLeft),
                        child: _Feathered(
                          // Only the edges that stop short of the screen's fade.
                          left: shown.left > 0.5,
                          top: shown.top > 0.5,
                          right: shown.right < size.width - 0.5,
                          bottom: shown.bottom < size.height - 0.5,
                          window: shown.shift(-at.picture.topLeft),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image(
                                key: imageKey,
                                image: provider,
                                fit: BoxFit.fill,
                                excludeFromSemantics: true,
                                errorBuilder: (context, error, stack) => fallback ?? const SizedBox.expand(),
                              ),
                              ?overlay,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The room around a backdrop's picture, painted from the same decoded
/// picture as it (see [SceneBackdrop]); nothing until it is decoded.
class _Fill extends StatefulWidget {
  const _Fill({required this.provider, required this.at, required this.bounds});

  final ImageProvider provider;
  final BackdropLayout at;

  /// The allowed part of the picture (fractions): nothing else is painted.
  final Rect bounds;

  @override
  State<_Fill> createState() => _FillState();
}

class _FillState extends State<_Fill> {
  ImageStream? _stream;
  ImageInfo? _info;
  late final _listener = ImageStreamListener(
    (info, _) {
      if (!mounted) return;
      setState(() {
        _info?.dispose();
        _info = info;
      });
    },
    // The picture itself shows its fallback; the room stays night.
    onError: (error, stack) {},
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolve();
  }

  @override
  void didUpdateWidget(_Fill old) {
    super.didUpdateWidget(old);
    if (old.provider != widget.provider) _resolve();
  }

  void _resolve() {
    final stream = widget.provider.resolve(createLocalImageConfiguration(context));
    if (stream.key == _stream?.key) return;
    _stream?.removeListener(_listener);
    _stream = stream..addListener(_listener);
  }

  @override
  void dispose() {
    _stream?.removeListener(_listener);
    _info?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final image = _info?.image;
    return CustomPaint(
      painter: image == null ? null : _FillPainter(image, widget.at, widget.bounds),
      child: const SizedBox.expand(),
    );
  }
}

class _FillPainter extends CustomPainter {
  _FillPainter(this.image, this.at, this.bounds);

  final ui.Image image;
  final BackdropLayout at;
  final Rect bounds;

  /// A strip of the shown picture this thick (screen points) is stretched
  /// out over the room beyond each edge it stops short at.
  static const _strip = 6.0;

  @override
  void paint(Canvas canvas, Size size) {
    final box = Offset.zero & size;
    final iw = image.width.toDouble(), ih = image.height.toDouble();
    // A rect on screen, over [picture] (on screen), as image pixels.
    Rect source(Rect r, Rect picture) => Rect.fromLTRB(
          (r.left - picture.left) / picture.width * iw,
          (r.top - picture.top) / picture.height * ih,
          (r.right - picture.left) / picture.width * iw,
          (r.bottom - picture.top) / picture.height * ih,
        );
    final paint = Paint()..filterQuality = FilterQuality.low;
    canvas.saveLayer(box, Paint()..imageFilter = ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16, tileMode: TileMode.clamp));
    // The allowed part covering the screen.
    final fill = at.fill!;
    final allowed = Rect.fromLTRB(
      fill.left + bounds.left * fill.width,
      fill.top + bounds.top * fill.height,
      fill.left + bounds.right * fill.width,
      fill.top + bounds.bottom * fill.height,
    ).intersect(box);
    canvas.drawImageRect(image, source(allowed, fill), allowed, paint);
    // Each edge the picture stops short at, drawn on out: whole at the
    // picture, gone by the screen's edge.
    final s = at.shown;
    void edge(Rect strip, Rect room, Alignment near, Alignment far) {
      canvas.saveLayer(room, Paint());
      canvas.drawImageRect(image, source(strip, at.picture), room, paint);
      canvas.drawRect(
        room,
        Paint()
          ..blendMode = BlendMode.dstIn
          ..shader = LinearGradient(
            begin: near,
            end: far,
            colors: const [Colors.white, Color(0x66FFFFFF), Colors.transparent],
            stops: const [0, 0.45, 1],
          ).createShader(room),
      );
      canvas.restore();
    }

    if (s.top > 0.5) {
      final f = SceneBackdrop.featherOf(s.height);
      edge(Rect.fromLTRB(s.left, s.top, s.right, s.top + _strip), Rect.fromLTRB(s.left, 0, s.right, s.top + f),
          Alignment.bottomCenter, Alignment.topCenter);
    }
    if (s.bottom < size.height - 0.5) {
      final f = SceneBackdrop.featherOf(s.height);
      edge(Rect.fromLTRB(s.left, s.bottom - _strip, s.right, s.bottom),
          Rect.fromLTRB(s.left, s.bottom - f, s.right, size.height), Alignment.topCenter, Alignment.bottomCenter);
    }
    if (s.left > 0.5) {
      final f = SceneBackdrop.featherOf(s.width);
      edge(Rect.fromLTRB(s.left, s.top, s.left + _strip, s.bottom), Rect.fromLTRB(0, s.top, s.left + f, s.bottom),
          Alignment.centerRight, Alignment.centerLeft);
    }
    if (s.right < size.width - 0.5) {
      final f = SceneBackdrop.featherOf(s.width);
      edge(Rect.fromLTRB(s.right - _strip, s.top, s.right, s.bottom),
          Rect.fromLTRB(s.right - f, s.top, size.width, s.bottom), Alignment.centerLeft, Alignment.centerRight);
    }
    canvas.restore();
    // A shade deeper than the picture: it leads, the room around it follows.
    canvas.drawRect(box, Paint()..color = AppColors.navyDeep.withValues(alpha: 0.18));
  }

  @override
  bool shouldRepaint(_FillPainter old) => old.image != image || old.at != at || old.bounds != bounds;
}

/// The picture with the edges of its shown [window] (in the picture's own
/// points) faded out on the sides asked for.
class _Feathered extends StatelessWidget {
  const _Feathered({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.window,
    required this.child,
  });

  final bool left, top, right, bottom;
  final Rect window;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!left && !top && !right && !bottom) return child;
    Widget fade(Widget child, {required bool horizontal}) {
      final from = horizontal ? left : top;
      final to = horizontal ? right : bottom;
      if (!from && !to) return child;
      return ShaderMask(
        blendMode: BlendMode.dstIn,
        shaderCallback: (rect) {
          final start = horizontal ? window.left : window.top;
          final end = horizontal ? window.right : window.bottom;
          final length = horizontal ? rect.width : rect.height;
          final f = SceneBackdrop.featherOf(end - start);
          double at(double v) => (v / length).clamp(0.0, 1.0);
          return LinearGradient(
            begin: horizontal ? Alignment.centerLeft : Alignment.topCenter,
            end: horizontal ? Alignment.centerRight : Alignment.bottomCenter,
            colors: const [Colors.transparent, Colors.white, Colors.white, Colors.transparent],
            stops: [at(start), at(from ? start + f : start), at(to ? end - f : end), at(end)],
          ).createShader(rect);
        },
        child: child,
      );
    }

    return fade(fade(child, horizontal: true), horizontal: false);
  }
}
