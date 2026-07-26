import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../../core/config/app_colors.dart';
import '../../../../../shared/models/models.dart';

class SubmissionGlassCard extends StatelessWidget {
  final SubmissionModel submission;
  final double maxScore;
  final bool isInteractive;
  final VoidCallback onTap;

  const SubmissionGlassCard({
    super.key,
    required this.submission,
    required this.maxScore,
    required this.isInteractive,
    required this.onTap,
  });

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0 && now.day == date.day) {
      return 'اليوم ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1 || (diff.inDays == 0 && now.day != date.day)) {
      return 'أمس ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.year}/${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isGraded = submission.isGraded;
    final pct = isGraded && maxScore > 0
        ? ((submission.score ?? 0) / maxScore).clamp(0.0, 1.0)
        : 0.0;

    final borderColor = isGraded
        ? (pct >= 0.8
            ? Colors.green
            : pct >= 0.5
                ? Colors.orange
                : Theme.of(context).colorScheme.error)
        : Colors.white24;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 16.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.6), // Glass effect
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
              color: borderColor.withValues(alpha: 0.4), width: 1.5),
          boxShadow: isGraded && pct >= 0.8
              ? [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ]
              : null,
        ),
        child: Column(
          children: [
            Row(
              children: [
                // Avatar with interactive glow
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: isGraded
                          ? [borderColor, borderColor.withValues(alpha: 0.5)]
                          : [Theme.of(context).colorScheme.primary, AppColors.secondary],
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 22.r,
                    backgroundColor: const Color(0xFF0F172A),
                    backgroundImage: submission.studentAvatar != null
                        ? NetworkImage(submission.studentAvatar!)
                        : null,
                    child: submission.studentAvatar == null
                        ? Icon(Icons.person, color: Colors.white70, size: 24.sp)
                        : null,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              submission.studentName ?? 'طالب',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isGraded && pct >= 0.9)
                            Padding(
                              padding: EdgeInsets.only(right: 6.w),
                              child:
                                  Text('🏆', style: TextStyle(fontSize: 14.sp)),
                            ),
                          if (isGraded && pct < 0.5)
                            Padding(
                              padding: EdgeInsets.only(right: 6.w),
                              child:
                                  Text('⚠️', style: TextStyle(fontSize: 14.sp)),
                            ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        _formatDate(submission.submittedAt),
                        style:
                            TextStyle(color: Colors.white54, fontSize: 11.sp),
                      ),
                    ],
                  ),
                ),
                // Score or Pending Badge
                if (isGraded)
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: borderColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${submission.score?.toStringAsFixed(1)}',
                          style: TextStyle(
                            color: borderColor,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          ' / ${maxScore.toStringAsFixed(0)}',
                          style: TextStyle(
                            color: borderColor.withValues(alpha: 0.7),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Theme.of(context).colorScheme.primary, AppColors.secondary],
                      ),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.edit_note, color: Colors.white, size: 14.sp),
                        SizedBox(width: 4.w),
                        Text(
                          'صحّح الآن',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),

            // Interactive Smart Action Area
            if (isGraded) ...[
              SizedBox(height: 16.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      isInteractive
                          ? Icons.analytics_outlined
                          : Icons.remove_red_eye_outlined,
                      color: Colors.white60,
                      size: 16.sp,
                    ),
                    SizedBox(width: 8.w),
                    Text(
                      isInteractive
                          ? 'عرض التحليل الذكي للإجابات'
                          : 'مراجعة المرفقات والتعليق',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12.sp,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.arrow_forward_ios,
                        color: Colors.white30, size: 12.sp),
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
