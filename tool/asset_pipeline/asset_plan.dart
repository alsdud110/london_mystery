import 'dart:convert';
import 'dart:io';

import '../ai_agents/image_manifest.dart';
import '../ai_agents/image_pricing.dart';
import '../ai_agents/image_styles.dart';
import '../ai_agents/openai_image.dart';
import '../season_gen/generate_case.dart' show GenerateFailure;
import '../season_gen/plan_files.dart';
import '../season_gen/plan_models.dart';
import '../season_gen/season_cases.dart';
import '../season_planner/asset_manifest.dart';
import '../season_planner/finding.dart';
import 'asset_budget.dart';
import 'asset_scheduler.dart';
import 'asset_transform.dart';

/// One picture of a season's `assets.manifest.json`, as the pipeline makes it.
class PipelineAsset {
  const PipelineAsset({
    required this.index,
    required this.assetId,
    required this.type,
    required this.use,
    required this.subject,
    required this.pose,
    required this.caseIds,
    required this.description,
    required this.prompt,
    required this.stylePreset,
    required this.width,
    required this.height,
    required this.transparent,
    required this.outputPath,
    required this.references,
    required this.status,
  });

  /// Its place in the manifest's list.
  final int index;
  final String assetId, type, use, subject, description, prompt, stylePreset, outputPath, status;
  final String? pose;
  final List<String> caseIds;
  final int width, height;
  final bool transparent;

  /// The asset ids it is drawn from.
  final List<String> references;

  String get size => '${width}x$height';

  /// Read from a manifest entry the manifest's check has passed.
  static PipelineAsset fromJson(int index, Map j) => PipelineAsset(
    index: index,
    assetId: j['assetId'] as String,
    type: j['type'] as String,
    use: j['use'] as String,
    subject: j['subject'] as String,
    pose: j['pose'] as String?,
    caseIds: (j['caseIds'] as List).cast<String>(),
    description: j['description'] as String,
    prompt: j['prompt'] as String,
    stylePreset: j['stylePreset'] as String,
    width: j['width'] as int,
    height: j['height'] as int,
    transparent: j['transparent'] as bool,
    outputPath: j['outputPath'] as String,
    references: (j['references'] as List).cast<String>(),
    status: j['status'] as String,
  );
}

/// A season's manifest read, checked and scheduled: what the pipeline would
/// make, in which order, at what cost. Reading it writes nothing.
class AssetPlan {
  AssetPlan._({
    required this.manifestPath,
    required this.seasonDir,
    required this.findings,
    this.season,
    this.cases = const [],
    this.seasonId = '?',
    this.assetRoot = '',
    this.model = 'gpt-image-2',
    this.quality = 'medium',
    this.styles = const {},
    this.assets = const [],
    this.schedule,
  });

  /// The line a prompt drawn from reference pictures gets, before its style.
  static const referenceLine =
      'Keep the look of the reference picture(s): the same person, place or object, with the same face, clothes, shapes and colours, '
      'drawn in the same style.';

  /// gpt-image-2's pixel limits (the image generation guide, 2026-10-29).
  static const minPixels = 655360;
  static const maxPixels = 8294400;

  /// The qualities a model takes (API reference): `xhigh` and `max` only on
  /// the 2.5 models; `auto` never here, its cost cannot be estimated.
  static Set<String> qualitiesOf(String model) =>
      model.startsWith('gpt-image-2.5-') ? const {'low', 'medium', 'high', 'xhigh', 'max'} : const {'low', 'medium', 'high'};

  /// `background: transparent`: the 2.5 models only (gpt-image-2's is a preview).
  static bool transparentOf(String model) => model.startsWith('gpt-image-2.5-');

  final String manifestPath;
  final String seasonDir;
  final Findings findings;
  final SeasonPlan? season;
  final List<CasePlan> cases;
  final String seasonId;
  final String assetRoot;
  final String model;
  final String quality;
  final Map<String, ImageStyle> styles;
  final List<PipelineAsset> assets;
  final AssetSchedule? schedule;

  bool get ok => findings.count(Level.error) == 0;
  List<Finding> get errors => findings.all.where((f) => f.isError).toList();

  PipelineAsset asset(String id) => assets.firstWhere((a) => a.assetId == id);

  /// The manifest at [manifestPath] (beside its `season.plan.json` and
  /// `cases/`), checked as the planner checks it (`AssetManifest.check`)
  /// and then for what making it needs: a priced model, its qualities, its
  /// pixel limits, references without a loop, requests the image tool takes.
  static AssetPlan load(String manifestPath, {String root = '.'}) {
    final path = manifestPath.replaceAll(r'\', '/');
    final seasonDir = File(path).parent.path.replaceAll(r'\', '/');
    final out = Findings();
    void error(String code, String where, String m) => out.error(code, where, m, source: Source.assets);
    AssetPlan bare() => AssetPlan._(manifestPath: path, seasonDir: seasonDir, findings: out);

    final Object? json;
    try {
      json = jsonDecode(File('$root/$path').readAsStringSync());
    } on FileSystemException catch (e) {
      error('manifest_missing', path, e.message);
      return bare();
    } on FormatException catch (e) {
      error('manifest_invalid', path, 'not JSON: ${e.message}');
      return bare();
    }
    final seasonPath = '$root/$seasonDir/season.plan.json';
    final SeasonPlan season;
    final List<CasePlan> cases;
    try {
      season = PlanFiles.loadSeasonPlan(seasonPath);
      cases = [for (final p in SeasonCases.of(seasonPath)) PlanFiles.loadCasePlan(p)];
    } on PlanFormatException catch (e) {
      error('plan_invalid', e.path, e.message);
      return bare();
    } on GenerateFailure catch (e) {
      error('plan_invalid', seasonDir, e.lines.join('; '));
      return bare();
    } on FileSystemException catch (e) {
      error('plan_missing', seasonDir, e.message);
      return bare();
    }

    // The planner's own check: ids, types, paths, sizes, styles, places and
    // their case plans, references that exist.
    AssetManifest.check(json, season, cases, out, root: root);
    if (out.count(Level.error) > 0 || json is! Map) return AssetPlan._(manifestPath: path, seasonDir: seasonDir, findings: out, season: season, cases: cases);

    final model = json['model'] as String? ?? 'gpt-image-2';
    final quality = json['quality'] as String? ?? 'medium';
    final styles = <String, ImageStyle>{
      ...ImageStyles.all,
      for (final s in (json['seasonStyles'] as List? ?? const []).cast<Map>())
        s['id'] as String: ImageStyle(
          id: s['id'] as String,
          kind: s['kind'] as String,
          size: s['size'] as String,
          background: s['background'] as String? ?? 'opaque',
          text: s['text'] as String,
        ),
    };
    final assets = [for (final (i, a) in (json['assets'] as List).indexed) PipelineAsset.fromJson(i, a as Map)];

    if (ImagePricing.ratesOf(model) == null) error('model_unpriced', r'$.model', '$model has no list price (image_pricing.dart): never made automatically');
    if (!qualitiesOf(model).contains(quality)) error('quality_unsupported', r'$.quality', '$quality (${qualitiesOf(model).join(', ')} for $model)');

    final studio = ImageStudio(api: _NoApi(), findKey: () => null, root: root);
    for (final a in assets) {
      final at = '${AssetManifest.fileName} \$.assets[${a.index}] ${a.assetId}';
      final pixels = a.width * a.height;
      if (pixels < minPixels || pixels > maxPixels) error('size_unsupported', at, '${a.size}: $pixels pixels (gpt-image-2: $minPixels to $maxPixels)');
      if (a.references.length > ImageStudio.maxReferences) error('references_too_many', at, '${a.references.length} references (at most ${ImageStudio.maxReferences})');
      if (a.transparent && !transparentOf(model)) error('transparent_unsupported', at, 'a transparent background is a preview on $model: not made automatically');
      if (a.references.toSet().length != a.references.length) error('reference_duplicate', at, 'a reference given twice');
      // The request as the image tool will check it (its references apart:
      // they are made by the pipeline before it).
      final req = _request(a, styles, model, quality, raw: rawPathFor(seasonIdOf(json), assetRootOf(json), a), refFiles: const []);
      for (final p in studio.problems(req)) {
        error('request_invalid', at, p);
      }
    }

    final schedule = AssetScheduler.of([for (final a in assets) a.assetId], {for (final a in assets) a.assetId: a.references});
    if (schedule.cycle case final c?) error('reference_cycle', AssetManifest.fileName, 'references go round: ${c.join(' → ')}');

    return AssetPlan._(
      manifestPath: path,
      seasonDir: seasonDir,
      findings: out,
      season: season,
      cases: cases,
      seasonId: seasonIdOf(json),
      assetRoot: assetRootOf(json),
      model: model,
      quality: quality,
      styles: styles,
      assets: assets,
      schedule: schedule,
    );
  }

  static String seasonIdOf(Map json) => json['seasonId'] as String;
  static String assetRootOf(Map json) => json['assetRoot'] as String;

  /// Where a season's pipeline keeps its pictures and records: never in
  /// `assets/` (the game's) or `lib/` (the app).
  static String workDirFor(String seasonId) => 'content_pipeline/asset_work/$seasonId';

  /// The API's picture of [a]: `<work>/raw/<its path under the season's asset root>`.
  static String rawPathFor(String seasonId, String assetRoot, PipelineAsset a, {String? work}) =>
      '${work ?? workDirFor(seasonId)}/raw/${a.outputPath.substring(assetRoot.length + 1)}';

  /// [a]'s picture at the game's size when it had to be changed:
  /// `<work>/game/<its path under the season's asset root>`.
  static String gamePathFor(String seasonId, String assetRoot, PipelineAsset a, {String? work}) =>
      '${work ?? workDirFor(seasonId)}/game/${a.outputPath.substring(assetRoot.length + 1)}';

  String rawPath(PipelineAsset a, {String? work}) => rawPathFor(seasonId, assetRoot, a, work: work);
  String gamePath(PipelineAsset a, {String? work}) => gamePathFor(seasonId, assetRoot, a, work: work);

  /// The size [a] is asked of the API at: its own (the manifest holds only
  /// the sizes the API makes, `AssetManifest.sizes`).
  String apiSize(PipelineAsset a) => a.size;

  /// How the API's picture of [a] becomes the game's.
  static CropAnchor anchorOf(PipelineAsset a) => a.type == 'character' ? CropAnchor.top : CropAnchor.center;

  /// The request for [a], drawn from [refFiles] (its references' pictures,
  /// in its order), written at [raw].
  ImageRequest request(PipelineAsset a, {required String raw, List<String> refFiles = const []}) =>
      _request(a, styles, model, quality, raw: raw, refFiles: refFiles);

  static ImageRequest _request(PipelineAsset a, Map<String, ImageStyle> styles, String model, String quality,
      {required String raw, required List<String> refFiles}) {
    final style = styles[a.stylePreset]!;
    final prompt = [a.prompt.trim(), if (a.references.isNotEmpty) referenceLine, style.text].join('\n\n');
    return ImageRequest(
      prompt: prompt,
      output: raw,
      model: model,
      size: a.size,
      quality: quality,
      background: a.transparent ? 'transparent' : style.background,
      styleId: style.id,
      subjectId: a.subject,
      references: refFiles,
    );
  }

  /// The cost of [a] (its references priced as inputs).
  AssetCost costOf(PipelineAsset a) => AssetBudget.cost(
    model: model,
    size: apiSize(a),
    quality: quality,
    prompt: _request(a, styles, model, quality, raw: 'x.png', refFiles: const []).prompt,
    references: a.references.length,
  )!;
}

/// Never called: an image studio used only to check requests.
class _NoApi implements ImageApi {
  @override
  Future<ApiImage> generate(Map<String, Object?> body, key) => throw StateError('no API');
}
