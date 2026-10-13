import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cloud/cloud_bootstrap.dart';
import 'auth_service.dart';
import 'consent.dart';

/// Where the user account stands on this device.
enum AccountStatus {
  /// Accounts cannot be used now (Firebase off for this build, or it could
  /// not start). The game goes on as a guest.
  unavailable,

  /// Firebase is still starting.
  starting,

  signedOut,
  signedIn,
}

@immutable
class AccountState {
  const AccountState(this.status, [this.session, this.consent = ConsentStatus.unconfirmed]);

  final AccountStatus status;
  final UserSession? session;

  /// The signed-in user's privacy consent (see [ConsentRepository]). Signing
  /// in or checking the email address never confirms it.
  final ConsentStatus consent;

  /// The signed-in user's id, from the sign-in provider only.
  String? get uid => status == AccountStatus.signedIn ? session?.uid : null;

  bool get consentConfirmed => uid != null && consent == ConsentStatus.confirmed;

  /// Cloud features (saving to the cloud, profiles in the account) need a
  /// signed-in user whose consent is confirmed. Until the consent procedure
  /// is decided, nobody's is.
  bool get cloudFeaturesAllowed => consentConfirmed;

  @override
  bool operator ==(Object other) =>
      other is AccountState && other.status == status && other.session == session && other.consent == consent;

  @override
  int get hashCode => Object.hash(status, session, consent);
}

/// The user account of this device, outside the profile sessions (it stays
/// when profiles are switched). It makes the [AuthService] only once
/// Firebase is ready: before that, and when Firebase is off or failed, every
/// action answers [AuthFailure.cloudUnavailable] and nothing calls Firebase.
/// A failed action never touches the game or its saves.
class AccountController extends ValueNotifier<AccountState> {
  AccountController({required this.cloud, required this.createAuth, this.consents = const UndecidedConsent()})
      : super(const AccountState(AccountStatus.starting)) {
    cloud.addListener(_onCloud);
    _onCloud();
  }

  final CloudBootstrap cloud;

  /// Makes the sign-in service; called once, when Firebase is ready.
  final AuthService Function() createAuth;

  /// Where each account's consent status comes from.
  final ConsentRepository consents;

  AuthService? _auth;
  StreamSubscription<UserSession?>? _sessions;

  void _onCloud() {
    switch (cloud.value) {
      case CloudStatus.ready:
        _attach();
      case CloudStatus.starting:
        if (_auth == null) value = const AccountState(AccountStatus.starting);
      case CloudStatus.disabled || CloudStatus.unavailable:
        if (_auth == null) value = const AccountState(AccountStatus.unavailable);
    }
  }

  void _attach() {
    if (_auth != null) return;
    cloud.requireReady();
    final auth = _auth = createAuth();
    // A session kept from an earlier start comes back here.
    _sessions = auth.sessions().listen(_onSession);
  }

  Future<void> _onSession(UserSession? s) async {
    if (s == null) {
      value = const AccountState(AccountStatus.signedOut);
      return;
    }
    // Unconfirmed until the record says otherwise.
    value = AccountState(AccountStatus.signedIn, s);
    final consent = await consents.statusOf(s.uid);
    if (value.session?.uid == s.uid) value = AccountState(AccountStatus.signedIn, value.session, consent);
  }

  Future<AuthResult> _use(Future<AuthResult> Function(AuthService auth) action) async {
    final auth = _auth;
    if (auth == null) return const AuthResult.failed(AuthFailure.cloudUnavailable);
    return action(auth);
  }

  Future<AuthResult> signUp({required String email, required String password}) =>
      _use((a) => a.signUp(email: email, password: password));

  Future<AuthResult> signIn({required String email, required String password}) =>
      _use((a) => a.signIn(email: email, password: password));

  Future<AuthResult> sendPasswordReset(String email) => _use((a) => a.sendPasswordReset(email));

  /// Before a sensitive action: the password again.
  Future<AuthResult> reauthenticate(String password) => _use((a) => a.reauthenticate(password));

  Future<AuthResult> sendEmailVerification() => _use((a) => a.sendEmailVerification());

  Future<AuthResult> refreshEmailVerified() => _use((a) => a.refreshEmailVerified());

  /// Ends the account session only: the guest and the local saves stay.
  Future<void> signOut() async => _auth?.signOut();

  @override
  void dispose() {
    cloud.removeListener(_onCloud);
    _sessions?.cancel();
    super.dispose();
  }
}

/// The device's user account, given to every profile session by `main()`.
/// Without an override: accounts unavailable.
final accountControllerProvider = Provider<AccountController>((ref) {
  final c = AccountController(
    cloud: ref.watch(cloudBootstrapProvider),
    createAuth: () => throw StateError('no sign-in in this build'),
  );
  ref.onDispose(c.dispose);
  return c;
});

/// The account state, for widgets and providers.
class AccountStateNotifier extends Notifier<AccountState> {
  @override
  AccountState build() {
    final controller = ref.watch(accountControllerProvider);
    void follow() => state = controller.value;
    controller.addListener(follow);
    ref.onDispose(() => controller.removeListener(follow));
    return controller.value;
  }
}

final accountStateProvider = NotifierProvider<AccountStateNotifier, AccountState>(AccountStateNotifier.new);
