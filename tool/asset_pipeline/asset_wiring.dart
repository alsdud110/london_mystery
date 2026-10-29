import '../season_gen/plan_ids.dart';
import '../season_gen/plan_models.dart';
import 'asset_plan.dart';

/// Whether the game can show a picture of a generated season, read from
/// the game's code (STEP 3-12A, `lib/` as of 2026-10-29; nothing there is
/// changed by this step).
///
/// * `wired`: the plans already name the file where the game reads it, and
///   the generator writes that into the season's content.
/// * `ready_to_wire`: the game has a place that shows this kind of picture,
///   but nothing names this file there yet: a line in `lib/` (`libEdit`) or
///   a table the generator does not write yet (`generatorExtension`).
/// * `blocked`: the game has such a place, but the picture as planned does
///   not fit it (its shape): plan it again first.
/// * `not_supported`: no screen of the game shows it for a generated season.
enum WiringStatus {
  wired('wired'),
  readyToWire('ready_to_wire'),
  blocked('blocked'),
  notSupported('not_supported');

  const WiringStatus(this.id);

  final String id;
}

/// Where one picture is (or would be) shown.
class Wiring {
  const Wiring({
    required this.asset,
    required this.status,
    required this.screen,
    required this.field,
    this.via,
    this.missions = const [],
    this.note,
  });

  final PipelineAsset asset;
  final WiringStatus status;

  /// The screen that shows it (null: none).
  final String? screen;

  /// The data it is named in, as the game reads it.
  final String? field;

  /// How it gets there: `generator` (already), `libEdit`, `generatorExtension`.
  final String? via;

  /// The missions it is shown in, when the plans say.
  final List<String> missions;
  final String? note;

  Map<String, Object?> toJson() => {
    'assetId': asset.assetId,
    'type': asset.type,
    'subject': asset.subject,
    'caseIds': asset.caseIds,
    'outputPath': asset.outputPath,
    'status': status.id,
    'screen': screen,
    'field': field,
    'via': via,
    if (missions.isNotEmpty) 'missions': missions,
    'note': ?note,
  };
}

abstract final class AssetWiring {
  /// Every picture of [plan], in the manifest's order.
  static List<Wiring> of(AssetPlan plan) => [for (final a in plan.assets) wiringOf(a, plan.season!, plan.cases)];

  /// Where [a] is shown, for [season] and its [cases].
  static Wiring wiringOf(PipelineAsset a, SeasonPlan season, List<CasePlan> cases) {
    final id = season.seasonId;
    switch (a.type) {
      case 'place':
        final place = season.places.where((p) => p.placeId == a.subject).firstOrNull;
        final missions = [for (final c in cases) for (final m in c.allMissions) if (m.placeId == a.subject) m.missionId];
        if (place == null || place.file != a.outputPath || place.width != a.width || place.height != a.height) {
          return Wiring(
            asset: a,
            status: WiringStatus.blocked,
            screen: 'Mission scene',
            field: 'season.plan.json places[${a.subject}]',
            note: 'season.plan.json does not show this file at this size',
          );
        }
        return Wiring(
          asset: a,
          status: WiringStatus.wired,
          screen: 'Mission scene: the place picture of its missions (PlaceArt, LandmarkArt.ofScene, PlaceScenery.scene)',
          field: 'season.plan.json places[${a.subject}].file → SeasonContent.places[\'${a.subject}\'] (ScenePlace); missions name it by sceneKey',
          via: 'generator',
          missions: missions,
          note: 'Shown by the generated content (generate_season.dart); the season itself is not in SeasonCatalog.',
        );
      case 'cover':
        final portrait = a.height > a.width;
        return Wiring(
          asset: a,
          status: portrait ? WiringStatus.readyToWire : WiringStatus.blocked,
          screen: 'World Map season board and the Detective Archives file strip',
          field: 'ArtAssets.seasonCovers[\'$id\'] (SeasonCover: file, pixels, crop, push, archiveLook) in lib/widgets/art_assets.dart',
          via: 'libEdit',
          note: portrait
              ? 'Not shown yet: one SeasonCover line in lib/ (file, pixels ${a.width}×${a.height}, crop, push, archiveLook chosen on '
                  'the drawn picture). Shown by BoxFit.cover: full screen on the season board, a 2:1 band in the archive, a 56×72 thumbnail.'
              : 'A season cover is a portrait painting (London 941×1672, Paris 941×1671) cropped to the 9:16 board; '
                  'a ${a.width}×${a.height} landscape loses most of itself there. Plan it as 1024×1536 first.',
        );
      case 'map':
        return Wiring(
          asset: a,
          status: WiringStatus.readyToWire,
          screen: 'Mission Map',
          field: 'SeasonMap.bySeason[\'$id\'] (artwork, pixels, aspect, landmarks, caseLandmarks) in lib/features/mission_map/map_world.dart',
          via: 'libEdit',
          note: 'Its landmarks are measured on the drawn map and written in lib/. Without a SeasonMap the season\'s Mission Map shows '
              '"not ready", so a released season needs this one.',
        );
      case 'prologue':
        return Wiring(
          asset: a,
          status: WiringStatus.notSupported,
          screen: null,
          field: null,
          note: 'The season openings\' pictures are written per season in lib/ (ArtAssets.season1LondonNight, season2GareDuNord); '
              'SeasonPrologue (season.plan.json prologue) is words only.',
        );
      case 'scene':
        return Wiring(
          asset: a,
          status: WiringStatus.readyToWire,
          screen: 'Story scene before or after a mission (StorySceneScreen)',
          field: 'SeasonContent.storyScenes[<missionId>] (StoryScenes.place / after / next: StoryPicture)',
          via: 'generatorExtension',
          note: 'The table is a SeasonContent one, but the generator writes no storyScenes yet and the manifest names no mission for it '
              '(cases ${a.caseIds.join(', ')}).',
        );
      case 'character':
        return Wiring(
          asset: a,
          status: WiringStatus.notSupported,
          screen: null,
          field: null,
          note: 'No table the generator writes shows a portrait. Portraits are shown only by Season 1 and 2\'s hand-written talk '
              'scenes (ArtAssets.characters, TalkSpeaker.portraits, DialogueScene speakers), which the plans and the generator do not make.',
        );
      case 'object' || 'document':
        if (PlanIds.evidence.hasMatch(a.subject)) {
          final missions = [for (final c in cases) for (final m in c.allMissions) if (m.clueOutputs.evidence == a.subject) m.missionId];
          return Wiring(
            asset: a,
            status: missions.isEmpty ? WiringStatus.blocked : WiringStatus.readyToWire,
            screen: 'Notebook evidence card and its close look (EvidenceCard)',
            field: 'ArtAssets.evidencePictures[\'${a.subject}\'] in lib/widgets/art_assets.dart (square: the round frame; no evidencePrints entry)',
            via: 'libEdit',
            missions: missions,
            note: missions.isEmpty
                ? 'No mission leaves ${a.subject}.'
                : 'No SeasonContent table holds evidence pictures: a generated season needs one lib/ line per evidence id, '
                    'or an engine table the generator could write.'
                    '${a.caseIds.length > 1 ? ' Planned for cases ${a.caseIds.join(', ')}: only ${a.subject} is named; other evidence ids it stands for are not mapped.' : ''}',
          );
        }
        return Wiring(
          asset: a,
          status: WiringStatus.notSupported,
          screen: null,
          field: null,
          note: '${a.subject} is no evidence id: no screen shows a picture by it.',
        );
    }
    return Wiring(asset: a, status: WiringStatus.notSupported, screen: null, field: null, note: 'type ${a.type}');
  }

  /// The counts by status.
  static Map<String, int> counts(List<Wiring> all) => {
    for (final s in WiringStatus.values) s.id: all.where((w) => w.status == s).length,
  };

  /// What `planning/asset_wiring.json` keeps: the same plans always make the
  /// same file (no time, no machine), for a generator to read back.
  static Map<String, Object?> report(AssetPlan plan) {
    final all = of(plan);
    return {
      'schemaVersion': 1,
      'seasonId': plan.seasonId,
      'tool': 'tool/asset_pipeline/asset_pipeline.dart --wiring --write',
      'checkedAgainst': 'lib/ as of 2026-10-29 (SeasonContent.places, ArtAssets.seasonCovers, SeasonMap.bySeason, '
          'ArtAssets.evidencePictures, SeasonContent.storyScenes)',
      'counts': counts(all),
      'assets': [for (final w in all) w.toJson()],
    };
  }
}
