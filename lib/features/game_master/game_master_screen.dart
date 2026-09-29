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
import 'playtest_tools.dart';

/// Operator tools for the play space: the QR cards to place on site, the
/// answer key for helpers, and a reset for the next child.
class GameMasterScreen extends ConsumerWidget {
  const GameMasterScreen({super.key});

  Future<void> _reset(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('다음 플레이어를 위해 초기화할까요?'),
        content: const Text('탐정 이름과 진행 기록이 모두 삭제됩니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('초기화')),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(gameControllerProvider.notifier).resetAll();
      if (context.mounted) context.go(Routes.start);
    }
  }

  Future<bool> _confirm(BuildContext context, String title, String body, String action) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(action)),
        ],
      ),
    );
    return ok == true;
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
    final qrMissions = episode.allMissions.where((m) => m.type == MissionType.qrScan).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('GAME MASTER')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text('현장 운영 도구', style: AppText.title(size: 22)),
          Text('CASE ${episode.numberLabel} · ${episode.title}', style: AppText.eyebrow()),
          const SizedBox(height: 4),
          Text('아래 QR 카드를 인쇄하거나 이 화면을 띄워 미션 장소에 비치하세요.', style: AppText.caption()),
          const SizedBox(height: 16),
          for (final m in qrMissions)
            Card(
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text('MISSION ${m.numberLabel} · ${m.location}', style: AppText.eyebrow()),
                    const SizedBox(height: 12),
                    QrImageView(data: m.answer, size: 220, backgroundColor: Colors.white),
                    const SizedBox(height: 8),
                    SelectableText(m.answer, style: AppText.title(size: 20).copyWith(letterSpacing: 2)),
                    Text('(QR 아래 수동 입력 코드)', style: AppText.caption()),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          ExpansionTile(
            title: Text('정답표 (도우미용)', style: AppText.subtitle()),
            children: [
              for (final m in episode.allMissions)
                ListTile(
                  dense: true,
                  title: Text('${m.numberLabel}. ${m.location}'),
                  subtitle: Text(m.question),
                  trailing: Text(m.answerLabel, style: AppText.button(size: 14, color: AppColors.royalBlue)),
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
                  OutlinedButton(onPressed: () => _startAt(context, ref, e), child: Text('CASE ${e.numberLabel}부터')),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              onPressed: () => _restartCase(context, ref, episode),
              child: Text('지금 사건(CASE ${episode.numberLabel}) 처음부터'),
            ),
          ],
          const SizedBox(height: 24),
          // Custom Asset Required: a reset glyph.
          OutlinedButton(
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            onPressed: () => _reset(context, ref),
            child: const Text('다음 플레이어를 위해 기기 초기화'),
          ),
        ],
      ),
    );
  }
}
