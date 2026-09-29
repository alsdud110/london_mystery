import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/episode.dart';
import '../../data/models/game_progress.dart';
import '../../data/models/mission.dart';
import '../../widgets/ink_icon.dart';

/// XP earned for one solved mission, split into the parts shown to the player.
@immutable
class XpBreakdown {
  const XpBreakdown({required this.base, required this.noHintBonus, required this.speedBonus});

  final int base;
  final int noHintBonus;
  final int speedBonus;

  int get total => base + noHintBonus + speedBonus;

  static XpBreakdown of(Mission m, GameProgress p) {
    final hints = p.hintsFor(m.id);
    final seconds = p.solveSeconds[m.id];
    final fastLimit = m.isFinal ? AppConstants.fastFinalSeconds : AppConstants.fastMissionSeconds;
    return XpBreakdown(
      base: m.isFinal ? AppConstants.finalBaseXp : AppConstants.missionBaseXp,
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
/// [glyph] is null while the badge's drawing is a Custom Asset Required
/// (the medal shows the title's initial until then).
enum GameBadge {
  firstClue('First Clue', '첫 단서 발견', InkGlyph.search, AppColors.royalBlue),
  sharpEyes('Sharp Eyes', '힌트 없이 미션 해결', null, AppColors.success), // eye
  quickThinker('Quick Thinker', '미션을 빠르게 해결', null, AppColors.burgundy), // stopwatch
  puzzleSolver('Puzzle Solver', '퍼즐 3개 해결', null, AppColors.navy), // puzzle piece
  londonExplorer('London Explorer', '모든 장소 방문', InkGlyph.pin, AppColors.inkBrown),
  masterDetective('Master Detective', '에피소드 완료', null, AppColors.goldDeep), // deerstalker

  // Case badges: earned by closing one case of the season. Each is shown
  // only in its own case, next to the six badges above.
  clockWatcher('Clock Watcher', '멈춘 시계의 비밀 해결', InkGlyph.clock, AppColors.royalBlue, episodeId: 'ep02'),
  evidenceHunter('Evidence Hunter', '작은 단서로 범인 추적', InkGlyph.footprint, AppColors.burgundy, episodeId: 'ep03'),
  letterReader('Letter Reader', '비밀 편지 해독', InkGlyph.letter, AppColors.inkBrown, episodeId: 'ep04'),
  codeBreaker('Code Breaker', '잠긴 방의 암호 해제', InkGlyph.key, AppColors.navy, episodeId: 'ep05'),
  mapMaster('Map Master', '잃어버린 지도 완성', InkGlyph.map, AppColors.success, episodeId: 'ep07'),
  londonLegend('London Legend', '시즌 1 마지막 사건 해결', InkGlyph.raven, AppColors.goldDeep, episodeId: 'ep12');

  const GameBadge(this.title, this.description, this.glyph, this.color, {this.episodeId});

  final String title;
  final String description;
  final InkGlyph? glyph;
  final Color color;

  /// The case this badge belongs to; null for badges every case can give.
  final String? episodeId;

  bool get isCaseBadge => episodeId != null;

  static GameBadge? byId(String id) {
    for (final b in values) {
      if (b.name == id) return b;
    }
    return null;
  }

  /// The badges a case can give: the shared ones plus its own case badge.
  static List<GameBadge> forEpisode(Episode e) =>
      [for (final b in values) if (b.episodeId == null || b.episodeId == e.id) b];

  bool isEarned(Episode e, GameProgress p) {
    if (episodeId != null) return episodeId == e.id && p.isCaseSolved;
    final solved = e.allMissions.where((m) => p.isCompleted(m.id)).toList();
    return switch (this) {
      GameBadge.firstClue => p.collectedClues(e).isNotEmpty,
      GameBadge.sharpEyes => solved.any((m) => !p.usedHint(m.id)),
      GameBadge.quickThinker => solved.any((m) => XpBreakdown.of(m, p).speedBonus > 0),
      GameBadge.puzzleSolver => solved.length >= 3,
      GameBadge.londonExplorer => p.allMissionsDone(e),
      GameBadge.masterDetective => p.isCaseSolved,
      _ => false, // case badges are handled above
    };
  }
}
