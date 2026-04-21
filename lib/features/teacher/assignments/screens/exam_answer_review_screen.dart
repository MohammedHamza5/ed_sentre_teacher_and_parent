import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/config/app_colors.dart';
import '../../../../shared/data/supabase_repository.dart';
import '../../../../shared/models/exam_models.dart';
import '../../../../shared/models/models.dart';
import 'package:provider/provider.dart';

// Extracted Widgets
import '../widgets/exam_review_header.dart';
import '../widgets/exam_review_scoreboard.dart';
import '../widgets/exam_review_filter_chips.dart';
import '../widgets/exam_review_question_card.dart';

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
  String _activeFilter = 'all';

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

  List<StudentAnswer> get _filteredAnswers {
    switch (_activeFilter) {
      case 'correct':
        return _answers.where((a) => a.isCorrect == true).toList();
      case 'wrong':
        return _answers.where((a) => a.isCorrect == false).toList();
      case 'unanswered':
        return _answers
            .where(
              (a) =>
                  a.studentAnswer == null ||
                  a.studentAnswer!.isEmpty ||
                  a.studentAnswer == '-1',
            )
            .toList();
      default:
        return _answers;
    }
  }

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
      final questions = _parseQuestions();
      final dbAnswersMap = await _fetchDbAnswers();
      final legacyAnswersJson = _parseLegacySubmission();

      // NOTE: Fallback for legacy submissions where the student app used
      // dynamic timestamps as keys instead of question IDs.
      final legacyKeys = legacyAnswersJson.keys
          .where((k) => int.tryParse(k) != null && k.length >= 13)
          .toList()
        ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));

      _answers = questions.asMap().entries.map((entry) {
        final i = entry.key;
        final q = entry.value;

        // First check real DB (student_answers table)
        if (dbAnswersMap.containsKey(q.id)) {
          final dbA = dbAnswersMap[q.id]!;
          return StudentAnswer.fromJson({...dbA, 'exam_questions': q.toJson()});
        }

        // Fallback to legacy submission_text JSON
        dynamic rawAnswer =
            legacyAnswersJson[q.id] ??
            legacyAnswersJson[q.orderIndex.toString()];
        if (rawAnswer == null && i < legacyKeys.length) {
          rawAnswer = legacyAnswersJson[legacyKeys[i]];
        }

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
            isCorrect = answerStr.trim().toLowerCase() ==
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
      debugPrint('❌ [ExamReview] CRITICAL ERROR: $e');
      if (mounted) {
        setState(() {
          _error = 'خطأ في جلب البيانات: $e';
          _isLoading = false;
        });
      }
    }
  }

  List<ExamQuestion> _parseQuestions() {
    final List<ExamQuestion> questions = [];
    final dynamic rawQuestions = widget.assignment['questions'];
    if (rawQuestions == null) return questions;

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

      double marks = (qData['points'] as num?)?.toDouble() ??
          (qData['marks'] as num?)?.toDouble() ??
          1.0;

      List<String>? options;
      if (qData['options'] != null && qData['options'] is List) {
        options =
            (qData['options'] as List).map((e) => e.toString()).toList();
      }

      final String qId = qData['id']?.toString() ?? i.toString();

      String? correctAnswer;
      if (questionType == QuestionType.mcq ||
          questionType == QuestionType.trueFalse) {
        final dynamic rawCorrect = qData['correct_answer'] ??
            qData['correct_option_index'] ??
            qData['correct'];
        final int? correctIdx = int.tryParse(rawCorrect?.toString() ?? '');

        if (correctIdx != null &&
            options != null &&
            options.length > correctIdx &&
            correctIdx >= 0) {
          correctAnswer = correctIdx.toString();
        } else if (rawCorrect != null && options != null) {
          final int foundIdx = options.indexWhere((opt) =>
              opt.toString().trim().toLowerCase() ==
              rawCorrect.toString().trim().toLowerCase());
          correctAnswer = foundIdx != -1 ? foundIdx.toString() : '0';
        } else {
          correctAnswer = '0';
        }
      } else {
        correctAnswer = qData['correct_answer']?.toString();
      }

      questions.add(
        ExamQuestion(
          id: qId,
          assignmentId: widget.assignment['id']?.toString() ?? '',
          text: qData['question']?.toString() ??
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
    return questions;
  }

  Future<Map<String, Map<String, dynamic>>> _fetchDbAnswers() async {
    final Map<String, Map<String, dynamic>> dbAnswersMap = {};
    if (!mounted) return dbAnswersMap;

    try {
      final repository = context.read<SupabaseRepository>();
      final dbResponse = await repository.client
          .from('student_answers')
          .select('*')
          .eq('submission_id', widget.submission.id);
      for (var row in dbResponse) {
        dbAnswersMap[row['question_id'].toString()] = row;
      }
    } catch (e) {
      debugPrint('❌ [ExamReview] Failed to fetch student_answers: $e');
    }
    return dbAnswersMap;
  }

  Map<String, dynamic> _parseLegacySubmission() {
    final String? subText = widget.submission.submissionText;
    if (subText != null && subText.isNotEmpty) {
      try {
        return jsonDecode(subText) as Map<String, dynamic>;
      } catch (_) {}
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
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
                    // Background gradient burst
                    Positioned(
                      top: -100,
                      right: -100,
                      child: Container(
                        width: 300.w,
                        height: 300.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              AppColors.accentVivid.withValues(alpha: 0.15),
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
                          SliverToBoxAdapter(
                            child: SizedBox(height: 100.h),
                          ),
                          SliverToBoxAdapter(
                            child: ExamReviewHeader(
                              submission: widget.submission,
                              assignmentTitle: widget.assignmentTitle,
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: ExamReviewScoreboard(
                              totalScore: _totalScore,
                              maxScore: widget.maxScore,
                              percentage: _percentage,
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: ExamReviewFilterChips(
                              activeFilter: _activeFilter,
                              totalCount: _answers.length,
                              correctCount: _correctCount,
                              wrongCount: _wrongCount,
                              unansweredCount: _unansweredCount,
                              onFilterChanged: (filter) {
                                setState(() => _activeFilter = filter);
                                _animController.reset();
                                _animController.forward();
                              },
                            ),
                          ),
                          SliverPadding(
                            padding:
                                EdgeInsets.symmetric(horizontal: 20.w),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final answer = _filteredAnswers[index];
                                  final originalIndex =
                                      answer.question?.orderIndex ?? index;
                                  return SlideTransition(
                                    position: Tween<Offset>(
                                      begin: const Offset(0.2, 0),
                                      end: Offset.zero,
                                    ).animate(
                                      CurvedAnimation(
                                        parent: _animController,
                                        curve: Interval(
                                          (index * 0.1).clamp(0.0, 1.0),
                                          1.0,
                                          curve: Curves.easeOutBack,
                                        ),
                                      ),
                                    ),
                                    child: Padding(
                                      padding:
                                          EdgeInsets.only(bottom: 24.h),
                                      child: ExamReviewQuestionCard(
                                        answer: answer,
                                        questionNumber: originalIndex + 1,
                                      ),
                                    ),
                                  );
                                },
                                childCount: _filteredAnswers.length,
                              ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: SizedBox(height: 40.h),
                          ),
                        ],
                      ),
                    ),
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
