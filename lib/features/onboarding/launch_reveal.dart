import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';

/// The native launch screen's magnifying glass, carried into the game: the
/// title page opens with it on screen where the launch screen left it, a
/// warm glimmer crosses its lens, and the detective's office comes up
/// through it before the title's words come in.
///
/// Played once per launch of the app ([take]); never when the title comes
/// back (from a case, a season change or developer mode) or the app returns
/// from the background.
abstract final class LaunchReveal {
  /// The launch screen's picture (`flutter_native_splash` in pubspec.yaml).
  static const asset = 'assets/branding/splash_logo.png';

  /// The square the launch screen draws [asset] in: 288 dp on Android, 288 pt
  /// on iOS (its @3x file is 864 px).
  static const side = 288.0;

  /// On Android 12+ the system splash draws `splash_logo_android12.png`: the
  /// same picture scaled by this much in the middle of the same square.
  static const android12Scale = 0.441;

  /// Where the lens is in [asset]: its centre ([Alignment] in the picture)
  /// and the radius of the glass, as a fraction of the picture's side.
  static const lensCentre = Alignment(-0.12, -0.142);
  static const lensRadius = 0.273;

  static const _channel = MethodChannel('world_mystery/launch');

  static ui.Image? _logo;
  static double _scale = 1;

  /// Android 12+: completes when the system splash has left the screen.
  static Completer<void>? _splashGone;

  /// The splash should leave with the first frame; if word never comes, the
  /// reveal begins after this anyway.
  static const _splashWait = Duration(milliseconds: 1500);

  /// Decodes the picture before the first frame, so the glass is on the
  /// first frame the game draws. Without it (or with [armed] false: another
  /// page comes first) the title simply opens as it always has.
  static Future<void> prepare({required bool armed}) async {
    if (!armed) return gameBars();
    try {
      final data = await rootBundle.load(asset);
      final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
      final frame = await codec.getNextFrame();
      codec.dispose();
      final android12 = await _isAndroid12Splash();
      _scale = android12 ? android12Scale : 1;
      if (android12) {
        final gone = _splashGone = Completer<void>();
        _channel.setMethodCallHandler((call) async {
          if (call.method == 'splashGone' && !gone.isCompleted) gone.complete();
        });
      }
      _logo = frame.image;
    } catch (_) {
      _logo = null; // no glass: no reveal
      await gameBars();
    }
  }

  /// Android shows its bars in the launch screen's navy from launch (see
  /// MainActivity) so they do not change as the game takes over; this gives
  /// them back to the game, once the reveal is over or when there is none.
  static Future<void> gameBars() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    // The bars MaterialApp asks for with the game's light theme (black
    // navigation bar, dark status icons); the status bar's own shade is
    // MainActivity's to give back.
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.dark);
    try {
      await _channel.invokeMethod<void>('gameBars');
    } catch (_) {
      // Nothing to give back.
    }
  }

  /// Android 12+ shows the system splash (its smaller glass); older Android
  /// the window background drawn by flutter_native_splash.
  static Future<bool> _isAndroid12Splash() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return false;
    try {
      return (await _channel.invokeMethod<int>('sdkInt') ?? 31) >= 31;
    } catch (_) {
      return true; // almost every phone today
    }
  }

  /// The glass for the one reveal of this launch; null after it was taken.
  static LaunchGlass? take() {
    final logo = _logo;
    _logo = null;
    if (logo == null) return null;
    final gone = _splashGone?.future;
    return LaunchGlass._(
      logo,
      _scale,
      gone == null ? Future<void>.value() : Future.any([gone, Future<void>.delayed(_splashWait)]),
    );
  }
}

/// The decoded glass of one reveal ([LaunchReveal.take]).
class LaunchGlass {
  LaunchGlass._(this.image, this.scale, this.onScreen);

  final ui.Image image;

  /// The picture's size against [LaunchReveal.side] (1, or Android 12's).
  final double scale;

  /// Completes when the game's own glass is what the player sees (the
  /// system splash gone): the reveal begins then, never unseen.
  final Future<void> onScreen;

  /// The reveal is over: the picture goes, and the bars are the game's again.
  void dispose() {
    image.dispose();
    LaunchReveal.gameBars();
  }
}

/// The reveal's timeline (of 1.1 s): a glimmer crosses the lens from the
/// first frame (to 0.8 s); the office comes up through the night from 0.4 s
/// while the glass lingers a moment longer (gone at 1.1 s); the title's words
/// come in after it. Nothing grows, moves or turns.
abstract final class LaunchRevealTiming {
  static const duration = Duration(milliseconds: 1100);
  static const glimmer = Interval(0, 0.73, curve: Curves.easeInOutSine);
  static const night = Interval(0.36, 0.91, curve: Curves.easeInOut);
  static const glass = Interval(0.45, 1, curve: Curves.easeInOut);
}

/// The launch screen's colour and glass over the title page, fading as
/// [reveal] runs to show the office underneath; gone once done.
class LaunchRevealLayer extends StatelessWidget {
  const LaunchRevealLayer({super.key, required this.glass, required this.reveal});

  final LaunchGlass glass;
  final Animation<double> reveal;

  @override
  Widget build(BuildContext context) {
    final side = LaunchReveal.side * glass.scale;
    // The launch screen centres the glass on the whole display; the game's
    // view can stop short of it (above an opaque navigation bar), so the
    // glass is placed against the display, not the view.
    final view = View.of(context);
    final display = view.display.size / view.devicePixelRatio;
    final screen = MediaQuery.sizeOf(context);
    final centre = display.isEmpty ? screen.center(Offset.zero) : display.center(Offset.zero);
    // Built once; only the opacities and the glimmer follow the reveal.
    final picture = Stack(
      children: [
        Positioned(
          left: centre.dx - side / 2,
          top: centre.dy - side / 2,
          width: side,
          height: side,
          child: CustomPaint(
            foregroundPainter: _GlimmerPainter(reveal),
            child: RawImage(image: glass.image, fit: BoxFit.contain, filterQuality: FilterQuality.medium),
          ),
        ),
      ],
    );
    return AnimatedBuilder(
      animation: reveal,
      builder: (context, picture) {
        final t = reveal.value;
        if (t >= 1) return const SizedBox.shrink();
        // Until it is gone the layer takes the taps: the title's buttons
        // underneath are not shown yet. The system bars stay the launch
        // screen's navy with light icons all the while.
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: _launchBars,
          child: AbsorbPointer(
            child: Stack(
              fit: StackFit.expand,
              children: [
                Opacity(
                  opacity: 1 - LaunchRevealTiming.night.transform(t),
                  child: const ColoredBox(color: AppColors.navyDeep),
                ),
                Opacity(opacity: 1 - LaunchRevealTiming.glass.transform(t), child: picture),
              ],
            ),
          ),
        );
      },
      child: picture,
    );
  }

  static const _launchBars = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark, // iOS: a dark background
    systemNavigationBarColor: AppColors.navyDeep,
    systemNavigationBarIconBrightness: Brightness.light,
  );
}

/// A soft band of warm light crossing the lens once, top left to bottom
/// right — inside the glass only, the frame and the handle untouched.
class _GlimmerPainter extends CustomPainter {
  _GlimmerPainter(this.reveal) : super(repaint: reveal);

  final Animation<double> reveal;

  @override
  void paint(Canvas canvas, Size size) {
    final g = reveal.value;
    if (g >= LaunchRevealTiming.glimmer.end) return;
    final p = LaunchRevealTiming.glimmer.transform(g);
    final lens = LaunchReveal.lensCentre.withinRect(Offset.zero & size);
    final r = LaunchReveal.lensRadius * size.shortestSide;
    // The band's middle travels the lens' diagonal, from beyond its top left
    // edge to beyond its bottom right one; it swells in and out on the way.
    const along = Offset(math.sqrt1_2, math.sqrt1_2);
    final middle = lens + along * (r * (2.8 * p - 1.4));
    final half = r * 0.9;
    final strength = math.sin(math.pi * p);
    final warm = AppColors.goldLight;
    final ivory = AppColors.paperLight;
    final paint = Paint()
      // Light added to the glass (plus, not screen: an advanced blend some
      // GPUs cannot draw, which drops the glimmer altogether).
      ..blendMode = BlendMode.plus
      ..shader = ui.Gradient.linear(
        middle - along * half,
        middle + along * half,
        [
          warm.withValues(alpha: 0),
          warm.withValues(alpha: 0.35 * strength),
          ivory.withValues(alpha: 0.55 * strength),
          warm.withValues(alpha: 0.35 * strength),
          warm.withValues(alpha: 0),
        ],
        const [0, 0.3, 0.5, 0.7, 1],
      );
    canvas
      ..save()
      ..clipPath(Path()..addOval(Rect.fromCircle(center: lens, radius: r)))
      ..drawRect(Offset.zero & size, paint)
      ..restore();
  }

  @override
  bool shouldRepaint(_GlimmerPainter old) => old.reveal != reveal;
}
