import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/translations.dart';
import '../models/models.dart';

class AppState extends ChangeNotifier {
  // ═══════════════════════════════════════════
  // Singleton
  // ═══════════════════════════════════════════
  AppState._internal();
  static final AppState instance = AppState._internal();

  // ═══════════════════════════════════════════
  // البيانات الفعلية
  // ═══════════════════════════════════════════
  final List<CurrencyPair> _pairs = [
    CurrencyPair(name: 'BTC/USD', symbol: 'BTCUSDT', category: 'crypto'),
    CurrencyPair(name: 'ETH/USD', symbol: 'ETHUSDT', category: 'crypto'),
    CurrencyPair(name: 'BNB/USD', symbol: 'BNBUSDT', category: 'crypto'),
    CurrencyPair(name: 'SOL/USD', symbol: 'SOLUSDT', category: 'crypto'),
    CurrencyPair(name: 'XRP/USD', symbol: 'XRPUSDT', category: 'crypto'),
    CurrencyPair(name: 'ADA/USD', symbol: 'ADAUSDT', category: 'crypto'),
    CurrencyPair(name: 'DOGE/USD', symbol: 'DOGEUSDT', category: 'crypto'),
    CurrencyPair(name: 'AVAX/USD', symbol: 'AVAXUSDT', category: 'crypto'),
    CurrencyPair(name: 'DOT/USD', symbol: 'DOTUSDT', category: 'crypto'),
    CurrencyPair(name: 'LINK/USD', symbol: 'LINKUSDT', category: 'crypto'),
    CurrencyPair(name: 'LTC/USD', symbol: 'LTCUSDT', category: 'crypto'),
    CurrencyPair(name: 'TRX/USD', symbol: 'TRXUSDT', category: 'crypto'),
    CurrencyPair(name: 'ATOM/USD', symbol: 'ATOMUSDT', category: 'crypto'),
    CurrencyPair(name: 'ETC/USD', symbol: 'ETCUSDT', category: 'crypto'),
    CurrencyPair(name: 'BCH/USD', symbol: 'BCHUSDT', category: 'crypto'),
    CurrencyPair(name: 'MATIC/USD', symbol: 'MATICUSDT', category: 'crypto'),
    CurrencyPair(name: 'EUR/USD', symbol: 'EURUSD=X', category: 'forex'),
    CurrencyPair(name: 'GBP/USD', symbol: 'GBPUSD=X', category: 'forex'),
    CurrencyPair(name: 'USD/JPY', symbol: 'USDJPY=X', category: 'forex'),
    CurrencyPair(name: 'AUD/USD', symbol: 'AUDUSD=X', category: 'forex'),
    CurrencyPair(name: 'USD/CAD', symbol: 'USDCAD=X', category: 'forex'),
    CurrencyPair(name: 'USD/CHF', symbol: 'USDCHF=X', category: 'forex'),
    CurrencyPair(name: 'NZD/USD', symbol: 'NZDUSD=X', category: 'forex'),
    CurrencyPair(name: 'EUR/GBP', symbol: 'EURGBP=X', category: 'forex'),
    CurrencyPair(name: 'EUR/JPY', symbol: 'EURJPY=X', category: 'forex'),
    CurrencyPair(name: 'GBP/JPY', symbol: 'GBPJPY=X', category: 'forex'),
    CurrencyPair(name: 'EUR/CHF', symbol: 'EURCHF=X', category: 'forex'),
    CurrencyPair(name: 'EUR/AUD', symbol: 'EURAUD=X', category: 'forex'),
    CurrencyPair(name: 'EUR/CAD', symbol: 'EURCAD=X', category: 'forex'),
    CurrencyPair(name: 'GBP/CHF', symbol: 'GBPCHF=X', category: 'forex'),
    CurrencyPair(name: 'GBP/AUD', symbol: 'GBPAUD=X', category: 'forex'),
    CurrencyPair(name: 'GBP/CAD', symbol: 'GBPCAD=X', category: 'forex'),
    CurrencyPair(name: 'AUD/JPY', symbol: 'AUDJPY=X', category: 'forex'),
    CurrencyPair(name: 'AUD/CAD', symbol: 'AUDCAD=X', category: 'forex'),
    CurrencyPair(name: 'AUD/CHF', symbol: 'AUDCHF=X', category: 'forex'),
    CurrencyPair(name: 'CAD/JPY', symbol: 'CADJPY=X', category: 'forex'),
    CurrencyPair(name: 'CAD/CHF', symbol: 'CADCHF=X', category: 'forex'),
    CurrencyPair(name: 'CHF/JPY', symbol: 'CHFJPY=X', category: 'forex'),
    CurrencyPair(name: 'NZD/JPY', symbol: 'NZDJPY=X', category: 'forex'),
    CurrencyPair(name: 'NZD/CAD', symbol: 'NZDCAD=X', category: 'forex'),
    CurrencyPair(name: 'NZD/CHF', symbol: 'NZDCHF=X', category: 'forex'),
    CurrencyPair(name: 'XAU/USD', symbol: 'GC=F', category: 'commodity'),
    CurrencyPair(name: 'XAG/USD', symbol: 'SI=F', category: 'commodity'),
  ];

  final List<SignalLog> _history = [];
  final List<String> _favorites = [];
  double _rsiBuyMax = 40;
  double _rsiSellMin = 60;
  int _refreshMinutes = 1;
  int _scoreThreshold = 2;
  bool _onlyStrong = false;
  bool _darkMode = true;
  bool _soundOn = true;
  bool _vibrationOn = true;
  bool _warningShown = false;
  bool _voiceEnabled = true;
  String? _hologramImagePath;

  // ═══════════════════════════════════════════
  // Static Getters / Setters
  // ═══════════════════════════════════════════
  static List<CurrencyPair> get pairs => instance._pairs;
  static List<SignalLog> get history => instance._history;
  static List<String> get favorites => instance._favorites;

  static double get rsiBuyMax => instance._rsiBuyMax;
  static set rsiBuyMax(double v) {
    instance._rsiBuyMax = v;
    instance.notify();
  }

  static double get rsiSellMin => instance._rsiSellMin;
  static set rsiSellMin(double v) {
    instance._rsiSellMin = v;
    instance.notify();
  }

  static int get refreshMinutes => instance._refreshMinutes;
  static set refreshMinutes(int v) {
    instance._refreshMinutes = v;
    instance.notify();
  }

  static int get scoreThreshold => instance._scoreThreshold;
  static set scoreThreshold(int v) {
    instance._scoreThreshold = v;
    instance.notify();
  }

  static bool get onlyStrong => instance._onlyStrong;
  static set onlyStrong(bool v) {
    instance._onlyStrong = v;
    instance.notify();
  }

  static bool get darkMode => instance._darkMode;
  static set darkMode(bool v) {
    instance._darkMode = v;
    instance.notify();
  }

  static bool get soundOn => instance._soundOn;
  static set soundOn(bool v) {
    instance._soundOn = v;
    instance.notify();
  }

  static bool get vibrationOn => instance._vibrationOn;
  static set vibrationOn(bool v) {
    instance._vibrationOn = v;
    instance.notify();
  }

  static bool get warningShown => instance._warningShown;
  static set warningShown(bool v) {
    instance._warningShown = v;
    instance.notify();
  }
  static bool get voiceEnabled => instance._voiceEnabled;
  static set voiceEnabled(bool v) {
    instance._voiceEnabled = v;
    instance.notify();
  }
  static String? get hologramImagePath => instance._hologramImagePath;
static set hologramImagePath(String? v) {
  instance._hologramImagePath = v;
  instance.notify();
}

  // ═══════════════════════════════════════════
  // دوال مساعدة
  // ═══════════════════════════════════════════
  void notify() => notifyListeners();

  // ═══════════════════════════════════════════
  // تحميل / حفظ
  // ═══════════════════════════════════════════
  static Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    instance._rsiBuyMax = p.getDouble('rsiBuy') ?? 40;
    instance._rsiSellMin = p.getDouble('rsiSell') ?? 60;
    instance._refreshMinutes = p.getInt('refresh') ?? 1;
    instance._scoreThreshold = p.getInt('score') ?? 2;
    instance._onlyStrong = p.getBool('strong') ?? false;
    instance._darkMode = p.getBool('dark') ?? true;
    instance._soundOn = p.getBool('sound') ?? true;
    instance._vibrationOn = p.getBool('vibration') ?? true;
    instance._warningShown = p.getBool('warningShown') ?? false;
    instance._voiceEnabled = p.getBool('voiceEnabled') ?? true;
    instance._hologramImagePath = p.getString('hologramImagePath');
    Translation.language = p.getString('language') ?? 'ar';

    instance._favorites.clear();
    instance._favorites.addAll(p.getStringList('favorites') ?? []);

    for (final pair in instance._pairs) {
      pair.isFavorite = instance._favorites.contains(pair.symbol);
    }

    instance._history.clear();
    instance._history.addAll(
      (p.getStringList('history') ?? [])
          .map((s) => SignalLog.fromJson(json.decode(s)))
          .toList(),
    );

    instance.notify();
  }

  static Future<void> save() async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble('rsiBuy', instance._rsiBuyMax);
    await p.setDouble('rsiSell', instance._rsiSellMin);
    await p.setInt('refresh', instance._refreshMinutes);
    await p.setInt('score', instance._scoreThreshold);
    await p.setBool('strong', instance._onlyStrong);
    await p.setBool('dark', instance._darkMode);
    await p.setBool('sound', instance._soundOn);
    await p.setBool('vibration', instance._vibrationOn);
    await p.setBool('warningShown', instance._warningShown);
    await p.setBool('voiceEnabled', instance._voiceEnabled);
    if (instance._hologramImagePath != null) {
  await p.setString('hologramImagePath', instance._hologramImagePath!);
}
    await p.setString('language', Translation.language);
    await p.setStringList('favorites', instance._favorites);
  }

  // ═══════════════════════════════════════════
  // عمليات على البيانات
  // ═══════════════════════════════════════════
  static Future<void> toggleFav(String symbol) async {
    if (instance._favorites.contains(symbol)) {
      instance._favorites.remove(symbol);
    } else {
      instance._favorites.add(symbol);
    }
    for (final p in instance._pairs) {
      p.isFavorite = instance._favorites.contains(p.symbol);
    }
    await save();
    instance.notify();
  }

  static Future<void> addHistory(SignalLog log) async {
    instance._history.insert(0, log);
    if (instance._history.length > 300) instance._history.removeLast();
    final p = await SharedPreferences.getInstance();
    await p.setStringList(
      'history',
      instance._history.map((s) => json.encode(s.toJson())).toList(),
    );
    instance.notify();
  }

  static Future<void> updateHistory() async {
    final p = await SharedPreferences.getInstance();
    await p.setStringList(
      'history',
      instance._history.map((s) => json.encode(s.toJson())).toList(),
    );
    instance.notify();
  }

  static Future<void> clearHistory() async {
    instance._history.clear();
    final p = await SharedPreferences.getInstance();
    await p.remove('history');
    instance.notify();
  }

  // ═══════════════════════════════════════════
  // إحصائيات
  // ═══════════════════════════════════════════
  static Map<String, int> stats() {
    int w = 0, l = 0;
    for (final h in instance._history) {
      if (h.result == 'win') {
        w++;
      } else if (h.result == 'loss') {
        l++;
      }
    }
    final total = w + l;
    return {
      'total': instance._history.length,
      'wins': w,
      'losses': l,
      'rate': total > 0 ? ((w / total) * 100).round() : 0,
    };
  }

  static Map<String, int> todayStats() {
    final t = DateTime.now();
    int c = 0, p = 0;
    for (final h in instance._history) {
      if (h.time.year == t.year &&
          h.time.month == t.month &&
          h.time.day == t.day) {
        if (h.signal == 'CALL') {
          c++;
        } else {
          p++;
        }
      }
    }
    return {'calls': c, 'puts': p, 'total': c + p};
  }
}