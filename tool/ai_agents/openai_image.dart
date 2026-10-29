import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import '../season_gen/sha256.dart';
import 'env_file.dart';
import 'image_manifest.dart';
import 'image_pricing.dart';
import 'image_styles.dart';
import 'png_check.dart';

/// Makes a picture with OpenAI's Image API (STEP 3-10): one request, checked,
/// priced, then (only with `--generate`) sent once, its PNG checked whole and
/// written, and the whole of it recorded in the folder's `image_manifest.json`.
///
///     dart run tool/ai_agents/openai_image.dart --prompt "..." --output qa/ai_image_tests/x.png
///         [--style london_scene] [--model gpt-image-2] [--size 1536x1024] [--quality medium]
///         [--background auto|opaque|transparent] [--subject <id>] [--reference <png>]...
///         [--manifest <json>] [--budget-usd 0.25] [--env .env] [--overwrite] [--generate]
///
/// * Without `--generate` nothing is sent and nothing written (a dry run):
///   the request and its estimated cost are printed.
/// * One picture a run; a failed call is never sent again by itself (run the
///   command again). A request already made (the same model, prompt, size,
///   quality, background), its file still as it was written, is not sent again.
/// * An existing file is never written over without `--overwrite`.
/// * The key is read from the environment's `OPENAI_API_KEY`, else `.env`
///   (never written); it is never printed or recorded, and any key-like text
///   in an API error is redacted.
///
/// Exit codes: 0 made, already made or dry run; 1 the API or its picture
/// failed; 2 the request was refused before anything was sent; 64 usage.
Future<void> main(List<String> args) async {
  final a = _Args.parse(args);
  if (a == null) {
    stderr.writeln('usage: dart run tool/ai_agents/openai_image.dart --prompt <text> --output <file.png> '
        '[--style ${ImageStyles.all.keys.join('|')}] [--model gpt-image-2] [--size 1536x1024] [--quality medium] '
        '[--background auto|opaque|transparent] [--subject <id>] [--reference <png>]... [--manifest <json>] '
        '[--budget-usd 0.25] [--env .env] [--overwrite] [--generate]');
    exit(64);
  }
  final style = a.style == null ? null : ImageStyles.all[a.style];
  if (a.style != null && style == null) {
    stderr.writeln('--style ${a.style}: not one of ${ImageStyles.all.keys.join(', ')}');
    exit(64);
  }
  final request = ImageRequest(
    prompt: style == null ? a.prompt! : '${a.prompt!.trim()}\n\n${style.text}',
    output: a.output!,
    model: a.model,
    size: a.size ?? style?.size ?? '1536x1024',
    quality: a.quality,
    background: a.background ?? style?.background ?? 'auto',
    styleId: style?.id,
    subjectId: a.subject,
    references: a.references,
  );
  final code = await ImageStudio(
    api: OpenAiImageApi(),
    findKey: () => ApiKey.find(envPath: a.envPath),
  ).run(request, generate: a.generate, overwrite: a.overwrite, budgetUsd: a.budgetUsd, manifestPath: a.manifest);
  exit(code);
}

class _Args {
  String? prompt, output, style, size, background, subject, manifest;
  String model = 'gpt-image-2', quality = 'medium', envPath = '.env';
  double budgetUsd = 0.25;
  bool generate = false, overwrite = false;
  final references = <String>[];

  static _Args? parse(List<String> args) {
    final a = _Args();
    for (var i = 0; i < args.length; i++) {
      String next() => i + 1 < args.length ? args[++i] : throw const FormatException();
      try {
        switch (args[i]) {
          case '--prompt':
            a.prompt = next();
          case '--output':
            a.output = next();
          case '--style':
            a.style = next();
          case '--model':
            a.model = next();
          case '--size':
            a.size = next();
          case '--quality':
            a.quality = next();
          case '--background':
            a.background = next();
          case '--subject':
            a.subject = next();
          case '--reference':
            a.references.add(next());
          case '--manifest':
            a.manifest = next();
          case '--env':
            a.envPath = next();
          case '--budget-usd':
            a.budgetUsd = double.parse(next());
          case '--generate':
            a.generate = true;
          case '--overwrite':
            a.overwrite = true;
          default:
            return null;
        }
      } on FormatException {
        return null;
      }
    }
    return a.prompt == null || a.output == null ? null : a;
  }
}

/// What the API sent back for one picture.
class ApiImage {
  const ApiImage({required this.png, this.usage, this.created, this.revisedPrompt});

  final Uint8List png;
  final Map<String, Object?>? usage;
  final int? created;
  final String? revisedPrompt;
}

/// The API refused or failed a request: its HTTP status (null when no answer
/// came) and its error, as OpenAI gave it (a key in it redacted when shown).
class ApiFailure implements Exception {
  const ApiFailure(this.message, {this.status, this.type, this.code});

  final String message;
  final int? status;
  final String? type;
  final String? code;

  Map<String, Object?> toJson(String Function(String) redact) =>
      {'status': ?status, 'type': ?type, 'code': ?code, 'message': redact(message)};

  @override
  String toString() => 'ApiFailure(${status ?? 'no answer'}${type == null ? '' : ' $type'}${code == null ? '' : ' $code'}): $message';
}

/// Sends one request to the Image API.
abstract interface class ImageApi {
  Future<ApiImage> generate(Map<String, Object?> body, ApiKey key);
}

/// OpenAI's `POST /v1/images/generations`, once: no retry.
class OpenAiImageApi implements ImageApi {
  OpenAiImageApi({this.endpoint = 'https://api.openai.com/v1/images/generations', this.timeout = const Duration(minutes: 5)});

  final String endpoint;
  final Duration timeout;

  @override
  Future<ApiImage> generate(Map<String, Object?> body, ApiKey key) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 30);
    try {
      final req = await client.postUrl(Uri.parse(endpoint));
      req.headers.set(HttpHeaders.authorizationHeader, 'Bearer ${key.bearer}');
      req.headers.contentType = ContentType.json;
      req.add(utf8.encode(jsonEncode(body)));
      final res = await req.close().timeout(timeout);
      final text = await res.transform(utf8.decoder).join().timeout(timeout);
      return parseResponse(res.statusCode, text);
    } on TimeoutException {
      throw ApiFailure('no answer within ${timeout.inSeconds}s');
    } on SocketException catch (e) {
      throw ApiFailure('network: ${e.message}');
    } on HttpException catch (e) {
      throw ApiFailure('http: ${e.message}');
    } finally {
      client.close(force: true);
    }
  }

  /// The answer of [status] with body [text]: the picture, or an [ApiFailure].
  static ApiImage parseResponse(int status, String text) {
    Object? json;
    try {
      json = jsonDecode(text);
    } on FormatException {
      throw ApiFailure('not JSON (${text.length} bytes)', status: status);
    }
    if (status != 200 || json is! Map) {
      final e = json is Map && json['error'] is Map ? json['error'] as Map : const {};
      throw ApiFailure('${e['message'] ?? 'HTTP $status'}', status: status, type: e['type'] as String?, code: e['code']?.toString());
    }
    final data = json['data'];
    final first = data is List && data.isNotEmpty && data.first is Map ? data.first as Map : null;
    final b64 = first?['b64_json'];
    if (b64 is! String) throw ApiFailure('no image in the answer', status: status);
    return ApiImage(
      png: base64Decode(b64),
      usage: json['usage'] is Map ? (json['usage'] as Map).cast<String, Object?>() : null,
      created: json['created'] as int?,
      revisedPrompt: first?['revised_prompt'] as String?,
    );
  }
}

/// One picture asked for, checked, sent and recorded.
class ImageStudio {
  ImageStudio({required this.api, required this.findKey, this.root = '.', void Function(String)? log, DateTime Function()? now})
      : log = log ?? stdout.writeln,
        now = now ?? DateTime.now;

  final ImageApi api;

  /// The API key, looked for only when it is needed.
  final ApiKey? Function() findKey;
  final String root;
  final void Function(String) log;
  final DateTime Function() now;

  static const maxPromptLength = 32000;
  static const qualities = {'low', 'medium', 'high', 'auto', 'xhigh', 'max'};
  static const backgrounds = {'auto', 'opaque', 'transparent'};

  /// What is wrong with [r] before anything is sent.
  List<String> problems(ImageRequest r) {
    final out = <String>[];
    final prompt = r.prompt.trim();
    if (prompt.isEmpty) out.add('prompt: empty');
    if (r.prompt.length > maxPromptLength) out.add('prompt: ${r.prompt.length} characters (at most $maxPromptLength)');
    if (RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]').hasMatch(r.prompt)) out.add('prompt: control characters');
    out.addAll(outputProblems(r.output));
    if (!RegExp(r'^gpt-image-[a-z0-9.\-]+$|^chatgpt-image-latest$').hasMatch(r.model)) out.add('model: ${r.model} is not a GPT image model');
    if (!qualities.contains(r.quality)) out.add('quality: ${r.quality} (${qualities.join(', ')})');
    if (!backgrounds.contains(r.background)) out.add('background: ${r.background} (${backgrounds.join(', ')})');
    final size = RegExp(r'^(\d+)x(\d+)$').firstMatch(r.size);
    if (r.size != 'auto') {
      if (size == null) {
        out.add('size: ${r.size} (WIDTHxHEIGHT or auto)');
      } else {
        final (w, h) = (int.parse(size[1]!), int.parse(size[2]!));
        if (w % 16 != 0 || h % 16 != 0) out.add('size: ${r.size}: width and height must be multiples of 16');
        if (w > 3840 || h > 3840) out.add('size: ${r.size}: an edge of at most 3840');
        if (w > 3 * h || h > 3 * w) out.add('size: ${r.size}: at most 3:1');
      }
    }
    for (final ref in r.references) {
      if (!File('$root/$ref').existsSync()) out.add('reference: $ref is not on disk');
    }
    if (r.references.isNotEmpty) out.add('reference: drawing from reference pictures (the image edits endpoint) is not made yet');
    return out;
  }

  /// What is wrong with writing a picture at [output]: a PNG in the
  /// repository, never in `lib/` (the app) or `assets/` (the game's pictures
  /// are registered by a later step).
  List<String> outputProblems(String output) {
    final out = <String>[];
    final rel = output.replaceAll(r'\', '/');
    if (!rel.toLowerCase().endsWith('.png')) out.add('output: $output is not a .png');
    final rootAbs = Directory(root).absolute.uri.normalizePath().path;
    final abs = File('$root/$rel').absolute.uri.normalizePath().path;
    if (File(rel).isAbsolute || !abs.startsWith(rootAbs) || rel.split('/').contains('..')) {
      out.add('output: $output is not inside the repository');
    } else {
      final inRepo = abs.substring(rootAbs.length);
      if (inRepo.startsWith('lib/')) out.add('output: $output is in lib/ (the app)');
      if (inRepo.startsWith('assets/')) out.add("output: $output is in assets/ (the game's pictures are not written here yet)");
    }
    return out;
  }

  /// Runs [r]: the exit code (see `main`).
  Future<int> run(ImageRequest r, {bool generate = false, bool overwrite = false, double budgetUsd = 0.25, String? manifestPath}) async {
    final problems = this.problems(r);
    if (problems.isNotEmpty) {
      for (final p in problems) {
        log('error    $p');
      }
      log('nothing sent');
      return 2;
    }
    final rel = r.output.replaceAll(r'\', '/');
    final file = File('$root/$rel');
    final manifestRel = manifestPath ?? '${File(rel).parent.path.replaceAll(r'\', '/')}/${ImageManifest.fileName}';
    final ImageManifest manifest;
    try {
      manifest = ImageManifest.load('$root/$manifestRel');
    } on FormatException catch (e) {
      log('error    ${e.message}');
      return 2;
    }
    final key = r.key;

    // The same picture made before, its file as it was written: not again.
    final made = manifest.generated(key);
    if (made != null && file.existsSync() && (made['file'] as Map?)?['sha256'] == 'sha256:${Sha256.hex(file.readAsBytesSync())}') {
      log('ok       already made: $rel (${made['completedAt']}); nothing sent');
      return 0;
    }
    if (file.existsSync() && !overwrite) {
      log('error    $rel exists: never written over (--overwrite)');
      log('nothing sent');
      return 2;
    }

    final estimate = ImagePricing.round(ImagePricing.estimate(model: r.model, size: r.size, quality: r.quality, prompt: r.prompt));
    log('request  ${r.model}, ${r.size}, quality ${r.quality}, background ${r.background}, 1 image${r.styleId == null ? '' : ', style ${r.styleId}'}');
    log('output   $rel  (manifest $manifestRel)');
    log('cost     ${estimate == null ? 'unknown (no list prices for ${r.model})' : '${ImagePricing.usd(estimate)} estimated'}'
        ' — an estimate from the list prices of ${ImagePricing.checkedOn}; the bill is OpenAI\'s');
    if (estimate == null || estimate > budgetUsd) {
      log('error    ${estimate == null ? 'cost unknown' : 'estimate over --budget-usd ${ImagePricing.usd(budgetUsd)}'}: not sent');
      return 2;
    }
    final apiKey = findKey();
    if (!generate) {
      log('dry run  ${const JsonEncoder.withIndent('  ').convert({...r.body, 'prompt': '(${r.prompt.length} characters)'})}');
      log('dry run  API key ${apiKey == null ? 'NOT found (OPENAI_API_KEY in the environment or .env)' : 'found'}; '
          'nothing sent, nothing written (--generate to make it)');
      return 0;
    }
    if (apiKey == null) {
      log('error    no API key: OPENAI_API_KEY is in neither the environment nor the .env file');
      log('nothing sent');
      return 2;
    }

    final started = now().toUtc();
    final entry = <String, Object?>{
      'key': key,
      'output': rel,
      'model': r.model,
      'size': r.size,
      'quality': r.quality,
      'background': r.background,
      'outputFormat': 'png',
      'style': ?r.styleId,
      'subject': ?r.subjectId,
      'references': r.references,
      'prompt': r.prompt,
      'requestedAt': started.toIso8601String(),
      'apiCalled': true,
      'callNumber': manifest.callsFor(key) + 1,
    };
    void record(String status) {
      final ended = now().toUtc();
      entry['status'] = status;
      entry['completedAt'] = ended.toIso8601String();
      entry['durationMs'] = ended.difference(started).inMilliseconds;
      manifest.add(entry);
      manifest.save();
    }

    log('sending  one request (no retry)…');
    final ApiImage image;
    try {
      image = await api.generate(r.body, apiKey);
    } on ApiFailure catch (e) {
      entry['error'] = e.toJson(apiKey.redact);
      entry['cost'] = {'estimatedUsd': estimate, 'fromUsageUsd': null, 'note': 'failed: billed only if OpenAI made the image'};
      record('failed');
      log('FAILED   ${apiKey.redact(e.toString())}');
      log('nothing written but the manifest; run the command again to retry');
      return 1;
    }
    final fromUsage = ImagePricing.round(ImagePricing.ofUsage(r.model, image.usage));
    entry['usage'] = image.usage;
    entry['cost'] = {
      'estimatedUsd': estimate,
      'fromUsageUsd': fromUsage,
      'note': 'fromUsage: the response\'s usage at the list prices of ${ImagePricing.checkedOn}; the bill is OpenAI\'s',
    };
    if (image.created != null) entry['apiCreated'] = image.created;
    if (image.revisedPrompt != null) entry['revisedPrompt'] = image.revisedPrompt;

    final PngInfo info;
    try {
      info = PngCheck.bytes(image.png);
    } on PngProblem catch (e) {
      entry['error'] = {'message': e.toString()};
      record('failed');
      log('FAILED   the answer\'s image: $e; nothing written but the manifest');
      return 1;
    }
    // Written beside its place, read back whole, then moved there.
    file.parent.createSync(recursive: true);
    final part = File('${file.path}.part');
    part.writeAsBytesSync(image.png, flush: true);
    try {
      PngCheck.file(part.path);
    } on PngProblem catch (e) {
      part.deleteSync();
      entry['error'] = {'message': 'written file: $e'};
      record('failed');
      log('FAILED   the written file: $e');
      return 1;
    }
    part.renameSync(file.path);
    final sizeAsked = r.size == 'auto' ? null : r.size;
    entry['file'] = {
      'bytes': image.png.length,
      'sha256': 'sha256:${Sha256.hex(image.png)}',
      ...info.toJson(),
      'sizeAsAsked': sizeAsked == null || sizeAsked == '${info.width}x${info.height}',
    };
    record('generated');
    log('wrote    $rel  ${info.width}x${info.height}, ${info.hasAlpha ? 'RGBA' : 'no alpha'}, ${image.png.length} bytes');
    log('cost     ${fromUsage == null ? 'no usage in the answer' : '${ImagePricing.usd(fromUsage)} from usage ${jsonEncode(image.usage)}'}');
    return 0;
  }
}
