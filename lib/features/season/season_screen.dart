import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../widgets/art_assets.dart';
import '../../widgets/desk_background.dart';
import '../../widgets/game_button.dart';
import '../../widgets/game_toast.dart';
import '../../widgets/ink_icon.dart';
import '../../widgets/paper.dart';
import '../../widgets/paper_background.dart';
import '../game/game_controller.dart';
import '../game/game_providers.dart';
import 'season_actions.dart';
import 'season_overview.dart';
import 'widgets/investigation_board.dart';

/// The season: Season → Case → Mission. Above the case files, it shows the
/// twelve cases as one story.
///
/// Before the season has begun, it is the season's cover: London at night,
/// seen from above, the whole city the case ahead — BEGIN SEASON ONE →
/// the season's opening sequence → Case 01's story. After that, it is the
/// investigation board on the detective's desk, with how many cases are
/// solved, the case to work on now and the way to it. Once every case is
/// solved, the completed board.
///
/// Nothing here decides progress: cases open through
/// [GameController.openEpisode] and the case's own flow ([SeasonActions]).
class SeasonScreen extends ConsumerStatefulWidget {
  const SeasonScreen({super.key});

  @override
  ConsumerState<SeasonScreen> createState() => _SeasonScreenState();
}

class _SeasonScreenState extends ConsumerState<SeasonScreen> with TickerProviderStateMixin {
  /// The cover coming in (before the season has begun): the title, the
  /// button, and a camera push so slow it is barely felt.
  late final AnimationController _book = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));

  /// BEGIN SEASON ONE: the camera moves into the city towards Westminster
  /// and the night closes in, then the opening's first scene comes up.
  late final AnimationController _leave = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));

  /// What changed on the board since it was last shown.
  late final AnimationController _reveal = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  /// Decided once on arrival, so the page does not switch under the player.
  late final bool _casebook;

  /// The board as it was before the cases just solved, while they play.
  SeasonOverview? _before;

  @override
  void initState() {
    super.initState();
    final overview = ref.read(seasonOverviewProvider);
    _casebook = !overview.begun;
    if (_casebook) {
      _book.forward();
      return;
    }
    final season = ref.read(seasonProvider);
    final fresh = [for (final id in ref.read(recentSolveProvider)) if (season.isSolved(id)) id];
    if (fresh.isEmpty) {
      _reveal.value = 1;
      return;
    }
    final repo = ref.read(progressRepositoryProvider);
    final active = ref.read(gameControllerProvider);
    _before = SeasonOverview.before(
      overview,
      season,
      fresh,
      operator: ref.read(operatorAccessProvider),
      progressOf: (id) => id == season.activeEpisodeId ? active : repo.load(id),
    );
    // Shown once: the next visit opens on the board as it is.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(recentSolveProvider.notifier).clear();
    });
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (mounted && !_reveal.isCompleted) _reveal.forward();
    });
  }

  bool get _still => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced motion: everything is simply in place.
    if (_still) {
      _book.value = 1;
      _reveal.value = 1;
    }
  }

  @override
  void dispose() {
    _book.dispose();
    _leave.dispose();
    _reveal.dispose();
    super.dispose();
  }

  /// A case on the board: its file in the case files (or why it is sealed).
  void _openFile(SeasonOverview overview, int index) {
    if (overview.marks[index] == CaseMark.sealed) {
      showGameToast(context, 'Solve Case ${overview.cases[index - 1].numberLabel} to open this file.');
      return;
    }
    context.go(Routes.caseFile(overview.cases[index].id));
  }

  /// A touch finishes whatever is still coming in.
  void _finish() {
    if (_book.isAnimating) _book.value = 1;
    if (_reveal.isAnimating) _reveal.value = 1;
  }

  /// BEGIN SEASON ONE: into the city, then the opening sequence.
  Future<void> _begin() async {
    if (_leave.isAnimating || _leave.isCompleted) return;
    if (!_still) await _leave.forward();
    if (mounted) context.go(Routes.prologue);
  }

  @override
  Widget build(BuildContext context) {
    final overview = ref.watch(seasonOverviewProvider);
    return Scaffold(
      backgroundColor: AppColors.nightBottom,
      // The picture (or the desk) runs up under the app bar.
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        foregroundColor: AppColors.goldLight,
        iconTheme: const IconThemeData(color: AppColors.goldLight),
        toolbarHeight: _casebook ? kToolbarHeight : 60,
        leading: IconButton(
          tooltip: 'Back',
          icon: const InkIcon(InkGlyph.back),
          // Over the painting, a faint dark disc keeps the arrow readable.
          style: _casebook ? IconButton.styleFrom(backgroundColor: AppColors.navyDeep.withValues(alpha: 0.45)) : null,
          onPressed: () => context.go(Routes.start),
        ),
        title: _casebook ? null : _Heading(overview),
      ),
      body: Listener(
        onPointerDown: (_) => _finish(),
        child: _casebook
            ? InkSurface(night: true, child: _coverPage(overview))
            : DeskBackground(
                child: SafeArea(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: _boardPage(overview),
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  /// The cover: the London panorama is the screen. The title stands in the
  /// night sky; the button sits on the rooftops below the young detective,
  /// never over them.
  Widget _coverPage(SeasonOverview overview) {
    return AnimatedBuilder(
      animation: Listenable.merge([_book, _leave]),
      builder: (context, _) {
        double iv(double a, double b) => Curves.easeOutCubic.transform(((_book.value - a) / (b - a)).clamp(0.0, 1.0));
        final leave = Curves.easeInCubic.transform(_leave.value);
        final ready = iv(0.55, 1);
        return Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: AppColors.nightBottom),
            _CoverPanorama(scale: 1 + 0.025 * iv(0, 1) + 0.14 * leave),
            // Shade only where words stand: the sky under the title, the
            // rooftops under the button. The city between stays clear.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    for (final a in const [0.72, 0.45, 0.0, 0.0, 0.6]) AppColors.navyDeep.withValues(alpha: a),
                  ],
                  stops: const [0, 0.24, 0.42, 0.8, 1],
                ),
              ),
            ),
            SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
                    child: Column(
                      children: [
                        // The title starts high in the sky (the back arrow keeps its corner).
                        const SizedBox(height: AppSpace.md),
                        Opacity(
                          opacity: iv(0.1, 0.6) * (1 - leave),
                          child: _CoverTitle(overview),
                        ),
                        const Spacer(),
                        Opacity(
                          opacity: ready * (1 - leave),
                          child: IgnorePointer(
                            ignoring: ready < 0.5 || _leave.value > 0,
                            child: GameButton(
                              label: 'BEGIN ${overview.info.label}',
                              arrow: true,
                              singleLine: true,
                              style: GameButtonStyle.glass,
                              // The season's opening sequence comes before its first case.
                              onPressed: _begin,
                            ),
                          ),
                        ),
                        // Raised off the edge so the rooftops show below it: the
                        // button rests on the city, not on the phone. Capped on
                        // tall phones so it stays below the young detective.
                        SizedBox(height: AppSpace.lg + (MediaQuery.sizeOf(context).height * 0.038).clamp(20.0, 28.0)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Into the night, where the opening's first scene begins.
            if (leave > 0) IgnorePointer(child: ColoredBox(color: AppColors.nightBottom.withValues(alpha: leave))),
          ],
        );
      },
    );
  }

  Widget _boardPage(SeasonOverview overview) {
    return LayoutBuilder(
      // The board takes the room the dossier leaves; on a small phone with
      // large text it keeps a usable size and the page scrolls instead.
      builder: (context, box) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.xs, AppSpace.md, AppSpace.sm),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight - AppSpace.xs - AppSpace.sm),
          child: IntrinsicHeight(
            child: AnimatedBuilder(
              animation: _reveal,
              builder: (context, _) {
                final t = _before == null ? 1.0 : _reveal.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _MinHeight(
                        260,
                        child: InvestigationBoard(
                          overview: overview,
                          before: _before,
                          t: t,
                          onCase: (i) => _openFile(overview, i),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpace.md),
                    _Dossier(
                      overview: overview,
                      completeReveal: _before != null && !_before!.complete ? ((t - 0.8) / 0.2).clamp(0.0, 1.0) : 1,
                      onCurrent: () => _openFile(overview, overview.current!),
                      onInvestigate: () => SeasonActions.investigate(context, ref, overview.current!),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// The cover painting: London at night from above, filling the screen.
/// [scale] pushes the camera in, towards Westminster.
class _CoverPanorama extends StatelessWidget {
  const _CoverPanorama({required this.scale});

  final double scale;

  /// When the phone is narrower than the painting (9:16), the crop leans
  /// right: Big Ben stands near the right edge; the young detective, on the
  /// left, stays in.
  static const _focus = Alignment(0.55, 0);

  @override
  Widget build(BuildContext context) {
    const pixels = ArtAssets.season1CoverLondonPanoramaPixels;
    return ClipRect(
      child: LayoutBuilder(
        builder: (context, box) => Transform.scale(
          scale: scale,
          alignment: const Alignment(0.7, -0.15),
          child: Image.asset(
            ArtAssets.season1CoverLondonPanorama,
            fit: BoxFit.cover,
            alignment: _focus,
            width: double.infinity,
            height: double.infinity,
            // Decoded at the width it covers (with room for the push),
            // never above the file.
            cacheWidth: math.min(
              (math.max(box.maxWidth, box.maxHeight * pixels.aspectRatio) * 1.15 * MediaQuery.devicePixelRatioOf(context))
                  .ceil(),
              pixels.width.toInt(),
            ),
            excludeFromSemantics: true,
            errorBuilder: (context, error, stack) => const PaperBackground(night: true, child: SizedBox.expand()),
          ),
        ),
      ),
    );
  }
}

/// The season's title, set in the night sky over the city.
class _CoverTitle extends StatelessWidget {
  const _CoverTitle(this.overview);

  final SeasonOverview overview;

  @override
  Widget build(BuildContext context) {
    final season = overview.info;
    final lift = [Shadow(color: AppColors.navyDeep.withValues(alpha: 0.75), blurRadius: 12)];
    final width = MediaQuery.sizeOf(context).width;
    // Large text grows the title a little, not so much that it covers the city.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.15,
      child: Column(
        children: [
          Text(
            'LONDON MYSTERY',
            style: AppText.eyebrow(color: AppColors.goldLight.withValues(alpha: 0.75)).copyWith(fontSize: 11.5, letterSpacing: 4, shadows: lift),
          ),
          const SizedBox(height: AppSpace.md),
          Text(season.label, style: AppText.eyebrow(color: AppColors.goldLight).copyWith(shadows: lift)),
          const SizedBox(height: AppSpace.xs),
          // Always two lines: the longer one is fitted to the width rather
          // than broken again, so the title never runs down into the city.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              season.title.toUpperCase().replaceFirst(' OVER ', '\nOVER '),
              textAlign: TextAlign.center,
              // Sized to leave London the larger part of the sky line.
              style: AppText.logo(size: (width * 0.082).clamp(26.0, 36.0), color: AppColors.paperLight)
                  .copyWith(height: 1.08, shadows: lift),
            ),
          ),
          const SizedBox(height: AppSpace.md),
          // ── ◆ ── between the title and what the season is.
          const OrnamentRule(color: AppColors.goldLight, width: 150),
          const SizedBox(height: AppSpace.md),
          // Kept clear of Big Ben's clock on the right, even with large text.
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: width * 0.62),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '${overview.total} CASES • ${season.tagline}',
                // A little lighter than the gold and a firmer shade under it:
                // it stands over the first lights of the city.
                style: AppText.eyebrow(color: Color.lerp(AppColors.goldLight, AppColors.paperLight, 0.35)!).copyWith(
                  letterSpacing: 2,
                  shadows: [Shadow(color: AppColors.navyDeep.withValues(alpha: 0.9), blurRadius: 10)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// SEASON ONE / Shadows over London, in the app bar.
class _Heading extends StatelessWidget {
  const _Heading(this.overview);

  final SeasonOverview overview;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(overview.info.label, style: AppText.eyebrow(color: AppColors.goldLight).copyWith(fontSize: 12)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            overview.info.title.toUpperCase(),
            maxLines: 1,
            style: AppText.logo(size: 20, color: AppColors.paperLight).copyWith(letterSpacing: 2),
          ),
        ),
      ],
    );
  }
}

/// The dossier under the board: how far the season has come, the case to
/// work on now and the way to it (or, at the end, that it is complete).
class _Dossier extends StatelessWidget {
  const _Dossier({
    required this.overview,
    required this.completeReveal,
    required this.onCurrent,
    required this.onInvestigate,
  });

  final SeasonOverview overview;

  /// 0 → 1 while the season's completion is being revealed.
  final double completeReveal;
  final VoidCallback onCurrent;
  final VoidCallback onInvestigate;

  @override
  Widget build(BuildContext context) {
    return PaperSheet(
      ruled: true,
      color: AppColors.paper,
      padding: const EdgeInsets.fromLTRB(AppSpace.lg, AppSpace.md, AppSpace.lg, AppSpace.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: '${overview.solvedCount} of ${overview.total} cases solved',
            excludeSemantics: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('CASES SOLVED', style: AppText.eyebrow(color: AppColors.inkBrown))),
                    Text(
                      '${overview.solvedCount} / ${overview.total}',
                      style: AppText.title(size: 22, color: AppColors.navy)
                          .copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpace.xs),
                _SolvedDots(overview.marks),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
            child: Container(height: AppLine.hairline, color: AppLine.faint(0.25)),
          ),
          if (overview.complete) ...[
            Opacity(opacity: completeReveal, child: _Completed(overview)),
            const SizedBox(height: AppSpace.md),
            GameButton(
              label: 'VIEW ALL CASE FILES',
              glyph: InkGlyph.folder,
              singleLine: true,
              onPressed: () => context.go(Routes.episodes),
            ),
            const SizedBox(height: AppSpace.md),
          ] else ...[
            if (overview.currentCase != null) _CurrentCase(overview: overview, onTap: onCurrent),
            const SizedBox(height: AppSpace.sm),
            GameButton(
              label: overview.currentStarted ? 'CONTINUE INVESTIGATION' : 'BEGIN INVESTIGATION',
              arrow: true,
              singleLine: true,
              onPressed: overview.current == null ? null : onInvestigate,
            ),
            Center(
              child: InkTextButton(
                label: 'View all case files',
                glyph: InkGlyph.folder,
                color: AppColors.inkBrown,
                onPressed: () => context.go(Routes.episodes),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One mark per case, in order: solved, the current one, the rest.
class _SolvedDots extends StatelessWidget {
  const _SolvedDots(this.marks);

  final List<CaseMark> marks;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (final m in marks)
          Container(
            width: 11,
            height: 11,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: m == CaseMark.solved ? AppColors.navy : null,
              border: Border.all(
                color: switch (m) {
                  CaseMark.solved => AppColors.navy,
                  CaseMark.current => AppColors.burgundy,
                  _ => AppColors.locked,
                },
                width: m == CaseMark.current ? AppLine.ink : AppLine.hairline,
              ),
            ),
          ),
      ],
    );
  }
}

/// CURRENT CASE: the number tag and title; tapping opens its case file.
class _CurrentCase extends StatelessWidget {
  const _CurrentCase({required this.overview, required this.onTap});

  final SeasonOverview overview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final e = overview.currentCase!;
    return Semantics(
      button: true,
      label: 'Current case: Case ${e.number}, ${e.title}. Open its case file',
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              // The case number, like the tab of its folder.
              Transform.rotate(
                angle: -0.04,
                child: Container(
                  width: 48,
                  padding: const EdgeInsets.symmetric(vertical: AppSpace.xs),
                  decoration: BoxDecoration(
                    color: AppColors.parchment,
                    border: Border.all(color: AppLine.faint(0.3), width: AppLine.hairline),
                    boxShadow: AppShadow.paperLift,
                  ),
                  child: Column(
                    children: [
                      Text('CASE', style: AppText.eyebrow(color: AppColors.inkBrown).copyWith(fontSize: 10, letterSpacing: 1.5)),
                      Text(e.numberLabel, style: AppText.title(size: 20, color: AppColors.navy)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CURRENT CASE', style: AppText.eyebrow(color: AppColors.burgundy)),
                    const SizedBox(height: 2),
                    Text(
                      e.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.placeTitle(size: 19, color: AppColors.ink),
                    ),
                  ],
                ),
              ),
              const InkIcon(InkGlyph.arrow, size: AppIconSize.small, color: AppColors.inkBrown),
            ],
          ),
        ),
      ),
    );
  }
}

/// SEASON ONE COMPLETED, and that the story goes on.
class _Completed extends StatelessWidget {
  const _Completed(this.overview);

  final SeasonOverview overview;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(overview.info.label, style: AppText.eyebrow(color: AppColors.goldDeep)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('COMPLETED', style: AppText.logo(size: 28, color: AppColors.navy)),
        ),
        const SizedBox(height: AppSpace.xs),
        for (final line in overview.info.outro)
          Text(line, textAlign: TextAlign.center, style: AppText.aside(size: 15, color: AppColors.inkBrown)),
      ],
    );
  }
}

/// Gives its child a floor for intrinsic height (the page's
/// [IntrinsicHeight] would otherwise ask the board, which sizes itself from
/// its constraints), and passes layout through unchanged.
class _MinHeight extends SingleChildRenderObjectWidget {
  const _MinHeight(this.height, {required Widget super.child});

  final double height;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderMinHeight(height);

  @override
  void updateRenderObject(BuildContext context, _RenderMinHeight renderObject) => renderObject.height = height;
}

class _RenderMinHeight extends RenderProxyBox {
  _RenderMinHeight(this.height);

  double height;

  @override
  double computeMinIntrinsicHeight(double width) => height;

  @override
  double computeMaxIntrinsicHeight(double width) => height;

  @override
  double computeMinIntrinsicWidth(double height) => 0;

  @override
  double computeMaxIntrinsicWidth(double height) => 0;

  @override
  void performLayout() {
    child!.layout(constraints.copyWith(minHeight: constraints.constrainHeight(height)), parentUsesSize: true);
    size = constraints.constrain(child!.size);
  }
}
