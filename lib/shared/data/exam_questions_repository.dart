import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../shared/models/exam_models.dart';

class ExamQuestionsRepository {
  final SupabaseClient client;

  ExamQuestionsRepository(this.client);

  /// Get all questions for an assignment
  Future<List<ExamQuestion>> getQuestions(String assignmentId) async {
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
    await client
        .from('exam_questions')
        .update({'is_deleted': true})
        .eq('id', questionId);
  }

  /// Reorder a list of questions
  Future<void> reorderQuestions(List<ExamQuestion> questions) async {
    // Requires a batch update, but PostgREST via Supabase doesn't support bulk upsert without primary keys well.
    // Iterating is fine for small lists (like 10-50 questions)
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
