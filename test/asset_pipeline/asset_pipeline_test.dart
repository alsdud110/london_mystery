import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

import '../../tool/ai_agents/env_file.dart';
import '../../tool/ai_agents/image_manifest.dart';
import '../../tool/ai_agents/image_pricing.dart';
import '../../tool/ai_agents/image_styles.dart';
import '../../tool/ai_agents/openai_image.dart';
import '../../tool/ai_agents/png_check.dart';
import '../../tool/asset_pipeline/asset_budget.dart';
import '../../tool/asset_pipeline/asset_pipeline.dart';
import '../../tool/asset_pipeline/asset_plan.dart';
import '../../tool/asset_pipeline/asset_scheduler.dart';
import '../../tool/asset_pipeline/asset_state.dart';
import '../../tool/asset_pipeline/asset_transform.dart';
import '../../tool/asset_pipeline/asset_wiring.dart';
import '../../tool/season_gen/plan_files.dart';
import '../../tool/season_planner/asset_manifest.dart';
import '../../tool/season_planner/finding.dart';

/// STEP 3-12A: the asset pipeline with no call to OpenAI. A fake API answers;
/// the Rome trial season's manifest is the input, copied to a temporary
/// folder whenever anything could be written.
void main() {
  const seasonDir = 'content_pipeline/seasons/s3_rome';
  const manifest = '$seasonDir/assets.manifest.json';
  const fakeKey = 'sk-test-0123456789abcdefSECRET';

  group('the order', () {
    test('references first, otherwise the manifest\'s order; the same input, the same order', () {
      final ids = ['pose', 'scene', 'base', 'place', 'solo'];
      final refs = {
        'pose': ['base'],
        'scene': ['pose', 'place'],
      };
      final s = AssetScheduler.of(ids, refs);
      expect(s.cycle, isNull);
      expect(s.order, ['base', 'pose', 'place', 'scene', 'solo']);
      expect(s.levels, {'base': 0, 'pose': 1, 'place': 0, 'scene': 2, 'solo': 0});
      expect(AssetScheduler.of(ids, refs).order, s.order);
    });

    test('a loop of references is refused, and named', () {
      final s = AssetScheduler.of(['a', 'b', 'c'], {
        'a': ['c'],
        'b': ['a'],
        'c': ['b'],
      });
      expect(s.order, isEmpty);
      expect(s.cycle!.first, s.cycle!.last);
      expect(s.cycle!.toSet(), {'a', 'b', 'c'});
      expect(AssetScheduler.of(['a'], {
        'a': ['a'],
      }).cycle, ['a', 'a']);
    });
  });

  group('the budget', () {
    test('a call refused past the call limit or the budget; usage spent, else the conservative cost', () {
      final b = AssetBudget(maxUsd: 0.20, maxCalls: 2);
      expect(b.refusal(0.10), isNull);
      b.charge(conservativeUsd: 0.10, fromUsageUsd: 0.04);
      expect(b.spentUsd, closeTo(0.04, 1e-12));
      expect(b.refusal(0.17), contains('--max-budget'));
      b.charge(conservativeUsd: 0.10);
      expect(b.spentUsd, closeTo(0.14, 1e-12));
      expect(b.refusal(0.01), contains('--max-calls'));
    });

    test('the conservative cost is half as much again; a reference priced as image input; no price, no cost', () {
      final plain = AssetBudget.cost(model: 'gpt-image-2', size: '1024x1536', quality: 'medium', prompt: 'x' * 400)!;
      final drawn = AssetBudget.cost(model: 'gpt-image-2', size: '1024x1536', quality: 'medium', prompt: 'x' * 400, references: 2)!;
      expect(plain.conservativeUsd, closeTo(plain.estimatedUsd * 1.5, 1e-6));
      expect(drawn.estimatedUsd - plain.estimatedUsd, closeTo(2 * ImagePricing.referenceImageTokens * 8 / 1e6, 1e-6));
      expect(AssetBudget.cost(model: 'gpt-image-9', size: '1024x1024', quality: 'low', prompt: 'x'), isNull);
    });
  });

  group('fitting to the game\'s size', () {
    test('the same size: nothing to do; a 2:3 portrait to the game\'s 4:5 portrait: enlarged a little, the head kept', () {
      expect(AssetTransform.plan(1536, 1024, 1536, 1024).needed, isFalse);
      final p = AssetTransform.plan(1024, 1536, 1122, 1402, anchor: CropAnchor.top);
      expect(p.problems, isEmpty);
      expect(p.scale, closeTo(1122 / 1024, 1e-9));
      expect(p.cropped, closeTo(1 - 1402 / (1536 * 1122 / 1024), 1e-6));
    });

    test('refused: enlarged too much, or too much of it cropped', () {
      expect(AssetTransform.plan(1024, 1024, 1536, 1536).problems.single, contains('enlarged'));
      expect(AssetTransform.plan(1536, 1024, 1024, 1024).problems.single, contains('cropped away'));
    });

    test('made: exactly the size, transparency kept, the original bytes untouched', () {
      final src = img.Image(width: 64, height: 96, numChannels: 4);
      for (final p in src) {
        p
          ..r = 200
          ..g = 100
          ..b = 50
          ..a = p.y < 48 ? 255 : 0;
      }
      final png = img.encodePng(src);
      final before = Uint8List.fromList(png);
      final out = AssetTransform.apply(png, AssetTransform.plan(64, 96, 70, 88, anchor: CropAnchor.top));
      final info = PngCheck.bytes(out);
      expect((info.width, info.height, info.hasAlpha), (70, 88, true));
      final back = img.decodePng(out)!;
      expect(back.getPixel(35, 5).a, 255);
      expect(back.getPixel(35, 85).a, 0, reason: 'transparent stays transparent');
      expect(png, before);
    });
  });

  group('reference pictures (images/edits)', () {
    late Directory tmp;
    setUp(() => tmp = Directory.systemTemp.createTempSync('asset_refs'));
    tearDown(() => tmp.deleteSync(recursive: true));

    test('the JSON body: the generation\'s fields and each reference as a PNG data URL, nothing the API does not list', () {
      File('${tmp.path}/qa/ref.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(_png(16, 16));
      const r = ImageRequest(prompt: 'p', output: 'qa/out.png', size: '1024x1024', references: ['qa/ref.png']);
      final body = r.editBody(tmp.path);
      expect(body.keys.toSet(), {'model', 'prompt', 'n', 'size', 'quality', 'output_format', 'images'});
      expect(body['images'], [
        {'image_url': 'data:image/png;base64,${base64Encode(_png(16, 16))}'},
      ]);
      expect(jsonEncode(r.editBodyShown), isNot(contains(base64Encode(_png(16, 16)))));
      expect(r.keyIn(tmp.path), isNot(r.key), reason: 'the reference\'s bytes shape the picture');
    });

    test('a reference checked whole before sending: missing, damaged, too many, no edits API', () {
      File('${tmp.path}/qa/bad.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(utf8.encode('not a png'));
      final api = _FakeApi();
      final studio = ImageStudio(api: api, editApi: api, findKey: () => null, root: tmp.path);
      ImageRequest req(List<String> refs) => ImageRequest(prompt: 'p', output: 'qa/out.png', references: refs);
      expect(studio.problems(req(['qa/none.png'])), [contains('not on disk')]);
      expect(studio.problems(req(['qa/bad.png'])), [contains('not a valid PNG')]);
      expect(studio.problems(req([for (var i = 0; i < 17; i++) 'qa/r$i.png'])), contains(contains('at most 16')));
      expect(ImageStudio(api: api, findKey: () => null, root: tmp.path).problems(req(['qa/bad.png'])), contains(contains('not made yet')));
    });

    test('sent to the edits endpoint, recorded as such', () async {
      File('${tmp.path}/qa/ref.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(_png(16, 16));
      final api = _FakeApi();
      final studio = ImageStudio(
        api: api,
        editApi: api,
        findKey: () => ApiKey.find(envPath: 'none', environment: {'OPENAI_API_KEY': fakeKey}),
        root: tmp.path,
        log: (_) {},
      );
      const r = ImageRequest(prompt: 'p', output: 'qa/out.png', size: '1024x1024', references: ['qa/ref.png']);
      expect(await studio.run(r, generate: true), 0);
      expect((api.calls, api.edits), (1, 1));
      final ledger = ImageManifest.load('${tmp.path}/qa/image_manifest.json');
      expect(ledger.entries.single['endpoint'], 'images/edits');
      expect((ledger.entries.single['cost'] as Map)['estimatedUsd'], greaterThan(ImagePricing.referenceImageTokens * 8 / 1e6));
    });
  });

  test('the Rome style: the game\'s ink and watercolour, Rome\'s light, the common lines, London and Paris as they were', () {
    final rome = ImageStyles.all['rome_scene']!;
    expect((rome.kind, rome.size, rome.background), ('scene', '1536x1024', 'opaque'));
    expect(rome.text, contains('pen line drawing'));
    expect(rome.text, contains('watercolour'));
    expect(rome.text, contains('No text'));
    expect(rome.text, isNot(contains('postcard')), reason: 'London\'s frame stays London\'s');
    expect(ImageStyles.all['london_scene']!.text, contains('framed like an old postcard'));
    expect(ImageStyles.all['paris_scene']!.text, contains('impressionist oil painting'));
  });

  group('a manifest refused whole', () {
    late Directory tmp;
    late _FakeApi api;
    setUp(() {
      tmp = _copySeason(seasonDir);
      api = _FakeApi();
    });
    tearDown(() => tmp.deleteSync(recursive: true));

    Future<List<String>> refusedWith(void Function(Map json) change) async {
      final f = File('${tmp.path}/$manifest');
      final json = jsonDecode(File(manifest).readAsStringSync()) as Map; // each change on the original
      change(json);
      f.writeAsStringSync(jsonEncode(json));
      final plan = AssetPlan.load(manifest, root: tmp.path);
      final log = <String>[];
      final code = await _pipeline(plan, api, tmp.path, log, fakeKey).run(generate: true, maxBudget: 10, maxCalls: 50);
      expect(code, 2);
      expect(api.calls, 0, reason: 'nothing is made from a manifest with an error');
      expect(Directory('${tmp.path}/content_pipeline/asset_work').existsSync(), isFalse);
      return [for (final e in plan.errors) e.code];
    }

    List assets(Map j) => j['assets'] as List;
    Map asset(Map j, String id) => assets(j).cast<Map>().singleWhere((a) => a['assetId'] == 's3_rome.asset.$id');

    test('an id twice', () async {
      expect(await refusedWith((j) => asset(j, 'ev_gold_tiles')['assetId'] = 's3_rome.asset.ev_owl_mosaic'), contains('asset_id_duplicate'));
    });
    test('a field missing', () async {
      expect(await refusedWith((j) => asset(j, 'ev_gold_tiles').remove('prompt')), contains('asset_field_missing'));
    });
    test('a path twice, or out of the season\'s folder', () async {
      expect(await refusedWith((j) => asset(j, 'ev_gold_tiles')['outputPath'] = asset(j, 'ev_owl_mosaic')['outputPath']), contains('asset_path_duplicate'));
      expect(await refusedWith((j) => asset(j, 'ev_gold_tiles')['outputPath'] = 'assets/seasons/season_02_paris/x.png'), contains('asset_path_invalid'));
    });
    test('a size the API does not make, a quality or a model it cannot price, a style that is not one', () async {
      expect(await refusedWith((j) => asset(j, 'ev_gold_tiles')['width'] = 1000), contains('asset_size_unsupported'));
      expect(await refusedWith((j) => j['quality'] = 'max'), contains('quality_unsupported'));
      expect(await refusedWith((j) => j['model'] = 'gpt-image-9'), contains('model_unpriced'));
      expect(await refusedWith((j) => asset(j, 'ev_gold_tiles')['stylePreset'] = 'tokyo_scene'), contains('asset_style_unknown'));
    });
    test('a reference to no asset, and references that go round', () async {
      expect(await refusedWith((j) => asset(j, 'ev_gold_tiles')['references'] = ['s3_rome.asset.nothing']), contains('asset_reference_unknown'));
      expect(await refusedWith((j) => asset(j, 'ev_real_piece')['references'] = ['s3_rome.asset.ev_plaster_copy']), contains('reference_cycle'));
    });
    test('a place\'s picture away from the file its case plans show', () async {
      expect(await refusedWith((j) => asset(j, 'trevi_fountain')['outputPath'] = 'assets/seasons/season_03_rome/locations/trevi.png'),
          contains('asset_path_mismatch'));
    });
  });

  group('making a season (fake API)', () {
    late Directory tmp;
    late _FakeApi api;
    late List<String> log;
    late AssetPlan plan;
    setUp(() {
      tmp = _copySeason(seasonDir);
      api = _FakeApi();
      log = [];
      plan = AssetPlan.load(manifest, root: tmp.path);
      expect(plan.ok, isTrue, reason: plan.errors.join('\n'));
    });
    tearDown(() => tmp.deleteSync(recursive: true));

    const work = 'content_pipeline/asset_work/s3_rome';
    AssetPipeline pipeline({String? key = fakeKey}) => _pipeline(plan, api, tmp.path, log, key);
    PipelineState state() => PipelineState.load('${tmp.path}/$work/pipeline_state.json', 's3_rome');
    String all() => log.join('\n');
    const base = 's3_rome.asset.char_livia_base', hood = 's3_rome.asset.char_livia_hood';

    test('a dry run: no call, no file', () async {
      expect(await pipeline().run(), 0);
      expect(api.calls, 0);
      expect(Directory('${tmp.path}/content_pipeline/asset_work').existsSync(), isFalse);
      expect(all(), contains('dry run  nothing sent'));
    });

    test('--generate without a budget, without a key, or with too many calls: refused before any call', () async {
      expect(await pipeline().run(generate: true), 2);
      expect(all(), contains('needs --max-budget'));
      expect(await pipeline(key: null).run(generate: true, maxBudget: 1), 2);
      expect(await pipeline().run(generate: true, maxBudget: 1, maxCalls: 51), 2);
      expect(api.calls, 0);
    });

    test('planned calls past the budget: refused whole, nothing sent', () async {
      expect(await pipeline().run(generate: true, maxBudget: 0.10, maxCalls: 3), 2);
      expect(all(), contains('pass --max-budget'));
      expect(api.calls, 0);
    });

    test('at most --max-calls a run; the next run goes on, never making a picture twice', () async {
      expect(await pipeline().run(generate: true, maxBudget: 1, maxCalls: 2), 0);
      expect(api.calls, 2);
      var s = state();
      expect(s.statusOf('s3_rome.asset.cover'), AssetStatus.validated);
      expect(s.statusOf('s3_rome.asset.city_map'), AssetStatus.validated);
      expect(s.statusOf('s3_rome.asset.prologue'), AssetStatus.planned);
      final raw = File('${tmp.path}/$work/raw/cover/season3_cover_rome.png');
      expect((PngCheck.file(raw.path).width, PngCheck.file(raw.path).height), (1024, 1536), reason: 'the cover is portrait');
      expect(s.of('s3_rome.asset.cover').game!.path, '$work/raw/cover/season3_cover_rome.png', reason: 'the game\'s size already: no copy');

      expect(await pipeline().run(generate: true, maxBudget: 1, maxCalls: 2), 0);
      expect(api.calls, 4);
      s = state();
      expect(s.statusOf('s3_rome.asset.prologue'), AssetStatus.validated);
      expect(s.statusOf('s3_rome.asset.guard_room'), AssetStatus.validated);
      expect(s.runs, hasLength(2));
      expect(s.runs.last['apiCalls'], 2);
      expect(Directory('${tmp.path}/assets').existsSync(), isFalse, reason: 'nothing in assets/');
    });

    test('a pose drawn from its base: the base first, then the pose through images/edits with the base\'s picture', () async {
      expect(await pipeline().run(generate: true, maxBudget: 1, maxCalls: 3, only: {hood}), 0);
      expect(api.calls, 0);
      expect(all(), contains('waiting  $hood'));

      expect(await pipeline().run(generate: true, maxBudget: 1, maxCalls: 3, only: {base, hood}), 0);
      expect((api.calls, api.edits), (2, 1));
      expect(api.bodies.first['prompt'], isNot(contains(AssetPlan.referenceLine)));
      final edit = api.bodies.last;
      expect(edit['prompt'], contains(AssetPlan.referenceLine));
      final sent = base64Decode(((edit['images'] as List).single['image_url'] as String).split(',').last);
      expect(sent, File('${tmp.path}/$work/raw/characters/livia_base.png').readAsBytesSync());
      expect(edit.containsKey('input_fidelity'), isFalse);
      expect(state().statusOf(hood), AssetStatus.validated);
    });

    test('an API error stops the run; the failed picture is the first made by the next run', () async {
      api.failOn = 2;
      expect(await pipeline().run(generate: true, maxBudget: 1, maxCalls: 3), 1);
      expect(api.calls, 2, reason: 'stopped at the error: no third call');
      expect(all(), contains('stop     an API error'));
      var s = state();
      expect(s.statusOf('s3_rome.asset.city_map'), AssetStatus.failed);
      expect(s.of('s3_rome.asset.city_map').error, isNot(contains(fakeKey)));
      expect(s.statusOf('s3_rome.asset.prologue'), AssetStatus.planned);

      api.failOn = null;
      expect(await pipeline().run(generate: true, maxBudget: 1, maxCalls: 1), 0);
      s = state();
      expect(s.statusOf('s3_rome.asset.city_map'), AssetStatus.validated);
      expect(s.of('s3_rome.asset.city_map').attempts, 2);
      expect(s.statusOf('s3_rome.asset.cover'), AssetStatus.validated);
    });

    test('a picture damaged after it was made: never reused, never written over, never sent again by itself', () async {
      expect(await pipeline().run(generate: true, maxBudget: 1, maxCalls: 1), 0);
      final raw = File('${tmp.path}/$work/raw/cover/season3_cover_rome.png');
      final damaged = Uint8List.fromList(raw.readAsBytesSync())..[100] ^= 0xFF;
      raw.writeAsBytesSync(damaged);
      expect(await pipeline().run(generate: true, maxBudget: 1, maxCalls: 1), 0);
      expect(api.calls, 2, reason: 'the next picture, not the damaged one');
      expect(state().statusOf('s3_rome.asset.cover'), AssetStatus.blocked);
      expect(raw.readAsBytesSync(), damaged, reason: 'never written over');
      expect(state().statusOf('s3_rome.asset.city_map'), AssetStatus.validated);
    });

    test('a call left unanswered (the process stopped) is failed, then made again', () async {
      final s = state()..of('s3_rome.asset.cover').status = AssetStatus.generating;
      s.save();
      expect(await pipeline().run(generate: true, maxBudget: 1, maxCalls: 1), 0);
      expect(all(), contains('interrupted during a call'));
      expect(state().statusOf('s3_rome.asset.cover'), AssetStatus.validated);
    });

    test('the API\'s usage spent: a run stops at its budget even under its call limit', () async {
      api.outputTokens = 32000; // ~ $0.96 a picture at list prices
      expect(await pipeline().run(generate: true, maxBudget: 1, maxCalls: 3), 0);
      expect(api.calls, 1);
      expect(all(), contains('would pass the budget'));
    });

    test('an answer of another shape: fitted to the game\'s size beside the original, which is kept', () async {
      api.size = (1024, 1600);
      expect(await pipeline().run(generate: true, maxBudget: 1, maxCalls: 1), 0);
      final r = state().of('s3_rome.asset.cover');
      expect(r.status, AssetStatus.validated);
      expect(r.transformed, isTrue);
      expect((r.raw!.width, r.raw!.height), (1024, 1600));
      expect(r.game!.path, '$work/game/cover/season3_cover_rome.png');
      expect(PngCheck.file('${tmp.path}/${r.game!.path}').height, 1536);
    });

    test('an answer that cannot be fitted: failed, nothing in game/', () async {
      api.size = (1024, 1024);
      expect(await pipeline().run(generate: true, maxBudget: 1, maxCalls: 1), 1);
      expect(state().statusOf('s3_rome.asset.cover'), AssetStatus.failed);
      expect(Directory('${tmp.path}/$work/game').existsSync(), isFalse);
    });

    test('the apply plan writes nothing and says what a later step copies', () async {
      expect(await pipeline().run(generate: true, maxBudget: 1, maxCalls: 1), 0);
      final before = _listing(tmp);
      log.clear();
      expect(pipeline().applyPlan(), 0);
      expect(all(), contains('copy     $work/raw/cover/season3_cover_rome.png → assets/seasons/season_03_rome/cover/season3_cover_rome.png (approval: draft)'));
      expect(all(), contains('assets/seasons/season_03_rome/locations/'));
      expect(_listing(tmp), before);
    });
  });

  group('the Rome manifest (STEP 3-11), whole', () {
    final plan = AssetPlan.load(manifest);

    test('47 pictures read, checked, no error', () {
      expect(plan.ok, isTrue, reason: plan.errors.join('\n'));
      expect(plan.assets, hasLength(47));
      expect(plan.seasonId, 's3_rome');
    });

    test('every reference made before the pictures drawn from it', () {
      final order = plan.schedule!.order;
      expect(order, hasLength(47));
      final drawn = plan.assets.where((a) => a.references.isNotEmpty).toList();
      expect(drawn, hasLength(7));
      expect(drawn.expand((a) => a.references), hasLength(8));
      for (final a in drawn) {
        for (final r in a.references) {
          expect(order.indexOf(r), lessThan(order.indexOf(a.assetId)), reason: '$r before ${a.assetId}');
        }
      }
      expect(plan.schedule!.levels['s3_rome.asset.scene_owl_reveal'], 2);
    });

    test('priced from the list prices, references included, as the planner prices it', () {
      final total = plan.assets.fold<double>(0, (s, a) => s + plan.costOf(a).estimatedUsd);
      final report = jsonDecode(File('$seasonDir/planning/quality_report.json').readAsStringSync()) as Map;
      final planner = ((report['summary'] as Map)['assets'] as Map)['estimatedUsd'] as num;
      expect(total, closeTo(planner, 0.01), reason: 'only the reference line\'s few words apart');
      expect(total, greaterThan(2.0));
    });

    test('the 18 place pictures wired at the files their case plans show; the others by what the game can show', () {
      final wiring = AssetWiring.of(plan);
      final places = wiring.where((w) => w.asset.type == 'place').toList();
      expect(places, hasLength(18));
      expect(places.every((w) => w.status == WiringStatus.wired), isTrue);
      for (final w in places) {
        expect(plan.season!.places.singleWhere((p) => p.placeId == w.asset.subject).file, w.asset.outputPath);
        expect(w.missions, isNotEmpty, reason: w.asset.assetId);
      }
      expect(AssetWiring.counts(wiring), {'wired': 18, 'ready_to_wire': 17, 'blocked': 0, 'not_supported': 12});
      expect(wiring.where((w) => w.asset.type == 'character').every((w) => w.status == WiringStatus.notSupported), isTrue);
      final cover = wiring.singleWhere((w) => w.asset.type == 'cover');
      expect(cover.status, WiringStatus.readyToWire, reason: 'portrait now, but no SeasonCover line in lib/: not wired');
      expect(cover.via, 'libEdit');
      expect(wiring.where((w) => w.status != WiringStatus.wired).every((w) => w.via != 'generator'), isTrue);
    });

    test('the cover: portrait at the API\'s 1024x1536, a safe area in its prompt; a landscape cover is warned of', () {
      final cover = plan.assets.singleWhere((a) => a.type == 'cover');
      expect(cover.size, '1024x1536');
      expect(cover.size, AssetManifest.coverSize);
      expect(cover.prompt, contains('central two-thirds of the width'));
      expect(cover.prompt, contains('upper third is open evening sky'));
      final json = jsonDecode(File(manifest).readAsStringSync()) as Map;
      final c = (json['assets'] as List).cast<Map>().singleWhere((a) => a['type'] == 'cover');
      c['width'] = 1536;
      c['height'] = 1024;
      final out = Findings();
      AssetManifest.check(json, plan.season!, plan.cases, out);
      expect(out.all.where((f) => f.code == 'asset_cover_shape'), hasLength(1));
    });

    test('STEP 3-12B: a place, Livia\'s base, her hood pose drawn from it; refused at \$0.30, never calling another picture', () async {
      const picks = {'s3_rome.asset.forum_view', 's3_rome.asset.char_livia_base', 's3_rome.asset.char_livia_hood'};
      final hood = plan.asset('s3_rome.asset.char_livia_hood');
      expect(hood.references, ['s3_rome.asset.char_livia_base']);
      final order = [for (final id in plan.schedule!.order) if (picks.contains(id)) id];
      expect(order, ['s3_rome.asset.forum_view', 's3_rome.asset.char_livia_base', 's3_rome.asset.char_livia_hood']);
      final conservative = picks.fold<double>(0, (s, id) => s + plan.costOf(plan.asset(id)).conservativeUsd);
      expect(conservative, greaterThan(0.30), reason: 'the reference priced at its assumed upper bound');
      expect(conservative, lessThan(0.32));

      final api = _FakeApi();
      final log = <String>[];
      final p = AssetPipeline(plan: plan, studio: ImageStudio(api: api, editApi: api, findKey: () => null, log: log.add), log: log.add);
      expect(await p.run(only: picks, maxBudget: 0.30, maxCalls: 3), 0);
      expect(log.join('\n'), contains('verdict  REFUSED: over --max-budget \$0.3000'));
      log.clear();
      expect(await p.run(only: picks, maxBudget: 0.32, maxCalls: 3), 0);
      expect(log.join('\n'), contains('verdict  within'));
      expect(api.calls, 0);

      // Generating at $0.30 (a copy of the season): refused whole, nothing sent.
      final tmp = _copySeason(seasonDir);
      addTearDown(() => tmp.deleteSync(recursive: true));
      final copy = AssetPlan.load(manifest, root: tmp.path);
      expect(await _pipeline(copy, api, tmp.path, log, fakeKey).run(generate: true, only: picks, maxBudget: 0.30, maxCalls: 3), 2);
      expect(api.calls, 0);
      // At $0.32: exactly the three, base before hood, the hood through images/edits.
      expect(await _pipeline(copy, api, tmp.path, log, fakeKey).run(generate: true, only: picks, maxBudget: 0.32, maxCalls: 3), 0);
      expect((api.calls, api.edits), (3, 1));
      final state = PipelineState.load('${tmp.path}/content_pipeline/asset_work/s3_rome/pipeline_state.json', 's3_rome');
      expect(state.records.keys.toSet(), picks);
    });

    test('.gitignore: the pipeline\'s pictures out of Git; the plans and the wiring in; .env out', () {
      bool ignored(String path) => Process.runSync('git', ['check-ignore', '-q', '--no-index', path]).exitCode == 0;
      expect(ignored('content_pipeline/asset_work/s3_rome/raw/locations/forum_view.png'), isTrue);
      expect(ignored('content_pipeline/asset_work/s3_rome/pipeline_state.json'), isTrue);
      expect(ignored(manifest), isFalse);
      expect(ignored('$seasonDir/planning/asset_wiring.json'), isFalse);
      expect(ignored('.env'), isTrue);
      expect(Process.runSync('git', ['ls-files', 'content_pipeline/asset_work']).stdout.toString().trim(), isEmpty);
    });

    test('planning/asset_wiring.json is the one the plans make now', () {
      final onDisk = File('$seasonDir/planning/asset_wiring.json').readAsStringSync().replaceAll('\r\n', '\n');
      expect(onDisk, PlanFiles.encode(AssetWiring.report(plan)), reason: 'run: dart run tool/asset_pipeline/asset_pipeline.dart --manifest $manifest --wiring --write');
    });

    test('a dry run on it: no call, no file written anywhere', () async {
      final api = _FakeApi();
      final log = <String>[];
      final before = _listing(Directory('content_pipeline'));
      expect(await AssetPipeline(plan: plan, studio: ImageStudio(api: api, editApi: api, findKey: () => null, log: log.add), log: log.add).run(), 0);
      expect(api.calls, 0);
      expect(_listing(Directory('content_pipeline')), before);
      expect(log.join('\n'), contains('7 drawn from references'));
    });
  });
}

AssetPipeline _pipeline(AssetPlan plan, _FakeApi api, String root, List<String> log, String? key) {
  var clock = DateTime.utc(2026, 10, 29, 9);
  DateTime now() => clock = clock.add(const Duration(seconds: 1));
  final studio = ImageStudio(
    api: api,
    editApi: api,
    findKey: () => key == null ? null : ApiKey.find(envPath: 'none', environment: {'OPENAI_API_KEY': key}),
    root: root,
    log: log.add,
    now: now,
  );
  return AssetPipeline(plan: plan, studio: studio, log: log.add, now: now);
}

/// The season's folder copied under a new temporary root.
Directory _copySeason(String seasonDir) {
  final tmp = Directory.systemTemp.createTempSync('asset_pipeline');
  for (final f in Directory(seasonDir).listSync(recursive: true).whereType<File>()) {
    final rel = f.path.replaceAll(r'\', '/');
    File('${tmp.path}/$rel')
      ..createSync(recursive: true)
      ..writeAsBytesSync(f.readAsBytesSync());
  }
  return tmp;
}

/// Every file under [dir] with its size and time.
Map<String, String> _listing(Directory dir) => {
  for (final f in dir.listSync(recursive: true).whereType<File>()) f.path: '${f.lengthSync()} ${f.lastModifiedSync().microsecondsSinceEpoch}',
};

class _FakeApi implements ImageApi, ImageEditApi {
  int calls = 0, edits = 0;
  final bodies = <Map<String, Object?>>[];

  /// The call (1, 2, …) answered with an error.
  int? failOn;

  /// The size answered (null: the size asked).
  (int, int)? size;
  int outputTokens = 1568;

  @override
  Future<ApiImage> generate(Map<String, Object?> body, ApiKey key) async => _answer(body);

  @override
  Future<ApiImage> edit(Map<String, Object?> body, ApiKey key) async {
    edits++;
    return _answer(body);
  }

  ApiImage _answer(Map<String, Object?> body) {
    calls++;
    bodies.add(body);
    if (calls == failOn) throw const ApiFailure('Incorrect API key provided: sk-test-0123456789abcdefSECRET.', status: 401);
    final [w, h] = size == null ? (body['size'] as String).split('x').map(int.parse).toList() : [size!.$1, size!.$2];
    return ApiImage(png: _png(w, h), usage: {
      'input_tokens': 100,
      'input_tokens_details': {'text_tokens': 100, 'image_tokens': 0},
      'output_tokens': outputTokens,
    });
  }
}

final _pngs = <(int, int), Uint8List>{};

/// A real PNG of [w]×[h] RGB pixels (made once a size).
Uint8List _png(int w, int h) => _pngs[(w, h)] ??= () {
  int crc(List<int> bytes) {
    var c = 0xFFFFFFFF;
    for (final x in bytes) {
      c ^= x;
      for (var k = 0; k < 8; k++) {
        c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
      }
    }
    return c ^ 0xFFFFFFFF;
  }

  List<int> chunk(String type, List<int> body) {
    final typed = [...ascii.encode(type), ...body];
    return [...(ByteData(4)..setUint32(0, body.length)).buffer.asUint8List(), ...typed, ...(ByteData(4)..setUint32(0, crc(typed))).buffer.asUint8List()];
  }

  final ihdr = (ByteData(13)
        ..setUint32(0, w)
        ..setUint32(4, h)
        ..setUint8(8, 8)
        ..setUint8(9, 2))
      .buffer
      .asUint8List();
  final raw = Uint8List(h * (w * 3 + 1));
  for (var i = 0; i < raw.length; i++) {
    if (i % (w * 3 + 1) != 0) raw[i] = (i * 7) & 0xFF;
  }
  return Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10, ...chunk('IHDR', ihdr), ...chunk('IDAT', ZLibEncoder().convert(raw)), ...chunk('IEND', [])]);
}();
