import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/translations.dart';
import '../state/app_state.dart';
import '../services/multi_timeframe_service.dart';
import '../services/entry_timing_service.dart';
import 'cosmic_background.dart';

class MultiTimeframeScreen extends StatefulWidget {
  const MultiTimeframeScreen({super.key});

  @override
  State<MultiTimeframeScreen> createState() => _MultiTimeframeScreenState();
}

class _MultiTimeframeScreenState extends State<MultiTimeframeScreen> {
  bool _isRunning = false;
  int _progress = 0;
  int _total = 0;
  List<MTFResult> _results = [];
  MTFResult? _selected;

  String _categoryFilter = 'crypto';
  int _limit = 8;

  // ═══ التوقيت ═══
  Timer? _countdownTimer;
  int _secondsLeft = 0;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _updateCountdown();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateCountdown();
    });
  }

  void _updateCountdown() {
    setState(() {
      _secondsLeft = EntryTimingService.instance.secondsToNextCandle('1m');
    });
  }

  Future<void> _runAnalysis() async {
    var pairs = AppState.pairs;
    if (_categoryFilter == 'crypto') {
      pairs = pairs.where((p) => p.category == 'crypto').toList();
    } else if (_categoryFilter == 'forex') {
      pairs = pairs.where((p) => p.category == 'forex').toList();
    }

    final selected = pairs.take(_limit).toList();

    setState(() {
      _isRunning = true;
      _progress = 0;
      _total = selected.length;
      _results = [];
      _selected = null;
    });

    final pairMaps = selected
        .map((p) => {'symbol': p.symbol, 'name': p.name})
        .toList();

    final results = await MultiTimeframeService.instance.analyzeBatch(
      pairs: pairMaps,
      onProgress: (done, total) {
        if (mounted) setState(() => _progress = done);
      },
    );

    if (!mounted) return;

    setState(() {
      _isRunning = false;
      _results = results;
      if (results.isNotEmpty) _selected = results.first;
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
                      colors: [AppColors.cyan, AppColors.violet],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.grid_view_rounded,
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
                    'Multi-Timeframe',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              if (_results.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.cyan),
                  onPressed: _isRunning ? null : _runAnalysis,
                  tooltip: 'تحديث',
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSettings(),
                const SizedBox(height: 16),
                if (_isRunning) _buildProgress(),
                if (!_isRunning && _results.isEmpty) _buildIntro(),
                if (!_isRunning && _results.isNotEmpty) ...[
                  _buildTopOpportunity(),
                  const SizedBox(height: 16),
                  _buildResultsList(),
                  const SizedBox(height: 16),
                  if (_selected != null) _buildDetail(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // الإعدادات
  // ═══════════════════════════════════════════
  Widget _buildSettings() {
    return GlassCard(
      borderColor: AppColors.violet,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.tune, color: AppColors.violet, size: 20),
              SizedBox(width: 8),
              Text(
                '⚙️ إعدادات التحليل',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _chip('crypto', '💰 Crypto', AppColors.cyan)),
              const SizedBox(width: 8),
              Expanded(child: _chip('forex', '💱 Forex', AppColors.gold)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'عدد الأزواج: ',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                '$_limit',
                style: const TextStyle(
                  color: AppColors.cyan,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Expanded(
                child: Slider(
                  value: _limit.toDouble(),
                  min: 3,
                  max: 15,
                  divisions: 12,
                  activeColor: AppColors.cyan,
                  onChanged: _isRunning
                      ? null
                      : (v) => setState(() => _limit = v.toInt()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isRunning ? null : _runAnalysis,
              icon: Icon(_isRunning ? Icons.hourglass_top : Icons.play_arrow),
              label: Text(_isRunning ? 'جاري التحليل...' : 'بدء تحليل MTF'),
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

  Widget _chip(String value, String label, Color color) {
    final selected = _categoryFilter == value;
    return GestureDetector(
      onTap: _isRunning ? null : () => setState(() => _categoryFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? color.withOpacity(0.25)
              : AppColors.backgroundThree.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? color : AppColors.cyan.withOpacity(0.3),
            width: selected ? 2 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : AppColors.silver,
              fontSize: 13,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // التقدم
  // ═══════════════════════════════════════════
  Widget _buildProgress() {
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
            'جاري التحليل $_progress / $_total',
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
  // المقدمة
  // ═══════════════════════════════════════════
  Widget _buildIntro() {
    return GlassCard(
      borderColor: AppColors.cyan,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Icon(Icons.grid_view_rounded,
              size: 60, color: AppColors.cyan),
          const SizedBox(height: 16),
          const Text(
            '📊 Multi-Timeframe + Timing',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'تحليل كل زوج على 4 أطر زمنية\n'
            'مع عدّاد توقيت الدخول الأمثل',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.silver.withOpacity(0.8),
              fontSize: 13,
              height: 1.8,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // أفضل فرصة + العدّاد
  // ═══════════════════════════════════════════
  Widget _buildTopOpportunity() {
    if (_results.isEmpty) return const SizedBox.shrink();
    final top = _results.first;

    final color = top.finalSignal == 'CALL'
        ? AppColors.green
        : top.finalSignal == 'PUT'
            ? AppColors.red
            : AppColors.amber;

    return GlassCard(
      borderColor: color,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // ═══ العنوان ═══
          Row(
            children: [
              const Icon(Icons.emoji_events, color: AppColors.gold, size: 24),
              const SizedBox(width: 8),
              const Text(
                '🏆 أفضل فرصة',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              _strengthStars(top.strength),
            ],
          ),

          const SizedBox(height: 16),

          // ═══ الزوج والإشارة ═══
          Text(
            top.pairName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color, width: 2),
            ),
            child: Text(
              _signalLabel(top.finalSignal),
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'التوافق: ${top.alignment}/4',
            style: TextStyle(
              color: AppColors.silver.withOpacity(0.8),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          // ═══ العدّاد التنازلي ═══
          _buildCountdown(color),

          const SizedBox(height: 16),

          // ═══ التوصيات ═══
          _buildRecommendations(top),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // العدّاد التنازلي
  // ═══════════════════════════════════════════
  Widget _buildCountdown(Color signalColor) {
    final isReady = _secondsLeft <= 15;
    final color = isReady ? AppColors.green : AppColors.cyan;
    final progress = 1 - (_secondsLeft / 60);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: isReady ? 2 : 1),
        boxShadow: isReady
            ? [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                isReady ? Icons.play_circle : Icons.hourglass_top,
                color: color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isReady ? '⏰ الدخول الآن!' : '⏱️ الدخول خلال',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'شمعة 1M',
                style: TextStyle(
                  color: AppColors.silver.withOpacity(0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // الرقم الكبير
          Text(
            EntryTimingService.instance.formatCountdown(_secondsLeft),
            style: TextStyle(
              color: color,
              fontSize: 48,
              fontWeight: FontWeight.w900,
              fontFamily: 'monospace',
              letterSpacing: 4,
              shadows: isReady
                  ? [
                      Shadow(color: color, blurRadius: 20),
                    ]
                  : null,
            ),
          ),

          const SizedBox(height: 12),

          // شريط التقدم
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.background,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            isReady
                ? '🎯 اللحظة المثالية للدخول!'
                : '⏳ انتظر نهاية الشمعة',
            style: TextStyle(
              color: color.withOpacity(0.9),
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // التوصيات
  // ═══════════════════════════════════════════
  Widget _buildRecommendations(MTFResult top) {
    final size = EntryTimingService.instance
        .suggestedPositionSize(top.strength);
    final duration = EntryTimingService.instance
        .suggestedDuration(top.alignment);
    final advice = EntryTimingService.instance.entryAdvice(top.alignment);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundThree.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb, color: AppColors.gold, size: 16),
              const SizedBox(width: 6),
              const Text(
                '🎯 توصيات الدخول',
                style: TextStyle(
                  color: AppColors.gold,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _recommendationRow('📊 المدة المقترحة', duration, AppColors.cyan),
          const SizedBox(height: 6),
          _recommendationRow('💰 حجم الصفقة', '${size.toStringAsFixed(1)}%',
              AppColors.gold),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              advice,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recommendationRow(String label, String value, Color color) {
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
            fontSize: 14,
            fontWeight: FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  String _signalLabel(String signal) {
    switch (signal) {
      case 'CALL':
        return '🟢 شراء (CALL)';
      case 'PUT':
        return '🔴 بيع (PUT)';
      default:
        return '⏸️ انتظار';
    }
  }

  Widget _strengthStars(int strength) {
    return Row(
      children: List.generate(
        5,
        (i) => Icon(
          Icons.star,
          size: 16,
          color: i < strength
              ? AppColors.gold
              : AppColors.silver.withOpacity(0.2),
        ),
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
              '📋 جميع النتائج',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ..._results.map((r) => _resultTile(r)),
        ],
      ),
    );
  }

  Widget _resultTile(MTFResult r) {
    final selected = _selected == r;
    final color = r.finalSignal == 'CALL'
        ? AppColors.green
        : r.finalSignal == 'PUT'
            ? AppColors.red
            : AppColors.amber;

    return GestureDetector(
      onTap: () => setState(() => _selected = r),
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
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    r.pairName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${r.alignment}/4',
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                _strengthStars(r.strength),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: r.signals.map((s) {
                final c = s.signal == 'CALL'
                    ? AppColors.green
                    : s.signal == 'PUT'
                        ? AppColors.red
                        : AppColors.silver;
                return Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      color: c.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: c.withOpacity(0.5)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          s.timeframe.toUpperCase(),
                          style: TextStyle(
                            color: AppColors.silver.withOpacity(0.7),
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          s.signal == 'CALL'
                              ? '🟢'
                              : s.signal == 'PUT'
                                  ? '🔴'
                                  : '⚪',
                          style: const TextStyle(fontSize: 14),
                        ),
                        Text(
                          '${s.confidence}%',
                          style: TextStyle(
                            color: c,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // التفاصيل
  // ═══════════════════════════════════════════
  Widget _buildDetail() {
    final r = _selected!;
    final color = r.finalSignal == 'CALL'
        ? AppColors.green
        : r.finalSignal == 'PUT'
            ? AppColors.red
            : AppColors.amber;

    return GlassCard(
      borderColor: color,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights, color: color, size: 22),
              const SizedBox(width: 8),
              Text(
                'تفاصيل ${r.pairName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _detailRow('الإشارة النهائية', _signalLabel(r.finalSignal), color),
          const SizedBox(height: 8),
          _detailRow('التوافق', '${r.alignment}/4', AppColors.cyan),
          const SizedBox(height: 8),
          _detailRow('القوة', '${r.strength}/5 ⭐', AppColors.gold),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24),
          const SizedBox(height: 12),
          const Text(
            'تفاصيل الأطر:',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...r.signals.map((s) {
            final c = s.signal == 'CALL'
                ? AppColors.green
                : s.signal == 'PUT'
                    ? AppColors.red
                    : AppColors.silver;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: c.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      s.timeframe.toUpperCase(),
                      style: TextStyle(
                        color: c,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _signalLabel(s.signal),
                    style: TextStyle(color: c, fontSize: 12),
                  ),
                  const Spacer(),
                  Text(
                    '${s.confidence}%',
                    style: TextStyle(
                      color: c,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
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
          ),
        ),
      ],
    );
  }
}