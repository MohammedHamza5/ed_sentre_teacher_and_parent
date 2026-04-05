import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/config/app_colors.dart';
import '../../../shared/models/exam_models.dart';
import '../../../shared/models/models.dart';

/// Premium read-only exam answer review screen for teachers.
class ExamAnswerReviewScreen extends StatefulWidget {
  final SubmissionModel submission;
  final double maxScore;
  final String assignmentTitle;
  final Map<String, dynamic> assignment;

  const ExamAnswerReviewScreen({
    super.key,
    required this.submission,
    required this.maxScore,
    required this.assignmentTitle,
    required this.assignment,
  });

  @override
  State<ExamAnswerReviewScreen> createState() => _ExamAnswerReviewScreenState();
}

class _ExamAnswerReviewScreenState extends State<ExamAnswerReviewScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;
  List<StudentAnswer> _answers = [];

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  int get _correctCount => _answers.where((a) => a.isCorrect == true).length;
  int get _wrongCount => _answers.where((a) => a.isCorrect == false).length;
  int get _unansweredCount => _answers
      .where(
        (a) =>
            a.studentAnswer == null ||
            a.studentAnswer!.isEmpty ||
            a.studentAnswer == '-1',
      )
      .length;
  double get _totalScore => _answers.fold(0.0, (sum, a) => sum + a.finalScore);
  double get _percentage =>
      widget.maxScore > 0 ? (_totalScore / widget.maxScore * 100) : 0.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _loadAnswers();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _loadAnswers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Parse Questions
      List<ExamQuestion> questions = [];
      final dynamic rawQuestions = widget.assignment['questions'];
      if (rawQuestions != null) {
        List<dynamic> qList = [];
        if (rawQuestions is String) {
          try {
            qList = jsonDecode(rawQuestions) as List<dynamic>;
          } catch (_) {}
        } else if (rawQuestions is List) {
          qList = rawQuestions;
        }

        for (int i = 0; i < qList.length; i++) {
          final qData = qList[i] as Map<String, dynamic>;
          final String qType = qData['type']?.toString() ?? 'mcq';
          final questionType = QuestionType.fromString(qType);

          double marks =
              (qData['points'] as num?)?.toDouble() ??
              (qData['marks'] as num?)?.toDouble() ??
              1.0;

          List<String>? options;
          if (qData['options'] != null && qData['options'] is List) {
            options = (qData['options'] as List)
                .map((e) => e.toString())
                .toList();
          }

          final String qId = qData['id']?.toString() ?? i.toString();

          String? correctAnswer;
          if (questionType == QuestionType.mcq ||
              questionType == QuestionType.trueFalse) {
            final int correctIdx =
                (qData['correct_option_index'] as num?)?.toInt() ??
                (qData['correct'] as num?)?.toInt() ??
                0;
            if (options != null &&
                options.length > correctIdx &&
                correctIdx >= 0) {
              correctAnswer = correctIdx.toString(); // Map option index
            }
          } else {
            correctAnswer = qData['correct_answer']?.toString();
          }

          questions.add(
            ExamQuestion(
              id: qId,
              assignmentId: widget.assignment['id']?.toString() ?? '',
              text:
                  qData['question']?.toString() ??
                  qData['text']?.toString() ??
                  '',
              type: questionType,
              marks: marks,
              options: options,
              correctAnswer: correctAnswer,
              orderIndex: i,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
        }
      }

      // Parse Submissions
      Map<String, dynamic> studentAnswersJson = {};
      final String? subText = widget.submission.submissionText;
      if (subText != null && subText.isNotEmpty) {
        try {
          studentAnswersJson = jsonDecode(subText) as Map<String, dynamic>;
        } catch (_) {}
      }

      _answers = questions.map((q) {
        final dynamic rawAnswer =
            studentAnswersJson[q.id] ??
            studentAnswersJson[q.orderIndex.toString()];
        final String? answerStr = rawAnswer?.toString();

        bool? isCorrect;
        double? autoScore;

        if (answerStr != null && answerStr.isNotEmpty) {
          if (q.type == QuestionType.mcq || q.type == QuestionType.trueFalse) {
            final int? answeredIdx = int.tryParse(answerStr);
            final int? correctIdx = int.tryParse(q.correctAnswer ?? '');
            if (answeredIdx != null && correctIdx != null) {
              isCorrect = answeredIdx == correctIdx;
            } else {
              isCorrect = answerStr.trim() == q.correctAnswer?.trim();
            }
          } else if (q.type == QuestionType.shortAnswer &&
              q.correctAnswer != null) {
            isCorrect =
                answerStr.trim().toLowerCase() ==
                q.correctAnswer?.trim().toLowerCase();
          }
          autoScore = isCorrect == true ? q.marks : 0.0;
        }

        return StudentAnswer(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          submissionId: widget.submission.id,
          questionId: q.id,
          studentAnswer: answerStr,
          isCorrect: isCorrect,
          autoScore: autoScore,
          createdAt: widget.submission.submittedAt,
          updatedAt: widget.submission.submittedAt,
          question: q,
        );
      }).toList();

      if (mounted) {
        setState(() => _isLoading = false);
        _animController.forward();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'خطأ في جلب البيانات: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Premium dark theme base
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'مراجعة الإجابات',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: const Color(0xFF0F172A).withValues(alpha: 0.5),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                backgroundColor: AppColors.accentVivid,
              ),
            )
          : _error != null
          ? _buildErrorScreen()
          : Stack(
              children: [
                // Background gradient bursts
                Positioned(
                  top: -100,
                  right: -100,
                  child: Container(
                    width: 300.w,
                    height: 300.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accentVivid.withValues(alpha: 0.15),
                    ),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                      child: Container(),
                    ),
                  ),
                ),
                FadeTransition(
                  opacity: _fadeAnim,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: SizedBox(height: 100.h)),
                      SliverToBoxAdapter(child: _buildStudentHeader()),
                      SliverToBoxAdapter(child: _buildPremiumScoreboard()),
                      SliverToBoxAdapter(child: _buildStatsChips()),
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) => _buildAnimatedQuestionCard(
                              _answers[index],
                              index + 1,
                              index,
                            ),
                            childCount: _answers.length,
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(child: SizedBox(height: 40.h)),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildStudentHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.accentVivid, AppColors.secondary],
              ),
            ),
            child: CircleAvatar(
              radius: 26.r,
              backgroundColor: AppColors.darkSurface,
              backgroundImage: widget.submission.studentAvatar != null
                  ? NetworkImage(widget.submission.studentAvatar!)
                  : null,
              child: widget.submission.studentAvatar == null
                  ? Icon(Icons.person, color: AppColors.accentVivid, size: 30.sp)
                  : null,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.submission.studentName ?? 'طالب مجهول',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  widget.assignmentTitle,
                  style: TextStyle(color: Colors.white60, fontSize: 12.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumScoreboard() {
    final color = _percentage >= 80
        ? const Color(0xFF10B981) // Emerald
        : _percentage >= 50
        ? const Color(0xFFF59E0B) // Amber
        : const Color(0xFFEF4444); // Rose

    return Container(
      margin: EdgeInsets.all(20.w),
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColors.darkSurface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'النتيجة النهائية',
                style: TextStyle(color: Colors.white70, fontSize: 14.sp),
              ),
              SizedBox(height: 8.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _totalScore.toStringAsFixed(1),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 42.sp,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 6.h, right: 4.w),
                    child: Text(
                      '/ ${widget.maxScore.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(30.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _percentage >= 50
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color: color,
                      size: 16.sp,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      _percentage >= 50 ? 'اجتياز بنجاح' : 'يحتاج للتحسين',
                      style: TextStyle(
                        color: color,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Circular progress ring
          SizedBox(
            width: 100.w,
            height: 100.w,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: _percentage / 100),
              duration: const Duration(seconds: 1),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: 1.0,
                      strokeWidth: 8.w,
                      backgroundColor: AppColors.forestDeep,
                    ),
                    CircularProgressIndicator(
                      value: value,
                      strokeWidth: 8.w,
                      strokeCap: StrokeCap.round,
                      backgroundColor: color,
                      color: Colors.transparent,
                    ),
                    Text(
                      '${(value * 100).toInt()}%',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsChips() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildPremiumChip(
              icon: Icons.check_circle,
              label: '$_correctCount صحيح',
              color: const Color(0xFF10B981),
            ),
            SizedBox(width: 8.w),
            _buildPremiumChip(
              icon: Icons.cancel,
              label: '$_wrongCount خطأ',
              color: const Color(0xFFEF4444),
            ),
            SizedBox(width: 8.w),
            _buildPremiumChip(
              icon: Icons.help,
              label: '$_unansweredCount مفقود',
              color: const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: AppColors.darkSurface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16.sp, color: color),
          SizedBox(width: 8.w),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedQuestionCard(
    StudentAnswer answer,
    int index,
    int delayIndex,
  ) {
    if (answer.question == null) return const SizedBox.shrink();

    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0.2, 0), end: Offset.zero)
          .animate(
            CurvedAnimation(
              parent: _animController,
              curve: Interval(
                (delayIndex * 0.1).clamp(0.0, 1.0),
                1.0,
                curve: Curves.easeOutBack,
              ),
            ),
          ),
      child: Padding(
        padding: EdgeInsets.only(bottom: 20.h),
        child: _buildQuestionCard(answer, index),
      ),
    );
  }

  Widget _buildQuestionCard(StudentAnswer answer, int index) {
    final question = answer.question!;
    final isCorrect = answer.isCorrect == true;
    final isWrong = answer.isCorrect == false;
    final isUnanswered =
        answer.studentAnswer == null ||
        answer.studentAnswer!.isEmpty ||
        answer.studentAnswer == '-1';

    Color stateColor;
    IconData stateIcon;
    if (isUnanswered) {
      stateColor = const Color(0xFF94A3B8);
      stateIcon = Icons.horizontal_rule_rounded;
    } else if (isCorrect) {
      stateColor = const Color(0xFF10B981);
      stateIcon = Icons.check_circle_rounded;
    } else if (isWrong) {
      stateColor = const Color(0xFFEF4444);
      stateIcon = Icons.cancel_rounded;
    } else {
      stateColor = AppColors.accentVivid;
      stateIcon = Icons.subject_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.darkSurface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: stateColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Elegant Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: stateColor.withValues(alpha: 0.1),
              border: Border(
                bottom: BorderSide(color: stateColor.withValues(alpha: 0.2)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    color: stateColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Center(
                    child: Text(
                      '$index',
                      style: TextStyle(
                        color: stateColor,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question.type.arabicName,
                      style: TextStyle(
                        color: stateColor,
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${answer.finalScore.toStringAsFixed(1)} / ${question.marks.toStringAsFixed(1)} نقطة',
                      style: TextStyle(color: Colors.white70, fontSize: 12.sp),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(stateIcon, color: stateColor, size: 24.sp),
              ],
            ),
          ),

          // Question Text
          Padding(
            padding: EdgeInsets.all(20.w),
            child: Text(
              question.text,
              style: TextStyle(
                color: Colors.white,
                fontSize: 15.sp,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Options / Answers
          if (question.type == QuestionType.mcq &&
              question.options != null) ...[
            Padding(
              padding: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 20.w),
              child: Column(
                children: question.options!.asMap().entries.map((entry) {
                  return _buildModernOption(
                    optionIndex: entry.key,
                    optionText: entry.value,
                    studentAnswer: answer.studentAnswer,
                    correctAnswer: question.correctAnswer,
                  );
                }).toList(),
              ),
            ),
          ],

          if (question.type == QuestionType.trueFalse) ...[
            Padding(
              padding: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 20.w),
              child: _buildTrueFalseRow(
                answer.studentAnswer,
                question.correctAnswer,
              ),
            ),
          ],

          if (question.type == QuestionType.shortAnswer ||
              question.type == QuestionType.essay) ...[
            _buildTextAnswerDisplay(answer),
          ],
        ],
      ),
    );
  }

  Widget _buildModernOption({
    required int optionIndex,
    required String optionText,
    required String? studentAnswer,
    required String? correctAnswer,
  }) {
    final studentIdx = int.tryParse(studentAnswer ?? '');
    final correctIdx = int.tryParse(correctAnswer ?? '');

    final isStudentChoice = studentIdx == optionIndex;
    final isCorrectOption = correctIdx == optionIndex;

    Color bgColor = Colors.transparent;
    Color borderColor = AppColors.glassBorderHighlight;
    Color textColor = Colors.white70;
    Widget? trailing;

    if (isStudentChoice && isCorrectOption) {
      bgColor = const Color(0xFF10B981).withValues(alpha: 0.15);
      borderColor = const Color(0xFF10B981);
      textColor = Colors.white;
      trailing = Icon(
        Icons.check_circle_rounded,
        color: const Color(0xFF10B981),
        size: 20.sp,
      );
    } else if (isStudentChoice && !isCorrectOption) {
      bgColor = const Color(0xFFEF4444).withValues(alpha: 0.15);
      borderColor = const Color(0xFFEF4444);
      textColor = Colors.white;
      trailing = Icon(
        Icons.cancel_rounded,
        color: const Color(0xFFEF4444),
        size: 20.sp,
      );
    } else if (isCorrectOption) {
      bgColor = const Color(0xFF10B981).withValues(alpha: 0.05);
      borderColor = const Color(0xFF10B981).withValues(alpha: 0.5);
      textColor = const Color(0xFF10B981);
      trailing = Icon(
        Icons.check_rounded,
        color: const Color(0xFF10B981),
        size: 20.sp,
      );
    }

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 24.w,
            height: 24.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isStudentChoice ? borderColor : Colors.white30,
                width: 2,
              ),
              color: isStudentChoice ? borderColor : Colors.transparent,
            ),
            child: isStudentChoice
                ? Icon(Icons.circle, color: AppColors.darkSurface, size: 10.sp)
                : null,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              optionText,
              style: TextStyle(
                color: textColor,
                fontSize: 14.sp,
                fontWeight: isStudentChoice || isCorrectOption
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildTrueFalseRow(String? studentAnswer, String? correctAnswer) {
    return Row(
      children: [
        Expanded(
          child: _buildModernOption(
            optionIndex: 0,
            optionText: 'صح',
            studentAnswer: studentAnswer,
            correctAnswer: correctAnswer,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _buildModernOption(
            optionIndex: 1,
            optionText: 'خطأ',
            studentAnswer: studentAnswer,
            correctAnswer: correctAnswer,
          ),
        ),
      ],
    );
  }

  Widget _buildTextAnswerDisplay(StudentAnswer answer) {
    return Padding(
      padding: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student response box
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: AppColors.glassBorderHighlight),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إجابة الطالب:',
                  style: TextStyle(color: Colors.white54, fontSize: 11.sp),
                ),
                SizedBox(height: 8.h),
                Text(
                  answer.studentAnswer?.isNotEmpty == true
                      ? answer.studentAnswer!
                      : 'لا توجد إجابة',
                  style: TextStyle(
                    color: answer.studentAnswer?.isNotEmpty == true
                        ? Colors.white
                        : Colors.white38,
                    fontSize: 14.sp,
                    fontStyle: answer.studentAnswer?.isNotEmpty == true
                        ? FontStyle.normal
                        : FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          // Expected answer box if available
          if (answer.question?.correctAnswer?.isNotEmpty == true) ...[
            SizedBox(height: 12.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'الإجابة النموذجية:',
                    style: TextStyle(
                      color: const Color(0xFF10B981),
                      fontSize: 11.sp,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    answer.question!.correctAnswer!,
                    style: TextStyle(color: Colors.white, fontSize: 14.sp),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48.sp, color: AppColors.errorRed),
          SizedBox(height: 16.h),
          Text(
            _error ?? 'حدث خطأ',
            style: TextStyle(color: Colors.white54, fontSize: 14.sp),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          ElevatedButton(
            onPressed: _loadAnswers,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentVivid,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.r),
              ),
            ),
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }
}
