// ═══════════════════════════════════════════
// Time DNA Models
// ═══════════════════════════════════════════

/// خلية زمنية واحدة (يوم + ساعة)
class TimeCell {
  final int dayOfWeek;   // 1 = الاثنين، 7 = الأحد
  final int hour;        // 0-23
  int wins = 0;
  int losses = 0;

  TimeCell({required this.dayOfWeek, required this.hour});

  int get total => wins + losses;
  double get winRate => total > 0 ? (wins / total * 100) : 0;
  bool get hasData => total > 0;

  /// تصنيف الأداء
  String get performance {
    if (total < 3) return 'insufficient';
    if (winRate >= 70) return 'excellent';
    if (winRate >= 55) return 'good';
    if (winRate >= 45) return 'average';
    if (winRate >= 35) return 'weak';
    return 'bad';
  }
}

/// رؤية ذكية
class TimeInsight {
  final String title;
  final String description;
  final String icon;
  final String type; // 'best_hour', 'worst_hour', 'best_day', 'worst_day', 'warning', 'tip'

  TimeInsight({
    required this.title,
    required this.description,
    required this.icon,
    required this.type,
  });
}

/// بيانات Time DNA الكاملة
class TimeDNAData {
  final Map<String, TimeCell> cells; // key: "day-hour"
  final List<TimeInsight> insights;
  final int totalTrades;
  final int overallWins;
  final int overallLosses;
  final int? bestHour;
  final int? worstHour;
  final int? bestDay;
  final int? worstDay;
  final double bestHourRate;
  final double worstHourRate;
  final double bestDayRate;
  final double worstDayRate;

  TimeDNAData({
    required this.cells,
    required this.insights,
    required this.totalTrades,
    required this.overallWins,
    required this.overallLosses,
    this.bestHour,
    this.worstHour,
    this.bestDay,
    this.worstDay,
    this.bestHourRate = 0,
    this.worstHourRate = 0,
    this.bestDayRate = 0,
    this.worstDayRate = 0,
  });

  double get overallWinRate =>
      totalTrades > 0 ? (overallWins / totalTrades * 100) : 0;

  /// الحصول على خلية
  TimeCell? getCell(int day, int hour) => cells['$day-$hour'];

  /// معدل الساعة الحالية
  double getCurrentHourRate(int day, int hour) {
    final cell = getCell(day, hour);
    return cell?.winRate ?? 0;
  }

  /// هل الوقت الحالي مناسب؟
  String getCurrentTimeAdvice(int day, int hour) {
    final cell = getCell(day, hour);
    if (cell == null || cell.total < 3) {
      return 'insufficient';
    }
    if (cell.winRate >= 70) return 'excellent';
    if (cell.winRate >= 55) return 'good';
    if (cell.winRate >= 45) return 'neutral';
    if (cell.winRate >= 35) return 'weak';
    return 'bad';
  }
}