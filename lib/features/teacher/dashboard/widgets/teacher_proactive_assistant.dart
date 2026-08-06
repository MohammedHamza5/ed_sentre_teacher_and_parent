import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/config/app_colors.dart';
import '../../../../core/theming/app_spacing.dart';
import '../../../ai/provider/ai_provider.dart';

class TeacherProactiveAssistant extends StatefulWidget {
  final String groupId;
  final String centerId;

  const TeacherProactiveAssistant({
    super.key,
    required this.groupId,
    required this.centerId,
  });

  @override
  State<TeacherProactiveAssistant> createState() => _TeacherProactiveAssistantState();
}

class _TeacherProactiveAssistantState extends State<TeacherProactiveAssistant> {
  Map<String, dynamic>? _analysis;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalysis();
  }

  @override
  void didUpdateWidget(covariant TeacherProactiveAssistant oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.groupId != widget.groupId || oldWidget.centerId != widget.centerId) {
      _loadAnalysis();
    }
  }

  Future<void> _loadAnalysis() async {
    setState(() => _isLoading = true);
    try {
      final aiProvider = context.read<AIProvider>();
      final result = await aiProvider.weaknessDetector.analyzeGroupWithAI(
        groupId: widget.groupId,
        centerId: widget.centerId,
      );
      if (mounted) {
        setState(() {
          _analysis = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 180.h,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: AppColors.teal),
        ),
      );
    }

    if (_analysis == null) {
      return Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: AppColors.teal.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.psychology_outlined,
              size: 40.sp,
              color: AppColors.teal.withValues(alpha: 0.4),
            ),
            SizedBox(height: 12.h),
            Text(
              'المساعد الاستباقي (AI)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14.sp,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'يحتاج التحليل إلى بيانات حضور وتقييمات كافية للمجموعة. سيظهر تحليل ذكي هنا بعد تسجيل بعض الجلسات والنتائج.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.sp,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    final score = _analysis!['overall_score'] as int? ?? 0;
    final strengths = (_analysis!['strengths'] as List?)?.cast<String>() ?? [];
    final weaknesses = (_analysis!['weaknesses'] as List?)?.cast<String>() ?? [];
    final suggestions = (_analysis!['suggestions'] as List?)?.cast<String>() ?? [];

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.teal.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20.r),
        child: Column(
          children: [
            // Header
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.teal.withValues(alpha: 0.2),
                    AppColors.teal.withValues(alpha: 0.05),
                  ],
                ),
                border: Border(
                  bottom: BorderSide(color: AppColors.teal.withValues(alpha: 0.2)),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.smart_toy_rounded, color: AppColors.teal, size: 24.sp),
                  AppSpacing.gapW8,
                  Text(
                    'المساعد الاستباقي (AI)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.sp,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: _getScoreColor(score).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      'صحة الفصل: $score%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getScoreColor(score),
                        fontSize: 12.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (strengths.isNotEmpty) ...[
                    _buildSectionHeader(Icons.thumb_up_alt_rounded, 'نقاط القوة', AppColors.success),
                    AppSpacing.gapH8,
                    ...strengths.map((s) => _buildListItem(s, AppColors.success)),
                    AppSpacing.gapH16,
                  ],
                  if (weaknesses.isNotEmpty) ...[
                    _buildSectionHeader(Icons.warning_amber_rounded, 'نقاط الضعف (تحتاج تدخل)', AppColors.error),
                    AppSpacing.gapH8,
                    ...weaknesses.map((w) => _buildListItem(w, AppColors.error)),
                    AppSpacing.gapH16,
                  ],
                  
                  if (suggestions.isNotEmpty) ...[
                    _buildSectionHeader(Icons.lightbulb_outline_rounded, 'الإجراءات المقترحة', AppColors.gold),
                    AppSpacing.gapH8,
                    ...suggestions.map((s) => _buildActionItem(context, s)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.warning;
    return AppColors.error;
  }

  Widget _buildSectionHeader(IconData icon, String title, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18.sp),
        AppSpacing.gapW8,
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: 13.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildListItem(String text, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h, right: 8.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 6.h),
            child: Container(
              width: 6.w,
              height: 6.w,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
            ),
          ),
          AppSpacing.gapW8,
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 12.sp,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem(BuildContext context, String actionText) {
    final bool isGenerateQuiz = actionText.contains('اختبار') || actionText.contains('Quiz');
    
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              actionText,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 12.sp,
              ),
            ),
          ),
          if (isGenerateQuiz) ...[
            AppSpacing.gapW8,
            ElevatedButton(
              onPressed: () {
                context.push('/teacher/ai/generate-exam');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 0),
                minimumSize: Size(0, 32.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.r),
                ),
              ),
              child: Text(
                'توليد الآن',
                style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
