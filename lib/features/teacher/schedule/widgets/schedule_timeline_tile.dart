import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
// Removed AppColors import
import '../../../../shared/models/group_model.dart';

class ScheduleTimelineTile extends StatelessWidget {
  final GroupModel group;
  final bool isFirst;
  final bool isLast;
  final bool isPast;

  const ScheduleTimelineTile({
    super.key,
    required this.group,
    this.isFirst = false,
    this.isLast = false,
    this.isPast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Line & Dot
          SizedBox(
            width: 50.w,
            child: Column(
              children: [
                // Upper Line
                Expanded(
                  child: isFirst
                      ? const SizedBox()
                      : Container(
                          width: 2.w,
                          color: isPast
                              ? Theme.of(
                                  context,
                                ).colorScheme.outline.withValues(alpha: 0.3)
                              : Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.3),
                        ),
                ),
                // Dot
                Container(
                  width: 12.w,
                  height: 12.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPast
                        ? Theme.of(context).colorScheme.outline
                        : Theme.of(context).colorScheme.primary,
                    border: Border.all(
                      color:
                          Theme.of(context).cardTheme.color ??
                          Theme.of(context).colorScheme.surface,
                      width: 2.w,
                    ),
                    boxShadow: [
                      if (!isPast)
                        BoxShadow(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                ),
                // Lower Line
                Expanded(
                  child: isLast
                      ? const SizedBox()
                      : Container(
                          width: 2.w,
                          color: isPast
                              ? Theme.of(
                                  context,
                                ).colorScheme.outline.withValues(alpha: 0.3)
                              : Theme.of(
                                  context,
                                ).colorScheme.primary.withValues(alpha: 0.3),
                        ),
                ),
              ],
            ),
          ),

          // Content Card
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: 24.h), // Spacing between items
              child: Container(
                decoration: BoxDecoration(
                  color:
                      Theme.of(context).cardTheme.color ??
                      Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).shadowColor.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(16.r),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Time & Status
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time_rounded,
                                  size: 14.sp,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                SizedBox(width: 4.w),
                                Text(
                                  _formatTime(group.startTime) ?? '00:00',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  ' - ',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  _formatTime(group.endTime) ?? '00:00',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (group.courseName != null)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 8.w,
                                vertical: 4.h,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.secondary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Text(
                                group.courseName!,
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 12.h),

                      // Group Name
                      Text(
                        group.groupName,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),

                      SizedBox(height: 8.h),

                      // Info Row (Room / Students count)
                      Row(
                        children: [
                          Icon(
                            Icons.people_outline_rounded,
                            size: 16.sp,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            '${group.currentStudents} / ${group.maxStudents} طالب',
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          SizedBox(width: 16.w),
                          // Placeholder for Room/Location if we add it later
                          Icon(
                            Icons.location_on_outlined,
                            size: 16.sp,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            'القاعة الرئيسية', // Hardcoded for now or fetch from DB
                            style: TextStyle(
                              fontSize: 13.sp,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn().slideX(begin: 0.1, end: 0),
            ),
          ),
        ],
      ),
    );
  }

  // Simple helper to format HH:MM:SS to HH:MM AM/PM
  String? _formatTime(String? timeStr) {
    if (timeStr == null) return null;
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final dt = DateTime(2022, 1, 1, hour, minute);
      final hour12 = dt.hour > 12
          ? dt.hour - 12
          : (dt.hour == 0 ? 12 : dt.hour);
      final amPm = dt.hour >= 12 ? 'PM' : 'AM';
      final minStr = minute.toString().padLeft(2, '0');
      return '$hour12:$minStr $amPm';
    } catch (e) {
      return timeStr; // Fallback
    }
  }
}
