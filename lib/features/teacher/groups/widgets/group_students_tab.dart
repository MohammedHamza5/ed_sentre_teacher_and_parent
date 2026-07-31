import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../core/widgets/genius/glass_card.dart';

/// Students list tab for group details screen.
class GroupStudentsTab extends StatelessWidget {
  final List<Map<String, dynamic>> students;

  const GroupStudentsTab({super.key, required this.students});

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline_rounded,
              size: 64.sp,
              color:
                  (Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey)
                      .withValues(alpha: 0.5),
            ),
            SizedBox(height: 16.h),
            Text(
              'لا يوجد طلاب',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'لم ينضم أي طالب لهذه المجموعة بعد',
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
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        final name = student['student_name'] as String? ?? 'طالب';
        final phone = student['student_phone'] as String? ?? '';
        final avatar = student['student_avatar'] as String?;
        final code = student['student_code'] as String?;
        return Padding(
          padding: EdgeInsets.only(bottom: 14.h),
          child:
              GlassCard(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0.7),
                    padding: EdgeInsets.all(16.w),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(2.w),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  (Theme.of(context).dividerTheme.color ??
                                  Colors.grey.shade300),
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 24.r,
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.surface,
                            child: avatar != null
                                ? ClipOval(
                                    child: CachedNetworkImage(
                                      imageUrl: avatar,
                                      width: 48.r,
                                      height: 48.r,
                                      fit: BoxFit.cover,
                                      errorWidget: (_, __, ___) => Icon(
                                        Icons.person_rounded,
                                        color:
                                            (Theme.of(
                                              context,
                                            ).textTheme.bodySmall?.color ??
                                            Colors.grey),
                                      ),
                                    ),
                                  )
                                : Text(
                                    name.isNotEmpty ? name[0] : 'ط',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface,
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16.sp,
                                ),
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                phone.isNotEmpty ? phone : '—',
                                style: TextStyle(
                                  color:
                                      (Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.color ??
                                      Colors.grey),
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (code != null && code.isNotEmpty) ...[
                                SizedBox(height: 2.h),
                                Text(
                                  'كود: $code',
                                  style: TextStyle(
                                    color:
                                        (Theme.of(
                                                  context,
                                                ).textTheme.bodySmall?.color ??
                                                Colors.grey)
                                            .withValues(alpha: 0.7),
                                    fontSize: 12.sp,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 6.h,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: Colors.green.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            'نشط',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate(delay: Duration(milliseconds: 50 * index))
                  .fadeIn()
                  .slideX(),
        );
      },
    );
  }
}
