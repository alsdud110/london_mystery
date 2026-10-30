import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:world_mystery/data/mock/season_catalog.dart';
import 'package:world_mystery/data/models/episode.dart';
import 'package:world_mystery/features/game/game_providers.dart';

import 'generated/s3_rome_slice/s3_rome_cases.g.dart';
import 'generated/s3_rome_slice/s3_rome_season.g.dart';

/// Rome's first playable case (STEP 3-15A): Case 05 as
/// `tool/season_gen/generate_case.dart --slice` made it of
/// `content_pipeline/seasons/s3_rome/`, its pictures the asset pipeline's.
/// Since the Rome integration the season itself is in the game
/// (`SeasonCatalog.all`, `lib/data/generated/s3_rome/`): the slice's files
/// are kept as what `--slice` makes, and it is played as the game's.
const romeSliceSeasonId = 's3_rome';

/// The slice as the game's validator checks a season. Not a constant: its
/// talks are not.
final romeSliceContent = SeasonContent(
  info: s3RomeInfoJson,
  episodes: s3RomeEpisodes,
  places: s3RomePlaces,
  released: false,
  storyGreeting: s3RomeStoryGreeting,
  learning: s3RomeLearning,
  languageTopics: s3RomeLanguageTopics,
  evidenceLinks: s3RomeEvidenceLinks,
  explores: s3RomeExplores,
  investigations: s3RomeInvestigations,
  dialogues: s3RomeDialogues,
  talkMissions: s3RomeTalkMissions,
  discoveries: s3RomeDiscoveries,
  endings: s3RomeEndings,
);

/// Its cases as the game reads them.
List<Episode> romeSliceEpisodes() => [for (final json in romeSliceContent.episodes.values) Episode.fromJson(json)];

/// The app as the game is (Rome in it): operator tools on, so a test build
/// may open Case 05 directly (`seasonPreviewSwitchProvider`).
List<Override> romeSliceOverrides() => [operatorToolsAvailableProvider.overrideWithValue(true)];
