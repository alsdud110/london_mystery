import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/ai_agents/png_check.dart';
import '../../tool/asset_pipeline/asset_plan.dart';
import '../../tool/season_factory/season_factory.dart';
import '../../tool/season_factory/sheets.dart';
import '../../tool/season_gen/plan_check.dart';
import '../../tool/season_gen/plan_files.dart';
import '../../tool/season_gen/plan_models.dart';

/// The season factory (the Rome integration): what it counts as needed and
/// as measured, its sheets, and the plans' new checks (a place's location,
/// the season map), on Rome as it is in the game. No API is called.
void main() {
  const dir = 'content_pipeline/seasons/s3_rome';

  test('the pictures the game shows: every place, choice and face, the cover, the map and each evidence picture; never one no screen shows', () {
    final plan = AssetPlan.load('$dir/assets.manifest.json');
    expect(plan.ok, isTrue, reason: plan.errors.join('\n'));
    final needed = SeasonFactory.neededPictures(plan);
    String id(String name) => 's3_rome.asset.$name';
    expect(needed, containsAll([id('cover'), id('city_map'), id('pantheon_hall'), id('char_bruno_site'), id('stone_lion'), id('ev_owl_card'), id('ev_business_card')]));
    expect(needed, isNot(contains(id('prologue'))), reason: 'no screen shows a generated season\'s prologue');
    expect(needed, isNot(contains(id('ev_gold_tiles'))), reason: 'the game writes the tiles');
    expect(needed, isNot(contains(id('scene_owl_reveal'))), reason: 'a story scene the generator has no table for');
    expect(needed, hasLength(60));
    for (final a in plan.assets.where((a) => needed.contains(a.assetId))) {
      expect(File(a.outputPath).existsSync(), isTrue, reason: '${a.assetId}: Rome has every picture it shows');
    }
  });

  test('Rome is measured whole: its map and its four look rounds, each on its very file', () {
    expect(SeasonFactory.unmeasured(dir), isEmpty);
  });

  test('the sheets: a review sheet of a batch, numbered; a grid sheet the size of its picture', () {
    final tmp = Directory.systemTemp.createTempSync('factory_sheets');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final files = ['assets/seasons/season_03_rome/objects/owl_card.png', 'assets/seasons/season_03_rome/locations/map/rome_map.png', 'assets/seasons/season_03_rome/characters/pia_base.png'];
    Sheets.review(files, '${tmp.path}/review.png', cell: 200);
    expect((PngCheck.file('${tmp.path}/review.png').width, PngCheck.file('${tmp.path}/review.png').height), (400, 400), reason: 'two a row');
    Sheets.grid('assets/seasons/season_03_rome/locations/map/rome_map.png', '${tmp.path}/grid.png');
    expect((PngCheck.file('${tmp.path}/grid.png').width, PngCheck.file('${tmp.path}/grid.png').height), (1536, 1024), reason: 'read in the picture\'s own pixels');
  });

  test('the plans: a place\'s location, and the season map\'s landmarks, are the season\'s own and on the map', () {
    final json = PlanFiles.readJson('$dir/season.plan.json') as Map<String, dynamic>;
    expect(PlanCheck.season(SeasonPlan.fromJson(json)), isEmpty);
    Map<String, dynamic> copy() => PlanFiles.readJson('$dir/season.plan.json') as Map<String, dynamic>;
    List<String> issues(void Function(Map<String, dynamic> j) change) {
      final j = copy();
      change(j);
      return [for (final i in PlanCheck.season(SeasonPlan.fromJson(j))) '${i.path} ${i.message}'];
    }

    Map<String, dynamic> map(Map<String, dynamic> j) => (j['art'] as Map<String, dynamic>)['map'] as Map<String, dynamic>;
    expect(issues((j) => ((j['places'] as List).first as Map)['locId'] = 'nowhere'), contains(contains('nowhere is not a location')));
    expect(issues((j) => ((j['places'] as List).first as Map).remove('locId')), [contains('must be on the season map')]);
    expect(issues((j) => ((map(j)['landmarks'] as List).first as Map)['at'] = [2000, 10]), [contains('is off the 1536x1024 map')]);
    expect(issues((j) => (map(j)['landmarks'] as List).removeLast()), isNotEmpty, reason: 'a place whose location has no landmark');
    expect(() => SeasonPlan.fromJson(copy()..['art'] = {'cover': {'file': 'assets/x.png', 'pixels': {'width': 1, 'height': 1}, 'crop': [2, 0]}}),
        throwsA(isA<PlanFormatException>()), reason: 'an alignment is -1 to 1');
  });

  test('status reads Rome as done: nothing to make, review or measure', () async {
    final out = await Process.run('dart', ['run', 'tool/season_factory/season_factory.dart', 'status', dir], runInShell: true);
    expect(out.exitCode, 0, reason: '${out.stdout}${out.stderr}');
    expect('${out.stdout}', contains('0 to make, 0 to review'));
    expect('${out.stdout}', contains('measured everything made'));
    expect('${out.stdout}', contains('generated into lib/data/generated/s3_rome'));
  }, timeout: const Timeout(Duration(minutes: 3)));
}
