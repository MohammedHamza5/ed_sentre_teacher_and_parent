import 'package:get_it/get_it.dart';
import 'domain/repositories/ai_assistant_repository.dart';
import 'data/repositories/ai_assistant_repository_impl.dart';
import 'presentation/cubits/ai_assistant/ai_assistant_cubit.dart';

final sl = GetIt.instance;

Future<void> setupAiAssistantDI() async {
  // Repositories
  if (!sl.isRegistered<AIAssistantRepository>()) {
    sl.registerLazySingleton<AIAssistantRepository>(() => AIAssistantRepositoryImpl());
  }

  // Cubits
  if (!sl.isRegistered<AIAssistantCubit>()) {
    sl.registerFactory<AIAssistantCubit>(() => AIAssistantCubit(sl()));
  }
}
