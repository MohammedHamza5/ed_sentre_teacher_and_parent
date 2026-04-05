import 'dart:convert';

// ════════════════════════════════════════════════════════════════════════════
// EdSentre AI Exam Models
// ════════════════════════════════════════════════════════════════════════════
// These models map the JSON schema produced by the Edge Function.
// Every field has a safe fallback — AI output can be unpredictable.
// ════════════════════════════════════════════════════════════════════════════

/// Question types supported by the AI generator
enum AiQuestionType {
  mcq,
  trueFalse;

  String get arabicLabel {
    switch (this) {
      case AiQuestionType.mcq:
        return 'اختيار من متعدد';
      case AiQuestionType.trueFalse:
        return 'صح / خطأ';
    }
  }

  static AiQuestionType fromString(String? s) {
    if (s == 'true_false' || s == 'trueFalse') return AiQuestionType.trueFalse;
    return AiQuestionType.mcq;
  }
}

/// Difficulty levels
enum ExamDifficulty {
  easy,
  medium,
  hard,
  mixed;

  String get arabicLabel {
    switch (this) {
      case ExamDifficulty.easy:
        return 'سهل';
      case ExamDifficulty.medium:
        return 'متوسط';
      case ExamDifficulty.hard:
        return 'صعب';
      case ExamDifficulty.mixed:
        return 'متنوع';
    }
  }

  static ExamDifficulty fromString(String? s) {
    switch (s) {
      case 'easy':
        return ExamDifficulty.easy;
      case 'hard':
        return ExamDifficulty.hard;
      case 'mixed':
        return ExamDifficulty.mixed;
      default:
        return ExamDifficulty.medium;
    }
  }
}

// ─── AiQuestionModel ──────────────────────────────────────────────────────────

class AiQuestionModel {
  final String id;
  final AiQuestionType type;
  final String text;
  final List<String> options;
  final int correctAnswerIndex;
  final String explanation;
  final String hint;
  final ExamDifficulty difficulty;
  final int marks;

  const AiQuestionModel({
    required this.id,
    required this.type,
    required this.text,
    required this.options,
    required this.correctAnswerIndex,
    required this.explanation,
    required this.hint,
    required this.difficulty,
    required this.marks,
  });

  /// Safe check whether the student's answer (int index) is correct
  bool isCorrect(int? studentAnswer) => studentAnswer == correctAnswerIndex;

  /// Get the correct option text
  String get correctAnswerText =>
      options.isNotEmpty && correctAnswerIndex < options.length
      ? options[correctAnswerIndex]
      : '';

  factory AiQuestionModel.fromJson(Map<String, dynamic> json) {
    // Support both `correct_answer` (int index) and legacy string formats
    final rawCorrect = json['correct_answer'];
    int correctIdx = 0;
    if (rawCorrect is int) {
      correctIdx = rawCorrect;
    } else if (rawCorrect is String) {
      correctIdx = int.tryParse(rawCorrect) ?? 0;
    }

    // Options — always a list of strings
    final rawOptions = json['options'];
    List<String> opts = [];
    if (rawOptions is List) {
      opts = rawOptions.map((e) => e.toString()).toList();
    }

    // Fallback options for true_false
    final type = AiQuestionType.fromString(json['type']?.toString());
    if (type == AiQuestionType.trueFalse && opts.isEmpty) {
      opts = ['صح', 'خطأ'];
    }

    return AiQuestionModel(
      id: json['id']?.toString() ?? 'q_unknown',
      type: type,
      text: json['text']?.toString() ?? json['question']?.toString() ?? '',
      options: opts,
      correctAnswerIndex: correctIdx,
      explanation:
          json['explanation']?.toString() ??
          'راجع المحتوى للتعرف على الإجابة الصحيحة.',
      hint:
          json['hint']?.toString() ?? 'فكر في المفاهيم الأساسية التي تعلمتها.',
      difficulty: ExamDifficulty.fromString(json['difficulty']?.toString()),
      marks: (json['marks'] as num?)?.toInt() ?? 2,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type == AiQuestionType.trueFalse ? 'true_false' : 'mcq',
    'text': text,
    'options': options,
    'correct_answer': correctAnswerIndex,
    'explanation': explanation,
    'hint': hint,
    'difficulty': difficulty.name,
    'marks': marks,
  };
}

// ─── AiExamModel ──────────────────────────────────────────────────────────────

class AiExamModel {
  final String title;
  final String subject;
  final ExamDifficulty difficulty;
  final int totalMarks;
  final int estimatedTimeMinutes;
  final List<AiQuestionModel> questions;
  final DateTime generatedAt;

  const AiExamModel({
    required this.title,
    required this.subject,
    required this.difficulty,
    required this.totalMarks,
    required this.estimatedTimeMinutes,
    required this.questions,
    required this.generatedAt,
  });

  int get questionCount => questions.length;
  int get mcqCount =>
      questions.where((q) => q.type == AiQuestionType.mcq).length;
  int get trueFalseCount =>
      questions.where((q) => q.type == AiQuestionType.trueFalse).length;

  factory AiExamModel.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'];
    final List<AiQuestionModel> questions = [];

    if (rawQuestions is List) {
      for (final q in rawQuestions) {
        if (q is Map<String, dynamic>) {
          try {
            questions.add(AiQuestionModel.fromJson(q));
          } catch (e) {
            // Skip malformed questions silently
          }
        }
      }
    }

    final count = questions.length;
    return AiExamModel(
      title: json['title']?.toString() ?? 'امتحان بالذكاء الاصطناعي',
      subject: json['subject']?.toString() ?? 'عام',
      difficulty: ExamDifficulty.fromString(json['difficulty']?.toString()),
      totalMarks: (json['total_marks'] as num?)?.toInt() ?? count * 2,
      estimatedTimeMinutes:
          (json['estimated_time_minutes'] as num?)?.toInt() ?? count * 2,
      questions: questions,
      generatedAt: DateTime.now(),
    );
  }

  /// Parse from raw Edge Function JSON string
  static AiExamModel? tryParseFromString(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      // Strip markdown fences if present
      var clean = raw.trim();
      if (clean.startsWith('```json')) {
        clean = clean.substring(7);
      } else if (clean.startsWith('```'))
        clean = clean.substring(3);
      if (clean.endsWith('```')) clean = clean.substring(0, clean.length - 3);
      clean = clean.trim();

      // dart:convert
      final map = jsonDecode(clean);
      if (map is Map<String, dynamic>) {
        return AiExamModel.fromJson(map);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'subject': subject,
    'difficulty': difficulty.name,
    'total_marks': totalMarks,
    'estimated_time_minutes': estimatedTimeMinutes,
    'generated_at': generatedAt.toIso8601String(),
    'questions': questions.map((q) => q.toJson()).toList(),
  };

  /// Convert to the format expected by CreateAssignmentScreen
  List<Map<String, dynamic>> toAssignmentQuestions() {
    return questions.map((q) {
      return {
        'id': q.id,
        'question': q.text,
        'type': q.type == AiQuestionType.trueFalse ? 'true_false' : 'mcq',
        'options': q.options,
        'correct': q.correctAnswerIndex,
        'correct_answer': q.correctAnswerText,
        'marks': q.marks,
        'difficulty': q.difficulty.name,
        'explanation': q.explanation,
        'hint': q.hint,
      };
    }).toList();
  }
}
