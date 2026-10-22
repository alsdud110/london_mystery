import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../data/models/letter_puzzles.dart' show FittedEnvelope, LetterPaper;
import '../../../data/models/opera_puzzles.dart' show AmendmentSlip, CueCard, OfficeRecord, PhotoPrint, ProgrammePage;
import '../../../data/models/river_puzzles.dart' show DrawnEvidence;
import '../../../data/models/scene_explore.dart' show ScenePixels;
import '../../../data/models/workshop_puzzles.dart';
import 'letter_papers.dart' show FittedEnvelopeView, LetterPaperView;
import 'opera_papers.dart';
import 'river_papers.dart' show PictureCanvas;

/// Case 05's papers and marks drawn with their words: the maker's mark and
/// its copies (cut from the one picture of the two clock hands), the cards
/// and slips written on, and a part of a picture shown alone. Every picture
/// is blank; what is written on it is written here, at the places measured
/// on it (`season2_case05_scenes.dart`).

/// The maker's mark as stamped: [copy] (the maker's own, or a copy of it),
/// drawn on its own square ([MakerMark.pixels]). [ink]: stamped in that
/// colour, its lines only (null: the brass hands as they are).
class MakerMarkView extends StatelessWidget {
  const MakerMarkView({super.key, required this.mark, required this.copy, this.ink});

  final MakerMark mark;
  final MarkCopy copy;
  final Color? ink;

  Widget _picture(String file) {
    final image = Image.asset(file, fit: BoxFit.fill, excludeFromSemantics: true);
    final ink = this.ink;
    return ink == null ? image : ColorFiltered(colorFilter: ColorFilter.mode(ink, BlendMode.srcIn), child: image);
  }

  @override
  Widget build(BuildContext context) {
    final size = Size(mark.pixels.width, mark.pixels.height);
    Widget hand({required bool long}) => ClipPath(clipper: _HandClipper(mark.split, long: long), child: _picture(mark.file));
    return PictureCanvas(
      pixels: mark.pixels,
      child: SizedBox.fromSize(
        size: size,
        child: switch (copy) {
          MarkCopy.exact => _picture(mark.file),
          MarkCopy.tip => Transform.translate(offset: mark.tipShift, child: _picture(mark.tipFile)),
          MarkCopy.oneHand => hand(long: true),
          MarkCopy.shifted => Stack(
            fit: StackFit.expand,
            children: [
              hand(long: true),
              Transform.translate(offset: mark.shift, child: hand(long: false)),
            ],
          ),
        },
      ),
    );
  }
}

/// One of the mark's two hands: above [split] (the long one) or below it.
class _HandClipper extends CustomClipper<Path> {
  const _HandClipper(this.split, {required this.long});

  final List<Offset> split;
  final bool long;

  @override
  Path getClip(Size size) {
    final path = Path()..moveTo(split.first.dx, split.first.dy);
    for (final p in split.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }
    final edge = long ? 0.0 : size.height;
    return path
      ..lineTo(size.width, split.last.dy)
      ..lineTo(size.width, edge)
      ..lineTo(0, edge)
      ..close();
  }

  @override
  bool shouldReclip(_HandClipper old) => old.long != long || old.split != split;
}

/// The colour of a note's ink.
Color inkOf(NoteInk ink) => switch (ink) {
  NoteInk.blue => AppColors.royalBlue,
  NoteInk.black => AppColors.charcoal,
  NoteInk.brown => AppColors.inkBrown,
};

/// Handwriting in ink, at [size] picture pixels.
TextStyle handwriting(double size, {Color color = AppColors.inkBrown}) =>
    AppText.style(AppText.italic, size: size, color: color, fontStyle: FontStyle.italic, height: 1.3);

/// A paper written on ([WrittenPaper]): its picture, its lines, and the
/// maker's mark or a short tag where it has them.
class WrittenPaperView extends StatelessWidget {
  const WrittenPaperView({super.key, required this.paper, this.textKey});

  final WrittenPaper paper;
  final Key? textKey;

  @override
  Widget build(BuildContext context) {
    final markAt = paper.markAt;
    final mark = paper.signedWith;
    final tagAt = paper.tagAt;
    return Semantics(
      image: true,
      label: '${paper.label}: ${[?paper.tag, ...paper.lines].join(' ')}',
      excludeSemantics: true,
      child: PictureCanvas(
        pixels: paper.pixels,
        child: Stack(
          children: [
            Positioned.fill(child: Image.asset(paper.file, fit: BoxFit.fill, excludeFromSemantics: true)),
            Positioned.fromRect(
              rect: paper.writeOn,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    paper.lines.join('\n'),
                    key: textKey,
                    textAlign: TextAlign.center,
                    style: AppText.style(AppText.body, size: paper.size, weight: FontWeight.w700, color: AppColors.walnutDeep, letterSpacing: paper.size * 0.03, height: 1.35),
                  ),
                ),
              ),
            ),
            if (paper.tag case final tag? when tagAt != null)
              Positioned.fromRect(
                rect: tagAt,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(tag, style: AppText.style(AppText.body, size: 72, weight: FontWeight.w800, color: AppColors.navyDeep, letterSpacing: 3)),
                  ),
                ),
              ),
            if (mark != null && markAt != null)
              Positioned.fromRect(rect: markAt, child: MakerMarkView(mark: mark, copy: MarkCopy.exact, ink: AppColors.walnutDeep)),
          ],
        ),
      ),
    );
  }
}

/// A part ([crop], fractions) of a picture at [pixels], filling its box; the
/// [child] is laid over the whole picture, at its pixels.
class CroppedPicture extends StatelessWidget {
  const CroppedPicture({super.key, required this.file, required this.pixels, required this.crop, this.child});

  final String file;
  final ScenePixels pixels;
  final Rect crop;
  final Widget? child;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: crop.width * pixels.width / (crop.height * pixels.height),
    child: LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth / crop.width;
        final h = box.maxHeight / crop.height;
        return ClipRect(
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: -crop.left * w,
                top: -crop.top * h,
                width: w,
                height: h,
                child: FittedBox(
                  fit: BoxFit.fill,
                  child: MediaQuery.withNoTextScaling(
                    child: SizedBox(
                      width: pixels.width,
                      height: pixels.height,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.asset(file, fit: BoxFit.fill, excludeFromSemantics: true),
                          ?child,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}

/// Case 05's, Case 06's and Case 07's evidence drawn (see `DrawnEvidenceArt`).
class DrawnEvidenceView extends StatelessWidget {
  const DrawnEvidenceView({super.key, required this.drawn});

  final DrawnEvidence drawn;

  @override
  Widget build(BuildContext context) => switch (drawn) {
    final WrittenPaper p => WrittenPaperView(paper: p),
    final PictureEvidence p => PictureCanvas(
      pixels: p.pixels,
      child: Image.asset(p.file, fit: BoxFit.fill, excludeFromSemantics: true),
    ),
    final FittedEnvelope e => FittedEnvelopeView(fitted: e),
    final LetterPaper l => LetterPaperView(paper: l),
    final OfficeRecord r => OfficeRecordView(record: r),
    final ProgrammePage p => ProgrammeView(page: p),
    final CueCard c => CueCardView(card: c),
    final AmendmentSlip s => AmendmentSlipView(slip: s),
    final PhotoPrint p => PhotoPrintView(photo: p),
    _ => const SizedBox.shrink(),
  };
}
