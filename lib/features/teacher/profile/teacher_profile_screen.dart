import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:cached_network_image/cached_network_image.dart';

import '../../../core/config/app_colors.dart';
import '../../../shared/models/models.dart';
import '../../auth/provider/auth_provider.dart';
import '../provider/teacher_provider.dart';
import '../../../core/providers/center_provider.dart';
import '../../../core/widgets/genius/glass_card.dart';
import '../../../core/widgets/genius/genius_button.dart';

import '../../settings/presentation/screens/settings_screen.dart';
import '../../ai/screens/ai_assistant_screen.dart';

/// 🎨 Teacher Profile Screen - Forest Dark Edition
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
      return const Scaffold(
        backgroundColor: AppColors.forestDeep,
        body: Center(
          child: CircularProgressIndicator(
            backgroundColor: AppColors.accentVivid,
          ),
        ),
      );
    }

    final currentCenter = centerProvider.currentCenter;

    return Scaffold(
      backgroundColor: AppColors.forestDeep,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // HEADER
          SliverToBoxAdapter(child: _buildHeader(user, teacher)),

          // STATS CARDS
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            sliver: SliverToBoxAdapter(
              child: _buildStatsCards(teacherProvider, centerProvider),
            ),
          ),

          // CENTER CARD
          if (currentCenter != null)
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              sliver: SliverToBoxAdapter(
                child: _buildCenterCard(currentCenter),
              ),
            ),

          // ACTIONS
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            sliver: SliverToBoxAdapter(
              child: _buildActionsSection(context, user, teacher, authProvider),
            ),
          ),

          SliverToBoxAdapter(child: SizedBox(height: 100.h)),
        ],
      ),
    );
  }

  Widget _buildHeader(UserModel user, TeacherModel? teacher) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: const BoxDecoration(
        color: AppColors.forestPrimary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: const SizedBox.shrink(),
          ),
          Padding(
            padding: EdgeInsets.all(24.w).copyWith(bottom: 40.h),
            child: Column(
              children: [
                SizedBox(height: 20.h),
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.accentVivid.withValues(alpha: 0.5),
                      width: 3,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 52.r,
                    backgroundColor: AppColors.darkSurface,
                    child: user.avatarUrl != null
                        ? ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: user.avatarUrl!,
                              width: 104.r,
                              height: 104.r,
                              fit: BoxFit.cover,
                              memCacheWidth: 208,
                              memCacheHeight: 208,
                              errorWidget: (_, __, ___) => Icon(
                                Icons.person,
                                color: AppColors.textMuted,
                                size: 48.sp,
                              ),
                            ),
                          )
                        : Text(
                            _getInitials(user.fullName),
                            style: TextStyle(
                              fontSize: 36.sp,
                              color: AppColors.textDisplay,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),
                SizedBox(height: 16.h),

                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.fullName,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDisplay,
                          ),
                    ).animate().fadeIn().slideY(begin: 0.2),
                    SizedBox(width: 8.w),
                    Icon(
                      Icons.verified,
                      color: AppColors.emeraldGreen,
                      size: 24.sp,
                    ).animate().fadeIn(delay: 200.ms).scale(),
                  ],
                ),
                SizedBox(height: 6.h),

                Text(
                  'كود الدعوة: ${user.email?.replaceAll('@edsentre.com', '') ?? ''}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
                ).animate().fadeIn(delay: 250.ms),
                SizedBox(height: 4.h),
                Text(
                  'الهاتف: ${user.phone ?? "غير محدد"}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
                ).animate().fadeIn(delay: 250.ms),
                SizedBox(height: 12.h),

                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentVivid.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(
                      color: AppColors.accentVivid.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.school_rounded,
                        color: AppColors.accentVivid,
                        size: 16.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'معلم ومرشد',
                        style: TextStyle(
                          color: AppColors.accentVivid,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms),
              ],
            ),
          ),
        ],
      ),
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
    return Transform.translate(
      offset: Offset(0, -20.h),
      child: GlassCard(
        color: AppColors.darkSurface.withValues(alpha: 0.9),
        padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              icon: Icons.people_rounded,
              value: '${teacherProvider.totalUniqueStudents}',
              label: 'طالب',
              color: AppColors.infoPurple,
            ),
            _buildStatDivider(),
            _buildStatItem(
              icon: Icons.groups_rounded,
              value: '${teacherProvider.totalActiveGroups}',
              label: 'مجموعة',
              color: AppColors.emeraldGreen,
            ),
            _buildStatDivider(),
            _buildStatItem(
              icon: Icons.business_rounded,
              value: '${centerProvider.availableCenters.length}',
              label: 'سنتر',
              color: AppColors.accentVivid,
            ),
          ],
        ),
      ).animate().fadeIn().slideY(begin: 0.2),
    );
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
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(icon, color: color, size: 24.sp),
          ),
          SizedBox(height: 10.h),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.textDisplay,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 50.h,
      width: 1,
      color: AppColors.glassBorderHighlight,
    );
  }

  Widget _buildCenterCard(dynamic center) {
    return GlassCard(
      color: AppColors.forestPrimary.withValues(alpha: 0.6),
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: AppColors.accentVivid.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(
              Icons.business_rounded,
              color: AppColors.accentVivid,
              size: 28.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'السنتر الحالي',
                  style: Theme.of(
                    context,
                  ).textTheme.labelSmall?.copyWith(color: AppColors.textMuted),
                ),
                SizedBox(height: 4.h),
                Text(
                  center.name ?? 'غير محدد',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: AppColors.textMuted,
            size: 18.sp,
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1);
  }

  Widget _buildActionsSection(
    BuildContext context,
    UserModel user,
    TeacherModel? teacher,
    AuthProvider authProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: 8.h),
        Text(
          'الإعدادات',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textDisplay,
          ),
        ),
        SizedBox(height: 16.h),
        GlassCard(
          color: AppColors.forestPrimary.withValues(alpha: 0.4),
          padding: EdgeInsets.all(12.w),
          child: Column(
            children: [
              _buildActionTile(
                icon: Icons.person_outline_rounded,
                title: 'تعديل الملف الشخصي',
                subtitle: 'تحديث البيانات والصورة',
                color: AppColors.accentVivid,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
              _buildDivider(),
              _buildActionTile(
                icon: Icons.auto_awesome,
                title: 'المولد الذكي للامتحانات',
                subtitle: 'المساعد الذكي للمعلم',
                color: AppColors.infoPurple,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AIAssistantScreen()),
                ),
              ),
              _buildDivider(),
              _buildActionTile(
                icon: Icons.qr_code_2_rounded,
                title: 'بطاقة المعلم',
                subtitle: 'عرض QR code للتحقق',
                color: AppColors.emeraldGreen,
                onTap: () => _showQRDialog(context, user, teacher),
              ),
              _buildDivider(),
              _buildActionTile(
                icon: Icons.dark_mode_rounded,
                title: 'الوضع الليلي',
                subtitle: 'Forest Dark مفعل بصفة دائمة',
                color: AppColors.textDisplay,
                trailing: Switch(
                  value: true,
                  activeColor: AppColors.accentVivid,
                  activeTrackColor: AppColors.accentVivid.withValues(
                    alpha: 0.3,
                  ),
                  onChanged: null,
                ),
              ),
              _buildDivider(),
              _buildActionTile(
                icon: Icons.logout_rounded,
                title: 'تسجيل الخروج',
                subtitle: 'الخروج من الحساب',
                color: AppColors.errorRed,
                isDestructive: true,
                onTap: () => _showLogoutDialog(context, authProvider),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
    Widget? trailing,
    bool isDestructive = false,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
      leading: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(icon, color: color, size: 22.sp),
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: isDestructive ? AppColors.errorRed : AppColors.textDisplay,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: AppColors.textMuted),
      ),
      trailing:
          trailing ??
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16.sp,
            color: AppColors.textMuted,
          ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 60.w,
      color: AppColors.glassBorderHighlight,
    );
  }

  void _showQRDialog(
    BuildContext context,
    UserModel user,
    TeacherModel? teacher,
  ) {
    final data = teacher?.id ?? user.id;
    final name = teacher?.displayName ?? user.fullName;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          border: Border(
            top: BorderSide(color: AppColors.glassBorderHighlight),
          ),
        ),
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: AppColors.textMuted.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(height: 24.h),
            Icon(
              Icons.qr_code_rounded,
              size: 48.sp,
              color: AppColors.accentVivid,
            ),
            SizedBox(height: 16.h),
            Text(
              'بطاقة المعلم',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            SizedBox(height: 4.h),
            Text(
              'امسح الكود للتحقق من الهوية',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
            ),
            SizedBox(height: 24.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: QrImageView(
                data: data,
                version: QrVersions.auto,
                size: 180.w,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.forestDeep,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.forestDeep,
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              name,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 32.h),
            SizedBox(
              width: double.infinity,
              child: GeniusButton(
                label: 'إغلاق',
                onPressed: () => Navigator.pop(context),
                variant: GeniusButtonVariant.glass,
              ),
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          color: AppColors.darkSurface.withValues(alpha: 0.9),
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: AppColors.errorRed,
                  size: 32.sp,
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'تسجيل الخروج',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10.h),
              Text(
                'هل أنت متأكد من تسجيل الخروج؟',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
              ),
              SizedBox(height: 28.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        side: BorderSide(color: AppColors.glassBorderHighlight),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      child: Text(
                        'إلغاء',
                        style: TextStyle(
                          color: AppColors.textDisplay,
                          fontSize: 16.sp,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await authProvider.signOut();
                        if (context.mounted) context.go('/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.errorRed,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      child: Text(
                        'خروج',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
