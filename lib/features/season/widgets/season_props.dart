import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../data/models/mission.dart';
import '../../../widgets/art_assets.dart';
import '../../../widgets/ink_icon.dart';
import '../../../widgets/landmark_art.dart';

/// Things lying on the detective's desk and board in the season pages: the
/// old London map, photo prints, push-pins and paper tags. Built from the
/// game's own pictures and ink, so they change with the story.

/// The game's London map as an old print: warm sepia on parchment.
/// [strength] is how much of the print shows through (0..1).
class MapPrint extends StatelessWidget {
  const MapPrint({super.key, this.strength = 0.6, this.alignment = Alignment.center});

  final double strength;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: ColoredBox(
        color: AppColors.parchment,
        child: LayoutBuilder(
          builder: (context, box) => Opacity(
            opacity: strength,
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(AppColors.inkBrown, BlendMode.color),
              child: Image.asset(
                ArtAssets.londonMap,
                fit: BoxFit.cover,
                alignment: alignment,
                width: double.infinity,
                height: double.infinity,
                cacheWidth: math.min(
                  (box.maxWidth * MediaQuery.devicePixelRatioOf(context)).ceil(),
                  ArtAssets.londonMapPixels.width.toInt(),
                ),
                excludeFromSemantics: true,
                errorBuilder: (context, error, stack) => const SizedBox.expand(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A photo print of a scene: white border, a shadow where it lifts off the
/// surface. Landmark prints show without their name plate (the print is
/// small; a tag says what it is).
class PhotoPrint extends StatelessWidget {
  const PhotoPrint(this.scene, {super.key, this.solved = 1, this.border = 3, this.bottom});

  final Artwork scene;
  final double solved;
  final double border;

  /// A wider bottom margin (a snapshot print), or [border].
  final double? bottom;

  @override
  Widget build(BuildContext context) {
    return PrintFrame(
      border: border,
      bottom: bottom,
      child: LandmarkArt(scene, borderRadius: 1, solved: solved, showName: !ArtAssets.landmarkScenes.containsKey(scene)),
    );
  }
}

/// The white border and shadow of a print, around any picture.
class PrintFrame extends StatelessWidget {
  const PrintFrame({super.key, required this.child, this.border = 3, this.bottom});

  final Widget child;
  final double border;
  final double? bottom;

  /// A print of a picture file (story objects and the like), filling the frame.
  factory PrintFrame.file(String file, {Key? key, double border = 3, double? bottom}) => PrintFrame(
        key: key,
        border: border,
        bottom: bottom,
        child: Builder(
          builder: (context) => Image.asset(
            file,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            excludeFromSemantics: true,
            errorBuilder: (context, error, stack) => const SizedBox.expand(),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(border, border, border, bottom ?? border),
      decoration: const BoxDecoration(
        color: AppColors.paperLight,
        boxShadow: [
          BoxShadow(color: Color(0x66000000), blurRadius: 6, offset: Offset(1.5, 3.5)),
          BoxShadow(color: Color(0x22000000), blurRadius: 1, offset: Offset(0, 0.5)),
        ],
      ),
      child: ClipRect(child: ColoredBox(color: AppColors.stone, child: child)),
    );
  }
}

/// A push-pin: a round head with a highlight where the lamp catches it.
class PushPin extends StatelessWidget {
  const PushPin({super.key, this.color = AppColors.burgundy, this.size = 10});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: const Alignment(-0.4, -0.45),
          radius: 0.9,
          colors: [Color.lerp(color, Colors.white, 0.45)!, color, Color.lerp(color, Colors.black, 0.35)!],
          stops: const [0, 0.45, 1],
        ),
        boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 2, offset: Offset(1, 2))],
      ),
    );
  }
}

/// A small paper tag with short upper-case writing ("05", "SECRET LETTERS").
class PaperTag extends StatelessWidget {
  const PaperTag(this.text, {super.key, this.size = 11, this.color = AppColors.inkBrown, this.glyph, this.paper = AppColors.paperLight});

  final String text;
  final double size;
  final Color color;
  final InkGlyph? glyph;
  final Color paper;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: size * 0.55, vertical: size * 0.28),
      decoration: BoxDecoration(
        color: paper,
        border: Border.all(color: AppColors.ink.withValues(alpha: 0.18), width: 0.8),
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 2, offset: Offset(0.5, 1.5))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (glyph != null) ...[
            InkIcon(glyph!, size: size * 1.6, color: color),
            SizedBox(width: size * 0.45),
          ],
          Text(text, style: AppText.eyebrow(color: color).copyWith(fontSize: size, letterSpacing: size * 0.13)),
        ],
      ),
    );
  }
}

/// The ink glyph named in season content (`'gem'`, `'mask'`…), or null.
InkGlyph? glyphNamed(String name) => InkGlyph.values.where((g) => g.name == name).firstOrNull;
