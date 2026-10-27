import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/translations.dart';
import 'home_screen.dart';
import 'cosmic_background.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    
    _scaleAnim = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => const HomeScreen(),
            transitionsBuilder: (_, animation, __, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Translation.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: CosmicBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnim,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // أيقونة النجمة (بدل التنين)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.gold.withOpacity(0.1),
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: AppColors.gold.withOpacity(0.5),
                                width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gold.withOpacity(0.3),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.star_rounded,
                            color: AppColors.gold,
                            size: 80,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // اسم التطبيق
                        ShaderMask(
                          shaderCallback: (b) => const LinearGradient(
                            colors: [AppColors.gold, AppColors.goldDark],
                          ).createShader(b),
                          child: const Text(
                            'CRYPTO COWBOY',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 32,
                              letterSpacing: 3,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // النص الفرعي
                        Text(
                          'TRADING SIGNALS',
                          style: TextStyle(
                            color: AppColors.cyan.withOpacity(0.7),
                            fontSize: 14,
                            letterSpacing: 5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        
                        const SizedBox(height: 40),
                        
                        // شريط التحميل
                        SizedBox(
                          width: 100,
                          child: LinearProgressIndicator(
                            backgroundColor: AppColors.backgroundThree,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.cyan),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}