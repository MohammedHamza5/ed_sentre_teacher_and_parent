import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/config/app_colors.dart';
import '../../../shared/data/supabase_repository.dart';
import '../../../shared/models/exam_models.dart';
import '../../../shared/models/models.dart';
import 'package:provider/provider.dart';

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
  String _activeFilter = 'all'; // 'all', 'correct', 'wrong', 'unanswered'

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
    debugPrint('\n======================================================');
    debugPrint('🚀 [ExamReview] Loading answers for Submission ID: ${widget.submission.id}');
    debugPrint('======================================================');
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Parse Questions
      List<ExamQuestion> questions = [];
      final dynamic rawQuestions = widget.assignment['questions'];
      debugPrint('🔍 [ExamReview] Checking assignment questions field...');
      debugPrint('   -> Is Null? ${rawQuestions == null}');
      debugPrint('   -> Type: ${rawQuestions.runtimeType}');

      if (rawQuestions != null) {
        List<dynamic> qList = [];
        if (rawQuestions is String) {
          try {
            debugPrint('   -> Parsing String JSON to List...');
            qList = jsonDecode(rawQuestions) as List<dynamic>;
          } catch (e) {
            debugPrint('❌ [ExamReview] Error parsing String to JSON: $e');
          }
        } else if (rawQuestions is List) {
           debugPrint('   -> Assignment Questions is already a List.');
          qList = rawQuestions;
        }

        debugPrint('🔍 [ExamReview] Number of questions found in assignment JSON: ${qList.length}');
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
            
            final dynamic rawCorrect = qData['correct_answer'] ?? 
                                       qData['correct_option_index'] ?? 
                                       qData['correct'];
                                       
            final int? correctIdx = int.tryParse(rawCorrect?.toString() ?? '');

            if (correctIdx != null && options != null && options.length > correctIdx && correctIdx >= 0) {
              correctAnswer = correctIdx.toString(); // Map option index
            } else if (rawCorrect != null && options != null) {
              // Find index by matching text
              final int foundIdx = options.indexWhere((opt) => 
                  opt.toString().trim().toLowerCase() == rawCorrect.toString().trim().toLowerCase());
              if (foundIdx != -1) {
                correctAnswer = foundIdx.toString();
              } else {
                correctAnswer = "0"; // final fallback
              }
            } else {
              correctAnswer = "0"; // final fallback
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
      debugPrint('✅ [ExamReview] Successfully parsed ${questions.length} questions into models.');

      // Fetch new student_answers format from database
      debugPrint('📥 [ExamReview] Querying "student_answers" table from Supabase for submission_id: ${widget.submission.id}...');
      List<dynamic> dbResponse = [];
      if (mounted) {
        final repository = context.read<SupabaseRepository>();
        try {
          dbResponse = await repository.client
              .from('student_answers')
              .select('*')
              .eq('submission_id', widget.submission.id);
          debugPrint('✅ [ExamReview] Received ${dbResponse.length} rows from student_answers table.');
        } catch (e) {
          debugPrint('❌ [ExamReview] Failed to fetch real student_answers: $e');
        }
      }

      final Map<String, Map<String, dynamic>> dbAnswersMap = {};
      for (var row in dbResponse) {
        final map = row as Map<String, dynamic>;
        dbAnswersMap[map['question_id'].toString()] = map;
      }
      debugPrint('🔍 [ExamReview] Mapped DB answers. Keys found: ${dbAnswersMap.keys.toList()}');

      // Parse Submissions
      debugPrint('🔄 [ExamReview] Analysing legacy submission_text JSON...');
      Map<String, dynamic> studentAnswersJson = {};
      final String? subText = widget.submission.submissionText;
      if (subText != null && subText.isNotEmpty) {
        try {
          studentAnswersJson = jsonDecode(subText) as Map<String, dynamic>;
          debugPrint('✅ [ExamReview] Parsed legacy submission JSON. Keys found: ${studentAnswersJson.keys.toList()}');
        } catch (e) {
             debugPrint('❌ [ExamReview] Error parsing legacy JSON: $e');
        }
      } else {
        debugPrint('⚠️ [ExamReview] submissionText is null or empty.');
      }

      // Fallback logic for existing submissions where the student app used dynamic timestamps
      final legacyKeys = studentAnswersJson.keys
          .where((k) => int.tryParse(k) != null && k.length >= 13)
          .toList()
        ..sort((a, b) => int.parse(a).compareTo(int.parse(b)));
        
      debugPrint('🔎 [ExamReview] Mapping student answers to questions...');

      _answers = questions.asMap().entries.map((entry) {
        final i = entry.key;
        final q = entry.value;

        debugPrint('\n--- Processing Question ${i + 1} | ID: ${q.id} | Type: ${q.type.name}');

        // First check if it exists in the real DB (student_answers)
        if (dbAnswersMap.containsKey(q.id)) {
          debugPrint('   🟢 Found answer in Supabase DB! Data: ${dbAnswersMap[q.id]}');
          final dbA = dbAnswersMap[q.id]!;
          return StudentAnswer.fromJson({...dbA, 'exam_questions': q.toJson()});
        }
        
        debugPrint('   🟡 NOT found in Supabase DB by q.id. Falling back to submissionText JSON...');
        dynamic rawAnswer =
            studentAnswersJson[q.id] ??
            studentAnswersJson[q.orderIndex.toString()];

        if (rawAnswer == null && i < legacyKeys.length) {
            debugPrint('   🟡 Trying legacy timestamp key: ${legacyKeys[i]}');
          rawAnswer = studentAnswersJson[legacyKeys[i]];
        }
            
        final String? answerStr = rawAnswer?.toString();
        debugPrint('   -> Extracted Raw Answer: $answerStr');

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

        debugPrint('   -> Evaluated - isCorrect: $isCorrect, Score: $autoScore');

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

      debugPrint('\n✅ [ExamReview] Finished processing all ${_answers.length} answers.');

      if (mounted) {
        setState(() => _isLoading = false);
        _animController.forward();
      }
    } catch (e, stacktrace) {
      debugPrint('\n❌❌❌ [ExamReview] CRITICAL ERROR IN _loadAnswers: $e');
      debugPrint('Stacktrace: $stacktrace');
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
                            (context, index) {
                              final answer = _filteredAnswers[index];
                              final originalIndex = answer.question?.orderIndex ?? index;
                              return _buildAnimatedQuestionCard(
                                answer,
                                originalIndex + 1,
                                index, // delayIndex based on current visible list
                              );
                            },
                            childCount: _filteredAnswers.length,
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
              icon: Icons.list_alt_rounded,
              label: 'الكل (${_answers.length})',
              color: AppColors.accentVivid,
              filterType: 'all',
            ),
            SizedBox(width: 8.w),
            _buildPremiumChip(
              icon: Icons.check_circle,
              label: '$_correctCount صحيح',
              color: const Color(0xFF10B981),
              filterType: 'correct',
            ),
            SizedBox(width: 8.w),
            _buildPremiumChip(
              icon: Icons.cancel,
              label: '$_wrongCount خطأ',
              color: const Color(0xFFEF4444),
              filterType: 'wrong',
            ),
            SizedBox(width: 8.w),
            _buildPremiumChip(
              icon: Icons.help_outline,
              label: '$_unansweredCount مفقود',
              color: const Color(0xFF94A3B8),
              filterType: 'unanswered',
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
    required String filterType,
  }) {
    final bool isActive = _activeFilter == filterType;
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeFilter = filterType;
        });
        _animController.reset();
        _animController.forward();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isActive 
              ? color.withValues(alpha: 0.15) 
              : AppColors.darkSurface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isActive ? color : color.withValues(alpha: 0.2),
            width: isActive ? 1.5 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16.sp, color: isActive ? color : color.withValues(alpha: 0.7)),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white70,
                fontSize: 13.sp,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                fontFamily: 'Cairo', // matching font
              ),
            ),
          ],
        ),
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
