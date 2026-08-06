import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Interactive tool card for the AI tools grid.
class AIToolCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final LinearGradient gradient;
  final String tag;
  final bool isDisabled;
  final VoidCallback onTap;

  const AIToolCard({
    super.key,
    required this.icon,
    required this.label,
    required this.description,
    required this.gradient,
    required this.tag,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(18.r),
        splashColor: gradient.colors.first.withValues(alpha: 0.12),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isDisabled ? 0.4 : 1.0,
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(18.r),
              border: Border.all(
                color: isDisabled
                    ? (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300)
                    : gradient.colors.first.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Icon with gradient
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    gradient: isDisabled ? null : gradient,
                    color: isDisabled ? (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300) : null,
                    borderRadius: BorderRadius.circular(14.r),
                    boxShadow: isDisabled
                        ? null
                        : [
                            BoxShadow(
                              color: gradient.colors.first
                                  .withValues(alpha: 0.35),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                  ),
                  child: Icon(
                    icon,
                    color: isDisabled
                        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
                        : Colors.white,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 14.w),
                // Label & Description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                          color: isDisabled
                              ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                // Tag
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: isDisabled
                        ? (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300).withValues(alpha: 0.5)
                        : gradient.colors.first.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: isDisabled
                          ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
                          : gradient.colors.first,
                    ),
                  ),
                ),
                SizedBox(width: 4.w),
                Icon(
                  isDisabled ? Icons.lock_rounded : Icons.chevron_right,
                  color: isDisabled
                      ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
                      : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                  size: 18.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
