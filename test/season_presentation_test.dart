import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:world_mystery/data/models/season.dart';
import 'package:world_mystery/features/mission_map/map_world.dart';
import 'package:world_mystery/features/season/widgets/season_props.dart';
import 'package:world_mystery/widgets/art_assets.dart';

/// A season's map, cover and their framing are registered once each
/// ([SeasonMap.bySeason], [ArtAssets.seasonCovers]); the pages read them
/// from there. London and Paris look as they always did.
void main() {
  test('the maps: London and Paris, each its own; none for an unknown season', () {
    expect(SeasonMap.bySeason.keys, [SeasonIds.london, SeasonIds.paris]);
    expect(SeasonMap.forSeason(SeasonIds.london)!.artwork, ArtAssets.londonMap);
    expect(SeasonMap.forSeason(SeasonIds.paris)!.artwork, ArtAssets.parisMap);
    expect(SeasonMap.forSeason('s9_nowhere'), isNull);
  });

  test('the covers: their pictures and framing as before; none for an unknown season', () {
    final london = ArtAssets.seasonCovers[SeasonIds.london]!;
    expect(london.file, ArtAssets.season1CoverLondonPanorama);
    expect(london.pixels, ArtAssets.season1CoverLondonPanoramaPixels);
    expect((london.archiveLook, london.crop, london.push), (
      const Alignment(0, 0.1),
      const Alignment(0.6, 0),
      const Alignment(0.7, -0.15),
    ));
    final paris = ArtAssets.seasonCovers[SeasonIds.paris]!;
    expect(paris.file, ArtAssets.season2CoverParisPanorama);
    expect(paris.pixels, ArtAssets.season2CoverParisPanoramaPixels);
    expect((paris.archiveLook, paris.crop, paris.push), (
      const Alignment(0.1, -0.25),
      const Alignment(0.3, 0),
      const Alignment(0.2, -0.2),
    ));
    expect(ArtAssets.seasonCovers.keys, [SeasonIds.london, SeasonIds.paris]);
    expect(ArtAssets.seasonCovers['s9_nowhere'], isNull);
  });

  test("the board's map print is the season's own map; London's for a season without one", () {
    final london = MapPrint.ofSeason(SeasonIds.london, strength: 0.62);
    expect((london.file, london.pixels, london.strength), (ArtAssets.londonMap, ArtAssets.londonMapPixels, 0.62));
    final paris = MapPrint.ofSeason(SeasonIds.paris);
    expect((paris.file, paris.pixels), (ArtAssets.parisMap, ArtAssets.parisMapPixels));
    final unknown = MapPrint.ofSeason('s9_nowhere');
    expect((unknown.file, unknown.pixels), (ArtAssets.londonMap, ArtAssets.londonMapPixels));
  });
}
