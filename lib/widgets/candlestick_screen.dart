import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../models/models.dart';
import '../utils/indicators.dart';
import 'cosmic_background.dart';

class CandlestickScreen extends StatefulWidget {
  final CurrencyPair pair;
  const CandlestickScreen({super.key, required this.pair});

  @override
  State<CandlestickScreen> createState() => _CandlestickScreenState();
}

class _CandlestickScreenState extends State<CandlestickScreen> {
  List<Candle>? _candles;
  List<double>? _ema20;
  List<double>? _ema50;
  FibonacciLevels? _fib;
  bool _loading = true;
  String? _error;
  bool _showFibonacci = false;

  @override
  void initState() {
    super.initState();
    _loadCandles();
  }

  Future<void> _loadCandles() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final candles = await fetchCandles(symbol: widget.pair.symbol, limit: 60);

    if (!mounted) return;

    if (candles == null || candles.isEmpty) {
      setState(() {
        _loading = false;
        _error = 'فشل جلب البيانات';
      });
      return;
    }

    final closes = candles.map((c) => c.close).toList();
    final ema20 = calcEmaSeries(closes, 20);
    final ema50 = calcEmaSeries(closes, 50);
    final fib = calcFibonacci(candles);

    setState(() {
      _candles = candles;
      _ema20 = ema20;
      _ema50 = ema50;
      _fib = fib;
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
              const Icon(Icons.candlestick_chart,
                  color: AppColors.gold, size: 22),
              const SizedBox(width: 8),
              Text(
                widget.pair.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          iconTheme: const IconThemeData(color: AppColors.gold),
          actions: [
            // زر فيبوناتشي
            IconButton(
              icon: Icon(
                Icons.architecture,
                color: _showFibonacci ? AppColors.gold : AppColors.silver,
              ),
              tooltip: 'فيبوناتشي',
              onPressed: _fib == null
                  ? null
                  : () => setState(() => _showFibonacci = !_showFibonacci),
            ),
            // تحديث
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.cyan),
              onPressed: _loadCandles,
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
            onPressed: _loadCandles,
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
    final candles = _candles!;
    final lastCandle = candles.last;
    final firstCandle = candles.first;
    final change =
        ((lastCandle.close - firstCandle.open) / firstCandle.open) * 100;
    final isUp = change >= 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ═══ السعر الحالي ═══
        GlassCard(
          borderColor: isUp ? AppColors.green : AppColors.red,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.pair.name,
                      style: TextStyle(
                        color: AppColors.silver.withOpacity(0.7),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lastCandle.close.toStringAsFixed(
                        lastCandle.close > 100 ? 2 : 5,
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: (isUp ? AppColors.green : AppColors.red)
                      .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isUp ? AppColors.green : AppColors.red,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isUp ? Icons.trending_up : Icons.trending_down,
                      color: isUp ? AppColors.green : AppColors.red,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${isUp ? '+' : ''}${change.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: isUp ? AppColors.green : AppColors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ═══ الشارت ═══
        GlassCard(
          borderColor: _showFibonacci ? AppColors.gold : AppColors.cyan,
          padding: const EdgeInsets.all(8),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    _legendDot(AppColors.gold, 'EMA 20'),
                    const SizedBox(width: 12),
                    _legendDot(AppColors.cyan, 'EMA 50'),
                    const Spacer(),
                    if (_showFibonacci)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.gold.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '📐 Fib',
                          style: TextStyle(
                            color: AppColors.gold,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 320,
                child: CustomPaint(
                  painter: _CandleWithEmaPainter(
                    candles: candles,
                    ema20: _ema20!,
                    ema50: _ema50!,
                    fib: _showFibonacci ? _fib : null,
                  ),
                  size: Size.infinite,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ═══ بطاقة فيبوناتشي ═══
        if (_showFibonacci && _fib != null) _buildFibCard(),

        const SizedBox(height: 12),

        // ═══ إحصائيات ═══
        GlassCard(
          borderColor: AppColors.violet,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.analytics,
                      color: AppColors.violet, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '📊 إحصائيات (${candles.length} شمعة)',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _statRow(
                'السعر الأعلى',
                candles.map((c) => c.high).reduce((a, b) => a > b ? a : b)
                    .toStringAsFixed(4),
                AppColors.green,
              ),
              _statRow(
                'السعر الأدنى',
                candles.map((c) => c.low).reduce((a, b) => a < b ? a : b)
                    .toStringAsFixed(4),
                AppColors.red,
              ),
              _statRow('إجمالي الشموع', '${candles.length}', AppColors.cyan),
              _statRow(
                'شموع صاعدة',
                '${candles.where((c) => c.isBullish).length}',
                AppColors.green,
              ),
              _statRow(
                'شموع هابطة',
                '${candles.where((c) => !c.isBullish).length}',
                AppColors.red,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════
  // بطاقة فيبوناتشي
  // ═══════════════════════════════════════════
  Widget _buildFibCard() {
    final fib = _fib!;
    final lastPrice = _candles!.last.close;
    final currentRatio = fib.ratioAt(lastPrice);
    final nearest = fib.nearestLevel(lastPrice);

    return GlassCard(
      borderColor: AppColors.gold,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.architecture, color: AppColors.gold, size: 20),
              SizedBox(width: 8),
              Text(
                '📐 مستويات فيبوناتشي',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _fibRow('🔝 القمة (0%)', fib.level0, AppColors.silver, lastPrice),
          _fibRow('23.6%', fib.level236, AppColors.silver, lastPrice),
          _fibRow('38.2%', fib.level382, AppColors.cyan, lastPrice),
          _fibRow('50.0%', fib.level500, AppColors.amber, lastPrice),
          _fibRow('⭐ 61.8% (ذهبي)', fib.level618, AppColors.gold, lastPrice,
              isGolden: true),
          _fibRow('78.6%', fib.level786, AppColors.silver, lastPrice),
          _fibRow('🔻 القاع (100%)', fib.level100, AppColors.silver, lastPrice),
          const SizedBox(height: 12),
          const Divider(color: Colors.white24),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.my_location,
                  color: AppColors.cyan, size: 14),
              const SizedBox(width: 6),
              const Text(
                'السعر الحالي: ',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cyan.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${(currentRatio * 100).toStringAsFixed(1)}% من القمة',
                  style: const TextStyle(
                    color: AppColors.cyan,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.gold.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.tips_and_updates,
                    color: AppColors.gold, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'أقرب مستوى: ${nearest.toStringAsFixed(4)}',
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _fibRow(
    String label,
    double price,
    Color color,
    double lastPrice, {
    bool isGolden = false,
  }) {
    final isNear = (lastPrice - price).abs() / lastPrice < 0.002;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: isNear
            ? BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              )
            : null,
        child: Row(
          children: [
            if (isGolden)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.star, color: AppColors.gold, size: 12),
              ),
            Text(
              label,
              style: TextStyle(
                color: isGolden ? AppColors.gold : color,
                fontSize: 11,
                fontWeight: isGolden ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            Text(
              price.toStringAsFixed(4),
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
            if (isNear)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.arrow_back,
                    color: AppColors.cyan, size: 12),
              ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 10, height: 3, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _statRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppColors.silver.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Painter: شموع + EMA + فيبوناتشي
// ═══════════════════════════════════════════
class _CandleWithEmaPainter extends CustomPainter {
  final List<Candle> candles;
  final List<double> ema20;
  final List<double> ema50;
  final FibonacciLevels? fib;

  _CandleWithEmaPainter({
    required this.candles,
    required this.ema20,
    required this.ema50,
    this.fib,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    // نطاق الأسعار
    double minPrice = candles.first.low;
    double maxPrice = candles.first.high;
    for (final c in candles) {
      if (c.low < minPrice) minPrice = c.low;
      if (c.high > maxPrice) maxPrice = c.high;
    }

    // إضافة فيبوناتشي للنطاق إن كان معروضاً
    if (fib != null) {
      if (fib!.swingLow < minPrice) minPrice = fib!.swingLow;
      if (fib!.swingHigh > maxPrice) maxPrice = fib!.swingHigh;
    }

    // هامش 5%
    final padding = (maxPrice - minPrice) * 0.05;
    minPrice -= padding;
    maxPrice += padding;

    final range = maxPrice - minPrice;
    if (range == 0) return;

    const edgePadding = 8.0;
    final chartHeight = size.height - edgePadding * 2;
    final chartWidth = size.width;

    double priceToY(double price) {
      return edgePadding + (1 - (price - minPrice) / range) * chartHeight;
    }

    // ═══ الشبكة ═══
    final gridPaint = Paint()
      ..color = AppColors.silver.withOpacity(0.08)
      ..strokeWidth = 0.5;
    for (int i = 0; i <= 4; i++) {
      final y = edgePadding + (chartHeight / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(chartWidth, y), gridPaint);
    }

    // ═══ الشموع ═══
    final slotWidth = chartWidth / candles.length;
    final bodyWidth = slotWidth * 0.65;

    for (int i = 0; i < candles.length; i++) {
      final c = candles[i];
      final x = i * slotWidth + slotWidth / 2;

      final isBull = c.isBullish;
      final color = isBull ? AppColors.green : AppColors.red;

      final wickPaint = Paint()
        ..color = color
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(x, priceToY(c.high)),
        Offset(x, priceToY(c.low)),
        wickPaint,
      );

      final top = priceToY(c.bodyTop);
      final bottom = priceToY(c.bodyBottom);
      final bodyHeight = (bottom - top).abs();
      final actualBodyHeight = bodyHeight < 1 ? 1.0 : bodyHeight;

      final bodyRect = Rect.fromLTWH(
        x - bodyWidth / 2,
        top,
        bodyWidth,
        actualBodyHeight,
      );

      final bodyPaint = Paint()
        ..color = isBull ? color.withOpacity(0.9) : color
        ..style = PaintingStyle.fill;
      final bodyBorder = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;

      canvas.drawRect(bodyRect, bodyPaint);
      canvas.drawRect(bodyRect, bodyBorder);
    }

    // ═══ فيبوناتشي (خلف EMA) ═══
    if (fib != null) {
      _drawFibonacci(canvas, size, fib!, priceToY, chartWidth);
    }

    // ═══ EMA 20 ═══
    _drawEmaLine(
        canvas, ema20, priceToY, slotWidth, AppColors.gold, chartWidth);

    // ═══ EMA 50 ═══
    _drawEmaLine(
        canvas, ema50, priceToY, slotWidth, AppColors.cyan, chartWidth);
  }

  void _drawFibonacci(
    Canvas canvas,
    Size size,
    FibonacciLevels fib,
    double Function(double) priceToY,
    double chartWidth,
  ) {
    // ═══ المنطقة الذهبية (38.2% - 61.8%) ═══
    final goldTop = priceToY(fib.level382);
    final goldBottom = priceToY(fib.level618);
    final goldZonePaint = Paint()
      ..color = AppColors.gold.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTRB(
        0,
        goldTop < goldBottom ? goldTop : goldBottom,
        chartWidth,
        goldTop < goldBottom ? goldBottom : goldTop,
      ),
      goldZonePaint,
    );

    // ═══ المستويات ═══
    final levels = [
      _FibLevel(0.0, fib.level0, '0%', AppColors.silver, false),
      _FibLevel(0.236, fib.level236, '23.6%', AppColors.silver, false),
      _FibLevel(0.382, fib.level382, '38.2%', AppColors.cyan, false),
      _FibLevel(0.500, fib.level500, '50%', AppColors.amber, false),
      _FibLevel(0.618, fib.level618, '61.8%', AppColors.gold, true),
      _FibLevel(0.786, fib.level786, '78.6%', AppColors.silver, false),
      _FibLevel(1.0, fib.level100, '100%', AppColors.silver, false),
    ];

    for (final level in levels) {
      final y = priceToY(level.price);
      final paint = Paint()
        ..color = level.color.withOpacity(level.isGolden ? 0.9 : 0.5)
        ..strokeWidth = level.isGolden ? 2.0 : 1.0
        ..style = PaintingStyle.stroke;

      // خط متقطع
      const dashWidth = 6.0;
      const dashSpace = 4.0;
      double startX = 0;
      while (startX < chartWidth) {
        canvas.drawLine(
          Offset(startX, y),
          Offset(startX + dashWidth, y),
          paint,
        );
        startX += dashWidth + dashSpace;
      }

      // التسمية
      final textSpan = TextSpan(
        text: level.label,
        style: TextStyle(
          color: level.color.withOpacity(level.isGolden ? 1.0 : 0.85),
          fontSize: level.isGolden ? 10 : 9,
          fontWeight: level.isGolden ? FontWeight.bold : FontWeight.normal,
          backgroundColor: level.isGolden
              ? AppColors.background.withOpacity(0.7)
              : null,
        ),
      );
      final tp = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(4, y - tp.height - 2));
    }
  }

  void _drawEmaLine(
    Canvas canvas,
    List<double> ema,
    double Function(double) priceToY,
    double slotWidth,
    Color color,
    double chartWidth,
  ) {
    if (ema.length < 2) return;

    final path = Path();
    for (int i = 0; i < ema.length && i < candles.length; i++) {
      final x = i * slotWidth + slotWidth / 2;
      final y = priceToY(ema[i]);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final paint = Paint()
      ..color = color.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CandleWithEmaPainter oldDelegate) {
    return oldDelegate.candles != candles ||
        oldDelegate.fib != fib;
  }
}

class _FibLevel {
  final double ratio;
  final double price;
  final String label;
  final Color color;
  final bool isGolden;

  _FibLevel(this.ratio, this.price, this.label, this.color, this.isGolden);
}