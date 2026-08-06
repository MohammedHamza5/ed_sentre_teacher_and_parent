import '../../../../../core/error/failures.dart';
import '../../../domain/entities/ai_exam_blueprint.dart';

sealed class ExamGeneratorState {
  const ExamGeneratorState();
}

class ExamGeneratorInitial extends ExamGeneratorState {
  const ExamGeneratorInitial();
}

class ExamGeneratorLoading extends ExamGeneratorState {
  const ExamGeneratorLoading();
}

class ExamGeneratorSaving extends ExamGeneratorState {
  const ExamGeneratorSaving();
}

class ExamGeneratorSuccess extends ExamGeneratorState {
  final AiExamBlueprint? blueprint;
  const ExamGeneratorSuccess({this.blueprint});
}

class ExamGeneratorSaved extends ExamGeneratorState {
  final String examId;
  const ExamGeneratorSaved({required this.examId});
}

class ExamGeneratorFailure extends ExamGeneratorState {
  final Failure failure;
  const ExamGeneratorFailure({required this.failure});

  String get message => failure.message;
}
