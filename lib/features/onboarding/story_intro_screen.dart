import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../data/models/episode.dart';
import '../../widgets/art_assets.dart';
import '../../widgets/game_button.dart';
import '../../widgets/landmark_art.dart';
import '../../widgets/paper_background.dart';
import '../../widgets/typewriter_text.dart';
import '../game/game_controller.dart';
import '../game/game_providers.dart';

/// Cinematic story intro: lines are "typed" one after another.
class StoryIntroScreen extends ConsumerStatefulWidget {
  const StoryIntroScreen({super.key});

  @override
  ConsumerState<StoryIntroScreen> createState() => _StoryIntroScreenState();
}

class _StoryIntroScreenState extends ConsumerState<StoryIntroScreen> {
  int _line = 0; // index of the line currently typing
  bool _skipCurrent = false;
  bool _lineDone = false;
  bool _ready = false;
  Timer? _pause;

  /// Keeps the newest line in view: on a small phone (or with large text)
  /// the story grows past the screen and the line being typed would be
  /// below the edge.
  final _scroll = ScrollController();

  List<String> get _lines => ref.read(currentEpisodeProvider).intro;

  @override
  void dispose() {
    _pause?.cancel();
    _scroll.dispose();
    super.dispose();
  }

  void _followNewestLine() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final end = _scroll.position.maxScrollExtent;
      if (MediaQuery.disableAnimationsOf(context)) {
        _scroll.jumpTo(end);
      } else {
        _scroll.animateTo(end, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
      }
    });
  }

  void _onLineFinished() {
    _followNewestLine();
    _lineDone = true;
    _pause?.cancel();
    _pause = Timer(const Duration(milliseconds: 750), _advance);
  }

  void _advance() {
    if (!mounted) return;
    setState(() {
      _skipCurrent = false;
      _lineDone = false;
      if (_line < _lines.length - 1) {
        _line++;
      } else {
        _ready = true;
      }
    });
    _followNewestLine();
  }

  void _onTap() {
    if (_ready) return;
    if (_lineDone) {
      _pause?.cancel();
      _advance();
    } else {
      setState(() => _skipCurrent = true); // finish typing this line now
    }
  }

  void _skipAll() {
    _pause?.cancel();
    setState(() {
      _line = _lines.length - 1;
      _skipCurrent = true;
      _ready = true;
    });
    _followNewestLine();
  }

  void _start() {
    ref.read(gameControllerProvider.notifier).startInvestigation();
    context.go(Routes.map);
  }

  @override
  Widget build(BuildContext context) {
    final lines = _lines;
    return Scaffold(
      backgroundColor: AppColors.nightBottom,
      // The narration over the place the case opens on, in the dark.
      body: Stack(
        fit: StackFit.expand,
        children: [
          _IntroScene(ref.read(currentEpisodeProvider)),
          InkSurface(
            night: true,
            child: SafeArea(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _onTap,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                      child: Column(
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: AnimatedOpacity(
                              opacity: _ready ? 0 : 1,
                              duration: const Duration(milliseconds: 250),
                              child: TextButton(
                                onPressed: _ready ? null : _skipAll,
                                child: Text('SKIP ›', style: AppText.button(size: 15, color: AppColors.goldLight)),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: SingleChildScrollView(
                                controller: _scroll,
                                child: Column(
                                  children: [
                                    for (var i = 0; i <= _line && i < lines.length; i++)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 22),
                                        child: AnimatedOpacity(
                                          // Older lines fade back so the newest one leads.
                                          opacity: i == _line ? 1 : 0.55,
                                          duration: const Duration(milliseconds: 400),
                                          child: TypewriterText(
                                            lines[i],
                                            key: ValueKey('intro-$i'),
                                            skip: i < _line || (i == _line && _skipCurrent),
                                            style: i == 0
                                                ? AppText.style(
                                                    AppText.display,
                                                    size: 22,
                                                    weight: FontWeight.w700,
                                                    color: AppColors.goldLight,
                                                    letterSpacing: 1.5,
                                                  )
                                                : AppText.style(
                                                    AppText.heading,
                                                    size: 23,
                                                    weight: FontWeight.w500,
                                                    color: AppColors.paperLight,
                                                    height: 1.35,
                                                  ),
                                            onFinished: i == _line ? _onLineFinished : null,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            transitionBuilder: (child, anim) => FadeTransition(
                              opacity: anim,
                              child: ScaleTransition(scale: Tween(begin: 0.9, end: 1.0).animate(anim), child: child),
                            ),
                            child: _ready
                                ? Column(
                                    key: const ValueKey('ready'),
                                    children: [
                                      Text(
                                        'Are you ready?',
                                        style: AppText.title(size: 32, color: AppColors.goldLight),
                                      ),
                                      const SizedBox(height: 20),
                                      GameButton(
                                        label: "I'M READY",
                                        arrow: true,
                                        style: GameButtonStyle.glass,
                                        onPressed: _start,
                                      ),
                                    ],
                                  )
                                : Padding(
                                    key: const ValueKey('tap'),
                                    padding: const EdgeInsets.only(bottom: 24),
                                    child: Text(
                                      'Tap to continue',
                                      style: AppText.caption(color: AppColors.paperLight.withValues(alpha: 0.75)),
                                    ),
                                  ),
                          ),
                          // Off the bottom edge, as on the title page and the season cover.
                          SizedBox(height: (MediaQuery.sizeOf(context).height * 0.038).clamp(20.0, 28.0)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The place the case opens on, filling the screen in the dark under the
/// narration: the case's [Episode.introScene] picture, or the London map
/// while the place has none (Case 01's Royal Archive). Dimmed so the words
/// lead, never so dark that the place is lost.
class _IntroScene extends StatelessWidget {
  const _IntroScene(this.episode);

  final Episode episode;

  @override
  Widget build(BuildContext context) {
    final scene = episode.introScene;
    final picture = scene != null && LandmarkArt.hasPicture(scene)
        // The print without its paper edge and name plate, as the whole scene.
        ? LandmarkArt(scene, showName: false, borderRadius: 0)
        : LayoutBuilder(
            builder: (context, box) => Image.asset(
              ArtAssets.londonMap,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              cacheWidth: math.min(
                (math.max(box.maxWidth, box.maxHeight * ArtAssets.londonMapAspect) *
                        MediaQuery.devicePixelRatioOf(context))
                    .ceil(),
                ArtAssets.londonMapPixels.width.toInt(),
              ),
              excludeFromSemantics: true,
              errorBuilder: (context, error, stack) => const SizedBox.expand(),
            ),
          );
    const shade = AppColors.navyDeep;
    return RepaintBoundary(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // A small print shown screen-sized: softened a touch so it reads as
          // a scene in the dark rather than an enlarged photo.
          ImageFiltered(imageFilter: ui.ImageFilter.blur(sigmaX: 1.5, sigmaY: 1.5), child: picture),
          // Night over the place, a little deeper at the edges and where the
          // button and the last words sit.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 1.0,
                colors: [shade.withValues(alpha: 0.6), shade.withValues(alpha: 0.82)],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  for (final a in const [0.25, 0.0, 0.0, 0.45]) shade.withValues(alpha: a),
                ],
                stops: const [0, 0.2, 0.7, 1],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
