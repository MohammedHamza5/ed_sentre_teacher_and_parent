import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../../core/config/app_colors.dart';
import '../../../../shared/data/supabase_repository.dart';
import '../../../../shared/models/notification_model.dart';
import '../../../../core/widgets/genius/shimmer_skeleton.dart';

/// Parent Notifications Screen - Premium Design with Real Data
class ParentNotificationsScreen extends StatefulWidget {
  const ParentNotificationsScreen({super.key});

  @override
  State<ParentNotificationsScreen> createState() =>
      _ParentNotificationsScreenState();
}

class _ParentNotificationsScreenState extends State<ParentNotificationsScreen> {

  bool _isLoading = true;
  List<NotificationModel> _notifications = [];
  final ScrollController _scrollController = ScrollController();
  final int _pageSize = 20;
  int _currentPage = 0;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadNotifications(reset: true);
  }

  @override
  void dispose() {
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
    await _loadNotifications();
  }

  Future<void> _loadNotifications({bool reset = false}) async {
    if (reset) {
      setState(() {
        _isLoading = true;
        _currentPage = 0;
        _hasMore = true;
        _notifications = [];
      });
    }
    try {
      final repo = context.read<SupabaseRepository>();
      final notifications = await repo.getNotifications(
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );
      if (mounted) {
        setState(() {
          if (reset) {
            _notifications = notifications;
          } else {
            _notifications.addAll(notifications);
          }
          _currentPage += 1;
          _hasMore = notifications.length == _pageSize;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final repo = context.read<SupabaseRepository>();
      await repo.markAllNotificationsRead();
      await _loadNotifications(reset: true);
    } catch (e) {
      debugPrint('Error marking notifications as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          // Premium Header
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.premiumEmerald,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32.r),
                bottomRight: Radius.circular(32.r),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
                child: Column(
                  children: [
                    // Title Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'الإشعارات',
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        if (unreadCount > 0)
                          GestureDetector(
                            onTap: _markAllAsRead,
                            child: Container(
                              padding: EdgeInsets.all(10.w),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Icon(
                                Icons.done_all_rounded,
                                color: Colors.white,
                                size: 22.sp,
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 16.h),

                    // Stats Row
                    Row(
                      children: [
                        _buildStatChip(
                          '$unreadCount',
                          'غير مقروءة',
                          Icons.mark_email_unread_rounded,
                        ),
                        SizedBox(width: 12.w),
                        _buildStatChip(
                          '${_notifications.length}',
                          'الإجمالي',
                          Icons.notifications_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? Padding(
                    padding: EdgeInsets.all(16.w),
                    child: const CardShimmerSkeleton(itemCount: 5),
                  )
                : RefreshIndicator(
                    onRefresh: () => _loadNotifications(reset: true),
                    child: _notifications.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            controller: _scrollController,
                            padding: EdgeInsets.all(16.w),
                            itemCount:
                                _notifications.length +
                                (_isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (_isLoadingMore &&
                                  index == _notifications.length) {
                                return Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12.h),
                                  child: const Center(
                                    child: ShimmerListItem(),
                                  ),
                                );
                              }
                              return _buildNotificationCard(
                                _notifications[index],
                                index,
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String count, String label, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.onSurface, size: 18.sp),
          SizedBox(width: 8.w),
          Text(
            count,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          SizedBox(width: 4.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification, int index) {
    final color = _getTypeColor(notification.type);
    final icon = _getTypeIcon(notification.type);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: !notification.isRead
            ? Border.all(color: color.withValues(alpha: 0.5), width: 2)
            : Border.all(color: (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: notification.isRead ? 0.05 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: () {
            // Could navigate to related screen based on type
          },
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Container
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(icon, color: color, size: 24.sp),
                ),
                SizedBox(width: 12.w),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: notification.isRead
                                    ? FontWeight.w500
                                    : FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8.w,
                              height: 8.w,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        timeago.format(notification.createdAt, locale: 'ar'),
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey).withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 80).ms).slideX(begin: 0.05);
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'attendance':
        return Colors.green;
      case 'grade':
        return AppColors.warningAmber;
      case 'payment':
        return Theme.of(context).colorScheme.error;
      case 'assignment':
        return Colors.purple;
      case 'message':
        return AppColors.premiumEmerald.colors.first;
      case 'announcement':
        return AppColors.premiumSunset.colors.first;
      default:
        return (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey);
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'attendance':
        return Icons.how_to_reg_rounded;
      case 'grade':
        return Icons.emoji_events_rounded;
      case 'payment':
        return Icons.payment_rounded;
      case 'assignment':
        return Icons.assignment_rounded;
      case 'message':
        return Icons.message_rounded;
      case 'announcement':
        return Icons.campaign_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(32.w),
            decoration: BoxDecoration(
              color: AppColors.parentPrimary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_off_rounded,
              size: 64.sp,
              color: AppColors.parentPrimary,
            ),
          ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
          SizedBox(height: 24.h),
          Text(
            'لا توجد إشعارات',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ).animate().fadeIn(delay: 200.ms),
          SizedBox(height: 8.h),
          Text(
            'سنخبرك فور حدوث أي نشاط جديد لابنك',
            style: TextStyle(fontSize: 14.sp, color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey)),
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }
}
