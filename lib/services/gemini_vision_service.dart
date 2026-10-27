import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiVisionService {
  // ═══════════════════════════════════════════
  // Singleton
  // ═══════════════════════════════════════════
  GeminiVisionService._();
  static final GeminiVisionService instance = GeminiVisionService._();

  // ═══════════════════════════════════════════
  // ⚠️ ضع مفتاح Gemini هنا
  // ═══════════════════════════════════════════
  const String _apiKey = 'YOUR_GEMINI_API_KEY_HERE';

  // ═══════════════════════════════════════════
  // النموذج (Flash = سريع ومجاني)
  // ═══════════════════════════════════════════
  GenerativeModel? _model;

  void _initModel() {
    if (_model != null) return;
    _model = GenerativeModel(
  model: 'gemini-3.8-flash',
  apiKey: _apiKey,
);
  }

  // ═══════════════════════════════════════════
  // تحليل صورة الشارت
  // ═══════════════════════════════════════════
  Future<ChartAnalysisResult> analyzeChart(File imageFile) async {
    try {
      _initModel();

      // قراءة الصورة
      final imageBytes = await imageFile.readAsBytes();

      // البرومبت (التعليمات للـ AI)
      const prompt = '''
You are a professional Forex and Crypto trading analyst with 10+ years of experience.

Analyze the attached trading chart image carefully and provide a trading signal.

Your response MUST be in this EXACT JSON format (no extra text):
{
  "signal": "CALL" or "PUT" or "WAIT",
  "confidence": 0-100,
  "timeframe": "1M" or "5M" or "15M" or "1H" or "unknown",
  "reason": "Brief explanation in Arabic (2-3 sentences max)"
}

Analysis Rules:
1. CALL (Buy):
   - Bullish trend on the chart
   - RSI crossing up from oversold (<30)
   - Price broke resistance upward
   - Bullish candlestick patterns (Hammer, Engulfing)

2. PUT (Sell):
   - Bearish trend on the chart
   - RSI crossing down from overbought (>70)
   - Price broke support downward
   - Bearish candlestick patterns (Shooting Star, Engulfing)

3. WAIT:
   - Unclear trend
   - Sideways market
   - Low confidence
   - Insufficient chart data

Confidence scoring:
- 80-100: Very strong signal (multiple confirmations)
- 60-79: Good signal (2 confirmations)
- 40-59: Weak signal (1 confirmation)
- 0-39: Very weak / unreliable

IMPORTANT:
- Answer ONLY in the JSON format specified
- No markdown, no code blocks, no extra text
- Explanation MUST be in Arabic
''';

      // إرسال الطلب
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/png', imageBytes),
        ]),
      ];

      final response = await _model!.generateContent(content);
      final text = response.text ?? '';

      debugPrint('📥 Gemini response: $text');

      // استخراج JSON من الرد
      return _parseResponse(text);

    } catch (e, stack) {
      debugPrint('❌ Gemini error: $e');
      debugPrint('📚 $stack');
      return ChartAnalysisResult.error('فشل التحليل: ${e.toString()}');
    }
  }

  // ═══════════════════════════════════════════
  // استخراج JSON من الرد
  // ═══════════════════════════════════════════
  ChartAnalysisResult _parseResponse(String text) {
    try {
      // تنظيف الرد (إزالة أي نص إضافي)
      String cleanText = text.trim();

      // إزالة علامات markdown إذا وُجدت
      cleanText = cleanText.replaceAll('```json', '');
      cleanText = cleanText.replaceAll('```', '');
      cleanText = cleanText.trim();

      // إيجاد JSON
      final start = cleanText.indexOf('{');
      final end = cleanText.lastIndexOf('}');

      if (start == -1 || end == -1) {
        return ChartAnalysisResult.error('لم يتم استلام رد صحيح من AI');
      }

      final jsonString = cleanText.substring(start, end + 1);
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;

      return ChartAnalysisResult(
        signal: jsonData['signal'] ?? 'WAIT',
        confidence: (jsonData['confidence'] as num?)?.toInt() ?? 0,
        timeframe: jsonData['timeframe'] ?? 'unknown',
        reason: jsonData['reason'] ?? 'لا يوجد تحليل',
      );
    } catch (e) {
      debugPrint('❌ Parse error: $e');
      return ChartAnalysisResult.error('خطأ في قراءة الرد');
    }
  }
}

// ═══════════════════════════════════════════
// نموذج النتيجة
// ═══════════════════════════════════════════
class ChartAnalysisResult {
  final String signal;      // CALL / PUT / WAIT
  final int confidence;     // 0-100
  final String timeframe;   // 1M, 5M...
  final String reason;      // سبب
  final String? error;      // إذا كان هناك خطأ

  ChartAnalysisResult({
    required this.signal,
    required this.confidence,
    required this.timeframe,
    required this.reason,
    this.error,
  });

  factory ChartAnalysisResult.error(String message) {
    return ChartAnalysisResult(
      signal: 'ERROR',
      confidence: 0,
      timeframe: 'unknown',
      reason: message,
      error: message,
    );
  }

  bool get isError => error != null;
  bool get isCall => signal == 'CALL';
  bool get isPut => signal == 'PUT';
  bool get isWait => signal == 'WAIT';
}