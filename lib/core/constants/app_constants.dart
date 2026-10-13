/// App-wide constants: storage keys and scoring rules.
abstract final class AppConstants {
  /// The first case of the season (always open; the default active case).
  static const currentEpisodeId = 'ep01';

  // Local storage keys (versioned so the schema can evolve safely). These are
  // the keys of the saves made before profiles; each profile keeps the same
  // saves under its own namespace (see [profileKey]).
  /// Progress of Episode 01. Kept unchanged so saves made before the season
  /// existed still load; later episodes use [progressKeyFor].
  static const progressStorageKey = 'lm.progress.v1';

  /// Which case is open and which cases are solved (see `SeasonProgress`).
  static const seasonStorageKey = 'lm.season.v1';

  /// The detective's coins (see `Wallet`): one wallet per profile.
  static const walletStorageKey = 'lm.wallet.v1';

  /// The key a case was saved under before profiles existed. A profile keeps
  /// the same key under its namespace (see [profileKey]).
  static String progressKeyFor(String episodeId) =>
      episodeId == currentEpisodeId ? progressStorageKey : '$progressStorageKey.$episodeId';

  /// Whether [key] is one of the saves made before profiles existed (kept on
  /// the device as the original after they are copied to the guest profile).
  static bool isLegacySaveKey(String key) =>
      key == progressStorageKey ||
      key.startsWith('$progressStorageKey.') ||
      key == seasonStorageKey ||
      key == walletStorageKey;

  /// The detectives of this device and which one plays (see `ProfileRegistry`).
  static const profilesStorageKey = 'lm.profiles.v1';

  /// The record of copying the saves made before profiles to the guest profile.
  static const legacyMigrationKey = 'lm.migration.legacy.v1';

  /// Every save of a profile starts with this.
  static String profilePrefix(String profileId) => 'lm.p.$profileId.';

  /// A profile's own key for the save kept under [legacyKey] before profiles
  /// existed: `lm.progress.v1.ep02` → `lm.p.<profileId>.progress.v1.ep02`.
  static String profileKey(String profileId, String legacyKey) {
    assert(legacyKey.startsWith('lm.'));
    return '${profilePrefix(profileId)}${legacyKey.substring('lm.'.length)}';
  }

  /// Set when a profile in safe mode starts over: the originals it was
  /// reading are no longer its saves (they are not removed).
  static String legacyClearedKey(String profileId) => '${profilePrefix(profileId)}legacy.cleared';

  /// A profile's save in progress (see `SaveJournal`): present only between
  /// the first and last write of a save of several keys.
  static String journalKey(String profileId) => '${profilePrefix(profileId)}journal.v1';

  /// A profile's changes waiting to be synced (see `Outbox`).
  static String outboxKey(String profileId) => '${profilePrefix(profileId)}outbox.v1';

  /// A profile's sync conflicts kept for a later decision (see `ConflictStore`).
  static String conflictsKey(String profileId) => '${profilePrefix(profileId)}conflicts.v1';

  /// A profile's reset epoch (see `SharedPrefsProgressRepository.epoch`).
  static String metaKey(String profileId) => '${profilePrefix(profileId)}meta.v1';

  /// A profile's cloud sync bookkeeping: confirmed cloudVersions, failures,
  /// back-off (see `CloudSyncMeta`). Separate from every game save.
  static String cloudSyncKey(String profileId) => '${profilePrefix(profileId)}cloud.v1';

  /// This installation of the app (see `ProfileStore.installId`).
  static const deviceStorageKey = 'lm.device.v1';

  /// Device setting (shared by every profile).
  static const soundEnabledKey = 'lm.settings.sound';

  // Detective name rules.
  static const nameMinLength = 1;
  static const nameMaxLength = 12;

  // Hints per mission.
  static const maxHints = 2;

  // XP rules (see XpBreakdown).
  // Rule 4 (current): the same XP for every solve, smaller numbers.
  static const missionXp = 30;
  static const finalXp = 60;

  // Rules 1-3 (kept for missions solved under them).
  static const missionBaseXp = 100;
  static const finalBaseXp = 200;

  // Rule 2: tips are free; a careful answer (first or second try) earns more.
  static const firstTryBonusXp = 50;
  static const secondTryBonusXp = 25;

  // Rule 1 (kept for missions solved under it).
  static const noHintBonusXp = 50;
  static const oneHintBonusXp = 25; // one hint halves the bonus, two remove it
  static const speedBonusXp = 20;
  static const fastMissionSeconds = 120;
  static const fastFinalSeconds = 180;

  // Coins (see `Wallet`): earned by solving, spent on Detective Tips. Every
  // price and reward lives here.
  /// Each mission pays once, ever (a case played again pays nothing more).
  static const missionCoins = 30;
  static const finalCoins = 60;

  /// Given once, when the wallet is made, so the first paid tip is in reach.
  static const startCoins = 20;

  /// Price of tip 1 and tip 2 of a mission. Tip 1 is always free; a tip the
  /// detective cannot pay for is given free too, so no one is ever stuck.
  static const tipPrices = [0, 20];
}
