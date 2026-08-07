import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../shared/widgets/premium_widgets.dart';
import '../utils/payment_utils.dart';

class TeacherPaymentsGroupBreakdown extends StatelessWidget {
  final Map<String, dynamic> salaryData;
  final bool isIndependent;

  const TeacherPaymentsGroupBreakdown({
    super.key,
    required this.salaryData,
    this.isIndependent = false,
  });

  @override
  Widget build(BuildContext context) {
    final salaryType = salaryData['salary_type'] ?? 'fixed';
    final items = salaryType == 'percentage'
        ? (salaryData['percentage_items'] as List? ?? [])
        : salaryType == 'per_session'
            ? (salaryData['sessions'] as List? ?? [])
            : [];

    if (items.isEmpty && salaryType == 'fixed') {
      // Fixed salary - show single card
      return _buildFixedSalarySection(context);
    }

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        SectionHeader(title: 'تفاصيل المجموعات', icon: Icons.groups_rounded),
        SizedBox(height: 16.h),
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value as Map<String, dynamic>;

          if (salaryType == 'percentage') {
            return _buildPercentageGroupCard(context, item, index);
          } else {
            return _buildSessionGroupCard(context, item, index);
          }
        }),
      ],
    );
  }

  Widget _buildFixedSalarySection(BuildContext context) {
    final baseSalary = (salaryData['base_salary'] as num?)?.toDouble() ?? 0;
    return Column(
      children: [
        SectionHeader(title: 'تفاصيل الراتب', icon: Icons.receipt_long_rounded),
        SizedBox(height: 16.h),
        PremiumCard(
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Colors.white,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'راتب ثابت شهري',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      'يُصرف شهرياً بغض النظر عن التحصيل',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${formatCurrency(baseSalary)} ج.م',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF4CAF50),
                ),
              ),
            ],
          ),
        ).animate().fadeIn().slideX(begin: 0.1),
      ],
    );
  }

  Widget _buildPercentageGroupCard(BuildContext context, Map<String, dynamic> item, int index) {
    final groupName = item['group'] ?? 'مجموعة';
    final students = (item['students'] as num?)?.toInt() ?? 0;
    final collected = (item['collected'] as num?)?.toDouble() ?? 0;
    final percentage = (item['percentage'] as num?)?.toDouble() ?? 0;
    final teacherTotal = (item['total'] as num?)?.toDouble() ?? 0;
    final centerTotal = (item['center_share'] as num?)?.toDouble() ?? 0;
    final expectedTeacherTotal = (item['expected_total'] as num?)?.toDouble() ?? teacherTotal;

    return PremiumCard(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group Header
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  Icons.groups_rounded,
                  color: Colors.white,
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  groupName,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  '$students طالب',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // Revenue Progress Bar
          if (isIndependent)
            _buildRevenueBar(
              context, 
              collected, 
              expectedTeacherTotal > collected ? expectedTeacherTotal - collected : 0,
            )
          else
            _buildRevenueBar(context, teacherTotal, centerTotal),

          SizedBox(height: 16.h),

          // Details Row
          Row(
            children: [
              _buildDetailChip(
                context,
                'المحصّل',
                '${formatCurrency(collected)} ج.م',
                Theme.of(context).colorScheme.primary,
              ),
              SizedBox(width: 6.w),
              _buildDetailChip(
                context,
                'نصيبك (${percentage.toInt()}%)',
                '${formatCurrency(teacherTotal)} ج.م',
                Colors.green,
              ),
              SizedBox(width: 6.w),
              isIndependent
                  ? _buildDetailChip(
                      context,
                      'متبقي لم يُحصّل',
                      '${formatCurrency(expectedTeacherTotal > collected ? expectedTeacherTotal - collected : 0)} ج.م',
                      Colors.orange.shade600,
                    )
                  : _buildDetailChip(
                      context,
                      'السنتر',
                      '${formatCurrency(centerTotal)} ج.م',
                      Theme.of(context).colorScheme.error,
                    ),
            ],
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: 100 * index)).fadeIn().slideX(begin: 0.1);
  }

  Widget _buildRevenueBar(BuildContext context, double teacherShare, double centerShare) {
    final total = teacherShare + centerShare;
    final teacherRatio = total > 0 ? teacherShare / total : 0.0;

    return Column(
      children: [
        // Labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 10.w,
                  height: 10.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ),
                SizedBox(width: 6.w),
                Text(
                  isIndependent ? 'المحصل' : 'نصيبك',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Container(
                  width: 10.w,
                  height: 10.w,
                  decoration: BoxDecoration(
                    color: isIndependent ? Colors.orange.shade600 : Theme.of(context).colorScheme.error,
                    borderRadius: BorderRadius.circular(3.r),
                  ),
                ),
                SizedBox(width: 6.w),
                Text(
                  isIndependent ? 'المتبقي' : 'السنتر',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
        SizedBox(height: 8.h),
        // Progress
        ClipRRect(
          borderRadius: BorderRadius.circular(6.r),
          child: SizedBox(
            height: 10.h,
            child: Row(
              children: [
                Expanded(
                  flex: (teacherRatio * 100).toInt().clamp(1, 99),
                  child: Container(
                    decoration: const BoxDecoration(color: Colors.green),
                  ),
                ),
                Expanded(
                  flex: ((1 - teacherRatio) * 100).toInt().clamp(1, 99),
                  child: Container(
                    decoration: BoxDecoration(
                      color: isIndependent ? Colors.orange.shade600 : Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSessionGroupCard(BuildContext context, Map<String, dynamic> item, int index) {
    final groupName = item['group'] ?? 'مجموعة';
    final count = (item['count'] as num?)?.toInt() ?? 0;
    final rate = (item['rate'] as num?)?.toDouble() ?? 0;
    final total = (item['total'] as num?)?.toDouble() ?? 0;

    return PremiumCard(
      margin: EdgeInsets.only(bottom: 12.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Column(
              children: [
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'حصة',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  groupName,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'سعر الحصة: ${formatCurrency(rate)} ج.م',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${formatCurrency(total)} ج.م',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF4CAF50),
            ),
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: 100 * index)).fadeIn().slideX(begin: 0.1);
  }

  Widget _buildDetailChip(BuildContext context, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10.sp,
                color: color.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 2.h),
            FittedBox(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
