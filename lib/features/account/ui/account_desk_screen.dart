import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../widgets/game_button.dart';
import '../account_controller.dart';
import '../auth_service.dart';
import 'account_page.dart';

/// The Account Desk: sign in, or (DEV builds only) make a new account. The
/// game never waits on it: "Play as a guest" goes back to the title page,
/// and a failure leaves the guest playing as before. Signing in changes no
/// profile's owner and uploads nothing.
class AccountDeskScreen extends ConsumerStatefulWidget {
  const AccountDeskScreen({super.key, this.newAccount = false});

  /// Opens on NEW ACCOUNT (when this build takes new accounts).
  final bool newAccount;

  @override
  ConsumerState<AccountDeskScreen> createState() => _AccountDeskScreenState();
}

class _AccountDeskScreenState extends ConsumerState<AccountDeskScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _again = TextEditingController();
  late bool _creating = widget.newAccount && ref.read(accountControllerProvider).signUpOpen;
  bool _busy = false;
  String? _problem;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _again.dispose();
    super.dispose();
  }

  void _mode(bool creating) => setState(() {
        _creating = creating;
        _problem = null;
        _again.clear();
      });

  Future<void> _submit() async {
    if (_busy) return;
    FocusManager.instance.primaryFocus?.unfocus();
    if (_creating && _password.text != _again.text) {
      setState(() => _problem = 'The two passwords are not the same.');
      return;
    }
    setState(() {
      _busy = true;
      _problem = null;
    });
    final account = ref.read(accountControllerProvider);
    final r = _creating
        ? await account.signUp(email: _email.text, password: _password.text)
        : await account.signIn(email: _email.text, password: _password.text);
    if (!mounted) return;
    if (!r.ok) {
      setState(() {
        _busy = false;
        _problem = r.failure!.message;
      });
      return;
    }
    _password.clear();
    _again.clear();
    // A new address is checked first; then the detectives.
    context.go(r.session?.emailVerified ?? false ? Routes.profiles : Routes.accountVerify);
  }

  @override
  Widget build(BuildContext context) {
    final account = ref.watch(accountControllerProvider);
    final status = ref.watch(accountStateProvider.select((s) => s.status));
    final available = status == AccountStatus.signedOut || status == AccountStatus.signedIn;
    final creating = _creating && account.signUpOpen;
    return AccountPage(
      title: creating ? 'Open a New Account' : 'Sign In',
      subtitle: creating ? 'Keep your detectives with your account.' : 'Welcome back, Detective.',
      onBack: () => context.go(Routes.start),
      content: [
        if (account.signUpOpen) _Tabs(creating: creating, onChange: _busy ? null : _mode),
        if (!available)
          AccountNote(
            status == AccountStatus.starting ? 'Opening the account desk…' : AuthFailure.cloudUnavailable.message,
            problem: status != AccountStatus.starting,
          ),
        AutofillGroup(
          child: Column(
            children: [
              LedgerField(
                label: 'Email',
                controller: _email,
                enabled: !_busy,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
              ),
              LedgerField(
                label: 'Password',
                controller: _password,
                enabled: !_busy,
                password: true,
                autofillHints: [creating ? AutofillHints.newPassword : AutofillHints.password],
                textInputAction: creating ? TextInputAction.next : TextInputAction.done,
                onSubmitted: creating ? null : (_) => _submit(),
              ),
              if (creating) ...[
                LedgerField(
                  label: 'Password again',
                  controller: _again,
                  enabled: !_busy,
                  password: true,
                  autofillHints: const [AutofillHints.newPassword],
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                ),
                Text(
                  'At least 8 characters, with letters and numbers.',
                  textAlign: TextAlign.center,
                  style: AppText.caption(),
                ),
              ],
            ],
          ),
        ),
        if (_problem case final p?) AccountNote(p),
        if (!creating)
          Center(
            child: InkTextButton(
              label: 'Forgot your password?',
              onPressed: _busy ? null : () => context.go(Routes.accountReset),
            ),
          ),
      ],
      actions: [
        GameButton(
          label: _busy ? 'ONE MOMENT…' : (creating ? 'CREATE ACCOUNT' : 'SIGN IN'),
          arrow: true,
          singleLine: true,
          style: GameButtonStyle.glass,
          onPressed: _busy || !available ? null : _submit,
        ),
        SizedBox(
          height: 52,
          child: Center(
            child: InkTextButton(
              label: 'Play as a guest',
              color: AppColors.paperLight.withValues(alpha: 0.8),
              onPressed: () => context.go(Routes.start),
            ),
          ),
        ),
      ],
    );
  }
}

/// SIGN IN | NEW ACCOUNT: two ink tabs, the open one underlined in gold.
class _Tabs extends StatelessWidget {
  const _Tabs({required this.creating, required this.onChange});

  final bool creating;
  final ValueChanged<bool>? onChange;

  @override
  Widget build(BuildContext context) {
    Widget tab(String label, bool value) {
      final open = creating == value;
      return Expanded(
        child: Semantics(
          selected: open,
          button: true,
          child: InkWell(
            onTap: onChange == null || open ? null : () => onChange!(value),
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: open ? AppColors.goldDeep : AppLine.faint(0.3),
                    width: open ? AppLine.ink : AppLine.hairline,
                  ),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.xs),
              // One line whatever the text size: the tab shrinks a little.
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label, maxLines: 1, style: AppText.eyebrow(color: open ? AppColors.navy : AppColors.muted)),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: Row(children: [tab('SIGN IN', false), tab('NEW ACCOUNT', true)]),
    );
  }
}
