import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_colors.dart';
import '../services/groq_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  ChatMessage({required this.text, required this.isUser, required this.time});
}

class ChatScreen extends StatefulWidget {
  final String userName;
  final double batteryPercentage;
  final double solarGenerationWatts;
  final double currentLoadWatts;

  const ChatScreen({
    super.key,
    required this.userName,
    required this.batteryPercentage,
    required this.solarGenerationWatts,
    required this.currentLoadWatts,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  late List<ChatMessage> _messages;
  bool _isLoading = false;

  final List<String> _quickQuestions = [
    'كيف أقتصد في الكهرباء الآن؟',
    'ما التوقعات للبطارية الليلة؟',
    'هل توجد أي مشكلة في النظام؟',
  ];

  @override
  void initState() {
    super.initState();
    _messages = [
      ChatMessage(
        text: "أهلاً بك يا ${widget.userName}! أنا 'فورتيفاي' حارس الطاقة الشمسية الذكي. أستطيع إجابتك عن أي سؤال يخص بطاريتك، استهلاكك، أو توقعات الإنتاج اليوم.",
        isUser: false,
        time: DateTime.now(),
      )
    ];
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = text.trim();
    _messageController.clear();

    setState(() {
      _messages.add(ChatMessage(text: userMsg, isUser: true, time: DateTime.now()));
      _isLoading = true;
    });
    _scrollToBottom();
    final aiReply = await GroqService.getSolarAnalysis(
      batteryPercentage: widget.batteryPercentage,
      solarGenerationWatts: widget.solarGenerationWatts,
      currentLoadWatts: widget.currentLoadWatts,
      weatherCondition: 'مشمس جزئياً',
      userQuery: userMsg,
    );

    if (mounted) {
      setState(() {
        _messages.add(ChatMessage(text: aiReply, isUser: false, time: DateTime.now()));
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(6.r),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.psychology, color: AppColors.primary),
            ),
            SizedBox(width: 10.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'مساعد voltify الذكي',
                  style: GoogleFonts.tajawal(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                Text(
                  '● متصل للتحليل الفوري',
                  style: GoogleFonts.tajawal(
                    fontSize: 11.sp,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildChatBubble(msg);
                },
              ),
            ),
            if (_isLoading)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 6.h),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16.r,
                      height: 16.r,
                      child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      'voltify يحلل قراءات النظام ويكتب الرد...',
                      style: GoogleFonts.tajawal(fontSize: 12.sp, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

            SizedBox(
              height: 40.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                itemCount: _quickQuestions.length,
                itemBuilder: (context, index) {
                  final q = _quickQuestions[index];
                  return Padding(
                    padding: EdgeInsets.only(left: 8.w),
                    child: ActionChip(
                      label: Text(q, style: GoogleFonts.tajawal(fontSize: 12.sp, color: AppColors.primary)),
                      backgroundColor: Colors.amber.shade50,
                      side: BorderSide(color: Colors.amber.shade200),
                      onPressed: () => _sendMessage(q),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: AppColors.inputBorder)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: GoogleFonts.tajawal(fontSize: 14.sp),
                      decoration: InputDecoration(
                        hintText: 'اكتب سؤالك لحارس الطاقة...',
                        hintStyle: GoogleFonts.tajawal(fontSize: 13.sp, color: AppColors.textSecondary),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.r),
                          borderSide: const BorderSide(color: AppColors.inputBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20.r),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  SizedBox(width: 8.w),
                  Container(
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: () => _sendMessage(_messageController.text),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildChatBubble(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 6.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        constraints: BoxConstraints(maxWidth: 280.w),
        decoration: BoxDecoration(
          color: msg.isUser ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
            bottomLeft: msg.isUser ? Radius.circular(16.r) : Radius.zero,
            bottomRight: msg.isUser ? Radius.zero : Radius.circular(16.r),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.text,
              style: GoogleFonts.tajawal(
                fontSize: 13.sp,
                color: msg.isUser ? Colors.white : AppColors.textDark,
                height: 1.4,
              ),
            ),
            SizedBox(height: 4.h),
            Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                '${msg.time.hour}:${msg.time.minute.toString().padLeft(2, '0')}',
                style: GoogleFonts.tajawal(
                  fontSize: 10.sp,
                  color: msg.isUser ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
