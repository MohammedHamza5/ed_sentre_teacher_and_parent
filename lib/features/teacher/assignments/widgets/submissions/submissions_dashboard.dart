import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/config/app_colors.dart';

class SubmissionsDashboard extends StatelessWidget {
  final String title;
  final String type;
  final int totalCount;
  final int gradedCount;
  final int pendingCount;
  final double avgPercentage;
  final double avgScore;
  final double maxScore;

  const SubmissionsDashboard({
    super.key,
    required this.title,
    required this.type,
    required this.totalCount,
    required this.gradedCount,
    required this.pendingCount,
    required this.avgPercentage,
    required this.avgScore,
    required this.maxScore,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalCount > 0 ? (gradedCount / totalCount) : 0.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4.h),
          Text(
            '$type • إجمالي التسليمات: $totalCount',
            style: TextStyle(color: Colors.white60, fontSize: 12.sp),
          ),
          SizedBox(height: 24.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Circular Avg Score
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 48.w,
                      height: 48.w,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: 1.0,
                            strokeWidth: 4,
                            color: Colors.white12,
                          ),
                          CircularProgressIndicator(
                            value: avgPercentage / 100,
                            strokeWidth: 4,
                            strokeCap: StrokeCap.round,
                            color: avgPercentage >= 80
                                ? Colors.green
                                : avgPercentage >= 50
                                    ? Colors.orange
                                    : Theme.of(context).colorScheme.error,
                          ),
                          Text(
                            '${avgPercentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'متوسط الدرجات',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10.sp,
                          ),
                        ),
                        Text(
                          '${avgScore.toStringAsFixed(1)} / ${maxScore.toStringAsFixed(1)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Overview Stats
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: 16.w),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('تم التصحيح',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 10.sp)),
                          Text('$gradedCount',
                              style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.sp)),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4.r),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4.h,
                          backgroundColor: Colors.white12,
                          valueColor: const AlwaysStoppedAnimation(
                              Colors.green),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('بانتظار التقيم',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 10.sp)),
                          Text('$pendingCount',
                              style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.sp)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
