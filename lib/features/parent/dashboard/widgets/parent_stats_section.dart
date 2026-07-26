import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/widgets/genius/glass_card.dart';

class ParentStatsSection extends StatelessWidget {
  final Map<String, dynamic> dashboardData;

  const ParentStatsSection({super.key, required this.dashboardData});

  @override
  Widget build(BuildContext context) {
    final stats = dashboardData['stats'] ?? {};
    final payment = dashboardData['payment'] ?? {};

    final attendanceRate = stats['attendance_rate'] ?? 0;
    final averageGrade = stats['average_grade'] ?? 0;
    final totalDue = payment['total_due'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'نسبة الحضور',
            '$attendanceRate%',
            Icons.check_circle_outline_rounded,
            AppColors.parentPrimary, // Emerald mint reassurance
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildStatCard(
            context,
            'متوسط الدرجات',
            averageGrade.toStringAsFixed(1),
            Icons.emoji_events_outlined,
            AppColors.warningAmber,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildStatCard(
            context,
            'المستحقات',
            '${totalDue.toStringAsFixed(0)}',
            Icons.account_balance_wallet_outlined,
            totalDue > 0 ? context.themeError : AppColors.parentPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return GlassCard(
      padding: EdgeInsets.symmetric(vertical: 18.h, horizontal: 10.w),
      color: context.themeCard,
      borderRadius: 20.r,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: iconColor, size: 22.sp),
          ),
          SizedBox(height: 12.h),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: context.themeTextPrimary,
              fontSize: 18.sp,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              color: context.themeTextSecondary,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
