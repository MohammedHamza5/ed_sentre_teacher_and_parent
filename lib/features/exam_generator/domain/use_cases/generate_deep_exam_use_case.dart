import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../entities/ai_exam_blueprint.dart';
import '../repositories/exam_generator_repository.dart';

class GenerateDeepExamParams {
  final String? knowledgeBaseId;
  final String difficulty;
  final int questionCount;
  final String examType;
  final String? filePath;
  final String? extractedText;
  final List<String>? targetChapters;
  final String? theme;

  const GenerateDeepExamParams({
    this.knowledgeBaseId,
    required this.difficulty,
    required this.questionCount,
    required this.examType,
    this.filePath,
    this.extractedText,
    this.targetChapters,
    this.theme,
  });
}

class GenerateDeepExamUseCase {
  final ExamGeneratorRepository repository;

  GenerateDeepExamUseCase(this.repository);

  Future<Either<Failure, AiExamBlueprint>> call(GenerateDeepExamParams params) {
    return repository.generateDeepExam(
      knowledgeBaseId: params.knowledgeBaseId,
      difficulty: params.difficulty,
      questionCount: params.questionCount,
      examType: params.examType,
      filePath: params.filePath,
      extractedText: params.extractedText,
      targetChapters: params.targetChapters,
      theme: params.theme,
    );
  }
}
