import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Widget for selecting due date and time for an assignment.
/// Includes quick-select chips and a custom date/time picker.
class AssignmentDateSelector extends StatelessWidget {
  final String type;
  final Color typeColor;
  final DateTime? dueDate;
  final TimeOfDay? dueTime;
  final ValueChanged<DateTime> onDueDateChanged;
  final ValueChanged<TimeOfDay> onDueTimeChanged;

  const AssignmentDateSelector({
    super.key,
    required this.type,
    required this.typeColor,
    required this.dueDate,
    required this.dueTime,
    required this.onDueDateChanged,
    required this.onDueTimeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300)
              .withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event, color: typeColor),
              SizedBox(width: 8.w),
              Text(
                type == 'exam' ? 'موعد الامتحان *' : 'موعد التسليم *',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),

          // Quick date options
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              _buildQuickDateChip(context, 'غداً', 1),
              _buildQuickDateChip(context, 'بعد 3 أيام', 3),
              _buildQuickDateChip(context, 'أسبوع', 7),
            ],
          ),
          SizedBox(height: 12.h),

          // Selected date display
          InkWell(
            onTap: () => _selectDate(context),
            child: Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: dueDate != null
                    ? typeColor.withValues(alpha: 0.1)
                    : Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(8.r),
                border: Border.all(
                  color: dueDate != null
                      ? typeColor
                      : Theme.of(
                          context,
                        ).colorScheme.outline.withValues(alpha: 0.5),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: dueDate != null
                        ? typeColor
                        : Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.7),
                    size: 20.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      dueDate != null
                          ? '${dueDate!.day}/${dueDate!.month}/${dueDate!.year}'
                          : 'اختر التاريخ',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: dueDate != null
                            ? Theme.of(context).colorScheme.onSurface
                            : Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  if (dueDate != null) ...[
                    GestureDetector(
                      onTap: () => _selectTime(context),
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
                          dueTime?.format(context) ?? '11:59 PM',
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

  Widget _buildQuickDateChip(BuildContext context, String label, int days) {
    final targetDate = DateTime.now().add(Duration(days: days));
    final isSelected =
        dueDate != null &&
        dueDate!.day == targetDate.day &&
        dueDate!.month == targetDate.month;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (v) {
        onDueDateChanged(targetDate);
        if (dueTime == null) {
          onDueTimeChanged(const TimeOfDay(hour: 23, minute: 59));
        }
      },
      selectedColor: typeColor.withValues(alpha: 0.2),
      backgroundColor: Theme.of(context).colorScheme.surface,
      side: BorderSide(
        color: isSelected
            ? typeColor
            : (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300)
                  .withValues(alpha: 0.5),
      ),
      labelStyle: TextStyle(
        color: isSelected
            ? typeColor
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final date = await showDatePicker(
      context: context,
      initialDate: dueDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      onDueDateChanged(date);
      if (dueTime == null) {
        onDueTimeChanged(const TimeOfDay(hour: 23, minute: 59));
      }
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final time = await showTimePicker(
      context: context,
      initialTime: dueTime ?? const TimeOfDay(hour: 23, minute: 59),
    );
    if (time != null) {
      onDueTimeChanged(time);
    }
  }
}
