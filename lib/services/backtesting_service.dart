import '../models/models.dart';
import '../utils/indicators.dart';

// ═══════════════════════════════════════════
// نتيجة اختبار زوج واحد
// ═══════════════════════════════════════════
class BacktestResult {
  final String pair;
  final String symbol;
  final int totalSignals;
  final int callSignals;
  final int putSignals;
  final int wins;
  final int losses;
  final int callWins;
  final int putWins;
  final double winRate;
  final double avgMove;
  final double bestMove;
  final double worstMove;
  final int testedCandles;
  final int lookahead;

  BacktestResult({
    required this.pair,
    required this.symbol,
    required this.totalSignals,
    required this.callSignals,
    required this.putSignals,
    required this.wins,
    required this.losses,
    required this.callWins,
    required this.putWins,
    required this.winRate,
    required this.avgMove,
    required this.bestMove,
    required this.worstMove,
    required this.testedCandles,
    required this.lookahead,
  });

  int get callLosses => callSignals - callWins;
  int get putLosses => putSignals - putWins;
  double get callWinRate =>
      callSignals > 0 ? (callWins / callSignals * 100) : 0;
  double get putWinRate =>
      putSignals > 0 ? (putWins / putSignals * 100) : 0;
}

// ═══════════════════════════════════════════
// Service
// ═══════════════════════════════════════════
class BacktestingService {
  BacktestingService._();
  static final BacktestingService instance = BacktestingService._();

  /// اختبار زوج واحد
  Future<BacktestResult?> runBacktest({
    required CurrencyPair pair,
    int scoreThreshold = 2,
    int lookahead = 5,
  }) async {
    // 1️⃣ جلب بيانات تاريخية
    final closes = await fetchHistoricalKlines(symbol: pair.symbol);
    if (closes == null || closes.length < 100) return null;

    // 2️⃣ إحصائيات
    int totalSignals = 0;
    int callSignals = 0;
    int putSignals = 0;
    int wins = 0;
    int losses = 0;
    int callWins = 0;
    int putWins = 0;
    double totalMove = 0;
    double bestMove = 0;
    double worstMove = 0;

    // 3️⃣ نمر على البيانات
    final start = 50;
    final end = closes.length - lookahead;

    for (int i = start; i < end; i++) {
      final historical = closes.sublist(0, i + 1);

      final rsi = calcRsi(historical);
      final ema20 = calcEma(historical, 20);
      final ema50 = calcEma(historical, 50);
      final macd = calcMacd(historical);
      final adx = calcAdx(historical);
      final bb = calcBB(historical);
      final stoch = calcStoch(historical);
      final pattern = detectPattern(historical);

      final price = historical.last;

      int buyScore = 0, sellScore = 0;
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
      if (pattern == 'Bullish Engulfing' || pattern == 'Hammer') {
        buyScore += 2;
      }
      if (pattern == 'Bearish Engulfing' || pattern == 'Shooting Star') {
        sellScore += 2;
      }

      String signal = 'WAIT';
      if (buyScore >= scoreThreshold && buyScore > sellScore) {
        signal = 'CALL';
      } else if (sellScore >= scoreThreshold && sellScore > buyScore) {
        signal = 'PUT';
      }

      if (signal == 'WAIT') continue;

      // 4️⃣ احكم على النتيجة
      final futurePrice = closes[i + lookahead];
      final movePercent = ((futurePrice - price) / price) * 100;

      totalSignals++;
      totalMove += movePercent;
      if (movePercent > bestMove) bestMove = movePercent;
      if (movePercent < worstMove) worstMove = movePercent;

      bool won = false;
      if (signal == 'CALL') {
        callSignals++;
        won = futurePrice > price;
        if (won) callWins++;
      } else {
        putSignals++;
        won = futurePrice < price;
        if (won) putWins++;
      }

      if (won) {
        wins++;
      } else {
        losses++;
      }
    }

    if (totalSignals == 0) return null;

    return BacktestResult(
      pair: pair.name,
      symbol: pair.symbol,
      totalSignals: totalSignals,
      callSignals: callSignals,
      putSignals: putSignals,
      wins: wins,
      losses: losses,
      callWins: callWins,
      putWins: putWins,
      winRate: (wins / totalSignals) * 100,
      avgMove: totalMove / totalSignals,
      bestMove: bestMove,
      worstMove: worstMove,
      testedCandles: closes.length,
      lookahead: lookahead,
    );
  }

  /// اختبار عدة أزواج
  Future<List<BacktestResult>> runBatchBacktest({
    required List<CurrencyPair> pairs,
    int scoreThreshold = 2,
    int lookahead = 5,
    Function(int done, int total)? onProgress,
  }) async {
    final results = <BacktestResult>[];
    for (int i = 0; i < pairs.length; i++) {
      final result = await runBacktest(
        pair: pairs[i],
        scoreThreshold: scoreThreshold,
        lookahead: lookahead,
      );
      if (result != null) results.add(result);
      onProgress?.call(i + 1, pairs.length);
    }
    results.sort((a, b) => b.winRate.compareTo(a.winRate));
    return results;
  }
}