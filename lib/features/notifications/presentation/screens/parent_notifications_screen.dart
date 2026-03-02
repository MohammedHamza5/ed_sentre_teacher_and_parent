import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/config/app_colors.dart';
import '../../../../../shared/data/supabase_repository.dart';
import '../../../../../shared/models/models.dart';
import '../../../../../shared/models/notification_model.dart';

class ParentNotificationsScreen extends StatefulWidget {
  const ParentNotificationsScreen({super.key});

  @override
  State<ParentNotificationsScreen> createState() => _ParentNotificationsScreenState();
}

class _ParentNotificationsScreenState extends State<ParentNotificationsScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
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
    if (position.pixels >= position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    setState(() => _isLoadingMore = true);
    await _loadNotifications();
  }

  Future<void> _loadNotifications({bool reset = false}) async {
    try {
      if (reset) {
        setState(() {
          _isLoading = true;
          _currentPage = 0;
          _hasMore = true;
          _notifications = [];
        });
      }
      final repo = context.read<SupabaseRepository>();
      final data = await repo.getNotifications(
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );
      if (mounted) {
        setState(() {
          if (reset) {
            _notifications = data;
          } else {
            _notifications.addAll(data);
          }
          _currentPage += 1;
          _hasMore = data.length == _pageSize;
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isLoadingMore = false;
        });
      }
      debugPrint('Error loading notifications: $e');
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (notification.isRead) return;

    try {
      final repo = context.read<SupabaseRepository>();
      await repo.markNotificationRead(notification.id);
      
      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notification.id);
        if (index != -1) {
          _notifications[index] = _notifications[index].copyWith(isRead: true);
        }
      });
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  Future<void> _markAllRead() async {
    try {
      final repo = context.read<SupabaseRepository>();
      await repo.markAllNotificationsRead();
      setState(() {
        _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('فشل تحديد الكل كمقروء')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الإشعارات', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          if (_notifications.any((n) => !n.isRead))
            IconButton(
              icon: const Icon(Icons.done_all, color: AppColors.primary),
              tooltip: 'تحديد الكل كمقروء',
              onPressed: _markAllRead,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () => _loadNotifications(reset: true),
                  child: ListView.separated(
                    controller: _scrollController,
                    padding: EdgeInsets.all(16.w),
                    itemCount:
                        _notifications.length + (_isLoadingMore ? 1 : 0),
                    separatorBuilder: (c, i) => SizedBox(height: 12.h),
                    itemBuilder: (context, index) {
                      if (_isLoadingMore && index == _notifications.length) {
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.h),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          ),
                        );
                      }
                      final notification = _notifications[index];
                      return _buildNotificationCard(notification)
                          .animate()
                          .fadeIn(delay: 50.ms * index)
                          .slideX(begin: 0.2, curve: Curves.easeOut);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.notifications_off_outlined, size: 48.sp, color: AppColors.primary),
          ),
          SizedBox(height: 16.h),
          Text(
            'لا توجد إشعارات حالياً',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          SizedBox(height: 8.h),
          Text(
            'سنخبرك فوراً عند وجود غياب أو درجات جديدة',
            style: TextStyle(fontSize: 14.sp, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    // Custom icon logic for parents
    IconData iconData = Icons.notifications;
    Color iconColor = AppColors.primary;

    if (notification.type == 'attendance') {
      if (notification.body.contains('غياب')) {
        iconData = Icons.cancel;
        iconColor = AppColors.error;
      } else {
        iconData = Icons.check_circle;
        iconColor = AppColors.success;
      }
    } else if (notification.type == 'payment') {
      iconData = Icons.payment;
      iconColor = AppColors.secondary;
    } else if (notification.type == 'assignment') {
      iconData = Icons.school;
      iconColor = AppColors.accent;
    }

    return GestureDetector(
      onTap: () async {
         await _markAsRead(notification);
      },
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : AppColors.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16.r),
          border: notification.isRead 
              ? Border.all(color: AppColors.gray200)
              : Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: notification.isRead ? AppColors.gray100 : Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                iconData,
                color: notification.isRead ? AppColors.textSecondary : iconColor,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 16.w),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (!notification.isRead)
                        Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    timeago.format(notification.createdAt, locale: 'ar'),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textHint,
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
}
