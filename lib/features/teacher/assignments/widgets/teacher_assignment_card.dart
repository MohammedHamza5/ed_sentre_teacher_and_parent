import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/widgets/genius/glass_card.dart';
import 'assignment_helper.dart';

class TeacherAssignmentCard extends StatelessWidget {
  final Map<String, dynamic> assignment;
  final VoidCallback onViewSubmissions;
  final VoidCallback onOpenDetails;
  final VoidCallback onShowMoreOptions;

  const TeacherAssignmentCard({
    super.key,
    required this.assignment,
    required this.onViewSubmissions,
    required this.onOpenDetails,
    required this.onShowMoreOptions,
  });

  String _formatDate(DateTime? date) {
    if (date == null) return 'بلا موعد';
    final now = DateTime.now();
    final diff = date.difference(now).inDays;

    if (diff == 0) return 'اليوم';
    if (diff == 1) return 'غداً';
    if (diff < 0) return 'منذ ${diff.abs()} يوم';
    return 'بعد $diff يوم';
  }

  Widget _buildIconText(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 14.sp, color: color),
        SizedBox(width: 4.w),
        Text(
          text,
          style: TextStyle(fontSize: 11.sp, color: color),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = assignment['title'] as String? ?? 'بدون عنوان';
    final courseName = assignment['course_name'] as String? ?? 'غير محدد';
    final type = assignment['type'] as String? ?? 'assignment';
    final dueDateStr = assignment['due_date'] as String?;
    final DateTime? dueDate = dueDateStr != null
        ? DateTime.tryParse(dueDateStr)
        : null;
    final publishDate = AssignmentHelper.getPublishDate(assignment);
    final isArchived = AssignmentHelper.isArchived(assignment);
    final maxScore = assignment['max_score'] ?? 0;

    // Extract submissions count from Supabase aggregate
    int subCount = 0;
    final subData = assignment['assignment_submissions'];
    if (subData is List && subData.isNotEmpty) {
      subCount = (subData[0]['count'] as num?)?.toInt() ?? 0;
    } else {
      subCount = (assignment['submissions_count'] as num?)?.toInt() ?? 0;
    }

    final isEnded = dueDate != null && DateTime.now().isAfter(dueDate);
    final isScheduled =
        publishDate != null && DateTime.now().isBefore(publishDate);

    Color typeColor;
    IconData typeIcon;
    String typeName;

    switch (type) {
      case 'exam':
        typeColor = Colors.orange;
        typeIcon = Icons.quiz_outlined;
        typeName = 'امتحان';
        break;
      case 'quiz':
        typeColor = const Color(0xFF8B5CF6);
        typeIcon = Icons.bolt;
        typeName = 'كويز';
        break;
      default:
        typeColor = Theme.of(context).colorScheme.primary;
        typeIcon = Icons.assignment_outlined;
        typeName = 'واجب';
    }

    return GlassCard(
      onTap: onViewSubmissions,
      padding: EdgeInsets.all(16.w),
      borderColor: (!isEnded && !isArchived)
          ? (isScheduled
                ? Colors.orange
                : typeColor.withValues(
                    alpha: 0.5,
                  )) // Emphasize border color by type
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: typeColor.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
                child: Icon(typeIcon, color: typeColor, size: 28.sp),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15.sp,
                        fontWeight: FontWeight.bold,
                        color: isEnded
                            ? Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.3)
                            : Theme.of(context).colorScheme.onSurface,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      '$typeName • $courseName',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ],
                ),
              ),
              if (isArchived)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'مؤرشف',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Theme.of(context).colorScheme.primary,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              if (isArchived) SizedBox(width: 6.w),
              if (isScheduled)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    'مجدول',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.orange,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
              if (isScheduled) SizedBox(width: 6.w),
              if (isEnded && !isArchived && subCount > 0)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.error.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.assignment_late_rounded,
                        color: Theme.of(context).colorScheme.error,
                        size: 10.sp,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'للمراجعة',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Theme.of(context).colorScheme.error,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                )
              else if (isEnded)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    'مغلق',
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 14.h),
          Container(
            height: 1,
            color:
                (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              _buildIconText(
                Icons.people_outline,
                '$subCount تسليم',
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const Spacer(),
              _buildIconText(
                Icons.grade_outlined,
                '$maxScore درجة',
                Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              const Spacer(),
              _buildIconText(
                Icons.calendar_today_outlined,
                _formatDate(dueDate),
                isEnded ? Theme.of(context).colorScheme.error : Colors.green,
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: GlassCard(
                  onTap: onOpenDetails,
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  borderRadius: 10.r,
                  color: Colors.white.withValues(alpha: 0.05),
                  borderColor:
                      (Theme.of(context).dividerTheme.color ??
                      Colors.grey.shade300),
                  child: Center(
                    child: Text(
                      'التفاصيل / تعديل',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              GlassCard(
                onTap: onShowMoreOptions,
                padding: EdgeInsets.all(8.w),
                borderRadius: 10.r,
                color: Colors.white.withValues(alpha: 0.05),
                child: Icon(
                  Icons.more_horiz,
                  size: 18.sp,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
