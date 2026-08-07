import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/config/app_colors.dart';
import '../../../../core/widgets/genius/glass_card.dart';
import '../../../../shared/models/models.dart';
import 'group_details_helper.dart';

/// Header section for the group details SliverAppBar FlexibleSpaceBar.
class GroupDetailsHeader extends StatelessWidget {
  final GroupModel group;
  final double tabBarHeight;

  const GroupDetailsHeader({
    super.key,
    required this.group,
    required this.tabBarHeight,
  });

  Widget _buildHeaderChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: context.themeSurface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.themeBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.sp, color: AppColors.primary),
          SizedBox(width: 8.w),
          Text(
            label,
            style: TextStyle(
              color: context.themeTextPrimary,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32.r)),
      ),
      child: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(
                16.w,
                16.h,
                16.w,
                72.h + tabBarHeight,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8.h),
                  Align(
                    alignment: Alignment.center,
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      runAlignment: WrapAlignment.center,
                      spacing: 12.w,
                      runSpacing: 12.h,
                      children: [
                        _buildHeaderChip(
                          context,
                          icon: Icons.people_alt_rounded,
                          label: '${group.currentStudents} طالب',
                        ),
                        _buildHeaderChip(
                          context,
                          icon: Icons.attach_money_rounded,
                          label: '${group.monthlyFee ?? 0} ج.م',
                        ),
                        if (group.groupCode != null &&
                            group.groupCode!.isNotEmpty)
                          _buildHeaderChip(
                            context,
                            icon: Icons.qr_code_rounded,
                            label: group.groupCode!,
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Align(
                    alignment: Alignment.center,
                    child: Text(
                      group.courseName ?? 'مادة',
                      style: TextStyle(
                        color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          PositionedDirectional(
            bottom: tabBarHeight + 8.h,
            start: 16.w,
            end: 16.w,
            child: GlassCard(
              color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Icon(
                      Icons.groups_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24.sp,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          group.groupName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 18.sp,
                          ),
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          GroupDetailsHelper.buildScheduleSummary(group),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey),
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.2, end: 0),
          ),
        ],
      ),
    );
  }
}
