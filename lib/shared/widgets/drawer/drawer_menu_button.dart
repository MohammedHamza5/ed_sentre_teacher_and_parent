import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../app_drawer.dart';

class DrawerMenuButton extends StatelessWidget {
  final bool isTeacher;
  final Color? color;

  const DrawerMenuButton({super.key, required this.isTeacher, this.color});

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Colors.white;

    return GestureDetector(
      onTap: isTeacher ? openTeacherDrawer : openParentDrawer,
      child: Container(
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: effectiveColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: effectiveColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _Bar(width: 22, color: effectiveColor),
            SizedBox(height: 5.h),
            _Bar(
              width: 14,
              color: effectiveColor.withValues(alpha: 0.8),
            ),
            SizedBox(height: 5.h),
            _Bar(width: 22, color: effectiveColor),
          ],
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double width;
  final Color? color;
  const _Bar({required this.width, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width.w,
      height: 2.h,
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(2.r),
      ),
    );
  }
}
