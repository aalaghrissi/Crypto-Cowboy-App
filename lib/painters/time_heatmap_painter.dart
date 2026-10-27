import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../models/time_dna.dart';

/// Painter لرسم خريطة حرارية زمنية
class TimeHeatmapPainter extends CustomPainter {
  final Map<String, TimeCell> cells;

  TimeHeatmapPainter({required this.cells});

  @override
  void paint(Canvas canvas, Size size) {
    // ═══ الأبعاد ═══
    const leftMargin = 50.0;
    const topMargin = 20.0;
    const cellSpacing = 1.5;

    final gridWidth = size.width - leftMargin;
    final gridHeight = size.height - topMargin;

    final cellW = (gridWidth - cellSpacing * 23) / 24;
    final cellH = (gridHeight - cellSpacing * 6) / 7;

    // ═══ رسم العناوين ═══
    _drawLabels(canvas, leftMargin, topMargin, cellW, cellH, cellSpacing);

    // ═══ رسم الخلايا ═══
    for (int day = 1; day <= 7; day++) {
      for (int hour = 0; hour < 24; hour++) {
        final key = '$day-$hour';
        final cell = cells[key];

        final x = leftMargin + hour * (cellW + cellSpacing);
        final y = topMargin + (day - 1) * (cellH + cellSpacing);

        final rect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, cellW, cellH),
          const Radius.circular(2),
        );

        // اللون حسب الأداء
        Color color;
        if (cell == null || cell.total == 0) {
          color = AppColors.backgroundThree.withOpacity(0.2);
        } else if (cell.total < 3) {
          color = AppColors.silver.withOpacity(0.2);
        } else {
          final rate = cell.winRate;
          if (rate >= 70) {
            color = AppColors.green.withOpacity(0.9);
          } else if (rate >= 55) {
            color = AppColors.green.withOpacity(0.6);
          } else if (rate >= 45) {
            color = AppColors.amber.withOpacity(0.5);
          } else if (rate >= 35) {
            color = AppColors.red.withOpacity(0.6);
          } else {
            color = AppColors.red.withOpacity(0.9);
          }
        }

        canvas.drawRRect(rect, Paint()..color = color);
      }
    }
  }

  void _drawLabels(
    Canvas canvas,
    double leftMargin,
    double topMargin,
    double cellW,
    double cellH,
    double cellSpacing,
  ) {
    // ═══ أسماء الأيام ═══
    const dayNames = ['اثن', 'ثلا', 'أرب', 'خمي', 'جمع', 'سبت', 'أحد'];
    for (int d = 0; d < 7; d++) {
      final y = topMargin + d * (cellH + cellSpacing) + cellH / 2;
      final tp = TextPainter(
        text: TextSpan(
          text: dayNames[d],
          style: TextStyle(
            color: AppColors.silver.withOpacity(0.7),
            fontSize: 9,
          ),
        ),
        textDirection: TextDirection.rtl,
      )..layout();
      tp.paint(
        canvas,
        Offset(leftMargin - 8 - tp.width, y - tp.height / 2),
      );
    }

    // ═══ أرقام الساعات (كل 3 ساعات) ═══
    for (int h = 0; h < 24; h += 3) {
      final x = leftMargin + h * (cellW + cellSpacing) + cellW / 2;
      final tp = TextPainter(
        text: TextSpan(
          text: '$h',
          style: TextStyle(
            color: AppColors.silver.withOpacity(0.7),
            fontSize: 9,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
        canvas,
        Offset(x - tp.width / 2, topMargin - tp.height - 3),
      );
    }
  }

  @override
  bool shouldRepaint(covariant TimeHeatmapPainter oldDelegate) {
    return oldDelegate.cells != cells;
  }
}