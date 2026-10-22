import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../data/models/letter_puzzles.dart';
import '../../../data/models/scene_explore.dart' show ScenePixels;
import 'river_papers.dart' show PictureCanvas;
import 'workshop_papers.dart' show handwriting;

/// Case 06's papers drawn with their words: a hold tag's front and back,
/// the torn envelope with its corner and seal, and the letter with its
/// drawing. Every picture is blank; what is written on it is written here,
/// at the places measured on it (`season2_case06_scenes.dart`).

/// Typed on a post office paper, at [size] picture pixels.
TextStyle postType(double size, {Color color = AppColors.walnutDeep, FontWeight weight = FontWeight.w800}) =>
    AppText.style(AppText.body, size: size, weight: weight, color: color, letterSpacing: size * 0.04, height: 1.25);

/// A hold tag up close, its front or its back ([back]: the same paper
/// turned over, so its picture is mirrored): the front says what it is for
/// and its number (a digit under ink where the ink hides one), the back
/// when it was held, and why.
class HoldTagView extends StatelessWidget {
  const HoldTagView({super.key, required this.scene, required this.tag, required this.back});

  final HoldRackScene scene;
  final HoldTag tag;
  final bool back;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(scene.tagFile, fit: BoxFit.fill, excludeFromSemantics: true);
    return Semantics(
      image: true,
      label: '${tag.name}, its ${back ? 'back' : 'front'}: ${(back ? tag.back : [tag.kind.word, 'No. ${tag.inked ? tag.number.replaceAll('?', ' (a digit hidden by ink) ') : tag.number}']).join('. ')}',
      excludeSemantics: true,
      child: PictureCanvas(
        pixels: scene.tagPixels,
        child: Stack(
          children: [
            Positioned.fill(child: back ? Transform.flip(flipX: true, child: image) : image),
            Positioned.fromRect(
              rect: scene.writeOn,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: SizedBox(
                  width: scene.writeOn.width,
                  child: back ? _TagBack(tag: tag) : _TagFront(tag: tag, ink: scene.ink),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TagFront extends StatelessWidget {
  const _TagFront({required this.tag, required this.ink});

  final HoldTag tag;
  final String ink;

  @override
  Widget build(BuildContext context) {
    const size = 116.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 40),
        Text(tag.kind.word, key: ValueKey('tag-kind-${tag.id}'), style: postType(100, color: AppColors.navyDeep)),
        const SizedBox(height: 70),
        Text('No.', style: postType(70, weight: FontWeight.w700)),
        const SizedBox(height: 10),
        // The number, a digit at a time: one under ink is hidden.
        Row(
          key: ValueKey('tag-number-${tag.id}'),
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final d in tag.number.split(''))
              SizedBox(
                width: size * 0.68,
                height: size * 1.3,
                child: d == '?'
                    ? OverflowBox(
                        maxWidth: size * 1.7,
                        maxHeight: size * 1.7,
                        child: Image.asset(ink, key: ValueKey('tag-ink-${tag.id}'), width: size * 1.7, height: size * 1.7, fit: BoxFit.contain, excludeFromSemantics: true),
                      )
                    : Center(child: Text(d, style: postType(size))),
              ),
          ],
        ),
      ],
    );
  }
}

class _TagBack extends StatelessWidget {
  const _TagBack({required this.tag});

  final HoldTag tag;

  @override
  Widget build(BuildContext context) {
    final [order, ...rest] = tag.reason.isEmpty ? [''] : tag.reason;
    return Column(
      key: ValueKey('tag-back-${tag.id}'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 30),
        Text('${tag.date}\n${tag.time}', textAlign: TextAlign.center, style: postType(68, weight: FontWeight.w700)),
        const SizedBox(height: 36),
        Text(tag.record, style: postType(92, color: AppColors.navyDeep)),
        const SizedBox(height: 40),
        if (order.isNotEmpty) Text(order, textAlign: TextAlign.center, style: postType(rest.isEmpty ? 58 : 50, color: AppColors.burgundy)),
        if (rest.isNotEmpty) ...[
          const SizedBox(height: 22),
          for (final line in rest) Text(line, textAlign: TextAlign.center, style: handwriting(54, color: AppColors.inkBrown)),
        ],
      ],
    );
  }
}

/// The corner from Clock III alone, its number on its sticker, on the
/// envelopes' canvas (laid at its origin it sits where it was torn from).
class CornerView extends StatelessWidget {
  const CornerView({super.key, required this.scene});

  final ArchiveScene scene;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: scene.envelopePixels.width,
    height: scene.envelopePixels.height,
    child: Stack(
      children: [
        Positioned.fill(child: Image.asset(scene.corner, fit: BoxFit.fill, excludeFromSemantics: true)),
        Positioned.fromRect(rect: scene.cornerTagAt, child: _Sticker(text: scene.drawers.cornerLabel)),
      ],
    ),
  );
}

class _Sticker extends StatelessWidget {
  const _Sticker({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: FittedBox(fit: BoxFit.scaleDown, child: Text(text, style: postType(96, color: AppColors.navyDeep))),
  );
}

/// The torn envelope with its corner back on it and its seal
/// ([FittedEnvelope]).
class FittedEnvelopeView extends StatelessWidget {
  const FittedEnvelopeView({super.key, required this.fitted, this.seal = true});

  final FittedEnvelope fitted;

  /// The seal on its spot (it is pressed on once the envelope is found).
  final bool seal;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: 'A torn envelope, its corner fitted back on it: ${fitted.tag}${seal ? '. A red wax seal on it' : ''}',
    excludeSemantics: true,
    child: PictureCanvas(
      pixels: fitted.pixels,
      child: Stack(
        children: [
          Positioned.fill(child: Image.asset(fitted.envelope, fit: BoxFit.fill, excludeFromSemantics: true)),
          Positioned.fill(child: Image.asset(fitted.corner, fit: BoxFit.fill, excludeFromSemantics: true)),
          Positioned.fromRect(rect: fitted.tagAt, child: _Sticker(text: fitted.tag)),
          if (seal) Positioned.fromRect(rect: fitted.sealAt, child: Image.asset(fitted.seal, key: const ValueKey('envelope-seal'), fit: BoxFit.contain, excludeFromSemantics: true)),
        ],
      ),
    ),
  );
}

/// The letter ([LetterPaper]): its two lines and its drawing; or its back,
/// the same paper turned over, with what is written there.
class LetterPaperView extends StatelessWidget {
  const LetterPaperView({super.key, required this.paper, this.back, this.onDrawing});

  final LetterPaper paper;

  /// Its back shown (null: as [LetterPaper.showBack] says).
  final bool? back;

  /// A tap on the drawing (to look at it closer), if it can be tapped.
  final VoidCallback? onDrawing;

  @override
  Widget build(BuildContext context) {
    final back = this.back ?? paper.showBack;
    final image = Image.asset(paper.file, fit: BoxFit.fill, excludeFromSemantics: true);
    return Semantics(
      image: true,
      label: back ? 'The back of the letter: ${paper.back.join(' · ')}' : 'A letter: ${paper.lines.join(' ')} Under the lines, a drawing of a grand building.',
      excludeSemantics: true,
      child: PictureCanvas(
        pixels: paper.pixels,
        child: Stack(
          children: [
            Positioned.fill(child: back ? Transform.flip(flipX: true, child: image) : image),
            if (back)
              Positioned.fromRect(
                rect: paper.backOn,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Column(
                      key: const ValueKey('letter-back'),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(paper.back.first, style: postType(104, color: AppColors.navyDeep)),
                        const SizedBox(height: 30),
                        for (final line in paper.back.skip(1)) Text(line, style: postType(132, color: AppColors.burgundy)),
                      ],
                    ),
                  ),
                ),
              )
            else ...[
              Positioned.fromRect(
                rect: paper.writeOn,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(paper.lines.join('\n'), key: const ValueKey('letter-lines'), textAlign: TextAlign.center, style: handwriting(84)),
                  ),
                ),
              ),
              Positioned.fromRect(
                rect: paper.sketchAt,
                child: GestureDetector(
                  key: const ValueKey('letter-drawing'),
                  behavior: HitTestBehavior.opaque,
                  onTap: onDrawing,
                  child: Image.asset(paper.sketch, fit: BoxFit.contain, excludeFromSemantics: true),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// A part ([crop], fractions) of a picture at [pixels], filling its box at
/// the part's own proportions.
class PicturePart extends StatelessWidget {
  const PicturePart({super.key, required this.file, required this.pixels, required this.crop});

  final String file;
  final ScenePixels pixels;
  final Rect crop;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: crop.width * pixels.width / (crop.height * pixels.height),
    child: LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth / crop.width;
        final h = box.maxHeight / crop.height;
        final dpr = MediaQuery.devicePixelRatioOf(context);
        return ClipRect(
          child: Stack(
            children: [
              Positioned(
                left: -crop.left * w,
                top: -crop.top * h,
                width: w,
                height: h,
                child: Image.asset(file, fit: BoxFit.fill, excludeFromSemantics: true, cacheWidth: math.min(pixels.width, w * dpr).ceil()),
              ),
            ],
          ),
        );
      },
    ),
  );
}
