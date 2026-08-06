import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/use_cases/generate_deep_exam_use_case.dart';
import '../../../domain/use_cases/publish_ai_exam_use_case.dart';
import 'exam_generator_state.dart';

class ExamGeneratorCubit extends Cubit<ExamGeneratorState> {
  final GenerateDeepExamUseCase _generateDeepExamUseCase;
  final PublishAiExamUseCase _publishAiExamUseCase;

  ExamGeneratorCubit(
    this._generateDeepExamUseCase,
    this._publishAiExamUseCase,
  ) : super(const ExamGeneratorInitial());

  Future<void> generateExam({
    String? knowledgeBaseId,
    required String difficulty,
    required int questionCount,
    required String examType,
    String? filePath,
    String? extractedText,
    List<String>? targetChapters,
    String? theme,
  }) async {
    // Prevent race conditions as per contract
    if (state is ExamGeneratorLoading) return;

    emit(const ExamGeneratorLoading());

    final result = await _generateDeepExamUseCase(
      GenerateDeepExamParams(
        knowledgeBaseId: knowledgeBaseId,
        difficulty: difficulty,
        questionCount: questionCount,
        examType: examType,
        filePath: filePath,
        extractedText: extractedText,
        targetChapters: targetChapters,
        theme: theme,
      ),
    );

    result.fold(
      (failure) => emit(ExamGeneratorFailure(failure: failure)),
      (blueprint) => emit(ExamGeneratorSuccess(blueprint: blueprint)),
    );
  }

  Future<void> publishExam(PublishAiExamParams params) async {
    if (state is ExamGeneratorSaving) return;

    emit(const ExamGeneratorSaving());

    final result = await _publishAiExamUseCase(params);

    result.fold(
      (failure) => emit(ExamGeneratorFailure(failure: failure)),
      (assignmentId) => emit(ExamGeneratorSaved(examId: assignmentId)),
    );
  }

  void reset() {
    emit(const ExamGeneratorInitial());
  }
}
