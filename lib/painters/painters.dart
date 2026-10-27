import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../models/models.dart';

class DragonPainter extends CustomPainter {
  final double glow;
  DragonPainter({required this.glow});

  @override
  void paint(Canvas canvas, Size size) {
    final o = Offset(size.width / 2, size.height / 2);
    final u = size.width / 200;

    canvas.drawCircle(
      o,
      size.width * 0.5,
      Paint()
        ..shader = RadialGradient(colors: [
          AppColors.cyan.withOpacity(0.4 * glow),
          Colors.transparent
        ]).createShader(
            Rect.fromCircle(center: o, radius: size.width * 0.5)),
    );

    final cy = Paint()
      ..color = AppColors.cyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5 * u
      ..strokeCap = StrokeCap.round;

    final gd = Paint()
      ..color = AppColors.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5 * u
      ..strokeCap = StrokeCap.round;

    final wing = Paint()..color = AppColors.violet.withOpacity(0.35);

    canvas.drawCircle(o, 78 * u, gd);

    canvas.drawPath(
      Path()
        ..moveTo(o.dx - 30 * u, o.dy - 10 * u)
        ..quadraticBezierTo(o.dx - 95 * u, o.dy - 60 * u, o.dx - 100 * u,
            o.dy + 20 * u)
        ..quadraticBezierTo(
            o.dx - 80 * u, o.dy + 40 * u, o.dx - 50 * u, o.dy + 10 * u)
        ..close(),
      wing,
    );

    canvas.drawPath(
      Path()
        ..moveTo(o.dx + 30 * u, o.dy - 10 * u)
        ..quadraticBezierTo(o.dx + 95 * u, o.dy - 60 * u, o.dx + 100 * u,
            o.dy + 20 * u)
        ..quadraticBezierTo(
            o.dx + 80 * u, o.dy + 40 * u, o.dx + 50 * u, o.dy + 10 * u)
        ..close(),
      wing,
    );

    canvas.drawPath(
      Path()
        ..moveTo(o.dx - 35 * u, o.dy - 30 * u)
        ..quadraticBezierTo(o.dx - 45 * u, o.dy - 75 * u, o.dx, o.dy - 80 * u)
        ..quadraticBezierTo(o.dx + 45 * u, o.dy - 75 * u, o.dx + 35 * u,
            o.dy - 30 * u)
        ..quadraticBezierTo(o.dx, o.dy - 15 * u, o.dx - 35 * u, o.dy - 30 * u),
      cy,
    );

    canvas.drawCircle(o.translate(-14 * u, -55 * u), 5 * u,
        Paint()..color = AppColors.gold);
    canvas.drawCircle(o.translate(14 * u, -55 * u), 5 * u,
        Paint()..color = AppColors.gold);
    canvas.drawCircle(o.translate(-14 * u, -55 * u), 2 * u,
        Paint()..color = Colors.black);
    canvas.drawCircle(o.translate(14 * u, -55 * u), 2 * u,
        Paint()..color = Colors.black);

    canvas.drawLine(o.translate(-32 * u, -72 * u),
        o.translate(-45 * u, -95 * u), gd);
    canvas.drawLine(o.translate(32 * u, -72 * u), o.translate(45 * u, -95 * u),
        gd);

    canvas.drawPath(
      Path()
        ..moveTo(o.dx, o.dy - 12 * u)
        ..cubicTo(o.dx + 50 * u, o.dy - 5 * u, o.dx + 65 * u, o.dy + 35 * u,
            o.dx + 30 * u, o.dy + 60 * u)
        ..cubicTo(o.dx, o.dy + 80 * u, o.dx - 30 * u, o.dy + 60 * u,
            o.dx - 55 * u, o.dy + 35 * u)
        ..cubicTo(o.dx - 70 * u, o.dy + 10 * u, o.dx - 50 * u, o.dy - 5 * u,
            o.dx - 30 * u, o.dy - 12 * u),
      cy,
    );

    canvas.drawLine(
        o.translate(-18 * u, 62 * u), o.translate(-25 * u, 82 * u), gd);
    canvas.drawLine(o.translate(0, 65 * u), o.translate(0, 88 * u), gd);
    canvas.drawLine(
        o.translate(18 * u, 62 * u), o.translate(25 * u, 82 * u), gd);
  }

  @override
  bool shouldRepaint(covariant DragonPainter oldDelegate) =>
      oldDelegate.glow != glow;
}

class ChartPainter extends CustomPainter {
  final List<double> priceData;
  final List<double> ema20Data;
  final List<double> ema50Data;
  final Color lineColor;

  ChartPainter({
    required this.priceData,
    required this.ema20Data,
    required this.ema50Data,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (priceData.length < 2) return;
    final all = [...priceData, ...ema20Data, ...ema50Data];
    final mn = all.reduce(math.min);
    final mx = all.reduce(math.max);
    final rng = mx - mn;
    if (rng == 0) return;

    final fill = Path()..moveTo(0, size.height);
    for (int i = 0; i < priceData.length; i++) {
      fill.lineTo((i / (priceData.length - 1)) * size.width,
          size.height - ((priceData[i] - mn) / rng) * size.height);
    }
    fill
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [lineColor.withOpacity(0.4), lineColor.withOpacity(0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    final line = Path();
    for (int i = 0; i < priceData.length; i++) {
      final x = (i / (priceData.length - 1)) * size.width;
      final y = size.height - ((priceData[i] - mn) / rng) * size.height;
      if (i == 0) {
        line.moveTo(x, y);
      } else {
        line.lineTo(x, y);
      }
    }
    canvas.drawPath(
      line,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5,
    );

    if (ema20Data.length > 1) {
      final p = Path();
      for (int i = 0; i < ema20Data.length; i++) {
        final x = (i / (ema20Data.length - 1)) * size.width;
        final y = size.height - ((ema20Data[i] - mn) / rng) * size.height;
        if (i == 0) {
          p.moveTo(x, y);
        } else {
          p.lineTo(x, y);
        }
      }
      canvas.drawPath(
        p,
        Paint()
          ..color = AppColors.gold
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }

    if (ema50Data.length > 1) {
      final p = Path();
      for (int i = 0; i < ema50Data.length; i++) {
        final x = (i / (ema50Data.length - 1)) * size.width;
        final y = size.height - ((ema50Data[i] - mn) / rng) * size.height;
        if (i == 0) {
          p.moveTo(x, y);
        } else {
          p.lineTo(x, y);
        }
      }
      canvas.drawPath(
        p,
        Paint()
          ..color = AppColors.cyan
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ChartPainter oldDelegate) => true;
}

// ═══════════════════════════════════════════
// رسم الشموع اليابانية
// ═══════════════════════════════════════════
class CandleChartPainter extends CustomPainter {
  final List<Candle> candles;
  final bool showGrid;

  CandleChartPainter({
    required this.candles,
    this.showGrid = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (candles.isEmpty) return;

    double minPrice = candles.first.low;
    double maxPrice = candles.first.high;
    for (final c in candles) {
      if (c.low < minPrice) minPrice = c.low;
      if (c.high > maxPrice) maxPrice = c.high;
    }
    final range = maxPrice - minPrice;
    if (range == 0) return;

    const padding = 8.0;
    final chartHeight = size.height - padding * 2;
    final chartWidth = size.width;

    // رسم الشبكة
    if (showGrid) {
      final gridPaint = Paint()
        ..color = AppColors.silver.withOpacity(0.08)
        ..strokeWidth = 0.5;
      for (int i = 0; i <= 4; i++) {
        final y = padding + (chartHeight / 4) * i;
        canvas.drawLine(Offset(0, y), Offset(chartWidth, y), gridPaint);
      }
    }

    final candleSlotWidth = chartWidth / candles.length;
    final bodyWidth = candleSlotWidth * 0.65;

    double priceToY(double price) {
      return padding + (1 - (price - minPrice) / range) * chartHeight;
    }

    for (int i = 0; i < candles.length; i++) {
      final c = candles[i];
      final x = i * candleSlotWidth + candleSlotWidth / 2;

      final isBull = c.isBullish;
      final color = isBull ? AppColors.green : AppColors.red;

      // الفتيل (Wick)
      final wickPaint = Paint()
        ..color = color
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(
        Offset(x, priceToY(c.high)),
        Offset(x, priceToY(c.low)),
        wickPaint,
      );

      // الجسم (Body)
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

    // خط السعر الأخير (متقطع)
    final lastCloseY = priceToY(candles.last.close);
    final linePaint = Paint()
      ..color = AppColors.gold.withOpacity(0.5)
      ..strokeWidth = 1;

    const dashWidth = 5.0;
    const dashSpace = 3.0;
    double startX = 0;
    while (startX < chartWidth) {
      canvas.drawLine(
        Offset(startX, lastCloseY),
        Offset(startX + dashWidth, lastCloseY),
        linePaint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CandleChartPainter oldDelegate) {
    return oldDelegate.candles != candles;
  }
}