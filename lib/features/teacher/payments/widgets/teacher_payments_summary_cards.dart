import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../utils/payment_utils.dart';

class TeacherPaymentsSummaryCards extends StatelessWidget {
  final Map<String, dynamic> salaryData;
  final bool isIndependent;

  const TeacherPaymentsSummaryCards({
    super.key,
    required this.salaryData,
    this.isIndependent = false,
  });

  @override
  Widget build(BuildContext context) {
    final grossPreview = (salaryData['gross_preview'] as num?)?.toDouble() ?? 0;
    final expectedGrossPreview = (salaryData['expected_gross_preview'] as num?)?.toDouble() ?? grossPreview;
    final salaryType = salaryData['salary_type'] ?? 'fixed';
    final percentage = (salaryData['salary_percentage'] as num?)?.toDouble() ?? 0;

    // Calculate total collected across all groups
    double totalCollected = 0;
    double centerShare = 0;
    final percentageItems = salaryData['percentage_items'] as List? ?? [];
    for (var item in percentageItems) {
      totalCollected += (item['collected'] as num?)?.toDouble() ?? 0;
      centerShare += (item['center_share'] as num?)?.toDouble() ?? 0;
    }
    if (isIndependent) centerShare = 0;

    return Column(
      children: [
        // Main Salary Card - Hero
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                isIndependent ? 'إجمالي الدخل المحصّل' : 'إجمالي نصيبك',
                style: TextStyle(
                  fontSize: 16.sp,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                '${formatCurrency(grossPreview)} ج.م',
                style: TextStyle(
                  fontSize: 36.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              if (salaryType == 'percentage') ...[
                SizedBox(height: 8.h),
                Text(
                  'المتوقع قبل التحصيل: ${formatCurrency(expectedGrossPreview)} ج.م',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  salaryType == 'percentage'
                      ? 'نسبة ${percentage.toInt()}%'
                      : salaryType == 'per_session'
                          ? 'بالحصة'
                          : 'راتب ثابت',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),

        SizedBox(height: 16.h),

        // Secondary Stats
        if (salaryType == 'percentage') ...[
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'إجمالي التحصيل',
                  value: formatCurrency(totalCollected),
                  icon: Icons.payments_rounded,
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: isIndependent
                    ? _buildStatCard(
                        context,
                        title: 'المتبقي لدى الطلاب',
                        value: formatCurrency(expectedGrossPreview - grossPreview),
                        icon: Icons.pending_actions_rounded,
                        gradient: LinearGradient(
                          colors: [
                            Colors.orange.shade700,
                            Colors.orange.shade600,
                          ],
                        ),
                      )
                    : _buildStatCard(
                        context,
                        title: 'نصيب السنتر',
                        value: formatCurrency(centerShare),
                        icon: Icons.account_balance_rounded,
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.error,
                            Theme.of(context).colorScheme.error.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
              ),
            ],
          ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1),
        ],
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Gradient gradient,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(icon, color: Colors.white, size: 18.sp),
          ),
          SizedBox(height: 12.h),
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '$value ج.م',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
