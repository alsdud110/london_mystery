import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/episode.dart';
import '../../data/models/game_progress.dart';
import '../../data/models/mission.dart';
import '../../widgets/ink_icon.dart';

/// XP earned for one solved mission, split into the parts shown to the player.
///
/// Each solved mission keeps the rule it was solved under
/// (`GameProgress.xpRules`), so changing the rules never changes XP already
/// earned:
/// - rule 1 (missions solved before rules were recorded): base, a bonus for
///   not opening tips, a bonus for speed;
/// - rule 2: base, and a bonus for answering on the first (+50) or second
///   (+25) try. It could not tell a lucky guess from understanding, and paid a
///   detective who misread once and corrected it less than a lucky guess;
/// - rule 3 ([currentRule]): the same XP for everyone who reaches the answer
///   (mission 100, final 200), whatever the wrong answers, tips or time. XP
///   rewards solving the case; it is not a measure of English.
@immutable
class XpBreakdown {
  const XpBreakdown({required this.base, this.noHintBonus = 0, this.speedBonus = 0, this.carefulBonus = 0});

  final int base;

  /// Rule 1 only.
  final int noHintBonus;

  /// Rule 1 only.
  final int speedBonus;

  /// Rule 2 only.
  final int carefulBonus;

  int get total => base + noHintBonus + speedBonus + carefulBonus;

  /// The rule recorded for missions solved from now on.
  static const currentRule = 3;

  static XpBreakdown of(Mission m, GameProgress p) {
    final base = m.isFinal ? AppConstants.finalBaseXp : AppConstants.missionBaseXp;
    final rule = p.xpRules[m.id] ?? 1;
    if (rule >= 3) return XpBreakdown(base: base);
    if (rule == 2) {
      return XpBreakdown(
        base: base,
        carefulBonus: switch (p.wrongCount(m.id)) {
          0 => AppConstants.firstTryBonusXp,
          1 => AppConstants.secondTryBonusXp,
          _ => 0,
        },
      );
    }
    final hints = p.hintsFor(m.id);
    final seconds = p.solveSeconds[m.id];
    final fastLimit = m.isFinal ? AppConstants.fastFinalSeconds : AppConstants.fastMissionSeconds;
    return XpBreakdown(
      base: base,
      noHintBonus: switch (hints) {
        0 => AppConstants.noHintBonusXp,
        1 => AppConstants.oneHintBonusXp,
        _ => 0,
      },
      speedBonus: seconds != null && seconds <= fastLimit ? AppConstants.speedBonusXp : 0,
    );
  }

  /// Total XP for everything solved so far.
  static int totalFor(Episode e, GameProgress p) => e.allMissions
      .where((m) => p.isCompleted(m.id))
      .fold(0, (sum, m) => sum + XpBreakdown.of(m, p).total);
}

/// Achievements shown in the notebook and on the case report.
///
/// Badges reward solving the case and real detective actions (each one
/// recorded by a UI event, see `BehaviorLog`). None of them measures English,
/// and none adds XP. Ids are saved by [name]: never rename or remove one.
///
/// Each badge's [glyph] is drawn by the Ink Icon System (a badge without
/// one would show the title's initial as a stand-in).
enum GameBadge {
  firstClue('First Clue', '첫 단서 발견', InkGlyph.search, AppColors.royalBlue),
  // Retired: no longer awarded (a first-try or fast answer cannot be told
  // from a lucky guess). Kept so saved badges still load and show; the
  // description is true of every way they were once earned.
  sharpEyes('Sharp Eyes', '이전 버전에서 미션을 해결하며 받은 배지', InkGlyph.eye, AppColors.success, retired: true),
  quickThinker('Quick Thinker', '이전 버전에서 미션을 빠르게 해결하며 받은 배지', InkGlyph.stopwatch, AppColors.burgundy,
      retired: true),
  puzzleSolver('Puzzle Solver', '퍼즐 3개 해결', InkGlyph.puzzle, AppColors.navy),
  londonExplorer('London Explorer', '모든 장소 방문', InkGlyph.pin, AppColors.inkBrown),
  masterDetective('Master Detective', '에피소드 완료', InkGlyph.deerstalker, AppColors.goldDeep),

  // Case badges: earned by closing one case of the season. Each is shown
  // only in its own case, next to the shared badges.
  clockWatcher('Clock Watcher', '멈춘 시계의 비밀 해결', InkGlyph.clock, AppColors.royalBlue, episodeId: 'ep02'),
  evidenceHunter('Evidence Hunter', '작은 단서로 범인 추적', InkGlyph.footprint, AppColors.burgundy, episodeId: 'ep03'),
  letterReader('Letter Reader', '비밀 편지 사건 해결', InkGlyph.letter, AppColors.inkBrown, episodeId: 'ep04'),
  codeBreaker('Code Breaker', '잠긴 방의 암호 해제', InkGlyph.key, AppColors.navy, episodeId: 'ep05'),
  mapMaster('Map Master', '잃어버린 지도 완성', InkGlyph.map, AppColors.success, episodeId: 'ep07'),
  londonLegend('London Legend', '시즌 1 마지막 사건 해결', InkGlyph.raven, AppColors.goldDeep, episodeId: 'ep12'),

  // Detective action badges: optional, earned by recorded actions only.
  secondLook('Second Look', '막혔을 때 편지나 증거를 다시 확인하고 해결', InkGlyph.letter, AppColors.burgundy),
  notebookExplorer('Notebook Explorer', '수첩이나 사건 기록의 증거를 자세히 살펴봄', InkGlyph.notebook, AppColors.navy),
  wordCollector('Word Collector', '모르는 단어 3개의 뜻을 스스로 찾아봄', InkGlyph.pen, AppColors.inkBrown);

  const GameBadge(this.title, this.description, this.glyph, this.color, {this.episodeId, this.retired = false});

  final String title;
  final String description;
  final InkGlyph? glyph;
  final Color color;

  /// The case this badge belongs to; null for badges every case can give.
  final String? episodeId;

  /// No longer awarded; shown only where it was already earned.
  final bool retired;

  bool get isCaseBadge => episodeId != null;

  /// Distinct looked-up words for [wordCollector].
  static const wordCollectorWords = 3;

  static GameBadge? byId(String id) {
    for (final b in values) {
      if (b.name == id) return b;
    }
    return null;
  }

  /// The badges a case can still give: the shared ones, then its own case
  /// badge (retired badges are never given again).
  static List<GameBadge> forEpisode(Episode e) => [
        for (final b in values) if (!b.retired && b.episodeId == null) b,
        for (final b in values) if (!b.retired && b.episodeId == e.id) b,
      ];

  /// The badges shown for a case: those it can give, and any retired badge
  /// the save already holds.
  static List<GameBadge> shownFor(Episode e, List<String> earnedIds) => [
        for (final b in values) if (b.retired && earnedIds.contains(b.name)) b,
        ...forEpisode(e),
      ];

  /// Whether [p] earns this badge now. It only decides new awards: badges
  /// already earned stay in `GameProgress.badgeIds`.
  bool isEarned(Episode e, GameProgress p) {
    if (retired) return false;
    if (episodeId != null) return episodeId == e.id && p.isCaseSolved;
    final solved = e.allMissions.where((m) => p.isCompleted(m.id)).toList();
    final log = p.behavior; // null: actions not recorded in this run
    return switch (this) {
      GameBadge.firstClue => p.collectedClues(e).isNotEmpty,
      GameBadge.puzzleSolver => solved.length >= 3,
      GameBadge.londonExplorer => p.allMissionsDone(e),
      GameBadge.masterDetective => p.isCaseSolved,
      // A wrong answer, then the letter re-read or evidence opened, then the
      // same mission solved (the log only takes a recheck after a wrong
      // answer and before the solve).
      GameBadge.secondLook =>
        log != null && solved.any((m) => log.rechecked.contains(m.id) && p.wrongCount(m.id) > 0),
      GameBadge.notebookExplorer => log != null && log.evidenceViewed.isNotEmpty,
      GameBadge.wordCollector => log != null && log.words.length >= wordCollectorWords,
      _ => false, // case badges are handled above
    };
  }
}
