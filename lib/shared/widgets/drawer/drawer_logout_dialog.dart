import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_colors.dart';
import '../../../features/auth/provider/auth_provider.dart';

/// Centralized logout dialog for the drawer
Future<void> confirmDrawerLogout(BuildContext context, AuthProvider auth) async {
  final scaffoldState = Scaffold.maybeOf(context);
  if (scaffoldState?.isDrawerOpen == true) {
    Navigator.of(context).pop(); // close drawer first
    await Future.delayed(const Duration(milliseconds: 300));
  }

  if (!context.mounted) return;

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
      child: AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
          side: BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: AppColors.errorSoft,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                Icons.logout_rounded,
                color: AppColors.error,
                size: 22.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              'تسجيل الخروج',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'هل أنت متأكد من تسجيل الخروج من الحساب؟',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize: 14.sp,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'إلغاء',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 14.sp,
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(left: 8.w, bottom: 4.h),
            child: ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: 20.w,
                  vertical: 10.h,
                ),
              ),
              child: Text(
                'تسجيل الخروج',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  if (confirmed == true && context.mounted) {
    await auth.signOut();
    if (context.mounted) {
      GoRouter.of(context).go('/login');
    }
  }
}
