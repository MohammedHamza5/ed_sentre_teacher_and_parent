import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/config/app_colors.dart';

/// Premium scoreboard with circular progress for exam review.
class ExamReviewScoreboard extends StatelessWidget {
  final double totalScore;
  final double maxScore;
  final double percentage;

  const ExamReviewScoreboard({
    super.key,
    required this.totalScore,
    required this.maxScore,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    final color = percentage >= 80
        ? Colors.green
        : percentage >= 50
        ? Colors.orange
        : Theme.of(context).colorScheme.error;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.analytics_rounded, color: color, size: 20.sp),
                    SizedBox(width: 8.w),
                    Text(
                      'النتيجة النهائية',
                      style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      totalScore.toStringAsFixed(1),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48.sp,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      '/ ${maxScore.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withValues(alpha: 0.2),
                        color.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30.r),
                    border: Border.all(color: color.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        percentage >= 50
                            ? Icons.military_tech_rounded
                            : Icons.info_outline_rounded,
                        color: color,
                        size: 18.sp,
                      ),
                      SizedBox(width: 6.w),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            percentage >= 90
                                ? 'عبقري وممتاز'
                                : percentage >= 50
                                ? 'اجتياز بنجاح'
                                : 'يحتاج للتحسين المستمر',
                            style: TextStyle(
                              color: color,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Circular Progress Ring
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.2),
            ),
            child: SizedBox(
              width: 90.w,
              height: 90.w,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: percentage / 100),
                duration: const Duration(seconds: 1),
                curve: Curves.easeOutBack,
                builder: (context, value, _) {
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: 1.0,
                        strokeWidth: 8.w,
                        backgroundColor: Colors.white.withValues(alpha: 0.05),
                      ),
                      CircularProgressIndicator(
                        value: value,
                        strokeWidth: 8.w,
                        strokeCap: StrokeCap.round,
                        color: color,
                      ),
                      Text(
                        '${(value * 100).toInt()}%',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
