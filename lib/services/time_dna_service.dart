import '../models/time_dna.dart';
import '../state/app_state.dart';

/// خدمة Time DNA - تحليل الأداء حسب الوقت
class TimeDNAService {
  TimeDNAService._();
  static final TimeDNAService instance = TimeDNAService._();

  /// بناء بيانات Time DNA من السجل
  TimeDNAData buildFromHistory({int maxDays = 90}) {
    final cells = <String, TimeCell>{};
    int overallWins = 0;
    int overallLosses = 0;
    final cutoff = DateTime.now().subtract(Duration(days: maxDays));

    // ═══ جمع البيانات ═══
    for (final log in AppState.history) {
      // تجاهل القديمة جداً
      if (log.time.isBefore(cutoff)) continue;
      // تجاهل pending
      if (log.result == 'pending') continue;

      final day = log.time.weekday; // 1-7 (1 = Monday, 7 = Sunday)
      final hour = log.time.hour;

      final key = '$day-$hour';
      final cell = cells.putIfAbsent(
        key,
        () => TimeCell(dayOfWeek: day, hour: hour),
      );

      if (log.result == 'win') {
        cell.wins++;
        overallWins++;
      } else if (log.result == 'loss') {
        cell.losses++;
        overallLosses++;
      }
    }

    // ═══ حساب الأفضل/الأسوأ ═══
    int? bestHour;
    int? worstHour;
    int? bestDay;
    int? worstDay;
    double bestHourRate = 0;
    double worstHourRate = 100;
    double bestDayRate = 0;
    double worstDayRate = 100;

    // أفضل/أسوأ ساعة
    for (int h = 0; h < 24; h++) {
      final hourCells = cells.values.where((c) => c.hour == h).toList();
      final totalWins = hourCells.fold<int>(0, (sum, c) => sum + c.wins);
      final totalLosses = hourCells.fold<int>(0, (sum, c) => sum + c.losses);
      final total = totalWins + totalLosses;
      if (total < 3) continue;

      final rate = (totalWins / total * 100);
      if (rate > bestHourRate) {
        bestHourRate = rate;
        bestHour = h;
      }
      if (rate < worstHourRate) {
        worstHourRate = rate;
        worstHour = h;
      }
    }

    // أفضل/أسوأ يوم
    for (int d = 1; d <= 7; d++) {
      final dayCells = cells.values.where((c) => c.dayOfWeek == d).toList();
      final totalWins = dayCells.fold<int>(0, (sum, c) => sum + c.wins);
      final totalLosses = dayCells.fold<int>(0, (sum, c) => sum + c.losses);
      final total = totalWins + totalLosses;
      if (total < 3) continue;

      final rate = (totalWins / total * 100);
      if (rate > bestDayRate) {
        bestDayRate = rate;
        bestDay = d;
      }
      if (rate < worstDayRate) {
        worstDayRate = rate;
        worstDay = d;
      }
    }

    // ═══ بناء الرؤى ═══
    final insights = _buildInsights(
      cells: cells,
      bestHour: bestHour,
      worstHour: worstHour,
      bestDay: bestDay,
      worstDay: worstDay,
      bestHourRate: bestHourRate,
      worstHourRate: worstHourRate,
      bestDayRate: bestDayRate,
      worstDayRate: worstDayRate,
      totalTrades: overallWins + overallLosses,
    );

    return TimeDNAData(
      cells: cells,
      insights: insights,
      totalTrades: overallWins + overallLosses,
      overallWins: overallWins,
      overallLosses: overallLosses,
      bestHour: bestHour,
      worstHour: worstHour,
      bestDay: bestDay,
      worstDay: worstDay,
      bestHourRate: bestHourRate,
      worstHourRate: worstHourRate == 100 ? 0 : worstHourRate,
      bestDayRate: bestDayRate,
      worstDayRate: worstDayRate == 100 ? 0 : worstDayRate,
    );
  }

  /// بناء الرؤى الذكية
  List<TimeInsight> _buildInsights({
    required Map<String, TimeCell> cells,
    required int? bestHour,
    required int? worstHour,
    required int? bestDay,
    required int? worstDay,
    required double bestHourRate,
    required double worstHourRate,
    required double bestDayRate,
    required double worstDayRate,
    required int totalTrades,
  }) {
    final insights = <TimeInsight>[];

    if (totalTrades < 5) {
      insights.add(TimeInsight(
        title: 'تحتاج مزيداً من البيانات',
        description:
            'لديك $totalTrades صفقة فقط. تداول أكثر ليكتشف التطبيق أنماطك الزمنية.',
        icon: '📊',
        type: 'tip',
      ));
      return insights;
    }

    // أفضل ساعة
    if (bestHour != null && bestHourRate > 60) {
      insights.add(TimeInsight(
        title: 'أفضل ساعة: ${_formatHour(bestHour)}',
        description:
            'معدل نجاحك: ${bestHourRate.toStringAsFixed(0)}% - أفضل وقت للتداول!',
        icon: '🥇',
        type: 'best_hour',
      ));
    }

    // أسوأ ساعة
    if (worstHour != null && worstHourRate < 45) {
      insights.add(TimeInsight(
        title: 'أسوأ ساعة: ${_formatHour(worstHour)}',
        description:
            'معدل نجاحك: ${worstHourRate.toStringAsFixed(0)}% - تجنب التداول في هذا الوقت!',
        icon: '⚠️',
        type: 'worst_hour',
      ));
    }

    // أفضل يوم
    if (bestDay != null && bestDayRate > 60) {
      insights.add(TimeInsight(
        title: 'أفضل يوم: ${_dayName(bestDay)}',
        description:
            'معدل نجاحك: ${bestDayRate.toStringAsFixed(0)}% - يومك المميز!',
        icon: '🏆',
        type: 'best_day',
      ));
    }

    // أسوأ يوم
    if (worstDay != null && worstDayRate < 45) {
      insights.add(TimeInsight(
        title: 'أسوأ يوم: ${_dayName(worstDay)}',
        description:
            'معدل نجاحك: ${worstDayRate.toStringAsFixed(0)}% - كن حذراً في هذا اليوم!',
        icon: '⚠️',
        type: 'worst_day',
      ));
    }

    // توصية
    if (bestHour != null && bestHourRate > 65 && totalTrades > 20) {
      insights.add(TimeInsight(
        title: '💡 استراتيجية موصى بها',
        description:
            'ركز تداولاتك بين ${_formatHour(bestHour)} و ${_formatHour(bestHour + 2)}. هذه أفضل نافذة زمنية لك!',
        icon: '💡',
        type: 'tip',
      ));
    }

    return insights;
  }

  String _formatHour(int h) {
    final hour = h % 24;
    final period = hour < 12 ? 'ص' : 'م';
    final display = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$display:00 $period';
  }

  String _dayName(int day) {
    const days = [
      '',
      'الاثنين',
      'الثلاثاء',
      'الأربعاء',
      'الخميس',
      'الجمعة',
      'السبت',
      'الأحد',
    ];
    return days[day];
  }
}