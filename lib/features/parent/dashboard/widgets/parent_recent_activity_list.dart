import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../../../core/config/app_colors.dart';
import '../../../../core/widgets/genius/glass_card.dart';

class ParentRecentActivityList extends StatelessWidget {
  final List<Map<String, dynamic>> recentActivities;

  const ParentRecentActivityList({super.key, required this.recentActivities});

  @override
  Widget build(BuildContext context) {
    if (recentActivities.isEmpty) {
      return GlassCard(
        padding: EdgeInsets.all(32.w),
        color: context.themeCard,
        borderRadius: 24.r,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_rounded, size: 48.sp, color: context.themeTextSecondary),
              SizedBox(height: 16.h),
              Text(
                'لا توجد نشاطات حديثة مسجلة',
                style: TextStyle(
                  color: context.themeTextPrimary,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn();
    }

    return Column(
      children: recentActivities.asMap().entries.map((entry) {
        final index = entry.key;
        final activity = entry.value;
        final isAttendance = activity['type'] == 'attendance';
        
        Color statusColor = AppColors.warningAmber;
        IconData actionIcon = Icons.star_outline_rounded;

        if (isAttendance) {
          actionIcon = Icons.fact_check_outlined;
          if (activity['status'] == 'present') {
            statusColor = AppColors.parentPrimary;
          } else if (activity['status'] == 'late') {
            statusColor = AppColors.warningAmber;
          } else {
            statusColor = context.themeError;
          }
        }

        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: GlassCard(
            color: context.themeCard,
            borderRadius: 18.r,
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Icon(
                    actionIcon,
                    color: statusColor,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity['title'] ?? 'تحديث جديد',
                        style: TextStyle(
                          color: context.themeTextPrimary,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        activity['subtitle'] ?? '',
                        style: TextStyle(
                          color: context.themeTextSecondary,
                          fontSize: 13.sp,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (activity['date'] != null && activity['date'] is DateTime)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text(
                      timeago.format(activity['date'] as DateTime, locale: 'ar'),
                      style: TextStyle(
                        color: context.themeTextSecondary,
                        fontSize: 11.5.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ).animate(delay: Duration(milliseconds: 50 * index)).fadeIn().slideX(begin: 0.05, end: 0);
      }).toList(),
    );
  }
}
