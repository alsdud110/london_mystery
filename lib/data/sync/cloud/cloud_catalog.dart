import 'package:flutter/foundation.dart';

import '../../../core/constants/app_constants.dart';
import '../../models/episode.dart';

/// The shipped season as the cloud sees it: case ids, each case's missions,
/// each mission's tips and coins. The same lists as the Firestore rules
/// (`missionCoins()`, `episodeIds()`, `caseMissions()`), built from the
/// bundled catalog.
@immutable
class CloudCatalog {
  const CloudCatalog._(this.caseIds, this._missionsOf, this._hints, this._coins);

  factory CloudCatalog.of(List<Episode> season) => CloudCatalog._(
        [for (final e in season) e.id],
        {for (final e in season) e.id: [for (final m in e.allMissions) m.id]},
        {for (final e in season) for (final m in e.allMissions) m.id: m.hints.length},
        {
          for (final e in season)
            for (final m in e.allMissions) m.id: m.isFinal ? AppConstants.finalCoins : AppConstants.missionCoins,
        },
      );

  final List<String> caseIds;
  final Map<String, List<String>> _missionsOf;
  final Map<String, int> _hints;
  final Map<String, int> _coins;

  bool isCase(String id) => _missionsOf.containsKey(id);

  bool isMission(String id) => _coins.containsKey(id);

  /// The missions of case [caseId] (empty for an unknown case).
  List<String> missionsOf(String caseId) => _missionsOf[caseId] ?? const [];

  /// How many tips mission [missionId] has (0 when unknown).
  int hintsOf(String missionId) => _hints[missionId] ?? 0;

  /// The coins mission [missionId] pays, or null for an unknown mission.
  int? coinsOf(String missionId) => _coins[missionId];
}
