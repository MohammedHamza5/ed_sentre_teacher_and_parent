import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/config/app_colors.dart';

class AttendanceMonitorTile extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final String code;
  final String status; // 'present', 'absent', 'late', 'excused', 'pending'
  final VoidCallback? onTap;

  const AttendanceMonitorTile({
    super.key,
    required this.name,
    this.avatarUrl,
    required this.code,
    required this.status,
    this.onTap,
  });

  bool get isPresent => status == 'present' || status == 'late';
  bool get isPending => status == 'pending';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: isPresent
              ? AppColors.success.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isPresent
                ? AppColors.success
                : Colors.transparent, // Clean look for pending
            width: 2.w,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Status Indicator (Corner Pulse)
            if (isPresent)
              Positioned(
                top: 8.h,
                right: 8.w,
                child:
                    Container(
                          width: 10.w,
                          height: 10.w,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                        )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .scale(
                          begin: const Offset(1, 1),
                          end: const Offset(1.5, 1.5),
                          duration: 1.seconds,
                        )
                        .fadeOut(begin: 0.5),
              ),

            Padding(
              padding: EdgeInsets.all(8.r),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Avatar
                  Container(
                    width: 40.w,
                    height: 40.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.surface,
                      border: Border.all(
                        color: isPresent
                            ? AppColors.success
                            : AppColors.primary.withValues(alpha: 0.2),
                        width: 2.w,
                      ),
                      image: avatarUrl != null
                          ? DecorationImage(
                              image: NetworkImage(avatarUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: avatarUrl == null
                        ? Icon(
                            Icons.person,
                            color: AppColors.textHint,
                            size: 20.sp,
                          )
                        : null,
                  ),
                  SizedBox(height: 6.h),

                  // Name
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: isPresent
                          ? AppColors.success
                          : AppColors.textPrimary,
                    ),
                  ),

                  SizedBox(height: 2.h),

                  // Code / Status Text
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: isPresent
                          ? AppColors.success.withValues(alpha: 0.2)
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Text(
                      isPresent ? 'حضور ✓' : '#$code',
                      style: TextStyle(
                        fontSize: 9.sp,
                        color: isPresent
                            ? AppColors.success
                            : AppColors.textHint,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
