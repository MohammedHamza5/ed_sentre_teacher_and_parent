import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/config/app_colors.dart';

/// ═══════════════════════════════════════════════════════════════════════════
/// PREMIUM PLUS WIDGETS - Enhanced Design System for Teachers
/// مكونات متميزة محسنة لنظام التصميم للمعلمين
/// ═══════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// GLASS MORPHISM CARD - Enhanced Glass Effect with Neon Border
// ═══════════════════════════════════════════════════════════════════════════

class GlassMorphismCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final Gradient? gradient;
  final Color? backgroundColor;
  final bool hasNeonBorder;
  final Color? neonColor;
  final double blurStrength;
  final VoidCallback? onTap;
  final int animationDelay;

  const GlassMorphismCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.gradient,
    this.backgroundColor,
    this.hasNeonBorder = false,
    this.neonColor,
    this.blurStrength = 15,
    this.onTap,
    this.animationDelay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
          margin: margin,
          decoration: hasNeonBorder
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(borderRadius ?? 24.r),
                  boxShadow: [
                    BoxShadow(
                      color: (neonColor ?? AppColors.primary).withOpacity(0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                )
              : null,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius ?? 24.r),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: blurStrength,
                sigmaY: blurStrength,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: backgroundColor,
                  gradient:
                      gradient ??
                      (backgroundColor == null
                          ? AppColors.glassGradient
                          : null),
                  borderRadius: BorderRadius.circular(borderRadius ?? 24.r),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.1),
                    width: hasNeonBorder ? 1.5 : 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(borderRadius ?? 24.r),
                    highlightColor: Colors.white.withOpacity(0.1),
                    splashColor: Colors.white.withOpacity(0.2),
                    child: Container(
                      padding: padding ?? EdgeInsets.all(20.w),
                      child: child,
                    ),
                  ),
                ),
              ),
            ),
          ),
        )
        .animate(delay: Duration(milliseconds: animationDelay))
        .fadeIn(duration: 500.ms)
        .scale(begin: const Offset(0.95, 0.95));
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PREMIUM STAT CARD - Enhanced Statistics with Interactive Effects
// ═══════════════════════════════════════════════════════════════════════════

class PremiumStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Gradient gradient;
  final Color? iconColor;
  final VoidCallback? onTap;
  final int animationDelay;
  final bool isInteractive;

  const PremiumStatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.gradient,
    this.iconColor,
    this.onTap,
    this.animationDelay = 0,
    this.isInteractive = true,
  });

  @override
  Widget build(BuildContext context) {
    return GlassMorphismCard(
      onTap: isInteractive ? onTap : null,
      padding: EdgeInsets.all(16.w),
      animationDelay: animationDelay,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon with gradient background
          Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(14.r),
                  boxShadow: AppColors.softGlow,
                ),
                child: Icon(icon, color: Colors.white, size: 22.sp),
              )
              .animate(delay: Duration(milliseconds: animationDelay + 100))
              .scale(),

          SizedBox(height: 16.h),

          // Value with animated counter effect
          Text(
                value,
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textOnDark,
                  height: 1,
                  fontFamily: 'Cairo',
                ),
              )
              .animate(delay: Duration(milliseconds: animationDelay + 200))
              .fadeIn()
              .slideY(begin: 0.1),

          SizedBox(height: 4.h),

          // Title
          Text(
            title,
            style: TextStyle(
              fontSize: 13.sp,
              color: AppColors.textOnDarkSecondary,
              fontWeight: FontWeight.w600,
              fontFamily: 'Cairo',
            ),
          ),

          if (subtitle != null) ...[
            SizedBox(height: 2.h),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 11.sp,
                color: AppColors.textOnDarkHint,
                fontFamily: 'Cairo',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FLOATING ACTION MENU - Premium Floating Action Button with Menu
// ═══════════════════════════════════════════════════════════════════════════

class FloatingActionMenu extends StatefulWidget {
  final IconData mainIcon;
  final List<FloatingActionItem> items;
  final Color? backgroundColor;
  final Color? iconColor;
  final double size;

  const FloatingActionMenu({
    super.key,
    required this.mainIcon,
    required this.items,
    this.backgroundColor,
    this.iconColor,
    this.size = 56,
  });

  @override
  State<FloatingActionMenu> createState() => _FloatingActionMenuState();
}

class _FloatingActionMenuState extends State<FloatingActionMenu> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isExpanded)
          ...widget.items.reversed.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: _buildActionItem(item, true),
            ),
          ),
        _buildMainButton(),
      ],
    );
  }

  Widget _buildMainButton() {
    return Container(
      width: widget.size.w,
      height: widget.size.h,
      decoration: BoxDecoration(
        gradient: AppColors.premiumOcean,
        shape: BoxShape.circle,
        boxShadow: AppColors.neonGlow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _toggleMenu,
          borderRadius: BorderRadius.circular(28.r),
          child: Icon(
            _isExpanded ? Icons.close : widget.mainIcon,
            color: Colors.white,
            size: 24.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildActionItem(FloatingActionItem item, bool isVisible) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: isVisible ? 48.w : 0,
      height: isVisible ? 48.h : 0,
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        shape: BoxShape.circle,
        boxShadow: AppColors.softGlow,
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            item.onTap();
            _toggleMenu();
          },
          borderRadius: BorderRadius.circular(24.r),
          child: Icon(item.icon, color: Colors.white, size: 20.sp),
        ),
      ),
    );
  }

  void _toggleMenu() {
    setState(() => _isExpanded = !_isExpanded);
  }
}

class FloatingActionItem {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const FloatingActionItem({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// PREMIUM SECTION HEADER - Enhanced with Interactive Actions
// ═══════════════════════════════════════════════════════════════════════════

class PremiumSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<HeaderAction>? actions;
  final Gradient? titleGradient;
  final int animationDelay;

  const PremiumSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.actions,
    this.titleGradient,
    this.animationDelay = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
          margin: EdgeInsets.only(bottom: 16.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (icon != null) ...[
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              gradient: titleGradient ?? AppColors.premiumOcean,
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Icon(icon, color: Colors.white, size: 18.sp),
                          ),
                          SizedBox(width: 12.w),
                        ],
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textOnDark,
                              fontFamily: 'Cairo',
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: 4.h),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: AppColors.textOnDarkSecondary,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (actions != null && actions!.isNotEmpty) ...[
                SizedBox(width: 12.w),
                Row(
                  children: actions!
                      .map(
                        (action) => Padding(
                          padding: EdgeInsets.only(left: 8.w),
                          child: _buildActionButton(action),
                        ),
                      )
                      .toList(),
                ),
              ],
            ],
          ),
        )
        .animate(delay: Duration(milliseconds: animationDelay))
        .fadeIn()
        .slideX(begin: 0.1);
  }

  Widget _buildActionButton(HeaderAction action) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: action.onTap,
          borderRadius: BorderRadius.circular(10.r),
          child: Icon(action.icon, color: Colors.white, size: 18.sp),
        ),
      ),
    );
  }
}

class HeaderAction {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const HeaderAction({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// PREMIUM DATA GRID - Organized Grid Layout for Teacher Dashboard
// ═══════════════════════════════════════════════════════════════════════════

class PremiumDataGrid extends StatelessWidget {
  final int crossAxisCount;
  final double childAspectRatio;
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final double spacing;

  const PremiumDataGrid({
    super.key,
    this.crossAxisCount = 2,
    this.childAspectRatio = 1.2,
    required this.children,
    this.padding = const EdgeInsets.all(16),
    this.spacing = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double itemWidth =
              (constraints.maxWidth - (spacing.w * (crossAxisCount - 1))) /
              crossAxisCount;
          final double itemHeight = itemWidth / childAspectRatio;

          return Wrap(
            spacing: spacing.w,
            runSpacing: spacing.h,
            children: children
                .map(
                  (child) => SizedBox(
                    width: itemWidth,
                    height: itemHeight,
                    child: GlassMorphismCard(
                      padding: EdgeInsets.all(16.w),
                      child: child,
                    ),
                  ),
                )
                .toList(),
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ANIMATED GRADIENT TEXT - Premium Text with Gradient Animation
// ═══════════════════════════════════════════════════════════════════════════

class AnimatedGradientText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final Gradient gradient;
  final Duration animationDuration;
  final TextAlign textAlign;

  const AnimatedGradientText({
    super.key,
    required this.text,
    this.style,
    this.gradient = AppColors.premiumOcean,
    this.animationDuration = const Duration(seconds: 2),
    this.textAlign = TextAlign.start,
  });

  @override
  State<AnimatedGradientText> createState() => _AnimatedGradientTextState();
}

class _AnimatedGradientTextState extends State<AnimatedGradientText>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) => widget.gradient.createShader(
            Rect.fromLTWH(0, 0, bounds.width, bounds.height),
          ),
          blendMode: BlendMode.srcIn,
          child: Text(
            widget.text,
            style:
                widget.style?.copyWith(color: Colors.white) ??
                TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Cairo',
                ),
            textAlign: widget.textAlign,
          ),
        );
      },
    );
  }
}
