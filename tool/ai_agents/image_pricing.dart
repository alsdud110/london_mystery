/// OpenAI's list prices for the GPT image models, per 1M tokens, as the
/// pricing page gave them on 2026-10-29 (https://developers.openai.com/api/docs/pricing).
/// The bill is OpenAI's: these only estimate a request before it is sent and
/// price the `usage` a response reports.
class TokenRates {
  const TokenRates({required this.textIn, required this.imageIn, required this.imageOut});

  final double textIn;
  final double imageIn;
  final double imageOut;
}

/// What a request is expected to cost, and what its usage cost.
abstract final class ImagePricing {
  static const checkedOn = '2026-10-29';

  static const rates = <String, TokenRates>{
    'gpt-image-2.5-sunburst': TokenRates(textIn: 5, imageIn: 8, imageOut: 30),
    'gpt-image-2.5-flare': TokenRates(textIn: 5, imageIn: 8, imageOut: 30),
    'gpt-image-2': TokenRates(textIn: 5, imageIn: 8, imageOut: 30),
    'gpt-image-1.5': TokenRates(textIn: 5, imageIn: 8, imageOut: 32),
    'gpt-image-1-mini': TokenRates(textIn: 2, imageIn: 2.5, imageOut: 8),
  };

  /// The rates of [model], a dated snapshot (`gpt-image-2-2026-04-21`) read as its model.
  static TokenRates? ratesOf(String model) =>
      rates[model] ?? rates[model.replaceFirst(RegExp(r'-\d{4}-\d{2}-\d{2}$'), '')];

  /// The output tokens of one image of the models before gpt-image-2, by
  /// quality and shape (the image generation guide's table). OpenAI gives
  /// gpt-image-2's and 2.5's only through its calculator: for them this is
  /// an estimate, never their count.
  static const _outputTokens = {
    'low': (square: 272, portrait: 408, landscape: 400),
    'medium': (square: 1056, portrait: 1584, landscape: 1568),
    'high': (square: 4160, portrait: 6240, landscape: 6208),
  };

  /// The output tokens [size] and [quality] are estimated at: `auto` (and the
  /// 2.5 models' `xhigh`, `max`) as `high` at least; a size of another area
  /// in proportion to its shape's.
  static int estimatedOutputTokens(String size, String quality) {
    final row = _outputTokens[quality] ?? _outputTokens['high']!;
    if (size == 'auto') return row.landscape;
    final [w, h] = size.split('x').map(int.parse).toList();
    final (base, area) = w == h ? (row.square, 1024 * 1024) : w > h ? (row.landscape, 1536 * 1024) : (row.portrait, 1024 * 1536);
    final scale = (w * h) / area;
    final tokens = (base * scale).ceil();
    return switch (quality) { 'xhigh' || 'max' => tokens * 2, _ => tokens };
  }

  /// A prompt's text tokens, roughly: four characters a token.
  static int estimatedTextTokens(String prompt) => (prompt.length / 4).ceil();

  /// The input tokens one reference picture (the image edits endpoint) is
  /// estimated at. OpenAI gives no count for gpt-image-2, which reads every
  /// input picture at high fidelity: this is an upper bound taken on
  /// purpose, the earlier models' high-fidelity extra for a 1536×1024
  /// picture (6,240) plus its base vision tokens (~1,105), rounded up.
  static const referenceImageTokens = 8000;

  /// The estimated cost in US dollars of one image, or null for a model
  /// with no rates here. [references]: the pictures sent with it to draw
  /// from, each priced as [referenceImageTokens] of image input.
  static double? estimate({required String model, required String size, required String quality, required String prompt, int n = 1, int references = 0}) {
    final r = ratesOf(model);
    if (r == null) return null;
    return n * estimatedOutputTokens(size, quality) * r.imageOut / 1e6 +
        estimatedTextTokens(prompt) * r.textIn / 1e6 +
        references * referenceImageTokens * r.imageIn / 1e6;
  }

  /// What a response's `usage` costs at list prices, or null without rates or usage.
  static double? ofUsage(String model, Map<String, Object?>? usage) {
    final r = ratesOf(model);
    if (r == null || usage == null) return null;
    int n(Object? v) => v is num ? v.toInt() : 0;
    final details = usage['input_tokens_details'];
    final input = n(usage['input_tokens']);
    final text = details is Map ? n(details['text_tokens']) : input;
    final image = details is Map ? n(details['image_tokens']) : 0;
    return text * r.textIn / 1e6 + image * r.imageIn / 1e6 + n(usage['output_tokens']) * r.imageOut / 1e6;
  }

  /// [usd] to a millionth of a dollar, as it is recorded.
  static double? round(double? usd) => usd == null ? null : double.parse(usd.toStringAsFixed(6));

  /// [usd] as `$0.0471`.
  static String usd(double usd) => '\$${usd.toStringAsFixed(4)}';
}
