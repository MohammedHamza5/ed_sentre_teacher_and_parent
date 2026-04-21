import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_colors.dart';
import 'drawer_models.dart';
import 'drawer_logout_button.dart';

class DrawerShell extends StatefulWidget {
  final Widget header;
  final List<DrawerSectionData> items;
  final VoidCallback onLogout;

  const DrawerShell({
    super.key,
    required this.header,
    required this.items,
    required this.onLogout,
  });

  @override
  State<DrawerShell> createState() => _DrawerShellState();
}

class _DrawerShellState extends State<DrawerShell>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.08, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Widget> _buildFlatList() {
    final widgets = <Widget>[];

    for (final section in widget.items) {
      widgets.add(
        Padding(
          padding: EdgeInsets.only(
            top: 20.h,
            bottom: 8.h,
            left: 8.w,
            right: 8.w,
          ),
          child: Row(
            children: [
              Container(
                width: 3.w,
                height: 12.h,
                decoration: BoxDecoration(
                  gradient: AppColors.secondaryGradient,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                section.title,
                style: TextStyle(
                  color: AppColors.textOnDarkHint,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      );

      for (final item in section.items) {
        widgets.add(_buildDrawerItem(item));
      }
    }

    return widgets;
  }

  Widget _buildDrawerItem(DrawerItemData item) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(context).pop();
            context.go(item.route);
          },
          borderRadius: BorderRadius.circular(16.r),
          splashColor: item.gradient.colors.first.withValues(alpha: 0.15),
          highlightColor: item.gradient.colors.first.withValues(alpha: 0.08),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              color: item.isActive
                  ? item.gradient.colors.first.withValues(alpha: 0.12)
                  : Colors.transparent,
              border: item.isActive
                  ? Border.all(
                      color: item.gradient.colors.first
                          .withValues(alpha: 0.25),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                if (item.isActive)
                  Container(
                    width: 3.w,
                    height: 24.h,
                    margin: EdgeInsets.only(left: 0, right: 10.w),
                    decoration: BoxDecoration(
                      gradient: item.gradient,
                      borderRadius: BorderRadius.circular(4.r),
                      boxShadow: [
                        BoxShadow(
                          color: item.gradient.colors.first
                              .withValues(alpha: 0.6),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    gradient: item.isActive ? item.gradient : null,
                    color: item.isActive
                        ? null
                        : AppColors.textOnDarkSecondary
                              .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: item.isActive
                        ? [
                            BoxShadow(
                              color: item.gradient.colors.first
                                  .withValues(alpha: 0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    item.icon,
                    color: item.isActive
                        ? Colors.white
                        : AppColors.textOnDarkSecondary,
                    size: 20.sp,
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight:
                          item.isActive ? FontWeight.bold : FontWeight.w500,
                      color: item.isActive
                          ? Colors.white
                          : AppColors.textOnDarkSecondary,
                      fontFamily: 'Cairo',
                    ),
                  ),
                ),
                if (item.badge != null)
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 8.w),
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      gradient: item.gradient,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: item.gradient.colors.last
                              .withValues(alpha: 0.4),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: Text(
                      item.badge!,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                if (item.isActive)
                  Container(
                    width: 6.w,
                    height: 6.w,
                    decoration: BoxDecoration(
                      color: item.gradient.colors.last,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: item.gradient.colors.last
                              .withValues(alpha: 0.5),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final flatItems = _buildFlatList();

    return Drawer(
      width: 300.w,
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28.r),
          bottomLeft: Radius.circular(28.r),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.forestPrimary.withValues(alpha: 0.92),
              border: Border(
                left: BorderSide(
                  color: AppColors.glassBorderHighlight,
                  width: 1.5,
                ),
              ),
            ),
            child: Column(
              children: [
                widget.header,
                Expanded(
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: ListView.builder(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ),
                        physics: const ClampingScrollPhysics(),
                        itemCount: flatItems.length,
                        itemBuilder: (_, i) => flatItems[i],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      vertical: 8.h,
                      horizontal: 12.w,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: AppColors.textOnDarkHint,
                          size: 14.sp,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'EdSentre v2.0',
                          style: TextStyle(
                            color: AppColors.textOnDarkHint,
                            fontSize: 11.sp,
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Divider(
                  color: AppColors.darkBorder.withValues(alpha: 0.5),
                  thickness: 1,
                  height: 1,
                ),
                DrawerLogoutButton(onTap: widget.onLogout),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
