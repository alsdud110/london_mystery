import 'package:flutter/material.dart';

import '../../../data/models/abbesses_puzzles.dart';
import '../../../widgets/ink_icon.dart';
import 'letter_papers.dart' show postType;
import 'opera_papers.dart' show PixelCrop, pencil, typeInk;
import 'river_papers.dart' show PictureCanvas;

/// Case 08's papers and drawings drawn with what the app adds to them: P.'s
/// drawings (a margin study laid on the third), and the torn paper's words
/// and seal. Every picture is as delivered; what is laid on it is laid here,
/// at the places measured on it (`season2_case08_scenes.dart`).

/// A line of words written into [at] (picture pixels), shrunk to fit.
class _Fit extends StatelessWidget {
  const _Fit({required this.at, required this.child, this.alignment = Alignment.center});

  final Rect at;
  final Widget child;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => Positioned.fromRect(
    rect: at,
    child: IgnorePointer(
      child: FittedBox(fit: BoxFit.scaleDown, alignment: alignment, child: child),
    ),
  );
}

/// One of P.'s drawings at its own pixels, with its margin study laid in
/// pencil (only its lines: the study's own paper never shows as a second
/// sheet); [child] over it, at the drawing's pixels.
class MorningSketchCanvas extends StatelessWidget {
  const MorningSketchCanvas({super.key, required this.sketch, this.child});

  final MorningSketch sketch;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final study = sketch.study;
    return SizedBox(
      width: sketch.pixels.width,
      height: sketch.pixels.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(sketch.file, fit: BoxFit.fill, excludeFromSemantics: true),
          if (study != null)
            Positioned.fromRect(
              rect: study.at,
              child: ColorFiltered(
                colorFilter: pencil,
                child: Image.asset(study.file, key: const ValueKey('margin-study'), fit: BoxFit.fill, excludeFromSemantics: true),
              ),
            ),
          ?child,
        ],
      ),
    );
  }
}

/// One of P.'s drawings, whole, fitted to its box.
class MorningSketchView extends StatelessWidget {
  const MorningSketchView({super.key, required this.sketch, this.child});

  final MorningSketch sketch;
  final Widget? child;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: sketch.label,
    excludeSemantics: child == null,
    child: PictureCanvas(pixels: sketch.pixels, child: MorningSketchCanvas(sketch: sketch, child: child)),
  );
}

/// The torn paper at its own pixels: FILE up to the tear, the minutes and
/// an arrow after it, the seal; [child] over it, at the picture's pixels.
class TornFormCanvas extends StatelessWidget {
  const TornFormCanvas({super.key, required this.form, this.child});

  final TornForm form;
  final Widget? child;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: form.pixels.width,
    height: form.pixels.height,
    child: Stack(
      children: [
        Positioned.fill(child: Image.asset(form.file, fit: BoxFit.fill, excludeFromSemantics: true)),
        _Fit(
          at: form.fileAt,
          alignment: Alignment.centerRight,
          child: Text(form.fileWord, key: const ValueKey('torn-file'), style: postType(76, color: typeInk)),
        ),
        _Fit(
          at: form.minutesAt,
          alignment: Alignment.centerLeft,
          child: Text(form.minutes, key: const ValueKey('torn-minutes'), style: postType(118, color: typeInk)),
        ),
        Positioned.fromRect(
          rect: form.arrowAt,
          child: const IgnorePointer(child: FittedBox(child: InkIcon(InkGlyph.arrow, size: 100, color: typeInk))),
        ),
        Positioned.fromRect(
          rect: form.stampAt,
          child: IgnorePointer(
            child: Opacity(opacity: 0.85, child: Image.asset(form.stamp, key: const ValueKey('torn-stamp'), fit: BoxFit.contain, excludeFromSemantics: true)),
          ),
        ),
        ?child,
      ],
    ),
  );
}

/// The torn paper, its paper only, fitted to its box.
class TornFormView extends StatelessWidget {
  const TornFormView({super.key, required this.form, this.child});

  final TornForm form;
  final Widget? child;

  static const label =
      'A torn paper: a double border, a band with FILE in it, its number torn away; :00 and an arrow, the hour torn away; a round purple stamp, a clock with no hands in a ring of leaves.';

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: label,
    excludeSemantics: child == null,
    child: PixelCrop(pixels: form.pixels, crop: form.paper, child: TornFormCanvas(form: form, child: child)),
  );
}
