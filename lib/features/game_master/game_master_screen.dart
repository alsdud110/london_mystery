import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/models/difficulty.dart';
import '../../data/models/episode.dart';
import '../../data/models/season.dart' show Season, SeasonIds;
import '../game/game_controller.dart';
import '../game/game_providers.dart';
import '../onboarding/detective_form.dart';
import '../../widgets/game_dialog.dart';
import '../../widgets/game_toast.dart';
import '../../widgets/ink_icon.dart';
import '../../widgets/paper_background.dart';
import 'dev_session.dart';
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

  void _changeLevel(BuildContext context, WidgetRef ref, Difficulty level) {
    if (level == ref.read(detectiveProfileProvider).difficulty) return;
    final episode = ref.read(currentEpisodeProvider);
    final restarted = changeTestLevel(ref, level);
    showGameToast(
      context,
      restarted ? 'CASE ${episode.numberLabel} restarts as ${level.label}.' : 'Test level: ${level.label}.',
      glyph: InkGlyph.check,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final episode = ref.watch(currentEpisodeProvider);
    // The cases a playtest can start at: the first season's (see startPlaytestAt).
    final catalog = SeasonAvailability.casesOf(ref.watch(seasonsProvider).first.id, ref.watch(allEpisodesProvider));
    final operatorOn = ref.watch(operatorAccessProvider);
    final previewOn = ref.watch(seasonPreviewProvider);
    final dev = ref.watch(devSessionProvider);
    final testing = dev?.active ?? false;
    // The test tools run in a test session — never on the player's own
    // saves. (A game without developer mode, a test of the tools, has them
    // where it is.)
    final tools = playtestToolsEnabled && (testing || dev == null);

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
              if (testing) ...[
                _DeveloperModeHeader(onExit: dev!.exit),
                const SizedBox(height: 16),
                Text('TEST LEVEL', style: AppText.eyebrow()),
                const SizedBox(height: 8),
                DifficultyChoice(
                  selected: ref.watch(detectiveProfileProvider.select((p) => p.difficulty)),
                  onChanged: (d) => _changeLevel(context, ref, d),
                ),
                const SizedBox(height: 24),
                const Divider(),
              ],
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
              // The player's own game: the tools are reached through a test
              // session of their own.
              if (playtestToolsEnabled && dev != null && !testing) ...[
                const SizedBox(height: 24),
                const Divider(),
                Text('개발자 모드 (DEVELOPER MODE)', style: AppText.title(size: 20)),
                Text(
                  '테스트 빌드에서만 보입니다. TESTER(BOY) 탐정으로 새 테스트 세션을 시작합니다. '
                  '사건 바로가기·CASE NN부터·OPERATOR MODE 등 테스트 도구는 그 안에서 쓰며, '
                  '테스트 기록은 메모리에만 있고 이 기기의 진행 기록은 바뀌지 않습니다. '
                  '나가면 테스트 기록은 모두 사라지고 다시 들어오면 처음부터 시작합니다.',
                  style: AppText.caption(),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  key: const ValueKey('enter-developer-mode'),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), backgroundColor: AppColors.navy),
                  onPressed: dev.enter,
                  child: const Text('START DEVELOPER MODE'),
                ),
              ],
              if (tools) ...[
                const SizedBox(height: 24),
                const Divider(),
                const CaseShortcuts(),
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
                // An unreleased season, played before its release (session only).
                SwitchListTile(
                  key: const ValueKey('season-preview-switch'),
                  contentPadding: EdgeInsets.zero,
                  title: Text('출시 전 시즌 플레이 (SEASON PREVIEW)', style: AppText.subtitle()),
                  subtitle: Text(
                    '테스트 빌드에서만 켤 수 있습니다. 출시 전 시즌(SEASON 2)이 보관함에서 열리고, '
                    '푼 기록은 그 시즌에 따로 저장됩니다. 끄거나 앱을 다시 시작하면 SEASON 1로 돌아갑니다.',
                    style: AppText.caption(),
                  ),
                  value: previewOn,
                  onChanged: (on) {
                    // Off: back to Season 1 first, while the season played can still be left.
                    if (!on && ref.read(selectedSeasonIdProvider) != SeasonIds.london) {
                      ref.read(gameControllerProvider.notifier).openSeason(SeasonIds.london);
                    }
                    ref.read(seasonPreviewSwitchProvider.notifier).set(on);
                  },
                ),
                if (previewOn)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    onPressed: () => context.go(Routes.seasons),
                    child: const Text('DETECTIVE ARCHIVES로 이동'),
                  ),
                const SizedBox(height: 12),
                // Season 2's opening, to check it before the season opens: it
                // changes nothing and opens no case (not in a release build).
                OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  onPressed: () => context.go(Routes.parisPrologue),
                  child: const Text('SEASON 2 프롤로그 미리보기'),
                ),
              ],
              // The one destructive action, set apart from the test tools below a
              // rule and in the try-again ink, so it is never tapped by mistake.
              // The player's own game only: a test session has nothing to reset
              // for a next player (it is thrown away on leaving).
              if (!testing) ...[
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
            ],
          ),
        ),
      ),
    );
  }
}

/// The case shortcuts: a season, then any of its cases, opened at its case
/// file without changing a save (see [jumpToCase]). Every season of the
/// game is listed, released or not; a planned case not in the game yet is
/// shown, shut, as COMING SOON. Operator builds only (as every test tool).
class CaseShortcuts extends ConsumerStatefulWidget {
  const CaseShortcuts({super.key});

  @override
  ConsumerState<CaseShortcuts> createState() => _CaseShortcutsState();
}

class _CaseShortcutsState extends ConsumerState<CaseShortcuts> {
  /// The season picked; null: the one being played.
  String? _seasonId;

  void _open(String seasonId, Episode e) {
    final refused = jumpToCase(ref, seasonId, e.id);
    if (refused == null) {
      context.go(Routes.caseFile(e.id));
      return;
    }
    GameDialog.confirmPlain(
      context,
      title: 'CASE ${e.numberLabel}을 열 수 없습니다',
      message: switch (refused) {
        CaseJumpRefusal.noDetective => '이 기기에 탐정이 아직 없습니다. 탐정을 먼저 만든 뒤 다시 시도해 주세요.',
        CaseJumpRefusal.noOperatorTools => '테스트 빌드에서만 사용할 수 있습니다.',
        CaseJumpRefusal.notOpen => '이 사건은 아직 게임에 없습니다.',
        CaseJumpRefusal.playerSaves => '사건 바로가기는 개발자 모드(테스트 세션) 안에서만 쓸 수 있습니다.',
      },
      confirmLabel: '확인',
      cancelLabel: '닫기',
    );
  }

  @override
  Widget build(BuildContext context) {
    // Never in a build without operator tools (a release build).
    if (!ref.watch(operatorToolsAvailableProvider)) return const SizedBox.shrink();
    final seasons = ref.watch(seasonsProvider);
    final all = ref.watch(allEpisodesProvider);
    final picked = seasons.firstWhere(
      (s) => s.id == (_seasonId ?? ref.watch(selectedSeasonIdProvider)),
      orElse: () => seasons.first,
    );
    final cases = SeasonAvailability.casesOf(picked.id, all);
    final planned = math.max(cases.length, picked.plannedCases ?? 0);

    return Column(
      key: const ValueKey('case-shortcuts'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('사건 바로가기', style: AppText.title(size: 20)),
        Text(
          '시즌과 사건을 고르면 그 사건 파일로 바로 이동합니다. 진행 기록은 지우거나 바꾸지 않으며, '
          '이전 사건을 풀지 않아도 열립니다. 이번 실행 동안만 OPERATOR MODE와 SEASON PREVIEW가 켜집니다.',
          style: AppText.caption(),
        ),
        const SizedBox(height: 12),
        Text('SELECT SEASON', style: AppText.eyebrow()),
        const SizedBox(height: 8),
        Row(
          children: [
            for (final (i, s) in seasons.indexed) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _SeasonChoice(
                  key: ValueKey('shortcut-season-${s.id}'),
                  season: s,
                  cases: SeasonAvailability.casesOf(s.id, all).length,
                  selected: s.id == picked.id,
                  onTap: () => setState(() => _seasonId = s.id),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        Text('${picked.city.toUpperCase()} — CASE SELECT', style: AppText.eyebrow()),
        const SizedBox(height: 8),
        for (var n = 1; n <= planned; n++)
          if (n <= cases.length)
            _CaseRow(
              key: ValueKey('shortcut-case-${cases[n - 1].id}'),
              number: cases[n - 1].numberLabel,
              title: cases[n - 1].title,
              onTap: () => _open(picked.id, cases[n - 1]),
            )
          else
            _CaseRow(
              key: ValueKey('shortcut-planned-${picked.id}-$n'),
              number: n.toString().padLeft(2, '0'),
              title: picked.upcomingTitles[n] ?? '',
              comingSoon: true,
            ),
      ],
    );
  }
}

/// The top of the Game Master's page in a test session: who is playing
/// (TESTER, nothing kept on the device) and the way out.
class _DeveloperModeHeader extends StatelessWidget {
  const _DeveloperModeHeader({required this.onExit});

  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('developer-mode-header'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('DEVELOPER MODE', style: AppText.title(size: 22, color: AppColors.burgundy)),
        Text('TESTER · BOY', style: AppText.eyebrow()),
        const SizedBox(height: 4),
        Text(
          '테스트 세션입니다. 여기서 한 진행·코인·힌트·난이도는 메모리에만 있고 이 기기의 진행 기록에는 쓰이지 않습니다. '
          '나가면 모두 사라지고, 다시 들어오면 처음부터 시작합니다.',
          style: AppText.caption(),
        ),
        const SizedBox(height: 12),
        OutlinedButton(
          key: const ValueKey('exit-developer-mode'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            foregroundColor: AppColors.burgundy,
            side: const BorderSide(color: AppColors.burgundy, width: 1.5),
          ),
          onPressed: onExit,
          child: const Text('EXIT DEVELOPER MODE'),
        ),
      ],
    );
  }
}

class _SeasonChoice extends StatelessWidget {
  const _SeasonChoice({super.key, required this.season, required this.cases, required this.selected, required this.onTap});

  final Season season;
  final int cases;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ink = selected ? AppColors.paperLight : AppColors.navy;
    return Semantics(
      button: true,
      selected: selected,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(64),
          backgroundColor: selected ? AppColors.navy : null,
          side: const BorderSide(color: AppColors.navy, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        ),
        onPressed: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(season.city.toUpperCase(), style: AppText.button(size: 16, color: ink)),
            const SizedBox(height: 2),
            Text(
              'Season ${season.number} · $cases Cases',
              textAlign: TextAlign.center,
              style: AppText.caption(color: ink.withValues(alpha: 0.8)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaseRow extends StatelessWidget {
  const _CaseRow({super.key, required this.number, required this.title, this.onTap, this.comingSoon = false});

  final String number;
  final String title;
  final VoidCallback? onTap;
  final bool comingSoon;

  @override
  Widget build(BuildContext context) {
    final ink = comingSoon ? AppColors.muted : AppColors.navy;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          alignment: Alignment.centerLeft,
          side: BorderSide(color: ink.withValues(alpha: comingSoon ? 0.4 : 1)),
        ),
        // A case not in the game yet: shown, never opened.
        onPressed: comingSoon ? null : onTap,
        child: Row(
          children: [
            Text('CASE $number', style: AppText.button(size: 14, color: ink)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                comingSoon ? (title.isEmpty ? 'Coming Soon' : '$title — Coming Soon') : title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.bodyText(size: 15, color: ink),
              ),
            ),
            if (!comingSoon) const InkIcon(InkGlyph.arrow, size: AppIconSize.small, color: AppColors.navy),
          ],
        ),
      ),
    );
  }
}
