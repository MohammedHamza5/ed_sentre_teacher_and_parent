import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui' as ui;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_colors.dart';
import '../provider/auth_provider.dart';

/// Splash Screen - App loading screen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkAuthAndNavigate();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Wait for splash animation + auth check
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final authProvider = context.read<AuthProvider>();

    // Wait for auth to finish loading
    while (authProvider.isLoading) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
    }

    if (!mounted) return;

    // Navigate based on auth state
    if (authProvider.isAuthenticated) {
      if (authProvider.isTeacher) {
        context.go('/teacher');
      } else if (authProvider.isParent) {
        context.go('/parent');
      } else {
        context.go('/login');
      }
    } else {
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gradient = const BoxDecoration(
      gradient: AppColors.sunsetGradient,
    );
    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: Stack(
        children: [
          Container(decoration: gradient),
          Positioned(
            right: -40.w,
            top: -40.h,
            child: Container(
              width: 160.w,
              height: 160.w,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.07),
                shape: BoxShape.circle,
              ),
            ).animate(onPlay: (c) => c.repeat()).fadeIn(duration: 600.ms).scale(
                  begin: const Offset(0.95, 0.95),
                  end: const Offset(1.0, 1.0),
                  duration: 2000.ms,
                  curve: Curves.easeInOut,
                ),
          ),
          Positioned(
            left: -50.w,
            bottom: -50.h,
            child: Container(
              width: 200.w,
              height: 200.w,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
            ).animate(onPlay: (c) => c.repeat()).fadeIn(duration: 800.ms).scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1.0, 1.0),
                  duration: 2200.ms,
                  curve: Curves.easeInOut,
                ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28.r),
                      child: BackdropFilter(
                        filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          padding: EdgeInsets.all(24.w),
                          width: 320.w,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(28.r),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 120.w,
                                height: 120.w,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24.r),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.25),
                                      blurRadius: 24,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                  color: Colors.white.withValues(alpha: 0.95),
                                ),
                                child: _buildLogo(),
                              )
                                  .animate()
                                  .fadeIn(duration: 600.ms, curve: Curves.easeOut)
                                  .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
                              SizedBox(height: 20.h),
                              _buildGradientText('EdSentre'),
                              SizedBox(height: 8.h),
                              Text(
                                'نظام إدارة السناتر التعليمية',
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  letterSpacing: 0.5,
                                ),
                              ).animate().fadeIn(duration: 500.ms, delay: 250.ms),
                              SizedBox(height: 24.h),
                              _buildLoader().animate().fadeIn(duration: 400.ms, delay: 450.ms),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(16.w),
                child: Text(
                  'الإصدار 1.0.0',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 130.w,
          height: 130.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.35),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
        ),
        Builder(
          builder: (context) {
            return SvgPicture.asset(
              'assets/icons/app_logo.svg',
              width: 72.w,
              height: 72.w,
              placeholderBuilder: (ctx) => Image.asset(
                'assets/icons/app_logo.png',
                width: 72.w,
                height: 72.w,
                errorBuilder: (c, e, s) => Icon(
                  Icons.school,
                  size: 56.sp,
                  color: AppColors.primary,
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 500.ms)
                .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
          },
        ),
      ],
    );
  }

  Widget _buildGradientText(String text) {
    final gradient = LinearGradient(
      colors: [
        Colors.white,
        Colors.white.withValues(alpha: 0.85),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    return ShaderMask(
      shaderCallback: (rect) => gradient.createShader(rect),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 30.sp,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildLoader() {
    dot(int i) => Container(
          width: 8.w,
          height: 8.w,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
        ).animate(onPlay: (c) => c.repeat()).fadeIn(duration: 400.ms).then(delay: (i * 200).ms).scale(
              begin: const Offset(0.8, 0.8),
              end: const Offset(1.1, 1.1),
              duration: 800.ms,
              curve: Curves.easeInOut,
            );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot(0),
        SizedBox(width: 8.w),
        dot(1),
        SizedBox(width: 8.w),
        dot(2),
      ],
    );
  }
}
