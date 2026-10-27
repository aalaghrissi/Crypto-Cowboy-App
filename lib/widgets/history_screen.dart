import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';
import '../constants/translations.dart';
import '../state/app_state.dart';
import 'cosmic_background.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  Widget build(BuildContext context) {
    final stats = AppState.stats();
    if (AppState.history.isEmpty) {
      return Center(
        child: Text(
          Translation.get('noData'),
          style: TextStyle(
            color: AppColors.silver.withOpacity(0.6),
            fontSize: 15,
          ),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        GlassCard(
          borderColor: AppColors.gold,
          child: Column(children: [
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.emoji_events, color: AppColors.gold, size: 22),
                SizedBox(width: 8),
                Text(
                  'STATISTICS',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                statBox('${stats['total']}', 'Total', AppColors.cyan),
                statBox(
                  '${stats['wins']}',
                  Translation.get('win'),
                  AppColors.green,
                ),
                statBox(
                  '${stats['losses']}',
                  Translation.get('loss'),
                  AppColors.red,
                ),
                statBox('${stats['rate']}%', '%', AppColors.gold),
              ],
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: actionBtn(
              '📤 ${Translation.get('export')}',
              AppColors.cyan,
              () async {
                final csv =
                    StringBuffer('Time,Pair,Signal,Price,Result,RSI\n');
                for (final l in AppState.history) {
                  csv.writeln(
                    '${l.time.toIso8601String()},${l.pair},${l.signal},${l.price},${l.result},${l.rsi}',
                  );
                }
                await Clipboard.setData(
                  ClipboardData(text: csv.toString()),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: actionBtn(
              '🗑️ ${Translation.get('clear')}',
              AppColors.red,
              () async {
                await AppState.clearHistory();
                setState(() {});
              },
            ),
          ),
        ]),
        const SizedBox(height: 12),
        ...AppState.history.map((log) {
          final c = log.signal == 'CALL' ? AppColors.green : AppColors.red;
          final rc = log.result == 'win'
              ? AppColors.green
              : log.result == 'loss'
                  ? AppColors.red
                  : AppColors.silver;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                AppColors.backgroundTwo.withOpacity(0.6),
                AppColors.backgroundThree.withOpacity(0.4),
              ]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.withOpacity(0.5), width: 1.2),
            ),
            child: Row(children: [
              Icon(
                log.result == 'win'
                    ? Icons.check_circle
                    : log.result == 'loss'
                        ? Icons.cancel
                        : Icons.hourglass_empty,
                color: rc,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.pair,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${log.time.hour.toString().padLeft(2, '0')}:${log.time.minute.toString().padLeft(2, '0')} • RSI ${log.rsi.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: AppColors.silver.withOpacity(0.6),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    log.signal,
                    style: TextStyle(
                      color: c,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    log.result.toUpperCase(),
                    style: TextStyle(
                      color: rc,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ]),
          );
        }),
      ],
    );
  }

  Widget statBox(String v, String l, Color c) => Column(children: [
        Text(
          v,
          style: TextStyle(
            color: c,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          l,
          style: TextStyle(
            color: AppColors.silver.withOpacity(0.6),
            fontSize: 9,
          ),
        ),
      ]);

  Widget actionBtn(String label, Color c, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              c.withOpacity(0.3),
              c.withOpacity(0.1),
            ]),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: c.withOpacity(0.6)),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: c,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      );
}