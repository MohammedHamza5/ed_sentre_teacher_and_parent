import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/config/app_colors.dart';

/// Single item in the AI Knowledge Base list
class KnowledgeCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onDelete;

  const KnowledgeCard({
    super.key,
    required this.item,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (item['content_type']) {
      case 'textbook':
        icon = Icons.menu_book;
        color = Colors.blue;
        break;
      case 'notes':
        icon = Icons.note;
        color = Colors.orange;
        break;
      case 'exercises':
        icon = Icons.assignment;
        color = Colors.green;
        break;
      default:
        icon = Icons.insert_drive_file;
        color = Colors.grey;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: color, size: 24.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['title'] ?? 'بدون عنوان',
                  style: TextStyle(
                    color: AppColors.textOnDark,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    if (item['subject_name'] != null &&
                        item['subject_name'].toString().isNotEmpty) ...[
                      Text(
                        item['subject_name'],
                        style: TextStyle(
                          color: AppColors.textOnDarkSecondary,
                          fontSize: 11.sp,
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.symmetric(horizontal: 6.w),
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: AppColors.darkBorder,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                    Text(
                      _formatDate(item['created_at']),
                      style: TextStyle(
                        color: AppColors.textOnDarkHint,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.error),
            onPressed: onDelete,
            tooltip: 'حذف من القاعدة',
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateString) {
    if (dateString == null) return '';
    try {
      final date = DateTime.parse(dateString.toString());
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return '';
    }
  }
}
