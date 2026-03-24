import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ═══════════════════════════════════════════════════════════════════════════
// AiExamProvider — الحل الجديد: إرسال PDF كـ base64 مباشرة
// بدون استخراج نص — Gemini يقرأ الصور والنصوص والجداول
// ═══════════════════════════════════════════════════════════════════════════

enum GenState { idle, reading, uploading, generating, success, error }

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
      _state == GenState.generating;
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
          GenState.generating => 'المساعد الذكي يقوم بإنشاء الأسئلة حالياً...',
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
        throw Exception('فشل في قراءة محتوى الملف. تأكد أن الملف ليس تالفاً.');
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
      _set(GenState.uploading, 'جاري تحويل الملف إلى صيغة رقمية (Base64)...');
      _setProgress(0.2);

      final base64Pdf = base64Encode(bytes);

      _statusDetail =
          'جاري إرسال الطلب إلى خادم الذكاء الاصطناعي (Edge Function)...';
      _setProgress(0.4);
      notifyListeners();

      // 3. التواصل مع AI
      _set(
        GenState.generating,
        'جاري التواصل مع Gemini AI... قد يستغرق هذا دقيقة.',
      );
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
      _set(
        GenState.success,
        'تم توليد ${result['questions']?.length} سؤال بنجاح!',
      );
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

    // استخرج data
    final data = response.data;
    if (data == null)
      throw Exception('تلقينا رداً فارغاً من الخادم. حاول مرة أخرى.');

    final map = data is Map<String, dynamic> ? data : <String, dynamic>{};

    if (map['success'] == false || map['error'] != null) {
      final remoteErr = map['error']?.toString() ?? 'خطأ غير معروف من خادم AI';
      throw Exception(remoteErr);
    }

    // الـ result هو JSON string
    final resultRaw = map['result'] ?? map['content'];
    if (resultRaw == null) throw Exception('لا يوجد result في الرد.');

    return _parseExam(resultRaw.toString(), difficulty);
  }

  Map<String, dynamic> _parseExam(String raw, String difficulty) {
    var s = raw.trim();
    if (s.startsWith('```json'))
      s = s.substring(7);
    else if (s.startsWith('```'))
      s = s.substring(3);
    if (s.endsWith('```')) s = s.substring(0, s.length - 3);
    s = s.trim();

    final parsed = jsonDecode(s);
    if (parsed is! Map<String, dynamic>) throw Exception('الرد ليس JSON صحيح.');

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
        'text': q['text']?.toString() ?? q['question']?.toString() ?? '',
        'options': opts,
        'correct_answer': correct,
        'explanation':
            q['explanation']?.toString() ?? 'راجع المحتوى للإجابة الصحيحة.',
        'hint': q['hint']?.toString() ?? 'فكر في المفاهيم الأساسية.',
        'difficulty': q['difficulty']?.toString() ?? difficulty,
        'marks': (q['marks'] as num?)?.toInt() ?? 2,
      });
    }

    return {...parsed, 'questions': questions};
  }

  String _friendlyError(String raw) {
    if (raw.contains('GEMINI_API_KEY'))
      return 'مفتاح API غير مضبوط. راجع Supabase secrets.';
    if (raw.contains('quota') || raw.contains('429'))
      return 'تجاوزت حد Gemini اليومي. انتظر قليلاً.';
    if (raw.contains('19.5') || raw.contains('كبير جداً')) return raw;
    if (raw.contains('فارغ') || raw.contains('empty'))
      return 'الملف لا يحتوي على محتوى مقروء.';
    if (raw.contains('timeout')) return 'انتهت مهلة الطلب. جرب ملفاً أصغر.';
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
