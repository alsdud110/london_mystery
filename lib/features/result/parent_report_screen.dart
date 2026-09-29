import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/mission.dart';
import '../../widgets/ink_icon.dart';
import '../../widgets/paper_background.dart';
import '../game/game_controller.dart';
import '../game/game_providers.dart';
import 'detective_report.dart';

/// Parent-facing summary, styled as a game report rather than a report card.
class ParentReportScreen extends ConsumerWidget {
  const ParentReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = DetectiveReport.from(ref.watch(currentEpisodeProvider), ref.watch(gameControllerProvider));

    return Scaffold(
      appBar: AppBar(
        title: const Text('DETECTIVE REPORT'),
        leading: IconButton(
          tooltip: 'Back',
          icon: const InkIcon(InkGlyph.back),
          onPressed: () => context.canPop() ? context.pop() : context.go(Routes.solved),
        ),
      ),
      body: PaperBackground(
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 36),
                children: [
                  _ReportHeader(report: report),
                  const SizedBox(height: 16),
                  _Section(
                    title: 'English Skills',
                    subtitle: '게임 속에서 사용한 영어 능력',
                    child: Column(
                      children: [
                        for (final s in Skill.values)
                          _SkillRow(
                            label: DetectiveReport.skillLabel(s),
                            labelKo: DetectiveReport.skillLabelKo(s),
                            stars: report.skillStars[s] ?? 1,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Section(
                    title: 'Mission Performance',
                    subtitle: '미션 수행 기록',
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _Metric(label: 'Accuracy', labelKo: '정답률', value: '${report.accuracyPercent}%'),
                            _Metric(label: 'Hints Used', labelKo: '힌트 사용', value: '${report.hintsUsed}'),
                            _Metric(label: 'Completion Time', labelKo: '플레이 시간', value: Formatters.minutes(report.elapsed)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _Metric(label: 'First Try', labelKo: '한 번에 해결', value: '${report.firstTryCount}'),
                            _Metric(label: 'Words Checked', labelKo: '찾아본 단어', value: '${report.wordsLookedUp}'),
                            _Metric(label: 'Badges', labelKo: '획득 배지', value: '${report.badges.length}'),
                          ],
                        ),
                        const Divider(height: 28, color: AppColors.parchmentDark),
                        for (final p in report.performances) _MissionRow(performance: p),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Section(
                    title: "Game Master's Note",
                    subtitle: '보호자님께',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final c in report.parentComments)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 3),
                                  child: InkStar(size: AppIconSize.small, color: AppColors.gold),
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(c, style: AppText.bodyText(size: 16))),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'London Mystery는 영어를 "공부"가 아닌 "모험의 도구"로 경험하는 에듀테인먼트 미션 게임입니다.',
                    textAlign: TextAlign.center,
                    style: AppText.caption(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReportHeader extends StatelessWidget {
  const _ReportHeader({required this.report});

  final DetectiveReport report;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.gold, width: 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('LONDON MYSTERY', style: AppText.eyebrow(color: AppColors.goldLight)),
          Text('Episode ${report.episode.numberLabel} Result', style: AppText.title(size: 24, color: Colors.white)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Detective', style: AppText.caption(color: Colors.white60)),
                    Text(report.detectiveName, style: AppText.title(size: 26, color: AppColors.gold)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Mission Completion', style: AppText.caption(color: Colors.white60)),
                  Text('${report.missionsCompleted} / ${report.missionsTotal}',
                      style: AppText.title(size: 26, color: Colors.white)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Wrap(
              spacing: 10,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('${report.xp} XP', style: AppText.button(size: 15, color: AppColors.goldLight)),
                Text('배지 ${report.badges.length}개', style: AppText.button(size: 15, color: Colors.white)),
                Text('단서 ${report.cluesFound}/${report.cluesTotal} · 증거 ${report.evidenceFound}/${report.evidenceTotal}',
                    style: AppText.button(size: 15, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.subtitle, required this.child});

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.parchmentDark, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.title(size: 20)),
          Text(subtitle, style: AppText.caption()),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _SkillRow extends StatelessWidget {
  const _SkillRow({required this.label, required this.labelKo, required this.stars});

  final String label;
  final String labelKo;
  final int stars;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label $stars of 5 stars',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppText.subtitle(color: AppColors.navy)),
                  Text(labelKo, style: AppText.caption()),
                ],
              ),
            ),
            for (var i = 0; i < 5; i++)
              InkStar(
                filled: i < stars,
                color: i < stars ? AppColors.gold : AppColors.parchmentDark,
                size: AppIconSize.large,
              ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.labelKo, required this.value});

  final String label;
  final String labelKo;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: AppText.title(size: 24, color: AppColors.royalBlue)),
          const SizedBox(height: 2),
          Text(label, style: AppText.caption(color: AppColors.charcoal), textAlign: TextAlign.center),
          Text(labelKo, style: AppText.caption(), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _MissionRow extends StatelessWidget {
  const _MissionRow({required this.performance});

  final MissionPerformance performance;

  @override
  Widget build(BuildContext context) {
    final m = performance.mission;
    final typeLabel = switch (m.type) {
      MissionType.multipleChoice => '객관식 읽기',
      MissionType.wordInput => '단어 완성',
      MissionType.numberCode => '숫자 암호',
      MissionType.imageChoice => '그림 추리',
      MissionType.qrScan => 'QR 현장 탐색',
      MissionType.finalCode => '최종 암호',
      MissionType.sequence => '순서 추리',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: performance.firstTry ? AppColors.successSoft : AppColors.royalBlueSoft,
              shape: BoxShape.circle,
            ),
            // Every row is a solved mission; the colour tells first try apart.
            child: InkIcon(
              InkGlyph.check,
              size: AppIconSize.small,
              color: performance.firstTry ? AppColors.success : AppColors.royalBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.location, style: AppText.button(size: 15, color: AppColors.navy)),
                Text(typeLabel, style: AppText.caption()),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                performance.firstTry ? '한 번에 해결' : '${performance.wrongAnswers + 1}번째 도전 성공',
                style: AppText.caption(color: AppColors.charcoal),
              ),
              if (performance.usedHint)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const InkIcon(InkGlyph.hint, size: AppIconSize.tiny, color: AppColors.muted),
                    const SizedBox(width: 2),
                    Text('힌트 ${performance.hints}개 사용', style: AppText.caption()),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
