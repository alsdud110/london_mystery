import 'dart:convert';
import 'dart:io';

import '../season_gen/sha256.dart';

/// What one picture is asked for: everything sent to the API that shapes it.
/// Its [key] names it: the same request is the same picture, never made twice.
class ImageRequest {
  const ImageRequest({
    required this.prompt,
    required this.output,
    this.model = 'gpt-image-2',
    this.size = '1536x1024',
    this.quality = 'medium',
    this.background = 'auto',
    this.styleId,
    this.subjectId,
    this.references = const [],
  });

  /// The whole prompt sent (the style's line already added).
  final String prompt;

  /// The PNG file to write, from the repository's root.
  final String output;
  final String model;
  final String size;
  final String quality;

  /// `auto`, `opaque` or `transparent`.
  final String background;

  /// The style its prompt was made with (`ImageStyles`), for the record.
  final String? styleId;

  /// What it shows, for a later picture of the same character or place to
  /// be drawn from it (`s3_rome.char.tour_guide`). For the record only now.
  final String? subjectId;

  /// Pictures to draw from, PNGs from the repository's root: sent to the
  /// image edits endpoint (STEP 3-12A), in this order.
  final List<String> references;

  Map<String, Object?> _shaping(String root) => {
    'model': model,
    'prompt': prompt,
    'size': size,
    'quality': quality,
    'background': background,
    'outputFormat': 'png',
    'references': [
      for (final r in references) File('$root/$r').existsSync() ? 'sha256:${Sha256.hex(File('$root/$r').readAsBytesSync())}' : r,
    ],
  };

  /// `sha256:` of what shapes the picture (not where it is written), its
  /// references read from the working directory.
  String get key => keyIn('.');

  /// [key], its references read from [root]: the same picture drawn from a
  /// changed reference is another request.
  String keyIn(String root) => 'sha256:${Sha256.hex(utf8.encode(jsonEncode(_shaping(root))))}';

  /// The API's request body (`/v1/images/generations`).
  Map<String, Object?> get body => {
    'model': model,
    'prompt': prompt,
    'n': 1,
    'size': size,
    'quality': quality,
    'output_format': 'png',
    if (background != 'auto') 'background': background,
  };

  /// The image edits endpoint's JSON body (`/v1/images/edits`): [body] with
  /// each reference as a PNG data URL in `images`, read from [root]. Only
  /// what the API reference lists for the GPT image models is sent: no
  /// `input_fidelity` (gpt-image-2 refuses it; it reads every input at high
  /// fidelity) and no `mask`.
  Map<String, Object?> editBody(String root) => {
    ...body,
    'images': [
      for (final r in references) {'image_url': 'data:image/png;base64,${base64Encode(File('$root/$r').readAsBytesSync())}'},
    ],
  };

  /// [editBody] as it may be shown: each picture's data replaced by its path.
  Map<String, Object?> get editBodyShown => {
    ...body,
    'images': [for (final r in references) {'image_url': 'data:image/png;base64,… ($r)'}],
  };
}

/// Every picture asked for in a folder and what came of it, oldest first:
/// `image_manifest.json` beside the pictures. Holds no key and no secret:
/// only what was asked, when, what was written and what it cost.
class ImageManifest {
  ImageManifest._(this.path, this.entries);

  static const schemaVersion = 1;
  static const fileName = 'image_manifest.json';

  final String path;
  final List<Map<String, Object?>> entries;

  /// The manifest at [path] (a new one when there is none).
  static ImageManifest load(String path) {
    final f = File(path);
    if (!f.existsSync()) return ImageManifest._(path, []);
    final json = jsonDecode(f.readAsStringSync());
    if (json is! Map || json['schemaVersion'] != schemaVersion || json['entries'] is! List) {
      throw FormatException('$path: not an image manifest (schemaVersion $schemaVersion)');
    }
    return ImageManifest._(path, [for (final e in json['entries'] as List) (e as Map).cast<String, Object?>()]);
  }

  /// The entry of [key] that made a picture, if one did.
  Map<String, Object?>? generated(String key) {
    for (final e in entries.reversed) {
      if (e['key'] == key && e['status'] == 'generated') return e;
    }
    return null;
  }

  /// How many times the API was called for [key] (failed calls too).
  int callsFor(String key) => entries.where((e) => e['key'] == key && e['apiCalled'] == true).length;

  void add(Map<String, Object?> entry) => entries.add(entry);

  /// The totals: API calls, pictures made, calls that failed, and their cost from usage.
  Map<String, Object?> get totals {
    final called = entries.where((e) => e['apiCalled'] == true).toList();
    final cost = called.fold<double>(0, (s, e) => s + (((e['cost'] as Map?)?['fromUsageUsd'] as num?)?.toDouble() ?? 0));
    return {
      'apiCalls': called.length,
      'generated': entries.where((e) => e['status'] == 'generated').length,
      'failed': entries.where((e) => e['status'] == 'failed').length,
      'fromUsageUsd': double.parse(cost.toStringAsFixed(6)),
    };
  }

  /// Written whole beside itself, then moved over the old one.
  void save() {
    final f = File(path)..parent.createSync(recursive: true);
    final part = File('$path.part');
    part.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert({'schemaVersion': schemaVersion, 'totals': totals, 'entries': entries})}\n',
      flush: true,
    );
    part.renameSync(f.path);
  }
}
