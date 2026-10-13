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
import '../../../widgets/game_button.dart';
import '../../../widgets/ink_icon.dart';
import '../../game/game_controller.dart';
import '../../game/game_providers.dart';
import '../../profile/profile_session.dart';
import '../account_controller.dart';
import 'account_page.dart';

/// Who's on the case? The guest of this device and the signed-in account's
/// detectives — never another account's. Choosing one plays it (its own
/// saves); nothing moves between them.
class ProfileSelectScreen extends ConsumerStatefulWidget {
  const ProfileSelectScreen({super.key});

  @override
  ConsumerState<ProfileSelectScreen> createState() => _ProfileSelectScreenState();
}

class _ProfileSelectScreenState extends ConsumerState<ProfileSelectScreen> {
  String? _problem;

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
    return AccountPage(
      eyebrow: 'THE CASEBOOK',
      title: "Who's on the Case?",
      subtitle: 'Each detective keeps their own cases and coins.',
      onBack: () => context.go(Routes.start),
      content: [
        for (final p in profiles) _ProfileRow(profile: p, playing: p.id == playing, onTap: () => _choose(p)),
        if (_problem case final p?) AccountNote(p),
        if (uid == null) ...[
          const SizedBox(height: AppSpace.sm),
          Text('Sign in to see the detectives of your account.', textAlign: TextAlign.center, style: AppText.caption()),
        ],
      ],
      actions: [
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
  const _ProfileRow({required this.profile, required this.playing, required this.onTap});

  final DetectiveProfile profile;
  final bool playing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final guest = profile.kind == ProfileKind.guest;
    final name = profile.detectiveName ?? (guest ? 'Guest detective' : 'New detective');
    final whose = guest ? 'GUEST · THIS DEVICE' : 'YOUR ACCOUNT';
    return Semantics(
      button: true,
      selected: playing,
      label: '$name, ${guest ? 'guest on this device' : 'your account'}${playing ? ', playing now' : ''}',
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
