/// Whether the privacy consent an account needs is confirmed.
///
/// In Korea, personal data of a user under 14 may be processed only with a
/// legal guardian's consent. How age is checked and how that consent is
/// given and recorded is not decided yet (legal review). Until it is,
/// nobody is [confirmed] and no personal data goes to the cloud.
enum ConsentStatus {
  /// Not confirmed (or not checked yet). Cloud features stay locked.
  unconfirmed,

  /// Confirmed by the decided procedure (age check, and a legal guardian's
  /// consent where needed).
  confirmed,
}

/// The consent status of each account, from a trusted record. Never derived
/// from signing in or from a checked email address: neither is a legal
/// guardian's consent.
abstract interface class ConsentRepository {
  Future<ConsentStatus> statusOf(String uid);
}

/// Until the consent procedure is decided: every account is unconfirmed.
class UndecidedConsent implements ConsentRepository {
  const UndecidedConsent();

  @override
  Future<ConsentStatus> statusOf(String uid) async => ConsentStatus.unconfirmed;
}
