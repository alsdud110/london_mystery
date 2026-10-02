import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/models/mission.dart';
import '../../widgets/game_button.dart';
import '../../widgets/glossary_text.dart';
import '../../widgets/ink_icon.dart';
import '../../widgets/landmark_art.dart';
import '../../widgets/place_art.dart';
import '../../widgets/paper.dart';
import '../../widgets/paper_background.dart';
import '../../widgets/typewriter_text.dart';
import '../game/game_controller.dart';
import '../game/game_providers.dart';

/// Short cinematic scene between missions: what happened next, and which
/// place just opened up.
class StorySceneScreen extends ConsumerStatefulWidget {
  const StorySceneScreen({super.key, required this.missionId});

  final String missionId;

  @override
  ConsumerState<StorySceneScreen> createState() => _StorySceneScreenState();
}

class _StorySceneScreenState extends ConsumerState<StorySceneScreen> {
  int _line = 0;
  bool _skip = false;
  bool _done = false;
  Timer? _pause;

  @override
  void dispose() {
    _pause?.cancel();
    super.dispose();
  }

  List<String> get _lines => ref.read(currentEpisodeProvider).missionById(widget.missionId)?.transition ?? const [];

  void _lineFinished() {
    _pause?.cancel();
    _pause = Timer(const Duration(milliseconds: 650), _next);
  }

  void _next() {
    if (!mounted) return;
    setState(() {
      _skip = false;
      if (_line < _lines.length - 1) {
        _line++;
      } else {
        _done = true;
      }
    });
  }

  void _tap() {
    if (_done) return;
    _pause?.cancel();
    setState(() {
      _line = _lines.length - 1;
      _skip = true;
      _done = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final episode = ref.watch(currentEpisodeProvider);
    final name = ref.watch(gameControllerProvider).detectiveName ?? '';
    final m = episode.missionById(widget.missionId)!;
    final next = m.nextMissionId == null ? null : episode.missionById(m.nextMissionId!);
    final lines = _lines;
    if (lines.isEmpty) _done = true;

    return Scaffold(
      backgroundColor: AppColors.navy,
      body: PaperBackground(
        night: true,
        child: SafeArea(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _tap,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(28, 20, 28, 20),
                  child: Column(
                    children: [
                      Text('MISSION ${m.numberLabel} COMPLETE', style: AppText.eyebrow(color: AppColors.goldLight)),
                      const SizedBox(height: AppSpace.sm),
                      const OrnamentRule(color: AppColors.goldLight),
                      const SizedBox(height: AppSpace.sm),
                      Text('Great work, Detective $name.',
                          textAlign: TextAlign.center, style: AppText.bodyText(size: 16, color: AppColors.paperLight.withValues(alpha: 0.72))),
                      Expanded(
                        child: Center(
                          child: SingleChildScrollView(
                            child: Column(
                              children: [
                                for (var i = 0; i <= _line && i < lines.length; i++)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 20),
                                    child: i < _line || _done
                                        ? GlossaryText(
                                            lines[i],
                                            textAlign: TextAlign.center,
                                            style: _lineStyle(i == lines.length - 1),
                                          )
                                        : TypewriterText(
                                            lines[i],
                                            key: ValueKey('scene-$i'),
                                            skip: _skip,
                                            style: _lineStyle(i == lines.length - 1),
                                            onFinished: _lineFinished,
                                          ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 450),
                        child: _done
                            ? Column(
                                key: const ValueKey('done'),
                                children: [
                                  if (next != null) _UnlockedCard(nextLocation: next.location, isFinal: next.isFinal, art: PlaceArt.placeOf(next)),
                                  const SizedBox(height: 18),
                                  GameButton(
                                    label: 'TO THE MAP',
                                    arrow: true,
                                    style: GameButtonStyle.gold,
                                    onPressed: () => context.go(Routes.map),
                                  ),
                                ],
                              )
                            : Padding(
                                key: const ValueKey('tap'),
                                padding: const EdgeInsets.only(bottom: 20),
                                child: Text('Tap to skip', style: AppText.caption(color: AppColors.paperLight.withValues(alpha: 0.75))),
                              ),
                      ),
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

  TextStyle _lineStyle(bool last) => AppText.style(
        AppText.heading,
        size: last ? 24 : 22,
        weight: last ? FontWeight.w600 : FontWeight.w500,
        color: last ? AppColors.goldLight : AppColors.paperLight,
        height: 1.35,
      );
}

class _UnlockedCard extends StatelessWidget {
  const _UnlockedCard({required this.nextLocation, required this.isFinal, required this.art});

  final String nextLocation;
  final bool isFinal;
  final Artwork art;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      // Settles in without overshoot: a card laid down, not bounced.
      duration: (MediaQuery.maybeDisableAnimationsOf(context) ?? false) ? Duration.zero : const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Transform.scale(scale: 0.94 + 0.06 * t, child: Opacity(opacity: t.clamp(0, 1), child: child)),
      // A paper card handed across the night desk.
      child: PaperSheet(
        ruled: true,
        tilt: -0.012,
        padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.lg, AppSpace.lg, AppSpace.lg),
        child: Row(
          children: [
            // A picture shows whole at its own ratio; a drawing stays square.
            SizedBox(
              width: LandmarkArt.hasPicture(art) ? 72 * LandmarkArt.aspectOf(art) : 72,
              height: 72,
              child: LandmarkArt(art, borderRadius: LandmarkArt.hasPicture(art) ? 2 : 6),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const InkIcon(InkGlyph.check, size: AppIconSize.small, color: AppColors.success),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(isFinal ? 'FINAL CASE UNLOCKED' : 'NEW PLACE UNLOCKED',
                            style: AppText.eyebrow(color: AppColors.success)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(nextLocation, style: AppText.title(size: 21)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
