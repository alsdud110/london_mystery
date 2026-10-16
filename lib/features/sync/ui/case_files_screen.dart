import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../data/models/episode.dart';
import '../../../data/models/game_progress.dart';
import '../../../data/repositories/progress_repository.dart';
import '../../../data/sync/case_conflicts.dart';
import '../../../widgets/game_button.dart';
import '../../../widgets/game_dialog.dart';
import '../../../widgets/game_toast.dart';
import '../../../widgets/ink_icon.dart';
import '../../../widgets/paper.dart';
import '../../account/account_controller.dart';
import '../../account/ui/account_page.dart';
import '../../game/game_controller.dart';
import '../../game/game_providers.dart';
import '../../game/scoring.dart';
import '../case_file_choice.dart';
import '../sync_session.dart';

// Phase 4.5: two case files of one case (it was played on two devices), and
// the detective's choice of the one to keep playing. Child-facing words only:
// two files, keep playing, decide later — the other file is always kept.

/// The session's saves when they are the device's (null in previews).
SharedPrefsProgressRepository? sessionSaves(WidgetRef ref) => switch (ref.read(progressRepositoryProvider)) {
      final SharedPrefsProgressRepository r => r,
      _ => null,
    };

/// The cases of the session's detective that have two case files. Read
/// again when the game or the season changes (a sync merges through them).
Set<String> casesWithTwoFiles(WidgetRef ref) {
  ref.watch(gameControllerProvider);
  ref.watch(seasonProvider);
  final repo = sessionSaves(ref);
  if (repo == null) return const {};
  return {for (final c in CaseConflicts.openChoices(repo, [for (final e in ref.watch(episodeCatalogProvider)) e.id])) c.caseId};
}

/// Opening a case that has two files: told once, with the way to them.
/// Returns true when the detective went to look at them.
Future<bool> offerTwoFilesOnce(BuildContext context, WidgetRef ref, String caseId) async {
  final repo = sessionSaves(ref);
  final choice = repo == null ? null : CaseConflicts.choiceFor(repo, caseId);
  if (repo == null || choice == null || CaseConflicts.noticed(repo, choice)) return false;
  CaseConflicts.markNoticed(repo, choice, DateTime.now());
  final look = await GameDialog.confirm(
    context,
    title: 'Two Case Files',
    message: 'This case was played on two devices. You can choose the file to keep playing.',
    confirmLabel: 'LOOK AT THE FILES',
    cancelLabel: 'Play on for now',
  );
  if (look && context.mounted) context.go(Routes.caseFiles(caseId));
  return look;
}

/// A small tag on a case or a detective that has two case files.
class TwoFilesTag extends StatelessWidget {
  const TwoFilesTag({super.key, this.label = 'TWO CASE FILES'});

  final String label;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const InkIcon(InkGlyph.folder, size: AppIconSize.tiny, color: AppColors.burgundy),
          const SizedBox(width: AppSpace.xs),
          Flexible(child: Text(label, style: AppText.eyebrow(color: AppColors.burgundy))),
        ],
      );
}

/// A coin counted differently on two devices: kept as it is on this device
/// (no balance changes for it), and said so — nothing to choose.
class CoinNoteTag extends StatelessWidget {
  const CoinNoteTag({super.key});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const InkIcon(InkGlyph.coin, size: AppIconSize.tiny, color: AppColors.goldDeep),
          const SizedBox(width: AppSpace.xs),
          Flexible(child: Text('COINS CHECKED · NOTHING LOST', style: AppText.eyebrow(color: AppColors.inkBrown))),
        ],
      );
}

/// The two files of [caseId], side by side on the casebook paper: where each
/// one is, how far it got, its XP and when it was last played. KEEP PLAYING
/// THIS ONE on either; DECIDE LATER leaves both as they are.
class CaseFilesScreen extends ConsumerStatefulWidget {
  const CaseFilesScreen({super.key, required this.caseId});

  final String caseId;

  @override
  ConsumerState<CaseFilesScreen> createState() => _CaseFilesScreenState();
}

class _CaseFilesScreenState extends ConsumerState<CaseFilesScreen> {
  bool _busy = false;
  String? _note;

  void _back() => context.go(Routes.caseFile(widget.caseId));

  Future<void> _keep(SharedPrefsProgressRepository repo, CaseChoice choice, {required bool keepPlaying}) async {
    if (_busy) return;
    final ok = await GameDialog.confirm(
      context,
      title: 'Keep Playing This File?',
      message: "We'll keep the other file safe.",
      confirmLabel: 'YES, KEEP PLAYING',
      cancelLabel: 'Not yet',
    );
    if (!ok || !mounted) return;
    final profileId = ref.read(profileSessionProvider).profileId;
    final uid = ref.read(accountStateProvider).uid;
    final container = ProviderScope.containerOf(context);
    setState(() {
      _busy = true;
      _note = null;
    });
    final result = await ref.read(caseFileChooserProvider).choose(
          repo: repo,
          choice: choice,
          keepPlaying: keepPlaying,
          isStillValid: () =>
              mounted && ref.read(profileSessionProvider).profileId == profileId && ref.read(accountStateProvider).uid == uid,
          applied: (id) => refreshFromSaves(container, 'case:$id'),
        );
    if (!mounted) return;
    switch (result) {
      case ChoiceResult.applied || ChoiceResult.alreadyDone:
        showGameToast(context, 'Playing on with this file.', glyph: InkGlyph.check);
        _back();
      case ChoiceResult.changed:
        setState(() {
          _busy = false;
          _note = 'The case files just changed. Take another look.';
        });
      case ChoiceResult.cannotKeep:
        setState(() {
          _busy = false;
          _note = 'This case already keeps lots of files, so nothing was changed. Ask a grown-up for help.';
        });
      case ChoiceResult.stopped:
        setState(() {
          _busy = false;
          _note = 'The detective changed, so nothing was changed.';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Shown again whenever a sync changes the case.
    ref.watch(gameControllerProvider);
    ref.watch(seasonProvider);
    final episode = ref.watch(episodeCatalogProvider).where((e) => e.id == widget.caseId).firstOrNull;
    final repo = sessionSaves(ref);
    final choice = repo == null || episode == null ? null : CaseConflicts.choiceFor(repo, widget.caseId);
    final eyebrow = episode == null ? 'THE CASEBOOK' : 'CASE ${episode.numberLabel}';
    if (repo == null || episode == null || choice == null) {
      return AccountPage(
        eyebrow: eyebrow,
        title: 'One Case File',
        subtitle: 'This case has one file now. Nothing to choose.',
        onBack: _back,
        content: [if (_note case final n?) AccountNote(n, problem: false)],
        actions: [GameButton(label: 'BACK TO CASE FILES', singleLine: true, style: GameButtonStyle.glass, onPressed: _back)],
      );
    }
    int done(GameProgress p) => episode.allMissions.where((m) => p.isCompleted(m.id)).length;
    final a = done(choice.playing.run);
    final b = done(choice.other.run);
    return AccountPage(
      eyebrow: eyebrow,
      title: 'Two Case Files',
      subtitle: 'This case was played on two devices. Which file do you want to keep playing?',
      onBack: _busy ? null : _back,
      content: [
        _FileCard(
          key: const ValueKey('file-playing'),
          file: choice.playing,
          episode: episode,
          playing: true,
          furtherAlong: a > b,
          onKeep: _busy ? null : () => _keep(repo, choice, keepPlaying: true),
        ),
        const SizedBox(height: AppSpace.md),
        _FileCard(
          key: const ValueKey('file-other'),
          file: choice.other,
          episode: episode,
          playing: false,
          furtherAlong: b > a,
          onKeep: _busy ? null : () => _keep(repo, choice, keepPlaying: false),
        ),
        const SizedBox(height: AppSpace.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const InkIcon(InkGlyph.coin, size: AppIconSize.small, color: AppColors.goldDeep),
            const SizedBox(width: AppSpace.xs),
            Flexible(child: Text('Your coins stay the same.', style: AppText.caption(color: AppColors.inkBrown))),
          ],
        ),
        if (_note case final n?) AccountNote(n),
      ],
      actions: [
        GameButton(
          label: 'DECIDE LATER',
          singleLine: true,
          style: GameButtonStyle.glass,
          onPressed: _busy ? null : _back,
        ),
      ],
    );
  }
}

/// One case file: where it is, how far it got, its XP, when it was last
/// played, and the button to keep playing it.
class _FileCard extends StatelessWidget {
  const _FileCard({
    super.key,
    required this.file,
    required this.episode,
    required this.playing,
    required this.furtherAlong,
    required this.onKeep,
  });

  final CaseFile file;
  final Episode episode;
  final bool playing;
  final bool furtherAlong;
  final VoidCallback? onKeep;

  static String? lastPlayed(GameProgress p, DateTime now) {
    final times = [p.startedAt, p.completedAt, ...p.missionStartedAt.values].whereType<DateTime>();
    if (times.isEmpty) return null;
    final last = times.reduce((a, b) => a.isAfter(b) ? a : b).toLocal();
    final days = DateTime(now.year, now.month, now.day).difference(DateTime(last.year, last.month, last.day)).inDays;
    if (days <= 0) return 'today';
    if (days == 1) return 'yesterday';
    if (days < 7) return '$days days ago';
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${last.day} ${months[last.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final run = file.run;
    final missions = episode.allMissions;
    final solved = missions.where((m) => run.isCompleted(m.id)).length;
    final xp = XpBreakdown.totalFor(episode, run);
    final when = lastPlayed(run, DateTime.now());
    final where = file.side == FileSide.device ? 'ON THIS DEVICE' : 'IN YOUR ACCOUNT';
    return Semantics(
      container: true,
      label: '$where${playing ? ', playing now' : ''}${furtherAlong ? ', further along' : ''}: '
          '$solved of ${missions.length} missions solved, $xp XP${when == null ? '' : ', last played $when'}',
      child: Container(
        padding: const EdgeInsets.all(AppSpace.md),
        decoration: BoxDecoration(
          color: AppColors.paperLight,
          border: Border.all(color: playing ? AppColors.navy.withValues(alpha: 0.45) : AppLine.faint(0.35), width: AppLine.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ExcludeSemantics(
              child: Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(where, style: AppText.eyebrow(color: AppColors.inkBrown)),
                  if (playing) Text('PLAYING NOW', style: AppText.eyebrow(color: AppColors.success)),
                  if (furtherAlong) const InkStamp('FURTHER ALONG', size: 10, tilt: 0),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.sm),
            ExcludeSemantics(
              child: Row(
                children: [
                  for (final m in missions)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpace.xs),
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: run.isCompleted(m.id) ? AppColors.navy : Colors.transparent,
                          border: Border.all(color: AppColors.navy.withValues(alpha: 0.6)),
                        ),
                      ),
                    ),
                  const SizedBox(width: AppSpace.xs),
                  Flexible(child: Text('$solved of ${missions.length} missions', style: AppText.caption(color: AppColors.ink))),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.xs),
            ExcludeSemantics(
              child: Text(
                '$xp XP${when == null ? '' : '  ·  Last played $when'}',
                style: AppText.caption(color: AppColors.inkBrown),
              ),
            ),
            const SizedBox(height: AppSpace.md),
            GameButton(
              label: 'KEEP PLAYING THIS ONE',
              singleLine: true,
              style: playing ? GameButtonStyle.navy : GameButtonStyle.outline,
              onPressed: onKeep,
            ),
          ],
        ),
      ),
    );
  }
}
