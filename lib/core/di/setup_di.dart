import 'package:get_it/get_it.dart';
import '../../features/update/update_di.dart';
import '../../features/assistant/assistant_di.dart';

final sl = GetIt.instance;

Future<void> setupDI() async {
  setupUpdateDI();
  setupAssistantDI();
}
