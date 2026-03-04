import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/config/app_colors.dart';
import '../../../shared/data/supabase_repository.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/premium_widgets.dart';

/// Teacher Submissions / Grading Screen
class SubmissionsScreen extends StatefulWidget {
  final Map<String, dynamic> assignment;

  const SubmissionsScreen({super.key, required this.assignment});

  @override
  State<SubmissionsScreen> createState() => _SubmissionsScreenState();
}

class _SubmissionsScreenState extends State<SubmissionsScreen> {
  bool _isLoading = true;
  String? _error;
  List<SubmissionModel> _submissions = [];

  String get _assignmentId => widget.assignment['id']?.toString() ?? '';
  String get _title => widget.assignment['title']?.toString() ?? 'بدون عنوان';
  String get _type => widget.assignment['type']?.toString() ?? 'assignment';
  double get _maxScore =>
      (widget.assignment['max_score'] as num?)?.toDouble() ?? 100;

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = context.read<SupabaseRepository>();
      final submissions = await repository.getAssignmentSubmissions(
        _assignmentId,
      );

      // Filter out 'in_progress' submissions (not yet submitted)
      final actualSubmissions = submissions.where((s) {
        // If submission has no submittedAt text or is in_progress status, skip
        return s.submittedAt != DateTime.fromMillisecondsSinceEpoch(0);
      }).toList();

      if (mounted) {
        setState(() {
          _submissions = actualSubmissions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isInteractive = _type == 'quiz' || _type == 'exam';

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'التسليمات',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              _title,
              style: TextStyle(fontSize: 11.sp, color: Colors.white60),
            ),
          ],
        ),
        backgroundColor: AppColors.darkSurface,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSubmissions,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
          ? _buildError()
          : _submissions.isEmpty
          ? _buildEmpty()
          : _buildSubmissionsList(isInteractive),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48.sp, color: AppColors.error),
          SizedBox(height: 12.h),
          Text(
            _error ?? 'حدث خطأ',
            style: TextStyle(color: AppColors.textOnDarkSecondary),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12.h),
          GradientButton(
            text: 'إعادة المحاولة',
            icon: Icons.refresh,
            onPressed: _loadSubmissions,
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.darkBorder),
            ),
            child: Icon(
              Icons.inbox_outlined,
              size: 48.sp,
              color: AppColors.textOnDarkHint,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'لا توجد تسليمات بعد',
            style: TextStyle(
              color: AppColors.textOnDark,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'لم يقم أي طالب بتسليم هذا الواجب حتى الآن',
            style: TextStyle(color: AppColors.textOnDarkHint, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionsList(bool isInteractive) {
    final graded = _submissions.where((s) => s.isGraded).length;
    final pending = _submissions.length - graded;

    return Column(
      children: [
        // Stats Bar
        Container(
          padding: EdgeInsets.all(16.w),
          margin: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Row(
            children: [
              _buildStat('${_submissions.length}', 'إجمالي', AppColors.primary),
              _buildDivider(),
              _buildStat('$graded', 'تم التصحيح', AppColors.success),
              _buildDivider(),
              _buildStat('$pending', 'بانتظار', AppColors.warning),
            ],
          ),
        ),

        // Submissions List
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: _submissions.length,
            itemBuilder: (context, index) {
              return _buildSubmissionCard(_submissions[index], isInteractive);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStat(String value, String label, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textOnDarkSecondary,
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 30.h, color: AppColors.darkBorder);
  }

  Widget _buildSubmissionCard(SubmissionModel submission, bool isInteractive) {
    final isGraded = submission.isGraded;

    // Parse answers if interactive
    Map<String, dynamic>? answers;
    if (isInteractive && submission.submissionText != null) {
      try {
        answers = Map<String, dynamic>.from(
          jsonDecode(submission.submissionText!) as Map,
        );
        answers.remove('_exam_started_at');
      } catch (_) {}
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isGraded
              ? AppColors.success.withOpacity(0.3)
              : AppColors.darkBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student info row
          Row(
            children: [
              CircleAvatar(
                radius: 20.r,
                backgroundColor: AppColors.primary.withOpacity(0.2),
                backgroundImage: submission.studentAvatar != null
                    ? NetworkImage(submission.studentAvatar!)
                    : null,
                child: submission.studentAvatar == null
                    ? Icon(Icons.person, color: AppColors.primary, size: 20.sp)
                    : null,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      submission.studentName ?? 'طالب',
                      style: TextStyle(
                        color: AppColors.textOnDark,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _formatDate(submission.submittedAt),
                      style: TextStyle(
                        color: AppColors.textOnDarkHint,
                        fontSize: 11.sp,
                      ),
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isGraded
                      ? AppColors.success.withOpacity(0.15)
                      : AppColors.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  isGraded
                      ? '${submission.score?.toStringAsFixed(0)} / ${_maxScore.toStringAsFixed(0)}'
                      : 'بانتظار التصحيح',
                  style: TextStyle(
                    color: isGraded ? AppColors.success : AppColors.warning,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          // Show answers if interactive
          if (isInteractive && answers != null && answers.isNotEmpty) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الإجابات:',
                    style: TextStyle(
                      color: AppColors.textOnDarkSecondary,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 6.h),
                  ...answers.entries.take(5).map((entry) {
                    final q = _findQuestion(entry.key);
                    return Padding(
                      padding: EdgeInsets.only(bottom: 4.h),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${q?['label'] ?? entry.key}: ',
                            style: TextStyle(
                              color: AppColors.textOnDarkHint,
                              fontSize: 10.sp,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              _formatAnswer(entry.value, q),
                              style: TextStyle(
                                color: AppColors.textOnDark,
                                fontSize: 10.sp,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (answers.length > 5)
                    Text(
                      '... و${answers.length - 5} إجابات أخرى',
                      style: TextStyle(
                        color: AppColors.textOnDarkHint,
                        fontSize: 10.sp,
                      ),
                    ),
                ],
              ),
            ),
          ],

          // Non-interactive: show submission text
          if (!isInteractive && submission.submissionText != null) ...[
            SizedBox(height: 12.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                submission.submissionText!,
                style: TextStyle(color: AppColors.textOnDark, fontSize: 12.sp),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],

          SizedBox(height: 12.h),

          // Grading section
          _buildGradingSection(submission),
        ],
      ),
    );
  }

  Widget _buildGradingSection(SubmissionModel submission) {
    if (submission.isGraded) {
      // Already graded — show result
      return Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: AppColors.success.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: AppColors.success.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.success, size: 18.sp),
            SizedBox(width: 8.w),
            Text(
              'الدرجة: ${submission.score?.toStringAsFixed(1)} / ${_maxScore.toStringAsFixed(0)}',
              style: TextStyle(
                color: AppColors.success,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => _showGradeDialog(submission),
              child: Text(
                'تعديل',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Not graded — show grade button
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _showGradeDialog(submission),
        icon: Icon(Icons.grading, size: 18.sp),
        label: Text(
          'تصحيح',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 10.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }

  void _showGradeDialog(SubmissionModel submission) {
    final scoreController = TextEditingController(
      text: submission.score?.toStringAsFixed(0) ?? '',
    );
    final feedbackController = TextEditingController(
      text: submission.feedback ?? '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: Text(
          'تصحيح — ${submission.studentName ?? "طالب"}',
          style: TextStyle(color: Colors.white, fontSize: 16.sp),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: scoreController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: Colors.white, fontSize: 14.sp),
              decoration: InputDecoration(
                labelText: 'الدرجة (من ${_maxScore.toStringAsFixed(0)})',
                labelStyle: TextStyle(color: Colors.white54),
                filled: true,
                fillColor: AppColors.darkSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: AppColors.darkBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: AppColors.darkBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: feedbackController,
              maxLines: 3,
              style: TextStyle(color: Colors.white, fontSize: 14.sp),
              decoration: InputDecoration(
                labelText: 'ملاحظات (اختياري)',
                labelStyle: TextStyle(color: Colors.white54),
                filled: true,
                fillColor: AppColors.darkSurface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: AppColors.darkBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: AppColors.darkBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () async {
              final score = double.tryParse(scoreController.text);
              if (score == null || score < 0 || score > _maxScore) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'أدخل درجة صحيحة (0 - ${_maxScore.toStringAsFixed(0)})',
                    ),
                  ),
                );
                return;
              }

              Navigator.pop(ctx);

              try {
                final repo = context.read<SupabaseRepository>();
                await repo.gradeSubmission(
                  submissionId: submission.id,
                  score: score,
                  feedback: feedbackController.text.isNotEmpty
                      ? feedbackController.text
                      : null,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('تم حفظ التصحيح بنجاح'),
                      backgroundColor: Colors.green,
                    ),
                  );
                  _loadSubmissions();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('فشل في الحفظ: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: const Text(
              'حفظ',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic>? _findQuestion(String questionId) {
    final questions = widget.assignment['questions'];
    if (questions is List) {
      for (int i = 0; i < questions.length; i++) {
        final q = questions[i] as Map<String, dynamic>?;
        if (q != null && q['id']?.toString() == questionId) {
          return {...q, 'label': 'س${i + 1}'};
        }
      }
    }
    return null;
  }

  String _formatAnswer(dynamic answer, Map<String, dynamic>? question) {
    if (answer is int && question != null) {
      final options = question['options'];
      if (options is List && answer < options.length) {
        return options[answer].toString();
      }
      return 'الخيار ${answer + 1}';
    }
    return answer?.toString() ?? '-';
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
