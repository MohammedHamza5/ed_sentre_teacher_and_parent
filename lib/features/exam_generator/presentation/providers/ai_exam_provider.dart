import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ═══════════════════════════════════════════════════════════════════════════
// AiExamProvider — توليد وحفظ ونشر الامتحانات بالذكاء الاصطناعي
// ═══════════════════════════════════════════════════════════════════════════

enum GenState { idle, reading, uploading, generating, saving, success, error }

class AiExamProvider extends ChangeNotifier {
  final SupabaseClient supabase;
  AiExamProvider(this.supabase);

  // ── State ──────────────────────────────────────────────────────────────
  GenState _state = GenState.idle;
  String? _error;
  String? _statusDetail;
  Map<String, dynamic>? _exam;
  double _progress = 0;

  GenState get state => _state;
  String? get error => _error;
  Map<String, dynamic>? get exam => _exam;
  double get progress => _progress;

  bool get isLoading =>
      _state == GenState.reading ||
      _state == GenState.uploading ||
      _state == GenState.generating ||
      _state == GenState.saving;
  bool get hasResult => _state == GenState.success;
  bool get hasError => _state == GenState.error;

  String get statusMessage {
    if (_state == GenState.error) return _error ?? 'حدث خطأ غير متوقع';
    if (_state == GenState.success) return 'تم إنشاء الامتحان بنجاح! 🎉';
    if (_state == GenState.idle) return '';
    return _statusDetail ??
        switch (_state) {
          GenState.reading => 'جاري قراءة الملف...',
          GenState.uploading => 'جاري تجهيز البيانات للذكاء الاصطناعي...',
          GenState.generating =>
            'المساعد الذكي يقوم بإنشاء الأسئلة حالياً...',
          GenState.saving => 'جاري حفظ الامتحان...',
          _ => '',
        };
  }

  // ── توليد من PDF ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>?> generateFromPdf({
    required File pdfFile,
    required int questionCount,
    required String difficulty,
    required String examType,
    String language = 'ar',
  }) async {
    _reset();
    _set(GenState.reading, 'بداية العملية: جاري الوصول للملف...');

    try {
      // 1. قراءة الملف
      _statusDetail = 'جاري قراءة بيانات ملف الـ PDF...';
      notifyListeners();

      final bytes = await compute(_readFileBytes, pdfFile.path);
      if (bytes.isEmpty) {
        throw Exception(
            'فشل في قراءة محتوى الملف. تأكد أن الملف ليس تالفاً.');
      }

      // حساب الحجم
      final sizeMB = bytes.length / (1024 * 1024);
      _statusDetail =
          'تمت القراءة بنجاح. الحجم: ${sizeMB.toStringAsFixed(1)} MB';
      notifyListeners();

      if (sizeMB > 19.5) {
        throw Exception(
          'حجم الملف (${sizeMB.toStringAsFixed(1)} MB) كبير جداً.\n'
          'الحد الأقصى هو 19.5 MB لضمان سرعة المعالجة.',
        );
      }

      // 2. التحويل والتحضير
      _set(GenState.uploading,
          'جاري تحويل الملف إلى صيغة رقمية (Base64)...');
      _setProgress(0.2);

      final base64Pdf = base64Encode(bytes);

      _statusDetail =
          'جاري إرسال الطلب إلى خادم الذكاء الاصطناعي (Edge Function)...';
      _setProgress(0.4);
      notifyListeners();

      // 3. التواصل مع AI
      _set(GenState.generating,
          'جاري التواصل مع Gemini AI... قد يستغرق هذا دقيقة.');
      _setProgress(0.6);

      final result = await _callEdgeFunction(
        task: 'generate_exam',
        pdfBase64: base64Pdf,
        params: {
          'questionCount': questionCount,
          'difficulty': difficulty,
          'examType': examType,
          'language': language,
        },
        difficulty: difficulty,
      );

      _statusDetail = 'تم استلام الأسئلة. جاري معالجة البيانات النهائية...';
      _setProgress(0.9);
      notifyListeners();

      _setProgress(1.0);
      _exam = result;
      _set(GenState.success,
          'تم توليد ${result['questions']?.length} سؤال بنجاح!');
      return result;
    } catch (e) {
      _error = _friendlyError(e.toString());
      _set(GenState.error);
      return null;
    }
  }

  // ── توليد من نص (knowledge base) ───────────────────────────────────────

  Future<Map<String, dynamic>?> generateFromText({
    required String text,
    required int questionCount,
    required String difficulty,
    required String examType,
    String language = 'ar',
  }) async {
    _reset();
    _set(GenState.generating);

    try {
      final result = await _callEdgeFunction(
        task: 'generate_from_text',
        content: text,
        params: {
          'questionCount': questionCount,
          'difficulty': difficulty,
          'examType': examType,
          'language': language,
        },
        difficulty: difficulty,
      );

      _exam = result;
      _set(GenState.success);
      return result;
    } catch (e) {
      _error = _friendlyError(e.toString());
      _set(GenState.error);
      return null;
    }
  }

  // ── حفظ الامتحان في قاعدة البيانات ────────────────────────────────────

  /// يحفظ الامتحان المولّد في جدول `ai_generated_exams`
  /// ثم يُنشئ assignment في `assignments` + أسئلة في `exam_questions`
  Future<String?> saveAndPublishExam({
    required String centerId,
    required String groupId,
    required String title,
    String? description,
    required String examType,
    required String difficulty,
    int? timeLimitMinutes,
    bool showAnswersAfter = true,
    bool shuffleQuestions = false,
    List<Map<String, dynamic>>? editedQuestions,
  }) async {
    if (_exam == null && editedQuestions == null) return null;

    _set(GenState.saving, 'جاري حفظ الامتحان في قاعدة البيانات...');

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('لم يتم تسجيل الدخول');

      final questions = editedQuestions ?? (_exam?['questions'] as List<dynamic>? ?? []);
      final totalMarks = questions.fold<int>(
        0,
        (sum, q) => sum + ((q as Map)['marks'] as int? ?? 2),
      );

      // 1. حفظ في `ai_generated_exams`
      _statusDetail = 'جاري حفظ بيانات الامتحان...';
      _setProgress(0.3);
      notifyListeners();

      final aiExamResponse = await supabase
          .from('ai_generated_exams')
          .insert({
            'teacher_id': userId,
            'center_id': centerId,
            'title': title,
            'exam_type': examType,
            'difficulty': difficulty,
            'questions': questions,
            'total_questions': questions.length,
            'total_marks': totalMarks,
            'time_limit_minutes': timeLimitMinutes,
            'shuffle_questions': shuffleQuestions,
            'show_answers_after': showAnswersAfter,
            'is_published': true,
          })
          .select('id')
          .single();

      final aiExamId = aiExamResponse['id'] as String;

      // 2. إنشاء assignment في جدول assignments
      _statusDetail = 'جاري نشر الامتحان للطلاب...';
      _setProgress(0.6);
      notifyListeners();

      final assignmentResponse = await supabase
          .from('assignments')
          .insert({
            'center_id': centerId,
            'group_id': groupId,
            'teacher_user_id': userId,
            'title': title,
            'description': description ?? 'امتحان منشأ بالذكاء الاصطناعي',
            'type': examType == 'quiz' ? 'quiz' : 'exam',
            'max_score': totalMarks,
            'questions': questions,
            'time_limit_minutes': timeLimitMinutes,
            'settings': {
              'ai_generated': true,
              'ai_exam_id': aiExamId,
              'show_answers_after': showAnswersAfter,
              'shuffle_questions': shuffleQuestions,
            },
          })
          .select('id')
          .single();

      final assignmentId = assignmentResponse['id'] as String;

      // 3. حفظ الأسئلة في `exam_questions`
      _statusDetail = 'جاري حفظ الأسئلة...';
      _setProgress(0.8);
      notifyListeners();

      final formattedQuestions =
          questions.asMap().entries.map((entry) {
        final q = entry.value as Map<String, dynamic>;

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

      await supabase.from('exam_questions').insert(formattedQuestions);

      // 4. ربط الامتحان بالـ assignment
      await supabase
          .from('ai_generated_exams')
          .update({'published_to_assignment_id': assignmentId})
          .eq('id', aiExamId);

      _setProgress(1.0);
      _set(GenState.success, 'تم نشر الامتحان بنجاح! 🎉');
      return assignmentId;
    } catch (e) {
      _error = _friendlyError(e.toString());
      _set(GenState.error);
      return null;
    }
  }

  // ── الحصول على قائمة الامتحانات المحفوظة ──────────────────────────────

  Future<List<Map<String, dynamic>>> getSavedExams() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await supabase
        .from('ai_generated_exams')
        .select()
        .eq('teacher_id', userId)
        .order('created_at', ascending: false);

    return (response as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  void reset() => _reset();

  // ── Private helpers ─────────────────────────────────────────────────────

  void _reset() {
    _state = GenState.idle;
    _error = null;
    _statusDetail = null;
    _exam = null;
    _progress = 0;
    notifyListeners();
  }

  void _set(GenState s, [String? detail]) {
    _state = s;
    if (detail != null) _statusDetail = detail;
    notifyListeners();
  }

  void _setProgress(double v) {
    _progress = v;
    notifyListeners();
  }

  Future<Map<String, dynamic>> _callEdgeFunction({
    required String task,
    String? pdfBase64,
    String? content,
    required Map<String, dynamic> params,
    required String difficulty,
  }) async {
    final body = <String, dynamic>{
      'task': task,
      'params': params,
      'difficulty': difficulty,
    };
    if (pdfBase64 != null) body['pdfBase64'] = pdfBase64;
    if (content != null) body['content'] = content;

    _statusDetail = 'جاري استدعاء وظيفة الحوسبة السحابية...';
    notifyListeners();

    final response = await supabase.functions.invoke(
      'ai-exam-generator',
      body: body,
    );

    final data = response.data;
    if (data == null) {
      throw Exception('تلقينا رداً فارغاً من الخادم. حاول مرة أخرى.');
    }

    final map =
        data is Map<String, dynamic> ? data : <String, dynamic>{};

    if (map['success'] == false || map['error'] != null) {
      final remoteErr =
          map['error']?.toString() ?? 'خطأ غير معروف من خادم AI';
      throw Exception(remoteErr);
    }

    final resultRaw = map['result'] ?? map['content'];
    if (resultRaw == null) throw Exception('لا يوجد result في الرد.');

    return _parseExam(resultRaw.toString(), difficulty);
  }

  Map<String, dynamic> _parseExam(String raw, String difficulty) {
    var s = raw.trim();
    if (s.startsWith('```json')) s = s.substring(7);
    if (s.startsWith('```')) s = s.substring(3);
    if (s.endsWith('```')) s = s.substring(0, s.length - 3);
    s = s.trim();

    final parsed = jsonDecode(s);
    if (parsed is! Map<String, dynamic>) {
      throw Exception('الرد ليس JSON صحيح.');
    }

    final rawQ = parsed['questions'];
    if (rawQ is! List || rawQ.isEmpty) {
      throw Exception('AI لم يُنشئ أي أسئلة. تأكد من محتوى الملف.');
    }

    // Normalize questions
    final questions = <Map<String, dynamic>>[];
    for (var i = 0; i < rawQ.length; i++) {
      final q = rawQ[i];
      if (q is! Map) continue;

      final rawOpts = q['options'];
      final opts = rawOpts is List
          ? rawOpts.map((e) => e.toString()).toList()
          : <String>['صح', 'خطأ'];

      final rawCA = q['correct_answer'];
      final correct = rawCA is int
          ? rawCA
          : int.tryParse(rawCA?.toString() ?? '0') ?? 0;

      questions.add({
        'id': q['id']?.toString() ?? 'q_${i + 1}',
        'type': q['type']?.toString() ?? 'mcq',
        'text':
            q['text']?.toString() ?? q['question']?.toString() ?? '',
        'options': opts,
        'correct_answer': correct,
        'explanation': q['explanation']?.toString() ??
            'راجع المحتوى للإجابة الصحيحة.',
        'hint': q['hint']?.toString() ??
            'فكر في المفاهيم الأساسية.',
        'difficulty': q['difficulty']?.toString() ?? difficulty,
        'marks': (q['marks'] as num?)?.toInt() ?? 2,
      });
    }

    return {
      ...parsed,
      'questions': questions,
    };
  }

  String _friendlyError(String raw) {
    if (raw.contains('GEMINI_API_KEY')) {
      return 'مفتاح API غير مضبوط. راجع Supabase secrets.';
    }
    if (raw.contains('quota') || raw.contains('429')) {
      return 'تجاوزت حد Gemini اليومي. انتظر قليلاً.';
    }
    if (raw.contains('19.5') || raw.contains('كبير جداً')) return raw;
    if (raw.contains('فارغ') || raw.contains('empty')) {
      return 'الملف لا يحتوي على محتوى مقروء.';
    }
    if (raw.contains('timeout')) {
      return 'انتهت مهلة الطلب. جرب ملفاً أصغر.';
    }
    if (raw.length > 150) return '${raw.substring(0, 150)}...';
    return raw;
  }
}

// ─── Isolate helper — قراءة ملف في الخلفية ─────────────────────────────────

Uint8List _readFileBytes(String path) {
  try {
    return File(path).readAsBytesSync();
  } catch (_) {
    return Uint8List(0);
  }
}
