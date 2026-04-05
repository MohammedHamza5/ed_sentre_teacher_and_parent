import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../../core/config/app_colors.dart';
import '../../../shared/data/supabase_repository.dart';
import '../../../shared/models/models.dart';
import '../../../shared/widgets/premium_widgets.dart';
import 'exam_answer_review_screen.dart';
import 'grading_review_screen.dart';

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

  bool get _isInteractive => _type == 'quiz' || _type == 'exam';

  int get _totalCount => _submissions.length;
  int get _gradedCount => _submissions.where((s) => s.isGraded).length;
  int get _pendingCount => _totalCount - _gradedCount;

  double get _avgScore {
    final graded = _submissions.where((s) => s.isGraded).toList();
    if (graded.isEmpty) return 0;
    final total = graded.fold(0.0, (sum, s) => sum + (s.score ?? 0));
    return total / graded.length;
  }

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

      if (mounted) {
        setState(() {
          _submissions = submissions;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('==== Error loading submissions: $e ====');
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
    return Scaffold(
      backgroundColor: AppColors.forestDeep,
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
          ? Center(
              child: CircularProgressIndicator(
                backgroundColor: AppColors.accentVivid,
              ),
            )
          : _error != null
          ? _buildError()
          : _submissions.isEmpty
          ? _buildEmpty()
          : _buildSubmissionsList(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48.sp, color: AppColors.errorRed),
          SizedBox(height: 12.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32.w),
            child: Text(
              _error ?? 'حدث خطأ',
              style: TextStyle(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
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
              color: AppColors.darkSurface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.glassBorderHighlight),
            ),
            child: Icon(
              Icons.inbox_outlined,
              size: 48.sp,
              color: AppColors.textMuted,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'لا توجد تسليمات بعد',
            style: TextStyle(
              color: AppColors.textDisplay,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'لم يقم أي طالب بتسليم هذا الواجب حتى الآن',
            style: TextStyle(color: AppColors.textMuted, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmissionsList() {
    return Column(
      children: [
        // Stats Bar
        Container(
          padding: EdgeInsets.all(16.w),
          margin: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.darkSurface,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: AppColors.glassBorderHighlight),
          ),
          child: Row(
            children: [
              _buildStat('$_totalCount', 'إجمالي', AppColors.accentVivid),
              _buildDivider(),
              _buildStat('$_gradedCount', 'تم التصحيح', AppColors.emeraldGreen),
              _buildDivider(),
              _buildStat('$_pendingCount', 'بانتظار', AppColors.warmAmber),
              _buildDivider(),
              _buildStat(
                '${_avgScore.toStringAsFixed(0)}%',
                'المعدل',
                AppColors.accentVivid,
              ),
            ],
          ),
        ),

        // Submissions List
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: _submissions.length,
            itemBuilder: (context, index) {
              return _buildSubmissionCard(_submissions[index]);
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
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 10.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 30.h, color: AppColors.glassBorderHighlight);
  }

  Widget _buildSubmissionCard(SubmissionModel submission) {
    final isGraded = submission.isGraded;

    return GestureDetector(
      onTap: () => _onSubmissionTap(submission),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.darkSurface,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isGraded
                ? AppColors.emeraldGreen.withValues(alpha: 0.3)
                : AppColors.glassBorderHighlight,
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
                  backgroundColor: AppColors.accentVivid.withValues(alpha: 0.2),
                  backgroundImage: submission.studentAvatar != null
                      ? NetworkImage(submission.studentAvatar!)
                      : null,
                  child: submission.studentAvatar == null
                      ? Icon(
                          Icons.person,
                          color: AppColors.accentVivid,
                          size: 20.sp,
                        )
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
                          color: AppColors.textDisplay,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatDate(submission.submittedAt),
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 10.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: isGraded
                        ? AppColors.emeraldGreen.withValues(alpha: 0.15)
                        : AppColors.warmAmber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    isGraded
                        ? '${submission.score?.toStringAsFixed(0)} / ${_maxScore.toStringAsFixed(0)}'
                        : 'بانتظار التصحيح',
                    style: TextStyle(
                      color: isGraded ? AppColors.emeraldGreen : AppColors.warmAmber,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 12.h),

            // Action row
            _buildActionRow(submission),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow(SubmissionModel submission) {
    if (submission.isGraded) {
      // Graded — show score bar + view button
      final pct = _maxScore > 0
          ? ((submission.score ?? 0) / _maxScore).clamp(0.0, 1.0)
          : 0.0;
      final color = pct >= 0.8
          ? AppColors.emeraldGreen
          : pct >= 0.5
          ? AppColors.warmAmber
          : AppColors.errorRed;

      return Column(
        children: [
          // Score progress
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6.h,
              backgroundColor: AppColors.darkSurface,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              Icon(Icons.check_circle, color: AppColors.emeraldGreen, size: 16.sp),
              SizedBox(width: 4.w),
              Text(
                'تم التصحيح',
                style: TextStyle(color: AppColors.emeraldGreen, fontSize: 11.sp),
              ),
              const Spacer(),
              if (_isInteractive) ...[
                Icon(
                  Icons.visibility_outlined,
                  color: AppColors.textMuted,
                  size: 16.sp,
                ),
                SizedBox(width: 4.w),
                Text(
                  'اضغط لمراجعة الإجابات',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ],
          ),
        ],
      );
    }

    // Not graded — show grade button
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => _onGradeTap(submission),
        icon: Icon(Icons.grading, size: 18.sp),
        label: Text(
          'تصحيح وإرسال النتيجة',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.sp),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accentVivid,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 10.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      ),
    );
  }

  void _onSubmissionTap(SubmissionModel submission) {
    if (_isInteractive) {
      // Navigate to read-only exam review
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ExamAnswerReviewScreen(
            submission: submission,
            maxScore: _maxScore,
            assignmentTitle: _title,
            assignment: widget.assignment, // Added this line
          ),
        ),
      );
    }
    // NOTE: Non-interactive (file/text) submissions don't need a detail screen
  }

  void _onGradeTap(SubmissionModel submission) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            GradingReviewScreen(submission: submission, maxScore: _maxScore),
      ),
    );
    if (result == true) {
      _loadSubmissions();
    }
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
