import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/config/app_colors.dart';
import '../../ai/provider/ai_provider.dart';

/// شاشة المحادثة مع المساعد الذكي — مع حفظ السجل
class AIChatScreen extends StatefulWidget {
  /// إذا كان null يتم عرض قائمة المحادثات أولاً
  final String? conversationId;

  const AIChatScreen({super.key, this.conversationId});

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;
  bool _isLoadingMessages = true;
  String? _currentConversationId;
  bool _isFirstMessage = true;
  File? _selectedFile;
  bool _isUploadingFile = false;

  @override
  void initState() {
    super.initState();
    _currentConversationId = widget.conversationId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_currentConversationId != null) {
        _loadMessages();
      } else {
        _createNewConversation();
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في اختيار الملف: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _createNewConversation() async {
    setState(() => _isLoadingMessages = true);
    final aiProvider = context.read<AIProvider>();
    final id = await aiProvider.createConversation();
    if (id != null && mounted) {
      setState(() {
        _currentConversationId = id;
        _messages = [];
        _isLoadingMessages = false;
        _isFirstMessage = true;
      });
    }
  }

  Future<void> _loadMessages() async {
    if (_currentConversationId == null) return;
    setState(() => _isLoadingMessages = true);

    final aiProvider = context.read<AIProvider>();
    final messages = await aiProvider.loadMessages(_currentConversationId!);

    if (mounted) {
      setState(() {
        _messages = messages;
        _isLoadingMessages = false;
        _isFirstMessage = messages.isEmpty;
      });
      _scrollToBottom();
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _currentConversationId == null) return;

    final aiProvider = context.read<AIProvider>();

    // NOTE: Chat has no daily limit — always available

    // إضافة رسالة المستخدم فوراً
    setState(() {
      _messages.add({
        'role': 'user',
        'content': text,
        'created_at': DateTime.now().toIso8601String(),
      });
      _isTyping = true;
    });
    _messageController.clear();
    _scrollToBottom();

    // تسمية تلقائية بعد أول رسالة
    final shouldAutoName = _isFirstMessage;
    _isFirstMessage = false;

    String? uploadedFilePath;
    if (_selectedFile != null) {
      if (mounted) {
        setState(() => _isUploadingFile = true);
      }
      uploadedFilePath = await aiProvider.uploadDocumentToStorage(
        _selectedFile!,
      );
      if (mounted) {
        setState(() {
          _isUploadingFile = false;
          _selectedFile = null; // Reset after reading/uploading it
        });
      }

      if (uploadedFilePath == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('فشل رفع الملف المرفق. الرجاء المحاولة مجدداً.'),
            ),
          );
        }
        // Remove the user message assuming it failed since the file was part of it
        setState(() {
          _messages.removeLast();
          _isTyping = false;
        });
        return;
      }
    }

    // إرسال إلى AI
    final aiReply = await aiProvider.sendChatMessage(
      conversationId: _currentConversationId!,
      content: text,
      filePath: uploadedFilePath,
      history:
          _messages
              .where((m) => m['role'] == 'user' || m['role'] == 'assistant')
              .toList()
            ..removeLast(), // Remove the message we just added
    );

    if (mounted) {
      setState(() {
        _isTyping = false;
        if (aiReply != null) {
          _messages.add({
            'role': 'assistant',
            'content': aiReply,
            'created_at': DateTime.now().toIso8601String(),
          });
        }
      });
      _scrollToBottom();
    }

    // تسمية تلقائية
    if (shouldAutoName && aiReply != null) {
      aiProvider.autoNameConversation(_currentConversationId!, text);
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

  void _showConversationHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (ctx) => _ConversationHistorySheet(
        onSelect: (id) {
          Navigator.pop(ctx);
          setState(() {
            _currentConversationId = id;
            _messages = [];
          });
          _loadMessages();
        },
        onNewChat: () {
          Navigator.pop(ctx);
          _createNewConversation();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Text(
          'المساعد الذكي 💬',
          style: TextStyle(color: AppColors.textOnDark, fontSize: 18.sp),
        ),
        backgroundColor: AppColors.darkCard,
        foregroundColor: AppColors.textOnDark,
        elevation: 0,
        actions: [
          // زر المحادثات السابقة
          IconButton(
            onPressed: _showConversationHistory,
            icon: const Icon(Icons.history_rounded),
            tooltip: 'سجل المحادثات',
          ),
          // زر محادثة جديدة
          IconButton(
            onPressed: _createNewConversation,
            icon: const Icon(Icons.add_comment_rounded),
            tooltip: 'محادثة جديدة',
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick suggestions (فقط في بداية المحادثة)
          if (_messages.isEmpty && !_isLoadingMessages)
            _buildQuickSuggestions(),

          // Messages
          Expanded(
            child: _isLoadingMessages
                ? Center(
                    child: CircularProgressIndicator(
                      backgroundColor: AppColors.primary,
                    ),
                  )
                : _messages.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.smart_toy_outlined,
            size: 64.sp,
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
          ),
          SizedBox(height: 16.h),
          Text(
            'ابدأ محادثة جديدة!',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textOnDark,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'اكتب سؤالك أو اختر اقتراحاً أدناه',
            style: TextStyle(
              fontSize: 14.sp,
              color: AppColors.textOnDarkSecondary,
            ),
          ),
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
    _sendMessage();
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isUser = message['role'] == 'user';
    return Align(
      alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 12.h,
          left: isUser ? 48.w : 0,
          right: isUser ? 0 : 48.w,
        ),
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(
                  colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                )
              : null,
          color: isUser ? null : AppColors.darkCard,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
            bottomLeft: isUser ? Radius.circular(16.r) : Radius.circular(4.r),
            bottomRight: isUser ? Radius.circular(4.r) : Radius.circular(16.r),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        constraints: BoxConstraints(maxWidth: 0.75.sw),
        child: SelectableText(
          message['content'] ?? '',
          style: TextStyle(
            fontSize: 14.sp,
            color: isUser ? Colors.white : AppColors.textOnDark,
            height: 1.5,
          ),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Selected File Preview
            if (_selectedFile != null)
              Container(
                margin: EdgeInsets.only(bottom: 8.h),
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.picture_as_pdf,
                      color: AppColors.primary,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        _selectedFile!.path.split('/').last,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: AppColors.error,
                        size: 18.sp,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _isUploadingFile
                          ? null
                          : () => setState(() => _selectedFile = null),
                    ),
                  ],
                ),
              ),

            // Input Row
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.darkSurface,
                      borderRadius: BorderRadius.circular(24.r),
                      border: Border.all(color: AppColors.darkBorder),
                    ),
                    child: Row(
                      children: [
                        // Attachment Button
                        IconButton(
                          icon: Icon(
                            Icons.attach_file,
                            color: AppColors.textOnDarkSecondary,
                          ),
                          onPressed: (_isTyping || _isUploadingFile)
                              ? null
                              : _pickFile,
                          tooltip: 'إرفاق ملف PDF',
                        ),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            style: TextStyle(
                              color: AppColors.textOnDark,
                              fontSize: 14.sp,
                            ),
                            decoration: InputDecoration(
                              hintText: 'اكتب سؤالك...',
                              hintStyle: TextStyle(
                                color: AppColors.textOnDarkSecondary,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 10.h,
                              ),
                            ),
                            maxLines: null,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                      ],
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
                    onPressed: (_isTyping || _isUploadingFile)
                        ? null
                        : _sendMessage,
                    icon: _isUploadingFile
                        ? SizedBox(
                            width: 20.sp,
                            height: 20.sp,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              backgroundColor: Colors.white,
                            ),
                          )
                        : Icon(Icons.send, color: Colors.white, size: 20.sp),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// شاشة سجل المحادثات
// ═══════════════════════════════════════════════════════════════════════

class _ConversationHistorySheet extends StatefulWidget {
  final Function(String) onSelect;
  final VoidCallback onNewChat;

  const _ConversationHistorySheet({
    required this.onSelect,
    required this.onNewChat,
  });

  @override
  State<_ConversationHistorySheet> createState() =>
      _ConversationHistorySheetState();
}

class _ConversationHistorySheetState extends State<_ConversationHistorySheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AIProvider>().loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, controller) {
        return Consumer<AIProvider>(
          builder: (_, aiProvider, __) {
            final conversations = aiProvider.conversations;

            return Column(
              children: [
                // Handle bar
                Container(
                  margin: EdgeInsets.symmetric(vertical: 12.h),
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: AppColors.darkBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),

                // Header
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Row(
                    children: [
                      Icon(
                        Icons.history_rounded,
                        color: AppColors.textOnDark,
                        size: 24.sp,
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        'سجل المحادثات',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textOnDark,
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: widget.onNewChat,
                        icon: Icon(Icons.add, size: 18.sp),
                        label: Text('جديد', style: TextStyle(fontSize: 13.sp)),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF8B5CF6),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 8.h),

                // List
                Expanded(
                  child: aiProvider.isLoadingConversations
                      ? Center(
                          child: CircularProgressIndicator(
                            backgroundColor: AppColors.primary,
                          ),
                        )
                      : conversations.isEmpty
                      ? Center(
                          child: Text(
                            'لا توجد محادثات سابقة',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: AppColors.textOnDarkSecondary,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: controller,
                          padding: EdgeInsets.symmetric(horizontal: 16.w),
                          itemCount: conversations.length,
                          itemBuilder: (context, index) {
                            final conv = conversations[index];
                            return _buildConversationTile(conv);
                          },
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildConversationTile(Map<String, dynamic> conv) {
    final title = conv['title'] ?? 'محادثة';
    final messageCount = conv['message_count'] ?? 0;
    final lastMessageAt = conv['last_message_at'];
    String timeAgo = '';
    if (lastMessageAt != null) {
      final dt = DateTime.tryParse(lastMessageAt.toString());
      if (dt != null) {
        final diff = DateTime.now().difference(dt);
        if (diff.inMinutes < 60) {
          timeAgo = 'منذ ${diff.inMinutes} دقيقة';
        } else if (diff.inHours < 24) {
          timeAgo = 'منذ ${diff.inHours} ساعة';
        } else {
          timeAgo = 'منذ ${diff.inDays} يوم';
        }
      }
    }

    return Dismissible(
      key: Key(conv['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(Icons.delete, color: AppColors.error, size: 24.sp),
      ),
      onDismissed: (_) {
        context.read<AIProvider>().deleteConversation(conv['id']);
      },
      child: Card(
        color: AppColors.darkSurface,
        margin: EdgeInsets.only(bottom: 8.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: BorderSide(color: AppColors.darkBorder.withValues(alpha: 0.5)),
        ),
        child: ListTile(
          onTap: () => widget.onSelect(conv['id']),
          leading: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              color: const Color(0xFF8B5CF6),
              size: 20.sp,
            ),
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: AppColors.textOnDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '$messageCount رسالة • $timeAgo',
            style: TextStyle(
              fontSize: 11.sp,
              color: AppColors.textOnDarkSecondary,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 14.sp,
            color: AppColors.textOnDarkHint,
          ),
        ),
      ),
    );
  }
}
