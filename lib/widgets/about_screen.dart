import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/translations.dart';
import 'cosmic_background.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: Translation.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            Translation.get('about'),
            style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // الشعار (نجمة)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.gold.withOpacity(0.5), width: 2),
                  boxShadow: [
                    BoxShadow(color: AppColors.gold.withOpacity(0.3), blurRadius: 30, spreadRadius: 5),
                  ],
                ),
                child: const Icon(Icons.star_rounded, color: AppColors.gold, size: 70),
              ),
              const SizedBox(height: 20),

              // الاسم
              const Text(
                'CRYPTO COWBOY',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'الإصدار 7.0.0',
                style: TextStyle(color: AppColors.cyan, fontSize: 14, fontFamily: 'monospace'),
              ),
              const SizedBox(height: 30),

              // البطاقة التعريفية
              GlassCard(
                borderColor: AppColors.cyan,
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      'تطبيق Crypto Cowboy هو منصة تحليل فني متقدمة تسخر الذكاء الاصطناعي لمساعدتك في قراءة حركة الأسواق. يجمع بين قوة المؤشرات التقليدية وتقنيات SMC الحديثة.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.silver.withOpacity(0.9),
                        fontSize: 13,
                        height: 1.8,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // تنبيه المخاطر
              GlassCard(
                borderColor: AppColors.red,
                padding: const EdgeInsets.all(16),
                child: const Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.warning_amber_rounded, color: AppColors.red, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'إخلاء مسؤولية',
                          style: TextStyle(color: AppColors.red, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      'هذا التطبيق مخصص لأغراض تعليمية وتحليلية فقط. الإشارات المقدمة ليست نصيحة مالية ولا تضمن أي أرباح. التداول في الأسواق المالية ينطوي على مخاطر عالية، وأنت وحدك المسؤول عن قراراتك المالية.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.6),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}