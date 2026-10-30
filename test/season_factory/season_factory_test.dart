import 'dart:convert';
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

  test('the levels step (exit 35): a skeleton for each file, a level copied from Rookie refused, the lines written kept, then on', () {
    const sandbox = 'content_pipeline/seasons/s9_sandbox';
    final tmp = Directory.systemTemp.createTempSync('factory_levels');
    addTearDown(() => tmp.deleteSync(recursive: true));
    final s = '${tmp.path.replaceAll(r'\', '/')}/s9_sandbox';
    for (final f in ['season.plan.json', 'cases/s9_ep01/case.plan.json', 'cases/s9_ep02/case.plan.json']) {
      File('$sandbox/$f').copySync((File('$s/$f')..createSync(recursive: true)).path);
    }
    final first = SeasonFactory.levelsToWrite(s, skeleton: true);
    final files = first.keys.toList();
    expect(files, containsAll(['$s/cases/s9_ep01/levels.json', '$s/cases/s9_ep02/levels.json']));
    expect(first.values.expand((f) => f), everyElement(startsWith('[levels_missing]')));
    for (final f in files) {
      expect(File(f).existsSync(), isTrue, reason: '$f: its skeleton, every line to write');
    }
    void write(String Function(String rookie, String level) words, {String? only}) {
      for (final f in files.where((f) => only == null || f == only)) {
        final json = jsonDecode(File(f).readAsStringSync()) as Map;
        for (final l in json['lines'] as List) {
          for (final level in ['junior', 'master']) {
            (l as Map)[level] = words(l['rookie'] as String, level);
          }
        }
        File(f).writeAsStringSync(jsonEncode(json));
      }
    }

    write((rookie, _) => rookie);
    final copied = SeasonFactory.levelsToWrite(s, skeleton: true);
    expect(copied['$s/cases/s9_ep01/levels.json'], [startsWith('[level_copied] junior'), startsWith('[level_copied] master')]);

    // Written: each sentence another (a one-word line, as a tile letter a puzzle spells, kept).
    String at(String rookie, String level) => rookie.contains(' ') ? '$rookie ($level)' : rookie;
    write(at);
    final ep02 = '$s/cases/s9_ep02/levels.json';
    final firstLine = ((jsonDecode(File(ep02).readAsStringSync()) as Map)['lines'] as List).first as Map;
    write((rookie, level) => rookie == firstLine['rookie'] && level == 'master' ? '' : at(rookie, level), only: ep02);
    final written = {for (final f in files) f: File(f).readAsStringSync()};
    expect(SeasonFactory.levelsToWrite(s, skeleton: true).map((f, found) => MapEntry(f, found.length)), {ep02: 1}, reason: 'the one line left');
    expect(File('$s/cases/s9_ep01/levels.json').readAsStringSync(), written['$s/cases/s9_ep01/levels.json'], reason: 'a file written is never written again');
    expect(((jsonDecode(File(ep02).readAsStringSync()) as Map)['lines'] as List).skip(1).map((l) => (l as Map)['junior']), everyElement(endsWith('(junior)')),
        reason: 'its skeleton again keeps the lines written');

    write(at, only: ep02);
    expect(SeasonFactory.levelsToWrite(s, skeleton: true), isEmpty, reason: 'every file written: the run goes on to generate');
  });

  test('status reads Rome as done: nothing to make, review or measure', () async {
    final out = await Process.run('dart', ['run', 'tool/season_factory/season_factory.dart', 'status', dir], runInShell: true);
    expect(out.exitCode, 0, reason: '${out.stdout}${out.stderr}');
    expect('${out.stdout}', contains('0 to make, 0 to review'));
    expect('${out.stdout}', contains('measured everything made'));
    expect('${out.stdout}', contains('levels   every case at Rookie, Junior and Master'));
    expect('${out.stdout}', contains('generated into lib/data/generated/s3_rome'));
  }, timeout: const Timeout(Duration(minutes: 3)));
}
