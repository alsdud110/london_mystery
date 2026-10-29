import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/ai_agents/env_file.dart';
import '../../tool/ai_agents/image_manifest.dart';
import '../../tool/ai_agents/image_pricing.dart';
import '../../tool/ai_agents/image_styles.dart';
import '../../tool/ai_agents/openai_image.dart';
import '../../tool/ai_agents/png_check.dart';

/// The image tool (STEP 3-10) with no call to OpenAI: a fake API answers.
/// The key is read and never shown, a request is checked and priced before
/// anything is sent, a dry run sends and writes nothing, a picture made is
/// checked whole and recorded, never made twice, never written over, and a
/// failed call is recorded once and never sent again by itself.
void main() {
  const png = _png;
  const fakeKey = 'sk-test-0123456789abcdefSECRET';

  group('the key', () {
    test('.env read as it is written: comments, export, quotes', () {
      expect(EnvFile.parse('# a comment\n\nexport A=1\nB = "two words"\nC=\'3\'\nD=4 # note\r\nbad line\n'),
          {'A': '1', 'B': 'two words', 'C': '3', 'D': '4'});
    });

    test("the environment's first, else the .env file's; none: null", () {
      final tmp = Directory.systemTemp.createTempSync('env');
      addTearDown(() => tmp.deleteSync(recursive: true));
      File('${tmp.path}/.env').writeAsStringSync('OPENAI_API_KEY=$fakeKey\n');
      expect(ApiKey.find(envPath: '${tmp.path}/.env', environment: {})!.bearer, fakeKey);
      expect(ApiKey.find(envPath: '${tmp.path}/.env', environment: {'OPENAI_API_KEY': 'sk-from-env'})!.bearer, 'sk-from-env');
      expect(ApiKey.find(envPath: '${tmp.path}/none', environment: {}), isNull);
      expect(ApiKey.find(envPath: '${tmp.path}/none', environment: {'OPENAI_API_KEY': '  '}), isNull);
      expect(File('${tmp.path}/.env').readAsStringSync(), 'OPENAI_API_KEY=$fakeKey\n', reason: 'never written');
    });

    test('never shown: its toString, and any key-like text redacted', () {
      final key = ApiKey.find(envPath: 'none', environment: {'OPENAI_API_KEY': fakeKey})!;
      expect('$key', isNot(contains('sk-')));
      expect(key.redact('Incorrect API key provided: $fakeKey. And sk-abc1****wxyz.'), 'Incorrect API key provided: [redacted]. And [redacted].');
    });
  });

  group('a PNG read whole', () {
    test('its size and colour', () {
      final i = PngCheck.bytes(png(3, 2));
      expect((i.width, i.height, i.hasAlpha), (3, 2, false));
    });

    test('refused: not a PNG, cut short, a wrong CRC, missing pixels', () {
      final good = png(3, 2);
      expect(() => PngCheck.bytes(Uint8List.fromList(utf8.encode('<html>'))), throwsA(isA<PngProblem>()));
      expect(() => PngCheck.bytes(Uint8List.sublistView(good, 0, good.length - 6)), throwsA(isA<PngProblem>()));
      final flipped = Uint8List.fromList(good)..[20] ^= 0xFF; // inside IHDR
      expect(() => PngCheck.bytes(flipped), throwsA(isA<PngProblem>().having((p) => p.message, 'message', contains('CRC'))));
    });
  });

  group('the price', () {
    test('estimated before: the output tokens of its size and quality at the list price, the prompt as text', () {
      final e = ImagePricing.estimate(model: 'gpt-image-2', size: '1536x1024', quality: 'medium', prompt: 'x' * 400)!;
      expect(e, closeTo(1568 * 30 / 1e6 + 100 * 5 / 1e6, 1e-9));
      expect(ImagePricing.ratesOf('gpt-image-2-2026-04-21'), isNotNull, reason: 'a snapshot priced as its model');
      expect(ImagePricing.estimate(model: 'gpt-image-9', size: '1024x1024', quality: 'low', prompt: 'x'), isNull);
    });

    test('a gpt-image-2 square at medium: never under what its calls took (1756 output tokens, STEP 3-15A)', () {
      expect(ImagePricing.estimatedOutputTokens('1024x1024', 'medium', model: 'gpt-image-2'), 1756);
      expect(ImagePricing.estimatedOutputTokens('1024x1024', 'medium', model: 'gpt-image-2-2026-04-21'), 1756, reason: 'a snapshot as its model');
      // The landscape and portrait measured lower (1372): the guide's larger count kept.
      expect(ImagePricing.estimatedOutputTokens('1536x1024', 'medium', model: 'gpt-image-2'), 1568);
      expect(ImagePricing.estimatedOutputTokens('1024x1536', 'medium', model: 'gpt-image-2'), 1584);
      // Not measured: the guide's.
      expect(ImagePricing.estimatedOutputTokens('1024x1024', 'medium', model: 'gpt-image-1.5'), 1056);
      expect(ImagePricing.estimatedOutputTokens('1024x1024', 'high', model: 'gpt-image-2'), 4160);
      // Case 05's Tito (1024x1024, medium): its prompt read as 129 text tokens, its usage priced.
      final paid = ImagePricing.ofUsage('gpt-image-2', {
        'input_tokens': 129,
        'input_tokens_details': {'text_tokens': 129, 'image_tokens': 0},
        'output_tokens': 1756,
      })!;
      final cat = ImagePricing.estimate(model: 'gpt-image-2', size: '1024x1024', quality: 'medium', prompt: 'x' * 129 * 4)!;
      expect(cat, closeTo(paid, 1e-9), reason: 'estimated at what was paid (\$0.0533), not \$0.0324');
    });

    test("after: the answer's usage at the list prices", () {
      final usd = ImagePricing.ofUsage('gpt-image-2', {
        'input_tokens': 120,
        'input_tokens_details': {'text_tokens': 120, 'image_tokens': 0},
        'output_tokens': 1500,
      });
      expect(usd, closeTo(120 * 5 / 1e6 + 1500 * 30 / 1e6, 1e-12));
    });
  });

  group('a request', () {
    late Directory tmp;
    late List<String> log;
    late _FakeApi api;
    ApiKey? key;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('openai_image');
      log = [];
      api = _FakeApi();
      key = ApiKey.find(envPath: 'none', environment: {'OPENAI_API_KEY': fakeKey});
    });
    tearDown(() => tmp.deleteSync(recursive: true));

    var clock = DateTime.utc(2026, 10, 29, 9);
    ImageStudio studio() => ImageStudio(api: api, findKey: () => key, root: tmp.path, log: log.add, now: () => clock = clock.add(const Duration(seconds: 1)));
    const out = 'qa/ai_image_tests/test.png';
    ImageRequest req({String prompt = 'A quiet library desk.', String output = out, String size = '1536x1024', String quality = 'medium'}) =>
        ImageRequest(prompt: prompt, output: output, size: size, quality: quality, styleId: 'london_scene');
    File file([String path = out]) => File('${tmp.path}/$path');
    Map<String, Object?> manifest() => jsonDecode(File('${tmp.path}/qa/ai_image_tests/image_manifest.json').readAsStringSync()) as Map<String, Object?>;
    String all() => log.join('\n');

    test('checked before anything is sent: prompt, size, quality, model, output', () {
      final s = studio();
      expect(s.problems(req(prompt: '  ')), ['prompt: empty']);
      expect(s.problems(req(prompt: 'x' * 32001)), [contains('32000')]);
      expect(s.problems(req(prompt: 'a\u0007b')), ['prompt: control characters']);
      expect(s.problems(req(size: '1000x1000')), [contains('multiples of 16')]);
      expect(s.problems(req(size: '3840x1024')), [contains('3:1')]);
      expect(s.problems(req(size: 'big')), [contains('WIDTHxHEIGHT')]);
      expect(s.problems(req(quality: 'ultra')), [contains('quality')]);
      expect(s.problems(ImageRequest(prompt: 'p', output: out, model: 'dall-e-9')), [contains('model')]);
      expect(s.problems(req(output: 'qa/x.jpg')), [contains('not a .png')]);
      expect(s.problems(req(output: '../outside.png')), [contains('not inside the repository')]);
      expect(s.problems(req(output: 'lib/x.png')), [contains('lib/')]);
      expect(s.problems(req(output: 'assets/seasons/x.png')), [contains('assets/')]);
      expect(s.problems(ImageRequest(prompt: 'p', output: out, references: ['qa/ref.png'])), [contains('not on disk'), contains('not made yet')]);
      expect(s.problems(req()), isEmpty);
    });

    test('a refused request sends and writes nothing', () async {
      expect(await studio().run(req(prompt: ''), generate: true), 2);
      expect(api.calls, 0);
      expect(Directory('${tmp.path}/qa').existsSync(), isFalse);
    });

    test('a dry run: priced and shown, the key only said to be found, nothing sent or written', () async {
      expect(await studio().run(req()), 0);
      expect(api.calls, 0);
      expect(all(), contains('gpt-image-2, 1536x1024, quality medium'));
      expect(all(), contains('estimated'));
      expect(all(), contains('API key found'));
      expect(all(), isNot(contains(fakeKey)));
      expect(Directory('${tmp.path}/qa').existsSync(), isFalse, reason: 'no picture, no manifest');
    });

    test('no key: a dry run says so; --generate is refused before sending', () async {
      key = null;
      expect(await studio().run(req()), 0);
      expect(all(), contains('API key NOT found'));
      expect(await studio().run(req(), generate: true), 2);
      expect(all(), contains('no API key'));
      expect(api.calls, 0);
    });

    test('an estimate over the budget is not sent', () async {
      expect(await studio().run(req(quality: 'high'), generate: true, budgetUsd: 0.05), 2);
      expect(all(), contains('over --budget-usd'));
      expect(api.calls, 0);
    });

    test('made: one call, the PNG checked and written, the whole of it in the manifest (no key in it)', () async {
      api.answer = () => ApiImage(png: png(16, 8), created: 1793000000, usage: {
        'input_tokens': 90,
        'input_tokens_details': {'text_tokens': 90, 'image_tokens': 0},
        'output_tokens': 1500,
        'total_tokens': 1590,
      });
      expect(await studio().run(req(size: '16x16'), generate: true), 0);
      expect(api.calls, 1);
      expect(api.bodies.single, {'model': 'gpt-image-2', 'prompt': 'A quiet library desk.', 'n': 1, 'size': '16x16', 'quality': 'medium', 'output_format': 'png'});
      expect(file().readAsBytesSync(), png(16, 8));
      expect(File('${file().path}.part').existsSync(), isFalse);
      final m = manifest();
      expect(m['totals'], {'apiCalls': 1, 'generated': 1, 'failed': 0, 'fromUsageUsd': closeTo(90 * 5 / 1e6 + 1500 * 30 / 1e6, 1e-6)});
      final e = (m['entries'] as List).single as Map;
      expect(e['status'], 'generated');
      expect(e['output'], out);
      expect(e['style'], 'london_scene');
      expect(e['callNumber'], 1);
      expect(e['requestedAt'], '2026-10-29T09:00:01.000Z');
      expect((e['file'] as Map)['width'], 16);
      expect((e['file'] as Map)['sizeAsAsked'], isFalse, reason: 'asked 16x16, given 16x8: said so');
      expect((e['cost'] as Map)['estimatedUsd'], isA<double>());
      expect(e['usage'], containsPair('output_tokens', 1500));
      final text = File('${tmp.path}/qa/ai_image_tests/image_manifest.json').readAsStringSync();
      expect(text, isNot(contains(fakeKey)));
      expect(text, isNot(contains('sk-')));
    });

    test('the same request again: not sent, the picture kept', () async {
      expect(await studio().run(req(), generate: true), 0);
      expect(await studio().run(req(), generate: true), 0);
      expect(api.calls, 1);
      expect(all(), contains('already made'));
    });

    test('another file there is never written over; with --overwrite it is', () async {
      file().createSync(recursive: true);
      file().writeAsStringSync('mine');
      expect(await studio().run(req(), generate: true), 2);
      expect(file().readAsStringSync(), 'mine');
      expect(api.calls, 0);
      expect(await studio().run(req(), generate: true, overwrite: true), 0);
      expect(PngCheck.file(file().path).width, 1536);
    });

    test('an API error: recorded once, its key redacted, nothing written, sent again only when run again', () async {
      api.answer = () => throw ApiFailure('Incorrect API key provided: $fakeKey.', status: 401, type: 'invalid_request_error', code: 'invalid_api_key');
      expect(await studio().run(req(), generate: true), 1);
      expect(api.calls, 1, reason: 'no retry by itself');
      expect(file().existsSync(), isFalse);
      expect(all(), isNot(contains(fakeKey)));
      var e = (manifest()['entries'] as List).single as Map;
      expect(e['status'], 'failed');
      expect(e['error'], {'status': 401, 'type': 'invalid_request_error', 'code': 'invalid_api_key', 'message': 'Incorrect API key provided: [redacted].'});
      expect(manifest()['totals'], containsPair('failed', 1));

      api.answer = null;
      expect(await studio().run(req(), generate: true), 0, reason: 'run again: sent again');
      expect(api.calls, 2);
      e = (manifest()['entries'] as List).last as Map;
      expect((e['status'], e['callNumber']), ('generated', 2));
    });

    test('an answer that is not a whole PNG: nothing written', () async {
      final bad = png(4, 4);
      api.answer = () => ApiImage(png: Uint8List.sublistView(bad, 0, bad.length - 20));
      expect(await studio().run(req(), generate: true), 1);
      expect(file().existsSync(), isFalse);
      expect(File('${file().path}.part').existsSync(), isFalse);
      expect(((manifest()['entries'] as List).single as Map)['status'], 'failed');
    });

    test('the manifest refuses a file that is not one', () async {
      File('${tmp.path}/qa/ai_image_tests/image_manifest.json')
        ..createSync(recursive: true)
        ..writeAsStringSync('{"something": "else"}');
      expect(await studio().run(req(), generate: true), 2);
      expect(api.calls, 0);
    });
  });

  group("the API's answer", () {
    test('an error: its status, type, code and message', () {
      expect(
        () => OpenAiImageApi.parseResponse(400, jsonEncode({'error': {'message': 'Invalid size', 'type': 'invalid_request_error', 'code': 'invalid_value'}})),
        throwsA(isA<ApiFailure>().having((e) => (e.status, e.type, e.code, e.message), 'what', (400, 'invalid_request_error', 'invalid_value', 'Invalid size'))),
      );
      expect(() => OpenAiImageApi.parseResponse(502, '<html>bad gateway'), throwsA(isA<ApiFailure>().having((e) => e.status, 'status', 502)));
      expect(() => OpenAiImageApi.parseResponse(200, '{"data": []}'), throwsA(isA<ApiFailure>()));
    });

    test('a picture: its bytes and usage', () {
      final a = OpenAiImageApi.parseResponse(200, jsonEncode({
        'created': 1,
        'data': [{'b64_json': base64Encode(png(2, 2))}],
        'usage': {'output_tokens': 10},
      }));
      expect(PngCheck.bytes(a.png).width, 2);
      expect(a.usage, {'output_tokens': 10});
    });
  });

  test("every style is the game's: a kind, a size the API takes, no text in the picture", () {
    for (final s in ImageStyles.all.values) {
      expect(['scene', 'character', 'object'], contains(s.kind));
      expect(ImageStudio(api: _FakeApi(), findKey: () => null).problems(ImageRequest(prompt: s.text, output: 'qa/x.png', size: s.size, background: s.background)), isEmpty, reason: s.id);
      expect(s.text, contains('No text'));
    }
  });
}

class _FakeApi implements ImageApi {
  int calls = 0;
  final bodies = <Map<String, Object?>>[];

  /// The next answer (null: a 1536x1024 picture).
  ApiImage Function()? answer;

  @override
  Future<ApiImage> generate(Map<String, Object?> body, ApiKey key) async {
    calls++;
    bodies.add(body);
    return (answer ?? () => ApiImage(png: _png1536))();
  }
}

/// A 1536x1024 picture, made once.
final Uint8List _png1536 = _png(1536, 1024);

/// A real PNG of [w]×[h] RGB pixels.
Uint8List _png(int w, int h) {
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
    if (i % (w * 3 + 1) != 0) raw[i] = (i * 7) & 0xFF; // each row's filter byte stays 0
  }
  return Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10, ...chunk('IHDR', ihdr), ...chunk('IDAT', ZLibEncoder().convert(raw)), ...chunk('IEND', [])]);
}
