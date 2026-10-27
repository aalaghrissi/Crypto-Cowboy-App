import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../constants/translations.dart';

/// خدمة المساعد الصوتي
class VoiceService {
  VoiceService._();
  static final VoiceService instance = VoiceService._();

  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;

  // ═══════════════════════════════════════════
  // التهيئة
  // ═══════════════════════════════════════════
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await _tts.setLanguage('ar-SA');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);

      _tts.setStartHandler(() => _isSpeaking = true);
      _tts.setCompletionHandler(() => _isSpeaking = false);
      _tts.setCancelHandler(() => _isSpeaking = false);
      _tts.setErrorHandler((msg) {
        debugPrint('❌ TTS error: $msg');
        _isSpeaking = false;
      });

      _isInitialized = true;
      debugPrint('✅ VoiceService initialized');
    } catch (e) {
      debugPrint('❌ VoiceService init error: $e');
    }
  }

  // ═══════════════════════════════════════════
  // تغيير اللغة
  // ═══════════════════════════════════════════
  Future<void> setLanguage(String lang) async {
    try {
      switch (lang) {
        case 'ar':
          await _tts.setLanguage('ar-SA');
          break;
        case 'en':
          await _tts.setLanguage('en-US');
          break;
        case 'fr':
          await _tts.setLanguage('fr-FR');
          break;
        case 'ru':
          await _tts.setLanguage('ru-RU');
          break;
        default:
          await _tts.setLanguage('en-US');
      }
    } catch (e) {
      debugPrint('❌ Set language error: $e');
    }
  }

  // ═══════════════════════════════════════════
  // نطق نص
  // ═══════════════════════════════════════════
  Future<void> speak(String text) async {
    if (!_isInitialized) await init();
    if (_isSpeaking) await stop();

    try {
      await _tts.speak(text);
    } catch (e) {
      debugPrint('❌ Speak error: $e');
    }
  }

  // ═══════════════════════════════════════════
  // إيقاف
  // ═══════════════════════════════════════════
  Future<void> stop() async {
    try {
      await _tts.stop();
      _isSpeaking = false;
    } catch (e) {
      debugPrint('❌ Stop error: $e');
    }
  }

  // ═══════════════════════════════════════════
  // نطق إشارة جديدة
  // ═══════════════════════════════════════════
  Future<void> announceSignal({
    required String pair,
    required String signal,
    required double price,
    required int confidence,
    required String grade,
  }) async {
    final isCall = signal == 'CALL';
    final priceStr = price.toStringAsFixed(price > 100 ? 2 : 4);

    final text = isCall
        ? 'إشارة شراء على $pair. السعر $priceStr. الثقة $confidence بالمئة. التصنيف $grade'
        : 'إشارة بيع على $pair. السعر $priceStr. الثقة $confidence بالمئة. التصنيف $grade';

    await speak(text);
  }

  // ═══════════════════════════════════════════
  // نطق تنبيه السعر
  // ═══════════════════════════════════════════
  Future<void> announcePriceAlert({
    required String pair,
    required String condition,
    required double currentValue,
    required double targetValue,
  }) async {
    final text =
        'تنبيه على $pair. $condition. القيمة الحالية ${currentValue.toStringAsFixed(4)}';
    await speak(text);
  }

  // ═══════════════════════════════════════════
  // نطق التوصية الحالية (Time DNA)
  // ═══════════════════════════════════════════
  Future<void> announceTimeAdvice({
    required String advice,
    required double winRate,
  }) async {
    final text = '$advice. معدل نجاحك في هذا الوقت $winRate بالمئة';
    await speak(text);
  }

  // ═══════════════════════════════════════════
  // نطق ملخص الإشارات
  // ═══════════════════════════════════════════
  Future<void> announceSummary({
    required int calls,
    required int puts,
    required int total,
  }) async {
    final text = 'ملخص اليوم. إجمالي الإشارات $total. شراء $calls. بيع $puts';
    await speak(text);
  }

  // ═══════════════════════════════════════════
  // اختبار الصوت
  // ═══════════════════════════════════════════
  Future<void> testVoice() async {
    final text = Translation.language == 'ar'
        ? 'مرحباً، أنا المساعد الصوتي لتطبيق إف إكس سنايبر. كل شيء يعمل بشكل جيد'
        : 'Hello, I am the voice assistant of FX Sniper app. Everything works well';
    await speak(text);
  }

  // ═══════════════════════════════════════════
  // Getter
  // ═══════════════════════════════════════════
  bool get isSpeaking => _isSpeaking;
  bool get isInitialized => _isInitialized;
}