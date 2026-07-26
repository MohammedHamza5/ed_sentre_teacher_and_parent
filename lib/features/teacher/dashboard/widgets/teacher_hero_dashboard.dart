import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/theming/app_spacing.dart';
import '../../../../core/providers/center_provider.dart';
import '../../provider/teacher_provider.dart';
import '../../../../shared/models/models.dart';
import '../../../../shared/widgets/premium_widgets.dart' show AvatarWithBorder;

/// 🟢 Premium Teacher Dashboard Hero Card with High-Contrast Power Operator Aesthetics
class TeacherHeroDashboard extends StatelessWidget {
  final UserModel? user;
  final TeacherModel? teacher;
  final TeacherProvider teacherProvider;
  final CenterProvider centerProvider;
  final int todayGroupsCount;
  final VoidCallback onCenterChanged;

  const TeacherHeroDashboard({
    super.key,
    required this.user,
    required this.teacher,
    required this.teacherProvider,
    required this.centerProvider,
    required this.todayGroupsCount,
    required this.onCenterChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingAll20,
      decoration: BoxDecoration(
        color: context.themeCard,
        borderRadius: AppSpacing.borderRadiusLg,
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode
                ? Colors.black.withValues(alpha: 0.35)
                : AppColors.shadow,
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(
          color: context.isDarkMode
              ? AppColors.teacherPrimary.withValues(alpha: 0.3)
              : context.themeBorder,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarWithBorder(imageUrl: user?.avatarUrl, radius: 28),
              AppSpacing.gapW12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getGreeting(),
                      style: TextStyle(
                        color: context.themeTextSecondary,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      teacher?.displayName ?? user?.fullName ?? 'معلم قيادي',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        color: context.themeTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (centerProvider.hasMultipleCenters)
                _buildCenterDropdown(context)
              else if (centerProvider.currentCenter != null)
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: context.teacherAccent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_on_rounded,
                    color: context.teacherAccent,
                    size: 20.sp,
                  ),
                ),
            ],
          ),
          AppSpacing.gapH16,
          Divider(color: context.themeBorder, height: 1),
          AppSpacing.gapH16,
          Row(
            children: [
              _buildMicroStat(
                context,
                'حصص اليوم',
                '$todayGroupsCount',
                Icons.event_note_rounded,
                context.teacherAccent,
              ),
              _buildMicroStat(
                context,
                'إجمال الطلاب',
                '${teacherProvider.statsTotalStudents}',
                Icons.groups_rounded,
                AppColors.teal,
              ),
              _buildMicroStat(
                context,
                'رسائل جديدة',
                '${teacherProvider.dashboardStats['unread_messages_count'] ?? 0}',
                Icons.forum_rounded,
                AppColors.gold,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }

  Widget _buildCenterDropdown(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: context.themeBackground,
        borderRadius: AppSpacing.borderRadiusSm,
        border: Border.all(color: context.themeBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: centerProvider.currentCenterId,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: context.themeTextPrimary,
            size: 18.sp,
          ),
          dropdownColor: context.themeCard,
          style: TextStyle(
            color: context.themeTextPrimary,
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
          ),
          items: centerProvider.availableCenters.map((center) {
            return DropdownMenuItem(value: center.id, child: Text(center.name));
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              centerProvider.selectCenter(value);
              onCenterChanged();
            }
          },
        ),
      ),
    );
  }

  Widget _buildMicroStat(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color accentColor,
  ) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(icon, color: accentColor, size: 22.sp),
          ),
          AppSpacing.gapH8,
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 19.sp,
              color: context.themeTextPrimary,
              height: 1.1,
            ),
          ),
          AppSpacing.gapH4,
          Text(
            title,
            style: TextStyle(
              color: context.themeTextSecondary,
              fontSize: 11.5.sp,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صباح الهمم عالية ☀️';
    if (hour < 17) return 'مساء التميز 🌤️';
    return 'مساء العطاء 🌙';
  }
}
