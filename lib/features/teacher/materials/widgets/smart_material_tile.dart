import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
// Removed AppColors import

class SmartMaterialTile extends StatelessWidget {
  final Map<String, dynamic> material;
  final VoidCallback onTap;
  final Function(String) onMenuAction;

  const SmartMaterialTile({
    super.key,
    required this.material,
    required this.onTap,
    required this.onMenuAction,
  });

  @override
  Widget build(BuildContext context) {
    final title = material['title'] ?? 'بدون عنوان';
    final type = material['file_type'] ?? 'document';
    final course = material['course_name'] ?? 'عام';
    final views = material['download_count'] ?? 0;
    final isPublished = material['is_published'] ?? true;

    Color color;
    IconData icon;

    switch (type) {
      case 'pdf':
        color = const Color(0xFFFF5252);
        icon = Icons.picture_as_pdf_rounded;
        break;
      case 'video':
        color = const Color(0xFFFF9800);
        icon = Icons.play_circle_fill_rounded;
        break;
      case 'image':
        color = const Color(0xFF9C27B0);
        icon = Icons.image_rounded;
        break;
      case 'link':
        color = const Color(0xFF2196F3);
        icon = Icons.link_rounded;
        break;
      default:
        color = const Color(0xFF607D8B);
        icon = Icons.insert_drive_file_rounded;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Preview / Icon Area
            Expanded(
              flex: 3,
              child: Container(
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(16.r),
                  ),
                ),
                child: Center(
                  child: Icon(icon, size: 48.sp, color: color),
                ),
              ),
            ),

            // Info Area
            Expanded(
              flex: 2,
              child: Padding(
                padding: EdgeInsets.all(10.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          course,
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.remove_red_eye_outlined,
                              size: 12.sp,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            SizedBox(width: 4.w),
                            Text(
                              '$views',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                        // Menu
                        SizedBox(
                          width: 24.w,
                          height: 24.w,
                          child: PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            icon: Icon(
                              Icons.more_horiz,
                              size: 18.sp,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            onSelected: onMenuAction,
                            itemBuilder: (c) => [
                              PopupMenuItem(
                                value: 'share',
                                child: Text('مشاركة'),
                              ),
                              PopupMenuItem(
                                value: 'toggle_publish',
                                child: Text(isPublished ? 'إخفاء' : 'نشر'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text(
                                  'حذف',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
