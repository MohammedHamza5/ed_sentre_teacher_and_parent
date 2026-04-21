import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/config/app_colors.dart';

class ExamPreviewQuestionView extends StatelessWidget {
  final int index;
  final Map<String, dynamic> question;
  final VoidCallback onDuplicate;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ExamPreviewQuestionView({
    super.key,
    required this.index,
    required this.question,
    required this.onDuplicate,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final options = (question['options'] as List?)?.cast<String>() ?? [];
    final correctIdx = question['correct_answer'] as int? ?? 0;
    final type = question['type']?.toString() ?? 'mcq';
    final explanation = question['explanation']?.toString() ?? '';

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: Icon(
                  Icons.drag_indicator,
                  color: AppColors.textOnDarkHint,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: Wrap(
                  spacing: 8.w,
                  runSpacing: 4.h,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        'سؤال ${index + 1}',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 6.w,
                        vertical: 2.h,
                      ),
                      decoration: BoxDecoration(
                        color: type.contains('true')
                            ? AppColors.warning.withValues(alpha: 0.15)
                            : AppColors.info.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                      child: Text(
                        type.contains('true') ? 'صح/خطأ' : 'اختيار',
                        style: TextStyle(
                          color: type.contains('true')
                              ? AppColors.warning
                              : AppColors.info,
                          fontSize: 10.sp,
                        ),
                      ),
                    ),
                    Text(
                      '${question['marks'] ?? 2} درجة',
                      style: TextStyle(
                        color: AppColors.textOnDarkHint,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
              // Actions
              IconButton(
                icon: Icon(
                  Icons.copy_rounded,
                  color: AppColors.info,
                  size: 20.sp,
                ),
                tooltip: 'استنساخ السؤال',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onDuplicate,
              ),
              SizedBox(width: 8.w),
              IconButton(
                icon: Icon(
                  Icons.edit_rounded,
                  color: AppColors.warning,
                  size: 20.sp,
                ),
                tooltip: 'تعديل',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onEdit,
              ),
              SizedBox(width: 8.w),
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                  size: 20.sp,
                ),
                tooltip: 'حذف',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onDelete,
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Question text
          Text(
            question['text']?.toString() ?? '',
            style: TextStyle(
              color: AppColors.textOnDark,
              fontSize: 14.sp,
              height: 1.5,
            ),
          ),
          SizedBox(height: 10.h),

          // Options
          ...options.asMap().entries.map((e) {
            final isCorrect = e.key == correctIdx;
            return Container(
              margin: EdgeInsets.only(bottom: 6.h),
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: isCorrect
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.darkInput,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: isCorrect
                      ? AppColors.success.withValues(alpha: 0.4)
                      : AppColors.darkBorder,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 24.w,
                    height: 24.w,
                    decoration: BoxDecoration(
                      color: isCorrect ? AppColors.success : Colors.transparent,
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(
                        color: isCorrect
                            ? AppColors.success
                            : AppColors.textOnDarkHint,
                      ),
                    ),
                    child: Center(
                      child: isCorrect
                          ? Icon(Icons.check, color: Colors.white, size: 14.sp)
                          : Text(
                              String.fromCharCode(65 + e.key),
                              style: TextStyle(
                                color: AppColors.textOnDarkHint,
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      e.value,
                      style: TextStyle(
                        color: isCorrect
                            ? AppColors.success
                            : AppColors.textOnDarkSecondary,
                        fontSize: 13.sp,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          // Explanation
          if (explanation.isNotEmpty) ...[
            SizedBox(height: 8.h),
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: AppColors.warning,
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      explanation,
                      style: TextStyle(
                        color: AppColors.textOnDarkSecondary,
                        fontSize: 12.sp,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
