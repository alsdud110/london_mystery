import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../widgets/game_button.dart';
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

  List<String> get _lines => ref.read(currentEpisodeProvider).intro;

  @override
  void dispose() {
    _pause?.cancel();
    super.dispose();
  }

  void _onLineFinished() {
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
  }

  void _start() {
    ref.read(gameControllerProvider.notifier).startInvestigation();
    context.go(Routes.map);
  }

  @override
  Widget build(BuildContext context) {
    final lines = _lines;
    return Scaffold(
      backgroundColor: AppColors.navy,
      body: PaperBackground(
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
                                                color: Colors.white,
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
                                  Text('Are you ready?', style: AppText.title(size: 32, color: AppColors.gold)),
                                  const SizedBox(height: 20),
                                  GameButton(
                                    label: "I'M READY",
                                    arrow: true,
                                    style: GameButtonStyle.gold,
                                    onPressed: _start,
                                  ),
                                ],
                              )
                            : Padding(
                                key: const ValueKey('tap'),
                                padding: const EdgeInsets.only(bottom: 24),
                                child: Text(
                                  'Tap to continue',
                                  style: AppText.caption(color: Colors.white.withValues(alpha: 0.5)),
                                ),
                              ),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
