import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/colors.dart';
import '../constants/translations.dart';
import 'cosmic_background.dart';

class RiskCalculatorScreen extends StatefulWidget {
  const RiskCalculatorScreen({super.key});

  @override
  State<RiskCalculatorScreen> createState() => _RiskCalculatorScreenState();
}

class _RiskCalculatorScreenState extends State<RiskCalculatorScreen> {
  // ═══════════════════════════════════════════
  // Controllers
  // ═══════════════════════════════════════════
  final _capitalController = TextEditingController(text: '1000');
  final _riskController = TextEditingController(text: '2');
  final _entryController = TextEditingController();
  final _stopController = TextEditingController();
  final _targetController = TextEditingController();

  // ═══════════════════════════════════════════
  // State
  // ═══════════════════════════════════════════
  String _signal = 'CALL'; // CALL or PUT

  // ═══════════════════════════════════════════
  // Computed Results
  // ═══════════════════════════════════════════
  double get _capital => double.tryParse(_capitalController.text) ?? 0;
  double get _riskPercent => double.tryParse(_riskController.text) ?? 0;
  double get _entry => double.tryParse(_entryController.text) ?? 0;
  double get _stop => double.tryParse(_stopController.text) ?? 0;
  double get _target => double.tryParse(_targetController.text) ?? 0;

  double get _riskAmount => _capital * _riskPercent / 100;

  double get _stopDistance {
    if (_entry == 0 || _stop == 0) return 0;
    return (_entry - _stop).abs();
  }

  double get _positionSize {
    if (_stopDistance == 0) return 0;
    return _riskAmount / _stopDistance;
  }

  double get _positionValue => _positionSize * _entry;

  double get _potentialProfit {
    if (_entry == 0 || _target == 0) return 0;
    final targetDistance = (_target - _entry).abs();
    return _positionSize * targetDistance;
  }

  double get _rrRatio {
    if (_stopDistance == 0) return 0;
    final targetDistance = (_target - _entry).abs();
    return targetDistance / _stopDistance;
  }

  bool get _isValidSetup {
    if (_capital <= 0) return false;
    if (_riskPercent <= 0 || _riskPercent > 100) return false;
    if (_entry <= 0) return false;
    if (_stop <= 0) return false;
    if (_target <= 0) return false;
    if (_signal == 'CALL') {
      return _stop < _entry && _target > _entry;
    } else {
      return _stop > _entry && _target < _entry;
    }
  }

  String get _qualityLabel {
    if (!_isValidSetup) return 'انتظر';
    if (_rrRatio >= 3) return 'ممتازة';
    if (_rrRatio >= 2) return 'جيدة';
    if (_rrRatio >= 1.5) return 'مقبولة';
    return 'ضعيفة';
  }

  Color get _qualityColor {
    if (!_isValidSetup) return AppColors.silver;
    if (_rrRatio >= 3) return AppColors.green;
    if (_rrRatio >= 2) return AppColors.cyan;
    if (_rrRatio >= 1.5) return AppColors.amber;
    return AppColors.red;
  }

  @override
  void dispose() {
    _capitalController.dispose();
    _riskController.dispose();
    _entryController.dispose();
    _stopController.dispose();
    _targetController.dispose();
    super.dispose();
  }

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
                    Icons.calculate,
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
                    'حاسبة إدارة المخاطر',
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
              IconButton(
                icon: const Icon(Icons.refresh, color: AppColors.gold),
                tooltip: 'إعادة تعيين',
                onPressed: _reset,
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSignalSelector(),
                const SizedBox(height: 16),
                _buildInputCard(),
                const SizedBox(height: 16),
                _buildPricesCard(),
                const SizedBox(height: 16),
                if (_isValidSetup) _buildResultsCard(),
                if (!_isValidSetup && _hasAnyInput()) _buildInvalidMessage(),
                const SizedBox(height: 16),
                _buildTipsCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _hasAnyInput() {
    return _entryController.text.isNotEmpty &&
        _stopController.text.isNotEmpty &&
        _targetController.text.isNotEmpty;
  }

  void _reset() {
    setState(() {
      _capitalController.text = '1000';
      _riskController.text = '2';
      _entryController.clear();
      _stopController.clear();
      _targetController.clear();
      _signal = 'CALL';
    });
  }

  Widget _buildSignalSelector() {
    return Row(
      children: [
        Expanded(
          child: _signalButton(
            'CALL',
            '🟢 شراء',
            AppColors.green,
            _signal == 'CALL',
            () => setState(() => _signal = 'CALL'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _signalButton(
            'PUT',
            '🔴 بيع',
            AppColors.red,
            _signal == 'PUT',
            () => setState(() => _signal = 'PUT'),
          ),
        ),
      ],
    );
  }

  Widget _signalButton(
    String value,
    String label,
    Color color,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    color.withOpacity(0.4),
                    color.withOpacity(0.15),
                  ],
                )
              : null,
          color: isSelected ? null : AppColors.backgroundThree.withOpacity(0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : AppColors.cyan.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 15,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppColors.silver,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return GlassCard(
      borderColor: AppColors.gold,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.account_balance_wallet,
                  color: AppColors.gold, size: 20),
              SizedBox(width: 8),
              Text(
                '💰 رأس المال والمخاطرة',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  controller: _capitalController,
                  label: 'رأس المال',
                  suffix: '\$',
                  icon: Icons.attach_money,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildNumberField(
                  controller: _riskController,
                  label: 'المخاطرة',
                  suffix: '%',
                  icon: Icons.warning_amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_capital > 0 && _riskPercent > 0)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.amber.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.amber, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'الحد الأقصى للخسارة: ',
                    style: TextStyle(
                      color: AppColors.silver.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    '\$${_riskAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.amber,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPricesCard() {
    return GlassCard(
      borderColor: AppColors.cyan,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, color: AppColors.cyan, size: 20),
              SizedBox(width: 8),
              Text(
                '📊 مستويات الأسعار',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildNumberField(
            controller: _entryController,
            label: 'سعر الدخول',
            suffix: '\$',
            icon: Icons.login,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _buildNumberField(
            controller: _stopController,
            label: 'وقف الخسارة',
            suffix: '\$',
            icon: Icons.shield,
            color: AppColors.red,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _buildNumberField(
            controller: _targetController,
            label: 'هدف الربح',
            suffix: '\$',
            icon: Icons.flag,
            color: AppColors.green,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsCard() {
    return GlassCard(
      borderColor: _qualityColor,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.analytics, color: AppColors.gold, size: 22),
              const SizedBox(width: 8),
              const Text(
                '📋 النتائج',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _qualityColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _qualityColor),
                ),
                child: Text(
                  _qualityLabel,
                  style: TextStyle(
                    color: _qualityColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _resultRow(
            '💵 حجم الصفقة',
            '\$${_positionValue.toStringAsFixed(2)}',
            AppColors.gold,
            isMain: true,
          ),
          const SizedBox(height: 10),
          _resultRow(
            '📊 الكمية',
            _positionSize.toStringAsFixed(6),
            AppColors.cyan,
          ),
          const SizedBox(height: 10),
          _resultRow(
            '🎯 المخاطرة',
            '\$${_riskAmount.toStringAsFixed(2)}',
            AppColors.red,
          ),
          const SizedBox(height: 10),
          _resultRow(
            '💰 الربح المتوقع',
            '\$${_potentialProfit.toStringAsFixed(2)}',
            AppColors.green,
          ),
          const SizedBox(height: 10),
          _resultRow(
            '⚖️ R:R Ratio',
            '${_rrRatio.toStringAsFixed(2)} : 1',
            _qualityColor,
            isMain: true,
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'جودة الصفقة',
                    style: TextStyle(
                      color: AppColors.silver.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _qualityLabel,
                    style: TextStyle(
                      color: _qualityColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (_rrRatio / 4).clamp(0.0, 1.0),
                  minHeight: 12,
                  backgroundColor: AppColors.background,
                  valueColor: AlwaysStoppedAnimation(_qualityColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAdvice(),
        ],
      ),
    );
  }

  Widget _resultRow(String label, String value, Color color,
      {bool isMain = false}) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.silver.withOpacity(0.8),
            fontSize: isMain ? 14 : 12,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: isMain ? 20 : 15,
            fontWeight: isMain ? FontWeight.w900 : FontWeight.bold,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }

  Widget _buildAdvice() {
    String advice;
    IconData icon;
    Color color;

    if (_rrRatio >= 3) {
      advice = '🌟 إعداد ممتاز! النسبة عالية جداً.';
      icon = Icons.emoji_events;
      color = AppColors.gold;
    } else if (_rrRatio >= 2) {
      advice = '✅ إعداد جيد. يمكنك الدخول بثقة.';
      icon = Icons.check_circle;
      color = AppColors.green;
    } else if (_rrRatio >= 1.5) {
      advice = '⚠️ إعداد مقبول. حاول تحسينه.';
      icon = Icons.info;
      color = AppColors.amber;
    } else {
      advice = '❌ إعداد ضعيف! النسبة منخفضة.';
      icon = Icons.warning;
      color = AppColors.red;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              advice,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvalidMessage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.red.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.red, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _signal == 'CALL'
                  ? '⚠️ للشراء (CALL): يجب أن يكون وقف الخسارة < الدخول < الهدف'
                  : '⚠️ للبيع (PUT): يجب أن يكون الهدف < الدخول < وقف الخسارة',
              style: const TextStyle(
                color: AppColors.red,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard() {
    return GlassCard(
      borderColor: AppColors.violet,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: AppColors.violet, size: 20),
              SizedBox(width: 8),
              Text(
                '💡 نصائح إدارة المخاطر',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _tip('🎯 لا تخاطر بأكثر من 1-2% من رأس المال'),
          _tip('⚖️ ابحث عن R:R على الأقل 1:2'),
          _tip('📊 استخدم وقف خسارة دائماً'),
          _tip('🧠 لا تنتقم من السوق بعد الخسارة'),
          _tip('📈 الإشارات ليست مضمونة 100%'),
        ],
      ),
    );
  }

  Widget _tip(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: const BoxDecoration(
              color: AppColors.violet,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.silver.withOpacity(0.8),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String suffix,
    required IconData icon,
    Color color = AppColors.cyan,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
        fontFamily: 'monospace',
      ),
      onChanged: onChanged ?? (_) => setState(() {}),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: AppColors.silver.withOpacity(0.7),
          fontSize: 12,
        ),
        prefixIcon: Icon(icon, color: color, size: 18),
        suffixText: suffix,
        suffixStyle: TextStyle(
          color: color,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
        filled: true,
        fillColor: AppColors.backgroundThree.withOpacity(0.4),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
      ),
    );
  }
}