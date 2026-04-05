import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// AppSettingsProvider — يدير إعدادات التطبيق (Theme، اللغة، إلخ)
///
/// يستبدل الـ ThemeMode.dark الثابت في main.dart بنظام ديناميكي
/// يتيح للمستخدم التبديل بين الوضع الليلي والنهاري ويحفظ الاختيار.
class AppSettingsProvider extends ChangeNotifier {
  // ─── مفاتيح SharedPreferences ──────────────────────────────────────────
  static const String _themeModeKey = 'app_theme_mode';
  static const String _notificationsKey = 'app_notifications_enabled';

  // ─── القيم الافتراضية ──────────────────────────────────────────────────
  ThemeMode _themeMode = ThemeMode.dark; // Dark كـ default للتطبيق
  bool _notificationsEnabled = true; // الإشعارات مفعّلة افتراضياً

  bool _isInitialized = false;

  // ─── Getters ───────────────────────────────────────────────────────────

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;
  bool get isLightMode => _themeMode == ThemeMode.light;
  bool get isSystemMode => _themeMode == ThemeMode.system;
  bool get notificationsEnabled => _notificationsEnabled;
  bool get isInitialized => _isInitialized;

  // ─── Initialization ────────────────────────────────────────────────────

  /// تهيئة الإعدادات من SharedPreferences
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ── Theme ──────────────────────────────────────────────────────────
      final savedMode = prefs.getString(_themeModeKey);
      if (savedMode != null) {
        _themeMode = _themeModeFromString(savedMode);
      }

      // ── Notifications ──────────────────────────────────────────────────
      // getBool returns null if key doesn't exist → keep the default (true)
      final savedNotifications = prefs.getBool(_notificationsKey);
      if (savedNotifications != null) {
        _notificationsEnabled = savedNotifications;
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      // في حالة الفشل نستخدم القيم الافتراضية
      _isInitialized = true;
      debugPrint('⚠️  [AppSettings] Failed to load settings: $e');
    }
  }

  // ─── Theme Control ─────────────────────────────────────────────────────

  /// التبديل بين الوضع الليلي والنهاري مباشرةً
  Future<void> toggleDarkMode() async {
    _themeMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    notifyListeners();
    await _saveThemeMode();
  }

  /// ضبط الـ ThemeMode بشكل صريح
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    notifyListeners();
    await _saveThemeMode();
  }

  /// ضبط الوضع الليلي
  Future<void> setDarkMode() => setThemeMode(ThemeMode.dark);

  /// ضبط الوضع النهاري
  Future<void> setLightMode() => setThemeMode(ThemeMode.light);

  /// اتباع إعداد النظام
  Future<void> setSystemMode() => setThemeMode(ThemeMode.system);

  // ─── Notifications Control ─────────────────────────────────────────────

  /// تفعيل/إيقاف الإشعارات
  Future<void> setNotificationsEnabled(bool value) async {
    if (_notificationsEnabled == value) return;
    _notificationsEnabled = value;
    notifyListeners();
    await _saveNotificationsEnabled();
  }

  /// تبديل حالة الإشعارات
  Future<void> toggleNotifications() =>
      setNotificationsEnabled(!_notificationsEnabled);

  // ─── Persistence ───────────────────────────────────────────────────────

  Future<void> _saveThemeMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_themeModeKey, _themeModeToString(_themeMode));
    } catch (e) {
      debugPrint('⚠️  [AppSettings] Failed to save theme mode: $e');
    }
  }

  Future<void> _saveNotificationsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_notificationsKey, _notificationsEnabled);
    } catch (e) {
      debugPrint('⚠️  [AppSettings] Failed to save notifications setting: $e');
    }
  }

  // ─── Helpers ───────────────────────────────────────────────────────────

  static String _themeModeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.light:
        return 'light';
      case ThemeMode.system:
        return 'system';
    }
  }

  static ThemeMode _themeModeFromString(String value) {
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      case 'system':
        return ThemeMode.system;
      default:
        return ThemeMode.dark; // fallback
    }
  }
}
