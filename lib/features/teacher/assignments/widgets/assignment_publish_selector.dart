import 'package:ed_sentre_techer_and_parent/core/config/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Widget for selecting the publish date/time for an assignment.
/// Includes quick-select chips and a custom date/time picker.
class AssignmentPublishSelector extends StatelessWidget {
  final Color typeColor;
  final DateTime? publishDate;
  final TimeOfDay? publishTime;
  final ValueChanged<DateTime> onPublishDateChanged;
  final ValueChanged<TimeOfDay> onPublishTimeChanged;

  const AssignmentPublishSelector({
    super.key,
    required this.typeColor,
    required this.publishDate,
    required this.publishTime,
    required this.onPublishDateChanged,
    required this.onPublishTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: AppColors.glassBorderHighlight.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.visibility, color: typeColor),
              SizedBox(width: 8.w),
              Text(
                'موعد الظهور للطلاب',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDisplay,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _buildQuickChip(context, 'فوري', 0),
              _buildQuickChip(context, 'غداً', 1),
              _buildQuickChip(context, 'بعد 3 أيام', 3),
            ],
          ),
          SizedBox(height: 12.h),
          InkWell(
            onTap: () => _selectPublishDate(context),
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: publishDate != null
                    ? typeColor.withValues(alpha: 0.1)
                    : AppColors.darkSurface,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: publishDate != null
                      ? typeColor
                      : Theme.of(context)
                          .colorScheme
                          .outline
                          .withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.schedule,
                    color: publishDate != null
                        ? typeColor
                        : Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                    size: 20.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      publishDate != null
                          ? '${publishDate!.day}/${publishDate!.month}/${publishDate!.year}'
                          : 'اختر تاريخ الظهور',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: publishDate != null
                            ? AppColors.textDisplay
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  if (publishDate != null) ...[
                    GestureDetector(
                      onTap: () => _selectPublishTime(context),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          color: typeColor,
                          borderRadius: BorderRadius.circular(20.r),
                        ),
                        child: Text(
                          publishTime?.format(context) ?? 'الآن',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(BuildContext context, String label, int days) {
    final baseDate = DateTime.now().add(Duration(days: days));
    final targetDate = DateTime(baseDate.year, baseDate.month, baseDate.day);
    final isSelected = publishDate != null &&
        publishDate!.day == targetDate.day &&
        publishDate!.month == targetDate.month &&
        publishDate!.year == targetDate.year;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (v) {
        onPublishDateChanged(targetDate);
        if (days == 0) {
          onPublishTimeChanged(TimeOfDay.fromDateTime(DateTime.now()));
        } else {
          onPublishTimeChanged(const TimeOfDay(hour: 8, minute: 0));
        }
      },
      selectedColor: typeColor.withValues(alpha: 0.2),
      backgroundColor: AppColors.darkSurface,
      side: BorderSide(
        color: isSelected
            ? typeColor
            : AppColors.glassBorderHighlight.withValues(alpha: 0.5),
      ),
      labelStyle: TextStyle(
        color: isSelected
            ? typeColor
            : AppColors.textDisplay.withValues(alpha: 0.7),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Future<void> _selectPublishDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: publishDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 0)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      onPublishDateChanged(date);
      if (publishTime == null) {
        onPublishTimeChanged(const TimeOfDay(hour: 8, minute: 0));
      }
    }
  }

  Future<void> _selectPublishTime(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: publishTime ?? const TimeOfDay(hour: 8, minute: 0),
    );
    if (time != null) {
      onPublishTimeChanged(time);
    }
  }
}
