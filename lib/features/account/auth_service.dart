import 'package:flutter/foundation.dart';

/// A signed-in user, as the sign-in provider reports it. The [uid] comes
/// only from the provider (never from input or storage); it owns the
/// user's detective profiles. Holds no email, password or token.
@immutable
class UserSession {
  const UserSession({required this.uid, required this.emailVerified});

  final String uid;
  final bool emailVerified;

  @override
  bool operator ==(Object other) =>
      other is UserSession && other.uid == uid && other.emailVerified == emailVerified;

  @override
  int get hashCode => Object.hash(uid, emailVerified);

  /// Never prints the uid in full (logs).
  @override
  String toString() => 'UserSession(${uid.length > 4 ? '${uid.substring(0, 4)}…' : '…'}, verified: $emailVerified)';
}

/// Why an account action did not succeed: a short code for the app, turned
/// into a message for the player by [message]. Provider details stay out of
/// the screen and the logs.
enum AuthFailure {
  /// Not a usable email address.
  invalidEmail,

  /// The email or the password is wrong (never says which).
  wrongCredentials,

  /// An account with this email exists already.
  emailInUse,

  /// The password is too short or too simple.
  weakPassword,

  /// Too many tries: wait a while.
  tooManyRequests,

  /// No connection.
  network,

  /// The action needs the password again (see [AuthService.reauthenticate]).
  requiresRecentLogin,

  /// The account was turned off.
  userDisabled,

  /// Nobody is signed in.
  notSignedIn,

  /// Accounts are not available on this device right now (Firebase off for
  /// this build, or not started).
  cloudUnavailable,

  /// New accounts cannot be made in this build (see
  /// `CloudEnvironment.signUpOpen`).
  signUpClosed,

  /// Anything else.
  unknown;

  /// For the player (English, as the game speaks; calm, no internal detail).
  String get message => switch (this) {
        invalidEmail => 'Please check your email address.',
        wrongCredentials => 'That email or password is not right.',
        emailInUse => 'This email already has an account. Sign in, or reset the password.',
        weakPassword => 'Use at least 8 characters, with letters and numbers.',
        tooManyRequests => 'Too many tries. Please wait a little and try again.',
        network => 'No internet connection. Check it and try again.',
        requiresRecentLogin => 'For safety, please type your password again.',
        userDisabled => 'This account cannot be used. Please contact support.',
        notSignedIn => 'Please sign in first.',
        cloudUnavailable => 'Accounts are not available right now. You can keep playing.',
        signUpClosed => 'New accounts are not open yet. You can play as a guest.',
        unknown => 'Something went wrong. Please try again.',
      };
}

/// The outcome of an account action.
@immutable
class AuthResult {
  const AuthResult.ok([this.session]) : failure = null;

  const AuthResult.failed(AuthFailure this.failure) : session = null;

  final UserSession? session;
  final AuthFailure? failure;

  bool get ok => failure == null;
}

/// User sign-in (email and password). Implementations: `FirebaseAuthService`
/// (the app), `FakeAuthService` (tests).
///
/// Signing in, or a checked email address, is not the consent a legal
/// guardian must give for a child under 14: nothing here records or implies
/// it (see `ConsentRepository`).
abstract interface class AuthService {
  /// The signed-in user, now and on every change (null: signed out). A
  /// session kept from an earlier start comes back here.
  Stream<UserSession?> sessions();

  UserSession? get current;

  Future<AuthResult> signUp({required String email, required String password});

  Future<AuthResult> signIn({required String email, required String password});

  /// Sends a password reset email. Reports success whether or not the
  /// address has an account (it does not tell who has one).
  Future<AuthResult> sendPasswordReset(String email);

  /// Asks for the password again before a sensitive action (account or
  /// profile deletion, consent withdrawal).
  Future<AuthResult> reauthenticate(String password);

  /// Sends the email address check to the signed-in user.
  Future<AuthResult> sendEmailVerification();

  /// Asks the provider again whether the email address is checked.
  Future<AuthResult> refreshEmailVerified();

  /// The signed-in user's email address, partly hidden (for the account
  /// page), or null. The full address is never kept by the app.
  String? get maskedEmail;

  Future<void> signOut();
}

/// Checks done before anything is sent (server-side rules still apply).
abstract final class AuthCredentials {
  static const passwordMinLength = 8;
  static const passwordMaxLength = 128;
  static final _email = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

  static String cleanEmail(String raw) => raw.trim();

  /// "detective@example.com" → "de•••@ex•••.com": enough to recognise it.
  static String mask(String email) {
    final at = email.lastIndexOf('@');
    if (at <= 0) return '•••';
    String keep(String s, int n) => s.length <= n ? s : s.substring(0, n);
    final domain = email.substring(at + 1);
    final dot = domain.lastIndexOf('.');
    final host = dot > 0 ? domain.substring(0, dot) : domain;
    final tld = dot > 0 ? domain.substring(dot) : '';
    return '${keep(email.substring(0, at), 2)}•••@${keep(host, 2)}•••$tld';
  }

  static AuthFailure? checkEmail(String raw) {
    final email = cleanEmail(raw);
    return email.isEmpty || email.length > 254 || !_email.hasMatch(email) ? AuthFailure.invalidEmail : null;
  }

  /// At least 8 characters, letters and digits, at most 128.
  static AuthFailure? checkNewPassword(String password) {
    final ok = password.length >= passwordMinLength &&
        password.length <= passwordMaxLength &&
        password.contains(RegExp(r'[A-Za-z]')) &&
        password.contains(RegExp(r'[0-9]'));
    return ok ? null : AuthFailure.weakPassword;
  }
}
