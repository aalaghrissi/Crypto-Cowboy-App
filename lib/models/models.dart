class SignalLog {
  final String pair;
  final String signal;
  final double price;
  final double rsi;
  final DateTime time;
  double exit;
  String result;

  SignalLog({
    required this.pair,
    required this.signal,
    required this.price,
    required this.rsi,
    required this.time,
    this.exit = 0,
    this.result = 'pending',
  });

  Map<String, dynamic> toJson() => {
        'pair': pair,
        'signal': signal,
        'price': price,
        'rsi': rsi,
        'time': time.toIso8601String(),
        'exit': exit,
        'result': result,
      };

  static SignalLog fromJson(Map<String, dynamic> j) => SignalLog(
        pair: j['pair'],
        signal: j['signal'],
        price: (j['price'] as num).toDouble(),
        rsi: (j['rsi'] as num).toDouble(),
        time: DateTime.parse(j['time']),
        exit: (j['exit'] as num?)?.toDouble() ?? 0,
        result: j['result'] ?? 'pending',
      );
}

class CurrencyPair {
  final String name;
  final String symbol;
  final String category;
  double price = 0;
  double rsi = 50;
  double ema20 = 0;
  double ema50 = 0;
  double macd = 0;
  double adx = 0;
  double bbUpper = 0;
  double bbLower = 0;
  double stochastic = 50;
  double support = 0;
  double resistance = 0;
  double change = 0;
  int buyScore = 0;
  int sellScore = 0;
  int confidence = 0;
  int strength = 0;
  String signal = 'WAIT';
  String grade = 'C';
  String pattern = 'None';
  List<double> priceHistory = [];
  List<double> ema20History = [];
  List<double> ema50History = [];
  bool isFavorite = false;
  DateTime? signalTime;
  DateTime? entryTime;

  CurrencyPair({
    required this.name,
    required this.symbol,
    this.category = 'crypto',
  });
}/// شمعة يابانية واحدة (OHLC)
class Candle {
  final DateTime time;
  final double open;
  final double high;
  final double low;
  final double close;

  Candle({
    required this.time,
    required this.open,
    required this.high,
    required this.low,
    required this.close,
  });

  /// هل الشمعة صاعدة؟
  bool get isBullish => close >= open;

  /// الجزء العلوي من الجسم
  double get bodyTop => isBullish ? close : open;

  /// الجزء السفلي من الجسم
  double get bodyBottom => isBullish ? open : close;

  /// هل هي شمعة دوجي (جسم شبه معدوم)؟
  bool get isDoji {
    final body = (close - open).abs();
    final range = high - low;
    return range > 0 && body / range < 0.1;
  }
}
/// مستويات فيبوناتشي
class FibonacciLevels {
  final double swingHigh;
  final double swingLow;
  final bool isUptrend;

  FibonacciLevels({
    required this.swingHigh,
    required this.swingLow,
    required this.isUptrend,
  });

  double get range => swingHigh - swingLow;

  /// سعر مستوى معين (0.0 = القمة، 1.0 = القاع)
  double priceAt(double ratio) {
    return swingHigh - range * ratio;
  }

  double get level0 => swingHigh;
  double get level236 => priceAt(0.236);
  double get level382 => priceAt(0.382);
  double get level500 => priceAt(0.500);
  double get level618 => priceAt(0.618);
  double get level786 => priceAt(0.786);
  double get level100 => swingLow;

  /// المستوى الحالي (أقرب مستوى للسعر)
  double nearestLevel(double price) {
    final levels = [level236, level382, level500, level618, level786];
    double nearest = levels.first;
    double minDist = (price - nearest).abs();
    for (final l in levels) {
      final d = (price - l).abs();
      if (d < minDist) {
        minDist = d;
        nearest = l;
      }
    }
    return nearest;
  }

  /// نسبة السعر من القمة (0% = قمة، 100% = قاع)
  double ratioAt(double price) {
    if (range == 0) return 0;
    return ((swingHigh - price) / range).clamp(0.0, 1.0);
  }
}
// ═══════════════════════════════════════════
// Price Alert Model
// ═══════════════════════════════════════════
class PriceAlert {
  final String id;
  final String pairName;
  final String symbol;
  final String conditionType;  // price_above, price_below, rsi_above, rsi_below, signal_call, signal_put
  final double targetValue;
  final bool isActive;
  final DateTime createdAt;
  DateTime? lastTriggered;
  bool isEnabled;

  PriceAlert({
    required this.id,
    required this.pairName,
    required this.symbol,
    required this.conditionType,
    required this.targetValue,
    this.isActive = true,
    required this.createdAt,
    this.lastTriggered,
    this.isEnabled = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'pairName': pairName,
        'symbol': symbol,
        'conditionType': conditionType,
        'targetValue': targetValue,
        'isActive': isActive ? 1 : 0,
        'createdAt': createdAt.toIso8601String(),
        'lastTriggered': lastTriggered?.toIso8601String(),
        'isEnabled': isEnabled ? 1 : 0,
      };

  static PriceAlert fromJson(Map<String, dynamic> j) => PriceAlert(
        id: j['id'],
        pairName: j['pairName'],
        symbol: j['symbol'],
        conditionType: j['conditionType'],
        targetValue: (j['targetValue'] as num).toDouble(),
        isActive: (j['isActive'] as int) == 1,
        createdAt: DateTime.parse(j['createdAt']),
        lastTriggered: j['lastTriggered'] != null
            ? DateTime.parse(j['lastTriggered'])
            : null,
        isEnabled: (j['isEnabled'] as int?) == 1,
      );

  String get conditionLabel {
    switch (conditionType) {
      case 'price_above':
        return '📈 السعر أعلى من';
      case 'price_below':
        return '📉 السعر أقل من';
      case 'rsi_above':
        return '📊 RSI أعلى من';
      case 'rsi_below':
        return '📊 RSI أقل من';
      case 'signal_call':
        return '🟢 إشارة CALL';
      case 'signal_put':
        return '🔴 إشارة PUT';
      default:
        return conditionType;
    }
  }

  String get conditionEmoji {
    switch (conditionType) {
      case 'price_above':
        return '📈';
      case 'price_below':
        return '📉';
      case 'rsi_above':
        return '🔴';
      case 'rsi_below':
        return '🟢';
      case 'signal_call':
        return '🟢';
      case 'signal_put':
        return '🔴';
      default:
        return '🔔';
    }
  }

  bool get isPriceCondition =>
      conditionType == 'price_above' || conditionType == 'price_below';
  bool get isRsiCondition =>
      conditionType == 'rsi_above' || conditionType == 'rsi_below';
  bool get isSignalCondition =>
      conditionType == 'signal_call' || conditionType == 'signal_put';
}

// ═══════════════════════════════════════════
// Smart Money Concepts (SMC) Models
// ═══════════════════════════════════════════

/// Order Block
class OrderBlock {
  final double high;
  final double low;
  final double price;       // سعر الشمعة
  final DateTime time;
  final bool isBullish;     // OB صاعد (دعم) أم هابط (مقاومة)
  final int strength;       // 1-5

  OrderBlock({
    required this.high,
    required this.low,
    required this.price,
    required this.time,
    required this.isBullish,
    required this.strength,
  });

  double get mid => (high + low) / 2;
}

/// Fair Value Gap (FVG)
class FairValueGap {
  final double high;
  final double low;
  final DateTime time;
  final bool isBullish;     // FVG صاعد (منطقة دعم) أم هابط

  FairValueGap({
    required this.high,
    required this.low,
    required this.time,
    required this.isBullish,
  });

  double get mid => (high + low) / 2;
  double get size => high - low;
}

/// Break of Structure / Change of Character
class StructureBreak {
  final String type;         // 'BOS' أو 'CHoCH'
  final bool isBullish;      // صاعد أم هابط
  final double level;        // المستوى المكسور
  final DateTime time;
  final double price;

  StructureBreak({
    required this.type,
    required this.isBullish,
    required this.level,
    required this.time,
    required this.price,
  });
}

/// Liquidity Zone
class LiquidityZone {
  final double high;
  final double low;
  final DateTime time;
  final String type;         // 'high' أو 'low'

  LiquidityZone({
    required this.high,
    required this.low,
    required this.time,
    required this.type,
  });
}

/// نتيجة تحليل SMC الكاملة
class SMCAnalysis {
  final List<OrderBlock> orderBlocks;
  final List<FairValueGap> fvgs;
  final List<StructureBreak> structureBreaks;
  final List<LiquidityZone> liquidityZones;
  final String trend;        // 'bullish' / 'bearish' / 'ranging'
  final String bias;         // 'long' / 'short' / 'neutral'
  final int score;           // 0-100

  SMCAnalysis({
    required this.orderBlocks,
    required this.fvgs,
    required this.structureBreaks,
    required this.liquidityZones,
    required this.trend,
    required this.bias,
    required this.score,
  });

  bool get hasSignal => score >= 60;
}