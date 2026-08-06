import 'dart:io';
import 'dart:convert';
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../shared/data/supabase_repository.dart';
import '../../../../shared/models/group_model.dart';
import '../../domain/entities/ai_exam_blueprint.dart';
import '../../domain/repositories/exam_generator_repository.dart';
import '../models/ai_exam_blueprint_model.dart';
import 'package:flutter/foundation.dart';

class ExamGeneratorRepositoryImpl implements ExamGeneratorRepository {
  final SupabaseRepository _supabaseRepository;

  ExamGeneratorRepositoryImpl(this._supabaseRepository);

  @override
  Future<Either<Failure, AiExamBlueprint>> generateDeepExam({
    String? knowledgeBaseId,
    required String difficulty,
    required int questionCount,
    required String examType,
    String? filePath,
    String? extractedText,
    List<String>? targetChapters,
    String? theme,
  }) async {
    try {
      String content = '';
      String subject = '';
      String grade = '';
      String? pdfBase64;

      if (knowledgeBaseId != null) {
        // Fetch knowledge base details if ID is provided
        final response = await _supabaseRepository.client
            .from('teacher_knowledge_base')
            .select()
            .eq('id', knowledgeBaseId)
            .maybeSingle();

        if (response == null) {
          return const Left(NotFoundFailure(message: 'لم يتم العثور على المحتوى في قاعدة المعرفة'));
        }

        content = response['extracted_text'] as String? ?? '';
        subject = response['subject_name'] as String? ?? '';
        grade = response['grade_level'] as String? ?? '';
        
        // Try to get file_url if text is empty, for edge function to download
        final fileUrl = response['file_url'] as String?;
        if (content.isEmpty && fileUrl != null) {
            try {
                final bytes = await _supabaseRepository.client.storage.from('ai_documents').download(fileUrl);
                if (bytes.isNotEmpty) {
                    final sizeMB = bytes.length / (1024 * 1024);
                    if (sizeMB <= 19.5) {
                        pdfBase64 = base64Encode(bytes);
                    } else {
                        return const Left(ValidationFailure(message: 'حجم الملف في قاعدة المعرفة كبير جداً'));
                    }
                }
            } catch (e) {
                debugPrint('Error downloading knowledge base file: $e');
            }
        }
      } else if (extractedText != null && extractedText.isNotEmpty) {
        content = extractedText;
        subject = 'مادة مخصصة';
        grade = 'عام';
      } else if (filePath != null) {
          try {
             final bytes = File(filePath).readAsBytesSync();
             final sizeMB = bytes.length / (1024 * 1024);
             if (sizeMB > 19.5) {
                 return const Left(ValidationFailure(message: 'حجم الملف كبير جداً. الحد الأقصى هو 19.5 MB'));
             }
             pdfBase64 = base64Encode(bytes);
          } catch (e) {
             return const Left(ValidationFailure(message: 'فشل في قراءة محتوى الملف. تأكد أن الملف ليس تالفاً.'));
          }
      } else {
        return const Left(ValidationFailure(message: 'يجب توفير ملف أو محتوى للامتحان'));
      }

      final params = <String, dynamic>{
        'subject': subject,
        'gradeLevel': grade,
        'difficulty': difficulty,
        'questionCount': questionCount,
        'examType': examType,
        'targetChapters': targetChapters,
      };

      final body = <String, dynamic>{
        'task': pdfBase64 != null ? 'generate_exam' : 'generate_from_text',
        'params': params,
        'difficulty': difficulty,
      };
      
      if (pdfBase64 != null) {
        body['pdfBase64'] = pdfBase64;
      }
      if (content.isNotEmpty) {
        body['content'] = content;
      }

      final response = await _supabaseRepository.client.functions.invoke(
        'ai-exam-generator',
        body: body,
      );

      final data = response.data;
      if (data == null) {
        return const Left(ServerFailure(message: 'تلقينا رداً فارغاً من الخادم. حاول مرة أخرى.'));
      }

      final map = data is Map<String, dynamic> ? data : <String, dynamic>{};
      if (map['success'] == false || map['error'] != null) {
        final remoteErr = map['error']?.toString() ?? 'خطأ غير معروف من خادم AI';
        return Left(ServerFailure(message: remoteErr));
      }

      final resultRaw = map['result'] ?? map['content'];
      if (resultRaw == null) {
        return const Left(ServerFailure(message: 'لا يوجد result في الرد.'));
      }

      // Parse JSON from the result text
      var s = resultRaw.toString().trim();
      if (s.startsWith('```json')) s = s.substring(7);
      if (s.startsWith('```')) s = s.substring(3);
      if (s.endsWith('```')) s = s.substring(0, s.length - 3);
      s = s.trim();

      final parsedJson = jsonDecode(s);
      if (parsedJson is! Map<String, dynamic>) {
        return const Left(ServerFailure(message: 'الرد ليس JSON صحيح.'));
      }

      final blueprint = AiExamBlueprintModel.fromJson(parsedJson);

      // Log to ai_usage_log for daily limit tracking
      final userId = _supabaseRepository.client.auth.currentUser?.id;
      if (userId != null) {
        try {
          await _supabaseRepository.client.from('ai_usage_log').insert({
            'teacher_id': userId,
            'action_type': 'generate_exam',
            'credits_used': 0,
            'input_data': {'examType': examType, 'difficulty': difficulty, 'questionCount': questionCount},
            'output_data': {'title': blueprint.title, 'questions_count': blueprint.questions.length},
          });
        } catch (e) {
          debugPrint('Error logging ai_usage_log: $e');
        }
      }

      return Right(blueprint);
    } catch (e) {
      debugPrint('Error generating deep exam: $e');
      return Left(UnknownFailure(message: 'حدث خطأ أثناء التوليد: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> saveGeneratedExam({
    required String centerId,
    String? knowledgeBaseId,
    required AiExamBlueprint blueprint,
    required String difficulty,
    required String examType,
  }) async {
    try {
      final userId = _supabaseRepository.client.auth.currentUser?.id;
      if (userId == null) return const Left(UnauthorizedFailure());

      // Map Blueprint to JSON for DB insertion
      final blueprintModel = blueprint as AiExamBlueprintModel;
      final blueprintJson = blueprintModel.toJson();

      final response = await _supabaseRepository.client
          .from('ai_generated_exams')
          .insert({
            'teacher_id': userId,
            'center_id': centerId,
            'knowledge_base_id': knowledgeBaseId,
            'title': blueprint.title,
            'exam_type': examType,
            'difficulty': difficulty,
            'questions': blueprintJson['questions'],
            'total_questions': blueprint.questions.length,
            'total_marks': blueprint.totalMarks,
            'time_limit_minutes': blueprint.estimatedTimeMinutes,
            // Custom cognitive data
            'cognitive_distribution': blueprintJson['cognitiveLevelDistribution'],
          })
          .select('id')
          .single();

      return Right(response['id'] as String);
    } catch (e) {
      debugPrint('Error saving deep exam: $e');
      return Left(ServerFailure(message: 'فشل في حفظ الامتحان: $e'));
    }
  }

  @override
  Future<Either<Failure, String>> publishAiExam({
    required String centerId,
    required List<GroupModel> targetGroups,
    required String title,
    String? description,
    required String examType,
    required String difficulty,
    int? timeLimitMinutes,
    required bool showAnswersAfter,
    required bool shuffleQuestions,
    required List<Map<String, dynamic>> editedQuestions,
  }) async {
    try {
      final userId = _supabaseRepository.client.auth.currentUser?.id;
      if (userId == null) {
        return const Left(UnauthorizedFailure());
      }

      if (targetGroups.isEmpty) {
        return const Left(ValidationFailure(message: 'يرجى تحديد مجموعة واحدة على الأقل.'));
      }

      final totalMarks = editedQuestions.fold<int>(
        0,
        (sum, q) => sum + ((q['marks'] as int?) ?? 2),
      );

      // 1. Save to ai_generated_exams
      final aiExamResponse = await _supabaseRepository.client
          .from('ai_generated_exams')
          .insert({
            'teacher_id': userId,
            'center_id': centerId,
            'title': title,
            'exam_type': examType,
            'difficulty': difficulty,
            'questions': editedQuestions,
            'total_questions': editedQuestions.length,
            'total_marks': totalMarks,
            'time_limit_minutes': timeLimitMinutes,
            'shuffle_questions': shuffleQuestions,
            'show_answers_after': showAnswersAfter,
            'is_published': true,
          })
          .select('id')
          .single();

      final aiExamId = aiExamResponse['id'] as String;
      String? firstAssignmentId;

      // 2. Create assignments
      for (int i = 0; i < targetGroups.length; i++) {
        final group = targetGroups[i];

        final assignmentResponse = await _supabaseRepository.client
            .from('assignments')
            .insert({
              'center_id': centerId,
              'group_id': group.id,
              'course_id': group.courseId,
              'teacher_user_id': userId,
              'title': title,
              'description': description ?? 'امتحان منشأ بالذكاء الاصطناعي',
              'type': examType == 'quiz' ? 'quiz' : 'exam',
              'max_score': totalMarks,
              'due_date': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
              'questions': editedQuestions,
              'time_limit_minutes': timeLimitMinutes,
              'settings': {
                'ai_generated': true,
                'ai_exam_id': aiExamId,
                'show_answers_after': showAnswersAfter,
                'shuffle_questions': shuffleQuestions,
                'publish_at': DateTime.now().toIso8601String(),
                'display_mode': 'all',
              },
            })
            .select('id')
            .single();

        final assignmentId = assignmentResponse['id'] as String;
        firstAssignmentId ??= assignmentId;

        // 3. Save questions in exam_questions
        final formattedQuestions = editedQuestions.asMap().entries.map((entry) {
          final q = entry.value;
          String type = 'mcq';
          final rawType = q['type']?.toString() ?? 'mcq';
          if (rawType.contains('true') || rawType.contains('false')) {
            type = 'true_false';
          }

          return {
            'assignment_id': assignmentId,
            'text': q['text']?.toString() ?? '',
            'type': type,
            'marks': (q['marks'] as num?)?.toDouble() ?? 2.0,
            'options': q['options'] ?? [],
            'correct_answer': q['correct_answer']?.toString() ?? '0',
            'explanation': q['explanation']?.toString(),
            'hint': q['hint']?.toString(),
            'order_index': entry.key,
          };
        }).toList();

        await _supabaseRepository.client.from('exam_questions').insert(formattedQuestions);
      }

      // 4. Link
      if (firstAssignmentId != null) {
        await _supabaseRepository.client
            .from('ai_generated_exams')
            .update({'published_to_assignment_id': firstAssignmentId})
            .eq('id', aiExamId);
      }

      return Right(firstAssignmentId ?? aiExamId);
    } catch (e) {
      debugPrint('Error publishing ai exam: $e');
      return Left(ServerFailure(message: 'فشل في حفظ ونشر الامتحان: $e'));
    }
  }
}
