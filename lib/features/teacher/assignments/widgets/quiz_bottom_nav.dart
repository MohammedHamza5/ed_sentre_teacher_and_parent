import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Bottom navigation bar for the Quiz creation stepper.
class QuizBottomNav extends StatelessWidget {
  final int currentStep;
  final bool isLoading;
  final Color typeColor;
  final VoidCallback onBack;
  final VoidCallback onNext;
  final VoidCallback onSubmit;

  const QuizBottomNav({
    super.key,
    required this.currentStep,
    required this.isLoading,
    required this.typeColor,
    required this.onBack,
    required this.onNext,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color:
                (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300)
                    .withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (currentStep > 0)
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.onSurface,
                    side: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.5),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: Text('\u0627\u0644\u0633\u0627\u0628\u0642'),
                ),
              ),
            if (currentStep > 0) SizedBox(width: 12.w),
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [typeColor, typeColor.withValues(alpha: 0.8)],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : (currentStep == 0 ? onNext : onSubmit),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 20.w,
                          height: 20.w,
                          child: CircularProgressIndicator(
                            backgroundColor: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              currentStep == 0
                                  ? '\u0627\u0644\u062a\u0627\u0644\u064a - \u0627\u0644\u0623\u0633\u0626\u0644\u0629'
                                  : '\u0646\u0634\u0631 \u0627\u0644\u0643\u0648\u064a\u0632',
                            ),
                            SizedBox(width: 8.w),
                            Icon(
                              currentStep == 0
                                  ? Icons.arrow_forward
                                  : Icons.send,
                              size: 18.sp,
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
