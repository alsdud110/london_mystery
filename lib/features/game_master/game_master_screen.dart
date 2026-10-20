import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../data/models/episode.dart';
import '../game/game_providers.dart';
import '../../widgets/game_dialog.dart';
import '../../widgets/ink_icon.dart';
import '../../widgets/paper_background.dart';
import 'playtest_tools.dart';

/// Operator tools for the play space: the answer key for helpers, the
/// playtest tools, and a reset for the next child.
class GameMasterScreen extends ConsumerWidget {
  const GameMasterScreen({super.key});

  Future<void> _reset(BuildContext context, WidgetRef ref) async {
    final ok = await GameDialog.confirmPlain(
      context,
      title: '다음 플레이어를 위해 초기화할까요?',
      message: '탐정 이름·아바타와 진행 기록(사건·코인·힌트)이 모두 삭제되고, '
          '다음 플레이어는 탐정 만들기와 How to Play부터 시작합니다.\n'
          '이 기기에 보관 중인 이전 버전 저장 원본도 함께 삭제됩니다.',
      confirmLabel: '초기화',
      cancelLabel: '취소',
      destructive: true,
    );
    if (!ok) return;
    var complete = await resetForNextPlayer(ref);
    // Something could not be removed: say so, and offer to finish it (the
    // reset is safe to repeat; the old progress cannot come back meanwhile).
    while (!complete) {
      if (!context.mounted) return;
      final retry = await GameDialog.confirmPlain(
        context,
        title: '일부 기록을 지우지 못했습니다',
        message: '이전 버전 저장 원본 중 일부가 남아 있습니다. 다시 시도할까요?',
        confirmLabel: '다시 시도',
        cancelLabel: '닫기',
      );
      if (!retry) break;
      complete = await ref.read(profileStoreProvider).wipeLegacy();
    }
    if (context.mounted) context.go(Routes.start);
  }

  Future<bool> _confirm(BuildContext context, String title, String body, String action) async {
    return GameDialog.confirmPlain(context, title: title, message: body, confirmLabel: action, cancelLabel: '취소');
  }

  Future<void> _startAt(BuildContext context, WidgetRef ref, Episode e) async {
    final ok = await _confirm(
      context,
      'CASE ${e.numberLabel}부터 테스트할까요?',
      '이 기기의 진행 기록이 모두 지워지고, CASE ${e.numberLabel} 이전 사건은 해결한 것으로 표시됩니다. '
          '(힌트·배지 기록 없음, Case Archive에는 증거가 보입니다.)',
      '시작',
    );
    if (!ok || !context.mounted) return;
    await startPlaytestAt(ref, e.id);
    if (context.mounted) context.go(Routes.caseFile(e.id));
  }

  Future<void> _restartCase(BuildContext context, WidgetRef ref, Episode e) async {
    final ok = await _confirm(
      context,
      'CASE ${e.numberLabel}을 처음부터 다시 할까요?',
      '이 사건의 단서·XP·배지·힌트 기록만 지워집니다. 탐정 이름과 다른 사건은 그대로입니다.',
      '다시 시작',
    );
    if (!ok || !context.mounted) return;
    restartCurrentCase(ref);
    context.go(Routes.caseFile(e.id));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episode = ref.watch(currentEpisodeProvider);
    // The cases a playtest can start at: the first season's (see startPlaytestAt).
    final catalog = SeasonAvailability.casesOf(ref.watch(seasonsProvider).first.id, ref.watch(allEpisodesProvider));
    final operatorOn = ref.watch(operatorAccessProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('GAME MASTER', style: AppText.eyebrow(color: AppColors.ink)),
        leading: IconButton(
          tooltip: 'Back',
          icon: const InkIcon(InkGlyph.back),
          onPressed: () => context.canPop() ? context.pop() : context.go(Routes.start),
        ),
      ),
      // The operator's page of the casebook: the same paper as the game.
      body: PaperBackground(
        // Its own (see-through) Material over the paper, so the list tiles'
        // touch marks draw on top of the paper instead of under it.
        child: Material(
          type: MaterialType.transparency,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              Text('현장 운영 도구', style: AppText.title(size: 22)),
              Text('CASE ${episode.numberLabel} · ${episode.title}', style: AppText.eyebrow()),
              const SizedBox(height: 4),
              // Every mission is played on this device alone: nothing to print
              // or place on site.
              Text('모든 미션은 이 기기 하나로 진행됩니다. 현장에 따로 준비할 카드는 없습니다.', style: AppText.caption()),
              const SizedBox(height: 16),
              ExpansionTile(
                // Folded and unfolded alike: no Material rules around it.
                shape: const Border(),
                collapsedShape: const Border(),
                iconColor: AppColors.ink,
                collapsedIconColor: AppColors.ink,
                title: Text('정답표 (도우미용)', style: AppText.subtitle()),
                children: [
                  for (final m in episode.allMissions)
                    ListTile(
                      dense: true,
                      title: Text('${m.numberLabel}. ${m.location}'),
                      // The answer under the question, not as a trailing widget:
                      // a sequence answer (A → B → C → D) is longer than a tile.
                      subtitle: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(text: '${m.question}\n'),
                            TextSpan(
                              text: '정답: ${m.answerLabel}',
                              style: AppText.button(size: 14, color: AppColors.royalBlue),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              if (playtestToolsEnabled) ...[
                const SizedBox(height: 24),
                const Divider(),
                Text('플레이 테스트 도구', style: AppText.title(size: 20)),
                Text('테스트 빌드에서만 보입니다. 원하는 사건을 처음부터 플레이할 수 있게 기기를 준비합니다.', style: AppText.caption()),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final e in catalog)
                      OutlinedButton(
                        onPressed: () => _startAt(context, ref, e),
                        child: Text('CASE ${e.numberLabel}부터'),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  onPressed: () => _restartCase(context, ref, episode),
                  child: Text('지금 사건(CASE ${episode.numberLabel}) 처음부터'),
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('전체 사건 열기 (OPERATOR MODE)', style: AppText.subtitle()),
                  subtitle: Text(
                    'Operator Mode lets you open cases for testing. '
                    'If you solve missions, your progress and rewards will be saved.',
                    style: AppText.caption(),
                  ),
                  value: operatorOn,
                  onChanged: (on) => ref.read(operatorAccessSwitchProvider.notifier).set(on),
                ),
                if (operatorOn)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    onPressed: () => context.go(Routes.episodes),
                    child: const Text('CASE FILES로 이동'),
                  ),
                const SizedBox(height: 12),
                // Season 2's opening, to check it before the season opens: it
                // changes nothing and opens no case (not in a release build).
                OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  onPressed: () => context.go(Routes.parisPrologue),
                  child: const Text('SEASON 2 프롤로그 미리보기'),
                ),
                const SizedBox(height: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  onPressed: () => context.go(Routes.parisCase01Preview),
                  child: const Text('PARIS CASE 01 플레이 미리보기'),
                ),
              ],
              // The one destructive action, set apart from the test tools below a
              // rule and in the try-again ink, so it is never tapped by mistake.
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 8),
              // Custom Asset Required: a reset glyph.
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  foregroundColor: AppColors.tryAgain,
                  side: const BorderSide(color: AppColors.tryAgain, width: 1.5),
                ),
                onPressed: () => _reset(context, ref),
                child: const Text('다음 플레이어를 위해 기기 초기화'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
