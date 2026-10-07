import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../data/models/episode.dart';
import '../../data/models/mission.dart';
import '../game/game_controller.dart';
import '../game/game_providers.dart';
import '../../widgets/game_dialog.dart';
import '../../widgets/ink_icon.dart';
import '../../widgets/paper.dart';
import '../../widgets/paper_background.dart';
import 'playtest_tools.dart';

/// Operator tools for the play space: the QR cards to place on site, the
/// answer key for helpers, and a reset for the next child.
class GameMasterScreen extends ConsumerWidget {
  const GameMasterScreen({super.key});

  Future<void> _reset(BuildContext context, WidgetRef ref) async {
    final ok = await GameDialog.confirmPlain(
      context,
      title: '다음 플레이어를 위해 초기화할까요?',
      message: '탐정 이름과 진행 기록이 모두 삭제됩니다.',
      confirmLabel: '초기화',
      cancelLabel: '취소',
      destructive: true,
    );
    if (ok) {
      await ref.read(gameControllerProvider.notifier).resetAll();
      if (context.mounted) context.go(Routes.start);
    }
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
    final catalog = ref.watch(episodeCatalogProvider);
    final operatorOn = ref.watch(operatorAccessProvider);
    final qrMissions = episode.allMissions.where((m) => m.type == MissionType.qrScan).toList();

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
              Text('아래 QR 카드를 인쇄하거나 이 화면을 띄워 미션 장소에 비치하세요.', style: AppText.caption()),
              const SizedBox(height: 16),
              for (final m in qrMissions)
                // A ruled card of the casebook; the code itself stays on white
                // so a camera reads it.
                PaperSheet(
                  ruled: true,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        'MISSION ${m.numberLabel} · ${m.location}',
                        style: AppText.eyebrow(),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      QrImageView(data: m.answer, size: 220, backgroundColor: Colors.white),
                      const SizedBox(height: 8),
                      SelectableText(m.answer, style: AppText.title(size: 20).copyWith(letterSpacing: 2)),
                      Text('(QR 아래 수동 입력 코드)', style: AppText.caption()),
                    ],
                  ),
                ),
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
                    'CASE 01~${catalog.last.numberLabel}을 순서와 상관없이 열 수 있습니다. 해결 기록·XP·배지·증거는 '
                    '바뀌지 않습니다(위의 "CASE NN부터"와 달리 이전 사건을 해결로 표시하지 않음). 앱을 다시 시작하면 꺼집니다.',
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
