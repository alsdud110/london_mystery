import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_text.dart';
import '../core/theme/app_tokens.dart';
import '../core/utils/audio_service.dart';
import '../features/game/game_providers.dart';
import 'ink_icon.dart';
import 'paper_background.dart';

/// [navy] is the primary action on paper, [gold] the primary action on the
/// dark night screens, [outline] a secondary action. One primary per screen.
/// - [navy]: primary on paper. [gold]: primary on the night page.
/// - [outline]: secondary (paper ink, or gold ink on the night page).
/// - [glass]: primary over a full-screen painting: dark translucent navy
///   with a thin gold edge, so the picture stays first.
/// - [parchment]: primary over the storybook's opening paintings (the title
///   page, the season cover): a light parchment cover with an antique gold
///   edge and navy ink, like the label on a casebook's spine.
enum GameButtonStyle { navy, gold, outline, glass, parchment }

/// The casebook tap ([GameSound.uiTap]) at [role]'s level, for a tap that
/// is not a [GameButton] (choosing a case from a list).
void playUiTap(BuildContext context, TapRole role) =>
    ProviderScope.containerOf(context, listen: false).read(audioServiceProvider).play(GameSound.uiTap, volume: role.volume);

/// Large, flat, kid-friendly button ("INVESTIGATE →"). Silent unless given
/// a [tap]: only the buttons that move the investigation on tap the
/// casebook. A button that does something in the story (CHECK ANSWER,
/// UNLOCK, a stamp, a letter) plays that thing's sound where it is handled,
/// and no tap with it; Back, Close and the story's own taps stay quiet.
class GameButton extends StatefulWidget {
  const GameButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.semanticLabel,
    this.style = GameButtonStyle.navy,
    this.glyph,
    this.arrow = false,
    this.singleLine = false,
    this.expand = true,
    this.tap,
  });

  final String label;
  final VoidCallback? onPressed;

  /// What a screen reader says when the short [label] needs its context
  /// ("GO" on the map is "GO TO KING'S CROSS"). Defaults to [label].
  final String? semanticLabel;
  final GameButtonStyle style;
  final InkGlyph? glyph;

  /// Shows a trailing ink arrow: the button moves the story forward.
  final bool arrow;

  /// Fixed size whatever the label: one line, fixed height, the arrow always
  /// in the same place. Long labels shrink slightly to fit instead of
  /// wrapping (e.g. "GO TO BUCKINGHAM PALACE").
  final bool singleLine;
  final bool expand;

  /// The casebook tap this button makes when pressed (null: silent).
  final TapRole? tap;

  @override
  State<GameButton> createState() => _GameButtonState();
}

class _GameButtonState extends State<GameButton> with TickerProviderStateMixin {
  bool _pressed = false;

  /// The ready navy button catches the eye: it floats, lifting a little off
  /// the page and settling, slowly, [_bobs] times, its shadow left on the
  /// page below (fainter and wider as it rises), a soft brass glint
  /// ([_glint]) crossing it on every lift; then it rests on the page a
  /// moment. While it rests it waits on a timer, not on frames.
  late final AnimationController _float = AnimationController(vsync: this, duration: _bob * _bobs);
  late final Animation<double> _glint =
      _float.drive(CurveTween(curve: const _GlintOnLift(bobs: _bobs, bob: _bob, sweep: _glintSweep)));
  Timer? _floatWait;
  static const _bob = Duration(milliseconds: 2400);
  static const _bobs = 3;
  static const _glintSweep = Duration(milliseconds: 700);
  static const _floatRest = Duration(milliseconds: 1200);
  static const _floatFirst = Duration(milliseconds: 600);

  /// How far it lifts at the top of a bob.
  static const _lift = 2.0;

  bool get _enabled => widget.onPressed != null;

  bool get _floats =>
      widget.style == GameButtonStyle.navy && _enabled && !(MediaQuery.maybeDisableAnimationsOf(context) ?? false);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncFloat();
  }

  @override
  void didUpdateWidget(GameButton old) {
    super.didUpdateWidget(old);
    _syncFloat();
  }

  @override
  void dispose() {
    _floatWait?.cancel();
    _float.dispose();
    super.dispose();
  }

  void _syncFloat() {
    if (!_floats) {
      _floatWait?.cancel();
      _floatWait = null;
      _float.reset();
    } else if (_floatWait == null && !_float.isAnimating) {
      _floatWait = Timer(_floatFirst, _rise);
    }
  }

  void _rise() {
    if (!mounted || !_floats) {
      _floatWait = null;
      return;
    }
    _float.forward(from: 0).whenCompleteOrCancel(() {
      if (!mounted) return;
      _float.reset();
      _floatWait = _floats ? Timer(_floatRest, _rise) : null;
    });
  }

  /// How high it is now, 0 (on the page) to 1 (the top of a bob): eased,
  /// so it lingers at the top and bottom.
  double get _height => (1 - math.cos(2 * math.pi * _bobs * _float.value)) / 2;

  void _onTap() {
    final tap = widget.tap;
    if (tap != null) playUiTap(context, tap);
    widget.onPressed?.call();
  }

  void _setPressed(bool value) {
    if (_enabled && _pressed != value) setState(() => _pressed = value);
  }

  /// Labels are actions: set in the reading face (Sentient), never in the
  /// display face that names the world.
  TextStyle _label(Color color) =>
      AppText.style(AppText.body, size: 16.5, weight: FontWeight.w600, color: color, letterSpacing: 1.6, height: 1.2);

  @override
  Widget build(BuildContext context) {
    // Fill, ink, outer edge, the printed inner rule, and the pressed-in
    // edge underneath (null: flat, it does not stand off the page).
    var (bg, fg, border, rule, depth) = switch (widget.style) {
      GameButtonStyle.navy => (
          AppColors.navy,
          AppColors.paperLight,
          AppColors.navyDeep,
          AppColors.goldLight.withValues(alpha: 0.35),
          AppColors.navyDeep as Color?,
        ),
      GameButtonStyle.gold => (
          AppColors.goldLight,
          AppColors.navyDeep,
          AppColors.goldDeep,
          AppColors.navyDeep.withValues(alpha: 0.28),
          AppColors.goldDeep as Color?,
        ),
      GameButtonStyle.glass => (
          AppColors.navyDeep.withValues(alpha: 0.48),
          // A touch brighter than the painting's lights, so it reads as a
          // button at first glance (no glow, no extra shadow).
          Color.lerp(AppColors.goldLight, AppColors.paperLight, 0.2)!,
          AppColors.goldLight.withValues(alpha: 0.92),
          AppColors.goldLight.withValues(alpha: 0.32),
          null,
        ),
      // Stands on a gold edge and presses into it, as the navy button does.
      GameButtonStyle.parchment => (
          AppColors.paper,
          AppColors.navy,
          AppColors.gold,
          AppColors.gold.withValues(alpha: 0.55),
          AppColors.goldDeep as Color?,
        ),
      // Ink on paper; gold ink on the navy night background, where dark
      // ink would disappear (e.g. "OPEN MY NOTEBOOK" in the final case).
      GameButtonStyle.outline =>
        InkSurface.isNight(context)
            ? (
                Colors.transparent,
                AppColors.goldLight,
                AppColors.goldLight.withValues(alpha: 0.7),
                AppColors.goldLight.withValues(alpha: 0.3),
                null,
              )
            : (
                AppColors.paperLight.withValues(alpha: 0.55),
                AppColors.ink,
                AppLine.faint(0.45),
                AppLine.faint(0.22),
                null,
              ),
    };
    // Not ready yet (e.g. no answer chosen): a faint pencilled outline
    // instead of a grey block, so it does not draw the eye.
    if (!_enabled && widget.style == GameButtonStyle.navy) {
      (bg, fg, border, rule, depth) = (Colors.transparent, AppColors.navy, AppLine.faint(0.35), AppLine.faint(0.15), null);
    }
    const depthPx = 3.0;
    final raised = depth != null;

    const arrowBox = AppIconSize.medium + AppSpace.md;
    final content = widget.singleLine
        ? Row(
            children: [
              // Balances the arrow so the label stays centred.
              if (widget.arrow && widget.glyph == null) const SizedBox(width: arrowBox),
              if (widget.glyph != null) ...[
                InkIcon(widget.glyph!, size: AppIconSize.medium, color: fg),
                const SizedBox(width: AppSpace.md),
              ],
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(widget.label, maxLines: 1, style: _label(fg).copyWith(letterSpacing: 1.2)),
                ),
              ),
              if (widget.arrow) ...[
                const SizedBox(width: AppSpace.md),
                InkIcon(InkGlyph.arrow, size: AppIconSize.medium, color: fg),
              ],
            ],
          )
        : Row(
            mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.glyph != null) ...[
                InkIcon(widget.glyph!, size: AppIconSize.medium, color: fg),
                const SizedBox(width: AppSpace.md),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: _label(fg),
                ),
              ),
              if (widget.arrow) ...[
                const SizedBox(width: AppSpace.md),
                InkIcon(InkGlyph.arrow, size: AppIconSize.medium, color: fg),
              ],
            ],
          );

    // A raised button stands on a darker edge and presses down into it; the
    // box keeps the same size, so nothing around it moves. A floating one's
    // shadow is drawn by the float instead (left on the page below it).
    final face = Container(
      constraints: widget.singleLine
          ? const BoxConstraints.tightFor(height: 56)
          : const BoxConstraints(minHeight: 56),
      decoration: raised
          ? BoxDecoration(
              color: depth,
              borderRadius: BorderRadius.circular(AppRadius.button),
              boxShadow: _pressed || _floats ? null : const [BoxShadow(color: _shadow, blurRadius: 8, offset: Offset(0, 4))],
            )
          : null,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 70),
        padding: EdgeInsets.only(
          top: raised && _pressed ? depthPx : 0,
          bottom: raised && !_pressed ? depthPx : 0,
        ),
        child: CustomPaint(
          foregroundPainter: _floats ? _Glint(_glint) : null,
          child: Container(
            constraints: widget.singleLine ? const BoxConstraints.expand() : const BoxConstraints(minHeight: 56 - depthPx),
            padding: EdgeInsets.symmetric(
              horizontal: widget.singleLine ? AppSpace.lg : AppSpace.xl,
              vertical: widget.singleLine ? 0 : AppSpace.md + 2,
            ),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(color: border, width: AppLine.hairline),
            ),
            // The printed inner rule: an engraved ticket, not a web button.
            foregroundDecoration: _InnerRule(rule),
            child: content,
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.semanticLabel ?? widget.label,
      excludeSemantics: true,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapCancel: () => _setPressed(false),
        onTapUp: (_) => _setPressed(false),
        onTap: _enabled ? _onTap : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: !_enabled ? 0.5 : 1,
          child: _floats ? AnimatedBuilder(animation: _float, builder: (context, child) => _floating(child!), child: face) : face,
        ),
      ),
    );
  }

  static const _shadow = Color(0x332A2622);

  /// [face] lifted by the float; its shadow stays on the page, fainter and
  /// wider the higher the button is (none while pressed in).
  Widget _floating(Widget face) {
    final h = _pressed ? 0.0 : _height;
    return Transform.translate(
      offset: Offset(0, -_lift * h),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.button),
          boxShadow: _pressed
              ? null
              : [
                  BoxShadow(
                    color: _shadow.withValues(alpha: _shadow.a * (1 - 0.35 * h)),
                    blurRadius: 8 + 5 * h,
                    offset: Offset(0, 4 + _lift * h + 1.5 * h),
                  ),
                ],
        ),
        child: face,
      ),
    );
  }
}

/// A quiet ink text action with an optional glyph ("Letter", "Get a tip").
class InkTextButton extends StatelessWidget {
  const InkTextButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.glyph,
    this.color = AppColors.royalBlue,
  });

  final String label;
  final VoidCallback? onPressed;
  final InkGlyph? glyph;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Disabled (e.g. Undo with nothing to undo): the ink greys out, so it
    // does not look like it can be tapped.
    final ink = onPressed == null ? AppColors.locked : color;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        foregroundColor: color,
        disabledForegroundColor: AppColors.locked,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (glyph != null) ...[
            InkIcon(glyph!, size: AppIconSize.small, color: ink),
            const SizedBox(width: AppSpace.sm),
          ],
          Flexible(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: AppText.button(size: 15, color: ink).copyWith(letterSpacing: 0.3),
            ),
          ),
        ],
      ),
    );
  }
}

/// A small button for a choice inside a dialog (about 44 high, 104 to 140
/// wide): [primary] is navy, the other paper with a fine rule. Flat, so the
/// dialog's own content (a price, a question) leads, not its buttons.
class CompactButton extends StatelessWidget {
  const CompactButton({super.key, required this.label, required this.onPressed, this.primary = false, this.semanticLabel});

  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ink = primary ? AppColors.paperLight : AppColors.navy;
    return Semantics(
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      button: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 104, maxWidth: 140, minHeight: 44),
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            minimumSize: const Size(104, 44),
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.sm),
            backgroundColor: primary ? AppColors.navy : AppColors.paperLight,
            foregroundColor: ink,
            overlayColor: primary ? AppColors.paperLight : AppColors.navy,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.button),
              side: primary ? BorderSide.none : BorderSide(color: AppLine.faint(0.35), width: AppLine.hairline),
            ),
          ),
          // One line always: a large text size scales it down, never cuts it.
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: AppText.button(size: 14, color: ink).copyWith(letterSpacing: 1.2),
            ),
          ),
        ),
      ),
    );
  }
}

/// A soft band of brass light crossing a ready navy [GameButton]'s face on a
/// slant, left to right, as [progress] runs (nothing at rest).
class _Glint extends CustomPainter {
  _Glint(this.progress) : super(repaint: progress);

  final Animation<double> progress;

  @override
  void paint(Canvas canvas, Size size) {
    final t = progress.value;
    if (t <= 0 || t >= 1) return;
    final face = Offset.zero & size;
    final band = face.width * 0.4;
    final x = face.left - band + (face.width + 2 * band) * Curves.easeInOut.transform(t);
    final glow = AppColors.goldLight.withValues(alpha: 0.32);
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(face, const Radius.circular(AppRadius.button)));
    canvas.drawRect(
      face,
      Paint()
        ..shader = LinearGradient(
          colors: [glow.withValues(alpha: 0), glow, glow.withValues(alpha: 0)],
          transform: const GradientRotation(-0.35),
        ).createShader(Rect.fromLTWH(x - band / 2, face.top, band, face.height)),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Glint old) => old.progress != progress;
}

/// Where a floating [GameButton]'s glint is in its sweep, from how far the
/// float has run: it crosses the face once on each of the [bobs] lifts,
/// [sweep] long and centred on the rise (the first half of each [bob]).
class _GlintOnLift extends Curve {
  const _GlintOnLift({required this.bobs, required this.bob, required this.sweep});

  final int bobs;
  final Duration bob;
  final Duration sweep;

  @override
  double transformInternal(double t) {
    final intoBob = (t * bobs % 1) * bob.inMicroseconds;
    final start = (bob.inMicroseconds / 2 - sweep.inMicroseconds) / 2;
    return ((intoBob - start) / sweep.inMicroseconds).clamp(0.0, 1.0);
  }
}

/// The hairline printed just inside a [GameButton]'s edge.
class _InnerRule extends Decoration {
  const _InnerRule(this.color);

  final Color color;

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _InnerRulePainter(color);
}

class _InnerRulePainter extends BoxPainter {
  _InnerRulePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final r = RRect.fromRectAndRadius((offset & configuration.size!).deflate(4), const Radius.circular(AppRadius.button - 3));
    canvas.drawRRect(
      r,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppLine.hairline,
    );
  }
}
