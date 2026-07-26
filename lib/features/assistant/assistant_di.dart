import 'package:get_it/get_it.dart';
import 'domain/repositories/assistant_repository.dart';
import 'data/repositories/assistant_repository_impl.dart';

void setupAssistantDI() {
  final sl = GetIt.instance;
  if (!sl.isRegistered<AssistantRepository>()) {
    sl.registerLazySingleton<AssistantRepository>(
      () => AssistantRepositoryImpl(),
    );
  }
}
