import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/center_provider.dart';
import '../../../../shared/data/supabase_repository.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/premium_widgets.dart';
import 'teacher_chat_screen.dart';
import 'teacher_new_chat_screen.dart';

/// Teacher Messages Screen - Premium Dark Mode
class TeacherMessagesScreen extends StatefulWidget {
  const TeacherMessagesScreen({super.key});

  @override
  State<TeacherMessagesScreen> createState() => _TeacherMessagesScreenState();
}

class _TeacherMessagesScreenState extends State<TeacherMessagesScreen> {
  bool _isLoading = true;
  List<ConversationModel> _conversations = [];
  List<ConversationModel> _filteredConversations = [];
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final int _pageSize = 20;
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadConversations(reset: true);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.maxScrollExtent > 0 &&
        position.pixels >= position.maxScrollExtent - 50) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    setState(() => _isLoadingMore = true);
    await _loadConversations();
  }

  Future<void> _loadConversations({bool reset = false}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _currentPage = 0;
        _hasMore = true;
        _conversations = [];
        _filteredConversations = [];
      });
    }
    try {
      final centerId = context.read<CenterProvider>().currentCenterId;
      if (centerId != null) {
        final repo = context.read<SupabaseRepository>();
        final data = await repo.getTeacherConversations(
          centerId: centerId,
          limit: _pageSize,
          offset: _currentPage * _pageSize,
        );
        if (mounted) {
          setState(() {
            if (reset) {
              _conversations = data;
            } else {
              _conversations.addAll(data);
            }
            _currentPage += 1;
            _hasMore = data.length == _pageSize;
            _isLoading = false;
            _isLoadingMore = false;
          });
          _filterConversations(_searchController.text);
        }
      }
    } catch (e) {
      debugPrint('Error loading conversations: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
          _hasMore = false; // Prevent infinite retry loops on failure
        });
      }
    }
  }

  void _filterConversations(String query) {
    if (query.isEmpty) {
      setState(() => _filteredConversations = _conversations);
    } else {
      setState(() {
        _filteredConversations = _conversations.where((c) {
          final q = query.toLowerCase();
          return (c.studentName ?? '').toLowerCase().contains(q) ||
              (c.parentName ?? '').toLowerCase().contains(q) ||
              c.conversationType.displayName.contains(q);
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(child: _buildSearchBar()),
          _isLoading
              ? SliverFillRemaining(
                  child: Center(
                    child: CircularProgressIndicator(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                )
              : _filteredConversations.isEmpty
              ? SliverFillRemaining(
                  hasScrollBody: false,
                  child: _buildEmptyState(),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildConversationTile(
                      _filteredConversations[index],
                      index,
                    ),
                    childCount: _filteredConversations.length,
                  ),
                ),
          if (_isLoadingMore)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: Center(
                  child: CircularProgressIndicator(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
          SliverToBoxAdapter(child: SizedBox(height: 80.h)),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: 80.h),
        child: FloatingActionButton(
          onPressed: () async {
            await Navigator.of(context, rootNavigator: true).push(
              MaterialPageRoute(builder: (_) => const TeacherNewChatScreen()),
            );
            _loadConversations(reset: true);
          },
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: Icon(Icons.edit_note, color: Colors.white),
        ).animate().scale(delay: 300.ms),
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 130.h,
      floating: false,
      pinned: true,
      backgroundColor:
          (Theme.of(context).cardTheme.color ??
          Theme.of(context).colorScheme.surface),
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.secondary,
                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: EdgeInsets.only(right: 20.w, bottom: 16.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                            child: Icon(
                              Icons.chat_bubble_rounded,
                              color: Colors.white,
                              size: 22.sp,
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Text(
                            'الرسائل',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '${_conversations.length} محادثة',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: Colors.white),
          onPressed: () => _loadConversations(reset: true),
        ),
        Padding(
          padding: EdgeInsets.only(left: 8.w),
          child: SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Container(
        decoration: BoxDecoration(
          color:
              (Theme.of(context).cardTheme.color ??
              Theme.of(context).colorScheme.surface),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.5),
          ),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: _filterConversations,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14.sp,
          ),
          decoration: InputDecoration(
            hintText: 'بحث عن طالب...',
            hintStyle: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
              size: 20.sp,
            ),
            filled: false,
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(vertical: 14.h),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildConversationTile(ConversationModel conversation, int index) {
    final hasUnread = conversation.unreadCountTeacher > 0;
    return Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
          child: PremiumCard(
            onTap: () async {
              await Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(
                  builder: (_) => TeacherChatScreen(conversation: conversation),
                ),
              );
              _loadConversations();
            },
            hasGlow: hasUnread,
            glowColor: Theme.of(context).colorScheme.secondary,
            padding: EdgeInsets.all(14.w),
            child: Row(
              children: [
                // Avatar with online indicator
                Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: hasUnread
                              ? Theme.of(context).colorScheme.secondary
                              : Theme.of(
                                  context,
                                ).colorScheme.outline.withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 24.r,
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        backgroundImage: conversation.studentAvatar != null
                            ? NetworkImage(conversation.studentAvatar!)
                            : null,
                        child: conversation.studentAvatar == null
                            ? Text(
                                (conversation.studentName != null &&
                                        conversation.studentName!.isNotEmpty)
                                    ? conversation.studentName!
                                          .substring(0, 1)
                                          .toUpperCase()
                                    : 'S',
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      (Theme.of(context).cardTheme.color ??
                                      Theme.of(context).colorScheme.surface),
                                ),
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 12.w,
                        height: 12.w,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                (Theme.of(context).cardTheme.color ??
                                Theme.of(context).colorScheme.surface),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(width: 12.w),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (conversation.conversationType ==
                              ConversationType.parentTeacher)
                            Container(
                              margin: EdgeInsets.only(left: 6.w),
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.purple.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: Text(
                                'ولي أمر',
                                style: TextStyle(
                                  color: Colors.purple,
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          Expanded(
                            child: Text(
                              conversation.conversationType ==
                                      ConversationType.parentTeacher
                                  ? '${conversation.parentName ?? 'ولي أمر'} (${conversation.studentName ?? 'طالب'})'
                                  : conversation.studentName ?? 'طالب',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15.sp,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (conversation.lastMessageAt != null)
                            Text(
                              _formatDate(conversation.lastMessageAt!),
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conversation.lastMessage ?? 'ابدأ المحادثة...',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: hasUnread
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Theme.of(context).colorScheme.onSurface
                                          .withValues(alpha: 0.7),
                                fontWeight: hasUnread
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                fontSize: 13.sp,
                              ),
                            ),
                          ),
                          if (hasUnread)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 3.h,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.secondary,
                                    Theme.of(context).colorScheme.secondary
                                        .withValues(alpha: 0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Text(
                                '${conversation.unreadCountTeacher}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
        .animate(delay: Duration(milliseconds: 50 * index))
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.05, end: 0);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(28.w),
            decoration: BoxDecoration(
              color:
                  (Theme.of(context).cardTheme.color ??
                  Theme.of(context).colorScheme.surface),
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.5),
              ),
            ),
            child: Icon(
              Icons.chat_bubble_outline,
              size: 56.sp,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'لا توجد محادثات',
            style: TextStyle(
              fontSize: 18.sp,
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'ستظهر المحادثات مع أولياء الأمور هنا',
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return DateFormat('hh:mm a').format(date);
    } else if (diff.inDays == 1) {
      return 'أمس';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }
}
