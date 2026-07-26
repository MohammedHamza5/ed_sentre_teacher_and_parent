import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/app_colors.dart';
import '../../../../core/widgets/genius/glass_card.dart';
import '../../../../core/widgets/genius/genius_button.dart';
import '../../../../shared/data/supabase_repository.dart';
import '../../attendance/screens/teacher_attendance_history_screen.dart';

/// Attendance overview tab for group details screen.
class GroupAttendanceTab extends StatelessWidget {
  final String groupId;
  final bool isLiveActive;
  final SupabaseRepository repository;
  final VoidCallback onShowMonitorWindowHint;

  const GroupAttendanceTab({
    super.key,
    required this.groupId,
    required this.isLiveActive,
    required this.repository,
    required this.onShowMonitorWindowHint,
  });

  Widget _buildMiniStat({
    required String label,
    required int value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(height: 8.h),
          Text(
            '$value',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(20.w),
      physics: const BouncingScrollPhysics(),
      children: [
        FutureBuilder<List<Map<String, dynamic>>>(
          future: repository.getGroupAttendanceForToday(groupId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return GlassCard(
                color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
                padding: EdgeInsets.all(20.w),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20.w,
                      height: 20.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    SizedBox(width: 16.w),
                    Text(
                      'تحميل ملخص حضور اليوم...',
                      style: TextStyle(
                        color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }

            final data = snapshot.data ?? [];
            final present = data
                .where((s) => s['attendance_status'] == 'present')
                .length;
            final late = data
                .where((s) => s['attendance_status'] == 'late')
                .length;
            final absent = data
                .where((s) => s['attendance_status'] == 'absent')
                .length;
            final pending = data
                .where(
                  (s) =>
                      s['attendance_status'] == 'pending' ||
                      s['attendance_status'] == null,
                )
                .length;

            return GlassCard(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
              padding: EdgeInsets.all(24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.today_rounded,
                        color: Theme.of(context).colorScheme.onSurface,
                        size: 20.sp,
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        'حضور اليوم',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 17.sp,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMiniStat(
                          label: 'حضور',
                          value: present,
                          color: Colors.green,
                          icon: Icons.check_circle_rounded,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildMiniStat(
                          label: 'تأخير',
                          value: late,
                          color: Colors.orange,
                          icon: Icons.access_time_rounded,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildMiniStat(
                          label: 'غياب',
                          value: absent,
                          color: Theme.of(context).colorScheme.error,
                          icon: Icons.cancel_rounded,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildMiniStat(
                          label: 'لم يُسجل',
                          value: pending,
                          color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
                          icon: Icons.help_outline_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0);
          },
        ),
        SizedBox(height: 20.h),
        GlassCard(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
          padding: EdgeInsets.all(24.w),
          child: Column(
            children: [
              Icon(
                    Icons.broadcast_on_personal_rounded,
                    size: 56.sp,
                    color: isLiveActive
                        ? Theme.of(context).colorScheme.error
                        : (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
                  )
                  .animate(target: isLiveActive ? 1 : 0)
                  .scale(
                    duration: 400.ms,
                    begin: Offset(0.8, 0.8),
                    end: Offset(1, 1),
                  ),
              SizedBox(height: 16.h),
              Text(
                'مراقبة الحضور (مباشر)',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                isLiveActive
                    ? 'الحصة جارية الآن. يمكنك بدء مراقبة الحضور.'
                    : 'لا توجد حصة جارية حالياً (يفتح قبل الموعد بـ 30 دقيقة).',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14.sp, color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey)),
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: GeniusButton(
                  label: 'بدء المراقبة',
                  onPressed: () {
                    if (isLiveActive) {
                      context.push('/teacher/attendance/$groupId');
                      return;
                    }
                    onShowMonitorWindowHint();
                  },
                ),
              ),
            ],
          ),
        ).animate().fadeIn().slideY(),
        SizedBox(height: 20.h),
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                    TeacherAttendanceHistoryScreen(groupId: groupId),
              ),
            );
          },
          child: GlassCard(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
            padding: EdgeInsets.all(20.w),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: Colors.purple.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Icon(
                    Icons.history_rounded,
                    color: Colors.purple,
                  ),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'سجل الحضور',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'مراجعة الحضور للأيام السابقة',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16.sp,
                  color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
                ),
              ],
            ),
          ).animate(delay: 100.ms).fadeIn().slideY(),
        ),
      ],
    );
  }
}
