import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

/// خدمة إدارة التنبيهات
class AlertService {
  AlertService._();
  static final AlertService instance = AlertService._();

  static const String _storageKey = 'price_alerts';

  List<PriceAlert> _alerts = [];
  List<PriceAlert> get alerts => _alerts;

  // ═══════════════════════════════════════════
  // تحميل / حفظ
  // ═══════════════════════════════════════════
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList(_storageKey) ?? [];
    _alerts = data
        .map((s) => PriceAlert.fromJson(json.decode(s)))
        .toList();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      _alerts.map((a) => json.encode(a.toJson())).toList(),
    );
  }

  // ═══════════════════════════════════════════
  // إضافة تنبيه
  // ═══════════════════════════════════════════
  Future<void> addAlert(PriceAlert alert) async {
    _alerts.add(alert);
    await _save();
  }

  // ═══════════════════════════════════════════
  // حذف تنبيه
  // ═══════════════════════════════════════════
  Future<void> removeAlert(String id) async {
    _alerts.removeWhere((a) => a.id == id);
    await _save();
  }

  // ═══════════════════════════════════════════
  // تعديل حالة
  // ═══════════════════════════════════════════
  Future<void> toggleAlert(String id) async {
    final idx = _alerts.indexWhere((a) => a.id == id);
    if (idx >= 0) {
      _alerts[idx].isEnabled = !_alerts[idx].isEnabled;
      await _save();
    }
  }

  // ═══════════════════════════════════════════
  // حذف الكل
  // ═══════════════════════════════════════════
  Future<void> clearAll() async {
    _alerts.clear();
    await _save();
  }

  // ═══════════════════════════════════════════
  // فحص التنبيهات
  // ═══════════════════════════════════════════
  /// يعيد قائمة التنبيهات التي تحققت شروطها
  List<PriceAlert> checkAlerts(CurrencyPair pair) {
    final triggered = <PriceAlert>[];

    for (final alert in _alerts) {
      // تجاهل التنبيهات المعطلة أو لأزواج أخرى
      if (!alert.isEnabled) continue;
      if (alert.symbol != pair.symbol) continue;

      // تجاهل التنبيهات التي تم إطلاقها مؤخراً (< 5 دقائق)
      if (alert.lastTriggered != null) {
        final diff = DateTime.now().difference(alert.lastTriggered!);
        if (diff.inMinutes < 5) continue;
      }

      bool shouldTrigger = false;

      switch (alert.conditionType) {
        case 'price_above':
          shouldTrigger = pair.price >= alert.targetValue;
          break;
        case 'price_below':
          shouldTrigger = pair.price <= alert.targetValue;
          break;
        case 'rsi_above':
          shouldTrigger = pair.rsi >= alert.targetValue;
          break;
        case 'rsi_below':
          shouldTrigger = pair.rsi <= alert.targetValue;
          break;
        case 'signal_call':
          shouldTrigger = pair.signal == 'CALL';
          break;
        case 'signal_put':
          shouldTrigger = pair.signal == 'PUT';
          break;
      }

      if (shouldTrigger) {
        alert.lastTriggered = DateTime.now();
        triggered.add(alert);
      }
    }

    if (triggered.isNotEmpty) {
      _save();
    }

    return triggered;
  }

  // ═══════════════════════════════════════════
  // إحصائيات
  // ═══════════════════════════════════════════
  int get activeCount => _alerts.where((a) => a.isEnabled).length;
  int get totalCount => _alerts.length;
}