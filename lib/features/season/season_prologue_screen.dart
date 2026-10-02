import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/models/episode.dart';
import '../../data/models/season.dart';
import '../../widgets/art_assets.dart';
import '../../widgets/back_to.dart';
import '../../widgets/desk_background.dart';
import '../../widgets/game_button.dart';
import '../../widgets/ink_icon.dart';
import '../../widgets/paper.dart';
import '../../widgets/paper_background.dart';
import 'season_actions.dart';
import 'season_overview.dart';
import 'widgets/prologue_art.dart';
import 'widgets/season_props.dart';

/// The season's opening sequence, played once — from the casebook, before
/// the first case. Short scenes, one message each, the picture first:
///
///  1. London at night: something strange is happening.
///  2. The desk: the kinds of trouble, laid down one by one.
///  3. The map: they look like separate cases…
///  4. …until the first red thread: what if they're connected?
///  5. The promise: 12 CASES · ONE MYSTERY → ACCEPT THE CASE.
///  6. The first case's file → START CASE 01 → the case's own story intro.
///
/// A tap finishes a scene's animation, then moves on. Back (app bar or
/// system) goes to the scene before; from the first, back to the casebook.
/// Nothing is saved here: the case opens through [SeasonActions].
class SeasonPrologueScreen extends ConsumerStatefulWidget {
  const SeasonPrologueScreen({super.key});

  @override
  ConsumerState<SeasonPrologueScreen> createState() =>
      _SeasonPrologueScreenState();
}

class _SeasonPrologueScreenState extends ConsumerState<SeasonPrologueScreen>
    with SingleTickerProviderStateMixin {
  static const _city = 0,
      _cases = 1,
      _separate = 2,
      _connection = 3,
      _promise = 4,
      _file = 5;

  /// How long each scene takes to come in (a tap finishes it at once).
  static const _durations = [1400, 2600, 1900, 2200, 1200, 1100];

  late final AnimationController _c = AnimationController(vsync: this);
  int _step = _city;

  @override
  void initState() {
    super.initState();
    _show(_city);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  bool get _still => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// Shows scene [step], playing it in (or complete, going back).
  void _show(int step, {bool complete = false}) {
    setState(() => _step = step);
    _c.duration = Duration(milliseconds: _durations[step]);
    if (complete) {
      _c.value = 1;
    } else {
      _c.forward(from: 0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _still) _c.value = 1;
      });
    }
  }

  void _tap() {
    if (_c.isAnimating) {
      _c.value = 1;
    } else if (_step < _promise) {
      _show(_step + 1);
    }
  }

  void _back() {
    if (_step == _city) {
      context.go(Routes.season);
    } else {
      _show(_step - 1, complete: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final overview = ref.watch(seasonOverviewProvider);
    final season = overview.info;
    final first = overview.cases[overview.current ?? 0];
    return BackTo(
      onBack: _back,
      child: Scaffold(
        // Between scenes the picture fades to the dark, never to paper.
        backgroundColor: AppColors.nightBottom,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          foregroundColor: AppColors.goldLight,
          iconTheme: const IconThemeData(color: AppColors.goldLight),
          leading: IconButton(
            tooltip: 'Back',
            icon: const InkIcon(InkGlyph.back),
            onPressed: _back,
          ),
          actions: [
            if (_step < _promise)
              TextButton(
                onPressed: () => _show(_promise),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.goldLight,
                  minimumSize: const Size(64, 48),
                ),
                child: Text(
                  'SKIP ›',
                  style: AppText.eyebrow(
                    color: AppColors.goldLight.withValues(alpha: 0.85),
                  ),
                ),
              ),
          ],
        ),
        body: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _tap,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 420),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            // The map scenes are one picture: only their words change.
            child: KeyedSubtree(
              key: ValueKey(_step == _connection ? _separate : _step),
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) => _scene(season, overview, first),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Part [a]..[b] of this scene's animation, eased.
  double _iv(double a, double b) =>
      Curves.easeOutCubic.transform(((_c.value - a) / (b - a)).clamp(0.0, 1.0));

  Widget _scene(Season season, SeasonOverview overview, Episode first) {
    final p = season.prologue;
    switch (_step) {
      case _city:
        return _SceneLayout(
          // The whole screen is London: the picture full-bleed, a little
          // shade at the top for Back / SKIP and at the bottom for the words.
          background: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: AppColors.nightBottom),
              LondonNightHero(push: _iv(0, 1)),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      for (final a in const [0.6, 0.0, 0.0, 0.74, 0.92])
                        AppColors.navyDeep.withValues(alpha: a),
                    ],
                    stops: const [0, 0.16, 0.52, 0.76, 1],
                  ),
                ),
              ),
            ],
          ),
          night: true,
          words: _Words(
            children: [
              Opacity(
                opacity: _iv(0.2, 0.55),
                child: Text(
                  'LONDON',
                  style: AppText.logo(size: 34, color: AppColors.goldLight)
                      .copyWith(
                        letterSpacing: 10,
                        // Lifted off the lit river behind it.
                        shadows: [
                          Shadow(
                            color: AppColors.navyDeep.withValues(alpha: 0.8),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                ),
              ),
              const SizedBox(height: AppSpace.md),
              Opacity(opacity: _iv(0.45, 0.85), child: _Line(p.city, size: 19)),
            ],
          ),
          footer: _NextBar(step: _step, onNext: _tap),
        );
      case _cases:
        return _SceneLayout(
          art: _TroubleDesk(appear: (i) => _iv(i * 0.22, i * 0.22 + 0.3)),
          words: _Words(
            children: [
              for (final (i, line) in p.cases.indexed)
                Opacity(
                  opacity: _iv(i * 0.22 + 0.08, i * 0.22 + 0.34),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: AppSpace.xs),
                    child: _Line(line, size: 17),
                  ),
                ),
            ],
          ),
          footer: _NextBar(step: _step, onNext: _tap),
        );
      case _separate:
      case _connection:
        final connecting = _step == _connection;
        return _SceneLayout(
          art: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
            child: TroubleMap(
              pinned: connecting ? 1 : _iv(0, 0.45),
              threads: connecting ? _iv(0, 0.35) + _iv(0.25, 0.6) : 0,
              push: connecting ? 0.5 + 0.5 * _iv(0, 1) : 0.5 * _iv(0, 1),
            ),
          ),
          words: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: connecting
                ? _Words(
                    key: const ValueKey('connection'),
                    children: [
                      Opacity(
                        opacity: _iv(0.45, 0.7),
                        child: Text(
                          p.question,
                          textAlign: TextAlign.center,
                          style: AppText.title(
                            size: 25,
                            color: AppColors.goldLight,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpace.md),
                      Opacity(
                        opacity: _iv(0.7, 0.95),
                        child: _Line(p.bigger, size: 17),
                      ),
                    ],
                  )
                : _Words(
                    key: const ValueKey('separate'),
                    children: [
                      for (final (i, line) in p.separate.indexed) ...[
                        Opacity(
                          opacity: i == 0 ? _iv(0.2, 0.45) : _iv(0.62, 0.9),
                          child: _Line(line, size: 19),
                        ),
                        if (i == 0) const SizedBox(height: AppSpace.md),
                      ],
                    ],
                  ),
          ),
          footer: _NextBar(step: _step, onNext: _tap),
        );
      case _promise:
        return _SceneLayout(
          art: Stack(
            fit: StackFit.expand,
            children: [
              // The map from before, in the dark behind the promise.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
                child: Opacity(
                  opacity: 0.22,
                  child: TroubleMap(threads: 2, push: 1),
                ),
              ),
              Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpace.xl,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Opacity(
                          opacity: _iv(0, 0.4),
                          child: Column(
                            children: [
                              Text(
                                season.label,
                                style: AppText.eyebrow(
                                  color: AppColors.goldLight,
                                ),
                              ),
                              const SizedBox(height: AppSpace.xs),
                              Text(
                                season.title.toUpperCase(),
                                style: AppText.logo(
                                  size: 20,
                                  color: AppColors.paperLight,
                                ).copyWith(letterSpacing: 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpace.xl),
                        Opacity(
                          opacity: _iv(0.2, 0.6),
                          child: Column(
                            children: [
                              Text(
                                '${overview.total} CASES',
                                style: AppText.logo(
                                  size: 38,
                                  color: AppColors.goldLight,
                                ),
                              ),
                              const SizedBox(height: AppSpace.sm),
                              const OrnamentRule(
                                color: AppColors.goldLight,
                                width: 150,
                              ),
                              const SizedBox(height: AppSpace.sm),
                              Text(
                                season.tagline,
                                style: AppText.logo(
                                  size: 38,
                                  color: AppColors.paperLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          words: _Words(
            children: [
              for (final (i, line) in p.promise.indexed)
                Opacity(
                  opacity: _iv(0.45 + 0.12 * i, 0.75 + 0.08 * i),
                  child: _Line(line, size: 17),
                ),
            ],
          ),
          footer: _Footer(
            raised: true,
            child: GameButton(
              label: 'ACCEPT THE CASE',
              arrow: true,
              singleLine: true,
              style: GameButtonStyle.glass,
              onPressed: () => _show(_file),
            ),
          ),
        );
      default:
        return _SceneLayout(
          art: _CaseFile(
            episode: first,
            picture: p.firstCasePicture,
            line: p.firstCaseLine,
            t: _c.value,
          ),
          footer: _Footer(
            raised: true,
            child: Opacity(
              opacity: 0.3 + 0.7 * _iv(0.5, 1),
              child: GameButton(
                label: 'START CASE ${first.numberLabel}',
                arrow: true,
                singleLine: true,
                style: GameButtonStyle.glass,
                onPressed: () => SeasonActions.investigate(
                  context,
                  ref,
                  overview.cases.indexOf(first),
                ),
              ),
            ),
          ),
        );
    }
  }
}

/// One scene: its background, the picture (most of the screen), the words
/// under it, and the way on. Fits a 360×640 phone without scrolling.
class _SceneLayout extends StatelessWidget {
  const _SceneLayout({
    this.background,
    this.art,
    this.words,
    required this.footer,
    this.night = false,
  });

  /// Full screen behind everything (default: the desk).
  final Widget? background;
  final Widget? art;
  final Widget? words;
  final Widget footer;
  final bool night;

  @override
  Widget build(BuildContext context) {
    final page = SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            children: [
              const SizedBox(height: kToolbarHeight),
              Expanded(child: art ?? const SizedBox.expand()),
              ?words,
              footer,
            ],
          ),
        ),
      ),
    );
    if (background == null) return DeskBackground(child: page);
    return Stack(
      fit: StackFit.expand,
      children: [
        background!,
        InkSurface(night: night, child: page),
      ],
    );
  }
}

/// The scene's words, centred under the picture.
class _Words extends StatelessWidget {
  const _Words({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.xl,
        AppSpace.lg,
        AppSpace.xl,
        AppSpace.sm,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

/// A line of the story, in the storybook italic.
class _Line extends StatelessWidget {
  const _Line(this.text, {this.size = 18});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) => Text(
    text,
    textAlign: TextAlign.center,
    style: AppText.aside(
      size: size,
      color: AppColors.paperLight.withValues(alpha: 0.92),
    ),
  );
}

class _Footer extends StatelessWidget {
  const _Footer({required this.child, this.raised = false});

  final Widget child;

  /// Off the bottom edge like the title page's and the cover's button
  /// (a little more room under it on taller phones).
  final bool raised;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(
      AppSpace.lg,
      AppSpace.sm,
      AppSpace.lg,
      raised
          ? AppSpace.sm +
                (MediaQuery.sizeOf(context).height * 0.038).clamp(20.0, 28.0)
          : AppSpace.md,
    ),
    child: child,
  );
}

/// Where the sequence is (five scenes before the file), and NEXT.
class _NextBar extends StatelessWidget {
  const _NextBar({required this.step, required this.onNext});

  final int step;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.xl,
        0,
        AppSpace.sm,
        AppSpace.xs,
      ),
      child: Row(
        children: [
          Semantics(
            label: 'Scene ${step + 1} of 5',
            excludeSemantics: true,
            child: Row(
              children: [
                for (var i = 0; i < 5; i++)
                  Container(
                    width: i == step ? 18 : 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: AppSpace.xs),
                    decoration: BoxDecoration(
                      color: AppColors.goldLight.withValues(
                        alpha: i == step ? 0.9 : 0.3,
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ),
          const Spacer(),
          InkTextButton(
            label: 'NEXT ›',
            color: AppColors.goldLight,
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

/// The desk, and the four kinds of trouble laid on it one by one.
class _TroubleDesk extends StatelessWidget {
  const _TroubleDesk({required this.appear});

  /// How far piece [i] has been laid down (0..1).
  final double Function(int i) appear;

  static const _spots = [
    Alignment(-0.95, -0.9),
    Alignment(0.95, -0.62),
    Alignment(-0.9, 0.68),
    Alignment(0.95, 0.95),
  ];
  static const _tilts = [-0.09, 0.07, 0.06, -0.05];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpace.lg,
        vertical: AppSpace.sm,
      ),
      child: LayoutBuilder(
        builder: (context, box) {
          // Each piece on its own part of the desk, barely touching.
          final size = (box.maxWidth * 0.47).clamp(0.0, box.maxHeight * 0.5);
          return Stack(
            children: [
              for (final (i, piece) in TroublePiece.values.indexed)
                () {
                  final p = appear(i);
                  return Align(
                    alignment: _spots[i],
                    child: Opacity(
                      opacity: p,
                      // Laid down: from a little above, settling onto the desk.
                      child: Transform.translate(
                        offset: Offset(0, -18 * (1 - p)),
                        child: Transform.rotate(
                          angle: _tilts[i] * (2 - p),
                          child: Transform.scale(
                            scale: 1.06 - 0.06 * p,
                            child: SizedBox(
                              width: size,
                              height: size * 0.9,
                              child: TroublePrint(piece, border: 5),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }(),
            ],
          );
        },
      ),
    );
  }
}

/// The first case's file, slid onto the desk and stamped ASSIGNED.
class _CaseFile extends StatelessWidget {
  const _CaseFile({
    required this.episode,
    required this.picture,
    required this.line,
    required this.t,
  });

  final Episode episode;
  final String picture;
  final String line;
  final double t;

  double _iv(double a, double b) =>
      Curves.easeOutCubic.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

  @override
  Widget build(BuildContext context) {
    final slide = _iv(0, 0.5);
    final stamp = Curves.easeInCubic.transform(
      ((t - 0.55) / 0.25).clamp(0.0, 1.0),
    );
    final file = ArtAssets.objects[picture];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.sm,
        AppSpace.lg,
        AppSpace.sm,
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: 328,
            child: Opacity(
              opacity: slide,
              child: Transform.translate(
                offset: Offset(0, 60 * (1 - slide)),
                child: Transform.rotate(
                  angle: -0.02,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CaseFolder(
                        tab: 'CASE ${episode.numberLabel}',
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpace.lg,
                            AppSpace.lg,
                            AppSpace.lg,
                            AppSpace.xl,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CASE FILE',
                                style: AppText.eyebrow(
                                  color: AppColors.burgundy,
                                ),
                              ),
                              const SizedBox(height: AppSpace.xs),
                              Text(
                                episode.title.toUpperCase(),
                                style: AppText.logo(
                                  size: 24,
                                  color: AppColors.navy,
                                ),
                              ),
                              const SizedBox(height: AppSpace.md),
                              if (file != null)
                                Align(
                                  child: Transform.rotate(
                                    angle: 0.03,
                                    child: SizedBox(
                                      width: 200,
                                      height: 150,
                                      child: PrintFrame.file(file, border: 5),
                                    ),
                                  ),
                                ),
                              const SizedBox(height: AppSpace.lg),
                              if (episode.synopsis.isNotEmpty)
                                Text(
                                  episode.synopsis.first,
                                  style: AppText.bodyText(
                                    size: 17,
                                    weight: FontWeight.w700,
                                  ),
                                ),
                              const SizedBox(height: AppSpace.md),
                              Text(
                                line,
                                style: AppText.aside(
                                  size: 16,
                                  color: AppColors.inkBrown,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (stamp > 0)
                        // On the empty corner by the last line, clear of the title.
                        Positioned(
                          right: AppSpace.lg,
                          bottom: AppSpace.xl,
                          child: Opacity(
                            opacity: stamp,
                            child: Transform.scale(
                              scale: 1.6 - 0.6 * stamp,
                              child: const InkStamp('ASSIGNED', size: 13),
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
    );
  }
}
