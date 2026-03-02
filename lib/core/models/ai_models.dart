class AiExamQuestion {
  final String id;
  final String type;
  final String text;
  final List<String>? options;
  final String correctAnswer;
  final String explanation;
  final int marks;

  AiExamQuestion({
    required this.id,
    required this.type,
    required this.text,
    this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.marks,
  });

  factory AiExamQuestion.fromJson(Map<String, dynamic> json) {
    return AiExamQuestion(
      id: json['id']?.toString() ?? '',
      type: json['type'] ?? '',
      text: json['text'] ?? '',
      options: (json['options'] as List?)?.map((e) => '$e').toList(),
      correctAnswer: json['correct_answer'] ?? '',
      explanation: json['explanation'] ?? '',
      marks: json['marks'] ?? 1,
    );
  }
}

class AiExamQuestionResult {
  final String id;
  final int score;
  final int maxScore;
  final bool isCorrect;
  final String feedback;

  AiExamQuestionResult({
    required this.id,
    required this.score,
    required this.maxScore,
    required this.isCorrect,
    required this.feedback,
  });

  factory AiExamQuestionResult.fromJson(Map<String, dynamic> json) {
    return AiExamQuestionResult(
      id: json['id']?.toString() ?? '',
      score: json['score'] ?? 0,
      maxScore: json['max_score'] ?? 0,
      isCorrect: json['is_correct'] ?? false,
      feedback: json['feedback'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'score': score,
      'max_score': maxScore,
      'is_correct': isCorrect,
      'feedback': feedback,
    };
  }
}

class AiExamResult {
  final int totalScore;
  final int maxScore;
  final double percentage;
  final String gradeLetter;
  final String feedback;
  final List<String> weakPoints;
  final List<String> strongPoints;
  final List<AiExamQuestionResult> questionsResults;

  AiExamResult({
    required this.totalScore,
    required this.maxScore,
    required this.percentage,
    required this.gradeLetter,
    required this.feedback,
    required this.weakPoints,
    required this.strongPoints,
    required this.questionsResults,
  });

  factory AiExamResult.fromJson(Map<String, dynamic> json) {
    return AiExamResult(
      totalScore: json['total_score'] ?? 0,
      maxScore: json['max_score'] ?? 0,
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      gradeLetter: json['grade_letter'] ?? '',
      feedback: json['feedback'] ?? '',
      weakPoints: List<String>.from(json['weak_points'] ?? []),
      strongPoints: List<String>.from(json['strong_points'] ?? []),
      questionsResults: (json['questions_results'] as List? ?? [])
          .map((e) => AiExamQuestionResult.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_score': totalScore,
      'max_score': maxScore,
      'percentage': percentage,
      'grade_letter': gradeLetter,
      'feedback': feedback,
      'weak_points': weakPoints,
      'strong_points': strongPoints,
      'questions_results': questionsResults.map((e) => e.toJson()).toList(),
    };
  }
}

class AiFlashcard {
  final int id;
  final String front;
  final String back;
  final String category;
  final String difficulty;

  AiFlashcard({
    required this.id,
    required this.front,
    required this.back,
    required this.category,
    required this.difficulty,
  });

  factory AiFlashcard.fromJson(Map<String, dynamic> json) {
    return AiFlashcard(
      id: json['id'] ?? 0,
      front: json['front'] ?? '',
      back: json['back'] ?? '',
      category: json['category'] ?? '',
      difficulty: json['difficulty'] ?? 'medium',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'front': front,
      'back': back,
      'category': category,
      'difficulty': difficulty,
    };
  }
}

class AiRouterResponse {
  final String? raw;
  final Map<String, dynamic>? json;
  final String model;
  final bool usedLongContext;
  final bool isValid;
  final String? error;

  const AiRouterResponse({
    this.raw,
    this.json,
    required this.model,
    required this.usedLongContext,
    required this.isValid,
    this.error,
  });
}
