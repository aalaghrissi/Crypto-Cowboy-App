import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../constants/colors.dart';
import '../constants/translations.dart';
import '../services/gemini_vision_service.dart';
import 'cosmic_background.dart';

class ChartAnalyzerScreen extends StatefulWidget {
  const ChartAnalyzerScreen({super.key});

  @override
  State<ChartAnalyzerScreen> createState() => _ChartAnalyzerScreenState();
}

class _ChartAnalyzerScreenState extends State<ChartAnalyzerScreen> {
  File? _imageFile;
  ChartAnalysisResult? _result;
  bool _isLoading = false;
  String? _errorMessage;

  final ImagePicker _picker = ImagePicker();

  // ═══════════════════════════════════════════
  // اختيار صورة من المعرض
  // ═══════════════════════════════════════════
  Future<void> _pickFromGallery() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        imageQuality: 85,
      );

      if (picked != null) {
        setState(() {
          _imageFile = File(picked.path);
          _result = null;
          _errorMessage = null;
        });
      }
    } catch (e) {
      _showError('فشل اختيار الصورة: $e');
    }
  }

  // ═══════════════════════════════════════════
  // اختيار صورة من الكاميرا
  // ═══════════════════════════════════════════
  Future<void> _pickFromCamera() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        imageQuality: 85,
      );

      if (picked != null) {
        setState(() {
          _imageFile = File(picked.path);
          _result = null;
          _errorMessage = null;
        });
      }
    } catch (e) {
      _showError('فشل التقاط الصورة: $e');
    }
  }

  // ═══════════════════════════════════════════
  // تحليل الصورة بالذكاء الاصطناعي
  // ═══════════════════════════════════════════
  Future<void> _analyzeChart() async {
    if (_imageFile == null) {
      _showError('الرجاء اختيار صورة الشارت أولاً');
      return;
    }

    setState(() {
      _isLoading = true;
      _result = null;
      _errorMessage = null;
    });

    final result = await GeminiVisionService.instance.analyzeChart(_imageFile!);

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result.isError) {
        _errorMessage = result.reason;
      } else {
        _result = result;
      }
    });
  }

  // ═══════════════════════════════════════════
  // إظهار خطأ
  // ═══════════════════════════════════════════
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // إعادة تعيين
  // ═══════════════════════════════════════════
  void _reset() {
    setState(() {
      _imageFile = null;
      _result = null;
      _errorMessage = null;
    });
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
                      colors: [AppColors.violet, AppColors.cyan],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
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
                    'تحليل الشارت بالذكاء الاصطناعي',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              if (_imageFile != null)
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.gold),
                  onPressed: _reset,
                  tooltip: 'صورة جديدة',
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ═══ معاينة الصورة أو رفعها ═══
                _buildImageSection(),

                const SizedBox(height: 16),

                // ═══ أزرار الاختيار ═══
                if (_imageFile == null) _buildPickerButtons(),

                // ═══ زر التحليل ═══
                if (_imageFile != null && !_isLoading && _result == null)
                  _buildAnalyzeButton(),

                // ═══ حالة التحميل ═══
                if (_isLoading) _buildLoadingIndicator(),

                // ═══ رسالة الخطأ ═══
                if (_errorMessage != null) _buildErrorCard(),

                // ═══ النتيجة ═══
                if (_result != null) _buildResultCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // قسم الصورة
  // ═══════════════════════════════════════════
  Widget _buildImageSection() {
    return GlassCard(
      borderColor: _imageFile == null ? AppColors.cyan : AppColors.violet,
      padding: const EdgeInsets.all(8),
      child: Container(
        width: double.infinity,
        height: 280,
        decoration: BoxDecoration(
          color: AppColors.backgroundThree.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(14),
        ),
        child: _imageFile == null
            ? _buildEmptyImagePlaceholder()
            : ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  _imageFile!,
                  fit: BoxFit.contain,
                  width: double.infinity,
                ),
              ),
      ),
    );
  }

  Widget _buildEmptyImagePlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.cyan.withValues(alpha: 0.2),
                  AppColors.violet.withValues(alpha: 0.2),
                ],
              ),
            ),
            child: const Icon(
              Icons.image_search,
              size: 60,
              color: AppColors.cyan,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            '📸 اختر صورة الشارت',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'من المعرض أو الكاميرا',
            style: TextStyle(
              color: AppColors.silver.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // أزرار اختيار الصورة
  // ═══════════════════════════════════════════
  Widget _buildPickerButtons() {
    return Row(
      children: [
        Expanded(
          child: _bigActionButton(
            icon: Icons.photo_library,
            label: 'من المعرض',
            color: AppColors.violet,
            onTap: _pickFromGallery,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _bigActionButton(
            icon: Icons.camera_alt,
            label: 'من الكاميرا',
            color: AppColors.cyan,
            onTap: _pickFromCamera,
          ),
        ),
      ],
    );
  }

  Widget _bigActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.25),
                color.withValues(alpha: 0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color, width: 1.5),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 15,
              ),
            ],
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // زر التحليل
  // ═══════════════════════════════════════════
  Widget _buildAnalyzeButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.gold, AppColors.goldDark],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: 0.5),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _analyzeChart,
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, color: Colors.black, size: 24),
                SizedBox(width: 10),
                Text(
                  'تحليل بالذكاء الاصطناعي',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // مؤشر التحميل
  // ═══════════════════════════════════════════
  Widget _buildLoadingIndicator() {
    return GlassCard(
      borderColor: AppColors.violet,
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              color: AppColors.violet,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '🤖 جاري تحليل الشارت...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'قد يأخذ التحليل 3-5 ثواني',
            style: TextStyle(
              color: AppColors.silver.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // بطاقة الخطأ
  // ═══════════════════════════════════════════
  Widget _buildErrorCard() {
    return GlassCard(
      borderColor: AppColors.red,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.red, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'فشل التحليل',
                  style: TextStyle(
                    color: AppColors.red,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _errorMessage ?? 'خطأ غير معروف',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.red),
            onPressed: _analyzeChart,
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // بطاقة النتيجة
  // ═══════════════════════════════════════════
  Widget _buildResultCard() {
    final r = _result!;
    final color = r.isCall
        ? AppColors.green
        : r.isPut
            ? AppColors.red
            : AppColors.amber;

    final emoji = r.isCall
        ? '🟢'
        : r.isPut
            ? '🔴'
            : '⏸️';

    final signalAr = r.isCall
        ? 'شراء (CALL)'
        : r.isPut
            ? 'بيع (PUT)'
            : 'انتظار (WAIT)';


    return GlassCard(
      borderColor: color,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ═══ العنوان ═══
          Row(
            children: [
              const Icon(Icons.analytics, color: AppColors.gold, size: 22),
              const SizedBox(width: 8),
              const Text(
                '📊 نتيجة التحليل',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ═══ الإشارة ═══
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withValues(alpha: 0.3),
                  color.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color, width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.4),
                  blurRadius: 20,
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  emoji,
                  style: const TextStyle(fontSize: 40),
                ),
                const SizedBox(height: 8),
                Text(
                  signalAr,
                  style: TextStyle(
                    color: color,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ═══ الثقة والإطار ═══
          Row(
            children: [
              Expanded(
                child: _statBox(
                  '📈 الثقة',
                  '${r.confidence}%',
                  color,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _statBox(
                  '⏱️ الإطار',
                  r.timeframe,
                  AppColors.cyan,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // ═══ شريط الثقة ═══
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'مستوى الثقة',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${r.confidence}%',
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: r.confidence / 100,
                  minHeight: 12,
                  backgroundColor: AppColors.background,
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ═══ السبب ═══
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.backgroundThree.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.cyan.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.lightbulb,
                      color: AppColors.gold,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      '📝 سبب التحليل',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  r.reason,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ═══ تحذير ═══
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.amber.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: AppColors.amber,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '⚠️ هذا تحليل تعليمي وليس نصيحة مالية. راجع قرارك بنفسك.',
                    style: TextStyle(
                      color: AppColors.amber.withValues(alpha: 0.9),
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ═══ زر تحليل جديد ═══
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: _analyzeChart,
                  icon: const Icon(Icons.refresh, color: AppColors.cyan),
                  label: const Text(
                    'تحليل مرة أخرى',
                    style: TextStyle(color: AppColors.cyan),
                  ),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: _reset,
                  icon: const Icon(Icons.add_photo_alternate,
                      color: AppColors.gold),
                  label: const Text(
                    'صورة جديدة',
                    style: TextStyle(color: AppColors.gold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // صندوق إحصائي صغير
  // ═══════════════════════════════════════════
  Widget _statBox(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}