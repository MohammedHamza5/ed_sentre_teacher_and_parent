import 'package:flutter/material.dart';
import '../../../shared/widgets/app_drawer.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/config/app_colors.dart';
import '../../../shared/models/models.dart';
import '../../auth/provider/auth_provider.dart';
import '../provider/teacher_provider.dart';
import '../../../core/providers/center_provider.dart';
import '../../../shared/widgets/premium_widgets.dart';
import '../../../shared/widgets/premium_plus_widgets.dart';
import '../../settings/presentation/screens/settings_screen.dart';

/// 🎨 Teacher Profile Screen - Premium Dark Mode Design
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final currentCenter = centerProvider.currentCenter;

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ═══════════════════════════════════════════════════════════
          // HEADER
          // ═══════════════════════════════════════════════════════════
          SliverToBoxAdapter(child: _buildHeader(user, teacher)),

          // ═══════════════════════════════════════════════════════════
          // STATS CARDS
          // ═══════════════════════════════════════════════════════════
          SliverPadding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            sliver: SliverToBoxAdapter(
              child: _buildStatsCards(teacherProvider, centerProvider),
            ),
          ),

          // ═══════════════════════════════════════════════════════════
          // CENTER CARD
          // ═══════════════════════════════════════════════════════════
          if (currentCenter != null)
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
              sliver: SliverToBoxAdapter(
                child: _buildCenterCard(currentCenter),
              ),
            ),

          // ═══════════════════════════════════════════════════════════
          // ACTIONS
          // ═══════════════════════════════════════════════════════════
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

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildHeader(UserModel user, TeacherModel? teacher) {
    return Container(
      padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: Stack(
        children: [
          // Drawer menu button (top-left)
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            child: DrawerMenuButton(isTeacher: true),
          ),
          // Decorative circles
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            left: -40,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),

          // Content
          Padding(
            padding: EdgeInsets.all(24.w).copyWith(bottom: 40.h),
            child: Column(
              children: [
                SizedBox(height: 20.h),
                // Avatar
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.4),
                        Colors.white.withValues(alpha: 0.1),
                      ],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 52.r,
                    backgroundColor: AppColors.darkCard,
                    backgroundImage: user.avatarUrl != null
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                    child: user.avatarUrl == null
                        ? Text(
                            _getInitials(user.fullName),
                            style: TextStyle(
                              fontSize: 36.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),
                SizedBox(height: 16.h),

                // Name with Badge
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.fullName ?? 'المعلم',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn().slideY(begin: 0.2),
                    SizedBox(width: 8.w),
                    Container(
                      padding: EdgeInsets.all(5.w),
                      decoration: BoxDecoration(
                        color: AppColors.warning,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.warning.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.verified,
                        color: Colors.white,
                        size: 14.sp,
                      ),
                    ).animate().fadeIn(delay: 200.ms).scale(),
                  ],
                ),
                SizedBox(height: 12.h),

                // Role Badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(24.r),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.school_rounded,
                        color: Colors.white,
                        size: 16.sp,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'معلم ومرشد',
                        style: TextStyle(
                          color: Colors.white,
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

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}';
    }
    return name.isNotEmpty ? name[0] : 'م';
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATS CARDS
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStatsCards(
    TeacherProvider teacherProvider,
    CenterProvider centerProvider,
  ) {
    return Transform.translate(
      offset: Offset(0, -30.h),
      child: GlassMorphismCard(
        padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
        hasNeonBorder: true,
        neonColor: AppColors.primary,
        blurStrength: 20,
        borderRadius: 24.r,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              icon: Icons.people_rounded,
              value: '${teacherProvider.totalUniqueStudents}',
              label: 'طالب',
              gradient: AppColors.premiumOcean,
            ),
            _buildStatDivider(),
            _buildStatItem(
              icon: Icons.groups_rounded,
              value: '${teacherProvider.totalActiveGroups}',
              label: 'مجموعة',
              gradient: AppColors.premiumEmerald,
            ),
            _buildStatDivider(),
            _buildStatItem(
              icon: Icons.business_rounded,
              value: '${centerProvider.availableCenters.length}',
              label: 'سنتر',
              gradient: AppColors.premiumRoyal,
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
    required Gradient gradient,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(14.r),
              boxShadow: [
                BoxShadow(
                  color: (gradient as LinearGradient).colors.first.withOpacity(
                    0.3,
                  ),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 24.sp),
          ),
          SizedBox(height: 10.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: AppColors.textOnDark,
              fontFamily: 'Cairo',
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.textOnDarkSecondary,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatDivider() {
    return Container(
      height: 50.h,
      width: 1,
      color: AppColors.darkBorder.withValues(alpha: 0.5),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CENTER CARD
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCenterCard(dynamic center) {
    return GlassMorphismCard(
      gradient: AppColors.premiumOcean,
      hasNeonBorder: true,
      neonColor: AppColors.info,
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(
              Icons.business_rounded,
              color: Colors.white,
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
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13.sp,
                    fontFamily: 'Cairo',
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  center.name ?? 'غير محدد',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: Colors.white54,
            size: 18.sp,
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTIONS SECTION
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildActionsSection(
    BuildContext context,
    UserModel user,
    TeacherModel? teacher,
    AuthProvider authProvider,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PremiumSectionHeader(
          title: 'الإعدادات',
          icon: Icons.settings_rounded,
          subtitle: 'تخصيص تجربتك',
          titleGradient: AppColors.premiumRoyal,
        ),
        SizedBox(height: 12.h),
        GlassMorphismCard(
          padding: EdgeInsets.all(12.w),
          child: Column(
            children: [
              _buildActionTile(
                icon: Icons.person_outline_rounded,
                title: 'تعديل الملف الشخصي',
                subtitle: 'تحديث البيانات والصورة',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
              _buildDivider(),
              _buildActionTile(
                icon: Icons.qr_code_2_rounded,
                title: 'بطاقة المعلم',
                subtitle: 'عرض QR code للتحقق',
                onTap: () => _showQRDialog(context, user, teacher),
              ),
              _buildDivider(),
              _buildActionTile(
                icon: Icons.dark_mode_rounded,
                title: 'الوضع الليلي',
                subtitle: 'مفعّل حالياً',
                trailing: Switch(
                  value: true,
                  activeColor: AppColors.primary,
                  onChanged: (_) {},
                ),
              ),
              _buildDivider(),
              _buildActionTile(
                icon: Icons.logout_rounded,
                title: 'تسجيل الخروج',
                subtitle: 'الخروج من الحساب',
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
    VoidCallback? onTap,
    Widget? trailing,
    bool isDestructive = false,
  }) {
    final color = isDestructive ? AppColors.error : AppColors.textOnDark;
    final iconBg = isDestructive ? AppColors.errorSoft : AppColors.primarySoft;
    final iconColor = isDestructive ? AppColors.error : AppColors.primary;

    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
      leading: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(icon, color: iconColor, size: 22.sp),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12.sp, color: AppColors.textOnDarkSecondary),
      ),
      trailing:
          trailing ??
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16.sp,
            color: AppColors.textOnDarkHint,
          ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 60.w,
      color: AppColors.darkBorder.withValues(alpha: 0.5),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // DIALOGS
  // ═══════════════════════════════════════════════════════════════════════════

  void _showQRDialog(
    BuildContext context,
    UserModel user,
    TeacherModel? teacher,
  ) {
    final data = teacher?.id ?? user.id;
    final name = teacher?.displayName ?? user.fullName ?? 'المعلم';

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(28.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconContainer(
                icon: Icons.verified_user_rounded,
                gradient: AppColors.primaryGradient,
                size: 32.sp,
                padding: 14,
              ),
              SizedBox(height: 20.h),
              Text(
                'بطاقة المعلم',
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textOnDark,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                'امسح الكود للتحقق من الهوية',
                style: TextStyle(
                  fontSize: 13.sp,
                  color: AppColors.textOnDarkSecondary,
                ),
              ),
              SizedBox(height: 28.h),

              // QR Container
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
                    color: AppColors.primary,
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: AppColors.primary,
                  ),
                ),
              ),
              SizedBox(height: 20.h),

              Text(
                name,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textOnDark,
                ),
              ),
              SizedBox(height: 24.h),

              GradientButton(
                text: 'إغلاق',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Padding(
          padding: EdgeInsets.all(28.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: AppColors.errorSoft,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: AppColors.error,
                  size: 32.sp,
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'تسجيل الخروج',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textOnDark,
                ),
              ),
              SizedBox(height: 10.h),
              Text(
                'هل أنت متأكد من تسجيل الخروج؟',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textOnDarkSecondary,
                ),
              ),
              SizedBox(height: 28.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        side: BorderSide(color: AppColors.darkBorder),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      child: Text(
                        'إلغاء',
                        style: TextStyle(
                          color: AppColors.textOnDarkSecondary,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
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
                        backgroundColor: AppColors.error,
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                      ),
                      child: Text(
                        'خروج',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
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
