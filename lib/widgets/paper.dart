import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../core/theme/app_tokens.dart';
import 'paper_background.dart';

/// A sheet of paper lying on the desk: the base surface for documents,
/// letters, notes and scene pictures (instead of rounded app cards).
class PaperSheet extends StatelessWidget {
  const PaperSheet({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.xl),
    this.tilt = 0,
    this.color = AppColors.paperLight,
    this.lifted = true,
    this.ruled = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  /// Small rotation in radians, for a hand-placed look (keep under 0.03).
  final double tilt;
  final Color color;
  final bool lifted;

  /// A printed double hairline just inside the edge, like an official form
  /// or a book plate (ID card, evidence, reports).
  final bool ruled;

  @override
  Widget build(BuildContext context) {
    final onNight = InkSurface.isNight(context);
    final sheet = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.paper),
        border: Border.all(color: AppLine.faint(), width: AppLine.hairline),
        boxShadow: lifted ? (onNight ? AppShadow.onNight : AppShadow.paperLift) : null,
      ),
      foregroundDecoration: ruled ? const RuledFrame() : null,
      // Paper, even when laid on the night desk: ink widgets inside use paper ink.
      child: InkSurface(night: false, child: child),
    );
    return tilt == 0 ? sheet : Transform.rotate(angle: tilt, child: sheet);
  }
}

/// A bottom sheet as a sheet of paper (the map menu, a letter, the word card,
/// "Not quite!", the final case's notebook): nearly square top corners. Set
/// per sheet with `showDragHandle: false`, [PaperSheetTab] at its top — the
/// app's sheet theme is left as it is.
const paperSheetShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.paper)),
);

/// The thin ink tab at the top of a [paperSheetShape] sheet, in place of the
/// grey Material handle, in the handle's own 48 dp slot (so a sheet keeps
/// its height). The whole sheet still drags to close.
class PaperSheetTab extends StatelessWidget {
  const PaperSheetTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 32,
        height: 3,
        margin: const EdgeInsets.only(top: 22, bottom: 23),
        decoration: BoxDecoration(
          color: AppColors.inkBrown.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

/// A manila case folder: a labelled tab on top of a paper body.
class CaseFolder extends StatelessWidget {
  const CaseFolder({super.key, required this.tab, required this.child});

  final String tab;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final edge = BorderSide(color: AppLine.faint(0.3), width: AppLine.hairline);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(left: AppSpace.md),
          padding: const EdgeInsets.fromLTRB(AppSpace.md, 5, AppSpace.md, 3),
          decoration: BoxDecoration(
            color: AppColors.parchment,
            border: Border(top: edge, left: edge, right: edge),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.paper)),
          ),
          child: Text(tab, style: AppText.eyebrow(color: AppColors.inkBrown)),
        ),
        PaperSheet(color: AppColors.parchment, padding: EdgeInsets.zero, child: child),
      ],
    );
  }
}

/// A rubber-stamp mark ("SOLVED", "UNLOCKED"). Status colours belong here —
/// on a stamp, never as a filled card.
class InkStamp extends StatelessWidget {
  const InkStamp(this.text, {super.key, this.color = AppColors.burgundy, this.size = 16, this.tilt = -0.12});

  final String text;
  final Color color;
  final double size;
  final double tilt;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: tilt,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: size * 0.6, vertical: size * 0.25),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.paper),
          border: Border.all(color: color.withValues(alpha: 0.85), width: size / 8),
        ),
        child: Text(
          text,
          style: AppText.style(AppText.display, size: size, weight: FontWeight.w800, color: color.withValues(alpha: 0.9), letterSpacing: 2),
        ),
      ),
    );
  }
}

/// The printed double hairline just inside a page edge ([PaperSheet.ruled]).
class RuledFrame extends Decoration {
  const RuledFrame({this.color = AppColors.inkBrown, this.inset = 5});

  final Color color;
  final double inset;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _RuledFramePainter(color, inset);
}

class _RuledFramePainter extends BoxPainter {
  _RuledFramePainter(this.color, this.inset);

  final Color color;
  final double inset;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final r = (offset & configuration.size!).deflate(inset);
    final ink = Paint()
      ..color = color.withValues(alpha: 0.32)
      ..style = PaintingStyle.stroke
      ..strokeWidth = AppLine.hairline;
    canvas.drawRect(r, ink);
    canvas.drawRect(r.deflate(3), ink..strokeWidth = 0.5);
  }
}

/// A printer's rule under a title: two hairlines with a small diamond.
class OrnamentRule extends StatelessWidget {
  const OrnamentRule({super.key, this.color = AppColors.gold, this.width = 132});

  final Color color;
  final double width;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(width: width, height: 12, child: CustomPaint(painter: _OrnamentPainter(color))),
    );
  }
}

class _OrnamentPainter extends CustomPainter {
  _OrnamentPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final line = Paint()
      ..color = color.withValues(alpha: 0.7)
      ..strokeWidth = AppLine.hairline;
    canvas.drawLine(Offset(0, c.dy), Offset(c.dx - 13, c.dy), line);
    canvas.drawLine(Offset(c.dx + 13, c.dy), Offset(size.width, c.dy), line);
    final dot = Paint()..color = color;
    canvas.drawCircle(Offset(c.dx - 9, c.dy), 1.3, dot);
    canvas.drawCircle(Offset(c.dx + 9, c.dy), 1.3, dot);
    canvas.drawPath(
      Path()
        ..moveTo(c.dx, c.dy - 5)
        ..lineTo(c.dx + 4, c.dy)
        ..lineTo(c.dx, c.dy + 5)
        ..lineTo(c.dx - 4, c.dy)
        ..close(),
      dot,
    );
  }

  @override
  bool shouldRepaint(_OrnamentPainter old) => old.color != color;
}

/// The page heading used across the game: a small upper-case label, the
/// title, a printer's rule, and an optional quiet line below.
class PageHeading extends StatelessWidget {
  const PageHeading({super.key, this.eyebrow, required this.title, this.subtitle, this.titleSize = 26});

  final String? eyebrow;
  final String title;
  final String? subtitle;
  final double titleSize;

  @override
  Widget build(BuildContext context) {
    final night = InkSurface.isNight(context);
    return Column(
      children: [
        if (eyebrow != null) ...[
          Text(eyebrow!, textAlign: TextAlign.center, style: AppText.eyebrow(color: night ? AppColors.goldLight : AppColors.goldDeep)),
          const SizedBox(height: AppSpace.xs),
        ],
        Text(
          title,
          textAlign: TextAlign.center,
          style: AppText.title(size: titleSize, color: night ? AppColors.paperLight : AppColors.navy).copyWith(letterSpacing: 1),
        ),
        const SizedBox(height: AppSpace.sm),
        OrnamentRule(color: night ? AppColors.goldLight : AppColors.gold),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpace.sm),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: AppText.aside(color: night ? AppColors.goldLight.withValues(alpha: 0.85) : AppColors.muted),
          ),
        ],
      ],
    );
  }
}

/// A brass medallion with a glyph: the agency's emblem (title page, ID
/// card, notebook cover).
class BrassEmblem extends StatelessWidget {
  const BrassEmblem({super.key, this.size = 96, this.glyph});

  final double size;

  /// The picture in the middle; the magnifier by default.
  final Widget? glyph;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: const _EmblemPainter(),
        child: Center(child: glyph ?? _magnifier(size)),
      ),
    );
  }

  static Widget _magnifier(double size) => SizedBox.square(
        dimension: size * 0.42,
        child: CustomPaint(painter: _MagnifierPainter()),
      );
}

class _EmblemPainter extends CustomPainter {
  const _EmblemPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    // A pressed brass disc: rim, face and a fine inner ring of beads.
    canvas.drawCircle(c + const Offset(0, 2), r, Paint()..color = const Color(0x40000000));
    canvas.drawCircle(
      c,
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.goldLight, AppColors.gold, AppColors.goldDeep],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawCircle(c, r * 0.84, Paint()..color = AppColors.navy);
    final ring = Paint()
      ..color = AppColors.goldLight.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(c, r * 0.76, ring);
    final bead = Paint()..color = AppColors.goldDeep;
    for (var i = 0; i < 28; i++) {
      final a = i * 2 * 3.141592653589793 / 28;
      canvas.drawCircle(c + Offset.fromDirection(a, r * 0.92), r * 0.022, bead);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _MagnifierPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final glass = Offset(s * 0.42, s * 0.42);
    final rim = Paint()
      ..color = AppColors.goldLight
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.1;
    canvas.drawCircle(glass, s * 0.3, Paint()..color = AppColors.goldLight.withValues(alpha: 0.12));
    canvas.drawCircle(glass, s * 0.3, rim);
    canvas.drawLine(
      glass + Offset(s * 0.22, s * 0.22),
      Offset(s * 0.94, s * 0.94),
      rim
        ..strokeWidth = s * 0.15
        ..strokeCap = StrokeCap.round,
    );
    // A glint on the glass.
    canvas.drawArc(
      Rect.fromCircle(center: glass, radius: s * 0.19),
      3.6,
      1.0,
      false,
      Paint()
        ..color = AppColors.paperLight.withValues(alpha: 0.7)
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.05
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
