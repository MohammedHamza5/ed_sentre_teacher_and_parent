import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/ai_service.dart';
import '../../../../core/config/ai_config.dart';
import '../services/ai_weakness_detector.dart';
import '../../../../shared/data/supabase_repository.dart';

/// مزود AI للمساعد الذكي — تطبيق المعلم
class AIProvider extends ChangeNotifier {
  final SupabaseRepository _repository;
  late final AiService _aiService;
  late final AIWeaknessDetector _weaknessDetector;

  // ═══════════════════════════════════════════════════════════════════════
  // State
  // ═══════════════════════════════════════════════════════════════════════

  // Daily usage limit
  static const int kDailyGenerationLimit = 5;
  int _todayGenerationCount = 0;

  // Legacy credits (kept for DB compat — no longer blocks usage)
  final int _freeCredits = 0;
  final int _paidCredits = 0;
  bool _isLoadingCredits = false;

  // Knowledge Base
  List<Map<String, dynamic>> _knowledgeBase = [];
  bool _isLoadingKnowledge = false;

  // Generation
  bool _isGenerating = false;
  String? _generationError;

  // Conversations
  List<Map<String, dynamic>> _conversations = [];
  bool _isLoadingConversations = false;

  AIProvider(this._repository) {
    _aiService = AiService(_repository.client);
    _weaknessDetector = AIWeaknessDetector(_repository, _aiService);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // Getters
  // ═══════════════════════════════════════════════════════════════════════

  int get todayGenerationCount => _todayGenerationCount;
  bool get hasReachedDailyLimit =>
      _todayGenerationCount >= kDailyGenerationLimit;
  int get remainingToday => (kDailyGenerationLimit - _todayGenerationCount)
      .clamp(0, kDailyGenerationLimit);

  // Legacy getters (kept for backward compat)
  int get freeCredits => _freeCredits;
  int get paidCredits => _paidCredits;
  int get totalCredits => _freeCredits + _paidCredits;
  bool get isLoadingCredits => _isLoadingCredits;
  List<Map<String, dynamic>> get knowledgeBase => _knowledgeBase;
  bool get isLoadingKnowledge => _isLoadingKnowledge;
  bool get hasKnowledgeBase => _knowledgeBase.isNotEmpty;
  bool get isGenerating => _isGenerating;
  String? get generationError => _generationError;
  List<Map<String, dynamic>> get conversations => _conversations;
  bool get isLoadingConversations => _isLoadingConversations;

  // ═══════════════════════════════════════════════════════════════════════
  // Daily Usage Tracking (replaces credit system)
  // ═══════════════════════════════════════════════════════════════════════

  /// Load today's generation count from usage log
  Future<void> loadDailyUsage() async {
    try {
      final userId = _repository.client.auth.currentUser?.id;
      if (userId == null) return;

      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);

      final response = await _repository.client
          .from('ai_usage_log')
          .select('id')
          .eq('teacher_id', userId)
          .inFilter('action_type', ['generate_exam', 'generate_assignment'])
          .gte('created_at', startOfDay.toIso8601String());

      _todayGenerationCount = (response as List).length;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading daily usage: $e');
    }
  }

  /// Check if teacher can generate and increment counter
  bool canGenerate() => _todayGenerationCount < kDailyGenerationLimit;

  /// Legacy credit methods (kept as no-op stubs for backward compat)
  Future<void> loadCredits() async {
    // NOTE: Credit system removed. Keeping method signature to avoid
    // breaking any existing callers.
    _isLoadingCredits = false;
    notifyListeners();
  }

  Future<bool> useCredits(int amount) async => true;

  // ═══════════════════════════════════════════════════════════════════════
  // إدارة المحادثات
  // ═══════════════════════════════════════════════════════════════════════

  /// جلب قائمة محادثات المعلم
  Future<void> loadConversations() async {
    _isLoadingConversations = true;
    notifyListeners();

    try {
      final userId = _repository.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _repository.client
          .from('teacher_ai_conversations')
          .select()
          .eq('teacher_id', userId)
          .order('last_message_at', ascending: false);

      _conversations = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error loading conversations: $e');
    } finally {
      _isLoadingConversations = false;
      notifyListeners();
    }
  }

  /// إنشاء محادثة جديدة
  Future<String?> createConversation() async {
    try {
      final userId = _repository.client.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _repository.client
          .from('teacher_ai_conversations')
          .insert({'teacher_id': userId, 'title': 'محادثة جديدة'})
          .select('id')
          .single();

      await loadConversations();
      return response['id'] as String;
    } catch (e) {
      debugPrint('Error creating conversation: $e');
      return null;
    }
  }

  /// جلب رسائل محادثة
  Future<List<Map<String, dynamic>>> loadMessages(String conversationId) async {
    try {
      final response = await _repository.client
          .from('teacher_ai_messages')
          .select()
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Error loading messages: $e');
      return [];
    }
  }

  /// إرسال رسالة في المحادثة (مع خصم الرصيد أولاً)
  Future<String?> sendChatMessage({
    required String conversationId,
    required String content,
    required List<Map<String, dynamic>> history,
    String? filePath,
  }) async {
    final cost = AiConfig.getCost(EdSentreTask.teacherChatAssistant);

    // خصم الرصيد أولاً
    if (cost > 0) {
      final deducted = await useCredits(cost);
      if (!deducted) return null;
    }

    try {
      // حفظ رسالة المستخدم
      await _repository.client.from('teacher_ai_messages').insert({
        'conversation_id': conversationId,
        'role': 'user',
        'content': content,
      });

      // بناء سياق المحادثة
      final historyMessages = history
          .map(
            (m) => {
              'role': m['role'] as String,
              'content': m['content'] as String,
            },
          )
          .toList();

      // إرسال إلى AI
      final response = await _aiService.router.executeTask(
        task: EdSentreTask.teacherChatAssistant,
        content: content,
        params: {
          'messages': historyMessages,
          if (filePath != null) 'file_path': filePath,
        },
      );

      final aiReply = response.raw ?? 'عذراً، لم أستطع الرد. حاول مرة أخرى.';

      // حفظ رد AI
      await _repository.client.from('teacher_ai_messages').insert({
        'conversation_id': conversationId,
        'role': 'assistant',
        'content': aiReply,
      });

      // تحديث المحادثة
      await _repository.client
          .from('teacher_ai_conversations')
          .update({
            'last_message_at': DateTime.now().toIso8601String(),
            'message_count': history.length + 2,
          })
          .eq('id', conversationId);

      // تسجيل الاستخدام
      await _logUsage(actionType: 'chat', creditsUsed: cost);

      return aiReply;
    } catch (e) {
      debugPrint('Error sending chat message: $e');
      // لا نسترد الرصيد — Edge Function قد تكون استجابت
      return null;
    }
  }

  /// تسمية المحادثة تلقائياً بعد أول رسالة
  Future<void> autoNameConversation(
    String conversationId,
    String firstMessage,
  ) async {
    try {
      final response = await _aiService.router.executeTask(
        task: EdSentreTask.autoNameConversation,
        content: firstMessage,
      );

      var title = response.raw?.trim() ?? '';
      // تنظيف العنوان
      title = title.replaceAll('"', '').replaceAll("'", '');
      if (title.isEmpty || title.length > 50) {
        title = firstMessage.length > 30
            ? '${firstMessage.substring(0, 30)}...'
            : firstMessage;
      }

      await _repository.client
          .from('teacher_ai_conversations')
          .update({'title': title})
          .eq('id', conversationId);

      await loadConversations();
    } catch (e) {
      debugPrint('Error auto-naming conversation: $e');
    }
  }

  /// حذف محادثة
  Future<bool> deleteConversation(String conversationId) async {
    try {
      await _repository.client
          .from('teacher_ai_conversations')
          .delete()
          .eq('id', conversationId);

      await loadConversations();
      return true;
    } catch (e) {
      debugPrint('Error deleting conversation: $e');
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

  /// تحميل ملف PDF مباشرة إلى Supabase Storage
  Future<String?> uploadDocumentToStorage(File pdfFile) async {
    try {
      final userId = _repository.client.auth.currentUser?.id;
      if (userId == null) return null;

      // Sanitize the filename to avoid InvalidKey exceptions in Supabase Storage
      String originalName = pdfFile.uri.pathSegments.last;

      // 1. Keep only alphanumeric characters, dots, underscores, and dashes
      // This will strip out Arabic characters, spaces, and special symbols
      String sanitizedName = originalName.replaceAll(
        RegExp(r'[^a-zA-Z0-9.\-_]'),
        '',
      );

      // 2. If the name becomes empty (e.g., if it was entirely Arabic), provide a fallback
      if (sanitizedName.isEmpty || sanitizedName == '.pdf') {
        sanitizedName = 'document.pdf';
      }

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_$sanitizedName';
      final filePath = '$userId/$fileName';

      await _repository.client.storage
          .from('ai_documents')
          .upload(
            filePath,
            pdfFile,
            fileOptions: const FileOptions(contentType: 'application/pdf'),
          );

      return filePath;
    } catch (e) {
      debugPrint('Error uploading PDF document: $e');
      return null;
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // إنشاء المحتوى بـ AI
  // ═══════════════════════════════════════════════════════════════════════

  /// إنشاء امتحان
  Future<Map<String, dynamic>?> generateExam({
    String? knowledgeBaseId,
    required String difficulty,
    required int questionCount,
    required String examType,
    String? filePath,
    String? extractedText,
    List<String>? targetChapters,
  }) async {
    // NOTE: Daily limit replaces credit system
    if (!canGenerate()) {
      _generationError = 'اكتمل حدك اليومي (5 امتحانات). عد غداً!';
      notifyListeners();
      return null;
    }

    _isGenerating = true;
    _generationError = null;
    notifyListeners();

    try {
      String content = '';
      String subject = '';
      String grade = '';

      if (knowledgeBaseId != null) {
        final knowledge = _knowledgeBase.firstWhere(
          (k) => k['id'] == knowledgeBaseId,
          orElse: () => {},
        );

        if (knowledge.isEmpty) {
          _generationError = 'لم يتم العثور على المحتوى';
          return null;
        }

        content = knowledge['extracted_text'] as String? ?? '';
        subject = knowledge['subject_name'] as String? ?? '';
        grade = knowledge['grade_level'] as String? ?? '';
      } else if (extractedText != null && extractedText.isNotEmpty) {
        content = extractedText;
        subject = 'مادة مخصصة';
        grade = 'عام';
      } else if (filePath == null) {
        _generationError = 'يجب توفير ملف أو محتوى للامتحان';
        return null;
      }

      final response = await _aiService.router.executeTask(
        task: EdSentreTask.teacherGenerateExam,
        content: content,
        params: {
          'subject': subject,
          'gradeLevel': grade,
          'difficulty': difficulty,
          'questionCount': questionCount,
          'examType': examType,
          'file_path': filePath,
          'targetChapters': targetChapters,
        },
      );

      if (response.isValid && response.json != null) {
        await _logUsage(
          actionType: 'generate_exam',
          creditsUsed: 0,
          inputData: {
            'knowledge_base_id': knowledgeBaseId,
            'difficulty': difficulty,
            'question_count': questionCount,
          },
          outputData: response.json,
        );
        // Increment daily counter immediately
        _todayGenerationCount++;
        return response.json;
      } else {
        _generationError = response.error ?? 'فشل في إنشاء الامتحان';
        if (_generationError == 'empty_response') {
          _generationError =
              'استغرق الطلب وقتًا طويلاً أو لم يصل رد. (يرجى المحاولة بملف أصغر)';
        } else if (_generationError == 'invalid_json' ||
            _generationError == 'invalid_shape' ||
            _generationError == 'missing_questions') {
          _generationError =
              'فشل في معالجة النتيجة من الخادم المكتظة. المحتوى ربما يكون كبيراً جداً.';
        }
        return null;
      }
    } catch (e) {
      _generationError = e.toString();
      if (_generationError!.toLowerCase().contains('timeout') ||
          _generationError!.toLowerCase().contains('deadline')) {
        _generationError = 'استغرق الطلب وقتًا طويلاً. الملف كبير العبء.';
      }
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
    // NOTE: Daily limit replaces credit system
    if (!canGenerate()) {
      _generationError = 'اكتمل حدك اليومي (5 امتحانات). عد غداً!';
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
        await _logUsage(
          actionType: 'generate_assignment',
          creditsUsed: 0,
          inputData: {'topic': topic, 'question_count': questionCount},
          outputData: response.json,
        );
        // Increment daily counter immediately
        _todayGenerationCount++;
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
    String? knowledgeBaseId,
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

      final exam = await _repository.client
          .from('ai_generated_exams')
          .select()
          .eq('id', examId)
          .single();

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
  // تحليل الطلاب (AI العميق)
  // ═══════════════════════════════════════════════════════════════════════

  /// تحليل نقاط ضعف الطالب بالذكاء الاصطناعي
  Future<List<WeaknessInsight>> analyzeStudentWeaknesses({
    required String studentId,
    required String centerId,
  }) async {
    // استخدام التحليل بالذكاء الاصطناعي العميق
    return await _weaknessDetector.analyzeStudentWithAI(
      studentId: studentId,
      centerId: centerId,
    );
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
}
