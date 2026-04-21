import 'package:ed_sentre_techer_and_parent/core/config/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Empty state shown when the teacher has no groups assigned.
class AssignmentNoGroupsState extends StatelessWidget {
  const AssignmentNoGroupsState({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.group_off,
            size: 64.sp,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          SizedBox(height: 16.h),
          Text(
            '\u0644\u0627 \u062a\u0648\u062c\u062f \u0645\u062c\u0645\u0648\u0639\u0627\u062a',
            style: TextStyle(fontSize: 16.sp, color: AppColors.textDisplay),
          ),
          SizedBox(height: 8.h),
          Text(
            '\u062a\u0623\u0643\u062f \u0645\u0646 \u0625\u0636\u0627\u0641\u0629 \u0645\u062c\u0645\u0648\u0639\u0627\u062a \u0623\u0648\u0644\u0627\u064b',
            style: TextStyle(
              fontSize: 12.sp,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
