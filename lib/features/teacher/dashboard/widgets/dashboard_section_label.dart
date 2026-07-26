import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/theming/app_spacing.dart';

/// 🟢 Premium reusable section header with consistent typography and action CTA.
class DashboardSectionLabel extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTapAction;
  final String actionText;

  const DashboardSectionLabel({
    super.key,
    required this.title,
    required this.icon,
    required this.iconColor,
    this.onTapAction,
    this.actionText = 'عرض الكل',
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: iconColor, size: 20.sp),
        ),
        AppSpacing.gapW8,
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.w700,
              color: context.themeTextPrimary,
            ),
          ),
        ),
        if (onTapAction != null)
          InkWell(
            onTap: onTapAction,
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: context.teacherAccent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: context.teacherAccent.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                actionText,
                style: TextStyle(
                  color: context.teacherAccent,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.sp,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
