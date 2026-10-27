import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../constants/colors.dart';
import '../constants/translations.dart';
import 'cosmic_background.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // 🔑 مفتاح Groq
  static const String API_KEY =
      const String apiKey = 'YOUR_GROQ_API_KEY_HERE';

  static const String API_URL =
      'https://api.groq.com/openai/v1/chat/completions';

  // ✅ الموديلات المتاحة لمفتاحك (بالترتيب: الأقوى → الأسرع)
  static const List<String> MODELS = [
    'openai/gpt-oss-120b',
    'qwen/qwen3.8-27b',
    'openai/gpt-oss-20b',
    'allam-2-7b',
  ];

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messages.add({
      'role': 'ai',
      'text':
          'مرحباً! 👋\nأنا FX Sniper AI، مساعدك في التداول.\n\nيمكنك سؤالي عن:\n• أي زوج (مثل BTC/USD)\n• شرح المؤشرات\n• إشارات التطبيق\n• إدارة المخاطر\n\nاكتب سؤالك!',
    });
  }

  Future<String?> _callAI(String userText) async {
    for (final model in MODELS) {
      for (int attempt = 1; attempt <= 2; attempt++) {
        try {
          final response = await http.post(
            Uri.parse(API_URL),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $API_KEY',
            },
            body: jsonEncode({
              'model': model,
              'messages': [
                {
                  'role': 'system',
                  'content':
                      'أنت مساعد خبير في التداول (فوركس وعملات رقمية). تجيب بالعربية بإيجاز ووضوح. اشرح المفاهيم بلغة سهلة ومبسطة.',
                },
                {'role': 'user', 'content': userText},
              ],
              'temperature': 0.7,
              'max_tokens': 1024,
            }),
          );

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            return data['choices'][0]['message']['content'];
          } else if (response.statusCode == 429) {
            await Future.delayed(Duration(seconds: attempt * 2));
            continue;
          } else {
            break;
          }
        } catch (e) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }
    return null;
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    final aiText = await _callAI(text);

    setState(() {
      if (aiText != null) {
        _messages.add({'role': 'ai', 'text': aiText});
      } else {
        _messages.add({
          'role': 'ai',
          'text':
              '⚠️ تعذّر الاتصال بالذكاء الاصطناعي.\nتأكد من الإنترنت وحاول مجدداً.'
        });
      }
      _isLoading = false;
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
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
            title: Row(
              children: const [
                Icon(Icons.smart_toy, color: AppColors.cyan, size: 22),
                SizedBox(width: 8),
                Text(
                  'FX Sniper AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            iconTheme: const IconThemeData(color: AppColors.gold),
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: _messages.length,
                  itemBuilder: (c, i) {
                    final m = _messages[i];
                    final isUser = m['role'] == 'user';
                    return Align(
                      alignment: isUser
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        constraints: BoxConstraints(
                          maxWidth:
                              MediaQuery.of(context).size.width * 0.78,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isUser
                                ? [
                                    AppColors.cyan.withOpacity(0.3),
                                    AppColors.cyan.withOpacity(0.1),
                                  ]
                                : [
                                    AppColors.gold.withOpacity(0.25),
                                    AppColors.gold.withOpacity(0.08),
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: isUser
                                ? AppColors.cyan.withOpacity(0.5)
                                : AppColors.gold.withOpacity(0.5),
                          ),
                        ),
                        child: SelectableText(
                          m['text'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              if (_isLoading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.gold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'جارٍ التفكير...',
                        style: TextStyle(
                          color: AppColors.silver,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.backgroundTwo.withOpacity(0.9),
                      AppColors.background.withOpacity(0.9),
                    ],
                  ),
                  border: Border(
                    top: BorderSide(
                      color: AppColors.cyan.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.backgroundThree
                              .withOpacity(0.5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.cyan.withOpacity(0.3),
                          ),
                        ),
                        child: TextField(
                          controller: _controller,
                          onSubmitted: (_) => _sendMessage(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          decoration: InputDecoration(
                            hintText: 'اكتب سؤالك...',
                            hintStyle: TextStyle(
                              color:
                                  AppColors.silver.withOpacity(0.5),
                              fontSize: 12,
                            ),
                            border: InputBorder.none,
                            contentPadding:
                                const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        padding: const EdgeInsets.all(11),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [
                              AppColors.gold,
                              AppColors.goldDark
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.gold.withOpacity(0.5),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.send,
                          color: AppColors.background,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}