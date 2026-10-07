
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/mock/season1/season1_discoveries.dart';
import '../../data/models/mission.dart';
import '../../widgets/evidence_card.dart';
import '../../widgets/game_button.dart';
import '../../widgets/glossary_text.dart';
import '../../widgets/ink_icon.dart';
import '../../widgets/landmark_art.dart';
import '../../widgets/place_art.dart';
import '../../widgets/place_scenery.dart';
import '../../widgets/paper.dart';
import '../../widgets/paper_background.dart';
import '../../widgets/typewriter_text.dart';
import '../game/game_controller.dart';
import '../game/game_providers.dart';

/// Short cinematic scene between missions: what happened next, and which
/// place just opened up.
///
/// After the final case (its [Mission.transition] is the post-case scene)
/// the same scene closes the case instead: its own place behind the words,
/// its last evidence, and SEE MY CASE REPORT.
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

  /// The post-case story is longer than a small phone: it keeps the newest
  /// line in view.
  final _scroll = ScrollController();

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
      if (_scroll.offset >= end) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        _scroll.jumpTo(end);
      } else {
        _scroll.animateTo(end, duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
      }
    });
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
    // The final case: the scene after the case is closed.
    final afterCase = m.isFinal;
    // Evidence this scene hands over (not the puzzle): laid down after its lines.
    final handed = afterCase ? null : storyEvidenceOf(m);
    final lines = _lines;
    if (lines.isEmpty) _done = true;

    return Scaffold(
      backgroundColor: AppColors.nightBottom,
      // The story goes on at the place the clue points to: its picture fills
      // the screen, in the dark, under the words. After the case: the place
      // the case was closed at.
      body: Stack(
        fit: StackFit.expand,
        children: [
          PlaceScenery(
            afterCase
                ? PlaceArt.sceneryOf(m)
                : next == null
                ? null
                : PlaceArt.sceneryOf(next),
          ),
          InkSurface(
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
                          Text(
                            afterCase ? 'CASE ${episode.numberLabel} COMPLETE' : 'MISSION ${m.numberLabel} COMPLETE',
                            style: AppText.eyebrow(color: AppColors.goldLight),
                          ),
                          const SizedBox(height: AppSpace.sm),
                          const OrnamentRule(color: AppColors.goldLight),
                          const SizedBox(height: AppSpace.sm),
                          Text(
                            'Great work, Detective $name.',
                            textAlign: TextAlign.center,
                            style: AppText.bodyText(size: 16, color: AppColors.paperLight.withValues(alpha: 0.72)),
                          ),
                          // The longer story scrolls: a breath between the greeting and its faded edge.
                          if (afterCase) const SizedBox(height: AppSpace.md),
                          Expanded(
                            child: Center(
                              child: NotificationListener<ScrollMetricsNotification>(
                                // A new line (or the evidence handed over) made the
                                // story taller: keep the newest in view.
                                onNotification: (_) {
                                  if (afterCase || handed != null) _followNewestLine();
                                  return false;
                                },
                                child: _StoryEdges(
                                  fade: afterCase,
                                  child: SingleChildScrollView(
                                    controller: _scroll,
                                    // Room to scroll the first and last lines clear of the faded edges.
                                    padding: afterCase ? const EdgeInsets.symmetric(vertical: AppSpace.xl) : null,
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
                                        // Once the lines are read: what was handed over.
                                        if (handed != null && _done)
                                          Padding(
                                            padding: const EdgeInsets.only(bottom: AppSpace.sm),
                                            child: _EvidenceCard(evidence: handed, location: m.location),
                                          ),
                                      ],
                                    ),
                                  ),
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
                                      // After the case: its last evidence, held up once more.
                                      if (afterCase && m.evidence != null)
                                        _EvidenceCard(evidence: m.evidence!, location: m.location)
                                      else if (next != null)
                                        _UnlockedCard(
                                          nextLocation: next.location,
                                          isFinal: next.isFinal,
                                          art: PlaceArt.placeOf(next),
                                        ),
                                      const SizedBox(height: 18),
                                      if (afterCase)
                                        GameButton(
                                          label: 'SEE MY CASE REPORT',
                                          glyph: InkGlyph.folder,
                                          style: GameButtonStyle.glass,
                                          onPressed: () => context.go(Routes.solved),
                                        )
                                      else
                                        GameButton(
                                          label: 'TO THE MAP',
                                          arrow: true,
                                          style: GameButtonStyle.glass,
                                          onPressed: () => context.go(Routes.map),
                                        ),
                                    ],
                                  )
                                : Padding(
                                    key: const ValueKey('tap'),
                                    padding: const EdgeInsets.only(bottom: 20),
                                    child: Text(
                                      'Tap to skip',
                                      style: AppText.caption(color: AppColors.paperLight.withValues(alpha: 0.75)),
                                    ),
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
        ],
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
    return _LaidDown(
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
                        child: Text(
                          isFinal ? 'FINAL CASE UNLOCKED' : 'NEW PLACE UNLOCKED',
                          style: AppText.eyebrow(color: AppColors.success),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(nextLocation, style: AppText.placeTitle(size: 21)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The case's last evidence after the case is closed (or, after a mission,
/// the evidence its scene hands over): the same paper card,
/// with what is written on it. Tap to look closer (as in the notebook).
class _EvidenceCard extends StatelessWidget {
  const _EvidenceCard({required this.evidence, required this.location});

  final Evidence evidence;
  final String location;

  @override
  Widget build(BuildContext context) {
    final note = evidence.inscription;
    return _LaidDown(
      child: Semantics(
        button: true,
        label: '${evidence.name}. ${note ?? ''} Tap to look closer.',
        excludeSemantics: true,
        child: GestureDetector(
          onTap: () => showEvidenceZoom(context, evidence, location: location),
          child: PaperSheet(
            ruled: true,
            tilt: -0.012,
            padding: const EdgeInsets.all(AppSpace.lg),
            child: EvidenceChip(evidence: evidence, note: note),
          ),
        ),
      ),
    );
  }
}

/// The longer post-case story scrolls: its lines fade out at the top and
/// bottom edges instead of being cut off under the greeting.
class _StoryEdges extends StatelessWidget {
  const _StoryEdges({required this.fade, required this.child});

  final bool fade;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!fade) return child;
    return ShaderMask(
      blendMode: BlendMode.dstIn,
      shaderCallback: (rect) => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Colors.transparent, Colors.white, Colors.white, Colors.transparent],
        stops: [0, 0.1, 0.92, 1],
      ).createShader(rect),
      child: child,
    );
  }
}

/// A card laid down on the night desk: it settles in without overshoot, not
/// bounced (at once with reduced motion).
class _LaidDown extends StatelessWidget {
  const _LaidDown({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: (MediaQuery.maybeDisableAnimationsOf(context) ?? false)
          ? Duration.zero
          : const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Transform.scale(
        scale: 0.94 + 0.06 * t,
        child: Opacity(opacity: t.clamp(0, 1), child: child),
      ),
      child: child,
    );
  }
}

