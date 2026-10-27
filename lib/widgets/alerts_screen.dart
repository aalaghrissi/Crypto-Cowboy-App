import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/translations.dart';
import '../models/models.dart';
import '../services/alert_service.dart';
import '../state/app_state.dart';
import 'cosmic_background.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  @override
  void initState() {
    super.initState();
    AlertService.instance.load().then((_) {
      if (mounted) setState(() {});
    });
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (_) => _AddAlertDialog(
        onAdded: () => setState(() {}),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alerts = AlertService.instance.alerts;

    return Directionality(
      textDirection:
          Translation.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: CosmicBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.backgroundTwo, AppColors.background],
                ),
                border: Border(
                  bottom: BorderSide(color: AppColors.cyan, width: 0.5),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.cyan),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.gold, AppColors.goldDark],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.notifications_active,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [AppColors.gold, AppColors.cyan],
                  ).createShader(b),
                  child: const Text(
                    'التنبيهات',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              if (alerts.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep, color: AppColors.red),
                  tooltip: 'حذف الكل',
                  onPressed: () => _confirmClearAll(),
                ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _showAddDialog,
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.background,
            icon: const Icon(Icons.add),
            label: const Text(
              'إضافة تنبيه',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          body: alerts.isEmpty ? _buildEmpty() : _buildList(alerts),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.notifications_off_outlined,
              size: 80, color: AppColors.silver),
          const SizedBox(height: 16),
          const Text(
            '🔔 لا توجد تنبيهات',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'أضف تنبيهاً للحصول على إشعار\nعند وصول السعر أو RSI لمستوى معين',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.silver.withOpacity(0.7),
              fontSize: 13,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<PriceAlert> alerts) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.gold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.gold.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: AppColors.gold, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${alerts.length} تنبيه (${AlertService.instance.activeCount} نشط)',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...alerts.map((alert) => _buildAlertCard(alert)),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildAlertCard(PriceAlert alert) {
    final enabled = alert.isEnabled;
    final color = enabled ? AppColors.gold : AppColors.silver;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundThree.withOpacity(0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: enabled
              ? color.withOpacity(0.5)
              : AppColors.silver.withOpacity(0.2),
          width: enabled ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(alert.conditionEmoji,
                  style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  alert.pairName,
                  style: TextStyle(
                    color: enabled ? Colors.white : AppColors.silver,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Switch(
                value: enabled,
                activeColor: AppColors.green,
                onChanged: (v) async {
                  await AlertService.instance.toggleAlert(alert.id);
                  if (mounted) setState(() {});
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.red, size: 20),
                onPressed: () async {
                  await AlertService.instance.removeAlert(alert.id);
                  if (mounted) setState(() {});
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  alert.conditionLabel,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                alert.isSignalCondition
                    ? ''
                    : alert.targetValue.toStringAsFixed(
                        alert.isRsiCondition ? 1 : 4,
                      ),
                style: TextStyle(
                  color: enabled ? Colors.white : AppColors.silver,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          if (alert.lastTriggered != null) ...[
            const SizedBox(height: 8),
            Text(
              'آخر تشغيل: ${_formatTime(alert.lastTriggered!)}',
              style: TextStyle(
                color: AppColors.silver.withOpacity(0.6),
                fontSize: 10,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'منذ لحظات';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
    return 'منذ ${diff.inDays} يوم';
  }

  void _confirmClearAll() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.backgroundTwo,
        title: const Text(
          'حذف كل التنبيهات؟',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'لا يمكن التراجع عن هذا الإجراء.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              await AlertService.instance.clearAll();
              if (mounted) {
                Navigator.pop(ctx);
                setState(() {});
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
            ),
            child: const Text('حذف الكل'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════
// Dialog: إضافة تنبيه
// ═══════════════════════════════════════════
class _AddAlertDialog extends StatefulWidget {
  final VoidCallback onAdded;
  const _AddAlertDialog({required this.onAdded});

  @override
  State<_AddAlertDialog> createState() => _AddAlertDialogState();
}

class _AddAlertDialogState extends State<_AddAlertDialog> {
  CurrencyPair? _selectedPair;
  String _conditionType = 'price_above';
  final _valueController = TextEditingController();

  @override
  void dispose() {
    _valueController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_selectedPair == null) {
      _showError('اختر الزوج أولاً');
      return;
    }

    final isSignal = _conditionType == 'signal_call' ||
        _conditionType == 'signal_put';

    double value = 0;
    if (!isSignal) {
      final parsed = double.tryParse(_valueController.text);
      if (parsed == null) {
        _showError('أدخل قيمة صحيحة');
        return;
      }
      value = parsed;
    }

    final alert = PriceAlert(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      pairName: _selectedPair!.name,
      symbol: _selectedPair!.symbol,
      conditionType: _conditionType,
      targetValue: value,
      createdAt: DateTime.now(),
    );

    await AlertService.instance.addAlert(alert);
    widget.onAdded();
    if (mounted) Navigator.pop(context);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSignal = _conditionType == 'signal_call' ||
        _conditionType == 'signal_put';

    return Directionality(
      textDirection:
          Translation.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: AlertDialog(
        backgroundColor: AppColors.backgroundTwo,
        title: const Row(
          children: [
            Icon(Icons.add_alert, color: AppColors.gold),
            SizedBox(width: 8),
            Text(
              'إضافة تنبيه',
              style: TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'الزوج:',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundThree.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: AppColors.cyan.withOpacity(0.3)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<CurrencyPair>(
                      isExpanded: true,
                      dropdownColor: AppColors.backgroundTwo,
                      value: _selectedPair,
                      hint: const Text(
                        'اختر الزوج',
                        style: TextStyle(color: AppColors.silver),
                      ),
                      items: AppState.pairs
                          .take(20)
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text(
                                  p.name,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 13),
                                ),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedPair = v),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'الشرط:',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _condChip('price_above', '📈 السعر ↑'),
                    _condChip('price_below', '📉 السعر ↓'),
                    _condChip('rsi_above', '📊 RSI ↑'),
                    _condChip('rsi_below', '📊 RSI ↓'),
                    _condChip('signal_call', '🟢 CALL'),
                    _condChip('signal_put', '🔴 PUT'),
                  ],
                ),
                const SizedBox(height: 16),
                if (!isSignal) ...[
                  Text(
                    _conditionType.contains('rsi')
                        ? 'قيمة RSI (0-100):'
                        : 'السعر المستهدف:',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _valueController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                        color: Colors.white, fontFamily: 'monospace'),
                    decoration: InputDecoration(
                      hintText:
                          _conditionType.contains('rsi') ? '30' : '85000',
                      hintStyle: const TextStyle(color: AppColors.silver),
                      filled: true,
                      fillColor:
                          AppColors.backgroundThree.withOpacity(0.4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(
                            color: AppColors.cyan.withOpacity(0.3)),
                      ),
                    ),
                  ),
                ] else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Text(
                      '✅ سيتم إشعارك عند ظهور هذه الإشارة',
                      style:
                          TextStyle(color: AppColors.green, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: const Text('حفظ'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.background,
            ),
          ),
        ],
      ),
    );
  }

  Widget _condChip(String value, String label) {
    final selected = _conditionType == value;
    return GestureDetector(
      onTap: () => setState(() => _conditionType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.gold.withOpacity(0.3)
              : AppColors.backgroundThree.withOpacity(0.4),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? AppColors.gold
                : AppColors.cyan.withOpacity(0.3),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.silver,
            fontSize: 11,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}