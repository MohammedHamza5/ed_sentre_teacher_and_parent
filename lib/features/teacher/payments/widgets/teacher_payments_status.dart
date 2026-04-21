import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../shared/widgets/premium_widgets.dart';

class TeacherPaymentsStatus extends StatelessWidget {
  final Map<String, dynamic> salaryData;

  const TeacherPaymentsStatus({super.key, required this.salaryData});

  @override
  Widget build(BuildContext context) {
    final status = salaryData['status'] ?? 'draft';
    final salaryId = salaryData['salary_id'];

    Color statusColor;
    String statusText;
    IconData statusIcon;

    switch (status) {
      case 'paid':
        statusColor = const Color(0xFF4CAF50);
        statusText = 'تم الصرف ✅';
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'approved':
        statusColor = const Color(0xFF2196F3);
        statusText = 'معتمد - في انتظار الصرف';
        statusIcon = Icons.verified_rounded;
        break;
      case 'pending':
        statusColor = const Color(0xFFFFA726);
        statusText = 'قيد المراجعة';
        statusIcon = Icons.hourglass_empty_rounded;
        break;
      default:
        statusColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7);
        statusText = salaryId != null ? 'محسوب — لم يُصرف بعد' : 'لم يُحسب بعد';
        statusIcon = Icons.info_outline_rounded;
    }

    return PremiumCard(
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(statusIcon, color: statusColor, size: 24.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'حالة الراتب',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: 200.ms).fadeIn().slideY(begin: 0.1);
  }
}
