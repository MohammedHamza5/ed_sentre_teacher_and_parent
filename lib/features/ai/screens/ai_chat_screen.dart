import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/app_colors.dart';
import '../../../core/services/ai_service.dart'; // New Import
import '../../../core/config/ai_config.dart'; // New Import
import '../../ai/provider/ai_provider.dart';
import '../../auth/provider/auth_provider.dart';
// import '../services/ai_service.dart'; // Removed old import

/// شاشة المحادثة مع المساعد الذكي
class AIChatScreen extends StatefulWidget {
  const AIChatScreen({super.key});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _messages.add(
      _ChatMessage(
        text:
            'مرحباً! أنا المساعد الذكي 🤖\n\nكيف يمكنني مساعدتك اليوم؟\n\nيمكنني:\n• كتابة رسائل لأولياء الأمور\n• اقتراح أفكار للشرح\n• تحليل أداء الطلاب\n• الإجابة عن أسئلتك التعليمية',
        isUser: false,
        timestamp: DateTime.now(),
      ),
    );
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
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(
          'المساعد الذكي 💬',
          style: TextStyle(color: AppColors.textOnDark),
        ),
        backgroundColor: AppColors.darkCard,
        foregroundColor: AppColors.textOnDark,
        elevation: 0,
        actions: [
          Container(
            margin: EdgeInsets.only(left: 12.w),
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
              ),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.stars, size: 16.sp, color: Colors.amber),
                SizedBox(width: 4.w),
                Consumer<AIProvider>(
                  builder: (_, ai, __) => Text(
                    '${ai.totalCredits}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick suggestions
          _buildQuickSuggestions(),

          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(16.w),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isTyping && index == _messages.length) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          // Input
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildQuickSuggestions() {
    final suggestions = [
      '📝 رسالة لولي أمر',
      '💡 اقتراح طريقة شرح',
      '📊 تحليل أداء',
    ];

    return Container(
      height: 48.h,
      padding: EdgeInsets.symmetric(vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        border: Border(bottom: BorderSide(color: AppColors.darkBorder)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          return ActionChip(
            label: Text(
              suggestions[index],
              style: TextStyle(fontSize: 12.sp, color: AppColors.textOnDark),
            ),
            backgroundColor: AppColors.darkSurface,
            side: BorderSide(color: AppColors.darkBorder),
            onPressed: () => _handleQuickSuggestion(index),
          );
        },
      ),
    );
  }

  void _handleQuickSuggestion(int index) {
    switch (index) {
      case 0:
        _messageController.text = 'اكتب لي رسالة لولي أمر طالب متأخر في الحضور';
        break;
      case 1:
        _messageController.text = 'اقترح طريقة مبتكرة لشرح جدول الضرب للطلاب';
        break;
      case 2:
        _messageController.text = 'كيف أحسن أداء الطلاب الضعفاء في صفي؟';
        break;
    }
    FocusScope.of(context).requestFocus(FocusNode());
    _sendMessage();
  }

  Widget _buildMessageBubble(_ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 12.h,
          left: message.isUser ? 48.w : 0,
          right: message.isUser ? 0 : 48.w,
        ),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          gradient: message.isUser
              ? const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                )
              : null,
          color: message.isUser ? null : AppColors.darkCard,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
            bottomLeft: message.isUser
                ? Radius.circular(16.r)
                : Radius.circular(4.r),
            bottomRight: message.isUser
                ? Radius.circular(4.r)
                : Radius.circular(16.r),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              message.text,
              style: TextStyle(
                fontSize: 14.sp,
                color: message.isUser ? Colors.white : AppColors.textOnDark,
                height: 1.5,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                fontSize: 10.sp,
                color: message.isUser
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppColors.textOnDarkSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h, right: 48.w),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDot(0),
            SizedBox(width: 4.w),
            _buildDot(1),
            SizedBox(width: 4.w),
            _buildDot(2),
          ],
        ),
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 8.w,
          height: 8.w,
          decoration: BoxDecoration(
            color: const Color(
              0xFF8B5CF6,
            ).withValues(alpha: 0.3 + (value * 0.4)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        border: Border(top: BorderSide(color: AppColors.darkBorder)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: TextField(
                  controller: _messageController,
                  style: TextStyle(
                    color: AppColors.textOnDark,
                    fontSize: 14.sp,
                  ),
                  decoration: InputDecoration(
                    hintText: 'اكتب سؤالك...',
                    hintStyle: TextStyle(color: AppColors.textOnDarkSecondary),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 10.h,
                    ),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                ),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _isTyping ? null : _sendMessage,
                icon: Icon(Icons.send, color: Colors.white, size: 20.sp),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final aiProvider = context.read<AIProvider>();

    if (aiProvider.totalCredits < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('لا يوجد رصيد كافي'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _messages.add(
        _ChatMessage(text: text, isUser: true, timestamp: DateTime.now()),
      );
      _isTyping = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final auth = context.read<AuthProvider>();
      final teacherName = auth.teacherProfile?.fullName ?? 'المعلم';

      final aiService = AiService(Supabase.instance.client);

      // Build History
      final history = _messages
          .where(
            (m) => m.text != text,
          ) // Exclude current message as it is sent as content
          .map(
            (m) => {'role': m.isUser ? 'user' : 'assistant', 'content': m.text},
          )
          .toList();

      final response = await aiService.router.executeTask(
        task: EdSentreTask.teacherChatAssistant,
        content: text,
        params: {
          'messages': history,
          'context':
              'أنت مساعد ذكي للمعلم "$teacherName" في مركز تعليمي. أجب بأسلوب مهني ومفيد باللغة العربية.',
        },
      );

      await aiProvider.useCredits(2);

      setState(() {
        _isTyping = false;
        _messages.add(
          _ChatMessage(
            text: response.raw ?? 'لم أفهم ذلك.',
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
      _scrollToBottom();
    } catch (e) {
      setState(() => _isTyping = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: AppColors.error),
        );
      }
    }
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

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  _ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}
