import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../core/theming/app_spacing.dart';

class AIThinkingBubble extends StatefulWidget {
  const AIThinkingBubble({super.key});

  @override
  State<AIThinkingBubble> createState() => _AIThinkingBubbleState();
}

class _AIThinkingBubbleState extends State<AIThinkingBubble>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late AnimationController _dotsController;

  late Timer _textTimer;
  int _currentTextIndex = 0;

  final List<String> _thinkingTexts = [
    'جارٍ تحليل استفسارك...',
    'جارٍ استحضار المعارف بواسطة Gemini 3.6...',
    'جارٍ تنظيم وترتيب الإجابة المناسبة...',
    'جارٍ وضع اللمسات الأخيرة...',
  ];

  @override
  void initState() {
    super.initState();

    // Pulse animation for avatar aura
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.35, end: 0.95).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Staggered dots animation
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    // Cycling text timer
    _textTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        setState(() {
          _currentTextIndex = (_currentTextIndex + 1) % _thinkingTexts.length;
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _dotsController.dispose();
    _textTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: AppColors.navyCard,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(18.r),
            topRight: Radius.circular(18.r),
            bottomRight: Radius.circular(18.r),
            bottomLeft: Radius.zero,
          ),
          border: Border.all(
            color: AppColors.teal.withValues(alpha: 0.35),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.teal.withValues(alpha: 0.12),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated Glowing AI Avatar Icon
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.teal, AppColors.electric],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.teal.withValues(alpha: _pulseAnimation.value),
                        blurRadius: 10 * _pulseAnimation.value,
                        spreadRadius: 2 * _pulseAnimation.value,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: Colors.white,
                    size: 16.sp,
                  ),
                );
              },
            ),
            AppSpacing.gapW12,

            // Text status & bouncing neural dots
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.2),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    _thinkingTexts[_currentTextIndex],
                    key: ValueKey<int>(_currentTextIndex),
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(height: 6.h),

                // 3 Bouncing Neural Dots
                Row(
                  children: List.generate(3, (index) {
                    return AnimatedBuilder(
                      animation: _dotsController,
                      builder: (context, child) {
                        final delay = index * 0.2;
                        final value = (_dotsController.value - delay) % 1.0;
                        final bounce = (value < 0.5)
                            ? (value * 2.0)
                            : (2.0 - value * 2.0);

                        return Container(
                          margin: EdgeInsets.only(left: 4.w),
                          width: 6.w,
                          height: 6.w + (bounce * 4.h),
                          decoration: BoxDecoration(
                            color: Color.lerp(
                              AppColors.teal,
                              AppColors.electricGlow,
                              bounce,
                            ),
                            borderRadius: BorderRadius.circular(3.r),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.teal.withValues(alpha: 0.6),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
