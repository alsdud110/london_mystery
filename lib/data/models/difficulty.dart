/// How hard the English of a season is. Only the English changes with it
/// (story, letters, clues, puzzle lines, hints): the story's facts, the
/// puzzles, their answers, the evidence and the rewards are the same at
/// every level (see `docs/DIFFICULTY_IMPLEMENTATION.md`).
///
/// Saved by [storageId], never by the enum's name or [label]: a stored id
/// never changes once released; the words on screen may.
enum Difficulty {
  rookie('rookie', 'ROOKIE', 'Short English sentences. Easy words and simple clues.'),
  junior('junior', 'JUNIOR', 'Everyday English. Read clues and connect the dots.'),
  master('master', 'MASTER', 'Advanced English. Read carefully and think deeply.');

  const Difficulty(this.storageId, this.label, this.blurb);

  /// The id kept in saves (`lm.detective.v1`, a season's record).
  final String storageId;

  /// The word on screen.
  final String label;

  /// What the level means, in a line, on its card (CHOOSE YOUR LEVEL).
  final String blurb;

  /// The level of a detective (or a season) that never chose one: every
  /// save from before difficulty existed reads as this.
  static const standard = Difficulty.rookie;

  /// The level saved as [id], or null when [id] names none (missing, null,
  /// an unknown or malformed value).
  static Difficulty? tryParse(Object? id) {
    for (final d in values) {
      if (d.storageId == id) return d;
    }
    return null;
  }

  /// The level saved as [id]; anything unreadable is [standard].
  static Difficulty parse(Object? id) => tryParse(id) ?? standard;

  /// Where this level's words are looked for, first to last, before the
  /// game's own words (the base, which is Rookie's): Master falls back on
  /// Junior's words, then the base; Junior and Rookie on the base.
  List<Difficulty> get fallbackChain => switch (this) {
        rookie => const [rookie],
        junior => const [junior],
        master => const [master, junior],
      };
}
