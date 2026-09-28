import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/episode.dart';
import '../../data/models/game_progress.dart';
import '../../data/models/mission.dart';

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
enum GameBadge {
  firstClue('First Clue', '첫 단서 발견', Icons.search_rounded, AppColors.royalBlue),
  sharpEyes('Sharp Eyes', '힌트 없이 미션 해결', Icons.visibility_rounded, Color(0xFF3E9B6A)),
  quickThinker('Quick Thinker', '미션을 빠르게 해결', Icons.bolt_rounded, Color(0xFFE0735A)),
  puzzleSolver('Puzzle Solver', '퍼즐 3개 해결', Icons.extension_rounded, Color(0xFF8A5CC7)),
  londonExplorer('London Explorer', '모든 장소 방문', Icons.map_rounded, Color(0xFF2E8FA3)),
  masterDetective('Master Detective', '에피소드 완료', Icons.emoji_events_rounded, AppColors.goldDeep);

  const GameBadge(this.title, this.description, this.icon, this.color);

  final String title;
  final String description;
  final IconData icon;
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
