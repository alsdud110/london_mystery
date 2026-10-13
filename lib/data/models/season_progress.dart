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
    this.playtestEpisodeIds = const [],
  });

  final String activeEpisodeId;

  /// Solved case ids, in the order they were first solved.
  final List<String> solvedEpisodeIds;

  /// Solved cases whose solve is operator (playtest) data: marked solved by
  /// the operator tools, or solved while only operator access had opened
  /// them. They play like any solved case; they are never synced to a live
  /// cloud. A later normal solve makes the case an ordinary solved case.
  final List<String> playtestEpisodeIds;

  static const empty = SeasonProgress();

  bool isSolved(String episodeId) => solvedEpisodeIds.contains(episodeId);

  SeasonProgress copyWith({String? activeEpisodeId, List<String>? solvedEpisodeIds, List<String>? playtestEpisodeIds}) =>
      SeasonProgress(
        activeEpisodeId: activeEpisodeId ?? this.activeEpisodeId,
        solvedEpisodeIds: solvedEpisodeIds ?? this.solvedEpisodeIds,
        playtestEpisodeIds: playtestEpisodeIds ?? this.playtestEpisodeIds,
      );

  /// [episodeId] solved. A [playtest] solve of a case not solved yet is
  /// recorded as operator data; a normal solve clears that record.
  SeasonProgress markSolved(String episodeId, {bool playtest = false}) {
    if (!isSolved(episodeId)) {
      return copyWith(
        solvedEpisodeIds: [...solvedEpisodeIds, episodeId],
        playtestEpisodeIds: playtest ? [...playtestEpisodeIds, episodeId] : null,
      );
    }
    if (!playtest && playtestEpisodeIds.contains(episodeId)) {
      return copyWith(playtestEpisodeIds: [for (final id in playtestEpisodeIds) if (id != episodeId) id]);
    }
    return this;
  }

  /// Tolerant decoding: unknown or malformed fields fall back to defaults.
  factory SeasonProgress.fromJson(Map<String, dynamic> json) {
    final active = json['activeEpisodeId'];
    final solved = json['solvedEpisodeIds'];
    final solvedIds = solved is List ? solved.whereType<String>().toSet().toList() : const <String>[];
    final playtest = json['playtestEpisodeIds'];
    return SeasonProgress(
      activeEpisodeId: active is String && active.isNotEmpty ? active : AppConstants.currentEpisodeId,
      solvedEpisodeIds: solvedIds,
      playtestEpisodeIds:
          playtest is List ? playtest.whereType<String>().where(solvedIds.contains).toSet().toList() : const [],
    );
  }

  /// Written only when there is operator data, so older saves keep their shape.
  Map<String, dynamic> toJson() => {
        'activeEpisodeId': activeEpisodeId,
        'solvedEpisodeIds': solvedEpisodeIds,
        if (playtestEpisodeIds.isNotEmpty) 'playtestEpisodeIds': playtestEpisodeIds,
      };
}
