import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onTap,
    );

    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImpl?.requestNotificationsPermission();

    debugPrint('✅ NotificationService initialized');
  }

  void _onTap(NotificationResponse response) {
    debugPrint('📱 Notification tapped: ${response.payload}');
  }

  Future<void> showSignal({
    required String pair,
    required String signal,
    required double price,
    required int confidence,
    required String grade,
  }) async {
    final isCall = signal == 'CALL';
    final emoji = isCall ? '🟢' : '🔴';
    final colorHex = isCall ? '#00E676' : '#FF1744';
    final signalAr = isCall ? 'شراء' : 'بيع';

    final androidDetails = AndroidNotificationDetails(
      'fx_signals_channel',
      'إشارات التداول',
      channelDescription: 'تنبيهات الإشارات الجديدة',
      importance: Importance.max,
      priority: Priority.high,
      color: _hexToColor(colorHex),
      playSound: true,
      enableVibration: true,
      ticker: 'إشارة جديدة',
      styleInformation: BigTextStyleInformation(
        'السعر: ${price.toStringAsFixed(2)}\n'
        'الثقة: $confidence% | التصنيف: $grade',
      ),
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _plugin.show(
      pair.hashCode,
      '$emoji إشارة $signalAr - $pair',
      'السعر: ${price.toStringAsFixed(2)} | الثقة: $confidence%',
      details,
      payload: pair,
    );

    debugPrint('🔔 Notification sent: $signal $pair');
  }
    // ═══════════════════════════════════════════
  // إشعار تنبيه السعر
  // ═══════════════════════════════════════════
  Future<void> showPriceAlert({
    required String pair,
    required String condition,
    required double currentValue,
    required double targetValue,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      'price_alerts_channel',
      'تنبيهات الأسعار',
      channelDescription: 'تنبيهات عند وصول السعر أو RSI لمستوى معين',
      importance: Importance.max,
      priority: Priority.high,
      color: _hexToColor('#FFD700'),
      playSound: true,
      enableVibration: true,
      ticker: 'تنبيه السعر',
      styleInformation: BigTextStyleInformation(
        'الشرط: $condition\n'
        'القيمة الحالية: ${currentValue.toStringAsFixed(4)}\n'
        'القيمة المستهدفة: ${targetValue.toStringAsFixed(4)}',
      ),
      largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _plugin.show(
      pair.hashCode + condition.hashCode,
      '🔔 تنبيه: $pair',
      '$condition → ${currentValue.toStringAsFixed(4)}',
      NotificationDetails(android: androidDetails, iOS: iosDetails),
      payload: pair,
    );

    debugPrint('🔔 Price Alert sent: $pair $condition');
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }
}