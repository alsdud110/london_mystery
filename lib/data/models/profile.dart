import 'package:flutter/foundation.dart';

/// The detective's picture, chosen when the detective is created. Stored by
/// [name]: never rename one.
enum DetectiveAvatar {
  boy('BOY'),
  girl('GIRL');

  const DetectiveAvatar(this.label);

  /// The word on the choice card.
  final String label;

  static DetectiveAvatar? byName(Object? name) {
    for (final a in values) {
      if (a.name == name) return a;
    }
    return null;
  }
}

/// Where the detective's data came from. Stored by [name]: never rename one.
enum ProfileOrigin {
  /// Copied from the saves made before profiles existed.
  legacy,

  /// Started new on this device.
  fresh;

  /// Unknown values (and `playtest`, from the builds with a cloud) read as
  /// [fresh]: nothing about it changes how the game plays.
  static ProfileOrigin byName(Object? name) {
    for (final o in values) {
      if (o.name == name) return o;
    }
    return fresh;
  }
}

/// Whether the first wallet still has to pay back a save from before coins
/// existed. Stored by [name]: never rename one.
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

/// The one detective of this device. Its saves live under its own storage
/// namespace (see `AppConstants.profileKey`).
///
/// The slot exists from the first start (its [id] names the namespace); the
/// detective is *created* when a name is given (see [isCreated]). NEW
/// ADVENTURE empties the slot again; there is never a second detective.
@immutable
class DetectiveProfile {
  const DetectiveProfile({
    required this.id,
    this.origin = ProfileOrigin.fresh,
    this.walletBackfill = WalletBackfill.never,
    this.detectiveName,
    this.avatar,
    this.createdAt,
  });

  /// Random, never changes (hex only, so it is safe inside a storage key).
  final String id;
  final ProfileOrigin origin;
  final WalletBackfill walletBackfill;

  /// The detective's name. The game also keeps it in each case save
  /// (`GameProgress.detectiveName`); both change together.
  final String? detectiveName;

  /// Null for a detective made before avatars existed (chosen later, in the
  /// detective's settings).
  final DetectiveAvatar? avatar;

  /// When the detective was created (or, for older data, first found).
  final DateTime? createdAt;

  bool get isCreated => detectiveName != null;

  /// A profile id: lowercase hex, 8 to 64 digits (new ones are 32).
  static const idPattern = r'^[0-9a-f]{8,64}$';
  static final _validId = RegExp(idPattern);

  static bool isValidId(Object? id) => id is String && _validId.hasMatch(id);

  DetectiveProfile copyWith({
    ProfileOrigin? origin,
    WalletBackfill? walletBackfill,
    String? detectiveName,
    DetectiveAvatar? avatar,
    DateTime? createdAt,
  }) =>
      DetectiveProfile(
        id: id,
        origin: origin ?? this.origin,
        walletBackfill: walletBackfill ?? this.walletBackfill,
        detectiveName: detectiveName ?? this.detectiveName,
        avatar: avatar ?? this.avatar,
        createdAt: createdAt ?? this.createdAt,
      );

  /// The same slot after everything it played was wiped (NEW ADVENTURE): no
  /// name, no avatar, nothing left to pay back. The id stays.
  DetectiveProfile startedOver() => DetectiveProfile(id: id);

  Map<String, dynamic> toJson() => {
        'id': id,
        'origin': origin.name,
        'walletBackfill': walletBackfill.name,
        if (detectiveName != null) 'detectiveName': detectiveName,
        if (avatar != null) 'avatar': avatar!.name,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      };

  /// Null for an entry that cannot be read. Unknown values fall back to the
  /// safest reading: nothing is paid back.
  static DetectiveProfile? fromJson(Object? json) {
    if (json is! Map) return null;
    final id = json['id'];
    if (!isValidId(id)) return null;
    final name = json['detectiveName'];
    final created = json['createdAt'];
    return DetectiveProfile(
      id: id as String,
      origin: ProfileOrigin.byName(json['origin']),
      walletBackfill: WalletBackfill.byName(json['walletBackfill']) ?? WalletBackfill.never,
      detectiveName: name is String && name.isNotEmpty ? name : null,
      avatar: DetectiveAvatar.byName(json['avatar']),
      createdAt: created is String ? DateTime.tryParse(created) : null,
    );
  }
}

/// What the device keeps about its detective (`lm.detective.v1`): the one
/// [profile], and the ids of earlier profiles found on the device that are
/// not it ([held]). A held profile's saves stay on the device untouched:
/// never opened, never removed.
@immutable
class DetectiveRecord {
  const DetectiveRecord({required this.profile, this.held = const []});

  static const schema = 1;

  final DetectiveProfile profile;
  final List<String> held;

  DetectiveRecord withProfile(DetectiveProfile next) {
    assert(next.id == profile.id);
    return DetectiveRecord(profile: next, held: held);
  }

  Map<String, dynamic> toJson() => {
        'schema': schema,
        'profile': profile.toJson(),
        if (held.isNotEmpty) 'held': held,
      };

  /// Null when nothing usable is saved.
  static DetectiveRecord? fromJson(Object? json) {
    if (json is! Map) return null;
    final profile = DetectiveProfile.fromJson(json['profile']);
    if (profile == null) return null;
    final held = json['held'];
    return DetectiveRecord(
      profile: profile,
      held: held is List ? [for (final id in held) if (DetectiveProfile.isValidId(id) && id != profile.id) id as String] : const [],
    );
  }
}
