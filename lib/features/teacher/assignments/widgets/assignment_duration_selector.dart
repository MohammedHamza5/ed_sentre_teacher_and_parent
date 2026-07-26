import 'package:ed_sentre_techer_and_parent/core/config/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Widget for selecting exam duration with preset chips and manual input.
class AssignmentDurationSelector extends StatelessWidget {
  final Color typeColor;
  final TextEditingController durationController;

  const AssignmentDurationSelector({
    super.key,
    required this.typeColor,
    required this.durationController,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300).withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer, color: typeColor),
              SizedBox(width: 8.w),
              Text(
                'مدة الامتحان *',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _DurationChip(
                  minutes: 30,
                  typeColor: typeColor,
                  controller: durationController,
                ),
                SizedBox(width: 8.w),
                _DurationChip(
                  minutes: 45,
                  typeColor: typeColor,
                  controller: durationController,
                ),
                SizedBox(width: 8.w),
                _DurationChip(
                  minutes: 60,
                  typeColor: typeColor,
                  controller: durationController,
                ),
                SizedBox(width: 8.w),
                _DurationChip(
                  minutes: 90,
                  typeColor: typeColor,
                  controller: durationController,
                ),
              ],
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: durationController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'أو أدخل عدد مخصص',
                    hintStyle: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
                    suffixText: 'دقيقة',
                    suffixStyle: TextStyle(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.7),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: BorderSide(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withValues(alpha: 0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.r),
                      borderSide: BorderSide(color: typeColor),
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 12.h,
                    ),
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

class _DurationChip extends StatelessWidget {
  final int minutes;
  final Color typeColor;
  final TextEditingController controller;

  const _DurationChip({
    required this.minutes,
    required this.typeColor,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = controller.text == minutes.toString();

    return ChoiceChip(
      label: Text('$minutes د'),
      selected: isSelected,
      onSelected: (v) {
        controller.text = minutes.toString();
      },
      selectedColor: typeColor.withValues(alpha: 0.2),
      backgroundColor: Theme.of(context).colorScheme.surface,
      side: BorderSide(
        color: isSelected
            ? typeColor
            : (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300).withValues(alpha: 0.5),
      ),
      labelStyle: TextStyle(
        color: isSelected
            ? typeColor
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
      ),
    );
  }
}
