import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/widgets/genius/glass_card.dart';

class ParentQuickActionsGrid extends StatelessWidget {
  const ParentQuickActionsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      {
        'icon': Icons.fact_check_outlined,
        'label': 'سجل الحضور',
        'color': AppColors.parentPrimary,
        'route': '/parent/attendance',
      },
      {
        'icon': Icons.calendar_today_outlined,
        'label': 'الجدول الدراسي',
        'color': AppColors.accentMid,
        'route': '/parent/schedule',
      },
      {
        'icon': Icons.auto_stories_rounded,
        'label': 'منهجي',
        'color': AppColors.primary,
        'route': '/parent/curriculum',
      },
      {
        'icon': Icons.assessment_outlined,
        'label': 'تقرير الدرجات',
        'color': AppColors.warningAmber,
        'route': '/parent/grades',
      },
      {
        'icon': Icons.account_balance_wallet_outlined,
        'label': 'المدفوعات',
        'color': context.themeError,
        'route': '/parent/payments',
      },
      {
        'icon': Icons.chat_bubble_outline,
        'label': 'المحادثات',
        'color': AppColors.statusInfo,
        'route': '/parent/messages',
      },
      {
        'icon': Icons.person_outline,
        'label': 'حسابي',
        'color': context.themeTextPrimary,
        'route': '/parent/profile',
      },
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - (16.w * 2)) / 3;
        return Wrap(
          spacing: 16.w,
          runSpacing: 16.h,
          children: actions.asMap().entries.map((entry) {
            final index = entry.key;
            final action = entry.value;
            return SizedBox(
              width: itemWidth,
              child: _buildActionCard(
                context: context,
                icon: action['icon'] as IconData,
                label: action['label'] as String,
                color: action['color'] as Color,
                onTap: () => context.push(action['route'] as String),
              ).animate(delay: Duration(milliseconds: 60 * index)).fadeIn().scale(curve: Curves.easeOutBack, duration: 350.ms),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Semantics(
      label: 'خدمة $label',
      button: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 110),
        child: GlassCard(
          color: context.themeCard,
          borderRadius: 20.r,
          padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 8.w),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(20.r),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(color: color.withValues(alpha: 0.3)),
                    ),
                    child: Icon(icon, color: color, size: 26.sp),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    label,
                    style: TextStyle(
                      color: context.themeTextPrimary,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
