import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../data/models/opera_puzzles.dart';
import '../../../data/models/scene_explore.dart' show ScenePixels;
import '../../../widgets/ink_icon.dart';
import 'letter_papers.dart' show postType;
import 'river_papers.dart' show PictureCanvas;
import 'workshop_papers.dart' show handwriting;

/// Case 07's papers drawn with their words: FILE 3 (its patch, and the old
/// photo mounted on it), FILE 4, the stage cue card, the Amendment Slip and
/// its back. Every picture is blank; what is written on it is written here,
/// at the places measured on it (`season2_case07_scenes.dart`).

/// An old photograph's brown tint (its stage picture is in colour).
const sepia = ColorFilter.matrix([
  0.393, 0.769, 0.189, 0, -18, //
  0.349, 0.686, 0.168, 0, -22,
  0.272, 0.534, 0.131, 0, -30,
  0, 0, 0, 1, 0,
]);

/// A pencil drawing on transparency laid on paper: its dark lines kept, in
/// graphite; its light fills let the paper show (a white sketch never sits
/// on a grey slip as a pasted card).
const pencil = ColorFilter.matrix([
  0, 0, 0, 0, 58, //
  0, 0, 0, 0, 55,
  0, 0, 0, 0, 52,
  -0.43, -0.43, -0.43, 1.3, 0,
]);

/// Paper on a lit light table: the light comes through it.
const _backlit = ColorFilter.matrix([
  1, 0, 0, 0, 34, //
  0, 1, 0, 0, 30,
  0, 0, 1, 0, 18,
  0, 0, 0, 1, 0,
]);

/// Two papers glued together let less of it through.
const _thicker = ColorFilter.matrix([
  0.78, 0, 0, 0, 0, //
  0, 0.74, 0, 0, 0,
  0, 0, 0.68, 0, 0,
  0, 0, 0, 1, 0,
]);

/// Type on old paper: dark ink, a little soaked in (never a screen's flat
/// black).
const typeInk = Color(0xE02A211B);
const typeBlue = Color(0xE01F2740);

/// Pen ink: a written line on a paper ([handwriting] in it), a little
/// lighter where the pen ran dry.
const penInk = Color(0xD9403020);

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

Widget _picture(String file, {ColorFilter? filter}) {
  final image = Image.asset(file, fit: BoxFit.fill, excludeFromSemantics: true);
  return filter == null ? image : ColorFiltered(colorFilter: filter, child: image);
}

/// [rect] (pixels of a picture [from] big) in a picture drawn at [to].
Rect scaled(Rect rect, ScenePixels from, Size to) =>
    Rect.fromLTRB(rect.left * to.width / from.width, rect.top * to.height / from.height, rect.right * to.width / from.width, rect.bottom * to.height / from.height);

/// The part [crop] (pixels of a picture [pixels] big) of [child], which is
/// laid out at the picture's own pixels: it fills its box at the part's
/// proportions, and taps on [child] are in the picture's pixels wherever it
/// is shown.
class PixelCrop extends StatelessWidget {
  const PixelCrop({super.key, required this.pixels, required this.crop, required this.child});

  final ScenePixels pixels;
  final Rect crop;
  final Widget child;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: crop.width / crop.height,
    child: LayoutBuilder(
      builder: (context, box) {
        final k = box.maxWidth / crop.width;
        return ClipRect(
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned(
                left: -crop.left * k,
                top: -crop.top * k,
                width: pixels.width * k,
                height: pixels.height * k,
                child: FittedBox(
                  fit: BoxFit.fill,
                  child: MediaQuery.withNoTextScaling(
                    child: SizedBox(width: pixels.width, height: pixels.height, child: child),
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

// ── The old photo ────────────────────────────────────────────────────────

/// The old photo in its mount: the stage, brown with age, and what is
/// written under it.
class PhotoPrintView extends StatelessWidget {
  const PhotoPrintView({super.key, required this.photo});

  final PhotoPrint photo;

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: 'An old photo of the stage: one small lamp glowing in the middle; the seats and the front of the stage dark. Written under it: ${photo.caption}',
    excludeSemantics: true,
    child: PictureCanvas(
      pixels: photo.pixels,
      child: Stack(
        children: [
          // The stage fills the window (its middle band: the mount is
          // wider than the stage).
          Positioned.fromRect(
            rect: photo.window.inflate(6),
            child: ColorFiltered(
              colorFilter: sepia,
              child: Image.asset(photo.stage, fit: BoxFit.cover, excludeFromSemantics: true),
            ),
          ),
          Positioned.fill(child: _picture(photo.file)),
          _Fit(
            at: photo.captionAt,
            child: Text(photo.caption, key: const ValueKey('photo-caption'), style: handwriting(120, color: AppColors.inkBrown)),
          ),
        ],
      ),
    ),
  );
}

// ── FILE 3 ───────────────────────────────────────────────────────────────

/// FILE 3, the office record: its heading, its three lines, the patch over
/// CURTAIN UP's time, and the old photo mounted below. On the lit light
/// table ([lit], 0 to 1: the light coming up) the paper glows, the patch's
/// edge shows, and the old time under it shows through.
class OfficeRecordView extends StatelessWidget {
  const OfficeRecordView({super.key, required this.record, this.lit, this.photo = true, this.semantics = true});

  final OfficeRecord record;

  /// How far the light under it is up (null: as [OfficeRecord.light] says).
  final double? lit;
  final bool photo;
  final bool semantics;

  /// The record laid out at its own pixels (for [PixelCrop]).
  static Widget canvas(OfficeRecord record, {double? lit, bool photo = true, List<Widget> over = const []}) =>
      SizedBox(width: record.pixels.width, height: record.pixels.height, child: Stack(children: [..._layers(record, lit ?? (record.light == RecordLight.lit ? 1 : 0), photo), ...over]));

  static List<Widget> _layers(OfficeRecord r, double lit, bool photo) {
    final patch = r.patch;
    final word = postType(46, color: typeInk);
    final time = postType(58, color: typeBlue);
    return [
      Positioned.fill(child: _picture(r.file)),
      if (lit > 0) Positioned.fill(child: Opacity(opacity: lit, child: _picture(r.file, filter: _backlit))),
      _Fit(
        at: r.fileAt,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('FILE', style: postType(26, color: typeInk)),
            Text(r.fileLabel.replaceFirst('FILE ', ''), key: const ValueKey('record-file'), style: postType(76, color: typeBlue)),
          ],
        ),
      ),
      _Fit(
        at: r.titleAt,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(r.title.first, style: AppText.style(AppText.display, size: 64, color: typeInk, letterSpacing: 2)),
            const SizedBox(height: 10),
            for (final t in r.title.skip(1)) Text(t, style: postType(46, color: typeInk, weight: FontWeight.w700)),
          ],
        ),
      ),
      for (final row in r.rows) ...[
        _Fit(at: row.labelAt, alignment: Alignment.bottomLeft, child: Text(row.label, style: word)),
        if (row.id != RecordSpot.patch)
          _Fit(at: row.timeAt, alignment: Alignment.bottomRight, child: Text(row.time, key: ValueKey('record-time-${row.id.name}'), style: time)),
      ],
      // The patch, glued over the old time. In daylight: a slightly whiter
      // piece of paper, its edge only a hairline that catches the eye on a
      // close look. Lit from under: two papers let less light through, so
      // the patch goes darker, its edge plain, and the old typed time under
      // it shows through as a shadow of ink, the patch's own grain over it.
      Positioned.fromRect(
        rect: patch.at,
        child: IgnorePointer(
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Daylight: the patch itself, a little whiter.
              Opacity(opacity: 0.42 * (1 - lit), child: _PatchPaper(patch: patch)),
              if (lit > 0) ...[
                // Less light through two papers.
                Opacity(opacity: lit, child: const ColoredBox(color: Color(0x2E4A3220))),
                // The old time, typed on FILE 3 under the patch.
                Positioned.fromRect(
                  rect: patch.oldAt.translate(-patch.at.left, -patch.at.top),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.bottomRight,
                    child: Opacity(
                      opacity: 0.85 * lit,
                      child: ImageFiltered(
                        imageFilter: ui.ImageFilter.blur(sigmaX: 1.1, sigmaY: 1.1),
                        child: Text(patch.oldTime, key: const ValueKey('record-old-time'), style: time.copyWith(color: const Color(0xFF2A211B))),
                      ),
                    ),
                  ),
                ),
                // The patch's paper over it, its grain softening the old ink.
                Opacity(opacity: 0.38 * lit, child: _PatchPaper(patch: patch, filter: _thicker)),
              ],
              CustomPaint(
                key: lit > 0 ? const ValueKey('patch-edge') : null,
                painter: _PatchEdge(lit: lit),
              ),
            ],
          ),
        ),
      ),
      // The new time, written by hand on the patch, on the line beside
      // CURTAIN UP.
      _Fit(
        at: patch.newAt,
        alignment: Alignment.bottomRight,
        child: Transform.rotate(
          angle: -0.025,
          child: Text(patch.newTime, key: const ValueKey('record-new-time'), style: handwriting(76, color: penInk).copyWith(height: 1.05)),
        ),
      ),
      if (photo) Positioned.fromRect(rect: r.photoAt, child: PhotoPrintView(photo: r.photo)),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final r = record;
    final light = lit ?? (r.light == RecordLight.lit ? 1.0 : 0.0);
    final view = PictureCanvas(pixels: r.pixels, child: Stack(children: _layers(r, light, photo)));
    if (!semantics) return ExcludeSemantics(child: view);
    return Semantics(
      image: true,
      label: [
        '${r.fileLabel}, the office record. ${r.title.join('. ')}.',
        for (final row in r.rows) '${row.label.replaceAll(' ·', '')} ${row.time}.',
        if (light > 0.5) 'A patch of paper is glued over the curtain up time. On it: ${r.patch.newTime}. Under it, showing through: ${r.patch.oldTime}.',
        if (photo) 'An old photo is clipped to it.',
      ].join(' '),
      excludeSemantics: true,
      child: view,
    );
  }
}

/// The patch's edge: in daylight a hairline shadow under its lower and
/// right edges (paper lifting a little) and a lighter upper edge; lit from
/// under, a soft dark outline where the two papers overlap their edges.
class _PatchEdge extends CustomPainter {
  _PatchEdge({required this.lit});

  final double lit;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    final day = 1 - lit;
    if (day > 0) {
      final shade = Paint()
        ..color = Color.fromRGBO(70, 50, 30, 0.22 * day)
        ..strokeWidth = 3
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
      canvas.drawLine(r.bottomLeft + const Offset(2, 0), r.bottomRight, shade);
      canvas.drawLine(r.topRight + const Offset(0, 2), r.bottomRight, shade);
      final light = Paint()
        ..color = Color.fromRGBO(255, 252, 240, 0.5 * day)
        ..strokeWidth = 2;
      canvas.drawLine(r.topLeft, r.topRight, light);
      canvas.drawLine(r.topLeft, r.bottomLeft, light);
    }
    if (lit > 0) {
      canvas.drawRect(
        r.deflate(1.5),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = Color.fromRGBO(60, 40, 22, 0.45 * lit)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2),
      );
    }
  }

  @override
  bool shouldRepaint(_PatchEdge old) => old.lit != lit;
}

class _PatchPaper extends StatelessWidget {
  const _PatchPaper({required this.patch, this.filter});

  final RecordPatch patch;
  final ColorFilter? filter;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      // The patch's paper fills the place it is glued (its picture's clear
      // margin stays outside).
      final p = patch.pixels;
      final sx = box.maxWidth / patch.paper.width;
      final sy = box.maxHeight / patch.paper.height;
      return Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            left: -patch.paper.left * sx,
            top: -patch.paper.top * sy,
            width: p.width * sx,
            height: p.height * sy,
            child: _picture(patch.file, filter: filter),
          ),
        ],
      );
    },
  );
}

// ── FILE 4 ───────────────────────────────────────────────────────────────

/// FILE 4, the programme: the show's name, its four parts, and the whole
/// show. No start time.
class ProgrammeView extends StatelessWidget {
  const ProgrammeView({super.key, required this.page});

  final ProgrammePage page;

  @override
  Widget build(BuildContext context) {
    final p = page;
    final part = postType(56, color: typeInk, weight: FontWeight.w700);
    return Semantics(
      image: true,
      label: 'FILE 4, the programme. ${p.title.join('. ')}. ${[for (final x in p.parts) '${x.name}, ${x.minutes} minutes'].join('. ')}. ${p.whole.replaceAll('\n', ' ')}',
      excludeSemantics: true,
      child: PictureCanvas(
        pixels: p.pixels,
        child: Stack(
          children: [
            Positioned.fill(child: _picture(p.file)),
            _Fit(
              at: p.titleAt,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(p.title.first, style: AppText.style(AppText.display, size: 64, color: typeInk, letterSpacing: 2)),
                  const SizedBox(height: 12),
                  for (final t in p.title.skip(1)) Text(t, style: postType(40, color: AppColors.goldDeep, weight: FontWeight.w700)),
                ],
              ),
            ),
            _Fit(
              at: p.partsAt,
              child: Column(
                key: const ValueKey('programme-parts'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final x in p.parts)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 22),
                      child: Text('${x.name} · ${x.minutes} MIN', style: part),
                    ),
                ],
              ),
            ),
            _Fit(
              at: p.wholeAt,
              child: Text(p.whole, textAlign: TextAlign.center, style: postType(58, color: const Color(0xE07A2E2E))),
            ),
          ],
        ),
      ),
    );
  }
}

// ── The stage cue card ───────────────────────────────────────────────────

class CueCardView extends StatelessWidget {
  const CueCardView({super.key, required this.card});

  final CueCard card;

  @override
  Widget build(BuildContext context) {
    final c = card;
    final [cue, time] = c.lines;
    return Semantics(
      image: true,
      label: 'The stage cue card: ${c.heading}. ${c.lines.join('. ')}.',
      excludeSemantics: true,
      child: PictureCanvas(
        pixels: c.pixels,
        child: Stack(
          children: [
            Positioned.fill(child: _picture(c.file)),
            _Fit(at: c.headingAt, child: Text(c.heading, key: const ValueKey('cue-heading'), style: postType(92, color: typeBlue))),
            // Written by hand, each line sitting on a ruled line of the card.
            _Fit(
              at: Rect.fromLTRB(c.linesAt.left, c.linesAt.top, c.linesAt.right, c.linesAt.top + c.linesAt.height * 0.2),
              alignment: Alignment.bottomLeft,
              child: Text(cue, style: handwriting(104, color: penInk).copyWith(height: 1.0)),
            ),
            _Fit(
              at: Rect.fromLTRB(c.linesAt.left, c.linesAt.top + c.linesAt.height * 0.25, c.linesAt.right, c.linesAt.bottom),
              alignment: Alignment.bottomCenter,
              child: Transform.rotate(
                angle: -0.03,
                child: Text(time, key: const ValueKey('cue-time'), style: handwriting(250, color: const Color(0xE88A2B2B)).copyWith(height: 1.0)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── The Amendment Slip ───────────────────────────────────────────────────

/// The Amendment Slip as laid out at its own pixels (its paper shown,
/// [AmendmentSlip.paper]): its words, the stamp; [times] false leaves its
/// two times out (the final's pins stand there).
class AmendmentSlipView extends StatelessWidget {
  const AmendmentSlipView({super.key, required this.slip, this.back, this.times = true});

  final AmendmentSlip slip;

  /// Its back shown (null: as [AmendmentSlip.showBack] says).
  final bool? back;
  final bool times;

  /// The slip at its own pixels, front or back.
  static Widget canvas(AmendmentSlip s, {required bool back, bool times = true}) => SizedBox(
    width: s.pixels.width,
    height: s.pixels.height,
    child: Stack(children: back ? _back(s) : _front(s, times: times)),
  );

  static List<Widget> _front(AmendmentSlip s, {required bool times}) {
    final time = postType(118, color: typeBlue);
    return [
      Positioned.fill(child: _picture(s.file)),
      _Fit(at: s.headerAt, child: Text(s.header, key: const ValueKey('slip-header'), style: postType(76, color: typeInk))),
      _Fit(
        at: s.linesAt,
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [for (final l in s.lines) Text(l, style: postType(70, color: typeInk))],
        ),
      ),
      _Fit(at: s.changeAt, alignment: Alignment.centerLeft, child: Text(s.changeLabel, style: postType(70, color: typeInk))),
      if (times) _Fit(at: s.oldAt, child: Text(s.oldTime, key: const ValueKey('slip-old'), style: time)),
      // From the old time to the new (drawn: the papers' faces have no arrow).
      Positioned.fromRect(
        rect: Rect.fromLTRB(s.oldAt.right, s.oldAt.top, s.newAt.left, s.oldAt.bottom).deflate(18),
        child: const FittedBox(child: InkIcon(InkGlyph.arrow, size: 100, color: typeInk)),
      ),
      if (times) _Fit(at: s.newAt, child: Text(s.newTime, key: const ValueKey('slip-new'), style: time.copyWith(color: const Color(0xE07A2E2E)))),
      Positioned.fromRect(
        rect: s.stampAt,
        child: Opacity(opacity: 0.85, child: Image.asset(s.stamp, key: const ValueKey('slip-stamp'), fit: BoxFit.contain, excludeFromSemantics: true)),
      ),
    ];
  }

  static List<Widget> _back(AmendmentSlip s) {
    final b = s.back;
    final sign = scaled(b.signAt, b.sketchPixels, b.sketchAt.size);
    return [
      // The same paper, turned over.
      Positioned.fill(child: Transform.flip(flipX: true, child: _picture(s.file))),
      Positioned.fromRect(
        rect: b.sketchAt,
        child: Stack(
          children: [
            // Pencil on the slip: only its lines, never the white of the
            // sketch's own paper.
            Positioned.fill(child: ColorFiltered(colorFilter: pencil, child: Image.asset(b.sketch, key: const ValueKey('slip-sketch'), fit: BoxFit.fill, excludeFromSemantics: true))),
            _Fit(at: sign.deflate(3), child: Text(b.sign, key: const ValueKey('slip-sign'), style: postType(44, color: const Color(0xFF2E2B28), weight: FontWeight.w700))),
          ],
        ),
      ),
      _Fit(at: b.noteAt, child: Text(b.note, key: const ValueKey('slip-note'), style: handwriting(76, color: const Color(0xE63A3633)))),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final s = slip;
    final turned = back ?? s.showBack;
    return Semantics(
      image: true,
      label: turned
          ? 'The back of the slip: a small pencil sketch of steps, a street lamp and a metro sign that says ${s.back.sign}. Under it: ${s.back.note}'
          : 'The Amendment Slip: ${s.words.join('. ')}. A round violet stamp: a clock with no hands in a ring of leaves. No name.',
      excludeSemantics: true,
      child: PixelCrop(pixels: s.pixels, crop: s.paper, child: canvas(s, back: turned, times: times)),
    );
  }
}

// ── A closer look ────────────────────────────────────────────────────────

/// [child] looked at closer over the page, in the dark: its [title], a
/// line under it ([line]), pinch to look closer still; [actions] under it
/// (the last one closes it: [closeLabel]). With Reduce Motion it opens at
/// once. Returns what an action popped.
Future<T?> showOperaCloser<T>(
  BuildContext context, {
  required String title,
  required Widget child,
  String? line,
  List<Widget> actions = const [],
  String closeLabel = 'CLOSE',
  Key? closeKey,
  double maxWidth = 560,
}) {
  final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  return Navigator.of(context).push<T>(
    PageRouteBuilder<T>(
      opaque: false,
      barrierDismissible: true,
      // Dark enough that the page under it never reads through.
      barrierColor: AppColors.navyDeep.withValues(alpha: 0.975),
      transitionDuration: still ? Duration.zero : const Duration(milliseconds: 250),
      pageBuilder: (context, anim, _) => FadeTransition(
        opacity: anim,
        child: Material(
          type: MaterialType.transparency,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text.rich(AppText.liningDigits(title, AppText.mark(color: AppColors.goldLight)), textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      ClipRect(child: InteractiveViewer(maxScale: 4, child: child)),
                      if (line != null) ...[
                        const SizedBox(height: 12),
                        Text(line, key: const ValueKey('closer-line'), textAlign: TextAlign.center, style: AppText.aside(size: 17, color: AppColors.paperLight)),
                      ],
                      const SizedBox(height: 16),
                      ...actions,
                      _CloseLink(label: closeLabel, closeKey: closeKey),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _CloseLink extends StatelessWidget {
  const _CloseLink({required this.label, this.closeKey});

  final String label;
  final Key? closeKey;

  @override
  Widget build(BuildContext context) => TextButton(
    key: closeKey,
    onPressed: () => Navigator.of(context).pop(),
    style: TextButton.styleFrom(minimumSize: const Size(48, 48), foregroundColor: AppColors.goldLight),
    child: Text(label, style: AppText.button(size: 16, color: AppColors.goldLight)),
  );
}

/// The metro sign of the sketch on the slip's back, up close: the name on
/// it large enough to read.
class SlipSignCloser extends StatelessWidget {
  const SlipSignCloser({super.key, required this.back});

  final SlipBack back;

  /// Round the sign: its arch and the top of its posts.
  static const around = Rect.fromLTRB(1000, 200, 1440, 520);

  @override
  Widget build(BuildContext context) => Semantics(
    image: true,
    label: 'The metro sign in the sketch, closer. It says ${back.sign}.',
    excludeSemantics: true,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: ColoredBox(
        color: const Color(0xFFE6E1D8),
        child: PixelCrop(
          pixels: back.sketchPixels,
          crop: around,
          child: Stack(
            children: [
              Positioned.fill(child: ColorFiltered(colorFilter: pencil, child: Image.asset(back.sketch, fit: BoxFit.fill, excludeFromSemantics: true))),
              _Fit(at: back.signAt.deflate(3), child: Text(back.sign, key: const ValueKey('slip-sign-close'), style: postType(44, color: const Color(0xFF2E2B28), weight: FontWeight.w700))),
            ],
          ),
        ),
      ),
    ),
  );
}
