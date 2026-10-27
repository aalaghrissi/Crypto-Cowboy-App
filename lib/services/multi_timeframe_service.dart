import '../utils/indicators.dart';

/// نتيجة تحليل MTF
class MTFResult {
  final String symbol;
  final String pairName;
  final List<TimeframeSignal> signals;
  final String finalSignal;
  final int alignment;
  final int strength;

  MTFResult({
    required this.symbol,
    required this.pairName,
    required this.signals,
    required this.finalSignal,
    required this.alignment,
    required this.strength,
  });

  bool get isStrong => strength >= 4;
  bool get isReliable => alignment >= 3;
}

class MultiTimeframeService {
  MultiTimeframeService._();
  static final MultiTimeframeService instance = MultiTimeframeService._();

  /// تحليل زوج واحد
  Future<MTFResult> analyzePair({
    required String symbol,
    required String pairName,
    int scoreThreshold = 2,
  }) async {
    final signals = await analyzeMultipleTimeframes(
      symbol: symbol,
      scoreThreshold: scoreThreshold,
    );

    final alignment = calculateAlignment(signals);
    final strength = calculateStrength(alignment);
    final finalSignal = getFinalSignal(signals);

    return MTFResult(
      symbol: symbol,
      pairName: pairName,
      signals: signals,
      finalSignal: finalSignal,
      alignment: alignment,
      strength: strength,
    );
  }

  /// تحليل دفعة (بالتوازي)
  Future<List<MTFResult>> analyzeBatch({
    required List<Map<String, String>> pairs,
    int scoreThreshold = 2,
    Function(int done, int total)? onProgress,
  }) async {
    final results = <MTFResult>[];
    for (int i = 0; i < pairs.length; i++) {
      final pair = pairs[i];
      final result = await analyzePair(
        symbol: pair['symbol']!,
        pairName: pair['name']!,
        scoreThreshold: scoreThreshold,
      );
      results.add(result);
      onProgress?.call(i + 1, pairs.length);
    }

    // ترتيب حسب القوة
    results.sort((a, b) => b.strength.compareTo(a.strength));
    return results;
  }
}