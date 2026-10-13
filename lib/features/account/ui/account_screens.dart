import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../widgets/game_button.dart';
import '../../../widgets/game_dialog.dart';
import '../../../widgets/ink_icon.dart';
import '../account_controller.dart';
import '../auth_service.dart';
import 'account_page.dart';

/// Forgot your password: one line for the email address. The answer is the
/// same whether or not the address has an account.
class PasswordResetScreen extends ConsumerStatefulWidget {
  const PasswordResetScreen({super.key});

  @override
  ConsumerState<PasswordResetScreen> createState() => _PasswordResetScreenState();
}

class _PasswordResetScreenState extends ConsumerState<PasswordResetScreen> {
  final _email = TextEditingController();
  bool _busy = false;
  String? _note;
  bool _problem = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_busy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _busy = true);
    final r = await ref.read(accountControllerProvider).sendPasswordReset(_email.text);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _problem = !r.ok;
      _note = r.ok ? 'If an account uses this email, a reset link is on its way. Check your inbox.' : r.failure!.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final back = ref.read(accountStateProvider).uid == null ? Routes.account : Routes.accountSettings;
    return AccountPage(
      title: 'Reset Your Password',
      subtitle: 'We will send a link to your email.',
      onBack: () => context.go(back),
      content: [
        LedgerField(
          label: 'Email',
          controller: _email,
          enabled: !_busy,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _send(),
        ),
        if (_note case final n?) AccountNote(n, problem: _problem),
      ],
      actions: [
        GameButton(
          label: _busy ? 'ONE MOMENT…' : 'SEND RESET LINK',
          singleLine: true,
          style: GameButtonStyle.glass,
          onPressed: _busy ? null : _send,
        ),
      ],
    );
  }
}

/// The email address check: what to do, "I've checked it", and "send it
/// again". Not required to play; the account page shows the state.
class EmailCheckScreen extends ConsumerStatefulWidget {
  const EmailCheckScreen({super.key});

  @override
  ConsumerState<EmailCheckScreen> createState() => _EmailCheckScreenState();
}

class _EmailCheckScreenState extends ConsumerState<EmailCheckScreen> {
  bool _busy = false;

  /// The letter could not be sent after sign-up: said at once, with "Send it
  /// again" (the account is made all the same).
  late final AuthFailure? _notSent = ref.read(accountControllerProvider).verificationSendFailure;
  late String? _note = _notSent == null ? null : "We couldn't send the letter. ${_notSent.message}";
  late bool _problem = _notSent != null;

  Future<void> _checked() async {
    setState(() => _busy = true);
    final r = await ref.read(accountControllerProvider).refreshEmailVerified();
    if (!mounted) return;
    if (r.ok && (r.session?.emailVerified ?? false)) {
      context.go(Routes.profiles);
      return;
    }
    setState(() {
      _busy = false;
      _problem = true;
      _note = r.ok ? 'Not checked yet. Open the link in the email, then try again.' : r.failure!.message;
    });
  }

  Future<void> _again() async {
    setState(() => _busy = true);
    final r = await ref.read(accountControllerProvider).sendEmailVerification();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _problem = !r.ok;
      _note = r.ok ? 'Sent again. It may take a minute.' : r.failure!.message;
    });
  }

  @override
  Widget build(BuildContext context) {
    final masked = ref.watch(accountControllerProvider).maskedEmail;
    return AccountPage(
      title: 'Check Your Email',
      onBack: () => context.go(Routes.profiles),
      content: [
        const Center(child: InkIcon(InkGlyph.letter, size: AppIconSize.emblem, color: AppColors.goldDeep)),
        const SizedBox(height: AppSpace.md),
        Text(
          _notSent == null
              ? 'We sent a letter to ${masked ?? 'your email'}. Open the link inside, then come back here.'
              : 'We will send a letter to ${masked ?? 'your email'}. Open the link inside, then come back here.',
          textAlign: TextAlign.center,
          style: AppText.bodyText(size: 16),
        ),
        if (_note case final n?) AccountNote(n, problem: _problem),
        const SizedBox(height: AppSpace.sm),
        Center(child: InkTextButton(label: 'Send it again', onPressed: _busy ? null : _again)),
      ],
      actions: [
        GameButton(
          label: "I'VE CHECKED MY EMAIL",
          singleLine: true,
          style: GameButtonStyle.glass,
          onPressed: _busy ? null : _checked,
        ),
        SizedBox(
          height: 52,
          child: Center(
            child: InkTextButton(
              label: 'Later',
              color: AppColors.paperLight.withValues(alpha: 0.8),
              onPressed: () => context.go(Routes.profiles),
            ),
          ),
        ),
      ],
    );
  }
}

/// The account page: who is signed in, the email check, cloud save (not
/// available yet), the detectives, password, sign out, and (DEV builds)
/// account deletion.
class AccountSettingsScreen extends ConsumerWidget {
  const AccountSettingsScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final ok = await GameDialog.confirm(
      context,
      title: 'Sign out?',
      message: 'Your detectives stay on this device. The guest detective keeps playing.',
      confirmLabel: 'SIGN OUT',
      cancelLabel: 'Stay signed in',
    );
    if (!ok) return;
    // The host closes this account's detective and opens the guest; the
    // new page starts at the title.
    await ref.read(accountControllerProvider).signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final account = ref.watch(accountControllerProvider);
    final state = ref.watch(accountStateProvider);
    final verified = state.session?.emailVerified ?? false;
    return AccountPage(
      title: 'Your Account',
      onBack: () => context.go(Routes.start),
      content: [
        AccountLine(label: 'EMAIL', value: account.maskedEmail ?? '—', glyph: InkGlyph.letter),
        AccountLine(label: 'EMAIL CHECK', value: verified ? 'Checked' : 'Not checked yet', glyph: InkGlyph.check),
        if (!verified)
          Align(
            alignment: Alignment.centerRight,
            child: InkTextButton(label: 'Check my email', onPressed: () => context.go(Routes.accountVerify)),
          ),
        const AccountLine(label: 'CLOUD SAVE', value: 'Not available yet', glyph: InkGlyph.lock),
        Text(
          'Your detectives are saved on this device. Nothing is sent to the cloud.',
          style: AppText.caption(),
        ),
        const SizedBox(height: AppSpace.md),
        Center(child: InkTextButton(label: 'Change password', onPressed: () => context.go(Routes.accountReset))),
        if (account.devBuild)
          Center(
            child: InkTextButton(
              label: 'Delete account',
              color: AppColors.tryAgain,
              onPressed: () => context.go(Routes.accountDelete),
            ),
          ),
      ],
      actions: [
        GameButton(
          label: 'SWITCH DETECTIVE',
          glyph: InkGlyph.folder,
          singleLine: true,
          style: GameButtonStyle.glass,
          onPressed: () => context.go(Routes.profiles),
        ),
        SizedBox(
          height: 52,
          child: Center(
            child: InkTextButton(
              label: 'Sign out',
              color: AppColors.paperLight.withValues(alpha: 0.8),
              onPressed: () => _signOut(context, ref),
            ),
          ),
        ),
      ],
    );
  }
}

/// Account deletion: what it would remove, and — until a server path that
/// deletes the account and its cloud documents together exists — a closed
/// button. Nothing here deletes anything yet. Shown in DEV builds only.
class AccountDeleteScreen extends ConsumerWidget {
  const AccountDeleteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final available = ref.watch(accountControllerProvider).deletionAvailable;
    return AccountPage(
      title: 'Delete Your Account',
      onBack: () => context.go(Routes.accountSettings),
      content: [
        Text(
          'Deleting your account removes your sign-in and the detectives kept in your account. '
          'It cannot be undone.',
          textAlign: TextAlign.center,
          style: AppText.bodyText(size: 16),
        ),
        const SizedBox(height: AppSpace.md),
        Text(
          'Detectives on this device stay here, and the guest detective is not touched.',
          textAlign: TextAlign.center,
          style: AppText.caption(),
        ),
        if (!available)
          const AccountNote(
            'Account deletion is not available in this test build yet. Nothing has been deleted.',
          ),
      ],
      actions: [
        GameButton(
          label: 'DELETE MY ACCOUNT',
          singleLine: true,
          style: GameButtonStyle.outline,
          // Closed until the server path exists (see CloudEnvironment).
          onPressed: null,
        ),
      ],
    );
  }
}
