import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/config/app_colors.dart';

class ExamPreviewQuestionEditor extends StatelessWidget {
  final int index;
  final Map<String, dynamic> question;
  final Map<String, TextEditingController> controllers;
  final int correctAnswerIndex;
  final ValueChanged<int> onCorrectAnswerChanged;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const ExamPreviewQuestionEditor({
    super.key,
    required this.index,
    required this.question,
    required this.controllers,
    required this.correctAnswerIndex,
    required this.onCorrectAnswerChanged,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final type = question['type']?.toString() ?? 'mcq';
    final optionsCount = type == 'true_false' ? 2 : 4;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppColors.warning, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note, color: AppColors.warning, size: 24.sp),
              SizedBox(width: 8.w),
              Text(
                'تعديل سؤال ${index + 1}',
                style: TextStyle(
                  color: AppColors.warning,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 60.w,
                child: TextField(
                  controller: controllers['marks'],
                  keyboardType: TextInputType.number,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 13.sp,
                  ),
                  decoration: InputDecoration(
                    labelText: 'الدرجة',
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                      fontSize: 11.sp,
                    ),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 8.h,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Question Text Edit
          TextField(
            controller: controllers['text'],
            maxLines: null,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14.sp),
            decoration: InputDecoration(
              labelText: 'نص السؤال',
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
          SizedBox(height: 12.h),

          // Options Edit
          Text(
            'حدد الإجابة الصحيحة واكتب الخيارات:',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 12.sp,
            ),
          ),
          SizedBox(height: 8.h),
          ...List.generate(optionsCount, (i) {
            final isCorrect = correctAnswerIndex == i;
            return Container(
              margin: EdgeInsets.only(bottom: 8.h),
              child: Row(
                children: [
                  Radio<int>(
                    value: i,
                    groupValue: correctAnswerIndex,
                    activeColor: AppColors.success,
                    fillColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppColors.success;
                      }
                      return Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);
                    }),
                    onChanged: (val) {
                      if (val != null) {
                        onCorrectAnswerChanged(val);
                      }
                    },
                  ),
                  Expanded(
                    child: TextField(
                      controller: controllers['opt_$i'],
                      style: TextStyle(
                        color: isCorrect
                            ? AppColors.success
                            : Theme.of(context).colorScheme.onSurface,
                        fontSize: 13.sp,
                      ),
                      decoration: InputDecoration(
                        hintText: 'الخيار ${i + 1}',
                        filled: true,
                        fillColor: isCorrect
                            ? AppColors.success.withValues(alpha: 0.1)
                            : Theme.of(context).colorScheme.surface,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 10.h,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: isCorrect
                              ? const BorderSide(color: AppColors.success)
                              : BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          // Explanation
          TextField(
            controller: controllers['explanation'],
            maxLines: 2,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 13.sp),
            decoration: InputDecoration(
              labelText: 'شرح الإجابة (اختياري)',
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
          ),
          SizedBox(height: 16.h),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: onCancel,
                child: Text(
                  'إلغاء',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)),
                ),
              ),
              SizedBox(width: 8.w),
              ElevatedButton.icon(
                onPressed: onSave,
                icon: Icon(Icons.check, color: Colors.white, size: 18),
                label: Text(
                  'حفظ التعديل',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
