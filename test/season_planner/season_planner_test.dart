import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/season_planner/english_check.dart';
import '../../tool/season_planner/finding.dart';
import '../../tool/season_planner/plan_season.dart';
import '../../tool/season_planner/season_quality.dart';

/// STEP 3-11: the season planner's checks, each on a copy of the Rome trial
/// season with one thing broken. The trial itself is checked whole in
/// `s3_rome_season_test.dart`.
void main() {
  const trial = 'content_pipeline/seasons/s3_rome';
  late Directory tmp;
  late String dir;

  setUp(() {
    tmp = Directory.systemTemp.createTempSync('season_planner_');
    dir = '${tmp.path.replaceAll(r'\', '/')}/s3_rome';
    _copy(Directory(trial), Directory(dir));
  });
  tearDown(() => tmp.deleteSync(recursive: true));

  Map<String, Object?> read(String file) => (jsonDecode(File('$dir/$file').readAsStringSync()) as Map).cast<String, Object?>();
  void write(String file, Object? json) => File('$dir/$file').writeAsStringSync(jsonEncode(json));
  void edit(String file, void Function(Map<String, dynamic> json) change) {
    final json = read(file);
    change(json);
    write(file, json);
  }

  QualityReport check() => SeasonQuality.run(dir);
  List<String> errors(QualityReport r) => [for (final f in r.findings) if (f.isError) f.code];

  test('the trial season, copied whole, has no ERROR', () {
    final r = check();
    expect(errors(r), isEmpty, reason: r.findings.where((f) => f.isError).join('\n'));
  });

  group('season structure', () {
    test('a case taken out', () {
      Directory('$dir/cases/s3_ep07').deleteSync(recursive: true);
      final r = check();
      expect(errors(r), contains('case_missing'));
      expect(r.summary['generator'], {'run': false}, reason: 'nothing goes to the generator with an ERROR');
    });

    test('cases out of order in an act', () {
      edit('season.plan.json', (s) {
        final ids = (s['acts'] as List).first['caseIds'] as List;
        ids.insert(0, ids.removeAt(1));
      });
      final r = check();
      expect(r.findings.where((f) => f.isError && f.where == 'season.plan.json' && f.message.contains('s3_ep02')), isNotEmpty);
    });

    test('a case given the id of another', () {
      edit('cases/s3_ep02/case.plan.json', (c) => c['caseId'] = 's3_ep01');
      expect(errors(check()), isNotEmpty);
    });

    test('a folder that is no case of the season', () {
      Directory('$dir/cases/s3_ep13').createSync();
      expect(errors(check()), contains('case_not_in_season'));
    });
  });

  group('story links', () {
    test('a clue no mission leaves', () {
      edit('cases/s3_ep05/case.plan.json', (c) => (((c['missions'] as List)[0] as Map)['clueInputs'] as List)[0]['ref'] = 's3_ep04_e9');
      expect(errors(check()), contains('clue_not_found'));
    });

    test('evidence used before it is found', () {
      edit('cases/s3_ep02/case.plan.json', (c) => ((((c['missions'] as List)[0] as Map)['clueInputs'] as List)).add({'ref': 's3_ep09_c1', 'use': 'textMention'}));
      expect(errors(check()), contains('clue_used_before_discovery'));
    });

    test('a character the season does not have', () {
      edit('cases/s3_ep03/case.plan.json', (c) => (c['characters'] as List).add('nobody_here'));
      expect(check().findings.where((f) => f.isError && f.message.contains('not a character')), isNotEmpty);
    });

    test('a location the season does not have', () {
      edit('cases/s3_ep03/case.plan.json', (c) => (c['locations'] as List).add('atlantis'));
      expect(check().findings.where((f) => f.isError && f.message.contains('not a location')), isNotEmpty);
    });

    test('a character before their first case', () {
      edit('cases/s3_ep01/case.plan.json', (c) => (c['characters'] as List).add('carla_bassi'));
      expect(errors(check()), contains('character_before_first_case'));
    });
  });

  group('puzzles', () {
    test('a required plan field missing', () {
      edit('cases/s3_ep04/case.plan.json', (c) => c.remove('goal'));
      expect(check().findings.where((f) => f.isError && f.message.contains('goal')), isNotEmpty);
    });

    test('a wrong option with nothing to say', () {
      edit('cases/s3_ep02/case.plan.json', (c) => ((((c['missions'] as List)[1] as Map)['puzzle'] as Map)['answerSpec']['options'] as List)[0].remove('feedback'));
      expect(errors(check()), contains('feedback_missing'));
    });

    test('an answer its options cannot give', () {
      edit('cases/s3_ep02/case.plan.json', (c) => (((c['missions'] as List)[1] as Map)['puzzle'] as Map)['answerSpec']['answer'] = 'nobody');
      expect(errors(check()), contains('answer_mismatch'));
    });

    test('a puzzle the generator does not make', () {
      edit('cases/s3_ep06/case.plan.json', (c) {
        final p = ((c['missions'] as List)[0] as Map)['puzzle'] as Map;
        p['paletteId'] = 'scene_explore_choose';
        p['status'] = 'awaitingAssets';
        p['assetNeeds'] = ['s3_rome.asset.navona_square'];
      });
      final r = check();
      expect(errors(r), contains('generate_unsupported'));
    });

    test('a hint that says the answer is a WARNING, not an ERROR', () {
      edit('cases/s3_ep04/case.plan.json', (c) => ((((c['missions'] as List)[1] as Map)['play'] as Map)['hints'] as List)[1] = 'The password is FOUND.');
      final r = check();
      expect(r.findings.where((f) => f.code == 'hint_reveals_answer').single.level, Level.warning);
      expect(errors(r), isEmpty);
    });
  });

  group('story bible', () {
    test('a name not the season plan\'s', () {
      edit('planning/story_bible.json', (b) => (b['characters'] as List)[0]['name'] = 'Julia Marino');
      expect(errors(check()), contains('bible_season_mismatch'));
    });

    test('a question never answered', () {
      edit('planning/story_bible.json', (b) => (b['mysteryQuestions'] as List)[0]['answeredIn'] = 's3_ep13');
      expect(errors(check()), contains('mystery_unresolved'));
    });

    test('a clue thread no mission uses', () {
      edit('planning/story_bible.json', (b) => (b['clueThreads'] as List).add({'from': 's3_ep01_c1', 'to': ['s3_ep12_m1'], 'meaning': 'x'}));
      expect(errors(check()), contains('bible_thread_unlinked'));
    });

    test('no story bible', () {
      File('$dir/planning/story_bible.json').deleteSync();
      expect(errors(check()), contains('bible_missing'));
    });
  });

  group('asset manifest', () {
    Map<String, dynamic> asset(Map<String, dynamic> m, String id) => ((m['assets'] as List).cast<Map<String, dynamic>>()).firstWhere((a) => a['assetId'] == id);

    test('an asset id of another season', () {
      edit('assets.manifest.json', (m) => asset(m, 's3_rome.asset.cover')['assetId'] = 's3_other.asset.cover');
      expect(errors(check()), contains('asset_id_invalid'));
    });

    test('an asset given twice', () {
      edit('assets.manifest.json', (m) => (m['assets'] as List).add(jsonDecode(jsonEncode(asset(m, 's3_rome.asset.cover')))));
      expect(errors(check()), containsAll(['asset_id_duplicate', 'asset_path_duplicate']));
    });

    test('a place picture away from the season plan\'s file', () {
      edit('assets.manifest.json', (m) => asset(m, 's3_rome.asset.map_hall')['outputPath'] = 'assets/seasons/season_03_rome/locations/hall.png');
      expect(errors(check()), contains('asset_path_mismatch'));
    });

    test('a place with no picture planned', () {
      edit('assets.manifest.json', (m) => (m['assets'] as List).removeWhere((a) => a['assetId'] == 's3_rome.asset.trevi_fountain'));
      expect(errors(check()), contains('asset_place_missing'));
    });

    test('a picture in another season\'s folder', () {
      edit('assets.manifest.json', (m) => asset(m, 's3_rome.asset.cover')['outputPath'] = 'assets/seasons/season_02_paris/cover/x.png');
      expect(errors(check()), contains('asset_path_invalid'));
    });

    test('a size the image models do not make', () {
      edit('assets.manifest.json', (m) => asset(m, 's3_rome.asset.cover')['width'] = 2000);
      expect(errors(check()), contains('asset_size_unsupported'));
    });

    test('a style that does not exist', () {
      edit('assets.manifest.json', (m) => asset(m, 's3_rome.asset.cover')['stylePreset'] = 'tokyo_scene');
      expect(errors(check()), contains('asset_style_unknown'));
    });

    test('a character\'s second pose not drawn from the first', () {
      edit('assets.manifest.json', (m) => asset(m, 's3_rome.asset.char_livia_hood')['references'] = <String>[]);
      expect(errors(check()), contains('asset_reference_missing'));
    });

    test('a reference to no asset', () {
      edit('assets.manifest.json', (m) => asset(m, 's3_rome.asset.ev_plaster_copy')['references'] = ['s3_rome.asset.nothing']);
      expect(errors(check()), contains('asset_reference_unknown'));
    });

    test('a picture marked generated that is not on disk', () {
      edit('assets.manifest.json', (m) => asset(m, 's3_rome.asset.cover')['status'] = 'generated');
      expect(errors(check()), contains('asset_file_missing'));
    });
  });

  group('English heuristics', () {
    test('only warn, and say they are heuristics', () {
      edit('cases/s3_ep01/case.plan.json', (c) => (c['play'] as Map)['intro'] = [
        'This is a very long sentence that goes on and on with far too many words for a young reader.',
        'The extraordinary investigation continues.',
      ]);
      final r = check();
      final en = r.findings.where((f) => f.source == Source.englishHeuristic).toList();
      expect(en.map((f) => f.code), containsAll(['en_long_sentence', 'en_hard_word']));
      expect(en.every((f) => f.level == Level.warning), isTrue);
      expect(errors(r), isEmpty);
    });

    test('count words and sentences, and leave possessives and common words alone', () {
      expect(EnglishCheck.sentences('One. Two!\nThree?'), ['One.', 'Two!', 'Three?']);
      expect(EnglishCheck.words("Pia's stall is red."), 4);
      expect(EnglishCheck.commonLongWords, contains('everything'));
    });
  });

  group('nothing half made', () {
    test('init refuses a season taken, a folder there, and another size, writing nothing', () {
      final root = '${tmp.path.replaceAll(r'\', '/')}/seasons';
      expect(() => SeasonBrief.parse(['--season', '3', '--city', 'Rome', '--cases', '10'], root: root), throwsFormatException);
      expect(() => SeasonBrief.parse(['--season', '3', '--city', 'Rome', '--acts', '4'], root: root), throwsFormatException);
      expect(Directory(root).existsSync(), isFalse);

      final brief = SeasonBrief.parse(['--season', '4', '--city', 'New York'], root: root);
      expect(brief.seasonId, 's4_newyork');
      brief.write();
      expect(File('$root/s4_newyork/planning/brief.json').existsSync(), isTrue);
      expect(Directory('$root/s4_newyork.part').existsSync(), isFalse);
      expect(() => SeasonBrief.parse(['--season', '4', '--city', 'New York'], root: root), throwsFormatException);
      expect(() => SeasonBrief.parse(['--season', '4', '--city', 'Tokyo'], root: root), throwsFormatException);
    });

    test('generate writes nothing with an ERROR, nor while pictures are missing', () {
      final out = '${tmp.path.replaceAll(r'\', '/')}/out';
      expect(generateCommand([dir, '--out', out]), 2, reason: 'the 18 place pictures are not made');
      expect(Directory(out).existsSync(), isFalse);

      Directory('$dir/cases/s3_ep12').deleteSync(recursive: true);
      expect(generateCommand([dir, '--out', out]), 1, reason: 'a case is missing');
      expect(Directory(out).existsSync(), isFalse);
    });

    test('the report is written whole and the same plans write the same report', () {
      final path = SeasonQuality.write(dir, check());
      final first = File(path).readAsStringSync();
      expect(File('$path.part').existsSync(), isFalse);
      SeasonQuality.write(dir, check());
      expect(File(path).readAsStringSync(), first, reason: 'no time and no machine in a report');
    });
  });
}

void _copy(Directory from, Directory to) {
  to.createSync(recursive: true);
  for (final e in from.listSync()) {
    final name = e.uri.pathSegments.where((s) => s.isNotEmpty).last;
    if (e is Directory) {
      _copy(e, Directory('${to.path}/$name'));
    } else if (e is File) {
      e.copySync('${to.path}/$name');
    }
  }
}
