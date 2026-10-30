import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/data/models/season.dart' show SeasonIds;
import 'package:world_mystery/features/game/game_providers.dart';

/// Rome, Season 3 (the Rome integration): the twelve cases of
/// `content_pipeline/seasons/s3_rome/`, made by the season's own path
/// (`plan_season.dart generate --target game`) into
/// `lib/data/generated/s3_rome/`, and in the game (`SeasonCatalog.all`).
/// The tests play it as the game has it; nothing is added for them.
const romeSeasonId = SeasonIds.rome;

/// The season as the game has it.
final romeContent = SeasonCatalog.byId(romeSeasonId)!;

/// Its cases as the game reads them, in play order.
List<Episode> romeEpisodes() => [for (final json in romeContent.episodes.values) Episode.fromJson({...json, 'seasonId': romeSeasonId})];

/// The app as it is, its operator tools on: a test build may open a case
/// directly (`seasonPreviewSwitchProvider`, operator access).
List<Override> romeOverrides() => [operatorToolsAvailableProvider.overrideWithValue(true)];
