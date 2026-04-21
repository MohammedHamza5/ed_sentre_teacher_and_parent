import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class IconContainer extends StatelessWidget {
  final IconData icon;
  final double? size;
  final Color? iconColor;
  final Color? backgroundColor;
  final Gradient? gradient;
  final double? padding;
  final double? borderRadius;

  const IconContainer({
    super.key,
    required this.icon,
    this.size,
    this.iconColor,
    this.backgroundColor,
    this.gradient,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.all(padding ?? 10.w),
      decoration: BoxDecoration(
        color: gradient == null
            ? (backgroundColor ??
                  theme.colorScheme.primary.withValues(alpha: 0.1))
            : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius ?? 12.r),
      ),
      child: Icon(
        icon,
        size: size ?? 22.sp,
        color: iconColor ?? theme.colorScheme.primary,
      ),
    );
  }
}
