import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../main.dart';
import '../constants/colors.dart';
import '../constants/translations.dart';
import '../models/models.dart';
import '../state/app_state.dart';
import '../utils/indicators.dart';
import '../painters/painters.dart';
import '../services/notification_service.dart';
import '../services/alert_service.dart';
import '../services/voice_service.dart';
import 'cosmic_background.dart';
import 'pair_card.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'about_screen.dart';
import 'splash_screen.dart';
import 'chat_screen.dart';
import 'chart_analyzer_screen.dart';
import 'risk_calculator_screen.dart';
import 'backtesting_screen.dart';
import 'multi_timeframe_screen.dart';
import 'alerts_screen.dart';
import 'time_dna_screen.dart';
import 'hologram_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;
  Timer? refreshTimer, countdownTimer, tickTimer;
  bool isLoading = false;
  String searchQuery = '', filterType = 'ALL', categoryFilter = 'ALL';
  int secondsRemaining = 60;
  int currentSecond = 0;

  @override
  void initState() {
    super.initState();
    AlertService.instance.load();
    _showWarningIfNeeded();
    refreshAll();
    startRefreshTimer();
    startCountdown();
    tickTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) setState(() => currentSecond = DateTime.now().second);
    });
  }

  Future<void> _showWarningIfNeeded() async {
    if (AppState.warningShown) return;
    await Future.delayed(const Duration(milliseconds: 2600));
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.backgroundTwo, AppColors.background],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.amber, width: 2),
            boxShadow: [
              BoxShadow(
                color: AppColors.amber.withOpacity(0.5),
                blurRadius: 30,
              ),
            ],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.amber.withOpacity(0.15),
                border: Border.all(color: AppColors.amber, width: 2),
              ),
              child: const Icon(
                Icons.warning_amber_rounded,
                color: AppColors.amber,
                size: 50,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              Translation.get('warning'),
              style: const TextStyle(
                color: AppColors.amber,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              Translation.get('warningText'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                height: 1.8,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.red.withOpacity(0.5)),
              ),
              child: const Text(
                '⚠️ لا تتداول بأموال لا تستطيع خسارتها',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber,
                  foregroundColor: AppColors.background,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  AppState.warningShown = true;
                  await AppState.save();
                  if (mounted) Navigator.pop(ctx);
                },
                child: const Text(
                  'أوافق وأفهم المخاطر',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void startRefreshTimer() {
    refreshTimer?.cancel();
    refreshTimer = Timer.periodic(
      Duration(minutes: AppState.refreshMinutes),
      (_) => refreshAll(),
    );
  }

  void startCountdown() {
    countdownTimer?.cancel();
    secondsRemaining = AppState.refreshMinutes * 60;
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (mounted) {
        setState(() {
          secondsRemaining--;
          if (secondsRemaining <= 0) {
            secondsRemaining = AppState.refreshMinutes * 60;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    refreshTimer?.cancel();
    countdownTimer?.cancel();
    tickTimer?.cancel();
    super.dispose();
  }

  Future<void> refreshAll() async {
    if (isLoading) return;
    setState(() => isLoading = true);
    await Future.wait(AppState.pairs.map((pair) async {
      try { await analyzePair(pair); } catch (e) { debugPrint('❌ ${pair.name}: $e'); }
    }));
    await checkResults();
    if (mounted) setState(() => isLoading = false);
  }

  // ═══════════════════════════════════════════════════════════
  // 🚀 محرك الدقة الخارقة (The Precision Engine)
  // ═══════════════════════════════════════════════════════════
  Future<void> analyzePair(CurrencyPair pair) async {
    // 1. جلب البيانات مع السيولة (Volume)
    final data = await fetchKlinesWithVolume(symbol: pair.symbol);
    if (data == null || data.closes.length < 50) {
      pair.signal = 'WAIT';
      return;
    }

    // 2. تأكيد إغلاق الشمعة (Candle Close)
    // نتجاهل الشمعة الحالية (التي لم تغلق بعد) ونعتمد على آخر 100 شمعة مغلقة
    final closes = data.closes.sublist(0, data.closes.length - 1);
    final volumes = data.volumes.sublist(0, data.volumes.length - 1);
    
    final price = closes.last;
    final prev = closes[closes.length - 2];

    // 3. الحسابات الفنية
    final rsiSeries = calcRsiSeries(closes);
    final rsiVal = rsiSeries.last;
    final ema20Val = calcEma(closes, 20);
    final ema50Val = calcEma(closes, 50);
    final macdVal = calcMacd(closes);
    final adxVal = calcAdx(closes);
    final bb = calcBB(closes);
    final stochVal = calcStoch(closes);

    pair.price = price;
    pair.rsi = rsiVal;
    pair.ema20 = ema20Val;
    pair.ema50 = ema50Val;
    pair.change = ((price - prev) / prev) * 100;
    pair.priceHistory = closes.length > 30 ? closes.sublist(closes.length - 30) : closes;
    pair.confidence = 0; // سيتم حسابها لاحقاً
    pair.grade = 'C';

    // 4. فلتر السيولة (Volume Filter)
    final avgVol = volumes.reduce((a, b) => a + b) / volumes.length;
    final isVolumeHigh = volumes.last > (avgVol * 1.2); // يجب أن يكون الحجم أعلى بـ 20%

    // 5. تأكيد الفريم الأكبر (15m MTF)
    final tf15 = await fetchTimeframeKlines(symbol: pair.symbol, interval: '15m');
    bool mtfBullish = true;
    bool mtfBearish = true;
    if (tf15 != null && tf15.length > 50) {
      final ema20_15 = calcEma(tf15, 20);
      final ema50_15 = calcEma(tf15, 50);
      mtfBullish = ema20_15 > ema50_15;
      mtfBearish = ema20_15 < ema50_15;
    }

    // 6. كشف الانحراف (Divergence)
    final divergence = detectDivergence(closes, rsiSeries);

    // 7. حساب النقاط (Scoring)
    int buyScore = 0, sellScore = 0;
    
    // الشروط الأساسية
    if (rsiVal <= AppState.rsiBuyMax) buyScore++;
    if (rsiVal <= 30) buyScore++;
    if (rsiVal >= AppState.rsiSellMin) sellScore++;
    if (rsiVal >= 70) sellScore++;
    
    if (ema20Val > ema50Val && price > ema20Val) buyScore++;
    if (ema20Val < ema50Val && price < ema20Val) sellScore++;
    
    if (macdVal > 0) buyScore++;
    if (macdVal < 0) sellScore++;
    
    if (adxVal > 25) {
      if (ema20Val > ema50Val) buyScore++; else sellScore++;
    }
    
    if (price <= pair.bbLower) buyScore++;
    if (price >= pair.bbUpper) sellScore++;
    
    if (stochVal < 20) buyScore++;
    if (stochVal > 80) sellScore++;

    // ترقيات الدقة:
    // إذا كان الحجم عالي، نعطي نقطة إضافية
    if (isVolumeHigh) {
      if (buyScore > sellScore) buyScore += 2;
      if (sellScore > buyScore) sellScore += 2;
    }

    // إذا كان الانحراف إيجابي، نعطي نقطة للشراء
    if (divergence == 'bullish') buyScore += 3;
    if (divergence == 'bearish') sellScore += 3;

    // 8. الفلتر الصارم (Strict Filter)
    String newSignal = 'WAIT';
    int newStrength = 1;

    // إشارة الشراء: تحتاج نقاط عالية + توافق مع الفريم الأكبر + انحراف إيجابي (أو على الأقل اتجاه صاعد)
    if (buyScore >= AppState.scoreThreshold && buyScore > sellScore && mtfBullish && isVolumeHigh) {
      newSignal = 'CALL';
      newStrength = buyScore >= 8 ? 3 : (buyScore >= 6 ? 2 : 1);
    } 
    // إشارة البيع: تحتاج نقاط عالية + توافق مع الفريم الأكبر + انحراف سلبي
    else if (sellScore >= AppState.scoreThreshold && sellScore > buyScore && mtfBearish && isVolumeHigh) {
      newSignal = 'PUT';
      newStrength = sellScore >= 8 ? 3 : (sellScore >= 6 ? 2 : 1);
    }

    final maxScore = buyScore > sellScore ? buyScore : sellScore;
    pair.confidence = ((maxScore / 12) * 100).round().clamp(0, 99);
    pair.grade = pair.confidence >= 75 ? 'A+' : pair.confidence >= 60 ? 'A' : pair.confidence >= 45 ? 'B' : 'C';

    if (newSignal != 'WAIT' && pair.signal != newSignal) {
      final now = DateTime.now();
      pair.signalTime = now;
      pair.entryTime = DateTime(now.year, now.month, now.day, now.hour, now.minute).add(const Duration(minutes: 1));
      
      await AppState.addHistory(SignalLog(pair: pair.name, signal: newSignal, price: price, rsi: rsiVal, time: now));
      await NotificationService.instance.showSignal(pair: pair.name, signal: newSignal, price: price, confidence: pair.confidence, grade: pair.grade);

      if (AppState.voiceEnabled) {
        VoiceService.instance.announceSignal(pair: pair.name, signal: newSignal, price: price, confidence: pair.confidence, grade: pair.grade);
      }
      if (AppState.soundOn) SystemSound.play(SystemSoundType.alert);
      if (AppState.vibrationOn) HapticFeedback.heavyImpact();
    } else if (newSignal == 'WAIT') {
      pair.signalTime = null;
      pair.entryTime = null;
    }
    
    if (AppState.onlyStrong && newStrength < 2) newSignal = 'WAIT';
    pair.signal = newSignal;
    pair.strength = newStrength;
  }

  Future<void> checkResults() async {
    bool changed = false;
    for (final log in AppState.history) {
      if (log.result != 'pending') continue;
      if (DateTime.now().difference(log.time).inMinutes < 1) continue;
      final pair = AppState.pairs.firstWhere((p) => p.name == log.pair, orElse: () => AppState.pairs[0]);
      final prices = await fetchKlines(symbol: pair.symbol);
      if (prices == null || prices.isEmpty) continue;
      log.exit = prices.last;
      log.result = (log.signal == 'CALL' ? log.exit > log.price : log.exit < log.price) ? 'win' : 'loss';
      changed = true;
    }
    if (changed) await AppState.updateHistory();
  }

  List<CurrencyPair> get filtered {
    var list = AppState.pairs.where((p) => p.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();
    if (categoryFilter != 'ALL') list = list.where((p) => p.category == categoryFilter).toList();
    if (filterType == 'FAV') list = list.where((p) => p.isFavorite).toList();
    if (filterType == 'CALL') list = list.where((p) => p.signal == 'CALL').toList();
    if (filterType == 'PUT') list = list.where((p) => p.signal == 'PUT').toList();
    if (filterType == 'WAIT') list = list.where((p) => p.signal == 'WAIT').toList();
    return list;
  }

  int secondsToEntry(CurrencyPair pair) {
    if (pair.entryTime == null) return -1;
    return pair.entryTime!.difference(DateTime.now()).inSeconds;
  }

  @override
  Widget build(BuildContext context) {
    final screens = [buildList(), const HistoryScreen(), SettingsScreen(onChanged: () { startRefreshTimer(); startCountdown(); }), const AboutScreen()];
    return Directionality(
      textDirection: Translation.isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: CosmicBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.backgroundTwo, AppColors.background]),
                border: Border(bottom: BorderSide(color: AppColors.cyan, width: 0.5)),
              ),
            ),
            title: Row(children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.1), shape: BoxShape.circle, border: Border.all(color: AppColors.gold.withOpacity(0.5)), boxShadow: [BoxShadow(color: AppColors.gold.withOpacity(0.3), blurRadius: 10, spreadRadius: 1)]),
                child: const Icon(Icons.star_rounded, color: AppColors.gold, size: 20),
              ),
              const SizedBox(width: 8),
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(colors: [AppColors.gold, AppColors.goldDark]).createShader(b),
                child: const Text('CRYPTO COWBOY', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.5)),
              ),
            ]),
            actions: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.cyan.withOpacity(0.2), AppColors.cyan.withOpacity(0.05)]), borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.cyan.withOpacity(0.4), width: 1)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.timer, color: AppColors.cyan, size: 12),
                  const SizedBox(width: 4),
                  Text('$currentSecond'.padLeft(2, '0'), style: const TextStyle(color: AppColors.cyan, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                ]),
              ),
              _buildActionButton(icon: Icons.auto_awesome, color: AppColors.gold, tooltip: 'AI', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChartAnalyzerScreen()))),
              _buildActionButton(icon: Icons.smart_toy, color: AppColors.cyan, tooltip: 'Chat', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()))),
              _buildActionButton(icon: Icons.grid_view_rounded, color: AppColors.violet, tooltip: 'MTF', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MultiTimeframeScreen()))),
              _buildActionButton(icon: Icons.notifications_active, color: AppColors.gold, tooltip: 'Alerts', onTap: () async { await AlertService.instance.load(); if (!context.mounted) return; Navigator.push(context, MaterialPageRoute(builder: (_) => const AlertsScreen())); }),
              PopupMenuButton<String>(
                icon: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.silver.withOpacity(0.2), AppColors.silver.withOpacity(0.05)]), shape: BoxShape.circle, border: Border.all(color: AppColors.silver.withOpacity(0.3))), child: const Icon(Icons.more_vert, color: Colors.white, size: 18)),
                color: Colors.transparent, elevation: 0, offset: const Offset(0, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                onSelected: (value) {
                  switch (value) {
                    case 'dark_mode': themeNotifier.value = !themeNotifier.value; AppState.darkMode = themeNotifier.value; AppState.save(); break;
                    case 'risk_calc': Navigator.push(context, MaterialPageRoute(builder: (_) => const RiskCalculatorScreen())); break;
                    case 'backtest': Navigator.push(context, MaterialPageRoute(builder: (_) => const BacktestingScreen())); break;
                    case 'time_dna': Navigator.push(context, MaterialPageRoute(builder: (_) => const TimeDNAScreen())); break;
                    case 'hologram': Navigator.push(context, MaterialPageRoute(builder: (_) => const HologramScreen())); break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem<String>(value: 'dark_mode', height: 60, padding: EdgeInsets.zero, child: _buildMenuItem(icon: themeNotifier.value ? Icons.light_mode : Icons.dark_mode, iconColor: AppColors.gold, title: themeNotifier.value ? 'الوضع الفاتح' : 'الوضع الداكن', subtitle: 'تغيير المظهر')),
                  const PopupMenuDivider(height: 1),
                  PopupMenuItem<String>(value: 'risk_calc', height: 60, padding: EdgeInsets.zero, child: _buildMenuItem(icon: Icons.calculate, iconColor: AppColors.green, title: 'Risk Calc', subtitle: 'Manage Capital')),
                  const PopupMenuDivider(height: 1),
                  PopupMenuItem<String>(value: 'backtest', height: 60, padding: EdgeInsets.zero, child: _buildMenuItem(icon: Icons.science, iconColor: AppColors.violet, title: 'Backtesting', subtitle: 'Test Signals')),
                  const PopupMenuDivider(height: 1),
                  PopupMenuItem<String>(value: 'time_dna', height: 60, padding: EdgeInsets.zero, child: _buildMenuItem(icon: Icons.access_time_filled, iconColor: AppColors.cyan, title: 'Time DNA', subtitle: 'Performance')),
                  const PopupMenuDivider(height: 1),
                  PopupMenuItem<String>(value: 'hologram', height: 60, padding: EdgeInsets.zero, child: _buildMenuItem(icon: Icons.blur_circular, iconColor: AppColors.violet, title: 'Hologram', subtitle: 'AI Broadcaster')),
                ],
              ),
            ],
          ),
          body: Column(children: [
            Container(
              width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.amber.withOpacity(0.2), AppColors.red.withOpacity(0.1)]), border: Border(bottom: BorderSide(color: AppColors.amber.withOpacity(0.6), width: 1))),
              child: Row(children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.amber, size: 14),
                const SizedBox(width: 6),
                Expanded(child: Text('⚠️ إشارات تحليلية - التداول يحمل مخاطرة', style: TextStyle(color: AppColors.amber.withOpacity(0.9), fontSize: 10, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
              ]),
            ),
            Expanded(child: IndexedStack(index: currentIndex, children: screens)),
          ]),
          bottomNavigationBar: Container(
            decoration: const BoxDecoration(gradient: LinearGradient(colors: [AppColors.backgroundTwo, AppColors.background]), border: Border(top: BorderSide(color: AppColors.cyan, width: 0.5))),
            child: BottomNavigationBar(
              currentIndex: currentIndex, onTap: (i) => setState(() => currentIndex = i), backgroundColor: Colors.transparent, elevation: 0, selectedItemColor: AppColors.gold, unselectedItemColor: AppColors.silver.withOpacity(0.6), type: BottomNavigationBarType.fixed,
              items: [
                BottomNavigationBarItem(icon: const Icon(Icons.home_rounded), label: Translation.get('home')),
                BottomNavigationBarItem(icon: const Icon(Icons.auto_graph_rounded), label: Translation.get('history')),
                BottomNavigationBarItem(icon: const Icon(Icons.tune_rounded), label: Translation.get('settings')),
                BottomNavigationBarItem(icon: const Icon(Icons.auto_awesome_rounded), label: Translation.get('about')),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildList() {
    final today = AppState.todayStats();
    final pairs = filtered;
    return RefreshIndicator(
      onRefresh: refreshAll, color: AppColors.cyan, backgroundColor: AppColors.backgroundTwo,
      child: Column(children: [
        Container(
          margin: const EdgeInsets.fromLTRB(12, 8, 12, 8), padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.backgroundTwo, border: Border.all(color: AppColors.gold.withOpacity(0.3)), borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            _hudStat('TODAY', '${today['total']}', AppColors.cyan), _hudStat('CALL', '${today['calls']}', AppColors.green), _hudStat('PUT', '${today['puts']}', AppColors.red), _hudStat('TIMER', '${secondsRemaining}s', AppColors.gold),
          ]),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            _hudChip('ALL', categoryFilter == 'ALL', () => setState(() => categoryFilter = 'ALL')),
            _hudChip('CRYPTO', categoryFilter == 'crypto', () => setState(() => categoryFilter = 'crypto')),
            _hudChip('FOREX', categoryFilter == 'forex', () => setState(() => categoryFilter = 'forex')),
            _hudChip('COMMODITY', categoryFilter == 'commodity', () => setState(() => categoryFilter = 'commodity')),
          ]),
        ),
        const SizedBox(height: 8),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(color: AppColors.backgroundThree, border: Border.all(color: AppColors.cyan.withOpacity(0.2))),
          child: TextField(
            onChanged: (v) => setState(() => searchQuery = v), style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
            decoration: InputDecoration(hintText: 'SEARCH ASSET...', hintStyle: TextStyle(color: AppColors.silver.withOpacity(0.3), fontSize: 12, fontFamily: 'monospace'), prefixIcon: const Icon(Icons.search, color: AppColors.cyan, size: 18), border: InputBorder.none, contentPadding: const EdgeInsets.symmetric(vertical: 12)),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(children: [
            _filterChip('ALL', filterType == 'ALL', AppColors.silver, () => setState(() => filterType = 'ALL')),
            _filterChip('CALL', filterType == 'CALL', AppColors.green, () => setState(() => filterType = 'CALL')),
            _filterChip('PUT', filterType == 'PUT', AppColors.red, () => setState(() => filterType = 'PUT')),
            _filterChip('WAIT', filterType == 'WAIT', AppColors.amber, () => setState(() => filterType = 'WAIT')),
          ]),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Stack(children: [
            ListView.builder(padding: const EdgeInsets.only(bottom: 20), itemCount: pairs.length, itemBuilder: (c, i) => PairCard(pair: pairs[i], secondsToEntry: secondsToEntry(pairs[i]))),
            if (isLoading) const Positioned(top: 12, right: 12, child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.cyan))),
          ]),
        ),
      ]),
    );
  }

  Widget _hudStat(String label, String value, Color color) {
    return Column(children: [
      Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'monospace')),
      Text(label, style: TextStyle(color: AppColors.silver.withOpacity(0.4), fontSize: 9, fontFamily: 'monospace', letterSpacing: 1)),
    ]);
  }

  Widget _hudChip(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6), decoration: BoxDecoration(color: isSelected ? AppColors.violet.withOpacity(0.2) : Colors.transparent, border: Border.all(color: isSelected ? AppColors.violet : AppColors.silver.withOpacity(0.2))), child: Text(label, style: TextStyle(color: isSelected ? AppColors.violet : AppColors.silver, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace'))));
  }

  Widget _filterChip(String label, bool isSelected, Color color, VoidCallback onTap) {
    return GestureDetector(onTap: onTap, child: Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), decoration: BoxDecoration(color: isSelected ? color.withOpacity(0.2) : Colors.transparent, border: Border.all(color: isSelected ? color : AppColors.silver.withOpacity(0.2))), child: Text(label, style: TextStyle(color: isSelected ? color : AppColors.silver, fontSize: 10, fontWeight: FontWeight.bold, fontFamily: 'monospace'))));
  }

  Widget _buildActionButton({required IconData icon, required Color color, required String tooltip, required VoidCallback onTap}) {
    return Padding(padding: const EdgeInsets.symmetric(horizontal: 1), child: Tooltip(message: tooltip, child: Material(color: Colors.transparent, child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(20), child: Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [color.withOpacity(0.25), color.withOpacity(0.08)]), shape: BoxShape.circle, border: Border.all(color: color.withOpacity(0.5), width: 1.2), boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8)]), child: Icon(icon, color: color, size: 18))))));
  }

  Widget _buildMenuItem({required IconData icon, required Color iconColor, required String title, required String subtitle}) {
    return Container(width: 220, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), child: Row(children: [
      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [iconColor.withOpacity(0.3), iconColor.withOpacity(0.1)]), shape: BoxShape.circle, border: Border.all(color: iconColor.withOpacity(0.5), width: 1), boxShadow: [BoxShadow(color: iconColor.withOpacity(0.3), blurRadius: 8)]), child: Icon(icon, color: iconColor, size: 18)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
        Text(subtitle, style: TextStyle(color: AppColors.silver.withOpacity(0.6), fontSize: 10)),
      ])),
      Icon(Icons.arrow_forward_ios, color: AppColors.silver.withOpacity(0.4), size: 12),
    ]));
  }
}