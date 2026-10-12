/// App-wide constants: storage keys and scoring rules.
abstract final class AppConstants {
  /// The first case of the season (always open; the default active case).
  static const currentEpisodeId = 'ep01';

  // Local storage keys (versioned so the schema can evolve safely).
  /// Progress of Episode 01. Kept unchanged so saves made before the season
  /// existed still load; later episodes use [progressKeyFor].
  static const progressStorageKey = 'lm.progress.v1';

  /// Which case is open and which cases are solved (see `SeasonProgress`).
  static const seasonStorageKey = 'lm.season.v1';

  /// The detective's coins (see `Wallet`): one wallet for the whole device.
  static const walletStorageKey = 'lm.wallet.v1';

  static String progressKeyFor(String episodeId) =>
      episodeId == currentEpisodeId ? progressStorageKey : '$progressStorageKey.$episodeId';
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
