import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_colors.dart';
import '../../features/auth/provider/auth_provider.dart';
import '../../features/teacher/provider/teacher_provider.dart';
import '../../features/parent/provider/parent_provider.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// GLOBAL SCAFFOLD KEYS
// ═══════════════════════════════════════════════════════════════════════════════

final GlobalKey<ScaffoldState> teacherScaffoldKey = GlobalKey<ScaffoldState>(
  debugLabel: 'TeacherShell',
);

final GlobalKey<ScaffoldState> parentScaffoldKey = GlobalKey<ScaffoldState>(
  debugLabel: 'ParentShell',
);

void openTeacherDrawer() => teacherScaffoldKey.currentState?.openDrawer();
void openParentDrawer() => parentScaffoldKey.currentState?.openDrawer();

// ═══════════════════════════════════════════════════════════════════════════════
// DRAWER MENU BUTTON
// ═══════════════════════════════════════════════════════════════════════════════

class DrawerMenuButton extends StatelessWidget {
  final bool isTeacher;
  final Color? color;

  const DrawerMenuButton({super.key, required this.isTeacher, this.color});

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Colors.white;

    return GestureDetector(
      onTap: isTeacher ? openTeacherDrawer : openParentDrawer,
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: effectiveColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: effectiveColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _Bar(width: 22, color: effectiveColor),
            SizedBox(height: 5.h),
            _Bar(
              width: 14,
              color: effectiveColor.withValues(alpha: 0.8),
            ),
            SizedBox(height: 5.h),
            _Bar(width: 22, color: effectiveColor),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double width;
  final Color? color;
  const _Bar({required this.width, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width.w,
      height: 2.h,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(2.r),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// TEACHER APP DRAWER
// ═══════════════════════════════════════════════════════════════════════════════

class TeacherAppDrawer extends StatelessWidget {
  const TeacherAppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final teacher = context.watch<TeacherProvider>();
    final location = GoRouterState.of(context).matchedLocation;

    final userName =
        auth.teacherProfile?.displayName ??
        auth.currentUser?.fullName ??
        'معلم';
    final userPhone = auth.currentUser?.phone ?? '';
    final avatarUrl = auth.currentUser?.avatarUrl;
    final centerName = teacher.selectedCenter?.name ?? 'سنتر';
    final groupsCount = teacher.totalActiveGroups;
    final studentsCount = teacher.totalUniqueStudents;

    return _DrawerShell(
      header: _DrawerHeader(
        userName: userName,
        subtitle: centerName,
        phone: userPhone,
        avatarUrl: avatarUrl,
        roleLabel: 'معلم',
        roleColor: AppColors.accentVivid,
        gradient: AppColors.secondaryGradient,
        stats: [
          _StatChip(
            label: 'مجموعة',
            value: groupsCount,
            icon: Icons.groups_rounded,
          ),
          _StatChip(
            label: 'طالب',
            value: studentsCount,
            icon: Icons.people_rounded,
          ),
        ],
      ),
      items: [
        _DrawerSectionData(
          title: 'الوصول السريع',
          items: [
            _DrawerItemData(
              icon: Icons.home_rounded,
              label: 'الرئيسية',
              route: '/teacher',
              gradient: AppColors.premiumOcean,
              isActive: location == '/teacher',
            ),
            _DrawerItemData(
              icon: Icons.calendar_month_rounded,
              label: 'الجدول الدراسي',
              route: '/teacher/schedule',
              gradient: AppColors.premiumOcean,
              isActive: location.startsWith('/teacher/schedule'),
            ),
          ],
        ),
        _DrawerSectionData(
          title: 'إدارة الفصول',
          items: [
            _DrawerItemData(
              icon: Icons.groups_rounded,
              label: 'المجموعات',
              route: '/teacher/groups',
              gradient: AppColors.premiumRoyal,
              isActive: location.startsWith('/teacher/groups'),
            ),
            _DrawerItemData(
              icon: Icons.people_alt_rounded,
              label: 'الطلاب',
              route: '/teacher/students',
              gradient: AppColors.premiumEmerald,
              isActive: location.startsWith('/teacher/students'),
            ),
            _DrawerItemData(
              icon: Icons.assignment_rounded,
              label: 'الواجبات',
              route: '/teacher/assignments',
              gradient: AppColors.premiumRoyal,
              isActive: location.startsWith('/teacher/assignments'),
            ),
            _DrawerItemData(
              icon: Icons.fact_check_rounded,
              label: 'الحضور',
              route: '/teacher/attendance',
              gradient: AppColors.premiumEmerald,
              isActive: location.startsWith('/teacher/attendance'),
            ),
            _DrawerItemData(
              icon: Icons.menu_book_rounded,
              label: 'إدارة المناهج',
              route: '/teacher/curriculum',
              gradient: AppColors.premiumOcean,
              isActive: location.startsWith('/teacher/curriculum'),
            ),
          ],
        ),
        _DrawerSectionData(
          title: 'الموارد والتقارير',
          items: [
            _DrawerItemData(
              icon: Icons.folder_copy_rounded,
              label: 'الملزمات',
              route: '/teacher/materials',
              gradient: AppColors.premiumSunset,
              isActive: location.startsWith('/teacher/materials'),
            ),
            _DrawerItemData(
              icon: Icons.bar_chart_rounded,
              label: 'التقارير',
              route: '/teacher/reports',
              gradient: AppColors.premiumOcean,
              isActive: location.startsWith('/teacher/reports'),
            ),
            _DrawerItemData(
              icon: Icons.message_rounded,
              label: 'الرسائل',
              route: '/teacher/messages',
              gradient: AppColors.premiumRoyal,
              isActive: location.startsWith('/teacher/messages'),
            ),
          ],
        ),
        _DrawerSectionData(
          title: 'أدوات متقدمة',
          items: [
            _DrawerItemData(
              icon: Icons.account_balance_wallet_rounded,
              label: 'المالية',
              route: '/teacher/payments',
              gradient: AppColors.premiumEmerald,
              isActive: location.startsWith('/teacher/payments'),
            ),
            _DrawerItemData(
              icon: Icons.auto_awesome_rounded,
              label: 'مساعد الذكاء الاصطناعي',
              route: '/teacher/ai-assistant',
              gradient: AppColors.premiumSunset,
              isActive: location.startsWith('/teacher/ai-assistant'),
              badge: 'AI',
            ),
          ],
        ),
        _DrawerSectionData(
          title: 'الحساب',
          items: [
            _DrawerItemData(
              icon: Icons.person_rounded,
              label: 'حسابي',
              route: '/teacher/profile',
              gradient: AppColors.premiumOcean,
              isActive: location.startsWith('/teacher/profile'),
            ),
          ],
        ),
      ],
      onLogout: () => _confirmLogout(context, auth),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// PARENT APP DRAWER
// ═══════════════════════════════════════════════════════════════════════════════

class ParentAppDrawer extends StatelessWidget {
  const ParentAppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final parent = context.watch<ParentProvider>();
    final location = GoRouterState.of(context).matchedLocation;

    final userName = auth.currentUser?.fullName ?? 'ولي أمر';
    final userPhone = auth.currentUser?.phone ?? '';
    final avatarUrl = auth.currentUser?.avatarUrl;
    final childName = parent.selectedChild?.fullName ?? '';
    final centerName = parent.selectedCenter?.centerName ?? 'سنتر';

    const parentGradient = LinearGradient(
      colors: [AppColors.emeraldGreen, AppColors.accentVivid],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return _DrawerShell(
      header: _DrawerHeader(
        userName: userName,
        subtitle: childName.isNotEmpty ? 'الطالب: $childName' : centerName,
        phone: userPhone,
        avatarUrl: avatarUrl,
        roleLabel: 'ولي أمر',
        roleColor: AppColors.accentVivid,
        gradient: parentGradient,
        stats: const [],
      ),
      items: [
        _DrawerSectionData(
          title: 'المتابعة',
          items: [
            _DrawerItemData(
              icon: Icons.home_rounded,
              label: 'الرئيسية',
              route: '/parent',
              gradient: parentGradient,
              isActive: location == '/parent',
            ),
            _DrawerItemData(
              icon: Icons.calendar_today_rounded,
              label: 'الجدول الدراسي',
              route: '/parent/schedule',
              gradient: const LinearGradient(
                colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
              ),
              isActive: location.startsWith('/parent/schedule'),
            ),
            _DrawerItemData(
              icon: Icons.fact_check_rounded,
              label: 'الحضور والغياب',
              route: '/parent/attendance',
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF34D399)],
              ),
              isActive: location.startsWith('/parent/attendance'),
            ),
            _DrawerItemData(
              icon: Icons.school_rounded,
              label: 'الدرجات والتقييمات',
              route: '/parent/grades',
              gradient: AppColors.sunsetGradient,
              isActive: location.startsWith('/parent/grades'),
            ),
          ],
        ),
        _DrawerSectionData(
          title: 'المالية والتواصل',
          items: [
            _DrawerItemData(
              icon: Icons.account_balance_wallet_rounded,
              label: 'المدفوعات',
              route: '/parent/payments',
              gradient: const LinearGradient(
                colors: [Color(0xFF1A5D1A), Color(0xFF0D7C66)],
              ),
              isActive: location.startsWith('/parent/payments'),
            ),
            _DrawerItemData(
              icon: Icons.message_rounded,
              label: 'الرسائل',
              route: '/parent/messages',
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
              ),
              isActive: location.startsWith('/parent/messages'),
            ),
            _DrawerItemData(
              icon: Icons.notifications_rounded,
              label: 'الإشعارات',
              route: '/parent/notifications',
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFFB923C)],
              ),
              isActive: location.startsWith('/parent/notifications'),
            ),
          ],
        ),
        _DrawerSectionData(
          title: 'الحساب',
          items: [
            _DrawerItemData(
              icon: Icons.person_rounded,
              label: 'حسابي',
              route: '/parent/profile',
              gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              ),
              isActive: location.startsWith('/parent/profile'),
            ),
          ],
        ),
      ],
      onLogout: () => _confirmLogout(context, auth),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED LOGOUT LOGIC
// ═══════════════════════════════════════════════════════════════════════════════

Future<void> _confirmLogout(BuildContext context, AuthProvider auth) async {
  Navigator.of(context).pop(); // close drawer first
  await Future.delayed(const Duration(milliseconds: 300));

  if (!context.mounted) return;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
          side: BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: AppColors.errorSoft,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.logout_rounded,
                color: AppColors.error,
                size: 22.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              'تسجيل الخروج',
              style: TextStyle(
                color: AppColors.textOnDark,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'هل أنت متأكد من تسجيل الخروج من الحساب؟',
          style: TextStyle(
            color: AppColors.textOnDarkSecondary,
            fontSize: 14.sp,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'إلغاء',
              style: TextStyle(
                color: AppColors.textOnDarkSecondary,
                fontSize: 14.sp,
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(left: 8.w, bottom: 4.h),
            child: ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: 20.w,
                  vertical: 10.h,
                ),
              ),
              child: Text(
                'تسجيل الخروج',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  if (confirmed == true && context.mounted) {
    await auth.signOut();
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DATA CLASSES (immutable, no widgets — zero overhead)
// ═══════════════════════════════════════════════════════════════════════════════

class _DrawerSectionData {
  final String title;
  final List<_DrawerItemData> items;
  const _DrawerSectionData({required this.title, required this.items});
}

class _DrawerItemData {
  final IconData icon;
  final String label;
  final String route;
  final LinearGradient gradient;
  final bool isActive;
  final String? badge;

  const _DrawerItemData({
    required this.icon,
    required this.label,
    required this.route,
    required this.gradient,
    this.isActive = false,
    this.badge,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// DRAWER SHELL — Staggered entrance animation, butter-smooth scroll
// ═══════════════════════════════════════════════════════════════════════════════

class _DrawerShell extends StatefulWidget {
  final _DrawerHeader header;
  final List<_DrawerSectionData> items;
  final VoidCallback onLogout;

  const _DrawerShell({
    required this.header,
    required this.items,
    required this.onLogout,
  });

  @override
  State<_DrawerShell> createState() => _DrawerShellState();
}

class _DrawerShellState extends State<_DrawerShell>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    // NOTE: Single animation controller for the entire drawer entrance.
    // This replaces the previous approach of one .animate() per item
    // which created ~20+ animation controllers simultaneously, causing jank.
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.08, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // NOTE: Flatten all sections+items into a single list for ListView.builder.
  // This enables item recycling and eliminates widget tree depth issues.
  List<Widget> _buildFlatList() {
    final widgets = <Widget>[];

    for (final section in widget.items) {
      // Section header
      widgets.add(
        Padding(
          padding: EdgeInsets.only(
            top: 20.h,
            bottom: 8.h,
            left: 8.w,
            right: 8.w,
          ),
          child: Row(
            children: [
              Container(
                width: 3.w,
                height: 12.h,
                decoration: BoxDecoration(
                  gradient: AppColors.secondaryGradient,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                section.title,
                style: TextStyle(
                  color: AppColors.textOnDarkHint,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      );

      // Section items
      for (final item in section.items) {
        widgets.add(_buildDrawerItem(item));
      }
    }

    return widgets;
  }

  Widget _buildDrawerItem(_DrawerItemData item) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).pop();
            context.go(item.route);
          },
          borderRadius: BorderRadius.circular(16.r),
          splashColor: item.gradient.colors.first.withValues(alpha: 0.15),
          highlightColor: item.gradient.colors.first.withValues(alpha: 0.08),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              color: item.isActive
                  ? item.gradient.colors.first.withValues(alpha: 0.12)
                  : Colors.transparent,
              border: item.isActive
                  ? Border.all(
                      color: item.gradient.colors.first
                          .withValues(alpha: 0.25),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                // Active indicator bar
                if (item.isActive)
                  Container(
                    width: 3.w,
                    height: 24.h,
                    margin: EdgeInsets.only(left: 0, right: 10.w),
                    decoration: BoxDecoration(
                      gradient: item.gradient,
                      borderRadius: BorderRadius.circular(4.r),
                      boxShadow: [
                        BoxShadow(
                          color: item.gradient.colors.first
                              .withValues(alpha: 0.6),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                // Icon
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    gradient: item.isActive ? item.gradient : null,
                    color: item.isActive
                        ? null
                        : AppColors.textOnDarkSecondary
                              .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: item.isActive
                        ? [
                            BoxShadow(
                              color: item.gradient.colors.first
                                  .withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    item.icon,
                    color: item.isActive
                        ? Colors.white
                        : AppColors.textOnDarkSecondary,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 14.w),
                // Label
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight:
                          item.isActive ? FontWeight.bold : FontWeight.w500,
                      color: item.isActive
                          ? Colors.white
                          : AppColors.textOnDarkSecondary,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
                // Badge
                if (item.badge != null)
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 8.w),
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      gradient: item.gradient,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: item.gradient.colors.last
                              .withValues(alpha: 0.4),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      item.badge!,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                // Active dot
                if (item.isActive)
                  Container(
                    width: 6.w,
                    height: 6.w,
                    decoration: BoxDecoration(
                      color: item.gradient.colors.last,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: item.gradient.colors.last
                              .withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final flatItems = _buildFlatList();

    return Drawer(
      width: 300.w,
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28.r),
          bottomLeft: Radius.circular(28.r),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.forestPrimary.withValues(alpha: 0.92),
              border: Border(
                left: BorderSide(
                  color: AppColors.glassBorderHighlight,
                  width: 1.5,
                ),
              ),
            ),
            child: Column(
              children: [
                // ── Header ──────────────────────────────────
                widget.header,

                // ── Scrollable Nav ──────────────────────────
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ),
                        // NOTE: ClampingScrollPhysics gives Android-native
                        // scroll feel — snappy with no over-scroll bounce.
                        physics: const ClampingScrollPhysics(),
                        itemCount: flatItems.length,
                        itemBuilder: (_, i) => flatItems[i],
                      ),
                    ),
                  ),
                ),

                // ── Version Badge ───────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: 8.h,
                      horizontal: 12.w,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.textOnDarkHint,
                          size: 14.sp,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'EdSentre v2.0',
                          style: TextStyle(
                            color: AppColors.textOnDarkHint,
                            fontSize: 11.sp,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Divider ─────────────────────────────────
                Divider(
                  color: AppColors.darkBorder.withValues(alpha: 0.5),
                  thickness: 1,
                  height: 1,
                ),

                // ── Logout ──────────────────────────────────
                _LogoutButton(onTap: widget.onLogout),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// DRAWER HEADER
// ═══════════════════════════════════════════════════════════════════════════════

class _DrawerHeader extends StatelessWidget {
  final String userName;
  final String subtitle;
  final String phone;
  final String? avatarUrl;
  final String roleLabel;
  final Color roleColor;
  final LinearGradient gradient;
  final List<_StatChip> stats;

  const _DrawerHeader({
    required this.userName,
    required this.subtitle,
    required this.phone,
    this.avatarUrl,
    required this.roleLabel,
    required this.roleColor,
    required this.gradient,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16.h,
        left: 16.w,
        right: 16.w,
        bottom: 16.h,
      ),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                _UserAvatar(url: avatarUrl, name: userName),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6.h),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 10.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Text(
                          roleLabel,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 20.sp,
                    ),
                  ),
                ),
              ],
            ),
            if (stats.isNotEmpty) ...[
              SizedBox(height: 16.h),
              Divider(
                color: Colors.white.withValues(alpha: 0.2),
                height: 1,
              ),
              SizedBox(height: 16.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: stats,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// USER AVATAR WIDGET
// ═══════════════════════════════════════════════════════════════════════════════

class _UserAvatar extends StatelessWidget {
  final String? url;
  final String name;

  const _UserAvatar({this.url, required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56.w,
      height: 56.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Colors.white24, Colors.white10],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipOval(
        child: url != null && url!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                width: 56.w,
                height: 56.w,
                memCacheWidth: 112,
                memCacheHeight: 112,
                placeholder: (_, __) => _AvatarFallback(name: name),
                errorWidget: (_, __, ___) => _AvatarFallback(name: name),
              )
            : _AvatarFallback(name: name),
      ),
    );
  }
}

class _AvatarFallback extends StatelessWidget {
  final String name;
  const _AvatarFallback({required this.name});

  @override
  Widget build(BuildContext context) {
    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join()
        : '?';
    return Container(
      color: Colors.white.withValues(alpha: 0.15),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// STAT CHIP
// ═══════════════════════════════════════════════════════════════════════════════

class _StatChip extends StatelessWidget {
  final String label;
  final int value;
  final IconData icon;

  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$value',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            fontFamily: 'Cairo',
          ),
        ),
        Row(
          children: [
            Icon(
              icon,
              color: Colors.white.withValues(alpha: 0.8),
              size: 12.sp,
            ),
            SizedBox(width: 4.w),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12.sp,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// LOGOUT BUTTON
// ═══════════════════════════════════════════════════════════════════════════════

class _LogoutButton extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14.r),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 13.h, horizontal: 16.w),
            decoration: BoxDecoration(
              color: AppColors.errorSoft,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: AppColors.error.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.logout_rounded,
                  color: AppColors.error,
                  size: 20.sp,
                ),
                SizedBox(width: 10.w),
                Text(
                  'تسجيل الخروج',
                  style: TextStyle(
                    color: AppColors.error,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
