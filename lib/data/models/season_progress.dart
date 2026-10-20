import 'package:flutter/foundation.dart';

import '../../core/constants/app_constants.dart';

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
  });

  final String activeEpisodeId;

  /// Solved case ids, in the order they were first solved.
  final List<String> solvedEpisodeIds;

  /// The season's opening has been watched to its first case's file (Season
  /// 2's: its board shows from then on, never the opening again).
  final bool prologueSeen;

  static const empty = SeasonProgress();

  bool isSolved(String episodeId) => solvedEpisodeIds.contains(episodeId);

  SeasonProgress copyWith({String? activeEpisodeId, List<String>? solvedEpisodeIds, bool? prologueSeen}) =>
      SeasonProgress(
        activeEpisodeId: activeEpisodeId ?? this.activeEpisodeId,
        solvedEpisodeIds: solvedEpisodeIds ?? this.solvedEpisodeIds,
        prologueSeen: prologueSeen ?? this.prologueSeen,
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
    );
  }

  Map<String, dynamic> toJson() => {
        'activeEpisodeId': activeEpisodeId,
        'solvedEpisodeIds': solvedEpisodeIds,
        if (prologueSeen) 'prologueSeen': true,
      };
}
