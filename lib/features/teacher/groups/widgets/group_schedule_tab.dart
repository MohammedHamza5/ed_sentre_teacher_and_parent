import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/widgets/genius/glass_card.dart';
import '../../../../shared/models/models.dart';
import 'group_details_helper.dart';

/// Schedule list tab for group details screen.
class GroupScheduleTab extends StatelessWidget {
  final GroupModel group;

  const GroupScheduleTab({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    if (group.schedules.isEmpty) {
      if (group.dayOfWeek != null) {
        return Padding(
          padding: EdgeInsets.all(20.w),
          child: GlassCard(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    Icons.schedule_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Text(
                    'الموعد: ${GroupDetailsHelper.getFieldDayName(group.dayOfWeek)} • ${group.startTime}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 15.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 64.sp,
              color:
                  (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey)
                      .withValues(alpha: 0.5),
            ),
            SizedBox(height: 16.h),
            Text(
              'لا توجد مواعيد',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'لم يتم تحديد مواعيد لهذه المجموعة',
              style: TextStyle(
                color:
                    (Theme.of(context).textTheme.bodySmall?.color ??
                    Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(20.w),
      itemCount: group.schedules.length,
      itemBuilder: (context, index) {
        final schedule = group.schedules[index];
        return Padding(
          padding: EdgeInsets.only(bottom: 14.h),
          child: GlassCard(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: Colors.purple.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    Icons.access_time_rounded,
                    color: Colors.purple,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        GroupDetailsHelper.translateDay(schedule.dayOfWeek),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '${schedule.startTime} - ${schedule.endTime}',
                        style: TextStyle(
                          color:
                              (Theme.of(context).textTheme.bodySmall?.color ??
                              Colors.grey),
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color:
                          (Theme.of(context).dividerTheme.color ??
                          Colors.grey.shade300),
                    ),
                  ),
                  child: Text(
                    schedule.roomName?.isNotEmpty == true
                        ? schedule.roomName!
                        : '—',
                    style: TextStyle(
                      color:
                          (Theme.of(context).textTheme.bodySmall?.color ??
                          Colors.grey),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
