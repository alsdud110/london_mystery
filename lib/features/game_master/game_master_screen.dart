import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../data/models/mission.dart';
import '../game/game_controller.dart';
import '../game/game_providers.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episode = ref.watch(currentEpisodeProvider);
    final qrMissions = episode.allMissions.where((m) => m.type == MissionType.qrScan).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('GAME MASTER')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text('현장 운영 도구', style: AppText.title(size: 22)),
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
                  trailing: Text(
                    m.options.isEmpty ? m.answer : m.options.firstWhere((o) => o.id == m.answer).label,
                    style: AppText.button(size: 14, color: AppColors.royalBlue),
                  ),
                ),
            ],
          ),
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
