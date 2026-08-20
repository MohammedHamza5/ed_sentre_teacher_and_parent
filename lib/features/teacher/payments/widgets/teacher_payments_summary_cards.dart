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
    final grossPreview =
        (salaryData['gross_preview'] as num?)?.toDouble() ?? 0;
    final expectedGrossPreview =
        (salaryData['expected_gross_preview'] as num?)?.toDouble() ??
            grossPreview;
    final salaryType = salaryData['salary_type'] ?? 'fixed';
    final percentage =
        (salaryData['salary_percentage'] as num?)?.toDouble() ?? 0;
    final baseSalary =
        (salaryData['base_salary'] as num?)?.toDouble() ?? 0;

    // Calculate total collected & center share across all groups
    double totalCollected = 0;
    double centerShare = 0;
    final percentageItems =
        salaryData['percentage_items'] as List? ?? [];
    for (var item in percentageItems) {
      totalCollected += (item['collected'] as num?)?.toDouble() ?? 0;
      centerShare += (item['center_share'] as num?)?.toDouble() ?? 0;
    }
    if (isIndependent) centerShare = 0;

    // Hero = expected (what teacher should earn). For fixed = the fixed salary.
    final heroAmount =
        salaryType == 'fixed' ? baseSalary : expectedGrossPreview;
    final collectedAmount = grossPreview; // actually collected so far

    // Progress: how much of expected has been collected
    final collectProgress =
        (heroAmount > 0) ? (collectedAmount / heroAmount).clamp(0.0, 1.0) : 0.0;
    final remainingAmount =
        (heroAmount - collectedAmount).clamp(0.0, double.infinity);

    return Column(
      children: [
        // ── Hero Card ────────────────────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              // Label
              Text(
                salaryType == 'fixed'
                    ? 'راتبك الثابت هذا الشهر'
                    : isIndependent
                        ? 'إجمالي إيراداتك المتوقعة'
                        : 'نصيبك المتوقع هذا الشهر',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              SizedBox(height: 8.h),
              // Hero amount
              Text(
                '${formatCurrency(heroAmount)} ج.م',
                style: TextStyle(
                  fontSize: 36.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              SizedBox(height: 6.h),
              // Badge
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  salaryType == 'independent'
                      ? 'إيراداتك الكاملة (مستقل 100%)'
                      : salaryType == 'percentage'
                          ? 'نسبة ${percentage.toInt()}% من التحصيل'
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

              // ── Collection Progress (for non-fixed types) ─────────────────
              if (salaryType != 'fixed') ...[
                SizedBox(height: 20.h),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.r),
                  child: LinearProgressIndicator(
                    value: collectProgress,
                    minHeight: 8.h,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF4CAF50)),
                  ),
                ),
                SizedBox(height: 10.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'محصّل حتى الآن',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                        Text(
                          '${formatCurrency(collectedAmount)} ج.م',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF81C784),
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'متبقي لم يُحصّل',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                        Text(
                          '${formatCurrency(remainingAmount)} ج.م',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade200,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ),
        ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),

        SizedBox(height: 16.h),

        // ── Secondary Stats ──────────────────────────────────────────────────
        if (salaryType == 'percentage' || salaryType == 'independent') ...[
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  title: 'إجمالي تحصيل الطلاب',
                  value: formatCurrency(totalCollected),
                  icon: Icons.payments_rounded,
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: isIndependent
                    ? _buildStatCard(
                        context,
                        title: 'لم يُسدَّد بعد',
                        value: formatCurrency(remainingAmount),
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
                            Theme.of(context)
                                .colorScheme
                                .error
                                .withValues(alpha: 0.8),
                          ],
                        ),
                      ),
              ),
            ],
          ).animate(delay: 100.ms).fadeIn().slideY(begin: 0.1),
        ],

        // ── Fixed Salary Info ────────────────────────────────────────────────
        if (salaryType == 'fixed') ...[
          Container(
            width: double.infinity,
            padding:
                EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 18.sp,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5)),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    'راتبك الثابت يُصرف شهرياً من المركز بغض النظر عن تحصيل الطلاب.',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.65),
                    ),
                  ),
                ),
              ],
            ),
          ).animate(delay: 100.ms).fadeIn(),
        ],
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Gradient gradient,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ??
            Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.08)),
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
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.7),
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
