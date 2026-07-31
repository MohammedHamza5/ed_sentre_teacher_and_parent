import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Filter chips for exam review screen (all, correct, wrong, unanswered).
class ExamReviewFilterChips extends StatelessWidget {
  final String activeFilter;
  final int totalCount;
  final int correctCount;
  final int wrongCount;
  final int unansweredCount;
  final ValueChanged<String> onFilterChanged;

  const ExamReviewFilterChips({
    super.key,
    required this.activeFilter,
    required this.totalCount,
    required this.correctCount,
    required this.wrongCount,
    required this.unansweredCount,
    required this.onFilterChanged,
  });

  Widget _buildPremiumChip({
    required IconData icon,
    required String label,
    required Color color,
    required String filterType,
  }) {
    final bool isActive = activeFilter == filterType;
    return GestureDetector(
      onTap: () => onFilterChanged(filterType),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isActive
              ? color.withValues(alpha: 0.2)
              : const Color(0xFF1E293B).withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isActive ? color : color.withValues(alpha: 0.2),
            width: isActive ? 2.0 : 1.0,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18.sp, color: isActive ? color : Colors.white54),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white70,
                fontSize: 13.sp,
                fontWeight: isActive ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildPremiumChip(
              icon: Icons.list_alt_rounded,
              label: 'الكل ($totalCount)',
              color: Theme.of(context).colorScheme.primary,
              filterType: 'all',
            ),
            SizedBox(width: 8.w),
            _buildPremiumChip(
              icon: Icons.check_circle_rounded,
              label: '$correctCount صحيح',
              color: Colors.green,
              filterType: 'correct',
            ),
            SizedBox(width: 8.w),
            _buildPremiumChip(
              icon: Icons.cancel_rounded,
              label: '$wrongCount خطأ',
              color: Theme.of(context).colorScheme.error,
              filterType: 'wrong',
            ),
            SizedBox(width: 8.w),
            _buildPremiumChip(
              icon: Icons.hourglass_empty_rounded,
              label: '$unansweredCount لم يُجب',
              color: const Color(0xFF94A3B8),
              filterType: 'unanswered',
            ),
          ],
        ),
      ),
    );
  }
}
