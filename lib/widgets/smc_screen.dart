import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../models/models.dart';
import '../services/smc_service.dart';
import 'cosmic_background.dart';

class SMCScreen extends StatefulWidget {
  final CurrencyPair pair;
  const SMCScreen({super.key, required this.pair});

  @override
  State<SMCScreen> createState() => _SMCScreenState();
}

class _SMCScreenState extends State<SMCScreen> {
  SMCAnalysis? _analysis;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await SMCService.instance.analyze(
      symbol: widget.pair.symbol,
    );

    if (!mounted) return;

    setState(() {
      _loading = false;
      if (result == null) {
        _error = 'فشل جلب البيانات';
      } else {
        _analysis = result;
      }
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
                    colors: [AppColors.violet, AppColors.cyan],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'SMC - ${widget.pair.name}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
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
            : _error != null
                ? _buildError()
                : _buildContent(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: AppColors.red, size: 60),
          const SizedBox(height: 16),
          Text(
            _error ?? 'خطأ غير معروف',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cyan,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final smc = _analysis!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSummaryCard(smc),
        const SizedBox(height: 12),
        _buildOrderBlocksCard(smc.orderBlocks),
        const SizedBox(height: 12),
        _buildFVGCard(smc.fvgs),
        const SizedBox(height: 12),
        _buildStructureCard(smc.structureBreaks),
        const SizedBox(height: 12),
        _buildLiquidityCard(smc.liquidityZones),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // ملخص
  // ═══════════════════════════════════════════
  Widget _buildSummaryCard(SMCAnalysis smc) {
    final trendColor = smc.trend == 'bullish'
        ? AppColors.green
        : smc.trend == 'bearish'
            ? AppColors.red
            : AppColors.amber;

    final biasColor = smc.bias == 'long'
        ? AppColors.green
        : smc.bias == 'short'
            ? AppColors.red
            : AppColors.silver;

    final scoreColor = smc.score >= 60
        ? AppColors.green
        : smc.score >= 40
            ? AppColors.amber
            : AppColors.red;

    return GlassCard(
      borderColor: scoreColor,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: AppColors.gold, size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '🧠 تحليل Smart Money',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: scoreColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: scoreColor),
                ),
                child: Text(
                  '${smc.score}%',
                  style: TextStyle(
                    color: scoreColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // الاتجاه والميل
          Row(
            children: [
              Expanded(
                child: _statBox(
                  '📈 الاتجاه',
                  smc.trend == 'bullish'
                      ? 'صاعد'
                      : smc.trend == 'bearish'
                          ? 'هابط'
                          : 'جانبي',
                  trendColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _statBox(
                  '🎯 الميل',
                  smc.bias == 'long'
                      ? 'Long شراء'
                      : smc.bias == 'short'
                          ? 'Short بيع'
                          : 'محايد',
                  biasColor,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // شريط النقاط
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'قوة التحليل',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const Spacer(),
                  Text(
                    '${smc.score}/100',
                    style: TextStyle(
                      color: scoreColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: smc.score / 100,
                  minHeight: 12,
                  backgroundColor: AppColors.background,
                  valueColor: AlwaysStoppedAnimation(scoreColor),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ملخص الإشارات
          Row(
            children: [
              _miniBadge('OB', smc.orderBlocks.length, AppColors.violet),
              const SizedBox(width: 6),
              _miniBadge('FVG', smc.fvgs.length, AppColors.cyan),
              const SizedBox(width: 6),
              _miniBadge('BOS', smc.structureBreaks.length, AppColors.gold),
              const SizedBox(width: 6),
              _miniBadge('LIQ', smc.liquidityZones.length, AppColors.amber),
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
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniBadge(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '$count',
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // Order Blocks
  // ═══════════════════════════════════════════
  Widget _buildOrderBlocksCard(List<OrderBlock> obs) {
    return GlassCard(
      borderColor: AppColors.violet,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.crop_square,
                  color: AppColors.violet, size: 20),
              const SizedBox(width: 8),
              const Text(
                '🎯 Order Blocks',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${obs.length}',
                style: const TextStyle(
                  color: AppColors.violet,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (obs.isEmpty)
            _emptyMessage('لا توجد Order Blocks حالياً')
          else
            ...obs.take(5).map((ob) => _obRow(ob)),
        ],
      ),
    );
  }

  Widget _obRow(OrderBlock ob) {
    final color = ob.isBullish ? AppColors.green : AppColors.red;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            ob.isBullish
                ? Icons.arrow_upward_rounded
                : Icons.arrow_downward_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${ob.low.toStringAsFixed(4)} - ${ob.high.toStringAsFixed(4)}',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                Icons.star,
                size: 10,
                color: i < ob.strength
                    ? AppColors.gold
                    : AppColors.silver.withOpacity(0.2),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // Fair Value Gaps
  // ═══════════════════════════════════════════
  Widget _buildFVGCard(List<FairValueGap> fvgs) {
    return GlassCard(
      borderColor: AppColors.cyan,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.space_bar, color: AppColors.cyan, size: 20),
              const SizedBox(width: 8),
              const Text(
                '📊 Fair Value Gaps',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${fvgs.length}',
                style: const TextStyle(
                  color: AppColors.cyan,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (fvgs.isEmpty)
            _emptyMessage('لا توجد FVGs حالياً')
          else
            ...fvgs.reversed.take(5).map((fvg) => _fvgRow(fvg)),
        ],
      ),
    );
  }

  Widget _fvgRow(FairValueGap fvg) {
    final color = fvg.isBullish ? AppColors.green : AppColors.red;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              fvg.isBullish ? '🟢 صاعد' : '🔴 هابط',
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${fvg.low.toStringAsFixed(4)} - ${fvg.high.toStringAsFixed(4)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // Structure Breaks
  // ═══════════════════════════════════════════
  Widget _buildStructureCard(List<StructureBreak> breaks) {
    return GlassCard(
      borderColor: AppColors.gold,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.stacked_line_chart,
                  color: AppColors.gold, size: 20),
              const SizedBox(width: 8),
              const Text(
                '📈 Break of Structure',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${breaks.length}',
                style: const TextStyle(
                  color: AppColors.gold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (breaks.isEmpty)
            _emptyMessage('لا يوجد كسر هيكل حالياً')
          else
            ...breaks.reversed.take(5).map((b) => _breakRow(b)),
        ],
      ),
    );
  }

  Widget _breakRow(StructureBreak b) {
    final color = b.isBullish ? AppColors.green : AppColors.red;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              b.type,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            b.isBullish
                ? Icons.trending_up
                : Icons.trending_down,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'كسر مستوى ${b.level.toStringAsFixed(4)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // Liquidity Zones
  // ═══════════════════════════════════════════
  Widget _buildLiquidityCard(List<LiquidityZone> zones) {
    return GlassCard(
      borderColor: AppColors.amber,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.water_drop,
                  color: AppColors.amber, size: 20),
              const SizedBox(width: 8),
              const Text(
                '💧 Liquidity Zones',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${zones.length}',
                style: const TextStyle(
                  color: AppColors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (zones.isEmpty)
            _emptyMessage('لا توجد مناطق سيولة حالياً')
          else
            ...zones.take(5).map((z) => _liqRow(z)),
        ],
      ),
    );
  }

  Widget _liqRow(LiquidityZone z) {
    final isHigh = z.type == 'high';
    final color = isHigh ? AppColors.red : AppColors.green;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isHigh ? Icons.arrow_upward : Icons.arrow_downward,
            color: color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            isHigh ? 'سيولة عالية' : 'سيولة منخفضة',
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            z.high.toStringAsFixed(4),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyMessage(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.backgroundThree.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.silver.withOpacity(0.6),
          fontSize: 11,
        ),
      ),
    );
  }
}