import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/theming/app_spacing.dart';

class AIExamCard extends StatelessWidget {
  final Map<String, dynamic> args;
  final VoidCallback onAction;

  const AIExamCard({super.key, required this.args, required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.navyCard,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.premiumRoyal.colors.first.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: AppColors.premiumRoyal.colors.first.withValues(alpha: 0.2),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
            ),
            child: Row(
              children: [
                Icon(Icons.assignment_turned_in_rounded, color: Colors.white, size: 20.sp),
                AppSpacing.gapW8,
                Text(
                  'امتحان مقترح',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.r),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  args['title'] ?? 'امتحان مراجعة',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                ),
                AppSpacing.gapH8,
                Text(
                  'الوحدة: ${args['unit'] ?? 'غير محدد'} | عدد الأسئلة: ${args['question_count'] ?? 10}',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.sp,
                  ),
                ),
                AppSpacing.gapH16,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildActionButton(Icons.send_rounded, 'إرسال للطلاب', AppColors.teal, onAction),
                    _buildActionButton(Icons.picture_as_pdf_rounded, 'حفظ PDF', AppColors.error, () {}),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.2),
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: BorderSide(color: color.withValues(alpha: 0.5)),
        ),
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
      ),
      icon: Icon(icon, size: 16.sp),
      label: Text(label, style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.bold)),
    );
  }
}
