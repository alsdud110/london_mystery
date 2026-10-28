import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/formatters.dart';
import '../../data/models/episode.dart';
import '../../data/models/learning.dart';
import '../../data/models/mission.dart';
import '../../widgets/ink_icon.dart';
import '../../widgets/paper.dart';
import '../../widgets/paper_background.dart';
import '../game/game_controller.dart';
import '../game/game_providers.dart';
import 'detective_report.dart';

/// Parent-facing summary, styled as a game report rather than a report card.
///
/// It keeps two things apart: the English the case was *designed* to offer
/// (its learning objectives) and what the save *recorded* about the play.
/// Nothing on it grades the child's English.
class ParentReportScreen extends ConsumerWidget {
  const ParentReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = DetectiveReport.from(ref.watch(currentEpisodeProvider), ref.watch(gameControllerProvider));
    final topic = report.languageTopic;
    final first = report.hasPlayRecord ? '${report.firstTryCount} / ${report.recordedPerformances.length}' : '기록 없음';

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
                    title: 'English in This Case',
                    subtitle: '이번 사건에서 다룬 영어 (학습 설계)',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (topic != null) ...[
                          Text(topic.titleKo, style: AppText.subtitle(color: AppColors.navy)),
                          Text(topic.title, style: AppText.aside(size: 15)),
                          const SizedBox(height: AppSpace.md),
                        ],
                        Text('사건 속 미션이 다루도록 만들어진 영어예요. 아이의 이해도를 시험하거나 측정한 결과가 아니에요.', style: AppText.caption()),
                        const SizedBox(height: AppSpace.sm),
                        for (final p in report.performances)
                          if (p.learning != null) _LearningRow(mission: p.mission, learning: p.learning!),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Section(
                    title: 'Words Checked',
                    subtitle: '스스로 눌러 뜻을 확인한 단어 (기록)',
                    child: _WordsChecked(report: report),
                  ),
                  const SizedBox(height: 16),
                  _Section(
                    title: 'Detective Actions',
                    subtitle: '탐정 행동 기록 (새 기록 — 이번 업데이트 이후 플레이부터)',
                    child: Row(
                      children: [
                        _Metric(
                          label: 'Second Looks',
                          labelKo: '막혔을 때 다시 확인',
                          value: report.actionsRecorded ? '${report.secondLooks}' : '기록 없음',
                        ),
                        _Metric(
                          label: 'Evidence Checked',
                          labelKo: '수첩에서 살펴본 증거',
                          value: report.actionsRecorded ? '${report.evidenceChecked}' : '기록 없음',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _Section(
                    title: 'Play Record',
                    subtitle: '플레이 기록 — 영어 점수가 아니에요',
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _Metric(
                              label: 'Missions',
                              labelKo: '해결한 미션',
                              value: '${report.missionsCompleted} / ${report.missionsTotal}',
                            ),
                            _Metric(
                              label: 'Hints Opened',
                              labelKo: '열어 본 힌트',
                              value: report.hasPlayRecord ? '${report.hintsUsed}' : '기록 없음',
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            _Metric(label: 'First Try', labelKo: '첫 시도에 해결', value: first),
                            _Metric(
                              label: 'Play Time',
                              labelKo: '플레이 시간',
                              value: report.elapsed == null ? '기록 없음' : Formatters.minutes(report.elapsed!),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpace.sm),
                        Text(
                          '"첫 시도에 해결"은 플레이 기록일 뿐이에요. 운 좋게 맞힌 경우와 구분할 수 없어서 영어 이해의 근거가 아니에요.',
                          style: AppText.caption(),
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
                    'World Mystery는 영어를 "공부"가 아닌 "모험의 도구"로 경험하는 에듀테인먼트 미션 게임입니다.\n'
                    '이 보고서는 플레이 기록과 사건의 학습 설계를 보여 줄 뿐, 영어 실력을 평가하지 않습니다.\n'
                    'XP와 배지는 사건 해결과 탐정 행동에 대한 게임 보상이며, 영어 점수가 아닙니다.',
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

/// One solved mission's learning design: the place, what the English does
/// in it, and the English itself.
class _LearningRow extends StatelessWidget {
  const _LearningRow({required this.mission, required this.learning});

  final Mission mission;
  final LearningObjective learning;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpace.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(mission.location, style: AppText.button(size: 15, color: AppColors.navy)),
              Text(learning.dependency.labelKo, style: AppText.caption(color: AppColors.goldDeep)),
            ],
          ),
          const SizedBox(height: 2),
          Text(learning.objective, style: AppText.bodyText(size: 15)),
          for (final e in learning.expressions)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('“$e”', style: AppText.aside(size: 15, color: AppColors.inkBrown)),
            ),
        ],
      ),
    );
  }
}

/// The words the child tapped, with their meanings, or why there are none.
class _WordsChecked extends ConsumerWidget {
  const _WordsChecked({required this.report});

  final DetectiveReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final words = report.wordsLookedUp;
    final Episode episode = report.episode;
    // A word looked up on earlier evidence (the Case Archive) is explained by
    // that case's glossary.
    final catalog = ref.watch(episodeCatalogProvider);
    String? meaningOf(String w) => episode.meaningOf(w) ?? catalog.map((e) => e.meaningOf(w)).nonNulls.firstOrNull;
    if (words.isEmpty) {
      return Text(
        report.lookupsRecorded ? '이번 사건에서는 단어 뜻 보기를 사용하지 않았어요.' : '기록 없음 (단어 기록 이전에 저장된 데이터)',
        style: AppText.bodyText(size: 15, color: AppColors.muted),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final w in words)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: w,
                    style: AppText.button(size: 15, color: AppColors.navy),
                  ),
                  if (meaningOf(w) != null)
                    TextSpan(
                      text: '  ${meaningOf(w)}',
                      style: AppText.bodyText(size: 15, color: AppColors.muted),
                    ),
                ],
              ),
            ),
          ),
        if (!report.lookupsRecorded)
          Padding(
            padding: const EdgeInsets.only(top: AppSpace.xs),
            child: Text('그 이전에 찾아본 단어는 기록이 없어요.', style: AppText.caption()),
          ),
      ],
    );
  }
}

class _ReportHeader extends StatelessWidget {
  const _ReportHeader({required this.report});

  final DetectiveReport report;

  @override
  Widget build(BuildContext context) {
    // The report folder's leather cover, gold-tooled at the edge.
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navy, AppColors.navyDeep],
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: AppShadow.paperLift,
      ),
      foregroundDecoration: const RuledFrame(color: AppColors.goldLight, inset: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('WORLD MYSTERY', style: AppText.eyebrow(color: AppColors.goldLight)),
          Text(
            'Episode ${report.episode.numberLabel} Result',
            style: AppText.title(size: 24, color: AppColors.paperLight),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Detective', style: AppText.caption(color: AppColors.paperLight.withValues(alpha: 0.62))),
                    // A name is one word: shrunk to fit, never cut ("MINYO…").
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        report.detectiveName,
                        maxLines: 1,
                        style: AppText.title(size: 26, color: AppColors.goldLight),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Mission Completion',
                    style: AppText.caption(color: AppColors.paperLight.withValues(alpha: 0.62)),
                  ),
                  Text(
                    '${report.missionsCompleted} / ${report.missionsTotal}',
                    style: AppText.title(size: 26, color: AppColors.paperLight),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.goldLight.withValues(alpha: 0.35), width: AppLine.hairline),
              ),
            ),
            child: Wrap(
              spacing: 10,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('${report.xp} XP', style: AppText.button(size: 15, color: AppColors.goldLight)),
                Text('배지 ${report.badges.length}개', style: AppText.button(size: 15, color: AppColors.paperLight)),
                Text(
                  '단서 ${report.cluesFound}/${report.cluesTotal} · 증거 ${report.evidenceFound}/${report.evidenceTotal}',
                  style: AppText.button(size: 15, color: AppColors.paperLight),
                ),
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
    // One page of the report.
    return PaperSheet(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppText.title(size: 20)),
          Text(subtitle, style: AppText.caption()),
          const SizedBox(height: AppSpace.sm),
          Divider(height: AppSpace.lg, color: AppLine.faint()),
          child,
        ],
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
          // Three to a row on a narrow phone: the figure fits its column.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, maxLines: 1, style: AppText.title(size: 24, color: AppColors.navy)),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppText.caption(color: AppColors.charcoal),
            textAlign: TextAlign.center,
          ),
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
    final p = performance;
    final m = p.mission;
    final typeLabel = switch (m.type) {
      MissionType.multipleChoice => '객관식',
      MissionType.wordInput => '단어 입력',
      MissionType.numberCode => '숫자 암호',
      MissionType.imageChoice => '그림 선택',
      MissionType.examine => '현장 조사',
      MissionType.finalCode => '최종 암호',
      MissionType.sequence => '순서 맞추기',
      MissionType.letterLock => '글자 자물쇠',
      MissionType.spotDifferences => '그림 비교',
      MissionType.matchPairs => '메모와 그림 연결',
      MissionType.revealLayer => '숨은 밑그림 조사',
      MissionType.canvasChoice => '단서로 캔버스 고르기',
    };
    final role = p.learning?.dependency.labelKo;
    final String record;
    if (!p.recorded) {
      record = '기록 없음';
    } else if (p.firstTry) {
      record = '첫 시도에 해결';
    } else {
      record = '${p.wrongAnswers + 1}번째 시도에 해결';
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: p.firstTry ? AppColors.successSoft : AppColors.royalBlueSoft,
              shape: BoxShape.circle,
            ),
            // Every row is a solved mission; the colour tells first try apart.
            child: InkIcon(
              InkGlyph.check,
              size: AppIconSize.small,
              color: p.firstTry ? AppColors.success : AppColors.royalBlue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m.location, style: AppText.button(size: 15, color: AppColors.navy)),
                Text(role == null ? typeLabel : '$typeLabel · $role', style: AppText.caption()),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(record, style: AppText.caption(color: AppColors.charcoal)),
              if (p.recorded && p.usedHint)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const InkIcon(InkGlyph.hint, size: AppIconSize.tiny, color: AppColors.muted),
                    const SizedBox(width: 2),
                    Text('힌트 ${p.hints}개 열어 봄', style: AppText.caption()),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
