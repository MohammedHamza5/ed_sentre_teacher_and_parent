import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../shared/widgets/premium_widgets.dart';

class TeacherPaymentsMonthSelector extends StatelessWidget {
  final int selectedMonth;
  final int selectedYear;
  final void Function(int month, int year) onMonthChanged;

  const TeacherPaymentsMonthSelector({
    super.key,
    required this.selectedMonth,
    required this.selectedYear,
    required this.onMonthChanged,
  });

  @override
  Widget build(BuildContext context) {
    final months = [
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];

    return PremiumCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous month
          _buildMonthArrow(
            context,
            Icons.chevron_right_rounded,
            onTap: () {
              int newMonth = selectedMonth;
              int newYear = selectedYear;
              if (selectedMonth == 1) {
                newMonth = 12;
                newYear--;
              } else {
                newMonth--;
              }
              onMonthChanged(newMonth, newYear);
            },
          ),

          // Current month display
          Column(
            children: [
              Text(
                months[selectedMonth - 1],
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                '$selectedYear',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),

          // Next month
          _buildMonthArrow(
            context,
            Icons.chevron_left_rounded,
            onTap: () {
              int newMonth = selectedMonth;
              int newYear = selectedYear;
              if (selectedMonth == 12) {
                newMonth = 1;
                newYear++;
              } else {
                newMonth++;
              }
              onMonthChanged(newMonth, newYear);
            },
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildMonthArrow(BuildContext context, IconData icon, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurface,
          size: 24.sp,
        ),
      ),
    );
  }
}
