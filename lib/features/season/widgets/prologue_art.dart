import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/models/mission.dart';
import '../../../widgets/art_assets.dart';
import '../../../widgets/landmark_art.dart';
import '../../../widgets/london_skyline.dart';
import 'season_props.dart';

/// The pictures of the season's opening sequence, drawn from the game's own
/// art: London at night, the four kinds of trouble on the desk, and the map
/// they are pinned to — the same map as the investigation board.

/// The opening's first scene: the London night picture filling the screen
/// (Big Ben, Westminster, the Thames). [push] (0..1) moves the camera in a
/// little, towards Big Ben. Without the file, the London drawn in code.
class LondonNightHero extends StatelessWidget {
  const LondonNightHero({super.key, this.push = 1});

  final double push;

  /// Where the picture is held when the phone is narrower than the picture
  /// (9:16): Big Ben stands at the right, so the crop leans right and keeps
  /// it whole; a little of the gas lamp on the left goes instead.
  static const focus = Alignment(0.75, -0.2);

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, box) => Transform.scale(
          scale: 1 + 0.04 * push,
          // Into the city, towards the clock tower.
          alignment: const Alignment(0.7, -0.25),
          child: Image.asset(
            ArtAssets.season1LondonNight,
            fit: BoxFit.cover,
            alignment: focus,
            width: double.infinity,
            height: double.infinity,
            // Decoded at the width it covers (taller phones show it wider
            // than the screen), with room for the push; never above the file.
            cacheWidth: math.min(
              (math.max(box.maxWidth, box.maxHeight * ArtAssets.season1LondonNightPixels.aspectRatio) *
                      1.05 *
                      MediaQuery.devicePixelRatioOf(context))
                  .ceil(),
              ArtAssets.season1LondonNightPixels.width.toInt(),
            ),
            excludeFromSemantics: true,
            errorBuilder: (context, error, stack) => NightLondon(push: push),
          ),
        ),
      ),
    );
  }
}

/// London at night drawn in code (the fallback of [LondonNightHero]): sky,
/// the skyline with Big Ben in front, the Thames with the city's lights on it, fog, and gas lamps on
/// the embankment. [push] (0..1) moves the camera in a little.
class NightLondon extends StatelessWidget {
  const NightLondon({super.key, this.push = 1});

  final double push;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Transform.scale(
        scale: 1 + 0.035 * push,
        alignment: const Alignment(-0.2, 0.1),
        child: const RepaintBoundary(child: CustomPaint(painter: _NightLondonPainter(), child: SizedBox.expand())),
      ),
    );
  }
}

class _NightLondonPainter extends CustomPainter {
  const _NightLondonPainter();

  /// Where the embankment stands (fraction of the height).
  static const _base = 0.55;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final w = size.width, h = size.height;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.nightTop, AppColors.navy, AppColors.nightBottom],
          stops: [0, 0.45, 0.8],
        ).createShader(rect),
    );
    // The moon behind the clouds, high on the right.
    final moon = Rect.fromCircle(center: Offset(w * 0.8, h * 0.12), radius: w * 0.7);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [AppColors.goldLight.withValues(alpha: 0.16), AppColors.goldLight.withValues(alpha: 0)],
        ).createShader(moon),
    );
    final rnd = math.Random(3);
    for (var i = 0; i < 40; i++) {
      canvas.drawCircle(
        Offset(rnd.nextDouble() * w, rnd.nextDouble() * h * 0.35),
        0.3 + rnd.nextDouble() * 0.9,
        Paint()..color = AppColors.paperLight.withValues(alpha: 0.1 + rnd.nextDouble() * 0.3),
      );
    }

    // The skyline, large: Big Ben a little left of the middle.
    final base = h * _base;
    final sw = math.min(w * 1.7, h * 0.45 / 0.3);
    final sh = LondonSkylinePainter.heightFor(sw);
    final x0 = w * 0.4 - sw * 0.3875;
    // Mist rising off the river behind the buildings.
    final mist = Rect.fromLTWH(0, base - sh * 0.7, w, sh * 0.8);
    canvas.drawRect(
      mist,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.royalBlue.withValues(alpha: 0), AppColors.royalBlue.withValues(alpha: 0.3)],
        ).createShader(mist),
    );
    canvas.save();
    canvas.translate(x0, base - sh);
    const LondonSkylinePainter().paint(canvas, Size(sw, sh));
    canvas.restore();

    // The Thames.
    final river = Rect.fromLTWH(0, base, w, h * 0.16);
    canvas.drawRect(
      river,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.navyDeep, AppColors.nightBottom],
        ).createShader(river),
    );
    // The lights of the city on the water, broken by small waves.
    final light = Paint()..strokeCap = StrokeCap.round;
    for (final (x, bright) in const [
      (38.75, 0.55), (2.5, 0.3), (14.5, 0.3), (44, 0.35), (50, 0.3), (55.5, 0.35), (63, 0.3), (77.4, 0.3), (89.4, 0.3),
    ]) {
      final sx = x0 + sw * x / 100;
      if (sx < -10 || sx > w + 10) continue;
      for (var k = 0; k < 5; k++) {
        light
          ..strokeWidth = 1.6
          ..color = AppColors.goldLight.withValues(alpha: bright * (1 - k / 5.5));
        final y = base + 5 + k * h * 0.018;
        final half = 3 + k * 1.5 + (k.isOdd ? 2 : 0);
        canvas.drawLine(Offset(sx - half + (k.isEven ? 1.5 : -1.5), y), Offset(sx + half, y), light);
      }
    }
    // The embankment wall.
    canvas.drawRect(Rect.fromLTWH(0, base - 1, w, 2.5), Paint()..color = AppColors.nightSkyline);

    // Fog drifting low over the water.
    for (final (y, alpha) in [(base + h * 0.03, 0.08), (base + h * 0.1, 0.06)]) {
      final band = Rect.fromLTWH(0, y - h * 0.04, w, h * 0.08);
      canvas.drawRect(
        band,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.paperLight.withValues(alpha: 0),
              AppColors.paperLight.withValues(alpha: alpha),
              AppColors.paperLight.withValues(alpha: 0),
            ],
          ).createShader(band),
      );
    }

    // Gas lamps on the embankment: one near, one further along.
    _lamp(canvas, Offset(w * 0.1, base + h * 0.13), h * 0.36, w);
    _lamp(canvas, Offset(w * 0.86, base + h * 0.04), h * 0.2, w);

    // Into the dark where the words are.
    final fade = Rect.fromLTWH(0, base + h * 0.06, w, h - base);
    canvas.drawRect(
      fade,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0x000E1424), AppColors.nightBottom],
          stops: [0, 0.45],
        ).createShader(fade),
    );
  }

  void _lamp(Canvas canvas, Offset foot, double height, double w) {
    final top = foot.translate(0, -height);
    final glow = Rect.fromCircle(center: top, radius: height * 0.45);
    canvas.drawRect(
      glow,
      Paint()
        ..shader = RadialGradient(
          colors: [AppColors.goldLight.withValues(alpha: 0.38), AppColors.goldLight.withValues(alpha: 0)],
        ).createShader(glow),
    );
    final post = Paint()..color = AppColors.nightSkyline;
    final s = height / 100;
    canvas.drawRect(Rect.fromLTWH(foot.dx - 1.6 * s, top.dy + 8 * s, 3.2 * s, height - 8 * s), post);
    canvas.drawRect(Rect.fromLTWH(foot.dx - 4 * s, foot.dy - 6 * s, 8 * s, 6 * s), post);
    // The lantern: a little glass box, lit.
    final lantern = Path()
      ..moveTo(top.dx - 5 * s, top.dy)
      ..lineTo(top.dx + 5 * s, top.dy)
      ..lineTo(top.dx + 3.5 * s, top.dy + 9 * s)
      ..lineTo(top.dx - 3.5 * s, top.dy + 9 * s)
      ..close();
    canvas.drawPath(lantern, Paint()..color = AppColors.goldLight.withValues(alpha: 0.9));
    canvas.drawPath(
      Path()
        ..moveTo(top.dx - 6 * s, top.dy)
        ..lineTo(top.dx, top.dy - 5 * s)
        ..lineTo(top.dx + 6 * s, top.dy)
        ..close(),
      post,
    );
  }

  @override
  bool shouldRepaint(_NightLondonPainter old) => false;
}

/// The four kinds of trouble, as pieces of evidence: what is missing, a
/// sealed letter, a locked door, a stranger in the fog. Mood only: none of
/// them is a case's answer.
enum TroublePiece { treasure, letter, door, stranger }

/// A print of one [TroublePiece].
class TroublePrint extends StatelessWidget {
  const TroublePrint(this.piece, {super.key, this.border = 4});

  final TroublePiece piece;
  final double border;

  @override
  Widget build(BuildContext context) {
    return switch (piece) {
      TroublePiece.treasure => PrintFrame.file(ArtAssets.objects['crown']!, border: border),
      TroublePiece.letter => PrintFrame.file(ArtAssets.objects['letter']!, border: border),
      TroublePiece.door => PrintFrame(
          border: border,
          child: const _Cutout(ArtAssets.lockedDoor, fallback: LandmarkArt(Artwork.lockedDoor, borderRadius: 0)),
        ),
      TroublePiece.stranger => PrintFrame(
          border: border,
          child: const _Cutout(
            ArtAssets.mysteriousStranger,
            fallback: CustomPaint(painter: _StrangerPainter(), child: SizedBox.expand()),
          ),
        ),
    };
  }
}

/// A picture cut out on transparency, laid on the same parchment as the
/// crown and letter prints. A missing file shows [fallback] instead.
class _Cutout extends StatelessWidget {
  const _Cutout(this.file, {required this.fallback});

  final String file;
  final Widget fallback;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.parchment,
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xs),
        child: Image.asset(
          file,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
          excludeFromSemantics: true,
          errorBuilder: (context, error, stack) => fallback,
        ),
      ),
    );
  }
}

/// A figure in a top hat and long coat under a street lamp, in the fog.
/// LEGACY FALLBACK: shown only when the stranger picture cannot be loaded.
class _StrangerPainter extends CustomPainter {
  const _StrangerPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final w = size.width, h = size.height;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.navy, AppColors.nightBottom],
        ).createShader(rect),
    );
    final lamp = Offset(w * 0.78, h * 0.22);
    final glow = Rect.fromCircle(center: lamp, radius: w * 0.6);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [AppColors.goldLight.withValues(alpha: 0.45), AppColors.goldLight.withValues(alpha: 0)],
        ).createShader(glow),
    );
    final dark = Paint()..color = AppColors.nightSkyline;
    canvas.drawRect(Rect.fromLTWH(lamp.dx - 1.5, lamp.dy, 3, h), dark);
    canvas.drawCircle(lamp, w * 0.035, Paint()..color = AppColors.goldLight);
    // The street, wet, and the stranger's long shadow on it.
    canvas.drawRect(Rect.fromLTWH(0, h * 0.8, w, h * 0.2), Paint()..color = AppColors.navyDeep);
    canvas.drawOval(Rect.fromLTWH(w * 0.12, h * 0.8, w * 0.42, h * 0.05), Paint()..color = Colors.black.withValues(alpha: 0.5));
    // The figure: hat, head, coat.
    final cx = w * 0.38;
    final figure = Path()
      ..addRect(Rect.fromLTWH(cx - w * 0.06, h * 0.2, w * 0.12, h * 0.12)) // hat
      ..addRect(Rect.fromLTWH(cx - w * 0.11, h * 0.31, w * 0.22, h * 0.025)) // brim
      ..addOval(Rect.fromCircle(center: Offset(cx, h * 0.37), radius: w * 0.06)) // head
      ..moveTo(cx - w * 0.1, h * 0.42)
      ..lineTo(cx + w * 0.1, h * 0.42)
      ..lineTo(cx + w * 0.17, h * 0.79)
      ..lineTo(cx - w * 0.17, h * 0.79)
      ..close();
    canvas.drawPath(figure, dark);
    // Fog across the street.
    final fog = Rect.fromLTWH(0, h * 0.55, w, h * 0.35);
    canvas.drawRect(
      fog,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.paperLight.withValues(alpha: 0),
            AppColors.paperLight.withValues(alpha: 0.16),
            AppColors.paperLight.withValues(alpha: 0.04),
          ],
        ).createShader(fog),
    );
  }

  @override
  bool shouldRepaint(_StrangerPainter old) => false;
}

/// The London map in its walnut frame — the investigation board before
/// anything is solved — with the four pieces of trouble pinned far apart.
/// [pinned] (0..1) brings the pieces in one by one; [threads] (0..2) draws
/// the first red thread, then the second; [push] moves the camera in.
class TroubleMap extends StatelessWidget {
  const TroubleMap({super.key, this.pinned = 1, this.threads = 0, this.push = 0});

  final double pinned;
  final double threads;
  final double push;

  /// Where each piece is pinned (fractions of the map): far apart.
  static const spots = [Offset(0.25, 0.22), Offset(0.76, 0.3), Offset(0.27, 0.74), Offset(0.74, 0.76)];
  static const tilts = [-0.08, 0.07, 0.05, -0.06];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AppColors.walnutDeep,
        borderRadius: BorderRadius.circular(AppRadius.paper),
        border: Border.all(color: AppColors.goldLight.withValues(alpha: 0.18), width: AppLine.hairline),
        boxShadow: AppShadow.onNight,
      ),
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, box) {
            final size = box.biggest;
            final piece = (math.min(size.width, size.height) * 0.3).clamp(64.0, 130.0);
            Offset at(int i) => Offset(spots[i].dx * size.width, spots[i].dy * size.height);
            return Transform.scale(
              scale: 1 + 0.05 * push,
              child: Stack(
                children: [
                  const Positioned.fill(child: MapPrint(strength: 0.62)),
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(radius: 0.85, colors: [Colors.transparent, Color(0x661B130D)], stops: [0.55, 1]),
                      ),
                    ),
                  ),
                  // The crown to the stranger, the letter to the door: two
                  // threads crossing in the middle.
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _ThreadsPainter([
                        (at(0).translate(0, -piece / 2 + 4), at(3).translate(0, -piece / 2 + 4), threads.clamp(0.0, 1.0)),
                        (at(1).translate(0, -piece / 2 + 4), at(2).translate(0, -piece / 2 + 4), (threads - 1).clamp(0.0, 1.0)),
                      ]),
                    ),
                  ),
                  for (final (i, p) in TroublePiece.values.indexed)
                    () {
                      final shown = ((pinned * 4) - i).clamp(0.0, 1.0);
                      return Positioned(
                        left: at(i).dx - piece / 2,
                        top: at(i).dy - piece / 2,
                        width: piece,
                        height: piece * 0.9,
                        child: Opacity(
                          opacity: shown,
                          child: Transform.translate(
                            offset: Offset(0, -10 * (1 - shown)),
                            child: Transform.rotate(
                              angle: tilts[i],
                              child: Stack(
                                clipBehavior: Clip.none,
                                alignment: Alignment.topCenter,
                                children: [
                                  Positioned.fill(child: TroublePrint(p, border: 3)),
                                  const Positioned(top: -4, child: PushPin(size: 11)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Red thread from pin to pin, drawn as far as its progress, with a faint
/// shadow (the board's thread).
class _ThreadsPainter extends CustomPainter {
  _ThreadsPainter(this.threads);

  final List<(Offset, Offset, double)> threads;

  @override
  void paint(Canvas canvas, Size size) {
    for (final (a, b, drawn) in threads) {
      if (drawn <= 0) continue;
      final mid = Offset.lerp(a, b, 0.5)!.translate(0, (b - a).distance * 0.06);
      final path = Path()
        ..moveTo(a.dx, a.dy)
        ..quadraticBezierTo(mid.dx, mid.dy, b.dx, b.dy);
      for (final m in path.computeMetrics()) {
        final part = m.extractPath(0, m.length * drawn);
        canvas.drawPath(
          part.shift(const Offset(1, 2)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8
            ..color = Colors.black.withValues(alpha: 0.22),
        );
        canvas.drawPath(
          part,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = 1.8
            ..color = AppColors.burgundy.withValues(alpha: 0.9),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ThreadsPainter old) => true;
}
