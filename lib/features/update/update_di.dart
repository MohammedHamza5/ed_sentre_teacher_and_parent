import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'data/data_sources/update_local_data_source.dart';
import 'data/data_sources/update_remote_data_source.dart';
import 'data/repositories/update_repository.dart';

final sl = GetIt.instance;

void setupUpdateDI() {
  sl.registerFactory(() => UpdateRemoteDataSource(Supabase.instance.client));
  sl.registerFactory(() => UpdateLocalDataSource());
  sl.registerLazySingleton(
    () => UpdateRepository(
      remoteDataSource: sl(),
      localDataSource: sl(),
    ),
  );
}
