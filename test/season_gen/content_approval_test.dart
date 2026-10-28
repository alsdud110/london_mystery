import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/season_gen/approve.dart' as approve_cli;
import '../../tool/season_gen/content_approval.dart';
import '../../tool/season_gen/content_hash.dart';
import '../../tool/season_gen/json_schema_lite.dart';
import '../../tool/season_gen/plan_files.dart';
import '../../tool/season_gen/sha256.dart';
import '../../tool/season_gen/validate_plan.dart' as validate_cli;
import 'plan_samples.dart';

/// Content approval (STEP 3-5): hashes, approvals, and what changes do to
/// them. Every season here is written to a folder of its own under the
/// system's temp; the fixtures and the content pipeline are only read.
void main() {
  group('SHA-256', () {
    String hex(String s) => Sha256.hex(utf8.encode(s));

    test("the standard's test vectors", () {
      expect(hex(''), 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855');
      expect(hex('abc'), 'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad');
      expect(hex('abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq'), '248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1');
      expect(Sha256.hex(List.filled(1000000, 0x61)), 'cdc76e5c9914fb9281a1c7e284d73e67f1809a48a497200e046d39ccc7112cd0');
    });

    test('messages about a block long hash apart', () {
      final hashes = {for (var n = 54; n <= 66; n++) Sha256.hex(List.filled(n, 0x61))};
      expect(hashes, hasLength(13));
    });
  });

  group('content hash', () {
    test('the same data in another key order, spacing or newlines: the same hash', () {
      const a = '{"b": 1, "a": {"y": [1, 2], "x": "é\\n"}}';
      const b = '{\n  "a": {\n    "x": "\\u00e9\\n",\n    "y": [\n      1,\n      2\n    ]\n  },\n  "b": 1.0\n}\n';
      expect(ContentHash.ofJson(jsonDecode(a)), ContentHash.ofJson(jsonDecode(b)));
      expect(ContentHash.canonicalJson(jsonDecode(a)), '{"a":{"x":"é\\n","y":[1,2]},"b":1}');
      expect(ContentHash.ofJson(jsonDecode(a)), matches(ContentHash.pattern));
    });

    test('a value changed, or an array reordered: another hash', () {
      final base = ContentHash.ofJson(sampleCaseJson());
      final title = sampleCaseJson()..['title'] = 'The Stopped Clocks';
      final order = sampleCaseJson()..['synopsis'] = ['b', 'a'];
      final reordered = sampleCaseJson()..['synopsis'] = ['a', 'b'];
      expect(ContentHash.ofJson(title), isNot(base));
      expect(ContentHash.ofJson(order), isNot(ContentHash.ofJson(reordered)));
      expect(ContentHash.ofJson({'a': null}), isNot(ContentHash.ofJson(<String, Object?>{})));
      expect(ContentHash.ofJson('é'), isNot(ContentHash.ofJson('é')), reason: 'no Unicode normalisation');
    });

    test('a plan read and written again by PlanFiles keeps its hash', () {
      const path = 'test/fixtures/season_gen/s2_paris/cases/s2_ep10/case.plan.json';
      final raw = PlanFiles.readJson(path);
      final again = jsonDecode(PlanFiles.encode(PlanFiles.loadCasePlan(path).toJson()));
      expect(ContentHash.ofJson(again), ContentHash.ofJson(raw));
      expect(ContentHash.ofJson(jsonDecode(jsonEncode(raw))), ContentHash.ofJson(raw), reason: 'minified');
    });

    test('what JSON cannot hold has no hash', () {
      expect(() => ContentHash.canonicalJson(double.nan), throwsArgumentError);
      expect(() => ContentHash.canonicalJson({1: 'a'}), throwsArgumentError);
    });
  });

  group('approvals', () {
    late Directory root;
    late SeasonApprovals approvals;
    late String seasonFile;
    late String caseFile;
    final t0 = DateTime.utc(2026, 10, 28, 9);

    void write(String path, Map<String, Object?> json) => File(path)
      ..parent.createSync(recursive: true)
      ..writeAsStringSync(PlanFiles.encode(json));

    setUp(() {
      root = Directory.systemTemp.createTempSync('approvals_');
      final dir = '${root.path}/content_pipeline/seasons/s3_sample';
      seasonFile = '$dir/season.plan.json';
      caseFile = '$dir/cases/s3_ep01/case.plan.json';
      write(seasonFile, sampleSeasonJson());
      write(caseFile, sampleCaseJson());
      approvals = SeasonApprovals(dir);
    });
    tearDown(() => root.deleteSync(recursive: true));

    test('nothing approved: draft, with no approval file', () {
      expect(approvals.seasonId, 's3_sample');
      expect(approvals.records(), isEmpty);
      expect(approvals.seasonPlan().status, ApprovalStatus.draft);
      final c = approvals.casePlan('s3_ep01');
      expect((c.status, c.record, c.currentHash), (ApprovalStatus.draft, null, ContentHash.ofJson(sampleCaseJson())));
      expect(File(approvals.logPath).existsSync(), isFalse);
    });

    test('an approval, asked for: approved, written down, its content kept', () {
      final (:record, :added) = approvals.approve(ApprovalKind.casePlan, 's3_ep01', approvedBy: 'Reviewer <r@example.com>', note: 'read through', now: t0);
      expect(added, isTrue);
      expect(record.hash, ContentHash.ofJson(sampleCaseJson()));
      final s = approvals.casePlan('s3_ep01');
      expect(s.status, ApprovalStatus.approved);
      expect(approvals.seasonPlan().status, ApprovalStatus.draft, reason: 'only what was approved');
      final log = jsonDecode(File(approvals.logPath).readAsStringSync());
      expect(log, {
        'schemaVersion': 1,
        'seasonId': 's3_sample',
        'approvals': [
          {'kind': 'casePlan', 'id': 's3_ep01', 'hash': record.hash, 'approvedAt': '2026-10-28T09:00:00.000Z', 'approvedBy': 'Reviewer <r@example.com>', 'note': 'read through'},
        ],
      });
      expect(approvals.approvedJson(record), sampleCaseJson());
      expect(File('${approvals.dir.path}/approved/${record.hash.substring(7)}.json').existsSync(), isTrue);
    });

    test('changed after its approval: stale, its approval kept; approved again: approved', () {
      approvals.approve(ApprovalKind.casePlan, 's3_ep01', approvedBy: 'Reviewer', now: t0);
      final log = File(approvals.logPath).readAsStringSync();

      // The same data written another way is not a change.
      File(caseFile).writeAsStringSync(jsonEncode(Map.fromEntries(sampleCaseJson().entries.toList().reversed)));
      expect(approvals.casePlan('s3_ep01').status, ApprovalStatus.approved);

      write(caseFile, sampleCaseJson()..['goal'] = 'Find who stopped it, and why.');
      final stale = approvals.casePlan('s3_ep01');
      expect(stale.status, ApprovalStatus.stale);
      expect(stale.currentHash, isNot(stale.record!.hash));
      expect(File(approvals.logPath).readAsStringSync(), log, reason: 'judging never writes');
      expect(approvals.readiness('s3_ep01').ready, isFalse);

      final again = approvals.approve(ApprovalKind.casePlan, 's3_ep01', approvedBy: 'Reviewer', now: t0.add(const Duration(hours: 1)));
      expect(again.added, isTrue);
      final s = approvals.casePlan('s3_ep01');
      expect(s.status, ApprovalStatus.approved);
      expect([for (final r in s.history) r.approvedAt.hour], [9, 10], reason: 'the first approval is kept');

      expect(approvals.approve(ApprovalKind.casePlan, 's3_ep01', approvedBy: 'Reviewer').added, isFalse, reason: 'already approved as it is');
      expect(approvals.records(), hasLength(2));
    });

    test('a plan that is not JSON any more: stale, and cannot be approved', () {
      approvals.approve(ApprovalKind.seasonPlan, 's3_sample', approvedBy: 'Reviewer', now: t0);
      File(seasonFile).writeAsStringSync('{"seasonId": ');
      final s = approvals.seasonPlan();
      expect((s.status, s.currentHash), (ApprovalStatus.stale, null));
      expect(s.problem, startsWith('not JSON'));
      expect(() => approvals.approve(ApprovalKind.seasonPlan, 's3_sample', approvedBy: 'Reviewer'), throwsA(isA<ApprovalException>()));
    });

    test('a target with no file: missing, approved or not, and cannot be approved', () {
      expect(approvals.casePlan('s3_ep02').status, ApprovalStatus.missing);
      expect(() => approvals.approve(ApprovalKind.casePlan, 's3_ep02', approvedBy: 'Reviewer'), throwsA(isA<ApprovalException>()));
      approvals.approve(ApprovalKind.casePlan, 's3_ep01', approvedBy: 'Reviewer', now: t0);
      File(caseFile).deleteSync();
      final s = approvals.casePlan('s3_ep01');
      expect((s.status, s.isApproved, s.record?.id), (ApprovalStatus.missing, false, 's3_ep01'));
      expect(approvals.readiness('s3_ep01').blockers, contains('casePlan s3_ep01 is missing'));
    });

    test('an asset: approved with its file, stale when its bytes change, not approved when gone', () {
      const id = 's3_sample.asset.station_hall';
      const path = 'assets/seasons/season_03_sample/station_hall.png';
      final file = File('${root.path}/$path')
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync([0x89, 0x50, 0x4e, 0x47, 1, 2, 3]);
      expect(approvals.asset(id).status, ApprovalStatus.draft, reason: 'its file is not known before it is approved');
      expect(() => approvals.approve(ApprovalKind.asset, id, approvedBy: 'Reviewer'), throwsA(isA<ApprovalException>()), reason: 'no path');
      expect(() => approvals.approve(ApprovalKind.asset, id, approvedBy: 'Reviewer', assetPath: '../outside.png'), throwsA(isA<ApprovalException>()));

      final (:record, added: _) = approvals.approve(ApprovalKind.asset, id, approvedBy: 'Reviewer', assetPath: path, now: t0);
      expect((record.path, record.hash), (path, ContentHash.ofBytes(file.readAsBytesSync())));
      expect(approvals.asset(id).status, ApprovalStatus.approved);
      expect(Directory('${approvals.dir.path}/approved').existsSync(), isFalse, reason: "a picture's content is its file, not kept again");

      file.writeAsBytesSync([0x89, 0x50, 0x4e, 0x47, 1, 2, 4]);
      expect(approvals.asset(id).status, ApprovalStatus.stale);
      approvals.approve(ApprovalKind.asset, id, approvedBy: 'Reviewer', now: t0);
      expect(approvals.asset(id).status, ApprovalStatus.approved, reason: 'approved again, at the path it was approved at');

      file.deleteSync();
      final gone = approvals.asset(id);
      expect((gone.status, gone.isApproved), (ApprovalStatus.missing, false));
      expect(() => approvals.approve(ApprovalKind.asset, id, approvedBy: 'Reviewer'), throwsA(isA<ApprovalException>()));
    });

    test('the report: the season plan, its twelve cases, the assets asked for', () {
      final r = approvals.report();
      expect(r.first.label, 'seasonPlan s3_sample');
      expect([for (final s in r) if (s.kind == ApprovalKind.casePlan) s.id], hasLength(12));
      expect([for (final s in r) if (s.kind == ApprovalKind.casePlan && s.status == ApprovalStatus.missing) s.id], hasLength(11));
      expect([for (final s in r) if (s.kind == ApprovalKind.asset) s.label], ['asset s3_sample.asset.station_hall']);
    });

    test('a status cannot be written, nor a record changed unseen', () {
      approvals.approve(ApprovalKind.casePlan, 's3_ep01', approvedBy: 'Reviewer', now: t0);
      final log = jsonDecode(File(approvals.logPath).readAsStringSync()) as Map<String, Object?>;
      final record = ((log['approvals']! as List).single as Map<String, Object?>)..['status'] = 'approved';
      File(approvals.logPath).writeAsStringSync(jsonEncode(log));
      expect(approvals.records, throwsA(isA<ApprovalFormatException>().having((e) => e.path, 'path', r'$.approvals[0].status')));

      record
        ..remove('status')
        ..['hash'] = 'sha256:${'0' * 64}';
      File(approvals.logPath).writeAsStringSync(jsonEncode(log));
      expect(approvals.casePlan('s3_ep01').status, ApprovalStatus.stale, reason: 'a hash the content does not have');
      expect(approvals.approvedJson(approvals.records().single), isNull, reason: 'no content kept with that hash');

      File(approvals.logPath).writeAsStringSync(jsonEncode({...log, 'seasonId': 's3_other'}));
      expect(approvals.records, throwsA(isA<ApprovalFormatException>()));
    });

    test('a kept content edited is not trusted', () {
      final (:record, added: _) = approvals.approve(ApprovalKind.casePlan, 's3_ep01', approvedBy: 'Reviewer', now: t0);
      File('${approvals.dir.path}/approved/${record.hash.substring(7)}.json').writeAsStringSync(jsonEncode(sampleCaseJson()..['title'] = 'Other'));
      expect(approvals.approvedJson(record), isNull);
    });

    test('checking and saving plans never approve them', () {
      final schemas = SchemaSet.load('tool/season_gen/schema');
      validate_cli.check(seasonFile, schemas);
      validate_cli.check(caseFile, schemas, season: PlanFiles.loadSeasonPlan(seasonFile));
      PlanFiles.saveCasePlan(PlanFiles.loadCasePlan(caseFile), caseFile);
      expect(File(approvals.logPath).existsSync(), isFalse);
      expect(approvals.report().every((s) => !s.isApproved), isTrue);
    });
  });

  group('Paris Case 10, copied: what it lacks to be made', () {
    const fixtures = 'test/fixtures/season_gen/s2_paris';
    late Directory root;
    late SeasonApprovals approvals;
    final schemas = SchemaSet.load('tool/season_gen/schema');

    setUp(() {
      root = Directory.systemTemp.createTempSync('approvals_paris_');
      final dir = '${root.path}/content_pipeline/seasons/s2_paris';
      Directory('$dir/cases/s2_ep10').createSync(recursive: true);
      File('$fixtures/season.plan.json').copySync('$dir/season.plan.json');
      File('$fixtures/cases/s2_ep10/case.plan.json').copySync('$dir/cases/s2_ep10/case.plan.json');
      approvals = SeasonApprovals(dir);
    });
    tearDown(() => root.deleteSync(recursive: true));

    String caseFile() => approvals.planFile(ApprovalKind.casePlan, 's2_ep10');

    test('its season plan, its plan, then each of its pictures', () {
      expect(approvals.readiness('s2_ep10').blockers, ['seasonPlan s2_paris is draft', 'casePlan s2_ep10 is draft']);
      approvals.approve(ApprovalKind.seasonPlan, 's2_paris', approvedBy: 'Reviewer');
      approvals.approve(ApprovalKind.casePlan, 's2_ep10', approvedBy: 'Reviewer');
      const pictures = ['record_drum', 'roof_photo', 'sundial_top', 'trial_log_open'];
      expect(approvals.readiness('s2_ep10').blockers, [for (final p in pictures) 'asset s2_paris.asset.$p is draft']);

      for (final p in pictures) {
        File('${root.path}/assets/test/$p.png')
          ..parent.createSync(recursive: true)
          ..writeAsBytesSync(utf8.encode(p));
        approvals.approve(ApprovalKind.asset, 's2_paris.asset.$p', approvedBy: 'Reviewer', assetPath: 'assets/test/$p.png');
      }
      final r = approvals.readiness('s2_ep10');
      expect((r.ready, r.states.length), (true, 6));

      File('${root.path}/assets/test/roof_photo.png').writeAsBytesSync([1]);
      expect(approvals.readiness('s2_ep10').blockers, ['asset s2_paris.asset.roof_photo is stale']);
    });

    group('the command line', () {
      final out = StringBuffer();
      int run(List<String> args, {bool yes = true}) {
        out.clear();
        return approve_cli.run(
          args,
          out: out,
          schemaDir: 'tool/season_gen/schema',
          confirm: (_, _) => yes,
          approver: () => 'Git User <git@example.com>',
          clock: () => DateTime.utc(2026, 10, 28, 9),
        );
      }

      test('status, approve (asked, then refused or given), status again', () {
        final dir = approvals.dir.path;
        expect(run(['status', dir, 'case', 's2_ep10']), 1);
        expect(out.toString(), startsWith('draft    casePlan s2_ep10'));

        expect(run(['approve', dir, 'case', 's2_ep10'], yes: false), 1);
        expect(out.toString(), contains('not approved: casePlan s2_ep10'));
        expect(File(approvals.logPath).existsSync(), isFalse);

        expect(run(['approve', dir, 'case', 's2_ep10', '--note', 'checked']), 0);
        expect(out.toString(), contains('approved casePlan s2_ep10 sha256:'));
        expect(approvals.records().single.approvedBy, 'Git User <git@example.com>');
        expect(run(['approve', dir, 'season', '--by', 'Someone']), 0);
        expect(approvals.seasonPlan().record!.approvedBy, 'Someone');

        expect(run(['status', dir, 'case', 's2_ep10']), 0);
        expect(run(['status', dir]), 1, reason: 'its other cases and pictures are not approved');
        expect(out.toString(), contains('blocked  s2_ep10: asset s2_paris.asset.record_drum is draft'));
      });

      test('a plan with errors is not approved', () {
        final json = PlanFiles.readJson(caseFile()) as Map<String, Object?>;
        File(caseFile()).writeAsStringSync(PlanFiles.encode({...json, 'number': 11}));
        expect(run(['approve', approvals.dir.path, 'case', 's2_ep10']), 1);
        expect(out.toString(), contains('has errors'));
        expect(File(approvals.logPath).existsSync(), isFalse);
      });

      test('a wrong command line, an asset with no path', () {
        final dir = approvals.dir.path;
        expect(run(['approve', dir]), 64);
        expect(run(['status', dir, 'case', 's3_ep01']), 64, reason: 'not a case of s2_paris');
        expect(run(['approve', dir, 'case', 's2_ep10', '--path', 'a.png']), 64);
        expect(run(['approve', dir, 'asset', 's2_paris.asset.roof_photo']), 1);
        expect(out.toString(), contains('an asset is approved with its file'));
      });

      test('impact: what a change of an approved plan touches', () {
        final dir = approvals.dir.path;
        run(['approve', dir, 'case', 's2_ep10']);
        expect(run(['impact', dir]), 0);
        expect(out.toString(), contains('nothing approved has changed'));

        final json = PlanFiles.readJson(caseFile()) as Map<String, Object?>;
        final m2 = (json['missions']! as List)[1] as Map<String, Object?>;
        (m2['clueOutputs']! as Map<String, Object?>)['evidence'] = 's2_ep10_e9';
        File(caseFile()).writeAsStringSync(PlanFiles.encode(json));
        expect(run(['impact', dir]), 0);
        expect(
          out.toString(),
          allOf(
            contains('stale    casePlan s2_ep10'),
            contains('[mission_changed] mission s2_ep10_m2: clueOutputs changed'),
            contains(r'[clue_removed] clue s2_ep10_e2: no longer left (was by s2_ep10_m2); s2_ep10_m3 is given it → review casePlan s2_ep10 $.missions[2].clueInputs[0]'),
          ),
        );
      });

      test('the plans still check as they did, approved or not', () {
        final before = validate_cli.check(caseFile(), schemas, season: PlanFiles.loadSeasonPlan('$fixtures/season.plan.json'));
        run(['approve', approvals.dir.path, 'case', 's2_ep10']);
        final after = validate_cli.check(caseFile(), schemas, season: PlanFiles.loadSeasonPlan('$fixtures/season.plan.json'));
        expect([after.errors, after.warnings, after.summary, after.clueSummary], [before.errors, before.warnings, before.summary, before.clueSummary]);
        expect(after.errors, isEmpty);
      });
    });
  });
}
