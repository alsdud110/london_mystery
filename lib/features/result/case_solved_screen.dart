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
import '../../widgets/badge_medal.dart';
import '../../widgets/ink_icon.dart';
import '../../widgets/landmark_art.dart';
import '../../widgets/letter_card.dart';
import '../../widgets/paper_background.dart';
import '../../widgets/game_button.dart';
import '../game/game_controller.dart';
import '../game/game_providers.dart';
import '../game_master/parent_gate.dart';
import 'detective_report.dart';

/// Kid-facing result, designed as a detective's case file rather than a
/// score sheet — pretty enough that parents want to share a screenshot.
class CaseSolvedScreen extends ConsumerStatefulWidget {
  const CaseSolvedScreen({super.key});

  @override
  ConsumerState<CaseSolvedScreen> createState() => _CaseSolvedScreenState();
}

class _CaseSolvedScreenState extends ConsumerState<CaseSolvedScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2800));

  @override
  void initState() {
    super.initState();
    _c.forward();
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (mounted) ref.read(audioServiceProvider).play(GameSound.success);
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Animation<double> _iv(double a, double b, [Curve curve = Curves.easeOutCubic]) =>
      CurvedAnimation(parent: _c, curve: Interval(a, b, curve: curve));

  /// The report is for grown-ups: ask the parent gate every time, and take
  /// the pass back as soon as the report is closed.
  Future<void> _openParentReport() async {
    if (!await ParentGate.show(context) || !mounted) return;
    final access = ref.read(parentReportAccessProvider.notifier)..grant();
    await context.push(Routes.report);
    access.revoke();
  }

  Future<void> _playAgain() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.paper,
        title: Text('Play the case again?', style: AppText.title(size: 22)),
        content: Text('Your clues and results will be cleared.', style: AppText.bodyText(size: 16)),
        actions: [
          TextButton(onPressed: () => context.pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => context.pop(true), child: const Text('Play again')),
        ],
      ),
    );
    if (ok == true && mounted) {
      ref.read(gameControllerProvider.notifier).playAgain();
      context.go(Routes.episodes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final report = DetectiveReport.from(ref.watch(currentEpisodeProvider), ref.watch(gameControllerProvider));
    final paper = _iv(0, 0.25, Curves.easeOutBack);
    final stamp = _iv(0.3, 0.45, Curves.easeInCubic);
    final xp = _iv(0.4, 0.75);
    final badge = _iv(0.6, 0.85, Curves.elasticOut);
    final footer = _iv(0.8, 1);

    return Scaffold(
      body: PaperBackground(
        night: true,
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
                          Text('London needs you again.',
                              style: AppText.subtitle(color: AppColors.goldLight), textAlign: TextAlign.center),
                          const SizedBox(height: 16),
                          GameButton(
                            label: 'VIEW MY DETECTIVE REPORT',
                            glyph: InkGlyph.folder,
                            style: GameButtonStyle.gold,
                            onPressed: _openParentReport,
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: InkTextButton(
                                  label: 'Notebook',
                                  glyph: InkGlyph.notebook,
                                  color: Colors.white70,
                                  onPressed: () => context.push(Routes.notebook),
                                ),
                              ),
                              // Custom Asset Required: a replay glyph.
                              Expanded(
                                child: InkTextButton(label: 'Play again', color: Colors.white70, onPressed: _playAgain),
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

/// The paper case file itself.
class _CaseFile extends StatelessWidget {
  const _CaseFile({required this.report, required this.stamp, required this.xpShown, required this.badgePop});

  final DetectiveReport report;
  final double stamp;
  final int xpShown;
  final double badgePop;

  @override
  Widget build(BuildContext context) {
    final top = report.topBadge;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFFAEC), AppColors.parchment, Color(0xFFEAD8AE)],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.parchmentDark, width: 2),
            boxShadow: const [BoxShadow(color: Color(0x66000000), blurRadius: 26, offset: Offset(0, 12))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Custom Asset Required: a brass push-pin for the file corner.
              Text('LONDON MYSTERY · FILE ${report.episode.numberLabel}', style: AppText.eyebrow(color: AppColors.inkBrown)),
              const SizedBox(height: 10),
              Text('CASE CLOSED', style: AppText.logo(size: 36, color: AppColors.navy), textAlign: TextAlign.center),
              const _Rule(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _Field(label: 'Detective', value: report.detectiveName, big: true)),
                  const SizedBox(width: 12),
                  _Photo(),
                ],
              ),
              const SizedBox(height: 10),
              _Field(label: 'Case', value: report.episode.title.toUpperCase()),
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
              _Row(label: 'Hints', value: '${report.hintsUsed}'),
              _Row(label: 'Time', value: Formatters.clock(report.elapsed)),
              _Row(
                label: 'XP',
                child: Text('$xpShown',
                    style: AppText.logo(size: 26, color: AppColors.goldDeep)
                        .copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
              ),
              if (top != null) ...[
                const _Rule(),
                Row(
                  children: [
                    Transform.scale(
                      scale: badgePop.clamp(0.0, 1.2),
                      child: BadgeMedal(badge: top, size: 70, showLabel: false),
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
                                  Tooltip(message: b.title, child: BadgeMedal(badge: b, size: 30, showLabel: false)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
              const _Rule(),
              Text('CASE REPORT', style: AppText.eyebrow(color: AppColors.inkBrown)),
              const SizedBox(height: 8),
              Text('"${report.caseSummary}"', style: AppText.letter(size: 18)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text('— London Mystery Detective Agency',
                        style: AppText.caption(color: AppColors.inkBrown)),
                  ),
                  const WaxSeal(size: 50),
                ],
              ),
            ],
          ),
        ),
        // The red stamp slams down onto the file.
        if (stamp > 0)
          Positioned(
            top: 180,
            right: 30,
            child: IgnorePointer(
              child: Opacity(
                opacity: stamp.clamp(0, 1),
                child: Transform.rotate(
                  angle: -0.25,
                  child: Transform.scale(scale: 2.2 - 1.2 * stamp, child: const _Stamp()),
                ),
              ),
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
          Text('★ ★ ★', style: AppText.button(size: 11, color: AppColors.waxRed.withValues(alpha: 0.9))),
        ],
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: 0.05,
      child: Container(
        width: 96,
        height: 96,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(1, 3))],
          borderRadius: BorderRadius.circular(4),
        ),
        child: const LandmarkArt(Artwork.royalBox, borderRadius: 2),
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
  const _Field({required this.label, required this.value, this.big = false});

  final String label;
  final String value;
  final bool big;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: AppText.eyebrow(color: AppColors.inkBrown)),
        const SizedBox(height: 2),
        Text(value, style: AppText.title(size: big ? 28 : 20)),
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
          Expanded(child: Text(label, style: AppText.subtitle(color: AppColors.inkBrown))),
          child ?? Text(value ?? '', style: AppText.title(size: 21)),
        ],
      ),
    );
  }
}
