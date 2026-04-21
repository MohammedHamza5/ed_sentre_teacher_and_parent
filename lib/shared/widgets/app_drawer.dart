import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/app_colors.dart';
import '../../features/auth/provider/auth_provider.dart';
import '../../features/teacher/provider/teacher_provider.dart';
import '../../features/parent/provider/parent_provider.dart';

import 'drawer/drawer_models.dart';
import 'drawer/drawer_shell.dart';
import 'drawer/drawer_header.dart';
import 'drawer/drawer_logout_dialog.dart';

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

    return DrawerShell(
      header: DrawerHeaderWidget(
        userName: userName,
        subtitle: centerName,
        phone: userPhone,
        avatarUrl: avatarUrl,
        roleLabel: 'معلم',
        roleColor: AppColors.accentVivid,
        gradient: AppColors.secondaryGradient,
        stats: [
          DrawerStatChip(
            label: 'مجموعة',
            value: groupsCount,
            icon: Icons.groups_rounded,
          ),
          DrawerStatChip(
            label: 'طالب',
            value: studentsCount,
            icon: Icons.people_rounded,
          ),
        ],
      ),
      items: [
        DrawerSectionData(
          title: 'الوصول السريع',
          items: [
            DrawerItemData(
              icon: Icons.home_rounded,
              label: 'الرئيسية',
              route: '/teacher',
              gradient: AppColors.premiumOcean,
              isActive: location == '/teacher',
            ),
            DrawerItemData(
              icon: Icons.calendar_month_rounded,
              label: 'الجدول الدراسي',
              route: '/teacher/schedule',
              gradient: AppColors.premiumOcean,
              isActive: location.startsWith('/teacher/schedule'),
            ),
          ],
        ),
        DrawerSectionData(
          title: 'إدارة الفصول',
          items: [
            DrawerItemData(
              icon: Icons.groups_rounded,
              label: 'المجموعات',
              route: '/teacher/groups',
              gradient: AppColors.premiumRoyal,
              isActive: location.startsWith('/teacher/groups'),
            ),
            DrawerItemData(
              icon: Icons.people_alt_rounded,
              label: 'الطلاب',
              route: '/teacher/students',
              gradient: AppColors.premiumEmerald,
              isActive: location.startsWith('/teacher/students'),
            ),
            DrawerItemData(
              icon: Icons.assignment_rounded,
              label: 'الواجبات',
              route: '/teacher/assignments',
              gradient: AppColors.premiumRoyal,
              isActive: location.startsWith('/teacher/assignments'),
            ),
            DrawerItemData(
              icon: Icons.fact_check_rounded,
              label: 'الحضور',
              route: '/teacher/attendance',
              gradient: AppColors.premiumEmerald,
              isActive: location.startsWith('/teacher/attendance'),
            ),
            DrawerItemData(
              icon: Icons.menu_book_rounded,
              label: 'إدارة المناهج',
              route: '/teacher/curriculum',
              gradient: AppColors.premiumOcean,
              isActive: location.startsWith('/teacher/curriculum'),
            ),
          ],
        ),
        DrawerSectionData(
          title: 'الموارد والتقارير',
          items: [
            DrawerItemData(
              icon: Icons.folder_copy_rounded,
              label: 'الملزمات',
              route: '/teacher/materials',
              gradient: AppColors.premiumSunset,
              isActive: location.startsWith('/teacher/materials'),
            ),
            DrawerItemData(
              icon: Icons.bar_chart_rounded,
              label: 'التقارير',
              route: '/teacher/reports',
              gradient: AppColors.premiumOcean,
              isActive: location.startsWith('/teacher/reports'),
            ),
            DrawerItemData(
              icon: Icons.message_rounded,
              label: 'الرسائل',
              route: '/teacher/messages',
              gradient: AppColors.premiumRoyal,
              isActive: location.startsWith('/teacher/messages'),
            ),
          ],
        ),
        DrawerSectionData(
          title: 'أدوات متقدمة',
          items: [
            DrawerItemData(
              icon: Icons.account_balance_wallet_rounded,
              label: 'المالية',
              route: '/teacher/payments',
              gradient: AppColors.premiumEmerald,
              isActive: location.startsWith('/teacher/payments'),
            ),
            DrawerItemData(
              icon: Icons.auto_awesome_rounded,
              label: 'مساعد الذكاء الاصطناعي',
              route: '/teacher/ai-assistant',
              gradient: AppColors.premiumSunset,
              isActive: location.startsWith('/teacher/ai-assistant'),
              badge: 'AI',
            ),
          ],
        ),
        DrawerSectionData(
          title: 'الحساب',
          items: [
            DrawerItemData(
              icon: Icons.person_rounded,
              label: 'حسابي',
              route: '/teacher/profile',
              gradient: AppColors.premiumOcean,
              isActive: location.startsWith('/teacher/profile'),
            ),
          ],
        ),
      ],
      onLogout: () => confirmDrawerLogout(context, auth),
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

    return DrawerShell(
      header: DrawerHeaderWidget(
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
        DrawerSectionData(
          title: 'المتابعة',
          items: [
            DrawerItemData(
              icon: Icons.home_rounded,
              label: 'الرئيسية',
              route: '/parent',
              gradient: parentGradient,
              isActive: location == '/parent',
            ),
            DrawerItemData(
              icon: Icons.calendar_today_rounded,
              label: 'الجدول الدراسي',
              route: '/parent/schedule',
              gradient: const LinearGradient(
                colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
              ),
              isActive: location.startsWith('/parent/schedule'),
            ),
            DrawerItemData(
              icon: Icons.fact_check_rounded,
              label: 'الحضور والغياب',
              route: '/parent/attendance',
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF34D399)],
              ),
              isActive: location.startsWith('/parent/attendance'),
            ),
            DrawerItemData(
              icon: Icons.school_rounded,
              label: 'الدرجات والتقييمات',
              route: '/parent/grades',
              gradient: AppColors.sunsetGradient,
              isActive: location.startsWith('/parent/grades'),
            ),
          ],
        ),
        DrawerSectionData(
          title: 'المالية والتواصل',
          items: [
            DrawerItemData(
              icon: Icons.account_balance_wallet_rounded,
              label: 'المدفوعات',
              route: '/parent/payments',
              gradient: const LinearGradient(
                colors: [Color(0xFF1A5D1A), Color(0xFF0D7C66)],
              ),
              isActive: location.startsWith('/parent/payments'),
            ),
            DrawerItemData(
              icon: Icons.message_rounded,
              label: 'الرسائل',
              route: '/parent/messages',
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
              ),
              isActive: location.startsWith('/parent/messages'),
            ),
            DrawerItemData(
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
        DrawerSectionData(
          title: 'الحساب',
          items: [
            DrawerItemData(
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
      onLogout: () => confirmDrawerLogout(context, auth),
    );
  }
}
