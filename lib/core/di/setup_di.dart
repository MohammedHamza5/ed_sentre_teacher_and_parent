import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/update/update_di.dart';
import '../../features/assistant/assistant_di.dart';
import '../../features/exam_generator/exam_generator_di.dart';
import '../../features/ai_assistant/ai_assistant_di.dart';
import '../../shared/data/supabase_repository.dart';
import '../services/ai_service.dart';

final sl = GetIt.instance;

Future<void> setupDI() async {
  // Core Data
  if (!sl.isRegistered<SupabaseClient>()) {
    sl.registerLazySingleton<SupabaseClient>(() => Supabase.instance.client);
  }
  if (!sl.isRegistered<SupabaseRepository>()) {
    sl.registerLazySingleton<SupabaseRepository>(() => SupabaseRepository(sl<SupabaseClient>()));
  }
  if (!sl.isRegistered<AiService>()) {
    sl.registerLazySingleton<AiService>(() => AiService(sl<SupabaseClient>()));
  }

  setupUpdateDI();
  setupAssistantDI();
  setupExamGeneratorDI();
  setupAiAssistantDI();
}
