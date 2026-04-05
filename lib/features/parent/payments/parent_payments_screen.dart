import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../core/config/app_colors.dart';

import '../provider/parent_provider.dart';
import '../../../shared/models/models.dart';

class ParentPaymentsScreen extends StatefulWidget {
  const ParentPaymentsScreen({super.key});

  @override
  State<ParentPaymentsScreen> createState() => _ParentPaymentsScreenState();
}

class _ParentPaymentsScreenState extends State<ParentPaymentsScreen> {
  bool _isLoading = true;
  List<PaymentModel> _payments = [];

  // Premium colors
  static const _paidColor = AppColors.emeraldGreen;
  static const _pendingColor = AppColors.warningAmber;
  static const _overdueColor = AppColors.errorRed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final parentProvider = context.read<ParentProvider>();
    if (parentProvider.selectedChild != null &&
        parentProvider.selectedCenter != null) {
      final payments = await parentProvider.getChildPayments();
      if (mounted) {
        setState(() {
          _payments = payments;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalDue = _payments
        .where((p) => p.status != PaymentStatus.paid)
        .fold<double>(0, (sum, p) => sum + p.amount);
    final totalPaid = _payments
        .where((p) => p.status == PaymentStatus.paid)
        .fold<double>(0, (sum, p) => sum + p.amount);

    return Scaffold(
      backgroundColor: AppColors.forestDeep,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accentVivid),
            )
          : CustomScrollView(
              slivers: [
                // Premium Header
                SliverToBoxAdapter(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: AppColors.premiumSunset,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(32.r),
                        bottomRight: Radius.circular(32.r),
                      ),
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 30.h),
                        child: Column(
                          children: [
                            // Title (centered, no back button)
                            Text(
                              'المدفوعات',
                              style: TextStyle(
                                fontSize: 22.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDisplay,
                              ),
                            ),
                            SizedBox(height: 24.h),

                            // Balance Display
                            Container(
                              padding: EdgeInsets.all(24.w),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(24.r),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Column(
                                    children: [
                                      Icon(
                                        Icons.account_balance_wallet,
                                        color: AppColors.textDisplay,
                                        size: 36.sp,
                                      ),
                                      SizedBox(height: 8.h),
                                      Text(
                                        '${totalDue.toStringAsFixed(0)} ج.م',
                                        style: TextStyle(
                                          fontSize: 28.sp,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textDisplay,
                                        ),
                                      ),
                                      Text(
                                        'المستحقات المتبقية',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: AppColors.textDisplay.withValues(
                                            alpha: 0.9,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    width: 1,
                                    height: 80.h,
                                    color: AppColors.textDisplay.withValues(alpha: 0.3),
                                  ),
                                  Column(
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline,
                                        color: AppColors.textDisplay,
                                        size: 36.sp,
                                      ),
                                      SizedBox(height: 8.h),
                                      Text(
                                        '${totalPaid.toStringAsFixed(0)} ج.م',
                                        style: TextStyle(
                                          fontSize: 28.sp,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textDisplay,
                                        ),
                                      ),
                                      Text(
                                        'المدفوع',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          color: AppColors.textDisplay.withValues(
                                            alpha: 0.9,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ).animate().fadeIn().scale(delay: 200.ms),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // Payments List
                SliverPadding(
                  padding: EdgeInsets.all(16.w),
                  sliver: SliverToBoxAdapter(
                    child: Text(
                      'سجل المدفوعات',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDisplay,
                      ),
                    ),
                  ),
                ),

                if (_payments.isEmpty)
                  SliverPadding(
                    padding: EdgeInsets.all(16.w),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        padding: EdgeInsets.all(32.w),
                        decoration: BoxDecoration(
                          color: AppColors.darkSurface,
                          borderRadius: BorderRadius.circular(20.r),
                          border: Border.all(color: AppColors.darkBorder),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.receipt_long_outlined,
                              size: 48.sp,
                              color: AppColors.textMuted,
                            ),
                            SizedBox(height: 12.h),
                            Text(
                              'لا توجد مدفوعات مسجلة لابنك',
                              style: TextStyle(
                                fontSize: 16.sp,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 16.w),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) =>
                            _buildPaymentCard(_payments[index], index),
                        childCount: _payments.length,
                      ),
                    ),
                  ),

                SliverPadding(padding: EdgeInsets.only(bottom: 100.h)),
              ],
            ),
    );
  }

  Widget _buildPaymentCard(PaymentModel payment, int index) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (payment.status) {
      case PaymentStatus.paid:
        statusColor = _paidColor;
        statusIcon = Icons.check_circle;
        statusText = 'مدفوع';
        break;
      case PaymentStatus.pending:
        statusColor = _pendingColor;
        statusIcon = Icons.schedule;
        statusText = 'معلق';
        break;
      case PaymentStatus.overdue:
        statusColor = _overdueColor;
        statusIcon = Icons.error_outline;
        statusText = 'متأخر';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
        statusText = 'غير محدد';
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.darkSurface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.darkBorder),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(statusIcon, color: statusColor, size: 24.sp),
          ),
          SizedBox(width: 14.w),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.monthYear ?? payment.courseName ?? 'رسوم دراسية',
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDisplay,
                  ),
                ),
                SizedBox(height: 4.h),
                if (payment.paymentDate != null)
                  Text(
                    'تاريخ الدفع: ${DateFormat('dd/MM/yyyy').format(payment.paymentDate!)}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.textMuted,
                    ),
                  ),
              ],
            ),
          ),

          // Amount & Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${payment.amount.toStringAsFixed(0)} ج.م',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDisplay,
                ),
              ),
              SizedBox(height: 4.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.05);
  }
}
