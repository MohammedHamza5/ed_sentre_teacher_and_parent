import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../auth/provider/auth_provider.dart';
import '../provider/parent_provider.dart';

import '../../../core/config/app_colors.dart';
import '../../../core/widgets/genius/glass_card.dart';
import '../../../core/widgets/genius/genius_button.dart';

/// 🎨 Parent Profile Screen - Forest Dark Edition
class ParentProfileScreen extends StatelessWidget {
  const ParentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final parentProvider = context.watch<ParentProvider>();
    final user = authProvider.currentUser;

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

    return Scaffold(
      backgroundColor: AppColors.forestDeep,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            _buildHeader(context, user, parentProvider),

            SizedBox(height: 16.h),

            // Menu Sections
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle(context, 'الحساب'),
                  _buildMenuSection(context, [
                    _MenuItem(
                      icon: Icons.person_outline_rounded,
                      iconColor: AppColors.accentVivid,
                      title: 'تعديل الملف الشخصي',
                      onTap: () => _showComingSoon(context),
                    ),
                    _buildDivider(),
                    _MenuItem(
                      icon: Icons.lock_outline_rounded,
                      iconColor: AppColors.infoPurple,
                      title: 'تغيير كلمة المرور',
                      onTap: () => _showComingSoon(context),
                    ),
                  ]).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

                  SizedBox(height: 24.h),

                  _buildSectionTitle(context, 'الإعدادات'),
                  _buildMenuSection(context, [
                    _MenuItem(
                      icon: Icons.notifications_outlined,
                      iconColor: AppColors.warningAmber,
                      title: 'إعدادات الإشعارات',
                      onTap: () => _showComingSoon(context),
                    ),
                    _buildDivider(),
                    _MenuItem(
                      icon: Icons.dark_mode_rounded,
                      iconColor: AppColors.textDisplay,
                      title: 'الوضع الليلي',
                      trailing: 'مفعّل',
                      onTap: () {},
                    ),
                    _buildDivider(),
                    _MenuItem(
                      icon: Icons.language_rounded,
                      iconColor: AppColors.emeraldGreen,
                      title: 'اللغة',
                      trailing: 'العربية',
                      onTap: () {},
                    ),
                  ]).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                  SizedBox(height: 24.h),

                  _buildSectionTitle(context, 'المساعدة'),
                  _buildMenuSection(context, [
                    _MenuItem(
                      icon: Icons.support_agent_rounded,
                      iconColor: AppColors.accentVivid,
                      title: 'التواصل مع الدعم',
                      onTap: () => _showComingSoon(context),
                    ),
                    _buildDivider(),
                    _MenuItem(
                      icon: Icons.help_outline_rounded,
                      iconColor: AppColors.emeraldGreen,
                      title: 'الأسئلة الشائعة',
                      onTap: () => _showComingSoon(context),
                    ),
                    _buildDivider(),
                    _MenuItem(
                      icon: Icons.info_outline_rounded,
                      iconColor: AppColors.textDisplay,
                      title: 'عن التطبيق',
                      trailing: 'v1.0.0',
                      onTap: () => _showAboutDialog(context),
                    ),
                  ]).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

                  SizedBox(height: 32.h),

                  SizedBox(
                    width: double.infinity,
                    child: GeniusButton(
                      label: 'تسجيل الخروج',
                      variant: GeniusButtonVariant.glass,
                      onPressed: () => _showLogoutConfirmation(
                        context,
                        authProvider,
                        parentProvider,
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

                  SizedBox(height: 100.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    user,
    ParentProvider parentProvider,
  ) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.forestPrimary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 32.h),
          child: Column(
            children: [
              Text(
                'حسابي',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDisplay,
                ),
              ),
              SizedBox(height: 24.h),

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
                  radius: 50.r,
                  backgroundColor: AppColors.darkSurface,
                  child: user?.avatarUrl != null
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: user!.avatarUrl!,
                            width: 96.w,
                            height: 96.w,
                            fit: BoxFit.cover,
                            errorWidget: (_, __, ___) => Icon(
                              Icons.person_rounded,
                              size: 48.sp,
                              color: AppColors.textMuted,
                            ),
                          ),
                        )
                      : Text(
                          user?.fullName?.isNotEmpty == true
                              ? user!.fullName![0]
                              : 'أ',
                          style: TextStyle(
                            fontSize: 36.sp,
                            color: AppColors.textDisplay,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ).animate().fadeIn().scale(),
              SizedBox(height: 16.h),

              Text(
                user?.fullName ?? 'ولي الأمر',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ).animate().fadeIn().slideY(begin: 0.1),
              SizedBox(height: 4.h),

              Text(
                'كود الدعوة: ${user?.email?.replaceAll('@edsentre.com', '') ?? ''}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
              ).animate().fadeIn(delay: 100.ms),
              SizedBox(height: 4.h),
              Text(
                'الهاتف: ${user?.phone ?? "غير محدد"}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
              ).animate().fadeIn(delay: 150.ms),
              SizedBox(height: 16.h),

              Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: AppColors.emeraldGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(
                    color: AppColors.emeraldGreen.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.family_restroom_rounded,
                      size: 20.sp,
                      color: AppColors.emeraldGreen,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      '${parentProvider.children.length} أبناء مسجلين',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: AppColors.emeraldGreen,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms).scale(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h, right: 4.w),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: AppColors.textMuted,
          fontWeight: FontWeight.bold,
        ),
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

  Widget _buildMenuSection(BuildContext context, List<Widget> children) {
    return GlassCard(
      color: AppColors.forestPrimary.withValues(alpha: 0.4),
      padding: EdgeInsets.zero,
      child: Column(children: children),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'قريباً إن شاء الله 🚀',
          style: TextStyle(
            color: AppColors.forestDeep,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: AppColors.accentVivid,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          color: AppColors.darkSurface.withValues(alpha: 0.9),
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: AppColors.accentVivid.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(
                      Icons.school_rounded,
                      color: AppColors.accentVivid,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 12.w),
                  Text(
                    'EdSentre',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              Text(
                'تطبيق EdSentre لأولياء الأمور',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 8.h),
              Text(
                'الإصدار: 1.0.0',
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppColors.textMuted),
              ),
              SizedBox(height: 16.h),
              Text(
                'متابعة أبنائك في المراكز التعليمية بسهولة وتصميم عصري يعزز التجربة المميزة.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: GeniusButton(
                  label: 'حسناً',
                  onPressed: () => Navigator.pop(context),
                  variant: GeniusButtonVariant.glass,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutConfirmation(
    BuildContext context,
    AuthProvider authProvider,
    ParentProvider parentProvider,
  ) {
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
                        parentProvider.clearSelection();
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

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? trailing;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.trailing,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      leading: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: iconColor.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(icon, color: iconColor, size: 22.sp),
      ),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(
              trailing!,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: AppColors.textMuted),
            ),
          SizedBox(width: 8.w),
          Icon(
            Icons.chevron_left_rounded,
            color: AppColors.textMuted,
            size: 20.sp,
          ),
        ],
      ),
    );
  }
}
