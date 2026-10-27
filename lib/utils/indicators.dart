import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';

Future<List<double>?> fetchKlines({required String symbol}) async {
  try {
    if (symbol.contains('=X') || symbol.contains('=F')) {
      final url = Uri.parse(
          'https://query1.finance.yahoo.com/v8/finance/chart/$symbol?interval=1m&range=1d');
      final r = await http.get(url, headers: {'User-Agent': 'Mozilla/5.0'});
      if (r.statusCode != 200) return null;
      final data = json.decode(r.body);
      final quotes =
          data['chart']['result'][0]['indicators']['quote'][0]['close'];
      final closes = (quotes as List)
          .where((c) => c != null)
          .map<double>((c) => (c as num).toDouble())
          .toList();
      if (closes.length < 50) return null;
      return closes;
    } else {
      final r = await http.get(Uri.parse(
          'https://api.binance.com/api/v3/klines?symbol=$symbol&interval=1m&limit=100'));
      if (r.statusCode != 200) return null;
      final d = json.decode(r.body);
      return d.map<double>((c) => double.parse(c[4] as String)).toList();
    }
  } catch (e) {
    return null;
  }
}
/// جلب بيانات تاريخية كثيرة للـ Backtesting
Future<List<double>?> fetchHistoricalKlines({
  required String symbol,
  int limit = 500,
}) async {
  try {
    if (symbol.contains('=X') || symbol.contains('=F')) {
      // Yahoo Finance - نستخدم 5 دقائق لـ 7 أيام
      final url = Uri.parse(
          'https://query1.finance.yahoo.com/v8/finance/chart/$symbol?interval=5m&range=7d');
      final r = await http.get(url, headers: {'User-Agent': 'Mozilla/5.0'});
      if (r.statusCode != 200) return null;
      final data = json.decode(r.body);
      final quotes =
          data['chart']['result'][0]['indicators']['quote'][0]['close'];
      final closes = (quotes as List)
          .where((c) => c != null)
          .map<double>((c) => (c as num).toDouble())
          .toList();
      if (closes.length < 100) return null;
      return closes;
    } else {
      // Binance - 1000 شمعة كحد أقصى
      final r = await http.get(Uri.parse(
          'https://api.binance.com/api/v3/klines?symbol=$symbol&interval=1m&limit=1000'));
      if (r.statusCode != 200) return null;
      final d = json.decode(r.body);
      final closes = d.map<double>((c) => double.parse(c[4] as String)).toList();
      if (closes.length < 100) return null;
      return closes;
    }
  } catch (e) {
    return null;
  }
}

double calcRsi(List<double> p, {int period = 14}) {
  if (p.length < period + 1) return 50;
  double u = 0, d = 0;
  for (int i = p.length - period; i < p.length; i++) {
    final x = p[i] - p[i - 1];
    if (x > 0) {
      u += x;
    } else {
      d -= x;
    }
  }
  if (d == 0) return 100;
  return 100 - (100 / (1 + u / d));
}

double calcEma(List<double> p, int period) {
  if (p.length < period) return p.last;
  final k = 2 / (period + 1);
  double e = p.sublist(0, period).reduce((a, b) => a + b) / period;
  for (int i = period; i < p.length; i++) {
    e = p[i] * k + e * (1 - k);
  }
  return e;
}

double calcMacd(List<double> p) {
  if (p.length < 26) return 0;
  return calcEma(p, 12) - calcEma(p, 26);
}

double calcAdx(List<double> p) {
  if (p.length < 15) return 0;
  final tr = <double>[];
  for (int i = 1; i < p.length; i++) {
    tr.add((p[i] - p[i - 1]).abs());
  }
  final a = tr.sublist(tr.length - 14).reduce((a, b) => a + b) / 14;
  if (a == 0) return 0;
  double u = 0, d = 0;
  for (int i = p.length - 14; i < p.length; i++) {
    final x = p[i] - p[i - 1];
    if (x > 0) {
      u += x;
    } else {
      d -= x;
    }
  }
  return (((u - d).abs() / (u + d == 0 ? 1 : u + d)) * 100).clamp(0, 100);
}

List<double> calcBB(List<double> p, {int period = 20}) {
  if (p.length < period) return [p.last, p.last];
  final s = p.sublist(p.length - period);
  final mean = s.reduce((a, b) => a + b) / period;
  final v =
      s.map((x) => (x - mean) * (x - mean)).reduce((a, b) => a + b) / period;
  final sd = math.sqrt(v);
  return [mean + 2 * sd, mean - 2 * sd];
}

double calcStoch(List<double> p, {int period = 14}) {
  if (p.length < period) return 50;
  final s = p.sublist(p.length - period);
  final h = s.reduce(math.max);
  final l = s.reduce(math.min);
  return h == l ? 50 : ((p.last - l) / (h - l)) * 100;
}

String detectPattern(List<double> p) {
  if (p.length < 3) return 'None';
  final c1 = p[p.length - 3];
  final c2 = p[p.length - 2];
  final c3 = p[p.length - 1];
  final b1 = (c2 - c1).abs();
  final b2 = (c3 - c2).abs();
  if (c3 > c2 && c2 < c1 && b2 > b1 * 1.5) return 'Bullish Engulfing';
  if (c3 < c2 && c2 > c1 && b2 > b1 * 1.5) return 'Bearish Engulfing';
  if (b2 < 0.001 * c3) return 'Doji';
  return 'None';
}/// حساب سلسلة EMA بالكامل بشكل تصاعدي (سريع جداً)
/// تُعيد قائمة بنفس طول [prices] (القيم الأولى = القيمة الأولية)
List<double> calcEmaSeries(List<double> prices, int period) {
  if (prices.isEmpty) return [];
  if (prices.length < period) {
    return List<double>.filled(prices.length, prices.last);
  }

  final k = 2 / (period + 1);
  final result = List<double>.filled(prices.length, 0);

  // القيمة الأولية = متوسط أول period سعر
  double sum = 0;
  for (int i = 0; i < period; i++) {
    sum += prices[i];
  }
  double ema = sum / period;

  // القيم قبل period = القيمة الأولية (للتعبئة فقط)
  for (int i = 0; i < period; i++) {
    result[i] = ema;
  }
  result[period - 1] = ema;

  // الحساب التصاعدي - O(n) بدل O(n²)
  for (int i = period; i < prices.length; i++) {
    ema = prices[i] * k + ema * (1 - k);
    result[i] = ema;
  }

  return result;
}
/// جلب بيانات OHLC كشموع
Future<List<Candle>?> fetchCandles({
  required String symbol,
  int limit = 60,
}) async {
  try {
    if (symbol.contains('=X') || symbol.contains('=F')) {
      // Yahoo Finance (فوركس + سلع)
      final url = Uri.parse(
          'https://query1.finance.yahoo.com/v8/finance/chart/$symbol?interval=5m&range=1d');
      final r = await http.get(url, headers: {'User-Agent': 'Mozilla/5.0'});
      if (r.statusCode != 200) return null;

      final data = json.decode(r.body);
      final result = data['chart']['result'][0];
      final timestamps = result['timestamp'] as List;
      final quote = result['indicators']['quote'][0];
      final opens = quote['open'] as List;
      final highs = quote['high'] as List;
      final lows = quote['low'] as List;
      final closes = quote['close'] as List;

      final candles = <Candle>[];
      for (int i = 0; i < timestamps.length; i++) {
        if (opens[i] == null ||
            highs[i] == null ||
            lows[i] == null ||
            closes[i] == null) {
          continue;
        }
        candles.add(Candle(
          time: DateTime.fromMillisecondsSinceEpoch(
              (timestamps[i] as int) * 1000),
          open: (opens[i] as num).toDouble(),
          high: (highs[i] as num).toDouble(),
          low: (lows[i] as num).toDouble(),
          close: (closes[i] as num).toDouble(),
        ));
      }
      if (candles.length < 20) return null;
      return candles.length > limit
          ? candles.sublist(candles.length - limit)
          : candles;
    } else {
      // Binance (عملات رقمية)
      final r = await http.get(Uri.parse(
          'https://api.binance.com/api/v3/klines?symbol=$symbol&interval=5m&limit=$limit'));
      if (r.statusCode != 200) return null;

      final d = json.decode(r.body) as List;
      final candles = d
          .map<Candle>((c) => Candle(
                time: DateTime.fromMillisecondsSinceEpoch(c[0] as int),
                open: double.parse(c[1] as String),
                high: double.parse(c[2] as String),
                low: double.parse(c[3] as String),
                close: double.parse(c[4] as String),
              ))
          .toList();

      if (candles.length < 20) return null;
      return candles;
    }
  } catch (e) {
    debugPrint('❌ fetchCandles: $e');
    return null;
  }
}
/// حساب مستويات فيبوناتشي من قائمة شموع
FibonacciLevels? calcFibonacci(List<Candle> candles, {int period = 50}) {
  if (candles.length < 20) return null;

  final recent = candles.length > period
      ? candles.sublist(candles.length - period)
      : candles;

  double high = recent.first.high;
  double low = recent.first.low;
  for (final c in recent) {
    if (c.high > high) high = c.high;
    if (c.low < low) low = c.low;
  }

  if (high == low) return null;

  // الاتجاه: نقارن أول سعر بآخر سعر
  final firstClose = recent.first.close;
  final lastClose = recent.last.close;
  final isUptrend = lastClose > firstClose;

  return FibonacciLevels(
    swingHigh: high,
    swingLow: low,
    isUptrend: isUptrend,
  );
}
// ═══════════════════════════════════════════
// Multi-Timeframe Analysis
// ═══════════════════════════════════════════

/// جلب شموع لإطار زمني محدد
Future<List<double>?> fetchTimeframeKlines({
  required String symbol,
  required String interval, // 1m, 5m, 15m, 1h
  int limit = 100,
}) async {
  try {
    if (symbol.contains('=X') || symbol.contains('=F')) {
      // Forex/Commodities - Yahoo
      final range = interval == '1h' ? '5d' : '1d';
      final url = Uri.parse(
          'https://query1.finance.yahoo.com/v8/finance/chart/$symbol?interval=$interval&range=$range');
      final r = await http.get(url, headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      }).timeout(const Duration(seconds: 8));
      if (r.statusCode != 200) return null;
      final data = json.decode(r.body);
      final quotes =
          data['chart']['result'][0]['indicators']['quote'][0]['close'];
      final closes = (quotes as List)
          .where((c) => c != null)
          .map<double>((c) => (c as num).toDouble())
          .toList();
      if (closes.length < 50) return null;
      return closes;
    } else {
      // Crypto - Binance
      final r = await http.get(Uri.parse(
          'https://api.binance.com/api/v3/klines?symbol=$symbol&interval=$interval&limit=$limit'));
      if (r.statusCode != 200) return null;
      final d = json.decode(r.body);
      final closes =
          d.map<double>((c) => double.parse(c[4] as String)).toList();
      if (closes.length < 50) return null;
      return closes;
    }
  } catch (e) {
    debugPrint('❌ fetchTimeframeKlines($symbol, $interval): $e');
    return null;
  }
}

/// نتيجة تحليل إطار واحد
class TimeframeSignal {
  final String timeframe;  // 1m, 5m, 15m, 1h
  final String signal;     // CALL, PUT, WAIT
  final int confidence;    // 0-100

  TimeframeSignal({
    required this.timeframe,
    required this.signal,
    required this.confidence,
  });
}

/// تحليل إشارة من قائمة أسعار
TimeframeSignal _analyzeTimeframe(
  String timeframe,
  List<double> closes,
  int scoreThreshold,
) {
  if (closes.length < 50) {
    return TimeframeSignal(
      timeframe: timeframe,
      signal: 'WAIT',
      confidence: 0,
    );
  }

  final rsi = calcRsi(closes);
  final ema20 = calcEma(closes, 20);
  final ema50 = calcEma(closes, 50);
  final macd = calcMacd(closes);
  final adx = calcAdx(closes);
  final bb = calcBB(closes);
  final stoch = calcStoch(closes);
  final price = closes.last;

  int buyScore = 0;
  int sellScore = 0;

  if (rsi <= 40) buyScore++;
  if (rsi <= 30) buyScore++;
  if (rsi >= 60) sellScore++;
  if (rsi >= 70) sellScore++;
  if (ema20 > ema50 && price > ema20) buyScore++;
  if (ema20 < ema50 && price < ema20) sellScore++;
  if (macd > 0) buyScore++;
  if (macd < 0) sellScore++;
  if (adx > 25) {
    if (ema20 > ema50) {
      buyScore++;
    } else {
      sellScore++;
    }
  }
  if (price <= bb[1]) buyScore++;
  if (price >= bb[0]) sellScore++;
  if (stoch < 20) buyScore++;
  if (stoch > 80) sellScore++;

  String signal = 'WAIT';
  if (buyScore >= scoreThreshold && buyScore > sellScore) {
    signal = 'CALL';
  } else if (sellScore >= scoreThreshold && sellScore > buyScore) {
    signal = 'PUT';
  }

  final maxScore = buyScore > sellScore ? buyScore : sellScore;
  final confidence = ((maxScore / 9) * 100).round().clamp(0, 99);

  return TimeframeSignal(
    timeframe: timeframe,
    signal: signal,
    confidence: confidence,
  );
}

/// تحليل متعدد الأطر
Future<List<TimeframeSignal>> analyzeMultipleTimeframes({
  required String symbol,
  int scoreThreshold = 2,
}) async {
  const timeframes = ['1m', '5m', '15m', '1h'];
  final results = <TimeframeSignal>[];

  for (final tf in timeframes) {
    final closes = await fetchTimeframeKlines(
      symbol: symbol,
      interval: tf,
    );
    if (closes == null) {
      results.add(TimeframeSignal(
        timeframe: tf,
        signal: 'WAIT',
        confidence: 0,
      ));
    } else {
      results.add(_analyzeTimeframe(tf, closes, scoreThreshold));
    }
  }

  return results;
}

/// حساب التوافق (0-4)
int calculateAlignment(List<TimeframeSignal> signals) {
  if (signals.isEmpty) return 0;

  // نجد الإشارة الأكثر شيوعاً (غير WAIT)
  final counts = <String, int>{};
  for (final s in signals) {
    if (s.signal == 'WAIT') continue;
    counts[s.signal] = (counts[s.signal] ?? 0) + 1;
  }

  if (counts.isEmpty) return 0;
  return counts.values.reduce((a, b) => a > b ? a : b);
}

/// حساب القوة (1-5 نجوم)
int calculateStrength(int alignment) {
  if (alignment >= 4) return 5;
  if (alignment == 3) return 4;
  if (alignment == 2) return 3;
  if (alignment == 1) return 2;
  return 1;
}

/// الإشارة النهائية (بناءً على التوافق)
String getFinalSignal(List<TimeframeSignal> signals) {
  if (signals.isEmpty) return 'WAIT';

  final counts = <String, int>{};
  for (final s in signals) {
    if (s.signal == 'WAIT') continue;
    counts[s.signal] = (counts[s.signal] ?? 0) + 1;
  }

  if (counts.isEmpty) return 'WAIT';
  if (counts.length > 1) {
    // تعارض - نستخدم الإشارة الأقوى
    int callCount = counts['CALL'] ?? 0;
    int putCount = counts['PUT'] ?? 0;
    if (callCount == putCount) return 'WAIT';
    return callCount > putCount ? 'CALL' : 'PUT';
  }

  return counts.keys.first;
}
// ═══════════════════════════════════════════
// Smart Money Concepts (SMC) Detection
// ═══════════════════════════════════════════

/// كشف Order Blocks
List<OrderBlock> detectOrderBlocks(List<Candle> candles, {int lookback = 50}) {
  final blocks = <OrderBlock>[];
  if (candles.length < 10) return blocks;

  final recent = candles.length > lookback
      ? candles.sublist(candles.length - lookback)
      : candles;

  for (int i = 1; i < recent.length - 3; i++) {
    final current = recent[i];
    final next = recent[i + 1];

    // ═══ Bullish Order Block ═══
    // شمعة هابطة قبل حركة صاعدة قوية
    if (!current.isBullish &&
        next.isBullish &&
        next.close > current.high &&
        (next.close - next.open) > (current.open - current.close) * 1.5) {
      blocks.add(OrderBlock(
        high: current.high,
        low: current.low,
        price: current.close,
        time: current.time,
        isBullish: true,
        strength: _obStrength(current, next),
      ));
    }

    // ═══ Bearish Order Block ═══
    // شمعة صاعدة قبل حركة هابطة قوية
    if (current.isBullish &&
        !next.isBullish &&
        next.close < current.low &&
        (next.open - next.close) > (current.close - current.open) * 1.5) {
      blocks.add(OrderBlock(
        high: current.high,
        low: current.low,
        price: current.close,
        time: current.time,
        isBullish: false,
        strength: _obStrength(current, next),
      ));
    }
  }

  // احتفظ بأقوى 10 فقط
  blocks.sort((a, b) => b.strength.compareTo(a.strength));
  return blocks.take(10).toList();
}

int _obStrength(Candle ob, Candle move) {
  final moveSize = (move.close - move.open).abs();
  final obSize = (ob.close - ob.open).abs();
  if (obSize == 0) return 1;
  final ratio = moveSize / obSize;
  if (ratio >= 3) return 5;
  if (ratio >= 2.5) return 4;
  if (ratio >= 2) return 3;
  if (ratio >= 1.5) return 2;
  return 1;
}

/// كشف Fair Value Gaps (FVG)
List<FairValueGap> detectFairValueGaps(List<Candle> candles, {int lookback = 50}) {
  final fvgs = <FairValueGap>[];
  if (candles.length < 3) return fvgs;

  final recent = candles.length > lookback
      ? candles.sublist(candles.length - lookback)
      : candles;

  for (int i = 2; i < recent.length; i++) {
    final c1 = recent[i - 2];
    final c2 = recent[i - 1];
    final c3 = recent[i];

    // ═══ Bullish FVG ═══
    // فجوة بين قمة الشمعة 1 وقاع الشمعة 3
    if (c3.low > c1.high) {
      fvgs.add(FairValueGap(
        high: c3.low,
        low: c1.high,
        time: c2.time,
        isBullish: true,
      ));
    }

    // ═══ Bearish FVG ═══
    // فجوة بين قاع الشمعة 1 وقمة الشمعة 3
    if (c3.high < c1.low) {
      fvgs.add(FairValueGap(
        high: c1.low,
        low: c3.high,
        time: c2.time,
        isBullish: false,
      ));
    }
  }

  // احتفظ بأحدث 10 فقط
  return fvgs.length > 10 ? fvgs.sublist(fvgs.length - 10) : fvgs;
}

/// كشف Break of Structure / Change of Character
List<StructureBreak> detectStructureBreaks(List<Candle> candles,
    {int lookback = 50}) {
  final breaks = <StructureBreak>[];
  if (candles.length < 10) return breaks;

  final recent = candles.length > lookback
      ? candles.sublist(candles.length - lookback)
      : candles;

  // ابحث عن القمم والقيعان
  final swingHighs = <int>[];
  final swingLows = <int>[];

  for (int i = 1; i < recent.length - 1; i++) {
    if (recent[i].high > recent[i - 1].high &&
        recent[i].high > recent[i + 1].high) {
      swingHighs.add(i);
    }
    if (recent[i].low < recent[i - 1].low &&
        recent[i].low < recent[i + 1].low) {
      swingLows.add(i);
    }
  }

  // كشف BOS / CHoCH
  for (int i = 1; i < recent.length; i++) {
    final c = recent[i];

    // BOS Bullish: كسر قمة سابقة
    for (final sh in swingHighs) {
      if (sh < i && c.close > recent[sh].high) {
        breaks.add(StructureBreak(
          type: 'BOS',
          isBullish: true,
          level: recent[sh].high,
          time: c.time,
          price: c.close,
        ));
        swingHighs.remove(sh);
        break;
      }
    }

    // BOS Bearish: كسر قاع سابق
    for (final sl in swingLows) {
      if (sl < i && c.close < recent[sl].low) {
        breaks.add(StructureBreak(
          type: 'BOS',
          isBullish: false,
          level: recent[sl].low,
          time: c.time,
          price: c.close,
        ));
        swingLows.remove(sl);
        break;
      }
    }
  }

  // احتفظ بأحدث 10
  return breaks.length > 10 ? breaks.sublist(breaks.length - 10) : breaks;
}

/// كشف Liquidity Zones
List<LiquidityZone> detectLiquidityZones(List<Candle> candles,
    {int lookback = 50}) {
  final zones = <LiquidityZone>[];
  if (candles.length < 10) return zones;

  final recent = candles.length > lookback
      ? candles.sublist(candles.length - lookback)
      : candles;

  for (int i = 1; i < recent.length - 1; i++) {
    // High liquidity (قمم متساوية)
    if (recent[i].high >= recent[i - 1].high &&
        recent[i].high >= recent[i + 1].high) {
      zones.add(LiquidityZone(
        high: recent[i].high,
        low: recent[i].high * 0.999,
        time: recent[i].time,
        type: 'high',
      ));
    }

    // Low liquidity (قيعان متساوية)
    if (recent[i].low <= recent[i - 1].low &&
        recent[i].low <= recent[i + 1].low) {
      zones.add(LiquidityZone(
        high: recent[i].low * 1.001,
        low: recent[i].low,
        time: recent[i].time,
        type: 'low',
      ));
    }
  }

  return zones.length > 10 ? zones.sublist(zones.length - 10) : zones;
}

/// تحليل SMC الكامل
SMCAnalysis analyzeSMC(List<Candle> candles) {
  final obs = detectOrderBlocks(candles);
  final fvgs = detectFairValueGaps(candles);
  final breaks = detectStructureBreaks(candles);
  final liquidity = detectLiquidityZones(candles);

  // ═══ تحديد الاتجاه ═══
  String trend = 'ranging';
  if (breaks.isNotEmpty) {
    final lastBreaks = breaks.length >= 3
        ? breaks.sublist(breaks.length - 3)
        : breaks;
    int bullCount = 0;
    int bearCount = 0;
    for (final b in lastBreaks) {
      if (b.isBullish) {
        bullCount++;
      } else {
        bearCount++;
      }
    }
    if (bullCount >= 2) {
      trend = 'bullish';
    } else if (bearCount >= 2) {
      trend = 'bearish';
    }
  }

  // ═══ تحديد الميل ═══
  String bias = 'neutral';
  if (trend == 'bullish') {
    bias = 'long';
  } else if (trend == 'bearish') {
    bias = 'short';
  }

  // ═══ حساب النقاط ═══
  int score = 0;
  score += (breaks.length * 8).clamp(0, 30);
  score += (obs.length * 5).clamp(0, 25);
  score += (fvgs.length * 3).clamp(0, 20);
  score += (liquidity.length * 2).clamp(0, 15);
  if (trend != 'ranging') score += 10;
  score = score.clamp(0, 100);

  return SMCAnalysis(
    orderBlocks: obs,
    fvgs: fvgs,
    structureBreaks: breaks,
    liquidityZones: liquidity,
    trend: trend,
    bias: bias,
    score: score,
  );
}
// ═══════════════════════════════════════════
// 1. بيانات الشموع مع السيولة (Volume)
// ═══════════════════════════════════════════
class KlineData {
  final List<double> closes;
  final List<double> volumes;
  KlineData({required this.closes, required this.volumes});
}

Future<KlineData?> fetchKlinesWithVolume({required String symbol}) async {
  try {
    if (symbol.contains('=X') || symbol.contains('=F')) {
      // Yahoo Finance
      final url = Uri.parse('https://query1.finance.yahoo.com/v8/finance/chart/$symbol?interval=1m&range=1d');
      final r = await http.get(url, headers: {'User-Agent': 'Mozilla/5.0'}).timeout(const Duration(seconds: 10));
      if (r.statusCode != 200) return null;
      final data = json.decode(r.body);
      final result = data['chart']['result'][0];
      final quote = result['indicators']['quote'][0];
      final closes = (quote['close'] as List).where((c) => c != null).map((c) => (c as num).toDouble()).toList();
      final volumes = (quote['volume'] as List).where((v) => v != null).map((v) => (v as num).toDouble()).toList();
      return KlineData(closes: closes, volumes: volumes);
    } else {
      // Binance
      final r = await http.get(Uri.parse('https://api.binance.com/api/v3/klines?symbol=$symbol&interval=1m&limit=100'));
      if (r.statusCode != 200) return null;
      final d = json.decode(r.body) as List;
      final closes = d.map<double>((c) => double.parse(c[4] as String)).toList();
      final volumes = d.map<double>((c) => double.parse(c[5] as String)).toList();
      return KlineData(closes: closes, volumes: volumes);
    }
  } catch (e) {
    return null;
  }
}

// ═══════════════════════════════════════════
// 2. كشف الانحراف (Divergence)
// ═══════════════════════════════════════════
List<double> calcRsiSeries(List<double> prices) {
  final rsis = <double>[];
  for (int i = 0; i < prices.length; i++) {
    if (i < 14) {
      rsis.add(50);
      continue;
    }
    rsis.add(calcRsi(prices.sublist(0, i + 1)));
  }
  return rsis;
}

String detectDivergence(List<double> closes, List<double> rsiSeries) {
  if (closes.length < 20 || rsiSeries.length < 20) return 'none';

  double priceHigh = closes[closes.length - 15];
  double priceLow = closes[closes.length - 15];
  double rsiHigh = rsiSeries[rsiSeries.length - 15];
  double rsiLow = rsiSeries[rsiSeries.length - 15];
  int highIndex = closes.length - 15;
  int lowIndex = closes.length - 15;

  for (int i = closes.length - 15; i < closes.length - 1; i++) {
    if (closes[i] > priceHigh) { priceHigh = closes[i]; highIndex = i; }
    if (closes[i] < priceLow) { priceLow = closes[i]; lowIndex = i; }
  }

  final currentHigh = closes.last;
  final currentLow = closes.last;
  final currentRsi = rsiSeries.last;

  // انحراف سلبي: السعر يصعد، RSI يهبط
  if (currentHigh > priceHigh && currentRsi < rsiSeries[highIndex] && currentRsi > 60) {
    return 'bearish';
  }
  // انحراف إيجابي: السعر يهبط، RSI يصعد
  if (currentLow < priceLow && currentRsi > rsiSeries[lowIndex] && currentRsi < 40) {
    return 'bullish';
  }

  return 'none';
}