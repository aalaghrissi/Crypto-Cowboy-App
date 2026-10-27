import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/translations.dart';
import '../models/models.dart';
import '../painters/painters.dart';
import 'cosmic_background.dart';
import 'candlestick_screen.dart';
import 'smc_screen.dart';

class PairDetailScreen extends StatelessWidget {
  final CurrencyPair pair;
  const PairDetailScreen({super.key, required this.pair});

  Color get sc => pair.signal == 'CALL'
      ? AppColors.green
      : pair.signal == 'PUT'
          ? AppColors.red
          : AppColors.amber;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
          Translation.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: CosmicBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: Text(
              pair.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
            iconTheme: const IconThemeData(color: AppColors.gold),
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GlassCard(
                borderColor: sc,
                child: Column(children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.gold, AppColors.goldDark],
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${Translation.get('grade')}: ${pair.grade}',
                          style: const TextStyle(
                            color: AppColors.background,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Text(
                        '${Translation.get('confidence')}: ${pair.confidence}%',
                        style: TextStyle(
                          color: sc,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    pair.price.toStringAsFixed(pair.price > 100 ? 2 : 5),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'RSI ${pair.rsi.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: AppColors.silver.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 12),
                          GlassCard(
                borderColor: AppColors.cyan,
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CandlestickScreen(pair: pair),
                      ),
                    );
                  },
                  child: Stack(
                    children: [
                      SizedBox(
                        height: 140,
                        width: double.infinity,
                        child: CustomPaint(
                          painter: ChartPainter(
                            priceData: pair.priceHistory,
                            ema20Data: pair.ema20History,
                            ema50Data: pair.ema50History,
                            lineColor: sc,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.gold),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.candlestick_chart,
                                  color: AppColors.gold, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'اضغط للشموع',
                                style: TextStyle(
                                  color: AppColors.gold,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GlassCard(
                borderColor: AppColors.gold,
                child: Column(children: [
                  row('EMA 20', pair.ema20.toStringAsFixed(4), AppColors.gold),
                  row('EMA 50', pair.ema50.toStringAsFixed(4), AppColors.cyan),
                  row(
                    'MACD',
                    pair.macd.toStringAsFixed(5),
                    pair.macd >= 0 ? AppColors.green : AppColors.red,
                  ),
                  row(
                    'ADX',
                    pair.adx.toStringAsFixed(1),
                    pair.adx > 25 ? AppColors.green : AppColors.amber,
                  ),
                  row('BB Upper', pair.bbUpper.toStringAsFixed(4),
                      AppColors.cyan),
                  row('BB Lower', pair.bbLower.toStringAsFixed(4),
                      AppColors.cyan),
                  row(
                    'Stoch',
                    pair.stochastic.toStringAsFixed(1),
                    pair.stochastic < 20
                        ? AppColors.green
                        : pair.stochastic > 80
                            ? AppColors.red
                            : AppColors.amber,
                  ),
                  row(Translation.get('support'),
                      pair.support.toStringAsFixed(4), AppColors.green),
                  row(Translation.get('resistance'),
                      pair.resistance.toStringAsFixed(4), AppColors.red),
                  row(Translation.get('patterns'), pair.pattern, sc),
                ]),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      sc.withOpacity(0.4),
                      sc.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: sc, width: 2.5),
                ),
                child: Column(children: [
                  Icon(
                    pair.signal == 'CALL'
                        ? Icons.trending_up_rounded
                        : pair.signal == 'PUT'
                            ? Icons.trending_down_rounded
                            : Icons.hourglass_empty_rounded,
                    color: sc,
                    size: 40,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pair.signal == 'CALL'
                        ? 'CALL 📈'
                        : pair.signal == 'PUT'
                            ? 'PUT 📉'
                            : 'WAIT ⏸️',
                    style: TextStyle(
                      color: sc,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ]),
              ),
                            const SizedBox(height: 12),

              // 🧠 زر Smart Money Concepts
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SMCScreen(pair: pair),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF667EEA),
                        Color(0xFF764BA2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF667EEA).withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.psychology,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🧠 Smart Money Concepts',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'تحليل احترافي متقدم (SMC)',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // 🧠 زر Smart Money Concepts
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SMCScreen(pair: pair),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF667EEA),
                        Color(0xFF764BA2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF667EEA).withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.psychology,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '🧠 Smart Money Concepts',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'تحليل احترافي متقدم (SMC)',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget row(String l, String v, Color c) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l,
              style: TextStyle(
                color: AppColors.silver.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
            Text(
              v,
              style: TextStyle(
                color: c,
                fontSize: 12,
                fontFamily: 'monospace',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
}