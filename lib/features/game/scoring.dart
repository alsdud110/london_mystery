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
  masterDetective('Master Detective', '에피소드 완료', null, AppColors.goldDeep); // deerstalker

  const GameBadge(this.title, this.description, this.glyph, this.color);

  final String title;
  final String description;
  final InkGlyph? glyph;
  final Color color;

  static GameBadge? byId(String id) {
    for (final b in values) {
      if (b.name == id) return b;
    }
    return null;
  }

  bool isEarned(Episode e, GameProgress p) {
    final solved = e.allMissions.where((m) => p.isCompleted(m.id)).toList();
    return switch (this) {
      GameBadge.firstClue => p.collectedClues(e).isNotEmpty,
      GameBadge.sharpEyes => solved.any((m) => !p.usedHint(m.id)),
      GameBadge.quickThinker => solved.any((m) => XpBreakdown.of(m, p).speedBonus > 0),
      GameBadge.puzzleSolver => solved.length >= 3,
      GameBadge.londonExplorer => p.allMissionsDone(e),
      GameBadge.masterDetective => p.isCaseSolved,
    };
  }
}
