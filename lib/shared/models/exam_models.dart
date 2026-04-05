enum QuestionType {
  mcq,
  trueFalse,
  shortAnswer,
  essay;

  static QuestionType fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'mcq':
        return QuestionType.mcq;
      case 'true_false':
        return QuestionType.trueFalse;
      case 'short_answer':
        return QuestionType.shortAnswer;
      case 'essay':
        return QuestionType.essay;
      default:
        return QuestionType.mcq;
    }
  }

  String get value {
    switch (this) {
      case QuestionType.mcq:
        return 'mcq';
      case QuestionType.trueFalse:
        return 'true_false';
      case QuestionType.shortAnswer:
        return 'short_answer';
      case QuestionType.essay:
        return 'essay';
    }
  }

  String get arabicName {
    switch (this) {
      case QuestionType.mcq:
        return 'اختيار من متعدد';
      case QuestionType.trueFalse:
        return 'صح وخطأ';
      case QuestionType.shortAnswer:
        return 'إجابة قصيرة';
      case QuestionType.essay:
        return 'مقال';
    }
  }
}

class ExamQuestion {
  final String id;
  final String assignmentId;
  final String text;
  final QuestionType type;
  final double marks;
  final List<String>? options;
  final String? correctAnswer;
  final int orderIndex;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;

  const ExamQuestion({
    required this.id,
    required this.assignmentId,
    required this.text,
    required this.type,
    required this.marks,
    this.options,
    this.correctAnswer,
    required this.orderIndex,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
  });

  factory ExamQuestion.fromJson(Map<String, dynamic> json) {
    return ExamQuestion(
      id: json['id'] as String,
      assignmentId: json['assignment_id'] as String,
      text: json['text'] as String,
      type: QuestionType.fromString(json['type']?.toString()),
      marks: (json['marks'] as num?)?.toDouble() ?? 1.0,
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      correctAnswer: json['correct_answer'] as String?,
      orderIndex: json['order_index'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isDeleted: json['is_deleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assignment_id': assignmentId,
      'text': text,
      'type': type.value,
      'marks': marks,
      'options': options,
      'correct_answer': correctAnswer,
      'order_index': orderIndex,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted,
    };
  }
}

class StudentAnswer {
  final String id;
  final String submissionId;
  final String questionId;
  final String? studentAnswer;
  final bool? isCorrect;
  final double? autoScore;
  final double? manualScore;
  final String? teacherComment;
  final String? gradedBy;
  final DateTime? gradedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined relations
  final ExamQuestion? question;

  const StudentAnswer({
    required this.id,
    required this.submissionId,
    required this.questionId,
    this.studentAnswer,
    this.isCorrect,
    this.autoScore,
    this.manualScore,
    this.teacherComment,
    this.gradedBy,
    this.gradedAt,
    required this.createdAt,
    required this.updatedAt,
    this.question,
  });

  factory StudentAnswer.fromJson(Map<String, dynamic> json) {
    return StudentAnswer(
      id: json['id'] as String,
      submissionId: json['submission_id'] as String,
      questionId: json['question_id'] as String,
      studentAnswer: json['student_answer'] as String?,
      isCorrect: json['is_correct'] as bool?,
      autoScore: (json['auto_score'] as num?)?.toDouble(),
      manualScore: (json['manual_score'] as num?)?.toDouble(),
      teacherComment: json['teacher_comment'] as String?,
      gradedBy: json['graded_by'] as String?,
      gradedAt: json['graded_at'] != null
          ? DateTime.parse(json['graded_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      question: json['exam_questions'] != null
          ? ExamQuestion.fromJson(json['exam_questions'])
          : null,
    );
  }

  double get finalScore => manualScore ?? autoScore ?? 0.0;
  bool get isGraded => gradedAt != null || autoScore != null;
}
