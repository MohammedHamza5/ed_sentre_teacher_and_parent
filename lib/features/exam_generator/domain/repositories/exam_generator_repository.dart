import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/ai_exam_blueprint.dart';
import '../../../../shared/models/group_model.dart';

abstract class ExamGeneratorRepository {
  /// Generates a deep exam using Bloom's Taxonomy and Distractor Analysis
  Future<Either<Failure, AiExamBlueprint>> generateDeepExam({
    String? knowledgeBaseId,
    required String difficulty,
    required int questionCount,
    required String examType,
    String? filePath,
    String? extractedText,
    List<String>? targetChapters,
    String? theme,
  });

  /// Saves the generated blueprint to the database
  Future<Either<Failure, String>> saveGeneratedExam({
    required String centerId,
    String? knowledgeBaseId,
    required AiExamBlueprint blueprint,
    required String difficulty,
    required String examType,
  });

  /// Publishes the AI generated exam by creating assignments and saving questions
  Future<Either<Failure, String>> publishAiExam({
    required String centerId,
    required List<GroupModel> targetGroups,
    required String title,
    String? description,
    required String examType,
    required String difficulty,
    int? timeLimitMinutes,
    required bool showAnswersAfter,
    required bool shuffleQuestions,
    required List<Map<String, dynamic>> editedQuestions,
  });
}
