import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';
import 'difficulty.dart';

/// Season-level record kept next to the per-case [GameProgress] saves:
/// which case file is open, and which cases were ever solved.
///
/// "Solved" is remembered here (not read from the case save) so that playing
/// a case again never locks the cases after it.
@immutable
class SeasonProgress {
  const SeasonProgress({
    this.activeEpisodeId = AppConstants.currentEpisodeId,
    this.solvedEpisodeIds = const [],
    this.prologueSeen = false,
    this.difficulty,
    this.nextLevelAsked = false,
  });

  final String activeEpisodeId;

  /// Solved case ids, in the order they were first solved.
  final List<String> solvedEpisodeIds;

  /// The season's opening has been watched to its first case's file (Season
  /// 2's: its board shows from then on, never the opening again).
  final bool prologueSeen;

  /// The level this season is played at, fixed for the season; null: not
  /// fixed yet (a season not started, or saved before difficulty existed),
  /// so the detective's own level applies (see [difficultyOr]).
  final Difficulty? difficulty;

  /// The season is complete and the detective has answered READY FOR YOUR
  /// NEXT MYSTERY? (kept their level or chose one for the next season): the
  /// question is not asked again.
  final bool nextLevelAsked;

  static const empty = SeasonProgress();

  bool isSolved(String episodeId) => solvedEpisodeIds.contains(episodeId);

  /// The level the season is played at: its own, or [profileLevel] (the
  /// detective's) while it has none.
  Difficulty difficultyOr(Difficulty profileLevel) => difficulty ?? profileLevel;

  SeasonProgress copyWith({
    String? activeEpisodeId,
    List<String>? solvedEpisodeIds,
    bool? prologueSeen,
    Difficulty? difficulty,
    bool? nextLevelAsked,
  }) =>
      SeasonProgress(
        activeEpisodeId: activeEpisodeId ?? this.activeEpisodeId,
        solvedEpisodeIds: solvedEpisodeIds ?? this.solvedEpisodeIds,
        prologueSeen: prologueSeen ?? this.prologueSeen,
        difficulty: difficulty ?? this.difficulty,
        nextLevelAsked: nextLevelAsked ?? this.nextLevelAsked,
      );

  /// [episodeId] solved (solving it again changes nothing).
  SeasonProgress markSolved(String episodeId) =>
      isSolved(episodeId) ? this : copyWith(solvedEpisodeIds: [...solvedEpisodeIds, episodeId]);

  /// Tolerant decoding: unknown or malformed fields fall back to defaults.
  factory SeasonProgress.fromJson(Map<String, dynamic> json) {
    final active = json['activeEpisodeId'];
    final solved = json['solvedEpisodeIds'];
    return SeasonProgress(
      activeEpisodeId: active is String && active.isNotEmpty ? active : AppConstants.currentEpisodeId,
      solvedEpisodeIds: solved is List ? solved.whereType<String>().toSet().toList() : const <String>[],
      prologueSeen: json['prologueSeen'] == true,
      // Missing (saved before difficulty) or unreadable: not fixed.
      difficulty: Difficulty.tryParse(json['difficulty']),
      nextLevelAsked: json['nextLevelAsked'] == true,
    );
  }

  /// The level and the question answered are written only once there, so
  /// a record without them keeps its old shape.
  Map<String, dynamic> toJson() => {
        'activeEpisodeId': activeEpisodeId,
        'solvedEpisodeIds': solvedEpisodeIds,
        if (prologueSeen) 'prologueSeen': true,
        if (difficulty != null) 'difficulty': difficulty!.storageId,
        if (nextLevelAsked) 'nextLevelAsked': true,
      };
}
