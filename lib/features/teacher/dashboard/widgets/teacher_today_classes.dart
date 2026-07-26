import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/theming/app_spacing.dart';
import '../../../../core/widgets/genius/shimmer_skeleton.dart';
import '../../../../core/widgets/genius/staggered_list_animator.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/premium_widgets.dart' show EmptyState;

/// 🟢 Teacher's Daily Schedule Cards with structured loading and time emphasis
class TeacherTodayClasses extends StatelessWidget {
  final bool isLoading;
  final List<GroupModel> todayGroups;

  const TeacherTodayClasses({
    super.key,
    required this.isLoading,
    required this.todayGroups,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Column(
        children: List.generate(
          2,
          (i) => const Padding(
            padding: EdgeInsets.only(bottom: 12.0),
            child: CardShimmerSkeleton(),
          ),
        ),
      );
    }

    if (todayGroups.isEmpty) {
      return const EmptyState(
        icon: Icons.event_available_rounded,
        title: 'لا توجد حصص مجدولة اليوم!',
        subtitle: 'استمتع بوقتك أو جهّز المواد العلمية للمجموعات القادمة',
      );
    }

    return StaggeredListAnimator(
      isList: false,
      children: todayGroups.map((group) => _buildClassCard(context, group)).toList(),
    );
  }

  Widget _buildClassCard(BuildContext context, GroupModel group) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: AppSpacing.borderRadiusMd,
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode ? Colors.black26 : AppColors.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: context.themeBorder),
      ),
      child: InkWell(
        borderRadius: AppSpacing.borderRadiusMd,
        onTap: () => context.go('/teacher/groups/${group.id}'),
        child: Padding(
          padding: AppSpacing.paddingAll16,
          child: Row(
            children: [
              // High-Contrast Executive Time Pillar
              Container(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                decoration: BoxDecoration(
                  color: context.teacherAccent.withValues(alpha: 0.1),
                  borderRadius: AppSpacing.borderRadiusSm,
                  border: Border.all(color: context.teacherAccent.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      _getTodayStartTime(group)?.split(' ')[0] ?? '--',
                      style: TextStyle(
                        color: context.teacherAccent,
                        fontWeight: FontWeight.w800,
                        fontSize: 16.sp,
                      ),
                    ),
                    if ((_getTodayStartTime(group)?.split(' ').length ?? 0) >= 2)
                      Text(
                        _getTodayStartTime(group)!.split(' ')[1],
                        style: TextStyle(
                          color: context.themeTextSecondary,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              AppSpacing.gapW16,

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.courseName ?? group.groupName,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15.sp,
                        color: context.themeTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    AppSpacing.gapH6,
                    Row(
                      children: [
                        Icon(Icons.class_outlined, size: 14.sp, color: context.themeTextSecondary),
                        AppSpacing.gapW4,
                        Expanded(
                          child: Text(
                            group.groupName,
                            style: TextStyle(fontSize: 12.sp, color: context.themeTextSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        AppSpacing.gapW8,
                        Icon(Icons.groups_rounded, size: 14.sp, color: context.teacherAccent),
                        AppSpacing.gapW4,
                        Text(
                          '${group.currentStudents}',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: context.themeTextPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16.sp,
                color: context.themeTextSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _getTodayStartTime(GroupModel group) {
    if (group.schedules.isEmpty) return group.startTime;
    final todayDate = DateTime.now();
    final dayNames = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
    ];
    final todayName = dayNames[todayDate.weekday - 1];
    try {
      final todaySchedule = group.schedules.firstWhere(
        (s) => s.dayOfWeek.toLowerCase() == todayName.toLowerCase(),
      );
      return todaySchedule.startTime.isNotEmpty ? todaySchedule.startTime : group.startTime;
    } catch (_) {
      return group.startTime;
    }
  }
}
