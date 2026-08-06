import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../shared/models/group_model.dart';
import '../repositories/exam_generator_repository.dart';

class PublishAiExamParams {
  final String centerId;
  final List<GroupModel> targetGroups;
  final String title;
  final String? description;
  final String examType;
  final String difficulty;
  final int? timeLimitMinutes;
  final bool showAnswersAfter;
  final bool shuffleQuestions;
  final List<Map<String, dynamic>> editedQuestions;

  PublishAiExamParams({
    required this.centerId,
    required this.targetGroups,
    required this.title,
    this.description,
    required this.examType,
    required this.difficulty,
    this.timeLimitMinutes,
    required this.showAnswersAfter,
    required this.shuffleQuestions,
    required this.editedQuestions,
  });
}

class PublishAiExamUseCase {
  final ExamGeneratorRepository _repository;

  PublishAiExamUseCase(this._repository);

  Future<Either<Failure, String>> call(PublishAiExamParams params) async {
    return await _repository.publishAiExam(
      centerId: params.centerId,
      targetGroups: params.targetGroups,
      title: params.title,
      description: params.description,
      examType: params.examType,
      difficulty: params.difficulty,
      timeLimitMinutes: params.timeLimitMinutes,
      showAnswersAfter: params.showAnswersAfter,
      shuffleQuestions: params.shuffleQuestions,
      editedQuestions: params.editedQuestions,
    );
  }
}
