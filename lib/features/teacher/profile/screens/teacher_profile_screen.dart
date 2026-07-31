import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/config/app_colors.dart';
import '../../../../shared/models/models.dart';
import '../../../auth/provider/auth_provider.dart';
import '../../provider/teacher_provider.dart';
import '../../../../core/providers/center_provider.dart';

import '../../../settings/presentation/screens/settings_screen.dart';
import '../../../ai/screens/ai_assistant_screen.dart';

/// 🎨 Teacher Profile Screen - Modern Academic Overhaul
class TeacherProfileScreen extends StatefulWidget {
  const TeacherProfileScreen({super.key});

  @override
  State<TeacherProfileScreen> createState() => _TeacherProfileScreenState();
}

class _TeacherProfileScreenState extends State<TeacherProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;
    final teacher = authProvider.teacherProfile;
    final teacherProvider = context.watch<TeacherProvider>();
    final centerProvider = context.watch<CenterProvider>();

    if (user == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final currentCenter = centerProvider.currentCenter;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'الملف الشخصي',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20.sp,
          ),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        child: Column(
          children: [
            // 1. Clean Profile Card
            _buildProfileCard(user, teacher, currentCenter),
            SizedBox(height: 20.h),

            // 2. Stats Section
            _buildStatsCards(teacherProvider, centerProvider),
            SizedBox(height: 20.h),

            // 3. Actions Section
            _buildActionsSection(context, authProvider),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(UserModel user, TeacherModel? teacher, dynamic currentCenter) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).dividerTheme.color ?? AppColors.gray100,
        ),
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).colorScheme.primary,
                width: 2.5,
              ),
            ),
            child: CircleAvatar(
              radius: 46.r,
              backgroundColor: AppColors.gray100,
              child: user.avatarUrl != null
                  ? ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: user.avatarUrl!,
                        width: 92.r,
                        height: 92.r,
                        fit: BoxFit.cover,
                        memCacheWidth: 184,
                        memCacheHeight: 184,
                        errorWidget: (_, __, ___) => Icon(
                          Icons.person,
                          color: AppColors.gray500,
                          size: 40.sp,
                        ),
                      ),
                    )
                  : Text(
                      _getInitials(user.fullName),
                      style: TextStyle(
                        fontSize: 28.sp,
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
          SizedBox(height: 16.h),

          // Name
          Text(
            user.fullName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 20.sp,
                ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),

          // Role Badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              'معلم ومرشد',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          const Divider(),
          SizedBox(height: 12.h),

          // Details List
          _buildDetailRow(Icons.phone_iphone_rounded, 'الهاتف', user.phone ?? 'غير محدد'),
          if (currentCenter != null) ...[
            SizedBox(height: 10.h),
            _buildDetailRow(Icons.business_rounded, 'السنتر الحالي', currentCenter.name ?? 'غير محدد'),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.gray500, size: 20.sp),
        SizedBox(width: 12.w),
        Text(
          '$label:',
          style: TextStyle(
            color: AppColors.gray500,
            fontSize: 14.sp,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14.sp,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return 'م';
    final parts = name.split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}';
    return name[0];
  }

  Widget _buildStatsCards(
    TeacherProvider teacherProvider,
    CenterProvider centerProvider,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 10.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).dividerTheme.color ?? AppColors.gray100,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.people_outline_rounded,
            value: '${teacherProvider.statsTotalStudents}',
            label: 'طالب',
            color: AppColors.electric,
          ),
          _buildStatDivider(),
          _buildStatItem(
            icon: Icons.class_outlined,
            value: '${teacherProvider.dashboardStats['groups_count'] ?? teacherProvider.totalActiveGroups}',
            label: 'مجموعة',
            color: AppColors.teal,
          ),
          _buildStatDivider(),
          _buildStatItem(
            icon: Icons.business_outlined,
            value: '${centerProvider.availableCenters.length}',
            label: 'سنتر',
            color: AppColors.gold,
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 24.sp),
          SizedBox(height: 6.h),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.gray500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 35.h,
      width: 1,
      color: Theme.of(context).dividerTheme.color ?? AppColors.gray100,
    );
  }

  Widget _buildActionsSection(BuildContext context, AuthProvider authProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).dividerTheme.color ?? AppColors.gray100,
        ),
      ),
      child: Column(
        children: [
          // Edit Profile Action
          _buildActionTile(
            icon: Icons.manage_accounts_outlined,
            title: 'تعديل الملف الشخصي',
            subtitle: 'تحديث بيانات الحساب الشخصي',
            color: Theme.of(context).colorScheme.primary,
            onTap: () {
              // Push setting screen using rootNavigator: true to cover bottom nav bar
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
          _buildDivider(),

          // AI Generator Action
          _buildActionTile(
            icon: Icons.psychology_outlined,
            title: 'المولد الذكي للامتحانات',
            subtitle: 'توليد الأسئلة والاختبارات بالذكاء الاصطناعي',
            color: AppColors.teal,
            onTap: () {
              // Push setting screen using rootNavigator: true to cover bottom nav bar
              Navigator.of(context, rootNavigator: true).push(
                MaterialPageRoute(builder: (_) => const AIAssistantScreen()),
              );
            },
          ),
          _buildDivider(),

          // Logout Action
          _buildActionTile(
            icon: Icons.logout_rounded,
            title: 'تسجيل الخروج',
            subtitle: 'الخروج من الحساب والعودة للدخول',
            color: Theme.of(context).colorScheme.error,
            isDestructive: true,
            onTap: () => _showLogoutDialog(context, authProvider),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      leading: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(icon, color: color, size: 22.sp),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15.sp,
          color: isDestructive ? Theme.of(context).colorScheme.error : Theme.of(context).colorScheme.onSurface,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 11.sp,
          color: AppColors.gray500,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        size: 14.sp,
        color: AppColors.gray300,
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 64.w,
      endIndent: 16.w,
      color: Theme.of(context).dividerTheme.color ?? AppColors.gray100,
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(ctx).colorScheme.surface,
        title: const Text('تسجيل الخروج', textAlign: TextAlign.center),
        content: const Text(
          'هل أنت متأكد من رغبتك في تسجيل الخروج من حسابك؟',
          textAlign: TextAlign.center,
        ),
        actionsPadding: EdgeInsets.all(16.w),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  child: const Text('إلغاء'),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(ctx).colorScheme.error,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                  ),
                  child: const Text('خروج'),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await authProvider.signOut();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }
}
