import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../constants/colors.dart';

class CosmicBackground extends StatefulWidget {
  final Widget child;
  const CosmicBackground({super.key, required this.child});

  @override
  State<CosmicBackground> createState() => _CosmicBackgroundState();
}

class _CosmicBackgroundState extends State<CosmicBackground>
    with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _particleController;
  final List<_Particle> _particles = [];

  @override
  void initState() {
    super.initState();
    
    // حركة التقريب السينمائية للخلفية (Ken Burns)
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 25),
    )..repeat(reverse: true);

    // حركة الغبار المتوهج
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // إنشاء الجزيئات
    for (int i = 0; i < 30; i++) {
      _particles.add(_Particle());
    }
  }

  @override
  void dispose() {
    _bgController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ═══ 1. الخلفية المتحركة (الصورة) ═══
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _bgController,
            builder: (context, child) {
              // التقريب البطيء من 1.0 إلى 1.15
              final scale = 1.0 + (_bgController.value * 0.15);
              return Transform.scale(
                scale: scale,
                child: Image.asset(
                  'assets/images/bg_cowboy.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: AppColors.background, // بديل في حال عدم وجود الصورة
                  ),
                ),
              );
            },
          ),
        ),

        // ═══ 2. الطبقة الداكنة (لظهور النصوص) ═══
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.background.withOpacity(0.85), // داكن في الأعلى
                  AppColors.background.withOpacity(0.60), // شفاف في المنتصف
                  AppColors.background.withOpacity(0.95), // داكن جداً في الأسفل
                ],
                stops: const [0.0, 0.4, 1.0],
              ),
            ),
          ),
        ),

        // ═══ 3. الجزيئات المتوهجة (الغبار) ═══
        Positioned.fill(
          child: AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                painter: _ParticlesPainter(
                  particles: _particles,
                  progress: _particleController.value,
                ),
              );
            },
          ),
        ),

        // ═══ 4. محتوى التطبيق ═══
        widget.child,
      ],
    );
  }
}

// ═══ جزيء الغبار ═══
class _Particle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final Color color;

  _Particle()
      : x = math.Random().nextDouble(),
        y = math.Random().nextDouble(),
        size = 1.0 + math.Random().nextDouble() * 3.0,
        speed = 0.2 + math.Random().nextDouble() * 0.8,
        color = math.Random().nextBool()
            ? AppColors.gold.withOpacity(0.5)
            : AppColors.cyan.withOpacity(0.4);
}

// ═══ رسام الجزيئات ═══
class _ParticlesPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ParticlesPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    for (var p in particles) {
      // حساب الحركة (تتجه للأعلى ببطء)
      double py = p.y - (progress * p.speed);
      if (py < 0) py += 1.0; // إعادة التدوير للأسفل

      final dx = p.x * size.width;
      final dy = py * size.height;

      paint.color = p.color;
      paint.maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

      canvas.drawCircle(Offset(dx, dy), p.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter oldDelegate) => true;
}

// ═══ HUD Glass Card (لم نغيره) ═══
class GlassCard extends StatelessWidget {
  final Widget child;
  final Color borderColor;
  final EdgeInsetsGeometry padding;

  const GlassCard({
    super.key,
    required this.child,
    this.borderColor = AppColors.cyan,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.backgroundTwo.withOpacity(0.75), // خلفية داكنة شفافة لقراءة النص
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withOpacity(0.3), width: 1),
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: child,
    );
  }
}