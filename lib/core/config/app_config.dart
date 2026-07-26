import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppConfig extends ChangeNotifier {
  static bool _isDemoMode = const bool.fromEnvironment('IS_DEMO', defaultValue: false);
  static String _runtimeVersion = '';

  static final instance = AppConfig();

  static Future<void> initVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      _runtimeVersion = '${info.version}+${info.buildNumber}';
    } catch (_) {}
  }

  static String get appVersion {
    const compileTimeVersion = String.fromEnvironment('APP_VERSION', defaultValue: '');
    if (compileTimeVersion.isNotEmpty) return compileTimeVersion;
    if (_runtimeVersion.isNotEmpty) return _runtimeVersion;
    return '1.0.0+1';
  }

  static bool get isDemoMode => _isDemoMode;
  
  static set isDemoMode(bool value) {
    _isDemoMode = value;
    instance.notifyListeners();
  }
}

