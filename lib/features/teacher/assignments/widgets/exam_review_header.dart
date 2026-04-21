import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/config/app_colors.dart';
import '../../../../shared/models/models.dart';

/// Student info header for the exam review screen.
class ExamReviewHeader extends StatelessWidget {
  final SubmissionModel submission;
  final String assignmentTitle;

  const ExamReviewHeader({
    super.key,
    required this.submission,
    required this.assignmentTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.accentVivid, AppColors.secondary],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accentVivid,
                    blurRadius: 10,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 26.r,
                backgroundColor: const Color(0xFF0F172A),
                backgroundImage: submission.studentAvatar != null
                    ? NetworkImage(submission.studentAvatar!)
                    : null,
                child: submission.studentAvatar == null
                    ? Icon(
                        Icons.school_rounded,
                        color: Colors.white,
                        size: 28.sp,
                      )
                    : null,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    submission.studentName ?? 'طالب مجهول',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    assignmentTitle,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
