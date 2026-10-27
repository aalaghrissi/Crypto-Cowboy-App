
/// خدمة توقيت الدخول الأمثل
class EntryTimingService {
  EntryTimingService._();
  static final EntryTimingService instance = EntryTimingService._();

  /// ثواني متبقية حتى نهاية الشمعة الحالية
  int secondsToNextCandle(String timeframe) {
    final now = DateTime.now();
    switch (timeframe) {
      case '1m':
        return 60 - now.second;
      case '5m':
        // 5 دقائق = 300 ثانية
        // نستخدم الدقيقة % 5
        final secsInto5m = (now.minute % 5) * 60 + now.second;
        return 300 - secsInto5m;
      case '15m':
        final secsInto15m = (now.minute % 15) * 60 + now.second;
        return 900 - secsInto15m;
      case '1h':
        return (60 - now.minute) * 60 - now.second;
      default:
        return 60 - now.second;
    }
  }

  /// أفضل لحظة للدخول (10-15 ثانية قبل نهاية الشمعة)
  /// القاعدة: Pocket Option يحتاج 10 ثواني على الأقل
  int bestEntrySeconds(String timeframe, {int leadTime = 15}) {
    return secondsToNextCandle(timeframe) - leadTime;
  }

  /// هل الوقت مناسب للدخول الآن؟
  bool isGoodEntryTime(String timeframe, {int leadTime = 15}) {
    final s = bestEntrySeconds(timeframe, leadTime: leadTime);
    return s >= 0 && s <= 5; // نافذة 5 ثواني
  }

  /// المدة المقترحة للصفقة بناءً على التوافق
  String suggestedDuration(int alignment) {
    if (alignment >= 4) return '5M';
    if (alignment == 3) return '3M';
    if (alignment == 2) return '1M';
    return 'لا تدخل';
  }

  /// حجم الصفقة كنسبة مئوية من رأس المال
  double suggestedPositionSize(int strength) {
    switch (strength) {
      case 5:
        return 2.0;
      case 4:
        return 1.5;
      case 3:
        return 1.0;
      case 2:
        return 0.5;
      default:
        return 0.0;
    }
  }

  /// نصيحة للدخول
  String entryAdvice(int alignment) {
    if (alignment >= 4) {
      return '✅ ادخل الآن! إشارة قوية جداً';
    } else if (alignment == 3) {
      return '🟢 ادخل - إشارة قوية';
    } else if (alignment == 2) {
      return '⚠️ انتظر تأكيد إضافي';
    } else {
      return '❌ لا تدخل - إشارة ضعيفة';
    }
  }

  /// format countdown (MM:SS)
  String formatCountdown(int seconds) {
    if (seconds < 0) return '00:00';
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// نسبة التقدم (0.0 إلى 1.0)
  double progress(String timeframe) {
    int total;
    switch (timeframe) {
      case '1m':
        total = 60;
        break;
      case '5m':
        total = 300;
        break;
      case '15m':
        total = 900;
        break;
      case '1h':
        total = 3600;
        break;
      default:
        total = 60;
    }
    final remaining = secondsToNextCandle(timeframe);
    return (total - remaining) / total;
  }
}