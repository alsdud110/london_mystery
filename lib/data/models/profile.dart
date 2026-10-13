import 'package:flutter/foundation.dart';

/// What kind of detective a profile is. Stored by [name]: never rename one.
enum ProfileKind {
  /// Plays on this device without an account (one per device). Never synced.
  guest,

  /// A detective profile owned by a user account (see [DetectiveProfile.ownerUid]).
  account;

  static ProfileKind? byName(Object? name) {
    for (final k in values) {
      if (k.name == name) return k;
    }
    return null;
  }
}

/// Where a profile's data came from. Stored by [name]: never rename one.
enum ProfileOrigin {
  /// Copied from the saves made before profiles existed.
  legacy,

  /// Started new on this device.
  fresh,

  /// Touched by the operator (playtest) tools: test data, never to be synced
  /// to a live cloud or linked to an account.
  playtest;

  static ProfileOrigin? byName(Object? name) {
    for (final o in values) {
      if (o.name == name) return o;
    }
    return null;
  }
}

/// Whether the profile's first wallet still has to pay back a save from
/// before coins existed. Stored by [name]: never rename one.
enum WalletBackfill {
  /// A legacy save without a wallet: the first wallet pays it back, once.
  pending,

  /// Paid back (or there was a wallet already).
  done,

  /// Nothing to pay back: the wallet starts with the start coins only.
  never;

  static WalletBackfill? byName(Object? name) {
    for (final w in values) {
      if (w.name == name) return w;
    }
    return null;
  }
}

/// One detective on this device. Its saves live under its own storage
/// namespace (see `AppConstants.profileKey`), so two detectives never share
/// progress, coins or tips.
@immutable
class DetectiveProfile {
  const DetectiveProfile({
    required this.id,
    this.kind = ProfileKind.guest,
    this.origin = ProfileOrigin.fresh,
    this.walletBackfill = WalletBackfill.never,
    this.detectiveName,
    this.createdAt,
    this.needsReview = false,
    this.ownerUid,
  });

  /// Random, never changes (hex only, so it is safe inside a storage key).
  final String id;
  final ProfileKind kind;
  final ProfileOrigin origin;
  final WalletBackfill walletBackfill;

  /// The name shown for the profile. The game itself still reads the name
  /// kept in each case save (`GameProgress.detectiveName`).
  final String? detectiveName;
  final DateTime? createdAt;

  /// Found again when the profile records could not be read, next to other
  /// saved profiles: kept whole, but not synced until a grown-up has
  /// confirmed which detective it is.
  final bool needsReview;

  /// The user account this profile belongs to (the sign-in provider's id), or
  /// null for the guest. Its saves on this device open only while that
  /// account is signed in.
  final String? ownerUid;

  /// Whether this profile may be opened with [signedInUid] signed in (null:
  /// nobody): the guest always; an account's profile only for that account.
  bool mayOpen(String? signedInUid) => ownerUid == null || ownerUid == signedInUid;

  static final _validId = RegExp(r'^[0-9a-f]{8,64}$');

  static bool isValidId(Object? id) => id is String && _validId.hasMatch(id);

  /// Whether this profile's data may ever go to a live cloud: an account
  /// profile that the operator tools never set up, and not waiting for a
  /// review. (Operator data inside it is filtered record by record.)
  bool get syncable => kind == ProfileKind.account && origin != ProfileOrigin.playtest && !needsReview;

  DetectiveProfile copyWith({
    ProfileOrigin? origin,
    WalletBackfill? walletBackfill,
    String? detectiveName,
    bool? needsReview,
  }) =>
      DetectiveProfile(
        id: id,
        kind: kind,
        origin: origin ?? this.origin,
        walletBackfill: walletBackfill ?? this.walletBackfill,
        detectiveName: detectiveName ?? this.detectiveName,
        createdAt: createdAt,
        needsReview: needsReview ?? this.needsReview,
        ownerUid: ownerUid,
      );

  /// The same profile after everything it played was wiped: no name, and
  /// nothing left to pay back.
  DetectiveProfile startedOver({required ProfileOrigin origin}) => DetectiveProfile(
        id: id,
        kind: kind,
        origin: origin,
        createdAt: createdAt,
        needsReview: needsReview,
        ownerUid: ownerUid,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'origin': origin.name,
        'walletBackfill': walletBackfill.name,
        if (detectiveName != null) 'detectiveName': detectiveName,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (needsReview) 'needsReview': true,
        if (ownerUid != null) 'ownerUid': ownerUid,
      };

  /// Null for an entry that cannot be read. Unknown values fall back to the
  /// safest reading: playtest stays out of sync, nothing is paid back.
  static DetectiveProfile? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    if (!isValidId(id)) return null;
    final name = json['detectiveName'];
    final created = json['createdAt'];
    return DetectiveProfile(
      id: id as String,
      kind: ProfileKind.byName(json['kind']) ?? ProfileKind.guest,
      origin: ProfileOrigin.byName(json['origin']) ?? ProfileOrigin.playtest,
      walletBackfill: WalletBackfill.byName(json['walletBackfill']) ?? WalletBackfill.never,
      detectiveName: name is String && name.isNotEmpty ? name : null,
      createdAt: created is String ? DateTime.tryParse(created) : null,
      needsReview: json['needsReview'] == true,
      ownerUid: switch (json['ownerUid']) {
        final String uid when uid.isNotEmpty => uid,
        _ => null,
      },
    );
  }
}

/// Every detective on this device and which one is playing.
@immutable
class ProfileRegistry {
  const ProfileRegistry({required this.activeProfileId, required this.profiles});

  static const schema = 1;

  final String activeProfileId;
  final List<DetectiveProfile> profiles;

  DetectiveProfile? byId(String id) {
    for (final p in profiles) {
      if (p.id == id) return p;
    }
    return null;
  }

  DetectiveProfile get active => byId(activeProfileId)!;

  /// [profile] added, or put in place of the profile with its id.
  ProfileRegistry upsert(DetectiveProfile profile) => ProfileRegistry(
        activeProfileId: activeProfileId,
        profiles: byId(profile.id) == null
            ? [...profiles, profile]
            : [for (final p in profiles) p.id == profile.id ? profile : p],
      );

  ProfileRegistry withActive(String id) {
    if (byId(id) == null) throw ArgumentError.value(id, 'id', 'no such profile');
    return ProfileRegistry(activeProfileId: id, profiles: profiles);
  }

  Map<String, dynamic> toJson() => {
        'schema': schema,
        'activeProfileId': activeProfileId,
        'profiles': [for (final p in profiles) p.toJson()],
      };

  /// Null when nothing usable is saved. Unreadable profiles are dropped, a
  /// repeated id keeps its first entry, and an unknown active id falls back
  /// to the first profile.
  static ProfileRegistry? fromJson(Object? json) {
    if (json is! Map) return null;
    final raw = json['profiles'];
    if (raw is! List) return null;
    final profiles = <DetectiveProfile>[];
    for (final e in raw) {
      final p = DetectiveProfile.fromJson(e);
      if (p != null && !profiles.any((q) => q.id == p.id)) profiles.add(p);
    }
    if (profiles.isEmpty) return null;
    final active = json['activeProfileId'];
    return ProfileRegistry(
      activeProfileId: profiles.any((p) => p.id == active) ? active as String : profiles.first.id,
      profiles: profiles,
    );
  }
}
