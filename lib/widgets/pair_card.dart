import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../models/models.dart';
import 'detail_screen.dart';

class PairCard extends StatelessWidget {
  final CurrencyPair pair;
  final int secondsToEntry;

  const PairCard({
    super.key,
    required this.pair,
    this.secondsToEntry = -1,
  });

  @override
  Widget build(BuildContext context) {
    final isCall = pair.signal == 'CALL';
    final isPut = pair.signal == 'PUT';
    final activeColor = isCall 
        ? AppColors.green 
        : isPut 
            ? AppColors.red 
            : AppColors.silver;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PairDetailScreen(pair: pair)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 12, right: 12),
        decoration: BoxDecoration(
          // خلفية زجاجية شفافة لرؤية صورة الكاوبوي
          color: AppColors.background.withOpacity(0.65),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCall || isPut ? activeColor.withOpacity(0.5) : AppColors.silver.withOpacity(0.1),
            width: 1,
          ),
          boxShadow: [
            if (isCall || isPut)
              BoxShadow(
                color: activeColor.withOpacity(0.15),
                blurRadius: 10,
                spreadRadius: 1,
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              // توهج جانبي حسب نوع الإشارة
              if (isCall || isPut)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: activeColor,
                      boxShadow: [
                        BoxShadow(color: activeColor, blurRadius: 8, spreadRadius: 1),
                      ],
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    // ═══ الصف الأول: الاسم، النجمة، والتصنيف ═══
                    Row(
                      children: [
                        Text(
                          pair.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _gradeBadge(),
                        const Spacer(),
                        Icon(
                          pair.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                          color: pair.isFavorite ? AppColors.gold : AppColors.silver.withOpacity(0.3),
                          size: 20,
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 12),

                    // ═══ الصف الثاني: السعر والتغير والإشارة ═══
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pair.price > 100
                                    ? pair.price.toStringAsFixed(2)
                                    : pair.price.toStringAsFixed(4),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'monospace',
                                  letterSpacing: -1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    pair.change >= 0 ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                                    color: pair.change >= 0 ? AppColors.green : AppColors.red,
                                    size: 16,
                                  ),
                                  Text(
                                    '${pair.change.abs().toStringAsFixed(2)}%',
                                    style: TextStyle(
                                      color: pair.change >= 0 ? AppColors.green : AppColors.red,
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // زر الإشارة المتوهج
                        if (isCall || isPut)
                          _buildSignalButton(activeColor, pair.signal)
                        else
                          _buildWaitButton(),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // ═══ الصف الثالث: المؤشرات (RSI, CONF, ENTRY) ═══
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildIndicator('CONF', '${pair.confidence}%', AppColors.gold),
                        _buildIndicator('RSI', pair.rsi.toStringAsFixed(1), 
                          pair.rsi > 70 ? AppColors.red : pair.rsi < 30 ? AppColors.green : AppColors.silver),
                        if (secondsToEntry > 0)
                          _buildIndicator('ENTRY', '${secondsToEntry}s', AppColors.cyan)
                        else
                          _buildIndicator('ENTRY', '--', AppColors.silver.withOpacity(0.3)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // شارة التصنيف (A+)
  Widget _gradeBadge() {
    Color color;
    switch (pair.grade) {
      case 'A+': color = AppColors.gold; break;
      case 'A': color = AppColors.green; break;
      case 'B': color = AppColors.cyan; break;
      default: color = AppColors.silver;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        pair.grade,
        style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  // زر الشراء / البيع
  Widget _buildSignalButton(Color color, String signal) {
    final isCall = signal == 'CALL';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.4), blurRadius: 12, spreadRadius: 2),
        ],
      ),
      child: Row(
        children: [
          Icon(
            isCall ? Icons.trending_up : Icons.trending_down,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 6),
          Text(
            isCall ? 'CALL' : 'PUT',
            style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  // زر الانتظار
  Widget _buildWaitButton() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.silver.withOpacity(0.3), width: 1),
      ),
      child: const Text(
        'WAIT',
        style: TextStyle(color: AppColors.silver, fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 1),
      ),
    );
  }

  // مؤشرات صغيرة
  Widget _buildIndicator(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: AppColors.silver.withOpacity(0.5), fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
        ),
      ],
    );
  }
}