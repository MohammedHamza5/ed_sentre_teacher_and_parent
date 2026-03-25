import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Removed AppColors import
import '../../../shared/data/supabase_repository.dart';
import '../../../shared/models/models.dart';

class TeacherChatScreen extends StatefulWidget {
  final ConversationModel conversation;

  const TeacherChatScreen({super.key, required this.conversation});

  @override
  State<TeacherChatScreen> createState() => _TeacherChatScreenState();
}

class _TeacherChatScreenState extends State<TeacherChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<MessageModel> _messages = [];
  bool _isLoading = true;
  final int _pageSize = 30;
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  RealtimeChannel? _subscription;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadMessages(reset: true);
    _subscribeToMessages();
    _markAsRead();
  }

  Future<void> _markAsRead() async {
    try {
      await context.read<SupabaseRepository>().markMessagesAsRead(widget.conversation.id);
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    if (_subscription != null) {
      context.read<SupabaseRepository>().unsubscribe(_subscription!);
    }
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.offset <= 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    setState(() => _isLoadingMore = true);
    await _loadMessages();
  }

  Future<void> _loadMessages({bool reset = false}) async {
    try {
      if (reset) {
        setState(() {
          _isLoading = true;
          _currentPage = 0;
          _hasMore = true;
          _messages = [];
        });
      }
      final repo = context.read<SupabaseRepository>();
      final beforeMaxExtent = _scrollController.hasClients
          ? _scrollController.position.maxScrollExtent
          : 0.0;
      final beforeOffset = _scrollController.hasClients
          ? _scrollController.offset
          : 0.0;
      final messages = await repo.getMessages(
        widget.conversation.id,
        limit: _pageSize,
        offset: _currentPage * _pageSize,
        ascending: false,
      );
      final page = messages.reversed.toList();

      if (mounted) {
        setState(() {
          if (reset) {
            _messages = page;
          } else {
            _messages = [...page, ..._messages];
          }
          _isLoading = false;
          _isLoadingMore = false;
          _currentPage += 1;
          _hasMore = page.length == _pageSize;
        });
        if (reset) {
          _scrollToBottom();
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              final afterMaxExtent = _scrollController.position.maxScrollExtent;
              final delta = afterMaxExtent - beforeMaxExtent;
              _scrollController.jumpTo(beforeOffset + delta);
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading messages: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  void _subscribeToMessages() {
    final repo = context.read<SupabaseRepository>();
    _subscription = repo.subscribeToMessages(widget.conversation.id, (
      newMessage,
    ) {
      if (mounted) {
        setState(() {
          _messages.add(newMessage);
        });
        _scrollToBottom();
      }
    });
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

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    _messageController.clear();

    try {
      final repo = context.read<SupabaseRepository>();
      await repo.sendMessage(
        conversationId: widget.conversation.id,
        content: content,
      );
    } catch (e) {
      debugPrint('Error sending message: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('فشل إرسال الرسالة'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: (Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary.withOpacity(0.8)]),
              ),
              child: CircleAvatar(
                radius: 18.r,
                backgroundColor: Colors.transparent,
                backgroundImage: widget.conversation.studentAvatar != null
                    ? NetworkImage(widget.conversation.studentAvatar!)
                    : null,
                child: widget.conversation.studentAvatar == null
                    ? const Icon(Icons.person, color: Colors.white)
                    : null,
              ),
            ),
            SizedBox(width: 10.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.conversation.studentName ?? 'طالب',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 6.w,
                      height: 6.w,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'متصل الآن',
                      style: TextStyle(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(color: Theme.of(context).colorScheme.primary),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(16.w),
                    itemCount: _messages.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isLoadingMore && index == 0) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 12.h),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        );
                      }
                      final actualIndex = _isLoadingMore ? index - 1 : index;
                      final msg = _messages[actualIndex];
                      return _buildMessageBubble(msg);
                    },
                  ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel msg) {
    final isMe = msg.isMine;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(bottom: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          gradient: isMe ? LinearGradient(colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary.withOpacity(0.8)]) : null,
          color: isMe ? null : (Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
            bottomLeft: isMe ? Radius.circular(16.r) : Radius.zero,
            bottomRight: isMe ? Radius.zero : Radius.circular(16.r),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        constraints: BoxConstraints(maxWidth: 0.75.sw),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg.content ?? '',
              style: TextStyle(
                color: isMe ? Colors.white : Theme.of(context).colorScheme.onSurface,
                fontSize: 14.sp,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              DateFormat('hh:mm a').format(msg.createdAt),
              style: TextStyle(
                color: isMe
                    ? Colors.white.withValues(alpha: 0.7)
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontSize: 10.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: (Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface),
        border: Border(top: BorderSide(color: Theme.of(context).colorScheme.outline.withOpacity(0.5), width: 1)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.attach_file),
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  color: (Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface),
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
                ),
                child: TextField(
                  controller: _messageController,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 14.sp,
                  ),
                  decoration: InputDecoration(
                    hintText: 'اكتب رسالتك...',
                    hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7)),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.primary.withOpacity(0.8)]),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: _sendMessage,
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
