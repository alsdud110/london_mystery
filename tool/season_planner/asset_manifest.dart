import 'dart:io';

import '../ai_agents/image_pricing.dart';
import '../ai_agents/image_styles.dart';
import '../season_gen/plan_ids.dart';
import '../season_gen/plan_models.dart';
import 'finding.dart';

/// A season's pictures, planned with its story (STEP 3-11):
/// `content_pipeline/seasons/<seasonId>/assets.manifest.json`.
///
/// Every picture the season will need, with the prompt it is to be made
/// with, its style, its size and where it goes in `assets/`. Nothing here is
/// made: a picture is `planned` until a later step makes it with
/// `tool/ai_agents` and marks it `generated`. A planned picture's file is
/// never on disk, and no other season's picture stands in for it.
///
/// ```json
/// {
///   "schemaVersion": 1, "seasonId": "s3_rome", "assetRoot": "assets/seasons/season_03_rome",
///   "model": "gpt-image-2", "quality": "medium",
///   "seasonStyles": [{"id": "rome_scene", "kind": "scene", "size": "1536x1024", "background": "opaque", "text": "Style: ..."}],
///   "assets": [{
///     "assetId": "s3_rome.asset.trevi_fountain", "type": "place", "use": "seasonPlace",
///     "subject": "s3_rome.trevi_fountain", "caseIds": ["s3_ep02"], "description": "...", "prompt": "...",
///     "stylePreset": "rome_scene", "width": 1536, "height": 1024, "transparent": false,
///     "outputPath": "assets/seasons/season_03_rome/locations/trevi_fountain.png",
///     "references": [], "status": "planned"
///   }]
/// }
/// ```
abstract final class AssetManifest {
  static const fileName = 'assets.manifest.json';
  static const schemaVersion = 1;

  /// `place` is a season place's picture (`season.plan.json` `places`), the
  /// one kind the generator puts in the game today. The others are planned
  /// for the pages that show them (covers, portraits, evidence art).
  static const types = {'cover', 'map', 'prologue', 'place', 'scene', 'character', 'object', 'document'};

  /// `seasonPlace`: the generated content shows it (its place's picture).
  /// `notWired`: no generated table shows it yet (a later step's).
  static const uses = {'seasonPlace', 'notWired'};
  static const statuses = {'planned', 'generated'};

  /// The sizes the GPT image models make without resizing, which are the
  /// game's own (`tool/ai_agents/STYLE_GUIDE.md`).
  static const sizes = {'1536x1024', '1024x1536', '1024x1024'};

  /// The style kind each type is drawn in.
  static const kindOf = {
    'cover': 'scene',
    'map': 'scene',
    'prologue': 'scene',
    'place': 'scene',
    'scene': 'scene',
    'character': 'character',
    'object': 'object',
    'document': 'object',
  };

  static const _fields = {
    'assetId', 'type', 'use', 'subject', 'pose', 'caseIds', 'description', 'prompt', 'stylePreset', //
    'width', 'height', 'transparent', 'outputPath', 'references', 'status', 'notes',
  };
  static const _topFields = {'schemaVersion', 'seasonId', 'assetRoot', 'model', 'quality', 'seasonStyles', 'assets', 'notes'};
  static const _styleFields = {'id', 'kind', 'size', 'background', 'text'};

  /// `assets/seasons/season_03_rome` for season 3 in Rome.
  static String rootFor(int number, String seasonId) =>
      'assets/seasons/season_${number.toString().padLeft(2, '0')}_${seasonId.substring(seasonId.indexOf('_') + 1)}';

  /// Checks the manifest [json] against its [season] and [cases] (the
  /// places and the evidence the pictures are of). [root]: the repository,
  /// where generated pictures are looked for. Adds its findings to [out]
  /// and returns the summary the quality report keeps.
  static Map<String, Object?> check(Object? json, SeasonPlan season, List<CasePlan> cases, Findings out, {String root = '.'}) {
    const where = AssetManifest.fileName;
    void error(String code, String at, String m) => out.error(code, '$where $at', m, source: Source.assets);
    void warning(String code, String at, String m) => out.warning(code, '$where $at', m, source: Source.assets);
    void info(String code, String at, String m) => out.info(code, '$where $at', m, source: Source.assets);

    if (json is! Map) {
      error('asset_manifest_invalid', r'$', 'not a JSON object');
      return const {};
    }
    for (final k in json.keys) {
      if (!_topFields.contains(k)) error('asset_field_unknown', '\$.$k', 'not a field of the manifest');
    }
    if (json['schemaVersion'] != schemaVersion) error('asset_manifest_invalid', r'$.schemaVersion', 'must be $schemaVersion');
    if (json['seasonId'] != season.seasonId) error('asset_manifest_invalid', r'$.seasonId', '${json['seasonId']}, not ${season.seasonId}');
    final assetRoot = rootFor(season.number, season.seasonId);
    if (json['assetRoot'] != assetRoot) error('asset_path_invalid', r'$.assetRoot', '${json['assetRoot']}: the season\'s pictures go under $assetRoot');
    final model = json['model'] is String ? json['model'] as String : 'gpt-image-2';
    final quality = json['quality'] is String ? json['quality'] as String : 'medium';
    if (ImagePricing.ratesOf(model) == null) warning('asset_model_unpriced', r'$.model', '$model has no list price in image_pricing.dart: no estimate');

    // The season's own styles: a city's look, on the game's common lines.
    final styles = <String, ({String kind, String size, String text})>{
      for (final s in ImageStyles.all.values) s.id: (kind: s.kind, size: s.size, text: s.text),
    };
    final seasonStyles = json['seasonStyles'] is List ? json['seasonStyles'] as List : const [];
    for (final (i, s) in seasonStyles.indexed) {
      final at = '\$.seasonStyles[$i]';
      if (s is! Map || s['id'] is! String || s['text'] is! String || s['kind'] is! String || s['size'] is! String) {
        error('asset_style_invalid', at, 'a style is {id, kind, size, background, text}');
        continue;
      }
      for (final k in s.keys) {
        if (!_styleFields.contains(k)) error('asset_field_unknown', '$at.$k', 'not a field of a style');
      }
      final id = s['id'] as String;
      if (styles.containsKey(id)) error('asset_style_invalid', '$at.id', '$id is already a style (image_styles.dart, or given twice)');
      if (!{'scene', 'character', 'object'}.contains(s['kind'])) error('asset_style_invalid', '$at.kind', '${s['kind']} (scene, character, object)');
      if (!sizes.contains(s['size'])) error('asset_size_unsupported', '$at.size', '${s['size']} (${sizes.join(', ')})');
      styles[id] = (kind: s['kind'] as String, size: s['size'] as String, text: s['text'] as String);
    }

    final list = json['assets'];
    if (list is! List || list.isEmpty) {
      error('asset_manifest_invalid', r'$.assets', 'no picture planned');
      return const {};
    }

    // What the plans name, for the pictures to be of.
    final caseIds = season.caseIds.toSet();
    final charIds = {for (final c in season.characters) c.charId};
    final placeFiles = {for (final p in season.places) p.placeId: p};
    final evidenceIds = {for (final c in cases) for (final m in c.allMissions) m.clueOutputs.evidence};
    final placeCases = <String, Set<String>>{};
    for (final c in cases) {
      for (final m in c.allMissions) {
        (placeCases[m.placeId] ??= {}).add(c.caseId);
      }
    }

    final ids = <String, int>{};
    final paths = <String, String>{};
    final byPlace = <String, String>{};
    final bases = <String, String>{};
    final poses = <(String, String, List<String>, String)>[];
    final counts = <String, int>{};
    var reused = 0, pending = 0, generated = 0;
    var cost = 0.0;
    var priced = true;

    for (final (i, a) in list.indexed) {
      final at = '\$.assets[$i]';
      if (a is! Map) {
        error('asset_invalid', at, 'not an object');
        continue;
      }
      for (final k in a.keys) {
        if (!_fields.contains(k)) error('asset_field_unknown', '$at.$k', 'not a field of an asset');
      }
      String? str(String key, {bool required = true}) {
        final v = a[key];
        if (v is String && v.trim().isNotEmpty) return v;
        if (required || v != null) error('asset_field_missing', '$at.$key', 'missing or empty');
        return null;
      }

      final id = str('assetId');
      final label = id ?? at;
      if (id != null) {
        if (!PlanIds.asset.hasMatch(id) || PlanIds.seasonOfScoped(id) != season.seasonId) {
          error('asset_id_invalid', '$at.assetId', '$id is not an asset id of ${season.seasonId} (${season.seasonId}.asset.<name>)');
        }
        if (ids.containsKey(id)) error('asset_id_duplicate', '$at.assetId', '$id is also \$.assets[${ids[id]}]');
        ids[id] = i;
      }
      final type = str('type');
      if (type != null && !types.contains(type)) error('asset_type_invalid', '$at.type', '$type (${types.join(', ')})');
      final use = str('use');
      if (use != null && !uses.contains(use)) error('asset_field_invalid', '$at.use', '$use (${uses.join(', ')})');
      if (use == 'seasonPlace' && type != 'place') error('asset_field_invalid', '$at.use', 'seasonPlace is a place\'s picture only');
      if (type == 'place' && use != 'seasonPlace') error('asset_field_invalid', '$at.use', 'a place\'s picture is shown as a season place (seasonPlace)');
      counts[type ?? '?'] = (counts[type ?? '?'] ?? 0) + 1;
      final subject = str('subject');
      str('description');
      final prompt = str('prompt');
      if (prompt != null && prompt.length > 32000) error('asset_prompt_invalid', '$at.prompt', '${prompt.length} characters (at most 32000)');

      // Its cases.
      final cs = a['caseIds'];
      final assetCases = <String>{};
      if (cs is! List || cs.isEmpty && type != 'cover' && type != 'map' && type != 'prologue') {
        error('asset_field_missing', '$at.caseIds', 'the cases it is shown in');
      } else {
        for (final (j, c) in cs.indexed) {
          if (c is! String || !caseIds.contains(c)) {
            error('asset_case_unknown', '$at.caseIds[$j]', '$c is not a case of ${season.seasonId}');
          } else if (!assetCases.add(c)) {
            error('asset_field_invalid', '$at.caseIds[$j]', '$c given twice');
          }
        }
      }
      if (assetCases.length > 1) reused++;

      // Its style and size.
      final style = str('stylePreset');
      final w = a['width'], h = a['height'];
      final size = '${w}x$h';
      if (w is! int || h is! int) {
        error('asset_size_unsupported', '$at.width', 'width and height are whole pixels');
      } else if (!sizes.contains(size)) {
        error('asset_size_unsupported', '$at.width', '$size (${sizes.join(', ')}: the image models\' and the game\'s sizes)');
      }
      if (style != null) {
        final s = styles[style];
        if (s == null) {
          error('asset_style_unknown', '$at.stylePreset', '$style is not a style (${styles.keys.join(', ')})');
        } else {
          final want = kindOf[type];
          if (want != null && s.kind != want) error('asset_style_mismatch', '$at.stylePreset', '$style draws ${s.kind}s, a $type is drawn as a $want');
          if (sizes.contains(size) && size != s.size) warning('asset_size_unusual', '$at.width', '$size, $style is made at ${s.size}');
          if (prompt != null && sizes.contains(size)) {
            final usd = ImagePricing.estimate(model: model, size: size, quality: quality, prompt: '$prompt\n\n${s.text}');
            if (usd == null) {
              priced = false;
            } else {
              cost += usd;
            }
          }
        }
      }
      final transparent = a['transparent'];
      if (transparent is! bool) {
        error('asset_field_missing', '$at.transparent', 'true or false');
      } else if (transparent) {
        warning('asset_transparency_unchecked', '$at.transparent', 'whether gpt-image-2 makes transparent pictures is not checked yet (tool/ai_agents)');
      }

      // Where it goes.
      final path = str('outputPath');
      if (path != null) {
        if (!PlanIds.assetFile.hasMatch(path) || !path.endsWith('.png')) {
          error('asset_path_invalid', '$at.outputPath', '$path is not a .png under assets/');
        } else if (!path.startsWith('$assetRoot/')) {
          error('asset_path_invalid', '$at.outputPath', '$path is not under $assetRoot/ (no other season\'s folder)');
        }
        if (paths.containsKey(path)) error('asset_path_duplicate', '$at.outputPath', '$path is also ${paths[path]}\'s');
        paths[path] = label;
      }
      final status = str('status');
      if (status != null && !statuses.contains(status)) error('asset_field_invalid', '$at.status', '$status (${statuses.join(', ')})');
      final onDisk = path != null && File('$root/$path').existsSync();
      if (status == 'generated') {
        generated++;
        if (!onDisk) error('asset_file_missing', '$at.status', 'generated, but $path is not on disk');
      } else if (status == 'planned') {
        pending++;
        if (onDisk) warning('asset_status_stale', '$at.status', 'planned, but $path is on disk: mark it generated once checked');
      }

      // Its references: earlier pictures of the same subject to draw from.
      final refs = a['references'];
      final references = <String>[];
      if (refs is! List) {
        error('asset_field_missing', '$at.references', 'a list (empty when it is drawn from nothing)');
      } else {
        for (final r in refs) {
          if (r is String) references.add(r);
        }
      }

      // What it is of.
      switch (type) {
        case 'place':
          if (subject != null) {
            final p = placeFiles[subject];
            if (p == null) {
              error('asset_place_unknown', '$at.subject', '$subject is not a place of season.plan.json (places)');
            } else {
              if (byPlace.containsKey(subject)) error('asset_id_duplicate', '$at.subject', '$subject has two pictures (${byPlace[subject]})');
              byPlace[subject] = label;
              if (path != null && path != p.file) error('asset_path_mismatch', '$at.outputPath', '$path, but season.plan.json shows $subject from ${p.file}');
              if (w is int && h is int && (w != p.width || h != p.height)) {
                error('asset_path_mismatch', '$at.width', '${w}x$h, but season.plan.json gives $subject ${p.width}x${p.height}');
              }
              final used = placeCases[subject] ?? const <String>{};
              if (used.isEmpty) {
                warning('asset_unused', '$at.subject', 'no mission is played at $subject');
              } else if (!(used.containsAll(assetCases) && assetCases.containsAll(used))) {
                warning('asset_cases_mismatch', '$at.caseIds', '${assetCases.join(', ')}, but its missions are in ${used.join(', ')}');
              }
            }
          }
        case 'character':
          final pose = a['pose'];
          if (subject != null && !charIds.contains(subject)) error('asset_character_unknown', '$at.subject', '$subject is not a character of season.plan.json');
          if (pose is! String || pose.isEmpty) {
            error('asset_field_missing', '$at.pose', 'base, or the pose it shows');
          } else if (subject != null && id != null) {
            if (pose == 'base') {
              if (bases.containsKey(subject)) error('asset_id_duplicate', '$at.pose', '$subject has two base portraits');
              bases[subject] = id;
              if (references.isNotEmpty) warning('asset_reference_unneeded', '$at.references', 'a base portrait is the one others are drawn from');
            } else {
              poses.add((subject, id, references, at));
            }
          }
        case 'object' || 'document':
          if (subject != null && !evidenceIds.contains(subject) && !subject.startsWith('${season.seasonId}.')) {
            error('asset_evidence_unknown', '$at.subject', '$subject is no evidence of the cases (an _e id) nor a ${season.seasonId}. subject');
          }
      }
      if (type != 'character' && a.containsKey('pose')) error('asset_field_invalid', '$at.pose', 'only a character has poses');
    }

    // References: known, earlier pictures; a character's other poses drawn from its base.
    for (final (i, a) in list.indexed) {
      if (a is! Map || a['references'] is! List) continue;
      for (final (j, r) in (a['references'] as List).indexed) {
        if (r is! String || !ids.containsKey(r)) {
          error('asset_reference_unknown', '\$.assets[$i].references[$j]', '$r is not an asset of the manifest');
        } else if (r == a['assetId']) {
          error('asset_reference_unknown', '\$.assets[$i].references[$j]', 'a picture drawn from itself');
        }
      }
    }
    for (final (char, id, refs, at) in poses) {
      final base = bases[char];
      if (base == null) {
        error('asset_reference_missing', '$at.subject', '$id is a pose of $char, who has no base portrait');
      } else if (!refs.contains(base)) {
        error('asset_reference_missing', '$at.references', '$id is a pose of $char: drawn from $base, so the face stays the same');
      }
    }

    // Every place shown, every character drawn, a cover.
    for (final p in season.places) {
      if (!byPlace.containsKey(p.placeId)) error('asset_place_missing', p.placeId, 'season.plan.json shows ${p.file}, but no picture is planned for it');
    }
    for (final c in season.characters) {
      if (!bases.containsKey(c.charId)) warning('asset_portrait_missing', c.charId, 'no base portrait planned for ${c.name}');
    }
    if ((counts['cover'] ?? 0) == 0) warning('asset_cover_missing', r'$.assets', 'no season cover planned');
    if (pending > 0) {
      info('asset_pending', r'$.assets', '$pending of ${list.length} pictures planned, not made yet (no API was called)');
    }

    return {
      'total': list.length,
      'byType': {for (final t in types) if (counts.containsKey(t)) t: counts[t]},
      'backgrounds': [for (final t in ['place', 'scene', 'cover', 'map', 'prologue']) counts[t] ?? 0].fold<int>(0, (s, n) => s + n),
      'characters': counts['character'] ?? 0,
      'objects': (counts['object'] ?? 0) + (counts['document'] ?? 0),
      'reusedAcrossCases': reused,
      'planned': pending,
      'generated': generated,
      'shownBySeasonPlaces': byPlace.length,
      'model': model,
      'quality': quality,
      'estimatedUsd': priced ? ImagePricing.round(cost) : null,
      'estimateNote': 'List prices of ${ImagePricing.checkedOn} (image_pricing.dart), an estimate before any call; nothing was sent.',
    };
  }
}
