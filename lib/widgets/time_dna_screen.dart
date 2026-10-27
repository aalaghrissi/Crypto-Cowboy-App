import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../models/time_dna.dart';
import '../painters/time_heatmap_painter.dart';
import '../services/time_dna_service.dart';
import 'cosmic_background.dart';

class TimeDNAScreen extends StatefulWidget {
  const TimeDNAScreen({super.key});

  @override
  State<TimeDNAScreen> createState() => _TimeDNAScreenState();
}

class _TimeDNAScreenState extends State<TimeDNAScreen> {
  TimeDNAData? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() => _loading = true);
    final data = TimeDNAService.instance.buildFromHistory();
    setState(() {
      _data = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return CosmicBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.gold, AppColors.cyan],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.access_time_filled,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Time DNA',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          iconTheme: const IconThemeData(color: AppColors.gold),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.cyan),
              onPressed: _load,
              tooltip: 'تحديث',
            ),
          ],
        ),
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.cyan),
              )
            : _data == null || _data!.totalTrades == 0
                ? _buildEmpty()
                : _buildContent(),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // شاشة فارغة
  // ═══════════════════════════════════════════
  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.access_time,
              size: 80,
              color: AppColors.silver,
            ),
            const SizedBox(height: 20),
            const Text(
              '🕐 Time DNA',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'لا توجد بيانات كافية بعد',
              style: TextStyle(
                color: AppColors.silver.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'احفظ صفقاتك في التطبيق، وسيقوم\nTime DNA بتحليل أوقاتك المثالية',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.silver.withOpacity(0.6),
                fontSize: 13,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cyan.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.cyan.withOpacity(0.3),
                ),
              ),
              child: const Column(
                children: [
                  Text(
                    '💡 كيف يعمل؟',
                    style: TextStyle(
                      color: AppColors.cyan,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• يحلل كل صفقة حسب الساعة واليوم\n'
                    '• يكتشف أفضل أوقات تداولك\n'
                    '• يحذرك من الأوقات السيئة\n'
                    '• يعطيك خريطة حرارية لأدائك',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.8,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // المحتوى الكامل
  // ═══════════════════════════════════════════
  Widget _buildContent() {
    final data = _data!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCurrentTimeCard(data),
        const SizedBox(height: 16),
        _buildHeatmapCard(data),
        const SizedBox(height: 16),
        if (data.insights.isNotEmpty) _buildInsightsCard(data.insights),
        const SizedBox(height: 16),
        _buildStatsCard(data),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // الوقت الحالي
  // ═══════════════════════════════════════════
  Widget _buildCurrentTimeCard(TimeDNAData data) {
    final now = DateTime.now();
    final day = now.weekday;
    final hour = now.hour;
    final advice = data.getCurrentTimeAdvice(day, hour);
    final cell = data.getCell(day, hour);
    final rate = cell?.winRate ?? 0;
    final total = cell?.total ?? 0;

    Color color;
    String emoji;
    String message;

    switch (advice) {
      case 'excellent':
        color = AppColors.green;
        emoji = '🟢';
        message = 'وقت ممتاز للتداول!';
        break;
      case 'good':
        color = AppColors.green;
        emoji = '🟢';
        message = 'وقت جيد للتداول';
        break;
      case 'neutral':
        color = AppColors.amber;
        emoji = '🟡';
        message = 'وقت متوسط - كن حذراً';
        break;
      case 'weak':
        color = AppColors.red;
        emoji = '🔴';
        message = 'وقت ضعيف - تجنب التداول';
        break;
      case 'bad':
        color = AppColors.red;
        emoji = '🔴';
        message = 'وقت سيء جداً - لا تتداول!';
        break;
      default:
        color = AppColors.silver;
        emoji = '⚪';
        message = 'بيانات غير كافية';
    }

    return GlassCard(
      borderColor: color,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.access_time_filled,
                  color: AppColors.gold, size: 20),
              const SizedBox(width: 8),
              const Text(
                '⏰ الوقت الحالي',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // الرقم الكبير
          Text(
            '$emoji',
            style: const TextStyle(fontSize: 50),
          ),
          const SizedBox(height: 8),

          if (total >= 3)
            Column(
              children: [
                Text(
                  '${rate.toStringAsFixed(0)}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 42,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'معدل نجاحك في هذا الوقت',
                  style: TextStyle(
                    color: AppColors.silver.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '($total صفقة سابقة)',
                  style: TextStyle(
                    color: AppColors.silver.withOpacity(0.5),
                    fontSize: 10,
                  ),
                ),
              ],
            )
          else
            Text(
              'لا توجد بيانات كافية لهذا الوقت',
              style: TextStyle(
                color: AppColors.silver.withOpacity(0.7),
                fontSize: 13,
              ),
            ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.5)),
            ),
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // الخريطة الحرارية
  // ═══════════════════════════════════════════
  Widget _buildHeatmapCard(TimeDNAData data) {
    return GlassCard(
      borderColor: AppColors.violet,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.grid_on, color: AppColors.violet, size: 20),
              SizedBox(width: 8),
              Text(
                '📊 خريطة الأداء الزمني',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '7 أيام × 24 ساعة',
            style: TextStyle(
              color: AppColors.silver.withOpacity(0.6),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 16),

          // الخريطة
          SizedBox(
            height: 180,
            child: CustomPaint(
              painter: TimeHeatmapPainter(cells: data.cells),
              size: Size.infinite,
            ),
          ),

          const SizedBox(height: 16),

          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              _legendDot(AppColors.green, 'ممتاز +70%'),
              _legendDot(AppColors.amber, 'متوسط'),
              _legendDot(AppColors.red, 'ضعيف -45%'),
              _legendDot(AppColors.silver, 'بيانات قليلة'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: AppColors.silver.withOpacity(0.8),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // الرؤى الذكية
  // ═══════════════════════════════════════════
  Widget _buildInsightsCard(List<TimeInsight> insights) {
    return GlassCard(
      borderColor: AppColors.gold,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome,
                  color: AppColors.gold, size: 20),
              SizedBox(width: 8),
              Text(
                '💡 اكتشافات ذكية',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...insights.map((insight) => _insightTile(insight)),
        ],
      ),
    );
  }

  Widget _insightTile(TimeInsight insight) {
    Color color;
    switch (insight.type) {
      case 'best_hour':
      case 'best_day':
        color = AppColors.green;
        break;
      case 'worst_hour':
      case 'worst_day':
        color = AppColors.red;
        break;
      case 'warning':
        color = AppColors.amber;
        break;
      default:
        color = AppColors.cyan;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            insight.icon,
            style: const TextStyle(fontSize: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.description,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // الإحصائيات
  // ═══════════════════════════════════════════
  Widget _buildStatsCard(TimeDNAData data) {
    final overallColor = data.overallWinRate >= 60
        ? AppColors.green
        : data.overallWinRate >= 50
            ? AppColors.amber
            : AppColors.red;

    return GlassCard(
      borderColor: AppColors.cyan,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics, color: AppColors.cyan, size: 20),
              SizedBox(width: 8),
              Text(
                '📊 الإحصائيات الإجمالية',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _statBox(
                  'إجمالي',
                  '${data.totalTrades}',
                  AppColors.cyan,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statBox(
                  'أرباح',
                  '${data.overallWins}',
                  AppColors.green,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statBox(
                  'خسائر',
                  '${data.overallLosses}',
                  AppColors.red,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statBox(
                  'المعدل',
                  '${data.overallWinRate.toStringAsFixed(0)}%',
                  overallColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: AppColors.silver.withOpacity(0.7),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}