import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../shared/widgets/premium_widgets.dart';
import '../utils/payment_utils.dart';

class TeacherPaymentsBonuses extends StatelessWidget {
  final List<dynamic> bonuses;
  final List<dynamic> deductions;

  const TeacherPaymentsBonuses({
    super.key,
    required this.bonuses,
    required this.deductions,
  });

  @override
  Widget build(BuildContext context) {
    if (bonuses.isEmpty && deductions.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SectionHeader(title: 'المكافآت والخصومات', icon: Icons.tune_rounded),
        SizedBox(height: 16.h),
        ...bonuses.map(
          (b) => _buildAdjustmentTile(
            context,
            b['description'] ?? 'مكافأة',
            (b['amount'] as num?)?.toDouble() ?? 0,
            isBonus: true,
          ),
        ),
        ...deductions.map(
          (d) => _buildAdjustmentTile(
            context,
            d['description'] ?? 'خصم',
            (d['amount'] as num?)?.toDouble() ?? 0,
            isBonus: false,
          ),
        ),
      ],
    );
  }

  Widget _buildAdjustmentTile(BuildContext context, String description, double amount, {required bool isBonus}) {
    return PremiumCard(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: (isBonus ? Colors.green : Theme.of(context).colorScheme.error)
                  .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              isBonus ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
              color: isBonus ? Colors.green : Theme.of(context).colorScheme.error,
              size: 20.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                fontSize: 14.sp,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            '${isBonus ? '+' : '-'}${formatCurrency(amount)} ج.م',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: isBonus ? Colors.green : Theme.of(context).colorScheme.error,
            ),
          ),
        ],
      ),
    ).animate().fadeIn();
  }
}
