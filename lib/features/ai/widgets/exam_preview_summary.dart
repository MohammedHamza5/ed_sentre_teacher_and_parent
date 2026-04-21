import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/config/app_colors.dart';

class ExamPreviewSummary extends StatelessWidget {
  final List<Map<String, dynamic>> questions;
  final String? difficulty;

  const ExamPreviewSummary({
    super.key,
    required this.questions,
    this.difficulty,
  });

  @override
  Widget build(BuildContext context) {
    final totalMarks = questions.fold<int>(
      0,
      (sum, q) => sum + (q['marks'] as int? ?? 2),
    );

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 28.sp,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'محرر الامتحان التفاعلي ✨',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'عدّل الأسئلة بمرونة واسحبها لترتيبها',
                      style: TextStyle(color: Colors.white70, fontSize: 13.sp),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryItem('${questions.length}', 'سؤال', Icons.help_outline),
              _summaryItem('$totalMarks', 'درجة', Icons.star_border),
              _summaryItem(
                difficulty == 'easy'
                    ? 'سهل'
                    : difficulty == 'hard'
                    ? 'صعب'
                    : 'متوسط',
                'صعوبة',
                Icons.trending_up,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20.sp),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.white60, fontSize: 11.sp),
        ),
      ],
    );
  }
}
