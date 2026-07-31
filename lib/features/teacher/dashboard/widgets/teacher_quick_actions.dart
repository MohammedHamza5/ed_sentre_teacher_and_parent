import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/theming/app_spacing.dart';

/// 🟢 Executive Quick Actions Grid with ergonomic target sizes and refined palettes.
class TeacherQuickActions extends StatelessWidget {
  const TeacherQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickActionItem(
        icon: Icons.groups_rounded,
        label: 'المجموعات',
        route: '/teacher/groups',
        color: context.teacherAccent,
      ),
      _QuickActionItem(
        icon: Icons.fact_check_rounded,
        label: 'الحضور',
        route: '/teacher/attendance',
        color: AppColors.teal,
      ),
      _QuickActionItem(
        icon: Icons.qr_code_scanner_rounded,
        label: 'مسح QR',
        route: '/teacher/scan',
        color: const Color(0xFFF97316), // Vibrant Orange for rapid visibility
      ),
      _QuickActionItem(
        icon: Icons.assignment_rounded,
        label: 'الواجبات',
        route: '/teacher/assignments',
        color: AppColors.gold,
      ),
      _QuickActionItem(
        icon: Icons.people_alt_rounded,
        label: 'الطلاب',
        route: '/teacher/students',
        color: AppColors.electric,
      ),
      _QuickActionItem(
        icon: Icons.folder_copy_rounded,
        label: 'الملزمات',
        route: '/teacher/materials',
        color: AppColors.accentOrange,
      ),
      _QuickActionItem(
        icon: Icons.menu_book_rounded,
        label: 'المناهج',
        route: '/teacher/curriculum',
        color: AppColors.statusInfo,
      ),
      _QuickActionItem(
        icon: Icons.bar_chart_rounded,
        label: 'التقارير',
        route: '/teacher/reports',
        color: AppColors.indigoLight,
      ),
      _QuickActionItem(
        icon: Icons.account_balance_wallet_rounded,
        label: 'المالية',
        route: '/teacher/payments',
        color: AppColors.statusSuccess,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 1.15,
      ),
      itemCount: actions.length,
      itemBuilder: (context, index) => _buildActionCard(context, actions[index], index),
    );
  }

  Widget _buildActionCard(BuildContext context, _QuickActionItem action, int index) {
    return Semantics(
      label: action.label,
      button: true,
      child: InkWell(
        onTap: () => context.go(action.route),
        borderRadius: AppSpacing.borderRadiusMd,
        child: Container(
          constraints: const BoxConstraints(minWidth: AppSpacing.touchTargetMin, minHeight: AppSpacing.touchTargetMin),
          decoration: BoxDecoration(
            color: context.themeCard,
            borderRadius: AppSpacing.borderRadiusMd,
            border: Border.all(color: context.themeBorder),
            boxShadow: [
              BoxShadow(
                color: context.isDarkMode ? Colors.black26 : AppColors.shadow,
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: action.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(action.icon, color: action.color, size: 22.sp),
              ),
              AppSpacing.gapH8,
              Text(
                action.label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12.sp,
                  color: context.themeTextPrimary,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: (50 * index).ms).scale(curve: Curves.easeOutBack, duration: 350.ms);
  }
}

class _QuickActionItem {
  final IconData icon;
  final String label;
  final String route;
  final Color color;
  const _QuickActionItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.color,
  });
}
