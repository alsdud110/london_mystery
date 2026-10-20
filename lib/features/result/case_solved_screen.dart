import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/audio_service.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/mission.dart';
import '../../widgets/art_assets.dart';
import '../../widgets/badge_medal.dart';
import '../../widgets/detective_character.dart';
import '../../widgets/ink_icon.dart';
import '../../widgets/landmark_art.dart';
import '../../widgets/letter_card.dart';
import '../../widgets/paper.dart';
import '../../widgets/place_art.dart';
import '../../widgets/desk_background.dart';
import '../../widgets/game_button.dart';
import '../../widgets/game_dialog.dart';
import '../game/game_controller.dart';
import '../game/game_providers.dart';
import '../game_master/parent_gate.dart';
import '../season/season_overview.dart';
import 'detective_report.dart';
import '../../data/models/detective_name.dart';

/// Kid-facing result, designed as a detective's case file rather than a
/// score sheet — pretty enough that parents want to share a screenshot.
class CaseSolvedScreen extends ConsumerStatefulWidget {
  const CaseSolvedScreen({super.key});

  @override
  ConsumerState<CaseSolvedScreen> createState() => _CaseSolvedScreenState();
}

class _CaseSolvedScreenState extends ConsumerState<CaseSolvedScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800))
    ..addListener(_stampDown);

  /// The stamp comes down over 0.3..0.45 of the page and meets the paper at
  /// its end (about 1.26 s in).
  static const _stampLands = 0.45;
  bool _stamped = false;

  /// Once, as the stamp meets the paper (at once with reduced motion, when
  /// the closed file is simply there).
  void _stampDown() {
    if (_stamped || _c.value < _stampLands) return;
    _stamped = true;
    ref.read(audioServiceProvider).play(GameSound.caseStamp);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reduced motion: the closed file is simply there, stamp and all.
    if (_c.isDismissed && (MediaQuery.maybeDisableAnimationsOf(context) ?? false)) _c.value = 1;
  }

  @override
  void initState() {
    super.initState();
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Animation<double> _iv(double a, double b, [Curve curve = Curves.easeOutCubic]) => CurvedAnimation(
    parent: _c,
    curve: Interval(a, b, curve: curve),
  );

  /// The report is for grown-ups: ask the parent gate every time, and take
  /// the pass back as soon as the report is closed.
  Future<void> _openParentReport() async {
    if (!await ParentGate.show(context) || !mounted) return;
    final access = ref.read(parentReportAccessProvider.notifier)..grant();
    await context.push(Routes.report);
    access.revoke();
  }

  Future<void> _playAgain() async {
    final ok = await GameDialog.confirm(
      context,
      title: 'Play the case again?',
      message: 'Your clues and results will be cleared.',
      confirmLabel: 'Play again',
      cancelLabel: 'Cancel',
    );
    if (ok && mounted) {
      ref.read(gameControllerProvider.notifier).playAgain();
      context.go(Routes.episodes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = DetectiveReport.from(ref.watch(currentEpisodeProvider), ref.watch(gameControllerProvider));
    final catalog = ref.watch(episodeCatalogProvider);
    final at = catalog.indexWhere((e) => e.id == report.episode.id);
    final nextCase = at >= 0 && at + 1 < catalog.length ? catalog[at + 1] : null;
    // On to the investigation board, where the solved case lands and the
    // next case waits under BEGIN INVESTIGATION (the same taps as through
    // the case files). Only when the board's current case is the next case:
    // a case played again keeps OPEN CASE NN opening case NN's file.
    final toBoard = nextCase == null || ref.watch(seasonOverviewProvider).currentCase?.id == nextCase.id;
    final season = ref.watch(seasonInfoProvider);
    // The season goes on, but its next case is not in the game yet: said so
    // plainly, never offered as a case to open.
    final comingNext = nextCase == null && catalog.length < (season.plannedCases ?? 0) ? catalog.length + 1 : null;
    final paper = _iv(0, 0.25);
    // The detective who closed it rises behind the file as it lands, just
    // before the stamp comes down.
    final detective = _iv(0.15, 0.38);
    final stamp = _iv(0.3, 0.45, Curves.easeInCubic);
    final xp = _iv(0.4, 0.75);
    final badge = _iv(0.6, 0.85);
    final footer = _iv(0.8, 1);

    return Scaffold(
      // The closed case file on the detective's desk (the same walnut desk as
      // the WELL DONE moment and the season board), not the night sky.
      body: DeskBackground(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: AnimatedBuilder(
                animation: _c,
                builder: (context, _) => ListView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
                  children: [
                    Opacity(
                      opacity: paper.value.clamp(0, 1),
                      child: Transform.translate(
                        offset: Offset(0, 60 * (1 - paper.value)),
                        child: _CaseFile(
                          report: report,
                          detective: detective.value,
                          stamp: stamp.value,
                          xpShown: (report.xp * xp.value).round(),
                          badgePop: badge.value,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Opacity(
                      opacity: footer.value,
                      child: Column(
                        children: [
                          // What the case left unanswered is told by the post-case
                          // scene before this report (Episode.hook is not repeated
                          // here: it would echo that scene, or spoil the next case).
                          Text(
                            '${season.city} needs you again.',
                            style: AppText.cinematicPrompt(size: 22),
                            textAlign: TextAlign.center,
                          ),
                          if (comingNext != null) ...[
                            const SizedBox(height: AppSpace.sm),
                            Text(
                              'CASE ${comingNext.toString().padLeft(2, '0')} · COMING SOON',
                              key: const ValueKey('next-case-coming-soon'),
                              style: AppText.eyebrow(color: AppColors.goldLight),
                              textAlign: TextAlign.center,
                            ),
                          ],
                          const SizedBox(height: 16),
                          // The child's next step is the primary action: on to the
                          // next case (after the last case of the season, the
                          // season's completed investigation board).
                          GameButton(
                            label: nextCase != null ? 'OPEN CASE ${nextCase.numberLabel}' : 'INVESTIGATION BOARD',
                            glyph: nextCase != null ? InkGlyph.folder : InkGlyph.pin,
                            arrow: true,
                            singleLine: true,
                            style: GameButtonStyle.glass,
                            tap: TapRole.primary,
                            onPressed: () => context.go(toBoard ? Routes.season : Routes.caseFile(nextCase.id)),
                          ),
                          const SizedBox(height: AppSpace.md),
                          // For grown-ups (behind the parent gate): secondary, and
                          // the lock says it asks first.
                          GameButton(
                            label: 'VIEW MY DETECTIVE REPORT',
                            glyph: InkGlyph.lock,
                            singleLine: true, // one line on a 360-wide phone
                            style: GameButtonStyle.outline,
                            onPressed: _openParentReport,
                          ),
                          const SizedBox(height: AppSpace.sm),
                          Row(
                            children: [
                              Expanded(
                                child: InkTextButton(
                                  label: 'Notebook',
                                  glyph: InkGlyph.notebook,
                                  color: AppColors.paperLight.withValues(alpha: 0.75),
                                  onPressed: () => context.push(Routes.notebook),
                                ),
                              ),
                              // Custom Asset Required: a replay glyph.
                              Expanded(
                                child: InkTextButton(
                                  label: 'Play again',
                                  color: AppColors.paperLight.withValues(alpha: 0.75),
                                  onPressed: _playAgain,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The paper case file itself, the player's detective standing behind it,
/// waist up over its top edge (confident: the case is theirs).
class _CaseFile extends StatelessWidget {
  const _CaseFile({
    required this.report,
    required this.detective,
    required this.stamp,
    required this.xpShown,
    required this.badgePop,
  });

  final DetectiveReport report;

  /// How far the detective has come in (0..1).
  final double detective;
  final double stamp;
  final int xpShown;
  final double badgePop;

  @override
  Widget build(BuildContext context) {
    final top = report.topBadge;
    // The case's emblem (Case 01: the Crown), else its small photo.
    final emblem = ArtAssets.caseClosedEmblems[report.episode.id];
    final standing = DetectiveCast.shows(DetectiveMoment.caseSolved);
    // Taller than at a mission's solve (Discovery); less on a short phone.
    final height = MediaQuery.sizeOf(context).height < 700 ? 150.0 : 190.0;
    // The file is laid over the detective's faded waist.
    final behind = standing ? height * 0.8 : 0.0;
    final shown = detective.clamp(0.0, 1.0);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (standing)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              // Rises a little into place behind the file: no spring.
              child: Opacity(
                opacity: shown,
                child: Transform.translate(
                  offset: Offset(0, 14 * (1 - shown)),
                  child: PlayerDetective(
                    moment: DetectiveMoment.caseSolved,
                    size: height,
                    entrance: false,
                    halo: true,
                    semanticLabel: '${DetectiveName.title(report.detectiveName)}, case solved',
                  ),
                ),
              ),
            ),
          ),
        Container(
          margin: EdgeInsets.only(top: behind),
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFAEC), AppColors.parchment, Color(0xFFEAD8AE)],
            ),
            borderRadius: BorderRadius.circular(AppRadius.paper),
            border: Border.all(color: AppColors.parchmentDark, width: AppLine.hairline),
            boxShadow: AppShadow.onNight,
          ),
          foregroundDecoration: const RuledFrame(inset: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Custom Asset Required: a brass push-pin for the file corner.
              Text(
                'LONDON MYSTERY · FILE ${report.episode.numberLabel}',
                style: AppText.eyebrow(color: AppColors.inkBrown),
              ),
              const SizedBox(height: 10),
              Text(
                'CASE CLOSED',
                style: AppText.logo(size: 36, color: AppColors.navy),
                textAlign: TextAlign.center,
              ),
              const _Rule(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _Field(label: 'Detective', value: report.detectiveName, big: true),
                  ),
                  const SizedBox(width: 12),
                  // The red stamp comes down on the case photo: placed by the
                  // photo, not at a fixed point of the page, so it never covers
                  // the name whatever the text size. A case with an emblem
                  // (below its title) has no photo: the stamp comes down on
                  // the paper in the photo's place.
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (emblem == null)
                        _Photo(scene: PlaceArt.sceneOf(report.episode.finalMission))
                      else
                        const SizedBox(key: ValueKey('case-closed-stamp-spot'), width: 112, height: 64),
                      if (stamp > 0)
                        Positioned(
                          // On the paper (no photo): kept off the name.
                          left: emblem == null ? -AppSpace.md : 0,
                          right: -AppSpace.md,
                          top: emblem == null ? 34 : 6,
                          child: IgnorePointer(
                            child: Opacity(
                              opacity: stamp.clamp(0, 1),
                              child: Transform.rotate(
                                angle: -0.25,
                                child: Transform.scale(
                                  scale: 2.2 - 1.2 * stamp,
                                  child: const FittedBox(fit: BoxFit.scaleDown, child: _Stamp()),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: emblem == null ? 10 : 2),
              _Field(label: 'Case', value: report.episode.title.toUpperCase(), name: true),
              // What the case was about, alone on the paper, under its title:
              // no frame, no tilt, no shadow.
              if (emblem != null)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpace.md),
                  child: Center(
                    child: LayoutBuilder(
                      builder: (context, box) {
                        final side = (box.maxWidth * 0.42).clamp(96.0, 150.0);
                        return Image.asset(
                          emblem,
                          key: const ValueKey('case-closed-emblem'),
                          width: side,
                          height: side,
                          fit: BoxFit.contain,
                          semanticLabel: report.episode.allEvidence.last.name,
                          errorBuilder: (context, error, stack) => const SizedBox.shrink(),
                        );
                      },
                    ),
                  ),
                ),
              const _Rule(),
              _Row(
                label: 'Missions',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < report.missionsTotal; i++)
                      InkStar(filled: i < report.missionsCompleted, color: AppColors.gold, size: AppIconSize.regular),
                  ],
                ),
              ),
              _Row(label: 'Clues Found', value: '${report.cluesFound} / ${report.cluesTotal}'),
              _Row(label: 'Evidence', value: '${report.evidenceFound} / ${report.evidenceTotal}'),
              _Row(label: 'Hints', value: report.hasPlayRecord ? '${report.hintsUsed}' : '—'),
              _Row(label: 'Time', value: report.elapsed == null ? '—' : Formatters.clock(report.elapsed!)),
              _Row(
                label: 'XP',
                child: Text(
                  '$xpShown',
                  style: AppText.title(
                    size: 26,
                    color: AppColors.goldDeep,
                  ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
                ),
              ),
              if (top != null) ...[
                const _Rule(),
                Row(
                  children: [
                    // The medal is pinned on: a short fade and settle, no spring.
                    Opacity(
                      opacity: badgePop.clamp(0.0, 1.0),
                      child: Transform.scale(
                        scale: 0.85 + 0.15 * badgePop.clamp(0.0, 1.0),
                        child: BadgeMedal(badge: top, size: 70, showLabel: false),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('BADGE', style: AppText.eyebrow(color: AppColors.inkBrown)),
                          Text(top.title.toUpperCase(), style: AppText.title(size: 22)),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final b in report.badges)
                                if (b != top)
                                  Tooltip(
                                    message: b.title,
                                    child: BadgeMedal(badge: b, size: 30, showLabel: false),
                                  ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              const _Rule(),
              Text('CASE REPORT', style: AppText.mark(color: AppColors.inkBrown)),
              const SizedBox(height: 8),
              Text('"${report.caseSummary}"', style: AppText.letter(size: 18)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text('— London Mystery Detective Agency', style: AppText.caption(color: AppColors.inkBrown)),
                  ),
                  const WaxSeal(size: 50),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.waxRed.withValues(alpha: 0.85), width: 3.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('SOLVED', style: AppText.logo(size: 22, color: AppColors.waxRed.withValues(alpha: 0.9))),
          Text('★ ★ ★', style: AppText.button(size: 13, color: AppColors.waxRed.withValues(alpha: 0.9))),
        ],
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({required this.scene});

  final Artwork scene;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.05,
      child: Container(
        // A picture shows whole at its own ratio; a drawing stays square.
        width: LandmarkArt.hasPicture(scene, solved: 1) ? 86 * LandmarkArt.aspectOf(scene, solved: 1) + 10 : 96,
        height: 96,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: AppColors.paperLight,
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(1, 3))],
          borderRadius: BorderRadius.circular(2),
        ),
        child: LandmarkArt(scene, borderRadius: 2, solved: 1),
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: LayoutBuilder(
        builder: (context, box) {
          final count = (box.maxWidth / 10).floor();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < count; i++)
                Container(width: 6, height: 2, color: AppColors.inkBrown.withValues(alpha: 0.4)),
            ],
          );
        },
      ),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.value, this.big = false, this.name = false});

  final String label;
  final String value;
  final bool big;

  /// A name of the world (the case): the display face.
  final bool name;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppText.eyebrow(color: AppColors.inkBrown)),
        const SizedBox(height: 2),
        // A name is one word: it shrinks to fit rather than breaking
        // mid-word ("MINYOUN / G") on a narrow phone.
        big
            ? FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, maxLines: 1, style: AppText.title(size: 28)),
              )
            : Text(value, style: name ? AppText.placeTitle(size: 21) : AppText.title(size: 20)),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, this.value, this.child});

  final String label;
  final String? value;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: AppText.subtitle(color: AppColors.inkBrown)),
          ),
          child ?? Text(value ?? '', style: AppText.title(size: 21)),
        ],
      ),
    );
  }
}
