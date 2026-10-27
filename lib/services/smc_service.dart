import '../models/models.dart';
import '../utils/indicators.dart';

/// خدمة تحليل Smart Money Concepts
class SMCService {
  SMCService._();
  static final SMCService instance = SMCService._();

  /// تحليل SMC لزوج واحد
  Future<SMCAnalysis?> analyze({required String symbol}) async {
    final candles = await fetchCandles(symbol: symbol, limit: 100);
    if (candles == null || candles.length < 20) return null;

    return analyzeSMC(candles);
  }

  /// تحليل دفعة
  Future<Map<String, SMCAnalysis>> analyzeBatch({
    required List<Map<String, String>> pairs,
    Function(int done, int total)? onProgress,
  }) async {
    final results = <String, SMCAnalysis>{};
    for (int i = 0; i < pairs.length; i++) {
      final pair = pairs[i];
      final analysis = await analyze(symbol: pair['symbol']!);
      if (analysis != null) {
        results[pair['name']!] = analysis;
      }
      onProgress?.call(i + 1, pairs.length);
    }
    return results;
  }

  /// الحصول على ملخص نصي
  String getSummary(SMCAnalysis smc) {
    final lines = <String>[];

    // الاتجاه
    switch (smc.trend) {
      case 'bullish':
        lines.add('📈 الاتجاه: صاعد');
        break;
      case 'bearish':
        lines.add('📉 الاتجاه: هابط');
        break;
      default:
        lines.add('➡️ الاتجاه: جانبي');
    }

    // الميل
    switch (smc.bias) {
      case 'long':
        lines.add('🟢 الميل: شراء (Long)');
        break;
      case 'short':
        lines.add('🔴 الميل: بيع (Short)');
        break;
      default:
        lines.add('⏸️ الميل: محايد');
    }

    lines.add('');
    lines.add('📊 الإشارات المكتشفة:');
    lines.add('• Order Blocks: ${smc.orderBlocks.length}');
    lines.add('• Fair Value Gaps: ${smc.fvgs.length}');
    lines.add('• Structure Breaks: ${smc.structureBreaks.length}');
    lines.add('• Liquidity Zones: ${smc.liquidityZones.length}');

    return lines.join('\n');
  }
}