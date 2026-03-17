import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../auth/provider/auth_provider.dart';
import '../provider/parent_provider.dart';

/// Parent Profile Screen - Premium Design with real data
class ParentProfileScreen extends StatelessWidget {
  const ParentProfileScreen({super.key});

  // Premium colors
  static const _gradientStart = Color(0xFF667EEA);
  static const _gradientEnd = Color(0xFF764BA2);

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final parentProvider = context.watch<ParentProvider>();
    final user = authProvider.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Premium Gradient Header
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_gradientStart, _gradientEnd],
                ),
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
                      // Title
                      Text(
                        'حسابي',
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 24.h),

                      // Avatar
                      Stack(
                        children: [
                          Container(
                            padding: EdgeInsets.all(4.w),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.5),
                                width: 3,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 50.r,
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.2,
                              ),
                              child: user?.avatarUrl != null
                                  ? ClipOval(
                                      child: CachedNetworkImage(
                                        imageUrl: user!.avatarUrl!,
                                        width: 96.w,
                                        height: 96.w,
                                        fit: BoxFit.cover,
                                        memCacheWidth: 192,
                                        memCacheHeight: 192,
                                        errorWidget: (_, __, ___) => Icon(
                                          Icons.person_rounded,
                                          size: 48.sp,
                                          color: Colors.white,
                                        ),
                                      ),
                                    )
                                  : Icon(
                                      Icons.person_rounded,
                                      size: 48.sp,
                                      color: Colors.white,
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: EdgeInsets.all(8.w),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.camera_alt_rounded,
                                size: 18.sp,
                                color: _gradientStart,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),

                      // Name
                      Text(
                        user?.fullName ?? 'ولي الأمر',
                        style: TextStyle(
                          fontSize: 22.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4.h),

                      // Invitation Code
                      Text(
                        'كود الدعوة: ${user?.email?.replaceAll('@edsentre.com', '') ?? ''}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      SizedBox(height: 4.h),
                      // Phone
                      Text(
                        'الهاتف: ${user?.phone ?? "غير محدد"}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                      SizedBox(height: 16.h),

                      // Children Count Badge
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 10.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(24.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.school_rounded,
                              size: 20.sp,
                              color: Colors.white,
                            ),
                            SizedBox(width: 8.w),
                            Text(
                              '${parentProvider.children.length} أبناء مسجلين',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 400.ms),

            // Menu Sections
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Account Section
                  _buildSectionTitle('الحساب'),
                  _buildMenuCard([
                    _MenuItem(
                      icon: Icons.person_outline_rounded,
                      iconColor: const Color(0xFF6366F1),
                      title: 'تعديل الملف الشخصي',
                      onTap: () => _showComingSoon(context),
                    ),
                    _MenuItem(
                      icon: Icons.lock_outline_rounded,
                      iconColor: const Color(0xFF8B5CF6),
                      title: 'تغيير كلمة المرور',
                      onTap: () => _showComingSoon(context),
                    ),
                  ]).animate().fadeIn(delay: 100.ms).slideY(begin: 0.05),

                  SizedBox(height: 16.h),

                  // Settings Section
                  _buildSectionTitle('الإعدادات'),
                  _buildMenuCard([
                    _MenuItem(
                      icon: Icons.notifications_outlined,
                      iconColor: const Color(0xFFF59E0B),
                      title: 'إعدادات الإشعارات',
                      onTap: () => _showComingSoon(context),
                    ),
                    _MenuItem(
                      icon: Icons.language_rounded,
                      iconColor: const Color(0xFF10B981),
                      title: 'اللغة',
                      trailing: 'العربية',
                      onTap: () {},
                    ),
                  ]).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05),

                  SizedBox(height: 16.h),

                  // Support Section
                  _buildSectionTitle('المساعدة'),
                  _buildMenuCard([
                    _MenuItem(
                      icon: Icons.support_agent_rounded,
                      iconColor: const Color(0xFF3B82F6),
                      title: 'التواصل مع الدعم',
                      onTap: () => _showComingSoon(context),
                    ),
                    _MenuItem(
                      icon: Icons.help_outline_rounded,
                      iconColor: const Color(0xFF14B8A6),
                      title: 'الأسئلة الشائعة',
                      onTap: () => _showComingSoon(context),
                    ),
                    _MenuItem(
                      icon: Icons.info_outline_rounded,
                      iconColor: const Color(0xFF6B7280),
                      title: 'عن التطبيق',
                      trailing: 'v1.0.0',
                      onTap: () => _showAboutDialog(context),
                    ),
                  ]).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05),

                  SizedBox(height: 24.h),

                  // Logout Button
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16.r),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16.r),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16.r),
                        onTap: () => _showLogoutConfirmation(
                          context,
                          authProvider,
                          parentProvider,
                        ),
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 16.h),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.logout_rounded,
                                color: const Color(0xFFEF4444),
                                size: 22.sp,
                              ),
                              SizedBox(width: 8.w),
                              Text(
                                'تسجيل الخروج',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFEF4444),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 400.ms),

                  SizedBox(height: 32.h),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h, right: 4.w),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF6B7280),
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<_MenuItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Column(
            children: [
              _buildMenuItemTile(item),
              if (index < items.length - 1)
                Divider(
                  height: 1,
                  indent: 56.w,
                  endIndent: 16.w,
                  color: const Color(0xFFE5E7EB),
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMenuItemTile(_MenuItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: item.iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(item.icon, color: item.iconColor, size: 22.sp),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1F2937),
                  ),
                ),
              ),
              if (item.trailing != null)
                Text(
                  item.trailing!,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              SizedBox(width: 8.w),
              Icon(
                Icons.chevron_left_rounded,
                color: const Color(0xFFD1D5DB),
                size: 20.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('قريباً إن شاء الله 🚀'),
        backgroundColor: _gradientStart,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_gradientStart, _gradientEnd],
                ),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.school_rounded,
                color: Colors.white,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 12.w),
            const Text('EdSentre'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'تطبيق EdSentre لأولياء الأمور',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8.h),
            Text(
              'الإصدار: 1.0.0',
              style: TextStyle(fontSize: 14.sp, color: const Color(0xFF6B7280)),
            ),
            SizedBox(height: 16.h),
            Text(
              'متابعة أبنائك في المراكز التعليمية بسهولة',
              style: TextStyle(fontSize: 13.sp, color: const Color(0xFF9CA3AF)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('حسناً'),
          ),
        ],
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
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Row(
          children: [
            Icon(
              Icons.logout_rounded,
              color: const Color(0xFFEF4444),
              size: 28.sp,
            ),
            SizedBox(width: 12.w),
            const Text('تسجيل الخروج'),
          ],
        ),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: TextStyle(color: const Color(0xFF6B7280)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              parentProvider.clearSelection();
              await authProvider.signOut();
              if (context.mounted) {
                context.go('/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: const Text(
              'تسجيل الخروج',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem {
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
}
