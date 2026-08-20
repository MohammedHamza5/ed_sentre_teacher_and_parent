import '../../domain/entities/cognitive_level.dart';
import '../../domain/entities/distractor_analysis.dart';
import '../../domain/entities/ai_generated_question.dart';
import '../../domain/entities/ai_exam_blueprint.dart';
import '../../../../shared/models/exam_models.dart';

class DistractorAnalysisModel extends DistractorAnalysis {
  const DistractorAnalysisModel({
    required super.optionText,
    required super.likelyReason,
    required super.correctiveFeedback,
  });

  factory DistractorAnalysisModel.fromJson(Map<String, dynamic> json) {
    return DistractorAnalysisModel(
      optionText: json['optionText'] as String? ?? '',
      likelyReason: json['likelyReason'] as String? ?? '',
      correctiveFeedback: json['correctiveFeedback'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'optionText': optionText,
      'likelyReason': likelyReason,
      'correctiveFeedback': correctiveFeedback,
    };
  }
}

class AiGeneratedQuestionModel extends AiGeneratedQuestion {
  const AiGeneratedQuestionModel({
    required super.text,
    required super.type,
    required super.marks,
    super.options,
    super.correctAnswer,
    required super.cognitiveLevel,
    super.distractorAnalysis,
  });

  factory AiGeneratedQuestionModel.fromJson(Map<String, dynamic> json) {
    return AiGeneratedQuestionModel(
      text: json['text'] as String? ?? '',
      type: QuestionType.fromString(json['type'] as String? ?? ''),
      marks: (json['marks'] as num?)?.toDouble() ?? 1.0,
      options: (json['options'] as List<dynamic>?)?.map((e) => e as String).toList(),
      correctAnswer: json['correctAnswer'] as String?,
      cognitiveLevel: CognitiveLevel.fromString(json['cognitiveLevel'] as String? ?? ''),
      distractorAnalysis: (json['distractorAnalysis'] as List<dynamic>?)
          ?.map((e) => DistractorAnalysisModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'type': type.toString().split('.').last,
      'marks': marks,
      if (options != null) 'options': options,
      if (correctAnswer != null) 'correctAnswer': correctAnswer,
      'cognitiveLevel': cognitiveLevel.toString().split('.').last,
      if (distractorAnalysis != null)
        'distractorAnalysis': distractorAnalysis!
            .map((e) => (e as DistractorAnalysisModel).toJson())
            .toList(),
    };
  }
}

class AiExamBlueprintModel extends AiExamBlueprint {
  const AiExamBlueprintModel({
    required super.title,
    required super.description,
    required List<AiGeneratedQuestionModel> super.questions,
    required super.totalMarks,
    required super.estimatedTimeMinutes,
    required super.cognitiveLevelDistribution,
  });

  factory AiExamBlueprintModel.fromJson(Map<String, dynamic> json) {
    return AiExamBlueprintModel(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      questions: (json['questions'] as List<dynamic>? ?? [])
          .map((e) => AiGeneratedQuestionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalMarks: (json['totalMarks'] as num?)?.toDouble() ?? 10.0,
      estimatedTimeMinutes: (json['estimatedTimeMinutes'] as num?)?.toInt() ?? 30,
      cognitiveLevelDistribution: (json['cognitiveLevelDistribution'] as Map<String, dynamic>? ?? {})
          .map((k, v) => MapEntry(k, (v as num).toDouble())),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'questions': questions
          .map((e) => (e as AiGeneratedQuestionModel).toJson())
          .toList(),
      'totalMarks': totalMarks,
      'estimatedTimeMinutes': estimatedTimeMinutes,
      'cognitiveLevelDistribution': cognitiveLevelDistribution,
    };
  }
}
