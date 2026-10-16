import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/audio_service.dart';
import '../../../data/models/detective_name.dart';
import '../../../data/models/profile.dart';
import '../../../data/repositories/progress_repository.dart';
import '../../../data/sync/case_conflicts.dart';
import '../../../widgets/game_button.dart';
import '../../../widgets/ink_icon.dart';
import '../../game/game_controller.dart';
import '../../game/game_providers.dart';
import '../../profile/profile_session.dart';
import '../../sync/profile_restore.dart';
import '../../sync/ui/case_files_screen.dart';
import '../account_controller.dart';
import 'account_page.dart';

/// Who's on the case? The guest of this device and the signed-in account's
/// detectives — never another account's. Choosing one plays it (its own
/// saves); nothing moves between them.
///
/// In a build that syncs, the account's detectives kept in the cloud and not
/// on this device yet are listed too: choosing one restores it (all its
/// records, checked first), then plays it. The guest is never moved.
class ProfileSelectScreen extends ConsumerStatefulWidget {
  const ProfileSelectScreen({super.key});

  @override
  ConsumerState<ProfileSelectScreen> createState() => _ProfileSelectScreenState();
}

class _ProfileSelectScreenState extends ConsumerState<ProfileSelectScreen> {
  String? _problem;

  /// The account's detectives in the cloud, once read (for [_cloudUid]).
  List<AccountDetective>? _cloud;
  String? _cloudUid;
  bool _listing = false;
  RestoreProblem? _cloudProblem;

  /// The detective being restored now.
  String? _restoring;

  Future<void> _list(ProfileRestore restore, String uid) async {
    setState(() {
      _listing = true;
      _cloudUid = uid;
      _cloudProblem = null;
    });
    final r = await restore.accountDetectives();
    if (!mounted || _cloudUid != uid) return;
    setState(() {
      _listing = false;
      _cloud = r.detectives;
      _cloudProblem = r.problem;
    });
  }

  Future<void> _restore(ProfileRestore restore, AccountDetective d) async {
    if (_restoring != null) return;
    setState(() {
      _restoring = d.id;
      _problem = null;
      _cloudProblem = null;
    });
    final problem = await restore.restore(d);
    if (!mounted) return;
    if (problem != null) {
      setState(() {
        _restoring = null;
        _cloudProblem = problem;
      });
      return;
    }
    try {
      // Restored: it plays now, in a session of its own.
      await ProfileSessionHost.of(context).switchTo(d.id);
    } on StateError {
      if (mounted) {
        setState(() {
          _restoring = null;
          _problem = 'This detective belongs to another account.';
        });
      }
    }
  }

  static String _say(RestoreProblem p) => switch (p) {
        RestoreProblem.unreachable => "Couldn't reach your account's case files. Nothing on this device changed.",
        RestoreProblem.invalidData =>
          "This detective's records could not be checked, so nothing was restored. Your other detectives are safe.",
        RestoreProblem.deletionInProgress => 'This account is being deleted. Nothing can be restored.',
        RestoreProblem.notAllowed => "Cloud saves aren't switched on for this account.",
        RestoreProblem.accountChanged => 'The account changed while restoring. Nothing was restored.',
        RestoreProblem.notYours => 'Another detective on this device already uses this case file.',
      };

  Future<void> _choose(DetectiveProfile p) async {
    if (p.id == ref.read(profileSessionProvider).profileId) {
      context.go(Routes.start);
      return;
    }
    try {
      // A new session: its own page, starting at the title.
      await ProfileSessionHost.of(context).switchTo(p.id);
    } on StateError {
      if (mounted) setState(() => _problem = 'This detective belongs to another account.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = ref.watch(accountStateProvider.select((s) => s.uid));
    final store = ref.watch(profileStoreProvider);
    final playing = ref.watch(profileSessionProvider).profileId;
    final profiles = store.openableBy(uid)
      ..sort((a, b) => a.kind == b.kind ? 0 : (a.kind == ProfileKind.guest ? -1 : 1));
    // A detective with a case played on two devices says so (Phase 4.5): the
    // one playing from its session, the others read only.
    final prefs = ref.watch(sharedPreferencesProvider);
    SharedPrefsProgressRepository? savesOf(DetectiveProfile p) => p.kind != ProfileKind.account
        ? null
        : p.id == playing
            ? sessionSaves(ref)
            : SharedPrefsProgressRepository.peek(prefs, profileId: p.id);
    bool twoFiles(DetectiveProfile p) {
      final r = savesOf(p);
      return r != null && CaseConflicts.hasOpenChoice(r);
    }

    // A coin found under two amounts: said, never changed (Phase 4.5).
    bool coinNote(DetectiveProfile p) {
      final r = savesOf(p);
      return r != null && CaseConflicts.hasCoinNote(r);
    }

    final restore = ref.watch(profileRestoreProvider);
    final cloudAllowed = ref.watch(accountStateProvider.select((s) => s.cloudFeaturesAllowed));
    final canRestore = restore != null && uid != null && cloudAllowed;
    if (canRestore && _cloudUid != uid && !_listing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _cloudUid != uid && !_listing) _list(restore, uid);
      });
    }
    final elsewhere = [
      if (canRestore && _cloudUid == uid)
        for (final d in _cloud ?? const <AccountDetective>[])
          if (!d.onThisDevice && store.profile(d.id) == null) d,
    ];
    return AccountPage(
      eyebrow: 'THE CASEBOOK',
      title: "Who's on the Case?",
      subtitle: 'Each detective keeps their own cases and coins.',
      onBack: () => context.go(Routes.start),
      content: [
        for (final p in profiles) _ProfileRow(
              profile: p,
              playing: p.id == playing,
              twoFiles: twoFiles(p),
              coinNote: coinNote(p),
              onTap: () => _choose(p),
            ),
        if (_problem case final p?) AccountNote(p),
        if (canRestore) ...[
          if (elsewhere.isNotEmpty) ...[
            const SizedBox(height: AppSpace.md),
            Text('IN YOUR ACCOUNT', style: AppText.eyebrow(color: AppColors.inkBrown)),
            for (final d in elsewhere)
              _CloudRow(
                detective: d,
                restoring: _restoring == d.id,
                onTap: _restoring == null ? () => _restore(restore, d) : null,
              ),
          ],
          if (_listing) ...[
            const SizedBox(height: AppSpace.sm),
            Text("Checking your account's case files…", textAlign: TextAlign.center, style: AppText.caption()),
          ],
          if (_cloudProblem case final p?) AccountNote(_say(p)),
        ],
        if (uid == null) ...[
          const SizedBox(height: AppSpace.sm),
          Text('Sign in to see the detectives of your account.', textAlign: TextAlign.center, style: AppText.caption()),
        ],
      ],
      actions: [
        if (canRestore && _cloudProblem == RestoreProblem.unreachable && !_listing && _restoring == null)
          GameButton(
            label: 'TRY AGAIN',
            singleLine: true,
            style: GameButtonStyle.glass,
            onPressed: () => _list(restore, uid),
          ),
        if (uid != null)
          GameButton(
            label: 'NEW DETECTIVE',
            glyph: InkGlyph.pen,
            singleLine: true,
            style: GameButtonStyle.glass,
            onPressed: () => context.go(Routes.newProfile),
          )
        else
          GameButton(
            label: 'SIGN IN',
            singleLine: true,
            style: GameButtonStyle.glass,
            onPressed: () => context.go(Routes.account),
          ),
      ],
    );
  }
}

/// One detective on the list: the name, whose it is, and "Playing now".
class _ProfileRow extends StatelessWidget {
  const _ProfileRow({required this.profile, required this.playing, required this.onTap, this.twoFiles = false, this.coinNote = false});

  final DetectiveProfile profile;
  final bool playing;
  final VoidCallback onTap;

  /// A case of it was played on two devices: two case files to choose from.
  final bool twoFiles;

  /// A coin was counted differently on two devices: kept as it is here.
  final bool coinNote;

  @override
  Widget build(BuildContext context) {
    final guest = profile.kind == ProfileKind.guest;
    final name = profile.detectiveName ?? (guest ? 'Guest detective' : 'New detective');
    final whose = guest ? 'GUEST · THIS DEVICE' : 'YOUR ACCOUNT';
    return Semantics(
      button: true,
      selected: playing,
      label: '$name, ${guest ? 'guest on this device' : 'your account'}${playing ? ', playing now' : ''}'
          '${twoFiles ? ', a case has two case files' : ''}'
          '${coinNote ? ', coins checked, nothing lost' : ''}',
      excludeSemantics: true,
      child: InkWell(
        key: ValueKey('profile-${profile.id}'),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppLine.faint(0.3)))),
          child: Row(
            children: [
              InkIcon(guest ? InkGlyph.deerstalker : InkGlyph.folder, size: AppIconSize.medium, color: AppColors.goldDeep),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppText.subtitle(color: AppColors.navy)),
                    Text(whose, style: AppText.eyebrow(color: AppColors.inkBrown)),
                    if (twoFiles) ...[
                      const SizedBox(height: AppSpace.xs),
                      const TwoFilesTag(label: 'A CASE HAS TWO FILES'),
                    ],
                    if (coinNote) ...[
                      const SizedBox(height: AppSpace.xs),
                      const CoinNoteTag(),
                    ],
                  ],
                ),
              ),
              if (playing) ...[
                const InkIcon(InkGlyph.check, size: AppIconSize.small, color: AppColors.success),
                const SizedBox(width: AppSpace.xs),
                Text('Playing', style: AppText.caption(color: AppColors.success)),
              ] else
                const InkIcon(InkGlyph.arrow, size: AppIconSize.small, color: AppColors.inkBrown),
            ],
          ),
        ),
      ),
    );
  }
}

/// One of the account's detectives that is not on this device yet: choosing
/// it restores it here.
class _CloudRow extends StatelessWidget {
  const _CloudRow({required this.detective, required this.restoring, required this.onTap});

  final AccountDetective detective;
  final bool restoring;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final name = detective.detectiveName;
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: '$name, in your account, ${restoring ? 'restoring' : 'restore to this device'}',
      excludeSemantics: true,
      child: InkWell(
        key: ValueKey('cloud-profile-${detective.id}'),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(vertical: AppSpace.sm),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppLine.faint(0.3)))),
          child: Row(
            children: [
              const InkIcon(InkGlyph.letter, size: AppIconSize.medium, color: AppColors.goldDeep),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: AppText.subtitle(color: AppColors.navy)),
                    Text(restoring ? 'RESTORING…' : 'ON ANOTHER DEVICE · RESTORE', style: AppText.eyebrow(color: AppColors.inkBrown)),
                  ],
                ),
              ),
              const InkIcon(InkGlyph.down, size: AppIconSize.small, color: AppColors.inkBrown),
            ],
          ),
        ),
      ),
    );
  }
}

/// A new detective for the signed-in account: a name (the one name rule),
/// then it plays. The guest and the other detectives are not touched.
class NewProfileScreen extends ConsumerStatefulWidget {
  const NewProfileScreen({super.key});

  @override
  ConsumerState<NewProfileScreen> createState() => _NewProfileScreenState();
}

class _NewProfileScreenState extends ConsumerState<NewProfileScreen> {
  final _name = TextEditingController();
  bool _busy = false;
  String? _problem;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (_busy) return;
    final uid = ref.read(accountStateProvider).uid;
    if (uid == null) {
      setState(() => _problem = 'Please sign in first.');
      return;
    }
    final error = GameController.validateName(_name.text);
    if (error != null) {
      setState(() => _problem = error);
      return;
    }
    setState(() => _busy = true);
    final name = GameController.cleanName(_name.text);
    final profile = await ref
        .read(profileStoreProvider)
        .addProfile(kind: ProfileKind.account, ownerUid: uid, detectiveName: name);
    if (!mounted) return;
    final host = ProfileSessionHost.of(context);
    await host.switchTo(profile.id);
    // The new detective's own saves carry the name (as registration does).
    host.container.read(gameControllerProvider.notifier).registerDetective(name);
  }

  @override
  Widget build(BuildContext context) {
    return AccountPage(
      eyebrow: 'DETECTIVE REGISTRATION',
      title: 'A New Detective',
      subtitle: 'What should we call them?',
      onBack: () => context.go(Routes.profiles),
      content: [
        LedgerField(
          label: 'Detective name',
          controller: _name,
          enabled: !_busy,
          textCapitalization: TextCapitalization.characters,
          maxLength: DetectiveName.maxLength,
          inputFormatters: [
            FilteringTextInputFormatter.allow(DetectiveName.typeable),
            LengthLimitingTextInputFormatter(DetectiveName.maxLength),
          ],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _create(),
        ),
        Text(
          'Up to ${DetectiveName.maxLength}: letters, numbers, spaces, . and -',
          textAlign: TextAlign.center,
          style: AppText.caption(),
        ),
        if (_problem case final p?) AccountNote(p),
      ],
      actions: [
        GameButton(
          label: 'CREATE DETECTIVE',
          arrow: true,
          singleLine: true,
          style: GameButtonStyle.glass,
          tap: TapRole.primary,
          onPressed: _busy ? null : _create,
        ),
      ],
    );
  }
}
