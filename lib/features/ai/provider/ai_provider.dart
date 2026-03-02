import 'package:flutter/foundation.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/config/ai_config.dart';
import '../services/ai_weakness_detector.dart';
import '../../../shared/data/supabase_repository.dart';

/// مزود AI للمساعد الذكي
class AIProvider extends ChangeNotifier {
  final SupabaseRepository _repository;
  late final AiService _aiService;
  late final AIWeaknessDetector _weaknessDetector;

  // ... (State variables)
  // حالة الرصيد
  int _freeCredits = 0;
  int _paidCredits = 0;
  bool _isLoadingCredits = false;

  // حالة قاعدة المعرفة
  List<Map<String, dynamic>> _knowledgeBase = [];
  bool _isLoadingKnowledge = false;

  // حالة الإنشاء
  bool _isGenerating = false;
  String? _generationError;

  AIProvider(this._repository) {
    _aiService = AiService(_repository.client);
    _weaknessDetector = AIWeaknessDetector(_repository, _aiService);
  }

  // Getters
  int get freeCredits => _freeCredits;
  int get paidCredits => _paidCredits;
  int get totalCredits => _freeCredits + _paidCredits;
  bool get isLoadingCredits => _isLoadingCredits;
  List<Map<String, dynamic>> get knowledgeBase => _knowledgeBase;
  bool get isLoadingKnowledge => _isLoadingKnowledge;
  bool get hasKnowledgeBase => _knowledgeBase.isNotEmpty;
  bool get isGenerating => _isGenerating;
  String? get generationError => _generationError;

  // ═══════════════════════════════════════════════════════════════════════
  // إدارة الرصيد
  // ═══════════════════════════════════════════════════════════════════════

  /// جلب رصيد المعلم
  Future<void> loadCredits() async {
    _isLoadingCredits = true;
    notifyListeners();

    try {
      final userId = _repository.client.auth.currentUser?.id;
      if (userId == null) return;

      final result = await _repository.client.rpc(
        'get_ai_credits',
        params: {'p_teacher_id': userId},
      );

      if (result != null) {
        _freeCredits = result['free_credits'] ?? 0;
        _paidCredits = result['paid_credits'] ?? 0;
      }
    } catch (e) {
      debugPrint('Error loading credits: $e');
    } finally {
      _isLoadingCredits = false;
      notifyListeners();
    }
  }

  /// استخدام رصيد
  Future<bool> useCredits(int amount) async {
    try {
      final userId = _repository.client.auth.currentUser?.id;
      if (userId == null) return false;

      final result = await _repository.client.rpc(
        'use_ai_credits',
        params: {'p_teacher_id': userId, 'p_credits_needed': amount},
      );

      if (result['success'] == true) {
        await loadCredits();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Error using credits: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // إدارة قاعدة المعرفة
  // ═══════════════════════════════════════════════════════════════════════

  /// جلب قاعدة معرفة المعلم
  Future<void> loadKnowledgeBase(String centerId) async {
    _isLoadingKnowledge = true;
    notifyListeners();

    try {
      final userId = _repository.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _repository.client
          .from('teacher_knowledge_base')
          .select('*, courses:course_id(name)')
          .eq('teacher_id', userId)
          .eq('center_id', centerId)
          .order('created_at', ascending: false);

      _knowledgeBase = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error loading knowledge base: $e');
    } finally {
      _isLoadingKnowledge = false;
      notifyListeners();
    }
  }

  /// إضافة محتوى لقاعدة المعرفة
  Future<String?> addToKnowledgeBase({
    required String centerId,
    required String title,
    required String contentType,
    required String extractedText,
    String? courseId,
    String? fileUrl,
    String? fileName,
    String? gradeLevel,
    String? subjectName,
    List<String>? chapters,
  }) async {
    try {
      final userId = _repository.client.auth.currentUser?.id;
      if (userId == null) return null;

      // تقسيم النص إلى أجزاء للبحث
      final chunks = _splitIntoChunks(extractedText, 1000);

      final response = await _repository.client
          .from('teacher_knowledge_base')
          .insert({
            'teacher_id': userId,
            'center_id': centerId,
            'course_id': courseId,
            'title': title,
            'content_type': contentType,
            'original_file_url': fileUrl,
            'original_file_name': fileName,
            'extracted_text': extractedText,
            'chunks': chunks,
            'grade_level': gradeLevel,
            'subject_name': subjectName,
            'chapters': chapters ?? [],
            'processing_status': 'completed',
          })
          .select('id')
          .single();

      await loadKnowledgeBase(centerId);
      return response['id'] as String;
    } catch (e) {
      debugPrint('Error adding to knowledge base: $e');
      return null;
    }
  }

  /// حذف من قاعدة المعرفة
  Future<bool> deleteFromKnowledgeBase(String id, String centerId) async {
    try {
      await _repository.client
          .from('teacher_knowledge_base')
          .delete()
          .eq('id', id);

      await loadKnowledgeBase(centerId);
      return true;
    } catch (e) {
      debugPrint('Error deleting from knowledge base: $e');
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // إنشاء المحتوى بـ AI
  // ═══════════════════════════════════════════════════════════════════════

  /// إنشاء امتحان
  Future<Map<String, dynamic>?> generateExam({
    required String knowledgeBaseId,
    required String difficulty,
    required int questionCount,
    required String examType,
    List<String>? targetChapters,
  }) async {
    // التحقق من الرصيد
    final cost = 15; // Fixed cost or derive from config
    if (totalCredits < cost) {
      _generationError = 'رصيد غير كافٍ. تحتاج $cost رصيد';
      notifyListeners();
      return null;
    }

    _isGenerating = true;
    _generationError = null;
    notifyListeners();

    try {
      // جلب المحتوى من قاعدة المعرفة
      final knowledge = _knowledgeBase.firstWhere(
        (k) => k['id'] == knowledgeBaseId,
        orElse: () => {},
      );

      if (knowledge.isEmpty) {
        _generationError = 'لم يتم العثور على المحتوى';
        return null;
      }

      final content = knowledge['extracted_text'] as String? ?? '';
      final subject = knowledge['subject_name'] as String? ?? '';
      final grade = knowledge['grade_level'] as String? ?? '';

      // استدعاء AI عبر Router الجديد
      final response = await _aiService.router.executeTask(
        task: EdSentreTask.teacherGenerateExam,
        content: content,
        params: {
          'subject': subject,
          'gradeLevel': grade,
          'difficulty': difficulty,
          'questionCount': questionCount,
          'examType': examType,
          'targetChapters': targetChapters,
        },
      );

      if (response.isValid && response.json != null) {
        // خصم الرصيد
        await useCredits(cost);

        // تسجيل الاستخدام
        await _logUsage(
          actionType: 'generate_exam',
          creditsUsed: cost,
          inputData: {
            'knowledge_base_id': knowledgeBaseId,
            'difficulty': difficulty,
            'question_count': questionCount,
          },
          outputData: response.json,
        );

        return response.json;
      } else {
        _generationError = response.error ?? 'فشل في إنشاء الامتحان';
        return null;
      }
    } catch (e) {
      _generationError = e.toString();
      return null;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  /// إنشاء واجب
  Future<Map<String, dynamic>?> generateAssignment({
    required String knowledgeBaseId,
    required String topic,
    required int questionCount,
  }) async {
    final cost = 10;
    if (totalCredits < cost) {
      _generationError = 'رصيد غير كافٍ';
      notifyListeners();
      return null;
    }

    _isGenerating = true;
    _generationError = null;
    notifyListeners();

    try {
      final knowledge = _knowledgeBase.firstWhere(
        (k) => k['id'] == knowledgeBaseId,
        orElse: () => {},
      );

      if (knowledge.isEmpty) {
        _generationError = 'لم يتم العثور على المحتوى';
        return null;
      }

      final content = knowledge['extracted_text'] as String? ?? '';

      final response = await _aiService.router.executeTask(
        task: EdSentreTask.teacherGenerateAssignment,
        content: content,
        params: {
          'subject': knowledge['subject_name'] ?? '',
          'gradeLevel': knowledge['grade_level'] ?? '',
          'topic': topic,
          'questionCount': questionCount,
        },
      );

      if (response.isValid && response.json != null) {
        await useCredits(cost);
        await _logUsage(
          actionType: 'generate_assignment',
          creditsUsed: cost,
          inputData: {'topic': topic, 'question_count': questionCount},
          outputData: response.json,
        );
        return response.json;
      } else {
        _generationError = response.error;
        return null;
      }
    } catch (e) {
      _generationError = e.toString();
      return null;
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  /// حفظ الامتحان المُنشأ
  Future<String?> saveGeneratedExam({
    required String centerId,
    required String knowledgeBaseId,
    required String title,
    required String examType,
    required String difficulty,
    required Map<String, dynamic> examData,
  }) async {
    try {
      final userId = _repository.client.auth.currentUser?.id;
      if (userId == null) return null;

      final questions = examData['questions'] as List? ?? [];

      final response = await _repository.client
          .from('ai_generated_exams')
          .insert({
            'teacher_id': userId,
            'center_id': centerId,
            'knowledge_base_id': knowledgeBaseId,
            'title': title,
            'exam_type': examType,
            'difficulty': difficulty,
            'questions': questions,
            'total_questions': questions.length,
            'total_marks': examData['total_marks'] ?? 0,
            'time_limit_minutes': examData['estimated_time_minutes'],
          })
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      debugPrint('Error saving exam: $e');
      return null;
    }
  }

  /// نشر الامتحان كـ Assignment
  Future<String?> publishExamAsAssignment({
    required String examId,
    required String centerId,
    required String courseId,
    required DateTime dueDate,
  }) async {
    try {
      final userId = _repository.client.auth.currentUser?.id;
      if (userId == null) return null;

      // جلب الامتحان
      final exam = await _repository.client
          .from('ai_generated_exams')
          .select()
          .eq('id', examId)
          .single();

      // إنشاء Assignment
      final assignmentResponse = await _repository.client
          .from('assignments')
          .insert({
            'center_id': centerId,
            'course_id': courseId,
            'teacher_user_id': userId,
            'title': exam['title'],
            'description': 'امتحان مُنشأ بواسطة المساعد الذكي',
            'due_date': dueDate.toIso8601String(),
            'max_score': exam['total_marks'],
          })
          .select('id')
          .single();

      final assignmentId = assignmentResponse['id'] as String;

      // تحديث الامتحان بالربط
      await _repository.client
          .from('ai_generated_exams')
          .update({
            'is_published': true,
            'published_to_assignment_id': assignmentId,
          })
          .eq('id', examId);

      return assignmentId;
    } catch (e) {
      debugPrint('Error publishing exam: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Helper Methods
  // ═══════════════════════════════════════════════════════════════════════

  List<Map<String, dynamic>> _splitIntoChunks(String text, int chunkSize) {
    final chunks = <Map<String, dynamic>>[];
    final words = text.split(' ');
    var currentChunk = StringBuffer();
    var chunkIndex = 0;

    for (final word in words) {
      if (currentChunk.length + word.length > chunkSize) {
        chunks.add({
          'index': chunkIndex,
          'text': currentChunk.toString().trim(),
        });
        currentChunk = StringBuffer();
        chunkIndex++;
      }
      currentChunk.write('$word ');
    }

    if (currentChunk.isNotEmpty) {
      chunks.add({'index': chunkIndex, 'text': currentChunk.toString().trim()});
    }

    return chunks;
  }

  Future<void> _logUsage({
    required String actionType,
    required int creditsUsed,
    Map<String, dynamic>? inputData,
    Map<String, dynamic>? outputData,
  }) async {
    try {
      final userId = _repository.client.auth.currentUser?.id;
      if (userId == null) return;

      await _repository.client.from('ai_usage_log').insert({
        'teacher_id': userId,
        'action_type': actionType,
        'credits_used': creditsUsed,
        'input_data': inputData,
        'output_data': outputData,
      });
    } catch (e) {
      debugPrint('Error logging usage: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // The Seer (Weakness Detector)
  // ═══════════════════════════════════════════════════════════════════════

  /// تحليل نقاط ضعف الطالب
  Future<List<WeaknessInsight>> analyzeStudentWeaknesses({
    required String studentId,
    required String centerId,
  }) async {
    return await _weaknessDetector.analyzeStudent(
      studentId: studentId,
      centerId: centerId,
    );
  }
}
