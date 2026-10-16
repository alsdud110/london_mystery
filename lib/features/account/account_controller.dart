import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/cloud/cloud_bootstrap.dart';
import '../../core/cloud/cloud_environment.dart';
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
    if (s?.uid != _sendFailureUid) _setSendFailure(null);
    if (s == null) {
      value = const AccountState(AccountStatus.signedOut);
      return;
    }
    // Unconfirmed until the record says otherwise.
    value = AccountState(AccountStatus.signedIn, s);
    final consent = await consents.statusOf(s.uid);
    if (value.session?.uid == s.uid) value = AccountState(AccountStatus.signedIn, value.session, consent);
  }

  /// Reads the signed-in user's consent again (e.g. it was withdrawn, or
  /// confirmed since sign-in). Fails closed like the first read: anything
  /// but a confirmed record leaves it unconfirmed.
  Future<ConsentStatus> refreshConsent() async {
    final s = value.session;
    if (value.uid == null || s == null) return ConsentStatus.unconfirmed;
    final consent = await consents.statusOf(s.uid);
    if (value.uid == s.uid && value.consent != consent) value = AccountState(AccountStatus.signedIn, value.session, consent);
    return value.uid == s.uid ? value.consent : ConsentStatus.unconfirmed;
  }

  Future<AuthResult> _use(Future<AuthResult> Function(AuthService auth) action) async {
    final auth = _auth;
    if (auth == null) return const AuthResult.failed(AuthFailure.cloudUnavailable);
    return action(auth);
  }

  /// Whether this build takes new accounts (DEV only, see
  /// [CloudEnvironment.signUpOpen]). The screen hides sign-up when not, and
  /// [signUp] refuses it all the same.
  bool get signUpOpen => cloud.decision.environment?.signUpOpen ?? false;

  /// Whether the account can be deleted from the app (not yet: see
  /// [CloudEnvironment.accountDeletionAvailable]).
  bool get deletionAvailable => cloud.decision.environment?.accountDeletionAvailable ?? false;

  /// Whether this build offers the account pages (see
  /// [CloudEnvironment.accountsShown]).
  bool get accountsShown => cloud.decision.environment?.accountsShown ?? false;

  /// A test build on the DEV project (shows what is still to come there).
  bool get devBuild => cloud.decision.environment == CloudEnvironment.dev;

  /// The signed-in user's email address, partly hidden.
  String? get maskedEmail => _auth?.maskedEmail;

  /// Why the email address check could not be sent right after sign-up
  /// (null: it was sent, or there was no sign-up). The check page says so
  /// and offers to send it again.
  /// Only for the account it happened to: signing out or another account
  /// signing in clears it.
  AuthFailure? get verificationSendFailure => _sendFailureUid == value.uid ? _verificationSendFailure : null;
  AuthFailure? _verificationSendFailure;
  String? _sendFailureUid;

  void _setSendFailure(AuthFailure? f) {
    _verificationSendFailure = f;
    _sendFailureUid = f == null ? null : value.uid;
  }

  /// Makes an account and signs it in, then sends the email address check.
  /// Nothing else happens: no profile changes owner, nothing is uploaded.
  /// The account is made even if the check cannot be sent (see
  /// [verificationSendFailure]).
  Future<AuthResult> signUp({required String email, required String password}) async {
    if (!signUpOpen) return const AuthResult.failed(AuthFailure.signUpClosed);
    final r = await _use((a) => a.signUp(email: email, password: password));
    _setSendFailure(null);
    if (r.ok) _setSendFailure((await _use((a) => a.sendEmailVerification())).failure);
    return r;
  }

  /// Sends the email address check (again).
  Future<AuthResult> sendEmailVerification() async {
    final r = await _use((a) => a.sendEmailVerification());
    _setSendFailure(r.failure);
    return r;
  }

  Future<AuthResult> signIn({required String email, required String password}) =>
      _use((a) => a.signIn(email: email, password: password));

  Future<AuthResult> sendPasswordReset(String email) => _use((a) => a.sendPasswordReset(email));

  /// Before a sensitive action: the password again.
  Future<AuthResult> reauthenticate(String password) => _use((a) => a.reauthenticate(password));


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
