import 'package:flutter/material.dart';
import '../main.dart';
import '../constants/colors.dart';
import '../constants/translations.dart';
import '../state/app_state.dart';

class SettingsScreen extends StatefulWidget {
  final VoidCallback onChanged;
  const SettingsScreen({super.key, required this.onChanged});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
            Translation.get('settings'),
            style: const TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('🎨 المظهر', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
            SwitchListTile(
              title: const Text('الوضع الداكن (Dark Mode)', style: TextStyle(color: Colors.white)),
              value: themeNotifier.value,
              activeColor: AppColors.cyan,
              onChanged: (v) async {
                setState(() {
                  themeNotifier.value = v;
                  AppState.darkMode = v;
                  AppState.save();
                });
                widget.onChanged();
              },
            ),
            const Divider(color: Colors.white24),
            
            const Text('🔊 الصوت', style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.bold)),
            SwitchListTile(
              title: const Text('المساعد الصوتي', style: TextStyle(color: Colors.white)),
              value: AppState.voiceEnabled,
              activeColor: AppColors.cyan,
              onChanged: (v) async {
                setState(() => AppState.voiceEnabled = v);
                await AppState.save();
              },
            ),
          ],
        ),
      ),
    );
  }
}