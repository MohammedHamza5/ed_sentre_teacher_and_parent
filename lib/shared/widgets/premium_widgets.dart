import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/config/app_colors.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PREMIUM WIDGETS - EdSentre Design System
/// ═══════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// GLASS CARD - Glassmorphism Effect
// ═══════════════════════════════════════════════════════════════════════════

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final Color? backgroundColor;
  final bool hasBorder;
  final double blur;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.backgroundColor,
    this.hasBorder = true,
    this.blur = 10,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius ?? 20.r),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(borderRadius ?? 20.r),
              child: Container(
                padding: padding ?? EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: backgroundColor ?? AppColors.glassWhite,
                  borderRadius: BorderRadius.circular(borderRadius ?? 20.r),
                  border: hasBorder
                      ? Border.all(color: AppColors.glassBorder)
                      : null,
                ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PREMIUM CARD - Elevated Dark Card
// ═══════════════════════════════════════════════════════════════════════════

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
    return Container(
      margin: margin ?? EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius ?? 20.r),
        boxShadow: hasGlow
            ? [
                BoxShadow(
                  color: (glowColor ?? AppColors.primary).withOpacity(0.2),
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
              color: gradient == null
                  ? (backgroundColor ?? AppColors.darkCard)
                  : null,
              gradient: gradient,
              borderRadius: BorderRadius.circular(borderRadius ?? 20.r),
              border: hasBorder
                  ? Border.all(color: AppColors.darkBorder.withOpacity(0.5))
                  : null,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GRADIENT BUTTON - Premium Button with Glow
// ═══════════════════════════════════════════════════════════════════════════

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Gradient? gradient;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final double? height;
  final double? fontSize;
  final bool hasGlow;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.gradient,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height,
    this.fontSize,
    this.hasGlow = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height ?? 56.h,
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: hasGlow
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(16.r),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 24.w,
                    height: 24.w,
                    child: const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, color: Colors.white, size: 22.sp),
                        SizedBox(width: 10.w),
                      ],
                      Text(
                        text,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: fontSize ?? 16.sp,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ANIMATED STAT CARD - Statistics with Animation
// ═══════════════════════════════════════════════════════════════════════════

class AnimatedStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Gradient? gradient;
  final Color? iconColor;
  final VoidCallback? onTap;
  final int animationDelay;

  const AnimatedStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.gradient,
    this.iconColor,
    this.onTap,
    this.animationDelay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
          onTap: onTap,
          hasGlow: true,
          glowColor: iconColor ?? AppColors.primary,
          padding: EdgeInsets.all(12.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon with gradient background
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  gradient: gradient ?? AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: Colors.white, size: 18.sp),
              ),
              SizedBox(height: 8.h),
              // Value
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textOnDark,
                    height: 1,
                  ),
                ),
              ),
              SizedBox(height: 2.h),
              // Title
              Text(
                title,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppColors.textOnDarkSecondary,
                  height: 1,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        )
        .animate(delay: Duration(milliseconds: animationDelay))
        .fadeIn(duration: 400.ms)
        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1));
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GLOWING ICON - Icon with Glow Effect
// ═══════════════════════════════════════════════════════════════════════════

class GlowingIcon extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color color;
  final double glowRadius;

  const GlowingIcon({
    super.key,
    required this.icon,
    this.size = 24,
    this.color = AppColors.primary,
    this.glowRadius = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.4),
            blurRadius: glowRadius,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Icon(icon, size: size, color: color),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ICON CONTAINER - Icon with Background
// ═══════════════════════════════════════════════════════════════════════════

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
    return Container(
      padding: EdgeInsets.all(padding ?? 10.w),
      decoration: BoxDecoration(
        color: gradient == null
            ? (backgroundColor ?? AppColors.primarySoft)
            : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius ?? 12.r),
      ),
      child: Icon(
        icon,
        size: size ?? 22.sp,
        color: iconColor ?? AppColors.primary,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SHIMMER LOADING - Skeleton Loading Effect
// ═══════════════════════════════════════════════════════════════════════════

class ShimmerLoading extends StatelessWidget {
  final double? width;
  final double? height;
  final double? borderRadius;

  const ShimmerLoading({super.key, this.width, this.height, this.borderRadius});

  @override
  Widget build(BuildContext context) {
    return Container(
          width: width ?? double.infinity,
          height: height ?? 20.h,
          decoration: BoxDecoration(
            color: AppColors.darkElevated,
            borderRadius: BorderRadius.circular(borderRadius ?? 8.r),
          ),
        )
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: 1500.ms,
          color: AppColors.darkBorder.withOpacity(0.3),
        );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SECTION HEADER - Title with Action
// ═══════════════════════════════════════════════════════════════════════════

class SectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final String? actionText;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.actionText,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: AppColors.primary, size: 22.sp),
                SizedBox(width: 10.w),
              ],
              Text(
                title,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textOnDark,
                ),
              ),
            ],
          ),
          if (onAction != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
                backgroundColor: AppColors.primarySoft,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              child: Text(
                actionText ?? 'عرض الكل',
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.1);
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EMPTY STATE - No Data Placeholder
// ═══════════════════════════════════════════════════════════════════════════

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.buttonText,
    this.onButtonPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(28.w),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.darkBorder.withOpacity(0.5),
                ),
              ),
              child: Icon(icon, size: 48.sp, color: AppColors.textOnDarkHint),
            ),
            SizedBox(height: 24.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.textOnDark,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: 12.h),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: AppColors.textOnDarkSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (buttonText != null && onButtonPressed != null) ...[
              SizedBox(height: 28.h),
              GradientButton(
                text: buttonText!,
                onPressed: onButtonPressed,
                width: 200.w,
                height: 48.h,
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9));
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FLOATING NAV BAR - Premium Bottom Navigation
// ═══════════════════════════════════════════════════════════════════════════

class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<FloatingNavItem> items;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: AppColors.darkBorder.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final isSelected = index == currentIndex;

          return GestureDetector(
            onTap: () => onTap(index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(
                horizontal: isSelected ? 20.w : 16.w,
                vertical: 10.h,
              ),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primarySoft : Colors.transparent,
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Row(
                children: [
                  Icon(
                    isSelected ? item.activeIcon : item.icon,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textOnDarkHint,
                    size: 24.sp,
                  ),
                  if (isSelected) ...[
                    SizedBox(width: 8.w),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class FloatingNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const FloatingNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// AVATAR WITH BORDER - Profile Avatar
// ═══════════════════════════════════════════════════════════════════════════

class AvatarWithBorder extends StatelessWidget {
  final String? imageUrl;
  final double radius;
  final Gradient? borderGradient;
  final double borderWidth;
  final IconData? placeholderIcon;

  const AvatarWithBorder({
    super.key,
    this.imageUrl,
    this.radius = 28,
    this.borderGradient,
    this.borderWidth = 2.5,
    this.placeholderIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(borderWidth),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: borderGradient ?? AppColors.primaryGradient,
      ),
      child: CircleAvatar(
        radius: radius.r,
        backgroundColor: AppColors.darkCard,
        backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
        child: imageUrl == null
            ? Icon(
                placeholderIcon ?? Icons.person,
                color: AppColors.textOnDarkSecondary,
                size: (radius * 0.9).sp,
              )
            : null,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STATUS BADGE - Colored Badge
// ═══════════════════════════════════════════════════════════════════════════

class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.text,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: color, size: 14.sp),
            SizedBox(width: 4.w),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// EXTENSIONS FOR ANIMATIONS
// ═══════════════════════════════════════════════════════════════════════════

extension PremiumAnimations on Widget {
  Widget animateFadeSlide({int delay = 0}) {
    return animate(
      delay: Duration(milliseconds: delay),
    ).fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }

  Widget animateScaleIn({int delay = 0}) {
    return animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: 300.ms)
        .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
  }

  Widget animateSlideRight({int delay = 0}) {
    return animate(
      delay: Duration(milliseconds: delay),
    ).fadeIn(duration: 400.ms).slideX(begin: 0.1, end: 0);
  }
}
