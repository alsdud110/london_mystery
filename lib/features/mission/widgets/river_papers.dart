import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../data/models/river_puzzles.dart';
import '../../../data/models/scene_explore.dart' show ScenePixels;
import '../../../widgets/glossary_text.dart';
import 'tower_documents.dart';
import 'workshop_papers.dart' show DrawnEvidenceView;

/// Case 04's stones and papers drawn with their words: the back of the
/// brass plaque, a carved mark up close, a page of the keeper's ledger, the
/// delivery label torn into pieces, the street book and the gate's sign.
/// Every picture is blank; what is written on it is written here, at the
/// places measured on it (`season2_case04_scenes.dart`).

/// Words scratched or carved into metal or stone: dark, with a fine light
/// edge under them.
TextStyle carved(double size, {Color color = AppColors.walnutDeep}) => AppText.style(AppText.body, size: size, weight: FontWeight.w800, color: color, letterSpacing: size * 0.06, height: 1.3).copyWith(
  shadows: [Shadow(color: AppColors.creamGold.withValues(alpha: 0.6), offset: const Offset(0, 1))],
);

/// [child] laid out at [pixels]' own size and scaled to fit its box: the
/// words on a picture keep their place and size relative to it on every
/// screen.
class PictureCanvas extends StatelessWidget {
  const PictureCanvas({super.key, required this.pixels, required this.child});

  final ScenePixels pixels;
  final Widget child;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: pixels.aspect,
    child: FittedBox(
      fit: BoxFit.fill,
      child: MediaQuery.withNoTextScaling(
        child: SizedBox(width: pixels.width, height: pixels.height, child: child),
      ),
    ),
  );
}

Rect _px(Rect fraction, ScenePixels p) => Rect.fromLTRB(fraction.left * p.width, fraction.top * p.height, fraction.right * p.width, fraction.bottom * p.height);

// ── The plaque's back ────────────────────────────────────────────────────

/// The back of the brass plaque, its three lines scratched on it.
class PlaqueBackView extends StatelessWidget {
  const PlaqueBackView({super.key, required this.plaque});

  final PlaqueBack plaque;

  @override
  Widget build(BuildContext context) {
    final at = _px(plaque.writeOn, plaque.pixels);
    return Semantics(
      image: true,
      label: '${plaque.label}: ${plaque.lines.join(' ')}',
      excludeSemantics: true,
      child: PictureCanvas(
        pixels: plaque.pixels,
        child: Stack(
          children: [
            Positioned.fill(child: Image.asset(plaque.file, fit: BoxFit.fill, excludeFromSemantics: true)),
            Positioned.fromRect(
              rect: at,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    plaque.lines.join('\n'),
                    key: const ValueKey('plaque-back-lines'),
                    textAlign: TextAlign.center,
                    // Scratched by hand: lighter than the front's engraving.
                    style: carved(62, color: AppColors.creamGold).copyWith(
                      fontWeight: FontWeight.w600,
                      shadows: const [Shadow(color: Color(0xCC000000), offset: Offset(0, 2), blurRadius: 1)],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── A mark of the quay wall ─────────────────────────────────────────────

/// A mark up close: its stone, and its word carved in its panel.
class RiverMarkView extends StatelessWidget {
  const RiverMarkView({super.key, required this.scene, required this.mark, this.wordKey = true});

  final RiverMarksScene scene;
  final RiverMark mark;

  /// Its word keyed (`mark-word-…`): false where the same mark is shown
  /// twice at once (the comparing cards under its close-up).
  final bool wordKey;

  @override
  Widget build(BuildContext context) {
    final at = _px(mark.closeWordAt, scene.closePixels);
    return Semantics(
      image: true,
      label: '${mark.spoken}.',
      excludeSemantics: true,
      child: PictureCanvas(
        pixels: scene.closePixels,
        child: Stack(
          children: [
            Positioned.fill(child: Image.asset(mark.closeUp, fit: BoxFit.fill, excludeFromSemantics: true)),
            Positioned.fromRect(
              rect: at,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(mark.word, key: wordKey ? ValueKey('mark-word-${mark.id}') : null, style: carved(104)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── The keeper's ledger ──────────────────────────────────────────────────

/// A page of the keeper's ledger, its lines written by the app. Its box
/// numbers can be circled ([onBox]); [circled] is the one circled, [found]
/// a line found on it (picked out in ink).
class LedgerPageView extends StatelessWidget {
  const LedgerPageView({super.key, required this.scene, required this.page, this.circled, this.found, this.onBox, this.words = false});

  final KeeperHutScene scene;
  final int page;
  final String? circled;
  final String? found;
  final ValueChanged<String>? onBox;

  /// Its harder words can be tapped for their meaning (the page read in
  /// the hut; not a small picture of it that opens as a whole).
  final bool words;

  static const _ink = AppColors.ink;

  @override
  Widget build(BuildContext context) {
    final p = scene.pages[page];
    final crop = p.crop;
    final size = Size(crop.width * scene.ledgerPixels.width, crop.height * scene.ledgerPixels.height);
    final write = p.writeInCrop;
    final at = Rect.fromLTRB(write.left * size.width, write.top * size.height, write.right * size.width, write.bottom * size.height);
    final text = AppText.style(AppText.body, size: 27, weight: FontWeight.w600, color: _ink, height: 1.2);
    return Semantics(
      container: true,
      label: '${scene.ledgerLabel}. ${p.title}.',
      child: AspectRatio(
        aspectRatio: size.width / size.height,
        child: FittedBox(
          fit: BoxFit.fill,
          child: MediaQuery.withNoTextScaling(
            child: SizedBox(
              width: size.width,
              height: size.height,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: CroppedPicture(file: scene.ledger, pixels: scene.ledgerPixels, crop: crop),
                  ),
                  Positioned.fromRect(
                    rect: at,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          p.title,
                          key: ValueKey('ledger-title-$page'),
                          textAlign: TextAlign.center,
                          style: AppText.style(AppText.body, size: 32, weight: FontWeight.w800, color: AppColors.navyDeep, letterSpacing: 2),
                        ),
                        Container(height: 2, margin: const EdgeInsets.only(top: 6, bottom: 10), color: AppColors.navyDeep.withValues(alpha: 0.5)),
                        for (final (i, e) in p.entries.indexed)
                          Expanded(
                            child: _LedgerLine(index: i, entry: e, style: text, hands: scene.hands, circled: circled, found: found != null && e.boxes.contains(found), onBox: onBox, page: page, words: words),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LedgerLine extends StatelessWidget {
  const _LedgerLine({required this.index, required this.entry, required this.style, required this.hands, required this.circled, required this.found, required this.onBox, required this.page, required this.words});

  final bool words;

  /// Its place on the page (a box can be on more than one line).
  final int index;
  final LedgerEntry entry;
  final TextStyle style;
  final String hands;
  final String? circled;
  final bool found;
  final ValueChanged<String>? onBox;
  final int page;

  @override
  Widget build(BuildContext context) {
    final e = entry;
    return Semantics(
      container: true,
      label: e.spoken,
      child: Container(
        decoration: found
            ? BoxDecoration(
                color: AppColors.creamGold.withValues(alpha: 0.35),
                border: Border(left: BorderSide(color: AppColors.burgundy.withValues(alpha: 0.8), width: 5)),
              )
            : null,
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 420,
                  child: ExcludeSemantics(
                    excluding: onBox == null,
                    child: GlossaryText.spans(
                      style: style,
                      interactive: words,
                      [
                          TextSpan(
                            text: '${e.date}  ',
                            style: style.copyWith(fontSize: style.fontSize! * 0.8, color: AppColors.inkBrown, fontWeight: FontWeight.w800),
                          ),
                          for (final part in e.parts)
                            if (part.box case final box?)
                              WidgetSpan(
                                alignment: PlaceholderAlignment.middle,
                                child: _BoxNumber(
                                  key: ValueKey('ledger-$page-$index-$box'),
                                  id: box,
                                  text: part.text,
                                  style: style,
                                  circled: circled == box,
                                  onTap: onBox == null ? null : () => onBox!(box),
                                ),
                              )
                            else
                              TextSpan(text: part.text, style: style),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            SizedBox(
              width: 62,
              child: ExcludeSemantics(
                child: e.hands
                    ? Image.asset(hands, key: const ValueKey('ledger-hands'), height: 52, fit: BoxFit.contain, excludeFromSemantics: true)
                    : Text(
                        '— ${e.initials ?? ''}',
                        style: AppText.style(AppText.italic, size: 22, color: AppColors.inkBrown, fontStyle: FontStyle.italic),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A box number on a ledger line: circled in red pencil when chosen.
class _BoxNumber extends StatelessWidget {
  const _BoxNumber({super.key, required this.id, required this.text, required this.style, required this.circled, required this.onTap});

  final String id;
  final String text;
  final TextStyle style;
  final bool circled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final word = Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: circled ? AppColors.burgundy : (onTap == null ? Colors.transparent : AppColors.navy.withValues(alpha: 0.35)), width: circled ? 4 : 2),
      ),
      child: Text(
        text,
        style: style.copyWith(fontWeight: FontWeight.w800, color: circled ? AppColors.burgundy : AppColors.navyDeep),
      ),
    );
    if (onTap == null) return word;
    return Semantics(
      button: true,
      selected: circled,
      label: '$text${circled ? ', circled' : ''}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        // A wider target than the ink (the lines are far enough apart).
        child: Padding(padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2), child: word),
      ),
    );
  }
}

// ── The delivery label ───────────────────────────────────────────────────

/// The label's pieces as cut by the app: the three tears, measured where
/// the address line is split so that the third goes exactly between its
/// two parts (whatever the type's widths).
class LabelCut {
  LabelCut(this.label) {
    final start = TextPainter(
      text: TextSpan(text: label.addressStart, style: addressStyle),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout();
    // The gap after the last letter of the first part (its letter spacing).
    restLeft = label.addressLeft + start.width;
    gap = restLeft - _addressSpacing / 2;
    start.dispose();
    final rng = math.Random(4);
    double jag(double a) => (rng.nextDouble() * 2 - 1) * a;
    final w = label.pixels.width, h = label.pixels.height;
    _tear1 = [for (var x = -10.0; x <= w + 10; x += 26) Offset(x, label.tear1 + jag(11))];
    _tear2 = [for (var x = -10.0; x <= w + 10; x += 26) Offset(x, label.tear2 + jag(11))];
    // The third: in from the right edge above the address, then down
    // through the gap in it, kept within the gap along the line.
    final band = (label.addressTop - 14, label.addressTop + label.addressSize * 1.35 + 14);
    _tear3 = [
      for (var x = w + 10; x > gap + 14; x -= 26) Offset(x, label.tear3 + jag(9)),
      Offset(gap, label.tear3),
      for (var y = label.tear3 + 24; y <= h + 10; y += 24) Offset(gap + (y >= band.$1 && y <= band.$2 ? jag(_addressSpacing / 2 - 2) : jag(12)), y),
    ];
  }

  final DeliveryLabel label;

  static const _addressSpacing = 9.0;

  TextStyle get addressStyle => AppText.style(AppText.body, size: label.addressSize, weight: FontWeight.w800, color: labelInk, letterSpacing: _addressSpacing, height: 1.2);

  /// Where the address's second part starts, and the gap the third tear
  /// goes down through (label pixels).
  late final double restLeft;
  late final double gap;

  late final List<Offset> _tear1;
  late final List<Offset> _tear2;
  late final List<Offset> _tear3;

  static const labelInk = Color(0xFF1F2A44);

  /// The outline of [piece] (label pixels).
  Path pathOf(String piece) {
    final w = label.pixels.width, h = label.pixels.height;
    Path poly(List<Offset> points) => Path()..addPolygon(points, true);
    return switch (piece) {
      DeliveryLabel.top => poly([const Offset(-10, -10), Offset(w + 10, -10), ..._tear1.reversed]),
      DeliveryLabel.middle => poly([..._tear1, ..._tear2.reversed]),
      DeliveryLabel.bottom => poly([..._tear2, Offset(w + 10, _tear3.first.dy), ..._tear3, Offset(-10, h + 10)]),
      _ => poly([..._tear3, Offset(w + 10, h + 10)]),
    };
  }

  /// The tears along [piece]'s torn edges, where the paper is.
  List<List<Offset>> tearsOf(String piece) {
    List<Offset> across(List<Offset> t) => [
      for (final p in t)
        if (p.dx >= label.paperLeft && p.dx <= label.paperRight) p,
    ];
    final corner = [
      for (final p in _tear3)
        if (p.dx <= label.paperRight && p.dy <= label.paperBottom) p,
    ];
    return switch (piece) {
      DeliveryLabel.top => [across(_tear1)],
      DeliveryLabel.middle => [across(_tear1), across(_tear2)],
      DeliveryLabel.bottom => [across(_tear2), corner],
      _ => [corner],
    };
  }

  /// The box a piece is shown in alone (label pixels): round its paper.
  Rect boundsOf(String piece) {
    final b = pathOf(piece).getBounds();
    return Rect.fromLTRB(math.max(b.left, label.paperLeft - 40), math.max(b.top, 0), math.min(b.right, label.paperRight + 40), math.min(b.bottom, label.paperBottom + 14));
  }

  /// [piece]'s outline on the back: the front turned over, left to right.
  Path backPathOf(String piece) => pathOf(piece).transform(
    (Matrix4.identity()
          ..translateByDouble(label.pixels.width, 0, 0, 1)
          ..scaleByDouble(-1, 1, 1, 1))
        .storage,
  );
}

/// The label's pieces in [pieces] laid where they are on it (label pixels,
/// the whole label's size): the blank card, cut along its tears, and what
/// is printed on each piece. Nothing of a piece not in [pieces] is built.
class LabelSheet extends StatelessWidget {
  const LabelSheet({super.key, required this.cut, required this.pieces});

  final LabelCut cut;
  final Set<String> pieces;

  @override
  Widget build(BuildContext context) {
    final l = cut.label;
    return SizedBox(
      width: l.pixels.width,
      height: l.pixels.height,
      child: Stack(
        children: [
          for (final p in [DeliveryLabel.top, DeliveryLabel.middle, DeliveryLabel.bottom, DeliveryLabel.last])
            if (pieces.contains(p))
              Positioned.fill(
                key: ValueKey('label-piece-$p'),
                child: ClipPath(
                  clipper: _PathClipper(cut.pathOf(p)),
                  child: Stack(
                    children: [
                      Positioned.fill(child: Image.asset(l.file, fit: BoxFit.fill, excludeFromSemantics: true)),
                      ..._printed(p),
                      Positioned.fill(child: CustomPaint(painter: _TearPainter(cut.tearsOf(p)))),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }

  List<Widget> _printed(String piece) {
    final l = cut.label;
    TextStyle ink(double size, {Color color = LabelCut.labelInk}) => AppText.style(AppText.body, size: size, weight: FontWeight.w800, color: color, letterSpacing: size * 0.07, height: 1.2);
    return [
      for (final line in l.lines)
        if (line.piece == piece)
          Positioned(
            left: line.centred ? 0 : line.left,
            right: line.centred ? 0 : null,
            top: line.top,
            child: line.stamp
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(border: Border.all(color: AppColors.burgundy.withValues(alpha: 0.85), width: 5)),
                      child: Text(line.text, style: ink(line.size, color: AppColors.burgundy.withValues(alpha: 0.9))),
                    ),
                  )
                : Text(
                    line.text,
                    textAlign: line.centred ? TextAlign.center : TextAlign.left,
                    style: ink(line.size, color: line.faint ? LabelCut.labelInk.withValues(alpha: 0.75) : LabelCut.labelInk),
                  ),
          ),
      if (piece == DeliveryLabel.middle)
        Positioned.fromRect(
          rect: l.stampAt,
          child: Opacity(
            opacity: 0.8,
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(AppColors.burgundy, BlendMode.srcIn),
              child: Image.asset(l.hands, key: const ValueKey('label-hands'), fit: BoxFit.contain, excludeFromSemantics: true),
            ),
          ),
        ),
      if (piece == DeliveryLabel.bottom) ...[
        Positioned(
          left: l.numberAt.left,
          top: l.numberAt.top,
          child: Text(l.numberLabel, style: ink(l.addressSize * 0.85)),
        ),
        // Where the number was: the ink run into the stain.
        Positioned(
          left: l.numberAt.left + 110,
          top: l.numberAt.top + 2,
          width: l.numberAt.width - 110,
          height: l.numberAt.height,
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 9, sigmaY: 7),
            child: DecoratedBox(
              key: const ValueKey('label-washed'),
              decoration: BoxDecoration(color: AppColors.walnut.withValues(alpha: 0.32), borderRadius: BorderRadius.circular(30)),
            ),
          ),
        ),
        Positioned(
          left: l.addressLeft,
          top: l.addressTop,
          child: Text(l.addressStart, key: const ValueKey('label-address-start'), style: cut.addressStyle),
        ),
      ],
      if (piece == DeliveryLabel.last)
        Positioned(
          left: cut.restLeft,
          top: l.addressTop,
          child: Text(l.addressRest, key: const ValueKey('label-address-rest'), style: cut.addressStyle),
        ),
    ];
  }
}

/// The last piece's back: the card turned over, its message written on it.
class LabelBackSheet extends StatelessWidget {
  const LabelBackSheet({super.key, required this.cut});

  final LabelCut cut;

  @override
  Widget build(BuildContext context) {
    final l = cut.label;
    return SizedBox(
      width: l.pixels.width,
      height: l.pixels.height,
      child: ClipPath(
        clipper: _PathClipper(cut.backPathOf(DeliveryLabel.last)),
        child: Stack(
          children: [
            Positioned.fill(child: Image.asset(l.back, fit: BoxFit.fill, excludeFromSemantics: true)),
            Positioned.fromRect(
              rect: l.backAt,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        l.backLines.join('\n'),
                        key: const ValueKey('label-back-message'),
                        textAlign: TextAlign.center,
                        style: AppText.style(AppText.italic, size: 46, color: AppColors.ink, fontStyle: FontStyle.italic, height: 1.3),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 60,
                      child: ColorFiltered(
                        colorFilter: const ColorFilter.mode(AppColors.ink, BlendMode.srcIn),
                        child: Image.asset(l.hands, fit: BoxFit.contain, excludeFromSemantics: true),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// [sheet] (label pixels, the whole label's size) shown through [part] of
/// it, scaled to fit its box.
class LabelPart extends StatelessWidget {
  const LabelPart({super.key, required this.part, required this.size, required this.sheet});

  final Rect part;
  final Size size;
  final Widget sheet;

  @override
  Widget build(BuildContext context) => AspectRatio(
    aspectRatio: part.width / part.height,
    child: FittedBox(
      fit: BoxFit.fill,
      child: MediaQuery.withNoTextScaling(
        child: SizedBox(
          width: part.width,
          height: part.height,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.topLeft,
              minWidth: size.width,
              maxWidth: size.width,
              minHeight: size.height,
              maxHeight: size.height,
              child: Transform.translate(offset: -part.topLeft, child: sheet),
            ),
          ),
        ),
      ),
    ),
  );
}

/// One piece of the label alone, at its own proportions.
class LabelPieceView extends StatelessWidget {
  const LabelPieceView({super.key, required this.cut, required this.piece});

  final LabelCut cut;
  final String piece;

  @override
  Widget build(BuildContext context) => LabelPart(
    part: cut.boundsOf(piece),
    size: Size(cut.label.pixels.width, cut.label.pixels.height),
    sheet: LabelSheet(cut: cut, pieces: {piece}),
  );
}

/// The last piece's back alone (its outline turned over).
class LabelPieceBackView extends StatelessWidget {
  const LabelPieceBackView({super.key, required this.cut});

  final LabelCut cut;

  @override
  Widget build(BuildContext context) {
    final b = cut.boundsOf(DeliveryLabel.last);
    final w = cut.label.pixels.width;
    return LabelPart(
      part: Rect.fromLTRB(w - b.right, b.top, w - b.left, b.bottom),
      size: Size(w, cut.label.pixels.height),
      sheet: LabelBackSheet(cut: cut),
    );
  }
}

/// What a label piece says, for screen readers (never the last piece's
/// words before it is found: it has none of its own here).
String labelPieceSpoken(DeliveryLabel l, String piece) => switch (piece) {
  DeliveryLabel.top =>
    'The piece with the brass eyelet: ${[for (final x in l.lines)
      if (x.piece == piece) x.text].join('. ')}.',
  DeliveryLabel.middle =>
    'A piece: ${[for (final x in l.lines)
      if (x.piece == piece) x.text].join('. ')}. Two clock hands are stamped on it.',
  DeliveryLabel.bottom =>
    'A piece: ${[for (final x in l.lines)
      if (x.piece == piece) x.text].join('. ')}. ${l.numberLabel}, the number washed away. ${l.addressStart}, then the label is torn.',
  _ => 'The last piece of the label: ${l.addressRest}.',
};

class _PathClipper extends CustomClipper<Path> {
  const _PathClipper(this.path);

  final Path path;

  @override
  Path getClip(Size size) => path;

  @override
  bool shouldReclip(_PathClipper old) => old.path != path;
}

/// A torn edge: pale frayed fibres along it, a soft shadow inside.
class _TearPainter extends CustomPainter {
  const _TearPainter(this.tears);

  final List<List<Offset>> tears;

  @override
  void paint(Canvas canvas, Size size) {
    final shade = Paint()
      ..color = AppColors.walnutDeep.withValues(alpha: 0.28)
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final fibre = Paint()
      ..color = const Color(0xFFF6EBD2)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;
    for (final t in tears) {
      if (t.length < 2) continue;
      final path = Path()..addPolygon(t, false);
      canvas.drawPath(path, shade);
      canvas.drawPath(path, fibre);
    }
  }

  @override
  bool shouldRepaint(_TearPainter old) => old.tears != tears;
}

/// The scrap that is not the label's: another, thinner paper (tinted
/// blue-grey by the app), its words in blue ink.
class DecoyScrapView extends StatelessWidget {
  const DecoyScrapView({super.key, required this.scene});

  final BoxesScene scene;

  /// The scrap's paper turned cool and grey (its picture is cream).
  static const tint = ColorFilter.matrix([
    0.62, 0.20, 0.10, 0, 6, //
    0.18, 0.66, 0.14, 0, 12,
    0.18, 0.22, 0.72, 0, 30,
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final at = _px(scene.decoyAt, scene.decoyPixels);
    return Semantics(
      image: true,
      label: 'A scrap of thinner, blue-grey paper, in blue ink: ${scene.decoyLines.join('. ')}.',
      excludeSemantics: true,
      child: PictureCanvas(
        pixels: scene.decoyPixels,
        child: Stack(
          children: [
            Positioned.fill(
              child: ColorFiltered(
                colorFilter: tint,
                child: Image.asset(scene.decoy, fit: BoxFit.fill, excludeFromSemantics: true),
              ),
            ),
            Positioned.fromRect(
              rect: at,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  scene.decoyLines.join('\n'),
                  key: const ValueKey('decoy-words'),
                  style: AppText.style(AppText.italic, size: 110, color: const Color(0xFF2B4C8C), fontStyle: FontStyle.italic, height: 1.25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── The street book ──────────────────────────────────────────────────────

/// The street book, its addresses written on its pages: each tappable
/// ([onEntry]); [selected] picked out, those [crossed] struck through in
/// red ink. Both pages at once (looked at closer), or one [page] read at a
/// time, its words at [bodySize] on screen.
class StreetBookView extends StatelessWidget {
  const StreetBookView({super.key, required this.scene, required this.selected, required this.crossed, this.onEntry, this.page});

  final StreetBookScene scene;
  final String? selected;
  final Set<String> crossed;
  final ValueChanged<String>? onEntry;

  /// The page shown alone (0: left, 1: right), or null: both.
  final int? page;

  /// The part of the book shown: its two pages (book pixels).
  static const view = Rect.fromLTRB(40, 220, 984, 1250);

  /// Each page shown alone (book pixels).
  static const pageViews = [Rect.fromLTRB(75, 235, 495, 1245), Rect.fromLTRB(490, 235, 960, 1245)];

  /// The size of an address's lines, and of its name, on screen (a page
  /// read alone).
  static const bodySize = 14.0;
  static const nameSize = 17.0;

  @override
  Widget build(BuildContext context) {
    final p = page;
    if (p == null) return _book(view, null);
    final part = pageViews[p];
    final aspect = part.width / part.height;
    return LayoutBuilder(
      builder: (context, box) {
        // As wide as the page, and no taller than most of the screen.
        final tallest = math.max(420.0, MediaQuery.sizeOf(context).height * 0.7);
        final width = math.min(box.maxWidth, tallest * aspect);
        return Center(
          child: SizedBox(width: width, child: _book(part, width / part.width)),
        );
      },
    );
  }

  /// The book through [part]; [scale]: screen points per book pixel when
  /// a page is read alone (its words then sized for the screen).
  Widget _book(Rect part, double? scale) {
    final px = scene.bookPixels;
    return LabelPart(
      part: part,
      size: Size(px.width, px.height),
      sheet: SizedBox(
        width: px.width,
        height: px.height,
        child: Stack(
          children: [
            Positioned.fill(child: Image.asset(scene.book, fit: BoxFit.fill, excludeFromSemantics: true)),
            for (final (i, area) in scene.pages.indexed)
              if (page == null || page == i)
                Positioned.fromRect(
                  rect: _px(area, px),
                  child: Column(
                    children: [
                      for (final e in scene.entries.where((e) => e.page == i))
                        Expanded(
                          child: _StreetEntryView(
                            key: ValueKey('book-entry-${e.id}'),
                            entry: e,
                            bodySize: scale == null ? 34 : bodySize / scale,
                            nameSize: scale == null ? 42 : nameSize / scale,
                            width: scale == null ? 330 : null,
                            selected: selected == e.id,
                            crossed: crossed.contains(e.id),
                            onTap: onEntry == null || crossed.contains(e.id) ? null : () => onEntry!(e.id),
                          ),
                        ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

class _StreetEntryView extends StatelessWidget {
  const _StreetEntryView({super.key, required this.entry, required this.bodySize, required this.nameSize, required this.width, required this.selected, required this.crossed, required this.onTap});

  final StreetEntry entry;

  /// Its lines' and its name's size (book pixels), and the width they are
  /// laid out in (null: the room there is).
  final double bodySize;
  final double nameSize;
  final double? width;
  final bool selected;
  final bool crossed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final e = entry;
    final ink = crossed ? AppColors.ink.withValues(alpha: 0.45) : AppColors.ink;
    return Semantics(
      button: onTap != null,
      selected: selected,
      label: '${e.name}. ${e.lines.join(' ')}${crossed ? ' Crossed out.' : ''}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: selected ? AppColors.creamGold.withValues(alpha: 0.45) : null,
            border: Border.all(color: selected ? AppColors.navy : Colors.transparent, width: 5),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, box) => FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.topLeft,
                  child: SizedBox(
                    width: width ?? box.maxWidth,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          e.name,
                          key: ValueKey('book-name-${e.id}'),
                          style: AppText.style(AppText.body, size: nameSize, weight: FontWeight.w800, color: crossed ? ink : AppColors.navyDeep, height: 1.15),
                        ),
                        SizedBox(height: bodySize * 0.3),
                        for (final (i, line) in e.lines.indexed)
                          Padding(
                            padding: EdgeInsets.only(bottom: bodySize * 0.18),
                            child: Text(
                              line,
                              key: ValueKey('book-line-${e.id}-$i'),
                              style: AppText.style(AppText.body, size: bodySize, weight: FontWeight.w500, color: ink, height: 1.2),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (crossed)
                Positioned.fill(
                  child: CustomPaint(key: ValueKey('book-crossed-${e.id}'), painter: const _CrossOutPainter()),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Two strokes of red ink across a crossed-out address.
class _CrossOutPainter extends CustomPainter {
  const _CrossOutPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final pen = Paint()
      ..color = AppColors.burgundy.withValues(alpha: 0.85)
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(size.width * 0.02, size.height * 0.22), Offset(size.width * 0.98, size.height * 0.16), pen);
    canvas.drawLine(Offset(size.width * 0.04, size.height * 0.62), Offset(size.width * 0.96, size.height * 0.30), pen..strokeWidth = 6);
  }

  @override
  bool shouldRepaint(_CrossOutPainter old) => false;
}

// ── The gate ─────────────────────────────────────────────────────────────

/// The gate of the address, its sign painted on its iron: [view] (fractions
/// of the picture) shown, and the label's last piece caught on its bar when
/// [scrap] is given.
class GateView extends StatelessWidget {
  const GateView({super.key, required this.scene, this.view = const Rect.fromLTRB(0, 0, 1, 1), this.scrap});

  final StreetBookScene scene;
  final Rect view;
  final Widget? scrap;

  @override
  Widget build(BuildContext context) {
    final px = scene.gatePixels;
    final part = _px(view, px);
    final sign = _px(scene.signAt, px);
    final caught = _px(scene.scrapAt, px);
    return Semantics(
      image: true,
      label: scene.gateLabel,
      excludeSemantics: true,
      child: LabelPart(
        part: part,
        size: Size(px.width, px.height),
        sheet: SizedBox(
          width: px.width,
          height: px.height,
          child: Stack(
            children: [
              Positioned.fill(child: Image.asset(scene.gate, fit: BoxFit.fill, excludeFromSemantics: true)),
              Positioned.fromRect(
                rect: sign,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      scene.signLines.join('\n'),
                      key: const ValueKey('gate-sign'),
                      textAlign: TextAlign.center,
                      style: AppText.style(AppText.display, size: 52, color: AppColors.goldLight, height: 1.1, letterSpacing: 4).copyWith(
                        shadows: const [Shadow(color: Color(0xCC000000), offset: Offset(0, 2), blurRadius: 3)],
                      ),
                    ),
                  ),
                ),
              ),
              if (scrap case final s?)
                Positioned.fromRect(
                  rect: caught,
                  child: Transform.rotate(angle: -0.12, child: Center(child: s)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Evidence drawn with its words ───────────────────────────────────────

/// A piece of Case 04's evidence as it is shown: its blank picture with
/// its words ([RiverEvidenceArt]).
class RiverEvidenceArtView extends StatelessWidget {
  const RiverEvidenceArtView({super.key, required this.art});

  final RiverEvidenceArt art;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: switch (art) {
      MarkEvidenceArt(:final scene, :final mark) => RiverMarkView(scene: scene, mark: scene.mark(mark)),
      LedgerEvidenceArt(:final scene, :final page) => LedgerPageView(scene: scene, page: page),
      DrawnEvidenceArt(:final drawn) => DrawnEvidenceView(drawn: drawn),
      final LabelEvidenceArt a => () {
        final cut = LabelCut(a.label);
        final size = Size(a.label.pixels.width, a.label.pixels.height);
        return a.last
            ? LabelPart(
                part: a.lowerPart,
                size: size,
                sheet: LabelSheet(cut: cut, pieces: const {DeliveryLabel.bottom, DeliveryLabel.last}),
              )
            : LabelPart(
                part: Offset.zero & size,
                size: size,
                sheet: LabelSheet(cut: cut, pieces: DeliveryLabel.boxPieces.toSet()),
              );
      }(),
    },
  );
}
