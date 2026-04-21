import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../../core/config/app_colors.dart';
import '../../provider/parent_provider.dart';
import '../../../../shared/data/supabase_repository.dart';
import '../../../../shared/models/models.dart';

/// Parent Messages Screen - Chat list with teachers
class ParentMessagesScreen extends StatefulWidget {
  const ParentMessagesScreen({super.key});

  @override
  State<ParentMessagesScreen> createState() => _ParentMessagesScreenState();
}

class _ParentMessagesScreenState extends State<ParentMessagesScreen> {
  bool _isLoading = true;
  List<ConversationModel> _conversations = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final parentProvider = context.read<ParentProvider>();
      final centerId = parentProvider.selectedCenterId;

      if (centerId == null) {
        setState(() {
          _isLoading = false;
          _error = 'لم يتم تحديد سنتر';
        });
        return;
      }

      final repo = context.read<SupabaseRepository>();
      final data = await repo.getParentConversations(centerId: centerId);

      if (mounted) {
        setState(() {
          _conversations = data;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.forestDeep,
      appBar: AppBar(
        title: const Text('الرسائل'),
        backgroundColor: AppColors.forestPrimary,
        foregroundColor: AppColors.textDisplay,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadConversations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accentVivid))
          : _error != null
          ? _buildErrorState()
          : _conversations.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadConversations,
              color: AppColors.accentVivid,
              backgroundColor: AppColors.darkSurface,
              child: ListView.separated(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                itemCount: _conversations.length,
                separatorBuilder: (context, index) =>
                    Divider(height: 1, color: AppColors.darkBorder),
                itemBuilder: (context, index) {
                  return _buildConversationTile(_conversations[index]);
                },
              ),
            ),
    );
  }

  Widget _buildConversationTile(ConversationModel conversation) {
    final hasUnread = conversation.unreadCountStudent > 0;

    return ListTile(
      onTap: () {
        // TODO: Navigate to chat screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('سيتم فتح المحادثة قريباً')),
        );
      },
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      leading: Stack(
        children: [
          CircleAvatar(
            radius: 28.r,
            backgroundColor: AppColors.premiumOcean.colors.first.withValues(alpha: 0.1),
            child: Icon(Icons.person, color: AppColors.premiumOcean.colors.first, size: 28.sp),
          ),
          // Unread Indicator
          if (hasUnread)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: AppColors.errorRed,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.darkSurface, width: 2),
                ),
                child: Text(
                  '${conversation.unreadCountStudent}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      title: Text(
        conversation.teacherName ?? 'معلم',
        style: TextStyle(
          fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
          fontSize: 16.sp,
          color: AppColors.textDisplay,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 4.h),
          Text(
            conversation.lastMessage ?? 'ابدأ المحادثة',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: hasUnread
                  ? AppColors.textDisplay
                  : AppColors.textMuted,
              fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (conversation.lastMessageAt != null)
            Text(
              _formatDate(conversation.lastMessageAt!),
              style: TextStyle(
                fontSize: 12.sp,
                color: hasUnread ? AppColors.accentVivid : AppColors.textMuted.withValues(alpha: 0.5),
                fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          SizedBox(height: 4.h),
          Icon(Icons.chevron_left, color: AppColors.textMuted.withValues(alpha: 0.5), size: 20.sp),
        ],
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
              color: AppColors.premiumOcean.colors.first.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 64.sp,
              color: AppColors.premiumOcean.colors.first.withValues(alpha: 0.5),
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'لا توجد رسائل',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textDisplay,
            ),
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 48.w),
            child: Text(
              'ستظهر المحادثات مع المعلمين هنا عند بدئها',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64.sp, color: AppColors.errorRed),
          SizedBox(height: 16.h),
          Text(
            'حدث خطأ',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textDisplay,
            ),
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Text(
              _error ?? 'خطأ غير معروف',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, color: AppColors.textMuted),
            ),
          ),
          SizedBox(height: 24.h),
          ElevatedButton.icon(
            onPressed: _loadConversations,
            icon: const Icon(Icons.refresh),
            label: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return DateFormat('hh:mm a').format(date);
    } else if (diff.inDays == 1) {
      return 'أمس';
    } else if (diff.inDays < 7) {
      return DateFormat('EEEE', 'ar').format(date);
    } else {
      return DateFormat('d/M').format(date);
    }
  }
}
