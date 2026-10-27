import 'package:flutter/material.dart';
import 'constants/translations.dart';
import 'state/app_state.dart';
import 'services/notification_service.dart';
import 'services/voice_service.dart';
import 'widgets/splash_screen.dart';

// ═══ متغير التحكم في الوضع الداكن ═══
final ValueNotifier<bool> themeNotifier = ValueNotifier<bool>(true);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await AppState.load();
  await NotificationService.instance.init();
  await VoiceService.instance.init();
  
  // تعيين القيمة الابتدائية
  themeNotifier.value = AppState.darkMode;
  
  runApp(const FxSniperApp());
}

class FxSniperApp extends StatelessWidget {
  const FxSniperApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: themeNotifier,
      builder: (_, isDark, __) {
        return MaterialApp(
          title: 'Crypto Cowboy',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            brightness: isDark ? Brightness.dark : Brightness.light,
            primaryColor: const Color(0xFF00E5FF),
            scaffoldBackgroundColor:
                isDark ? const Color(0xFF02040A) : const Color(0xFFF5F7FA),
            useMaterial3: true,
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}