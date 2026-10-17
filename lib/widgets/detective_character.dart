import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_tokens.dart';
import '../data/models/profile.dart';
import '../features/game/game_providers.dart';
import 'art_assets.dart';
import 'ink_icon.dart';

/// How the detective is shown.
enum DetectiveStyle {
  /// In a gold medallion, as the witnesses are shown: small places (by a
  /// button, on a slip, on a sheet).
  portrait,

  /// The whole picture — face, hands and what they hold — at its own
  /// ratio, its cut-off foot melting into the page: the moments that are
  /// the detective's (a find, a solve, the case closed).
  illustration,
}

/// The moments of play where the player's own detective shows, each with
/// its expression and the way it is shown. The detective is the player,
/// never a partner: it reacts to what the player just did, it never tells
/// the answer.
enum DetectiveMoment {
  /// Setting out to search a place (beside INVESTIGATE / the search's start).
  investigate(DetectiveExpression.investigating, DetectiveStyle.portrait),

  /// "Not quite!": looking again, a hint within reach.
  lookAgain(DetectiveExpression.thinking, DetectiveStyle.portrait),

  /// A mission's puzzle put new evidence or a new clue in hand.
  newFind(DetectiveExpression.surprised, DetectiveStyle.illustration),

  /// A mission solved (any other discovery).
  missionSolved(DetectiveExpression.happy, DetectiveStyle.illustration),

  /// The whole case solved (Case Closed).
  caseSolved(DetectiveExpression.confident, DetectiveStyle.illustration);

  const DetectiveMoment(this.expression, this.style);

  final DetectiveExpression expression;

  /// How the moment shows the detective where it has the room.
  final DetectiveStyle style;
}

/// Which [DetectiveMoment]s show the detective: the one switch for every
/// screen. Take a moment out of [shown] and its screen goes back to how it
/// was, with no gap left behind.
abstract final class DetectiveCast {
  static const shown = {
    DetectiveMoment.investigate,
    DetectiveMoment.lookAgain,
    DetectiveMoment.newFind,
    DetectiveMoment.missionSolved,
    DetectiveMoment.caseSolved,
  };

  static bool shows(DetectiveMoment moment) => shown.contains(moment);
}

/// The player's detective in the [expression] picture.
///
/// [DetectiveStyle.portrait]: a gold medallion [size] across inside the
/// rim, cut round the face and hands ([ArtAssets.detectiveCrop]).
/// [DetectiveStyle.illustration]: the whole picture [size] tall at its own
/// ratio, never cropped; its lower edge fades out (the picture is cut off
/// at the waist), so the detective stands in the scene.
///
/// [entrance]: comes in once as it appears — a short fade and settle (none
/// with reduced motion); off when the screen times the entrance itself.
/// [halo]: warm lamplight behind (and, on a medallion, a second fine ring).
/// [semanticLabel]: what a screen reader says; none, it is decoration.
class DetectiveCharacter extends StatelessWidget {
  const DetectiveCharacter({
    super.key,
    required this.avatar,
    required this.expression,
    this.style = DetectiveStyle.portrait,
    this.size = 64,
    this.entrance = true,
    this.halo = false,
    this.semanticLabel,
  });

  /// Null: a detective made before avatars existed (shown as the boy).
  final DetectiveAvatar? avatar;
  final DetectiveExpression expression;
  final DetectiveStyle style;
  final double size;
  final bool entrance;
  final bool halo;
  final String? semanticLabel;

  /// The gold rim round a medallion.
  static const rim = 3.0;

  /// A medallion's whole width, rim (and halo ring) included.
  static double extent(double size, {bool halo = false}) => size + 2 * rim + (halo ? 2 * _haloGap : 0);

  /// An illustration's width at [height] (the picture's own ratio).
  static double illustrationWidth(DetectiveAvatar? avatar, DetectiveExpression expression, double height) =>
      height * ArtAssets.detectiveCrop(avatar, expression).pixels.aspectRatio;

  static const _haloGap = 6.0;

  @override
  Widget build(BuildContext context) {
    final picture = switch (style) {
      DetectiveStyle.portrait => _medallion(),
      DetectiveStyle.illustration => _Illustration(avatar: avatar, expression: expression, height: size, glow: halo),
    };
    final keyed = KeyedSubtree(
      key: ValueKey('detective-${(avatar ?? DetectiveAvatar.boy).name}-${expression.name}'),
      child: picture,
    );
    final shown = semanticLabel == null
        ? ExcludeSemantics(child: keyed)
        : Semantics(image: true, label: semanticLabel, excludeSemantics: true, child: keyed);
    if (!entrance) return shown;
    final still = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: still ? 1 : 0, end: 1),
      duration: still ? Duration.zero : const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 6 * (1 - t)),
          child: Transform.scale(scale: 0.92 + 0.08 * t, child: child),
        ),
      ),
      child: shown,
    );
  }

  Widget _medallion() {
    Widget medallion = Container(
      padding: const EdgeInsets.all(rim),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.goldLight,
        border: Border.all(color: AppColors.goldDeep, width: 1.2),
        boxShadow: AppShadow.paperLift,
      ),
      child: ClipOval(
        child: SizedBox.square(
          dimension: size,
          child: DecoratedBox(
            // Its edge faded into parchment, as an old printed portrait.
            position: DecorationPosition.foreground,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [AppColors.parchment.withValues(alpha: 0), AppColors.parchment.withValues(alpha: 0.85)],
                stops: const [0.8, 1],
              ),
            ),
            child: ColoredBox(
              // Behind the cut-out: the print's paper.
              color: AppColors.parchment,
              child: _Cut(avatar: avatar, expression: expression, size: size),
            ),
          ),
        ),
      ),
    );
    if (halo) {
      medallion = DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Lamplight behind the medallion: warm, low, no glare.
          gradient: RadialGradient(
            colors: [AppColors.goldLight.withValues(alpha: 0.32), AppColors.goldLight.withValues(alpha: 0)],
            stops: const [0.62, 1],
          ),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.7), width: AppLine.hairline),
        ),
        child: Padding(padding: const EdgeInsets.all(_haloGap), child: medallion),
      );
    }
    return medallion;
  }
}

/// The whole picture, [height] tall at its own ratio. Its lower fifth fades
/// out (the drawing stops at the waist); [glow]: soft lamplight behind the
/// head, for a dark page. A missing file leaves the detective's cap.
class _Illustration extends StatelessWidget {
  const _Illustration({required this.avatar, required this.expression, required this.height, required this.glow});

  final DetectiveAvatar? avatar;
  final DetectiveExpression expression;
  final double height;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final width = DetectiveCharacter.illustrationWidth(avatar, expression, height);
    final pixels = ArtAssets.detectiveCrop(avatar, expression).pixels;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final figure = ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.black, Colors.black, Colors.transparent],
        stops: [0, 0.78, 1],
      ).createShader(rect),
      child: Image.asset(
        ArtAssets.detective(avatar, expression),
        width: width,
        height: height,
        fit: BoxFit.contain,
        cacheWidth: math.min((width * dpr).ceil(), pixels.width.toInt()),
        excludeFromSemantics: true,
        gaplessPlayback: true,
        errorBuilder: (context, error, stack) => SizedBox(
          width: width,
          height: height,
          child: Center(
            child: InkIcon(
              InkGlyph.deerstalker,
              size: height * 0.35,
              color: AppColors.goldLight.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (glow)
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    // Gone before the box's edge: no square of light.
                    center: const Alignment(0, -0.15),
                    radius: 0.5,
                    colors: [AppColors.goldLight.withValues(alpha: 0.22), AppColors.goldLight.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
          figure,
        ],
      ),
    );
  }
}

/// The picture placed so its medallion circle fills [size] exactly, decoded
/// no larger than it shows. A missing file shows the detective's cap.
class _Cut extends StatelessWidget {
  const _Cut({required this.avatar, required this.expression, required this.size});

  final DetectiveAvatar? avatar;
  final DetectiveExpression expression;
  final double size;

  @override
  Widget build(BuildContext context) {
    final crop = ArtAssets.detectiveCrop(avatar, expression);
    final scale = size / (2 * crop.radius);
    final width = crop.pixels.width * scale;
    final height = crop.pixels.height * scale;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: [
        Positioned(
          left: size / 2 - crop.centre.dx * scale,
          top: size / 2 - crop.centre.dy * scale,
          width: width,
          height: height,
          child: Image.asset(
            ArtAssets.detective(avatar, expression),
            fit: BoxFit.fill,
            cacheWidth: math.min((width * dpr).ceil(), crop.pixels.width.toInt()),
            excludeFromSemantics: true,
            gaplessPlayback: true,
            errorBuilder: (context, error, stack) => SizedBox(
              width: width,
              height: height,
              child: Align(
                alignment: Alignment(
                  (crop.centre.dx / crop.pixels.width) * 2 - 1,
                  (crop.centre.dy / crop.pixels.height) * 2 - 1,
                ),
                child: InkIcon(InkGlyph.deerstalker, size: size * 0.55, color: AppColors.inkBrown),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// [DetectiveCharacter] as the player chose them: follows the saved profile,
/// so a new picture chosen in the detective's settings shows at once.
/// Shown as [moment] shows it unless [style] says otherwise (a small
/// place). Shows nothing when [moment] is switched off ([DetectiveCast]).
class PlayerDetective extends ConsumerWidget {
  const PlayerDetective({
    super.key,
    required this.moment,
    this.style,
    this.size = 64,
    this.entrance = true,
    this.halo = false,
    this.semanticLabel,
  });

  final DetectiveMoment moment;
  final DetectiveStyle? style;
  final double size;
  final bool entrance;
  final bool halo;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!DetectiveCast.shows(moment)) return const SizedBox.shrink();
    final avatar = ref.watch(detectiveProfileProvider.select((p) => p.avatar));
    return DetectiveCharacter(
      avatar: avatar,
      expression: moment.expression,
      style: style ?? moment.style,
      size: size,
      entrance: entrance,
      halo: halo,
      semanticLabel: semanticLabel,
    );
  }
}

/// [child] (a page's one action) with the player's detective beside it in
/// a medallion, no taller than the button (the row keeps the button's
/// height): e.g. the detective with the magnifying glass by INVESTIGATE.
/// Just [child] when [moment] is switched off.
class WithPlayerDetective extends StatelessWidget {
  const WithPlayerDetective({super.key, required this.moment, required this.child, this.size = 42});

  final DetectiveMoment moment;
  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (!DetectiveCast.shows(moment)) return child;
    return Row(
      children: [
        PlayerDetective(moment: moment, style: DetectiveStyle.portrait, size: size),
        const SizedBox(width: AppSpace.md),
        Expanded(child: child),
      ],
    );
  }
}
