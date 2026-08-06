import '../../core/di/setup_di.dart';
import '../../shared/data/supabase_repository.dart';
import 'data/repositories/exam_generator_repository_impl.dart';
import 'domain/repositories/exam_generator_repository.dart';
import 'domain/use_cases/generate_deep_exam_use_case.dart';
import 'presentation/cubits/exam_generator/exam_generator_cubit.dart';
import 'domain/use_cases/publish_ai_exam_use_case.dart';

void setupExamGeneratorDI() {
  // Repository
  sl.registerLazySingleton<ExamGeneratorRepository>(
    () => ExamGeneratorRepositoryImpl(sl<SupabaseRepository>()),
  );

  // Use Cases
  sl.registerLazySingleton<GenerateDeepExamUseCase>(
    () => GenerateDeepExamUseCase(sl<ExamGeneratorRepository>()),
  );
  sl.registerLazySingleton<PublishAiExamUseCase>(
    () => PublishAiExamUseCase(sl<ExamGeneratorRepository>()),
  );

  // Cubits
  sl.registerFactory<ExamGeneratorCubit>(
    () => ExamGeneratorCubit(sl<GenerateDeepExamUseCase>(), sl<PublishAiExamUseCase>()),
  );
}
