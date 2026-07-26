import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/config/app_colors.dart';

/// Animated daily usage monitor card.
class AIDailyUsagePulse extends StatelessWidget {
  final int used;
  final int limit;
  final Animation<double> pulseAnimation;

  const AIDailyUsagePulse({
    super.key,
    required this.used,
    this.limit = 5,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final remaining = (limit - used).clamp(0, limit);
    final progress = used / limit;

    // Dynamic color based on remaining
    final Color statusColor;
    final String statusText;
    final IconData statusIcon;

    if (remaining == 0) {
      statusColor = AppColors.error;
      statusText = 'اكتمل حدك اليومي — عد غداً!';
      statusIcon = Icons.hourglass_empty_rounded;
    } else if (remaining <= 2) {
      statusColor = AppColors.warning;
      statusText = 'باقي $remaining من $limit لهذا اليوم';
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusColor = const Color(0xFF8B5CF6);
      statusText = 'باقي $remaining من $limit لهذا اليوم';
      statusIcon = Icons.bolt_rounded;
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: AnimatedBuilder(
        animation: pulseAnimation,
        builder: (context, child) {
          final glowOpacity = 0.2 + (pulseAnimation.value * 0.15);

          return Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: statusColor.withValues(alpha: glowOpacity),
                  blurRadius: 20,
                  spreadRadius: -2,
                ),
              ],
            ),
            child: child,
          );
        },
        child: Column(
          children: [
            Row(
              children: [
                // Animated icon
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        statusColor,
                        statusColor.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    statusIcon,
                    color: Colors.white,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'الاستخدام اليومي',
                        style: TextStyle(
                          color: AppColors.textOnDark,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Count display
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '$remaining',
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: '/$limit',
                          style: TextStyle(
                            color: statusColor.withValues(alpha: 0.6),
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 14.h),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6.r),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return LinearProgressIndicator(
                    value: value,
                    minHeight: 6.h,
                    backgroundColor: (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300),
                    valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
