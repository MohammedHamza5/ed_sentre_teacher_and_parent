import 'ai_generated_question.dart';

class AiExamBlueprint {
  final String title;
  final String description;
  final List<AiGeneratedQuestion> questions;
  final double totalMarks;
  final int estimatedTimeMinutes;
  
  // Cognitive analysis
  final Map<String, double> cognitiveLevelDistribution;

  const AiExamBlueprint({
    required this.title,
    required this.description,
    required this.questions,
    required this.totalMarks,
    required this.estimatedTimeMinutes,
    required this.cognitiveLevelDistribution,
  });
}
