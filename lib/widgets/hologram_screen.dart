import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../constants/colors.dart';
import '../constants/translations.dart';
import '../services/voice_service.dart';
import '../state/app_state.dart';
import 'cosmic_background.dart';

class HologramScreen extends StatefulWidget {
  const HologramScreen({super.key});
  @override
  State<HologramScreen> createState() => _HologramScreenState();
}

class _HologramScreenState extends State<HologramScreen>
    with TickerProviderStateMixin {
  File? _imageFile;
  bool _isTalking = false;
  String _news = 'مرحباً! أنا المذيع الذكي';
  Color _mood = AppColors.cyan;
  int _idx = 0;

  // متغيرات حركة الهاتف (3D Parallax)
  double _tiltX = 0.0;
  double _tiltY = 0.0;
  StreamSubscription? _gyroSub;

  late AnimationController _float;
  late AnimationController _breathe;
  late AnimationController _scan;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    final saved = AppState.hologramImagePath;
    if (saved != null && saved.isNotEmpty) {
      final f = File(saved);
      if (f.existsSync()) _imageFile = f;
    }

    _float = AnimationController(
        vsync: this, duration: const Duration(seconds: 4))
      ..repeat(reverse: true);
    _breathe = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);
    _scan = AnimationController(
        vsync: this, duration: const Duration(seconds: 3))
      ..repeat();

    // تشغيل حساسات الهاتف
    try {
      _gyroSub = gyroscopeEventStream().listen((GyroscopeEvent event) {
        if (mounted) {
          setState(() {
            _tiltX = (event.y * 0.5).clamp(-0.5, 0.5);
            _tiltY = (event.x * 0.5).clamp(-0.5, 0.5);
          });
        }
      });
    } catch (e) {
      debugPrint('Gyro not supported: $e');
    }

    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && !_isTalking) _nextNews();
    });
  }

  @override
  void dispose() {
    _gyroSub?.cancel();
    _float.dispose();
    _breathe.dispose();
    _scan.dispose();
    _timer?.cancel();
    VoiceService.instance.stop();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
      );
      if (picked == null) return;
      setState(() => _imageFile = File(picked.path));
      AppState.hologramImagePath = picked.path;
      await AppState.save();
      _speak('تم تحديث الصورة');
    } catch (e) {
      debugPrint('❌ $e');
    }
  }

  Future<void> _speak(String text) async {
    if (!AppState.voiceEnabled) return;
    setState(() {
      _isTalking = true;
      _news = text;
    });
    try {
      await VoiceService.instance.speak(text);
    } catch (e) {
      debugPrint('❌ $e');
    }
    await Future.delayed(Duration(milliseconds: 1500 + text.length * 60));
    if (mounted) setState(() => _isTalking = false);
  }

  void _nextNews() {
    final pairs = AppState.pairs
        .where((p) => p.signal == 'CALL' || p.signal == 'PUT')
        .toList();
    final list = pairs.isEmpty ? AppState.pairs.take(5).toList() : pairs;
    if (list.isEmpty) return;
    final p = list[_idx % list.length];
    _idx++;
    if (p.signal == 'CALL') {
      _mood = AppColors.green;
      _speak('إشارة شراء على ${p.name}، الثقة ${p.confidence} بالمئة');
    } else if (p.signal == 'PUT') {
      _mood = AppColors.red;
      _speak('إشارة بيع على ${p.name}، الثقة ${p.confidence} بالمئة');
    } else {
      _mood = AppColors.cyan;
      _speak('${p.name} حالياً في حالة انتظار');
    }
  }

  void _summary() {
    final t = AppState.todayStats();
    _mood = AppColors.gold;
    _speak('ملخص اليوم: ${t['total']} إشارة، ${t['calls']} شراء، ${t['puts']} بيع');
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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.cyan),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'CRYPTO COWBOY',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _hologramCard(),
                const SizedBox(height: 16),
                _newsCard(),
                const SizedBox(height: 16),
                _controlsCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hologramCard() {
    return GlassCard(
      borderColor: _mood,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.blur_circular, color: _mood, size: 20),
              const SizedBox(width: 8),
              Text(
                '🔮 المذيع الذكي (3D)',
                style: TextStyle(
                  color: _mood,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_isTalking)
                const Text(
                  '🗣️ يتحدث',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 300,
            child: AnimatedBuilder(
              animation: Listenable.merge([_float, _breathe, _scan]),
              builder: (_, __) => _avatar(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar() {
    final floatY = math.sin(_float.value * math.pi * 2) * 8;
    final breathe = 0.95 + _breathe.value * 0.1;
    final glow = 0.4 + _breathe.value * 0.6;

    // تأثير 3D Parallax
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.001)
        ..rotateX(_tiltY)
        ..rotateY(_tiltX),
      child: Transform.translate(
        offset: Offset(0, floatY),
        child: Transform.scale(
          scale: breathe,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.translate(
                offset: Offset(-_tiltX * 40, -_tiltY * 40),
                child: Container(
                  width: 260,
                  height: 260,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: _mood.withOpacity(glow * 0.4),
                        blurRadius: 60,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
              if (_imageFile != null)
                ClipOval(
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _mood.withOpacity(0.8),
                        width: 3,
                      ),
                    ),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ColorFiltered(
                          colorFilter: ColorFilter.mode(
                            _mood.withOpacity(0.25),
                            BlendMode.srcATop,
                          ),
                          child: Image.file(
                            _imageFile!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _mood.withOpacity(0.1),
                    border: Border.all(
                      color: _mood.withOpacity(0.5),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_outline,
                        color: _mood.withOpacity(0.7),
                        size: 80,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'اختر صورتك',
                        style: TextStyle(
                          color: _mood.withOpacity(0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _Scanlines(
                      progress: _scan.value,
                      color: _mood,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _newsCard() {
    return GlassCard(
      borderColor: AppColors.gold,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.newspaper,
                  color: AppColors.gold, size: 20),
              const SizedBox(width: 8),
              const Text(
                '📰 الأخبار',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: _isTalking ? null : _nextNews,
                icon: const Icon(Icons.skip_next,
                    color: AppColors.cyan, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.gold.withOpacity(0.3),
              ),
            ),
            child: Text(
              _news,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.6,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlsCard() {
    return GlassCard(
      borderColor: AppColors.violet,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.image, size: 20),
              label: Text(
                _imageFile == null ? '📸 اختر صورتك' : '🖼️ تغيير الصورة',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.violet,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isTalking ? null : _nextNews,
              icon: const Icon(Icons.campaign, size: 20),
              label: const Text(
                '📢 اقرأ خبراً',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cyan,
                foregroundColor: AppColors.background,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isTalking ? null : _summary,
              icon: const Icon(Icons.summarize, size: 20),
              label: const Text(
                '📊 ملخص اليوم',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.background,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Scanlines extends CustomPainter {
  final double progress;
  final Color color;
  _Scanlines({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final p1 = Paint()
      ..color = color.withOpacity(0.12)
      ..strokeWidth = 1.5;
    for (double y = 0; y < size.height; y += 6) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p1);
    }
    final scanY = progress * size.height;
    final p2 = Paint()
      ..shader = LinearGradient(
        colors: [
          color.withOpacity(0),
          color.withOpacity(0.8),
          color.withOpacity(0),
        ],
      ).createShader(
          Rect.fromLTWH(0, scanY - 20, size.width, 40));
    canvas.drawRect(
      Rect.fromLTWH(0, scanY - 1, size.width, 2),
      p2,
    );
  }

  @override
  bool shouldRepaint(covariant _Scanlines old) =>
      old.progress != progress || old.color != color;
}