import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../core/theme/app_tokens.dart';
import '../features/game/scoring.dart';
import 'art_assets.dart';
import 'game_button.dart';
import 'ink_icon.dart';
import 'paper.dart';

/// A round medal for a [GameBadge], the one way a badge is drawn.
///
/// Earned: the badge's own medal picture ([ArtAssets.badges]), in full
/// colour. Still to win: the empty rosette ([ArtAssets.badgeFrame]), greyed,
/// with a lock — every locked badge looks the same, so its emblem stays a
/// surprise and only its name and description say what is still to discover.
/// A missing picture falls back to the medal drawn in code.
class BadgeMedal extends StatelessWidget {
  const BadgeMedal({
    super.key,
    required this.badge,
    this.earned = true,
    this.size = 64,
    this.showLabel = true,
    this.labelWidth,
    this.labelGap = 0,
    this.caption,
    this.captionLines = 2,
  });

  final GameBadge badge;
  final bool earned;
  final double size;
  final bool showLabel;

  /// The width of the name and description (default: a little wider than
  /// the medal). A grid passes its cell width.
  final double? labelWidth;

  /// Space between the name and the description.
  final double labelGap;

  /// The line under the name (default: the badge's whole description). The
  /// notebook's grid passes the short one ([BadgeCaption.shortDescription]).
  final String? caption;

  /// The lines the description always takes (and at most shows), so
  /// medals line up whatever their text.
  final int captionLines;

  /// What a screen reader says: "First Clue, earned", "Puzzle Solver,
  /// locked", "Sharp Eyes, retired, earned".
  String get semanticLabel => [badge.title, if (badge.retired) 'retired', earned ? 'earned' : 'locked'].join(', ');

  /// The badge's state as printed on its details: EARNED, LOCKED or
  /// RETIRED · EARNED.
  static String statusOf(GameBadge badge, {required bool earned}) =>
      [if (badge.retired) 'RETIRED', earned ? 'EARNED' : 'LOCKED'].join(' · ');

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox.square(
            dimension: size,
            child: earned ? _EarnedMedal(badge: badge, size: size) : _LockedMedal(size: size),
          ),
          // The name always takes two lines, so every description starts at
          // the same height whether the name wraps or not.
          if (showLabel) ...[
            const SizedBox(height: 6),
            _LinesText(
              badge.title,
              lines: 2,
              width: labelWidth ?? size + 36,
              style: AppText.button(size: 13, color: earned ? AppColors.navy : AppColors.muted),
            ),
            SizedBox(height: labelGap),
            _LinesText(
              caption ?? badge.description,
              lines: captionLines,
              width: labelWidth ?? size + 36,
              style: AppText.caption(),
            ),
          ],
        ],
      ),
    );
  }
}

/// The short Korean line under a badge in the notebook's grid: one line on a
/// small phone. Its whole description ([GameBadge.description]) is on its
/// details. Display only: a badge's id and award never depend on it.
extension BadgeCaption on GameBadge {
  String get shortDescription => switch (this) {
        GameBadge.firstClue => '첫 단서 발견',
        GameBadge.sharpEyes => '이전 버전 배지',
        GameBadge.quickThinker => '이전 버전 배지',
        GameBadge.puzzleSolver => '퍼즐 3개 해결',
        GameBadge.londonExplorer => '모든 장소 방문',
        GameBadge.masterDetective => '사건 해결 완료',
        GameBadge.clockWatcher => '시계 비밀 해결',
        GameBadge.evidenceHunter => '숨은 단서 추적',
        GameBadge.letterReader => '비밀 편지 해결',
        GameBadge.codeBreaker => '암호 해독 성공',
        GameBadge.mapMaster => '지도 완성',
        GameBadge.londonLegend => '시즌 1 완료',
        GameBadge.secondLook => '단서 다시 확인',
        GameBadge.notebookExplorer => '수첩 증거 확인',
        GameBadge.wordCollector => '단어 3개 확인',
      };
}

/// The details of [badge] on a sheet of paper: the medal large, its name,
/// its whole description and its state. A badge still to win keeps its lock
/// (its picture stays hidden here too). Closes with CLOSE, Back, a tap
/// outside or a drag; the page under it stays where it was.
Future<void> showBadgeDetails(BuildContext context, GameBadge badge, {required bool earned}) {
  final status = BadgeMedal.statusOf(badge, earned: earned);
  return showModalBottomSheet<void>(
    context: context,
    // The word card's sheet: nearly square corners, the ink tab on top.
    shape: paperSheetShape,
    showDragHandle: false,
    // As tall as its content, scrolling only if large text needs it.
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const PaperSheetTab(),
            // Its name and state are read below: the picture is not read.
            ExcludeSemantics(child: BadgeMedal(badge: badge, earned: earned, size: 132, showLabel: false)),
            const SizedBox(height: AppSpace.md),
            Text(badge.title, textAlign: TextAlign.center, style: AppText.title(size: 26)),
            const SizedBox(height: AppSpace.sm),
            const OrnamentRule(),
            const SizedBox(height: AppSpace.sm),
            Text(badge.description, textAlign: TextAlign.center, style: AppText.letter(size: 17, color: AppColors.ink)),
            const SizedBox(height: AppSpace.md),
            Semantics(
              label: status.toLowerCase().replaceAll(' · ', ', '),
              excludeSemantics: true,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  InkIcon(
                    earned ? InkGlyph.check : InkGlyph.lock,
                    size: AppIconSize.small,
                    color: earned ? AppColors.goldDeep : AppColors.muted,
                  ),
                  const SizedBox(width: AppSpace.xs),
                  Flexible(child: Text(status, style: AppText.eyebrow(color: earned ? AppColors.goldDeep : AppColors.muted))),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GameButton(label: 'CLOSE', onPressed: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    ),
  );
}

/// An earned badge: its medal picture as delivered (rosette, face and emblem
/// in one), or the medal drawn in code while the file is missing.
class _EarnedMedal extends StatelessWidget {
  const _EarnedMedal({required this.badge, required this.size});

  final GameBadge badge;
  final double size;

  @override
  Widget build(BuildContext context) {
    // A pressed award rosette: scalloped brass edge, an enamel face in the
    // badge's colour and a fine gold ring, its glyph on the face.
    final drawn = Container(
      alignment: Alignment.center,
      decoration: _RosetteDecoration(earned: true, face: badge.color),
      child: InkMark(
        glyph: badge.glyph,
        monogram: badge.title.substring(0, 1),
        size: size * 0.5,
        color: AppColors.paperLight,
      ),
    );
    final asset = ArtAssets.badges[badge];
    return asset == null ? drawn : _MedalPicture(asset: asset, size: size, fallback: drawn);
  }
}

/// A badge still to win: the empty rosette, greyed and faded, with a lock on
/// its face (a pencil outline of the rosette while the file is missing).
class _LockedMedal extends StatelessWidget {
  const _LockedMedal({required this.size});

  final double size;

  /// Greyscale (luminance), at 45% of the picture's own opacity.
  static const _faded = ColorFilter.matrix([
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0.2126, 0.7152, 0.0722, 0, 0, //
    0, 0, 0, 0.45, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Positioned.fill(
          child: _MedalPicture(
            asset: ArtAssets.badgeFrame,
            size: size,
            filter: _faded,
            fallback: const DecoratedBox(decoration: _RosetteDecoration(earned: false, face: AppColors.locked)),
          ),
        ),
        InkIcon(InkGlyph.lock, size: size * 0.4, color: AppColors.locked),
      ],
    );
  }
}

/// A square medal picture at [size], decoded at the pixels the screen needs
/// (the files are far larger), whole and undistorted. Decorative: the medal
/// speaks through [BadgeMedal]'s label.
class _MedalPicture extends StatelessWidget {
  const _MedalPicture({required this.asset, required this.size, required this.fallback, this.filter});

  final String asset;
  final double size;
  final Widget fallback;
  final ColorFilter? filter;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      cacheWidth: math.min((size * MediaQuery.devicePixelRatioOf(context)).ceil(), ArtAssets.badgePixels.width.toInt()),
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true,
      // The filter is for the picture only, not for the drawing below.
      frameBuilder: filter == null
          ? null
          : (context, child, frame, sync) => ColorFiltered(colorFilter: filter!, child: child),
      errorBuilder: (context, error, stack) => fallback, // a missing file keeps the drawing
    );
  }
}

/// Text that always takes the height of [lines] lines, so medals line up at
/// the same size whether a label wraps or not (at any text scale).
class _LinesText extends StatelessWidget {
  const _LinesText(this.text, {required this.lines, required this.width, required this.style});

  final String text;
  final int lines;
  final double width;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Opacity(opacity: 0, child: Text('\n' * (lines - 1), style: style)), // reserves the lines
          Text(text, textAlign: TextAlign.center, maxLines: lines, overflow: TextOverflow.ellipsis, style: style),
        ],
      ),
    );
  }
}

/// Smoothly counts from the previous value to [value] ("340 XP").
class XpCounter extends StatelessWidget {
  const XpCounter({super.key, required this.value, this.style, this.suffix = ' XP'});

  final int value;
  final TextStyle? style;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(end: value),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Text(
        '$v$suffix',
        style: (style ?? AppText.button(size: 14, color: Colors.white)).copyWith(
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

class _RosetteDecoration extends Decoration {
  const _RosetteDecoration({required this.earned, required this.face});

  final bool earned;
  final Color face;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _RosettePainter(earned, face);
}

class _RosettePainter extends BoxPainter {
  _RosettePainter(this.earned, this.face);

  final bool earned;
  final Color face;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final size = configuration.size!;
    final c = offset + size.center(Offset.zero);
    final r = size.shortestSide / 2;

    // The scalloped edge: 18 small bumps around the disc.
    const bumps = 18;
    final edge = Path();
    for (var i = 0; i <= bumps * 8; i++) {
      final a = i * 2 * math.pi / (bumps * 8);
      final rr = r * (0.93 + 0.07 * math.cos(a * bumps).abs());
      final p = c + Offset(math.cos(a) * rr, math.sin(a) * rr);
      i == 0 ? edge.moveTo(p.dx, p.dy) : edge.lineTo(p.dx, p.dy);
    }
    edge.close();

    if (!earned) {
      canvas.drawPath(edge, Paint()..color = AppColors.parchment);
      canvas.drawPath(
        edge,
        Paint()
          ..color = AppColors.parchmentDark
          ..style = PaintingStyle.stroke
          ..strokeWidth = AppLine.rule,
      );
      return;
    }
    canvas.drawPath(edge.shift(Offset(0, r * 0.05)), Paint()..color = const Color(0x332A2622));
    canvas.drawPath(
      edge,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.goldLight, AppColors.gold, AppColors.goldDeep],
        ).createShader(Rect.fromCircle(center: c, radius: r)),
    );
    canvas.drawCircle(c, r * 0.76, Paint()..color = face);
    canvas.drawCircle(
      c,
      r * 0.68,
      Paint()
        ..color = AppColors.goldLight.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(0.8, r / 40),
    );
  }
}
