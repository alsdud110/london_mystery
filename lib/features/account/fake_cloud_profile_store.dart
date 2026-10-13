import 'cloud_profile_store.dart';
import 'consent.dart';

/// [CloudProfileStore] in memory, for tests and previews. It answers as the
/// Firestore rules do: only the signed-in account ([signedInUid]) reaches its
/// own documents, every write needs its confirmed consent ([consents]), only
/// the allowed fields and values, nothing is deleted.
class FakeCloudProfileStore implements CloudProfileStore {
  FakeCloudProfileStore({required this.consents, required this.signedInUid});

  final ConsentRepository consents;

  /// Who is signed in now (null: nobody), as the sign-in provider says.
  final String? Function() signedInUid;

  /// Accounts made (uid → locale, region).
  final accounts = <String, ({String locale, String region})>{};
  final _profiles = <String, Map<String, CloudProfile>>{};

  /// The next call answers this instead (then it is cleared), e.g. offline.
  CloudWriteResult? failNext;

  /// Server time, for tests.
  DateTime Function() now = DateTime.now;

  int writes = 0;

  Future<CloudWriteResult> _check(String uid) async {
    final failure = failNext;
    failNext = null;
    if (failure != null) return failure;
    if (signedInUid() != uid) return CloudWriteResult.denied;
    if (await consents.statusOf(uid) != ConsentStatus.confirmed) return CloudWriteResult.consentRequired;
    return CloudWriteResult.done;
  }

  @override
  Future<CloudWriteResult> ensureAccount(String uid, {String locale = 'ko', String region = 'KR'}) async {
    if (!CloudPaths.locale.hasMatch(locale) || !CloudPaths.region.hasMatch(region)) return CloudWriteResult.invalid;
    final ok = await _check(uid);
    if (ok != CloudWriteResult.done) return ok;
    if (accounts.containsKey(uid)) return CloudWriteResult.done;
    accounts[uid] = (locale: locale, region: region);
    writes++;
    return CloudWriteResult.done;
  }

  @override
  Future<CloudWriteResult> createProfile(String uid, {required String profileId, required String detectiveName}) async {
    if (!CloudPaths.validProfileId(profileId) || !CloudPaths.validName(detectiveName)) {
      return CloudWriteResult.invalid;
    }
    final ok = await _check(uid);
    if (ok != CloudWriteResult.done) return ok;
    if (!accounts.containsKey(uid)) return CloudWriteResult.noAccountDocument;
    final mine = _profiles.putIfAbsent(uid, () => {});
    // An existing profile is not made again (its createdAt stays).
    if (mine.containsKey(profileId)) return CloudWriteResult.denied;
    mine[profileId] = CloudProfile(id: profileId, detectiveName: detectiveName, createdAt: now());
    writes++;
    return CloudWriteResult.done;
  }

  @override
  Future<CloudWriteResult> renameProfile(String uid, {required String profileId, required String detectiveName}) async {
    if (!CloudPaths.validName(detectiveName)) return CloudWriteResult.invalid;
    final ok = await _check(uid);
    if (ok != CloudWriteResult.done) return ok;
    final p = _profiles[uid]?[profileId];
    if (p == null) return CloudWriteResult.denied;
    _profiles[uid]![profileId] = CloudProfile(id: p.id, detectiveName: detectiveName, createdAt: p.createdAt);
    writes++;
    return CloudWriteResult.done;
  }

  @override
  Future<List<CloudProfile>> profilesOf(String uid) async {
    if (signedInUid() != uid) return const [];
    return [...?_profiles[uid]?.values];
  }
}
