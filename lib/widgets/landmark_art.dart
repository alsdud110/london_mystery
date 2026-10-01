import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../data/models/mission.dart';
import 'art_assets.dart';

/// The scene of a place, everywhere the game shows one (mission, final case,
/// image choices, the unlocked-place card, the Case Solved photo).
///
/// A place with a picture in [ArtAssets.scenes] (the nine London landmarks)
/// shows that picture, whole; every other place, or a picture that fails to
/// load, is drawn in code: vintage storybook ink outlines with a slightly
/// hand-drawn double line and a few muted washes. Screens only name the
/// [Artwork]; which file or drawing it is lives here and in [ArtAssets].
class LandmarkArt extends StatelessWidget {
  const LandmarkArt(
    this.artwork, {
    super.key,
    this.borderRadius = 24,
    this.showSky = true,
    this.solved = 0,
    this.showName = true,
  }) : _picture = true;

  /// The code drawing of [artwork] only, never its picture (what shows when
  /// a picture is missing).
  const LandmarkArt.drawing(this.artwork, {super.key, this.borderRadius = 24, this.showSky = true, this.solved = 0})
    : showName = true,
      _picture = false;

  final Artwork artwork;
  final double borderRadius;
  final bool showSky;

  /// False hides the name plate printed on a scene picture. Only for an
  /// image-choice answer: the place must be recognized, not read (the plate
  /// would tell the answer). Drawn scenes have no name either way.
  final bool showName;

  /// 0 = the place as the detective finds it, 1 = after the case is solved
  /// (in between while the solve animation plays). Only scenes that change
  /// when solved use it: the Case 02 clock turns from 8:17 to 9:17.
  final double solved;

  final bool _picture;

  /// Places inside a landmark with no drawing of their own yet, and the
  /// drawing used for each. A stand-in lends its *drawing* only, never its
  /// picture: the Boathouse is a place in Hyde Park, not Hyde Park, so it
  /// stays drawn until it has a picture of its own in [ArtAssets.scenes].
  static const standIns = {
    Artwork.oldSuitcase: Artwork.suitcase,
    Artwork.egyptRoom: Artwork.britishMuseum,
    Artwork.greatCourt: Artwork.britishMuseum,
    Artwork.boathouse: Artwork.hydePark,
    Artwork.roseGarden: Artwork.hydePark,
    Artwork.waitingRoom: Artwork.kingsCross,
    Artwork.staffRoom: Artwork.buckinghamPalace,
    Artwork.courtyard: Artwork.buckinghamPalace,
    Artwork.dressingRoom: Artwork.theatre,
  };

  /// Whether [artwork] shows a picture file (not the code drawing).
  static bool hasPicture(Artwork artwork, {double solved = 0}) => ArtAssets.scene(artwork, solved: solved) != null;

  /// Width / height of a frame that fits [artwork]: the picture's own ratio,
  /// so it shows whole without stretching, or 4:3 for a drawing.
  static double aspectOf(Artwork artwork, {double solved = 0}) =>
      hasPicture(artwork, solved: solved) ? ArtAssets.sceneAspect(artwork) : 4 / 3;

  @override
  Widget build(BuildContext context) {
    final drawn = CustomPaint(
      painter: _LandmarkPainter(standIns[artwork] ?? artwork, showSky: showSky, solved: solved),
      child: const SizedBox.expand(),
    );
    final file = _picture ? ArtAssets.scene(artwork, solved: solved) : null;
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: file == null ? drawn : _ScenePicture(file, showName: showName, fallback: drawn),
    );
  }
}

/// A scene picture: whole (contain), with its own paper frame and name plate.
/// Without the name plate ([showName] false), the part above it fills the
/// frame instead.
class _ScenePicture extends StatelessWidget {
  const _ScenePicture(this.file, {required this.showName, required this.fallback});

  final String file;
  final bool showName;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    if (showName) {
      return LayoutBuilder(
        builder: (context, box) => Image.asset(
          file,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
          // Decoded at display size (a place picture is ~1300 px); never
          // enlarged beyond the file.
          cacheWidth: box.maxWidth.isFinite ? (box.maxWidth * MediaQuery.devicePixelRatioOf(context)).ceil() : null,
          excludeFromSemantics: true,
          errorBuilder: (context, error, stack) => fallback,
        ),
      );
    }
    final spec = ArtAssets.scenePrint;
    // The part of the picture to show, in fractions of its size.
    final left = spec.frame;
    final top = spec.frame;
    final width = 1 - 2 * spec.frame;
    final height = (showName ? 1 - spec.frame : spec.nameTop) - top;
    return FittedBox(
      fit: BoxFit.cover,
      clipBehavior: Clip.hardEdge,
      child: ClipRect(
        child: Align(
          // Places the part [left, top, width, height] in the clip.
          alignment: Alignment(2 * left / (1 - width) - 1, 2 * top / (1 - height) - 1),
          widthFactor: width,
          heightFactor: height,
          child: SizedBox.fromSize(
            size: spec.size,
            child: Image.asset(
              file,
              fit: BoxFit.cover,
              excludeFromSemantics: true,
              errorBuilder: (context, error, stack) => fallback,
            ),
          ),
        ),
      ),
    );
  }
}

class _LandmarkPainter extends CustomPainter {
  _LandmarkPainter(this.artwork, {required this.showSky, this.solved = 0});

  final Artwork artwork;
  final bool showSky;
  final double solved;

  // A small, muted wash palette (ink does the drawing, colour only tints).
  static const _stone = AppColors.stone;
  static const _stoneShade = AppColors.parchmentDark;
  static const _brick = AppColors.brick;
  static const _leather = Color(0xFFA88462);
  static const _leatherDark = Color(0xFF7A5E44);
  static const _window = AppColors.river;
  static const _guardRed = Color(0xFFA85A4E);
  static const _paper = AppColors.paperLight;

  Paint _fill(Color c) => Paint()..color = c;

  /// Keeps outlines pen-thin on large pictures (the scene is drawn in 100
  /// units, so without this a big picture would get a marker-thick line).
  double _pen = 1;

  Paint get _ink => Paint()
    ..color = AppColors.ink.withValues(alpha: 0.9)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.95 * _pen
    ..strokeJoin = StrokeJoin.round
    ..strokeCap = StrokeCap.round;

  /// A faint second pass, slightly off the first, like a pen going over a
  /// line twice.
  Paint get _sketch => Paint()
    ..color = AppColors.ink.withValues(alpha: 0.28)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.5
    ..strokeCap = StrokeCap.round;

  void _outline(Canvas c, Path path) {
    c.drawPath(path, _ink);
    c.drawPath(path.shift(const Offset(0.55, 0.4)), _sketch);
  }

  void _box(Canvas c, double l, double t, double r, double b, Color color, {double radius = 0.6}) {
    final rr = RRect.fromLTRBR(l, t, r, b, Radius.circular(radius));
    c.drawRRect(rr, _fill(color));
    _outline(c, Path()..addRRect(rr));
  }

  void _poly(Canvas c, List<Offset> pts, Color color) {
    final path = Path()..addPolygon(pts, true);
    c.drawPath(path, _fill(color));
    _outline(c, path);
  }

  @override
  void paint(Canvas canvas, Size size) {
    // Paper, not sky: the scene is a picture in a storybook.
    final bg = Rect.fromLTWH(0, 0, size.width, size.height);
    if (showSky) canvas.drawRect(bg, _fill(AppColors.paperLight));

    // Draw the scene in a centred 100x100 unit box.
    final s = math.min(size.width, size.height) / 100;
    _pen = (2.2 / s).clamp(0.6, 1.0);
    canvas.save();
    canvas.translate((size.width - 100 * s) / 2, (size.height - 100 * s) / 2);
    canvas.scale(s);

    if (showSky && !_isMap) {
      // Ground: a light wash across the full width, shaded with ink hatching.
      final extra = (size.width / s - 100) / 2 + 1;
      canvas.drawRect(Rect.fromLTRB(-extra, 84, 100 + extra, 140), _fill(_groundColor.withValues(alpha: 0.55)));
      canvas.drawLine(Offset(-extra, 84), Offset(100 + extra, 84), _ink..strokeWidth = 0.77);
      final hatch = _sketch..strokeWidth = 0.42;
      for (var x = -extra; x < 100 + extra; x += 3.2) {
        canvas.drawLine(Offset(x, 87), Offset(x + 2.4, 84.6), hatch);
      }
    }

    switch (artwork) {
      case Artwork.kingsCross:
        _kingsCross(canvas);
      case Artwork.suitcase:
        _suitcase(canvas);
      case Artwork.britishMuseum:
        _museum(canvas);
      case Artwork.bigBen:
        _bigBen(canvas);
      case Artwork.hydePark:
        _park(canvas);
      case Artwork.buckinghamPalace:
        _palace(canvas);
      case Artwork.towerBridge:
        _towerBridge(canvas);
      case Artwork.londonEye:
        _londonEye(canvas);
      case Artwork.royalBox:
        _royalBox(canvas);
      case Artwork.clockFace:
        _clockFace(canvas);
      case Artwork.gallery:
        _gallery(canvas);
      case Artwork.towerOfLondon:
        _towerOfLondon(canvas);
      case Artwork.lockedDoor:
        _lockedDoor(canvas);
      case Artwork.coventGarden:
        _coventGarden(canvas);
      case Artwork.theatre:
        _theatre(canvas);
      case Artwork.raven:
        _ravenOnWall(canvas);
      case Artwork.jewelCase:
        _jewelCase(canvas);
      // Drawn through their stand-in scene (see `LandmarkArt.standIns`).
      case Artwork.oldSuitcase ||
          Artwork.egyptRoom ||
          Artwork.greatCourt ||
          Artwork.boathouse ||
          Artwork.roseGarden ||
          Artwork.waitingRoom ||
          Artwork.staffRoom ||
          Artwork.courtyard ||
          Artwork.dressingRoom:
        break;
      // X beside the right bench / beside the left bench / under the tree /
      // at the old gate (see `_parkMap`).
      case Artwork.parkMapA:
        _parkMap(canvas, const Offset(89, 18));
      case Artwork.parkMapB:
        _parkMap(canvas, const Offset(31, 45));
      case Artwork.parkMapC:
        _parkMap(canvas, const Offset(34, 87));
      case Artwork.parkMapD:
        _parkMap(canvas, const Offset(43, 15));
    }
    canvas.restore();
  }

  bool get _isMap => const {Artwork.parkMapA, Artwork.parkMapB, Artwork.parkMapC, Artwork.parkMapD}.contains(artwork);

  Color get _groundColor => switch (artwork) {
    Artwork.hydePark || Artwork.londonEye => AppColors.park,
    Artwork.raven || Artwork.towerOfLondon => AppColors.park,
    Artwork.theatre => AppColors.burgundy,
    Artwork.towerBridge => AppColors.river,
    Artwork.royalBox => AppColors.parchmentDark,
    _ => const Color(0xFFD9CBA8),
  };

  void _kingsCross(Canvas c) {
    _box(c, 8, 44, 92, 86, _brick);
    // Two great arched train sheds.
    for (final left in [14.0, 54.0]) {
      final arch = Path()
        ..moveTo(left, 86)
        ..lineTo(left, 62)
        ..arcToPoint(Offset(left + 32, 62), radius: const Radius.circular(16))
        ..lineTo(left + 32, 86)
        ..close();
      c.drawPath(arch, _fill(_window));
      c.drawPath(arch, _ink);
      for (var i = 1; i < 4; i++) {
        c.drawLine(Offset(left + i * 8, 52), Offset(left + i * 8, 86), _ink..strokeWidth = 0.56);
      }
    }
    // Clock tower.
    _box(c, 43, 20, 57, 46, _brick);
    _poly(c, const [Offset(42, 20), Offset(50, 10), Offset(58, 20)], AppColors.navy);
    c.drawCircle(const Offset(50, 30), 5, _fill(_paper));
    c.drawCircle(const Offset(50, 30), 5, _ink);
    c.drawLine(const Offset(50, 30), const Offset(50, 26.5), _ink);
    c.drawLine(const Offset(50, 30), const Offset(52.5, 31), _ink);
  }

  void _suitcase(Canvas c) {
    // Platform sign "9" in the background.
    _box(c, 64, 12, 92, 30, AppColors.navy, radius: 2);
    _text(c, '9', const Offset(78, 21), 14, AppColors.goldLight);
    c.drawLine(const Offset(70, 30), const Offset(70, 40), _ink..strokeWidth = 1.12);
    c.drawLine(const Offset(86, 30), const Offset(86, 40), _ink);

    // Handle.
    final handle = Path()
      ..moveTo(40, 46)
      ..lineTo(40, 38)
      ..quadraticBezierTo(50, 32, 60, 38)
      ..lineTo(60, 46);
    c.drawPath(handle, _ink..strokeWidth = 2.24);
    c.drawPath(
      handle,
      Paint()
        ..color = _leatherDark
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );

    // Body + straps.
    _box(c, 14, 45, 86, 84, _leather, radius: 5);
    _box(c, 28, 45, 34, 84, _leatherDark, radius: 0.5);
    _box(c, 66, 45, 72, 84, _leatherDark, radius: 0.5);
    _box(c, 27, 60, 35, 66, AppColors.gold, radius: 1);
    _box(c, 65, 60, 73, 66, AppColors.gold, radius: 1);

    // Travel stickers.
    c.drawCircle(const Offset(48, 58), 6, _fill(AppColors.royalBlue));
    c.drawCircle(const Offset(48, 58), 6, _ink..strokeWidth = 0.84);
    _text(c, 'L', const Offset(48, 58), 7, _paper);
    _box(c, 44, 68, 60, 77, AppColors.goldLight, radius: 1.5);
    _text(c, 'LDN', const Offset(52, 72.5), 4.6, AppColors.navy);

    // A letter peeking out of the suitcase.
    c.save();
    c.translate(76, 44);
    c.rotate(0.25);
    _box(c, -8, -8, 10, 4, _paper, radius: 0.8);
    c.drawCircle(const Offset(1, -2), 2.6, _fill(AppColors.waxRed));
    c.restore();
  }

  void _museum(Canvas c) {
    _poly(c, const [Offset(12, 40), Offset(50, 20), Offset(88, 40)], _stone);
    _poly(c, const [Offset(24, 37), Offset(50, 25), Offset(76, 37)], _stoneShade);
    _box(c, 12, 40, 88, 47, _stone);
    for (var i = 0; i < 8; i++) {
      final x = 16 + i * 9.4;
      _box(c, x, 47, x + 5, 78, _stone, radius: 0.4);
      c.drawLine(Offset(x + 2.5, 50), Offset(x + 2.5, 75), _ink..strokeWidth = 0.35);
    }
    _box(c, 10, 78, 90, 82, _stoneShade);
    _box(c, 6, 82, 94, 86, _stone);
    // Banner.
    _box(c, 43, 55, 57, 70, AppColors.waxRed, radius: 0.5);
    _text(c, 'BM', const Offset(50, 62.5), 5.4, AppColors.goldLight);
  }

  void _bigBen(Canvas c) {
    _box(c, 40, 34, 60, 86, _stone);
    for (var y = 58.0; y < 84; y += 7) {
      _box(c, 44, y, 48, y + 4, _window, radius: 1);
      _box(c, 52, y, 56, y + 4, _window, radius: 1);
    }
    // Clock face.
    _box(c, 37, 34, 63, 56, AppColors.goldLight, radius: 1);
    c.drawCircle(const Offset(50, 45), 9.5, _fill(_paper));
    c.drawCircle(const Offset(50, 45), 9.5, _ink..strokeWidth = 0.98);
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      c.drawLine(
        Offset(50 + 7.6 * math.cos(a), 45 + 7.6 * math.sin(a)),
        Offset(50 + 8.8 * math.cos(a), 45 + 8.8 * math.sin(a)),
        _ink..strokeWidth = 0.49,
      );
    }
    c.drawLine(const Offset(50, 45), const Offset(50, 38.5), _ink..strokeWidth = 0.84);
    c.drawLine(const Offset(50, 45), const Offset(54.5, 45), _ink);
    // Belfry + spire.
    _box(c, 41, 24, 59, 34, _stone);
    for (var i = 0; i < 3; i++) {
      _box(c, 43.5 + i * 5, 26, 46.5 + i * 5, 32, AppColors.navy, radius: 1.5);
    }
    _poly(c, const [Offset(40, 24), Offset(50, 4), Offset(60, 24)], AppColors.navy);
    c.drawCircle(const Offset(50, 4), 1.6, _fill(AppColors.gold));
  }

  void _park(Canvas c) {
    c.drawCircle(const Offset(82, 16), 7, _fill(AppColors.goldLight));
    // Trees.
    for (final (x, y, r) in [(16.0, 48.0, 11.0), (86.0, 50.0, 9.0), (70.0, 44.0, 7.0)]) {
      _box(c, x - 1.6, y, x + 1.6, 72, _leather, radius: 0.5);
      c.drawCircle(Offset(x, y), r, _fill(AppColors.parkDeep));
      c.drawCircle(Offset(x, y), r, _ink);
    }
    // Lake.
    final lake = Rect.fromLTRB(8, 64, 92, 92);
    c.drawOval(lake, _fill(AppColors.river));
    c.drawOval(lake, _ink);
    // Two swans.
    for (final x in [38.0, 60.0]) {
      c.drawOval(Rect.fromCenter(center: Offset(x, 77), width: 12, height: 6), _fill(_paper));
      c.drawOval(Rect.fromCenter(center: Offset(x, 77), width: 12, height: 6), _ink..strokeWidth = 0.7);
      final neck = Path()
        ..moveTo(x + 4, 76)
        ..quadraticBezierTo(x + 7, 70, x + 4.5, 67.5);
      c.drawPath(neck, _ink..strokeWidth = 1.82);
      c.drawPath(
        neck,
        Paint()
          ..color = _paper
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.98,
      );
      c.drawCircle(Offset(x + 4.5, 67.5), 1.6, _fill(_paper));
      c.drawCircle(Offset(x + 3.0, 68.2), 0.9, _fill(AppColors.gold)); // beak
    }
  }

  void _palace(Canvas c) {
    _box(c, 6, 44, 94, 80, _stone);
    _box(c, 36, 36, 64, 44, _stone);
    _poly(c, const [Offset(34, 36), Offset(50, 28), Offset(66, 36)], _stoneShade);
    // Flag.
    c.drawLine(const Offset(50, 28), const Offset(50, 12), _ink..strokeWidth = 0.7);
    _box(c, 50, 12, 62, 19, AppColors.royalBlue, radius: 0.3);
    c.drawLine(
      const Offset(50, 12),
      const Offset(62, 19),
      Paint()
        ..color = _guardRed
        ..strokeWidth = 0.98,
    );
    c.drawLine(
      const Offset(50, 19),
      const Offset(62, 12),
      Paint()
        ..color = _guardRed
        ..strokeWidth = 0.98,
    );
    // Windows.
    for (var row = 0; row < 2; row++) {
      for (var i = 0; i < 9; i++) {
        final x = 10 + i * 9.2;
        _box(c, x, 48 + row * 11, x + 4, 55 + row * 11, _window, radius: 0.4);
      }
    }
    // Gate with gold tips.
    for (var x = 12.0; x <= 88; x += 4) {
      c.drawLine(Offset(x, 72), Offset(x, 86), _ink..strokeWidth = 0.7);
      c.drawCircle(Offset(x, 71.5), 0.9, _fill(AppColors.gold));
    }
    c.drawLine(const Offset(10, 76), const Offset(90, 76), _ink..strokeWidth = 0.7);
    // Two guards: red coats + tall black hats.
    for (final x in [28.0, 72.0]) {
      _box(c, x - 3.6, 71, x + 3.6, 82, _guardRed, radius: 1);
      _box(c, x - 3, 82, x - 0.4, 88, AppColors.navy, radius: 0.3);
      _box(c, x + 0.4, 82, x + 3, 88, AppColors.navy, radius: 0.3);
      c.drawCircle(Offset(x, 68.5), 2.6, _fill(const Color(0xFFF2C9A2)));
      final hat = RRect.fromLTRBR(x - 3.4, 58, x + 3.4, 67.5, const Radius.circular(3.4));
      c.drawRRect(hat, _fill(AppColors.charcoal));
    }
  }

  void _towerBridge(Canvas c) {
    // River shading.
    for (var y = 88.0; y < 100; y += 4) {
      c.drawLine(Offset(10, y), Offset(30, y), _ink..strokeWidth = 0.42);
      c.drawLine(Offset(60, y + 2), Offset(84, y + 2), _ink);
    }
    // Suspension cables.
    final cable = Paint()
      ..color = AppColors.royalBlue
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.12;
    c.drawPath(
      Path()
        ..moveTo(0, 60)
        ..quadraticBezierTo(14, 58, 22, 40),
      cable,
    );
    c.drawPath(
      Path()
        ..moveTo(100, 60)
        ..quadraticBezierTo(86, 58, 78, 40),
      cable,
    );
    // Road deck.
    _box(c, 0, 62, 100, 67, _stoneShade);
    // Towers.
    for (final l in [20.0, 64.0]) {
      _box(c, l, 30, l + 16, 88, _stone);
      _box(c, l + 5, 44, l + 11, 54, _window, radius: 3);
      _poly(c, [Offset(l - 1, 30), Offset(l + 8, 16), Offset(l + 17, 30)], AppColors.navy);
      c.drawCircle(Offset(l + 8, 16), 1.3, _fill(AppColors.gold));
    }
    // High walkways.
    _box(c, 36, 34, 64, 37.5, AppColors.royalBlue, radius: 0.3);
    _box(c, 36, 39.5, 64, 43, AppColors.royalBlue, radius: 0.3);
  }

  void _londonEye(Canvas c) {
    const center = Offset(50, 46);
    const r = 32.0;
    // Legs.
    c.drawLine(center, const Offset(34, 86), _ink..strokeWidth = 1.54);
    c.drawLine(center, const Offset(66, 86), _ink);
    // Spokes & rim.
    for (var i = 0; i < 16; i++) {
      final a = i * math.pi / 8;
      c.drawLine(center, center + Offset(r * math.cos(a), r * math.sin(a)), _ink..strokeWidth = 0.35);
    }
    c.drawCircle(
      center,
      r,
      Paint()
        ..color = AppColors.royalBlue
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    c.drawCircle(center, r - 3, _ink..strokeWidth = 0.56);
    for (var i = 0; i < 16; i++) {
      final a = i * math.pi / 8;
      final p = center + Offset((r + 2) * math.cos(a), (r + 2) * math.sin(a));
      c.drawOval(Rect.fromCenter(center: p, width: 4.6, height: 3.2), _fill(_paper));
      c.drawOval(Rect.fromCenter(center: p, width: 4.6, height: 3.2), _ink..strokeWidth = 0.49);
    }
    c.drawCircle(center, 3, _fill(AppColors.gold));
    c.drawCircle(center, 3, _ink..strokeWidth = 0.7);
  }

  void _royalBox(Canvas c) {
    _box(c, 18, 52, 82, 86, AppColors.gold, radius: 2);
    final lid = Path()
      ..moveTo(16, 54)
      ..lineTo(16, 44)
      ..quadraticBezierTo(50, 26, 84, 44)
      ..lineTo(84, 54)
      ..close();
    c.drawPath(lid, _fill(AppColors.goldDeep));
    _outline(c, lid);
    for (final x in [26.0, 74.0]) {
      _box(c, x - 2.5, 40, x + 2.5, 86, AppColors.goldLight, radius: 0.5);
    }
    _box(c, 44, 56, 56, 68, AppColors.navy, radius: 1.5);
    c.drawCircle(const Offset(50, 60.5), 1.8, _fill(AppColors.goldLight));
    c.drawLine(
      const Offset(50, 61),
      const Offset(50, 65),
      Paint()
        ..color = AppColors.goldLight
        ..strokeWidth = 0.98,
    );
    _crown(c, const Offset(50, 41), 8);
  }

  void _crown(Canvas c, Offset center, double w) {
    final h = w * 0.7;
    final path = Path()
      ..moveTo(center.dx - w, center.dy + h / 2)
      ..lineTo(center.dx - w, center.dy - h / 2)
      ..lineTo(center.dx - w / 2, center.dy)
      ..lineTo(center.dx, center.dy - h)
      ..lineTo(center.dx + w / 2, center.dy)
      ..lineTo(center.dx + w, center.dy - h / 2)
      ..lineTo(center.dx + w, center.dy + h / 2)
      ..close();
    c.drawPath(path, _fill(AppColors.goldLight));
    c.drawPath(path, _ink..strokeWidth = 0.7);
    c.drawCircle(Offset(center.dx, center.dy + h / 5), w / 6, _fill(AppColors.waxRed));
  }

  /// A small cog: a ring with square teeth.
  void _cog(Canvas c, Offset center, double r, Color color) {
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final tooth = Offset(center.dx + (r + 1.2) * math.cos(a), center.dy + (r + 1.2) * math.sin(a));
      c.drawCircle(tooth, 1.3, _fill(color));
    }
    c.drawCircle(center, r, _fill(color));
    c.drawCircle(center, r, _ink..strokeWidth = 0.7);
    c.drawCircle(center, r * 0.35, _fill(_paper));
    c.drawCircle(center, r * 0.35, _ink..strokeWidth = 0.5);
  }

  /// Ink raven in profile, facing right, standing at [feet].
  void _raven(Canvas c, Offset feet, double s) {
    Offset p(double x, double y) => Offset(feet.dx + x * s, feet.dy + y * s);
    final (tail, back, head, beak, throat, belly) = (p(-9, -4), p(-4, -12), p(3, -12), p(9, -13), p(5, -9), p(-3, -2));
    final chest = p(4, -3);
    final body = Path()
      ..moveTo(tail.dx, tail.dy)
      ..quadraticBezierTo(back.dx, back.dy, head.dx, head.dy)
      ..lineTo(beak.dx, beak.dy)
      ..lineTo(throat.dx, throat.dy)
      ..quadraticBezierTo(chest.dx, chest.dy, belly.dx, belly.dy)
      ..close();
    c.drawPath(body, _fill(AppColors.charcoal));
    _outline(c, body);
    final legs = _ink..strokeWidth = 0.7;
    c.drawLine(p(-2, -2), p(-2.5, 0), legs);
    c.drawLine(p(1, -2.5), p(1, 0), legs);
    c.drawCircle(p(3.6, -10.6), 0.55 * s, _fill(AppColors.goldLight));
  }

  // Case 02 — the great clock, stopped at 8:17.
  void _clockFace(Canvas c) {
    _box(c, 16, 10, 84, 80, AppColors.goldLight, radius: 1.5);
    _box(c, 20, 14, 80, 76, _stone, radius: 1);
    const center = Offset(50, 45);
    c.drawCircle(center, 26, _fill(_paper));
    c.drawCircle(center, 26, _ink..strokeWidth = 1.1);
    c.drawCircle(center, 22.5, _ink..strokeWidth = 0.4);
    for (var i = 0; i < 60; i++) {
      final a = i * math.pi / 30;
      final r1 = i % 5 == 0 ? 19.5 : 21.5;
      c.drawLine(
        Offset(center.dx + r1 * math.sin(a), center.dy - r1 * math.cos(a)),
        Offset(center.dx + 22.5 * math.sin(a), center.dy - 22.5 * math.cos(a)),
        _ink..strokeWidth = i % 5 == 0 ? 0.9 : 0.35,
      );
    }
    // Stopped: hour hand between 8 and 9, minute hand two marks past the 3.
    // Solved: the detective set it to 9:17, so the hands turn one hour on.
    final time = 8 + 17 / 60 + solved.clamp(0.0, 1.0);
    final hour = time * math.pi / 6;
    final minute = time * 2 * math.pi;
    c.drawLine(center, Offset(center.dx + 12 * math.sin(hour), center.dy - 12 * math.cos(hour)), _ink..strokeWidth = 2);
    c.drawLine(
      center,
      Offset(center.dx + 18 * math.sin(minute), center.dy - 18 * math.cos(minute)),
      _ink..strokeWidth = 1.2,
    );
    c.drawCircle(center, 1.8, _fill(AppColors.gold));
    // The works behind the face.
    _cog(c, const Offset(24, 84), 5, AppColors.gold);
    _cog(c, const Offset(38, 88), 3.5, AppColors.goldDeep);
    _cog(c, const Offset(76, 86), 4.5, AppColors.gold);
  }

  // Case 03 — Gallery 8: the empty frame, and three small clues.
  void _gallery(Canvas c) {
    _box(c, 0, 8, 100, 84, _stoneShade, radius: 0);
    // Side pictures.
    _box(c, 6, 30, 20, 48, AppColors.goldDeep, radius: 0.5);
    _box(c, 8, 32, 18, 46, AppColors.river, radius: 0.3);
    _box(c, 80, 30, 94, 48, AppColors.goldDeep, radius: 0.5);
    _box(c, 82, 32, 92, 46, AppColors.park, radius: 0.3);
    // The empty golden frame.
    _box(c, 30, 16, 70, 60, AppColors.gold, radius: 0.8);
    _box(c, 35, 21, 65, 55, _stone, radius: 0.3);
    _text(c, '17', const Offset(50, 64), 5, AppColors.inkBrown);
    // Blue cloth caught on the frame.
    _poly(c, const [Offset(64, 54), Offset(71, 57), Offset(69, 63), Offset(64, 60)], AppColors.royalBlue);
    // Bench, with the red button under it.
    _box(c, 32, 72, 68, 75, _leather, radius: 0.5);
    _box(c, 34, 75, 36, 83, _leatherDark, radius: 0.2);
    _box(c, 64, 75, 66, 83, _leatherDark, radius: 0.2);
    c.drawCircle(const Offset(50, 81), 1.6, _fill(AppColors.waxRed));
    // Door and the wet footprint.
    _box(c, 84, 56, 98, 84, _leatherDark, radius: 0.5);
    c.drawOval(Rect.fromCenter(center: const Offset(78, 88), width: 3.2, height: 5), _fill(AppColors.riverDeep));
    c.drawOval(Rect.fromCenter(center: const Offset(78, 92.5), width: 2.4, height: 2.6), _fill(AppColors.riverDeep));
  }

  // Case 04 / 05 — the Tower of London: a keep with four towers, thick walls.
  void _towerOfLondon(Canvas c) {
    // Outer wall with battlements.
    _box(c, 4, 64, 96, 86, _stone, radius: 0.3);
    for (var x = 4.0; x < 96; x += 7) {
      _box(c, x, 60, x + 3.5, 64, _stone, radius: 0.2);
    }
    _box(c, 44, 70, 56, 86, _leatherDark, radius: 5);
    // The White Tower and its four corner towers.
    _box(c, 26, 28, 74, 64, _paper, radius: 0.3);
    for (final x in [22.0, 70.0]) {
      _box(c, x, 22, x + 8, 64, _paper, radius: 0.3);
      final dome = Path()
        ..moveTo(x, 22)
        ..quadraticBezierTo(x + 4, 13, x + 8, 22)
        ..close();
      c.drawPath(dome, _fill(AppColors.navy));
      _outline(c, dome);
    }
    for (final x in [38.0, 54.0]) {
      _box(c, x, 22, x + 8, 28, _paper, radius: 0.3);
      final dome = Path()
        ..moveTo(x, 22)
        ..quadraticBezierTo(x + 4, 15, x + 8, 22)
        ..close();
      c.drawPath(dome, _fill(AppColors.navy));
      _outline(c, dome);
    }
    for (var row = 0; row < 2; row++) {
      for (final x in [34.0, 46.0, 58.0]) {
        _box(c, x, 36 + row * 13, x + 5, 44 + row * 13, _window, radius: 2.5);
      }
    }
    _raven(c, const Offset(14, 60), 0.7);
  }

  // Case 05 — the door with no keyhole: a dial and four brass gears.
  void _lockedDoor(Canvas c) {
    _box(c, 0, 8, 100, 84, _stone, radius: 0);
    for (var y = 16.0; y < 84; y += 10) {
      c.drawLine(Offset(0, y), Offset(100, y), _sketch..strokeWidth = 0.4);
    }
    final door = Path()
      ..moveTo(26, 84)
      ..lineTo(26, 34)
      ..arcToPoint(const Offset(74, 34), radius: const Radius.circular(24))
      ..lineTo(74, 84)
      ..close();
    c.drawPath(door, _fill(_leather));
    _outline(c, door);
    for (final x in [38.0, 50.0, 62.0]) {
      c.drawLine(Offset(x, 14), Offset(x, 84), _ink..strokeWidth = 0.4);
    }
    for (final y in [40.0, 72.0]) {
      _box(c, 26, y, 74, y + 3, AppColors.charcoal, radius: 0.2);
    }
    // The dial with arrows, and four gears around it.
    const dial = Offset(50, 56);
    for (final o in const [Offset(-13, -9), Offset(13, -9), Offset(-13, 9), Offset(13, 9)]) {
      _cog(c, dial + o, 3.6, AppColors.gold);
    }
    c.drawCircle(dial, 8.5, _fill(AppColors.goldLight));
    c.drawCircle(dial, 8.5, _ink..strokeWidth = 0.9);
    for (var i = 0; i < 12; i++) {
      final a = i * math.pi / 6;
      c.drawLine(
        dial + Offset(6.4 * math.cos(a), 6.4 * math.sin(a)),
        dial + Offset(7.8 * math.cos(a), 7.8 * math.sin(a)),
        _ink..strokeWidth = 0.4,
      );
    }
    c.drawLine(dial, dial + const Offset(0, -5.5), _ink..strokeWidth = 1.2);
    c.drawCircle(dial, 1.3, _fill(AppColors.goldDeep));
  }

  // Case 06 / 11 — Covent Garden: the market hall with its glass roof.
  void _coventGarden(Canvas c) {
    final roof = Path()
      ..moveTo(8, 42)
      ..quadraticBezierTo(50, 12, 92, 42)
      ..close();
    c.drawPath(roof, _fill(AppColors.river.withValues(alpha: 0.7)));
    _outline(c, roof);
    for (var i = 1; i < 8; i++) {
      final x = 8 + i * 10.5;
      c.drawLine(Offset(x, 42), Offset(50 + (x - 50) * 0.55, 24 + (x - 50).abs() * 0.25), _ink..strokeWidth = 0.35);
    }
    _box(c, 8, 42, 92, 48, _stone, radius: 0.3);
    for (var i = 0; i < 6; i++) {
      final x = 12 + i * 15.0;
      _box(c, x, 48, x + 4, 84, _stone, radius: 0.3);
    }
    for (var i = 0; i < 5; i++) {
      final x = 16 + i * 15.0;
      final arch = Path()
        ..moveTo(x, 84)
        ..lineTo(x, 58)
        ..arcToPoint(Offset(x + 11, 58), radius: const Radius.circular(5.5))
        ..lineTo(x + 11, 84);
      c.drawPath(arch, _fill(AppColors.navy.withValues(alpha: 0.18)));
      c.drawPath(arch, _ink..strokeWidth = 0.5);
    }
    // A street lamp.
    c.drawLine(const Offset(96, 86), const Offset(96, 58), _ink..strokeWidth = 1);
    _box(c, 93.5, 52, 98.5, 58, AppColors.goldLight, radius: 0.5);
  }

  // Case 11 — the theatre stage, a mask in the spotlight.
  void _theatre(Canvas c) {
    _box(c, 0, 8, 100, 84, AppColors.navyDeep, radius: 0);
    // Curtains.
    for (final left in [true, false]) {
      final x0 = left ? 0.0 : 100.0;
      final dir = left ? 1.0 : -1.0;
      final curtain = Path()
        ..moveTo(x0, 8)
        ..lineTo(x0 + dir * 30, 8)
        ..quadraticBezierTo(x0 + dir * 18, 46, x0 + dir * 24, 84)
        ..lineTo(x0, 84)
        ..close();
      c.drawPath(curtain, _fill(AppColors.burgundy));
      _outline(c, curtain);
      for (var i = 1; i < 4; i++) {
        c.drawLine(Offset(x0 + dir * i * 6, 10), Offset(x0 + dir * i * 5.5, 82), _sketch..strokeWidth = 0.6);
      }
    }
    _box(c, 0, 6, 100, 14, AppColors.burgundy, radius: 0);
    // Spotlight on the stage floor and the mask.
    c.drawOval(
      Rect.fromCenter(center: const Offset(50, 80), width: 34, height: 8),
      _fill(AppColors.goldLight.withValues(alpha: 0.5)),
    );
    final mask = Path()
      ..moveTo(36, 44)
      ..quadraticBezierTo(50, 38, 64, 44)
      ..quadraticBezierTo(63, 56, 56, 56)
      ..quadraticBezierTo(50, 51, 44, 56)
      ..quadraticBezierTo(37, 56, 36, 44)
      ..close();
    c.drawPath(mask, _fill(_paper));
    _outline(c, mask);
    c.drawOval(Rect.fromLTRB(40.5, 45.5, 47, 50), _fill(AppColors.navyDeep));
    c.drawOval(Rect.fromLTRB(53, 45.5, 59.5, 50), _fill(AppColors.navyDeep));
    c.drawLine(const Offset(64, 45), const Offset(70, 60), _ink..strokeWidth = 0.8);
  }

  // Case 10 — a raven on the Tower wall at dawn.
  void _ravenOnWall(Canvas c) {
    c.drawCircle(const Offset(80, 22), 8, _fill(AppColors.goldLight.withValues(alpha: 0.8)));
    // The Tower far behind.
    _box(c, 8, 34, 30, 68, _stoneShade, radius: 0.3);
    final dome = Path()
      ..moveTo(8, 34)
      ..quadraticBezierTo(19, 22, 30, 34)
      ..close();
    c.drawPath(dome, _fill(AppColors.navy.withValues(alpha: 0.7)));
    _outline(c, dome);
    // The wall.
    _box(c, 0, 66, 100, 86, _stone, radius: 0);
    for (var x = 0.0; x < 100; x += 9) {
      _box(c, x, 62, x + 5, 66, _stone, radius: 0.2);
    }
    for (var y = 72.0; y < 86; y += 6) {
      c.drawLine(Offset(0, y), Offset(100, y), _sketch..strokeWidth = 0.4);
    }
    _raven(c, const Offset(56, 62), 2.1);
    // The small paper in its beak.
    c.save();
    c.translate(76.5, 34);
    c.rotate(-0.3);
    _box(c, 0, 0, 9, 5, _paper, radius: 0.3);
    c.restore();
  }

  // Case 09 — the jewel case, empty but for a small card.
  void _jewelCase(Canvas c) {
    _box(c, 0, 8, 100, 84, _stoneShade, radius: 0);
    // Pedestal.
    _box(c, 36, 62, 64, 86, _stone, radius: 0.4);
    _box(c, 32, 58, 68, 62, _stone, radius: 0.4);
    // Glass case.
    _box(c, 30, 26, 70, 58, AppColors.river.withValues(alpha: 0.35), radius: 0.6);
    c.drawLine(const Offset(34, 30), const Offset(42, 38), _ink..strokeWidth = 0.4);
    c.drawLine(const Offset(36, 30), const Offset(46, 40), _ink..strokeWidth = 0.3);
    // Velvet cushion with an empty hollow, and a card.
    final cushion = RRect.fromLTRBR(38, 48, 62, 57, const Radius.circular(3));
    c.drawRRect(cushion, _fill(AppColors.burgundy));
    _outline(c, Path()..addRRect(cushion));
    c.drawOval(
      Rect.fromCenter(center: const Offset(50, 51), width: 8, height: 3.6),
      _fill(AppColors.navyDeep.withValues(alpha: 0.6)),
    );
    c.save();
    c.translate(55, 42);
    c.rotate(0.2);
    _box(c, 0, 0, 9, 6, _paper, radius: 0.3);
    c.restore();
    // Crown on top of the case.
    _crown(c, const Offset(50, 20), 5);
  }

  /// Case 07 — the same park path drawn as a map, with one spot marked X.
  void _parkMap(Canvas c, Offset x) {
    final grass = RRect.fromLTRBR(4, 4, 96, 96, const Radius.circular(3));
    c.drawRRect(grass, _fill(AppColors.park.withValues(alpha: 0.55)));
    _outline(c, Path()..addRRect(grass));
    // The stream, and the bridge over it.
    final stream = Path()
      ..moveTo(4, 56)
      ..quadraticBezierTo(30, 50, 50, 54)
      ..quadraticBezierTo(72, 58, 96, 52);
    c.drawPath(
      stream,
      Paint()
        ..color = AppColors.river
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );
    // Paths: from the gate at the bottom, past the tree, over the bridge,
    // then left to the old gate or right to the bench.
    final path = Paint()
      ..color = AppColors.parchmentDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final route = Path()
      ..moveTo(50, 96)
      ..lineTo(50, 46)
      ..moveTo(50, 46)
      ..lineTo(28, 32)
      ..lineTo(28, 20)
      ..moveTo(50, 46)
      ..lineTo(84, 30);
    c.drawPath(route, path);
    c.drawPath(route, _ink..strokeWidth = 0.4);
    _box(c, 43, 50, 57, 58, _stone, radius: 0.6);
    // The big tree beside the lower path.
    _box(c, 32, 70, 35, 80, _leather, radius: 0.3);
    c.drawCircle(const Offset(33.5, 68), 8, _fill(AppColors.parkDeep));
    c.drawCircle(const Offset(33.5, 68), 8, _ink);
    // Two benches: one on each side after the bridge.
    for (final b in const [Offset(38, 36), Offset(84, 25)]) {
      _box(c, b.dx - 5, b.dy - 1.5, b.dx + 5, b.dy + 1.5, _leatherDark, radius: 0.3);
    }
    // The old gate.
    _box(c, 22, 13, 24, 20, AppColors.charcoal, radius: 0.2);
    _box(c, 32, 13, 34, 20, AppColors.charcoal, radius: 0.2);
    c.drawLine(const Offset(23, 14), const Offset(33, 14), _ink..strokeWidth = 0.8);
    // X marks the spot.
    final mark = Paint()
      ..color = AppColors.waxRed
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    c.drawLine(x + const Offset(-4, -4), x + const Offset(4, 4), mark);
    c.drawLine(x + const Offset(4, -4), x + const Offset(-4, 4), mark);
  }

  void _text(Canvas c, String text, Offset center, double size, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: size,
          fontWeight: FontWeight.w700,
          fontVariations: const [FontVariation('wght', 700)],
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_LandmarkPainter old) => old.artwork != artwork || old.showSky != showSky || old.solved != solved;
}
