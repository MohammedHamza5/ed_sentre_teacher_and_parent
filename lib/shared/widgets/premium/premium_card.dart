import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final Color? backgroundColor;
  final Gradient? gradient;
  final bool hasBorder;
  final bool hasGlow;
  final Color? glowColor;
  final VoidCallback? onTap;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.backgroundColor,
    this.gradient,
    this.hasBorder = true,
    this.hasGlow = false,
    this.glowColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.cardTheme.color ?? theme.colorScheme.surface;

    return Container(
      margin: margin ?? EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius ?? 20.r),
        boxShadow: hasGlow
            ? [
                BoxShadow(
                  color: (glowColor ?? theme.colorScheme.primary).withValues(
                    alpha: 0.2,
                  ),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius ?? 20.r),
          child: Container(
            padding: padding ?? EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: gradient == null ? (backgroundColor ?? cardColor) : null,
              gradient: gradient,
              borderRadius: BorderRadius.circular(borderRadius ?? 20.r),
              border: hasBorder
                  ? Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.15),
                    )
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
