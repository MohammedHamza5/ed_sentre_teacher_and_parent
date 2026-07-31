import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../../../shared/models/models.dart';
import '../../../../shared/models/exam_models.dart';
import '../../../../shared/data/exam_questions_repository.dart';
import '../../../../shared/data/supabase_repository.dart';
import '../../../auth/provider/auth_provider.dart';

class GradingReviewScreen extends StatefulWidget {
  final SubmissionModel submission;
  final double maxScore;

  const GradingReviewScreen({
    super.key,
    required this.submission,
    required this.maxScore,
  });

  @override
  State<GradingReviewScreen> createState() => _GradingReviewScreenState();
}

class _GradingReviewScreenState extends State<GradingReviewScreen> {
  bool _isLoading = true;
  String? _error;
  List<StudentAnswer> _answers = [];
  final Map<String, TextEditingController> _scoreControllers = {};
  final Map<String, TextEditingController> _commentControllers = {};

  double get _currentTotalScore {
    double total = 0;
    for (final answer in _answers) {
      if (answer.question?.type == QuestionType.essay ||
          answer.question?.type == QuestionType.shortAnswer) {
        final ctrl = _scoreControllers[answer.id];
        if (ctrl != null && ctrl.text.isNotEmpty) {
          total += double.tryParse(ctrl.text) ?? 0.0;
        } else {
          total += answer.finalScore;
        }
      } else {
        total += answer.finalScore;
      }
    }
    return total;
  }

  @override
  void initState() {
    super.initState();
    _loadAnswers();
  }

  @override
  void dispose() {
    for (var ctrl in _scoreControllers.values) {
      ctrl.dispose();
    }
    for (var ctrl in _commentControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _loadAnswers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final supabaseClient = context.read<SupabaseRepository>().client;
      final repo = ExamQuestionsRepository(supabaseClient);

      _answers = await repo.getAnswersForSubmission(widget.submission.id);

      // Initialize controllers for essay/short answer
      for (final answer in _answers) {
        if (answer.question?.type == QuestionType.essay ||
            answer.question?.type == QuestionType.shortAnswer) {
          _scoreControllers[answer.id] = TextEditingController(
            text:
                answer.manualScore?.toStringAsFixed(1) ??
                (answer.autoScore != null
                    ? answer.autoScore!.toStringAsFixed(1)
                    : ''),
          );
          _commentControllers[answer.id] = TextEditingController(
            text: answer.teacherComment ?? '',
          );

          _scoreControllers[answer.id]!.addListener(() {
            setState(() {});
          });
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveAllGrades({bool notifyStudent = false}) async {
    setState(() => _isLoading = true);

    try {
      final teacherId = context.read<AuthProvider>().teacherProfile?.id;
      if (teacherId == null) throw Exception('المعلم غير مسجل الدخول');

      final supabaseClient = context.read<SupabaseRepository>().client;
      final examRepo = ExamQuestionsRepository(supabaseClient);
      // NOTE: Capture repo reference before async gap to satisfy use_build_context_synchronously
      final mainRepo = context.read<SupabaseRepository>();

      for (final answer in _answers) {
        if (answer.question?.type == QuestionType.essay ||
            answer.question?.type == QuestionType.shortAnswer) {
          final scoreText = _scoreControllers[answer.id]?.text;
          final commentText = _commentControllers[answer.id]?.text;

          if (scoreText != null && scoreText.isNotEmpty) {
            final score = double.tryParse(scoreText) ?? 0.0;
            await examRepo.gradeAnswer(
              answerId: answer.id,
              manualScore: score,
              teacherComment: commentText?.isNotEmpty == true
                  ? commentText
                  : null,
              teacherId: teacherId,
            );
          }
        }
      }

      // Update the main submission score
      await mainRepo.gradeSubmission(
        submissionId: widget.submission.id,
        score: _currentTotalScore,
        feedback: notifyStudent ? 'تم إرسال إشعار' : 'تم الحفظ كمسودة',
      );

      // TODO: Phase 3 Notification trigger here if notifyStudent == true

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              notifyStudent ? 'تم الحفظ وإشعار الطالب' : 'تم حفظ التعديلات',
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // true = needs refresh
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الحفظ: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'تصحيح: ${widget.submission.studentName ?? "طالب"}',
          style: TextStyle(fontSize: 16.sp, color: Colors.white),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Text(_error!, style: TextStyle(color: Colors.red)),
            )
          : Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: ListView.builder(
                    padding: EdgeInsets.all(16.w),
                    itemCount: _answers.length,
                    itemBuilder: (context, index) {
                      final answer = _answers[index];
                      return _buildAnswerCard(answer, index + 1);
                    },
                  ),
                ),
                _buildBottomActions(),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color:
                (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'إجمالي الدرجات',
                style: TextStyle(
                  color:
                      (Theme.of(context).textTheme.bodySmall?.color ??
                      Colors.grey),
                  fontSize: 12.sp,
                ),
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    _currentTotalScore.toStringAsFixed(1),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    ' / ${widget.maxScore.toStringAsFixed(0)}',
                    style: TextStyle(
                      color:
                          (Theme.of(context).textTheme.bodySmall?.color ??
                          Colors.grey),
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Theme.of(context).colorScheme.primary),
            ),
            child: Text(
              _answers.any(
                    (a) =>
                        a.manualScore == null &&
                        (a.question?.type == QuestionType.essay ||
                            a.question?.type == QuestionType.shortAnswer),
                  )
                  ? 'يوجد أسئلة بانتظار تصحيحك'
                  : 'تم مراجعة كل الأسئلة',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerCard(StudentAnswer answer, int index) {
    if (answer.question == null) return SizedBox.shrink();

    final question = answer.question!;
    final isObjective =
        question.type == QuestionType.mcq ||
        question.type == QuestionType.trueFalse;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isObjective
              ? (answer.isCorrect == true
                    ? Colors.green.withValues(alpha: 0.5)
                    : Theme.of(
                        context,
                      ).colorScheme.error.withValues(alpha: 0.5))
              : (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'س$index (${question.type.arabicName})',
                style: TextStyle(
                  color:
                      (Theme.of(context).textTheme.bodySmall?.color ??
                      Colors.grey),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (isObjective)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: answer.isCorrect == true
                        ? Colors.green.withValues(alpha: 0.2)
                        : Theme.of(
                            context,
                          ).colorScheme.error.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        answer.isCorrect == true ? Icons.check : Icons.close,
                        color: answer.isCorrect == true
                            ? Colors.green
                            : Theme.of(context).colorScheme.error,
                        size: 14.sp,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '${answer.finalScore} / ${question.marks} درجة',
                        style: TextStyle(
                          color: answer.isCorrect == true
                              ? Colors.green
                              : Theme.of(context).colorScheme.error,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Text(
                  'التصحيح من ${question.marks}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),

          // Question Text
          Text(
            question.text,
            style: TextStyle(color: Colors.white, fontSize: 14.sp),
          ),
          SizedBox(height: 16.h),

          // Student Answer
          Container(
            padding: EdgeInsets.all(12.w),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إجابة الطالب:',
                  style: TextStyle(
                    color:
                        (Theme.of(context).textTheme.bodySmall?.color ??
                        Colors.grey),
                    fontSize: 11.sp,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  answer.studentAnswer?.isNotEmpty == true
                      ? answer.studentAnswer!
                      : '(لم يُجب)',
                  style: TextStyle(
                    color: answer.studentAnswer?.isNotEmpty == true
                        ? Colors.white
                        : Colors.white38,
                    fontSize: 13.sp,
                  ),
                ),
              ],
            ),
          ),

          // Show Correct Answer for objective if student was wrong
          if (isObjective &&
              answer.isCorrect == false &&
              question.correctAnswer != null) ...[
            SizedBox(height: 8.h),
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 14.sp),
                SizedBox(width: 4.w),
                Expanded(
                  child: Text(
                    'الإجابة الصحيحة: ${question.correctAnswer}',
                    style: TextStyle(color: Colors.green, fontSize: 12.sp),
                  ),
                ),
              ],
            ),
          ],

          // Teacher Grading Input for Essay/Short Answer
          if (!isObjective) ...[
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _scoreControllers[answer.id],
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: TextStyle(color: Colors.white, fontSize: 14.sp),
                    decoration: InputDecoration(
                      labelText: 'الدرجة المستحقة',
                      labelStyle: TextStyle(
                        color:
                            (Theme.of(context).textTheme.bodySmall?.color ??
                            Colors.grey),
                        fontSize: 12.sp,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  flex: 4,
                  child: TextField(
                    controller: _commentControllers[answer.id],
                    style: TextStyle(color: Colors.white, fontSize: 14.sp),
                    decoration: InputDecoration(
                      labelText: 'ملاحظتك للطالب (اختياري)',
                      labelStyle: TextStyle(
                        color:
                            (Theme.of(context).textTheme.bodySmall?.color ??
                            Colors.grey),
                        fontSize: 12.sp,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.r),
                        borderSide: BorderSide(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color:
                (Theme.of(context).dividerTheme.color ?? Colors.grey.shade300),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _saveAllGrades(notifyStudent: false),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Theme.of(context).colorScheme.primary),
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'حفظ كمسودة',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: () => _saveAllGrades(notifyStudent: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: EdgeInsets.symmetric(vertical: 14.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'حفظ واعتماد النتيجة',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
