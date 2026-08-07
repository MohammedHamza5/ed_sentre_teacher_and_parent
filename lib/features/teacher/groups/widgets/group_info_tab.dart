import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/config/app_colors.dart';
import '../../../../core/widgets/genius/glass_card.dart';
import '../../../../shared/models/models.dart';

/// Info summary tab for group details screen.
class GroupInfoTab extends StatelessWidget {
  final GroupModel group;

  const GroupInfoTab({super.key, required this.group});

  Widget _buildInfoPill(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: context.themeSurface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: context.themeBorder),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -8.w,
            top: -4.h,
            child: Icon(
              icon,
              size: 28.sp,
              color: context.themeTextSecondary.withValues(alpha: 0.2),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: context.themeTextSecondary,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                value,
                style: TextStyle(
                  color: context.themeTextPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14.sp,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      ('اسم المجموعة', group.groupName, Icons.label_rounded),
      ('المادة', group.courseName ?? '-', Icons.book_rounded),
      ('المرحلة', group.gradeLevel ?? '-', Icons.school_rounded),
      ('الكود', group.groupCode ?? '-', Icons.qr_code_rounded),
      (
        'السعر الشهري',
        '${group.monthlyFee ?? 0} ج.م',
        Icons.attach_money_rounded,
      ),
      (
        'عدد الطلاب',
        '${group.currentStudents} / ${group.maxStudents}',
        Icons.people_alt_rounded,
      ),
    ];

    return ListView(
      padding: EdgeInsets.all(20.w),
      physics: const BouncingScrollPhysics(),
      children: [
        GlassCard(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.7),
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ملخص سريع',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 18.sp,
                ),
              ),
              SizedBox(height: 20.h),
              LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = (constraints.maxWidth - 16.w) / 2;
                  return Wrap(
                    spacing: 16.w,
                    runSpacing: 16.h,
                    children: items.map((e) {
                      return SizedBox(
                        width: itemWidth,
                        child: _buildInfoPill(
                          context,
                          label: e.$1,
                          value: e.$2,
                          icon: e.$3,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
