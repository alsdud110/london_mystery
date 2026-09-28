/// App-wide constants: storage keys and scoring rules.
abstract final class AppConstants {
  static const currentEpisodeId = 'ep01';

  // Local storage keys (versioned so the schema can evolve safely).
  static const progressStorageKey = 'lm.progress.v1';
  static const soundEnabledKey = 'lm.settings.sound';

  // Detective name rules.
  static const nameMinLength = 1;
  static const nameMaxLength = 12;

  // Hints per mission.
  static const maxHints = 2;

  // XP rules (see XpBreakdown).
  static const missionBaseXp = 100;
  static const finalBaseXp = 200;
  static const noHintBonusXp = 50;
  static const oneHintBonusXp = 25; // one hint halves the bonus, two remove it
  static const speedBonusXp = 20;
  static const fastMissionSeconds = 120;
  static const fastFinalSeconds = 180;
}
