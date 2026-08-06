import 'cognitive_level.dart';
import 'distractor_analysis.dart';
import '../../../../shared/models/exam_models.dart';

class AiGeneratedQuestion {
  final String text;
  final QuestionType type;
  final double marks;
  final List<String>? options;
  final String? correctAnswer;
  final CognitiveLevel cognitiveLevel;
  final List<DistractorAnalysis>? distractorAnalysis;

  const AiGeneratedQuestion({
    required this.text,
    required this.type,
    required this.marks,
    this.options,
    this.correctAnswer,
    required this.cognitiveLevel,
    this.distractorAnalysis,
  });
}
