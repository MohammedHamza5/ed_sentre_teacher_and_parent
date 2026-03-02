import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/config/app_colors.dart';
import '../../ai/services/ai_weakness_detector.dart';

class WeaknessCard extends StatelessWidget {
  final WeaknessInsight insight;

  const WeaknessCard({super.key, required this.insight});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280.w,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            _getSeverityColor(insight.severity).withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: _getSeverityColor(insight.severity).withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow.withValues(alpha: 0.05),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: _getSeverityColor(
                    insight.severity,
                  ).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getInsightIcon(insight.type),
                  color: _getSeverityColor(insight.severity),
                  size: 16.sp,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  insight.subjectName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13.sp,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildSeverityBadge(insight.severity),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            insight.message,
            style: TextStyle(
              fontSize: 12.sp,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 6.h),
          Text(
            '💡 ${insight.suggestion}',
            style: TextStyle(
              fontSize: 10.sp,
              color: AppColors.textHint,
              fontStyle: FontStyle.italic,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.2);
  }

  Color _getSeverityColor(WeaknessSeverity severity) {
    switch (severity) {
      case WeaknessSeverity.high:
        return AppColors.error;
      case WeaknessSeverity.medium:
        return AppColors.warning;
      case WeaknessSeverity.low:
        return AppColors.info;
    }
  }

  IconData _getInsightIcon(WeaknessType type) {
    switch (type) {
      case WeaknessType.grades:
        return Icons.trending_down_rounded;
      case WeaknessType.attendance:
        return Icons.person_off_rounded;
      case WeaknessType.behavior:
        return Icons.warning_amber_rounded;
    }
  }

  Widget _buildSeverityBadge(WeaknessSeverity severity) {
    String label;
    Color color;

    switch (severity) {
      case WeaknessSeverity.high:
        label = 'High';
        color = AppColors.error;
        break;
      case WeaknessSeverity.medium:
        label = 'Medium';
        color = AppColors.warning;
        break;
      case WeaknessSeverity.low:
        label = 'Low';
        color = AppColors.info;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
