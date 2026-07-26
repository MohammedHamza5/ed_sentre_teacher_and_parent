import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/exam_models.dart';
import '../../core/config/app_config.dart';
import '../../demo/mock_database.dart';

class ExamQuestionsRepository {
  final SupabaseClient client;

  ExamQuestionsRepository(this.client);

  /// Get all questions for an assignment
  Future<List<ExamQuestion>> getQuestions(String assignmentId) async {
    if (AppConfig.isDemoMode) {
      final ass = MockDatabase.instance.assignments.firstWhere(
        (a) => a.id == assignmentId,
        orElse: () => MockDatabase.instance.assignments.first,
      );
      if (ass.questions != null) {
        return (ass.questions as List).map((q) => ExamQuestion.fromJson(Map<String, dynamic>.from(q))).toList();
      }
      return [];
    }

    final response = await client
        .from('exam_questions')
        .select()
        .eq('assignment_id', assignmentId)
        .eq('is_deleted', false)
        .order('order_index', ascending: true);

    return (response as List).map((e) => ExamQuestion.fromJson(e)).toList();
  }

  /// Create a new question
  Future<ExamQuestion> createQuestion(ExamQuestion question) async {
    if (AppConfig.isDemoMode) {
      return question;
    }

    final response = await client
        .from('exam_questions')
        .insert({
          'assignment_id': question.assignmentId,
          'text': question.text,
          'type': question.type.value,
          'marks': question.marks,
          'options': question.options,
          'correct_answer': question.correctAnswer,
          'order_index': question.orderIndex,
        })
        .select()
        .single();

    return ExamQuestion.fromJson(response);
  }

  /// Update an existing question
  Future<ExamQuestion> updateQuestion(ExamQuestion question) async {
    if (AppConfig.isDemoMode) {
      return question;
    }

    final response = await client
        .from('exam_questions')
        .update({
          'text': question.text,
          'type': question.type.value,
          'marks': question.marks,
          'options': question.options,
          'correct_answer': question.correctAnswer,
          'order_index': question.orderIndex,
        })
        .eq('id', question.id)
        .select()
        .single();

    return ExamQuestion.fromJson(response);
  }

  /// Soft delete a question
  Future<void> deleteQuestion(String questionId) async {
    if (AppConfig.isDemoMode) return;

    await client
        .from('exam_questions')
        .update({'is_deleted': true})
        .eq('id', questionId);
  }

  /// Reorder a list of questions
  Future<void> reorderQuestions(List<ExamQuestion> questions) async {
    if (AppConfig.isDemoMode) return;

    for (int i = 0; i < questions.length; i++) {
      await client
          .from('exam_questions')
          .update({'order_index': i})
          .eq('id', questions[i].id);
    }
  }

  /// ----------------------------------------
  /// STUDENT ANSWERS
  /// ----------------------------------------

  /// Save or update a single answer
  Future<void> saveAnswer({
    required String submissionId,
    required String questionId,
    required String? textAnswer,
    bool? isCorrect,
    double? autoScore,
  }) async {
    if (AppConfig.isDemoMode) return;

    await client.from('student_answers').upsert({
      'submission_id': submissionId,
      'question_id': questionId,
      'student_answer': textAnswer,
      'is_correct': isCorrect,
      'auto_score': autoScore,
    }, onConflict: 'submission_id,question_id');
  }

  /// Get all answers for a specific submission, including joined question details
  Future<List<StudentAnswer>> getAnswersForSubmission(
    String submissionId,
  ) async {
    if (AppConfig.isDemoMode) {
      final sub = MockDatabase.instance.submissions.firstWhere(
        (s) => s.id == submissionId,
        orElse: () => MockDatabase.instance.submissions.first,
      );
      final ass = MockDatabase.instance.assignments.firstWhere(
        (a) => a.id == sub.assignmentId,
        orElse: () => MockDatabase.instance.assignments.first,
      );
      
      if (ass.questions == null) return [];
      
      return (ass.questions as List).map((q) {
        final eq = ExamQuestion.fromJson(Map<String, dynamic>.from(q));
        return StudentAnswer(
          id: 'ans_${eq.id}_$submissionId',
          submissionId: submissionId,
          questionId: eq.id,
          studentAnswer: eq.type == QuestionType.mcq ? eq.correctAnswer : 'إجابة الطالب التجريبية للأسئلة المقالية.',
          isCorrect: eq.type == QuestionType.mcq ? true : null,
          autoScore: eq.type == QuestionType.mcq ? eq.marks : null,
          manualScore: sub.status == 'graded' ? (eq.type == QuestionType.mcq ? null : eq.marks) : null,
          teacherComment: sub.status == 'graded' ? 'عمل ممتاز ومجهود رائع!' : null,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          question: eq,
        );
      }).toList();
    }

    final response = await client
        .from('student_answers')
        .select('*, exam_questions(*)')
        .eq('submission_id', submissionId);

    return (response as List).map((e) => StudentAnswer.fromJson(e)).toList();
  }

  /// Grade an essay (manual grading by teacher)
  Future<void> gradeAnswer({
    required String answerId,
    required double manualScore,
    String? teacherComment,
    required String teacherId,
  }) async {
    if (AppConfig.isDemoMode) return;

    await client
        .from('student_answers')
        .update({
          'manual_score': manualScore,
          'teacher_comment': teacherComment,
          'graded_by': teacherId,
          'graded_at': DateTime.now().toIso8601String(),
        })
        .eq('id', answerId);
  }
}
