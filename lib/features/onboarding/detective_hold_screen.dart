import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/repositories/profile_store.dart';
import '../../widgets/game_button.dart';
import '../../widgets/game_dialog.dart';
import '../../widgets/paper.dart';
import '../../widgets/paper_background.dart';
import '../game/game_providers.dart';
import '../game_master/dev_session.dart';
import '../game_master/parent_gate.dart';

/// Starts the game with the device's detective ([ProfileSession]), or — when
/// several detectives with progress were found and nothing says which is
/// this device's ([ProfileHold]) — first asks a grown-up to choose one.
class DeviceDetectiveGate extends StatefulWidget {
  const DeviceDetectiveGate({
    super.key,
    required this.start,
    required this.store,
    required this.overrides,
    required this.child,
  });

  final DeviceStart start;
  final ProfileStore store;

  /// Given to the game's provider scope (shared preferences, content).
  final List<Override> overrides;
  final Widget child;

  @override
  State<DeviceDetectiveGate> createState() => _DeviceDetectiveGateState();
}

class _DeviceDetectiveGateState extends State<DeviceDetectiveGate> {
  late DeviceStart _start = widget.start;

  Future<void> _choose(ProfileHold hold, String id) async {
    final session = await widget.store.resolveHold(hold, id);
    if (mounted) setState(() => _start = session);
  }

  @override
  Widget build(BuildContext context) => switch (_start) {
        // The player's game, and developer mode's test sessions in its place
        // while it is on (see DevSessionHost).
        final ProfileSession session => DevSessionHost(
            overrides: [...widget.overrides, profileSessionProvider.overrideWithValue(session)],
            child: widget.child,
          ),
        final ProfileHold hold => MaterialApp(
            title: 'London Mystery',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            home: DetectiveHoldScreen(hold: hold, onChoose: (id) => _choose(hold, id)),
          ),
      };
}

/// For a grown-up: more than one detective's progress is on this device.
/// Nothing was removed; the one chosen plays on, the others stay stored.
class DetectiveHoldScreen extends StatelessWidget {
  const DetectiveHoldScreen({super.key, required this.hold, required this.onChoose});

  final ProfileHold hold;
  final Future<void> Function(String id) onChoose;

  Future<void> _pick(BuildContext context, HeldDetective d) async {
    if (!await ParentGate.show(context) || !context.mounted) return;
    final ok = await GameDialog.confirmPlain(
      context,
      title: '${_name(d)} 탐정으로 계속할까요?',
      message: '이 기기에서는 이 탐정의 기록으로 게임을 이어 합니다.\n'
          '다른 탐정의 기록은 지워지지 않고 이 기기에 그대로 보관됩니다.',
      confirmLabel: '계속',
      cancelLabel: '취소',
    );
    if (ok) await onChoose(d.id);
  }

  static String _name(HeldDetective d) => d.name ?? '이름 없는';

  static String _date(DateTime t) =>
      '${t.year}.${t.month.toString().padLeft(2, '0')}.${t.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PaperBackground(
        night: true,
        child: InkSurface(
          night: true,
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpace.screen),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: PaperSheet(
                    padding: const EdgeInsets.all(AppSpace.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('보호자 확인이 필요합니다',
                            textAlign: TextAlign.center, style: AppText.mark(color: AppColors.burgundy)),
                        const SizedBox(height: AppSpace.sm),
                        Text('이 기기에서 계속할\n탐정을 골라 주세요', textAlign: TextAlign.center, style: AppText.title(size: 22)),
                        const SizedBox(height: AppSpace.md),
                        const Center(child: OrnamentRule()),
                        const SizedBox(height: AppSpace.md),
                        Text(
                          '진행 기록이 있는 탐정이 둘 이상 발견되었습니다. '
                          '어떤 기록도 지우지 않았습니다. '
                          '고르지 않은 탐정의 기록은 이 기기에 그대로 보관됩니다.',
                          style: AppText.bodyText(size: 16, color: AppColors.muted),
                        ),
                        const SizedBox(height: AppSpace.lg),
                        for (final d in hold.candidates) ...[
                          _Candidate(
                            detective: d,
                            details: [
                              '해결한 사건 ${d.solvedCases}개',
                              if (d.lastPlayed != null) '마지막 플레이 ${_date(d.lastPlayed!)}',
                            ].join(' · '),
                            onPressed: () => _pick(context, d),
                          ),
                          const SizedBox(height: AppSpace.md),
                        ],
                      ],
                    ),
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

class _Candidate extends StatelessWidget {
  const _Candidate({required this.detective, required this.details, required this.onPressed});

  final HeldDetective detective;
  final String details;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: AppLine.faint(0.35), width: AppLine.hairline),
        borderRadius: BorderRadius.circular(AppRadius.paper),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              detective.name == null ? '이름 없는 탐정' : 'Detective ${detective.name}',
              style: AppText.title(size: 20),
            ),
            const SizedBox(height: AppSpace.xs),
            Text(details, style: AppText.caption()),
            const SizedBox(height: AppSpace.md),
            GameButton(
              label: '이 탐정으로 계속',
              style: GameButtonStyle.outline,
              onPressed: onPressed,
            ),
          ],
        ),
      ),
    );
  }
}
