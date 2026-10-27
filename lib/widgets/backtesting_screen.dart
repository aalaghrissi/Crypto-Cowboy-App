import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/translations.dart';
import '../state/app_state.dart';
import '../services/backtesting_service.dart';
import 'cosmic_background.dart';

class BacktestingScreen extends StatefulWidget {
  const BacktestingScreen({super.key});

  @override
  State<BacktestingScreen> createState() => _BacktestingScreenState();
}

class _BacktestingScreenState extends State<BacktestingScreen> {
  bool _isRunning = false;
  int _progress = 0;
  int _total = 0;
  List<BacktestResult> _results = [];
  BacktestResult? _selectedResult;

  // إعدادات
  int _scoreThreshold = 2;
  int _lookahead = 5;
  String _categoryFilter = 'crypto'; // crypto / forex / all

  Future<void> _runBacktest() async {
    // تصفية الأزواج
    var pairs = AppState.pairs;
    if (_categoryFilter == 'crypto') {
      pairs = pairs.where((p) => p.category == 'crypto').toList();
    } else if (_categoryFilter == 'forex') {
      pairs = pairs.where((p) => p.category == 'forex').toList();
    }
    // خذ أول 10 أزواج فقط (لتجنب rate limits)
    pairs = pairs.take(10).toList();

    setState(() {
      _isRunning = true;
      _progress = 0;
      _total = pairs.length;
      _results = [];
      _selectedResult = null;
    });

    final results = await BacktestingService.instance.runBatchBacktest(
      pairs: pairs,
      scoreThreshold: _scoreThreshold,
      lookahead: _lookahead,
      onProgress: (done, total) {
        if (mounted) {
          setState(() => _progress = done);
        }
      },
    );

    if (!mounted) return;

    setState(() {
      _isRunning = false;
      _results = results;
      if (results.isNotEmpty) {
        _selectedResult = results.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          Translation.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: CosmicBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.backgroundTwo, AppColors.background],
                ),
                border: Border(
                  bottom: BorderSide(color: AppColors.cyan, width: 0.5),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.cyan),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.violet, AppColors.cyan],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.science,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [AppColors.gold, AppColors.cyan],
                  ).createShader(b),
                  child: const Text(
                    'Backtesting',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSettingsCard(),
                const SizedBox(height: 16),
                if (_isRunning) _buildProgressCard(),
                if (!_isRunning && _results.isEmpty) _buildIntroCard(),
                if (!_isRunning && _results.isNotEmpty) ...[
                  _buildSummaryCard(),
                  const SizedBox(height: 16),
                  _buildResultsList(),
                  const SizedBox(height: 16),
                  if (_selectedResult != null) _buildDetailCard(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // بطاقة الإعدادات
  // ═══════════════════════════════════════════
  Widget _buildSettingsCard() {
    return GlassCard(
      borderColor: AppColors.violet,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.settings, color: AppColors.violet, size: 20),
              SizedBox(width: 8),
              Text(
                '⚙️ إعدادات الاختبار',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // التصنيف
          const Text(
            'التصنيف',
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _chip('crypto', '💰 Crypto'),
              const SizedBox(width: 8),
              _chip('forex', '💱 Forex'),
            ],
          ),
          const SizedBox(height: 16),

          // النقاط
          Text(
            'الحد الأدنى للنقاط: $_scoreThreshold',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Slider(
            value: _scoreThreshold.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            activeColor: AppColors.cyan,
            onChanged: _isRunning
                ? null
                : (v) => setState(() => _scoreThreshold = v.toInt()),
          ),

          // Lookahead
          Text(
            'عدد الشمعات للأمام: $_lookahead',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          Slider(
            value: _lookahead.toDouble(),
            min: 1,
            max: 20,
            divisions: 19,
            activeColor: AppColors.gold,
            onChanged: _isRunning
                ? null
                : (v) => setState(() => _lookahead = v.toInt()),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isRunning ? null : _runBacktest,
              icon: Icon(_isRunning ? Icons.hourglass_top : Icons.play_arrow),
              label: Text(_isRunning ? 'جاري الاختبار...' : 'بدء الاختبار'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.violet,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String value, String label) {
    final selected = _categoryFilter == value;
    return GestureDetector(
      onTap: _isRunning
          ? null
          : () => setState(() => _categoryFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.violet.withOpacity(0.3)
              : AppColors.backgroundThree.withOpacity(0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.violet : AppColors.cyan.withOpacity(0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.silver,
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // بطاقة التقدم
  // ═══════════════════════════════════════════
  Widget _buildProgressCard() {
    return GlassCard(
      borderColor: AppColors.cyan,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              color: AppColors.cyan,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'جاري الاختبار $_progress / $_total',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: _total > 0 ? _progress / _total : 0,
            backgroundColor: AppColors.background,
            valueColor: const AlwaysStoppedAnimation(AppColors.cyan),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // بطاقة المقدمة
  // ═══════════════════════════════════════════
  Widget _buildIntroCard() {
    return GlassCard(
      borderColor: AppColors.cyan,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.science, size: 60, color: AppColors.cyan),
          const SizedBox(height: 16),
          const Text(
            '🧪 Backtesting',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'اختبر دقة الإشارات على بيانات تاريخية حقيقية\n'
            'قبل استخدامها في التداول',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.silver.withOpacity(0.8),
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.amber.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.amber.withOpacity(0.3)),
            ),
            child: const Text(
              '⚠️ ملاحظة: الاختبار يستخدم بيانات آخر 7 أيام،\n'
              'قد يستغرق 1-2 دقيقة',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.amber, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // ملخص النتائج
  // ═══════════════════════════════════════════
  Widget _buildSummaryCard() {
    // حساب الإجمالي
    int totalWins = 0;
    int totalLosses = 0;
    int totalSignals = 0;
    for (final r in _results) {
      totalWins += r.wins;
      totalLosses += r.losses;
      totalSignals += r.totalSignals;
    }
    final overallRate =
        totalSignals > 0 ? (totalWins / totalSignals * 100) : 0.0;
    final color = overallRate >= 60
        ? AppColors.green
        : overallRate >= 50
            ? AppColors.amber
            : AppColors.red;

    return GlassCard(
      borderColor: color,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.analytics, color: AppColors.gold, size: 22),
              SizedBox(width: 8),
              Text(
                '📊 النتائج الإجمالية',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Center(
            child: Column(
              children: [
                Text(
                  '${overallRate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'نسبة النجاح',
                  style: TextStyle(
                    color: AppColors.silver.withOpacity(0.7),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _statBox('إجمالي', '$totalSignals', AppColors.cyan),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statBox('أرباح', '$totalWins', AppColors.green),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statBox('خسائر', '$totalLosses', AppColors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: AppColors.silver.withOpacity(0.7),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // قائمة النتائج
  // ═══════════════════════════════════════════
  Widget _buildResultsList() {
    return GlassCard(
      borderColor: AppColors.cyan,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Text(
              '🏆 ترتيب الأزواج',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ..._results.asMap().entries.map((entry) {
            final i = entry.key;
            final r = entry.value;
            final color = r.winRate >= 60
                ? AppColors.green
                : r.winRate >= 50
                    ? AppColors.amber
                    : AppColors.red;
            final selected = _selectedResult == r;

            return GestureDetector(
              onTap: () => setState(() => _selectedResult = r),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: selected
                      ? color.withOpacity(0.15)
                      : AppColors.backgroundThree.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: selected ? color : Colors.transparent,
                    width: selected ? 1.5 : 0,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      '${i + 1}',
                      style: TextStyle(
                        color: i < 3 ? AppColors.gold : AppColors.silver,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        r.pair,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      '${r.wins}/${r.totalSignals}',
                      style: TextStyle(
                        color: AppColors.silver.withOpacity(0.7),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${r.winRate.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // تفاصيل زوج محدد
  // ═══════════════════════════════════════════
  Widget _buildDetailCard() {
    final r = _selectedResult!;
    final color = r.winRate >= 60
        ? AppColors.green
        : r.winRate >= 50
            ? AppColors.amber
            : AppColors.red;

    return GlassCard(
      borderColor: color,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights, color: AppColors.gold, size: 22),
              const SizedBox(width: 8),
              Text(
                '📈 ${r.pair}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${r.winRate.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _detailRow('📊 إجمالي الإشارات', '${r.totalSignals}', AppColors.cyan),
          const SizedBox(height: 8),
          _detailRow('🟢 إشارات CALL', '${r.callSignals}', AppColors.green),
          const SizedBox(height: 8),
          _detailRow('🔴 إشارات PUT', '${r.putSignals}', AppColors.red),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          _detailRow('✅ أرباح CALL',
              '${r.callWins} (${r.callWinRate.toStringAsFixed(0)}%)',
              AppColors.green),
          const SizedBox(height: 8),
          _detailRow('❌ خسائر CALL', '${r.callLosses}', AppColors.red),
          const SizedBox(height: 8),
          _detailRow('✅ أرباح PUT',
              '${r.putWins} (${r.putWinRate.toStringAsFixed(0)}%)',
              AppColors.green),
          const SizedBox(height: 8),
          _detailRow('❌ خسائر PUT', '${r.putLosses}', AppColors.red),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 16),
          _detailRow('📈 متوسط الحركة',
              '${r.avgMove.toStringAsFixed(2)}%', AppColors.cyan),
          const SizedBox(height: 8),
          _detailRow('🚀 أفضل حركة',
              '${r.bestMove.toStringAsFixed(2)}%', AppColors.green),
          const SizedBox(height: 8),
          _detailRow('📉 أسوأ حركة',
              '${r.worstMove.toStringAsFixed(2)}%', AppColors.red),
          const SizedBox(height: 8),
          _detailRow('📊 عدد الشمعات', '${r.testedCandles}', AppColors.silver),
          const SizedBox(height: 8),
          _detailRow('⏭️ Lookahead', '${r.lookahead} شمعة', AppColors.silver),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value, Color color) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.silver.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}