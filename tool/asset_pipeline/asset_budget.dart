import '../ai_agents/image_pricing.dart';

/// What one picture is expected to cost: the list-price estimate
/// (`ImagePricing`) and the conservative figure every limit is checked with.
class AssetCost {
  const AssetCost(this.estimatedUsd, this.conservativeUsd);

  final double estimatedUsd;
  final double conservativeUsd;
}

/// The money and calls one generating run may spend.
///
/// * A run without a budget never calls the API.
/// * Before a call: what was spent, plus the next picture's conservative
///   cost, must stay within the budget; the calls within [maxCalls].
/// * After a call: what its usage cost at list prices is spent; a call with
///   no usage, or one that failed (it may still be billed), is spent at its
///   conservative cost.
///
/// These are estimates from list prices: the bill is OpenAI's.
class AssetBudget {
  AssetBudget({required this.maxUsd, required this.maxCalls});

  /// gpt-image-2's output tokens are only estimated (OpenAI gives them in
  /// its calculator only), so every limit is checked at half as much again.
  static const safetyFactor = 1.5;

  /// Calls one run makes when `--max-calls` is not given.
  static const defaultMaxCalls = 3;

  /// The most calls one run may be given.
  static const maxCallsCeiling = 50;

  final double maxUsd;
  final int maxCalls;
  double spentUsd = 0;
  int calls = 0;

  double get remainingUsd => maxUsd - spentUsd;

  /// The cost of one picture, or null for a model with no list price
  /// (never made by the pipeline).
  static AssetCost? cost({required String model, required String size, required String quality, required String prompt, int references = 0}) {
    final e = ImagePricing.estimate(model: model, size: size, quality: quality, prompt: prompt, references: references);
    if (e == null) return null;
    return AssetCost(ImagePricing.round(e)!, ImagePricing.round(e * safetyFactor)!);
  }

  /// Why the next call, at [conservativeUsd], may not be made; null when it may.
  String? refusal(double conservativeUsd) {
    if (calls >= maxCalls) return 'the run\'s $maxCalls call(s) are made (--max-calls)';
    if (spentUsd + conservativeUsd > maxUsd + 1e-9) {
      return 'the next picture (${ImagePricing.usd(conservativeUsd)} conservative) would pass the budget: '
          '${ImagePricing.usd(spentUsd)} of ${ImagePricing.usd(maxUsd)} spent (--max-budget)';
    }
    return null;
  }

  /// A call made: [fromUsageUsd] spent, else [conservativeUsd].
  void charge({required double conservativeUsd, double? fromUsageUsd}) {
    calls++;
    spentUsd += fromUsageUsd ?? conservativeUsd;
  }
}
