import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/config/app_colors.dart';
import '../../../../shared/models/exam_models.dart';

/// Single question card for the exam review screen.
/// Handles MCQ, True/False, Short Answer, and Essay question types.
class ExamReviewQuestionCard extends StatelessWidget {
  final StudentAnswer answer;
  final int questionNumber;

  const ExamReviewQuestionCard({
    super.key,
    required this.answer,
    required this.questionNumber,
  });

  @override
  Widget build(BuildContext context) {
    if (answer.question == null) return SizedBox.shrink();

    final question = answer.question!;
    final isCorrect = answer.isCorrect == true;
    final isWrong = answer.isCorrect == false;
    final isUnanswered =
        answer.studentAnswer == null ||
        answer.studentAnswer!.isEmpty ||
        answer.studentAnswer == '-1';

    final (stateColor, stateIcon) = _resolveState(
      isCorrect: isCorrect,
      isWrong: isWrong,
      isUnanswered: isUnanswered,
    );

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: stateColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: stateColor.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildCardHeader(
            question: question,
            stateColor: stateColor,
            stateIcon: stateIcon,
            isCorrect: isCorrect,
            isWrong: isWrong,
            isUnanswered: isUnanswered,
          ),

          // Question Text
          Padding(
            padding: EdgeInsets.all(24.w),
            child: Text(
              question.text,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.sp,
                height: 1.6,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Options / Answers
          if (question.type == QuestionType.mcq &&
              question.options != null) ...[
            Padding(
              padding: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 20.h),
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
              padding: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 20.h),
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

  (Color, IconData) _resolveState({
    required bool isCorrect,
    required bool isWrong,
    required bool isUnanswered,
  }) {
    if (isUnanswered) {
      return (const Color(0xFF94A3B8), Icons.hourglass_empty_rounded);
    } else if (isCorrect) {
      return (Colors.green, Icons.check_circle_rounded);
    } else if (isWrong) {
      return (AppColors.danger, Icons.cancel_rounded);
    } else {
      return (AppColors.primary, Icons.subject_rounded);
    }
  }

  Widget _buildCardHeader({
    required ExamQuestion question,
    required Color stateColor,
    required IconData stateIcon,
    required bool isCorrect,
    required bool isWrong,
    required bool isUnanswered,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            stateColor.withValues(alpha: 0.15),
            stateColor.withValues(alpha: 0.05),
          ],
        ),
        border: Border(
          bottom: BorderSide(color: stateColor.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              color: stateColor,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Center(
              child: Text(
                '$questionNumber',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w900,
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
                  color: stateColor.withValues(alpha: 0.9),
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${answer.finalScore.toStringAsFixed(1)} / ${question.marks.toStringAsFixed(1)} نقطة',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: stateColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20.r),
            ),
            child: Row(
              children: [
                Icon(stateIcon, color: stateColor, size: 16.sp),
                SizedBox(width: 4.w),
                Text(
                  isCorrect
                      ? 'إجابة صحيحة'
                      : isWrong
                      ? 'إجابة خاطئة'
                      : isUnanswered
                      ? 'لم يُجب'
                      : 'مراجعة مقالية',
                  style: TextStyle(
                    color: stateColor,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
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

    Color bgColor = const Color(0xFF0F172A).withValues(alpha: 0.5);
    Color borderColor = Colors.white.withValues(alpha: 0.1);
    Color textColor = Colors.white70;
    Widget? trailing;

    if (isStudentChoice && isCorrectOption) {
      bgColor = Colors.green.withValues(alpha: 0.2);
      borderColor = Colors.green;
      textColor = Colors.white;
      trailing = Icon(
        Icons.check_circle_rounded,
        color: Colors.green,
        size: 24.sp,
      );
    } else if (isStudentChoice && !isCorrectOption) {
      bgColor = AppColors.danger.withValues(alpha: 0.2);
      borderColor = AppColors.danger;
      textColor = Colors.white;
      trailing = Icon(
        Icons.cancel_rounded,
        color: AppColors.danger,
        size: 24.sp,
      );
    } else if (isCorrectOption) {
      bgColor = Colors.green.withValues(alpha: 0.05);
      borderColor = Colors.green.withValues(alpha: 0.5);
      textColor = Colors.green;
      trailing = Icon(
        Icons.check_rounded,
        color: Colors.green,
        size: 24.sp,
      );
    }

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: borderColor,
          width: isStudentChoice || isCorrectOption ? 2 : 1,
        ),
        boxShadow: isStudentChoice || isCorrectOption
            ? [
                BoxShadow(
                  color: borderColor.withValues(alpha: 0.1),
                  blurRadius: 10,
                ),
              ]
            : [],
      ),
      child: Row(
        children: [
          Container(
            width: 28.w,
            height: 28.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isStudentChoice ? borderColor : Colors.white30,
                width: 2.5,
              ),
              color: isStudentChoice ? borderColor : Colors.transparent,
            ),
            child: isStudentChoice
                ? Icon(
                    Icons.circle,
                    color: const Color(0xFF0F172A),
                    size: 12.sp,
                  )
                : null,
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Text(
              optionText,
              style: TextStyle(
                color: textColor,
                fontSize: 15.sp,
                fontWeight: isStudentChoice || isCorrectOption
                    ? FontWeight.w900
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
      padding: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Student response box
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.edit_note_rounded,
                      color: Colors.white54,
                      size: 18.sp,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      'إجابة الطالب:',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                Text(
                  answer.studentAnswer?.isNotEmpty == true
                      ? answer.studentAnswer!
                      : 'لا توجد إجابة',
                  style: TextStyle(
                    color: answer.studentAnswer?.isNotEmpty == true
                        ? Colors.white
                        : Colors.white38,
                    fontSize: 15.sp,
                    height: 1.5,
                    fontStyle: answer.studentAnswer?.isNotEmpty == true
                        ? FontStyle.normal
                        : FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),

          // Expected Correct answer box if available
          if (answer.question?.correctAnswer?.isNotEmpty == true) ...[
            SizedBox(height: 16.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: Colors.green.withValues(alpha: 0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        color: Colors.green,
                        size: 18.sp,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'الإجابة النموذجية:',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    answer.question!.correctAnswer!,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.sp,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
