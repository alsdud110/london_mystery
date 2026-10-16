import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/audio_service.dart';
import '../../widgets/game_button.dart';
import '../../widgets/art_assets.dart';
import '../../widgets/game_dialog.dart';
import '../../widgets/ink_icon.dart';
import '../../widgets/paper.dart';
import '../../widgets/paper_background.dart';
import '../account/account_controller.dart';
import '../game/game_controller.dart';
import '../game/game_providers.dart';
import '../game_master/parent_gate.dart';
import 'how_to_play_state.dart';

/// Title page of the storybook: the name of the game, London, and one way in.
class StartScreen extends ConsumerStatefulWidget {
  const StartScreen({super.key});

  @override
  ConsumerState<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends ConsumerState<StartScreen> with TickerProviderStateMixin {
  /// The title comes in only the first time the app shows it.
  static bool _introduced = false;

  /// The words and the button coming in (about a second).
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));

  /// The office, barely alive — only noticed by someone who stays a while:
  /// a camera drifting towards the window and back, rain on the glass, the
  /// lamp's light breathing. [_ambientIn] fades them in.
  late final AnimationController _push = AnimationController(vsync: this, duration: const Duration(seconds: 14));
  late final AnimationController _rain = AnimationController(vsync: this, duration: const Duration(milliseconds: 7200));
  late final AnimationController _lamp = AnimationController(vsync: this, duration: const Duration(milliseconds: 4200));
  late final AnimationController _ambientIn = AnimationController(vsync: this, duration: const Duration(seconds: 2));

  /// The ambience starts a beat after the title is up, not with it.
  Timer? _ambientStart;

  bool get _still => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  @override
  void initState() {
    super.initState();
    if (_introduced) {
      _intro.value = 1;
    } else {
      _introduced = true;
      _intro.forward();
    }
    _ambientStart = Timer(const Duration(milliseconds: 2400), () => _setAmbient(true));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced motion: the page is simply there, and still.
    if (_still) {
      _intro.value = 1;
      _setAmbient(false);
    }
  }

  /// Runs or rests the ambience. It rests while a dialog covers the title
  /// (the room behind a question need not move), and with reduced motion.
  void _setAmbient(bool on) {
    _ambientStart?.cancel();
    _ambientStart = null;
    if (!mounted) return;
    if (on && !_still) {
      _push.repeat(reverse: true);
      _rain.repeat();
      _lamp.repeat(reverse: true);
      _ambientIn.forward();
    } else {
      for (final c in [_push, _rain, _lamp, _ambientIn]) {
        c.stop();
      }
    }
  }

  @override
  void dispose() {
    _ambientStart?.cancel();
    for (final c in [_intro, _push, _rain, _lamp, _ambientIn]) {
      c.dispose();
    }
    super.dispose();
  }

  void _continue() {
    final progress = ref.read(gameControllerProvider);
    if (progress.isCaseSolved) {
      context.go(Routes.solved);
    } else if (progress.introSeen) {
      context.go(Routes.map);
    } else if (progress.hasDetective) {
      // No case under way: the season (its casebook the very first time,
      // then the board with the case to work on) — after How to Play, for a
      // detective who left it unfinished before the season began.
      context.go(ref.read(needsHowToPlayProvider) ? Routes.howToPlay : Routes.season);
    } else {
      context.go(Routes.register);
    }
  }

  Future<void> _confirmNewGame() async {
    _setAmbient(false);
    final ok = await GameDialog.confirm(
      context,
      title: 'Start a New Adventure?',
      // What resetAll() clears: every case save, the season record and the
      // detective's name (registration comes next).
      message: 'Your investigation progress, case files and clues will be cleared. You will sign up again with a detective name.',
      confirmLabel: 'START NEW ADVENTURE',
      cancelLabel: 'Keep playing',
      onScene: true,
    );
    if (ok && mounted) {
      await ref.read(gameControllerProvider.notifier).resetAll();
      if (mounted) context.go(Routes.register);
    } else {
      _setAmbient(true);
    }
  }

  Future<void> _openGameMaster() async {
    _setAmbient(false);
    if (await ParentGate.show(context) && mounted) {
      ref.read(gameMasterAccessProvider.notifier).grant();
      // The tools page covers the title (its tickers pause underneath).
      context.push(Routes.gameMaster);
    }
    _setAmbient(true);
  }

  @override
  Widget build(BuildContext context) {
    final progress = ref.watch(gameControllerProvider);
    final hasSave = progress.hasDetective;
    final screen = MediaQuery.sizeOf(context);
    // A breath of shade where the words stand — the top of the evening sky
    // behind the title, the desk front under the greeting and the buttons —
    // and nowhere else: the window, the city and the lamp stay as painted.
    const shade = AppColors.navyDeep;
    final accountsShown = ref.watch(accountControllerProvider).accountsShown;
    final accountLink = !accountsShown
        ? null
        : switch (ref.watch(accountStateProvider.select((a) => a.status))) {
            AccountStatus.signedOut => ('Sign in', Routes.account),
            AccountStatus.signedIn => ('My account', Routes.accountSettings),
            AccountStatus.starting || AccountStatus.unavailable => null,
          };

    return Scaffold(
      backgroundColor: AppColors.nightBottom,
      // No text field here: the keyboard of the parent gate dialog must not
      // squeeze the title page (the dialog moves above the keyboard itself).
      resizeToAvoidBottomInset: false,
      // The detective's office at night: the title page of the storybook.
      body: InkSurface(
        night: true,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _Office(push: _push, rain: _rain, lamp: _lamp, ambientIn: _ambientIn),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    // From the top of the desk down: soft enough that the
                    // letter and map still read as paper, never a panel.
                    for (final a in const [0.4, 0.16, 0.0, 0.0, 0.4, 0.64]) shade.withValues(alpha: a),
                  ],
                  stops: const [0, 0.2, 0.36, 0.56, 0.78, 1],
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  // The page fills the screen; on a very small screen (or with
                  // large text) it scrolls instead of squeezing.
                  child: LayoutBuilder(
                    builder: (context, box) => SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: box.maxHeight),
                        child: IntrinsicHeight(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(height: (screen.height * 0.04).clamp(AppSpace.md, AppSpace.xxl)),
                              // The title, centred in the evening sky of the
                              // window, above the city: the moon and Big Ben
                              // on the right stay clear.
                              // Long-press: the grown-ups' game master tools.
                              Center(
                                child: GestureDetector(
                                  onLongPress: _openGameMaster,
                                  child: _TitleBlock(intro: _intro, width: screen.width),
                                ),
                              ),
                              // The middle is the window: London, left to itself.
                              const Spacer(),
                              // The greeting stands with the way in, on the
                              // desk: an invitation for a new player, a welcome
                              // for a detective coming back.
                              _RiseIn(
                                intro: _intro,
                                from: 0.42,
                                child: _Greeting(detectiveName: hasSave ? progress.detectiveName : null),
                              ),
                              const SizedBox(height: AppSpace.md),
                              // Last to come in, but answers a tap from the first frame.
                              _RiseIn(
                                intro: _intro,
                                from: 0.6,
                                child: GameButton(
                                  label: hasSave ? 'CONTINUE ADVENTURE' : 'START ADVENTURE',
                                  arrow: true,
                                  singleLine: true, // one line on a 360-wide phone
                                  style: GameButtonStyle.parchment,
                                  tap: TapRole.primary,
                                  onPressed: _continue,
                                ),
                              ),
                              if (hasSave)
                                _RiseIn(
                                  intro: _intro,
                                  from: 0.7,
                                  child: SizedBox(
                                    height: 52,
                                    child: Center(
                                      // Starts the whole adventure over (asks first).
                                      child: _PageLink(label: 'NEW ADVENTURE', emphasis: true, onPressed: _confirmNewGame),
                                    ),
                                  ),
                                ),
                              // The user account, small and quiet: playing never
                              // needs it (only when this build has accounts).
                              if (accountLink case (final label, final route))
                                _RiseIn(
                                  intro: _intro,
                                  from: 0.75,
                                  child: SizedBox(
                                    height: 48,
                                    child: Center(
                                      child: _PageLink(label: label, onPressed: () => context.go(route)),
                                    ),
                                  ),
                                ),
                              // Raised off the edge so the desk shows below it; a
                              // little more on tall phones, never up into the desk.
                              SizedBox(
                                // With two actions, the group sits a little higher
                                // (about 12 on a small phone, a touch more when tall).
                                height: hasSave
                                    ? AppSpace.sm + (screen.height * 0.019).clamp(10.0, 14.0)
                                    : AppSpace.lg + (screen.height * 0.038).clamp(20.0, 28.0),
                              ),
                            ],
                          ),
                        ),
                      ),
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

/// The detective's office, filling the screen — and barely alive: the
/// camera drifts towards the window and back, rain runs down the glass,
/// the lamp's light breathes. The painting, the rain and the light move
/// together; the words and buttons above never do.
class _Office extends StatelessWidget {
  const _Office({required this.push, required this.rain, required this.lamp, required this.ambientIn});

  final Animation<double> push;
  final Animation<double> rain;
  final Animation<double> lamp;
  final Animation<double> ambientIn;

  /// When the phone is narrower than the painting (9:16), the crop leans a
  /// little right to keep Big Ben (near the right edge of the window) whole;
  /// the lamp on the left keeps its glowing bulb.
  static const _focus = Alignment(0.55, 0);

  /// The camera drifts in this far (and back), towards the window.
  static const _pushBy = 0.022;

  @override
  Widget build(BuildContext context) {
    const pixels = ArtAssets.titleDetectiveOfficePixels;
    return LayoutBuilder(
      builder: (context, box) {
        final picture = _coverRect(box.biggest, pixels, _focus);
        // The camera push moves the painting only. The rain and the lamp
        // light are separate layers above it that follow the same push (so
        // they stay on the window and the lamp); the words and buttons are
        // above all of them, in the page, and never move with it.
        Widget pushed(Widget child) => AnimatedBuilder(
              animation: push,
              builder: (context, child) => Transform.scale(
                scale: 1 + _pushBy * Curves.easeInOut.transform(push.value),
                // Into the room towards the window, Big Ben nearly still.
                alignment: const Alignment(0.6, -0.3),
                child: child,
              ),
              child: child,
            );
        return ClipRect(
          child: Stack(
            fit: StackFit.expand,
            children: [
              pushed(
                Image.asset(
                  ArtAssets.titleDetectiveOffice,
                  fit: BoxFit.cover,
                  alignment: _focus,
                  width: double.infinity,
                  height: double.infinity,
                  // Decoded at the width it covers, never above the file.
                  cacheWidth: math.min(
                    (math.max(box.maxWidth, box.maxHeight * pixels.aspectRatio) * MediaQuery.devicePixelRatioOf(context)).ceil(),
                    pixels.width.toInt(),
                  ),
                  excludeFromSemantics: true,
                  // Without the picture: the night page it replaced.
                  errorBuilder: (context, error, stack) => const PaperBackground(night: true, child: SizedBox.expand()),
                ),
              ),
              IgnorePointer(
                child: pushed(
                  RepaintBoundary(
                    child: CustomPaint(painter: _RainPainter(picture: picture, rain: rain, shown: ambientIn)),
                  ),
                ),
              ),
              IgnorePointer(
                child: pushed(
                  RepaintBoundary(
                    child: CustomPaint(painter: _LampLightPainter(picture: picture, lamp: lamp, shown: ambientIn)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Where a picture of [pixels] lands when it covers [box] at [alignment]
/// (what `BoxFit.cover` does), so things can be drawn on its parts.
Rect _coverRect(Size box, Size pixels, Alignment alignment) {
  final scale = math.max(box.width / pixels.width, box.height / pixels.height);
  final size = pixels * scale;
  return alignment.inscribe(size, Offset.zero & box);
}

/// Rain on the window glass: a few thin, faint streaks running slowly down
/// the panes — and nowhere else (not the frame, not the room). Panes are
/// fractions of the painting.
class _RainPainter extends CustomPainter {
  _RainPainter({required this.picture, required this.rain, required this.shown}) : super(repaint: Listenable.merge([rain, shown]));

  final Rect picture;
  final Animation<double> rain;
  final Animation<double> shown;

  /// The glass between the window's bars (left, top, right, bottom).
  static const _panes = [
    Rect.fromLTRB(0.350, 0.040, 0.618, 0.630),
    Rect.fromLTRB(0.645, 0.020, 0.968, 0.630),
  ];

  /// One streak: across its pane (0..1), where it starts, how long, how
  /// fast (whole pane-heights per loop, so the loop never jumps), how faint.
  static final _streaks = () {
    final rnd = math.Random(17);
    return [
      for (var i = 0; i < 34; i++)
        (
          pane: i % _panes.length,
          x: rnd.nextDouble(),
          phase: rnd.nextDouble(),
          length: 0.038 + rnd.nextDouble() * 0.054,
          speed: 1 + rnd.nextInt(2),
          alpha: 0.10 + rnd.nextDouble() * 0.14,
        ),
    ];
  }();

  @override
  void paint(Canvas canvas, Size size) {
    final fade = shown.value;
    if (fade <= 0) return;
    Rect onScreen(Rect f) => Rect.fromLTRB(
          picture.left + f.left * picture.width,
          picture.top + f.top * picture.height,
          picture.left + f.right * picture.width,
          picture.top + f.bottom * picture.height,
        );
    final panes = [for (final p in _panes) onScreen(p)];
    final glass = Path();
    for (final p in panes) {
      glass.addRect(p);
    }
    canvas.save();
    canvas.clipPath(glass);
    final line = Paint()
      ..strokeWidth = 0.98
      ..strokeCap = StrokeCap.round;
    for (final s in _streaks) {
      final pane = panes[s.pane];
      final len = s.length * picture.height;
      final y = pane.top - len + ((s.phase + rain.value * s.speed) % 1) * (pane.height + len);
      final x = pane.left + s.x * pane.width;
      line.color = AppColors.paperLight.withValues(alpha: s.alpha * fade);
      // A little slant, as rain runs on glass.
      canvas.drawLine(Offset(x, y), Offset(x - len * 0.05, y + len), line);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RainPainter old) => old.picture != picture;
}

/// The lamp's warm light on the wall and desk around it, breathing very
/// slightly as a flame would (the lamp itself does not move).
class _LampLightPainter extends CustomPainter {
  _LampLightPainter({required this.picture, required this.lamp, required this.shown}) : super(repaint: Listenable.merge([lamp, shown]));

  final Rect picture;
  final Animation<double> lamp;
  final Animation<double> shown;

  /// The bulb under the shade, as fractions of the painting.
  static const _bulb = Offset(0.100, 0.506);

  @override
  void paint(Canvas canvas, Size size) {
    final fade = shown.value;
    if (fade <= 0) return;
    // 0.88 ↔ 1.0 of a faint warm light, eased like a slow breath.
    final strength = (0.88 + 0.12 * Curves.easeInOut.transform(lamp.value)) * fade;
    final center = Offset(picture.left + _bulb.dx * picture.width, picture.top + _bulb.dy * picture.height);
    final radius = picture.width * 0.26;
    final glow = Rect.fromCircle(center: center, radius: radius);
    canvas.drawRect(
      glow,
      // Plain (source-over) painting. An "advanced" blend mode such as
      // screen makes the GPU renderer (Impeller) read back the picture
      // under it, and on devices that dropped the words drawn after it.
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.goldLight.withValues(alpha: 0.16 * strength),
            AppColors.goldLight.withValues(alpha: 0.05 * strength),
            AppColors.goldLight.withValues(alpha: 0),
          ],
          stops: const [0, 0.45, 1],
        ).createShader(glow),
    );
  }

  @override
  bool shouldRepaint(_LampLightPainter old) => old.picture != picture;
}

/// Comes in once with the title: a short fade and a rise of a few pixels,
/// starting at [from] (0..1) of the entrance. Taps reach it all along.
class _RiseIn extends StatelessWidget {
  const _RiseIn({required this.intro, required this.from, required this.child});

  final Animation<double> intro;
  final double from;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: intro,
      builder: (context, child) {
        // Each part takes up to 0.4 of the entrance and is always complete by
        // its end (a later part gets a shorter rise, never a partial one).
        final t = Curves.easeOutCubic.transform(((intro.value - from) / math.min(0.4, 1 - from)).clamp(0.0, 1.0));
        return Opacity(opacity: t, child: Transform.translate(offset: Offset(0, 6 * (1 - t)), child: child));
      },
      child: child,
    );
  }
}

/// Lifts light words off the painted desk (its letter and map are pale):
/// a wide faint halo, a soft one and a close edge, all dark — no glow.
List<Shadow> _lift([double strength = 1]) => [
      Shadow(color: AppColors.navyDeep.withValues(alpha: 0.35 * strength), blurRadius: 18),
      Shadow(color: AppColors.navyDeep.withValues(alpha: 0.55 * strength), blurRadius: 8, offset: const Offset(0, 1)),
      Shadow(color: AppColors.navyDeep.withValues(alpha: 0.45 * strength), blurRadius: 2, offset: const Offset(0, 1)),
    ];

/// The detective's cap / LONDON / MYSTERY / ◆, centred in the window's sky.
class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.intro, required this.width});

  final Animation<double> intro;
  final double width;

  @override
  Widget build(BuildContext context) {
    // Only enough to lift the letters off the painted clouds: no glow.
    final lift = [Shadow(color: AppColors.navyDeep.withValues(alpha: 0.55), blurRadius: 8, offset: const Offset(0, 1))];
    // Sized to leave the sky and the city the larger part of the window.
    final size = (width * 0.1).clamp(32.0, 42.0);
    // Large text grows the title a little, not over the moon or into the
    // city: the column stays narrow, and a long greeting wraps.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.15,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: width * 0.76),
        child: Column(
          children: [
            _RiseIn(
              intro: intro,
              from: 0,
              child: const InkIcon(InkGlyph.deerstalker, size: AppIconSize.medium, color: AppColors.goldLight),
            ),
            const SizedBox(height: AppSpace.sm),
            // One word to a line, always: fitted to a narrower column than the
            // greeting's (large text shrinks the words rather than reach the
            // moon), never broken.
            _RiseIn(
              intro: intro,
              from: 0.12,
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: width * 0.58),
                child: Column(
                  children: [
                    for (final word in const ['LONDON', 'MYSTERY'])
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          word,
                          maxLines: 1,
                          softWrap: false,
                          style: AppText.logo(size: size, color: AppColors.creamGold)
                              .copyWith(letterSpacing: size * 0.08, height: 1.08, shadows: lift),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpace.md),
            _RiseIn(intro: intro, from: 0.3, child: const OrnamentRule(color: AppColors.goldLight, width: 120)),
          ],
        ),
      ),
    );
  }
}

/// Become a Detective. (or Welcome back, Detective NAME!) — in the
/// storybook italic, ivory, just above the way in. A long name takes a
/// second line, never a third.
class _Greeting extends StatelessWidget {
  const _Greeting({required this.detectiveName});

  final String? detectiveName;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.15,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
        child: Text(
          detectiveName == null ? 'Become a Detective.' : 'Welcome back, Detective $detectiveName!',
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppText.aside(size: 17, color: AppColors.paperLight).copyWith(shadows: _lift(1.4)),
        ),
      ),
    );
  }
}

/// A quiet way off the title page, under its button: words only, lifted
/// off the desk. [emphasis] (NEW ADVENTURE): cream caps with a faint rule
/// under them; otherwise (Sign in) smaller and plainer, the least of the page.
class _PageLink extends StatelessWidget {
  const _PageLink({required this.label, required this.onPressed, this.emphasis = false});

  final String label;
  final VoidCallback onPressed;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final color = emphasis ? AppColors.creamGold : AppColors.paperLight.withValues(alpha: 0.9);
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        minimumSize: const Size(48, 48),
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
        foregroundColor: color,
        // A soft light under the finger: it answers, it does not flash.
        overlayColor: AppColors.paperLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: AppText.button(size: emphasis ? 15 : 14, color: color).copyWith(
          letterSpacing: emphasis ? 1.4 : 0.3,
          fontWeight: emphasis ? null : FontWeight.w500,
          shadows: _lift(1.4),
          decoration: emphasis ? TextDecoration.underline : null,
          decorationColor: color.withValues(alpha: 0.45),
          decorationThickness: 1,
        ),
      ),
    );
  }
}
